"""Elements: props, building parts, vehicles and guns, made the way the characters are. Python
geometry (tools/models/poly.py) in a family file `tools/models/props/<family>.py`, baked and
exported by Blender into `assets/models/props/`; never edit those files by hand.

    tools\\blender.ps1 tools\\models\\props.py hydrant          -> assets/models/props/hydrant.glb, .json,
                                                               hydrant_<state>.png per state, hydrant_wear.png
    tools\\blender.ps1 tools\\models\\props.py hydrant --quick  -> shapes only, flat colours, previews
    python tools/models/props.py hydrant --sketch              -> references/shots/sketch_hydrant.png in seconds,
                                                               no Blender (for shaping)
    python tools/models/props.py --list                        -> every element of every family

A family file says `ELEMENTS = {"name": spec}`, a spec being a dict:
    build(lod) -> {part name: Part}   the element at LOD 0, 1, 2... (fewer sides, fewer details);
                                       LOD 0 keeps its parts apart, the others are one mesh
    materials  {tag: Material}         what each face tag is painted as
    states     ["clean", ...]           one albedo each (clean, abandoned, damaged, burnt)
    lods       number of LODs
    extra(maps, state, col) -> col     optional: lettering and anything else painted by position

The first part is the fixed body; the others move (`Part.motion`): {"rotate": [axis, degrees]}
about the part's pivot, or {"move": [x, y, z]}. Game coordinates: metres, Y up, facing -Z,
standing on y = 0.
"""
import importlib.util
import json
import os
import sys
from dataclasses import dataclass, field

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np  # noqa: E402

from poly import Mesh  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FAMILIES = os.path.join(os.path.dirname(os.path.abspath(__file__)), "props")
OUT = os.path.join(ROOT, "assets", "models", "props")
SHOTS = os.path.join(ROOT, "references", "shots")
TEX = 1024
STATES = ["clean", "abandoned", "damaged", "burnt"]


@dataclass
class Material:
    """How a tag is painted. `paint` the top coat, `under` the primer a chip shows, `bare` the
    metal or wood under that (rust grows from it when `rusts`), `chip` how readily its edges chip
    (0 never: glass, rubber), `emit` a glow colour for anything lit."""
    paint: tuple
    under: tuple = (0.50, 0.33, 0.20)
    bare: tuple = (0.20, 0.19, 0.18)
    chip: float = 1.0
    rusts: bool = True
    grain: float = 0.08
    emit: tuple = None


@dataclass
class Part:
    mesh: Mesh
    pivot: tuple = (0.0, 0.0, 0.0)
    motion: dict = field(default_factory=dict)


# --- Shapes (the detail kit, S141, grows these) ---------------------------------------------------

def lathe(profile, sides, flute=None, turn=0.0, tag="paint", caps=(True, True)):
    """A body of revolution round +Y: `profile` = [(y, r) or (y, r, tag of the band above)], from
    the bottom up; a radius of 0 is a tip. `flute(j, y)` may scale point j's radius at height y
    (grooves, ribs). Returns a Mesh."""
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
    a = np.asarray(axis, dtype=np.float64)
    a /= np.linalg.norm(a)
    ref = np.array([0.0, 1.0, 0.0]) if abs(a[1]) < 0.9 else np.array([1.0, 0.0, 0.0])
    x = np.cross(ref, a)
    x /= np.linalg.norm(x)
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


# --- Families --------------------------------------------------------------------------------------

def families():
    """{family name: module} for every file in tools/models/props/."""
    out = {}
    for fn in sorted(os.listdir(FAMILIES)):
        if fn.endswith(".py") and not fn.startswith("_"):
            spec = importlib.util.spec_from_file_location("family_" + fn[:-3], os.path.join(FAMILIES, fn))
            mod = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(mod)
            out[fn[:-3]] = mod
    return out


