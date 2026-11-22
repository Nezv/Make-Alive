"""The detail kit's shapes (S141): every form an element is made of, low-poly and flat-shaded, in
numpy, as `poly.Mesh`es. Family files (tools/models/props/*.py) build with these; the kit's board
(`tools/models/props/kit.py`, `--prop-rack=kit`) shows each one.

    chamfer_box / bevel_box     a box with some or all edges cut once (chamfer) or twice (bevel)
    clip / cut                  a closed convex shape cut by a plane: one side kept and capped, or
                                both sides (a cut line for collapse, its break face rough)
    lathe, prism, along         bodies of revolution, nuts and studs, turned onto any axis
    sweep, fillet, pipe,        a profile swept along a path with mitred corners; rounded bends;
    cable, handrail             a sagging cable; a rail on posts with its ends turned down
    extrude                     any outline (concave too) pushed out, its front edge chamfered
    panel                       a door or shutter panel: inset (recessed) or raised (fielded)
    array_linear / _radial      copies along a line or round an axis
    opening_frame               a window or door surround: a moulding swept round the opening
                                (square or segmental arch), its sill with a drip under it
    vent                        a plate of slots or of slanted louvres in a frame, dark behind
    subdivide, dent             cut quads into a grid; push a round dent into it

Game coordinates: metres, Y up, the front faces -Z. Faces are wound outward where it matters;
Blender recalculates normals per connected piece anyway (pipeline.mesh_from_poly).
"""
import numpy as np

from poly import Mesh

X, Y, Z = np.eye(3)


def _v(p):
    return np.asarray(p, dtype=np.float64)


def _unit(v):
    v = _v(v)
    n = np.linalg.norm(v)
    return v / n if n > 1e-12 else v


# --- Welding and convex clipping -------------------------------------------------------------------

def weld(mesh, eps=1e-6):
    """Points at the same place made one (so a piece is connected and its normals agree)."""
    out = Mesh()
    index = {}
    remap = []
    for v in mesh.verts:
        key = tuple(np.round(v / eps).astype(np.int64))
        if key not in index:
            index[key] = out.add([v])
        remap.append(index[key])
    for f, t, u in zip(mesh.faces, mesh.tags, mesh.units_list()):
        g = []
        for i in f:
            j = remap[i]
            if not g or g[-1] != j:
                g.append(j)
        while len(g) > 1 and g[0] == g[-1]:
            g.pop()
        if len(set(g)) >= 3:
            out.face(g, t, u)
    return out


def _plane_frame(n):
    n = _unit(n)
    ref = Y if abs(n[1]) < 0.9 else X
    u = _unit(np.cross(ref, n))
    v = np.cross(n, u)
    return u, v


def clip(mesh, point, normal, cap_tag=None, rough=0.0, seed=0, cap_unit=0):
    """The part of a closed convex `mesh` behind the plane through `point` (where
    (p - point) . normal <= 0), the hole closed by one face tagged `cap_tag` facing along
    `normal` (no cap when None). `rough` makes the cap a fan to a centre pushed in or out by up to
    that much (a broken face), seeded so both halves of a cut get the same break."""
    point, n = _v(point), _unit(normal)
    m = Mesh()
    cut_pts = []
    for f, t, u in zip(mesh.faces, mesh.tags, mesh.units_list()):
        poly = [mesh.verts[i] for i in f]
        d = [float((p - point) @ n) for p in poly]
        out = []
        k = len(poly)
        for i in range(k):
            a, b = poly[i], poly[(i + 1) % k]
            da, db = d[i], d[(i + 1) % k]
            if da <= 1e-9:
                out.append(a)
            if abs(da) <= 1e-9:
                cut_pts.append(a)
            if (da < -1e-9 < 1e-9 < db) or (db < -1e-9 < 1e-9 < da):
                x = a + (b - a) * (da / (da - db))
                out.append(x)
                cut_pts.append(x)
        if len(out) >= 3:
            base = m.add(out)
            m.face(range(base, base + len(out)), t, u)
    if cap_tag is not None and len(cut_pts) >= 3:
        C = np.unique(np.round(np.array(cut_pts), 7), axis=0)
        if len(C) >= 3:
            c = C.mean(0)
            pu, pv = _plane_frame(n)
            ang = np.arctan2((C - c) @ pv, (C - c) @ pu)
            ring = C[np.argsort(ang)]  # counter-clockwise seen from +n: the cap faces +n
            # ...unless the mesh is wound the other way round: then the cap must agree with it
            key = lambda p: tuple(np.round(p, 6))  # noqa: E731
            edges = set()
            for f in m.faces:
                for i in range(len(f)):
                    edges.add((key(m.verts[f[i]]), key(m.verts[f[(i + 1) % len(f)]])))
            for i in range(len(ring)):
                e = (key(ring[i]), key(ring[(i + 1) % len(ring)]))
                if e in edges:
                    ring = ring[::-1]
                    break
                if e[::-1] in edges:
                    break
            if rough != 0:  # the same draw on both halves; a negative `rough` mirrors it for the other side
                rng = np.random.default_rng(seed)
                centre = c + n * np.sign(rough) * rng.uniform(-abs(rough), abs(rough))
                b = m.add([centre])
                r0 = m.add(ring)
                for i in range(len(ring)):
                    m.face([b, r0 + i, r0 + (i + 1) % len(ring)], cap_tag, cap_unit)
            else:
                base = m.add(ring)
                m.face(range(base, base + len(ring)), cap_tag, cap_unit)
    return weld(m)


