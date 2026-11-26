extends TestCase
## The room producer in the town (S246): some row houses open, their floors are laid out by
## HousePlan and built near the camera, the shell is cut away and the front's box turned off.

static var _city: CityMap


func _m() -> CityMap:
	if _city == null:
		_city = GameMap.create("city")
	return _city


static func after_all() -> void:
	if _city != null:
		_city.root.free()
	_city = null


func test_some_houses_open_and_the_pick_is_the_same_every_time() -> void:
	var m := _m()
	assert_true(m.blocks.open_houses.size() > 50, "open houses: %d" % m.blocks.open_houses.size())
	var again := CityMap.new(false)
	assert_eq(again.blocks.open_houses, m.blocks.open_houses, "every peer opens the same houses")
	again.root.free()


func test_an_open_house_near_the_terminal_is_built_and_its_street_door_faces_the_street() -> void:
	var m := _m()
	assert_true(m.houses != null, "the city has a streamer")
	var at := m.poi_pos("terminal")
	var nearest := -1
	var best := INF
	for i: int in m.blocks.open_houses:
		var d := (m.blocks.house_box(i)[0] as Vector2).distance_to(Vector2(at.x, at.z))
		if d < best:
			best = d
			nearest = i
	var c: Vector2 = m.blocks.house_box(nearest)[0]
	m.houses.build_near(Vector3(c.x, 0, c.y))
	assert_true(m.houses.built.has(nearest), "the nearest open house stands (failed: %s)" % str(m.houses.failed.has(nearest)))
	var node: Node3D = m.houses.built[nearest]
	assert_true(node.get_child_count() >= 2, "floors built")
	var h: Dictionary = m.blocks.houses[nearest]
	assert_true((h.front_shape as CollisionShape3D) != null, "its street front has its own box")
	# The plan's z axis points into the block: away from the street side (h.out).
	var inward := node.transform.basis.z
	var out: Vector2 = h.out
	assert_true(Vector2(inward.x, inward.z).dot(out) < -0.9, "plan z runs into the block")
	# The plan's origin sits inside the footprint, by the street front.
	var o := Vector2(node.position.x, node.position.z)
	assert_true(Geometry2D.is_point_in_polygon(o + Vector2(inward.x, inward.z) * 0.2 + Vector2(node.transform.basis.x.x, node.transform.basis.x.z) * 0.2, h.foot),
		"the plan starts inside the house")
	var shell := m.houses.shell
	assert_true(int(shell.get_shader_parameter("holes")) >= 1, "the shell is cut")
	m.houses._take_down(nearest)
	assert_false(m.houses.built.has(nearest), "taken down")
	assert_eq(int(shell.get_shader_parameter("holes")), m.houses.built.size(), "hole count follows")
