"""Clothes for the zombie bodies of tools/models/body.py: shirts and jackets with long or short
sleeves, trousers and shorts, shoes and boots. Each garment is fitted to the male or the female
body by slicing it: a ring of the garment is the outline of the body at that height (its convex
hull, the way cloth spans hollows) pushed out by the garment's ease.

A garment is one continuous surface: the sleeve grows out of the shirt's armhole, both legs out
of the trousers' seat, and it bends at a joint instead of breaking there. Under it the body is
cut away (it would only poke through); what is left of the body (head, hands, bare forearms or
shins) is closed where it was cut, inside the clothes.

How a garment bends: every ring of it rides one bone (nothing is blended, so nothing pinches).
At each joint the ring round it rides a helper bone that turns half as far as the joint
(shoulder_r_mid, elbow_r_mid, hip_r_mid, knee_r_mid; the game turns them, Humanoid._apply), so a
bend is shared by the two bands either side of it. The torso rings blend spine and hips like the
body's own.

Coming apart: that half-turning ring is also where the garment is cut into the game's rigid pieces
(a gib, a ragdoll): it is there twice, once for each piece, each closed by a wound. Every point
says which piece it goes with (Mesh.vdata, then a UV channel in the .glb), so a sleeve's gib is
exactly the sleeve between its two cuts. Every opening of a garment (collar, cuff, hem) turns in
under whatever comes out of it (neck, wrist, shoe, the shirt under the trousers) and is closed
there: each piece is a closed surface, and a severed head or arm leaves a wound, not a hole.

Game coordinates: metres, Y up, facing -Z, the model's right is +X. Garments are built for the
right side and mirrored.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np  # noqa: E402

import body as B  # noqa: E402
from poly import Mesh, V  # noqa: E402

# Joints at rest (pipeline.BONES); the helpers sit on their joints.
SHOULDER_Y = B.SHOULDER[1]
ELBOW_Y = B.ELBOW[1]
HIP_Y = B.HIP[1]
KNEE_Y = B.KNEE[1]


# --- Skinning data ----------------------------------------------------------------------------

def on(bone, seg):
    """A point riding one bone, going with one piece."""
    return ({bone: 1.0}, seg)


def trunk(points, p):
    """The torso's rule (body.skin_weights): spine above the body's break, hips below, half and
    half on it; all with the torso piece."""
    out = []
    for x, y, z in np.asarray(points).reshape(-1, 3):
        t = float(np.clip((y - B.seam_y(x, z, p) + 0.05) / 0.1, 0, 1))
        t = t * t * (3 - 2 * t)
        w = {k: v for k, v in (("spine", t), ("hips", 1.0 - t)) if v > 1e-4}
        out.append((w, "torso"))
    return out


# --- 2D outlines ------------------------------------------------------------------------------

def hull(pts):
    """Convex hull of (x, z) points, counter-clockwise (x right, z up)."""
    pts = np.unique(np.round(np.asarray(pts, dtype=np.float64), 6), axis=0)
    if len(pts) < 3:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower, upper = [], []
    for q in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], q) <= 0:
            lower.pop()
        lower.append(q)
    for q in pts[::-1]:
        while len(upper) >= 2 and cross(upper[-2], upper[-1], q) <= 0:
            upper.pop()
        upper.append(q)
    return np.array(lower[:-1] + upper[:-1])


def grow(H, d):
    """The outline pushed out by d (corners mitred, at most twice as far)."""
    n = len(H)
    out = []
    for i in range(n):
        a, b, c = H[i - 1], H[i], H[(i + 1) % n]
        e0, e1 = b - a, c - b
        n0 = np.array([e0[1], -e0[0]]) / max(np.linalg.norm(e0), 1e-9)
        n1 = np.array([e1[1], -e1[0]]) / max(np.linalg.norm(e1), 1e-9)
        m = n0 + n1
        m /= max(np.linalg.norm(m), 1e-9)
        k = min(1.0 / max(m @ n0, 0.5), 2.0)
        out.append(b + m * d * k)
    return np.array(out)


def exit_point(H, c, d):
    """Where a ray from c (inside H) along d leaves the outline."""
    best = None
    n = len(H)
    for i in range(n):
        a, b = H[i], H[(i + 1) % n]
        e = b - a
        den = d[0] * (-e[1]) - d[1] * (-e[0])
        if abs(den) < 1e-12:
            continue
        r = a - c
        t = (r[0] * (-e[1]) - r[1] * (-e[0])) / den
        s = (d[0] * r[1] - d[1] * r[0]) / den
        if t > 0 and -1e-9 <= s <= 1 + 1e-9 and (best is None or t < best):
            best = t
    if best is None:
        return c.copy()
    return c + d * best


def vline(H, x):
    """The front (smallest z) and back (largest z) of the outline at x."""
    zs = []
    n = len(H)
    for i in range(n):
        a, b = H[i], H[(i + 1) % n]
        if (a[0] - x) * (b[0] - x) <= 0 and abs(b[0] - a[0]) > 1e-12:
            t = (x - a[0]) / (b[0] - a[0])
            zs.append(a[1] + (b[1] - a[1]) * t)
        elif abs(a[0] - x) < 1e-12:
            zs.append(a[1])
    if not zs:
        i = int(np.argmin(np.abs(H[:, 0] - x)))
        return H[i, 1], H[i, 1]
    return min(zs), max(zs)


def side_point(H):
    """The widest point of the outline (largest x)."""
    xm = H[:, 0].max()
    near = H[np.abs(H[:, 0] - xm) < 1e-4]
    return np.array([xm, near[:, 1].mean()])


# Ring directions of a limb (right side): outer (+X), front-outer, front (-Z), front-inner,
# inner, back-inner, back (+Z), back-outer.
LIMB_DIRS = [np.array([np.cos(k * np.pi / 4), -np.sin(k * np.pi / 4)]) for k in range(8)]


def limb_ring(H, centre, y, ease):
    """Eight points round a limb at height y: where rays from its axis leave its outline,
    pushed out by `ease`."""
    c = np.asarray(centre, dtype=np.float64)
    G = grow(H, ease)
    return np.array([[q[0], y, q[1]] for q in (exit_point(G, c, d) for d in LIMB_DIRS)])


def round_ring(centre, y, rx, rz, n=8):
    """A ring of n points at height y (k = 0 outward, going round like LIMB_DIRS)."""
    cx, cz = centre
    return np.array([[cx + rx * np.cos(2 * np.pi * k / n), y, cz - rz * np.sin(2 * np.pi * k / n)] for k in range(n)])


# --- The body, sliced ---------------------------------------------------------------------------

class Fit:
    """One body variant as the clothes see it: its pieces (to slice) and where its limbs hang."""

    def __init__(self, p):
        self.p = p
        self.parts = B.pieces(p)
        self._tri = {}
        for key, m in self.parts.items():
            P, T, _ = m.triangles()
            self._tri[key] = (P, T)
        self.arm_x = B.SHOULDER[0] - p["arm_in"]
        self.leg_x = B.HIP[0]
        s = p["head_h"] / 0.32
        self.neck_top = p["chin_y"] + 0.11 * s
        self.neck_r = (p["neck"][0] * 1.04, p["neck"][1] * 1.04)

    def neck_z(self, y):
        """The neck's axis leans back a little as it goes down (body.head)."""
        return 0.006 + (self.neck_top - y) / (self.neck_top - 1.46) * 0.01

    def outline(self, keys, y):
        """Convex hull (x, z) of the body pieces `keys` = [(piece, side)] cut at height y."""
        pts = []
        for key in keys:
            if key not in self._tri:
                continue
            P, T = self._tri[key]
            for a, b in ((0, 1), (1, 2), (2, 0)):
                A, C = P[T[:, a]], P[T[:, b]]
                da, dc = A[:, 1] - y, C[:, 1] - y
                hit = (da * dc) < 0
                if hit.any():
                    t = da[hit] / (da[hit] - dc[hit])
                    Q = A[hit] + (C[hit] - A[hit]) * t[:, None]
                    pts.append(Q[:, [0, 2]])
        if not pts:
            return None
        return hull(np.concatenate(pts))

    def trunk_outline(self, y):
        keys = [(B.TORSO, 0), (B.PELVIS, 0)]
        if y < 1.0:
            keys += [(B.THIGH, 1), (B.THIGH, -1)]
        return self.outline(keys, y)

    def arm_outline(self, y):
        return self.outline([(B.UPPER_ARM, 1), (B.FOREARM, 1)], y)

    def leg_outline(self, y):
        return self.outline([(B.THIGH, 1), (B.SHIN, 1)], y)


