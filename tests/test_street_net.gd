extends TestCase
## Street network 2 (S040): the town's plan on Joinville's bones. CityData.STREETS is a skeleton of
## French streets (names, kinds, widths, one-way, surface), StreetNet turns it into a graph with real
## junctions (pans coupés, T and skewed crosses, a rond-point) and street surfaces as polygons that
## CityMap builds into meshes; the 4 m grid is only for navigation.

const PREFIXES := ["rue ", "Grande Rue", "quai ", "place ", "impasse ", "boulevard ", "passage ", "ruelle ",
	"pont ", "route ", "chemin ", "allée ", "cours ", "montée "]

static var _net: StreetNet


func _n() -> StreetNet:
	if _net == null:
		_net = StreetNet.new(CityData.STREETS, CityData.ROUNDABOUTS)
	return _net


func _plan(px: Vector2) -> Vector2:
	return CityData.to_plan(px)


func _streets_of(kind: String) -> Array:
	var out := []
	for s: Dictionary in CityData.STREETS:
		if s.kind == kind:
			out.append(s)
	return out


func _length(pts: Array) -> float:
	var l := 0.0
	for i in pts.size() - 1:
		l += CityData.to_plan(pts[i]).distance_to(CityData.to_plan(pts[i + 1]))
	return l


func test_every_street_has_an_invented_french_name() -> void:
	var seen := {}
	for s: Dictionary in CityData.STREETS:
		assert_true(CityData.NAMES.has(s.id), "%s has a name in the table" % s.id)
		var name: String = CityData.NAMES.get(s.id, "")
		var french := false
		for p: String in PREFIXES:
			french = french or name.begins_with(p)
		assert_true(french, "'%s' is a French street name" % name)
		for joinville in ["Rua", "Avenida", "Joinville", "Doutor", "Marechal"]:
			assert_false(name.contains(joinville), "'%s' names nothing of Joinville" % name)
		assert_false(seen.has(name), "'%s' is used once" % name)
		seen[name] = true
	for sq: Dictionary in CityData.SQUARES:
		assert_true(String(CityData.NAMES.get(sq.id, "")).begins_with("place "), "%s is a place" % sq.id)
	assert_gt(CityData.STREETS.size(), 30, "a town, not a handful of roads")


func test_every_street_says_its_widths_way_and_surface() -> void:
	for s: Dictionary in CityData.STREETS:
		var sp := CityData.spec(s)
		assert_gt(float(sp.road), 2.5, "%s has a carriageway" % s.id)
		assert_eq((sp.walk as Array).size(), 2, "%s: a pavement width each side" % s.id)
		assert_true([-1, 0, 1].has(int(sp.oneway)), "%s: one-way along, against or both ways" % s.id)
		assert_true(CityData.SURFACES.has(sp.surface), "%s: setts, asphalt or flags" % s.id)
	for kind in ["ruelle", "impasse"]:
		for s: Dictionary in _streets_of(kind):
			assert_eq(CityData.spec(s).walk, [0.0, 0.0], "%s: setts wall to wall, no pavement" % s.id)
	assert_gt(CityData.width(_streets_of("boulevard")[0]), CityData.width(_streets_of("faubourg")[0]))
	assert_gt(CityData.width(_streets_of("faubourg")[0]), CityData.width(_streets_of("rue")[0]))
	assert_gt(CityData.width(_streets_of("rue")[0]), CityData.width(_streets_of("ruelle")[0]))
	assert_gt(float(CityData.spec(_streets_of("boulevard")[0]).mall), 6.0, "the boulevard's walk under its trees")
	var oneway := 0
	var setts := 0
	var asphalt := 0
	for s: Dictionary in CityData.STREETS:
		var sp := CityData.spec(s)
		oneway += 1 if int(sp.oneway) != 0 else 0
		setts += 1 if sp.surface == "setts" else 0
		asphalt += 1 if sp.surface == "asphalt" else 0
	assert_gt(oneway, 8, "the old streets are one-way")
	assert_gt(setts, asphalt, "setts on the old streets, asphalt on the newer roads")
	assert_gt(asphalt, 3)


func test_the_through_roads_link_the_five_places() -> void:
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


func test_quays_run_along_both_banks() -> void:
	var quays := _streets_of("quai")
	assert_eq(quays.size(), 2, "one quay each bank")
	var river := PackedVector2Array()
	for p: Vector2 in CityData.RIVER:
		river.append(_plan(p))
	for q: Dictionary in quays:
		var near := 0
		var total := 0
		for i in (q.pts as Array).size() - 1:
			for t in [0.25, 0.5, 0.75]:
				var p := _plan((q.pts[i] as Vector2).lerp(q.pts[i + 1], t))
				total += 1
				var d := INF
				for k in river.size() - 1:
					d = minf(d, Geometry2D.get_closest_point_to_segment(p, river[k], river[k + 1]).distance_to(p))
				if d < CityData.RIVER_WIDTH * 0.5 + 16.0:
					near += 1
		assert_gt(float(near) / total, 0.9, "%s runs along the water" % q.id)
		assert_gt(_length(q.pts), 900.0, "%s is a long quay" % q.id)


