"""The zombies' outfits as models: the male and female bodies of body.py dressed in the clothes of
clothes.py (shirts with long or short sleeves, jackets and coats, trousers, shoes and boots).
Plain colours for now: one per garment part; prints, badges and other details come later.

    tools\\blender.ps1 tools\\models\\outfits.py             -> assets/models/zombie_<outfit>_<m|f>.glb
                                                             (+ _albedo.png, _emission.png), previews
    tools\\blender.ps1 tools\\models\\outfits.py cop --f     -> only those (any outfit names, --m / --f)
    tools\\blender.ps1 tools\\models\\outfits.py --quick     -> shapes only, flat colours, previews
    tools\\blender.ps1 tools\\models\\outfits.py nurse --f --bitten -> also the ten bite variants (zombie_<outfit>_<m|f>_b<N>.glb, --only-bite=N one,
                                                             sharing the outfit's textures; --bite-shots renders them)
    python tools/models/outfits.py --bites nurse --f       -> every bite flat-shaded, no Blender (references/shots/bites_*.png)
    python tools/models/outfits.py --sketch [names]        -> flat-shaded pictures without Blender,
                                                             standing and bent in the game's poses
                                                             (references/shots/sketch_outfit_*.png)
    python tools/models/outfits.py --folds [names]         -> how many faces fold over in each pose

Game coordinates: metres, Y up, facing -Z, the model's right is +X.
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np  # noqa: E402

import body as B  # noqa: E402
import clothes as C  # noqa: E402
import rig  # noqa: E402
from poly import Mesh  # noqa: E402

ROOT = B.ROOT
OUT = B.OUT
SHOTS = B.SHOTS
TEX = 1024

# Under clothes the arms hang further out than the bare bodies' (body.py pulls them in against
# the chest): a sleeve's inside then just meets the shirt's side instead of cutting into it.
DRESSED = {"m": dict(B.MALE, arm_in=0.004), "f": dict(B.FEMALE, arm_in=0.048)}


def _c(h):
    return B._hex(h)


# --- The outfits ---------------------------------------------------------------------------------
# top: clothes.top's arguments; pants: clothes.pants's; shoes: "shoe", "sneaker" or "boot";
# hat: clothes.hat's kind; colours: one per tag the garments use.

OUTFITS = {
    "civilian": dict(
        top=dict(sleeves="short", neck="crew", hem=0.95),
        pants=dict(length="long"), shoes="sneaker",
        colours=dict(shirt="3d5a80", pants="34435e", shoe="d8d8d0", sole="f2f2ea")),
    "worker": dict(
        top=dict(sleeves="short", neck="crew", hem=0.95, ease=0.02, tags=dict(main="vest", sleeve="shirt")),
        pants=dict(length="long", ease=0.014), shoes="boot", hat="hard",
        colours=dict(vest="e0701a", shirt="5b6b7a", pants="34435e", shoe="6a4a28", sole="2a2018",
                     hat="e8c21a", hat2="d0aa10")),
    "nurse": dict(
        top=dict(sleeves="short", neck="crew", hem=0.94),
        pants=dict(length="long"), shoes="shoe", hat="nurse", blood_every=2,
        colours=dict(shirt="4fa3a0", pants="3f8f8c", shoe="e8e8e0", sole="b8b8b0", hat="e8e8e0")),
    "doctor": dict(
        top=dict(sleeves="long", neck="collar", hem=0.84, ease=0.024, hem_flare=0.01,
                 opening=dict(x=0.07, depth=0.02), tags=dict(main="coat", trim="coat", inner="shirt2")),
        pants=dict(length="long"), shoes="shoe",
        colours=dict(coat="e4e4dc", shirt2="5f8fb0", pants="3a3a40", shoe="1c1c22", sole="101014")),
    "cop": dict(
        top=dict(sleeves="long", neck="collar", hem=0.97, tucked=True),
        pants=dict(length="long", top_ease=0.024, tags=dict(belt="belt")), shoes="boot", hat="cap",
        colours=dict(shirt="5a7aa8", pants="1c2438", belt="15151a", shoe="15151a", sole="0e0e10",
                     hat="1f2a44", hat2="15151a")),
    "soldier": dict(
        top=dict(sleeves="long", neck="high", hem=0.92, ease=0.026, sleeve_ease=0.016,
                 tags=dict(main="vest", trim="jacket", sleeve="jacket")),
        pants=dict(length="long", ease=0.016), shoes="boot", hat="helmet",
        colours=dict(vest="3b4530", jacket="5a6a44", pants="55643f", shoe="2a2420", sole="15120f",
                     hat="4a5638")),
    "firefighter": dict(
        top=dict(sleeves="long", neck="high", hem=0.84, ease=0.03, sleeve_ease=0.02, hem_flare=0.012,
                 tags=dict(main="coat", trim="coat")),
        pants=dict(length="long", ease=0.02), shoes="boot", hat="fire",
        colours=dict(coat="9a8048", pants="8c7440", shoe="15151a", sole="0e0e10", hat="b3261e", hat2="9a1e18")),
    "office": dict(
        top=dict(sleeves="long", neck="collar", hem=0.86, ease=0.022,
                 opening=dict(x=0.06, depth=0.018), tags=dict(main="jacket", trim="jacket", inner="shirt2")),
        pants=dict(length="long"), shoes="shoe",
        colours=dict(jacket="2b2e36", shirt2="d9d9d2", pants="25282f", shoe="15151a", sole="0e0e10")),
    "prisoner": dict(
        top=dict(sleeves="short", neck="crew", hem=0.95),
        pants=dict(length="long"), shoes="sneaker",
        colours=dict(shirt="d0661a", pants="c45f18", shoe="c8c8c0", sole="9a9a92")),
}
NAMES = list(OUTFITS)

# What a face of the model is, for the painter: the body's tags, then the clothes'.
TAGS = B.TAGS + ["shirt", "shirt2", "vest", "jacket", "coat", "pants", "belt", "shoe", "sole", "hat", "hat2"]
TAG = {name: i for i, name in enumerate(TAGS)}
CLOTH = set(TAGS) - set(B.TAGS)


# --- Assembling ----------------------------------------------------------------------------------

def _body_data(piece, side, P, p):
    """Skinning data of a body piece's points (each piece rides one joint, as in body.py)."""
    s = {1: "r", -1: "l", 0: ""}[side]
    one = {B.HEAD: ("neck", "head"), B.HAIR: ("neck", "head"), B.UPPER_ARM: ("shoulder_" + s, "upper_arm_" + s),
           B.FOREARM: ("elbow_" + s, "forearm_" + s), B.THIGH: ("hip_" + s, "thigh_" + s),
           B.SHIN: ("knee_" + s, "shin_" + s)}
    if piece in one:
        bone, seg = one[piece]
        return [C.on(bone, seg)] * len(P)
    return C.trunk(P, p)


