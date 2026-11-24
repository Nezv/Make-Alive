class_name StreetNet
extends RefCounted
## The town's streets as a graph with real junctions, and their surfaces as flat triangles in plan
## metres (x, z), ready to be built into meshes or drawn on a plan. No nodes.
##
## From CityData.STREETS (pixels of joinville.png): an end that lies within SNAP metres of another
## street joins it there, and streets that cross get a shared point; every shared point or end is a
## node, the stretches between are links. At each node the arms are sorted round it and, for the
## carriageway (ROAD) and for the building line (WALK, the pavements' outer edge), each pair of
## neighbouring arms meets at a corner cut by a chamfer: KERB_CUT at the kerb, PAN_COUPE at the
## houses (the pans coupés of French street corners). A T, a skewed cross and a bend all come out of
## the same rule.
## Links are strips with mitred joints, trimmed where the junction shape takes over.

const WALK := 0     ## pavement, out to the building line
const ROAD := 1     ## carriageway, kerb to kerb
const SNAP := 9.0   ## metres: an end this close to a street joins it
const STEP := 4.0   ## metres between a strip's cross-sections (they follow the ground on the hill)
const KERB_CUT := 2.5
const PAN_COUPE := 4.0
const MAX_TRIM := 40.0
const BUCKET := 16.0
const SEG_CELL := 32.0  ## metres: the squares segments are sorted into for joining
const WELD := 1.5       ## metres: points of the plan closer than this are one
const ARM_LOOK := 3.0   ## metres: an arm's direction is taken this far along it

var streets: Array = []   ## CityData entries
var specs: Array = []     ## CityData.spec of each
var lines: Array = []     ## per street: { pts: PackedVector2Array, f: PackedFloat32Array } after joining
var nodes: Array = []     ## { at: Vector2, arms: Array }
var links: Array = []     ## { street: int, pts, f, a: node, b: node }
var pieces: Array = []    ## { layer, surface: String, street: int (-1 a junction), node: int, tris: PackedVector2Array, box: Rect2 }

var _key_node := {}
var _corners: Array = []  ## per node: [{ sharp, inside }]
var _buckets := {}


func _init(street_data: Array) -> void:
	for s: Dictionary in street_data:
		streets.append(s)
		specs.append(CityData.spec(s))
		var pts := PackedVector2Array()
		var f := PackedFloat32Array()
		var narrow: Array = s.get("narrow", [])
		for i in (s.pts as Array).size():
			pts.append(CityData.to_plan(s.pts[i]))
			f.append(float(narrow[i]) if i < narrow.size() else 1.0)
		lines.append({ "pts": pts, "f": f })
	_join_ends()
	_weld()
	_split_crossings()
	_weld()
	_make_nodes()
	_make_links()
	for k in nodes.size():
		_junction(k)
	for i in links.size():
		_strips(i)


# --- Joining ---------------------------------------------------------------------------------

static func _key(p: Vector2) -> Vector2i:
	return Vector2i(roundi(p.x * 20.0), roundi(p.y * 20.0))


## Every segment of every street by the SEG_CELL squares it touches: [street, segment, ...] (flat).
func _segment_grid() -> Dictionary:
	var grid := {}
	for s in lines.size():
		var pts: PackedVector2Array = lines[s].pts
		for i in pts.size() - 1:
			var box := Rect2(pts[i], Vector2.ZERO).expand(pts[i + 1]).grow(SNAP)
			for x in range(floori(box.position.x / SEG_CELL), floori(box.end.x / SEG_CELL) + 1):
				for y in range(floori(box.position.y / SEG_CELL), floori(box.end.y / SEG_CELL) + 1):
					var key := Vector2i(x, y)
					if not grid.has(key):
						grid[key] = []
					(grid[key] as Array).append_array([s, i])
	return grid


