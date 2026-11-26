extends TestCase
## Shell casings: brass for pistols and rifles, a red hull for shotguns, a long case for snipers;
## thrown from the ejection port the gun's own way, when its action works (at the shot for an
## automatic, on the pump, on the bolt pull); a bounce with a tumble, a smaller one, then they lie
## still a while and sink away. A tink on each bounce, a wisp from the port. MultiMesh, capped.

const DT := 1.0 / 60.0


func _casings() -> Casings:
	var c := Casings.new()
	add_child(c)
	return c


func test_each_kind_of_casing_has_its_look() -> void:
	assert_eq(Weapons.casing_kind(Weapons.P19), Weapons.Casing.PISTOL)
	assert_eq(Weapons.casing_kind(Weapons.AK47), Weapons.Casing.RIFLE)
	assert_eq(Weapons.casing_kind(Weapons.SPAS12), Weapons.Casing.SHELL)
	assert_eq(Weapons.casing_kind(Weapons.T5000), Weapons.Casing.SNIPER)
	var pistol := Casings.mesh_for(Weapons.Casing.PISTOL).get_aabb().get_longest_axis_size()
	var rifle := Casings.mesh_for(Weapons.Casing.RIFLE).get_aabb().get_longest_axis_size()
	var sniper := Casings.mesh_for(Weapons.Casing.SNIPER).get_aabb().get_longest_axis_size()
	assert_lt(pistol, rifle)
	assert_lt(rifle, sniper)
	var shell: Color = Casings.COLORS[Weapons.Casing.SHELL]
	assert_gt(shell.r, shell.g + 0.3, "a red hull")
	var brass: Color = Casings.COLORS[Weapons.Casing.RIFLE]
	assert_gt(brass.r, brass.b + 0.3, "brass")


func test_a_casing_bounces_twice_then_rests_then_sinks_away() -> void:
	var c := _casings()
	c.spawn(Vector3(0, 1.2, 0), Vector3(1.5, 1.0, 0), Weapons.Casing.RIFLE)
	assert_eq(c.alive(), 1)
	var bounces := []
	for i in 240:
		c.step(DT)
		if c.bounces(0) > bounces.size():
			bounces.append(c.position_of(0).y)
	assert_eq(c.bounces(0), 2, "two bounces, no more")
	assert_eq(c.tinks, 2, "a tink each")
	assert_true(c.resting(0), "then still")
	assert_near(c.position_of(0).y, 0.0, 0.02, "on the floor")
	var at := c.position_of(0)
	c.step(Config.CASING_REST - 4.0)
	assert_eq(c.position_of(0), at, "lies there a while")
	c.step(Config.CASING_SINK + 4.5)
	assert_eq(c.alive(), 0, "sunk away")
	c.free()


func test_the_pool_holds_its_cap() -> void:
	var c := _casings()
	for i in 500:
		c.spawn(Vector3(0, 1, 0), Vector3.ZERO, Weapons.Casing.PISTOL)
	assert_true(c.alive() <= Config.CASING_MAX)
	c.free()


func _vm(id: int) -> Array:
	var vm := Viewmodel.new()
	add_child(vm)
	var w := WeaponState.new()
	w.switch_to(id)
	w.step(1.0)
	vm.show_weapon(id)
	var out := []
	vm.eject.connect(func(at: Vector3, vel: Vector3, kind: int): out.append([at, vel, kind]))
	return [vm, w, out]


func _shoot(vm: Viewmodel, w: WeaponState) -> void:
	w.try_fire()
	vm.fire()


func _run(vm: Viewmodel, w: WeaponState, secs: float) -> void:
	for i in maxi(1, int(round(secs / DT))):
		w.step(DT)
		vm.update(DT, 0.0, false, false, w)


func test_an_automatic_throws_its_case_at_the_shot_to_the_right() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	_run(vm, a[1], 0.2)
	_shoot(vm, a[1])
	var out: Array = a[2]
	assert_eq(out.size(), 1, "at once")
	assert_eq(out[0][2], Weapons.Casing.RIFLE)
	var right := vm.global_transform.basis.x
	assert_gt((out[0][1] as Vector3).dot(right), 0.5, "out to the right")
	vm.free()


func test_a_pump_or_a_bolt_throws_it_when_worked() -> void:
	for id in [Weapons.SPAS12, Weapons.T5000]:
		var a := _vm(id)
		var vm: Viewmodel = a[0]
		_run(vm, a[1], 0.2)
		_shoot(vm, a[1])
		var out: Array = a[2]
		assert_eq(out.size(), 0, "%s: not at the shot" % Weapons.def(id).name)
		_run(vm, a[1], float(Weapons.def(id).interval))
		assert_eq(out.size(), 1, "%s: when the action is worked" % Weapons.def(id).name)
		vm.free()


func test_the_port_smokes_and_the_game_drops_the_casing() -> void:
	var a := _vm(Weapons.AK47)
	var vm: Viewmodel = a[0]
	var wisps := [0]
	vm.smoke.connect(func(at: Vector3, count: int, thin: bool):
		if thin:
			wisps[0] += 1)
	_run(vm, a[1], 0.2)
	_shoot(vm, a[1])
	assert_eq(wisps[0], 1, "a wisp from the port")
	vm.free()
	var g := await new_game()
	var before := g.casings.alive()
	g.local_player.weapons.try_fire()
	g.local_player.view.fire()
	assert_eq(g.casings.alive(), before + 1)