def cut(mesh, point, normal, tag="break", rough=0.0, seed=0):
    """A cut line for collapse: (the part behind the plane, the part in front), each closed by a
    `tag` face; with `rough` the two breaks are the same jagged surface, so they fit together."""
    n = _unit(normal)
    a = clip(mesh, point, n, tag, rough, seed)
    b = clip(mesh, point, -n, tag, -rough, seed)  # the same push, seen from the other side
    return a, b


# --- Boxes -----------------------------------------------------------------------------------------

def box(center, half, tag="paint", basis=None):
    m = Mesh()
    m.box(center, half, tag, basis)
    return weld(m)


def _edge_ok(edges, k, sa, sb, i, j):
    """Is the edge along axis k, on side sa of axis i and side sb of axis j, one to cut?"""
    if edges == "all":
        return True
    if edges == "vertical":
        return k == 1
    on_top = (i == 1 and sa > 0) or (j == 1 and sb > 0)
    on_bottom = (i == 1 and sa < 0) or (j == 1 and sb < 0)
    if edges == "top":
        return on_top
    if edges == "top_vertical":
        return on_top or k == 1
    if edges == "front":  # the edges round the -Z face
        return (i == 2 and sa < 0) or (j == 2 and sb < 0)
    if edges == "not_bottom":
        return not on_bottom
    raise ValueError(edges)


def chamfer_box(center, half, c, tag="paint", basis=None, edges="all", segments=1, cap_tag=None):
    """A box whose `edges` ("all", "vertical", "top", "top_vertical", "front", "not_bottom") are
    cut: once at 45 degrees (`segments` 1, a chamfer of `c` along each face) or more times round a
    radius `c` (2: a bevel). The cut faces take `cap_tag` (default the box's tag)."""
    half = _v(half)
    m = box((0, 0, 0), half, tag)
    cap = cap_tag or tag
    for k in range(3):
        i, j = [a for a in range(3) if a != k]
        for sa in (-1, 1):
            for sb in (-1, 1):
                if not _edge_ok(edges, k, sa, sb, i, j):
                    continue
                e = np.eye(3)
                centre = e[i] * sa * (half[i] - c) + e[j] * sb * (half[j] - c)
                for s in range(segments):
                    th = (s + 0.5) * (np.pi / 2) / segments
                    n = e[i] * sa * np.cos(th) + e[j] * sb * np.sin(th)
                    if segments == 1:  # a chamfer cuts `c` off each face
                        point = e[i] * sa * (half[i] - c) + e[j] * sb * half[j]
                    else:  # a bevel: planes tangent to the rounding
                        point = centre + n * c
                    m = clip(m, point, n, cap)
    B = np.eye(3) if basis is None else _v(basis)
    return m.transformed(B, center)


def bevel_box(center, half, r, tag="paint", basis=None, edges="all", cap_tag=None):
    """A box with its edges rounded in two cuts (a bevel of radius `r`)."""
    return chamfer_box(center, half, r, tag, basis, edges, 2, cap_tag)


# --- Turned and placed shapes (from props.py, S140) -------------------------------------------------

