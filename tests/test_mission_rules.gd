extends TestCase
## The mission's rules on the host: the objective list of the map's data run in order, the hooks
## it fires, how it fails, and what every peer is told.

const S := MissionRules.Status
const CORNER := Vector3(0, 0.1, 0)   ## inside the corridor's "corner" zone
const EXIT := Vector3(31, 0.1, 0)    ## inside its "exit" zone
const NOWHERE := Vector3(0, 0.1, 20) ## in neither


func _objective(kind: String, more := {}) -> Dictionary:
	var o := { "id": kind, "kind": kind, "zone": "", "seconds": 0.0, "waves": [], "text": "Do the %s" % kind,
		"who": "any", "target": -1, "time_limit": 0.0 }
	o.merge(more, true)
	return o


## A corridor match frozen in time: the test moves the players and steps the rules itself.
func _frozen(defs: Array, respawn := true) -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	g.players[1].pos = NOWHERE
	g.rules.start(defs, respawn)
	return g


func _guest(g: Game, id := 7) -> void:
	g._add_player(id, "Guest")
	g.players[id].pos = NOWHERE


func test_the_corridor_runs_its_own_small_list() -> void:
	var g := await new_game()
	assert_true(g.rules.running())
	assert_eq(g.rules.objectives.size(), MapAreas.CORRIDOR.objectives.size())
	assert_eq(g.rules.index, 0)
	assert_eq(g.rules.current().id, "reach_corner")
	assert_eq(g.mission_view.text, "Get to the corner")
	g._process(0.0)
	assert_true(g.hud.objective_label.text.contains("Get to the corner"), g.hud.objective_label.text)
	assert_eq(MapData.new(MapAreas.CORRIDOR).errors, [])


func test_a_map_with_no_objectives_is_free_play() -> void:
	var g := await _frozen([])
	assert_false(g.rules.running())
	assert_eq(g.rules.status, S.IDLE)
	g.rules.step(1.0)
	assert_eq(g.mission_view.text, "")
	g._process(0.0)
	assert_eq(g.hud.objective_label.text, "")


func test_reaching_a_zone_completes_it_and_moves_on() -> void:
	var g := await _frozen([_objective("reach", { "id": "a", "zone": "corner" }), _objective("extract", { "id": "b", "zone": "exit", "seconds": 2.0 })])
	var calls := spy(g)
	g.rules.step(0.1)
	assert_eq(g.rules.index, 0, "nobody there yet")
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_eq(g.rules.index, 1)
	assert_eq(count(calls, &"on_objective_reached"), 1)
	assert_eq(calls[0], [&"on_objective_reached", ["a", 1]])
	assert_eq(count(calls, &"on_checkpoint_reached"), 1, "the corner is a checkpoint zone")
	assert_eq(calls[1][1], ["corner"])
	assert_eq(count(calls, &"on_extraction_ready"), 1, "the next objective is the way out")
	assert_eq(calls[2][1], ["exit"])
	assert_eq(g.mission_view.id, "b")


func test_reach_all_waits_for_every_player_still_in_the_fight() -> void:
	var g := await _frozen([_objective("reach", { "zone": "corner", "who": "all" })])
	_guest(g)
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_true(g.rules.running(), "the guest is not there")
	g.rules.set_out(7, true)
	g.rules.step(0.1)
	assert_eq(g.rules.status, S.WON, "a player who is out is not waited for")


func test_hold_counts_only_while_someone_is_inside() -> void:
	var g := await _frozen([_objective("hold", { "zone": "corner", "seconds": 3.0 })])
	var calls := spy(g)
	g.rules.step(1.0)
	assert_eq(g.rules.progress, 0.0)
	assert_false(g.mission_view.counting)
	g.players[1].pos = CORNER
	g.rules.step(1.0)
	g.rules.step(1.0)
	assert_near(g.rules.progress, 2.0, 0.001)
	assert_true(g.mission_view.counting, "peers are told the clock is running")
	assert_near(g.rules.seconds_left(), 1.0, 0.001)
	g.players[1].pos = NOWHERE
	g.rules.step(5.0)
	assert_near(g.rules.progress, 2.0, 0.001, "leaving pauses it, it does not start over")
	assert_false(g.mission_view.counting)
	assert_near(g.mission_view.left, 1.0, 0.001)
	g.players[1].pos = CORNER
	g.rules.step(1.1)
	assert_eq(g.rules.status, S.WON)
	assert_eq(count(calls, &"on_objective_reached"), 1)


