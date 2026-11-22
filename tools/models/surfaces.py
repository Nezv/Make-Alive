"""The detail kit's surfaces (S141): what walls, floors and roofs are made of.

Painted into the bake (patterns: functions of position in a wall's plane, for `Material.pattern`):
    Bond(kind)        brick bonds: stretcher, flemish, english; `foraine` the long flat Toulouse brick
    Bond("block")     concrete block (parpaing), Bond("ashlar") dressed stone in courses
    BoardFormed       concrete cast against boards: board lines, grain, tie holes
    Plaster           lime plaster over a bond that shows where the plaster has fallen

Modelled (geometry, one unit per piece so the painter can vary each):
    setts             stone setts in rows or in Paris fans, each a chamfered block, on a sand bed
    pavers            interlocking concrete pavers (double-T), chamfered
    roof_tiles        flat clay tiles or canal tiles in overlapping rows; ridge_caps along a ridge
    corrugated, ribbed  sheet metal: a sine wave or trapezoid ribs
    grille, wire_mesh, louvres   a round cast-iron tree grate, welded mesh, a shutter's slats

A pattern returns, for every texel: its colour, how much it is joint (mortar, a gap: grime
gathers there), and the unit it belongs to (so wear can pick whole bricks).
"""
import numpy as np

import shapes as S
from poly import Mesh


def _hash(*a):
    """A number 0..1 from whole numbers, the same everywhere (numpy arrays welcome)."""
    h = np.zeros_like(np.asarray(a[0], np.float64), dtype=np.float64)
    for i, v in enumerate(a):
        h = h + np.asarray(v, np.float64) * [12.9898, 78.233, 37.719, 4.581][i % 4]
    h = np.sin(h) * 43758.5453
    return h - np.floor(h)


def frame_uv(P, origin, right, up):
    o, r, u = (np.asarray(x, np.float32) for x in (origin, right, up))
    rel = P - o
    return rel @ r, rel @ u


# --- Patterns --------------------------------------------------------------------------------------

BRICK_RED = [(0.55, 0.27, 0.18), (0.58, 0.30, 0.20), (0.50, 0.25, 0.17), (0.60, 0.34, 0.23), (0.52, 0.28, 0.20),
             (0.62, 0.38, 0.27)]  # close tones, as on brick_valade: a wall reads as one red
STONE = [(0.72, 0.68, 0.58), (0.76, 0.72, 0.62), (0.68, 0.64, 0.55), (0.79, 0.75, 0.66)]


