extends TestCase
## The ways to play a city match (GameModes): extraction, defense, open world.

const S := MissionRules.Status


func test_extraction_runs_from_the_start_to_a_way_out_on_a_street() -> void:
	var g := await new_game("city", "terminal", false, "extraction")
	g.set_physics_process(false)
	var map := g.map as CityMap
	assert_true(map.zones.has("halfway") and map.zones.has("way_out"), "the mode's zones")
	var start := map.player_spawn()
	var out := map.data.zone_center("way_out")
	var d := Vector2(out.x - start.x, out.z - start.z).length()
	assert_true(d > Config.MODE_EXTRACT_DIST * 0.6 and d < Config.MODE_EXTRACT_DIST + Config.MODE_STREET_SEARCH + 10.0, "the way out is %.0f m off" % d)
	assert_true([CityMap.STREET, CityMap.SQUARE].has(map.type_at(out)), "the way out stands on a street")
	assert_eq(g.rules.status, S.RUNNING)
	assert_eq(g.rules.current().id, "halfway")
	g.players[1].pos = map.data.zone_center("halfway")
	g.rules.step(0.1)
	assert_eq(g.rules.current().id, "way_out", "the checkpoint reached")
	assert_eq(g.rules.checkpoint, "halfway", "the dead come back there")
	g.players[1].pos = out
	for i in ceili(Config.MODE_EXTRACT_HOLD / 0.5) + 2:
		g.rules.step(0.5)
	assert_eq(g.rules.status, S.WON, "held the way out")


func test_defense_holds_the_start_through_waves_until_the_helicopter() -> void:
	var g := await new_game("city", "prefeitura", false, "defense")
	g.set_physics_process(false)
	var o: Dictionary = g.rules.current()
	assert_eq(o.kind, "survive")
	assert_eq((o.waves as Array).size(), 3)
	assert_eq(float(o.heli), Config.MODE_DEFENSE_HELI)
	assert_true(g.map.data.zone_contains("stand", g.map.player_spawn() + Vector3(0, 1, 0)), "the stand is round the start")
	assert_eq(g.rules.objectives[-1].kind, "extract", "then everyone to the helicopter")
	assert_eq(g.welcome_rules().mode, "defense", "joiners are told the mode")


func test_open_world_clock_turns_day_into_night_and_the_seventh_is_a_horde_night() -> void:
	var c := OpenWorld.cycle()
	assert_eq(OpenWorld.at(0.0)[1], 0, "it starts in the morning")
	assert_eq(OpenWorld.at(c * 2.0 + 1.0)[0], 3, "day 3")
	var night_at := 0.0
	for i in Config.OPEN_PHASES.size():
		if Config.OPEN_PHASES[i][0] == "night":
			break
		night_at += float(Config.OPEN_PHASES[i][2])
	assert_eq(Config.OPEN_PHASES[OpenWorld.at(night_at + 1.0)[1]][0], "night")
	assert_true(OpenWorld.is_horde_night(Config.OPEN_HORDE_NIGHT) and not OpenWorld.is_horde_night(1))
	var g := await new_game("city", "", false, "open_world")
	assert_true(g.open_world != null, "the clock runs")
	assert_true(g.rules.objectives.is_empty(), "no objective")
	assert_eq(g.rules.respawn_after, Config.OPEN_RESPAWN, "the dead come back after a while")
	g.open_world.step(0.0)
	assert_false(g.director.enabled, "the town is quiet by day")
	g.open_world.clock = c * (Config.OPEN_HORDE_NIGHT - 1) + night_at + 1.0
	g.open_world.step(0.0)
	assert_eq(g.open_world.day, Config.OPEN_HORDE_NIGHT)
	assert_true(g.director.enabled, "the night brings them")
	assert_true(g.open_world.text(OpenWorld.at(g.open_world.clock)).contains("HORDE NIGHT"))
	g.open_world.step(6.0)
	assert_true(g.zombies.size() > 0, "a horde night's first wave")
	assert_eq(g.welcome_rules().get("open_clock", -1.0), g.open_world.clock, "joiners get the clock")
