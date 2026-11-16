extends TestCase
## Defending: waves from the map's data (size, types, closets, the calm between), growing with
## the number of players, the last wave lasting until the helicopter is down, the HUD and the siren.

const S := MissionRules.Status


func _defend(waves: Array, heli := 0.0) -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	var o := { "id": "hold_out", "kind": "survive", "zone": "", "seconds": 0.0, "waves": waves, "text": "Hold out",
		"who": "any", "target": -1, "time_limit": 0.0, "heli": heli }
	g.rules.start([MapData.new({ "objectives": [o] }).objectives[0]])
	return g


func _kill_all(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)


func _types(g: Game) -> Dictionary:
	var out := {}
	for z: Zombie in g.zombies.values():
		out[z.type] = out.get(z.type, 0) + 1
	return out


func test_map_data_reads_waves_as_sizes_or_as_full_entries() -> void:
	var d := MapData.new({ "name": "t",
		"zombie_closets": [{ "id": "a", "at": Vector3.ZERO }, { "id": "b", "at": Vector3(5, 0, 0) }],
		"objectives": [{ "id": "o", "kind": "survive", "heli": 90.0, "waves": [
			6, { "size": 10, "types": { "runner": 1.0 }, "closets": ["b"], "gap": 12.0 }] }] })
	assert_eq(d.errors, [])
	var waves: Array = d.objectives[0].waves
	assert_eq(waves[0].size, 6)
	assert_eq(waves[0].gap, Config.WAVE_GAP, "the default calm")
	assert_eq(waves[0].types, {})
	assert_eq(waves[1].closets, ["b"])
	assert_eq(waves[1].gap, 12.0)
	assert_eq(waves[1].types, { "runner": 1.0 })
	assert_eq(d.objectives[0].heli, 90.0)
	var bad := MapData.new({ "name": "t", "zombie_closets": [{ "id": "a", "at": Vector3.ZERO }],
		"objectives": [{ "id": "o", "kind": "survive", "waves": [{ "size": 4, "closets": ["nope"], "types": { "brute": 1.0 } }] }] })
	assert_eq(bad.errors.size(), 2, str(bad.errors))


func test_each_wave_waits_for_the_last_to_die_then_a_calm_with_a_countdown() -> void:
	var g := await _defend([3, { "size": 4, "gap": 5.0 }])
	var calls := spy(g)
	g.rules.step(0.1)
	assert_eq(g.zombies.size(), 3, "the first wave comes at once")
	assert_eq(g.mission_view.wave, 1)
	_kill_all(g)
	g.rules.step(0.1)
	assert_eq(g.zombies.size(), 0)
	assert_true(g.mission_view.calm, "a calm between waves")
	assert_near(g.rules.seconds_left(), 5.0, 0.15)
	assert_true(g.mission_view.counting, "its countdown runs on every peer")
	g.rules.step(4.0)
	assert_eq(g.zombies.size(), 0, "still calm")
	g.rules.step(1.1)
	assert_eq(g.zombies.size(), 4, "second wave")
	assert_eq(g.mission_view.wave, 2)
	assert_false(g.mission_view.calm)
	_kill_all(g)
	g.rules.step(0.1)
	assert_eq(g.rules.status, S.WON, "no helicopter: the last wave cleared is the end")
	assert_eq(count(calls, &"on_horde_incoming"), 2)


func test_a_wave_brings_the_types_it_lists() -> void:
	var g := await _defend([{ "size": 8, "types": { "runner": 1.0 } }])
	g.rules.step(0.1)
	assert_eq(_types(g), { Zombie.Type.RUNNER: 8 })


