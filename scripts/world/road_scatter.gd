class_name RoadScatter
## Puts RoadProps (and a few Props) on the city's roads: what an emptied town has lying in its
## streets. Two passes, each with its own fixed seed so every peer builds the same road:
##
##   hill_road   the road up Morro da Boa Vista, from the list in references/mirante_elements.md
##               ("Road scatter"): HILL says what stands where, as a distance up the road from
##               the gate (`m` metres or `f` of the climb), at the sharp bend nearest a fraction
##               (`bend`), or at the hairpin, moved on by `ahead` metres; `side` is across the
##               road (-1 the left kerb going up, 1 the right, where the brick lane is; at a bend
##               + is the outside), `yaw` degrees turned left from facing uphill. Then
##               dropped things sprinkled along the brick lane (HILL_LITTER_*).
##   streets     abandoned cars, bins and rubbish along the avenues of the flat city, every
##               STREETS_EVERY metres with a chance, never in a junction, near a POI or on a
##               cell a set piece already took.
##
## The hill road is one lane each way (two nav cells), so its props never close cells: their
## solid parts collide (`_put_free`) and keep to one side, leaving a lane open. On an avenue a car
## at the kerb closes the cells under it like any other prop. To change what's on the hill, edit
## HILL; every kind is in `_draw`.

