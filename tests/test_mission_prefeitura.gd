extends TestCase
## The Prefeitura: the city hall block on the east bank (PrefeituraSet, CityMap._prefeitura) and
## its mission, defending: hold the forecourt through three waves, then board the helicopter on the
## round pad on the south lawn.

const S := MissionRules.Status


func _mission() -> Game:
	var g := await new_game("city", "prefeitura")
	return g


func _kill_all(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)


func test_the_building_faces_the_avenue_and_its_lawn_stays_open() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	var lot: Transform3D = m.prefeitura.frame
	assert_true(m.nav.is_blocked(lot * Vector3(0, 0, CityMap.PREFEITURA_BUILDING_Z)), "the block is solid")
	assert_true(m.nav.is_blocked(lot * Vector3(30, 0, CityMap.PREFEITURA_BUILDING_Z)), "all along its length")
	assert_false(m.nav.is_blocked(lot * Vector3(0, 0, -30)), "the walk down the lawn is open")
	var door: Vector3 = m.prefeitura.door
	assert_lt(door.x, m.poi_pos("prefeitura").x + 20.0, "its door looks west")
	assert_gt(door.x, m.poi_pos("prefeitura").x, "from behind the lawn")
	var labels := m.root.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)
	assert_true(labels.has("Prefeitura Municipal de Joinville"), "the sign on the lawn")


func test_the_mission_has_its_data_and_it_fits_the_map() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	assert_eq(m.data.name, "prefeitura")
	assert_eq(m.data.errors, [], "the dictionary is sound")
	assert_eq(m.data.check(m), [], "spawns and closets on open ground, closets out of sight")
	var kinds := m.objective_defs.map(func(o: Dictionary) -> String: return o.kind)
	assert_eq(kinds, ["survive", "extract"])
	assert_eq((m.objective_defs[0].waves as Array).size(), 3)
	for slot in 8:
		var p := m.player_spawn_point(slot)
		assert_true(m.data.zone_contains("forecourt", p), "slot %d starts on the forecourt" % slot)
		assert_false(m.nav.is_blocked(p))
	for c: Dictionary in m.data.closets:
		assert_true(m.nav.reachable(c.at, m.player_spawn_point(0)), "zombies from '%s' can reach the door" % c.id)


func test_hold_the_forecourt_then_board_on_the_pad() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	g.set_physics_process(false)
	var me: Dictionary = g.players[1]
	me.pos = m.player_spawn_point(0)
	assert_eq(g.rules.current().kind, "survive")
	for i in 60:
		g.rules.step(0.5)
		_kill_all(g)
		g.rules.step(30.0)
		if g.rules.heli_left >= 0.0:
			break
	assert_gt(g.rules.heli_left, 0.0, "after the waves the helicopter is on its way")
	for i in 40:
		g.rules.step(5.0)
		_kill_all(g)
		if g.rules.current().kind == "extract":
			break
	assert_eq(g.rules.current().kind, "extract")
	var pad: Vector3 = m.prefeitura.pad
	me.pos = pad + Vector3(1.0, 0.1, 1.0)
	for i in 20:
		g.rules.step(0.5)
	assert_eq(g.rules.status, S.WON, "on the pad: extracted")
