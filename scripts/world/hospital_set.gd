class_name HospitalSet
## The pieces of the Hospital Dona Helena, like MiranteSet and PrefeituraSet: each draws into the
## Builder it is given at transform `t` and returns its solid parts as [[center, size, basis?], ...]
## in its own space. Pieces stand on y = 0 and face -Z (the street, Rua Blumenau).
##
## From references/hospital1.jpg (at night from the air: the white tower in three bodies washed in
## blue light, the lit sign on the middle body, the ambulance bay along the street) and
## hospital2.png (by day from the street: the old wing with dark vertical concrete fins in front of
## brown glass, the green-banded annex, the tower behind). What's built: references/hospital_elements.md.
##
## The tower's frame: its front at z = TOWER_FRONT, its back at TOWER_BACK, three bodies side by
## side along X (A tall and narrow, B the sign body stepping forward, C wide with balcony bands).
## A steel fire stair climbs the back from the yard to the roof, where the helipad is.

## Alpha is the surface class (MeshKit): cc PAINT, 99 METAL, b3 BRICK, 66 GLASS, 80 TILE.
const WHITE := Color("e6e6e0")
const WHITE_SHADE := Color("cfd0cc")
const GLASS_BLUE := Color("1e3a6a66")
const GLASS_BROWN := Color("2e221866")
const FIN := Color("6a6258")
const OLIVE := Color("7a7f44cc")
const TILE_ROOF := Color("9a4a2ab3")
const STEEL := Color("5a606899")
const SAFETY := Color("c8a01ecc")
const SIGN_BLUE := Color("9fd0ff")      ## the lit sign's letters (Label3D colour: alpha 1)
const WASH := Color("3a7cff")           ## the blue light up the faces
const BAY_BLUE := Color("2a6ad8cc")     ## the bay canopy's lit edge (PAINT; its glow is in `glow`)
const PAD_GREEN := Color("2f5a3acc")

const FLOOR_H := 3.3
const FLOORS := 10
const ROOF_Y := FLOOR_H * FLOORS
const TOWER_FRONT := 4.0
const TOWER_BACK := 24.0
const A := Vector2(-54.0, -42.0)        ## x ranges of the three bodies
const B := Vector2(-42.0, -30.0)
const C := Vector2(-30.0, -8.0)
const B_OUT := 2.0                      ## the sign body steps forward
const STAIR_X := -24.0                  ## the fire stair, against the back wall of body C
const STAIR_RUN := 4.2                  ## a flight's run; it rises half a floor
const STAIR_W := 1.2
const PAD_AT := Vector3(-19.0, ROOF_Y, 14.0)
const PAD_HALF := 7.0
const SIGN_AT := Vector3((-42.0 - 30.0) * 0.5, ROOF_Y - 1.6, TOWER_FRONT - B_OUT - 0.32)
const WASH_AT := Vector3(-31.0, 1.0, -6.0)
const BAY := Rect2(-52.0, -10.0, 42.0, 14.0)  ## the ambulance bay canopy (x, z, w, d)


static func bx(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, -1.0, rot, t)


static func rb(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, r: float, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, r, rot, t)


static func at(t: Transform3D, p: Vector3, yaw := 0.0) -> Transform3D:
	return t * Transform3D(Basis(Vector3.UP, yaw), p)


# --- The tower ----------------------------------------------------------------------------

