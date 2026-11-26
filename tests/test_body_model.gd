extends TestCase
## The generic bodies every outfit model is built on (tools/models/body.py ->
## assets/models/zombie_body_m.glb and zombie_body_f.glb): low-poly and flat-shaded like
## references/zombies.png, one closed piece per body part riding one joint of the game's
## skeleton, a male and a female on the same rig.


func _rig(female: bool) -> Humanoid:
	var rig := Humanoid.create_model(CharacterModel.body(female), {"zombie": true})
	add_child(rig)
	return rig


func _visible_meshes(n: Node, out: Array) -> Array:
	if n is MeshInstance3D and (n as MeshInstance3D).is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_visible_meshes(c, out)
	return out


## The widest |x| of the torso piece between two heights (model space).
func _torso_width(m: CharacterModel, y0: float, y1: float) -> float:
	var spine := CharacterModel.rest_positions()[CharacterModel.JOINTS.find("spine")]
	var w := 0.0
	for v: Vector3 in m.parts.torso.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		var y := v.y + spine.y
		if y >= y0 and y <= y1:
			w = maxf(w, absf(v.x))
	return w


func test_both_bodies_are_one_skinned_textured_mesh_on_the_games_skeleton() -> void:
	for female in [false, true]:
		var rig := _rig(female)
		assert_eq(rig.skeleton.get_bone_count(), CharacterModel.JOINTS.size(), "the game's joints")
		var shown := _visible_meshes(rig, [])
		assert_eq(shown.size(), 1, "one mesh drawn")
		var body: MeshInstance3D = shown[0]
		assert_true(body.skin != null, "skinned")
		assert_eq(body.mesh.get_surface_count(), 1, "one surface, one draw call")
		var mat := body.get_active_material(0) as StandardMaterial3D
		assert_true(mat.albedo_texture != null and mat.emission_texture != null, "painted, with glowing eyes")
		rig.free()


func test_low_poly_with_flat_faces_never_curves() -> void:
	for female in [false, true]:
		var m := CharacterModel.body(female)
		var tris := m.mesh.get_faces().size() / 3
		assert_gt(tris, 1500, "a whole body")
		assert_lt(tris, 4000, "low poly like the reference")
		var a := m.mesh.surface_get_arrays(0)
		var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
		var smooth := 0
		for t in range(0, idx.size(), 3):
			var n0 := ns[idx[t]]
			if not (n0.is_equal_approx(ns[idx[t + 1]]) and n0.is_equal_approx(ns[idx[t + 2]])):
				smooth += 1
		assert_eq(smooth, 0, "every triangle is flat: one normal for its three corners")


func test_they_stand_on_the_floor_facing_forward_at_the_games_size() -> void:
	for female in [false, true]:
		var box := CharacterModel.body(female).mesh.get_aabb()
		assert_near(box.position.y, 0.0, 0.01, "feet on the floor")
		assert_gt(box.end.y, 1.85, "full height")
		# the head hitbox (Humanoid.MODEL_SEGMENTS) ends 1.88 m up: the hair may stick out a little
		assert_lt(box.end.y, 1.95, "the head stays near its hitbox")
		assert_lt(box.position.z, -0.15, "face and toes point at -Z")


func test_big_head_and_big_hands_like_the_reference() -> void:
	var m := CharacterModel.body(false)
	var head: AABB = (m.parts.head as Mesh).get_aabb()
	assert_gt(head.size.x, 0.28, "a big head (ears included)")
	var forearm: AABB = (m.parts.forearm_r as Mesh).get_aabb()
	var elbow := CharacterModel.rest_positions()[CharacterModel.JOINTS.find("elbow_r")]
	assert_lt(forearm.position.y + elbow.y, 0.7, "the fingers hang to mid-thigh")
	assert_gt(forearm.size.z, 0.12, "a hand wider than the wrist")


func test_the_female_is_narrower_at_the_waist_and_shoulders_and_rounder_at_the_hips() -> void:
	var m := CharacterModel.body(false)
	var f := CharacterModel.body(true)
	assert_lt(_torso_width(f, 1.4, 1.5), _torso_width(m, 1.4, 1.5) - 0.02, "narrower chest and shoulders")
	assert_lt(_torso_width(f, 1.03, 1.1), _torso_width(m, 1.03, 1.1) - 0.02, "narrower waist")
	assert_gt(_torso_width(f, 0.9, 1.0) - _torso_width(f, 1.03, 1.1),
		_torso_width(m, 0.9, 1.0) - _torso_width(m, 1.03, 1.1) + 0.02, "hips flare from the waist")


func test_the_shoulder_is_the_torsos_and_the_arm_starts_under_it() -> void:
	for female in [false, true]:
		var m := CharacterModel.body(female)
		var rest := CharacterModel.rest_positions()
		var arm: AABB = (m.parts.upper_arm_r as Mesh).get_aabb()
		var shoulder := rest[CharacterModel.JOINTS.find("shoulder_r")]
		assert_lt(arm.end.y + shoulder.y, 1.49, "no bump: the arm ends below the shoulder line")
		var arm_x := arm.get_center().x + shoulder.x
		assert_gt(_torso_width(m, 1.44, 1.5), arm_x + 0.03, "the torso's ledge reaches out over the arm")


