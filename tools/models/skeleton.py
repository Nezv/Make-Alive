"""A low-poly human skeleton, made like the bodies (tools/models/poly.py: flat faces, never a
curve) and fitted inside them: each bone rides the joint its body piece rides, the skull is the
head's own rings pulled in (its sockets sit behind the eyes), the hand and foot bones follow the
body's fingers and toes. Bodies take bits of it (bone stubs where a severed part's wound shows);
on its own it is a model like the others.

    tools\\blender.ps1 tools\\models\\skeleton.py    -> assets/models/zombie_skeleton.glb (+ textures)
    python tools/models/body.py --sketch            -> draws it beside the bodies (x-ray view too)

Game coordinates: metres, Y up, facing -Z, the model's right is +X. Built for the male body's
proportions; `bones(p)` takes either variant.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np  # noqa: E402

import body as B  # noqa: E402
from poly import Mesh, knob, limb, strip, tapered_block  # noqa: E402

TEX = 512


def _limb(a, b, r0, r1=None, sides=6, tag="bone"):
    """A bone's shaft from a to b, radius r0 at a and r1 at b, flat ends."""
    a = np.asarray(a, dtype=np.float64)
    b = np.asarray(b, dtype=np.float64)
    L = float(np.linalg.norm(b - a))
    r1 = r0 if r1 is None else r1
    return limb(a, b, [(0.0, r0, r0), (L, r1, r1)], sides=sides, turn=np.pi / sides, tag=tag)


def _plate(outline, thick, tag="bone"):
    """A flat plate (a shoulder blade): a convex outline thickened along its normal."""
    P = np.asarray(outline, dtype=np.float64)
    n = np.cross(P[1] - P[0], P[2] - P[0])
    n /= np.linalg.norm(n)
    m = Mesh()
    m.loft([P - n * thick / 2, P + n * thick / 2], tag)
    return m


def vertebra(center, w, h, d, tag="bone"):
    """A vertebra: its body, and its spine pointing back and down."""
    x, y, z = center
    m = Mesh()
    m.box(center, (w, h, d), tag)
    m.merge(tapered_block((x, y, z + d * 0.7), (x, y - h * 1.6, z + d * 2.7), (w * 0.32, h * 0.7),
                          (w * 0.14, h * 0.35), up=(0, 1, 0), tag=tag))
    return m


# --- Skull ------------------------------------------------------------------------------------------

def skull(p, eyes=True):
    """The head's rings pulled in under the skin: deep round sockets, a hole for the nose, hollow
    cheeks, bare teeth where the lips were."""
    rings, L = B.head_rings(p)
    names = [n for n, _ in rings]
    H = L["H"]
    out = []
    for name, ring in rings:
        pts = []
        for j, (x, t, z) in enumerate(ring):
            col = j if j <= 8 else 16 - j
            r = np.hypot(x, z - 0.01)
            k = max(r - 0.013, 0.02) / r if r > 1e-6 else 1.0
            x2, z2 = x * k, 0.01 + (z - 0.01) * k
            t2 = t - 0.013 * (t / H) ** 3
            if name in ("socket_lo", "socket_hi") and col in (1, 2, 3):
                z2 += 0.017
                x2 += np.sign(x) * 0.006 * (col == 3)
            if name in ("nose_lo", "nose_tip", "cheek") and col in (0, 1):
                z2 = max(z2, -0.112 if col == 0 else -0.108)
            if name in ("nose_lo", "lip_hi", "mouth_hi") and col in (3, 4):
                z2 += 0.009
            pts.append((x2, t2, z2))
        out.append(pts)
    i_lip_lo, i_mouth_hi = names.index("lip_lo"), names.index("mouth_hi")
    i_sock_lo, i_sock_hi = names.index("socket_lo"), names.index("socket_hi")
    i_chin, i_nose_lo, i_cheek = names.index("chin"), names.index("nose_lo"), names.index("cheek")

    def tag(r, j):
        if j in B.MOUTH_BANDS:
            if i_lip_lo <= r <= i_mouth_hi:
                return "socket"
            if r == i_chin or r == i_mouth_hi + 1:
                return "teeth"
        if j in B.SOCKET_BANDS and i_sock_lo - 1 <= r <= i_sock_hi:
            return "socket"
        if j in (0, 15) and i_nose_lo <= r < i_cheek:
            return "socket"
        return None

    m = Mesh()
    m.loft([B._to_head(r, p) for r in out], "bone", band_tags=tag)
    if eyes:  # pinpoints glowing deep in the sockets
        t_e, ex = L["t_eye"], L["ex"]
        for s in (1.0, -1.0):
            c = B._to_head([(s * ex, t_e, -0.098)], p)[0]
            m.box(c, (0.006, 0.004, 0.004), "eye")
    return m


