class_name Gore
extends Node3D
## All the mess: blood sprays, floor stains, arterial spurts, flying limbs, meat chunks and
## ragdoll corpses. Purely cosmetic and local to each peer (the host only sends *what happened*).
## Everything is capped so a horde can't tank the frame rate.

const MAX_SPLATS := 600
const MAX_GIBS := 70
const MAX_ACTIVE_RAGDOLLS := 10 # still simulating
const MAX_CORPSES := 40         # frozen ragdolls left lying around
const RAGDOLL_SIM_TIME := 5.0

## Counters (tests read these; handy for debugging too).
var stats := { "bursts": 0, "splats": 0, "gibs": 0, "ragdolls": 0, "chunks": 0 }

var ground := Callable() ## map.ground_y: where stains lie (unset: y = 0)
var last_impulse := Vector3.ZERO ## the push the last ragdoll got (tests)
var _splats: MultiMesh
var _splat_i := 0
var _gibs: Array[RigidBody3D] = []
var _active: Array[Node3D] = []
var _corpses: Array[Node3D] = []
var _drop_mesh: BoxMesh
var _drop_mat: StandardMaterial3D
var _chunk_meshes: Array[BoxMesh] = []
var _chunk_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	name = "Gore"
	# Floor stains: one MultiMesh = one draw call for every blood pool in the level.
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.45
	mat.roughness = 0.2
	mat.metallic = 0.2
	var quad := PlaneMesh.new()
	quad.size = Vector2.ONE
	quad.material = mat
	_splats = MultiMesh.new()
	_splats.transform_format = MultiMesh.TRANSFORM_3D
	_splats.use_colors = true
	_splats.mesh = quad
	_splats.instance_count = MAX_SPLATS
	_splats.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _splats
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-200, -1, -200), Vector3(400, 3, 400))
	add_child(mmi)

	_drop_mat = MeshKit.unshaded(Color("8a0000"))
	_drop_mesh = BoxMesh.new()
	_drop_mesh.size = Vector3.ONE * 0.05
	_drop_mesh.material = _drop_mat
	for col in [Color("7a0a0a"), Color("a02020"), Color("c9a0a0"), Color("4a0505")]:
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = 0.4
		_chunk_mats.append(m)
	for sz in [0.07, 0.1, 0.14]:
		var bm := BoxMesh.new()
		bm.size = Vector3(sz, sz * 0.7, sz * 1.2)
		_chunk_meshes.append(bm)


## Run `fn(node)` after `delay` seconds, but only if `node` still exists by then.
## (Never capture a node in a timer lambda directly: it may be freed first.)
func _later(delay: float, node: Node, fn: Callable) -> void:
	var id := node.get_instance_id()
	get_tree().create_timer(delay).timeout.connect(func():
		var n := instance_from_id(id) as Node
		if n != null and not n.is_queued_for_deletion():
			fn.call(n))


# --- Blood ----------------------------------------------------------------------

## Height of the floor under `pos`, where stains go.
func floor_at(pos: Vector3) -> float:
	return ground.call(pos) if ground.is_valid() else 0.0


## A blob of blood on the floor under `pos` (on the ground, whatever `pos.y`), stretched along `dir`.
func splat(pos: Vector3, dir := Vector3.ZERO, size := 0.5) -> void:
	var yaw := atan2(dir.x, dir.z) if dir.length_squared() > 0.001 else randf() * TAU
	var stretch := randf_range(1.0, 2.2) if dir.length_squared() > 0.001 else randf_range(0.8, 1.3)
	var b := Basis(Vector3.UP, yaw + randf_range(-0.4, 0.4)).scaled_local(Vector3(size, 1.0, size * stretch))
	var i := _splat_i % MAX_SPLATS
	# Tiny per-splat height offset stops overlapping stains from flickering.
	_splats.set_instance_transform(i, Transform3D(b, Vector3(pos.x, floor_at(pos) + 0.012 + i * 0.00002, pos.z)))
	var shade := randf_range(0.28, 0.5)
	_splats.set_instance_color(i, Color(shade, shade * 0.06, shade * 0.05))
	_splat_i += 1
	_splats.visible_instance_count = mini(_splat_i, MAX_SPLATS)
	stats.splats += 1


## A one-shot spray of droplets from `pos` flying along `dir`, plus stains where it lands.
func burst(pos: Vector3, dir: Vector3, amount := 24, speed := 5.0) -> void:
	stats.bursts += 1
	var p := CPUParticles3D.new()
	p.mesh = _drop_mesh
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 0.9
	p.direction = dir.normalized() if dir.length_squared() > 0.001 else Vector3.UP
	p.spread = 38.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -15, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.8
	p.position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.3).timeout.connect(p.queue_free)
	var flat := Vector3(dir.x, 0, dir.z)
	for i in clampi(amount / 6, 1, 7):
		var reach := randf_range(0.2, 0.4 + speed * 0.3)
		var jitter := Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4))
		splat(pos + flat.normalized() * reach + jitter, flat, randf_range(0.2, 0.75))