const HILL := [
	# At the gate: the Guarda Municipal got this far.
	{ "kind": "guarda_bike", "m": 7.0, "side": 0.55, "yaw": 150.0 },
	{ "kind": "cone", "m": 4.0, "side": -0.3 },
	{ "kind": "cone", "m": 5.5, "side": 0.1 },
	{ "kind": "litter", "m": 10.0, "side": 0.6, "count": 4 },
	# The first stretch: a hatchback, a car that slid into the rail on the first bend.
	{ "kind": "hatchback", "f": 0.04, "side": -0.6, "yaw": 8.0, "doors": 1 },
	{ "kind": "slid_car", "bend": 0.07, "side": 0.72, "yaw": -38.0 },
	{ "kind": "bicycles", "f": 0.1, "side": 0.8, "yaw": 80.0 },
	# The bus line's minibus, stopped where its passengers got off running.
	{ "kind": "minibus", "f": 0.15, "side": -0.45, "yaw": -4.0 },
	{ "kind": "litter", "f": 0.15, "side": 0.55, "count": 7, "ahead": 6.0 },
	{ "kind": "bin", "f": 0.19, "side": 1.15 },
	{ "kind": "bicycles", "f": 0.23, "side": 0.85, "yaw": 100.0 },
	# A tree down across the left half, a snapped pole on the right: one lane is left between them.
	{ "kind": "fallen_tree", "f": 0.31, "side": -1.15, "yaw": -78.0, "length": 5.5 },
	{ "kind": "snapped_pole", "f": 0.31, "ahead": 14.0, "side": 1.15, "yaw": 160.0 },
	{ "kind": "hatchback", "f": 0.36, "side": 0.55, "yaw": 172.0, "doors": 2 },
	{ "kind": "cone", "f": 0.37, "side": 0.1 },
	{ "kind": "bicycles", "f": 0.4, "side": 0.85, "yaw": 70.0 },
	# Halfway: a taxi with its passengers gone, rubbish bins knocked over.
	{ "kind": "taxi", "f": 0.49, "side": 0.5, "yaw": -12.0 },
	{ "kind": "litter", "f": 0.49, "ahead": -5.0, "side": 0.6, "count": 5 },
	{ "kind": "bin", "f": 0.55, "side": -1.15, "wheelie": true },
	{ "kind": "blood_trail", "f": 0.58, "side": -1.0, "yaw": -100.0, "length": 6.0 },
	# The patrol car across the road, cones where it tried to close it.
	{ "kind": "patrol_car", "f": 0.66, "side": -0.4, "yaw": -72.0 },
	{ "kind": "cone", "f": 0.66, "ahead": -3.0, "side": 0.6 },
	{ "kind": "cone", "f": 0.66, "ahead": -3.5, "side": 0.25 },
	{ "kind": "pare", "f": 0.67, "side": 0.5, "yaw": 20.0 },
	{ "kind": "blood_trail", "f": 0.7, "side": 1.0, "yaw": 100.0, "length": 6.0 },
	# Benches dragged down from the viewpoint into a barricade across half the road, below the hairpin.
	{ "kind": "barricade", "f": 0.76, "side": -0.45, "width": 5.6 },
	{ "kind": "litter", "f": 0.76, "ahead": -4.0, "side": 0.5, "count": 3 },
	# The hairpin, where the checkpoint is: the dead carried there, and the ones dragged away.
	{ "kind": "bodybags", "at": "hairpin", "ahead": -9.0, "side": -0.6, "yaw": 85.0 },
	{ "kind": "blood_trail", "at": "hairpin", "ahead": -6.0, "side": -1.0, "yaw": -90.0, "length": 7.0 },
	{ "kind": "blood_trail", "at": "hairpin", "ahead": 8.0, "side": 1.0, "yaw": 95.0, "length": 9.0 },
	{ "kind": "pare", "at": "hairpin", "ahead": 10.0, "side": -0.3, "yaw": 30.0 },
	{ "kind": "cone", "at": "hairpin", "ahead": 11.0, "side": 0.2 },
	# The last climb.
	{ "kind": "hatchback", "f": 0.88, "side": -0.55, "yaw": 4.0, "doors": 2 },
	{ "kind": "bicycles", "f": 0.9, "side": 0.85, "yaw": 70.0 },
	# The viewpoint bend near the top: a bench still facing the view, bins knocked over.
	{ "kind": "bench", "bend": 0.925, "side": 0.8, "yaw": -90.0 },
	{ "kind": "bin", "bend": 0.925, "ahead": 3.0, "side": 0.9 },
	{ "kind": "bin", "bend": 0.925, "ahead": -4.0, "side": -0.85, "wheelie": true },
	{ "kind": "litter", "bend": 0.925, "ahead": -3.0, "side": 0.6, "count": 4 },
]
const HILL_LITTER_EVERY := 9.0    ## metres between chances of something dropped on the brick lane
const HILL_LITTER_CHANCE := 0.3
const HILL_SHARP_BEND := 0.35     ## radians: a bend sharper than this has a guard rail (CityMap._hill_road uses _bends too)
## Places the hill's props keep clear of (CityData pixels, as MapAreas.mirante has them): the
## checkpoint's tent at the hairpin and the zombie closets on the road. Only solid props mind.
const HILL_KEEP_CLEAR := [Vector2(1806, -96), Vector2(1818, -27), Vector2(1823, 33)]
const HILL_KEEP_RADIUS := 5.0

const SEAT_PITCH := 0.2           ## steepest a prop leans along the road (rise over run)
const SEAT_ROLL := 0.06           ## and across it

const STREETS_EVERY := 34.0       ## metres between chances of something on an avenue
const STREETS_CHANCE := 0.45
const STREETS_JUNCTION := 14.0    ## nothing this close to a street's own corner points
const STREETS_POI := 45.0         ## nor this close to a POI


# --- The road up Morro da Boa Vista -----------------------------------------------------------

