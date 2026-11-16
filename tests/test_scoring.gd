extends TestCase
## The score of a match: what the host counts per player, the titles, the end screen's rows, the
## best times on disk, and the buttons.

const S := MissionRules.Status
const TEST_RECORDS := "user://test_records.cfg"


func before_each() -> void:
	Records.path = TEST_RECORDS
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS))


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS))
	Records.path = "user://test_run_records.cfg" # back to the runner's, never the player's


func _game() -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	return g


func test_kills_headshots_severs_and_damage_are_counted() -> void:
	var g := await _game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	await frames(2)
	g.hit_zombie(1, z, Humanoid.Part.ARM_L, z.global_position + Vector3(0, 1.3, 0), Vector3.FORWARD, Config.ARM_HP)
	g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)
	assert_eq(g.score.get_stat(1, "kills"), 1)
	assert_eq(g.score.get_stat(1, "headshots"), 1)
	assert_gt(g.score.get_stat(1, "severs"), 0)
	g.damage_player(1, 12)
	g.damage_player(1, 5)
	assert_eq(g.score.get_stat(1, "damage"), 17)
	g.hooks.on_player_revived(7, 1)
	assert_eq(g.score.get_stat(1, "revives"), 1, "a revive counts for the one who did it")


func test_shots_and_hits_are_counted_per_trigger_pull() -> void:
	var g := await _game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	z.hp = 100000
	await frames(2)
	var chest := z.rig.spine.global_position + Vector3(0, 0.25, 0)
	var from := chest + Vector3(0, 0, 1.2)
	g.rng.seed = 11
	g.resolve_shot(1, from, (chest - from).normalized(), Weapons.SPAS12)
	g.resolve_shot(1, from, Vector3.UP, Weapons.SPAS12)
	assert_eq(g.score.get_stat(1, "shots"), 2, "a shotgun blast is one shot")
	assert_eq(g.score.get_stat(1, "hits"), 1)
	assert_near(g.score.accuracy(1), 0.5, 0.001)


func test_distance_walked_is_counted_but_not_teleports() -> void:
	var g := await _game()
	var p: Dictionary = g.players[1]
	var t := Config.NOISE_STEP_INTERVAL
	p.step_pos = p.pos - Vector3(0, 0, Config.WALK_SPEED * t)
	g._footsteps(t)
	assert_near(g.score.get_stat(1, "distance"), Config.WALK_SPEED * t, 0.01)
	p.step_pos = p.pos - Vector3(0, 0, 500.0)
	g._footsteps(t)
	assert_near(g.score.get_stat(1, "distance"), Config.WALK_SPEED * t, 0.01, "a respawn is not a walk")


func test_titles_go_to_who_earned_them() -> void:
	var s := Score.new()
	s.join(1, "Ana")
	s.join(2, "Bia")
	s.join(3, "Caio")
	s.add(1, "headshots", 4)
	s.add(2, "headshots", 9)
	s.add(3, "revives", 2)
	s.add(1, "damage", 30)
	s.add(2, "damage", 80)
	s.add(3, "damage", 55)
	s.last_out = 3
	var t := s.titles()
	assert_eq(t["Sharpshooter"], 2)
	assert_eq(t["Medic"], 3)
	assert_eq(t["Untouched"], 1)
	assert_eq(t["Last one standing"], 3)
	var alone := Score.new()
	alone.join(1, "Ana")
	assert_true(alone.titles().is_empty(), "nothing earned, nothing named")


func test_the_last_player_standing_is_remembered() -> void:
	var g := await _game()
	g.rules.start([{ "id": "x", "kind": "reach", "zone": "exit", "seconds": 0.0, "waves": [], "text": "",
		"who": "any", "target": -1, "time_limit": 0.0 }], false)
	g._add_player(7, "Guest")
	g.players[7].pos = Vector3(0, 0.1, 20)
	g.damage_player(1, 100000)
	g.damage_player(7, 100000)
	assert_eq(g.score.last_out, 7)


