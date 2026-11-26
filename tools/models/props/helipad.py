"""The hospital's rooftop helipad (S208). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

helipad: the raised steel deck over the roof: a square deck of 16 m on a grid of steel legs, the H in
its circle and the touchdown ring painted (by position), the edge's perimeter lights (lit), the safety
netting sloping out on its brackets all round, the windsock on its mast at one corner, the access
stair down to the roof with its gate, the fire hose box beside it.

The deck's surface is y = 0, the roof 1.6 m below it; the stair comes down on the -Z side.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

PAD = dict(size=16.0, legs=1.60, net=1.5, deck=0.25)


def materials():
    return {
        "deck": Material((0.30, 0.31, 0.32), kind="concrete", chip=0.0, rusts=False, grain=0.12),
        "steel": Material((0.48, 0.50, 0.52), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.06, fixing=True),
        "net": Material((0.62, 0.64, 0.64), chip=0.0, rusts=False, grain=0.04),
        "lamp": Material((0.80, 0.95, 0.65), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.70, 1.0, 0.55)),
        "sock": Material((0.95, 0.42, 0.08), kind="paper", chip=0.0, rusts=False, grain=0.06),
        "red": Material((0.70, 0.10, 0.08), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.04),
        "white": Material((0.90, 0.90, 0.88), kind="rubber", chip=0.0, rusts=False, grain=0.04),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


def helipad(lod):
    A, Hl, nw, dt = PAD["size"], PAD["legs"], PAD["net"], PAD["deck"]
    m = Mesh()
    m.merge(S.box((0, -dt / 2, 0), (A / 2, dt / 2, A / 2), "deck"))
    # the frame under it: beams both ways, legs on the roof
    n = [5, 3, 2][lod]
    for k in range(n):
        c = -A / 2 + 1.0 + k * (A - 2.0) / (n - 1)
        m.merge(S.box((c, -dt - 0.20, 0), (0.10, 0.20, A / 2 - 0.2), "steel"))
        if lod < 2:
            m.merge(S.box((0, -dt - 0.20, c), (A / 2 - 0.2, 0.20, 0.10), "steel"))
        for k2 in range(n):
            c2 = -A / 2 + 1.0 + k2 * (A - 2.0) / (n - 1)
            m.merge(S.box((c, -(Hl + dt) / 2 - 0.2, c2), (0.10, (Hl - dt) / 2 - 0.2, 0.10), "steel"))
    # the netting: sloping out from the deck's edge on brackets, its rim tube
    for s in range(4):
        R = S.rotation((0, 1, 0), s * np.pi / 2)
        net = Mesh()
        net.merge(S.box((0, -0.15, -A / 2 - nw / 2), (A / 2, 0.01, nw / 2), "net").transformed(S.rotation((1, 0, 0), 0.0), (0, 0, 0)))
        if lod < 2:
            for x in np.linspace(-A / 2, A / 2, [9, 5][lod]):
                net.merge(S.sweep([(x, -0.30, -A / 2), (x, -0.05, -A / 2 - nw)], S.circle(0.025, 4), "steel"))
            net.merge(S.sweep([(-A / 2, -0.05, -A / 2 - nw), (A / 2, -0.05, -A / 2 - nw)], S.circle(0.03, 5), "steel"))
        if lod == 0:  # the mesh's strands across
            for k in range(1, 6):
                z = -A / 2 - k * nw / 6
                net.merge(S.box((0, -0.14, z), (A / 2, 0.015, 0.006), "steel"))
        m.merge(net.transformed(R, (0, 0, 0)))
    # the perimeter lights along the edges
    for s in range(4):
        R = S.rotation((0, 1, 0), s * np.pi / 2)
        for x in np.linspace(-A / 2 + 0.5, A / 2 - 0.5, [8, 4, 2][lod]):
            lamp = S.lathe([(0.0, 0.07), (0.05, 0.06), (0.10, 0.0)], [8, 6, 4][lod], tag="lamp").transformed(np.eye(3), (x, 0, -A / 2 + 0.15))
            m.merge(lamp.transformed(R, (0, 0, 0)))
    # the windsock on its mast at a corner beyond the net
    mx, mz = A / 2 + nw - 0.2, A / 2 + nw - 0.2
    m.merge(S.sweep([(mx, -Hl, mz), (mx, 4.0, mz)], S.circle(0.04, [8, 5, 4][lod]), "red"))
    sock = S.lathe([(0.0, 0.25), (0.6, 0.20), (1.2, 0.15), (1.8, 0.11)], [10, 6, 4][lod], tag="sock", caps=(True, False))
    m.merge(S.along(sock, (-0.9, -0.25, -0.35), (mx, 3.85, mz)))
    if lod < 2:
        m.merge(S.lathe([(3.85 - 0.02, 0.27), (3.85 + 0.02, 0.27)], 10, tag="steel").transformed(np.eye(3), (mx - 0.12, 0, mz)))
    # the access stair down the -Z side to the roof, its gate in the net's gap, the hose box
    sx = -A / 2 + 2.0
    steps = 9
    for k in range(steps):
        y = -k * Hl / steps - Hl / steps
        z = -A / 2 - nw - 0.30 - k * 0.25
        m.merge(S.box((sx, y, z), (0.45, 0.02, 0.13), "steel"))
    for s in (1, -1):
        m.merge(S.sweep([(sx + s * 0.48, 0.0, -A / 2 - nw - 0.2), (sx + s * 0.48, -Hl, -A / 2 - nw - 0.30 - steps * 0.25)], [(-0.01, -0.10), (0.01, -0.10), (0.01, 0.10), (-0.01, 0.10)], "steel", up=(1, 0, 0)))
        if lod < 2:
            m.merge(S.sweep([(sx + s * 0.50, 1.0, -A / 2 - nw - 0.2), (sx + s * 0.50, -Hl + 1.0, -A / 2 - nw - 0.30 - steps * 0.25)], S.circle(0.02, 5), "steel"))
    m.merge(S.box((sx, -0.02, -A / 2 - nw / 2 - 0.1), (0.5, 0.02, nw / 2 + 0.1), "steel"))     # the walkway over the net to the stair
    if lod < 2:
        m.merge(_cb((sx + 1.4, 0.45, -A / 2 + 0.3), (0.40, 0.45, 0.15), 0.01, "red", lod))
    return {"body": Part(m)}


def _paint_pad(P, N, tag, tags, state, col):
    """The H in its circle, the touchdown ring, the edge's line, in white on the dark deck."""
    sel = (tag == tags.index("deck")) & (N[:, 1] > 0.8)
    r = np.hypot(P[:, 0], P[:, 2])
    ring = (np.abs(r - 5.0) < 0.25)
    circle = (np.abs(r - 3.2) < 0.15)
    hx, hz = np.abs(P[:, 0]), np.abs(P[:, 2])
    H = ((hx > 0.9) & (hx < 1.4) & (hz < 1.8)) | ((hx < 0.9) & (hz < 0.25))
    edge = (np.maximum(hx, hz) > PAD["size"] / 2 - 0.35) & (np.maximum(hx, hz) < PAD["size"] / 2 - 0.15)
    white = np.array([0.92, 0.92, 0.90], np.float32)
    yellow = np.array([0.90, 0.75, 0.15], np.float32)
    col = np.where((sel & (circle | H | edge))[:, None], white, col)
    return np.where((sel & ring)[:, None], yellow, col)


ELEMENTS = {
    "helipad": dict(build=helipad, materials=materials(), extra=_paint_pad, extra_first=True, uv_scale={"deck": 2.0},
                    states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.006, close=(0.0, 0.2, -6.0), tex=2048),
}
