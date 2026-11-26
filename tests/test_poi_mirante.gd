extends TestCase
## The Mirante on Morro da Boa Vista: the gate at the foot, the road up and the summit with its
## lookout tower (MiranteSet, CityMap._hill_road and _mirante).

static var _shared: CityMap


func _map() -> CityMap:
	if _shared == null:
		_shared = GameMap.create("city")
	return _shared


static func after_all() -> void:
	if _shared != null:
		_shared.root.free()
		_shared = null


func _labels(m: CityMap) -> Array:
	return m.root.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)


func test_the_gate_stands_where_the_road_enters_the_forest() -> void:
	var m := _map()
	assert_true(m.mirante.has("gate"), "the hill road has its gate")
	var gate: Vector3 = m.mirante.gate
	assert_eq(m.type_at(gate), CityMap.STREET, "it straddles the road")
	assert_lt(gate.y, 20.0, "at the foot of the hill, not up it")
	assert_false(m.nav.is_blocked(gate), "and the road through it stays open")
	assert_true(_labels(m).has("MORRO DA BOA VISTA"), "the name across the portal")
	assert_true(m.nav.reachable(gate, m.poi_pos("mirante")), "the road goes from the gate to the top")


func test_power_poles_and_guard_rails_follow_the_road_up() -> void:
	var m := _map()
	assert_gt(m.mirante.poles, 40, "concrete power poles all the way up")
	assert_gt(m.mirante.rails, 20, "guard rails round the bends")


func test_the_road_up_is_grey_pavers_with_a_red_brick_lane() -> void:
	var m := _map()
	var colors := {}
	for mi: MeshInstance3D in m.root.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or mi.mesh.get_surface_count() == 0:
			continue
		var arr: Array = mi.mesh.surface_get_arrays(0)
		if arr[Mesh.ARRAY_COLOR] == null:
			continue
		for c: Color in arr[Mesh.ARRAY_COLOR] as PackedColorArray:
			colors[c.to_html()] = colors.get(c.to_html(), 0) + 1
	assert_gt(colors.get(MiranteSet.BRICK.to_html(), 0), 3000, "a brick lane the length of the road")
	assert_gt(colors.get(MiranteSet.PAVERS.to_html(), 0), 1000, "grey pavers on the hill")


func test_the_tower_stands_on_the_summit_with_its_deck_at_14_5_m() -> void:
	var m := _map()
	var tower: Vector3 = m.mirante.tower
	var deck: Vector3 = m.mirante.deck
	assert_lt(Vector2(tower.x, tower.z).distance_to(Vector2(m.poi_pos("mirante").x, m.poi_pos("mirante").z)), 30.0, "on the summit clearing")
	assert_near(tower.y, m.ground_y(tower), 0.01, "standing on the ground")
	assert_near(deck.y - tower.y, 14.5, 0.01, "the real lookout is 14.5 m tall")
	var deck_area := pow(MiranteSet.TOWER_HALF * 2.0, 2.0)
	assert_gt(deck_area, 60.0, "about the real deck's 70 m²")
	assert_lt(deck_area, 100.0)


func test_a_player_climbs_the_stairs_to_the_deck() -> void:
	var g := await new_game("city", "mirante")
	var m: CityMap = g.map
	var p := g.local_player
	var path: Array = m.tower_climb()
	var start: Vector3 = path[0]
	p.teleport(start + Vector3(0, 0.3, 0))
	await seconds(0.3)
	p.bot = true
	for i in range(1, path.size()):
		var goal: Vector3 = path[i]
		var got := await wait_until(func() -> bool:
			var way := goal - p.global_position
			way.y = 0.0
			p.bot_move = way.normalized()
			return way.length() < 0.35, 8.0)
		assert_true(got, "reached step %d of the climb (at %s, wanted %s)" % [i, p.global_position, goal])
		if not got:
			break
	p.bot_move = Vector3.ZERO
	await seconds(0.3)
	assert_near(p.global_position.y, (m.mirante.deck as Vector3).y, 0.4, "standing on the deck")


func test_the_summit_has_its_buildings_and_masts() -> void:
	var m := _map()
	var reds := m.root.find_children("*", "MeshInstance3D", true, false).filter(func(mi: MeshInstance3D) -> bool:
		var mat := mi.material_override as StandardMaterial3D
		return mat != null and mat.emission_enabled and mat.emission.r > 0.9 and mat.emission.g < 0.3)
	assert_eq(reds.size(), 1, "the radio masts' red warning lights, one mesh")
