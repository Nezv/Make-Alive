class_name RoadProps
## What people left on the roads when they ran: everyday cars and bikes, a fallen tree, a snapped
## power pole, benches dragged into a barricade, bins knocked over, and the small things dropped on
## the way (backpacks, bottles, phones, flip-flops). Same rules as Props: each draws into the
## Builder it is given at transform `t`, stands on y = 0, faces -Z, and returns its solid parts as
## [[center, size, basis?], ...] in its own space. Scattered detail takes the caller's seeded rng,
## never randf, so every peer builds the same road. RoadScatter decides where they go.

## Alpha is the surface class (MeshKit): cc = PAINT, glossy.
const PAINTS := [Color("8a2222cc"), Color("2a4a8acc"), Color("b8b8b0cc"), Color("3a3a3ecc"), Color("6a7a3acc"),
	Color("c8a030cc"), Color("5a2a5acc"), Color("9a9a9ecc"), Color("1e3a3acc")]
const TAXI_WHITE := Color("e2e2dacc")
const BUS_LINE := Color("2a7a4acc")         ## the green of the town's bus line
const GUARDA_BLUE := Color("1a3a7acc")      ## Guarda Municipal
const BARK := Color("4a3a2a4d")        ## BARK
const BARK_DARK := Color("34281c4d")
const LEAF := Color("2a4a2433")        ## LEAF
const LEAF_DARK := Color("1c331833")
const BLOOD := Color("4a0606cc")      ## wet: PAINT
const BLOOD_DARK := Color("2a0303cc")
const BAG_BLACK := Color("18181a")
const BIN_GREEN := Color("2a5a2acc")
const BIN_ORANGE := Color("c86a1acc")
const RUBBISH := [Color("8a7a5a"), Color("c8c8c0"), Color("5a6a7a"), Color("7a3a2a"), Color("3a5a3a")]
const STUFF := [Color("7a2a2a"), Color("2a4a7a"), Color("3a3a3a"), Color("c86a1a"), Color("3a6a4a"),
	Color("7a4a7a"), Color("d8c040"), Color("2a8a9a")]


static func V(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)


static func bx(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, -1.0, rot, t)


## A door hung on its front edge at `hinge` (side -1 left, 1 right), swung open by `open` radians.
static func _door(b: MeshKit.Builder, t: Transform3D, hinge: Vector3, side: float, length: float, height: float,
		open: float, paint: Color, glass: Color) -> void:
	var rot := Basis(Vector3.UP, -side * open)
	var mid := hinge + rot * V(0, 0, length * 0.5)
	bx(b, t, V(0.06, height * 0.55, length), mid + V(0, -height * 0.2, 0), paint, rot)
	bx(b, t, V(0.05, height * 0.4, length * 0.85), mid + V(0, height * 0.27, 0), glass, rot)


# --- Vehicles -------------------------------------------------------------------------

