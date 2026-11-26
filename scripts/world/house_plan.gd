class_name HousePlan
extends RefCounted
## A house's floors (S244), laid out like a Paris house before Haussmann: a narrow house between
## party walls, its rooms along the street and along the court, a mur de refend across it, the stair
## in its own cage against a party wall, an allée from the street door to the stair, a shop on the
## ground floor. Data only, no nodes: InteriorBuilder makes it into walls, RoomDressing paints and
## furnishes each room, `tools/house_plans.py` draws it.
##
## Two kinds of thing. **Fixed**, the same on every floor because the house is built that way
## (`frame`): the footprint, the window bays of both facades, the street door, the stair cage and its
## flights, the refends (where the bands of rooms end) and the flues in the party walls. **Seeded**,
## different on every floor (`floors`, HouseFloor): the partitions, which room is what, the doors,
## the paint, the lamps and the furniture slots. A floor keeps some partitions of the floor below
## (Config.INTERIOR_STACK), so walls stand over walls as in a real house.
##
## Plan coordinates, metres: x across the house from one party wall's inner face to the other's
## (0 .. width), z from the street facade's inner face to the court's (0 .. depth). The walls lie
## outside that rectangle: the party walls' halves at x < 0 and x > width, the facades at z < 0
## (street) and z > depth (court). Rectangles are Rect2 with (x, z) in (position.x, position.y).
## The stair stands against the party wall on the side of the street door (spec.door: "left" is
## x = 0, "right" is x = width); everything is laid out with it at x = 0 and mirrored at the end.
##
## Every space keeps the player's size: corridors, passages and the allée are at least
## Config.INTERIOR_CORRIDOR wide, doors Config.INTERIOR_DOOR, rooms Config.INTERIOR_ROOM_MIN, and the
## furniture leaves a way through between every door of a room (RoomDressing.check).

const EPS := 0.005

## What each kind of space is: its French name, whether it is a way through (no furniture in the
## way, lit along its length), wet (opens only onto a way through), and whether it needs a window.
const KINDS := {
	"stair": { "label": "escalier", "circulation": true, "wet": false, "window": false },
	"allee": { "label": "allée", "circulation": true, "wet": false, "window": false },
	"corridor": { "label": "couloir", "circulation": true, "wet": false, "window": false },
	"entree": { "label": "entrée", "circulation": true, "wet": false, "window": false },
	"salon": { "label": "salon", "circulation": false, "wet": false, "window": true },
	"salle_a_manger": { "label": "salle à manger", "circulation": false, "wet": false, "window": true },
	"chambre": { "label": "chambre", "circulation": false, "wet": false, "window": true },
	"cabinet": { "label": "cabinet", "circulation": false, "wet": false, "window": true },
	"cuisine": { "label": "cuisine", "circulation": false, "wet": false, "window": true },
	"salle_d_eau": { "label": "salle d'eau", "circulation": false, "wet": true, "window": false },
	"wc": { "label": "WC", "circulation": false, "wet": true, "window": false },
	"debarras": { "label": "débarras", "circulation": false, "wet": false, "window": false },
	"boutique": { "label": "boutique", "circulation": false, "wet": false, "window": true },
	"loge": { "label": "loge", "circulation": false, "wet": false, "window": true },
	"arriere_boutique": { "label": "arrière-boutique", "circulation": false, "wet": false, "window": false },
	"reserve": { "label": "réserve", "circulation": false, "wet": false, "window": false },
	"remise": { "label": "remise", "circulation": false, "wet": false, "window": false },
	"atelier": { "label": "atelier", "circulation": false, "wet": false, "window": true },
}

var spec: Dictionary
var width: float    ## inside, m
var depth: float    ## inside, m
var storey: float   ## floor to floor, m
var clear: float    ## floor to ceiling, m
var mirrored := false
## The fixed things: variant ("middle": the stair between the two bands of rooms, "back": against
## the court), cage / palier / up / back_flight / mid (Rect2: the cage, its landing at floor level,
## the flight up from it, the flight that comes back to the next floor, the half landing), riser,
## risers, front_band (z where the street rooms end), back_band (z where the court rooms begin, the
## depth when there are none), bay / back_bay (m), front_bays / back_bays (x of each bay's middle),
## front_windows / back_windows ([x0, x1] of the standard windows), door ([x0, x1] of the street
## door), flues ({ x, z, band }: a chimney flue in a party wall).
var frame := {}
var floors: Array = []  ## one Dictionary per floor (HouseFloor.to_data)
var ok := true
var problem := ""


