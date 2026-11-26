"""Road details (S155). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

manhole: the Paris sewer manhole (regard d'égout, after ballu): a square cast-iron frame set in
the road with a round seat, the round cover with its cast rings, lettering (EAUX, ÉGOUTS) and
lifting slot, the fine checker of studs cast all over both (baked: `Checker`), the shaft under it
with its rungs. The cover is a part: open, it lies pried off beside the hole.
manhole_square: the square cover of the other kind (mc2015c): a square frame, a square cover with
a raised ring and rows of diamonds radiating from the middle, corner triangles.
valve_cover: the small round cover of a gas valve in the pavement (mc2015a): GAZ, a slot.

Coordinates: metres, Y up, x = 0 the middle, the front -Z; y = 0 the road's surface: everything
lies flush in it and the shaft goes down below.
"""
import numpy as np

import lettering as LT
import shapes as S
from poly import Mesh
from props import Material, Part


class Checker:
    """The studs cast in rows over a cover's and a frame's top (ballu): small squares standing up
    between dark grooves, turned 45 degrees; the tops polished lighter by tyres. Only on faces
    looking up; the sides are plain iron."""

    def __init__(self, pitch=0.030, base=(0.13, 0.125, 0.12), stud=(0.27, 0.26, 0.245), angle=45.0):
        self.pitch, self.angle = pitch, np.radians(angle)
        self.base, self.stud = np.array(base, np.float32), np.array(stud, np.float32)

    def __call__(self, P, N):
        x, z = P[:, 0], P[:, 2]
        u = x * np.cos(self.angle) + z * np.sin(self.angle)
        v = -x * np.sin(self.angle) + z * np.cos(self.angle)
        fu, fv = (u / self.pitch) % 1.0, (v / self.pitch) % 1.0
        top = N[:, 1] > 0.7
        stud = (fu > 0.24) & (fu < 0.76) & (fv > 0.24) & (fv < 0.76)
        col = np.where((stud | ~top)[:, None], self.stud[None] if True else None, self.base[None])
        col = np.where((~top)[:, None], self.base[None] * 1.25, col)
        joint = np.where(top & ~stud, 0.6, 0.0).astype(np.float32)
        unit = np.zeros(len(P), np.int64)
        return col.astype(np.float32), joint, unit


def materials():
    return {
        "iron": Material((0.20, 0.19, 0.18), under=(0.22, 0.20, 0.18), bare=(0.30, 0.20, 0.13), chip=0.0, grain=0.08,
                         pattern=Checker(), fades=False),
        "letter": Material((0.33, 0.32, 0.30), under=(0.30, 0.28, 0.26), bare=(0.36, 0.34, 0.31), chip=0.0, grain=0.05, fades=False),
        "hole": Material((0.03, 0.03, 0.03), kind="sand", chip=0.0, rusts=False, grain=0.1, sheds=False),
        "shaft": Material((0.26, 0.24, 0.21), kind="masonry", chip=0.0, rusts=False, grain=0.2, sheds=False),
        "water": Material((0.05, 0.06, 0.06), kind="glass", chip=0.0, rusts=False, grain=0.05, sheds=False),
        "rung": Material((0.16, 0.12, 0.09), under=(0.30, 0.18, 0.10), bare=(0.32, 0.18, 0.09), chip=0.5, grain=0.1, fixing=True),
    }


def _outward(m):
    """Flip a closed mesh's faces if they point in (its signed volume negative)."""
    P, T, _ = m.triangles()
    P = np.asarray(P)
    T = np.asarray(T)
    vol = np.einsum("ij,ij->i", P[T[:, 0]], np.cross(P[T[:, 1]], P[T[:, 2]])).sum()
    if vol < 0:
        m.faces = [tuple(reversed(f)) for f in m.faces]
    return m


def _square_ring(n):
    """n points round a unit square, at evenly spaced angles (so they pair with a circle's)."""
    out = []
    for k in range(n):
        a = 2 * np.pi * k / n + np.pi / 4  # the corners fall on samples (n a multiple of 4)
        c, s = np.cos(a), np.sin(a)
        t = 1.0 / max(abs(c), abs(s))
        out.append((c * t, s * t))
    return out


