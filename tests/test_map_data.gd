extends TestCase
## The map data format: one dictionary says where players and zombies appear, where the zones,
## doors and lootboxes are and what the objectives are. A new map or mission is data, not code.

static var _corridor: CorridorGameMap


static func _map() -> CorridorGameMap:
	if _corridor == null:
		_corridor = CorridorGameMap.new()
	return _corridor


static func after_all() -> void:
	if _corridor != null:
		_corridor.root.free()
		_corridor = null


func _with(change: Callable) -> MapData:
	var d: Dictionary = MapAreas.CORRIDOR.duplicate(true)
	change.call(d)
	return MapData.new(d)


func _has_error(data: MapData, text: String) -> bool:
	for e: String in data.errors:
		if e.contains(text):
			return true
	return false


# --- The format -------------------------------------------------------------------

func test_corridor_data_is_valid() -> void:
	var data := MapData.new(MapAreas.CORRIDOR)
	assert_eq(data.errors, [], "no structural errors")
	assert_eq(data.check(_map()), [], "and everything stands on the map it describes")
	assert_eq(MapData.new({}).errors, [], "a map with no data yet is fine too")


func test_duplicate_ids_are_errors() -> void:
	assert_true(_has_error(_with(func(d): d.lootboxes[0].iid = d.doors[0].iid), "iid"), "two interactables with one iid")
	assert_true(_has_error(_with(func(d): d.zones.append(d.zones[0].duplicate())), "zone"), "two zones with one id")
	assert_true(_has_error(_with(func(d): d.zombie_closets.append(d.zombie_closets[0].duplicate())), "closet"))
	assert_true(_has_error(_with(func(d): d.objectives.append(d.objectives[0].duplicate())), "objective"))


func test_dangling_references_and_unknown_kinds_are_errors() -> void:
	assert_true(_has_error(_with(func(d): d.objectives[0].zone = "nowhere"), "nowhere"), "an objective in a zone that isn't there")
	assert_true(_has_error(_with(func(d): d.horde_routes[0].closet = "attic"), "attic"), "a route from a closet that isn't there")
	assert_true(_has_error(_with(func(d): d.zones[0].kind = "disco"), "disco"))
	assert_true(_has_error(_with(func(d): d.objectives[0].kind = "dance"), "dance"))
	assert_true(_has_error(_with(func(d): d.zones[0].erase("box")), "shape"), "a zone needs a box or a polygon")
	assert_true(_has_error(_with(func(d): d.player_spawns = []), "spawn"), "nowhere for players to start")
	assert_true(_has_error(_with(func(d): d.doors[0].erase("at")), "at"), "a door with no position")


func test_zones_know_what_is_inside_them() -> void:
	var data := MapData.new({
		"zones": [
			{ "id": "pad", "kind": "extraction", "box": [Vector3(10, 1, 0), Vector3(4, 2, 6)] },
			{ "id": "roof", "kind": "trigger", "polygon": [Vector2(0, 0), Vector2(8, 0), Vector2(8, 8), Vector2(0, 8)], "y": [9.0, 13.0] },
			{ "id": "yard", "kind": "checkpoint", "polygon": [Vector2(20, 0), Vector2(30, 0), Vector2(25, 10)] },
		] })
	assert_eq(data.errors, [])
	assert_true(data.zone_contains("pad", Vector3(11.5, 0.5, -2.5)))
	assert_false(data.zone_contains("pad", Vector3(12.5, 0.5, 0)), "past the box's side")
	assert_false(data.zone_contains("pad", Vector3(10, 3, 0)), "above the box")
	assert_true(data.zone_contains("roof", Vector3(4, 10, 4)), "on the roof")
	assert_false(data.zone_contains("roof", Vector3(4, 0.1, 4)), "the street under it is another floor")
	assert_true(data.zone_contains("yard", Vector3(25, 0, 3)), "a polygon with no floor range is any height")
	assert_true(data.zone_contains("yard", Vector3(25, 40, 3)))
	assert_false(data.zone_contains("yard", Vector3(21, 0, 8)), "outside the triangle")
	assert_false(data.zone_contains("no such zone", Vector3.ZERO))
	assert_eq(data.zones_at(Vector3(4, 10, 4)), ["roof"])
	assert_eq(data.zone_ids("extraction"), ["pad"])
	assert_near(data.zone_center("pad").distance_to(Vector3(10, 1, 0)), 0.0, 0.001)
	assert_near(data.zone_center("roof").distance_to(Vector3(4, 11, 4)), 0.0, 0.001)


func test_closets_serve_waves_and_have_routes() -> void:
	var data := MapData.new({
		"zombie_closets": [
			{ "id": "alley", "at": Vector3(5, 0, 5), "radius": 2.0 },
			{ "id": "garage", "at": Vector3(9, 0, 5), "radius": 2.0, "waves": [2, 3] },
		],
		"horde_routes": [{ "closet": "garage", "points": [Vector3(9, 0, 5), Vector3(9, 0, 0), Vector3(0, 0, 0)] }] })
	assert_eq(data.errors, [])
	assert_eq(data.closet_ids(1), ["alley"], "no wave list: every wave")
	assert_eq(data.closet_ids(2), ["alley", "garage"])
	assert_eq(data.route_from("garage").size(), 3)
	assert_eq(data.route_from("alley"), [], "no route: straight at the players")


