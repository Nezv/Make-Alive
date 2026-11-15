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
## The ground is flat for now: the hill has its road and its forest but no height.
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
## The menu's night-map look, by cell type (OUT is see-through).
const MENU_COLORS := [Color(0, 0, 0, 0), Color("2e3136"), Color("101215"), Color("1d4a66"), Color("17301c"),
	Color("2c4a2a"), Color("6b6250"), Color("d8cfb4")]
const MENU_EDGE := Color("99ff66", 0.55)
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

var _floors := PackedByteArray()     # storeys of the building on each BLOCK cell (for the plan)
var _b := MeshKit.Builder.new()      # buildings, walls, POIs
var _g := MeshKit.Builder.new()      # ground and paint
var _trees := MeshKit.Builder.new()
var _glow := MeshKit.Builder.new()   # lit windows and lamps
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
	_buildings()
	_pois()
	if not full:
		return
	_navigation()
	_ground()
	_street_dressing()
	_forest()
	_edge_wall()

	root.add_child(_g.instance(null, false))
	root.add_child(_b.instance(null, false))
	root.add_child(_trees.instance(null, false))
	root.add_child(_glow.instance(MeshKit.emissive(Color("ffd9a0"), 2.5), false))


# --- GameMap ------------------------------------------------------------------------

## A mission starts at its POI; free play at the bus terminal.
func player_spawn() -> Vector3:
	return poi_pos(mission if CityData.POIS.has(mission) else "terminal") + Vector3(0, 0.1, 0)


func player_spawn_point() -> Vector3:
	return player_spawn() + Vector3(randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0))


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
		p = nav.center_of(nav.cell_of(p)) + Vector3(0, 0.1, 0)
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
	return nav.nearest_free(around + Vector3(Config.CITY_SPAWN_NEAR, 0.1, 0))


func is_direct(from: Vector3, to: Vector3) -> bool:
	return nav.is_direct(from, to)


func nav_target(from: Vector3, to: Vector3, lane := 0.0) -> Vector3:
	return nav.nav_target(from, to, lane)


# --- Questions about the layout ---------------------------------------------------------

## Where a player stands at a POI ("hospital", "terminal", "prefeitura", "batalhao", "mirante").
func poi_pos(id: String) -> Vector3:
	var poi: Dictionary = CityData.POIS[id]
	return CityData.to_world(poi.at)


func contains(p: Vector3) -> bool:
	return Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), boundary)


func distance_to_edge(p: Vector3) -> float:
	var q := Vector2(p.x, p.z)
	var best := INF
	for i in boundary.size():
		best = minf(best, Geometry2D.get_closest_point_to_segment(q, boundary[i], boundary[(i + 1) % boundary.size()]).distance_to(q))
	return best


func area_km2() -> float:
	return _area(boundary) / 1.0e6


func type_at(p: Vector3) -> int:
	var c := floori((p.x - lo.x) / cell)
	var r := floori((p.z - lo.y) / cell)
	if c < 0 or r < 0 or c >= gw or r >= gh:
		return OUT
	return grid[r * gw + c]


func layout_hash() -> int:
	return hash([hash(grid), hash(_floors), building_count])


# --- The edge and the grid ------------------------------------------------------------

func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		a += poly[i].cross(poly[(i + 1) % poly.size()])
	return absf(a) * 0.5


func _edge() -> void:
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
	if grown.is_empty() or _area(grown[0]) < _area(hull): # wound the other way: it shrank
		hull.reverse()
		grown = Geometry2D.offset_polygon(hull, Config.CITY_MARGIN, Geometry2D.JOIN_ROUND)
	boundary = grown[0]

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
	for id: String in CityData.POIS:
		var poi: Dictionary = CityData.POIS[id]
		_fill(_plan(poi.lot), LOT, _mask([BLOCK, FOREST, PARK, WATER]))
		_stamp(_plan([poi.at, poi.gate]), CityData.LANE, STREET, inside)


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
		var mid := Vector3(lo.x + (c + n * 0.5) * cell, 0.02, lo.y + (r + 0.5) * cell)
		if GROUND_COLORS.has(t):
			_g.flat(Vector2(n * cell, cell), mid, GROUND_COLORS[t])
		if t == WATER or t == FOREST: # nobody swims and the forest is too thick: closed to players too
			_collide(mid + Vector3(0, 1.5, 0), Vector3(n * cell, 3.0, cell)))
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
					_g.box(Vector3(3.5, 0.02, 0.22), Vector3(p.x, 0.03, p.y), PAINT, basis)
			while width >= CityData.AVENUE and next_lamp < walked + length:
				var p := a + dir * (next_lamp - walked) + Vector2(-dir.y, dir.x) * (width * 0.5 - 1.0) * lamp_side
				next_lamp += 48.0
				lamp_side = -lamp_side
				if type_at(Vector3(p.x, 0, p.y)) != STREET:
					continue
				_b.box(Vector3(0.2, 7.0, 0.2), Vector3(p.x, 3.5, p.y), Props.STEEL)
				_collide(Vector3(p.x, 3.5, p.y), Vector3(0.2, 7.0, 0.2))
				if _rng.randf() < 0.35: # most of the grid is down
					_glow.box(Vector3(0.6, 0.2, 0.6), Vector3(p.x, 7.0, p.y), Color.WHITE)
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
			var at := Vector3(lo.x + (c + _rng.randf_range(0.3, 0.7)) * cell, h * 0.5, lo.y + (r + _rng.randf_range(0.3, 0.7)) * cell)
			_trees.box(Vector3(w, h, w), at, LEAVES[_rng.randi() % LEAVES.size()], Basis(Vector3.UP, _rng.randf() * TAU))


## The wall where the map ends.
func _edge_wall() -> void:
	for i in boundary.size():
		_wall(boundary[i], boundary[(i + 1) % boundary.size()], Config.CITY_WALL_H, Props.CONCRETE_DARK)


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


## The whole city for the main menu: `image` (RGBA, transparent outside the edge, which glows)
## and `pois`, each POI's `at` as a 0..1 position on that image. Lays the city out and frees it.
static func menu_picture(scale := 2) -> Dictionary:
	var city := CityMap.new(false)
	var img := Image.create(city.gw, city.gh, false, Image.FORMAT_RGBA8)
	for r in city.gh:
		for c in city.gw:
			var i := r * city.gw + c
			var t := city.grid[i]
			var color: Color = MENU_COLORS[t]
			if t == BLOCK:
				color = color.lightened(minf(city._floors[i], 16.0) / 16.0 * 0.5)
			elif t == OUT:
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var n := Vector2i(c, r) + d
					if n.x >= 0 and n.y >= 0 and n.x < city.gw and n.y < city.gh and city.grid[n.y * city.gw + n.x] != OUT:
						color = MENU_EDGE
			img.set_pixel(c, r, color)
	img.resize(city.gw * scale, city.gh * scale, Image.INTERPOLATE_NEAREST)
	var pois := {}
	for id: String in CityData.POIS:
		var p := city.poi_pos(id)
		pois[id] = Vector2((p.x - city.lo.x) / (city.gw * city.cell), (p.z - city.lo.y) / (city.gh * city.cell))
	city.root.free()
	return { "image": img, "pois": pois }


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
