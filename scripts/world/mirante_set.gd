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
const CONCRETE_LIGHT := Color("bdbbb3")
## Alpha is the surface class (MeshKit): cc PAINT, 99 METAL, b3 BRICK, e6 PAVERS, 80 TILE, 66 GLASS.
const PAINT_WHITE := Color("e4e4decc")
const SIGN_GREEN := Color("2f6a2c")     ## the gate's lettering (a Label3D colour: keep alpha 1)
const BOOTH_ORANGE := Color("c0602ecc")
const ROOF_BROWN := Color("5a3a26cc")
const KERB_YELLOW := Color("e0b41ccc")
const GALVANISED := Color("9aa0a499")
const GRATING := Color("3a3e4299")
const CREAM := Color("ddd2b4")
const AWNING := Color("c0521e")
const AWNING_LIGHT := Color("ecdfc4")
const TILE_BLUE := Color("5f8fa880")
const TILE_WHITE := Color("d9dcd680")
const TERRACOTTA := Color("a8583a")
const PORCELAIN := Color("cfd2cccc")
const CHALK := Color("23362bcc")
const PLASTIC_RED := Color("b8262acc")
const PAVERS := Color("6b6a66e6")      ## grey concrete pavers of the road up (PAVERS: a weave)
const BRICK := Color("7a3a2ab3")       ## the red brick walking lane (BRICK: running bond)

## The lookout: a square deck TOWER_HALF either side of its centre, TOWER_DECK_Y above its foot.
const TOWER_DECK_Y := 14.5
const TOWER_HALF := 4.6
const CORE_HALF := 1.5               ## the lift shaft in the middle
const FLIGHT_IN := 2.6               ## stairs run round the shaft between these distances from the centre
const FLIGHT_OUT := 4.4
const LANDING := FLIGHT_OUT - FLIGHT_IN ## corner landings are as wide as the flights


static func bx(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, -1.0, rot, t)


## A bevelled box with its own bevel radius `r`.
static func rb(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, r: float, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, r, rot, t)


## `t` moved to `at` and turned `yaw` radians: a local frame for a detail that faces -Z.
static func at(t: Transform3D, p: Vector3, yaw := 0.0) -> Transform3D:
	return t * Transform3D(Basis(Vector3.UP, yaw), p)


# --- Shared details: the layer that makes a box a building -----------------------------

## A window facing -Z at the origin of `f`: dark glass set back, a frame round it, a mullion
## down the middle when it is wide, and a sill that sticks out under it.
static func window(b: MeshKit.Builder, f: Transform3D, w: float, h: float, frame := PAINT_WHITE) -> void:
	var k := 0.07
	bx(b, f, Vector3(w, h, 0.04), Vector3(0, 0, 0.01), Props.GLASS)
	rb(b, f, Vector3(w + k * 2.0, k, 0.1), Vector3(0, h * 0.5 + k * 0.5, -0.02), frame, 0.015)
	rb(b, f, Vector3(w + k * 2.0, k, 0.1), Vector3(0, -h * 0.5 - k * 0.5, -0.02), frame, 0.015)
	for sx in [-1.0, 1.0]:
		rb(b, f, Vector3(k, h, 0.1), Vector3(sx * (w * 0.5 + k * 0.5), 0, -0.02), frame, 0.015)
	if w > 1.1:
		rb(b, f, Vector3(k * 0.6, h, 0.06), Vector3(0, 0, -0.01), frame, 0.01)
	rb(b, f, Vector3(w + 0.3, 0.07, 0.22), Vector3(0, -h * 0.5 - k - 0.03, -0.08), CONCRETE_LIGHT, 0.02)


## A door facing -Z, its foot at the origin of `f`: frame, leaf with two panels, a handle.
static func door(b: MeshKit.Builder, f: Transform3D, w: float, h: float, leaf: Color, frame := PAINT_WHITE) -> void:
	bx(b, f, Vector3(w, h, 0.06), Vector3(0, h * 0.5, 0), leaf)
	for y in [h * 0.3, h * 0.72]:
		rb(b, f, Vector3(w * 0.7, h * 0.3, 0.03), Vector3(0, y, -0.04), leaf.lightened(0.08), 0.012)
	rb(b, f, Vector3(w + 0.16, 0.08, 0.12), Vector3(0, h + 0.04, -0.02), frame, 0.015)
	for sx in [-1.0, 1.0]:
		rb(b, f, Vector3(0.08, h, 0.12), Vector3(sx * (w * 0.5 + 0.04), h * 0.5, -0.02), frame, 0.015)
	b.rcyl(0.025, 0.12, Vector3(w * 0.36, h * 0.48, -0.08), GALVANISED, 8, 0.008, Basis(Vector3.RIGHT, PI * 0.5), f)


## A wall-mounted air conditioner facing -Z: casing, a grille of slats, the round fan behind.
static func ac_unit(b: MeshKit.Builder, f: Transform3D) -> void:
	rb(b, f, Vector3(0.8, 0.55, 0.32), Vector3(0, 0, 0), PAINT_WHITE, 0.04)
	b.rcyl(0.19, 0.03, Vector3(0.12, 0, -0.16), Props.DARK, 14, 0.01, Basis(Vector3.RIGHT, PI * 0.5), f)
	for k in 4:
		rb(b, f, Vector3(0.42, 0.018, 0.02), Vector3(0.12, -0.15 + k * 0.1, -0.175), PAINT_WHITE.darkened(0.1), 0.004)
	for sx in [-0.28, 0.28]:
		rb(b, f, Vector3(0.05, 0.05, 0.3), Vector3(sx, -0.3, 0.12), GALVANISED, 0.01)   # brackets


## A downpipe from `top` to `foot` (both in the frame of `t`), with a shoe at the bottom.
static func downpipe(b: MeshKit.Builder, t: Transform3D, top: Vector3, foot: Vector3, color := CONCRETE_LIGHT) -> void:
	b.tube(PackedVector3Array([top, foot + Vector3(0, 0.25, 0), foot + Vector3(0, 0.08, -0.2)]), 0.055, color, 8, -1.0, t)
	var n := int(top.distance_to(foot) / 1.2)
	for i in n:
		var p := foot.lerp(top, (i + 0.5) / n)
		b.rcyl(0.07, 0.05, p, color.darkened(0.1), 8, 0.01, Basis.IDENTITY, t)


## A turned plant pot with a bush in it, its foot at `p`.
static func potted(b: MeshKit.Builder, t: Transform3D, p: Vector3, size: float, flower: Color, key: int) -> void:
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(size * 0.32, 0), Vector2(size * 0.36, size * 0.06),
		Vector2(size * 0.44, size * 0.55), Vector2(size * 0.5, size * 0.6), Vector2(size * 0.5, size * 0.68),
		Vector2(size * 0.42, size * 0.66)]), p, TERRACOTTA, 12, Basis.IDENTITY, t)
	Vegetation.shrub(b, t, p + Vector3(0, size * 0.6, 0), size * 0.9, flower, key)


## A long planter box at `p` (its foot), `l` metres along X, filled with shrubs.
static func planter(b: MeshKit.Builder, t: Transform3D, p: Vector3, l: float, flower: Color, key: int) -> void:
	rb(b, t, Vector3(l, 0.55, 0.8), p + Vector3(0, 0.275, 0), CONCRETE_LIGHT, 0.05)
	rb(b, t, Vector3(l - 0.16, 0.06, 0.64), p + Vector3(0, 0.53, 0), Color("3a2a1e"), 0.01)  # soil
	var n := maxi(1, int(l / 0.9))
	for i in n:
		var x := -l * 0.5 + (i + 0.5) * l / n
		Vegetation.shrub(b, t, p + Vector3(x, 0.5, 0), 0.85, flower, key * 31 + i)


