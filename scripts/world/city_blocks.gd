class_name CityBlocks
extends RefCounted
## The town's mass (S043): every block between the streets is an îlot, closed along its edge by a
## row of narrow houses, Paris before Haussmann (the Turgot plan): each house its own width (two to
## five window bays), its own height and its own roof, corner houses turning every corner, courts
## inside with the back buildings and halls of the traced footprints (CityOsm), an hôtel
## particulier now and then behind its court and gate, gardens behind walls at the edge of town.
##
## The îlots come from CityMap's 4 m grid: each 4-connected run of BLOCK cells, its outline traced
## round the cells and straightened (Config.CITY_BLOCK_SIMPLIFY), so its edges lie on the streets'
## building lines within a metre or two. Every class of place has its own houses (CLASSES): the old
## core round the place du Marché and the place de l'Église, the main streets (mansards over a stone
## ground floor), the ordinary rues, the edge of town, post-war slabs round the hospital and the bus
## station, ateliers along the river.
##
## `plan()` is the layout (data only: `ilots`, `houses`, `walls`); `build()` makes the walls and roofs
## into CityMap's builders and one collision shape per îlot (its street walls). Outside the detail
## area an îlot is only its silhouette: its outline raised to the height of its houses.
## No windows, doors, cornices, dormers or chimneys: those are the facade and roof kits (S157-S164).

## Per class of place: floors [min, max], width in window bays [min, max] (`width` in metres
## instead for the slabs), depth from the street in metres, the roof, its pitch in degrees, the
## share of tile roofs (the rest slate), how far the oldest lean (metres at the eave), the share of
## a row left as a garden behind a wall, and whether the ground floor is stone.
const CLASSES := {
	"core": { "floors": [4, 6], "bays": [2, 3], "depth": [9.0, 12.0], "roof": "gable", "pitch": [50.0, 56.0], "tile": 0.5, "lean": 0.16, "gap": 0.0, "wing": 0.75 },
	"main": { "floors": [4, 5], "bays": [3, 4], "depth": [11.0, 14.0], "roof": "mansard", "pitch": [72.0, 76.0], "tile": 0.0, "plinth": true, "gap": 0.0, "wing": 0.6 },
	"rue": { "floors": [3, 5], "bays": [2, 4], "depth": [9.0, 13.0], "roof": "gable", "pitch": [42.0, 50.0], "tile": 0.55, "gap": 0.03, "wing": 0.45 },
	"faubourg": { "floors": [2, 3], "bays": [2, 4], "depth": [8.0, 11.0], "roof": "gable", "pitch": [36.0, 44.0], "tile": 0.8, "gap": 0.25, "wing": 0.1 },
	"postwar": { "floors": [6, 9], "width": [18.0, 36.0], "depth": [11.0, 13.0], "roof": "flat", "pitch": [0.0, 0.0], "tile": 0.0, "gap": 0.0 },
	"atelier": { "floors": [1, 2], "width": [14.0, 30.0], "depth": [14.0, 24.0], "roof": "sawtooth", "pitch": [0.0, 0.0], "tile": 0.0, "storey": 4.5, "gap": 0.0 },
	"hotel": { "floors": [3, 3], "width": [0.0, 0.0], "depth": [12.0, 14.0], "roof": "mansard", "pitch": [72.0, 76.0], "tile": 0.0, "plinth": true, "gap": 0.0 },
	"back": { "floors": [2, 4], "roof": "hip", "pitch": [30.0, 40.0], "tile": 0.6, "gap": 0.0 },
}
## Which class wins a corner between two rows.
const RANK := { "main": 5, "core": 4, "postwar": 3, "rue": 2, "atelier": 1, "faubourg": 0 }

const MAIN_FAUBOURG_FLOORS := [3, 4]   ## main streets at the edge of town
const WING_COURT := Vector2(4.0, 8.0)  ## metres: the court between a house and the wing behind it
const WING_DEPTH := Vector2(6.0, 10.0)
const WING_PITCH := Vector2(40.0, 50.0)
const COURT_FILL := { "core": 0.65, "main": 0.5, "rue": 0.4, "faubourg": 0.08 } ## share of a deep court's free ground built on
const COURT_STEP := 18.0               ## metres between the court's back buildings
const COURT_CLEAR := 16.0              ## metres from the street they keep
const COURT_SHED := Vector2(8.0, 15.0) ## metres: their size
const MANSARD_RISE := 2.8              ## metres: the mansard's steep lower slope
const MANSARD_TOP := 20.0              ## degrees: its top
const HALL_PITCH := 15.0
const HALL_STOREY := 4.5
const GABLE_RISE_MAX := 8.0            ## metres: the steepest roof over the deepest house stops here
const SAWTOOTH := 5.0                  ## metres per tooth of an atelier's roof
const SAWTOOTH_RISE := 2.4
const PLINTH := 3.6                    ## metres: the stone ground floor
const GARDEN_WALL := 2.4
const GATE_WALL := 3.8
const GATE := 3.6                      ## metres: a porte cochère's opening
const COURT := Vector2(12.0, 16.0)     ## metres: an hôtel's front court, street to house
const SILHOUETTE_ROOF := 2.5           ## metres over the eaves that stand for the roofs from afar
const LIT := Vector2(1.2, 1.5)         ## a lit window

const PLASTER := [Color("c9bb9f"), Color("bfa883"), Color("b3a58f"), Color("a69c8c"), Color("cfc3a6"),
	Color("b9a07a"), Color("9f9a90"), Color("c4b59a"), Color("ad9877"), Color("bdb2a2")]
const STONE := Color("8f877a")
const SLATE := [Color("4b525b"), Color("535a63"), Color("454b52")]
const ZINC := Color("7d858c")
const TILES := [Color("8a4b36"), Color("9b5a3f"), Color("7a3f2f"), Color("a0634a")]
const TAR := Color("3a3a3c")
const GLASS := Color("5e7480")
const GATE_WOOD := Color("3a2a20")
const COURT_GROUND := Color("4a4640")
const GARDEN := Color("2a3322")

var ilots: Array = []    ## { outline (x, z, turning positive), area, cls, centre, street_edge, fronted, silhouette, eave }
var houses: Array = []   ## { foot, shape (row / corner / back / hotel / small), cls, floors, eave, roof, pitch, roof_colour, wall, plinth, width, out, lean, faces_street, ilot }
var walls: Array = []    ## { a, b, height, gate, ilot }: garden walls and hôtels' gate walls on the street
var triangles := 0
var built_ilots := 0     ## îlots with a collision shape

var _map: CityMap
var _labels := PackedInt32Array()  # îlot of each BLOCK cell, -1 elsewhere
var _skind := PackedByteArray()    # CityMap's street kind per cell (0 none, 1 rue, 2 principale)
var _river := PackedVector2Array()
var _core: Array[Vector2] = []
var _marche := Vector2.ZERO
var _postwar: Array[Vector2] = []
var _hotel_plots: Array = []       # PackedVector2Array per hôtel: its court and house, no back building there
var _row_floors := -1              # the row being built: its houses keep within a floor of this


