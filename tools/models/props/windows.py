"""The window kit (S157). Card and references of each element: references/elements/<name>.md;
the workflow every element follows: references/elements/WORKFLOW.md.

window_french: the tall French casement of an old Paris plaster front (fenêtre à la française):
a raised plaster band round the opening, a stone sill, the persiennes closing in a rebate in the
wall's face, the reveal going back to the frame, two leaves of panes opening into the room, the
iron garde-corps across the lower part between the jambs, the dark room behind.

window_ribbon: one 2.40 m bay of the post-war band window (S157; the hospital's tower, the town
hall's office floors, the bus station's ticket hall): a precast concrete sill with its drip, thin
concrete reveals that are only the ends of the band, an anodised aluminium frame with a middle
mullion and a transom, a fixed pane on the viewer's left, a sash on the right that slides behind it
(part `sash`), a top-hung vent over each half (`vent_l`, `vent_r`), the dark room behind. Bays laid
side by side make the ribbon: each end post is half a mullion.

window_barracks: the tall timber window of the barracks blocks (S157, S221): a deep opening in a
thick white wall with a flat painted band round it, a concrete sill, a frame painted green, two
casement leaves of three panes opening into the room (`leaf_l`, `leaf_r`), a fixed transom and a
fanlight over it that tilts in from its foot (`fanlight`), the dark room behind.

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
DRIP = (0.022, 0.034, 0.012)        # the sill's drip groove: from the nose, to, and how high it is cut
IRON = (0.011, 0.014)               # the garde-corps' flat bar: across the face, deep


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
        "hardware": Material((0.84, 0.83, 0.78), under=(0.45, 0.25, 0.12), bare=(0.30, 0.17, 0.08), chip=1.4, fixing=True, grain=0.1),
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
    if lod == 0:  # round 2: a drip groove (goutte d'eau) cut under the nose
        nose = -SILL_FRONT
        m.merge(_bx(-sw, sw, 0.0, SILL_H, nose + DRIP[1], FRAME_Z, "stone", 0.012, "top"))
        m.merge(_bx(-sw, sw, 0.0, SILL_H, nose, nose + DRIP[0], "stone", 0.014, "top"))
        m.merge(_bx(-sw, sw, DRIP[2], SILL_H, nose + DRIP[0] - 0.001, nose + DRIP[1] + 0.001, "stone"))
    else:
        m.merge(_bx(-sw, sw, 0.0, SILL_H, -SILL_FRONT, FRAME_Z, "stone", 0.0, "top"))
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
    m.merge(_bx(-fw, fw, SILL_H, SILL_H + 0.045, z0 - 0.02, z1, "joinery", 0.012 if lod == 0 else 0.0, "top"))  # the sill rail (piece d'appui), its top washed
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
    if lod == 0:  # round 2: the drip moulding (jet d'eau) across the bottom rail, sloped to shed water
        m.merge(_bx(g0, x_in + side * 0.004, lo + 0.035, lo + 0.075, z0 - 0.022, z0, "joinery", 0.014, "top"))
        if side < 0:  # the right leaf's battement covers the joint between the two
            m.merge(_bx(-0.022, 0.022, lo + 0.075, hi, z0 - 0.020, z0 - 0.008, "joinery", 0.005, "front"))
        for y in (lo + 0.28, hi - 0.28):  # the hinges (fiches) on the frame side, their knuckles
            m.merge(S.prism((x_out + side * 0.004, y, z0 - 0.004), 0.007, 0.09, 6, tag="hardware"))
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
    if lod == 0:  # round 2: what holds it, on the face that meets the glass when shut (the street's once open)
        hz = z1
        for y in _penture_ys(lo, hi):  # the pentures: flat straps from the hinge in, ending in a spade
            m.merge(_bx(side * (rw + 0.004), side * (rw - 0.36), y - 0.017, y + 0.017, hz, hz + 0.004, "hardware"))
            m.merge(_bx(side * (rw - 0.36), side * (rw - 0.39), y - 0.011, y + 0.011, hz, hz + 0.004, "hardware"))
            for k in (0.08, 0.2, 0.32):  # their nails
                m.merge(S.prism((side * (rw - k), y, hz + 0.004), 0.005, 0.003, 6, tag="hardware", axis=(0, 0, 1)))
        # the catch on the middle rail: a plate, its knob and the bar that drops into the other's keeper
        mx = side * 0.20
        m.merge(_bx(mx - 0.06, mx + 0.06, SHUTTER_MID - 0.014, SHUTTER_MID + 0.014, hz, hz + 0.004, "hardware"))
        m.merge(S.prism((mx, SHUTTER_MID, hz + 0.004), 0.006, 0.012, 6, tag="hardware", axis=(0, 0, 1)))
        m.merge(_bx(mx, side * 0.03, SHUTTER_MID - 0.006, SHUTTER_MID + 0.006, hz + 0.010, hz + 0.018, "hardware"))
        # the bolt (verrou) down the inner stile, into the sill
        bx = side * 0.030
        m.merge(_bx(bx - 0.008, bx + 0.008, lo + 0.04, lo + 0.26, hz, hz + 0.010, "hardware"))
    hinge = (side * rw, lo, -BAND_PROUD)
    return m, hinge


def _penture_ys(lo, hi):
    return (lo + 0.16, (lo + hi) / 2 + 0.05, hi - 0.16)


def _gonds(lod):
    """The hinge pins (gonds) the persiennes hang on, leaded into the rebate's edge: three each side."""
    m = Mesh()
    if lod > 0:
        return m
    rw = REBATE_W / 2
    lo, hi = SILL_H + 0.006, REBATE_TOP - 0.006
    for s in (1, -1):
        for y in _penture_ys(lo, hi):
            m.merge(S.prism((s * rw, y - 0.045, -0.002), 0.010, 0.04, 6, tag="hardware"))  # the knuckle
            m.merge(_bx(s * rw, s * (rw + 0.05), y - 0.05, y - 0.04, -0.006, 0.0, "hardware"))  # its arm into the wall
    return m