## The ward tower: three bodies, its glass entrance under the bay canopy, the roof with its
## parapets, plant and the helipad. `glow` takes the lit windows, the sign's box and the bay's edge.
static func tower(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> Array:
	var solid := []
	var depth := TOWER_BACK - TOWER_FRONT
	var mid_z := (TOWER_FRONT + TOWER_BACK) * 0.5
	# Body A: tall and narrow, plain white, two punched windows a floor on the front, a grid on the side.
	var a_h := ROOF_Y + FLOOR_H
	bx(b, t, Vector3(A.y - A.x, a_h, depth), Vector3((A.x + A.y) * 0.5, a_h * 0.5, mid_z), WHITE)
	for fl in range(1, FLOORS + 1):
		var y := fl * FLOOR_H + 1.6
		for k in 2:
			var x := A.x + 3.0 + k * 6.0
			MiranteSet.window(b, at(t, Vector3(x, y, TOWER_FRONT - 0.02)), 2.0, 1.5, WHITE_SHADE)
			_maybe_lit(glow, t, Vector3(x, y, TOWER_FRONT - 0.05), Vector2(1.8, 1.3), 31, fl, k)
		for k in 4: # the west side
			MiranteSet.window(b, at(t, Vector3(A.x - 0.02, y, TOWER_FRONT + 2.5 + k * 5.0), PI * 0.5), 1.6, 1.5, WHITE_SHADE)
	for x in [A.x, A.y]: # corner pilasters
		rb(b, t, Vector3(0.6, a_h, 0.5), Vector3(x, a_h * 0.5, TOWER_FRONT - 0.2), WHITE_SHADE, 0.05)
	rb(b, t, Vector3(A.y - A.x + 0.4, 0.5, depth + 0.4), Vector3((A.x + A.y) * 0.5, a_h + 0.25, mid_z), WHITE_SHADE, 0.05)
	solid.append([Vector3((A.x + A.y) * 0.5, a_h * 0.5, mid_z), Vector3(A.y - A.x, a_h, depth)])
	# Body B: steps forward; a full-height slot of blue glass framed in white, the sign at the top.
	var b_front := TOWER_FRONT - B_OUT
	var b_h := ROOF_Y + 1.8
	bx(b, t, Vector3(B.y - B.x, b_h, depth + B_OUT), Vector3((B.x + B.y) * 0.5, b_h * 0.5, mid_z - B_OUT * 0.5), WHITE)
	var slot_w := 6.0
	var bx_mid := (B.x + B.y) * 0.5
	bx(b, t, Vector3(slot_w, ROOF_Y - FLOOR_H * 1.5, 0.06), Vector3(bx_mid, FLOOR_H + (ROOF_Y - FLOOR_H * 1.5) * 0.5, b_front - 0.02), GLASS_BLUE)
	for fl in range(1, FLOORS): # a white transom at every floor across the slot, two mullions
		rb(b, t, Vector3(slot_w, 0.18, 0.2), Vector3(bx_mid, fl * FLOOR_H + 0.1, b_front - 0.08), WHITE, 0.02)
		_maybe_lit(glow, t, Vector3(bx_mid, fl * FLOOR_H + 1.7, b_front - 0.06), Vector2(slot_w - 0.4, 2.4), 37, fl, 0)
	for mx in [-slot_w * 0.5, -slot_w / 6.0, slot_w / 6.0, slot_w * 0.5]:
		rb(b, t, Vector3(0.16 if absf(mx) < slot_w * 0.4 else 0.4, ROOF_Y - FLOOR_H * 1.5, 0.22), Vector3(bx_mid + mx, FLOOR_H + (ROOF_Y - FLOOR_H * 1.5) * 0.5, b_front - 0.1), WHITE, 0.03)
	# The sign: a lit box with the lettering (the map's Label3D at SIGN_AT) and the round logo.
	rb(b, t, Vector3(slot_w + 2.4, 2.2, 0.3), Vector3(bx_mid, SIGN_AT.y, b_front - 0.12), WHITE_SHADE, 0.04)
	glow.rbox(Vector3(slot_w + 1.8, 0.06, 0.06), Vector3(bx_mid, SIGN_AT.y - 1.1, b_front - 0.3), Color.WHITE, 0.01, Basis.IDENTITY, t)
	b.rcyl(0.7, 0.12, Vector3(bx_mid - slot_w * 0.5 - 0.6, SIGN_AT.y, b_front - 0.3), MeshKit.surf(Color("2a6ad8"), MeshKit.PAINT), 20, 0.03, Basis(Vector3.RIGHT, PI * 0.5), t)
	b.rcyl(0.42, 0.14, Vector3(bx_mid - slot_w * 0.5 - 0.6, SIGN_AT.y, b_front - 0.32), WHITE, 20, 0.03, Basis(Vector3.RIGHT, PI * 0.5), t)
	solid.append([Vector3(bx_mid, b_h * 0.5, mid_z - B_OUT * 0.5), Vector3(B.y - B.x, b_h, depth + B_OUT)])
	# Body C: wide, a white balcony slab at every floor, blue glass bands set back between them,
	# white fins every few metres, glass rails on the balconies.
	var cx := (C.x + C.y) * 0.5
	var cw := C.y - C.x
	bx(b, t, Vector3(cw, ROOF_Y, depth), Vector3(cx, ROOF_Y * 0.5, mid_z), WHITE_SHADE)
	for fl in range(1, FLOORS):
		var y := fl * FLOOR_H
		rb(b, t, Vector3(cw + 0.4, 0.26, 1.1), Vector3(cx, y, TOWER_FRONT - 0.55), WHITE, 0.05)
		rb(b, t, Vector3(cw + 0.4, 0.9, 0.05), Vector3(cx, y + 0.58, TOWER_FRONT - 1.05), MeshKit.surf(Color("8fb0c8"), MeshKit.GLASS), 0.01)
		rb(b, t, Vector3(cw + 0.44, 0.06, 0.08), Vector3(cx, y + 1.05, TOWER_FRONT - 1.05), STEEL, 0.01)
		PrefeituraSet.glazing(b, at(t, Vector3(cx, y + 1.75, TOWER_FRONT - 0.02)), cw - 0.6, 2.6, MeshKit.hash01(41, fl, 0) < 0.25, glow)
	for k in int(cw / 4.4) + 1:
		rb(b, t, Vector3(0.3, ROOF_Y - FLOOR_H, 1.1), Vector3(C.x + k * 4.4, FLOOR_H + (ROOF_Y - FLOOR_H) * 0.5, TOWER_FRONT - 0.55), WHITE, 0.04)
	for fl in range(1, FLOORS): # the east side: a band of windows per floor
		PrefeituraSet.glazing(b, at(t, Vector3(C.y + 0.02, fl * FLOOR_H + 1.75, mid_z), -PI * 0.5), depth - 4.0, 1.6)
	solid.append([Vector3(cx, ROOF_Y * 0.5, mid_z), Vector3(cw, ROOF_Y, depth)])
	# The back of all three: a band of windows per floor, doors onto the fire stair's landings.
	for fl in range(1, FLOORS):
		for e: Vector2 in [A, B, C]:
			var w := e.y - e.x - 2.0
			if e == C:
				w = (STAIR_X - 3.6) - e.x - 1.0
				PrefeituraSet.glazing(b, at(t, Vector3((STAIR_X + 3.6 + e.y) * 0.5, fl * FLOOR_H + 1.75, TOWER_BACK + 0.02), PI), e.y - STAIR_X - 4.6, 1.6)
				PrefeituraSet.glazing(b, at(t, Vector3((e.x + STAIR_X - 3.6) * 0.5, fl * FLOOR_H + 1.75, TOWER_BACK + 0.02), PI), w, 1.6)
			else:
				PrefeituraSet.glazing(b, at(t, Vector3((e.x + e.y) * 0.5, fl * FLOOR_H + 1.75, TOWER_BACK + 0.02), PI), w, 1.6)
		MiranteSet.door(b, at(t, Vector3(STAIR_X - 2.6, fl * FLOOR_H + 0.05, TOWER_BACK + 0.04), PI), 0.9, 2.1, Color("8a2a22cc"), WHITE_SHADE)
	# Ground floor along the front: dark glass behind the bay, the entrance doors, a plinth.
	rb(b, t, Vector3(C.y - A.x + 0.4, 0.4, 0.5), Vector3((A.x + C.y) * 0.5, 0.2, TOWER_FRONT - 0.2), Props.CONCRETE_DARK, 0.04)
	PrefeituraSet.glazing(b, at(t, Vector3((A.x + A.y) * 0.5 + 0.5, 1.8, TOWER_FRONT - 0.03)), A.y - A.x - 3.0, 2.6, true, glow)
	PrefeituraSet.glazing(b, at(t, Vector3(cx, 1.8, TOWER_FRONT - 0.03)), cw - 1.0, 2.6, true, glow)
	PrefeituraSet.glazing(b, at(t, Vector3(bx_mid, 1.6, b_front - 0.03)), B.y - B.x - 2.0, 3.0, true, glow)
	for k in 2: # sliding doors
		rb(b, t, Vector3(1.4, 2.4, 0.06), Vector3(bx_mid - 0.72 + k * 1.44, 1.3, b_front - 0.1), MeshKit.surf(Color("2a3a4a"), MeshKit.GLASS), 0.01)
	_bay(b, glow, t)
	_roof(b, glow, t)
	return solid


## A window band left lit, picked by a hash so every peer agrees.
static func _maybe_lit(glow: MeshKit.Builder, t: Transform3D, p: Vector3, size: Vector2, key: int, i: int, j: int) -> void:
	if MeshKit.hash01(key, i, j) < 0.22:
		glow.box(Vector3(size.x, size.y, 0.02), p + Vector3(0, 0, 0.06), Color.WHITE, Basis.IDENTITY, t)


## The ambulance bay: a long thin canopy on round steel columns along the front, its edge lit
## blue, lamps let into its soffit, and the PRONTO ATENDIMENTO sign (the map's label).
const BAY_SIGN_AT := Vector3(-24.0, 4.55, -10.3)
static func _bay(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> void:
	var cxz := Vector3(BAY.position.x + BAY.size.x * 0.5, 4.2, BAY.position.y + BAY.size.y * 0.5)
	rb(b, t, Vector3(BAY.size.x, 0.35, BAY.size.y), cxz, WHITE, 0.06)
	rb(b, t, Vector3(BAY.size.x + 0.1, 0.5, 0.2), Vector3(cxz.x, 4.25, BAY.position.y), WHITE_SHADE, 0.04)
	rb(b, t, Vector3(BAY.size.x - 0.4, 0.06, 0.08), Vector3(cxz.x, 4.05, BAY.position.y - 0.1), BAY_BLUE, 0.01)
	glow.rbox(Vector3(BAY.size.x - 0.4, 0.05, 0.05), Vector3(cxz.x, 4.05, BAY.position.y - 0.14), Color.WHITE, 0.01, Basis.IDENTITY, t)
	for k in 7:
		var x := BAY.position.x + 1.5 + k * (BAY.size.x - 3.0) / 6.0
		b.rcyl(0.18, 4.0, Vector3(x, 2.0, BAY.position.y + 1.0), WHITE_SHADE, 12, 0.03, Basis.IDENTITY, t)
		b.rcyl(0.28, 0.2, Vector3(x, 0.1, BAY.position.y + 1.0), Props.CONCRETE_DARK, 12, 0.03, Basis.IDENTITY, t)
		b.rcyl(0.16, 0.04, Vector3(x + 2.5, 4.0, cxz.z), Props.STEEL, 10, 0.01, Basis.IDENTITY, t)
		if k % 2 == 0:
			glow.rcyl(0.13, 0.03, Vector3(x + 2.5, 3.99, cxz.z), Color.WHITE, 10, 0.01, Basis.IDENTITY, t)
	rb(b, t, Vector3(9.0, 0.9, 0.2), BAY_SIGN_AT + Vector3(0, 0, 0.12), Props.RED, 0.04)


## Bay columns collide, but stand on open paving (the cells stay open).
static func bay_columns() -> Array:
	var out := []
	for k in 7:
		var x := BAY.position.x + 1.5 + k * (BAY.size.x - 3.0) / 6.0
		out.append([Vector3(x, 2.0, BAY.position.y + 1.0), Vector3(0.36, 4.0, 0.36)])
	return out


## The roof: parapets all round (a gap where the fire stair comes up), lift motor rooms, tanks,
## an antenna, and the helipad: a green square with its white H, the edge lights and a windsock.
static func _roof(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> void:
	var y := ROOF_Y
	var x0 := B.x
	var x1 := C.y
	for z in [TOWER_FRONT, TOWER_BACK]:
		if z == TOWER_BACK: # split round the stair's top landing
			rb(b, t, Vector3(STAIR_X - 3.4 - x0, 1.1, 0.25), Vector3((x0 + STAIR_X - 3.4) * 0.5, y + 0.55, z - 0.12), WHITE_SHADE, 0.04)
			rb(b, t, Vector3(x1 - (STAIR_X - 1.8), 1.1, 0.25), Vector3((x1 + STAIR_X - 1.8) * 0.5, y + 0.55, z - 0.12), WHITE_SHADE, 0.04)
		else:
			rb(b, t, Vector3(x1 - x0, 1.1, 0.25), Vector3((x0 + x1) * 0.5, y + 0.55, z + 0.12), WHITE_SHADE, 0.04)
	rb(b, t, Vector3(0.25, 1.1, TOWER_BACK - TOWER_FRONT), Vector3(x1 - 0.12, y + 0.55, (TOWER_FRONT + TOWER_BACK) * 0.5), WHITE_SHADE, 0.04)
	# Lift motor rooms on B, a water tank and condensers on C, an antenna on A.
	bx(b, t, Vector3(8.0, 3.0, 6.0), Vector3((B.x + B.y) * 0.5, y + 1.8 + 1.5, 16.0), WHITE)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(1.4, 0), Vector2(1.4, 2.4), Vector2(1.2, 2.7), Vector2(0, 2.8)]), Vector3(-11.5, y, 20.0), WHITE_SHADE, 16, Basis.IDENTITY, t)
	for k in 3:
		var p := Vector3(-28.0, y + 0.5, 6.5 + k * 1.6)
		rb(b, t, Vector3(1.2, 1.0, 1.0), p, PrefeituraSet.FRAME_DARK.lightened(0.5), 0.05)
		b.rcyl(0.38, 0.05, p + Vector3(0, 0.51, 0), Props.DARK, 14, 0.01, Basis.IDENTITY, t)
	b.taper(0.12, 0.04, 8.0, Vector3(-48.0, ROOF_Y + FLOOR_H + 0.5, 14.0), STEEL, 6, Basis.IDENTITY, t)
	glow.rcyl(0.12, 0.2, Vector3(-48.0, ROOF_Y + FLOOR_H + 8.6, 14.0), Color.WHITE, 8, 0.03, Basis.IDENTITY, t)
	# The helipad.
	var pad := PAD_AT
	rb(b, t, Vector3(PAD_HALF * 2.0, 0.12, PAD_HALF * 2.0), pad + Vector3(0, 0.06, 0), PAD_GREEN, 0.04)
	rb(b, t, Vector3(PAD_HALF * 2.0 - 0.5, 0.02, 0.25), pad + Vector3(0, 0.13, -PAD_HALF + 0.4), MiranteSet.PAINT_WHITE, 0.005)
	rb(b, t, Vector3(PAD_HALF * 2.0 - 0.5, 0.02, 0.25), pad + Vector3(0, 0.13, PAD_HALF - 0.4), MiranteSet.PAINT_WHITE, 0.005)
	for sx in [-1.0, 1.0]:
		rb(b, t, Vector3(0.25, 0.02, PAD_HALF * 2.0 - 0.5), pad + Vector3(sx * (PAD_HALF - 0.4), 0.13, 0), MiranteSet.PAINT_WHITE, 0.005)
		rb(b, t, Vector3(0.8, 0.02, 4.4), pad + Vector3(sx * 1.4, 0.13, 0), MiranteSet.PAINT_WHITE, 0.005)
	rb(b, t, Vector3(2.0, 0.02, 0.8), pad + Vector3(0, 0.13, 0), MiranteSet.PAINT_WHITE, 0.005)
	for k in 12:
		var a := TAU * k / 12.0
		var p := pad + Vector3(clampf(cos(a) * 1.5, -1.0, 1.0) * PAD_HALF, 0.12, clampf(sin(a) * 1.5, -1.0, 1.0) * PAD_HALF)
		b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.09, 0), Vector2(0.07, 0.12), Vector2(0, 0.14)]), p, STEEL, 8, Basis.IDENTITY, t)
		glow.lathe(PackedVector2Array([Vector2(0, 0.1), Vector2(0.05, 0.1), Vector2(0.04, 0.16), Vector2(0, 0.17)]), p, Color.WHITE, 8, Basis.IDENTITY, t)
	var sock := pad + Vector3(PAD_HALF + 1.5, 0, PAD_HALF - 1.0)
	b.rcyl(0.05, 4.5, sock + Vector3(0, 2.25, 0), STEEL, 8, 0.01, Basis.IDENTITY, t)
	var bend := Basis(Vector3.FORWARD, -1.25) * Basis(Vector3.UP, 0.4)
	b.lathe(PackedVector2Array([Vector2(0.3, 0), Vector2(0.22, 0.6), Vector2(0.16, 1.2), Vector2(0.12, 1.6)]), sock + Vector3(0, 4.4, 0), MeshKit.surf(Color("e0602a"), MeshKit.PAINT), 10, bend, t)


