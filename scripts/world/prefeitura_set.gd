class_name PrefeituraSet
## The pieces of the Prefeitura Municipal de Joinville, like MiranteSet: each draws into the Builder
## it is given at transform `t` and returns its solid parts as [[center, size, basis?], ...] in its
## own space. Pieces stand on y = 0 and face -Z (the building's front faces its lawn and the avenue).
##
## From the photos in references/ (prefeitura1.jpg straight on, prefeitura2.jpg from over the river,
## prefeitura3.png from high up): a long low block of four storeys, red brick piers at every bay,
## deep grey concrete balcony bands at every floor line with the windows set back behind them, a
## pink plaster ground floor, blue steel space frames over the entrance, on the wings and up the
## stair tower at the north end, brick buttresses widening to the ground under them, two tall brick
## towers and a few lower boxes on a low metal roof. What's built: references/prefeitura_elements.md.

## Alpha is the surface class (MeshKit): cc PAINT, 99 METAL, b3 BRICK, e6 PAVERS, 80 TILE, 66 GLASS.
const BRICK := Color("9a4a2cb3")
const BRICK_DARK := Color("7e3a22b3")
const CONCRETE := Color("9c9a92")
const CONCRETE_DARK := Color("74726c")
const CONCRETE_LIGHT := Color("b6b3a9")
const PLASTER := Color("e2c2b4")       ## the pink ground floor
const FRAME_BLUE := Color("3f74bccc")  ## the space frames
const FRAME_DARK := Color("2a2d31cc")  ## window frames
const ROOF := Color("8a909699")        ## corrugated sheet
const PAVING := Color("8f897ce6")      ## light pavers of the forecourt and the walks
const GRASS := Color("33502a")
const ASPHALT := Color("2e2f32")
const LINE := Color("c8c8bccc")
const SIGN_TEXT := Color("f2f2ec")     ## the lawn sign's letters (a Label3D colour: keep alpha 1)
const FLAG_GREEN := Color("1f8a3acc")
const FLAG_YELLOW := Color("f0c419cc")
const FLAG_BLUE := Color("1f3d8acc")
const FLAG_RED := Color("c4262ecc")
const FLAG_WHITE := Color("ecece6cc")
const FLOWER_RED := Color("d0202833")
const FLOWER_YELLOW := Color("e8b81833")

## The block: LENGTH along X, DEPTH along Z, the front wall at z = -DEPTH / 2.
const LENGTH := 72.0
const DEPTH := 18.0
const FLOOR_H := 3.6
const FLOORS := 4
const ROOF_Y := FLOOR_H * FLOORS
const BAY := 4.0                        ## one brick pier every BAY metres
const BAND_OUT := 1.3                   ## how far the balcony bands stand out from the wall
const CENTRE_HALF := 8.0                ## the entrance block steps forward between x = ±CENTRE_HALF
const CENTRE_OUT := 3.0
const WINGS := [-22.0, 22.0]            ## x of the wings' space frames and their buttresses
const TOWER_X := LENGTH * 0.5 + 2.6     ## the stair tower at the north end (+X)
const TOWER_Z := -DEPTH * 0.5 + 3.0
const TOWER_SIZE := 5.0
const TOWER_H := ROOF_Y + 2.8
const CANOPY_OUT := 3.4                 ## the entrance canopy, beyond the entrance block
const ENTRANCE_LAMP := Vector3(0, 3.1, -DEPTH * 0.5 - CENTRE_OUT - 1.6)
const ROOF_TOWERS := [[Vector3(-17, 0, 2.0), Vector3(6.5, 8.5, 6.5)], [Vector3(19, 0, 2.5), Vector3(6.0, 7.0, 6.0)]]


static func bx(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, -1.0, rot, t)


static func rb(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color, r: float, rot := Basis.IDENTITY) -> void:
	b.rbox(size, pos, color, r, rot, t)


static func at(t: Transform3D, p: Vector3, yaw := 0.0) -> Transform3D:
	return t * Transform3D(Basis(Vector3.UP, yaw), p)


# --- Shared details ---------------------------------------------------------------------