def cervical(p):
    """Neck vertebrae, from under the skull down into the chest (the lowest one is the stub a
    severed head shows)."""
    m = Mesh()
    for i, y in enumerate(np.linspace(1.44, 1.6, 5)):
        m.merge(vertebra((0.0, y, 0.022), 0.019, 0.011, 0.015))
    return m


# --- Trunk ------------------------------------------------------------------------------------------

def _spine_z(y):
    return 0.045 + 0.03 * np.sin(np.pi * np.clip((y - 1.17) / 0.33, 0, 1))


def thoracic(p, lo=1.03, hi=1.5):
    m = Mesh()
    for y in np.linspace(0.99, 1.5, 13):
        if lo <= y <= hi:
            k = 1.0 + (1.5 - y) * 0.5
            m.merge(vertebra((0.0, y, _spine_z(y)), 0.021 * k, 0.012 * k, 0.017 * k))
    return m


RIB_W = [0.115, 0.148, 0.168, 0.183, 0.193, 0.198, 0.196, 0.188]


def ribs(p):
    """Eight pairs: from the spine round the side and forward, the upper six to the breastbone."""
    m = Mesh()
    wide = p["torso"][6][4][0] / 0.244  # chest width of this body against the male's
    for i, w0 in enumerate(RIB_W):
        w = w0 * wide
        yb = 1.465 - 0.036 * i
        zs = _spine_z(yb)
        pts = [(0.022, yb, zs), (0.065, yb - 0.004, zs + 0.035), (0.8 * w, yb - 0.018, zs + 0.03),
               (w, yb - 0.045, zs - 0.05), (0.82 * w, yb - 0.075, zs - 0.125), (0.5 * w, yb - 0.095, zs - 0.158)]
        if i < 6:
            pts.append((0.024, 1.455 - 0.028 * i, -0.106))
        for s in (1.0, -1.0):
            side = [(s * x, y, z) for x, y, z in pts]
            m.merge(strip(side, 0.0085, 0.0045, up=(0, 1, 0)))
    return m


def sternum(p):
    m = Mesh()
    m.merge(tapered_block((0, 1.476, -0.104), (0, 1.43, -0.108), (0.026, 0.006), (0.02, 0.006), up=(0, 0, -1),
                          tag="bone"))
    m.merge(tapered_block((0, 1.43, -0.108), (0, 1.3, -0.118), (0.017, 0.006), (0.014, 0.006), up=(0, 0, -1),
                          tag="bone"))
    m.merge(tapered_block((0, 1.3, -0.118), (0, 1.27, -0.115), (0.008, 0.004), (0.003, 0.003), up=(0, 0, -1),
                          tag="bone"))
    return m


def shoulder_girdle(p):
    """Collarbones to the top of each shoulder, and the shoulder blades on the back."""
    m = Mesh()
    ax = B.SHOULDER[0] - p["arm_in"]
    tip = ax - 0.025
    for s in (1.0, -1.0):
        clav = [(0.026, 1.476, -0.1), (0.08, 1.487, -0.108), (0.15, 1.497, -0.09), (0.5 * (0.15 + tip), 1.506, -0.052),
                (tip, 1.512, -0.02)]
        m.merge(strip([(s * x, y, z) for x, y, z in clav], 0.008, 0.0065))
        blade = [(0.075, 1.495, 0.112), (tip - 0.03, 1.47, 0.06), (0.125, 1.29, 0.105), (0.07, 1.36, 0.115)]
        m.merge(_plate([(s * x, y, z) for x, y, z in blade], 0.007))
        ridge = [(0.085, 1.455, 0.124), (tip - 0.02, 1.49, 0.07), (tip, 1.505, 0.01)]
        m.merge(strip([(s * x, y, z) for x, y, z in ridge], 0.007, 0.006))
    return m


