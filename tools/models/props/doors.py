"""Doors and frames (S191). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

door_wood: the panelled wooden door of a flat or an office: the architrave round the opening, the
jamb lining in the reveal, the threshold; the leaf (part `leaf`) of stiles and rails round four
raised panels on both faces, three hinges, lever handles on their roses, the keyhole.
door_glass: the aluminium-framed glass door of a shop or a hall: narrow stiles, a deep bottom rail,
the glass, a push bar across the outside, a pull handle inside, the closer over it (part `leaf`).
door_fire: the steel fire door: a pressed steel frame, a flush leaf (part `leaf`) with its wired-glass
vision panel, the panic bar and the kick plate inside, the closer, the hinges.
door_plank: the corridor's service door (`door.gd`): a heavy timber frame, a ledged and braced leaf
of vertical planks 2.0 x 2.6 (part `leaf`), strap hinges, a thumb latch and a hasp.
roller_shutter: the steel roller shutter (rideau métallique) of a shop or a service bay, on the
wall's face: a guide channel down each side, the box (coffre) over the opening that the curtain
rolls into, the curtain (part `curtain`, gathered up into the box when open) of interlocking
galvanised slats with a band of perforated ones, the bottom bar with its lifting handles and the
lock, the key switch of the motor on the wall.

Wall face z = 0, the house +Z, the floor y = 0; the viewer stands at -Z, so their left is +X. Every
leaf hangs on the viewer's left jamb and opens inward (+Z).
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

WOOD = dict(w=0.90, h=2.10, reveal=0.16, t=0.042)
GLASS = dict(w=1.00, h=2.20, reveal=0.12, t=0.05)
FIRE = dict(w=0.95, h=2.10, reveal=0.15, t=0.054)
PLANK = dict(w=2.00, h=2.60, reveal=0.20, t=0.06)


def materials():
    return {
        "paint": Material((0.22, 0.30, 0.26), under=(0.75, 0.72, 0.65), bare=(0.48, 0.38, 0.26), kind="wood", chip=0.6, grain=0.06, rusts=False),
        "trim": Material((0.86, 0.84, 0.78), under=(0.70, 0.66, 0.58), bare=(0.50, 0.40, 0.28), kind="wood", chip=0.5, grain=0.05, rusts=False),
        "plank": Material((0.42, 0.31, 0.20), under=(0.40, 0.30, 0.20), bare=(0.50, 0.40, 0.28), kind="wood", chip=0.0, rusts=False, grain=0.22,
                          palette=[(0.42, 0.31, 0.20), (0.38, 0.28, 0.18), (0.46, 0.34, 0.22), (0.40, 0.30, 0.19)], vary=0.05),
        "timber": Material((0.34, 0.26, 0.18), kind="wood", chip=0.0, rusts=False, grain=0.2),
        "iron": Material((0.12, 0.12, 0.12), under=(0.40, 0.24, 0.14), bare=(0.35, 0.20, 0.10), chip=0.6, grain=0.08, fixing=True),
        "brass": Material((0.68, 0.56, 0.30), under=(0.5, 0.4, 0.2), bare=(0.5, 0.4, 0.2), chip=0.0, rusts=False, grain=0.03, fades=False),
        "alu": Material((0.72, 0.73, 0.74), under=(0.65, 0.66, 0.67), bare=(0.68, 0.69, 0.70), chip=0.0, rusts=False, grain=0.03),
        "glass": Material((0.30, 0.34, 0.36), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "steel": Material((0.56, 0.55, 0.52), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.05),
        "red": Material((0.55, 0.12, 0.10), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.05),
        "dark": Material((0.06, 0.06, 0.06), chip=0.0, rusts=False, grain=0.02, fades=False),
        "rubber": Material((0.10, 0.10, 0.10), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "stone": Material((0.62, 0.60, 0.56), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "box": Material((0.50, 0.52, 0.53), under=(0.62, 0.63, 0.64), bare=(0.40, 0.30, 0.22), chip=0.5, grain=0.05),
        "bolt": Material((0.45, 0.45, 0.44), chip=0.0, grain=0.04, fixing=True),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


def _lining(w, h, rv, tag, lod, arch=True):
    """The architrave on the wall's face, the lining round the reveal, the threshold."""
    m = Mesh()
    mould = [(0.0, 0.0), (0.07, 0.0), (0.07, -0.012), (0.04, -0.022), (0.0, -0.025)] if lod == 0 else [(0.0, 0.0), (0.07, 0.0), (0.07, -0.02), (0.0, -0.02)]
    if lod < 2:
        m.merge(S.opening_frame(w, h, mould, origin=(0, 0, 0), tag=tag, bottom=False))
    for s in (1, -1):
        m.merge(S.box((s * (w / 2 + 0.01), h / 2, rv / 2), (0.01, h / 2, rv / 2), tag))
    m.merge(S.box((0, h + 0.01, rv / 2), (w / 2 + 0.02, 0.01, rv / 2), tag))
    m.merge(_cb((0, 0.01, rv / 2 - 0.02), (w / 2, 0.01, rv / 2 + 0.03), 0.004, "stone", lod, edges="top"))
    return m