func test_the_end_screen_gets_a_row_per_player_and_counts_them_up() -> void:
	var g := await _game()
	g._add_player(7, "Guest")
	g.score.add(1, "kills", 12)
	g.score.add(7, "kills", 3)
	g.score.add(7, "headshots", 2)
	g.rules.start([{ "id": "x", "kind": "survive", "zone": "", "seconds": 1.0, "waves": [], "text": "",
		"who": "any", "target": -1, "time_limit": 0.0 }])
	g.rules.step(1.1)
	assert_eq(g.rules.status, S.WON)
	var sent: Dictionary = g.final_score_view
	assert_true(sent.won)
	assert_eq(sent.rows.size(), 2)
	assert_eq(sent.titles["Sharpshooter"], "Guest")
	for i in 40:
		g._process(0.1)
		g.hud._process(0.1)
	assert_true(g.hud.end_panel.visible)
	assert_eq(g.hud.score_rows.size(), 2, "a row each")
	var mine: Label = g.hud.score_rows[0]
	assert_true(mine.text.contains("Tester"), mine.text)
	assert_true(mine.text.contains("12"), "counted all the way up: " + mine.text)
	assert_true(g.hud.end_titles.text.contains("Sharpshooter"), g.hud.end_titles.text)


func test_numbers_tick_up_rather_than_appear() -> void:
	var hud := Hud.new()
	add_child(hud)
	hud.show_end(true, "")
	hud.set_final_score({ "won": true, "seconds": 75.0, "best": false, "titles": {},
		"rows": [{ "id": 1, "name": "Ana", "kills": 40, "headshots": 0, "severs": 0, "damage": 0, "revives": 0,
			"shots": 0, "hits": 0, "distance": 0 }] })
	hud.end_panel.visible = true
	hud._process(Config.SCORE_TICK_TIME * 0.3)
	var early := hud.score_rows[0].text
	assert_false(early.contains("40"), "not there yet: " + early)
	hud._process(Config.SCORE_TICK_TIME)
	assert_true(hud.score_rows[0].text.contains("40"), hud.score_rows[0].text)
	assert_true(hud.end_detail.text.contains("1:15"), hud.end_detail.text)
	hud.free()


func test_a_won_mission_records_the_best_time() -> void:
	assert_eq(Records.best_time("terminal"), -1.0)
	assert_true(Records.submit("terminal", 300.0))
	assert_eq(Records.best_time("terminal"), 300.0)
	assert_false(Records.submit("terminal", 320.0), "slower")
	assert_eq(Records.best_time("terminal"), 300.0)
	assert_true(Records.submit("terminal", 250.0))
	assert_eq(Records.best_time("terminal"), 250.0)
	assert_eq(Records.best_time("terminal", "hard"), -1.0, "per difficulty")
	assert_false(Records.submit("", 10.0))


func test_the_host_saves_its_time_when_the_mission_is_won_and_not_when_lost() -> void:
	var g := await _game()
	g.rules.start([{ "id": "x", "kind": "survive", "zone": "", "seconds": 1.0, "waves": [], "text": "",
		"who": "any", "target": -1, "time_limit": 0.0 }])
	g.rules.step(1.1)
	assert_gt(Records.best_time("corridor"), 0.0, "training counts under the map's name")
	assert_true(g.final_score_view.best)
	var lost := await _game()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_RECORDS))
	lost.rules.start([{ "id": "x", "kind": "reach", "zone": "exit", "seconds": 0.0, "waves": [], "text": "",
		"who": "any", "target": -1, "time_limit": 1.0 }])
	lost.rules.step(2.0)
	assert_eq(lost.rules.status, S.FAILED)
	assert_eq(Records.best_time("corridor"), -1.0)


func test_retry_is_for_the_host_and_both_buttons_leave_the_match() -> void:
	var g := await _game()
	assert_true(g.hud.retry_button.visible, "the host can retry")
	var asked := []
	g.retry_requested.connect(func(): asked.append("retry"))
	g.leave_requested.connect(func(): asked.append("leave"))
	g.hud.retry_button.pressed.emit()
	g.hud.end_button.pressed.emit()
	assert_eq(asked, ["retry", "leave"])
	assert_true(g.hud.end_button.text.to_lower().contains("lobby") or g.hud.end_button.text.to_lower().contains("menu"))
