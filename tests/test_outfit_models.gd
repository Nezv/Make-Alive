extends TestCase
## The zombies' outfits (tools/models/outfits.py -> assets/models/zombie_<outfit>_<m|f>.glb): the
## male and female bodies dressed in clothes made as one continuous surface (a sleeve grows out of
## the shirt, both legs out of the trousers) that bends on helper bones turning half as far as
## their joints, and comes apart into closed rigid pieces where it was made to be cut.

const O := Characters.Outfit


func _outfits() -> Array:
	return range(Characters.FEMALE_SHARE.size())


func _rig(outfit: int, female: bool) -> Humanoid:
	var rig := Humanoid.create_model(CharacterModel.outfit(Characters.OUTFIT_NAMES[outfit], female), {"zombie": true})
	add_child(rig)
	return rig


func _visible_meshes(n: Node, out: Array) -> Array:
	if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_visible_meshes(c, out)
	return out


func _tris(m: Mesh) -> int:
	return m.get_faces().size() / 3


## Edges not shared by exactly two triangles, once flat-shaded corners are welded back by position.
static func _open_edges(mesh: ArrayMesh) -> int:
	var a := mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var weld := {}
	var id_of := PackedInt32Array()
	for v in vs:
		var key := Vector3i((v * 2000.0).round())
		if not weld.has(key):
			weld[key] = weld.size()
		id_of.append(weld[key])
	var edges := {}
	for t in range(0, idx.size(), 3):
		for k in 3:
			var p := id_of[idx[t + k]]
			var q := id_of[idx[t + (k + 1) % 3]]
			if p == q:
				continue
			var key := Vector2i(mini(p, q), maxi(p, q))
			edges[key] = edges.get(key, 0) + 1
	var open := 0
	for c: int in edges.values():
		if c != 2:
			open += 1
	return open


## How much each vertex rides `bone` (its weight there), by vertex.
static func _weights_on(m: CharacterModel, bone: String) -> PackedFloat32Array:
	var a := m.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var ws: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / vs.size()
	var out := PackedFloat32Array()
	out.resize(vs.size())
	for v in vs.size():
		for k in per:
			if String(m.skin.get_bind_name(bones[v * per + k])) == bone:
				out[v] += ws[v * per + k]
	return out


func test_every_outfit_is_one_skinned_textured_mesh_on_both_bodies() -> void:
	for outfit: int in _outfits():
		for female in [false, true]:
			var rig := _rig(outfit, female)
			var n := "%s %s" % [Characters.OUTFIT_NAMES[outfit], "f" if female else "m"]
			assert_eq(rig.skeleton.get_bone_count(), CharacterModel.JOINTS.size(), n + ": the game's joints and the helpers")
			var shown := _visible_meshes(rig, [])
			assert_eq(shown.size(), 1, n + ": one mesh drawn, body and clothes together")
			var body: MeshInstance3D = shown[0]
			assert_true(body.skin != null, n + " is skinned")
			assert_eq(body.mesh.get_surface_count(), 1, n + ": one surface, one draw call")
			var mat := body.get_active_material(0) as StandardMaterial3D
			assert_true(mat.albedo_texture != null and mat.emission_texture != null, n + ": painted, eyes glowing")
			assert_eq(mat.cull_mode, BaseMaterial3D.CULL_DISABLED, n + ": a fold seen from behind is still cloth")
			assert_lt(_tris(body.mesh), 5000, n + " is still low poly")
			rig.free()


func test_they_stand_on_the_floor_facing_forward() -> void:
	for outfit: int in _outfits():
		for female in [false, true]:
			var box := CharacterModel.outfit(Characters.OUTFIT_NAMES[outfit], female).mesh.get_aabb()
			var n: String = Characters.OUTFIT_NAMES[outfit]
			assert_near(box.position.y, 0.0, 0.01, n + ": shoes on the floor")
			assert_gt(box.end.y, 1.85, n + ": full height")
			assert_lt(box.end.y, 2.1, n + ": a hat at most on top")
			assert_lt(box.position.z, -0.15, n + ": face and toes point at -Z")
			assert_lt(box.size.x, 0.95, n + ": arms down at the sides")


func test_every_piece_is_closed_so_gibs_and_stumps_show_no_holes() -> void:
	for outfit: int in _outfits():
		for female in [false, true]:
			var m := CharacterModel.outfit(Characters.OUTFIT_NAMES[outfit], female)
			assert_eq(m.parts.size(), 10, "ten pieces")
			for seg_name: String in m.parts:
				var n := "%s of %s %s" % [seg_name, Characters.OUTFIT_NAMES[outfit], "f" if female else "m"]
				assert_gt(_tris(m.parts[seg_name]), 40, n + " has its own share of the model")
				assert_eq(_open_edges(m.parts[seg_name]), 0, n + " is closed")


func test_a_sleeve_comes_off_where_it_was_cut_and_carries_the_hand() -> void:
	var m := CharacterModel.outfit("cop")
	var rest := CharacterModel.rest_positions()
	var elbow := rest[CharacterModel.JOINTS.find("elbow_r")]
	var shoulder := rest[CharacterModel.JOINTS.find("shoulder_r")]
	var forearm: AABB = (m.parts.forearm_r as Mesh).get_aabb()
	assert_lt(forearm.position.y + elbow.y, 0.75, "the hand goes with the forearm")
	assert_lt(forearm.end.y + elbow.y, elbow.y, "cut just below the elbow: the elbow's fold stays with the upper arm")
	var upper: AABB = (m.parts.upper_arm_r as Mesh).get_aabb()
	assert_gt(upper.position.y + shoulder.y, elbow.y - 0.08, "the upper arm ends at the elbow")
	assert_lt(upper.end.y + shoulder.y, 1.36, "cut from the shirt under the armpit: the shoulder stays on the torso")


