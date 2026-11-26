class_name CityMap
extends GameMap
## Central Joinville, cut down to the five mission POIs and whatever lies between them.
##
## The edge is the convex hull of the POI lots grown by Config.CITY_MARGIN, so anything on a
## straight line between two POIs is in and the rest of the city is not. Inside it, CityData's
## traced streets, river, hill and squares are painted onto a grid of CITY_CELL-metre cells:
##
##   OUT     beyond the edge wall            WATER   Rio Cachoeira (bridges are STREET cells)
##   BLOCK   city blocks, filled with        FOREST  Morro da Boa Vista, closed except its road
##           solid buildings                 PARK    squares and the cemetery, open ground
##   STREET  roads, bridges, driveways       LOT     a POI's grounds;  BUILT  a POI's structures
##
## The same grid is the navigation grid, so what zombies think is open is exactly what is open.
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

const PLAN_COLORS := [Color("0c0d0f"), Color("6e675d"), Color("2c2e32"), Color("27506e"), Color("1f3d24"),
	Color("3f6a3a"), Color("b0a070"), Color("f0e8d0")]
const GROUND_COLORS := { OUT: Color("0d0e0f"), WATER: Color("0e1c26"), FOREST: Color("18261a"),
	PARK: Color("26361f"), LOT: Color("4a4b4d") }
const FACADES := [Color("7b7469"), Color("6d7078"), Color("8a8377"), Color("5f5a55"), Color("77706a"),
	Color("6a6e66"), Color("807a80"), Color("8d8a82")]
const ASPHALT := Color("242528")
const SHOPFRONT := Color("2a2b2f")
const PAINT := Color("b8b8a8")
const LEAVES := [Color("1c3320"), Color("23402a"), Color("182b1c"), Color("2a4a2c")]

var nav: NavGrid
var grid := PackedByteArray()        ## one cell type per cell, row by row from the north-west
var gw := 0
var gh := 0
var lo := Vector2.ZERO               ## (x, z) of the grid's north-west corner
var cell := Config.CITY_CELL
var boundary := PackedVector2Array() ## the map's edge, (x, z) in metres
var building_count := 0
var landmarks := {}
var prop_counts := {}               ## set piece props by kind
var mirante := {}                    ## where the Mirante's pieces stand (world): gate, gate_yaw, tower, deck, poles, rails
var roadside_trees: Array = []       ## [{ at, kind }]: the real trees (Vegetation) lining the forest's roads

var heights := PackedFloat32Array()  ## ground height at every cell corner, (gw + 1) x (gh + 1)
var _raised := PackedByteArray()     # 1 where any corner of the cell is above 0
var _floors := PackedByteArray()     # storeys of the building on each BLOCK cell (for the plan)
var _b := MeshKit.Builder.new()      # buildings, walls, POIs
var _g := MeshKit.Builder.new()      # ground and paint
var _trees := MeshKit.Builder.new()
var _glow := MeshKit.Builder.new()   # lit windows and lamps
var _red := MeshKit.Builder.new()    # aircraft warning lights on the radio masts
var _body := StaticBody3D.new()
var _rng := RandomNumberGenerator.new()


## `full` false lays the city out (grid, building heights, POI footprints) without the ground,
## trees, navigation or any node but the empty root: enough for a picture of it.
func _init(full := true) -> void:
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

	_edge()
	_layout()
	_hill()
	_buildings()
	_pois()
	if not full:
		return
	_scenery()
	_hill_road()
	_navigation()
	_ground()
	_hill_ground()
	_street_dressing()
	_forest()
	_edge_wall()

	root.add_child(_g.instance(null, false))
	root.add_child(_b.instance(null, false))
	root.add_child(_trees.instance(null, false))
	root.add_child(_glow.instance(MeshKit.emissive(Color("ffd9a0"), 2.5), false))
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


## The Mirante has its own objectives, built from where its gate and tower ended up.
func _mission_changed() -> void:
	if mission == "mirante" and mirante.has("gate") and nav != null:
		use_data(MapAreas.mirante(self))
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


