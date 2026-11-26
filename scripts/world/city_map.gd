class_name CityMap
extends GameMap
## The town on Joinville's plan: all of joinville.png (CityData.FRAME), the five mission POIs in it.
##
## Inside the frame, CityData's streets, river, hill and squares are painted onto a grid of
## CITY_CELL-metre cells:
##
##   OUT     beyond the edge wall            WATER   the river (bridges are STREET cells)
##   BLOCK   city blocks, filled with        FOREST  the hill, closed except its road
##           solid buildings                 PARK    the cemetery, open ground
##   STREET  roads, bridges, driveways       LOT     a POI's grounds;  BUILT  a POI's structures
##   SQUARE  the paved places
##
## The grid is only for navigation and for where buildings stand: what zombies think is open is
## exactly what is open. What people see of the streets is StreetNet's: carriageways, pavements
## and junctions at their real widths, as meshes that follow the polylines (`streets`).
## The city is flat at y = 0. Morro da Boa Vista rises out of it: forest cells, and the road and
## lot inside the forest, take their height from CityHeights (read off the topography map), eased
## in over Config.CITY_HILL_FADE from the forest's edge. `ground_y` answers for any point.
## POI buildings are placeholders (solid shells, no interiors) standing where the real ones do.
##
## Everything is merged into four meshes (ground, buildings, trees, lit windows). Layout is
## fixed; only its own seeded rng picks building sizes, heights and trees, so every peer builds
## the same city. `plan_image` and `reference_overlay` draw what was chosen (`--city-plan=DIR`).

const OUT := 0
const BLOCK := 1
const STREET := 2
const WATER := 3
const FOREST := 4
const PARK := 5
const LOT := 6
const BUILT := 7
const SQUARE := 8

const PLAN_COLORS := [Color("0c0d0f"), Color("6e675d"), Color("2c2e32"), Color("27506e"), Color("1f3d24"),
	Color("3f6a3a"), Color("b0a070"), Color("f0e8d0"), Color("7a6a58")]
const GROUND_COLORS := { OUT: Color("0d0e0f"), WATER: Color("0e1c26"), FOREST: Color("18261a"),
	PARK: Color("26361f"), LOT: Color("4a4b4d"), SQUARE: Color("4d4741") }
## The streets' surfaces (StreetNet pieces), in the world and on the plan.
const SURFACE_COLORS := { "setts": Color("45403b"), "asphalt": Color("27282b"), "flags": Color("5c5954") }
const PLAN_SURFACE := { "setts": Color("9a8a72"), "asphalt": Color("3a3c42"), "flags": Color("cfc6b4") }
const PLAN_COVERED := Color("c08a3a")
const LAYER_Y := [0.03, 0.05]   ## height of each StreetNet layer over the ground
const GROUND := Color("302d2a")              ## unpaved ground between the streets and the houses
const VERGE := Color("26291f")               ## the hill road's sides
const FACADES := [Color("7b7469"), Color("6d7078"), Color("8a8377"), Color("5f5a55"), Color("77706a"),
	Color("6a6e66"), Color("807a80"), Color("8d8a82")]
const ASPHALT := Color("242528")
const SHOPFRONT := Color("2a2b2f")
const PAINT := Color("b8b8a8")
const LEAVES := [Color("1c3320"), Color("23402a"), Color("182b1c"), Color("2a4a2c")]

var nav: NavGrid
var blocks: CityBlocks              ## the îlots and their houses
var street_kind := PackedByteArray() ## per cell: 0, 1 a street, 2 a main street (what a house fronts)
var _full := true
var streets: StreetNet                ## the street plan: graph, junctions, surfaces
var detail_area := PackedVector2Array() ## (x, z) polygon: only streets in it are built (empty: all)
var street_triangles := 0
var grid := PackedByteArray()        ## one cell type per cell, row by row from the north-west
var gw := 0
var gh := 0
var lo := Vector2.ZERO               ## (x, z) of the grid's north-west corner
var cell := Config.CITY_CELL
var boundary := PackedVector2Array() ## the map's edge, (x, z) in metres
var building_count := 0
var landmarks := {}
var prop_counts := {}               ## set piece props by kind

var heights := PackedFloat32Array()  ## ground height at every cell corner, (gw + 1) x (gh + 1)
var _raised := PackedByteArray()     # 1 where any corner of the cell is above 0
var _floors := PackedByteArray()     # storeys of the building on each BLOCK cell (for the plan)
var _b := MeshKit.Builder.new()      # buildings, walls, POIs
var _g := MeshKit.Builder.new()      # ground and paint
var _trees := MeshKit.Builder.new()
var _glow := MeshKit.Builder.new()   # lit windows and lamps
var _shells := MeshKit.Builder.new() # the open houses' outer walls (HouseStreamer cuts each away while its floors stand)
var houses: HouseStreamer = null     ## builds the open houses' floors near the camera (S246)
var _body := StaticBody3D.new()
var _rng := RandomNumberGenerator.new()


## `full` false lays the city out (grid, building heights, POI footprints) without the ground,
## trees, navigation or any node but the empty root: enough for a picture of it.
func _init(full := true, detail := PackedVector2Array()) -> void:
	name = "city"
	outdoor = true
	all_weapons = true
	nav_refresh = 0.35
	_rng.seed = 18510309
	root = Node3D.new()
	root.name = "City"
	_body.collision_layer = Config.LAYER_WORLD
	_body.collision_mask = 0
	root.add_child(_body)

	detail_area = detail
	_full = full
	streets = StreetNet.new(CityData.STREETS)
	_edge()
	_layout()
	_hill()
	_buildings()
	_pois()
	if not full:
		return
	_scenery()
	_navigation()
	_ground()
	_hill_ground()
	_street_surfaces()
	_street_dressing()
	_forest()
	_edge_wall()

	root.add_child(_g.instance(null, false))
	root.add_child(_b.instance(null, false))
	root.add_child(_trees.instance(null, false))
	root.add_child(_glow.instance(MeshKit.emissive(Color("ffd9a0"), 2.5), false))
	if not blocks.open_houses.is_empty():
		var shells := _shells.instance(HouseStreamer.shell_material(), false)
		shells.name = "OpenHouseShells"
		root.add_child(shells)
		houses = HouseStreamer.new(self, shells.material_override)
		root.add_child(houses)


# --- GameMap ------------------------------------------------------------------------

## A mission starts at its POI; free play at the bus terminal.
func player_spawn() -> Vector3:
	return poi_pos(mission if CityData.POIS.has(mission) else "terminal") + Vector3(0, 0.1, 0)