class Bond:
    """A wall of units in courses, painted. kind: stretcher (each course half a brick on),
    english (a course of stretchers, a course of headers), flemish (stretcher, header, stretcher...
    in every course, the headers centred over the stretchers below), foraine (the long flat
    Toulouse brick, thick joints), block (concrete blocks 50 x 20), ashlar (stone courses of
    varying height and length, fine joints). `origin`, `right`, `up` place it on its face."""

    SIZES = {"stretcher": (0.22, 0.055, 0.010), "english": (0.22, 0.055, 0.010), "flemish": (0.22, 0.055, 0.010),
             "foraine": (0.40, 0.045, 0.022), "block": (0.50, 0.20, 0.010), "ashlar": (0.80, 0.42, 0.005)}

    def __init__(self, kind, origin=(0, 0, 0), right=(1, 0, 0), up=(0, 1, 0), colours=None, mortar=(0.66, 0.62, 0.55),
                 seed=0):
        self.kind, self.origin, self.right, self.up, self.seed = kind, origin, right, up, seed
        self.L, self.H, self.J = self.SIZES[kind]
        if colours is None:
            colours = {"block": [(0.56, 0.56, 0.54), (0.60, 0.60, 0.58), (0.52, 0.53, 0.52)], "ashlar": STONE}.get(kind, BRICK_RED)
        self.colours = np.array(colours, np.float32)
        self.mortar = np.array(mortar if kind != "block" else (0.60, 0.59, 0.56), np.float32)

    def cells(self, u, v):
        """(unit id, distance to the nearest joint in metres, (unit's u, v) inside it)."""
        course = np.floor(v / (self.H + self.J)).astype(np.int64)
        vin = v - course * (self.H + self.J)
        L, J = self.L, self.J
        if self.kind == "ashlar":  # courses of their own height; stones of their own length
            hs = 0.32 + 0.14 * _hash(np.arange(64), self.seed)
            edges = np.concatenate([[0.0], np.cumsum(hs + J)])
            course = np.clip(np.searchsorted(edges, v, side="right") - 1, 0, 63)
            vin = v - edges[course]
            Hc = hs[course]
            shift = _hash(course, 7.0 + self.seed) * 0.6
            lens = 0.55 + 0.5 * _hash(course, np.floor((u + shift) / 0.8), 3.0)
            x = u + shift
            k = np.floor(x / 0.8).astype(np.int64)
            xin = x - k * 0.8
            # split the 0.8 m cell in two stones at a length that varies
            cut = np.clip(lens * 0.8 / 1.05, 0.25, 0.7)
            second = xin > cut
            uid = course * 4096 + k * 2 + second
            sl = np.where(second, 0.8 - cut, cut)
            uin = np.where(second, xin - cut, xin)
            dj = np.minimum.reduce([uin, sl - J - uin, vin, Hc - vin])
            return uid, dj, uin, vin
        if self.kind in ("stretcher", "foraine", "block"):
            shift = (course % 2) * (L + J) / 2
            x = u + shift
            k = np.floor(x / (L + J)).astype(np.int64)
            uin = x - k * (L + J)
            ul = np.full_like(uin, L)
        elif self.kind == "english":
            header = course % 2 == 1
            Lc = np.where(header, (L - J) / 2, L)
            shift = np.where(header, (L + J) / 4, 0.0)
            x = u + shift
            k = np.floor(x / (Lc + J)).astype(np.int64)
            uin = x - k * (Lc + J)
            ul = Lc
        else:  # flemish: a stretcher and a header repeat every 1.5 bricks; odd courses shift by 3/4 brick
            hd = (L - J) / 2
            period = L + hd + 2 * J
            shift = (course % 2) * (L + J + hd + J) / 2 + (L - hd) / 4 * (course % 2)
            x = u + shift
            k = np.floor(x / period).astype(np.int64)
            xp = x - k * period
            is_header = xp > L + J
            uin = np.where(is_header, xp - (L + J), xp)
            ul = np.where(is_header, hd, L)
            k = k * 2 + is_header
        uid = course * 4096 + k
        dj = np.minimum.reduce([uin, ul - uin, vin, self.H - vin])
        return uid, dj, uin, vin

    def __call__(self, P, N):
        from noise import fbm
        u, v = frame_uv(P, self.origin, self.right, self.up)
        uid, dj, uin, vin = self.cells(u, v)
        h = _hash(uid, self.seed + 1.0)
        col = self.colours[(h * len(self.colours)).astype(int) % len(self.colours)]
        # each unit a little lighter or darker, its own speckle, burnt ends on some bricks
        col = col * (0.94 + 0.12 * _hash(uid, 5.0))[:, None]
        col = col * (0.92 + 0.16 * fbm(P, 60.0 if self.kind != "ashlar" else 25.0, 2, 3))[:, None]
        if self.kind in ("stretcher", "english", "flemish", "foraine"):
            end = (np.minimum(uin, (self.L - uin)) < 0.03) & (_hash(uid, 9.0) > 0.7)
            col = np.where(end[:, None], col * 0.7, col)
        joint = dj < 0
        mort = self.mortar * (0.9 + 0.2 * fbm(P, 90.0, 2, 5))[:, None]
        col = np.where(joint[:, None], mort, col)
        # the unit's arris catches less light where it rounds into the joint
        rim = np.clip(1 - np.maximum(dj, 0) / 0.006, 0, 1) * (~joint)
        col = col * (1 - 0.25 * rim)[:, None]
        jv = np.clip(1 - np.maximum(dj, 0) / 0.004, 0, 1)
        return col, np.where(joint, 1.0, 0.4 * jv).astype(np.float32), uid


