"""The market fountain (S187). Card and references: references/elements/market_fountain.md; the
workflow: references/elements/WORKFLOW.md.

market_fountain: the place du Marché's fountain, a column of about 1800 in the manner of whole.jpg
(an invented town's, smaller): a wide round basin with its rim and still water, a square inner
tier with a lion-mask spout on each face pouring into it, the pedestal with its cornice and the
four couchant beasts at its corners, the column's base, a shaft banded with four gilt bracelets,
a capital of palm leaves, a globe, and the gilt Victory on it with her arms raised holding two
wreaths. The figure is a blockout here (round 4 makes it a low-poly sculpture).

Standing on y = 0, the middle at x = z = 0, the inscription's face -Z.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

BASIN = dict(r=4.4, rim=0.55, wall=0.35, water=0.38)
TIER = dict(w=3.0, h=1.10)
PED = dict(w=1.70, h=2.40)
COL = dict(base=0.30, h=6.6, r=(0.46, 0.38))
INSCRIPTION = ("FONTAINE DU MARCHE", "AN XI")     # invented


def materials():
    return {
        "stone": Material((0.74, 0.71, 0.64), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "water": Material((0.16, 0.20, 0.20), kind="glass", chip=0.0, rusts=False, grain=0.04, sheds=False, fades=False),
        "gilt": Material((0.82, 0.62, 0.22), under=(0.45, 0.32, 0.15), bare=(0.35, 0.28, 0.18), chip=0.3, rusts=False, grain=0.05, fades=False),
        "bronze": Material((0.22, 0.30, 0.24), under=(0.40, 0.30, 0.18), bare=(0.40, 0.30, 0.18), chip=0.0, rusts=False, grain=0.08),
        "dark": Material((0.06, 0.06, 0.06), chip=0.0, rusts=False, grain=0.02, fades=False),
    }


def _box(c, h, tag, cham=0.0, edges="top"):
    return S.chamfer_box(c, h, cham, tag, edges=edges) if cham else S.box(c, h, tag)


def _victory(y0, lod):
    """The Victory on her globe: a robe, the body, the head, the arms raised, two wreaths, wings."""
    m = Mesh()
    sides = [10, 6, 4][lod]
    robe = S.lathe([(0.0, 0.22), (0.15, 0.20), (0.75, 0.16), (1.05, 0.13), (1.25, 0.15), (1.45, 0.12), (1.52, 0.06)], sides, tag="gilt")
    m.merge(robe.transformed(np.diag([1.0, 1.0, 0.8]), (0, y0, 0)))
    m.merge(S.lathe([(1.52, 0.05), (1.58, 0.09), (1.70, 0.09), (1.76, 0.0)], sides, tag="gilt").transformed(np.eye(3), (0, y0, 0)))  # the head
    for s in (1, -1):  # arms up and out, a wreath held in each hand
        sh = np.array([s * 0.15, y0 + 1.40, 0.0])
        hand = np.array([s * 0.42, y0 + 2.05, -0.05])
        m.merge(S.sweep([sh, sh + np.array([s * 0.12, 0.30, 0.0]), hand], S.circle(0.045, [6, 4, 3][lod]), "gilt"))
        if lod < 2:
            ring = [hand + np.array([np.cos(a) * 0.14, 0.12 + np.sin(a) * 0.14, 0.0]) for a in np.linspace(0, 2 * np.pi, [12, 6][lod] + 1)[:-1]]
            m.merge(S.sweep(ring, S.circle(0.03, 4), "gilt", closed=True, up=(0, 0, 1)))
        # the wings: a feathered blade from the shoulders up and back
        wing = [(0.0, 0.0), (0.10, 0.25), (0.28, 0.80), (0.24, 1.05), (0.12, 0.85), (0.02, 0.45)]
        m.merge(S.extrude([(s * x, y) for x, y in (wing if s > 0 else wing[::-1])], 0.04, 0.0, "gilt",
                          origin=(s * 0.08, y0 + 0.95, 0.12), right=(1, 0, 0), up=(0, 1, 0)).transformed(S.rotation((0, 1, 0), s * 0.35), (0, 0, 0)))
    return m


def market_fountain(lod):
    r, rim, wall, wl = BASIN["r"], BASIN["rim"], BASIN["wall"], BASIN["water"]
    tw, th = TIER["w"], TIER["h"]
    pw, ph = PED["w"], PED["h"]
    sides = [32, 16, 10][lod]
    m = Mesh()
    # the basin: its rim's wall round, its moulded top, the water and the basin's floor
    m.merge(S.lathe([(0.0, r + 0.10), (0.08, r + 0.10), (0.10, r), (rim - 0.06, r), (rim - 0.02, r + 0.05), (rim, r + 0.05), (rim, r - wall),
                     (wl, r - wall)], sides, tag="stone", caps=(False, False)))
    m.merge(S.lathe([(wl, r - wall), (wl, 0.0)], sides, tag="water", caps=(False, False)))
    # the inner tier, its four lion masks and their spouts
    m.merge(_box((0, th / 2, 0), (tw / 2, th / 2, tw / 2), "stone", 0.03 if lod == 0 else 0.0))
    m.merge(_box((0, th + 0.05, 0), (tw / 2 + 0.08, 0.05, tw / 2 + 0.08), "stone", 0.02 if lod == 0 else 0.0))
    for k in range(4):
        R = S.rotation((0, 1, 0), k * np.pi / 2)
        f = Mesh()
        if lod < 2:
            f.merge(S.lathe([(0.0, 0.18), (0.06, 0.16), (0.12, 0.08), (0.14, 0.0)], [10, 6][lod], tag="bronze").transformed(S.rotation((1, 0, 0), -np.pi / 2), (0, th * 0.6, -tw / 2)))
            f.merge(S.prism((0, th * 0.6 - 0.07, -tw / 2 - 0.10), 0.02, 0.12, 6, axis=(0, 0, -1), tag="bronze"))
            if lod == 0:  # the jet falling into the basin: a thin bent stream
                f.merge(S.sweep([(0, th * 0.6 - 0.07, -tw / 2 - 0.22), (0, th * 0.4, -tw / 2 - 0.45), (0, wl + 0.01, -tw / 2 - 0.62)], S.circle(0.018, 4), "water"))
        m.merge(f.transformed(R, (0, 0, 0)))
    # the pedestal: base course, die, cornice; the couchant beasts at its corners
    y = th + 0.10
    m.merge(_box((0, y + 0.15, 0), (pw / 2 + 0.12, 0.15, pw / 2 + 0.12), "stone", 0.02 if lod == 0 else 0.0))
    m.merge(_box((0, y + 0.30 + (ph - 0.55) / 2, 0), (pw / 2, (ph - 0.55) / 2, pw / 2), "stone"))
    m.merge(_box((0, y + ph - 0.125, 0), (pw / 2 + 0.14, 0.125, pw / 2 + 0.14), "stone", 0.03 if lod == 0 else 0.0))
    if lod < 2:
        for sx in (1, -1):
            for sz in (1, -1):
                c = np.array([sx * (tw / 2 - 0.35), th + 0.10, sz * (tw / 2 - 0.35)])
                beast = Mesh()
                beast.merge(S.bevel_box((0, 0.22, 0), (0.18, 0.22, 0.42), 0.08, "stone") if lod == 0 else S.box((0, 0.22, 0), (0.18, 0.22, 0.42), "stone"))
                beast.merge(S.bevel_box((0, 0.58, -0.30), (0.15, 0.16, 0.14), 0.06, "stone") if lod == 0 else S.box((0, 0.58, -0.30), (0.15, 0.16, 0.14), "stone"))
                yaw = np.arctan2(-sx, -sz)   # facing out from the corner
                m.merge(beast.transformed(S.rotation((0, 1, 0), yaw), c))
        m.merge(S.box((0, y + 0.30 + (ph - 0.55) * 0.55, -pw / 2 - 0.004), (pw / 2 - 0.20, 0.28, 0.004), "stone"))   # the inscription's panel
    # the column: base mouldings, the shaft with its bracelets, the palm capital, the globe
    y = th + 0.10 + ph
    cb, ch = COL["base"], COL["h"]
    r0, r1 = COL["r"]
    csides = [16, 10, 6][lod]
    m.merge(S.lathe([(y, r0 + 0.12), (y + 0.08, r0 + 0.12), (y + 0.14, r0 + 0.06), (y + 0.22, r0 + 0.08), (y + cb, r0)], csides, tag="stone"))
    m.merge(S.lathe([(y + cb, r0), (y + cb + ch, r1)], csides, tag="stone", caps=(False, False)))
    for k in range(4):
        yy = y + cb + ch * (0.18 + 0.2 * k)
        rr = r0 + (r1 - r0) * (yy - y - cb) / ch
        m.merge(S.lathe([(yy - 0.12, rr + 0.03), (yy - 0.10, rr + 0.06), (yy + 0.10, rr + 0.06), (yy + 0.12, rr + 0.03)], csides, tag="gilt", caps=(False, False)))
    yt = y + cb + ch
    leaves = (lambda j, yv: 1.0 + (0.18 if j % 2 else 0.0) * max(0.0, (yv - yt) / 0.7)) if lod == 0 else None
    m.merge(S.lathe([(yt, r1 + 0.02), (yt + 0.25, r1 + 0.10), (yt + 0.55, r1 + 0.32), (yt + 0.70, r1 + 0.40), (yt + 0.72, 0.30), (yt + 0.80, 0.30)],
                    csides * (2 if lod == 0 else 1), flute=leaves, tag="gilt"))
    m.merge(S.lathe([(yt + 0.80, 0.0), (yt + 0.84, 0.18), (yt + 1.0, 0.33), (yt + 1.18, 0.30), (yt + 1.32, 0.15), (yt + 1.35, 0.0)], csides, tag="gilt"))
    m.merge(_victory(yt + 1.32, lod))
    return {"body": Part(m)}


def _paint_fountain(P, N, tag, tags, state, col):
    tw, th = TIER["w"], TIER["h"]
    pw, ph = PED["w"], PED["h"]
    sel = (tag == tags.index("stone")) & (N[:, 2] < -0.5) & (np.abs(P[:, 0]) < pw / 2)
    y = th + 0.10 + 0.30 + (ph - 0.55) * 0.55
    words = lettering.mask(P, INSCRIPTION[0], np.array([0, y + 0.08, -pw / 2 - 0.008], np.float32), 0.075, (-1, 0, 0), (0, 1, 0), weight=1.2) | \
        lettering.mask(P, INSCRIPTION[1], np.array([0, y - 0.10, -pw / 2 - 0.008], np.float32), 0.09, (-1, 0, 0), (0, 1, 0), weight=1.3)
    return np.where((sel & words)[:, None], col * 0.40, col)


ELEMENTS = {
    "market_fountain": dict(build=market_fountain, materials=materials(), extra=_paint_fountain, extra_first=True,
                            states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.006, close=(0.0, 3.0, -1.2), tex=2048),
}
