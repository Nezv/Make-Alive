"""Clutter on the floors (S196). Cards: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

papers: a 1.2 m patch of an office's floor after the panic: sheets lying flat, curled and
crumpled, an open folder spilling them, a paper cup on its side, a phone face down, a pen. The
print on the sheets waits for round 3 (rows of text per sheet, no brand).
shards: broken window glass on a floor: a spray of flat shards, a few large, many small, some
standing on an edge, thrown one way (from -Z to +Z).
picture_frame: a fallen frame: face down at an angle against a wall, its back board and hanger,
its glass cracked out in front of it, a corner of the picture showing.

Lying on y = 0 (the floor), the front -Z.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part


def materials():
    return {
        "paper": Material((0.92, 0.91, 0.88), kind="paper", chip=0.0, rusts=False, grain=0.05,
                          palette=[(0.93, 0.92, 0.89), (0.90, 0.90, 0.86), (0.88, 0.86, 0.80), (0.86, 0.88, 0.90)], vary=0.02),
        "folder": Material((0.70, 0.22, 0.16), kind="paper", chip=0.0, rusts=False, grain=0.06,
                           palette=[(0.70, 0.22, 0.16), (0.20, 0.35, 0.55), (0.75, 0.62, 0.20)]),
        "cup": Material((0.88, 0.86, 0.80), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "phone": Material((0.07, 0.07, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "pen": Material((0.15, 0.25, 0.55), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "glass": Material((0.55, 0.62, 0.62), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "frame": Material((0.45, 0.32, 0.18), under=(0.5, 0.4, 0.3), bare=(0.5, 0.4, 0.3), kind="wood", chip=0.6, grain=0.08),
        "board": Material((0.55, 0.45, 0.32), kind="paper", chip=0.0, rusts=False, grain=0.10),
        "picture": Material((0.40, 0.48, 0.35), kind="paper", chip=0.0, rusts=False, grain=0.06),
        "wire": Material((0.5, 0.5, 0.5), under=(0.4, 0.4, 0.4), bare=(0.4, 0.3, 0.2), chip=0.0, grain=0.04),
    }


def _sheet(c, yaw, lod, unit, curl=0.0, crumple=0.0, rng=None, size=(0.21, 0.297)):
    """An A4 sheet lying at c (x, z), turned by yaw; curled up at one end, or crumpled."""
    w, l = size
    n = [4, 2, 1][lod]
    m = Mesh()
    pts = []
    for j in range(n + 1):
        for i in range(n + 1):
            u, v = i / n - 0.5, j / n - 0.5
            y = 0.0008 + curl * max(0.0, v) ** 2 * 0.6
            if crumple and rng is not None:
                y += crumple * rng.uniform(0, 1)
            pts.append((u * w, y, v * l))
    base = m.add([np.array(p) for p in pts])
    for j in range(n):
        for i in range(n):
            a = base + j * (n + 1) + i
            m.face([a, a + n + 1, a + n + 2, a + 1], "paper", unit)
    R = S.rotation((0, 1, 0), yaw)
    return m.transformed(R, (c[0], 0.0, c[1]))


def papers(lod):
    rng = np.random.default_rng(7)
    m = Mesh()
    k = [16, 9, 4][lod]
    for i in range(k):
        c = (rng.uniform(-0.5, 0.5), rng.uniform(-0.5, 0.5))
        curl = rng.uniform(0.0, 0.12) if i % 3 == 0 else 0.0
        m.merge(_sheet(c, rng.uniform(0, np.pi), lod, i % 4 + 1, curl=curl))
    if lod < 2:
        # crumpled balls
        for i in range([3, 1][lod]):
            ball = S.lathe([(0.0, 0.0), (0.012, 0.03), (0.035, 0.035), (0.06, 0.02), (0.065, 0.0)], 6, turn=i,
                           flute=lambda j, y: 1.0 + 0.25 * np.sin(j * 2.3 + y * 60), tag="paper")
            m.merge(ball.transformed(S.rotation((1, 0, 0), 0.4 * i), (rng.uniform(-0.4, 0.4), 0.0, rng.uniform(-0.4, 0.4))).set_unit(2))
        # the open folder: two covers, sheets spilling from it
        fc = (-0.25, 0.20)
        for s in (1, -1):
            cover = S.box((s * 0.115, 0.0015, 0), (0.115, 0.0015, 0.16), "folder").transformed(S.rotation((0, 0, 1), -s * 0.06), (0, 0, 0))
            m.merge(cover.transformed(S.rotation((0, 1, 0), 0.5), (fc[0], 0.0, fc[1])).set_unit(1))
        # a paper cup on its side, a phone face down, a pen
        cup = S.lathe([(0.0, 0.0), (0.0, 0.028), (0.095, 0.042), (0.10, 0.044)], [10, 6][lod], tag="cup", caps=(True, False))
        m.merge(S.along(cup, (1, 0, 0.3), (0.30, 0.044, -0.25)))
        m.merge(S.bevel_box((0.05, 0.0045, -0.35), (0.036, 0.0045, 0.075), 0.004, "phone").transformed(S.rotation((0, 1, 0), 0.8), (0, 0, 0)) if lod == 0 else
                S.box((0.05, 0.0045, -0.35), (0.036, 0.0045, 0.075), "phone"))
        m.merge(S.along(S.lathe([(0.0, 0.004), (0.13, 0.004), (0.14, 0.0)], 6, tag="pen"), (1, 0, -0.6), (-0.10, 0.004, 0.40)))
    return {"body": Part(m)}


def _shard(rng, size):
    """A flat shard: a jagged polygon of 3 to 6 points."""
    n = rng.integers(3, 7)
    a = np.sort(rng.uniform(0, 2 * np.pi, n))
    r = size * rng.uniform(0.5, 1.0, n)
    return [(np.cos(t) * rr, np.sin(t) * rr) for t, rr in zip(a, r)]


def shards(lod):
    rng = np.random.default_rng(3)
    m = Mesh()
    k = [40, 18, 8][lod]
    for i in range(k):
        size = 0.12 if i < 4 else rng.uniform(0.015, 0.05)
        z = rng.normal(0.0, 0.35) + 0.15
        x = rng.normal(0.0, 0.30)
        poly = _shard(rng, size)
        sh = S.extrude(poly, 0.004, 0.0, "glass", origin=(0, 0.0, 0), right=(1, 0, 0), up=(0, 0, 1))
        tilt = S.rotation((1, 0, 0), 1.2) if (i % 9 == 4 and lod < 2) else np.eye(3)    # a few standing on an edge
        m.merge(sh.transformed(S.rotation((0, 1, 0), rng.uniform(0, 2 * np.pi)) @ tilt, (x, 0.0, z)))
    return {"body": Part(m)}


def picture_frame(lod):
    w, h, t = 0.50, 0.40, 0.025
    m = Mesh()
    lean = np.radians(70)          # leaning back against the wall (z = 0), its foot out on the floor
    R = S.rotation((1, 0, 0), -(np.pi / 2 - lean))
    fr = Mesh()
    for (ax, ay), (bx, by) in (((-w / 2, 0.0), (w / 2, 0.0)), ((w / 2, 0.0), (w / 2, h)), ((w / 2, h), (-w / 2, h)), ((-w / 2, h), (-w / 2, 0.0))):
        cx, cy = (ax + bx) / 2, (ay + by) / 2
        hx, hy = max(abs(bx - ax) / 2, 0.025), max(abs(by - ay) / 2, 0.025)
        fr.merge(S.chamfer_box((cx, cy, 0), (hx, hy, t / 2), 0.006, "frame", edges="front") if lod < 2 else S.box((cx, cy, 0), (hx, hy, t / 2), "frame"))
    fr.merge(S.box((0, h / 2, t / 2 - 0.003), (w / 2 - 0.02, h / 2 - 0.02, 0.003), "board"))   # the back board, facing out
    fr.merge(S.box((0, h / 2, -t / 2 + 0.002), (w / 2 - 0.025, h / 2 - 0.025, 0.001), "picture"))   # the picture, face to the wall
    if lod == 0:
        fr.merge(S.sweep([(-0.12, h * 0.75, t / 2 + 0.002), (0.0, h * 0.82, t / 2 + 0.002), (0.12, h * 0.75, t / 2 + 0.002)], S.circle(0.0015, 3), "wire"))
    # face down: turned to show its back, leaning on the wall
    m.merge(fr.transformed(S.rotation((0, 1, 0), np.pi) @ R, (0.0, 0.0, -np.cos(lean) * h - 0.02)))
    # its glass, fallen out in pieces in front of it
    rng = np.random.default_rng(9)
    for i in range([10, 5, 2][lod]):
        poly = _shard(rng, rng.uniform(0.03, 0.10))
        sh = S.extrude(poly, 0.003, 0.0, "glass", origin=(0, 0, 0), right=(1, 0, 0), up=(0, 0, 1))
        m.merge(sh.transformed(S.rotation((0, 1, 0), rng.uniform(0, 6.28)), (rng.normal(0, 0.15), 0.0, -0.25 - abs(rng.normal(0, 0.12)))))
    return {"body": Part(m)}


# --- food_litter --------------------------------------------------------------------------------------------
def _pouch(c, size, yaw, lod, unit):
    """A crisp packet or a wrapper: a pillow, crimped flat at both ends."""
    l, w, h = size
    nx, nr = [6, 4, 2][lod], [8, 6, 4][lod]
    rings = []
    for x in np.linspace(-l / 2, l / 2, nx):
        s = max(0.0, 1.0 - abs(2 * x / l) ** 4) ** 0.5
        ring = [(x, h / 2 * s * np.sin(a) + h / 2, w / 2 * (0.85 + 0.15 * s) * np.cos(a)) for a in np.linspace(0, 2 * np.pi, nr + 1)[:-1]]
        rings.append(ring)
    m = Mesh()
    m.loft(rings, "wrapper", caps=(True, True))
    return m.transformed(S.rotation((0, 1, 0), yaw), c).set_unit(unit)


def food_litter(lod):
    rng = np.random.default_rng(12)
    m = Mesh()
    # crisp packets and wrappers
    for i in range([6, 4, 2][lod]):
        m.merge(_pouch((rng.uniform(-0.5, 0.5), 0.0, rng.uniform(-0.4, 0.4)), (rng.uniform(0.15, 0.26), rng.uniform(0.10, 0.17), 0.035), rng.uniform(0, np.pi), lod, i % 4 + 1))
    # cans on their sides, one crushed; a takeaway cup and its lid
    for i, (x, z, crush) in enumerate(((0.30, -0.20, 0.0), (-0.35, 0.25, 0.5), (0.05, 0.35, 0.0))[: [3, 2, 1][lod]]):
        can = S.lathe([(0.0, 0.0), (0.0, 0.026), (0.004, 0.033), (0.11, 0.033), (0.116, 0.027), (0.116, 0.0)], [10, 6, 4][lod], tag="can",
                      flute=(lambda j, y, c=crush: 1.0 - c * 0.5 * (1 + np.cos(j * 1.7)) * (0.03 < y < 0.09)) if lod == 0 else None)
        m.merge(S.along(can, (np.cos(i * 1.3), 0, np.sin(i * 1.3)), (x, 0.033 * (1 - crush * 0.4), z)).set_unit(i + 1))
    if lod < 2:
        cup = S.lathe([(0.0, 0.0), (0.0, 0.03), (0.12, 0.045), (0.125, 0.047)], [10, 6][lod], tag="cup", caps=(True, False))
        m.merge(S.along(cup, (0.8, 0, -0.6), (-0.15, 0.047, -0.30)))
        m.merge(S.lathe([(0.0, 0.048), (0.008, 0.048), (0.012, 0.0)], [10, 6][lod], tag="phone").transformed(S.rotation((1, 0, 0), 1.4), (0.15, 0.05, 0.10)))
        # a plastic bag, crumpled, half flat
        bag = S.lathe([(0.0, 0.0), (0.02, 0.10), (0.06, 0.14), (0.10, 0.12), (0.12, 0.06), (0.13, 0.0)], [9, 6][lod], tag="bag",
                      flute=lambda j, y: 1.0 + 0.25 * np.sin(j * 2.3 + y * 40))
        m.merge(bag.transformed(np.diag([1.4, 0.6, 1.0]), (-0.55, 0.0, -0.05)))
        # a pizza box, its lid open
        m.merge(S.box((0.45, 0.02, 0.30), (0.17, 0.02, 0.17), "board"))
        m.merge(S.box((0.0, 0.0, 0.0), (0.17, 0.004, 0.17), "board").transformed(S.rotation((1, 0, 0), -1.9), (0.45, 0.04, 0.47)))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "food_litter": dict(build=food_litter, materials=dict(materials(), **{
        "wrapper": Material((0.80, 0.15, 0.12), kind="paper", chip=0.0, rusts=False, grain=0.04,
                            palette=[(0.80, 0.15, 0.12), (0.92, 0.75, 0.10), (0.15, 0.40, 0.75), (0.20, 0.60, 0.25)], vary=0.04),
        "can": Material((0.70, 0.12, 0.12), under=(0.7, 0.7, 0.72), bare=(0.72, 0.73, 0.74), chip=0.4, rusts=False, grain=0.03,
                        palette=[(0.70, 0.12, 0.12), (0.15, 0.30, 0.60), (0.75, 0.75, 0.76)]),
        "bag": Material((0.90, 0.90, 0.88), kind="rubber", chip=0.0, rusts=False, grain=0.04)}),
        edge_radius=0.001, close=(0.0, 0.05, 0.0), **_SPEC),
    "papers": dict(build=papers, materials=materials(), edge_radius=0.001, close=(0.0, 0.0, 0.0), **_SPEC),
    "shards": dict(build=shards, materials=materials(), edge_radius=0.001, close=(0.0, 0.0, 0.1), **_SPEC),
    "picture_frame": dict(build=picture_frame, materials=materials(), edge_radius=0.002, close=(0.0, 0.2, -0.2), **_SPEC),
}