func test_old_streets_wander() -> void:
	var bent := 0
	for s: Dictionary in CityData.STREETS:
		if not ["rue", "grande_rue", "ruelle"].has(s.kind) or (s.pts as Array).size() < 3:
			continue
		var most := 0.0
		for i in range(1, (s.pts as Array).size() - 1):
			var a: Vector2 = s.pts[i] - s.pts[i - 1]
			var b: Vector2 = s.pts[i + 1] - s.pts[i]
			most = maxf(most, absf(rad_to_deg(a.angle_to(b))))
		if most > 8.0:
			bent += 1
	assert_gt(bent, 10, "old streets bend; Joinville's long straight grid is broken up")


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
	assert_gt(tees, 15, "T junctions")
	assert_gt(crosses, 5, "crossings")
	assert_gt(skewed, 10, "streets meeting askew")


func test_impasses_and_covered_passages() -> void:
	var n := _n()
	var edge := CityMap.edge_polygon()
	var impasses := _streets_of("impasse")
	assert_gt(impasses.size(), 2)
	for s: Dictionary in impasses:
		var a := n.node_near(_plan(s.pts[0]), 3.0)
		var b := n.node_near(_plan(s.pts[-1]), 3.0)
		var ends := [(n.nodes[a].arms as Array).size(), (n.nodes[b].arms as Array).size()]
		ends.sort()
		assert_eq(ends[0], 1, "%s ends blind" % s.id)
		assert_gt(ends[1], 1, "%s opens off a street" % s.id)
		assert_true(Geometry2D.is_point_in_polygon(_plan(s.pts[0]), edge) and Geometry2D.is_point_in_polygon(_plan(s.pts[-1]), edge),
			"%s is inside the town, not cut by the edge" % s.id)
	var passages := _streets_of("passage")
	assert_gt(passages.size(), 1)
	for s: Dictionary in passages:
		assert_true(CityData.spec(s).covered, "%s is covered" % s.id)
		for end: Vector2 in [s.pts[0], s.pts[-1]]:
			assert_gt((n.nodes[n.node_near(_plan(end), 3.0)].arms as Array).size(), 1, "%s goes through, street to street" % s.id)


func test_the_old_core_stands_round_the_place_du_marche() -> void:
	var n := _n()
	var marche: Dictionary = CityData.square("marche")
	assert_false(marche.is_empty(), "there is a place du Marché")
	var poly := PackedVector2Array()
	for p: Vector2 in marche.pts:
		poly.append(_plan(p))
	var mid := Vector2.ZERO
	for p in poly:
		mid += p / poly.size()
	assert_lt(mid.distance_to(_plan(CityData.POIS.terminal.at)), 200.0, "next to the gare routière, where Praça da Bandeira is")
	var entering := {}
	for s: Dictionary in CityData.STREETS:
		for p: Vector2 in s.pts:
			var q := _plan(p)
			var d := INF
			for i in poly.size():
				d = minf(d, Geometry2D.get_closest_point_to_segment(q, poly[i], poly[(i + 1) % poly.size()]).distance_to(q))
			if d < 4.0:
				entering[s.id] = true
	assert_gt(entering.size(), 3, "streets enter the square from several sides: %s" % [entering.keys()])
	# Dense: the old core inside the boulevard holds more street per hectare than the faubourgs.
	var ring := n.ring_polygon()
	assert_gt(ring.size(), 6, "the boulevard and the quay close a ring")
	assert_true(Geometry2D.is_point_in_polygon(mid, ring), "the market is inside the ring")
	var inside := 0.0
	var outside := 0.0
	var edge := CityMap.edge_polygon()
	for s: Dictionary in CityData.STREETS:
		for i in (s.pts as Array).size() - 1:
			var a := _plan(s.pts[i])
			var b := _plan(s.pts[i + 1])
			var m := (a + b) * 0.5
			if Geometry2D.is_point_in_polygon(m, ring):
				inside += a.distance_to(b)
			elif Geometry2D.is_point_in_polygon(m, edge):
				outside += a.distance_to(b)
	var ring_area := CityMap._poly_area(ring)
	var out_area := CityMap._poly_area(edge) - ring_area
	assert_gt(inside / ring_area, 1.6 * outside / out_area, "the core is a tangle, the faubourgs open")


func test_a_tree_lined_boulevard_rings_the_old_town_from_quay_to_quay() -> void:
	var n := _n()
	var ring := n.ring_polygon()
	var market := _plan(CityData.square("marche").pts[0])
	var near := INF
	var far := 0.0
	for p in ring:
		near = minf(near, p.distance_to(market))
		far = maxf(far, p.distance_to(market))
	assert_gt(near, 60.0, "the ring stands back from the market")
	assert_lt(far, 1100.0, "a walled town, not the whole map")
	var blvd := _streets_of("boulevard")
	var first: Vector2 = blvd[0].pts[0]
	var last: Vector2 = blvd[-1].pts[-1]
	for end: Vector2 in [first, last]:
		var on_quay := false
		for q: Dictionary in _streets_of("quai"):
			on_quay = on_quay or n.distance_to_street(_plan(end), q.id) < 4.0
		assert_true(on_quay, "the boulevard ends on the quay at %s" % end)


