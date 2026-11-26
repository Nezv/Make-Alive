extends TestCase
## Muzzle flash and smoke (S029): a star of crossed quads shaped by the gun's class, a warm light on
## the shooter's own gun only, a couple of puffs drifting up with the wind, a wisp after a long
## burst, and other players' guns flashing too (cheaper) when the host's shot counter moves.

const DT := 1.0 / 60.0


func _fx() -> Fx:
	var fx := Fx.new()
	add_child(fx)
	fx.set_tier("high")
	return fx


func _flash(id: int, cheap := false, fx: Fx = null) -> MuzzleFlash:
	var m := MuzzleFlash.new(cheap)
	m.fx = fx
	m.rng.seed = 7
	add_child(m)
	m.set_gun(id, Vector3(0, 0.02, -0.5))
	return m


func _step(m: MuzzleFlash, fx: Fx, secs: float) -> void:
	for i in int(round(secs / DT)):
		m.step(DT)
		if fx:
			fx.step(DT)


func test_every_gun_flashes_by_its_class() -> void:
	assert_eq(Weapons.flash_shape(Weapons.P19), Weapons.Flash.ROUND, "pistol: small and round")
	assert_eq(Weapons.flash_shape(Weapons.AK47), Weapons.Flash.FORK, "rifle: long and forked")
	assert_eq(Weapons.flash_shape(Weapons.SPAS12), Weapons.Flash.BALL, "shotgun: a wide ball")
	assert_eq(Weapons.flash_shape(Weapons.T5000), Weapons.Flash.JETS, "braked sniper: side jets")
	assert_eq(Weapons.flash_shape(Weapons.ASVAL), Weapons.Flash.NONE, "suppressed: no flash")
	for id in Weapons.COUNT:
		assert_eq(Weapons.flash_shape(id) != Weapons.Flash.NONE, bool(Weapons.def(id).flash),
			Weapons.def(id).name + " agrees with its flash flag")


func test_the_flash_is_a_star_of_three_to_five_crossed_quads() -> void:
	var sizes := {}
	for shape in [Weapons.Flash.ROUND, Weapons.Flash.FORK, Weapons.Flash.BALL, Weapons.Flash.JETS]:
		var mesh := MuzzleFlash.mesh_for(shape)
		var quads := mesh.get_faces().size() / 6
		assert_true(quads >= 3 and quads <= 5, "shape %d is 3 to 5 quads, not %d" % [shape, quads])
		sizes[shape] = mesh.get_aabb().size
	assert_gt(sizes[Weapons.Flash.FORK].z, sizes[Weapons.Flash.ROUND].z * 1.8, "a rifle's flash is long")
	assert_gt(sizes[Weapons.Flash.BALL].x, sizes[Weapons.Flash.ROUND].x * 1.5, "a shotgun's is wide")
	assert_gt(sizes[Weapons.Flash.JETS].x, sizes[Weapons.Flash.JETS].z * 1.5, "a muzzle brake throws it sideways")


func test_a_shot_flashes_for_a_frame_or_two_with_a_random_roll_and_size() -> void:
	var m := _flash(Weapons.AK47)
	assert_false(m.flash.visible, "dark before the shot")
	m.fire()
	m.step(DT)
	assert_true(m.flash.visible, "the first frame after the shot")
	var roll := m.flash.rotation.z
	var size := m.flash.scale
	_step(m, null, DT * 3.0)
	assert_false(m.flash.visible, "gone two or three frames later")
	m.fire()
	m.step(DT)
	assert_true(absf(angle_difference(m.flash.rotation.z, roll)) > 0.01 or not m.flash.scale.is_equal_approx(size),
		"every shot looks a little different")
	m.free()


func test_the_shooters_own_gun_lights_up_warm_and_without_shadows() -> void:
	var m := _flash(Weapons.AK47)
	assert_true(m.light != null, "the full tier has a light")
	assert_false(m.light.shadow_enabled)
	assert_gt(m.light.light_color.r, m.light.light_color.b + 0.4, "warm orange")
	assert_gt(m.light.omni_range, 4.0, "reaches the hands and the walls nearby")
	m.fire()
	m.step(DT)
	assert_gt(m.light.light_energy, 0.0, "on right after the shot")
	_step(m, null, Config.MUZZLE_LIGHT_TIME + DT)
	assert_eq(m.light.light_energy, 0.0, "off within %.2f s" % (Config.MUZZLE_LIGHT_TIME + DT))
	m.free()


