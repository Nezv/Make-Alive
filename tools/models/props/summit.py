"""The lookout's summit furniture (S231). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

coin_binoculars: the coin-operated binoculars of a viewpoint: a pedestal on its base plate, the yoke,
the head with its two barrels and hoods, the eyepieces' rubber cups behind a visor, the side
handles, the coin box with its slot.
panorama_table: the orientation table: a round masonry drum with its coping, the bronze plate on
top tilted toward the visitor, lines out from the centre to what can be seen, each named round the
edge (invented names, painted by position), the compass's N.
antenna_mast: a guyed lattice mast on the summit: three legs, zigzag bracing, a platform near the top,
panel antennas and a dish, the cable ladder, red obstruction lamps at the top and halfway (lit),
guy wires to three anchors, the concrete base.

Standing on y = 0, the front -Z (the view lies to -Z).
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

TABLE = dict(r=0.55, h=1.00, tilt=0.26, plate=0.50)
NAMES = [(0.0, "MARCHÉ"), (0.55, "ÉGLISE"), (1.15, "GARE"), (1.75, "HÔPITAL"), (2.45, "MAIRIE"), (3.15, "CASERNE"), (3.90, "FORÊT"), (4.60, "BAIE"), (5.40, "PONT")]
MAST = dict(h=15.0, side=0.60, guy=7.0)


def materials():
    return {
        "paint": Material((0.18, 0.40, 0.30), under=(0.40, 0.40, 0.40), bare=(0.40, 0.26, 0.16), chip=0.6, grain=0.06, fixing=True),
        "black": Material((0.07, 0.07, 0.07), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "glass": Material((0.25, 0.30, 0.34), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "chrome": Material((0.72, 0.73, 0.74), under=(0.5, 0.5, 0.5), bare=(0.40, 0.28, 0.18), chip=0.2, grain=0.03),
        "stone": Material((0.62, 0.58, 0.50), kind="stone", chip=0.0, rusts=False, grain=0.18),
        "bronze": Material((0.48, 0.40, 0.24), under=(0.4, 0.32, 0.2), bare=(0.55, 0.45, 0.28), chip=0.0, rusts=False, grain=0.05, fades=False),
        "galv": Material((0.64, 0.65, 0.64), under=(0.55, 0.56, 0.55), bare=(0.42, 0.30, 0.20), chip=0.3, grain=0.08),
        "white": Material((0.88, 0.88, 0.86), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "concrete": Material((0.62, 0.61, 0.58), kind="concrete", chip=0.0, rusts=False, grain=0.18),
        "redlamp": Material((0.70, 0.08, 0.06), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.10, 0.06)),
        "wire": Material((0.45, 0.45, 0.44), chip=0.2, grain=0.05),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- coin_binoculars ---------------------------------------------------------------------------------------
def coin_binoculars(lod):
    m = Mesh()
    n = [14, 8, 6][lod]
    m.merge(_cb((0, 0.02, 0), (0.22, 0.02, 0.22), 0.006, "paint", lod, edges="top"))
    m.merge(S.lathe([(0.04, 0.10), (0.10, 0.08), (0.14, 0.065), (1.00, 0.055), (1.04, 0.07), (1.08, 0.07)], n, tag="paint"))
    # the yoke over the pedestal, the head tilted up a little toward the view
    for s in (1, -1):
        m.merge(_cb((s * 0.20, 1.20, 0), (0.025, 0.14, 0.05), 0.008, "paint", lod))
    m.merge(_cb((0, 1.08, 0), (0.22, 0.025, 0.06), 0.008, "paint", lod))
    head = Mesh()
    head.merge(_cb((0, 0, 0.02), (0.17, 0.13, 0.16), 0.03, "paint", lod))
    for s in (1, -1):
        barrel = S.lathe([(0.0, 0.0), (0.0, 0.065), (0.18, 0.065), (0.20, 0.075), (0.24, 0.075), (0.24, 0.06)], n, tag="paint", caps=(True, False))
        head.merge(S.along(barrel, (0, 0, -1), (s * 0.085, 0.02, -0.12)))
        head.merge(S.along(S.lathe([(0.0, 0.058), (0.004, 0.058), (0.004, 0.0)], n, tag="glass"), (0, 0, -1), (s * 0.085, 0.02, -0.355)))
        if lod < 2:  # the eyepieces behind, their rubber cups; the handles at the sides
            head.merge(S.along(S.lathe([(0.0, 0.03), (0.05, 0.03), (0.06, 0.04), (0.08, 0.042), (0.08, 0.03)], [10, 6][lod], tag="black", caps=(True, False)), (0, 0, 1), (s * 0.045, 0.04, 0.18)))
            head.merge(S.sweep([(s * 0.17, 0.0, 0.10), (s * 0.30, 0.0, 0.14), (s * 0.30, -0.02, 0.24)], S.circle(0.018, [8, 5][lod]), "chrome"))
            head.merge(S.along(S.lathe([(0.0, 0.025), (0.10, 0.025), (0.10, 0.0)], 8, tag="black"), (0, 0, 1), (s * 0.30, -0.02, 0.22)))
    if lod < 2:
        head.merge(_cb((0, 0.10, 0.17), (0.15, 0.04, 0.03), 0.01, "paint", lod))     # the visor over the eyepieces
        head.merge(_cb((0.0, -0.16, 0.06), (0.10, 0.05, 0.08), 0.01, "paint", lod))   # the coin box under the head
        head.merge(S.box((0.0, -0.13, 0.141), (0.012, 0.025, 0.002), "black"))
        head.merge(S.box((0.06, -0.17, 0.141), (0.02, 0.02, 0.002), "chrome"))
    m.merge(head.transformed(S.rotation((1, 0, 0), 0.10), (0, 1.25, 0)))
    return {"body": Part(m)}


# --- panorama_table ----------------------------------------------------------------------------------------
def _plate_frame():
    """The plate's centre and its frame: n its normal, u and v across it (v toward the back)."""
    R, H, tilt = TABLE["r"], TABLE["h"], TABLE["tilt"]
    rot = S.rotation((1, 0, 0), -tilt)                          # its back edge raised: it faces the visitor at -Z
    n = rot @ np.array([0.0, 1.0, 0.0])
    u = rot @ np.array([1.0, 0.0, 0.0])
    v = rot @ np.array([0.0, 0.0, 1.0])
    c = np.array([0.0, H + 0.10, 0.0]) + n * 0.012
    return rot, c, n, u, v


