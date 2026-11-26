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
const FACADES := [Color("7b7469"), Color("6d7078"), Color("8a8377"), Color("5f5a55"), Color("77706a"),
	Color("6a6e66"), Color("807a80"), Color("8d8a82")]
const ASPHALT := Color("242528")
const SHOPFRONT := Color("2a2b2f")
const PAINT := Color("b8b8a8")
const HILL_ROAD := "telegraphe" # the chemin du Télégraphe (CityData.HAND_STREETS)
const KERB := Color("8a8983")        ## the flush concrete edging of the road up the hill
const VERGE := Color("2e2b21")       ## packed earth and fallen leaves between the kerb and the trees
const HILL_LANE := 2.2               ## the red brick walking lane on the right going up the hill
const HILL_LINE := 0.14              ## the white line beside it, HILL_LINE_GAP in from the lane
const HILL_LINE_GAP := 0.03
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
var terminal := {}                   ## the terminal lot frame (-Z to the street), gate, platform (the middle island)
var hospital := {}                   ## the Hospital's lot frame (-Z to Rua Blumenau), door, yard, stair frame, climb (world points), pad
var prefeitura := {}                 ## the Prefeitura's lot frame (-Z to the avenue), its door and its pad (world)
var mirante := {}                    ## where the Mirante's pieces stand (world): gate, gate_yaw, tower, deck, poles, rails
var roadside_trees: Array = []       ## [{ at, kind }]: the real trees (Vegetation) lining the forest's roads
var hill_line := PackedVector2Array() ## the road up Morro da Boa Vista as drawn: straightened, smoothed, a point every CITY_ROAD_STEP m (x, z)
var hill_corners := PackedVector2Array() ## the traced points of that road left after straightening (where it really bends)
var hill_width := 0.0
var hill_length := 0.0

var heights := PackedFloat32Array()  ## ground height at every cell corner, (gw + 1) x (gh + 1)
var _raised := PackedByteArray()     # 1 where any corner of the cell is above 0
var _floors := PackedByteArray()     # storeys of the building on each BLOCK cell (for the plan)
var _b := MeshKit.Builder.new()      # buildings, walls, POIs
var _g := MeshKit.Builder.new()      # ground and paint
var _trees := MeshKit.Builder.new()
var _glow := MeshKit.Builder.new()   # lit windows and lamps
var _shells := MeshKit.Builder.new() # the open houses' outer walls (HouseStreamer cuts each away while its floors stand)
var houses: HouseStreamer = null     ## builds the open houses' floors near the camera (S246)
var _red := MeshKit.Builder.new()    # aircraft warning lights on the radio masts
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
	_hill_road()
	RoadScatter.hill_road(self)
	RoadScatter.streets(self)
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
	root.add_child(_red.instance(MeshKit.emissive(Color("ff2a1a"), 3.0), false))


# --- GameMap ------------------------------------------------------------------------

## A mission with data of its own (the Mirante) starts at its first spawn; another at its POI;
## free play at the bus terminal.
func player_spawn() -> Vector3:
	if not spawns.is_empty():
		return spawns[0].at
	return poi_pos(mission if CityData.POIS.has(mission) else "terminal") + Vector3(0, 0.1, 0)


func player_spawn_point(slot := 0) -> Vector3:
	if not spawns.is_empty():
		return spawns[posmod(slot, spawns.size())].at
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


## The Mirante, the Hospital and the Prefeitura have their own objectives, built from where their pieces ended up.
func _mission_changed() -> void:
	if mission == "mirante" and mirante.has("gate") and nav != null:
		use_data(MapAreas.mirante(self))
	elif mission == "terminal" and terminal.has("platform") and prefeitura.has("pad") and nav != null:
		use_data(MapAreas.terminal(self))
	elif mission == "hospital" and hospital.has("pad") and nav != null:
		use_data(MapAreas.hospital(self))
	elif mission == "prefeitura" and prefeitura.has("pad") and nav != null:
		use_data(MapAreas.prefeitura(self))
	else:
		use_data({})


func is_walkable(p: Vector3) -> bool:
	return contains(p) and not nav.is_blocked(p)


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
	_smooth_hill_road()
	if hill_line.size() >= 2:
		# Through the forest the open cells reach well past the paving, so no forest cell (a
		# solid block) pokes into the road or its verge.
		_stamp(hill_line, hill_width, STREET, inside)
		_stamp(hill_line, hill_width + cell * 1.5, STREET, _mask([FOREST]))
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
	_level_hill_road()
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
	# The road's own paving is one smooth band (_hill_paving): the open cells round it are
	# forest floor, or the clearing's ground on the summit.
	var summit := _plan(CityData.POIS["mirante"].lot)
	for r in range(r0, r1 + 1):
		for c in range(c0, c1 + 1):
			var i := r * gw + c
			if _raised[i] == 0 or done[i] == 1:
				continue
			var t := grid[i]
			var color: Color = GROUND_COLORS.get(t, GROUND_COLORS[LOT])
			if t == STREET:
				var mid := Vector2(lo.x + (c + 0.5) * cell, lo.y + (r + 0.5) * cell)
				color = GROUND_COLORS[LOT] if Geometry2D.is_point_in_polygon(mid, summit) else GROUND_COLORS[FOREST]
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

func _is(c: int, r: int, t: int) -> bool:
	return c >= 0 and r >= 0 and c < gw and r < gh and grid[r * gw + c] == t


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


func _label(text: String, pos: Vector3, size: int, color: Color, yaw_deg := 0.0, shaded := true) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.02
	l.modulate = color
	l.outline_size = 0
	l.position = pos
	l.rotation.y = deg_to_rad(yaw_deg)
	l.shaded = shaded
	root.add_child(l)


func _lamp(pos: Vector3, energy := 3.0, reach := 34.0, color := Color("ffd9a0")) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
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


