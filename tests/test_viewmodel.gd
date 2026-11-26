extends TestCase
## Gun models and the first-person gun animation: aim, sprint carry, reload, recoil.

const DT := 1.0 / 60.0


func _vm(id: int) -> Array:
	var vm := Viewmodel.new()
	vm._rng.seed = 1234 # recoil and idle breathing are random: pinned, or settling checks pass 9 times in 10
	add_child(vm)
	var w := WeaponState.new()
	w.switch_to(id)
	w.step(1.0)
	vm.show_weapon(id)
	return [vm, w]


func _run(vm: Viewmodel, w: WeaponState, secs: float, aiming := false, sprinting := false) -> void:
	for i in int(secs / DT):
		w.step(DT)
		vm.update(DT, 8.0 if sprinting else 0.0, aiming, sprinting, w)


func test_every_gun_builds_a_model_pointing_forward() -> void:
	for id in Weapons.COUNT:
		var m := Guns.build(id)
		add_child(m)
		var n: String = Weapons.def(id).name
		assert_gt(m.body.mesh.get_faces().size(), 30 * 3, n + " is more than a couple of boxes")
		assert_lt(m.muzzle.z, m.sight.z - 0.1, n + " muzzle is ahead of the rear sight")
		assert_gt(m.sight.y, m.muzzle.y - 0.001, n + " sights sit above the barrel")
		assert_eq(m.mag != null, Weapons.def(id).reload_style == Weapons.Reload.MAG, n + " magazine part")
		assert_true(m.body.material_override is ShaderMaterial, n + " uses the shiny gun material")
		m.free()


func test_aiming_brings_the_sights_to_the_middle_of_the_screen() -> void:
	for id in [Weapons.P19, Weapons.AK47, Weapons.P90]:
		var a := _vm(id)
		var vm: Viewmodel = a[0]
		_run(vm, a[1], 0.5)
		var hip: Vector3 = vm.pivot.transform * vm.gun.sight
		assert_gt(hip.x, 0.08, "at the hip the gun sits to the right")
		_run(vm, a[1], 0.6, true)
		var ads: Vector3 = vm.pivot.transform * vm.gun.sight
		assert_near(ads.x, 0.0, 0.004, "sight centred (x)")
		assert_near(ads.y, 0.0, 0.004, "sight centred (y)")
		assert_near(vm.aim, 1.0, 0.02)
		vm.free()


func test_aim_eases_in_instead_of_snapping() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	_run(vm, a[1], 0.3)
	_run(vm, a[1], DT * 2.0, true)
	assert_gt(vm.aim, 0.0)
	assert_lt(vm.aim, 0.5, "two frames in, it's still on the way up")
	vm.free()


func test_sprinting_some_guns_stay_up_and_others_drop() -> void:
	for id in Weapons.COUNT:
		var a := _vm(id)
		var vm: Viewmodel = a[0]
		_run(vm, a[1], 0.8, false, true)
		var muzzle_dir: Vector3 = -vm.pivot.transform.basis.z
		var n: String = Weapons.def(id).name
		if Weapons.def(id).carry == Weapons.Carry.HIGH:
			assert_gt(muzzle_dir.y, 0.5, n + " is carried muzzle-up")
		else:
			assert_lt(muzzle_dir.y, -0.25, n + " is carried muzzle-down")
		_run(vm, a[1], 0.6)
		assert_near((-vm.pivot.transform.basis.z).y, 0.0, 0.08, n + " comes back level when you stop")
		vm.free()
	var high := 0
	for id in Weapons.COUNT:
		if Weapons.def(id).carry == Weapons.Carry.HIGH:
			high += 1
	assert_gt(high, 1, "some stay up")
	assert_lt(high, Weapons.COUNT - 1, "some don't")


func test_reload_takes_the_magazine_out_and_puts_it_back() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.3)
	var rest := vm.gun.mag.position
	w.ammo[w.current] = 0
	w.start_reload()
	var t: float = w.def().reload
	_run(vm, w, t * 0.4)
	assert_gt(vm.gun.mag.position.distance_to(rest), 0.1, "magazine is out mid-reload")
	assert_gt(absf(vm.pivot.rotation.z) + absf(vm.pivot.rotation.x), 0.15, "gun is tilted to work on it")
	_run(vm, w, t * 0.7 + 0.4)
	assert_lt(vm.gun.mag.position.distance_to(rest), 0.005, "magazine seated again")
	assert_lt(absf(vm.pivot.rotation.z), 0.03, "gun level again")
	vm.free()