def lathe(profile, sides, flute=None, turn=0.0, tag="paint", caps=(True, True)):
    """A body of revolution round +Y: `profile` = [(y, r) or (y, r, tag of the band above)], from
    the bottom up; a radius of 0 is a tip. `flute(j, y)` may scale point j's radius at height y
    (grooves, ribs)."""
    rings, tags = [], []
    for st in profile:
        y, r = st[0], st[1]
        tags.append(st[2] if len(st) > 2 else tag)
        if r <= 0:
            rings.append(np.array([[0.0, y, 0.0]]))
            continue
        pts = []
        for j in range(sides):
            a = turn + 2 * np.pi * j / sides
            k = flute(j, y) if flute else 1.0
            pts.append([np.cos(a) * r * k, y, np.sin(a) * r * k])
        rings.append(np.array(pts))
    m = Mesh()
    m.loft(rings, tag, caps=caps, cap_tags=(tags[0], tags[-1]), band_tags=lambda r, j: tags[r])
    return m


def along(mesh, axis, origin=(0, 0, 0)):
    """A shape made round +Y turned to lie along `axis` (its y becomes the distance along it)."""
    a = _unit(axis)
    ref = Y if abs(a[1]) < 0.9 else X
    x = _unit(np.cross(ref, a))
    z = np.cross(x, a)
    basis = np.stack([x, a, z], 1)
    if np.linalg.det(basis) < 0:
        basis[:, 0] *= -1
        m = mesh.transformed(basis, origin)
        m.faces = [tuple(reversed(f)) for f in m.faces]
        return m
    return mesh.transformed(basis, origin)


def prism(center, radius, height, sides, turn=0.0, tag="bolt", axis=(0, 1, 0)):
    """A nut, a bolt head, a stud: a short prism of `sides` round `axis`, its base at `center`."""
    m = lathe([(0.0, radius), (height, radius)], sides, turn=turn, tag=tag)
    return along(m, axis, center)


# --- Sweeps ----------------------------------------------------------------------------------------

def fillet(path, radius, n=4):
    """The path with each inner corner rounded by an arc of `n` segments of `radius` (less where
    the legs are short)."""
    P = [_v(p) for p in path]
    if len(P) < 3 or radius <= 0:
        return P
    out = [P[0]]
    for i in range(1, len(P) - 1):
        a, b, c = P[i - 1], P[i], P[i + 1]
        d1, d2 = _unit(a - b), _unit(c - b)
        cosang = np.clip(d1 @ d2, -1, 1)
        ang = np.arccos(cosang)
        if ang > np.pi - 1e-3 or ang < 1e-3:
            out.append(b)
            continue
        t = radius / np.tan(ang / 2)
        t = min(t, 0.45 * np.linalg.norm(a - b), 0.45 * np.linalg.norm(c - b))
        p0, p1 = b + d1 * t, b + d2 * t
        for k in range(n + 1):
            s = k / n  # a quadratic Bezier through the corner: close to an arc, never past it
            out.append((1 - s) ** 2 * p0 + 2 * (1 - s) * s * b + s * s * p1)
    out.append(P[-1])
    return out


def _legs(P, closed):
    """The direction of the leg arriving at each point (the leaving one at an open path's start)."""
    n = len(P)
    out = []
    for i in range(n):
        if i == 0 and not closed:
            out.append(_unit(P[1] - P[0]))
        else:
            out.append(_unit(P[i] - P[i - 1]))
    return out


def sweep(path, profile, tag="paint", closed=False, up=(0, 1, 0), caps=True, scale=None):
    """`profile` (a closed polygon of (side, up) points round the path) swept along `path`. Each
    cross-section is the profile square to the leg arriving there, slid along that leg onto the
    plane halving the corner, so corners are true mitres (a square frame stays square). "side" is
    the leg crossed with `up`; where a leg runs along `up` the side is carried over from the leg
    before. `closed` joins the end to the start. `scale(i)` may scale the profile at point i."""
    P = [_v(p) for p in path]
    prof = np.array(profile, dtype=np.float64)
    n = len(P)
    L = _legs(P, closed)
    upv = _unit(up)
    rings = []
    s_prev = None
    for i in range(n):
        d = L[i]
        s = np.cross(d, upv)
        if np.linalg.norm(s) < 0.1:
            s = s_prev - d * (s_prev @ d) if s_prev is not None else np.cross(d, Z if abs(d[2]) < 0.9 else X)
        s = _unit(s)
        s_prev = s
        u = np.cross(s, d)
        k = scale(i) if scale else 1.0
        ring = np.array([P[i] + s * x * k + u * y * k for x, y in prof])
        nxt = P[(i + 1) % n] if (closed or i < n - 1) else None
        if nxt is not None and (closed or i > 0):
            t_out = _unit(nxt - P[i])
            m = _unit(d + t_out)
            denom = d @ m
            if abs(denom) > 1e-6:
                ring = np.array([q - d * (((q - P[i]) @ m) / denom) for q in ring])
        rings.append(ring)
    m = Mesh()
    if closed:
        rings.append(rings[0].copy())
        m.loft(rings, tag, caps=(False, False))
        return weld(m)
    m.loft(rings, tag, caps=(caps, caps))
    return weld(m)


