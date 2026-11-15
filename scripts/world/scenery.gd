class_name Scenery
extends RefCounted
## Set pieces for the streets: what the old evacuation-shelter map was made of, kept as a kit.
##
## A map makes one Scenery, places pieces with `place(xf)` + a piece function, then calls `finish()`.
## Every piece is laid out in its own metres (the numbers it had in the shelter yard, around the
## piece's `origin`), so `place` can drop it anywhere and at any angle.
##
##   building elements  shelter_building, facade, entrance, blast_hole, fire_escape
##   set pieces         crash_site (fallen helicopter), triage_camp, motor_pool (trucks, humvee,
##                      APC, ammo dump), checkpoint, gun_pits, street_wrecks, roadblock
##   helpers            put, solid, decal, corpse, flame, smoke, spot (a weapon pickup), label
##
## Vehicles, barriers, tents and the rest are single props in Props. Solid parts collide through
## the map's StaticBody and close navigation through `blocker`; guns may lie at `spot`s.
## Only `rng` (seeded by the map) scatters detail, so every peer builds the same thing.

const FLOORS := 5                           ## the shelter building's floors
const FLOOR_H := 3.6
const BUILDING := Rect2(-20, -42, 40, 24)   ## its footprint around its origin: front wall at z = -18
const SIDE_DOORS := [Vector3(-20, 0, -30), Vector3(20, 0, -30)]

const WALL := Color("767a80")
const WALL_DARK := Color("5c6066")
const FRAME := Color("9a9da2")
const GLASS := Color("141c24")
const HOLE := Color("050607")
const SHUTTER := Color("4a4e55")
const BLOOD := Color("4a0606")
const P := Corpses.Pose
const O := Characters.Outfit

var root: Node3D
var body: StaticBody3D
var rng: RandomNumberGenerator
## Called with (world centre, size, basis) for every solid part a walker would bump into.
var blocker := Callable()
var spots: Array = []         ## every WeaponPickup made
var corpses: Array = []       ## { pos, outfit, pose, zombie }
var prop_counts := {}         ## kind -> how many were placed
var next_iid := 10            ## interactable ids handed to spots; the map must keep them unique
var b := MeshKit.Builder.new()      # props and buildings
var g := MeshKit.Builder.new()      # ground paint and stains
var dead := MeshKit.Builder.new()   # corpses
var glow := MeshKit.Builder.new()   # lit windows
var fire := MeshKit.Builder.new()   # flames
var xf := Transform3D.IDENTITY      # where the current piece goes
var _w := Transform3D.IDENTITY      # xf, shifted so the piece's own numbers land around its origin


func _init(root_: Node3D, body_: StaticBody3D, rng_: RandomNumberGenerator) -> void:
	root = root_
	body = body_
	rng = rng_


static func floor_y(i: int) -> float:
	return i * FLOOR_H


## Put the next piece at `at`, turned `yaw_deg` (its own -Z faces that way).
func place(at: Vector3, yaw_deg := 0.0) -> Scenery:
	xf = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), at)
	return self


## Add the merged meshes to the root. Call once, after the last piece.
func finish() -> void:
	root.add_child(g.instance(null, false))
	root.add_child(b.instance())
	root.add_child(dead.instance())
	root.add_child(glow.instance(MeshKit.emissive(Color("ffd9a0"), 2.5), false))
	root.add_child(fire.instance(MeshKit.emissive(Color("ff8a2a"), 5.0), false))


func _origin(x: float, z: float) -> void:
	_w = xf * Transform3D(Basis.IDENTITY, Vector3(-x, 0, -z))


# --- Helpers (piece coordinates) -------------------------------------------------------------

func t(x: float, z: float, yaw_deg := 0.0, y := 0.0) -> Transform3D:
	return _w * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(x, y, z))


func box(size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY, into: MeshKit.Builder = null) -> void:
	(into if into != null else b).box(size, pos, color, rot, _w)


## A prop from Props at world transform `at`: count it, make its solid parts solid.
func put(kind: String, colliders: Array, at: Transform3D) -> void:
	prop_counts[kind] = prop_counts.get(kind, 0) + 1
	for c: Array in colliders:
		_collide_world(at * Transform3D(Basis.IDENTITY, c[0]), c[1])


