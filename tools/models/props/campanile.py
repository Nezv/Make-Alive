"""The town hall's campanile (S214). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

campanile: the square stone lantern on the central pavilion's roof: a base with its cornice and,
on the front, the clock in a stone surround with its dial, numerals and hands (painted, stopped);
the open stage of four corner piers with pilasters and round arches on each face, the bell hung on
its beam inside; the entablature; the dome à l'impériale in lead with ribs at its corners; a small
lantern, the finial, two flagstaffs leaning out of the front.

Standing on y = 0 (the pavilion's ridge), the front -Z.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

CAMP = dict(w=3.00, base=1.80, stage=2.60, ent=0.45, dome=2.10)


def materials():
    return {
        "stone": Material((0.82, 0.78, 0.68), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "lead": Material((0.48, 0.50, 0.52), under=(0.45, 0.46, 0.47), bare=(0.55, 0.56, 0.57), chip=0.0, rusts=False, grain=0.06),
        "bronze": Material((0.42, 0.36, 0.22), under=(0.4, 0.32, 0.2), bare=(0.55, 0.45, 0.28), chip=0.0, rusts=False, grain=0.05, fades=False),
        "dial": Material((0.90, 0.88, 0.82), kind="paper", chip=0.0, rusts=False, grain=0.03),
        "iron": Material((0.10, 0.10, 0.11), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.06),
        "timber": Material((0.36, 0.28, 0.20), kind="wood", chip=0.0, rusts=False, grain=0.2),
        "dark": Material((0.08, 0.08, 0.09), chip=0.0, rusts=False, grain=0.02, fades=False),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


def campanile(lod):
    w, hb, hs, he, hd = CAMP["w"], CAMP["base"], CAMP["stage"], CAMP["ent"], CAMP["dome"]
    m = Mesh()
    # the base and its cornice
    m.merge(S.box((0, hb / 2, 0), (w / 2, hb / 2, w / 2), "stone"))
    m.merge(_cb((0, hb + 0.08, 0), (w / 2 + 0.12, 0.08, w / 2 + 0.12), 0.02, "stone", lod))
    # the clock in its surround on the front
    cy = hb * 0.52
    n = [32, 16, 10][lod]
    m.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.62), (0.08, 0.62), (0.10, 0.55), (0.10, 0.0)], n, tag="stone"), (0, 0, -1), (0, cy, -w / 2)))
    m.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.50), (0.003, 0.50), (0.003, 0.0)], n, tag="dial"), (0, 0, -1), (0, cy, -w / 2 - 0.10)))
    if lod < 2:  # the hands, stopped at twenty past four
        for ang, ln, wd in ((np.radians(90 - 4.33 * 30), 0.26, 0.022), (np.radians(90 - 20 * 6), 0.40, 0.014)):
            d = np.array([np.cos(ang), np.sin(ang), 0.0])
            m.merge(S.sweep([(0, cy, -w / 2 - 0.108), tuple(np.array([0, cy, -w / 2 - 0.108]) + d * ln)], [(-wd, -0.003), (wd, -0.003), (wd, 0.003), (-wd, 0.003)], "iron", up=(0, 0, -1)))
        m.merge(S.along(S.lathe([(0.0, 0.03), (0.01, 0.03), (0.012, 0.0)], 8, tag="iron"), (0, 0, -1), (0, cy, -w / 2 - 0.11)))
    # the open stage: four corner piers, each face an arch on its imposts
    y0 = hb + 0.16
    pw = 0.55
    for sx in (1, -1):
        for sz in (1, -1):
            m.merge(S.box((sx * (w / 2 - pw / 2), y0 + hs / 2, sz * (w / 2 - pw / 2)), (pw / 2, hs / 2, pw / 2), "stone"))
            if lod < 2:  # pilasters on both outer faces
                m.merge(S.box((sx * (w / 2 - pw / 2), y0 + hs / 2, sz * (w / 2 + 0.03)), (0.16, hs / 2, 0.03), "stone"))
                m.merge(S.box((sx * (w / 2 + 0.03), y0 + hs / 2, sz * (w / 2 - pw / 2)), (0.03, hs / 2, 0.16), "stone"))
    span = w - 2 * pw
    spring = y0 + hs - span / 2 - 0.20
    na = [12, 8, 4][lod]
    for k in range(4):
        R = S.rotation((0, 1, 0), k * np.pi / 2)
        face = Mesh()
        # the spandrel over the arch, the arch's ring, the imposts
        outline = [(-span / 2, spring)] + [(np.cos(a) * span / 2, spring + np.sin(a) * span / 2) for a in np.linspace(np.pi, 0, na + 1)][1:-1] + \
                  [(span / 2, spring), (span / 2, y0 + hs), (-span / 2, y0 + hs)]
        face.merge(S.extrude(outline, pw, 0.0, "stone", origin=(0, 0, -w / 2 + pw), right=(1, 0, 0), up=(0, 1, 0)))
        if lod < 2:
            ring = [(np.cos(a) * (span / 2 + 0.06), spring + np.sin(a) * (span / 2 + 0.06), -w / 2 - 0.02) for a in np.linspace(np.pi, 0, na + 1)]
            face.merge(S.sweep(ring, [(-0.08, -0.03), (0.08, -0.03), (0.08, 0.03), (-0.08, 0.03)], "stone", up=(0, 0, -1)))
            for s in (1, -1):
                face.merge(S.box((s * (span / 2 + 0.02), spring - 0.04, -w / 2 + pw / 2), (0.06, 0.05, pw / 2 + 0.03), "stone"))
            # a low balustrade rail across the arch's foot
            face.merge(S.box((0, y0 + 0.45, -w / 2 + pw / 2), (span / 2, 0.05, pw / 2 - 0.05), "stone"))
            for j in range([7, 4][lod]):
                x = -span / 2 + 0.12 + j * (span - 0.24) / ([7, 4][lod] - 1)
                face.merge(S.lathe([(y0, 0.05), (y0 + 0.08, 0.07), (y0 + 0.25, 0.04), (y0 + 0.40, 0.06)], 6, tag="stone").transformed(np.eye(3), (x, 0, -w / 2 + pw / 2)))
        m.merge(face.transformed(R, (0, 0, 0)))
    # the floor of the stage and its bell on the beam
    m.merge(S.box((0, y0 + 0.02, 0), (w / 2 - 0.05, 0.02, w / 2 - 0.05), "stone"))
    if lod < 2:
        m.merge(S.box((0, y0 + hs - 0.45, 0), (w / 2 - pw, 0.08, 0.10), "timber"))
        yb = y0 + hs - 0.53 - 0.78                          # the bell's mouth; it hangs from the beam
        bell = [(yb, 0.40), (yb + 0.06, 0.38), (yb + 0.25, 0.27), (yb + 0.55, 0.22), (yb + 0.70, 0.18), (yb + 0.76, 0.10), (yb + 0.78, 0.0)]
        m.merge(S.lathe(bell, [16, 10][lod], tag="bronze"))
    # the entablature
    ye = y0 + hs
    m.merge(S.box((0, ye + he / 2, 0), (w / 2 + 0.04, he / 2, w / 2 + 0.04), "stone"))
    m.merge(_cb((0, ye + he - 0.06, 0), (w / 2 + 0.16, 0.06, w / 2 + 0.16), 0.02, "stone", lod))
    # the dome à l'impériale: a square ogee in lead, ribs at the corners
    yd = ye + he
    prof = [(0.0, 1.0), (0.15, 0.98), (0.35, 0.90), (0.55, 0.72), (0.70, 0.55), (0.80, 0.45), (0.90, 0.30), (1.0, 0.15)]
    if lod == 2:
        prof = [(0.0, 1.0), (0.5, 0.80), (1.0, 0.15)]
    sq = (w / 2) * np.sqrt(2)
    dome = S.lathe([(yd + t * hd, r * sq) for t, r in prof], 4, turn=np.pi / 4, tag="lead", caps=(True, False))
    m.merge(dome)
    if lod < 2:
        for k in range(4):
            a = np.pi / 4 + k * np.pi / 2
            rib = [(np.cos(a) * r * sq * 1.01, yd + t * hd, np.sin(a) * r * sq * 1.01) for t, r in prof]
            m.merge(S.sweep(rib, S.circle(0.05, 5), "lead"))
    # the small lantern on top, the finial, the flagstaffs leaning out of the front
    yl = yd + hd
    m.merge(S.lathe([(yl - 0.02, 0.32), (yl + 0.45, 0.30), (yl + 0.50, 0.38), (yl + 0.62, 0.0)], [8, 6, 4][lod], tag="lead"))
    m.merge(S.lathe([(yl + 0.60, 0.04), (yl + 1.10, 0.02), (yl + 1.15, 0.06), (yl + 1.25, 0.0)], [8, 6, 4][lod], tag="bronze"))
    if lod < 2:
        for s in (1, -1):
            m.merge(S.sweep([(s * 0.8, hb + 0.20, -w / 2 - 0.12), (s * 1.6, hb + 2.60, -w / 2 - 1.10)], S.circle(0.03, 5), "iron"))
    return {"body": Part(m)}


def _paint_clock(P, N, tag, tags, state, col):
    """The dial's hour marks and Roman numerals at XII, III, VI, IX."""
    w, hb = CAMP["w"], CAMP["base"]
    cy = hb * 0.52
    sel = (tag == tags.index("dial")) & (N[:, 2] < -0.5)
    rel = P[:, :2] - np.array([0.0, cy])
    r = np.hypot(rel[:, 0], rel[:, 1])
    ang = np.mod(np.arctan2(rel[:, 1], rel[:, 0]), 2 * np.pi / 12)
    marks = (r > 0.43) & (r < 0.48) & ((ang < 0.02) | (ang > 2 * np.pi / 12 - 0.02))
    words = np.zeros(len(P), bool)
    z = -w / 2 - 0.103
    for text, (x, y) in (("XII", (0, 0.35)), ("III", (-0.35, 0)), ("VI", (0, -0.35)), ("IX", (0.35, 0))):
        words |= lettering.mask(P, text, np.array([x, cy + y - 0.035, z], np.float32), 0.07, (-1, 0, 0), (0, 1, 0), weight=1.3)
    return np.where((sel & (marks | words))[:, None], np.array([0.08, 0.08, 0.09], np.float32), col)


ELEMENTS = {
    "campanile": dict(build=campanile, materials=materials(), extra=_paint_clock, extra_first=True, uv_scale={"dial": 3.0},
                      states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.006, close=(0.0, 1.0, -1.6), tex=2048),
}
