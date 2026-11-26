extends TestCase
## Other players' animations: the snapshot says what each body is doing (aiming, reloading, shoving,
## throwing, vaulting, crouching, healing, downed) and where they look; the rig's legs follow the
## movement while the arms do the action on top (run and reload at once), the head follows the look,
## each shot kicks the gun, and a death falls the way the last blow pushed.

const DT := 1.0 / 60.0


func test_the_snapshot_carries_every_action_and_the_look() -> void:
	assert_eq(PlayerWire.BYTES_EACH, 26)
	var bits := PlayerWire.ACTION_AIM | PlayerWire.ACTION_RELOAD | PlayerWire.ACTION_SHOVE | PlayerWire.ACTION_THROW | PlayerWire.ACTION_VAULT | PlayerWire.ACTION_CROUCH
	var out := PlayerWire.unpack(PlayerWire.pack([{ "id": 3, "pos": Vector3.ZERO, "yaw": 0.0, "hp": 50, "kills": 0, "weapon": 3, "action": bits, "mag": 7, "pitch": -0.62 }]))
	assert_eq(out[0].action, bits)
	assert_near(out[0].pitch, -0.62, 0.02, "the look, to a degree or so")
	assert_eq(out[0].mag, 7)


func test_the_player_says_what_its_body_is_doing() -> void:
	var g := await new_game()
	var lp := g.local_player
	lp.aiming = true
	assert_true(lp.action_bits() & PlayerWire.ACTION_AIM != 0)
	lp.aiming = false
	lp.weapons.draw_left = 0.0 # (the gun is up)
	lp.weapons.ammo[lp.weapons.current] = 0
	assert_true(lp.weapons.start_reload())
	assert_true(lp.action_bits() & PlayerWire.ACTION_RELOAD != 0)
	assert_true(PlayerWire.ACTION_BODY & PlayerWire.ACTION_RELOAD != 0, "a client may say it")
	assert_true(PlayerWire.ACTION_BODY & PlayerWire.ACTION_HEAL == 0, "but not that it heals")


func _remote() -> RemotePlayer:
	var r := RemotePlayer.create(5, "Mate")
	add_child(r)
	return r


func _run(r: RemotePlayer, secs: float, speed := 0.0) -> void:
	for i in int(secs / DT):
		r.animate(DT, speed)


func test_actions_play_on_the_arms_while_the_legs_keep_moving() -> void:
	var r := _remote()
	r.set_weapon(Weapons.AK47)
	r.set_action(PlayerWire.ACTION_RELOAD)
	var hips := []
	for i in int(1.0 / DT):
		r.animate(DT, 6.5)
		hips.append(r.rig._cur[Humanoid.J.HIP_L])
	assert_eq(r.rig.anim, Humanoid.Anim.RUN, "the legs run")
	assert_eq(r.rig.upper, Humanoid.Upper.RELOAD, "the arms reload")
	assert_gt(hips.max() - hips.min(), 0.4, "the legs really do swing")
	var hip_y := r.gun.position.y
	r.set_action(PlayerWire.ACTION_AIM)
	_run(r, 0.5)
	assert_eq(r.rig.upper, Humanoid.Upper.AIM)
	assert_gt(r.gun.position.y, hip_y + 0.1, "the gun comes up to the shoulder")
	var level: float = r.rig._cur[Humanoid.J.SH_R_X]
	r.look_pitch = 0.5 # looking up
	_run(r, 0.5)
	assert_gt(r.rig._cur[Humanoid.J.SH_R_X], level + 0.2, "the gun follows the look up")
	assert_lt(r.rig._cur[Humanoid.J.NECK_PITCH], -0.1, "and so does the head")
	for bit in [PlayerWire.ACTION_SHOVE, PlayerWire.ACTION_THROW]:
		r.set_action(bit)
		r.animate(DT, 0.0)
		assert_eq(r.rig.upper, Humanoid.Upper.SHOVE if bit == PlayerWire.ACTION_SHOVE else Humanoid.Upper.THROW)
	r.set_action(PlayerWire.ACTION_VAULT)
	r.animate(DT, 0.0)
	assert_eq(r.rig.anim, Humanoid.Anim.JUMP, "over the cover")
	r.free()


func test_a_throw_winds_up_then_lets_go() -> void:
	var r := _remote()
	r.set_action(PlayerWire.ACTION_THROW)
	_run(r, 0.25)
	var back: float = r.rig._cur[Humanoid.J.SH_R_X]
	_run(r, 0.4)
	assert_gt(r.rig._cur[Humanoid.J.SH_R_X], back + 1.0, "the arm comes over")
	assert_lt(back, 0.3, "after it went back")
	r.free()


func test_every_shot_kicks_their_gun() -> void:
	var r := _remote()
	r.set_weapon(Weapons.AK47)
	_run(r, 0.5)
	var rest: float = r.rig._cur[Humanoid.J.SH_R_X]
	r.fired(RandomNumberGenerator.new())
	_run(r, 0.05)
	assert_gt(r.rig._cur[Humanoid.J.SH_R_X], rest + 0.05, "the muzzle climbs")
	_run(r, 0.6)
	assert_near(r.rig._cur[Humanoid.J.SH_R_X], rest, 0.03, "and settles")
	r.free()


func test_a_death_falls_the_way_the_blow_pushed() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	var lp_pos: Vector3 = g.players[1].pos
	var z := g.spawn_zombie(Zombie.Type.WALKER, lp_pos + Vector3(0, 0.1, -2))
	g.damage_player(1, 5, z, 0.99)
	g.kill_player(1)
	var push := g.gore.last_impulse
	assert_gt(push.z, 0.5, "the zombie was in front (-Z): the body falls back (+Z)")
