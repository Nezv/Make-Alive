"""Street signs (S169). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

street_plate: the blue enamel street plate of an old town (plate_beaubourg, plate_damesme): a blue
field with white letters and a white line inside a raised green cast frame, rosettes at its corners,
a half-round plate over it with the quarter's name. Screwed to a house's wall: the wall's face is
z = 0, the plate's foot y = 0.
sign_stop, sign_giveway, sign_no_entry: French road signs on a galvanised pole (stop_fleuri,
giveway_lyon, giveway_back): an aluminium plate with a rolled edge, painted face (by position, in
`_paint`), rails and clamps on its back, the pole with its cap. Standing on y = 0.

The faces' colours and letters are paint (the `extra` painter), so the kit's wear goes over them.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

POLE = (0.038, 2.95)     # the pole: radius, height
SIGN_LOW = 2.20          # the sign's lowest point over the pavement (pedestrians walk under)
PLATE_T = 0.004
STOP_R = 0.70 / 2 / np.cos(np.pi / 8)   # the STOP octagon: 0.70 across its flats
GIVEWAY_SIDE = 0.90      # the give-way triangle's side
NO_ENTRY_R = 0.325       # the no-entry disc's radius
STREET = dict(w=0.72, h=0.40, arch=(0.20, 0.15), frame=0.032)
STREET_TEXT = ("RUE", "PASTEUR", "CENTRE")   # an invented town's street (CityStreets.NAMES) and quarter


def materials():
    return {
        "face": Material((0.92, 0.92, 0.90), under=(0.80, 0.81, 0.82), bare=(0.74, 0.75, 0.76), kind="metal", chip=0.4, rusts=False,
                         grain=0.03),
        "back": Material((0.62, 0.63, 0.63), under=(0.62, 0.63, 0.63), bare=(0.70, 0.71, 0.72), chip=0.0, rusts=False, grain=0.06),
        "galv": Material((0.58, 0.59, 0.58), under=(0.50, 0.50, 0.48), bare=(0.42, 0.30, 0.20), chip=0.3, grain=0.12),
        "cap": Material((0.12, 0.12, 0.13), kind="rubber", chip=0.0, rusts=False, grain=0.05),
        "bolt": Material((0.45, 0.45, 0.45), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
        "enamel": Material((0.10, 0.16, 0.52), under=(0.20, 0.20, 0.22), bare=(0.12, 0.12, 0.13), kind="metal", chip=0.5, rusts=True,
                           grain=0.02, fades=False),
        "frame": Material((0.22, 0.42, 0.26), under=(0.35, 0.22, 0.12), bare=(0.30, 0.18, 0.10), chip=0.6, grain=0.06),
    }


# --- shared --------------------------------------------------------------------------------------
def _pole(lod):
    r, h = POLE
    sides = [10, 6, 4][lod]
    m = S.lathe([(0.0, r), (h, r)], sides, tag="galv", caps=(False, False))
    m.merge(S.lathe([(h, r + 0.004), (h + 0.02, r + 0.004), (h + 0.035, r * 0.6), (h + 0.04, 0.0)], sides, tag="cap"))
    if lod == 0:  # the collar where it goes into the pavement
        m.merge(S.lathe([(0.0, r + 0.02), (0.015, r + 0.012), (0.02, r + 0.002)], sides, tag="galv", caps=(False, False)))
    return m


def _plate(outline, cy, lod, z_front=-0.05):
    """The sign: an outline of (x, y) round its centre at height cy, a plate PLATE_T thick whose
    face looks at -Z from z_front, its rolled edge behind the face, rails and clamps on its back."""
    m = Mesh()
    m.merge(S.extrude(outline, PLATE_T, 0.0, "back", cap_tag="face", origin=(0, cy, z_front + PLATE_T), right=(1, 0, 0), up=(0, 1, 0)))
    if lod < 2:  # the rolled edge: a lip all round behind the face
        ring = [(x, cy + y, z_front + PLATE_T + 0.006) for x, y in outline]
        m.merge(S.sweep(ring, [(-0.006, -0.006), (0.006, -0.006), (0.006, 0.006), (-0.006, 0.006)], "back", closed=True, up=(0, 0, 1)))
    return m


def _width_at(outline, y):
    """Half the outline's width at height y (it is symmetric about x = 0)."""
    xs = []
    for i in range(len(outline)):
        (ax, ay), (bx, by) = outline[i], outline[(i + 1) % len(outline)]
        if (ay - y) * (by - y) <= 0 and ay != by:
            xs.append(ax + (bx - ax) * (y - ay) / (by - ay))
    return (max(xs) - min(xs)) / 2 if xs else 0.0


