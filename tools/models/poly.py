"""Low-poly modelling in numpy: a few flat faces per shape, never a curve.

A Mesh is points and faces; every face carries a tag (what it is: skin, eye, mouth...) that
the painter colours it by. Shapes are rings of points lofted into prisms (limbs, torso, head),
boxes and tapered blocks (fingers, teeth), mirrored for the other side. Rings may be bent
(each point at its own height) and features are made by moving single points, which is how a
face gets a brow that overhangs the eyes or a mouth sunk into the jaw.

Game coordinates: metres, Y up, the model faces -Z, its right side is +X. Faces are written
as polygons; `triangles()` cuts quads along their shorter diagonal, which mirrors cleanly, so
both halves of the body crease the same way.
"""
import numpy as np


def V(x, y, z):
    return np.array([x, y, z], dtype=np.float64)


def _shift(band_tags, first_tag):
    """Band tags for a loft that got a tip ring in front: the tip's band takes `first_tag`."""
    def f(r, j):
        if r == 0:
            return first_tag
        return band_tags(r - 1, j) if band_tags else None
    return f


def other_side(name):
    """A bone or segment name of one side as the other side's ("shoulder_r_mid" -> "shoulder_l_mid")."""
    swap = {"l": "r", "r": "l"}
    return "_".join(swap.get(t, t) for t in name.split("_"))