# --- Building shells ---------------------------------------------------------------------------

class Shell:
    """A garment being built: rings of points with their skinning data, quads between them."""

    def __init__(self):
        self.m = Mesh()

    def ring(self, pts, data):
        base = self.m.add(pts, data)
        return list(range(base, base + len(pts)))

    def quad(self, a, b, c, d, tag):
        self.m.face([a, b, c, d], tag)

    def band(self, lo, hi, tag, skip=()):
        """Quads between two rings going round the same way (j to j + 1, closed)."""
        n = len(lo)
        for j in range(n):
            if j in skip:
                continue
            k = (j + 1) % n
            t = tag(j) if callable(tag) else tag
            self.quad(lo[j], lo[k], hi[k], hi[j], t)

    def cap(self, ring, tag, data):
        """Close a ring with a fan to its middle (the middle rides `data`)."""
        P = np.array([self.m.verts[i] for i in ring])
        c = self.m.add(P.mean(0), data)
        n = len(ring)
        for j in range(n):
            self.m.face([ring[j], ring[(j + 1) % n], c], tag)

    def cut(self, pts, seg_a, seg_b, bone, tag="wound"):
        """A ring where the garment is cut in two pieces: once for each, each closed by a wound.
        Returns (ring of piece a, ring of piece b)."""
        a = self.ring(pts, on(bone, seg_a))
        b = self.ring(pts, on(bone, seg_b))
        self.cap(a, tag, on(bone, seg_a))
        self.cap(b, tag, on(bone, seg_b))
        return a, b

    def point(self, i):
        return self.m.verts[i]


def turned_in(ring_pts, inner_pts):
    """Points of a hem turned in: same heights as the hem, positions of the surface under it."""
    out = np.array(inner_pts, dtype=np.float64)
    out[:, 1] = np.asarray(ring_pts)[:, 1]
    return out


# --- Torso rows ----------------------------------------------------------------------------------
# A torso ring is a right half (centre front ... centre back) and its mirror. Its columns are
# named; each says where it lies on the half outline: on the front at a fraction of the width,
# at the side, or on the back. The armhole is cut between the rows "A" (armpit) and "S"
# (shoulder) at the columns f2, s and b2.

