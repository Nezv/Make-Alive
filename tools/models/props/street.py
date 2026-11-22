"""Street furniture. Card and references of each element: references/elements/<name>.md.

hydrant: the old cast-iron poteau d'incendie of French towns (references/elements/hydrant/):
a fluted column on a bolted foot, a collar a third of the way up, a head with a 100 mm outlet
to the front and a 65 mm one each side, an oval maker's plate, a rim and a dome topped by the
pentagon operating nut. The three outlet caps hang open on their pivots.
"""
import numpy as np

import props as K
from props import Material, Part, lathe, along, prism

RED = (0.56, 0.10, 0.075)

HYDRANT_MATERIALS = {
    "paint": Material(RED, under=(0.55, 0.36, 0.17), bare=(0.17, 0.16, 0.15)),
    "plate": Material(RED, under=(0.55, 0.36, 0.17), bare=(0.17, 0.16, 0.15), chip=1.6),
    "cap": Material((0.58, 0.59, 0.57), under=(0.45, 0.45, 0.43), bare=(0.40, 0.40, 0.38), chip=0.6, rusts=False,
                    grain=0.05),
    "chain": Material((0.55, 0.56, 0.55), under=(0.4, 0.4, 0.38), bare=(0.33, 0.2, 0.1), chip=0.3, grain=0.1),
    "hole": Material((0.07, 0.06, 0.06), chip=0.0, rusts=False, grain=0.2),
    "iron": Material((0.27, 0.22, 0.19), under=(0.30, 0.18, 0.10), bare=(0.32, 0.17, 0.08), chip=1.2, grain=0.15),
}

# Heights (m) measured on ref_6 against its 0.97 m total (see the card).
FOOT, COLLAR_LO, COLLAR_HI, HEAD_LO, RIM_LO, RIM_HI, DOME_TOP, NUT_TOP = 0.05, 0.31, 0.355, 0.66, 0.80, 0.835, 0.91, 0.97
COLUMN_R = 0.07
FRONT_Y, SIDE_Y = 0.58, 0.74