func test_bounds_polygon() -> void:
	var data := MapData.new(MapAreas.CORRIDOR)
	assert_true(data.in_bounds(Vector3(0, 0, 20)), "leg A")
	assert_true(data.in_bounds(Vector3(30, 0, 0)), "leg B")
	assert_false(data.in_bounds(Vector3(20, 0, 20)), "the notch of the L")
	assert_gt(data.blocked_exits.size(), 0, "the open end is declared")
	assert_true(MapData.new({}).in_bounds(Vector3(999, 0, 999)), "no polygon: no limit")


# --- Checked against the map ------------------------------------------------------

func test_a_closet_players_can_see_is_an_error() -> void:
	var data := _with(func(d): d.zombie_closets[0].at = Vector3(0, 0.1, 8))
	assert_eq(data.errors, [])
	var problems := data.check(_map())
	assert_gt(problems.size(), 0)
	assert_true(str(problems).contains("in sight"), str(problems))


func test_things_off_the_floor_plan_are_errors() -> void:
	var problems := _with(func(d): d.player_spawns[0].at = Vector3(20, 0.1, 20)).check(_map())
	assert_true(str(problems).contains("player_spawns"), "a spawn inside the wall: " + str(problems))
	problems = _with(func(d): d.lootboxes[0].at = Vector3(-30, 0, 0)).check(_map())
	assert_true(str(problems).contains("lootboxes"), str(problems))
	problems = _with(func(d): d.zones[0].box = [Vector3(100, 1, 100), Vector3(2, 2, 2)]).check(_map())
	assert_true(str(problems).contains(MapAreas.CORRIDOR.zones[0].id), str(problems))


# --- The corridor, ported ---------------------------------------------------------

func test_game_map_reads_the_data() -> void:
	var m := _map()
	assert_eq(m.spawns.size(), Config.MAX_PLAYERS, "a spawn per player slot")
	assert_true(m.zones.has("exit"))
	assert_eq(m.zones.exit.kind, "extraction")
	assert_gt(m.objective_defs.size(), 0)
	assert_eq(m.objective_defs[m.objective_defs.size() - 1].kind, "extract")
	for i in m.spawns.size():
		for j in i:
			var a: Vector3 = m.spawns[i].at
			var b: Vector3 = m.spawns[j].at
			assert_gt(a.distance_to(b), 0.8, "players don't spawn inside each other")


func test_corridor_interactables_come_from_the_data_unchanged() -> void:
	var m := _map()
	assert_eq(m.door.iid, 1)
	assert_eq(m.door.position, Vector3(CorridorMap.DOOR_X, 0, 0))
	assert_eq(m.lootbox.iid, 2)
	assert_eq(m.lootbox.position, Vector3(CorridorMap.HALF_W - 0.6, 0, 22))
	assert_near(m.lootbox.rotation.y, -PI / 2.0, 0.001)
	assert_eq(m.interactables.size(), 5, "door, lootbox, ammo crate, two ammo boxes")
	assert_eq(m.player_spawn(), CorridorMap.PLAYER_SPAWN)


func test_each_player_slot_has_its_own_spawn() -> void:
	var m := _map()
	for slot in Config.MAX_PLAYERS:
		assert_eq(m.player_spawn_point(slot), m.spawns[slot].at)
		assert_lt(m.player_spawn_point(slot).distance_to(CorridorMap.PLAYER_SPAWN), 4.0)
	assert_eq(m.player_spawn_point(Config.MAX_PLAYERS + 3), m.spawns[3].at, "slots wrap rather than crash")
	var g := await new_game()
	assert_eq(g.players[1].slot, 0)
	g.respawn_player(1, "test")
	assert_eq(g.players[1].pos, m.spawns[0].at)
	g._add_player(7, "Guest")
	assert_eq(g.players[7].slot, 1, "the next free slot")
	assert_eq(g.players[7].pos, m.spawns[1].at)
	g._on_peer_left(7)
	g._add_player(9, "Other")
	assert_eq(g.players[9].slot, 1, "a freed slot is used again")


func test_zombies_spawn_inside_a_closet() -> void:
	var m := _map()
	var closet: Dictionary = m.data.closets[0]
	for i in 100:
		var p := m.zombie_spawn_point([])
		assert_lt(Vector2(p.x - closet.at.x, p.z - closet.at.z).length(), closet.radius + 0.001)
		assert_true(m.is_walkable(p))


func test_debug_drawing_builds() -> void:
	var node := MapData.new(MapAreas.CORRIDOR).debug_node()
	var lines: MeshInstance3D = null
	for c in node.get_children():
		if c is MeshInstance3D:
			lines = c
	assert_true(lines != null)
	assert_gt(lines.mesh.get_surface_count(), 0, "zones, closets, routes and spawns are drawn")
	node.free()