def _lever(x, y, z, side, lod):
    """A lever handle on its rose, pointing away from the hinge; side -1 the outside, +1 inside."""
    m = Mesh()
    m.merge(S.along(S.lathe([(0.0, 0.026), (0.008, 0.026), (0.010, 0.02), (0.010, 0.0)], [10, 6, 4][lod], tag="brass"), (0, 0, side), (x, y, z)))
    if lod < 2:
        m.merge(S.sweep([(x, y, z + side * 0.008), (x, y, z + side * 0.055), (x - 0.12, y - 0.005, z + side * 0.06)], S.circle(0.009, [6, 4][lod]), "brass"))
        m.merge(S.along(S.lathe([(0.0, 0.018), (0.006, 0.018), (0.006, 0.0)], 8, tag="brass"), (0, 0, side), (x, y - 0.12, z)))
        m.merge(S.box((x, y - 0.12, z + side * 0.0065), (0.003, 0.008, 0.001), "dark"))
    return m


def _hinges(x, z, ys, lod, tag="brass", r=0.009):
    m = Mesh()
    for y in ys:
        m.merge(S.lathe([(y - 0.05, r), (y + 0.05, r), (y + 0.06, r * 0.6), (y + 0.06, 0.0)], [8, 6, 4][lod], tag=tag).transformed(np.eye(3), (x, 0, z)))
    return m


# --- door_wood --------------------------------------------------------------------------------------------
def door_wood(lod):
    w, h, rv, t = WOOD["w"], WOOD["h"], WOOD["reveal"], WOOD["t"]
    m = _lining(w, h, rv, "trim", lod)
    lw, lh = w - 0.006, h - 0.008
    z0 = 0.05                                                   # the leaf's outside face, set in the reveal
    leaf = Mesh()
    leaf.merge(S.box((0, 0.012 + lh / 2, z0 + t / 2), (lw / 2, lh / 2, t / 2), "paint"))
    if lod < 2:
        # four raised panels on each face: two tall above the lock rail, two short below
        cells = [(-0.19, 1.45, 0.24, 0.95), (0.19, 1.45, 0.24, 0.95), (-0.19, 0.48, 0.24, 0.62), (0.19, 0.48, 0.24, 0.62)]
        for cx, cy, pw, ph in cells:
            for face, sgn in ((z0, -1), (z0 + t, 1)):
                if lod == 1 and sgn > 0:
                    continue
                p = S.panel(pw, ph, t=0.012, border=0.0, kind="raised", depth=0.006, bevel=0.035, tag="paint",
                            origin=(cx, cy, face), right=(1, 0, 0) if sgn < 0 else (-1, 0, 0), up=(0, 1, 0))
                leaf.merge(p)
    leaf.merge(_lever(-lw / 2 + 0.07, 1.02, z0, -1, lod))
    if lod == 0:
        leaf.merge(_lever(-lw / 2 + 0.07, 1.02, z0 + t, 1, lod))
    leaf.merge(_hinges(lw / 2, z0 + t + 0.004, (0.25, 1.05, 1.85), lod))
    return {"body": Part(m), "leaf": Part(leaf, (lw / 2, 0.0, z0 + t), {"rotate": [[0, 1, 0], 95.0]})}


