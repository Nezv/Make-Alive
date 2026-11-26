class_name TerminalSet
## The pieces of the Terminal Central, like HospitalSet and PrefeituraSet: each draws into the
## Builder it is given at transform `t` and returns its solid parts as [[center, size, basis?], ...]
## in its own space. The lot's frame: -Z to the street (Rua Nove de Março), x along the platforms.
##
## From references/terminal1.png (inside on a wet day): the heavy grey concrete roof slabs with
## their deep fascias, the skylight lantern down the spine, the dark steel tree columns fanning up
## into the soffit, corrugated clerestory bands, round downlights, the platform islands with yellow
## kerbs and white barriers at their ends, the cobbled bus lanes, the yellow city buses with their
## headlights on. What's built: references/terminal_elements.md.

## Alpha is the surface class (MeshKit): cc PAINT, 99 METAL, 66 GLASS, e6 PAVERS, 1a SOOT.
const SLAB := Color("a6a8a6")
const SLAB_DARK := Color("7e817f")
const SOFFIT := Color("5d6062")
const STEEL_DARK := Color("2a2e3299")
const CORRUGATED := Color("8c939a99")
const ISLAND := Color("8d8f8ae6")
const KERB_YELLOW := Color("d6b21ecc")
const SETTS := Color("4a4c4ee6")
const LANE := Color("3c3f42")
const BUS_YELLOW := Color("e2b51ccc")
const BUS_DARK := Color("23272bcc")
const SIGN_TEXT := Color("f0ece0")

const LENGTH := 84.0                ## the platforms' length (x)
const ISLANDS := [-17.0, 3.0, 23.0] ## the islands' centres (z)
const ISLAND_W := 4.5
const ISLAND_H := 0.16
const ROOF_Z := Vector2(-22.0, 28.0)  ## the roof's extent (z)
const SOFFIT_Y := 6.2
const SLAB_T := 0.7
const SPINE_Z := 3.0                ## the skylight lantern runs over the middle island
const LANTERN_W := 4.0
const COLUMNS_X := [-36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0]
const FRONT_Z := -35.0              ## the street front of the hall and the shops
const FRONT_D := 8.0
const GATE_HALF := 13.0             ## the way in from the street, between the hall and the shops
const SIGN_AT := Vector3(0, 7.0, FRONT_Z - 0.32)


static func rb(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, r := -1.0, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, r, rot, t)


static func at(t: Transform3D, p: Vector3, yaw := 0.0) -> Transform3D:
	return t * Transform3D(Basis(Vector3.UP, yaw), p)


# --- The roof --------------------------------------------------------------------------------

