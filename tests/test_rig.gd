extends TestCase
## The jointed procedural rig: every animation state must produce a sane pose.


func test_every_animation_runs_without_nan_and_keeps_feet_near_the_ground() -> void:
	var rig := Characters.zombie(1, Zombie.Type.WALKER)
	add_child(rig)
	for anim in Humanoid.Anim.values():
		rig.set_anim(anim)
		for i in 40:
			rig.update(1.0 / 60.0, 2.0)
		for seg: Dictionary in rig.segs.values():
			var p: Vector3 = (seg.node as Node3D).global_position
			assert_true(is_finite(p.x) and is_finite(p.y) and is_finite(p.z), "finite pose in anim %d" % anim)
			assert_gt(p.y, -0.3, "%s not under the floor in anim %d" % [seg.name, anim])
			assert_lt(p.y, 2.6, "%s not sky-high in anim %d" % [seg.name, anim])
	rig.free()


func test_poses_blend_smoothly_between_states() -> void:
	var rig := Characters.zombie(2, Zombie.Type.WALKER)
	add_child(rig)
	rig.set_anim(Humanoid.Anim.WALK)
	for i in 30:
		rig.update(1.0 / 60.0, 2.0)
	var before := rig.hips.position.y
	rig.set_anim(Humanoid.Anim.CRAWL)
	rig.update(1.0 / 60.0, 1.0)
	assert_lt(absf(rig.hips.position.y - before), 0.25, "one frame after switching, the hips haven't snapped down")
	for i in 60:
		rig.update(1.0 / 60.0, 1.0)
	assert_lt(rig.hips.position.y, 0.45, "a second later it's on the ground")
	rig.free()


func test_sever_removes_the_whole_limb_and_leaves_a_stump() -> void:
	var rig := Characters.zombie(3, Zombie.Type.WALKER)
	add_child(rig)
	var segs := rig.sever(Humanoid.Part.ARM_R)
	assert_eq(segs.size(), 2, "upper arm and forearm")
	assert_true(rig.is_severed(Humanoid.Part.ARM_R))
	assert_eq(rig.sever(Humanoid.Part.ARM_R).size(), 0, "can't sever twice")
	Humanoid.discard(segs)
	rig.free()


func test_hit_reaction_decays_back_to_rest() -> void:
	var rig := Characters.zombie(4, Zombie.Type.WALKER)
	add_child(rig)
	rig.hit_react(Vector3.BACK, 1.0)
	rig.update(1.0 / 60.0, 0.0)
	assert_gt(rig.flinch.length(), 0.01, "flinches")
	for i in 180:
		rig.update(1.0 / 60.0, 0.0)
	assert_lt(rig.flinch.length(), 0.02, "and settles")
	rig.free()


func test_legless_zombie_stays_on_the_ground_in_every_state() -> void:
	var rig := Characters.zombie(5, Zombie.Type.LEAPER)
	add_child(rig)
	Humanoid.discard(rig.sever(Humanoid.Part.LEG_L))
	for anim in [Humanoid.Anim.CRAWL, Humanoid.Anim.ATTACK, Humanoid.Anim.STAGGER, Humanoid.Anim.IDLE]:
		rig.set_anim(anim)
		for i in 60:
			rig.update(1.0 / 60.0, 0.5)
			if i > 40:
				assert_lt(rig.hips.position.y, 0.45, "hips low in anim %d (no floating torsos)" % anim)
	rig.free()
