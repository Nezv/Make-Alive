"""Stairs, railings, ceilings and floors of public buildings (S192). Cards and references:
references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

stair_flight: a dog-leg stair's half flight of cast concrete between two floors 3.0 m apart: nine
risers up to the half landing, granilite treads with a dark nosing strip, the sloping soffit, the
landing slab, a steel tube handrail on brackets along the wall side and a balustrade of flat bars
along the well side, its rail ending in a scroll.
ceiling_grid: a 2.4 x 2.4 m module of suspended ceiling: the T-bar grid, its 600 mm mineral tiles
(one hanging open, one gone, a stain), a recessed louvre light (lit), the hangers to the slab above.

The flight starts on y = 0 at z = 0 and climbs toward +Z (the wall on its +X side); the ceiling hangs
below y = 0 (the soffit), like the fittings.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

FLIGHT = dict(w=1.20, risers=9, rise=1.50, going=0.28, landing=1.30, slab=0.18)
GRID = dict(n=4, tile=0.60, drop=0.45)


def materials():
    return {
        "concrete": Material((0.62, 0.61, 0.58), kind="concrete", chip=0.0, rusts=False, grain=0.16),
        "granilite": Material((0.66, 0.64, 0.60), kind="stone", chip=0.0, rusts=False, grain=0.30, speckle=0.5),
        "nosing": Material((0.18, 0.18, 0.18), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "rail": Material((0.30, 0.38, 0.45), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.5, grain=0.05),
        "steel": Material((0.62, 0.63, 0.64), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.2, grain=0.04),
        "tile": Material((0.86, 0.85, 0.82), kind="plaster", chip=0.0, rusts=False, grain=0.12, speckle=0.3),
        "dark": Material((0.08, 0.08, 0.09), chip=0.0, rusts=False, grain=0.02, fades=False),
        "light": Material((0.92, 0.94, 0.96), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.90, 0.95, 1.0)),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- stair_flight ------------------------------------------------------------------------------------------
def stair_flight(lod):
    w, n, H, g, ld, sl = FLIGHT["w"], FLIGHT["risers"], FLIGHT["rise"], FLIGHT["going"], FLIGHT["landing"], FLIGHT["slab"]
    r = H / n
    L = (n - 1) * g                                         # the flight's run: the last riser lands on the landing
    m = Mesh()
    # the waist: the steps' profile over a sloping soffit, pushed across the stair's width
    prof = [(0.0, 0.0)]
    for k in range(n - 1):
        prof += [(k * g, (k + 1) * r), ((k + 1) * g, (k + 1) * r)]
    prof += [(L, H), (L + ld, H), (L + ld, H - sl), (L, H - sl), (0.0 + sl * 0.3, -0.0)]
    prof = [(z, y) for z, y in prof]
    m.merge(S.extrude([(z, y) for z, y in prof], w, 0.0, "concrete", origin=(-w / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0)))     # pushed toward +X across the width
    # the treads: granilite slabs with their dark nosings; the landing's floor
    for k in range(n - 1):
        y = (k + 1) * r
        m.merge(_cb((0, y + 0.012, k * g + g / 2 - 0.01), (w / 2, 0.012, g / 2 + 0.01), 0.004, "granilite", lod, edges="top").set_unit(k + 1))
        if lod < 2:
            m.merge(S.box((0, y + 0.025, k * g + 0.02), (w / 2 - 0.05, 0.002, 0.012), "nosing"))
    m.merge(S.box((0, H + 0.012, L + ld / 2), (w / 2, 0.012, ld / 2), "granilite"))
    if lod < 2:
        # the wall side (+X): a tube handrail on brackets, its ends turned to the wall
        x = w / 2 - 0.06
        rail = [(x + 0.06, 0.90, -0.30), (x, 0.90, -0.30)] + [(x, 0.90 + k * r + r / 2, k * g + g / 2) for k in (0, n - 2)] + [(x, H + 0.90, L + 0.30), (x + 0.06, H + 0.90, L + 0.30)]
        m.merge(S.sweep(rail, S.circle(0.021, [10, 6][lod]), "rail"))
        for k in range(0, n - 1, 3):
            y = 0.90 + k * r + r / 2
            m.merge(S.sweep([(x, y - 0.02, k * g + g / 2), (x + 0.06, y - 0.07, k * g + g / 2)], S.circle(0.008, 4), "rail"))
        # the well side (-X): flat-bar balusters fixed to the stringer, the top rail, its scroll at the foot
        xb = -w / 2 - 0.03
        top = [(xb, 0.95, -0.05), (xb, H + 0.95, L), (xb, H + 0.95, L + ld)]
        m.merge(S.sweep(top, [(-0.025, -0.02), (0.025, -0.02), (0.025, 0.02), (-0.025, 0.02)], "rail", up=(1, 0, 0)))
        nb = [int((L + ld) / 0.11), int((L + ld) / 0.22)][lod]
        for i in range(nb + 1):
            z = -0.05 + i * (L + ld + 0.05) / nb
            yb = min(H, max(0.0, z / L * H)) if z < L else H
            ytop = 0.95 + (H * min(1.0, max(0.0, (z + 0.05) / (L + 0.05)))) - 0.02
            m.merge(S.box((xb, (yb + ytop) / 2 + 0.02, z), (0.006, (ytop - yb) / 2, 0.02), "rail"))
        m.merge(S.sweep([(xb, 0.20, -0.05), (xb, 0.95, -0.05)], [(-0.02, -0.02), (0.02, -0.02), (0.02, 0.02), (-0.02, 0.02)], "rail", up=(0, 0, 1)))
        if lod == 0:
            scroll = [(xb + 0.08 * np.cos(a) * (1 - a / 10), 0.95 - 0.08 * np.sin(a) * (1 - a / 10) * 0.6, -0.05 - 0.10 * np.sin(a / 2)) for a in np.linspace(0, 1.6 * np.pi, 9)]
            m.merge(S.sweep(scroll, S.circle(0.012, 4), "rail"))
    return {"body": Part(m)}


# --- ceiling_grid ------------------------------------------------------------------------------------------
def ceiling_grid(lod):
    n, t, drop = GRID["n"], GRID["tile"], GRID["drop"]
    W = n * t
    rng = np.random.default_rng(6)
    m = Mesh()
    y = -drop
    tee = [(-0.012, -0.002), (0.012, -0.002), (0.012, 0.0), (0.002, 0.0), (0.002, 0.03), (-0.002, 0.03), (-0.002, 0.0), (-0.012, 0.0)]
    for k in range(n + 1):
        c = -W / 2 + k * t
        m.merge(S.sweep([(-W / 2, y, c), (W / 2, y, c)], tee if lod < 2 else [(-0.012, -0.002), (0.012, -0.002), (0.012, 0.0), (-0.012, 0.0)], "steel", up=(0, 1, 0)))
        m.merge(S.sweep([(c, y, -W / 2), (c, y, W / 2)], tee if lod < 2 else [(-0.012, -0.002), (0.012, -0.002), (0.012, 0.0), (-0.012, 0.0)], "steel", up=(0, 1, 0)))
    gone, hanging, lamp = (1, 2), (2, 0), (1, 1)
    for i in range(n):
        for j in range(n):
            cx, cz = -W / 2 + (i + 0.5) * t, -W / 2 + (j + 0.5) * t
            if (i, j) == gone:
                continue
            if (i, j) == lamp:  # the recessed louvre light: its frame, the lit diffuser behind the louvres
                m.merge(S.box((cx, y + 0.004, cz), (t / 2 - 0.02, 0.004, t / 2 - 0.02), "light"))
                if lod < 2:
                    for k in range([7, 3][lod]):
                        u = -t / 2 + 0.05 + k * (t - 0.10) / ([7, 3][lod] - 1)
                        m.merge(S.box((cx + u, y - 0.012, cz), (0.004, 0.012, t / 2 - 0.03), "steel"))
                    m.merge(S.box((cx, y + 0.08, cz), (t / 2 - 0.05, 0.07, t / 2 - 0.05), "steel"))
                continue
            tile = _cb((0, 0, 0), (t / 2 - 0.013, 0.008, t / 2 - 0.013), 0.003, "tile", lod, edges="vertical")
            if (i, j) == hanging and lod < 2:  # dropped at one edge, hanging from the far tee
                tile = tile.transformed(S.rotation((1, 0, 0), 0.9), (0, 0, 0)).transformed(np.eye(3), (0, -0.24, -0.06))
            m.merge(tile.transformed(np.eye(3), (cx, y + 0.010, cz)).set_unit(i * n + j + 1))
    if lod < 2:  # the hangers to the slab, the services above the gap
        for k in range(n + 1):
            for c in (-W / 2 + 0.3, W / 2 - 0.3):
                m.merge(S.sweep([(-W / 2 + k * t, y + 0.03, c), (-W / 2 + k * t, 0.0, c)], S.circle(0.002, 3), "steel"))
        m.merge(S.box((0, -0.10, 0.5), (W / 2, 0.08, 0.12), "steel"))     # a duct over the tiles
        m.merge(S.sweep([(-W / 2, -0.25, -0.3), (W / 2, -0.20, -0.3)], S.circle(0.012, 5), "dark"))
    return {"body": Part(m)}


def _paint_ceiling(P, N, tag, tags, state, col):
    """A water stain spreading on two tiles, darker at its rim."""
    sel = tag == tags.index("tile")
    d = np.hypot(P[:, 0] - 0.55, P[:, 2] + 0.45)
    ring = (d < 0.38) & sel
    k = np.clip(1.0 - d / 0.38, 0, 1)
    stain = np.array([0.62, 0.52, 0.36], np.float32)
    rim = (np.abs(d - 0.36) < 0.02) & sel
    col = np.where(ring[:, None], col * (1 - 0.25 * k[:, None]) + stain * 0.25 * k[:, None], col)
    return np.where(rim[:, None], col * 0.75, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "stair_flight": dict(build=stair_flight, materials=materials(), edge_radius=0.004, close=(0.0, 0.8, 0.6), **_SPEC),
    "ceiling_grid": dict(build=ceiling_grid, materials=materials(), extra=_paint_ceiling, edge_radius=0.002, close=(0.0, -0.5, 0.0), **_SPEC),
}
