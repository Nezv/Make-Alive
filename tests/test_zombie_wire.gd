extends TestCase
## Zombie snapshots must fit in one network packet even with a full horde.

const MTU := 1392


func test_round_trip_keeps_everything_that_matters() -> void:
	var bytes := ZombieWire.pack([
		{ "zid": 70000, "pos": Vector3(-2.37, 1.52, 41.9), "yaw": -2.5, "state": Zombie.State.LEAP,
			"type": Zombie.Type.LEAPER, "mask": (1 << Humanoid.Part.ARM_L) | (1 << Humanoid.Part.LEG_R) },
		{ "zid": 3, "pos": Vector3(0, 0, 0), "yaw": 3.1, "state": Zombie.State.CHASE,
			"type": Zombie.Type.WALKER, "mask": 0 },
	])
	var out := ZombieWire.unpack(bytes)
	assert_eq(out.size(), 2)
	var a: Dictionary = out[0]
	assert_eq(a.zid, 70000)
	assert_true((a.pos as Vector3).distance_to(Vector3(-2.37, 1.52, 41.9)) < 0.02, "position within 2 cm")
	assert_near(angle_difference(a.yaw, -2.5), 0.0, 0.03, "yaw within ~1.5 degrees")
	assert_eq(a.state, Zombie.State.LEAP)
	assert_eq(a.type, Zombie.Type.LEAPER)
	assert_eq(a.mask, (1 << Humanoid.Part.ARM_L) | (1 << Humanoid.Part.LEG_R))
	assert_eq(out[1].zid, 3)
	assert_near(angle_difference(out[1].yaw, 3.1), 0.0, 0.03)


func test_full_horde_fits_in_one_packet() -> void:
	var list := []
	for i in Config.ZOMBIE_MAX:
		list.append({ "zid": 100000 + i, "pos": Vector3(i, 1, -i), "yaw": 1.0, "state": 0, "type": 0, "mask": 0 })
	var bytes := ZombieWire.pack(list)
	# Leave room for 8 players and RPC overhead in the same packet.
	assert_lt(bytes.size(), MTU - Config.MAX_PLAYERS * PlayerWire.BYTES_EACH - 40, "zombie block size")


func test_positions_far_from_the_origin_survive() -> void:
	# The city is kilometres wide: the hospital is 650 m west of the origin, the Mirante 1.8 km east
	# and 230 m up. A horde there must not be squeezed back toward the middle of the map.
	for at: Vector3 in [Vector3(-658.4, 0.1, -222.5), Vector3(1867.2, 230.6, -1031.9)]:
		var out := ZombieWire.unpack(ZombieWire.pack([
			{ "zid": 1, "pos": at, "yaw": 0.0, "state": 0, "type": 0, "mask": 0 },
			{ "zid": 2, "pos": at + Vector3(-40.25, 1.5, 61.75), "yaw": 0.0, "state": 0, "type": 0, "mask": 0 },
		]))
		assert_lt((out[0].pos as Vector3).distance_to(at), 0.02, "first zombie at %s" % at)
		assert_lt((out[1].pos as Vector3).distance_to(at + Vector3(-40.25, 1.5, 61.75)), 0.02, "its neighbour")


func test_empty_list() -> void:
	assert_eq(ZombieWire.unpack(ZombieWire.pack([])).size(), 0)


# --- Room to grow: twelve types, more states, flags, still 13 bytes ----------------------------

func _z(zid: int, extra := {}) -> Dictionary:
	var z := { "zid": zid, "pos": Vector3(zid, 1, -zid), "yaw": 1.0, "state": 0, "type": 0, "mask": 0 }
	z.merge(extra, true)
	return z


func test_twelve_types_and_thirty_two_states_still_take_thirteen_bytes() -> void:
	assert_eq(ZombieWire.BYTES_EACH, 13)
	var list := []
	for t in 12:
		list.append(_z(100 + t, { "type": t, "state": (t * 3) % 32 }))
	list.append(_z(200, { "type": 11, "state": 31 }))
	var bytes := ZombieWire.pack(list)
	assert_eq(bytes.size(), ZombieWire.HEADER + 13 * list.size())
	var out := ZombieWire.unpack(bytes)
	for i in list.size():
		assert_eq(out[i].zid, list[i].zid)
		assert_eq(out[i].type, list[i].type, "type %d" % i)
		assert_eq(out[i].state, list[i].state, "state %d" % i)