## Small hatchback, 3.9 m. `doors` is how many doors were left open: 0, 1 (driver's) or 2.
## `nose_down` drops the front as if a tyre burst or it ran into a ditch.
static func hatchback(b: MeshKit.Builder, t: Transform3D, paint: Color, doors := 1, nose_down := 0.0) -> Array:
	var tilt := Transform3D(Basis(Vector3.RIGHT, -nose_down), V(0, 0, 0))
	var k := t * tilt
	Props._wheels(b, k, 0.76, [-1.2, 1.15], 0.31, 0.22)
	bx(b, k, V(1.66, 0.55, 3.9), V(0, 0.64, 0), paint)                   # body
	bx(b, k, V(1.52, 0.55, 2.1), V(0, 1.18, 0.45), paint.darkened(0.06)) # cabin, short at the back
	bx(b, k, V(1.42, 0.44, 0.06), V(0, 1.18, -0.62), Props.GLASS, Basis(Vector3.RIGHT, -0.35)) # windscreen
	bx(b, k, V(1.42, 0.44, 0.06), V(0, 1.12, 1.52), Props.GLASS, Basis(Vector3.RIGHT, 0.25))   # hatch
	bx(b, k, V(1.7, 0.18, 0.14), V(0, 0.46, -1.96), Props.DARK)          # bumpers
	bx(b, k, V(1.7, 0.18, 0.14), V(0, 0.46, 1.96), Props.DARK)
	bx(b, k, V(0.3, 0.12, 0.06), V(-0.55, 0.76, -1.97), Props.WHITE)
	bx(b, k, V(0.3, 0.12, 0.06), V(0.55, 0.76, -1.97), Props.WHITE)
	bx(b, k, V(0.26, 0.12, 0.06), V(-0.6, 0.8, 1.97), Props.RED)
	bx(b, k, V(0.26, 0.12, 0.06), V(0.6, 0.8, 1.97), Props.RED)
	for side in [-1.0, 1.0]:
		var open: bool = doors >= 2 or (doors == 1 and side < 0.0)
		if open:
			_door(b, k, V(side * 0.8, 0.95, -0.55), side, 1.15, 1.0, 1.05, paint, Props.GLASS)
			bx(b, k, V(0.04, 0.4, 1.0), V(side * 0.76, 1.18, 0.0), Props.SOOT) # the dark inside
		else:
			bx(b, k, V(0.06, 0.4, 1.9), V(side * 0.77, 1.18, 0.45), Props.GLASS)
	bx(b, k, V(0.5, 0.5, 0.5), V(-0.35, 0.95, 0.05), Props.DARK)         # seats
	bx(b, k, V(0.5, 0.5, 0.5), V(0.35, 0.95, 0.05), Props.DARK)
	return [[V(0, 0.75, 0), V(1.66, 1.5, 3.9), tilt.basis]]


## A taxi: a white saloon with the roof light, both back doors open.
static func taxi(b: MeshKit.Builder, t: Transform3D) -> Array:
	var solid := Props.car(b, t, TAXI_WHITE)
	bx(b, t, V(0.7, 0.2, 0.3), V(0, 1.58, 0.1), Color("d8c040"))         # TAXI light
	bx(b, t, V(0.72, 0.06, 0.32), V(0, 1.47, 0.1), Props.DARK)
	bx(b, t, V(1.82, 0.1, 4.0), V(0, 0.9, 0), Color("c8a030"))           # stripe along the sides
	for side in [-1.0, 1.0]:
		_door(b, t, V(side * 0.92, 0.95, 0.35), side, 1.0, 1.0, 0.9 + side * 0.15, TAXI_WHITE, Props.GLASS)
	return solid


## The bus line's minibus, 7.5 m, front door folded open, a side window smashed.
static func minibus(b: MeshKit.Builder, t: Transform3D) -> Array:
	Props._wheels(b, t, 0.98, [-2.4, 2.2], 0.42, 0.3)
	bx(b, t, V(2.2, 2.3, 7.5), V(0, 1.65, 0), Props.WHITE)
	bx(b, t, V(2.24, 0.45, 7.52), V(0, 1.05, 0), BUS_LINE)               # the line's stripe
	bx(b, t, V(2.24, 0.12, 7.52), V(0, 2.55, 0), BUS_LINE)
	bx(b, t, V(2.0, 0.9, 0.06), V(0, 2.1, -3.76), Props.GLASS)           # windscreen
	bx(b, t, V(1.4, 0.26, 0.06), V(0, 2.68, -3.76), Color("d8882a"))     # destination: MIRANTE
	bx(b, t, V(2.24, 0.25, 0.2), V(0, 0.6, -3.78), Props.DARK)
	bx(b, t, V(0.3, 0.16, 0.06), V(-0.75, 0.95, -3.77), Props.WHITE)
	bx(b, t, V(0.3, 0.16, 0.06), V(0.75, 0.95, -3.77), Props.WHITE)
	for i in 5:
		var z := -2.0 + i * 1.3
		bx(b, t, V(0.06, 0.75, 1.05), V(-1.11, 2.05, z), Props.GLASS if i != 3 else Props.SOOT)
		bx(b, t, V(0.06, 0.75, 1.05), V(1.11, 2.05, z), Props.GLASS)
	bx(b, t, V(1.9, 0.8, 0.06), V(0, 2.1, 3.76), Props.GLASS)            # back window
	bx(b, t, V(2.24, 0.25, 0.2), V(0, 0.6, 3.78), Props.DARK)
	for side in [-1.0, 1.0]:
		bx(b, t, V(0.22, 0.4, 0.06), V(side * 0.85, 1.25, 3.77), Props.RED)
	bx(b, t, V(0.06, 1.9, 0.85), V(1.12, 1.45, -3.0), Props.SOOT)        # door opening
	bx(b, t, V(0.4, 1.8, 0.05), V(1.3, 1.45, -3.35), Props.WHITE, Basis(Vector3.UP, 1.2)) # door leaves, folded
	bx(b, t, V(0.4, 1.8, 0.05), V(1.3, 1.45, -2.65), Props.WHITE, Basis(Vector3.UP, -1.2))
	return [[V(0, 1.4, 0), V(2.2, 2.8, 7.5)]]


