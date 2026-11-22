extends TestCase
## Every element in the registry (scripts/models/elements.gd), made by tools/models/props.py:
## it loads, it is the size its card says, it keeps its budgets per LOD, and its moving parts and
## states are there.


func _card_size(elem: String) -> Vector3:
	var f := FileAccess.open("res://references/elements/%s.md" % elem, FileAccess.READ)
	assert_true(f != null, "%s has a card" % elem)
	if f == null:
		return Vector3.ZERO
	var re := RegEx.create_from_string("size \\(m\\):\\s*([0-9.]+)\\s*x\\s*([0-9.]+)\\s*x\\s*([0-9.]+)")
	var m := re.search(f.get_as_text())
	assert_true(m != null, "%s's card gives its size as `size (m): W x H x D`" % elem)
	if m == null:
		return Vector3.ZERO
	return Vector3(float(m.get_string(1)), float(m.get_string(2)), float(m.get_string(3)))


func _tris(n: Node) -> int:
	var t := 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		t += (n as MeshInstance3D).mesh.get_faces().size() / 3
	for c in n.get_children():
		t += _tris(c)
	return t


func test_every_element_loads_at_its_cards_size() -> void:
	assert_gt(Elements.ALL.size(), 0, "at least the worked example")
	for elem: String in Elements.ALL:
		var model := PropModel.load_model(elem)
		assert_true(model != null and model.lods.size() > 0, "%s loads" % elem)
		var want := _card_size(elem)
		var got := model.size()
		for axis in 3:
			assert_near(got[axis], want[axis], want[axis] * 0.05, "%s: axis %d within 5%% of the card" % [elem, axis])


func test_budgets_per_lod_and_lods_get_cheaper() -> void:
	for elem: String in Elements.ALL:
		var e: Dictionary = Elements.ALL[elem]
		var model := PropModel.load_model(elem)
		var budget: Array = e.tris
		assert_eq(model.lods.size(), budget.size(), "%s: one budget per LOD" % elem)
		var last := 1 << 30
		for i in model.lods.size():
			var n := model.triangles(i)
			assert_lt(n, budget[i] + 1, "%s LOD%d: %d triangles, budget %d" % [elem, i, n, budget[i]])
			assert_lt(n, last, "%s LOD%d cheaper than the one before" % [elem, i])
			last = n
		assert_lt(model.draws(0), e.draws + 1, "%s: draws at LOD0" % elem)


func test_lods_switch_by_distance() -> void:
	for elem: String in Elements.ALL:
		var node := PropModel.load_model(elem).instance()
		add_child(node)
		var ends: Array[float] = []
		for i in PropModel.load_model(elem).lods.size():
			var lod := node.get_node("lod%d" % i) as Node3D
			assert_true(lod != null, "%s has lod%d" % [elem, i])
			for c in lod.find_children("*", "GeometryInstance3D", true, false):
				var gi := c as GeometryInstance3D
				assert_near(gi.visibility_range_end, Elements.ALL[elem].lod_ends[i], 0.01, "%s lod%d ends where the registry says" % [elem, i])
		node.free()


func test_parts_are_named_nodes_that_move() -> void:
	for elem: String in Elements.ALL:
		var model := PropModel.load_model(elem)
		var node := model.instance()
		add_child(node)
		for part: String in Elements.ALL[elem].parts:
			var p := PropModel.part(node, part)
			assert_true(p != null, "%s: part %s is a node" % [elem, part])
			if p == null:
				continue
			var rest := p.transform
			PropModel.set_open(node, part, 1.0)
			assert_false(p.transform.is_equal_approx(rest), "%s: %s moves when opened" % [elem, part])
			PropModel.set_open(node, part, 0.0)
			assert_true(p.transform.is_equal_approx(rest), "%s: %s back at rest" % [elem, part])
		node.free()


func test_every_state_has_its_own_paint() -> void:
	for elem: String in Elements.ALL:
		var model := PropModel.load_model(elem)
		var seen := {}
		for state: String in Elements.ALL[elem].states:
			var mat := model.material(state)
			assert_true(mat != null and mat.albedo_texture != null, "%s: %s is painted" % [elem, state])
			if mat:
				seen[mat.albedo_texture.get_rid()] = true
		assert_eq(seen.size(), Elements.ALL[elem].states.size(), "%s: each state its own texture" % elem)
		var last: String = Elements.ALL[elem].states[-1]
		var node := model.instance(last)
		add_child(node)
		for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
			assert_eq(mi.material_override, model.material(last), "%s: the instance wears the state asked for" % elem)
		node.free()


