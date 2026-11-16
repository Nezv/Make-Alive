extends TestCase
## The settings store: defaults, saving and loading, live changes, and surviving a broken file.

const PATH := "user://test_settings.cfg"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	Controls.reset()


func _store() -> SettingsStore:
	var s := SettingsStore.new()
	s.path = PATH
	s.apply_to_engine = false # tests must not resize the window or touch the real audio buses
	add_child(s)
	return s


func test_defaults_match_config() -> void:
	var s := _store()
	assert_near(s.get_value("fov"), Config.FOV)
	assert_near(s.get_value("mouse_sensitivity"), Config.MOUSE_SENS, 0.00001)
	assert_eq(s.get_value("invert_y"), false)
	assert_eq(s.get_value("graphics_tier"), "medium")
	for bus: String in SettingsStore.BUSES:
		assert_near(s.get_value("volume_" + bus.to_lower()), 1.0, 0.001, bus)
	s.free()


func test_set_emits_changed_and_survives_a_reload() -> void:
	var s := _store()
	var seen := []
	s.changed.connect(func(key: String): seen.append(key))
	s.set_value("fov", 90.0)
	s.set_value("player_name", "Ana")
	assert_eq(seen, ["fov", "player_name"])
	s.free()
	var again := _store()
	assert_near(again.get_value("fov"), 90.0)
	assert_eq(again.get_value("player_name"), "Ana")
	again.free()


func test_setting_the_same_value_is_silent() -> void:
	var s := _store()
	var seen := []
	s.changed.connect(func(key: String): seen.append(key))
	s.set_value("fov", Config.FOV)
	assert_eq(seen.size(), 0)
	s.free()


func test_values_are_clamped_and_unknown_keys_refused() -> void:
	var s := _store()
	s.set_value("fov", 500.0)
	assert_near(s.get_value("fov"), SettingsStore.DEFS.fov.max)
	s.set_value("volume_master", -3.0)
	assert_near(s.get_value("volume_master"), 0.0)
	s.set_value("graphics_tier", "ultra-mega")
	assert_eq(s.get_value("graphics_tier"), "medium", "not one of the choices")
	s.set_value("no_such_setting", 1)
	assert_eq(s.get_value("no_such_setting"), null)
	s.free()


func test_broken_file_falls_back_to_defaults() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("[[[ this is not a config file\nfov = banana\n]]] = = =")
	f.close()
	var s := _store()
	assert_near(s.get_value("fov"), Config.FOV)
	s.free()


func test_wrong_types_in_the_file_are_ignored() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("[settings]\nfov=\"wide\"\ninvert_y=true\nmade_up=3\n")
	f.close()
	var s := _store()
	assert_near(s.get_value("fov"), Config.FOV, 0.01, "a string is not a field of view")
	assert_eq(s.get_value("invert_y"), true, "the good line still loads")
	s.free()


func test_key_bindings_rebind_and_persist() -> void:
	Controls.setup()
	var s := _store()
	s.set_key("reload", KEY_T)
	assert_eq(Controls.key_of("reload"), KEY_T)
	var e := InputEventKey.new()
	e.physical_keycode = KEY_T
	e.pressed = true
	assert_true(InputMap.event_is_action(e, "reload"), "T reloads now")
	e.physical_keycode = KEY_R
	assert_false(InputMap.event_is_action(e, "reload"), "R no longer does")
	s.free()
	Controls.reset()
	assert_eq(Controls.key_of("reload"), KEY_R)
	var again := _store()
	assert_eq(Controls.key_of("reload"), KEY_T, "loaded from the file")
	again.free()


func test_volume_reaches_the_audio_bus() -> void:
	var s := _store()
	s.apply_to_engine = true
	s.set_value("volume_guns", 0.5)
	var bus := AudioServer.get_bus_index("Guns")
	assert_gt(bus, -1, "the Guns bus exists")
	assert_near(AudioServer.get_bus_volume_db(bus), linear_to_db(0.5), 0.01)
	s.set_value("volume_guns", 1.0)
	s.apply_to_engine = false
	s.free()