## A motorbike, 2 m. `police` paints it as the Guarda Municipal's with a blue light and panniers.
## `fallen` lays it on its left side.
static func motorbike(b: MeshKit.Builder, t: Transform3D, paint: Color, police := false, fallen := false) -> Array:
	var k := t
	if fallen:
		k = t * Transform3D(Basis(Vector3.FORWARD, PI * 0.5 - 0.1), V(-0.32, 0.32, 0))
	else:
		k = t * Transform3D(Basis(Vector3.FORWARD, 0.12), Vector3.ZERO) # on its side stand
	for z in [-0.72, 0.68]:
		b.cyl(0.32, 0.12, V(0, 0.32, z), Props.TYRE, 10, Basis(Vector3.FORWARD, PI * 0.5), k)
		b.cyl(0.18, 0.14, V(0, 0.32, z), Props.STEEL, 6, Basis(Vector3.FORWARD, PI * 0.5), k)
	bx(b, k, V(0.3, 0.35, 0.9), V(0, 0.62, -0.05), Props.STEEL)          # engine and frame
	bx(b, k, V(0.34, 0.26, 0.55), V(0, 0.92, -0.3), paint)               # tank
	bx(b, k, V(0.3, 0.12, 0.7), V(0, 0.9, 0.3), Props.DARK)              # seat
	bx(b, k, V(0.05, 0.05, 0.75), V(0, 0.7, -0.6), Props.STEEL, Basis(Vector3.RIGHT, -0.45)) # forks
	bx(b, k, V(0.7, 0.04, 0.04), V(0, 1.05, -0.78), Props.DARK)          # handlebar
	bx(b, k, V(0.2, 0.16, 0.08), V(0, 0.95, -0.86), Props.WHITE)         # headlight
	bx(b, k, V(0.3, 0.08, 0.5), V(0, 0.68, 0.68), paint)                 # mudguard
	if police:
		bx(b, k, V(0.55, 0.36, 0.08), V(0, 1.2, -0.75), Color("a8b8c0"), Basis(Vector3.RIGHT, -0.3)) # screen
		bx(b, k, V(0.12, 0.1, 0.12), V(0, 1.2, 0.68), Color("2040c0"))   # light on the pole
		bx(b, k, V(0.02, 0.4, 0.02), V(0, 1.0, 0.68), Props.STEEL)
		for side in [-1.0, 1.0]:
			bx(b, k, V(0.18, 0.32, 0.45), V(side * 0.28, 0.65, 0.55), paint) # panniers
			bx(b, k, V(0.19, 0.06, 0.46), V(side * 0.28, 0.72, 0.55), Props.WHITE)
	return [] # small enough to step round; it blocks nothing