## Hospital Dona Helena, facing east over its ambulance bay to Rua Blumenau (HospitalSet): the
## white ward tower in three bodies washed in blue light with the lit sign on the middle one, the
## bay canopy along the front, the old wing with its dark fins and the green-banded annex on the
## street, the little old house kept between, the yard behind with the oxygen tank, and the steel
## fire stair up the back to the helipad on the roof. Triage was set up under the bay and lost.
## `hospital` keeps the lot's frame (-Z faces the street) and where the mission's places are.
func _hospital(c: Vector3) -> void:
	var lot := Transform3D(Basis(Vector3.UP, -PI * 0.5), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 18600512
	hospital.frame = lot
	_put(HospitalSet.tower(_b, _glow, lot), lot)
	_put(HospitalSet.roof_colliders(), lot)
	_put_free(HospitalSet.bay_columns(), lot)
	var stair := lot * Transform3D(Basis.IDENTITY, Vector3(HospitalSet.STAIR_X, 0, HospitalSet.TOWER_BACK))
	_put_free(HospitalSet.fire_stair(_b, stair), stair)
	hospital.stair = stair
	hospital.climb = HospitalSet.stair_points().map(func(p: Vector3) -> Vector3: return stair * p)
	hospital.pad = lot * HospitalSet.PAD_AT
	hospital.door = lot * Vector3((HospitalSet.B.x + HospitalSet.B.y) * 0.5, 0, HospitalSet.TOWER_FRONT - HospitalSet.B_OUT - 1.0)
	hospital.yard = lot * Vector3(-31, 0, 34)
	var face := rad_to_deg(-PI * 0.5) + 180.0
	_label(CityData.POIS.hospital.name, lot * HospitalSet.SIGN_AT, 90, HospitalSet.SIGN_BLUE, face, false)
	_label("PRONTO ATENDIMENTO", lot * HospitalSet.BAY_SIGN_AT, 40, Color.WHITE, face, false)
	_lamp(lot * HospitalSet.WASH_AT, 2.5, 30.0, HospitalSet.WASH)
	_lamp(lot * Vector3(-31, 3.6, -3), 1.6, 12.0, Config.LOOK_LAMP_WARM)
	# The buildings on the street.
	var wing := lot * Transform3D(Basis.IDENTITY, Vector3(19, 0, -32))
	_put(HospitalSet.old_wing(_b, _glow, wing, 30.0, 14.0), wing)
	var annex := lot * Transform3D(Basis.IDENTITY, Vector3(49, 0, -30))
	_put(HospitalSet.annex(_b, _glow, annex, 26.0, 16.0), annex)
	var house := lot * Transform3D(Basis.IDENTITY, Vector3(-65, 0, -28))
	_put(HospitalSet.house(_b, house, 14.0, 10.0), house)
	# The ground: the drop-off lane, paving under the bay and along the street, the yard behind.
	var y := 0.035
	_patch(lot, [-58.0, -38.0, 2.0, -10.0], y, PrefeituraSet.ASPHALT)
	for k in 8: # the drop-off's bays
		_patch(lot, [-54.0 + k * 6.0, -14.0, -53.88 + k * 6.0, -10.5], y + 0.01, PrefeituraSet.LINE)
	_patch(lot, [-58.0, -10.0, -4.0, 4.0], y, PrefeituraSet.PAVING)
	_patch(lot, [2.0, -38.0, 66.0, -32.0], y, PrefeituraSet.PAVING)
	_patch(lot, [-74.0, -38.0, -58.0, -28.0], y, PrefeituraSet.PAVING)
	_patch(lot, [-60.0, 24.0, 2.0, 44.0], y, PrefeituraSet.ASPHALT)
	for k in 10:
		_patch(lot, [-46.0 + k * 3.0, 39.0, -45.88 + k * 3.0, 44.0], y + 0.01, PrefeituraSet.LINE)
	for x in [-72.0, -62.0, 8.0, 22.0, 36.0, 50.0, 62.0]:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(x, 0, -36.5))
		_put_free(Vegetation.plant(_trees, t, Vegetation.Kind.BROADLEAF if int(x) % 3 != 0 else Vegetation.Kind.IPE_YELLOW, rng), t)
	# The yard: the oxygen tank, the generator, bins by the back doors, staff cars.
	var tank := lot * Transform3D(Basis.IDENTITY, Vector3(-53, 0, 36))
	_put(HospitalSet.oxygen_tank(_b, tank), tank)
	var gen := lot * Transform3D(Basis(Vector3.UP, 0.1), Vector3(-4, 0, 34))
	_put_free(HospitalSet.generator(_b, gen), gen)
	for x in [-13.0, -11.6, -36.0]:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf() * 0.6), Vector3(x, 0, 26.0))
		_put_free(RoadProps.bin(_b, t, true, rng), t)
	for k in 3:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.1, 0.1)), Vector3(-41.0 + k * 6.0, 0, 41.6))
		var paint: Color = RoadProps.PAINTS[rng.randi() % RoadProps.PAINTS.size()]
		_put_free(RoadProps.hatchback(_b, t, paint, rng.randi_range(0, 1)), t)
	# Triage under the bay, overrun: ambulances left with their doors open, a minibus dragged across
	# the lane as a barricade, cots, body bags, wheelchairs, drip stands, blood to the doors.
	for a: Array in [[-46.0, -18.0, 0.15], [-14.0, -22.0, -2.6]]:
		var t := lot * Transform3D(Basis(Vector3.UP, a[2]), Vector3(a[0], 0, a[1]))
		_put_free(Props.ambulance(_b, t), t)
	var bus := lot * Transform3D(Basis(Vector3.UP, PI * 0.5 + 0.3), Vector3(-30, 0, -30))
	_put_free(RoadProps.minibus(_b, bus), bus)
	for k in 5:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.2, 0.2)), Vector3(-48.0 + k * 1.4, 0, -4.5))
		_put_free(Props.cot(_b, t, k % 2 == 0), t)
		if k % 2 == 1:
			HospitalSet.drip_stand(_b, lot * Transform3D(Basis.IDENTITY, Vector3(-48.0 + k * 1.4 + 0.6, 0, -5.8)))
	for k in 4:
		var t := lot * Transform3D(Basis(Vector3.UP, PI * 0.5 + rng.randf_range(-0.15, 0.15)), Vector3(-20.0 + k * 0.1, 0, -6.0 + k * 0.8))
		_put_free(Props.bodybag(_b, t), t)
	for w: Array in [[-27.0, -3.0, 0.4, false], [-24.5, -2.2, 2.2, true], [-10.0, -14.0, 1.0, true]]:
		HospitalSet.wheelchair(_b, lot * Transform3D(Basis(Vector3.UP, w[2]), Vector3(w[0], 0, w[1])), w[3])
	RoadProps.litter(_b, lot * Transform3D(Basis.IDENTITY, Vector3(-34.0, 0.0, -2.0)), 6, rng, _glow)
	RoadProps.litter(_b, lot * Transform3D(Basis.IDENTITY, Vector3(-40.0, 0.0, 30.0)), 4, rng, _glow)
	var ground_at := func(_p: Vector3) -> float: return c.y
	RoadProps.blood_trail(_b, lot * Transform3D(Basis(Vector3.UP, PI), Vector3(-36.0, 0, -12.0)), 12.0, rng, ground_at)


