extends TestCase
## The city map: all of references/joinville.png (and above it, the hill road's hairpin), the five
## mission POIs in it.

const POIS := ["hospital", "terminal", "prefeitura", "batalhao", "mirante"]

static var _shared: CityMap # building a city takes a moment, so the read-only tests share one


func _map() -> CityMap:
	if _shared == null:
		_shared = GameMap.create("city")
	return _shared


static func after_all() -> void:
	if _shared != null:
		_shared.root.free()
		_shared = null


func _count(node: Node, type_name: String) -> int:
	var n := 1 if node.is_class(type_name) else 0
	for c in node.get_children():
		n += _count(c, type_name)
	return n


func _px(x: float, y: float) -> Vector3:
	return CityData.to_world(Vector2(x, y))


func test_city_comes_from_the_map_factory() -> void:
	assert_true(GameMap.NAMES.has("city"))
	var m := _map()
	assert_true(m is CityMap)
	assert_true(m.outdoor)
	assert_eq(m.name, "city")


func test_all_five_pois_are_inside_with_room_around_them() -> void:
	var m := _map()
	assert_eq(CityData.POIS.size(), 5)
	for id: String in POIS:
		assert_true(CityData.POIS.has(id), "%s is a POI" % id)
		var p := m.poi_pos(id)
		assert_true(m.contains(p), "%s is inside the map" % id)


func test_everything_between_the_pois_is_in() -> void:
	var m := _map()
	for a: String in POIS:
		for b: String in POIS:
			for t in [0.25, 0.5, 0.75]:
				var p := m.poi_pos(a).lerp(m.poi_pos(b), t)
				assert_true(m.contains(p), "between %s and %s" % [a, b])


func test_the_whole_picture_is_the_map() -> void:
	var m := _map()
	for corner: Vector3 in [_px(2, 2), _px(1918, 2), _px(2, 1018), _px(1918, 1018)]:
		assert_true(m.contains(corner), "the picture's corner %s is in" % corner)
	for far: Vector3 in [_px(100, 100), _px(300, 600), _px(450, 300), _px(1700, 800), _px(1200, 950), _px(900, 60)]:
		assert_true(m.contains(far), "%s is in: the town is not cut down to the POIs" % far)
	assert_false(m.contains(_px(-10, 500)), "nothing beyond the picture")
	assert_near(m.area_km2(), CityData.FRAME.get_area() * CityData.M_PER_PX * CityData.M_PER_PX / 1.0e6, 0.01)


func test_every_poi_can_be_walked_to_from_the_start() -> void:
	var m := _map()
	var start := m.player_spawn()
	assert_false(m.nav.is_blocked(start), "players start on open ground")
	assert_lt(start.distance_to(m.poi_pos("terminal")), 40.0, "at the bus terminal")
	for id: String in POIS:
		assert_false(m.nav.is_blocked(m.poi_pos(id)), "%s stands on open ground" % id)
		assert_true(m.nav.reachable(start, m.poi_pos(id)), "streets lead to %s" % id)


func test_player_spawn_points_are_all_clear() -> void:
	var m := _map()
	for i in 30:
		assert_false(m.nav.is_blocked(m.player_spawn_point()))


func test_streets_are_open_and_blocks_are_built_up() -> void:
	var m := _map()
	assert_gt(m.building_count, 400, "city blocks are filled with buildings")
	# main streets and side streets across the picture
	for street: Vector3 in [_px(233, 125.7), _px(371.65, 818.95), _px(569, 210.5), _px(254.6, 788.15)]:
		assert_eq(m.type_at(street), CityMap.STREET, "street at %s" % street)
		assert_false(m.nav.is_blocked(street))
	var block := _px(850, 318) # a block of the centre, far from every street
	assert_eq(m.type_at(block), CityMap.BLOCK)
	assert_true(m.nav.is_blocked(block), "buildings are solid")


func test_the_river_needs_a_bridge() -> void:
	var m := _map()
	assert_eq(m.type_at(_px(1154, 380)), CityMap.WATER)
	assert_true(m.nav.is_blocked(_px(1154, 380)), "no wading")
	assert_true(m.nav.reachable(m.poi_pos("hospital"), m.poi_pos("prefeitura")), "west bank to east bank over a bridge")


