"""Trees (S174). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

plane_tree: the square's and the quay's plane tree (square, fork, bare): a trunk flaring at its
roots, leaning a little, forking at 3.6 m into three limbs that branch twice more, the crown of
leaf clusters (faceted lumps, seeded) round the branch ends, 18 m tall and 14 m across; the bark
painted in the mottled patches of grey, olive and cream (bark).
plane_pollard: the pollarded plane of the squares (quay_1900's young ones grown old): a shorter
trunk, five thick limbs cut back to knuckles, a tuft of shoots and leaves on each.
chestnut_old (S175): the old horse chestnut: thick and short, a low dome, white candles in spring.
street_lime (S176): a young lime in a street's pit, staked.

Seeded (`SEED`), so every peer grows the same tree; the map turns and scales them. Standing on
y = 0, the trunk at x = z = 0.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

SEED = 21


def materials():
    return {
        "bark": Material((0.55, 0.53, 0.46), kind="wood", chip=0.0, rusts=False, grain=0.12, fades=False),
        "leaves": Material((0.28, 0.40, 0.18), kind="paper", chip=0.0, rusts=False, grain=0.18, fades=False,
                           palette=[(0.28, 0.40, 0.18), (0.24, 0.36, 0.15), (0.32, 0.44, 0.20), (0.26, 0.38, 0.19)], vary=0.06),
        "knuckle": Material((0.50, 0.47, 0.40), kind="wood", chip=0.0, rusts=False, grain=0.15, fades=False),
        "flower": Material((0.93, 0.92, 0.86), kind="paper", chip=0.0, rusts=False, grain=0.1, fades=False),
        "stake": Material((0.62, 0.50, 0.34), kind="wood", chip=0.0, rusts=False, grain=0.15),
    }


def _branch(m, a, b, r0, r1, sides, bend, rng, tag="bark"):
    """A limb from a to b tapering r0 to r1, bowed a little sideways (`bend` of its length)."""
    a, b = np.asarray(a, np.float64), np.asarray(b, np.float64)
    d = b - a
    side = np.cross(d, rng.normal(size=3))
    side /= max(np.linalg.norm(side), 1e-9)
    n = 4 if sides > 5 else 2
    pts = [a + d * t + side * np.linalg.norm(d) * bend * np.sin(np.pi * t) for t in np.linspace(0, 1, n + 1)]
    m.merge(S.sweep(pts, S.circle(1.0, sides), tag, scale=lambda i: r0 + (r1 - r0) * i / n))


def _lump(c, r, rng, unit, lod):
    """A leaf cluster: a lumpy, flattened ball."""
    sides = [7, 5, 4][min(lod, 2)]
    bumps = rng.uniform(0.80, 1.15, (sides, 6))
    prof = [(-r * 0.95, 0.0), (-r * 0.70, r * 0.70), (-r * 0.1, r), (r * 0.40, r * 0.88), (r * 0.80, r * 0.45), (r * 0.95, 0.0)]
    rows = {round(y, 6): k for k, (y, _) in enumerate(prof)}
    ball = S.lathe(prof, sides, turn=rng.uniform(0, 6.28), tag="leaves",
                   flute=lambda j, y: bumps[j % sides, rows.get(round(y, 6), 0) % 6])
    return ball.transformed(np.eye(3), c).set_unit(unit)


def _grow(m, ends, base, top, r, depth, lod, rng, spread, length):
    """Branches from `base` out along `top` (a direction), splitting `depth` more times."""
    sides = [8, 5, 4, 3][lod]
    d = np.asarray(top, np.float64)
    d /= np.linalg.norm(d)
    tip = np.asarray(base) + d * length
    _branch(m, base, tip, r, r * 0.62, sides if depth > 0 else max(3, sides - 2), 0.06, rng)
    if depth == 1 and lod < 2:  # leaves along the last limbs too, so the crown comes down
        ends.append((np.asarray(base) + d * length * 0.5, length * 0.8))
    if depth == 0 or (lod >= 2 and depth == 1):
        ends.append((tip, length))
        return
    kids = 3 if depth > 1 else 2
    for k in range(kids):
        a = 2 * np.pi * k / kids + rng.uniform(-0.5, 0.5)
        out = np.array([np.cos(a), 0.0, np.sin(a)])
        nd = d * 0.85 + out * spread + np.array([0, 0.30, 0])
        _grow(m, ends, tip, nd, r * 0.62, depth - 1, lod, rng, spread * 0.9, length * rng.uniform(0.55, 0.7))


def _trunk(m, h, r, lean, lod):
    sides = [12, 8, 5, 4][lod]
    m.merge(S.lathe([(0.0, r * 1.55), (0.25, r * 1.3), (0.7, r * 1.08), (1.2, r)], sides, tag="bark", caps=(False, False),
                    flute=(lambda j, y: 1.0 + (0.18 if j % 3 == 0 else 0.0) * max(0.0, 1.0 - y / 0.7)) if lod < 2 else None))  # the root buttresses
    top = np.array([lean, h, lean * 0.4])
    pts = [np.array([0.0, 1.2, 0.0]), np.array([lean * 0.3, h * 0.5, lean * 0.1]), top]
    m.merge(S.sweep(pts, S.circle(1.0, sides), "bark", scale=lambda i: r * (1.0 - 0.18 * i / 2)))
    return top


def plane_tree(lod):
    rng = np.random.default_rng(SEED)
    m = Mesh()
    top = _trunk(m, 3.6, 0.52, 0.25, lod)
    ends = []
    depth = [3, 2, 1, 1][lod]
    for k in range(3):  # the fork: three limbs up and out
        a = 2 * np.pi * k / 3 + 0.4
        d = np.array([np.cos(a) * 0.45, 1.0, np.sin(a) * 0.45])
        _grow(m, ends, top, d, 0.34, depth, lod, rng, 0.42, 5.0 if lod < 3 else 6.5)
    # the crown: a leaf cluster on every branch end, more where they are
    unit = 1
    if lod == 3:  # far: one lump for the whole crown
        m.merge(_lump(np.array([0.3, 11.0, 0.1]), 6.5, rng, 1, lod))
        return {"body": Part(m)}
    for tip, length in ends:
        r = [2.0, 2.6, 4.2][lod] * (0.8 + 0.4 * rng.uniform())
        m.merge(_lump(tip + np.array([0, r * 0.3, 0]), r, rng, unit % 4 + 1, lod))
        unit += 1
    return {"body": Part(m)}


def plane_pollard(lod):
    rng = np.random.default_rng(SEED + 1)
    m = Mesh()
    top = _trunk(m, 3.6, 0.36, 0.10, lod)
    sides = [8, 5, 4, 3][lod]
    n = 5
    for k in range(n):
        a = 2 * np.pi * k / n + rng.uniform(-0.3, 0.3)
        d = np.array([np.cos(a) * 0.8, 1.0, np.sin(a) * 0.8])
        d /= np.linalg.norm(d)
        tip = top + d * rng.uniform(1.6, 2.2)
        _branch(m, top, tip, 0.18, 0.13, sides, 0.08, rng)
        # the knuckle where it is cut back every winter, a tuft of shoots, leaves round them
        m.merge(S.lathe([(-0.18, 0.0), (-0.12, 0.17), (0.08, 0.22), (0.22, 0.12), (0.26, 0.0)], sides, tag="knuckle").transformed(np.eye(3), tip))
        if lod < 3:
            if lod == 0:
                for j in range(4):
                    sd = d + rng.normal(0, 0.35, 3) + np.array([0, 0.6, 0])
                    _branch(m, tip + np.array([0, 0.15, 0]), tip + sd / np.linalg.norm(sd) * 1.4, 0.03, 0.012, 3, 0.1, rng)
            m.merge(_lump(tip + np.array([0, 1.2, 0]) + d * 0.3, [1.3, 1.5, 1.8][lod], rng, k % 4 + 1, lod))
    if lod == 3:
        m.merge(_lump(top + np.array([0, 2.4, 0]), 3.0, rng, 1, lod))
    return {"body": Part(m)}


def chestnut_old(lod):
    """The old horse chestnut (in_flower, bare, allee_1900): a thick short trunk, five limbs
    spreading wide and low, a dome crown coming down almost to the ground, white candles of flowers
    standing on it in spring."""
    rng = np.random.default_rng(SEED + 2)
    m = Mesh()
    top = _trunk(m, 2.6, 0.75, 0.15, lod)
    ends = []
    depth = [2, 2, 1, 1][lod]
    for k in range(5):
        a = 2 * np.pi * k / 5 + 0.3
        d = np.array([np.cos(a) * 0.9, 0.85, np.sin(a) * 0.9])
        _grow(m, ends, top, d, 0.36, depth, lod, rng, 0.55, 4.6 if lod < 3 else 5.5)
    if lod == 3:
        m.merge(_lump(np.array([0.0, 7.5, 0.0]), 7.0, rng, 1, lod))
        return {"body": Part(m)}
    for tip, length in ends:
        r = [2.6, 2.8, 4.4][lod] * (0.8 + 0.4 * rng.uniform())
        c = tip + np.array([0, r * 0.1, 0])
        m.merge(_lump(c, r, rng, rng.integers(1, 5), lod))
        if lod == 0:  # the candles: white cones standing on the crown's upper side
            for _ in range(6):
                a = rng.uniform(0, 2 * np.pi)
                e = rng.uniform(0.3, 1.1)
                p = c + np.array([np.cos(a) * np.cos(e), np.sin(e) * 0.9, np.sin(a) * np.cos(e)]) * r * 0.95
                m.merge(S.lathe([(-0.05, 0.11), (0.36, 0.0)], 4, turn=a, tag="flower").transformed(np.eye(3), p))
    return {"body": Part(m)}


def street_lime(lod):
    """A young lime planted in a street's pit: a straight trunk, a narrow oval crown, two stakes
    with their ties, the grille's ring round its foot."""
    rng = np.random.default_rng(SEED + 3)
    m = Mesh()
    sides = [8, 6, 4, 3][lod]
    m.merge(S.lathe([(0.0, 0.10), (0.3, 0.085), (3.2, 0.065), (3.4, 0.05)], sides, tag="bark", caps=(False, True)))
    ends = []
    for k in range(4):
        a = 2 * np.pi * k / 4 + 0.4
        d = np.array([np.cos(a) * 0.35, 1.0, np.sin(a) * 0.35])
        _grow(m, ends, (0, 3.2, 0), d, 0.05, [1, 1, 1, 1][lod], lod, rng, 0.3, 1.6)
    if lod == 3:
        m.merge(_lump(np.array([0.0, 5.3, 0.0]), 2.0, rng, 1, lod).transformed(np.diag([1.0, 1.4, 1.0]), (0, -2.1, 0)))
        return {"body": Part(m)}
    for tip, length in ends:
        r = [1.2, 1.3, 1.8][lod]
        m.merge(_lump(tip, r, rng, rng.integers(1, 5), lod).transformed(np.diag([1.0, 1.35, 1.0]), (0, -tip[1] * 0.35, 0)))
    if lod < 2:  # the stakes and their ties
        for x in (-0.25, 0.25):
            m.merge(S.lathe([(0.0, 0.03), (1.8, 0.03), (1.85, 0.0)], 5, tag="stake").transformed(np.eye(3), (x, 0, 0)))
        m.merge(S.box((0, 1.5, 0), (0.25, 0.015, 0.012), "stake"))
    return {"body": Part(m)}


