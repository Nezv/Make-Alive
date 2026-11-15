class_name ShelterMap
extends GameMap
## Evacuation Shelter 7, seen from outside after it fell.
##
##   z = -46  +--------------------------------------------------+  north wall
##            | alley  +----------------------------+  alley     |  zombies come round both sides
##            |        |   THE SHELTER (5 floors)   |            |  and out of the side doors
##   z = -18  |        +---------[entrance]---------+            |
##            | heli   nests + wire      rubble   HQ tent  APC   |
##            | triage tents    bus (avenue)    humvee  trucks   |  west: medics / east: motor pool
##            | ambulance, body bags            ammo dump        |
##   z =  25  +-------fence----[ gate ]-----fence----------------+
##            = = = = = = road: wrecks, PLAYERS SPAWN (0, 30) = = =   zombies also come down the road
##   z =  35  +--------------------------------------------------+
##           x=-45   -34                                34      45
##
## Later: the interior. The shell is already sized for it. FLOORS floors, FLOOR_H apart
## (`floor_y(i)`), footprint BUILDING, main entrance at ENTRANCE, side doors at SIDE_DOORS, stair
## cores planned at STAIR_CORES and a lift at LIFT. The walls are separate boxes (not one block),
## the windows sit on the floor grid, and the fire escape already reaches every floor.
##
## Everything is merged into a handful of meshes (ground, props + building, the dead, lit windows,
## flames). Layout is fixed; only its own seeded rng scatters detail, so every peer builds the
## same yard. Solid props register a collision box and a navigation obstacle through `_put`.

const FLOORS := 5
const FLOOR_H := 3.6
const BUILDING := Rect2(-20, -42, 40, 24) ## x, z, width, depth: the front wall is at z = -18
const ENTRANCE := Vector3(0, 0, -18)
const SIDE_DOORS := [Vector3(-20, 0, -30), Vector3(20, 0, -30)]
const STAIR_CORES := [Vector3(-16, 0, -38), Vector3(16, 0, -38)]
const LIFT := Vector3(0, 0, -36)
const PLAYER_SPAWN := Vector3(0, 0.1, 30)
const YARD_X := 34.0   ## side walls
const FENCE_Z := 25.15 ## south fence, with the gate in the middle
const ROAD_X := 45.0

const WALL := Color("767a80")
const WALL_DARK := Color("5c6066")
const FRAME := Color("9a9da2")
const GLASS := Color("141c24")
const HOLE := Color("050607")
const SHUTTER := Color("4a4e55")
const BLOOD := Color("4a0606")
const P := Corpses.Pose
const O := Characters.Outfit

## Where zombies appear: [center, half size] on the ground.
const SPAWN_ZONES := [
	[Vector3(-40.5, 0.1, 30), Vector3(1.5, 0, 3.0)], [Vector3(40.5, 0.1, 30), Vector3(1.5, 0, 3.0)], # road ends
	[Vector3(-27, 0.1, -40), Vector3(4, 0, 3)], [Vector3(27, 0.1, -40), Vector3(4, 0, 3)],           # behind the building
	[Vector3(-22.6, 0.1, -30), Vector3(1.0, 0, 1.5)], [Vector3(22.6, 0.1, -30), Vector3(1.0, 0, 1.5)], # side doors
]

var nav: NavGrid
var spots: Array = []       ## every WeaponPickup, filled or not
var corpses: Array = []     ## { pos, outfit, pose, zombie } for each body
var prop_counts := {}       ## kind -> how many were placed
var landmarks := {}         ## named places tests and scripts can refer to

var _b := MeshKit.Builder.new()     # props and the building
var _g := MeshKit.Builder.new()     # ground, paint, stains
var _dead := MeshKit.Builder.new()  # corpses
var _glow := MeshKit.Builder.new()  # lit windows
var _fire := MeshKit.Builder.new()  # flames
var _body := StaticBody3D.new()
var _rng := RandomNumberGenerator.new()
var _next_iid := 10


static func floor_y(i: int) -> float:
	return i * FLOOR_H


func _init() -> void:
	name = "shelter"
	outdoor = true
	all_weapons = false
	nav_refresh = 0.35
	_rng.seed = 20261115
	root = Node3D.new()
	root.name = "Shelter"
	_body.collision_layer = Config.LAYER_WORLD
	_body.collision_mask = 0
	root.add_child(_body)
	nav = NavGrid.new(Vector2(-ROAD_X, -47), Vector2(ROAD_X, 36), 0.5)

	_ground()
	_building()
	_perimeter()
	_road()
	_gate()
	_avenue()
	_triage()
	_motor_pool()
	_forecourt()
	_the_dead()
	_lights()

	nav.finish()
	root.add_child(_g.instance(null, false))
	root.add_child(_b.instance())
	root.add_child(_dead.instance())
	root.add_child(_glow.instance(MeshKit.emissive(Color("ffd9a0"), 2.5), false))
	root.add_child(_fire.instance(MeshKit.emissive(Color("ff8a2a"), 5.0), false))


# --- GameMap ------------------------------------------------------------------------

func player_spawn() -> Vector3:
	return PLAYER_SPAWN


func player_spawn_point() -> Vector3:
	return PLAYER_SPAWN + Vector3(randf_range(-2.2, 2.2), 0, randf_range(-1.8, 1.8))


func zombie_spawn_point(avoid: Array) -> Vector3:
	var ok := []
	var farthest := 0
	var farthest_d := -1.0
	for i in SPAWN_ZONES.size():
		var c: Vector3 = SPAWN_ZONES[i][0]
		var nearest := INF
		for p: Vector3 in avoid:
			nearest = minf(nearest, c.distance_to(p))
		if nearest > Config.SPAWN_MIN_DIST + 4.0:
			ok.append(i)
		if nearest > farthest_d:
			farthest_d = nearest
			farthest = i
	var zone: Array = SPAWN_ZONES[ok[randi() % ok.size()] if not ok.is_empty() else farthest]
	var half: Vector3 = zone[1]
	return zone[0] + Vector3(randf_range(-half.x, half.x), 0, randf_range(-half.z, half.z))