def _prof(w, h):
    return [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]


def _spiral(c, r0, r1, a0, turns, z, step=18.0):
    """A flat iron scroll: a spiral round `c` (x, y) from radius r0 at angle a0 (degrees) winding
    `turns` (negative: clockwise) in to r1, at depth z."""
    n = max(4, int(abs(turns) * 360 / step))
    pts = []
    for k in range(n + 1):
        t = k / n
        a = np.radians(a0 + turns * 360 * t)
        r = r0 + (r1 - r0) * t
        pts.append((c[0] + np.cos(a) * r, c[1] + np.sin(a) * r, z))
    return S.sweep(pts, _prof(*IRON), "iron", up=(0, 0, -1))


def _bar(a, b, z, w=None, h=None):
    return S.sweep([(a[0], a[1], z), (b[0], b[1], z)], _prof(w or IRON[0], h or IRON[1]), "iron", up=(0, 0, -1))


def _ellipse(c, rx, ry, z, n=20):
    pts = [(c[0] + np.cos(2 * np.pi * k / n) * rx, c[1] + np.sin(2 * np.pi * k / n) * ry, z) for k in range(n)]
    return S.sweep(pts, _prof(*IRON), "iron", closed=True, up=(0, 0, -1))


def _lattice(x0, x1, y0, y1, z, pitch=0.035):
    """Diagonal bars crossing at 45 degrees inside a rectangle (the treillis of tall_railing)."""
    m = Mesh()
    for sgn in (1, -1):
        cs = [y - sgn * x for x in (x0, x1) for y in (y0, y1)]
        for k in range(int(np.floor(min(cs) / pitch)), int(np.ceil(max(cs) / pitch)) + 1):
            c = k * pitch  # the line y = sgn * x + c
            pts = []
            for x in (x0, x1):
                y = sgn * x + c
                if y0 - 1e-9 <= y <= y1 + 1e-9:
                    pts.append((x, y))
            for y in (y0, y1):
                x = (y - c) * sgn
                if x0 < x < x1:
                    pts.append((x, y))
            pts = sorted(set((round(p[0], 6), round(p[1], 6)) for p in pts))
            if len(pts) >= 2 and np.hypot(pts[-1][0] - pts[0][0], pts[-1][1] - pts[0][1]) > 0.012:
                m.merge(_bar(pts[0], pts[-1], z + 0.002 * sgn, 0.006, 0.010))
    return m