## The roof's parapets as colliders (with the gap over the stair).
static func roof_colliders() -> Array:
	var y := ROOF_Y + 0.55
	return [
		[Vector3((B.x + C.y) * 0.5, y, TOWER_FRONT + 0.12), Vector3(C.y - B.x, 1.1, 0.25)],
		[Vector3((B.x + STAIR_X - 3.4) * 0.5, y, TOWER_BACK - 0.12), Vector3(STAIR_X - 3.4 - B.x, 1.1, 0.25)],
		[Vector3((C.y + STAIR_X - 1.8) * 0.5, y, TOWER_BACK - 0.12), Vector3(C.y - (STAIR_X - 1.8), 1.1, 0.25)],
		[Vector3(C.y - 0.12, y, (TOWER_FRONT + TOWER_BACK) * 0.5), Vector3(0.25, 1.1, TOWER_BACK - TOWER_FRONT)],
		[Vector3((B.x + B.y) * 0.5, ROOF_Y + 1.8 + 1.5, 16.0), Vector3(8.0, 3.0, 6.0)],
		[PAD_AT + Vector3(0, 0.06, 0), Vector3(PAD_HALF * 2.0, 0.12, PAD_HALF * 2.0)],
	]


# --- The fire stair -------------------------------------------------------------------------

