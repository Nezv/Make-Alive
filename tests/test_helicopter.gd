extends TestCase
## The helicopter: a box-built military transport that flies a fixed path every peer works out from
## (landing point, heading, time): in high, one circle, a nose-up flare, down on its skids. Rotor
## blades blur at speed and droop when stopped; lights blink; its downwash kicks up dust and shakes
## the view; a door gunner fires at the horde while it is low; players who reach the door are sat
## inside and it lifts off with them.

const LZ := Vector3(0, 0, 26)


func _flight() -> HeliFlight:
	return HeliFlight.new(LZ, 0.6)


# --- The model ------------------------------------------------------------------------

func test_the_model_has_its_moving_parts_and_lights() -> void:
	var h := Helicopter.new()
	add_child(h)
	for part in [h.body, h.main_rotor, h.blades, h.blur, h.tail_rotor, h.door_l, h.door_r, h.skids, h.nav_red, h.nav_green, h.strobe, h.beacon, h.gunner]:
		assert_true(part != null and part.is_inside_tree(), "every part is built")
	assert_true(h.beacon.shadow_enabled == false, "no shadows from its lights")
	var meshes := h.find_children("*", "MeshInstance3D", true, false).size()
	assert_true(meshes <= Config.HELI_MAX_MESHES, "a handful of draws: %d" % meshes)
	h.free()


func test_the_rotor_blurs_at_speed_and_the_blades_droop_when_stopped() -> void:
	var h := Helicopter.new()
	add_child(h)
	h.set_rotor(0.0, 0.1)
	assert_true(h.blades.visible and not h.blur.visible, "stopped: blades")
	assert_lt(h.blade_droop(), -0.02, "and they sag")
	h.set_rotor(1.0, 0.1)
	assert_true(h.blur.visible and not h.blades.visible, "at speed: a disc")
	var turn := h.main_rotor.rotation.y
	h.set_rotor(1.0, 0.05)
	assert_true(absf(h.main_rotor.rotation.y - turn) > 0.1, "and it turns")
	h.free()


# --- The flight -----------------------------------------------------------------------

func test_it_comes_in_high_circles_once_flares_and_lands() -> void:
	var f := _flight()
	var start := f.pose(0.0)
	assert_gt(Vector2(start.pos.x - LZ.x, start.pos.z - LZ.z).length(), 150.0, "from far off")
	assert_gt((start.pos as Vector3).y - LZ.y, 35.0, "and high")
	var circled := false
	var banked := false
	var flared := false
	var t := 0.0
	while t < HeliFlight.LAND_AT:
		var p := f.pose(t)
		if p.phase == HeliFlight.Phase.CIRCLE:
			circled = circled or absf(Vector2(p.pos.x - LZ.x, p.pos.z - LZ.z).length() - HeliFlight.CIRCLE_R) < 1.0
			banked = banked or absf(p.roll) > 0.08
		if p.phase == HeliFlight.Phase.DESCEND and p.pitch > 0.05:
			flared = true
		t += 0.1
	assert_true(circled, "one circle round the landing point")
	assert_true(banked, "banked into the turn")
	assert_true(flared, "nose up to slow down")
	var down := f.pose(HeliFlight.LAND_AT)
	assert_eq(down.phase, HeliFlight.Phase.LANDED)
	assert_lt((down.pos as Vector3).distance_to(LZ), 0.05, "on the spot")
	assert_gt(down.compress, 0.5, "skids squashed")
	assert_eq(f.pose(HeliFlight.LAND_AT + 200.0).phase, HeliFlight.Phase.LANDED, "it waits")


func test_it_lifts_off_when_told_and_is_gone() -> void:
	var f := _flight()
	var at := HeliFlight.LAND_AT + 10.0
	f.depart_at = at
	assert_eq(f.pose(at - 0.1).phase, HeliFlight.Phase.LANDED)
	var up := f.pose(at + 5.0)
	assert_eq(up.phase, HeliFlight.Phase.DEPART)
	assert_gt((up.pos as Vector3).y, LZ.y + 10.0, "climbing away")
	assert_eq(f.pose(at + HeliFlight.DEPART_TIME + 1.0).phase, HeliFlight.Phase.GONE)