def _garde_corps(lod):
    """The cast-iron guard across the lower part, fixed into the reveal's jambs in front of the frame
    (tall_railing): a moulded handrail, a bottom rail, the panel's frame, and inside it a central
    oval with its rosette, C-scrolls winding out of it each way, lattice panels in the top corners and
    scrolls in the corners. LOD 1 keeps the oval and the big scrolls; LOD 2 the rails and a few bars."""
    m = Mesh()
    ow = OPEN_W / 2
    z = REBATE_D + 0.03
    top, bot = RAIL_TOP - 0.03, SILL_H + 0.06
    c = 0.004 if lod == 0 else 0.0
    m.merge(_bx(-ow, ow, top, RAIL_TOP, z - 0.022, z + 0.022, "iron", c, "top"))  # the handrail
    if lod == 0:  # its moulding: a bead under it
        m.merge(_bx(-ow, ow, top - 0.012, top, z - 0.012, z + 0.012, "iron", 0.003, "front"))
    m.merge(_bx(-ow, ow, bot, bot + 0.022, z - 0.010, z + 0.010, "iron"))  # the bottom rail
    if lod >= 2:
        for k in range(7):
            x = -ow + (k + 1) * OPEN_W / 8
            m.merge(_bx(x - 0.008, x + 0.008, bot, top, z - 0.008, z + 0.008, "iron"))
        return m
    px, py0, py1 = ow - 0.045, bot + 0.022, top - 0.012
    for sx in (1, -1):
        m.merge(_bx(sx * px, sx * (px + 0.016), bot, top, z - 0.009, z + 0.009, "iron"))  # the standards
        m.merge(_bx(sx * ow, sx * (ow - 0.02), bot, top, z - 0.009, z + 0.009, "iron"))  # the end bars in the jambs
    m.merge(_bx(-px, px, py0, py0 + 0.012, z - 0.007, z + 0.007, "iron"))
    m.merge(_bx(-px, px, py1 - 0.012, py1, z - 0.007, z + 0.007, "iron"))
    step = 18.0 if lod == 0 else 45.0
    cy = (py0 + py1) / 2
    h = py1 - py0
    m.merge(_ellipse((0, cy), 0.085, h * 0.40, z, 20 if lod == 0 else 10))  # the central oval
    if lod == 0:  # the inner ring, the rosette and the stems above and below
        m.merge(_ellipse((0, cy), 0.050, h * 0.27, z, 16))
        m.merge(S.prism((0, cy, z - 0.012), 0.024, 0.024, 8, tag="iron", axis=(0, 0, 1)))
        for k in range(6):
            a = np.radians(90 + 60 * k)
            m.merge(S.prism((np.cos(a) * 0.034, cy + np.sin(a) * 0.034, z - 0.008), 0.012, 0.014, 5, turn=a, tag="iron", axis=(0, 0, 1)))
        m.merge(_bar((0, py0 + 0.01), (0, cy - h * 0.40), z))
        m.merge(_bar((0, cy + h * 0.40), (0, py1 - 0.01), z))
    for sx in (1, -1):
        # a big C-scroll leaving the oval's waist, winding in below and outward
        m.merge(_spiral((sx * 0.22, cy - h * 0.06), h * 0.32, h * 0.05, 180 if sx > 0 else 0, -1.15 * sx, z, step))
        # the one above it, winding the other way under the lattice
        m.merge(_spiral((sx * 0.40, cy + h * 0.02), h * 0.22, h * 0.04, 0 if sx > 0 else 180, 1.1 * sx, z, step))
        if lod == 0:
            # the pair under the big scroll, winding up out of the bottom rail (tall_railing's lower half)
            m.merge(_spiral((sx * 0.43, py0 + h * 0.20), h * 0.15, h * 0.03, 270, -1.0 * sx, z))
            m.merge(_spiral((sx * 0.13, py0 + h * 0.16), h * 0.12, h * 0.025, 0 if sx > 0 else 180, 0.9 * sx, z))
            for cyy, a0, tw in ((py1 - 0.06, 90, 1.0), (py0 + 0.06, 270, -1.0)):  # the corners' small scrolls
                m.merge(_spiral((sx * (px - 0.07), cyy), 0.05, 0.010, a0, tw * sx, z))
            lx0, lx1 = sorted((sx * 0.14, sx * (px - 0.13)))  # the lattice in the top corner, framed
            ly0, ly1 = py1 - 0.13, py1 - 0.012
            m.merge(_lattice(lx0, lx1, ly0, ly1, z))
            m.merge(_bar((lx0, ly0), (lx1, ly0), z))
            for x in (lx0, lx1):
                m.merge(_bar((x, ly0), (x, ly1), z))
            # the cast leaf where the scrolls meet the rail
            m.merge(_bx(sx * 0.30 - 0.03, sx * 0.30 + 0.03, py1 - 0.03, py1 - 0.012, z - 0.010, z + 0.010, "iron", 0.004, "front"))
            for y in (top - 0.015, bot + 0.011):  # the fixings: lugs leaded into the jambs
                m.merge(_bx(sx * ow, sx * (ow + 0.04), y - 0.01, y + 0.01, z - 0.006, z + 0.006, "iron"))
    return m