# --- door_glass -------------------------------------------------------------------------------------------
def door_glass(lod):
    w, h, rv, t = GLASS["w"], GLASS["h"], GLASS["reveal"], GLASS["t"]
    m = Mesh()
    # the aluminium frame in the opening
    for s in (1, -1):
        m.merge(S.box((s * (w / 2 + 0.02), h / 2, rv / 2), (0.04, h / 2, rv / 2), "alu"))
    m.merge(S.box((0, h + 0.03, rv / 2), (w / 2 + 0.06, 0.04, rv / 2), "alu"))
    m.merge(_cb((0, 0.008, rv / 2), (w / 2, 0.008, rv / 2 + 0.03), 0.003, "alu", lod, edges="top"))
    z0 = 0.035
    lw, lh = w - 0.01, h - 0.01
    leaf = Mesh()
    for s in (1, -1):  # stiles, top rail, the deep bottom rail
        leaf.merge(_cb((s * (lw / 2 - 0.05), 0.012 + lh / 2, z0 + t / 2), (0.05, lh / 2, t / 2), 0.004, "alu", lod))
    leaf.merge(_cb((0, lh - 0.04, z0 + t / 2), (lw / 2 - 0.1, 0.05, t / 2), 0.004, "alu", lod))
    leaf.merge(_cb((0, 0.14, z0 + t / 2), (lw / 2 - 0.1, 0.13, t / 2), 0.004, "alu", lod))
    leaf.merge(S.box((0, (0.27 + lh - 0.09) / 2, z0 + t / 2), (lw / 2 - 0.1, (lh - 0.09 - 0.27) / 2, 0.004), "glass"))
    if lod < 2:
        # the push bar outside, standing off on two arms
        y = 1.05
        leaf.merge(S.sweep([(-lw / 2 + 0.08, y, z0), (-lw / 2 + 0.08, y, z0 - 0.07), (lw / 2 - 0.08, y, z0 - 0.07), (lw / 2 - 0.08, y, z0)], S.circle(0.016, [8, 5][lod]), "alu"))
        # the pull handle inside, the closer at the head
        leaf.merge(S.sweep([(-lw / 2 + 0.09, 0.80, z0 + t), (-lw / 2 + 0.09, 0.80, z0 + t + 0.06), (-lw / 2 + 0.09, 1.30, z0 + t + 0.06), (-lw / 2 + 0.09, 1.30, z0 + t)], S.circle(0.014, [8, 5][lod]), "alu"))
        if lod == 0:  # the lock cylinder in the bottom rail
            leaf.merge(S.along(S.lathe([(0.0, 0.014), (0.005, 0.014), (0.005, 0.0)], 8, tag="brass"), (0, 0, -1), (-lw / 2 + 0.05, 0.20, z0)))
    m.merge(_cb((w / 2 - 0.25, h - 0.06, rv + 0.03), (0.15, 0.03, 0.03), 0.006, "alu", lod))
    if lod < 2:
        m.merge(S.sweep([(w / 2 - 0.12, h - 0.06, rv + 0.06), (0.0, h - 0.08, rv + 0.12), (-0.05, h - 0.09, z0 + t + 0.01)], S.circle(0.008, 4), "alu"))
    leaf.merge(_hinges(lw / 2, z0 + t + 0.004, (0.20, h - 0.25), lod, tag="alu"))
    return {"body": Part(m), "leaf": Part(leaf, (lw / 2, 0.0, z0 + t), {"rotate": [[0, 1, 0], 95.0]})}