func test_clothes_bend_on_helpers_and_the_armhole_follows_the_arm() -> void:
	for female in [false, true]:
		var m := CharacterModel.outfit("civilian", female)
		for helper in ["shoulder_l_mid", "shoulder_r_mid", "hip_l_mid", "hip_r_mid", "knee_l_mid", "knee_r_mid"]:
			var w := _weights_on(m, helper)
			var full := 0
			for v in w:
				if v > 0.99:
					full += 1
			assert_gt(full, 7, "a ring of cloth rides %s" % helper)
		var shared := 0
		var spine := _weights_on(m, "spine")
		var mid := _weights_on(m, "shoulder_r_mid")
		for v in spine.size():
			if spine[v] > 0.2 and mid[v] > 0.2:
				shared += 1
		assert_gt(shared, 5, "the armhole is part shirt, part sleeve: no break at the shoulder")
	var cop := CharacterModel.outfit("cop")
	assert_gt(Array(_weights_on(cop, "elbow_r_mid")).filter(func(v): return v > 0.99).size(), 7, "long sleeves bend at the elbow")


func test_helpers_turn_half_as_far_as_their_joints() -> void:
	var rig := _rig(O.SOLDIER, false)
	rig.set_anim(Humanoid.Anim.ATTACK)
	for i in 10:
		rig.update(1.0 / 60.0, 0.0)
	var sk := rig.skeleton
	for h: int in CharacterModel.HELPER_OF:
		var j: int = CharacterModel.HELPER_OF[h]
		var want := Quaternion.IDENTITY.slerp(sk.get_bone_pose_rotation(j), 0.5)
		assert_true(sk.get_bone_pose_rotation(h).is_equal_approx(want), "%s turns half as far" % CharacterModel.JOINTS[h])
	assert_gt(sk.get_bone_pose_rotation(sk.find_bone("shoulder_r")).get_angle(), 2.0, "the arms are up")
	rig.free()


func test_a_shot_off_arm_leaves_the_sleeve_root_at_rest() -> void:
	var rig := _rig(O.OFFICE, true)
	rig.set_anim(Humanoid.Anim.WALK)
	for i in 30:
		rig.update(1.0 / 60.0, 1.0)
	var sk := rig.skeleton
	var helper := sk.find_bone("shoulder_l_mid")
	assert_gt(sk.get_bone_pose_rotation(helper).get_angle(), 0.3, "while it is on, the sleeve root follows the arm")
	var segs := rig.sever(Humanoid.Part.ARM_L)
	assert_eq(segs.size(), 2, "upper arm and forearm come off")
	for seg: Dictionary in segs:
		assert_true((seg.mesh as MeshInstance3D).visible, "%s shows, ready to fly" % seg.name)
	rig.update(1.0 / 60.0, 1.0)
	assert_lt(sk.get_bone_pose_scale(sk.find_bone("shoulder_l")).x, 0.01, "the arm shrinks away on the skinned body")
	assert_true(sk.get_bone_pose_rotation(helper).is_equal_approx(Quaternion.IDENTITY), "the stump's ring of cloth stays put")
	assert_false(sk.get_bone_pose_rotation(sk.find_bone("shoulder_r_mid")).is_equal_approx(Quaternion.IDENTITY),
		"the other arm still bends its sleeve")
	Humanoid.discard(segs)
	var parts := rig.take_all()
	assert_eq(parts.size(), 8, "the ragdoll gets what is left")
	assert_false(rig.body_mesh.visible, "the pieces took over")
	rig.free()


func test_a_crowd_has_men_and_women_in_every_outfit() -> void:
	for outfit: int in _outfits():
		var women := 0
		for id in range(1, 201):
			if Characters.is_female(id, outfit):
				women += 1
			assert_eq(Characters.is_female(id, outfit), Characters.is_female(id, outfit), "picked from the id")
		var n: String = Characters.OUTFIT_NAMES[outfit]
		assert_gt(women, 20, n + ": some women")
		assert_lt(women, 180, n + ": some men")
	assert_false(Characters.has_model(O.FERAL), "the leaper keeps its feral body")


func test_walkers_wear_their_outfits_models_and_share_them() -> void:
	for path in Characters.model_paths(): # the game loads them before the first spawn
		CharacterModel.load_model(path)
	Characters.zombie(4, 0, O.COP).free()
	var t0 := Time.get_ticks_usec()
	for i in 20:
		Characters.zombie(4 + i, i % 2, i % 9).free()
	assert_lt((Time.get_ticks_usec() - t0) / 20000.0, 2.0, "milliseconds per zombie")
	for id in [3, 4, 5, 6, 7, 8]:
		var a := Characters.zombie(id, 0, O.NURSE)
		var b := Characters.zombie(id, 0, O.NURSE)
		var want := CharacterModel.outfit("nurse", Characters.is_female(id, O.NURSE), Characters.bite_for(id, O.NURSE))
		assert_true(a.body_mesh.mesh == want.mesh, "zombie %d wears the nurse (and bite) it should" % id)
		assert_true(a.body_mesh.mesh == b.body_mesh.mesh, "one mesh in memory for every one alike")
		a.free()
		b.free()


func test_a_game_loads_the_models_before_the_first_spawn() -> void:
	CharacterModel._cache.clear()
	var g := await new_game()
	for path in Characters.model_paths():
		assert_true(CharacterModel._cache.has(path), "no hitch when the first %s shows up" % path.get_file())
	assert_true(g != null)