## Terminal Central, opening south onto Rua Nove de Março (TerminalSet): three platform islands
## under the heavy concrete roof slabs with the skylight lantern down the spine, the steel tree
## columns, the ticket hall and the shops along the street with the sign over the way in, and the
## yellow buses that never left: two nose to tail, one rammed into a column, one burnt out.
## `terminal` keeps the lot's frame (-Z to the street) and where the mission's places are.
func _terminal(c: Vector3) -> void:
	var lot := Transform3D(Basis(Vector3.UP, PI), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 18570309
	terminal.frame = lot
	terminal.gate = lot * Vector3(0, 0, TerminalSet.FRONT_Z - 2.0)
	terminal.platform = lot * Vector3(0, TerminalSet.ISLAND_H, TerminalSet.ISLANDS[1])
	var y := 0.03
	_patch(lot, [-49.0, TerminalSet.FRONT_Z + TerminalSet.FRONT_D, 49.0, 36.0], y, TerminalSet.LANE)
	_patch(lot, [-TerminalSet.GATE_HALF, -36.0, TerminalSet.GATE_HALF, TerminalSet.FRONT_Z + TerminalSet.FRONT_D], y, TerminalSet.LANE)
	for k in 2: # the cobbled bus lanes between the islands, drains along the kerbs, bay lines
		var z0: float = TerminalSet.ISLANDS[k] + TerminalSet.ISLAND_W * 0.5
		var z1: float = TerminalSet.ISLANDS[k + 1] - TerminalSet.ISLAND_W * 0.5
		_patch(lot, [-44.0, z0, 44.0, z1], y + 0.005, TerminalSet.SETTS)
		for z in [z0 + 0.3, z1 - 0.3]:
			_patch(lot, [-44.0, z - 0.12, 44.0, z + 0.12], y + 0.01, Color("1e2022"))
		for b in 6:
			var x := -36.0 + b * 14.4
			_patch(lot, [x - 0.08, z0 + 0.4, x + 0.08, z0 + 3.0], y + 0.012, TerminalSet.KERB_YELLOW)
	for z: float in TerminalSet.ISLANDS:
		var it := lot * Transform3D(Basis.IDENTITY, Vector3(0, 0, z))
		_put_free(TerminalSet.island(_b, _glow, it, TerminalSet.LENGTH, int(z)), it)
		for x: float in TerminalSet.COLUMNS_X:
			var ct := lot * Transform3D(Basis.IDENTITY, Vector3(x, TerminalSet.ISLAND_H, z))
			_put_free(TerminalSet.tree_column(_b, ct), ct)
	TerminalSet.roof(_b, _glow, lot)
	_put(TerminalSet.front(_b, _glow, lot), lot)
	_label(CityData.POIS.terminal.name, lot * TerminalSet.SIGN_AT, 120, TerminalSet.SIGN_TEXT, rad_to_deg(PI) + 180.0, false)
	_lamp(lot * Vector3(0, TerminalSet.SOFFIT_Y - 0.6, TerminalSet.SPINE_Z), 1.4, 26.0, Color("dfe6ff"))
	# The buses: where they stopped, where one crashed, where one burnt.
	for bus: Array in [[-26.0, -11.5, PI * 0.5, true, true], [-12.0, -11.8, PI * 0.5, true, false],
			[17.5, -2.6, PI * 0.5 + 0.32, true, true], [-20.0, 9.0, -PI * 0.5, false, true],
			[26.0, 17.6, -PI * 0.5, true, true], [-31.0, 30.0, -PI * 0.5, false, false]]:
		var t := lot * Transform3D(Basis(Vector3.UP, bus[2]), Vector3(bus[0], 0, bus[1]))
		_put(TerminalSet.bus(_b, _glow, t, bus[3], bus[4]), t)
	var burnt := lot * Transform3D(Basis(Vector3.UP, PI * 0.5 + 0.06), Vector3(31.0, 0, 30.5))
	_put(TerminalSet.bus(_b, _glow, burnt, false, true, true), burnt)
	TerminalSet.scorch(_b, _glow, burnt, rng)
	_lamp(burnt * Vector3(0, 1.2, 0), 1.2, 9.0, Color("ff8a3a"))
	# What people left: luggage on the islands and in the lanes, litter, blood to the hall's doors.
	for p: Vector3 in [Vector3(-8, TerminalSet.ISLAND_H, -17), Vector3(6, 0, -6), Vector3(-30, TerminalSet.ISLAND_H, 3), Vector3(14, 0, 12)]:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf() * TAU), p)
		_put_free(Props.luggage(_b, t, 3 + rng.randi() % 3, rng), t)
	for p: Vector3 in [Vector3(0, 0, -24), Vector3(-18, 0, -5), Vector3(20, 0, 26)]:
		RoadProps.litter(_b, lot * Transform3D(Basis.IDENTITY, p), 5, rng, _glow)
	var ground_at := func(_p: Vector3) -> float: return c.y
	RoadProps.blood_trail(_b, lot * Transform3D(Basis(Vector3.UP, PI), Vector3(-20.0, 0, -20.0)), 9.0, rng, ground_at)
	RoadProps.blood_trail(_b, lot * Transform3D(Basis(Vector3.UP, 1.2), Vector3(8.0, 0, 12.0)), 7.0, rng, ground_at)