class BoardFormed:
    """Concrete cast against boards (`board` m wide): each board's print a slightly different
    grey with grain along it, fine ridges where the boards met, tie holes on a grid."""

    def __init__(self, origin=(0, 0, 0), right=(1, 0, 0), up=(0, 1, 0), board=0.14, ties=(0.6, 0.56), seed=0,
                 base=(0.60, 0.59, 0.56)):
        self.origin, self.right, self.up, self.board, self.ties, self.seed = origin, right, up, board, ties, seed
        self.base = np.array(base, np.float32)

    def __call__(self, P, N):
        from noise import fbm
        u, v = frame_uv(P, self.origin, self.right, self.up)
        row = np.floor(v / self.board).astype(np.int64)
        vin = v - row * self.board
        seg = np.floor((u + _hash(row, 2.0) * 2.4) / 2.4).astype(np.int64)  # boards 2.4 m long, ends staggered
        uid = row * 64 + seg
        tone = 0.9 + 0.18 * _hash(uid, self.seed + 3.0)
        Q = np.stack([u * 0.08, v * 3.0, np.zeros_like(u)], 1).astype(np.float32)  # grain: stretched along the board
        grain = fbm(Q, 9.0, 3, 11)
        col = self.base[None] * (tone * (0.92 + 0.14 * grain))[:, None]
        ridge = (vin < 0.004) | (vin > self.board - 0.002)
        col = np.where(ridge[:, None], col * 0.82, col)
        tu, tv = self.ties
        du = (u - tu / 2) - np.round((u - tu / 2) / tu) * tu
        dv = (v - tv / 2) - np.round((v - tv / 2) / tv) * tv
        d = np.hypot(du, dv)
        col = np.where((d < 0.016)[:, None], col * 0.75, col)
        col = np.where((d < 0.009)[:, None], np.array([0.12, 0.11, 0.10], np.float32), col)
        joint = np.where(d < 0.009, 1.0, np.where(ridge, 0.5, 0.0)).astype(np.float32)
        return col, joint, uid


class Plaster:
    """Lime plaster (enduit) over a wall: an off-white, uneven coat, patched in places; where it
    has fallen (more with the years: the painter's `spall` mask) the bond under it shows."""

    def __init__(self, under, colour=(0.80, 0.76, 0.68), seed=0):
        self.under, self.colour, self.seed = under, np.array(colour, np.float32), seed

    def __call__(self, P, N):
        from noise import fbm
        col = self.colour[None] * (0.9 + 0.12 * fbm(P, 3.0, 3, 41) + 0.06 * fbm(P, 40.0, 2, 43))[:, None]
        patch = fbm(P, 1.6, 2, 47) > 0.62
        col = np.where(patch[:, None], col * np.array([0.97, 0.97, 1.0], np.float32), col)
        return col, np.zeros(len(P), np.float32), np.zeros(len(P), np.int64)

    def beneath(self, P, N):
        return self.under(P, N)


# --- Geometry --------------------------------------------------------------------------------------

def setts(w, d, size=(0.20, 0.14), joint=0.01, h=0.06, pattern="rows", origin=(0, 0, 0), seed=0, lod=0,
          unit0=1, tag="sett", bed_tag="sand"):
    """Stone setts filling `w` x `d` (x by z) from `origin` (its near left corner, the setts' tops
    at origin's y + `h` / 3): in `rows` (courses across z, each half a sett on) or in Paris `fan`s
    (arcs one metre across). Each sett a block with its top edges chamfered, a little tilted and
    proud or sunk, its own unit; a sand bed under them."""
    rng = np.random.default_rng(seed)
    o = np.asarray(origin, np.float64)
    m = Mesh()
    L, W = size
    places = []  # (x, z, yaw, length)
    if pattern == "rows":
        z = W / 2 + joint / 2
        r = 0
        while z < d:
            x = (L / 2 if r % 2 == 0 else 0.0) + joint / 2
            while x < w + L / 2:
                a, b = max(x - L / 2, 0.0), min(x + L / 2, w)  # cut to fit at the edges
                if b - a > 0.05:
                    places.append(((a + b) / 2, z, 0.0, b - a))
                x += L + joint
            z += W + joint
            r += 1
    else:  # fans (pavage en éventail): fish scales. Fans `fan` wide on rows `fan` / 2 apart,
        # alternate rows half a fan on; each fan is the lower half of a disc of setts laid in arcs,
        # less what the disc of the row above covers, so every fan's ends tuck under its neighbours
        fan = 1.0
        R = fan * 0.6
        L = W = 0.10  # fans are laid in small cubes (pavés mosaïques)
        rows_z = np.arange(0.0, d + R + fan / 2, fan / 2)
        centres = [(fx, fz, ri) for ri, fz in enumerate(rows_z)
                   for fx in np.arange(-fan if ri % 2 else -fan / 2, w + fan, fan)]

        def covered_above(x, z, ri):
            for fx, fz, rj in centres:
                if rj == ri + 1 and (x - fx) ** 2 + (z - fz) ** 2 < (R - W * 0.2) ** 2:
                    return True
            return False
        for fx, fz, ri in centres:
            rad = W * 0.6
            while rad < R:
                n = max(1, int(np.ceil(np.pi * rad / (L + joint))))
                for k in range(n):
                    a = -np.pi / 2 + (k + 0.5) * np.pi / n
                    x, z = fx + np.sin(a) * rad, fz - np.cos(a) * rad
                    if 0.06 < x < w - 0.06 and not covered_above(x, z, ri):
                        places.append((x, z, -a, min(L, np.pi * rad / n - joint)))
                rad += W + joint
    unit = unit0
    for x, z, yaw, L in places:
        if not (W / 2 <= z <= d - W / 2 + 1e-6):
            continue
        lift = rng.uniform(-0.006, 0.008)
        tilt = rng.uniform(-0.03, 0.03, 2)
        R = S.rotation((0, 1, 0), yaw + rng.uniform(-0.05, 0.05)) @ S.rotation((1, 0, 0), tilt[0]) @ S.rotation((0, 0, 1), tilt[1])
        hl = (L / 2 * rng.uniform(0.93, 1.0), h / 2, W / 2 * rng.uniform(0.93, 1.0))
        c = o + np.array([x, h / 3 - h / 2 + lift, z])  # the top stands h / 3 above the sand
        if lod >= 2:
            b = S.box(c, hl, tag, R)
        else:
            b = S.chamfer_box(c, hl, 0.022 if lod == 0 else 0.012, tag, R, edges="top_vertical", segments=2 if lod == 0 else 1)
        m.merge(b.set_unit(unit))
        unit += 1
    bed = S.box(o + np.array([w / 2, -0.02, d / 2]), (w / 2, h / 3 + 0.0, d / 2), bed_tag)
    m.merge(bed)
    return m