func distance_to_edge(p: Vector3) -> float:
	var q := Vector2(p.x, p.z)
	var best := INF
	for i in boundary.size():
		best = minf(best, Geometry2D.get_closest_point_to_segment(q, boundary[i], boundary[(i + 1) % boundary.size()]).distance_to(q))
	return best


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

## The map's edge in (x, z) metres: the hull of the POI lots (and EDGE_EXTRA) grown by CITY_MARGIN.
static func edge_polygon() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for id: String in CityData.POIS:
		var poi: Dictionary = CityData.POIS[id]
		for p: Vector2 in poi.lot:
			pts.append(CityData.to_plan(p))
	for p: Vector2 in CityData.EDGE_EXTRA:
		pts.append(CityData.to_plan(p))
	var hull := Geometry2D.convex_hull(pts)
	if hull.size() > 1 and hull[0] == hull[hull.size() - 1]:
		hull.remove_at(hull.size() - 1)
	var grown: Array[PackedVector2Array] = Geometry2D.offset_polygon(hull, Config.CITY_MARGIN, Geometry2D.JOIN_ROUND)
	if grown.is_empty() or _poly_area(grown[0]) < _poly_area(hull): # wound the other way: it shrank
		hull.reverse()
		grown = Geometry2D.offset_polygon(hull, Config.CITY_MARGIN, Geometry2D.JOIN_ROUND)
	return grown[0]


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
func _stamp(line: PackedVector2Array, width: float, type: int, over: int) -> void:
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


func _layout() -> void:
	var inside := _mask([BLOCK, STREET, WATER, FOREST, PARK, LOT])
	_fill(boundary, BLOCK, _mask([OUT]))
	_fill(_plan(CityData.FOREST), FOREST, _mask([BLOCK]))
	for park: Array in CityData.PARKS:
		_fill(_plan(park), PARK, _mask([BLOCK]))
	_stamp(_plan(CityData.RIVER), CityData.RIVER_WIDTH, WATER, _mask([BLOCK, FOREST, PARK]))
	for street: Array in CityData.STREETS:
		_stamp(_plan(street.slice(2)), street[1], STREET, inside)
	for path: Array in CityData.SQUARE_PATHS:
		_stamp(_plan(path), CityData.LANE, STREET, _mask([BLOCK]))
	for id: String in CityData.POIS:
		var poi: Dictionary = CityData.POIS[id]
		_fill(_plan(poi.lot), LOT, _mask([BLOCK, FOREST, PARK, WATER]))
		_stamp(_plan([poi.at, poi.gate]), CityData.LANE, STREET, inside)


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
			var color: Color = MiranteSet.PAVERS if t == STREET else GROUND_COLORS.get(t, GROUND_COLORS[LOT])
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
	return t == STREET or t == PARK or t == LOT


## Carve every block into rectangles and stand a building on each.
func _buildings() -> void:
	var used := PackedByteArray()
	used.resize(gw * gh)
	for r in gh:
		for c in gw:
			var i := r * gw + c
			if grid[i] != BLOCK or used[i] == 1:
				continue
			var max_w := _rng.randi_range(3, 8)
			var max_h := _rng.randi_range(3, 8)
			var w := 1
			while w < max_w and c + w < gw and grid[i + w] == BLOCK and used[i + w] == 0:
				w += 1
			var h := 1
			while h < max_h and r + h < gh:
				var row_ok := true
				for k in w:
					var j := (r + h) * gw + c + k
					if grid[j] != BLOCK or used[j] == 1:
						row_ok = false
						break
				if not row_ok:
					break
				h += 1
			var floors := _storeys(c, r, w, h)
			for dr in h:
				for dc in w:
					used[(r + dr) * gw + c + dc] = 1
					_floors[(r + dr) * gw + c + dc] = floors
			_building(c, r, w, h, floors)


