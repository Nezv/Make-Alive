class_name MiranteSet
## The pieces of Morro da Boa Vista, like Props: each draws into the Builder it is given at
## transform `t` and returns its solid parts as [[center, size, basis?], ...] in its own space.
## Pieces stand on y = 0 and face -Z (a gate faces the way you drive in).
##
## From the photos in references/ (mirante_entrance.jpg, mirante_street.jpg) and what is written
## about the place: the concrete portal with MORRO DA BOA VISTA on it and the white butterfly
## roof, concrete power poles carrying cable bundles up the road, guard rails on the bends, and
## on the summit the 14.5 m reinforced-concrete lookout with flights of stairs round a lift shaft
## up to a 70 m² deck (part of its floor open steel grating), the snack bar, the toilets, the
## guard hut and the radio masts. No photo of the tower itself is in references/ yet: its shape
## here follows the written facts only (see references/mirante_elements.md).

const CONCRETE := Color("a3a29c")
const CONCRETE_DARK := Color("7a7a76")
const PAINT_WHITE := Color("e4e4de")
const SIGN_GREEN := Color("2f6a2c")
const BOOTH_ORANGE := Color("b8562a")
const KERB_YELLOW := Color("e0b41c")
const GALVANISED := Color("9aa0a4")
const GRATING := Color("3a3e42")
const CREAM := Color("d8cdb0")
const AWNING := Color("c0521e")
const PAVERS := Color("6b6a66")      ## grey concrete pavers of the road up
const BRICK := Color("7a3a2a")       ## the red brick walking lane

## The lookout: a square deck TOWER_HALF either side of its centre, TOWER_DECK_Y above its foot.
const TOWER_DECK_Y := 14.5
const TOWER_HALF := 4.6
const CORE_HALF := 1.5               ## the lift shaft in the middle
const FLIGHT_IN := 2.6               ## stairs run round the shaft between these distances from the centre
const FLIGHT_OUT := 4.4
const LANDING := FLIGHT_OUT - FLIGHT_IN ## corner landings are as wide as the flights


static func bx(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> void:
	b.box(size, pos, color, rot, t)


# --- The gate at the foot -------------------------------------------------------------

## The portal over the road (`road` metres wide, centred on x = 0): two concrete pillars, the
## sign across them, the white butterfly roof, the guard hut on the right and the boom.
## Returns colliders; the lettering is the map's (`GATE_SIGN_AT`).
const GATE_SIGN_AT := Vector3(0, 7.7, -0.56)
static func gate(b: MeshKit.Builder, t: Transform3D, road: float) -> Array:
	var x := road * 0.5 + 0.8
	var solid := []
	for side in [-1.0, 1.0]:
		bx(b, t, Vector3(1.1, 8.6, 1.1), Vector3(side * x, 4.3, 0), CONCRETE)
		solid.append([Vector3(side * x, 4.3, 0), Vector3(1.1, 8.6, 1.1)])
	bx(b, t, Vector3(x * 2.0 + 1.6, 1.9, 1.0), Vector3(0, 7.7, 0), CONCRETE)              # the sign
	bx(b, t, Vector3(x * 2.0 + 1.0, 1.5, 0.06), Vector3(0, 7.7, -0.52), CONCRETE.lightened(0.15))
	bx(b, t, Vector3(x * 1.4, 0.08, 0.04), Vector3(0, 7.2, -0.56), SIGN_GREEN)            # rule under the name
	# The butterfly roof: two white slabs rising away from a valley over the road.
	for side in [-1.0, 1.0]:
		var wing := Basis(Vector3.FORWARD, side * 0.16)
		bx(b, t, Vector3(x + 5.0, 0.3, 11.0), Vector3(side * (x + 5.0) * 0.5, 9.0 + (x + 5.0) * 0.08, 1.5), PAINT_WHITE, wing)
		bx(b, t, Vector3(x + 5.0, 0.7, 0.3), Vector3(side * (x + 5.0) * 0.5, 8.75 + (x + 5.0) * 0.08, -4.0), PAINT_WHITE, wing)
	# Guard hut behind the right pillar, the boom across the road raised and left that way.
	var hut := Vector3(x + 2.4, 0, 3.0)
	bx(b, t, Vector3(3.0, 2.8, 3.0), hut + Vector3(0, 1.4, 0), BOOTH_ORANGE)
	bx(b, t, Vector3(2.6, 1.0, 0.06), hut + Vector3(0, 1.7, -1.52), Props.GLASS)
	bx(b, t, Vector3(0.06, 1.0, 2.2), hut + Vector3(-1.52, 1.7, 0), Props.GLASS)
	bx(b, t, Vector3(3.4, 0.2, 3.4), hut + Vector3(0, 2.9, 0), CONCRETE_DARK)
	solid.append([hut + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 3.0)])
	var post := Vector3(x - 1.0, 0, 1.6)
	bx(b, t, Vector3(0.4, 1.1, 0.4), post + Vector3(0, 0.55, 0), Props.RED)
	var up := Basis(Vector3.FORWARD, -1.25)
	for i in 6: # red and white stripes
		var along := up * Vector3(-0.6 - i * 0.6, 0, 0)
		bx(b, t, Vector3(0.6, 0.12, 0.12), post + Vector3(0, 1.05, 0) + along, Props.RED if i % 2 == 0 else PAINT_WHITE, up)
	# Yellow kerbs both sides, the PARE board and cones on the walking side.
	for side in [-1.0, 1.0]:
		bx(b, t, Vector3(0.3, 0.22, 22.0), Vector3(side * (road * 0.5 + 0.15), 0.11, 2.0), KERB_YELLOW)
	var board := Vector3(road * 0.5 - 1.6, 0, -3.5)
	bx(b, t, Vector3(1.6, 0.9, 0.06), board + Vector3(0, 0.75, 0), PAINT_WHITE)
	for i in 3:
		bx(b, t, Vector3(0.3, 0.9, 0.07), board + Vector3(-0.55 + i * 0.55, 0.75, 0), Props.RED, Basis(Vector3.FORWARD, 0.5))
	bx(b, t, Vector3(0.7, 0.7, 0.08), board + Vector3(0, 1.6, 0), Props.RED, Basis(Vector3.FORWARD, PI / 8.0)) # PARE
	for k in 2:
		Props.cone(b, t * Transform3D(Basis.IDENTITY, board + Vector3(0.9 + k * 0.6, 0, 0.4)))
	return solid


