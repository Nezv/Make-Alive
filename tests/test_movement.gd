extends TestCase
## The player's body: stamina, crouching, jumping and landing, vaulting, gun weight, and what
## other players see of it.

const DT := 1.0 / 60.0


func after_each() -> void:
	Sfx.reset() # no breath still sounding when the run ends


## Run `m` for `seconds` on the floor.
func _run(m: MoveState, seconds_: float, sprinting: bool, crouching := false) -> void:
	for i in roundi(seconds_ / DT):
		m.step(DT, sprinting and m.can_sprint(), true, crouching, 0.0, 0.0)


func test_sprinting_drains_stamina_and_walking_refills_it_after_a_rest() -> void:
	var m := MoveState.new()
	assert_eq(m.stamina, Config.STAMINA_MAX)
	_run(m, 3.0, true)
	assert_near(m.stamina, Config.STAMINA_MAX - Config.STAMINA_SPRINT_DRAIN * 3.0, 0.5)
	var low := m.stamina
	_run(m, Config.STAMINA_REST_DELAY * 0.5, false)
	assert_near(m.stamina, low, 0.01, "nothing comes back straight away")
	_run(m, Config.STAMINA_REST_DELAY * 0.5 + 1.0, false)
	assert_near(m.stamina, low + Config.STAMINA_REFILL, 1.0, "then it refills")
	_run(m, 60.0, false)
	assert_eq(m.stamina, Config.STAMINA_MAX, "and stops at full")
	assert_near(m.stamina_share(), 1.0, 0.001)


func test_empty_stamina_forces_a_walk_until_it_has_recovered() -> void:
	var m := MoveState.new()
	_run(m, Config.STAMINA_MAX / Config.STAMINA_SPRINT_DRAIN + 0.5, true)
	assert_eq(m.stamina, 0.0)
	assert_true(m.winded)
	assert_false(m.can_sprint())
	_run(m, Config.STAMINA_REST_DELAY + 0.3, true) # still holding sprint: it walks, so it rests
	assert_gt(m.stamina, 0.0)
	assert_false(m.can_sprint(), "a sliver of stamina is not enough to run again")
	_run(m, Config.STAMINA_RECOVER / Config.STAMINA_REFILL + 0.2, false)
	assert_false(m.winded)
	assert_true(m.can_sprint())


func test_crouching_is_lower_slower_quieter_and_steadier() -> void:
	var m := MoveState.new()
	assert_near(m.height(), Config.PLAYER_HEIGHT, 0.001)
	_run(m, Config.CROUCH_TIME * 0.5, false, true)
	assert_gt(m.crouch, 0.2)
	assert_lt(m.crouch, 0.8, "it eases down, it does not snap")
	_run(m, Config.CROUCH_TIME, false, true)
	assert_eq(m.crouch, 1.0)
	assert_near(m.height(), Config.CROUCH_HEIGHT, 0.001)
	assert_near(m.eye_height(), Config.CROUCH_EYE_HEIGHT, 0.001)
	assert_near(m.speed(Weapons.AK47, false, false), Config.WALK_SPEED * Config.CROUCH_SPEED_MULT, 0.001)
	assert_false(m.can_sprint(), "no sprinting on your haunches")
	assert_lt(m.step_loudness(false), 1.0)
	var d := Weapons.def(Weapons.AK47)
	assert_lt(Weapons.spread(d, false, 0.0, 1.0), Weapons.spread(d, false, 0.0, 0.0), "tighter spread")
	assert_near(Weapons.spread(d, false, 0.0, 1.0), d.spread * Config.CROUCH_SPREAD_MULT, 0.0001)
	_run(m, Config.CROUCH_TIME + 0.1, false, false)
	assert_eq(m.crouch, 0.0)


