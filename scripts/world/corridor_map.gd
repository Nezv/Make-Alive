class_name CorridorMap
## The test map: one L-shaped corridor.
##
##        z = 30  +-----+   <- players spawn here (leg A, runs along Z)
##                |  A  |
##                |     |
##        z = 3   |     +------------+---------------------+
##                | corner           D (door, x = 14)   B    <- open end, zombies arrive (x > 36)
##        z = -3  +------------------+---------------------+
##               x=-3   x=3
##
## Navigation is by "spine distance": a single number that grows from the player end of leg A
## (negative) through the corner (0) and along leg B (positive). Chokepoints sit on the spine.

const HALF_W := 3.0
const LEG_A_END := 30.0
const LEG_B_END := 44.0
const WALL_H := 4.0
const WALL_T := 0.4
const DOOR_X := 14.0
const DOOR_HALF := 1.0
const PLAYER_SPAWN := Vector3(0, 0.1, 26)

const CHOKE_NONE := -1
const CHOKE_CORNER := 0
const CHOKE_DOOR := 1
const _CHOKE_S := [0.0, DOOR_X]


static func spine(p: Vector3) -> float:
	if p.x > HALF_W:
		return p.x
	if p.z > HALF_W:
		return -p.z
	return p.x - p.z


## The first chokepoint someone at `from` must pass to reach `to` (CHOKE_NONE = straight line).
static func next_choke(from: Vector3, to: Vector3) -> int:
	var sf := spine(from)
	var st := spine(to)
	var dir := signf(st - sf)
	var best := CHOKE_NONE
	var best_d := INF
	for i in _CHOKE_S.size():
		var cs: float = _CHOKE_S[i]
		if (cs - sf) * dir > 0.5 and (st - cs) * dir > 0.5 and absf(cs - sf) < best_d:
			best = i
			best_d = absf(cs - sf)
	return best


static func is_direct(from: Vector3, to: Vector3) -> bool:
	return next_choke(from, to) == CHOKE_NONE


## Where to walk right now to get from `from` to `to`. `lane` (-1..1) spreads a crowd sideways.
static func nav_target(from: Vector3, to: Vector3, lane := 0.0) -> Vector3:
	match next_choke(from, to):
		CHOKE_CORNER:
			return Vector3(lane * 2.0, 0, lane * 2.0)
		CHOKE_DOOR:
			return Vector3(DOOR_X, 0, lane * DOOR_HALF * 0.6)
	return to


## Builds geometry and lights. Returns { root }. Spawns, the door and the lootbox are data:
## MapAreas.CORRIDOR, read by CorridorGameMap.
static func build() -> Dictionary:
	var root := Node3D.new()
	root.name = "Corridor"
	var b := MeshKit.Builder.new()
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_WORLD
	body.collision_mask = 0
	root.add_child(body)

	var solid := func(center: Vector3, size: Vector3, color: Color, surface := Surface.Kind.CONCRETE) -> void:
		b.box(size, center, color)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		cs.position = center
		Surface.tag(cs, surface)
		body.add_child(cs)
	var wall_x := func(x: float, z0: float, z1: float, color: Color) -> void:
		solid.call(Vector3(x, WALL_H / 2.0, (z0 + z1) / 2.0), Vector3(WALL_T, WALL_H, absf(z1 - z0)), color)
	var wall_z := func(z: float, x0: float, x1: float, color: Color) -> void:
		solid.call(Vector3((x0 + x1) / 2.0, WALL_H / 2.0, z), Vector3(absf(x1 - x0), WALL_H, WALL_T), color)

	var floor_c := Color("34383c")
	var wall_c := Color("5c6168")
	var edge := HALF_W + WALL_T / 2.0
	# Floors
	solid.call(Vector3(0, -0.25, (LEG_A_END - HALF_W) / 2.0), Vector3(HALF_W * 2 + 1, 0.5, LEG_A_END + HALF_W + 1), floor_c, Surface.Kind.TILE)
	solid.call(Vector3((LEG_B_END + HALF_W) / 2.0, -0.25, 0), Vector3(LEG_B_END - HALF_W, 0.5, HALF_W * 2 + 1), floor_c, Surface.Kind.TILE)
	# Floor stripes, so movement reads clearly
	var z := 6.0
	while z < LEG_A_END:
		b.box(Vector3(HALF_W * 2, 0.01, 0.12), Vector3(0, 0.005, z), Color("444a50"))
		z += 3.0
	var x := 6.0
	while x < LEG_B_END:
		b.box(Vector3(0.12, 0.01, HALF_W * 2), Vector3(x, 0.005, 0), Color("444a50"))
		x += 3.0
	# Walls
	wall_x.call(-edge, -edge, LEG_A_END + WALL_T, wall_c)          # A west
	wall_x.call(edge, HALF_W, LEG_A_END + WALL_T, wall_c)          # A east
	wall_z.call(LEG_A_END + WALL_T / 2.0, -edge, edge, wall_c)     # A end cap
	wall_z.call(-edge, -edge, LEG_B_END, wall_c)                   # corner + B north
	wall_z.call(edge, HALF_W, LEG_B_END, wall_c)                   # B south
	# Door wall with an opening
	var frame_c := Color("4a4e55")
	solid.call(Vector3(DOOR_X, WALL_H / 2.0, -(HALF_W + DOOR_HALF) / 2.0), Vector3(0.3, WALL_H, HALF_W - DOOR_HALF), frame_c, Surface.Kind.METAL)
	solid.call(Vector3(DOOR_X, WALL_H / 2.0, (HALF_W + DOOR_HALF) / 2.0), Vector3(0.3, WALL_H, HALF_W - DOOR_HALF), frame_c, Surface.Kind.METAL)
	solid.call(Vector3(DOOR_X, (WALL_H + Door.HEIGHT) / 2.0, 0), Vector3(0.3, WALL_H - Door.HEIGHT, DOOR_HALF * 2), frame_c, Surface.Kind.METAL)
	root.add_child(b.instance())

	# Lamps
	var lamp_mesh := MeshKit.Builder.new()
	var lamps := [Vector3(0, 3.4, 24), Vector3(0, 3.4, 12), Vector3(0, 3.4, 0), Vector3(9, 3.4, 0),
		Vector3(20, 3.4, 0), Vector3(31, 3.4, 0)]
	for i in lamps.size():
		var p: Vector3 = lamps[i]
		lamp_mesh.box(Vector3(0.5, 0.08, 0.5), p + Vector3(0, 0.3, 0), Color.WHITE)
		var light := OmniLight3D.new()
		light.position = p
		light.light_color = Color("ffd9a0")
		light.light_energy = 2.2
		light.omni_range = 12.0
		light.shadow_enabled = i == 2 or i == 3 # the two around the corner cast shadows
		light.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID # 2 passes instead of 6
		root.add_child(light)
	root.add_child(lamp_mesh.instance(MeshKit.emissive(Color("ffd9a0"), 3.0), false))

	return { "root": root }