def dress(name, sex):
    """Everything of one outfit on one body: [(piece number, Mesh with skinning data)]."""
    rec = OUTFITS[name]
    p = DRESSED[sex]
    fit = C.Fit(p)
    top_args = dict(rec["top"])
    pants_args = dict(rec["pants"])
    shoe_kind = rec["shoes"]
    pants_ease = pants_args.get("ease", 0.012)
    if not top_args.get("tucked"):
        top_args["under_ease"] = pants_args.get("top_ease", pants_ease)
    shirt = C.top(fit, **top_args)
    shoe_ease = 0.012
    pants_args.setdefault("shoe_ease", shoe_ease if shoe_kind != "boot" else shoe_ease + 0.012)
    if shoe_kind == "boot":
        pants_args.setdefault("hem", 0.2)
    trousers = C.pants(fit, **pants_args)
    shoe_r = C.shoe(fit, shoe_kind, ease=shoe_ease, pants_ease=pants_ease)
    sleeves = top_args.get("sleeves", "long")
    cover = dict(torso=True, thigh="all", shin="all" if pants_args.get("length") == "long" else 0.66,
                 feet=True, shoe_top=0.1)
    if sleeves == "long":
        cover.update(upper_arm="all", forearm=0.955)
    elif sleeves == "short":
        cover.update(upper_arm=1.3)
    if pants_args.get("length") == "shorts":
        cover.update(thigh=0.72, shin=None)
    parts = []
    for (piece, side), m in C.body_under(p, cover).items():
        P = np.array(m.verts)
        m.vdata = _body_data(piece, side, P, p)
        parts.append((piece, m))
    parts.append((B.TORSO, shirt))
    parts.append((B.PELVIS, trousers))
    parts.append((B.SHIN, shoe_r))
    parts.append((B.SHIN, shoe_r.mirrored()))
    if rec.get("hat"):
        parts.append((B.HAIR, C.hat(fit, rec["hat"])))
    return parts, p