def _paver_outline(L=0.20, W=0.165, neck=0.03):
    """A double-T paver (I-shape) in metres, centred, counter-clockwise."""
    a, b = L / 2, W / 2
    n = b - neck
    s = 0.05
    return [(-a, -b), (-a + s, -b), (-a + s, -n), (a - s, -n), (a - s, -b), (a, -b), (a, b), (a - s, b), (a - s, n),
            (-a + s, n), (-a + s, b), (-a, b)]


def pavers(w, d, origin=(0, 0, 0), h=0.06, joint=0.004, unit0=1, tag="paver", bed_tag="sand", lod=0, seed=0):
    """Interlocking double-T concrete pavers filling `w` x `d` from `origin` (near left corner, tops
    at origin's y), each extruded with a chamfered top and its own unit."""
    o = np.asarray(origin, np.float64)
    out = _paver_outline()
    L, W = 0.20, 0.165
    neck = 0.03
    m = Mesh()
    unit = unit0
    rng = np.random.default_rng(seed)
    row = 0
    z = W / 2
    while z < d + W:
        x = (L / 2 if row % 2 == 0 else 0.0)
        while x < w + L:
            if 0 <= x - L / 2 and x + L / 2 <= w + 1e-6 and z + W / 2 <= d + 1e-6 and z - W / 2 >= -1e-6:
                lift = rng.uniform(-0.003, 0.003)
                o2 = o + np.array([x, lift - h, z])
                pts = [(px * (1 - joint / L), pz * (1 - joint / W)) for px, pz in out]
                # the outline lies in x-z: right = +X, up = +Z, so the extrusion's front is +Y
                e = S.extrude(pts, h, chamfer=0.006 if lod < 2 else 0.0, tag=tag, origin=o2, right=(1, 0, 0), up=(0, 0, 1),
                              unit=unit)
                m.merge(e)
                unit += 1
            x += L + 0.0
        z += W - neck + 0.0
        row += 1
    m.merge(S.box(o + np.array([w / 2, -h - 0.015, d / 2]), (w / 2, 0.015, d / 2), bed_tag))
    return m