# --- The gate at the foot -------------------------------------------------------------

## The portal over the road (`road` metres wide, centred on x = 0): two concrete pillars, the
## sign across them, the white butterfly roof, the guard hut on the right and the boom.
## Returns colliders; the lettering is the map's (`GATE_SIGN_AT`).
const GATE_SIGN_AT := Vector3(0, 7.7, -0.56)
static func gate(b: MeshKit.Builder, t: Transform3D, road: float) -> Array:
	var x := road * 0.5 + 0.8
	var solid := []
	for side in [-1.0, 1.0]:
		var px: float = side * x
		rb(b, t, Vector3(1.5, 0.45, 1.5), Vector3(px, 0.225, 0), CONCRETE_DARK, 0.06)          # plinth
		rb(b, t, Vector3(1.3, 0.12, 1.3), Vector3(px, 0.5, 0), CONCRETE_LIGHT, 0.03)
		rb(b, t, Vector3(1.1, 8.1, 1.1), Vector3(px, 4.55, 0), CONCRETE, 0.06)                 # shaft
		for fz in [-1.0, 1.0]: # two shadow grooves down each face (a strip, darker, slightly proud)
			for gx in [-0.24, 0.24]:
				rb(b, t, Vector3(0.06, 5.6, 0.03), Vector3(px + gx, 3.6, fz * 0.555), CONCRETE_DARK, 0.01)
		for y in [1.2, 6.6]: # banding
			rb(b, t, Vector3(1.18, 0.1, 1.18), Vector3(px, y, 0), CONCRETE_LIGHT, 0.02)
		solid.append([Vector3(px, 4.3, 0), Vector3(1.1, 8.6, 1.1)])
		# Planters at the outer foot of each pillar, red hibiscus one side, pink the other.
		planter(b, t, Vector3(px + side * 1.55, 0, -0.9), 1.6, Vegetation.HIBISCUS_RED if side < 0.0 else Vegetation.BOUGAINVILLEA_PINK, 7 + int(side))
	# The sign: a beam with cornices top and bottom, a lighter panel for the letters, a green rule.
	var w := x * 2.0 + 1.6
	rb(b, t, Vector3(w, 1.9, 1.0), Vector3(0, 7.7, 0), CONCRETE, 0.06)
	rb(b, t, Vector3(w + 0.25, 0.2, 1.25), Vector3(0, 8.72, 0), CONCRETE_LIGHT, 0.05)
	rb(b, t, Vector3(w + 0.12, 0.14, 1.12), Vector3(0, 6.72, 0), CONCRETE_LIGHT, 0.04)
	rb(b, t, Vector3(x * 2.0 + 1.0, 1.5, 0.06), Vector3(0, 7.7, -0.52), CONCRETE_LIGHT.lightened(0.12), 0.02)
	for y in [6.98, 8.42]: # thin green lines framing the lettering
		rb(b, t, Vector3(x * 2.0 + 0.8, 0.04, 0.03), Vector3(0, y, -0.555), surf(SIGN_GREEN, MeshKit.PAINT), 0.008)
	bx(b, t, Vector3(x * 1.4, 0.08, 0.04), Vector3(0, 7.2, -0.56), surf(SIGN_GREEN, MeshKit.PAINT))
	# The butterfly roof: two white slabs rising away from a valley over the road, a fascia band
	# round their edges, a grey soffit under them, lamps let into it, a gutter down the valley.
	for side in [-1.0, 1.0]:
		var span := x + 5.0
		var wing := Basis(Vector3.FORWARD, side * 0.16)
		var mid := Vector3(side * span * 0.5, 9.0 + span * 0.08, 1.5)
		var f := Transform3D(wing, mid)
		rb(b, t * f, Vector3(span, 0.3, 11.0), Vector3.ZERO, PAINT_WHITE, 0.08)
		rb(b, t * f, Vector3(span - 0.3, 0.06, 10.7), Vector3(0, -0.17, 0), CONCRETE_LIGHT.darkened(0.08), 0.02)  # soffit
		rb(b, t * f, Vector3(span + 0.1, 0.42, 0.16), Vector3(0, -0.04, -5.5), PAINT_WHITE.darkened(0.06), 0.04)   # fascia front
		rb(b, t * f, Vector3(span + 0.1, 0.42, 0.16), Vector3(0, -0.04, 5.5), PAINT_WHITE.darkened(0.06), 0.04)    # and back
		rb(b, t * f, Vector3(0.16, 0.42, 11.2), Vector3(side * span * 0.5, -0.04, 0), PAINT_WHITE.darkened(0.06), 0.04)
		rb(b, t * f, Vector3(x + 5.0, 0.7, 0.3), Vector3(0, -0.25, -5.5), PAINT_WHITE, 0.06)
		for k in 3: # downlights
			b.rcyl(0.13, 0.05, Vector3(0, -0.21, -3.0 + k * 3.0), GALVANISED, 10, 0.015, Basis.IDENTITY, t * f)
	b.tube(PackedVector3Array([Vector3(0, 9.2, -4.0), Vector3(0, 9.2, 6.9)]), 0.11, CONCRETE_LIGHT, 8, -1.0, t)   # valley gutter
	downpipe(b, t, Vector3(x - 0.62, 8.6, 0.62), Vector3(x - 0.62, 0.45, 0.62))
	# The guard hut behind the right pillar: plinth, orange walls, windows with white frames
	# all round the front and the road side, a brown roof band, a door at the back, an air
	# conditioner, a lamp, a pot by the door.
	var hut := Vector3(x + 2.4, 0, 3.0)
	var h := at(t, hut)
	rb(b, h, Vector3(3.3, 0.3, 3.3), Vector3(0, 0.15, 0), CONCRETE_DARK, 0.05)
	rb(b, h, Vector3(3.0, 2.5, 3.0), Vector3(0, 1.55, 0), BOOTH_ORANGE, 0.06)
	rb(b, h, Vector3(3.08, 0.5, 3.08), Vector3(0, 0.55, 0), BOOTH_ORANGE.darkened(0.18), 0.04)   # skirting
	window(b, at(h, Vector3(0, 1.75, -1.52)), 2.3, 0.95)
	window(b, at(h, Vector3(-1.52, 1.75, 0), PI * 0.5), 2.2, 0.95)
	window(b, at(h, Vector3(1.52, 1.85, -0.5), -PI * 0.5), 0.9, 0.7)
	door(b, at(h, Vector3(0.4, 0.3, 1.52), PI), 0.85, 2.0, Color("5a3a26cc"))
	rb(b, h, Vector3(3.5, 0.36, 3.5), Vector3(0, 2.98, 0), ROOF_BROWN, 0.05)   # roof band
	rb(b, h, Vector3(3.3, 0.14, 3.3), Vector3(0, 3.22, 0), CONCRETE_DARK, 0.04)
	ac_unit(b, at(h, Vector3(1.68, 2.35, 0.7), -PI * 0.5))
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.12, 0), Vector2(0.14, 0.06), Vector2(0.08, 0.16), Vector2(0, 0.17)]),
		Vector3(0.4, 2.56, 1.62), GALVANISED, 10, Basis(Vector3.RIGHT, PI), h)       # lamp over the door
	potted(b, h, Vector3(-0.6, 0.3, 1.95), 0.7, Vegetation.HIBISCUS_RED, 3)
	solid.append([hut + Vector3(0, 1.4, 0), Vector3(3.0, 2.8, 3.0)])
	# The boom: a post with a motor housing, the arm raised in red and white, a counterweight.
	var post := Vector3(x - 1.0, 0, 1.6)
	rb(b, t, Vector3(0.5, 1.0, 0.45), post + Vector3(0, 0.5, 0), surf(Props.RED, MeshKit.PAINT), 0.05)
	rb(b, t, Vector3(0.56, 0.08, 0.5), post + Vector3(0, 1.04, 0), PAINT_WHITE, 0.03)
	var up := Basis(Vector3.FORWARD, -1.25)
	var pivot := post + Vector3(0, 1.0, 0)
	b.rcyl(0.1, 0.12, pivot, GALVANISED, 10, 0.02, Basis(Vector3.RIGHT, PI * 0.5), t)
	for i in 7: # red and white stripes
		var along := up * Vector3(-0.3 - i * 0.6, 0, 0)
		b.rcyl(0.06, 0.6, pivot + along, Props.RED if i % 2 == 0 else PAINT_WHITE, 8, 0.01, up * Basis(Vector3.FORWARD, PI * 0.5), t)
	rb(b, t, Vector3(0.3, 0.3, 0.2), pivot + up * Vector3(0.45, 0, 0), CONCRETE_DARK, 0.04)
	# Yellow kerbs both sides, the PARE board and cones on the walking side.
	for side in [-1.0, 1.0]:
		rb(b, t, Vector3(0.3, 0.22, 22.0), Vector3(side * (road * 0.5 + 0.15), 0.11, 2.0), KERB_YELLOW, 0.05)
	var board := Vector3(road * 0.5 - 1.6, 0, -3.5)
	for lx in [-0.7, 0.7]: # A-frame legs
		b.tube(PackedVector3Array([board + Vector3(lx, 0, 0.35), board + Vector3(lx, 1.25, 0)]), 0.03, GALVANISED, 6, -1.0, t)
		b.tube(PackedVector3Array([board + Vector3(lx, 0, -0.35), board + Vector3(lx, 1.25, 0)]), 0.03, GALVANISED, 6, -1.0, t)
	rb(b, t, Vector3(1.6, 0.9, 0.06), board + Vector3(0, 0.75, -0.03), PAINT_WHITE, 0.02)
	for i in 3:
		rb(b, t, Vector3(0.3, 0.9, 0.07), board + Vector3(-0.55 + i * 0.55, 0.75, -0.03), Props.RED, 0.01, Basis(Vector3.FORWARD, 0.5))
	var octa := Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI / 8.0)
	b.rcyl(0.4, 0.05, board + Vector3(0, 1.6, -0.02), PAINT_WHITE, 8, 0.01, octa, t)       # PARE
	b.rcyl(0.36, 0.06, board + Vector3(0, 1.6, -0.03), Props.RED, 8, 0.01, octa, t)
	for k in 2:
		Props.cone(b, t * Transform3D(Basis.IDENTITY, board + Vector3(0.9 + k * 0.6, 0, 0.4)))
	return solid