func test_recoil_kicks_differently_each_shot_then_settles() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.3)
	var rest_z := vm.pivot.position.z
	var rolls := {}
	for i in 6:
		vm.fire()
		vm.update(DT, 0.0, false, false, w)
		assert_gt(vm.pivot.position.z, rest_z + 0.005, "kicks back toward you")
		rolls[snappedf(vm.kick_rot.y, 0.0001)] = true
		_run(vm, w, 0.5)
	assert_gt(rolls.size(), 3, "random sideways kick")
	assert_near(vm.pivot.position.z, rest_z, 0.003, "settles back")
	vm.free()


func test_bolt_and_pump_guns_work_the_action_after_a_shot() -> void:
	for id in [Weapons.SPAS12, Weapons.T5000]:
		var a := _vm(id)
		var vm: Viewmodel = a[0]
		var w: WeaponState = a[1]
		_run(vm, w, 0.3)
		var rest := vm.gun.action.position
		w.try_fire()
		vm.fire()
		var moved := 0.0
		for i in int(w.def().interval / DT):
			w.step(DT)
			vm.update(DT, 0.0, false, false, w)
			moved = maxf(moved, vm.gun.action.position.distance_to(rest))
		assert_gt(moved, 0.04, Weapons.def(id).name + " action cycles")
		_run(vm, w, 0.3)
		assert_lt(vm.gun.action.position.distance_to(rest), 0.004, "and returns")
		vm.free()


func test_player_zooms_and_slows_down_when_aiming() -> void:
	var g := await new_game()
	var p := g.local_player
	await frames(3)
	assert_near(p.camera.fov, Config.FOV, 0.5)
	p.debug_aim = true
	await seconds(0.6)
	assert_lt(p.camera.fov, Config.FOV - 5.0, "zoomed")
	assert_true(p.aiming)
	assert_false(p.sprinting, "no sprinting while aiming")
	p.debug_aim = false
	await seconds(0.6)
	assert_near(p.camera.fov, Config.FOV, 0.5)


func test_right_click_on_a_door_opens_it_instead_of_aiming() -> void:
	var g := await new_game()
	assert_true(g.right_click_is_use(g.door), "looking at a door: right-click uses it")
	assert_false(g.right_click_is_use(null), "looking at nothing: right-click aims")


# --- Handling: reload parts, the bolt, inspect, idle life, swaps, the last rounds ---------

func _events(vm: Viewmodel) -> Array:
	var out := []
	vm.handling.connect(func(what: String): out.append(what))
	return out


func _reload(vm: Viewmodel, w: WeaponState, rounds: int) -> void:
	w.ammo[w.current] = rounds
	assert_true(w.start_reload())
	_run(vm, w, float(w.def().reload) + 0.1)


func test_a_magazine_reload_is_parts_each_with_its_own_sound() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.3)
	var ev := _events(vm)
	_reload(vm, w, 12)
	assert_eq(ev, ["mag_release", "mag_out", "mag_in", "mag_slap"], "a tactical reload: a round is still in")
	ev.clear()
	_reload(vm, w, 0)
	assert_eq(ev, ["mag_release", "mag_out", "mag_in", "mag_slap", "bolt_rack"], "an empty one racks the charging handle")
	for what in ["mag_release", "mag_out", "mag_in", "mag_slap", "bolt_rack", "shell_in", "pump_back", "pump_fwd",
			"bolt_up", "bolt_back", "bolt_fwd", "bolt_down", "holster", "draw", "inspect"]:
		assert_true(Sfx.stream("h_" + what) != null, what + " has a sound")
	vm.free()


func test_the_old_magazine_falls_out() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var dropped := [0]
	vm.mag_dropped.connect(func(at: Vector3, vel: Vector3): dropped[0] += 1)
	_run(vm, a[1], 0.3)
	_reload(vm, a[1], 3)
	assert_eq(dropped[0], 1)
	vm.free()
	var g := await new_game()
	var lp := g.local_player
	lp.weapons.switch_to(Weapons.AK47)
	lp.weapons.step(1.0)
	lp.weapons.ammo[Weapons.AK47] = 3
	lp.weapons.start_reload()
	for i in int(2.0 / DT):
		lp.weapons.step(DT)
		lp.view.update(DT, 0.0, false, false, lp.weapons)
	assert_gt(g.casings.mags(), 0, "it lies on the floor")