# --- the bark's patches ----------------------------------------------------------------------------------
GREY = np.array([0.56, 0.55, 0.49], np.float32)
OLIVE = np.array([0.46, 0.45, 0.32], np.float32)
CREAM = np.array([0.80, 0.77, 0.64], np.float32)


def _paint_bark(P, N, tag, tags, state, col):
    """The plane's bark: plates shed in patches, grey over olive over cream (bark.jpg)."""
    sel = (tag == tags.index("bark")) | (tag == tags.index("knuckle"))
    q = P * np.array([7.0, 3.2, 7.0], np.float32)       # patches taller than wide
    n1 = np.sin(q[:, 0] * 1.7 + np.sin(q[:, 1] * 1.3)) + np.sin(q[:, 2] * 1.9 + q[:, 1] * 0.7) + np.sin(q[:, 1] * 2.3 + q[:, 0])
    n2 = np.sin(q[:, 0] * 3.1 - q[:, 1] * 1.1) + np.sin(q[:, 2] * 2.7 + q[:, 1] * 1.9)
    out = np.where((n1 > 0.9)[:, None], CREAM, np.where((n2 > 0.6)[:, None], OLIVE, GREY))
    low = (P[:, 1] < 1.2)[:, None]       # the foot stays dark and rough
    out = np.where(low & (n1 < 1.4)[:, None], GREY * 0.85, out)
    return np.where(sel[:, None], out, col)