## A bicycle, 1.75 m, lying on its side (or `standing` against nothing, on its stand).
static func bicycle(b: MeshKit.Builder, t: Transform3D, paint: Color, standing := false) -> Array:
	var k := t * (Transform3D(Basis(Vector3.FORWARD, 0.15), Vector3.ZERO) if standing \
		else Transform3D(Basis(Vector3.FORWARD, PI * 0.5 - 0.06), V(-0.36, 0.06, 0)))
	for z in [-0.55, 0.55]:
		for i in 8: # a rim of short pieces
			var a := TAU * i / 8.0
			bx(b, k, V(0.03, 0.27, 0.04), V(0, 0.36 + sin(a) * 0.32, z + cos(a) * 0.32), Props.TYRE, Basis(Vector3.RIGHT, -a))
		bx(b, k, V(0.04, 0.04, 0.04), V(0, 0.36, z), Props.STEEL)
	bx(b, k, V(0.04, 0.04, 0.6), V(0, 0.62, -0.05), paint, Basis(Vector3.RIGHT, 0.12))   # top tube
	bx(b, k, V(0.04, 0.04, 0.7), V(0, 0.48, -0.18), paint, Basis(Vector3.RIGHT, -0.75))  # down tube
	bx(b, k, V(0.04, 0.5, 0.04), V(0, 0.58, 0.18), paint, Basis(Vector3.RIGHT, 0.3))     # seat tube
	bx(b, k, V(0.04, 0.04, 0.42), V(0, 0.36, 0.38), paint)                               # chain stay
	bx(b, k, V(0.04, 0.04, 0.5), V(0, 0.5, 0.36), paint, Basis(Vector3.RIGHT, 0.8))      # seat stay
	bx(b, k, V(0.04, 0.45, 0.04), V(0, 0.58, -0.5), Props.STEEL, Basis(Vector3.RIGHT, -0.3)) # fork
	bx(b, k, V(0.5, 0.03, 0.03), V(0, 0.84, -0.42), Props.DARK)          # bar
	bx(b, k, V(0.12, 0.05, 0.25), V(0, 0.86, 0.26), Props.DARK)          # saddle
	return []


## A police car across the road with its doors open and the light bar on.
static func patrol_car(b: MeshKit.Builder, t: Transform3D, glow: MeshKit.Builder) -> Array:
	var solid := Props.car(b, t, GUARDA_BLUE, false, true)
	for side in [-1.0, 1.0]:
		_door(b, t, V(side * 0.92, 0.95, -0.6), side, 1.1, 1.0, 1.2, Props.WHITE, Props.GLASS)
	if glow != null: # one lamp of the bar still lit
		glow.box(V(0.48, 0.1, 0.22), V(-0.3, 1.56, 0.2), Color.WHITE, Basis.IDENTITY, t)
	return solid


# --- Down across the road -----------------------------------------------------------------

## A tree come down across the road, `length` m of trunk lying along -Z from its root plate at
## the origin, the crown spread at the far end. Solid: the trunk (you climb over or go round).
static func fallen_tree(b: MeshKit.Builder, t: Transform3D, length: float, rng: RandomNumberGenerator) -> Array:
	var r := 0.32
	var trunk := Basis(Vector3.RIGHT, PI * 0.5)
	b.cyl(r, length, V(0, r, -length * 0.5), BARK, 8, trunk, t)
	b.cyl(r * 0.7, length * 0.35, V(0.1, r * 1.1, -length * 0.95), BARK_DARK, 6, trunk * Basis(Vector3.FORWARD, 0.2), t)
	# The root plate, torn out of the bank with its earth.
	bx(b, t, V(2.2, 2.0, 0.5), V(0, 0.8, 0.3), Color("3a2c1e"), Basis(Vector3.RIGHT, 0.25))
	for i in 6:
		var a := TAU * i / 6.0
		bx(b, t, V(0.08, 0.08, 1.0), V(cos(a) * 0.7, 0.8 + sin(a) * 0.7, 0.7), BARK_DARK, Basis(Vector3.RIGHT, -0.4))
	# Branches off the upper trunk, and the crown's leaves crushed on the road.
	for i in 7:
		var z := -length * rng.randf_range(0.45, 1.0)
		var side := -1.0 if i % 2 == 0 else 1.0
		var rot := Basis(Vector3.UP, side * rng.randf_range(0.5, 1.1)) * Basis(Vector3.RIGHT, rng.randf_range(-0.6, 0.2))
		bx(b, t, V(0.1, 0.1, rng.randf_range(1.2, 2.6)), V(side * 0.6, r + 0.35, z), BARK, rot)
	for i in 9:
		var s := rng.randf_range(1.0, 2.2)
		bx(b, t, V(s * 1.3, s * 0.6, s), V(rng.randf_range(-2.4, 2.4), s * 0.28, -length * rng.randf_range(0.6, 1.05)),
			LEAF if i % 2 == 0 else LEAF_DARK, Basis(Vector3.UP, rng.randf() * TAU))
	return [[V(0, r, -length * 0.5), V(r * 2.0, r * 2.0, length)]]


