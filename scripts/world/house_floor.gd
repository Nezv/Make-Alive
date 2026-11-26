class_name HouseFloor
extends RefCounted
## One floor of a HousePlan (S244). Laid out in this order, each step on the last one's result:
##   1. the facade's openings on this floor (the bays are fixed; what fills them is not: a street
##      door, shop windows, French windows upstairs, casements on the court, the stair's window);
##   2. the way through: the stair cage (fixed), a corridor beside it (seeded width; it widens into
##      an entrée when what would be left beside it is too narrow for a room), and on the ground
##      floor the allée from the street door to the stair and a passage on to the court;
##   3. the rooms: what is left, cut along the refends into bands, each band cut into rooms by
##      partitions (Config.INTERIOR_PARTITION). A band on a facade is cut only across, between two
##      windows, so every room gets a window and no wall meets the facade across one; a partition
##      prefers lining up with a wall behind it (Config.INTERIOR_ALIGN) and with one of the floor
##      below (Config.INTERIOR_STACK). A band without a facade (beside the corridor) is cut along,
##      into small rooms that all open onto the corridor;
##   4. what each room is (a dwelling: salon, kitchen, WC, bedrooms...; a shop floor: the shop, the
##      concierge's loge, store rooms);
##   5. the doors: every room joined to the way through, or else to a room already joined (never
##      through a WC), each door near a corner of its wall, its leaf clear of the others; then
##      enfilades along the street, the kitchen to the dining room, the shop's back door;
##   6. paint, lamps and furniture slots (RoomDressing).
## A layout that breaks a rule is thrown away and tried again with the next seed (up to
## Config.INTERIOR_TRIES).

const EPS := 0.005
const LIVING := ["salon", "salle_a_manger", "chambre", "cabinet"]

var level: int
var ok := false
var problem := ""
var tries := 0
var spaces: Array = []   ## { id, kind, rect, rects, band, facing, carved, windows, doors, area, paint, lights, switches, furniture, main_door }
var doors: Array = []    ## { id, a, b (-1 the street, -2 the court), axis, at, t, from, to, height, kind, swing (space id or -1), hinge }
var windows: Array = []  ## { id, side, from, to, sill, head, kind, space }
var cuts: Array = []     ## { facing, axis, at }: this floor's partitions, for the floor above to keep
var rejected: Array = [] ## why each layout tried before this one was thrown away

var _w: float
var _d: float
var _clear: float
var _storey: float
var _f: Dictionary
var _spec: Dictionary
var _below: Array
var _rng := RandomNumberGenerator.new()
var _front: Array = []    ## this floor's openings in the street facade: { from, to, kind, sill, head }
var _back: Array = []
var _contacts: Array = [] ## { a, b, axis, at, t, from, to }
var _lines: Array = []    ## x of the core band's walls, for partitions to line up with
var _corridor := {}
var _entry := {}       ## with no corridor, the room the landing opens into
var _ground := false
var _shop := false
var _top := false
var _next_id := 0


func _init(info: Dictionary, lvl: int, below: Array) -> void:
	level = lvl
	_w = info.width
	_d = info.depth
	_clear = info.clear
	_storey = info.storey
	_f = info.frame
	_spec = info.spec
	_below = below
	_ground = level == 0
	_shop = _ground and bool(_spec.shop)
	_top = level == int(_spec.floors) - 1
	for attempt in Config.INTERIOR_TRIES:
		_rng.seed = hash([int(_spec.seed), "floor", level, attempt])
		tries = attempt + 1
		problem = _lay_out()
		if problem == "":
			problem = _dress(attempt == Config.INTERIOR_TRIES - 1)
		if problem == "":
			ok = true
			return
		rejected.append(problem)


func to_data() -> Dictionary:
	return { "level": level, "y": level * _storey, "clear": _clear, "variant": _f.variant, "tries": tries,
		"ok": ok, "problem": problem, "rejected": rejected, "spaces": spaces, "doors": doors, "windows": windows }


# --- 1. The facades ---------------------------------------------------------------

func _openings() -> void:
	_front = []
	_back = []
	var bays: Array = _f.front_bays
	for i in bays.size():
		var c: float = bays[i]
		var std: Array = _f.front_windows[i]
		if _ground and i == 0:
			_front.append({ "from": _f.door[0], "to": _f.door[1], "kind": "street" })
		elif _shop:
			var half := minf(Config.INTERIOR_SHOP_WINDOW.x, float(_f.bay) - 0.75) * 0.5
			_front.append({ "from": c - half, "to": c + half, "kind": "shop",
				"sill": Config.INTERIOR_SHOP_WINDOW.y, "head": minf(Config.INTERIOR_SHOP_WINDOW.z, _clear - 0.2) })
		elif _ground:
			_front.append({ "from": std[0], "to": std[1], "kind": "casement",
				"sill": Config.INTERIOR_CASEMENT.y, "head": minf(Config.INTERIOR_CASEMENT.z, _clear - 0.25) })
		else:
			_front.append({ "from": std[0], "to": std[1], "kind": "french",
				"sill": Config.INTERIOR_WINDOW.y, "head": minf(Config.INTERIOR_WINDOW.z, _clear - 0.25) })
	var cage: Rect2 = _f.cage
	for span: Array in _f.back_windows:
		var o := { "from": span[0], "to": span[1], "kind": "casement",
			"sill": Config.INTERIOR_CASEMENT.y, "head": minf(Config.INTERIOR_CASEMENT.z, _clear - 0.25) }
		if cage.end.y >= _d - EPS and float(span[1]) <= cage.end.x + EPS and not _top:
			# the stair's window lights the half landing, between this floor and the next
			o.kind = "stair"
			o.sill = _storey * 0.5 + 0.85
			o.head = o.sill + 1.25
		_back.append(o)


