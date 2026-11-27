class_name BatalhaoSet
## The pieces of the 62º Batalhão de Infantaria, like the other POI sets: each draws into the
## Builder it is given at transform `t` and returns its solid parts as [[center, size, basis?], ...]
## in its own space. The lot's frame: -Z to the street (rue Jules-Ferry), x along it.
##
## From references/batalhao.jpg (straight down the parade ground from the air) and batalhao2.jpg
## (the compound from high up): long two-storey blocks round a concrete parade ground, white walls
## over a green band at the foot, rows of tall green-framed windows, brown hipped tile roofs, the
## headquarters at the head of the ground with 62ºBI on it, the gym hall with its curved metal roof,
## the round emblem bed in the middle of the ground, the low stands, the trucks lined up at the
## head, the lawn on the street with big stars cut into it, the railings along the street.
## What's built: references/batalhao_elements.md.

## Alpha is the surface class (MeshKit): cc PAINT, 99 METAL, 66 GLASS, e6 PAVERS, 1a SOOT.
const WALL := Color("e4e2da")
const WALL_SHADE := Color("cfccc2")
const BAND := Color("2f5b3ccc")
const FRAME := Color("2c6a44cc")
const GLASS := Color("1a2a3066")
const ROOF := Color("7a4632")
const ROOF_DARK := Color("5c3424")
const RIDGE := Color("6a3a28")
const GROUND := Color("a5a49ce6")
const LINE := Color("eeeee6")
const LAWN := Color("4f7a34")
const BED := Color("3f6a2c")
const KERB := Color("d8d6cc")
const METAL_ROOF := Color("8f979e99")
const RAIL := Color("2a5a3a99")
const STEEL := Color("4e545a99")
const COURT := Color("3a6a8acc")
const BOOM_RED := Color("b02a24cc")

const YAW := -0.8211              ## the lot's turn: -Z faces rue Jules-Ferry, to the north-east
const STREET_SET := 8.0           ## from the street's middle to the railings (z = 0)
const STOREY := 3.8
const EAVE := 7.8
const DEPTH := 12.0
const FRONT_Z := 28.0             ## the front block's middle (its street face at FRONT_Z - DEPTH / 2)
const FRONT_LEN := 130.0
const PASSAGE := 5.0              ## half the way through the front block, on the drive
const PASSAGE_H := 4.4
const GROUND_X := 48.0            ## the parade ground: x within +-GROUND_X, z in GROUND_Z
const GROUND_Z := Vector2(40.0, 142.0)
const SIDE_X := 60.0              ## the side blocks' middles
const SIDE_Z := 92.0
const SIDE_LEN := 100.0
const HQ_Z := 156.0
const HQ_LEN := 76.0
const HQ_DEPTH := 13.0
const EMBLEM := Vector3(0, 0, 84)
const EMBLEM_R := 6.5
const PAD := Vector3(0, 0, 114)    ## where the helicopter comes down
const GYM := Vector3(-92, 0, 150)
const GYM_SIZE := Vector2(24, 40)
const LOT_X := Vector2(-120.0, 115.0)
const LOT_BACK := 230.0
const GATE_HALF := 7.0


static func rb(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, r := -1.0, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, r, rot, t)


static func at(t: Transform3D, p: Vector3, yaw := 0.0) -> Transform3D:
	return t * Transform3D(Basis(Vector3.UP, yaw), p)


# --- The blocks --------------------------------------------------------------------------