# --- Along the road -------------------------------------------------------------------

## A concrete power pole: tapered shaft, a crossarm with insulators, a transformer on some, and a
## street lamp arm over the road (-Z) on others. The lamp head is at `LAMP_HEAD`.
const POLE_TOP := 9.6
const LAMP_HEAD := Vector3(0, 7.9, -2.1)
static func power_pole(b: MeshKit.Builder, t: Transform3D, lamp: bool, transformer: bool) -> Array:
	bx(b, t, Vector3(0.34, 6.0, 0.34), Vector3(0, 3.0, 0), CONCRETE)
	bx(b, t, Vector3(0.26, POLE_TOP - 6.0, 0.26), Vector3(0, 6.0 + (POLE_TOP - 6.0) * 0.5, 0), CONCRETE)
	bx(b, t, Vector3(1.8, 0.12, 0.12), Vector3(0, POLE_TOP - 0.4, 0), CONCRETE_DARK)
	for x in [-0.8, 0.0, 0.8]:
		bx(b, t, Vector3(0.08, 0.2, 0.08), Vector3(x, POLE_TOP - 0.24, 0), PAINT_WHITE)
	for y in [7.0, 6.6]: # the thick bundles of phone and cable lines lower down
		bx(b, t, Vector3(0.5, 0.14, 0.14), Vector3(0, y, 0.1), Props.DARK)
	if transformer:
		b.cyl(0.32, 1.1, Vector3(0, 6.2, 0.45), GALVANISED, 8, Basis.IDENTITY, t)
	if lamp:
		bx(b, t, Vector3(0.08, 0.08, 2.0), Vector3(0, 7.95, -1.05), GALVANISED, Basis(Vector3.RIGHT, -0.12))
		bx(b, t, Vector3(0.3, 0.14, 0.6), LAMP_HEAD + Vector3(0, 0.08, 0), Props.STEEL)
	return [[Vector3(0, POLE_TOP * 0.5, 0), Vector3(0.34, POLE_TOP, 0.34)]]


## The points a pole's wires hang from, in its own space.
static func wire_points() -> Array:
	return [Vector3(-0.8, POLE_TOP - 0.18, 0), Vector3(0, POLE_TOP - 0.18, 0), Vector3(0.8, POLE_TOP - 0.18, 0), Vector3(0, 6.8, 0.1)]


