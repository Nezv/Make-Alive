"""The detail kit's board (S141): every helper of the kit side by side, the way a mason's yard
shows its samples. Card: references/elements/kit.md; references: references/elements/kit/.

A garden wall of sample panels in two tiers (bricks in four bonds, concrete block, ashlar with a
cellar vent; plaster over brick, board-formed concrete with a bolted plate and stencil, corrugated
and ribbed sheet, welded mesh, a window with its surround, broken glass and a louvred shutter),
coped with flat tiles and ridge caps on the left and canal tiles on the right; a door at the
right end in its stone surround, its leaf of inset and raised panels, a street plate and a house
number above. In front the floor samples (setts in rows and in fans, interlocking pavers, a road
word on asphalt, a tree grate in stone slabs, a row of material swatches that shows every burnt
material), and a bench of the shapes (chamfered and bevelled boxes, a turned baluster, an
extrusion, a railing of balusters, a bolt circle, a bent pipe, a cable, a cut column whose top
falls), a handrail along it.

Units in metres; the wall's face is z = 0, the front is -Z.
"""
import numpy as np

import shapes as S
import surfaces as F
import lettering as T
from poly import Mesh
from props import Material, Part

X, Y, Z = np.eye(3)
COL = 1.0           # one sample panel and its gap
PANEL = 0.9
LEFT = -3.0         # the wall's left end
LOW = (0.08, 1.0)   # the lower tier, bottom and top
UP = (1.1, 2.0)
PROUD = 0.03        # a panel stands proud of the backing wall by this
WALL_TOP = 2.05
DOOR_X = (3.05, 4.35)
FLOOR_Z = (-0.15, -1.35)
FLOOR_LIFT = 0.09   # the floor samples' beds stand on y = 0
BENCH_Z = (-2.5, -3.1)
BENCH_H = 0.72


def panel_x(col):
    return LEFT + col * COL + (COL - PANEL) / 2


def _panel_centre(col, tier):
    y0, y1 = LOW if tier == 0 else UP
    return np.array([panel_x(col) + PANEL / 2, (y0 + y1) / 2, -PROUD])


def _pattern_frame(col, tier):
    y0 = (LOW if tier == 0 else UP)[0]
    return dict(origin=(panel_x(col), y0, 0.0), right=(1, 0, 0), up=(0, 1, 0))


# --- Materials -------------------------------------------------------------------------------------

LIMESTONE = (0.74, 0.70, 0.60)
GRANITE = [(0.47, 0.46, 0.45), (0.52, 0.50, 0.48), (0.42, 0.42, 0.43), (0.55, 0.49, 0.45), (0.38, 0.39, 0.41)]
CLAY = [(0.62, 0.30, 0.17), (0.58, 0.27, 0.16), (0.66, 0.36, 0.21), (0.52, 0.25, 0.16), (0.70, 0.42, 0.26)]
CANAL = [(0.66, 0.42, 0.28), (0.60, 0.36, 0.24), (0.70, 0.50, 0.36), (0.55, 0.33, 0.24), (0.62, 0.46, 0.36)]
PAVER = [(0.48, 0.30, 0.24), (0.52, 0.34, 0.27), (0.44, 0.28, 0.23), (0.56, 0.38, 0.30)]