static func _spans(openings: Array, skip: Array = []) -> Array:
	var out := []
	for o: Dictionary in openings:
		if not skip.has(o.kind):
			out.append([o.from, o.to])
	return out


# --- 2..5. The layout ----------------------------------------------------------------

func _lay_out() -> String:
	spaces = []
	doors = []
	windows = []
	cuts = []
	_contacts = []
	_lines = []
	_corridor = {}
	_entry = {}
	_next_id = 0
	_openings()
	var cage: Rect2 = _f.cage
	_add("stair", cage, "core")
	var refend := Config.INTERIOR_REFEND
	var holes := [Rect2(0, float(_f.front_band) - refend * 0.5, _w, refend),
		Rect2(cage.position.x, cage.position.y, cage.size.x + Config.INTERIOR_CAGE_WALL, cage.size.y)]
	if _f.variant == "middle":
		holes.append(Rect2(0, float(_f.back_band) - refend * 0.5, _w, refend))
	var err := _circulation(cage)
	if err != "":
		return err
	for s: Dictionary in spaces:
		if s.kind != "stair":
			holes.append((s.rect as Rect2).grow(Config.INTERIOR_PARTITION))
	var regions := HousePlan.free_rects(Rect2(0, 0, _w, _d), holes)
	for r: Rect2 in regions:
		if minf(r.size.x, r.size.y) < Config.INTERIOR_CLOSET_MIN - EPS:
			continue # a sliver between walls: left solid
		var facing := _facing(r)
		var pieces := []
		_split(r, facing, pieces, 0)
		for p: Array in pieces:
			var s := _add("", p[0], _band(p[0]))
			s.facing = facing
			s.carved = p[1]
	err = _assign_windows()
	if err != "":
		return err
	_find_contacts()
	err = _program_shop() if _shop else _program_home()
	if err != "":
		return err
	err = _connect()
	if err != "":
		return err
	_extras()
	_exterior_doors()
	var got := HousePlan.reachable({ "spaces": spaces, "doors": doors })
	for s: Dictionary in spaces:
		if not got.has(s.id):
			return "the %s %d is not reached" % [s.kind, s.id]
	return ""


## The stair's neighbours: the corridor beside it, and on the ground floor the allée in front.
func _circulation(cage: Rect2) -> String:
	var z0 := cage.position.y
	var z1 := cage.end.y
	var cx0 := cage.end.x + Config.INTERIOR_CAGE_WALL
	_lines.append(cage.end.x + Config.INTERIOR_CAGE_WALL * 0.5)
	if _ground and _f.variant == "middle":
		z1 = _d # the passage goes on through to the court
	var reaches_back := z1 >= _d - EPS
	var cx1 := cx0 + Config.INTERIOR_CORRIDOR + _rng.randf() * Config.INTERIOR_CORRIDOR_SLACK
	if reaches_back:
		cx1 = HousePlan.pier(cx1, Config.INTERIOR_PARTITION, _spans(_back))
	var need := Config.INTERIOR_ROOM_MIN if reaches_back else Config.INTERIOR_CLOSET_MIN
	var as_rooms := false
	if _w - cx1 - Config.INTERIOR_PARTITION < need:
		cx1 = _w
		as_rooms = not _ground and reaches_back and _w - cx0 >= Config.INTERIOR_ROOM_MIN
	if not as_rooms:
		var kind := "corridor" if _ground or cx1 - cx0 <= Config.INTERIOR_HALL + EPS else "entree"
		var wc_d := 0.0
		if not _shop and _f.variant == "back": # nowhere dark for a WC: it closes the corridor's far end
			wc_d = _rng.randf_range(Config.INTERIOR_CLOSET_MIN, 1.6)
			if z1 - z0 - wc_d - Config.INTERIOR_PARTITION < Config.INTERIOR_LANDING + Config.INTERIOR_DOOR + 0.6:
				wc_d = 0.0
		var cz1 := z1 - (wc_d + Config.INTERIOR_PARTITION if wc_d > 0.0 else 0.0)
		_corridor = _add(kind, Rect2(cx0, z0, cx1 - cx0, cz1 - z0), "core")
		_lines.append(cx1 + Config.INTERIOR_PARTITION * 0.5)
		if wc_d > 0.0:
			var wc := _add("", Rect2(cx0, z1 - wc_d, cx1 - cx0, wc_d), "core")
			wc.carved = true
			wc.facing = "back"
	if _ground:
		var door: Array = _f.door
		var ax := maxf(float(door[1]) + Config.INTERIOR_JAMB, Config.INTERIOR_CORRIDOR)
		ax = HousePlan.pier(ax, Config.INTERIOR_PARTITION, _spans(_front, ["street"]))
		if _w - ax - Config.INTERIOR_PARTITION < Config.INTERIOR_ROOM_MIN:
			ax = _w
		var fd := float(_f.front_band) - Config.INTERIOR_REFEND * 0.5
		if ax < Config.INTERIOR_CORRIDOR - EPS:
			return "the allée is too narrow"
		_add("allee", Rect2(0, 0, ax, fd), "front")
		_lines.append(ax + Config.INTERIOR_PARTITION * 0.5)
	return ""


