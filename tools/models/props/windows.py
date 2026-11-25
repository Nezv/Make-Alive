"""The window kit (S157). Card and references of each element: references/elements/<name>.md;
the workflow every element follows: references/elements/WORKFLOW.md.

window_french: the tall French casement of an old Paris plaster front (fenêtre à la française):
a raised plaster band round the opening, a stone sill, the persiennes closing in a rebate in the
wall's face, the reveal going back to the frame, two leaves of panes opening into the room, the
iron garde-corps across the lower part between the jambs, the dark room behind.

Coordinates (as every element): metres, Y up, the front is -Z; x = 0 the window's middle, so
the viewer's left is +X. The wall's face is z = 0, the bottom of the sill y = 0. The house
(S162) cuts a hole the size of the band's outside (`hole()`) and sets this in it.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

# --- Measurements (the card, round 1: frontal_white straightened at 300 px/m) ----------------------
SILL_H = 0.08            # the sill's top: where the opening starts
REBATE_W = 1.40          # the persiennes close in this, flush with the wall's face
REBATE_TOP = 2.49
REBATE_D = 0.05          # how deep the rebate is cut
OPEN_W = 1.30            # the reveal (tableau) behind the rebate
OPEN_TOP = 2.44
BAND = 0.16              # the wall round the rebate that comes with the element
BAND_PROUD = 0.0         # flush: none of the references has a band down the sides
FRAME_Z = 0.20           # the frame's front face, back in the reveal
FRAME_W = 1.23           # the frame's outside
FRAME_TOP = 2.28         # under it the reveal's head comes down to the frame
FRAME_D = 0.06
ROOM_D = 0.60            # the dark room behind the glass
SILL_OVER = -0.06        # the sill ends 0.10 past the rebate (tall_railing), inside the band
SILL_FRONT = 0.055       # ...and in front of the wall
RAIL_TOP = 0.80          # the garde-corps' top rail
SHUTTER_T = 0.034
SLAT_PITCH = 0.067
SHUTTER_MID = 1.40       # the persienne's middle rail (its catch)
PANE_ROWS = 3            # panes up each leaf (tall_railing, blue_frontal; frontal_white has 2)
HEAD_PLATE = (0.90, 0.24, 0.010)  # the raised plaster plate over the opening: half-width, height, proud


def _bx(x0, x1, y0, y1, z0, z1, tag, c=0.0, edges="front"):
    """A box by its extents, chamfered `c` on `edges` (none when 0)."""
    centre = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    half = (abs(x1 - x0) / 2, abs(y1 - y0) / 2, abs(z1 - z0) / 2)
    if c > 0 and min(half) > c * 1.2:
        return S.chamfer_box(centre, half, c, tag, edges=edges)
    return S.box(centre, half, tag)


def materials():
    return {
        "plaster": Material((0.80, 0.77, 0.72), kind="plaster", chip=0.0, rusts=False, grain=0.05),
        "stone": Material((0.72, 0.69, 0.62), kind="stone", chip=0.0, rusts=False, grain=0.07),
        "joinery": Material((0.88, 0.87, 0.83), under=(0.74, 0.72, 0.66), bare=(0.52, 0.46, 0.38), kind="wood", rusts=False),
        "persienne": Material((0.86, 0.85, 0.80), under=(0.70, 0.69, 0.64), bare=(0.50, 0.45, 0.37), kind="wood", rusts=False),
        "glass": Material((0.20, 0.23, 0.26), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "iron": Material((0.10, 0.10, 0.11), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.6, grain=0.1),
        "room": Material((0.05, 0.045, 0.04), kind="sand", chip=0.0, rusts=False, grain=0.2, sheds=False),
    }


# --- The wall round it --------------------------------------------------------------------------

def _surround(lod):
    """The band, the rebate, the reveal back to the frame and its head, the sill."""
    m = Mesh()
    rw, ow = REBATE_W / 2, OPEN_W / 2
    bw = rw + BAND
    top = REBATE_TOP + BAND
    c = 0.006 if lod == 0 else 0.0
    # the band: two jambs and a head, standing proud of the wall's face
    for s in (1, -1):
        m.merge(_bx(s * rw, s * bw, SILL_H, top, -BAND_PROUD, REBATE_D, "plaster", c))
    m.merge(_bx(-rw, rw, REBATE_TOP, top, -BAND_PROUD, REBATE_D, "plaster", c))
    pw, ph, pp = HEAD_PLATE  # the plate over the head (frontal_white, worn_shutters)
    m.merge(_bx(-pw, pw, REBATE_TOP, REBATE_TOP + ph, -pp, 0.0, "plaster", 0.004 if lod == 0 else 0.0))
    # behind the rebate the wall steps in to the reveal, which runs back to the frame
    for s in (1, -1):
        m.merge(_bx(s * ow, s * rw, SILL_H, REBATE_TOP, REBATE_D, FRAME_Z + FRAME_D, "plaster"))
    m.merge(_bx(-rw, rw, OPEN_TOP, REBATE_TOP, REBATE_D, FRAME_Z + FRAME_D, "plaster"))
    m.merge(_bx(-ow, ow, FRAME_TOP, OPEN_TOP, FRAME_Z - 0.03, FRAME_Z + FRAME_D, "plaster"))  # the head down to the frame
    for s in (1, -1):  # and the jambs in to it: the light strip beside the frame
        m.merge(_bx(s * FRAME_W / 2, s * ow, SILL_H, FRAME_TOP, FRAME_Z - 0.03, FRAME_Z + FRAME_D, "plaster"))
    # the sill: a stone slab across the band, its nose in front of the wall
    sw = bw + SILL_OVER
    m.merge(_bx(-sw, sw, 0.0, SILL_H, -SILL_FRONT, FRAME_Z, "stone", 0.012 if lod == 0 else 0.0, "top"))
    # the room: a dark box behind the frame
    fw = FRAME_W / 2
    back = FRAME_Z + FRAME_D + ROOM_D
    m.merge(_bx(-fw, fw, SILL_H, FRAME_TOP, back, back + 0.02, "room"))
    for s in (1, -1):
        m.merge(_bx(s * fw, s * (fw + 0.02), SILL_H, FRAME_TOP, FRAME_Z + FRAME_D, back, "room"))
    m.merge(_bx(-fw, fw, FRAME_TOP, FRAME_TOP + 0.02, FRAME_Z + FRAME_D, back, "room"))
    m.merge(_bx(-fw, fw, SILL_H - 0.02, SILL_H, FRAME_Z + FRAME_D, back, "room"))
    return m


def _frame(lod):
    """The fixed frame (dormant) in the reveal: jambs, head and the sill rail."""
    m = Mesh()
    fw, mw = FRAME_W / 2, 0.035
    z0, z1 = FRAME_Z, FRAME_Z + FRAME_D
    c = 0.004 if lod == 0 else 0.0
    for s in (1, -1):
        m.merge(_bx(s * (fw - mw), s * fw, SILL_H, FRAME_TOP, z0, z1, "joinery", c))
    m.merge(_bx(-fw, fw, FRAME_TOP - mw, FRAME_TOP, z0, z1, "joinery", c))
    m.merge(_bx(-fw, fw, SILL_H, SILL_H + 0.045, z0 - 0.02, z1, "joinery", c))  # the sill rail, in front
    return m


LEAF_STILE, LEAF_TOP, LEAF_BOTTOM, MEET, BAR = 0.05, 0.055, 0.11, 0.075, 0.035


def _leaf(side, lod):
    """One leaf: hinged on the frame's jamb (side +1 the viewer's left), meeting the other in the
    middle; a small pane over a tall one. Returns the mesh and its hinge."""
    fw = FRAME_W / 2 - 0.035
    z0, z1 = FRAME_Z + 0.01, FRAME_Z + 0.055
    x_out, x_in = side * fw, side * 0.003
    lo, hi = SILL_H + 0.045, FRAME_TOP - 0.035
    c = 0.004 if lod == 0 else 0.0
    m = Mesh()
    m.merge(_bx(x_out, x_out - side * LEAF_STILE, lo, hi, z0, z1, "joinery", c))
    m.merge(_bx(x_in, x_in + side * MEET, lo, hi, z0 - 0.008, z1, "joinery", c))  # the meeting stile stands proud
    m.merge(_bx(x_out, x_in, hi - LEAF_TOP, hi, z0, z1, "joinery", c))
    m.merge(_bx(x_out, x_in, lo, lo + LEAF_BOTTOM, z0, z1, "joinery", c))
    g0, g1 = x_out - side * LEAF_STILE, x_in + side * MEET
    gz = (z0 + z1) / 2
    y_lo, y_hi = lo + LEAF_BOTTOM, hi - LEAF_TOP
    pane = (y_hi - y_lo - (PANE_ROWS - 1) * BAR) / PANE_ROWS
    for k in range(PANE_ROWS):
        y0 = y_lo + k * (pane + BAR)
        m.merge(_bx(g0, g1, y0, y0 + pane, gz - 0.002, gz + 0.002, "glass"))
        if k and lod < 2:  # the glazing bar under this pane
            m.merge(_bx(g0, g1, y0 - BAR, y0, z0 + 0.008, z1 - 0.008, "joinery", c))
    hinge = (x_out, lo, z1)
    return m, hinge


def _persienne(side, lod):
    """One persienne, closed in the rebate (side +1 the viewer's left), hinged on its outer edge at
    the wall's face: stiles, rails, a middle rail with its catch, slats tilted down and out."""
    rw = REBATE_W / 2
    x_out, x_in = side * (rw - 0.004), side * 0.002
    lo, hi = SILL_H + 0.006, REBATE_TOP - 0.006
    z0, z1 = -BAND_PROUD + 0.003, -BAND_PROUD + 0.003 + SHUTTER_T
    st, rail = 0.055, 0.07
    c = 0.004 if lod == 0 else 0.0
    m = Mesh()
    for a, b in ((x_out, x_out - side * st), (x_in + side * st, x_in)):
        m.merge(_bx(a, b, lo, hi, z0, z1, "persienne", c))
    g0, g1 = x_out - side * st, x_in + side * st
    for y0, y1 in ((lo, lo + rail * 1.3), (hi - rail, hi), (SHUTTER_MID - rail * 0.45, SHUTTER_MID + rail * 0.45)):
        m.merge(_bx(g0, g1, y0, y1, z0, z1, "persienne", c))
    if lod >= 1:  # past 15 m the slats are one board, a little back, its look baked from LOD 0
        m.merge(_bx(g0, g1, lo, hi, z0 + 0.008, z1 - 0.008, "persienne"))
    else:
        R = S.rotation((1, 0, 0), np.radians(-35))
        half = (abs(g1 - g0) / 2, SLAT_PITCH * 0.56, 0.005)
        cx = (g0 + g1) / 2
        for y0, y1 in ((lo + rail * 1.3, SHUTTER_MID - rail * 0.45), (SHUTTER_MID + rail * 0.45, hi - rail)):
            n = max(1, int(round((y1 - y0) / SLAT_PITCH)))
            for k in range(n):
                y = y0 + (k + 0.5) * (y1 - y0) / n
                slat = S.box((0, 0, 0), half, "persienne")
                m.merge(slat.transformed(R, (cx, y, (z0 + z1) / 2)))
    hinge = (side * rw, lo, -BAND_PROUD)
    return m, hinge


def _garde_corps(lod):
    """The iron guard across the lower part, fixed into the reveal's jambs in front of the frame:
    a top rail, a bottom rail and bars (round 1: the plain form; its scrolls are round 2)."""
    m = Mesh()
    ow = OPEN_W / 2
    z = REBATE_D + 0.03
    m.merge(_bx(-ow, ow, RAIL_TOP - 0.03, RAIL_TOP, z - 0.02, z + 0.02, "iron", 0.004 if lod == 0 else 0.0, "top"))
    m.merge(_bx(-ow, ow, SILL_H + 0.06, SILL_H + 0.08, z - 0.008, z + 0.008, "iron"))
    if lod < 2:
        n = 11
        for k in range(n):
            x = -ow + (k + 1) * OPEN_W / (n + 1)
            m.merge(_bx(x - 0.008, x + 0.008, SILL_H + 0.06, RAIL_TOP - 0.03, z - 0.008, z + 0.008, "iron"))
    return m


def hole():
    """The rectangle the house cuts out of its wall for this: (x half-width, bottom, top)."""
    return REBATE_W / 2 + BAND, 0.0, REBATE_TOP + BAND


def window_french(lod):
    body = _surround(lod)
    body.merge(_frame(lod))
    body.merge(_garde_corps(lod))
    parts = {"body": Part(body)}
    for side, nm in ((1, "leaf_l"), (-1, "leaf_r")):
        mesh, hinge = _leaf(side, lod)
        parts[nm] = Part(mesh, hinge, {"rotate": [[0, 1, 0], 100.0 * side]})  # into the room
    for side, nm in ((1, "shutter_l"), (-1, "shutter_r")):
        mesh, hinge = _persienne(side, lod)
        parts[nm] = Part(mesh, hinge, {"rotate": [[0, 1, 0], -178.0 * side]})  # out and back flat on the wall
    if lod > 0:
        merged = Mesh()
        for p in parts.values():
            merged.merge(p.mesh)
        return {"body": Part(merged)}
    return parts


ELEMENTS = {
    "window_french": {
        "build": window_french,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
    },
}
