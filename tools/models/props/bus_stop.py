"""Bus stops (S170). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

bus_shelter: the glass shelter of the main streets (shelter_front, shelter_end): a thin roof like a
wing curving over the waiting people, carried on slim grey legs at the back, two glass panels
behind, the lit poster case closing one end, a perch bench along the back, the timetable and the
lines' map on the glass. The kerb's edge is in front (-Z); standing on y = 0, x = 0 its middle.
bus_stop_pole: the plain stop (totem): a grey pole, the blue BUS sign at its top, the stop's name
and the lines' numbers on plates below, the timetable case at eye height.

No brand anywhere: the town's own buses. Words and numbers are paint (`extra`), so wear goes over them.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

SHELTER = dict(len=4.40, back=0.55, front=-1.05, roof=(2.36, 2.52), legs=(-1.95, 0.0, 1.95), glass=(0.14, 2.10))
CASE = dict(w=1.30, h=1.85, t=0.13, low=0.30)   # the poster case at the left end (-x), across the shelter's depth
POLE = dict(r=0.045, h=3.05, sign=0.44)
STOP_NAME = ("MARCHE", "PLACE DU")              # an invented stop (the place du Marché)
LINES = ("3", "7", "12")

GLASS = (0.42, 0.47, 0.46)


def materials():
    return {
        "steel": Material((0.47, 0.49, 0.48), under=(0.38, 0.38, 0.37), bare=(0.30, 0.22, 0.16), chip=0.4, grain=0.05),
        "roof": Material((0.55, 0.58, 0.55), under=(0.45, 0.45, 0.44), bare=(0.35, 0.30, 0.25), chip=0.3, grain=0.06),
        "glass": Material(GLASS, kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "poster": Material((0.86, 0.84, 0.78), kind="paper", chip=0.0, rusts=False, grain=0.05, emit=(0.80, 0.82, 0.86)),
        "panel": Material((0.92, 0.92, 0.90), kind="paper", chip=0.0, rusts=False, grain=0.03),
        "seat": Material((0.36, 0.38, 0.38), under=(0.30, 0.30, 0.30), bare=(0.30, 0.22, 0.16), chip=0.5, grain=0.05),
        "sign": Material((0.10, 0.25, 0.58), under=(0.70, 0.71, 0.72), bare=(0.72, 0.73, 0.74), chip=0.3, rusts=False, grain=0.03),
        "bolt": Material((0.30, 0.30, 0.30), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
        "rubber": Material((0.08, 0.08, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.04),
    }


def _frame(x0, x1, y0, y1, z, w, t, tag="steel"):
    """A flat rectangular frame in the plane z (x0..x1, y0..y1), members w wide and t deep."""
    m = Mesh()
    for y in (y0 + w / 2, y1 - w / 2):
        m.merge(S.box(((x0 + x1) / 2, y, z), ((x1 - x0) / 2, w / 2, t / 2), tag))
    for x in (x0 + w / 2, x1 - w / 2):
        m.merge(S.box((x, (y0 + y1) / 2, z), (w / 2, (y1 - y0) / 2 - w, t / 2), tag))
    return m


def _roof(lod):
    """The wing: thin at both edges, thicker over the legs, rising a little to the front."""
    L = SHELTER["len"]
    zb, zf = SHELTER["back"] + 0.15, SHELTER["front"]
    yb, yf = SHELTER["roof"]
    n = [10, 6, 3][lod]
    top, bot = [], []
    for k in range(n + 1):
        t = k / n
        z = zb + (zf - zb) * t
        y = yb + (yf - yb) * t + 0.06 * np.sin(np.pi * t)      # a gentle camber
        th = 0.025 + 0.07 * np.sin(np.pi * min(1.0, t * 1.4)) ** 1.5 * (1 - 0.6 * t)
        top.append((z, y + th / 2))
        bot.append((z, y - th / 2))
    outline = top + bot[::-1]
    c = 0.01 if lod == 0 else 0.0
    return S.extrude(outline, L, c, "roof", origin=(-L / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0))


def bus_shelter(lod):
    m = Mesh()
    L, zb = SHELTER["len"], SHELTER["back"]
    g0, g1 = SHELTER["glass"]
    m.merge(_roof(lod))
    # the legs at the back, each a flat blade rising into the roof, its foot on a plate
    for x in SHELTER["legs"]:
        leg = S.chamfer_box((x, 1.22, zb), (0.035, 1.22, 0.06), 0.008, "steel", edges="vertical") if lod < 2 else S.box((x, 1.22, zb), (0.035, 1.22, 0.06), "steel")
        m.merge(leg)
        m.merge(S.box((x, 0.006, zb), (0.09, 0.006, 0.10), "steel"))
        if lod == 0:
            for dx in (-0.06, 0.06):
                m.merge(S.prism((x + dx, 0.012, zb), 0.008, 0.006, 6, tag="bolt"))
            m.merge(S.box((x, SHELTER["roof"][0] - 0.06, zb - 0.10), (0.03, 0.03, 0.12), "steel"))  # the roof's bracket
    # the glass behind, two panes in their frames between the legs
    xs = SHELTER["legs"]
    for a, b in zip(xs[:-1], xs[1:]):
        x0, x1 = a + 0.035, b - 0.035
        m.merge(S.box(((x0 + x1) / 2, (g0 + g1) / 2, zb), ((x1 - x0) / 2 - 0.02, (g1 - g0) / 2 - 0.02, 0.005), "glass"))
        if lod < 2:
            m.merge(_frame(x0, x1, g0, g1, zb, 0.04, 0.03))
    # the poster case closing the left end, the poster on both faces, lit from inside
    cw, ch, ct, cl = CASE["w"], CASE["h"], CASE["t"], CASE["low"]
    cx = -L / 2 + 0.12
    cz = zb - cw / 2 + 0.06
    m.merge(S.chamfer_box((cx, cl + ch / 2, cz), (ct / 2, ch / 2, cw / 2), 0.02 if lod == 0 else 0.0, "steel") if lod == 0 else
            S.box((cx, cl + ch / 2, cz), (ct / 2, ch / 2, cw / 2), "steel"))
    for s in (1, -1):
        m.merge(S.box((cx + s * (ct / 2 + 0.002), cl + ch / 2, cz), (0.003, ch / 2 - 0.06, cw / 2 - 0.06), "poster"))
    m.merge(S.box((cx, cl / 2, cz), (0.04, cl / 2, 0.20), "steel"))  # its foot
    if lod < 2:
        # the perch bench along the back, on brackets from the legs
        for x in (-1.05, 1.05):
            m.merge(S.box((x, 0.60, zb - 0.16), (0.70, 0.02, 0.10), "seat"))
            m.merge(S.box((x, 0.53, zb - 0.06), (0.02, 0.07, 0.05), "steel"))
            m.merge(S.box((x + 0.45, 0.53, zb - 0.06), (0.02, 0.07, 0.05), "steel"))
            m.merge(S.box((x - 0.45, 0.53, zb - 0.06), (0.02, 0.07, 0.05), "steel"))
        # the timetable and the lines' map, stuck inside the glass
        m.merge(S.box((1.00, 1.45, zb - 0.012), (0.24, 0.32, 0.006), "panel"))
        m.merge(S.box((-0.95, 1.40, zb - 0.012), (0.42, 0.42, 0.006), "panel"))
        # the stop's name on a blade at the right end of the roof's front
        m.merge(S.box((L / 2 - 0.35, SHELTER["roof"][1] + 0.18, SHELTER["front"] + 0.25), (0.32, 0.10, 0.015), "sign"))
        m.merge(S.box((L / 2 - 0.35, SHELTER["roof"][1] + 0.06, SHELTER["front"] + 0.25), (0.015, 0.04, 0.015), "steel"))
    if lod == 0:  # the roof's gutter lip and the glass's rubber at the foot
        m.merge(S.box((0, SHELTER["roof"][0] - 0.035, SHELTER["back"] + 0.13), (L / 2, 0.01, 0.02), "steel"))
        m.merge(S.box((0, g0 - 0.005, zb), (L / 2 - 0.1, 0.006, 0.012), "rubber"))
    return {"body": Part(m)}


def _pole(lod):
    r, h = POLE["r"], POLE["h"]
    sides = [12, 8, 5][lod]
    m = S.lathe([(0.0, r + 0.02), (0.02, r + 0.01), (0.03, r), (h, r), (h + 0.02, r * 0.5), (h + 0.025, 0.0)], sides, tag="steel")
    return m


def bus_stop_pole(lod):
    m = _pole(lod)
    s = POLE["sign"]
    h = POLE["h"]
    # the blue BUS sign, a square plate with a rolled edge, on its clamps
    m.merge(S.chamfer_box((0, h - s / 2 - 0.05, -0.06), (s / 2, s / 2, 0.006), 0.006 if lod == 0 else 0.0, "sign", edges="vertical") if lod == 0 else
            S.box((0, h - s / 2 - 0.05, -0.06), (s / 2, s / 2, 0.006), "sign"))
    # the stop's name and the lines' plates under it
    m.merge(S.box((0.20, h - s - 0.20, -0.06), (0.32, 0.075, 0.008), "panel"))
    for k, _ in enumerate(LINES):
        m.merge(S.box((0, h - s - 0.40 - k * 0.15, -0.06), (0.08, 0.06, 0.008), "sign"))
    # the timetable case at eye height
    m.merge(S.box((0, 1.50, -0.07), (0.17, 0.24, 0.025), "steel"))
    m.merge(S.box((0, 1.50, -0.097), (0.15, 0.22, 0.002), "panel"))
    if lod < 2:
        for y in (h - s / 2 - 0.05, h - s - 0.20, 1.50):
            m.merge(S.lathe([(-0.025, POLE["r"] + 0.008), (0.025, POLE["r"] + 0.008)], 8, tag="steel", caps=(False, False))
                    .transformed(np.eye(3), (0, y, 0)))
    return {"body": Part(m)}


# --- the words ---------------------------------------------------------------------------------------
WHITE = np.array([0.93, 0.93, 0.91], np.float32)
INK = np.array([0.10, 0.12, 0.16], np.float32)


def _paint_shelter(P, N, tag, tags, state, col):
    zf = SHELTER["front"] + 0.25 - 0.016
    sel = (tag == tags.index("sign")) & (N[:, 2] < -0.5)
    c = np.array([SHELTER["len"] / 2 - 0.35, SHELTER["roof"][1] + 0.18, zf], np.float32)
    words = lettering.mask(P, " ".join(reversed(STOP_NAME)), c, 0.06, (-1, 0, 0), (0, 1, 0), weight=1.2)
    col = np.where((sel & words)[:, None], WHITE, col)
    # the timetable's rows and the map's lines, printed
    pan = (tag == tags.index("panel")) & (N[:, 2] < -0.5)
    rows = (np.mod(P[:, 1] * 40, 1.0) < 0.35) & (np.abs(P[:, 0] - 1.0) < 0.2)
    lines = (np.abs(np.sin(P[:, 0] * 9 + P[:, 1] * 4)) < 0.08) | (np.abs(np.sin(P[:, 0] * 3 - P[:, 1] * 11)) < 0.06)
    col = np.where((pan & rows)[:, None], INK, col)
    col = np.where((pan & lines & (P[:, 0] < 0))[:, None], np.array([0.75, 0.20, 0.18], np.float32), col)
    # the poster: an invented show, big shapes and a title
    pos = tag == tags.index("poster")
    blob = np.hypot(P[:, 1] - (CASE["low"] + 1.2), P[:, 2] - SHELTER["back"] + 0.6) < 0.38
    col = np.where((pos & blob)[:, None], np.array([0.70, 0.30, 0.22], np.float32), col)
    band = pos & (P[:, 1] < CASE["low"] + 0.55) & (P[:, 1] > CASE["low"] + 0.30)
    return np.where(band[:, None], np.array([0.15, 0.18, 0.30], np.float32), col)


def _paint_pole(P, N, tag, tags, state, col):
    s, h = POLE["sign"], POLE["h"]
    front = N[:, 2] < -0.5
    sign = (tag == tags.index("sign")) & front
    words = lettering.mask(P, "BUS", np.array([0, h - s / 2 - 0.05, -0.07], np.float32), 0.12, (-1, 0, 0), (0, 1, 0), weight=1.6)
    for k, n in enumerate(LINES):
        words |= lettering.mask(P, n, np.array([0, h - s - 0.40 - k * 0.15, -0.07], np.float32), 0.07, (-1, 0, 0), (0, 1, 0), weight=1.5)
    col = np.where((sign & words)[:, None], WHITE, col)
    pan = (tag == tags.index("panel")) & front
    c = np.array([0.20, h - s - 0.20, -0.07], np.float32)
    words = lettering.mask(P, STOP_NAME[1], c + np.array([0, 0.03, 0], np.float32), 0.035, (-1, 0, 0), (0, 1, 0)) | \
        lettering.mask(P, STOP_NAME[0], c - np.array([0, 0.03, 0], np.float32), 0.045, (-1, 0, 0), (0, 1, 0), weight=1.3)
    col = np.where((pan & words)[:, None], INK, col)
    rows = pan & (P[:, 1] < 1.70) & (np.mod(P[:, 1] * 45, 1.0) < 0.3)
    return np.where(rows[:, None], INK, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.004, extra_first=True)

ELEMENTS = {
    "bus_shelter": dict(build=bus_shelter, materials=materials(), extra=_paint_shelter, close=(-1.0, 1.2, 0.3), **_SPEC),
    "bus_stop_pole": dict(build=bus_stop_pole, materials=materials(), extra=_paint_pole, close=(0.0, POLE["h"] - 0.5, 0.0), **_SPEC),
}
