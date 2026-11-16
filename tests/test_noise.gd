extends TestCase
## Noise: what makes it, who hears it, what the horde director does with it.

const FAR := Vector3(38, 0.1, 0)   ## down the far leg of the corridor, a long way from the player's spawn
const SPOT := Vector3(26, 0, 0)    ## where the noise is made in these tests


func _noises(calls: Array) -> Array:
	return calls.filter(func(c: Array) -> bool: return c[0] == &"on_noise").map(func(c: Array) -> Array: return c[1])


func test_every_gun_has_a_loudness_and_a_quieter_suppressed_one() -> void:
	for id in Weapons.COUNT:
		assert_gt(Weapons.loudness(id), 0.0, Weapons.def(id).name)
		assert_lt(Weapons.loudness(id, true), Weapons.loudness(id) + 0.001, Weapons.def(id).name + " suppressed")
	assert_gt(Weapons.loudness(Weapons.SPAS12), Weapons.loudness(Weapons.P19), "a shotgun carries farther than a pistol")
	assert_gt(Weapons.loudness(Weapons.T5000), Weapons.loudness(Weapons.AK47))
	for id in Weapons.COUNT:
		if id != Weapons.ASVAL:
			assert_gt(Weapons.loudness(id), Weapons.loudness(Weapons.ASVAL), "the AS Val is the quiet one")
	assert_lt(Weapons.loudness(Weapons.AK47, true), Weapons.loudness(Weapons.AK47) * 0.5)


func test_make_noise_fires_the_hook() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.make_noise(SPOT, 30.0, 1)
	assert_eq(_noises(calls), [[SPOT, 30.0, 1]])
	g.make_noise(SPOT, 0.0, 1)
	assert_eq(_noises(calls).size(), 1, "silence is not a noise")


func test_a_shot_is_as_loud_as_its_gun_where_it_was_fired() -> void:
	var g := await new_game()
	var calls := spy(g)
	var from := Vector3(0, 1.6, 26)
	g._queue_shot(1, from, Vector3.FORWARD, Weapons.SPAS12)
	assert_eq(_noises(calls), [[from, Weapons.loudness(Weapons.SPAS12), 1]], "one noise for the shot, not one per pellet")
	g._queue_shot(1, from, Vector3.FORWARD, Weapons.SPAS12)
	assert_eq(_noises(calls).size(), 1, "a shot the host refused made no sound")


func test_a_broken_door_is_heard() -> void:
	var g := await new_game()
	var calls := spy(g)
	g._on_door_smashed(g.door)
	var heard := _noises(calls)
	assert_eq(heard.size(), 1)
	assert_eq(heard[0][1], Config.NOISE_DOOR_BREAK)
	assert_eq(heard[0][2], 0, "nobody's fault")
	assert_lt((heard[0][0] as Vector3).distance_to(g.door.global_position), 0.1)


func test_sprinting_is_heard_walking_and_crouching_are_not() -> void:
	var g := await new_game()
	var calls := spy(g)
	var p: Dictionary = g.players[1]
	var t := Config.NOISE_STEP_INTERVAL
	p.step_pos = p.pos - Vector3(0, 0, Config.WALK_SPEED * t)
	g._footsteps(t)
	assert_eq(_noises(calls).size(), 0, "walking")
	p.step_pos = p.pos - Vector3(0, 0, Config.SPRINT_SPEED * 0.9 * t)
	g._footsteps(t)
	assert_eq(_noises(calls), [[p.pos, Config.NOISE_SPRINT, 1]])
	p.action = PlayerWire.ACTION_CROUCH
	p.step_pos = p.pos - Vector3(0, 0, Config.SPRINT_SPEED * 0.9 * t)
	g._footsteps(t)
	assert_eq(_noises(calls).size(), 1, "crouched: quiet however fast")
	p.action = 0
	p.step_pos = p.pos - Vector3(0, 0, 500.0)
	g._footsteps(t)
	assert_eq(_noises(calls).size(), 1, "a teleport is not a sprint")
	g._footsteps(t * 0.5)
	assert_eq(_noises(calls).size(), 1, "only once per interval")