# --- door_fire --------------------------------------------------------------------------------------------
def door_fire(lod):
    w, h, rv, t = FIRE["w"], FIRE["h"], FIRE["reveal"], FIRE["t"]
    m = Mesh()
    # the pressed steel frame: a profile wrapped round the opening, its stop proud inside the reveal
    prof = [(0.0, 0.0), (0.05, 0.0), (0.05, -0.012), (0.0, -0.012)]
    for s in (1, -1):
        m.merge(S.box((s * (w / 2 + 0.025), h / 2, rv / 2), (0.025, h / 2, rv / 2 + 0.012), "steel"))
        m.merge(S.box((s * (w / 2 - 0.008), h / 2, rv * 0.75), (0.012, h / 2, 0.02), "steel"))
    m.merge(S.box((0, h + 0.025, rv / 2), (w / 2 + 0.05, 0.025, rv / 2 + 0.012), "steel"))
    m.merge(S.box((0, h - 0.012, rv * 0.75), (w / 2, 0.012, 0.02), "steel"))
    z0 = rv * 0.75 - 0.02 - t
    lw, lh = w - 0.01, h - 0.012
    leaf = Mesh()
    leaf.merge(_cb((0, 0.008 + lh / 2, z0 + t / 2), (lw / 2, lh / 2, t / 2), 0.004, "red", lod))
    # the vision panel: wired glass in a steel bead
    vx, vy, vw, vh = 0.0, 1.45, 0.16, 0.60
    leaf.merge(S.box((vx, vy, z0 - 0.001), (vw / 2, vh / 2, 0.002), "glass"))
    leaf.merge(S.box((vx, vy, z0 + t + 0.001), (vw / 2, vh / 2, 0.002), "glass"))
    if lod < 2:
        for s in (-1, 1):
            for zz in (z0 - 0.004, z0 + t + 0.004):
                leaf.merge(S.box((vx + s * (vw / 2 + 0.01), vy, zz), (0.01, vh / 2 + 0.02, 0.004), "steel"))
                leaf.merge(S.box((vx, vy + s * (vh / 2 + 0.01), zz), (vw / 2 + 0.02, 0.01, 0.004), "steel"))
        # the panic bar and the kick plate inside, a pull handle outside
        zi = z0 + t
        leaf.merge(S.box((0, 0.98, zi + 0.06), (lw / 2 - 0.10, 0.025, 0.025), "steel"))
        for x in (-lw / 2 + 0.10, lw / 2 - 0.10):
            leaf.merge(_cb((x, 0.98, zi + 0.035), (0.04, 0.05, 0.035), 0.008, "steel", lod))
        leaf.merge(S.box((0, 0.15, zi + 0.001), (lw / 2 - 0.02, 0.15, 0.001), "steel"))
        leaf.merge(S.sweep([(-lw / 2 + 0.08, 0.85, z0), (-lw / 2 + 0.08, 0.85, z0 - 0.05), (-lw / 2 + 0.08, 1.15, z0 - 0.05), (-lw / 2 + 0.08, 1.15, z0)], S.circle(0.012, [6, 4][lod]), "steel"))
    leaf.merge(_hinges(lw / 2, z0 + t + 0.004, (0.25, 1.05, 1.85), lod, tag="steel", r=0.011))
    # the closer on the frame's head inside, its arm to the leaf
    m.merge(_cb((w / 2 - 0.30, h - 0.07, rv + 0.03), (0.16, 0.035, 0.03), 0.006, "steel", lod))
    if lod < 2:
        m.merge(S.sweep([(w / 2 - 0.16, h - 0.07, rv + 0.06), (0.05, h - 0.09, rv + 0.10), (-0.02, h - 0.10, z0 + t + 0.01)], S.circle(0.008, 4), "steel"))
    return {"body": Part(m), "leaf": Part(leaf, (lw / 2, 0.0, z0 + t), {"rotate": [[0, 1, 0], 95.0]})}