def _frame_square_round(half, r, y0, y1, n, chamfer=0.0):
    """A square plate with a round hole: the frame of a round cover."""
    sq = _square_ring(n)
    circ = [(np.cos(2 * np.pi * k / n + np.pi / 4), np.sin(2 * np.pi * k / n + np.pi / 4)) for k in range(n)]
    ob = [np.array([x * half, y0, z * half]) for x, z in sq]
    ot = [np.array([x * half, y1, z * half]) for x, z in sq]
    it = [np.array([x * r, y1, z * r]) for x, z in circ]
    ib = [np.array([x * r, y0, z * r]) for x, z in circ]
    rings = [ob, ot]
    if chamfer:  # the seat: the hole's edge chamfered down to where the cover rests
        rings += [[np.array([x * (r + chamfer), y1, z * (r + chamfer)]) for x, z in circ],
                  [np.array([x * r, y1 - chamfer, z * r]) for x, z in circ]]
    else:
        rings += [it]
    rings += [ib, ob]
    m = Mesh()
    m.loft(rings, "iron", caps=(False, False))
    return _outward(S.weld(m))


def _frame_square_square(half, inner, y0, y1, chamfer=0.0):
    """A square plate with a square hole (the square cover's frame)."""
    m = Mesh()
    sq = [(-1, -1), (1, -1), (1, 1), (-1, 1)]
    ob = [np.array([x * half, y0, z * half]) for x, z in sq]
    ot = [np.array([x * half, y1, z * half]) for x, z in sq]
    it = [np.array([x * (inner + chamfer), y1, z * (inner + chamfer)]) for x, z in sq]
    ic = [np.array([x * inner, y1 - chamfer, z * inner]) for x, z in sq]
    ib = [np.array([x * inner, y0, z * inner]) for x, z in sq]
    m.loft([ob, ot, it, ic, ib, ob], "iron", caps=(False, False))
    return _outward(S.weld(m))


def _band(r, w, y, h, sides, tag="iron"):
    """A raised ring cast on a cover's face: `w` wide, `h` proud, at radius r."""
    m = S.lathe([(y, r + w / 2), (y + h, r + w / 2 - h * 0.6), (y + h, r - w / 2 + h * 0.6), (y, r - w / 2)], sides,
                tag=tag, caps=(False, False))
    return m


def _arc_text(text, r, y, height, top=True, depth=0.004, spacing=0.82, tag="letter"):
    """Raised letters round an arc of radius r on a face at height y: across the top (θ round
    90°, their tops outward) or across the bottom (θ round 270°, their tops inward), both read
    from the front."""
    m = Mesh()
    step = height * spacing / r
    n = len(text)
    mid = np.pi / 2 if top else -np.pi / 2
    for k, ch in enumerate(text):
        if ch == " ":
            continue
        off = (k - (n - 1) / 2) * step
        th = mid + off if top else mid - off
        radial = np.array([np.cos(th), 0.0, np.sin(th)])
        if top:
            up, right = radial, np.array([-np.sin(th), 0.0, np.cos(th)])
        else:
            up, right = -radial, np.array([np.sin(th), 0.0, -np.cos(th)])
        right = -right if top else right
        if np.cross(right, up)[1] < 0:
            right = -right
        m.merge(LT.mesh(ch, height, depth, origin=(radial[0] * r, y, radial[2] * r), right=tuple(right), up=tuple(up),
                        weight=1.3, tag=tag))
    return m


# --- manhole (the card: ballu straightened) ----------------------------------------------------------
MH_HALF = 0.43           # the square frame: half its side
MH_SEAT = 0.335          # the round hole
MH_COVER = (0.325, 0.038)  # the cover: radius, thickness
MH_SHAFT = (0.32, 1.40)  # the shaft under it: radius, depth


