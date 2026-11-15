extends TestCase
## The shelter map: an overrun evacuation building seen from outside, with a wrecked forecourt.

var _maps: Array[GameMap] = []


func _map() -> ShelterMap:
	var m: ShelterMap = GameMap.create("shelter")
	add_child(m.root)
	_maps.append(m)
	return m


func after_each() -> void:
	for m in _maps:
		m.root.free()
	_maps.clear()


func _count(node: Node, type_name: String) -> int:
	var n := 1 if node.is_class(type_name) else 0
	for c in node.get_children():
		n += _count(c, type_name)
	return n


func test_both_maps_come_from_the_same_factory() -> void:
	var corridor := GameMap.create("corridor")
	assert_true(corridor is CorridorGameMap)
	corridor.root.free()
	assert_true(_map() is ShelterMap)
	assert_true(GameMap.create("nonsense") == null)
	assert_true(GameMap.NAMES.has("shelter"))


func test_building_is_five_floors_and_players_start_outside_it() -> void:
	var m := _map()
	assert_eq(ShelterMap.FLOORS, 5)
	assert_gt(ShelterMap.FLOOR_H, 3.0)
	assert_near(ShelterMap.floor_y(0), 0.0, 0.001, "ground floor is at ground level")
	assert_near(ShelterMap.floor_y(4), 4 * ShelterMap.FLOOR_H, 0.001, "floor heights are fixed now so interiors can slot in")
	var spawn := m.player_spawn()
	assert_false(ShelterMap.BUILDING.has_point(Vector2(spawn.x, spawn.z)), "spawn is outside the building")
	assert_gt(spawn.z, ShelterMap.BUILDING.end.y + 20.0, "well in front of it")
	assert_false(m.nav.is_blocked(spawn))
	assert_true(m.nav.is_blocked(Vector3(ShelterMap.BUILDING.get_center().x, 0, ShelterMap.BUILDING.get_center().y)),
		"can't walk into the building yet")
	assert_true(m.outdoor)
	assert_true(m.door == null)


func test_player_spawn_points_are_all_clear() -> void:
	var m := _map()
	for i in 40:
		var p := m.player_spawn_point()
		assert_false(m.nav.is_blocked(p), "spawn %s is on open ground" % p)


func test_the_yard_is_full_of_wreckage() -> void:
	var m := _map()
	for need: Array in [["truck", 2], ["humvee", 1], ["apc", 1], ["ambulance", 1], ["bus", 1], ["car", 3],
			["helicopter", 1], ["sandbags", 6], ["barrier", 5], ["hesco", 3], ["wire", 2], ["tent", 2],
			["table", 3], ["crate", 6], ["rubble", 4], ["crater", 3], ["bodybag", 6]]:
		assert_gt(m.prop_counts.get(need[0], 0), need[1] - 1, "at least %d %s" % [need[1], need[0]])


func test_the_dead_reuse_our_character_models() -> void:
	var m := _map()
	assert_gt(m.corpses.size(), 24, "bodies everywhere")
	var kinds := {}
	var poses := {}
	var humans := 0
	for c: Dictionary in m.corpses:
		kinds[c.outfit] = true
		poses[c.pose] = true
		if not c.zombie:
			humans += 1
		assert_false(ShelterMap.BUILDING.has_point(Vector2(c.pos.x, c.pos.z)), "bodies are outside")
	assert_gt(kinds.size(), 4, "soldiers, medics, cops, civilians...")
	assert_true(kinds.has(Characters.Outfit.SOLDIER))
	assert_gt(poses.size(), 2, "face down, face up, slumped sitting")
	assert_gt(humans, 5, "some died as people, not zombies")
	assert_lt(humans, m.corpses.size(), "and some are put-down zombies")


func test_it_stays_cheap_to_draw() -> void:
	var m := _map()
	assert_lt(_count(m.root, "MeshInstance3D"), 40, "static world is a handful of merged meshes, corpses included")
	var shadows := 0
	for l in m.root.find_children("*", "Light3D", true, false):
		if (l as Light3D).shadow_enabled:
			shadows += 1
	assert_lt(shadows, 3, "at most two shadow-casting lights")


func test_layout_is_identical_every_time() -> void:
	var a := _map()
	var b := _map()
	assert_eq(a.spots.size(), b.spots.size())
	for i in a.spots.size():
		assert_eq((a.spots[i] as WeaponPickup).position, (b.spots[i] as WeaponPickup).position, "spot %d" % i)
		assert_eq((a.spots[i] as WeaponPickup).iid, (b.spots[i] as WeaponPickup).iid)
	assert_eq(a.corpses.size(), b.corpses.size())
	assert_eq(str(a.corpses[7].pos), str(b.corpses[7].pos), "every peer builds the same yard")
	var ids := {}
	for it: Interactable in a.interactables:
		assert_false(ids.has(it.iid), "interactable ids are unique")
		ids[it.iid] = true


func test_zombies_arrive_from_several_places_away_from_players() -> void:
	var m := _map()
	var player := m.player_spawn()
	var zones := {}
	for i in 80:
		var p := m.zombie_spawn_point([player])
		assert_false(m.nav.is_blocked(p), "spawn %s is on open ground" % p)
		assert_gt(p.distance_to(player), Config.SPAWN_MIN_DIST - 0.01, "not on top of the player")
		assert_true(m.nav.reachable(p, player), "and it can walk to the player from %s" % p)
		zones[Vector2i(roundi(p.x / 12.0), roundi(p.z / 12.0))] = true
	assert_gt(zones.size(), 2, "more than two directions")


func test_player_stands_on_the_ground_and_cannot_enter_the_building() -> void:
	var g := await new_game("shelter")
	await seconds(0.4)
	var p := g.local_player
	assert_near(p.global_position.y, 0.0, 0.15, "standing on the road")
	p.teleport(Vector3(10, 0.1, ShelterMap.BUILDING.end.y + 1.5))
	p.velocity = Vector3(0, 0, -20)
	for i in 30:
		p.velocity.z = -20.0
		p.move_and_slide()
	assert_gt(p.global_position.z, ShelterMap.BUILDING.end.y, "the wall is solid")


func test_zombie_paths_around_a_truck_to_reach_the_player() -> void:
	var g := await new_game("shelter")
	var m: ShelterMap = g.map
	var truck: Vector3 = m.landmarks.truck_a
	g.local_player.teleport(truck + Vector3(-4.0, 0.1, 0))
	await frames(3)
	var z := g.spawn_zombie(Zombie.Type.RUNNER, truck + Vector3(4.0, 0.1, 0))
	z.hp = 100000
	assert_false(m.is_direct(z.global_position, g.local_player.global_position), "truck is between them")
	var got_there := await wait_until(func(): return z.global_position.distance_to(g.local_player.global_position) < 2.0, 8.0)
	assert_true(got_there, "runner went around the truck (ended %.1f m away)" % z.global_position.distance_to(g.local_player.global_position))


func test_corridor_is_still_the_default_test_map() -> void:
	var g := await new_game()
	assert_eq(g.map_name, "corridor")
	assert_true(g.door != null)