def panorama_table(lod):
    R, H, pr = TABLE["r"], TABLE["h"], TABLE["plate"]
    n = [24, 14, 8][lod]
    m = Mesh()
    # the drum: a plinth, the masonry body, the coping cut along the plate's slope
    rot, c, nn, u, v = _plate_frame()
    top = np.array([0.0, H + 0.10, 0.0])
    body = S.lathe([(0.0, R + 0.08), (0.12, R + 0.08), (0.14, R), (H + 0.45, R)], n, tag="stone", caps=(False, True))
    m.merge(S.clip(body, top - nn * 0.10, nn, cap_tag="stone"))                 # cut along the plate's slope
    coping = S.lathe([(H - 0.40, R + 0.05), (H + 0.45, R + 0.05)], n, tag="stone", caps=(True, True))
    coping = S.clip(S.clip(coping, top, nn, cap_tag="stone"), top - nn * 0.10, -nn, cap_tag="stone")
    m.merge(coping)
    plate = S.lathe([(0.0, pr), (0.012, pr), (0.012, 0.0)], n, tag="bronze", caps=(False, True))
    m.merge(plate.transformed(rot, (0, H + 0.10, 0)))
    if lod < 2:  # the raised rim and the lines out to each name, the pin at the centre
        rim = S.lathe([(0.012, pr), (0.022, pr), (0.022, pr - 0.02), (0.012, pr - 0.02)], n, tag="bronze", caps=(False, False))
        m.merge(rim.transformed(rot, (0, H + 0.10, 0)))
        if lod == 0:
            for a, _ in NAMES:
                d = np.cos(a) * v * -1 + np.sin(a) * u
                p0, p1 = c + d * 0.05, c + d * (pr - 0.12)
                m.merge(S.sweep([tuple(p0 + nn * 0.002), tuple(p1 + nn * 0.002)], [(-0.002, -0.0015), (0.002, -0.0015), (0.002, 0.0015), (-0.002, 0.0015)], "bronze", up=tuple(nn)))
        m.merge(S.along(S.lathe([(0.0, 0.015), (0.03, 0.012), (0.04, 0.0)], 8, tag="bronze"), tuple(nn), tuple(c)))
    return {"body": Part(m)}


def _paint_table(P, N, tag, tags, state, col):
    """The names round the plate's edge, each where its line points; the N."""
    pr = TABLE["plate"]
    rot, c, nn, u, v = _plate_frame()
    near = np.abs((P - c) @ nn) < 0.01
    sel = (tag == tags.index("bronze")) & near & ((N @ nn) > 0.8)
    words = np.zeros(len(P), bool)
    for a, name in NAMES:
        d = np.cos(a) * -v + np.sin(a) * u                  # bearing a from the front (-Z), clockwise seen from above
        centre = c + d * (pr - 0.075)
        right = np.cross(-d, nn)                            # read from outside the rim: the letters' tops toward the centre
        words |= lettering.mask(P, name, centre.astype(np.float32), 0.028, right, -d, weight=1.2)
    words |= lettering.mask(P, "N", (c + v * (pr - 0.04)).astype(np.float32), 0.03, np.cross(-v, nn), -v, weight=1.5)
    return np.where((sel & words)[:, None], col * 0.35, col)