func test_heavy_guns_sprint_slower() -> void:
	var m := MoveState.new()
	assert_near(m.speed(Weapons.P19, true, false), Config.SPRINT_SPEED, 0.001)
	assert_lt(m.speed(Weapons.T5000, true, false), m.speed(Weapons.AK47, true, false))
	assert_lt(m.speed(Weapons.AK47, true, false), m.speed(Weapons.P19, true, false))
	assert_gt(m.speed(Weapons.T5000, true, false), Config.WALK_SPEED, "still faster than walking")
	assert_near(m.speed(Weapons.T5000, false, false), Config.WALK_SPEED, 0.001, "walking is the same with any gun")
	assert_near(m.speed(Weapons.AK47, false, true), Config.WALK_SPEED * Config.ADS_MOVE_MULT, 0.001)


func test_coyote_time_allows_a_late_jump_but_only_one() -> void:
	var m := MoveState.new()
	m.step(DT, false, true, false, 0.0, 0.0)
	assert_true(m.can_jump())
	m.step(Config.COYOTE_TIME * 0.5, false, false, false, 0.0, 0.0) # walked off an edge
	assert_true(m.can_jump(), "just off the edge still counts")
	m.jump()
	assert_false(m.can_jump(), "no second jump in the air")
	m.step(DT, false, true, false, 0.0, 0.0)
	assert_true(m.can_jump(), "on the floor again")
	m.step(Config.COYOTE_TIME + 0.05, false, false, false, 0.0, 0.0)
	assert_false(m.can_jump(), "too late")


func test_landing_dips_the_view_by_fall_speed_and_it_springs_back() -> void:
	var soft := MoveState.new()
	soft.land(3.0)
	var hard := MoveState.new()
	hard.land(9.0)
	assert_gt(soft.dip, 0.0)
	assert_gt(hard.dip, soft.dip)
	var huge := MoveState.new()
	huge.land(500.0)
	assert_eq(huge.dip, Config.LAND_DIP_MAX, "capped")
	assert_lt(hard.eye_height(), Config.EYE_HEIGHT)
	_run(hard, 1.5, false)
	assert_lt(hard.dip, 0.005, "back up")


func test_a_fall_is_measured_from_its_highest_point_and_hurts_above_the_safe_height() -> void:
	var m := MoveState.new()
	m.step(DT, false, true, false, 10.0, 0.0)
	assert_eq(m.step(DT, false, false, false, 10.6, 0.0), 0.0) # jumped up a little
	m.step(DT, false, false, false, 4.0, 9.0)
	var fell := m.step(DT, false, true, false, 3.0, 12.0)
	assert_near(fell, 7.6, 0.001, "from the top of the jump to the floor")
	assert_gt(m.dip, 0.0)
	assert_eq(MoveState.fall_damage(1.2), 0, "a jump costs nothing")
	assert_eq(MoveState.fall_damage(Config.FALL_SAFE_HEIGHT), 0)
	assert_eq(MoveState.fall_damage(Config.FALL_SAFE_HEIGHT + 2.0), roundi(2.0 * Config.FALL_DAMAGE_PER_M))
	assert_gt(MoveState.fall_damage(fell), 0)


func test_the_host_takes_the_hp_for_a_fall() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.player_fell(1, 1.0)
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP, "a hop is free")
	g.player_fell(1, Config.FALL_SAFE_HEIGHT + 2.0)
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP - roundi(2.0 * Config.FALL_DAMAGE_PER_M))
	assert_eq(count(calls, &"on_player_damaged"), 1)
	g.player_fell(1, 100000.0)
	assert_true(g.players[1].health.hp >= 0)
	g.player_fell(42, 50.0) # nobody: ignored