func test_a_shotgun_loads_shell_by_shell_and_pumps_at_the_end() -> void:
	var a := _vm(Weapons.SPAS12)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.3)
	var ev := _events(vm)
	w.ammo[w.current] = 5
	assert_true(w.start_reload())
	_run(vm, w, float(w.def().reload) * 3.0 + 0.2)
	assert_eq(ev.count("shell_in"), 3, "one each")
	assert_eq(ev.slice(-2), ["pump_back", "pump_fwd"], "and racked at the end")
	vm.free()


func test_a_bolt_rifle_works_the_bolt_in_four_moves_and_the_scope_leaves_the_eye() -> void:
	var a := _vm(Weapons.T5000)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.6, true)
	var ev := _events(vm)
	w.try_fire()
	vm.fire()
	var broke := 0.0
	var off := 0.0
	for i in int(float(w.def().interval) / DT):
		w.step(DT)
		vm.update(DT, 0.0, true, false, w)
		broke = maxf(broke, vm.scope_break)
		var s: Vector3 = vm.pivot.transform * vm.gun.sight
		off = maxf(off, Vector2(s.x, s.y).length())
	assert_eq(ev, ["bolt_up", "bolt_back", "bolt_fwd", "bolt_down"])
	assert_gt(broke, 0.5, "the eye comes off the scope")
	assert_gt(off, 0.02, "the sights leave the middle")
	assert_lt(vm.scope_break, 0.05, "and back on it after")
	vm.free()


func test_inspect_rolls_the_gun_one_way_then_the_other_then_checks_the_chamber() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.5)
	var ev := _events(vm)
	assert_true(vm.inspect())
	assert_eq(ev, ["inspect"])
	var rolls := []
	var peek := 0.0
	for i in int(Config.INSPECT_TIME / DT):
		w.step(DT)
		vm.update(DT, 0.0, false, false, w)
		rolls.append(vm.pivot.rotation.z)
		peek = maxf(peek, vm.chamber_peek)
	assert_gt(rolls.max(), 0.3, "rolled one way")
	assert_lt(rolls.min(), -0.3, "and the other")
	assert_gt(peek, 0.5, "the chamber was checked")
	assert_lt(vm.chamber_peek, 0.01, "and closed again")
	assert_true(vm.inspect())
	vm.fire()
	assert_lt(vm.inspect_t, 0.0, "a shot ends it")
	vm.free()


func test_standing_still_the_hands_breathe_and_shift_on_the_grip() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.5)
	var ys := []
	for i in int(5.0 / DT):
		w.step(DT)
		vm.update(DT, 0.0, false, false, w)
		ys.append(vm.pivot.position.y)
	assert_gt(ys.max() - ys.min(), 0.001, "it lives")
	_run(vm, w, 0.6, true)
	var aimed := []
	for i in int(5.0 / DT):
		w.step(DT)
		vm.update(DT, 0.0, true, false, w)
		aimed.append(vm.pivot.position.y)
	assert_lt(aimed.max() - aimed.min(), (ys.max() - ys.min()) * 0.5, "steadier on the sights")
	vm.free()


func test_swapping_guns_sounds_the_holster_then_the_draw() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var w: WeaponState = a[1]
	_run(vm, w, 0.3)
	var ev := _events(vm)
	w.switch_to(Weapons.P19)
	vm.show_weapon(Weapons.P19)
	_run(vm, w, float(w.draw_total) + 0.1)
	assert_eq(ev, ["holster", "draw"])
	vm.free()


func test_the_last_rounds_of_a_magazine_click() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	var lp := g.local_player
	lp.weapons.switch_to(Weapons.AK47)
	lp.weapons.step(1.0)
	lp.weapons.ammo[Weapons.AK47] = 20
	Sfx.last.clear()
	lp.weapons.try_fire()
	g._fire(Weapons.def(Weapons.AK47))
	assert_false(Sfx.last.has("low_ammo_click"), "plenty left")
	lp.weapons.ammo[Weapons.AK47] = 2
	Sfx.last.clear()
	lp.weapons.try_fire()
	g._fire(Weapons.def(Weapons.AK47))
	assert_true(Sfx.last.has("low_ammo_click"), "nearly dry: thinner, with a click")