def _rails_and_clamps(outline, cy, ys, lod, z_back=-0.04):
    """Two rails across the back (each 85 % of the sign's width there), a clamp round the pole on each."""
    m = Mesh()
    r = POLE[0]
    for y in ys:
        half = max(_width_at(outline, y - cy) * 0.85, r + 0.03)
        m.merge(S.box((0, y, z_back + 0.008), (half, 0.016, 0.006), "back"))
        if lod < 2:
            m.merge(S.box((0, y, z_back + 0.02), (r + 0.012, 0.022, 0.012), "galv"))  # the clamp's saddle
            if lod == 0:
                ring = S.lathe([(-0.02, r + 0.006), (0.02, r + 0.006)], 8, tag="galv", caps=(False, False))
                m.merge(ring.transformed(np.eye(3), (0, y, 0)))
                for x in (-r - 0.02, r + 0.02):
                    m.merge(S.prism((x, y, z_back + 0.032), 0.007, 0.012, 6, axis=(0, 0, 1), tag="bolt"))
    return m


def _signpost(outline, extent, lod):
    """A sign on its pole: the pole at z = 0, the plate in front of it."""
    lo, hi, half = extent
    cy = SIGN_LOW - lo
    m = _pole(lod)
    m.merge(_plate(outline, cy, lod))
    m.merge(_rails_and_clamps(outline, cy, (cy + lo * 0.5, cy + hi * 0.5), lod))
    return m


# --- the faces' paint ------------------------------------------------------------------------------
RED = np.array([0.72, 0.08, 0.07], np.float32)
WHITE = np.array([0.93, 0.93, 0.91], np.float32)
BLUE = np.array([0.10, 0.16, 0.52], np.float32)


def _face(P, N, tag, tags):
    return (tag == tags.index("face")) & (N[:, 2] < -0.5)


def _paint_stop(P, N, tag, tags, state, col):
    sel = _face(P, N, tag, tags)
    cy = SIGN_LOW + STOP_R * np.cos(np.pi / 8)
    x, y = P[:, 0], P[:, 1] - cy
    # the octagon's inner edge: distance in from its sides
    a = np.arctan2(y, x)
    k = np.round((a - np.pi / 8) / (np.pi / 4)) * (np.pi / 4) + np.pi / 8  # the nearest side's normal angle
    flat = STOP_R * np.cos(np.pi / 8)
    d = flat - (x * np.cos(k) + y * np.sin(k))
    out = np.where((d < 0.018)[:, None], WHITE, RED)
    h = min(0.20, 0.50 / max(lettering.width("STOP", 1.0), 1e-3))  # the word fills the middle, inside the border
    letters = lettering.mask(P, "STOP", np.array([0, cy, -0.05], np.float32), h, (-1, 0, 0), (0, 1, 0), weight=1.5)
    out = np.where(letters[:, None], WHITE, out)
    return np.where(sel[:, None], out, col)


def _tri(side):
    h = side * np.sqrt(3) / 2
    return [(-side / 2, h / 3), (side / 2, h / 3), (0.0, -2 * h / 3)]  # round its centroid, point down