## Taller toward the centre (the terminal is the origin), with the odd tower.
func _storeys(c: int, r: int, w: int, h: int) -> int:
	var d := Vector2(lo.x + (c + w * 0.5) * cell, lo.y + (r + h * 0.5) * cell).length()
	var floors := _rng.randi_range(1, 3)
	var roll := _rng.randf()
	if d < 500.0:
		floors = _rng.randi_range(2, 6)
		if roll < 0.2:
			floors = _rng.randi_range(8, 18)
	elif d < 1000.0:
		floors = _rng.randi_range(2, 4)
		if roll < 0.06:
			floors = _rng.randi_range(7, 12)
	if mini(w, h) == 1:
		floors = mini(floors, 2)
	return floors


func _building(c: int, r: int, w: int, h: int, floors: int) -> void:
	building_count += 1
	var size := Vector3(w * cell, floors * Config.CITY_FLOOR_H + _rng.randf_range(0.0, 1.2), h * cell)
	var center := Vector3(lo.x + c * cell + size.x * 0.5, size.y * 0.5, lo.y + r * cell + size.z * 0.5)
	var color: Color = FACADES[_rng.randi() % FACADES.size()]
	_b.box(size, center, color.darkened(_rng.randf_range(0.0, 0.25)))
	# Which sides face somewhere a person can stand: [facing?, outward normal, length along the side]
	var sides := [[false, Vector3.FORWARD, size.x], [false, Vector3.BACK, size.x], [false, Vector3.LEFT, size.z], [false, Vector3.RIGHT, size.z]]
	for k in w:
		sides[0][0] = sides[0][0] or _open(c + k, r - 1)
		sides[1][0] = sides[1][0] or _open(c + k, r + h)
	for k in h:
		sides[2][0] = sides[2][0] or _open(c - 1, r + k)
		sides[3][0] = sides[3][0] or _open(c + w, r + k)
	var faced := false
	for side: Array in sides:
		if not side[0]:
			continue
		faced = true
		var out: Vector3 = side[1]
		var along: float = side[2]
		var x_side := absf(out.x) > 0.5
		var reach := (size.x if x_side else size.z) * 0.5
		var at := Vector3(center.x, 0, center.z) + out * (reach + 0.04)
		# a dark shop front along the pavement
		_b.box(Vector3(0.1, 2.8, along - 0.6) if x_side else Vector3(along - 0.6, 2.8, 0.1), at + Vector3(0, 1.4, 0), SHOPFRONT)
		if floors > 1 and _rng.randf() < 0.3: # somebody left a light on
			for n in _rng.randi_range(1, 3):
				var slide := _rng.randf_range(-0.4, 0.4) * (along - 2.0)
				var y := (_rng.randi_range(1, floors - 1) + 0.55) * Config.CITY_FLOOR_H
				var where := at + Vector3(0, y, 0) + (Vector3(0, 0, slide) if x_side else Vector3(slide, 0, 0))
				_glow.box(Vector3(0.1, 1.3, 1.5) if x_side else Vector3(1.5, 1.3, 0.1), where, Color.WHITE)
	if faced: # buildings buried inside a block are only ever seen from above
		_collide(center, size)


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


## Mirante: the lookout on the summit of Morro da Boa Vista, where the hill road ends: the
## 14.5 m tower with its stairs and deck, the snack bar, the toilets, the guard hut and two radio
## masts round the clearing. Each piece stands on the slope where it is (MiranteSet).
func _mirante(c: Vector3) -> void:
	var tower := _on_ground(c + Vector3(14, 0, -12))
	_put_free(MiranteSet.tower(_b, tower), tower)
	_mark_built(Vector2(tower.origin.x, tower.origin.z), Vector2(MiranteSet.CORE_HALF, MiranteSet.CORE_HALF))
	mirante.tower = tower.origin
	mirante.deck = tower.origin + Vector3(0, MiranteSet.TOWER_DECK_Y, 0)
	_label("MIRANTE", tower.origin + Vector3(0, MiranteSet.TOWER_DECK_Y + 1.6, MiranteSet.CORE_HALF + 0.12), 18, Color("2a2a2a"))
	for piece: Array in [[Vector3(-14, 0, -12), 160.0, "snack_bar"], [Vector3(-13, 0, 10), 20.0, "toilets"], [Vector3(6, 0, 16), 180.0, "booth"]]:
		var t := _on_ground(c + (piece[0] as Vector3), piece[1])
		match piece[2]:
			"snack_bar": _put(MiranteSet.snack_bar(_b, t), t)
			"toilets": _put(MiranteSet.toilets(_b, t), t)
			"booth": _put(Props.booth(_b, t), t)
	for mast: Array in [[Vector3(-6, 0, -26), 26.0], [Vector3(26, 0, 6), 20.0]]:
		var t := _on_ground(c + (mast[0] as Vector3))
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
func _on_ground(p: Vector3, yaw_deg := 0.0) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(p.x, ground_y(p), p.z))


