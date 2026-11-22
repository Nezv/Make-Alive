"""Blender side of the character pipeline: low-poly meshes (tools/models/poly.py) -> one mesh with
a painted texture and the game's skeleton -> .glb. Run through tools\blender.ps1.

Coordinates: everything is given in the game's frame (Y up, the model faces -Z). Blender is
Z up; the glTF exporter turns Blender (x, y, z) into (x, z, -y), so a game point (x, y, z) is
put in Blender at (x, -z, y) and comes out of the .glb exactly where the game expects it.
"""
import math
import os

import bmesh
import bpy
import numpy as np

from rig import BONES  # noqa: F401  the game's joints and the clothes' helper bones

# The game's rigid pieces (CharacterModel.SEGMENT_IDS), in order: a model may say which one each
# point goes with (its second UV channel, u = (id + 0.5) / 16).
SEGMENTS = ["torso", "head", "upper_arm_l", "forearm_l", "upper_arm_r", "forearm_r", "thigh_l", "shin_l",
            "thigh_r", "shin_r"]


def g2b(p):
    return (p[0], -p[2], p[1])


def b2g_array(a):
    """(N, 3) Blender coordinates -> game coordinates."""
    return np.stack([a[:, 0], a[:, 2], -a[:, 1]], -1)


def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def _select_only(obj):
    for o in bpy.context.view_layer.objects:
        o.select_set(False)
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj


# --- Geometry ------------------------------------------------------------------------------

def mesh_from_poly(name, points, triangles, face_attrs, weights=None, segments=None):
    """A mesh object straight from triangles in game coordinates (tools/models/poly.py), flat
    shaded, its faces turned outward. `face_attrs` = {name: value or one value per triangle},
    stored as FACE float attributes (survive joining; bake_maps can bake them). `weights`: one
    {bone: weight} per point (vertex groups); `segments`: one rigid piece name per point (the
    "seg" UV channel, after the texture's "UVMap")."""
    P = np.asarray(points, dtype=np.float64)
    bv = np.stack([P[:, 0], -P[:, 2], P[:, 1]], -1)
    me = bpy.data.meshes.new(name)
    me.from_pydata(bv.tolist(), [], np.asarray(triangles).tolist())
    me.validate()
    obj = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(obj)
    bm = bmesh.new()
    bm.from_mesh(me)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me)
    bm.free()
    n = len(me.polygons)
    for key, value in face_attrs.items():
        vals = np.broadcast_to(np.asarray(value, dtype=np.float32), (n,)).copy()
        attr = me.attributes.get(key) or me.attributes.new(key, "FLOAT", "FACE")
        attr.data.foreach_set("value", vals)
    me.shade_flat()
    if weights is not None:
        groups = {}
        for vi, w in enumerate(weights):
            for bone, v in w.items():
                if v > 1e-4:
                    groups.setdefault(bone, {}).setdefault(round(float(v), 4), []).append(vi)
        for bone, levels in groups.items():
            vg = obj.vertex_groups.get(bone) or obj.vertex_groups.new(name=bone)
            for v, idx in levels.items():
                vg.add(idx, v, "REPLACE")
    if segments is not None:
        if "UVMap" not in me.uv_layers:
            me.uv_layers.new(name="UVMap")
        seg = me.uv_layers.new(name="seg")
        ids = np.array([SEGMENTS.index(s) for s in segments], dtype=np.float32)
        loops = np.empty(len(me.loops), dtype=np.int32)
        me.loops.foreach_get("vertex_index", loops)
        uv = np.zeros((len(loops), 2), dtype=np.float32)
        uv[:, 0] = (ids[loops] + 0.5) / 16.0
        uv[:, 1] = 0.5
        seg.data.foreach_set("uv", uv.ravel())
        me.uv_layers.active = me.uv_layers["UVMap"]
        me.uv_layers["UVMap"].active_render = True
    return obj


def join(objs, name):
    _select_only(objs[0])
    for o in objs[1:]:
        o.select_set(True)
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    obj.name = name
    obj.data.name = name
    return obj