def _paint_fire(P, N, tag, tags, state, col):
    """The wire in the vision panel's glass: a 12 mm square mesh."""
    sel = tag == tags.index("glass")
    grid = (np.mod(P[:, 0] + 1.0, 0.0125) < 0.0012) | (np.mod(P[:, 1], 0.0125) < 0.0012)
    return np.where((sel & grid)[:, None], np.array([0.55, 0.56, 0.56], np.float32), col)


# --- door_plank -------------------------------------------------------------------------------------------
def door_plank(lod):
    w, h, rv, t = PLANK["w"], PLANK["h"], PLANK["reveal"], PLANK["t"]
    m = Mesh()
    # the heavy timber frame: posts and a head, chamfered, a stone sill
    for s in (1, -1):
        m.merge(_cb((s * (w / 2 + 0.07), h / 2 + 0.05, rv / 2), (0.07, h / 2 + 0.05, rv / 2), 0.012, "timber", lod))
    m.merge(_cb((0, h + 0.13, rv / 2), (w / 2 + 0.16, 0.08, rv / 2 + 0.01), 0.012, "timber", lod))
    m.merge(_cb((0, 0.02, rv / 2), (w / 2 + 0.14, 0.02, rv / 2 + 0.06), 0.006, "stone", lod, edges="top"))
    z0 = 0.06
    leaf = Mesh()
    n = [11, 6, 1][lod]
    lw, lh = w - 0.01, h - 0.02
    if lod < 2:
        for i in range(n):  # the vertical planks, a groove between each
            x = -lw / 2 + (i + 0.5) * lw / n
            leaf.merge(_cb((x, 0.04 + lh / 2, z0 + t * 0.3), (lw / n / 2 - 0.003, lh / 2, t * 0.3), 0.003, "plank", lod).set_unit(i % 4 + 1))
        # the ledges and the braces on the inside face
        for y in (0.35, lh / 2, lh - 0.35):
            leaf.merge(_cb((0, y, z0 + t * 0.6 + 0.02), (lw / 2 - 0.06, 0.08, 0.02), 0.004, "plank", lod))
        for ya, yb in ((0.35, lh / 2), (lh / 2, lh - 0.35)):
            leaf.merge(S.sweep([(lw / 2 - 0.15, ya + 0.06, z0 + t * 0.6 + 0.02), (-lw / 2 + 0.15, yb - 0.06, z0 + t * 0.6 + 0.02)],
                               [(-0.07, -0.02), (0.07, -0.02), (0.07, 0.02), (-0.07, 0.02)], "plank", up=(0, 0, 1)))
    else:
        leaf.merge(S.box((0, 0.04 + lh / 2, z0 + t / 2), (lw / 2, lh / 2, t / 2), "plank"))
    # strap hinges across the outside from the hinge side, the thumb latch and a hasp with its padlock
    for y in (0.35, lh - 0.35):
        leaf.merge(S.box((lw / 2 - 0.40, y, z0 - 0.004), (0.40, 0.025, 0.004), "iron"))
        if lod < 2:
            for k in range(4):
                leaf.merge(S.prism((lw / 2 - 0.10 - k * 0.22, y, z0 - 0.009), 0.008, 0.004, 6, axis=(0, 0, -1), tag="iron"))
    if lod < 2:
        leaf.merge(S.sweep([(-lw / 2 + 0.15, 1.05, z0), (-lw / 2 + 0.15, 1.05, z0 - 0.05), (-lw / 2 + 0.15, 1.25, z0 - 0.05), (-lw / 2 + 0.15, 1.25, z0)], S.circle(0.01, [6, 4][lod]), "iron"))
        leaf.merge(S.box((-lw / 2 + 0.05, 1.15, z0 - 0.006), (0.10, 0.02, 0.006), "iron"))
        if lod == 0:
            m.merge(_cb((-w / 2 - 0.03, 1.15, -0.02), (0.035, 0.045, 0.012), 0.005, "brass", lod))
    for y in (0.35, lh - 0.35):
        leaf.merge(S.lathe([(y - 0.06, 0.016), (y + 0.06, 0.016)], [8, 6, 4][lod], tag="iron").transformed(np.eye(3), (lw / 2, 0, z0)))
    return {"body": Part(m), "leaf": Part(leaf, (lw / 2, 0.0, z0 + t), {"rotate": [[0, 1, 0], 100.0]})}