func test_the_player_really_crouches_capsule_and_camera() -> void:
	var g := await new_game()
	var lp := g.local_player
	await frames(3)
	await _drawn(lp)
	var standing_eye := lp.camera.global_position.y - lp.global_position.y
	assert_near(lp.capsule.height, Config.PLAYER_HEIGHT, 0.001)
	lp.debug_crouch = true
	await seconds(Config.CROUCH_TIME + 0.2)
	await _drawn(lp)
	assert_near(lp.capsule.height, Config.CROUCH_HEIGHT, 0.01)
	assert_near(lp.body_shape.position.y, Config.CROUCH_HEIGHT / 2.0, 0.01, "still standing on the floor")
	var crouched_eye := lp.camera.global_position.y - lp.global_position.y
	assert_near(standing_eye - crouched_eye, Config.EYE_HEIGHT - Config.CROUCH_EYE_HEIGHT, 0.05)
	assert_true(lp.action_bits() & PlayerWire.ACTION_CROUCH != 0)
	lp.debug_crouch = false
	await seconds(Config.CROUCH_TIME + 0.2)
	assert_near(lp.capsule.height, Config.PLAYER_HEIGHT, 0.01)
	assert_eq(lp.action_bits() & PlayerWire.ACTION_CROUCH, 0)


## The camera is placed when a frame is drawn, not on physics ticks: under load several ticks can
## pass without one, so wait for drawn frames before reading where it is.
func _drawn(lp: LocalPlayer) -> void:
	for i in 3:
		await get_tree().process_frame
	lp.velocity = Vector3.ZERO


func test_you_cannot_stand_up_under_something_low() -> void:
	var g := await new_game()
	var lp := g.local_player
	lp.debug_crouch = true
	await seconds(Config.CROUCH_TIME + 0.2)
	var roof := _block(g, lp.global_position + Vector3(0, Config.CROUCH_HEIGHT + 0.25, 0), Vector3(2, 0.2, 2))
	await frames(2)
	lp.debug_crouch = false
	await seconds(Config.CROUCH_TIME + 0.2)
	assert_gt(lp.move.crouch, 0.9, "the ceiling keeps you down")
	roof.free()
	await seconds(Config.CROUCH_TIME + 0.3)
	assert_lt(lp.move.crouch, 0.1, "and you rise once it is gone")


