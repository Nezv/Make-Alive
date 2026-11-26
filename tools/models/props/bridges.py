"""Bridges over the river (S165). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

bridge_stone: the old stone road bridge (pont_neuf): three elliptical arches on two piers, the
piers' pointed cutwaters rising into half-round bays in the parapet, each with its stone bench;
the archivolt round every arch, a cornice on corbels with a carved mask every few metres, the
parapet; the road between kerbs and two pavements of flags. Built as a module of the river's width.
bridge_foot: the early cast-iron footbridge (arts): one shallow span between stone abutments, five
iron arch ribs with rings in their spandrels, cross-bracing, a deck of oak planks, the iron railing
on both sides with a lantern post at each end.

y = 0 is the deck's surface (the road for the stone bridge), the water at WATER below it; the bridge
runs along X from bank to bank, its faces look -Z (downstream) and +Z.
"""
import numpy as np

import shapes as S
import surfaces as F
from poly import Mesh
from props import Material, Part

STONE = dict(span=10.0, rise=4.6, pier=3.0, width=12.0, road=8.0, water=-6.2, cornice=-0.45, parapet=1.0, bay=1.6)
FOOT = dict(span=24.0, rise=2.4, width=5.0, water=-4.5, ribs=5, rail=1.05)


def materials():
    return {
        "stone": Material((0.74, 0.70, 0.62), kind="stone", chip=0.0, rusts=False, grain=0.12, sheds=True,
                          pattern=F.Bond("ashlar", seed=5)),
        "voussoir": Material((0.78, 0.74, 0.66), kind="stone", chip=0.0, rusts=False, grain=0.10),
        "carved": Material((0.70, 0.66, 0.58), kind="stone", chip=0.0, rusts=False, grain=0.16),
        "asphalt": Material((0.20, 0.20, 0.21), kind="concrete", chip=0.0, rusts=False, grain=0.10, fades=False),
        "flags": Material((0.58, 0.56, 0.52), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "kerb": Material((0.50, 0.50, 0.49), kind="stone", chip=0.0, rusts=False, grain=0.10),
        "iron": Material((0.17, 0.22, 0.20), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.06, fixing=True),
        "plank": Material((0.48, 0.38, 0.27), kind="wood", chip=0.0, rusts=False, grain=0.20,
                          palette=[(0.48, 0.38, 0.27), (0.44, 0.35, 0.25), (0.52, 0.42, 0.30), (0.42, 0.34, 0.24)], vary=0.06),
        "lamp": Material((0.85, 0.80, 0.62), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.82, 0.52)),
    }


# --- bridge_stone ------------------------------------------------------------------------------------------
def _arch_pts(x0, span, rise, y0, n):
    """An elliptical arch's intrados from its left springing at (x0, y0) over to the right."""
    return [(x0 + span / 2 - np.cos(a) * span / 2, y0 + np.sin(a) * rise) for a in np.linspace(0, np.pi, n + 1)]


def _stone_layout():
    sp, pw = STONE["span"], STONE["pier"]
    L = 3 * sp + 2 * pw
    arches = [-L / 2 + k * (sp + pw) for k in range(3)]       # each arch's left springing x
    piers = [a + sp + pw / 2 for a in arches[:2]]               # the piers' middles
    return L, arches, piers