def hole():
    """The rectangle the house cuts out of its wall for this: (x half-width, bottom, top)."""
    return REBATE_W / 2 + BAND, 0.0, REBATE_TOP + BAND


def window_french(lod):
    body = _surround(lod)
    body.merge(_frame(lod))
    body.merge(_garde_corps(lod))
    body.merge(_gonds(lod))
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


# --- window_ribbon ---------------------------------------------------------------------------------
# Measurements (card `window_ribbon.md`): a 2.40 m structural bay; sill to head 1.45 m.
RB_W = 2.40            # one bay, post centre to post centre
RB_SILL = 0.06         # the precast sill's top
RB_HEAD = 1.45         # the head (the slab's soffit above)
RB_SILL_FRONT = 0.05   # the sill's nose in front of the face
RB_FRAME_Z = 0.05      # the aluminium frame's front face, a little back in the reveal
RB_FRAME_D = 0.07
RB_POST = 0.05         # a mullion (each end is half of one)
RB_TRANSOM = 1.10      # the transom's middle
RB_ROOM = 0.50


def _ribbon_body(lod):
    m = Mesh()
    hw = RB_W / 2
    c = 0.004 if lod == 0 else 0.0
    # the sill: a precast slab with a washed top, a drip under the nose
    if lod == 0:
        m.merge(_bx(-hw, hw, 0.0, RB_SILL, -RB_SILL_FRONT + 0.03, RB_FRAME_Z + 0.01, "concrete", 0.01, "top"))
        m.merge(_bx(-hw, hw, 0.015, RB_SILL, -RB_SILL_FRONT, -RB_SILL_FRONT + 0.02, "concrete", 0.008, "top"))
    else:
        m.merge(_bx(-hw, hw, 0.0, RB_SILL, -RB_SILL_FRONT, RB_FRAME_Z + 0.01, "concrete"))
    # the head: the slab edge's soffit from the face back to the frame
    m.merge(_bx(-hw, hw, RB_HEAD, RB_HEAD + 0.04, 0.0, RB_FRAME_Z + 0.01, "concrete", c, "front"))
    z0, z1 = RB_FRAME_Z, RB_FRAME_Z + RB_FRAME_D
    p = RB_POST / 2
    # the frame: head, sill rail, the two half posts at the ends and the middle mullion
    m.merge(_bx(-hw, hw, RB_HEAD - 0.045, RB_HEAD, z0, z1, "alu", c))
    m.merge(_bx(-hw, hw, RB_SILL, RB_SILL + 0.05, z0 - 0.01, z1, "alu", c, "top"))
    for x0, x1 in ((-hw, -hw + p), (hw - p, hw), (-p, p)):
        m.merge(_bx(x0, x1, RB_SILL, RB_HEAD, z0 - 0.005, z1, "alu", c))
    # the transom right across
    m.merge(_bx(-hw, hw, RB_TRANSOM - 0.025, RB_TRANSOM + 0.025, z0 - 0.005, z1, "alu", c))
    # the fixed pane on the viewer's left (+X), set in the frame's outer track
    gz = z0 + 0.018
    m.merge(_bx(p, hw - p, RB_SILL + 0.05, RB_TRANSOM - 0.025, gz - 0.003, gz + 0.003, "glass"))
    if lod == 0:  # its glazing bead: a thin rim round the pane
        bx0, bx1, by0, by1 = p, hw - p, RB_SILL + 0.05, RB_TRANSOM - 0.025
        for a, b, c0, c1 in ((bx0, bx1, by0, by0 + 0.02), (bx0, bx1, by1 - 0.02, by1), (bx0, bx0 + 0.02, by0, by1), (bx1 - 0.02, bx1, by0, by1)):
            m.merge(_bx(a, b, c0, c1, gz - 0.009, gz - 0.003, "alu"))
    if lod == 0:  # weep slots in the sill rail, the slab's drip edge, a gap where the sash slides
        for x in (-hw * 0.7, -hw * 0.25, hw * 0.25, hw * 0.7):
            m.merge(_bx(x - 0.02, x + 0.02, RB_SILL + 0.012, RB_SILL + 0.018, z0 - 0.0105, z0 - 0.0095, "dark"))
        m.merge(_bx(-hw, hw, RB_HEAD - 0.01, RB_HEAD, -0.012, 0.0, "concrete"))
    # the room
    back = z1 + RB_ROOM
    m.merge(_bx(-hw + p, hw - p, RB_SILL, RB_HEAD - 0.045, back, back + 0.02, "room"))
    m.merge(_bx(-hw + p, hw - p, RB_SILL - 0.02, RB_SILL, z1, back, "room"))
    m.merge(_bx(-hw + p, hw - p, RB_HEAD - 0.065, RB_HEAD - 0.045, z1, back, "room"))
    if lod == 0:  # round 1: the end of a venetian blind showing, the ceiling's light
        m.merge(_bx(-hw + p, hw - p, RB_HEAD - 0.12, RB_HEAD - 0.065, z1 + 0.04, z1 + 0.07, "blind"))
    return m