def _paint_furrowed(P, N, tag, tags, state, col):
    """Old furrowed bark: dark grey-brown, its ridges paler, running up and twisting a little."""
    sel = tag == tags.index("bark")
    a = np.arctan2(P[:, 2], P[:, 0])
    ridge = np.sin(a * 23 + P[:, 1] * 1.5 + np.sin(P[:, 1] * 3.0) * 0.8) > 0.35
    out = np.where(ridge[:, None], np.array([0.44, 0.40, 0.34], np.float32), np.array([0.26, 0.23, 0.20], np.float32))
    moss = (P[:, 2] > 0.1) & (P[:, 1] < 2.0) & (np.sin(P[:, 0] * 9 + P[:, 1] * 5) > 0.3)     # the north side (+Z) green at the foot
    out = np.where(moss[:, None], np.array([0.30, 0.36, 0.18], np.float32), out)
    return np.where(sel[:, None], out, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=4, extra=_paint_bark, extra_first=True, edge_radius=0.0)
_OLD = dict(_SPEC, extra=_paint_furrowed)

ELEMENTS = {
    "plane_tree": dict(build=plane_tree, materials=materials(), close=(0.0, 2.0, 0.0), **_SPEC),
    "plane_pollard": dict(build=plane_pollard, materials=materials(), close=(0.0, 4.5, 0.0), **_SPEC),
    "chestnut_old": dict(build=chestnut_old, materials=materials(), close=(0.0, 2.0, 0.0), **_OLD),
    "street_lime": dict(build=street_lime, materials=materials(), close=(0.0, 1.5, 0.0), **_OLD),
}
