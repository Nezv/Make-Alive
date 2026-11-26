extends TestCase
## House interiors (S244): a house's floors laid out from a few fixed things (the footprint, the
## window bays, the street door, the stair, the load-bearing walls and the flues, the same on every
## floor) and seeded partitions, room kinds, doors, paint, lamps and furniture slots (HousePlan,
## HouseFloor, RoomDressing), and built into walls you can walk between (InteriorBuilder).

const EPS := 0.011

static var _sample: HousePlan
static var _houses: Array = []


func _house() -> HousePlan:
	if _sample == null:
		_sample = HousePlan.new(HousePlan.sample())
	return _sample


## Houses the town builds (CityBlocks: 2 to 5 bays, 9 to 14 m deep, three floors and up), seeded.
func _sweep() -> Array:
	if not _houses.is_empty():
		return _houses
	var out := []
	var i := 0
	for bays in [2, 3, 4, 5]:
		for depth in [9.5, 11.0, 12.5, 14.0]:
			var spec := HousePlan.sample(1000 + i)
			spec.bays = bays
			spec.back_bays = bays
			spec.width = bays * (2.3 + 0.5 * fmod(i * 0.37, 1.0))
			spec.depth = depth
			spec.storey = 2.9 + 0.5 * fmod(i * 0.61, 1.0)
			spec.door = "left" if i % 2 == 0 else "right"
			spec.shop = i % 3 != 0
			out.append(HousePlan.new(spec))
			i += 1
	_houses = out
	return out


func _space(f: Dictionary, id: int) -> Dictionary:
	for s: Dictionary in f.spaces:
		if s.id == id:
			return s
	return {}


func _rects(s: Dictionary) -> Array:
	return s.rects


# --- The fixed frame ---------------------------------------------------------------

func test_the_sample_house_has_three_floors_laid_out() -> void:
	var h := _house()
	assert_true(h.ok, "laid out: " + h.problem)
	assert_eq(h.floors.size(), 3, "three floors")
	for f: Dictionary in h.floors:
		assert_gt(f.spaces.size(), 5, "floor %d has rooms" % f.level)


func test_the_fixed_frame_is_the_same_on_every_floor() -> void:
	var h := _house()
	var cage: Rect2 = h.frame.cage
	for f: Dictionary in h.floors:
		var stair := {}
		for s: Dictionary in f.spaces:
			if s.kind == "stair":
				stair = s
		assert_false(stair.is_empty(), "floor %d has the stair" % f.level)
		assert_true((stair.rect as Rect2).is_equal_approx(cage), "the stair stands in the same place on floor %d" % f.level)
		var front := []
		for w: Dictionary in f.windows:
			if w.side == "front":
				front.append(snappedf((float(w.from) + float(w.to)) * 0.5, 0.01))
		for d: Dictionary in f.doors:
			if d.kind == "street" or d.kind == "shop":
				front.append(snappedf((float(d.from) + float(d.to)) * 0.5, 0.01))
		front.sort()
		var bays := []
		for b: Array in h.frame.front_windows:
			bays.append(snappedf((float(b[0]) + float(b[1])) * 0.5, 0.01))
		bays.sort()
		assert_eq(front, bays, "floor %d's front openings sit on the bays" % f.level)


func test_the_stair_is_sized_for_the_storey_and_the_player() -> void:
	var h := _house()
	var riser: float = h.frame.riser
	assert_near(riser * h.frame.risers, h.storey, 0.001, "the risers make the storey")
	assert_lt(riser, Config.INTERIOR_RISER_MAX + 0.001, "a riser a person climbs")
	var up: Rect2 = h.frame.up
	assert_true(minf(up.size.x, up.size.y) >= Config.INTERIOR_FLIGHT - EPS, "a flight is wide enough for the player")
	var slope := rad_to_deg(atan(riser / Config.INTERIOR_TREAD))
	assert_lt(slope, 40.0, "the flight is walkable")


# --- Rules every floor keeps -------------------------------------------------------