## A steel fire stair on the back wall, from the yard to the roof, its frame `f` on the wall plane
## at the stair's middle, facing out (+Z away from the wall). Each floor: a flight along the outside
## rising half a floor east, a landing, a flight along the wall back west, the floor's landing with
## its door. Flights are ramps underfoot (treads drawn on them). Returns colliders with their basis.
static func fire_stair(b: MeshKit.Builder, f: Transform3D) -> Array:
	var solid := []
	var half := FLOOR_H * 0.5
	var r := STAIR_RUN * 0.5
	var z_out := 2.1
	var z_in := 0.85
	var land_x := r + 0.5
	for fl in FLOORS:
		var y := fl * FLOOR_H
		_flight(b, f, solid, Vector3(-r, y, z_out), Vector3(r, y + half, z_out))
		_landing(b, f, solid, Vector3(land_x, y + half, 1.5))
		_flight(b, f, solid, Vector3(r, y + half, z_in), Vector3(-r, y + FLOOR_H, z_in))
		_landing(b, f, solid, Vector3(-land_x, y + FLOOR_H, 1.5))
	# Posts at the corners up the whole height, braced; a rail along the outside of every landing.
	for px in [-land_x - 0.45, land_x + 0.45]:
		for pz in [0.15, 2.8]:
			rb(b, f, Vector3(0.14, ROOF_Y + 1.1, 0.14), Vector3(px, (ROOF_Y + 1.1) * 0.5, pz), STEEL, 0.02)
		solid.append([Vector3(px, (ROOF_Y + 1.1) * 0.5, 2.8), Vector3(0.14, ROOF_Y + 1.1, 0.14)])
	# Rails round the outside of every landing: along its far end (x) and its outer edge (z).
	for fl in FLOORS + 1:
		for s in [-1.0, 1.0]:
			var y := fl * FLOOR_H + (half if s > 0.0 else 0.0)
			if y > ROOF_Y + 0.1 or y < 0.1:
				continue
			var x_end: float = s * (land_x + 0.46)
			var x_in: float = s * (land_x - 0.5)
			b.tube(PackedVector3Array([Vector3(x_end, y + 1.0, 0.2), Vector3(x_end, y + 1.0, 2.8), Vector3(x_in, y + 1.0, 2.8)]), 0.03, STEEL, 6, -1.0, f)
			b.tube(PackedVector3Array([Vector3(x_end, y + 0.5, 0.2), Vector3(x_end, y + 0.5, 2.8), Vector3(x_in, y + 0.5, 2.8)]), 0.02, STEEL, 6, -1.0, f)
			solid.append([Vector3(x_end, y + 0.5, 1.5), Vector3(0.08, 1.0, 2.6)])
			solid.append([Vector3(s * land_x, y + 0.5, 2.8), Vector3(1.0, 1.0, 0.08)])
	return solid


