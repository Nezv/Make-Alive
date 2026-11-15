extends TestCase
## Guns lying in the city's set pieces (Scenery): a random few of the possible spots each match.

static var _shared: CityMap


func _map() -> CityMap:
	if _shared == null:
		_shared = GameMap.create("city") # not in the tree: spots' `position` is their place in the world
	return _shared


static func after_all() -> void:
	if _shared != null:
		_shared.root.free()
		_shared = null


func _active(m: GameMap) -> Array:
	return m.spots.filter(func(s: WeaponPickup) -> bool: return s.weapon >= 0)


func test_the_set_pieces_hold_spots_in_vehicles_on_corpses_and_on_tables() -> void:
	var m := _map()
	assert_gt(m.spots.size(), Config.WEAPON_SPOTS_ACTIVE, "more spots than guns, so it varies")
	var kinds := {}
	var start := m.player_spawn()
	for s: WeaponPickup in m.spots:
		kinds[s.kind] = kinds.get(s.kind, 0) + 1
		assert_true(m.interactables.has(s), "spot %d is an interactable" % s.iid)
		assert_true(m.contains(s.position), "spot at %s is inside the map" % s.position)
		var eye := s.stand + Vector3(0, Config.EYE_HEIGHT, 0)
		assert_lt(eye.distance_to(s.position), Config.INTERACT_RANGE - 0.2, "%s spot is within arm's reach" % s.kind)
		var near := m.nav.nearest_free(s.stand)
		assert_true(m.nav.reachable(start, near), "%s spot at %s can be walked to" % [s.kind, s.position])
	for kind in ["truck", "vehicle", "corpse", "table"]:
		assert_gt(kinds.get(kind, 0), 0, "a %s spot" % kind)
	var ids := {}
	for it: Interactable in m.interactables:
		assert_false(ids.has(it.iid), "interactable ids are unique")
		ids[it.iid] = true


func test_the_kit_s_pieces_are_all_in_the_city() -> void:
	var m := _map()
	for kind in ["helicopter", "truck", "humvee", "apc", "ambulance", "tent", "car", "sandbags", "booth"]:
		assert_gt(m.prop_counts.get(kind, 0), 0, "a %s in the streets" % kind)
	for id: String in CityData.POIS:
		assert_true(m.nav.reachable(m.player_spawn(), m.poi_pos(id)), "the wrecks don't cut off %s" % id)


func test_each_match_a_random_few_spots_hold_a_random_gun() -> void:
	var m := _map()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	m.roll_weapons(rng)
	var first := _active(m).map(func(s: WeaponPickup) -> String: return "%d:%d" % [s.iid, s.weapon])
	assert_eq(first.size(), Config.WEAPON_SPOTS_ACTIVE)
	for s: WeaponPickup in _active(m):
		assert_true(Weapons.valid(s.weapon))
		assert_true(s.weapon != Weapons.P19, "everyone already has the pistol")
		assert_true(s.gun != null, "the gun is lying there to be seen")
	rng.seed = 1
	m.roll_weapons(rng)
	assert_eq(_active(m).map(func(s: WeaponPickup) -> String: return "%d:%d" % [s.iid, s.weapon]), first, "same seed, same loot")
	var differs := false
	for seed_value in [2, 3, 4]:
		rng.seed = seed_value
		m.roll_weapons(rng)
		assert_eq(_active(m).size(), Config.WEAPON_SPOTS_ACTIVE)
		if _active(m).map(func(s: WeaponPickup) -> String: return "%d:%d" % [s.iid, s.weapon]) != first:
			differs = true
	assert_true(differs, "another match, other spots")


func test_pickup_state_travels_to_other_peers() -> void:
	var host := WeaponPickup.new()
	var client := WeaponPickup.new()
	add_child(host)
	add_child(client)
	host.set_weapon(Weapons.SPAS12)
	client.apply_state(host.get_state())
	assert_eq(client.weapon, Weapons.SPAS12)
	assert_true(client.gun != null)
	assert_true(client.prompt().contains("SPAS-12"))
	host.take()
	client.apply_state(host.get_state())
	assert_eq(client.weapon, -1)
	assert_true(client.gun == null, "gone for everyone")
	assert_eq(client.prompt(), "")
	host.free()
	client.free()


## On a map where you must find guns (all_weapons off): only the pistol until you pick one up.
func test_right_click_takes_the_gun_and_the_host_then_accepts_its_shots() -> void:
	var g := await new_game("city")
	g.map.all_weapons = false
	g.players[1].owned = { Weapons.P19: true }
	g.local_player.set_loadout({ Weapons.P19: true })
	var calls := spy(g)
	var spot: WeaponPickup = _active(g.map)[0]
	var weapon := spot.weapon
	var from := g.local_player.global_position + Vector3(0, 1.6, 0)
	g._queue_shot(1, from, Vector3.FORWARD, weapon)
	assert_eq(g._pending_shots.size(), 0, "host refuses shots from a gun you don't have")
	g.local_player.teleport(spot.stand + Vector3(0, 0.1, 0))
	await frames(3)
	assert_true(g.host_interact(1, spot.iid))
	assert_eq(count(calls, &"on_right_click_weapon"), 1)
	assert_eq(count(calls, &"on_weapon_picked_up"), 1)
	assert_true(g.players[1].owned.has(weapon), "host knows you have it")
	assert_true(g.local_player.owned.has(weapon))
	assert_eq(g.local_player.weapons.current, weapon, "and it's in your hands")
	assert_eq(spot.weapon, -1, "spot is empty now")
	g.host_interact(1, spot.iid)
	assert_eq(count(calls, &"on_weapon_picked_up"), 1, "nothing left to take")
	g._queue_shot(1, from, Vector3.FORWARD, weapon)
	assert_eq(g._pending_shots.size(), 1, "now the host accepts its shots")


func test_corridor_players_keep_every_gun() -> void:
	var g := await new_game()
	assert_eq(g.local_player.owned.size(), Weapons.COUNT)
	assert_eq(g.local_player.weapons.current, Weapons.DEFAULT)