func _facing(r: Rect2) -> String:
	if r.position.y <= EPS:
		return "front"
	if r.end.y >= _d - EPS:
		return "back"
	return "none"


func _band(r: Rect2) -> String:
	if r.end.y <= float(_f.front_band) + EPS:
		return "front"
	if _f.variant == "middle" and r.position.y >= float(_f.back_band) - EPS:
		return "back"
	return "core"


## Cut a region into rooms: pieces [rect, carved] into `out`.
func _split(r: Rect2, facing: String, out: Array, depth: int) -> void:
	var t := Config.INTERIOR_PARTITION
	var target: float
	match facing:
		"front":
			target = _rng.randf_range(10.0, 18.0)
		"back":
			target = _rng.randf_range(8.0, 14.0)
		_:
			target = _rng.randf_range(2.2, 4.2)
	if r.get_area() <= target * 1.3 or depth > 6:
		out.append([r, false])
		return
	var opts := _cut_options(r, facing, target)
	if opts.is_empty():
		out.append([r, false])
		return
	var best: Dictionary = opts[0]
	for o: Dictionary in opts:
		if float(o.score) > float(best.score):
			best = o
	var at: float = best.at
	var a: Rect2
	var b: Rect2
	if facing == "none":
		a = Rect2(r.position.x, r.position.y, r.size.x, at - t * 0.5 - r.position.y)
		b = Rect2(r.position.x, at + t * 0.5, r.size.x, r.end.y - at - t * 0.5)
		cuts.append({ "facing": facing, "axis": "z", "at": at })
	else:
		a = Rect2(r.position.x, r.position.y, at - t * 0.5 - r.position.x, r.size.y)
		b = Rect2(at + t * 0.5, r.position.y, r.end.x - at - t * 0.5, r.size.y)
		cuts.append({ "facing": facing, "axis": "x", "at": at })
	_split(a, facing, out, depth + 1)
	_split(b, facing, out, depth + 1)


## Where a partition may stand in a region, each place scored: balanced pieces, lined up with a
## wall behind or below, a little luck.
func _cut_options(r: Rect2, facing: String, target: float) -> Array:
	var t := Config.INTERIOR_PARTITION
	var cands := []
	if facing == "none":
		var lo := r.position.y + Config.INTERIOR_CLOSET_MIN + t * 0.5
		var hi := r.end.y - Config.INTERIOR_CLOSET_MIN - t * 0.5
		if hi >= lo:
			for k in 5:
				cands.append([lerpf(lo, hi, k / 4.0), false])
			for c: Dictionary in _below:
				if c.axis == "z" and float(c.at) >= lo and float(c.at) <= hi:
					cands.append([c.at, true])
	else:
		var ops := []
		for o: Dictionary in (_front if facing == "front" else _back):
			if float(o.from) >= r.position.x - EPS and float(o.to) <= r.end.x + EPS:
				ops.append(o)
		ops.sort_custom(func(p: Dictionary, q: Dictionary): return float(p.from) < float(q.from))
		for i in ops.size() - 1:
			var lo := maxf(float(ops[i].to) + Config.INTERIOR_JAMB + t * 0.5, r.position.x + Config.INTERIOR_ROOM_MIN + t * 0.5)
			var hi := minf(float(ops[i + 1].from) - Config.INTERIOR_JAMB - t * 0.5, r.end.x - Config.INTERIOR_ROOM_MIN - t * 0.5)
			if hi < lo:
				continue
			cands.append([(lo + hi) * 0.5, false])
			for x: float in _lines:
				if x >= lo and x <= hi:
					cands.append([x, false, true])
			for c: Dictionary in _below:
				if c.axis == "x" and c.facing == facing and float(c.at) >= lo and float(c.at) <= hi:
					cands.append([c.at, true])
		cands = cands.filter(func(c: Array): return _keeps_corridor_end(r, float(c[0])))
	var out := []
	var size := r.size.y if facing == "none" else r.size.x
	var start := r.position.y if facing == "none" else r.position.x
	for c: Array in cands:
		var at: float = c[0]
		var score := -absf((at - start) / size - 0.5) * 1.5 + _rng.randf() * 0.8
		if facing == "none": # closets: cut off one of about the target's size
			var piece := minf(at - start, start + size - at) * r.size.x
			score = -absf(piece - target) / target + _rng.randf() * 0.4
		if c.size() > 2:
			score += 0.5
		if c[1] and _rng.randf() < Config.INTERIOR_STACK:
			score += 1.2
		out.append({ "at": at, "score": score })
	return out