def _sides(lod, s0):
    return max(6, [s0, s0 // 2, s0 // 4][lod])


def _column(lod):
    sides = _sides(lod, 24)
    fl = lod == 0

    def flute(j, y):  # twelve grooves down each length of column
        if not fl:
            return 1.0
        grooved = (FOOT + 0.03 < y < COLLAR_LO - 0.015) or (COLLAR_HI + 0.02 < y < HEAD_LO - 0.02)
        ribbed = RIM_HI + 0.01 < y < DOME_TOP - 0.006  # and twelve ribs over the dome
        if j % 2 and grooved:
            return 0.93
        return 1.07 if j % 2 and ribbed else 1.0

    r = COLUMN_R
    prof = [(0.0, 0.125), (0.028, 0.125), (0.040, 0.108), (FOOT, 0.092), (FOOT + 0.015, 0.082),
            (FOOT + 0.03, r * 1.04), (FOOT + 0.031, r * 1.04), (COLLAR_LO - 0.015, r), (COLLAR_LO - 0.014, r),
            (COLLAR_LO, r * 1.06), (COLLAR_LO + 0.008, r * 1.2), (COLLAR_HI - 0.008, r * 1.2), (COLLAR_HI, r * 1.06),
            (COLLAR_HI + 0.02, r), (COLLAR_HI + 0.021, r), (HEAD_LO - 0.02, r * 0.98), (HEAD_LO - 0.019, r * 0.98),
            (HEAD_LO + 0.02, r * 1.14), (RIM_LO - 0.02, r * 1.2), (RIM_LO, r * 1.24), (RIM_LO + 0.004, r * 1.32),
            (RIM_HI - 0.004, r * 1.32), (RIM_HI, r * 1.24), (RIM_HI + 0.004, r * 1.2), (RIM_HI + 0.03, r * 1.14),
            (DOME_TOP - 0.03, r * 0.98), (DOME_TOP - 0.014, r * 0.78), (DOME_TOP - 0.004, r * 0.56), (DOME_TOP, r * 0.5)]
    if lod >= 2:
        prof = [prof[i] for i in (0, 1, 3, 8, 10, 11, 13, 15, 17, 19, 21, 22, 25, 28)]
    m = lathe(prof, sides, flute=flute, turn=np.pi / sides)
    return m


def _nut(lod):
    m = lathe([(DOME_TOP - 0.004, 0.04), (DOME_TOP + 0.012, 0.04), (DOME_TOP + 0.016, 0.034)], _sides(lod, 12), tag="iron")
    m.merge(prism((0, DOME_TOP + 0.016, 0), 0.026, NUT_TOP - DOME_TOP - 0.016, 5, tag="iron"))
    return m


def _boss(axis, at, length, r, lod):
    """An outlet's spout out of the column: a tube with a flange where the cap screws on."""
    sides = _sides(lod, 16)
    prof = [(0.0, r * 1.5), (0.028, r * 1.45), (0.045, r * 1.1), (0.055, r), (length - 0.016, r),
            (length - 0.012, r * 1.18), (length, r * 1.18, "hole")]  # flared out of the column; the bore shows open
    if lod >= 2:
        prof = [prof[0], prof[2], prof[4], prof[6]]
    return along(lathe(prof, sides, turn=np.pi / sides, caps=(False, True)), axis, at)


def _chain(a, b, sag, lod, links=14):
    """A hanging chain from a to b: flat links turned alternately, sagging `sag` in the middle."""
    m = K.Mesh()
    if lod > 0:
        return m
    a, b = np.asarray(a, np.float64), np.asarray(b, np.float64)
    pts = [a + (b - a) * t + np.array([0, -sag * np.sin(np.pi * t), 0]) for t in np.linspace(0, 1, links + 1)]
    for i in range(links):
        p, q = pts[i], pts[i + 1]
        d = q - p
        d /= np.linalg.norm(d)
        side = np.cross(d, [0.0, 0.0, 1.0] if abs(d[2]) < 0.9 else [1.0, 0.0, 0.0])
        side /= np.linalg.norm(side)
        if i % 2:
            side = np.cross(d, side)
        up = np.cross(side, d)
        basis = np.stack([side, d, up], 1)
        half = np.linalg.norm(q - p) * 0.62
        m.box((p + q) / 2, (0.0045, half, 0.0016), tag="chain", basis=basis)
    return m


def _cap(axis, at, r, depth, lugs, lod):
    """A coupling cap: a short drum with lugs round it and a square nut on its face."""
    sides = _sides(lod, 16)
    prof = [(0.0, r), (depth * 0.15, r * 1.04), (depth * 0.85, r * 1.04), (depth, r * 0.9)]
    m = lathe(prof, sides, turn=np.pi / sides, tag="cap")
    if lod == 0:
        for k in range(lugs):
            a = 2 * np.pi * k / lugs + np.pi / 2
            c = np.array([np.cos(a) * r * 1.06, depth * 0.2, np.sin(a) * r * 1.06])
            m.box(c + np.array([0, depth * 0.3, 0]), (0.008, depth * 0.3, 0.008), tag="cap")
    if lod <= 1:
        m.merge(prism((0, depth, 0), r * 0.3, 0.012, 4, turn=np.pi / 4, tag="cap"))
    return along(m, axis, at)


def _plate(lod):
    """The maker's oval on the front of the head (lettering is painted, see the card)."""
    m = K.Mesh()
    if lod > 0:
        return m
    rings = []
    for z, s in ((-COLUMN_R * 1.1, 1.0), (-COLUMN_R * 1.2 - 0.006, 1.0), (-COLUMN_R * 1.2 - 0.009, 0.88)):
        rings.append([[np.cos(a) * 0.036 * s, 0.785 + np.sin(a) * 0.022 * s, z] for a in np.linspace(0, 2 * np.pi, 16, endpoint=False)])
    m.loft(rings, "plate")
    return m


def _bolts(lod):
    m = K.Mesh()
    if lod > 0:
        return m
    for k in range(4):
        a = np.pi / 4 + k * np.pi / 2
        m.merge(prism((np.cos(a) * 0.108, 0.026, np.sin(a) * 0.108), 0.01, 0.014, 6, tag="iron"))
    return m


def hydrant(lod):
    body = _column(lod)
    body.merge(_nut(lod))
    body.merge(_plate(lod))
    body.merge(_bolts(lod))
    r = COLUMN_R
    front_len = 0.125
    body.merge(_boss((0, 0, -1), (0, FRONT_Y, -r * 0.6), front_len - r * 0.6, 0.05, lod))
    side_len = 0.13
    for s in (1, -1):
        body.merge(_boss((s, 0, 0), (s * r * 0.6, SIDE_Y, 0), side_len - r * 0.6, 0.036, lod))
    body.merge(_chain((0.02, FRONT_Y - 0.055, -front_len + 0.012), (0.045, 0.43, -r * 0.92), 0.025, lod))
    for s in (1, -1):
        body.merge(_chain((s * (side_len - 0.012), SIDE_Y - 0.04, -0.012), (s * r * 0.95, 0.62, -0.03), 0.03, lod))
    front = _cap((0, 0, -1), (0, FRONT_Y, -front_len), 0.058, 0.036, 3, lod)
    parts = {"body": Part(body)}
    parts["cap_front"] = Part(front, (0.0, FRONT_Y - 0.058, -front_len), {"rotate": [[1, 0, 0], -100.0]})
    for s, nm in ((1, "cap_r"), (-1, "cap_l")):
        c = _cap((s, 0, 0), (s * side_len, SIDE_Y, 0), 0.042, 0.03, 2, lod)
        parts[nm] = Part(c, (s * side_len, SIDE_Y - 0.042, 0.0), {"rotate": [[0, 0, 1], -100.0 * s]})
    if lod > 0:  # far away the caps never move: one mesh
        merged = K.Mesh()
        for p in parts.values():
            merged.merge(p.mesh)
        return {"body": Part(merged)}
    return parts


def _hydrant_paint(P, N, tag, tags, state, col):
    """The founder's name raised on the oval (the paint rubs off it first: bare iron showing),
    the post's number painted white on the column under the front outlet, as on poste_rouen."""
    front = N[:, 2] < -0.5
    plate = (tag == tags.index("plate")) & front & (P[:, 2] < -COLUMN_R * 1.2 - 0.004)
    name = K.letters(P, "VERNAY", (0, 0.789, 0), 0.011, right=(-1, 0, 0)) & plate
    year = K.letters(P, "1887", (0, 0.776, 0), 0.008, right=(-1, 0, 0)) & plate
    raised = name | year
    metal = np.array([0.30, 0.28, 0.26], np.float32) if state != "clean" else np.array([0.75, 0.2, 0.15], np.float32)
    col = np.where(raised[:, None], metal, col)
    paint = (tag == tags.index("paint")) & (P[:, 2] < -0.04)  # the front half only
    number = K.letters(P, "17", (0, 0.47, 0), 0.05, right=(-1, 0, 0)) & paint
    white = np.array([0.86, 0.85, 0.80], np.float32)
    if state == "burnt":
        white = white * 0.35
    elif state != "clean":
        white = white * 0.85
    return np.where(number[:, None], white, col)


ELEMENTS = {
    "hydrant": {
        "build": hydrant,
        "materials": HYDRANT_MATERIALS,
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.005,
        "extra": _hydrant_paint,
    },
}