class Mesh:
    """Points, faces and a tag per face. A point may also carry skinning data, `(weights,
    segment)`: {bone: weight} and the rigid piece it goes with when the model comes apart
    (clothes set it; body pieces leave it None and get theirs from the piece they are)."""

    def __init__(self):
        self.verts = []
        self.faces = []
        self.tags = []
        self.vdata = []
        self.units = []  # a whole number per face: which brick, sett or tile it belongs to (0 = none)

    # --- building ---------------------------------------------------------------------------

    def add(self, points, data=None):
        """Add points; `data` is one (weights, segment) for all of them, or a list, one each."""
        base = len(self.verts)
        pts = np.asarray(points, dtype=np.float64).reshape(-1, 3)
        for i, p in enumerate(pts):
            self.verts.append(p.copy())
            self.vdata.append(data[i] if isinstance(data, list) else data)
        return base

    def face(self, idx, tag, unit=0):
        self.faces.append(tuple(int(i) for i in idx))
        self.tags.append(tag)
        self.units.append(int(unit))

    def units_list(self):
        """One unit per face (faces set by hand without one count as unit 0)."""
        return self.units if len(self.units) == len(self.faces) else [0] * len(self.faces)

    def set_unit(self, unit):
        self.units = [int(unit)] * len(self.faces)
        return self

    def merge(self, other):
        base = len(self.verts)
        if other.verts:
            self.verts += [v.copy() for v in other.verts]
            self.vdata += list(other.vdata) if other.vdata else [None] * len(other.verts)
        for f, t, u in zip(other.faces, other.tags, other.units_list()):
            self.face([base + i for i in f], t, u)
        return self

    def copy(self):
        m = Mesh()
        m.verts = [v.copy() for v in self.verts]
        m.faces = list(self.faces)
        m.tags = list(self.tags)
        m.vdata = list(self.vdata)
        m.units = list(self.units_list())
        return m

    def mirrored(self):
        """The same shape on the other side (x -> -x), faces turned to stay outward, bones and
        segments of one side swapped for the other's."""
        m = Mesh()
        m.verts = [v * np.array([-1.0, 1.0, 1.0]) for v in self.verts]
        m.faces = [tuple(reversed(f)) for f in self.faces]
        m.tags = list(self.tags)
        m.units = list(self.units_list())
        m.vdata = [None if d is None else ({other_side(b): w for b, w in d[0].items()}, other_side(d[1]))
                   for d in self.vdata]
        return m

    def transformed(self, basis, origin=(0, 0, 0)):
        m = self.copy()
        B = np.asarray(basis, dtype=np.float64)
        o = np.asarray(origin, dtype=np.float64)
        m.verts = [B @ v + o for v in m.verts]
        return m

    def without(self, drop):
        """A copy without the faces `drop(face's points)` says go (points left unused stay)."""
        m = Mesh()
        m.verts = [v.copy() for v in self.verts]
        m.vdata = list(self.vdata)
        for f, t, u in zip(self.faces, self.tags, self.units_list()):
            if not drop(np.array([self.verts[i] for i in f])):
                m.face(f, t, u)
        return m

    def loft(self, rings, tag="skin", caps=(True, True), cap_tags=(None, None), band_tags=None,
             cap_points=(None, None)):
        """Join rings of points (each the same count, going round the same way) into a closed
        prism. `band_tags(r, j)` may tag the face between ring r and r + 1 at point j. A cap
        is one flat polygon, or a fan to `cap_points[i]` when that is given (a bent ring's cap
        tucked inside another shape); give a ring of a single point to end in a tip instead."""
        rings = [np.asarray(r, dtype=np.float64).reshape(-1, 3) for r in rings]
        if cap_points[0] is not None:
            rings = [np.asarray(cap_points[0], dtype=np.float64)[None]] + rings
            cap_tags = (cap_tags[0], cap_tags[1])
            band_tags = _shift(band_tags, cap_tags[0] or tag)
        if cap_points[1] is not None:
            rings = rings + [np.asarray(cap_points[1], dtype=np.float64)[None]]
            last = len(rings) - 2
            inner = band_tags
            band_tags = (lambda r, j: (cap_tags[1] or tag) if r == last else (inner(r, j) if inner else None))
        return self._loft(rings, tag, caps, cap_tags, band_tags)

    def _loft(self, rings, tag, caps, cap_tags, band_tags):
        rings = [np.asarray(r, dtype=np.float64).reshape(-1, 3) for r in rings]
        n = max(len(r) for r in rings)
        idx = []
        for r in rings:
            if len(r) == 1:
                i = self.add(r)
                idx.append([i] * n)
            else:
                assert len(r) == n, "rings must have the same number of points"
                b = self.add(r)
                idx.append([b + j for j in range(n)])
        for r in range(len(rings) - 1):
            lo, hi = idx[r], idx[r + 1]
            for j in range(n):
                k = (j + 1) % n
                t = band_tags(r, j) if band_tags else None
                quad = [lo[j], lo[k], hi[k], hi[j]]
                uniq = []
                for q in quad:
                    if q not in uniq:
                        uniq.append(q)
                if len(uniq) >= 3:
                    self.face(uniq, t or tag)
        if caps[0] and len(set(idx[0])) > 1:
            self.face(list(reversed(idx[0])), cap_tags[0] or tag)
        if caps[-1] and len(set(idx[-1])) > 1:
            self.face(idx[-1], cap_tags[1] or tag)
        return self

    def block(self, corners_lo, corners_hi, tag="skin"):
        """A six-sided block from its bottom and top quads (each four points, same order)."""
        return self.loft([corners_lo, corners_hi], tag)

    def box(self, center, half, tag="skin", basis=None):
        c = np.asarray(center, dtype=np.float64)
        hx, hy, hz = half
        lo = np.array([[-hx, -hy, -hz], [hx, -hy, -hz], [hx, -hy, hz], [-hx, -hy, hz]])
        hi = lo * np.array([1, -1, 1])
        if basis is not None:
            B = np.asarray(basis, dtype=np.float64)
            lo = lo @ B.T
            hi = hi @ B.T
        return self.block(lo + c, hi + c, tag)

    # --- output -----------------------------------------------------------------------------

    def triangles(self):
        """(vertices, triangles, tag per triangle). Quads are cut on the shorter diagonal;
        bigger polygons are fanned from their first corner (caps are convex)."""
        P = np.array(self.verts)
        tris, tags = [], []
        for f, t in zip(self.faces, self.tags):
            if len(f) == 3:
                tris.append(f)
                tags.append(t)
            elif len(f) == 4:
                a, b, c, d = f
                if np.linalg.norm(P[a] - P[c]) <= np.linalg.norm(P[b] - P[d]) + 1e-9:
                    tris += [(a, b, c), (a, c, d)]
                else:
                    tris += [(a, b, d), (b, c, d)]
                tags += [t, t]
            else:
                for i in range(1, len(f) - 1):
                    tris.append((f[0], f[i], f[i + 1]))
                    tags.append(t)
        return P, np.array(tris, dtype=np.int64), tags

    def triangle_units(self):
        """The unit of every triangle `triangles()` returns, in the same order."""
        out = []
        for f, u in zip(self.faces, self.units_list()):
            out += [u] * (len(f) - 2)
        return out

    def check_closed(self):
        """Every edge used by exactly two faces (a gib must not show a hole). Returns the
        number of open edges."""
        _, T, _ = self.triangles()
        P = np.round(np.array(self.verts), 6)
        _, inv = np.unique(P, axis=0, return_inverse=True)
        inv = inv.ravel()
        count = {}
        for tri in T:
            for i in range(3):
                a, b = inv[tri[i]], inv[tri[(i + 1) % 3]]
                if a == b:
                    continue
                key = (min(a, b), max(a, b))
                count[key] = count.get(key, 0) + 1
        return sum(1 for c in count.values() if c != 2)


# --- Rings ------------------------------------------------------------------------------------

def frame(axis):
    """Two directions across `axis`: `side` (towards +X where it can) and `front` (towards -Z)."""
    a = np.asarray(axis, dtype=np.float64)
    a = a / np.linalg.norm(a)
    ref = np.array([1.0, 0.0, 0.0]) if abs(a[0]) < 0.9 else np.array([0.0, 0.0, -1.0])
    side = ref - a * (ref @ a)
    side /= np.linalg.norm(side)
    front = np.cross(a, side)
    if front[2] > 0:
        front = -front
    return side, front