## A band across the end of the corridor must leave one room facing that end along a door's
## width: a partition in the middle of it would leave the corridor leading nowhere.
func _keeps_corridor_end(r: Rect2, at: float) -> bool:
	if _corridor.is_empty():
		return true
	var c: Rect2 = _corridor.rect
	var gap_front := c.position.y - r.end.y
	var gap_back := r.position.y - c.end.y
	if not (gap_front > 0.0 and gap_front < 0.4) and not (gap_back > 0.0 and gap_back < 0.4):
		return true
	var need := Config.INTERIOR_DOOR + 2.0 * Config.INTERIOR_JAMB
	var t := Config.INTERIOR_PARTITION * 0.5
	var left := minf(at - t, c.end.x) - maxf(r.position.x, c.position.x)
	var right := minf(r.end.x, c.end.x) - maxf(at + t, c.position.x)
	var whole := minf(r.end.x, c.end.x) - maxf(r.position.x, c.position.x)
	return whole < need or left >= need - EPS or right >= need - EPS


func _add(kind: String, rect: Rect2, band: String) -> Dictionary:
	var s := { "id": _next_id, "kind": kind, "rect": rect, "rects": [rect], "band": band, "facing": "none",
		"carved": false, "windows": [], "doors": [], "area": snappedf(rect.get_area(), 0.01), "paint": {},
		"lights": [], "switches": [], "furniture": [], "main_door": -1 }
	_next_id += 1
	spaces.append(s)
	return s


func _space(id: int) -> Dictionary:
	for s: Dictionary in spaces:
		if s.id == id:
			return s
	return {}


func _of_kind(kind: String) -> Dictionary:
	for s: Dictionary in spaces:
		if s.kind == kind:
			return s
	return {}


## Every opening of both facades goes to the space whose wall holds it whole.
func _assign_windows() -> String:
	for side in ["front", "back"]:
		for o: Dictionary in (_front if side == "front" else _back):
			if o.kind == "street":
				continue
			var host := {}
			for s: Dictionary in spaces:
				var r: Rect2 = s.rect
				var on := r.position.y <= EPS if side == "front" else r.end.y >= _d - EPS
				if on and float(o.from) >= r.position.x - EPS and float(o.to) <= r.end.x + EPS:
					host = s
			if host.is_empty():
				return "a %s window at %.2f..%.2f falls on a wall" % [side, o.from, o.to]
			var w := { "id": windows.size(), "side": side, "from": o.from, "to": o.to, "sill": o.sill,
				"head": o.head, "kind": o.kind, "space": host.id }
			windows.append(w)
			host.windows.append(w.id)
	return ""


## Spaces that face each other across one wall, and how far along it they do.
func _find_contacts() -> void:
	var palier: Rect2 = _f.palier
	for i in spaces.size():
		for j in range(i + 1, spaces.size()):
			var a: Dictionary = spaces[i]
			var b: Dictionary = spaces[j]
			var c := _contact(a.rect, b.rect)
			if c.is_empty():
				continue
			if a.kind == "stair" or b.kind == "stair": # the cage opens only off its landing
				var lo := palier.position.y if c.axis == "x" else palier.position.x
				var hi := palier.end.y if c.axis == "x" else palier.end.x
				if c.axis == "z" and absf(float(c.at) - palier.position.y) > 0.3:
					continue
				c.from = maxf(c.from, lo)
				c.to = minf(c.to, hi)
				if c.to - c.from < Config.INTERIOR_DOOR:
					continue
			c.a = a.id
			c.b = b.id
			_contacts.append(c)


static func _contact(a: Rect2, b: Rect2) -> Dictionary:
	var most := Config.INTERIOR_REFEND + 0.06
	var oz0 := maxf(a.position.y, b.position.y)
	var oz1 := minf(a.end.y, b.end.y)
	var ox0 := maxf(a.position.x, b.position.x)
	var ox1 := minf(a.end.x, b.end.x)
	if oz1 - oz0 > EPS:
		for pair in [[a, b], [b, a]]:
			var p: Rect2 = pair[0]
			var q: Rect2 = pair[1]
			var gap := q.position.x - p.end.x
			if gap > EPS and gap <= most:
				return { "axis": "x", "at": p.end.x + gap * 0.5, "t": gap, "from": oz0, "to": oz1 }
	if ox1 - ox0 > EPS:
		for pair in [[a, b], [b, a]]:
			var p: Rect2 = pair[0]
			var q: Rect2 = pair[1]
			var gap := q.position.y - p.end.y
			if gap > EPS and gap <= most:
				return { "axis": "z", "at": p.end.y + gap * 0.5, "t": gap, "from": ox0, "to": ox1 }
	return {}


func _contact_of(a: int, b: int) -> Dictionary:
	for c: Dictionary in _contacts:
		if (c.a == a and c.b == b) or (c.a == b and c.b == a):
			return c
	return {}


