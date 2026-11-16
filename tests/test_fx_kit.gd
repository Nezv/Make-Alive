extends TestCase
## The effects kit: pooled particles, lights, decals and trails, their caps, the quality tiers,
## and the one RPC that carries an effect to every peer.


func _fx() -> Fx:
	var fx := Fx.new()
	add_child(fx)
	fx.set_tier("high") # full counts and lives, whatever the player's setting
	return fx


func test_burst_makes_particles_that_live_and_die() -> void:
	var fx := _fx()
	fx.burst(Fx.Layer.SMOKE, Vector3(0, 1, 0), Vector3.UP, 10, { "life": 0.5 })
	assert_eq(fx.alive(Fx.Layer.SMOKE), 10)
	assert_eq(fx.alive(Fx.Layer.CHIP), 0)
	fx.step(0.25)
	assert_eq(fx.alive(Fx.Layer.SMOKE), 10, "still there halfway")
	fx.step(0.3)
	assert_eq(fx.alive(Fx.Layer.SMOKE), 0, "gone after their life")
	fx.free()


func test_particles_move_along_the_burst_direction() -> void:
	var fx := _fx()
	fx.burst(Fx.Layer.GLOW, Vector3.ZERO, Vector3.RIGHT, 12, { "speed": 4.0, "spread": 0.1, "life": 1.0, "gravity": 0.0, "drag": 0.0 })
	fx.step(0.5)
	for p: Vector3 in fx.positions(Fx.Layer.GLOW):
		assert_gt(p.x, 1.0, "flew to the right")
		assert_lt(absf(p.y) + absf(p.z), 1.0, "in a narrow cone")
	fx.free()


func test_chips_fall_and_stay_on_the_ground() -> void:
	var fx := _fx()
	fx.ground = func(_p: Vector3) -> float: return 2.0
	fx.burst(Fx.Layer.CHIP, Vector3(0, 3, 0), Vector3.UP, 8, { "speed": 1.0, "life": 3.0, "gravity": 20.0 })
	for i in 60:
		fx.step(1.0 / 30.0)
	for p: Vector3 in fx.positions(Fx.Layer.CHIP):
		assert_gt(p.y, 1.99, "never below the floor")
		assert_lt(p.y, 2.3, "came to rest on it")
	fx.free()


func test_500_bursts_never_break_the_caps() -> void:
	var fx := _fx()
	var nodes := fx.get_child_count()
	for i in 500:
		var at := Vector3(i % 20, 1, i / 20)
		fx.burst(Fx.Layer.CHIP, at, Vector3.UP, 20, { "life": 5.0 })
		fx.burst(Fx.Layer.GLOW, at, Vector3.UP, 20, { "life": 5.0 })
		fx.burst(Fx.Layer.SMOKE, at, Vector3.UP, 20, { "life": 5.0 })
		fx.light(at, Color.ORANGE, 3.0, 6.0, 5.0)
		fx.decal(Fx.Mark.HOLE, at, Vector3.UP, 0.1)
		fx.decal(Fx.Mark.SCORCH, at, Vector3.UP, 1.0)
		if i % 50 == 0:
			fx.step(0.016)
	assert_eq(fx.alive(Fx.Layer.CHIP), Config.FX_MAX_CHIPS)
	assert_eq(fx.alive(Fx.Layer.GLOW), Config.FX_MAX_GLOWS)
	assert_eq(fx.alive(Fx.Layer.SMOKE), Config.FX_MAX_SMOKE)
	assert_eq(fx.lights_on(), Config.FX_MAX_LIGHTS)
	assert_eq(fx.decal_count(Fx.Mark.HOLE), Config.FX_MAX_DECALS)
	assert_eq(fx.decal_count(Fx.Mark.SCORCH), Config.FX_MAX_DECALS)
	assert_eq(fx.get_child_count(), nodes, "nothing was allocated: every node was made up front")
	fx.free()


func test_a_full_pool_reuses_the_oldest_particle() -> void:
	var fx := _fx()
	fx.burst(Fx.Layer.SMOKE, Vector3(100, 0, 0), Vector3.UP, 1, { "life": 9.0, "speed": 0.0 })
	fx.burst(Fx.Layer.SMOKE, Vector3.ZERO, Vector3.UP, Config.FX_MAX_SMOKE, { "life": 9.0, "speed": 0.0 })
	for p: Vector3 in fx.positions(Fx.Layer.SMOKE):
		assert_lt(p.x, 50.0, "the first puff gave up its slot")
	fx.free()