func _check_floor(h: HousePlan, f: Dictionary, tag: String) -> void:
	var inside := Rect2(0, 0, h.width, h.depth)
	var all := []
	for s: Dictionary in f.spaces:
		for r: Rect2 in _rects(s):
			assert_true(inside.grow(EPS).encloses(r), "%s: %s %d inside the house" % [tag, s.kind, s.id])
			all.append([s.id, r])
		var k: Dictionary = HousePlan.KINDS[s.kind]
		var r0: Rect2 = s.rect
		var least := minf(r0.size.x, r0.size.y)
		if k.circulation and s.kind != "stair":
			assert_true(least >= Config.INTERIOR_CORRIDOR - EPS, "%s: %s %d is %.2f m wide, at least a corridor" % [tag, s.kind, s.id, least])
		elif not k.window:
			assert_true(least >= Config.INTERIOR_CLOSET_MIN - EPS, "%s: %s %d is %.2f m, a closet at least" % [tag, s.kind, s.id, least])
		elif not k.circulation:
			assert_true(least >= Config.INTERIOR_ROOM_MIN - EPS, "%s: %s %d is %.2f m, a room at least" % [tag, s.kind, s.id, least])
		if k.window:
			assert_false((s.windows as Array).is_empty() and not _has_glazed_door(f, s.id), "%s: the %s %d has a window" % [tag, s.kind, s.id])
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a: Rect2 = all[i][1]
			var b: Rect2 = all[j][1]
			if all[i][0] != all[j][0]:
				assert_false(a.grow(-EPS).intersects(b.grow(-EPS)), "%s: spaces %d and %d overlap" % [tag, all[i][0], all[j][0]])
				var gap := _gap(a, b)
				if gap > 0.0 and gap < 0.09:
					fail("%s: spaces %d and %d are %.3f m apart: no room for a wall" % [tag, all[i][0], all[j][0], gap])


func _has_glazed_door(f: Dictionary, id: int) -> bool:
	for d: Dictionary in f.doors:
		if d.kind == "shop" and d.a == id:
			return true
	return false


## The wall's thickness between two rectangles that face each other, 0 if they do not.
func _gap(a: Rect2, b: Rect2) -> float:
	var oz := minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
	var ox := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
	if oz > EPS:
		if b.position.x >= a.end.x - EPS:
			return b.position.x - a.end.x
		if a.position.x >= b.end.x - EPS:
			return a.position.x - b.end.x
	if ox > EPS:
		if b.position.y >= a.end.y - EPS:
			return b.position.y - a.end.y
		if a.position.y >= b.end.y - EPS:
			return a.position.y - b.end.y
	return 0.0


func test_every_floor_keeps_the_rules() -> void:
	for f: Dictionary in _house().floors:
		_check_floor(_house(), f, "sample floor %d" % f.level)


func test_every_space_is_reached_from_the_way_in() -> void:
	for h: HousePlan in [_house()] + _sweep():
		if not h.ok:
			fail("house %s not laid out: %s" % [h.spec, h.problem])
			continue
		for f: Dictionary in h.floors:
			var got := HousePlan.reachable(f)
			for s: Dictionary in f.spaces:
				assert_true(got.has(s.id), "floor %d of %s: the %s %d is reached" % [f.level, h.spec.seed, s.kind, s.id])


func test_doors_and_corridors_fit_the_player() -> void:
	var h := _house()
	assert_gt(h.clear, Config.PLAYER_HEIGHT * 1.35, "the ceiling is well over the player")
	for f: Dictionary in h.floors:
		for d: Dictionary in f.doors:
			var w := float(d.to) - float(d.from)
			assert_true(w >= Config.INTERIOR_DOOR - EPS, "floor %d door %d is %.2f m wide" % [f.level, d.id, w])
			assert_true(w > Config.PLAYER_RADIUS * 2.0 + 0.05, "the player's shoulders go through door %d" % d.id)
			assert_true(float(d.height) >= Config.INTERIOR_DOOR_HEIGHT - EPS, "door %d is high enough" % d.id)
			assert_true(float(d.height) <= h.clear, "door %d fits under the ceiling" % d.id)