## A concrete power pole snapped at the foot, lying along -Z, its cables on the road. The stump
## stands at the origin.
static func snapped_pole(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator) -> Array:
	var top := MiranteSet.POLE_TOP - 1.2
	bx(b, t, V(0.34, 1.2, 0.34), V(0, 0.6, 0), MiranteSet.CONCRETE)
	bx(b, t, V(0.3, 0.2, 0.3), V(0.04, 1.25, 0.02), MiranteSet.CONCRETE_DARK, Basis(Vector3.FORWARD, 0.4)) # broken end
	bx(b, t, V(0.04, 0.5, 0.04), V(0.08, 1.4, 0), Props.RUST, Basis(Vector3.RIGHT, 0.5)) # rebar sticking out
	var lie := Basis(Vector3.RIGHT, -PI * 0.5 + 0.06) # lying, the top end a little down
	bx(b, t, V(0.32, top, 0.32), V(0, 0.4, -0.6 - top * 0.5), MiranteSet.CONCRETE, lie)
	bx(b, t, V(1.8, 0.12, 0.12), V(0, 0.16, -top + 0.2), MiranteSet.CONCRETE_DARK, Basis(Vector3.FORWARD, 1.3)) # crossarm on its end
	b.cyl(0.32, 1.1, V(0.6, 0.32, -top * 0.7), MiranteSet.GALVANISED, 8, Basis(Vector3.FORWARD, PI * 0.5), t) # its transformer
	# The cables: long lazy curves across the road, flat on the ground.
	for w in 3:
		var p := V(-0.4 + w * 0.4, 0.03, -top + 0.3)
		var heading := rng.randf_range(-0.7, 0.7)
		for s in 6:
			heading += rng.randf_range(-0.5, 0.5)
			var dir := V(sin(heading), 0, -cos(heading))
			var q := p + dir * 2.4
			bx(b, t, V(0.06, 0.05, 2.45), (p + q) * 0.5, Props.DARK, Basis.looking_at(dir, Vector3.UP))
			p = q
	return [[V(0, 0.4, -0.6 - top * 0.5), V(0.4, 0.8, top)]]


# --- Street furniture -------------------------------------------------------------------------

## A park bench, 1.8 m along X. `tipped` lays it on its back.
static func bench(b: MeshKit.Builder, t: Transform3D, tipped := false) -> Array:
	var k := t * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), V(0, 0.45, 0.5)) if tipped else t
	for z in [-0.12, 0.05, 0.22]:
		bx(b, k, V(1.8, 0.05, 0.14), V(0, 0.45, z), Props.WOOD)          # seat slats
	for y in [0.7, 0.88]:
		bx(b, k, V(1.8, 0.12, 0.04), V(0, y, 0.33), Props.WOOD, Basis(Vector3.RIGHT, -0.2)) # back
	for x in [-0.75, 0.75]:
		bx(b, k, V(0.06, 0.45, 0.5), V(x, 0.22, 0.05), Props.DARK)       # cast legs
		bx(b, k, V(0.06, 0.5, 0.06), V(x, 0.7, 0.33), Props.DARK, Basis(Vector3.RIGHT, -0.2))
	return [[V(0, 0.45, 0.1), V(1.8, 0.9, 0.6), Basis.IDENTITY]] if not tipped else [[V(0, 0.3, 0.3), V(1.8, 0.6, 1.0)]]


## Benches dragged across `width` metres of road (along X) and stacked: somebody's last stand.
static func bench_barricade(b: MeshKit.Builder, t: Transform3D, width: float, rng: RandomNumberGenerator) -> Array:
	var solid := []
	var n := maxi(2, roundi(width / 1.9))
	for i in n:
		var x := -width * 0.5 + (i + 0.5) * width / n
		var at := t * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.25, 0.25)), V(x, 0, rng.randf_range(-0.3, 0.3)))
		bench(b, at, i % 2 == 1)
		if i % 3 == 0: # one on top, leaning
			bench(b, at * Transform3D(Basis(Vector3.FORWARD, rng.randf_range(-0.3, 0.3)), V(0, 0.55, 0.1)), true)
	solid.append([V(0, 0.5, 0), V(width, 1.0, 0.9)])
	Props.cone(b, t * Transform3D(Basis.IDENTITY, V(-width * 0.5 - 0.6, 0, 0.4)))
	return solid