def _ribbon_sash(lod):
    """The sliding sash: in the inner track on the viewer's right (-X), slides left behind the fixed pane."""
    m = Mesh()
    hw, p = RB_W / 2, RB_POST / 2
    z0 = RB_FRAME_Z + 0.038
    z1 = z0 + 0.026
    c = 0.003 if lod == 0 else 0.0
    x0, x1 = -hw + p - 0.005, -p + 0.02  # overlaps the mullion so the meeting is closed
    y0, y1 = RB_SILL + 0.05, RB_TRANSOM - 0.025
    st = 0.045
    if lod == 2:  # far off: the glass alone, the frame's look baked round it
        m.merge(_bx(x0, x1, y0, y1, z0, z1, "glass"))
        return m, (x0, y0, z0)
    m.merge(_bx(x0, x0 + st, y0, y1, z0, z1, "alu", c))
    m.merge(_bx(x1 - st, x1, y0, y1, z0, z1, "alu", c))
    m.merge(_bx(x0, x1, y0, y0 + st, z0, z1, "alu", c))
    m.merge(_bx(x0, x1, y1 - st, y1, z0, z1, "alu", c))
    gz = (z0 + z1) / 2
    m.merge(_bx(x0 + st, x1 - st, y0 + st, y1 - st, gz - 0.003, gz + 0.003, "glass"))
    if lod == 0:  # the pull: a recessed grip in the meeting stile, the lock's lever
        m.merge(_bx(x1 - st * 0.7, x1 - st * 0.3, (y0 + y1) / 2 - 0.07, (y0 + y1) / 2 + 0.07, z0 - 0.004, z0, "dark"))
        m.merge(_bx(x1 - st * 0.75, x1 - st * 0.25, (y0 + y1) / 2 + 0.10, (y0 + y1) / 2 + 0.13, z1, z1 + 0.012, "alu"))
    return m, (x0, y0, z0)