## A blue space frame facing -Z, `w` wide, `h` tall and `d` deep, its foot centred at the origin of
## `f`: a square grid on the front and the back with an X in every square (so diamonds read across
## it), struts between the two at every node, a heavier outer frame.
static func space_frame(b: MeshKit.Builder, f: Transform3D, w: float, h: float, d: float, cell := 1.2, color := FRAME_BLUE) -> void:
	var nx := maxi(1, roundi(w / cell))
	var ny := maxi(1, roundi(h / cell))
	var sx := w / nx
	var sy := h / ny
	for face in [-0.5, 0.5]:
		var z: float = face * d
		for j in ny + 1:
			var y := j * sy
			var heavy := j == 0 or j == ny
			rb(b, f, Vector3(w + 0.12, 0.14 if heavy else 0.09, 0.14 if heavy else 0.09), Vector3(0, y, z), color, 0.02)
		for i in nx + 1:
			var x := -w * 0.5 + i * sx
			var heavy := i == 0 or i == nx
			rb(b, f, Vector3(0.14 if heavy else 0.09, h, 0.14 if heavy else 0.09), Vector3(x, h * 0.5, z), color, 0.02)
		for i in nx:
			for j in ny:
				var x0 := -w * 0.5 + i * sx
				var y0 := j * sy
				b.tube(PackedVector3Array([Vector3(x0, y0, z), Vector3(x0 + sx, y0 + sy, z)]), 0.035, color, 4, -1.0, f)
				b.tube(PackedVector3Array([Vector3(x0 + sx, y0, z), Vector3(x0, y0 + sy, z)]), 0.035, color, 4, -1.0, f)
	for i in nx + 1:
		for j in ny + 1:
			if (i + j) % 2 == 1:
				continue
			var p := Vector3(-w * 0.5 + i * sx, j * sy, 0)
			b.tube(PackedVector3Array([p + Vector3(0, 0, -d * 0.5), p + Vector3(0, 0, d * 0.5)]), 0.04, color, 4, -1.0, f)
	for x in [-w * 0.5, w * 0.5]:
		for y in [0.0, h]:
			b.rcyl(0.1, 0.12, Vector3(x, y, -d * 0.5 - 0.02), color.darkened(0.15), 8, 0.02, Basis(Vector3.RIGHT, PI * 0.5), f) # node plates


## A band of glazing facing -Z, `w` wide and `h` tall, centred at the origin of `f`: dark glass, a
## frame round it, mullions about every metre, a transom a third of the way down.
static func glazing(b: MeshKit.Builder, f: Transform3D, w: float, h: float, lit := false, glow: MeshKit.Builder = null) -> void:
	bx(b, f, Vector3(w, h, 0.05), Vector3(0, 0, 0.02), Props.GLASS)
	rb(b, f, Vector3(w + 0.1, 0.08, 0.12), Vector3(0, h * 0.5, -0.02), FRAME_DARK, 0.015)
	rb(b, f, Vector3(w + 0.1, 0.08, 0.12), Vector3(0, -h * 0.5, -0.02), FRAME_DARK, 0.015)
	rb(b, f, Vector3(w, 0.05, 0.08), Vector3(0, h * 0.18, -0.02), FRAME_DARK, 0.01)
	var n := maxi(1, roundi(w / 1.05))
	for i in n + 1:
		rb(b, f, Vector3(0.06 if 0 < i and i < n else 0.09, h, 0.1), Vector3(-w * 0.5 + i * w / n, 0, -0.02), FRAME_DARK, 0.012)
	if lit and glow != null: # somebody left the light on
		glow.box(Vector3(w * 0.9, h * 0.6, 0.02), Vector3(0, -h * 0.1, 0.05), Color.WHITE, Basis.IDENTITY, f)


## A lamp post on a walk, its foot at the origin of `f`: base, tapered pole, a round lantern.
static func lamp_post(b: MeshKit.Builder, f: Transform3D, glow: MeshKit.Builder, lit: bool) -> Array:
	b.rcyl(0.16, 0.4, Vector3(0, 0.2, 0), CONCRETE_DARK, 10, 0.04, Basis.IDENTITY, f)
	b.taper(0.07, 0.045, 3.9, Vector3(0, 0.4, 0), Props.STEEL.darkened(0.2), 8, Basis.IDENTITY, f)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.08, 0), Vector2(0.24, 0.12), Vector2(0.24, 0.16), Vector2(0.06, 0.3), Vector2(0, 0.32)]),
		Vector3(0, 4.55, 0), Props.STEEL.darkened(0.2), 10, Basis.IDENTITY, f)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.17, 0.02), Vector2(0.2, 0.18), Vector2(0.07, 0.24)]),
		Vector3(0, 4.3, 0), Props.GLASS, 10, Basis.IDENTITY, f)
	if lit:
		glow.rbox(Vector3(0.26, 0.18, 0.26), Vector3(0, 4.42, 0), Color.WHITE, 0.05, Basis.IDENTITY, f)
	return [[Vector3(0, 2.2, 0), Vector3(0.3, 4.4, 0.3)]]