## The red and white PARE board on its A-frame, knocked over, dragged up the road.
static func pare_board(b: MeshKit.Builder, t: Transform3D, fallen := true) -> Array:
	var k := t * Transform3D(Basis(Vector3.RIGHT, -1.45), V(0, 0.08, 0.6)) if fallen else t
	bx(b, k, V(1.6, 0.4, 0.05), V(0, 0.9, 0), Props.WHITE)
	for i in 4:
		bx(b, k, V(0.2, 0.4, 0.06), V(-0.6 + i * 0.4, 0.9, 0), Props.RED)
	bx(b, k, V(0.55, 0.55, 0.06), V(0, 1.45, 0), Props.RED, Basis(Vector3.FORWARD, PI / 8.0)) # the octagon
	bx(b, k, V(0.34, 0.08, 0.07), V(0, 1.45, 0), Props.WHITE)
	for x in [-0.7, 0.7]:
		bx(b, k, V(0.05, 1.2, 0.05), V(x, 0.6, 0.2), Props.STEEL, Basis(Vector3.RIGHT, 0.3))
		bx(b, k, V(0.05, 1.2, 0.05), V(x, 0.6, -0.2), Props.STEEL, Basis(Vector3.RIGHT, -0.3))
	return []


## A public bin on its post, or the big wheeled kind knocked over with its rubbish out.
static func bin(b: MeshKit.Builder, t: Transform3D, wheelie: bool, rng: RandomNumberGenerator) -> Array:
	if not wheelie:
		bx(b, t, V(0.08, 1.0, 0.08), V(0, 0.5, 0), Props.STEEL)
		b.cyl(0.24, 0.55, V(0, 0.95, -0.25), BIN_ORANGE, 8, Basis.IDENTITY, t)
		bx(b, t, V(0.1, 0.06, 0.3), V(0, 1.0, -0.1), Props.STEEL)
		rubbish(b, t * Transform3D(Basis.IDENTITY, V(0, 0, -0.6)), 4, rng)
		return []
	var lying := t * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5 + 0.05), V(0, 0.36, 0))
	bx(b, lying, V(0.62, 1.0, 0.72), V(0, 0.5, 0), BIN_GREEN)            # bin on its back, mouth to -Z
	bx(b, lying, V(0.66, 0.06, 0.78), V(0, 1.08, 0.3), BIN_GREEN.darkened(0.2), Basis(Vector3.RIGHT, 1.2)) # lid flung open
	bx(b, lying, V(0.7, 0.12, 0.12), V(0, 0.05, 0.4), Props.DARK)        # axle
	rubbish(b, t * Transform3D(Basis.IDENTITY, V(0, 0, -1.4)), 9, rng)
	return [[V(0, 0.36, 0), V(0.72, 0.72, 1.0)]]


## Rubbish spilled over about a metre and a half: black bags, cartons, paper.
static func rubbish(b: MeshKit.Builder, t: Transform3D, count: int, rng: RandomNumberGenerator) -> Array:
	for i in count:
		var p := V(rng.randf_range(-0.8, 0.8), 0, rng.randf_range(-0.8, 0.8))
		var rot := Basis(Vector3.UP, rng.randf() * TAU)
		if i % 3 == 0:
			var s := rng.randf_range(0.35, 0.55)
			bx(b, t, V(s, s * 0.8, s * 1.1), p + V(0, s * 0.35, 0), BAG_BLACK, rot * Basis(Vector3.RIGHT, 0.3))
		else:
			var c: Color = RUBBISH[rng.randi() % RUBBISH.size()]
			bx(b, t, V(rng.randf_range(0.1, 0.3), 0.03, rng.randf_range(0.1, 0.25)), p + V(0, 0.02, 0), c, rot)
	return []


# --- Things people dropped -----------------------------------------------------------------