def _ribbon_vent(side, lod):
    """A top-hung vent over one half (side +1 the viewer's left), hinged at the head, out at the foot."""
    m = Mesh()
    hw, p = RB_W / 2, RB_POST / 2
    xa, xb = sorted((side * p, side * (hw - p)))
    y0, y1 = RB_TRANSOM + 0.025, RB_HEAD - 0.045
    z0, z1 = RB_FRAME_Z + 0.012, RB_FRAME_Z + 0.05
    st = 0.04
    c = 0.003 if lod == 0 else 0.0
    if lod == 2:
        m.merge(_bx(xa, xb, y0, y1, z0, z1, "glass"))
        return m, (0.0, y1, z0)
    m.merge(_bx(xa, xa + st, y0, y1, z0, z1, "alu", c))
    m.merge(_bx(xb - st, xb, y0, y1, z0, z1, "alu", c))
    m.merge(_bx(xa, xb, y0, y0 + st, z0, z1, "alu", c))
    m.merge(_bx(xa, xb, y1 - st, y1, z0, z1, "alu", c))
    gz = (z0 + z1) / 2
    m.merge(_bx(xa + st, xb - st, y0 + st, y1 - st, gz - 0.003, gz + 0.003, "glass"))
    if lod == 0:  # the stay arm on the inside
        m.merge(_bx((xa + xb) / 2 - 0.008, (xa + xb) / 2 + 0.008, y0 + 0.02, y0 + 0.2, z1, z1 + 0.01, "alu"))
    return m, (0.0, y1, z0)


def window_ribbon(lod):
    parts = {"body": Part(_ribbon_body(lod))}
    sash, piv = _ribbon_sash(lod)
    parts["sash"] = Part(sash, piv, {"move": [RB_W / 2 - RB_POST - 0.06, 0.0, 0.0]})  # behind the fixed pane
    for side, nm in ((1, "vent_l"), (-1, "vent_r")):
        mesh, hinge = _ribbon_vent(side, lod)
        parts[nm] = Part(mesh, hinge, {"rotate": [[1, 0, 0], 28.0]})  # the foot swings out
    if lod > 0:
        merged = Mesh()
        for q in parts.values():
            merged.merge(q.mesh)
        return {"body": Part(merged)}
    return parts


# --- window_barracks -------------------------------------------------------------------------------
# Measurements (card `window_barracks.md`): a 1.10 x 2.30 opening in a 0.35 m wall.
BK_W = 1.10            # the opening
BK_TOP = 2.38          # the opening's head above the sill's bottom
BK_SILL = 0.08         # the sill's top
BK_SILL_FRONT = 0.06
BK_BAND = 0.14         # the painted band round the opening, proud of the wall
BK_BAND_PROUD = 0.015
BK_WALL = 0.35         # the reveal's depth: the frame stands at the inner face
BK_FRAME_Z = 0.24      # the frame's front face
BK_FRAME_D = 0.07
BK_TRANSOM = 1.86      # the transom's middle: the fanlight above it
BK_ROOM = 0.60
BK_PANES = 3