static func hill_road(map: CityMap) -> void:
	if not map.mirante.has("gate"):
		return
	var line := map.hill_line
	var width := map.hill_width
	var total := map.hill_length
	var gate: Vector3 = map.mirante.gate
	var start := _distance_along(line, Vector2(gate.x, gate.z))
	var climb := total - 4.0 - start
	var hairpin := _distance_along(line, _flat(CityData.to_world(Vector2(1808, -90))))
	var bends := _bends(map.hill_corners, line, start)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19870416
	for e: Dictionary in HILL:
		var d := start
		var side: float = e.get("side", 0.0)
		var yaw: float = e.get("yaw", 0.0)
		if e.has("m"):
			d = start + float(e.m)
		elif e.has("f"):
			d = start + climb * float(e.f)
		elif e.get("at", "") == "hairpin":
			d = hairpin
		elif e.has("bend"):
			if bends.is_empty():
				continue
			var bend: Array = bends[0]
			for c: Array in bends: # the bend nearest that far up
				if absf(c[0] - start - climb * float(e.bend)) < absf(bend[0] - start - climb * float(e.bend)):
					bend = c
			d = bend[0]
			side *= bend[1] # at a bend, + is the outside (where the rail is) and yaw turns towards it
			yaw *= bend[1]
		d += float(e.get("ahead", 0.0))
		if d < start - 12.0 or d > total - 4.0:
			continue
		var p := map.hill_at(d) + map.hill_right(d) * side * width * 0.5
		var h := map.hill_heading(d)
		var face := Vector2(h.x, h.y).rotated(-deg_to_rad(yaw))
		if _solid_kind(e.kind) and _near_keep_clear(p):
			continue
		var t := _seat(map, p, face, _footprint(e.kind))
		_draw(map, e, t, rng, false)
	# Things dropped along the brick lane all the way up.
	var k := start + 14.0
	while k < total - 10.0:
		k += HILL_LITTER_EVERY
		if rng.randf() > HILL_LITTER_CHANCE:
			continue
		var p := map.hill_at(k) + map.hill_right(k) * (width * 0.5 - 1.1 + rng.randf_range(-0.5, 0.5))
		var t := _seat(map, p, map.hill_heading(k).rotated(rng.randf() * TAU), 0.5)
		var kind := ["litter", "litter", "flip_flops", "bottle", "backpack", "phone"][rng.randi() % 6] as String
		_draw(map, { "kind": kind, "count": rng.randi_range(1, 3) }, t, rng, false)


# --- Avenues of the flat city -----------------------------------------------------------------

static func streets(map: CityMap) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 18510310
	var pois := []
	for id: String in CityData.POIS:
		pois.append(_flat(map.poi_pos(id)))
	for street: Dictionary in CityData.STREETS:
		if street.kind != "principale": # the main streets only (where the bus routes run)
			continue
		var width := CityData.width(street)
		var line: PackedVector2Array = map._plan(street.pts)
		var total := _length(line)
		var d := STREETS_EVERY * 0.5
		while d < total - STREETS_EVERY * 0.5:
			d += STREETS_EVERY * rng.randf_range(0.7, 1.3)
			if rng.randf() > STREETS_CHANCE:
				continue
			var p0 := map._along(line, d)
			if _near_any(p0, line, STREETS_JUNCTION) or _near_list(p0, pois, STREETS_POI):
				continue
			var side := 1.0 if rng.randf() < 0.5 else -1.0
			var h := map._heading(line, d)
			var roll := rng.randf()
			var e := {}
			if roll < 0.55:
				e = { "kind": "hatchback", "doors": rng.randi_range(0, 2), "paint": rng.randi() }
			elif roll < 0.7:
				e = { "kind": "car", "paint": rng.randi(), "burnt": rng.randf() < 0.35 }
			elif roll < 0.82:
				e = { "kind": "bin", "wheelie": rng.randf() < 0.6 }
			elif roll < 0.92:
				e = { "kind": "litter", "count": rng.randi_range(3, 6) }
			else:
				e = { "kind": "motorbike", "paint": rng.randi() }
			var off := width * 0.5 - (2.4 if _solid_kind(e.kind) else 1.5)
			var p := p0 + map._right(line, d) * side * off
			var face := h.rotated(deg_to_rad(rng.randf_range(-12.0, 12.0)) + (PI if side < 0.0 and rng.randf() < 0.7 else 0.0))
			if not _clear_street(map, p, face, _footprint(e.kind)):
				continue
			_draw(map, e, _seat(map, p, face, _footprint(e.kind)), rng, true)


# --- Drawing one ------------------------------------------------------------------------------