def pelvis(p):
    """Hip blades, sockets, the pubic and sitting bones, sacrum and tailbone; and the lumbar
    vertebrae below the torso's break."""
    m = Mesh()
    wide = p["torso"][2][4][0] / 0.207  # this body's pelvis against the male's
    for s in (1.0, -1.0):
        def S(pts):
            return [(s * x * wide, y, z) for x, y, z in pts]
        crest = [(0.045, 0.98, 0.07), (0.1, 1.02, 0.06), (0.155, 1.015, 0.02), (0.175, 0.985, -0.03),
                 (0.15, 0.95, -0.072)]
        m.merge(strip(S(crest), 0.03, 0.006))
        m.merge(tapered_block(S([(0.135, 0.975, 0.0)])[0], (s * 0.12, 0.925, 0.0), (0.03, 0.012), (0.026, 0.02),
                              up=(0, 0, 1), tag="bone"))
        m.merge(knob((s * 0.124, 0.92, 0.0), 0.033, axis=(s, 0, 0)))
        m.merge(strip(S([(0.105, 0.905, -0.035), (0.06, 0.875, -0.065), (0.012, 0.86, -0.072)]), 0.01, 0.008))
        m.merge(strip(S([(0.11, 0.895, 0.025), (0.085, 0.825, 0.03), (0.045, 0.82, -0.02), (0.012, 0.845, -0.068)]),
                      0.009, 0.008))
    m.merge(tapered_block((0, 1.0, 0.065), (0, 0.88, 0.085), (0.048, 0.012), (0.016, 0.008), up=(0, 0, 1), tag="bone"))
    m.merge(tapered_block((0, 0.88, 0.085), (0, 0.84, 0.07), (0.012, 0.006), (0.004, 0.004), up=(0, 0, 1), tag="bone"))
    m.merge(thoracic(p, lo=0.0, hi=1.025))
    return m


# --- Limbs (right side; the left mirrors) -----------------------------------------------------------

def humerus(p, stub_only=False):
    ax = B.SHOULDER[0] - p["arm_in"]
    m = Mesh()
    if stub_only:  # its top stays under the shoulder's ledge
        return m.merge(knob((ax, 1.448, 0.0), 0.02 * p["arm"]))
    m.merge(knob((ax, 1.48, 0.0), 0.025 * p["arm"]))
    m.merge(_limb((ax, 1.47, 0.0), (ax, 1.205, 0.003), 0.0145 * p["arm"], 0.013 * p["arm"]))
    m.box((ax, 1.188, 0.006), (0.034 * p["arm"], 0.016, 0.018), "bone")
    return m


def forearm_bones(p):
    ax = B.ELBOW[0] - p["arm_in"]
    k = p["arm"]
    m = Mesh()
    m.merge(knob((ax - 0.006, 1.2, 0.026), 0.013 * k))
    m.merge(_limb((ax - 0.01, 1.185, 0.02), (ax - 0.016, 0.918, 0.012), 0.009 * k, 0.007 * k))
    m.merge(_limb((ax + 0.012, 1.175, -0.006), (ax + 0.008, 0.918, -0.022), 0.0075 * k, 0.011 * k))
    h = p["hand"]
    top = 0.915
    knuckle = top - 0.102 * h
    m.box((ax, 0.898, -0.004), (0.013, 0.013, 0.03 * h), "bone")
    lengths = (0.1, 0.112, 0.106, 0.09)
    for i in range(4):
        z = (-0.045 + i * 0.03) * h
        L = lengths[i] * h
        a = np.array([ax - 0.004, knuckle + 0.008, z])
        mid = a + np.array([-np.sin(0.22), -np.cos(0.22), 0.0]) * L * 0.55
        tip = mid + np.array([-np.sin(0.75), -np.cos(0.75), 0.0]) * L * 0.45
        m.merge(_limb((ax, 0.888, z * 0.7), a, 0.006 * h))
        m.merge(knob(a, 0.0075 * h))
        m.merge(_limb(a, mid, 0.0065 * h, 0.006 * h))
        m.merge(_limb(mid, tip, 0.0058 * h, 0.0045 * h))
    base = np.array([ax - 0.014, top - 0.026 * h, -0.05 * h])
    mid = base + np.array([-0.016, -0.04, -0.032]) * h
    tip = mid + np.array([-0.018, -0.036, -0.006]) * h
    m.merge(_limb((ax - 0.004, 0.9, -0.024 * h), base, 0.007 * h))
    m.merge(_limb(base, mid, 0.007 * h, 0.0065 * h))
    m.merge(_limb(mid, tip, 0.0062 * h, 0.0048 * h))
    return m