## One long two-storey block along its x, facing -Z: the green band at the foot, white walls with a
## floor band, tall green-framed windows in rows on both faces, the cornice and a brown hipped tile
## roof. `opening` > 0 leaves a way through the ground floor that wide at x = 0 (the front block's
## gate); the walls either side are the colliders, the storey over it collides through `lintel`.
## `lit` windows (by index) glow in `glow`.
static func block(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D, length: float, depth := DEPTH,
		opening := 0.0, lit := []) -> Array:
	var hl := length * 0.5
	var hd := depth * 0.5
	var spans: Array = [Vector2(-hl, hl)] if opening <= 0.0 else [Vector2(-hl, -opening), Vector2(opening, hl)]
	var solids := []
	for s: Vector2 in spans:
		var w := s.y - s.x
		var mx := (s.x + s.y) * 0.5
		rb(b, t, Vector3(w, 1.0, depth + 0.12), Vector3(mx, 0.5, 0), BAND, 0.04)
		solids.append([Vector3(mx, EAVE * 0.5, 0), Vector3(w, EAVE, depth)])
	if opening > 0.0: # the walls over the way through, its soffit and the jambs
		rb(b, t, Vector3(opening * 2.0 + 0.2, EAVE - PASSAGE_H - 1.0, depth), Vector3(0, (EAVE + PASSAGE_H + 1.0) * 0.5, 0), WALL, 0.05)
		rb(b, t, Vector3(opening * 2.0, 0.2, depth - 0.2), Vector3(0, PASSAGE_H + 0.1, 0), WALL_SHADE, 0.02)
		for x in [-opening, opening]:
			for z in [-hd, hd]:
				rb(b, t, Vector3(0.6, PASSAGE_H + 0.4, 0.5), Vector3(x, (PASSAGE_H + 0.4) * 0.5, z), WALL_SHADE, 0.05)
	for s: Vector2 in spans:
		var w := s.y - s.x
		var mx := (s.x + s.y) * 0.5
		rb(b, t, Vector3(w, EAVE - 1.0, depth), Vector3(mx, 1.0 + (EAVE - 1.0) * 0.5, 0), WALL, 0.05)
	# the floor band and the cornice right round
	rb(b, t, Vector3(length + 0.2, 0.22, depth + 0.2), Vector3(0, STOREY + 0.2, 0), WALL_SHADE, 0.04)
	rb(b, t, Vector3(length + 0.9, 0.36, depth + 0.9), Vector3(0, EAVE + 0.1, 0), WALL, 0.08)
	rb(b, t, Vector3(length + 0.7, 0.14, depth + 0.7), Vector3(0, EAVE - 0.14, 0), WALL_SHADE, 0.03)
	# the hipped roof, its ridge and the hips' caps
	var rise := depth * 0.32
	b.frustum(Vector2(length + 1.1, depth + 1.1), Vector2(maxf(length - depth, 0.4), 0.18), rise,
		Vector3(0, EAVE + 0.28, 0), ROOF, Basis.IDENTITY, t)
	rb(b, t, Vector3(maxf(length - depth, 0.4) + 0.2, 0.2, 0.3), Vector3(0, EAVE + 0.28 + rise, 0), RIDGE, 0.08)
	for k in int(length / 3.6): # tile courses: darker lines across the slopes
		var x := -hl + 1.8 + k * 3.6
		for side in [-1.0, 1.0]:
			rb(b, t, Vector3(0.08, 0.04, depth * 0.5), Vector3(x, EAVE + 0.3 + rise * 0.5, side * hd * 0.5), ROOF_DARK, 0.01,
				Basis(Vector3.RIGHT, side * atan2(rise, hd + 0.55)))
	# the windows on both faces, two rows
	var n := int((length - 2.0) / 3.6)
	var i := 0
	for k in n:
		var x := -hl + 1.0 + 1.8 + k * 3.6
		if opening > 0.0 and absf(x) < opening + 1.0:
			continue
		for face in [-1.0, 1.0]:
			for row in 2:
				var y0 := 1.5 if row == 0 else STOREY + 0.9
				window(b, glow, t, Vector3(x, y0, face * (hd + 0.02)), face, lit.has(i))
				i += 1
	# downpipes at the ends
	for x in [-hl + 0.3, hl - 0.3]:
		for face in [-1.0, 1.0]:
			b.rcyl(0.06, EAVE, Vector3(x, EAVE * 0.5, face * (hd + 0.1)), STEEL, 6, 0.0, Basis.IDENTITY, t)
	return solids


## The storey over a way through a block, as a collider: walked under, not into.
static func lintel(depth := DEPTH, opening := PASSAGE) -> Array:
	return [[Vector3(0, (EAVE + PASSAGE_H) * 0.5, 0), Vector3(opening * 2.0, EAVE - PASSAGE_H, depth)]]


## A tall window on a face (`face` -1 the -Z side, +1 the +Z side) with its green frame, the sill,
## the mullion and the transom, the panes dark or lit.
static func window(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D, p: Vector3, face: float, lit: bool) -> void:
	var h := 2.1
	var w := 1.3
	var c := p + Vector3(0, h * 0.5, 0)
	(glow if lit else b).box(Vector3(w - 0.1, h - 0.1, 0.04), c + Vector3(0, 0, face * -0.04), GLASS, Basis.IDENTITY, t)
	for x in [-w * 0.5, w * 0.5]:
		rb(b, t, Vector3(0.09, h, 0.1), c + Vector3(x, 0, 0), FRAME, 0.015)
	for y in [-h * 0.5, h * 0.5, h * 0.18]:
		rb(b, t, Vector3(w, 0.09, 0.1), c + Vector3(0, y, 0), FRAME, 0.015)
	rb(b, t, Vector3(0.06, h, 0.08), c, FRAME, 0.01)
	rb(b, t, Vector3(w + 0.24, 0.08, 0.22), c + Vector3(0, -h * 0.5 - 0.06, face * 0.08), WALL_SHADE, 0.02)