## Ends that stop on (or just short of) another street are moved onto it, and a point is added there.
## Points of the street within SNAP of where its end now lies go: a traced end that ran past the
## other street would otherwise double back at the junction.
func _join_ends() -> void:
	var grid := _segment_grid()
	var moves := []  # [street, end, other street, point]
	for s in lines.size():
		for e in [0, -1]:
			var pts: PackedVector2Array = lines[s].pts
			var p := pts[e]
			var best := SNAP
			var hit := Vector2.INF
			var on := -1
			var near: Array = grid.get(Vector2i(floori(p.x / SEG_CELL), floori(p.y / SEG_CELL)), [])
			for n in range(0, near.size(), 2):
				var o: int = near[n]
				var i: int = near[n + 1]
				if o == s:
					continue
				var q: PackedVector2Array = lines[o].pts
				var c := Geometry2D.get_closest_point_to_segment(p, q[i], q[i + 1])
				var d := c.distance_to(p)
				if d < best - 0.01:
					best = d
					# prefer a point the other street already has
					if c.distance_to(q[i]) < 1.5:
						c = q[i]
					elif c.distance_to(q[i + 1]) < 1.5:
						c = q[i + 1]
					hit = c
					on = o
			if hit != Vector2.INF:
				moves.append([s, e, on, hit])
	for m: Array in moves:
		var s: int = m[0]
		var hit: Vector2 = m[3]
		var pts: PackedVector2Array = lines[s].pts
		var f: PackedFloat32Array = lines[s].f
		if m[1] == 0:
			pts[0] = hit
			while pts.size() > 2 and pts[1].distance_to(hit) < SNAP:
				pts.remove_at(1)
				f.remove_at(1)
		else:
			pts[-1] = hit
			while pts.size() > 2 and pts[-2].distance_to(hit) < SNAP:
				pts.remove_at(pts.size() - 2)
				f.remove_at(f.size() - 2)
		lines[s].pts = pts
		lines[s].f = f
	var adds := []  # [street, segment, point]: the segment found again, as points may have gone
	for m: Array in moves:
		var o: int = m[2]
		var hit: Vector2 = m[3]
		var q: PackedVector2Array = lines[o].pts
		var seg := 0
		var best := INF
		for i in q.size() - 1:
			var d := Geometry2D.get_closest_point_to_segment(hit, q[i], q[i + 1]).distance_to(hit)
			if d < best:
				best = d
				seg = i
		adds.append([o, seg, hit])
	_insert(adds)


## Points of different streets closer than WELD are one point (a traced junction is a little blurred),
## and a street never keeps two points that close in a row.
func _weld() -> void:
	var seen := {}  # cell -> [points]
	for s in lines.size():
		var pts: PackedVector2Array = lines[s].pts
		var f: PackedFloat32Array = lines[s].f
		var out := PackedVector2Array()
		var of := PackedFloat32Array()
		for i in pts.size():
			var p := pts[i]
			var c := Vector2i(floori(p.x / WELD), floori(p.y / WELD))
			var found := false
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					for q: Vector2 in seen.get(c + Vector2i(dx, dy), []):
						if not found and q.distance_to(p) < WELD:
							p = q
							found = true
			if not found:
				if not seen.has(c):
					seen[c] = []
				(seen[c] as Array).append(p)
			var last := i == pts.size() - 1
			if not out.is_empty() and out[-1].distance_to(p) < WELD:
				if last and out.size() > 1: # the end wins over the point before it
					out[-1] = p
				continue
			out.append(p)
			of.append(f[i])
		if out.size() < 2: # a street shorter than WELD: keep its ends
			out = PackedVector2Array([pts[0], pts[-1]])
			of = PackedFloat32Array([f[0], f[-1]])
		lines[s].pts = out
		lines[s].f = of


## Streets that cross share the crossing point.
func _split_crossings() -> void:
	var grid := _segment_grid()
	var adds := []
	var done := {}
	for key: Vector2i in grid:
		var list: Array = grid[key]
		for m in range(0, list.size(), 2):
			for n in range(m + 2, list.size(), 2):
				var s: int = list[m]
				var o: int = list[n]
				if s == o:
					continue
				var i: int = list[m + 1]
				var j: int = list[n + 1]
				if s > o:
					var t := s
					s = o
					o = t
					t = i
					i = j
					j = t
				var pair := Vector4i(s, i, o, j)
				if done.has(pair):
					continue
				done[pair] = true
				var a: PackedVector2Array = lines[s].pts
				var b: PackedVector2Array = lines[o].pts
				var x: Variant = Geometry2D.segment_intersects_segment(a[i], a[i + 1], b[j], b[j + 1])
				if x == null:
					continue
				var p: Vector2 = x
				# snap to a point either street already has
				for v: Vector2 in [a[i], a[i + 1], b[j], b[j + 1]]:
					if v.distance_to(p) < 1.0:
						p = v
				adds.append([s, i, p])
				adds.append([o, j, p])
	_insert(adds)