# --- antenna_mast ------------------------------------------------------------------------------------------
def antenna_mast(lod):
    H, a, G = MAST["h"], MAST["side"], MAST["guy"]
    m = Mesh()
    r = a / np.sqrt(3)
    legs = [np.array([np.cos(t) * r, 0.0, np.sin(t) * r]) for t in (np.pi / 2 + k * 2 * np.pi / 3 for k in range(3))]
    m.merge(_cb((0, 0.15, 0), (0.6, 0.15, 0.6), 0.02, "concrete", lod, edges="top"))
    for p in legs:
        m.merge(S.sweep([tuple(p + (0, 0.3, 0)), tuple(p + (0, H, 0))], S.circle(0.03, [8, 5, 4][lod]), "galv"))
    if lod < 2:  # the zigzag bracing on each face, the platform, the cable ladder
        step = [1.0, 2.0][lod]
        for k in range(3):
            p, q = legs[k], legs[(k + 1) % 3]
            ys = np.arange(0.3, H, step)
            pts = [tuple((p if i % 2 == 0 else q) + (0, y, 0)) for i, y in enumerate(ys)]
            m.merge(S.sweep(pts, S.circle(0.012, 3), "galv"))
            for y in ys[::2]:
                m.merge(S.sweep([tuple(p + (0, y, 0)), tuple(q + (0, y, 0))], S.circle(0.010, 3), "galv"))
        ring = [(np.cos(t) * 0.9, H - 1.5, np.sin(t) * 0.9) for t in np.linspace(0, 2 * np.pi, [13, 7][lod])[:-1]]
        m.merge(S.sweep(ring, S.circle(0.025, 4), "galv", closed=True))
        m.merge(S.lathe([(H - 1.52, 0.9), (H - 1.50, 0.9), (H - 1.50, 0.0)], [12, 6][lod], tag="galv", caps=(False, True)))
        m.merge(S.box((r + 0.08, H / 2, 0), (0.01, H / 2 - 0.3, 0.12), "galv"))
    # the antennas: three panels round the top, a dish below, the lightning rod
    for k in range(3):
        t = np.pi / 2 + k * 2 * np.pi / 3 + np.pi / 3
        d = np.array([np.cos(t), 0, np.sin(t)])
        c = d * (r + 0.15) + (0, H - 0.6, 0)
        m.merge(_cb((0, 0, 0), (0.15, 0.6, 0.06), 0.02, "white", lod).transformed(S.rotation((0, 1, 0), np.pi / 2 - t), tuple(c)))
    if lod < 2:
        dish = S.lathe([(0.0, 0.0), (0.06, 0.20), (0.15, 0.38), (0.17, 0.40)], [16, 8][lod], tag="white", caps=(False, True))
        m.merge(S.along(dish, (0, 0, -1), (0, H - 3.5, -r - 0.05)))
    m.merge(S.sweep([(0, H, 0), (0, H + 1.2, 0)], S.circle(0.015, 4), "galv"))
    # the red lamps at the top and halfway
    for y in (H + 0.05, H / 2):
        m.merge(S.lathe([(y, 0.06), (y + 0.10, 0.07), (y + 0.16, 0.0)], [10, 6, 4][lod], tag="redlamp").transformed(np.eye(3), tuple(legs[0] + (0, 0, 0.0))))
    # the guys: from two heights to three anchors on the ground
    for k in range(3):
        t = np.pi / 2 + k * 2 * np.pi / 3
        anchor = (np.cos(t) * G, 0.15, np.sin(t) * G)
        m.merge(_cb((anchor[0], 0.10, anchor[2]), (0.25, 0.10, 0.25), 0.02, "concrete", lod, edges="top"))
        for y in (H * 0.5, H * 0.92):
            m.merge(S.cable(anchor, tuple(legs[k] + (0, y, 0)), 0.08, r=0.006, n=[6, 3, 1][lod], sides=3, tag="wire"))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "coin_binoculars": dict(build=coin_binoculars, materials=materials(), edge_radius=0.003, close=(0.0, 1.25, -0.1), **_SPEC),
    "panorama_table": dict(build=panorama_table, materials=materials(), extra=_paint_table, extra_first=True, edge_radius=0.004, close=(0.0, 1.1, -0.2), **_SPEC),
    "antenna_mast": dict(build=antenna_mast, materials=materials(), edge_radius=0.003, close=(0.0, 1.0, -0.5), **_SPEC),
}
