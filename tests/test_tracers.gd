extends TestCase
## Tracers and the bullet's whiz: a thin bright streak runs from the muzzle to where the bullet went
## at bullet speed and fades at the end; others' guns show one every shot, yours every third; the
## colour is the calibre's (bright rifles, faint pistols, a fan of short ones for shotguns), a sniper
## shot leaves a vapour line that lingers and drifts apart; a teammate's bullet passing close whizzes
## and makes you flinch. Pooled and capped.

const DT := 1.0 / 60.0


func _tracers() -> Tracers:
	var t := Tracers.new()
	add_child(t)
	return t


func test_a_tracer_runs_to_the_hit_at_bullet_speed_and_is_gone_after() -> void:
	var t := _tracers()
	var from := Vector3.ZERO
	var to := Vector3(0, 0, -200)
	t.fire(from, to, Weapons.AK47)
	assert_eq(t.active(), 1)
	t.step(0.05)
	var seg := t.segment(0)
	assert_near((seg[0] as Vector3).distance_to(from), Config.TRACER_SPEED * 0.05, 0.5, "the head moves at bullet speed")
	t.step(0.2)
	seg = t.segment(0)
	assert_near((seg[0] as Vector3).distance_to(seg[1]), Config.TRACER_LENGTH, 0.5, "a segment of fixed length")
	t.step(200.0 / Config.TRACER_SPEED)
	assert_eq(t.active(), 0, "gone once it reaches the end")
	t.free()


func test_it_fades_as_it_reaches_the_end() -> void:
	var t := _tracers()
	t.fire(Vector3.ZERO, Vector3(0, 0, -100), Weapons.AK47)
	t.step(0.05)
	var early := t.alpha(0)
	t.step(100.0 / Config.TRACER_SPEED - 0.05 + Config.TRACER_LENGTH / Config.TRACER_SPEED * 0.8)
	assert_lt(t.alpha(0), early, "fading out")
	t.free()


func test_the_colour_is_the_calibres() -> void:
	var rifle := Tracers.color_for(Weapons.AK47)
	var pistol := Tracers.color_for(Weapons.P19)
	assert_gt(rifle.a, 0.8, "rifles are bright")
	assert_gt(rifle.r, rifle.b + 0.3, "yellow-white")
	assert_lt(pistol.a, 0.5, "pistols faint")


func test_a_shotgun_throws_a_fan_of_short_ones() -> void:
	var t := _tracers()
	t.fire(Vector3.ZERO, Vector3(0, 0, -40), Weapons.SPAS12)
	assert_eq(t.active(), int(Weapons.def(Weapons.SPAS12).pellets), "one per pellet")
	t.step(0.05)
	var ends := {}
	for i in t.active():
		var seg := t.segment(i)
		assert_lt((seg[0] as Vector3).distance_to(seg[1]), Config.TRACER_LENGTH * 0.5, "short")
		ends[str((seg[0] as Vector3).snapped(Vector3.ONE * 0.01))] = true
	assert_gt(ends.size(), 1, "fanned out, not on one line")
	t.free()


func test_a_sniper_leaves_a_vapour_line_that_lingers_and_drifts_apart() -> void:
	var t := _tracers()
	t.fire(Vector3.ZERO, Vector3(0, 0, -150), Weapons.T5000)
	assert_eq(t.vapour_count(), 1)
	var tight := t.vapour_spread(0)
	t.step(Config.VAPOUR_TIME * 0.6)
	assert_eq(t.vapour_count(), 1, "still hanging there")
	assert_gt(t.vapour_spread(0), tight, "wobbling apart")
	t.step(Config.VAPOUR_TIME)
	assert_eq(t.vapour_count(), 0)
	t.free()


func test_the_pool_holds_its_cap() -> void:
	var t := _tracers()
	for i in 500:
		t.fire(Vector3.ZERO, Vector3(0, 0, -300), Weapons.AK47)
	assert_true(t.active() <= Config.TRACER_MAX, "%d" % t.active())
	t.free()


# --- In a match -----------------------------------------------------------------------

func test_your_own_gun_shows_one_every_third_shot_others_every_shot() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	var d := Weapons.def(g.local_player.weapons.current)
	var before := g.tracers.fired
	for i in 3:
		g._fire(d)
	assert_eq(g.tracers.fired - before, 1, "one in three of your own")
	g._add_player(7, "Guest")
	g._apply_snapshot([{ "id": 7, "pos": Vector3(1, 0.1, 26), "yaw": 0.0, "hp": 100, "kills": 0, "weapon": Weapons.AK47, "action": 0 }], [])
	before = g.tracers.fired
	for i in 3:
		g.shot_seen(7, Weapons.AK47, Vector3(1, 1.5, 26), Vector3(1, 1.5, -20))
	assert_eq(g.tracers.fired - before, 3, "every one of theirs")


func test_a_teammates_bullet_passing_close_whizzes_and_you_flinch() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	g._apply_snapshot([{ "id": 7, "pos": Vector3(1, 0.1, 40), "yaw": 0.0, "hp": 100, "kills": 0, "weapon": Weapons.AK47, "action": 0 }], [])
	var lp := g.local_player
	var ear := lp.camera.global_position
	lp.punch = Vector2.ZERO
	g.shot_seen(7, Weapons.AK47, ear + Vector3(0.4, 0, 30), ear + Vector3(0.4, 0, -30))
	assert_eq(g.whizzes, 1, "it went by your ear")
	assert_gt(lp.punch.length(), 0.0, "a tiny flinch")
	g.shot_seen(7, Weapons.AK47, ear + Vector3(6, 0, 30), ear + Vector3(6, 0, -30))
	assert_eq(g.whizzes, 1, "not from a shot well wide")
	g.shot_seen(7, Weapons.AK47, ear + Vector3(0.4, 0, 30), ear + Vector3(0.4, 0, 10))
	assert_eq(g.whizzes, 1, "nor one that stopped short of you")
	assert_true(Sfx.stream("whiz") != null)
