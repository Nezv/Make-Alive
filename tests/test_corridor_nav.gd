extends TestCase
## The test map is an L: leg A runs along +Z (players spawn there), leg B along +X (zombies
## come from there). Chokepoints: the corner at the origin and the doorway at x = DOOR_X.


func test_same_leg_goes_straight_to_target() -> void:
	var to := Vector3(1, 0, 25)
	assert_eq(CorridorMap.nav_target(Vector3(0, 0, 10), to), to)


func test_other_leg_routes_through_the_corner() -> void:
	var way := CorridorMap.nav_target(Vector3(8, 0, 0), Vector3(0, 0, 20))
	assert_lt(way.length(), 3.0, "waypoint is in the corner square")


func test_far_side_of_door_routes_through_the_doorway_first() -> void:
	var way := CorridorMap.nav_target(Vector3(30, 0, 2), Vector3(0, 0, 20))
	assert_near(way.x, CorridorMap.DOOR_X, 0.01)
	assert_lt(absf(way.z), CorridorMap.DOOR_HALF, "inside the door opening")
	assert_eq(CorridorMap.next_choke(Vector3(30, 0, 2), Vector3(0, 0, 20)), CorridorMap.CHOKE_DOOR)


func test_lane_spreads_zombies_across_the_corner() -> void:
	var a := CorridorMap.nav_target(Vector3(8, 0, 0), Vector3(0, 0, 20), -1.0)
	var b := CorridorMap.nav_target(Vector3(8, 0, 0), Vector3(0, 0, 20), 1.0)
	assert_gt(a.distance_to(b), 2.0)


func test_is_direct() -> void:
	assert_true(CorridorMap.is_direct(Vector3(0, 0, 10), Vector3(0, 0, 25)))
	assert_false(CorridorMap.is_direct(Vector3(10, 0, 0), Vector3(0, 0, 25)))


func test_spawn_points_are_past_the_door_inside_leg_b() -> void:
	for i in 20:
		var p := CorridorMap.zombie_spawn_point()
		assert_gt(p.x, CorridorMap.DOOR_X + 5.0)
		assert_lt(absf(p.z), CorridorMap.HALF_W)