def roof_tiles(w, length, pitch_deg, kind="flat", origin=(0, 0, 0), unit0=1, tag="tile", lod=0, seed=0, gauge=None):
    """Clay tiles on a slope `w` wide (along x) and `length` up the slope from the eaves at
    `origin` (its left end), rising towards +Z at `pitch_deg`. kind: `flat` (tuiles plates: small
    flat tiles, rows a half tile on, each lying on the one below so the rows step) or `canal`
    (tapered half-round tiles: channels laid concave, covers laid convex over their joints).
    Each tile its own unit."""
    o = np.asarray(origin, np.float64)
    rng = np.random.default_rng(seed)
    p = np.radians(pitch_deg)
    up_slope = np.array([0.0, np.sin(p), np.cos(p)])
    normal = np.array([0.0, np.cos(p), -np.sin(p)])
    m = Mesh()
    unit = unit0
    if kind == "flat":
        tw, tl, th = 0.17, 0.27, 0.014
        g = gauge or 0.105  # each row shows a bit more than a third of the tile
        rows = int(length / g)
        for r in range(rows):
            x = (tw / 2 if r % 2 == 0 else 0.0) + 0.002
            while x < w + tw / 2:
                x0, x1 = max(x - tw / 2, 0.0), min(x + tw / 2, w)
                if x1 - x0 > 0.03:
                    tilt = np.radians(4.5) + rng.uniform(-0.01, 0.01)  # rests on the row below: steeper than the roof
                    R = S.rotation((1, 0, 0), -tilt) @ np.stack([np.array([1.0, 0, 0]), normal, up_slope], 1)
                    c = o + np.array([(x0 + x1) / 2, 0, 0]) + up_slope * (r * g + tl / 2) + normal * (th / 2 + 0.004 * (r % 2))
                    half = ((x1 - x0) / 2 - 0.002, th / 2, tl / 2)
                    t = S.chamfer_box((0, 0, 0), half, 0.004, tag, edges="front" if lod else "all") if lod < 2 else S.box((0, 0, 0), half, tag)
                    if lod == 0:  # the tail's corners cut round (tuile plate à bout arrondi)
                        for s in (-1, 1):
                            t = S.clip(t, (s * (half[0] - 0.025), 0, -half[2] + 0.0), (s * 0.7, 0, -0.7), tag)
                    m.merge(t.transformed(R, c).set_unit(unit))
                    unit += 1
                x += tw + 0.003
        return m
    # canal tiles
    tl, r_big, r_small, th = 0.42, 0.105, 0.08, 0.014
    g = gauge or 0.30
    pitch_x = 0.19
    rows = max(1, int((length - tl) / g) + 1)
    sides = 6 if lod == 0 else 4
    for col in range(int(w / pitch_x) + 1):
        xc = pitch_x / 2 + col * pitch_x
        if xc > w:
            break
        for cover in (False, True):
            x = xc + (pitch_x / 2 if cover else 0.0)
            if cover and x + r_big > w:
                continue
            for r in range(rows):
                # half a ring of `sides` facets, wide at the lower end of a channel and narrow at a cover's
                a = np.linspace(0, np.pi, sides + 1)
                k = rng.uniform(0.97, 1.03)
                lo_r, hi_r = (r_small, r_big) if cover else (r_big, r_small)
                lo_r *= k
                hi_r *= k

                def arc(rad, s):
                    ys = np.sin(a) * rad * (1 if cover else -1) * 0.75
                    return [(np.cos(t) * rad, y) for t, y in zip(a, ys)] if s else [(np.cos(t) * rad, y) for t, y in zip(a[::-1], ys[::-1])]
                rings = []
                lift = (0.05 if cover else 0.0) + 0.012 * (r % 2)
                for s, rad in ((0.0, lo_r), (tl, hi_r)):
                    outer = [(cx, cy) for cx, cy in arc(rad, True)]
                    inner = [(cx * (rad - th) / rad, cy * (rad - th) / rad) for cx, cy in arc(rad, False)]
                    ring = []
                    for cx, cy in outer + inner:
                        ring.append(o + np.array([x + cx, 0, 0]) + normal * (cy + lift + (r_big * 0.75 if not cover else 0.0)) + up_slope * (r * g + s))
                    rings.append(np.array(ring))
                t = Mesh()
                t.loft(rings, tag)
                m.merge(S.weld(t).set_unit(unit))
                unit += 1
    return m


