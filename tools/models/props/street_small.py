"""Small street furniture (S173). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

bench_double: the Paris double bench (banc double, Davioud's model of the 1860s): two seats back to
back on two cast-iron end frames, each frame a central post with a crest, seat brackets pierced
with rings, legs of rings on a foot plate, the town's shield in the middle; green slats bolted on.
borne: the stone guard stone (borne chasse-roue) at a house's corner or beside a carriage gate:
a truncated cone, faceted, its top rounded, chipped where wheels struck it, leaning a little.
guard_bar: the cast-iron guard (chasse-roue en fonte) at the foot of a gate's jamb: a round bar
rising from a foot on the pavement and curving back into the wall.

Coordinates: metres, Y up, the front -Z, x = 0 the middle, standing on y = 0. For borne and
guard_bar the wall's face is z = 0 (the house +Z).
"""
import numpy as np

import lettering
import shapes as S
import surfaces
from poly import Mesh
from props import Material, Part

_STATES = ["clean", "abandoned", "damaged", "burnt"]

# --- bench_double (canal straightened: the end frame square-on) ---------------------------------
B_LEN = 1.90             # the slats' length
B_FRAMES = 0.78          # the end frames at ±this
B_SEAT = 0.44            # the seat's top
B_REACH = 0.50           # each seat's front edge from the middle
B_SLAT = (0.105, 0.032)  # a slat: width, thickness
B_BACK = (0.64, 0.80)    # the back board on the post: bottom, top
B_POST_TOP = 0.86