## Prefeitura: the long four-storey block facing west over its lawn to Avenida Hermann August
## Lepper and the river (PrefeituraSet): brick piers, concrete bands, blue space frames, the stair
## tower, the towers on the roof. In front: the forecourt, the walk down the middle, the zig-zag
## ramp, the sign on the lawn, flower beds, imperial palms along the avenue, the car park to the
## north and the round pad on the south lawn. A last stand was made at the door.
## `prefeitura` keeps the lot's frame (-Z faces the avenue) and where the mission's places are.
const PREFEITURA_BUILDING_Z := 18.0  # the block's centre, metres back from the POI point
func _prefeitura(c: Vector3) -> void:
	var lot := Transform3D(Basis(Vector3.UP, PI * 0.5), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 18510320
	var bt := lot * Transform3D(Basis.IDENTITY, Vector3(0, 0, PREFEITURA_BUILDING_Z))
	_put(PrefeituraSet.building(_b, _glow, bt), bt)
	_put_free(PrefeituraSet.canopy_columns(), bt)
	_lamp(bt * PrefeituraSet.ENTRANCE_LAMP, 1.8, 12.0, Config.LOOK_LAMP_WARM)
	prefeitura.frame = lot
	prefeitura.door = bt * Vector3(0, 0, -PrefeituraSet.DEPTH * 0.5 - PrefeituraSet.CENTRE_OUT)
	# The ground: paving along the front and down the middle, grass either side, the car park.
	var y := 0.035
	for r: Array in [[-40.0, -2.0, 40.0, 9.0], [-14.0, -12.0, 14.0, -2.0], [-3.0, -58.0, 3.0, -12.0]]:
		_patch(lot, r, y, PrefeituraSet.PAVING)
	for r: Array in [[-45.0, -58.0, -14.0, -2.0], [14.0, -58.0, 45.0, -2.0], [-14.0, -58.0, -3.0, -12.0], [3.0, -58.0, 14.0, -12.0]]:
		_patch(lot, r, y, PrefeituraSet.GRASS)
	_patch(lot, [22.0, -52.0, 44.0, -24.0], y + 0.01, PrefeituraSet.ASPHALT)
	for k in 9: # bay lines, cars nose in from the aisle
		_patch(lot, [22.0, -50.0 + k * 3.0, 27.5, -49.9 + k * 3.0], y + 0.02, PrefeituraSet.LINE)
		_patch(lot, [38.5, -50.0 + k * 3.0, 44.0, -49.9 + k * 3.0], y + 0.02, PrefeituraSet.LINE)
	for k in 6:
		var row_x := 24.8 if k % 2 == 0 else 41.2
		var t := lot * Transform3D(Basis(Vector3.UP, PI * 0.5 + rng.randf_range(-0.12, 0.12) + (PI if k % 2 == 1 else 0.0)), Vector3(row_x, 0, -47.0 + k * 4.4))
		var paint: Color = RoadProps.PAINTS[rng.randi() % RoadProps.PAINTS.size()]
		_put(RoadProps.hatchback(_b, t, paint, rng.randi_range(0, 2)), t)
	# The pad on the south lawn, the sign, the ramp, beds, lamps, flags, palms.
	var pad := lot * Transform3D(Basis.IDENTITY, Vector3(-31, 0, -38))
	PrefeituraSet.pad(_b, pad, _glow)
	prefeitura.pad = pad.origin
	var sign_t := lot * Transform3D(Basis(Vector3.UP, 0.12), Vector3(-13, 0, -24))
	_put_free(PrefeituraSet.lawn_sign(_b, sign_t), sign_t)
	_label("Prefeitura Municipal de Joinville", sign_t * PrefeituraSet.SIGN_AT, 30, PrefeituraSet.SIGN_TEXT,
		rad_to_deg(sign_t.basis.get_euler().y) + 180.0, false) # lit letters: readable at night
	_put_free(PrefeituraSet.ramp(_b, _g, lot, Vector3(7, 0, -52), Vector3(11, 0, -13), 3, 5.0, 2.2), lot)
	for e: Array in [[-6.5, -13.5, 4.0, 1.6], [6.5, -13.5, 4.0, 1.6], [-22.0, -3.2, 7.0, 1.2], [22.0, -3.2, 7.0, 1.2]]:
		PrefeituraSet.flower_bed(_b, lot * Transform3D(Basis.IDENTITY, Vector3(e[0], 0, e[1])), e[2], e[3], int(e[0]) + 50)
	for z in [-50.0, -38.0, -26.0]:
		for x in [-4.2, 4.2]:
			var t := lot * Transform3D(Basis.IDENTITY, Vector3(x, 0, z))
			_put_free(PrefeituraSet.lamp_post(_b, t, _glow, z == -26.0 and x > 0.0), t)
	for k in 3:
		PrefeituraSet.flag(_b, lot * Transform3D(Basis.IDENTITY, Vector3(-11.0 - k * 1.7, 0, 4.4)), k)
	for x in [-40.0, -28.0, -16.0, 16.0, 30.0, 42.0]:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(x, 0, -55.5))
		_put_free(Vegetation.plant(_trees, t, Vegetation.Kind.IMPERIAL_PALM, rng), t)
	# The yard behind: the staff car park, bins by the back door, the forest's first trees.
	_patch(lot, [-40.0, 31.0, 40.0, 54.0], y, PrefeituraSet.ASPHALT)
	for k in 14:
		_patch(lot, [-21.0 + k * 3.0, 31.0, -20.9 + k * 3.0, 36.5], y + 0.01, PrefeituraSet.LINE)
	for k in 5:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.1, 0.1)), Vector3(-19.5 + k * 9.0, 0, 33.8))
		var paint: Color = RoadProps.PAINTS[rng.randi() % RoadProps.PAINTS.size()]
		_put_free(RoadProps.hatchback(_b, t, paint, rng.randi_range(0, 1)), t)
	for x in [-6.0, -4.6, 6.4]:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf() * 0.6), Vector3(x, 0, 28.6))
		_put_free(RoadProps.bin(_b, t, true, rng), t)
	for k in 9:
		var t := lot * Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(-40.0 + k * 10.0 + rng.randf_range(-2.0, 2.0), 0, 56.5))
		_put_free(Vegetation.plant(_trees, t, Vegetation.Kind.BROADLEAF if k % 3 != 1 else Vegetation.Kind.JUCARA, rng), t)
	# The last stand at the door: sandbags either side of the walk, a patrol car and an ambulance
	# left across the forecourt, a bench dragged over, things dropped, a body dragged inside.
	for x in [-4.4, 4.4]:
		var t := lot * Transform3D(Basis(Vector3.UP, 0.08 if x < 0.0 else -0.08), Vector3(x, 0, -5.5))
		_put_free(Props.sandbags(_b, t, 5.0, 3), t)
	var car := lot * Transform3D(Basis(Vector3.UP, 0.55), Vector3(-10.5, 0, -4.0))
	_put_free(RoadProps.patrol_car(_b, car, _glow), car)
	var amb := lot * Transform3D(Basis(Vector3.UP, -1.9), Vector3(11.5, 0, -7.0))
	_put_free(Props.ambulance(_b, amb), amb)
	var bench := lot * Transform3D(Basis(Vector3.UP, 1.2), Vector3(-6.5, 0, -9.0))
	_put_free(RoadProps.bench(_b, bench, true), bench)
	RoadProps.litter(_b, lot * Transform3D(Basis.IDENTITY, Vector3(2.5, 0.0, -8.5)), 5, rng, _glow)
	RoadProps.litter(_b, lot * Transform3D(Basis.IDENTITY, Vector3(-2.0, 0.0, 1.5)), 4, rng, _glow)
	var ground_at := func(_p: Vector3) -> float: return c.y
	RoadProps.blood_trail(_b, lot * Transform3D(Basis(Vector3.UP, PI), Vector3(0.8, 0, -6.0)), 11.0, rng, ground_at)