static func _flight(b: MeshKit.Builder, f: Transform3D, solid: Array, p0: Vector3, p1: Vector3) -> void:
	var basis := Basis.looking_at((p1 - p0).normalized(), Vector3.UP)
	var length := p0.distance_to(p1)
	var mid := (p0 + p1) * 0.5 + basis * Vector3(0, -0.08, 0)
	rb(b, f, Vector3(STAIR_W, 0.16, length + 0.1), mid, STEEL.darkened(0.2), 0.02, basis)
	solid.append([mid, Vector3(STAIR_W, 0.16, length + 0.1), basis])
	var dir := Vector3(p1.x - p0.x, 0, p1.z - p0.z).normalized()
	var flat := Basis.looking_at(dir, Vector3.UP)
	var steps := ceili((p1.y - p0.y) / 0.18)
	for k in steps:
		var q := p0.lerp(p1, (k + 0.5) / steps) + Vector3(0, 0.02, 0)
		rb(b, f, Vector3(STAIR_W - 0.1, 0.05, absf(p1.x - p0.x) / steps * 0.6), q, STEEL, 0.01, flat)
		rb(b, f, Vector3(STAIR_W - 0.1, 0.02, 0.04), q - dir * (absf(p1.x - p0.x) / steps * 0.3) + Vector3(0, 0.025, 0), SAFETY, 0.005, flat)
	for s in [-1.0, 1.0]: # stringers and a hand rail on the outer side
		var off := Vector3(0, 0, s * (STAIR_W * 0.5 - 0.04))
		rb(b, f, Vector3(0.06, 0.3, length + 0.1), mid + off + Vector3(0, -0.06, 0), STEEL.darkened(0.3), 0.01, basis)
	var out := Vector3(0, 0, (STAIR_W * 0.5 - 0.04) * (1.0 if p0.z > 1.5 else -1.0))
	b.tube(PackedVector3Array([p0 + out + Vector3(0, 1.0, 0), p1 + out + Vector3(0, 1.0, 0)]), 0.03, STEEL, 6, -1.0, f)
	b.tube(PackedVector3Array([p0 + out + Vector3(0, 0.5, 0), p1 + out + Vector3(0, 0.5, 0)]), 0.02, STEEL, 6, -1.0, f)
	if p0.z > 1.5:
		solid.append([(p0 + p1) * 0.5 + out + Vector3(0, 0.5, 0), Vector3(0.08, 1.0, length), basis])