def ridge_caps(w, origin=(0, 0, 0), r=0.12, piece=0.40, lap=0.06, tag="tile", mortar_tag="mortar", unit0=1, lod=0, seed=0):
    """Half-round ridge tiles (faîtières) along a ridge `w` long from `origin` (the ridge's left
    end), each a tapered half ring lapping the next, bedded on a mortar fillet each side."""
    o = np.asarray(origin, np.float64)
    rng = np.random.default_rng(seed)
    m = Mesh()
    sides = 7 if lod == 0 else 4
    unit = unit0
    x = 0.0
    while x < w - 0.05:
        L = min(piece, w - x)
        a = np.linspace(0, np.pi, sides + 1)
        rings = []
        for s, rad in ((0.0, r * 1.06), (L, r * 0.94)):
            outer = [(np.cos(t) * rad, np.sin(t) * rad * 0.8) for t in a]
            inner = [(np.cos(t) * (rad - 0.014), np.sin(t) * (rad - 0.014) * 0.8) for t in a[::-1]]
            rings.append(np.array([o + np.array([x + s, cy, cz]) for cz, cy in outer + inner]))
        t = Mesh()
        t.loft(rings, tag)
        R = S.rotation((1, 0, 0), rng.uniform(-0.02, 0.02))
        t = S.weld(t)
        c = o + np.array([x + L / 2, 0, 0])
        t.verts = [R @ (v - c) + c for v in t.verts]
        m.merge(t.set_unit(unit))
        unit += 1
        if L < piece:  # the last, short piece
            break
        x += L - lap
    for s in (-1, 1):  # the mortar fillets (embarrures) under the edges
        m.merge(S.sweep([o + np.array([0.0, 0.0, s * r * 0.98]), o + np.array([w, 0.0, s * r * 0.98])],
                        [(-0.03, -0.04), (0.03, -0.04), (0.012, 0.015), (-0.012, 0.015)] if s > 0 else
                        [(0.03, -0.04), (-0.03, -0.04), (-0.012, 0.015), (0.012, 0.015)], mortar_tag, up=(0, 1, 0)))
    return m


def sheet_profile(kind, width, pitch, depth, steps=8):
    """The cross-section line of a metal sheet across its width: `corrugated` (a sine wave) or
    `ribbed` (trapezoid ribs on a flat pan)."""
    xs, ys = [], []
    n = int(round(width / pitch))
    if kind == "corrugated":
        for i in range(n * steps + 1):
            x = i * pitch / steps
            xs.append(x)
            ys.append(depth / 2 * np.cos(2 * np.pi * x / pitch))
    else:
        top, slope = pitch * 0.18, pitch * 0.12
        for k in range(n):
            b = k * pitch
            for x, y in ((b, 0.0), (b + pitch - top - 2 * slope, 0.0), (b + pitch - top - slope, depth),
                         (b + pitch - slope, depth), (b + pitch, 0.0)):
                if not xs or x > xs[-1] + 1e-9:
                    xs.append(x)
                    ys.append(y)
    return np.array(xs), np.array(ys)


def sheet(kind, width, height, origin=(0, 0, 0), pitch=None, depth=None, t=0.0012, tag="metal", lod=0, rows=1):
    """A metal sheet `width` (x) by `height` (y) standing on `origin` (its bottom left, the
    sheet's back on z = origin's z, the front -Z): corrugated (76 mm sine) or ribbed (trapezoid
    ribs). Both faces modelled, so it has a thickness."""
    pitch = pitch or (0.076 if kind == "corrugated" else 0.25)
    depth = depth or (0.018 if kind == "corrugated" else 0.035)
    xs, ys = sheet_profile(kind, width, pitch, depth, steps=8 if lod == 0 else 4)
    o = np.asarray(origin, np.float64)
    front = [(x, -(y + depth / 2) - t) for x, y in zip(xs, ys)]
    back = [(x, -(y + depth / 2)) for x, y in zip(xs[::-1], ys[::-1])]
    prof = front + back
    rings = []
    for yy in np.linspace(0.0, height, rows + 1):  # more rows: room for dents
        rings.append(np.array([o + np.array([x, yy, z]) for x, z in prof]))
    m = Mesh()
    m.loft(rings, tag)
    return S.weld(m)