def circle(r, sides, turn=None):
    turn = np.pi / sides if turn is None else turn
    return [(np.cos(turn + 2 * np.pi * j / sides) * r, np.sin(turn + 2 * np.pi * j / sides) * r) for j in range(sides)]


def pipe(path, r, sides=8, bend=0.0, bend_steps=4, tag="paint", caps=True):
    """A round pipe along `path`, its corners bent round `bend` (0 = mitred elbows)."""
    return sweep(fillet(path, bend, bend_steps) if bend else path, circle(r, sides), tag, caps=caps)


def cable(a, b, sag, r=0.006, n=12, sides=5, tag="cable"):
    """A cable hung from a to b, sagging `sag` at the middle (a parabola close to the chain's)."""
    a, b = _v(a), _v(b)
    pts = [a + (b - a) * t - Y * sag * 4 * t * (1 - t) for t in np.linspace(0, 1, n + 1)]
    return sweep(pts, circle(r, sides), tag)


def handrail(path, r=0.022, post_every=1.0, post_h=0.9, post_r=0.018, sides=8, tag="paint", end_drop=0.12):
    """A round handrail at `post_h` above the floor points of `path` (its first and last
    lengths turned down `end_drop`), on round posts with collars about every `post_every` m."""
    P = [_v(p) for p in path]
    top = [p + Y * post_h for p in P]
    rail = [top[0] - Y * end_drop] + top + [top[-1] - Y * end_drop]
    m = sweep(fillet(rail, 0.06, 3), circle(r, sides), tag)
    # posts along the path, evenly
    lengths = [np.linalg.norm(P[i + 1] - P[i]) for i in range(len(P) - 1)]
    total = sum(lengths)
    count = max(2, int(round(total / post_every)) + 1)
    for k in range(count):
        d = total * k / (count - 1)
        for i, L in enumerate(lengths):
            if d <= L + 1e-9 or i == len(lengths) - 1:
                p = P[i] + (P[i + 1] - P[i]) * (min(d, L) / L)
                break
            d -= L
        m.merge(lathe([(0.0, post_r * 2.2), (0.012, post_r * 2.2), (0.02, post_r * 1.3), (0.03, post_r),
                       (post_h - r - 0.03, post_r), (post_h - r - 0.02, post_r * 1.35), (post_h - r * 0.4, post_r * 1.35)],
                      sides, tag=tag).transformed(np.eye(3), p))
    return m


# --- Extrusions and panels -------------------------------------------------------------------------

def _area2(poly):
    a = 0.0
    for i in range(len(poly)):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % len(poly)]
        a += x1 * y2 - x2 * y1
    return a / 2


def triangulate(poly):
    """Ear-clipping: triangles (index triples, counter-clockwise) of a simple polygon given
    counter-clockwise."""
    pts = [tuple(p) for p in poly]
    idx = list(range(len(pts)))
    tris = []

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    def inside(p, a, b, c):
        return cross(a, b, p) >= -1e-12 and cross(b, c, p) >= -1e-12 and cross(c, a, p) >= -1e-12

    guard = 0
    while len(idx) > 3 and guard < 10000:
        guard += 1
        for k in range(len(idx)):
            i0, i1, i2 = idx[k - 1], idx[k], idx[(k + 1) % len(idx)]
            a, b, c = pts[i0], pts[i1], pts[i2]
            if cross(a, b, c) <= 1e-12:
                continue
            if any(inside(pts[j], a, b, c) for j in idx if j not in (i0, i1, i2)):
                continue
            tris.append((i0, i1, i2))
            idx.pop(k)
            break
        else:
            break
    if len(idx) == 3:
        tris.append(tuple(idx))
    return tris


def _offset(poly, d):
    """The polygon (counter-clockwise) moved inward by d along each corner's bisector."""
    P = np.array(poly, dtype=np.float64)
    n = len(P)
    out = []
    for i in range(n):
        a, b, c = P[i - 1], P[i], P[(i + 1) % n]
        e1, e2 = _unit(b - a), _unit(c - b)
        n1, n2 = np.array([-e1[1], e1[0]]), np.array([-e2[1], e2[0]])  # inward for CCW
        bis = n1 + n2
        bl = np.linalg.norm(bis)
        if bl < 1e-9:
            out.append(b + n1 * d)
            continue
        bis /= bl
        out.append(b + bis * d / max(bis @ n1, 0.25))
    return out