## Put each [street, segment, point] into its street, in order along the segment, once.
func _insert(adds: Array) -> void:
	var by_street := {}
	for a: Array in adds:
		if not by_street.has(a[0]):
			by_street[a[0]] = []
		by_street[a[0]].append(a)
	for s: int in by_street:
		var pts: PackedVector2Array = lines[s].pts
		var f: PackedFloat32Array = lines[s].f
		var out := PackedVector2Array()
		var of := PackedFloat32Array()
		for i in pts.size():
			if out.is_empty() or _key(out[-1]) != _key(pts[i]):
				out.append(pts[i])
				of.append(f[i])
			if i == pts.size() - 1:
				break
			var here := []
			for a: Array in by_street[s]:
				if a[1] == i:
					here.append(a[2])
			var a0 := pts[i]
			here.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.distance_squared_to(a0) < q.distance_squared_to(a0))
			var seg := pts[i].distance_to(pts[i + 1])
			for p: Vector2 in here:
				if _key(p) == _key(out[-1]) or _key(p) == _key(pts[i + 1]):
					continue
				out.append(p)
				of.append(lerpf(f[i], f[i + 1], p.distance_to(pts[i]) / maxf(seg, 0.001)))
		lines[s].pts = out
		lines[s].f = of


func _make_nodes() -> void:
	var count := {}
	for s in lines.size():
		var pts: PackedVector2Array = lines[s].pts
		for i in pts.size():
			var k := _key(pts[i])
			count[k] = int(count.get(k, 0)) + (2 if i == 0 or i == pts.size() - 1 else 1)
	for s in lines.size():
		var pts: PackedVector2Array = lines[s].pts
		for i in pts.size():
			var k := _key(pts[i])
			if count[k] >= 2 and not _key_node.has(k):
				_key_node[k] = nodes.size()
				nodes.append({ "at": pts[i], "arms": [] })


func _make_links() -> void:
	for s in lines.size():
		var pts: PackedVector2Array = lines[s].pts
		var f: PackedFloat32Array = lines[s].f
		var start := 0
		for i in range(1, pts.size()):
			if not _key_node.has(_key(pts[i])):
				continue
			var lp := pts.slice(start, i + 1)
			var lf := f.slice(start, i + 1)
			var a: int = _key_node[_key(pts[start])]
			var b: int = _key_node[_key(pts[i])]
			var id := links.size()
			links.append({ "street": s, "pts": lp, "f": lf, "a": a, "b": b })
			_arm(a, id, true)
			_arm(b, id, false)
			start = i
	for n: Dictionary in nodes:
		(n.arms as Array).sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return p.dir.angle() < q.dir.angle())


## One arm of a node: which way the link leaves it and how far its edges stand to each side. `right`
## is the side the arm's direction turns to at +90 degrees (the next arm round), `left` the other.
func _arm(node: int, link: int, at_start: bool) -> void:
	var l: Dictionary = links[link]
	var pts: PackedVector2Array = l.pts
	var f: PackedFloat32Array = l.f
	var sp: Dictionary = specs[l.street]
	var o := pts[0] if at_start else pts[-1]
	var dir := Vector2.ZERO
	for k in range(1, pts.size()):
		var q := pts[k] if at_start else pts[pts.size() - 1 - k]
		dir = (q - o).normalized()
		if q.distance_to(o) >= ARM_LOOK:
			break
	var fe := f[0] if at_start else f[-1]
	var road: float = sp.road * fe * 0.5
	var walk: Array = sp.walk
	# The link's left is its direction's orthogonal(); leaving from its end the sides swap.
	var w_right: float = walk[1] if at_start else walk[0]
	var w_left: float = walk[0] if at_start else walk[1]
	(nodes[node].arms as Array).append({ "link": link, "start": at_start, "street": l.street, "dir": dir,
		"road": road, "right": [road + w_right, road], "left": [road + w_left, road],
		"trim": [0.0, 0.0] })


# --- Junctions ---------------------------------------------------------------------------------

## The arm's edge line on one side: a point and the direction.
static func _edge(o: Vector2, arm: Dictionary, right: bool, level: int) -> Vector2:
	var n: Vector2 = (arm.dir as Vector2).rotated(PI * 0.5)
	return o + n * float(arm.right[level]) if right else o - n * float(arm.left[level])


