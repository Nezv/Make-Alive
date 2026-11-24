extends TestCase
## Street network 2 (S040): Joinville's own streets (traced into CityStreets: the main ones where its
## bus routes run, every other street a rue) under invented French names, with widths, way and
## surface; StreetNet turns them into a graph with real junctions (pans coupés, T and skewed crosses)
## and street surfaces as polygons that CityMap builds into meshes; the 4 m grid is only for navigation.

const PREFIXES := ["rue ", "place ", "impasse ", "boulevard ", "passage ", "ruelle ", "avenue ", "route ",
	"chemin ", "allée "]

static var _net: StreetNet


func _n() -> StreetNet:
	if _net == null:
		_net = StreetNet.new(CityData.STREETS)
	return _net


func _plan(px: Vector2) -> Vector2:
	return CityData.to_plan(px)


func _streets_of(kind: String) -> Array:
	var out := []
	for s: Dictionary in CityData.STREETS:
		if s.kind == kind:
			out.append(s)
	return out


func test_every_street_has_an_invented_french_name() -> void:
	var seen := {}
	for s: Dictionary in CityData.STREETS:
		var name := CityData.name_of(s.id)
		assert_true(name != "", "%s has a name" % s.id)
		var french := false
		for p: String in PREFIXES:
			french = french or name.begins_with(p)
		assert_true(french, "'%s' is a French street name" % name)
		for joinville in ["Rua", "Avenida", "Joinville", "Doutor", "Marechal"]:
			assert_false(name.contains(joinville), "'%s' names nothing of Joinville" % name)
		assert_false(seen.has(name), "'%s' is used once" % name)
		seen[name] = true
	for sq: Dictionary in CityData.SQUARES:
		assert_true(CityData.name_of(sq.id).begins_with("place "), "%s is a place" % sq.id)


func test_every_street_says_its_widths_way_and_surface() -> void:
	for s: Dictionary in CityData.STREETS:
		var sp := CityData.spec(s)
		assert_gt(float(sp.road), 2.5, "%s has a carriageway" % s.id)
		assert_eq((sp.walk as Array).size(), 2, "%s: a pavement width each side" % s.id)
		assert_true([-1, 0, 1].has(int(sp.oneway)), "%s: one-way along, against or both ways" % s.id)
		assert_true(CityData.SURFACES.has(sp.surface), "%s: setts, asphalt or flags" % s.id)
	assert_gt(CityData.width(_streets_of("principale")[0]), CityData.width(_streets_of("rue")[0]), "main streets are wider")


## The plan is Joinville's: every traced street lies on a street of joinville.png, and the main ones
## are many and long (the bus routes cross the whole picture).
func test_the_streets_are_joinvilles_own() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(CityData.REF_IMAGE))
	assert_true(img != null and not img.is_empty(), "the reference picture is there")
	var on := 0
	var total := 0
	for s: Dictionary in CityStreets.STREETS:
		var pts: Array = s.pts
		for i in pts.size() - 1:
			var p: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], 0.5)
			total += 1
			var found := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var x := clampi(int(p.x) + dx, 0, img.get_width() - 1)
					var y := clampi(int(p.y) + dy, 0, img.get_height() - 1)
					var c := img.get_pixel(x, y)
					# white, yellow or orange street fill (the background is greyer: 242, 239, 233)
					if c.r8 >= 246 and (c.g8 >= 246 or c.b8 <= 200):
						found = true
			on += 1 if found else 0
	assert_gt(total, 1000)
	assert_gt(float(on) / total, 0.95, "the streets run where Joinville's do (%d of %d)" % [on, total])
	var main := 0.0
	for s: Dictionary in _streets_of("principale"):
		for i in (s.pts as Array).size() - 1:
			main += _plan(s.pts[i]).distance_to(_plan(s.pts[i + 1]))
	assert_gt(main, 20000.0, "kilometres of main street")
	assert_gt(_streets_of("rue").size(), 150, "and a town's worth of side streets")


func test_the_streets_link_the_five_places() -> void:
	var n := _n()
	var gates := {}
	for id: String in CityData.POIS:
		var g := _plan(CityData.POIS[id].gate)
		var k := n.node_near(g, 1.0e9)
		assert_lt(n.distance_to_street(g), 6.0, "%s's gate is on a street" % id)
		gates[id] = k
	for a: String in gates:
		for b: String in gates:
			assert_true(n.connected(gates[a], gates[b]), "streets lead from %s to %s" % [a, b])


func test_streets_meet_at_odd_angles() -> void:
	var n := _n()
	var skewed := 0
	var tees := 0
	var crosses := 0
	for k in n.nodes.size():
		var arms: Array = n.nodes[k].arms
		if arms.size() == 3:
			tees += 1
		elif arms.size() >= 4:
			crosses += 1
		if arms.size() < 3:
			continue
		for i in arms.size():
			var a: Vector2 = arms[i].dir
			var b: Vector2 = arms[(i + 1) % arms.size()].dir
			var ang := rad_to_deg(absf(a.angle_to(b)))
			if absf(ang - 90.0) > 22.0 and absf(ang - 180.0) > 22.0:
				skewed += 1
				break
	assert_gt(tees, 150, "T junctions")
	assert_gt(crosses, 40, "crossings")
	assert_gt(skewed, 30, "streets meeting askew")


