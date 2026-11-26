"""Street lamps (S166). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

lamp_post: the cast-iron candélabre of the old streets and quays (Marville's photographs of the
1860s, `louvre` and `arts_metiers`): a stone slab, a square pedestal tapering up with a cartouche
on each face and a cornice, a bell with garlands, a collar, leaves round the foot of a square
fluted shaft, a capital, and on it the lantern.
wall_lantern: the same lantern hung from a scrolled iron bracket (potence) on a house's wall, as
the old lanes have them (Bury's porte-lanternes).
The lantern (`_lantern`): a square glass box widening upwards on a pointed foot, corner posts, a
pyramid roof with its eave, a crown and a finial; the burner inside lit (emission).

Coordinates: metres, Y up, the front -Z, x = 0 the middle. lamp_post stands on y = 0; the wall
lantern's wall face is z = 0 (the house is +Z), its lantern's foot y = 0.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

# --- Measurements (the card: louvre at 0.0033 m a pixel, from the lantern's 0.46 m) ---------------
L_FOOT = 0.10            # the lantern's pointed foot under the glass
L_GLASS = (0.31, 0.155, 0.225)  # the glass box: height, half-width at its foot and at its top
L_ROOF = (0.19, 0.24)    # the roof: height, half-width at its eave
L_CROWN = (0.09, 0.065)  # the crown (cheminée): height, half-width
POST = [  # the post's sections bottom up: (y, half-width), each an octagon (a square, corners cut)
    (0.15, 0.31), (0.25, 0.31), (0.25, 0.27), (0.29, 0.27), (0.29, 0.25),   # the iron foot, stepping in
    (0.31, 0.25), (1.03, 0.19),                                            # the pedestal, tapering
    (1.03, 0.215), (1.07, 0.215), (1.07, 0.17),                            # its cornice
    (1.12, 0.165), (1.20, 0.13), (1.28, 0.10), (1.33, 0.085),             # the bell
    (1.33, 0.10), (1.38, 0.10), (1.38, 0.08), (1.50, 0.08), (1.50, 0.10), (1.54, 0.10), (1.54, 0.07),  # the collar
    (2.62, 0.058),                                                          # the shaft
    (2.62, 0.064), (2.66, 0.08), (2.71, 0.10), (2.74, 0.10), (2.74, 0.075), (2.80, 0.075),  # the capital
]
LANTERN_Y = 2.88         # where the lantern's glass starts on the post


def materials():
    return {
        "iron": Material((0.10, 0.13, 0.11), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.7, grain=0.1),
        "stone": Material((0.66, 0.63, 0.57), kind="stone", chip=0.0, rusts=False, grain=0.08),
        "glass": Material((0.30, 0.31, 0.30), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False, emit=(0.85, 0.62, 0.34)),
        "flame": Material((1.0, 0.86, 0.6), kind="glass", chip=0.0, rusts=False, grain=0.0, sheds=False, emit=(1.0, 0.78, 0.45)),
        "brass": Material((0.55, 0.45, 0.24), under=(0.45, 0.36, 0.18), bare=(0.5, 0.4, 0.2), chip=0.2, rusts=False, grain=0.08),
        "fixing": Material((0.12, 0.12, 0.12), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


def _oct(y, h, c=0.22):
    """A square of half-width h at height y with its corners cut (c: the cut's share)."""
    k = h * (1 - c)
    pts = [(k, -h), (h, -k), (h, k), (k, h), (-k, h), (-h, k), (-h, -k), (-k, -h)]
    return [np.array([x, y, z]) for x, z in pts]


def _sq(y, h):
    return [np.array([x * h, y, z * h]) for x, z in ((1, -1), (1, 1), (-1, 1), (-1, -1))]


def _loft(levels, tag, ring=_oct, caps=(True, True)):
    m = Mesh()
    m.loft([ring(y, h) for y, h in levels], tag, caps=caps)
    return S.weld(m)


def _bar(a, b, w, tag="iron"):
    return S.sweep([a, b], [(-w / 2, -w / 2), (w / 2, -w / 2), (w / 2, w / 2), (-w / 2, w / 2)], tag)


def _lantern(y0, lod, x=0.0, z=0.0):
    """The lantern, its glass starting at y0: foot, glass box, corner posts, the rims, roof, crown,
    finial, the burner lit inside."""
    gh, g0, g1 = L_GLASS
    rh, rw = L_ROOF
    ch, cw = L_CROWN
    m = Mesh()
    m.merge(_loft([(y0 - L_FOOT, 0.03), (y0 - 0.03, 0.12), (y0, g0 + 0.012)], "iron", _sq))  # the pointed foot
    m.merge(S.lathe([(y0 - L_FOOT - 0.05, 0.0), (y0 - L_FOOT - 0.035, 0.022), (y0 - L_FOOT, 0.018)], [8, 6, 4][lod], tag="iron"))
    g = Mesh()
    g.loft([_sq(y0, g0), _sq(y0 + gh, g1)], "glass", caps=(False, False))
    m.merge(g)
    if lod < 2:  # the corner posts and the rims round the glass's foot and top
        for sx, sz in ((1, -1), (1, 1), (-1, 1), (-1, -1)):
            m.merge(_bar((sx * g0, y0, sz * g0), (sx * g1, y0 + gh, sz * g1), 0.016 if lod == 0 else 0.02))
        m.merge(_loft([(y0 - 0.005, g0 + 0.015), (y0 + 0.02, g0 + 0.015)], "iron", _sq))
    m.merge(_loft([(y0 + gh - 0.01, g1 + 0.01), (y0 + gh + 0.025, rw), (y0 + gh + 0.035, rw)], "iron", _sq))  # the eave
    roof = [(y0 + gh + 0.035, rw - 0.005), (y0 + gh + rh, cw + 0.01)]
    m.merge(_loft(roof, "iron", _sq))
    cy = y0 + gh + rh
    m.merge(_loft([(cy, cw), (cy + ch, cw), (cy + ch, cw + 0.02), (cy + ch + 0.025, cw + 0.02), (cy + ch + 0.05, 0.02)], "iron", _sq))
    m.merge(S.lathe([(cy + ch + 0.05, 0.012), (cy + ch + 0.07, 0.025), (cy + ch + 0.10, 0.012), (cy + ch + 0.11, 0.0)],
                    [8, 6, 4][lod], tag="iron"))  # the finial
    if lod == 0:
        for k in range(4):  # the crown's vents, dark
            a = np.pi / 2 * k
            n = np.array([np.cos(a), 0, np.sin(a)])
            c = n * (cw + 0.001) + np.array([0, cy + ch * 0.5, 0])
            m.merge(S.box(tuple(c), (0.035 if abs(n[2]) > 0.5 else 0.002, 0.022, 0.035 if abs(n[0]) > 0.5 else 0.002), "fixing"))
        for sx, sz in ((1, -1), (1, 1), (-1, 1), (-1, -1)):  # the roof's corner ribs and the eave's crockets
            m.merge(_bar((sx * (rw - 0.01), y0 + gh + 0.04, sz * (rw - 0.01)), (sx * (cw + 0.01), cy, sz * (cw + 0.01)), 0.012))
            m.merge(S.lathe([(0, 0.012), (0.02, 0.018), (0.04, 0.0)], 6, tag="iron").transformed(
                np.eye(3), (sx * rw, y0 + gh + 0.035, sz * rw)))
        # the burner: a brass column and the lit mantle
        m.merge(S.lathe([(y0 + 0.0, 0.022), (y0 + 0.08, 0.016), (y0 + 0.09, 0.03), (y0 + 0.10, 0.0)], 8, tag="brass"))
        m.merge(S.lathe([(y0 + 0.10, 0.018), (y0 + 0.13, 0.03), (y0 + 0.19, 0.026), (y0 + 0.21, 0.0)], 8, tag="flame"))
    else:
        m.merge(S.lathe([(y0 + 0.05, 0.03), (y0 + 0.2, 0.03)], 4, tag="flame"))
    return m.transformed(np.eye(3), (x, 0.0, z))


def lamp_post(lod):
    m = Mesh()
    c = 0.01 if lod == 0 else 0.0
    m.merge(S.chamfer_box((0, 0.075, 0), (0.40, 0.075, 0.40), 0.02, "stone", edges="top") if lod < 2 else
            S.box((0, 0.075, 0), (0.40, 0.075, 0.40), "stone"))  # the stone slab it is set on
    levels = POST if lod == 0 else [lv for k, lv in enumerate(POST) if k in (0, 1, 5, 6, 7, 8, 9, 13, 20, 21, 25, 27)]
    m.merge(_loft(levels, "iron", _oct if lod < 2 else _sq))
    if lod == 0:
        # a cartouche on each face of the pedestal: an oval frame and its boss
        for k in range(4):
            a = np.pi / 2 * k
            n = np.array([np.sin(a), 0.0, -np.cos(a)])
            t = np.array([np.cos(a), 0.0, np.sin(a)])
            yc, w = 0.62, 0.22  # the face's half-width there
            o = n * w + np.array([0, yc, 0])
            ring = [o + t * np.cos(q) * 0.07 + np.array([0, np.sin(q) * 0.10, 0]) for q in np.linspace(0, 2 * np.pi, 13)[:-1]]
            m.merge(S.sweep(ring, [(-0.008, -0.006), (0.008, -0.006), (0.008, 0.006), (-0.008, 0.006)], "iron", closed=True,
                            up=tuple(n)))
            m.merge(S.prism(tuple(o), 0.04, 0.015, 8, axis=tuple(n), tag="iron"))
            # the pedestal's foot moulding: a scroll each side of the face (the garlands' ends)
            for sx in (1, -1):
                m.merge(S.prism(tuple(n * 0.245 + t * sx * 0.17 + np.array([0, 0.36, 0])), 0.03, 0.012, 8, axis=tuple(n), tag="iron"))
            # the garland on the bell: a drop of leaves
            m.merge(_bar(tuple(n * 0.15 + np.array([0, 1.10, 0]) - t * 0.06), tuple(n * 0.12 + np.array([0, 1.18, 0])), 0.022))
            m.merge(_bar(tuple(n * 0.12 + np.array([0, 1.18, 0])), tuple(n * 0.15 + np.array([0, 1.10, 0]) + t * 0.06), 0.022))
            # the leaves round the shaft's foot, rising up each face
            for lw, lh, off in ((0.05, 0.30, 0.0), (0.03, 0.22, 0.045), (0.03, 0.22, -0.045)):
                base = n * 0.07 + t * off + np.array([0, 1.54, 0])
                top = n * 0.062 + t * off * 0.6 + np.array([0, 1.54 + lh, 0])
                m.merge(S.sweep([tuple(base), tuple(top)], [(-lw / 2, -0.008), (lw / 2, -0.008), (lw / 4, 0.010), (-lw / 4, 0.010)],
                                "iron", up=tuple(n), scale=lambda i: 1.0 - 0.7 * i))
            # the flutes: three fillets up each face of the shaft
            for f in (-0.03, 0.0, 0.03):
                b0 = n * 0.0655 + t * f + np.array([0, 1.90, 0])
                b1 = n * 0.0585 + t * f * 0.9 + np.array([0, 2.58, 0])
                m.merge(_bar(tuple(b0), tuple(b1), 0.008))
        # the arms holding the lantern's foot
        for sx, sz in ((1, -1), (1, 1), (-1, 1), (-1, -1)):
            m.merge(_bar((sx * 0.05, 2.78, sz * 0.05), (sx * 0.12, LANTERN_Y - 0.03, sz * 0.12), 0.014))
    m.merge(_lantern(LANTERN_Y, lod))
    return {"body": Part(m)}


# --- wall_lantern (Bury's porte-lanternes, the lanes' potences) --------------------------------------
W_ARM = (0.96, 0.80)     # the arm: height over the lantern's foot, reach from the wall
W_OUT = 0.74             # where the lantern hangs (from the wall)


def _flat(pts, w=(0.016, 0.028)):
    return S.sweep(pts, [(-w[0] / 2, -w[1] / 2), (w[0] / 2, -w[1] / 2), (w[0] / 2, w[1] / 2), (-w[0] / 2, w[1] / 2)], "iron",
                   up=(1, 0, 0))


def _scroll(c, r0, r1, a0, turns, steps=14):
    """A flat scroll in the bracket's plane (y, -z) round c = (z, y)."""
    pts = []
    for k in range(steps + 1):
        t = k / steps
        a = np.radians(a0 + turns * 360 * t)
        r = r0 + (r1 - r0) * t
        pts.append((0.0, c[1] + np.sin(a) * r, c[0] + np.cos(a) * r))
    return _flat(pts, (0.012, 0.022))


def wall_lantern(lod):
    m = Mesh()
    ay, reach = W_ARM
    # the wall plate and its bolts
    m.merge(S.box((0, ay - 0.30, 0.004), (0.04, 0.36, 0.004), "iron"))
    if lod == 0:
        for y in (ay + 0.03, ay - 0.62):
            m.merge(S.prism((0, y, 0.0), 0.012, 0.01, 6, axis=(0, 0, -1), tag="fixing"))
    # the arm, its tip curling down over the lantern's hook
    m.merge(_flat([(0, ay, 0.0), (0, ay, -reach + 0.06)]))
    steps = 10 if lod == 0 else 4
    m.merge(_scroll((-reach + 0.06, ay - 0.05), 0.05, 0.015, 90, -0.9, steps))
    # the brace: from the plate's foot sweeping up to the arm, and the scrolls filling the corner
    brace = [(0, ay - 0.62, 0.0)] + [(0, ay - 0.62 + 0.62 * (1 - (1 - t) ** 2), -0.55 * t) for t in np.linspace(0.1, 1, 6 if lod == 0 else 3)]
    m.merge(_flat(brace))
    if lod < 2:
        m.merge(_scroll((-0.15, ay - 0.16), 0.13, 0.02, 90, 1.1, steps))
        m.merge(_scroll((-0.40, ay - 0.08), 0.075, 0.015, 270, -1.0, steps))
    # the hook and the chain's links down to the lantern's finial
    top = L_FOOT + L_GLASS[0] + L_ROOF[0] + L_CROWN[0] + 0.11
    if lod == 0:
        for k, y in enumerate(np.linspace(ay - 0.02, top + 0.02, 3)):
            ring = S.lathe([(-0.003, 0.018), (0.003, 0.018)], 8, tag="iron", caps=(True, True))
            ring = S.along(ring, (1, 0, 0) if k % 2 else (0, 0, 1), (0.0, y, -W_OUT))
            m.merge(ring)
    else:
        m.merge(_bar((0, ay, -W_OUT), (0, top, -W_OUT), 0.012))
    m.merge(_lantern(L_FOOT, lod, 0.0, -W_OUT))
    return {"body": Part(m)}


ELEMENTS = {
    "lamp_post": {
        "build": lamp_post,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.005,
        "close": (0.0, LANTERN_Y + 0.2, 0.0),  # the lantern
    },
    "wall_lantern": {
        "build": wall_lantern,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
        "close": (0.0, 0.6, -0.5),
    },
}