def _cover_round(lod):
    r, t = MH_COVER
    top = -0.003
    sides = [32, 16, 10][lod]
    m = S.lathe([(top - t, 0.0), (top - t, r - 0.012), (top - 0.012, r), (top, r), (top, 0.0)], sides, tag="iron")
    if lod == 0:
        for rr, w in ((0.300, 0.014), (0.205, 0.012), (0.105, 0.010)):
            m.merge(_band(rr, w, top, 0.005, sides))
        m.merge(_arc_text("EAUX", 0.252, top, 0.042, top=True))
        m.merge(_arc_text("ÉGOUTS", 0.252, top, 0.042, top=False))
        m.merge(S.box((0, top + 0.0005, 0), (0.042, 0.001, 0.013), "hole"))  # the lifting slot
        m.merge(_band(0.058, 0.012, top, 0.005, 12))
    return m


def _shaft(lod):
    """The shaft under the frame: a masonry tube seen from inside, dark water at its foot, iron
    rungs down one side."""
    if lod > 0:
        return Mesh()
    r, d = MH_SHAFT
    m = S.lathe([(-d, r), (-0.10, r)], 16, tag="shaft", caps=(False, False))
    m.faces = [tuple(reversed(f)) for f in m.faces]  # seen from inside
    m.merge(S.box((0, -d + 0.08, 0), (r * 0.72, 0.005, r * 0.72), "water"))
    for k in range(4):
        y = -0.32 - k * 0.28
        z = r - 0.01
        m.merge(S.pipe([(-0.14, y, z), (-0.14, y, z - 0.12), (0.14, y, z - 0.12), (0.14, y, z)], 0.011, 6, tag="rung"))
    return m


def manhole(lod):
    sides = [32, 16, 8][lod]
    body = _frame_square_round(MH_HALF, MH_SEAT, -0.10, 0.0, sides, 0.01 if lod == 0 else 0.0)
    body.merge(_shaft(lod))
    cover = _cover_round(lod)
    parts = {"body": Part(body), "cover": Part(cover, (0.0, 0.0, 0.0), {"move": [0.0, 0.035, -0.74]})}
    if lod > 0:
        merged = Mesh()
        for p in parts.values():
            merged.merge(p.mesh)
        return {"body": Part(merged)}
    return parts


# --- manhole_square (mc2015c) ------------------------------------------------------------------------
MS_HALF = 0.40
MS_INNER = 0.31
MS_T = 0.04


def _cover_square(lod):
    h = MS_INNER - 0.006
    top = -0.003
    if lod == 2:
        return S.box((0, top - MS_T / 2, 0), (h, MS_T / 2, h), "iron")
    m = S.chamfer_box((0, top - MS_T / 2, 0), (h, MS_T / 2, h), 0.006 if lod == 0 else 0.002, "iron", edges="top")
    if lod > 0:
        return m
    m.merge(_band(0.27, 0.016, top, 0.006, 32))  # the big ring
    m.merge(_band(0.105, 0.012, top, 0.005, 20))
    for count, rr, size in ((8, 0.065, 0.018), (14, 0.15, 0.026), (20, 0.215, 0.028), (26, 0.245, 0.022)):
        for k in range(count):  # the diamonds radiating from the middle
            a = 2 * np.pi * (k + 0.5 * (count % 2)) / count
            c = (np.cos(a) * rr, top, np.sin(a) * rr)
            d = S.prism(c, size, 0.006, 4, turn=a, tag="iron")
            d.verts = [np.array([v[0], v[1], v[2]]) for v in d.verts]
            m.merge(d)
    for sx in (1, -1):  # the corner triangles: a raised border round each
        for sz in (1, -1):
            pts = [(sx * (h - 0.02), sz * (h - 0.02)), (sx * (h - 0.02), sz * (h - 0.13)), (sx * (h - 0.13), sz * (h - 0.02))]
            for a, b in zip(pts, pts[1:] + pts[:1]):
                m.merge(S.sweep([(a[0], top + 0.003, a[1]), (b[0], top + 0.003, b[1])],
                                [(-0.006, -0.003), (0.006, -0.003), (0.006, 0.003), (-0.006, 0.003)], "iron", up=(0, 0, 1)))
    m.merge(S.box((0, top + 0.0005, 0), (0.04, 0.001, 0.012), "hole"))
    return m


