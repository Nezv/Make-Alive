extends TestCase
## The shove: a stock or muzzle strike with any gun that pushes zombies back, staggers walkers,
## breaks a leaper's wind-up and never takes a limb.


func _game() -> Game:
	var g := await new_game()
	g.local_player.teleport(Vector3(0, 0.1, 20))
	g.players[1].pos = Vector3(0, 0.1, 20)
	return g


## A zombie standing `dist` metres in front of the player (who looks down -Z from z = 20).
func _zombie(g: Game, type: int, dist := 1.2, side := 0.0) -> Zombie:
	var z := g.spawn_zombie(type, Vector3(side, 0.1, 20.0 - dist))
	await frames(2)
	z.global_position = Vector3(side, 0.1, 20.0 - dist)
	return z


const FROM := Vector3(0, 1.6, 20)


func test_the_player_shoves_once_per_swing_and_pays_stamina() -> void:
	var g := await _game()
	var lp := g.local_player
	assert_true(InputMap.has_action("shove"))
	assert_true(lp.try_shove())
	assert_near(lp.move.stamina, Config.STAMINA_MAX - Config.SHOVE_STAMINA, 0.001)
	assert_false(lp.try_shove(), "one swing at a time")
	lp.shove_left = 0.0
	lp.move.stamina = Config.SHOVE_STAMINA * 0.5
	assert_false(lp.try_shove(), "too tired")
	lp.move.stamina = Config.STAMINA_MAX
	lp.move.vault_left = 0.3
	assert_false(lp.try_shove(), "hands are on the cover")


func test_the_gun_pulls_back_thrusts_with_a_roll_and_overshoots_home() -> void:
	var v := Viewmodel.new()
	add_child(v)
	v.show_weapon(Weapons.AK47)
	v.shove()
	var back := v.shove_pose(0.06)
	var thrust := v.shove_pose(0.175)
	var over := v.shove_pose(0.28)
	assert_gt(back.z, 0.0, "pulled back toward the body first")
	assert_lt(thrust.z, -0.1, "then out")
	assert_gt(absf(v.shove_roll(0.14)), 0.2, "rolled into the strike")
	assert_gt(over.z, 0.0, "it swings past home on the way back")
	assert_lt(v.shove_pose(Config.SHOVE_TIME).length(), 0.005, "and settles")
	v.free()


func test_a_shove_pushes_a_walker_back_and_staggers_it_with_little_damage() -> void:
	var g := await _game()
	var calls := spy(g)
	var z := await _zombie(g, Zombie.Type.WALKER)
	var hp := z.hp
	var before := z.global_position
	assert_eq(g.host_shove(1, FROM, Vector3.FORWARD), 1)
	assert_eq(z.state, Zombie.State.STAGGER)
	assert_eq(hp - z.hp, Config.SHOVE_DAMAGE)
	assert_eq(count(calls, &"on_zombie_shoved"), 1)
	assert_eq(count(calls, &"on_limb_severed"), 0)
	await seconds(0.3)
	assert_lt(z.global_position.z, before.z - Config.SHOVE_PUSH * 0.1, "pushed away from the player")


func test_a_shove_never_takes_a_limb() -> void:
	var g := await _game()
	var calls := spy(g)
	var z := await _zombie(g, Zombie.Type.WALKER)
	for part in z.part_hp:
		z.part_hp[part] = 1
	for i in 5:
		g.host_shove(1, FROM, Vector3.FORWARD)
		g.players[1].last_shove = -100.0
	assert_eq(count(calls, &"on_limb_severed"), 0)
	for part in z.part_hp:
		assert_false(z.rig.is_severed(part))


func test_a_shove_breaks_a_leapers_wind_up() -> void:
	var g := await _game()
	var z := await _zombie(g, Zombie.Type.LEAPER, 1.5)
	z.set_state(Zombie.State.WINDUP)
	g.host_shove(1, FROM, Vector3.FORWARD)
	assert_true(z.state != Zombie.State.WINDUP and z.state != Zombie.State.LEAP, "no jump")
	assert_gt(z.leap_cd, 1.0, "and it has to start over")


func test_only_what_is_in_front_and_in_reach_is_hit() -> void:
	var g := await _game()
	var far := await _zombie(g, Zombie.Type.WALKER, Config.SHOVE_RANGE + 1.0)
	var beside := await _zombie(g, Zombie.Type.WALKER, 0.2, 2.5)
	var near := await _zombie(g, Zombie.Type.WALKER, 1.0, 0.3)
	assert_eq(g.host_shove(1, FROM, Vector3.FORWARD), 1)
	assert_eq(near.state, Zombie.State.STAGGER)
	assert_true(far.state != Zombie.State.STAGGER)
	assert_true(beside.state != Zombie.State.STAGGER)


func test_a_crawler_is_shoved_away_too() -> void:
	var g := await _game()
	var z := await _zombie(g, Zombie.Type.WALKER, 1.0)
	z.rig.sever(Humanoid.Part.LEG_L)
	z.part_hp[Humanoid.Part.LEG_L] = 0
	assert_true(z.is_crawling())
	var before := z.global_position
	g.host_shove(1, FROM, Vector3.FORWARD)
	await seconds(0.3)
	assert_lt(z.global_position.z, before.z - 0.2, "dragged off its teammate's ankle")


func test_the_host_limits_how_often_a_player_shoves() -> void:
	var g := await _game()
	await _zombie(g, Zombie.Type.WALKER)
	assert_eq(g.host_shove(1, FROM, Vector3.FORWARD), 1)
	assert_eq(g.host_shove(1, FROM, Vector3.FORWARD), 0, "faster than the swing: refused")
	assert_eq(g.host_shove(42, FROM, Vector3.FORWARD), 0, "nobody")


func test_a_landed_shove_thuds_puffs_and_nudges_the_view() -> void:
	var g := await _game()
	await _zombie(g, Zombie.Type.WALKER)
	assert_true(Sfx.stream("thud") != null)
	var played: int = Sfx.stats.played
	var pitch := g.local_player.pitch
	var bursts: int = g.fx.stats.bursts
	g.host_shove(1, FROM, Vector3.FORWARD)
	assert_gt(Sfx.stats.played, played, "thud")
	assert_gt(g.fx.stats.bursts, bursts, "a puff")
	assert_true(g.local_player.punch != Vector2.ZERO or g.local_player.pitch != pitch, "the view jolts")
	Sfx.reset()


func test_a_miss_makes_no_thud() -> void:
	var g := await _game()
	var played: int = Sfx.stats.played
	assert_eq(g.host_shove(1, FROM, Vector3.FORWARD), 0)
	assert_eq(Sfx.stats.played, played)