func test_flags_and_armour_ride_in_the_spare_bits() -> void:
	var all_flags: int = ZombieWire.FLAG_BURNING | ZombieWire.FLAG_CLIMBING | ZombieWire.FLAG_CRAWLING
	assert_eq(all_flags, 7, "three separate bits")
	var list := [
		_z(1),
		_z(2, { "flags": ZombieWire.FLAG_BURNING }),
		_z(3, { "flags": ZombieWire.FLAG_CLIMBING | ZombieWire.FLAG_CRAWLING }),
		_z(4, { "flags": all_flags, "armour": 15, "type": 11, "state": 31, "mask": 0xFF }),
		_z(5, { "armour": 10 }),
	]
	var out := ZombieWire.unpack(ZombieWire.pack(list))
	assert_eq(out[0].flags, 0)
	assert_eq(out[0].armour, 0)
	assert_eq(out[1].flags, ZombieWire.FLAG_BURNING)
	assert_eq(out[2].flags, ZombieWire.FLAG_CLIMBING | ZombieWire.FLAG_CRAWLING)
	assert_eq(out[3].flags, all_flags)
	assert_eq(out[3].armour, 15)
	assert_eq(out[3].type, 11, "and the rest is not disturbed")
	assert_eq(out[3].state, 31)
	assert_eq(out[3].mask, 0xFF)
	assert_eq(out[4].armour, 10)
	assert_eq(out[4].flags, 0)


func test_ids_have_room_for_sixteen_million_zombies() -> void:
	var out := ZombieWire.unpack(ZombieWire.pack([_z(0xFFFFFF), _z(70000), _z(0x1000000 + 5)]))
	assert_eq(out[0].zid, 0xFFFFFF)
	assert_eq(out[1].zid, 70000)
	assert_eq(out[2].zid, 5, "a match never gets that far; if it does the old ids are long dead")


func test_a_horde_using_every_field_still_fits_with_eight_players() -> void:
	var list := []
	for i in Config.ZOMBIE_MAX:
		list.append(_z(0xFFFF00 + i, { "type": i % 12, "state": i % 32, "mask": 0xFF, "flags": 7, "armour": 15 }))
	assert_lt(ZombieWire.pack(list).size(), MTU - Config.MAX_PLAYERS * PlayerWire.BYTES_EACH - 40)


func test_the_host_flags_the_crawlers() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	var walker := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 5))
	var cripple := g.spawn_zombie(Zombie.Type.WALKER, Vector3(2, 0.1, 5))
	Humanoid.discard(cripple.rig.sever(Humanoid.Part.LEG_L))
	var out := ZombieWire.unpack(ZombieWire.pack(g.build_snapshot()[1]))
	var by_id := {}
	for e: Dictionary in out:
		by_id[e.zid] = e
	assert_eq(by_id[walker.zid].flags, 0)
	assert_eq(by_id[cripple.zid].flags & ZombieWire.FLAG_CRAWLING, ZombieWire.FLAG_CRAWLING)


# --- Interest management ----------------------------------------------------------------------

func _crowd(n: int) -> Array:
	var list := []
	for i in n:
		list.append(_z(1000 + i, { "pos": Vector3(i * 1.0, 0.1, 0) })) # a line away from the viewer at the origin
	return list


func test_everything_goes_to_everyone_while_it_fits_in_a_packet() -> void:
	assert_gt(Interest.budget(Config.MAX_PLAYERS), Config.ZOMBIE_MAX - 1, "today's cap fits with eight players")
	var list := _crowd(Config.ZOMBIE_MAX)
	assert_eq(Interest.pick(list, Vector3.ZERO, 0, Interest.budget(Config.MAX_PLAYERS)), list)
	assert_gt(Interest.budget(1), Interest.budget(Config.MAX_PLAYERS), "fewer players, more room")


func test_a_crowd_over_the_budget_sends_the_nearest_every_tick_and_the_far_ones_in_turn() -> void:
	var budget := 60
	var list := _crowd(150)
	var seen := {}
	var near_each_tick := true
	for tick in 12:
		var picked := Interest.pick(list, Vector3.ZERO, tick, budget)
		assert_true(picked.size() <= budget, "tick %d: %d" % [tick, picked.size()])
		var ids := {}
		for e: Dictionary in picked:
			assert_false(ids.has(e.zid), "no zombie twice in one packet")
			ids[e.zid] = true
			seen[e.zid] = true
		for i in 30: # the nearest thirty
			if not ids.has(1000 + i):
				near_each_tick = false
	assert_true(near_each_tick, "the close ones are in every packet")
	assert_eq(seen.size(), 150, "and every far one comes round within a few ticks")