def extrude(outline, depth, chamfer=0.0, tag="paint", cap_tag=None, origin=(0, 0, 0), right=(1, 0, 0),
            up=(0, 1, 0), unit=0):
    """An outline (any simple polygon of (right, up) points) pushed out `depth` towards the
    front (-Z of its frame: right x up points back), its front edge chamfered by `chamfer`. The
    front face is `cap_tag` (default `tag`); the back is left open when it lies on something."""
    poly = [tuple(p) for p in outline]
    if _area2(poly) < 0:
        poly = poly[::-1]
    o, r, u = _v(origin), _unit(right), _unit(up)
    f = -np.cross(r, u)  # the front

    def place(pts2, z):
        return [o + r * x + u * y + f * z for x, y in pts2]

    rings = [place(poly, 0.0)]
    if chamfer > 0:
        rings.append(place(poly, depth - chamfer))
        inner = _offset(poly, chamfer)
        rings.append(place(inner, depth))
        front2 = inner
    else:
        rings.append(place(poly, depth))
        front2 = poly
    m = Mesh()
    m.loft(rings, tag, caps=(False, False))
    # The loft's bands face outward when the outline turns counter-clockwise seen from the front.
    base = m.add(rings[-1])
    for a, b, c in triangulate(front2):
        m.face([base + a, base + b, base + c], cap_tag or tag, unit)
    base = m.add(rings[0])
    for a, b, c in triangulate(poly):
        m.face([base + a, base + c, base + b], tag, unit)
    m = weld(m)
    if unit:
        m.set_unit(unit)
    return m


def _rect(w, h, cx=0.0, cy=0.0):
    return [(cx - w / 2, cy - h / 2), (cx + w / 2, cy - h / 2), (cx + w / 2, cy + h / 2), (cx - w / 2, cy + h / 2)]


def panel(w, h, t=0.035, border=0.07, kind="inset", depth=0.012, bevel=0.03, tag="wood", origin=(0, 0, 0),
          right=(1, 0, 0), up=(0, 1, 0)):
    """A door or shutter panel `w` x `h`, `t` thick, its front towards -Z of the frame. Inside a
    `border` of flat frame the field is `inset` (sunk `depth`, its sides sloping in over `bevel`)
    or `raised` (a fielded panel: a groove, then a bevel rising to a flat field)."""
    o, r, u = _v(origin), _unit(right), _unit(up)
    f = -np.cross(r, u)

    def ring(rw, rh, z):
        return [o + r * x + u * y + f * z for x, y in _rect(rw, rh)]

    iw, ih = w - 2 * border, h - 2 * border
    rings = [ring(w, h, 0.0), ring(w, h, t)]
    if kind == "inset":
        rings += [ring(iw, ih, t), ring(iw - 2 * bevel * 0.4, ih - 2 * bevel * 0.4, t - depth)]
    else:  # raised: down into a groove, then up the bevel to the field
        g = 0.008
        rings += [ring(iw, ih, t), ring(iw, ih, t - depth), ring(iw - 2 * g, ih - 2 * g, t - depth),
                  ring(iw - 2 * g - 2 * bevel, ih - 2 * g - 2 * bevel, t + depth * 0.4)]
    m = Mesh()
    m.loft(rings, tag)
    return weld(m)


# --- Arrays ----------------------------------------------------------------------------------------

def array_linear(mesh, count, step, units_from=0):
    """`count` copies of `mesh`, each `step` further; with `units_from` > 0 each copy is its own
    unit (units_from, units_from + 1, ...)."""
    out = Mesh()
    for i in range(count):
        c = mesh.transformed(np.eye(3), _v(step) * i)
        if units_from:
            c.set_unit(units_from + i)
        out.merge(c)
    return out


def rotation(axis, angle):
    a = _unit(axis)
    K = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
    return np.eye(3) + np.sin(angle) * K + (1 - np.cos(angle)) * K @ K