func test_every_peer_works_out_the_same_flight() -> void:
	var a := _flight()
	var b := HeliFlight.new(LZ, 0.6)
	for t in [0.0, 3.3, 11.1, 19.9, HeliFlight.LAND_AT - 0.5]:
		assert_eq(a.pose(t), b.pose(t))


# --- In a match -----------------------------------------------------------------------

func _game() -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	return g


func test_the_host_calls_it_and_everyone_flies_the_same_one() -> void:
	var g := await _game()
	var other := await new_game() # (made first: no frames may pass between the call and the copy)
	g.call_heli(LZ, 10.0)
	assert_true(g.heli != null, "built on this peer")
	assert_near(g.heli_t, HeliFlight.LAND_AT - 10.0, 0.001, "timed to land when the mission says")
	var state := g.welcome_rules().get("heli", {}) as Dictionary
	assert_false(state.is_empty(), "late joiners get it")
	other.apply_heli_state(state)
	assert_true(other.heli != null)
	assert_eq(other.heli_flight.pose(other.heli_t), g.heli_flight.pose(g.heli_t))
	var before := g.heli_t
	g.step_heli(1.0)
	assert_near(g.heli_t, before + 1.0, 0.001)


func test_the_last_wave_calls_the_helicopter() -> void:
	var g := await _game()
	var o := { "kind": "survive", "waves": [{ "size": 1, "types": {}, "gap": 0.0, "closets": [] }], "heli": 30.0, "zone": "" }
	g.rules._send_wave(o)
	assert_true(g.heli != null, "on its way")
	assert_near(HeliFlight.LAND_AT - g.heli_t, 30.0, 0.01, "landing as the clock runs out")


func test_its_downwash_kicks_up_dust_and_shakes_you_underneath() -> void:
	var g := await _game()
	g.call_heli(g.local_player.global_position, 0.5) # half a second from touchdown, right over you
	var bursts: int = g.fx.stats.bursts
	g.step_heli(0.2)
	assert_gt(g.fx.stats.bursts, bursts, "dust blown out on the ground")
	assert_gt(g.local_player.wash_shake, 0.0, "the view trembles")
	g.local_player.global_position += Vector3(Config.HELI_WASH_RADIUS * 3.0, 0, 0)
	g.step_heli(0.2)
	assert_eq(g.local_player.wash_shake, 0.0, "not from far off")


func test_the_door_gunner_fires_at_the_horde_while_it_is_low() -> void:
	var g := await _game()
	g.call_heli(LZ, 0.0) # on the ground
	var z := g.spawn_zombie(Zombie.Type.WALKER, LZ + Vector3(12, 0.1, 0))
	var hp := z.hp
	var far := g.spawn_zombie(Zombie.Type.WALKER, LZ + Vector3(Config.HELI_GUNNER_RANGE + 20, 0.1, 0))
	var far_hp := far.hp
	g.step_heli(Config.HELI_GUNNER_INTERVAL * 1.5)
	assert_lt(z.hp, hp, "the near one is hit")
	assert_eq(far.hp, far_hp, "out of range")
	assert_eq(g.fx.last_kind, Fx.Kind.TRACER, "a tracer from the door")


func test_players_at_the_door_are_sat_inside_and_it_lifts_off_with_everyone() -> void:
	var g := await _game()
	var calls := spy(g)
	g._add_player(7, "Guest")
	g.players[1].pos = LZ + Vector3(-40, 0, 0) # both away from the door when it lands
	g.players[7].pos = LZ + Vector3(40, 0, 0)
	g.call_heli(LZ, 0.0)
	var door := g.heli.door_point()
	g.players[1].pos = door
	g.step_heli(0.1)
	assert_true(g.players[1].boarded, "in")
	assert_eq(count(calls, &"on_heli_boarded"), 1)
	assert_true(g.local_player.seat != null, "your view sits in the cabin")
	assert_eq(g.heli_flight.depart_at, INF, "waits for the others")
	g.players[7].pos = door
	g.step_heli(0.1)
	assert_true(g.heli_flight.depart_at < INF, "everyone aboard: off")
	assert_eq(count(calls, &"on_heli_departed"), 1)
	g.step_heli(6.0)
	assert_gt(g.local_player.seat.global_position.y, LZ.y + 8.0, "the city falls away")