func _neighbours(s: Dictionary) -> Array:
	var out := []
	for c: Dictionary in _contacts:
		if c.a == s.id:
			out.append(_space(c.b))
		elif c.b == s.id:
			out.append(_space(c.a))
	return out


func _fits(c: Dictionary) -> bool:
	return not c.is_empty() and float(c.to) - float(c.from) >= Config.INTERIOR_DOOR + 2.0 * Config.INTERIOR_JAMB - EPS


## Does the room face a way through (not the stair) along enough wall for a door?
func _on_way(s: Dictionary) -> bool:
	for n: Dictionary in _neighbours(s):
		if HousePlan.KINDS.get(n.kind, {}).get("circulation", false) and n.kind != "stair" and _fits(_contact_of(s.id, n.id)):
			return true
	return false


func _rooms() -> Array:
	var out := []
	for s: Dictionary in spaces:
		if s.kind == "":
			out.append(s)
	return out


# --- 4. What each room is ------------------------------------------------------------

func _program_home() -> String:
	var rooms := _rooms()
	var lit := []
	for s: Dictionary in rooms:
		if not s.carved and not (s.windows as Array).is_empty():
			lit.append(s)
	if lit.is_empty():
		return "no room has a window"
	var salon := {}
	for s: Dictionary in lit:
		if s.facing == "front" and (salon.is_empty() or float(s.area) > float(salon.area)):
			salon = s
	if salon.is_empty():
		salon = lit[0]
	# the kitchen: on the court, off the corridor, about 9 m²; the best that leaves every room reached
	var kitchens := []
	for s: Dictionary in lit:
		if s == salon:
			continue
		var score := (2.0 if s.facing == "back" else 0.0) + (3.0 if _on_way(s) else 0.0) 			- absf(float(s.area) - 9.0) * 0.15 + _rng.randf() * 0.5 - (5.0 if float(s.area) < 4.5 else 0.0)
		kitchens.append([score, s])
	kitchens.sort_custom(func(p: Array, q: Array): return float(p[0]) > float(q[0]))
	kitchens.append([0.0, {}])
	for k: Array in kitchens:
		for s: Dictionary in rooms:
			s.kind = ""
		salon.kind = "salon"
		_assign_home(rooms, lit, salon, k[1])
		if _graph_ok() and _sleeps(lit):
			return ""
		var kitchen: Dictionary = k[1]
		if kitchen.is_empty():
			continue
		for n: Dictionary in _neighbours(kitchen): # a room between the corridor and the kitchen eats there
			if n.kind == "chambre" and _on_way(n) and _fits(_contact_of(n.id, kitchen.id)):
				n.kind = "salle_a_manger"
				break
		if _graph_ok() and _sleeps(lit):
			return ""
	return "no arrangement of the rooms reaches them all and has a bedroom"


## A flat of three lit rooms or more has somewhere to sleep.
func _sleeps(lit: Array) -> bool:
	if lit.size() < 3:
		return true
	for s: Dictionary in lit:
		if s.kind == "chambre":
			return true
	return false


## Every room but the salon, given the kitchen: WC and salle d'eau in the dark (or carved) rooms
## off the corridor, box rooms in the rest, bedrooms (a cabinet when small) in the lit ones.
func _assign_home(rooms: Array, lit: Array, salon: Dictionary, kitchen: Dictionary) -> void:
	if not kitchen.is_empty():
		kitchen.kind = "cuisine"
	var dark := []
	var wc := false
	var bath := false
	for s: Dictionary in rooms:
		if s.carved:
			s.kind = "wc" if float(s.area) < 3.2 else "salle_d_eau"
			wc = wc or s.kind == "wc"
			bath = bath or s.kind == "salle_d_eau"
		elif (s.windows as Array).is_empty():
			dark.append(s)
	dark.sort_custom(func(p: Dictionary, q: Dictionary):
		var pw := _on_way(p)
		var qw := _on_way(q)
		return pw and not qw if pw != qw else float(p.area) < float(q.area))
	for s: Dictionary in dark:
		if not wc and (_on_way(s) or _corridor.is_empty()):
			s.kind = "wc"
			wc = true
		elif not bath and float(s.area) >= 2.4 and (_on_way(s) or _corridor.is_empty()) and _rng.randf() < 0.85:
			s.kind = "salle_d_eau"
			bath = true
		else:
			s.kind = "debarras"
	if not wc and not bath: # nowhere dark: the smallest room left becomes the salle d'eau
		var small := {}
		for s: Dictionary in lit:
			if s.kind == "" and float(s.area) < 7.5 and _on_way(s) and (small.is_empty() or float(s.area) < float(small.area)):
				small = s
		if not small.is_empty():
			small.kind = "salle_d_eau"
	var rest := []
	for s: Dictionary in lit:
		if s.kind == "":
			s.kind = "cabinet" if float(s.area) < 7.0 else "chambre"
			rest.append(s)
	var beds := 0
	for s: Dictionary in rest:
		beds += 1 if s.kind == "chambre" else 0
	if beds >= 2:
		for s: Dictionary in rest:
			if s.kind == "chambre" and s.facing == "front" and not _contact_of(s.id, salon.id).is_empty() and _rng.randf() < 0.45:
				s.kind = "salle_a_manger"
				break