def array_radial(mesh, count, centre=(0, 0, 0), axis=(0, 1, 0), start=0.0, span=2 * np.pi):
    """`count` copies of `mesh` turned round `axis` through `centre` (a full turn, or `span`)."""
    out = Mesh()
    c = _v(centre)
    full = abs(span - 2 * np.pi) < 1e-9
    for i in range(count):
        ang = start + span * i / (count if full else max(count - 1, 1))
        R = rotation(axis, ang)
        m = mesh.copy()
        m.verts = [R @ (v - c) + c for v in m.verts]
        out.merge(m)
    return out


# --- Openings --------------------------------------------------------------------------------------

def opening_path(w, h, arch=0.0, steps=6):
    """The outline of an opening, from its bottom left, round by the top and back: square, or with a
    segmental arch rising `arch` over the width."""
    if arch <= 0:
        return [(-w / 2, 0.0), (w / 2, 0.0), (w / 2, h), (-w / 2, h)]
    R = (w * w / 4 + arch * arch) / (2 * arch)
    cy = h - R
    a0 = np.arcsin((w / 2) / R)
    pts = [(-w / 2, 0.0), (w / 2, 0.0)]
    for k in range(steps + 1):  # from the right springing over the crown to the left
        a = a0 - 2 * a0 * k / steps
        pts.append((np.sin(a) * R, cy + np.cos(a) * R))
    return pts


def opening_frame(w, h, mould, arch=0.0, origin=(0, 0, 0), tag="stone", sill=None, sill_tag=None, bottom=True):
    """A surround round an opening `w` x `h` (its bottom centre at `origin`, the wall's face the
    plane z = origin's z, the front -Z): the moulding `mould` = [(out from the opening's edge,
    forward of the wall)] swept round it. `sill` = (overhang, depth, thickness): a slab under it,
    its front edge chamfered, a drip groove under the front (where water leaves the wall).
    `bottom` False leaves the bottom rail out (a door)."""
    o = _v(origin)
    pts2 = opening_path(w, h, arch)
    path = [o + X * x + Y * y for x, y in pts2]
    # The profile is drawn in (out, forward); seen along the path (anticlockwise round the opening
    # seen from the front) "side" points out of the opening and "up" forward.
    prof = [(a, b) for a, b in mould]
    m = Mesh()
    if bottom:
        m.merge(sweep(path, prof, tag, closed=True, up=-Z))
    else:
        # A door: the jambs and the head only, standing on the floor.
        p = [o + X * (w / 2)] + path[2:] + [o + X * (-w / 2)]
        m.merge(sweep(p, prof, tag, up=-Z))
    if sill:
        over, dep, th = sill
        st = sill_tag or tag
        sw = w + 2 * max(a for a, _ in mould) + 2 * over
        s = chamfer_box(o + Y * (-th / 2) + Z * (-dep / 2 + 0.02), (sw / 2, th / 2, dep / 2), min(th, dep) * 0.25,
                        st, edges="top")
        m.merge(s)
        # the drip: a small groove under the front edge, shown as a dark strip
        m.merge(box(o + Y * (-th - 0.002) + Z * (-dep + 0.035), (sw / 2 - 0.02, 0.002, 0.006), "hole"))
    return m


def vent(w, h, slots=6, louvre=False, t=0.02, frame=0.03, tag="metal", origin=(0, 0, 0)):
    """A vent `w` x `h` standing on `origin` (its bottom centre on the wall's face, front -Z): a
    frame and `slots` openings between bars, or slanted louvres (`louvre`), a dark cavity behind."""
    o = _v(origin)
    m = Mesh()
    c = min(frame * 0.3, 0.008)
    m.merge(chamfer_box(o + Y * (frame / 2) + Z * (-t / 2), (w / 2, frame / 2, t / 2), c, tag, edges="front"))
    m.merge(chamfer_box(o + Y * (h - frame / 2) + Z * (-t / 2), (w / 2, frame / 2, t / 2), c, tag, edges="front"))
    for s in (-1, 1):
        m.merge(chamfer_box(o + X * s * (w / 2 - frame / 2) + Y * (h / 2) + Z * (-t / 2), (frame / 2, h / 2 - frame, t / 2),
                            c, tag, edges="front"))
    iw, ih = w - 2 * frame, h - 2 * frame
    m.merge(box(o + Y * (h / 2) + Z * 0.004, (iw / 2, ih / 2, 0.003), "hole"))
    pitch = ih / slots
    for k in range(slots - 1 if not louvre else slots):
        y = frame + pitch * (k + (1.0 if not louvre else 0.5))
        if louvre:  # a slat tilted 40 degrees, its front edge low (rain runs off outward)
            R = rotation(X, np.radians(-40))
            m.merge(box((0, 0, 0), (iw / 2, pitch * 0.62, 0.003), tag).transformed(R, o + Y * y + Z * (-t * 0.45)))
        else:
            bar = pitch * 0.45
            m.merge(chamfer_box(o + Y * y + Z * (-t * 0.4), (iw / 2, bar / 2, t * 0.4), bar * 0.2, tag, edges="front"))
    return m