def combined(parts):
    """All parts in one Mesh (points no face uses dropped), and the piece of every face."""
    m = Mesh()
    piece_of = []
    for piece, part in parts:
        m.merge(part)
        piece_of += [piece] * len(part.faces)
    used = sorted({i for f in m.faces for i in f})
    remap = {old: new for new, old in enumerate(used)}
    out = Mesh()
    out.verts = [m.verts[i] for i in used]
    out.vdata = [m.vdata[i] for i in used]
    for f, t in zip(m.faces, m.tags):
        out.face([remap[i] for i in f], t)
    return out, piece_of


def colours(name):
    rec = OUTFITS[name]
    pal = dict(B.PALETTE)
    for t in CLOTH:
        pal[t] = _c(rec["colours"].get(t, "808080"))
    return pal


# --- Painting ------------------------------------------------------------------------------------
# Like body.paint: every texel knows where it is, which way it faces, its piece and its face's
# tag. The tag gives the flat colour (one per face: the faceted look); cloth gets a faint weave of
# light and dark and dirt towards the ground; blood goes over everything by position.

def paint(maps, p, name):
    """Albedo and emission (both sRGB) for every texel the bake reached."""
    from noise import fbm
    pal = colours(name)
    mask = maps["mask"]
    P = maps["pos"][mask].astype(np.float32)
    N = maps["nrm"][mask].astype(np.float32)
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-6)
    piece = maps["piece"][mask]
    tag = np.clip(maps["tag"][mask], 0, len(TAGS) - 1)
    ao = np.clip(maps["ao"][mask], 0, 1)
    y = P[:, 1]
    col = np.array([pal[t] for t in TAGS], dtype=np.float32)[tag]
    skin = tag == TAG["skin"]
    mott = fbm(P, 3.0, 3, 21)
    col[skin] *= (0.95 + 0.1 * mott[skin])[:, None]
    bruise = skin & (fbm(P, 9.0, 3, 23) > 0.7)
    col[bruise] = col[bruise] * 0.7 + np.array([0.3, 0.26, 0.33], np.float32) * 0.3
    hair = tag == TAG["hair"]
    col[hair] *= (0.8 + 0.4 * fbm(P[hair] * np.array([1.0, 0.25, 1.0], np.float32), 90.0, 2, 35))[:, None]
    wound = tag == TAG["wound"]
    col[wound] = np.where((fbm(P[wound], 60.0, 2, 37) > 0.55)[:, None], B.BLOOD["light"], B.PALETTE["wound"])
    teeth = tag == TAG["teeth"]
    col[teeth] *= (0.85 + 0.2 * fbm(P[teeth], 140.0, 2, 39))[:, None]
    cloth = np.isin(tag, [TAG[t] for t in CLOTH])
    weave = fbm(P, 14.0, 3, 41)
    col[cloth] *= (0.9 + 0.16 * weave[cloth])[:, None]
    worn = cloth & (fbm(P, 5.0, 3, 43) > 0.68)
    col[worn] = col[worn] * 0.82 + np.array([0.28, 0.25, 0.2], np.float32) * 0.18
    dirt = cloth & (y < 0.5)
    col[dirt] *= (0.78 + 0.22 * np.clip(y[dirt] / 0.5, 0, 1) + 0.08 * (fbm(P[dirt], 20.0, 2, 45) - 0.5))[:, None]
    soak = np.zeros(len(P), np.float32)
    soak = np.where(piece == B.FOREARM, np.clip((1.0 - y) / 0.2, 0, 1) * 1.05, soak)
    soak = np.where(piece == B.SHIN, np.clip((0.07 - y) / 0.07, 0, 1) * 0.7, soak)
    paintable = ~np.isin(tag, [TAG["eye"], TAG["teeth"], TAG["mouth"]])
    col[paintable] = B.blood(P[paintable], N[paintable], col[paintable], B._splats(p)[::OUTFITS[name].get("blood_every", 1)], B._drips(p)[::OUTFITS[name].get("blood_every", 1)], soak[paintable], seed=5)
    col *= (0.66 + 0.34 * ao)[:, None]
    eye = tag == TAG["eye"]
    col[eye] = B.PALETTE["eye"]
    emit = np.zeros_like(col)
    emit[eye] = B.PALETTE["eye"]
    size = mask.shape[0]
    albedo = np.zeros((size, size, 3), np.float32)
    emission = np.zeros((size, size, 3), np.float32)
    albedo[mask] = col
    emission[mask] = emit
    return albedo, emission