def find(name):
    for fam, mod in families().items():
        if name in mod.ELEMENTS:
            return fam, mod.ELEMENTS[name]
    raise SystemExit(f"no element called {name}; python tools/models/props.py --list")


def merged(parts, placed=True):
    """All parts as one Mesh, a face attribute each: tags and part numbers."""
    m = Mesh()
    part_of = []
    for i, part in enumerate(parts.values()):
        before = len(m.faces)
        m.merge(part.mesh)
        part_of += [i] * (len(m.faces) - before)
    return m, part_of


def size_of(parts):
    P = np.array(merged(parts)[0].verts)
    return P.max(0) - P.min(0), P.min(0), P.max(0)


# --- Painting --------------------------------------------------------------------------------------

def _mix(a, b, t):
    return a * (1 - t[:, None]) + b * t[:, None]


def paint(maps, spec, state):
    """Albedo (sRGB) for every texel the bake reached, in one state: the materials' coats chipped
    at the edges, dirt at the foot and in the cavities, rust running down from bare metal, moss
    on shaded faces, bullet pocks, soot. Deterministic: noise seeded by position."""
    from noise import fbm
    mats = spec["materials"]
    tags = list(mats)
    mask = maps["mask"]
    P = maps["pos"][mask].astype(np.float32)
    N = maps["nrm"][mask].astype(np.float32)
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-6)
    tag = np.clip(maps["tag"][mask], 0, len(tags) - 1)
    ao = np.clip(maps["ao"][mask], 0, 1)
    edge = np.clip(maps["edge"][mask], 0, 1)
    y = P[:, 1]
    M = [mats[t] for t in tags]
    coat = np.array([m.paint for m in M], np.float32)[tag]
    under = np.array([m.under for m in M], np.float32)[tag]
    bare = np.array([m.bare for m in M], np.float32)[tag]
    chip_k = np.array([m.chip for m in M], np.float32)[tag]
    rusts = np.array([m.rusts for m in M])[tag]
    grain = np.array([m.grain for m in M], np.float32)[tag]
    wear = {"clean": 0.15, "abandoned": 0.55, "damaged": 0.85, "burnt": 0.7}[state]
    # The coat: a little uneven, faded on what faces the sky.
    col = coat * (1 - grain[:, None] + 2 * grain[:, None] * fbm(P, 9.0, 3, 3)[:, None])
    sky = np.clip(N[:, 1], 0, 1)
    if state != "clean":  # sun-faded: paler and pinker, most on top
        col = _mix(col, col * 0.55 + np.array([0.33, 0.24, 0.22], np.float32), np.clip(0.55 * wear + 0.4 * wear * sky, 0, 1))
    # Chips: at the edges first, then in patches as the years go; through to the primer, and in
    # the middle of a patch to the bare stuff.
    patch = fbm(P, 14.0, 4, 7)
    edge_n = edge + 0.35 * (fbm(P, 70.0, 2, 9) - 0.5)
    patches = (patch - (0.74 - 0.22 * wear)) * 2.0 if wear > 0.3 else np.full(len(P), -1.0, np.float32)
    chipped = np.maximum(edge_n - (0.8 - 0.45 * wear), patches) * chip_k
    col = np.where((chipped > 0)[:, None], under * (0.9 + 0.2 * fbm(P, 50.0, 2, 8))[:, None], col)
    deep = chipped > 0.3
    col = np.where(deep[:, None], bare, col)
    # Rust on the bare metal and running down below it.
    if state != "clean":
        rust = np.array([0.34, 0.16, 0.07], np.float32)
        streak = fbm(P * np.array([1.0, 0.12, 1.0], np.float32), 55.0, 3, 11)
        runs = rusts & (streak > 0.72 - 0.12 * wear) & (fbm(P, 6.0, 2, 13) > 0.45)
        col = np.where((rusts & deep)[:, None], _mix(bare, rust, np.full(len(P), 0.7, np.float32)), col)
        col = _mix(col, rust, runs * 0.55 * wear)
    # Grime in the cavities and dirt splashed up from the ground.
    grime = np.clip((1 - ao) * 1.4, 0, 1) * (0.25 + 0.6 * wear)
    col = _mix(col, np.array([0.17, 0.15, 0.12], np.float32), grime * 0.6)
    foot = np.clip(1 - y / (0.12 + 0.25 * wear), 0, 1) * (0.5 + 0.5 * fbm(P, 30.0, 3, 17))
    col = _mix(col, np.array([0.30, 0.26, 0.21], np.float32), foot * (0.35 + 0.4 * wear))
    if state == "abandoned":
        shade = np.clip(-N[:, 1] * 0.5 + 0.5, 0, 1) * np.clip(1 - y / 0.5, 0, 1)
        moss = (fbm(P, 14.0, 3, 19) * shade * (1 - ao * 0.3)) > 0.3
        col = np.where(moss[:, None], np.array([0.20, 0.25, 0.10], np.float32) * (0.8 + 0.3 * fbm(P, 60.0, 2, 21))[:, None], col)
    if state == "damaged":
        # Bullet pocks: a dark hole with a bright ring of bare metal, seeded by position.
        cell = np.floor(P / 0.05)
        h = np.sin(cell @ np.array([12.9898, 78.233, 37.719], np.float32)) * 43758.5453
        h = h - np.floor(h)
        centre = (cell + 0.5) * 0.05
        d = np.linalg.norm(P - centre, axis=1)
        hit = h > 0.7
        col = np.where((hit & (d < 0.013))[:, None], bare * 0.9 + 0.15, col)
        col = np.where((hit & (d < 0.007))[:, None], np.array([0.05, 0.05, 0.05], np.float32), col)
    if state == "burnt":
        # Soot climbing from the foot, the coat blistered and burnt off, ash on top.
        soot = np.clip(1.25 - y / max(float(P[:, 1].max()), 0.3) + 0.3 * fbm(P, 8.0, 3, 23), 0, 1)
        col = _mix(col, np.array([0.06, 0.05, 0.05], np.float32), soot * 0.85)
        blister = fbm(P, 90.0, 2, 29) > 0.62
        col = np.where(blister[:, None], col * 0.6, col)
        col = _mix(col, np.array([0.42, 0.40, 0.37], np.float32), sky * (fbm(P, 25.0, 3, 31) > 0.55) * 0.6)
    if "extra" in spec:
        col = spec["extra"](P, N, tag, tags, state, col)
    col *= (0.55 + 0.45 * ao)[:, None]
    size = mask.shape[0]
    albedo = np.zeros((size, size, 3), np.float32)
    albedo[mask] = np.clip(col, 0, 1)
    return albedo