# --- Damage ----------------------------------------------------------------------------------------

def subdivide(mesh, n):
    """Every quad cut into an n x n grid (triangles and bigger faces stay): room for a dent."""
    out = Mesh()
    for f, t, u in zip(mesh.faces, mesh.tags, mesh.units_list()):
        if len(f) != 4 or n <= 1:
            base = out.add([mesh.verts[i] for i in f])
            out.face(range(base, base + len(f)), t, u)
            continue
        a, b, c, d = (mesh.verts[i] for i in f)
        grid = [[a + (b - a) * (i / n) + ((d + (c - d) * (i / n)) - (a + (b - a) * (i / n))) * (j / n)
                 for i in range(n + 1)] for j in range(n + 1)]
        base = out.add([p for row in grid for p in row])
        for j in range(n):
            for i in range(n):
                k = base + j * (n + 1) + i
                out.face([k, k + 1, k + n + 2, k + n + 1], t, u)
    return weld(out)


def dent(mesh, centre, radius, depth, direction, crush=False):
    """Push the points within `radius` of `centre` along `direction` by up to `depth` (a smooth
    bowl: deepest in the middle, nothing at the rim). `crush`: only what stands proud of the
    bowl is pushed, onto it (a kick into corrugated sheet flattens the crests, the troughs stay)."""
    c, d = _v(centre), _unit(direction)
    m = mesh.copy()
    out = []
    for v in m.verts:
        r = np.linalg.norm((v - c) - d * ((v - c) @ d)) / radius
        if r >= 1:
            out.append(v)
            continue
        k = depth * (1 - r * r) ** 2
        if crush:
            s = (v - c) @ d
            out.append(v + d * (k - s) if s < k else v)
        else:
            out.append(v + d * k)
    m.verts = out
    return m


def broken_pane(w, h, holes=(), t=0.004, origin=(0, 0, 0), tag="glass", seed=0, ring=28):
    """A pane `w` x `h` (bottom centre at `origin`, in the plane z = origin's z) with jagged holes
    punched through it: `holes` = [(x, y from the bottom centre, radius)]. Each hole's rim is a
    ring of shards (points in and out at random) joined to the pane's edge, both faces and the
    broken edge modelled. Only the first hole is cut when there are more (the rest are painted
    cracks)."""
    o = _v(origin)
    m = Mesh()
    if not holes:
        return box(o + Y * (h / 2), (w / 2, h / 2, t / 2), tag)
    hx, hy, hr = holes[0]
    rng = np.random.default_rng(seed)
    c = np.array([hx, hy])
    ang = np.linspace(0, 2 * np.pi, ring, endpoint=False) + rng.uniform(-0.08, 0.08, ring)
    rad = hr * np.where(np.arange(ring) % 2, rng.uniform(0.45, 0.8, ring), rng.uniform(0.9, 1.5, ring))
    inner = c + np.stack([np.cos(ang), np.sin(ang)], 1) * rad[:, None]
    # the pane's edge, sampled at the same angles from the hole (a ray to the rectangle)
    outer = []
    for a in ang:
        d = np.array([np.cos(a), np.sin(a)])
        tx = ((w / 2 if d[0] > 0 else -w / 2) - c[0]) / d[0] if abs(d[0]) > 1e-9 else 1e9
        ty = ((h if d[1] > 0 else 0.0) - c[1]) / d[1] if abs(d[1]) > 1e-9 else 1e9
        outer.append(c + d * min(tx, ty))
    corners = [(-w / 2, 0.0), (w / 2, 0.0), (w / 2, h), (-w / 2, h)]

    def P3(p, z):
        return o + X * p[0] + Y * p[1] + Z * z

    for z, flip in ((-t / 2, False), (t / 2, True)):
        for i in range(ring):
            j = (i + 1) % ring
            q = [P3(outer[i], z), P3(outer[j], z), P3(inner[j], z), P3(inner[i], z)]
            b = m.add(q)
            m.face([b, b + 1, b + 2, b + 3][::-1] if flip else [b, b + 1, b + 2, b + 3], tag)
            # a corner of the pane between two rays: a triangle to the hole's centre-side point
            a0, a1 = ang[i], ang[j] if j else ang[j] + 2 * np.pi
            for cx, cy in corners:
                ca = np.arctan2(cy - c[1], cx - c[0]) % (2 * np.pi)
                lo, hi = a0 % (2 * np.pi), a1 % (2 * np.pi)
                inside = lo < ca < hi if lo < hi else (ca > lo or ca < hi)
                if inside:
                    tri = [P3(outer[i], z), P3((cx, cy), z), P3(outer[j], z)]
                    b = m.add(tri)
                    m.face([b, b + 1, b + 2][::-1] if flip else [b, b + 1, b + 2], tag)
    for i in range(ring):  # the broken edge round the hole
        j = (i + 1) % ring
        b = m.add([P3(inner[i], -t / 2), P3(inner[j], -t / 2), P3(inner[j], t / 2), P3(inner[i], t / 2)])
        m.face([b, b + 1, b + 2, b + 3], tag)
    return weld(m)


