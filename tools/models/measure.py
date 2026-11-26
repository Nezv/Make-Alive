"""Measure the zombies in references/zombies.png: proportions, face layout and colours, for the
model scripts to build from (tools/models/body.py reads the JSON).

    python tools/models/measure.py      -> tools/models/measured.json + references/shots/measure_zombies.png

The picture is small (360 x 203) and the zombies overlap, so each one gets rough landmarks by
hand below (crown, chin, eyes, mouth, feet...) and the script snaps every mark to what the pixels
say: eyes to the glowing blob's centre, the mouth to the dark hole, the crown and the feet to the
edge of the figure against a fitted background, the chin to the strongest light-to-dark edge,
the face's width to the skin's edges. Colours come from clustering the pixels of each kind
(skin, blood, eyes, mouth, hair). The overlay shows every snapped landmark: check it after a change.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "references", "zombies.png")
OUT_JSON = os.path.join(ROOT, "tools", "models", "measured.json")
OUT_PNG = os.path.join(ROOT, "references", "shots", "measure_zombies.png")

# Rough landmarks, pixels of the source picture. crown = top of the skull (under any hat), chin =
# bottom of the jaw, eyes = (x, y) of each glowing eye, mouth = centre of the open mouth, face =
# (x left, x right) of the face at the eyes, feet = a point near the bottom of each visible shoe,
# shoulders = the outer corners of the shoulders, hands = boxes around each visible hand.
# Faces hidden by glasses, make-up or a hat brim give no face layout (eyes None). Under a hat or a
# big hairdo (hat=True) the crown is where the skull must be, as marked, not snapped.
FIGURES = [
    dict(name="schoolgirl", sex="f", hat=True, crown=(40, 42), chin=(41, 71), eyes=[(34.5, 58.5), (45, 58.5)],
         mouth=(41, 65.5), face=(27, 52), feet=[(29, 171)], shoulders=[(13, 77), (62, 77)],
         hands=[(3, 118, 20, 139), (56, 123, 70, 142)]),
    dict(name="army_girl", sex="f", hat=True, crown=(70, 17), chin=(73, 43), eyes=None, mouth=(75, 39),
         face=(62, 84), feet=None, shoulders=None, hands=[]),
    dict(name="cop", sex="m", hat=True, crown=(110, 35), chin=(112, 61), eyes=None, mouth=(112, 56),
         face=(99, 125), feet=[(99, 171), (128, 172)], shoulders=[(86, 64), (137, 64)],
         hands=[(78, 116, 94, 139), (125, 116, 139, 139)]),
    dict(name="office", sex="m", crown=(147, 17), chin=(147, 46), eyes=[(143, 33), (149, 32.5)],
         mouth=(147, 40), face=(138, 157), feet=None, shoulders=None, hands=[]),
    dict(name="worker", sex="m", hat=True, crown=(208, 22), chin=(208, 40), eyes=None, mouth=(208, 34.5),
         face=(199, 219), feet=None, shoulders=None, hands=[]),
    dict(name="glasses", sex="m", crown=(246, 28), chin=(249, 60), eyes=None, mouth=(250, 56),
         face=(237, 260), feet=[(231, 166), (258, 174)], shoulders=[(221, 63), (268, 62)],
         hands=[(254, 118, 270, 140)]),
    dict(name="jacket", sex="m", crown=(282, 26), chin=(281, 53), eyes=[(276.5, 40), (285.5, 40)],
         mouth=(280, 48), face=(270, 292), feet=[(278, 147)], shoulders=None, hands=[]),
    dict(name="bellhop", sex="m", hat=True, crown=(322, 38), chin=(322, 68), eyes=[(311.5, 55), (322, 53.5)],
         mouth=(322, 61.5), face=(309, 336), feet=[(306, 178), (332, 185)], shoulders=[(299, 72), (343, 70)],
         hands=[(326, 128, 345, 150)]),
]
TEXT_BOX = (0, 172, 80, 203)   # the "POLYGON CITY ZOMBIES" lettering: never figure, never background


def load():
    im = np.asarray(Image.open(SRC).convert("RGB"), dtype=np.float32) / 255.0
    return im


def luminance(im):
    return im[..., 0] * 0.2126 + im[..., 1] * 0.7152 + im[..., 2] * 0.0722


def saturation(im):
    mx = im.max(-1)
    mn = im.min(-1)
    return (mx - mn) / np.maximum(mx, 1e-4)


# --- Background and figure mask -------------------------------------------------------------

def _design(xs, ys, w, h):
    u = xs / w * 2 - 1
    v = ys / h * 2 - 1
    return np.stack([np.ones_like(u), u, v, u * u, u * v, v * v, u ** 3, u * u * v, u * v * v, v ** 3], -1)


def fit_background(im):
    """A smooth backdrop (a cubic in x and y per channel), fitted robustly: start from the
    picture's empty top band and edges, then keep every pixel the fit explains and refit."""
    h, w, _ = im.shape
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    A = _design(xs.ravel(), ys.ravel(), w, h)
    flat = im.reshape(-1, 3)
    seed = np.zeros((h, w), bool)
    seed[:9, :] = True
    seed[:, 350:] = True
    seed[190:, 100:] = True
    seed[:30, :22] = True
    seed[TEXT_BOX[1]:TEXT_BOX[3], TEXT_BOX[0]:TEXT_BOX[2]] = False
    use = seed.ravel()
    for _ in range(6):
        coef, *_ = np.linalg.lstsq(A[use], flat[use], rcond=None)
        bg = A @ coef
        resid = np.abs(flat - bg).max(-1)
        use = resid < 0.045
        use &= ~_text_mask(h, w).ravel()
    return (A @ coef).reshape(h, w, 3)


