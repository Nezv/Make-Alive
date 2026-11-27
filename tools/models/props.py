"""Elements: props, building parts, vehicles and guns, made the way the characters are. Python
geometry (tools/models/poly.py) in a family file `tools/models/props/<family>.py`, baked and
exported by Blender into `assets/models/props/`; never edit those files by hand.

    tools\\blender.ps1 tools\\models\\props.py hydrant          -> assets/models/props/hydrant.glb, .json,
                                                               hydrant_<state>.png per state, hydrant_wear.png
    tools\\blender.ps1 tools\\models\\props.py hydrant --quick  -> shapes only, flat colours, previews
    python tools/models/props.py hydrant --sketch              -> references/shots/sketch_hydrant.png in seconds,
                                                               no Blender (for shaping)
    python tools/models/props.py --list                        -> every element of every family
    python tools/models/props.py kit --json                    -> rewrite only the .json's samples and views

A family file says `ELEMENTS = {"name": spec}`, a spec being a dict:
    build(lod) -> {part name: Part}   the element at LOD 0, 1, 2... (fewer sides, fewer details);
                                       LOD 0 keeps its parts apart, the others are one mesh
    materials  {tag: Material}         what each face tag is painted as
    states     ["clean", ...]           one albedo each (clean, abandoned, damaged, burnt)
    lods       number of LODs
    extra(maps, state, col) -> col     optional: lettering and anything else painted by position
    emit_where(P, N, tag, tags) -> bool optional: which texels of the lit tags glow (default all)

The first part is the fixed body; the others move (`Part.motion`): {"roll": fraction} gathers the part up into its pivot (a roller shutter's curtain into its box), {"rotate": [axis, degrees]}
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
    (0 never: glass, rubber, bare stone), `emit` a glow colour for anything lit.
    The kit (S141): `kind` says how it wears and burns (metal, wood, masonry, stone, plaster,
    concrete, clay, glass, paper, rubber, sand); `pattern(P, N) -> (colour, joint, unit)` paints it
    instead of a flat coat (surfaces.Bond, BoardFormed, Plaster); `palette` picks a colour per unit
    and `vary` shades each unit (setts, tiles); `fixing` marks bolts and nails rust runs hang
    from; `sheds` whether water runs off its ledges; `fades` whether the sun fades it (default:
    painted things)."""
    paint: tuple
    under: tuple = (0.50, 0.33, 0.20)
    bare: tuple = (0.20, 0.19, 0.18)
    chip: float = 1.0
    rusts: bool = True
    grain: float = 0.08
    emit: tuple = None
    kind: str = "metal"
    pattern: object = None
    palette: list = None
    vary: float = 0.0
    fixing: bool = False
    sheds: bool = True
    fades: bool = None
    speckle: float = 0.0

    def __post_init__(self):
        if self.fades is None:
            self.fades = self.chip > 0 and self.kind in ("metal", "wood")


@dataclass
class Part:
    mesh: Mesh
    pivot: tuple = (0.0, 0.0, 0.0)
    motion: dict = field(default_factory=dict)


# --- Shapes: the detail kit (S141) -----------------------------------------------------------------
# Family files use `from props import lathe, along, prism` or the kit modules directly.
from shapes import lathe, along, prism  # noqa: E402,F401


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

def paint(maps, spec, state):
    """Albedo (sRGB) for every texel the bake reached, in one state, from the kit's layers
    (tools/models/wear.py): the materials' coats or patterns, plaster fallen off, sun fade, chips,
    rust and its runs, water stains, grime and dirt, moss, decals, the family's own `extra`
    (lettering), bullet pocks, cracked glass, the burnt version; then the baked AO. Deterministic:
    noise seeded by position."""
    import wear as W
    c = W.Ctx(maps, spec, state)
    col = W.base(c)
    col = W.plaster_fall(c, col)
    col = W.fade(c, col)
    col, deep = W.chips(c, col)
    col = W.rust(c, col, deep)
    col = W.water(c, col)
    col = W.grime(c, col)
    col = W.moss(c, col)
    col = W.decals(c, col)
    late = not spec.get("extra_first")  # the hydrant paints its lettering over the damage
    if "extra" in spec and not late:
        col = spec["extra"](c.P, c.N, c.tag, c.tags, state, col)
    col = W.pocks(c, col)
    col = W.glass_cracks(c, col)
    col = W.burnt(c, col)
    if "extra" in spec and late:
        col = spec["extra"](c.P, c.N, c.tag, c.tags, state, col)
    col *= (0.55 + 0.45 * c.ao)[:, None]
    mask = maps["mask"]
    size = mask.shape[0]
    albedo = np.zeros((size, size, 3), np.float32)
    albedo[mask] = np.clip(col, 0, 1)
    return albedo