func _init(map: CityMap) -> void:
	_map = map
	_skind = map.street_kind
	for p: Vector2 in CityData.RIVER:
		_river.append(CityData.to_plan(p))
	for id in ["marche", "eglise"]:
		_core.append(_centroid(_plan(CityData.square(id).pts)))
	_marche = _core[0]
	for id in ["hospital", "terminal"]:
		_postwar.append(CityData.to_plan(CityData.POIS[id].at))


# --- The layout ------------------------------------------------------------------------------

func plan() -> void:
	_label()
	_outlines()
	for i in ilots.size():
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([18510309, i])
		_classify(i, rng)
		if ilots[i].area < Config.CITY_ILOT_SMALL:
			_small(i, rng)
		else:
			_rows(i, rng)
	_backs()
	_fill_courts()


## One label per 4-connected run of BLOCK cells.
func _label() -> void:
	var gw := _map.gw
	var gh := _map.gh
	var grid := _map.grid
	_labels.resize(gw * gh)
	_labels.fill(-1)
	var n := 0
	var queue := PackedInt32Array()
	for start in grid.size():
		if grid[start] != CityMap.BLOCK or _labels[start] != -1:
			continue
		_labels[start] = n
		queue.clear()
		queue.append(start)
		var head := 0
		while head < queue.size():
			var i := queue[head]
			head += 1
			var c := i % gw
			for j: int in [i - 1 if c > 0 else -1, i + 1 if c < gw - 1 else -1, i - gw, i + gw]:
				if j >= 0 and j < grid.size() and grid[j] == CityMap.BLOCK and _labels[j] == -1:
					_labels[j] = n
					queue.append(j)
		ilots.append({ "cells": queue.size(), "first": start })
		n += 1


## Each îlot's outer outline: the cells' boundary edges chained into loops (turning left at a corner
## where two of its cells only touch diagonally), the largest loop kept, then straightened.
func _outlines() -> void:
	var gw := _map.gw
	var gh := _map.gh
	var cw := gw + 1
	var edges: Array = []   # per îlot: PackedInt32Array of (from corner, to corner) pairs
	edges.resize(ilots.size())
	for k in ilots.size():
		edges[k] = PackedInt32Array()
	for r in gh:
		for c in gw:
			var l := _labels[r * gw + c]
			if l < 0:
				continue
			var e: PackedInt32Array = edges[l]
			if r == 0 or _labels[(r - 1) * gw + c] != l:
				e.append(r * cw + c); e.append(r * cw + c + 1)
			if c == gw - 1 or _labels[r * gw + c + 1] != l:
				e.append(r * cw + c + 1); e.append((r + 1) * cw + c + 1)
			if r == gh - 1 or _labels[(r + 1) * gw + c] != l:
				e.append((r + 1) * cw + c + 1); e.append((r + 1) * cw + c)
			if c == 0 or _labels[r * gw + c - 1] != l:
				e.append((r + 1) * cw + c); e.append(r * cw + c)
			edges[l] = e
	var kept: Array = []
	for k in ilots.size():
		var loop := _largest_loop(edges[k], cw)
		var raw := PackedVector2Array()
		for key in loop:
			raw.append(_map.lo + Vector2(key % cw, key / cw) * _map.cell)
		raw = _drop_collinear(raw)
		var outline := _straighten(raw)
		var a := area(outline)
		if a < 0.0:
			outline.reverse()
			a = -a
		var il: Dictionary = ilots[k]
		il.merge({ "outline": outline, "area": a, "centre": _centroid(outline), "cls": "rue", "street_edge": 0.0,
			"fronted": 0.0, "silhouette": false, "eave": 0.0, "index": k })
	edges.clear()


func _largest_loop(e: PackedInt32Array, cw: int) -> PackedInt32Array:
	var out := {}  # corner -> [edge indices]
	for i in range(0, e.size(), 2):
		if out.has(e[i]):
			(out[e[i]] as Array).append(i)
		else:
			out[e[i]] = [i]
	var used := PackedByteArray()
	used.resize(e.size() / 2)
	var best := PackedInt32Array()
	var best_area := 0.0
	for s in range(0, e.size(), 2):
		if used[s / 2] == 1:
			continue
		var loop := PackedInt32Array()
		var i := s
		while used[i / 2] == 0:
			used[i / 2] = 1
			loop.append(e[i])
			var here := e[i + 1]
			var d_in := Vector2i(here % cw - e[i] % cw, here / cw - e[i] / cw)
			var next := -1
			var turn := -2
			for j: int in out.get(here, []):
				if used[j / 2] == 1:
					continue
				var d_out := Vector2i(e[j + 1] % cw - here % cw, e[j + 1] / cw - here / cw)
				var t := d_in.x * d_out.y - d_in.y * d_out.x  # +1 left, 0 on, -1 right
				if t > turn:
					turn = t
					next = j
			if next < 0:
				break
			i = next
		var a := 0.0
		for k in loop.size():
			var p := Vector2(loop[k] % cw, loop[k] / cw)
			var q := Vector2(loop[(k + 1) % loop.size()] % cw, loop[(k + 1) % loop.size()] / cw)
			a += p.cross(q)
		if absf(a) > best_area:
			best_area = absf(a)
			best = loop
	return best