func test_extract_needs_everyone_alive_inside_and_names_who_got_out() -> void:
	var g := await _frozen([_objective("extract", { "zone": "exit", "seconds": 2.0 })])
	var calls := spy(g)
	_guest(g)
	g.players[1].pos = EXIT
	g.rules.step(1.0)
	assert_eq(g.rules.progress, 0.0, "one is still outside")
	g.players[7].pos = EXIT
	g.rules.step(1.5)
	g.players[7].pos = NOWHERE
	g.rules.step(1.5)
	assert_true(g.rules.running(), "stepping out paused it")
	g.players[7].pos = EXIT
	g.rules.step(0.6)
	assert_eq(g.rules.status, S.WON)
	assert_eq(count(calls, &"on_extracted"), 1)
	var who: Array = calls[-1][1][0]
	who.sort()
	assert_eq(who, [1, 7])
	assert_eq(g.mission_view.status, S.WON)


func test_survive_sends_its_waves_one_after_the_other() -> void:
	var g := await _frozen([_objective("survive", { "waves": [2, 3] })])
	var calls := spy(g)
	g.rules.step(0.1)
	assert_eq(g.zombies.size(), 2, "first wave")
	assert_eq(g.rules.wave, 1)
	g.rules.step(0.1)
	assert_eq(g.zombies.size(), 2, "the next one waits for these")
	_kill_all(g)
	g.rules.step(0.1)
	assert_eq(g.zombies.size(), 3, "second wave")
	assert_true(g.rules.running())
	_kill_all(g)
	g.rules.step(0.1)
	assert_eq(g.rules.status, S.WON)
	assert_eq(count(calls, &"on_horde_incoming"), 2)


func _kill_all(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)


func test_survive_can_also_be_a_stretch_of_time() -> void:
	var g := await _frozen([_objective("survive", { "seconds": 10.0 })])
	g.rules.step(4.0)
	assert_true(g.rules.running())
	assert_near(g.rules.seconds_left(), 6.0, 0.001)
	assert_true(g.mission_view.counting)
	g.rules.step(6.1)
	assert_eq(g.rules.status, S.WON)


func test_interact_waits_for_a_right_click_on_its_thing() -> void:
	var g := await _frozen([_objective("interact", { "target": g_lootbox_iid() })])
	var calls := spy(g)
	g.rules.step(1.0)
	assert_true(g.rules.running())
	assert_true(g.mission_view.has_marker, "the marker is on the thing")
	assert_lt((g.mission_view.marker as Vector3).distance_to(g.lootbox.global_position), 0.01)
	g.players[1].pos = g.door.global_position
	g.host_interact(1, g.door.iid)
	assert_true(g.rules.running(), "the wrong thing")
	g.players[1].pos = g.lootbox.global_position
	assert_true(g.host_interact(1, g.lootbox.iid))
	assert_eq(g.rules.status, S.WON)
	var reached := calls.filter(func(c: Array) -> bool: return c[0] == &"on_objective_reached")
	assert_eq(reached[0][1], ["interact", 1])


func g_lootbox_iid() -> int:
	return MapAreas.CORRIDOR.lootboxes[0].iid


func test_a_time_limit_fails_the_mission() -> void:
	var g := await _frozen([_objective("reach", { "zone": "corner", "time_limit": 5.0 })])
	var calls := spy(g)
	g.rules.step(4.0)
	assert_true(g.rules.running())
	assert_near(g.rules.seconds_left(), 1.0, 0.001)
	assert_true(g.mission_view.counting, "a limit always runs")
	g.rules.step(1.5)
	assert_eq(g.rules.status, S.FAILED)
	assert_eq(g.rules.reason, "out of time")
	assert_eq(count(calls, &"on_mission_failed"), 1)
	assert_eq(calls[-1][1], ["out of time"])
	g.players[1].pos = CORNER
	g.rules.step(1.0)
	assert_eq(g.rules.status, S.FAILED, "too late")
	assert_eq(count(calls, &"on_objective_reached"), 0)
	assert_eq(g.mission_view.status, S.FAILED)
	assert_eq(g.mission_view.reason, "out of time")