def bench_materials():
    return {
        "iron": Material((0.70, 0.72, 0.70), under=(0.40, 0.26, 0.16), bare=(0.30, 0.20, 0.14), chip=0.9, grain=0.08),
        "slat": Material((0.13, 0.30, 0.21), under=(0.40, 0.36, 0.28), bare=(0.48, 0.40, 0.30), kind="wood", rusts=False,
                         palette=[(0.13, 0.30, 0.21), (0.12, 0.28, 0.20), (0.14, 0.31, 0.22)], vary=0.04),
        "bolt": Material((0.20, 0.20, 0.20), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
        "stone": Material((0.68, 0.65, 0.58), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "cast": Material((0.13, 0.13, 0.14), under=(0.30, 0.18, 0.10), bare=(0.32, 0.18, 0.09), chip=0.6, grain=0.1),
    }


def _ring_yz(x, y, z, r, t, n=12):
    """A cast ring standing in the frame's plane (y, z), at x, its section t square."""
    pts = [(x, y + np.sin(a) * r, z + np.cos(a) * r) for a in np.linspace(0, 2 * np.pi, n + 1)[:-1]]
    return S.sweep(pts, [(-t / 2, -t / 2), (t / 2, -t / 2), (t / 2, t / 2), (-t / 2, t / 2)], "iron", closed=True, up=(1, 0, 0))


def _plate_yz(x, outline, t, tag="iron", c=0.0):
    """An outline of (z, y) points as a plate t thick centred on x (the frame's plane)."""
    return S.extrude(outline, t, c, tag, origin=(x + t / 2, 0.0, 0.0), right=(0, 0, -1), up=(0, 1, 0))


def _end_frame(x, lod):
    m = Mesh()
    t = 0.035
    c = 0.006 if lod == 0 else 0.0
    # the foot plate, the central post rising to its crest
    m.merge(S.chamfer_box((x, 0.015, 0), (0.035, 0.015, 0.16), 0.006, "iron", edges="top") if lod < 2 else S.box((x, 0.015, 0), (0.035, 0.015, 0.16), "iron"))
    post = [(0.03, 0.03), (0.045, 0.30), (0.035, 0.42), (0.03, B_POST_TOP - 0.06), (0.05, B_POST_TOP - 0.02), (0.0, B_POST_TOP + 0.03),
            (-0.05, B_POST_TOP - 0.02), (-0.03, B_POST_TOP - 0.06), (-0.035, 0.42), (-0.045, 0.30), (-0.03, 0.03)]
    m.merge(_plate_yz(x, post, t, c=c))
    for s in (1, -1):
        # the seat bracket: its top level under the slats, its underside sweeping down to the post
        br = [(s * 0.03, B_SEAT - 0.035), (s * B_REACH, B_SEAT - 0.035), (s * B_REACH, B_SEAT - 0.075), (s * (B_REACH - 0.06), B_SEAT - 0.09),
              (s * 0.25, B_SEAT - 0.13), (s * 0.10, B_SEAT - 0.22), (s * 0.03, B_SEAT - 0.26)]
        if s < 0:
            br = br[::-1]
        m.merge(_plate_yz(x, br, t * 0.8, c=c))
        # the leg: a strut from the bracket's middle to the foot, rings along it
        m.merge(S.sweep([(x, 0.03, s * 0.14), (x, B_SEAT - 0.20, s * 0.24)], [(-t / 2, -0.015), (t / 2, -0.015), (t / 2, 0.015), (-t / 2, 0.015)],
                        "iron", up=(1, 0, 0)))
        if lod < 2:
            m.merge(_ring_yz(x, 0.11, s * 0.13, 0.055, 0.02, 12 if lod == 0 else 6))
            m.merge(_ring_yz(x, B_SEAT - 0.10, s * 0.34, 0.035, 0.016, 10 if lod == 0 else 6))
        if lod == 0:
            m.merge(_ring_yz(x, 0.25, s * 0.11, 0.045, 0.018, 12))
            m.merge(_ring_yz(x, B_SEAT - 0.08, s * 0.18, 0.03, 0.014, 10))
            # the back board's bracket on the post
            m.merge(S.box((x, (B_BACK[0] + B_BACK[1]) / 2, s * 0.045), (t * 0.4, (B_BACK[1] - B_BACK[0]) / 2, 0.012), "iron"))
    if lod == 0:  # the shield cast on the post's middle, both faces
        shield = [(0.05, 0.62), (0.05, 0.50), (0.0, 0.44), (-0.05, 0.50), (-0.05, 0.62)]
        m.merge(_plate_yz(x, shield, t + 0.016, c=0.004))
        m.merge(S.prism((x - t / 2 - 0.008, 0.545, 0), 0.018, 0.006, 6, axis=(-1, 0, 0), tag="iron"))
        m.merge(S.prism((x + t / 2 + 0.008, 0.545, 0), 0.018, 0.006, 6, axis=(1, 0, 0), tag="iron"))
    return m


def bench_double(lod):
    m = Mesh()
    for s in (1, -1):
        m.merge(_end_frame(s * B_FRAMES, lod))
    w, th = B_SLAT
    unit = 1
    c = 0.006 if lod == 0 else 0.0
    for s in (1, -1):
        for k in range(3):  # three slats a seat, gaps between
            z0 = s * (0.12 + k * (w + 0.018))
            z1 = z0 + s * w
            slat = S.chamfer_box((0, B_SEAT - th / 2, (z0 + z1) / 2), (B_LEN / 2, th / 2, w / 2), c, "slat", edges="top") if c else \
                S.box((0, B_SEAT - th / 2, (z0 + z1) / 2), (B_LEN / 2, th / 2, w / 2), "slat")
            m.merge(slat.set_unit(unit))
            unit += 1
            if lod == 0:  # carriage bolts over the frames
                for x in (B_FRAMES, -B_FRAMES):
                    m.merge(S.prism((x, B_SEAT, (z0 + z1) / 2), 0.011, 0.005, 6, tag="bolt"))
        # the back board on the post
        z = s * 0.075
        board = S.box((0, (B_BACK[0] + B_BACK[1]) / 2, z), (B_LEN / 2, (B_BACK[1] - B_BACK[0]) / 2, th / 2), "slat")
        m.merge(board.set_unit(unit))
        unit += 1
        if lod == 0:
            for x in (B_FRAMES, -B_FRAMES):
                for y in (B_BACK[0] + 0.04, B_BACK[1] - 0.04):
                    m.merge(S.prism((x, y, z + s * th / 2), 0.011, 0.005, 6, axis=(0, 0, s), tag="bolt"))
    return {"body": Part(m)}


# --- borne (glatigny: the lanes' guard stones) -------------------------------------------------------
def borne(lod):
    sides = [10, 7, 5][lod]
    prof = [(0.0, 0.17), (0.30, 0.15), (0.48, 0.13), (0.55, 0.11), (0.60, 0.07), (0.62, 0.0)] if lod == 0 else \
        [(0.0, 0.17), (0.48, 0.13), (0.60, 0.07), (0.62, 0.0)]
    m = S.lathe(prof, sides, turn=0.2, tag="stone", caps=(False, False))
    if lod == 0:  # a chip where a wheel struck it, on the street's side
        m = S.clip(m, (0.0, 0.47, -0.125), (0.25, 0.55, -1.0), "stone", rough=0.01, seed=3)
    # it leans a little away from the street, against the wall it guards
    lean = np.array([[1, 0, 0], [0, 1, 0], [0, 0.035, 1]], np.float64)
    m.verts = [lean @ v for v in m.verts]
    return {"body": Part(m.transformed(np.eye(3), (0.0, 0.0, -0.20)))}


# --- guard_bar (guard43) -------------------------------------------------------------------------------
def guard_bar(lod):
    m = Mesh()
    r = 0.035
    sides = [10, 6, 4][lod]
    n = [10, 5, 3][lod]
    # from its foot 0.38 out from the wall, up and round in a quarter circle into the wall at 0.70
    R = 0.36
    path = [(0.0, 0.05, -0.38)] + [(0.0, 0.34 + np.sin(a) * R, -0.02 - np.cos(a) * R) for a in np.linspace(0.12, np.pi / 2, n)]
    path = [(0.0, 0.05, -0.38), (0.0, 0.32, -0.38)] + path[2:]
    m.merge(S.sweep(path, S.circle(r, sides), "cast", up=(1, 0, 0)))  # the path lies in the y-z plane
    m.merge(S.lathe([(0.0, 0.055), (0.02, 0.055), (0.035, 0.042), (0.05, r)], sides, tag="cast").transformed(np.eye(3), (0.0, 0.0, -0.38)))
    flange = S.lathe([(0.0, 0.06), (0.012, 0.06), (0.02, 0.045)], sides, tag="cast")
    m.merge(S.along(flange, (0, 0, -1), (0.0, 0.70, 0.0)))
    if lod == 0:
        for k in range(3):
            a = 2 * np.pi * k / 3 + 0.5
            m.merge(S.prism((np.cos(a) * 0.045, 0.70 + np.sin(a) * 0.045, -0.012), 0.009, 0.006, 6, axis=(0, 0, -1), tag="bolt"))
    return {"body": Part(m)}


# --- bin_hoop (bag_hoop: the bag bin on its post) ----------------------------------------------------
HOOP = dict(r=0.205, y=0.86, post_z=0.265, post=(0.030, 0.014))   # the ring: radius, height; the post behind it


def bin_materials():
    m = bench_materials()
    m.update({
        "green": Material((0.10, 0.34, 0.20), under=(0.55, 0.55, 0.52), bare=(0.30, 0.20, 0.14), chip=0.7, grain=0.06),
        "bag": Material((0.34, 0.58, 0.32), kind="rubber", chip=0.0, rusts=False, grain=0.10, fades=False),
        "litter": Material((0.70, 0.68, 0.62), kind="paper", chip=0.0, rusts=False, grain=0.2,
                           palette=[(0.75, 0.74, 0.70), (0.55, 0.20, 0.18), (0.25, 0.35, 0.55), (0.80, 0.70, 0.35)], vary=0.08),
        "grey": Material((0.56, 0.57, 0.56), under=(0.45, 0.45, 0.44), bare=(0.30, 0.20, 0.14), chip=0.5, grain=0.06),
        "yellow": Material((0.93, 0.76, 0.08), under=(0.70, 0.70, 0.68), bare=(0.35, 0.22, 0.12), chip=0.6, grain=0.04),
        "label": Material((0.12, 0.22, 0.52), kind="paper", chip=0.0, rusts=False, grain=0.03),
        "slot": Material((0.03, 0.03, 0.03), chip=0.0, rusts=False, grain=0.02, fades=False),
        "earth": Material((0.22, 0.17, 0.12), kind="sand", chip=0.0, rusts=False, grain=0.25),
        "drain": Material((0.10, 0.10, 0.10), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.3, grain=0.1),
        "band": Material((0.88, 0.88, 0.85), under=(0.25, 0.22, 0.20), bare=(0.25, 0.22, 0.20), chip=0.5, rusts=False, grain=0.03),
    })
    m["cast"] = Material((0.20, 0.18, 0.16), under=(0.30, 0.18, 0.10), bare=(0.32, 0.18, 0.09), chip=0.6, grain=0.1)
    return m


def fountain_materials():
    m = bin_materials()
    m["cast"] = Material((0.11, 0.25, 0.19), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.08)
    return m


def _bag(lod, r, y_top, y_low, seed=1):
    """A litter bag hung from a ring of radius r at y_top: folded over the ring, bulging, knotted under."""
    sides = [14, 8, 6][lod]
    rng = np.random.default_rng(seed)
    bumps = rng.uniform(-1, 1, (sides, 3))
    h = y_top - y_low

    def flute(j, y):
        t = (y_top - y) / h
        return 1.0 + 0.10 * t * (bumps[j, 0] + 0.5 * np.sin(t * 7 + bumps[j, 1] * 3))

    prof = [(y_low, 0.0), (y_low + h * 0.06, r * 0.45), (y_low + h * 0.22, r * 0.95), (y_low + h * 0.50, r * 1.06),
            (y_low + h * 0.80, r * 1.02), (y_top - 0.004, r * 0.99)]
    if lod == 2:
        prof = [prof[0], prof[2], prof[3], prof[5]]
    m = S.lathe(prof, sides, flute=flute, tag="bag", caps=(False, True))
    if lod < 2:  # the fold hanging over the ring, its hem uneven
        hem = [(y_top - 0.07, r + 0.018), (y_top + 0.004, r + 0.012)]
        m.merge(S.lathe(hem, sides, flute=lambda j, y: 1.0 + 0.04 * bumps[j, 2], tag="bag", caps=(False, False)))
    return m


def bin_hoop(lod):
    r, y, pz = HOOP["r"], HOOP["y"], HOOP["post_z"]
    pw, pt = HOOP["post"]
    m = Mesh()
    # the post: a flat bar up the back, its head bent forward to hold the ring
    path = [(0.0, 0.02, pz), (0.0, y - 0.03, pz), (0.0, y + 0.03, pz - 0.035), (0.0, y + 0.035, r + 0.035)]
    m.merge(S.sweep(path if lod == 0 else [path[0], path[1], path[3]], [(-pw, -pt), (pw, -pt), (pw, pt), (-pw, pt)], "green", up=(1, 0, 0)))
    m.merge(S.chamfer_box((0.0, 0.006, pz), (0.07, 0.006, 0.05), 0.003, "green", edges="top") if lod < 2 else S.box((0, 0.006, pz), (0.07, 0.006, 0.05), "green"))
    # the ring: a flat band, its clamp at the back
    n = [24, 12, 8][lod]
    ring = [(np.cos(a) * r, y, np.sin(a) * r) for a in np.linspace(0, 2 * np.pi, n + 1)[:-1]]
    m.merge(S.sweep(ring, [(-0.006, -0.018), (0.006, -0.018), (0.006, 0.018), (-0.006, 0.018)], "green", closed=True))
    m.merge(S.box((0.0, y + 0.01, r + 0.02), (0.05, 0.03, 0.016), "green"))
    if lod == 0:
        for x in (-0.03, 0.03):
            m.merge(S.prism((x, y + 0.01, r + 0.036), 0.008, 0.005, 6, axis=(0, 0, 1), tag="bolt"))
        for x in (-0.045, 0.045):
            m.merge(S.prism((x, 0.012, pz), 0.010, 0.006, 6, tag="bolt"))
    m.merge(_bag(lod, r - 0.008, y, 0.24))
    return {"body": Part(m)}


# --- bin_cage (cage: the steel-rod basket) -----------------------------------------------------------
CAGE = [(0.0, 0.10), (0.06, 0.16), (0.30, 0.225), (0.55, 0.230), (0.76, 0.200), (0.84, 0.185)]   # (y, r) of the rods


def _cage_r(y):
    ys, rs = zip(*CAGE)
    return float(np.interp(y, ys, rs))


def _hoop(r, y, w, t, tag, n, flare=0.0):
    path = [(np.cos(a) * r, y, np.sin(a) * r) for a in np.linspace(0, 2 * np.pi, n + 1)[:-1]]
    prof = [(-t, -w), (t, -w), (t + flare, w), (-t + flare, w)]
    return S.sweep(path, prof, tag, closed=True)


def bin_cage(lod):
    m = Mesh()
    rods = [24, 12, 8][lod]
    n = [24, 12, 8][lod]
    ys = np.linspace(0.04, 0.84, [9, 5, 3][lod])
    for k in range(rods):
        a = 2 * np.pi * (k + 0.5) / rods
        path = [(np.cos(a) * _cage_r(y), y, np.sin(a) * _cage_r(y)) for y in ys]
        m.merge(S.sweep(path, S.circle(0.0045, [5, 4, 3][lod]), "grey", caps=lod == 0))
    m.merge(_hoop(_cage_r(0.04), 0.03, 0.03, 0.006, "grey", n))
    m.merge(_hoop(_cage_r(0.42), 0.42, 0.012, 0.004, "grey", n))
    # the top: a rolled rim flaring out over the rods
    m.merge(_hoop(0.19, 0.855, 0.022, 0.005, "grey", n, flare=0.035))
    if lod < 2:
        m.merge(_hoop(0.225, 0.878, 0.006, 0.008, "grey", n))
    # the foot ring on the pavement and its bolts
    m.merge(S.lathe([(0.0, 0.13), (0.012, 0.13), (0.02, 0.11), (0.03, 0.10)], n, tag="grey", caps=(False, True)))
    if lod == 0:  # crumpled litter at the bottom (the bag stolen, as in the photo)
        for i, (x, z, s) in enumerate(((0.04, -0.03, 0.05), (-0.06, 0.04, 0.04), (0.0, 0.07, 0.035))):
            lump = S.lathe([(0.0, 0.0), (s * 0.5, s), (s * 1.4, s * 0.8), (s * 1.8, 0.0)], 5, turn=i, tag="litter")
            m.merge(lump.transformed(np.eye(3), (x, 0.03, z)).set_unit(i + 1))
    return {"body": Part(m)}


# --- bollard (potelets_aubry: the Paris cast-iron potelet) ---------------------------------------------
BOLLARD = [(0.0, 0.062), (0.018, 0.062), (0.030, 0.054), (0.050, 0.050), (0.075, 0.046), (0.78, 0.040), (0.80, 0.047),
           (0.835, 0.047), (0.85, 0.036), (0.88, 0.030), (0.90, 0.038), (0.935, 0.046), (0.965, 0.042), (0.99, 0.028),
           (1.005, 0.0)]


def bollard(lod):
    sides = [12, 8, 6][lod]
    prof = BOLLARD if lod == 0 else [BOLLARD[i] for i in (0, 2, 5, 6, 7, 9, 11, 13, 14)] if lod == 1 else \
        [BOLLARD[i] for i in (0, 5, 7, 9, 11, 14)]
    m = S.lathe(prof, sides, tag="cast", caps=(False, False))
    if lod == 0:  # the reflective band round the head
        m.merge(S.lathe([(0.805, 0.0485), (0.83, 0.0485)], sides, tag="band", caps=(False, False)))
    return {"body": Part(m)}


# --- post_box (wall_box: the yellow letter box on a wall) ----------------------------------------------
POST = dict(w=0.46, h=0.58, d=0.20, low=1.00)   # the box's width, height, depth; its foot above the pavement


def post_box(lod):
    w, h, d, lo = POST["w"], POST["h"], POST["d"], POST["low"]
    m = Mesh()
    c = 0.012 if lod == 0 else 0.0
    body = S.chamfer_box((0, lo + h / 2, -d / 2), (w / 2, h / 2, d / 2), c, "yellow", edges="front") if c else \
        S.box((0, lo + h / 2, -d / 2), (w / 2, h / 2, d / 2), "yellow")
    m.merge(body)
    # the hood over the slots, sloping off the rain
    hood = [(0.0, lo + h), (-d - 0.03, lo + h - 0.03), (-d - 0.03, lo + h - 0.05), (0.0, lo + h - 0.02)]
    m.merge(S.extrude([(z, y) for z, y in hood], w + 0.02, 0.0, "yellow", origin=(-w / 2 - 0.01, 0, 0), right=(0, 0, 1), up=(0, 1, 0)))
    if lod < 2:
        sy = lo + h - 0.10
        for sx in (-w / 4, w / 4):  # two slots, a blue label under each
            m.merge(S.box((sx, sy, -d - 0.002), (0.085, 0.009, 0.003), "slot"))
            m.merge(S.box((sx, sy - 0.05, -d - 0.002), (0.095, 0.025, 0.002), "label"))
        # the collection door: a raised frame, its lock, the times plate
        door = S.panel(w - 0.07, h - 0.20, t=0.008, border=0.03, kind="inset", depth=0.004, bevel=0.008, tag="yellow",
                       origin=(0.0, lo + 0.03 + (h - 0.20) / 2, -d))
        m.merge(door)
        m.merge(S.box((0.0, lo + 0.24, -d - 0.008), (0.035, 0.05, 0.002), "label"))
        if lod == 0:
            m.merge(S.prism((w / 2 - 0.07, lo + 0.20, -d - 0.008), 0.012, 0.008, 10, axis=(0, 0, -1), tag="bolt"))
            for sx in (-w / 2 + 0.04, w / 2 - 0.04):
                m.merge(S.prism((sx, lo + 0.04, -d - 0.008), 0.006, 0.004, 6, axis=(0, 0, -1), tag="bolt"))
    return {"body": Part(m)}


def _paint_post_box(P, N, tag, tags, state, col):
    """The labels' white words and the raised words at the box's foot (no brand: the town's own post)."""
    w, h, d, lo = POST["w"], POST["h"], POST["d"], POST["low"]
    front = N[:, 2] < -0.5
    lab = (tag == tags.index("label")) & front
    sy = lo + h - 0.15
    words = np.zeros(len(P), bool)
    for sx, text in ((w / 4, "VILLE"), (-w / 4, "AUTRES")):  # the reader's left is +x
        words |= lettering.mask(P, text, np.array([sx, sy, -d], np.float32), 0.018, (-1, 0, 0), (0, 1, 0), weight=1.2)
    words |= lettering.mask(P, "LETTRES", np.array([0, lo + 0.255, -d], np.float32), 0.012, (-1, 0, 0), (0, 1, 0))
    words |= lettering.mask(P, "LEVEES 9H 17H", np.array([0, lo + 0.22, -d], np.float32), 0.010, (-1, 0, 0), (0, 1, 0))
    col = np.where((lab & words)[:, None], np.array([0.92, 0.92, 0.90], np.float32), col)
    yel = (tag == tags.index("yellow")) & front
    raised = lettering.mask(P, "NE PAS DEPOSER DE JOURNAUX", np.array([0, lo + 0.075, -d], np.float32), 0.016, (-1, 0, 0), (0, 1, 0))
    return np.where((yel & raised)[:, None], col * 0.82, col)


# --- tree_grille (round: the cast-iron tree grate) ---------------------------------------------------
def tree_grille(lod):
    m = surfaces.grille(r_out=0.72, r_in=0.24, rings=[7, 5, 3][lod], spokes=[24, 16, 8][lod], t=0.03, origin=(0, 0.0, 0),
                        tag="cast", hole_tag="earth", square=True, lod=min(lod, 1))
    if lod == 0:  # the line where the two halves meet, and their lifting holes
        m.merge(S.box((0.0, -0.001, 0.0), (0.004, 0.001, 0.78), "drain"))
        for z in (-0.5, 0.5):
            m.merge(S.box((0.06, -0.001, z), (0.02, 0.001, 0.008), "drain"))
    return {"body": Part(m)}


# --- fountain_wall (applied: the cast-iron wall fountain of 1872) -------------------------------------
FOUNT = dict(h=1.95, w=0.96, t=0.05, arch_c=1.55, arch_r=0.40, basin=(1.02, 0.17))


def _fount_outline(n):
    """The back plate's half outline (x, y): wide foot, waisted, the consoles, the arch."""
    ac, ar = FOUNT["arch_c"], FOUNT["arch_r"]
    side = [(0.48, 0.0), (0.48, 0.12), (0.44, 0.22), (0.37, 0.40), (0.35, 0.55), (0.35, 1.30), (0.40, 1.40), (0.40, ac)]
    arch = [(np.cos(a) * ar, ac + np.sin(a) * ar) for a in np.linspace(0, np.pi, n + 1)]
    right = side + arch[1:-1]
    return right + [(-x, y) for x, y in reversed(side)]


def _mascaron(lod, y):
    """The head the water comes from: a face, its hair falling to the shoulders, the mouth's pipe."""
    m = Mesh()
    sides = [10, 6, 5][lod]
    face = S.lathe([(0.0, 0.0), (0.02, 0.07), (0.05, 0.085), (0.085, 0.06), (0.10, 0.0)], sides, tag="cast")
    face.verts = [np.array([v[0] * 0.9, v[2] * 1.25, v[1]]) for v in face.verts]  # its depth out of the plate, taller than wide
    face.faces = [tuple(reversed(f)) for f in face.faces]
    m.merge(face.transformed(np.eye(3), (0, y, -FOUNT["t"] - 0.10)))
    if lod < 2:
        for s in (1, -1):
            hair = S.lathe([(0.0, 0.0), (0.02, 0.04), (0.10, 0.045), (0.16, 0.02), (0.18, 0.0)], sides, tag="cast")
            m.merge(hair.transformed(S.rotation((0, 0, 1), s * 0.35), (s * 0.085, y - 0.12, -FOUNT["t"] - 0.03)))
        m.merge(S.lathe([(0.0, 0.0), (0.03, 0.05), (0.06, 0.03), (0.07, 0.0)], sides, tag="cast")
                .transformed(np.diag([1.6, 1.0, 0.8]), (0, y + 0.08, -FOUNT["t"] - 0.02)))  # the crown of hair
    if lod == 0:
        m.merge(S.prism((0, y - 0.07, -FOUNT["t"] - 0.08), 0.010, 0.05, 8, axis=(0, 0, -1), tag="drain"))  # the spout
        m.merge(S.prism((0, y - 0.005, -FOUNT["t"] - 0.13), 0.011, 0.02, 5, axis=(0, 0, -1), tag="cast"))  # the nose
    return m


def fountain_wall(lod):
    t = FOUNT["t"]
    ac, ar = FOUNT["arch_c"], FOUNT["arch_r"]
    n = [16, 10, 6][lod]
    m = Mesh()
    m.merge(S.extrude(_fount_outline(n), t, 0.008 if lod == 0 else 0.0, "cast", origin=(0, 0, 0), right=(1, 0, 0), up=(0, 1, 0)))
    sq = [(-0.02, -0.018), (0.02, -0.018), (0.02, 0.018), (-0.02, 0.018)]
    # the arch's moulding and the shell fanning out behind the head
    arc = [(np.cos(a) * (ar - 0.03), ac + np.sin(a) * (ar - 0.03), -t - 0.012) for a in np.linspace(0, np.pi, n + 1)]
    m.merge(S.sweep(arc, sq, "cast", up=(0, 0, -1)))
    if lod < 2:
        for k in range([9, 5][lod]):
            a = np.pi * (k + 0.5) / [9, 5][lod]
            R = S.rotation((0, 0, 1), a - np.pi / 2)
            rib = S.chamfer_box((0, 0.20, 0), (0.016, 0.13, 0.010), 0.004, "cast", edges="front") if lod == 0 else S.box((0, 0.20, 0), (0.016, 0.13, 0.010), "cast")
            m.merge(rib.transformed(R, (0, ac - 0.06, -t - 0.010)))
    # the pilasters, their consoles under the arch, the scrolls at the foot
    for s in (1, -1):
        pil = S.chamfer_box((s * 0.29, 0.95, -t - 0.012), (0.035, 0.42, 0.012), 0.005, "cast", edges="front") if lod < 2 else \
            S.box((s * 0.29, 0.95, -t - 0.012), (0.035, 0.42, 0.012), "cast")
        m.merge(pil)
        m.merge(S.chamfer_box((s * 0.31, 1.42, -t - 0.025), (0.07, 0.04, 0.025), 0.008, "cast", edges="front") if lod < 2 else
                S.box((s * 0.31, 1.42, -t - 0.025), (0.07, 0.04, 0.025), "cast"))
        if lod < 2:
            sc = [(s * (0.40 - 0.03 * np.cos(a)) , 0.28 + 0.10 * np.sin(a) * (1 - a / 7), -t - 0.012)
                  for a in np.linspace(0, 6.0, [14, 7][lod])]
            m.merge(S.sweep(sc, [(-0.015, -0.012), (0.015, -0.012), (0.015, 0.012), (-0.015, 0.012)], "cast", up=(0, 0, -1)))
    m.merge(_mascaron(lod, ac - 0.10))
    # the basin: half a cup on the plate, its rim rolled, the drop hanging under it
    by, br = FOUNT["basin"]
    cup = S.lathe([(-0.10, 0.0), (-0.09, 0.07), (-0.05, 0.14), (0.0, br), (0.015, br + 0.012), (0.03, br - 0.005)],
                  [14, 8, 6][lod], tag="cast", caps=(False, True))
    cup = S.clip(cup, (0, 0, 0), (0, 0, 1), "cast")
    m.merge(cup.transformed(np.eye(3), (0, by, -t)))
    drop = S.lathe([(0.0, 0.0), (0.10, 0.035), (0.22, 0.05), (0.30, 0.03), (0.34, 0.0)], [8, 6, 4][lod], tag="cast")
    drop.verts = [np.array([v[0], by - 0.10 - v[1], v[2] * 0.6 - t - 0.02]) for v in drop.verts]
    drop.faces = [tuple(reversed(f)) for f in drop.faces]
    m.merge(drop)
    # the drain grating on the pavement under it
    m.merge(S.box((0, 0.01, -0.20), (0.30, 0.01, 0.15), "drain"))
    if lod == 0:
        for k in range(7):
            m.merge(S.box((-0.24 + k * 0.08, 0.021, -0.20), (0.012, 0.002, 0.12), "earth"))
    return {"body": Part(m)}


# --- bike_hoop and lawn_hoops ---------------------------------------------------------------------------
def bike_hoop(lod):
    """The bicycle stand of the pavements: a steel tube bent into an inverted U, set in the
    pavement, a bar across it low down for small wheels."""
    m = Mesh()
    w, h, r = 0.70, 0.75, 0.024
    path = [(-w / 2, -0.05, 0.0), (-w / 2, h - 0.18, 0.0), (-w / 2 + 0.05, h - 0.03, 0.0), (0.0, h, 0.0), (w / 2 - 0.05, h - 0.03, 0.0), (w / 2, h - 0.18, 0.0), (w / 2, -0.05, 0.0)]
    m.merge(S.sweep(S.fillet(path, 0.15, 4) if lod == 0 else path, S.circle(r, [10, 6, 4][lod]), "green"))
    if lod < 2:
        m.merge(S.sweep([(-w / 2, 0.28, 0.0), (w / 2, 0.28, 0.0)], S.circle(r * 0.8, [8, 5][lod]), "green"))
        for x in (-w / 2, w / 2):  # the collars where it goes into the pavement
            m.merge(S.lathe([(0.0, r + 0.02), (0.01, r + 0.015), (0.015, r + 0.002)], 8, tag="green", caps=(False, False)).transformed(np.eye(3), (x, 0, 0)))
    return {"body": Part(m)}


def lawn_hoops(lod):
    """A 2 m run of the low hoop railing round the squares' lawns: overlapping arches of round bar
    on short posts, about knee high."""
    m = Mesh()
    L, hh, r = 2.0, 0.42, 0.007
    n = 5
    step = L / n
    k = [10, 6, 4][lod]
    for i in range(n + 1):  # each hoop spans two steps, so they overlap
        x0 = -L / 2 + (i - 1) * step
        pts = [(x0 + 2 * step * t, np.sin(np.pi * t) * hh, 0.0) for t in np.linspace(0, 1, k + 1)]
        pts = [p for p in pts if -L / 2 - 1e-6 <= p[0] <= L / 2 + 1e-6]
        if len(pts) > 1:
            m.merge(S.sweep(pts, S.circle(r, [5, 4, 3][lod]), "green"))
    if lod < 2:
        for i in range(n + 1):
            x = -L / 2 + i * step
            m.merge(S.lathe([(0.0, 0.012), (0.18, 0.010), (0.20, 0.016), (0.22, 0.0)], 6, tag="green").transformed(np.eye(3), (x, 0, 0)))
    return {"body": Part(m)}


ELEMENTS = {
    "bike_hoop": dict(build=bike_hoop, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.002, close=(0.0, 0.5, 0.0)),
    "lawn_hoops": dict(build=lawn_hoops, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.001, close=(0.0, 0.3, 0.0)),
    "bench_double": {
        "build": bench_double,
        "materials": bench_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
        "close": (B_FRAMES, 0.45, 0.0),  # an end frame
    },
    "borne": {
        "build": borne,
        "materials": bench_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.006,
        "close": (0.0, 0.35, -0.2),
    },
    "guard_bar": {
        "build": guard_bar,
        "materials": bench_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
        "close": (0.0, 0.4, -0.2),
    },
    "bin_hoop": dict(build=bin_hoop, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.003, close=(0.0, 0.85, 0.1)),
    "bin_cage": dict(build=bin_cage, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.002, close=(0.0, 0.8, 0.0)),
    "bollard": dict(build=bollard, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.003, close=(0.0, 0.85, 0.0)),
    "post_box": dict(build=post_box, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.004, extra=_paint_post_box,
                     extra_first=True, close=(0.0, POST["low"] + POST["h"] - 0.12, -POST["d"])),
    "tree_grille": dict(build=tree_grille, materials=bin_materials(), states=_STATES, lods=3, edge_radius=0.003, close=(0.4, 0.0, 0.0)),
    "fountain_wall": dict(build=fountain_wall, materials=fountain_materials(), states=_STATES, lods=3, edge_radius=0.005,
                          close=(0.0, FOUNT["arch_c"] - 0.15, -0.1)),
}
