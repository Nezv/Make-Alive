"""The vehicle kit (S179): what every car shares, so each vehicle step only makes its body. Cards and
references: references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

wheel_steel: a 195/65 R15 wheel standing on the ground, its axle along x: the tyre with its
bulged sidewalls, tread blocks and grooves, the steel rim with its flanges, well, disc and
ventilation holes, the hub and four nuts.
plate_fr: the long French plate (siv_transit's layout, white): the blue band at the left with the
ring of stars and F, the band at the right with the region number, the black letters in the
middle on a plastic holder. The code is invented and the region 00 does not exist.
headlamp: a headlamp cluster: the housing, two reflector bowls behind the clear lens, the amber
indicator, lit by the emission map. Its front -Z.
tail_lamp: the rear cluster: red, amber and white sections in a housing, lit.
wing_mirror: a door mirror (mirror): the housing round the glass, its arm and the sail it is
fixed to the door by. The door's skin is x = 0, the mirror out at +x, its glass facing +Z (back along\nthe car).

Metres, Y up; the car's forward is -Z.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

TYRE = dict(r=0.3175, w=0.195, rim=0.1905)          # 195/65 R15
PLATE = dict(w=0.520, h=0.110, band=0.040)
PLATE_TEXT = ("JV-417-KM", "00")                    # invented; department 00 does not exist
LAMP = dict(w=0.34, h=0.14, d=0.12)


def materials():
    return {
        "tyre": Material((0.07, 0.07, 0.07), kind="rubber", chip=0.0, rusts=False, grain=0.06),
        "rim": Material((0.12, 0.12, 0.13), under=(0.35, 0.35, 0.35), bare=(0.40, 0.28, 0.18), chip=0.5, grain=0.05),
        "nut": Material((0.55, 0.55, 0.55), under=(0.4, 0.4, 0.4), bare=(0.40, 0.25, 0.15), fixing=True, grain=0.05),
        "dark": Material((0.03, 0.03, 0.03), chip=0.0, rusts=False, grain=0.02, fades=False),
        "plate": Material((0.94, 0.94, 0.92), kind="metal", chip=0.3, rusts=False, grain=0.02),
        "holder": Material((0.06, 0.06, 0.06), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "housing": Material((0.10, 0.10, 0.11), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "chrome": Material((0.78, 0.79, 0.80), under=(0.5, 0.5, 0.5), bare=(0.5, 0.5, 0.5), chip=0.0, rusts=False, grain=0.02),
        "lens": Material((0.80, 0.82, 0.84), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.95, 0.85)),
        "amber": Material((0.85, 0.48, 0.08), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.55, 0.10)),
        "red": Material((0.62, 0.06, 0.05), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.08, 0.05)),
        "white": Material((0.85, 0.85, 0.85), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "paint": Material((0.55, 0.57, 0.60), under=(0.45, 0.45, 0.45), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.03),
        "glass": Material((0.55, 0.60, 0.62), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "alloy": Material((0.70, 0.71, 0.72), under=(0.6, 0.6, 0.6), bare=(0.66, 0.67, 0.68), chip=0.3, rusts=False, grain=0.04),
        "seat": Material((0.22, 0.23, 0.26), kind="paper", chip=0.0, rusts=False, grain=0.14),
        "dial": Material((0.85, 0.85, 0.80), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.95, 0.55, 0.20)),
    }


# --- wheel_steel ----------------------------------------------------------------------------------------
def wheel_steel(lod):
    R, W, Rr = TYRE["r"], TYRE["w"], TYRE["rim"]
    sides = [48, 24, 12][lod]
    m = Mesh()

    def tread(j, y):  # blocks: every other point of the tread sunk a little in the shoulders, grooves round
        if abs(y) < W / 2 - 0.02:
            g = 0.985 if (abs(abs(y) - 0.035) < 0.006 or abs(y) < 0.005) else 1.0
            return g * (0.992 if (j % 2 and abs(y) > 0.05) else 1.0)
        return 1.0

    prof = [(-W / 2 + 0.01, Rr + 0.012), (-W / 2 - 0.006, Rr + 0.06), (-W / 2 + 0.002, R - 0.03), (-W / 2 + 0.02, R - 0.004),
            (-0.07, R), (-0.035, R), (0.0, R), (0.035, R), (0.07, R),
            (W / 2 - 0.02, R - 0.004), (W / 2 - 0.002, R - 0.03), (W / 2 + 0.006, Rr + 0.06), (W / 2 - 0.01, Rr + 0.012)]
    if lod:
        prof = [prof[0], prof[1], prof[3], prof[6], prof[9], prof[11], prof[12]]
    tyre = S.lathe(prof, sides, flute=tread if lod == 0 else None, tag="tyre", caps=(False, False))
    tyre.faces = [tuple(reversed(f)) for f in tyre.faces]   # the profile runs outward then back in: turn it to face out
    m.merge(S.along(tyre, (1, 0, 0), (0, R, 0)))
    # the rim: flanges, the well, the disc set in to the hub
    rim = [(-W / 2 + 0.01, Rr + 0.012), (-W / 2 + 0.012, Rr - 0.01), (-0.04, Rr - 0.03), (0.04, Rr - 0.03), (W / 2 - 0.012, Rr - 0.01), (W / 2 - 0.01, Rr + 0.012)]
    m.merge(S.along(S.lathe(rim, [32, 16, 8][lod], tag="rim", caps=(False, False)), (1, 0, 0), (0, R, 0)))
    disc = [(-0.02, Rr - 0.03), (-0.035, Rr - 0.06), (-0.05, 0.08), (-0.05, 0.035), (-0.075, 0.03), (-0.075, 0.0)]
    m.merge(S.along(S.lathe(disc, [24, 12, 8][lod], tag="rim", caps=(False, True)), (-1, 0, 0), (0, R, 0)))
    if lod < 2:
        for k in range(4):  # the nuts round the hub
            a = 2 * np.pi * k / 4 + np.pi / 4
            m.merge(S.prism((-0.05, R + np.sin(a) * 0.05, np.cos(a) * 0.05), 0.010, 0.018, 6, axis=(-1, 0, 0), tag="nut"))
        for k in range([8, 4][lod]):  # the ventilation holes in the disc, dark
            a = 2 * np.pi * k / [8, 4][lod]
            m.merge(S.box((-0.046, R + np.sin(a) * 0.125, np.cos(a) * 0.125), (0.002, 0.018, 0.018), "dark").transformed(np.eye(3), (0, 0, 0)))
    return {"body": Part(m)}


# --- plate_fr ---------------------------------------------------------------------------------------------
def plate_fr(lod):
    w, h = PLATE["w"], PLATE["h"]
    m = Mesh()
    m.merge(S.chamfer_box((0, h / 2, 0.006), (w / 2 + 0.012, h / 2 + 0.012, 0.006), 0.004 if lod == 0 else 0.0, "holder", edges="front") if lod == 0 else
            S.box((0, h / 2, 0.006), (w / 2 + 0.012, h / 2 + 0.012, 0.006), "holder"))
    m.merge(S.chamfer_box((0, h / 2, -0.001), (w / 2, h / 2, 0.001), 0.003 if lod == 0 else 0.0, "plate", edges="vertical") if lod == 0 else
            S.box((0, h / 2, -0.001), (w / 2, h / 2, 0.001), "plate"))
    if lod == 0:  # the two rivets
        for x in (-w / 2 + 0.06, w / 2 - 0.06):
            m.merge(S.prism((x, h / 2, -0.002), 0.006, 0.002, 8, axis=(0, 0, -1), tag="nut"))
    return {"body": Part(m)}


BLUE = np.array([0.05, 0.18, 0.58], np.float32)
WHITE = np.array([0.94, 0.94, 0.92], np.float32)
BLACK = np.array([0.05, 0.05, 0.05], np.float32)
GOLD = np.array([0.95, 0.80, 0.10], np.float32)


def _paint_plate(P, N, tag, tags, state, col):
    w, h, b = PLATE["w"], PLATE["h"], PLATE["band"]
    sel = (tag == tags.index("plate")) & (N[:, 2] < -0.5)
    x, y = P[:, 0], P[:, 1]
    band_l = x > w / 2 - b          # the reader's left is +x
    band_r = x < -w / 2 + b
    out = np.where((band_l | band_r)[:, None], BLUE, WHITE)
    a = np.arctan2(y - h * 0.66, x - (w / 2 - b / 2))
    stars = band_l & (np.abs(np.hypot(x - (w / 2 - b / 2), y - h * 0.66) - 0.013) < 0.003) & (np.mod(a * 12 / (2 * np.pi), 1.0) < 0.45)
    out = np.where(stars[:, None], GOLD, out)
    code, region = PLATE_TEXT
    txt = lettering.mask(P, "F", np.array([w / 2 - b / 2, h * 0.28, -0.002], np.float32), 0.022, (-1, 0, 0), (0, 1, 0), weight=1.3) & band_l
    txt |= lettering.mask(P, region, np.array([-w / 2 + b / 2, h * 0.30, -0.002], np.float32), 0.024, (-1, 0, 0), (0, 1, 0), weight=1.3) & band_r
    out = np.where(txt[:, None], WHITE, out)
    size = min(0.075, (w - 2 * b - 0.03) / lettering.width(code, 1.0))     # the letters fill the white field
    main = lettering.mask(P, code, np.array([0.0, h / 2, -0.002], np.float32), size, (-1, 0, 0), (0, 1, 0), weight=1.6) & ~band_l & ~band_r
    out = np.where(main[:, None], BLACK, out)
    return np.where(sel[:, None], out, col)


# --- the lamps ---------------------------------------------------------------------------------------------
def _cluster(outline, d, lod):
    """A lamp's housing: the outline (x, y) pushed back d from its lens at z = 0."""
    m = Mesh()
    m.merge(S.extrude(outline, d, 0.0, "housing", cap_tag="housing", origin=(0, 0, d), right=(1, 0, 0), up=(0, 1, 0)))
    return m