def bridge_stone(lod):
    sp, rise, pw, W, rd = STONE["span"], STONE["rise"], STONE["pier"], STONE["width"], STONE["road"]
    wy, cy, ph, bay = STONE["water"], STONE["cornice"], STONE["parapet"], STONE["bay"]
    L, arches, piers = _stone_layout()
    spring = cy - 0.35 - rise                                   # the crown 0.35 under the cornice
    n = [20, 10, 6][lod]
    m = Mesh()
    # the body: the elevation (waterline, the arches cut up into it, the cornice's foot) pushed through the bridge's width
    elev = [(-L / 2, wy - 0.5)]
    for x0 in arches:
        elev += [(x0, wy - 0.5), (x0, spring)] + _arch_pts(x0, sp, rise, spring, n)[1:-1] + [(x0 + sp, spring), (x0 + sp, wy - 0.5)]
    elev += [(L / 2, wy - 0.5), (L / 2, cy), (-L / 2, cy)]
    m.merge(S.extrude(elev, W, 0.0, "stone", origin=(0, 0, W / 2), right=(1, 0, 0), up=(0, 1, 0)))
    # the archivolts: a band of voussoirs proud of each face round every arch
    if lod < 2:
        for x0 in arches:
            pts = _arch_pts(x0, sp, rise, spring, n)
            for s in (1, -1):
                path = [(x, y, s * (W / 2 + 0.04)) for x, y in pts]
                m.merge(S.sweep(path, [(-0.0, -0.04), (0.55, -0.04), (0.55, 0.04), (0.0, 0.04)], "voussoir", up=(0, 0, s)))
    # the piers' cutwaters: pointed in plan, rising from the water to a cone, then a half-round bay to the cornice
    for xp in piers:
        for s in (1, -1):
            z0 = s * W / 2
            cut = [(-pw / 2, 0.0), (pw / 2, 0.0), (0.0, s * 1.8)]
            m.merge(S.extrude([(x, z) for x, z in cut], spring + 1.2 - (wy - 0.5), 0.0, "stone",
                              origin=(xp, wy - 0.5, z0), right=(1, 0, 0), up=(0, 0, 1)))     # pushed up from under the water
            # the cap: a half pyramid over the point, the half-round turret rising to the bay
            m.merge(S.lathe([(spring + 1.2, bay * 1.02), (spring + 1.55, bay * 0.98)], [16, 10, 6][lod], tag="stone", caps=(True, False))
                    .transformed(np.eye(3), (xp, 0, z0)))
            half = S.lathe([(spring + 1.55, bay), (cy, bay)], [16, 10, 6][lod], tag="stone", caps=(False, False))
            half = S.clip(half.transformed(np.eye(3), (xp, 0, z0)), (xp, 0, z0), (0, 0, -s), cap_tag="stone")
            m.merge(half)
    # the cornice on its corbels, its masks; the parapet along both faces, out round the bays; the benches
    co = 0.28
    for s in (1, -1):
        # the cornice and parapet follow the face, bulging round each bay
        line = [(-L / 2, s * (W / 2 + co))]
        for xp in piers:
            r = bay + co
            for a in np.linspace(np.pi, 0, [14, 8, 4][lod] + 1):
                line.append((xp + np.cos(a) * r, s * (W / 2 + np.sin(a) * r)))
        line.append((L / 2, s * (W / 2 + co)))
        cornice = [(x, cy + 0.0, z) for x, z in line]
        m.merge(S.sweep(cornice, [(-0.0, 0.0), (0.12, 0.0), (0.12, 0.45), (-0.30, 0.45), (-0.30, 0.30)] if s > 0 else
                        [(0.0, 0.0), (-0.12, 0.0), (-0.12, 0.45), (0.30, 0.45), (0.30, 0.30)], "stone", up=(0, 1, 0)))
        par = [(x, cy + 0.45, z - s * 0.10) for x, z in line]
        m.merge(S.sweep(par, [(-0.22, 0.0), (0.22, 0.0), (0.22, ph), (0.20, ph + 0.06), (-0.20, ph + 0.06), (-0.22, ph)], "stone", up=(0, 1, 0)))
        if lod == 0:
            k = 0
            for x in np.arange(-L / 2 + 0.6, L / 2, 0.75):
                if any(abs(x - xp) < bay + co + 0.2 for xp in piers):
                    continue
                m.merge(S.box((x, cy - 0.12, s * (W / 2 + 0.10)), (0.09, 0.12, 0.10), "carved"))     # a corbel
                if k % 4 == 2:  # a mask: a rounded face between the corbels
                    face = S.lathe([(-0.18, 0.0), (-0.16, 0.12), (0.0, 0.17), (0.16, 0.12), (0.18, 0.0)], 8, tag="carved")
                    m.merge(S.along(face, (0, 0, s), (x + 0.37, cy - 0.20, s * (W / 2 + 0.02))))
                k += 1
        if lod < 2:
            for xp in piers:  # the bench round the inside of each bay
                seat = [(xp + np.cos(a) * (bay - 0.45), cy + 0.45 + 0.45, s * (W / 2 + np.sin(a) * (bay - 0.45))) for a in np.linspace(np.pi * 0.95, np.pi * 0.05, [10, 5][lod])]
                m.merge(S.sweep(seat, [(-0.22, -0.45), (0.22, -0.45), (0.22, 0.0), (-0.22, 0.0)], "stone", up=(0, 1, 0)))
    # the deck: road, kerbs, pavements of flags, the bays' floors
    m.merge(S.box((0, cy / 2, 0), (L / 2, -cy / 2, rd / 2), "asphalt"))
    for s in (1, -1):
        zc = s * (rd / 2 + (W / 2 - rd / 2) / 2)
        m.merge(S.box((0, (cy + 0.15) / 2, zc), (L / 2, (0.15 - cy) / 2, (W / 2 - rd / 2) / 2), "flags"))
        if lod < 2:
            m.merge(S.box((0, 0.075, s * (rd / 2 + 0.15)), (L / 2, 0.075 + 0.002, 0.15), "kerb"))
        for xp in piers:
            m.merge(S.lathe([(cy, bay), (0.15, bay)], [16, 10, 6][lod], tag="flags", caps=(False, True))
                    .transformed(np.eye(3), (xp, 0, s * W / 2)))
    return {"body": Part(m)}