static func surf(c: Color, kind: float) -> Color:
	return MeshKit.surf(c, kind)


# --- Along the road -------------------------------------------------------------------

## A concrete power pole: tapered shaft, a crossarm with insulators, a transformer on some, and a
## street lamp arm over the road (-Z) on others. The lamp head is at `LAMP_HEAD`.
const POLE_TOP := 9.6
const LAMP_HEAD := Vector3(0, 7.9, -2.1)
static func power_pole(b: MeshKit.Builder, t: Transform3D, lamp: bool, transformer: bool) -> Array:
	b.rcyl(0.36, 0.3, Vector3(0, 0.1, 0), CONCRETE_DARK, 10, 0.06, Basis.IDENTITY, t)        # collar in the ground
	rb(b, t, Vector3(0.34, 6.0, 0.34), Vector3(0, 3.0, 0), CONCRETE, 0.05)
	rb(b, t, Vector3(0.26, POLE_TOP - 6.0, 0.26), Vector3(0, 6.0 + (POLE_TOP - 6.0) * 0.5, 0), CONCRETE, 0.045)
	rb(b, t, Vector3(0.3, 0.12, 0.3), Vector3(0, 6.0, 0), CONCRETE_DARK, 0.03)                 # the step in the taper
	rb(b, t, Vector3(0.18, 0.28, 0.02), Vector3(0, 2.4, -0.18), surf(Color("e0b41c"), MeshKit.PAINT), 0.008)   # pole number
	for y in [3.4, 3.9, 4.4, 4.9, 5.4]: # step bolts up the side
		b.rcyl(0.018, 0.16, Vector3(0.18 if int(y * 2.0) % 2 == 0 else -0.18, y, 0), GALVANISED, 6, 0.004, Basis(Vector3.FORWARD, PI * 0.5), t)
	# Crossarm with its braces and three pin insulators.
	rb(b, t, Vector3(1.9, 0.12, 0.12), Vector3(0, POLE_TOP - 0.4, 0), CONCRETE_DARK, 0.025)
	for sx in [-1.0, 1.0]:
		b.tube(PackedVector3Array([Vector3(sx * 0.12, POLE_TOP - 0.95, -0.08), Vector3(sx * 0.6, POLE_TOP - 0.46, -0.08)]), 0.022, GALVANISED, 5, -1.0, t)
	for x in [-0.8, 0.0, 0.8]:
		b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.03, 0), Vector2(0.03, 0.05), Vector2(0.075, 0.07), Vector2(0.05, 0.1),
			Vector2(0.07, 0.13), Vector2(0.045, 0.17), Vector2(0.05, 0.2), Vector2(0, 0.22)]), Vector3(x, POLE_TOP - 0.34, 0), PORCELAIN, 10, Basis.IDENTITY, t)
	# The thick bundles of phone and cable lines lower down, strapped on.
	for y in [7.0, 6.6]:
		rb(b, t, Vector3(0.5, 0.14, 0.14), Vector3(0, y, 0.1), Props.DARK, 0.04)
		b.rcyl(0.2, 0.04, Vector3(0, y, 0.0), GALVANISED, 8, 0.01, Basis.IDENTITY, t)
	b.rcyl(0.16, 0.3, Vector3(0, 6.85, 0.22), Props.DARK, 8, 0.05, Basis(Vector3.RIGHT, PI * 0.5), t)   # a splice box
	if transformer:
		var k := Vector3(0, 6.2, 0.48)
		b.rcyl(0.32, 1.1, k, surf(Color("8e969a"), MeshKit.METAL), 14, 0.05, Basis.IDENTITY, t)
		b.rcyl(0.35, 0.08, k + Vector3(0, 0.58, 0), surf(Color("6e7478"), MeshKit.METAL), 14, 0.03, Basis.IDENTITY, t)    # lid
		for i in 8: # cooling fins
			var a := TAU * i / 8.0 + 0.2
			rb(b, t, Vector3(0.025, 0.85, 0.14), k + Vector3(cos(a) * 0.36, -0.05, sin(a) * 0.36), surf(Color("7e8488"), MeshKit.METAL), 0.008, Basis(Vector3.UP, PI * 0.5 - a))
		for i in 3: # bushings
			b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.04, 0), Vector2(0.06, 0.05), Vector2(0.035, 0.09), Vector2(0.05, 0.13), Vector2(0, 0.2)]),
				k + Vector3(-0.15 + i * 0.15, 0.62, 0), Color("5a4a3a"), 8, Basis.IDENTITY, t)
		for y in [5.9, 6.6]: # straps
			rb(b, t, Vector3(0.4, 0.06, 0.2), Vector3(0, y, 0.18), GALVANISED, 0.01)
	if lamp:
		b.tube(MeshKit.arc(Vector3(0, 7.3, -0.16), Vector3(0, 8.3, -0.5), LAMP_HEAD + Vector3(0, 0.12, 0.25), 8), 0.045, GALVANISED, 6, 0.035, t)
		b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.27, 0), Vector2(0.3, 0.05), Vector2(0.26, 0.13), Vector2(0.14, 0.19), Vector2(0, 0.2)]),
			LAMP_HEAD + Vector3(0, 0.02, 0), surf(Color("6a7076"), MeshKit.METAL), 12, Basis.IDENTITY, t, Vector2(0.8, 1.35))
		b.rcyl(0.27, 0.025, LAMP_HEAD + Vector3(0, 0.02, 0), Props.GLASS, 12, 0.008, Basis.IDENTITY, t)
	return [[Vector3(0, POLE_TOP * 0.5, 0), Vector3(0.34, POLE_TOP, 0.34)]]