# --- door_double ------------------------------------------------------------------------------------------
def _glazed_leaf(x_hinge, side, lw, lh, z0, t, lod):
    """A half-glazed leaf hung at x_hinge: its glass over a raised panel, push plate and kick plate.
    side +1 when the hinge is on +X."""
    xc = x_hinge - side * lw / 2
    leaf = Mesh()
    for s in (1, -1):  # stiles
        leaf.merge(S.box((xc + s * (lw / 2 - 0.06), 0.012 + lh / 2, z0 + t / 2), (0.06, lh / 2, t / 2), "paint"))
    for y, hh in ((lh - 0.05, 0.05), (0.95, 0.06), (0.10, 0.10)):  # top, lock and bottom rails
        leaf.merge(S.box((xc, 0.012 + y, z0 + t / 2), (lw / 2 - 0.12, hh, t / 2), "paint"))
    gy0, gy1 = 1.02, lh - 0.10
    leaf.merge(S.box((xc, 0.012 + (gy0 + gy1) / 2, z0 + t / 2), (lw / 2 - 0.12, (gy1 - gy0) / 2, 0.004), "glass"))
    if lod == 2:  # far off the lower panel is a flat fill
        leaf.merge(S.box((xc, 0.012 + 0.54, z0 + t / 2), (lw / 2 - 0.12, 0.33, t / 2 - 0.006), "paint"))
    if lod < 2:
        leaf.merge(S.panel(lw - 0.24, 0.66, t=0.014, border=0.0, kind="raised", depth=0.006, bevel=0.035, tag="paint",
                           origin=(xc, 0.012 + 0.54, z0), right=(1, 0, 0), up=(0, 1, 0)))
        for zz, sg in ((z0 - 0.002, -1), (z0 + t + 0.002, 1)):   # glazing beads round the glass, both faces
            for yy in (gy0, gy1):
                leaf.merge(S.box((xc, 0.012 + yy, zz), (lw / 2 - 0.12, 0.012, 0.004), "paint"))
        leaf.merge(S.box((xc - side * (lw / 2 - 0.16), 1.20, z0 - 0.002), (0.04, 0.15, 0.002), "brass"))     # the push plate
        leaf.merge(S.box((xc, 0.12, z0 + t + 0.002), (lw / 2 - 0.03, 0.10, 0.002), "brass"))                 # the kick plate inside
    leaf.merge(_hinges(x_hinge, z0 + t + 0.004, (0.25, 1.05, 1.85), lod))
    return leaf


def door_double(lod):
    w, h, rv, t = 1.50, 2.10, 0.16, 0.044
    m = _lining(w, h, rv, "trim", lod)
    z0 = 0.05
    lw, lh = w / 2 - 0.004, h - 0.008
    parts = {"body": Part(m)}
    for name, xh, side in (("leaf_l", w / 2 - 0.002, 1), ("leaf_r", -w / 2 + 0.002, -1)):
        parts[name] = Part(_glazed_leaf(xh, side, lw, lh, z0, t, lod), (xh, 0.0, z0 + t), {"rotate": [[0, 1, 0], 95.0 * side]})
    return parts


