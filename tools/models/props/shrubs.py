"""Shrubs and flowers (S177). Cards: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

window_box: geraniums in a zinc window box on its two iron brackets under a sill: the trough, the
earth, the plants' leaf mounds, red flower heads standing over them. The wall's face is z = 0 (the
house +Z), y = 0 the sill's top.
yew_cone: a clipped yew of a formal garden: a cone of dark green on a short trunk, in its square
bed edged with box.
hedge_box: a 1 m module of low box hedge, clipped square, its foot in the earth; modules join along x.
ivy_patch: ivy over a wall: stems climbing and branching, flat clusters of leaves lying on the wall,
denser at the foot. The wall's face is z = 0, the ivy in front of it (-Z), its foot y = 0.

Standing on y = 0 unless said, the front -Z.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part


def materials():
    green = dict(kind="paper", chip=0.0, rusts=False, fades=False)
    return {
        "zinc": Material((0.52, 0.55, 0.55), under=(0.45, 0.47, 0.46), bare=(0.40, 0.42, 0.42), chip=0.2, grain=0.05),
        "iron": Material((0.10, 0.10, 0.11), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.07),
        "earth": Material((0.20, 0.15, 0.11), kind="sand", chip=0.0, rusts=False, grain=0.25),
        "leaf": Material((0.24, 0.42, 0.18), grain=0.15, palette=[(0.24, 0.42, 0.18), (0.20, 0.38, 0.16), (0.28, 0.45, 0.20)], vary=0.05, **green),
        "bloom": Material((0.80, 0.10, 0.10), grain=0.1, palette=[(0.82, 0.10, 0.12), (0.88, 0.20, 0.35), (0.75, 0.08, 0.08)], vary=0.04, **green),
        "yew": Material((0.10, 0.22, 0.12), grain=0.12, vary=0.03, **green),
        "box": Material((0.18, 0.32, 0.14), grain=0.15, vary=0.04, **green),
        "bark": Material((0.32, 0.25, 0.20), kind="wood", chip=0.0, rusts=False, grain=0.12, fades=False),
        "ivy": Material((0.14, 0.26, 0.12), grain=0.15, palette=[(0.14, 0.26, 0.12), (0.18, 0.30, 0.14), (0.12, 0.22, 0.10)], vary=0.05, **green),
        "gravel": Material((0.62, 0.58, 0.50), kind="sand", chip=0.0, rusts=False, grain=0.3),
    }


def _mound(c, r, h, sides, rng, tag, unit):
    """A low lumpy mound of leaves."""
    bumps = rng.uniform(0.8, 1.15, sides)
    m = S.lathe([(0.0, r), (h * 0.5, r * 1.05), (h, r * 0.4), (h * 1.05, 0.0)], sides, turn=rng.uniform(0, 6.28), tag=tag,
                flute=lambda j, y: bumps[j])
    return m.transformed(np.eye(3), c).set_unit(unit)


# --- window_box -------------------------------------------------------------------------------------------
def window_box(lod):
    L, d, h = 0.90, 0.20, 0.17
    rng = np.random.default_rng(5)
    m = Mesh()
    z = -d / 2 - 0.02
    m.merge(S.chamfer_box((0, h / 2 + 0.01, z), (L / 2, h / 2, d / 2), 0.008 if lod == 0 else 0.0, "zinc", edges="top") if lod == 0 else
            S.box((0, h / 2 + 0.01, z), (L / 2, h / 2, d / 2), "zinc"))
    m.merge(S.box((0, h + 0.008, z), (L / 2 - 0.01, 0.004, d / 2 - 0.01), "earth"))
    if lod < 2:
        for x in (-L / 2 + 0.12, L / 2 - 0.12):  # the brackets: an L of flat iron under it, a stay to the wall
            m.merge(S.box((x, 0.004, z), (0.012, 0.004, d / 2 + 0.02), "iron"))
            m.merge(S.sweep([(x, 0.0, -d - 0.02), (x, -0.12, -0.01)], [(-0.012, -0.004), (0.012, -0.004), (0.012, 0.004), (-0.012, 0.004)], "iron", up=(1, 0, 0)))
    n = [5, 3, 2][lod]
    for k in range(n):  # the plants: leaf mounds, the flower heads on stalks over them
        x = -L / 2 + (k + 0.5) * L / n
        m.merge(_mound((x, h + 0.01, z), min(L / n * 0.65, 0.15), 0.16, [7, 5, 4][lod], rng, "leaf", k % 3 + 1))
        if lod < 2:
            for j in range([4, 2][lod]):
                p = np.array([x + rng.uniform(-0.07, 0.07), h + 0.18 + rng.uniform(0, 0.08), z + rng.uniform(-0.06, 0.04)])
                if lod == 0:
                    m.merge(S.sweep([p - np.array([0, 0.12, 0]), p], S.circle(0.004, 3), "leaf"))
                ball = S.lathe([(-0.035, 0.0), (0.0, 0.045), (0.035, 0.0)], 5, turn=j, tag="bloom")
                m.merge(ball.transformed(np.eye(3), p).set_unit(j % 3 + 1))
    return {"body": Part(m)}


# --- yew_cone ----------------------------------------------------------------------------------------------
def yew_cone(lod):
    rng = np.random.default_rng(9)
    m = Mesh()
    sides = [12, 8, 6][lod]
    m.merge(S.lathe([(0.0, 0.08), (0.30, 0.07)], 6, tag="bark", caps=(False, True)))
    cone = S.lathe([(0.25, 0.0), (0.25, 0.55), (0.45, 0.62), (1.4, 0.42), (2.3, 0.15), (2.55, 0.0)], sides, tag="yew",
                   flute=(lambda j, y: 1.0 + 0.025 * np.sin(j * 2.1 + y * 9)) if lod == 0 else None)
    m.merge(cone)
    # the bed: gravel, edged with a low box border
    m.merge(S.box((0, 0.01, 0), (0.85, 0.01, 0.85), "gravel"))
    if lod < 2:
        for k in range(4):
            R = S.rotation((0, 1, 0), k * np.pi / 2)
            m.merge(S.chamfer_box((0, 0.11, 0.80), (0.85, 0.11, 0.07), 0.03, "box", edges="top").transformed(R, (0, 0, 0)) if lod == 0 else
                    S.box((0, 0.11, 0.80), (0.85, 0.11, 0.07), "box").transformed(R, (0, 0, 0)))
    return {"body": Part(m)}


# --- hedge_box ------------------------------------------------------------------------------------------------
def hedge_box(lod):
    m = Mesh()
    hedge = S.chamfer_box((0, 0.22, 0), (0.50, 0.22, 0.20), 0.05, "box", edges="top") if lod == 0 else S.box((0, 0.22, 0), (0.50, 0.22, 0.20), "box")
    if lod == 0:  # its clipped sides not quite flat
        hedge = S.subdivide(hedge, 1)
        hedge.verts = [v + np.array([0, 0.008 * np.sin(v[0] * 23 + v[1] * 17), 0.010 * np.sin(v[0] * 19 - v[1] * 13)]) for v in hedge.verts]
    m.merge(hedge)
    m.merge(S.box((0, 0.005, 0), (0.50, 0.005, 0.26), "earth"))
    return {"body": Part(m)}


# --- ivy_patch -------------------------------------------------------------------------------------------------
def ivy_patch(lod):
    rng = np.random.default_rng(13)
    m = Mesh()
    W, H = 2.0, 3.2
    stems = []
    for k in range(5):  # stems climbing from the foot, wandering, branching once
        x = -W / 2 + 0.2 + k * (W - 0.4) / 4
        pts = [(x, 0.0, -0.02)]
        for j in range(1, 7):
            x += rng.normal(0, 0.12)
            pts.append((np.clip(x, -W / 2, W / 2), H * j / 6 * rng.uniform(0.7, 1.0), -0.02))
        stems.append(pts)
        if lod < 2:
            m.merge(S.sweep(pts, S.circle(0.012, 3), "bark"))
    n = [60, 25, 10][lod]
    unit = 1
    for i in range(n):  # leaf clusters lying flat on the wall, thicker low down
        s = stems[i % len(stems)]
        t = rng.uniform(0, 1) ** 1.6
        a = np.asarray(s[int(t * (len(s) - 1))])
        b = np.asarray(s[min(int(t * (len(s) - 1)) + 1, len(s) - 1)])
        p = a + (b - a) * rng.uniform() + np.array([rng.normal(0, 0.15), 0, 0])
        r = rng.uniform(0.15, 0.30) * (1.3 - 0.5 * t)
        k = [7, 5, 4][lod]
        outline = [(np.cos(2 * np.pi * j / k) * r * rng.uniform(0.75, 1.1), np.sin(2 * np.pi * j / k) * r * rng.uniform(0.6, 0.9)) for j in range(k)]
        cl = S.extrude(outline, 0.04 + 0.03 * rng.uniform(), 0.02 if lod == 0 else 0.0, "ivy", origin=(p[0], p[1] + 0.1, -0.005), right=(1, 0, 0), up=(0, 1, 0))
        m.merge(cl.set_unit(unit % 3 + 1))
        unit += 1
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.0)

ELEMENTS = {
    "window_box": dict(build=window_box, materials=materials(), close=(0.0, 0.2, -0.1), **_SPEC),
    "yew_cone": dict(build=yew_cone, materials=materials(), close=(0.0, 1.0, -0.5), **_SPEC),
    "hedge_box": dict(build=hedge_box, materials=materials(), close=(0.0, 0.3, -0.2), states=_SPEC["states"], lods=2, edge_radius=0.0),
    "ivy_patch": dict(build=ivy_patch, materials=materials(), close=(0.0, 0.8, 0.0), **_SPEC),
}