## A prop's colliders without closing any cells (poles and rails in the forest, the tower's stairs).
## A collider may carry its own basis as a third element.
func _put_free(colliders: Array, t: Transform3D) -> void:
	for c: Array in colliders:
		var basis: Basis = c[2] if c.size() > 2 else Basis.IDENTITY
		_collide(t * (c[0] as Vector3), c[1], t.basis * basis)


## The road up Morro da Boa Vista from the gate at the forest's edge: grey pavers (drawn by
## _hill_ground) with a red brick walking lane on the right going up and a white line beside it,
## concrete power poles with sagging cables and a few lamps, guard rails round the outside of
## the bends, and the gate itself where the road enters the forest.
func _hill_road() -> void:
	var line := PackedVector2Array()
	var width := 0.0
	for street: Array in CityData.STREETS:
		if street[0] == "Rua Pastor Guilherme Rau":
			line = _plan(street.slice(2))
			width = street[1]
	var forest := _plan(CityData.FOREST)
	var total := 0.0
	for i in line.size() - 1:
		total += line[i].distance_to(line[i + 1])
	var gate_at := -1.0
	var step := 2.0
	var d := 0.0
	while d < total:
		if Geometry2D.is_point_in_polygon(_along(line, d), forest):
			gate_at = d + 6.0
			break
		d += step
	if gate_at < 0.0:
		return
	# The gate: its sign faces the way you come from.
	var g := _along(line, gate_at)
	var dir := _heading(line, gate_at)
	var yaw := atan2(dir.x, dir.y)
	var gate := Transform3D(Basis(Vector3.UP, yaw), Vector3(g.x, ground_y(Vector3(g.x, 0, g.y)), g.y))
	_put_free(MiranteSet.gate(_b, gate, width), gate)
	mirante.gate = gate.origin
	mirante.gate_yaw = yaw
	_label("MORRO DA BOA VISTA", gate * (MiranteSet.GATE_SIGN_AT + Vector3(0, 0.15, -0.02)), 46, MiranteSet.SIGN_GREEN, rad_to_deg(yaw) + 180.0)
	_label("ÁREA DE RELEVANTE INTERESSE ECOLÓGICO", gate * (MiranteSet.GATE_SIGN_AT + Vector3(0, -0.5, -0.02)), 17, MiranteSet.SIGN_GREEN, rad_to_deg(yaw) + 180.0)
	# Flowers by the gate, as in the photo: hibiscus and bougainvillea, a purple ipê.
	for bush: Array in [[Vector3(-width * 0.5 - 2.5, 0, -3), Vegetation.Kind.HIBISCUS], [Vector3(-width * 0.5 - 3.0, 0, 2), Vegetation.Kind.HIBISCUS],
			[Vector3(width * 0.5 + 6.0, 0, -2), Vegetation.Kind.BOUGAINVILLEA], [Vector3(-width * 0.5 - 4.0, 0, 9), Vegetation.Kind.IPE_PURPLE],
			[Vector3(width * 0.5 + 5.0, 0, 10), Vegetation.Kind.BOUGAINVILLEA]]:
		var at := gate * (bush[0] as Vector3)
		at.y = ground_y(at)
		Vegetation.plant(_trees, Transform3D(Basis(Vector3.UP, _rng.randf() * TAU), at), bush[1], _rng)
	# Lane, line, poles, cables and rails, from the gate to the summit.
	var lane := 2.2
	var poles: Array = []
	var rails := 0
	d = gate_at - 10.0
	var next_pole := gate_at + 12.0
	while d < total - 4.0:
		var e := minf(d + step, total - 4.0)
		var a := _along(line, d)
		var b := _along(line, e)
		var ra := _right(line, d)
		var rb := _right(line, e)
		var off := width * 0.5 - lane * 0.5
		_strip(a + ra * off, b + rb * off, ra, rb, lane, MiranteSet.BRICK)
		_strip(a + ra * (off - lane * 0.5 - 0.1), b + rb * (off - lane * 0.5 - 0.1), ra, rb, 0.14, PAINT)
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
			for seg: Array in [[a, mid], [mid, b]]:
				var s0: Vector3 = seg[0]
				var s1: Vector3 = seg[1]
				if s0.distance_to(s1) < 0.1:
					continue
				_b.box(Vector3(thick, thick, s0.distance_to(s1)), (s0 + s1) * 0.5, Props.DARK, Basis.looking_at((s1 - s0).normalized(), Vector3.UP))
	# Guard rails round the outside of every sharp bend on the hill.
	var walked := 0.0
	for i in range(1, line.size() - 1):
		walked += line[i - 1].distance_to(line[i])
		if walked < gate_at:
			continue
		var din := (line[i] - line[i - 1]).normalized()
		var dout := (line[i + 1] - line[i]).normalized()
		var turn := din.angle_to(dout)
		if absf(turn) < 0.35:
			continue
		var outer := -1.0 if turn > 0.0 else 1.0 # turning right (+ in this x, z plane): the outside is the left
		var k := maxf(gate_at, walked - 14.0)
		while k < minf(total - 6.0, walked + 14.0):
			var a := _along(line, k) + _right(line, k) * outer * (width * 0.5 + 0.4)
			var b := _along(line, k + 4.0) + _right(line, k + 4.0) * outer * (width * 0.5 + 0.4)
			var pa := Vector3(a.x, ground_y(Vector3(a.x, 0, a.y)), a.y)
			var pb := Vector3(b.x, ground_y(Vector3(b.x, 0, b.y)), b.y)
			var t := Transform3D(Basis.looking_at((pb - pa).normalized(), Vector3.UP), pa)
			_put_free(MiranteSet.guard_rail(_b, t, pa.distance_to(pb)), t)
			rails += 1
			k += 4.0
	mirante.poles = poles.size()
	mirante.rails = rails


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