## Vertices of the torso and how much the spine (rather than the hips) moves each one.
func _torso_spine_weights(m: CharacterModel) -> Array:
	var a := m.mesh.surface_get_arrays(0)
	var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
	var ws: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
	var per := bones.size() / vs.size()
	var out := []
	for v in vs.size():
		var spine := 0.0
		var trunk := 0.0
		for k in per:
			var bone_name := String(m.skin.get_bind_name(bones[v * per + k]))
			if bone_name == "spine":
				spine += ws[v * per + k]
			if bone_name == "spine" or bone_name == "hips":
				trunk += ws[v * per + k]
		if trunk > 0.99:
			out.append([vs[v], spine])
	return out


func test_the_torso_breaks_along_an_upside_down_v_that_bends_closed() -> void:
	for female in [false, true]:
		var m := CharacterModel.body(female)
		var front := -1.0
		var side := 9.0
		var shared := 0
		for vw: Array in _torso_spine_weights(m):
			var v: Vector3 = vw[0]
			if absf(vw[1] - 0.5) > 0.05:
				continue
			shared += 1 # on the break: half hips, half spine, on both pieces
			if absf(v.x) < 0.02 and v.z < -0.05:
				front = maxf(front, v.y)
			if absf(v.x) > 0.17:
				side = minf(side, v.y)
		assert_gt(shared, 15, "a ring of vertices shared by chest and pelvis")
		assert_gt(front - side, 0.08, "high in the middle of the belly, low at the sides")
		assert_near(side, Humanoid.HIP_HEIGHT, 0.05, "at the sides it is level with the hip joints, where the spine turns")


func test_a_severed_leg_or_head_shows_bone() -> void:
	var m := CharacterModel.body(false)
	var thigh: AABB = (m.parts.thigh_r as Mesh).get_aabb()
	assert_gt(thigh.end.y, 0.08, "the thigh bone sticks out above the flesh, into the hips")
	var head: AABB = (m.parts.head as Mesh).get_aabb()
	var neck := CharacterModel.rest_positions()[CharacterModel.JOINTS.find("neck")]
	assert_lt(head.position.y + neck.y, 1.45, "a neck bone below the neck, inside the chest")


func test_every_part_is_a_closed_piece_so_gibs_show_no_holes() -> void:
	for female in [false, true]:
		var m := CharacterModel.body(female)
		assert_eq(m.parts.size(), 10, "ten segments")
		for seg_name: String in m.parts:
			var mesh: ArrayMesh = m.parts[seg_name]
			var vs: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
			var weld := {}
			var id_of := PackedInt32Array()
			for v in vs: # flat faces split their corners: join them back by position
				var key := Vector3i((v * 2000.0).round())
				if not weld.has(key):
					weld[key] = weld.size()
				id_of.append(weld[key])
			var edges := {}
			for t in range(0, idx.size(), 3):
				for k in 3:
					var a := id_of[idx[t + k]]
					var b := id_of[idx[t + (k + 1) % 3]]
					if a == b:
						continue
					var key := Vector2i(mini(a, b), maxi(a, b))
					edges[key] = edges.get(key, 0) + 1
			var open := 0
			for c: int in edges.values():
				if c != 2:
					open += 1
			assert_eq(open, 0, "%s of the %s body is closed" % [seg_name, "female" if female else "male"])


func test_parts_come_off_and_ragdoll_like_any_model_zombie() -> void:
	for female in [false, true]:
		var rig := _rig(female)
		var arm := rig.sever(Humanoid.Part.ARM_R)
		assert_eq(arm.size(), 2, "upper arm and forearm")
		assert_lt(rig.skeleton.get_bone_pose_scale(rig.skeleton.find_bone("shoulder_r")).x, 0.01, "gone from the body")
		Humanoid.discard(arm)
		var parts := rig.take_all()
		assert_eq(parts.size(), 8, "what's left")
		assert_false(rig.body_mesh.visible, "the pieces took over")
		rig.free()


func test_the_bones_follow_the_procedural_animation() -> void:
	var rig := _rig(true)
	rig.set_anim(Humanoid.Anim.ATTACK)
	for i in 12:
		rig.update(1.0 / 60.0, 0.0)
	var sk := rig.skeleton
	var q: Quaternion = sk.get_bone_pose_rotation(sk.find_bone("shoulder_l"))
	assert_true(q.is_equal_approx(rig.shoulder_l.quaternion), "the arm bone turns with its joint")
	assert_gt(sk.get_bone_global_pose(sk.find_bone("elbow_l")).origin.y, 1.25, "the attack raises the arms")
	rig.free()