TORSO_COLS = [("cf", "f", 0.0), ("f1", "f", 0.45), ("f2", "f", 0.82), ("s", "s", 1.0),
              ("b2", "b", 0.82), ("b1", "b", 0.45), ("cb", "b", 0.0)]


def full_ring(half):
    """Right half (centre front .. centre back, 7 points) to the whole ring (12 points)."""
    left = [np.array([-q[0], q[1], q[2]]) for q in reversed(half[1:-1])]
    return [np.asarray(q, dtype=np.float64) for q in half] + left


def half_from_outline(H, y, cols=TORSO_COLS):
    """A row's right half from a body outline at y (already grown by the ease)."""
    w = H[:, 0].max()
    sp = side_point(H)
    half = []
    for _, kind, f in cols:
        if kind == "s":
            half.append([sp[0], y, sp[1]])
        else:
            zf, zb = vline(H, f * w)
            half.append([f * w, y, zf if kind == "f" else zb])
    return np.array(half)


def half_from_points(pts, cols=TORSO_COLS):
    """A designed row's right half (points for cf, f1, f2, s, b2, b1, cb, a polyline from the
    centre front over the side point to the centre back) re-sampled at `cols`, each column by its
    x on the front or the back half of it."""
    pts = np.asarray(pts, dtype=np.float64)
    front, back = pts[:4], pts[3:][::-1]   # both from the centre out to the side
    w = pts[3, 0]
    out = []
    for _, kind, f in cols:
        if kind == "s":
            out.append(pts[3])
            continue
        line = front if kind == "f" else back
        x = f * w
        xs = line[:, 0]
        i = int(np.clip(np.searchsorted(xs, x) - 1, 0, len(line) - 2))
        t = 0.0 if xs[i + 1] == xs[i] else np.clip((x - xs[i]) / (xs[i + 1] - xs[i]), 0, 1)
        out.append(line[i] + (line[i + 1] - line[i]) * t)
    return np.array(out)


# --- Tops ----------------------------------------------------------------------------------------

SHAPE = {
    # height of the armpit row and the row through the armhole; the shoulder point (out from the
    # joint, up from it); how far the neckline stands off the neck; the sleeve's ease.
    "m": dict(armpit=1.335, mid=1.425, shoulder=(0.012, 0.03), neck_gap=0.016),
    "f": dict(armpit=1.325, mid=1.42, shoulder=(-0.018, 0.022), neck_gap=0.014),
}


def shoulder_half(fit, ease):
    """The shoulder row (S): across the upper chest, over the shoulder point, across the upper
    back. From the body's own shoulder ring, the point over the joint designed."""
    p = fit.p
    st = p["torso"][-2]
    y0, z0, c1, c2, c3, c4, z5 = st[:7]
    dy = st[7]
    sh = SHAPE[p["sex"]]
    ox, oy = sh["shoulder"]
    pts = [(0.0, y0 + dy[0], z0 - ease), (c1[0], y0 + dy[1], c1[1] - ease),
           (c2[0], y0 + dy[2] + ease * 0.5, c2[1] - ease * 0.8),
           (B.SHOULDER[0] + ox, SHOULDER_Y + oy, 0.0),
           (c4[0], y0 + dy[4] + ease * 0.5, c4[1] + ease * 0.8),
           (c4[0] * 0.45, y0 + (dy[4] + dy[5]) / 2, (c4[1] + z5) / 2 + ease + 0.008),
           (0.0, y0 + dy[5], z5 + ease)]
    return np.array(pts)


def neck_half(fit, gap, lift=0.0, flare=0.0, front_y=None):
    """A ring round the neck (right half, 7 points by angle from the front): low in front, high
    at the back, `gap` off the neck, raised by `lift`."""
    rx, rz = fit.neck_r
    fy = (fit.p["chin_y"] - 0.052) if front_y is None else front_y
    by = fy + 0.055
    out = []
    for k in range(7):
        a = k * np.pi / 6
        y = fy + (by - fy) * (1 - np.cos(a)) / 2 + lift
        g = gap + flare
        out.append((np.sin(a) * (rx + g) * 1.08, y, fit.neck_z(y) - np.cos(a) * (rz + g)))
    return np.array(out)


