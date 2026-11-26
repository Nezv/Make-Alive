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
PILASTER = (0.15, 0.03)  # round 2: the fluted pilaster on each side box's outer half: width, proud
CAPITAL = 0.13           # its console capital's height, under the box's capital band
STORE = (0.075, 0.12)    # the rolled awning: radius, stripe width


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
        "fitting": Material((0.20, 0.13, 0.08), under=(0.30, 0.22, 0.15), bare=(0.35, 0.27, 0.18), kind="wood", chip=0.3, rusts=False, sheds=False),
        "goods": Material((0.45, 0.40, 0.32), kind="paper", chip=0.0, rusts=False, grain=0.1, sheds=False,
                          palette=[(0.55, 0.48, 0.36), (0.30, 0.34, 0.40), (0.58, 0.20, 0.16), (0.70, 0.66, 0.58), (0.25, 0.32, 0.22)]),
        "store": Material((0.62, 0.16, 0.13), kind="paper", chip=0.0, rusts=False, grain=0.15,
                          palette=[(0.62, 0.16, 0.13), (0.86, 0.82, 0.72)]),
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
        if lod == 0:  # round 2: a fluted pilaster on the outer half, the panel on the inner (brown_frontal)
            m.merge(_panel(x0 - s * (PILASTER[0] + 0.07), x1 + s * 0.04, STEP[0] + 0.26, FRIEZE_TOP - 0.18, ZF - 0.02, 0.025, lod))
            m.merge(_pilaster(s, x0 - s * 0.035, lod))
        else:
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
    if lod < 2:  # round 2: the fascia's end blocks, each with a rosette (brown_frontal)
        for s in (1, -1):
            bx0, bx1 = s * (half - 0.02), s * (half - 0.26)
            m.merge(_bx(bx0, bx1, FASCIA[0] + 0.06, FASCIA[1] - 0.06, ZF - 0.10, ZF - 0.05, "joinery", c))
            if lod == 0:
                cx, cy = (bx0 + bx1) / 2, (FASCIA[0] + FASCIA[1]) / 2
                m.merge(S.prism((cx, cy, ZF - 0.10), 0.085, 0.012, 12, axis=(0, 0, -1), tag="joinery"))
                m.merge(S.prism((cx, cy, ZF - 0.112), 0.055, 0.014, 8, turn=np.pi / 8, axis=(0, 0, -1), tag="joinery"))
                m.merge(S.prism((cx, cy, ZF - 0.126), 0.022, 0.012, 6, axis=(0, 0, -1), tag="brass"))
    m.merge(_cornice(lod))
    if lod < 2:
        m.merge(_store(lod))
    return m


def _pilaster(s, x_out, lod):
    """A fluted pilaster on a side box (x_out its outer edge), its base, and a console capital
    with two volutes under the box's capital band (brown_frontal, yellow_pilasters)."""
    m = Mesh()
    w, p = PILASTER
    a, b = x_out, x_out - s * w
    z = ZF - 0.02
    y0, y1 = STEP[0] + 0.18, FRIEZE_TOP - 0.12 - CAPITAL
    m.merge(_bx(a, b, y0, y1, z - p * 0.5, z, "joinery", 0.004))  # the shaft
    for k in range(4):  # the fillets between the flutes
        x = a - s * (0.018 + k * (w - 0.036) / 3)
        m.merge(_bx(x - 0.007, x + 0.007, y0 + 0.08, y1 - 0.06, z - p, z - p * 0.5, "joinery", 0.003))
    m.merge(_bx(a + s * 0.01, b - s * 0.01, y0, y0 + 0.08, z - p - 0.012, z, "joinery", 0.006, "top"))  # the base
    # the console: a neck, a block widening upwards, an abacus
    m.merge(_bx(a, b, y1, y1 + 0.03, z - p - 0.005, z, "joinery", 0.004))
    m.merge(_bx(a + s * 0.008, b - s * 0.008, y1 + 0.03, y1 + CAPITAL - 0.03, z - p - 0.03, z, "joinery", 0.008, "front"))
    m.merge(_bx(a + s * 0.02, b - s * 0.02, y1 + CAPITAL - 0.03, y1 + CAPITAL, z - p - 0.05, z, "joinery", 0.006, "front"))
    for x in (a, b):  # the volutes curling out at its corners
        m.merge(S.prism((x, y1 + CAPITAL - 0.05, z - p - 0.035), 0.026, 0.03, 8, axis=(0, 0, 1), tag="joinery"))
        m.merge(S.prism((x, y1 + CAPITAL - 0.05, z - p - 0.040), 0.012, 0.006, 6, axis=(0, 0, 1), tag="joinery"))
    return m