func player_spawn_point(_slot := 0) -> Vector3:
	var p := player_spawn() + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))
	p.y = ground_y(p) + 0.1
	return p


## A street corner near a player, out of everyone's sight when there is one.
func zombie_spawn_point(avoid: Array) -> Vector3:
	var around: Vector3 = avoid[randi() % avoid.size()] if not avoid.is_empty() else player_spawn()
	var fallback := Vector3.INF
	for i in Config.CITY_SPAWN_TRIES:
		var a := randf() * TAU
		var d := randf_range(Config.CITY_SPAWN_NEAR, Config.CITY_SPAWN_FAR)
		var p := around + Vector3(cos(a) * d, 0, sin(a) * d)
		if nav.is_blocked(p):
			continue
		p = nav.center_of(nav.cell_of(p))
		p.y = ground_y(p) + 0.1
		var hidden := true
		var clear := true
		for q: Vector3 in avoid:
			if p.distance_to(q) < Config.SPAWN_MIN_DIST:
				clear = false
			elif nav.is_direct(p, q):
				hidden = false
		if not clear or not nav.reachable(p, around):
			continue
		if hidden:
			return p
		fallback = p
	if fallback != Vector3.INF:
		return fallback
	var last := nav.nearest_free(around + Vector3(Config.CITY_SPAWN_NEAR, 0, 0))
	last.y = ground_y(last) + 0.1
	return last


func is_direct(from: Vector3, to: Vector3) -> bool:
	return nav.is_direct(from, to)


func nav_target(from: Vector3, to: Vector3, lane := 0.0) -> Vector3:
	return nav.nav_target(from, to, lane)


# --- Questions about the layout ---------------------------------------------------------

## Where a player stands at a POI ("hospital", "terminal", "prefeitura", "batalhao", "mirante").
func poi_pos(id: String) -> Vector3:
	var poi: Dictionary = CityData.POIS[id]
	var p := CityData.to_world(poi.at)
	p.y = ground_y(p)
	return p


## Bilinear between the four corners of the cell under `p`.
func ground_y(p: Vector3) -> float:
	if heights.is_empty():
		return 0.0
	var fx := clampf((p.x - lo.x) / cell, 0.0, gw - 0.001)
	var fz := clampf((p.z - lo.y) / cell, 0.0, gh - 0.001)
	var c := floori(fx)
	var r := floori(fz)
	var i := r * (gw + 1) + c
	var top := lerpf(heights[i], heights[i + 1], fx - c)
	var bottom := lerpf(heights[i + gw + 1], heights[i + gw + 2], fx - c)
	return lerpf(top, bottom, fz - r)


func contains(p: Vector3) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), boundary)


func area_km2() -> float:
	return _poly_area(boundary) / 1.0e6


func type_at(p: Vector3) -> int:
	var c := floori((p.x - lo.x) / cell)
	var r := floori((p.z - lo.y) / cell)
	if c < 0 or r < 0 or c >= gw or r >= gh:
		return OUT
	return grid[r * gw + c]


func layout_hash() -> int:
	return hash([hash(grid), hash(_floors), building_count])


# --- The edge and the grid ------------------------------------------------------------

## The map's edge in (x, z) metres: CityData.FRAME.
static func edge_polygon() -> PackedVector2Array:
	var f := CityData.FRAME
	return PackedVector2Array([CityData.to_plan(f.position), CityData.to_plan(Vector2(f.end.x, f.position.y)),
		CityData.to_plan(f.end), CityData.to_plan(Vector2(f.position.x, f.end.y))])


static func _poly_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		a += poly[i].cross(poly[(i + 1) % poly.size()])
	return absf(a) * 0.5


func _edge() -> void:
	boundary = edge_polygon()

	var hi := boundary[0]
	lo = boundary[0]
	for p in boundary:
		lo = lo.min(p)
		hi = hi.max(p)
	lo = (lo / cell).floor() * cell - Vector2(cell, cell)
	gw = ceili((hi.x - lo.x) / cell) + 1
	gh = ceili((hi.y - lo.y) / cell) + 1
	grid.resize(gw * gh)
	_floors.resize(gw * gh)
	street_kind.resize(gw * gh)


func _mask(types: Array) -> int:
	var m := 0
	for t: int in types:
		m |= 1 << t
	return m


