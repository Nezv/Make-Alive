extends TestCase
## Block massing (S043): every block between the streets is an îlot closed by a row of narrow houses
## along its edge, each with its own height and roof by the class of its place (old core, main
## streets, the edge of town, post-war blocks, the river's ateliers, hôtels behind their court),
## courts and back buildings inside from the traced footprints. Collision is one shape per îlot.

static var _layout: CityMap   # the layout only (CityMap.new(false)): îlots and houses as data
static var _full: CityMap     # built: meshes and collision


func _l() -> CityMap:
	if _layout == null:
		_layout = CityMap.new(false)
	return _layout


func _m() -> CityMap:
	if _full == null:
		_full = GameMap.create("city")
	return _full


static func after_all() -> void:
	for m: CityMap in [_layout, _full]:
		if m != null:
			m.root.free()
	_layout = null
	_full = null


func _houses_of(cls: String) -> Array:
	var out := []
	for h: Dictionary in _l().blocks.houses:
		if h.cls == cls:
			out.append(h)
	return out


func _centre(h: Dictionary) -> Vector2:
	var c := Vector2.ZERO
	for p in h.foot:
		c += p
	return c / (h.foot as PackedVector2Array).size()


func test_every_block_is_an_ilot() -> void:
	var b := _l().blocks
	assert_gt(b.ilots.size(), 150, "one îlot per block between the streets")
	for il: Dictionary in b.ilots:
		var outline: PackedVector2Array = il.outline
		assert_gt(outline.size(), 2)
		assert_gt(CityBlocks.area(outline), 0.0, "outlines turn the same way")


func test_ilots_are_closed_by_rows_of_houses_along_their_edge() -> void:
	var b := _l().blocks
	var front := 0.0
	var edge := 0.0
	for il: Dictionary in b.ilots:
		if il.silhouette or CityBlocks.area(il.outline) < 2000.0:
			continue
		edge += il.street_edge
		front += il.fronted
	assert_gt(edge, 20000.0)
	assert_gt(front / edge, 0.97, "every metre of an îlot's street side is a house front or a wall")


func test_houses_are_narrow_and_stand_on_the_block() -> void:
	var m := _l()
	var narrow := 0
	var rows := 0
	var off := 0
	for h: Dictionary in m.blocks.houses:
		var c := _centre(h)
		var t := m.type_at(Vector3(c.x, 0, c.y))
		if t != CityMap.BLOCK and t != CityMap.OUT:
			off += 1
		if h.cls in ["core", "rue", "main"] and h.shape == "row":
			rows += 1
			if float(h.width) <= 13.5:
				narrow += 1
	assert_lt(off, m.blocks.houses.size() / 200, "houses stand on the blocks, not on the streets (%d off)" % off)
	assert_gt(m.blocks.houses.size(), 4000, "the town is many houses, not a few big boxes")
	assert_gt(float(narrow) / rows, 0.95, "a town house is two to five windows wide")


func test_the_old_core_is_tall_and_steep_and_the_edge_of_town_low() -> void:
	var core := _houses_of("core")
	var edge := _houses_of("faubourg")
	assert_gt(core.size(), 200)
	assert_gt(edge.size(), 200)
	for h: Dictionary in core:
		_between(h.floors, 4, 6, "old core: four to six floors")
		assert_true(h.roof == "gable" or h.roof == "hip", "steep pitched roofs in the old core")
		assert_gt(float(h.pitch), 48.0)
	for h: Dictionary in edge:
		_between(h.floors, 2, 3, "edge of town: two or three floors")


func test_main_streets_have_mansards_over_a_stone_ground_floor() -> void:
	var main := _houses_of("main")
	assert_gt(main.size(), 300)
	for h: Dictionary in main:
		_between(h.floors, 3, 5)
		assert_eq(h.roof, "mansard")
		assert_true(h.plinth, "stone ground floor")


func test_post_war_blocks_stand_by_the_hospital_and_the_bus_station_and_none_is_a_tower() -> void:
	var m := _l()
	var slabs := _houses_of("postwar")
	assert_gt(slabs.size(), 20)
	var near := { "hospital": 0, "terminal": 0 }
	for h: Dictionary in slabs:
		assert_eq(h.roof, "flat")
		for id: String in near:
			var p := m.poi_pos(id)
			if _centre(h).distance_to(Vector2(p.x, p.z)) < 260.0:
				near[id] += 1
	assert_gt(near.hospital, 2, "post-war blocks round the hospital")
	assert_gt(near.terminal, 2, "and the bus station")
	for h: Dictionary in m.blocks.houses:
		assert_lt(h.floors, 10, "no skyline of towers")