## The points a pole's wires hang from, in its own space.
static func wire_points() -> Array:
	return [Vector3(-0.8, POLE_TOP - 0.18, 0), Vector3(0, POLE_TOP - 0.18, 0), Vector3(0.8, POLE_TOP - 0.18, 0), Vector3(0, 6.8, 0.1)]


## One length of galvanised guard rail along -Z: posts every two metres with spacer blocks and
## amber reflectors, the W-beam on top (two rounded ribs), bolts.
static func guard_rail(b: MeshKit.Builder, t: Transform3D, length: float) -> Array:
	var n := maxi(1, roundi(length / 2.0))
	for i in n + 1:
		var z := -length * float(i) / n
		rb(b, t, Vector3(0.15, 0.85, 0.1), Vector3(0, 0.38, z), Props.STEEL, 0.02)
		rb(b, t, Vector3(0.12, 0.3, 0.14), Vector3(0.06, 0.62, z), Props.STEEL.darkened(0.15), 0.02)   # spacer
		rb(b, t, Vector3(0.02, 0.09, 0.06), Vector3(-0.08, 0.8, z), surf(Color("e08a1a"), MeshKit.GLASS), 0.006)  # reflector
	for y in [0.56, 0.74]: # the W-beam's two ribs, and the valley between
		rb(b, t, Vector3(0.1, 0.16, length + 0.2), Vector3(0.14, y, -length * 0.5), GALVANISED, 0.045)
	rb(b, t, Vector3(0.05, 0.34, length + 0.2), Vector3(0.12, 0.65, -length * 0.5), GALVANISED.darkened(0.12), 0.01)
	for i in n + 1:
		b.rcyl(0.025, 0.04, Vector3(0.2, 0.65, -length * float(i) / n), GALVANISED.lightened(0.1), 6, 0.008, Basis(Vector3.FORWARD, PI * 0.5), t)
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
	# Lift shaft, footed a metre into the slope, with its doors at the bottom on the north side:
	# pilasters at its corners, a band at every landing, a steel door in a frame, the call button.
	rb(b, t, Vector3(CORE_HALF * 2.0, h + 1.0, CORE_HALF * 2.0), Vector3(0, (h - 1.0) * 0.5, 0), CONCRETE, 0.06)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			rb(b, t, Vector3(0.3, h + 1.0, 0.3), Vector3(sx * (CORE_HALF - 0.1), (h - 1.0) * 0.5, sz * (CORE_HALF - 0.1)), CONCRETE_LIGHT, 0.04)
	for i in range(1, 4):
		rb(b, t, Vector3(CORE_HALF * 2.0 + 0.1, 0.16, CORE_HALF * 2.0 + 0.1), Vector3(0, rise * i + 0.9, 0), CONCRETE_LIGHT, 0.03)
	bx(b, t, Vector3(1.2, 2.2, 0.06), Vector3(0, 1.1, -CORE_HALF - 0.03), Props.STEEL)
	b.rbox(Vector3(0.02, 2.1, 0.02), Vector3(0, 1.1, -CORE_HALF - 0.07), Props.DARK, 0.005, Basis.IDENTITY, t)   # the doors' seam
	rb(b, t, Vector3(1.5, 0.14, 0.12), Vector3(0, 2.27, -CORE_HALF - 0.05), GALVANISED, 0.02)
	for sx in [-1.0, 1.0]:
		rb(b, t, Vector3(0.14, 2.3, 0.12), Vector3(sx * 0.68, 1.12, -CORE_HALF - 0.05), GALVANISED, 0.02)
	rb(b, t, Vector3(0.12, 0.22, 0.04), Vector3(0.95, 1.2, -CORE_HALF - 0.03), GALVANISED, 0.01)
	b.rcyl(0.025, 0.03, Vector3(0.95, 1.24, -CORE_HALF - 0.06), surf(Color("e0b41c"), MeshKit.GLASS), 8, 0.005, Basis(Vector3.RIGHT, PI * 0.5), t)
	solid.append([Vector3(0, (h - 1.0) * 0.5, 0), Vector3(CORE_HALF * 2.0, h + 1.0, CORE_HALF * 2.0)])
	# Corner columns, footed into the slope too, each on a plinth with a cap under the deck.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var cat := Vector3(sx * (TOWER_HALF - 0.25), (h - 1.0) * 0.5, sz * (TOWER_HALF - 0.25))
			rb(b, t, Vector3(0.5, h + 1.0, 0.5), cat, CONCRETE_DARK, 0.05)
			rb(b, t, Vector3(0.8, 0.6, 0.8), Vector3(cat.x, 0.1, cat.z), CONCRETE_DARK.darkened(0.1), 0.06)
			rb(b, t, Vector3(0.64, 0.2, 0.64), Vector3(cat.x, h - 0.45, cat.z), CONCRETE, 0.04)
			solid.append([cat, Vector3(0.5, h + 1.0, 0.5)])
	# Corners in climbing order and the landing at each (the first is on the ground).
	var corners := [Vector2(-c, c), Vector2(c, c), Vector2(c, -c), Vector2(-c, -c), Vector2(-c, c)]
	for i in 4:
		var y := rise * i
		var a: Vector2 = corners[i]
		var z: Vector2 = corners[i + 1]
		if i > 0:
			var land := Vector3(a.x, y - 0.15, a.y)
			rb(b, t, Vector3(LANDING, 0.3, LANDING), land, CONCRETE, 0.04)
			rb(b, t, Vector3(LANDING + 0.06, 0.1, LANDING + 0.06), land + Vector3(0, -0.18, 0), CONCRETE_DARK, 0.02)  # drip edge
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
		rb(b, t, Vector3(width, 0.24, length + 0.1), mid, CONCRETE, 0.03, basis)
		solid.append([mid, Vector3(width, 0.24, length + 0.1), basis])
		var side := Vector3(-dir.y, 0, dir.x)
		for s: float in [1.0, -1.0]: # stringers, the beams the flight hangs on
			rb(b, t, Vector3(0.14, 0.42, length + 0.1), mid + side * s * (width * 0.5 - 0.07) + Vector3(0, -0.12, 0), CONCRETE_DARK, 0.03, basis)
		var steps := ceili(rise / 0.18)
		var flat := Basis.looking_at(Vector3(dir.x, 0, dir.y), Vector3.UP)
		for k in steps: # each step a bevelled tread with a nosing
			var f := (k + 0.5) / steps
			var tread := Vector3(from.x, 0, from.y).lerp(Vector3(to.x, 0, to.y), f) + Vector3(0, y + rise * f + 0.02, 0)
			rb(b, t, Vector3(width - 0.3, 0.07, run / steps * 0.5), tread, CONCRETE_LIGHT, 0.02, flat)
			rb(b, t, Vector3(width - 0.32, 0.025, 0.04), tread - Vector3(dir.x, 0, dir.y) * (run / steps * 0.25) + Vector3(0, 0.03, 0), Props.DARK, 0.008, flat)
		# Hand rails on both sides of the flight: round tube on posts.
		for s: float in [1.0, -1.0]:
			var off := side * s * (width * 0.5 - 0.05)
			b.tube(PackedVector3Array([p0 + off + Vector3(0, 1.0, 0), p1 + off + Vector3(0, 1.0, 0)]), 0.035, GALVANISED, 8, -1.0, t)
			b.tube(PackedVector3Array([p0 + off + Vector3(0, 0.5, 0), p1 + off + Vector3(0, 0.5, 0)]), 0.02, GALVANISED, 6, -1.0, t)
			for k in 5:
				var q := p0.lerp(p1, (k + 0.5) / 5.0) + off
				b.rcyl(0.025, 1.0, q + Vector3(0, 0.5, 0), GALVANISED, 6, 0.006, Basis.IDENTITY, t)
			var rail := (p0 + p1) * 0.5 + off + Vector3(0, 1.0, 0)
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
		rb(b, t, d[1], d[0], d[2], 0.02)
		solid.append([d[0], d[1]])
	# A fascia band round the deck's edge, deeper than the slab, with a drip groove under it.
	for e: Array in [[Vector3(0, 0, -TOWER_HALF - 0.06), Vector3(TOWER_HALF * 2.0 + 0.24, 0, 0.12)], [Vector3(0, 0, TOWER_HALF + 0.06), Vector3(TOWER_HALF * 2.0 + 0.24, 0, 0.12)],
			[Vector3(-TOWER_HALF - 0.06, 0, 0), Vector3(0.12, 0, TOWER_HALF * 2.0)], [Vector3(TOWER_HALF + 0.06, 0, 0), Vector3(0.12, 0, TOWER_HALF * 2.0)]]:
		var ep: Vector3 = e[0]
		var es: Vector3 = e[1]
		rb(b, t, es + Vector3(0, 0.55, 0), ep + Vector3(0, h - 0.2, 0), CONCRETE_LIGHT, 0.04)
		rb(b, t, es + Vector3(0.02, 0.06, 0.02), ep + Vector3(0, h - 0.5, 0), CONCRETE_DARK, 0.01)
	for k in 8: # the grating's bars and the cross bars under them
		rb(b, t, Vector3(0.05, 0.04, TOWER_HALF * 2.0), Vector3(1.6 + k * 0.4, h + 0.02, 0), GALVANISED, 0.012)
	for k in 12:
		rb(b, t, Vector3(TOWER_HALF - 1.4, 0.03, 0.03), Vector3((1.4 + TOWER_HALF) * 0.5, h + 0.005, -TOWER_HALF + 0.4 + k * 0.75), GALVANISED.darkened(0.2), 0.006)
	# Railing round the deck, and round the hole except where the stairs arrive (south end):
	# a round top rail, a mid rail and posts.
	for rside: Array in [[Vector3(0, 0, -TOWER_HALF), Vector3(TOWER_HALF * 2.0, 0, 0.08)], [Vector3(0, 0, TOWER_HALF), Vector3(TOWER_HALF * 2.0, 0, 0.08)],
			[Vector3(-TOWER_HALF, 0, 0), Vector3(0.08, 0, TOWER_HALF * 2.0)], [Vector3(TOWER_HALF, 0, 0), Vector3(0.08, 0, TOWER_HALF * 2.0)],
			[Vector3(-FLIGHT_IN, 0, (hole_lo + hole_hi) * 0.5), Vector3(0.08, 0, hole_hi - hole_lo)],
			[Vector3((-TOWER_HALF - FLIGHT_IN) * 0.5, 0, hole_lo), Vector3(TOWER_HALF - FLIGHT_IN, 0, 0.08)]]:
		var rat: Vector3 = rside[0]
		var size: Vector3 = rside[1]
		var along := Vector3(size.x * 0.5, 0, 0) if size.x > size.z else Vector3(0, 0, size.z * 0.5)
		b.tube(PackedVector3Array([rat - along + Vector3(0, h + 1.1, 0), rat + along + Vector3(0, h + 1.1, 0)]), 0.045, GALVANISED, 8, -1.0, t, true)
		b.tube(PackedVector3Array([rat - along + Vector3(0, h + 0.55, 0), rat + along + Vector3(0, h + 0.55, 0)]), 0.025, GALVANISED, 6, -1.0, t)
		b.tube(PackedVector3Array([rat - along + Vector3(0, h + 0.12, 0), rat + along + Vector3(0, h + 0.12, 0)]), 0.02, GALVANISED, 6, -1.0, t)
		solid.append([rat + Vector3(0, h + 0.55, 0), size + Vector3(0.1, 1.1, 0.1)])
	# Posts of the railing, the shaft's roof and the two coin binoculars facing the city and the bay.
	for k in 9:
		var f := -TOWER_HALF + k * TOWER_HALF * 0.25
		for p: Vector3 in [Vector3(f, 0, -TOWER_HALF), Vector3(f, 0, TOWER_HALF), Vector3(TOWER_HALF, 0, f)]:
			b.rcyl(0.035, 1.1, p + Vector3(0, h + 0.55, 0), GALVANISED, 8, 0.01, Basis.IDENTITY, t)
	# The lift head: a block over the shaft with a cornice, louvres, and a small mast on top.
	rb(b, t, Vector3(CORE_HALF * 2.0 + 0.2, 2.4, CORE_HALF * 2.0 + 0.2), Vector3(0, h + 1.2, 0), CONCRETE, 0.06)  # lift head
	rb(b, t, Vector3(CORE_HALF * 2.0 + 0.5, 0.2, CORE_HALF * 2.0 + 0.5), Vector3(0, h + 2.48, 0), CONCRETE_LIGHT, 0.05)
	rb(b, t, Vector3(CORE_HALF * 2.0 + 0.3, 0.12, CORE_HALF * 2.0 + 0.3), Vector3(0, h + 0.06, 0), CONCRETE_DARK, 0.03)
	for k in 5:
		rb(b, t, Vector3(0.08, 0.04, 0.9), Vector3(-CORE_HALF - 0.12, h + 1.0 + k * 0.12, 0), CONCRETE_DARK, 0.01, Basis(Vector3.FORWARD, 0.4))
	b.rcyl(0.04, 1.4, Vector3(0.9, h + 3.28, 0.9), GALVANISED, 6, 0.01, Basis.IDENTITY, t)
	solid.append([Vector3(0, h + 1.2, 0), Vector3(CORE_HALF * 2.0 + 0.2, 2.4, CORE_HALF * 2.0 + 0.2)])
	for bat: Vector3 in [Vector3(3.4, 0, -3.4), Vector3(-1.6, 0, 3.4)]:
		_binoculars(b, at(t, bat + Vector3(0, h, 0), atan2(bat.x, bat.z) + PI))
	# Planters in the deck's free corners.
	potted(b, t, Vector3(-3.9, h, -3.9), 0.9, Vegetation.BOUGAINVILLEA_PINK, 41)
	potted(b, t, Vector3(3.9, h, 3.9), 0.9, Vegetation.HIBISCUS_RED, 42)
	return solid