static func _drop_collinear(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	for i in n:
		var a := pts[(i - 1 + n) % n]
		var b := pts[i]
		var c := pts[(i + 1) % n]
		if absf((b - a).cross(c - b)) > 0.001:
			out.append(b)
	return out


## Douglas-Peucker on the closed outline, falling back to a tighter tolerance when the straight
## version crosses itself or loses too much of the block.
func _straighten(raw: PackedVector2Array) -> PackedVector2Array:
	if raw.size() < 4:
		return raw
	var raw_area := absf(area(raw))
	for tol: float in [Config.CITY_BLOCK_SIMPLIFY, Config.CITY_BLOCK_SIMPLIFY * 0.5]:
		var far := 0
		for i in raw.size():
			if raw[i].distance_squared_to(raw[0]) > raw[far].distance_squared_to(raw[0]):
				far = i
		var one := PackedVector2Array()
		for i in range(0, far + 1):
			one.append(raw[i])
		var two := PackedVector2Array()
		for i in range(far, raw.size()):
			two.append(raw[i])
		two.append(raw[0])
		var out := _dp(one, tol)
		out.resize(out.size() - 1)
		var rest := _dp(two, tol)
		rest.resize(rest.size() - 1)
		out.append_array(rest)
		var a := absf(area(out))
		if out.size() >= 3 and a > raw_area * 0.8 and a < raw_area * 1.2 and _simple(out):
			return out
	return raw


static func _dp(pts: PackedVector2Array, tol: float) -> PackedVector2Array:
	if pts.size() < 3:
		return pts
	var a := pts[0]
	var b := pts[pts.size() - 1]
	var worst := -1.0
	var at := 0
	for i in range(1, pts.size() - 1):
		var d := Geometry2D.get_closest_point_to_segment(pts[i], a, b).distance_to(pts[i])
		if d > worst:
			worst = d
			at = i
	if worst <= tol:
		return PackedVector2Array([a, b])
	var left := _dp(pts.slice(0, at + 1), tol)
	var right := _dp(pts.slice(at), tol)
	left.resize(left.size() - 1)
	left.append_array(right)
	return left


static func _simple(poly: PackedVector2Array) -> bool:
	var n := poly.size()
	for i in n:
		for j in range(i + 2, n):
			if i == 0 and j == n - 1:
				continue
			if Geometry2D.segment_intersects_segment(poly[i], poly[(i + 1) % n], poly[j], poly[(j + 1) % n]) != null:
				return false
	return true


# --- Classes ---------------------------------------------------------------------------------

func _classify(i: int, rng: RandomNumberGenerator) -> void:
	var il: Dictionary = ilots[i]
	var c: Vector2 = il.centre
	var cls := "rue"
	var to_core := minf(c.distance_to(_core[0]), c.distance_to(_core[1]))
	if c.distance_to(_marche) > Config.CITY_FAUBOURG:
		cls = "faubourg"
		if rng.randf() < Config.CITY_POSTWAR_EDGE:
			cls = "postwar"
	elif to_core < Config.CITY_CORE_RADIUS:
		cls = "core"
	# Rebuilt after the war: round the hospital, and round the bus station on the side away from
	# the market.
	if c.distance_to(_postwar[0]) < Config.CITY_POSTWAR_NEAR.x or (c.distance_to(_postwar[1]) < Config.CITY_POSTWAR_NEAR.y
			and c.distance_to(_marche) > Config.CITY_MARCHE_KEEP):
		cls = "postwar"
	il.cls = cls
	il.silhouette = not _map._in_detail(c)


## What lies outside an outline's edge: [cell type, street kind].
func _facing(mid: Vector2, out: Vector2) -> Array:
	for d: float in [2.5, 5.0]:
		var p := mid + out * d
		var c := floori((p.x - _map.lo.x) / _map.cell)
		var r := floori((p.y - _map.lo.y) / _map.cell)
		if c < 0 or r < 0 or c >= _map.gw or r >= _map.gh:
			return [CityMap.OUT, 0]
		var i := r * _map.gw + c
		var t := _map.grid[i]
		if t != CityMap.BLOCK:
			return [t, _skind[i]]
	return [CityMap.BLOCK, 0]


static func _open_type(t: int) -> bool:
	return t == CityMap.STREET or t == CityMap.SQUARE or t == CityMap.WATER or t == CityMap.PARK or t == CityMap.LOT


func _river_distance(p: Vector2) -> float:
	var d := INF
	for i in _river.size() - 1:
		d = minf(d, Geometry2D.get_closest_point_to_segment(p, _river[i], _river[i + 1]).distance_to(p))
	return d


## How far the block goes in from `p` along `inward` before it ends (metres, up to 80). The
## straightened outline may lie a little outside the block's cells: those first metres count.
func _reach(p: Vector2, inward: Vector2, ilot: int) -> float:
	var d := 0.5
	var entered := false
	while d < 80.0:
		var q := p + inward * d
		var c := floori((q.x - _map.lo.x) / _map.cell)
		var r := floori((q.y - _map.lo.y) / _map.cell)
		var inside := c >= 0 and r >= 0 and c < _map.gw and r < _map.gh and _labels[r * _map.gw + c] == ilot
		if inside:
			entered = true
		elif entered or d > _map.cell * 1.5:
			return d
		d += 1.0
	return d


# --- Rows of houses --------------------------------------------------------------------------

## The houses along every edge of an îlot, a corner house at every convex corner.
func _rows(k: int, rng: RandomNumberGenerator) -> void:
	var il: Dictionary = ilots[k]
	var poly: PackedVector2Array = il.outline
	var n := poly.size()
	var straight := cos(deg_to_rad(Config.CITY_STRAIGHT_DEG))
	# Per edge: direction, length, inward normal, what it faces, class, depth.
	var e: Array = []
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var length := a.distance_to(b)
		var u := (b - a) / maxf(length, 0.001)
		var inward := Vector2(-u.y, u.x)
		var mid := (a + b) * 0.5
		var facing := _facing(mid, -inward)
		var cls: String = il.cls
		if int(facing[1]) == 2 and cls != "postwar":
			cls = "main"
		elif cls != "core" and cls != "postwar" and _river_distance(mid) < Config.CITY_ATELIER_RIVER \
				and rng.randf() < Config.CITY_ATELIER_SHARE:
			cls = "atelier"
		var spec: Dictionary = CLASSES[cls]
		var reach := minf(minf(_reach(a.lerp(b, 0.25), inward, k), _reach(mid, inward, k)), _reach(a.lerp(b, 0.75), inward, k))
		var depth := minf(rng.randf_range(spec.depth[0], spec.depth[1]), maxf(2.5, reach * 0.5))
		var open := _open_type(int(facing[0]))
		if open:
			il.street_edge += length
		e.append({ "a": a, "b": b, "u": u, "in": inward, "len": length, "cls": cls, "depth": depth,
			"reach": reach, "open": open, "street": int(facing[0]) == CityMap.STREET, "s0": 0.0, "s1": length })
	# Corners: where the outline turns left by more than CITY_STRAIGHT_DEG, a corner house out to
	# where the two rows' backs meet, shrunk to fit short edges.
	var corners: Array = []
	for i in n:
		var p: Dictionary = e[(i - 1 + n) % n]
		var q: Dictionary = e[i]
		var u1: Vector2 = p.u
		var u2: Vector2 = q.u
		if u1.cross(u2) <= 0.0 or u1.dot(u2) > straight:
			corners.append(null)
			continue
		var depth := minf(p.depth, q.depth)
		var v := poly[i]
		var hit: Variant = Geometry2D.line_intersects_line(v + (p.in as Vector2) * depth, u1, v + (q.in as Vector2) * depth, u2)
		if hit == null:
			corners.append(null)
			continue
		var t1 := -((hit as Vector2) - v).dot(u1)
		var t2 := ((hit as Vector2) - v).dot(u2)
		if t1 <= 0.1 or t2 <= 0.1:
			corners.append(null)
			continue
		corners.append({ "v": v, "t1": t1, "t2": t2, "depth": depth, "p": (i - 1 + n) % n, "q": i })
	# An edge holds at most half of each of its corners.
	for i in n:
		var c: Variant = corners[i]
		if c == null:
			continue
		var f := minf(1.0, minf(float(e[c.p].len) * 0.5 / float(c.t1), float(e[c.q].len) * 0.5 / float(c.t2)))
		c.t1 *= f
		c.t2 *= f
		c.depth *= f
		e[c.p].s1 = float(e[c.p].len) - float(c.t1)
		e[c.q].s0 = float(c.t2)
	for i in n:
		var c: Variant = corners[i]
		if c == null:
			continue
		var p: Dictionary = e[c.p]
		var q: Dictionary = e[c.q]
		var v: Vector2 = c.v
		var a1: Vector2 = v - (p.u as Vector2) * float(c.t1)
		var a2: Vector2 = v + (q.u as Vector2) * float(c.t2)
		var hit: Variant = Geometry2D.line_intersects_line(v + (p.in as Vector2) * float(c.depth), p.u, v + (q.in as Vector2) * float(c.depth), q.u)
		var inner: Vector2 = hit if hit != null else (a1 + a2) * 0.5
		var cls: String = p.cls if RANK.get(p.cls, 0) >= RANK.get(q.cls, 0) else q.cls
		if cls == "atelier":
			cls = "rue"
		var h := _house(PackedVector2Array([a1, v, a2, inner]), "corner", cls, k, rng)
		h.width = float(c.t1) + float(c.t2)
		h.out = -((p.in as Vector2) + (q.in as Vector2)).normalized()
		h.faces_street = p.street or q.street
		if p.open:
			il.fronted += float(c.t1)
		if q.open:
			il.fronted += float(c.t2)
	for i in n:
		_row(k, e[i], rng)
	_row_floors = -1


## One edge's run of houses from s0 to s1, in widths of whole bays.
func _row(k: int, edge: Dictionary, rng: RandomNumberGenerator) -> void:
	var il: Dictionary = ilots[k]
	var s0: float = edge.s0
	var s1: float = edge.s1
	if s1 - s0 < 0.5:
		return
	var cls: String = edge.cls
	var spec: Dictionary = CLASSES[cls]
	var a: Vector2 = edge.a
	var u: Vector2 = edge.u
	var inward: Vector2 = edge.in
	var depth: float = edge.depth
	# An hôtel particulier: a gate wall on the street, a court, the house behind it.
	var hotel := Vector2(-1, -1)
	if cls in ["core", "rue", "main"] and s1 - s0 > Config.CITY_HOTEL_ROW + 10.0 and float(edge.reach) > Config.CITY_HOTEL_ROW * 1.2 \
			and rng.randf() < Config.CITY_HOTEL_SHARE * (s1 - s0) / 40.0:
		var w := rng.randf_range(Config.CITY_HOTEL_ROW * 0.7, Config.CITY_HOTEL_ROW)
		var at := rng.randf_range(s0 + 5.0, s1 - 5.0 - w)
		hotel = Vector2(at, at + w)
	var widths := _widths(s1 - s0, spec, rng)
	_row_floors = rng.randi_range(spec.floors[0], spec.floors[1])
	var s := s0
	for w: float in widths:
		var lo := s
		var hi := s + w
		s = hi
		if hotel.x >= 0.0 and hi > hotel.x and lo < hotel.y:
			if lo <= hotel.x: # the first house the hôtel's plot touches gives way to it
				if hotel.x - lo > 2.0:
					_front_house(k, edge, lo, hotel.x, cls, rng)
				_hotel(k, edge, hotel.x, hotel.y, rng)
			if hi > hotel.y and hi - hotel.y > 2.0:
				_front_house(k, edge, hotel.y, hi, cls, rng)
			continue
		if rng.randf() < float(spec.gap):
			_wall(k, a + u * lo, a + u * hi, GARDEN_WALL, false, edge.open)
			continue
		_front_house(k, edge, lo, hi, cls, rng)


## Widths that fill `length`: whole bays (or metres for slabs and halls); a leftover under the
## narrowest house goes to the last one.
func _widths(length: float, spec: Dictionary, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	var bay := rng.randf_range(Config.CITY_BAY.x, Config.CITY_BAY.y)
	var least: float
	var most: float
	if spec.has("bays"):
		least = spec.bays[0] * bay
		most = spec.bays[1] * bay
	else:
		least = spec.width[0]
		most = spec.width[1]
	var left := length
	while left > 0.01:
		var w: float
		if spec.has("bays"):
			w = rng.randi_range(spec.bays[0], spec.bays[1]) * bay
		else:
			w = rng.randf_range(least, most)
		if left - w < least * 0.5:
			w = left if left <= most + 2.0 else left * 0.5
		out.append(w)
		left -= w
	return out


func _front_house(k: int, edge: Dictionary, lo: float, hi: float, cls: String, rng: RandomNumberGenerator) -> void:
	var a: Vector2 = edge.a
	var u: Vector2 = edge.u
	var inward: Vector2 = edge.in
	var depth: float = edge.depth
	var fa := a + u * lo
	var fb := a + u * hi
	var h := _house(PackedVector2Array([fa, fb, fb + inward * depth, fa + inward * depth]), "row", cls, k, rng)
	h.width = hi - lo
	h.out = -inward
	h.faces_street = edge.street
	if edge.open:
		ilots[k].fronted += hi - lo
	# A wing behind it across a narrow court, where the block is deep enough (the Turgot plan's
	# courts are full of them).
	var court := rng.randf_range(WING_COURT.x, WING_COURT.y)
	var wing := rng.randf_range(WING_DEPTH.x, WING_DEPTH.y)
	if rng.randf() < float(CLASSES[cls].get("wing", 0.0)) and float(edge.reach) * 0.5 >= depth + court + wing:
		var narrow := rng.randf_range(0.0, 0.2) * (hi - lo)
		var wa := fa + u * narrow * 0.5 + inward * (depth + court)
		var wb := fb - u * narrow * 0.5 + inward * (depth + court)
		var w := _house(PackedVector2Array([wa, wb, wb + inward * wing, wa + inward * wing]), "wing", "back", k, rng)
		w.floors = maxi(2, int(h.floors) - rng.randi_range(0, 1))
		w.eave = float(h.eave) * float(w.floors) / float(h.floors)
		w.roof = "gable"
		w.pitch = rng.randf_range(WING_PITCH.x, WING_PITCH.y)
		w.width = hi - lo - narrow
		w.out = -inward


func _hotel(k: int, edge: Dictionary, lo: float, hi: float, rng: RandomNumberGenerator) -> void:
	var a: Vector2 = edge.a
	var u: Vector2 = edge.u
	var inward: Vector2 = edge.in
	var fa := a + u * lo
	var fb := a + u * hi
	var mid := (lo + hi) * 0.5
	_wall(k, fa, a + u * (mid - GATE * 0.5), GATE_WALL, false, edge.open)
	_wall(k, a + u * (mid - GATE * 0.5), a + u * (mid + GATE * 0.5), GATE_WALL, true, edge.open)
	_wall(k, a + u * (mid + GATE * 0.5), fb, GATE_WALL, false, edge.open)
	var court := rng.randf_range(COURT.x, COURT.y)
	var depth := rng.randf_range(CLASSES.hotel.depth[0], CLASSES.hotel.depth[1])
	var ha := fa + u * 1.0 + inward * court
	var hb := fb - u * 1.0 + inward * court
	var h := _house(PackedVector2Array([ha, hb, hb + inward * depth, ha + inward * depth]), "hotel", "hotel", k, rng)
	h.width = hi - lo - 2.0
	h.out = -inward
	_hotel_plots.append(PackedVector2Array([fa, fb, fb + inward * (court + depth + 4.0), fa + inward * (court + depth + 4.0)]))


func _wall(k: int, a: Vector2, b: Vector2, height: float, gate: bool, open: bool) -> void:
	walls.append({ "a": a, "b": b, "height": height, "gate": gate, "ilot": k })
	if open:
		ilots[k].fronted += a.distance_to(b)


## An îlot too small for a row: one building over all of it.
func _small(k: int, rng: RandomNumberGenerator) -> void:
	var il: Dictionary = ilots[k]
	var foot: PackedVector2Array = Geometry2D.convex_hull(il.outline)
	foot.resize(foot.size() - 1)
	if area(foot) < 0.0:
		foot.reverse()
	var cls: String = il.cls
	if cls == "atelier":
		cls = "rue"
	var h := _house(foot, "small", cls, k, rng)
	if h.roof == "gable" or h.roof == "sawtooth":
		h.roof = "hip"
	h.width = sqrt(il.area)
	h.out = Vector2.ZERO
	il.street_edge = 0.0


## A house's height, roof and colours from its class.
func _house(foot: PackedVector2Array, shape: String, cls: String, k: int, rng: RandomNumberGenerator) -> Dictionary:
	var spec: Dictionary = CLASSES[cls]
	var floors := rng.randi_range(spec.floors[0], spec.floors[1])
	if shape == "row" and _row_floors > 0: # neighbours differ by a floor at most, as in Marville's streets
		floors = clampi(_row_floors + [-1, 0, 0, 1][rng.randi() % 4], spec.floors[0], spec.floors[1])
	if cls == "main" and (ilots[k].centre as Vector2).distance_to(_marche) > Config.CITY_FAUBOURG:
		floors = rng.randi_range(MAIN_FAUBOURG_FLOORS[0], MAIN_FAUBOURG_FLOORS[1])
	var storey: float = spec.get("storey", rng.randf_range(Config.CITY_STOREY.x, Config.CITY_STOREY.y))
	var roof: String = spec.roof
	if shape != "row" and shape != "wing" and roof == "gable":
		roof = "hip"
	if shape == "corner" and roof == "sawtooth":
		roof = "flat"
	var tile := rng.randf() < float(spec.tile)
	var roof_colour: Color = TILES[rng.randi() % TILES.size()] if tile else SLATE[rng.randi() % SLATE.size()]
	if roof == "flat":
		roof_colour = TAR
	elif roof == "sawtooth":
		roof_colour = SLATE[0].darkened(0.2)
	var lean := Vector2.ZERO
	if spec.has("lean") and shape == "row":
		lean = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * float(spec.lean)
	var wall: Color = PLASTER[rng.randi() % PLASTER.size()].darkened(rng.randf_range(0.0, 0.18))
	if cls == "hotel":
		wall = STONE.lightened(0.25)
	var h := { "foot": foot, "shape": shape, "cls": cls, "floors": floors, "eave": floors * storey,
		"roof": roof, "pitch": rng.randf_range(spec.pitch[0], spec.pitch[1]), "roof_colour": roof_colour,
		"wall": wall, "plinth": bool(spec.get("plinth", false)), "width": 0.0, "out": Vector2.ZERO, "lean": lean,
		"faces_street": false, "ilot": k, "lit": rng.randf() < Config.CITY_LIT_SHARE, "lit_at": rng.randf() }
	houses.append(h)
	return h


## Back buildings and halls in the courts: the traced footprints (CityOsm) that lie inside an îlot,
## clear of its front rows and of the hôtels' courts.
func _backs() -> void:
	var taken := PackedByteArray()
	taken.resize(_map.gw * _map.gh)
	paint_floors(taken)
	for fp: Array in CityOsm.BUILDINGS:
		if float(fp[1]) < Config.CITY_BACK_MIN:
			continue
		var c := CityData.to_plan(fp[2])
		var col := floori((c.x - _map.lo.x) / _map.cell)
		var row := floori((c.y - _map.lo.y) / _map.cell)
		if col < 0 or row < 0 or col >= _map.gw or row >= _map.gh:
			continue
		var k := _labels[row * _map.gw + col]
		if k < 0 or ilots[k].area < Config.CITY_ILOT_SMALL:
			continue
		var foot := PackedVector2Array()
		for p: Vector2 in fp[0]:
			foot.append(CityData.to_plan(p))
		if area(foot) < 0.0:
			foot.reverse()
		var outline: PackedVector2Array = ilots[k].outline
		var clear := not _taken(c, taken)
		for p in foot:
			if not Geometry2D.is_point_in_polygon(p, outline) or _edge_distance(p, outline) < 9.0 or _taken(p, taken):
				clear = false
				break
		for plot: PackedVector2Array in _hotel_plots:
			if Geometry2D.is_point_in_polygon(c, plot):
				clear = false
		if not clear:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([18510309, "back", fp[2]])
		var h := _house(foot, "back", "back", k, rng)
		if float(fp[1]) > Config.CITY_HALL_AREA:
			h.floors = 2
			h.eave = 2 * HALL_STOREY
			h.pitch = HALL_PITCH
		elif ilots[k].cls == "core":
			h.floors = mini(int(h.floors) + 1, 5)
			h.eave = float(h.floors) * Config.CITY_STOREY.x
		h.width = sqrt(float(fp[1]))


func _taken(p: Vector2, taken: PackedByteArray) -> bool:
	var c := floori((p.x - _map.lo.x) / _map.cell)
	var r := floori((p.y - _map.lo.y) / _map.cell)
	return c >= 0 and r >= 0 and c < _map.gw and r < _map.gh and taken[r * _map.gw + c] > 0


## What the traced footprints leave empty in a deep court: a back building every COURT_STEP metres
## or so (sheds, workshops, a stable), seeded, the rest garden or paving.
func _fill_courts() -> void:
	var taken := PackedByteArray()
	taken.resize(_map.gw * _map.gh)
	paint_floors(taken)
	for k in ilots.size():
		var il: Dictionary = ilots[k]
		var share: float = COURT_FILL.get(il.cls, 0.0)
		if share <= 0.0 or il.area < Config.CITY_ILOT_SMALL * 10.0:
			continue
		var poly: PackedVector2Array = il.outline
		var axis := Vector2.RIGHT
		var longest := 0.0
		for i in poly.size():
			var d := poly[(i + 1) % poly.size()] - poly[i]
			if d.length() > longest:
				longest = d.length()
				axis = d.normalized()
		var across := Vector2(-axis.y, axis.x)
		var box := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			box = box.expand(p)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([18510309, "court", k])
		var c0 := box.get_center()
		var reach := box.size.length() * 0.5
		var a := -reach
		while a < reach:
			var b := -reach
			while b < reach:
				var at := c0 + axis * (a + rng.randf_range(-0.35, 0.35) * COURT_STEP) + across * (b + rng.randf_range(-0.35, 0.35) * COURT_STEP)
				b += COURT_STEP
				if not Geometry2D.is_point_in_polygon(at, poly) or _edge_distance(at, poly) < COURT_CLEAR or rng.randf() > share:
					continue
				var half := Vector2(rng.randf_range(COURT_SHED.x, COURT_SHED.y), rng.randf_range(COURT_SHED.x, COURT_SHED.y) * 0.75) * 0.5
				var foot := PackedVector2Array([at - axis * half.x - across * half.y, at + axis * half.x - across * half.y,
					at + axis * half.x + across * half.y, at - axis * half.x + across * half.y])
				var free := true
				for p in foot:
					if _taken(p, taken) or not Geometry2D.is_point_in_polygon(p, poly):
						free = false
						break
				if not free or _taken(at, taken):
					continue
				var h := _house(foot, "back", "back", k, rng)
				h.floors = rng.randi_range(1, 3)
				h.eave = float(h.floors) * Config.CITY_STOREY.x
				h.width = half.x * 2.0
				for p in [at] + Array(foot):
					var col := floori((p.x - _map.lo.x) / _map.cell)
					var row := floori((p.y - _map.lo.y) / _map.cell)
					taken[row * _map.gw + col] = 1
			a += COURT_STEP


static func _edge_distance(p: Vector2, poly: PackedVector2Array) -> float:
	var d := INF
	for i in poly.size():
		d = minf(d, Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()]).distance_to(p))
	return d