def headlamp(lod):
    w, h, d = LAMP["w"], LAMP["h"], LAMP["d"]
    outline = [(-w / 2, -h / 2), (w / 2 - 0.06, -h / 2), (w / 2, -h / 2 + 0.04), (w / 2, h / 2 - 0.02), (-w / 2 + 0.04, h / 2), (-w / 2, h / 2 - 0.03)]
    m = _cluster(outline, d, lod)
    sides = [16, 10, 6][lod]
    for x, r in ((-0.08, 0.050), (0.05, 0.045)):   # the reflector bowls, chrome, the bulbs' lit discs
        bowl = S.lathe([(0.0, r), (0.03, r * 0.8), (0.05, r * 0.3), (0.055, 0.0)], sides, tag="chrome", caps=(False, False))
        bowl.faces = [tuple(reversed(f)) for f in bowl.faces]
        m.merge(S.along(bowl, (0, 0, 1), (x, 0.0, -0.002)))
        m.merge(S.prism((x, 0.0, 0.02), r * 0.35, 0.004, 8, axis=(0, 0, -1), tag="lens"))
    m.merge(S.box((w / 2 - 0.05, -h / 2 + 0.035, -0.004), (0.035, 0.022, 0.003), "amber"))
    m.merge(S.extrude(outline, 0.006, 0.003 if lod == 0 else 0.0, "white", origin=(0, 0, -0.001), right=(1, 0, 0), up=(0, 1, 0)))   # the clear lens
    return {"body": Part(m)}