## The headquarters at the head of the ground: a block with its middle bay raised a storey under its
## own hipped roof, a porch on columns over the steps, the coat of arms over the door.
static func headquarters(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> Array:
	var solids := block(b, glow, t, HQ_LEN, HQ_DEPTH, 0.0, [3, 8, 12, 21, 30])
	var bay := at(t, Vector3(0, 0, 0))
	var bw := 16.0
	var bh := EAVE + 3.6
	rb(b, bay, Vector3(bw, bh - EAVE, HQ_DEPTH + 0.6), Vector3(0, EAVE + (bh - EAVE) * 0.5, 0), WALL, 0.06)
	rb(b, bay, Vector3(bw + 0.8, 0.36, HQ_DEPTH + 1.4), Vector3(0, bh + 0.1, 0), WALL, 0.08)
	b.frustum(Vector2(bw + 1.0, HQ_DEPTH + 1.6), Vector2(bw - HQ_DEPTH * 0.7, 0.2), 3.4, Vector3(0, bh + 0.28, 0), ROOF, Basis.IDENTITY, bay)
	for x in [-5.0, 0.0, 5.0]:
		window(b, glow, bay, Vector3(x, EAVE + 0.7, -HQ_DEPTH * 0.5 - 0.32), -1.0, x == 0.0)
	# the porch: four columns, a flat roof, three steps
	var pz := -HQ_DEPTH * 0.5 - 3.0
	for x in [-4.5, -1.5, 1.5, 4.5]:
		b.rcyl(0.3, 3.6, Vector3(x, 1.8 + 0.45, pz - 1.5), WALL, 12, 0.04, Basis.IDENTITY, t)
	rb(b, t, Vector3(11.0, 0.5, 6.0), Vector3(0, 4.3, pz), WALL, 0.06)
	rb(b, t, Vector3(11.2, 0.12, 6.2), Vector3(0, 4.6, pz), BAND, 0.02)
	for s in 3:
		rb(b, t, Vector3(10.0 - s * 0.6, 0.15, 6.0 - s * 0.9), Vector3(0, 0.075 + s * 0.15, pz + s * 0.45), KERB, 0.02)
	rb(b, t, Vector3(2.6, 2.9, 0.12), Vector3(0, 1.45 + 0.45, -HQ_DEPTH * 0.5 - 0.06), Color("3a2a1e"), 0.02) # the door
	# the arms over the door: a green shield on a gold disc
	b.rcyl(0.95, 0.1, Vector3(0, 6.9, -HQ_DEPTH * 0.5 - 0.65), Color("c8a23acc"), 20, 0.02, Basis(Vector3.RIGHT, PI * 0.5), t)
	rb(b, t, Vector3(1.0, 1.2, 0.12), Vector3(0, 6.95, -HQ_DEPTH * 0.5 - 0.74), BAND, 0.06)
	solids.append([Vector3(0, 0.25, pz), Vector3(10.0, 0.5, 6.0)])
	return solids


## The gym hall: low brick walls under a barrel roof of ribbed metal sheet, its ends filled in white
## with a big door on the ground side. Its length runs along local z.
static func gym(b: MeshKit.Builder, t: Transform3D) -> Array:
	var w := GYM_SIZE.x
	var l := GYM_SIZE.y
	var wall_h := 3.4
	var r := w * 0.5
	for side in [-1.0, 1.0]:
		rb(b, t, Vector3(0.4, wall_h, l), Vector3(side * r, wall_h * 0.5, 0), WALL, 0.04)
		rb(b, t, Vector3(0.44, 0.9, l + 0.04), Vector3(side * r, 0.45, 0), BAND, 0.03)
		for k in 8: # high strip windows
			rb(b, t, Vector3(0.1, 0.7, 3.2), Vector3(side * (r + 0.16), wall_h - 0.7, -l * 0.5 + 2.5 + k * 5.0), GLASS, 0.01)
	var steps := 14
	var rise := w * 0.36
	for k in steps: # the barrel: flat strips round the arc, ribs over them
		var a0 := PI * float(k) / steps
		var a1 := PI * float(k + 1) / steps
		var p0 := Vector2(-cos(a0) * r, sin(a0) * rise)
		var p1 := Vector2(-cos(a1) * r, sin(a1) * rise)
		var mid := (p0 + p1) * 0.5
		var tilt := atan2(p1.y - p0.y, p1.x - p0.x)
		rb(b, t, Vector3(p0.distance_to(p1) + 0.08, 0.08, l + 0.6), Vector3(mid.x, wall_h + mid.y, 0), METAL_ROOF, 0.0,
			Basis(Vector3.BACK, tilt))
	for k in 11:
		var z := -l * 0.5 + k * l / 10.0
		var pts := PackedVector3Array()
		for s in steps + 1:
			var a := PI * float(s) / steps
			pts.append(Vector3(-cos(a) * (r + 0.05), wall_h + sin(a) * rise + 0.06, z))
		b.tube(pts, 0.05, STEEL, 4, -1.0, t)
	for end in [-1.0, 1.0]: # the ends: white, stepped up under the arc
		var z: float = end * l * 0.5
		rb(b, t, Vector3(w, wall_h, 0.4), Vector3(0, wall_h * 0.5, z), WALL, 0.04)
		for s in 6:
			var y := wall_h + rise * (s + 0.5) / 6.0
			var half := r * sqrt(maxf(0.0, 1.0 - pow((s + 1.0) / 6.0, 2.0)))
			rb(b, t, Vector3(half * 2.0 + 0.4, rise / 6.0 + 0.02, 0.36), Vector3(0, y, z), WALL, 0.02)
		if end > 0.0:
			rb(b, t, Vector3(6.0, 4.4, 0.12), Vector3(0, 2.2, z + 0.24), STEEL, 0.02) # the roller door, down
			for y in range(1, 11):
				rb(b, t, Vector3(6.0, 0.03, 0.04), Vector3(0, y * 0.4, z + 0.31), Color("3e4448"), 0.0)
	return [[Vector3(0, (wall_h + rise) * 0.5, 0), Vector3(w + 0.4, wall_h + rise, l + 0.4)]]


# --- The ground and the lawn --------------------------------------------------------------

## A five-pointed star lying on the ground at `c` (in `t`), `r` to its points, turned `spin`.
static func star(g: MeshKit.Builder, t: Transform3D, c: Vector3, r: float, color: Color, spin := 0.0) -> void:
	var pts := []
	for k in 10:
		var a := spin + PI * float(k) / 5.0
		var rr := r if k % 2 == 0 else r * 0.4
		pts.append(t * (c + Vector3(sin(a) * rr, 0, -cos(a) * rr)))
	var mid := t * c
	for k in 10:
		g.ground_tri(mid, pts[k], pts[(k + 1) % 10], color)


## A flat disc on the ground (in `t`).
static func disc(g: MeshKit.Builder, t: Transform3D, c: Vector3, r: float, color: Color, sides := 20) -> void:
	var mid := t * c
	for k in sides:
		var a0 := TAU * float(k) / sides
		var a1 := TAU * float(k + 1) / sides
		g.ground_tri(mid, t * (c + Vector3(cos(a0) * r, 0, sin(a0) * r)), t * (c + Vector3(cos(a1) * r, 0, sin(a1) * r)), color)


## The emblem bed in the middle of the ground: a low white kerb round a green bed, a white star in
## it with the battalion's number on a plinth at its heart.
static func emblem(b: MeshKit.Builder, g: MeshKit.Builder, t: Transform3D) -> void:
	disc(g, t, EMBLEM + Vector3(0, 0.06, 0), EMBLEM_R, BED, 24)
	star(g, t, EMBLEM + Vector3(0, 0.08, 0), EMBLEM_R * 0.8, LINE)
	for k in 24:
		var a := TAU * (k + 0.5) / 24.0
		var p := EMBLEM + Vector3(cos(a) * EMBLEM_R, 0.09, sin(a) * EMBLEM_R)
		rb(b, t, Vector3(0.3, 0.18, EMBLEM_R * TAU / 24.0 + 0.05), p, KERB, 0.03, Basis(Vector3.UP, -a))
	b.frustum(Vector2(1.2, 1.2), Vector2(0.8, 0.8), 0.9, EMBLEM, KERB, Basis.IDENTITY, t)
	rb(b, t, Vector3(0.9, 0.1, 0.9), EMBLEM + Vector3(0, 0.95, 0), BAND, 0.02)


## The low stands: three concrete steps `length` long facing +Z (the ground).
static func stands(b: MeshKit.Builder, t: Transform3D, length: float) -> Array:
	for s in 3:
		rb(b, t, Vector3(length, 0.45 * (s + 1), 1.1), Vector3(0, 0.225 * (s + 1), 1.1 - s * 1.1), WALL_SHADE if s % 2 == 0 else KERB, 0.04)
	for x in range(int(-length * 0.5) + 2, int(length * 0.5) - 1, 6): # the rail at the back
		b.rcyl(0.04, 1.0, Vector3(x, 1.35 + 0.5, -1.6), RAIL, 6, 0.0, Basis.IDENTITY, t)
	rb(b, t, Vector3(length, 0.06, 0.06), Vector3(0, 2.35, -1.6), RAIL, 0.01)
	return [[Vector3(0, 0.675, 0), Vector3(length, 1.35, 3.3)]]


## A flagpole with a flag hanging off it (`kind` 0 Brazil's green and yellow, 1 the army's red,
## 2 white with a green band).
static func flagpole(b: MeshKit.Builder, t: Transform3D, kind: int) -> void:
	b.rcyl(0.3, 0.3, Vector3(0, 0.15, 0), KERB, 12, 0.04, Basis.IDENTITY, t)
	b.taper(0.07, 0.04, 11.0, Vector3(0, 0.3, 0), WALL, 8, Basis.IDENTITY, t)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.07, 0.03), Vector2(0.09, 0.09), Vector2(0, 0.18)]),
		Vector3(0, 11.3, 0), Color("b8922e99"), 8, Basis.IDENTITY, t)
	var cloth: Color = [Color("1f8a3acc"), Color("a8282ccc"), Color("ecece6cc")][kind]
	var hf := t * Transform3D(Basis(Vector3.UP, 0.25), Vector3(0.75, 10.3, -0.1))
	rb(b, hf, Vector3(1.5, 1.0, 0.03), Vector3.ZERO, cloth, 0.01)
	match kind:
		0:
			rb(b, hf, Vector3(0.66, 0.66, 0.035), Vector3.ZERO, Color("f0c419cc"), 0.006, Basis(Vector3.BACK, PI * 0.25))
			b.rcyl(0.24, 0.04, Vector3.ZERO, Color("1f3d8acc"), 14, 0.008, Basis(Vector3.RIGHT, PI * 0.5), hf)
		2:
			rb(b, hf, Vector3(1.5, 0.3, 0.035), Vector3(0, -0.2, 0), BAND, 0.006)