# --- Build (Blender) ----------------------------------------------------------------------------------

VIEWS = [
    ("front", (0.0, 1.2, -3.6), (0, 0.98, 0), 50),
    ("three_quarter", (-2.1, 1.55, -2.75), (0, 0.98, 0), 50),
    ("back", (0.4, 1.4, 3.6), (0, 0.98, 0), 50),
]


def build(name, sex, quick, bitten=False, shots=False):
    import pipeline as pl
    parts, p = dress(name, sex)
    mesh, piece_of = combined(parts)
    P, T, tags = mesh.triangles()
    piece_tri = []
    for f, pc in zip(mesh.faces, piece_of):
        piece_tri += [pc] * (len(f) - 2)
    model = f"zombie_{name}_{sex}"
    pl.reset_scene()
    obj = pl.mesh_from_poly(model, P, T, {"piece": piece_tri, "tag": [TAG[t] for t in tags]},
                            weights=[d[0] for d in mesh.vdata], segments=[d[1] for d in mesh.vdata])
    if quick:
        pal = colours(name)
        pl.flat_materials(obj, "tag", [pal[t] for t in TAGS])
    else:
        pl.unwrap(obj, {B.HEAD: 2.0, B.HAIR: 1.1, B.FOREARM: 1.2})
        maps = pl.bake_maps(obj, TEX, (-0.5, -0.05, -0.32), (0.5, 2.1, 0.32), attrs=("piece", "tag"))
        assert maps["tag"][maps["mask"]].max() >= TAG["shirt"], "cloth tags lost in the bake"
        albedo, emission = paint(maps, p, name)
        os.makedirs(OUT, exist_ok=True)
        alb = pl.save_png(albedo, os.path.join(OUT, model + "_albedo.png"), TEX)
        em = pl.save_png(emission, os.path.join(OUT, model + "_emission.png"), TEX)
        pl.textured_material(obj, alb, em)
        arm = pl.add_rig(obj)
        pl.export_glb([obj, arm], os.path.join(OUT, model + ".glb"))
    print(f"built {model}: {len(T)} triangles{' (quick)' if quick else ''}")
    prefix = "model_" + model
    pl.render_views(obj, SHOTS, prefix, VIEWS)
    if bitten and not quick:
        import bites
        only = [int(a.split("=")[1]) for a in sys.argv if a.startswith("--only-bite=")] or None
        bites.build_all(name, sex, obj, maps, albedo, alb, em, shots=shots, only=only)
    return [os.path.join(SHOTS, f"{prefix}_{v[0]}.png") for v in VIEWS]


