extends TestCase
## Muzzle flash and smoke: a star of crossed quads at the muzzle for a frame or two, shaped by the
## kind of gun (round for pistols, long and forked for rifles, a wide ball for shotguns, side jets for
## braked rifles, nothing on a suppressed one), a short warm light, a few puffs of smoke, a heat
## shimmer and a wisp after a long burst; other players' guns flash too, without the light.

const DT := 1.0 / 60.0


func _vm(id: int) -> Array:
	var vm := Viewmodel.new()
	add_child(vm)
	vm._rng.seed = 11
	var w := WeaponState.new()
	w.switch_to(id)
	w.step(1.0)
	vm.show_weapon(id)
	return [vm, w]


func _run(vm: Viewmodel, w: WeaponState, secs: float) -> void:
	for i in maxi(1, int(round(secs / DT))):
		w.step(DT)
		vm.update(DT, 0.0, false, false, w)


func test_every_gun_has_a_flash_shape_by_its_kind() -> void:
	assert_eq(Weapons.flash_shape(Weapons.P19), Weapons.Flash.ROUND)
	assert_eq(Weapons.flash_shape(Weapons.AK47), Weapons.Flash.FORKED)
	assert_eq(Weapons.flash_shape(Weapons.TYPE95), Weapons.Flash.FORKED)
	assert_eq(Weapons.flash_shape(Weapons.USAS12), Weapons.Flash.BALL)
	assert_eq(Weapons.flash_shape(Weapons.SPAS12), Weapons.Flash.BALL)
	assert_eq(Weapons.flash_shape(Weapons.T5000), Weapons.Flash.JETS)
	assert_eq(Weapons.flash_shape(Weapons.ASVAL), Weapons.Flash.NONE, "suppressed")
	for id in Weapons.COUNT:
		assert_eq(Weapons.flash_shape(id) == Weapons.Flash.NONE, not Weapons.def(id).flash, Weapons.def(id).name)


func test_a_flash_is_a_star_of_three_to_five_crossed_quads_shaped_by_the_gun() -> void:
	for shape in [Weapons.Flash.ROUND, Weapons.Flash.FORKED, Weapons.Flash.BALL, Weapons.Flash.JETS]:
		var m := MuzzleFlash.mesh_for(shape)
		var quads := m.get_faces().size() / 6
		assert_true(quads >= 3 and quads <= 5, "%d quads" % quads)
	var round_box := MuzzleFlash.mesh_for(Weapons.Flash.ROUND).get_aabb()
	var forked := MuzzleFlash.mesh_for(Weapons.Flash.FORKED).get_aabb()
	var ball := MuzzleFlash.mesh_for(Weapons.Flash.BALL).get_aabb()
	var jets := MuzzleFlash.mesh_for(Weapons.Flash.JETS).get_aabb()
	assert_lt(round_box.get_longest_axis_size(), 0.2, "a pistol's is small")
	assert_gt(forked.size.z, forked.size.x * 2.0, "a rifle's is long")
	assert_gt(ball.size.x, 0.25, "a shotgun's is wide")
	assert_gt(jets.size.x, jets.size.z * 1.5, "a braked rifle blows out sideways")


func test_the_flash_shows_for_a_frame_or_two_with_a_random_roll() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	_run(vm, a[1], 0.2)
	vm.fire()
	assert_true(vm.flash.visible)
	var roll := vm.flash.rotation.z
	_run(vm, a[1], DT)
	assert_true(vm.flash.visible, "still there the next frame")
	_run(vm, a[1], DT * 2.0)
	assert_false(vm.flash.visible, "gone after two")
	vm.fire()
	assert_true(absf(vm.flash.rotation.z - roll) > 0.001, "a different roll every shot")
	vm.free()


func test_a_short_warm_light_with_no_shadow() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	assert_false(vm.light.shadow_enabled)
	assert_gt(vm.light.light_color.r, vm.light.light_color.b + 0.4, "warm")
	vm.fire()
	_run(vm, a[1], DT)
	assert_gt(vm.light.light_energy, 0.0)
	_run(vm, a[1], Config.MUZZLE_LIGHT_TIME + DT)
	assert_eq(vm.light.light_energy, 0.0)
	vm.free()


func test_a_suppressed_gun_has_no_flash_or_light_only_a_thin_puff() -> void:
	var a := _vm(Weapons.ASVAL)
	var vm: Viewmodel = a[0]
	var puffs := []
	vm.smoke.connect(func(at: Vector3, count: int, thin: bool): puffs.append([count, thin]))
	vm.fire()
	_run(vm, a[1], DT)
	assert_false(vm.flash.visible)
	assert_eq(vm.light.light_energy, 0.0)
	assert_eq(puffs, [[1, true]])
	vm.free()


func test_every_shot_puffs_two_or_three_soft_clouds() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var puffs := []
	vm.smoke.connect(func(at: Vector3, count: int, thin: bool): puffs.append([at, count, thin]))
	vm.fire()
	assert_eq(puffs.size(), 1)
	assert_true(puffs[0][1] >= 2 and puffs[0][1] <= 3)
	assert_false(puffs[0][2])
	var g := await new_game()
	var bursts: int = g.fx.stats.bursts
	g.local_player.view.fire()
	assert_eq(g.fx.stats.bursts, bursts + 1, "the game makes them (how many particles is the quality tier's call)")
	vm.free()


func test_a_long_burst_leaves_the_barrel_shimmering_and_smoking_for_a_while() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var wisps := [0] # (a lambda copies a plain int)
	vm.smoke.connect(func(at: Vector3, count: int, thin: bool):
		if thin:
			wisps[0] += 1)
	for i in 4:
		vm.fire()
		_run(vm, a[1], 0.1)
	_run(vm, a[1], 0.5)
	assert_false(vm.shimmer.visible, "a few shots: nothing")
	for i in Config.HEAT_SHOTS + 2:
		vm.fire()
		_run(vm, a[1], 0.1)
	_run(vm, a[1], 0.4)
	assert_true(vm.shimmer.visible, "hot: the air above it wobbles")
	_run(vm, a[1], 1.0)
	assert_gt(wisps[0], 3, "a steady wisp")
	_run(vm, a[1], Config.HEAT_WISP_TIME + 0.5)
	assert_false(vm.shimmer.visible, "cooled down")
	vm.free()


func test_other_players_guns_flash_too_without_the_light() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	var guest := { "id": 7, "pos": Vector3(1, 0.1, 26), "yaw": 0.0, "hp": 100, "kills": 0, "weapon": Weapons.AK47, "action": 0 }
	g._apply_snapshot([guest], [])
	var r: RemotePlayer = g.remotes[7]
	assert_false(r.flash.visible)
	var lights := g.fx.lights_on()
	var smoke := g.fx.alive(Fx.Layer.SMOKE)
	g.resolve_shot(7, Vector3(1, 1.6, 26), Vector3(0, 0, -1), Weapons.AK47)
	assert_true(r.flash.visible, "the host saw the guest fire")
	assert_eq(g.fx.lights_on(), lights, "no light: the cheaper tier")
	assert_gt(g.fx.alive(Fx.Layer.SMOKE), smoke, "a puff")
	r._process(0.1)
	assert_false(r.flash.visible)