## One length of galvanised guard rail along -Z: posts every two metres, the W-beam on top.
static func guard_rail(b: MeshKit.Builder, t: Transform3D, length: float) -> Array:
	var n := maxi(1, roundi(length / 2.0))
	for i in n + 1:
		bx(b, t, Vector3(0.12, 0.8, 0.12), Vector3(0, 0.4, -length * float(i) / n), Props.STEEL)
	bx(b, t, Vector3(0.06, 0.32, length + 0.2), Vector3(0.08, 0.65, -length * 0.5), GALVANISED)
	return [[Vector3(0, 0.45, -length * 0.5), Vector3(0.25, 0.9, length)]]


# --- The summit -------------------------------------------------------------------------

## The lookout tower. A square lift shaft in the middle; four flights of stairs climb round it,
## one along each side, from corner landing to corner landing (south-west, south-east,
## north-east, north-west, then up through the deck at the south-west); the deck on top with a
## railing all round and its east third open steel grating. The flights are ramps underfoot
## (the steps are drawn on them). Returns colliders, including the ramps (with their basis).
static func tower(b: MeshKit.Builder, t: Transform3D) -> Array:
	var solid := []
	var h := TOWER_DECK_Y
	var rise := h / 4.0
	var c := (FLIGHT_IN + FLIGHT_OUT) * 0.5       # the middle of the stair band
	var width := FLIGHT_OUT - FLIGHT_IN
	# Lift shaft, footed a metre into the slope, with its doors at the bottom on the north side.
	bx(b, t, Vector3(CORE_HALF * 2.0, h + 1.0, CORE_HALF * 2.0), Vector3(0, (h - 1.0) * 0.5, 0), CONCRETE)
	bx(b, t, Vector3(1.2, 2.2, 0.06), Vector3(0, 1.1, -CORE_HALF - 0.03), Props.STEEL)
	solid.append([Vector3(0, (h - 1.0) * 0.5, 0), Vector3(CORE_HALF * 2.0, h + 1.0, CORE_HALF * 2.0)])
	# Corner columns, footed into the slope too.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var at := Vector3(sx * (TOWER_HALF - 0.25), (h - 1.0) * 0.5, sz * (TOWER_HALF - 0.25))
			bx(b, t, Vector3(0.5, h + 1.0, 0.5), at, CONCRETE_DARK)
			solid.append([at, Vector3(0.5, h + 1.0, 0.5)])
	# Corners in climbing order and the landing at each (the first is on the ground).
	var corners := [Vector2(-c, c), Vector2(c, c), Vector2(c, -c), Vector2(-c, -c), Vector2(-c, c)]
	for i in 4:
		var y := rise * i
		var a: Vector2 = corners[i]
		var z: Vector2 = corners[i + 1]
		if i > 0:
			var land := Vector3(a.x, y - 0.15, a.y)
			bx(b, t, Vector3(LANDING, 0.3, LANDING), land, CONCRETE)
			solid.append([land, Vector3(LANDING, 0.3, LANDING)])
		# The flight from the edge of this landing to the edge of the next, rising `rise`.
		var dir := (z - a).normalized()
		var from := a + dir * LANDING * 0.5
		var to := z - dir * LANDING * 0.5
		var run := from.distance_to(to)
		var p0 := Vector3(from.x, y, from.y)
		var p1 := Vector3(to.x, y + rise, to.y)
		var basis := Basis.looking_at((p1 - p0).normalized(), Vector3.UP)
		var length := p0.distance_to(p1)
		var mid := (p0 + p1) * 0.5 + basis * Vector3(0, -0.12, 0)
		bx(b, t, Vector3(width, 0.24, length + 0.1), mid, CONCRETE, basis)
		solid.append([mid, Vector3(width, 0.24, length + 0.1), basis])
		var steps := ceili(rise / 0.18)
		for k in steps:
			var f := (k + 0.5) / steps
			var tread := Vector3(from.x, 0, from.y).lerp(Vector3(to.x, 0, to.y), f) + Vector3(0, y + rise * f + 0.02, 0)
			bx(b, t, Vector3(width - 0.1, 0.05, run / steps * 0.35), tread, CONCRETE_DARK, Basis.looking_at(Vector3(dir.x, 0, dir.y), Vector3.UP))
		# Rails on both sides of the flight.
		var side := Vector3(-dir.y, 0, dir.x)
		for s: float in [1.0, -1.0]:
			var rail := (p0 + p1) * 0.5 + side * s * (width * 0.5 - 0.05) + Vector3(0, 1.0, 0)
			bx(b, t, Vector3(0.06, 0.06, length), rail, GALVANISED, basis)
			solid.append([rail + Vector3(0, -0.45, 0), Vector3(0.1, 1.0, length), basis])
	# The deck: concrete over the shaft and the west, steel grating to the east, a hole above
	# the last flight (west side) where the stairs come up.
	var hole_lo := -c + LANDING * 0.5
	var hole_hi := c - LANDING * 0.5
	var slab := 0.3
	var deck := []
	deck.append([Vector3((-FLIGHT_IN + 1.4) * 0.5, h - slab * 0.5, 0), Vector3(FLIGHT_IN + 1.4, slab, TOWER_HALF * 2.0), CONCRETE])     # x -2.6 .. 1.4
	deck.append([Vector3((1.4 + TOWER_HALF) * 0.5, h - slab * 0.5, 0), Vector3(TOWER_HALF - 1.4, slab, TOWER_HALF * 2.0), GRATING])   # x 1.4 .. 4.2
	for sz in [-1.0, 1.0]: # the west strip either side of the hole
		var z0 := hole_hi if sz > 0 else -TOWER_HALF
		var z1 := TOWER_HALF if sz > 0 else hole_lo
		deck.append([Vector3((-TOWER_HALF - FLIGHT_IN) * 0.5, h - slab * 0.5, (z0 + z1) * 0.5), Vector3(TOWER_HALF - FLIGHT_IN, slab, z1 - z0), CONCRETE])
	for d: Array in deck:
		bx(b, t, d[1], d[0], d[2])
		solid.append([d[0], d[1]])
	for k in 8: # the grating's bars
		bx(b, t, Vector3(0.04, 0.04, TOWER_HALF * 2.0), Vector3(1.6 + k * 0.4, h + 0.02, 0), GALVANISED)
	# Railing round the deck, and round the hole except where the stairs arrive (south end).
	for side: Array in [[Vector3(0, 0, -TOWER_HALF), Vector3(TOWER_HALF * 2.0, 0, 0.08)], [Vector3(0, 0, TOWER_HALF), Vector3(TOWER_HALF * 2.0, 0, 0.08)],
			[Vector3(-TOWER_HALF, 0, 0), Vector3(0.08, 0, TOWER_HALF * 2.0)], [Vector3(TOWER_HALF, 0, 0), Vector3(0.08, 0, TOWER_HALF * 2.0)],
			[Vector3(-FLIGHT_IN, 0, (hole_lo + hole_hi) * 0.5), Vector3(0.08, 0, hole_hi - hole_lo)],
			[Vector3((-TOWER_HALF - FLIGHT_IN) * 0.5, 0, hole_lo), Vector3(TOWER_HALF - FLIGHT_IN, 0, 0.08)]]:
		var at: Vector3 = side[0]
		var size: Vector3 = side[1]
		bx(b, t, size + Vector3(0, 0.08, 0), at + Vector3(0, h + 1.1, 0), GALVANISED)
		bx(b, t, size + Vector3(0, 0.04, 0), at + Vector3(0, h + 0.55, 0), GALVANISED)
		solid.append([at + Vector3(0, h + 0.55, 0), size + Vector3(0.1, 1.1, 0.1)])
	# Posts of the railing, the shaft's roof and the two coin binoculars facing the city and the bay.
	for k in 9:
		var f := -TOWER_HALF + k * TOWER_HALF * 0.25
		for p: Vector3 in [Vector3(f, 0, -TOWER_HALF), Vector3(f, 0, TOWER_HALF), Vector3(TOWER_HALF, 0, f)]:
			bx(b, t, Vector3(0.06, 1.1, 0.06), p + Vector3(0, h + 0.55, 0), GALVANISED)
	bx(b, t, Vector3(CORE_HALF * 2.0 + 0.2, 2.4, CORE_HALF * 2.0 + 0.2), Vector3(0, h + 1.2, 0), CONCRETE)  # lift head
	solid.append([Vector3(0, h + 1.2, 0), Vector3(CORE_HALF * 2.0 + 0.2, 2.4, CORE_HALF * 2.0 + 0.2)])
	for at: Vector3 in [Vector3(3.4, 0, -3.4), Vector3(-1.6, 0, 3.4)]:
		bx(b, t, Vector3(0.12, 1.1, 0.12), at + Vector3(0, h + 0.55, 0), Props.STEEL)
		bx(b, t, Vector3(0.36, 0.3, 0.5), at + Vector3(0, h + 1.25, 0), Color("2a5a9a"))
	return solid