func collide(center: Vector3, size: Vector3, rot := Basis.IDENTITY) -> void:
	_collide_world(_w * Transform3D(rot, center), size)


func _collide_world(at: Transform3D, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.transform = at
	body.add_child(cs)
	var y := at.origin.y
	if blocker.is_valid() and y - size.y * 0.5 < 0.9 and y + size.y * 0.5 > 0.35: # a walker bumps into it
		blocker.call(at.origin, size, at.basis)


func solid(center: Vector3, size: Vector3, color: Color) -> void:
	box(size, center, color)
	collide(center, size)


## Flat paint or stain on the ground. `layer` keeps overlapping ones from flickering.
func decal(x: float, z: float, w: float, d: float, color: Color, layer := 3, yaw_deg := 0.0) -> void:
	g.box(Vector3(w, 0.012, d), Vector3(x, 0.012 + layer * 0.013, z), color, Basis(Vector3.UP, deg_to_rad(yaw_deg)), _w)


## A place a gun may lie: `pos` where it lies, `stand` where a player reaches it from.
func spot(kind: String, pos: Vector3, stand: Vector3, yaw_deg := 0.0) -> WeaponPickup:
	var s := WeaponPickup.new()
	s.iid = next_iid
	next_iid += 1
	s.kind = kind
	s.transform = _w * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), pos)
	s.stand = _w * stand
	root.add_child(s)
	spots.append(s)
	return s


## Same as `spot`, with points already in world space (from `at`).
func spot_world(kind: String, pos: Vector3, stand: Vector3, yaw_deg := 0.0) -> WeaponPickup:
	var keep := _w
	_w = Transform3D.IDENTITY
	var s := spot(kind, pos, stand, yaw_deg + rad_to_deg(keep.basis.get_euler().y))
	_w = keep
	return s


## A prop's own-space point in the world.
func at(xform: Transform3D, x: float, y: float, z: float) -> Vector3:
	return xform * Vector3(x, y, z)


func corpse(x: float, z: float, yaw_deg: float, pose: int, outfit: int, human: bool, y := 0.0) -> void:
	var id := 300 + corpses.size() * 7
	var style := Corpses.human_style(id, outfit) if human else Characters.zombie_style(id, 0, outfit)
	Corpses.add(dead, style, pose, t(x, z, yaw_deg, y), rng)
	corpses.append({ "pos": _w * Vector3(x, y, z), "outfit": outfit, "pose": pose, "zombie": not human })
	if y < 0.1:
		decal(x + rng.randf_range(-0.3, 0.3), z + rng.randf_range(-0.3, 0.3), rng.randf_range(1.0, 1.9),
			rng.randf_range(0.8, 1.5), BLOOD, 5, rng.randf() * 360.0)


func flame(pos: Vector3, size := 0.5) -> void:
	for i in 4:
		fire.box(Vector3(size * 0.5, size * rng.randf_range(0.8, 1.6), size * 0.5),
			pos + Vector3(rng.randf_range(-size, size) * 0.4, size * 0.5, rng.randf_range(-size, size) * 0.4),
			Color.WHITE, Basis(Vector3.UP, rng.randf() * TAU), _w)
	var light := OmniLight3D.new()
	light.position = _w * (pos + Vector3(0, 0.8, 0))
	light.light_color = Color("ff9a40")
	light.light_energy = 2.4
	light.omni_range = 10.0
	root.add_child(light)


func smoke(pos: Vector3, amount := 20) -> void:
	var p := CPUParticles3D.new()
	p.position = _w * pos
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


func label(text: String, pos: Vector3, size: int, color: Color, yaw_deg := 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.01
	l.modulate = color
	l.outline_size = 0
	l.transform = _w * Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), pos)
	l.shaded = true
	root.add_child(l)


# --- Building elements ------------------------------------------------------------------------