def materials():
    stone = dict(kind="stone", chip=0.0, rusts=False, grain=0.06)
    return {
        "backing": Material((0.62, 0.60, 0.56), **dict(stone, grain=0.05), sheds=False),
        "coping": Material(LIMESTONE, **stone),
        "brick_stretcher": Material((0.6, 0.3, 0.2), kind="masonry", chip=0.0, rusts=False,
                                    pattern=F.Bond("stretcher", **_pattern_frame(0, 0), seed=1)),
        "brick_flemish": Material((0.6, 0.3, 0.2), kind="masonry", chip=0.0, rusts=False,
                                  pattern=F.Bond("flemish", **_pattern_frame(1, 0), seed=2)),
        "brick_english": Material((0.6, 0.3, 0.2), kind="masonry", chip=0.0, rusts=False,
                                  pattern=F.Bond("english", **_pattern_frame(2, 0), seed=3)),
        "brick_foraine": Material((0.6, 0.3, 0.2), kind="masonry", chip=0.0, rusts=False,
                                  pattern=F.Bond("foraine", **_pattern_frame(3, 0), seed=4,
                                                 colours=[(0.72, 0.42, 0.28), (0.66, 0.36, 0.24), (0.76, 0.50, 0.34),
                                                          (0.60, 0.32, 0.22)], mortar=(0.70, 0.64, 0.54))),
        "block": Material((0.56, 0.56, 0.54), kind="concrete", chip=0.0, rusts=False,
                          pattern=F.Bond("block", **_pattern_frame(4, 0), seed=5)),
        "ashlar": Material(LIMESTONE, kind="stone", chip=0.0, rusts=False, pattern=F.Bond("ashlar", **_pattern_frame(5, 0), seed=6)),
        "plaster": Material((0.80, 0.76, 0.68), kind="plaster", chip=0.0, rusts=False,
                            pattern=F.Plaster(F.Bond("stretcher", **_pattern_frame(0, 1), seed=7))),
        "board": Material((0.6, 0.6, 0.57), kind="concrete", chip=0.0, rusts=False,
                          pattern=F.BoardFormed(**_pattern_frame(1, 1), seed=8)),
        "plate": Material((0.30, 0.38, 0.33), under=(0.55, 0.36, 0.17), bare=(0.22, 0.21, 0.2), chip=1.1),
        "bolt": Material((0.25, 0.25, 0.25), under=(0.3, 0.18, 0.1), bare=(0.3, 0.17, 0.08), fixing=True, grain=0.1),
        "zinc": Material((0.56, 0.58, 0.58), under=(0.48, 0.49, 0.48), bare=(0.40, 0.40, 0.39), chip=0.5, grain=0.12),
        "shutter_steel": Material((0.20, 0.30, 0.24), under=(0.45, 0.45, 0.42), bare=(0.25, 0.24, 0.23), chip=0.9),
        "wire": Material((0.30, 0.30, 0.29), under=(0.3, 0.2, 0.12), bare=(0.3, 0.17, 0.08), chip=0.3, grain=0.1),
        "angle": Material((0.24, 0.25, 0.25), under=(0.5, 0.33, 0.2), bare=(0.22, 0.2, 0.19)),
        "surround": Material(LIMESTONE, **stone),
        "joinery": Material((0.86, 0.85, 0.80), under=(0.70, 0.68, 0.62), bare=(0.50, 0.47, 0.42), kind="wood", rusts=False),
        "glass": Material((0.36, 0.43, 0.48), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "persienne": Material((0.55, 0.62, 0.58), under=(0.82, 0.80, 0.74), bare=(0.50, 0.47, 0.42), kind="wood", rusts=False),
        "iron": Material((0.17, 0.16, 0.16), under=(0.3, 0.18, 0.1), bare=(0.3, 0.17, 0.08), chip=0.8, grain=0.12),
        "door": Material((0.14, 0.27, 0.20), under=(0.62, 0.58, 0.48), bare=(0.48, 0.45, 0.40), kind="wood", rusts=False),
        "brass": Material((0.62, 0.50, 0.24), under=(0.45, 0.36, 0.18), bare=(0.5, 0.4, 0.2), chip=0.2, rusts=False, grain=0.1),
        "enamel": Material((0.10, 0.20, 0.52), under=(0.08, 0.08, 0.09), bare=(0.22, 0.12, 0.07), chip=0.6),
        "cast": Material((0.13, 0.13, 0.14), under=(0.3, 0.18, 0.1), bare=(0.3, 0.17, 0.08), chip=0.6),
        "letter": Material((0.84, 0.82, 0.74), under=(0.3, 0.3, 0.3), bare=(0.3, 0.3, 0.3), chip=1.0),
        "sett": Material(GRANITE[0], kind="stone", chip=0.0, rusts=False, palette=GRANITE, vary=0.1, grain=0.08, speckle=0.2),
        "sand": Material((0.34, 0.31, 0.26), kind="sand", chip=0.0, rusts=False, grain=0.15, speckle=0.25),
        "paver": Material(PAVER[0], kind="concrete", chip=0.0, rusts=False, palette=PAVER, vary=0.06, grain=0.1, speckle=0.1),
        "asphalt": Material((0.20, 0.20, 0.21), kind="concrete", chip=0.0, rusts=False, grain=0.2, speckle=0.3),
        "slab": Material((0.62, 0.60, 0.56), kind="stone", chip=0.0, rusts=False, vary=0.06, grain=0.08, speckle=0.08),
        "hole": Material((0.05, 0.045, 0.04), chip=0.0, rusts=False, grain=0.2, kind="sand", sheds=False),
        "tile": Material(CLAY[0], kind="clay", chip=0.0, rusts=False, palette=CLAY, vary=0.08, grain=0.1),
        "canal": Material(CANAL[0], kind="clay", chip=0.0, rusts=False, palette=CANAL, vary=0.08, grain=0.12),
        "mortar": Material((0.68, 0.64, 0.56), kind="masonry", chip=0.0, rusts=False, grain=0.1),
        "bench": Material((0.42, 0.30, 0.19), under=(0.42, 0.30, 0.19), bare=(0.36, 0.25, 0.15), kind="wood", chip=0.0,
                          rusts=False, grain=0.14),
        "shape": Material((0.33, 0.42, 0.52), under=(0.55, 0.36, 0.17), bare=(0.22, 0.21, 0.2)),
        "pipe": Material((0.24, 0.25, 0.26), under=(0.5, 0.33, 0.2), bare=(0.22, 0.2, 0.19)),
        "cable": Material((0.05, 0.05, 0.05), kind="rubber", chip=0.0, rusts=False, grain=0.05),
        "rail": Material((0.10, 0.10, 0.11), under=(0.4, 0.25, 0.15), bare=(0.3, 0.17, 0.08)),
        "column": Material(LIMESTONE, **stone),
        "break": Material((0.84, 0.80, 0.71), kind="stone", chip=0.0, rusts=False, grain=0.1, sheds=False),
        "sw_wood": Material((0.55, 0.40, 0.25), kind="wood", chip=0.0, rusts=False, grain=0.15),
        "sw_brick": Material((0.6, 0.3, 0.2), kind="masonry", chip=0.0, rusts=False, grain=0.1),
        "sw_plaster": Material((0.82, 0.78, 0.70), kind="plaster", chip=0.0, rusts=False),
        "sw_clay": Material((0.64, 0.34, 0.2), kind="clay", chip=0.0, rusts=False),
        "sw_rubber": Material((0.07, 0.07, 0.07), kind="rubber", chip=0.0, rusts=False),
        "sw_cloth": Material((0.62, 0.55, 0.42), kind="paper", chip=0.0, rusts=False, grain=0.15),
        "road_paint": Material((0.20, 0.20, 0.21), kind="concrete", chip=0.0, rusts=False, grain=0.2, speckle=0.3),
    }


# --- The wall --------------------------------------------------------------------------------------

def _panel(col, tier, tag, lod):
    c = _panel_centre(col, tier)
    y0, y1 = LOW if tier == 0 else UP
    return S.box((c[0], c[1], -PROUD / 2), (PANEL / 2, (y1 - y0) / 2, PROUD / 2), tag)


def _wall(lod):
    m = Mesh()
    # The backing wall and its plinth; the panels stand proud of it.
    m.merge(S.box((0.0, WALL_TOP / 2, 0.09), (-LEFT + 0.05, WALL_TOP / 2, 0.09), "backing"))
    tags = [["brick_stretcher", "brick_flemish", "brick_english", "brick_foraine", "block", "ashlar"],
            ["plaster", "board", None, None, None, None]]
    for tier in (0, 1):
        for col in range(6):
            if tags[tier][col]:
                m.merge(_panel(col, tier, tags[tier][col], lod))
    # Copings over the lower tier: a limestone string course, its top weathered (sloped) and
    # a drip under its front, so water leaves it and stains the bricks below.
    for col in range(6):
        x = panel_x(col) + PANEL / 2
        if lod < 2:
            cp = S.chamfer_box((x, LOW[1] + 0.03, -0.055), (PANEL / 2 + 0.03, 0.03, 0.055), 0.012, "coping", edges="front")
            m.merge(cp)
            if lod == 0:
                m.merge(S.box((x, LOW[1] - 0.001, -0.095), (PANEL / 2 + 0.02, 0.0015, 0.004), "hole"))
        else:
            m.merge(S.box((x, LOW[1] + 0.03, -0.055), (PANEL / 2 + 0.03, 0.03, 0.055), "coping"))
    return m


def _cellar_vent(lod):
    """A cellar vent (soupirail) in the ashlar panel: a slot vent, and a louvre vent under it."""
    m = Mesh()
    x = panel_x(5) + PANEL / 2
    m.merge(S.vent(0.36, 0.16, slots=5, origin=(x - 0.2, 0.62, -PROUD), tag="iron") if lod < 2 else Mesh())
    m.merge(S.vent(0.30, 0.22, louvre=True, slots=6, origin=(x + 0.22, 0.6, -PROUD), tag="iron") if lod < 2 else Mesh())
    return m


def _bolted_plate(lod):
    """A painted steel plate on the board-formed panel, six bolts that run rust down it."""
    m = Mesh()
    c = _panel_centre(1, 1)
    px, py = c[0] + 0.18, UP[0] + 0.25
    m.merge(S.chamfer_box((px, py, -PROUD - 0.004), (0.17, 0.12, 0.004), 0.003, "plate", edges="front"))
    if lod == 0:
        for i in range(3):
            for j in (-1, 1):
                m.merge(S.prism((px - 0.13 + i * 0.13, py + j * 0.085, -PROUD - 0.008), 0.009, 0.007, 6, tag="bolt",
                                axis=(0, 0, -1)))
    return m


def _sheets(lod):
    m = Mesh()
    rows = 32 if lod == 0 else 1
    corr = F.sheet("corrugated", PANEL, UP[1] - UP[0], origin=(panel_x(2), UP[0], -0.003), tag="zinc", lod=lod, rows=rows)
    if lod == 0:  # dents: a kick at the foot and a blow higher up
        front = -0.003 - 0.018 - 0.0012  # the crests' face
        corr = S.dent(corr, (panel_x(2) + 0.3, UP[0] + 0.2, front), 0.2, 0.016, (0, 0, 1), crush=True)
        corr = S.dent(corr, (panel_x(2) + 0.62, UP[0] + 0.58, front), 0.13, 0.012, (0, 0, 1), crush=True)
    m.merge(corr)
    m.merge(F.sheet("ribbed", PANEL, UP[1] - UP[0], origin=(panel_x(3), UP[0], -0.003), tag="shutter_steel", lod=lod))
    if lod < 2:
        m.merge(F.wire_mesh(PANEL - 0.04, UP[1] - UP[0] - 0.04, origin=(panel_x(4) + 0.02, UP[0] + 0.02, -0.03),
                            tag="wire", frame_tag="angle") if lod == 0 else
                S.box((panel_x(4) + PANEL / 2, (UP[0] + UP[1]) / 2, -0.03), (PANEL / 2 - 0.02, (UP[1] - UP[0]) / 2 - 0.02, 0.003), "wire"))
    m.merge(_panel(4, 1, "plaster", lod))
    return m


WIN = dict(w=0.5, h=0.62, sill=UP[0] + 0.14)


def _window(lod):
    """A window in a plastered panel: a moulded stone surround with a segmental arch, its sill, a
    casement of two leaves of panes (one pane broken through), and a louvred shutter (the moving
    part: hinged at the left of the opening)."""
    m = Mesh()
    col = 5
    cx = panel_x(col) + PANEL / 2
    y0 = WIN["sill"]
    w, h = WIN["w"], WIN["h"]
    # the panel around the opening (plaster), cut as four pieces round the hole
    pl = []
    top, bot = UP[1], UP[0]
    x0, x1 = panel_x(col), panel_x(col) + PANEL
    for (a, b, c, d) in ((x0, cx - w / 2, bot, top), (cx + w / 2, x1, bot, top), (cx - w / 2, cx + w / 2, bot, y0),
                         (cx - w / 2, cx + w / 2, y0 + h + 0.06, top)):
        pl.append(S.box(((a + b) / 2, (c + d) / 2, -PROUD / 2), ((b - a) / 2, (d - c) / 2, PROUD / 2), "plaster"))
    for p in pl:
        m.merge(p)
    m.merge(S.box((cx, y0 + h / 2 + 0.03, 0.03), (w / 2, h / 2 + 0.03, 0.005), "hole"))  # the room behind
    mould = [(0.0, 0.0), (0.0, 0.035), (0.03, 0.035), (0.045, 0.02), (0.075, 0.02), (0.075, 0.0)]
    if lod < 2:
        m.merge(S.opening_frame(w, h, mould, arch=0.06 if lod == 0 else 0.0, origin=(cx, y0, -PROUD), tag="surround",
                                sill=(0.03, 0.08, 0.045) if lod == 0 else None))
        if lod == 0:  # a keystone at the crown
            m.merge(S.chamfer_box((cx, y0 + h + 0.03, -PROUD - 0.025), (0.035, 0.05, 0.025), 0.008, "surround", edges="front"))
    # the casement: two leaves of three panes, a glazing bar, the lower left pane broken
    if lod < 2:
        stile = 0.035
        for side in (-1, 1):
            lx = cx + side * w / 4
            for (a, b) in ((lx - w / 4, lx - w / 4 + stile), (lx + w / 4 - stile, lx + w / 4)):
                m.merge(S.chamfer_box(((a + b) / 2, y0 + h / 2, 0.012), ((b - a) / 2, h / 2, 0.02), 0.004, "joinery", edges="front"))
            for yy in (y0 + stile / 2, y0 + h - stile / 2, y0 + h / 3, y0 + 2 * h / 3):
                m.merge(S.chamfer_box((lx, yy, 0.012), (w / 4 - stile, 0.012, 0.016), 0.003, "joinery", edges="front"))
            for k in range(3):
                pane_y = y0 + k * h / 3
                pw, ph = w / 2 - 2 * stile, h / 3 - 0.024
                if side > 0 and k == 0 and lod == 0:  # the right leaf's lowest pane (the shutter covers the left)
                    m.merge(S.broken_pane(pw, ph, [(0.02, ph * 0.55, 0.05)], origin=(lx, pane_y + 0.012, 0.016), seed=4))
                else:
                    m.merge(S.box((lx, pane_y + 0.012 + ph / 2, 0.016), (pw / 2, ph / 2, 0.002), "glass"))
    return m


def _shutter(lod):
    """The louvred shutter (persienne), hinged at the left of the window: opens 165 degrees."""
    col = 5
    cx = panel_x(col) + PANEL / 2
    w, h = WIN["w"] / 2 + 0.01, WIN["h"] + 0.02
    x0 = cx - WIN["w"] / 2  # closed over the left half of the opening at rest
    m = F.louvres(w, h, origin=(x0, WIN["sill"] - 0.01, -PROUD - 0.04), tag="persienne", lod=lod)
    if lod == 0:  # two strap hinges and a catch
        for yy in (WIN["sill"] + 0.08, WIN["sill"] + h - 0.1):
            m.merge(S.box((x0 + 0.06, yy, -PROUD - 0.072), (0.06, 0.008, 0.002), "iron"))
            m.merge(S.lathe([(0.0, 0.007), (0.03, 0.007)], 6, tag="iron").transformed(np.eye(3), (x0 - 0.002, yy - 0.015, -PROUD - 0.072)))
    pivot = (x0, WIN["sill"], -PROUD - 0.072)
    return m, pivot


def _door(lod):
    """A door in a plastered bay at the right end: a moulded stone surround with a flat lintel
    and a cornice over it, a leaf of two raised panels over two inset ones, a knob, a letter
    slot, a street plate and a house number on the wall above."""
    m = Mesh()
    x0, x1 = DOOR_X
    cx = (x0 + x1) / 2
    H = 2.75
    dw, dh = 0.95, 2.1
    # the bay's wall around the door
    for (a, b, c, d) in ((x0, cx - dw / 2 - 0.0, 0.0, H), (cx + dw / 2, x1, 0.0, H), (cx - dw / 2, cx + dw / 2, dh, H)):
        m.merge(S.box(((a + b) / 2, (c + d) / 2, 0.065), ((b - a) / 2, (d - c) / 2, 0.055), "backing"))
        m.merge(S.box(((a + b) / 2, (c + d) / 2, 0.005), ((b - a) / 2, (d - c) / 2, 0.005), "plaster"))  # the rendered skin
    mould = [(0.0, 0.0), (0.0, 0.03), (0.02, 0.045), (0.06, 0.045), (0.07, 0.03), (0.09, 0.03), (0.09, 0.0)]
    if lod < 2:
        m.merge(S.opening_frame(dw, dh, mould, origin=(cx, 0.0, 0.0), tag="surround", bottom=False))
        cor = S.sweep([(cx - dw / 2 - 0.16, dh + 0.14, 0.0), (cx + dw / 2 + 0.16, dh + 0.14, 0.0)],
                      [(0.0, 0.0), (0.0, -0.04), (0.04, -0.05), (0.06, -0.09), (0.09, -0.09), (0.09, 0.0)][::-1],
                      "surround", up=(0, 0, -1))
        m.merge(cor)
    m.merge(S.box((cx, dh / 2, 0.11), (dw / 2, dh / 2, 0.005), "hole"))
    # the leaf: rails and stiles round four panels
    leaf = Mesh()
    z = 0.06
    pw, ph = (dw - 0.06) / 2, 0.0
    if lod < 2:
        rows = [(0.1, 0.62, "inset"), (0.74, 1.95, "raised")]
        for (ya, yb, kind) in rows:
            for side in (-1, 1):
                pcx = cx + side * (dw / 4 - 0.008)
                leaf.merge(S.panel(dw / 2 - 0.02, yb - ya, t=0.045, border=0.06, kind=kind if lod == 0 else "inset", tag="door",
                                   origin=(pcx, (ya + yb) / 2, z + 0.045), right=(1, 0, 0), up=(0, 1, 0)))
        leaf.merge(S.chamfer_box((cx, 0.05, z + 0.022), (dw / 2, 0.05, 0.024), 0.006, "door", edges="front"))
        leaf.merge(S.chamfer_box((cx, 0.68, z + 0.022), (dw / 2, 0.06, 0.024), 0.006, "door", edges="front"))
        leaf.merge(S.chamfer_box((cx, 2.02, z + 0.022), (dw / 2, 0.08, 0.024), 0.006, "door", edges="front"))
        if lod == 0:
            knob = S.lathe([(0.0, 0.03), (0.01, 0.03), (0.02, 0.012), (0.05, 0.012), (0.06, 0.028), (0.085, 0.03), (0.095, 0.0)], 10,
                           tag="brass")
            leaf.merge(S.along(knob, (0, 0, -1), (cx, 1.0, z - 0.002)))
            leaf.merge(S.chamfer_box((cx, 0.86, z - 0.006), (0.14, 0.022, 0.004), 0.003, "brass", edges="front"))
            leaf.merge(S.box((cx, 0.86, z - 0.011), (0.12, 0.006, 0.0015), "hole"))
    else:
        leaf.merge(S.box((cx, dh / 2, z + 0.02), (dw / 2, dh / 2, 0.02), "door"))
    m.merge(leaf)
    # the street plate: blue enamel, dark green border, two lines of white letters (painted)
    if lod < 2:
        m.merge(S.chamfer_box((cx, 2.47, -0.006), (0.33, 0.11, 0.006), 0.003, "enamel", edges="front"))
        for sx in (-1, 1):
            for sy in (-1, 1):
                m.merge(S.prism((cx + sx * 0.30, 2.47 + sy * 0.085, -0.012), 0.006, 0.003, 6, tag="bolt", axis=(0, 0, -1)))
        # the house number: a small blue enamel plate by the door
        m.merge(S.chamfer_box((x1 - 0.1, 1.72, -0.004), (0.06, 0.07, 0.004), 0.002, "enamel", edges="front"))
    return m


def _plaques(lod):
    """A cast plaque with raised letters on the ashlar (as on Paris's public buildings)."""
    m = Mesh()
    if lod > 0:
        return m
    x = panel_x(5) + PANEL / 2
    y = 0.32
    m.merge(S.chamfer_box((x, y, -PROUD - 0.006), (0.28, 0.1, 0.006), 0.004, "cast", edges="front"))
    m.merge(S.sweep([(x - 0.265, y - 0.085, -PROUD - 0.012), (x + 0.265, y - 0.085, -PROUD - 0.012), (x + 0.265, y + 0.085, -PROUD - 0.012),
                     (x - 0.265, y + 0.085, -PROUD - 0.012)], [(-0.004, -0.003), (0.004, -0.003), (0.004, 0.003), (-0.004, 0.003)],
                    "letter", closed=True, up=(0, 0, -1)))
    m.merge(T.mesh("ÉDIFICE PUBLIC", 0.016, 0.003, origin=(x, y + 0.052, -PROUD - 0.012), tag="letter"))
    m.merge(T.mesh("DÉFENSE D'AFFICHER", 0.029, 0.004, origin=(x, y + 0.0, -PROUD - 0.012), tag="letter"))
    m.merge(T.mesh("LOI DU 29 JUILLET 1881", 0.015, 0.003, origin=(x, y - 0.05, -PROUD - 0.012), tag="letter"))
    return m


# --- Roof copings ----------------------------------------------------------------------------------

def _roofs(lod):
    """The wall's top: a gable coping of flat tiles under ridge caps on the left half, a lean-to
    of canal tiles on the right half."""
    m = Mesh()
    pitch = 35.0
    half_w = 0.32  # each slope reaches this far either side of the ridge, over the wall's top
    rise = half_w * np.tan(np.radians(pitch))
    p = np.radians(pitch)
    slope_len = half_w / np.cos(p)
    ridge = WALL_TOP + rise
    # the deck under the tiles (seen at the gable ends)
    for s in (-1, 1):
        R = S.rotation(X, s * p)
        deck = S.box((0, -0.015, 0), (1.5, 0.012, slope_len / 2), "mortar").transformed(R, (-1.5, WALL_TOP + rise / 2 - 0.01, 0.09 - s * half_w / 2))
        m.merge(deck)
    if lod < 2:
        for s in (-1, 1):  # both slopes, rising from the eaves to the ridge
            ft = F.roof_tiles(3.0, slope_len + 0.02, pitch, "flat", origin=(LEFT, WALL_TOP - 0.01, 0.09 - half_w - 0.03), tag="tile",
                              lod=lod, unit0=2000 + (s > 0) * 500, seed=11 + s)
            if s > 0:  # the back slope: the front one turned round the ridge line
                R = S.rotation(Y, np.pi)
                ft.verts = [R @ (v - np.array([-1.5, 0, 0.09])) + np.array([-1.5, 0, 0.09]) for v in ft.verts]
            m.merge(ft)
        m.merge(F.ridge_caps(3.0, origin=(LEFT, ridge + 0.01, 0.09), r=0.11, unit0=3000, lod=lod))
    # the lean-to: canal tiles falling to the front
    if lod < 2:
        m.merge(F.roof_tiles(3.0, 0.75, 22.0, "canal", origin=(0.0, WALL_TOP - 0.02, -0.38), tag="canal", lod=lod, unit0=4000, seed=5))
    lean = S.box((0, 0, 0), (1.5, 0.02, 0.38), "mortar").transformed(S.rotation(X, np.radians(22)), (1.5, WALL_TOP + 0.11, -0.03))
    m.merge(lean)
    return m


# --- The floor -------------------------------------------------------------------------------------

def _floor(lod):
    m = Mesh()
    z0, z1 = FLOOR_Z
    d = z0 - z1
    if lod < 2:
        m.merge(F.setts(1.0, d, origin=(-3.0, 0.0, z1), lod=lod, seed=1, unit0=10))
        m.merge(F.setts(1.0, d, origin=(-2.0, 0.0, z1), pattern="fan", lod=lod, seed=2, unit0=400))
        m.merge(F.pavers(1.0, d, origin=(-1.0, 0.0, z1), lod=lod, unit0=800))
    else:
        m.merge(S.box((-1.5, -0.03, (z0 + z1) / 2), (1.5, 0.03, d / 2), "sett"))
    # asphalt with a road word (painted: the material's `extra`)
    m.merge(S.box((0.5, -0.03, (z0 + z1) / 2), (0.5, 0.03, d / 2), "road_paint"))
    # stone slabs round a tree grate
    for i, (a, b) in enumerate(((1.0, 1.25), (1.75, 2.0))):
        m.merge(S.chamfer_box(((a + b) / 2, -0.04, (z0 + z1) / 2), ((b - a) / 2 - 0.004, 0.04, d / 2 - 0.004), 0.006, "slab",
                              edges="top").set_unit(5000 + i))
    for i, (a, b) in enumerate(((z1, z1 + 0.35), (z0 - 0.35, z0))):
        m.merge(S.chamfer_box((1.5, -0.04, (a + b) / 2), (0.25 - 0.004, 0.04, (b - a) / 2 - 0.004), 0.006, "slab",
                              edges="top").set_unit(5010 + i))
    if lod < 2:
        m.merge(F.grille(0.24, 0.07, rings=4, spokes=16, origin=(1.5, 0.0, (z0 + z1) / 2), lod=lod, square=False))
    # the swatches: one block of each kind of material, burnt in the burnt state
    sw = ["sw_wood", "shape", "sw_brick", "sw_plaster", "glass", "sw_clay", "sw_rubber", "sw_cloth"]
    m.merge(S.box((2.5, -0.02, (z0 + z1) / 2), (0.5, 0.02, d / 2), "slab"))
    for i, t in enumerate(sw):
        x = 2.06 + i * 0.125
        m.merge(S.chamfer_box((x, 0.06, (z0 + z1) / 2), (0.05, 0.06, 0.22), 0.008, t, edges="top"))
    return m


# --- The bench of shapes ---------------------------------------------------------------------------

def _bench(lod):
    m = Mesh()
    z0, z1 = BENCH_Z
    zc = (z0 + z1) / 2
    top = BENCH_H
    m.merge(S.chamfer_box((-0.5, top - 0.025, zc), (2.9, 0.025, (z0 - z1) / 2), 0.008, "bench", edges="top"))
    for x in (-3.3, -0.5, 2.3):
        for z in (z0 - 0.08, z1 + 0.08):
            m.merge(S.chamfer_box((x, (top - 0.05) / 2, z), (0.03, (top - 0.05) / 2, 0.03), 0.006, "bench", edges="vertical"))
    if lod >= 2:
        return m
    at = lambda x, y=0.0: (x, top + y, zc)  # noqa: E731
    # chamfered and bevelled boxes
    m.merge(S.chamfer_box(at(-3.1, 0.1), (0.12, 0.1, 0.12), 0.02, "shape"))
    m.merge(S.bevel_box(at(-2.75, 0.08), (0.14, 0.08, 0.1), 0.025, "shape"))
    # a turned baluster
    bal = [(0.0, 0.05), (0.03, 0.05), (0.04, 0.035), (0.07, 0.03), (0.1, 0.045), (0.16, 0.06), (0.22, 0.045), (0.27, 0.025),
           (0.29, 0.03), (0.31, 0.04), (0.34, 0.04)]
    m.merge(S.lathe(bal, 12 if lod == 0 else 6, tag="column").transformed(np.eye(3), at(-2.4)))
    # an extrusion: a T outline with its edge chamfered, lying on its back
    tee = [(-0.12, 0.0), (0.12, 0.0), (0.12, 0.05), (0.035, 0.05), (0.035, 0.2), (-0.035, 0.2), (-0.035, 0.05), (-0.12, 0.05)]
    m.merge(S.extrude(tee, 0.05, 0.008, "shape", origin=(-2.05, top, zc - 0.1), right=(1, 0, 0), up=(0, 0, 1)))
    # panels: inset and raised, standing
    m.merge(S.panel(0.22, 0.34, kind="inset", tag="door", origin=(-1.72, top + 0.17, zc)))
    m.merge(S.panel(0.22, 0.34, kind="raised", tag="door", origin=(-1.45, top + 0.17, zc)))
    # a linear array: a little railing of balusters on a plinth and under a rail
    small = S.lathe([(0.0, 0.016), (0.02, 0.012), (0.08, 0.02), (0.14, 0.012), (0.16, 0.016)], 6 if lod else 8, tag="column")
    m.merge(S.array_linear(small.transformed(np.eye(3), at(-1.2, 0.03)), 7, (0.055, 0, 0)))
    m.merge(S.chamfer_box(at(-1.2 + 0.165, 0.015), (0.2, 0.015, 0.03), 0.005, "column", edges="top"))
    m.merge(S.chamfer_box(at(-1.2 + 0.165, 0.205), (0.2, 0.015, 0.03), 0.005, "column", edges="top"))
    # a radial array: a flange with a bolt circle
    fl = S.lathe([(0.0, 0.12), (0.025, 0.12), (0.03, 0.06), (0.09, 0.05)], 16 if lod == 0 else 8, tag="pipe")
    m.merge(fl.transformed(np.eye(3), at(-0.55)))
    bolt = S.prism((0.095, top + 0.025, 0.0), 0.011, 0.012, 6, tag="bolt")
    bolts = S.array_radial(bolt, 8, (0, 0, 0))
    m.merge(bolts.transformed(np.eye(3), (-0.55, 0.0, zc)))
    # a pipe with bends running up and over
    path = [at(-0.2, 0.0), at(-0.2, 0.25), at(0.15, 0.25), (0.15, top + 0.25, zc + 0.15), (0.45, top + 0.45, zc + 0.15)]
    m.merge(S.pipe(path, 0.022, 8 if lod == 0 else 5, bend=0.07, tag="pipe"))
    # a cable hung between two posts
    for x in (0.6, 1.3):
        m.merge(S.chamfer_box(at(x, 0.2), (0.015, 0.2, 0.015), 0.004, "rail", edges="vertical"))
    m.merge(S.cable(at(0.6, 0.39), at(1.3, 0.39), 0.08, 0.006, n=14 if lod == 0 else 6))
    # a block of stencil letters... (painted, see `extra`) on a crate
    m.merge(S.chamfer_box(at(1.75, 0.15), (0.3, 0.15, 0.15), 0.01, "sw_wood", edges="all"))
    return m


def _column_parts(lod):
    """A stone column cut on a slanting, broken line: the base stays, the top is the moving part."""
    z0, z1 = BENCH_Z
    zc = (z0 + z1) / 2
    col = S.chamfer_box((2.4, BENCH_H + 0.3, zc), (0.09, 0.3, 0.09), 0.015, "column", edges="vertical")
    if lod == 0:
        col = S.subdivide(col, 1)
    base, top = S.cut(col, (2.4, BENCH_H + 0.3, zc), (0.45, 1.0, 0.15), tag="break", rough=0.03 if lod == 0 else 0.0, seed=7)
    return base, top


# --- The element -----------------------------------------------------------------------------------

def kit(lod):
    body = Mesh()
    body.merge(_wall(lod))
    body.merge(_cellar_vent(lod))
    body.merge(_bolted_plate(lod))
    body.merge(_sheets(lod))
    body.merge(_window(lod))
    body.merge(_door(lod))
    body.merge(_plaques(lod))
    body.merge(_roofs(lod))
    body.merge(_floor(lod).transformed(np.eye(3), (0.0, FLOOR_LIFT, 0.0)))  # standing on the ground, not in it
    body.merge(_bench(lod))
    if lod < 2:
        body.merge(S.handrail([(-3.3, 0.0, BENCH_Z[1] - 0.15), (0.0, 0.0, BENCH_Z[1] - 0.15), (2.8, 0.0, BENCH_Z[1] - 0.15)], post_every=1.4, sides=8 if lod == 0 else 5,
                              tag="rail"))
    shutter, pivot = _shutter(lod)
    base, top = _column_parts(lod)
    body.merge(base)
    if lod > 0:
        body.merge(shutter)
        body.merge(top)
        return {"body": Part(body)}
    pts = np.array(top.verts)
    low = pts[np.argmin(pts[:, 1])]  # the column's top tips over its lowest corner
    return {
        "body": Part(body),
        "shutter": Part(shutter, tuple(pivot), {"rotate": [[0, 1, 0], -165.0]}),
        "fallen": Part(top, (float(low[0]) + 0.09, float(low[1]), float(BENCH_Z[0] + BENCH_Z[1]) / 2), {"rotate": [[0, 0, 1], -80.0]}),
    }


def _text(P, N, tag, tags, state, col):
    """The painted lettering: the street plate (white on blue, a dark green border, two lines),
    the house number, the road word stretched along the road, the stencil on the board-formed
    concrete and on the crate."""
    def on(t):
        return tag == tags.index(t)
    white = np.array([0.90, 0.90, 0.88], np.float32)
    green = np.array([0.08, 0.26, 0.18], np.float32)
    age = {"clean": 0.0, "abandoned": 0.25, "damaged": 0.35, "burnt": 0.7}[state]
    ink = white * (1 - age) + col * age * 0.5
    x0, x1 = DOOR_X
    cx = (x0 + x1) / 2
    front = N[:, 2] < -0.5
    en = on("enamel") & front
    # the plate's border: a green band inside the edge
    plate = en & (P[:, 1] > 2.3)
    bx = np.abs(P[:, 0] - cx)
    by = np.abs(P[:, 1] - 2.47)
    border = plate & ((bx > 0.33 - 0.028) | (by > 0.11 - 0.028)) & ~((bx > 0.33 - 0.012) | (by > 0.11 - 0.012))
    col = np.where(border[:, None], green * (1 - age) + col * age, col)
    t1 = T.mask(P, "RUE DES TANNEURS", (cx, 2.495, 0), 0.042) & plate
    t2 = T.mask(P, "XVIIE SIÈCLE", (cx, 2.415, 0), 0.022) & plate
    col = np.where((t1 | t2)[:, None], ink, col)
    num = en & (P[:, 1] < 1.9)
    n = T.mask(P, "12", (x1 - 0.1, 1.72, 0), 0.08, weight=1.2) & num
    col = np.where(n[:, None], ink, col)
    nb = num & ((np.abs(P[:, 0] - (x1 - 0.1)) > 0.045) | (np.abs(P[:, 1] - 1.72) > 0.055))
    col = np.where(nb[:, None], green * (1 - age) + col * age, col)
    # the road word: BUS, its letters 3 times as long as wide, read by a driver coming from the front
    road = on("road_paint") & (N[:, 1] > 0.5)
    yellow = np.array([0.82, 0.72, 0.22], np.float32) * (1 - age * 0.6) + col * age * 0.6
    rw = T.mask(P, "BUS", (0.5, 0.0, -0.75), 0.9, right=(-1, 0, 0), up=(0, 0, 1), aspect=3.2, weight=1.25) & road
    col = np.where(rw[:, None], yellow, col)
    # the stencil: on the board-formed panel and on the crate
    stencil_c = np.array([0.08, 0.08, 0.08], np.float32) * (1 - age) + col * age
    board = on("board") & front
    s1 = T.mask(P, "ABRI 12", (panel_x(1) + 0.33, UP[0] + 0.68, 0), 0.1, font="stencil") & board
    s2 = T.mask(P, "À 50 M", (panel_x(1) + 0.33, UP[0] + 0.53, 0), 0.06, font="stencil") & board
    col = np.where((s1 | s2)[:, None], stencil_c, col)
    crate = on("sw_wood") & front & (P[:, 1] > BENCH_H)
    s3 = T.mask(P, "MUNITIONS", (1.75, BENCH_H + 0.19, 0), 0.05, font="stencil") & crate
    s4 = T.mask(P, "7,62 - 1200 CART.", (1.75, BENCH_H + 0.1, 0), 0.026, font="stencil") & crate
    col = np.where((s3 | s4)[:, None], np.array([0.12, 0.10, 0.08], np.float32), col)
    return col


def samples():
    """Where each sample stands on the board (its middle), by the names tests/test_elements.gd
    asks for."""
    z0, z1 = FLOOR_Z
    zf = (z0 + z1) / 2
    zb = (BENCH_Z[0] + BENCH_Z[1]) / 2
    pc = lambda c, t: [float(v) for v in _panel_centre(c, t)]  # noqa: E731
    bench = lambda x, y=0.1: [x, BENCH_H + y, zb]  # noqa: E731
    dcx = (DOOR_X[0] + DOOR_X[1]) / 2
    return {
        "chamfer_box": bench(-3.1), "bevel_box": bench(-2.75), "lathe": bench(-2.4, 0.17), "extrude": bench(-2.05, 0.03),
        "panel_inset": bench(-1.72, 0.17), "panel_raised": bench(-1.45, 0.17), "array_linear": bench(-1.03),
        "array_radial": bench(-0.55, 0.03), "sweep_pipe": bench(0.0, 0.25), "cable": bench(0.95, 0.33),
        "handrail": [0.0, 0.9, BENCH_Z[1] - 0.15], "window_frame": pc(5, 1), "door_frame": [dcx, 1.2, 0.0],
        "vent": [panel_x(5) + PANEL / 2 - 0.2, 0.7, -PROUD], "louvre_vent": [panel_x(5) + PANEL / 2 + 0.22, 0.71, -PROUD],
        "brick_stretcher": pc(0, 0), "brick_flemish": pc(1, 0), "brick_english": pc(2, 0), "brick_foraine": pc(3, 0),
        "concrete_block": pc(4, 0), "ashlar": pc(5, 0), "setts": [-2.5, FLOOR_LIFT, zf], "setts_fan": [-1.5, FLOOR_LIFT, zf],
        "pavers": [-0.5, FLOOR_LIFT, zf], "roof_flat_tiles": [-1.5, WALL_TOP + 0.1, -0.1], "roof_canal_tiles": [1.5, WALL_TOP + 0.15, -0.2],
        "ridge_caps": [-1.5, WALL_TOP + 0.25, 0.09], "corrugated": pc(2, 1), "ribbed": pc(3, 1), "grille": [1.5, FLOOR_LIFT, zf],
        "mesh": pc(4, 1), "louvres": [panel_x(5) + PANEL / 2 - 0.12, (UP[0] + UP[1]) / 2, -0.08], "board_formed": pc(1, 1),
        "font_block": [dcx, 2.47, -0.01], "font_stencil": [panel_x(1) + 0.33, UP[0] + 0.68, -PROUD],
        "numbers": [DOOR_X[1] - 0.1, 1.72, -0.01], "street_plate": [dcx, 2.47, -0.01], "road_word": [0.5, FLOOR_LIFT, zf],
        "chips": bench(-3.1), "rust_runs": [panel_x(1) + PANEL / 2 + 0.18, UP[0] + 0.2, -PROUD],
        "water_stains": [panel_x(2) + PANEL / 2, LOW[1] - 0.2, -PROUD], "soot": [panel_x(5) + PANEL / 2, UP[1] - 0.1, -PROUD],
        "moss": [panel_x(0) + PANEL / 2, 0.15, -PROUD], "dirt_foot": [panel_x(1) + PANEL / 2, 0.12, -PROUD],
        "posters": [panel_x(4) + PANEL / 2, 0.55, -PROUD], "graffiti": [panel_x(0) + PANEL / 2, 1.55, -PROUD],
        "dents": [panel_x(2) + 0.3, UP[0] + 0.2, -0.02], "broken_glass": [panel_x(5) + PANEL / 2 + 0.125, WIN["sill"] + 0.12, 0.016],
        "pocks": pc(5, 0), "burnt_materials": [2.5, FLOOR_LIFT + 0.06, zf], "cut": bench(2.4, 0.3),
    }


def views():
    """The board's close-ups (the review sheet shoots each in every state): eye, target, fov."""
    zb = (BENCH_Z[0] + BENCH_Z[1]) / 2

    def v(name, eye, at, fov=34.0):
        return {"name": name, "eye": [float(a) for a in eye], "at": [float(a) for a in at], "fov": fov}
    return [
        v("wall_low_a", (-2.0, 0.75, -2.2), (-2.0, 0.55, 0.0), 40),
        v("wall_low_b", (0.0, 0.75, -2.2), (0.0, 0.55, 0.0), 40),
        v("wall_low_c", (2.0, 0.75, -2.2), (2.0, 0.55, 0.0), 40),
        v("wall_up_a", (-2.0, 1.55, -2.2), (-2.0, 1.55, 0.0), 40),
        v("wall_up_b", (0.0, 1.55, -2.2), (0.0, 1.55, 0.0), 40),
        v("wall_up_c", (2.0, 1.55, -2.2), (2.0, 1.55, 0.0), 40),
        v("door", (3.7, 1.45, -2.6), (3.7, 1.4, 0.0), 58),
        v("roofs", (0.0, 3.6, -2.2), (0.0, 2.2, 0.0), 50),
        v("floor_left", (-1.5, 1.7, -2.4), (-1.5, 0.0, -0.75), 50),
        v("floor_right", (1.5, 1.7, -2.4), (1.5, 0.0, -0.75), 50),
        v("bench_a", (-2.8, 1.5, -4.2), (-2.8, BENCH_H + 0.12, zb), 40),
        v("bench_b", (-1.75, 1.5, -4.2), (-1.75, BENCH_H + 0.12, zb), 40),
        v("bench_c", (-0.7, 1.5, -4.2), (-0.7, BENCH_H + 0.12, zb), 40),
        v("bench_d", (0.35, 1.5, -4.2), (0.35, BENCH_H + 0.12, zb), 40),
        v("bench_e", (1.4, 1.5, -4.2), (1.4, BENCH_H + 0.12, zb), 40),
        v("bench_f", (2.4, 1.5, -4.2), (2.4, BENCH_H + 0.12, zb), 40),
        v("glass_close", (2.75, 1.45, -0.75), (2.62, 1.34, 0.0), 30),
        v("plaque_vent", (2.5, 0.6, -1.0), (2.5, 0.5, 0.0), 34),
        v("street_plate", (3.7, 2.3, -1.0), (3.7, 2.4, 0.0), 30),
    ]


def decals():
    p4 = panel_x(4) + PANEL / 2
    p0 = panel_x(0) + PANEL / 2
    c5 = panel_x(5) + PANEL / 2
    return [
        {"kind": "poster", "at": (p4 - 0.18, 0.55, -PROUD), "size": (0.34, 0.48), "seed": 0,
         "text": ["AVIS", "À LA POPULATION", "LES HABITANTS DU", "QUARTIER SONT PRIÉS", "DE REJOINDRE", "LE POINT DE", "RASSEMBLEMENT"]},
        {"kind": "poster", "at": (p4 + 0.22, 0.6, -PROUD), "size": (0.3, 0.4), "seed": 3,
         "text": ["COUVRE-FEU", "DÈS 20 HEURES", "PAR ORDRE DU PRÉFET"]},
        {"kind": "graffiti", "at": (p0, 1.55, -PROUD), "size": (0.86, 0.3), "text": "ILS ARRIVENT", "seed": 2, "colour": 1},
        {"kind": "graffiti", "at": (panel_x(3) + PANEL / 2, 1.35, -0.03), "size": (0.86, 0.26), "text": "NE PAS OUVRIR", "seed": 5,
         "colour": 0, "depth": 0.08, "states": ("abandoned", "damaged", "burnt")},
        {"kind": "soot", "at": (c5, WIN["sill"] + WIN["h"] + 0.15, -PROUD), "size": (0.7, 0.36), "depth": 0.1},
        {"kind": "soot", "at": ((DOOR_X[0] + DOOR_X[1]) / 2, 2.45, -0.02), "size": (1.1, 0.7), "depth": 0.14},
    ]


ELEMENTS = {
    "kit": {
        "build": kit,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "tex": 4096,
        "edge_radius": 0.004,
        "extra": _text,
        "extra_first": True,
        "samples": samples,
        "views": views,
        "decals": decals(),
        "uv_margin": 0.0015,  # thousands of small islands (setts, tiles): thin margins, or the texture goes to gaps
        "uv_scale": {"backing": 0.35, "bench": 0.6, "mortar": 0.5, "sand": 0.6, "enamel": 6.0, "board": 2.0, "plaster": 1.6, "road_paint": 1.5, "sw_wood": 2.0, "block": 1.6,
                     "shutter_steel": 1.5, "cast": 2.0, "letter": 2.0, "glass": 2.0},
        "glass_holes": [((panel_x(5) + PANEL / 2 + WIN["w"] / 4 + 0.02, WIN["sill"] + 0.012 + (WIN["h"] / 3 - 0.024) * 0.55, 0.016),
                         0.05, (0, 0, -1))],
    },
}