def top(fit, sleeves="long", neck="crew", hem=0.95, tucked=False, ease=0.016, sleeve_ease=0.012,
        under_ease=0.012, opening=None, tags=None, hem_flare=0.0):
    """A shirt, a jacket or a coat: torso, collar, sleeves (or armholes), as one shell.

    sleeves: "long", "short" or "none". neck: "crew", "collar" or "high". hem: height of the
    bottom edge; `tucked`: it goes inside the trousers (else it hangs over them and turns in onto
    them, `under_ease` being theirs). opening: an open front, dict(x=half width or fn(y), depth),
    whose inside is tagged "inner" (the shirt under a jacket). tags: names for "main", "trim",
    "inner", "sleeve"."""
    p = fit.p
    T = dict(main="shirt", trim="shirt", inner="shirt2", sleeve=None, cuff=None)
    T.update(tags or {})
    T["sleeve"] = T["sleeve"] or T["main"]
    T["cuff"] = T["cuff"] or T["sleeve"]
    sh = SHAPE[p["sex"]]
    cols = list(TORSO_COLS)
    if opening:
        ox = opening["x"]
        fx = ox if callable(ox) else (lambda y, v=ox: v)
        # the edge of the opening: an inner and an outer column, a few millimetres apart
        cols = [cols[0], ("e_in", "x", fx), ("e_out", "x", lambda y, f=fx: f(y) + 0.005)] + cols[1:]
    names = [c[0] for c in cols]
    S = Shell()

    def resolve(y):
        """Torso columns at height y, x columns resolved."""
        cs = []
        for name, kind, f in cols:
            if kind == "x":
                cs.append((name, "fx", f(y)))
            else:
                cs.append((name, kind, f))
        return cs

    def fractions(y, w, most):
        """The columns at height y on a row `w` wide; the opening's two edge columns are kept
        apart and short of the side (`most`) on a narrow row, like round the neck."""
        cs = []
        for name, kind, f in resolve(y):
            if kind == "fx":
                f = min(f / w, most)
                if name == "e_out":
                    f = min(max(f, cs[-1][2] + 0.04), most + 0.04)
                cs.append((name, "f", f))
            else:
                cs.append((name, kind, f))
        return cs

    def outline_half(y, e):
        H = grow(fit.trunk_outline(y), e)
        return half_from_outline(H, y, fractions(y, H[:, 0].max(), 0.4))

    def design_half(pts, y):
        return half_from_points(pts, fractions(y, pts[3][0], 0.3))

    def recess(half, depth):
        """Push the open front's inside (cf, e_in) in by depth."""
        if not opening:
            return half
        half = np.array(half, dtype=np.float64)
        for name in ("cf", "e_in"):
            half[names.index(name), 2] += depth
        return half

    # Rows from the hem up to the armpit, then the armhole rows, the shoulder and the neck.
    y_a, y_m = sh["armpit"], sh["mid"]
    n_low = max(3, int(round((y_a - hem) / 0.085)))
    ys = [hem] + list(np.linspace(hem + 0.03, y_a, n_low))
    depth = opening.get("depth", 0.014) if opening else 0.0
    rows = []
    for y in ys:
        e = ease + hem_flare * float(np.clip((hem + 0.12 - y) / 0.12, 0, 1))
        rows.append(recess(outline_half(y, e), depth))
    row_m = recess(outline_half(y_m, ease), depth)
    s_pts = shoulder_half(fit, ease)
    row_s = recess(design_half(s_pts, s_pts[3][1]), depth * 0.5)
    n_pts = neck_half(fit, sh["neck_gap"])
    row_n = recess(design_half(n_pts, n_pts[0][1]), depth * 0.3)

    def tag_of(lo_name, hi_name, region):
        if opening and {lo_name, hi_name} == {"cf", "e_in"}:
            return T["inner"]
        return region

    def ring_tags(row_names, region):
        n = len(row_names)
        return lambda j: tag_of(row_names[j], row_names[(j + 1) % n], region)

    full_names = names + list(reversed(names[1:-1]))
    idx_rows = []
    for half in rows:
        pts = full_ring(half)
        idx_rows.append(S.ring(pts, trunk(pts, p)))
    for r in range(len(idx_rows) - 1):
        S.band(idx_rows[r], idx_rows[r + 1], ring_tags(full_names, T["main"]))
    row_a = idx_rows[-1]

    # Row M has no side points: the armholes are there.
    m_full = full_ring(row_m)
    m_idx = S.ring(m_full, trunk(m_full, p))
    s_full = full_ring(row_s)
    s_idx = S.ring(s_full, trunk(s_full, p))
    n_full = full_ring(row_n)
    n_idx = S.ring(n_full, trunk(n_full, p))
    i_s = names.index("s")
    nn = len(full_names)
    side_r, side_l = i_s, nn - i_s
    hole = {side_r - 1, side_r, side_l - 1, side_l}   # faces f2-s, s-b2 on each side
    S.band(row_a, m_idx, ring_tags(full_names, T["main"]), skip=hole)
    S.band(m_idx, s_idx, ring_tags(full_names, T["main"]), skip=hole)
    S.band(s_idx, n_idx, ring_tags(full_names, T["main"]))

    # Collar: up from the neckline, then turned in under the neck and closed (the wound a lost
    # head leaves).
    lift, flare, band_tag = {"crew": (0.012, -0.006, T["main"]), "collar": (0.026, 0.008, T["trim"]),
                             "high": (0.045, 0.012, T["trim"])}[neck]
    c_pts = neck_half(fit, sh["neck_gap"] + flare, lift=lift)
    c_full = full_ring(design_half(c_pts, c_pts[0][1]))
    c_idx = S.ring(c_full, trunk(c_full, p))
    S.band(n_idx, c_idx, band_tag)
    t_pts = neck_half(fit, -0.016, lift=lift - 0.004)
    t_full = full_ring(design_half(t_pts, t_pts[0][1]))
    t_idx = S.ring(t_full, trunk(t_full, p))
    S.band(c_idx, t_idx, band_tag)
    S.cap(t_idx, "wound", trunk([np.mean(t_full, 0)], p)[0])

    # Hem: turned in onto the trousers, or tucked into them; closed either way.
    bottom = idx_rows[0]
    if tucked:
        S.cap(bottom, T["main"], trunk([np.mean([S.point(i) for i in bottom], 0)], p)[0])
    else:
        under = outline_half(hem, under_ease - 0.004)
        inner = turned_in(full_ring(rows[0]), full_ring(under))
        in_idx = S.ring(inner, trunk(inner, p))
        S.band(in_idx, bottom, T["main"])
        S.cap(in_idx, T["main"], trunk([np.mean(inner, 0)], p)[0])

    # Armholes and sleeves (built on the right, mirrored for the left).
    loop_r = [s_idx[side_r], s_idx[side_r - 1], m_idx[side_r - 1], row_a[side_r - 1], row_a[side_r],
              row_a[side_r + 1], m_idx[side_r + 1], s_idx[side_r + 1]]
    loop_l = [s_idx[side_l], s_idx[side_l + 1], m_idx[side_l + 1], row_a[side_l + 1], row_a[side_l],
              row_a[side_l - 1], m_idx[side_l - 1], s_idx[side_l - 1]]
    m = S.m
    if sleeves == "none":
        for loop in (loop_r, loop_l):
            S.cap(loop, T["main"], trunk([np.mean([S.point(i) for i in loop], 0)], p)[0])
        return m
    # The armhole's own points follow the arm a little (more under the arm than over it).
    for loop, helper in ((loop_r, "shoulder_r_mid"), (loop_l, "shoulder_l_mid")):
        for kk, i in enumerate(loop):
            f = TUNE["loop_follow"][kk]
            w, seg = m.vdata[i]
            m.vdata[i] = (blend((w, 1 - f), ({helper: 1.0}, f)), seg)
    right = sleeve(fit, [S.point(i) for i in loop_r], sleeves, sleeve_ease, T)
    # The sleeve's first ring is the armhole itself: join them.
    base = len(m.verts)
    m.merge(right.m)
    _weld_loop(m, loop_r, base)
    left = right.m.mirrored()
    base = len(m.verts)
    m.merge(left)
    _weld_loop(m, loop_l, base)
    return m