def vertex_arrays(obj):
    """(positions in game coordinates, piece of each vertex)."""
    me = obj.data
    co = np.empty(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    P = b2g_array(co.reshape(-1, 3))
    piece_f = np.empty(len(me.polygons), dtype=np.float32)
    me.attributes["piece"].data.foreach_get("value", piece_f)
    piece_v = np.zeros(len(me.vertices), dtype=np.float32)
    for poly in me.polygons:
        for vi in poly.vertices:
            piece_v[vi] = piece_f[poly.index]
    return P, piece_v


# --- UVs -----------------------------------------------------------------------------------

def unwrap(obj, scale_by_piece=None, margin=0.004):
    """Smart-project UVs, give some pieces more texture (the face), pack into the square."""
    _select_only(obj)
    me = obj.data
    if "UVMap" not in me.uv_layers:
        me.uv_layers.new(name="UVMap")
    me.uv_layers.active = me.uv_layers["UVMap"]
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin, area_weight=0.0,
        correct_aspect=True, scale_to_bounds=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    if scale_by_piece:
        piece_f = np.empty(len(me.polygons), dtype=np.float32)
        me.attributes["piece"].data.foreach_get("value", piece_f)
        uv = me.uv_layers.active.data
        for poly in me.polygons:
            s = scale_by_piece.get(int(round(piece_f[poly.index])), 1.0)
            if s != 1.0:
                for li in poly.loop_indices:
                    uv[li].uv = (uv[li].uv[0] * s, uv[li].uv[1] * s)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.select_all(action="SELECT")
    bpy.ops.uv.pack_islands(rotate=True, margin=margin)
    bpy.ops.object.mode_set(mode="OBJECT")


# --- Baking --------------------------------------------------------------------------------

def _use_gpu():
    try:
        prefs = bpy.context.preferences.addons["cycles"].preferences
        for kind in ("OPTIX", "CUDA"):
            try:
                prefs.compute_device_type = kind
                prefs.get_devices()
                if any(d.type == kind for d in prefs.devices):
                    for d in prefs.devices:
                        d.use = d.type == kind
                    return True
            except TypeError:
                continue
    except Exception:
        pass
    return False


def bake_maps(obj, size, lo, hi, margin=8, attrs=("piece",), ao_samples=64):
    """Bake what the painter needs per texel: position (game coordinates), normal, ambient
    occlusion and every face attribute in `attrs` (whole numbers: the piece, a face's tag; a
    tenth each into a float image). Returns float arrays (size, size, ...) and the mask of used
    texels."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "GPU" if _use_gpu() else "CPU"
    scene.render.bake.margin = margin
    _select_only(obj)
    mat = bpy.data.materials.new("bake")
    mat.use_nodes = True
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    attr = nt.nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "piece"
    tex = nt.nodes.new("ShaderNodeTexCoord")
    sep_math = nt.nodes.new("ShaderNodeVectorMath")
    img_node = nt.nodes.new("ShaderNodeTexImage")
    nt.nodes.active = img_node
    lo_b = np.array(g2b(lo))
    hi_b = np.array(g2b(hi))
    blo = np.minimum(lo_b, hi_b)
    bhi = np.maximum(lo_b, hi_b)

    def new_image(name):
        img = bpy.data.images.new(name, size, size, alpha=True, float_buffer=True)
        img.colorspace_settings.name = "Non-Color"
        img.generated_color = (0, 0, 0, 0)
        return img

    def read(img):
        a = np.empty(size * size * 4, dtype=np.float32)
        img.pixels.foreach_get(a)
        return a.reshape(size, size, 4)

    results = {}
    # Object-space position, scaled into 0..1 by the model's box.
    pos_img = new_image("bake_pos")
    img_node.image = pos_img
    sub = nt.nodes.new("ShaderNodeVectorMath")
    sub.operation = "SUBTRACT"
    sub.inputs[1].default_value = tuple(blo)
    div = nt.nodes.new("ShaderNodeVectorMath")
    div.operation = "DIVIDE"
    div.inputs[1].default_value = tuple(bhi - blo)
    nt.links.new(tex.outputs["Object"], sub.inputs[0])
    nt.links.new(sub.outputs[0], div.inputs[0])
    nt.links.new(div.outputs[0], emit.inputs["Color"])
    scene.cycles.samples = 1
    bpy.ops.object.bake(type="EMIT", margin=margin, use_clear=True)
    raw = read(pos_img)
    mask = raw[..., 3] > 0.5
    pb = raw[..., :3] * (bhi - blo) + blo
    results["pos"] = np.stack([pb[..., 0], pb[..., 2], -pb[..., 1]], -1)  # to game coordinates
    # Normal (object space).
    nrm_img = new_image("bake_nrm")
    img_node.image = nrm_img
    for link in list(emit.inputs["Color"].links):
        nt.links.remove(link)
    half = nt.nodes.new("ShaderNodeVectorMath")
    half.operation = "MULTIPLY_ADD"
    half.inputs[1].default_value = (0.5, 0.5, 0.5)
    half.inputs[2].default_value = (0.5, 0.5, 0.5)
    to_obj = nt.nodes.new("ShaderNodeVectorTransform")
    to_obj.vector_type = "NORMAL"
    to_obj.convert_from = "WORLD"
    to_obj.convert_to = "OBJECT"
    nt.links.new(geo.outputs["Normal"], to_obj.inputs[0])
    nt.links.new(to_obj.outputs[0], half.inputs[0])
    nt.links.new(half.outputs[0], emit.inputs["Color"])
    bpy.ops.object.bake(type="EMIT", margin=margin, use_clear=True)
    nb = read(nrm_img)[..., :3] * 2.0 - 1.0
    results["nrm"] = np.stack([nb[..., 0], nb[..., 2], -nb[..., 1]], -1)
    # Whole-number face attributes (piece, tag), a tenth each so they fit in a colour.
    scale = nt.nodes.new("ShaderNodeMath")
    scale.operation = "MULTIPLY"
    scale.inputs[1].default_value = 0.1
    nt.links.new(attr.outputs["Fac"], scale.inputs[0])
    for name in attrs:
        attr.attribute_name = name
        img = new_image("bake_" + name)
        img_node.image = img
        for link in list(emit.inputs["Color"].links):
            nt.links.remove(link)
        nt.links.new(scale.outputs[0], emit.inputs["Color"])
        bpy.ops.object.bake(type="EMIT", margin=margin, use_clear=True)
        results[name] = np.rint(read(img)[..., 0] * 10.0).astype(np.int32)
    # Ambient occlusion.
    ao_img = new_image("bake_ao")
    img_node.image = ao_img
    scene.cycles.samples = ao_samples
    bpy.ops.object.bake(type="AO", margin=margin, use_clear=True)
    results["ao"] = read(ao_img)[..., 0]
    results["mask"] = mask
    obj.data.materials.clear()
    return results


def save_png(rgb, path, size):
    """Save an (size, size, 3) sRGB array (0..1) as a PNG, row 0 at the bottom like Blender."""
    img = bpy.data.images.new(os.path.basename(path), size, size, alpha=False, float_buffer=False)
    rgba = np.concatenate([np.clip(rgb, 0, 1), np.ones((size, size, 1), np.float32)], -1)
    img.pixels.foreach_set(rgba.astype(np.float32).ravel())
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    return img


def textured_material(obj, albedo_img, emission_img, emission_strength=3.0):
    mat = bpy.data.materials.new(obj.name + "_mat")
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes.get("Principled BSDF")
    t_alb = nt.nodes.new("ShaderNodeTexImage")
    t_alb.image = albedo_img
    t_alb.image.colorspace_settings.name = "sRGB"
    nt.links.new(t_alb.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = 0.8
    if emission_img is not None:
        t_em = nt.nodes.new("ShaderNodeTexImage")
        t_em.image = emission_img
        nt.links.new(t_em.outputs["Color"], bsdf.inputs["Emission Color"])
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    return mat


# --- Rig -----------------------------------------------------------------------------------

def add_rig(obj, weights=None):
    """The game's skeleton as an armature, and `weights` {bone: (N,) array} on the vertices
    (None: the vertex groups are already there, mesh_from_poly made them)."""
    arm_data = bpy.data.armatures.new("Rig")
    arm = bpy.data.objects.new("Rig", arm_data)
    bpy.context.scene.collection.objects.link(arm)
    _select_only(arm)
    bpy.ops.object.mode_set(mode="EDIT")
    for name, parent, head, tail in BONES:
        b = arm_data.edit_bones.new(name)
        b.head = g2b(head)
        b.tail = g2b(tail)
        if parent:
            b.parent = arm_data.edit_bones[parent]
            b.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for name, w in (weights or {}).items():
        vg = obj.vertex_groups.new(name=name)
        for level in np.unique(np.round(w[w > 0.001], 3)):
            idx = np.nonzero(np.abs(np.round(w, 3) - level) < 1e-6)[0]
            vg.add(idx.tolist(), float(level), "REPLACE")
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = arm
    obj.parent = arm
    return arm


def export_glb(objs, path):
    for o in bpy.context.view_layer.objects:
        o.select_set(o in objs)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
        export_skins=True, export_animations=False, export_yup=True, export_apply=False,
        export_materials="NONE")  # the game makes the material from the PNGs next to the .glb


# --- Previews ------------------------------------------------------------------------------

def flat_materials(obj, attr, colours):
    """Quick look: one plain material per value of a face attribute (colours[value] = RGB)."""
    me = obj.data
    vals = np.empty(len(me.polygons), dtype=np.float32)
    me.attributes[attr].data.foreach_get("value", vals)
    me.materials.clear()
    for i, c in enumerate(colours):
        mat = bpy.data.materials.new(f"{obj.name}_{attr}_{i}")
        mat.use_nodes = True
        bsdf = mat.node_tree.nodes["Principled BSDF"]
        bsdf.inputs["Base Color"].default_value = (*[float(v) ** 2.2 for v in c], 1.0)
        bsdf.inputs["Roughness"].default_value = 0.85
        me.materials.append(mat)
    me.polygons.foreach_set("material_index", np.rint(vals).astype(np.int32))


def contact_sheet(paths, out_path, cols):
    """Rendered previews (same size) side by side, `cols` per row, into one PNG."""
    imgs = [bpy.data.images.load(p) for p in paths]
    w, h = imgs[0].size
    rows = (len(imgs) + cols - 1) // cols
    sheet = np.zeros((rows * h, cols * w, 4), dtype=np.float32)
    for i, img in enumerate(imgs):
        px = np.empty(w * h * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        r, c = divmod(i, cols)
        y0 = (rows - 1 - r) * h  # Blender's rows start at the bottom
        sheet[y0:y0 + h, c * w:(c + 1) * w] = px.reshape(h, w, 4)
    out = bpy.data.images.new(os.path.basename(out_path), cols * w, rows * h, alpha=False)
    out.pixels.foreach_set(sheet.ravel())
    out.filepath_raw = out_path
    out.file_format = "PNG"
    out.save()


def render_views(obj, out_dir, prefix, views, size=(720, 1080)):
    """Render the model from game-space camera positions looking at game-space targets."""
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x, scene.render.resolution_y = size
    scene.render.film_transparent = False
    world = bpy.data.worlds.new("World")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = (0.045, 0.045, 0.06, 1)
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    scene.world = world
    scene.view_settings.view_transform = "Standard"
    key = bpy.data.objects.new("key", bpy.data.lights.new("key", "SUN"))
    key.data.energy = 3.2
    key.rotation_euler = (math.radians(50), 0, math.radians(200))
    scene.collection.objects.link(key)
    fill = bpy.data.objects.new("fill", bpy.data.lights.new("fill", "SUN"))
    fill.data.energy = 0.9
    fill.rotation_euler = (math.radians(70), 0, math.radians(20))
    scene.collection.objects.link(fill)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    import mathutils
    for name, eye, target, lens in views:
        cam.location = g2b(eye)
        d = mathutils.Vector(g2b(target)) - mathutils.Vector(g2b(eye))
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        cam.data.lens = lens
        scene.render.filepath = os.path.join(out_dir, f"{prefix}_{name}.png")
        bpy.ops.render.render(write_still=True)


# --- Elements (tools/models/props.py) ---------------------------------------------------------

def bake_edges(obj, size, radius=0.006, margin=8, samples=16):
    """How much each texel sits on an edge (0 flat .. 1 a sharp corner): the angle between the
    face's normal and the normal rounded over `radius` (Cycles' bevel). The painter chips paint
    there first. Returns a float array (size, size)."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "GPU" if _use_gpu() else "CPU"
    scene.cycles.samples = samples
    _select_only(obj)
    mat = bpy.data.materials.new("bake_edge")
    mat.use_nodes = True
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    nt.links.new(emit.outputs[0], out.inputs["Surface"])
    geo = nt.nodes.new("ShaderNodeNewGeometry")
    bevel = nt.nodes.new("ShaderNodeBevel")
    bevel.samples = 8
    bevel.inputs["Radius"].default_value = radius
    dot = nt.nodes.new("ShaderNodeVectorMath")
    dot.operation = "DOT_PRODUCT"
    nt.links.new(bevel.outputs["Normal"], dot.inputs[0])
    nt.links.new(geo.outputs["Normal"], dot.inputs[1])
    inv = nt.nodes.new("ShaderNodeMath")
    inv.operation = "MULTIPLY_ADD"  # (1 - dot) * 4, clamped
    inv.use_clamp = True
    inv.inputs[1].default_value = -4.0
    inv.inputs[2].default_value = 4.0
    nt.links.new(dot.outputs["Value"], inv.inputs[0])
    nt.links.new(inv.outputs[0], emit.inputs["Color"])
    img = bpy.data.images.new("bake_edge", size, size, alpha=True, float_buffer=True)
    img.colorspace_settings.name = "Non-Color"
    node = nt.nodes.new("ShaderNodeTexImage")
    node.image = img
    nt.nodes.active = node
    bpy.ops.object.bake(type="EMIT", margin=margin, use_clear=True)
    a = np.empty(size * size * 4, dtype=np.float32)
    img.pixels.foreach_get(a)
    obj.data.materials.clear()
    return a.reshape(size, size, 4)[..., 0]


