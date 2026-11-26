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
import surfaces as SF
from poly import Mesh
from props import Material, Part

# --- chimney_stack (the card, round 1: three_pots straightened at 400 px/m) -----------------------
BODY_H = 1.20            # the body's top, under the coping
BODY_D = 0.50            # front to back (the party wall's thickness)
COPING = (0.12, 0.10)    # thickness, overhang all round
POT = dict(r0=0.108, r1=0.098, h=0.36, rim=0.012, gap=0.28)  # foot and top radius, height, lip, centres
FLAUNCH = (0.15, 0.04)   # the mortar bed round each pot's foot: radius, height
SINK = 0.40              # how much of the body the roof hides
BAND = (0.82, 0.07, 0.025)  # round 2: the render's band (bandeau) round the body: height, tall, proud
PIPE = dict(r=0.065, h=0.55, hat=0.14, gap=0.07)  # a galvanised extension pipe: radius, length, its hat's radius and lift


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
        "galv": Material((0.58, 0.59, 0.58), under=(0.50, 0.50, 0.48), bare=(0.42, 0.30, 0.20), chip=0.3, grain=0.12),
        "iron": Material((0.16, 0.15, 0.14), under=(0.35, 0.20, 0.11), bare=(0.32, 0.18, 0.09), chip=0.8, fixing=True, grain=0.1),
        "aerial": Material((0.66, 0.67, 0.68), under=(0.60, 0.60, 0.60), bare=(0.55, 0.55, 0.55), chip=0.0, rusts=False, grain=0.05),
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


def _extension(x, y, z, lod, tall=PIPE["h"]):
    """A galvanised pipe pushed into a pot to make the flue draw, a conical hat (chapeau chinois) on
    three struts over it (pots_antennas: every flue of a stack; stacks_rows: one here and there)."""
    m = Mesh()
    sides = [10, 6, 4][lod]
    r = PIPE["r"]
    prof = [(0.0, r * 1.15), (0.03, r * 1.15), (0.035, r), (tall, r), (tall, r - 0.004, "hole"), (tall - 0.05, r - 0.004, "hole")]
    if lod > 0:  # far: a plain tube and its hat
        prof = [(0.0, r), (tall, r)]
    if lod == 0:  # a sleeve joint half way, as the pipes were sold in lengths
        prof = prof[:3] + [(tall * 0.5 - 0.02, r), (tall * 0.5 - 0.02, r * 1.08), (tall * 0.5 + 0.02, r * 1.08), (tall * 0.5 + 0.02, r)] + prof[3:]
    m.merge(S.lathe(prof, sides, tag="galv", caps=(False, True)))
    hr, lift = PIPE["hat"], PIPE["gap"]
    hy = tall + lift
    hat = [(hy - 0.01, hr), (hy, hr), (hy + 0.07, 0.012), (hy + 0.075, 0.0)] if lod == 0 else [(hy, hr), (hy + 0.075, 0.0)]
    m.merge(S.lathe(hat, sides, tag="galv", caps=(True, False)))
    if lod == 0:
        for k in range(3):
            a = 2 * np.pi * k / 3
            m.merge(_bx(np.cos(a) * r - 0.004, np.cos(a) * r + 0.004, tall - 0.04, hy, np.sin(a) * r - 0.006, np.sin(a) * r + 0.006, "galv"))
    return m.transformed(np.eye(3), (x, y, z))


def _cowl(x, y, z, lod):
    """A cast ventilating cowl (aspirateur) set on a pot: a collar, a drum slotted all round, a
    mushroom cap (stacks_rows, the grey ones over the pots)."""
    sides = [12, 8, 6][lod]
    prof = [(0.0, 0.085), (0.04, 0.085), (0.045, 0.07), (0.20, 0.07), (0.21, 0.10), (0.27, 0.10), (0.28, 0.07), (0.32, 0.07),
            (0.33, 0.13), (0.35, 0.13), (0.42, 0.02), (0.43, 0.0)]
    if lod > 0:
        prof = [(0.0, 0.085), (0.21, 0.08), (0.27, 0.10), (0.33, 0.13), (0.43, 0.0)]
    m = S.lathe(prof, sides, tag="galv", caps=(True, False))
    if lod == 0:  # the drum's slots, dark
        for k in range(6):
            a = 2 * np.pi * (k + 0.5) / 6
            c = np.array([np.cos(a), 0.0, np.sin(a)]) * 0.101
            m.merge(S.box((c[0], 0.24, c[2]), (0.004, 0.022, 0.004), "hole"))
    return m.transformed(np.eye(3), (x, y, z))


