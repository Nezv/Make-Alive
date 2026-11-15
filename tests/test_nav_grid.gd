extends TestCase
## Grid navigation for open maps: walk around vehicles and barricades, never through them.


## A 40 x 40 m field with one wall across the middle (x -10..10 at z = 0).
func _field() -> NavGrid:
	var n := NavGrid.new(Vector2(-20, -20), Vector2(20, 20), 0.5)
	n.block_rect(Vector2(0, 0), Vector2(10, 0.3))
	n.finish()
	return n


func test_blocked_inside_free_outside() -> void:
	var n := _field()
	assert_true(n.is_blocked(Vector3(0, 0, 0)))
	assert_true(n.is_blocked(Vector3(9.5, 0, 0)))
	assert_false(n.is_blocked(Vector3(0, 0, 3)))
	assert_false(n.is_blocked(Vector3(14, 0, 0)), "past the end of the wall")
	assert_true(n.is_blocked(Vector3(99, 0, 0)), "outside the map counts as blocked")


func test_rotated_obstacles_block_where_they_really_are() -> void:
	var n := NavGrid.new(Vector2(-20, -20), Vector2(20, 20), 0.5)
	n.block_rect(Vector2(0, 0), Vector2(6, 0.3), PI / 4.0) # a diagonal wall
	n.finish()
	assert_true(n.is_blocked(Vector3(3, 0, -3)) or n.is_blocked(Vector3(3, 0, 3)), "on the diagonal")
	assert_false(n.is_blocked(Vector3(5, 0, 0)), "beside the diagonal, where an unrotated wall would be")


func test_line_of_sight() -> void:
	var n := _field()
	assert_false(n.is_direct(Vector3(0, 0, 5), Vector3(0, 0, -5)), "the wall is in the way")
	assert_true(n.is_direct(Vector3(-5, 0, 5), Vector3(5, 0, 5)), "same side")
	assert_true(n.is_direct(Vector3(15, 0, 5), Vector3(15, 0, -5)), "around the end")


func test_walking_the_nav_targets_gets_around_the_wall() -> void:
	var n := _field()
	var pos := Vector3(0, 0, 6)
	var goal := Vector3(0, 0, -6)
	var steps := 0
	while pos.distance_to(goal) > 0.5 and steps < 400:
		var way := n.nav_target(pos, goal, 0.0) - pos
		way.y = 0.0
		pos += way.normalized() * 0.2
		assert_false(n.is_blocked(pos), "never walks into the wall (step %d at %s)" % [steps, pos])
		steps += 1
	assert_lt(pos.distance_to(goal), 0.6, "arrived")
	assert_gt(steps, 80, "it had to go the long way round")
	assert_lt(steps, 220, "but not absurdly long")


func test_direct_when_nothing_is_in_the_way() -> void:
	var n := _field()
	var to := Vector3(8, 0, 12)
	assert_eq(n.nav_target(Vector3(-8, 0, 12), to, 0.0), to)


func test_lanes_spread_a_crowd() -> void:
	var n := _field()
	var a := n.nav_target(Vector3(0, 0, 6), Vector3(0, 0, -6), -1.0)
	var b := n.nav_target(Vector3(0, 0, 6), Vector3(0, 0, -6), 1.0)
	assert_gt(a.distance_to(b), 0.2, "different lanes aim at different spots")
	assert_false(n.is_blocked(a))
	assert_false(n.is_blocked(b))


func test_targets_inside_obstacles_snap_to_free_ground() -> void:
	var n := _field()
	assert_true(n.reachable(Vector3(0, 0, 6), Vector3(0, 0, 0)), "goal inside the wall: go next to it")
	var free := n.nearest_free(Vector3(0, 0, 0))
	assert_false(n.is_blocked(free))
	assert_lt(free.distance_to(Vector3.ZERO), 2.0)


func test_sealed_areas_are_unreachable() -> void:
	var n := NavGrid.new(Vector2(-20, -20), Vector2(20, 20), 0.5)
	for side in [[Vector2(0, -4), Vector2(4.5, 0.3)], [Vector2(0, 4), Vector2(4.5, 0.3)],
			[Vector2(-4, 0), Vector2(0.3, 4.5)], [Vector2(4, 0), Vector2(0.3, 4.5)]]:
		n.block_rect(side[0], side[1])
	n.finish()
	assert_false(n.reachable(Vector3(10, 0, 10), Vector3(0, 0, 0)), "boxed in")
	assert_true(n.reachable(Vector3(10, 0, 10), Vector3(-10, 0, -10)))