def tail_lamp(lod):
    w, h, d = 0.28, 0.13, 0.08
    outline = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2 + 0.05, h / 2), (-w / 2, h / 2 - 0.04)]
    m = _cluster(outline, d, lod)
    # the sections behind the lens: red the outer two thirds, amber, white for reversing
    for x0, x1, tag in ((-w / 2 + 0.01, w * 0.15, "red"), (w * 0.15 + 0.005, w * 0.33, "amber"), (w * 0.33 + 0.005, w / 2 - 0.01, "white")):
        m.merge(S.box(((x0 + x1) / 2, 0.0, -0.003), ((x1 - x0) / 2, h / 2 - 0.012, 0.003), tag))
    if lod == 0:  # the ribs moulded in the red lens
        for k in range(5):
            m.merge(S.box((-w / 2 + 0.03 + k * 0.035, 0.0, -0.0075), (0.004, h / 2 - 0.02, 0.0015), "red"))
    return {"body": Part(m)}


# --- wing_mirror --------------------------------------------------------------------------------------------
def wing_mirror(lod):
    m = Mesh()
    # the sail on the door (x = 0), the arm out to the housing
    m.merge(S.extrude([(0.0, 0.0), (0.09, 0.0), (0.0, 0.07)], 0.02, 0.0, "housing", origin=(0.0, 0.0, 0.0), right=(0, 0, 1), up=(0, 1, 0)))
    m.merge(S.box((0.035, 0.03, 0.03), (0.035, 0.015, 0.025), "housing"))
    # the housing: a rounded shell, its open back towards +Z with the glass in it
    shell = S.bevel_box((0.15, 0.06, 0.05), (0.09, 0.06, 0.045), 0.03, "paint") if lod == 0 else S.box((0.15, 0.06, 0.05), (0.09, 0.06, 0.045), "paint")
    shell.verts = [np.array([v[0], v[1], v[2] - 0.25 * (v[0] - 0.06) * max(0.0, 0.05 - v[2]) * 4]) for v in shell.verts]   # swept back at its tip
    m.merge(shell)
    m.merge(S.box((0.15, 0.06, 0.096), (0.08, 0.052, 0.002), "glass"))
    if lod == 0:
        m.merge(S.box((0.15, 0.06, 0.093), (0.085, 0.056, 0.003), "housing"))  # the rim round the glass
    return {"body": Part(m)}