func test_waves_come_from_more_closets_as_they_go() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g.map.data = MapData.new({ "name": "t", "zombie_closets": [
		{ "id": "a", "at": Vector3(40, 0.1, 0), "radius": 0.5 }, { "id": "b", "at": Vector3(30, 0.1, 0), "radius": 0.5 },
		{ "id": "c", "at": Vector3(20, 0.1, 0), "radius": 0.5 }] })
	var o: Dictionary = MapData.new({ "objectives": [{ "id": "o", "kind": "survive", "waves": [6, { "size": 6, "gap": 0.1 }, { "size": 6, "gap": 0.1 }] }] }).objectives[0]
	g.rules.start([o])
	var seen := []
	for w in 3:
		g.rules.step(0.2)
		g.rules.step(0.2)
		var near := {}
		for z: Zombie in g.zombies.values():
			near[roundi(z.global_position.x / 10.0)] = true
		seen.append(near.size())
		_kill_all(g)
		g.rules.step(0.05)
	assert_eq(seen, [1, 2, 3], "one way in, then two, then three")


func test_waves_grow_with_the_players_alive() -> void:
	var g := await _defend([10])
	assert_eq(g.rules.wave_size(10), 10)
	g._add_player(7, "Guest")
	g._add_player(8, "Guest 2")
	assert_eq(g.rules.wave_size(10), roundi(10 * (1.0 + 2 * Config.WAVE_PER_PLAYER)))
	g.rules.set_out(8, true)
	assert_eq(g.rules.wave_size(10), roundi(10 * (1.0 + Config.WAVE_PER_PLAYER)), "only the living count")


func test_the_last_wave_keeps_coming_until_the_helicopter_is_down() -> void:
	var g := await _defend([2, { "size": 4, "gap": 0.5 }], 20.0)
	var calls := spy(g)
	g.rules.step(0.1)
	_kill_all(g)
	g.rules.step(0.1)
	g.rules.step(0.6)
	assert_eq(g.mission_view.wave, 2)
	assert_true(g.mission_view.heli, "the helicopter is on its way")
	assert_near(g.rules.seconds_left(), 20.0, 0.2)
	_kill_all(g)
	g.rules.step(Config.LAST_WAVE_TOPUP + 0.1)
	assert_gt(g.zombies.size(), 0, "killing them all does not end it: more come")
	assert_true(g.rules.running())
	for i in 30:
		g.rules.step(0.5)
		assert_true(g.zombies.size() <= g.rules.wave_size(4), "topped up, never beyond the wave")
	assert_true(g.rules.running(), "15 s in: still waiting")
	g.rules.step(5.5)
	assert_eq(g.rules.status, S.WON, "the helicopter is down")
	assert_eq(count(calls, &"on_objective_reached"), 1)


func test_the_hud_shows_the_wave_whats_left_and_the_clocks() -> void:
	var g := await _defend([3, { "size": 4, "gap": 8.0 }], 90.0)
	g.rules.step(0.1)
	g._process(0.0)
	var text := g.hud.objective_label.text
	assert_true(text.contains("Wave 1/2"), text)
	assert_true(text.contains("3 left"), text)
	_kill_all(g)
	g.rules.step(0.1)
	g._process(0.0)
	text = g.hud.objective_label.text
	assert_true(text.to_lower().contains("next wave"), text)
	assert_true(text.contains("0:08"), text)
	g.rules.step(8.1)
	g._process(0.0)
	text = g.hud.objective_label.text
	assert_true(text.contains("Wave 2/2"), text)
	assert_true(text.to_lower().contains("helicopter 1:30"), text)


func test_a_siren_sounds_at_each_wave_start_on_every_peer() -> void:
	var g := await _defend([2, { "size": 2, "gap": 0.2 }])
	assert_true(Sfx.stream("siren") != null)
	var played: int = Sfx.stats.played
	g.rules.step(0.1)
	assert_eq(Sfx.stats.played, played + 1, "wave 1")
	_kill_all(g)
	g.rules.step(0.1)
	assert_eq(Sfx.stats.played, played + 1, "the calm is quiet")
	g.rules.step(0.3)
	assert_eq(Sfx.stats.played, played + 2, "wave 2")
	Sfx.reset()