## Could every space be reached under the door rules (_rank), walls long enough for a door and
## leaves aside? The stair opens onto the corridor, or with none onto one room (`_entry`, the first
## that reaches everything).
func _graph_ok() -> bool:
	var stair := _of_kind("stair")
	var entries := []
	if not _corridor.is_empty():
		entries = [_corridor]
	else:
		for k: String in ["cuisine", "salle_a_manger", "chambre", "salon", "cabinet"]:
			for n: Dictionary in _neighbours(stair):
				if n.kind == k and _fits(_contact_of(stair.id, n.id)):
					entries.append(n)
	for e: Dictionary in entries:
		if _fits(_contact_of(stair.id, e.id)) and _reaches_all(stair, e):
			_entry = e
			return true
	return false


func _reaches_all(stair: Dictionary, entry: Dictionary) -> bool:
	var got := { stair.id: true, entry.id: true }
	var todo := [entry]
	while not todo.is_empty():
		var at: Dictionary = todo.pop_back()
		for n: Dictionary in _neighbours(at):
			if got.has(n.id) or n.kind == "stair" or not _fits(_contact_of(at.id, n.id)) or _rank(n, at) < 0.0:
				continue
			got[n.id] = true
			todo.append(n)
	for s: Dictionary in spaces:
		if not got.has(s.id):
			return false
	return true


func _program_shop() -> String:
	var rooms := _rooms()
	var front := []
	for s: Dictionary in rooms:
		if s.facing == "front":
			front.append(s)
	if front.is_empty():
		return "no shop on the street"
	front.sort_custom(func(p: Dictionary, q: Dictionary): return float(p.area) > float(q.area))
	front[0].kind = "boutique"
	var allee := _of_kind("allee")
	for i in range(1, front.size()):
		var s: Dictionary = front[i]
		var by_allee := not allee.is_empty() and _fits(_contact_of(s.id, allee.id))
		s.kind = "loge" if by_allee and float(s.area) >= 5.0 and _of_kind("loge").is_empty() else "boutique"
		if s.kind == "loge": # the concierge's window is an ordinary one, not a shop's
			for wid: int in s.windows:
				var w := _window(wid)
				var c := (float(w.from) + float(w.to)) * 0.5
				w.from = c - Config.INTERIOR_WINDOW.x * 0.5
				w.to = c + Config.INTERIOR_WINDOW.x * 0.5
				w.kind = "casement"
				w.sill = Config.INTERIOR_CASEMENT.y
				w.head = minf(Config.INTERIOR_CASEMENT.z, _clear - 0.25)
	var wc := false
	for s: Dictionary in rooms:
		if s.kind != "":
			continue
		var shop_behind := false
		for n: Dictionary in _neighbours(s):
			shop_behind = shop_behind or n.kind == "boutique" and _fits(_contact_of(s.id, n.id))
		if (s.windows as Array).is_empty():
			if not wc and _on_way(s):
				s.kind = "wc"
				wc = true
			else:
				s.kind = "reserve"
		elif shop_behind:
			s.kind = "arriere_boutique"
		else:
			s.kind = "atelier" if float(s.area) > 14.0 else "remise"
	return ""


# --- 5. Doors ------------------------------------------------------------------------

func _connect() -> String:
	var joined := {}
	var stair := _of_kind("stair")
	joined[stair.id] = true
	for s: Dictionary in spaces: # a shop is reached from the street (its back door is an extra)
		if s.kind == "boutique":
			joined[s.id] = true
	if _ground:
		var allee := _of_kind("allee")
		if not _add_door(allee, stair, "arch", -1, "centre"):
			return "the allée does not reach the stair"
		joined[allee.id] = true
		if not _corridor.is_empty():
			if not _add_door(_corridor, stair, "arch", -1, "centre"):
				return "the passage does not reach the stair"
			joined[_corridor.id] = true
	elif not _corridor.is_empty():
		if not _add_door(stair, _corridor, "palier", _corridor.id, "deep"):
			return "the landing has no door to the flat"
		joined[_corridor.id] = true
		_corridor.main_door = doors[-1].id
	else: # a narrow house: the landing opens straight into a room
		var entry := _entry
		if entry.is_empty() or not _add_door(stair, entry, "palier", entry.id, "deep"):
			return "the landing opens into no room"
		joined[entry.id] = true
		entry.main_door = doors[-1].id
	var todo := []
	for s: Dictionary in spaces:
		if not joined.has(s.id):
			todo.append(s)
	var progress := true
	while progress and not todo.is_empty():
		progress = false
		todo.sort_custom(func(p: Dictionary, q: Dictionary): return _wet(p) and not _wet(q))
		for s: Dictionary in todo.duplicate():
			if _join(s, joined):
				joined[s.id] = true
				todo.erase(s)
				progress = true
	if not todo.is_empty():
		return "the %s %d cannot be reached" % [todo[0].kind, todo[0].id]
	return ""