func test_smoke_puffs_drift_up_and_are_gone_in_under_a_second() -> void:
	var fx := _fx()
	var m := _flash(Weapons.AK47, false, fx)
	var at := m.global_position
	m.fire()
	assert_true(fx.alive(Fx.Layer.SMOKE) in [2, 3], "two or three puffs, not %d" % fx.alive(Fx.Layer.SMOKE))
	_step(m, fx, 0.4)
	for p: Vector3 in fx.positions(Fx.Layer.SMOKE):
		assert_gt(p.y, at.y + 0.05, "rising")
	_step(m, fx, Config.MUZZLE_SMOKE_LIFE)
	assert_eq(fx.alive(Fx.Layer.SMOKE), 0, "gone after their life")
	m.free()
	fx.free()


func test_a_suppressed_gun_has_no_flash_and_a_thin_grey_puff() -> void:
	var fx := _fx()
	var m := _flash(Weapons.ASVAL, false, fx)
	m.fire()
	m.step(DT)
	assert_false(m.flash.visible, "no flash")
	assert_eq(m.light.light_energy, 0.0, "no light")
	assert_eq(fx.alive(Fx.Layer.SMOKE), 1, "one thin puff")
	m.free()
	fx.free()


func test_a_long_burst_leaves_a_wisp_for_two_seconds_and_a_short_one_does_not() -> void:
	var fx := _fx()
	var m := _flash(Weapons.AK47, false, fx)
	for i in 3:
		m.fire()
		_step(m, fx, 0.1)
	_step(m, fx, Config.MUZZLE_SMOKE_LIFE + 0.2)
	assert_eq(fx.alive(Fx.Layer.SMOKE), 0, "three shots: no wisp")
	for i in 20:
		m.fire()
		_step(m, fx, 0.1)
	_step(m, fx, 1.5)
	assert_gt(fx.alive(Fx.Layer.SMOKE), 0, "two seconds of a wisp after a long burst")
	_step(m, fx, Config.MUZZLE_WISP_TIME - 1.5 + Config.MUZZLE_SMOKE_LIFE + 0.2)
	assert_eq(fx.alive(Fx.Layer.SMOKE), 0, "and then it stops")
	m.free()
	fx.free()


func test_the_viewmodel_flash_sits_at_the_muzzle_of_the_gun_in_hand() -> void:
	var vm := Viewmodel.new()
	add_child(vm)
	for id in [Weapons.P19, Weapons.DRAGUNOV]:
		vm._swap(id)
		assert_lt(vm.muzzle.position.distance_to(vm.gun.muzzle), 0.06, Weapons.def(id).name + " flash at its muzzle")
		assert_eq(vm.muzzle.shape, Weapons.flash_shape(id))
		assert_false(vm.muzzle.cheap)
	vm.free()


func test_the_shot_counter_rides_in_the_action_bits() -> void:
	var bits := PlayerWire.ACTION_CROUCH | PlayerWire.shots_bits(37)
	var out := PlayerWire.unpack(PlayerWire.pack([
		{ "id": 2, "pos": Vector3.ZERO, "yaw": 0.0, "hp": 50, "kills": 0, "weapon": 3, "action": bits }]))
	assert_eq(int(out[0].action) & PlayerWire.ACTION_BODY, PlayerWire.ACTION_CROUCH, "the body bits are kept")
	assert_eq(PlayerWire.shots_of(out[0].action), 37 % 16, "the count wraps at 16")


func test_other_players_guns_flash_when_they_shoot() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Ana")
	g._apply_snapshot(g.build_snapshot()[0], [])
	var r: RemotePlayer = g.remotes[7]
	assert_true(r.muzzle != null, "a remote gun has a muzzle flash")
	assert_true(r.muzzle.cheap, "the cheaper tier")
	assert_true(r.muzzle.light == null, "only the shooter's own gun lights up")
	assert_eq(r.shots_seen, 0, "joined at zero shots")
	var gun: int = g.players[7].weapon
	g._queue_shot(7, Vector3(0, 1.6, 0), Vector3.FORWARD, gun)
	g._apply_snapshot(g.build_snapshot()[0], [])
	assert_eq(r.shots_seen, 1)
	assert_eq(r.flashes, 1, "one shot, one flash")
	r.muzzle.step(DT)
	assert_eq(r.muzzle.flash.visible, Weapons.flash_shape(gun) != Weapons.Flash.NONE)
	g._apply_snapshot(g.build_snapshot()[0], [])
	assert_eq(r.flashes, 1, "no new shot, no new flash")


func test_a_player_seen_for_the_first_time_does_not_flash_for_old_shots() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Ana")
	g.players[7].shots = 11
	g._apply_snapshot(g.build_snapshot()[0], [])
	var r: RemotePlayer = g.remotes[7]
	assert_eq(r.flashes, 0, "the count it arrived with is history")
	assert_eq(r.shots_seen, 11)