## The shelter: five floors, walls as separate slabs (so an interior can go in later), windows on
## the floor grid, a torn-open entrance, a blast hole and a fire escape. Origin: the middle of its
## front wall; it faces +Z.
func shelter_building() -> void:
	_origin(0, BUILDING.end.y)
	var x0 := BUILDING.position.x
	var x1 := BUILDING.end.x
	var z0 := BUILDING.position.y
	var z1 := BUILDING.end.y
	var h := FLOORS * FLOOR_H
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var th := 0.6
	solid(Vector3(cx, h * 0.5, z1 - th * 0.5), Vector3(x1 - x0, h, th), WALL)        # front
	solid(Vector3(cx, h * 0.5, z0 + th * 0.5), Vector3(x1 - x0, h, th), WALL_DARK)   # back
	solid(Vector3(x0 + th * 0.5, h * 0.5, cz), Vector3(th, h, z1 - z0), WALL_DARK)   # west
	solid(Vector3(x1 - th * 0.5, h * 0.5, cz), Vector3(th, h, z1 - z0), WALL_DARK)   # east
	if blocker.is_valid(): # the inside is closed too until it has one
		blocker.call(_w * Vector3(cx, 1.0, cz), Vector3(x1 - x0, 2.0, z1 - z0), _w.basis)
	box(Vector3(x1 - x0 + 0.6, 0.4, z1 - z0 + 0.6), Vector3(cx, h + 0.2, cz), WALL_DARK)  # roof
	for side: Array in [[cx, z1 + 0.15, x1 - x0 + 0.6, 0.3], [cx, z0 - 0.15, x1 - x0 + 0.6, 0.3],
			[x0 - 0.15, cz, 0.3, z1 - z0], [x1 + 0.15, cz, 0.3, z1 - z0]]:
		box(Vector3(side[2], 0.9, side[3]), Vector3(side[0], h + 0.85, side[1]), WALL)  # parapet
	box(Vector3(3.0, 2.4, 3.0), Vector3(-12, h + 1.6, -30), SHUTTER)                  # water tank
	box(Vector3(4.0, 1.2, 2.5), Vector3(8, h + 1.0, -34), WALL_DARK)                  # plant room
	box(Vector3(0.15, 7.0, 0.15), Vector3(14, h + 3.9, -22), SHUTTER)                 # mast
	box(Vector3(0.3, 0.3, 0.3), Vector3(14, h + 7.5, -22), Color.WHITE, Basis.IDENTITY, glow)
	facade(Vector3(x0, 0, z1), Vector3.RIGHT, Vector3.BACK, 10, [4, 5], [[7, 2], [8, 2], [7, 3], [8, 3]])
	facade(Vector3(x0, 0, z0), Vector3.BACK, Vector3.LEFT, 6, [3], [])
	facade(Vector3(x1, 0, z0), Vector3.BACK, Vector3.RIGHT, 6, [3], [])
	entrance(z1)
	blast_hole(Vector3(12, floor_y(2) + 1.6, z1))
	fire_escape(x1, -34.0)
	for door: Vector3 in SIDE_DOORS:                                                   # dark side doorways
		box(Vector3(0.14, 2.5, 1.7), door + Vector3(signf(door.x) * 0.02, 1.25, 0), HOLE)
		box(Vector3(0.3, 0.2, 2.1), door + Vector3(signf(door.x) * 0.1, 2.6, 0), FRAME)
	box(Vector3(5.0, 3.2, 0.06), Vector3(-12, floor_y(3) + 1.0, z1 + 0.08), Color("c9c9c0")) # banner
	box(Vector3(1.4, 2.6, 0.07), Vector3(-10.6, floor_y(3) + 0.6, z1 + 0.09), BLOOD)
	label("SAFE ZONE", Vector3(-12, floor_y(3) + 1.6, z1 + 0.13), 110, Color("1c3a8a"))
	label("ALL SURVIVORS\nWELCOME", Vector3(-12.3, floor_y(3) + 0.3, z1 + 0.13), 48, Color("222222"))