def _weld_loop(m, loop, base):
    """The sleeve shell was built starting with a copy of the armhole's 8 points (its first 8
    vertices): point its faces at the armhole's own vertices instead."""
    remap = {base + k: loop[k] for k in range(8)}
    m.faces = [tuple(remap.get(i, i) for i in f) for f in m.faces]


# How the shoulder bends (tuned against the game's poses: python tools/models/outfits.py --folds):
# how far the armhole's own points follow the arm (by loop index: 0 top, 2 front, 4 armpit,
# 6 back), where the helper's ring sits between the armhole and the first ring of the arm, and
# how much that first ring still holds back.
TUNE = dict(loop_follow=(0.05, 0.2, 0.35, 0.5, 0.6, 0.5, 0.35, 0.2), mid_at=0.6, r1_hold=0.6,
            deltoid=(0.012, 0.02, 0.012), t1_hold=0.5)


def blend(*parts):
    """Weights mixed: blend(({"spine": 1}, 0.6), ({"shoulder_r_mid": 1}, 0.4))."""
    out = {}
    for w, k in parts:
        for b, v in w.items():
            out[b] = out.get(b, 0.0) + v * k
    return {b: v for b, v in out.items() if v > 1e-4}


def sleeve(fit, loop_pts, kind, ease, T):
    """The right sleeve from its armhole (8 points, top first, going front, under, back) down
    the arm: a ring on the shoulder's helper (rounded over the deltoid), the arm's rings, then
    either a short hem or the elbow (a ring on its helper) and the forearm down to a cuff. The
    sleeve is cut from the shirt at the arm's first ring, the forearm from the upper arm just
    below the elbow."""
    p = fit.p
    S = Shell()
    loop = np.asarray(loop_pts, dtype=np.float64)
    S.ring(loop, on("spine", "torso"))  # placeholder for the armhole (welded by the caller)
    ax = fit.arm_x
    k = p["arm"]

    def arm_ring(y, e):
        H = fit.arm_outline(y)
        if H is None:
            return round_ring((ax, 0.0), y, 0.06 * k + e, 0.06 * k + e)
        return limb_ring(H, (ax, 0.0), y, e)

    y1 = loop[4][1] - 0.035          # first ring, under the armpit
    r1 = arm_ring(y1, ease)
    mid = loop + (r1 - loop) * TUNE["mid_at"]
    out = np.array([1.0, 0.0, 0.0])
    for kk, push in zip((7, 0, 1), TUNE["deltoid"]):
        mid[kk] += out * push
    m_idx = S.ring(mid, on("shoulder_r_mid", "torso"))
    S.band(list(range(8)), m_idx, T["sleeve"])
    hold = TUNE["r1_hold"]
    r1_w = blend(({"shoulder_r_mid": 1.0}, hold), ({"shoulder_r": 1.0}, 1 - hold))
    r1_a, r1_b = S.cut(r1, "torso", "upper_arm_r", "shoulder_r")
    for i in r1_a + r1_b + [len(S.m.verts) - 2, len(S.m.verts) - 1]:
        S.m.vdata[i] = (r1_w, S.m.vdata[i][1])
    S.band(m_idx, r1_a, T["sleeve"])
    r1_idx = r1_b
    if kind == "short":
        y_h = y1 - 0.06
        hem = arm_ring(y_h, ease + 0.004)
        h_idx = S.ring(hem, on("shoulder_r", "upper_arm_r"))
        S.band(r1_idx, h_idx, T["sleeve"])
        inner = turned_in(hem, arm_ring(y_h, -0.006))
        i_idx = S.ring(inner, on("shoulder_r", "upper_arm_r"))
        S.band(h_idx, i_idx, T["cuff"])
        S.cap(i_idx, T["sleeve"], on("shoulder_r", "upper_arm_r"))
        return S
    prev = r1_idx
    for y in (ELBOW_Y + 0.06,):
        idx = S.ring(arm_ring(y, ease), on("shoulder_r", "upper_arm_r"))
        S.band(prev, idx, T["sleeve"])
        prev = idx
    e_idx = S.ring(arm_ring(ELBOW_Y, ease + 0.004), on("elbow_r_mid", "upper_arm_r"))
    S.band(prev, e_idx, T["sleeve"])
    e_a, e_b = S.cut(arm_ring(ELBOW_Y - 0.06, ease), "upper_arm_r", "forearm_r", "elbow_r")
    S.band(e_idx, e_a, T["sleeve"])
    prev = e_b
    for y in (1.03, 0.965):
        idx = S.ring(arm_ring(y, ease), on("elbow_r", "forearm_r"))
        S.band(prev, idx, T["sleeve"])
        prev = idx
    y_c = 0.94
    cuff = arm_ring(y_c, ease + 0.003)
    c_idx = S.ring(cuff, on("elbow_r", "forearm_r"))
    S.band(prev, c_idx, T["cuff"])
    inner = turned_in(cuff, arm_ring(y_c, -0.007))
    i_idx = S.ring(inner, on("elbow_r", "forearm_r"))
    S.band(c_idx, i_idx, T["cuff"])
    S.cap(i_idx, T["sleeve"], on("elbow_r", "forearm_r"))
    return S