def _paint_giveway(P, N, tag, tags, state, col):
    sel = _face(P, N, tag, tags)
    h = GIVEWAY_SIDE * np.sqrt(3) / 2
    cy = SIGN_LOW + 2 * h / 3
    x, y = P[:, 0], P[:, 1] - cy
    tri = _tri(GIVEWAY_SIDE)
    d = np.full(len(P), 9.0)
    for i in range(3):
        (ax, ay), (bx, by) = tri[i], tri[(i + 1) % 3]
        ex, ey = bx - ax, by - ay
        L = np.hypot(ex, ey)
        nx, ny = ey / L, -ex / L  # inward for this winding
        if (0 - ax) * nx + (0 - ay) * ny < 0:
            nx, ny = -nx, -ny
        d = np.minimum(d, (x - ax) * nx + (y - ay) * ny)
    out = np.where(((d > 0.016) & (d < 0.12))[:, None], RED, WHITE)
    return np.where(sel[:, None], out, col)


def _paint_no_entry(P, N, tag, tags, state, col):
    sel = _face(P, N, tag, tags)
    cy = SIGN_LOW + NO_ENTRY_R
    x, y = P[:, 0], P[:, 1] - cy
    r = np.hypot(x, y)
    out = np.where((r > NO_ENTRY_R - 0.016)[:, None], WHITE, RED)
    bar = (np.abs(x) < NO_ENTRY_R * 0.72) & (np.abs(y) < NO_ENTRY_R * 0.19)
    out = np.where(bar[:, None], WHITE, out)
    return np.where(sel[:, None], out, col)


def _paint_street(P, N, tag, tags, state, col):
    sel = (tag == tags.index("enamel")) & (N[:, 2] < -0.5)
    w, h = STREET["w"], STREET["h"]
    fr = STREET["frame"]
    x, y = P[:, 0], P[:, 1]
    out = np.broadcast_to(BLUE, (len(P), 3)).copy()
    # the white line inside the frame, on the main plate and round the arch
    inner = (np.abs(x) < w / 2 - fr - 0.012) & (y > fr + 0.012) & (y < h - fr - 0.012)
    line = (np.abs(x) < w / 2 - fr - 0.004) & (y > fr + 0.004) & (y < h - fr - 0.004) & ~inner
    out = np.where(line[:, None], WHITE, out)
    aw, ah = STREET["arch"]
    ar = np.hypot(x / (aw - fr - 0.004), (y - h) / (ah - fr - 0.004))
    out = np.where(((y > h) & (ar > 0.93) & (ar < 1.0))[:, None], WHITE, out)
    first, second, quarter = STREET_TEXT
    m1 = lettering.mask(P, first, np.array([0, h * 0.70, -0.02], np.float32), 0.075, (-1, 0, 0), (0, 1, 0), weight=1.3)
    m2 = lettering.mask(P, second, np.array([0, h * 0.34, -0.02], np.float32), 0.075, (-1, 0, 0), (0, 1, 0), weight=1.3)
    m3 = lettering.mask(P, quarter, np.array([0, h + ah * 0.40, -0.02], np.float32), 0.045, (-1, 0, 0), (0, 1, 0), weight=1.2)
    out = np.where((m1 | m2 | m3)[:, None], WHITE, out)
    return np.where(sel[:, None], out, col)


# --- the elements --------------------------------------------------------------------------------
def sign_stop(lod):
    n = 8
    outline = [(np.cos(np.pi / 8 + 2 * np.pi * k / n) * STOP_R, np.sin(np.pi / 8 + 2 * np.pi * k / n) * STOP_R) for k in range(n)]
    flat = STOP_R * np.cos(np.pi / 8)
    return {"body": Part(_signpost(outline, (-flat, flat, flat), lod))}


def sign_giveway(lod):
    tri = _tri(GIVEWAY_SIDE)
    h = GIVEWAY_SIDE * np.sqrt(3) / 2
    if lod == 0:  # the corners rounded
        rounded = []
        for i in range(3):
            a, b, c = np.array(tri[i - 1]), np.array(tri[i]), np.array(tri[(i + 1) % 3])
            for t in (0.06, 0.0):
                pass
            rounded += [tuple(b + (a - b) / np.linalg.norm(a - b) * 0.03), tuple(b + (c - b) / np.linalg.norm(c - b) * 0.03)]
        tri = rounded
    return {"body": Part(_signpost(tri, (-2 * h / 3, h / 3, GIVEWAY_SIDE / 2), lod))}