def manhole_square(lod):
    body = _frame_square_square(MS_HALF, MS_INNER, -0.10, 0.0, 0.008 if lod == 0 else 0.0)
    if lod == 0:  # the frame's border moulding: a raised line round the hole
        for k in range(4):
            a, b = [(-1, -1), (1, -1), (1, 1), (-1, 1)][k], [(-1, -1), (1, -1), (1, 1), (-1, 1)][(k + 1) % 4]
            r = MS_INNER + 0.035
            body.merge(S.sweep([(a[0] * r, 0.003, a[1] * r), (b[0] * r, 0.003, b[1] * r)],
                               [(-0.007, -0.003), (0.007, -0.003), (0.007, 0.003), (-0.007, 0.003)], "iron", up=(0, 0, 1)))
        body.merge(_shaft(lod))
    parts = {"body": Part(body), "cover": Part(_cover_square(lod), (0.0, 0.0, 0.0), {"move": [0.0, 0.04, -0.70]})}
    if lod > 0:
        merged = Mesh()
        for p in parts.values():
            merged.merge(p.mesh)
        return {"body": Part(merged)}
    return parts


# --- valve_cover (mc2015a) ---------------------------------------------------------------------------
def valve_cover(lod):
    sides = [24, 12, 8][lod]
    r = 0.115
    m = S.lathe([(-0.06, r + 0.035), (0.0, r + 0.035), (0.0, r + 0.004), (-0.004, r + 0.002), (-0.004, 0.0)], sides,
                tag="iron", caps=(True, False))
    if lod == 0:
        m.merge(LT.mesh("GAZ", 0.038, 0.004, origin=(0.0, -0.004, 0.045), right=(-1, 0, 0), up=(0, 0, 1), weight=1.3, tag="letter"))
        m.merge(S.box((0, -0.0035, -0.01), (0.03, 0.001, 0.008), "hole"))
        m.merge(_band(r - 0.012, 0.01, -0.004, 0.004, sides))
    return {"body": Part(m)}


# --- gully_grate (dr1: the double gully grate at the kerb) ----------------------------------------------
GULLY = dict(grate=0.40, gap=0.06, rows=7, surround=0.07)
HUMP = dict(w=3.50, ramp=1.00, top=2.50, h=0.10)


def road_materials():
    m = materials()
    m.update({
        "grate": Material((0.22, 0.17, 0.13), under=(0.24, 0.18, 0.13), bare=(0.34, 0.22, 0.13), chip=0.0, grain=0.12, fades=False),
        "concrete": Material((0.62, 0.61, 0.58), kind="concrete", chip=0.0, rusts=False, grain=0.15),
        "asphalt": Material((0.16, 0.16, 0.17), kind="concrete", chip=0.0, rusts=False, grain=0.25, fades=False),
    })
    return m


def _grate(cx, lod):
    """One square grate lying in the road at x = cx: its frame, the bar down the middle, the bars
    between its rows of slots, the dark pit under them."""
    g, rows = GULLY["grate"], GULLY["rows"]
    m = Mesh()
    t = 0.035
    fr = 0.03
    for sx in (1, -1):
        m.merge(S.box((cx + sx * (g / 2 - fr / 2), -t / 2, 0), (fr / 2, t / 2, g / 2), "grate"))
        m.merge(S.box((cx, -t / 2, sx * (g / 2 - fr / 2)), (g / 2 - fr, t / 2, fr / 2), "grate"))
    m.merge(S.box((cx, -t / 2, 0), (0.025, t / 2, g / 2 - fr), "grate"))
    if lod < 2:
        inner = g - 2 * fr
        pitch = inner / rows
        for k in range(1, rows):
            z = -inner / 2 + k * pitch
            m.merge(S.box((cx, -t / 2, z), (g / 2 - fr, t / 2, (pitch - 0.022) / 2), "grate"))
        if lod == 0:  # the lifting slot through the bar and a rib across each slot's floor
            m.merge(S.box((cx, -0.001, -pitch * 0.5), (0.01, 0.001, 0.03), "hole"))
    m.merge(S.box((cx, -0.10, 0), (g / 2, 0.06, g / 2), "hole"))
    return m