def _barracks_body(lod):
    m = Mesh()
    hw = BK_W / 2
    c = 0.005 if lod == 0 else 0.0
    # the band: two jambs and a head round the opening, a little proud of the wall
    for s in (1, -1):
        m.merge(_bx(s * hw, s * (hw + BK_BAND), BK_SILL, BK_TOP + BK_BAND, -BK_BAND_PROUD, 0.0, "band", c))
    m.merge(_bx(-hw, hw, BK_TOP, BK_TOP + BK_BAND, -BK_BAND_PROUD, 0.0, "band", c))
    # the reveal back to the frame
    for s in (1, -1):
        m.merge(_bx(s * (hw - 0.01), s * hw, BK_SILL, BK_TOP, 0.0, BK_FRAME_Z, "plaster"))
    m.merge(_bx(-hw, hw, BK_TOP - 0.01, BK_TOP, 0.0, BK_FRAME_Z, "plaster"))
    # the sill: concrete, washed, its nose with a drip
    sw = hw + BK_BAND + 0.03
    if lod == 0:
        m.merge(_bx(-sw, sw, 0.0, BK_SILL, -BK_SILL_FRONT + 0.03, BK_FRAME_Z, "concrete", 0.012, "top"))
        m.merge(_bx(-sw, sw, 0.02, BK_SILL, -BK_SILL_FRONT, -BK_SILL_FRONT + 0.022, "concrete", 0.01, "top"))
    else:
        m.merge(_bx(-sw, sw, 0.0, BK_SILL, -BK_SILL_FRONT, BK_FRAME_Z, "concrete"))
    # the frame: jambs, head, sill rail, the transom
    z0, z1 = BK_FRAME_Z, BK_FRAME_Z + BK_FRAME_D
    fw = hw - 0.01
    for s in (1, -1):
        m.merge(_bx(s * (fw - 0.05), s * fw, BK_SILL, BK_TOP - 0.01, z0, z1, "frame", c))
    m.merge(_bx(-fw, fw, BK_TOP - 0.06, BK_TOP - 0.01, z0, z1, "frame", c))
    m.merge(_bx(-fw, fw, BK_SILL, BK_SILL + 0.05, z0 - 0.025, z1, "frame", 0.012 if lod == 0 else 0.0, "top"))
    m.merge(_bx(-fw, fw, BK_TRANSOM - 0.035, BK_TRANSOM + 0.035, z0 - 0.015, z1, "frame", c, "top"))
    # the room
    back = z1 + BK_ROOM
    fi = fw - 0.05
    m.merge(_bx(-fi, fi, BK_SILL, BK_TOP - 0.06, back, back + 0.02, "room"))
    for s in (1, -1):
        m.merge(_bx(s * fi, s * (fi + 0.02), BK_SILL, BK_TOP - 0.06, z1, back, "room"))
    m.merge(_bx(-fi, fi, BK_TOP - 0.08, BK_TOP - 0.06, z1, back, "room"))
    m.merge(_bx(-fi, fi, BK_SILL - 0.02, BK_SILL, z1, back, "room"))
    if lod == 0:  # round 1: the fixings of the shutters that were taken off, a conduit up the reveal
        for s in (1, -1):
            for y in (0.5, BK_TOP - 0.4):
                m.merge(S.prism((s * (hw + BK_BAND - 0.03), y, -BK_BAND_PROUD - 0.012), 0.008, 0.024, 6, tag="iron", axis=(0, 0, 1)))
    return m


def _barracks_leaf(side, lod):
    """A casement leaf, hinged on the frame's jamb (side +1 the viewer's left), opening into the room."""
    fw = BK_W / 2 - 0.06
    x_out, x_in = side * fw, side * 0.002
    lo, hi = BK_SILL + 0.05, BK_TRANSOM - 0.035
    z0, z1 = BK_FRAME_Z + 0.01, BK_FRAME_Z + 0.055
    c = 0.004 if lod == 0 else 0.0
    m = Mesh()
    st, top, bot, meet, bar = 0.055, 0.06, 0.12, 0.06, 0.03
    if lod == 2:  # far off: the leaf as one board of glass, its bars baked
        m.merge(_bx(x_out, x_in, lo, hi, z0, z1, "glass"))
        return m, (x_out, lo, z1)
    m.merge(_bx(x_out, x_out - side * st, lo, hi, z0, z1, "frame", c))
    m.merge(_bx(x_in, x_in + side * meet, lo, hi, z0 - 0.006, z1, "frame", c))
    m.merge(_bx(x_out, x_in, hi - top, hi, z0, z1, "frame", c))
    m.merge(_bx(x_out, x_in, lo, lo + bot, z0, z1, "frame", c))
    g0, g1 = x_out - side * st, x_in + side * meet
    gz = (z0 + z1) / 2
    y_lo, y_hi = lo + bot, hi - top
    pane = (y_hi - y_lo - (BK_PANES - 1) * bar) / BK_PANES
    for k in range(BK_PANES):
        y0 = y_lo + k * (pane + bar)
        m.merge(_bx(g0, g1, y0, y0 + pane, gz - 0.002, gz + 0.002, "glass"))
        if k and lod < 2:
            m.merge(_bx(g0, g1, y0 - bar, y0, z0 + 0.008, z1 - 0.008, "frame", c))
    if lod == 0:  # the drip moulding on the bottom rail, the hinges, the turn handle on the right leaf
        m.merge(_bx(g0, x_in + side * 0.004, lo + 0.03, lo + 0.07, z0 - 0.02, z0, "frame", 0.012, "top"))
        for y in (lo + 0.2, hi - 0.2):
            m.merge(S.prism((x_out + side * 0.004, y, z0 - 0.004), 0.007, 0.08, 6, tag="iron"))
        if side < 0:
            m.merge(_bx(-0.018, 0.018, lo + bot, hi - top, z0 - 0.016, z0 - 0.006, "frame", 0.004, "front"))
    return m, (x_out, lo, z1)