## A flag on a pole, foot at the origin of `f`, the flag blowing to +X in two bent halves.
## `kind`: 0 Brazil, 1 Santa Catarina, 2 Joinville.
static func flag(b: MeshKit.Builder, f: Transform3D, kind: int) -> void:
	b.rcyl(0.14, 0.25, Vector3(0, 0.125, 0), CONCRETE_DARK, 10, 0.03, Basis.IDENTITY, f)
	b.taper(0.06, 0.04, 10.0, Vector3(0, 0.25, 0), Props.WHITE, 8, Basis.IDENTITY, f)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.06, 0.02), Vector2(0.08, 0.08), Vector2(0.06, 0.15), Vector2(0, 0.17)]),
		Vector3(0, 10.25, 0), Props.BRASS, 8, Basis.IDENTITY, f)
	var half := [Transform3D(Basis(Vector3.UP, 0.22), Vector3(0.5, 9.45, -0.1)),
		Transform3D(Basis(Vector3.UP, -0.18), Vector3(1.45, 9.45, -0.12))]
	var colours := [[FLAG_GREEN, FLAG_GREEN], [FLAG_RED, FLAG_RED], [FLAG_WHITE, FLAG_WHITE]]
	for k in 2:
		var hf: Transform3D = f * (half[k] as Transform3D)
		rb(b, hf, Vector3(0.98, 1.3, 0.025), Vector3.ZERO, colours[kind][k], 0.008)
		match kind:
			0: # the yellow diamond, the blue globe across the middle
				rb(b, hf, Vector3(0.62, 0.62, 0.03), Vector3(0.49 - k * 0.98, 0, 0), FLAG_YELLOW, 0.006, Basis(Vector3.BACK, PI * 0.25))
				b.rcyl(0.3, 0.035, Vector3(0.49 - k * 0.98, 0, 0), FLAG_BLUE, 14, 0.008, Basis(Vector3.RIGHT, PI * 0.5), hf)
			1: # red and white stripes, the arms on the white
				rb(b, hf, Vector3(0.98, 0.4, 0.03), Vector3(0, 0, 0), FLAG_WHITE, 0.006)
				if k == 0:
					b.rcyl(0.17, 0.035, Vector3(0.49, 0, 0), FLAG_GREEN, 12, 0.008, Basis(Vector3.RIGHT, PI * 0.5), hf)
			2: # white with the city's arms
				if k == 0:
					b.rcyl(0.26, 0.035, Vector3(0.49, 0, 0), FLAG_RED, 12, 0.008, Basis(Vector3.RIGHT, PI * 0.5), hf)
					b.rcyl(0.16, 0.04, Vector3(0.49, 0, 0), FLAG_BLUE, 12, 0.008, Basis(Vector3.RIGHT, PI * 0.5), hf)


# --- The building -----------------------------------------------------------------------