def gully_grate(lod):
    g, gap, sr = GULLY["grate"], GULLY["gap"], GULLY["surround"]
    m = Mesh()
    for s in (1, -1):
        m.merge(_grate(s * (g + gap) / 2, lod))
    # the concrete surround they sit in, its top flush with the road
    W, D = 2 * g + gap + 2 * sr, g + 2 * sr
    outer = [(-W / 2, -D / 2), (W / 2, -D / 2), (W / 2, D / 2), (-W / 2, D / 2)]
    for k, (x0, x1, z0, z1) in enumerate(((-W / 2, W / 2, -D / 2, -g / 2), (-W / 2, W / 2, g / 2, D / 2),
                                          (-W / 2, -g - gap / 2, -g / 2, g / 2), (g + gap / 2, W / 2, -g / 2, g / 2), (-gap / 2, gap / 2, -g / 2, g / 2))):
        m.merge(S.box(((x0 + x1) / 2, -0.03, (z0 + z1) / 2), ((x1 - x0) / 2, 0.03, (z1 - z0) / 2), "concrete"))
    return {"body": Part(m)}


# --- speed_hump (hu1: a flat-topped hump with its painted teeth) -----------------------------------------
def speed_hump(lod):
    w, ramp, top, h = HUMP["w"], HUMP["ramp"], HUMP["top"], HUMP["h"]
    z0 = -(ramp + top / 2)
    prof = [(z0, 0.0), (-top / 2, h), (top / 2, h), (-z0, 0.0)]
    if lod == 0:  # the ramps' foot and head eased
        prof = [(z0, 0.0), (z0 + 0.15, 0.010), (-top / 2 - 0.15, h - 0.010), (-top / 2, h), (top / 2, h), (top / 2 + 0.15, h - 0.010), (-z0 - 0.15, 0.010), (-z0, 0.0)]
    outline = [(z, y) for z, y in prof]
    m = S.extrude(outline, w, 0.0, "asphalt", origin=(-w / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0))
    return {"body": Part(m)}


def _paint_hump(P, N, tag, tags, state, col):
    """White teeth on each ramp, their points up the slope (the French marking)."""
    w, ramp, top = HUMP["w"], HUMP["ramp"], HUMP["top"]
    sel = (tag == tags.index("asphalt")) & (N[:, 1] > 0.5)
    x, z = P[:, 0], P[:, 2]
    tooth = 0.50
    u = np.mod(x + w / 2, tooth) / tooth - 0.5                  # -0.5..0.5 across each tooth
    d = np.abs(z) - top / 2                                    # 0 at the ramp's head, `ramp` at its foot
    on_ramp = (d > 0.05) & (d < ramp - 0.05)
    t = (d - 0.05) / (ramp - 0.10)                             # 0 at the head (the point), 1 at the foot (the base)
    white = on_ramp & (np.abs(u) < 0.42 * t) & (np.abs(x) < w / 2 - 0.05)
    return np.where((sel & white)[:, None], np.array([0.88, 0.88, 0.85], np.float32), col)


ELEMENTS = {
    "gully_grate": dict(build=gully_grate, materials=road_materials(), states=["clean", "abandoned", "damaged", "burnt"], lods=3,
                        edge_radius=0.003, close=(0.0, 0.0, 0.0)),
    "speed_hump": dict(build=speed_hump, materials=road_materials(), extra=_paint_hump, extra_first=True,
                       states=["clean", "abandoned", "damaged", "burnt"], lods=2, edge_radius=0.004, close=(0.0, 0.1, -1.6)),
    "manhole": {
        "build": manhole,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
        "close": (0.0, 0.0, 0.0),
    },
    "manhole_square": {
        "build": manhole_square,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
        "close": (0.0, 0.0, 0.0),
    },
    "valve_cover": {
        "build": valve_cover,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.003,
        "close": (0.0, 0.0, 0.0),
    },
}