def _broken_pot(x, y, z, h, unit):
    """A pot whose top has broken away, its rim jagged and the flue open (seeded by its unit)."""
    rng = np.random.default_rng(unit * 31 + 7)
    sides = 12
    r0, r1 = POT["r0"], POT["r1"]
    t = 0.014
    tops = h * (0.55 + 0.35 * rng.random(sides))
    tops[rng.integers(sides)] = h * 0.35  # one deep notch
    rad = lambda j, f: r0 + (r1 - r0) * tops[j] / h * f  # noqa: E731
    specs = [(lambda j: 0.0, lambda j: r0), (lambda j: tops[j] * 0.5, lambda j: rad(j, 0.5)),
             (lambda j: tops[j], lambda j: rad(j, 1.0)), (lambda j: tops[j] - 0.004, lambda j: rad(j, 1.0) - t),
             (lambda j: tops[j] - 0.10, lambda j: r0 - t)]
    rings = []
    for yy, rr in specs:
        rings.append([np.array([np.cos(2 * np.pi * j / sides) * rr(j), yy(j), np.sin(2 * np.pi * j / sides) * rr(j)]) for j in range(sides)])
    m = Mesh()
    m.loft(rings, "pot", caps=(False, True), cap_tags=(None, "hole"), band_tags=lambda r, j: "pot" if r < 3 else "hole")
    m.set_unit(unit)
    return m.transformed(np.eye(3), (x, y, z))


def _rungs(x, lod, ys=(0.58, 0.98)):
    """Iron rungs (crampons) leaded into the stack's end for the sweep (stacks_rows)."""
    m = Mesh()
    if lod > 0:
        return m
    for y in ys:
        for zz in (-0.13, 0.13):
            m.merge(_bx(x, x + 0.11, y - 0.009, y + 0.009, zz - 0.009, zz + 0.009, "iron"))
        m.merge(_bx(x + 0.09, x + 0.11, y - 0.009, y + 0.009, -0.13, 0.13, "iron"))
    return m


def _antenna(x, lod):
    """A TV aerial on a mast clamped to the stack's end (pots_antennas): two clamps, the mast, a
    Yagi's boom with its elements, the reflector's grid and a dipole under it."""
    m = Mesh()
    mx = x + 0.05
    top = BODY_H + 2.0
    sides = [8, 5, 4][lod]
    m.merge(S.pipe([(mx, 0.45, 0.0), (mx, top, 0.0)], 0.02, sides, tag="galv"))
    for y in (0.62, 1.05):  # the clamps: a bracket leaded in, round the mast
        m.merge(_bx(x, mx + 0.03, y - 0.02, y + 0.02, -0.03, 0.03, "iron"))
    by = top - 0.10
    if lod == 2:
        m.merge(_bx(mx - 0.008, mx + 0.008, by - 0.008, by + 0.008, -0.55, 0.45, "aerial"))
        return m
    m.merge(S.pipe([(mx, by, -0.55), (mx, by, 0.45)], 0.011, sides, tag="aerial"))  # the boom, pointing front
    n = 9 if lod == 0 else 3
    for k in range(n):
        z = -0.5 + k * 0.9 / (n - 1)
        half = 0.13 + 0.12 * (k / (n - 1))  # directors short in front, widest at the back
        if lod == 0:
            m.merge(S.pipe([(mx - half, by, z), (mx + half, by, z)], 0.004, 4, tag="aerial"))
        else:
            m.merge(_bx(mx - half, mx + half, by - 0.004, by + 0.004, z - 0.004, z + 0.004, "aerial"))
    if lod == 0:  # the reflector's grid, the dipole and the cable down the mast
        for dy in (-0.10, -0.05, 0.05, 0.10):
            m.merge(S.pipe([(mx - 0.25, by + dy, 0.45), (mx + 0.25, by + dy, 0.45)], 0.003, 4, tag="aerial"))
        m.merge(S.pipe([(mx, by - 0.10, 0.45), (mx, by + 0.10, 0.45)], 0.004, 4, tag="aerial"))
        m.merge(S.pipe([(mx - 0.32, top - 0.55, 0.0), (mx + 0.32, top - 0.55, 0.0)], 0.006, 5, tag="aerial"))
        m.merge(S.pipe([(mx + 0.025, by - 0.02, 0.0), (mx + 0.025, 0.7, 0.0)], 0.0035, 4, tag="iron"))
    return m