# --- Trousers ------------------------------------------------------------------------------------

def pants(fit, length="long", waist=1.0, ease=0.012, top_ease=None, hem=0.11, tags=None, shoe_ease=None):
    """Trousers (or shorts): waist, seat, the crotch where the legs part, each leg down to a hem
    turned in onto the shoe (or the shin, for shorts). `top_ease` (default `ease`): the waistband's,
    bigger when a shirt is tucked under it. tags: "main", "belt" (the waistband)."""
    p = fit.p
    T = dict(main="pants", belt="pants")
    T.update(tags or {})
    S = Shell()
    top_ease = ease if top_ease is None else top_ease
    y_c = 0.8                                     # the crotch row: legs part below it
    ys = [waist, waist - 0.035, HIP_Y + 0.0, 0.86, y_c]
    rows = []
    for i, y in enumerate(ys):
        e = top_ease if i < 2 else ease
        H = grow(fit.trunk_outline(y), e)
        rows.append(full_ring(half_from_outline(H, y)))
    idx = []
    for pts in rows:
        idx.append(S.ring(pts, trunk(pts, p)))
    for r in range(len(idx) - 1):
        S.band(idx[r + 1], idx[r], T["belt"] if r == 0 else T["main"])
    S.cap(idx[0], T["main"], trunk([np.mean(rows[0], 0)], p)[0])
    crotch_row = idx[-1]
    cr = rows[-1]
    # The crotch point, between the legs, a little lower than the row.
    k_pt = np.array([0.0, y_c - 0.04, (cr[0][2] + cr[6][2]) / 2])
    k_idx = S.ring([k_pt], trunk([k_pt], p))[0]
    # Right leg's top loop, in limb order: outer, front-outer, front, front-inner, inner (the
    # crotch), back-inner, back, back-outer.
    loop = [crotch_row[3], crotch_row[2], crotch_row[1], crotch_row[0], k_idx, crotch_row[6],
            crotch_row[5], crotch_row[4]]
    # Left: mirrored columns, same order seen from the left leg's outside.
    n = len(crotch_row)
    loop_l = [crotch_row[n - 3], crotch_row[n - 2], crotch_row[n - 1], crotch_row[0], k_idx,
              crotch_row[6], crotch_row[7], crotch_row[8]]
    m = S.m
    right = leg(fit, [S.point(i) for i in loop], length, ease, hem, T, shoe_ease)
    base = len(m.verts)
    m.merge(right.m)
    _weld_loop(m, loop, base)
    left = right.m.mirrored()
    base = len(m.verts)
    m.merge(left)
    _weld_loop(m, loop_l, base)
    return m


def leg(fit, loop_pts, length, ease, hem, T, shoe_ease):
    """The right trouser leg from its top loop: a ring on the hip's helper, the thigh (cut from
    the trousers at its first ring), a ring on the knee's helper, the shin (cut from the thigh just
    below the knee), the hem turned in onto the shoe; or a short leg ending in a hem on the thigh."""
    S = Shell()
    loop = np.asarray(loop_pts, dtype=np.float64)
    S.ring(loop, on("hips", "torso"))  # placeholder for the loop (welded by the caller)
    cx = fit.leg_x

    def leg_ring(y, e):
        return limb_ring(fit.leg_outline(y), (cx, 0.0), y, e)

    h_idx = S.ring(leg_ring(0.74, ease), on("hip_r_mid", "torso"))
    S.band(list(range(8)), h_idx, T["main"])
    t_a, t_b = S.cut(leg_ring(0.68, ease), "torso", "thigh_r", "hip_r")
    hold = TUNE["t1_hold"]
    t_w = blend(({"hip_r_mid": 1.0}, hold), ({"hip_r": 1.0}, 1 - hold))
    for i in t_a + t_b + [len(S.m.verts) - 2, len(S.m.verts) - 1]:
        S.m.vdata[i] = (t_w, S.m.vdata[i][1])
    S.band(h_idx, t_a, T["main"])
    prev = t_b
    if length == "shorts":
        y_e = 0.6
        for y in (0.66,):
            idx = S.ring(leg_ring(y, ease), on("hip_r", "thigh_r"))
            S.band(prev, idx, T["main"])
            prev = idx
        edge = leg_ring(y_e, ease + 0.004)
        e_idx = S.ring(edge, on("hip_r", "thigh_r"))
        S.band(prev, e_idx, T["main"])
        inner = turned_in(edge, leg_ring(y_e, -0.006))
        i_idx = S.ring(inner, on("hip_r", "thigh_r"))
        S.band(e_idx, i_idx, T["main"])
        S.cap(i_idx, T["main"], on("hip_r", "thigh_r"))
        return S
    for y in (0.6, KNEE_Y + 0.065):
        idx = S.ring(leg_ring(y, ease), on("hip_r", "thigh_r"))
        S.band(prev, idx, T["main"])
        prev = idx
    k_idx = S.ring(leg_ring(KNEE_Y, ease + 0.004), on("knee_r_mid", "thigh_r"))
    S.band(prev, k_idx, T["main"])
    k_a, k_b = S.cut(leg_ring(KNEE_Y - 0.065, ease), "thigh_r", "shin_r", "knee_r")
    S.band(k_idx, k_a, T["main"])
    prev = k_b
    for y in (0.33, 0.22):
        idx = S.ring(leg_ring(y, ease), on("knee_r", "shin_r"))
        S.band(prev, idx, T["main"])
        prev = idx
    edge = leg_ring(hem, ease + 0.006)
    e_idx = S.ring(edge, on("knee_r", "shin_r"))
    S.band(prev, e_idx, T["main"])
    inner_r = (shoe_ease if shoe_ease is not None else ease) - 0.008
    inner = turned_in(edge, leg_ring(hem, inner_r))
    i_idx = S.ring(inner, on("knee_r", "shin_r"))
    S.band(e_idx, i_idx, T["main"])
    S.cap(i_idx, T["main"], on("knee_r", "shin_r"))
    return S