## One wall's worth of windows, floor bands and pilasters. `along` runs along the wall, `out`
## points away from it. `doors` are ground-floor bays to leave clear; `skip` are [bay, floor]
## pairs where something else goes (a blast hole). Uses the current piece's origin.
func facade(origin: Vector3, along: Vector3, out: Vector3, bays: int, doors: Array, skip: Array,
		floors := FLOORS, floor_h := FLOOR_H) -> void:
	var bay_w := 4.0
	var along_x := absf(along.x) > 0.5
	var put_box := func(w: float, hgt: float, depth: float, a: float, y: float, o: float, color: Color, into: MeshKit.Builder) -> void:
		box(Vector3(w, hgt, depth) if along_x else Vector3(depth, hgt, w), origin + along * a + Vector3(0, y, 0) + out * o, color, Basis.IDENTITY, into)
	for f in floors + 1:
		put_box.call(bays * bay_w + 0.3, 0.35, 0.28, bays * bay_w * 0.5, f * floor_h, 0.1, WALL_DARK, b) # floor band
	for k in bays + 1:
		put_box.call(0.55, floors * floor_h, 0.24, k * bay_w, floors * floor_h * 0.5, 0.08, WALL_DARK, b) # pilaster
	for f in floors:
		for k in bays:
			if (f == 0 and doors.has(k)) or skip.has([k, f]):
				continue
			var a := (k + 0.5) * bay_w
			var y := f * floor_h + 1.95
			var roll := (f * 31 + k * 17 + int(absf(origin.x + origin.z)) * 7) % 20
			if f == 0: # ground floor was shuttered
				put_box.call(2.6, 1.9, 0.1, a, y, 0.03, SHUTTER, b)
				for i in 5:
					put_box.call(2.6, 0.06, 0.14, a, y - 0.8 + i * 0.4, 0.04, SHUTTER.darkened(0.25), b)
				continue
			put_box.call(2.9, 2.2, 0.08, a, y, 0.02, FRAME, b)
			if roll < 2: # someone left a light on
				put_box.call(2.6, 1.9, 0.1, a, y, 0.04, Color.WHITE, glow)
			elif roll < 5: # boarded up
				put_box.call(2.6, 1.9, 0.1, a, y, 0.03, HOLE, b)
				for i in 3:
					put_box.call(2.8, 0.34, 0.12, a, y - 0.6 + i * 0.6, 0.06, Props.WOOD.darkened(0.1 * i), b)
			elif roll < 8: # smashed
				put_box.call(2.6, 1.9, 0.1, a, y, 0.03, HOLE, b)
				put_box.call(0.9, 0.7, 0.1, a - 0.85, y - 0.6, 0.04, GLASS.lightened(0.15), b)
				put_box.call(0.6, 0.5, 0.1, a + 1.0, y + 0.7, 0.04, GLASS.lightened(0.15), b)
			else:
				put_box.call(2.6, 1.9, 0.1, a, y, 0.03, GLASS, b)
				put_box.call(0.08, 1.9, 0.12, a, y, 0.04, FRAME, b) # mullion
			if roll == 9 or roll == 14: # a bloody handprint smear, or a sheet hung out
				put_box.call(0.5, 1.2, 0.05, a + 0.6, y - 1.3, 0.05, BLOOD if roll == 9 else Color("c9c9c0"), b)


## A torn-open main entrance in the wall at z, centred on x = 0: shutters, tape, canopy, sign.
func entrance(z: float, sign := "EVACUATION SHELTER 7") -> void:
	box(Vector3(7.6, 3.4, 0.2), Vector3(0, 1.7, z + 0.05), HOLE)                       # the dark doorway
	for x in [-1.85, 1.85]:                                                             # steel shutters, half torn
		box(Vector3(3.5, 3.2, 0.12), Vector3(x, 1.6, z + 0.18), SHUTTER, Basis(Vector3.RIGHT, 0.05 if x < 0 else -0.12))
		for i in 7:
			box(Vector3(3.5, 0.07, 0.16), Vector3(x, 0.35 + i * 0.42, z + 0.2), SHUTTER.darkened(0.25))
	box(Vector3(8.2, 0.12, 0.05), Vector3(0, 1.6, z + 0.32), Props.HAZARD, Basis(Vector3.BACK, 0.38)) # tape
	box(Vector3(8.2, 0.12, 0.05), Vector3(0, 1.6, z + 0.33), Props.HAZARD, Basis(Vector3.BACK, -0.38))
	collide(Vector3(0, 1.7, z + 0.2), Vector3(7.6, 3.4, 0.4))
	box(Vector3(12.4, 0.4, 4.6), Vector3(0, 3.9, z + 2.3), WALL_DARK)                  # canopy
	box(Vector3(12.5, 0.14, 4.7), Vector3(0, 3.66, z + 2.3), Props.RED)
	for x in [-5.6, 5.6]:
		solid(Vector3(x, 1.85, z + 4.2), Vector3(0.5, 3.7, 0.5), WALL)                 # columns
	box(Vector3(11.0, 1.5, 0.2), Vector3(0, 4.95, z + 4.4), Color("c8ccd0"))           # sign board
	box(Vector3(0.9, 0.3, 0.06), Vector3(-4.6, 4.95, z + 4.52), Props.RED)             # red cross
	box(Vector3(0.3, 0.9, 0.06), Vector3(-4.6, 4.95, z + 4.52), Props.RED)
	label(sign, Vector3(0.6, 4.95, z + 4.53), 72, Color("1a1c20"))
	label("DO NOT OPEN\nDEAD INSIDE", Vector3(0, 2.0, z + 0.36), 64, Color("a01010"))
	var red := OmniLight3D.new()                                                       # emergency light
	red.position = _w * Vector3(0, 3.2, z + 2.2)
	red.light_color = Color("ff2a1a")
	red.light_energy = 1.6
	red.omni_range = 9.0
	root.add_child(red)
	box(Vector3(0.3, 0.15, 0.15), Vector3(0, 3.5, z + 0.45), Color.WHITE, Basis.IDENTITY, fire)