static func backpack(b: MeshKit.Builder, t: Transform3D, color: Color) -> Array:
	bx(b, t, V(0.34, 0.16, 0.45), V(0, 0.08, 0), color)                  # lying on its back
	bx(b, t, V(0.26, 0.1, 0.18), V(0, 0.19, 0.1), color.darkened(0.2))   # front pocket
	bx(b, t, V(0.05, 0.03, 0.4), V(-0.1, 0.01, -0.05), Props.DARK)       # straps
	bx(b, t, V(0.05, 0.03, 0.4), V(0.1, 0.01, -0.05), Props.DARK)
	return []


static func bottle(b: MeshKit.Builder, t: Transform3D, color := Color("4a8ab0")) -> Array:
	b.cyl(0.04, 0.24, V(0, 0.04, 0), color, 6, Basis(Vector3.RIGHT, PI * 0.5), t)
	bx(b, t, V(0.04, 0.04, 0.04), V(0, 0.04, -0.14), Props.WHITE)        # cap
	return []


static func phone(b: MeshKit.Builder, t: Transform3D, lit := false, glow: MeshKit.Builder = null) -> Array:
	bx(b, t, V(0.075, 0.012, 0.15), V(0, 0.006, 0), Props.DARK)
	if lit and glow != null: # still on, a crack across the screen
		glow.box(V(0.065, 0.004, 0.13), V(0, 0.014, 0), Color.WHITE, Basis.IDENTITY, t)
	return []


static func selfie_stick(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(0.025, 0.025, 0.9), V(0, 0.013, 0), Props.DARK)
	bx(b, t, V(0.04, 0.04, 0.12), V(0, 0.02, 0.48), Props.TYRE)          # grip
	bx(b, t, V(0.09, 0.02, 0.06), V(0, 0.02, -0.47), Props.STEEL)        # empty clamp
	return []


## A pair of flip-flops, not quite together.
static func flip_flops(b: MeshKit.Builder, t: Transform3D, color: Color) -> Array:
	bx(b, t, V(0.1, 0.02, 0.26), V(-0.07, 0.01, 0), color)
	bx(b, t, V(0.1, 0.02, 0.26), V(0.25, 0.01, 0.15), color, Basis(Vector3.UP, 0.9))
	bx(b, t, V(0.02, 0.02, 0.1), V(-0.07, 0.03, -0.04), Props.WHITE)
	return []


## A few dropped things spread over a couple of metres: what a crowd running uphill leaves.
static func litter(b: MeshKit.Builder, t: Transform3D, count: int, rng: RandomNumberGenerator, glow: MeshKit.Builder = null) -> Array:
	for i in count:
		var at := t * Transform3D(Basis(Vector3.UP, rng.randf() * TAU), V(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2)))
		var c: Color = STUFF[rng.randi() % STUFF.size()]
		match rng.randi() % 6:
			0: backpack(b, at, c)
			1: bottle(b, at)
			2: phone(b, at, rng.randf() < 0.3, glow)
			3: flip_flops(b, at, c)
			4: selfie_stick(b, at)
			_: Props.luggage(b, at, 1, rng)
	return []


# --- Blood ---------------------------------------------------------------------------------

## Where a body was dragged: smears getting thinner along -Z, `length` m long. Flat on the ground
## (`ground` gives the height at a local point, so it follows the slope); no solid parts.
static func blood_trail(b: MeshKit.Builder, t: Transform3D, length: float, rng: RandomNumberGenerator, ground: Callable) -> Array:
	var n := maxi(3, roundi(length / 0.7))
	var x := 0.0
	for i in n:
		var f := float(i) / n
		x += rng.randf_range(-0.15, 0.15)
		var local := V(x, 0, -length * f)
		var at := t * local
		at.y = ground.call(at) + 0.04
		var w := lerpf(0.6, 0.18, f) * rng.randf_range(0.7, 1.2)
		var dir := t.basis * V(0, 0, -1)
		b.box(V(w, 0.01, length / n + 0.15), at, BLOOD if i % 2 == 0 else BLOOD_DARK, Basis(Vector3.UP, atan2(-dir.x, -dir.z)))
	var pool := t.origin
	pool.y = ground.call(pool) + 0.035
	b.box(V(1.1, 0.01, 0.9), pool, BLOOD_DARK, Basis(Vector3.UP, rng.randf() * TAU))
	return []