# --- Shoes -------------------------------------------------------------------------------------

def shoe(fit, kind="shoe", top=None, ease=0.012, pants_ease=None, tags=None):
    """A right shoe (or boot): a foot block heel to toe with a sole band, and a shaft round the
    ankle up to `top`, both closed. A boot's rim turns in onto the trousers (`pants_ease`)."""
    p = fit.p
    T = dict(main="shoe", sole="sole")
    T.update(tags or {})
    S = Shell()
    data = on("knee_r", "shin_r")
    x = fit.leg_x
    k = p["foot"]
    sole_h = {"shoe": 0.018, "sneaker": 0.028, "boot": 0.024}[kind]
    # sections heel to toe: z, half width, height
    secs = [(0.095, 0.042, 0.06), (0.07, 0.054, 0.1), (-0.03, 0.062, 0.095), (-0.12, 0.066, 0.065),
            (-0.18 * k - 0.01, 0.06, 0.05), (-0.205 * k - 0.012, 0.048, 0.034)]
    rings = []
    for z, w, h in secs:
        w = w * (0.85 + 0.15 * k)
        rings.append([(x - w, 0.0, z), (x + w, 0.0, z), (x + w, sole_h, z), (x + w * 0.96, h * 0.72, z),
                      (x + w * 0.55, h, z), (x - w * 0.55, h, z), (x - w * 0.96, h * 0.72, z), (x - w, sole_h, z)])
    idx = [S.ring(r, data) for r in rings]
    sole_faces = {0, 1, 7}

    def ftag(j):
        return T["sole"] if j in sole_faces else T["main"]

    for r in range(len(idx) - 1):
        S.band(idx[r], idx[r + 1], ftag)
    S.cap(idx[0], T["main"], data)
    S.cap(idx[-1], T["main"], data)
    # The shaft: round the ankle from inside the foot block up to its rim.
    top = top if top is not None else {"shoe": 0.115, "sneaker": 0.12, "boot": 0.27}[kind]

    def ankle(y, e):
        return limb_ring(fit.leg_outline(y), (x, 0.0), y, e)

    lo = ankle(0.05, ease)
    ys = [0.05, top] if kind != "boot" else [0.05, 0.12, top]
    prev = S.ring(lo, data)
    S.cap(prev, T["main"], data)
    for y in ys[1:]:
        e = ease + (0.012 if kind == "boot" else 0.0)
        idx_y = S.ring(ankle(y, e), data)
        S.band(prev, idx_y, T["main"])
        prev = idx_y
    if kind == "boot" and pants_ease is not None:
        rim = turned_in([S.point(i) for i in prev], ankle(top, pants_ease - 0.004))
        r_idx = S.ring(rim, data)
        S.band(prev, r_idx, T["main"])
        prev = r_idx
    S.cap(prev, T["main"], data)
    return S.m


# --- Hats --------------------------------------------------------------------------------------

def _head_rings(fit, y, ease, n=12, centre=(0.0, 0.012)):
    """n points round the head and hair at height y, `ease` off them (k = 0 at the front)."""
    H = fit.outline([(B.HEAD, 0), (B.HAIR, 0)], y)
    c = np.asarray(centre, dtype=np.float64)
    G = grow(H, ease)
    out = []
    for k in range(n):
        a = 2 * np.pi * k / n
        d = np.array([np.sin(a), -np.cos(a)])
        q = exit_point(G, c, d)
        out.append([q[0], y, q[1]])
    return np.array(out)


def _scaled(ring, s, centre=(0.0, 0.012), dy=0.0, back=0.0):
    """A ring scaled about the head's axis, lifted by dy, its back half pushed out by `back`."""
    r = np.array(ring, dtype=np.float64)
    r[:, 0] = r[:, 0] * s
    r[:, 2] = centre[1] + (r[:, 2] - centre[1]) * s + np.maximum(r[:, 2] - centre[1], 0) * back
    r[:, 1] += dy
    return r