func _junction(k: int) -> void:
	var node: Dictionary = nodes[k]
	var arms: Array = node.arms
	_corners.append([])
	if arms.size() < 2:
		return
	var o: Vector2 = node.at
	for level in [ROAD, WALK]:
		var cut := KERB_CUT if level == ROAD else PAN_COUPE
		var sectors := []
		for i in arms.size():
			var a: Dictionary = arms[i]
			var b: Dictionary = arms[(i + 1) % arms.size()]
			var da: Vector2 = a.dir
			var db: Vector2 = b.dir
			var theta := fposmod(db.angle() - da.angle(), TAU)
			if arms.size() == 2 and i == 1:
				theta = TAU - fposmod(arms[1].dir.angle() - arms[0].dir.angle(), TAU)
			var pa := _edge(o, a, true, level)
			var pb := _edge(o, b, false, level)
			var sec := { "convex": false, "s": 0.0, "t": 0.0, "pa": pa, "pb": pb }
			if theta < deg_to_rad(165.0):
				# pa + da*s = pb + db*t
				var w := pb - pa
				var det := da.cross(-db)
				if absf(det) > 1e-4:
					var s := w.cross(-db) / det
					var t := da.cross(w) / det
					if s > -0.5 and t > -0.5:
						sec.convex = true
						sec.s = clampf(s, 0.0, MAX_TRIM)
						sec.t = clampf(t, 0.0, MAX_TRIM)
						sec.sharp = pa + da * s
						sec.clamped = s > MAX_TRIM or t > MAX_TRIM
			sectors.append(sec)
		# Trims: each arm runs in until both its corners are behind it.
		for i in arms.size():
			var right: Dictionary = sectors[i]
			var left: Dictionary = sectors[(i - 1 + arms.size()) % arms.size()]
			var tr := 0.0
			if right.convex:
				tr = maxf(tr, float(right.s) + cut)
			if left.convex:
				tr = maxf(tr, float(left.t) + cut)
			arms[i].trim[level] = minf(tr, MAX_TRIM + cut)
		# The shape: round the arms, each arm's left and right edge at its trim, the cut corners between.
		var poly := PackedVector2Array()
		for i in arms.size():
			var a: Dictionary = arms[i]
			var j := (i + 1) % arms.size()
			var b: Dictionary = arms[j]
			var ta: float = a.trim[level]
			var tb: float = b.trim[level]
			var sec: Dictionary = sectors[i]
			poly.append(_edge(o, a, false, level) + a.dir * ta)
			poly.append(_edge(o, a, true, level) + a.dir * ta)
			if sec.convex:
				var ca: Vector2 = sec.pa + a.dir * minf(float(sec.s) + cut, ta)
				var cb: Vector2 = sec.pb + b.dir * minf(float(sec.t) + cut, tb)
				poly.append(ca)
				poly.append(cb)
				if level == ROAD and not sec.get("clamped", false) and float(sec.s) > 0.5 and float(sec.t) > 0.5:
					var mid := (ca + cb) * 0.5
					(_corners[k] as Array).append({ "sharp": sec.sharp, "beyond": mid + (mid - o).normalized() * 0.4 })
			else:
				poly.append(sec.pa)
				poly.append(sec.pb)
		_add_poly(level, _surface_at(k, level), -1, k, poly)
		# Each arm's own band from the node out to its trim: however skewed the junction, its
		# polygon and the strips leave no hole along any street.
		for arm: Dictionary in arms:
			var l: Dictionary = links[arm.link]
			var length := _length(l.pts)
			var tr: float = arm.trim[level]
			if tr <= 0.0:
				continue
			var t0 := 0.0 if arm.start else maxf(0.0, length - tr)
			var t1 := maxf(0.0, length - tr) if arm.start else 0.0
			_add(level, _surface_at(k, level), -1, k, _band(l, level, t0, t1))


func _surface_at(k: int, level: int) -> String:
	if level == WALK:
		return "flags"
	var best := -1.0
	var out := "setts"
	for arm: Dictionary in nodes[k].arms:
		if float(arm.road) > best:
			best = arm.road
			out = specs[arm.street].surface
	return out


func _add_poly(layer: int, surface: String, street: int, node: int, poly: PackedVector2Array) -> void:
	var tris := PackedVector2Array()
	var clean := PackedVector2Array()
	for p in poly:
		if clean.is_empty() or clean[-1].distance_to(p) > 0.05:
			clean.append(p)
	if clean.size() > 2 and clean[0].distance_to(clean[-1]) < 0.05:
		clean.remove_at(clean.size() - 1)
	if clean.size() < 3:
		return
	var idx := Geometry2D.triangulate_polygon(clean)
	if idx.is_empty():
		# Not a simple polygon (an awkward corner): a fan from the middle covers it.
		var mid := Vector2.ZERO
		for p in clean:
			mid += p / clean.size()
		for i in clean.size():
			tris.append_array([mid, clean[i], clean[(i + 1) % clean.size()]])
	else:
		for i in idx:
			tris.append(clean[i])
	_add(layer, surface, street, node, tris)