# --- wheel_alloy ------------------------------------------------------------------------------------------
def wheel_alloy(lod):
    """The same tyre on a five-spoke alloy rim: the barrel, the lip, five spokes tapering from the hub,
    the centre cap (no badge), five nuts."""
    R, W, Rr = TYRE["r"], TYRE["w"], TYRE["rim"]
    base = wheel_steel(lod)["body"].mesh                   # keep the steel wheel's tyre, build the rest anew
    keep = Mesh()
    keep.verts = [v.copy() for v in base.verts]
    keep.vdata = list(base.vdata)
    for f, t, u in zip(base.faces, base.tags, base.units_list()):
        if t == "tyre":
            keep.face(f, t, u)
    rim = [(-W / 2 + 0.01, Rr + 0.012), (-W / 2 + 0.012, Rr - 0.01), (-0.04, Rr - 0.03), (0.04, Rr - 0.03), (W / 2 - 0.012, Rr - 0.01), (W / 2 - 0.01, Rr + 0.012)]
    keep.merge(S.along(S.lathe(rim, [32, 16, 8][lod], tag="alloy", caps=(False, False)), (1, 0, 0), (0, R, 0)))
    # the face: the lip ring, the hub, the spokes
    xf = -W / 2 + 0.03
    keep.merge(S.along(S.lathe([(0.0, Rr - 0.004), (0.0, Rr - 0.03), (0.02, Rr - 0.03), (0.02, Rr - 0.004)], [32, 16, 8][lod], tag="alloy", caps=(False, False)), (-1, 0, 0), (xf + 0.02, R, 0)))
    keep.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.075), (0.03, 0.07), (0.035, 0.0)], [16, 10, 6][lod], tag="alloy"), (-1, 0, 0), (xf - 0.005, R, 0)))
    for k in range(5):
        a = 2 * np.pi * k / 5 + np.pi / 2
        d = np.array([0.0, np.sin(a), np.cos(a)])
        p0, p1 = np.array([xf - 0.01, R, 0.0]) + d * 0.06, np.array([xf + 0.01, R, 0.0]) + d * (Rr - 0.025)
        keep.merge(S.sweep([tuple(p0), tuple(p1)], [(-0.032, -0.012), (0.032, -0.012), (0.026, 0.012), (-0.026, 0.012)], "alloy", up=(-1, 0, 0),
                           scale=lambda i: [1.0, 0.75][i]))
        if lod < 2:
            b = a + np.pi / 5
            keep.merge(S.prism((xf - 0.04, R + np.sin(b) * 0.045, np.cos(b) * 0.045), 0.009, 0.016, 6, axis=(-1, 0, 0), tag="nut"))
    if lod < 2:
        keep.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.03), (0.008, 0.028), (0.01, 0.0)], 10, tag="chrome"), (-1, 0, 0), (xf - 0.04, R, 0)))
    return {"body": Part(keep)}