## Snack bar: a cream box with its roll-up shutter half down under an orange awning.
static func snack_bar(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, Vector3(6.0, 3.0, 4.0), Vector3(0, 1.5, 0), CREAM)
	bx(b, t, Vector3(4.4, 1.0, 0.06), Vector3(0, 1.9, -2.03), Props.STEEL)       # shutter half down
	bx(b, t, Vector3(4.4, 0.9, 0.06), Vector3(0, 1.0, -2.03), Props.SOOT)        # dark below it
	bx(b, t, Vector3(4.6, 0.12, 0.7), Vector3(0, 1.05, -2.3), CONCRETE_DARK)     # counter
	bx(b, t, Vector3(6.4, 0.1, 1.8), Vector3(0, 2.85, -2.7), AWNING, Basis(Vector3.RIGHT, -0.2))
	bx(b, t, Vector3(6.3, 0.25, 4.3), Vector3(0, 3.1, 0), CONCRETE_DARK)
	return [[Vector3(0, 1.5, 0), Vector3(6.0, 3.0, 4.0)]]


## Toilet block: two doors, small high windows.
static func toilets(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, Vector3(7.0, 3.0, 4.0), Vector3(0, 1.5, 0), CREAM.darkened(0.1))
	for x in [-1.8, 1.8]:
		bx(b, t, Vector3(1.0, 2.1, 0.06), Vector3(x, 1.05, -2.03), Color("355a7a"))
		bx(b, t, Vector3(1.6, 0.4, 0.06), Vector3(x, 2.6, -2.03), Props.GLASS)
	bx(b, t, Vector3(7.4, 0.25, 4.4), Vector3(0, 3.1, 0), CONCRETE_DARK)
	return [[Vector3(0, 1.5, 0), Vector3(7.0, 3.0, 4.0)]]