def _text_mask(h, w):
    m = np.zeros((h, w), bool)
    m[TEXT_BOX[1]:TEXT_BOX[3], TEXT_BOX[0]:TEXT_BOX[2]] = True
    return m


def figure_mask(im, bg):
    """Pixels that are a zombie: far from the backdrop's colour, and not just the backdrop in
    shadow (same hue, darker)."""
    diff = np.abs(im - bg).max(-1)
    L, Lb = luminance(im), luminance(bg)
    ratio = L / np.maximum(Lb, 1e-4)
    chroma = im / np.maximum(im.sum(-1, keepdims=True), 1e-4)
    chroma_b = bg / np.maximum(bg.sum(-1, keepdims=True), 1e-4)
    same_hue = np.abs(chroma - chroma_b).max(-1) < 0.035
    floor = np.arange(im.shape[0])[:, None] > 112      # shadows only fall on the floor
    shadow = same_hue & (ratio > 0.35) & (ratio < 1.0) & floor
    m = (diff > 0.07) & ~shadow
    m = ndi.binary_opening(m, iterations=1)
    m = ndi.binary_fill_holes(m)
    return m & ~_text_mask(*m.shape)


# --- Snapping marks to the picture -----------------------------------------------------------

def snap_eye(L, x, y, r=3):
    """The glowing blob nearest the mark: its centre and size (pixels)."""
    xi, yi = int(round(x)), int(round(y))
    win = L[yi - r:yi + r + 1, xi - r:xi + r + 1]
    peak = win.max()
    blob = win > peak - 0.12
    lab, _ = ndi.label(blob)
    py, px = np.unravel_index(np.argmax(win), win.shape)
    one = lab == lab[py, px]
    wts = (win - (peak - 0.12)) * one
    cy, cx = ndi.center_of_mass(wts)
    ys, xs = np.nonzero(one)
    return dict(x=float(xi - r + cx), y=float(yi - r + cy), w=float(np.ptp(xs) + 1), h=float(np.ptp(ys) + 1),
                glow=float(peak))


def snap_mouth(im, L, x, y, rx=6, ry=4):
    """The open mouth: dark pixels (and the red of the lips round them) near the mark."""
    xi, yi = int(round(x)), int(round(y))
    win = L[yi - ry:yi + ry + 1, xi - rx:xi + rx + 1]
    sub = im[yi - ry:yi + ry + 1, xi - rx:xi + rx + 1]
    dark = win < max(0.2, np.percentile(win, 12) + 0.03)
    lab, n = ndi.label(dark)
    if n == 0:
        return dict(x=float(x), y=float(y), w=0.0, h=0.0)
    py, px = np.unravel_index(np.argmin(win + (1 - dark) * 9), win.shape)
    hole = lab == lab[py, px]
    red = (sub[..., 0] > sub[..., 1] * 1.45) & (sub[..., 0] > 0.25)
    lips = ndi.binary_dilation(hole, iterations=1) & red | hole
    ys, xs = np.nonzero(hole)
    ly, lx = np.nonzero(lips)
    return dict(x=float(xi - rx + xs.mean()), y=float(yi - ry + ys.mean()), w=float(np.ptp(xs) + 1),
                h=float(np.ptp(ys) + 1), lips_w=float(np.ptp(lx) + 1), lips_h=float(np.ptp(ly) + 1))