# --- bridge_foot -------------------------------------------------------------------------------------------
def bridge_foot(lod):
    sp, rise, W, wy, nr, rh = FOOT["span"], FOOT["rise"], FOOT["width"], FOOT["water"], FOOT["ribs"], FOOT["rail"]
    m = Mesh()
    deck_t = 0.12
    spring = -deck_t - 0.25 - rise
    # the abutments: stone blocks from the water up to the deck at each end, a cornice on them
    for s in (1, -1):
        x = s * (sp / 2 + 1.2)
        m.merge(S.box((x, (wy - 0.5) / 2, 0), (1.2, -(wy - 0.5) / 2, W / 2 + 0.5), "stone"))
        m.merge(S.box((x, -0.10, 0), (1.25, 0.10, W / 2 + 0.6), "stone"))
    # the ribs: shallow segmental arches of I-section iron, rings in their spandrels
    n = [24, 12, 6][lod]
    zs = np.linspace(-W / 2 + 0.35, W / 2 - 0.35, nr if lod < 2 else 3)
    I = [(-0.05, -0.18), (0.05, -0.18), (0.05, 0.18), (-0.05, 0.18)]
    for z in zs:
        arc = [(x, spring + rise * (1 - (2 * x / sp) ** 2), z) for x in np.linspace(-sp / 2, sp / 2, n + 1)]
        m.merge(S.sweep(arc, I, "iron", up=(0, 0, 1)))
        m.merge(S.sweep([(-sp / 2, -deck_t - 0.10, z), (sp / 2, -deck_t - 0.10, z)], [(-0.04, -0.10), (0.04, -0.10), (0.04, 0.10), (-0.04, 0.10)], "iron", up=(0, 0, 1)))
        if lod < 2:  # the spandrel: rings shrinking toward the crown, posts between them
            x = -sp / 2 + 0.5
            while x < sp / 2 - 0.4:
                ya = spring + rise * (1 - (2 * x / sp) ** 2)
                gap = -deck_t - 0.20 - ya
                if gap > 0.18:
                    r = gap / 2 - 0.03
                    if lod == 0 and abs(z) > W / 2 - 0.5:   # rings on the two outer ribs, the ones seen; posts inside
                        ring = [(x + np.cos(a) * r, ya + gap / 2 + np.sin(a) * r, z) for a in np.linspace(0, 2 * np.pi, 9)[:-1]]
                        m.merge(S.sweep(ring, S.circle(0.025, 4), "iron", closed=True, up=(0, 0, 1)))
                    else:
                        m.merge(S.box((x, ya + gap / 2, z), (0.03, gap / 2, 0.03), "iron"))
                    x += 2 * r + 0.10
                else:
                    x += 0.4
    if lod < 2:  # the cross-bracing between the ribs under the deck
        for x in np.linspace(-sp / 2 + 1.5, sp / 2 - 1.5, [9, 5][lod]):
            y = spring + rise * (1 - (2 * x / sp) ** 2)
            m.merge(S.sweep([(x, y, zs[0]), (x, y, zs[-1])], S.circle(0.03, 4), "iron"))
    # the deck: oak planks across on the bearers
    L = sp + 0.8
    if lod == 0:
        nplank = int(L / 0.20)
        for i in range(nplank):
            x = -L / 2 + (i + 0.5) * L / nplank
            m.merge(S.box((x, -deck_t / 2, 0), (0.095, deck_t / 2, W / 2), "plank").set_unit(i % 7 + 1))
    else:
        m.merge(S.box((0, -deck_t / 2, 0), (L / 2, deck_t / 2, W / 2), "plank"))
    # the railings: a top rail on posts, balusters between, and a lantern post at each end
    for s in (1, -1):
        z = s * (W / 2 - 0.05)
        m.merge(S.sweep([(-L / 2, rh, z), (L / 2, rh, z)], [(-0.04, -0.03), (0.04, -0.03), (0.04, 0.03), (-0.04, 0.03)], "iron", up=(0, 1, 0)))
        if lod < 2:
            m.merge(S.sweep([(-L / 2, 0.10, z), (L / 2, 0.10, z)], [(-0.025, -0.02), (0.025, -0.02), (0.025, 0.02), (-0.025, 0.02)], "iron", up=(0, 1, 0)))
            for x in np.arange(-L / 2, L / 2 + 0.01, 2.0):
                m.merge(S.box((x, rh / 2, z), (0.035, rh / 2, 0.035), "iron"))
            if lod == 0:
                for x in np.arange(-L / 2 + 0.16, L / 2, 0.16):
                    m.merge(S.box((x, (0.10 + rh) / 2, z), (0.008, (rh - 0.10) / 2, 0.008), "iron"))
        for xe in (-L / 2 + 0.2, L / 2 - 0.2):  # the lantern posts
            post = [(0.0, 0.10), (0.30, 0.08), (0.35, 0.05), (2.60, 0.04), (2.70, 0.06), (2.75, 0.03)]
            m.merge(S.lathe(post, [8, 6, 4][lod], tag="iron").transformed(np.eye(3), (xe, 0, z)))
            if lod < 2:
                m.merge(S.lathe([(2.75, 0.08), (2.80, 0.12), (3.05, 0.14), (3.10, 0.10), (3.25, 0.0)], [6, 4][lod], tag="lamp").transformed(np.eye(3), (xe, 0, z)))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "bridge_stone": dict(build=bridge_stone, materials=materials(), edge_radius=0.01, close=(-8.0, -1.0, -6.0), tex=2048, **_SPEC),
    "bridge_foot": dict(build=bridge_foot, materials=materials(), edge_radius=0.006, close=(-10.0, 0.5, -2.5), tex=2048, **_SPEC),
}