func test_the_hill_is_forest_with_one_road_up() -> void:
	var m := _map()
	assert_eq(m.type_at(_px(1500, 330)), CityMap.FOREST)
	assert_true(m.nav.is_blocked(_px(1500, 330)))


## joinville.png cuts the hill off at its top edge; the road up was re-traced from
## joinville_topography.png (same scale, shifted by TOPO_OFFSET_PX).
func test_the_mirante_road_climbs_the_real_hairpins_to_the_summit() -> void:
	var m := _map()
	var summit := _px(1866, 45) # the 230 m trig point, where the chemin du Télégraphe ends
	var top := m.poi_pos("mirante")
	assert_lt(Vector2(top.x, top.z).distance_to(Vector2(summit.x, summit.z)), 12.0, "the tower stands on the summit")
	for bend: Vector2 in [Vector2(1648, 283), Vector2(1700, 148), Vector2(1668, 40), Vector2(1808, -90), Vector2(1823, -50)]:
		var p := _px(bend.x, bend.y)
		assert_true(m.contains(p), "bend %s is inside the map" % bend)
		assert_eq(m.type_at(p), CityMap.STREET, "the road passes the bend at %s" % bend)
	assert_eq(m.type_at(_px(1760, 100)), CityMap.FOREST, "no shortcut straight up the slope")
	assert_true(m.nav.reachable(m.poi_pos("terminal"), m.poi_pos("mirante")))


func test_the_hill_rises_to_the_mirante_and_the_city_stays_flat() -> void:
	var m := _map()
	var top := m.poi_pos("mirante")
	assert_gt(top.y, 180.0, "the Mirante stands on a hill (summit is 230 m, the city ~12 m)")
	assert_near(m.ground_y(top), top.y, 0.01, "poi_pos is on the ground")
	for flat: String in ["terminal", "hospital", "prefeitura", "batalhao"]:
		assert_near(m.poi_pos(flat).y, 0.0, 0.01, "%s is down in the city" % flat)
	for street: Vector3 in [_px(950, 523), _px(1139, 330), _px(1169, 262)]:
		assert_near(m.ground_y(street), 0.0, 0.01, "city streets stay at 0")


func test_the_hill_road_is_climbable_all_the_way() -> void:
	var m := _map()
	var road: Array = []
	road.append_array(CityData.street("telegraphe").pts)
	var prev := Vector3.INF
	var steepest := 0.0
	var where := Vector3.ZERO
	for i in road.size() - 1:
		var a := CityData.to_world(road[i])
		var b := CityData.to_world(road[i + 1])
		for k in 12:
			var p := a.lerp(b, k / 12.0)
			p.y = m.ground_y(p)
			if prev != Vector3.INF and Vector2(p.x, p.z).distance_to(Vector2(prev.x, prev.z)) > 0.5:
				var slope := absf(p.y - prev.y) / Vector2(p.x, p.z).distance_to(Vector2(prev.x, prev.z))
				if slope > steepest:
					steepest = slope
					where = p
			prev = p
	assert_lt(rad_to_deg(atan(steepest)), 38.0, "no stretch of the road is steeper than a walker can climb (worst at %s, px %s)" % [where, CityData.to_px(where)])
	assert_gt(m.ground_y(CityData.to_world(road[road.size() - 1])), 180.0, "and it ends up on the top")


func test_players_stand_on_the_hill_and_zombies_climb_it() -> void:
	var g := await new_game("city", "mirante")
	await seconds(0.6)
	var p := g.local_player
	assert_near(p.global_position.y, g.map.ground_y(p.global_position), 0.3, "standing on the summit, not inside or above it")
	assert_gt(p.global_position.y, 180.0)
	# Up one stretch of the road: from a bend to the next one, ~60 m away and well above it.
	var up := CityData.to_world(Vector2(1708, 10))
	up.y = g.map.ground_y(up) + 0.1
	p.teleport(up)
	var below := CityData.to_world(Vector2(1683, 15))
	below.y = g.map.ground_y(below) + 0.1
	assert_gt(up.y - below.y, 10.0, "it is a climb")
	var z := g.spawn_zombie(Zombie.Type.RUNNER, below)
	z.hp = 100000
	var got_there := await wait_until(func(): return z.global_position.distance_to(p.global_position) < 2.5, 16.0)
	assert_true(got_there, "a runner climbs the road to the player (at %s, player at %s)" % [z.global_position, p.global_position])