def sign_no_entry(lod):
    n = [32, 16, 10][lod]
    outline = [(np.cos(2 * np.pi * k / n) * NO_ENTRY_R, np.sin(2 * np.pi * k / n) * NO_ENTRY_R) for k in range(n)]
    return {"body": Part(_signpost(outline, (-NO_ENTRY_R, NO_ENTRY_R, NO_ENTRY_R), lod))}


def street_plate(lod):
    """The blue enamel plate on the wall, its green frame with rosettes, the arch over it."""
    w, h = STREET["w"], STREET["h"]
    aw, ah = STREET["arch"]
    fr = STREET["frame"]
    m = Mesh()
    zf = -0.014  # the enamel's face, in front of the wall
    n = [16, 10, 6][lod]
    arch = [(np.cos(np.pi * k / n) * aw, h + np.sin(np.pi * k / n) * ah) for k in range(n + 1)]
    field = [(w / 2, 0.0), (w / 2, h), (aw, h)] + arch[1:-1] + [(-aw, h), (-w / 2, h), (-w / 2, 0.0)]
    m.merge(S.extrude(field, -zf, 0.0, "frame", cap_tag="enamel", origin=(0, 0, 0), right=(1, 0, 0), up=(0, 1, 0)))
    prof = [(-fr / 2, -0.006), (fr / 2, -0.006), (fr / 2 - 0.006, 0.006), (-fr / 2 + 0.006, 0.006)]
    if lod < 2:  # the raised green frame round the main plate and round the arch
        rect = [(w / 2 - fr / 2, fr / 2), (w / 2 - fr / 2, h - fr / 2), (-w / 2 + fr / 2, h - fr / 2), (-w / 2 + fr / 2, fr / 2)]
        m.merge(S.sweep([(x, y, zf - 0.004) for x, y in rect], prof, "frame", closed=True, up=(0, 0, -1)))
        arc = [(np.cos(np.pi * k / n) * (aw - fr / 2), h - fr / 2 + np.sin(np.pi * k / n) * (ah - fr / 2 + fr / 2)) for k in range(n + 1)]
        m.merge(S.sweep([(x, y, zf - 0.004) for x, y in arc], prof, "frame", up=(0, 0, -1)))
    if lod == 0:  # the rosettes over the screws at the corners and the arch's top
        for x, y in ((w / 2 - fr / 2, fr / 2), (-w / 2 + fr / 2, fr / 2), (w / 2 - fr / 2, h - fr / 2), (-w / 2 + fr / 2, h - fr / 2), (0, h + ah - fr / 2)):
            m.merge(S.prism((x, y, zf - 0.008), 0.026, 0.006, 10, axis=(0, 0, -1), tag="frame"))
            m.merge(S.prism((x, y, zf - 0.014), 0.012, 0.005, 8, axis=(0, 0, -1), tag="frame"))
    return {"body": Part(m)}


# --- more of the code de la route: speed limit, no parking, one-way, crossing, direction ----------------------
ROUND_R = 0.325           # the round signs (B14, B6a1): 650 mm
SQUARE = 0.50             # the square ones (C12, C20a): 500 mm
DIRECTION = dict(w=1.00, h=0.25, point=0.12, texts=("CENTRE VILLE", "GARE ROUTIERE"))   # the white town signs, two stacked
BLACK = np.array([0.08, 0.08, 0.09], np.float32)


def _inside(x, y, poly):
    """Points (x, y) inside the polygon (a list of (x, y)), by counting crossings."""
    inside = np.zeros(len(x), bool)
    n = len(poly)
    for i in range(n):
        (ax, ay), (bx, by) = poly[i], poly[(i + 1) % n]
        cond = (ay > y) != (by > y)
        xc = ax + (y - ay) * (bx - ax) / np.where(by - ay == 0, 1e-9, by - ay)
        inside ^= cond & (x < xc)
    return inside


def _disc(n):
    return [(np.cos(2 * np.pi * k / n) * ROUND_R, np.sin(2 * np.pi * k / n) * ROUND_R) for k in range(n)]


def _square():
    s = SQUARE / 2
    return [(-s, -s), (s, -s), (s, s), (-s, s)]