func _wet(s: Dictionary) -> bool:
	return HousePlan.KINDS[s.kind].wet


## How willingly room `s` takes its door from neighbour `o` (below 0: never).
func _rank(s: Dictionary, o: Dictionary) -> float:
	var k: Dictionary = HousePlan.KINDS[o.kind]
	if o.kind == "stair" or _wet(o) or o.kind in ["debarras", "reserve"]: # nobody walks through a WC or a box room
		return -1.0
	if k.circulation:
		return 3.0
	if _wet(s):
		if s.kind == "salle_d_eau" and o.kind == "chambre":
			return 1.0
		return 0.5 if _corridor.is_empty() and o.kind != "salon" else -1.0
	if s.kind == "cuisine" or o.kind == "cuisine":
		var other: String = o.kind if s.kind == "cuisine" else s.kind
		return { "salle_a_manger": 2.5, "salon": 1.0, "cabinet": 0.6, "remise": 1.0 }.get(other, -1.0)
	match o.kind:
		"boutique":
			return 3.0 if s.kind in ["arriere_boutique", "reserve", "loge"] else 1.0
		"salon", "salle_a_manger":
			return 2.0
		"chambre":
			return 1.0
	return 0.8


func _join(s: Dictionary, joined: Dictionary) -> bool:
	var opts := []
	for n: Dictionary in _neighbours(s):
		if not joined.has(n.id):
			continue
		var rank := _rank(s, n)
		if rank >= 0.0:
			opts.append([rank + _rng.randf() * 0.3, n])
	opts.sort_custom(func(p: Array, q: Array): return float(p[0]) > float(q[0]))
	for o: Array in opts:
		if _add_door(o[1], s, "door", s.id, ""):
			s.main_door = doors[-1].id
			return true
	return false


## The doors no room needs but a house of the time has: enfilades along the street (near the
## windows), the kitchen to the dining room, the shop's back door.
func _extras() -> void:
	for c: Dictionary in _contacts:
		var a := _space(c.a)
		var b := _space(c.b)
		if _door_between(a.id, b.id):
			continue
		var chance := 0.0
		var prefer := ""
		if a.kind in LIVING and b.kind in LIVING and a.facing == b.facing and a.facing != "none":
			chance = Config.INTERIOR_ENFILADE if a.facing == "front" else Config.INTERIOR_ENFILADE * 0.5
			prefer = "facade"
		elif (a.kind == "cuisine" and b.kind == "salle_a_manger") or (b.kind == "cuisine" and a.kind == "salle_a_manger"):
			chance = 0.8
		elif (a.kind == "boutique" and HousePlan.KINDS[b.kind].circulation and b.kind != "stair") \
				or (b.kind == "boutique" and HousePlan.KINDS[a.kind].circulation and a.kind != "stair"):
			chance = 0.65
		if chance > 0.0 and _rng.randf() < chance:
			var into: Dictionary = b if float(b.area) <= float(a.area) else a
			if HousePlan.KINDS[into.kind].circulation:
				into = a if into == b else b
			_add_door(a, b, "door", into.id, prefer)


func _door_between(a: int, b: int) -> bool:
	for d: Dictionary in doors:
		if (d.a == a and d.b == b) or (d.a == b and d.b == a):
			return true
	return false


## The street door into the allée, the shop's own door in one of its bays, the court door at
## the end of the passage.
func _exterior_doors() -> void:
	if not _ground:
		return
	var allee := _of_kind("allee")
	var f := Config.INTERIOR_FACADE
	doors.append({ "id": doors.size(), "a": allee.id, "b": -1, "axis": "z", "at": -f * 0.5, "t": f,
		"from": _f.door[0], "to": _f.door[1], "height": minf(Config.INTERIOR_STREET_DOOR.y, _clear - 0.15),
		"kind": "street", "swing": allee.id, "hinge": _f.door[0] })
	allee.doors.append(doors[-1].id)
	allee.main_door = doors[-1].id
	for s: Dictionary in spaces:
		if s.kind != "boutique" or (s.windows as Array).is_empty():
			continue
		var ws: Array = s.windows.duplicate()
		ws.sort_custom(func(p: int, q: int): return float(_window(p).from) < float(_window(q).from))
		var pick: int = ws[ws.size() / 2] if ws.size() >= 3 else ws[0]
		if ws.size() == 2 and not allee.is_empty() and absf(float(_window(ws[1]).from) - (allee.rect as Rect2).end.x) < absf(float(_window(ws[0]).from) - (allee.rect as Rect2).end.x):
			pick = ws[1]
		var w := _window(pick)
		var c := (float(w.from) + float(w.to)) * 0.5
		var half := Config.INTERIOR_SHOP_DOOR.x * 0.5
		doors.append({ "id": doors.size(), "a": s.id, "b": -1, "axis": "z", "at": -f * 0.5, "t": f,
			"from": c - half, "to": c + half, "height": minf(Config.INTERIOR_SHOP_DOOR.y, _clear - 0.15),
			"kind": "shop", "swing": s.id, "hinge": c - half })
		s.doors.append(doors[-1].id)
		s.main_door = doors[-1].id
		_drop_window(w)
	if not _corridor.is_empty() and (_corridor.rect as Rect2).end.y >= _d - EPS:
		var r: Rect2 = _corridor.rect
		var c := r.get_center().x
		for wid: int in _corridor.windows.duplicate():
			c = (float(_window(wid).from) + float(_window(wid).to)) * 0.5
			_drop_window(_window(wid))
		var half := minf(Config.INTERIOR_COURT_DOOR.x, r.size.x - 2.0 * Config.INTERIOR_JAMB) * 0.5
		doors.append({ "id": doors.size(), "a": _corridor.id, "b": -2, "axis": "z", "at": _d + f * 0.5, "t": f,
			"from": c - half, "to": c + half, "height": minf(Config.INTERIOR_COURT_DOOR.y, _clear - 0.15),
			"kind": "court", "swing": _corridor.id, "hinge": c - half })
		_corridor.doors.append(doors[-1].id)


