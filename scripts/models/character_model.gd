class_name CharacterModel
## A character made by the model scripts in tools/models (`<name>.glb` holding one skinned mesh,
## plus `<name>_albedo.png` and `<name>_emission.png`): the mesh, a skin bound to the game's
## joints, its material, and a rigid copy of every body part for gibs and ragdolls.
## Loaded once and shared by every rig made from it (Humanoid.create_model).
##
## The .glb's own skeleton is not used: the rig builds a Skeleton3D with the game's joints
## (rest = straight offsets, no rotation), so a joint's rotation is its bone's pose as it is.
## The mesh's bone indices point at the skin's binds, which are named after those joints.
##
## The outfits (tools/models/outfits.py: the bodies dressed) also bind helper bones, one per
## limb joint, sitting on it and turning half as far (Humanoid._apply): the ring of cloth round
## a joint rides one, so a sleeve or a trouser leg bends instead of pinching. They say which rigid
## piece each point goes with in their second UV channel, so a sleeve comes off cut where the
## clothes were made to be cut, closed by a wound.

## The game's joints in bone order, then the helpers; their parents, and where each sits on its
## parent at rest (a helper sits where its joint does).
const JOINTS := ["hips", "spine", "neck", "shoulder_l", "elbow_l", "shoulder_r", "elbow_r",
	"hip_l", "knee_l", "hip_r", "knee_r",
	"shoulder_l_mid", "elbow_l_mid", "shoulder_r_mid", "elbow_r_mid",
	"hip_l_mid", "knee_l_mid", "hip_r_mid", "knee_r_mid"]
const PARENTS := [-1, 0, 1, 1, 3, 1, 5, 0, 7, 0, 9,
	1, 3, 1, 5, 0, 7, 0, 9]
## helper bone -> the joint it follows half way
const HELPER_OF := {11: 3, 12: 4, 13: 5, 14: 6, 15: 7, 16: 8, 17: 9, 18: 10}
## Which joints each of Humanoid's segments is made of; the first is the joint it hangs on.
const SEGMENTS := {
	"torso": ["spine", "hips", "shoulder_l_mid", "shoulder_r_mid", "hip_l_mid", "hip_r_mid"],
	"head": ["neck"],
	"upper_arm_l": ["shoulder_l", "elbow_l_mid"], "forearm_l": ["elbow_l"],
	"upper_arm_r": ["shoulder_r", "elbow_r_mid"], "forearm_r": ["elbow_r"],
	"thigh_l": ["hip_l", "knee_l_mid"], "shin_l": ["knee_l"],
	"thigh_r": ["hip_r", "knee_r_mid"], "shin_r": ["knee_r"],
}
## The segments by number, as a model's second UV channel names them (u = (id + 0.5) / 16;
## tools/models/pipeline.py SEGMENTS).
const SEGMENT_IDS := ["torso", "head", "upper_arm_l", "forearm_l", "upper_arm_r", "forearm_r",
	"thigh_l", "shin_l", "thigh_r", "shin_r"]
## The generic bodies, no clothes (tools/models/body.py): what the outfits are built on.
const BODY_M := "res://assets/models/zombie_body_m"
const BODY_F := "res://assets/models/zombie_body_f"
## The skeleton the bodies are built round (tools/models/skeleton.py), on the same joints.
const SKELETON := "res://assets/models/zombie_skeleton"

static var _cache := {}

var mesh: ArrayMesh
var skin: Skin
var material: StandardMaterial3D
var parts := {}   ## segment name -> ArrayMesh of that part alone, in its joint's space


static func body(female := false) -> CharacterModel:
	return load_model(BODY_F if female else BODY_M)


static func skeleton() -> CharacterModel:
	return load_model(SKELETON)


## A dressed zombie (tools/models/outfits.py): `outfit_name` as in Characters.OUTFIT_NAMES.
static func outfit(outfit_name: String, female := false) -> CharacterModel:
	return load_model(outfit_path(outfit_name, female))


static func outfit_path(outfit_name: String, female := false) -> String:
	return "res://assets/models/zombie_%s_%s" % [outfit_name, "f" if female else "m"]


static func load_model(base: String) -> CharacterModel:
	if not _cache.has(base):
		var m := CharacterModel.new()
		m._load(base)
		_cache[base] = m
	return _cache[base]


## Each joint's offset from its parent at rest (Humanoid's layout); helpers sit on their joints.
static func offsets() -> Array[Vector3]:
	var m := Vector3(-1, 1, 1)
	var out: Array[Vector3] = [Vector3(0, Humanoid.HIP_HEIGHT, 0), Vector3.ZERO, Humanoid.NECK_AT,
		Humanoid.SHOULDER_AT * m, Humanoid.ELBOW_AT, Humanoid.SHOULDER_AT, Humanoid.ELBOW_AT,
		Humanoid.HIP_AT * m, Humanoid.KNEE_AT, Humanoid.HIP_AT, Humanoid.KNEE_AT]
	for h in range(11, JOINTS.size()):
		out.append(out[HELPER_OF[h]])
	return out


