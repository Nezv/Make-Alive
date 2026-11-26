class_name InteriorBuilder
extends RefCounted
## A HousePlan built (S244): per floor, the walls (everything inside the house's outline that is no
## space, no door and no window, from the floor to the next one), each room's paint on its own
## faces of them (dado, wallpaper, cornice), the floors and ceilings in their colours, the slab
## with the stair's well cut out, the stair's treads and landings, the door leaves standing open,
## the furniture slots as plain blocks of their real size, and a light at every lamp.
## A blockout to judge the layout by: walls, doors and furniture become elements (S191-S194).
##
## Nodes: house / floor_<n> (at the floor's height) / walls, floor, ceiling (apart, so a rack can
## take it off to look in from above), furniture, lamps, lights (one OmniLight3D per lamp) and
## collision (a StaticBody3D on Config.LAYER_WORLD: boxes for walls and slabs, ramps for flights).
## Plan x, z are the node's x, z; the street facade's inner face is z = 0.

const CORE := Color("8d8579")       ## the wall's own core: reveals and jambs
const SLAB := Color("6f675c")
const TREAD := Color("6b4f3b")
const RAIL := Color("2e2a26")
const LEAF := { "door": Color("d6cfbd"), "palier": Color("5a3f2c"), "street": Color("3d2c22"), "shop": Color("2f4a3e"), "court": Color("4a3a2c") }
const WOOD := Color("6e4b32")
const ITEMS := { "lit": Color("c2b49a"), "canape": Color("6f4f45"), "fauteuil": Color("7a5a4c"), "piano": Color("231e1b"),
	"cheminee": Color("d9d3c6"), "cuisiniere": Color("2e2d2c"), "evier": Color("bdb7a9"), "plan": Color("9a7a55"),
	"cuvette": Color("ecebe5"), "lave_mains": Color("ecebe5"), "lavabo": Color("ecebe5"), "baignoire": Color("e6e4dc"),
	"vitrine": Color("9fb3b8"), "caisse": Color("8a7150"), "etabli": Color("7a5c3a"), "etagere": Color("8b6d4c"),
	"chevet": Color("5e3f2a"), "armoire": Color("4f3423"), "bibliotheque": Color("4a3222"), "comptoir": Color("4b3424") }
const SKIN := 0.006
const LEAF_OPEN := 1.3  ## radians the leaves stand open


static func build(plan: HousePlan) -> Node3D:
	var root := Node3D.new()
	root.name = "house"
	for f: Dictionary in plan.floors:
		root.add_child(_floor(plan, f))
	return root


static func _lin(c: Color) -> Color:
	return c.srgb_to_linear()


static func _floor(plan: HousePlan, f: Dictionary) -> Node3D:
	var node := Node3D.new()
	node.name = "floor_%d" % f.level
	node.position.y = f.y
	var body := StaticBody3D.new()
	body.name = "collision"
	body.collision_layer = Config.LAYER_WORLD
	body.collision_mask = 0
	var walls := MeshKit.Builder.new()
	var floor_b := MeshKit.Builder.new()
	var ceiling := MeshKit.Builder.new()
	var furniture := MeshKit.Builder.new()
	var lamps := MeshKit.Builder.new()
	var below: Dictionary = plan.floors[f.level - 1] if f.level > 0 else {}
	_walls(plan, f, below, walls, body)
	_slab(plan, f, floor_b, body)
	_rooms(plan, f, walls, floor_b, ceiling)
	_leaves(f, walls)
	_stair(plan, f, walls, body)
	if f.level == plan.floors.size() - 1: # the top floor's ceiling closes the house (the attic is not built)
		var inside := Rect2(0, 0, plan.width, plan.depth)
		_box(ceiling, body, inside, plan.clear, plan.storey, SLAB)
	for s: Dictionary in f.spaces:
		for it: Dictionary in s.furniture:
			var r: Rect2 = it.rect
			var col: Color = ITEMS.get(it.item, WOOD)
			furniture.box(Vector3(r.size.x, it.height, r.size.y), Vector3(r.get_center().x, float(it.height) * 0.5, r.get_center().y), _lin(col))
	var lights := Node3D.new()
	lights.name = "lights"
	for s: Dictionary in f.spaces:
		for l: Dictionary in s.lights:
			var p: Vector3 = l.pos
			var omni := OmniLight3D.new()
			omni.position = p - Vector3(0, 0.12, 0)
			omni.omni_range = l.range
			omni.light_energy = l.energy
			omni.light_color = l.colour
			omni.shadow_enabled = false
			lights.add_child(omni)
			var size: Vector3 = { "lustre": Vector3(0.5, 0.35, 0.5), "suspension": Vector3(0.35, 0.22, 0.35), "applique": Vector3(0.12, 0.22, 0.1) }.get(l.kind, Vector3(0.3, 0.06, 0.3))
			lamps.box(size, p - Vector3(0, size.y * 0.5, 0), _lin(l.colour))
			if l.kind == "lustre" or l.kind == "suspension": # the cord to the ceiling rose
				var top := plan.clear
				lamps.box(Vector3(0.02, top - p.y, 0.02), Vector3(p.x, (top + p.y) * 0.5, p.z), Color(0.1, 0.1, 0.1))
	for pair in [["walls", walls, null], ["floor", floor_b, null], ["ceiling", ceiling, null],
			["furniture", furniture, null], ["lamps", lamps, MeshKit.unshaded(Color(1.0, 0.9, 0.7))]]:
		var mi: MeshInstance3D = (pair[1] as MeshKit.Builder).instance(pair[2])
		mi.name = pair[0]
		node.add_child(mi)
	node.add_child(lights)
	node.add_child(body)
	return node