func _window(id: int) -> Dictionary:
	for w: Dictionary in windows:
		if w.id == id:
			return w
	return {}


func _drop_window(w: Dictionary) -> void:
	var s := _space(w.space)
	s.windows.erase(w.id)
	windows.erase(w)


## Put a door of `kind` in the wall between a and b, the leaf swinging into `swing` (-1: an
## opening without one). Near one corner of the wall, unless `prefer` says otherwise ("centre",
## "facade": the end nearest the windows); never where its leaf would meet another's.
func _add_door(a: Dictionary, b: Dictionary, kind: String, swing: int, prefer: String) -> bool:
	var c := _contact_of(a.id, b.id)
	if c.is_empty():
		return false
	var lo := float(c.from) + Config.INTERIOR_JAMB
	var hi := float(c.to) - Config.INTERIOR_JAMB
	var w := Config.INTERIOR_DOOR
	if kind == "palier":
		w = Config.INTERIOR_DOOR + 0.05
	elif kind == "arch":
		w = clampf(hi - lo, Config.INTERIOR_DOOR, 1.4)
	if hi - lo < w - EPS:
		return false
	var room := hi - lo - w
	var j := minf(_rng.randf_range(0.0, 0.3), room)
	var near_lo := lo + j
	var near_hi := hi - w - j
	var middle := lo + room * 0.5
	var order := [near_lo, near_hi] if _rng.randf() < 0.5 else [near_hi, near_lo]
	if prefer == "centre":
		order = [middle]
	elif prefer == "deep": # as far into the house as the wall allows, clear of the corridor's first doorway
		order = [hi - w, lo]
	elif prefer == "facade":
		var facing: String = a.facing
		order = [near_lo, near_hi] if (c.axis == "z" or facing == "front") else [near_hi, near_lo]
	order.append(middle)
	for p: float in order:
		var d := { "id": doors.size(), "a": a.id, "b": b.id, "axis": c.axis, "at": c.at, "t": c.t,
			"from": p, "to": p + w, "kind": kind, "swing": swing,
			"height": minf(_clear - 0.3, 2.3) if kind == "arch" else Config.INTERIOR_DOOR_HEIGHT,
			"hinge": p if p - float(c.from) <= float(c.to) - (p + w) else p + w }
		if _clashes(d):
			continue
		doors.append(d)
		a.doors.append(d.id)
		b.doors.append(d.id)
		return true
	return false


## Would door d stand on another, or its leaf sweep over another's?
func _clashes(d: Dictionary) -> bool:
	for e: Dictionary in doors:
		if e.axis == d.axis and absf(float(e.at) - float(d.at)) < 0.35 \
				and float(e.from) < float(d.to) + 0.25 and float(d.from) < float(e.to) + 0.25:
			return true
		for id: int in [d.a, d.b]:
			if id < 0 or not (id == e.a or id == e.b):
				continue
			# a leaf may not sweep over another leaf or across another doorway; stepping through
			# where a leaf swings is what corridors are for
			var r: Rect2 = _space(id).rect
			var dz := RoomDressing.swing_rect(d, r) if d.swing == id else RoomDressing.doorway(d, r)
			var ez := RoomDressing.swing_rect(e, r) if e.swing == id else RoomDressing.doorway(e, r)
			if (d.swing == id or e.swing == id) and dz.grow(-EPS).intersects(ez.grow(-EPS)):
				return true
	return false


# --- 6. Paint, lamps, furniture ------------------------------------------------------------

func _dress(last: bool) -> String:
	var paint_rng := RandomNumberGenerator.new()
	paint_rng.seed = hash([int(_spec.seed), "paint", level])
	var scheme := RoomDressing.scheme(paint_rng, level)
	var ctx := { "doors": doors, "windows": windows, "flues": _f.flues, "width": _w, "depth": _d,
		"clear": _clear, "level": level, "scheme": scheme }
	for s: Dictionary in spaces:
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([int(_spec.seed), "dress", level, s.id, tries])
		var missing := RoomDressing.dress(s, ctx, rng)
		if missing != "" and not last:
			return "the %s has no room for its %s" % [s.kind, missing]
	return ""