## The whole block. `glow` takes the lit windows and lamps. Returns colliders.
static func building(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> Array:
	var hl := LENGTH * 0.5
	var front := -DEPTH * 0.5
	var back := DEPTH * 0.5
	var solid := []
	# The mass behind the glass, dark, and the plinth all round.
	bx(b, t, Vector3(LENGTH - 0.4, ROOF_Y, DEPTH - 0.4), Vector3(0, ROOF_Y * 0.5, 0), Color("3a3836"))
	for z in [front, back]:
		rb(b, t, Vector3(LENGTH + 0.4, 0.35, 0.5), Vector3(0, 0.175, z), CONCRETE_DARK, 0.04)
	# Both long faces: the front in full, the back plainer.
	_face(b, glow, at(t, Vector3(0, 0, front)), true)
	_face(b, glow, at(t, Vector3(0, 0, back), PI), false)
	# The ends: brick, the bands wrapping round, a slot of windows.
	for side in [-1.0, 1.0]:
		var x: float = side * hl
		bx(b, t, Vector3(0.6, ROOF_Y, DEPTH + 0.6), Vector3(x, ROOF_Y * 0.5, 0), BRICK)
		for f in range(1, FLOORS):
			rb(b, t, Vector3(BAND_OUT, 0.24, DEPTH + BAND_OUT * 2.0), Vector3(x + side * BAND_OUT * 0.5, f * FLOOR_H, 0), CONCRETE, 0.04)
			rb(b, t, Vector3(0.18, 0.95, DEPTH + BAND_OUT * 2.0), Vector3(x + side * (BAND_OUT - 0.09), f * FLOOR_H + 0.35, 0), CONCRETE, 0.04)
			glazing(b, at(t, Vector3(x + side * 0.32, f * FLOOR_H + 1.9, -2.0), side * -PI * 0.5), 1.6, 1.4)
		glazing(b, at(t, Vector3(x + side * 0.32, 1.9, 2.5), side * -PI * 0.5), 1.6, 1.4)
	_roof(b, t)
	_centre(b, glow, t)
	for x: float in WINGS:
		_wing_frame(b, t, x)
		solid.append([Vector3(x, 1.8, front - 1.4), Vector3(7.2, 3.6, 2.8)])
	_stair_tower(b, t)
	solid.append([Vector3(0, ROOF_Y * 0.5, 0), Vector3(LENGTH + 0.6, ROOF_Y, DEPTH + 1.0)])
	solid.append([Vector3(0, ROOF_Y * 0.5, front - CENTRE_OUT * 0.5), Vector3(CENTRE_HALF * 2.0, ROOF_Y, CENTRE_OUT)])
	solid.append([Vector3(TOWER_X, TOWER_H * 0.5, TOWER_Z), Vector3(TOWER_SIZE, TOWER_H, TOWER_SIZE)])
	return solid


## The entrance canopy's two columns: they collide but stand on open paving (cells stay open).
static func canopy_columns() -> Array:
	var z := -DEPTH * 0.5 - CENTRE_OUT - CANOPY_OUT + 0.4
	return [[Vector3(-CENTRE_HALF + 1.0, 1.7, z), Vector3(0.5, 3.4, 0.5)], [Vector3(CENTRE_HALF - 1.0, 1.7, z), Vector3(0.5, 3.4, 0.5)]]


## One long face, built in the frame `f` (wall plane at its z = 0, facing -Z). The front leaves
## the entrance block's bays to `_centre` and gets air conditioners and planters.
static func _face(b: MeshKit.Builder, glow: MeshKit.Builder, f: Transform3D, front: bool) -> void:
	var skip_centre := -1.0 if front else 1.0
	var hl := LENGTH * 0.5
	var bays := int(LENGTH / BAY)
	var key := 11 if front else 23
	for i in bays + 1:
		var x := -hl + i * BAY
		bx(b, f, Vector3(0.7, ROOF_Y - 0.3, 0.55), Vector3(x, (ROOF_Y - 0.3) * 0.5 + 0.3, -0.27), BRICK)  # brick pier
		rb(b, f, Vector3(0.82, 0.3, 0.66), Vector3(x, 0.45, -0.3), BRICK_DARK, 0.03)                     # its foot
	for i in bays:
		var x := -hl + (i + 0.5) * BAY
		if skip_centre < 0.0 and absf(x) < CENTRE_HALF:
			continue
		# Ground floor: pink plaster with a framed window and a sill (a door every so often at the back).
		bx(b, f, Vector3(BAY - 0.7, 3.2, 0.2), Vector3(x, 1.95, -0.05), PLASTER)
		if not front and i % 6 == 2:
			MiranteSet.door(b, at(f, Vector3(x, 0.35, -0.16)), 1.6, 2.3, Color("4a4e54cc"), CONCRETE_LIGHT)
		else:
			MiranteSet.window(b, at(f, Vector3(x, 2.05, -0.16)), BAY - 1.6, 1.5, CONCRETE_LIGHT)
		# The upper floors: glass set back behind the bands.
		for fl in range(1, FLOORS):
			var y := fl * FLOOR_H
			var lit := MeshKit.hash01(key, i, fl) < 0.07
			glazing(b, at(f, Vector3(x, y + 0.95 + 1.25, -0.02)), BAY - 0.7, 2.5, lit, glow)
			if front and MeshKit.hash01(key + 1, i, fl) < 0.45: # an air conditioner on the band below the window
				MiranteSet.ac_unit(b, at(f, Vector3(x + (MeshKit.hash01(key, i, fl + 7) - 0.5) * 1.6, y + 0.5, -0.62)))
	# The bands: a slab at each floor line, an upturned parapet at its edge, a drip groove under it.
	for fl in range(1, FLOORS):
		var y := fl * FLOOR_H
		rb(b, f, Vector3(LENGTH + 0.6, 0.24, BAND_OUT), Vector3(0, y, -BAND_OUT * 0.5), CONCRETE, 0.04)
		rb(b, f, Vector3(LENGTH + 0.6, 0.95, 0.18), Vector3(0, y + 0.35, -BAND_OUT + 0.09), CONCRETE, 0.05)
		rb(b, f, Vector3(LENGTH + 0.62, 0.07, 0.2), Vector3(0, y + 0.82, -BAND_OUT + 0.09), CONCRETE_LIGHT, 0.02)   # coping
		rb(b, f, Vector3(LENGTH + 0.5, 0.05, 0.04), Vector3(0, y - 0.14, -BAND_OUT + 0.2), CONCRETE_DARK, 0.01)    # drip groove
		# Rain streaks down the parapets, a little darker.
		for k in int(LENGTH / 3.0):
			if MeshKit.hash01(key + 3, k, fl) < 0.4:
				rb(b, f, Vector3(0.3 + MeshKit.hash01(key, k, fl) * 0.5, 0.6, 0.02), Vector3(-hl + k * 3.0 + 1.2, y + 0.2, -BAND_OUT - 0.005), CONCRETE_DARK, 0.005)
		# Plants spilling over the first band of the front (the green along it in prefeitura2.jpg).
		if front and fl == 1:
			for k in int(LENGTH / 1.6):
				var px := -hl + (k + 0.5) * 1.6
				if (skip_centre < 0.0 and absf(px) < CENTRE_HALF) or MeshKit.hash01(key + 5, k, 0) < 0.3:
					continue
				var s := 0.45 + MeshKit.hash01(key + 6, k, 0) * 0.3
				b.blob(Vector3(s * 1.4, s, s), Vector3(px, y + 0.95 + s * 0.4, -BAND_OUT + 0.4), Vegetation.leaf(Vegetation.LEAVES[k % 5]), key + k, 0.3, 4, 7, Basis.IDENTITY, f, 0.2)
				if MeshKit.hash01(key + 7, k, 0) < 0.4: # trailing down the front of the parapet
					b.blob(Vector3(s * 0.7, s * 1.1, 0.18), Vector3(px + 0.2, y + 0.25, -BAND_OUT - 0.08), Vegetation.leaf(Vegetation.LEAVES[(k + 2) % 5]), key + k + 90, 0.3, 4, 6, Basis.IDENTITY, f)
	# The fascia at the roof line: deep, its own coping, a soffit under it.
	rb(b, f, Vector3(LENGTH + 0.8, 0.2, BAND_OUT), Vector3(0, ROOF_Y, -BAND_OUT * 0.5), CONCRETE_LIGHT.darkened(0.1), 0.03)
	rb(b, f, Vector3(LENGTH + 0.8, 1.5, 0.24), Vector3(0, ROOF_Y + 0.55, -BAND_OUT + 0.12), CONCRETE, 0.06)
	rb(b, f, Vector3(LENGTH + 0.84, 0.1, 0.3), Vector3(0, ROOF_Y + 1.33, -BAND_OUT + 0.12), CONCRETE_LIGHT, 0.03)
	for k in int(LENGTH / 2.5):
		if MeshKit.hash01(key + 9, k, 0) < 0.35:
			rb(b, f, Vector3(0.4, 1.0, 0.02), Vector3(-hl + k * 2.5 + 1.0, ROOF_Y + 0.4, -BAND_OUT - 0.005), CONCRETE_DARK, 0.005)


## The low metal roof behind the fascia, two slopes from a ridge along the middle, ribbed; the brick
## towers and boxes on it, a tank room, air conditioners and a vent.
static func _roof(b: MeshKit.Builder, t: Transform3D) -> void:
	var hl := LENGTH * 0.5
	var pitch := 0.07
	for side in [-1.0, 1.0]:
		var tilt := Basis(Vector3.RIGHT, side * pitch)
		var mid := Vector3(0, ROOF_Y + 0.5 + DEPTH * 0.25 * pitch, side * DEPTH * 0.25)
		rb(b, t, Vector3(LENGTH - 0.2, 0.1, DEPTH * 0.5), mid, ROOF, 0.02, tilt)
		for k in int(LENGTH / 0.9):
			rb(b, t, Vector3(0.07, 0.07, DEPTH * 0.5), mid + Vector3(-hl + 0.45 + k * 0.9, 0.07, 0), ROOF.lightened(0.06), 0.015, tilt)
	rb(b, t, Vector3(LENGTH - 0.2, 0.16, 0.5), Vector3(0, ROOF_Y + 0.5 + DEPTH * 0.25 * pitch * 2.0 + 0.05, 0), ROOF.darkened(0.12), 0.03) # ridge cap
	for e: Array in ROOF_TOWERS:
		var p: Vector3 = e[0]
		var s: Vector3 = e[1]
		var base := p + Vector3(0, ROOF_Y, 0)
		bx(b, t, s, base + Vector3(0, s.y * 0.5, 0), BRICK)
		rb(b, t, Vector3(s.x + 0.12, 0.35, s.z + 0.12), base + Vector3(0, s.y * 0.62, 0), CONCRETE_LIGHT, 0.04) # the concrete band
		rb(b, t, Vector3(s.x + 0.2, 0.22, s.z + 0.2), base + Vector3(0, s.y + 0.1, 0), CONCRETE, 0.04)          # cap
		for k in 4: # louvres high on the front
			rb(b, t, Vector3(1.2, 0.06, 0.12), base + Vector3(0, s.y * 0.8 + k * 0.16, -s.z * 0.5 - 0.04), CONCRETE_DARK, 0.01, Basis(Vector3.RIGHT, 0.5))
		b.rcyl(0.1, 2.4, base + Vector3(s.x * 0.3, s.y + 1.3, s.z * 0.3), Props.STEEL, 8, 0.02, Basis.IDENTITY, t)   # a mast
	for e: Array in [[Vector3(-3, 0, -1), Vector3(7, 3.0, 5), BRICK], [Vector3(6, 0, 1), Vector3(4.5, 3.2, 4), MiranteSet.PAINT_WHITE],
			[Vector3(30, 0, 0), Vector3(5, 2.6, 4), BRICK]]:
		var p: Vector3 = e[0]
		var s: Vector3 = e[1]
		var c: Color = e[2]
		bx(b, t, s, p + Vector3(0, ROOF_Y + s.y * 0.5, 0), c)
		rb(b, t, Vector3(s.x + 0.14, 0.16, s.z + 0.14), p + Vector3(0, ROOF_Y + s.y + 0.08, 0), CONCRETE, 0.03)
	MiranteSet.door(b, at(t, Vector3(6, ROOF_Y + 0.2, -1.0 - 0.02)), 0.9, 2.1, Color("5a5e64cc"), CONCRETE_LIGHT)
	for k in 7: # condensers on the roof
		var p := Vector3(-28.0 + k * 8.5, ROOF_Y + 0.9, 5.5 if k % 2 == 0 else -5.0)
		rb(b, t, Vector3(1.0, 0.8, 0.5), p, MiranteSet.PAINT_WHITE, 0.04)
		b.rcyl(0.3, 0.04, p + Vector3(0, 0, -0.26), Props.DARK, 14, 0.01, Basis(Vector3.RIGHT, PI * 0.5), t)
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.35, 0), Vector2(0.35, 0.8), Vector2(0.5, 0.9), Vector2(0.5, 1.0), Vector2(0, 1.05)]),
		Vector3(-26, ROOF_Y + 0.6, -2.0), Props.STEEL, 10, Basis.IDENTITY, t)   # a turbine vent