# --- car_seat -----------------------------------------------------------------------------------------------
def _cushion(c, half, r, lod, tag="seat"):
    """A padded block: a box with every edge rounded, a little crowned on its faces."""
    return S.bevel_box(c, half, r, tag) if lod == 0 else S.box(c, half, tag)


def car_seat(lod):
    m = Mesh()
    # the runners on the floor, the frame, the cushion with its bolsters
    for s in (1, -1):
        m.merge(S.box((s * 0.18, 0.03, 0.0), (0.02, 0.03, 0.30), "housing"))
    m.merge(S.box((0, 0.12, 0.02), (0.20, 0.05, 0.22), "housing"))
    m.merge(_cushion((0, 0.25, 0.0), (0.25, 0.07, 0.26), 0.04, lod))
    if lod < 2:
        for s in (1, -1):
            m.merge(_cushion((s * 0.22, 0.30, 0.02), (0.05, 0.05, 0.22), 0.03, lod))
    # the back, reclined, its side bolsters; the headrest on its two posts
    R = S.rotation((1, 0, 0), 0.22)
    back = Mesh()
    back.merge(_cushion((0, 0.32, 0), (0.24, 0.32, 0.07), 0.04, lod))
    if lod < 2:
        for s in (1, -1):
            back.merge(_cushion((s * 0.22, 0.30, -0.04), (0.05, 0.26, 0.06), 0.03, lod))
        for s in (1, -1):
            back.merge(S.sweep([(s * 0.07, 0.62, 0.0), (s * 0.07, 0.72, 0.0)], S.circle(0.007, 6), "chrome"))
    back.merge(_cushion((0, 0.80, 0.01), (0.14, 0.09, 0.06), 0.035, lod))
    m.merge(back.transformed(R, (0, 0.28, 0.27)))
    if lod < 2:  # the recline lever, the seat belt's buckle on its stalk
        m.merge(S.box((0.27, 0.22, 0.18), (0.012, 0.015, 0.07), "housing"))
        m.merge(S.sweep([(-0.27, 0.12, 0.20), (-0.29, 0.30, 0.18)], [(-0.01, -0.02), (0.01, -0.02), (0.01, 0.02), (-0.01, 0.02)], "housing", up=(1, 0, 0)))
        m.merge(S.box((-0.29, 0.33, 0.18), (0.015, 0.03, 0.02), "chrome"))
    return {"body": Part(m)}


