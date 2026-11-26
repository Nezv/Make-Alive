extends TestCase
## The Mirante mission, climbing up: start at the gate at the foot of Morro da Boa Vista, up the
## road through the forest (checkpoint at the hairpin), hold the summit until the helicopter
## comes, then up the tower to board it on the deck.

const S := MissionRules.Status


func _mission() -> Game:
	var g := await new_game("city", "mirante")
	return g


func _kill_all(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)


func test_the_mission_has_its_data_and_it_fits_the_map() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	assert_eq(m.data.name, "mirante")
	assert_eq(m.data.errors, [], "the dictionary is sound")
	assert_eq(m.data.check(m), [], "and it fits the hill: spawns and closets on open ground, closets out of sight")
	var kinds := m.objective_defs.map(func(o: Dictionary) -> String: return o.kind)
	assert_eq(kinds, ["reach", "reach", "survive", "extract"])
	var survive: Dictionary = m.objective_defs[2]
	assert_gt(survive.heli, 30.0, "the last wave lasts until the helicopter is down")
	assert_gt((survive.waves as Array).size(), 1)


func test_free_play_on_the_city_has_no_mission_data() -> void:
	var g := await new_game("city")
	assert_true(g.map.objective_defs.is_empty())
	assert_false(g.map.data.raw.has("heli"))


func test_everyone_starts_at_the_gate_at_the_foot() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	var gate: Vector3 = m.mirante.gate
	for slot in 8:
		var p := m.player_spawn_point(slot)
		assert_lt(Vector2(p.x, p.z).distance_to(Vector2(gate.x, gate.z)), 25.0, "slot %d starts by the gate" % slot)
		assert_false(m.nav.is_blocked(p), "slot %d stands on open ground" % slot)
		assert_lt(p.y, 20.0, "at the foot of the hill")
	assert_lt(g.local_player.global_position.distance_to(m.player_spawn_point(0)), 4.0, "the host is there")


func test_the_hairpin_is_a_checkpoint_on_the_road() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	assert_true(m.zones.has("hairpin"))
	assert_eq(m.zones.hairpin.kind, "checkpoint")
	var c := m.data.zone_center("hairpin")
	assert_eq(m.type_at(c), CityMap.STREET)
	var on_road := Vector3(c.x, m.ground_y(c) + 0.1, c.z)
	assert_true(m.data.zone_contains("hairpin", on_road), "someone standing on the road there is in it")


func test_the_way_out_is_the_tower_deck_and_the_helicopter_comes_beside_it() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	var deck: Vector3 = m.mirante.deck
	assert_true(m.data.zone_contains("deck", deck + Vector3(2.0, 0.1, 2.0)), "standing on the deck counts")
	assert_false(m.data.zone_contains("deck", (m.mirante.tower as Vector3) + Vector3(5, 0.1, 0)), "standing at the tower's foot does not")
	var heli: Dictionary = m.data.raw.heli
	var at: Vector3 = heli.at
	assert_gt(at.y, deck.y, "it hangs level with the deck")
	assert_lt(at.y - deck.y, 3.0)
	var off := Vector2(at.x - deck.x, at.z - deck.z).length()
	assert_gt(off, MiranteSet.TOWER_HALF + 1.5, "beside the tower, not on it")
	assert_lt(off, MiranteSet.TOWER_HALF + 6.0, "close enough to step aboard")


func test_the_whole_climb_from_gate_to_helicopter() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	g.set_physics_process(false)
	var calls := spy(g)
	var me: Dictionary = g.players[1]
	assert_eq(g.rules.current().id, "hairpin")
	var hairpin := m.data.zone_center("hairpin")
	me.pos = Vector3(hairpin.x, m.ground_y(hairpin) + 0.1, hairpin.z)
	g.rules.step(0.1)
	assert_eq(count(calls, &"on_checkpoint_reached"), 1, "the hairpin is a checkpoint")
	assert_eq(g.rules.current().id, "summit")
	var top := m.poi_pos("mirante")
	me.pos = top + Vector3(0, 0.1, 0)
	g.rules.step(0.1)
	assert_eq(g.rules.current().kind, "survive", "hold the summit")
	var waves: int = (g.rules.current().waves as Array).size()
	for i in 60:
		g.rules.step(0.5)
		_kill_all(g)
		g.rules.step(30.0) # past any calm
		if g.rules.heli_left >= 0.0:
			break
	assert_gt(g.rules.heli_left, 0.0, "after %d waves the helicopter is on its way" % waves)
	assert_true(g.mission_view.heli)
	await seconds(0.2)
	assert_true(g.heli != null, "it is seen coming")
	assert_lt(g.heli_flight.lz.distance_to(m.data.raw.heli.at), 0.01, "to its spot beside the deck")
	for i in 40:
		g.rules.step(5.0)
		_kill_all(g)
		if g.rules.current().kind == "extract":
			break
	assert_eq(g.rules.current().kind, "extract", "down: up the tower to board it")
	me.pos = (m.mirante.deck as Vector3) + Vector3(1.5, 0.1, 1.5)
	for i in 20:
		g.rules.step(0.5)
	assert_eq(g.rules.status, S.WON, "everyone aboard: extracted")
