"""The element against its references at the same scale: each reference photo straightened onto
the element's own plane (four points of something whose real size is known: an opening, a
door, a panel) and the element's flat elevation drawn over it, so a form that is wrong by 3 cm
shows as two lines 3 cm apart, not as an impression. No Blender: the elevation is the sketch's.

    python tools/models/match.py window_french            -> references/elements/reviews/window_french_match.jpg
    python tools/models/match.py window_french --round=1  -> ..._match_r1.jpg (kept with the round)
    python tools/models/match.py window_french --grid     -> each reference straightened with a 10 cm
                                                             grid, to take measurements off (same folder)

The references and their four points are in `references/elements/<name>/match.json`:

    {"view": "front",                  front: seen from -Z, the viewer's right is -X (u = -x, v = y)
                                       side: seen from -X, the viewer's right is -Z (u = -z, v = y)
     "ppm": 300,                       pixels per metre of the sheet
     "refs": {
       "frontal_white.jpg": {
         "px": [[575,195],[1325,195],[1325,1485],[575,1485]],   four points on the photo (pixels)
         "m":  [[-0.70,2.43],[0.70,2.43],[0.70,0.08],[-0.70,0.08]],  the same points in the elevation (metres)
         "crop": [-1.2, -0.1, 1.2, 2.9],                         u0, v0, u1, v1 of what is shown
         "open": {"shutter_l": 1, "shutter_r": 1},              the parts as the photo shows them
         "note": "the persiennes' rebate: 1.40 x 2.35 (see the card)"}}}

Pick points on one plane (the wall face): anything standing proud of it or sunk behind it is
off by its parallax, which is what the overlay shows too, so judge depth on the 1 m close-ups.
Each tile: the photo straightened, the elevation, and the photo greyed with the elevation's
edges over it (cyan: the element's outline and every crease; a 10 cm grid, labels every 50 cm).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import props  # noqa: E402
import sketch as sk  # noqa: E402

ROOT = props.ROOT
REVIEWS = os.path.join(ROOT, "references", "elements", "reviews")

# view -> (direction looked along, the viewer's right) in game coordinates
VIEWS = {
    "front": (np.array([0.0, 0.0, 1.0]), np.array([-1.0, 0.0, 0.0])),
    "back": (np.array([0.0, 0.0, -1.0]), np.array([1.0, 0.0, 0.0])),
    "side": (np.array([1.0, 0.0, 0.0]), np.array([0.0, 0.0, 1.0])),
}


def homography(src, dst):
    """The 3x3 H with dst ~ H @ src for four point pairs."""
    A, b = [], []
    for (x, y), (u, v) in zip(src, dst):
        A.append([x, y, 1, 0, 0, 0, -u * x, -u * y])
        A.append([0, 0, 0, x, y, 1, -v * x, -v * y])
        b += [u, v]
    h = np.linalg.solve(np.array(A, np.float64), np.array(b, np.float64))
    return np.append(h, 1.0).reshape(3, 3)


def sheet_px(crop, ppm):
    u0, v0, u1, v1 = crop
    return int(round((u1 - u0) * ppm)), int(round((v1 - v0) * ppm))


def to_px(uv, crop, ppm):
    u0, v0, u1, v1 = crop
    return ((uv[0] - u0) * ppm, (v1 - uv[1]) * ppm)


def straighten(photo, ref, crop, ppm):
    """The photo seen square-on: the sheet's pixels mapped back onto the photo's."""
    size = sheet_px(crop, ppm)
    out_pts = [to_px(p, crop, ppm) for p in ref["m"]]
    H = homography(out_pts, ref["px"])  # sheet pixel -> photo pixel
    coeffs = (H / H[2, 2]).flatten()[:8]
    return photo.transform(size, Image.PERSPECTIVE, tuple(coeffs), Image.BICUBIC, fillcolor=(16, 17, 22))


def elevation(name, view, crop, ppm, lod=0, opened=None):
    """The element's flat elevation over `crop` (its colours, shaded) and its edges (a mask),
    its parts open as `opened` says ({part: 0..1}, as the photo shows them)."""
    _, spec = props.find(name)
    parts = spec["build"](lod)
    parts = {k: props._opened(p, (opened or {}).get(k, 0.0)) for k, p in parts.items()}
    m, _ = props.merged(parts)
    P, T, ftags = m.triangles()
    P = np.asarray(P, np.float64)
    T = np.asarray(T)
    cols = props._sketch_colours(spec, ftags, m.triangle_units())
    look, right = VIEWS[view]
    up = np.array([0.0, 1.0, 0.0])
    u0, v0, u1, v1 = crop
    cu, cv = (u0 + u1) / 2, (v0 + v1) / 2
    centre = right * cu + up * cv
    eye = centre - look * 20.0
    size = sheet_px(crop, ppm)
    img, ids = sk.render(P, T, cols, eye, centre, size=size, ortho=ppm, ids=True,
                         key=(-0.45, 0.75, -0.5) if view != "back" else (0.45, 0.75, 0.5))
    # edges: a change of triangle where the shade changes, or the depth (parallel faces one
    # behind the other), or the outline against nothing
    A, B, C = P[T[:, 0]], P[T[:, 1]], P[T[:, 2]]
    N = np.cross(B - A, C - A)
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)
    depth = ((A + B + C) / 3) @ look
    flat = np.abs(N @ look) > 0.996
    edge = np.zeros(ids.shape, bool)
    lum = img.astype(np.int32).sum(2)
    for dy, dx in ((0, 1), (1, 0)):
        a = ids[: ids.shape[0] - dy, : ids.shape[1] - dx]
        b = ids[dy:, dx:]
        diff = a != b
        bg = (a < 0) | (b < 0)
        la = lum[: lum.shape[0] - dy, : lum.shape[1] - dx]
        lb = lum[dy:, dx:]
        shade = np.abs(la - lb) > 12
        ia, ib = np.maximum(a, 0), np.maximum(b, 0)
        step = flat[ia] & flat[ib] & (np.abs(depth[ia] - depth[ib]) > 0.004)
        e = diff & (bg | shade | step)
        edge[: edge.shape[0] - dy, : edge.shape[1] - dx] |= e
    return Image.fromarray(img), edge, len(T)


def grid(im, crop, ppm, colour=(255, 210, 40), every=0.1, label=0.5):
    d = ImageDraw.Draw(im)
    u0, v0, u1, v1 = crop
    k0 = int(np.ceil(u0 / every - 1e-6))
    for k in range(k0, int(np.floor(u1 / every + 1e-6)) + 1):
        u = k * every
        x = (u - u0) * ppm
        major = abs(u / label - round(u / label)) < 1e-6
        d.line([(x, 0), (x, im.height)], fill=colour if major else tuple(c // 3 for c in colour), width=1)
        if major:
            d.text((x + 2, im.height - 12), f"{u:+.1f}", fill=colour)
    k0 = int(np.ceil(v0 / every - 1e-6))
    for k in range(k0, int(np.floor(v1 / every + 1e-6)) + 1):
        v = k * every
        y = (v1 - v) * ppm
        major = abs(v / label - round(v / label)) < 1e-6
        d.line([(0, y), (im.width, y)], fill=colour if major else tuple(c // 3 for c in colour), width=1)
        if major:
            d.text((2, y - 12), f"{v:.1f}", fill=colour)
    return im


def overlay(photo, edge):
    g = np.asarray(photo.convert("L"), np.float32)[..., None] * np.array([0.62, 0.62, 0.62]) + 30
    g = np.clip(g, 0, 255)
    thick = edge.copy()
    thick[1:] |= edge[:-1]
    thick[:, 1:] |= edge[:, :-1]
    g[thick] = (0, 235, 255)
    return Image.fromarray(g.astype(np.uint8))


def _label(im, text):
    d = ImageDraw.Draw(im)
    d.rectangle([0, 0, len(text) * 6 + 8, 14], fill=(0, 0, 0))
    d.text((4, 1), text, fill=(255, 255, 255))
    return im


def load(name):
    path = os.path.join(ROOT, "references", "elements", name, "match.json")
    if not os.path.exists(path):
        raise SystemExit(f"no {path}: say which references to match and their four points (see the top of match.py)")
    return json.load(open(path, encoding="utf-8")), os.path.dirname(path)


def main():
    args = sys.argv[1:]
    names = [a for a in args if not a.startswith("--")]
    rnd = next((a.split("=", 1)[1] for a in args if a.startswith("--round=")), None)
    for name in names:
        cfg, folder = load(name)
        ppm = cfg.get("ppm", 300)
        view = cfg.get("view", "front")
        rows = []
        for fn, ref in cfg["refs"].items():
            crop = ref["crop"]
            photo = straighten(Image.open(os.path.join(folder, fn)).convert("RGB"), ref, crop, ppm)
            if "--grid" in args:
                out = os.path.join(REVIEWS, f"{name}_grid_{fn.rsplit('.', 1)[0]}.jpg")
                grid(photo.copy(), crop, ppm).save(out, quality=88)
                print("wrote", out)
                continue
            elev, edge, ntri = elevation(name, ref.get("view", view), crop, ppm, opened=ref.get("open"))
            tiles = [_label(grid(photo.copy(), crop, ppm), fn), _label(grid(elev, crop, ppm, (200, 200, 90)), f"{name} ({ntri} tris)"),
                     _label(grid(overlay(photo, edge), crop, ppm, (120, 110, 40)), "overlay: " + ref.get("note", ""))]
            rows.append(tiles)
        if not rows:
            continue
        W = sum(t.width for t in rows[0])
        H = sum(r[0].height for r in rows)
        sheet = Image.new("RGB", (max(sum(t.width for t in r) for r in rows), H), (10, 10, 12))
        y = 0
        for r in rows:
            x = 0
            for t in r:
                sheet.paste(t, (x, y))
                x += t.width
            y += r[0].height
        out = os.path.join(REVIEWS, f"{name}_match{'_r' + rnd if rnd else ''}.jpg")
        os.makedirs(REVIEWS, exist_ok=True)
        sheet.save(out, quality=88)
        print("wrote", out, sheet.size)


if __name__ == "__main__":
    main()