## A solid box over rect from y0 to y1, drawn and collided.
static func _box(b: MeshKit.Builder, body: StaticBody3D, r: Rect2, y0: float, y1: float, col: Color) -> void:
	if r.size.x <= 0.001 or r.size.y <= 0.001 or y1 - y0 <= 0.001:
		return
	var size := Vector3(r.size.x, y1 - y0, r.size.y)
	var at := Vector3(r.get_center().x, (y0 + y1) * 0.5, r.get_center().y)
	b.box(size, at, _lin(col))
	if body:
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		cs.position = at
		body.add_child(cs)


# --- Walls --------------------------------------------------------------------------

## The plan region of a door (the gap through its wall) or a window (through the facade).
static func door_rect(d: Dictionary) -> Rect2:
	var half := float(d.t) * 0.5
	if d.axis == "x":
		return Rect2(float(d.at) - half, d.from, float(d.t), float(d.to) - float(d.from))
	return Rect2(d.from, float(d.at) - half, float(d.to) - float(d.from), float(d.t))


static func window_rect(plan: HousePlan, w: Dictionary) -> Rect2:
	var f := Config.INTERIOR_FACADE
	var z := -f if w.side == "front" else plan.depth
	return Rect2(w.from, z, float(w.to) - float(w.from), f)


## Everything inside the outline that is not a space, cut round doors and windows: the plane cut
## at every edge, each cell's solid heights worked out, cells that agree merged into boxes.
static func _walls(plan: HousePlan, f: Dictionary, below: Dictionary, b: MeshKit.Builder, body: StaticBody3D) -> void:
	var p := Config.INTERIOR_PARTY
	var fa := Config.INTERIOR_FACADE
	var foot := Rect2(-p, -fa, plan.width + 2.0 * p, plan.depth + 2.0 * fa)
	var top := plan.storey
	var rooms := []
	for s: Dictionary in f.spaces:
		rooms.append_array(s.rects)
	var opens := [] # [Rect2, y0, y1]
	for d: Dictionary in f.doors:
		opens.append([door_rect(d), 0.0, float(d.height)])
	for w: Dictionary in f.windows:
		opens.append([window_rect(plan, w), float(w.sill), minf(float(w.head), top)])
	if not below.is_empty(): # a window of the floor below that rises past this floor's line (the stair's)
		for w: Dictionary in below.windows:
			if float(w.head) > top:
				opens.append([window_rect(plan, w), maxf(float(w.sill) - top, 0.0), float(w.head) - top])
	var xs := [foot.position.x, foot.end.x]
	var zs := [foot.position.y, foot.end.y]
	for r: Rect2 in rooms:
		xs.append_array([r.position.x, r.end.x])
		zs.append_array([r.position.y, r.end.y])
	for o: Array in opens:
		var r: Rect2 = o[0]
		xs.append_array([r.position.x, r.end.x])
		zs.append_array([r.position.y, r.end.y])
	xs = HousePlan._unique(xs)
	zs = HousePlan._unique(zs)
	var nx := xs.size() - 1
	var nz := zs.size() - 1
	var keys := []
	keys.resize(nx * nz)
	var solid := {}
	for j in nz:
		for i in nx:
			var c := Vector2((xs[i] + xs[i + 1]) * 0.5, (zs[j] + zs[j + 1]) * 0.5)
			var key := ""
			var inside := foot.has_point(c)
			for r: Rect2 in rooms:
				if r.has_point(c):
					inside = false
					break
			if inside:
				var gaps := []
				for o: Array in opens:
					if (o[0] as Rect2).has_point(c):
						gaps.append([o[1], o[2]])
				var spans := _minus([[0.0, top]], gaps)
				key = JSON.stringify(spans)
				solid[key] = spans
			keys[j * nx + i] = key
	var done := PackedByteArray()
	done.resize(nx * nz)
	for j in nz:
		for i in nx:
			var key: String = keys[j * nx + i]
			if key == "" or done[j * nx + i] == 1:
				continue
			var i1 := i
			while i1 + 1 < nx and keys[j * nx + i1 + 1] == key and done[j * nx + i1 + 1] == 0:
				i1 += 1
			var j1 := j
			while j1 + 1 < nz:
				var same := true
				for k in range(i, i1 + 1):
					if keys[(j1 + 1) * nx + k] != key or done[(j1 + 1) * nx + k] == 1:
						same = false
						break
				if not same:
					break
				j1 += 1
			for jj in range(j, j1 + 1):
				for k in range(i, i1 + 1):
					done[jj * nx + k] = 1
			var r := Rect2(xs[i], zs[j], xs[i1 + 1] - xs[i], zs[j1 + 1] - zs[j])
			for span: Array in solid[key]:
				_box(b, body, r, span[0], span[1], CORE)