def snap_crown(mask, x, y, search=5):
    """The top of the figure in the columns round x, near the mark."""
    best = y
    cols = [int(round(x)) + d for d in (-1, 0, 1)]
    tops = []
    for c in cols:
        col = mask[max(0, int(y) - search):int(y) + search + 1, c]
        on = np.nonzero(col)[0]
        if len(on):
            tops.append(max(0, int(y) - search) + on[0])
    if tops:
        best = float(np.median(tops))
    return best


def snap_chin(L, x, y, search=3):
    """Under the jaw the light skin meets the dark of the neck's shadow: the strongest fall in
    brightness going down, near the mark."""
    xi = int(round(x))
    band = L[:, xi - 2:xi + 3].mean(-1)
    g = band[1:] - band[:-1]                 # g[i]: from row i to row i + 1
    lo, hi = int(y) - search, int(y) + search
    i = lo + int(np.argmin(g[lo:hi + 1]))
    return float(i) + 0.5


def snap_face(im, L, y, x0, x1, search=3):
    """Left and right edges of the face at row y: the strongest brightness steps near the marks."""
    row = L[int(round(y)) - 1:int(round(y)) + 2].mean(0)
    g = np.abs(row[1:] - row[:-1])
    a = int(x0) - search + int(np.argmax(g[int(x0) - search:int(x0) + search + 1]))
    b = int(x1) - search + int(np.argmax(g[int(x1) - search:int(x1) + search + 1]))
    return float(a) + 0.5, float(b) + 0.5


def snap_foot(mask, x, y, rx=6, search=8):
    """The lowest figure pixel near the mark."""
    xi, yi = int(round(x)), int(round(y))
    win = mask[yi - search:yi + search + 1, xi - rx:xi + rx + 1]
    ys, _ = np.nonzero(win)
    return float(yi - search + ys.max()) if len(ys) else float(y)


def snap_shoulder(mask, x, y, side, search=4):
    """The outer edge of the figure along the row, near the mark (side -1 = left, +1 = right)."""
    xi, yi = int(round(x)), int(round(y))
    row = mask[yi - 1:yi + 2].any(0)
    best = xi
    for dx in range(-search, search + 1):
        c = xi + dx
        if row[c] and not row[c + side]:
            if abs(dx) <= abs(best - xi) or best == xi and not (row[xi] and not row[xi + side]):
                best = c
    return float(best)


def hand_size(im, box):
    """A hand's blob in its box: skin or blood, joined up. Returns (width, height) in pixels."""
    x0, y0, x1, y1 = box
    sub = im[y0:y1, x0:x1]
    L = luminance(sub)
    s = saturation(sub)
    red = (sub[..., 0] > sub[..., 1] * 1.4) & (sub[..., 0] > 0.3)
    skin = (s < 0.3) & (L > 0.4)
    m = ndi.binary_closing(red | skin, iterations=1)
    lab, n = ndi.label(m)
    if n == 0:
        return 0.0, 0.0
    sizes = ndi.sum(m, lab, range(1, n + 1))
    one = lab == 1 + int(np.argmax(sizes))
    ys, xs = np.nonzero(one)
    return float(np.ptp(xs) + 1), float(np.ptp(ys) + 1)


# --- Colours ---------------------------------------------------------------------------------

def kmeans(X, k, iters=30, seed=3):
    rng = np.random.default_rng(seed)
    C = X[rng.choice(len(X), k, replace=False)]
    for _ in range(iters):
        d = ((X[:, None] - C[None]) ** 2).sum(-1)
        a = d.argmin(1)
        C = np.stack([X[a == j].mean(0) if (a == j).any() else C[j] for j in range(k)])
    counts = np.bincount(a, minlength=k)
    return C, counts


def hexc(c):
    c = np.clip(np.asarray(c), 0, 1)
    return "#%02x%02x%02x" % tuple(int(round(v * 255)) for v in c)


