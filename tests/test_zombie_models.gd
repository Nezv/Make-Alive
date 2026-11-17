extends TestCase
## The round body in the style of references/zombies.png (what corpses, the feral leaper and
## survivors wear; walking zombies wear outfit models, tests/test_outfit_models.gd): round limbs
## and body, a real face (brows, sunken eyes, nose, a gaping mouth with teeth, ears), blood
## painted onto the clothes.


## A zombie built from its style, as a corpse or a leaper is.
static func _round(id: int, type: int, outfit := -1) -> Humanoid:
	return Humanoid.create(Characters.zombie_style(id, type, outfit))


static func _distinct_normals(mi: MeshInstance3D) -> int:
	var seen := {}
	var ns: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	for n in ns:
		var k := Vector3i((n.normalized() * 20.0).round())
		seen[k] = true
	return seen.size()


## How many vertices of the mesh are (about) this colour.
static func _count_colour(mi: MeshInstance3D, c: Color) -> int:
	var n := 0
	var cs: PackedColorArray = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	for v in cs:
		if absf(v.r - c.r) + absf(v.g - c.g) + absf(v.b - c.b) < 0.03:
			n += 1
	return n


static func _verts(mi: MeshInstance3D) -> PackedVector3Array:
	return mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]


func test_body_and_limbs_are_round_not_boxes() -> void:
	var rig := _round(11, Zombie.Type.WALKER, Characters.Outfit.CIVILIAN)
	add_child(rig)
	for seg_name in ["torso", "head", "upper_arm_l", "forearm_r", "thigh_l", "shin_r"]:
		assert_gt(_distinct_normals(rig.segs[seg_name].mesh), 30, seg_name + " is rounded, not a box")
	rig.free()


func test_a_zombie_has_a_face() -> void:
	var rig := _round(11, Zombie.Type.WALKER, Characters.Outfit.CIVILIAN)
	add_child(rig)
	var head: MeshInstance3D = rig.segs.head.mesh
	assert_gt(_count_colour(head, Humanoid.MOUTH), 5, "a dark, open mouth")
	assert_gt(_count_colour(head, Humanoid.TEETH), 5, "teeth in it")
	var front := 0.0
	var wide := 0.0
	for v in _verts(head):
		front = minf(front, v.z)
		wide = maxf(wide, absf(v.x))
	assert_lt(front, -0.16, "nose and brow stand out of the face")
	assert_gt(wide, 0.15, "ears on the sides")
	var eyes: MeshInstance3D = null
	for c in head.get_children():
		if c is MeshInstance3D:
			eyes = c
	assert_true(eyes != null, "glowing eyes")
	var box := eyes.get_aabb()
	assert_lt(box.get_center().z, -0.14, "the eyes are on the front of the face")
	assert_gt(box.get_center().y, 0.14, "the eyes are above the nose")
	rig.free()


func test_survivors_have_a_human_face() -> void:
	var rig := Characters.survivor(1)
	add_child(rig)
	var head: MeshInstance3D = rig.segs.head.mesh
	assert_eq(_count_colour(head, Humanoid.TEETH), 0, "no bared teeth")
	assert_eq(_count_colour(head, Humanoid.MOUTH), 0, "no gaping mouth")
	for c in head.get_children():
		assert_false(c is MeshInstance3D, "no glowing eyes")
	assert_gt(_distinct_normals(rig.segs.torso.mesh), 30, "the same round body")
	rig.free()


func test_blood_is_painted_onto_the_clothes() -> void:
	var walker := _round(12, Zombie.Type.WALKER, Characters.Outfit.OFFICE)
	var runner := _round(12, Zombie.Type.RUNNER, Characters.Outfit.OFFICE)
	add_child(walker)
	add_child(runner)
	var shares := []
	for rig: Humanoid in [walker, runner]:
		var torso: MeshInstance3D = rig.segs.torso.mesh
		var bloody := _count_colour(torso, Characters.BLOOD) + _count_colour(torso, Characters.BLOOD_DARK)
		shares.append(float(bloody) / _verts(torso).size())
	assert_gt(shares[0], 0.04, "a walker has blood on its shirt")
	assert_gt(shares[1], shares[0], "a runner is bloodier")
	var hand: MeshInstance3D = walker.segs.forearm_l.mesh
	assert_gt(_count_colour(hand, Characters.BLOOD), 12, "bloody hands")
	walker.free()
	runner.free()


func test_paint_colours_faces_by_region() -> void:
	var shape := MeshKit.loft([[0.0, 0.1, 0.1], [0.5, 0.1, 0.1], [1.0, 0.1, 0.1]], 8)
	var b := MeshKit.Body.new().add(shape, Color.WHITE, [[Vector3(-1, 0.5, -1), Vector3(1, 2, 1), Color.RED]])
	var arrays := b.mesh().surface_get_arrays(0)
	var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var cs: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	assert_eq(vs.size(), cs.size())
	var wrong := 0
	for i in vs.size():
		if vs[i].y > 0.51 and cs[i] != Color.RED or vs[i].y < 0.49 and cs[i] != Color.WHITE:
			wrong += 1
	assert_eq(wrong, 0, "the upper half is red, the lower half white")


func test_looks_are_the_same_on_every_peer() -> void:
	var a := _round(77, Zombie.Type.WALKER)
	var b := _round(77, Zombie.Type.WALKER)
	add_child(a)
	add_child(b)
	for seg_name: String in a.segs:
		var ca: PackedColorArray = (a.segs[seg_name].mesh as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		var cb: PackedColorArray = (b.segs[seg_name].mesh as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
		assert_eq(ca, cb, seg_name + " is painted the same")
	a.free()
	b.free()


func test_hitboxes_did_not_change_size() -> void:
	var rig := Characters.zombie(5, Zombie.Type.WALKER)
	add_child(rig)
	assert_eq(rig.segs.head.size, Vector3(0.3, 0.3, 0.3), "headshots are as hard as before")
	assert_eq(rig.segs.torso.size, Vector3(0.5, 0.62, 0.28))
	assert_eq(rig.segs.upper_arm_l.size, Vector3(0.15, 0.32, 0.17))
	assert_eq(rig.segs.thigh_r.size, Vector3(0.19, 0.45, 0.21))
	rig.free()


func test_a_zombie_still_builds_quickly() -> void:
	Characters.zombie(1, 0).free() # warm the shape cache
	var t0 := Time.get_ticks_usec()
	for i in 30:
		Characters.zombie(i + 1, i % 3).free()
	var ms := (Time.get_ticks_usec() - t0) / 30000.0
	assert_lt(ms, 4.0, "a zombie builds in a few milliseconds (a horde streams them in)")


func test_corpses_merge_the_new_bodies() -> void:
	var b := MeshKit.Builder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	Corpses.add(b, Characters.zombie_style(9, 0, Characters.Outfit.COP), Corpses.Pose.PRONE, Transform3D.IDENTITY, rng)
	assert_gt(b.mesh().get_faces().size() / 3, 1000, "the whole round body in one mesh")
