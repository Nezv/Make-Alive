"""The jardin public (S190). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

bandstand: the octagonal kiosque à musique (small, large): a stone base 0.9 m high with its
cornice and steps on the front, eight slender cast-iron columns, a railing between them, curved
brackets and a frieze under the eaves, the tent roof of green zinc with its pale ceiling, a lantern
and finial on top.

Standing on y = 0, the steps at the front (-Z), x = z = 0 the middle.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

BAND = dict(r=3.00, base=0.90, col=2.70, eave=3.75, top=5.00)


def materials():
    return {
        "stone": Material((0.72, 0.68, 0.60), kind="stone", chip=0.0, rusts=False, grain=0.14),
        "iron": Material((0.14, 0.28, 0.22), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.07),
        "zinc": Material((0.20, 0.36, 0.30), under=(0.45, 0.47, 0.46), bare=(0.50, 0.52, 0.52), chip=0.3, grain=0.05),
        "ceiling": Material((0.88, 0.84, 0.74), under=(0.6, 0.55, 0.5), bare=(0.5, 0.4, 0.3), kind="wood", chip=0.5, grain=0.06),
        "floor": Material((0.55, 0.45, 0.32), kind="wood", chip=0.0, rusts=False, grain=0.12),
        "chair": Material((0.33, 0.45, 0.32), under=(0.45, 0.30, 0.20), bare=(0.35, 0.22, 0.14), chip=0.6, grain=0.06),
        "water": Material((0.10, 0.16, 0.13), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "gilt": Material((0.80, 0.62, 0.25), under=(0.14, 0.14, 0.13), bare=(0.30, 0.18, 0.10), chip=0.3, grain=0.04),
        "black": Material((0.07, 0.08, 0.08), under=(0.35, 0.22, 0.14), bare=(0.30, 0.18, 0.10), chip=0.4, grain=0.05),
    }


def _corner(k, r):
    a = -np.pi / 2 + np.pi / 8 + k * np.pi / 4      # corners either side of the front face's middle (-Z)
    return np.array([np.cos(a) * r, 0.0, np.sin(a) * r])


def bandstand(lod):
    r, hb, hc, he, ht = BAND["r"], BAND["base"], BAND["col"], BAND["eave"], BAND["top"]
    m = Mesh()
    turn = np.pi / 8 - np.pi / 2   # the lathes' corners on _corner's
    # the base: plinth, wall, cornice; the wooden floor
    m.merge(S.lathe([(0.0, r + 0.10), (0.20, r + 0.10), (0.22, r), (hb - 0.10, r), (hb - 0.08, r + 0.08), (hb, r + 0.08)], 8, turn=turn, tag="stone"))
    m.merge(S.lathe([(hb, r), (hb + 0.01, r), (hb + 0.01, 0.0)], 8, turn=turn, tag="floor", caps=(False, False)))
    # the steps up to the front face
    face_w = 2 * r * np.sin(np.pi / 8)
    apo = r * np.cos(np.pi / 8)
    for k in range(4):
        y = hb * (k + 1) / 5
        m.merge(S.box((0, y / 2, -apo - 0.15 - (3 - k) * 0.28), (face_w / 2 * 0.8, y / 2, 0.15), "stone"))
    # the columns at the corners, their capitals and brackets
    sides = [10, 6, 4][lod]
    rc = r - 0.15
    for k in range(8):
        c = _corner(k, rc)
        col = S.lathe([(hb, 0.09), (hb + 0.12, 0.07), (hb + 0.16, 0.05), (hb + hc - 0.15, 0.045), (hb + hc - 0.08, 0.08), (hb + hc, 0.08)], sides, tag="iron")
        m.merge(col.transformed(np.eye(3), (c[0], 0, c[2])))
        if lod < 2:  # a curved bracket out and up to the eaves, one each side along the faces
            for kk in (k - 1, k + 1):
                n = _corner(kk, rc)
                mid = (c + n) / 2
                d = (mid - c) * 0.45
                pts = [c + np.array([0, hb + hc - 0.35, 0]), c + d * 0.5 + np.array([0, hb + hc - 0.10, 0]), c + d + np.array([0, hb + hc + 0.02, 0])]
                m.merge(S.sweep(pts, [(-0.012, -0.012), (0.012, -0.012), (0.012, 0.012), (-0.012, 0.012)], "iron"))
    # the railing between the columns (not across the steps), the frieze under the eaves
    for k in range(8):
        a, b = _corner(k, rc), _corner(k + 1, rc)
        front = abs(((a + b) / 2)[0]) < 0.1 and ((a + b) / 2)[2] < 0
        if not front:
            for y in (hb + 0.10, hb + 0.95):
                m.merge(S.sweep([a + np.array([0, y, 0]), b + np.array([0, y, 0])], [(-0.02, -0.015), (0.02, -0.015), (0.02, 0.015), (-0.02, 0.015)], "iron"))
            if lod < 2:
                n = [10, 4][lod]
                for i in range(1, n):
                    p = a + (b - a) * i / n
                    m.merge(S.box((p[0], hb + 0.52, p[2]), (0.008, 0.42, 0.008), "iron"))
        m.merge(S.sweep([a + np.array([0, hb + hc, 0]), b + np.array([0, hb + hc, 0])], [(-0.03, -0.10), (0.03, -0.10), (0.03, 0.10), (-0.03, 0.10)], "iron"))
    # the roof: zinc tent from its eave out over the columns up to the lantern; the ceiling under it
    m.merge(S.lathe([(he - 0.05, r + 0.35), (he, r + 0.35), (he + 0.20, r + 0.10), (ht - 0.35, 0.55), (ht - 0.30, 0.55)], 8, turn=turn, tag="zinc", caps=(False, False)))
    ceil = S.lathe([(ht - 0.6, 0.0), (hb + hc + 0.12, rc), (he - 0.05, r + 0.35)], 8, turn=turn, tag="ceiling", caps=(False, False))
    m.merge(ceil)
    # the lantern and finial
    m.merge(S.lathe([(ht - 0.30, 0.45), (ht - 0.05, 0.40), (ht, 0.45), (ht + 0.05, 0.25), (ht + 0.35, 0.05), (ht + 0.60, 0.0)], 8, turn=turn, tag="zinc"))
    if lod < 2:
        m.merge(S.lathe([(ht + 0.55, 0.03), (ht + 0.62, 0.05), (ht + 0.70, 0.03), (ht + 0.95, 0.0)], 6, tag="iron"))
    return {"body": Part(m)}


# --- park_chair -------------------------------------------------------------------------------------------
def park_chair(lod):
    w, sh, bh, d = CHAIR["w"], CHAIR["seat"], CHAIR["back"], CHAIR["d"]
    m = Mesh()
    bar = [(-0.011, -0.004), (0.011, -0.004), (0.011, 0.004), (-0.011, 0.004)]
    rod = S.circle(0.009, [6, 5, 4][lod])
    for s in (1, -1):
        x = s * w / 2
        # the back leg runs up into the back's side, raked; the front leg splays out a little
        back = [(x * 1.06, 0.0, d / 2 + 0.04), (x, sh, d / 2 - 0.02), (x * 0.98, sh + 0.20, d / 2 + 0.03), (x * 0.95, bh, d / 2 + 0.10)]
        m.merge(S.sweep(S.fillet(back, 0.06, 3) if lod < 2 else back, rod, "chair"))
        m.merge(S.sweep([(x * 1.06, 0.0, -d / 2 - 0.03), (x, sh, -d / 2 + 0.02)], rod, "chair"))
        # the seat's side rail, and the stretcher low between the legs
        m.merge(S.sweep([(x, sh - 0.015, -d / 2 + 0.02), (x, sh - 0.015, d / 2 - 0.02)], bar, "chair", up=(1, 0, 0)))
        if lod < 2:
            m.merge(S.sweep([(x * 1.04, 0.12, -d / 2 + 0.0), (x * 1.04, 0.12, d / 2 + 0.01)], S.circle(0.006, 4), "chair"))
    # the seat: slats across, dipping in the middle; the back: curved slats, hollowed for the back
    nseat = [8, 5, 3][lod]
    for i in range(nseat):
        z = -d / 2 + 0.04 + i * (d - 0.08) / (nseat - 1)
        dip = 0.012 * np.sin(np.pi * (i + 0.5) / nseat)
        sl = [(-w / 2 + 0.01, sh, z), (0, sh - dip - 0.008, z), (w / 2 - 0.01, sh, z)]
        m.merge(S.sweep(sl, [(-0.018, -0.006), (0.018, -0.006), (0.018, 0.0), (-0.018, 0.0)], "chair", up=(0, 1, 0)))
    nback = [5, 3, 2][lod]
    for i in range(nback):
        t = (i + 0.5) / nback
        y = sh + 0.12 + t * (bh - sh - 0.16)
        z = d / 2 + 0.03 + t * 0.06
        sl = [(-w / 2 * 0.97, y, z), (0, y, z + 0.035), (w / 2 * 0.97, y, z)]
        m.merge(S.sweep(sl, [(-0.004, -0.014), (0.004, -0.014), (0.004, 0.014), (-0.004, 0.014)], "chair", up=(0, 1, 0)))
    if lod == 0:  # the feet's caps
        for sx in (1, -1):
            for z in (-d / 2 - 0.03, d / 2 + 0.04):
                m.merge(S.prism((sx * w / 2 * 1.06, 0.006, z), 0.014, 0.012, 6, tag="black"))
    return {"body": Part(m)}


# --- park_basin --------------------------------------------------------------------------------------------
def park_basin(lod):
    R, h = BASIN["r"], BASIN["rim"]
    n = [48, 28, 16][lod]
    m = Mesh()
    # the rim: a broad stone roll over a low wall, its inner face going down into the water
    rim = [(0.0, R + 0.05), (0.08, R + 0.05), (0.10, R), (h - 0.12, R), (h - 0.06, R + 0.05), (h - 0.02, R + 0.06), (h, R + 0.03),
           (h + 0.01, R - 0.10), (h, R - 0.30), (h - 0.06, R - 0.36), (h - 0.14, R - 0.36), (h - 0.18, R - 0.32)]
    if lod == 2:
        rim = [(0.0, R + 0.05), (h, R + 0.05), (h, R - 0.32), (h - 0.18, R - 0.32)]
    m.merge(S.lathe(rim, n, tag="stone", caps=(False, False)))
    # the water, the rim's foot under it: one disc
    wy = h - 0.18
    m.merge(S.lathe([(wy, R - 0.32), (wy, 0.0)], n, tag="water", caps=(False, False)))
    # the vasque in the middle: a pedestal, a shallow bowl with a lip, the jet's nozzle
    vp = [(wy - 0.01, 0.42), (wy + 0.12, 0.40), (wy + 0.18, 0.28), (wy + 0.60, 0.18), (wy + 0.66, 0.24), (wy + 0.70, 0.18),
          (wy + 0.78, 0.30), (wy + 0.92, 0.72), (wy + 0.98, 0.80), (wy + 1.02, 0.78), (wy + 1.00, 0.70), (wy + 0.96, 0.10),
          (wy + 1.12, 0.06), (wy + 1.30, 0.03), (wy + 1.32, 0.0)]
    if lod == 2:
        vp = [(wy, 0.40), (wy + 0.60, 0.18), (wy + 1.00, 0.80), (wy + 0.98, 0.0)]
    m.merge(S.lathe(vp, [24, 14, 8][lod], tag="stone", caps=(False, False)))
    if lod < 2:  # the water held in the bowl, its bronze nozzle
        m.merge(S.lathe([(wy + 0.97, 0.70), (wy + 0.97, 0.0)], [24, 14][lod], tag="water", caps=(False, False)))
    return {"body": Part(m)}


# --- park_gate ----------------------------------------------------------------------------------------------
def _pier(x, lod):
    """A stone pier: plinth, shaft with a sunk panel, cornice, a cap and its urn."""
    p, H = GATE["pier"], GATE["pier_h"]
    m = Mesh()
    c = 0.015 if lod == 0 else 0.0
    m.merge(S.chamfer_box((x, 0.20, 0), (p / 2 + 0.05, 0.20, p / 2 + 0.05), c, "stone") if c else S.box((x, 0.20, 0), (p / 2 + 0.05, 0.20, p / 2 + 0.05), "stone"))
    m.merge(S.box((x, 0.40 + (H - 0.80) / 2, 0), (p / 2, (H - 0.80) / 2, p / 2), "stone"))
    m.merge(S.chamfer_box((x, H - 0.30, 0), (p / 2 + 0.07, 0.10, p / 2 + 0.07), c, "stone") if c else S.box((x, H - 0.30, 0), (p / 2 + 0.07, 0.10, p / 2 + 0.07), "stone"))
    m.merge(S.box((x, H - 0.10, 0), (p / 2 + 0.03, 0.10, p / 2 + 0.03), "stone"))
    if lod < 2:
        for zf in (-1, 1):  # the sunk panels front and back
            m.merge(S.box((x, 0.40 + (H - 0.80) / 2, zf * (p / 2 + 0.004)), (p / 2 - 0.08, (H - 0.80) / 2 - 0.12, 0.004), "stone"))
    urn = [(0.0, 0.16), (0.06, 0.16), (0.08, 0.08), (0.18, 0.07), (0.26, 0.20), (0.42, 0.24), (0.50, 0.20), (0.54, 0.22), (0.58, 0.10), (0.70, 0.04), (0.74, 0.0)]
    if lod == 2:
        urn = [(0.0, 0.16), (0.40, 0.24), (0.74, 0.0)]
    m.merge(S.lathe(urn, [12, 8, 6][lod], tag="stone").transformed(np.eye(3), (x, H, 0)))
    return m


def _leaf(x0, x1, lod):
    """One leaf from x0 (its hanging stile) to x1 (the meeting stile): rails, bars with gilt spears,
    a dog-bar panel at the foot, a frieze of rings, scrolls under the top rail."""
    H = GATE["leaf_h"]
    m = Mesh()
    flat = [(-0.025, -0.012), (0.025, -0.012), (0.025, 0.012), (-0.025, 0.012)]
    for x in (x0, x1):
        m.merge(S.sweep([(x, 0.05, 0), (x, H, 0)], flat, "black", up=(0, 0, 1)))
    rails = (0.08, 0.40, 0.55, H - 0.30) if lod < 2 else (0.08, H - 0.30)
    for y in rails:
        m.merge(S.sweep([(x0, y, 0), (x1, y, 0)], flat, "black", up=(0, 0, 1)))
    lo, hi = min(x0, x1), max(x0, x1)
    nb = int((hi - lo) / [0.12, 0.18, 0.36][lod])
    for i in range(nb):
        x = lo + (i + 0.5) * (hi - lo) / nb
        top = H + 0.20 + 0.25 * np.sin(np.pi * (x - lo) / (hi - lo)) ** 2 * (1 if x0 < x1 else 1)
        m.merge(S.sweep([(x, 0.08, 0), (x, top, 0)], S.circle(0.012, [6, 4, 4][lod]), "black"))
        if lod < 2:  # the spear
            m.merge(S.lathe([(0.0, 0.0), (0.02, 0.025), (0.09, 0.0)], [6, 4][lod], tag="gilt").transformed(np.eye(3), (x, top, 0)))
            if lod == 0 and i % 2 == 0:  # the dog bars between, short
                m.merge(S.sweep([(x + (hi - lo) / nb / 2, 0.08, 0), (x + (hi - lo) / nb / 2, 0.40, 0)], S.circle(0.009, 4), "black"))
    if lod == 0:  # the frieze of rings between the middle rails, the scrolls under the top rail
        for i in range(nb):
            x = lo + (i + 0.5) * (hi - lo) / nb
            ring = [(x + np.cos(a) * 0.06, 0.475 + np.sin(a) * 0.06, 0) for a in np.linspace(0, 2 * np.pi, 11)[:-1]]
            m.merge(S.sweep(ring, S.circle(0.007, 4), "gilt", closed=True, up=(0, 0, 1)))
        for i in range(nb // 2):
            x = lo + (2 * i + 1) * (hi - lo) / nb
            sc = [(x + 0.10 * np.cos(a) * (1 - a / 9), H - 0.42 + 0.10 * np.sin(a) * (1 - a / 9), 0) for a in np.linspace(0, 1.6 * np.pi, 10)]
            m.merge(S.sweep(sc, S.circle(0.008, 4), "gilt", up=(0, 0, 1)))
    return m


def park_gate(lod):
    W, p, Hp = GATE["w"], GATE["pier"], GATE["pier_h"]
    m = Mesh()
    xp = W / 2 + p / 2
    for s in (1, -1):
        m.merge(_pier(s * xp, lod))
    # the overthrow: an arch of bars between the piers, scrolls in it, the gilt crest at its crown
    if lod < 2:
        arch = [(x, Hp + 0.35 + 0.55 * np.cos(np.pi * x / W) ** 1.5, 0) for x in np.linspace(-W / 2, W / 2, [15, 7][lod])]
        flat = [(-0.025, -0.012), (0.025, -0.012), (0.025, 0.012), (-0.025, 0.012)]
        m.merge(S.sweep(arch, flat, "black", up=(0, 0, 1)))
        m.merge(S.sweep([(-W / 2, Hp + 0.30, 0), (W / 2, Hp + 0.30, 0)], flat, "black", up=(0, 0, 1)))
        for s in (1, -1):
            m.merge(S.sweep([(s * W / 2, Hp - 0.40, 0), (s * W / 2, Hp + 0.40, 0)], flat, "black", up=(0, 0, 1)))
        if lod == 0:
            for s in (1, -1):
                for k in range(3):
                    cx = s * (0.35 + k * 0.45)
                    cy = Hp + 0.30 + 0.20 * (1 - k / 3)
                    sc = [(cx + s * 0.14 * np.cos(a) * (1 - a / 10), cy + 0.14 * np.sin(a) * (1 - a / 10), 0) for a in np.linspace(0, 1.7 * np.pi, 12)]
                    m.merge(S.sweep(sc, S.circle(0.009, 4), "gilt", up=(0, 0, 1)))
        crest = S.lathe([(0.0, 0.0), (0.05, 0.16), (0.30, 0.20), (0.45, 0.10), (0.55, 0.0)], [10, 6][lod], tag="gilt")
        m.merge(crest.transformed(np.diag([1.0, 1.0, 0.18]), (0, Hp + 0.85, 0)))
    parts = {"body": Part(m)}
    for name, x0, x1, side in (("leaf_l", -W / 2, -0.01, 1), ("leaf_r", W / 2, 0.01, -1)):
        parts[name] = Part(_leaf(x0, x1, lod), (x0, 0.0, 0.0), {"rotate": [[0, 1, 0], -95.0 * side]})
    return parts


CHAIR = dict(w=0.44, seat=0.43, back=0.84, d=0.46)
BASIN = dict(r=3.00, rim=0.50)
GATE = dict(w=3.60, pier=0.70, pier_h=3.10, leaf_h=2.40)

ELEMENTS = {
    "park_chair": dict(build=park_chair, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.002,
                       close=(0.0, 0.5, 0.0)),
    "park_basin": dict(build=park_basin, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.008,
                       close=(0.0, 0.5, -3.0)),
    "park_gate": dict(build=park_gate, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.003,
                      close=(0.0, 2.0, 0.0)),
    "bandstand": dict(build=bandstand, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.008,
                      close=(0.0, 2.5, -2.8)),
}