## A flat patch of ground in the frame `t`: `r` is [x0, z0, x1, z1] in that frame, `y` above it.
func _patch(t: Transform3D, r: Array, y: float, color: Color) -> void:
	var x0: float = r[0]
	var z0: float = r[1]
	var x1: float = r[2]
	var z1: float = r[3]
	_g.ground_quad(t * Vector3(x0, y, z0), t * Vector3(x1, y, z0), t * Vector3(x1, y, z1), t * Vector3(x0, y, z1), color)


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


## Mirante: the lookout on the summit of Morro da Boa Vista, where the hill road ends: the
## 14.5 m tower with its stairs and deck, the snack bar, the toilets, the guard hut and two radio
## masts round the clearing. Each piece stands on the slope where it is (MiranteSet).
func _mirante(c: Vector3) -> void:
	var tower := _stand_at(c + Vector3(14, 0, -12))
	_put_free(MiranteSet.tower(_b, tower), tower)
	_mark_built(Vector2(tower.origin.x, tower.origin.z), Vector2(MiranteSet.CORE_HALF, MiranteSet.CORE_HALF))
	mirante.tower = tower.origin
	mirante.deck = tower.origin + Vector3(0, MiranteSet.TOWER_DECK_Y, 0)
	_label("MIRANTE", tower.origin + Vector3(0, MiranteSet.TOWER_DECK_Y + 1.6, MiranteSet.CORE_HALF + 0.12), 18, Color("2a2a2a"))
	for piece: Array in [[Vector3(-14, 0, -12), 160.0, "snack_bar"], [Vector3(-13, 0, 10), 20.0, "toilets"], [Vector3(6, 0, 16), 180.0, "booth"]]:
		var t := _stand_at(c + (piece[0] as Vector3), piece[1])
		match piece[2]:
			"snack_bar":
				_put(MiranteSet.snack_bar(_b, t), t)
				_label("LANCHONETE", t * (MiranteSet.SNACK_SIGN_AT + Vector3(0, 0, -0.01)), 26, Color("8a2a10"), rad_to_deg(t.basis.get_euler().y) + 180.0)
				for sx in [-1.2, 1.2]: # the sign's two lamps, still on, and the light they throw
					_glow.box(Vector3(0.14, 0.03, 0.14), t * Vector3(sx, 4.11, -2.72), Color.WHITE)
				_lamp(t * Vector3(0, 3.6, -3.4), 1.6, 9.0, Config.LOOK_LAMP_WARM)
			"toilets": _put(MiranteSet.toilets(_b, t), t)
			"booth": _put(Props.booth(_b, t), t)
	for mast: Array in [[Vector3(-6, 0, -26), 26.0], [Vector3(26, 0, 6), 20.0]]:
		var t := _stand_at(c + (mast[0] as Vector3))
		_put(MiranteSet.radio_mast(_b, t, mast[1]), t)
		_red.box(Vector3(0.36, 0.36, 0.36), t * MiranteSet.mast_top(mast[1]), Color.WHITE)


## The way up the lookout, world points: from the ground by its south-west corner, up each
## flight round the lift shaft, out onto the deck. Players (and the bot) walk it point to point.
func tower_climb() -> Array:
	var t: Vector3 = mirante.tower
	var c := (MiranteSet.FLIGHT_IN + MiranteSet.FLIGHT_OUT) * 0.5
	var rise := MiranteSet.TOWER_DECK_Y / 4.0
	var out := [Vector3(t.x - c, ground_y(t), t.z + c + 3.0)]
	var corners := [Vector2(-c, c), Vector2(c, c), Vector2(c, -c), Vector2(-c, -c), Vector2(-c, c)]
	for i in corners.size():
		var k: Vector2 = corners[i]
		out.append(t + Vector3(k.x, rise * i, k.y))
	out.append(t + Vector3(MiranteSet.TOWER_HALF - 1.2, MiranteSet.TOWER_DECK_Y, MiranteSet.TOWER_HALF - 1.2))
	return out


## A transform standing on the ground at `p` (x, z), turned `yaw_deg`.
func _stand_at(p: Vector3, yaw_deg := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(p.x, ground_y(p), p.z))


## A prop's colliders without closing any cells (poles and rails in the forest, the tower's stairs).
## A collider may carry its own basis as a third element.
func _put_free(colliders: Array, t: Transform3D) -> void:
	for c: Array in colliders:
		var basis: Basis = c[2] if c.size() > 2 else Basis.IDENTITY
		_collide(t * (c[0] as Vector3), c[1], t.basis * basis)