def colours(im, L, mask, figs):
    out = {}
    sat = saturation(im)
    # Skin: the face between the eyes' line and the chin, minus eyes, mouth, blood and shadow.
    skin_px = []
    for f in figs:
        if f.get("eyes_m") is None:
            continue
        y0 = int(round(min(e["y"] for e in f["eyes_m"]) - 1))
        y1 = int(round(f["chin_m"]))
        x0, x1 = int(round(f["face_m"][0])) + 2, int(round(f["face_m"][1])) - 1
        sub = im[y0:y1, x0:x1].reshape(-1, 3)
        Ls = L[y0:y1, x0:x1].ravel()
        ss = sat[y0:y1, x0:x1].ravel()
        red = (sub[:, 0] > sub[:, 1] * 1.3)
        keep = (ss < 0.28) & (Ls > 0.32) & (Ls < 0.86) & ~red
        skin_px.append(sub[keep])
    skin = np.concatenate(skin_px)
    Ls = luminance(skin)
    out["skin"] = hexc(np.median(skin, 0))
    out["skin_lit"] = hexc(np.median(skin[Ls > np.percentile(Ls, 70)], 0))
    out["skin_shade"] = hexc(np.median(skin[Ls < np.percentile(Ls, 30)], 0))
    # Blood: every strongly red pixel of the figures, in three tones.
    px = im[mask]
    red = px[(px[:, 0] > 0.3) & (px[:, 0] > px[:, 1] * 1.7) & (px[:, 0] > px[:, 2] * 1.5)]
    C, counts = kmeans(red, 3)
    order = np.argsort(luminance(C))
    out["blood_dark"], out["blood"], out["blood_light"] = (hexc(C[i]) for i in order)
    out["blood_share"] = float(len(red) / max(len(px), 1))
    # Eyes: the glowing pixels; mouth: the darkest of each hole.
    glow, hole = [], []
    for f in figs:
        for e in f.get("eyes_m") or []:
            xi, yi = int(round(e["x"])), int(round(e["y"]))
            win = im[yi - 1:yi + 2, xi - 1:xi + 2].reshape(-1, 3)
            glow.append(win[np.argmax(luminance(win))])
        m = f["mouth_m"]
        xi, yi = int(round(m["x"])), int(round(m["y"]))
        win = im[yi - 1:yi + 2, xi - 2:xi + 3].reshape(-1, 3)
        hole.append(win[np.argmin(luminance(win))])
    out["eyes"] = hexc(np.median(glow, 0))
    out["mouth"] = hexc(np.median(hole, 0))
    # Hair: dark, not backdrop, above the brow of the faces we can see.
    hair = []
    for f in figs:
        if f.get("eyes_m") is None:
            continue
        top = int(round(f["crown_m"]))
        brow = int(round(min(e["y"] for e in f["eyes_m"]) - 0.3 * f["head_h"]))
        x0, x1 = int(round(f["face_m"][0])), int(round(f["face_m"][1]))
        sub = im[top:brow, x0:x1].reshape(-1, 3)
        msk = mask[top:brow, x0:x1].ravel()
        Lh = luminance(sub)
        sh = saturation(sub[None])[0]
        hair.append(sub[msk & (Lh < 0.33) & (sh < 0.35) & (sub[:, 0] < sub[:, 1] * 1.25)])
    hair = np.concatenate(hair)
    out["hair"] = hexc(np.median(hair, 0))
    return out


# --- Run -------------------------------------------------------------------------------------