# --- roller_shutter ---------------------------------------------------------------------------------------
# Measurements (card `roller_shutter.md`): a 3.00 x 2.80 opening, slats 77 mm, a 0.40 m box.
RS_W, RS_H = 3.00, 2.80
RS_GUIDE = (0.065, 0.075)   # the guide channel: across, deep (from the wall's face out)
RS_BOX = (0.40, 0.40)       # the box: high, deep
RS_PITCH = 0.077            # one slat
RS_Z = -0.040               # the curtain's middle, in the guides
RS_PERF = (1.55, 1.95)      # the band of perforated slats (a shop's: the window seen through it)


def _rs_body(lod):
    m = Mesh()
    gw, gd = RS_GUIDE
    hw = RS_W / 2
    for s in (1, -1):  # the guides: a U channel, its lips toward the curtain
        x0, x1 = s * (hw - 0.02), s * (hw - 0.02 + gw)
        lo, hi = sorted((x0, x1))
        m.merge(_cb(((lo + hi) / 2, RS_H / 2, -0.004), ((hi - lo) / 2, RS_H / 2, 0.004), 0.0, "steel", lod))  # the back on the wall
        m.merge(S.box((x1 - s * 0.003, RS_H / 2, -gd / 2), (0.003, RS_H / 2, gd / 2), "steel"))  # the outer side
        for z in (RS_Z - 0.014, RS_Z + 0.014):  # the lips either side of the curtain
            m.merge(S.box((x0 + s * 0.012, RS_H / 2, z), (0.012, RS_H / 2, 0.002), "steel"))
        m.merge(S.box((x0 + s * 0.003, RS_H / 2, -gd / 2), (0.003, RS_H / 2, gd / 2), "steel"))
        if lod == 0:  # the fixings down the back, the guide's flared mouth at the top
            for y in (0.3, 1.4, 2.5):
                m.merge(S.prism(((lo + hi) / 2, y, -0.009), 0.007, 0.004, 6, axis=(0, 0, -1), tag="bolt"))
    bh, bd = RS_BOX
    bw = hw + gw + 0.02
    # the box: a folded steel front, rounded at its foot, end plates
    if lod == 0:
        m.merge(S.chamfer_box((0, RS_H + bh / 2, -bd / 2), (bw, bh / 2, bd / 2 - 0.002), 0.05, "box", edges="front"))
        for s in (1, -1):
            m.merge(S.box((s * (bw + 0.003), RS_H + bh / 2, -bd / 2), (0.003, bh / 2 + 0.004, bd / 2), "box"))
        m.merge(S.box((0, RS_H + 0.006, -bd / 2 + 0.04), (bw - 0.02, 0.006, bd / 2 - 0.06), "dark"))  # the slot the curtain enters
        m.merge(S.box((0, RS_H + bh - 0.04, -bd - 0.002), (bw - 0.06, 0.004, 0.002), "box"))  # a fold line on the front
        # the motor's key switch on the wall beside the opening, its conduit up to the box
        kx = hw + gw + 0.16
        m.merge(_cb((kx, 1.35, -0.025), (0.045, 0.06, 0.025), 0.006, "steel", lod))
        m.merge(S.prism((kx, 1.36, -0.052), 0.012, 0.004, 8, axis=(0, 0, -1), tag="dark"))
        m.merge(S.pipe([(kx, 1.41, -0.012), (kx, RS_H + 0.1, -0.012), (bw - 0.02, RS_H + 0.1, -0.012)], 0.010, 6, tag="steel"))
    else:
        m.merge(S.box((0, RS_H + bh / 2, -bd / 2), (bw, bh / 2, bd / 2), "box"))
    return m