## The road up Morro da Boa Vista from the gate at the forest's edge: grey pavers (drawn by
## _hill_paving) with a red brick walking lane on the right going up and a white line beside it,
## concrete power poles with sagging cables and a few lamps, guard rails round the outside of
## the bends, and the gate itself where the road enters the forest. It all follows hill_line,
## the smoothed road (_smooth_hill_road), which _hill has already levelled into the hillside.
func _hill_road() -> void:
	if hill_line.size() < 2:
		return
	var width := hill_width
	var forest := _plan(CityData.FOREST)
	var total := hill_length
	var gate_at := -1.0
	var step := 2.0
	var d := 0.0
	while d < total:
		if Geometry2D.is_point_in_polygon(hill_at(d), forest):
			gate_at = d + 6.0
			break
		d += step
	if gate_at < 0.0:
		return
	# Kerbs and verges up to the summit's clearing, then just the pavers across it.
	var summit := _plan(CityData.POIS["mirante"].lot)
	var clearing := total
	while clearing > gate_at and Geometry2D.is_point_in_polygon(hill_at(clearing), summit):
		clearing -= step
	_hill_paving(gate_at - 7.0, clearing, true)
	_hill_paving(clearing, total, false)
	# The gate: its sign faces the way you come from.
	var g := hill_at(gate_at)
	var dir := hill_heading(gate_at)
	var yaw := atan2(dir.x, dir.y)
	var gate := Transform3D(Basis(Vector3.UP, yaw), Vector3(g.x, ground_y(Vector3(g.x, 0, g.y)), g.y))
	_put_free(MiranteSet.gate(_b, gate, width), gate)
	mirante.gate = gate.origin
	mirante.gate_yaw = yaw
	_label("MORRO DA BOA VISTA", gate * (MiranteSet.GATE_SIGN_AT + Vector3(0, 0.15, -0.02)), 46, MiranteSet.SIGN_GREEN, rad_to_deg(yaw) + 180.0)
	_label("ÁREA DE RELEVANTE INTERESSE ECOLÓGICO", gate * (MiranteSet.GATE_SIGN_AT + Vector3(0, -0.5, -0.02)), 17, MiranteSet.SIGN_GREEN, rad_to_deg(yaw) + 180.0)
	# Warm light under the roof and over the guard hut's door: the gate is the last lit place.
	var hut := Vector3(width * 0.5 + 0.8 + 2.4, 0, 3.0)
	_lamp(gate * Vector3(0, 8.4, 1.0), 2.2, 16.0, Config.LOOK_LAMP_WARM)
	_lamp(gate * (hut + Vector3(0.4, 2.2, 2.1)), 1.2, 7.0, Config.LOOK_LAMP_WARM)
	_glow.box(Vector3(0.2, 0.03, 0.2), gate * (hut + Vector3(0.4, 2.39, 1.62)), Color.WHITE, gate.basis)
	# Flowers by the gate, as in the photo: hibiscus and bougainvillea, a purple ipê.
	for bush: Array in [[Vector3(-width * 0.5 - 2.5, 0, -3), Vegetation.Kind.HIBISCUS], [Vector3(-width * 0.5 - 3.0, 0, 2), Vegetation.Kind.HIBISCUS],
			[Vector3(width * 0.5 + 6.0, 0, -2), Vegetation.Kind.BOUGAINVILLEA], [Vector3(-width * 0.5 - 4.0, 0, 9), Vegetation.Kind.IPE_PURPLE],
			[Vector3(width * 0.5 + 5.0, 0, 10), Vegetation.Kind.BOUGAINVILLEA]]:
		var at := gate * (bush[0] as Vector3)
		at.y = ground_y(at)
		Vegetation.plant(_trees, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), at), bush[1], _rng)
	# Poles, cables and rails, from the gate to the summit (the lane and its line are paving).
	var poles: Array = []
	var rails := 0
	d = gate_at - 10.0
	var next_pole := gate_at + 12.0
	while d < total - 4.0:
		var e := minf(d + step, total - 4.0)
		var a := hill_at(d)
		var ra := hill_right(d)
		if d >= next_pole:
			next_pole += 36.0
			var at := a + ra * (width * 0.5 + 0.7)
			var n := poles.size()
			var t := Transform3D(Basis(Vector3.UP, atan2(ra.x, ra.y)), Vector3(at.x, ground_y(Vector3(at.x, 0, at.y)), at.y))
			var lamp := n % 3 == 1
			_put_free(MiranteSet.power_pole(_b, t, lamp, n % 5 == 2), t)
			if lamp and _rng.randf() < 0.6: # a few still burn
				_glow.box(Vector3(0.3, 0.06, 0.5), t * MiranteSet.LAMP_HEAD, Color.WHITE)
			poles.append(t)
		d = e
	# Cables sag from pole to pole.
	for i in poles.size() - 1:
		var p: Transform3D = poles[i]
		var q: Transform3D = poles[i + 1]
		for w: Vector3 in MiranteSet.wire_points():
			var a := p * w
			var b := q * w
			var mid := (a + b) * 0.5 + Vector3(0, -0.9 if w.y < 8.0 else -0.6, 0)
			var thick := 0.1 if w.y < 8.0 else 0.04
			if a.distance_to(b) < 0.1:
				continue
			_b.tube(MeshKit.sag(a, b, (mid.y - (a.y + b.y) * 0.5) * -1.0, 10), thick * 0.5, Props.DARK, 5)
	# Guard rails round the outside of every sharp bend on the hill.
	for bend: Array in RoadScatter._bends(hill_corners, hill_line, gate_at):
		var walked: float = bend[0]
		var outer: float = bend[1]
		var k := maxf(gate_at, walked - 14.0)
		while k < minf(total - 6.0, walked + 14.0):
			var a := hill_at(k) + hill_right(k) * outer * (width * 0.5 + 0.4)
			var b := hill_at(k + 4.0) + hill_right(k + 4.0) * outer * (width * 0.5 + 0.4)
			var pa := Vector3(a.x, ground_y(Vector3(a.x, 0, a.y)), a.y)
			var pb := Vector3(b.x, ground_y(Vector3(b.x, 0, b.y)), b.y)
			var t := Transform3D(Basis.looking_at((pb - pa).normalized(), Vector3.UP), pa)
			_put_free(MiranteSet.guard_rail(_b, t, pa.distance_to(pb)), t)
			rails += 1
			k += 4.0
	mirante.poles = poles.size()
	mirante.rails = rails


# --- The road up the hill -----------------------------------------------------------------

## The road up Morro da Boa Vista as it is drawn and walked: the traced points (pixels of the
## plan, so a road that wobbles a little every few metres) with every wobble under
## CITY_ROAD_STRAIGHTEN straightened out, then a smooth curve through what is left, a point every
## CITY_ROAD_STEP metres.
func _smooth_hill_road() -> void:
	var hill: Dictionary = CityData.street(HILL_ROAD)
	if not hill.is_empty():
		hill_width = CityData.width(hill)
		hill_corners = simplify(_plan(hill.pts), Config.CITY_ROAD_STRAIGHTEN)
	hill_line = smooth_line(hill_corners, Config.CITY_ROAD_STEP)
	hill_length = 0.0
	if hill_line.size() >= 2:
		hill_length = (hill_line.size() - 2) * Config.CITY_ROAD_STEP + hill_line[hill_line.size() - 2].distance_to(hill_line[hill_line.size() - 1])


## The point `d` metres along the road up the hill (x, z). hill_line is evenly spaced, so this
## is a lookup, not a walk along it.
func hill_at(d: float) -> Vector2:
	var n := hill_line.size()
	var i := clampi(floori(d / Config.CITY_ROAD_STEP), 0, n - 2)
	var a := hill_line[i]
	var b := hill_line[i + 1]
	return a.lerp(b, clampf((d - i * Config.CITY_ROAD_STEP) / maxf(a.distance_to(b), 0.001), 0.0, 1.0))