## Something blew a two-storey hole in a wall facing +Z at `pos`.
func blast_hole(pos: Vector3) -> void:
	box(Vector3(7.2, 6.6, 0.25), pos + Vector3(0, 1.8, 0.1), HOLE)
	for i in 26:
		var a := TAU * i / 26.0
		var s := rng.randf_range(0.5, 1.3)
		box(Vector3(s, s * rng.randf_range(0.6, 1.4), 0.5), pos + Vector3(cos(a) * 3.8, 1.8 + sin(a) * 3.5, 0.2),
			WALL.darkened(rng.randf_range(0.1, 0.5)), Basis(Vector3.BACK, rng.randf() * TAU))
	box(Vector3(8.5, 4.0, 0.06), pos + Vector3(0.4, 6.6, 0.33), Color("1a1a1b"))      # soot above it
	box(Vector3(4.0, 0.25, 1.6), pos + Vector3(-0.8, -1.5, 0.6), WALL_DARK, Basis(Vector3.RIGHT, 0.5)) # hanging slab
	smoke(pos + Vector3(0, 3.0, 0.5), 16)


## Steel fire escape on a wall facing +X at x, centred on z. Reaches every floor; the last ladder is up.
func fire_escape(x: float, z: float, floors := FLOORS, floor_h := FLOOR_H) -> void:
	var steel := Color("3c4046")
	for f in range(1, floors):
		var y := f * floor_h
		box(Vector3(1.4, 0.08, 5.4), Vector3(x + 0.8, y, z), steel)                    # landing
		box(Vector3(0.05, 1.0, 5.4), Vector3(x + 1.5, y + 0.5, z), steel)              # rail
		box(Vector3(0.05, 0.05, 5.4), Vector3(x + 1.5, y + 1.0, z), steel)
		if f < floors - 1:
			var dir := 1.0 if f % 2 == 1 else -1.0
			box(Vector3(0.9, 0.08, 5.6), Vector3(x + 0.9, y + floor_h * 0.5, z), steel,
				Basis(Vector3.RIGHT, dir * atan2(floor_h, 4.2)))                        # stairs
	box(Vector3(0.5, 2.0, 0.08), Vector3(x + 0.8, floor_h - 1.0, z + 2.5), steel)      # the raised ladder


# --- Set pieces -------------------------------------------------------------------------------

## A military helicopter that came down: the wreck in its crater, smoke, its crew, a gun by one of
## them. About 14 x 12 m.
func crash_site() -> void:
	_origin(-25, -11)
	var heli := t(-25, -11, 200)
	put("helicopter", Props.helicopter(b, heli), heli)
	put("crater", Props.crater(g, t(-25, -11, 0, 0.03), 3.6, rng), t(-25, -11))
	smoke(Vector3(-24.5, 2.5, -11.5), 14)
	flame(Vector3(-23.0, 0.6, -12.5), 0.6)
	corpse(-21.5, -6.0, 60, P.SUPINE, O.SOLDIER, true)
	corpse(-27.0, -6.6, 310, P.PRONE, O.SOLDIER, true)
	spot("corpse", Vector3(-20.7, 0.1, -6.6), Vector3(-19.6, 0, -5.9), 160)