def _rs_curtain(lod):
    """The curtain, down: slats from the floor to the box, the bottom bar, handles and lock."""
    m = Mesh()
    hw = RS_W / 2 - 0.02 + 0.012  # into the guides
    t = 0.010
    bar = 0.06
    n = int(round((RS_H - bar) / RS_PITCH))
    pitch = (RS_H - bar) / n
    # the bottom bar: an L of heavier steel with a rubber strip under it
    m.merge(S.box((0, bar / 2 + 0.006, RS_Z), (hw, bar / 2, 0.014), "steel"))
    m.merge(S.box((0, 0.003, RS_Z), (hw - 0.01, 0.003, 0.010), "rubber"))
    if lod == 2:
        m.merge(S.box((0, bar + (RS_H - bar) / 2, RS_Z), (hw, (RS_H - bar) / 2, t / 2), "steel"))
        return m
    for k in range(n):
        y0 = bar + k * pitch
        yc = y0 + pitch / 2
        perf = RS_PERF[0] <= yc <= RS_PERF[1]
        if lod == 0:  # a slat: a curved face (two planes) with the hook joint at its top
            m.merge(S.box((0, yc - pitch * 0.22, RS_Z - 0.002), (hw, pitch * 0.26, t / 2), "steel").set_unit(k % 3 + 1))
            m.merge(S.box((0, yc + pitch * 0.18, RS_Z - 0.004), (hw, pitch * 0.22, t / 2), "steel").set_unit(k % 3 + 1))
            m.merge(S.box((0, y0 + pitch - 0.004, RS_Z + 0.002), (hw, 0.005, t / 2 + 0.002), "dark"))  # the joint's shadow
            if perf:  # a row of slots punched along the slat: the dark room shows through
                for j in range(int(RS_W / 0.12)):
                    x = -RS_W / 2 + 0.09 + j * 0.12
                    m.merge(S.box((x, yc, RS_Z - 0.0095), (0.035, 0.009, 0.0008), "dark"))
        else:
            m.merge(S.box((0, yc, RS_Z), (hw, pitch / 2 - 0.002, t / 2), "steel").set_unit(k % 3 + 1))
    if lod == 0:  # two lifting handles, the lock's cylinder and its bolts into the guides
        for x in (-0.6, 0.6):
            m.merge(S.sweep([(x - 0.07, 0.04, RS_Z - 0.014), (x - 0.07, 0.04, RS_Z - 0.05), (x + 0.07, 0.04, RS_Z - 0.05), (x + 0.07, 0.04, RS_Z - 0.014)],
                            S.circle(0.008, 6), "steel"))
        m.merge(S.prism((0, 0.036, RS_Z - 0.016), 0.013, 0.012, 10, axis=(0, 0, -1), tag="brass"))
        m.merge(S.box((0, 0.036, RS_Z - 0.029), (0.0015, 0.007, 0.001), "dark"))
    return m


def roller_shutter(lod):
    body = _rs_body(lod)
    curtain = _rs_curtain(lod)
    if lod > 0:
        body.merge(curtain)
        return {"body": Part(body)}
    # open, the curtain gathers into the box: all but the bottom bar's height
    return {"body": Part(body), "curtain": Part(curtain, (0.0, RS_H, RS_Z), {"roll": 0.975})}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "door_wood": dict(build=door_wood, materials=materials(), edge_radius=0.003, close=(-0.3, 1.0, -0.05), **_SPEC),
    "door_glass": dict(build=door_glass, materials=materials(), edge_radius=0.003, close=(-0.3, 1.0, -0.05), **_SPEC),
    "door_fire": dict(build=door_fire, materials=materials(), extra=_paint_fire, edge_radius=0.003, close=(0.0, 1.4, 0.0), **_SPEC),
    "door_double": dict(build=door_double, materials=materials(), edge_radius=0.003, close=(0.0, 1.2, -0.05), **_SPEC),
    "door_plank": dict(build=door_plank, materials=materials(), edge_radius=0.004, close=(-0.8, 1.2, -0.05), **_SPEC),
    "roller_shutter": dict(build=roller_shutter, materials=materials(), edge_radius=0.003, close=(0.6, 0.3, -0.1), **_SPEC),
}