## A strip of paint `w` wide over the ground from `a` to `b` (centre line), hugging the slope.
func _strip(a: Vector2, b: Vector2, ra: Vector2, rb: Vector2, w: float, color: Color) -> void:
	var corners := [a - ra * w * 0.5, b - rb * w * 0.5, b + rb * w * 0.5, a + ra * w * 0.5]
	var pts := []
	for q: Vector2 in corners:
		pts.append(Vector3(q.x, ground_y(Vector3(q.x, 0, q.y)) + 0.06, q.y))
	_g.ground_quad(pts[0], pts[1], pts[2], pts[3], color)


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
		nav.solid[i] = 0 if (t == STREET or t == PARK or t == LOT) else 1
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
	_g.box(size, center, ASPHALT)
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


## Centre lines on every street and lamp posts along the avenues.
func _street_dressing() -> void:
	for street: Array in CityData.STREETS:
		var width: float = street[1]
		var line := _plan(street.slice(2))
		var walked := 0.0
		var next_dash := 6.0
		var next_lamp := 20.0
		var lamp_side := 1.0
		for s in line.size() - 1:
			var a := line[s]
			var b := line[s + 1]
			var length := a.distance_to(b)
			var dir := (b - a) / maxf(length, 0.001)
			var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x))
			while next_dash < walked + length:
				var p := a + dir * (next_dash - walked)
				next_dash += 12.0
				if width > CityData.LANE and type_at(Vector3(p.x, 0, p.y)) == STREET:
					_g.box(Vector3(3.5, 0.02, 0.22), Vector3(p.x, 0.03 + ground_y(Vector3(p.x, 0, p.y)), p.y), PAINT, basis)
			while width >= CityData.AVENUE and next_lamp < walked + length:
				var p := a + dir * (next_lamp - walked) + Vector2(-dir.y, dir.x) * (width * 0.5 - 1.0) * lamp_side
				next_lamp += 48.0
				lamp_side = -lamp_side
				if type_at(Vector3(p.x, 0, p.y)) != STREET:
					continue
				var y := ground_y(Vector3(p.x, 0, p.y))
				_b.box(Vector3(0.2, 7.0, 0.2), Vector3(p.x, y + 3.5, p.y), Props.STEEL)
				_collide(Vector3(p.x, y + 3.5, p.y), Vector3(0.2, 7.0, 0.2))
				if _rng.randf() < 0.35: # most of the grid is down
					_glow.box(Vector3(0.6, 0.2, 0.6), Vector3(p.x, y + 7.0, p.y), Color.WHITE)
			walked += length


