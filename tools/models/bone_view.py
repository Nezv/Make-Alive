"""One bite seen through the body: the outfit model slightly transparent, the whole skeleton beneath
it, and the bones the bite lays bare (the ones you can see from outside) lit up. No Blender.

    python tools/models/bone_view.py [bite=chest] [outfit=nurse] [sex=m]  -> references/shots/bone_view_<outfit>_<sex>_<bite>.png

The skeleton is fitted inside the male body, so `m` is the one that lines up.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import bites as K
import body as B
import skeleton as S
import sketch as sk

SENTINEL = (255, 0, 255)
SEE_THROUGH = 0.58          # how much of the body's own colour stays (1 = opaque)
LIT = np.array([1.0, 0.62, 0.1])
LIT_EDGE = (255, 214, 64)


def _layer(P, T, cols, eye, target, size, focal):
    img = sk.render(P, T, cols, eye, target, size=size, focal=focal, bg=SENTINEL)
    mask = ~np.all(img == np.array(SENTINEL, np.uint8), axis=-1)
    return img.astype(np.float32), mask


_FIT = {}


def fitted_skeleton(outfit, sex):
    """Points and triangles of the skeleton as the bites place it (cached)."""
    import outfits as O
    if (outfit, sex) in _FIT:
        return _FIT[(outfit, sex)]
    parts = K.skeleton_parts()
    dressed, _p = O.dress(outfit, sex)
    mesh, piece_of = O.combined(dressed)
    soup = K.Soup(mesh, piece_of)
    sp, st, off = [], [], 0
    for seg, comps in parts.items():
        axis, sc = K.fit_skeleton(comps, seg, soup.tri_pts(soup.tris_of(seg)))
        print(f"{outfit} {sex} {seg}: skeleton scaled to {sc:.2f}")
        for b in comps:
            m = K.Mesh()
            m.verts, m.faces, m.tags = [tuple(v) for v in K._shrunk(b.verts, axis, sc)], b.faces, b.tags
            P, T, _t = m.triangles()
            sp.append(P)
            st.append(T + off)
            off += len(P)
    _FIT[(outfit, sex)] = (np.vstack(sp), np.vstack(st))
    return _FIT[(outfit, sex)]


def view(outfit, sex, bite_name, eye, target, size, focal):
    k = K.NAMES.index(bite_name)
    arr, rep, _ = K.make(outfit, sex, k)
    P, T = arr["P"], arr["T"]
    cols = K.colours(arr, outfit)
    kinds = np.array([kd in ("bone", "marrow") for kd in arr["kind"]])
    # the whole skeleton, every bone, pale, shrunk the way the bites shrink it to sit inside the cloth
    SP, ST = fitted_skeleton(outfit, sex)
    bone_cols = np.tile(np.array([0.9, 0.88, 0.78]), (len(ST), 1))
    bones_img, bones_mask = _layer(SP, ST, bone_cols, eye, target, size, focal)
    body_img, body_mask = _layer(P, T[~kinds], cols[~kinds], eye, target, size, focal)
    lit_img, lit_all = _layer(P, T[kinds], np.tile(LIT, (int(kinds.sum()), 1)), eye, target, size, focal)
    # which of the bite's bones can be seen from outside: draw the whole body with them white and
    # everything else black; what is white is not hidden behind cloth or flesh
    probe = np.where(kinds[:, None], 1.0, 0.0) * np.ones((1, 3))
    seen = sk.render(P, T, probe, eye, target, size=size, focal=focal, bg=(0, 0, 0), ambient=1.0)
    lit_mask = lit_all & (seen.sum(-1) > 300)

    bg = np.array(sk.render(P[:1], np.zeros((0, 3), np.int64), np.zeros((0, 3)), eye, target, size=size, bg=(16, 17, 22)), np.float32)
    out = bg.copy()
    out[bones_mask] = bones_img[bones_mask]
    a = SEE_THROUGH
    out[body_mask] = body_img[body_mask] * a + out[body_mask] * (1 - a)
    # the bones the bite shows: a glow round them, then themselves, on top of everything
    glow = np.array(Image.fromarray((lit_mask * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))) > 0
    out[glow & ~lit_mask] = out[glow & ~lit_mask] * 0.3 + np.array(LIT_EDGE, np.float32) * 0.7
    out[lit_mask] = lit_img[lit_mask]
    return out.astype(np.uint8)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    bite = args[0] if args else "chest"
    outfit = args[1] if len(args) > 1 else "nurse"
    sex = args[2] if len(args) > 2 else "m"
    k = K.NAMES.index(bite)
    arr, rep, _ = K.make(outfit, sex, k)
    c = rep["centre"]
    to = np.asarray(K.BITES[k]["to"], dtype=np.float64)
    to /= np.linalg.norm(to)
    side = np.cross(to, [0.0, 1.0, 0.0])
    views = [
        ((0.0, 1.0, -3.4), (0.0, 0.95, 0.0), (420, 680), 2.1),
        (c - to * 0.95, c, (460, 460), 3.0),
        (c - to * 0.9 + side * 0.55, c, (460, 460), 3.0),
        (c + side * 1.0 + np.array([0.0, 0.1, 0.0]) - to * 0.15, c, (460, 460), 3.0),
    ]
    pics = [view(outfit, sex, bite, e, t, s, f) for e, t, s, f in views]
    path = os.path.join(B.SHOTS, f"bone_view_{outfit}_{sex}_{bite}.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sk.sheet_mixed([pics], path)
    print("wrote", path)


if __name__ == "__main__":
    main()