func _add(layer: int, surface: String, street: int, node: int, tris: PackedVector2Array) -> void:
	if tris.is_empty():
		return
	var box := Rect2(tris[0], Vector2.ZERO)
	for p in tris:
		box = box.expand(p)
	pieces.append({ "layer": layer, "surface": surface, "street": street, "node": node, "tris": tris, "box": box })


# --- Strips ----------------------------------------------------------------------------------

func _trim_of(node: int, link: int, start: bool, level: int) -> float:
	for arm: Dictionary in nodes[node].arms:
		if arm.link == link and arm.start == start:
			return arm.trim[level]
	return 0.0


## The polyline from distance t0 to (length - t1), with cross-sections at least every STEP metres.
static func _cut(pts: PackedVector2Array, f: PackedFloat32Array, t0: float, t1: float) -> Array:
	var dist := PackedFloat32Array([0.0])
	for i in pts.size() - 1:
		dist.append(dist[-1] + pts[i].distance_to(pts[i + 1]))
	var end := dist[-1] - t1
	if end - t0 < 0.05:
		return []
	var stops := PackedFloat32Array([t0])
	for i in range(1, pts.size() - 1):
		if dist[i] > t0 + 0.05 and dist[i] < end - 0.05:
			stops.append(dist[i])
	stops.append(end)
	var out := PackedVector2Array()
	var of := PackedFloat32Array()
	for k in stops.size() - 1:
		var n := maxi(1, ceili((stops[k + 1] - stops[k]) / STEP))
		for j in n:
			var q := _at(pts, f, dist, lerpf(stops[k], stops[k + 1], float(j) / n))
			out.append(q[0])
			of.append(q[1])
	var last := _at(pts, f, dist, end)
	out.append(last[0])
	of.append(last[1])
	return [out, of]


## [point, narrowing] at distance `s` along the line.
static func _at(pts: PackedVector2Array, f: PackedFloat32Array, dist: PackedFloat32Array, s: float) -> Array:
	var i := 0
	while i < pts.size() - 2 and dist[i + 1] < s:
		i += 1
	var u := clampf((s - dist[i]) / maxf(dist[i + 1] - dist[i], 0.001), 0.0, 1.0)
	return [pts[i].lerp(pts[i + 1], u), lerpf(f[i], f[i + 1], u)]


static func _length(pts: PackedVector2Array) -> float:
	var out := 0.0
	for i in pts.size() - 1:
		out += pts[i].distance_to(pts[i + 1])
	return out


func _strips(i: int) -> void:
	var l: Dictionary = links[i]
	var sp: Dictionary = specs[l.street]
	for level in [WALK, ROAD]:
		if level == WALK and float(sp.walk[0]) <= 0.0 and float(sp.walk[1]) <= 0.0:
			continue
		var t0 := _trim_of(l.a, i, true, level)
		var t1 := _trim_of(l.b, i, false, level)
		var surface: String = "flags" if level == WALK else sp.surface
		_add(level, surface, l.street, -1, _band(l, level, t0, t1))


## A link's surface at one level as triangles, from t0 metres after its start to t1 before its end:
## cross-sections every STEP metres, mitred at its bends.
func _band(l: Dictionary, level: int, t0: float, t1: float) -> PackedVector2Array:
	var sp: Dictionary = specs[l.street]
	var tris := PackedVector2Array()
	if level == WALK and float(sp.walk[0]) <= 0.0 and float(sp.walk[1]) <= 0.0:
		return tris
	var cut := _cut(l.pts, l.f, t0, t1)
	if cut.is_empty():
		return tris
	var pts: PackedVector2Array = cut[0]
	var f: PackedFloat32Array = cut[1]
	var lefts := PackedVector2Array()
	var rights := PackedVector2Array()
	for k in pts.size():
		var d_prev := (pts[k] - pts[k - 1]).normalized() if k > 0 else (pts[1] - pts[0]).normalized()
		var d_next := (pts[k + 1] - pts[k]).normalized() if k < pts.size() - 1 else d_prev
		var n_prev := d_prev.orthogonal()
		var n := (n_prev + d_next.orthogonal()).normalized()
		if n == Vector2.ZERO:
			n = n_prev
		var miter := 1.0 / maxf(n.dot(n_prev), 0.35)
		var road: float = sp.road * f[k] * 0.5
		var hl := road
		var hr := road
		if level == WALK:
			hl += float(sp.walk[0])
			hr += float(sp.walk[1])
		lefts.append(pts[k] + n * hl * miter)
		rights.append(pts[k] - n * hr * miter)
	for k in pts.size() - 1:
		tris.append_array([lefts[k], rights[k], rights[k + 1], lefts[k], rights[k + 1], lefts[k + 1]])
	return tris