def _store(lod):
    """The striped fabric awning (store) rolled up on its roller under the fascia, under a zinc
    hood, its folded arms hanging down the side boxes (rolled out: a later round)."""
    m = Mesh()
    r, stripe = STORE
    inner = W / 2 - 0.10
    y = FRIEZE_TOP - 0.01
    z = ZF - 0.05 - r
    n = int(round(2 * inner / stripe)) if lod == 0 else 1  # far: one roll, its stripes baked from LOD 0
    sides = 8 if lod == 0 else 5
    for k in range(n):  # the roll: one band per stripe, alternating
        x0 = -inner + k * 2 * inner / n
        band = S.lathe([(0.0, r), (2 * inner / n, r)], sides, tag="store", caps=(k == 0, k == n - 1))
        band.set_unit(k % 2)
        m.merge(S.along(band, (1, 0, 0), (x0, y, z)))
    if lod == 0:  # the valance hanging from the roll: scalloped edge
        for k in range(n):
            x0 = -inner + k * 2 * inner / n
            v = S.box((x0 + inner / n, y - r - 0.07, z - r * 0.6), (inner / n - 0.002, 0.07, 0.003), "store")
            v.set_unit(k % 2)
            m.merge(v)
    # the hood: a zinc sheet sloping over the roll
    hood = [(0.0, 0.0), (0.0, 0.03), (-(r * 2 + 0.03), -0.04), (-(r * 2 + 0.03), -0.06), (-(r * 2 + 0.02), -0.06), (-0.003, 0.0)]
    hood = [(-q[0], q[1]) for q in hood]
    m.merge(S.sweep([(inner + 0.06, y + r + 0.01, ZF - 0.05), (-inner - 0.06, y + r + 0.01, ZF - 0.05)],
                    [(-hz, hy) for hz, hy in hood], "zinc"))
    for s in (1, -1):  # the roller's brackets and the folded arms down the boxes
        m.merge(_bx(s * (inner + 0.02), s * (inner + 0.05), y - r, y + r + 0.01, z - 0.02, ZF - 0.05, "iron"))
        if lod == 0:
            ax = s * (inner + 0.035)
            m.merge(S.pipe([(ax, y - r, z), (ax, y - 0.75, z + 0.03), (ax, y - 0.80, ZF - 0.05)], 0.012, 6, tag="iron"))
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
    if lod < 2:  # round 2: the shop's fittings seen through the glass, a counter and the shelves
        f = STEP[0]
        m.merge(_bx(-inner + 0.25, -0.75, f, f + 0.92, z0 + 0.55, z0 + 1.0, "fitting", 0.01 if lod == 0 else 0.0, "top"))
        m.merge(_bx(-inner + 0.22, -0.72, f + 0.92, f + 0.96, z0 + 0.52, z0 + 1.02, "fitting"))
        for k, y in enumerate((0.55, 0.95, 1.35, 1.75)):  # shelves on the back wall
            m.merge(_bx(-inner + 0.02, inner - 0.02, f + y, f + y + 0.025, z1 - 0.32, z1, "fitting"))
            if lod == 0:  # goods on them: boxes and jars, coloured by the seed of their place
                x = -inner + 0.08
                j = 0
                while x < inner - 0.2:
                    w = 0.10 + 0.08 * ((k * 7 + j * 3) % 4) / 3
                    h = 0.12 + 0.18 * ((k * 5 + j * 11) % 5) / 4
                    if (k + j) % 6 != 3:  # a gap where something was taken
                        g = S.box((x + w / 2, f + y + 0.025 + h / 2, z1 - 0.16), (w / 2 - 0.006, h / 2, 0.12), "goods")
                        g.set_unit(k * 13 + j)
                        m.merge(g)
                    x += w + 0.01
                    j += 1
        for x in (-inner + 0.02, 0.0, inner - 0.02):
            m.merge(_bx(x - 0.02, x + 0.02, f, f + 2.0, z1 - 0.32, z1, "fitting"))
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
        m.merge(_bx(hx - 0.016, hx + 0.016, 0.86, 0.94, z0 - 0.004, z0, "brass"))  # the lock's escutcheon
        m.merge(_bx(hx - 0.004, hx + 0.004, 0.875, 0.905, z0 - 0.006, z0 - 0.004, "room"))
        # round 2: the kick plate across the bottom rail, the letterbox in the lock rail
        m.merge(_bx(-d + 0.02, d - 0.02, y0 + 0.02, y0 + 0.17, z0 - 0.003, z0, "brass"))
        m.merge(_bx(-0.14, 0.14, lock - 0.035, lock + 0.035, z0 - 0.004, z0, "brass", 0.002, "front"))
        m.merge(_bx(-0.11, 0.11, lock - 0.012, lock + 0.012, z0 - 0.006, z0 - 0.004, "room"))
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
            if lod == 0:  # round 2: the studs (clous) in rows down each panel's frame (shutters_up)
                for xx in (p + (q - p) * 0.12, q - (q - p) * 0.12):
                    for yy in np.linspace(RISER_TOP + 0.12, GLASS_TOP - 0.12, 6):
                        if min(abs(yy - (RISER_TOP + 0.38)), abs(yy - (GLASS_TOP - 0.38))) > 0.05:
                            m.merge(S.prism((xx, yy, z0), 0.009, 0.006, 6, axis=(0, 0, -1), tag="bolt"))
        for y in (RISER_TOP + 0.38, GLASS_TOP - 0.38):
            m.merge(_bx(a + s * 0.03, b - s * 0.03, y - 0.025, y + 0.025, z0 - 0.012, z0, "iron", c))
            if lod == 0:
                for x in (a + s * 0.06, b - s * 0.06):  # the bolt heads holding the bar
                    m.merge(S.prism((x, y, z0 - 0.012), 0.012, 0.01, 6, axis=(0, 0, -1), tag="bolt"))
                for x, d in ((a, s), (b, -s)):  # round 2: the bar's hooked ends into the eyes on the box and the post
                    m.merge(S.pipe([(x + d * 0.03, y, z0 - 0.006), (x - d * 0.01, y, z0 - 0.006), (x - d * 0.025, y, z0 + 0.02)],
                                   0.007, 5, tag="iron"))
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