func _plan(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(CityData.to_plan(p))
	return out


## Paint the inside of a polygon, over cells whose type is in `over`.
func _fill(poly: PackedVector2Array, type: int, over: int) -> void:
	var z0 := poly[0].y
	var z1 := poly[0].y
	for p in poly:
		z0 = minf(z0, p.y)
		z1 = maxf(z1, p.y)
	var n := poly.size()
	for r in range(maxi(0, floori((z0 - lo.y) / cell)), mini(gh - 1, floori((z1 - lo.y) / cell)) + 1):
		var z := lo.y + (r + 0.5) * cell
		var xs: Array[float] = []
		for i in n:
			var a := poly[i]
			var b := poly[(i + 1) % n]
			if (a.y <= z) != (b.y <= z):
				xs.append(a.x + (z - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		for k in range(0, xs.size() - 1, 2):
			var c0 := maxi(0, ceili((xs[k] - lo.x) / cell - 0.5))
			var c1 := mini(gw - 1, floori((xs[k + 1] - lo.x) / cell - 0.5))
			for c in range(c0, c1 + 1):
				var i := r * gw + c
				if (over >> grid[i]) & 1 == 1:
					grid[i] = type


## Paint a band `width` metres wide along a line, over cells whose type is in `over`.
## `kind` (when given) is written to street_kind too, the larger winning.
func _stamp(line: PackedVector2Array, width: float, type: int, over: int, kind := 0) -> void:
	var half := width * 0.5
	for s in line.size() - 1:
		var a := line[s]
		var b := line[s + 1]
		var c0 := maxi(0, floori((minf(a.x, b.x) - half - lo.x) / cell))
		var c1 := mini(gw - 1, floori((maxf(a.x, b.x) + half - lo.x) / cell))
		var r0 := maxi(0, floori((minf(a.y, b.y) - half - lo.y) / cell))
		var r1 := mini(gh - 1, floori((maxf(a.y, b.y) + half - lo.y) / cell))
		for r in range(r0, r1 + 1):
			for c in range(c0, c1 + 1):
				var i := r * gw + c
				if (over >> grid[i]) & 1 == 0:
					continue
				var p := Vector2(lo.x + (c + 0.5) * cell, lo.y + (r + 0.5) * cell)
				if Geometry2D.get_closest_point_to_segment(p, a, b).distance_squared_to(p) <= half * half:
					grid[i] = type
					street_kind[i] = maxi(street_kind[i], kind)


func _layout() -> void:
	var inside := _mask([BLOCK, STREET, WATER, FOREST, PARK, LOT, SQUARE])
	_fill(boundary, BLOCK, _mask([OUT]))
	_fill(_plan(CityData.FOREST), FOREST, _mask([BLOCK]))
	for park: Array in CityData.PARKS:
		_fill(_plan(park), PARK, _mask([BLOCK]))
	for sq: Dictionary in CityData.SQUARES:
		_fill(_plan(sq.pts), SQUARE, _mask([BLOCK, PARK]))
	_stamp(_plan(CityData.RIVER), CityData.RIVER_WIDTH, WATER, _mask([BLOCK, FOREST, PARK]))
	for i in streets.lines.size():
		var widest := 1.0
		for f: float in streets.lines[i].f:
			widest = maxf(widest, f)
		var sp: Dictionary = streets.specs[i]
		var w: float = sp.road * widest + sp.walk[0] + sp.walk[1]
		_stamp(streets.lines[i].pts, maxf(w, CityData.NAV_MIN_WIDTH), STREET, inside, 2 if streets.streets[i].kind == "principale" else 1)
	for id: String in CityData.POIS:
		var poi: Dictionary = CityData.POIS[id]
		_fill(_plan(poi.lot), LOT, _mask([BLOCK, FOREST, PARK, WATER]))
		_stamp(_plan([poi.at, poi.gate]), CityData.DRIVE, STREET, inside)


# --- The hill -------------------------------------------------------------------------

## Corner heights: CityHeights where the hill is (forest, and the road and lot inside it), eased
## from 0 at the forest's edge to full height CITY_HILL_FADE metres in. Everything else stays 0.
func _hill() -> void:
	heights.resize((gw + 1) * (gh + 1))
	_raised.resize(gw * gh)
	var forest := _plan(CityData.FOREST)
	var fade := maxi(1, ceili(Config.CITY_HILL_FADE / cell))
	# Steps (in cells) from the nearest non-hill cell, up to `fade`.
	var steps := PackedInt32Array()
	steps.resize(gw * gh)
	var queue := PackedInt32Array()
	for r in gh:
		for c in gw:
			var i := r * gw + c
			var t := grid[i]
			var hill := t == FOREST or ((t == STREET or t == LOT) and Geometry2D.is_point_in_polygon(
				Vector2(lo.x + (c + 0.5) * cell, lo.y + (r + 0.5) * cell), forest))
			steps[i] = fade if hill else 0
			if not hill:
				queue.append(i)
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var r := i / gw
		var c := i % gw
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nc := c + d.x
			var nr := r + d.y
			if nc < 0 or nr < 0 or nc >= gw or nr >= gh:
				continue
			var j := nr * gw + nc
			if steps[j] > steps[i] + 1:
				steps[j] = steps[i] + 1
				queue.append(j)
	for r in gh + 1:
		for c in gw + 1:
			var near := fade
			for k: Vector2i in [Vector2i(c - 1, r - 1), Vector2i(c, r - 1), Vector2i(c - 1, r), Vector2i(c, r)]:
				near = mini(near, steps[k.y * gw + k.x] if k.x >= 0 and k.y >= 0 and k.x < gw and k.y < gh else 0)
			if near == 0:
				continue
			var at := lo + Vector2(c, r) * cell
			var w := smoothstep(0.0, float(fade), float(near))
			heights[r * (gw + 1) + c] = CityHeights.at_px(at / CityData.M_PER_PX + CityData.ORIGIN_PX) * w
	for r in gh:
		for c in gw:
			var i := r * (gw + 1) + c
			if heights[i] > 0.0 or heights[i + 1] > 0.0 or heights[i + gw + 1] > 0.0 or heights[i + gw + 2] > 0.0:
				_raised[r * gw + c] = 1


## Lowest and highest corner of a run of `n` cells starting at (c, r).
func _span(r: int, c: int, n: int) -> Vector2:
	var low := INF
	var high := -INF
	for k in n + 1:
		for i: int in [r * (gw + 1) + c + k, (r + 1) * (gw + 1) + c + k]:
			low = minf(low, heights[i])
			high = maxf(high, heights[i])
	return Vector2(low, high)


func _corner(r: int, c: int) -> Vector3:
	return Vector3(lo.x + c * cell, heights[r * (gw + 1) + c], lo.y + r * cell)


## The raised ground as one mesh and one height-map collider. Whole 4 x 4 blocks of forest are one
## quad (nobody walks there); roads and lots get a quad per cell.
func _hill_ground() -> void:
	var c0 := gw
	var c1 := -1
	var r0 := gh
	var r1 := -1
	for r in gh:
		for c in gw:
			if _raised[r * gw + c] == 1:
				c0 = mini(c0, c)
				c1 = maxi(c1, c)
				r0 = mini(r0, r)
				r1 = maxi(r1, r)
	if c1 < 0:
		return
	var done := PackedByteArray()
	done.resize(gw * gh)
	const B := 4
	for r in range(r0, r1 + 1, B):
		for c in range(c0, c1 + 1, B):
			if r + B > gh or c + B > gw:
				continue
			var all_forest := true
			for rr in range(r, r + B):
				for cc in range(c, c + B):
					if grid[rr * gw + cc] != FOREST or _raised[rr * gw + cc] == 0:
						all_forest = false
			if not all_forest:
				continue
			_g.ground_quad(_corner(r, c), _corner(r, c + B), _corner(r + B, c + B), _corner(r + B, c), GROUND_COLORS[FOREST])
			for rr in range(r, r + B):
				for cc in range(c, c + B):
					done[rr * gw + cc] = 1
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			var i := r * gw + c
			if _raised[i] == 0 or done[i] == 1:
				continue
			var t := grid[i]
			var color: Color = VERGE if t == STREET else GROUND_COLORS.get(t, GROUND_COLORS[LOT])
			_g.ground_quad(_corner(r, c), _corner(r, c + 1), _corner(r + 1, c + 1), _corner(r + 1, c), color)
	# One height-map collider over the raised area, scaled up from 1 m to one cell.
	var w := c1 - c0 + 2
	var d := r1 - r0 + 2
	var data := PackedFloat32Array()
	data.resize(w * d)
	for z in d:
		for x in w:
			data[z * w + x] = heights[(r0 + z) * (gw + 1) + c0 + x] / cell
	var shape := HeightMapShape3D.new()
	shape.map_width = w
	shape.map_depth = d
	shape.map_data = data
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * cell),
		Vector3(lo.x + (c0 + (w - 1) * 0.5) * cell, 0.0, lo.y + (r0 + (d - 1) * 0.5) * cell))
	_body.add_child(cs)


# --- City blocks ------------------------------------------------------------------------

func _open(c: int, r: int) -> bool:
	if c < 0 or r < 0 or c >= gw or r >= gh:
		return false
	var t := grid[r * gw + c]
	return t == STREET or t == PARK or t == LOT or t == SQUARE


## The town's mass: îlots closed by rows of houses (CityBlocks). The layout always; walls, roofs
## and collision only for a full build.
func _buildings() -> void:
	blocks = CityBlocks.new(self)
	blocks.plan()
	building_count = blocks.houses.size()
	blocks.paint_floors(_floors)
	if _full:
		blocks.build(_b, _g, _glow, _body, _shells)


# --- Building blocks --------------------------------------------------------------------

func _collide(center: Vector3, size: Vector3, basis := Basis.IDENTITY) -> void:
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.transform = Transform3D(basis, center)
	_body.add_child(cs)


## Every cell a rectangle touches becomes BUILT (closed to walkers).
func _mark_built(center: Vector2, half: Vector2) -> void:
	var c0 := maxi(0, floori((center.x - half.x - lo.x) / cell))
	var c1 := mini(gw - 1, ceili((center.x + half.x - lo.x) / cell) - 1)
	var r0 := maxi(0, floori((center.y - half.y - lo.y) / cell))
	var r1 := mini(gh - 1, ceili((center.y + half.y - lo.y) / cell) - 1)
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			if grid[r * gw + c] != OUT:
				grid[r * gw + c] = BUILT


## A solid upright box: seen, bumped into and walked around.
func _solid(center: Vector3, size: Vector3, color: Color) -> void:
	_b.box(size, center, color)
	_collide(center, size)
	_mark_built(Vector2(center.x, center.z), Vector2(size.x, size.z) * 0.5)


## A prop from Props: its solid parts collide and close the cells under them.
func _put(colliders: Array, t: Transform3D) -> void:
	for c: Array in colliders:
		var center: Vector3 = c[0]
		var size: Vector3 = c[1]
		var at := t * center
		_collide(at, size, t.basis)
		var half := Vector2(absf(t.basis.x.x) * size.x + absf(t.basis.z.x) * size.z,
			absf(t.basis.x.z) * size.x + absf(t.basis.z.z) * size.z) * 0.5
		_mark_built(Vector2(at.x, at.z), half)


## A wall from `a` to `b` (x, z). With `walkers` it also closes the cells it crosses, except
## street cells, and leaves a gap wherever it comes within `gap` metres of the line `clear`.
func _wall(a: Vector2, b: Vector2, height: float, color: Color, walkers := false,
		clear := PackedVector2Array(), gap := 7.0) -> void:
	var length := a.distance_to(b)
	var pieces := maxi(1, ceili(length / 8.0)) if walkers else 1
	var dir := (b - a) / maxf(length, 0.001)
	var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x))
	for i in pieces:
		var p := a.lerp(b, float(i) / pieces)
		var q := a.lerp(b, float(i + 1) / pieces)
		var mid := (p + q) * 0.5
		if clear.size() == 2 and Geometry2D.get_closest_point_to_segment(mid, clear[0], clear[1]).distance_to(mid) < gap:
			continue
		var size := Vector3(p.distance_to(q) + 0.5, height, 0.5)
		_b.box(size, Vector3(mid.x, height * 0.5, mid.y), color, basis)
		_collide(Vector3(mid.x, height * 0.5, mid.y), size, basis)
		if walkers:
			_stamp(PackedVector2Array([p, q]), cell * 1.5, BUILT, _mask([LOT, PARK, BLOCK]))