## The entrance block: steps forward from the front, glass in front of every floor, the big space
## frame over the first two floors, the doors under a concrete canopy on two columns.
static func _centre(b: MeshKit.Builder, glow: MeshKit.Builder, t: Transform3D) -> void:
	var front := -DEPTH * 0.5
	var z := front - CENTRE_OUT
	var f := at(t, Vector3(0, 0, z))
	bx(b, t, Vector3(CENTRE_HALF * 2.0, ROOF_Y, CENTRE_OUT), Vector3(0, ROOF_Y * 0.5, front - CENTRE_OUT * 0.5), Color("3a3836"))
	for side in [-1.0, 1.0]: # brick returns at its corners
		bx(b, f, Vector3(1.0, ROOF_Y + 0.4, 1.0), Vector3(side * (CENTRE_HALF - 0.5), (ROOF_Y + 0.4) * 0.5, 0.2), BRICK)
		bx(b, t, Vector3(0.4, ROOF_Y, CENTRE_OUT), Vector3(side * (CENTRE_HALF - 0.2), ROOF_Y * 0.5, front - CENTRE_OUT * 0.5), BRICK)
	for fl in range(1, FLOORS):
		var y := fl * FLOOR_H
		glazing(b, at(f, Vector3(0, y + 1.75, -0.02)), CENTRE_HALF * 2.0 - 2.0, 3.0, fl == 2, glow)
		rb(b, f, Vector3(CENTRE_HALF * 2.0 - 1.8, 0.3, 0.5), Vector3(0, y, -0.1), CONCRETE, 0.04)
	rb(b, f, Vector3(CENTRE_HALF * 2.0 + 0.2, 1.6, 0.4), Vector3(0, ROOF_Y + 0.55, 0.1), CONCRETE, 0.06)
	# The doors: a glazed screen, two pairs of doors, a dark transom with the lettering's panel.
	glazing(b, at(f, Vector3(0, 1.7, -0.02)), CENTRE_HALF * 2.0 - 2.0, 3.0)
	for dx in [-2.4, 2.4]:
		for leaf in [-0.62, 0.62]:
			rb(b, f, Vector3(1.18, 2.4, 0.06), Vector3(dx + leaf, 1.4, -0.1), MeshKit.surf(Color("1c2630"), MeshKit.GLASS), 0.01)
			rb(b, f, Vector3(0.05, 0.9, 0.05), Vector3(dx + leaf * 0.12, 1.25, -0.16), Props.STEEL, 0.01)        # pull bar
	# The canopy: a slab with a deep edge, two round columns, downlights let into it.
	var cz := -CANOPY_OUT * 0.5
	rb(b, f, Vector3(CENTRE_HALF * 2.0 - 0.4, 0.28, CANOPY_OUT + 0.4), Vector3(0, 3.55, cz), CONCRETE_LIGHT, 0.05)
	rb(b, f, Vector3(CENTRE_HALF * 2.0 - 0.3, 0.55, 0.2), Vector3(0, 3.5, -CANOPY_OUT - 0.1), CONCRETE, 0.05)
	for cx in [-CENTRE_HALF + 1.0, CENTRE_HALF - 1.0]:
		b.rcyl(0.22, 3.4, Vector3(cx, 1.7, -CANOPY_OUT + 0.4), CONCRETE_LIGHT, 14, 0.04, Basis.IDENTITY, f)
		b.rcyl(0.3, 0.2, Vector3(cx, 0.1, -CANOPY_OUT + 0.4), CONCRETE_DARK, 14, 0.04, Basis.IDENTITY, f)
	for k in 4:
		b.rcyl(0.14, 0.04, Vector3(-4.5 + k * 3.0, 3.4, cz), Props.STEEL, 10, 0.01, Basis.IDENTITY, f)
		if k == 1:
			glow.rcyl(0.11, 0.03, Vector3(-4.5 + k * 3.0, 3.38, cz), Color.WHITE, 10, 0.01, Basis.IDENTITY, f)
	# The big space frame over the first two floors, standing out from the glass.
	space_frame(b, at(f, Vector3(0, FLOOR_H - 0.2, -1.2)), CENTRE_HALF * 2.0 + 1.2, FLOOR_H * 2.0 + 1.6, 1.2)
	# Steps up to the doors along the canopy, the kind you trip on.
	for k in 2:
		rb(b, f, Vector3(CENTRE_HALF * 2.0 - 3.0, 0.12, 0.45), Vector3(0, 0.06, -CANOPY_OUT - 0.6 - k * 0.45), CONCRETE_LIGHT, 0.02)