func test_doors_sit_on_their_walls_with_jambs_and_do_not_clash() -> void:
	for f: Dictionary in _house().floors:
		var swings := []
		for d: Dictionary in f.doors:
			if d.b >= 0:
				var a: Rect2 = _space(f, d.a).rect
				var b: Rect2 = _space(f, d.b).rect
				var lo := maxf(a.position.y, b.position.y) if d.axis == "x" else maxf(a.position.x, b.position.x)
				var hi := minf(a.end.y, b.end.y) if d.axis == "x" else minf(a.end.x, b.end.x)
				var room_lo := lo
				var room_hi := hi
				assert_true(float(d.from) >= room_lo + Config.INTERIOR_JAMB - EPS and float(d.to) <= room_hi - Config.INTERIOR_JAMB + EPS,
					"floor %d door %d (%.2f..%.2f) stands within %.2f..%.2f with its jambs" % [f.level, d.id, d.from, d.to, lo, hi])
			if d.swing >= 0:
				var sq := RoomDressing.swing_rect(d, _space(f, d.swing).rect)
				for other: Array in swings:
					if other[0] == d.swing:
						assert_false((other[1] as Rect2).grow(-EPS).intersects(sq.grow(-EPS)), "floor %d: door %d swings into another door's leaf" % [f.level, d.id])
				swings.append([d.swing, sq])


func test_interior_walls_never_cut_a_window() -> void:
	for h: HousePlan in [_house()] + _sweep():
		for f: Dictionary in h.floors:
			for w: Dictionary in f.windows:
				var s := _space(f, w.space)
				assert_false(s.is_empty(), "floor %d window %d opens into a space" % [f.level, w.id])
				if s.is_empty():
					continue
				var r: Rect2 = s.rect
				assert_true(float(w.from) >= r.position.x - EPS and float(w.to) <= r.end.x + EPS,
					"%s floor %d: window %.2f..%.2f lies inside the %s's wall %.2f..%.2f" % [h.spec.seed, f.level, w.from, w.to, s.kind, r.position.x, r.end.x])


func test_a_dwelling_has_a_kitchen_a_living_room_and_a_wc_off_the_way_in() -> void:
	var h := _house()
	for f: Dictionary in h.floors:
		if f.level == 0:
			continue
		var kinds := {}
		for s: Dictionary in f.spaces:
			kinds[s.kind] = int(kinds.get(s.kind, 0)) + 1
		assert_eq(kinds.get("cuisine", 0), 1, "floor %d has one kitchen" % f.level)
		assert_eq(kinds.get("salon", 0), 1, "floor %d has one salon" % f.level)
		assert_eq(kinds.get("wc", 0), 1, "floor %d has one WC" % f.level)
		for d: Dictionary in f.doors:
			for id: int in [d.a, d.b]:
				if id < 0:
					continue
				var s := _space(f, id)
				var other := _space(f, d.b if id == d.a else d.a)
				if HousePlan.KINDS[s.kind].wet and not other.is_empty():
					assert_true(HousePlan.KINDS[other.kind].circulation or other.kind == "chambre",
						"floor %d: the %s opens onto the corridor, not the %s" % [f.level, s.kind, other.kind])


func test_the_ground_floor_has_the_street_door_the_shop_and_the_way_to_the_court() -> void:
	var f: Dictionary = _house().floors[0]
	var kinds := {}
	for d: Dictionary in f.doors:
		kinds[d.kind] = true
	assert_true(kinds.has("street"), "the street door")
	assert_true(kinds.has("shop"), "the shop's door")
	var shop := false
	for s: Dictionary in f.spaces:
		shop = shop or s.kind == "boutique"
	assert_true(shop, "a shop on the street")


func test_the_same_seed_lays_out_the_same_house_and_floors_differ() -> void:
	var a := HousePlan.new(HousePlan.sample())
	var b := HousePlan.new(HousePlan.sample())
	assert_eq(JSON.stringify(a.to_dict()), JSON.stringify(b.to_dict()), "deterministic")
	var differ := 0
	var houses := 0
	for h: HousePlan in _sweep():
		if h.floors.size() < 3:
			continue
		houses += 1
		var f1: Dictionary = h.to_dict().floors[1]
		var f2: Dictionary = h.to_dict().floors[2]
		if JSON.stringify(f1.spaces) != JSON.stringify(f2.spaces) or JSON.stringify(f1.doors) != JSON.stringify(f2.doors):
			differ += 1
	assert_gt(differ, houses * 0.7, "the upper floors of a house are not copies of each other")
	var c := HousePlan.new(HousePlan.sample(77))
	assert_true(JSON.stringify(a.to_dict()) != JSON.stringify(c.to_dict()), "another seed, another house")


