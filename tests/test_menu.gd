extends TestCase
## The main menu: the whole city map, a pin per mission POI, a Start button for the picked one.


var _was := Vector2i.ZERO


func _menu() -> Menu:
	_was = get_tree().root.size
	get_tree().root.size = Vector2i(1600, 900) # headless windows are tiny
	var m := Menu.new()
	add_child(m)
	await frames(3)
	return m


func after_each() -> void:
	if _was != Vector2i.ZERO:
		get_tree().root.size = _was


func test_the_city_map_fills_the_menu() -> void:
	var m := await _menu()
	assert_true(m.map_texture.texture != null, "the city is drawn")
	assert_true(m.find_children("*", "Label", true, false).any(func(l: Label) -> bool: return l.text == "MAKE ALIVE"), "titled Make Alive")
	var shown := m.map_rect()
	var screen := m.get_viewport().get_visible_rect().size
	assert_gt(shown.size.x * shown.size.y, screen.x * screen.y * 0.45, "and takes up most of the screen")
	m.free()


func test_the_whole_city_is_drawn_not_just_the_play_area() -> void:
	var m := await _menu()
	var tex := m.map_texture.texture.get_size()
	assert_eq(tex, Vector2(CityPicture.W, CityPicture.H), "every pixel of the city picture")
	var shown := m.map_rect()
	for p: Vector2 in CityMap.edge_polygon():
		var px := p / CityData.M_PER_PX + CityData.ORIGIN_PX
		assert_true(shown.grow(1.0).has_point(m.px_point(px)), "the play area's edge at %s is on screen" % px)
	m.free()


func test_every_traced_street_is_drawn_over_the_city() -> void:
	var m := await _menu()
	var lines := m.street_lines()
	assert_eq(lines.size(), CityData.STREETS.size(), "one red line per street the game builds, the hill road too")
	var shown := m.map_rect().grow(2.0)
	for line: PackedVector2Array in lines:
		for p in line:
			assert_true(shown.has_point(p), "street point %s is on the map" % p)
	m.free()


func test_every_mission_has_a_pin_where_its_poi_is() -> void:
	var m := await _menu()
	assert_eq(m.pins.size(), Missions.ORDER.size())
	assert_eq(Missions.ORDER.size(), CityData.POIS.size(), "one mission per POI")
	var shown := m.map_rect()
	for id: String in Missions.ORDER:
		assert_true(shown.has_point(m.pin_point(id)), "%s pin is on the map" % id)
	# Same layout as the city: the Mirante is far north-east, the barracks far south-west.
	assert_gt(m.pin_point("mirante").x, m.pin_point("prefeitura").x)
	assert_lt(m.pin_point("mirante").y, m.pin_point("terminal").y)
	assert_lt(m.pin_point("batalhao").x, m.pin_point("terminal").x)
	assert_gt(m.pin_point("batalhao").y, m.pin_point("hospital").y)
	assert_lt(m.pin_point("hospital").x, m.pin_point("terminal").x)
	m.free()


func test_start_needs_a_picked_mission_then_starts_it() -> void:
	var m := await _menu()
	var started := []
	m.mission_pressed.connect(func(id: String): started.append(id))
	assert_true(m.start_button.disabled, "nothing picked yet")
	m.pins["mirante"].pressed.emit()
	assert_eq(m.selected, "mirante")
	assert_false(m.start_button.disabled)
	assert_true(m.mission_title.text.contains("MIRANTE"), "the panel shows the picked mission")
	assert_true(m.pins["mirante"].button_pressed, "its pin stays lit")
	m.pins["hospital"].pressed.emit()
	assert_false(m.pins["mirante"].button_pressed, "only one pin lit at a time")
	m.start_button.pressed.emit()
	assert_eq(started, ["hospital"])
	m.free()


func test_free_play_and_join_are_still_there() -> void:
	var m := await _menu()
	var hosted := []
	m.host_pressed.connect(func(): hosted.append(true))
	m.free_play_button.pressed.emit()
	assert_eq(hosted.size(), 1, "training ground hosts without a mission")
	assert_true(m.ip_edit != null and m.lan_list != null, "join by IP and LAN list")
	m.free()


func test_a_mission_hosts_the_city_at_its_poi() -> void:
	var g := await new_game("city", "batalhao")
	assert_eq(g.mission, "batalhao")
	assert_lt(g.local_player.global_position.distance_to(g.map.poi_pos("batalhao")), 4.0)
