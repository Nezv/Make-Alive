extends TestCase
## The extraction helicopter (Helicopter): its flight in, the body language, the rotor and the
## lights, and how a match shows it from the mission's state on every peer.

const LAND := Transform3D(Basis(Vector3.UP, 0.6), Vector3(100, 40, -50))


func _pose(t: float) -> Transform3D:
	return Helicopter.flight_pose(t, LAND)


func _local(t: float) -> Vector3:
	return LAND.affine_inverse() * _pose(t).origin


func test_it_comes_from_far_and_high_and_ends_where_it_lands() -> void:
	var start := _pose(0.0).origin
	assert_gt(start.distance_to(LAND.origin), 400.0, "it starts far off")
	assert_gt(start.y - LAND.origin.y, 80.0, "and high")
	var end := _pose(Config.HELI_FLIGHT)
	assert_lt(end.origin.distance_to(LAND.origin), 0.05, "it settles on its spot")
	assert_lt(end.basis.z.angle_to(LAND.basis.z), 0.05, "facing the way the map wants")


func test_the_flight_is_smooth_and_not_too_fast() -> void:
	var dt := 0.05
	var top := 0.0
	var prev := _pose(0.0).origin
	var t := dt
	while t <= Config.HELI_FLIGHT:
		var p := _pose(t).origin
		top = maxf(top, p.distance_to(prev) / dt)
		prev = p
		t += dt
	assert_lt(top, 70.0, "no jumps: under 250 km/h all the way")
	var last := _pose(Config.HELI_FLIGHT - 0.2).origin.distance_to(_pose(Config.HELI_FLIGHT).origin) / 0.2
	assert_lt(last, 1.0, "it slows to a hover before it settles")


func test_it_circles_once_banking_into_the_turn() -> void:
	var seen_sides := {}
	var bank := 0.0
	for i in 100:
		var t := Config.HELI_FLIGHT * (0.35 + 0.5 * i / 100.0)
		var p := _local(t)
		seen_sides[Vector2i(signi(roundi(p.x / 20.0)), signi(roundi(p.z / 20.0)))] = true
		bank = maxf(bank, absf(_roll(_pose(t).basis)))
	assert_gt(seen_sides.size(), 4, "it goes round the landing spot")
	assert_gt(rad_to_deg(bank), 10.0, "leaning into the turn")


func _roll(b: Basis) -> float:
	var right := b.x
	return asin(clampf(-right.y, -1.0, 1.0))


func _pitch(b: Basis) -> float:
	var fwd := -b.z
	return asin(clampf(fwd.y, -1.0, 1.0))


func test_it_flares_nose_up_before_it_settles() -> void:
	var flare := -1.0
	var t := Config.HELI_FLIGHT - 10.0
	while t < Config.HELI_FLIGHT:
		flare = maxf(flare, _pitch(_pose(t).basis))
		t += 0.1
	assert_gt(rad_to_deg(flare), 4.0, "nose up to bleed off speed")
	var cruise := _pitch(_pose(Config.HELI_FLIGHT * 0.1).basis)
	assert_lt(rad_to_deg(cruise), 1.0, "nose level or down on the way in")


func test_it_sways_in_the_hover() -> void:
	var h := Helicopter.new()
	h.setup(LAND)
	add_child(h)
	var seen := []
	for i in 30:
		h.hover(0.1)
		seen.append(h.transform.origin)
	var spread := 0.0
	for p: Vector3 in seen:
		spread = maxf(spread, p.distance_to(LAND.origin))
	assert_gt(spread, 0.05, "never quite still")
	assert_lt(spread, 0.8, "but holds its spot")
	h.free()


func test_the_rotor_blurs_into_a_disc_at_speed_and_the_lights_blink() -> void:
	var h := Helicopter.new()
	h.setup(LAND)
	add_child(h)
	h.arrive(Config.HELI_FLIGHT * 0.5)
	assert_true(h.blur.visible, "a spinning rotor is a translucent disc")
	assert_false(h.blades.visible, "not a stopped set of blades")
	assert_true(h.nav_red.visible and h.nav_green.visible, "red and green nav lights")
	var on := 0
	for i in 40:
		h.hover(0.05)
		if h.strobe.visible:
			on += 1
	assert_gt(on, 0, "the white strobe flashes")
	assert_lt(on, 40, "and goes dark between flashes")
	h.free()


func test_it_lifts_off_and_flies_away_once_everyone_is_aboard() -> void:
	var h := Helicopter.new()
	h.setup(LAND)
	add_child(h)
	h.hover(0.1)
	for i in 100:
		h.depart(0.1)
	assert_gt(h.transform.origin.y - LAND.origin.y, 30.0, "it climbs away")
	h.free()


## A map whose data has a helicopter spot and a defend objective with one coming.
func _heli_game() -> Game:
	var g := await new_game()
	var data := MapAreas.CORRIDOR.duplicate(true)
	data["heli"] = { "at": Vector3(31, 6, 0), "yaw": 0.0 }
	g.map.use_data(data)
	g.rules.start([]) # no objectives running: the tests say where the mission stands
	return g


func test_a_match_shows_it_only_once_it_is_on_its_way() -> void:
	var g: Game = await _heli_game()
	g.mission_view = { "index": 0, "status": MissionRules.Status.RUNNING, "kind": "survive", "heli": true, "left": Config.HELI_FLIGHT + 30.0,
		"counting": true, "zone": "", "text": "", "reason": "", "id": "", "wave": 1, "waves": 1, "calm": false, "has_marker": false, "marker": Vector3.ZERO }
	await seconds(0.2)
	assert_true(g.helicopter == null or not g.helicopter.visible, "still far away: not drawn")
	g.mission_view.left = Config.HELI_FLIGHT * 0.5
	await seconds(0.2)
	assert_true(g.helicopter != null and g.helicopter.visible, "on its way in")
	assert_gt(g.helicopter.position.distance_to(Vector3(31, 6, 0)), 20.0, "still flying in")


func test_it_holds_over_its_spot_while_the_extraction_runs() -> void:
	var g: Game = await _heli_game()
	g.mission_view = { "index": 1, "status": MissionRules.Status.RUNNING, "kind": "extract", "heli": false, "left": 5.0,
		"counting": false, "zone": "exit", "text": "", "reason": "", "id": "", "wave": 0, "waves": 0, "calm": false, "has_marker": false, "marker": Vector3.ZERO }
	await seconds(0.2)
	assert_true(g.helicopter != null, "it's there")
	assert_lt(g.helicopter.position.distance_to(Vector3(31, 6, 0)), 1.0, "hovering at its spot")