def femur(p, stub_only=False):
    """The thigh bone. As a stub, its head and a broken shaft end poking up out of the thigh's
    wound (inside the hips while the leg is on)."""
    m = Mesh()
    hx, hy = B.HIP[0], B.HIP[1]
    m.merge(knob((hx, hy, 0.0), 0.027))
    if stub_only:
        m.merge(limb((hx, hy, 0.002), (hx, hy + 0.1, 0.002), [(0.0, 0.015, 0.015), (0.07, 0.014, 0.014),
                     (0.085, 0.0, 0.0)], sides=5, tag="bone"))
        return m
    m.merge(_limb((hx, hy, 0.0), (hx + 0.052, hy - 0.025, 0.0), 0.016, 0.018))
    m.merge(knob((hx + 0.06, hy - 0.015, 0.008), 0.02))
    m.merge(_limb((hx + 0.052, hy - 0.035, 0.004), (hx + 0.008, 0.505, 0.006), 0.017, 0.016))
    m.box((hx + 0.002, 0.485, 0.006), (0.037 * p["thigh"], 0.02, 0.028), "bone")
    return m


def shin_bones(p):
    x = B.KNEE[0]
    k = p["shin"]
    m = Mesh()
    m.box((x, 0.47, -0.05), (0.022, 0.026, 0.008), "bone")
    m.box((x, 0.452, 0.0), (0.037 * k, 0.011, 0.03 * k), "bone")
    m.merge(_limb((x - 0.002, 0.44, -0.01), (x - 0.008, 0.105, -0.004), 0.017 * k, 0.013 * k))
    m.merge(knob((x - 0.02, 0.09, -0.002), 0.013))
    m.merge(_limb((x + 0.033 * k, 0.44, 0.012), (x + 0.03 * k, 0.1, 0.008), 0.0075 * k))
    m.merge(knob((x + 0.032 * k, 0.085, 0.008), 0.012))
    f = p["foot"]
    m.merge(tapered_block((x, 0.035, 0.072), (x, 0.045, 0.01), (0.02, 0.024), (0.022, 0.026), up=(0, 1, 0), tag="bone"))
    m.box((x, 0.068, 0.005), (0.022, 0.016, 0.024), "bone")
    m.box((x, 0.05, -0.035), (0.036 * f, 0.016, 0.022), "bone")
    for i, dx in enumerate((-0.03, -0.015, 0.0, 0.015, 0.028)):
        r = (0.0075 if i == 0 else 0.0055) * f
        a = (x + dx * f, 0.042, -0.055)
        b = (x + dx * f * 1.15, 0.02, -0.115 * f)
        c = (x + dx * f * 1.2, 0.012, -0.165 * f)
        m.merge(_limb(a, b, r))
        m.merge(_limb(b, c, r * 0.9, r * 0.75))
    return m


# --- Whole ------------------------------------------------------------------------------------------

def bones(p):
    """{(piece, side): Mesh} on the same pieces (and joints) as the body."""
    head = skull(p)
    head.merge(cervical(p))
    chest = Mesh()
    for part in (thoracic(p), ribs(p), sternum(p), shoulder_girdle(p)):
        chest.merge(part)
    out = {(B.HEAD, 0): head, (B.TORSO, 0): chest, (B.PELVIS, 0): pelvis(p)}
    for piece, fn in ((B.UPPER_ARM, humerus), (B.FOREARM, forearm_bones), (B.THIGH, femur), (B.SHIN, shin_bones)):
        right = fn(p)
        out[(piece, 1)] = right
        out[(piece, -1)] = right.mirrored()
    return out