## A wing's space frame over the first floor, with its brick buttress widening to the ground under it.
static func _wing_frame(b: MeshKit.Builder, t: Transform3D, x: float) -> void:
	var front := -DEPTH * 0.5
	var foot := Vector3(x, 0, front - 1.4)
	b.frustum(Vector2(8.0, 3.0), Vector2(5.8, 2.2), FLOOR_H, foot, BRICK, Basis.IDENTITY, t, Vector2(0, 0.4))
	rb(b, t, Vector3(6.2, 0.2, 2.6), foot + Vector3(0, FLOOR_H + 0.05, 0.2), CONCRETE_LIGHT, 0.04)                 # its cap
	rb(b, t, Vector3(8.3, 0.25, 3.3), foot + Vector3(0, 0.12, 0), CONCRETE_DARK, 0.04)                              # and its foot
	space_frame(b, at(t, Vector3(x, FLOOR_H + 0.15, front - BAND_OUT - 0.8)), 7.2, FLOOR_H + 0.4, 1.0, 1.2)


## The stair tower at the north end: a concrete core inside a tall blue space frame on its front and
## outer side, a brick buttress at its foot, a little roof on top.
static func _stair_tower(b: MeshKit.Builder, t: Transform3D) -> void:
	var c := Vector3(TOWER_X, 0, TOWER_Z)
	var s := TOWER_SIZE
	bx(b, t, Vector3(s - 1.6, TOWER_H, s - 1.6), c + Vector3(0, TOWER_H * 0.5, 0), CONCRETE_LIGHT)
	for k in int(TOWER_H / 2.4): # the stair windows, a slot up the core
		rb(b, t, Vector3(0.7, 1.2, 0.06), c + Vector3(0, 1.4 + k * 2.4, -(s - 1.6) * 0.5 - 0.02), Props.GLASS, 0.01)
	space_frame(b, at(t, c + Vector3(0, 0, -s * 0.5 + 0.5)), s, TOWER_H, 1.0, 1.25)
	space_frame(b, at(t, c + Vector3(s * 0.5 - 0.5, 0, 0), -PI * 0.5), s, TOWER_H, 1.0, 1.25)
	space_frame(b, at(t, c + Vector3(-s * 0.5 + 0.5, 0, 0), PI * 0.5), s, TOWER_H, 1.0, 1.25)
	rb(b, t, Vector3(s + 0.4, 0.3, s + 0.4), c + Vector3(0, TOWER_H + 0.15, 0), CONCRETE, 0.05)
	b.frustum(Vector2(s + 2.4, s + 2.0), Vector2(s + 0.2, s + 0.1), 3.0, c, BRICK, Basis.IDENTITY, t)