static func _landing(b: MeshKit.Builder, f: Transform3D, solid: Array, c: Vector3) -> void:
	rb(b, f, Vector3(1.0, 0.14, 2.7), c + Vector3(0, -0.07, 0), STEEL.darkened(0.2), 0.02)
	for k in 5: # grating bars
		rb(b, f, Vector3(0.9, 0.02, 0.04), c + Vector3(0, 0.01, -1.1 + k * 0.55), STEEL, 0.005)
	solid.append([c + Vector3(0, -0.07, 0), Vector3(1.0, 0.14, 2.7)])


## World-free: the way up the stair in the frame of the stair, landing by landing (for the bot,
## and a test that walks it).
static func stair_points() -> Array:
	var out := []
	var r := STAIR_RUN * 0.5
	var land_x := r + 0.5
	out.append(Vector3(-r - 1.0, 0, 2.1))
	for fl in FLOORS:
		var y := fl * FLOOR_H
		out.append(Vector3(land_x, y + FLOOR_H * 0.5, 1.5))
		out.append(Vector3(-land_x, y + FLOOR_H, 1.5))
	return out


# --- The old wing, the annex and the house on the street ----------------------------------

## The old wing on the street, its front at z = 0 of `f`, `w` wide (centred), four floors: white
## plaster ends with ledges, and between them the dark vertical concrete fins in front of brown
## glass that flare out at their feet. The name and logo high on the left end. Returns colliders.
const WING_H := 4 * 3.4
static func old_wing(b: MeshKit.Builder, glow: MeshKit.Builder, f: Transform3D, w: float, d: float) -> Array:
	var h := WING_H
	bx(b, f, Vector3(w, h, d), Vector3(0, h * 0.5, d * 0.5), WHITE)
	var end_w := 8.0
	var mid0 := -w * 0.5 + end_w
	var mid1 := w * 0.5 - 6.0
	bx(b, f, Vector3(mid1 - mid0, h - 2.0, 0.06), Vector3((mid0 + mid1) * 0.5, 1.0 + (h - 2.0) * 0.5, -0.02), GLASS_BROWN)
	var fins := int((mid1 - mid0) / 1.9)
	for k in fins + 1:
		var x := mid0 + k * (mid1 - mid0) / fins
		rb(b, f, Vector3(0.32, h - 1.6, 1.1), Vector3(x, 1.6 + (h - 1.6) * 0.5, -0.55), FIN, 0.05)
		b.frustum(Vector2(0.5, 2.2), Vector2(0.32, 1.1), 1.6, Vector3(x, 0, -0.9), FIN.darkened(0.1), Basis.IDENTITY, f, Vector2(0, 0.35))
		rb(b, f, Vector3(0.4, 0.12, 0.3), Vector3(x, 1.2 + 3.4 * float(k % 3), -1.0), Color("c8c0a8"), 0.02)  # the light stone inserts
	for e in [[-w * 0.5 + end_w * 0.5, end_w], [w * 0.5 - 3.0, 6.0]]:
		var ex: float = e[0]
		var ew: float = e[1]
		for fl in 4:
			var y := fl * 3.4
			rb(b, f, Vector3(ew + 0.3, 0.2, 0.7), Vector3(ex, y + 3.3, -0.3), WHITE_SHADE, 0.04)  # ledges
			if fl > 0:
				MiranteSet.window(b, at(f, Vector3(ex, y + 1.7, -0.02)), ew - 3.0, 1.4, WHITE_SHADE)
				_maybe_lit(glow, f, Vector3(ex, y + 1.7, -0.06), Vector2(ew - 3.2, 1.2), 53, fl, int(ex))
	MiranteSet.ac_unit(b, at(f, Vector3(mid0 + 2.0, 2.3, -1.4)))
	rb(b, f, Vector3(w + 0.4, 0.4, d + 0.4), Vector3(0, h + 0.2, d * 0.5), WHITE_SHADE, 0.05)
	for k in 6: # the rail along the roof
		b.rcyl(0.03, 1.0, Vector3(-w * 0.5 + 1.0 + k * (w - 2.0) / 5.0, h + 0.9, 0.2), STEEL, 6, 0.01, Basis.IDENTITY, f)
	b.tube(PackedVector3Array([Vector3(-w * 0.5 + 1.0, h + 1.4, 0.2), Vector3(w * 0.5 - 1.0, h + 1.4, 0.2)]), 0.03, STEEL, 6, -1.0, f)
	b.rcyl(0.9, 0.1, Vector3(-w * 0.5 + end_w * 0.5 - 2.0, h - 2.2, -0.08), MeshKit.surf(Color("2a6ad8"), MeshKit.PAINT), 20, 0.03, Basis(Vector3.RIGHT, PI * 0.5), f)
	b.rcyl(0.55, 0.12, Vector3(-w * 0.5 + end_w * 0.5 - 2.0, h - 2.2, -0.1), WHITE, 20, 0.03, Basis(Vector3.RIGHT, PI * 0.5), f)
	# Steps up to the old entrance under the fins, with a rail.
	for k in 3:
		rb(b, f, Vector3(4.0, 0.15, 0.4), Vector3(mid0 + 4.0, 0.075 + k * 0.15, -1.9 + k * 0.4), Props.CONCRETE, 0.02)
	return [[Vector3(0, h * 0.5, d * 0.5), Vector3(w, h, d)]]