func test_a_rond_point_where_the_boulevard_meets_the_quay() -> void:
	var n := _n()
	assert_eq(CityData.ROUNDABOUTS.size(), 1)
	var rp: Dictionary = CityData.ROUNDABOUTS[0]
	var k := n.node_near(_plan(rp.at), 2.0)
	assert_gt(k, -1, "the rond-point is a junction")
	var kinds := {}
	for arm: Dictionary in n.nodes[k].arms:
		kinds[CityData.STREETS[arm.street].kind] = true
	assert_true(kinds.has("boulevard") and kinds.has("quai"), "boulevard meets quay there: %s" % [kinds.keys()])
	var c := _plan(rp.at)
	var r: float = rp.r
	for a in 8:
		var dir := Vector2.from_angle(a * TAU / 8.0)
		assert_true(n.covers(c + dir * (r - 1.5), StreetNet.ROAD), "the ring road goes round")
		assert_true(n.covers(c + dir * (r - CityData.RING_ROAD - 1.0), StreetNet.ISLAND), "an island in the middle")
	assert_false(n.covers(c, StreetNet.ROAD), "nobody drives over the island")


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
	assert_gt(total, 80)
	assert_gt(cut, total * 0.95, "kerb corners are chamfered, not sharp")
	assert_gt(kept, total * 0.8, "and the chamfer stops at the block")


func test_streets_are_meshes_at_their_real_width() -> void:
	var n := _n()
	var s: Dictionary = CityData.street("grande_rue")
	var sp := CityData.spec(s)
	var a := _plan(s.pts[3]) # between the rue Saint-Martin and the passage des Lanternes
	var b := _plan(s.pts[4])
	var mid := (a + b) * 0.5
	var side := (b - a).normalized().orthogonal()
	var narrow: Array = s.get("narrow", [1.0, 1.0, 1.0])
	var road: float = sp.road * (float(narrow[3]) + float(narrow[4])) * 0.5
	var walk: Array = sp.walk
	for sgn in [1.0, -1.0]:
		var w: float = walk[0] if sgn > 0.0 else walk[1]
		assert_true(n.covers(mid + side * sgn * (road * 0.5 - 0.3), StreetNet.ROAD), "carriageway to its kerb")
		assert_false(n.covers(mid + side * sgn * (road * 0.5 + 0.3), StreetNet.ROAD), "and no further: not a 4 m cell")
		assert_true(n.covers(mid + side * sgn * (road * 0.5 + w - 0.3), StreetNet.WALK), "pavement beyond it")
		assert_false(n.covers(mid + side * sgn * (road * 0.5 + w + 0.3), StreetNet.WALK), "then the houses")


func test_no_gaps_along_any_street() -> void:
	var n := _n()
	var gaps := []
	for link: Dictionary in n.links:
		var pts: PackedVector2Array = link.pts
		for i in pts.size() - 1:
			var steps := ceili(pts[i].distance_to(pts[i + 1]) / 1.5)
			for k in steps + 1:
				var p := pts[i].lerp(pts[i + 1], float(k) / steps)
				if not n.covers(p, StreetNet.ROAD) and not n.covers(p, StreetNet.ISLAND):
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


func test_the_mall_runs_on_past_streets_that_meet_the_boulevard_from_one_side() -> void:
	var n := _n()
	var whole := 0
	var cut := 0
	for k in n.nodes.size():
		var arms: Array = n.nodes[k].arms
		var blvd := []
		var others := []
		for arm: Dictionary in arms:
			(blvd if float(arm.mall) > 0.0 else others).append(arm)
		if blvd.size() != 2 or others.is_empty() or n.nodes[k].round > 0.0:
			continue
		var sides := 0
		for arm: Dictionary in others:
			sides |= 1 if (blvd[0].dir as Vector2).cross(arm.dir) > 0.0 else 2
		var on_mall := n.covers(n.nodes[k].at, StreetNet.MALL)
		if sides == 3:
			assert_false(on_mall, "a street crosses the boulevard at node %d: the walk stops" % k)
			cut += 1
		else:
			assert_true(on_mall, "a street meets the boulevard from one side at node %d: the walk goes on" % k)
			whole += 1
	assert_gt(whole, 3)
	assert_gt(cut, 2)


func test_every_square_opens_onto_streets() -> void:
	var n := _n()
	for sq: Dictionary in CityData.SQUARES:
		var touching := 0
		for p: Vector2 in sq.pts:
			if n.distance_to_street(_plan(p)) < 8.0:
				touching += 1
		assert_gt(touching, 1, "%s has streets along it, not houses all round" % sq.id)
