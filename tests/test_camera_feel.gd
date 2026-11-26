extends TestCase
## Camera feel: a figure-eight bob in step with the feet (bigger when sprinting), the gun lagging the
## mouse and springing back (more for heavy guns), a degree or two of tilt when strafing, recoil as a
## spring, the view widening while sprinting and pinching on a sniper shot, shakes from explosions,
## hits, landing leapers and the helicopter mixed and capped; all scaled by a setting, nothing at zero.

const DT := 1.0 / 60.0


func _walk(f: CameraFeel, secs: float, speed: float, sprinting := false, strafe := 0.0, mouse := Vector2.ZERO, weight := 1.0) -> Array:
	var xs := []
	var ys := []
	for i in int(secs / DT):
		f.step(DT, speed, sprinting, strafe, mouse if i == 0 else Vector2.ZERO, weight)
		xs.append(f.offset.x)
		ys.append(f.offset.y)
	return [xs, ys]


func _crossings(vals: Array) -> int:
	var n := 0
	for i in range(1, vals.size()):
		if signf(vals[i]) != signf(vals[i - 1]) and vals[i] != 0.0:
			n += 1
	return n


func test_walking_bobs_in_a_figure_eight_in_step_with_the_feet() -> void:
	var f := CameraFeel.new()
	var steps := f.step_count
	var xy := _walk(f, 4.0, Config.WALK_SPEED)
	var cx := _crossings(xy[0])
	var cy := _crossings(xy[1])
	assert_gt(cx, 2)
	assert_near(float(cy) / cx, 2.0, 0.35, "up and down twice for each side to side: a figure eight")
	assert_near(float(f.step_count - steps), float(cy) / 2.0, 1.5, "a step at every low point")
	var walk: float = (xy[1] as Array).max() - (xy[1] as Array).min()
	var run := _walk(f, 4.0, Config.SPRINT_SPEED, true)
	assert_gt((run[1] as Array).max() - (run[1] as Array).min(), walk * 1.2, "bigger when sprinting")
	var still := _walk(f, 2.0, 0.0)
	assert_lt(absf(f.offset.y), 0.002, "and it settles standing still")


func test_the_gun_lags_the_mouse_then_springs_back_and_heavy_guns_lag_more() -> void:
	var light := CameraFeel.new()
	var heavy := CameraFeel.new()
	var peak_l := 0.0
	var peak_h := 0.0
	for i in 20:
		light.step(DT, 0.0, false, 0.0, Vector2(30, 0) if i == 0 else Vector2.ZERO, 1.0)
		heavy.step(DT, 0.0, false, 0.0, Vector2(30, 0) if i == 0 else Vector2.ZERO, 1.6)
		peak_l = minf(peak_l, light.sway.x)
		peak_h = minf(peak_h, heavy.sway.x)
	assert_lt(peak_l, 0.0, "turning right, the gun trails left")
	assert_lt(peak_h, peak_l, "a heavy gun trails further")
	for i in int(1.0 / DT):
		light.step(DT, 0.0, false, 0.0, Vector2.ZERO, 1.0)
	assert_lt(light.sway.length(), absf(peak_l) * 0.1, "and springs back")


func test_strafing_tilts_the_view_a_degree_or_two() -> void:
	var f := CameraFeel.new()
	_walk(f, 1.0, Config.WALK_SPEED, false, 1.0)
	assert_true(absf(f.angles.z) >= deg_to_rad(1.0) and absf(f.angles.z) <= deg_to_rad(2.0), "%f" % rad_to_deg(f.angles.z))
	assert_lt(f.angles.z, 0.0, "leaning into a move right")
	_walk(f, 1.0, Config.WALK_SPEED, false, 0.0)
	assert_lt(absf(f.angles.z), deg_to_rad(0.2), "level walking forward")


func test_the_view_widens_when_sprinting_and_pinches_on_a_sniper_shot() -> void:
	var f := CameraFeel.new()
	_walk(f, 0.1, Config.SPRINT_SPEED, true)
	assert_true(f.fov_add > 0.0 and f.fov_add < Config.CAM_SPRINT_FOV, "eases open")
	_walk(f, 1.5, Config.SPRINT_SPEED, true)
	assert_near(f.fov_add, Config.CAM_SPRINT_FOV, 0.1)
	_walk(f, 1.5, 0.0)
	f.pinch()
	f.step(DT, 0.0, false, 0.0, Vector2.ZERO, 1.0)
	assert_lt(f.fov_add, -1.0, "a sniper shot pinches it")
	_walk(f, 1.0, 0.0)
	assert_near(f.fov_add, 0.0, 0.05)


func test_shakes_mix_up_to_a_cap_and_die_away() -> void:
	var f := CameraFeel.new()
	for i in 10:
		f.add_shake(1.0, 0.5)
	assert_true(f.shake_amount() <= Config.CAM_SHAKE_MAX + 0.0001, "capped")
	_walk(f, 0.6, 0.0)
	assert_eq(f.shake_amount(), 0.0, "gone")
	f.rumble = 0.03
	f.step(DT, 0.0, false, 0.0, Vector2.ZERO, 1.0)
	assert_gt(f.shake_amount(), 0.0, "the helicopter's rumble counts")


func test_the_setting_scales_it_all_and_zero_turns_it_off() -> void:
	var f := CameraFeel.new()
	f.scale = 0.0
	f.add_shake(0.5, 1.0)
	f.pinch()
	_walk(f, 2.0, Config.SPRINT_SPEED, true, 1.0, Vector2(40, 0))
	assert_eq(f.offset, Vector3.ZERO)
	assert_eq(f.angles, Vector3.ZERO)
	assert_eq(f.fov_add, 0.0)
	assert_eq(f.sway, Vector2.ZERO)
	assert_true(Settings.get_value("camera_motion") == 1.0, "on by default")


func test_recoil_is_a_spring_that_comes_back_past_its_rest() -> void:
	var g := await new_game()
	var lp := g.local_player
	lp.punch = Vector2.ZERO
	lp.punch_vel = Vector2.ZERO
	lp.kick_view(Vector2(0.05, 0.01))
	var first := lp.punch.x
	var peak := 0.0
	var low := 0.0
	for i in int(0.8 / DT):
		lp.step_recoil(DT)
		peak = maxf(peak, lp.punch.x)
		low = minf(low, lp.punch.x)
	assert_gt(peak, first, "it climbs, not a jump")
	assert_lt(low, 0.0, "and comes back past where it was")
	assert_lt(absf(lp.punch.x), peak * 0.15, "settled")


func test_hits_explosions_and_leapers_landing_shake_you() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	var lp := g.local_player
	g.damage_player(1, 5)
	assert_gt(lp.feel.shake_amount(), 0.0, "a hit")
	lp.feel.clear_shakes()
	g.world_fx(Fx.Kind.BLAST, lp.global_position + Vector3(4, 0, 0), Vector3.UP, 1.0)
	assert_gt(lp.feel.shake_amount(), 0.0, "an explosion near")
	lp.feel.clear_shakes()
	g.world_fx(Fx.Kind.BLAST, lp.global_position + Vector3(400, 0, 0), Vector3.UP, 1.0)
	assert_eq(lp.feel.shake_amount(), 0.0, "not one far off")
	g.shake_near(lp.global_position + Vector3(2, 0, 0), Config.CAM_SHAKE_LEAP, 8.0)
	assert_gt(lp.feel.shake_amount(), 0.0, "a leaper landing beside you")