def main(names, sexes):
    import pipeline as pl
    quick = "--quick" in sys.argv
    shots = []
    for name in names:
        for sex in sexes:
            shots += build(name, sex, quick, "--bitten" in sys.argv, "--bite-shots" in sys.argv)
    pl.contact_sheet(shots, os.path.join(SHOTS, "model_outfits.png"), len(VIEWS) * len(sexes))
    print("previews:", os.path.join(SHOTS, "model_outfits.png"))


# --- Sketch (no Blender) -----------------------------------------------------------------------------

SKETCH_POSES = ["rest", "walk", "attack", "run", "windup", "crawl"]


def _view(pose):
    if pose == "crawl":
        return (-2.6, 1.4, -2.6), (0, 0.35, -0.3)
    if pose == "windup":
        return (-2.6, 1.3, -3.0), (0, 0.65, 0)
    return (-2.4, 1.45, -3.4), (0, 0.95, 0)


def sketch(names, sexes, path_fmt):
    import sketch as sk
    for name in names:
        rows = []
        for sex in sexes:
            parts, p = dress(name, sex)
            mesh, _ = combined(parts)
            P, T, tags = mesh.triangles()
            pal = colours(name)
            cols = np.array([pal[t] for t in tags])
            W = [d[0] for d in mesh.vdata]
            row = []
            for v in [("front", (0.0, 1.15, -4.2), (0, 0.98, 0)), ("side", (4.2, 1.15, 0.0), (0, 0.98, 0)),
                      ("back", (0.5, 1.4, 4.2), (0, 0.98, 0))]:
                row.append(sk.render(P, T, cols, v[1], v[2], focal=4.0))
            for pose in SKETCH_POSES[1:]:
                Q = rig.pose_points(P, W, rig.POSES[pose])
                eye, target = _view(pose)
                row.append(sk.render(Q, T, cols, eye, target, focal=3.6))
            rows.append(row)
            print(f"{name} {sex}: {len(P)} points, {len(T)} triangles")
        path = path_fmt.format(name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        sk.sheet(rows, path)
        print("wrote", path)


# --- Folds (no Blender) -----------------------------------------------------------------------------

def folds(name, sex, poses=SKETCH_POSES[1:] + ["stagger"]):
    """{pose: {bones: count}}: faces of the bent model turned inside out against every bone they
    ride (cloth folded over itself). The outfit material is double-sided, so a fold shows cloth,
    not a hole, but fewer is better: tune clothes.TUNE against this."""
    parts, _ = dress(name, sex)
    mesh, _ = combined(parts)
    P, T, _ = mesh.triangles()
    W = [d[0] for d in mesh.vdata]

    def normals(Q):
        n = np.cross(Q[T[:, 1]] - Q[T[:, 0]], Q[T[:, 2]] - Q[T[:, 0]])
        return n / np.maximum(np.linalg.norm(n, axis=1, keepdims=True), 1e-12)

    n0 = normals(P)
    out = {}
    for pose in poses:
        M = rig.skin_matrices(rig.POSES[pose])
        n1 = normals(rig.pose_points(P, W, rig.POSES[pose]))
        bad = {}
        for f, tri in enumerate(T):
            bones = set().union(*(W[i].keys() for i in tri))
            if len(bones) > 1 and not any(n1[f] @ (M[b][0] @ n0[f]) > 0.0 for b in bones):
                key = "+".join(sorted(bones))
                bad[key] = bad.get(key, 0) + 1
        out[pose] = bad
    return out


if __name__ == "__main__":
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    names = [a for a in argv if a in OUTFITS] or NAMES
    sexes = [s for s in ("m", "f") if "--" + s in argv] or ["m", "f"]
    if "--sketch" in argv:
        sketch(names, sexes, os.path.join(SHOTS, "sketch_outfit_{}.png"))
    elif "--bites" in argv:
        import bites
        for name in names:
            bites.sketch(name, sexes, os.path.join(SHOTS, "bites_{}_{}.png"))
    elif "--folds" in argv:
        for name in names:
            for sex in sexes:
                res = folds(name, sex)
                print(f"{name} {sex}: " + ", ".join(f"{pose} {sum(b.values())}" for pose, b in res.items()))
    else:
        main(names, sexes)