## Coin binoculars on a post, looking out along -Z of `f`.
static func _binoculars(b: MeshKit.Builder, f: Transform3D) -> void:
	b.rcyl(0.16, 0.08, Vector3(0, 0.04, 0), Props.STEEL, 10, 0.02, Basis.IDENTITY, f)
	b.taper(0.07, 0.05, 1.05, Vector3(0, 0.05, 0), Props.STEEL, 8, Basis.IDENTITY, f)
	rb(b, f, Vector3(0.34, 0.26, 0.3), Vector3(0, 1.22, 0.02), surf(Color("2a5a9a"), MeshKit.PAINT), 0.07)
	for sx in [-0.09, 0.09]:
		b.rcyl(0.07, 0.32, Vector3(sx, 1.28, -0.2), surf(Color("2a5a9a"), MeshKit.PAINT), 10, 0.02, Basis(Vector3.RIGHT, PI * 0.5), f)
		b.rcyl(0.055, 0.02, Vector3(sx, 1.28, -0.365), Props.GLASS, 10, 0.005, Basis(Vector3.RIGHT, PI * 0.5), f)
		b.rcyl(0.04, 0.08, Vector3(sx, 1.28, 0.2), Props.DARK, 8, 0.01, Basis(Vector3.RIGHT, PI * 0.5), f)
	rb(b, f, Vector3(0.1, 0.06, 0.04), Vector3(0.12, 1.14, 0.17), surf(Color("c8a030"), MeshKit.METAL), 0.01)   # coin slot