# --- The edge ------------------------------------------------------------------------------

## The street front from x0 to x1 along z = 0: a white plinth wall, square white piers every 6 m
## with green caps, green railings between. Returns one collider.
static func railings(b: MeshKit.Builder, t: Transform3D, x0: float, x1: float) -> Array:
	var length := x1 - x0
	var mx := (x0 + x1) * 0.5
	rb(b, t, Vector3(length, 0.8, 0.45), Vector3(mx, 0.4, 0), WALL, 0.04)
	rb(b, t, Vector3(length + 0.1, 0.08, 0.55), Vector3(mx, 0.84, 0), WALL_SHADE, 0.02)
	rb(b, t, Vector3(length, 0.06, 0.06), Vector3(mx, 2.3, 0), RAIL, 0.01)
	rb(b, t, Vector3(length, 0.06, 0.06), Vector3(mx, 1.0, 0), RAIL, 0.01)
	var piers := maxi(1, int(length / 6.0))
	for k in piers + 1:
		var x := x0 + length * float(k) / piers
		rb(b, t, Vector3(0.6, 2.6, 0.6), Vector3(x, 1.3, 0), WALL, 0.05)
		rb(b, t, Vector3(0.72, 0.16, 0.72), Vector3(x, 2.66, 0), BAND, 0.04)
	var bars := int(length / 0.14)
	for k in bars:
		var x := x0 + 0.07 + k * 0.14
		b.box(Vector3(0.025, 1.4, 0.025), Vector3(x, 1.6, 0), RAIL, Basis.IDENTITY, t)
	return [[Vector3(mx, 1.3, 0), Vector3(length, 2.6, 0.6)]]