func is_direct(from: Vector3, to: Vector3) -> bool:
	return nav.is_direct(from, to)


func nav_target(from: Vector3, to: Vector3, lane := 0.0) -> Vector3:
	return nav.nav_target(from, to, lane)


## Empty every spot, then put a random gun in a random few.
func roll_weapons(rng: RandomNumberGenerator) -> void:
	var order := range(spots.size())
	for i in range(order.size() - 1, 0, -1): # shuffle with the given rng so a seed pins it
		var j := rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	for i in order.size():
		var spot: WeaponPickup = spots[order[i]]
		spot.set_weapon(Weapons.roll_loot(rng) if i < Config.WEAPON_SPOTS_ACTIVE else -1)


# --- Building blocks ------------------------------------------------------------------

func _t(x: float, z: float, yaw_deg := 0.0, y := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(x, y, z))


## Register a prop: count it and make its solid parts collide and block navigation.
func _put(kind: String, colliders: Array, t: Transform3D) -> void:
	prop_counts[kind] = prop_counts.get(kind, 0) + 1
	for c: Array in colliders:
		_collide(c[0], c[1], t)


func _collide(center: Vector3, size: Vector3, t := Transform3D.IDENTITY) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.transform = t * Transform3D(Basis.IDENTITY, center)
	_body.add_child(cs)
	if center.y - size.y * 0.5 < 0.9 and center.y + size.y * 0.5 > 0.35: # something a walker bumps into
		var at := t * center
		nav.block_rect(Vector2(at.x, at.z), Vector2(size.x, size.z) * 0.5, t.basis.get_euler().y)


## A plain solid box in world space.
func _solid(center: Vector3, size: Vector3, color: Color) -> void:
	_b.box(size, center, color)
	_collide(center, size)


## Flat paint or stain on the ground. `layer` keeps overlapping ones from flickering.
func _decal(x: float, z: float, w: float, d: float, color: Color, layer := 3, yaw_deg := 0.0) -> void:
	_g.box(Vector3(w, 0.012, d), Vector3(x, 0.012 + layer * 0.013, z), color, Basis(Vector3.UP, deg_to_rad(yaw_deg)))


func _spot(kind: String, pos: Vector3, stand: Vector3, yaw_deg := 0.0) -> void:
	var s := WeaponPickup.new()
	s.iid = _next_iid
	_next_iid += 1
	s.kind = kind
	s.position = pos
	s.rotation.y = deg_to_rad(yaw_deg)
	s.stand = stand
	root.add_child(s)
	spots.append(s)
	interactables.append(s)


## A prop's own-space point in the world.
func _at(t: Transform3D, x: float, y: float, z: float) -> Vector3:
	return t * Vector3(x, y, z)


func _corpse(x: float, z: float, yaw_deg: float, pose: int, outfit: int, human: bool, y := 0.0) -> void:
	var id := 300 + corpses.size() * 7
	var style := Corpses.human_style(id, outfit) if human else Characters.zombie_style(id, 0, outfit)
	Corpses.add(_dead, style, pose, _t(x, z, yaw_deg, y), _rng)
	corpses.append({ "pos": Vector3(x, y, z), "outfit": outfit, "pose": pose, "zombie": not human })
	if y < 0.1:
		_decal(x + _rng.randf_range(-0.3, 0.3), z + _rng.randf_range(-0.3, 0.3), _rng.randf_range(1.0, 1.9),
			_rng.randf_range(0.8, 1.5), BLOOD, 5, _rng.randf() * 360.0)


func _flame(pos: Vector3, size := 0.5) -> void:
	for i in 4:
		_fire.box(Vector3(size * 0.5, size * _rng.randf_range(0.8, 1.6), size * 0.5),
			pos + Vector3(_rng.randf_range(-size, size) * 0.4, size * 0.5, _rng.randf_range(-size, size) * 0.4),
			Color.WHITE, Basis(Vector3.UP, _rng.randf() * TAU))
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 0.8, 0)
	light.light_color = Color("ff9a40")
	light.light_energy = 2.4
	light.omni_range = 10.0
	root.add_child(light)


func _smoke(pos: Vector3, amount := 20) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.direction = Vector3(0.25, 1, 0.1)
	p.spread = 12.0
	p.gravity = Vector3.ZERO
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 1.8
	p.scale_amount_min = 1.2
	p.scale_amount_max = 3.2
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.5
	var quad := QuadMesh.new()
	quad.size = Vector2(1.4, 1.4)
	var m := MeshKit.unshaded(Color("16171a"), 0.35)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	quad.material = m
	p.mesh = quad
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(p)