# --- Questions --------------------------------------------------------------------------------

## Signed area of a polygon (x, z): positive when it turns the way every outline here does.
static func area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		a += poly[i].cross(poly[(i + 1) % poly.size()])
	return a * 0.5


static func _centroid(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for p in poly:
		c += p
	return c / maxf(1.0, poly.size())


func _plan(points: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in points:
		out.append(CityData.to_plan(p))
	return out


func layout_hash() -> int:
	var parts: Array = [ilots.size(), walls.size()]
	for h: Dictionary in houses:
		parts.append(hash([h.foot, h.floors, h.roof, h.cls]))
	return hash(parts)


## A house fronting a street, in an îlot built in detail: for tests.
func front_sample() -> Dictionary:
	for h: Dictionary in houses:
		if h.shape == "row" and h.faces_street and float(h.width) > 5.0 and not ilots[h.ilot].silhouette:
			return h
	return {}


## Storeys over every cell a house stands on (the plan picture's shading).
func paint_floors(floors: PackedByteArray) -> void:
	var lo := _map.lo
	var cell := _map.cell
	for h: Dictionary in houses:
		var foot: PackedVector2Array = h.foot
		var box := Rect2(foot[0], Vector2.ZERO)
		for p in foot:
			box = box.expand(p)
		for r in range(maxi(0, floori((box.position.y - lo.y) / cell)), mini(_map.gh - 1, floori((box.end.y - lo.y) / cell)) + 1):
			for c in range(maxi(0, floori((box.position.x - lo.x) / cell)), mini(_map.gw - 1, floori((box.end.x - lo.x) / cell)) + 1):
				if Geometry2D.is_point_in_polygon(lo + Vector2(c + 0.5, r + 0.5) * cell, foot):
					floors[r * _map.gw + c] = maxi(floors[r * _map.gw + c], int(h.floors))


# --- Building it -------------------------------------------------------------------------------

## Walls and roofs into `b`, lit windows into `glow`, courts into `ground`, one collision shape
## per îlot into `body`.
func build(b: MeshKit.Builder, ground: MeshKit.Builder, glow: MeshKit.Builder, body: StaticBody3D) -> void:
	var faces: Array = []
	faces.resize(ilots.size())
	for k in ilots.size():
		faces[k] = PackedVector3Array()
	var start := b.count
	var eaves: Array = []
	eaves.resize(ilots.size())
	for k in ilots.size():
		eaves[k] = []
	for h: Dictionary in houses:
		eaves[h.ilot].append(float(h.eave))
		if ilots[h.ilot].silhouette:
			continue
		_house_mesh(b, h)
		if h.lit and int(h.floors) > 1 and h.shape == "row" and h.faces_street:
			_lit(glow, h)
		if h.shape == "row" or h.shape == "corner" or h.shape == "small":
			_front_faces(faces[h.ilot], h)
	for w: Dictionary in walls:
		if ilots[w.ilot].silhouette:
			continue
		_wall_mesh(b, w)
		_quad_faces(faces[w.ilot], w.a, w.b, float(w.height))
	for k in ilots.size():
		var il: Dictionary = ilots[k]
		var e: Array = eaves[k]
		e.sort()
		il.eave = float(e[e.size() / 2]) if not e.is_empty() else 3.0 * Config.CITY_FLOOR_H
		if il.silhouette:
			_silhouette(b, il, faces[k])
		else:
			_court(ground, il)
		var f: PackedVector3Array = faces[k]
		if f.is_empty():
			continue
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(f)
		var cs := CollisionShape3D.new()
		cs.shape = shape
		Surface.tag(cs, Surface.Kind.BRICK)
		body.add_child(cs)
		built_ilots += 1
	triangles = b.count - start


func _v(p: Vector2, y: float, h: Dictionary) -> Vector3:
	var lean: Vector2 = h.lean
	var f := y / maxf(1.0, float(h.eave))
	return Vector3(p.x + lean.x * f, y, p.y + lean.y * f)


## A face of any number of points (a fan), lit by its own normal turned toward `hint`.
func _face(b: MeshKit.Builder, pts: Array, colour: Color, hint: Vector3) -> void:
	var n := Vector3.ZERO
	for i in range(1, pts.size() - 1):
		n += ((pts[i] as Vector3) - pts[0]).cross((pts[i + 1] as Vector3) - pts[0])
	if n.length_squared() < 1e-8:
		return
	n = n.normalized()
	if n.dot(hint) < 0.0:
		n = -n
	for i in range(1, pts.size() - 1):
		b._tri(pts[0], pts[i], pts[i + 1], n, colour)


func _house_mesh(b: MeshKit.Builder, h: Dictionary) -> void:
	var foot: PackedVector2Array = h.foot
	var eave: float = h.eave
	var wall: Color = h.wall
	var c := _centroid(foot)
	var n := foot.size()
	for i in n:
		var p := foot[i]
		var q := foot[(i + 1) % n]
		var out := Vector2(q.y - p.y, p.x - q.x).normalized()
		if out.dot((p + q) * 0.5 - c) < 0.0:
			out = -out
		var hint := Vector3(out.x, 0, out.y)
		var front: bool = (h.shape == "row" and i == 0) or (h.shape == "corner" and i < 2)
		if h.plinth and front and eave > PLINTH + 1.0:
			_face(b, [_v(p, 0.0, h), _v(q, 0.0, h), _v(q, PLINTH, h), _v(p, PLINTH, h)], STONE, hint)
			_face(b, [_v(p, PLINTH, h), _v(q, PLINTH, h), _v(q, eave, h), _v(p, eave, h)], wall, hint)
		else:
			_face(b, [_v(p, 0.0, h), _v(q, 0.0, h), _v(q, eave, h), _v(p, eave, h)], wall if front or h.shape != "row" else wall.darkened(0.12), hint)
	match h.roof:
		"gable":
			_gable(b, h)
		"mansard":
			if h.shape == "row":
				_mansard(b, h)
			else:
				_mansard_hip(b, h)
		"hip":
			_hip(b, h, foot, eave, float(h.pitch), h.roof_colour)
		"sawtooth":
			_sawtooth(b, h)
		_:
			_flat(b, h, foot, eave, h.roof_colour)


## Ridge along the street, a gable on each party wall.
func _gable(b: MeshKit.Builder, h: Dictionary) -> void:
	var f: PackedVector2Array = h.foot
	var eave: float = h.eave
	var depth := (f[0].distance_to(f[3]) + f[1].distance_to(f[2])) * 0.5
	var top := eave + minf(depth * 0.5 * tan(deg_to_rad(float(h.pitch))), GABLE_RISE_MAX)
	var ra := (f[0] + f[3]) * 0.5
	var rb := (f[1] + f[2]) * 0.5
	var col: Color = h.roof_colour
	var out: Vector2 = h.out
	_face(b, [_v(f[0], eave, h), _v(f[1], eave, h), _v(rb, top, h), _v(ra, top, h)], col, Vector3(out.x, 1, out.y))
	_face(b, [_v(f[3], eave, h), _v(f[2], eave, h), _v(rb, top, h), _v(ra, top, h)], col.darkened(0.08), Vector3(-out.x, 1, -out.y))
	var side := (f[1] - f[0]).normalized()
	_face(b, [_v(f[1], eave, h), _v(f[2], eave, h), _v(rb, top, h)], h.wall, Vector3(side.x, 0, side.y))
	_face(b, [_v(f[0], eave, h), _v(f[3], eave, h), _v(ra, top, h)], h.wall, Vector3(-side.x, 0, -side.y))


## A steep slate slope front and back, a shallow zinc top, the party walls up to it.
func _mansard(b: MeshKit.Builder, h: Dictionary) -> void:
	var f: PackedVector2Array = h.foot
	var eave: float = h.eave
	var inset := MANSARD_RISE / tan(deg_to_rad(float(h.pitch)))
	var da := (f[3] - f[0]).normalized()
	var db := (f[2] - f[1]).normalized()
	var depth := (f[0].distance_to(f[3]) + f[1].distance_to(f[2])) * 0.5
	inset = minf(inset, depth * 0.3)
	var ia := f[0] + da * inset
	var ib := f[1] + db * inset
	var ja := f[3] - da * inset
	var jb := f[2] - db * inset
	var ra := (f[0] + f[3]) * 0.5
	var rb := (f[1] + f[2]) * 0.5
	var y1 := eave + MANSARD_RISE
	var top := y1 + maxf(0.2, depth * 0.5 - inset) * tan(deg_to_rad(MANSARD_TOP))
	var out: Vector2 = h.out
	var slate: Color = h.roof_colour
	_face(b, [_v(f[0], eave, h), _v(f[1], eave, h), _v(ib, y1, h), _v(ia, y1, h)], slate, Vector3(out.x, 0.3, out.y))
	_face(b, [_v(f[3], eave, h), _v(f[2], eave, h), _v(jb, y1, h), _v(ja, y1, h)], slate.darkened(0.08), Vector3(-out.x, 0.3, -out.y))
	_face(b, [_v(ia, y1, h), _v(ib, y1, h), _v(rb, top, h), _v(ra, top, h)], ZINC, Vector3(out.x, 1, out.y))
	_face(b, [_v(ja, y1, h), _v(jb, y1, h), _v(rb, top, h), _v(ra, top, h)], ZINC.darkened(0.08), Vector3(-out.x, 1, -out.y))
	var side := (f[1] - f[0]).normalized()
	_face(b, [_v(f[1], eave, h), _v(ib, y1, h), _v(rb, top, h), _v(jb, y1, h), _v(f[2], eave, h)], h.wall, Vector3(side.x, 0, side.y))
	_face(b, [_v(f[0], eave, h), _v(ia, y1, h), _v(ra, top, h), _v(ja, y1, h), _v(f[3], eave, h)], h.wall, Vector3(-side.x, 0, -side.y))


## A mansard all round (corner houses, hôtels): the steep band, then a low hip.
func _mansard_hip(b: MeshKit.Builder, h: Dictionary) -> void:
	var f: PackedVector2Array = h.foot
	var eave: float = h.eave
	var c := _centroid(f)
	var r := _edge_distance(c, f)
	var inset := minf(MANSARD_RISE / tan(deg_to_rad(float(h.pitch))), r * 0.4)
	var k := 1.0 - inset / maxf(r, 0.01)
	var inner := PackedVector2Array()
	for p in f:
		inner.append(c + (p - c) * k)
	var y1 := eave + MANSARD_RISE
	for i in f.size():
		var j := (i + 1) % f.size()
		var mid := (f[i] + f[j]) * 0.5 - c
		_face(b, [_v(f[i], eave, h), _v(f[j], eave, h), _v(inner[j], y1, h), _v(inner[i], y1, h)], h.roof_colour, Vector3(mid.x, 0.3, mid.y))
	_hip(b, h, inner, y1, MANSARD_TOP, ZINC)


## Every side slopes up to a ridge along the footprint's long axis (a point for a square one).
func _hip(b: MeshKit.Builder, h: Dictionary, foot: PackedVector2Array, eave: float, pitch: float, colour: Color) -> void:
	var c := _centroid(foot)
	# The long axis: the longest edge's direction.
	var axis := Vector2.RIGHT
	var longest := 0.0
	for i in foot.size():
		var d := foot[(i + 1) % foot.size()] - foot[i]
		if d.length() > longest:
			longest = d.length()
			axis = d.normalized()
	var across := Vector2(-axis.y, axis.x)
	var lo := INF
	var hi := -INF
	var wlo := INF
	var whi := -INF
	for p in foot:
		lo = minf(lo, (p - c).dot(axis))
		hi = maxf(hi, (p - c).dot(axis))
		wlo = minf(wlo, (p - c).dot(across))
		whi = maxf(whi, (p - c).dot(across))
	var half_w := (whi - wlo) * 0.5
	var centre := c + across * (whi + wlo) * 0.5 + axis * (hi + lo) * 0.5
	var run := maxf(0.0, (hi - lo) * 0.5 - half_w)
	var top := eave + minf(half_w * tan(deg_to_rad(pitch)), GABLE_RISE_MAX)
	var r0 := centre - axis * run
	var r1 := centre + axis * run
	var ends: Array = []
	for p in foot:
		ends.append(r1 if (p - centre).dot(axis) > 0.0 else r0)
	for i in foot.size():
		var j := (i + 1) % foot.size()
		var mid := (foot[i] + foot[j]) * 0.5 - centre
		var hint := Vector3(mid.x, maxf(0.5, mid.length()), mid.y)
		if ends[i] == ends[j]:
			_face(b, [_v(foot[i], eave, h), _v(foot[j], eave, h), _v(ends[i], top, h)], colour, hint)
		else:
			_face(b, [_v(foot[i], eave, h), _v(foot[j], eave, h), _v(ends[j], top, h), _v(ends[i], top, h)], colour, hint)


func _flat(b: MeshKit.Builder, h: Dictionary, foot: PackedVector2Array, eave: float, colour: Color) -> void:
	var pts: Array = []
	for p in foot:
		pts.append(_v(p, eave, h))
	_face(b, pts, colour, Vector3.UP)


## North-light teeth along the street: a slate slope up to a glass face, one every SAWTOOTH metres.
func _sawtooth(b: MeshKit.Builder, h: Dictionary) -> void:
	var f: PackedVector2Array = h.foot
	var eave: float = h.eave
	var teeth := maxi(1, roundi(float(h.width) / SAWTOOTH))
	var u := (f[1] - f[0]).normalized()
	var out: Vector2 = h.out
	for t in teeth:
		var k0 := float(t) / teeth
		var k1 := float(t + 1) / teeth
		var f0 := f[0].lerp(f[1], k0)
		var f1 := f[0].lerp(f[1], k1)
		var b0 := f[3].lerp(f[2], k0)
		var b1 := f[3].lerp(f[2], k1)
		var top := eave + SAWTOOTH_RISE
		_face(b, [_v(f0, eave, h), _v(b0, eave, h), _v(b1, top, h), _v(f1, top, h)], h.roof_colour, Vector3(-u.x, 1, -u.y))
		_face(b, [_v(f1, eave, h), _v(b1, eave, h), _v(b1, top, h), _v(f1, top, h)], GLASS, Vector3(u.x, 0, u.y))
		_face(b, [_v(f0, eave, h), _v(f1, eave, h), _v(f1, top, h)], h.wall, Vector3(out.x, 0, out.y))
		_face(b, [_v(b0, eave, h), _v(b1, eave, h), _v(b1, top, h)], h.wall, Vector3(-out.x, 0, -out.y))


func _wall_mesh(b: MeshKit.Builder, w: Dictionary) -> void:
	var a: Vector2 = w.a
	var e: Vector2 = w.b
	var length := a.distance_to(e)
	if length < 0.05:
		return
	var dir := (e - a) / length
	var basis := Basis(Vector3.UP, atan2(-dir.y, dir.x))
	var mid := (a + e) * 0.5
	var height: float = w.height
	if w.gate:
		var in2 := Vector2(-dir.y, dir.x)
		b.box(Vector3(length, height - 0.6, 0.12), Vector3(mid.x + in2.x * 0.15, (height - 0.6) * 0.5, mid.y + in2.y * 0.15), GATE_WOOD, basis)
		b.box(Vector3(length + 0.6, 0.6, 0.55), Vector3(mid.x, height - 0.3, mid.y), STONE, basis)
	else:
		b.box(Vector3(length, height, 0.45), Vector3(mid.x, height * 0.5, mid.y), STONE.darkened(0.1), basis)


## A window left lit on the front, on a seeded floor.
func _lit(glow: MeshKit.Builder, h: Dictionary) -> void:
	var f: PackedVector2Array = h.foot
	var out: Vector2 = h.out
	var floors: int = h.floors
	var storey: float = float(h.eave) / floors
	var at := f[0].lerp(f[1], 0.25 + 0.5 * float(h.lit_at)) + out * 0.06
	var y := (1 + floori(float(h.lit_at) * (floors - 1))) * storey + storey * 0.45
	var side := (f[1] - f[0]).normalized() * LIT.x * 0.5
	var n := Vector3(out.x, 0, out.y)
	glow._quad(_v(at - side, y - LIT.y * 0.5, h), _v(at + side, y - LIT.y * 0.5, h), _v(at + side, y + LIT.y * 0.5, h), _v(at - side, y + LIT.y * 0.5, h), n, Color.WHITE)


func _front_faces(f: PackedVector3Array, h: Dictionary) -> void:
	var foot: PackedVector2Array = h.foot
	match h.shape:
		"row":
			_quad_faces(f, foot[0], foot[1], h.eave)
		"corner":
			_quad_faces(f, foot[0], foot[1], h.eave)
			_quad_faces(f, foot[1], foot[2], h.eave)
		_:
			for i in foot.size():
				_quad_faces(f, foot[i], foot[(i + 1) % foot.size()], h.eave)


func _quad_faces(f: PackedVector3Array, a: Vector2, b: Vector2, height: float) -> void:
	var p := Vector3(a.x, -0.5, a.y)
	var q := Vector3(b.x, -0.5, b.y)
	var pt := Vector3(a.x, height, a.y)
	var qt := Vector3(b.x, height, b.y)
	f.append_array([p, q, qt, p, qt, pt])


## From afar: the outline raised to the houses' middle eave, a lid for the roofs.
func _silhouette(b: MeshKit.Builder, il: Dictionary, f: PackedVector3Array) -> void:
	var poly: PackedVector2Array = il.outline
	var top: float = float(il.eave) + SILHOUETTE_ROOF
	var colour: Color = PLASTER[int(il.index) % PLASTER.size()].darkened(0.1)
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		var out := Vector2((q - p).y, -(q - p).x).normalized()
		b._quad(Vector3(p.x, 0, p.y), Vector3(q.x, 0, q.y), Vector3(q.x, top, q.y), Vector3(p.x, top, p.y), Vector3(out.x, 0, out.y), colour)
		_quad_faces(f, p, q, top)
	var tris := Geometry2D.triangulate_polygon(poly)
	for t in range(0, tris.size(), 3):
		b._tri(Vector3(poly[tris[t]].x, top, poly[tris[t]].y), Vector3(poly[tris[t + 1]].x, top, poly[tris[t + 1]].y),
			Vector3(poly[tris[t + 2]].x, top, poly[tris[t + 2]].y), Vector3.UP, SLATE[1])


## The court's ground: paved in the centre, gardens at the edge of town.
func _court(ground: MeshKit.Builder, il: Dictionary) -> void:
	var poly: PackedVector2Array = il.outline
	var colour := COURT_GROUND if il.cls == "core" or il.cls == "postwar" else GARDEN
	var tris := Geometry2D.triangulate_polygon(poly)
	for t in range(0, tris.size(), 3):
		ground.ground_tri(Vector3(poly[tris[t]].x, 0.012, poly[tris[t]].y), Vector3(poly[tris[t + 1]].x, 0.012, poly[tris[t + 1]].y),
			Vector3(poly[tris[t + 2]].x, 0.012, poly[tris[t + 2]].y), colour)