## Snack bar: a cream kiosk on a plinth with a tiled band, its roll-up shutter half down under a
## striped awning with a scalloped edge, a sign box (lettering: `SNACK_SIGN_AT`, the map's), a menu
## board, a drinks cooler, a gas bottle, an air conditioner, and plastic tables and chairs left
## outside, one tipped over.
const SNACK_SIGN_AT := Vector3(0, 3.6, -2.3)
static func snack_bar(b: MeshKit.Builder, t: Transform3D) -> Array:
	rb(b, t, Vector3(6.3, 0.2, 4.3), Vector3(0, 0.1, 0), CONCRETE_DARK, 0.04)
	rb(b, t, Vector3(6.0, 3.0, 4.0), Vector3(0, 1.5, 0), CREAM, 0.06)
	rb(b, t, Vector3(6.06, 0.9, 4.06), Vector3(0, 0.65, 0), TILE_BLUE, 0.03)             # tiled band
	rb(b, t, Vector3(6.1, 0.08, 4.1), Vector3(0, 1.12, 0), PAINT_WHITE, 0.02)
	# The opening: a dark inside, the shutter half down with its ribs, the counter in front.
	bx(b, t, Vector3(4.4, 1.3, 0.06), Vector3(0, 1.75, -2.03), Props.SOOT)
	rb(b, t, Vector3(4.5, 1.0, 0.08), Vector3(0, 2.05, -2.06), Props.STEEL, 0.01)
	for k in 6:
		rb(b, t, Vector3(4.5, 0.03, 0.04), Vector3(0, 1.6 + k * 0.17, -2.11), Props.STEEL.lightened(0.15), 0.008)
	rb(b, t, Vector3(4.6, 0.1, 0.12), Vector3(0, 1.58, -2.12), Props.STEEL.darkened(0.2), 0.02)       # bottom rail
	rb(b, t, Vector3(4.7, 0.1, 0.7), Vector3(0, 1.1, -2.3), CONCRETE_LIGHT, 0.03)                     # counter
	rb(b, t, Vector3(4.5, 0.9, 0.08), Vector3(0, 0.62, -2.06), TILE_WHITE, 0.02)
	for sx in [-1.0, 1.0]:
		rb(b, t, Vector3(0.12, 2.2, 0.14), Vector3(sx * 2.3, 1.55, -2.05), PAINT_WHITE, 0.02)
	# Things left on the counter: a napkin box, a bottle, a sugar shaker.
	rb(b, t, Vector3(0.16, 0.1, 0.12), Vector3(-1.4, 1.2, -2.4), PAINT_WHITE, 0.02)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.035, 0), Vector2(0.035, 0.16), Vector2(0.014, 0.22), Vector2(0.012, 0.26), Vector2(0, 0.26)]),
		Vector3(0.8, 1.15, -2.45), surf(Color("3a7a3a"), MeshKit.GLASS), 10, Basis.IDENTITY, t)
	b.rcyl(0.035, 0.12, Vector3(0.6, 1.21, -2.4), Props.GLASS, 8, 0.01, Basis.IDENTITY, t)
	# The awning: alternating stripes, sloping out, with a scalloped valance.
	var tilt := Basis(Vector3.RIGHT, -0.22)
	var af := t * Transform3D(tilt, Vector3(0, 2.85, -2.75))
	for k in 10:
		var x := -3.2 + k * 0.64
		rb(b, af, Vector3(0.64, 0.06, 1.8), Vector3(x + 0.32, 0, 0), AWNING if k % 2 == 0 else AWNING_LIGHT, 0.015)
		b.blob(Vector3(0.3, 0.14, 0.04), Vector3(x + 0.32, -0.02, -0.9), AWNING if k % 2 == 0 else AWNING_LIGHT, k, 0.0, 4, 8, Basis(Vector3.RIGHT, PI), af, 0.5)
	rb(b, af, Vector3(6.5, 0.06, 0.06), Vector3(0, 0.04, -0.9), Props.STEEL, 0.015)
	for sx in [-3.2, 3.2]: # brackets back to the wall
		b.tube(PackedVector3Array([Vector3(sx, 2.3, -2.02), Vector3(sx, 2.62, -3.55)]), 0.025, Props.STEEL, 6, -1.0, t)
	# Roof: a parapet with a cornice, the sign box standing on the front edge.
	rb(b, t, Vector3(6.4, 0.25, 4.4), Vector3(0, 3.1, 0), CONCRETE_LIGHT, 0.05)
	rb(b, t, Vector3(6.2, 0.35, 0.15), Vector3(0, 3.38, 2.08), CONCRETE_LIGHT, 0.03)
	rb(b, t, Vector3(4.2, 0.7, 0.24), Vector3(0, 3.6, -2.15), PAINT_WHITE, 0.05)
	rb(b, t, Vector3(4.3, 0.08, 0.3), Vector3(0, 3.98, -2.15), surf(AWNING, MeshKit.PAINT), 0.02)
	rb(b, t, Vector3(4.3, 0.08, 0.3), Vector3(0, 3.22, -2.15), surf(AWNING, MeshKit.PAINT), 0.02)
	for sx in [-1.2, 1.2]: # sign lamps peering down
		b.tube(PackedVector3Array([Vector3(sx, 4.0, -2.2), Vector3(sx, 4.25, -2.45), Vector3(sx, 4.2, -2.7)]), 0.02, Props.STEEL, 5, -1.0, t)
		b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.09, 0), Vector2(0.06, 0.1), Vector2(0, 0.12)]), Vector3(sx, 4.12, -2.72), Props.STEEL, 8, Basis.IDENTITY, t)
	# Menu board on the wall right of the opening: a dark board in a wooden frame, chalk lines.
	var mb := at(t, Vector3(2.62, 1.75, -2.03))
	rb(b, mb, Vector3(0.6, 0.9, 0.05), Vector3(0, 0, -0.03), Color("6a4a2c"), 0.02)
	rb(b, mb, Vector3(0.5, 0.8, 0.03), Vector3(0, 0, -0.06), CHALK, 0.008)
	for k in 6:
		rb(b, mb, Vector3(0.22 + 0.1 * (k % 3), 0.02, 0.01), Vector3(-0.06, 0.28 - k * 0.11, -0.078), PAINT_WHITE, 0.004)
	# Side: air conditioner, gas bottle in a little cage, a downpipe; behind: a door.
	ac_unit(b, at(t, Vector3(3.17, 2.3, 0.6), -PI * 0.5))
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.17, 0), Vector2(0.19, 0.06), Vector2(0.19, 0.62), Vector2(0.12, 0.74),
		Vector2(0.05, 0.76), Vector2(0.05, 0.84), Vector2(0, 0.85)]), Vector3(3.35, 0.2, -1.1), surf(Color("c84a1a"), MeshKit.PAINT), 12, Basis.IDENTITY, t)
	downpipe(b, t, Vector3(-3.08, 3.0, 1.9), Vector3(-3.08, 0.2, 1.9))
	door(b, at(t, Vector3(1.6, 0.2, 2.02), PI), 0.9, 2.05, surf(Color("6a7a5a"), MeshKit.PAINT))
	# The drinks cooler by the counter.
	var cool := at(t, Vector3(-3.55, 0.0, -1.3), PI * 0.5)
	rb(b, cool, Vector3(0.7, 1.7, 0.7), Vector3(0, 0.85, 0), PLASTIC_RED, 0.06)
	rb(b, cool, Vector3(0.5, 1.2, 0.04), Vector3(0, 0.95, -0.36), Props.GLASS, 0.01)
	for k in 3:
		rb(b, cool, Vector3(0.46, 0.02, 0.4), Vector3(0, 0.55 + k * 0.38, -0.05), Props.STEEL, 0.005)
	rb(b, cool, Vector3(0.66, 0.24, 0.05), Vector3(0, 1.62, -0.36), PAINT_WHITE, 0.02)
	# Outside: two tables with chairs, one table knocked over with its chair, a bin.
	var solid := [[Vector3(0, 1.5, 0), Vector3(6.0, 3.0, 4.0)]]
	for tb: Array in [[Vector3(-1.6, 0, -4.6), false], [Vector3(1.5, 0, -5.2), true]]:
		var tp: Vector3 = tb[0]
		var tipped: bool = tb[1]
		var tt := at(t, tp, 0.4 if not tipped else 0.0)
		if tipped:
			tt = tt * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.38, 0.38, 0))
		_cafe_table(b, tt)
		for k in 2:
			var ca := 0.8 + k * PI + (0.3 if tipped else 0.0)
			var ct := at(t, tp + Vector3(cos(ca) * 0.75, 0, sin(ca) * 0.75), -ca + PI * 0.5)
			if tipped and k == 1:
				ct = ct * Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0.25, 0))
			_cafe_chair(b, ct)
		solid.append([tp + Vector3(0, 0.4, 0), Vector3(0.8, 0.8, 0.8)])
	Props.barrel(b, at(t, Vector3(-2.6, 0, -3.0)), surf(Color("2a5a2a"), MeshKit.PAINT))
	potted(b, t, Vector3(2.9, 0.2, -2.45), 0.75, Vegetation.HIBISCUS_RED, 11)
	return solid


