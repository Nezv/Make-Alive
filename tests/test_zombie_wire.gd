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