## The house the step is judged on: three bays on a rue, a shop on the ground floor, three floors.
static func sample(seed := 18000) -> Dictionary:
	return { "width": 7.5, "depth": 12.5, "bays": 3, "back_bays": 3, "floors": 3, "storey": 3.2,
		"door": "left", "shop": true, "seed": seed }


func _init(s: Dictionary) -> void:
	spec = s.duplicate()
	var defaults := sample()
	for k: String in defaults:
		if not spec.has(k):
			spec[k] = defaults[k]
	width = float(spec.width) - 2.0 * Config.INTERIOR_PARTY
	depth = float(spec.depth) - 2.0 * Config.INTERIOR_FACADE
	storey = float(spec.storey)
	clear = storey - Config.INTERIOR_SLAB
	mirrored = spec.door == "right"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(spec.seed), "house"])
	problem = _frame(rng)
	ok = problem == ""
	if not ok:
		return
	var below: Array = []
	for level in int(spec.floors):
		var f := HouseFloor.new(info(), level, below)
		if not f.ok:
			ok = false
			problem = "floor %d: %s" % [level, f.problem]
		floors.append(f.to_data())
		below = f.cuts
	if mirrored:
		_mirror_all()


## What a floor needs to know of its house (HouseFloor keeps no reference to the plan).
func info() -> Dictionary:
	return { "width": width, "depth": depth, "storey": storey, "clear": clear, "frame": frame, "spec": spec }


# --- The frame ------------------------------------------------------------------

func _frame(rng: RandomNumberGenerator) -> String:
	var bays := int(spec.bays)
	var back_bays := int(spec.back_bays)
	if bays < 1 or back_bays < 1:
		return "no bays"
	var bay := float(spec.width) / bays
	var back_bay := float(spec.width) / back_bays
	frame.bay = bay
	frame.back_bay = back_bay
	frame.front_bays = []
	frame.front_windows = []
	for i in bays:
		var c := (i + 0.5) * bay - Config.INTERIOR_PARTY
		var half := minf(Config.INTERIOR_WINDOW.x, bay - 0.7) * 0.5
		frame.front_bays.append(c)
		frame.front_windows.append([c - half, c + half])
	frame.back_bays = []
	frame.back_windows = []
	for i in back_bays:
		var c := (i + 0.5) * back_bay - Config.INTERIOR_PARTY
		var half := minf(Config.INTERIOR_CASEMENT.x, back_bay - 0.7) * 0.5
		frame.back_bays.append(c)
		frame.back_windows.append([c - half, c + half])
	var c0: float = frame.front_bays[0]
	var door_half := minf(Config.INTERIOR_STREET_DOOR.x, bay - 2.0 * Config.INTERIOR_JAMB - 0.3) * 0.5
	if door_half * 2.0 < Config.INTERIOR_DOOR:
		return "the bays are too narrow for the street door"
	frame.door = [c0 - door_half, c0 + door_half]

	# the stair: an even number of risers, two flights a floor, a landing at each end
	var risers := ceili(storey / Config.INTERIOR_RISER_MAX - 0.0001)
	if risers % 2 == 1:
		risers += 1
	frame.risers = risers
	frame.riser = storey / risers
	var flight := (risers / 2 - 1) * Config.INTERIOR_TREAD
	var cage_len := Config.INTERIOR_LANDING * 2.0 + flight
	var cage_w := Config.INTERIOR_FLIGHT * 2.0 + Config.INTERIOR_WELL
	frame.flight = flight

	var middle_room := depth - Config.INTERIOR_REFEND * 2.0 - cage_len - Config.INTERIOR_BAND_MIN
	var middle_ok := middle_room >= Config.INTERIOR_BAND_MIN
	var back_front := depth - cage_len - Config.INTERIOR_REFEND
	var back_ok := back_front >= Config.INTERIOR_BAND_MIN and back_front <= Config.INTERIOR_BAND_MAX
	if not middle_ok and not back_ok:
		return "%.1f m deep inside: too shallow for a stair and a band of rooms" % depth
	frame.variant = "middle" if middle_ok and (not back_ok or rng.randf() < 0.6) else "back"
	var front_depth := back_front
	if frame.variant == "middle":
		var hi := minf(Config.INTERIOR_BAND_MAX, middle_room)
		front_depth = rng.randf_range(minf(Config.INTERIOR_BAND_MIN + 0.9, hi), minf(hi, Config.INTERIOR_BAND_MIN + 2.6))
	var z0 := front_depth + Config.INTERIOR_REFEND
	frame.front_band = front_depth + Config.INTERIOR_REFEND * 0.5
	if frame.variant == "back":
		# the cage reaches the court wall: its inner wall must stand between two windows
		cage_w = pier(cage_w, Config.INTERIOR_CAGE_WALL, frame.back_windows)
		frame.back_band = depth
	else:
		frame.back_band = z0 + cage_len + Config.INTERIOR_REFEND * 0.5
	if width - cage_w - Config.INTERIOR_CAGE_WALL < Config.INTERIOR_CORRIDOR:
		return "%.1f m wide inside: no room for the stair and a passage beside it" % width
	var fw := minf((cage_w - Config.INTERIOR_WELL) * 0.5, Config.INTERIOR_FLIGHT * 1.2)
	frame.cage = Rect2(0, z0, cage_w, cage_len)
	frame.palier = Rect2(0, z0, cage_w, Config.INTERIOR_LANDING)
	frame.up = Rect2(0, z0 + Config.INTERIOR_LANDING, fw, flight)
	frame.back_flight = Rect2(cage_w - fw, z0 + Config.INTERIOR_LANDING, fw, flight)
	frame.mid = Rect2(0, z0 + Config.INTERIOR_LANDING + flight, cage_w, Config.INTERIOR_LANDING)

	# flues: one in each party wall a band of rooms touches, the same on every floor
	frame.flues = []
	var bands := [["front", 0.0, front_depth, [0.0, width]]]
	if frame.variant == "middle":
		bands.append(["back", float(frame.back_band) + Config.INTERIOR_REFEND * 0.5, depth, [0.0, width]])
	else: # the court rooms stand beside the cage: only the far party wall
		bands.append(["back", z0, depth, [width]])
	for b: Array in bands:
		var lo: float = b[1]
		var hi: float = b[2]
		if hi - lo < 2.4:
			continue
		for x: float in b[3]:
			var z := (lo + hi) * 0.5 + rng.randf_range(-0.2, 0.2) * (hi - lo)
			frame.flues.append({ "x": x, "z": snappedf(z, 0.01), "band": b[0] })
	return ""