## Where each joint is at rest, in the model's space.
static func rest_positions() -> Array[Vector3]:
	var off := offsets()
	var out: Array[Vector3] = []
	for i in JOINTS.size():
		out.append(off[i] + (out[PARENTS[i]] if PARENTS[i] >= 0 else Vector3.ZERO))
	return out


## A fresh skeleton with the game's joints, posed at rest.
func make_skeleton() -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton"
	var off := offsets()
	for j in JOINTS:
		sk.add_bone(j)
	for i in JOINTS.size():
		sk.set_bone_parent(i, PARENTS[i])
		sk.set_bone_rest(i, Transform3D(Basis(), off[i]))
	sk.reset_bone_poses()
	return sk


func _load(base: String) -> void:
	var scene: PackedScene = load(base + ".glb")
	var root := scene.instantiate()
	var src := _skinned_mesh(root)
	assert(src != null, base + ".glb has no skinned mesh")
	mesh = src.mesh
	var rest := rest_positions()
	skin = Skin.new()
	var bind_joint := PackedInt32Array()
	for i in src.skin.get_bind_count():
		var bone_name := String(src.skin.get_bind_name(i))
		var j := JOINTS.find(bone_name)
		assert(j >= 0, "%s.glb binds an unknown bone %s" % [base, bone_name])
		skin.add_named_bind(bone_name, Transform3D(Basis(), -rest[j]))
		bind_joint.append(j)
	root.free()
	material = StandardMaterial3D.new()
	material.albedo_texture = _mipmapped(load(base + "_albedo.png"))
	material.roughness = 0.85
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY # the map says where it glows
	material.emission_texture = _mipmapped(load(base + "_emission.png"))
	material.emission_energy_multiplier = 2.5
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var seg_of := _segments_of_vertices()
	if not seg_of.is_empty():
		# Clothes fold over at a hard bend: a face seen from behind still shows cloth, not a hole.
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_cut_parts(bind_joint, rest, seg_of)


## The PNGs import as plain 2D textures (import settings are not kept in git); a 3D surface seen
## from afar needs mipmaps, so make them once here.
static func _mipmapped(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img == null or img.is_compressed() or img.has_mipmaps():
		return tex
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _skinned_mesh(n: Node) -> MeshInstance3D:
	if n is MeshInstance3D and (n as MeshInstance3D).skin != null:
		return n
	for c in n.get_children():
		var found := _skinned_mesh(c)
		if found:
			return found
	return null


## The segment each vertex goes with, when the model says so (its second UV channel); empty if not.
func _segments_of_vertices() -> PackedStringArray:
	var a := mesh.surface_get_arrays(0)
	var out := PackedStringArray()
	if not (a[Mesh.ARRAY_TEX_UV2] is PackedVector2Array):
		return out
	var uv2: PackedVector2Array = a[Mesh.ARRAY_TEX_UV2]
	for uv in uv2:
		out.append(SEGMENT_IDS[clampi(int(uv.x * 16.0), 0, SEGMENT_IDS.size() - 1)])
	return out


## Split the mesh into one rigid piece per segment: by what the model says (`seg_of`), else by
## which joint moves each triangle most.
func _cut_parts(bind_joint: PackedInt32Array, rest: Array[Vector3], seg_of: PackedStringArray) -> void:
	var a := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = a[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var ws: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var vseg := PackedStringArray()
	if seg_of.size() == vs.size():
		vseg = seg_of
	else:
		var by_joint := {}
		for seg_name: String in SEGMENTS:
			for j: String in SEGMENTS[seg_name]:
				by_joint[JOINTS.find(j)] = seg_name
		var per := bones.size() / vs.size()
		vseg.resize(vs.size())
		for v in vs.size():
			var best := 0
			var bw := -1.0
			for k in per:
				if ws[v * per + k] > bw:
					bw = ws[v * per + k]
					best = bind_joint[bones[v * per + k]]
			vseg[v] = by_joint[best]
	var tris := {} # segment -> Array of vertex indices (an Array: packed arrays copy out of dictionaries)
	for seg_name: String in SEGMENTS:
		tris[seg_name] = []
	for t in range(0, idx.size(), 3):
		var s1 := vseg[idx[t + 1]]
		var seg := s1 if s1 == vseg[idx[t + 2]] else vseg[idx[t]]
		(tris[seg] as Array).append_array([idx[t], idx[t + 1], idx[t + 2]])
	for seg_name: String in SEGMENTS:
		var origin: Vector3 = rest[JOINTS.find(SEGMENTS[seg_name][0])]
		var remap := {}
		var pv := PackedVector3Array()
		var pn := PackedVector3Array()
		var pu := PackedVector2Array()
		var pi := PackedInt32Array()
		for v: int in tris[seg_name]:
			if not remap.has(v):
				remap[v] = pv.size()
				pv.append(vs[v] - origin)
				pn.append(ns[v])
				pu.append(uvs[v])
			pi.append(remap[v])
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = pv
		arrays[Mesh.ARRAY_NORMAL] = pn
		arrays[Mesh.ARRAY_TEX_UV] = pu
		arrays[Mesh.ARRAY_INDEX] = pi
		var part := ArrayMesh.new()
		part.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		parts[seg_name] = part