def measure():
    im = load()
    L = luminance(im)
    bg = fit_background(im)
    mask = figure_mask(im, bg)
    figs = []
    for spec in FIGURES:
        f = dict(name=spec["name"], sex=spec["sex"])
        cx, cy = spec["crown"]
        f["crown_m"] = float(cy) if spec.get("hat") else snap_crown(mask, cx, cy)
        f["chin_m"] = snap_chin(L, *spec["chin"])
        f["head_h"] = f["chin_m"] - f["crown_m"]
        f["mouth_m"] = snap_mouth(im, L, *spec["mouth"])
        f["eyes_m"] = [snap_eye(L, *e) for e in spec["eyes"]] if spec["eyes"] else None
        eye_y = np.mean([e["y"] for e in f["eyes_m"]]) if f["eyes_m"] else (f["crown_m"] + f["chin_m"]) / 2
        f["face_m"] = snap_face(im, L, eye_y, *spec["face"])
        f["head_w"] = f["face_m"][1] - f["face_m"][0]
        if spec["feet"]:
            f["feet_m"] = [(x, snap_foot(mask, x, y)) for x, y in spec["feet"]]
            f["height"] = max(y for _, y in f["feet_m"]) - f["crown_m"]
        if spec["shoulders"]:
            (lx, ly), (rx, ry) = spec["shoulders"]
            f["shoulders_m"] = [(snap_shoulder(mask, lx, ly, -1), ly), (snap_shoulder(mask, rx, ry, 1), ry)]
            f["shoulder_w"] = f["shoulders_m"][1][0] - f["shoulders_m"][0][0]
        f["hands_m"] = [hand_size(im, b) for b in spec["hands"]]
        figs.append(f)

    def med(vals):
        vals = [v for v in vals if v is not None]
        return float(np.median(vals)) if vals else None

    ratios = []
    for f in figs:
        r = dict(name=f["name"], sex=f["sex"], head_h_px=f["head_h"], head_w_px=f["head_w"],
                 head_aspect=f["head_w"] / f["head_h"])
        if f.get("height"):
            r["heads_tall"] = f["height"] / f["head_h"]
        if f.get("shoulder_w"):
            r["shoulders_in_heads"] = f["shoulder_w"] / f["head_w"]
        if f["hands_m"]:
            r["hand_in_heads"] = max(max(w, h) for w, h in f["hands_m"]) / f["head_h"]
        m = f["mouth_m"]
        r["mouth_line"] = (m["y"] - f["crown_m"]) / f["head_h"]
        r["mouth_w"] = m["w"] / f["head_w"]
        r["mouth_h"] = m["h"] / f["head_h"]
        if f["eyes_m"]:
            e0, e1 = sorted(f["eyes_m"], key=lambda e: e["x"])
            r["eye_line"] = ((e0["y"] + e1["y"]) / 2 - f["crown_m"]) / f["head_h"]
            r["eye_gap"] = (e1["x"] - e0["x"]) / f["head_w"]
            r["eye_w"] = (e0["w"] + e1["w"]) / 2 / f["head_w"]
            r["eye_h"] = (e0["h"] + e1["h"]) / 2 / f["head_h"]
            r["brow_to_eye"] = None
        ratios.append(r)
    keys = ["head_aspect", "heads_tall", "shoulders_in_heads", "hand_in_heads", "eye_line", "eye_gap",
            "eye_w", "eye_h", "mouth_line", "mouth_w", "mouth_h"]
    summary = {k: med([r.get(k) for r in ratios]) for k in keys}
    summary["female"] = {k: med([r.get(k) for r in ratios if r["sex"] == "f"]) for k in keys}
    summary["male"] = {k: med([r.get(k) for r in ratios if r["sex"] == "m"]) for k in keys}
    pal = colours(im, L, mask, figs)
    return im, bg, mask, figs, ratios, summary, pal


def overlay(im, mask, figs, path, k=4):
    h, w, _ = im.shape
    base = (im * 255).astype(np.uint8)
    tint = base.copy()
    tint[~mask] = (tint[~mask] * 0.35).astype(np.uint8)
    img = Image.fromarray(np.concatenate([base, tint], 1)).resize((w * 2 * k, h * k), Image.NEAREST)
    d = ImageDraw.Draw(img)

    def P(x, y, off=0):
        return ((x + off) * k, y * k)

    for off in (0, w):
        for f in figs:
            x0, x1 = f["face_m"]
            d.rectangle([P(x0, f["crown_m"], off), P(x1, f["chin_m"], off)], outline=(255, 220, 0))
            for e in f["eyes_m"] or []:
                cx, cy = P(e["x"], e["y"], off)
                d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], outline=(0, 255, 255), width=2)
            m = f["mouth_m"]
            d.rectangle([P(m["x"] - m["w"] / 2, m["y"] - m["h"] / 2, off), P(m["x"] + m["w"] / 2, m["y"] + m["h"] / 2, off)],
                        outline=(255, 60, 200), width=2)
            for x, y in f.get("feet_m", []):
                d.line([P(x - 4, y, off), P(x + 4, y, off)], fill=(80, 255, 80), width=3)
            for x, y in f.get("shoulders_m", []):
                cx, cy = P(x, y, off)
                d.line([cx, cy - 10, cx, cy + 10], fill=(255, 140, 0), width=3)
            if f.get("height"):
                d.line([P(f["face_m"][0] - 2, f["crown_m"], off), P(f["face_m"][0] - 2, f["crown_m"] + f["height"], off)],
                       fill=(80, 255, 80), width=1)
            d.text(P(f["face_m"][0], f["crown_m"] - 4, off), f["name"], fill=(255, 255, 255))
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)


def main():
    im, bg, mask, figs, ratios, summary, pal = measure()
    overlay(im, mask, figs, OUT_PNG)
    data = dict(source="references/zombies.png", figures=ratios, summary=summary, colours=pal)
    with open(OUT_JSON, "w") as fh:
        json.dump(data, fh, indent=1, sort_keys=False)
    if "--quiet" not in sys.argv:
        for r in ratios:
            print(r["name"].ljust(11), " ".join(f"{k}={v:.3f}" for k, v in r.items()
                                                if isinstance(v, float) and k not in ("head_h_px", "head_w_px")))
        print("summary:", json.dumps(summary, indent=1))
        print("colours:", pal)
        print("wrote", OUT_JSON, "and", OUT_PNG)


if __name__ == "__main__":
    main()
