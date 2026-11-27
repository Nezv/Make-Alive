extends TestCase
## The 62º Batalhão de Infantaria: the compound round the parade ground (BatalhaoSet,
## CityMap._batalhao) and its mission, defending: in at the gate, hold the parade ground through
## three waves, then board the helicopter on the H at its middle.

const S := MissionRules.Status


func _mission() -> Game:
	var g := await new_game("city", "batalhao")
	return g


func _kill_all(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)


func test_the_blocks_close_round_the_ground_and_the_way_in_is_open() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	var lot: Transform3D = m.batalhao.frame
	assert_lt(Vector2(m.batalhao.gate.x, m.batalhao.gate.z).distance_to(Vector2(m.poi_pos("batalhao").x, m.poi_pos("batalhao").z)), 100.0,
		"the gate is near the ground's middle")
	assert_false(m.nav.is_blocked(m.batalhao.gate), "inside the gate is open")
	assert_false(m.nav.is_blocked(lot * Vector3(0, 0, BatalhaoSet.FRONT_Z)), "the way through the front block is open")
	assert_true(m.nav.is_blocked(lot * Vector3(-30, 0, BatalhaoSet.FRONT_Z)), "the front block is solid beside it")
	assert_true(m.nav.is_blocked(lot * Vector3(30, 0, BatalhaoSet.FRONT_Z)), "on both sides")
	assert_true(m.nav.is_blocked(lot * Vector3(-BatalhaoSet.SIDE_X, 0, BatalhaoSet.SIDE_Z)), "the west block is solid")
	assert_true(m.nav.is_blocked(lot * Vector3(0, 0, BatalhaoSet.HQ_Z)), "the headquarters is solid")
	assert_false(m.nav.is_blocked(m.batalhao.ground), "the parade ground is open")
	assert_false(m.nav.is_blocked(m.batalhao.pad), "the H is clear")
	assert_true(m.nav.reachable(m.batalhao.gate, m.batalhao.pad), "from the gate through the front block to the H")
	var labels := m.root.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)
	assert_true(labels.has("62ºBI"), "the number on the headquarters")
	assert_true(labels.has("62º BATALHÃO DE INFANTARIA"), "the name over the way in")


func test_the_mission_has_its_data_and_it_fits_the_map() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	assert_eq(m.data.name, "batalhao")
	assert_eq(m.data.errors, [], "the dictionary is sound")
	assert_eq(m.data.check(m), [], "spawns and closets on open ground, closets out of sight")
	var kinds := m.objective_defs.map(func(o: Dictionary) -> String: return o.kind)
	assert_eq(kinds, ["survive", "extract"])
	assert_eq((m.objective_defs[0].waves as Array).size(), 3)
	for slot in 8:
		assert_false(m.nav.is_blocked(m.player_spawn_point(slot)), "slot %d on open ground" % slot)
	assert_true(m.data.zone_contains("parade", m.batalhao.ground), "the parade ground is the zone")
	assert_true(m.data.zone_contains("pad", m.batalhao.pad + Vector3(0, 0.1, 0)), "the H is the way out")
	for c: Dictionary in m.data.closets:
		assert_true(m.nav.reachable(c.at, m.batalhao.ground), "zombies from '%s' can reach the ground" % c.id)


func test_hold_the_ground_then_board_on_the_h() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	g.set_physics_process(false)
	var me: Dictionary = g.players[1]
	me.pos = m.batalhao.ground + Vector3(0, 0.1, 0)
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
	me.pos = m.batalhao.pad + Vector3(1.0, 0.1, 1.0)
	for i in 20:
		g.rules.step(0.5)
	assert_eq(g.rules.status, S.WON, "on the H: extracted")
