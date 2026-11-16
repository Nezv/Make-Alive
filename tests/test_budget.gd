extends TestCase
## The performance budget. Every map must stay inside Config.BUDGET, the host must finish a tick
## with a full horde inside one frame, and a full match must still fit one packet.
## Measured without a screen: see scripts/budget.gd for what is counted and how.

static var _city: CityMap


static func after_all() -> void:
	if _city != null:
		_city.root.free()
		_city = null


func test_counting_a_small_scene() -> void:
	var root := Node3D.new()
	add_child(root)
	var b := MeshKit.Builder.new()
	b.box(Vector3.ONE, Vector3(0, 0.5, -5), Color.WHITE)
	root.add_child(b.instance())
	var hidden := MeshKit.Builder.new().box(Vector3.ONE, Vector3.ZERO, Color.WHITE).instance()
	hidden.visible = false
	root.add_child(hidden)
	var lamp := OmniLight3D.new()
	lamp.shadow_enabled = true
	root.add_child(lamp)
	root.add_child(OmniLight3D.new())
	var got := Budget.measure(root)
	assert_eq(got.meshes, 1, "hidden meshes cost nothing")
	assert_eq(got.surfaces, 1)
	assert_eq(got.lights, 2)
	assert_eq(got.shadow_lights, 1)
	var eye := Transform3D(Basis.IDENTITY, Vector3(0, 1.6, 0))
	assert_eq(Budget.surfaces_in_view(root, eye), 1, "the box is ahead (-Z)")
	assert_eq(Budget.surfaces_in_view(root, Transform3D(Basis(Vector3.UP, PI), eye.origin)), 0, "and not behind")
	root.free()


func test_over_reports_only_what_is_over() -> void:
	var limits: Dictionary = Config.BUDGET.corridor
	var fine := {}
	var bad := {}
	for key: String in limits:
		fine[key] = limits[key]
		bad[key] = limits[key] + 1
	assert_eq(Budget.over("corridor", fine), [], "at the limit is inside it")
	assert_eq(Budget.over("corridor", bad).size(), limits.size())
	assert_eq(Budget.over("a map with no budget", bad), [])


func test_every_map_has_a_budget() -> void:
	for map_name: String in GameMap.NAMES:
		assert_true(Config.BUDGET.has(map_name), map_name)
		assert_lt(Config.BUDGET[map_name].shadow_lights, 3, map_name + ": only two lamps cast shadows")


func test_corridor_is_inside_its_budget() -> void:
	var g := await new_game()
	var got := Budget.report(g.map)
	print("[budget] corridor ", got)
	assert_eq(Budget.over("corridor", got), [])
	assert_gt(got.worst_view, 0, "the cameras see the map")


func test_city_is_inside_its_budget() -> void:
	if _city == null:
		_city = CityMap.new()
	add_child(_city.root)
	var got := Budget.report(_city)
	print("[budget] city ", got)
	assert_eq(Budget.over("city", got), [])
	remove_child(_city.root)


func test_host_tick_with_a_full_horde_fits_in_a_frame() -> void:
	var g := await new_game()
	g.door.toggle()
	for i in Config.ZOMBIE_MAX:
		g.spawn_zombie(i % 3, Vector3(8.0 + (i % 12) * 2.5, 0.1, -2.0 + (i / 12) * 1.0))
	assert_eq(g.zombies.size(), Config.ZOMBIE_MAX)
	await frames(10) # let them start chasing
	var times := []
	for i in 40:
		var t := Time.get_ticks_usec()
		g._physics_process(1.0 / 60.0)
		times.append((Time.get_ticks_usec() - t) / 1000.0)
		await get_tree().physics_frame
	times.sort()
	var median: float = times[times.size() / 2]
	print("[budget] host tick with %d zombies: median %.2f ms, worst %.2f ms" % [Config.ZOMBIE_MAX, median, times[times.size() - 1]])
	assert_lt(median, Config.BUDGET_HOST_TICK_MS, "the host's whole tick")


func test_a_full_match_fits_one_packet() -> void:
	var g := await new_game()
	for i in range(1, Config.MAX_PLAYERS):
		g._add_player(1000000000 + i, "W".repeat(20)) # the longest name allowed, the largest ids
	for i in Config.ZOMBIE_MAX:
		g.spawn_zombie(i % 3, Vector3(8.0 + (i % 12) * 2.5, 0.1, -2.0 + (i / 12) * 1.0))
	assert_eq(g.players.size(), Config.MAX_PLAYERS)
	assert_eq(g.zombies.size(), Config.ZOMBIE_MAX)
	var snap: Array = g.build_snapshot() # exactly what the host sends 20 times a second
	var size := var_to_bytes([PlayerWire.pack(snap[0]), ZombieWire.pack(snap[1])]).size()
	print("[budget] full snapshot: %d bytes" % size)
	assert_lt(size, Config.BUDGET_PACKET_BYTES, "8 players and a full horde in one unfragmented packet")