# --- dashboard ----------------------------------------------------------------------------------------------
def dashboard(lod):
    """A small car's dashboard: the moulded top under the windscreen, the binnacle over two dials (lit),
    the steering wheel on its column on the left, the centre stack with its vents and radio, the
    glovebox on the right."""
    W = 1.40
    m = Mesh()
    prof = [(0.0, 0.0), (0.05, 0.0), (0.12, 0.32), (0.40, 0.42), (0.55, 0.44), (0.55, 0.30), (0.20, 0.18), (0.05, -0.10)]
    m.merge(S.extrude([(z, y) for z, y in prof], W, 0.012 if lod == 0 else 0.0, "housing", origin=(W / 2, 0.40, -0.05), right=(0, 0, -1), up=(0, 1, 0)))     # pushed toward -X across the car
    xd = -0.37
    # the binnacle's hood and its dials
    m.merge(_cushion((xd, 0.86, -0.20), (0.18, 0.05, 0.09), 0.03, lod, tag="housing"))
    for x in (-0.07, 0.07):
        m.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.055), (0.004, 0.055), (0.004, 0.0)], [16, 8, 6][lod], tag="dial"), (0, 0.25, 1), (xd + x, 0.80, -0.12)))
    # the steering wheel: rim, three spokes, the hub; its column into the dash
    col = np.array([xd, 0.72, 0.10])
    tilt = S.rotation((1, 0, 0), -0.40)
    wheel = Mesh()
    rim = [(np.cos(a) * 0.185, np.sin(a) * 0.185, 0.0) for a in np.linspace(0, 2 * np.pi, [24, 14, 8][lod] + 1)[:-1]]
    wheel.merge(S.sweep(rim, S.circle(0.016, [8, 5, 4][lod]), "housing", closed=True, up=(0, 0, 1)))
    for a in (0.0, np.pi, -np.pi / 2):
        wheel.merge(S.sweep([(0, 0, 0.01), (np.cos(a) * 0.17, np.sin(a) * 0.17, 0.0)], [(-0.025, -0.008), (0.025, -0.008), (0.025, 0.008), (-0.025, 0.008)], "housing", up=(0, 0, 1)))
    wheel.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.07), (0.04, 0.06), (0.05, 0.0)], [12, 8, 6][lod], tag="housing"), (0, 0, 1), (0, 0, -0.01)))
    m.merge(wheel.transformed(tilt, tuple(col)))
    m.merge(S.sweep([tuple(col + tilt @ np.array([0, 0, -0.05])), (xd, 0.66, -0.18)], S.circle(0.035, [8, 5, 4][lod]), "housing"))
    if lod < 2:
        # the centre stack: two vents, the radio, the heater's three knobs; the side vents; the glovebox
        for x in (-0.06, 0.06):
            m.merge(S.box((x, 0.76, -0.04), (0.05, 0.03, 0.01), "dark"))
        m.merge(S.box((0, 0.66, -0.03), (0.09, 0.025, 0.01), "dark"))
        m.merge(S.box((0, 0.66, -0.041), (0.03, 0.006, 0.001), "dial"))
        for x in (-0.06, 0.0, 0.06):
            m.merge(S.along(S.lathe([(0.0, 0.016), (0.015, 0.014), (0.015, 0.0)], 8, tag="chrome"), (0, 0, -1), (x, 0.58, -0.02)))
        for x in (-W / 2 + 0.08, W / 2 - 0.08):
            m.merge(S.along(S.lathe([(0.0, 0.04), (0.005, 0.04), (0.005, 0.0)], 10, tag="dark"), (0, 0, 1), (x, 0.76, 0.0)))
        m.merge(S.box((0.36, 0.62, 0.012), (0.18, 0.08, 0.004), "housing"))
        m.merge(S.box((0.36, 0.67, 0.002), (0.03, 0.008, 0.006), "chrome"))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "wheel_steel": dict(build=wheel_steel, materials=materials(), edge_radius=0.003, close=(0.0, TYRE["r"], 0.0), **_SPEC),
    "plate_fr": dict(build=plate_fr, materials=materials(), extra=_paint_plate, extra_first=True, edge_radius=0.001, close=(0.0, 0.055, 0.0),
                     states=_SPEC["states"], lods=2),
    "headlamp": dict(build=headlamp, materials=materials(), edge_radius=0.002, close=(0.0, 0.0, 0.0), **_SPEC),
    "tail_lamp": dict(build=tail_lamp, materials=materials(), edge_radius=0.002, close=(0.0, 0.0, 0.0), states=_SPEC["states"], lods=2),
    "wing_mirror": dict(build=wing_mirror, materials=materials(), edge_radius=0.002, close=(0.15, 0.06, 0.05), states=_SPEC["states"], lods=2),
    "wheel_alloy": dict(build=wheel_alloy, materials=materials(), edge_radius=0.002, close=(-0.15, 0.32, 0.0), **_SPEC),
    "car_seat": dict(build=car_seat, materials=materials(), edge_radius=0.003, close=(0.0, 0.5, -0.2), **_SPEC),
    "dashboard": dict(build=dashboard, materials=materials(), edge_radius=0.003, close=(-0.37, 0.8, 0.2), **_SPEC),
}