func _t(x: float, z: float, yaw_deg := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(x, 0, z))


func _label(text: String, pos: Vector3, size: int, color: Color, yaw_deg := 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.02
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation.y = deg_to_rad(yaw_deg)
	l.shaded = true
	root.add_child(l)


func _lamp(pos: Vector3, energy := 3.0, reach := 34.0) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color("ffd9a0")
	light.light_energy = energy
	light.omni_range = reach
	root.add_child(light)


# --- The five places --------------------------------------------------------------------
# Placeholders with the right footprint and height, standing where the real ones do. Each keeps
# its `at` point and the driveway to its gate clear.

func _pois() -> void:
	_hospital(poi_pos("hospital"))
	_terminal(poi_pos("terminal"))
	_prefeitura(poi_pos("prefeitura"))
	_batalhao(poi_pos("batalhao"))
	_mirante(poi_pos("mirante"))
	for id: String in CityData.POIS:
		landmarks[id] = poi_pos(id)
		_lamp(poi_pos(id) + Vector3(0, 6, 0))


## Dona Helena: eight-floor ward block with a helipad on the roof (the extraction point), a
## lower wing, and the ambulance bay facing Rua Blumenau.
func _hospital(c: Vector3) -> void:
	var white := Color("b9bcbd")
	var h := 8 * Config.CITY_FLOOR_H
	_solid(c + Vector3(-26, h * 0.5, -4), Vector3(32, h, 96), white)
	_solid(c + Vector3(9, 6.4, -50), Vector3(34, 12.8, 22), white.darkened(0.12))
	for f in range(1, 8): # window bands
		_b.box(Vector3(0.12, 1.3, 92), c + Vector3(-9.95, f * Config.CITY_FLOOR_H + 1.7, -4), Props.GLASS)
	_b.box(Vector3(0.14, 5.0, 1.5), c + Vector3(-9.9, h - 4.5, 30), Props.RED) # red cross
	_b.box(Vector3(0.14, 1.5, 5.0), c + Vector3(-9.9, h - 4.5, 30), Props.RED)
	_b.box(Vector3(16, 0.3, 16), c + Vector3(-26, h + 0.15, -20), Color("3a3c40")) # helipad
	_b.box(Vector3(1.2, 0.34, 8), c + Vector3(-29, h + 0.17, -20), PAINT)
	_b.box(Vector3(1.2, 0.34, 8), c + Vector3(-23, h + 0.17, -20), PAINT)
	_b.box(Vector3(6, 0.34, 1.2), c + Vector3(-26, h + 0.17, -20), PAINT)
	_b.box(Vector3(14, 0.4, 14), c + Vector3(-2.5, 4.4, 0), Props.RED.darkened(0.3)) # ambulance bay canopy
	for x in [-8.5, 3.5]:
		for z in [-6.0, 6.0]:
			_b.box(Vector3(0.4, 4.2, 0.4), c + Vector3(x, 2.1, z), white)
			_collide(c + Vector3(x, 2.1, z), Vector3(0.4, 4.2, 0.4))
	_label(CityData.POIS.hospital.name, c + Vector3(-9.8, h - 9.0, -4), 160, Color("7a1212"), 90)


## Terminal Central: four platform roofs on columns, a ticket hall and the buses that never left.
func _terminal(c: Vector3) -> void:
	var steel := Props.STEEL
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var at := c + Vector3(sx * 27, 0, sz * 16)
			_b.box(Vector3(34, 0.4, 8), at + Vector3(0, 4.8, 0), Color("8a2a22"))
			for x in [-15.0, 0.0, 15.0]:
				_b.box(Vector3(0.5, 4.6, 0.5), at + Vector3(x, 2.3, 0), steel)
				_collide(at + Vector3(x, 2.3, 0), Vector3(0.5, 4.6, 0.5))
			_g.flat(Vector2(34, 5), at + Vector3(0, 0.03, 0), Color("5a5b5e")) # platform
	for bus: Array in [[27.0, -20.0, 90.0], [-27.0, 12.0, 90.0], [-24.0, -21.0, 78.0]]:
		_put(Props.bus(_b, _t(c.x + bus[0], c.z + bus[1], bus[2])), _t(c.x + bus[0], c.z + bus[1], bus[2]))
	_solid(c + Vector3(-34, 3.0, -31), Vector3(22, 6.0, 8), Color("8f8a80")) # ticket hall
	for x in [-16.0, 16.0]: # the sign over the way in from Rua Nove de Março
		_b.box(Vector3(0.6, 7.5, 0.6), c + Vector3(x, 3.75, 34), steel)
		_collide(c + Vector3(x, 3.75, 34), Vector3(0.6, 7.5, 0.6))
	_b.box(Vector3(33, 2.4, 0.4), c + Vector3(0, 6.6, 34), Color("1d2a52"))
	_label(CityData.POIS.terminal.name, c + Vector3(0, 6.6, 34.25), 150, Color("e8e4d8"))


## Prefeitura: a long seven-floor slab and an annex, with the flag poles out front.
func _prefeitura(c: Vector3) -> void:
	var stone := Color("a39d8e")
	var h := 7 * Config.CITY_FLOOR_H
	_solid(c + Vector3(4, h * 0.5, -28), Vector3(84, h, 24), stone)
	_solid(c + Vector3(30, 4.8, 26), Vector3(30, 9.6, 20), stone.darkened(0.15))
	for f in range(1, 7):
		_b.box(Vector3(80, 1.3, 0.12), c + Vector3(4, f * Config.CITY_FLOOR_H + 1.7, -15.95), Props.GLASS)
	_b.box(Vector3(18, 3.4, 0.3), c + Vector3(4, 1.7, -15.9), SHOPFRONT) # the doors
	_b.box(Vector3(22, 0.4, 6), c + Vector3(4, 3.8, -13), stone.darkened(0.3))
	for i in 3:
		_b.box(Vector3(0.15, 11.0, 0.15), c + Vector3(-20.0 + i * 3.0, 5.5, -9), Props.STEEL)
		_b.box(Vector3(1.8, 1.1, 0.05), c + Vector3(-19.0 + i * 3.0, 10.2, -9), [Color("2a7a3a"), Color("b8b8a8"), Color("a01e1e")][i])
	_label(CityData.POIS.prefeitura.name, c + Vector3(4, h - 2.2, -15.85), 170, Color("2a2a2a"))


## 62º Batalhão: a walled compound with barracks, headquarters, a parade ground and a motor pool.
func _batalhao(c: Vector3) -> void:
	var poi: Dictionary = CityData.POIS.batalhao
	var lot := _plan(poi.lot)
	var drive := _plan([poi.at, poi.gate])
	for i in lot.size():
		_wall(lot[i], lot[(i + 1) % lot.size()], 3.2, Props.CONCRETE_DARK, true, drive)
	for z in [-60.0, -30.0, 0.0]:
		_solid(c + Vector3(-125, 3.2, z), Vector3(60, 6.4, 14), Props.OLIVE)
		_b.box(Vector3(61, 0.5, 15), c + Vector3(-125, 6.6, z), Props.OLIVE_DARK)
	_solid(c + Vector3(-50, 4.8, 70), Vector3(56, 9.6, 16), Props.TAN)
	_b.box(Vector3(52, 1.2, 0.12), c + Vector3(-50, 6.4, 61.95), Props.GLASS)
	_label(poi.name, c + Vector3(-50, 8.4, 61.9), 150, Color("1c2414"), 180)
	_g.flat(Vector2(70, 90), c + Vector3(60, 0.03, 50), Color("3a4a2a")) # parade ground
	_b.box(Vector3(0.15, 12.0, 0.15), c + Vector3(24, 6.0, 50), Props.STEEL)
	_b.box(Vector3(2.0, 1.2, 0.05), c + Vector3(25.1, 11.2, 50), Color("2a7a3a"))
	for truck: Array in [[150.0, 70.0, 20.0], [160.0, 86.0, 20.0], [140.0, 98.0, 110.0]]:
		_put(Props.truck(_b, _t(c.x + truck[0], c.z + truck[1], truck[2])), _t(c.x + truck[0], c.z + truck[1], truck[2]))
	_put(Props.humvee(_b, _t(c.x + 128, c.z + 80, 200), Props.OLIVE), _t(c.x + 128, c.z + 80, 200))
	_solid(c + Vector3(56, 4.5, -64.5), Vector3(4, 9, 4), Props.CONCRETE) # guard tower by the gate
	_b.box(Vector3(5.5, 0.3, 5.5), c + Vector3(56, 9.15, -64.5), Props.OLIVE_DARK)


## Mirante: the lookout tower on top of Morro da Boa Vista, where the hill road ends.
func _mirante(c: Vector3) -> void:
	var concrete := Props.CONCRETE
	_solid(c + Vector3(14, 18, -12), Vector3(7, 36, 7), concrete)
	_b.box(Vector3(17, 1.0, 17), c + Vector3(14, 36.5, -12), concrete.darkened(0.2)) # the deck
	for side: Array in [[0.0, 8.4, 17.0, 0.2], [0.0, -8.4, 17.0, 0.2], [8.4, 0.0, 0.2, 17.0], [-8.4, 0.0, 0.2, 17.0]]:
		_b.box(Vector3(side[2], 1.1, side[3]), c + Vector3(14 + side[0], 37.55, -12 + side[1]), Props.STEEL)
	_b.box(Vector3(9, 0.5, 9), c + Vector3(14, 40.5, -12), concrete.darkened(0.2))
	_b.box(Vector3(0.2, 8, 0.2), c + Vector3(14, 44.7, -12), Props.STEEL)
	_glow.box(Vector3(0.5, 0.5, 0.5), c + Vector3(14, 48.9, -12), Color.WHITE)
	_solid(c + Vector3(-4, 1.75, 18), Vector3(10, 3.5, 6), Color("8f8a80")) # kiosk
	_label(CityData.POIS.mirante.name, c + Vector3(10.4, 6.0, -12), 110, Color("2a2a2a"), -90)


# --- Set pieces -------------------------------------------------------------------------------
# From the Scenery kit: what's left of the army's last stand, in the squares and on the avenue by
# the bus terminal, the way every mission starts out. Guns may lie in them (all_weapons aside).

func _scenery() -> void:
	var kit := Scenery.new(root, _body, _rng)
	kit.blocker = _block_cells
	kit.place(CityData.to_world(Vector2(950, 570)), 20).crash_site()
	kit.place(CityData.to_world(Vector2(978, 566)), 0).triage_camp()
	kit.place(CityData.to_world(Vector2(1110, 510)), 90).motor_pool()
	kit.place(CityData.to_world(Vector2(700, 385)), 90).checkpoint()
	kit.place(CityData.to_world(Vector2(960, 525)), -3).street_wrecks()
	kit.finish()
	spots = kit.spots
	interactables.append_array(kit.spots)
	prop_counts = kit.prop_counts


## Close every cell whose centre a solid box (world centre, size, basis) covers.
func _block_cells(center: Vector3, size: Vector3, basis: Basis) -> void:
	var half := Vector2(absf(basis.x.x) * size.x + absf(basis.z.x) * size.z,
		absf(basis.x.z) * size.x + absf(basis.z.z) * size.z) * 0.5
	var inv := basis.inverse()
	for r in range(maxi(0, floori((center.z - half.y - lo.y) / cell)), mini(gh - 1, floori((center.z + half.y - lo.y) / cell)) + 1):
		for c in range(maxi(0, floori((center.x - half.x - lo.x) / cell)), mini(gw - 1, floori((center.x + half.x - lo.x) / cell)) + 1):
			var local := inv * (Vector3(lo.x + (c + 0.5) * cell, center.y, lo.y + (r + 0.5) * cell) - center)
			if absf(local.x) <= size.x * 0.5 + 0.3 and absf(local.z) <= size.z * 0.5 + 0.3 and grid[r * gw + c] != OUT:
				grid[r * gw + c] = BUILT


# --- Navigation and the ground ------------------------------------------------------------

func _navigation() -> void:
	nav = NavGrid.new(lo, lo + (Vector2(gw, gh) - Vector2(0.5, 0.5)) * cell, cell)
	for i in grid.size():
		var t := grid[i]
		nav.solid[i] = 0 if (t == STREET or t == PARK or t == LOT or t == SQUARE) else 1
	nav.finish()


## Call `each.call(row, first column, columns, type)` for every run of same-type cells in a row.
func _runs(each: Callable) -> void:
	for r in gh:
		var start := 0
		for c in range(1, gw + 1):
			if c == gw or grid[r * gw + c] != grid[r * gw + start]:
				each.call(r, start, c - start, grid[r * gw + start])
				start = c


func _ground() -> void:
	var size := Vector3(gw * cell, 1.0, gh * cell)
	var center := Vector3(lo.x + size.x * 0.5, -0.5, lo.y + size.z * 0.5)
	_g.box(size, center, GROUND)
	_collide(center, size)
	_runs(func(r: int, c: int, n: int, t: int) -> void:
		# Split the run where it goes up the hill: raised cells are drawn by _hill_ground.
		var start := c
		for k in range(c + 1, c + n + 1):
			if k < c + n and _raised[r * gw + k] == _raised[r * gw + start]:
				continue
			_ground_run(r, start, k - start, t, _raised[r * gw + start] == 1)
			start = k)
	# A parapet wherever the river meets ground you can stand on
	for r in gh:
		for c in gw:
			if grid[r * gw + c] != WATER:
				continue
			var at := Vector3(lo.x + (c + 0.5) * cell, 0.5, lo.y + (r + 0.5) * cell)
			for side: Array in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
				if _open(c + side[0], r + side[1]):
					_b.box(Vector3(cell if side[0] == 0 else 0.3, 1.0, 0.3 if side[0] == 0 else cell),
						at + Vector3(side[0], 0, side[1]) * (cell * 0.5), Props.CONCRETE_DARK)


func _ground_run(r: int, c: int, n: int, t: int, raised: bool) -> void:
	var closed := t == WATER or t == FOREST # nobody swims and the forest is too thick: closed to players too
	if not raised:
		var mid := Vector3(lo.x + (c + n * 0.5) * cell, 0.02, lo.y + (r + 0.5) * cell)
		if GROUND_COLORS.has(t):
			_g.flat(Vector2(n * cell, cell), mid, GROUND_COLORS[t])
		if closed:
			_collide(mid + Vector3(0, 1.5, 0), Vector3(n * cell, 3.0, cell))
		return
	if not closed:
		return
	# On the slope, short boxes that hug the ground: a long one would stand up out of the hill
	# and stop shots fired down from the top.
	for k in range(c, c + n, 4):
		var m := mini(4, c + n - k)
		var span := _span(r, k, m)
		_collide(Vector3(lo.x + (k + m * 0.5) * cell, (span.x + span.y) * 0.5 + 1.5, lo.y + (r + 0.5) * cell),
			Vector3(m * cell, span.y - span.x + 3.0, cell))


func _in_detail(p: Vector2) -> bool:
	return detail_area.is_empty() or Geometry2D.is_point_in_polygon(p, detail_area)


func _on_ground(p: Vector2, lift: float) -> Vector3:
	var y := ground_y(Vector3(p.x, 0.0, p.y))
	return Vector3(p.x, y + lift + (0.1 if y > 0.01 else 0.0), p.y)


## The streets as meshes: every StreetNet piece inside the detail area, laid on the ground (on the
## hill the strips follow it: they have a cross-section every StreetNet.STEP metres). Each street's
## surface is a shade off its neighbours'.
func _street_surfaces() -> void:
	for piece: Dictionary in streets.pieces_in(detail_area):
		var tris: PackedVector2Array = piece.tris
		var color: Color = SURFACE_COLORS[piece.surface]
		var id: int = piece.street if piece.street >= 0 else 1000 + int(piece.node)
		color = color.lightened(0.08 * fposmod(id * 0.6180339, 1.0))
		var lift: float = LAYER_Y[piece.layer]
		for t in range(0, tris.size(), 3):
			_g.ground_tri(_on_ground(tris[t], lift), _on_ground(tris[t + 1], lift), _on_ground(tris[t + 2], lift), color)
		street_triangles += tris.size() / 3


## Dashed centre lines on the two-way asphalt roads, lamp posts along the main streets. (The real
## markings and lamps are S041 and S046.)
func _street_dressing() -> void:
	for link: Dictionary in streets.links:
		var sp: Dictionary = streets.specs[link.street]
		var kind: String = streets.streets[link.street].kind
		var line: PackedVector2Array = link.pts
		var dashes: bool = sp.surface == "asphalt" and int(sp.oneway) == 0 and float(sp.road) >= 7.0
		var sides: Array = []
		if kind == "principale": # on the kerb, both sides in turn
			var off := float(sp.road) * 0.5 + 0.5
			sides = [off, -off]
		var total := 0.0
		for s in line.size() - 1:
			total += line[s].distance_to(line[s + 1])
		var walked := 0.0
		var next_dash := 10.0
		var next_lamp := 12.0
		var side := 0
		for s in line.size() - 1:
			var a := line[s]
			var b := line[s + 1]
			var length := a.distance_to(b)
			var dir := (b - a) / maxf(length, 0.001)
			var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x))
			while dashes and next_dash < walked + length and next_dash < total - 10.0:
				var p := a + dir * (next_dash - walked)
				next_dash += 12.0
				if _in_detail(p) and type_at(Vector3(p.x, 0, p.y)) == STREET:
					_g.box(Vector3(3.5, 0.02, 0.18), _on_ground(p, 0.06), PAINT, basis)
			while not sides.is_empty() and next_lamp < walked + length:
				var p := a + dir * (next_lamp - walked) + dir.orthogonal() * float(sides[side % sides.size()])
				next_lamp += 30.0
				side += 1
				if not _in_detail(p) or type_at(Vector3(p.x, 0, p.y)) != STREET:
					continue
				var at := _on_ground(p, 0.0)
				_b.box(Vector3(0.2, 6.0, 0.2), at + Vector3(0, 3.0, 0), Props.STEEL)
				_collide(at + Vector3(0, 3.0, 0), Vector3(0.2, 6.0, 0.2))
				if _rng.randf() < 0.35: # most of the grid is down
					_glow.box(Vector3(0.5, 0.25, 0.5), at + Vector3(0, 6.0, 0), Color.WHITE)
			walked += length


