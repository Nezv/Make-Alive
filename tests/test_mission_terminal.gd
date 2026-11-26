extends TestCase
## The Terminal Central: the platforms under the concrete roof (TerminalSet, CityMap._terminal) and
## its mission, a run: out of the terminal, a checkpoint halfway, on to the Prefeitura's pad.

const S := MissionRules.Status


func _mission() -> Game:
	var g := await new_game("city", "terminal")
	return g


func test_the_platforms_stand_under_the_roof_and_the_way_out_is_open() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	var lot: Transform3D = m.terminal.frame
	assert_false(m.nav.is_blocked(m.terminal.platform), "the middle island is open")
	assert_false(m.nav.is_blocked(m.terminal.gate), "the way in from the street is open")
	assert_true(m.nav.is_blocked(lot * Vector3(-30, 0, TerminalSet.FRONT_Z + 4.0)), "the ticket hall is solid")
	assert_true(m.nav.reachable(m.terminal.platform, m.terminal.gate), "from the platforms out to the street")
	var labels := m.root.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)
	assert_true(labels.has("TERMINAL CENTRAL"), "the sign over the way in")
	await frames(2)
	var space := m.root.get_world_3d().direct_space_state
	var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(m.terminal.platform + Vector3(6, 1.0, 0), m.terminal.platform + Vector3(6, 20.0, 0)))
	assert_true(up.is_empty(), "the roof does not stop bullets fired up (it has no collision)")


func test_the_mission_has_its_data_and_it_fits_the_map() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	assert_eq(m.data.name, "terminal")
	assert_eq(m.data.errors, [], "the dictionary is sound")
	assert_eq(m.data.check(m), [], "spawns and closets on open ground, closets out of sight")
	var kinds := m.objective_defs.map(func(o: Dictionary) -> String: return o.kind)
	assert_eq(kinds, ["reach", "extract"])
	for slot in 8:
		assert_false(m.nav.is_blocked(m.player_spawn_point(slot)), "slot %d on open ground" % slot)
	var mid := m.data.zone_center("halfway")
	assert_true(m.nav.reachable(m.player_spawn_point(0), mid), "the run reaches the checkpoint")
	assert_true(m.nav.reachable(mid, m.prefeitura.pad), "and the Prefeitura's pad from there")


func test_run_to_the_checkpoint_then_the_pad() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	g.set_physics_process(false)
	var me: Dictionary = g.players[1]
	me.pos = m.player_spawn_point(0)
	g.rules.step(0.5)
	assert_eq(g.rules.current().kind, "reach")
	me.pos = m.data.zone_center("halfway")
	g.rules.step(0.5)
	assert_eq(g.rules.checkpoint, "halfway", "the dead come back at the checkpoint")
	assert_eq(g.rules.current().kind, "extract")
	me.pos = m.prefeitura.pad + Vector3(1.0, 0.2, 1.0)
	for i in 20:
		g.rules.step(0.5)
	assert_eq(g.rules.status, S.WON, "on the pad: out")