func _block(g: Game, centre: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_WORLD
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	g.add_child(body)
	body.global_position = centre
	return body


func test_sprinting_into_waist_high_cover_vaults_it_in_half_a_second() -> void:
	var g := await new_game()
	var lp := g.local_player
	lp.teleport(Vector3(0, 0.1, 19.7))
	await frames(3)
	var start := lp.global_position
	_block(g, Vector3(0, 0.5, 18.6), Vector3(4, 1.0, 0.5)) # a wall of sandbags across the way, 1 m high
	await frames(2)
	assert_true(lp.try_vault(Vector3.FORWARD), "waist-high and thin: over it")
	assert_true(lp.move.is_vaulting())
	assert_gt(lp.view.stow_goal, 0.5, "hands leave the gun")
	await seconds(Config.VAULT_TIME * 0.5)
	assert_gt(lp.global_position.y, start.y + 0.8, "over the top")
	await seconds(Config.VAULT_TIME * 0.5 + 0.15)
	assert_false(lp.move.is_vaulting())
	assert_lt(lp.global_position.z, 18.2, "on the far side")
	await frames(10)
	assert_lt(lp.global_position.y, 0.3, "feet down")
	assert_lt(lp.move.stamina, Config.STAMINA_MAX, "it costs stamina")


func test_no_vault_over_a_wall_a_thick_block_or_nothing() -> void:
	var g := await new_game()
	var lp := g.local_player
	lp.teleport(Vector3(0, 0.1, 19.7))
	await frames(3)
	assert_false(lp.try_vault(Vector3.FORWARD), "nothing there")
	var wall := _block(g, Vector3(0, 1.5, 18.6), Vector3(4, 3.0, 0.5))
	await frames(2)
	assert_false(lp.try_vault(Vector3.FORWARD), "too high")
	wall.free()
	await frames(2)
	_block(g, Vector3(0, 0.5, 17.5), Vector3(4, 1.0, 3.0))
	await frames(2)
	assert_false(lp.try_vault(Vector3.FORWARD), "too deep to clear")
	assert_false(lp.move.is_vaulting())


func test_action_bits_travel_in_the_player_snapshot() -> void:
	var out := PlayerWire.unpack(PlayerWire.pack([
		{ "id": 1, "pos": Vector3.ZERO, "yaw": 0.0, "hp": 100, "kills": 0, "weapon": 3, "action": PlayerWire.ACTION_CROUCH },
		{ "id": 2, "pos": Vector3.ZERO, "yaw": 0.0, "hp": 100, "kills": 0, "weapon": 3, "action": PlayerWire.ACTION_AIR },
		{ "id": 3, "pos": Vector3.ZERO, "yaw": 0.0, "hp": 100, "kills": 0, "weapon": 3 },
	]))
	assert_eq(out[0].action, PlayerWire.ACTION_CROUCH)
	assert_eq(out[1].action, PlayerWire.ACTION_AIR)
	assert_eq(out[2].action, 0)
	assert_eq(out[0].weapon, 3)


func test_the_host_puts_each_players_action_in_the_snapshot() -> void:
	var g := await new_game()
	g.local_player.debug_crouch = true
	await seconds(Config.CROUCH_TIME + 0.2)
	var me: Dictionary = g.build_snapshot()[0][0]
	assert_true(me.action & PlayerWire.ACTION_CROUCH != 0)


func test_other_players_are_seen_crouching_and_jumping() -> void:
	var r := RemotePlayer.create(7, "Guest")
	add_child(r)
	r.buffer.push(Vector3.ZERO, 0.0)
	r.set_action(PlayerWire.ACTION_CROUCH)
	r._process(0.1)
	assert_eq(r.rig.anim, Humanoid.Anim.CROUCH)
	for i in 30:
		r._process(0.05)
	assert_lt(r.rig.hips.position.y, Humanoid.HIP_HEIGHT - 0.2, "hips come down")
	r.set_action(PlayerWire.ACTION_AIR)
	r._process(0.1)
	assert_eq(r.rig.anim, Humanoid.Anim.JUMP)
	r.set_action(0)
	r._process(0.1)
	assert_eq(r.rig.anim, Humanoid.Anim.IDLE)
	r.free()


func test_the_stamina_bar_only_shows_while_it_is_not_full() -> void:
	var g := await new_game()
	var hud := g.hud
	hud.set_stamina(1.0, false)
	hud._process(1.0)
	assert_eq(hud.stamina_bar.modulate.a, 0.0, "full: out of the way")
	hud.set_stamina(0.4, false)
	hud._process(0.5)
	assert_gt(hud.stamina_bar.modulate.a, 0.5)
	assert_near(hud.stamina_fill.size.x / hud.stamina_bar.size.x, 0.4, 0.02)
	var normal := hud.stamina_fill.color
	hud.set_stamina(0.05, true)
	assert_true(hud.stamina_fill.color != normal, "winded: another colour")
	hud.set_stamina(1.0, false)
	hud._process(2.0)
	assert_eq(hud.stamina_bar.modulate.a, 0.0)


func test_being_winded_is_heard() -> void:
	var g := await new_game()
	var lp := g.local_player
	assert_true(Sfx.stream("breath") != null)
	lp.move.stamina = 0.0
	lp.move.winded = true
	var before: int = Sfx.stats.played
	lp._breathe(Config.BREATH_INTERVAL + 0.01)
	assert_eq(Sfx.stats.played, before + 1)
	lp._breathe(Config.BREATH_INTERVAL * 0.5)
	assert_eq(Sfx.stats.played, before + 1, "one breath at a time")
	lp.move.winded = false
	lp._breathe(Config.BREATH_INTERVAL * 3.0)
	assert_eq(Sfx.stats.played, before + 1, "quiet again once recovered")
