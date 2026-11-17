extends TestCase
## Surfaces and impacts: every collision shape says what it is made of (concrete, asphalt, brick,
## metal, wood, glass, dirt, grass, water, flesh, tile); a bullet that hits it makes that surface's
## impact (dust and chips, sparks, splinters, a star crack, clods, a splash...) and leaves a hole lying
## on the surface; a shotgun makes one puff for the pattern and a hole per pellet. How far a bullet
## gets through each is stored for later (S101).



func test_every_surface_has_a_name_and_penetration_numbers() -> void:
	assert_eq(Surface.NAMES.size(), Surface.Kind.size())
	for kind in Surface.Kind.values():
		assert_true(Surface.PENETRATION.has(kind), Surface.NAMES[kind])
	assert_gt(Surface.PENETRATION[Surface.Kind.WOOD], Surface.PENETRATION[Surface.Kind.CONCRETE], "wood stops less than concrete")
	assert_gt(Surface.PENETRATION[Surface.Kind.GLASS], Surface.PENETRATION[Surface.Kind.METAL])


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD | Config.LAYER_HITBOX)
	q.collide_with_areas = true
	return get_viewport().get_world_3d().direct_space_state.intersect_ray(q)


func test_a_hit_says_what_it_hit_by_the_shape_or_the_body() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_WORLD
	add_child(body)
	for i in 2:
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1, 1, 1)
		cs.shape = box
		cs.position = Vector3(i * 3.0, 0, -50)
		body.add_child(cs)
		if i == 0:
			Surface.tag(cs, Surface.Kind.METAL)
	Surface.tag(body, Surface.Kind.BRICK)
	await frames(2)
	assert_eq(Surface.of_hit(_ray(Vector3(0, 0, -40), Vector3(0, 0, -60))), Surface.Kind.METAL, "the shape's own")
	assert_eq(Surface.of_hit(_ray(Vector3(3, 0, -40), Vector3(3, 0, -60))), Surface.Kind.BRICK, "else the body's")
	assert_eq(Surface.of_hit({}), Surface.Kind.CONCRETE, "nothing said: concrete")
	body.free()


func test_the_corridor_has_a_tiled_floor_concrete_walls_and_a_wooden_door() -> void:
	var g := await new_game()
	await frames(2)
	var spawn := g.map.player_spawn()
	assert_eq(Surface.of_hit(_ray(spawn + Vector3(0, 1, 0), spawn + Vector3(0, -2, 0))), Surface.Kind.TILE)
	assert_eq(Surface.of_hit(_ray(spawn + Vector3(0, 1.5, 0), spawn + Vector3(-20, 1.5, 0))), Surface.Kind.CONCRETE)
	assert_eq(int(g.door.body.get_meta("surface", -1)), Surface.Kind.WOOD)
	var z := g.spawn_zombie(Zombie.Type.WALKER, spawn + Vector3(0, 0, -6))
	await frames(2)
	assert_eq(Surface.of_hit(_ray(spawn + Vector3(0, 1.4, 0), spawn + Vector3(0, 1.4, -10))), Surface.Kind.FLESH, "a zombie")
	z.queue_free()


func test_each_surface_makes_its_own_impact() -> void:
	var g := await new_game()
	var fx := g.fx
	var at := Vector3(0, 1, -5)
	var n := Vector3(0, 0, 1)
	var lights := fx.lights_on()
	fx.play(Fx.Kind.IMPACT, at, n, Surface.Kind.METAL)
	assert_gt(fx.lights_on(), lights, "metal: a bright flash")
	assert_gt(fx.alive(Fx.Layer.GLOW), 0, "and sparks")
	var cracks := fx.decal_count(Fx.Mark.CRACK)
	fx.play(Fx.Kind.IMPACT, at, n, Surface.Kind.GLASS)
	assert_eq(fx.decal_count(Fx.Mark.CRACK), cracks + 1, "glass: a star crack")
	var puddles := fx.decal_count(Fx.Mark.PUDDLE)
	var holes := fx.decal_count(Fx.Mark.HOLE)
	fx.play(Fx.Kind.IMPACT, at, Vector3.UP, Surface.Kind.WATER)
	assert_eq(fx.decal_count(Fx.Mark.PUDDLE), puddles + 1, "water: rings")
	assert_eq(fx.decal_count(Fx.Mark.HOLE), holes, "and no hole")
	for kind in Surface.Kind.values():
		if kind == Surface.Kind.FLESH:
			continue
		var bursts: int = fx.stats.bursts
		var decals: int = fx.stats.decals
		fx.play(Fx.Kind.IMPACT, at, n, kind)
		assert_true(fx.stats.bursts > bursts and fx.stats.decals > decals, "%s makes something" % Surface.NAMES[kind])
	var colours := {}
	for kind in [Surface.Kind.CONCRETE, Surface.Kind.BRICK, Surface.Kind.WOOD, Surface.Kind.DIRT]:
		colours[str(Fx.IMPACT_DUST[kind])] = true
	assert_eq(colours.size(), 4, "each has its own dust")


func test_the_hole_lies_on_the_surface() -> void:
	var g := await new_game()
	var n := Vector3(1, 0, 0)
	g.fx.play(Fx.Kind.IMPACT, Vector3(2, 1, -3), n, Surface.Kind.CONCRETE)
	assert_lt(g.fx.last_decal.basis.y.normalized().distance_to(n), 0.01, "facing out of the wall")


func test_a_bullet_into_a_wall_makes_the_walls_impact() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	await frames(2)
	var spawn := g.map.player_spawn()
	var holes := g.fx.decal_count(Fx.Mark.HOLE)
	g.resolve_shot(1, spawn + Vector3(0, 1.5, 0), Vector3(-1, 0, 0), Weapons.AK47)
	assert_eq(g.fx.last_kind, Fx.Kind.IMPACT)
	assert_eq(g.fx.decal_count(Fx.Mark.HOLE), holes + 1)


func test_a_shotgun_makes_one_puff_and_a_hole_per_pellet() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	await frames(2)
	var spawn := g.map.player_spawn()
	var impacts: int = g.fx.stats.impacts
	var holes := g.fx.decal_count(Fx.Mark.HOLE)
	g.resolve_shot(1, spawn + Vector3(0, 1.5, 0), Vector3(-1, 0, 0), Weapons.SPAS12)
	assert_eq(g.fx.stats.impacts, impacts + 1, "one puff for the pattern")
	assert_eq(g.fx.decal_count(Fx.Mark.HOLE), holes + int(Weapons.def(Weapons.SPAS12).pellets), "a hole for each pellet")