def split_by_attr(obj, attr, value, name):
    """A copy of `obj` holding only the faces whose FACE float `attr` is `value`."""
    me = obj.data.copy()
    me.name = name
    vals = np.empty(len(me.polygons), dtype=np.float32)
    me.attributes[attr].data.foreach_get("value", vals)
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    drop = [f for f in bm.faces if abs(vals[f.index] - value) > 0.5]
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    bm.to_mesh(me)
    bm.free()
    out = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(out)
    return out


def set_origin(obj, pivot):
    """Move the object's origin to `pivot` (game coordinates) without moving its faces."""
    p = np.array(g2b(pivot))
    me = obj.data
    co = np.empty(len(me.vertices) * 3, dtype=np.float32)
    me.vertices.foreach_get("co", co)
    co = (co.reshape(-1, 3) - p).ravel()
    me.vertices.foreach_set("co", co)
    me.update()
    obj.location = tuple(p)


def transfer_uvs(src, dst):
    """Give `dst` (a cheaper LOD) UVs from `src`'s nearest faces, so it wears the same texture."""
    if "UVMap" not in dst.data.uv_layers:
        dst.data.uv_layers.new(name="UVMap")
    mod = dst.modifiers.new("uv", "DATA_TRANSFER")
    mod.object = src
    mod.use_loop_data = True
    mod.data_types_loops = {"UV"}
    mod.loop_mapping = "POLYINTERP_NEAREST"
    _select_only(dst)
    bpy.ops.object.modifier_apply(modifier=mod.name)