## The first x at or after `x` where a wall `t` thick stands clear of every span (window or door)
## by a jamb: walls meet a facade between its openings, never across one.
static func pier(x: float, t: float, spans: Array) -> float:
	var at := x
	var moved := true
	while moved:
		moved = false
		for s: Array in spans:
			if at < float(s[1]) + Config.INTERIOR_JAMB and at + t > float(s[0]) - Config.INTERIOR_JAMB:
				at = float(s[1]) + Config.INTERIOR_JAMB
				moved = true
	return at


## `area` less every rectangle of `holes`, as rectangles: the plane cut at every edge, the cells
## left merged row by row (along x first, then down z), so a band of rooms comes out whole.
static func free_rects(area: Rect2, holes: Array) -> Array:
	var xs := [area.position.x, area.end.x]
	var zs := [area.position.y, area.end.y]
	for h: Rect2 in holes:
		var c := h.intersection(area)
		if c.size.x <= EPS or c.size.y <= EPS:
			continue
		xs.append_array([c.position.x, c.end.x])
		zs.append_array([c.position.y, c.end.y])
	xs = _unique(xs)
	zs = _unique(zs)
	var nx := xs.size() - 1
	var nz := zs.size() - 1
	var free := PackedByteArray()
	free.resize(nx * nz)
	for j in nz:
		for i in nx:
			var p := Vector2((xs[i] + xs[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5)
			var open := 1
			for h: Rect2 in holes:
				if h.has_point(p):
					open = 0
					break
			free[j * nx + i] = open
	var out := []
	for j in nz:
		for i in nx:
			if free[j * nx + i] != 1:
				continue
			var i1 := i
			while i1 + 1 < nx and free[j * nx + i1 + 1] == 1:
				i1 += 1
			var j1 := j
			while j1 + 1 < nz:
				var row_ok := true
				for k in range(i, i1 + 1):
					if free[(j1 + 1) * nx + k] != 1:
						row_ok = false
						break
				if not row_ok:
					break
				j1 += 1
			for jj in range(j, j1 + 1):
				for k in range(i, i1 + 1):
					free[jj * nx + k] = 2
			out.append(Rect2(xs[i], zs[j], xs[i1 + 1] - xs[i], zs[j1 + 1] - zs[j]))
	return out


static func _unique(v: Array) -> Array:
	v.sort()
	var out := []
	for x: float in v:
		if out.is_empty() or x - float(out[-1]) > EPS:
			out.append(x)
	return out


## The ids of every space reached from the stair through doors (and through the street: a shop
## opens onto it), with -1 the street and -2 the court.
static func reachable(f: Dictionary) -> Dictionary:
	var links := {}
	for d: Dictionary in f.doors:
		var a: int = d.a
		var b: int = d.b
		if not links.has(a):
			links[a] = []
		if not links.has(b):
			links[b] = []
		links[a].append(b)
		links[b].append(a)
	var start := -1
	for s: Dictionary in f.spaces:
		if s.kind == "stair":
			start = s.id
	var got := { start: true }
	var todo := [start]
	while not todo.is_empty():
		var at: int = todo.pop_back()
		for n: int in links.get(at, []):
			if not got.has(n):
				got[n] = true
				todo.append(n)
	return got


# --- Mirroring ------------------------------------------------------------------

func _mirror_all() -> void:
	for k in ["cage", "palier", "up", "back_flight", "mid"]:
		frame[k] = _mirror_rect(frame[k])
	for k in ["front_windows", "back_windows"]:
		var spans := []
		for s: Array in frame[k]:
			spans.append([width - float(s[1]), width - float(s[0])])
		spans.reverse()
		frame[k] = spans
	for k in ["front_bays", "back_bays"]:
		var xs := []
		for x: float in frame[k]:
			xs.append(width - x)
		xs.reverse()
		frame[k] = xs
	frame.door = [width - float(frame.door[1]), width - float(frame.door[0])]
	for fl: Dictionary in frame.flues:
		fl.x = width - float(fl.x)
	for f: Dictionary in floors:
		for s: Dictionary in f.spaces:
			s.rect = _mirror_rect(s.rect)
			var rs := []
			for r: Rect2 in s.rects:
				rs.append(_mirror_rect(r))
			s.rects = rs
			for l: Dictionary in s.lights:
				l.pos = _mirror_point(l.pos)
			for w: Dictionary in s.switches:
				w.pos = _mirror_point(w.pos)
			for it: Dictionary in s.furniture:
				it.rect = _mirror_rect(it.rect)
				var fc: Vector2 = it.facing
				it.facing = Vector2(-fc.x, fc.y)
				it.wall = { "x0": "x1", "x1": "x0" }.get(it.wall, it.wall)
		for d: Dictionary in f.doors:
			if d.axis == "x":
				d.at = width - float(d.at)
			else:
				var lo := width - float(d.to)
				d.to = width - float(d.from)
				d.from = lo
				d.hinge = width - float(d.hinge)
		for w: Dictionary in f.windows:
			var lo := width - float(w.to)
			w.to = width - float(w.from)
			w.from = lo


func _mirror_rect(r: Rect2) -> Rect2:
	return Rect2(width - r.end.x, r.position.y, r.size.x, r.size.y)


func _mirror_point(p: Vector3) -> Vector3:
	return Vector3(width - p.x, p.y, p.z)


# --- Export -----------------------------------------------------------------------

## Everything as plain JSON values (rectangles [x, z, w, d], colours "#rrggbb", points [x, y, z]),
## for `--house-plans` and tools/house_plans.py.
func to_dict() -> Dictionary:
	return { "spec": spec, "width": width, "depth": depth, "storey": storey, "clear": clear,
		"party": Config.INTERIOR_PARTY, "facade": Config.INTERIOR_FACADE, "ok": ok, "problem": problem,
		"frame": plain(frame), "floors": plain(floors), "kinds": KINDS,
		"player": { "radius": Config.PLAYER_RADIUS, "height": Config.PLAYER_HEIGHT } }


static func plain(v: Variant) -> Variant:
	match typeof(v):
		TYPE_RECT2:
			var r: Rect2 = v
			return [snappedf(r.position.x, 0.001), snappedf(r.position.y, 0.001), snappedf(r.size.x, 0.001), snappedf(r.size.y, 0.001)]
		TYPE_VECTOR2:
			var p: Vector2 = v
			return [snappedf(p.x, 0.001), snappedf(p.y, 0.001)]
		TYPE_VECTOR3:
			var p: Vector3 = v
			return [snappedf(p.x, 0.001), snappedf(p.y, 0.001), snappedf(p.z, 0.001)]
		TYPE_COLOR:
			return "#" + (v as Color).to_html(false)
		TYPE_FLOAT:
			return snappedf(v, 0.001)
		TYPE_DICTIONARY:
			var out := {}
			for k: Variant in v:
				out[k] = plain(v[k])
			return out
		TYPE_ARRAY:
			var out := []
			for x: Variant in v:
				out.append(plain(x))
			return out
	return v
