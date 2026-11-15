extends TestCase
## Hordes, zombie types and the leaper's jump.


func test_spawn_horde_spawns_the_requested_count_and_fires_hook() -> void:
	var g := await new_game()
	var calls := spy(g)
	var n := g.director.spawn_horde(12)
	assert_eq(n, 12)
	assert_eq(g.zombies.size(), 12)
	assert_eq(count(calls, &"on_horde_incoming"), 1)


func test_horde_respects_the_zombie_cap() -> void:
	var g := await new_game()
	g.director.spawn_horde(Config.ZOMBIE_MAX + 50)
	assert_eq(g.zombies.size(), Config.ZOMBIE_MAX)


func test_hordes_grow_each_wave() -> void:
	var g := await new_game()
	assert_gt(g.director.horde_size(3), g.director.horde_size(1))


func test_director_sends_a_horde_on_its_own() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.director.enabled = true
	g.director.step(Config.HORDE_FIRST + 0.1)
	assert_eq(count(calls, &"on_horde_incoming"), 1)
	assert_gt(g.zombies.size(), Config.HORDE_SIZE - 1)


func test_horde_walks_around_the_corner_to_the_player() -> void:
	var g := await new_game()
	g.door.toggle() # open
	var z := g.spawn_zombie(Zombie.Type.RUNNER, Vector3(8, 0.1, 0))
	var arrived := await wait_until(func(): return z.global_position.z > 6.0, 5.0)
	assert_true(arrived, "runner got from leg B into leg A (z=%.1f x=%.1f)" % [z.global_position.z, z.global_position.x])


func test_zombies_spread_out_instead_of_stacking() -> void:
	var g := await new_game()
	g.local_player.teleport(Vector3(0, 0.1, 28))
	var a := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 10))
	var b := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0.05, 0.1, 10))
	await seconds(1.0)
	assert_gt(a.global_position.distance_to(b.global_position), 0.45)


func test_leaper_winds_up_then_jumps_at_the_player() -> void:
	var g := await new_game()
	var z := g.spawn_zombie(Zombie.Type.LEAPER, g.local_player.global_position + Vector3(0, 0, -8))
	z.leap_cd = 0.0 # normally random, so a fresh spawn doesn't jump instantly
	var seen := { "windup": false, "leap": false, "max_y": 0.0 }
	var start_dist := z.global_position.distance_to(g.local_player.global_position)
	await wait_until(func():
		if not is_instance_valid(z):
			return true
		seen.windup = seen.windup or z.state == Zombie.State.WINDUP
		seen.leap = seen.leap or z.state == Zombie.State.LEAP
		seen.max_y = maxf(seen.max_y, z.global_position.y)
		return seen.leap and z.state != Zombie.State.LEAP and z.state != Zombie.State.WINDUP, 4.0)
	assert_true(seen.windup, "crouched first")
	assert_true(seen.leap, "then leapt")
	assert_gt(seen.max_y, 0.6, "left the ground")
	assert_lt(z.global_position.distance_to(g.local_player.global_position), start_dist - 4.0, "closed the gap")


func test_crawling_leaper_cannot_jump() -> void:
	var g := await new_game()
	var z := g.spawn_zombie(Zombie.Type.LEAPER, g.local_player.global_position + Vector3(0, 0, -8))
	z.leap_cd = 0.0
	await frames(2)
	g.hit_zombie(1, z, Humanoid.Part.LEG_L, z.global_position, Vector3.FORWARD)
	g.hit_zombie(1, z, Humanoid.Part.LEG_L, z.global_position, Vector3.FORWARD)
	var leapt := await wait_until(func(): return z.state == Zombie.State.LEAP, 1.5)
	assert_false(leapt)