func test_the_town_s_houses_lay_out() -> void:
	var n := 0
	for h: HousePlan in _sweep():
		assert_true(h.ok, "%s: %s" % [JSON.stringify(h.spec), h.problem])
		if h.ok:
			n += 1
			for f: Dictionary in h.floors:
				_check_floor(h, f, "seed %d floor %d" % [h.spec.seed, f.level])
	assert_eq(n, 16, "every house of the sweep")


# --- Paint, lamps, furniture -------------------------------------------------------

func test_walls_are_painted_room_by_room_with_variation() -> void:
	for f: Dictionary in _house().floors:
		var colours := {}
		for s: Dictionary in f.spaces:
			assert_true(s.paint.has("wall") and s.paint.has("floor") and s.paint.has("ceiling"), "the %s is painted" % s.kind)
			colours[(s.paint.wall as Color).to_html(false)] = true
		assert_gt(colours.size(), 3, "floor %d's rooms are not all one colour" % f.level)
	var h2 := HousePlan.new(HousePlan.sample(5))
	var salon_a := {}
	for f: Dictionary in _house().floors:
		for s: Dictionary in f.spaces:
			if s.kind == "salon":
				salon_a[f.level] = s.paint.wall
	assert_true(salon_a.get(1) != salon_a.get(2), "two salons of one house are painted differently")
	assert_true(h2.ok, "another house")


func test_every_room_has_a_lamp_and_a_switch_by_its_door() -> void:
	var h := _house()
	for f: Dictionary in h.floors:
		for s: Dictionary in f.spaces:
			assert_gt((s.lights as Array).size(), 0, "floor %d: the %s %d has a lamp" % [f.level, s.kind, s.id])
			for l: Dictionary in s.lights:
				var p: Vector3 = l.pos
				var r: Rect2 = s.rect
				assert_true(r.grow(0.05).has_point(Vector2(p.x, p.z)), "the %s's lamp hangs in it" % s.kind)
				assert_true(p.y <= h.clear and p.y >= Config.PLAYER_HEIGHT + 0.15, "the %s's lamp is over the player's head (%.2f)" % [s.kind, p.y])
			if s.kind == "corridor":
				var r: Rect2 = s.rect
				var need := maxi(1, floori(maxf(r.size.x, r.size.y) / Config.INTERIOR_LIGHT_STEP))
				assert_true((s.lights as Array).size() >= need, "the corridor is lit along its length")
			if not HousePlan.KINDS[s.kind].circulation:
				assert_false((s.switches as Array).is_empty(), "floor %d: the %s has a switch" % [f.level, s.kind])


func test_furniture_slots_leave_the_way_clear() -> void:
	var problems := []
	for h: HousePlan in [_house()] + _sweep().slice(0, 8):
		for f: Dictionary in h.floors:
			for s: Dictionary in f.spaces:
				var r: Rect2 = s.rect
				for it: Dictionary in s.furniture:
					var fr: Rect2 = it.rect
					assert_true(r.grow(EPS).encloses(fr), "the %s's %s stands inside it" % [s.kind, it.item])
				for i in (s.furniture as Array).size():
					for j in range(i + 1, (s.furniture as Array).size()):
						var a: Rect2 = s.furniture[i].rect
						var b: Rect2 = s.furniture[j].rect
						if a.grow(-EPS).intersects(b.grow(-EPS)):
							problems.append("floor %d %s: %s and %s overlap" % [f.level, s.kind, s.furniture[i].item, s.furniture[j].item])
				for p: String in RoomDressing.check(s, f):
					problems.append("seed %d floor %d %s %d: %s" % [h.spec.seed, f.level, s.kind, s.id, p])
	assert_eq(problems, [], "furniture")


