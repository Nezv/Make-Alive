extends TestCase
## Bite variants (tools/models/bites.py -> assets/models/zombie_<outfit>_<m|f>_b<N>.glb): the ten
## named regions torn out of an outfit's flesh and clothes together. A variant is its outfit's
## model with a hole in one or two of its rigid pieces: it wears the outfit's own textures (one
## albedo and one emission map in memory for all eleven), keeps every piece closed so a gib or a
## stump shows no hole, and is picked from the zombie's id so every peer sees the same bite.

const O := Characters.Outfit
const OutfitTests := preload("res://tests/test_outfit_models.gd")


func _tris(m: Mesh) -> int:
	return m.get_faces().size() / 3


func _total(m: CharacterModel) -> int:
	return _tris(m.mesh)


## The first distance a ray hits the model's mesh at, from `from` along `dir` (-1: none).
func _hit(m: CharacterModel, from: Vector3, dir: Vector3) -> float:
	var faces := m.mesh.get_faces()
	var best := -1.0
	for i in range(0, faces.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(from, dir, faces[i], faces[i + 1], faces[i + 2])
		if hit != null:
			var d := from.distance_to(hit as Vector3)
			if best < 0.0 or d < best:
				best = d
	return best


func test_there_are_ten_named_bites_and_every_outfit_has_each_on_both_bodies() -> void:
	assert_eq(Characters.BITES.size(), 10, "ten bites")
	for outfit in Characters.FEMALE_SHARE.size():
		for female in [false, true]:
			for bite in Characters.BITES.size():
				var path := CharacterModel.outfit_path(Characters.OUTFIT_NAMES[outfit], female, bite)
				assert_true(ResourceLoader.exists(path + ".glb"), "%s exists" % path.get_file())
	assert_eq(CharacterModel.outfit_path("nurse", true, 3), "res://assets/models/zombie_nurse_f_b3", "naming")
	assert_eq(CharacterModel.outfit_path("nurse", true), "res://assets/models/zombie_nurse_f", "no bite, no suffix")


func test_a_bite_is_a_real_hole_you_can_see_into() -> void:
	for outfit in [O.NURSE, O.COP, O.FIREFIGHTER]:
		for female in [false, true]:
			var name: String = Characters.OUTFIT_NAMES[outfit]
			var plain := CharacterModel.outfit(name, female)
			for bite in Characters.BITES.size():
				var b: Dictionary = Characters.BITES[bite]
				var dir: Vector3 = (b.to as Vector3).normalized()
				var from: Vector3 = (b.at as Vector3) - dir * 0.3
				var model := CharacterModel.outfit(name, female, bite)
				var d0 := _hit(plain, from, dir)
				var d1 := _hit(model, from, dir)
				var n := "%s %s bite %s" % [name, "f" if female else "m", b.name]
				assert_gt(d0, 0.0, n + ": the plain model is there")
				assert_gt(d1, d0 + 0.02, n + ": the surface is gone, what you see is deeper")
				assert_lt(d1, d0 + 0.2, n + ": and something closes the hole (flesh, bone), no seeing through")


func test_every_piece_of_a_bitten_model_is_closed() -> void:
	for outfit in [O.NURSE, O.COP]:
		for female in [false, true]:
			for bite in Characters.BITES.size():
				var m := CharacterModel.outfit(Characters.OUTFIT_NAMES[outfit], female, bite)
				assert_eq(m.parts.size(), 10, "ten pieces")
				for seg_name: String in m.parts:
					var n := "%s of %s %s bite %d" % [seg_name, Characters.OUTFIT_NAMES[outfit], "f" if female else "m", bite]
					assert_eq(OutfitTests._open_edges(m.parts[seg_name]), 0, n + " is closed")


func test_a_bite_changes_only_the_pieces_it_reaches() -> void:
	var plain := CharacterModel.outfit("nurse", true)
	var forearm := CharacterModel.outfit("nurse", true, Characters.BITES.find_custom(func(b): return b.name == "forearm_l"))
	assert_gt(_tris(forearm.parts.forearm_l), _tris(plain.parts.forearm_l) + 20, "the bitten forearm has its crater")
	for seg_name in ["torso", "head", "thigh_l", "thigh_r", "shin_l", "shin_r", "forearm_r", "upper_arm_r"]:
		assert_eq(_tris(forearm.parts[seg_name]), _tris(plain.parts[seg_name]), "%s is untouched" % seg_name)
	var shoulder := CharacterModel.outfit("nurse", true, Characters.BITES.find_custom(func(b): return b.name == "shoulder_l"))
	assert_gt(_tris(shoulder.parts.torso), _tris(plain.parts.torso), "the shoulder is part of the torso piece")
	var arm := CharacterModel.outfit("nurse", true, Characters.BITES.find_custom(func(b): return b.name == "upper_arm_r"))
	assert_gt(_tris(arm.parts.upper_arm_r), _tris(plain.parts.upper_arm_r), "an upper arm bite is in the arm")
	assert_gt(_tris(arm.parts.torso), _tris(plain.parts.torso), "and where it reaches the torso, in that: each piece closes its own side")


func test_variants_share_their_outfits_textures_and_stay_low_poly() -> void:
	for outfit in [O.CIVILIAN, O.DOCTOR, O.SOLDIER]:
		var name: String = Characters.OUTFIT_NAMES[outfit]
		var plain := CharacterModel.outfit(name, false)
		for bite in Characters.BITES.size():
			var m := CharacterModel.outfit(name, false, bite)
			var n := "%s bite %d" % [name, bite]
			assert_true(m.material.albedo_texture == plain.material.albedo_texture, n + ": one albedo in memory")
			assert_true(m.material.emission_texture == plain.material.emission_texture, n + ": one emission map")
			assert_eq(m.skin.get_bind_count(), plain.skin.get_bind_count(), n + ": the same joints")
			assert_lt(_total(m), _total(plain) + 1400, n + ": close to the plain model in triangles")
			assert_lt(_total(m), 5000, n + " is still low poly")


func test_a_bitten_limb_comes_off_closed_with_its_bite() -> void:
	var idx: int = Characters.BITES.find_custom(func(b): return b.name == "forearm_l")
	var rig := Humanoid.create_model(CharacterModel.outfit("cop", false, idx), {"zombie": true})
	add_child(rig)
	var segs := rig.sever(Humanoid.Part.ARM_L)
	assert_eq(segs.size(), 2, "upper arm and forearm come off")
	for seg: Dictionary in segs:
		var mesh := (seg.mesh as MeshInstance3D).mesh as ArrayMesh
		assert_eq(OutfitTests._open_edges(mesh), 0, "%s is closed" % seg.name)
	Humanoid.discard(segs)
	rig.free()


func test_the_bite_follows_the_pose() -> void:
	# The crater rides the same joints as the flesh round it: bent, it stays on its limb.
	var idx: int = Characters.BITES.find_custom(func(b): return b.name == "upper_arm_r")
	var m := CharacterModel.outfit("civilian", true, idx)
	var plain := CharacterModel.outfit("civilian", true)
	for helper in ["shoulder_r_mid", "hip_r_mid", "knee_r_mid"]:
		var got := OutfitTests._weights_on(m, helper)
		var full := 0
		for v in got:
			if v > 0.99:
				full += 1
		assert_gt(full, 7, "%s still carries its ring of cloth" % helper)
	assert_gt(_tris(m.parts.upper_arm_r), _tris(plain.parts.upper_arm_r), "the crater is part of the upper arm")


func test_a_zombies_bite_is_picked_from_its_id() -> void:
	var seen := {}
	var bitten := 0
	for id in range(1, 2001):
		var b := Characters.bite_for(id, id % 9)
		assert_eq(b, Characters.bite_for(id, id % 9), "the same on every peer")
		assert_true(b >= -1 and b < Characters.BITES.size(), "a known bite or none")
		if b >= 0:
			bitten += 1
			seen[b] = true
	assert_eq(seen.size(), Characters.BITES.size(), "every bite turns up in a crowd")
	assert_gt(bitten, 2000 * Config.BITE_SHARE * 0.8, "about the share the config says")
	assert_lt(bitten, 2000 * Config.BITE_SHARE * 1.2, "and not more")
	assert_eq(Characters.bite_for(5, Characters.Outfit.FERAL), -1, "the feral leaper has no model to bite")


func test_a_bitten_walker_wears_its_variant_and_the_plain_ones_share_the_outfits_mesh() -> void:
	var found_bitten := false
	var found_plain := false
	for id in range(1, 400):
		var outfit := Characters.outfit_for(id, Zombie.Type.WALKER)
		var bite := Characters.bite_for(id, outfit)
		var z := Characters.zombie(id, Zombie.Type.WALKER)
		var female := Characters.is_female(id, outfit)
		var want := CharacterModel.outfit(Characters.OUTFIT_NAMES[outfit], female, bite)
		assert_true(z.body_mesh.mesh == want.mesh, "zombie %d wears bite %d" % [id, bite])
		z.free()
		found_bitten = found_bitten or bite >= 0
		found_plain = found_plain or bite < 0
		if found_bitten and found_plain and id > 60:
			break
	assert_true(found_bitten and found_plain, "a crowd has both")


func test_a_game_loads_every_bite_before_the_first_spawn() -> void:
	CharacterModel._cache.clear()
	var t0 := Time.get_ticks_msec()
	var g := await new_game()
	var seconds := (Time.get_ticks_msec() - t0) / 1000.0
	assert_eq(Characters.model_paths().size(), 18 * 11, "every outfit, body and bite")
	for path in Characters.model_paths():
		assert_true(CharacterModel._cache.has(path), "no hitch when %s shows up" % path.get_file())
	assert_lt(seconds, 20.0, "loading them all stays a matter of seconds")
	assert_true(g != null)