def sign_speed(lod):
    return {"body": Part(_signpost(_disc([32, 16, 10][lod]), (-ROUND_R, ROUND_R, ROUND_R), lod))}


def sign_no_parking(lod):
    return {"body": Part(_signpost(_disc([32, 16, 10][lod]), (-ROUND_R, ROUND_R, ROUND_R), lod))}


def sign_one_way(lod):
    return {"body": Part(_signpost(_square(), (-SQUARE / 2, SQUARE / 2, SQUARE / 2), lod))}


def sign_crossing(lod):
    return {"body": Part(_signpost(_square(), (-SQUARE / 2, SQUARE / 2, SQUARE / 2), lod))}


def sign_direction(lod):
    """Two white arrow plates pointing to the reader's left (+x), one over the other on the pole's side."""
    w, h, pt = DIRECTION["w"], DIRECTION["h"], DIRECTION["point"]
    m = _pole(lod)
    plate = [(0.0, -h / 2), (w - pt, -h / 2), (w, 0.0), (w - pt, h / 2), (0.0, h / 2)]
    for k in range(2):
        cy = SIGN_LOW + h / 2 + k * (h + 0.03)
        m.merge(_plate(plate, cy, lod))
        if lod < 2:
            m.merge(S.box((w * 0.12, cy, -0.035), (0.016, h / 2 - 0.02, 0.006), "back"))  # the clamp's rail
            m.merge(S.box((0.0, cy, -0.02), (POLE[0] + 0.012, 0.03, 0.012), "galv"))
    return {"body": Part(m)}


def _round_face(P, N, tag, tags):
    sel = _face(P, N, tag, tags)
    cy = SIGN_LOW + ROUND_R
    return sel, P[:, 0], P[:, 1] - cy, np.hypot(P[:, 0], P[:, 1] - cy)


def _paint_speed(P, N, tag, tags, state, col):
    sel, x, y, r = _round_face(P, N, tag, tags)
    out = np.where((r > ROUND_R - 0.016)[:, None], WHITE, np.where((r > ROUND_R - 0.075)[:, None], RED, WHITE))
    num = lettering.mask(P, "30", np.array([0, SIGN_LOW + ROUND_R, -0.05], np.float32), 0.20, (-1, 0, 0), (0, 1, 0), weight=1.5)
    out = np.where(num[:, None], BLACK, out)
    return np.where(sel[:, None], out, col)


def _paint_no_parking(P, N, tag, tags, state, col):
    sel, x, y, r = _round_face(P, N, tag, tags)
    out = np.where((r > ROUND_R - 0.016)[:, None], WHITE, np.where((r > ROUND_R - 0.070)[:, None], RED, BLUE))
    bar = (np.abs(x * 0.7071 - y * 0.7071) < 0.035) & (r < ROUND_R - 0.06)  # the red bar from top left to bottom right (seen from the front)
    out = np.where(bar[:, None], RED, out)
    return np.where(sel[:, None], out, col)


def _square_face(P, N, tag, tags):
    sel = _face(P, N, tag, tags)
    cy = SIGN_LOW + SQUARE / 2
    x, y = P[:, 0], P[:, 1] - cy
    edge = np.maximum(np.abs(x), np.abs(y)) > SQUARE / 2 - 0.014
    return sel, x, y, edge


def _paint_one_way(P, N, tag, tags, state, col):
    sel, x, y, edge = _square_face(P, N, tag, tags)
    out = np.where(edge[:, None], WHITE, BLUE)
    arrow = [(-0.05, -0.17), (0.05, -0.17), (0.05, 0.04), (0.11, 0.04), (0.0, 0.18), (-0.11, 0.04), (-0.05, 0.04)]
    out = np.where(_inside(x, y, arrow)[:, None], WHITE, out)
    return np.where(sel[:, None], out, col)