## Trees on the hill: thick along the road so it reads as a wall of forest, thinner behind.
func _forest() -> void:
	for r in gh:
		for c in gw:
			if grid[r * gw + c] != FOREST:
				continue
			var roadside := _open(c - 1, r) or _open(c + 1, r) or _open(c, r - 1) or _open(c, r + 1)
			if _rng.randf() > (0.85 if roadside else 0.08):
				continue
			var w := _rng.randf_range(3.5, 6.5)
			var h := _rng.randf_range(7.0, 15.0)
			var at := Vector3(lo.x + (c + _rng.randf_range(0.3, 0.7)) * cell, 0.0, lo.y + (r + _rng.randf_range(0.3, 0.7)) * cell)
			at.y = ground_y(at) + h * 0.5 - 0.6
			_trees.box(Vector3(w, h, w), at, LEAVES[_rng.randi() % LEAVES.size()], Basis(Vector3.UP, _rng.randf() * TAU))


## The wall where the map ends.
func _edge_wall() -> void:
	for i in boundary.size():
		var a := boundary[i]
		var b := boundary[(i + 1) % boundary.size()]
		var pieces := 1
		for f in [0.0, 0.25, 0.5, 0.75, 1.0]:
			var q := a.lerp(b, f)
			if ground_y(Vector3(q.x, 0, q.y)) > 0.0:
				pieces = maxi(1, ceili(a.distance_to(b) / 8.0))
		if pieces == 1:
			_wall(a, b, Config.CITY_WALL_H, Props.CONCRETE_DARK)
			continue
		# Over the hill: short pieces, each standing on the ground where it is.
		var dir := (b - a).normalized()
		var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x))
		for k in pieces:
			var p := a.lerp(b, float(k) / pieces)
			var q := a.lerp(b, float(k + 1) / pieces)
			var y0 := ground_y(Vector3(p.x, 0, p.y))
			var y1 := ground_y(Vector3(q.x, 0, q.y))
			var h := Config.CITY_WALL_H + absf(y1 - y0)
			var mid := Vector3((p.x + q.x) * 0.5, minf(y0, y1) + h * 0.5 - 0.3, (p.y + q.y) * 0.5)
			var size := Vector3(p.distance_to(q) + 0.5, h, 0.5)
			_b.box(size, mid, Props.CONCRETE_DARK, basis)
			_collide(mid, size, basis)