## The green-banded annex: three floors of olive panels between white bands, square windows.
static func annex(b: MeshKit.Builder, glow: MeshKit.Builder, f: Transform3D, w: float, d: float) -> Array:
	var h := 3 * 3.4
	bx(b, f, Vector3(w, h, d), Vector3(0, h * 0.5, d * 0.5), WHITE)
	for fl in 3:
		var y := fl * 3.4
		rb(b, f, Vector3(w + 0.2, 0.35, 0.3), Vector3(0, y + 3.25, -0.1), WHITE, 0.04)
		rb(b, f, Vector3(w + 0.1, 1.1, 0.12), Vector3(0, y + 0.9, -0.08), OLIVE, 0.03)
		var n := int(w / 3.2)
		for k in n:
			var x := -w * 0.5 + (k + 0.5) * w / n
			MiranteSet.window(b, at(f, Vector3(x, y + 2.25, -0.04)), 1.3, 1.2, WHITE_SHADE)
			_maybe_lit(glow, f, Vector3(x, y + 2.25, -0.08), Vector2(1.2, 1.1), 59, fl, k)
	rb(b, f, Vector3(w + 0.3, 0.5, d + 0.3), Vector3(0, h + 0.25, d * 0.5), WHITE_SHADE, 0.05)
	MiranteSet.downpipe(b, f, Vector3(w * 0.5 - 0.3, h, -0.2), Vector3(w * 0.5 - 0.3, 0, -0.2), WHITE_SHADE)
	return [[Vector3(0, h * 0.5, d * 0.5), Vector3(w, h, d)]]


## The little old house kept between the buildings: one storey, a tiled gable roof, a porch.
static func house(b: MeshKit.Builder, f: Transform3D, w: float, d: float) -> Array:
	var h := 3.4
	bx(b, f, Vector3(w, h, d), Vector3(0, h * 0.5, d * 0.5), Color("e8dcc0"))
	rb(b, f, Vector3(w + 0.1, 0.5, d + 0.1), Vector3(0, 0.25, d * 0.5), Color("b8a888"), 0.04)
	b.frustum(Vector2(w + 0.8, d + 0.8), Vector2(w + 0.8, 0.0), 2.4, Vector3(0, h, d * 0.5), TILE_ROOF, Basis.IDENTITY, f)
	for k in 3:
		MiranteSet.window(b, at(f, Vector3(-w * 0.5 + 1.8 + k * (w - 3.6) / 2.0, 1.8, -0.02)), 1.1, 1.3, MiranteSet.PAINT_WHITE)
	MiranteSet.door(b, at(f, Vector3(w * 0.25, 0.5, -0.03)), 0.9, 2.1, Color("5a3a26cc"))
	return [[Vector3(0, h * 0.5, d * 0.5), Vector3(w, h, d)]]


# --- Small things ----------------------------------------------------------------------------

