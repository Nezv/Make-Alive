extends TestCase
## Hit feedback: four ticks that snap in and ease out (red and bigger for a kill, a skull for a
## headshot, an extra tick and a wet sound for a limb), a red arc on the side a hit came from, the view
## punched away from the attacker with a red flash and the sound muffled a moment, a pulsing, grey,
## blurred edge at low HP, and blood on the lens after a close kill.

const DT := 1.0 / 60.0


func test_a_hit_marker_snaps_in_and_eases_out() -> void:
	var hm := HitMarker.new()
	add_child(hm)
	hm.show_hit(HitMarker.Kind.HIT)
	assert_true(hm.visible)
	assert_gt(hm.spread(), 1.0, "starts wide")
	hm.step(0.06)
	var settled := hm.spread()
	assert_lt(settled, 1.3, "snapped in")
	hm.step(Config.HIT_MARKER_TIME)
	assert_false(hm.visible, "eased out")
	hm.show_hit(HitMarker.Kind.KILL)
	assert_gt(hm.tick_size(), Config.HIT_MARKER_SIZE, "a kill is bigger")
	assert_gt(hm.color().r, hm.color().g + 0.5, "and red")
	hm.show_hit(HitMarker.Kind.HEADSHOT)
	assert_true(hm.skull, "a skull for a headshot")
	hm.free()


func _game() -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	return g


func test_the_game_tells_the_shooter_what_their_shot_did() -> void:
	var g := await _game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, g.local_player.global_position + Vector3(0, 0.1, -8))
	g.hit_zombie(1, z, Humanoid.Part.TORSO, z.global_position, Vector3.FORWARD, 1)
	assert_eq(g.hud.hitmarker.kind, HitMarker.Kind.HIT)
	Sfx.last.clear()
	z.hp = 9999 # (only the arm comes off, it does not die of it)
	g.hit_zombie(1, z, Humanoid.Part.ARM_L, z.global_position, Vector3.FORWARD, Config.ARM_HP + 1)
	assert_gt(g.hud.hitmarker.sever_tick, 0.0, "a limb off: an extra tick")
	assert_true(Sfx.last.has("sever_wet"), "and a wet sound")
	var z2 := g.spawn_zombie(Zombie.Type.WALKER, g.local_player.global_position + Vector3(2, 0.1, -8))
	g.hit_zombie(1, z2, Humanoid.Part.HEAD, z2.global_position, Vector3.FORWARD, 9999)
	assert_eq(g.hud.hitmarker.kind, HitMarker.Kind.HEADSHOT)


func test_a_hit_shows_where_it_came_from_and_fades() -> void:
	var g := await _game()
	var lp := g.local_player
	lp.yaw = 0.0 # looking north (-Z)
	var right := g.spawn_zombie(Zombie.Type.WALKER, lp.global_position + Vector3(3, 0.1, 0))
	g.damage_player(1, 10, right, 0.99)
	assert_eq(g.hud.arcs.count(), 1)
	assert_near(g.hud.arcs.angle_of(0), PI / 2.0, 0.2, "from the right")
	g.hud.arcs.step(Config.DAMAGE_ARC_TIME + 0.1)
	assert_eq(g.hud.arcs.count(), 0, "faded")


func test_a_hit_punches_the_view_away_and_muffles_the_sound() -> void:
	var g := await _game()
	var lp := g.local_player
	lp.yaw = 0.0
	lp.punch = Vector2.ZERO
	lp.punch_vel = Vector2.ZERO
	var right := g.spawn_zombie(Zombie.Type.WALKER, lp.global_position + Vector3(3, 0.1, 0))
	g.damage_player(1, 10, right, 0.99)
	assert_gt(lp.punch_vel.y, 0.0, "the view turns away from the blow (left)")
	assert_gt(Sfx.muffle_amount(), 0.0, "the world goes dull")
	Sfx.step_muffle(Config.MUFFLE_TIME + 0.1)
	assert_eq(Sfx.muffle_amount(), 0.0, "and comes back")


func test_low_hp_pulses_greys_and_blurs_the_edges() -> void:
	var g := await _game()
	g.hud.set_hp(15)
	g.hud.step_low_hp(1.0)
	assert_gt(g.hud.low_hp_amount(), 0.5)
	g.hud.set_hp(90)
	g.hud.step_low_hp(2.0)
	assert_eq(g.hud.low_hp_amount(), 0.0)


func test_a_close_kill_puts_blood_on_the_lens() -> void:
	var g := await _game()
	var lp := g.local_player
	var near := g.spawn_zombie(Zombie.Type.WALKER, lp.global_position + Vector3(0, 0.1, -1.5))
	g.hit_zombie(1, near, Humanoid.Part.TORSO, near.global_position, Vector3.FORWARD, 9999)
	assert_gt(g.hud.lens.drops.size(), 0, "a few drops")
	g.hud.lens.step(Config.LENS_BLOOD_TIME + 0.1)
	assert_eq(g.hud.lens.drops.size(), 0, "run down and gone")
	var far := g.spawn_zombie(Zombie.Type.WALKER, lp.global_position + Vector3(0, 0.1, -20))
	g.hit_zombie(1, far, Humanoid.Part.TORSO, far.global_position, Vector3.FORWARD, 9999)
	assert_eq(g.hud.lens.drops.size(), 0, "not from far off")