def wear_mask(maps):
    """R edges, G cavities, B what faces the sky: for anything painted later in the game."""
    mask = maps["mask"]
    out = np.zeros(mask.shape + (3,), np.float32)
    out[..., 0] = np.clip(maps["edge"], 0, 1)
    out[..., 1] = np.clip(1 - maps["ao"], 0, 1)
    out[..., 2] = np.clip(maps["nrm"][..., 1], 0, 1)
    out[~mask] = 0
    return out


# --- Blender ---------------------------------------------------------------------------------------

def _part_object(pl, name, part, tags):
    P, T, ftags = part.mesh.triangles()
    obj = pl.mesh_from_poly(name, P, T, {"tag": [tags.index(t) for t in ftags]})
    return obj


def build(name, quick=False):
    import bpy
    import pipeline as pl
    fam, spec = find(name)
    tags = list(spec["materials"])
    pl.reset_scene()
    parts = spec["build"](0)
    size, lo, hi = size_of(parts)
    objs = []
    for i, (pname, part) in enumerate(parts.items()):
        o = _part_object(pl, f"src_{pname}", part, tags)
        n = len(o.data.polygons)
        a = o.data.attributes.new("part", "FLOAT", "FACE")
        a.data.foreach_set("value", np.full(n, i, np.float32))
        objs.append(o)
    whole = pl.join(objs, "whole")
    tris = [len(whole.data.polygons)]
    os.makedirs(OUT, exist_ok=True)
    meta = {"name": name, "family": fam, "size": [float(v) for v in size], "min": [float(v) for v in lo],
            "states": spec["states"], "parts": {}, "tris": [], "emission": False}
    if quick:
        pl.flat_materials(whole, "tag", [spec["materials"][t].paint for t in tags])
    else:
        pl.unwrap(whole, margin=0.006)
        pad = np.array([0.02, 0.02, 0.02])
        maps = pl.bake_maps(whole, TEX, lo - pad, hi + pad, attrs=("tag",))
        maps["edge"] = pl.bake_edges(whole, TEX, radius=spec.get("edge_radius", 0.006))
        for state in spec["states"]:
            pl.save_png(paint(maps, spec, state), os.path.join(OUT, f"{name}_{state}.png"), TEX)
        pl.save_png(wear_mask(maps), os.path.join(OUT, f"{name}_wear.png"), TEX)
        emits = [t for t in tags if spec["materials"][t].emit]
        if emits:
            em = np.zeros((TEX, TEX, 3), np.float32)
            for t in emits:
                em[maps["mask"] & (maps["tag"] == tags.index(t))] = spec["materials"][t].emit
            pl.save_png(em, os.path.join(OUT, f"{name}_emission.png"), TEX)
            meta["emission"] = True
    # LOD 0: the parts apart again, each object's origin on its pivot.
    lod_objs = []
    for i, (pname, part) in enumerate(parts.items()):
        o = pl.split_by_attr(whole, "part", i, f"lod0_{pname}")
        pl.set_origin(o, part.pivot)
        lod_objs.append(o)
        meta["parts"][pname] = {"pivot": [float(v) for v in part.pivot], **part.motion}
    # LOD 1..: one mesh each, the texture's UVs taken from LOD 0's nearest face.
    for lod in range(1, spec["lods"]):
        m, _ = merged(spec["build"](lod))
        P, T, ftags = m.triangles()
        o = pl.mesh_from_poly(f"lod{lod}", P, T, {"tag": [tags.index(t) for t in ftags]})
        if not quick:
            pl.transfer_uvs(whole, o)
        else:
            pl.flat_materials(o, "tag", [spec["materials"][t].paint for t in tags])
        tris.append(len(o.data.polygons))
        lod_objs.append(o)
    meta["tris"] = tris
    if not quick:
        pl.export_glb(lod_objs, os.path.join(OUT, name + ".glb"))
        with open(os.path.join(OUT, name + ".json"), "w") as f:
            json.dump(meta, f, indent=1)
    print(f"built {name}: triangles per LOD {tris}, size {np.round(size, 3).tolist()}{' (quick)' if quick else ''}")
    bpy.data.objects.remove(whole)
    return meta


