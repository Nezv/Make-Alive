extends TestCase
## The OpenStreetMap tiles traced into scripts/world/city_osm.gd (tools/trace_osm.py): every tile
## registered onto joinville.png by two control points, building footprints, streets by class, water,
## parks, parking and forest, and the gaps between tiles reported.


func _inside(p: Vector2, poly: Array) -> bool:
	return Geometry2D.is_point_in_polygon(p, PackedVector2Array(poly))


func test_every_tile_has_two_control_points_at_a_quarter_scale() -> void:
	assert_eq(CityOsm.TILES.size(), 9)
	for n: int in CityOsm.TILES:
		var cp: Array = CityOsm.TILES[n]
		var t0: Vector2 = cp[0][0]
		var j0: Vector2 = cp[0][1]
		var t1: Vector2 = cp[1][0]
		var j1: Vector2 = cp[1][1]
		assert_near((j1.x - j0.x) / (t1.x - t0.x), 0.25, 0.001, "tile %d: four times the zoom" % n)
		assert_near((j1.y - j0.y) / (t1.y - t0.y), 0.25, 0.001)


func test_the_terminal_the_prefeitura_and_the_hospital_land_in_their_lots() -> void:
	for poi in ["terminal", "prefeitura", "hospital"]:
		var lot: Array = CityData.POIS[poi].lot
		var found := 0
		for b: Array in CityOsm.BUILDINGS:
			if float(b[1]) >= 300.0 and _inside(b[2], lot):
				found += 1
		assert_gt(found, 0, "%s: a footprint of its own inside its lot" % poi)


func test_there_are_buildings_streets_of_every_class_and_the_river() -> void:
	assert_gt(CityOsm.BUILDINGS.size(), 800)
	for b: Array in CityOsm.BUILDINGS:
		assert_true((b[0] as Array).size() >= 3, "a footprint has corners")
	for k in ["trunk", "primary", "secondary", "residential", "pedestrian"]:
		assert_gt((CityOsm.STREETS[k] as Array).size(), 10, k)
	var river := false
	for p: Dictionary in CityOsm.AREAS.water:
		for q: Vector2 in CityData.RIVER:
			if _inside(q, p.outer):
				river = true
	assert_true(river, "the Rio Cachoeira is water")
	assert_gt((CityOsm.AREAS.forest as Array).size(), 0)
	assert_gt((CityOsm.AREAS.park as Array).size(), 0)
	assert_true(CityOsm.GAPS is Array, "the gaps are reported")