## Intervals [a, b] less the gaps.
static func _minus(spans: Array, gaps: Array) -> Array:
	var out := spans
	for g: Array in gaps:
		var next := []
		for s: Array in out:
			var a: float = s[0]
			var bb: float = s[1]
			var g0: float = g[0]
			var g1: float = g[1]
			if g1 <= a or g0 >= bb:
				next.append(s)
				continue
			if g0 > a + 0.001:
				next.append([a, g0])
			if g1 < bb - 0.001:
				next.append([g1, bb])
		out = next
	return out


## The floor under this one's rooms, with the stair's well open over the flights below.
static func _slab(plan: HousePlan, f: Dictionary, b: MeshKit.Builder, body: StaticBody3D) -> void:
	var inside := Rect2(0, 0, plan.width, plan.depth)
	var holes := []
	if f.level > 0:
		var cage: Rect2 = plan.frame.cage
		var palier: Rect2 = plan.frame.palier
		holes.append(Rect2(cage.position.x, palier.end.y, cage.size.x, cage.end.y - palier.end.y))
	for r: Rect2 in HousePlan.free_rects(inside, holes):
		_box(b, body, r, -Config.INTERIOR_SLAB, 0.0, SLAB)


# --- Paint ---------------------------------------------------------------------------

## Each space's floor, ceiling and its own faces of the walls round it, in its paint.
static func _rooms(plan: HousePlan, f: Dictionary, walls: MeshKit.Builder, floor_b: MeshKit.Builder, ceiling: MeshKit.Builder) -> void:
	var clear := plan.clear
	var opens := []
	for d: Dictionary in f.doors:
		opens.append([door_rect(d), 0.0, float(d.height)])
	for w: Dictionary in f.windows:
		opens.append([window_rect(plan, w), float(w.sill), minf(float(w.head), clear)])
	for s: Dictionary in f.spaces:
		var paint: Dictionary = s.paint
		var r: Rect2 = s.rect
		var floor_col: Color = paint.floor_colour
		var stair: bool = s.kind == "stair"
		if not stair or f.level == 0:
			floor_b.box(Vector3(r.size.x, 0.01, r.size.y), Vector3(r.get_center().x, 0.005, r.get_center().y), _lin(floor_col))
		elif stair: # the landing only: the well is open
			var pal: Rect2 = plan.frame.palier
			floor_b.box(Vector3(pal.size.x, 0.01, pal.size.y), Vector3(pal.get_center().x, 0.005, pal.get_center().y), _lin(floor_col))
		if not stair:
			ceiling.box(Vector3(r.size.x, 0.01, r.size.y), Vector3(r.get_center().x, clear - 0.005, r.get_center().y), _lin(paint.ceiling))
		var wall: Color = paint.wall
		if paint.get("paper", false):
			wall = wall.lerp(paint.paper_colour, 0.55)
		var lower: Color = paint.get("lower", wall)
		var lower_h: float = paint.lower_h
		var top := clear if not stair else plan.storey
		for side in ["x0", "x1", "z0", "z1"]:
			_skin(walls, r, side, opens, top, wall, lower, lower_h)
			if paint.get("cornice", false):
				_cornice(ceiling, r, side, clear, paint.ceiling)
	for d: Dictionary in f.doors: # the threshold, in the floor of the room it opens into
		var dr := door_rect(d)
		var into: int = d.swing if d.swing >= 0 else d.a
		var col := Color("6f675c")
		for s: Dictionary in f.spaces:
			if s.id == into:
				col = s.paint.floor_colour
		floor_b.box(Vector3(dr.size.x, 0.01, dr.size.y), Vector3(dr.get_center().x, 0.005, dr.get_center().y), _lin(col))


