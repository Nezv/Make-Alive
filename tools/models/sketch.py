"""Quick flat-shaded pictures of a model without Blender (numpy + Pillow): for shaping a
poly.Mesh in seconds. Every face is one colour lit by a key and a fill light, which is also
how the game shows the faceted models.

    python tools/models/body.py --sketch      -> references/shots/sketch_body.png
"""
import numpy as np
from PIL import Image


def _look(eye, target, up=(0.0, 1.0, 0.0)):
    eye = np.asarray(eye, dtype=np.float64)
    f = np.asarray(target, dtype=np.float64) - eye
    f /= np.linalg.norm(f)
    r = np.cross(f, up)
    r /= np.linalg.norm(r)
    u = np.cross(r, f)
    return eye, r, u, f


def render(P, T, colors, eye, target, size=(420, 640), focal=2.6, bg=(16, 17, 22),
           key=(-0.45, 0.75, -0.5), fill=(0.6, 0.3, 0.4), ambient=0.32):
    """P (n, 3) points, T (m, 3) triangles, colors (m, 3) in 0..1. `focal` is the lens in
    picture heights (bigger = narrower view). Returns an RGB uint8 picture."""
    w, h = size
    eye, r, u, f = _look(eye, target)
    rel = P - eye
    cz = rel @ f
    cx = rel @ r
    cy = rel @ u
    sx = w / 2 + cx / np.maximum(cz, 1e-4) * focal * h / 2
    sy = h / 2 - cy / np.maximum(cz, 1e-4) * focal * h / 2
    A, B, C = P[T[:, 0]], P[T[:, 1]], P[T[:, 2]]
    N = np.cross(B - A, C - A)
    N /= np.maximum(np.linalg.norm(N, axis=1, keepdims=True), 1e-12)
    centre = (A + B + C) / 3
    # two-sided: every face is drawn and lit on the side the camera sees (the z-buffer keeps
    # the outside of a closed shape in front, whichever way its faces were wound)
    N *= np.where(((eye - centre) * N).sum(1) > 0, 1.0, -1.0)[:, None]
    facing = np.ones(len(T), dtype=bool)
    k = np.asarray(key, dtype=np.float64)
    k /= np.linalg.norm(k)
    fl = np.asarray(fill, dtype=np.float64)
    fl /= np.linalg.norm(fl)
    shade = ambient + 0.75 * np.clip(N @ k, 0, 1) + 0.22 * np.clip(N @ fl, 0, 1)
    col = np.clip(colors * shade[:, None], 0, 1)
    img = np.empty((h, w, 3), dtype=np.float64)
    img[:] = np.array(bg) / 255.0
    zbuf = np.full((h, w), np.inf)
    for i in np.nonzero(facing)[0]:
        ia, ib, ic = T[i]
        x0, y0, x1, y1, x2, y2 = sx[ia], sy[ia], sx[ib], sy[ib], sx[ic], sy[ic]
        lo_x = max(int(np.floor(min(x0, x1, x2))), 0)
        hi_x = min(int(np.ceil(max(x0, x1, x2))), w - 1)
        lo_y = max(int(np.floor(min(y0, y1, y2))), 0)
        hi_y = min(int(np.ceil(max(y0, y1, y2))), h - 1)
        if lo_x > hi_x or lo_y > hi_y:
            continue
        gy, gx = np.mgrid[lo_y:hi_y + 1, lo_x:hi_x + 1]
        px, py = gx + 0.5, gy + 0.5
        area = (x1 - x0) * (y2 - y0) - (x2 - x0) * (y1 - y0)
        if abs(area) < 1e-9:
            continue
        w0 = ((x1 - px) * (y2 - py) - (x2 - px) * (y1 - py)) / area
        w1 = ((x2 - px) * (y0 - py) - (x0 - px) * (y2 - py)) / area
        w2 = 1.0 - w0 - w1
        inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        if not inside.any():
            continue
        z = w0 * cz[ia] + w1 * cz[ib] + w2 * cz[ic]
        sub = zbuf[lo_y:hi_y + 1, lo_x:hi_x + 1]
        win = inside & (z < sub)
        sub[win] = z[win]
        img[lo_y:hi_y + 1, lo_x:hi_x + 1][win] = col[i]
    return (np.clip(img, 0, 1) * 255).astype(np.uint8)


def sheet(rows, path, labels=None):
    """Pictures in rows (lists of equal-size arrays) into one PNG."""
    h, w, _ = rows[0][0].shape
    cols = max(len(r) for r in rows)
    out = np.zeros((h * len(rows), w * cols, 3), dtype=np.uint8)
    for ri, r in enumerate(rows):
        for ci, im in enumerate(r):
            out[ri * h:(ri + 1) * h, ci * w:(ci + 1) * w] = im
    Image.fromarray(out).save(path)
    return path