## The two roof slabs either side of the lantern, their deep fascias turned down at the outer edges
## and the ends, rain streaks down them, the soffit with its downlights, the clerestory bands and
## the skylight lantern down the spine. `glow` takes the lit downlights and the lantern's glass.
static func roof(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> void:
	var y := SOFFIT_Y + SLAB_T * 0.5
	var lz0 := SPINE_Z - LANTERN_W * 0.5
	var lz1 := SPINE_Z + LANTERN_W * 0.5
	for half: Vector2 in [Vector2(ROOF_Z.x, lz0), Vector2(lz1, ROOF_Z.y)]:
		var mid := (half.x + half.y) * 0.5
		var depth := half.y - half.x
		rb(b, t, Vector3(LENGTH + 4.0, SLAB_T, depth), Vector3(0, y, mid), SLAB, 0.08)
		rb(b, t, Vector3(LENGTH + 3.6, 0.05, depth - 0.4), Vector3(0, SOFFIT_Y - 0.02, mid), SOFFIT, 0.01)
		# The haunch: the slab thickens toward the spine, as the shells in the photo do.
		var inner := half.y if half.y <= SPINE_Z else half.x
		var dir := -1.0 if half.y <= SPINE_Z else 1.0
		b.frustum(Vector2(LENGTH + 3.6, 3.0), Vector2(LENGTH + 3.6, 0.1), 0.9, Vector3(0, SOFFIT_Y - 0.9, inner + dir * 1.5), SOFFIT,
			Basis(Vector3.RIGHT, PI), t, Vector2(0, dir * 1.4))
		# Downlights in rows along the soffit, a few still on.
		for k in 12:
			for row in [mid - depth * 0.25, mid + depth * 0.25]:
				var p := Vector3(-LENGTH * 0.5 + 3.5 + k * (LENGTH - 7.0) / 11.0, SOFFIT_Y - 0.05, row)
				b.rcyl(0.24, 0.06, p, Props.STEEL, 12, 0.02, Basis.IDENTITY, t)
				if MeshKit.hash01(71, k, int(row)) < 0.45:
					glow.rcyl(0.18, 0.02, p - Vector3(0, 0.04, 0), Color.WHITE, 12, 0.01, Basis.IDENTITY, t)
	# The deep fascias: outer edges and the two ends, with the rain's dark streaks.
	for z in [ROOF_Z.x, ROOF_Z.y]:
		var s := -1.0 if z < SPINE_Z else 1.0
		rb(b, t, Vector3(LENGTH + 4.4, 1.9, 0.5), Vector3(0, SOFFIT_Y + 0.25, z + s * 0.2), SLAB, 0.1)
		rb(b, t, Vector3(LENGTH + 4.5, 0.2, 0.6), Vector3(0, SOFFIT_Y + 1.25, z + s * 0.2), SLAB_DARK, 0.05)
		for k in 26:
			var x := -LENGTH * 0.5 + 1.0 + k * (LENGTH - 2.0) / 25.0 + MeshKit.hash01(73, k, int(z)) * 2.0
			var h := 0.6 + MeshKit.hash01(74, k, int(z)) * 1.1
			rb(b, t, Vector3(0.3 + MeshKit.hash01(75, k, 0) * 0.6, h, 0.02), Vector3(x, SOFFIT_Y + 1.15 - h * 0.5, z + s * 0.46), SLAB_DARK.darkened(0.15), 0.005)
	for x in [-(LENGTH + 4.0) * 0.5, (LENGTH + 4.0) * 0.5]:
		rb(b, t, Vector3(0.5, 1.9, ROOF_Z.y - ROOF_Z.x + 0.9), Vector3(x, SOFFIT_Y + 0.25, (ROOF_Z.x + ROOF_Z.y) * 0.5), SLAB, 0.1)
	# The lantern: two clerestory bands of corrugated sheet, steel frames and glass above them.
	var top := SOFFIT_Y + SLAB_T
	for z in [lz0, lz1]:
		rb(b, t, Vector3(LENGTH, 1.1, 0.12), Vector3(0, top + 0.55, z), CORRUGATED, 0.01)
		for k in int(LENGTH / 0.3):
			rb(b, t, Vector3(0.06, 1.1, 0.05), Vector3(-LENGTH * 0.5 + 0.15 + k * 0.3, top + 0.55, z + (0.07 if z > SPINE_Z else -0.07)), CORRUGATED.darkened(0.15), 0.005)
	var glass_y := top + 1.1
	for k in 15:
		var x := -LENGTH * 0.5 + k * LENGTH / 14.0
		rb(b, t, Vector3(0.18, 1.4, LANTERN_W + 0.2), Vector3(x, glass_y + 0.7, SPINE_Z), STEEL_DARK, 0.02)
	for z in [lz0, lz1]:
		rb(b, t, Vector3(LENGTH, 1.3, 0.04), Vector3(0, glass_y + 0.65, z), MeshKit.surf(Color("9ab4c0"), MeshKit.GLASS), 0.005)
		glow.box(Vector3(LENGTH - 1.0, 1.1, 0.02), Vector3(0, glass_y + 0.65, z + (0.05 if z > SPINE_Z else -0.05)), Color(0.55, 0.6, 0.62), Basis.IDENTITY, t)
	rb(b, t, Vector3(LENGTH + 0.4, 0.25, LANTERN_W + 0.6), Vector3(0, glass_y + 1.45, SPINE_Z), SLAB_DARK, 0.04)
	# Inside the lantern's well: the steel trusses spanning the gap.
	for k in 8:
		var x := -LENGTH * 0.5 + 5.0 + k * (LENGTH - 10.0) / 7.0
		b.tube(PackedVector3Array([Vector3(x, SOFFIT_Y + 0.2, lz0), Vector3(x, top + 1.0, SPINE_Z), Vector3(x, SOFFIT_Y + 0.2, lz1)]), 0.08, STEEL_DARK, 6, -1.0, t)
		rb(b, t, Vector3(0.14, 0.14, LANTERN_W), Vector3(x, SOFFIT_Y + 0.2, SPINE_Z), STEEL_DARK, 0.02)


## A tree column on an island: a stout dark post, a collar, and four struts fanning up to the soffit.
static func tree_column(b: MeshKit.Builder, t: Transform3D) -> Array:
	b.rcyl(0.32, 0.25, Vector3(0, 0.125, 0), Props.CONCRETE_DARK, 12, 0.04, Basis.IDENTITY, t)
	b.rcyl(0.2, 3.3, Vector3(0, 1.9, 0), STEEL_DARK, 10, 0.03, Basis.IDENTITY, t)
	b.rcyl(0.3, 0.35, Vector3(0, 3.6, 0), STEEL_DARK, 10, 0.04, Basis.IDENTITY, t)
	for i in 4:
		var a := TAU * (i + 0.5) / 4.0
		var tip := Vector3(cos(a) * 2.6, SOFFIT_Y - 0.1, sin(a) * 1.6)
		b.tube(PackedVector3Array([Vector3(0, 3.7, 0), Vector3(cos(a) * 1.2, 5.0, sin(a) * 0.75), tip]), 0.11, STEEL_DARK, 6, 0.08, t)
		b.rcyl(0.22, 0.08, tip + Vector3(0, 0.04, 0), STEEL_DARK, 8, 0.02, Basis.IDENTITY, t)
	b.tube(PackedVector3Array([Vector3(-1.9, 5.3, 0), Vector3(1.9, 5.3, 0)]), 0.05, STEEL_DARK, 6, -1.0, t)
	return [[Vector3(0, 1.8, 0), Vector3(0.45, 3.6, 0.45)]]


# --- The islands and lanes ------------------------------------------------------------------

## A platform island, `length` long along x: raised pavers, yellow-painted kerbs, white barriers
## at both ends, benches, bins, a timetable board, the round stop signs and a clock in the middle.
static func island(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D, length: float, key: int) -> Array:
	var solid := []
	rb(b, t, Vector3(length, ISLAND_H, ISLAND_W), Vector3(0, ISLAND_H * 0.5, 0), ISLAND, 0.02)
	for s in [-1.0, 1.0]:
		rb(b, t, Vector3(length, ISLAND_H + 0.02, 0.25), Vector3(0, (ISLAND_H + 0.02) * 0.5, s * (ISLAND_W * 0.5 - 0.12)), KERB_YELLOW, 0.02)
		for k in int(length / 1.2):  # joints in the pavers
			rb(b, t, Vector3(0.02, 0.01, ISLAND_W - 0.6), Vector3(-length * 0.5 + 0.6 + k * 1.2, ISLAND_H + 0.004, 0), ISLAND.darkened(0.18), 0.002)
	for e in [-1.0, 1.0]:  # the ends: white concrete barriers across, a dropped kerb
		var bt := at(t, Vector3(e * (length * 0.5 + 0.9), 0, 0))
		rb(b, bt, Vector3(0.7, 0.35, ISLAND_W), Vector3(0, 0.175, 0), Color("dcdcd4"), 0.05)
		rb(b, bt, Vector3(0.45, 0.6, ISLAND_W - 0.1), Vector3(0, 0.65, 0), Color("e6e6de"), 0.06)
		for z in [-1.4, 0.0, 1.4]:
			rb(b, bt, Vector3(0.47, 0.12, 0.6), Vector3(0, 0.75, z), Color("b8342acc"), 0.02)
		solid.append([Vector3(e * (length * 0.5 + 0.9), 0.5, 0), Vector3(0.7, 1.0, ISLAND_W)])
	for k in 4:  # benches back to back
		var x := -length * 0.5 + 8.0 + k * (length - 16.0) / 3.0
		for s in [-1.0, 1.0]:
			bench(b, at(t, Vector3(x + 3.0, ISLAND_H, s * 0.55), 0.0 if s > 0.0 else PI))
		bin(b, at(t, Vector3(x - 1.0, ISLAND_H, 0)))
	for k in 3:  # round stop signs and timetables
		var x := -length * 0.5 + 6.0 + k * (length - 12.0) / 2.0
		stop_sign(b, glow, at(t, Vector3(x, ISLAND_H, -ISLAND_W * 0.5 + 0.6)), key * 10 + k)
		stop_sign(b, glow, at(t, Vector3(x + 2.0, ISLAND_H, ISLAND_W * 0.5 - 0.6), PI), key * 10 + k + 5)
	clock(b, glow, at(t, Vector3(4.5, ISLAND_H, 0)))
	return solid


static func bench(b: MeshKit.Builder, t: Transform3D) -> void:
	for x in [-0.8, 0.8]:
		rb(b, t, Vector3(0.06, 0.42, 0.42), Vector3(x, 0.21, 0), STEEL_DARK, 0.01)
	for k in 3:
		rb(b, t, Vector3(1.9, 0.04, 0.11), Vector3(0, 0.44, -0.14 + k * 0.14), Props.STEEL, 0.01)
	rb(b, t, Vector3(1.9, 0.3, 0.03), Vector3(0, 0.66, 0.2), Props.STEEL, 0.01, Basis(Vector3.RIGHT, -0.15))


static func bin(b: MeshKit.Builder, t: Transform3D) -> void:
	b.rcyl(0.05, 0.9, Vector3(0, 0.45, 0), STEEL_DARK, 8, 0.01, Basis.IDENTITY, t)
	b.lathe(PackedVector2Array([Vector2(0, 0.35), Vector2(0.22, 0.35), Vector2(0.25, 0.85), Vector2(0.23, 0.88), Vector2(0, 0.88)]), Vector3.ZERO, Color("2f5a3acc"), 14, Basis.IDENTITY, t)


## The round blue stop sign on its post with the timetable panel lit beneath it.
static func stop_sign(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D, key: int) -> void:
	b.rcyl(0.04, 2.9, Vector3(0, 1.45, 0), Props.STEEL, 8, 0.01, Basis.IDENTITY, t)
	b.rcyl(0.3, 0.04, Vector3(0, 2.7, -0.03), Color("1f4fa0cc"), 18, 0.01, Basis(Vector3.RIGHT, PI * 0.5), t)
	b.rcyl(0.2, 0.05, Vector3(0, 2.7, -0.04), Color.WHITE, 18, 0.01, Basis(Vector3.RIGHT, PI * 0.5), t)
	rb(b, t, Vector3(0.18, 0.04, 0.02), Vector3(0, 2.7, -0.07), Color("1f4fa0cc"), 0.005)
	rb(b, t, Vector3(0.5, 0.7, 0.06), Vector3(0, 1.4, -0.05), Props.STEEL, 0.01)
	if MeshKit.hash01(77, key, 0) < 0.6:
		glow.box(Vector3(0.42, 0.6, 0.01), Vector3(0, 1.4, -0.09), Color(0.9, 0.92, 0.85), Basis.IDENTITY, t)
	else:
		rb(b, t, Vector3(0.42, 0.6, 0.01), Vector3(0, 1.4, -0.085), Color("d8d8cc"), 0.003)


## The station clock: a double face on a tall post, stopped.
static func clock(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> void:
	b.rcyl(0.07, 3.6, Vector3(0, 1.8, 0), STEEL_DARK, 10, 0.02, Basis.IDENTITY, t)
	b.rcyl(0.5, 0.18, Vector3(0, 3.95, 0), STEEL_DARK, 24, 0.04, Basis(Vector3.RIGHT, PI * 0.5), t)
	for s in [-1.0, 1.0]:
		glow.rcyl(0.43, 0.02, Vector3(0, 3.95, s * 0.095), Color(0.95, 0.95, 0.9), 24, 0.005, Basis(Vector3.RIGHT, PI * 0.5), t)
		for h in 12:
			var a := TAU * h / 12.0
			rb(b, t, Vector3(0.03, 0.08, 0.01), Vector3(sin(a) * 0.36, 3.95 + cos(a) * 0.36, s * 0.11), Props.DARK, 0.003, Basis(Vector3.BACK, -a))
		rb(b, t, Vector3(0.025, 0.26, 0.01), Vector3(0.09, 3.99, s * 0.115), Props.DARK, 0.003, Basis(Vector3.BACK, -0.9))  # stopped at 7:40
		rb(b, t, Vector3(0.03, 0.33, 0.01), Vector3(0, 3.79, s * 0.12), Props.DARK, 0.003, Basis(Vector3.BACK, PI * 0.0))


# --- The front on the street -----------------------------------------------------------------

## The ticket hall (x < 0) and the shops (x > 0) along the street, the gap between them the way
## in, under the TERMINAL CENTRAL sign on its two portal frames.
static func front(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> Array:
	var solid := []
	var h := 5.0
	for s in [-1.0, 1.0]:
		var x0: float = GATE_HALF
		var x1 := LENGTH * 0.5 + 4.0
		var cx: float = s * (x0 + x1) * 0.5
		var w := x1 - x0
		var cz := FRONT_Z + FRONT_D * 0.5
		rb(b, t, Vector3(w, h, FRONT_D), Vector3(cx, h * 0.5, cz), SLAB, 0.06)
		rb(b, t, Vector3(w + 0.6, 0.9, FRONT_D + 0.6), Vector3(cx, h + 0.1, cz), SLAB_DARK, 0.06)
		solid.append([Vector3(cx, h * 0.5, cz), Vector3(w, h, FRONT_D)])
		# The street side: shopfronts, every one with a roller shutter half down or kicked in.
		var n := int(w / 5.0)
		for k in n:
			var x := cx - w * 0.5 + (k + 0.5) * w / n
			var sw := w / n - 0.6
			var shut := MeshKit.hash01(79, k, int(s))
			rb(b, t, Vector3(sw, 2.8, 0.05), Vector3(x, 1.6, FRONT_Z - 0.02), Props.GLASS, 0.01)
			if s < 0.0 or shut > 0.7:
				glow.box(Vector3(sw - 0.3, 2.4, 0.01), Vector3(x, 1.5, FRONT_Z - 0.01), Color(0.8, 0.75, 0.55), Basis.IDENTITY, t)
			var down := 2.6 * clampf(shut, 0.1, 0.95)
			rb(b, t, Vector3(sw, down, 0.08), Vector3(x, 3.0 - down * 0.5, FRONT_Z - 0.08), Color("9aa0a299"), 0.01)
			for r in int(down / 0.12):
				rb(b, t, Vector3(sw, 0.015, 0.09), Vector3(x, 3.0 - r * 0.12, FRONT_Z - 0.085), Color("7e848699"), 0.003)
			rb(b, t, Vector3(sw + 0.3, 0.4, 0.35), Vector3(x, 3.25, FRONT_Z - 0.2), Color("2a5a9acc") if k % 2 == 0 else Color("c83a2acc"), 0.03)  # fascia board
			rb(b, t, Vector3(0.3, 3.0, 0.3), Vector3(x - (sw + 0.6) * 0.5, 1.5, FRONT_Z - 0.1), SLAB_DARK, 0.03)
		# The platform side: the hall's glazing and doors onto the south lane.
		rb(b, t, Vector3(w - 1.0, 2.6, 0.05), Vector3(cx, 1.5, FRONT_Z + FRONT_D + 0.02), Props.GLASS, 0.01)
		if s < 0.0:
			glow.box(Vector3(w - 2.0, 2.2, 0.01), Vector3(cx, 1.5, FRONT_Z + FRONT_D + 0.04), Color(0.75, 0.72, 0.6), Basis.IDENTITY, t)
	# The portal frames and the sign spanning the way in.
	for s in [-1.0, 1.0]:
		var p := Vector3(s * (GATE_HALF - 0.6), 0, FRONT_Z - 0.3)
		rb(b, t, Vector3(0.6, 8.2, 0.6), p + Vector3(0, 4.1, 0), STEEL_DARK, 0.04)
		b.frustum(Vector2(1.0, 1.0), Vector2(0.62, 0.62), 0.6, p, Props.CONCRETE_DARK, Basis.IDENTITY, t)
		solid.append([p + Vector3(0, 4.1, 0), Vector3(0.6, 8.2, 0.6)])
	rb(b, t, Vector3(GATE_HALF * 2.0, 2.0, 0.5), Vector3(0, SIGN_AT.y, FRONT_Z - 0.05), Color("1d2a52cc"), 0.05)
	rb(b, t, Vector3(GATE_HALF * 2.0 + 0.2, 0.15, 0.55), Vector3(0, SIGN_AT.y + 1.05, FRONT_Z - 0.05), Props.STEEL, 0.02)
	glow.box(Vector3(GATE_HALF * 2.0 - 1.0, 0.06, 0.04), Vector3(0, SIGN_AT.y - 0.95, FRONT_Z - 0.32), Color.WHITE, Basis.IDENTITY, t)
	return solid


# --- The city bus ----------------------------------------------------------------------------

## A yellow 12 m city bus, facing -Z: rounded body, the dark window band, a sloped windscreen with
## the lit destination board, three doors on the right (open with `open`), roof pods, wheels in
## their arches, headlights (lit: `lit`). `burnt` blackens it to a shell.
static func bus(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D, lit := true, open := true, burnt := false) -> Array:
	var paint := Props.SOOT if burnt else BUS_YELLOW
	var band := Color("0a0a0b1a") if burnt else BUS_DARK
	var L := 12.0
	var W := 2.55
	rb(b, t, Vector3(W, 2.4, L), Vector3(0, 1.75, 0), paint, 0.18)
	rb(b, t, Vector3(W + 0.02, 0.25, L + 0.02), Vector3(0, 0.62, 0), band, 0.08)  # skirt
	rb(b, t, Vector3(W + 0.02, 1.15, L - 1.6), Vector3(0, 2.15, 0.5), band, 0.06)  # window band
	for k in 7:
		rb(b, t, Vector3(W + 0.04, 1.05, 0.06), Vector3(0, 2.15, -4.5 + k * 1.55), paint.darkened(0.1), 0.01)
	rb(b, t, Vector3(W - 0.1, 1.7, 0.1), Vector3(0, 2.0, -L * 0.5 - 0.02), band, 0.05, Basis(Vector3.RIGHT, -0.08))  # windscreen
	rb(b, t, Vector3(W - 0.5, 0.28, 0.06), Vector3(0, 2.75, -L * 0.5 - 0.1), Props.DARK, 0.02)
	if lit and not burnt:
		glow.box(Vector3(W - 0.7, 0.18, 0.02), Vector3(0, 2.75, -L * 0.5 - 0.14), Color(1.0, 0.75, 0.2), Basis.IDENTITY, t)
	for s in [-1.0, 1.0]:
		var hp := Vector3(s * (W * 0.5 - 0.35), 0.95, -L * 0.5 - 0.04)
		rb(b, t, Vector3(0.42, 0.2, 0.08), hp, Props.STEEL, 0.03)
		if lit and not burnt:
			glow.box(Vector3(0.36, 0.14, 0.02), hp - Vector3(0, 0, 0.05), Color.WHITE, Basis.IDENTITY, t)
		rb(b, t, Vector3(0.3, 0.2, 0.06), Vector3(s * (W * 0.5 - 0.3), 1.0, L * 0.5 + 0.03), Color("8a1010cc"), 0.02)
		b.tube(PackedVector3Array([Vector3(s * (W * 0.5), 2.5, -L * 0.5 + 0.3), Vector3(s * (W * 0.5 + 0.35), 2.4, -L * 0.5 + 0.1), Vector3(s * (W * 0.5 + 0.4), 2.0, -L * 0.5 + 0.1)]), 0.03, Props.DARK, 5, -1.0, t)
	rb(b, t, Vector3(W, 0.18, 0.3), Vector3(0, 0.55, -L * 0.5 - 0.05), Props.DARK, 0.04)  # bumper
	rb(b, t, Vector3(W, 0.18, 0.3), Vector3(0, 0.55, L * 0.5 + 0.05), Props.DARK, 0.04)
	for z in [-L * 0.5 + 1.0, -0.6, 3.6]:  # doors on the right
		if open:
			rb(b, t, Vector3(0.06, 2.1, 1.1), Vector3(W * 0.5 + 0.01, 1.55, z), Color("050505"), 0.01)
			rb(b, t, Vector3(0.5, 2.0, 0.05), Vector3(W * 0.5 + 0.28, 1.55, z - 0.5), band, 0.01, Basis(Vector3.UP, 0.4))
		else:
			rb(b, t, Vector3(0.05, 2.0, 1.1), Vector3(W * 0.5 + 0.02, 1.55, z), band, 0.01)
	for z in [-3.0, 1.0]:  # roof pods
		rb(b, t, Vector3(1.8, 0.35, 2.4), Vector3(0, 3.1, z), paint.darkened(0.05) if not burnt else paint, 0.1)
	for z in [-L * 0.5 + 2.6, L * 0.5 - 3.0]:
		for s in [-1.0, 1.0]:
			b.lathe(PackedVector2Array([Vector2(0.0, -0.16), Vector2(0.5, -0.16), Vector2(0.52, -0.12), Vector2(0.52, 0.12), Vector2(0.5, 0.16), Vector2(0.0, 0.16)]),
				Vector3(s * (W * 0.5 - 0.15), 0.52, z), Props.TYRE, 16, Basis(Vector3.FORWARD, PI * 0.5), t)
			b.rcyl(0.28, 0.34, Vector3(s * (W * 0.5 - 0.14), 0.52, z), Props.STEEL, 10, 0.02, Basis(Vector3.FORWARD, PI * 0.5), t)
			rb(b, t, Vector3(0.05, 0.75, 1.3), Vector3(s * (W * 0.5 + 0.01), 0.75, z), Props.DARK, 0.05)
	return [[Vector3(0, 1.6, 0), Vector3(W, 3.2, L)]]


## Glowing embers and the scorched slab where a bus burnt out: a dark stain on the ground and up
## the soffit above it.
static func scorch(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator) -> void:
	b.rcyl(5.0, 0.02, Vector3(0, 0.02, 0), Color("0c0b0a1a"), 18, 0.005, Basis.IDENTITY, t)
	b.rcyl(4.0, 0.03, Vector3(0, SOFFIT_Y - 0.06, 0), Color("15141310"), 18, 0.005, Basis.IDENTITY, t)
	for k in 18:
		var p := Vector3(rng.randf_range(-1.4, 1.4), rng.randf_range(0.3, 0.9), rng.randf_range(-5.0, 5.0))
		glow.box(Vector3(0.12, 0.06, 0.12), p, Color(1.0, 0.45, 0.1), Basis(Vector3.UP, rng.randf() * TAU), t)