func test_flat_shaded_like_the_characters() -> void:
	for elem: String in Elements.ALL:
		var mesh := PropModel.load_model(elem).lods[0][0].mesh as ArrayMesh
		var a := mesh.surface_get_arrays(0)
		var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var smooth := 0
		for t in range(0, idx.size(), 3):
			# the import packs normals, so a flat face's three can differ in the fourth decimal
			if ns[idx[t]].dot(ns[idx[t + 1]]) < 0.999 or ns[idx[t]].dot(ns[idx[t + 2]]) < 0.999:
				smooth += 1
		assert_eq(smooth, 0, "%s: every face flat" % elem)


func test_repeated_elements_are_one_multimesh_per_piece() -> void:
	for elem: String in Elements.ALL:
		var model := PropModel.load_model(elem)
		var xs: Array[Transform3D] = []
		for i in 30:
			xs.append(Transform3D(Basis(), Vector3(i * 3.0, 0, 0)))
		var node := model.multimesh(xs)
		add_child(node)
		var mms := node.find_children("*", "MultiMeshInstance3D", true, false)
		var pieces := 0
		for lod: Array in model.lods:
			pieces += lod.size()
		assert_eq(mms.size(), pieces, "%s: one multimesh per piece of every LOD" % elem)
		for mm: MultiMeshInstance3D in mms:
			assert_eq(mm.multimesh.instance_count, 30, "%s: every copy in it" % elem)
		node.free()


func test_the_rack_shows_it_from_every_review_view() -> void:
	for elem: String in Elements.ALL:
		var rack := PropRack.new()
		add_child(rack)
		assert_true(rack.setup(elem, {"state": Elements.ALL[elem].states[-1], "part": "open"}), "%s on the rack" % elem)
		var first := rack.element.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
		assert_eq(first.material_override, rack.model.material(Elements.ALL[elem].states[-1]), "%s: --state" % elem)
		var p := PropModel.part(rack.element, Elements.ALL[elem].parts[0])
		assert_false(p.transform.is_equal_approx(p.get_meta(&"rest")), "%s: --part=open" % elem)
		var mid := Vector3(0, rack.model.size().y * 0.5, 0)
		for i in PropRack.VIEWS.size():
			rack.look(i)
			assert_true(rack.camera.is_position_in_frustum(mid), "%s: view %s sees it" % [elem, PropRack.VIEWS[i]])
		rack.free()


## The detail kit (S141): every helper of tools/models/shapes.py, surfaces.py, lettering.py and
## wear.py has a sample on the kit's board, named in kit.json with where it stands, and one of the
## board's own review views looks at it.
const KIT_SAMPLES := [
	# shapes
	"chamfer_box", "bevel_box", "lathe", "sweep_pipe", "cable", "handrail", "extrude", "panel_inset",
	"panel_raised", "array_linear", "array_radial", "window_frame", "door_frame", "vent", "louvre_vent",
	# surfaces
	"brick_stretcher", "brick_flemish", "brick_english", "brick_foraine", "concrete_block", "ashlar",
	"setts", "setts_fan", "pavers", "roof_flat_tiles", "roof_canal_tiles", "ridge_caps", "corrugated",
	"ribbed", "grille", "mesh", "louvres", "board_formed",
	# lettering
	"font_block", "font_stencil", "numbers", "street_plate", "road_word",
	# wear
	"chips", "rust_runs", "water_stains", "soot", "moss", "dirt_foot", "posters", "graffiti",
	# damage
	"dents", "broken_glass", "pocks", "burnt_materials", "cut",
]


func test_the_kit_shows_every_helper() -> void:
	var model := PropModel.load_model("kit")
	assert_true(model != null, "the kit is built")
	if model == null:
		return
	var samples: Dictionary = model.info.get("samples", {})
	var size := model.size()
	var lo: Array = model.info.min
	var rack := PropRack.new()
	add_child(rack)
	rack.setup("kit", {})
	var views: Array = model.info.get("views", [])
	assert_gt(views.size(), 3, "the kit has close-up views")
	for s: String in KIT_SAMPLES:
		assert_true(samples.has(s), "the kit shows %s" % s)
		if not samples.has(s):
			continue
		var a: Array = samples[s]
		var p := Vector3(a[0], a[1], a[2])
		for axis in 3:
			assert_true(p[axis] >= float(lo[axis]) - 0.01 and p[axis] <= float(lo[axis]) + size[axis] + 0.01, "%s lies on the kit" % s)
		var seen := false
		for i in views.size():
			rack.look_view(i)
			if rack.camera.is_position_in_frustum(p):
				seen = true
				break
		assert_true(seen, "a close-up of the kit sees %s" % s)
	rack.free()
