extends TestCase
## The skeleton (tools/models/skeleton.py -> assets/models/zombie_skeleton.glb): low-poly bones
## made like the bodies and fitted inside them, each bone on the joint its body piece rides, so
## it animates and comes apart like any model zombie.


func test_a_skeleton_is_one_skinned_mesh_on_the_games_joints() -> void:
	var rig := Humanoid.create_model(CharacterModel.skeleton(), {"zombie": true})
	add_child(rig)
	assert_eq(rig.skeleton.get_bone_count(), CharacterModel.JOINTS.size(), "the game's joints")
	assert_true(rig.body_mesh.skin != null, "skinned")
	var mat := rig.body_mesh.get_active_material(0) as StandardMaterial3D
	assert_true(mat.albedo_texture != null and mat.emission_texture != null, "painted bone, eyes glowing in the sockets")
	rig.free()


func test_low_poly_and_flat_like_the_bodies() -> void:
	var m := CharacterModel.skeleton()
	var tris := m.mesh.get_faces().size() / 3
	assert_gt(tris, 2000, "ribs, spine, hands and feet")
	assert_lt(tris, 5000, "still low poly")
	var a := m.mesh.surface_get_arrays(0)
	var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = a[Mesh.ARRAY_INDEX]
	var smooth := 0
	for t in range(0, idx.size(), 3):
		if not (ns[idx[t]].is_equal_approx(ns[idx[t + 1]]) and ns[idx[t]].is_equal_approx(ns[idx[t + 2]])):
			smooth += 1
	assert_eq(smooth, 0, "flat faces")


func test_it_fits_inside_the_male_body() -> void:
	var bones := CharacterModel.skeleton()
	var body := CharacterModel.body(false)
	var outer := body.mesh.get_aabb().grow(0.01)
	var inner := bones.mesh.get_aabb()
	assert_true(outer.encloses(inner), "every bone inside the body's outline")
	var head: AABB = (body.parts.head as Mesh).get_aabb().grow(0.005)
	assert_true(head.encloses((bones.parts.head as Mesh).get_aabb()), "the skull inside the head")
	for seg_name: String in ["thigh_l", "shin_r", "forearm_l"]:
		var flesh: AABB = (body.parts[seg_name] as Mesh).get_aabb().grow(0.01)
		assert_true(flesh.encloses((bones.parts[seg_name] as Mesh).get_aabb()), "%s's bones inside it" % seg_name)


func test_it_comes_apart_like_any_model_zombie() -> void:
	var rig := Humanoid.create_model(CharacterModel.skeleton(), {"zombie": true})
	add_child(rig)
	assert_eq(rig.segs.size(), 10, "ten pieces")
	var head := rig.sever(Humanoid.Part.HEAD)
	assert_eq(head.size(), 1, "the skull comes off")
	assert_gt((head[0].mesh as MeshInstance3D).mesh.get_faces().size() / 3, 200, "with its own bones")
	Humanoid.discard(head)
	rig.free()
