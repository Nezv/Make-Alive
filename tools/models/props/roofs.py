"""Roofs, dormers and balconies (S159). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

chimney_stack: the plastered stack of an old Paris house (souche de cheminée) standing out of the
roof on the party wall: a rendered body, an overhanging stone coping weathered to a slope, a
mortar bed (flaunching) and a row of terracotta pots (mitrons), one per flue.
chimney_stack_long: the same on a long party wall, eight flues, the pots of uneven heights.
dormer: the zinc dormer (lucarne) of a Paris mansard: a casement down to the floor behind a
little railing, zinc-clad jambs and lintel, skirts flaring out at the foot, cheeks running back
to the mansard's steep slope, a small hipped zinc cap with roll joints.

Coordinates: metres, Y up, the front is -Z, x = 0 the middle. The stack's foot is y = 0: the house
sinks it into its roof (`SINK` of it is meant to be below the slates).
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

# --- chimney_stack (the card, round 1: three_pots straightened at 400 px/m) -----------------------
BODY_H = 1.20            # the body's top, under the coping
BODY_D = 0.50            # front to back (the party wall's thickness)
COPING = (0.12, 0.10)    # thickness, overhang all round
POT = dict(r0=0.108, r1=0.098, h=0.36, rim=0.012, gap=0.28)  # foot and top radius, height, lip, centres
FLAUNCH = (0.15, 0.04)   # the mortar bed round each pot's foot: radius, height
SINK = 0.40              # how much of the body the roof hides


def _bx(x0, x1, y0, y1, z0, z1, tag, c=0.0, edges="front"):
    centre = ((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)
    half = (abs(x1 - x0) / 2, abs(y1 - y0) / 2, abs(z1 - z0) / 2)
    if c > 0 and min(half) > c * 1.2:
        return S.chamfer_box(centre, half, c, tag, edges=edges)
    return S.box(centre, half, tag)


def chimney_materials():
    return {
        "render": Material((0.70, 0.69, 0.66), kind="plaster", chip=0.0, rusts=False, grain=0.07),
        "coping": Material((0.56, 0.55, 0.51), kind="stone", chip=0.0, rusts=False, grain=0.1),
        "mortar": Material((0.60, 0.58, 0.54), kind="masonry", chip=0.0, rusts=False, grain=0.12),
        "pot": Material((0.62, 0.27, 0.13), kind="clay", chip=0.0, rusts=False, grain=0.08,
                        palette=[(0.62, 0.27, 0.13), (0.66, 0.32, 0.16), (0.56, 0.24, 0.12), (0.70, 0.38, 0.20)], vary=0.06),
        "hole": Material((0.04, 0.035, 0.03), chip=0.0, rusts=False, grain=0.2, kind="sand", sheds=False),
    }


def _pot(x, y, z, h, lod, unit):
    """A terracotta pot tapering up to a rolled lip, its flue dark inside."""
    sides = [12, 8, 6][lod]
    r0, r1, lip = POT["r0"], POT["r1"], POT["rim"]
    t = 0.014  # the wall's thickness, seen at the top
    if lod == 0:
        prof = [(0.0, r0), (h * 0.08, r0 * 0.99), (h - 0.03, r1), (h - 0.028, r1 + lip), (h - 0.004, r1 + lip),
                (h, r1 + lip * 0.4), (h, r1 - t, "hole"), (h - 0.06, r1 - t, "hole")]
    else:
        prof = [(0.0, r0), (h - 0.03, r1), (h, r1 + lip * 0.6), (h, r1 - t, "hole")]
    m = S.lathe(prof, sides, turn=np.pi / sides, tag="pot", caps=(False, True))
    m.set_unit(unit)
    return m.transformed(np.eye(3), (x, y, z))


def _stack(n, length, heights, lod):
    m = Mesh()
    half = length / 2
    c = 0.01 if lod == 0 else 0.0
    m.merge(_bx(-half, half, 0.0, BODY_H, -BODY_D / 2, BODY_D / 2, "render", c, "vertical"))
    th, ov = COPING
    ch, cd = half + ov, BODY_D / 2 + ov
    # the coping: a slab whose top is weathered down to its edges
    m.merge(_bx(-ch, ch, BODY_H, BODY_H + th * 0.55, -cd, cd, "coping", 0.008 if lod == 0 else 0.0, "all"))
    if lod < 2:
        top = [(-ch + 0.03, -cd + 0.03), (ch - 0.03, -cd + 0.03), (ch - 0.03, cd - 0.03), (-ch + 0.03, cd - 0.03)]
        inner = [(-half + 0.02, -BODY_D / 2 + 0.02), (half - 0.02, -BODY_D / 2 + 0.02), (half - 0.02, BODY_D / 2 - 0.02),
                 (-half + 0.02, BODY_D / 2 - 0.02)]
        rings = [[(x, BODY_H + th * 0.55, z) for x, z in [(-ch, -cd), (ch, -cd), (ch, cd), (-ch, cd)]],
                 [(x, BODY_H + th * 0.75, z) for x, z in top], [(x, BODY_H + th, z) for x, z in inner]]
        w = Mesh()
        w.loft([[np.array(p, np.float64) for p in r] for r in rings], "coping", caps=(False, True))
        m.merge(w)
    xs = [(-(n - 1) / 2 + k) * POT["gap"] for k in range(n)]
    for k, x in enumerate(xs):
        y0 = BODY_H + th
        if lod < 2:  # the flaunching: a low cone of mortar round the pot's foot
            fr, fh = FLAUNCH
            m.merge(S.lathe([(0.0, fr), (fh, POT["r0"] + 0.006)], [10, 8, 6][lod], tag="mortar", caps=(False, False))
                    .transformed(np.eye(3), (x, y0 - 0.002, 0.0)))
        m.merge(_pot(x, y0 + (FLAUNCH[1] * 0.5 if lod < 2 else 0.0), 0.0, heights[k], lod, k + 1))
    return m


def chimney_stack(lod):
    n = 3
    return {"body": Part(_stack(n, 1.16, [POT["h"]] * n, lod))}


# the long stack: pots of the sizes the merchants sold, set as each flue was rebuilt (stacks_rows)
LONG_HEIGHTS = [0.36, 0.42, 0.36, 0.30, 0.48, 0.36, 0.42, 0.36]


def chimney_stack_long(lod):
    n = len(LONG_HEIGHTS)
    return {"body": Part(_stack(n, n * POT["gap"] + 0.30, LONG_HEIGHTS, lod))}


# --- dormer (the card, round 1: zinc_row straightened at 300 px/m) ---------------------------------
D_OPEN = (0.94, 1.88)    # the casement's opening: width, height over the floor
D_JAMB = 0.18            # zinc-clad jambs each side
D_HEAD = 2.02            # the lintel's top, under the cap
D_CAP = (0.81, 2.10, 2.38, 0.15)  # the cap: half-width, eave top, ridge, how far it stands in front
D_SKIRT = (1.60, 0.18)   # the skirts: where they start flaring, how far out at the foot
D_SLOPE = 0.325          # the mansard's steep slope behind: metres back per metre up (72 degrees)
D_RAIL = 0.98
D_ROOM = 0.95


def dormer_materials():
    return {
        "zinc": Material((0.55, 0.57, 0.58), under=(0.48, 0.49, 0.48), bare=(0.42, 0.42, 0.41), chip=0.2, rusts=False, grain=0.1),
        "joinery": Material((0.88, 0.87, 0.83), under=(0.74, 0.72, 0.66), bare=(0.52, 0.46, 0.38), kind="wood", rusts=False),
        "glass": Material((0.20, 0.23, 0.26), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "iron": Material((0.10, 0.10, 0.11), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.3, grain=0.1),
        "room": Material((0.05, 0.045, 0.04), kind="sand", chip=0.0, rusts=False, grain=0.2, sheds=False),
    }


def _poly_face(pts, tag, t=0.004):
    """A flat quad or triangle as a sheet `t` thick (zinc), so both sides show and no two faces
    share their corners (Blender would merge them)."""
    P = np.array(pts, np.float64)
    n = np.cross(P[1] - P[0], P[2] - P[0])
    n /= np.linalg.norm(n)
    m = Mesh()
    rings = [[p for p in P], [p - n * t for p in P]]
    m.loft(rings, tag)
    return m


def _dormer_body(lod):
    m = Mesh()
    ow, oh = D_OPEN
    hw = ow / 2
    fw = hw + D_JAMB
    c = 0.006 if lod == 0 else 0.0
    # the front: jambs, lintel, all clad in zinc, standing 4 cm proud of the skirts
    for s in (1, -1):
        m.merge(_bx(s * hw, s * fw, 0.0, D_HEAD, -0.04, 0.10, "zinc", c))
    m.merge(_bx(-fw, fw, oh, D_HEAD, -0.05, 0.10, "zinc", c))
    # the skirts: from the jamb out to an edge that flares from D_SKIRT[0] down to the floor
    top, out = D_SKIRT
    for s in (1, -1):
        e_top, e_foot = s * fw, s * (fw + out)
        m.merge(_poly_face([(s * fw, 0.0, -0.005), (e_foot, 0.0, -0.005), (e_top, top, -0.005), (s * fw, top, -0.005)], "zinc"))
        # the cheek: from that edge back to the slope (deeper the higher it goes)
        steps = [0.0, top * 0.5, top, D_CAP[1]]
        for a, b in zip(steps, steps[1:]):
            xa = s * (fw + out * max(0.0, 1 - a / top))
            xb = s * (fw + out * max(0.0, 1 - b / top))
            m.merge(_poly_face([(xa, a, -0.005), (xb, b, -0.005), (xb, b, b * D_SLOPE + 0.1), (xa, a, a * D_SLOPE + 0.1)], "zinc"))
        if lod == 0:  # the zinc roll along the skirt's edge
            m.merge(S.pipe([(e_foot, 0.0, -0.012), (e_top, top, -0.012), (e_top, D_CAP[1], -0.012)], 0.012, 6, tag="zinc"))
    # the sill and the floor plate the railing stands on
    m.merge(_bx(-fw - out - 0.05, fw + out + 0.05, -0.05, 0.02, -0.28, 0.12, "zinc", 0.008 if lod == 0 else 0.0, "top"))
    # the casement: a frame, two fixed leaves of three panes (moving leaves are round 2)
    z0, z1 = 0.08, 0.13
    m.merge(_bx(-hw, hw, oh - 0.05, oh, z0, z1, "joinery", c))
    for s in (1, -1):
        m.merge(_bx(s * hw, s * (hw - 0.05), 0.02, oh, z0, z1, "joinery", c))
        m.merge(_bx(s * 0.0, s * 0.045, 0.02, oh - 0.05, z0 - 0.006, z1, "joinery", c))
        m.merge(_bx(s * (hw - 0.05), s * 0.045, 0.02, 0.14, z0, z1, "joinery", c))
        lx0, lx1 = s * (hw - 0.05), s * 0.045
        y_lo, y_hi = 0.14, oh - 0.05
        pane = (y_hi - y_lo - 2 * 0.03) / 3
        for k in range(3):
            y = y_lo + k * (pane + 0.03)
            m.merge(_bx(lx0, lx1, y, y + pane, 0.103, 0.107, "glass"))
            if k and lod < 2:
                m.merge(_bx(lx0, lx1, y - 0.03, y, z0 + 0.008, z1 - 0.008, "joinery", c))
    # the dark room behind
    m.merge(_bx(-hw, hw, 0.0, oh, z1 + D_ROOM, z1 + D_ROOM + 0.02, "room"))
    for s in (1, -1):
        m.merge(_bx(s * hw, s * (hw + 0.02), 0.0, oh, z1, z1 + D_ROOM, "room"))
    m.merge(_bx(-hw, hw, oh, oh + 0.02, z1, z1 + D_ROOM, "room"))
    m.merge(_bx(-hw, hw, -0.02, 0.0, z1, z1 + D_ROOM, "room"))
    # the railing in front, on the floor plate
    rz = -0.16
    rw = fw + 0.05
    m.merge(_bx(-rw, rw, D_RAIL - 0.03, D_RAIL, rz - 0.015, rz + 0.015, "iron", 0.004 if lod == 0 else 0.0, "top"))
    m.merge(_bx(-rw, rw, 0.10, 0.12, rz - 0.008, rz + 0.008, "iron"))
    for s in (1, -1):
        m.merge(_bx(s * rw, s * (rw - 0.025), 0.02, D_RAIL, rz - 0.012, rz + 0.012, "iron"))
    if lod < 2:
        n = 10
        for k in range(n):
            x = -rw + (k + 1) * 2 * rw / (n + 1)
            m.merge(_bx(x - 0.007, x + 0.007, 0.02, D_RAIL - 0.03, rz - 0.007, rz + 0.007, "iron"))
    m.merge(_dormer_cap(lod))
    return m


def _dormer_cap(lod):
    """The hipped zinc cap: a fascia round its eaves, a front hip and two side slopes up to a ridge
    running back into the mansard, a roll on every hip and ridge, a few on the slopes."""
    hw, eave, ridge, front = D_CAP
    back = D_CAP[1] * D_SLOPE + 0.45
    m = Mesh()
    zf = -front
    # the fascia: a band under the eaves on the front and the sides
    m.merge(_bx(-hw, hw, eave - 0.08, eave, zf, zf + 0.04, "zinc", 0.004 if lod == 0 else 0.0))
    for s in (1, -1):
        m.merge(_bx(s * hw, s * (hw - 0.04), eave - 0.08, eave, zf, back, "zinc"))
    apex = (0.0, ridge, zf + hw * 0.55)  # the hip's top: as far back as the cap is steep
    rb = (0.0, ridge, back)
    fl, fr = (hw + 0.02, eave, zf - 0.02), (-hw - 0.02, eave, zf - 0.02)
    bl, br = (hw + 0.02, eave, back), (-hw - 0.02, eave, back)
    m.merge(_poly_face([fl, fr, apex], "zinc"))
    m.merge(_poly_face([fr, br, rb, apex], "zinc"))
    m.merge(_poly_face([bl, fl, apex, rb], "zinc"))
    if lod == 0:  # rolls on the hips and the ridge, one down the front
        for a, b in ((fl, apex), (fr, apex), (apex, rb), ((0.0, eave, zf - 0.02), apex)):
            pa, pb = np.array(a) + [0, 0.008, 0], np.array(b) + [0, 0.008, 0]
            m.merge(S.pipe([tuple(pa), tuple(pb)], 0.011, 6, tag="zinc"))
    return m


def dormer(lod):
    return {"body": Part(_dormer_body(lod))}


ELEMENTS = {
    "chimney_stack": {
        "build": chimney_stack,
        "materials": chimney_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.006,
        "close": (0.0, BODY_H + 0.2, 0.0),  # the pots on the coping
    },
    "chimney_stack_long": {
        "build": chimney_stack_long,
        "materials": chimney_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.006,
        "close": (0.0, BODY_H + 0.2, 0.0),  # the pots on the coping
    },
    "dormer": {
        "build": dormer,
        "materials": dormer_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.005,
        "close": (0.0, 1.9, 0.0),  # the lintel and the cap
    },
}