## The way the road up the hill runs `d` metres along it, (x, z), unit length.
func hill_heading(d: float) -> Vector2:
	return (hill_at(d + 1.0) - hill_at(d - 1.0)).normalized()


## Its right-hand side going up at `d`.
func hill_right(d: float) -> Vector2:
	var h := hill_heading(d)
	return Vector2(-h.y, h.x)


## The road up the hill climbs without bumps and lies level from side to side: its height is the
## hillside's under its centre averaged CITY_ROAD_SMOOTH metres either way (twice), every corner
## of its open cells takes the height of the road beside it, and past them the bench eases back
## into the hillside over CITY_ROAD_BLEND metres, a cutting above the road and a bank below it.
## Only the hill moves: the flat city stays at 0.
func _level_hill_road() -> void:
	var n := hill_line.size()
	if n < 2:
		return
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in n:
		raw[i] = ground_y(Vector3(hill_line[i].x, 0.0, hill_line[i].y))
	var reach := maxi(1, roundi(Config.CITY_ROAD_SMOOTH / Config.CITY_ROAD_STEP))
	var level := _average(_average(raw, reach), reach)
	# Open cells reach (width + 1.5 cells) / 2 from the centre (_layout), their corners
	# up to a cell's half diagonal further: all of those lie level.
	var flat := hill_width * 0.5 + cell * 1.5
	var far := flat + Config.CITY_ROAD_BLEND
	var best := PackedFloat32Array()
	best.resize(heights.size())
	best.fill(INF)
	var best_h := PackedFloat32Array()
	best_h.resize(heights.size())
	var span := ceili(far / cell)
	for i in n:
		var p := hill_line[i]
		var c0 := floori((p.x - lo.x) / cell)
		var r0 := floori((p.y - lo.y) / cell)
		for r in range(maxi(0, r0 - span), mini(gh, r0 + span + 1) + 1):
			for c in range(maxi(0, c0 - span), mini(gw, c0 + span + 1) + 1):
				var k := r * (gw + 1) + c
				var d2 := p.distance_squared_to(Vector2(lo.x + c * cell, lo.y + r * cell))
				if d2 < best[k]:
					best[k] = d2
					best_h[k] = level[i]
	for k in heights.size():
		if heights[k] <= 0.0 or best[k] >= far * far:
			continue
		heights[k] = lerpf(best_h[k], heights[k], smoothstep(flat, far, sqrt(best[k])))


