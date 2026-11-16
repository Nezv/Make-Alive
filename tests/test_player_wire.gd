extends TestCase
## Player snapshots are packed like zombie ones, and names travel once instead of 20 times a
## second, so eight players and a full horde fit one packet (tests/test_budget.gd checks the sum).


func test_round_trip_keeps_everything_that_matters() -> void:
	var bytes := PlayerWire.pack([
		{ "id": 1, "pos": Vector3(-658.37, 0.12, 222.5), "yaw": -2.5, "hp": 100, "kills": 0, "weapon": Weapons.AK47 },
		{ "id": 2147483647, "pos": Vector3(1867.2, 230.61, -1031.9), "yaw": 3.1, "hp": 7, "kills": 4321, "weapon": Weapons.DRAGUNOV },
	])
	assert_eq(bytes.size(), 2 * PlayerWire.BYTES_EACH)
	var out := PlayerWire.unpack(bytes)
	assert_eq(out.size(), 2)
	assert_eq(out[0].id, 1)
	assert_lt((out[0].pos as Vector3).distance_to(Vector3(-658.37, 0.12, 222.5)), 0.001, "anywhere in the city, to the millimetre")
	assert_near(angle_difference(out[0].yaw, -2.5), 0.0, 0.001)
	assert_eq(out[0].hp, 100)
	assert_eq(out[0].weapon, Weapons.AK47)
	assert_eq(out[1].id, 2147483647, "peer ids are large")
	assert_lt((out[1].pos as Vector3).distance_to(Vector3(1867.2, 230.61, -1031.9)), 0.001)
	assert_eq(out[1].hp, 7)
	assert_eq(out[1].kills, 4321)
	assert_eq(out[1].weapon, Weapons.DRAGUNOV)


func test_out_of_range_numbers_are_clamped_not_wrapped() -> void:
	var out := PlayerWire.unpack(PlayerWire.pack([
		{ "id": 5, "pos": Vector3.ZERO, "yaw": 0.0, "hp": -20, "kills": 99999, "weapon": 3 }]))
	assert_eq(out[0].hp, 0)
	assert_eq(out[0].kills, 65535)
	assert_eq(PlayerWire.unpack(PlayerWire.pack([])).size(), 0)
	assert_eq(PlayerWire.unpack(PackedByteArray([1, 2, 3])).size(), 0, "a torn packet is nobody, not a crash")


func test_names_travel_apart_from_snapshots() -> void:
	var g := await new_game()
	assert_eq(g.names, { 1: "Tester" })
	g._add_player(7, "Ana")
	assert_eq(g.names, { 1: "Tester", 7: "Ana" }, "sent when someone joins")
	var snap: Array = g.build_snapshot()
	assert_eq(snap[0].size(), 2)
	assert_false((snap[0][0] as Dictionary).has("name"), "not in the 20 Hz snapshot")
	g._apply_snapshot(snap[0], snap[1])
	assert_eq(g.remotes[7].tag.text, "Ana", "the other player's name tag")
	g._on_peer_left(7)
	assert_eq(g.names, { 1: "Tester" })