## One side of a room's walls painted, round the doors and windows that open in it.
static func _skin(b: MeshKit.Builder, r: Rect2, side: String, opens: Array, top: float, wall: Color, lower: Color, lower_h: float) -> void:
	var along_z := side.begins_with("x")
	var lo := r.position.y if along_z else r.position.x
	var hi := r.end.y if along_z else r.end.x
	var gaps := [] # [s0, s1, y0, y1]
	for o: Array in opens:
		var g: Rect2 = o[0]
		var touches := false
		match side:
			"x0":
				touches = absf(g.end.x - r.position.x) < 0.01
			"x1":
				touches = absf(g.position.x - r.end.x) < 0.01
			"z0":
				touches = absf(g.end.y - r.position.y) < 0.01
			"z1":
				touches = absf(g.position.y - r.end.y) < 0.01
		var s0 := g.position.y if along_z else g.position.x
		var s1 := g.end.y if along_z else g.end.x
		if touches and s1 > lo + 0.001 and s0 < hi - 0.001:
			gaps.append([maxf(s0, lo), minf(s1, hi), o[1], o[2]])
	var cuts := [lo, hi]
	for g: Array in gaps:
		cuts.append_array([g[0], g[1]])
	cuts = HousePlan._unique(cuts)
	for k in cuts.size() - 1:
		var a: float = cuts[k]
		var bb: float = cuts[k + 1]
		var holes := []
		for g: Array in gaps:
			if float(g[0]) <= a + 0.001 and float(g[1]) >= bb - 0.001:
				holes.append([g[2], g[3]])
		for span: Array in _minus([[0.0, top]], holes):
			var y0: float = span[0]
			var y1: float = span[1]
			if lower_h > 0.0 and y0 < lower_h:
				_skin_box(b, r, side, a, bb, y0, minf(y1, lower_h), lower)
				y0 = lower_h
			if y1 > y0:
				_skin_box(b, r, side, a, bb, y0, y1, wall)


static func _skin_box(b: MeshKit.Builder, r: Rect2, side: String, a: float, bb: float, y0: float, y1: float, col: Color) -> void:
	var mid := (a + bb) * 0.5
	var y := (y0 + y1) * 0.5
	var h := y1 - y0
	var c := _lin(col)
	match side:
		"x0":
			b.box(Vector3(SKIN, h, bb - a), Vector3(r.position.x + SKIN * 0.5, y, mid), c)
		"x1":
			b.box(Vector3(SKIN, h, bb - a), Vector3(r.end.x - SKIN * 0.5, y, mid), c)
		"z0":
			b.box(Vector3(bb - a, h, SKIN), Vector3(mid, y, r.position.y + SKIN * 0.5), c)
		"z1":
			b.box(Vector3(bb - a, h, SKIN), Vector3(mid, y, r.end.y - SKIN * 0.5), c)


static func _cornice(b: MeshKit.Builder, r: Rect2, side: String, clear: float, col: Color) -> void:
	var d := 0.07
	var h := 0.12
	var c := _lin(col.darkened(0.05))
	var y := clear - h * 0.5
	match side:
		"x0":
			b.box(Vector3(d, h, r.size.y), Vector3(r.position.x + d * 0.5, y, r.get_center().y), c)
		"x1":
			b.box(Vector3(d, h, r.size.y), Vector3(r.end.x - d * 0.5, y, r.get_center().y), c)
		"z0":
			b.box(Vector3(r.size.x, h, d), Vector3(r.get_center().x, y, r.position.y + d * 0.5), c)
		"z1":
			b.box(Vector3(r.size.x, h, d), Vector3(r.get_center().x, y, r.end.y - d * 0.5), c)


# --- Doors and the stair -------------------------------------------------------------

