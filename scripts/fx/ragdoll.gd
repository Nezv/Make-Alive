class_name Ragdoll
## Turns Humanoid segments into physics bodies. Used for whole-body ragdolls (bodies pinned
## together at the joints) and for loose gibs (a single severed limb).

## One rigid body for a segment, taking over its mesh at its current pose.
## Call while the segment's mesh is still in the scene tree.
static func body_from_seg(seg: Dictionary) -> RigidBody3D:
	var node: Node3D = seg.node
	var mesh: MeshInstance3D = seg.mesh
	var joint_xf := node.global_transform
	var s := joint_xf.basis.get_scale().x
	var body_xf := Transform3D(joint_xf.basis.orthonormalized(), joint_xf * (seg.center as Vector3))
	var mesh_xf := mesh.global_transform

	var body := RigidBody3D.new()
	body.name = seg.name
	body.transform = body_xf
	body.collision_layer = Config.LAYER_DEBRIS
	body.collision_mask = Config.LAYER_WORLD
	var size: Vector3 = (seg.size as Vector3) * s
	body.mass = maxf(1.0, size.x * size.y * size.z * 500.0)
	body.angular_damp = 2.5
	body.linear_damp = 0.15
	var mat := PhysicsMaterial.new()
	mat.friction = 1.0
	mat.bounce = 0.05
	body.physics_material_override = mat
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size * 0.9
	cs.shape = shape
	body.add_child(cs)

	if seg.has("hitbox"):
		(seg.hitbox as Node).queue_free()
	mesh.get_parent().remove_child(mesh)
	body.add_child(mesh)
	mesh.transform = body_xf.affine_inverse() * mesh_xf
	body.set_meta("pivot", joint_xf.origin) # where it was attached to its parent
	return body


## A full ragdoll from what's left of a rig. `base_velocity` is how the zombie was moving,
## `impulse` is the extra shove applied to the part that got hit (or the torso).
static func create(segments: Array, base_velocity: Vector3, impulse: Vector3, hit_part: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Ragdoll"
	var bodies := {}
	for seg: Dictionary in segments:
		var body := body_from_seg(seg)
		body.linear_velocity = base_velocity + Vector3(randf_range(-0.4, 0.4), randf_range(0.0, 0.6), randf_range(-0.4, 0.4))
		body.angular_velocity = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2))
		if seg.part == hit_part or (seg.name == "torso" and hit_part == Humanoid.Part.HEAD):
			body.linear_velocity += impulse
		elif seg.name == "torso":
			body.linear_velocity += impulse * 0.5
		bodies[seg.name] = body
		root.add_child(body)
	for seg: Dictionary in segments:
		var parent_name: String = seg.parent
		if parent_name == "" or not bodies.has(parent_name):
			continue # torso, or its parent was shot off
		var child: RigidBody3D = bodies[seg.name]
		var pin := PinJoint3D.new()
		pin.position = child.get_meta("pivot")
		pin.node_a = NodePath("../" + parent_name)
		pin.node_b = NodePath("../" + String(seg.name))
		pin.set_param(PinJoint3D.PARAM_BIAS, 0.5)
		pin.set_param(PinJoint3D.PARAM_DAMPING, 1.2)
		root.add_child(pin)
	return root


## Stop simulating a ragdoll but keep it lying there (cheap corpse).
static func freeze(root: Node3D) -> void:
	for child in root.get_children():
		if child is Joint3D:
			child.queue_free()
		elif child is RigidBody3D:
			child.freeze = true
			child.collision_layer = 0
			child.collision_mask = 0