def check_normals(maps):
    """The baked normal must point out of the model in game coordinates: the topmost texels face
    up, the frontmost face -Z (S140 left this open; the painters rely on it for sky and facing)."""
    mask = maps["mask"]
    P, N = maps["pos"][mask], maps["nrm"][mask]
    top = P[:, 1] > P[:, 1].max() - 0.003
    front = P[:, 2] < P[:, 2].min() + 0.003
    up, fw = float(N[top, 1].mean()), float(N[front, 2].mean())
    print(f"normal check: top texels' mean N.y {up:.2f}, front texels' mean N.z {fw:.2f}")
    if up < 0.3 or fw > -0.3:
        raise SystemExit("baked normals point the wrong way (see pipeline.bake_maps)")


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
    obj = pl.mesh_from_poly(name, P, T, {"tag": [tags.index(t) for t in ftags], "unit": part.mesh.triangle_units()})
    return obj


def _parts_apart(obj, n, step):
    """For the AO bake: every moving part moved `step` metres away from the body and from each
    other, then back. Baked at rest, a closed shutter's back and a cap's inside would be dark
    with the wall and the body they touch, and show dark once open."""
    me = obj.data
    part = np.empty(len(me.polygons), np.float32)
    me.attributes["part"].data.foreach_get("value", part)
    of_vert = np.zeros(len(me.vertices), np.int32)
    for poly, p in zip(me.polygons, part):
        of_vert[list(poly.vertices)] = int(round(p))
    co = np.empty(len(me.vertices) * 3, np.float32)
    me.vertices.foreach_get("co", co)
    rest = co.copy()
    moved = co.reshape(-1, 3).copy()
    moved[:, 0] += of_vert * step  # along Blender's X (the game's X)

    def around(before):
        me.vertices.foreach_set("co", moved.ravel() if before else rest)
        me.update()
    return around


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
    if "close" in spec:  # where the rack's 1 m close-up looks (default: the head of a post, the middle of a tall thing)
        meta["close"] = [float(v) for v in spec["close"]]
    for key in ("samples", "views"):  # the kit's board: where each sample stands, its close-ups
        if key in spec:
            meta[key] = spec[key]() if callable(spec[key]) else spec[key]
    tex = spec.get("tex", TEX)
    if quick:
        pl.flat_materials(whole, "tag", [spec["materials"][t].paint for t in tags])
    else:
        # more texture for what carries lettering or fine detail (`uv_scale`: {tag: factor})
        scale = {tags.index(t): k for t, k in spec.get("uv_scale", {}).items()}
        if scale:
            a = whole.data.attributes["tag"]
            v = np.empty(len(whole.data.polygons), np.float32)
            a.data.foreach_get("value", v)
            p = whole.data.attributes.get("piece") or whole.data.attributes.new("piece", "FLOAT", "FACE")
            p.data.foreach_set("value", v)
        pl.unwrap(whole, scale or None, margin=spec.get("uv_margin", 0.006))
        pad = np.array([0.02, 0.02, 0.02])
        apart = _parts_apart(whole, len(parts), float(max(size)) * 3 + 1) if len(parts) > 1 and spec.get("ao_apart", True) else None
        maps = pl.bake_maps(whole, tex, lo - pad, hi + pad, attrs=("tag", "unit"), around_ao=apart)
        check_normals(maps)
        maps["edge"] = pl.bake_edges(whole, tex, radius=spec.get("edge_radius", 0.006))
        for state in spec["states"]:
            pl.save_png(paint(maps, spec, state), os.path.join(OUT, f"{name}_{state}.png"), tex)
        pl.save_png(wear_mask(maps), os.path.join(OUT, f"{name}_wear.png"), tex)
        emits = [t for t in tags if spec["materials"][t].emit]
        if emits:
            em = np.zeros((tex, tex, 3), np.float32)
            for t in emits:
                em[maps["mask"] & (maps["tag"] == tags.index(t))] = spec["materials"][t].emit
            if "emit_where" in spec:  # only part of a lit tag glows (an LED board's letters)
                msk = maps["mask"]
                keep = spec["emit_where"](maps["pos"][msk], maps["nrm"][msk], maps["tag"][msk], tags)
                flat = em[msk]
                flat[~keep] = 0.0
                em[msk] = flat
            pl.save_png(em, os.path.join(OUT, f"{name}_emission.png"), tex)
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
        cols = _sketch_colours(spec, ftags, m.triangle_units())
        views = sketch_views(size, lo, hi) if lod == 0 else sketch_views(size, lo, hi)[:3]
        rows.append([sk.render(P, T, cols, eye, tgt, size=(360, 480), focal=f) for eye, tgt, f in views[:4]])
        if lod == 0:
            rows.append([sk.render(P, T, cols, eye, tgt, size=(360, 480), focal=f) for eye, tgt, f in views[4:]])
            opened = {k: _opened(p) for k, p in parts.items()}
            m2, _ = merged(opened)
            P2, T2, t2 = m2.triangles()
            c2 = np.array([spec["materials"][t].paint for t in t2], np.float64)
            rows.append([sk.render(P2, T2, c2, eye, tgt, size=(360, 480), focal=f) for eye, tgt, f in views[:4]])
        if lod == 0 and "views" in spec:  # an element with close-ups of its own (the kit's board)
            vs = spec["views"]() if callable(spec["views"]) else spec["views"]
            shots = [sk.render(P, T, cols, np.array(v["eye"]), np.array(v["at"]), size=(480, 300),
                               focal=1.0 / np.tan(np.radians(v["fov"]) / 2)) for v in vs]
            vpath = os.path.join(SHOTS, f"sketch_{name}_views.png")
            sk.sheet([shots[i:i + 3] for i in range(0, len(shots), 3)], vpath)
            print("wrote", vpath)
        print(f"{name} LOD{lod}: {len(T)} triangles, size {np.round(size, 3).tolist()}")
    os.makedirs(SHOTS, exist_ok=True)
    path = os.path.join(SHOTS, f"sketch_{name}.png")
    sk.sheet(rows, path)
    print("wrote", path)


