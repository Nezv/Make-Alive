extends TestCase
## Dismemberment, death, ragdolls and the zombie hooks.

const P := Humanoid.Part


func _zombie(g: Game, type := Zombie.Type.WALKER) -> Zombie:
	var z := g.spawn_zombie(type, Vector3(0, 0.1, 12))
	await frames(2)
	return z


func test_headshot_kills_in_one_and_makes_a_ragdoll() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := await _zombie(g)
	var id := z.zid
	g.hit_zombie(1, z, P.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD)
	assert_false(g.zombies.has(id), "zombie removed")
	assert_eq(g.gore.stats.ragdolls, 1)
	assert_eq(count(calls, &"on_zombie_killed"), 1)
	assert_eq(g.players[1].kills, 1)
	var killed_args: Array = calls.filter(func(c): return c[0] == &"on_zombie_killed")[0][1]
	assert_true(killed_args[2], "headshot flag passed to the hook")


func test_torso_takes_three_shots() -> void:
	var g := await new_game()
	var z := await _zombie(g)
	var id := z.zid
	for i in 2:
		g.hit_zombie(1, z, P.TORSO, z.global_position + Vector3(0, 1.2, 0), Vector3.FORWARD)
	assert_true(g.zombies.has(id), "alive after two")
	g.hit_zombie(1, z, P.TORSO, z.global_position + Vector3(0, 1.2, 0), Vector3.FORWARD)
	assert_false(g.zombies.has(id), "dead after three")


func test_arm_is_severed_and_flies_off() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := await _zombie(g)
	var gibs_before: int = g.gore.stats.gibs
	g.hit_zombie(1, z, P.ARM_L, z.global_position + Vector3(-0.3, 1.3, 0), Vector3.FORWARD)
	assert_false(z.rig.is_severed(P.ARM_L), "one shot isn't enough")
	g.hit_zombie(1, z, P.ARM_L, z.global_position + Vector3(-0.3, 1.3, 0), Vector3.FORWARD)
	assert_true(z.rig.is_severed(P.ARM_L))
	assert_true(g.zombies.has(z.zid), "still alive without the arm")
	assert_gt(g.gore.stats.gibs, gibs_before, "the arm became a physics gib")
	assert_eq(count(calls, &"on_limb_severed"), 1)
	assert_false(z.rig.segs.has("forearm_l"))


func test_losing_a_leg_makes_it_crawl_slowly() -> void:
	var g := await new_game()
	var z := await _zombie(g, Zombie.Type.RUNNER)
	var full := z.move_speed()
	g.hit_zombie(1, z, P.LEG_R, z.global_position + Vector3(0.1, 0.5, 0), Vector3.FORWARD)
	g.hit_zombie(1, z, P.LEG_R, z.global_position + Vector3(0.1, 0.5, 0), Vector3.FORWARD)
	assert_true(z.is_crawling())
	assert_lt(z.move_speed(), full * 0.5)
	await seconds(Config.STAGGER_TIME + 0.2) # it staggers from the hit first
	assert_eq(z.rig.anim, Humanoid.Anim.CRAWL)


func test_bullet_ray_hits_the_part_hitbox() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := await _zombie(g)
	await frames(3)
	var torso: Area3D = z.rig.segs["torso"].hitbox
	var from := Vector3(0, 1.6, 4) # from behind: its reaching arms would shield the chest from the front
	g.resolve_shot(1, from, (torso.global_position - from).normalized())
	assert_eq(count(calls, &"on_zombie_hit"), 1)
	var args: Array = calls.filter(func(c): return c[0] == &"on_zombie_hit")[0][1]
	assert_eq(args[1], P.TORSO)


func test_closed_door_stops_bullets() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(CorridorMap.DOOR_X + 4.0, 0.1, 0))
	await frames(3)
	var from := Vector3(CorridorMap.DOOR_X - 4.0, 1.2, 0)
	g.resolve_shot(1, from, Vector3.RIGHT)
	assert_eq(count(calls, &"on_zombie_hit"), 0)
	assert_true(is_instance_valid(z))


func test_ragdoll_bodies_stay_in_the_corridor() -> void:
	var g := await new_game()
	var z := await _zombie(g)
	g.hit_zombie(1, z, P.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD)
	await seconds(1.5)
	var bodies := g.gore.find_children("*", "RigidBody3D", true, false)
	assert_gt(bodies.size(), 5, "ragdoll parts exist")
	for b: RigidBody3D in bodies:
		assert_gt(b.global_position.y, -0.5, "nothing fell through the floor")
		assert_lt(b.global_position.y, 6.0, "nothing got launched into orbit")


func test_late_joiner_sees_already_severed_limbs() -> void:
	var mask := (1 << P.ARM_L) | (1 << P.LEG_R)
	var z := Zombie.create(99, Zombie.Type.WALKER, false, Vector3.ZERO, mask)
	add_child(z)
	assert_true(z.rig.is_severed(P.ARM_L))
	assert_true(z.rig.is_severed(P.LEG_R))
	assert_false(z.rig.is_severed(P.ARM_R))
	z.free()