BONE = np.array([0.8, 0.76, 0.64])
PALETTE = dict(B.PALETTE, bone=BONE, teeth=np.array([0.86, 0.82, 0.68]), socket=np.array([0.1, 0.08, 0.08]))


def flat_colours(tags):
    return np.array([PALETTE[t] for t in tags])


def paint(maps):
    """Old bone: dirt in the hollows, stains, a little blood."""
    from noise import fbm
    mask = maps["mask"]
    P = maps["pos"][mask].astype(np.float32)
    N = maps["nrm"][mask].astype(np.float32)
    tag = np.clip(maps["tag"][mask], 0, len(B.TAGS) - 1)
    ao = np.clip(maps["ao"][mask], 0, 1)
    col = np.array([PALETTE[t] for t in B.TAGS], dtype=np.float32)[tag]
    bone = tag == B.TAG["bone"]
    stain = fbm(P, 14.0, 3, 51)
    col[bone] *= (0.86 + 0.18 * stain[bone])[:, None]
    brown = bone & (fbm(P, 6.0, 3, 53) > 0.62)
    col[brown] = col[brown] * 0.75 + np.array([0.45, 0.36, 0.26], np.float32) * 0.25
    splats = [((0.0, 1.62, -0.12), 0.04), ((0.05, 1.4, -0.1), 0.05), ((-0.1, 1.3, 0.0), 0.04),
              ((0.3, 1.0, 0.0), 0.04), ((-0.13, 0.6, 0.0), 0.04), ((0.12, 0.25, 0.0), 0.035)]
    keep = tag != B.TAG["eye"]
    col[keep] = B.blood(P[keep], N[keep], col[keep], splats, [], None, seed=13)
    col *= (0.55 + 0.45 * ao)[:, None]
    eye = tag == B.TAG["eye"]
    col[eye] = PALETTE["eye"]
    emit = np.zeros_like(col)
    emit[eye] = PALETTE["eye"]
    size = mask.shape[0]
    albedo = np.zeros((size, size, 3), np.float32)
    emission = np.zeros((size, size, 3), np.float32)
    albedo[mask] = col
    emission[mask] = emit
    return albedo, emission


def main():
    import pipeline as pl
    quick = "--quick" in sys.argv
    p = B.MALE
    name = "zombie_skeleton"
    pl.reset_scene()
    objs = []
    for (pc, side), mesh in bones(p).items():
        P, T, tags = mesh.triangles()
        objs.append(pl.mesh_from_poly(f"{name}_{pc}_{side}", P, T, {"piece": pc, "tag": [B.TAG[t] for t in tags]}))
    obj = pl.join(objs, "ZombieSkeleton")
    tris = len(obj.data.polygons)
    if quick:
        pl.flat_materials(obj, "tag", [PALETTE[t] for t in B.TAGS])
    else:
        pl.unwrap(obj, {B.HEAD: 1.6})
        maps = pl.bake_maps(obj, TEX, (-0.5, -0.05, -0.3), (0.5, 2.05, 0.3), attrs=("piece", "tag"), ao_samples=32)
        albedo, emission = paint(maps)
        os.makedirs(B.OUT, exist_ok=True)
        alb = pl.save_png(albedo, os.path.join(B.OUT, name + "_albedo.png"), TEX)
        em = pl.save_png(emission, os.path.join(B.OUT, name + "_emission.png"), TEX)
        pl.textured_material(obj, alb, em)
        Pv, piece_v = pl.vertex_arrays(obj)
        arm = pl.add_rig(obj, B.skin_weights(Pv, piece_v, seam=False))
        pl.export_glb([obj, arm], os.path.join(B.OUT, name + ".glb"))
    print(f"built {name}: {tris} triangles{' (quick)' if quick else ''}")
    pl.render_views(obj, B.SHOTS, "model_skeleton", B.VIEWS)
    pl.contact_sheet([os.path.join(B.SHOTS, f"model_skeleton_{v[0]}.png") for v in B.VIEWS],
                     os.path.join(B.SHOTS, "model_skeleton.png"), len(B.VIEWS))


if __name__ == "__main__":
    main()