def ring(center, axis, half_side, half_front, sides=6, turn=0.0, front_shift=0.0, bulge=None):
    """`sides` points round `center` across `axis`: an ellipse's polygon, `half_side` along the
    side direction and `half_front` along the front one. `turn` (radians) spins it so a flat
    face looks forward when `sides` is 6 or 8; `front_shift` moves it forward; `bulge(angle)`
    may scale each point's radius (a calf's back, a kneecap's front)."""
    c = np.asarray(center, dtype=np.float64)
    s, f = frame(axis)
    pts = []
    for j in range(sides):
        a = turn + 2 * np.pi * j / sides
        k = bulge(a) if bulge else 1.0
        pts.append(c + s * np.cos(a) * half_side * k + f * (np.sin(a) * half_front * k + front_shift))
    return np.array(pts)


def limb(top, bottom, stations, sides=6, turn=0.0, tag="skin", cap_tags=(None, None)):
    """A limb from joint `top` towards `bottom`: stations are (distance down the axis from
    `top`, half side, half front[, front shift[, bulge]]); the first and last end in a tip
    when their sizes are 0."""
    top = np.asarray(top, dtype=np.float64)
    axis = np.asarray(bottom, dtype=np.float64) - top
    length = np.linalg.norm(axis)
    down = axis / length
    rings = []
    for st in stations:
        d, hs, hf = st[0], st[1], st[2]
        shift = st[3] if len(st) > 3 else 0.0
        bulge = st[4] if len(st) > 4 else None
        c = top + down * d
        if hs <= 0 and hf <= 0:
            rings.append(c[None])
        else:
            rings.append(ring(c, -down, hs, hf, sides, turn, shift, bulge))
    last = len(rings) - 2

    def ends(r, j):  # a tip's faces are its cap
        if r == 0 and len(rings[0]) == 1:
            return cap_tags[0]
        if r == last and len(rings[-1]) == 1:
            return cap_tags[1]
        return None

    m = Mesh()
    m.loft(rings, tag, cap_tags=cap_tags, band_tags=ends)
    return m


def strip(points, half_w, half_t, up=(0, 1, 0), tag="bone", taper=None):
    """A flat band along a path (a rib, a collarbone, a hip blade): `half_w` across it towards
    `up`, `half_t` thick. `taper(i)` may scale the band at point i."""
    P = [np.asarray(p, dtype=np.float64) for p in points]
    rings = []
    for i, p in enumerate(P):
        a, b = P[max(i - 1, 0)], P[min(i + 1, len(P) - 1)]
        t = b - a
        t /= np.linalg.norm(t)
        u = np.asarray(up, dtype=np.float64) - t * (np.asarray(up, dtype=np.float64) @ t)
        u /= np.linalg.norm(u)
        n = np.cross(t, u)
        k = taper(i) if taper else 1.0
        hw, ht = half_w * k, half_t * k
        rings.append([p - n * ht - u * hw, p + n * ht - u * hw, p + n * ht + u * hw, p - n * ht + u * hw])
    m = Mesh()
    m.loft(rings, tag)
    return m


def knob(center, radius, axis=(0, 1, 0), sides=6, tag="bone", stretch=1.0):
    """A faceted ball (the end of a bone, a joint's head): two rings and two tips."""
    c = np.asarray(center, dtype=np.float64)
    a = np.asarray(axis, dtype=np.float64)
    a = a / np.linalg.norm(a)
    r = radius
    return limb(c + a * r * stretch, c - a * r * stretch,
                [(0.0, 0, 0), (0.55 * r * stretch, 0.8 * r, 0.8 * r), (1.45 * r * stretch, 0.8 * r, 0.8 * r),
                 (2.0 * r * stretch, 0, 0)], sides=sides, turn=np.pi / sides, tag=tag)


def tapered_block(a, b, half_a, half_b, up=(0, 1, 0), tag="skin"):
    """A block from point a to point b, cross-sections `half_a` and `half_b` = (half width,
    half thickness), its thickness along `up` as far as the direction allows (fingers, toes,
    teeth)."""
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    d = b - a
    d /= np.linalg.norm(d)
    u = np.asarray(up, dtype=np.float64)
    u = u - d * (u @ d)
    if np.linalg.norm(u) < 1e-6:
        u = np.array([0.0, 0.0, -1.0]) - d * d[2] * -1
    u /= np.linalg.norm(u)
    w = np.cross(d, u)

    def quad(c, hw, ht):
        return [c - w * hw - u * ht, c + w * hw - u * ht, c + w * hw + u * ht, c - w * hw + u * ht]

    m = Mesh()
    m.block(quad(a, *half_a), quad(b, *half_b), tag)
    return m