## A wheelchair, facing -Z: two big wheels, small casters, the seat and the push handles.
static func wheelchair(b: MeshKit.Builder, t: Transform3D, tipped := false) -> Array:
	var k := t * Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(0.3, 0.3, 0)) if tipped else t
	for s in [-0.3, 0.3]:
		b.lathe(PackedVector2Array([Vector2(0.3, -0.02), Vector2(0.3, 0.02)]), Vector3(s, 0.3, 0.05), Props.TYRE, 16, Basis(Vector3.FORWARD, PI * 0.5), k)
		b.tube(MeshKit.arc(Vector3(s, 0.3, -0.25), Vector3(s, 0.6, 0.05), Vector3(s, 0.3, 0.35)), 0.012, STEEL, 4, -1.0, k)
		b.rcyl(0.06, 0.03, Vector3(s * 0.85, 0.06, -0.35), Props.TYRE, 8, 0.01, Basis(Vector3.FORWARD, PI * 0.5), k)
		b.tube(PackedVector3Array([Vector3(s * 0.85, 0.1, -0.35), Vector3(s * 0.85, 0.5, -0.3), Vector3(s * 0.85, 0.95, 0.3), Vector3(s * 0.85, 1.0, 0.42)]), 0.015, STEEL, 5, -1.0, k)
	rb(b, k, Vector3(0.48, 0.05, 0.44), Vector3(0, 0.5, 0.0), Color("1e2a3a"), 0.02)
	rb(b, k, Vector3(0.48, 0.42, 0.04), Vector3(0, 0.74, 0.24), Color("1e2a3a"), 0.02, Basis(Vector3.RIGHT, -0.12))
	return []


## A drip stand: five-legged foot on casters, the pole, the hook, a bag.
static func drip_stand(b: MeshKit.Builder, t: Transform3D) -> Array:
	for i in 5:
		var a := TAU * i / 5.0
		b.tube(PackedVector3Array([Vector3(0, 0.1, 0), Vector3(cos(a) * 0.3, 0.06, sin(a) * 0.3)]), 0.012, STEEL, 4, -1.0, t)
		b.rcyl(0.025, 0.03, Vector3(cos(a) * 0.3, 0.03, sin(a) * 0.3), Props.TYRE, 6, 0.008, Basis.IDENTITY, t)
	b.rcyl(0.012, 1.8, Vector3(0, 1.0, 0), STEEL, 6, 0.004, Basis.IDENTITY, t)
	b.tube(MeshKit.arc(Vector3(-0.15, 1.85, 0), Vector3(0, 1.95, 0), Vector3(0.15, 1.85, 0)), 0.01, STEEL, 4, -1.0, t)
	b.blob(Vector3(0.08, 0.13, 0.03), Vector3(0.15, 1.7, 0), MeshKit.surf(Color("c8e0e8"), MeshKit.GLASS), 3, 0.05, 4, 6, Basis.IDENTITY, t)
	return []


## The oxygen tank in the yard: a tall white vessel on legs, a fenced pad, pipework, a hazard sign.
static func oxygen_tank(b: MeshKit.Builder, t: Transform3D) -> Array:
	rb(b, t, Vector3(5.0, 0.2, 5.0), Vector3(0, 0.1, 0), Props.CONCRETE, 0.04)
	for i in 4:
		var a := TAU * (i + 0.5) / 4.0
		b.rcyl(0.08, 1.6, Vector3(cos(a) * 0.9, 1.0, sin(a) * 0.9), STEEL, 8, 0.02, Basis.IDENTITY, t)
	b.lathe(PackedVector2Array([Vector2(0, 1.4), Vector2(0.8, 1.5), Vector2(1.1, 1.9), Vector2(1.1, 7.6), Vector2(0.8, 8.0), Vector2(0, 8.1)]), Vector3.ZERO, MiranteSet.PAINT_WHITE, 16, Basis.IDENTITY, t)
	b.tube(PackedVector3Array([Vector3(0.6, 1.6, 0.6), Vector3(1.6, 0.8, 1.6), Vector3(2.3, 0.8, 2.3)]), 0.05, STEEL, 6, -1.0, t)
	for k in 4: # the fence: posts and a mesh panel each side
		var a := TAU * k / 4.0
		var side := Vector3(cos(a), 0, sin(a)) * 2.4
		var along := Vector3(-sin(a), 0, cos(a))
		rb(b, t, Vector3(0.06, 1.8, 0.06), side + along * 2.4 + Vector3(0, 0.9, 0), STEEL, 0.01)
		var basis := Basis(Vector3.UP, -a)
		rb(b, t, Vector3(0.03, 1.6, 4.6), side + Vector3(0, 1.0, 0), MeshKit.surf(Color("7a8088"), MeshKit.METAL), 0.005, basis)
	rb(b, t, Vector3(0.5, 0.5, 0.03), Vector3(0, 1.4, -2.44), SAFETY, 0.01, Basis(Vector3.BACK, PI * 0.25))
	return [[Vector3(0, 1.0, 0), Vector3(4.8, 2.0, 4.8)]]


## A generator: a long steel housing on skids, louvres, an exhaust.
static func generator(b: MeshKit.Builder, t: Transform3D) -> Array:
	rb(b, t, Vector3(1.6, 0.15, 3.8), Vector3(0, 0.08, 0), STEEL.darkened(0.3), 0.02)
	rb(b, t, Vector3(1.5, 1.6, 3.6), Vector3(0, 0.95, 0), MeshKit.surf(Color("c8c0a0"), MeshKit.PAINT), 0.05)
	for k in 6:
		rb(b, t, Vector3(0.04, 0.05, 1.0), Vector3(0.76, 0.6 + k * 0.15, -0.8), STEEL, 0.008)
	b.tube(PackedVector3Array([Vector3(0, 1.75, 1.2), Vector3(0, 2.4, 1.2), Vector3(0, 2.6, 1.5)]), 0.09, STEEL, 8, -1.0, t)
	return [[Vector3(0, 0.9, 0), Vector3(1.6, 1.8, 3.8)]]