def _barracks_fanlight(lod):
    """The fanlight over the transom: one sash of two panes, hinged at its foot, tilting in at the top."""
    fw = BK_W / 2 - 0.06
    lo, hi = BK_TRANSOM + 0.035, BK_TOP - 0.06
    z0, z1 = BK_FRAME_Z + 0.012, BK_FRAME_Z + 0.05
    c = 0.004 if lod == 0 else 0.0
    m = Mesh()
    st = 0.045
    if lod == 2:
        m.merge(_bx(-fw, fw, lo, hi, z0, z1, "glass"))
        return m, (0.0, lo, z1)
    m.merge(_bx(-fw, -fw + st, lo, hi, z0, z1, "frame", c))
    m.merge(_bx(fw - st, fw, lo, hi, z0, z1, "frame", c))
    m.merge(_bx(-fw, fw, lo, lo + st, z0, z1, "frame", c))
    m.merge(_bx(-fw, fw, hi - st, hi, z0, z1, "frame", c))
    m.merge(_bx(-0.015, 0.015, lo + st, hi - st, z0 + 0.006, z1 - 0.006, "frame", c))
    gz = (z0 + z1) / 2
    m.merge(_bx(-fw + st, fw - st, lo + st, hi - st, gz - 0.002, gz + 0.002, "glass"))
    return m, (0.0, lo, z1)


def window_barracks(lod):
    parts = {"body": Part(_barracks_body(lod))}
    for side, nm in ((1, "leaf_l"), (-1, "leaf_r")):
        mesh, hinge = _barracks_leaf(side, lod)
        parts[nm] = Part(mesh, hinge, {"rotate": [[0, 1, 0], 100.0 * side]})
    fan, hinge = _barracks_fanlight(lod)
    parts["fanlight"] = Part(fan, hinge, {"rotate": [[1, 0, 0], 35.0]})  # the top tips into the room
    if lod > 0:
        merged = Mesh()
        for q in parts.values():
            merged.merge(q.mesh)
        return {"body": Part(merged)}
    return parts


def ribbon_materials():
    out = materials()
    out.update({
        "concrete": Material((0.66, 0.65, 0.62), kind="concrete", chip=0.0, rusts=False, grain=0.08),
        "alu": Material((0.62, 0.62, 0.60), under=(0.55, 0.55, 0.54), bare=(0.58, 0.58, 0.57), chip=0.0, rusts=False, grain=0.03),
        "dark": Material((0.05, 0.05, 0.05), chip=0.0, rusts=False, grain=0.02, fades=False),
        "blind": Material((0.78, 0.76, 0.70), kind="plaster", chip=0.0, rusts=False, grain=0.04),
    })
    return out


def barracks_materials():
    out = materials()
    out.update({
        "concrete": Material((0.70, 0.69, 0.66), kind="concrete", chip=0.0, rusts=False, grain=0.08),
        "band": Material((0.90, 0.89, 0.85), kind="plaster", chip=0.0, rusts=False, grain=0.05),
        "frame": Material((0.17, 0.33, 0.22), under=(0.80, 0.80, 0.76), bare=(0.48, 0.42, 0.34), kind="wood", rusts=False, chip=0.7),
    })
    out["plaster"] = Material((0.88, 0.87, 0.83), kind="plaster", chip=0.0, rusts=False, grain=0.05)
    return out


ELEMENTS = {
    "window_ribbon": {
        "build": window_ribbon,
        "materials": ribbon_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.003,
    },
    "window_barracks": {
        "build": window_barracks,
        "materials": barracks_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
    },
    "window_french": {
        "build": window_french,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
    },
}