func test_ateliers_are_low_glass_roofed_halls_by_the_river() -> void:
	var halls := _houses_of("atelier")
	assert_gt(halls.size(), 10)
	var river := PackedVector2Array()
	for p: Vector2 in CityData.RIVER:
		river.append(CityData.to_plan(p))
	for h: Dictionary in halls:
		assert_eq(h.roof, "sawtooth")
		assert_lt(h.floors, 3)
		var c := _centre(h)
		var d := INF
		for i in river.size() - 1:
			d = minf(d, Geometry2D.get_closest_point_to_segment(c, river[i], river[i + 1]).distance_to(c))
		assert_lt(d, Config.CITY_ATELIER_RIVER + 40.0, "by the river")


func test_hotels_stand_behind_a_court_and_a_gate() -> void:
	var b := _l().blocks
	var hotels := _houses_of("hotel")
	assert_gt(hotels.size(), 3)
	var gates := 0
	for w: Dictionary in b.walls:
		if w.gate:
			gates += 1
	assert_gt(gates, hotels.size() - 1, "each hôtel has its gate on the street")


func test_gaps_at_the_edge_of_town_are_closed_by_garden_walls() -> void:
	var garden := 0
	for w: Dictionary in _l().blocks.walls:
		if not w.gate:
			garden += 1
	assert_gt(garden, 50)


func test_courts_hold_back_buildings_from_the_traced_footprints() -> void:
	assert_gt(_houses_of("back").size(), 100, "back buildings and halls fill the courts in the centre")


func test_roofs_vary_house_to_house() -> void:
	var steps := 0
	var pairs := 0
	var hs: Array = _l().blocks.houses
	for i in hs.size() - 1:
		if hs[i].ilot == hs[i + 1].ilot and hs[i].shape == "row" and hs[i + 1].shape == "row":
			pairs += 1
			if absf(float(hs[i].eave) - float(hs[i + 1].eave)) > 0.5:
				steps += 1
	assert_gt(float(steps) / pairs, 0.4, "the cornice line steps from house to house")
	var colours := {}
	for h: Dictionary in hs:
		colours[(h.roof_colour as Color).to_html()] = true
	assert_gt(colours.size(), 4, "slate, zinc and tiles of several shades")


func test_collision_is_one_shape_per_ilot() -> void:
	var m := _m()
	var shapes := 0
	for c in m.root.find_children("*", "CollisionShape3D", true, false):
		if (c as CollisionShape3D).shape is ConcavePolygonShape3D:
			shapes += 1
	assert_eq(shapes, m.blocks.built_ilots, "one shape per built îlot")
	assert_lt(m.blocks.built_ilots, m.blocks.houses.size() / 5, "far fewer shapes than one box per building")


func test_a_house_front_stops_a_bullet_and_a_walker() -> void:
	var g := await new_game("city")
	var m: CityMap = g.map
	var h: Dictionary = m.blocks.front_sample()
	var a: Vector2 = h.foot[0]
	var b: Vector2 = h.foot[1]
	var mid := (a + b) * 0.5
	var out: Vector2 = h.out
	var from := Vector3(mid.x + out.x * 4.0, 1.6, mid.y + out.y * 4.0)
	var to := Vector3(mid.x - out.x * 4.0, 1.6, mid.y - out.y * 4.0)
	var hit: Dictionary = g.local_player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD))
	assert_false(hit.is_empty(), "the front is solid")
	if not hit.is_empty():
		assert_lt(Vector2(hit.position.x, hit.position.z).distance_to(mid), 0.6, "right on the building line")


func test_blocks_outside_the_detail_area_are_silhouettes() -> void:
	var t := _l().poi_pos("terminal")
	var r := 300.0
	var area := PackedVector2Array([Vector2(t.x - r, t.z - r), Vector2(t.x + r, t.z - r), Vector2(t.x + r, t.z + r), Vector2(t.x - r, t.z + r)])
	var near := CityMap.new(true, area)
	var whole := _m()
	var sil := 0
	for il: Dictionary in near.blocks.ilots:
		if il.silhouette:
			sil += 1
	assert_gt(sil, near.blocks.ilots.size() / 2, "most îlots lie outside a small area")
	assert_lt(near.blocks.triangles * 3, whole.blocks.triangles, "silhouettes are a fraction of the detail")
	near.root.free()


func test_the_town_stays_one_mesh_and_inside_its_triangle_budget() -> void:
	var m := _m()
	assert_lt(m.blocks.triangles, Config.CITY_BLOCK_TRIANGLES, "the whole town's mass")
	assert_lt(m.root.find_children("*", "MeshInstance3D", true, false).size(), 12)


func test_the_same_town_every_time() -> void:
	var a := _l()
	var b := CityMap.new(false)
	assert_eq(a.blocks.houses.size(), b.blocks.houses.size())
	assert_eq(a.blocks.layout_hash(), b.blocks.layout_hash(), "every peer builds the same houses")
	b.root.free()


func _between(v: float, a: float, b: float, msg := "") -> void:
	assert_true(v >= a and v <= b, "%s: %s not in %s..%s" % [msg, v, a, b])
