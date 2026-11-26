extends TestCase
## S050: the sky and the time of day. Presets as data (TimeOfDay), the sky dome that draws them
## (SkyDome: one shader, one light, the fog) and the far backdrop it paints past the far plane.


func test_every_preset_says_everything_the_dome_needs() -> void:
	assert_eq(TimeOfDay.NAMES, ["clear", "overcast", "dusk", "night", "storm"])
	for name: String in TimeOfDay.NAMES:
		var p := TimeOfDay.preset(name)
		for key: String in TimeOfDay.KEYS:
			assert_true(p.has(key), "%s has %s" % [name, key])


func test_unknown_names_fall_back_to_the_night() -> void:
	assert_eq(TimeOfDay.resolve("nonsense"), "night")
	assert_eq(TimeOfDay.resolve("day"), "clear")
	assert_eq(TimeOfDay.resolve("dusk"), "dusk")


func test_shadows_only_by_day_and_dusk() -> void:
	for name: String in TimeOfDay.NAMES:
		var want := name in ["clear", "overcast", "dusk"]
		assert_eq(bool(TimeOfDay.preset(name).shadows), want, name)


func test_the_sun_is_high_by_day_and_low_at_dusk() -> void:
	assert_true(float(TimeOfDay.preset("clear").sun_elevation) > 30.0)
	var dusk := float(TimeOfDay.preset("dusk").sun_elevation)
	assert_true(dusk > 0.0 and dusk < 12.0, "a low dusk sun: %s" % dusk)
	assert_true(float(TimeOfDay.preset("night").sun_elevation) > 15.0, "the moon stands high at night")


func test_the_fog_hides_the_far_plane_in_every_preset() -> void:
	for name: String in TimeOfDay.NAMES:
		var hidden := TimeOfDay.fog_at(TimeOfDay.preset(name), Config.VIEW_FAR)
		assert_true(hidden >= Config.SKY_FOG_HIDES, "%s fog hides %.2f of the far plane" % [name, hidden])


func test_the_fog_starts_thin() -> void:
	for name: String in TimeOfDay.NAMES:
		var p := TimeOfDay.preset(name)
		assert_true(TimeOfDay.fog_at(p, 30.0) < 0.15, "%s: a street's length stays clear" % name)
		assert_true(TimeOfDay.fog_at(p, 600.0) < TimeOfDay.fog_at(p, Config.VIEW_FAR), name)


func test_each_mission_has_a_preset_and_free_play_is_night() -> void:
	for id: String in Missions.ORDER:
		assert_true(TimeOfDay.NAMES.has(Missions.INFO[id].sky), id)
	assert_eq(MapData.new({}).sky, "night")
	assert_eq(MapData.new({ "sky": "dusk" }).sky, "dusk")


func test_the_city_under_its_dome() -> void:
	var g := await new_game("city")
	# lit by the dome: our own sky shader, fog, no sun shadows at night
	assert_eq(g.sky, "night")
	assert_true(g.sky_dome != null)
	var env := g.sky_dome.environment
	assert_eq(env.background_mode, Environment.BG_SKY)
	assert_true(env.sky.sky_material is ShaderMaterial, "the sky is our own shader")
	assert_true(env.fog_enabled)
	assert_false(g.sky_dome.light.shadow_enabled, "no sun shadows at night")

	# another preset changes the light, the fog and the shader
	var night_fog := env.fog_light_color
	g.sky_dome.apply("clear")
	assert_true(g.sky_dome.light.shadow_enabled)
	assert_true(g.sky_dome.light.light_energy > 1.0)
	assert_true(env.fog_light_color != night_fog, "the fog changes colour")
	var mat := env.sky.sky_material as ShaderMaterial
	assert_eq(mat.get_shader_parameter("zenith"), TimeOfDay.preset("clear").zenith)
	g.sky_dome.apply("dusk")
	assert_true(g.sky_dome.light.shadow_enabled, "the dusk sun casts shadows")
	assert_true(g.sky_dome.light.rotation.x > deg_to_rad(-15.0), "and stands low")

	# the backdrop: the hill seen from the place du Marché, toward the Mirante and not behind you
	var map := g.map as CityMap
	var at := CityData.to_world(CityData.square("marche").pts[0]) + Vector3(0, 1.7, 0)
	var summit := map.poi_pos("mirante")
	var toward := summit - at
	var n := Config.SKY_PROFILE_SIZE
	var i := SkyDome.profile_index(atan2(toward.x, -toward.z), n)
	var want := atan2(summit.y - at.y, Vector2(toward.x, toward.z).length())
	var there := SkyDome.profile_at(map, at, SkyDome.azimuth_of(i, n))
	assert_true(there.x > want * 0.8, "the hill stands %.1f deg up toward the Mirante (%.1f)" % [rad_to_deg(there.x), rad_to_deg(want)])
	var behind := SkyDome.profile_at(map, at, SkyDome.azimuth_of(posmod(i + n / 2, n), n))
	assert_true(behind.x < want * 0.3, "and not behind you")
	assert_true(there.w > 0.0 or behind.w > 0.0, "roofs past the far plane")

	# the landmark stand-ins and the fires are fixed by the map
	var names := SkyDome.towers_of(map).map(func(t: Dictionary) -> String: return t.id)
	for id in ["eglise", "campanile", "telegraphe", "moulin"]:
		assert_true(names.has(id), id)
	var a := SkyDome.smoke_of(map)
	assert_eq(a.size(), Config.SKY_SMOKE_COLUMNS)
	assert_eq(a, SkyDome.smoke_of(map), "the same fires on every peer")

	# a storm flashes now and then; a clear sky never does
	g.sky_dome.apply("storm")
	var flashes := 0
	var was := false
	for k in 1200: # one minute at 20 Hz
		g.sky_dome.step(0.05)
		var on := g.sky_dome.flash > 0.5
		if on and not was:
			flashes += 1
		was = on
	assert_true(flashes >= 2 and flashes <= 20, "%d flashes a minute" % flashes)
	g.sky_dome.apply("clear")
	g.sky_dome.step(0.05)
	assert_eq(g.sky_dome.flash, 0.0)


func test_a_mission_brings_its_own_sky() -> void:
	var g := await new_game("city", "terminal")
	assert_eq(g.sky, Missions.INFO.terminal.sky)


func test_the_host_can_choose_the_time_and_peers_learn_it_in_welcome() -> void:
	var g := Game.new()
	g.sky_choice = "day"
	add_child(g)
	g.start_host("Tester")
	g.director.enabled = false
	_games.append(g)
	await frames(2)
	assert_eq(g.sky, "clear")
	assert_eq(g.welcome_rules().sky, "clear")


func test_the_corridor_stays_a_dark_interior() -> void:
	var g := await new_game("corridor")
	assert_eq(g.sky_dome.environment.background_mode, Environment.BG_COLOR)
	assert_false(g.sky_dome.light.shadow_enabled)