func test_lights_fade_out_and_never_cast_shadows() -> void:
	var fx := _fx()
	fx.light(Vector3(0, 2, 0), Color.ORANGE, 4.0, 8.0, 0.2)
	assert_eq(fx.lights_on(), 1)
	var lamp: OmniLight3D = null
	for c in fx.get_children():
		if c is OmniLight3D:
			assert_false((c as OmniLight3D).shadow_enabled, "pooled lights never cast shadows")
			if c.visible:
				lamp = c
	assert_true(lamp != null)
	assert_near(lamp.light_energy, 4.0, 0.01)
	assert_eq(lamp.global_position, Vector3(0, 2, 0))
	fx.step(0.1)
	assert_lt(lamp.light_energy, 3.0, "dimming")
	assert_gt(lamp.light_energy, 0.0)
	fx.step(0.15)
	assert_eq(fx.lights_on(), 0)
	assert_false(lamp.visible)
	fx.free()


func test_decals_lie_on_the_surface_they_hit() -> void:
	var fx := _fx()
	for normal: Vector3 in [Vector3.UP, Vector3.RIGHT, Vector3.BACK, Vector3(1, 1, 0).normalized()]:
		var xf := fx.decal(Fx.Mark.HOLE, Vector3(1, 2, 3), normal, 0.2)
		assert_near(xf.basis.y.normalized().dot(normal), 1.0, 0.001, "faces out of the surface")
		assert_near(xf.origin.distance_to(Vector3(1, 2, 3)), 0.0, 0.05, "sits on it")
		assert_near(xf.basis.x.length(), 0.2, 0.001, "at the asked size")
	assert_eq(fx.decal_count(Fx.Mark.HOLE), 4)
	assert_eq(fx.decal_count(Fx.Mark.PUDDLE), 0)
	fx.free()


func test_trail_follows_a_node_with_a_capped_length() -> void:
	var fx := _fx()
	var bullet := Node3D.new()
	add_child(bullet)
	var id := fx.trail(bullet, 0.05, Color.YELLOW, 0.3)
	assert_gt(id, -1)
	for i in Config.FX_TRAIL_POINTS * 3:
		bullet.position.x += 0.5
		fx.step(0.01)
	assert_eq(fx.trail_points(id), Config.FX_TRAIL_POINTS)
	assert_eq(fx.trails_on(), 1)
	bullet.free()
	fx.step(0.1)
	assert_eq(fx.trails_on(), 1, "the ribbon outlives what drew it for a moment")
	fx.step(0.3)
	assert_eq(fx.trails_on(), 0, "then fades")
	fx.free()


func test_trails_are_capped_too() -> void:
	var fx := _fx()
	var nodes := []
	for i in Config.FX_MAX_TRAILS + 5:
		var n := Node3D.new()
		add_child(n)
		nodes.append(n)
		fx.trail(n, 0.05, Color.WHITE, 1.0)
	assert_eq(fx.trails_on(), Config.FX_MAX_TRAILS)
	for n: Node3D in nodes:
		n.free()
	fx.free()


func test_quality_tiers_scale_the_counts() -> void:
	var fx := _fx()
	fx.set_tier("high")
	fx.burst(Fx.Layer.CHIP, Vector3.ZERO, Vector3.UP, 20)
	var high := fx.alive(Fx.Layer.CHIP)
	fx.clear()
	fx.set_tier("low")
	fx.burst(Fx.Layer.CHIP, Vector3.ZERO, Vector3.UP, 20)
	var low := fx.alive(Fx.Layer.CHIP)
	assert_eq(high, 20)
	assert_lt(low, high, "low draws fewer")
	assert_gt(low, 0, "but never nothing")
	fx.free()


func test_every_registered_effect_plays() -> void:
	var fx := _fx()
	assert_eq(Fx.NAMES.size(), Fx.Kind.size(), "a name per effect, for the rack")
	for kind: int in Fx.Kind.values():
		var before: int = fx.stats.played
		fx.play(kind, Vector3(0, 1, 0), Vector3.UP, 1.0)
		assert_eq(fx.stats.played, before + 1, Fx.NAMES[kind])
		fx.step(0.016)
	fx.play(999, Vector3.ZERO, Vector3.UP)
	fx.play(-1, Vector3.ZERO, Vector3.UP)
	assert_eq(fx.stats.played, Fx.Kind.size(), "unknown kinds from the wire are ignored")
	assert_gt(fx.alive(Fx.Layer.SMOKE) + fx.alive(Fx.Layer.GLOW) + fx.alive(Fx.Layer.CHIP), 0)
	fx.free()


func test_host_effect_plays_on_the_host_through_the_game() -> void:
	var g := await new_game()
	var before: int = g.fx.stats.played
	g.play_fx(Fx.Kind.BLAST, Vector3(0, 1, 20), Vector3.UP, 1.0)
	assert_eq(g.fx.stats.played, before + 1)
	assert_gt(g.fx.lights_on(), 0, "an explosion lights the room")