func test_everyone_out_fails_the_mission() -> void:
	var g := await _frozen([_objective("reach", { "zone": "corner" })], false)
	var calls := spy(g)
	_guest(g)
	g.rules.set_out(1, true)
	assert_true(g.rules.running(), "one is still standing")
	g.rules.set_out(1, false)
	g.rules.set_out(7, true)
	g.rules.set_out(1, true)
	assert_eq(g.rules.status, S.FAILED)
	assert_eq(count(calls, &"on_mission_failed"), 1)
	assert_eq(calls[-1][1], ["everyone is down"])


func test_without_respawn_the_dead_are_out_and_zombies_leave_them() -> void:
	var g := await _frozen([_objective("reach", { "zone": "corner" })], false)
	var calls := spy(g)
	_guest(g)
	g.players[7].pos = Vector3(0, 0.1, 10)
	g.damage_player(1, 100000)
	assert_eq(count(calls, &"on_player_died"), 1)
	assert_true(g.rules.out.has(1))
	assert_true(g.rules.running(), "the guest lives")
	assert_eq(g.nearest_player(g.players[1].pos), 7, "zombies go for the living")
	g.damage_player(7, 100000)
	assert_eq(g.rules.status, S.FAILED)


func test_with_respawn_the_dead_come_back_and_nothing_fails() -> void:
	var g := await _frozen([_objective("reach", { "zone": "corner" })])
	g.damage_player(1, 100000)
	assert_false(g.rules.out.has(1))
	assert_true(g.rules.running())
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP, "respawned")


func test_peers_get_the_state_on_change_and_late_joiners_in_welcome() -> void:
	var g := await _frozen([_objective("hold", { "id": "h", "zone": "corner", "seconds": 90.0, "text": "Hold the corner" })])
	var state := g.rules.state()
	assert_eq(state.index, 0)
	assert_eq(state.id, "h")
	assert_eq(state.text, "Hold the corner")
	assert_eq(state.status, S.RUNNING)
	assert_true(state.has_marker)
	assert_eq(state.marker, g.map.data.zone_center("corner"))
	assert_eq(g.welcome_rules().mission, state, "what a late joiner is sent")
	# A client: it is told once, then counts the clock down on its own.
	var told := state.duplicate()
	told.left = 75.0
	told.counting = true
	g.mission_state(told)
	g._process(0.0)
	assert_true(g.hud.objective_label.text.contains("Hold the corner"))
	assert_true(g.hud.objective_label.text.contains("1:15"), g.hud.objective_label.text)
	g._tick_mission_view(10.0)
	g._process(0.0)
	assert_true(g.hud.objective_label.text.contains("1:05"), g.hud.objective_label.text)
	told.counting = false
	g.mission_state(told)
	g._tick_mission_view(10.0)
	assert_near(g.mission_view.left, 75.0, 0.001, "paused: it stays put")
	told.status = S.FAILED
	told.reason = "out of time"
	g.mission_state(told)
	g._process(0.0)
	assert_true(g.hud.objective_label.text.to_lower().contains("failed"), g.hud.objective_label.text)


func test_map_data_reads_and_checks_the_objective_details() -> void:
	var d := MapData.new({ "name": "t", "respawn": false,
		"zones": [{ "id": "z", "kind": "trigger", "box": [Vector3.ZERO, Vector3.ONE] }],
		"doors": [{ "iid": 4, "at": Vector3.ZERO }],
		"objectives": [
			{ "id": "a", "kind": "reach", "zone": "z", "who": "all", "time_limit": 60.0 },
			{ "id": "b", "kind": "interact", "target": 4 },
		] })
	assert_eq(d.errors, [])
	assert_false(d.respawn)
	assert_eq(d.objectives[0].who, "all")
	assert_eq(d.objectives[0].time_limit, 60.0)
	assert_eq(d.objectives[1].target, 4)
	assert_eq(d.objectives[1].who, "any", "the default")
	assert_true(MapData.new({}).respawn, "the dead come back unless the data says otherwise")
	var bad := MapData.new({ "name": "t", "objectives": [
		{ "id": "a", "kind": "reach", "who": "some" },
		{ "id": "b", "kind": "interact", "target": 99 },
		{ "id": "c", "kind": "interact" },
		{ "id": "d", "kind": "hold" },
	] })
	assert_eq(bad.errors.size(), 5, str(bad.errors))