def _stack(n, length, heights, lod, kinds=None):
    m = Mesh()
    half = length / 2
    c = 0.01 if lod == 0 else 0.0
    m.merge(_bx(-half, half, 0.0, BODY_H, -BODY_D / 2, BODY_D / 2, "render", c, "vertical"))
    if lod < 2:  # the band round it where the stack was raised once (stacks_rows)
        by, bh, bp = BAND
        m.merge(_bx(-half - bp, half + bp, by, by + bh, -BODY_D / 2 - bp, BODY_D / 2 + bp, "render", 0.008 if lod == 0 else 0.0, "top"))
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
        kind = (kinds or {}).get(k, "pot")
        py = y0 + (FLAUNCH[1] * 0.5 if lod < 2 else 0.0)
        if kind == "broken" and lod < 2:
            m.merge(_broken_pot(x, py, 0.0, heights[k], k + 1))
        else:
            m.merge(_pot(x, py, 0.0, heights[k], lod, k + 1))
        if kind == "pipe":
            m.merge(_extension(x, py + heights[k] - 0.06, 0.0, lod))
        elif kind == "cowl":
            m.merge(_cowl(x, py + heights[k] - 0.02, 0.0, lod))
    return m


def chimney_stack(lod):
    n = 3
    m = _stack(n, 1.16, [POT["h"]] * n, lod, {2: "pipe"})
    m.merge(_rungs(1.16 / 2, lod))
    return {"body": Part(m)}


# the long stack: pots of the sizes the merchants sold, set as each flue was rebuilt (stacks_rows)
LONG_HEIGHTS = [0.36, 0.42, 0.36, 0.30, 0.48, 0.36, 0.42, 0.36]
LONG_KINDS = {1: "pipe", 3: "cowl", 5: "broken", 6: "pipe"}  # round 2: what was done to some flues


def chimney_stack_long(lod):
    n = len(LONG_HEIGHTS)
    length = n * POT["gap"] + 0.30
    m = _stack(n, length, LONG_HEIGHTS, lod, LONG_KINDS)
    m.merge(_antenna(length / 2, lod))
    return {"body": Part(m)}


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
    # the casement's frame (dormant); the leaves are parts of their own (`_dormer_leaf`)
    z0, z1 = D_Z
    m.merge(_bx(-hw, hw, oh - 0.05, oh, z0, z1, "joinery", c))
    for s in (1, -1):
        m.merge(_bx(s * hw, s * (hw - 0.05), 0.02, oh, z0, z1, "joinery", c))
    if lod == 0:  # round 2: the jambs' raised panels and the architrave strip under the cap (zinc_row)
        for s in (1, -1):
            a, b = s * (hw + 0.025), s * (fw - 0.025)
            for x in (a, b):
                m.merge(_bx(x - 0.008, x + 0.008, 0.10, oh - 0.06, -0.052, -0.04, "zinc", 0.003, "front"))
            for y in (0.10, oh - 0.06):
                m.merge(_bx(a, b, y - 0.008, y + 0.008, -0.052, -0.04, "zinc", 0.003, "front"))
        m.merge(_bx(-fw - 0.01, fw + 0.01, D_HEAD - 0.045, D_HEAD - 0.01, -0.07, -0.05, "zinc", 0.004, "front"))
        # the flashing (noquet) where each cheek meets the slope, a strip lying on the slates
        for s in (1, -1):
            steps = [0.0, top * 0.5, top, D_CAP[1]]
            for a, b in zip(steps, steps[1:]):
                xa = s * (fw + out * max(0.0, 1 - a / top))
                xb = s * (fw + out * max(0.0, 1 - b / top))
                za, zb = a * D_SLOPE + 0.1, b * D_SLOPE + 0.1
                m.merge(_poly_face([(xa, a, za - 0.004), (xa + s * 0.05, a, za - 0.004), (xb + s * 0.05, b, zb - 0.004), (xb, b, zb - 0.004)][::s], "zinc"))
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
    if lod == 0:  # round 2: the cornice's drip standing out over the fascia, front and sides
        m.merge(_bx(-hw - 0.025, hw + 0.025, eave - 0.022, eave, zf - 0.025, zf + 0.02, "zinc", 0.006, "front"))
        for s in (1, -1):
            m.merge(_bx(s * (hw + 0.025), s * (hw - 0.02), eave - 0.022, eave, zf - 0.025, back, "zinc"))
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
        # round 2: the standing seams (rolls) down the side slopes, from the ridge to the eaves
        for k in (1, 2):
            z = apex[2] + (back - apex[2]) * k / 3
            for s in (1, -1):
                m.merge(S.pipe([(0.0, ridge + 0.006, z), (s * (hw + 0.02), eave + 0.006, z)], 0.008, 5, tag="zinc"))
    return m


D_Z = (0.08, 0.13)       # the casement's frame: front and back