## Two medical tents with cots, an ambulance, body bags and the medics who stayed. About 20 x 20 m.
func triage_camp() -> void:
	_origin(-20, 4)
	put("tent", Props.tent(b, t(-20, 9), 8, 6), t(-20, 9))
	put("tent", Props.tent(b, t(-20, -1), 8, 6), t(-20, -1))
	Props.cot(b, t(-22.5, 7.5))
	Props.cot(b, t(-20.5, 7.5, 180), true)
	Props.cot(b, t(-18.2, 10.6, 90))
	Props.cot(b, t(-22.0, -2.5), true)
	Props.cot(b, t(-20.0, -2.5))
	Props.cot(b, t(-18.0, 0.6, 90), true)
	put("table", Props.table(b, t(-21.5, 10.9), Color("c4c8c8")), t(-21.5, 10.9))
	spot("table", Vector3(-21.5, 0.83, 10.9), Vector3(-21.5, 0, 9.7), 15)
	for c: Array in [[-17.0, 6.4, 10.0], [-23.3, 0.9, 80.0], [-16.6, -2.6, 30.0], [-16.4, 11.2, 0.0]]:
		put("crate", Props.crate(b, t(c[0], c[1], c[2]), Vector3(0.8, 0.5, 0.6), Color("c4c8c8")), t(c[0], c[1], c[2]))
	var amb := t(-11, 15, -90)
	put("ambulance", Props.ambulance(b, amb), amb)
	spot_world("vehicle", at(amb, -0.4, 1.14, 1.6), at(amb, 0, 0, 3.9), 0)
	for i in 4:                                                                       # the ones they had time for
		Props.bodybag(b, t(-29.5, 13.5 + i * 1.9, 90))
		Props.bodybag(b, t(-27.0, 13.5 + i * 1.9, 90), Color("c9c9c0") if i == 1 else Color("1d1f24"))
		prop_counts["bodybag"] = prop_counts.get("bodybag", 0) + 2
	put("barrel", Props.barrel(b, t(-14.5, 3.5)), t(-14.5, 3.5))
	flame(Vector3(-14.5, 0.9, 3.5), 0.35)
	corpse(-17.2, 8.8, 120, P.PRONE, O.NURSE, true)
	corpse(-18.6, -3.8, 260, P.SIDE, O.DOCTOR, true)
	corpse(-15.5, 1.4, 15, P.PRONE, O.NURSE, false)
	corpse(-22.5, 7.5, 180, P.SUPINE, O.CIVILIAN, true, 0.33)                        # died on the cots
	corpse(-22.0, -2.5, 0, P.SUPINE, O.CIVILIAN, false, 0.33)