## The gate: two big piers with lamps on them, the barrier boom left up and bent, sandbags.
static func gate(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> Array:
	var solids := []
	for side in [-1.0, 1.0]:
		var x: float = side * GATE_HALF
		rb(b, t, Vector3(1.4, 3.6, 1.4), Vector3(x, 1.8, 0), WALL, 0.06)
		rb(b, t, Vector3(1.6, 0.4, 1.6), Vector3(x, 3.8, 0), BAND, 0.06)
		b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.22, 0.05), Vector2(0.26, 0.45), Vector2(0.12, 0.6), Vector2(0, 0.62)]),
			Vector3(x, 4.0, 0), STEEL, 8, Basis.IDENTITY, t)
		glow.box(Vector3(0.36, 0.3, 0.36), t * Vector3(x, 4.25, 0), Color.WHITE)
		solids.append([Vector3(x, 1.8, 0), Vector3(1.4, 3.6, 1.4)])
	# the boom: its post by the guard house, the arm up at a slant, red and white
	var post := Vector3(GATE_HALF - 1.6, 0, 2.0)
	rb(b, t, Vector3(0.5, 1.1, 0.5), post + Vector3(0, 0.55, 0), Color("d8d8d0cc"), 0.04)
	var arm := Basis(Vector3.BACK, 1.15)
	for k in 7:
		var off := arm * Vector3(-0.5 - k * 0.9, 0, 0)
		rb(b, t, Vector3(0.9, 0.12, 0.12), post + Vector3(0, 1.0, 0) + off, BOOM_RED if k % 2 == 0 else LINE, 0.02, arm)
	return solids