def _dormer_leaf(side, lod):
    """One leaf of the casement (side +1 the viewer's left), hinged on the frame's jamb, opening
    into the room: stiles, rails, three panes and their bars, the drip moulding on the bottom rail."""
    hw = D_OPEN[0] / 2
    z0, z1 = D_Z
    c = 0.004 if lod == 0 else 0.0
    xo, xi = side * (hw - 0.05), side * 0.002
    lo, hi = 0.02, D_OPEN[1] - 0.05
    m = Mesh()
    m.merge(_bx(xo, xo - side * 0.045, lo, hi, z0 + 0.005, z1 - 0.005, "joinery", c))
    m.merge(_bx(xi + side * 0.045, xi, lo, hi, z0 - 0.006, z1 - 0.005, "joinery", c))
    m.merge(_bx(xo, xi, hi - 0.05, hi, z0 + 0.005, z1 - 0.005, "joinery", c))
    m.merge(_bx(xo, xi, lo, lo + 0.12, z0 + 0.005, z1 - 0.005, "joinery", c))
    lx0, lx1 = xo - side * 0.045, xi + side * 0.045
    y_lo, y_hi = lo + 0.12, hi - 0.05
    rows = 3 if lod < 2 else 1  # far: one sheet of glass, the bars baked on it
    pane = (y_hi - y_lo - (rows - 1) * 0.03) / rows
    for k in range(rows):
        y = y_lo + k * (pane + 0.03)
        m.merge(_bx(lx0, lx1, y, y + pane, 0.103, 0.107, "glass"))
        if k:
            m.merge(_bx(lx0, lx1, y - 0.03, y, z0 + 0.012, z1 - 0.012, "joinery", c))
    if lod == 0:
        m.merge(_bx(lx0, xi, lo + 0.04, lo + 0.075, z0 - 0.018, z0 + 0.005, "joinery", 0.012, "top"))  # the jet d'eau
    return m, (xo, lo, z1 - 0.005)


def dormer(lod):
    parts = {"body": Part(_dormer_body(lod))}
    for side, nm in ((1, "leaf_l"), (-1, "leaf_r")):
        mesh, hinge = _dormer_leaf(side, lod)
        parts[nm] = Part(mesh, hinge, {"rotate": [[0, 1, 0], 100.0 * side]})  # into the room
    if lod > 0:
        merged = Mesh()
        for p in parts.values():
            merged.merge(p.mesh)
        return {"body": Part(merged)}
    return parts


# --- balcony, balcony_long (the cards, round 1: pc61 and valois) ------------------------------------
# The stone balcony of the main floor: a slab with a moulded edge and rounded front corners on
# scrolled consoles, a wrought-iron railing of bars with hearts of C-scrolls between them (pc61).
# Coordinates: the wall's face z = 0, the front -Z, x = 0 the middle; the consoles' feet y = 0,
# the floor of the balcony (the slab's top) at `balcony_floor(spec)`.
BALCONY = dict(L=1.90, D=0.58, R=0.24, CH=0.80, consoles=(0.62,), bay=0.118)
BALCONY_LONG = dict(L=7.40, D=0.86, R=0.42, CH=1.30, consoles=(3.30, 1.18), bay=0.118)
SLAB_T = 0.26            # the slab, moulding included
B_RAIL = 1.00            # the railing's top over the floor
B_IN = 0.07              # how far the railing stands in from the slab's edge
B_BAR = (0.014, 0.014)   # square bars
B_FLAT = (0.008, 0.016)  # the flat scroll iron: across, deep


