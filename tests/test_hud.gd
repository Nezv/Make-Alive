extends TestCase
## HUD 2: the ammo panel (name, a pip per round or a number, reserve, fire mode), the vitals (a
## health bar with temporary HP and bleed marks), a compass strip with the objective and teammates on
## it, the objective typed in and struck out when done, world markers clamped to the screen edge, a
## downed teammate's timer and an outline for far ones, the prompt with its key, fading when idle, and
## a HUD scale setting.

const DT := 1.0 / 60.0


func _hud() -> Hud:
	var g := await new_game()
	return g.hud


func test_the_ammo_panel_shows_pips_or_a_number_the_reserve_and_the_fire_mode() -> void:
	var h := await _hud()
	h.set_gun(Weapons.def(Weapons.AK47), 17, false, 90)
	assert_eq(h.ammo.pips(), 17, "a pip a round")
	assert_eq(h.ammo.reserve_text(), "90")
	assert_eq(h.ammo.mode, "AUTO")
	h.set_gun(Weapons.def(Weapons.P90), 44, false, -1)
	assert_eq(h.ammo.pips(), -1, "a big magazine is a number")
	assert_eq(h.ammo.reserve_text(), "∞")
	assert_eq(Hud.fire_mode(Weapons.def(Weapons.P19)), "SEMI")
	assert_eq(Hud.fire_mode(Weapons.def(Weapons.SPAS12)), "PUMP")
	assert_eq(Hud.fire_mode(Weapons.def(Weapons.T5000)), "BOLT")


func test_the_vitals_show_health_temporary_hp_and_each_wound() -> void:
	var h := await _hud()
	var s := PlayerStatus.new()
	s.bleed = 2
	h.set_vitals(60, 20, s)
	assert_near(h.vitals.health_share(), 0.6, 0.001)
	assert_near(h.vitals.temp_share(), 0.2, 0.001)
	assert_eq(h.vitals.bleed_marks(), 2)


func test_the_compass_puts_bearings_where_they_are_and_drops_what_is_behind() -> void:
	var w := 600.0
	assert_near(Compass.bearing_x(0.0, 0.0, w), w / 2.0, 0.01, "dead ahead is the middle")
	assert_gt(Compass.bearing_x(0.0, deg_to_rad(30.0), w), w / 2.0, "to the right is right of it")
	assert_true(is_nan(Compass.bearing_x(0.0, PI, w)), "behind is off the strip")
	assert_eq(Compass.label(0.0), "N")
	assert_eq(Compass.label(PI / 2.0), "E")
	var h := await _hud()
	h.set_compass(0.0, [{ "bearing": 0.2, "kind": "objective" }, { "bearing": -0.3, "kind": "mate" }])
	assert_eq(h.compass.ticks.size(), 2)


func test_the_objective_types_in_and_the_old_one_is_struck_and_slides_away() -> void:
	var ot := ObjectiveText.new()
	add_child(ot)
	ot.show_text("Get to the corner")
	ot.step(0.05)
	var early := ot.visible_chars()
	ot.step(0.3)
	assert_gt(ot.visible_chars(), early, "typed in")
	ot.step(3.0)
	assert_eq(ot.visible_chars(), "Get to the corner".length())
	ot.show_text("Hold the room")
	assert_eq(ot.leaving, "Get to the corner", "the old one is struck through")
	ot.step(Config.HUD_OBJECTIVE_OUT * 0.5)
	assert_gt(ot.leaving_offset(), 0.0, "and slides out")
	ot.step(Config.HUD_OBJECTIVE_OUT)
	assert_eq(ot.leaving, "", "gone")
	ot.free()


func test_a_marker_on_screen_sits_on_its_spot_and_one_off_screen_waits_at_the_edge() -> void:
	var size := Vector2(1600, 900)
	var on := WorldMarkers.place(size, Vector2(400, 300), false)
	assert_false(on.clamped)
	assert_eq(on.pos, Vector2(400, 300))
	var right := WorldMarkers.place(size, Vector2(2400, 450), false)
	assert_true(right.clamped)
	assert_near(right.pos.x, size.x - Config.HUD_EDGE, 0.01, "at the right edge")
	assert_near(right.angle, 0.0, 0.01, "its arrow points right")
	var behind := WorldMarkers.place(size, Vector2(800, 450), true)
	assert_true(behind.clamped, "behind you: at the edge too")
	assert_near(behind.pos.y, size.y - Config.HUD_EDGE, 0.01, "at the bottom")
	assert_eq(WorldMarkers.distance_text(123.4), "123 m")


func test_a_downed_teammate_shows_a_timer_and_a_far_one_an_outline() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	var far := g.local_player.global_position + Vector3(0, 0, -(Config.HUD_OUTLINE_DIST + 10))
	g._apply_snapshot([{ "id": 7, "pos": far, "yaw": 0.0, "hp": 0, "kills": 0, "weapon": 0, "action": PlayerWire.ACTION_DOWNED }], [])
	var r: RemotePlayer = g.remotes[7]
	r.global_position = far
	r.step_tag(1.0)
	assert_true(r.tag.text.contains("%d" % int(Config.DOWNED_TIME - 1.0)), r.tag.text)
	assert_true(g.hud.markers.outlined(g, 7), "far: outlined through the walls")
	r.global_position = g.local_player.global_position + Vector3(0, 0, -3)
	assert_false(g.hud.markers.outlined(g, 7), "near: no need")


func test_the_prompt_names_its_key() -> void:
	var h := await _hud()
	h.set_prompt("Open door", "interact")
	assert_eq(h.prompt_label.text, "[RMB] Open door")
	h.set_prompt("Inspect", "inspect")
	assert_eq(h.prompt_label.text, "[F] Inspect")
	h.set_prompt("")
	assert_eq(h.prompt_label.text, "")


func test_idle_parts_fade_and_come_back_when_they_change() -> void:
	var h := await _hud()
	h.set_gun(Weapons.def(Weapons.AK47), 30, false, 90)
	h.step_fades(Config.HUD_FADE_AFTER + 2.0)
	assert_lt(h.ammo.modulate.a, 0.6, "idle: faded")
	h.set_gun(Weapons.def(Weapons.AK47), 29, false, 90)
	h.step_fades(DT)
	assert_gt(h.ammo.modulate.a, 0.9, "a shot: back")


func test_the_hud_scale_setting_scales_it_and_it_still_fills_the_screen() -> void:
	var h := await _hud()
	h.apply_scale(1.25)
	assert_near(h.root.scale.x, 1.25, 0.001)
	var vp := h.get_viewport().get_visible_rect().size
	assert_lt((h.root.size * 1.25).distance_to(vp), 1.0, "covers the screen exactly")
	assert_eq(Settings.get_value("hud_scale"), 1.0, "a setting, 1 by default")