## The guard house by the gate: a small white box with a window band all round, a flat roof with
## a deep overhang, a door to the inside.
static func guard_house(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> Array:
	rb(b, t, Vector3(4.2, 0.6, 3.2), Vector3(0, 0.3, 0), BAND, 0.03)
	rb(b, t, Vector3(4.0, 2.2, 3.0), Vector3(0, 1.7, 0), WALL, 0.04)
	glow.box(Vector3(3.6, 0.9, 3.04), t * Vector3(0, 1.7, 0), GLASS)
	rb(b, t, Vector3(4.02, 0.08, 3.02), Vector3(0, 2.2, 0), FRAME, 0.01)
	rb(b, t, Vector3(4.02, 0.08, 3.02), Vector3(0, 1.22, 0), FRAME, 0.01)
	rb(b, t, Vector3(5.2, 0.22, 4.2), Vector3(0, 2.9, 0), WALL, 0.05)
	rb(b, t, Vector3(5.24, 0.08, 4.24), Vector3(0, 2.76, 0), BAND, 0.02)
	return [[Vector3(0, 1.4, 0), Vector3(4.2, 2.8, 3.2)]]


## The watch tower at the corner of the gate: four steel legs braced, a cabin with a roof, the gun.
static func watch_tower(b: MeshKit.Builder, t: Transform3D) -> Array:
	var h := 6.0
	for x in [-1.3, 1.3]:
		for z in [-1.3, 1.3]:
			b.rcyl(0.1, h, Vector3(x, h * 0.5, z), STEEL, 6, 0.0, Basis.IDENTITY, t)
	for y in [1.8, 3.8]:
		for side in [-1.3, 1.3]:
			rb(b, t, Vector3(2.6, 0.08, 0.08), Vector3(0, y, side), STEEL, 0.0, Basis(Vector3.BACK, 0.6))
			rb(b, t, Vector3(0.08, 0.08, 2.6), Vector3(side, y, 0), STEEL, 0.0, Basis(Vector3.RIGHT, 0.6))
	rb(b, t, Vector3(3.4, 0.2, 3.4), Vector3(0, h, 0), Props.OLIVE_DARK, 0.03)
	for side in [-1.0, 1.0]:
		rb(b, t, Vector3(3.4, 1.1, 0.1), Vector3(0, h + 0.65, side * 1.65), Props.OLIVE, 0.02)
		rb(b, t, Vector3(0.1, 1.1, 3.4), Vector3(side * 1.65, h + 0.65, 0), Props.OLIVE, 0.02)
	for x in [-1.6, 1.6]:
		for z in [-1.6, 1.6]:
			b.rcyl(0.05, 1.6, Vector3(x, h + 1.0, z), STEEL, 6, 0.0, Basis.IDENTITY, t)
	b.frustum(Vector2(4.0, 4.0), Vector2(0.4, 0.4), 1.0, Vector3(0, h + 1.8, 0), Props.OLIVE_DARK, Basis.IDENTITY, t)
	Props.mounted_gun(b, at(t, Vector3(0, h + 1.1, -1.6)))
	Props.sandbags(b, at(t, Vector3(0, h + 0.1, -1.4)), 2.6, 2)
	return [[Vector3(0, h * 0.5, 0), Vector3(2.8, h, 2.8)]]