## Draws the prop `e.kind` at `t`. With `close` its solid parts close the cells under them
## (CityMap._put); otherwise they only collide (_put_free).
static func _draw(map: CityMap, e: Dictionary, t: Transform3D, rng: RandomNumberGenerator, close: bool) -> void:
	var b: MeshKit.Builder = map._b
	var kind: String = e.kind
	var solid := []
	match kind:
		"hatchback":
			var paint: Color = RoadProps.PAINTS[int(e.get("paint", rng.randi())) % RoadProps.PAINTS.size()]
			solid = RoadProps.hatchback(b, t, paint, e.get("doors", 1))
		"car":
			var paint: Color = RoadProps.PAINTS[int(e.get("paint", rng.randi())) % RoadProps.PAINTS.size()]
			solid = Props.car(b, t, paint, e.get("burnt", false))
		"slid_car":
			var paint: Color = RoadProps.PAINTS[rng.randi() % RoadProps.PAINTS.size()]
			solid = RoadProps.hatchback(b, t, paint, 1, 0.06)
			RoadProps.rubbish(b, t * Transform3D(Basis.IDENTITY, Vector3(0, 0, -2.6)), 3, rng) # bits of its front
		"taxi":
			solid = RoadProps.taxi(b, t)
		"minibus":
			solid = RoadProps.minibus(b, t)
		"patrol_car":
			solid = RoadProps.patrol_car(b, t, map._glow)
		"guarda_bike":
			solid = RoadProps.motorbike(b, t, RoadProps.GUARDA_BLUE, true, false)
		"motorbike":
			solid = RoadProps.motorbike(b, t, RoadProps.PAINTS[int(e.get("paint", 0)) % RoadProps.PAINTS.size()], false, true)
		"bicycles":
			for i in rng.randi_range(1, 2):
				var at := t * Transform3D(Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)), Vector3(rng.randf_range(-0.4, 0.4), 0, i * 1.4))
				RoadProps.bicycle(b, at, RoadProps.STUFF[rng.randi() % RoadProps.STUFF.size()])
		"fallen_tree":
			solid = RoadProps.fallen_tree(b, t, e.get("length", 6.0), rng)
		"snapped_pole":
			solid = RoadProps.snapped_pole(b, t, rng)
		"barricade":
			solid = RoadProps.bench_barricade(b, t, e.get("width", 4.0), rng)
		"bench":
			solid = RoadProps.bench(b, t)
		"bin":
			solid = RoadProps.bin(b, t, e.get("wheelie", false), rng)
		"pare":
			RoadProps.pare_board(b, t)
		"cone":
			Props.cone(b, t)
		"bodybags":
			Props.bodybag(b, t)
			Props.bodybag(b, t * Transform3D(Basis(Vector3.UP, 0.2), Vector3(0.9, 0, 0.3)), Color("2a2e24"))
		"blood_trail":
			RoadProps.blood_trail(map._g, t, e.get("length", 6.0), rng, func(p: Vector3) -> float: return map.ground_y(p))
		"litter":
			RoadProps.litter(b, t, e.get("count", 3), rng, map._glow)
		"flip_flops":
			RoadProps.flip_flops(b, t, RoadProps.STUFF[rng.randi() % RoadProps.STUFF.size()])
		"bottle":
			RoadProps.bottle(b, t)
		"backpack":
			RoadProps.backpack(b, t, RoadProps.STUFF[rng.randi() % RoadProps.STUFF.size()])
		"phone":
			RoadProps.phone(b, t, rng.randf() < 0.4, map._glow)
		_:
			push_warning("RoadScatter: no prop called %s" % kind)
			return
	if close:
		map._put(solid, t)
	else:
		map._put_free(solid, t)
	map.prop_counts[kind] = map.prop_counts.get(kind, 0) + 1


static func _solid_kind(kind: String) -> bool:
	return kind in ["hatchback", "car", "slid_car", "taxi", "minibus", "patrol_car", "fallen_tree", "snapped_pole",
		"barricade", "bench", "bin"]


