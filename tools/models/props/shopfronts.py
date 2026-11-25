"""The shopfront kit (S158). Card and references: references/elements/shopfront.md; the workflow:
references/elements/WORKFLOW.md.

shopfront: the wooden front applied to the house (devanture en applique) of an old Paris shop:
a stone step, panelled side boxes that hold the night shutters, panelled stall risers under two
shop windows, a glazed door in the middle, a frieze of panels over them, the deep fascia that
carries the shop's name and a cornice capped in zinc. The night shutters (panels with an iron
bar across) are one moving part: at rest they are up over the windows; opened they go into
the shop. The door opens into the shop.

Coordinates: metres, Y up, the front is -Z, x = 0 the middle (the viewer's left is +X); the
house's wall face is z = 0, the pavement y = 0. The house leaves a bay `bay()` wide for it.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

# --- Measurements (the card, round 1: frontal_wood straightened at 160 px/m) -----------------------
W = 4.80                 # the side boxes' outsides
STEP = (0.13, 0.38)      # the stone step: its height, how far in front of the joinery's face
ZF = -0.20               # the joinery's face, in front of the wall
BOX_W = 0.40             # each side box (coffre) holding the shutters
RISER_TOP = 0.78         # the stall riser under the windows
GLASS_TOP = 2.09         # the windows' and the door's heads
FRIEZE_TOP = 2.50        # the frieze of panels over them
FASCIA = (2.56, 3.42)    # the fascia board
CORNICE_TOP = 3.56
CORNICE_OUT = 0.42       # how far the cornice stands in front of the wall
CORNICE_SIDE = 0.20      # and past the side boxes (frontal_wood, brown_frontal)
DOOR_W = 1.00
POST = 0.09              # the posts between the windows and the door
ROOM_D = 1.40            # the dark shop behind the glass


def _bx(x0, x1, y0, y1, z0, z1, tag, c=0.0, edges="front"):
    centre = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    half = (abs(x1 - x0) / 2, abs(y1 - y0) / 2, abs(z1 - z0) / 2)
    if c > 0 and min(half) > c * 1.2:
        return S.chamfer_box(centre, half, c, tag, edges=edges)
    return S.box(centre, half, tag)


def _panel(x0, x1, y0, y1, z_back, t, lod, tag="joinery", border=0.07, kind="raised"):
    """A fielded panel in a frame, its back at z_back, its front t in front of it."""
    w, h = abs(x1 - x0), abs(y1 - y0)
    if lod >= 2:
        return _bx(x0, x1, y0, y1, z_back - t, z_back, tag)
    border = min(border, w / 3, h / 3)
    return S.panel(w, h, t=t, border=border, kind=kind if lod == 0 else "inset", depth=0.01, bevel=0.025, tag=tag,
                   origin=((x0 + x1) / 2, (y0 + y1) / 2, z_back))


def materials():
    return {
        "joinery": Material((0.10, 0.22, 0.16), under=(0.40, 0.30, 0.22), bare=(0.42, 0.32, 0.22), kind="wood", rusts=False),
        "fascia": Material((0.10, 0.22, 0.16), under=(0.40, 0.30, 0.22), bare=(0.42, 0.32, 0.22), kind="wood", rusts=False),
        "shutter": Material((0.12, 0.24, 0.17), under=(0.45, 0.42, 0.36), bare=(0.45, 0.36, 0.26), kind="wood", rusts=False),
        "stone": Material((0.62, 0.60, 0.55), kind="stone", chip=0.0, rusts=False, grain=0.08),
        "zinc": Material((0.52, 0.54, 0.54), under=(0.46, 0.47, 0.46), bare=(0.40, 0.40, 0.39), chip=0.3, grain=0.1, rusts=False),
        "glass": Material((0.20, 0.23, 0.26), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "iron": Material((0.10, 0.10, 0.11), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.3, grain=0.1),
        "bolt": Material((0.12, 0.12, 0.12), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), grain=0.1, fixing=True),
        "brass": Material((0.62, 0.50, 0.24), under=(0.45, 0.36, 0.18), bare=(0.5, 0.4, 0.2), chip=0.2, rusts=False, grain=0.1),
        "room": Material((0.05, 0.045, 0.04), kind="sand", chip=0.0, rusts=False, grain=0.2, sheds=False),
    }


def _layout():
    """x extents of the windows and the door: box | window | door | window | box (+X first)."""
    inner = W / 2 - BOX_W                      # the boxes' insides
    door = DOOR_W / 2
    win_l = (inner, door + POST)                # the window on the viewer's left (+X)
    return inner, door, win_l


def _front(lod):
    m = Mesh()
    c = 0.006 if lod == 0 else 0.0
    inner, door, (wa, wb) = _layout()
    half = W / 2
    # the step across the whole front
    m.merge(_bx(-half - 0.05, half + 0.05, 0.0, STEP[0], ZF - STEP[1] + 0.2, 0.0, "stone", 0.01 if lod == 0 else 0.0, "top"))
    # the side boxes: a plinth, a panelled front, a capital under the fascia
    for s in (1, -1):
        x0, x1 = s * half, s * inner
        m.merge(_bx(x0, x1, STEP[0], FASCIA[0], ZF - 0.02, 0.0, "joinery", c))
        m.merge(_bx(x0 + s * 0.015, x1 - s * 0.015, STEP[0], STEP[0] + 0.18, ZF - 0.04, ZF, "joinery", c))
        m.merge(_panel(x0 - s * 0.05, x1 + s * 0.05, STEP[0] + 0.26, FRIEZE_TOP - 0.18, ZF - 0.02, 0.025, lod))
        m.merge(_bx(x0 + s * 0.015, x1 - s * 0.015, FRIEZE_TOP - 0.12, FASCIA[0], ZF - 0.05, ZF, "joinery", c))
    # the stall risers, the windows' frames and their glass
    for s in (1, -1):
        a, b = s * wa, s * wb
        m.merge(_bx(a, b, STEP[0], RISER_TOP, ZF, ZF + 0.04, "joinery"))
        m.merge(_panel(a - s * 0.06, b + s * 0.06, STEP[0] + 0.07, RISER_TOP - 0.08, ZF, 0.022, lod))
        m.merge(_bx(a + s * 0.01, b - s * 0.01, RISER_TOP - 0.06, RISER_TOP, ZF - 0.045, ZF, "joinery", c, "top"))  # the sill rail
        m.merge(_bx(b, b + s * POST, STEP[0], GLASS_TOP, ZF - 0.02, ZF + 0.05, "joinery", c))  # the post by the door
        for x in (a, b):  # the window's own stiles
            m.merge(_bx(x, x - s * 0.06 if x == a else x + s * 0.06, RISER_TOP, GLASS_TOP, ZF - 0.01, ZF + 0.04, "joinery", c))
        mid = (a + b) / 2  # one glazing bar
        if lod < 2:
            m.merge(_bx(mid - 0.02, mid + 0.02, RISER_TOP, GLASS_TOP, ZF + 0.005, ZF + 0.035, "joinery", c))
        m.merge(_bx(a - s * 0.06, b + s * 0.06, RISER_TOP, GLASS_TOP, ZF + 0.018, ZF + 0.022, "glass"))
    # the head rail over windows and door, the frieze of panels, a fanlight over the door
    m.merge(_bx(-inner, inner, GLASS_TOP, GLASS_TOP + 0.07, ZF - 0.03, ZF + 0.04, "joinery", c))
    y0, y1 = GLASS_TOP + 0.07, FRIEZE_TOP
    for s in (1, -1):
        m.merge(_bx(s * wa, s * wb, y0, y1, ZF, ZF + 0.04, "joinery"))
        m.merge(_panel(s * (wa - 0.05), s * (wb + 0.05), y0 + 0.05, y1 - 0.05, ZF, 0.022, lod))
        m.merge(_bx(s * wb, s * (wb + POST), y0, y1, ZF - 0.02, ZF + 0.04, "joinery", c))
    m.merge(_bx(-door, door, y0, y0 + 0.05, ZF - 0.01, ZF + 0.04, "joinery", c))
    m.merge(_bx(-door, door, y1 - 0.05, y1, ZF - 0.01, ZF + 0.04, "joinery", c))
    m.merge(_bx(-door, door, y0 + 0.05, y1 - 0.05, ZF + 0.018, ZF + 0.022, "glass"))
    # the band under the fascia, the fascia, its mouldings
    m.merge(_bx(-half, half, FRIEZE_TOP, FASCIA[0], ZF - 0.04, 0.0, "joinery", c))
    m.merge(_bx(-half - 0.03, half + 0.03, FASCIA[0], FASCIA[1], ZF - 0.05, 0.0, "fascia", c))
    for y in (FASCIA[0] + 0.03, FASCIA[1] - 0.03):
        m.merge(_bx(-half - 0.04, half + 0.04, y - 0.025, y + 0.025, ZF - 0.08, ZF - 0.05, "joinery", c))
    m.merge(_cornice(lod))
    return m


def _cornice(lod):
    """A moulded cornice along the top, its top a zinc capping sloping out."""
    half = W / 2 + CORNICE_SIDE
    path = [(half, FASCIA[1], 0.0), (-half, FASCIA[1], 0.0)]
    # (forward of the wall, up from the fascia's top): a cove rising out to the corona
    full = [(0.0, 0.0), (-ZF + 0.08, 0.0), (-ZF + 0.10, 0.03), (-ZF + 0.14, 0.05), (CORNICE_OUT - 0.04, 0.08),
            (CORNICE_OUT, 0.09), (CORNICE_OUT, CORNICE_TOP - FASCIA[1] - 0.02), (0.0, CORNICE_TOP - FASCIA[1])]
    if lod >= 1:
        full = [full[0], full[1], full[4], full[5], full[6], full[7]]
    m = S.sweep(path, full, "joinery")
    # the zinc capping: a thin sheet over the top with a drip at its edge
    top = CORNICE_TOP - FASCIA[1]
    cap = [(0.0, top + 0.004), (CORNICE_OUT + 0.015, top - 0.02 + 0.004), (CORNICE_OUT + 0.015, top - 0.04),
           (CORNICE_OUT + 0.01, top - 0.04), (CORNICE_OUT + 0.01, top - 0.022), (0.0, top - 0.002)]
    m.merge(S.sweep([(half + 0.01, FASCIA[1], 0.0), (-half - 0.01, FASCIA[1], 0.0)], cap, "zinc"))
    return m


def _room(lod):
    """The dark shop behind the glass: back, sides, floor, ceiling."""
    m = Mesh()
    inner = W / 2 - BOX_W
    z0, z1 = ZF + 0.05, ZF + ROOM_D
    m.merge(_bx(-inner, inner, STEP[0], GLASS_TOP + 0.4, z1, z1 + 0.02, "room"))
    for s in (1, -1):
        m.merge(_bx(s * inner, s * (inner + 0.02), STEP[0], GLASS_TOP + 0.4, z0, z1, "room"))
    m.merge(_bx(-inner, inner, STEP[0] - 0.02, STEP[0], z0, z1, "room"))
    m.merge(_bx(-inner, inner, GLASS_TOP + 0.4, GLASS_TOP + 0.42, z0, z1, "room"))
    return m


def _door(lod):
    """The shop door: stiles, rails, a fielded panel under a glazed top, a brass handle. Hinged on
    its +X stile, it opens into the shop."""
    m = Mesh()
    c = 0.005 if lod == 0 else 0.0
    d = DOOR_W / 2 - 0.004
    y0, y1 = STEP[0] + 0.005, GLASS_TOP - 0.004
    z0, z1 = ZF + 0.0, ZF + 0.05
    st, top, bot, lock = 0.10, 0.10, 0.20, 0.95
    for x in (d, -d):
        m.merge(_bx(x, x - np.sign(x) * st, y0, y1, z0, z1, "joinery", c))
    m.merge(_bx(-d + st, d - st, y1 - top, y1, z0, z1, "joinery", c))
    m.merge(_bx(-d + st, d - st, y0, y0 + bot, z0, z1, "joinery", c))
    m.merge(_bx(-d + st, d - st, lock - 0.06, lock + 0.06, z0, z1, "joinery", c))
    m.merge(_panel(-d + st, d - st, y0 + bot, lock - 0.06, z1 - 0.005, 0.03, lod))
    if lod < 2:
        m.merge(_bx(-0.015, 0.015, lock + 0.06, y1 - top, z0 + 0.01, z1 - 0.01, "joinery", c))  # a glazing bar
    m.merge(_bx(-d + st, d - st, lock + 0.06, y1 - top, (z0 + z1) / 2 - 0.002, (z0 + z1) / 2 + 0.002, "glass"))
    if lod == 0:  # the handle, on the side away from the hinge
        hx = -d + st * 0.5
        m.merge(_bx(hx - 0.012, hx + 0.012, 1.00, 1.16, z0 - 0.03, z0 - 0.01, "brass"))
        m.merge(_bx(hx - 0.02, hx + 0.02, 0.98, 1.18, z0 - 0.01, z0, "brass"))
    return m, (d, y0, z1)


def _shutters(lod):
    """The night shutters up over both windows: boards in a frame, two flat iron bars across
    each, held by pins in the side boxes and the door posts (shutters_up, shutters_up_old)."""
    m = Mesh()
    c = 0.004 if lod == 0 else 0.0
    _, _, (wa, wb) = _layout()
    z0, z1 = ZF - 0.075, ZF - 0.045
    for s in (1, -1):
        a, b = s * (wa + 0.0), s * (wb - 0.0)
        n = 3  # three panels each, butting
        xs = np.linspace(a, b, n + 1)
        for k in range(n):
            p, q = xs[k], xs[k + 1]
            m.merge(_panel(p - s * 0.002, q + s * 0.002, RISER_TOP, GLASS_TOP, z1, z1 - z0, lod, "shutter", 0.06, "inset"))
        for y in (RISER_TOP + 0.38, GLASS_TOP - 0.38):
            m.merge(_bx(a + s * 0.03, b - s * 0.03, y - 0.025, y + 0.025, z0 - 0.012, z0, "iron", c))
            if lod == 0:
                for x in (a + s * 0.06, b - s * 0.06):  # the bolt heads holding the bar
                    m.merge(S.prism((x, y, z0 - 0.012), 0.012, 0.01, 6, axis=(0, 0, -1), tag="bolt"))
    return m


def bay():
    """The width the house leaves for it, and its height."""
    return W + 0.10, CORNICE_TOP


def shopfront(lod):
    body = _front(lod)
    body.merge(_room(lod))
    door, hinge = _door(lod)
    parts = {
        "body": Part(body),
        "door": Part(door, hinge, {"rotate": [[0, 1, 0], 95.0]}),  # into the shop
        "shutters": Part(_shutters(lod), (0.0, 0.0, 0.0), {"move": [0.0, 0.0, 1.05]}),  # taken down into the shop
    }
    if lod > 0:
        merged = Mesh()
        for p in parts.values():
            merged.merge(p.mesh)
        return {"body": Part(merged)}
    return parts


ELEMENTS = {
    "shopfront": {
        "build": shopfront,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.005,
    },
}