func test_junction_corners_are_cut() -> void:
	var n := _n()
	var cut := 0
	var kept := 0
	var total := 0
	for k in n.nodes.size():
		for corner: Dictionary in n.corners(k):
			# The block's corner where two kerbs would meet is cut off and given to the street: a pan
			# coupé. Just beyond the cut is the block again.
			total += 1
			if n.covers(corner.sharp, StreetNet.ROAD):
				cut += 1
			if not n.covers(corner.beyond, StreetNet.ROAD):
				kept += 1
	assert_gt(total, 400)
	assert_gt(cut, total * 0.95, "kerb corners are chamfered, not sharp")
	assert_gt(kept, total * 0.8, "and the chamfer stops at the block")


func test_streets_are_meshes_at_their_real_width() -> void:
	var n := _n()
	var checked := {}
	for link: Dictionary in n.links:
		var s: Dictionary = n.streets[link.street]
		if checked.has(s.kind) and int(checked[s.kind]) >= 3:
			continue
		var pts: PackedVector2Array = link.pts
		for i in pts.size() - 1:
			# a long straight stretch well away from any junction
			if pts[i].distance_to(pts[i + 1]) < 60.0:
				continue
			var mid := (pts[i] + pts[i + 1]) * 0.5
			if n.node_near(mid, 30.0) >= 0:
				continue
			var sp: Dictionary = n.specs[link.street]
			var side := (pts[i + 1] - pts[i]).normalized().orthogonal()
			var road: float = sp.road
			for sgn in [1.0, -1.0]:
				var w: float = sp.walk[0] if sgn > 0.0 else sp.walk[1]
				assert_true(n.covers(mid + side * sgn * (road * 0.5 - 0.3), StreetNet.ROAD), "%s: carriageway to its kerb" % s.id)
				assert_false(n.covers(mid + side * sgn * (road * 0.5 + 0.3), StreetNet.ROAD), "%s: and no further: not a 4 m cell" % s.id)
				assert_true(n.covers(mid + side * sgn * (road * 0.5 + w - 0.3), StreetNet.WALK), "%s: pavement beyond it" % s.id)
			checked[s.kind] = int(checked.get(s.kind, 0)) + 1
			break
	assert_eq(checked.get("principale", 0), 3, "main streets measured")
	assert_eq(checked.get("rue", 0), 3, "side streets measured")


func test_no_gaps_along_any_street() -> void:
	var n := _n()
	var gaps := []
	for link: Dictionary in n.links:
		var pts: PackedVector2Array = link.pts
		for i in pts.size() - 1:
			var steps := ceili(pts[i].distance_to(pts[i + 1]) / 1.5)
			for k in steps + 1:
				var p := pts[i].lerp(pts[i + 1], float(k) / steps)
				if not n.covers(p, StreetNet.ROAD):
					gaps.append(CityData.to_px(Vector3(p.x, 0, p.y)))
	assert_eq(gaps.size(), 0, "the carriageway is continuous through bends and junctions: gaps at %s" % [gaps.slice(0, 8)])


func test_only_the_detail_area_is_built() -> void:
	var n := _n()
	var all := n.triangles()
	var c := _plan(CityData.POIS.terminal.at)
	var area := PackedVector2Array([c + Vector2(-200, -200), c + Vector2(200, -200), c + Vector2(200, 200), c + Vector2(-200, 200)])
	var some := n.triangles(area)
	assert_gt(some, 0)
	assert_lt(some, all / 3, "a mission area builds its own streets, not the town's")
	for piece: Dictionary in n.pieces_in(area):
		var tris: PackedVector2Array = piece.tris
		var hit := false
		for p in tris:
			hit = hit or p.distance_to(c) < 420.0
		assert_true(hit, "every piece built is near the area")


func test_the_place_du_marche_is_by_the_bus_terminal() -> void:
	var marche: Dictionary = CityData.square("marche")
	assert_false(marche.is_empty(), "there is a place du Marché")
	var mid := Vector2.ZERO
	for p: Vector2 in marche.pts:
		mid += _plan(p) / (marche.pts as Array).size()
	assert_lt(mid.distance_to(_plan(CityData.POIS.terminal.at)), 200.0, "next to the gare routière, where Praça da Bandeira is")


func test_every_square_opens_onto_streets() -> void:
	var n := _n()
	for sq: Dictionary in CityData.SQUARES:
		var touching := 0
		for p: Vector2 in sq.pts:
			if n.distance_to_street(_plan(p)) < 8.0:
				touching += 1
		assert_gt(touching, 1, "%s has streets along it, not houses all round" % sq.id)


func test_driveways_inside_a_poi_are_left_to_the_poi() -> void:
	for s: Dictionary in CityData.STREETS:
		if s.kind == "chemin":
			continue
		assert_false(CityData._mostly_in_a_lot(s.pts), "%s is a street, not a car park inside a POI" % s.id)
	var dropped := CityStreets.STREETS.size() + CityData.HAND_STREETS.size() - CityData.STREETS.size()
	assert_gt(dropped, 0, "the hospital's and prefeitura's own driveways are not town streets")