## A round plastic café table, its foot at the origin of `f`.
static func _cafe_table(b: MeshKit.Builder, f: Transform3D) -> void:
	b.rcyl(0.4, 0.04, Vector3(0, 0.74, 0), PAINT_WHITE, 16, 0.015, Basis.IDENTITY, f)
	b.taper(0.04, 0.035, 0.72, Vector3(0, 0.02, 0), PAINT_WHITE.darkened(0.05), 8, Basis.IDENTITY, f)
	for k in 4:
		var a := TAU * k / 4.0 + 0.4
		b.tube(PackedVector3Array([Vector3(0, 0.12, 0), Vector3(cos(a) * 0.3, 0.02, sin(a) * 0.3)]), 0.022, PAINT_WHITE.darkened(0.05), 5, -1.0, f)


## A plastic chair facing -Z, its foot at the origin of `f`.
static func _cafe_chair(b: MeshKit.Builder, f: Transform3D) -> void:
	var c := PLASTIC_RED
	rb(b, f, Vector3(0.44, 0.05, 0.42), Vector3(0, 0.44, 0), c, 0.02)
	rb(b, f, Vector3(0.44, 0.42, 0.05), Vector3(0, 0.68, 0.22), c, 0.02, Basis(Vector3.RIGHT, 0.12))
	for sx in [-0.19, 0.19]:
		for sz in [-0.18, 0.18]:
			b.tube(PackedVector3Array([Vector3(sx, 0.43, sz), Vector3(sx * 1.12, 0.0, sz * 1.12)]), 0.022, c, 5, -1.0, f)


## Toilet block: plinth, a tiled lower band, two doors in frames with the pictograms over them,
## high windows, louvred vents, a roof with a fascia, downpipes, and a drinking fountain.
static func toilets(b: MeshKit.Builder, t: Transform3D) -> Array:
	rb(b, t, Vector3(7.3, 0.2, 4.3), Vector3(0, 0.1, 0), CONCRETE_DARK, 0.04)
	rb(b, t, Vector3(7.0, 3.0, 4.0), Vector3(0, 1.5, 0), CREAM.darkened(0.1), 0.06)
	rb(b, t, Vector3(7.06, 1.2, 4.06), Vector3(0, 0.8, 0), TILE_WHITE, 0.03)
	rb(b, t, Vector3(7.1, 0.1, 4.1), Vector3(0, 1.42, 0), TILE_BLUE, 0.02)
	for k in 2:
		var x := -1.8 + k * 3.6
		door(b, at(t, Vector3(x, 0.2, -2.03)), 1.0, 2.05, surf(Color("355a7a"), MeshKit.PAINT))
		window(b, at(t, Vector3(x + (1.2 if k == 0 else -1.2), 2.55, -2.02)), 0.9, 0.35)
		# The plate over the door with its figure: a head and a body (a skirt on the right).
		var pl := at(t, Vector3(x, 2.55, -2.05))
		rb(b, pl, Vector3(0.4, 0.4, 0.03), Vector3(0, 0, -0.01), surf(Color("2a4a8a"), MeshKit.PAINT), 0.03)
		b.rcyl(0.04, 0.02, Vector3(0, 0.1, -0.035), PAINT_WHITE, 10, 0.005, Basis(Vector3.RIGHT, PI * 0.5), pl)
		if k == 0:
			rb(b, pl, Vector3(0.1, 0.18, 0.015), Vector3(0, -0.06, -0.035), PAINT_WHITE, 0.005)
		else:
			b.taper(0.08, 0.03, 0.18, Vector3(0, -0.15, -0.035), PAINT_WHITE, 8, Basis(Vector3.RIGHT, 0.0), pl)
	for k in 3: # louvres on the side walls
		for sx in [-1.0, 1.0]:
			var lv := at(t, Vector3(sx * 3.52, 2.5, -0.8 + k * 0.8), sx * -PI * 0.5)
			rb(b, lv, Vector3(0.5, 0.36, 0.04), Vector3.ZERO, CONCRETE_DARK, 0.01)
			for j in 4:
				rb(b, lv, Vector3(0.46, 0.03, 0.06), Vector3(0, -0.12 + j * 0.08, -0.03), CONCRETE_LIGHT, 0.006, Basis(Vector3.RIGHT, 0.5))
	rb(b, t, Vector3(7.5, 0.25, 4.5), Vector3(0, 3.1, 0), CONCRETE_DARK, 0.05)
	rb(b, t, Vector3(7.56, 0.12, 4.56), Vector3(0, 2.96, 0), CONCRETE_LIGHT, 0.03)
	for sx in [-1.0, 1.0]:
		downpipe(b, t, Vector3(sx * 3.58, 3.0, 2.0), Vector3(sx * 3.58, 0.2, 2.0))
	# Drinking fountain between the doors.
	var df := at(t, Vector3(0, 0.2, -2.5))
	rb(b, df, Vector3(0.36, 0.85, 0.36), Vector3(0, 0.425, 0), CONCRETE_LIGHT, 0.05)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.2, 0), Vector2(0.27, 0.08), Vector2(0.26, 0.12), Vector2(0.2, 0.06), Vector2(0, 0.05)]),
		Vector3(0, 0.85, 0), surf(Color("b8bcc0"), MeshKit.METAL), 14, Basis.IDENTITY, df)
	b.tube(PackedVector3Array([Vector3(0, 0.9, 0.1), Vector3(0, 1.02, 0.08), Vector3(0, 1.0, 0.0)]), 0.015, Props.STEEL, 5, -1.0, df)
	return [[Vector3(0, 1.5, 0), Vector3(7.0, 3.0, 4.0)]]


