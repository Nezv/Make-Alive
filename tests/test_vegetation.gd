extends TestCase
## Trees and bushes from boxes (Vegetation) and the forest they make along the Mirante road.

static var _shared: CityMap


func _map() -> CityMap:
	if _shared == null:
		_shared = GameMap.create("city")
	return _shared


static func after_all() -> void:
	if _shared != null:
		_shared.root.free()
		_shared = null


func _draw(kind: int, seed_: int) -> Dictionary:
	var b := MeshKit.Builder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var solid := Vegetation.plant(b, Transform3D.IDENTITY, kind, rng)
	var mesh := b.mesh()
	return { "tris": b.count, "box": mesh.get_aabb(), "solid": solid }


func test_every_kind_draws_something_standing_on_the_ground() -> void:
	for kind in Vegetation.Kind.COUNT:
		var d := _draw(kind, 7)
		assert_gt(d.tris, 20, "%s is more than a box" % Vegetation.NAMES[kind])
		var box: AABB = d.box
		assert_gt(box.position.y, -0.1, "%s does not sink into the ground" % Vegetation.NAMES[kind])
		assert_lt(box.position.y, 0.3, "%s stands on the ground" % Vegetation.NAMES[kind])


func test_the_same_seed_draws_the_same_plant_and_another_seed_another() -> void:
	for kind in Vegetation.Kind.COUNT:
		var a := _draw(kind, 11)
		var b := _draw(kind, 11)
		var c := _draw(kind, 12)
		assert_eq(a.box, b.box, "%s: seeded, every peer draws it alike" % Vegetation.NAMES[kind])
		assert_true(a.box != c.box, "%s: a few shapes per species, not one" % Vegetation.NAMES[kind])


func test_the_species_keep_their_shapes() -> void:
	var palm: AABB = _draw(Vegetation.Kind.IMPERIAL_PALM, 3).box
	var broad: AABB = _draw(Vegetation.Kind.BROADLEAF, 3).box
	var fern: AABB = _draw(Vegetation.Kind.TREE_FERN, 3).box
	var araucaria: AABB = _draw(Vegetation.Kind.ARAUCARIA, 3).box
	var bush: AABB = _draw(Vegetation.Kind.HIBISCUS, 3).box
	assert_gt(palm.size.y, 18.0, "imperial palms are very tall")
	assert_gt(palm.size.y, broad.size.y, "taller than a broad tree")
	assert_lt(palm.size.x, palm.size.y * 0.5, "and slim")
	assert_gt(araucaria.size.y, 14.0, "araucárias stand tall")
	assert_lt(fern.size.y, 6.0, "tree ferns are short")
	assert_lt(bush.size.y, 2.5, "bushes stay below the eye")


func test_trees_have_a_trunk_bushes_do_not() -> void:
	var tree: Array = _draw(Vegetation.Kind.BROADLEAF, 1).solid
	assert_eq(tree.size(), 1, "one trunk to bump into")
	var trunk: Vector3 = tree[0][1]
	assert_lt(trunk.x, 1.2, "a thin trunk: shots pass around it")
	assert_eq((_draw(Vegetation.Kind.HIBISCUS, 1).solid as Array).size(), 0, "a bush is walked into, not blocked by")


func test_ipe_blooms_in_its_colour_and_drops_petals() -> void:
	var b := MeshKit.Builder.new()
	var rng := RandomNumberGenerator.new()
	Vegetation.plant(b, Transform3D.IDENTITY, Vegetation.Kind.IPE_YELLOW, rng)
	var colors := b.mesh().surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray
	var bloom := 0
	var petals_on_ground := 0
	var verts := b.mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	for i in colors.size():
		if colors[i].is_equal_approx(Vegetation.IPE_YELLOW):
			bloom += 1
			if verts[i].y < 0.1:
				petals_on_ground += 1
	assert_gt(bloom, 100, "a yellow crown")
	assert_gt(petals_on_ground, 6, "petals on the ground beneath")


func test_the_mirante_road_runs_between_real_trees() -> void:
	var m := _map()
	var spots: Array = m.roadside_trees
	assert_gt(spots.size(), 300, "the road up is lined with trees")
	var kinds := {}
	for s: Dictionary in spots:
		kinds[s.kind] = true
		var at: Vector3 = s.at
		assert_true(m.type_at(at) != CityMap.STREET, "a tree at %s stands beside the road, not on it" % at)
		assert_near(at.y, m.ground_y(at), 0.05, "a tree at %s grows out of the slope" % at)
	assert_gt(kinds.size(), 4, "a mix of species, Atlantic forest")
	assert_true(kinds.has(Vegetation.Kind.TREE_FERN), "tree ferns along the road")


func test_the_forest_stays_one_mesh() -> void:
	var m := _map()
	var meshes := m.root.find_children("*", "MeshInstance3D", true, false)
	assert_lt(meshes.size(), 12, "trees are merged with the rest of the forest")
