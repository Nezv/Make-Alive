extends TestCase
## Mission-side gameplay hooks. Most are only declared for now: the steps that build objectives,
## extraction, downed players and noise call them. What matters here is that they exist, take the
## arguments the plan promises, and show up in `spy(g)`.


func test_every_mission_hook_reaches_the_spy() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.hooks.on_mission_started("mirante")
	g.hooks.on_objective_reached("roof", 1)
	g.hooks.on_extraction_ready("helipad")
	g.hooks.on_extracted([1])
	g.hooks.on_mission_failed("everyone died")
	g.hooks.on_checkpoint_reached("halfway")
	g.hooks.on_player_downed(1)
	g.hooks.on_player_revived(1, 2)
	g.hooks.on_noise(Vector3(1, 0, 2), 30.0, 1)
	for hook: StringName in [&"on_mission_started", &"on_objective_reached", &"on_extraction_ready", &"on_extracted",
			&"on_mission_failed", &"on_checkpoint_reached", &"on_player_downed", &"on_player_revived", &"on_noise"]:
		assert_eq(count(calls, hook), 1, str(hook))
	assert_eq(calls[1][1], ["roof", 1], "objective id and who reached it")
	assert_eq(calls[8][1], [Vector3(1, 0, 2), 30.0, 1], "noise: where, how loud, who")


func test_hosting_a_mission_fires_on_mission_started() -> void:
	var g := Game.new()
	g.map_name = "corridor"
	g.mission = "terminal"
	add_child(g)
	_games.append(g)
	var calls := spy(g)
	g.start_host("Tester")
	g.director.enabled = false
	assert_eq(count(calls, &"on_mission_started"), 1)
	assert_eq(calls[calls.size() - 1][1], ["terminal"])


func test_free_play_starts_no_mission() -> void:
	var g := Game.new()
	g.map_name = "corridor"
	add_child(g)
	_games.append(g)
	var calls := spy(g)
	g.start_host("Tester")
	g.director.enabled = false
	assert_eq(count(calls, &"on_mission_started"), 0)