def _sketch_colours(spec, ftags, units):
    """A flat colour per triangle: its material's, or its unit's from the material's palette."""
    out = []
    for t, u in zip(ftags, units):
        m = spec["materials"][t]
        if m.palette:
            out.append(m.palette[(u * 7919) % len(m.palette)])
        else:
            out.append(m.paint)
    return np.array(out, np.float64)


def _opened(part, amount=1.0):
    """The part moved open (fully, or by `amount` 0..1; for the sketch and match.py)."""
    if not part.motion or amount == 0:
        return part
    piv = np.asarray(part.pivot, np.float64)
    if "rotate" in part.motion:
        axis, deg = part.motion["rotate"]
        a = np.asarray(axis, np.float64)
        a /= np.linalg.norm(a)
        t = np.radians(deg) * amount
        K = np.array([[0, -a[2], a[1]], [a[2], 0, -a[0]], [-a[1], a[0], 0]])
        R = np.eye(3) + np.sin(t) * K + (1 - np.cos(t)) * K @ K
        m = part.mesh.copy()
        m.verts = [R @ (v - piv) + piv for v in m.verts]
    elif "roll" in part.motion:  # gathered up into the pivot: a roller shutter into its box
        k = 1.0 - float(part.motion["roll"]) * amount
        m = part.mesh.copy()
        m.verts = [np.array([v[0], piv[1] + (v[1] - piv[1]) * k, v[2]]) for v in m.verts]
    else:
        m = part.mesh.copy()
        m.verts = [v + np.asarray(part.motion["move"], np.float64) * amount for v in m.verts]
    return Part(m, part.pivot, part.motion)


if __name__ == "__main__":
    if "--list" in sys.argv:
        for fam, mod in families().items():
            print(fam + ":", ", ".join(mod.ELEMENTS))
    elif "--json" in sys.argv:  # only the board's samples and views changed: no Blender needed
        for n in [a for a in sys.argv[1:] if not a.startswith("--")]:
            _, spec = find(n)
            path = os.path.join(OUT, n + ".json")
            meta = json.load(open(path))
            for key in ("samples", "views"):
                if key in spec:
                    meta[key] = spec[key]() if callable(spec[key]) else spec[key]
            json.dump(meta, open(path, "w"), indent=1)
            print("updated", path)
    elif "--sketch" in sys.argv:
        for n in [a for a in sys.argv[1:] if not a.startswith("--")]:
            sketch(n)
    else:
        main()


# --- Lettering: the kit's stroke fonts (tools/models/lettering.py) ---------------------------------

def letters(P, text, centre, height, right=(1.0, 0.0, 0.0), up=(0.0, 1.0, 0.0), font="block", **kw):
    """Which points lie on `text` written at `centre`, `height` tall (cap height), along `right`
    and `up` (a flat projection: give a mask of the faces it may land on as well)."""
    import lettering
    return lettering.mask(P, text, centre, height, right, up, font, **kw)