def grille(r_out=0.6, r_in=0.18, rings=5, spokes=24, t=0.03, origin=(0, 0, 0), tag="iron", hole_tag="sand", square=True, lod=0):
    """A round cast-iron tree grate (grille d'arbre) lying on `origin`: a square plate's frame
    round a disc of concentric rings tied by radial bars, the earth under its slots."""
    o = np.asarray(origin, np.float64)
    m = Mesh()
    sides = 32 if lod == 0 else 16
    radii = np.linspace(r_in, r_out, rings)
    for r in radii:
        w = 0.016 if r not in (r_in, r_out) else 0.03
        m.merge(S.lathe([(-t, r - w / 2), (0.0, r - w / 2), (0.0, r + w / 2), (-t, r + w / 2)], sides, tag=tag)
                .transformed(np.eye(3), o))
    bar = S.chamfer_box((0, -t / 2, (r_in + r_out) / 2), (0.012, t / 2, (r_out - r_in) / 2), 0.004, tag, edges="top")
    m.merge(S.array_radial(bar, spokes, (0, 0, 0), (0, 1, 0)).transformed(np.eye(3), o))
    if square:
        s = r_out + 0.06
        for k in range(4):
            R = S.rotation((0, 1, 0), k * np.pi / 2)
            piece = S.chamfer_box((0, -t / 2, s - 0.03), (s, t / 2, 0.03), 0.006, tag, edges="top")
            piece.verts = [R @ v + o for v in piece.verts]
            m.merge(piece)
        # the corners between the disc and the square, solid plate with a raised dot pattern
        for k in range(4):
            R = S.rotation((0, 1, 0), k * np.pi / 2 + np.pi / 4)
            c = o + R @ np.array([0, -0.004, (r_out + s * 1.414) / 2 - 0.02])
            m.merge(S.box(c, (0.12, 0.004, 0.07), tag, R))
    m.merge(S.box(o + np.array([0, -t - 0.01, 0]), (r_out + 0.05, 0.01, r_out + 0.05), hole_tag))
    return m


def wire_mesh(w, h, step=0.05, wire=0.004, origin=(0, 0, 0), tag="wire", frame_tag="metal"):
    """Welded wire mesh `w` x `h` standing on `origin` (bottom left), wires `step` apart, in a
    frame of angle iron."""
    o = np.asarray(origin, np.float64)
    m = Mesh()
    nx, ny = int(w / step), int(h / step)
    for i in range(1, nx):
        m.merge(S.box(o + np.array([i * w / nx, h / 2, -wire / 2]), (wire / 2, h / 2, wire / 2), tag))
    for j in range(1, ny):
        m.merge(S.box(o + np.array([w / 2, j * h / ny, -wire * 1.5]), (w / 2, wire / 2, wire / 2), tag))
    for p0, p1 in (((0, 0), (w, 0)), ((w, 0), (w, h)), ((w, h), (0, h)), ((0, h), (0, 0))):
        a = o + np.array([p0[0], p0[1], 0.0])
        b = o + np.array([p1[0], p1[1], 0.0])
        m.merge(S.sweep([a, b], [(-0.012, 0.0), (0.012, 0.0), (0.012, -0.003), (0.003, -0.003), (0.003, -0.024),
                                 (-0.003, -0.024), (-0.003, -0.003), (-0.012, -0.003)][::-1], frame_tag, up=(0, 0, -1)))
    return m


def louvres(w, h, slats=None, frame=0.055, t=0.03, origin=(0, 0, 0), tag="wood", lod=0):
    """A louvred shutter leaf (persienne) `w` x `h` standing on `origin` (its bottom left, back
    on origin's z, front -Z): stiles and rails with chamfered edges, a middle rail, slats tilted
    down and out between them."""
    o = np.asarray(origin, np.float64)
    m = Mesh()
    c = 0.005
    for x in (frame / 2, w - frame / 2):
        m.merge(S.chamfer_box(o + np.array([x, h / 2, -t / 2]), (frame / 2, h / 2, t / 2), c, tag, edges="front"))
    mid = h * 0.42
    for y, hh in ((frame * 0.6, frame * 1.2), (h - frame / 2, frame), (mid, frame * 0.8)):
        m.merge(S.chamfer_box(o + np.array([w / 2, y, -t / 2]), (w / 2 - frame, hh / 2, t / 2), c, tag, edges="front"))
    pitch = 0.05
    for y0, y1 in ((frame * 1.2, mid - frame * 0.4), (mid + frame * 0.4, h - frame)):
        n = int((y1 - y0) / pitch)
        for k in range(n):
            y = y0 + (k + 0.5) * (y1 - y0) / n
            R = S.rotation((1, 0, 0), np.radians(-38))
            slat = S.box((0, 0, 0), (w / 2 - frame, pitch * 0.62, 0.0045), tag) if lod else \
                S.chamfer_box((0, 0, 0), (w / 2 - frame, pitch * 0.62, 0.0045), 0.002, tag, edges="front")
            m.merge(slat.transformed(R, o + np.array([w / 2, y, -t * 0.5])))
    return m
