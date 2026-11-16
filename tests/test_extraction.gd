extends TestCase
## The way out: the zone opens, everyone alive must stand in it while the clock runs, its look,
## the countdown and its beeps, and the end of the match.

const S := MissionRules.Status
const EXIT := Vector3(31, 0.1, 0)
const NOWHERE := Vector3(0, 0.1, 20)


func _extract_game(seconds := 5.0) -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	g.players[1].pos = NOWHERE
	g.rules.start([{ "id": "out", "kind": "extract", "zone": "exit", "seconds": seconds, "waves": [], "text": "Get out",
		"who": "any", "target": -1, "time_limit": 0.0 }])
	return g


func test_the_zone_opens_with_the_hook_and_every_peer_builds_its_look() -> void:
	var g := await new_game()
	var calls := spy(g)
	assert_true(g.extraction == null, "closed until its objective comes up")
	g.set_physics_process(false)
	g.rules.start([{ "id": "out", "kind": "extract", "zone": "exit", "seconds": 5.0, "waves": [], "text": "Get out",
		"who": "any", "target": -1, "time_limit": 0.0 }])
	assert_eq(count(calls, &"on_extraction_ready"), 1)
	assert_eq(g.mission_view.zone, "exit", "peers are told which zone")
	g._process(0.0)
	assert_true(g.extraction != null)
	assert_eq(g.extraction.zone, "exit")
	assert_lt(g.extraction.global_position.distance_to(Vector3(31, 0, 0)), 0.1, "on the zone's floor")
	assert_gt(g.extraction.ring_count(), 3, "light strips round the edge")


func test_the_flare_smoke_rises_as_a_tall_leaning_column() -> void:
	var g := await _extract_game()
	g._process(0.0)
	g.fx.clear()
	for i in 60:
		g.extraction.step(0.1)
		g.fx.step(0.1)
	var smoke := g.fx.positions(Fx.Layer.SMOKE)
	assert_gt(smoke.size(), 10, "a steady stream of puffs")
	var top := 0.0
	var lean := 0.0
	for p: Vector3 in smoke:
		if p.y > top:
			top = p.y
			lean = Vector2(p.x - 31.0, p.z).dot(Vector2(Config.EXTRACT_WIND.x, Config.EXTRACT_WIND.z).normalized())
	assert_gt(top, Config.EXTRACT_SMOKE_HEIGHT * 0.6, "it climbs high")
	assert_gt(lean, 1.0, "and leans with the wind")
	assert_lt(smoke.size(), Config.FX_MAX_SMOKE / 2, "it leaves room in the pool for the fight")
	assert_gt(g.fx.alive(Fx.Layer.GLOW), 0, "sparks drifting up inside")


func test_the_ring_pulses() -> void:
	var g := await _extract_game()
	g._process(0.0)
	var seen := {}
	for i in 20:
		g.extraction.step(0.07)
		seen[snappedf(g.extraction.glow(), 0.01)] = true
	assert_gt(seen.size(), 5)


func test_countdown_numerals_show_while_everyone_is_in_and_beep_up_the_last_five() -> void:
	var g := await _extract_game(8.0)
	g._process(0.0)
	assert_false(g.hud.countdown_label.visible, "nobody inside")
	g.players[1].pos = EXIT
	g.rules.step(0.1)
	g._process(0.0)
	assert_true(g.hud.countdown_label.visible)
	assert_eq(g.hud.countdown_label.text, "8")
	var played: int = Sfx.stats.played
	var pitches := []
	var t := 0.1
	while t < 7.95:
		g.rules.step(0.1)
		g._process(0.1)
		if g.hud.last_beep_pitch > 0.0 and (pitches.is_empty() or pitches[-1] != g.hud.last_beep_pitch):
			pitches.append(g.hud.last_beep_pitch)
		t += 0.1
	assert_eq(pitches.size(), 5, "a beep for each of the last five seconds")
	for i in range(1, pitches.size()):
		assert_gt(pitches[i], pitches[i - 1], "each higher than the last")
	assert_gt(Sfx.stats.played, played + 4)
	assert_true(Sfx.stream("beep") != null)
	assert_eq(g.hud.countdown_label.text, "1")


func test_leaving_pauses_the_numerals_and_the_beeps() -> void:
	var g := await _extract_game(3.0)
	g.players[1].pos = EXIT
	g.rules.step(1.2)
	g._process(0.0)
	g.players[1].pos = NOWHERE
	g.rules.step(0.1)
	g._process(0.0)
	assert_false(g.hud.countdown_label.visible)
	var played: int = Sfx.stats.played
	for i in 20:
		g._process(0.1)
	assert_eq(Sfx.stats.played, played, "silence while it waits")


func test_success_fades_to_white_and_shows_the_end_screen() -> void:
	var g := await _extract_game(1.0)
	var calls := spy(g)
	g.players[1].pos = EXIT
	g.rules.step(1.1)
	assert_eq(g.rules.status, S.WON)
	assert_eq(count(calls, &"on_extracted"), 1)
	g._process(0.0)
	assert_false(g.hud.countdown_label.visible)
	assert_true(g.hud.end_panel.visible == false or g.hud.fade.color.a < 1.0, "it fades first")
	for i in 30:
		g._process(0.1)
		g.hud._process(0.1)
	assert_gt(g.hud.fade.color.a, 0.8, "white")
	assert_true(g.hud.end_panel.visible)
	assert_true(g.hud.end_title.text.contains("EXTRACTED"), g.hud.end_title.text)
	assert_eq(Input.mouse_mode, Input.MOUSE_MODE_VISIBLE, "a pointer to press the button with")
	var left := [false]
	g.leave_requested.connect(func(): left[0] = true)
	g.hud.end_button.pressed.emit()
	assert_true(left[0], "back to the menu")


func test_a_failed_mission_ends_in_red() -> void:
	var g := await _extract_game()
	g.rules.fail("everyone is down")
	for i in 30:
		g._process(0.1)
		g.hud._process(0.1)
	assert_true(g.hud.end_panel.visible)
	assert_true(g.hud.end_title.text.contains("FAILED"), g.hud.end_title.text)
	assert_true(g.hud.end_detail.text.contains("everyone is down"))
	assert_lt(g.hud.fade.color.g, 0.5, "red, not white")


func test_the_zone_goes_once_the_objective_is_done() -> void:
	var g := await _extract_game(0.5)
	g._process(0.0)
	var look := g.extraction
	g.players[1].pos = EXIT
	g.rules.step(0.6)
	g._process(0.0)
	assert_true(g.extraction == null)
	await frames(2)
	assert_false(is_instance_valid(look))
