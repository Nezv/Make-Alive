"""The barracks' old riding hall and its court (S224). Cards and references:
references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

riding_hall: the manège of the caserne, now its gym: a long stone hall on a plinth, pilasters between
tall round-headed windows down both sides, the gable ends with their great arched doors (part
`door_l` / `door_r`, the leaves of the front one) and an oculus over each, the slate roof on its
cornice with a ridge vent running along it and the iron trusses inside.
sports_court: the court beside it: a 28 x 15 m playing surface with its lines painted (basketball,
volleyball), two basketball posts with backboards and hoops, the volleyball posts and net.

Standing on y = 0; the hall's length runs along Z, its front gable (the one whose leaves open) at -Z.
"""
import numpy as np

import shapes as S
import surfaces as F
from poly import Mesh
from props import Material, Part

HALL = dict(len=40.0, w=18.0, wall=8.0, pitch=0.42, bays=8)
COURT = dict(len=28.0, w=15.0)


def materials():
    return {
        "stone": Material((0.76, 0.72, 0.63), kind="stone", chip=0.0, rusts=False, grain=0.12, pattern=F.Bond("ashlar", seed=9)),
        "dress": Material((0.82, 0.78, 0.69), kind="stone", chip=0.0, rusts=False, grain=0.10),
        "slate": Material((0.26, 0.28, 0.31), kind="stone", chip=0.0, rusts=False, grain=0.10),
        "glass": Material((0.20, 0.23, 0.25), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "frame": Material((0.30, 0.34, 0.30), under=(0.45, 0.30, 0.20), bare=(0.40, 0.28, 0.18), chip=0.5, grain=0.05),
        "door": Material((0.28, 0.20, 0.13), under=(0.45, 0.35, 0.25), bare=(0.50, 0.40, 0.28), kind="wood", chip=0.5, rusts=False, grain=0.12),
        "zinc": Material((0.55, 0.57, 0.58), under=(0.5, 0.5, 0.5), bare=(0.6, 0.6, 0.6), chip=0.0, rusts=False, grain=0.05),
        "iron": Material((0.18, 0.20, 0.20), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.06),
        "court": Material((0.36, 0.42, 0.50), kind="concrete", chip=0.0, rusts=False, grain=0.08, fades=False),
        "white": Material((0.90, 0.90, 0.88), under=(0.6, 0.6, 0.6), bare=(0.5, 0.5, 0.5), chip=0.3, grain=0.04),
        "board": Material((0.88, 0.88, 0.86), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "net": Material((0.85, 0.85, 0.82), kind="paper", chip=0.0, rusts=False, grain=0.04),
    }


def _arch_outline(w, h, n):
    """A round-headed opening's outline from its foot: straight jambs to h - w/2, a half-circle."""
    pts = [(-w / 2, 0.0), (w / 2, 0.0)]
    for a in np.linspace(0, np.pi, n + 1):
        pts.append((np.cos(a) * w / 2, h - w / 2 + np.sin(a) * w / 2))
    return pts


# --- riding_hall ----------------------------------------------------------------------------------------------
def riding_hall(lod):
    L, W, H, p, nb = HALL["len"], HALL["w"], HALL["wall"], HALL["pitch"], HALL["bays"]
    m = Mesh()
    rise = W / 2 * np.tan(p)
    # the walls' mass and the gables: one prism of the hall's section pushed along its length
    sec = [(-W / 2, 0.0), (W / 2, 0.0), (W / 2, H), (0.0, H + rise), (-W / 2, H)]
    m.merge(S.extrude(sec, L, 0.0, "stone", origin=(0, 0, L / 2), right=(1, 0, 0), up=(0, 1, 0)))
    m.merge(S.box((0, 0.35, 0), (W / 2 + 0.15, 0.35, L / 2 + 0.15), "dress"))       # the plinth
    # the cornice and the slate roof's two slopes, the ridge vent
    m.merge(S.box((0, H + 0.12, 0), (W / 2 + 0.35, 0.12, L / 2 + 0.10), "dress"))
    for s in (1, -1):
        slope = S.box((0, 0, 0), (W / 2 / np.cos(p) / 2 + 0.25, 0.06, L / 2 + 0.30), "slate")
        R = S.rotation((0, 0, 1), -s * p)
        c = np.array([s * W / 4, H + 0.24 + rise / 2, 0.0])
        m.merge(slope.transformed(R, tuple(c)))
    if lod < 2:
        m.merge(S.box((0, H + rise + 0.50, 0), (0.6, 0.30, L / 2 - 2.0), "zinc"))
        m.merge(S.box((0, H + rise + 0.84, 0), (0.9, 0.05, L / 2 - 1.8), "zinc"))
    # the side bays: a pilaster between each, a tall round-headed window in each bay
    bay = L / nb
    for s in (1, -1):
        for k in range(nb + 1):
            z = -L / 2 + k * bay
            m.merge(S.box((s * (W / 2 + 0.12), H / 2, z), (0.12, H / 2, 0.45), "dress"))
        for k in range(nb):
            z = -L / 2 + (k + 0.5) * bay
            win = _arch_outline(2.2, 4.6, [10, 6, 3][lod])
            pane = S.extrude(win, 0.02, 0.0, "glass", origin=(s * (W / 2 + 0.01), 2.4, z), right=(0, 0, -s), up=(0, 1, 0))
            m.merge(pane)
            if lod < 2:  # its surround, the keystone and the glazing bars
                ring = [(s * (W / 2 + 0.04), 2.4 + y, z - s * x) for x, y in win[2:]]
                m.merge(S.sweep(ring, [(-0.14, -0.04), (0.14, -0.04), (0.14, 0.04), (-0.14, 0.04)], "dress", up=(s, 0, 0)))
                m.merge(S.box((s * (W / 2 + 0.06), 2.4 + 4.6 + 0.08, z), (0.06, 0.20, 0.14), "dress"))
                m.merge(S.box((s * (W / 2 + 0.04), 2.32, z), (0.08, 0.08, 1.30), "dress"))      # the sill
                if lod == 0:
                    for j in range(1, 4):
                        m.merge(S.box((s * (W / 2 + 0.025), 2.4 + j * 0.9, z), (0.01, 0.025, 1.08), "frame"))
                    m.merge(S.box((s * (W / 2 + 0.025), 2.4 + 2.0, z), (0.01, 2.0, 0.025), "frame"))
    # the gable ends: an oculus high up, the great arched door (the front one's leaves are parts)
    parts = {}
    for s in (1, -1):
        zf = s * (L / 2 + 0.01)
        n = [16, 10, 6][lod]
        ring = [(np.cos(a) * 1.3, H + 1.0 + np.sin(a) * 1.3, zf) for a in np.linspace(0, 2 * np.pi, n + 1)[:-1]]
        m.merge(S.extrude([(np.cos(a) * 1.15, H + 1.0 + np.sin(a) * 1.15) for a in np.linspace(0, 2 * np.pi, n + 1)[:-1]], 0.02, 0.0, "glass",
                          origin=(0, 0, zf), right=(-s, 0, 0), up=(0, 1, 0)))
        if lod < 2:
            m.merge(S.sweep(ring, [(-0.16, -0.05), (0.16, -0.05), (0.16, 0.05), (-0.16, 0.05)], "dress", closed=True, up=(0, 0, s)))
        dw, dh = 5.0, 6.0
        door = _arch_outline(dw, dh, [12, 8, 4][lod])
        if lod < 2:
            m.merge(S.sweep([(x, y, zf + s * 0.03) for x, y in door[2:]] , [(-0.30, -0.06), (0.30, -0.06), (0.30, 0.06), (-0.30, 0.06)], "dress", up=(0, 0, s)))
            for sx in (1, -1):
                m.merge(S.box((sx * (dw / 2 + 0.30), (dh - dw / 2) / 2, zf + s * 0.03), (0.30, (dh - dw / 2) / 2, 0.06), "dress"))
        # the fanlight over the leaves, the two leaves
        fan = [(np.cos(a) * dw / 2, dh - dw / 2 + np.sin(a) * dw / 2) for a in np.linspace(0, np.pi, [12, 8, 4][lod] + 1)]
        m.merge(S.extrude(fan, 0.02, 0.0, "glass", origin=(0, 0, zf), right=(-s, 0, 0), up=(0, 1, 0)))
        for side, name in ((1, "door_r"), (-1, "door_l")):
            leaf = Mesh()
            xh = side * dw / 2
            leaf.merge(S.box((xh - side * dw / 4, (dh - dw / 2) / 2, zf + s * 0.06), (dw / 4 - 0.01, (dh - dw / 2) / 2, 0.06), "door"))
            if lod < 2:
                for y in (1.0, 2.4):  # the leaves' ledges and strap hinges
                    leaf.merge(S.box((xh - side * dw / 4, y, zf + s * 0.13), (dw / 4 - 0.08, 0.08, 0.02), "door"))
                    leaf.merge(S.box((xh - side * 0.5, y, zf + s * 0.15), (0.5, 0.04, 0.01), "iron"))
            if s < 0:
                parts[name] = Part(leaf, (xh, 0.0, zf + s * 0.06), {"rotate": [[0, 1, 0], -100.0 * side]})
            else:
                m.merge(leaf)
    if lod == 0:
        # the iron trusses inside, seen through the windows and the open doors
        for k in range(1, nb):
            z = -L / 2 + k * bay
            tr = [(-W / 2 + 0.3, H, z), (0.0, H + rise - 0.3, z), (W / 2 - 0.3, H, z)]
            m.merge(S.sweep(tr, [(-0.08, -0.15), (0.08, -0.15), (0.08, 0.15), (-0.08, 0.15)], "iron", up=(0, 0, 1)))
            m.merge(S.sweep([(-W / 2 + 0.3, H, z), (W / 2 - 0.3, H, z)], S.circle(0.04, 4), "iron"))
    return dict({"body": Part(m)}, **parts)


# --- sports_court ---------------------------------------------------------------------------------------------
def sports_court(lod):
    L, W = COURT["len"], COURT["w"]
    m = Mesh()
    m.merge(S.box((0, 0.01, 0), (W / 2 + 1.5, 0.01, L / 2 + 2.0), "court"))
    # the basketball posts at both ends: an arm out over the line, the backboard, the hoop and its net
    for s in (1, -1):
        z = s * (L / 2 + 1.2)
        m.merge(S.box((0, 0.15, z), (0.30, 0.15, 0.30), "court"))
        m.merge(S.sweep([(0, 0.3, z), (0, 3.3, z), (0, 3.3, z - s * 1.0)], S.circle(0.06, [8, 5, 4][lod]), "white"))
        m.merge(S.box((0, 3.4, s * (L / 2 - 0.0)), (0.90, 0.53, 0.025), "board"))
        if lod < 2:
            ring = [(np.cos(a) * 0.23, 3.05, s * (L / 2 - 0.40) + np.sin(a) * 0.23) for a in np.linspace(0, 2 * np.pi, [12, 7][lod])[:-1]]
            m.merge(S.sweep(ring, S.circle(0.01, 4), "iron", closed=True))
            m.merge(S.lathe([(2.70, 0.13), (3.05, 0.22)], [10, 6][lod], tag="net", caps=(False, False)).transformed(np.eye(3), (0, 0, s * (L / 2 - 0.40))))
    if lod < 2:  # the volleyball posts and the net across the middle
        for s in (1, -1):
            m.merge(S.lathe([(0.0, 0.05), (2.55, 0.05), (2.58, 0.0)], [8, 5][lod], tag="white").transformed(np.eye(3), (s * (W / 2 - 1.0 + 1.5), 0, 0)))
        m.merge(S.box((0, 2.24 + 0.5, 0), (W / 2 + 0.5, 0.5, 0.004), "net"))
    return {"body": Part(m)}


def _paint_court(P, N, tag, tags, state, col):
    """The lines: the court's edge, the centre line and circle, the keys and three-point arcs, the
    volleyball's attack lines; in white, 5 cm."""
    L, W = COURT["len"], COURT["w"]
    sel = (tag == tags.index("court")) & (N[:, 1] > 0.8)
    x, z = P[:, 0], P[:, 2]
    lw = 0.05
    edge = (np.abs(np.abs(x) - W / 2) < lw / 2) & (np.abs(z) < L / 2) | (np.abs(np.abs(z) - L / 2) < lw / 2) & (np.abs(x) < W / 2)
    centre = (np.abs(z) < lw / 2) & (np.abs(x) < W / 2) | (np.abs(np.hypot(x, z) - 1.8) < lw / 2)
    keys = np.zeros(len(P), bool)
    for s in (1, -1):
        keys |= (np.abs(np.abs(x) - 2.45) < lw / 2) & (s * z > L / 2 - 5.8) & (s * z < L / 2)
        keys |= (np.abs(s * z - (L / 2 - 5.8)) < lw / 2) & (np.abs(x) < 2.45)
        r = np.hypot(x, z - s * (L / 2 - 1.575))
        keys |= (np.abs(r - 6.75) < lw / 2) & (s * z < L / 2) & (s * (z - s * (L / 2 - 1.575)) < 0)
    lines = sel & (edge | centre | keys)
    return np.where(lines[:, None], np.array([0.92, 0.92, 0.90], np.float32), col)


ELEMENTS = {
    "riding_hall": dict(build=riding_hall, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"], lods=3,
                        edge_radius=0.01, close=(-9.0, 4.0, -20.0), tex=2048),
    "sports_court": dict(build=sports_court, materials=materials(), extra=_paint_court, extra_first=True, uv_scale={"court": 3.0},
                         states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.004, close=(0.0, 3.0, -13.5), tex=2048),
}