# --- Pictures of the layout ----------------------------------------------------------------

## The layout from above, `scale` pixels per cell, over `rect` (x, z metres; empty: the whole grid).
## The grid underneath (buildings lighter the taller they are, POI structures near white, the street
## cells of the navigation grid a dull brown), and on it the street plan as it is built: pavements,
## setts, asphalt, covered passages in amber. Each POI is ringed in red.
func plan_image(scale := 2, rect := Rect2()) -> Image:
	if rect.size == Vector2.ZERO:
		rect = Rect2(lo, Vector2(gw, gh) * cell)
	var ppm := float(scale) / cell
	var w := ceili(rect.size.x * ppm)
	var h := ceili(rect.size.y * ppm)
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var c0 := maxi(0, floori((rect.position.x - lo.x) / cell))
	var c1 := mini(gw, ceili((rect.end.x - lo.x) / cell))
	var r0 := maxi(0, floori((rect.position.y - lo.y) / cell))
	var r1 := mini(gh, ceili((rect.end.y - lo.y) / cell))
	for r in range(r0, r1):
		for c in range(c0, c1):
			var t := grid[r * gw + c]
			var color: Color = PLAN_COLORS[t]
			if t == BLOCK:
				color = color.lightened(minf(_floors[r * gw + c], 16.0) / 16.0 * 0.55)
			elif t == STREET:
				color = Color("4a4038")
			var at := (Vector2(lo.x + c * cell, lo.y + r * cell) - rect.position) * ppm
			var p0 := Vector2i(floori(at.x), floori(at.y))
			img.fill_rect(Rect2i(p0, Vector2i(ceili(at.x + scale) - p0.x, ceili(at.y + scale) - p0.y)), color)
	for layer in [StreetNet.WALK, StreetNet.ROAD]:
		for piece: Dictionary in streets.pieces:
			if piece.layer != layer or not (piece.box as Rect2).intersects(rect):
				continue
			var color: Color = PLAN_SURFACE[piece.surface]
			if piece.street >= 0 and streets.specs[piece.street].covered:
				color = PLAN_COVERED
			var tris: PackedVector2Array = piece.tris
			for t in range(0, tris.size(), 3):
				_raster(img, (tris[t] - rect.position) * ppm, (tris[t + 1] - rect.position) * ppm, (tris[t + 2] - rect.position) * ppm, color)
	# The houses by their roofs (the figure-ground of the town), and at a close scale the îlots'
	# outlines they were cut from, in yellow.
	if blocks != null:
		for house: Dictionary in blocks.houses:
			var foot: PackedVector2Array = house.foot
			if not Rect2(foot[0], Vector2.ZERO).grow(40.0).intersects(rect):
				continue
			var colour: Color = (house.roof_colour as Color).lightened(0.25)
			for t in range(1, foot.size() - 1):
				_raster(img, (foot[0] - rect.position) * ppm, (foot[t] - rect.position) * ppm, (foot[t + 1] - rect.position) * ppm, colour)
			if scale >= 6:
				for i in foot.size():
					_line(img, (foot[i] - rect.position) * ppm, (foot[(i + 1) % foot.size()] - rect.position) * ppm, 0, Color("1a1a1a"))
		for wall: Dictionary in blocks.walls:
			if not rect.has_point(wall.a):
				continue
			_line(img, ((wall.a as Vector2) - rect.position) * ppm, ((wall.b as Vector2) - rect.position) * ppm, 0, Color("c03030") if wall.gate else Color("d8d0c0"))
		if scale >= 6:
			for il: Dictionary in blocks.ilots:
				var poly: PackedVector2Array = il.outline
				for i in poly.size():
					if not rect.has_point(poly[i]):
						continue
					_line(img, (poly[i] - rect.position) * ppm, (poly[(i + 1) % poly.size()] - rect.position) * ppm, 0, Color("ffe000"))
	for id: String in CityData.POIS:
		var p := poi_pos(id)
		var at := Vector2i(((Vector2(p.x, p.z) - rect.position) * ppm).round())
		var ring := 14 * scale
		for d in range(-ring, ring + 1):
			for k in [-ring, ring]:
				_dot(img, at + Vector2i(d, k), scale / 2, Color("ff3020"))
				_dot(img, at + Vector2i(k, d), scale / 2, Color("ff3020"))
	return img