def main():
    args = [a for a in sys.argv[sys.argv.index("--") + 1:]] if "--" in sys.argv else sys.argv[1:]
    names = [a for a in args if not a.startswith("--")]
    for n in names:
        build(n, "--quick" in args)


# --- Sketch (no Blender) ---------------------------------------------------------------------------

def sketch_views(size, lo, hi):
    """Eight angles round the element and one close look, framed by its size."""
    c = (lo + hi) / 2
    r = float(max(size[0], size[2], size[1])) * 1.45 + 0.15
    out = []
    for k in range(8):
        a = np.pi * k / 4
        out.append((np.array([np.sin(a) * -r, c[1] + r * 0.3, np.cos(a) * -r]), c, 2.0))
    return out


def sketch(name):
    import sketch as sk
    _, spec = find(name)
    rows = []
    for lod in range(spec["lods"]):
        parts = spec["build"](lod)
        size, lo, hi = size_of(parts)
        m, _ = merged(parts)
        P, T, ftags = m.triangles()
        cols = np.array([spec["materials"][t].paint for t in ftags], np.float64)
        views = sketch_views(size, lo, hi) if lod == 0 else sketch_views(size, lo, hi)[:3]
        rows.append([sk.render(P, T, cols, eye, tgt, size=(360, 480), focal=f) for eye, tgt, f in views[:4]])
        if lod == 0:
            rows.append([sk.render(P, T, cols, eye, tgt, size=(360, 480), focal=f) for eye, tgt, f in views[4:]])
            opened = {k: _opened(p) for k, p in parts.items()}
            m2, _ = merged(opened)
            P2, T2, t2 = m2.triangles()
            c2 = np.array([spec["materials"][t].paint for t in t2], np.float64)
            rows.append([sk.render(P2, T2, c2, eye, tgt, size=(360, 480), focal=f) for eye, tgt, f in views[:4]])
        print(f"{name} LOD{lod}: {len(T)} triangles, size {np.round(size, 3).tolist()}")
    os.makedirs(SHOTS, exist_ok=True)
    path = os.path.join(SHOTS, f"sketch_{name}.png")
    sk.sheet(rows, path)
    print("wrote", path)