# --- Questions ---------------------------------------------------------------------------------

func node_near(p: Vector2, within: float) -> int:
	var best := within
	var out := -1
	for k in nodes.size():
		var d: float = (nodes[k].at as Vector2).distance_to(p)
		if d <= best:
			best = d
			out = k
	return out


## Metres from `p` to the nearest street's centre line (or to the street `id`).
func distance_to_street(p: Vector2, id := "") -> float:
	var best := INF
	for s in lines.size():
		if id != "" and streets[s].id != id:
			continue
		var pts: PackedVector2Array = lines[s].pts
		for i in pts.size() - 1:
			best = minf(best, Geometry2D.get_closest_point_to_segment(p, pts[i], pts[i + 1]).distance_to(p))
	return best


func connected(a: int, b: int) -> bool:
	if a < 0 or b < 0:
		return false
	var seen := { a: true }
	var todo := [a]
	while not todo.is_empty():
		var k: int = todo.pop_back()
		if k == b:
			return true
		for arm: Dictionary in nodes[k].arms:
			var l: Dictionary = links[arm.link]
			var other: int = l.b if arm.start else l.a
			if not seen.has(other):
				seen[other] = true
				todo.append(other)
	return false


## At node `k`, where each pair of kerbs would meet (`sharp`: the block's corner, which the chamfer
## cuts off and gives to the street) and a point just beyond the chamfer (`beyond`: still the block).
func corners(k: int) -> Array:
	return _corners[k]


func _bucket(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / BUCKET), floori(p.y / BUCKET))


func covers(p: Vector2, layer: int) -> bool:
	if _buckets.is_empty():
		for pi in pieces.size():
			var tris: PackedVector2Array = pieces[pi].tris
			for t in range(0, tris.size(), 3):
				var box := Rect2(tris[t], Vector2.ZERO).expand(tris[t + 1]).expand(tris[t + 2])
				var b0 := _bucket(box.position)
				var b1 := _bucket(box.end)
				for x in range(b0.x, b1.x + 1):
					for y in range(b0.y, b1.y + 1):
						var key := Vector2i(x, y)
						if not _buckets.has(key):
							_buckets[key] = [] # a plain Array: a packed one in a Dictionary is a copy
						(_buckets[key] as Array).append_array([pi, t])
	var list: Array = _buckets.get(_bucket(p), [])
	for k in range(0, list.size(), 2):
		var piece: Dictionary = pieces[list[k]]
		if piece.layer != layer:
			continue
		var tris: PackedVector2Array = piece.tris
		var t: int = list[k + 1]
		if _in_tri(p, tris[t], tris[t + 1], tris[t + 2]):
			return true
	return false


## Inside or on an edge (a point on the seam between two triangles is covered).
static func _in_tri(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var area := (b - a).cross(c - a)
	if absf(area) < 1e-9:
		return false
	var e := 1e-4 * absf(area)
	var w0 := (b - a).cross(p - a) * signf(area)
	var w1 := (c - b).cross(p - b) * signf(area)
	var w2 := (a - c).cross(p - c) * signf(area)
	return w0 >= -e and w1 >= -e and w2 >= -e


## The pieces with a corner inside `area` (all of them when it is empty).
func pieces_in(area := PackedVector2Array()) -> Array:
	if area.is_empty():
		return pieces
	var bound := Rect2(area[0], Vector2.ZERO)
	for p in area:
		bound = bound.expand(p)
	var out := []
	for piece: Dictionary in pieces:
		if not (piece.box as Rect2).intersects(bound):
			continue
		for p: Vector2 in piece.tris:
			if Geometry2D.is_point_in_polygon(p, area):
				out.append(piece)
				break
	return out


func triangles(area := PackedVector2Array()) -> int:
	var n := 0
	for piece: Dictionary in pieces_in(area):
		n += (piece.tris as PackedVector2Array).size() / 3
	return n