## Trees on the hill: real ones (Vegetation) along the road so it runs between trunks and
## fronds, a thick wall of canopy boxes just behind them, thinner further in.
func _forest() -> void:
	for r in gh:
		for c in gw:
			if grid[r * gw + c] != FOREST:
				continue
			var roadside := _open(c - 1, r) or _open(c + 1, r) or _open(c, r - 1) or _open(c, r + 1)
			if roadside:
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
			if _rng.randf() > (0.7 if second else 0.08):
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

## The layout from above, `scale` pixels per cell: buildings lighter the taller they are, POI
## structures near white, each POI ringed in red.
func plan_image(scale := 2) -> Image:
	var img := Image.create(gw, gh, false, Image.FORMAT_RGB8)
	for r in gh:
		for c in gw:
			var t := grid[r * gw + c]
			var color: Color = PLAN_COLORS[t]
			if t == BLOCK:
				color = color.lightened(minf(_floors[r * gw + c], 16.0) / 16.0 * 0.55)
			img.set_pixel(c, r, color)
	for id: String in CityData.POIS:
		var p := poi_pos(id)
		var at := Vector2i(floori((p.x - lo.x) / cell), floori((p.z - lo.y) / cell))
		for d in range(-14, 15):
			for k in [-14, -13, 13, 14]:
				_dot(img, at + Vector2i(d, k), 0, Color("ff3020"))
				_dot(img, at + Vector2i(k, d), 0, Color("ff3020"))
	img.resize(gw * scale, gh * scale, Image.INTERPOLATE_NEAREST)
	return img


## The reference map with everything outside the edge dimmed, the edge in red, the traced
## streets in blue and the POIs as red squares. Null if the reference picture is missing.
func reference_overlay() -> Image:
	var path := ProjectSettings.globalize_path(CityData.REF_IMAGE)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(path)
	img.convert(Image.FORMAT_RGB8)
	var edge: Array[Vector2] = []
	for p in boundary:
		edge.append(p / CityData.M_PER_PX + CityData.ORIGIN_PX)
	for y in img.get_height():
		var xs: Array[float] = []
		for i in edge.size():
			var a := edge[i]
			var b := edge[(i + 1) % edge.size()]
			if (a.y <= y) != (b.y <= y):
				xs.append(a.x + (y - a.y) / (b.y - a.y) * (b.x - a.x))
		xs.sort()
		var k := 0
		var inside := false
		for x in img.get_width():
			while k < xs.size() and xs[k] <= x:
				inside = not inside
				k += 1
			if not inside:
				img.set_pixel(x, y, img.get_pixel(x, y).darkened(0.62))
	for street: Array in CityData.STREETS:
		for s in range(2, street.size() - 1):
			_line(img, street[s], street[s + 1], 1, Color("1040ff"))
	for i in edge.size():
		_line(img, edge[i], edge[(i + 1) % edge.size()], 2, Color("ff2010"))
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