## Half the length of a prop, for seating it on the slope (front and back on the ground).
static func _footprint(kind: String) -> float:
	match kind:
		"minibus": return 3.6
		"hatchback", "car", "slid_car", "taxi", "patrol_car": return 2.0
		"fallen_tree", "snapped_pole": return 3.0
		"barricade": return 1.2
	return 0.6


# --- Placing ------------------------------------------------------------------------------------

## A transform at (x, z) `p` facing `face` (x, z), on the ground and tilted with it: the slope
## along the prop is read `reach` metres ahead and behind, across it a metre either side.
static func _seat(map: CityMap, p: Vector2, face: Vector2, reach: float) -> Transform3D:
	var f := face.normalized()
	var r := Vector2(-f.y, f.x)
	var g := func(q: Vector2) -> float: return map.ground_y(Vector3(q.x, 0, q.y))
	# The ground is a 4 m grid: across a narrow prop it can kink, so tilt is held to SEAT_PITCH / SEAT_ROLL.
	var pitch := clampf((g.call(p + f * reach) - g.call(p - f * reach)) / (2.0 * reach), -SEAT_PITCH, SEAT_PITCH)
	var roll := clampf((g.call(p + r) - g.call(p - r)) / 2.0, -SEAT_ROLL, SEAT_ROLL)
	var fwd := Vector3(f.x, pitch, f.y).normalized()
	var right := Vector3(r.x, roll, r.y).normalized()
	var up := right.cross(fwd).normalized()
	right = fwd.cross(up).normalized()
	return Transform3D(Basis(right, up, -fwd), Vector3(p.x, g.call(p) - 0.03, p.y))


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


static func _length(line: PackedVector2Array) -> float:
	var total := 0.0
	for i in line.size() - 1:
		total += line[i].distance_to(line[i + 1])
	return total


## How far along `line` its closest point to `p` is.
static func _distance_along(line: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	var best_d := 0.0
	var walked := 0.0
	for i in line.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])
		if q.distance_to(p) < best:
			best = q.distance_to(p)
			best_d = walked + line[i].distance_to(q)
		walked += line[i].distance_to(line[i + 1])
	return best_d


## The sharp bends past `from` metres along `line` (the smoothed road), found at the `corners`
## it was smoothed through: [distance along line, side of the outside (-1 left, 1 right)].
static func _bends(corners: PackedVector2Array, line: PackedVector2Array, from: float) -> Array:
	var out := []
	for i in range(1, corners.size() - 1):
		var turn := (corners[i] - corners[i - 1]).normalized().angle_to((corners[i + 1] - corners[i]).normalized())
		if absf(turn) < HILL_SHARP_BEND:
			continue
		var walked := _distance_along(line, corners[i])
		if walked >= from:
			out.append([walked, -1.0 if turn > 0.0 else 1.0]) # turning right (+ here): the outside is the left
	return out


static func _near_keep_clear(p: Vector2) -> bool:
	for px: Vector2 in HILL_KEEP_CLEAR:
		if _flat(CityData.to_world(px)).distance_to(p) < HILL_KEEP_RADIUS:
			return true
	return false


static func _near_list(p: Vector2, points: Array, radius: float) -> bool:
	for q: Vector2 in points:
		if q.distance_to(p) < radius:
			return true
	return false


## Near one of the line's own corner points (where streets meet, since they share them), or its ends.
static func _near_any(p: Vector2, line: PackedVector2Array, radius: float) -> bool:
	for q in line:
		if q.distance_to(p) < radius:
			return true
	return false


## Every cell under a prop of half length `reach` at `p` facing `face` is open street.
static func _clear_street(map: CityMap, p: Vector2, face: Vector2, reach: float) -> bool:
	var f := face.normalized()
	var r := Vector2(-f.y, f.x)
	for q: Vector2 in [p, p + f * reach, p - f * reach, p + r * 1.2, p - r * 1.2, p + f * reach + r * 1.2, p - f * reach - r * 1.2]:
		if map.type_at(Vector3(q.x, 0, q.y)) != CityMap.STREET:
			return false
	return true