def _opened(part):
    """The part moved fully open (for the sketch)."""
    if not part.motion:
        return part
    piv = np.asarray(part.pivot, np.float64)
    if "rotate" in part.motion:
        axis, deg = part.motion["rotate"]
        a = np.asarray(axis, np.float64)
        a /= np.linalg.norm(a)
        t = np.radians(deg)
        K = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
        R = np.eye(3) + np.sin(t) * K + (1 - np.cos(t)) * K @ K
        m = part.mesh.copy()
        m.verts = [R @ (v - piv) + piv for v in m.verts]
    else:
        m = part.mesh.copy()
        m.verts = [v + np.asarray(part.motion["move"], np.float64) for v in m.verts]
    return Part(m, part.pivot, part.motion)


if __name__ == "__main__":
    if "--list" in sys.argv:
        for fam, mod in families().items():
            print(fam + ":", ", ".join(mod.ELEMENTS))
    elif "--sketch" in sys.argv:
        for n in [a for a in sys.argv[1:] if not a.startswith("--")]:
            sketch(n)
    else:
        main()


# --- Lettering (a 5 x 7 stencil; the detail kit, S141, grows it into fonts) -------------------------

GLYPHS = {
    "0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
    "1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
    "2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
    "3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
    "4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
    "5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
    "6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
    "7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
    "8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
    "9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
    "A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
    "E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
    "N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
    "R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
    "V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
    "Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
    " ": ["00000"] * 7,
}


def letters(P, text, centre, height, right=(1.0, 0.0, 0.0), up=(0.0, 1.0, 0.0)):
    """Which points lie on `text` written at `centre`, `height` tall, along `right` and `up`
    (a flat projection: give a mask of the faces it may land on as well)."""
    right, up = np.asarray(right, np.float32), np.asarray(up, np.float32)
    cell = height / 7.0
    width = (len(text) * 6 - 1) * cell
    rel = P - np.asarray(centre, np.float32)
    u = (rel @ right + width / 2) / cell
    v = (height / 2 - rel @ up) / cell
    out = np.zeros(len(P), bool)
    inside = (u >= 0) & (u < len(text) * 6) & (v >= 0) & (v < 7)
    gi = np.floor(u / 6).astype(int)
    cx = np.floor(u).astype(int) % 6
    cy = np.floor(v).astype(int)
    for i, ch in enumerate(text):
        g = GLYPHS[ch]
        sel = inside & (gi == i) & (cx < 5)
        idx = np.nonzero(sel)[0]
        out[idx] = [g[cy[k]][cx[k]] == "1" for k in idx]
    return out
