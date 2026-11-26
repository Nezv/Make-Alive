"""Front walls, railings and gates (S156). Cards and references: references/elements/<name>.md;
the workflow: references/elements/WORKFLOW.md.

porte_cochere: the carriage gateway of a house (square_on, carved, worn_1900): an opening with a low
segmental head in a stone surround, its reveal, two great wooden leaves of raised panels (parts
`leaf_l`, `leaf_r`, opening into the court), a fixed panel in the arch, knob, knocker and letter
slot, the stone sill and a cast-iron chasse-roue at each jamb's foot. The wall's face is z = 0
(the house +Z), the opening's foot y = 0.
railing_plinth: one 2.40 m bay of an iron railing on a stone plinth (bury_plate28, boulevard): the
plinth and its coping, the bars with spear finials between two rails, a band of rings at the foot.
Bays join end to end along x; the railing's middle is z = 0.
railing_pier: the stone pier between bays and at gates: a square shaft, a moulded cap, a ball on it.
railing_gate: the gate between two piers (3.0 m): two leaves of bars, their top rail rising to the
middle, the lock box (parts `leaf_l`, `leaf_r`).
garden_wall: one 3.0 m bay of a plastered rubble wall with its sloping stone coping, a pier
at the bay's end.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

GATE = dict(w=2.50, h=3.20, arch=0.22, reveal=0.22)   # the porte cochÃ¨re's opening: width, springing, rise
PLINTH = dict(h=0.60, d=0.40, bay=2.40)
RAIL = dict(top=1.95, bars=0.12, bar=0.022)            # over the pavement: the top rail, the bars' spacing and size
PIER = dict(w=0.50, h=2.30)
WALL = dict(bay=3.00, h=2.40, t=0.45)


def materials():
    return {
        "stone": Material((0.72, 0.68, 0.60), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "wood": Material((0.16, 0.26, 0.38), under=(0.55, 0.52, 0.46), bare=(0.42, 0.32, 0.22), kind="wood", chip=0.8, grain=0.10,
                         palette=[(0.16, 0.26, 0.38)], vary=0.02),
        "iron": Material((0.10, 0.10, 0.11), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.6, grain=0.08),
        "brass": Material((0.62, 0.50, 0.26), under=(0.40, 0.32, 0.18), bare=(0.35, 0.28, 0.16), chip=0.0, rusts=False, grain=0.05),
        "plaster": Material((0.80, 0.76, 0.68), under=(0.55, 0.50, 0.44), bare=(0.48, 0.44, 0.38), kind="plaster", chip=0.6, rusts=False, grain=0.15),
        "dark": Material((0.06, 0.06, 0.06), chip=0.0, rusts=False, grain=0.02, fades=False),
        "bolt": Material((0.20, 0.20, 0.20), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


# --- porte_cochere -----------------------------------------------------------------------------------
def _leaf(w, h, lod, side):
    """One leaf w x h, its hinge edge at x = 0 and the rest towards +x (side 1) or -x (side -1),
    its front at z = 0: a low panel, a tall one, the rails and stiles between."""
    m = Mesh()
    t = 0.07
    kind = "raised" if lod == 0 else "inset"
    xs = side * w / 2
    lo = 1.05
    if lod < 2:
        m.merge(S.panel(w, lo, t=t, border=0.11, kind=kind, depth=0.015, bevel=0.04, tag="wood", origin=(xs, lo / 2, 0)))
        m.merge(S.panel(w, h - lo, t=t, border=0.11, kind=kind, depth=0.015, bevel=0.04, tag="wood", origin=(xs, lo + (h - lo) / 2, 0)))
    else:
        m.merge(S.box((xs, h / 2, -t / 2), (w / 2, h / 2, t / 2), "wood"))
    if lod == 0:
        # the meeting edge's moulded strip (battement) on the right leaf, the knob on the left
        edge = xs + side * w / 2
        if side < 0:
            m.merge(S.chamfer_box((edge - 0.02, h / 2, -0.012), (0.035, h / 2 - 0.02, 0.012), 0.006, "wood", edges="front").transformed(np.eye(3), (0, 0, -t)))
        else:
            m.merge(S.prism((edge - 0.18, 1.10, -t - 0.002), 0.035, 0.05, 12, axis=(0, 0, -1), tag="brass"))
            m.merge(S.box((edge - 0.45, 1.25, -t - 0.004), (0.14, 0.035, 0.004), "brass"))      # the letter plate
            m.merge(S.box((edge - 0.45, 1.25, -t - 0.0085), (0.10, 0.008, 0.001), "dark"))       # its slot
        # the hinges' straps across the stiles
        for y in (0.25, h * 0.5, h - 0.25):
            m.merge(S.box((side * 0.10, y, -t - 0.006), (0.10, 0.02, 0.006), "iron"))
    return m


def porte_cochere(lod):
    w, h, arch, rev = GATE["w"], GATE["h"], GATE["arch"], GATE["reveal"]
    m = Mesh()
    # the stone surround: a broad flat band with a small moulding at its inner edge
    mould = [(0.0, 0.0), (0.30, 0.0), (0.30, -0.035), (0.06, -0.035), (0.04, -0.06), (0.0, -0.06)] if lod == 0 else \
        [(0.0, 0.0), (0.30, 0.0), (0.30, -0.04), (0.0, -0.04)]
    m.merge(S.opening_frame(w, h + arch, mould, arch=arch, origin=(0, 0, 0), tag="stone", bottom=False))
    # the reveal: the jambs' depth into the wall, and the head's soffit
    for s in (1, -1):
        m.merge(S.box((s * (w / 2 + 0.01), (h + arch) / 2, rev / 2), (0.01, (h + arch) / 2, rev / 2), "stone"))
    m.merge(S.box((0, h + arch + 0.005, rev / 2), (w / 2, 0.01, rev / 2), "stone"))
    # the fixed panel in the arch over the leaves
    arc = S.opening_path(w, h + arch, arch, [8, 5, 3][lod])[2:]       # the head from the right springing to the left
    tym = [(w / 2, h)] + [(x, y) for x, y in arc] + [(-w / 2, h)]
    m.merge(S.extrude(tym, 0.07, 0.0, "wood", origin=(0, 0, rev), right=(1, 0, 0), up=(0, 1, 0)))
    m.merge(S.box((0, h - 0.04, rev - 0.035), (w / 2, 0.04, 0.035), "wood"))  # the transom under it
    # the sill and the chasse-roues
    m.merge(S.chamfer_box((0, 0.03, rev / 2 - 0.05), (w / 2 + 0.30, 0.03, rev / 2 + 0.10), 0.01, "stone", edges="top"))
    if lod < 2:
        for s in (1, -1):
            path = [(s * (w / 2 - 0.02), 0.06, -0.20), (s * (w / 2 - 0.02), 0.30, -0.20), (s * (w / 2 - 0.02), 0.52, -0.12), (s * (w / 2 - 0.02), 0.62, 0.0)]
            m.merge(S.sweep(S.fillet(path, 0.12, 3) if lod == 0 else path, S.circle(0.035, [8, 5][lod]), "iron"))
    parts = {"body": Part(m)}
    lw = w / 2
    for name, side, x in (("leaf_l", 1, -w / 2), ("leaf_r", -1, w / 2)):
        leaf = _leaf(lw, h - 0.08, lod, side).transformed(np.eye(3), (x, 0.0, rev))
        parts[name] = Part(leaf, (x, 0.0, rev), {"rotate": [[0, 1, 0], -95.0 * side]})
    return parts


# --- the railings ----------------------------------------------------------------------------------------
def _plinth(length, lod):
    m = Mesh()
    hh, d = PLINTH["h"], PLINTH["d"]
    m.merge(S.box((0, (hh - 0.08) / 2, 0), (length / 2, (hh - 0.08) / 2, d / 2), "stone"))
    cop = S.chamfer_box((0, hh - 0.04, 0), (length / 2, 0.04, d / 2 + 0.03), 0.015, "stone", edges="top") if lod < 2 else \
        S.box((0, hh - 0.04, 0), (length / 2, 0.04, d / 2 + 0.03), "stone")
    m.merge(cop)
    return m


def _bars(length, y0, top, lod, rise=0.0):
    """Bars between two rails across `length` (x from -length/2), the top rail `top` (plus `rise`
    at the middle, an arch), the spears above it."""
    m = Mesh()
    b = RAIL["bar"]
    n = max(2, int(round(length / RAIL["bars"])))
    sq = [(-b / 2, -b / 2), (b / 2, -b / 2), (b / 2, b / 2), (-b / 2, b / 2)]
    for i in range(n):
        x = -length / 2 + (i + 0.5) * length / n
        t = top + rise * np.cos(np.pi * x / length)
        m.merge(S.box((x, (y0 + t) / 2, 0), (b / 2, (t - y0) / 2, b / 2), "iron"))
        if lod < 2:  # the spear: a collar and a flat point
            m.merge(S.extrude([(-0.022, 0.0), (0.022, 0.0), (0.008, 0.06), (0.0, 0.11), (-0.008, 0.06)], b, 0.0, "iron",
                              origin=(x, t + 0.02, b / 2), right=(1, 0, 0), up=(0, 1, 0)))
            if lod == 0:
                m.merge(S.box((x, t + 0.012, 0), (b * 0.9, 0.012, b * 0.9), "iron"))
    for y in (y0 + 0.03, top - 0.06):
        if rise and y > y0 + 0.1:
            k = [16, 8, 4][lod]
            pts = [(-length / 2 + length * j / k, y + rise * np.cos(np.pi * (-0.5 + j / k)), 0) for j in range(k + 1)]
            m.merge(S.sweep(pts, [(-0.008, -0.03), (0.008, -0.03), (0.008, 0.03), (-0.008, 0.03)], "iron"))
        else:
            m.merge(S.box((0, y, 0), (length / 2, 0.025, 0.012), "iron"))
    return m


def railing_plinth(lod):
    L = PLINTH["bay"]
    m = _plinth(L, lod)
    y0 = PLINTH["h"]
    m.merge(_bars(L, y0, RAIL["top"], lod))
    if lod == 0:  # the band of rings over the bottom rail, a ring between each pair of bars
        n = int(round(L / RAIL["bars"]))
        for i in range(n - 1):
            x = -L / 2 + (i + 1) * L / n
            ring = [(x + np.cos(a) * 0.045, y0 + 0.13 + np.sin(a) * 0.045, 0) for a in np.linspace(0, 2 * np.pi, 9)[:-1]]
            m.merge(S.sweep(ring, [(-0.005, -0.008), (0.005, -0.008), (0.005, 0.008), (-0.005, 0.008)], "iron", closed=True, up=(0, 0, 1)))
        m.merge(S.box((0, y0 + 0.19, 0), (L / 2, 0.012, 0.010), "iron"))
        for i in range(n):  # the bars leaded into the coping
            m.merge(S.box((-L / 2 + (i + 0.5) * L / n, y0 + 0.003, 0), (0.02, 0.003, 0.02), "dark"))
    return {"body": Part(m)}


def railing_pier(lod):
    w, h = PIER["w"], PIER["h"]
    m = Mesh()
    m.merge(S.chamfer_box((0, 0.15, 0), (w / 2 + 0.04, 0.15, w / 2 + 0.04), 0.02, "stone", edges="top") if lod < 2 else S.box((0, 0.15, 0), (w / 2 + 0.04, 0.15, w / 2 + 0.04), "stone"))
    m.merge(S.box((0, (h - 0.25) / 2 + 0.15, 0), (w / 2, (h - 0.25 - 0.30) / 2 + 0.15, w / 2), "stone"))
    # the cap: a moulded slab over a neck
    cap = [(h - 0.25, w / 2 + 0.02), (h - 0.19, w / 2 + 0.02), (h - 0.17, w / 2 + 0.07), (h - 0.10, w / 2 + 0.07), (h - 0.08, w / 2 + 0.03), (h - 0.04, w / 2 + 0.03)]
    cap = cap if lod == 0 else [cap[0], cap[2], cap[3], cap[5]]
    m.merge(S.lathe([(y, r * np.sqrt(2)) for y, r in cap], 4, turn=np.pi / 4, tag="stone"))  # square: corners at r * sqrt 2
    if lod < 2:  # the ball on its neck
        n = [10, 6][lod]
        m.merge(S.lathe([(h - 0.04, 0.10), (h, 0.06), (h + 0.03, 0.06), (h + 0.08, 0.13), (h + 0.18, 0.15), (h + 0.28, 0.12), (h + 0.34, 0.0)], n, tag="stone"))
    return {"body": Part(m)}


def railing_gate(lod):
    W = 3.00
    m = Mesh()
    m.merge(S.box((0, 0.02, 0), (W / 2, 0.02, 0.20), "stone"))  # the sill between the piers
    parts = {"body": Part(m)}
    lw = W / 2 - 0.02
    for name, side, x in (("leaf_l", 1, -W / 2), ("leaf_r", -1, W / 2)):
        leaf = Mesh()
        b = Mesh()  # the top rail rises to the middle of the pair: each leaf half the arch
        n = int(round(lw / RAIL["bars"]))
        for i in range(n):
            u = (i + 0.5) / n                      # 0 at the hinge, 1 at the meeting stile
            top = 2.00 + 0.30 * np.sin(np.pi / 2 * u)
            bx = side * (u * lw)
            b.merge(S.box((bx, (0.06 + top) / 2, 0), (RAIL["bar"] / 2, (top - 0.06) / 2, RAIL["bar"] / 2), "iron"))
            if lod < 2:
                b.merge(S.extrude([(-0.022, 0.0), (0.022, 0.0), (0.008, 0.06), (0.0, 0.11), (-0.008, 0.06)], RAIL["bar"], 0.0, "iron",
                                  origin=(bx, top + 0.02, RAIL["bar"] / 2), right=(1, 0, 0), up=(0, 1, 0)))
        k = [10, 6, 3][lod]
        rail = [(side * lw * j / k, 1.94 + 0.30 * np.sin(np.pi / 2 * j / k), 0) for j in range(k + 1)]
        b.merge(S.sweep(rail, [(-0.008, -0.03), (0.008, -0.03), (0.008, 0.03), (-0.008, 0.03)], "iron"))
        for y in (0.09, 0.95):
            b.merge(S.box((side * lw / 2, y, 0), (lw / 2, 0.03, 0.014), "iron"))
        for u in (0.0, 1.0):  # the stiles
            b.merge(S.box((side * u * lw, 1.05, 0), (0.025, 1.0, 0.02), "iron"))
        if side < 0:  # the lock box on the meeting stile
            b.merge(S.box((side * (lw - 0.08), 1.05, -0.03), (0.08, 0.10, 0.03), "iron"))
        leaf.merge(b)
        parts[name] = Part(leaf.transformed(np.eye(3), (x, 0.0, 0.0)), (x, 0.0, 0.0), {"rotate": [[0, 1, 0], -95.0 * side]})
    return parts


# --- garden_wall -------------------------------------------------------------------------------------
def garden_wall(lod):
    L, h, t = WALL["bay"], WALL["h"], WALL["t"]
    m = Mesh()
    m.merge(S.box((0, (h - 0.10) / 2, 0), (L / 2, (h - 0.10) / 2, t / 2), "plaster"))
    # the coping: two slopes to a ridge, overhanging both faces, a drip under each edge
    cop = [(-t / 2 - 0.05, h - 0.10), (t / 2 + 0.05, h - 0.10), (t / 2 + 0.05, h - 0.05), (0.0, h + 0.10), (-t / 2 - 0.05, h - 0.05)]
    m.merge(S.extrude([(z, y) for z, y in cop], L, 0.0, "stone", origin=(-L / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0)))
    # the plinth course at the foot, the stone pier at the bay's end
    m.merge(S.box((0, 0.15, 0), (L / 2, 0.15, t / 2 + 0.02), "stone"))
    if lod < 2:
        pw = 0.55
        m.merge(S.box((L / 2 - pw / 2, (h + 0.15) / 2, 0), (pw / 2, (h + 0.15) / 2, t / 2 + 0.05), "stone"))
        m.merge(S.chamfer_box((L / 2 - pw / 2, h + 0.20, 0), (pw / 2 + 0.04, 0.05, t / 2 + 0.09), 0.02, "stone", edges="top"))
    if lod == 0:  # where the plaster has fallen, the rubble under it shows: a few stones proud
        rng = np.random.default_rng(5)
        for k in range(9):
            x, y = rng.uniform(-L / 2 + 0.3, L / 2 - 0.8), rng.uniform(0.4, 1.0)
            m.merge(S.box((x, y, -t / 2 - 0.006), (rng.uniform(0.07, 0.14), rng.uniform(0.04, 0.07), 0.008), "stone").set_unit(k + 1))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "porte_cochere": dict(build=porte_cochere, materials=materials(), edge_radius=0.006, close=(0.6, 1.2, 0.1), **_SPEC),
    "railing_plinth": dict(build=railing_plinth, materials=materials(), edge_radius=0.003, close=(0.0, 0.8, 0.0), **_SPEC),
    "railing_pier": dict(build=railing_pier, materials=materials(), edge_radius=0.006, close=(0.0, PIER["h"], 0.0), **_SPEC),
    "railing_gate": dict(build=railing_gate, materials=materials(), edge_radius=0.003, close=(0.0, 1.9, 0.0), **_SPEC),
    "garden_wall": dict(build=garden_wall, materials=materials(), edge_radius=0.006, close=(0.0, WALL["h"], 0.0), **_SPEC),
}