## Every door's leaf, standing open into the room it swings into.
static func _leaves(f: Dictionary, b: MeshKit.Builder) -> void:
	for d: Dictionary in f.doors:
		if d.swing < 0 or not LEAF.has(d.kind):
			continue
		var room := Rect2()
		for s: Dictionary in f.spaces:
			if s.id == d.swing:
				room = s.rect
		var w := float(d.to) - float(d.from)
		var half := float(d.t) * 0.5
		var hinge_hi := float(d.hinge) > float(d.from) + 0.001
		var along := Vector2(0, -1 if hinge_hi else 1) if d.axis == "x" else Vector2(-1 if hinge_hi else 1, 0)
		var normal := Vector2.ZERO
		var hinge := Vector2.ZERO
		if d.axis == "x":
			var sgn := 1.0 if room.get_center().x > float(d.at) else -1.0
			normal = Vector2(sgn, 0)
			hinge = Vector2(float(d.at) + sgn * half, d.hinge)
		else:
			var sgn := 1.0 if room.get_center().y > float(d.at) else -1.0
			normal = Vector2(0, sgn)
			hinge = Vector2(d.hinge, float(d.at) + sgn * half)
		var u := (along * cos(LEAF_OPEN) + normal * sin(LEAF_OPEN)).normalized()
		var c := hinge + u * w * 0.5 + normal * 0.02
		var yaw := atan2(-u.y, u.x)
		var h := float(d.height) - 0.01
		b.box(Vector3(w - 0.02, h, 0.045), Vector3(c.x, h * 0.5, c.y), _lin(LEAF[d.kind]), Basis(Vector3.UP, yaw))


## The stair's flights from this floor to the next, its half landing and the rails along the well.
static func _stair(plan: HousePlan, f: Dictionary, b: MeshKit.Builder, body: StaticBody3D) -> void:
	var fr := plan.frame
	var cage: Rect2 = fr.cage
	var up: Rect2 = fr.up
	var back: Rect2 = fr.back_flight
	var mid: Rect2 = fr.mid
	var k := int(fr.risers) / 2
	var riser: float = fr.riser
	var tread := Config.INTERIOR_TREAD
	var half := plan.storey * 0.5
	var top: bool = f.level == plan.floors.size() - 1
	var inner_up := up.end.x if up.get_center().x < cage.get_center().x else up.position.x
	var inner_back := back.position.x if back.get_center().x > cage.get_center().x else back.end.x
	if top: # nothing goes on up: a rail along the landing's edge over the flight below
		_box(b, body, Rect2(up.position.x, up.position.y - 0.03, up.size.x, 0.06), 0.0, 1.0, RAIL)
		return
	for j in range(1, k):
		var z := up.position.y + (j - 1) * tread
		_box(b, null, Rect2(up.position.x, z, up.size.x, tread), maxf(j * riser - riser - 0.12, 0.0), j * riser, TREAD)
		var z2 := up.end.y - j * tread
		_box(b, null, Rect2(back.position.x, z2, back.size.x, tread), half + j * riser - riser - 0.12, half + j * riser, TREAD)
	_box(b, body, mid, half - 0.2, half, TREAD)
	_ramp(b, body, up, Vector2(up.position.y, 0.0), Vector2(up.end.y, half), false)
	_ramp(b, body, back, Vector2(up.end.y, half), Vector2(up.position.y, plan.storey), false)
	_ramp(b, body, Rect2(inner_up - 0.025, up.position.y, 0.05, up.size.y), Vector2(up.position.y, 0.95), Vector2(up.end.y, half + 0.95), true)
	_ramp(b, body, Rect2(inner_back - 0.025, back.position.y, 0.05, back.size.y), Vector2(up.end.y, half + 0.95), Vector2(up.position.y, plan.storey + 0.95), true)


## A sloped plate over `r`'s x-range from (z, y) `a` to `b`: a flight's walking surface (hidden
## under its treads) or, `shown`, a handrail.
static func _ramp(b: MeshKit.Builder, body: StaticBody3D, r: Rect2, a: Vector2, bb: Vector2, shown: bool) -> void:
	var dz := bb.x - a.x
	var dy := bb.y - a.y
	var length := sqrt(dz * dz + dy * dy)
	var z_axis := Vector3(0, dy, dz) / length
	var x_axis := Vector3(1, 0, 0) if dz > 0.0 else Vector3(-1, 0, 0)
	var y_axis := z_axis.cross(x_axis)
	var basis := Basis(x_axis, y_axis, z_axis)
	var thick := 0.05 if shown else 0.08
	var centre := Vector3(r.get_center().x, (a.y + bb.y) * 0.5, (a.x + bb.x) * 0.5) - y_axis * thick * 0.5
	var size := Vector3(r.size.x, thick, length)
	if shown:
		b.box(size, centre, _lin(RAIL), basis)
		return
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.transform = Transform3D(basis, centre)
	body.add_child(cs)