## Blood pumping out of a wound for a few seconds. `parent` is the joint the wound sits on,
## so the spray follows the zombie as it keeps coming.
func spurt(parent: Node3D, local_pos: Vector3, local_dir: Vector3, duration := 2.5) -> void:
	var p := CPUParticles3D.new()
	p.mesh = _drop_mesh
	p.amount = 28
	p.lifetime = 0.6
	p.local_coords = false
	p.direction = local_dir
	p.spread = 14.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 4.5
	p.gravity = Vector3(0, -15, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.5
	p.position = local_pos
	parent.add_child(p)
	# Drip stains under the wound while it pumps.
	var drips := Timer.new()
	drips.wait_time = 0.18
	drips.autostart = true
	p.add_child(drips)
	drips.timeout.connect(func(): # the timer is p's child, so this can't outlive p
		var at := (drips.get_parent() as Node3D).global_position
		splat(at + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), Vector3.ZERO, randf_range(0.15, 0.4)))
	_later(duration, p, func(n: CPUParticles3D):
		n.emitting = false
		(n.get_child(0) as Timer).stop()
		_later(0.8, n, func(m: Node): m.queue_free()))


# --- Flying bits ------------------------------------------------------------------

func _track_gib(body: RigidBody3D) -> void:
	add_child(body)
	_gibs.append(body)
	stats.gibs += 1
	while _gibs.size() > MAX_GIBS:
		var old: RigidBody3D = _gibs.pop_front()
		if is_instance_valid(old):
			old.queue_free()
	# Leave a blood trail where it lands and slides.
	for delay in [0.45, 0.9, 1.6]:
		_later(delay, body, func(b: RigidBody3D):
			if b.global_position.y < floor_at(b.global_position) + 0.6:
				splat(b.global_position, b.linear_velocity, randf_range(0.25, 0.6)))


## Severed limb segments become tumbling physics objects.
func gibs_from_segments(segments: Array, velocity: Vector3) -> void:
	for seg: Dictionary in segments:
		var body := Ragdoll.body_from_seg(seg)
		body.linear_velocity = velocity + Vector3(randf_range(-1.5, 1.5), randf_range(1.0, 3.5), randf_range(-1.5, 1.5))
		body.angular_velocity = Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))
		_track_gib(body)


## A plain box sent flying (broken door panels and the like).
func gib_box(size: Vector3, xf: Transform3D, color: Color, velocity: Vector3) -> void:
	var body := RigidBody3D.new()
	body.transform = xf
	body.collision_layer = Config.LAYER_DEBRIS
	body.collision_mask = Config.LAYER_WORLD
	body.mass = maxf(1.0, size.x * size.y * size.z * 400.0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	body.add_child(MeshKit.Builder.new().box(size, Vector3.ZERO, color).instance())
	body.linear_velocity = velocity
	body.angular_velocity = Vector3(randf_range(-4, 4), randf_range(-4, 4), randf_range(-4, 4))
	add_child(body)
	_gibs.append(body)


## Small meat chunks exploding outward (a head popping).
func chunks(pos: Vector3, dir: Vector3, n := 10) -> void:
	for i in n:
		var body := RigidBody3D.new()
		body.position = pos + Vector3(randf_range(-0.1, 0.1), randf_range(-0.05, 0.15), randf_range(-0.1, 0.1))
		body.collision_layer = Config.LAYER_DEBRIS
		body.collision_mask = Config.LAYER_WORLD
		body.mass = 0.3
		var mesh: BoxMesh = _chunk_meshes[randi() % _chunk_meshes.size()]
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		cs.shape = shape
		body.add_child(cs)
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = _chunk_mats[randi() % _chunk_mats.size()]
		body.add_child(mi)
		body.linear_velocity = dir * randf_range(1.0, 4.0) + Vector3(randf_range(-3, 3), randf_range(2.0, 6.5), randf_range(-3, 3))
		body.angular_velocity = Vector3(randf_range(-15, 15), randf_range(-15, 15), randf_range(-15, 15))
		stats.chunks += 1
		_track_gib(body)


# --- Corpses ----------------------------------------------------------------------

## The remains of a rig collapse as a physics ragdoll, bleed out, then freeze in place.
func ragdoll(segments: Array, base_velocity: Vector3, impulse: Vector3, hit_part: int) -> void:
	if segments.is_empty():
		return
	stats.ragdolls += 1
	last_impulse = impulse
	var root := Ragdoll.create(segments, base_velocity, impulse, hit_part)
	add_child(root)
	_active.append(root)
	while _active.size() > MAX_ACTIVE_RAGDOLLS:
		_settle(_active[0])
	_later(RAGDOLL_SIM_TIME, root, func(r: Node3D): _settle(r))
	# A pool spreads under the body.
	for delay in [0.7, 1.4, 2.4]:
		_later(delay, root, func(r: Node3D):
			if r.get_child_count() > 0:
				var torso := r.get_child(0) as Node3D
				splat(torso.global_position + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), Vector3.ZERO, randf_range(0.7, 1.3)))


func _settle(root: Node3D) -> void:
	if not is_instance_valid(root) or not _active.has(root):
		return
	_active.erase(root)
	Ragdoll.freeze(root)
	_corpses.append(root)
	while _corpses.size() > MAX_CORPSES:
		var old: Node3D = _corpses.pop_front()
		if is_instance_valid(old):
			old.queue_free()