# --- The grounds ---------------------------------------------------------------------------

## The lawn sign: "Prefeitura Municipal de Joinville" on a blue board inside a space frame, on a
## low brick bed of flowers. Its foot at the origin of `f`, facing -Z. The letters are the map's
## (`SIGN_AT`). Returns colliders.
const SIGN_W := 11.0
const SIGN_AT := Vector3(0, 1.35, -0.32)
static func lawn_sign(b: MeshKit.Builder, f: Transform3D) -> Array:
	rb(b, f, Vector3(SIGN_W + 1.6, 0.45, 2.0), Vector3(0, 0.225, 0.3), BRICK, 0.04)                 # the bed
	rb(b, f, Vector3(SIGN_W + 1.3, 0.06, 1.7), Vector3(0, 0.44, 0.3), Color("3a2a1e"), 0.01)         # soil
	for k in 9:
		var flower: Color = FLOWER_RED if k % 2 == 0 else FLOWER_YELLOW
		Vegetation.shrub(b, f, Vector3(-SIGN_W * 0.5 + k * SIGN_W / 8.0, 0.42, 0.75), 0.7, flower, 40 + k)
	rb(b, f, Vector3(SIGN_W, 1.0, 0.12), Vector3(0, 1.35, -0.2), MeshKit.surf(Color("1f3f86"), MeshKit.PAINT), 0.03)
	space_frame(b, at(f, Vector3(0, 0.45, -0.2)), SIGN_W + 0.6, 1.8, 0.4, 0.6)
	return [[Vector3(0, 1.1, 0.1), Vector3(SIGN_W + 1.6, 2.2, 1.2)]]