func test_zombies_in_earshot_go_to_the_spot_not_to_the_player() -> void:
	var g := await new_game()
	var near := g.spawn_zombie(Zombie.Type.WALKER, FAR)
	var deaf := g.spawn_zombie(Zombie.Type.WALKER, FAR + Vector3(2, 0, 0))
	near.speed = 2.0
	await frames(2)
	g.make_noise(SPOT, 13.0, 0)
	assert_true(near.investigating(), "12 m away from a 13 m noise")
	assert_false(deaf.investigating(), "14 m away: out of earshot")
	assert_eq(near.heard, SPOT)
	await wait_until(func() -> bool: return near.global_position.distance_to(SPOT) < Config.NOISE_ARRIVE + 0.3, 12.0)
	assert_lt(near.global_position.distance_to(SPOT), Config.NOISE_ARRIVE + 0.3, "it walked to where the noise was")
	var at := near.global_position
	await seconds(0.5)
	assert_lt(near.global_position.distance_to(at), 0.4, "and stands there, though the player is elsewhere")


func test_a_zombie_that_has_a_player_close_keeps_chasing() -> void:
	var g := await new_game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, g.players[1].pos + Vector3(0, 0, -Config.ZOMBIE_NOTICE_RANGE * 0.5))
	await frames(2)
	g.make_noise(z.global_position + Vector3(0, 0, -3), 20.0, 0)
	assert_true(z.investigating(), "it heard it")
	var before := z.global_position.distance_to(g.players[1].pos)
	await seconds(1.0)
	assert_lt(z.global_position.distance_to(g.players[1].pos), before, "but dinner is right there")


func test_interest_fades_and_the_chase_resumes() -> void:
	var g := await new_game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, FAR)
	await frames(2)
	z.speed = 2.0
	g.make_noise(FAR + Vector3(-1, 0, 0), 10.0, 0)
	assert_true(z.investigating())
	z.heard_left = 0.05
	await seconds(0.2)
	assert_false(z.investigating())
	var before := z.global_position.x
	await seconds(1.0)
	assert_lt(z.global_position.x, before - 0.5, "walking up the corridor toward the player again")


func test_noise_fills_the_directors_heat_and_a_full_meter_brings_the_horde_sooner() -> void:
	var g := await new_game()
	var d := g.director
	assert_eq(d.heat, 0.0)
	g.make_noise(SPOT, 50.0, 1)
	assert_near(d.heat, 50.0 * Config.NOISE_HEAT_PER_M, 0.001)
	var timer := d._horde_timer
	assert_gt(timer, Config.NOISE_HORDE_SOON)
	g.make_noise(SPOT, Config.NOISE_HEAT_FULL / Config.NOISE_HEAT_PER_M, 1)
	assert_eq(d.heat, 0.0, "the meter empties when it brings them")
	assert_near(d._horde_timer, Config.NOISE_HORDE_SOON, 0.001)
	d._horde_timer = 1.0
	g.make_noise(SPOT, Config.NOISE_HEAT_FULL / Config.NOISE_HEAT_PER_M, 1)
	assert_near(d._horde_timer, 1.0, 0.001, "never later than it already was")


func test_heat_cools_off_in_the_quiet() -> void:
	var g := await new_game()
	var d := g.director
	d.heat = 10.0
	d.step(2.0)
	assert_near(d.heat, 10.0 - 2.0 * Config.NOISE_HEAT_DECAY, 0.001)
	d.step(1000.0)
	assert_eq(d.heat, 0.0)


func test_noise_rings_show_where_noise_was_and_fade() -> void:
	var g := await new_game()
	assert_true(g.noise_rings == null, "off unless asked for (--noise)")
	g.make_noise(SPOT, 10.0, 0)
	g.show_noise()
	g.make_noise(SPOT, 10.0, 0)
	g.make_noise(SPOT + Vector3(2, 0, 0), 20.0, 0)
	assert_eq(g.noise_rings.count(), 2)
	g.noise_rings._process(Config.NOISE_RING_TIME * 0.5)
	assert_gt(g.noise_rings.radius_of(0), 0.0)
	assert_lt(g.noise_rings.radius_of(0), 10.0, "still growing")
	g.noise_rings._process(Config.NOISE_RING_TIME)
	assert_eq(g.noise_rings.count(), 0)
	for i in Config.NOISE_RINGS_MAX + 5:
		g.make_noise(SPOT, 5.0, 0)
	assert_eq(g.noise_rings.count(), Config.NOISE_RINGS_MAX, "capped")