## Two trucks, a humvee, an APC, a command tent and an ammo dump behind HESCO walls; guns in the
## vehicles and on the tables. About 24 x 30 m.
func motor_pool() -> void:
	_origin(22, 4)
	var truck_a := t(16, 12)
	put("truck", Props.truck(b, truck_a), truck_a)
	spot_world("truck", at(truck_a, 0.2, 1.2, 2.9), at(truck_a, 0, 0, 4.7), 20)
	var truck_b := t(25, 3, 90)
	put("truck", Props.truck(b, truck_b), truck_b)
	spot_world("truck", at(truck_b, -0.2, 1.2, 2.9), at(truck_b, 0, 0, 4.7), 70)
	var hmv := t(12.5, -2.5, 160)
	put("humvee", Props.humvee(b, hmv), hmv)
	spot_world("vehicle", at(hmv, 0, 1.47, -1.5), at(hmv, 1.75, 0, -1.6), 130)
	var apc := t(27, -10, 200)
	put("apc", Props.apc(b, apc), apc)
	spot_world("vehicle", at(apc, 0, 0.8, 4.2), at(apc, 0, 0, 5.6), 200)
	put("tent", Props.tent(b, t(19, -9), 6, 5, Props.OLIVE, false), t(19, -9))       # command post
	put("table", Props.table(b, t(19.5, -9.9), Props.OLIVE_DARK), t(19.5, -9.9))
	spot("table", Vector3(19.5, 0.83, -9.9), Vector3(19.5, 0, -8.6), -10)
	box(Vector3(0.5, 0.35, 0.3), Vector3(18.9, 0.98, -9.9), Props.DARK)               # radio
	box(Vector3(0.03, 0.9, 0.03), Vector3(18.7, 1.5, -9.9), Props.STEEL)
	for p: Array in [[32.0, 13.2], [32.0, 14.5], [32.0, 15.8], [32.0, 17.1], [30.7, 12.5], [29.4, 12.5]]:
		put("hesco", Props.hesco(b, t(p[0], p[1])), t(p[0], p[1]))                   # ammo dump
	put("crate", Props.crate(b, t(30.6, 16.6)), t(30.6, 16.6))
	put("crate", Props.crate(b, t(30.6, 16.6, 12, 0.6), Vector3(0.9, 0.5, 0.6)), t(30.6, 16.6, 12, 0.6))
	put("crate", Props.crate(b, t(29.4, 17.3, 30)), t(29.4, 17.3, 30))
	put("crate", Props.crate(b, t(28.2, 14.4, 0), Vector3(1.0, 0.6, 0.7), Props.OLIVE, true), t(28.2, 14.4))
	spot("crate", Vector3(28.2, 0.66, 14.4), Vector3(27.0, 0, 14.4), 80)
	put("table", Props.table(b, t(26.5, 17.6), Props.OLIVE_DARK), t(26.5, 17.6))
	spot("table", Vector3(26.5, 0.83, 17.6), Vector3(26.5, 0, 16.4), 5)
	for p: Array in [[21.0, 17.5], [21.7, 17.9], [21.2, 18.4]]:
		put("barrel", Props.barrel(b, t(p[0], p[1]), Props.OLIVE_DARK), t(p[0], p[1]))
	put("barrel", Props.barrel(b, t(23.5, 9.5)), t(23.5, 9.5))
	flame(Vector3(23.5, 0.9, 9.5), 0.35)
	put("crater", Props.crater(g, t(18, -1, 0, 0.03), 2.4, rng), t(18, -1))
	Props.casings(b, t(14, 14), 30, rng)
	corpse(14.2, 15.6, 120, P.PRONE, O.SOLDIER, true)
	corpse(18.4, 8.6, 270, P.SUPINE, O.WORKER, false)
	corpse(27.6, -5.6, 150, P.SUPINE, O.SOLDIER, true)


## A gate checkpoint: booth, desk, chicane of barriers, sandbags, cones, floodlights; two soldiers.
## About 24 x 8 m, the road through it runs along Z.
func checkpoint() -> void:
	_origin(0, 21)
	put("booth", Props.booth(b, t(7.4, 22.8)), t(7.4, 22.8))
	var desk := t(5.0, 20.6, 90)
	put("table", Props.table(b, desk), desk)
	spot("table", Vector3(5.0, 0.83, 20.6), Vector3(3.8, 0, 20.6), 100)
	put("barrier", Props.barrier(b, t(-2.6, 21.5, 90)), t(-2.6, 21.5, 90))           # chicane
	put("barrier", Props.barrier(b, t(2.6, 18.5, 90)), t(2.6, 18.5, 90))
	put("sandbags", Props.sandbags(b, t(-7.5, 22.6), 4.3), t(-7.5, 22.6))
	put("sandbags", Props.sandbags(b, t(-9.5, 21.3, 90), 2.5), t(-9.5, 21.3, 90))
	Props.casings(b, t(-7.5, 21.5), 40, rng)
	for p: Array in [[-4.6, 24.2], [4.6, 24.2], [0.4, 20.0], [-0.6, 17.2]]:
		Props.cone(b, t(p[0], p[1], rng.randf() * 90))
	put("floodlight", Props.floodlight(b, t(9.6, 21.2)), t(9.6, 21.2))
	put("floodlight", Props.floodlight(b, t(-12.5, 21.6)), t(-12.5, 21.6))
	corpse(-3.6, 23.5, 40, P.PRONE, O.SOLDIER, true)
	corpse(7.4, 21.35, 0, P.SITTING, O.SOLDIER, true)
	spot("corpse", Vector3(-2.9, 0.1, 23.0), Vector3(-1.9, 0, 23.7), 300)