## A flower bed edged in brick, `w` × `d`, its foot at the origin of `f`.
static func flower_bed(b: MeshKit.Builder, f: Transform3D, w: float, d: float, key: int) -> void:
	rb(b, f, Vector3(w, 0.35, d), Vector3(0, 0.175, 0), BRICK, 0.04)
	rb(b, f, Vector3(w - 0.3, 0.06, d - 0.3), Vector3(0, 0.34, 0), Color("3a2a1e"), 0.01)
	var n := maxi(1, int(w / 0.9))
	for i in n:
		var flower: Color = FLOWER_RED if (i + key) % 3 != 0 else FLOWER_YELLOW
		Vegetation.shrub(b, f, Vector3(-w * 0.5 + (i + 0.5) * w / n, 0.32, 0), minf(0.8, d * 0.7), flower, key * 13 + i)


## The round concrete pad on the south lawn, centred at the origin of `f`: an apron, a yellow ring,
## the H, and lights round its rim (`glow`).
const PAD_R := 6.5
static func pad(b: MeshKit.Builder, f: Transform3D, glow: MeshKit.Builder) -> void:
	b.rcyl(PAD_R, 0.1, Vector3(0, 0.05, 0), CONCRETE_LIGHT, 32, 0.04, Basis.IDENTITY, f)
	b.lathe(PackedVector2Array([Vector2(PAD_R - 0.5, 0.105), Vector2(PAD_R - 0.9, 0.105)]), Vector3.ZERO, MeshKit.surf(FLAG_YELLOW, MeshKit.PAINT), 32, Basis.IDENTITY, f)
	for x in [-1.3, 1.3]:
		rb(b, f, Vector3(0.6, 0.02, 3.6), Vector3(x, 0.11, 0), MiranteSet.PAINT_WHITE, 0.005)
	rb(b, f, Vector3(2.0, 0.02, 0.6), Vector3(0, 0.11, 0), MiranteSet.PAINT_WHITE, 0.005)
	for k in 8:
		var a := TAU * k / 8.0
		var p := Vector3(cos(a) * (PAD_R + 0.15), 0.08, sin(a) * (PAD_R + 0.15))
		b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.1, 0), Vector2(0.08, 0.12), Vector2(0, 0.14)]), p, Props.STEEL, 8, Basis.IDENTITY, f)
		if k % 2 == 0:
			glow.lathe(PackedVector2Array([Vector2(0, 0.1), Vector2(0.06, 0.1), Vector2(0.05, 0.16), Vector2(0, 0.17)]), p, Color.WHITE, 8, Basis.IDENTITY, f)


## A zig-zag ramp across the lawn from `a` to `b` (in the frame `f`, flat), in `legs` legs, `w` wide:
## pavers on `g`, rails both sides on `b`. Returns colliders (the rails) in the frame of `f`.
static func ramp(b: MeshKit.Builder, g: MeshKit.Builder, f: Transform3D, start: Vector3, end: Vector3, legs: int, swing: float, w: float) -> Array:
	var solid := []
	var pts := [start]
	for k in range(1, legs):
		var p := start.lerp(end, float(k) / legs)
		p.x += swing if k % 2 == 1 else -swing
		pts.append(p)
	pts.append(end)
	for k in pts.size() - 1:
		var a: Vector3 = pts[k]
		var c: Vector3 = pts[k + 1]
		var dir := (c - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x) * w * 0.5
		var y := Vector3(0, 0.045, 0)
		g.ground_quad(f * (a - side + y), f * (c - side + y), f * (c + side + y), f * (a + side + y), PAVING)
		var yaw := atan2(-dir.x, -dir.z)
		for s in [-1.0, 1.0]:
			var off: Vector3 = side * s * 1.08
			b.tube(PackedVector3Array([a + off + Vector3(0, 0.95, 0), c + off + Vector3(0, 0.95, 0)]), 0.03, Props.STEEL, 6, -1.0, f)
			b.tube(PackedVector3Array([a + off + Vector3(0, 0.5, 0), c + off + Vector3(0, 0.5, 0)]), 0.02, Props.STEEL, 6, -1.0, f)
			var n := maxi(1, int(a.distance_to(c) / 2.0))
			for i in n + 1:
				var p := a.lerp(c, float(i) / n) + off
				b.rcyl(0.03, 0.95, p + Vector3(0, 0.475, 0), Props.STEEL, 6, 0.01, Basis.IDENTITY, f)
			solid.append([(a + c) * 0.5 + off + Vector3(0, 0.5, 0), Vector3(0.1, 1.0, a.distance_to(c)), Basis(Vector3.UP, yaw)])
	return solid