def balcony_materials():
    return {
        "stone": Material((0.74, 0.70, 0.62), kind="stone", chip=0.0, rusts=False, grain=0.08),
        "iron": Material((0.09, 0.09, 0.10), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.5, grain=0.1),
        "lead": Material((0.46, 0.47, 0.48), under=(0.44, 0.44, 0.44), bare=(0.40, 0.40, 0.40), chip=0.0, rusts=False, grain=0.08),
        "fixing": Material((0.12, 0.11, 0.10), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


def balcony_floor(b):
    return b["CH"] + SLAB_T


def _plan(b, o, n_arc):
    """The slab's outline in plan (x, z) pushed out by `o` (negative: in), its back on the wall:
    the front, its rounded corners, the sides; ordered as the kit's boxes go round."""
    L, D, R = b["L"] / 2 + o, b["D"] + o, max(b["R"] + o, 0.01)
    pts = []
    for k in range(n_arc + 1):  # the -X corner, from the side to the front
        a = np.radians(180 + 90 * k / n_arc)
        pts.append((-L + R + np.cos(a) * R, -D + R + np.sin(a) * R))
    for k in range(n_arc + 1):  # the +X corner
        a = np.radians(270 + 90 * k / n_arc)
        pts.append((L - R + np.cos(a) * R, -D + R + np.sin(a) * R))
    pts += [(L, 0.0), (-L, 0.0)]
    return pts


def _slab(b, lod):
    """The slab lofted through its moulding: a fillet at the top, a torus, a cavetto, the corona and
    the soffit stepping in under it."""
    top = balcony_floor(b)
    if lod == 0:
        prof = [(0.0, 0.0), (0.0, -0.035), (-0.012, -0.045), (0.004, -0.075), (-0.012, -0.10), (-0.012, -0.14),
                (-0.04, -0.17), (-0.07, -0.19), (-0.09, -0.21), (-0.09, -SLAB_T)]
        n_arc = 8
    elif lod == 1:
        prof = [(0.0, 0.0), (0.0, -0.10), (-0.05, -0.18), (-0.09, -SLAB_T)]
        n_arc = 5
    else:
        prof = [(0.0, 0.0), (-0.05, -SLAB_T)]
        n_arc = 3
    rings = []
    for o, dy in prof[::-1]:  # bottom up
        rings.append([np.array([x, top + dy, z]) for x, z in _plan(b, o, n_arc)])
    m = Mesh()
    m.loft(rings, "stone", caps=(True, True))
    if lod == 0:  # the lead flashing turned down over the top's edge, the floor sloping out
        ring_a = [np.array([x, top + 0.004, z]) for x, z in _plan(b, 0.004, n_arc)]
        ring_b = [np.array([x, top + 0.004, z]) for x, z in _plan(b, -0.03, n_arc)]
        ring_c = [np.array([x, top - 0.02, z]) for x, z in _plan(b, 0.004, n_arc)]
        f = Mesh()
        f.loft([ring_c, ring_a, ring_b], "lead", caps=(False, False))
        m.merge(f)
    return m


def _console_outline(h, d):
    """The console's side (out from the wall, up from its foot): a big volute under the slab
    curling in, a neck, a small volute at the foot curling out (valois, pc61)."""
    pts = [(0.0, 0.0), (0.10 * d, 0.0)]
    for k in range(1, 6):  # the foot's scroll bulging out
        a = np.radians(-90 + 180 * k / 6)
        pts.append((0.10 * d + np.cos(a) * 0.20 * d + 0.06 * d, 0.10 * h + np.sin(a) * 0.10 * h))
    pts.append((0.18 * d, 0.30 * h))
    for k in range(0, 7):  # the long concave sweep up to the big scroll
        t = k / 6
        pts.append((0.18 * d + (0.62 * d) * t ** 2.2, 0.32 * h + 0.48 * h * t))
    for k in range(1, 5):  # the big scroll's face rounding up under the slab
        a = np.radians(-30 + 30 * k)
        pts.append((0.80 * d + np.cos(a) * 0.12 * d, 0.88 * h + np.sin(a) * 0.08 * h))
    pts += [(d, h), (0.0, h)]
    return pts


def _console(x, b, lod, w=0.24):
    """One console at `x`: its side profile pushed `w` wide, the volutes' eyes on both sides, a
    leaf (an acanthus strip) down its front and an abacus under the slab."""
    h, d = b["CH"], b["D"] * 0.62
    m = Mesh()
    outline = _console_outline(h, d)
    m.merge(S.extrude(outline, w, 0.012 if lod == 0 else 0.0, "stone", origin=(x + w / 2, 0.0, 0.0),
                      right=(0, 0, -1), up=(0, 1, 0)))
    m.merge(_bx(x - w / 2 - 0.02, x + w / 2 + 0.02, h - 0.05, h, -d - 0.03, 0.0, "stone", 0.008 if lod == 0 else 0.0, "front"))
    if lod == 0:
        for sx in (1, -1):  # the volutes' eyes, standing proud on each side
            m.merge(S.prism((x + sx * w / 2, 0.86 * h, -0.74 * d), 0.10 * d + 0.04, 0.02, 10, axis=(sx, 0, 0), tag="stone"))
            m.merge(S.prism((x + sx * (w / 2 + 0.02), 0.86 * h, -0.74 * d), 0.04, 0.012, 8, axis=(sx, 0, 0), tag="stone"))
            m.merge(S.prism((x + sx * w / 2, 0.11 * h, -0.16 * d), 0.07 * d + 0.02, 0.015, 8, axis=(sx, 0, 0), tag="stone"))
        # the leaf down the front: a raised strip following the concave sweep, wider at the top
        for k in range(6):
            t0, t1 = k / 6, (k + 1) / 6
            y0, y1 = 0.32 * h + 0.48 * h * t0, 0.32 * h + 0.48 * h * t1
            z0 = -(0.18 * d + 0.62 * d * t0 ** 2.2)
            ww = w * (0.18 + 0.22 * t1)
            m.merge(_bx(x - ww, x + ww, y0, y1, z0 - 0.022, z0 + 0.02, "stone", 0.006))
        # the drops (gouttes) under the foot
        for k in (-1, 0, 1):
            m.merge(S.prism((x + k * 0.05, 0.05, -0.10 * d - 0.03), 0.018, 0.05, 6, axis=(0, -1, 0), tag="stone"))
    return m


def _rail_path(b, n_arc):
    """Where the railing stands: the slab's outline B_IN in, from the wall at +X round to the wall
    at -X (the order the bars and the rails follow)."""
    pts = _plan(b, -B_IN, n_arc)
    body = pts[:-2]  # without the wall's two
    return [(pts[-2][0], -0.02)] + body[::-1] + [(pts[-1][0], -0.02)]


def _sample(path, step):
    """Points every `step` along a 2D path, each with its tangent: [(p, t)]."""
    P = [np.array(p, np.float64) for p in path]
    seg = [np.linalg.norm(P[i + 1] - P[i]) for i in range(len(P) - 1)]
    total = sum(seg)
    n = max(2, int(round(total / step)))
    out = []
    for k in range(n + 1):
        d = total * k / n
        for i, L in enumerate(seg):
            if d <= L + 1e-9 or i == len(seg) - 1:
                t = (P[i + 1] - P[i]) / max(L, 1e-9)
                out.append((P[i] + t * min(d, L), t))
                break
            d -= L
    return out, total / n


def _flat(pts3, w=None):
    w = w or B_FLAT
    return S.sweep(pts3, [(-w[0] / 2, -w[1] / 2), (w[0] / 2, -w[1] / 2), (w[0] / 2, w[1] / 2), (-w[0] / 2, w[1] / 2)],
                   "iron", up=(0, 1, 0))


def _heart(p, t, y, w, h, lod):
    """A heart of two C-scrolls between two bars (pc61's railing): each scroll starts at the
    heart's point below, rises round its lobe and curls in. `p` the middle (x, z) on the rail's
    line, `t` its tangent, `y` the heart's bottom, `w` and `h` its size."""
    m = Mesh()
    steps = 6 if h > 0.15 else 4  # the low band's small hearts take fewer
    c = np.array([w * 0.25, h * 0.60])  # the right lobe's centre (along the rail, up)
    r0 = w * 0.25
    lobe = [np.array([0.0, 0.0])]
    for k in range(steps + 1):  # round the outside of the lobe, over its top, curling in
        a = np.radians(-100 + 330 * k / steps)
        r = r0 * (1 - 0.55 * k / steps)
        lobe.append(c + np.array([np.cos(a), np.sin(a) * (h * 0.40) / r0]) * r)
    for s in (1, -1):
        p3 = [np.array([p[0] + t[0] * q[0] * s, y + q[1], p[1] + t[1] * q[0] * s]) for q in lobe]
        m.merge(_flat(p3))
    return m


def _railing(b, lod):
    m = Mesh()
    floor = balcony_floor(b)
    n_arc = 8 if lod == 0 else 4
    path = _rail_path(b, n_arc)
    top = [(x, floor + B_RAIL, z) for x, z in path]
    low = [(x, floor + 0.07, z) for x, z in path]
    # the handrail: a moulded iron bar, wider than deep; the bottom rail and a second rail under the hearts
    m.merge(S.sweep(top, [(-0.022, -0.03), (0.022, -0.03), (0.026, -0.012), (0.018, 0.0), (-0.018, 0.0), (-0.026, -0.012)],
                    "iron", up=(0, 1, 0)))
    m.merge(_flat(low, (0.012, 0.03)))
    band = 0.24  # the hearts' band under the handrail
    if lod < 2:
        m.merge(_flat([(x, floor + B_RAIL - 0.03 - band, z) for x, z in path], (0.010, 0.016)))
    step = b["bay"] if lod < 2 else 0.45
    pts, gap = _sample(path, step)
    for k, (p, t) in enumerate(pts[1:-1], 1):  # the bars (the first and last are the rail's ends on the wall)
        bar_w = B_BAR if lod == 0 else (0.016, 0.016)
        m.merge(_bx(p[0] - bar_w[0] / 2, p[0] + bar_w[0] / 2, floor + 0.07, floor + B_RAIL - 0.03, p[1] - bar_w[1] / 2, p[1] + bar_w[1] / 2, "iron"))
        if lod == 0 and k < len(pts) - 1:  # a heart between this bar and the next, in the top band and the bottom
            q = (pts[k][0] + pts[k + 1][0]) / 2 if k + 1 < len(pts) else p
            tt = pts[k][1]
            m.merge(_heart(q, tt, floor + B_RAIL - 0.03 - band + 0.02, gap * 0.92, band - 0.04, lod))
            m.merge(_heart(q, tt * np.array([1, 1]), floor + 0.09, gap * 0.92, 0.12, lod))
    if lod == 0:  # where the rails go into the wall: lugs leaded in, their plates
        for x, z in (path[0], path[-1]):
            for y in (floor + B_RAIL - 0.015, floor + 0.085):
                m.merge(_bx(x - 0.035, x + 0.035, y - 0.035, y + 0.035, -0.006, 0.0, "fixing"))
        for p, t in pts[1:-1:6]:  # the bars' feet leaded into the slab
            m.merge(S.prism((p[0], floor, p[1]), 0.016, 0.012, 6, tag="lead"))
    return m


def _balcony(b, lod):
    m = _slab(b, lod)
    for cx in b["consoles"]:
        for s in (1, -1):
            m.merge(_console(s * cx, b, lod))
    if len(b["consoles"]) == 1 and lod < 2:
        pass
    m.merge(_railing(b, lod))
    return {"body": Part(m)}


def balcony(lod):
    return _balcony(BALCONY, lod)


def balcony_long(lod):
    return _balcony(BALCONY_LONG, lod)


# --- mansard (the card, round 1: zinc_row, pots_antennas) ------------------------------------------
# One bay of a Paris mansard roof, to be repeated along a front: the zinc box gutter (chéneau) on
# the cornice, the steep slate slope (brisis) on its deck, the zinc roll at the break (bourseau),
# the shallow zinc slope (terrasson) with its standing seams up to the ridge's roll, a cast-iron
# skylight (tabatière) in it. Coordinates: the front wall's face z = 0, the top of the cornice
# y = 0; the bay runs along x, its ends open (the next bay closes them).
M_W = 3.00               # the bay's width
M_SLOPE = 72.0           # the brisis' pitch (dormer: 0.325 m back per metre up)
M_H = 2.60               # the brisis' height: one attic floor
M_TOP = 20.0             # the terrasson's pitch
M_BACK = 2.40            # how far back the terrasson runs to the ridge
M_SEAM = 0.62            # standing seams on the terrasson
M_EAVE = (0.10, 0.06)    # where the slates start: up, back from the wall's face


def mansard_materials():
    return {
        "slate": Material((0.25, 0.26, 0.29), kind="stone", chip=0.0, rusts=False, grain=0.06, vary=0.05,
                          palette=[(0.25, 0.26, 0.29), (0.24, 0.25, 0.28), (0.265, 0.27, 0.295), (0.245, 0.245, 0.27), (0.27, 0.275, 0.30)]),
        "zinc": Material((0.55, 0.57, 0.58), under=(0.48, 0.49, 0.48), bare=(0.42, 0.42, 0.41), chip=0.2, rusts=False, grain=0.1),
        "deck": Material((0.10, 0.08, 0.06), kind="wood", chip=0.0, rusts=False, grain=0.2, sheds=False),
        "iron": Material((0.12, 0.12, 0.13), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), chip=0.6, grain=0.1),
        "glass": Material((0.20, 0.23, 0.26), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
    }


def _slope_frame(deg):
    p = np.radians(deg)
    return np.array([0.0, np.sin(p), np.cos(p)]), np.array([0.0, np.cos(p), -np.sin(p)])


def _mansard_lines():
    """The eaves, the break and the ridge as (y, z) points, and the slopes' lengths."""
    up1, n1 = _slope_frame(M_SLOPE)
    eave = np.array([0.0, M_EAVE[0], M_EAVE[1]])
    L1 = M_H / np.sin(np.radians(M_SLOPE))
    brk = eave + up1 * L1
    up2, n2 = _slope_frame(M_TOP)
    L2 = M_BACK / np.cos(np.radians(M_TOP))
    ridge = brk + up2 * L2
    return eave, brk, ridge, L1, L2


def _gutter(lod):
    """The box gutter on the cornice: its floor, the front with a rolled lip, the back turned up
    under the slates."""
    hw = M_W / 2
    if lod == 0:
        prof = [(0.06, 0.0), (-0.30, 0.0), (-0.30, 0.10), (-0.325, 0.12), (-0.33, 0.145), (-0.315, 0.165), (-0.295, 0.16),
                (-0.285, 0.14), (-0.285, 0.025), (0.045, 0.025), (0.045, 0.13), (0.06, 0.13)]
    else:
        prof = [(0.06, 0.0), (-0.32, 0.0), (-0.32, 0.16), (-0.285, 0.16), (-0.285, 0.025), (0.045, 0.025), (0.045, 0.13), (0.06, 0.13)]
    # the sweep's "side" points out of the wall (-Z) for a path running -X: (out, up) = (-z, y)
    prof = [(-z, y) for z, y in prof]
    return S.sweep([(hw, 0.0, 0.0), (-hw, 0.0, 0.0)], prof[::-1], "zinc", caps=False)


def _sheet(a, b, c, d, tag, t=0.008):
    return _poly_face([a, b, c, d], tag, t)


def mansard(lod):
    hw = M_W / 2
    eave, brk, ridge, L1, L2 = _mansard_lines()
    up1, n1 = _slope_frame(M_SLOPE)
    up2, n2 = _slope_frame(M_TOP)
    X = np.array([1.0, 0.0, 0.0])
    m = Mesh()
    m.merge(_gutter(lod))
    # the deck under the slates (dark where a slate is missing), and the slates
    o = eave + np.array([-hw, 0, 0])
    m.merge(_sheet(o + X * M_W, o, o + up1 * L1, o + X * M_W + up1 * L1, "deck"))
    missing = ((7, 4), (8, 4), (15, 10)) if lod == 0 else ()
    m.merge(SF.slates(M_W, L1, M_SLOPE, origin=o + n1 * 0.004, tag="slate", lod=lod, seed=11, missing=missing))
    # the break: a zinc roll (bourseau) over the slates' top row, its apron down onto them
    if lod < 2:
        r = 0.055
        path = [tuple(brk + X * hw + n1 * 0.02), tuple(brk - X * hw + n1 * 0.02)]
        prof = [(np.cos(a) * r, np.sin(a) * r) for a in np.radians(np.linspace(-120, 200, 9 if lod == 0 else 5))]
        m.merge(S.sweep(path, prof, "zinc", caps=False))
        a0 = brk + n1 * 0.012
        m.merge(_sheet(a0 + X * hw, a0 - X * hw, a0 - X * hw - up1 * 0.14, a0 + X * hw - up1 * 0.14, "zinc", 0.004))
    # the terrasson: a zinc sheet up to the ridge, its standing seams, a roll along the ridge
    t0 = brk + n2 * 0.006
    m.merge(_sheet(t0 + X * hw, t0 - X * hw, t0 - X * hw + up2 * L2, t0 + X * hw + up2 * L2, "zinc"))
    if lod < 2:
        k = 0
        x = -hw + M_SEAM / 2
        while x < hw:
            s0 = brk + X * x + n2 * 0.012
            m.merge(S.pipe([tuple(s0), tuple(s0 + up2 * L2)], 0.010 if lod == 0 else 0.014, 5 if lod == 0 else 3, tag="zinc"))
            x += M_SEAM
            k += 1
        m.merge(S.pipe([tuple(ridge + X * hw + n2 * 0.03), tuple(ridge - X * hw + n2 * 0.03)], 0.035, 8 if lod == 0 else 4, tag="zinc"))
    if lod == 0:  # a cast-iron skylight (tabatière) half way up, its glass, its frame and its prop
        c = brk + up2 * (L2 * 0.45) + X * (M_SEAM * 0.5)
        fw, fl = 0.24, 0.30
        B = np.stack([X, n2, up2], 1)
        m.merge(S.chamfer_box((0, 0, 0), (fw, 0.04, fl), 0.01, "iron", edges="not_bottom").transformed(B, c + n2 * 0.04))
        m.merge(S.box((0, 0, 0), (fw - 0.03, 0.005, fl - 0.03), "glass").transformed(B, c + n2 * 0.083))
        m.merge(S.box((0, 0, 0), (0.008, 0.008, fl - 0.04), "iron").transformed(B, c + n2 * 0.09))  # the bar down its middle
        m.merge(S.box((0, 0, 0), (fw + 0.05, 0.003, fl + 0.06), "zinc").transformed(B, c + n2 * 0.012))  # its flashing
    return {"body": Part(m)}


ELEMENTS = {
    "mansard": {
        "build": mansard,
        "materials": mansard_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.004,
        "close": (0.0, 1.4, 0.4),  # the slates and the missing ones
    },
    "balcony": {
        "build": balcony,
        "materials": balcony_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.005,
        "close": (0.62, BALCONY["CH"] * 0.8, -0.3),  # a console and the railing's foot
    },
    "balcony_long": {
        "build": balcony_long,
        "materials": balcony_materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.005,
        "close": (3.3, BALCONY_LONG["CH"] + 0.4, -0.5),  # the rounded end: console, slab and railing
    },
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