func _label(text: String, pos: Vector3, size: int, color: Color, yaw_deg := 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation.y = deg_to_rad(yaw_deg)
	l.shaded = true
	root.add_child(l)


# --- Ground ---------------------------------------------------------------------------

func _ground() -> void:
	_g.box(Vector3(ROAD_X * 2 + 2, 0.5, 86), Vector3(0, -0.25, -5.5), Color("2a2c2f"))
	_collide(Vector3(0, -0.25, -5.5), Vector3(ROAD_X * 2 + 2, 0.5, 86))
	_decal(0, 3.5, YARD_X * 2, FENCE_Z + 18.0 + 0.3, Color("47494c"), 0)          # forecourt slab
	_decal(-YARD_X + 4.5, -32, 9, 28, Color("3d4436"), 0)                        # weeds in the alleys
	_decal(YARD_X - 4.5, -32, 9, 28, Color("3d4436"), 0)
	_decal(0, 3.5, 10, FENCE_Z + 18.0, Color("55575a"), 1)                       # avenue to the door
	for x in [-5.0, 5.0]:
		_decal(x, 3.5, 0.18, FENCE_Z + 18.0, Color("b89a1a"), 2)
	for z in range(-12, 24, 6):                                                  # slab joints
		_decal(-19.5, z, 29, 0.08, Color("3a3c3f"), 1)
		_decal(19.5, z, 29, 0.08, Color("3a3c3f"), 1)
	for z in [16.0, 9.0, -8.0]:                                                  # painted arrows: this way in
		_decal(-0.75, z, 0.4, 2.2, Color("c8c8c0"), 2, 35)
		_decal(0.75, z, 0.4, 2.2, Color("c8c8c0"), 2, -35)
	_decal(0, 30.2, ROAD_X * 2, 9.6, Color("202124"), 0)                         # road
	for x in range(-42, 44, 5):
		_decal(x, 30.2, 2.2, 0.16, Color("c8c8c0"), 1)
	_decal(0, 25.45, ROAD_X * 2, 0.3, Color("6a6c6f"), 1)                        # kerb
	for i in 46:                                                                 # blood and scorch marks
		var x := _rng.randf_range(-32, 32)
		var z := _rng.randf_range(-17, 34)
		if _rng.randf() < 0.75:
			_decal(x, z, _rng.randf_range(0.3, 1.5), _rng.randf_range(0.3, 1.2), BLOOD.darkened(_rng.randf() * 0.4), 4, _rng.randf() * 360)
		else:
			_decal(x, z, _rng.randf_range(1.0, 2.6), _rng.randf_range(1.0, 2.6), Color("151516"), 3, _rng.randf() * 360)
	for trail: Array in [[-1.5, -9.0, 0.5, 6.0, 8.0], [3.0, 18.0, 0.4, 5.0, -20.0], [-16.0, 5.0, 0.45, 4.5, 70.0]]:
		_decal(trail[0], trail[1], trail[2], trail[3], BLOOD, 4, trail[4])       # something was dragged


# --- The shelter ----------------------------------------------------------------------

func _building() -> void:
	var x0 := BUILDING.position.x
	var x1 := BUILDING.end.x
	var z0 := BUILDING.position.y
	var z1 := BUILDING.end.y
	var h := FLOORS * FLOOR_H
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var t := 0.6
	# Four walls, not one block, so the inside can be opened up later.
	_solid(Vector3(cx, h * 0.5, z1 - t * 0.5), Vector3(x1 - x0, h, t), WALL)       # front (south)
	_solid(Vector3(cx, h * 0.5, z0 + t * 0.5), Vector3(x1 - x0, h, t), WALL_DARK)  # back
	_solid(Vector3(x0 + t * 0.5, h * 0.5, cz), Vector3(t, h, z1 - z0), WALL_DARK)  # west
	_solid(Vector3(x1 - t * 0.5, h * 0.5, cz), Vector3(t, h, z1 - z0), WALL_DARK)  # east
	nav.block_rect(Vector2(cx, cz), Vector2(x1 - x0, z1 - z0) * 0.5, 0.0, 0.0)
	_b.box(Vector3(x1 - x0 + 0.6, 0.4, z1 - z0 + 0.6), Vector3(cx, h + 0.2, cz), WALL_DARK) # roof
	for side: Array in [[cx, z1 + 0.15, x1 - x0 + 0.6, 0.3], [cx, z0 - 0.15, x1 - x0 + 0.6, 0.3],
			[x0 - 0.15, cz, 0.3, z1 - z0], [x1 + 0.15, cz, 0.3, z1 - z0]]:
		_b.box(Vector3(side[2], 0.9, side[3]), Vector3(side[0], h + 0.85, side[1]), WALL) # parapet
	_b.box(Vector3(3.0, 2.4, 3.0), Vector3(-12, h + 1.6, -30), SHUTTER)            # water tank
	_b.box(Vector3(4.0, 1.2, 2.5), Vector3(8, h + 1.0, -34), WALL_DARK)            # plant room
	_b.box(Vector3(0.15, 7.0, 0.15), Vector3(14, h + 3.9, -22), SHUTTER)           # mast
	_glow.box(Vector3(0.3, 0.3, 0.3), Vector3(14, h + 7.5, -22), Color.WHITE)

	_facade(Vector3(x0, 0, z1), Vector3.RIGHT, Vector3.BACK, 10, [4, 5], [[7, 2], [8, 2], [7, 3], [8, 3]])
	_facade(Vector3(x0, 0, z0), Vector3.BACK, Vector3.LEFT, 6, [3], [])
	_facade(Vector3(x1, 0, z0), Vector3.BACK, Vector3.RIGHT, 6, [3], [])
	_entrance()
	_blast_hole(Vector3(12, floor_y(2) + 1.6, z1))
	_fire_escape(x1, -34.0)
	for door: Vector3 in SIDE_DOORS:                                               # dark side doorways
		_b.box(Vector3(0.14, 2.5, 1.7), door + Vector3(signf(door.x) * 0.02, 1.25, 0), HOLE)
		_b.box(Vector3(0.3, 0.2, 2.1), door + Vector3(signf(door.x) * 0.1, 2.6, 0), FRAME)
	_b.box(Vector3(5.0, 3.2, 0.06), Vector3(-12, floor_y(3) + 1.0, z1 + 0.08), Color("c9c9c0")) # banner
	_b.box(Vector3(1.4, 2.6, 0.07), Vector3(-10.6, floor_y(3) + 0.6, z1 + 0.09), BLOOD)
	_label("SAFE ZONE", Vector3(-12, floor_y(3) + 1.6, z1 + 0.13), 110, Color("1c3a8a"))
	_label("ALL SURVIVORS\nWELCOME", Vector3(-12.3, floor_y(3) + 0.3, z1 + 0.13), 48, Color("222222"))


## One wall's worth of windows, floor bands and pilasters. `along` runs along the wall, `out`
## points away from it. `doors` are ground-floor bays to leave clear; `skip` are [bay, floor]
## pairs where something else goes (the blast hole).
func _facade(origin: Vector3, along: Vector3, out: Vector3, bays: int, doors: Array, skip: Array) -> void:
	var bay_w := 4.0
	var along_x := absf(along.x) > 0.5
	var box := func(w: float, hgt: float, depth: float, a: float, y: float, o: float, color: Color, into: MeshKit.Builder) -> void:
		into.box(Vector3(w, hgt, depth) if along_x else Vector3(depth, hgt, w), origin + along * a + Vector3(0, y, 0) + out * o, color)
	for f in FLOORS + 1:
		box.call(bays * bay_w + 0.3, 0.35, 0.28, bays * bay_w * 0.5, floor_y(f), 0.1, WALL_DARK, _b) # floor band
	for k in bays + 1:
		box.call(0.55, FLOORS * FLOOR_H, 0.24, k * bay_w, FLOORS * FLOOR_H * 0.5, 0.08, WALL_DARK, _b) # pilaster
	for f in FLOORS:
		for k in bays:
			if (f == 0 and doors.has(k)) or skip.has([k, f]):
				continue
			var a := (k + 0.5) * bay_w
			var y := floor_y(f) + 1.95
			var roll := (f * 31 + k * 17 + int(absf(origin.x + origin.z)) * 7) % 20
			if f == 0: # ground floor was shuttered
				box.call(2.6, 1.9, 0.1, a, y, 0.03, SHUTTER, _b)
				for i in 5:
					box.call(2.6, 0.06, 0.14, a, y - 0.8 + i * 0.4, 0.04, SHUTTER.darkened(0.25), _b)
				continue
			box.call(2.9, 2.2, 0.08, a, y, 0.02, FRAME, _b)
			if roll < 2: # someone left a light on
				box.call(2.6, 1.9, 0.1, a, y, 0.04, Color.WHITE, _glow)
			elif roll < 5: # boarded up
				box.call(2.6, 1.9, 0.1, a, y, 0.03, HOLE, _b)
				for i in 3:
					box.call(2.8, 0.34, 0.12, a, y - 0.6 + i * 0.6, 0.06, Props.WOOD.darkened(0.1 * i), _b)
			elif roll < 8: # smashed
				box.call(2.6, 1.9, 0.1, a, y, 0.03, HOLE, _b)
				box.call(0.9, 0.7, 0.1, a - 0.85, y - 0.6, 0.04, GLASS.lightened(0.15), _b)
				box.call(0.6, 0.5, 0.1, a + 1.0, y + 0.7, 0.04, GLASS.lightened(0.15), _b)
			else:
				box.call(2.6, 1.9, 0.1, a, y, 0.03, GLASS, _b)
				box.call(0.08, 1.9, 0.12, a, y, 0.04, FRAME, _b) # mullion
			if roll == 9 or roll == 14: # a bloody handprint smear, or a sheet hung out
				box.call(0.5, 1.2, 0.05, a + 0.6, y - 1.3, 0.05, BLOOD if roll == 9 else Color("c9c9c0"), _b)


func _entrance() -> void:
	var z := BUILDING.end.y
	_b.box(Vector3(7.6, 3.4, 0.2), Vector3(0, 1.7, z + 0.05), HOLE)                # the dark doorway
	for x in [-1.85, 1.85]:                                                        # steel shutters, half torn
		_b.box(Vector3(3.5, 3.2, 0.12), Vector3(x, 1.6, z + 0.18), SHUTTER, Basis(Vector3.RIGHT, 0.05 if x < 0 else -0.12))
		for i in 7:
			_b.box(Vector3(3.5, 0.07, 0.16), Vector3(x, 0.35 + i * 0.42, z + 0.2), SHUTTER.darkened(0.25))
	_b.box(Vector3(8.2, 0.12, 0.05), Vector3(0, 1.6, z + 0.32), Props.HAZARD, Basis(Vector3.BACK, 0.38)) # tape
	_b.box(Vector3(8.2, 0.12, 0.05), Vector3(0, 1.6, z + 0.33), Props.HAZARD, Basis(Vector3.BACK, -0.38))
	_collide(Vector3(0, 1.7, z + 0.2), Vector3(7.6, 3.4, 0.4))
	_b.box(Vector3(12.4, 0.4, 4.6), Vector3(0, 3.9, z + 2.3), WALL_DARK)           # canopy
	_b.box(Vector3(12.5, 0.14, 4.7), Vector3(0, 3.66, z + 2.3), Props.RED)
	for x in [-5.6, 5.6]:
		_solid(Vector3(x, 1.85, z + 4.2), Vector3(0.5, 3.7, 0.5), WALL)            # columns
	_b.box(Vector3(11.0, 1.5, 0.2), Vector3(0, 4.95, z + 4.4), Color("c8ccd0"))    # sign board
	_b.box(Vector3(0.9, 0.3, 0.06), Vector3(-4.6, 4.95, z + 4.52), Props.RED)      # red cross
	_b.box(Vector3(0.3, 0.9, 0.06), Vector3(-4.6, 4.95, z + 4.52), Props.RED)
	_label("EVACUATION SHELTER 7", Vector3(0.6, 4.95, z + 4.53), 72, Color("1a1c20"))
	_label("DO NOT OPEN\nDEAD INSIDE", Vector3(0, 2.0, z + 0.36), 64, Color("a01010"))
	var red := OmniLight3D.new()                                                   # emergency light
	red.position = Vector3(0, 3.2, z + 2.2)
	red.light_color = Color("ff2a1a")
	red.light_energy = 1.6
	red.omni_range = 9.0
	root.add_child(red)
	_fire.box(Vector3(0.3, 0.15, 0.15), Vector3(0, 3.5, z + 0.45), Color.WHITE)


## Something blew a two-storey hole in the front wall; the rubble is in the forecourt.
func _blast_hole(at: Vector3) -> void:
	_b.box(Vector3(7.2, 6.6, 0.25), at + Vector3(0, 1.8, 0.1), HOLE)
	for i in 26:
		var a := TAU * i / 26.0
		var s := _rng.randf_range(0.5, 1.3)
		_b.box(Vector3(s, s * _rng.randf_range(0.6, 1.4), 0.5), at + Vector3(cos(a) * 3.8, 1.8 + sin(a) * 3.5, 0.2),
			WALL.darkened(_rng.randf_range(0.1, 0.5)), Basis(Vector3.BACK, _rng.randf() * TAU))
	_b.box(Vector3(8.5, 4.0, 0.06), at + Vector3(0.4, 6.6, 0.33), Color("1a1a1b"))  # soot above it
	_b.box(Vector3(4.0, 0.25, 1.6), at + Vector3(-0.8, -1.5, 0.6), WALL_DARK, Basis(Vector3.RIGHT, 0.5)) # hanging slab
	_smoke(at + Vector3(0, 3.0, 0.5), 16)


## Steel fire escape on the east wall. It reaches every floor; the last ladder is pulled up.
func _fire_escape(x: float, z: float) -> void:
	var steel := Color("3c4046")
	for f in range(1, FLOORS):
		var y := floor_y(f)
		_b.box(Vector3(1.4, 0.08, 5.4), Vector3(x + 0.8, y, z), steel)               # landing
		_b.box(Vector3(0.05, 1.0, 5.4), Vector3(x + 1.5, y + 0.5, z), steel)         # rail
		_b.box(Vector3(0.05, 0.05, 5.4), Vector3(x + 1.5, y + 1.0, z), steel)
		if f < FLOORS - 1:
			var dir := 1.0 if f % 2 == 1 else -1.0
			_b.box(Vector3(0.9, 0.08, 5.6), Vector3(x + 0.9, y + FLOOR_H * 0.5, z), steel,
				Basis(Vector3.RIGHT, dir * atan2(FLOOR_H, 4.2)))                   # stairs
	_b.box(Vector3(0.5, 2.0, 0.08), Vector3(x + 0.8, floor_y(1) - 1.0, z + 2.5), steel)  # the raised ladder


# --- Outside ----------------------------------------------------------------------------

func _perimeter() -> void:
	var c := Props.CONCRETE_DARK
	for x in [-YARD_X - 0.2, YARD_X + 0.2]:                                        # yard side walls
		_solid(Vector3(x, 1.5, (FENCE_Z - 46.0) * 0.5), Vector3(0.4, 3.0, FENCE_Z + 46.0), c)
	_solid(Vector3(0, 1.5, -46.2), Vector3(YARD_X * 2 + 0.8, 3.0, 0.4), c)         # north wall
	_solid(Vector3(0, 1.5, 35.4), Vector3(ROAD_X * 2 + 1, 3.0, 0.4), c)            # far side of the road
	for side in [-1.0, 1.0]:
		_solid(Vector3(side * (ROAD_X + 0.2), 1.5, 30.2), Vector3(0.4, 3.0, 10.6), Props.SOOT) # road blocked off
		_solid(Vector3(side * (YARD_X + ROAD_X) * 0.5, 1.5, FENCE_Z), Vector3(ROAD_X - YARD_X, 3.0, 0.4), c)
		_put("fence", Props.fence(_b, _t(side * 19.5, FENCE_Z), 29.0), _t(side * 19.5, FENCE_Z))
		for z in [27.0, 30.2, 33.4]:
			_put("barrier", Props.barrier(_b, _t(side * 43.0, z)), _t(side * 43.0, z))
	_label("ROAD CLOSED", Vector3(-42.6, 1.6, 30.2), 56, Color("d8b21a"), 90)
	_label("ROAD CLOSED", Vector3(42.6, 1.6, 30.2), 56, Color("d8b21a"), -90)


func _road() -> void:
	var police := _t(-17, 29.5, 70)
	_put("car", Props.car(_b, police, Color("20242c"), false, true), police)
	_spot("vehicle", _at(police, 0, 1.06, 1.75), _at(police, 0, 0, 3.4), 70)
	_put("car", Props.car(_b, _t(9, 31.8, 185), Color("8a2222")), _t(9, 31.8, 185))
	_put("car", Props.car(_b, _t(15.5, 28.3, 20), Props.SOOT, true), _t(15.5, 28.3, 20))
	_flame(Vector3(15.3, 0.9, 27.6), 0.7)
	_smoke(Vector3(15.5, 1.6, 28.3))
	var flipped := Transform3D(Basis(Vector3.UP, deg_to_rad(95)) * Basis(Vector3.FORWARD, PI / 2.0), Vector3(23, 0.9, 31))
	_put("car", Props.car(_b, flipped, Color("2a4a8a")), flipped)
	_put("humvee", Props.humvee(_b, _t(-8, 32.3, 80), Props.OLIVE), _t(-8, 32.3, 80))
	_put("crater", Props.crater(_g, _t(4.6, 27.0, 0, 0.03), 1.6, _rng), _t(4.6, 27.0))
	_put("crater", Props.crater(_g, _t(-26, 31.5, 0, 0.03), 2.2, _rng), _t(-26, 31.5))
	Props.luggage(_b, _t(3.2, 33.6), 5, _rng)
	Props.casings(_b, _t(-13, 28), 30, _rng)
	for p: Array in [[-19.5, 27.2], [-14.4, 32.0], [-12.6, 26.4]]:
		Props.cone(_b, _t(p[0], p[1]))
	for x in [-14.0, 14.0]:                                                        # street lamps
		_b.box(Vector3(0.16, 6.0, 0.16), Vector3(x, 3.0, 35.0), Props.STEEL)
		_b.box(Vector3(0.12, 0.12, 2.2), Vector3(x, 6.0, 34.0), Props.STEEL)
	_glow.box(Vector3(0.3, 0.1, 0.6), Vector3(14, 5.92, 33.1), Color.WHITE)


func _gate() -> void:
	_put("booth", Props.booth(_b, _t(7.4, 22.8)), _t(7.4, 22.8))
	var desk := _t(5.0, 20.6, 90)
	_put("table", Props.table(_b, desk), desk)
	_spot("table", Vector3(5.0, 0.83, 20.6), Vector3(3.8, 0, 20.6), 100)
	_put("barrier", Props.barrier(_b, _t(-2.6, 21.5, 90)), _t(-2.6, 21.5, 90))     # chicane
	_put("barrier", Props.barrier(_b, _t(2.6, 18.5, 90)), _t(2.6, 18.5, 90))
	_put("sandbags", Props.sandbags(_b, _t(-7.5, 22.6), 4.3), _t(-7.5, 22.6))
	_put("sandbags", Props.sandbags(_b, _t(-9.5, 21.3, 90), 2.5), _t(-9.5, 21.3, 90))
	Props.casings(_b, _t(-7.5, 21.5), 40, _rng)
	for p: Array in [[-4.6, 24.2], [4.6, 24.2], [0.4, 20.0], [-0.6, 17.2]]:
		Props.cone(_b, _t(p[0], p[1], _rng.randf() * 90))
	_put("floodlight", Props.floodlight(_b, _t(9.6, 21.2)), _t(9.6, 21.2))
	_put("floodlight", Props.floodlight(_b, _t(-12.5, 21.6)), _t(-12.5, 21.6))


func _avenue() -> void:
	_put("bus", Props.bus(_b, _t(-1.2, 5.0, 14)), _t(-1.2, 5.0, 14))
	Props.luggage(_b, _t(2.8, 1.6), 8, _rng)
	Props.luggage(_b, _t(1.8, 10.0), 5, _rng)
	Props.luggage(_b, _t(-3.6, 13.2), 4, _rng)
	for p: Array in [[-12.0, 90.0], [-8.6, 90.0], [8.6, 90.0], [12.0, 90.0]]:      # last line before the doors
		_put("barrier", Props.barrier(_b, _t(p[0], -4.0, p[1])), _t(p[0], -4.0, p[1]))
	_put("barrier", Props.barrier(_b, _t(4.8, -3.0, 58)), _t(4.8, -3.0, 58))       # shoved aside
	_put("crater", Props.crater(_g, _t(-4.2, 12.6, 0, 0.03), 1.8, _rng), _t(-4.2, 12.6))


func _triage() -> void:
	_put("tent", Props.tent(_b, _t(-20, 9), 8, 6), _t(-20, 9))
	_put("tent", Props.tent(_b, _t(-20, -1), 8, 6), _t(-20, -1))
	Props.cot(_b, _t(-22.5, 7.5))
	Props.cot(_b, _t(-20.5, 7.5, 180), true)
	Props.cot(_b, _t(-18.2, 10.6, 90))
	Props.cot(_b, _t(-22.0, -2.5), true)
	Props.cot(_b, _t(-20.0, -2.5))
	Props.cot(_b, _t(-18.0, 0.6, 90), true)
	_put("table", Props.table(_b, _t(-21.5, 10.9), Color("c4c8c8")), _t(-21.5, 10.9))
	_spot("table", Vector3(-21.5, 0.83, 10.9), Vector3(-21.5, 0, 9.7), 15)
	for c: Array in [[-17.0, 6.4, 10.0], [-23.3, 0.9, 80.0], [-16.6, -2.6, 30.0], [-16.4, 11.2, 0.0]]:
		_put("crate", Props.crate(_b, _t(c[0], c[1], c[2]), Vector3(0.8, 0.5, 0.6), Color("c4c8c8")), _t(c[0], c[1], c[2]))
	var amb := _t(-11, 15, -90)
	_put("ambulance", Props.ambulance(_b, amb), amb)
	_spot("vehicle", _at(amb, -0.4, 1.14, 1.6), _at(amb, 0, 0, 3.9), 0)
	for i in 4:                                                                    # the ones they had time for
		Props.bodybag(_b, _t(-29.5, 13.5 + i * 1.9, 90))
		Props.bodybag(_b, _t(-27.0, 13.5 + i * 1.9, 90), Color("c9c9c0") if i == 1 else Color("1d1f24"))
		prop_counts["bodybag"] = prop_counts.get("bodybag", 0) + 2
	for p: Array in [[-31.5, -9.5], [-31.5, -10.8], [-30.2, -9.5]]:
		_put("hesco", Props.hesco(_b, _t(p[0], p[1])), _t(p[0], p[1]))
	_put("barrel", Props.barrel(_b, _t(-14.5, 3.5)), _t(-14.5, 3.5))
	_flame(Vector3(-14.5, 0.9, 3.5), 0.35)
	var heli := _t(-25, -11, 200)
	_put("helicopter", Props.helicopter(_b, heli), heli)
	_put("crater", Props.crater(_g, _t(-25, -11, 0, 0.03), 3.6, _rng), _t(-25, -11))
	_smoke(Vector3(-24.5, 2.5, -11.5), 14)
	_put("rubble", Props.rubble(_b, _t(-30, 22.5), 1.8, _rng), _t(-30, 22.5))


func _motor_pool() -> void:
	var truck_a := _t(16, 12)
	landmarks["truck_a"] = truck_a.origin
	_put("truck", Props.truck(_b, truck_a), truck_a)
	_spot("truck", _at(truck_a, 0.2, 1.2, 2.9), _at(truck_a, 0, 0, 4.7), 20)
	var truck_b := _t(25, 3, 90)
	_put("truck", Props.truck(_b, truck_b), truck_b)
	_spot("truck", _at(truck_b, -0.2, 1.2, 2.9), _at(truck_b, 0, 0, 4.7), 70)
	var hmv := _t(12.5, -2.5, 160)
	_put("humvee", Props.humvee(_b, hmv), hmv)
	_spot("vehicle", _at(hmv, 0, 1.47, -1.5), _at(hmv, 1.75, 0, -1.6), 130)
	var apc := _t(27, -10, 200)
	_put("apc", Props.apc(_b, apc), apc)
	_spot("vehicle", _at(apc, 0, 0.8, 4.2), _at(apc, 0, 0, 5.6), 200)
	_put("tent", Props.tent(_b, _t(19, -9), 6, 5, Props.OLIVE, false), _t(19, -9))  # command post
	_put("table", Props.table(_b, _t(19.5, -9.9), Props.OLIVE_DARK), _t(19.5, -9.9))
	_spot("table", Vector3(19.5, 0.83, -9.9), Vector3(19.5, 0, -8.6), -10)
	_b.box(Vector3(0.5, 0.35, 0.3), Vector3(18.9, 0.98, -9.9), Props.DARK)        # radio
	_b.box(Vector3(0.03, 0.9, 0.03), Vector3(18.7, 1.5, -9.9), Props.STEEL)
	# Ammo dump in the south-east corner
	for p: Array in [[32.0, 13.2], [32.0, 14.5], [32.0, 15.8], [32.0, 17.1], [30.7, 12.5], [29.4, 12.5]]:
		_put("hesco", Props.hesco(_b, _t(p[0], p[1])), _t(p[0], p[1]))
	_put("crate", Props.crate(_b, _t(30.6, 16.6)), _t(30.6, 16.6))
	_put("crate", Props.crate(_b, _t(30.6, 16.6, 12, 0.6), Vector3(0.9, 0.5, 0.6)), _t(30.6, 16.6, 12, 0.6))
	_put("crate", Props.crate(_b, _t(29.4, 17.3, 30)), _t(29.4, 17.3, 30))
	_put("crate", Props.crate(_b, _t(28.2, 14.4, 0), Vector3(1.0, 0.6, 0.7), Props.OLIVE, true), _t(28.2, 14.4))
	_spot("crate", Vector3(28.2, 0.66, 14.4), Vector3(27.0, 0, 14.4), 80)
	_put("table", Props.table(_b, _t(26.5, 17.6), Props.OLIVE_DARK), _t(26.5, 17.6))
	_spot("table", Vector3(26.5, 0.83, 17.6), Vector3(26.5, 0, 16.4), 5)
	for p: Array in [[21.0, 17.5], [21.7, 17.9], [21.2, 18.4]]:
		_put("barrel", Props.barrel(_b, _t(p[0], p[1]), Props.OLIVE_DARK), _t(p[0], p[1]))
	_put("barrel", Props.barrel(_b, _t(23.5, 9.5)), _t(23.5, 9.5))
	_flame(Vector3(23.5, 0.9, 9.5), 0.35)
	_put("crater", Props.crater(_g, _t(18, -1, 0, 0.03), 2.4, _rng), _t(18, -1))
	_put("rubble", Props.rubble(_b, _t(22, 22), 1.4, _rng), _t(22, 22))
	Props.casings(_b, _t(14, 14), 30, _rng)


func _forecourt() -> void:
	for side in [-1.0, 1.0]:                                                       # fighting positions by the door
		_put("sandbags", Props.sandbags(_b, _t(side * 7.0, -10.8), 4.4), _t(side * 7.0, -10.8))
		_put("sandbags", Props.sandbags(_b, _t(side * 7.0 - 2.1, -12.0, 90), 2.4), _t(side * 7.0 - 2.1, -12.0, 90))
		_put("sandbags", Props.sandbags(_b, _t(side * 7.0 + 2.1, -12.0, 90), 2.4), _t(side * 7.0 + 2.1, -12.0, 90))
		Props.mounted_gun(_b, _t(side * 7.0, -11.6, 180))
		Props.casings(_b, _t(side * 7.0, -12.2), 50, _rng)
	_put("wire", Props.wire(_b, _t(-14.5, -9.2), 9.0), _t(-14.5, -9.2))
	_put("wire", Props.wire(_b, _t(15.0, -9.2, 4), 8.0), _t(15.0, -9.2, 4))
	_put("sandbags", Props.sandbags(_b, _t(0, -15.6), 5.0, 2), _t(0, -15.6))        # what they piled at the doors
	_put("crate", Props.crate(_b, _t(-1.6, -16.7)), _t(-1.6, -16.7))
	_put("crate", Props.crate(_b, _t(0.2, -16.5, 15)), _t(0.2, -16.5, 15))
	_put("crate", Props.crate(_b, _t(1.7, -16.8), Vector3(0.9, 0.9, 0.7), Props.WOOD), _t(1.7, -16.8))
	_put("rubble", Props.rubble(_b, _t(13.2, -15.4), 3.0, _rng), _t(13.2, -15.4))  # under the blast hole
	_put("rubble", Props.rubble(_b, _t(-16, -16.6), 1.5, _rng), _t(-16, -16.6))
	_put("rubble", Props.rubble(_b, _t(3.4, -13.4), 0.9, _rng), _t(3.4, -13.4))
	_decal(13.2, -14.5, 9, 7, Color("2a2a2b"), 2, 10)                              # dust
	_put("barrel", Props.barrel(_b, _t(-3.6, -13.2)), _t(-3.6, -13.2))
	_flame(Vector3(-3.6, 0.9, -13.2), 0.35)


func _the_dead() -> void:
	# [x, z, facing, pose, who they were, died human?]
	for c: Array in [
		# heaped at the entrance
		[-0.8, -14.2, 30, P.PRONE, O.CIVILIAN, false], [0.9, -13.6, 140, P.SUPINE, O.OFFICE, false],
		[1.9, -14.4, 250, P.SIDE, O.NURSE, false], [-2.2, -13.3, 80, P.PRONE, O.SOLDIER, true],
		[0.2, -12.4, 10, P.SUPINE, O.CIVILIAN, false], [3.4, -12.3, 300, P.PRONE, O.DOCTOR, false],
		# the two gun pits and the wire
		[-7.9, -12.3, 0, P.SITTING, O.SOLDIER, true], [7.4, -12.6, 200, P.PRONE, O.SOLDIER, true],
		[5.6, -9.6, 90, P.SUPINE, O.CIVILIAN, false], [-12.0, -8.3, 20, P.PRONE, O.CIVILIAN, false],
		[13.5, -8.4, 170, P.PRONE, O.PRISONER, false],
		# along the avenue, with their luggage
		[2.8, 0.5, 60, P.PRONE, O.CIVILIAN, true], [-3.4, -1.5, 200, P.SUPINE, O.OFFICE, true],
		[3.6, 8.2, 330, P.SIDE, O.CIVILIAN, true], [-4.2, 10.6, 100, P.PRONE, O.WORKER, false],
		[1.2, 15.5, 45, P.SUPINE, O.CIVILIAN, false],
		# the checkpoint
		[-3.6, 23.5, 40, P.PRONE, O.SOLDIER, true], [7.4, 21.35, 0, P.SITTING, O.SOLDIER, true],
		# triage: patients and the people treating them
		[-17.2, 8.8, 120, P.PRONE, O.NURSE, true], [-18.6, -3.8, 260, P.SIDE, O.DOCTOR, true],
		[-15.5, 1.4, 15, P.PRONE, O.NURSE, false], [-13.6, 9.0, 290, P.SUPINE, O.FIREFIGHTER, true],
		# the helicopter crew
		[-21.5, -6.0, 60, P.SUPINE, O.SOLDIER, true], [-27.0, -6.6, 310, P.PRONE, O.SOLDIER, true],
		# motor pool and ammo dump
		[14.2, 15.6, 120, P.PRONE, O.SOLDIER, true], [18.4, 8.6, 270, P.SUPINE, O.WORKER, false],
		[22.6, 6.6, 10, P.PRONE, O.SOLDIER, false], [27.6, -5.6, 150, P.SUPINE, O.SOLDIER, true],
		[31.0, 15.2, 90, P.SITTING, O.SOLDIER, true],
		# out on the road
		[-15.3, 27.9, 300, P.PRONE, O.COP, true], [6.6, 28.6, 75, P.SUPINE, O.CIVILIAN, false],
		[11.6, 33.6, 190, P.PRONE, O.CIVILIAN, true], [-22.0, 27.4, 130, P.SIDE, O.FIREFIGHTER, false],
		[19.2, 29.6, 20, P.PRONE, O.CIVILIAN, false], [-5.4, 26.5, 210, P.SUPINE, O.COP, false]]:
		_corpse(c[0], c[1], c[2], c[3], c[4], c[5])
	_corpse(-22.5, 7.5, 180, P.SUPINE, O.CIVILIAN, true, 0.33)                     # died on the cots
	_corpse(-22.0, -2.5, 0, P.SUPINE, O.CIVILIAN, false, 0.33)
	# Guns that fell with whoever carried them
	_spot("corpse", Vector3(-7.1, 0.1, -12.7), Vector3(-6.9, 0, -13.9), 40)
	_spot("corpse", Vector3(6.5, 0.1, -12.2), Vector3(7.0, 0, -14.0), 110)
	_spot("corpse", Vector3(-2.9, 0.1, 23.0), Vector3(-1.9, 0, 23.7), 300)
	_spot("corpse", Vector3(-20.7, 0.1, -6.6), Vector3(-19.6, 0, -5.9), 160)
	_spot("corpse", Vector3(-14.5, 0.1, 27.3), Vector3(-13.4, 0, 26.9), 20)


func _lights() -> void:
	var a := SpotLight3D.new()                                                     # the one working floodlight
	a.position = Vector3(9.6, 5.2, 21.2)
	root.add_child(a)
	a.look_at_from_position(a.position, Vector3(1, 0, 2))
	a.light_color = Color("dfe8ff")
	a.light_energy = 6.0
	a.spot_range = 46.0
	a.spot_angle = 44.0
	a.shadow_enabled = true
	_glow.box(Vector3(1.2, 0.35, 0.25), Vector3(9.6, 5.2, 21.2), Color.WHITE)
	var b := SpotLight3D.new()
	b.position = Vector3(-12.5, 5.2, 21.6)
	root.add_child(b)
	b.look_at_from_position(b.position, Vector3(-18, 0, 5))
	b.light_color = Color("dfe8ff")
	b.light_energy = 4.0
	b.spot_range = 34.0
	b.spot_angle = 40.0
	_glow.box(Vector3(1.2, 0.35, 0.25), Vector3(-12.5, 5.2, 21.6), Color.WHITE)
	var lamp := SpotLight3D.new()                                                  # street lamp over the spawn
	lamp.position = Vector3(14, 5.8, 33.1)
	lamp.rotation.x = -PI / 2.0
	lamp.light_color = Color("ffd9a0")
	lamp.light_energy = 4.0
	lamp.spot_range = 14.0
	lamp.spot_angle = 55.0
	root.add_child(lamp)
