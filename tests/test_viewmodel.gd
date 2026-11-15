extends TestCase
## Gun models and the first-person gun animation: aim, sprint carry, reload, recoil.

const DT := 1.0 / 60.0


func _vm(id: int) -> Array:
	var vm := Viewmodel.new()
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