## Two sandbagged machine-gun pits either side of a doorway, wire, rubble, the last defenders.
## About 30 x 8 m, facing +Z (the way the guns point).
func gun_pits() -> void:
	_origin(0, -12)
	for side in [-1.0, 1.0]:
		put("sandbags", Props.sandbags(b, t(side * 7.0, -10.8), 4.4), t(side * 7.0, -10.8))
		put("sandbags", Props.sandbags(b, t(side * 7.0 - 2.1, -12.0, 90), 2.4), t(side * 7.0 - 2.1, -12.0, 90))
		put("sandbags", Props.sandbags(b, t(side * 7.0 + 2.1, -12.0, 90), 2.4), t(side * 7.0 + 2.1, -12.0, 90))
		Props.mounted_gun(b, t(side * 7.0, -11.6, 180))
		Props.casings(b, t(side * 7.0, -12.2), 50, rng)
	put("wire", Props.wire(b, t(-14.5, -9.2), 9.0), t(-14.5, -9.2))
	put("wire", Props.wire(b, t(15.0, -9.2, 4), 8.0), t(15.0, -9.2, 4))
	put("rubble", Props.rubble(b, t(3.4, -13.4), 0.9, rng), t(3.4, -13.4))
	put("barrel", Props.barrel(b, t(-3.6, -13.2)), t(-3.6, -13.2))
	flame(Vector3(-3.6, 0.9, -13.2), 0.35)
	corpse(-7.9, -12.3, 0, P.SITTING, O.SOLDIER, true)
	corpse(7.4, -12.6, 200, P.PRONE, O.SOLDIER, true)
	corpse(5.6, -9.6, 90, P.SUPINE, O.CIVILIAN, false)
	spot("corpse", Vector3(-7.1, 0.1, -12.7), Vector3(-6.9, 0, -13.9), 40)
	spot("corpse", Vector3(6.5, 0.1, -12.2), Vector3(7.0, 0, -14.0), 110)


## Cars left in a road: a police car (gun inside), a burning wreck, one on its roof, a humvee,
## craters, luggage and cones. About 40 x 9 m along X.
func street_wrecks() -> void:
	_origin(0, 30)
	var police := t(-17, 29.5, 70)
	put("car", Props.car(b, police, Color("20242c"), false, true), police)
	spot_world("vehicle", at(police, 0, 1.06, 1.75), at(police, 0, 0, 3.4), 70)
	put("car", Props.car(b, t(9, 31.8, 185), Color("8a2222")), t(9, 31.8, 185))
	put("car", Props.car(b, t(15.5, 28.3, 20), Props.SOOT, true), t(15.5, 28.3, 20))
	flame(Vector3(15.3, 0.9, 27.6), 0.7)
	smoke(Vector3(15.5, 1.6, 28.3))
	var flipped := _w * Transform3D(Basis(Vector3.UP, deg_to_rad(95)) * Basis(Vector3.FORWARD, PI / 2.0), Vector3(23, 0.9, 31))
	put("car", Props.car(b, flipped, Color("2a4a8a")), flipped)
	put("humvee", Props.humvee(b, t(-8, 32.3, 80), Props.OLIVE), t(-8, 32.3, 80))
	put("crater", Props.crater(g, t(4.6, 27.0, 0, 0.03), 1.6, rng), t(4.6, 27.0))
	Props.luggage(b, t(3.2, 33.6), 5, rng)
	Props.casings(b, t(-13, 28), 30, rng)
	for p: Array in [[-19.5, 27.2], [-14.4, 32.0], [-12.6, 26.4]]:
		Props.cone(b, t(p[0], p[1]))
	corpse(-15.3, 27.9, 300, P.PRONE, O.COP, true)
	corpse(6.6, 28.6, 75, P.SUPINE, O.CIVILIAN, false)
	spot("corpse", Vector3(-14.5, 0.1, 27.3), Vector3(-13.4, 0, 26.9), 20)


## Barriers across a road `width` metres wide (along X), with ROAD CLOSED signs.
func roadblock(width := 10.0) -> void:
	_origin(0, 0)
	var n := maxi(2, ceili(width / 3.2))
	for i in n:
		var x := -width * 0.5 + (i + 0.5) * width / n
		put("barrier", Props.barrier(b, t(x, 0, 90)), t(x, 0, 90))
	label("ROAD CLOSED", Vector3(0, 1.6, 0.35), 56, Color("d8b21a"))