func test_zombies_spawn_on_the_ground_on_the_hill() -> void:
	var m := _map()
	var player := m.poi_pos("mirante")
	for i in 10:
		var p := m.zombie_spawn_point([player])
		assert_near(p.y, m.ground_y(p) + 0.1, 0.05, "spawn %s sits on the ground" % p)


func test_blood_lands_on_the_slope() -> void:
	var g := await new_game("city", "mirante")
	var at: Vector3 = g.map.poi_pos("mirante") + Vector3(3, 1.2, 3)
	g.gore.splat(at)
	assert_gt(g.map.ground_y(at), 150.0)
	assert_near(g.gore.floor_at(at), g.map.ground_y(at), 0.01, "stains go on the hillside, not buried under it")


func test_a_mission_starts_players_at_its_poi() -> void:
	for id: String in POIS:
		var m := _map()
		m.mission = id
		assert_lt(m.player_spawn().distance_to(m.poi_pos(id)), 3.0, "%s mission starts at %s" % [id, id])
		assert_false(m.nav.is_blocked(m.player_spawn()))
	_map().mission = ""
	assert_lt(_map().player_spawn().distance_to(_map().poi_pos("terminal")), 3.0, "no mission: the bus terminal")


func test_game_passes_the_mission_to_the_map() -> void:
	var g := await new_game("city", "mirante")
	assert_eq(g.map.mission, "mirante")
	assert_lt(g.local_player.global_position.distance_to(g.map.poi_pos("mirante")), 4.0, "player starts at the Mirante")


func test_it_stays_cheap_to_draw() -> void:
	var m := _map()
	assert_lt(_count(m.root, "MeshInstance3D"), 12, "the whole city is a handful of merged meshes")
	var shadows := 0
	for l in m.root.find_children("*", "Light3D", true, false):
		if (l as Light3D).shadow_enabled:
			shadows += 1
	assert_lt(shadows, 3, "at most two shadow-casting lights")


func test_layout_is_identical_every_time() -> void:
	var a := _map()
	var b: CityMap = GameMap.create("city")
	assert_eq(a.building_count, b.building_count)
	assert_eq(a.layout_hash(), b.layout_hash(), "every peer builds the same city")
	b.root.free()


func test_zombies_arrive_nearby_but_away_from_players() -> void:
	var m := _map()
	var player := m.player_spawn()
	for i in 30:
		var p := m.zombie_spawn_point([player])
		assert_false(m.nav.is_blocked(p), "spawn %s is on open ground" % p)
		assert_gt(p.distance_to(player), Config.SPAWN_MIN_DIST - 0.01, "not on top of the player")
		assert_lt(p.distance_to(player), Config.CITY_SPAWN_FAR + 6.0, "but in the same neighbourhood")
		assert_true(m.nav.reachable(p, player), "and it can walk to the player from %s" % p)


func test_plan_picture_shows_the_chosen_part() -> void:
	var img := _map().plan_image()
	assert_gt(img.get_width(), 400)
	assert_gt(img.get_height(), 300)


func test_player_stands_on_the_street_and_a_zombie_walks_up() -> void:
	var g := await new_game("city")
	await seconds(0.4)
	var p := g.local_player
	assert_near(p.global_position.y, 0.0, 0.15, "standing on the ground")
	var z := g.spawn_zombie(Zombie.Type.RUNNER, p.global_position + Vector3(10, 0.1, 0))
	z.hp = 100000
	var got_there := await wait_until(func(): return z.global_position.distance_to(p.global_position) < 2.0, 8.0)
	assert_true(got_there, "runner reached the player")