## Each value the mean of itself and `reach` neighbours either side (fewer at the ends).
static func _average(values: PackedFloat32Array, reach: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(values.size())
	for i in values.size():
		var sum := 0.0
		var count := 0
		for j in range(maxi(0, i - reach), mini(values.size(), i + reach + 1)):
			sum += values[j]
			count += 1
		out[i] = sum / count
	return out


## The paving of the road up the hill from `from` to `to` metres along it, one smooth band across:
## pavers, the red brick lane on the right going up with a white line beside it and, with
## `edges`, a flush concrete kerb either side and a strip of packed earth out to the trees. Every
## edge is a clean curve instead of the cells' staircase, and the bands share their edges rather
## than lie one over another, so none can show through the next.
func _hill_paving(from: float, to: float, edges: bool) -> void:
	var half := hill_width * 0.5
	var kerb := half + Config.CITY_ROAD_KERB
	var verge := kerb + Config.CITY_ROAD_VERGE
	var lane := half - HILL_LANE
	var line := lane - HILL_LINE_GAP
	var offsets := [-half, line - HILL_LINE, line, lane, half]
	var colors := [MiranteSet.PAVERS, PAINT, MiranteSet.PAVERS, MiranteSet.BRICK]
	if edges:
		offsets = [-verge, -kerb] + offsets + [kerb, verge]
		colors = [VERGE, KERB] + colors + [KERB, VERGE]
	var lifts := []
	for c: Color in colors:
		lifts.append(0.03 if c == VERGE else 0.04)
	var d := maxf(0.0, from)
	var a := _cross_section(d, offsets)
	while d < to - 0.01:
		var e := minf(d + Config.CITY_ROAD_STEP, to)
		var b := _cross_section(e, offsets)
		for k in colors.size():
			var up := Vector3(0, lifts[k], 0)
			_g.ground_quad(a[k] + up, b[k] + up, b[k + 1] + up, a[k + 1] + up, colors[k])
		a = b
		d = e


## Points on the ground across the road up the hill at `d`, `offsets` metres to its right. On
## the inside of a bend tighter than they reach, they are pulled in so the band never folds over.
func _cross_section(d: float, offsets: Array) -> PackedVector3Array:
	var p := hill_at(d)
	var right := hill_right(d)
	var h0 := hill_heading(d - 2.0)
	var h1 := hill_heading(d + 2.0)
	var turn := absf(h0.angle_to(h1))
	var radius := 4.0 / turn if turn > 0.001 else INF
	var inner := signf((h1 - h0).dot(right)) # the side the bend's centre is on
	var out := PackedVector3Array()
	for o: float in offsets:
		var off := o
		if signf(o) == inner:
			off = inner * minf(absf(o), radius * 0.85)
		var q := p + right * off
		out.append(Vector3(q.x, ground_y(Vector3(q.x, 0.0, q.y)), q.y))
	return out


## `line` with every point closer than `tolerance` to the straight line past it dropped
## (Douglas-Peucker): the wobbles go, the real bends stay.
static func simplify(line: PackedVector2Array, tolerance: float) -> PackedVector2Array:
	if line.size() < 3:
		return line
	var keep := PackedByteArray()
	keep.resize(line.size())
	keep[0] = 1
	keep[line.size() - 1] = 1
	var spans := [Vector2i(0, line.size() - 1)]
	while not spans.is_empty():
		var span: Vector2i = spans.pop_back()
		var worst := 0.0
		var at := -1
		for i in range(span.x + 1, span.y):
			var off := Geometry2D.get_closest_point_to_segment(line[i], line[span.x], line[span.y]).distance_to(line[i])
			if off > worst:
				worst = off
				at = i
		if at >= 0 and worst > tolerance:
			keep[at] = 1
			spans.append(Vector2i(span.x, at))
			spans.append(Vector2i(at, span.y))
	var out := PackedVector2Array()
	for i in line.size():
		if keep[i] == 1:
			out.append(line[i])
	return out


## A smooth curve through every point of `points` (centripetal Catmull-Rom: no loops, no
## overshoot at a tight bend), returned as points `step` metres apart along it.
static func smooth_line(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var n := points.size()
	if n < 2:
		return points
	var dense := PackedVector2Array()
	for i in n - 1:
		var p1 := points[i]
		var p2 := points[i + 1]
		var p0 := points[i - 1] if i > 0 else p1 * 2.0 - p2
		var p3 := points[i + 2] if i + 2 < n else p2 * 2.0 - p1
		var pieces := maxi(1, ceili(p1.distance_to(p2) / (step * 0.25)))
		for k in pieces:
			dense.append(_catmull_rom(p0, p1, p2, p3, float(k) / pieces))
	dense.append(points[n - 1])
	var out := PackedVector2Array([dense[0]])
	var carry := 0.0 # metres walked since the last point out
	for i in dense.size() - 1:
		var a := dense[i]
		var b := dense[i + 1]
		var length := a.distance_to(b)
		var s := step - carry
		while s <= length:
			out.append(a.lerp(b, s / length))
			s += step
		carry = length - (s - step)
	if carry > step * 0.05:
		out.append(dense[dense.size() - 1])
	else:
		out[out.size() - 1] = dense[dense.size() - 1]
	return out


## The point `u` (0..1) of the way from p1 to p2 on a centripetal Catmull-Rom curve.
static func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, u: float) -> Vector2:
	var t1 := sqrt(maxf(p0.distance_to(p1), 0.001))
	var t2 := t1 + sqrt(maxf(p1.distance_to(p2), 0.001))
	var t3 := t2 + sqrt(maxf(p2.distance_to(p3), 0.001))
	var t := lerpf(t1, t2, u)
	var a1 := p0.lerp(p1, t / t1)
	var a2 := p1.lerp(p2, (t - t1) / (t2 - t1))
	var a3 := p2.lerp(p3, (t - t2) / (t3 - t2))
	var b1 := a1.lerp(a2, t / t2)
	var b2 := a2.lerp(a3, (t - t1) / (t3 - t1))
	return b1.lerp(b2, (t - t1) / (t2 - t1))


## The point `d` metres along a polyline.
func _along(line: PackedVector2Array, d: float) -> Vector2:
	for i in line.size() - 1:
		var length := line[i].distance_to(line[i + 1])
		if d <= length or i == line.size() - 2:
			return line[i].lerp(line[i + 1], clampf(d / maxf(length, 0.001), 0.0, 1.0))
		d -= length
	return line[line.size() - 1]


## The way a polyline runs `d` metres along it, (x, z), unit length.
func _heading(line: PackedVector2Array, d: float) -> Vector2:
	return (_along(line, d + 1.0) - _along(line, d - 1.0)).normalized()


## The right-hand side going along a polyline at `d` (forward is -Z, so right is +X going north).
func _right(line: PackedVector2Array, d: float) -> Vector2:
	var h := _heading(line, d)
	return Vector2(-h.y, h.x)


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
		if piece.street >= 0 and hill_line.size() >= 2 and streets.streets[piece.street].id == HILL_ROAD:
			continue # the road up the hill is its own smooth band with kerbs (_hill_paving)
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


## Trees on the hill: real ones (Vegetation) along the road so it runs between trunks and
## fronds, a thick wall of canopy boxes just behind them, thinner further in.
func _forest() -> void:
	for r in gh:
		for c in gw:
			if grid[r * gw + c] != FOREST:
				continue
			var roadside := _open(c - 1, r) or _open(c + 1, r) or _open(c, r - 1) or _open(c, r + 1)
			# Real trees (Vegetation) only along a street up on the hill: the forest's edge round
			# the whole town is far longer and gets the cheap crowns below (it ran out of memory).
			var by_road := _is(c - 1, r, STREET) or _is(c + 1, r, STREET) or _is(c, r - 1, STREET) or _is(c, r + 1, STREET)
			if by_road and ground_y(Vector3(lo.x + (c + 0.5) * cell, 0.0, lo.y + (r + 0.5) * cell)) < Config.CITY_REAL_TREES_ABOVE:
				by_road = false
			if roadside and by_road:
				# Back from the kerb: towards the side of the cell away from the open ground.
				var away := Vector2(int(_open(c - 1, r)) - int(_open(c + 1, r)), int(_open(c, r - 1)) - int(_open(c, r + 1)))
				var at := Vector3(lo.x + (c + 0.5 + away.x * 0.35 + _rng.randf_range(-0.1, 0.1)) * cell, 0.0,
					lo.y + (r + 0.5 + away.y * 0.35 + _rng.randf_range(-0.1, 0.1)) * cell)
				if mirante.has("gate") and Vector2(at.x, at.z).distance_to(Vector2(mirante.gate.x, mirante.gate.z)) < 9.0:
					continue # the portal and its hut stand here
				at.y = ground_y(at)
				var kind := Vegetation.forest_kind(_rng)
				Vegetation.plant(_trees, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), at), kind, _rng)
				roadside_trees.append({ "at": at, "kind": kind })
				continue
			var second := _open(c - 2, r) or _open(c + 2, r) or _open(c, r - 2) or _open(c, r + 2)
			if _rng.randf() > (0.85 if roadside else (0.7 if second else 0.08)):
				continue
			var w := _rng.randf_range(3.5, 6.5)
			var h := _rng.randf_range(7.0, 15.0)
			var at := Vector3(lo.x + (c + _rng.randf_range(0.3, 0.7)) * cell, 0.0, lo.y + (r + _rng.randf_range(0.3, 0.7)) * cell)
			at.y = ground_y(at) + h * 0.5 - 0.6
			# The deep forest: a tall lumpy crown down to the ground and a lighter tuft on top
			# (the cheap stand-in for a whole tree, a few hundred of them; asset_quality.md).
			var color: Color = LEAVES[_rng.randi() % LEAVES.size()]
			var turn := Basis(Vector3.UP, _rng.randf() * TAU)
			var key := r * gw + c
			_trees.blob(Vector3(w * 0.55, h * 0.5, w * 0.55), at, Vegetation.leaf(color), key, 0.28, 4, 7, turn)
			var lit: Color = Vegetation.LEAVES_LIT[key % Vegetation.LEAVES_LIT.size()]
			_trees.blob(Vector3(w * 0.32, h * 0.16, w * 0.32), at + Vector3(w * 0.08, h * 0.38, -w * 0.06), Vegetation.leaf(lit.darkened(0.15)), key + 7, 0.25, 3, 6, turn)


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
