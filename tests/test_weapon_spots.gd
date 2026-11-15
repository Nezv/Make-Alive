extends TestCase
## Guns lying around the shelter yard: a random few of the possible spots each match.


func _active(m: ShelterMap) -> Array:
	return m.spots.filter(func(s: WeaponPickup) -> bool: return s.weapon >= 0)


func test_there_are_spots_in_trucks_on_corpses_and_on_tables() -> void:
	var m: ShelterMap = GameMap.create("shelter")
	add_child(m.root)
	assert_gt(m.spots.size(), 13, "plenty of candidate spots")
	var kinds := {}
	for s: WeaponPickup in m.spots:
		kinds[s.kind] = kinds.get(s.kind, 0) + 1
		assert_eq(s.weapon, -1, "empty until the host rolls")
		assert_true(m.nav.reachable(m.player_spawn(), s.stand), "%s spot at %s can be walked to" % [s.kind, s.position])
		assert_false(m.nav.is_blocked(s.stand), "you can stand next to it")
		var eye := s.stand + Vector3(0, Config.EYE_HEIGHT, 0)
		assert_lt(eye.distance_to(s.position), Config.INTERACT_RANGE - 0.2, "%s spot is within arm's reach" % s.kind)
	for kind in ["truck", "corpse", "table"]:
		assert_gt(kinds.get(kind, 0), 1, "at least two %s spots" % kind)
	m.root.free()


func test_each_match_a_random_few_spots_hold_a_random_gun() -> void:
	var m: ShelterMap = GameMap.create("shelter")
	add_child(m.root)
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
	m.root.free()


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


func test_shelter_players_start_with_only_the_pistol() -> void:
	var g := await new_game("shelter")
	assert_eq(g.local_player.weapons.current, Weapons.P19)
	assert_eq(g.local_player.owned.keys(), [Weapons.P19])
	g.local_player.switch_weapon(Weapons.AK47)
	assert_eq(g.local_player.weapons.current, Weapons.P19, "can't switch to a gun you haven't found")
	g._queue_shot(1, Vector3(0, 1.6, 30), Vector3.FORWARD, Weapons.AK47)
	assert_eq(g._pending_shots.size(), 0, "host refuses shots from a gun you don't own")
	g._queue_shot(1, Vector3(0, 1.6, 30), Vector3.FORWARD, Weapons.P19)
	assert_eq(g._pending_shots.size(), 1)
	assert_eq(_active(g.map).size(), Config.WEAPON_SPOTS_ACTIVE, "host rolled the loot")


func test_right_click_takes_the_gun() -> void:
	var g := await new_game("shelter")
	var calls := spy(g)
	var spot: WeaponPickup = _active(g.map)[0]
	var weapon := spot.weapon
	assert_false(g.host_interact(1, spot.iid) and count(calls, &"on_weapon_picked_up") > 0, "too far away at spawn")
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
	g._queue_shot(1, Vector3(0, 1.6, 30), Vector3.FORWARD, weapon)
	assert_eq(g._pending_shots.size(), 1, "now the host accepts its shots")


func test_corridor_players_keep_every_gun() -> void:
	var g := await new_game()
	assert_eq(g.local_player.owned.size(), Weapons.COUNT)
	assert_eq(g.local_player.weapons.current, Weapons.DEFAULT)