def miswound(mesh):
    """How many edges disagree on winding (each edge must run once each way in a closed,
    consistently wound piece; an open rim counts too, so use it on closed shapes)."""
    _, T, _ = weld(mesh).triangles()
    seen = {}
    for t in T:
        for i in range(3):
            e = (int(t[i]), int(t[(i + 1) % 3]))
            seen[e] = seen.get(e, 0) + 1
    return sum(1 for (a, b), n in seen.items() if n > 1 or (b, a) not in seen)


def check():
    """The kit's own checks: shapes that must be closed are, sweeps are mitred, triangulation works
    on a concave outline. `python tools/models/shapes.py --check`."""
    fails = []

    def closed(name, m):
        n = weld(m).check_closed()
        if n:
            fails.append(f"{name}: {n} open edges")

    for name, m in (("chamfer_box", chamfer_box((0, 0, 0), (0.3, 0.2, 0.1), 0.02)),
                    ("bevel_box", bevel_box((0, 0, 0), (0.3, 0.2, 0.1), 0.03)),
                    ("extrude", extrude([(0, 0), (3, 0), (3, 1), (2, 1), (2, 3), (1, 3), (1, 1), (0, 1)], 0.2, 0.05)),
                    ("cut", cut(box((0, 0, 0), (0.1, 0.5, 0.1)), (0, 0.1, 0), (0.3, 1, 0.1), rough=0.03)[1]),
                    ("panel", panel(0.5, 0.8, kind="raised")), ("pipe", pipe([(0, 0, 0), (0, 1, 0), (1, 1, 0.5)], 0.04, bend=0.15))):
        if miswound(m):
            fails.append(f"{name}: {miswound(m)} edges wound against their neighbours")
    closed("chamfer_box", chamfer_box((0, 0, 0), (0.3, 0.2, 0.1), 0.02))
    closed("bevel_box", bevel_box((0, 0, 0), (0.3, 0.2, 0.1), 0.03))
    closed("chamfer_box top", chamfer_box((0, 0, 0), (0.3, 0.2, 0.1), 0.02, edges="top"))
    a, b = cut(box((0, 0, 0), (0.1, 0.5, 0.1)), (0, 0.1, 0), (0.3, 1, 0.1), rough=0.03, seed=3)
    closed("cut lower", a)
    closed("cut upper", b)
    closed("sweep", sweep([(0, 0, 0), (0, 1, 0), (1, 1, 0)], circle(0.05, 6)))
    closed("pipe", pipe([(0, 0, 0), (0, 1, 0), (1, 1, 0.5)], 0.04, bend=0.15))
    closed("extrude concave", extrude([(0, 0), (3, 0), (3, 1), (2, 1), (2, 3), (1, 3), (1, 1), (0, 1)], 0.2, 0.05))
    closed("panel raised", panel(0.5, 0.8, kind="raised"))
    fr = sweep([(x, y, 0) for x, y in opening_path(1, 1.4)], [(0, 0), (0.1, 0), (0.1, 0.05), (0, 0.05)], closed=True, up=-Z)
    closed("frame", fr)
    t = triangulate([(0, 0), (3, 0), (3, 1), (2, 1), (2, 3), (1, 3), (1, 1), (0, 1)])
    if len(t) != 6:
        fails.append(f"triangulate: {len(t)} triangles for an 8-gon")
    return fails


if __name__ == "__main__":
    import sys
    if "--check" in sys.argv:
        f = check()
        print("\n".join(f) if f else "shapes: all checks pass")
        sys.exit(1 if f else 0)