func test_rooms_get_their_furniture() -> void:
	var need := { "chambre": "lit", "cuisine": "cuisiniere", "wc": "cuvette", "salon": "canape", "boutique": "comptoir" }
	for f: Dictionary in _house().floors:
		for s: Dictionary in f.spaces:
			if need.has(s.kind):
				var got := false
				for it: Dictionary in s.furniture:
					got = got or String(it.item).begins_with(need[s.kind])
				assert_true(got, "floor %d: the %s has its %s" % [f.level, s.kind, need[s.kind]])


func test_a_fireplace_stands_on_a_flue_on_every_floor() -> void:
	var h := _house()
	assert_gt((h.frame.flues as Array).size(), 0, "the house has flues in its party walls")
	var at := {}
	for f: Dictionary in h.floors:
		for s: Dictionary in f.spaces:
			for it: Dictionary in s.furniture:
				if it.item == "cheminee":
					var r: Rect2 = it.rect
					var c := r.get_center()
					var on_flue := false
					for fl: Dictionary in h.frame.flues:
						on_flue = on_flue or absf(c.y - float(fl.z)) < 0.05 and absf(c.x - float(fl.x)) < 0.6
					assert_true(on_flue, "floor %d: the %s's fireplace is on a flue" % [f.level, s.kind])
					at[f.level] = true
	assert_gt(at.size(), 1, "fireplaces on more than one floor")


# --- Built -------------------------------------------------------------------------

func test_the_built_house_lets_the_player_through_doors_and_stops_them_at_walls() -> void:
	var h := _house()
	var node := InteriorBuilder.build(h)
	add_child(node)
	await frames(3)
	var space := node.get_world_3d().direct_space_state
	var shape := CapsuleShape3D.new()
	shape.radius = Config.PLAYER_RADIUS * 0.9
	shape.height = Config.PLAYER_HEIGHT * 0.9
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.collision_mask = Config.LAYER_WORLD
	var f: Dictionary = h.floors[1]
	for d: Dictionary in f.doors:
		var mid := (float(d.from) + float(d.to)) * 0.5
		var p := Vector3(float(d.at), 0, mid) if d.axis == "x" else Vector3(mid, 0, float(d.at))
		var y := float(f.y) + shape.height * 0.5 + 0.08
		q.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, y, p.z))
		assert_eq(space.intersect_shape(q, 1).size(), 0, "the player stands in door %d (%s)" % [d.id, d.kind])
	for s: Dictionary in f.spaces:
		if s.kind == "stair":
			continue
		var c: Vector2 = (s.rect as Rect2).get_center()
		q.transform = Transform3D(Basis.IDENTITY, Vector3(c.x, float(f.y) + shape.height * 0.5 + 0.08, c.y))
		var hits := space.intersect_shape(q, 1)
		assert_eq(hits.size(), 0, "the middle of the %s is clear" % s.kind)
	var ray := PhysicsRayQueryParameters3D.create(Vector3(-2, float(f.y) + 1.0, 0.5), Vector3(h.width + 2, float(f.y) + 1.0, 0.5))
	ray.collision_mask = Config.LAYER_WORLD
	assert_false(space.intersect_ray(ray).is_empty(), "the walls stop a ray across the house")
	node.free()


func test_the_built_house_has_its_lamps_and_floors() -> void:
	var h := _house()
	var node := InteriorBuilder.build(h)
	var lamps := 0
	for f in h.floors.size():
		var fl := node.get_node_or_null("floor_%d" % f)
		assert_true(fl != null, "floor %d built" % f)
		if fl:
			assert_true(fl.get_node_or_null("walls") is MeshInstance3D, "walls")
			assert_true(fl.get_node_or_null("ceiling") is MeshInstance3D, "a ceiling apart, to be hidden")
			lamps += fl.get_node("lights").get_child_count()
	var want := 0
	for f: Dictionary in h.floors:
		for s: Dictionary in f.spaces:
			want += (s.lights as Array).size()
	assert_eq(lamps, want, "one light per lamp")
	node.free()