## Radio mast: three legs of round tube narrowing to the top, banded red and white, cross
## bracing, dishes, a red light on top (the map lights it), and an equipment shelter with its
## cable tray at the foot. Returns colliders; the light is at `mast_top(height)`.
static func radio_mast(b: MeshKit.Builder, t: Transform3D, height: float) -> Array:
	var foot := 1.4
	var legs := []
	for i in 3:
		var a := TAU * i / 3.0
		legs.append(Vector3(cos(a), 0, sin(a)))
	var band := 3.0
	for i in 3:
		var bottom: Vector3 = legs[i] * foot
		var top: Vector3 = legs[i] * 0.25 + Vector3(0, height, 0)
		var nb := int(ceil(height / band))
		for k in nb: # each band its own colour, aviation red and white
			var p0 := bottom.lerp(top, float(k) / nb)
			var p1 := bottom.lerp(top, float(k + 1) / nb)
			b.tube(PackedVector3Array([p0, p1]), 0.07, surf(Props.RED.darkened(0.05), MeshKit.PAINT) if k % 2 == 0 else PAINT_WHITE, 6, -1.0, t)
		b.rcyl(0.18, 0.3, bottom + Vector3(0, 0.15, 0), CONCRETE_DARK, 8, 0.04, Basis.IDENTITY, t)   # footing
	for k in range(1, int(height / 3.0)):
		var y := k * 3.0
		var r := lerpf(foot, 0.25, y / height)
		var r2 := lerpf(foot, 0.25, (y - 3.0) / height)
		for i in 3:
			var p: Vector3 = legs[i] * r + Vector3(0, y, 0)
			var q: Vector3 = legs[(i + 1) % 3] * r + Vector3(0, y, 0)
			var q0: Vector3 = legs[(i + 1) % 3] * r2 + Vector3(0, y - 3.0, 0)
			b.tube(PackedVector3Array([p, q]), 0.035, GALVANISED, 5, -1.0, t)
			b.tube(PackedVector3Array([p, q0]), 0.025, GALVANISED, 5, -1.0, t)   # diagonal
	_dish(b, at(t, Vector3(0.55, height * 0.7, 0), -PI * 0.5), 0.6)
	_dish(b, at(t, Vector3(-0.3, height * 0.55, 0.45), PI), 0.45)
	for k in 3: # panel antennas near the top
		var a := TAU * k / 3.0 + 0.5
		rb(b, t, Vector3(0.22, 1.2, 0.08), Vector3(cos(a) * 0.42, height - 1.6, sin(a) * 0.42), PAINT_WHITE, 0.03, Basis(Vector3.UP, -a + PI * 0.5))
	b.rcyl(0.04, 1.4, Vector3(0, height + 0.5, 0), GALVANISED, 6, 0.01, Basis.IDENTITY, t)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.16, 0), Vector2(0.17, 0.1), Vector2(0.12, 0.28), Vector2(0, 0.32)]),
		mast_top(height) + Vector3(0, -0.16, 0), surf(Props.RED, MeshKit.GLASS), 10, Basis.IDENTITY, t)
	# The equipment shelter: a grey box with a door, an air conditioner, the cable tray up the mast.
	var sh := at(t, Vector3(3.4, 0, 0), PI * 0.5)
	rb(b, sh, Vector3(2.6, 0.2, 2.6), Vector3(0, 0.1, 0), CONCRETE_DARK, 0.04)
	rb(b, sh, Vector3(2.4, 2.4, 2.4), Vector3(0, 1.4, 0), surf(Color("a8aca6"), MeshKit.PAINT), 0.06)
	rb(b, sh, Vector3(2.6, 0.12, 2.6), Vector3(0, 2.66, 0), CONCRETE_DARK, 0.03)
	door(b, at(sh, Vector3(0, 0.2, -1.22)), 0.9, 2.0, Props.STEEL, Props.STEEL.darkened(0.2))
	ac_unit(b, at(sh, Vector3(1.38, 1.8, 0.4), -PI * 0.5))
	b.tube(PackedVector3Array([Vector3(1.9, 2.2, 0), Vector3(0.9, 2.6, 0), Vector3(0.45, 3.4, 0), Vector3(0.3, height * 0.6, 0)]), 0.06, Props.DARK, 6, -1.0, t)
	return [[Vector3(0, 1.5, 0), Vector3(foot * 1.6, 3.0, foot * 1.6)], [Vector3(3.4, 1.3, 0), Vector3(2.4, 2.6, 2.4)]]


## A dish antenna looking along -Z of `f`, `r` metres across.
static func _dish(b: MeshKit.Builder, f: Transform3D, r: float) -> void:
	var face := Basis(Vector3.RIGHT, -PI * 0.5)    # the lathe's +Y becomes -Z
	b.lathe(PackedVector2Array([Vector2(0, -0.02), Vector2(r * 0.5, 0.02), Vector2(r * 0.9, 0.09), Vector2(r, 0.14),
		Vector2(r * 0.96, 0.16), Vector2(r * 0.5, 0.06), Vector2(0, 0.03)]), Vector3.ZERO, PAINT_WHITE, 14, face, f)
	b.tube(PackedVector3Array([Vector3(0, 0, 0.0), Vector3(0, 0, -r * 0.6)]), 0.02, GALVANISED, 5, -1.0, f)
	b.rcyl(0.05, 0.08, Vector3(0, 0, -r * 0.62), Props.DARK, 8, 0.01, face, f)
	b.tube(PackedVector3Array([Vector3(0, 0, 0.05), Vector3(0, 0, 0.35)]), 0.04, GALVANISED, 6, -1.0, f)


static func mast_top(height: float) -> Vector3:
	return Vector3(0, height + 0.2, 0)