## Fill a triangle (image pixels) with a colour: every pixel whose centre is inside.
static func _raster(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var x0 := maxi(0, floori(minf(a.x, minf(b.x, c.x))))
	var x1 := mini(img.get_width() - 1, ceili(maxf(a.x, maxf(b.x, c.x))))
	var y0 := maxi(0, floori(minf(a.y, minf(b.y, c.y))))
	var y1 := mini(img.get_height() - 1, ceili(maxf(a.y, maxf(b.y, c.y))))
	var area := (b - a).cross(c - a)
	if absf(area) < 1e-6:
		return
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var w0 := (b - a).cross(p - a) / area
			var w1 := (c - b).cross(p - b) / area
			var w2 := (a - c).cross(p - c) / area
			if w0 >= 0.0 and w1 >= 0.0 and w2 >= 0.0:
				img.set_pixel(x, y, color)


## The centre round the bus terminal and the place du Marché, in metres: for a close plan of the
## junctions.
func core_rect() -> Rect2:
	return Rect2(CityData.to_plan(Vector2(760, 280)), Vector2(420, 330) * CityData.M_PER_PX)


const KIND_LINE := { "principale": Color("ff3a10"), "rue": Color("1060ff"), "chemin": Color("8040ff") }


## The reference map with the streets of the plan over it by kind (main streets red, rues blue, the
## hill road violet), the squares in yellow and the POIs as red squares. Null if the reference
## picture is missing.
func reference_overlay() -> Image:
	var path := ProjectSettings.globalize_path(CityData.REF_IMAGE)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGB8)
	for i in streets.lines.size():
		var pts: PackedVector2Array = streets.lines[i].pts
		var kind: String = streets.streets[i].kind
		var radius := maxi(0, roundi(CityData.width(streets.streets[i]) / CityData.M_PER_PX * 0.3))
		for s in pts.size() - 1:
			_line(img, pts[s] / CityData.M_PER_PX + CityData.ORIGIN_PX, pts[s + 1] / CityData.M_PER_PX + CityData.ORIGIN_PX, radius, KIND_LINE[kind])
	for sq: Dictionary in CityData.SQUARES:
		var pts: Array = sq.pts
		for i in pts.size():
			_line(img, pts[i], pts[(i + 1) % pts.size()], 0, Color("ffe000"))
	for id: String in CityData.POIS:
		var poi: Dictionary = CityData.POIS[id]
		var lot: Array = poi.lot
		for i in lot.size():
			_line(img, lot[i], lot[(i + 1) % lot.size()], 1, Color("ff2010"))
		var at: Vector2 = poi.at
		_dot(img, Vector2i(at), 5, Color("ff2010"))
		_dot(img, Vector2i(at), 2, Color.WHITE)
	return img


func _dot(img: Image, at: Vector2i, radius: int, color: Color) -> void:
	for y in range(at.y - radius, at.y + radius + 1):
		for x in range(at.x - radius, at.x + radius + 1):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
				img.set_pixel(x, y, color)


func _line(img: Image, a: Vector2, b: Vector2, radius: int, color: Color) -> void:
	var steps := maxi(1, ceili(a.distance_to(b)))
	for i in steps + 1:
		_dot(img, Vector2i(a.lerp(b, float(i) / steps)), radius, color)