def hat(fit, kind, tags=None):
    """Headgear riding the neck (it leaves with the head): "cap" (a peaked police cap), "hard"
    (a hard hat with a brim), "helmet" (round, low over the ears), "fire" (a long brim at the
    back), "nurse" (a little folded cap on the crown)."""
    T = dict(main="hat", trim="hat2")
    T.update(tags or {})
    S = Shell()
    data = on("neck", "head")
    p = fit.p
    s = p["head_h"] / 0.32
    top = p["chin_y"] + p["head_h"]          # the crown, under the hair
    brow = p["chin_y"] + 0.255 * s

    def loft(rings, tag_of=None):
        idx = [S.ring(r, data) for r in rings]
        for i in range(len(idx) - 1):
            S.band(idx[i], idx[i + 1], tag_of(i) if tag_of else T["main"])
        S.cap(idx[0], T["main"], data)
        S.cap(idx[-1], T["main"], data)

    if kind == "nurse":
        y0 = top - 0.03
        base = _head_rings(fit, y0, 0.004)
        loft([_scaled(base, 0.8, dy=-0.004), _scaled(base, 0.82, dy=0.035), _scaled(base, 0.7, dy=0.05)])
        return S.m
    band_y = brow + (0.0 if kind == "cap" else -0.012)
    band = _head_rings(fit, band_y, 0.008)
    if kind == "cap":
        crown = _head_rings(fit, band_y + 0.04, 0.012)
        loft([band, _scaled(crown, 1.0), _scaled(crown, 1.2, dy=0.045, back=0.06),
              _scaled(crown, 1.14, dy=0.06, back=0.06)], lambda i: T["trim"] if i == 0 else T["main"])
        # the peak: a thin plate out over the eyes, from the band's front
        f = band[[10, 11, 0, 1, 2]]
        lo = f + np.array([0.0, -0.003, -0.004])   # just off the band, a piece of its own
        tip = f.copy()
        tip[:, 2] -= 0.075
        tip[:, 1] -= 0.03
        tip[:, 0] *= 0.9
        a = S.ring(np.vstack([lo, tip[::-1]]), data)
        b = S.ring(np.vstack([lo, tip[::-1]]) + np.array([0, -0.008, 0]), data)
        S.band(a, b, T["trim"])
        S.cap(a, T["trim"], data)
        S.cap(b, T["trim"], data)
        return S.m
    # domes: brim, then the shell rising over the head
    low = band_y - (0.03 if kind == "helmet" else 0.0)
    shell = _head_rings(fit, low, 0.016)
    lift = top - low + 0.055
    rings = []
    if kind in ("hard", "fire"):
        out_s = 1.25 if kind == "hard" else 1.18
        brim = _scaled(shell, out_s, back=0.6 if kind == "fire" else 0.0)
        rings += [_scaled(brim, 1.0, dy=-0.006), _scaled(brim, 1.0, dy=0.004)]
    # a round dome: straight up a little, then curving in to a small flat top
    rings += [_scaled(shell, 1.0, dy=0.006), _scaled(shell, 1.03, dy=lift * 0.4),
              _scaled(shell, 0.95, dy=lift * 0.7), _scaled(shell, 0.72, dy=lift * 0.9),
              _scaled(shell, 0.32, dy=lift)]
    loft(rings, lambda i: T["trim"] if (kind in ("hard", "fire") and i < 2) else T["main"])
    return S.m


# --- Putting a figure together -----------------------------------------------------------------

def body_under(p, cover):
    """The body pieces left under the clothes: {(piece, side): Mesh}. `cover` says what the
    clothes hide: "torso" (chest and pelvis), "upper_arm" / "forearm" / "thigh" / "shin": None
    (bare), "all", or the height above which the part is covered; "feet": shoes on."""
    import skeleton as Sk
    out = {}
    head = B.head(p)
    head.merge(Sk.vertebra((0.0, 1.44, 0.022), 0.019, 0.011, 0.015))
    out[(B.HEAD, 0)] = head
    out[(B.HAIR, 0)] = B.hair(p)
    if not cover.get("torso"):
        chest, hips = B.torso(p)
        out[(B.TORSO, 0)] = chest
        out[(B.PELVIS, 0)] = hips

    def kept(name):
        c = cover.get(name)
        if c is None:
            return None            # bare: the whole piece
        if c == "all":
            return "drop"
        return (-1.0, c)           # what hangs below c

    def put(piece, m):
        out[(piece, 1)] = m
        out[(piece, -1)] = m.mirrored()

    k = kept("upper_arm")
    if k != "drop":
        put(B.UPPER_ARM, B.upper_arm(p, k))
    k = kept("forearm")
    put(B.FOREARM, B.hand(p, B.ELBOW[0] - p["arm_in"]) if k == "drop" else B.forearm(p, k))
    k = kept("thigh")
    if k != "drop":
        m = B.thigh(p, k)
        if k is None:
            m.merge(Sk.femur(p, stub_only=True))
        put(B.THIGH, m)
    k = kept("shin")
    feet = cover.get("feet")
    if k != "drop":
        lo = cover.get("shoe_top", 0.1) - 0.03 if feet else -1.0
        hi = 9.0 if k is None else k[1]
        if hi > lo + 0.05:
            put(B.SHIN, B.shin(p, None if (k is None and not feet) else (lo, hi), with_foot=not feet))
    return out