func test_the_far_ones_come_round_often_enough() -> void:
	var budget := 60
	var list := _crowd(150)
	var last_seen := {}
	var worst := 0
	for tick in 40:
		for e: Dictionary in Interest.pick(list, Vector3.ZERO, tick, budget):
			if last_seen.has(e.zid):
				worst = maxi(worst, tick - last_seen[e.zid])
			last_seen[e.zid] = tick
	assert_lt(worst, Config.INTEREST_FAR_TICKS + 1, "a far zombie is never more than a few ticks old (%d)" % worst)


func test_what_is_near_depends_on_who_is_looking() -> void:
	var list := _crowd(150)
	var from_start := Interest.pick(list, Vector3.ZERO, 0, 60).map(func(e: Dictionary) -> int: return e.zid)
	var from_end := Interest.pick(list, Vector3(149, 0, 0), 0, 60).map(func(e: Dictionary) -> int: return e.zid)
	assert_true(from_start.has(1000), "the first one is near the first viewer")
	assert_true(from_end.has(1149), "the last one is near the last viewer")
	assert_false(from_end.has(1000))


func test_the_host_sends_each_client_its_own_zombies_when_there_are_too_many() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	g.players[1].pos = Vector3.ZERO
	var budget := Interest.budget(g.players.size())
	g.players[7].pos = Vector3(budget + 19, 0.1, 0)
	var list := _crowd(budget + 20)
	var for_host := ZombieWire.unpack(g.zombie_bytes_for(1, list, 0))
	var for_guest := ZombieWire.unpack(g.zombie_bytes_for(7, list, 0))
	assert_eq(for_host.size(), budget)
	assert_eq(for_guest.size(), budget)
	assert_true(for_host.map(func(e: Dictionary) -> int: return e.zid).has(1000))
	assert_false(for_guest.map(func(e: Dictionary) -> int: return e.zid).has(1000), "the guest is at the far end")
	var few := _crowd(5)
	assert_eq(ZombieWire.unpack(g.zombie_bytes_for(7, few, 0)).size(), 5, "a small crowd goes whole")


func test_a_client_keeps_a_zombie_that_missed_a_packet_and_drops_it_when_it_stays_gone() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	g.is_host = false # as a client sees it: the zombies are puppets of what the snapshots say
	var a := { "zid": 31, "pos": Vector3(0, 0.1, 5), "yaw": 0.0, "state": 0, "type": 0, "mask": 0 }
	var b := { "zid": 32, "pos": Vector3(2, 0.1, 5), "yaw": 0.0, "state": 0, "type": 0, "mask": 0 }
	g._apply_snapshot([], [a, b])
	assert_true(g.zombies.has(31) and g.zombies.has(32))
	g._apply_snapshot([], [a]) # 32 was one of the far ones this time
	assert_true(g.zombies.has(32), "still there: it comes round again in a few ticks")
	g._zombie_seen[32] = Time.get_ticks_msec() - int((Config.ZOMBIE_STALE + 0.2) * 1000.0) # (as if that long had gone by)
	g._apply_snapshot([], [a])
	assert_false(g.zombies.has(32), "gone for too long: it is gone")
	assert_true(g.zombies.has(31))
	g.is_host = true


# --- Versions ---------------------------------------------------------------------------------

func test_a_mismatched_build_is_told_why() -> void:
	assert_eq(Game.version_problem(Config.PROTOCOL_VERSION), "")
	var msg := Game.version_problem(Config.PROTOCOL_VERSION + 1)
	assert_true(msg != "")
	assert_true(msg.contains(str(Config.PROTOCOL_VERSION)) and msg.contains(str(Config.PROTOCOL_VERSION + 1)), msg)
	assert_true(Game.version_problem(0) != "", "a build that sends no version at all is an old one")


func test_the_host_announces_its_version_and_a_client_of_another_build_leaves() -> void:
	var g := await new_game()
	assert_eq(g.welcome_rules().version, Config.PROTOCOL_VERSION)
	var client := Game.new()
	add_child(client)
	_games.append(client)
	var said := []
	client.join_refused.connect(func(message: String): said.append(message))
	var rules := g.welcome_rules()
	rules.version = Config.PROTOCOL_VERSION + 7
	client.welcome("corridor", "", {}, rules)
	assert_eq(said.size(), 1)
	assert_true(said[0].contains(str(Config.PROTOCOL_VERSION + 7)), said[0])
	assert_true(client.map == null, "nothing was built for a host it cannot play with")
	client.welcome("corridor", "", {}, g.welcome_rules())
	assert_eq(said.size(), 1, "the same build is welcome")
	assert_true(client.map != null)
