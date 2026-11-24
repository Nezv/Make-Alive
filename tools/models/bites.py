"""Bite variants of the zombies' outfit models: ten named regions torn out of the flesh and the clothes
together, each a model of its own (assets/models/zombie_<outfit>_<m|f>_b<N>.glb) that wears its
outfit's own textures.

How a bite is made (numpy, no Blender; `outfits.py --bites` draws it):

  1. The outfit's triangles are welded per rigid piece (a piece's surface is closed on its own, so a
     gib or a stump shows no hole) and given a consistent winding.
  2. The bite's centre is where a ray from outside, through the bite's `at` along `to`, first hits
     the model; round it a ragged ellipsoid (`Volume`: its edge swings in and out in a few
     harmonics) is the part that goes. The triangles near it are split (red-green refinement, no
     T-junctions) so the torn edge is made of 2 cm teeth, not of 8 cm cloth quads.
  3. Every triangle whose middle is in the volume is dropped; pinched points and slivers are
     cleaned until what is left has simple boundary loops. Each loop is closed again by a crater:
     the loop, a wall ring, a floor ring and a floor point, each pushed down and inwards with a
     little jitter, so the opening is a pit of torn flesh and never see-through. Every rigid piece
     the volume reaches gets its own crater, so each stays closed when it comes off.
  4. Under the hole only that region's bones show: a few ribs, the humerus, radius and ulna, the
     femur, the tibia and fibula, cervical vertebrae, a collarbone (`BITES[..].bones`), whole closed
     prisms set into the crater, dropped onto the surface under them and pushed down to a depth.
  5. The cloth round the opening is soaked: the triangles touching the rim are painted dark blood.

A variant keeps the base model's UVs (every kept or split triangle maps through its parent's
corners), so it wears the same albedo and emission maps; the crater, the bones and the soaked rim map
to single texels of that texture picked by what they should look like (`swatches`), flat like the
faceted body. One texture and one rig for the outfit, ten small meshes.

    python tools/models/outfits.py --bites nurse --f     -> references/shots/bites_nurse_f.png
    python tools/models/bites.py --check                  -> closed pieces, bones inside, for every outfit
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np  # noqa: E402

import body as B  # noqa: E402
from poly import Mesh, strip, knob, tapered_block  # noqa: E402

# --- The ten bites --------------------------------------------------------------------------------
# `at` and `to`: a point on the way in and the direction of travel; the ray from `at - 0.4 * to`
# along `to` first meets the model at the bite's centre (the same two numbers are in
# Characters.BITES, the game's test casts that ray at every outfit). `r`: half sizes across (u, along
# the floor's horizontal), along (v, up it) and out of the surface (w). `depth`: how deep the pit
# goes. `bones`: what shows in it, in the surface's frame: kind line (along "u" or "v", `off` the
# other way, `at` along it, `len`, `drop` = fraction of the depth it lies at, half width, half
# thickness), knob (a joint's end, radius), column (stacked vertebrae); `seg`: which rigid piece's
# crater it goes in (None: every one the bite has).

BITES = [
    dict(name="abdomen_l", at=(-0.085, 1.07, 0.0), to=(0.0, 0.0, 1.0), r=(0.085, 0.075, 0.055), depth=0.06, seed=11,
         bones=[dict(kind="line", along="u", off=0.062, at=0.0, len=0.15, drop=0.52, w=0.011, t=0.007, seg="torso")]),
    dict(name="abdomen_r", at=(0.09, 1.04, 0.0), to=(-0.2, 0.0, 0.98), r=(0.08, 0.085, 0.055), depth=0.065, seed=23,
         bones=[]),
    dict(name="ribs_r", at=(0.14, 1.25, 0.0), to=(-0.45, 0.0, 0.89), r=(0.075, 0.09, 0.05), depth=0.05, seed=37,
         bones=[dict(kind="line", along="u", off=o, at=0.0, len=0.2, drop=0.55, w=0.012, t=0.008, seg="torso")
                for o in (-0.044, 0.004, 0.052)]),
    dict(name="chest", at=(-0.05, 1.38, 0.0), to=(0.0, 0.1, 1.0), r=(0.075, 0.07, 0.05), depth=0.056, seed=41,
         bones=[dict(kind="line", along="u", off=0.047, at=0.0, len=0.18, drop=0.6, w=0.014, t=0.009, seg="torso"),
                dict(kind="line", along="u", off=-0.012, at=0.0, len=0.18, drop=0.55, w=0.012, t=0.008, seg="torso"),
                dict(kind="line", along="v", off=0.025, at=0.0, len=0.15, drop=0.72, w=0.016, t=0.007, seg="torso")]),
    dict(name="shoulder_l", at=(-0.31, 1.46, 0.0), to=(0.45, -0.55, 0.35), r=(0.07, 0.07, 0.05), depth=0.05, seed=53,
         bones=[dict(kind="line", along="u", off=0.03, at=0.0, len=0.15, drop=0.6, w=0.01, t=0.01, seg="torso"),
                dict(kind="knob", at=(0.0, -0.01), drop=0.78, radius=0.024, seg="torso")]),
    dict(name="upper_arm_r", at=(0.30, 1.34, 0.0), to=(-0.3, 0.0, 0.95), r=(0.05, 0.075, 0.04), depth=0.036, seed=67,
         bones=[dict(kind="line", along="v", off=0.0, at=0.0, len=0.17, drop=0.78, w=0.013, t=0.013, seg=None)]),
    dict(name="forearm_l", at=(-0.30, 1.02, 0.0), to=(0.35, 0.0, 0.94), r=(0.045, 0.07, 0.04), depth=0.05, seed=79,
         bones=[dict(kind="line", along="v", off=-0.011, at=0.0, len=0.17, drop=0.8, w=0.0085, t=0.0085, seg="forearm_l"),
                dict(kind="line", along="v", off=0.011, at=0.012, len=0.13, drop=0.8, w=0.0075, t=0.0075, seg="forearm_l")]),
    dict(name="thigh_r", at=(0.12, 0.72, 0.0), to=(-0.35, 0.0, 0.94), r=(0.07, 0.085, 0.05), depth=0.05, seed=83,
         bones=[dict(kind="line", along="v", off=0.0, at=0.0, len=0.2, drop=0.8, w=0.019, t=0.019, seg="thigh_r")]),
    dict(name="calf_l", at=(-0.12, 0.34, 0.0), to=(0.0, 0.0, -1.0), r=(0.05, 0.075, 0.04), depth=0.046, seed=97,
         bones=[dict(kind="line", along="v", off=-0.004, at=0.0, len=0.18, drop=0.8, w=0.013, t=0.013, seg="shin_l"),
                dict(kind="line", along="v", off=0.022, at=0.012, len=0.14, drop=0.8, w=0.0075, t=0.0075, seg="shin_l")]),
    dict(name="neck", at=(0.0, 1.57, 0.0), to=(0.8, -0.1, 0.6), r=(0.05, 0.055, 0.04), depth=0.046, seed=101,
         bones=[dict(kind="column", at=(0.0, 0.0), n=3, size=0.024, gap=0.034, drop=0.85, seg="head")]),
]
# Every hole is this much wider across the surface than first drawn and a little deeper: at 3 m the
# first ones could hardly be seen. What shows in it is the real skeleton (tools/models/skeleton.py),
# not shapes made up for the hole: see `skeleton_for`.
SIZE = 1.75
DEEPER = 1.2
for _b in BITES:
    _b["r"] = (_b["r"][0] * SIZE, _b["r"][1] * SIZE, _b["r"][2])
    _b["depth"] *= DEEPER
    _b["bones"] = []
NAMES = [b["name"] for b in BITES]

# What a face of a variant is for the painter and the sketch: its own colour (RGB 0..1).
KINDS = {
    "rim": np.array([0.24, 0.03, 0.04]),      # the torn edge, blood-dark
    "flesh": np.array([0.55, 0.09, 0.09]),    # raw flesh in the wall of the pit
    "deep": np.array([0.3, 0.04, 0.06]),      # the dark floor
    "bone": np.array([0.84, 0.8, 0.68]),
    "marrow": np.array([0.6, 0.2, 0.18]),     # a bone's broken end
    "soak": np.array([0.3, 0.04, 0.05]),      # cloth and skin round the rim, soaked
}


# --- A closed triangle soup ----------------------------------------------------------------------

def _edge(a, b):
    return (a, b) if a < b else (b, a)


class Soup:
    """The outfit as triangles welded per rigid piece (a piece is its own closed surface), every
    triangle with its tag, base piece, parent (the base triangle it was cut from), and kind (None
    for the outfit, else what the bite made it)."""

    def __init__(self, mesh, piece_of):
        P, T, tags = mesh.triangles()
        self.base_P, self.base_T = P, T
        seg_of = [d[1] for d in mesh.vdata]
        key = {}
        self.P, self.vd = [], []
        W = []
        for i, pt in enumerate(P):
            k = (tuple(np.round(pt, 6)), seg_of[i])
            if k not in key:
                key[k] = len(self.P)
                self.P.append(np.array(pt, dtype=np.float64))
                self.vd.append(mesh.vdata[i])
            W.append(key[k])
        self.T, self.tag, self.piece, self.seg, self.parent, self.kind, self.alive = [], [], [], [], [], [], []
        face_piece = []
        for f, pc in zip(mesh.faces, piece_of):
            face_piece += [pc] * (len(f) - 2)
        for j, (t, tg) in enumerate(zip(T, tags)):
            a, b, c = (W[i] for i in t)
            if len({a, b, c}) < 3:
                continue
            self.T.append([a, b, c])
            self.tag.append(tg)
            self.piece.append(face_piece[j])
            self.seg.append(seg_of[t[0]])
            self.parent.append(j)
            self.kind.append(None)
            self.alive.append(True)
        self.orient()

    # --- structure ---------------------------------------------------------------------------

    def tris_of(self, seg):
        return [i for i in range(len(self.T)) if self.alive[i] and self.seg[i] == seg]

    def orient(self):
        """A consistent winding by flood fill, each connected piece outward (positive volume)."""
        ids = [i for i in range(len(self.T)) if self.alive[i]]
        edges = {}
        for i in ids:
            a, b, c = self.T[i]
            for e in ((a, b), (b, c), (c, a)):
                edges.setdefault(_edge(*e), []).append(i)
        seen = set()
        for s in ids:
            if s in seen:
                continue
            comp = [s]
            seen.add(s)
            k = 0
            while k < len(comp):
                i = comp[k]
                k += 1
                a, b, c = self.T[i]
                for e in ((a, b), (b, c), (c, a)):
                    users = edges[_edge(*e)]
                    if len(users) != 2:
                        continue
                    j = users[0] if users[1] == i else users[1]
                    if j in seen:
                        continue
                    ja, jb, jc = self.T[j]
                    if e in ((ja, jb), (jb, jc), (jc, ja)):  # same direction as ours: flip it
                        self.T[j] = [ja, jc, jb]
                    seen.add(j)
                    comp.append(j)
            vol = 0.0
            for i in comp:
                a, b, c = (self.P[v] for v in self.T[i])
                vol += float(np.dot(a, np.cross(b, c)))
            if vol < 0:
                for i in comp:
                    a, b, c = self.T[i]
                    self.T[i] = [a, c, b]

    def tri_pts(self, ids):
        T = np.array([self.T[i] for i in ids])
        P = np.array(self.P)
        return P[T[:, 0]], P[T[:, 1]], P[T[:, 2]]

    def normals(self, ids):
        A, Bq, C = self.tri_pts(ids)
        n = np.cross(Bq - A, C - A)
        return n, np.linalg.norm(n, axis=1)

    def add_vertex(self, pos, vd):
        self.P.append(np.asarray(pos, dtype=np.float64))
        self.vd.append(vd)
        return len(self.P) - 1

    def add_tri(self, abc, tag, kind, like):
        self.T.append(list(abc))
        self.tag.append(tag)
        self.piece.append(self.piece[like])
        self.seg.append(self.seg[like])
        self.parent.append(-1 if kind else self.parent[like])
        self.kind.append(kind)
        self.alive.append(True)
        return len(self.T) - 1

    # --- refinement --------------------------------------------------------------------------

    def _mid(self, cache, a, b):
        k = _edge(a, b)
        if k not in cache:
            wa, wb = self.vd[a][0], self.vd[b][0]
            w = {}
            for bone in set(wa) | set(wb):
                w[bone] = 0.5 * (wa.get(bone, 0.0) + wb.get(bone, 0.0))
            cache[k] = self.add_vertex(0.5 * (self.P[a] + self.P[b]), (w, self.vd[a][1]))
        return cache[k]

    def refine(self, seg, want):
        """One pass of red-green refinement over the piece's triangles: those `want(i)` says go
        are split in four, their neighbours in two, three or four so no point sits on a neighbour's
        edge. Returns how many triangles were split."""
        ids = self.tris_of(seg)
        split = set()
        red = 0
        for i in ids:
            if want(i):
                a, b, c = self.T[i]
                split |= {_edge(a, b), _edge(b, c), _edge(c, a)}
                red += 1
        if not split:
            return 0
        cache = {}
        for i in ids:
            v = list(self.T[i])
            f = [_edge(v[0], v[1]) in split, _edge(v[1], v[2]) in split, _edge(v[2], v[0]) in split]
            k = sum(f)
            if k == 0:
                continue
            while (not f[0]) if k == 1 else (k == 2 and not (f[0] and f[1])):
                v = v[1:] + v[:1]
                f = f[1:] + f[:1]
            self.alive[i] = False
            tg, kd = self.tag[i], self.kind[i]
            par, pc = self.parent[i], self.piece[i]

            def new(abc):
                j = self.add_tri(abc, tg, kd, i)
                self.parent[j] = par
                self.piece[j] = pc
            m01 = self._mid(cache, v[0], v[1]) if f[0] else None
            m12 = self._mid(cache, v[1], v[2]) if f[1] else None
            m20 = self._mid(cache, v[2], v[0]) if f[2] else None
            if k == 1:
                new([v[0], m01, v[2]])
                new([m01, v[1], v[2]])
            elif k == 2:
                new([m01, v[1], m12])
                if np.linalg.norm(self.P[m01] - self.P[v[2]]) < np.linalg.norm(self.P[v[0]] - self.P[m12]):
                    new([v[0], m01, v[2]])
                    new([m01, m12, v[2]])
                else:
                    new([v[0], m01, m12])
                    new([v[0], m12, v[2]])
            else:
                new([v[0], m01, m20])
                new([m01, v[1], m12])
                new([m20, m12, v[2]])
                new([m01, m12, m20])
        return red


# --- The volume that goes ------------------------------------------------------------------------

class Volume:
    """A ragged ellipsoid: `c` its centre, `u`, `v`, `w` its axes (w points out of the surface),
    `r` its half sizes. Its edge swings in and out round w in a few harmonics: a tear, not a drill."""

    def __init__(self, c, u, v, w, r, seed):
        self.c, self.u, self.v, self.w, self.r = c, u, v, w, r
        rng = np.random.default_rng(seed)
        self.phase = rng.uniform(0, 2 * np.pi, 5)
        self.amp = np.array([0.1, 0.17, 0.14, 0.1, 0.07])

    def local(self, pts):
        q = np.asarray(pts) - self.c
        return q @ self.u, q @ self.v, q @ self.w

    def inside(self, pts, grow=1.0):
        a, b, h = self.local(pts)
        ru, rv, rw = self.r
        e = np.sqrt((a / ru) ** 2 + (b / rv) ** 2 + (h / rw) ** 2)
        th = np.arctan2(b / rv, a / ru)
        f = 1.0 + sum(self.amp[k] * np.sin((k + 2) * th + self.phase[k]) for k in range(5))
        return e < f * grow


def ray_first(A, Bq, C, o, d, tmin=1e-4):
    """The first hit (distance, triangle) of the ray o + t d on triangles (A, B, C), or (None, -1)."""
    e1, e2 = Bq - A, C - A
    pv = np.cross(d, e2)
    det = (e1 * pv).sum(1)
    ok = np.abs(det) > 1e-12
    inv = np.where(ok, 1.0 / np.where(ok, det, 1.0), 0.0)
    tv = o - A
    u = (tv * pv).sum(1) * inv
    qv = np.cross(tv, e1)
    v = (qv * d).sum(1) * inv
    t = (qv * e2).sum(1) * inv
    hit = ok & (u >= -1e-9) & (v >= -1e-9) & (u + v <= 1 + 1e-9) & (t > tmin)
    if not hit.any():
        return None, -1
    idx = np.nonzero(hit)[0]
    k = idx[np.argmin(t[idx])]
    return float(t[k]), int(k)


# --- Making a bite -----------------------------------------------------------------------------

def _hash_pick(i, seed, n):
    return int((i * 2654435761 + seed * 40503) % 4294967296) % n


def make_frame(w, up=(0.0, 1.0, 0.0)):
    w = w / np.linalg.norm(w)
    up = np.asarray(up, dtype=np.float64)
    if abs(w @ up) > 0.9:
        up = np.array([0.0, 0.0, -1.0])
    u = np.cross(up, w)
    u /= np.linalg.norm(u)
    v = np.cross(w, u)
    return u, v, w


def find_centre(soup, spec):
    """Where the ray of the bite first meets the outfit, and the surface's outward direction there
    (the mean of the triangles within 4 cm: a facet's own normal is too jumpy)."""
    to = np.asarray(spec["to"], dtype=np.float64)
    to /= np.linalg.norm(to)
    o = np.asarray(spec["at"], dtype=np.float64) - to * 0.4
    ids = [i for i in range(len(soup.T)) if soup.alive[i]]
    A, Bq, C = soup.tri_pts(ids)
    t, k = ray_first(A, Bq, C, o, to)
    if t is None:
        raise RuntimeError(f"bite {spec['name']} hits nothing")
    c = o + to * t
    n, area = soup.normals(ids)
    mid = (A + Bq + C) / 3
    near = np.linalg.norm(mid - c, axis=1) < 0.04
    w = (n[near] / np.maximum(area[near], 1e-12)[:, None] * area[near, None]).sum(0)
    if np.linalg.norm(w) < 1e-6 or w @ -to < 0:
        w = -to
    return c, w / np.linalg.norm(w), to


def boundary(soup, tris):
    """(directed boundary edges {a: [b..]}, undirected edge -> triangles) of the given triangles."""
    use = {}
    for i in tris:
        a, b, c = soup.T[i]
        for e in ((a, b), (b, c), (c, a)):
            use.setdefault(_edge(*e), []).append(i)
    out = {}
    for i in tris:
        a, b, c = soup.T[i]
        for e in ((a, b), (b, c), (c, a)):
            if len(use[_edge(*e)]) == 1:
                out.setdefault(e[0], []).append(e[1])
    return out, use


def loops_of(out):
    """Closed chains of the boundary (each a list of points)."""
    left = {a: list(bs) for a, bs in out.items()}
    loops = []
    for start in list(left):
        while left.get(start):
            loop = [start]
            cur = left[start].pop()
            while cur != start:
                loop.append(cur)
                if not left.get(cur):
                    raise RuntimeError("boundary does not close")
                cur = left[cur].pop()
            loops.append(loop)
    return loops


def carve(soup, seg, vol, refine_to=0.03):
    """Split the triangles near the volume, drop those inside it and tidy what is left until the
    hole's boundary is made of simple closed loops. Returns (removed triangle count, loops, the
    removed triangles' mean outward normal)."""
    big = lambda i: 1.0  # noqa: E731
    for _ in range(4):
        ids = soup.tris_of(seg)
        A, Bq, C = soup.tri_pts(ids)
        mid = (A + Bq + C) / 3
        near = vol.inside(mid, 1.45)
        longest = np.maximum.reduce([np.linalg.norm(Bq - A, axis=1), np.linalg.norm(C - Bq, axis=1),
                                     np.linalg.norm(A - C, axis=1)])
        flag = dict(zip(ids, near & (longest > refine_to)))
        if not soup.refine(seg, lambda i: flag.get(i, False)):
            break
    ids = soup.tris_of(seg)
    A, Bq, C = soup.tri_pts(ids)
    gone = set(i for i, hit in zip(ids, vol.inside((A + Bq + C) / 3)) if hit)
    if not gone:
        return 0, [], None
    removed = set(gone)
    for _ in range(60):
        kept = [i for i in ids if i not in removed]
        out, use = boundary(soup, kept)
        grow = set()
        # spikes: a kept triangle with two edges on the boundary hangs by a thread
        for i in kept:
            a, b, c = soup.T[i]
            if sum(len(use[_edge(*e)]) == 1 for e in ((a, b), (b, c), (c, a))) >= 2:
                grow.add(i)
        # pinches: a point the boundary passes through twice
        pinch = {a for a, bs in out.items() if len(bs) > 1}
        if pinch:
            for i in kept:
                a, b, c = soup.T[i]
                for e in ((a, b), (b, c), (c, a)):
                    if len(use[_edge(*e)]) == 1 and (e[0] in pinch or e[1] in pinch):
                        grow.add(i)
        # little islands the hole left standing
        if not grow:
            comp = _components(soup, kept)
            for c in comp:
                touched = any(len(use[_edge(*e)]) == 1 for i in c for e in _edges(soup.T[i]))
                if touched and len(c) < 12:
                    grow |= set(c)
        if not grow:
            break
        removed |= grow
    kept = [i for i in ids if i not in removed]
    out, _ = boundary(soup, kept)
    loops = loops_of(out)
    rm = sorted(removed)
    n, area = soup.normals(rm)
    mean_n = n.sum(0)
    for i in rm:
        soup.alive[i] = False
    return len(rm), loops, mean_n / max(np.linalg.norm(mean_n), 1e-12)


def _edges(t):
    a, b, c = t
    return ((a, b), (b, c), (c, a))


def _components(soup, ids):
    use = {}
    for i in ids:
        for e in _edges(soup.T[i]):
            use.setdefault(_edge(*e), []).append(i)
    seen, comps = set(), []
    for s in ids:
        if s in seen:
            continue
        comp = [s]
        seen.add(s)
        k = 0
        while k < len(comp):
            for e in _edges(soup.T[comp[k]]):
                for j in use[_edge(*e)]:
                    if j not in seen:
                        seen.add(j)
                        comp.append(j)
            k += 1
        comps.append(comp)
    return comps


def make_crater(soup, seg, loop, normal, depth, rng, like):
    """Close a boundary loop with a pit: rim, wall ring, floor ring, floor point. Returns the
    points of the pit's middle (for the bones) and the new points."""
    P = soup.P
    rim = list(loop)
    n = len(rim)
    pts = np.array([P[i] for i in rim])
    mid = pts.mean(0)
    # how deep it may go: not through the far side of whatever it is cut in
    ids = soup.tris_of(seg)
    A, Bq, C = soup.tri_pts(ids)
    t, _ = ray_first(A, Bq, C, mid, -normal, 0.004)
    room = depth if t is None else min(depth, 0.65 * t)
    # a pit that is already deeper than it is wide only needs the room
    rings = []
    for alpha, drop, tag_mix in ((0.07, 0.5, ("rim", "flesh")), (0.14, 1.0, ("flesh", "deep"))):
        ring = []
        for k, i in enumerate(rim):
            p = P[i]
            toward = mid - p
            j = rng.normal(0.0, 1.0, 3)
            j -= normal * (j @ normal)
            wob = 1.0 + 0.12 * float(rng.normal())
            pos = p + toward * alpha + (-normal) * room * drop * np.clip(wob, 0.85, 1.2) + j * 0.0045
            ring.append(soup.add_vertex(pos, soup.vd[i]))
        rings.append(ring)
    centre = soup.add_vertex(mid - normal * room * 1.15, soup.vd[rim[0]])
    rows = [rim] + rings
    tags = [("rim", "rim", "rim", "rim", "rim", "flesh"), ("flesh", "flesh", "flesh", "flesh", "flesh", "rim"),
            ("deep", "deep", "deep", "deep", "deep", "flesh")]
    kinds = ["rim", "flesh", "deep"]
    for r in range(2):
        lo, hi = rows[r], rows[r + 1]
        for k in range(n):
            k2 = (k + 1) % n
            quad = [lo[k2], lo[k], hi[k], hi[k2]]
            kd = tags[r][_hash_pick(k + 7 * r, int(rng.integers(0, 1000)), len(tags[r]))]
            for tri in ([quad[0], quad[1], quad[2]], [quad[0], quad[2], quad[3]]):
                soup.add_tri(tri, "wound", kd, like)
    last = rows[-1]
    for k in range(n):
        k2 = (k + 1) % n
        kd = tags[2][_hash_pick(k, int(rng.integers(0, 1000)), len(tags[2]))]
        soup.add_tri([last[k2], last[k], centre], "wound", kd, like)
    return mid, room


def soak_rim(soup, seg, rim_pts, reach=0.022, small=0.045):
    """The cloth and skin touching the opening are soaked: small triangles whose middle is within
    `reach` of a rim point are marked (a big one would paint half a sleeve)."""
    R = np.array(rim_pts)
    for i in soup.tris_of(seg):
        if soup.kind[i] is not None or soup.tag[i] in ("eye", "teeth", "mouth", "hair"):
            continue
        P = np.array([soup.P[v] for v in soup.T[i]])
        if max(np.linalg.norm(P[a] - P[b]) for a, b in ((0, 1), (1, 2), (2, 0))) > small:
            continue
        d = np.linalg.norm(R - P.mean(0), axis=1).min()
        if d < reach:
            soup.kind[i] = "soak"


# --- Bones ---------------------------------------------------------------------------------------

def _surface_drop(A, Bq, C, origin, down, depth):
    """A point dropped from `origin` along `down` onto the first surface it meets, then `depth`
    further down; None if it meets nothing."""
    t, _ = ray_first(A, Bq, C, origin, down, 1e-4)
    if t is None:
        return None
    return origin + down * (t + depth)


SKELETON_BEHIND = 0.06     # the pit's floor lies this far behind the nearest bone
SKELETON_MARGIN = 0.012     # the bones stay this far inside the clothes' own surface
SEG_OF = {(B.HEAD, 0): "head", (B.TORSO, 0): "torso", (B.PELVIS, 0): "torso",
          (B.UPPER_ARM, 1): "upper_arm_r", (B.UPPER_ARM, -1): "upper_arm_l",
          (B.FOREARM, 1): "forearm_r", (B.FOREARM, -1): "forearm_l",
          (B.THIGH, 1): "thigh_r", (B.THIGH, -1): "thigh_l",
          (B.SHIN, 1): "shin_r", (B.SHIN, -1): "shin_l"}


class Bone:
    """A closed piece of the skeleton: points, polygon faces (what `add_mesh` reads)."""
    def __init__(self, verts, faces, tags):
        self.verts, self.faces, self.tags = verts, faces, tags


def skeleton_parts():
    """The whole skeleton as closed components, by the rigid piece they ride: {seg: [Bone]}."""
    import skeleton as S
    out = {}
    for key, mesh in S.bones(B.MALE).items():
        seg = SEG_OF[key]
        parent = list(range(len(mesh.verts)))

        def find(i):
            while parent[i] != i:
                parent[i] = parent[parent[i]]
                i = parent[i]
            return i
        for f in mesh.faces:
            for i in f[1:]:
                parent[find(i)] = find(f[0])
        groups = {}
        for fi, f in enumerate(mesh.faces):
            groups.setdefault(find(f[0]), []).append(fi)
        for fis in groups.values():
            used = sorted({v for fi in fis for v in mesh.faces[fi]})
            remap = {o: n for n, o in enumerate(used)}
            out.setdefault(seg, []).append(Bone(
                [tuple(mesh.verts[o]) for o in used],
                [tuple(remap[v] for v in mesh.faces[fi]) for fi in fis],
                [mesh.tags[fi] for fi in fis]))
    return out


def _inside(pts, A, Bq, C, margin=0.0):
    """Which of `pts` are inside the surface (A, B, C) with `margin` to spare: a ray each way across
    (+x, -x, +z, -z) meets the surface at least `margin` away. (Not a parity count: a rigid piece is
    cloth, skin and caps in layers, and an edge-on hit would fool it.)"""
    res = np.ones(len(pts), dtype=bool)
    for k, o in enumerate(pts):
        for d in ((1.0, 0.0, 0.0), (-1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 0.0, -1.0)):
            t, _ = ray_first(A, Bq, C, o, np.array(d), 1e-5)
            if t is None or t < margin:
                res[k] = False
                break
    return res


def _shrunk(verts, axis, s):
    """Across (x, z) the points are pulled towards the bones' own axis by `s` and the axis is moved to
    where the piece's cloth is centred; the length (y) is kept. axis = (ax, az, tx, tz)."""
    v = np.array(verts, dtype=np.float64)
    v[:, 0] = axis[2] + (v[:, 0] - axis[0]) * s
    v[:, 2] = axis[3] + (v[:, 2] - axis[1]) * s
    return v


def fit_skeleton(parts, seg, surface):
    """How the skeleton of one piece is fitted into it: centred in the cloth (the trunk keeps its own
    axis: the spine lies at the back) and shrunk across, the length kept, until every point of it is
    inside the cloth with SKELETON_MARGIN to spare. Returns (axis, scale), axis as for `_shrunk`."""
    A, Bq, C = surface
    allv = np.vstack([np.array(b.verts) for b in parts])
    ax, az = float(allv[:, 0].mean()), float(allv[:, 2].mean())
    # a bone runs on past its piece into the next one at a joint: only the middle of the piece counts
    cloth = np.vstack([A, Bq, C])
    ys = cloth[:, 1]
    mid = allv[(allv[:, 1] > ys.min() + 0.05) & (allv[:, 1] < ys.max() - 0.05)]
    pick = mid[:: max(1, len(mid) // 90)] if len(mid) else allv[:1]
    pick = pick[:: max(1, len(pick) // 40)]
    # the trunk keeps its own axis (the spine lies at the back); a limb or the head is moved about
    # until the most room is left round it
    shifts = [(0.0, 0.0)] if seg == "torso" else [(dx, dz) for dx in (-0.03, -0.015, 0.0, 0.015, 0.03)
                                                  for dz in (-0.03, -0.015, 0.0, 0.015, 0.03)]
    cloth_c = (ax, az)
    if seg != "torso":
        band = cloth[(ys > ys.min() + 0.05) & (ys < ys.max() - 0.05)]
        if len(band):
            cloth_c = (float(band[:, 0].mean()), float(band[:, 2].mean()))
    for s in (1.0, 0.88, 0.76, 0.64, 0.52, 0.45):
        for dx, dz in sorted(shifts, key=lambda q: abs(q[0]) + abs(q[1])):
            axis = (ax, az, (cloth_c[0] if seg != "torso" else ax) + dx, (cloth_c[1] if seg != "torso" else az) + dz)
            if _inside(_shrunk(pick, axis, s), A, Bq, C, SKELETON_MARGIN).all():
                return axis, float(s)
    return (ax, az, cloth_c[0], cloth_c[1]), 0.45


def skeleton_for(parts, seg, surface, vol, normal, mid):
    """The bones of one piece that show in a bite: every component of its skeleton with a point
    over the hole, shrunk to fit inside the cloth. Returns (meshes, how deep the nearest of them lies
    under the rim, in metres)."""
    if seg not in parts:
        return [], 0.0
    axis, s = fit_skeleton(parts[seg], seg, surface)
    ru, rv, rw = vol.r
    made, front = [], 9.0
    for b in parts[seg]:
        V = _shrunk(b.verts, axis, s)
        a, bb, h = vol.local(V)
        over = np.sqrt((a / ru) ** 2 + (bb / rv) ** 2) < 1.25
        if not over.any() or np.abs(h[over]).min() > 0.2:
            continue
        made.append(Bone([tuple(p) for p in V], b.faces, b.tags))
        front = min(front, float(((mid - V[over]) @ normal).min()))
    return made, (0.0 if front == 9.0 else front)


def add_mesh(soup, mesh, seg, vd, like, kind="bone"):
    """A closed mesh as part of the piece (all its points ride `vd`); its faces are `kind`."""
    P = np.array(mesh.verts)
    base = len(soup.P)
    for p in P:
        soup.add_vertex(p, vd)
    for f, t in zip(mesh.faces, mesh.tags):
        for i in range(1, len(f) - 1):
            soup.add_tri([base + f[0], base + f[i], base + f[i + 1]], "bone", kind, like)


# --- Applying a bite ---------------------------------------------------------------------------

def apply(soup, spec, parts=None):
    """Make the bite in `soup` (a fresh copy of the outfit). Returns a report: the centre, the
    pieces reached and how many triangles went from each."""
    parts = skeleton_parts() if parts is None else parts
    c, w, to = find_centre(soup, spec)
    u, v, w = make_frame(w)
    ru, rv, rw = spec["r"]
    vol = Volume(c, u, v, w, (ru, rv, rw), spec["seed"])
    report = dict(name=spec["name"], centre=c, frame=(u, v, w), segs={})
    segs = sorted({soup.seg[i] for i in range(len(soup.T)) if soup.alive[i]})
    rng = np.random.default_rng(spec["seed"] * 7 + 1)
    for seg in segs:
        ids = soup.tris_of(seg)
        A, Bq, C = soup.tri_pts(ids)
        near = vol.inside((A + Bq + C) / 3, 1.6)
        if not near.any():
            continue
        surface = soup.tri_pts(ids)
        gone, loops, mean_n = carve(soup, seg, vol)
        if not loops:
            continue
        like = soup.tris_of(seg)[0]
        normal = mean_n if mean_n is not None else w
        big = max(loops, key=lambda l: len(l))
        mid0 = np.mean([soup.P[i] for i in big], axis=0)
        shown, front = skeleton_for(parts, seg, surface, vol, normal, mid0)
        # the pit goes down to just behind the nearest bones, so they stand in it with flesh behind them
        depth = max(spec["depth"], front + SKELETON_BEHIND) if front else spec["depth"]
        for lp in loops:
            rim_pts = [soup.P[i] for i in lp]
            make_crater(soup, seg, lp, normal, depth, rng, like)
            soak_rim(soup, seg, rim_pts)
        vd = soup.vd[big[0]]
        room = depth
        for m in shown:
            add_mesh(soup, m, seg, vd, like)
        report["segs"][seg] = dict(removed=gone, loops=len(loops), room=room)
    return report


def compact(soup):
    """The soup as arrays: points (only those used), triangles, per-triangle tag / kind / parent /
    piece, per-point (weights, segment)."""
    ids = [i for i in range(len(soup.T)) if soup.alive[i]]
    used = sorted({v for i in ids for v in soup.T[i]})
    remap = {o: n for n, o in enumerate(used)}
    return dict(
        P=np.array([soup.P[o] for o in used]),
        T=np.array([[remap[v] for v in soup.T[i]] for i in ids], dtype=np.int64),
        tag=[soup.tag[i] for i in ids], kind=[soup.kind[i] for i in ids],
        parent=[soup.parent[i] for i in ids], piece=[soup.piece[i] for i in ids],
        vd=[soup.vd[o] for o in used], seg=[soup.seg[i] for i in ids])


def open_edges(arr, seg=None):
    """Edges not used by exactly two triangles, within each rigid piece (`seg`: only that one)."""
    T, S = arr["T"], arr["seg"]
    count = {}
    for t, s in zip(T, S):
        if seg is not None and s != seg:
            continue
        a, b, c = (int(x) for x in t)
        for e in ((a, b), (b, c), (c, a)):
            k = (s,) + _edge(*e)
            count[k] = count.get(k, 0) + 1
    return sum(1 for c in count.values() if c != 2)


def wrong_way(arr):
    """Directed edges used twice the same way (a face turned against its neighbour)."""
    T = arr["T"]
    seen, bad = set(), 0
    for t in T:
        a, b, c = (int(x) for x in t)
        for e in ((a, b), (b, c), (c, a)):
            if e in seen:
                bad += 1
            seen.add(e)
    return bad


def make(outfit, sex, which):
    """Bite number `which` of one outfit on one body, as arrays, plus a report."""
    import outfits as O
    parts, p = O.dress(outfit, sex)
    mesh, piece_of = O.combined(parts)
    soup = Soup(mesh, piece_of)
    rep = apply(soup, BITES[which])
    return compact(soup), rep, soup


def colours(arr, outfit):
    """A colour per triangle for the sketch: the outfit's own, the bite's where it made it."""
    import outfits as O
    pal = O.colours(outfit)
    cols = []
    for tg, kd in zip(arr["tag"], arr["kind"]):
        cols.append(KINDS[kd] if kd else pal[tg])
    return np.array(cols)


# --- Blender: the variants as models ------------------------------------------------------------

def swatches(maps, albedo, tag_index, seed=5, per_class=48):
    """Texels of the outfit's own painted texture to dress the bite's new faces with: {kind: [(u, v)]}.
    Only texels well inside an island (a 5 x 5 neighbourhood of the same tag), so the margin's blur
    never reaches them: the wound's dark and bright blood, and the bone's pale."""
    mask, tag = maps["mask"], maps["tag"]
    size = mask.shape[0]
    lum = albedo.sum(-1)
    rng = np.random.default_rng(seed)

    def inner(tag_name):
        m = mask & (tag == tag_index[tag_name])
        keep = m.copy()
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                keep &= np.roll(np.roll(m, dy, 0), dx, 1)
        return keep

    def pick(m, lo, hi):
        ys, xs = np.nonzero(m)
        if len(ys) == 0:
            return []
        order = np.argsort(lum[ys, xs])
        a, b = int(len(order) * lo), max(int(len(order) * hi), int(len(order) * lo) + 1)
        sel = order[a:b]
        sel = rng.choice(sel, size=min(per_class, len(sel)), replace=False)
        return [((xs[i] + 0.5) / size, (ys[i] + 0.5) / size) for i in sel]

    wound = inner("wound")
    bone = inner("bone")
    if not bone.any():
        bone = inner("teeth")
    out = dict(rim=pick(wound, 0.02, 0.3), flesh=pick(wound, 0.82, 1.0), deep=pick(wound, 0.0, 0.12),
               bone=pick(bone, 0.3, 0.9))
    out["soak"] = out["rim"]
    out["marrow"] = out["flesh"]
    for k, v in out.items():
        assert v, f"no texels for {k}: the outfit's texture has no {k}"
    return out


def build_all(name, sex, base_obj, maps, albedo, alb_img, em_img, shots=False, only=None):
    """Make every bite's .glb from the outfit just built (`base_obj`: unwrapped and baked,
    `maps`/`albedo`: what the painter had)."""
    import bpy
    import outfits as O
    import pipeline as pl
    me0 = base_obj.data
    uv0 = me0.uv_layers["UVMap"].data
    sw = swatches(maps, albedo, O.TAG)
    polys = []
    for poly in me0.polygons:
        polys.append({vi: tuple(uv0[li].uv) for li, vi in zip(poly.loop_indices, poly.vertices)})
    made = []
    for k, spec in enumerate(BITES):
        if only is not None and k not in only:
            continue
        arr, rep, soup = make(name, sex, k)
        assert len(polys) == len(soup.base_T), "Blender dropped faces of the base: UVs would not line up"
        T, P = arr["T"], arr["P"]
        bt, bp = soup.base_T, soup.base_P
        tri_uv = []
        for t in range(len(T)):
            kind, par = arr["kind"][t], arr["parent"][t]
            uv = {}
            if kind is not None:
                pool = sw[kind]
                u0 = pool[(t * 2654435761) % len(pool)]
                for vi in T[t]:
                    uv[int(vi)] = u0
            else:
                A, Bq, C = (bp[i] for i in bt[par])
                e1, e2 = Bq - A, C - A
                d00, d01, d11 = e1 @ e1, e1 @ e2, e2 @ e2
                den = d00 * d11 - d01 * d01
                pu = [polys[par][int(i)] for i in bt[par]]
                for vi in T[t]:
                    q = P[vi] - A
                    d20, d21 = q @ e1, q @ e2
                    b1 = (d11 * d20 - d01 * d21) / den
                    b2 = (d00 * d21 - d01 * d20) / den
                    b1, b2 = float(np.clip(b1, 0, 1)), float(np.clip(b2, 0, 1))
                    uv[int(vi)] = (pu[0][0] + (pu[1][0] - pu[0][0]) * b1 + (pu[2][0] - pu[0][0]) * b2,
                                   pu[0][1] + (pu[1][1] - pu[0][1]) * b1 + (pu[2][1] - pu[0][1]) * b2)
            tri_uv.append(uv)
        model = f"zombie_{name}_{sex}_b{k}"
        tagn = [O.TAG["bone" if kd in ("bone",) else ("wound" if kd else tg)] for kd, tg in zip(arr["kind"], arr["tag"])]
        obj = pl.mesh_from_poly(model, P, T, {"piece": arr["piece"], "tag": tagn},
                                weights=[d[0] for d in arr["vd"]], segments=[d[1] for d in arr["vd"]])
        me = obj.data
        assert len(me.polygons) == len(T), "Blender dropped faces of the variant"
        uvl = me.uv_layers["UVMap"].data
        for poly in me.polygons:
            m = tri_uv[poly.index]
            for li, vi in zip(poly.loop_indices, poly.vertices):
                uvl[li].uv = m[vi]
        pl.textured_material(obj, alb_img, em_img)
        arm = pl.add_rig(obj)
        pl.export_glb([obj, arm], os.path.join(O.OUT, model + ".glb"))
        print(f"built {model} ({spec['name']}): {len(T)} triangles")
        if shots:
            c = rep["centre"]
            to = np.asarray(spec["to"], dtype=np.float64)
            to /= np.linalg.norm(to)
            views = [("close", tuple(c - to * 0.6), tuple(c), 70),
                     ("wide", tuple(c - to * 2.6 + np.array([0, 0.3, 0])), tuple(c * 0.5 + np.array([0, 0.5, 0])), 50)]
            pl.render_views(obj, O.SHOTS, "bite_" + model, views, size=(540, 540))
            made += [os.path.join(O.SHOTS, f"bite_{model}_{v[0]}.png") for v in views]
        bpy.data.objects.remove(arm)
        bpy.data.objects.remove(obj)
    return made


# --- Sketch (no Blender) -------------------------------------------------------------------------

def sketch(outfit, sexes, path_fmt, which=None):
    """Every bite of an outfit as flat-shaded pictures: close up from outside, from the side so the
    pit's depth shows, and a wider view for scale. `which`: bite numbers (default all)."""
    import sketch as sk
    which = list(range(len(BITES))) if which is None else which
    for sex in sexes:
        close, side, wide = [], [], []
        for k in which:
            arr, rep, _ = make(outfit, sex, k)
            P, T = arr["P"], arr["T"]
            cols = colours(arr, outfit)
            c = rep["centre"]
            to = np.asarray(BITES[k]["to"], dtype=np.float64)
            to /= np.linalg.norm(to)
            u, v, w = rep["frame"]
            close.append(sk.render(P, T, cols, c - to * 0.5, c, size=(330, 330), focal=3.4))
            sideways = u * 0.55 + w * 0.2
            side.append(sk.render(P, T, cols, c + sideways, c, size=(330, 330), focal=3.4))
            wide.append(sk.render(P, T, cols, c - to * 1.8 + np.array([0.0, 0.25, 0.0]), c * 0.6 + np.array([0, 0.5, 0.0]),
                                  size=(330, 460), focal=2.0))
            print(f"{outfit} {sex} {BITES[k]['name']}: {len(T)} triangles, open {open_edges(arr)}, "
                  + ", ".join(f"{s} -{r['removed']}" for s, r in rep["segs"].items()))
        path = path_fmt.format(outfit, sex)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        half = (len(close) + 1) // 2
        rows = []
        for a in (0, half):
            if a >= len(close):
                break
            for group in (close, side, wide):
                rows.append(group[a:a + half])
        w_img = max(len(r) for r in rows)
        for r in rows:  # pad short rows so the sheet is a rectangle
            while len(r) < w_img:
                r.append(np.zeros_like(r[0]))
        sk.sheet_mixed(rows, path)
        print("wrote", path)


if __name__ == "__main__":
    import outfits as O
    if "--check" in sys.argv:
        bad = 0
        for outfit in O.NAMES:
            for sex in "mf":
                for k in range(len(BITES)):
                    arr, rep, _ = make(outfit, sex, k)
                    oe = open_edges(arr)
                    ww = wrong_way(arr)
                    if oe or ww or not rep["segs"]:
                        bad += 1
                    print(f"{outfit} {sex} {BITES[k]['name']}: {len(arr['T'])} tris, "
                          f"open {oe}, wrong-way {ww}, pieces {sorted(rep['segs'])}")
        print("BAD" if bad else "all closed", bad)
        sys.exit(1 if bad else 0)