## Radio mast: three legs of lattice narrowing to the top, cross bracing, dishes, a red light
## on top (the map lights it). Returns colliders; the light is at `mast_top(height)`.
static func radio_mast(b: MeshKit.Builder, t: Transform3D, height: float) -> Array:
	var foot := 1.4
	var legs := []
	for i in 3:
		var a := TAU * i / 3.0
		legs.append(Vector3(cos(a), 0, sin(a)))
	for i in 3:
		var bottom: Vector3 = legs[i] * foot
		var top: Vector3 = legs[i] * 0.25 + Vector3(0, height, 0)
		bx(b, t, Vector3(0.1, 0.1, bottom.distance_to(top)), (bottom + top) * 0.5, Props.RED.darkened(0.1) if i == 0 else PAINT_WHITE,
			Basis.looking_at((top - bottom).normalized(), Vector3.FORWARD if absf((top - bottom).normalized().y) > 0.99 else Vector3.UP))
	for k in range(1, int(height / 3.0)):
		var y := k * 3.0
		var r := lerpf(foot, 0.25, y / height)
		for i in 3:
			var p: Vector3 = legs[i] * r + Vector3(0, y, 0)
			var q: Vector3 = legs[(i + 1) % 3] * r + Vector3(0, y, 0)
			bx(b, t, Vector3(0.05, 0.05, p.distance_to(q)), (p + q) * 0.5, PAINT_WHITE if k % 2 == 0 else Props.RED, Basis.looking_at((q - p).normalized(), Vector3.UP))
	b.cyl(0.6, 0.2, Vector3(0.5, height * 0.7, 0), GALVANISED, 8, Basis(Vector3.FORWARD, PI * 0.5), t)
	b.cyl(0.45, 0.2, Vector3(-0.3, height * 0.55, 0.4), GALVANISED, 8, Basis(Vector3.RIGHT, PI * 0.5), t)
	bx(b, t, Vector3(0.3, 0.3, 0.3), mast_top(height), Props.RED)
	return [[Vector3(0, 1.5, 0), Vector3(foot * 1.6, 3.0, foot * 1.6)]]


static func mast_top(height: float) -> Vector3:
	return Vector3(0, height + 0.2, 0)