def _paint_crossing(P, N, tag, tags, state, col):
    sel, x, y, edge = _square_face(P, N, tag, tags)
    out = np.where(edge[:, None], WHITE, BLUE)
    tri = [(-0.21, -0.17), (0.21, -0.17), (0.0, 0.20)]
    out = np.where(_inside(x, y, tri)[:, None], WHITE, out)
    # the walker, seen from the front facing the reader's left (+x), on the zebra's stripes
    body = [(0.012, 0.09), (0.03, 0.03), (0.055, -0.02), (0.045, -0.03), (0.02, 0.0), (0.012, -0.03), (0.04, -0.11), (0.025, -0.115),
            (-0.005, -0.05), (-0.03, -0.115), (-0.045, -0.11), (-0.018, -0.03), (-0.02, 0.03), (-0.05, -0.01), (-0.055, 0.0), (-0.018, 0.075)]
    fig = _inside(x, y, body) | (np.hypot(x - 0.005, y - 0.115) < 0.022)
    stripes = (y < -0.125) & (y > -0.155) & (np.mod(x * 25, 1.0) < 0.5) & (np.abs(x) < 0.15)
    out = np.where((fig | stripes)[:, None], BLACK, out)
    return np.where(sel[:, None], out, col)


def _paint_direction(P, N, tag, tags, state, col):
    w, h, pt = DIRECTION["w"], DIRECTION["h"], DIRECTION["point"]
    sel = _face(P, N, tag, tags)
    out = np.broadcast_to(WHITE, (len(P), 3)).copy()
    words = np.zeros(len(P), bool)
    border = np.zeros(len(P), bool)
    for k, text in enumerate(DIRECTION["texts"]):
        cy = SIGN_LOW + h / 2 + k * (h + 0.03)
        y = P[:, 1] - cy
        x = P[:, 0]
        outer = [(0.0, -h / 2), (w - pt, -h / 2), (w, 0.0), (w - pt, h / 2), (0.0, h / 2)]
        inner = [(0.015, -h / 2 + 0.015), (w - pt - 0.006, -h / 2 + 0.015), (w - 0.022, 0.0), (w - pt - 0.006, h / 2 - 0.015), (0.015, h / 2 - 0.015)]
        border |= _inside(x, y, outer) & ~_inside(x, y, inner) & (np.abs(y) < h / 2 + 0.001)
        words |= lettering.mask(P, text, np.array([(w - pt) / 2 + 0.01, cy, -0.05], np.float32), 0.075, (-1, 0, 0), (0, 1, 0), weight=1.4)
    out = np.where((words | border)[:, None], BLACK, out)
    return np.where(sel[:, None], out, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.003, extra_first=True)

ELEMENTS = {
    "street_plate": dict(build=street_plate, materials=materials(), extra=_paint_street, close=(0.0, 0.25, 0.0), **_SPEC),
    "sign_stop": dict(build=sign_stop, materials=materials(), extra=_paint_stop, close=(0.0, SIGN_LOW + 0.35, 0.0), **_SPEC),
    "sign_giveway": dict(build=sign_giveway, materials=materials(), extra=_paint_giveway, close=(0.0, SIGN_LOW + 0.5, 0.0), **_SPEC),
    "sign_no_entry": dict(build=sign_no_entry, materials=materials(), extra=_paint_no_entry, close=(0.0, SIGN_LOW + 0.33, 0.0), **_SPEC),
    "sign_speed": dict(build=sign_speed, materials=materials(), extra=_paint_speed, close=(0.0, SIGN_LOW + ROUND_R, 0.0), **_SPEC),
    "sign_no_parking": dict(build=sign_no_parking, materials=materials(), extra=_paint_no_parking, close=(0.0, SIGN_LOW + ROUND_R, 0.0), **_SPEC),
    "sign_one_way": dict(build=sign_one_way, materials=materials(), extra=_paint_one_way, close=(0.0, SIGN_LOW + SQUARE / 2, 0.0), **_SPEC),
    "sign_crossing": dict(build=sign_crossing, materials=materials(), extra=_paint_crossing, close=(0.0, SIGN_LOW + SQUARE / 2, 0.0), **_SPEC),
    "sign_direction": dict(build=sign_direction, materials=materials(), extra=_paint_direction, close=(0.5, SIGN_LOW + 0.3, 0.0), **_SPEC),
}
