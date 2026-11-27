class_name PropModel
## An element made by tools/models/props.py: `assets/models/props/<name>.glb` (objects `lod0_<part>`
## for the moving parts at full detail, `lod1`, `lod2`... for the cheaper copies), `<name>.json` (its
## size, parts with their pivots and how they move, states, triangles per LOD) and one albedo per
## state (`<name>_<state>.png`), plus `<name>_emission.png` when something on it is lit.
## Loaded once and shared; `instance(state)` builds a node, `multimesh(transforms, state)` many.
##
## Models stand on y = 0 and face -Z, metres. A part's node sits on its pivot, so opening it is a
## turn of that node (`set_open`).

const DIR := "res://assets/models/props/"

static var _cache := {}

var name := ""
var info := {}             ## the .json beside the model
## lods[i] = Array of {"name": part, "mesh": ArrayMesh, "at": Transform3D of the part's node at rest}
var lods: Array = []
var _materials := {}       ## state -> StandardMaterial3D


static func load_model(elem: String) -> PropModel:
	if not _cache.has(elem):
		var m := PropModel.new()
		if not m._load(elem):
			return null
		_cache[elem] = m
	return _cache[elem]


func _load(elem: String) -> bool:
	name = elem
	var f := FileAccess.open(DIR + elem + ".json", FileAccess.READ)
	if f == null:
		push_error("no element model " + elem)
		return false
	info = JSON.parse_string(f.get_as_text())
	var scene: PackedScene = load(DIR + elem + ".glb")
	var root := scene.instantiate()
	var by_name := {}
	for mi: MeshInstance3D in root.find_children("*", "MeshInstance3D", true, false):
		by_name[String(mi.name)] = mi
	var lod0: Array = []
	for part: String in _part_names():
		var mi: MeshInstance3D = by_name.get("lod0_" + part)
		assert(mi != null, "%s.glb has no lod0_%s" % [elem, part])
		lod0.append({"name": part, "mesh": mi.mesh, "at": mi.transform})
	lods.append(lod0)
	var i := 1
	while by_name.has("lod%d" % i):
		var mi: MeshInstance3D = by_name["lod%d" % i]
		lods.append([{"name": "body", "mesh": mi.mesh, "at": mi.transform}])
		i += 1
	root.free()
	return true


## The parts in the order the model gives them: the fixed body first.
func _part_names() -> Array:
	var out := ["body"]
	for p: String in info.parts:
		if p != "body":
			out.append(p)
	return out


## Width, height and depth of the whole element at rest.
func size() -> Vector3:
	var box := AABB()
	var first := true
	for piece: Dictionary in lods[0]:
		var b: AABB = (piece.at as Transform3D) * (piece.mesh as Mesh).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box.size


func triangles(lod: int) -> int:
	var n := 0
	for piece: Dictionary in lods[lod]:
		n += (piece.mesh as Mesh).get_faces().size() / 3
	return n


## Draw calls of one copy at that LOD (one per piece: each mesh has one surface).
func draws(lod: int) -> int:
	return lods[lod].size()


func states() -> Array:
	return info.states


## The material of a state ("" = the first): its own albedo, the shared emission map.
func material(state := "") -> StandardMaterial3D:
	if state == "":
		state = info.states[0]
	if not _materials.has(state):
		var path := DIR + "%s_%s.png" % [name, state]
		if not ResourceLoader.exists(path):
			return null
		var mat := StandardMaterial3D.new()
		mat.albedo_texture = CharacterModel._mipmapped(load(path))
		mat.roughness = 0.8
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if info.get("emission", false):
			mat.emission_enabled = true
			mat.emission = Color.WHITE
			mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			mat.emission_texture = CharacterModel._mipmapped(load(DIR + name + "_emission.png"))
			mat.emission_energy_multiplier = 2.0
		_materials[state] = mat
	return _materials[state]


## Where each LOD stops being drawn (metres from the camera), from the registry.
func lod_ends() -> Array:
	return Elements.ALL[name].lod_ends if Elements.ALL.has(name) else [20.0, 60.0, 200.0]


func _lod_range(gi: GeometryInstance3D, lod: int) -> void:
	var ends := lod_ends()
	gi.visibility_range_begin = 0.0 if lod == 0 else float(ends[lod - 1])
	gi.visibility_range_end = float(ends[lod])


## One copy: a Node3D named after the element holding `lod0` (a node per part, on its pivot),
## `lod1`... each drawn only in its own distance band.
func instance(state := "") -> Node3D:
	var root := Node3D.new()
	root.name = name
	var mat := material(state)
	for i in lods.size():
		var holder := Node3D.new()
		holder.name = "lod%d" % i
		root.add_child(holder)
		for piece: Dictionary in lods[i]:
			var mi := MeshInstance3D.new()
			mi.name = piece.name
			mi.mesh = piece.mesh
			mi.transform = piece.at
			mi.material_override = mat
			mi.set_meta(&"rest", piece.at)
			_lod_range(mi, i)
			holder.add_child(mi)
	return root


## The node of a moving part of an instance (null if it has none such).
static func part(node: Node3D, part_name: String) -> Node3D:
	return node.get_node_or_null("lod0/" + part_name) as Node3D


## Move a part between rest (0) and fully open (1) as the model's data says.
static func set_open(node: Node3D, part_name: String, t: float) -> void:
	var p := part(node, part_name)
	var model := load_model(String(node.name))
	if p == null or model == null:
		return
	var motion: Dictionary = model.info.parts.get(part_name, {})
	var rest: Transform3D = p.get_meta(&"rest")
	if motion.has("rotate"):
		var a: Array = motion.rotate[0]
		var axis := Vector3(a[0], a[1], a[2]).normalized()
		p.transform = Transform3D(rest.basis * Basis(axis, deg_to_rad(float(motion.rotate[1]) * t)), rest.origin)
	elif motion.has("move"):
		var m: Array = motion.move
		p.transform = Transform3D(rest.basis, rest.origin + Vector3(m[0], m[1], m[2]) * t)
	elif motion.has("roll"):  # gathered up into the pivot: a roller shutter's curtain into its box
		var k := 1.0 - float(motion.roll) * t
		p.transform = Transform3D(rest.basis * Basis.from_scale(Vector3(1.0, k, 1.0)), rest.origin)


## Many copies at rest: one MultiMeshInstance3D per piece of every LOD, each in its distance band.
func multimesh(transforms: Array[Transform3D], state := "") -> Node3D:
	var root := Node3D.new()
	root.name = name + "_many"
	var mat := material(state)
	for i in lods.size():
		for piece: Dictionary in lods[i]:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = piece.mesh
			mm.instance_count = transforms.size()
			for k in transforms.size():
				mm.set_instance_transform(k, transforms[k] * (piece.at as Transform3D))
			var mmi := MultiMeshInstance3D.new()
			mmi.name = "lod%d_%s" % [i, piece.name]
			mmi.multimesh = mm
			mmi.material_override = mat
			_lod_range(mmi, i)
			root.add_child(mmi)
	return root
