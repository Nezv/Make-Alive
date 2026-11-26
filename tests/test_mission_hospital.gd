extends TestCase
## The Hospital Dona Helena: the tower facing Rua Blumenau (HospitalSet, CityMap._hospital) and
## its mission: round the tower to the yard, hold it through three waves, then up the fire stair
## to board the helicopter on the roof.

const S := MissionRules.Status


func _mission() -> Game:
	var g := await new_game("city", "hospital")
	return g


func _kill_all(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)


func test_the_tower_faces_the_street_and_the_yard_is_reachable() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	var lot: Transform3D = m.hospital.frame
	assert_true(m.nav.is_blocked(lot * Vector3(-31, 0, 14)), "the tower is solid")
	assert_false(m.nav.is_blocked(lot * Vector3(-31, 0, -20)), "the drop-off lane is open")
	assert_gt(m.hospital.door.x, m.poi_pos("hospital").x - 40.0, "its door looks east")
	assert_true(m.nav.reachable(m.player_spawn_point(0), m.hospital.yard), "round the tower to the yard")
	var labels := m.root.find_children("*", "Label3D", true, false).map(func(l: Label3D) -> String: return l.text)
	assert_true(labels.has("HOSPITAL DONA HELENA"), "the lit sign on the tower")
	assert_true(labels.has("PRONTO ATENDIMENTO"), "the bay's sign")


func test_the_fire_stair_can_be_stood_on_all_the_way_to_the_roof() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	await frames(2)
	var space := m.root.get_world_3d().direct_space_state
	var climb: Array = m.hospital.climb
	assert_near((climb[-1] as Vector3).y, HospitalSet.ROOF_Y, 0.01, "the last landing is level with the roof")
	for i in range(1, climb.size()):
		var p: Vector3 = climb[i]
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.2, 0), p - Vector3(0, 1.0, 0)))
		assert_false(hit.is_empty(), "landing %d has a floor" % i)
		if not hit.is_empty():
			assert_near((hit.position as Vector3).y, p.y, 0.3, "landing %d is where the stair says" % i)
	var pad: Vector3 = m.hospital.pad
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(pad + Vector3(0, 2.0, 0), pad - Vector3(0, 1.0, 0)))
	assert_false(hit.is_empty(), "the helipad can be stood on")


func test_the_mission_has_its_data_and_it_fits_the_map() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	assert_eq(m.data.name, "hospital")
	assert_eq(m.data.errors, [], "the dictionary is sound")
	assert_eq(m.data.check(m), [], "spawns and closets on open ground, closets out of sight")
	var kinds := m.objective_defs.map(func(o: Dictionary) -> String: return o.kind)
	assert_eq(kinds, ["reach", "survive", "extract"])
	for slot in 8:
		assert_false(m.nav.is_blocked(m.player_spawn_point(slot)), "slot %d on open ground" % slot)
	for c: Dictionary in m.data.closets:
		assert_true(m.nav.reachable(c.at, m.hospital.yard), "zombies from '%s' can reach the yard" % c.id)


func test_reach_the_yard_hold_it_then_board_on_the_roof() -> void:
	var g: Game = await _mission()
	var m: CityMap = g.map
	g.set_physics_process(false)
	var me: Dictionary = g.players[1]
	me.pos = m.player_spawn_point(0)
	g.rules.step(0.5)
	assert_eq(g.rules.current().kind, "reach")
	me.pos = m.hospital.yard + Vector3(0, 0.1, 0)
	g.rules.step(0.5)
	assert_eq(g.rules.current().kind, "survive", "in the yard: hold it")
	assert_eq(g.rules.checkpoint, "yard", "and the dead come back here")
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
	me.pos = m.hospital.pad + Vector3(1.0, 0.2, 1.0)
	for i in 20:
		g.rules.step(0.5)
	assert_eq(g.rules.status, S.WON, "on the helipad: extracted")
