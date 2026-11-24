class_name SkyDome
extends Node
## The sky, the sun or moon, the fog and the far backdrop of a match (S050). `Game` makes one with
## the map and the preset named by `Game.sky` (TimeOfDay); `apply(name)` switches presets. Indoor
## maps (the corridor) keep a dark interior: black background, thick fog, a dim moon.
##
## The backdrop is drawn by the sky shader (SkyShader) past the far plane: the hill and the town's
## roofscape come from `horizon_profile`, worked out from the map's heights and cells for where the
## camera stands (again in slices when it has moved), the landmark towers from `towers_of` and the
## fires' smoke columns from `smoke_of`, both fixed by the map so every peer sees the same.
## Card: references/elements/sky.md.

var environment: Environment
var light: DirectionalLight3D
var material: ShaderMaterial
var preset_name := ""
var preset := {}
var flash := 0.0               ## lightning, 0..1, decays
var outdoor := true

var _map: GameMap
var _world_env: WorldEnvironment
var _profile_img: Image
var _profile_tex: ImageTexture
var _profile_at := Vector3(INF, INF, INF) ## where the profile was worked out from
var _profile_next := -1                   ## next slice to work out (-1: done)
var _profile_from := Vector3.ZERO
var _cloud := Vector2.ZERO
var _time := 0.0
var _rng := RandomNumberGenerator.new()
var _flash_in := 0.0
var _flicker := 0.0
var _since_update := INF
var _flash_shown := 0.0


func setup(map: GameMap, name: String) -> void:
	_map = map
	outdoor = map == null or map.outdoor
	_rng.seed = Config.SKY_SEED
	environment = Environment.new()
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.fog_enabled = true
	material = ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = SkyShader.CODE
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	environment.sky = sky
	_world_env = WorldEnvironment.new()
	_world_env.environment = environment
	add_child(_world_env)
	light = DirectionalLight3D.new()
	light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	light.directional_shadow_max_distance = Config.SKY_SHADOW_DISTANCE
	add_child(light)
	_setup_backdrop()
	apply(name)


func apply(name: String) -> void:
	preset_name = TimeOfDay.resolve(name)
	preset = TimeOfDay.preset(preset_name)
	var p := preset
	flash = 0.0
	_flash_in = _next_flash()
	if not outdoor:
		# A dark interior: what the corridor always looked like.
		environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
		environment.tonemap_exposure = 1.0
		environment.background_mode = Environment.BG_COLOR
		environment.background_color = Color("0b0d10")
		environment.ambient_light_color = Color("7f8fa6")
		environment.ambient_light_energy = 0.35
		environment.fog_light_color = Color("0b0d10")
		environment.fog_density = 0.035
		environment.fog_sky_affect = 1.0
		light.light_color = Color("aabbdd")
		light.light_energy = 0.5
		light.shadow_enabled = false # lamps cast the shadows; a sun shadow would redraw the horde again
		light.rotation = Vector3(deg_to_rad(-60), deg_to_rad(35), 0)
		_set_params(p)
		return
	environment.background_mode = Environment.BG_SKY
	environment.ambient_light_color = p.ambient
	environment.ambient_light_energy = p.ambient_energy
	environment.fog_mode = Environment.FOG_MODE_DEPTH # up to fog_max at the far plane, where the shader's backdrop takes over
	environment.fog_light_color = p.fog_color
	environment.fog_density = p.fog_max
	environment.fog_depth_begin = p.fog_begin
	environment.fog_depth_end = Config.VIEW_FAR
	environment.fog_depth_curve = p.fog_curve
	environment.fog_sky_affect = 0.0 # the shader hazes its own backdrop
	environment.tonemap_exposure = p.exposure
	light.light_color = p.sun_color
	light.light_energy = p.sun_energy
	light.shadow_enabled = p.shadows
	light.shadow_opacity = p.shadow_opacity
	light.rotation = TimeOfDay.light_rotation(p)
	_set_params(p)


func _set_params(p: Dictionary) -> void:
	var m := material
	for key in ["zenith", "horizon", "ground", "sun_color", "cloud_lit", "cloud_shade", "glow_color",
			"fog_color", "fog_begin", "fog_curve", "fog_max", "air", "sun_size", "stars", "cloud_low", "cloud_high", "glow",
			"hill_color", "roof_color", "lights", "cloud_relief"]:
		m.set_shader_parameter(key, p[key])
	m.set_shader_parameter("sun_dir", TimeOfDay.sun_dir(p))
	m.set_shader_parameter("is_moon", 1.0 if p.moon else 0.0)
	m.set_shader_parameter("far_plane", Config.VIEW_FAR)
	m.set_shader_parameter("wind", Vector2(1.0, 0.35).normalized() * float(p.wind))
	m.set_shader_parameter("flash", 0.0)
	m.set_shader_parameter("gain", 1.0 / float(p.exposure) if outdoor else 1.0)
	# the engine's fog goes through the exposure and the sky does not: meet it at the horizon
	m.set_shader_parameter("fog_color", Color(p.fog_color) * (float(p.exposure) if outdoor else 1.0))


## Every frame (Game._process): the clouds drift, lightning flashes, the backdrop follows the camera.
func step(dt: float, cam: Vector3 = Vector3.INF) -> void:
	if preset.is_empty():
		return
	_time += dt
	_cloud += Vector2(1.0, 0.35) * float(preset.wind) * Config.SKY_CLOUD_SPEED * dt
	_step_flash(dt)
	if not outdoor:
		return
	light.light_energy = float(preset.sun_energy) + flash * Config.SKY_FLASH_LIGHT
	# Each change of a parameter redraws the sky's reflections too, so they change a few times a second
	# (a flash at once); the clouds move too slowly for it to show.
	_since_update += dt
	if _since_update >= Config.SKY_UPDATE or flash > 0.0 or _flash_shown > 0.0:
		_since_update = 0.0
		_flash_shown = flash
		material.set_shader_parameter("cloud_offset", _cloud)
		material.set_shader_parameter("sky_time", _time)
		material.set_shader_parameter("flash", flash)
		if cam != Vector3.INF:
			material.set_shader_parameter("cam_pos", cam)
	if cam != Vector3.INF:
		_step_profile(cam)


## A lightning strike now, at a compass bearing in radians (NAN: anywhere). The review's shots use it (`--lightning`).
func strike(az := NAN) -> void:
	_flicker = Config.SKY_FLASH_TIME
	material.set_shader_parameter("flash_az", _rng.randf_range(-PI, PI) if is_nan(az) else az)
	_since_update = INF


func _next_flash() -> float:
	var per_min := float(preset.get("lightning", 0.0))
	if per_min <= 0.0:
		return INF
	var mean := 60.0 / per_min
	return _rng.randf_range(mean * 0.3, mean * 1.7)


func _step_flash(dt: float) -> void:
	if float(preset.get("lightning", 0.0)) <= 0.0 and _flicker <= 0.0:
		flash = 0.0
		return
	_flash_in -= dt
	if _flash_in <= 0.0:
		_flash_in = _next_flash()
		strike()
	if _flicker > 0.0:
		var t := 1.0 - _flicker / Config.SKY_FLASH_TIME
		# a strike flickers: bright at once, two or three pulses, then out
		flash = clampf(sqrt(1.0 - t) * (0.7 + 0.3 * cos(t * 30.0)), 0.0, 1.0)
		_flicker -= dt
	else:
		flash = maxf(0.0, flash - dt * 8.0)


# --- The backdrop ----------------------------------------------------------------------------

func _setup_backdrop() -> void:
	var n := Config.SKY_PROFILE_SIZE
	_profile_img = Image.create_empty(n, 1, false, Image.FORMAT_RGBAF)
	_profile_tex = ImageTexture.create_from_image(_profile_img)
	material.set_shader_parameter("profile", _profile_tex)
	material.set_shader_parameter("tower_count", 0)
	material.set_shader_parameter("smoke_count", 0)
	if not (_map is CityMap):
		return
	var city := _map as CityMap
	var tex := ImageTexture.create_from_image(CityPicture.image())
	material.set_shader_parameter("town", tex)
	material.set_shader_parameter("has_town", 1.0)
	var lt := CityData.to_plan(Vector2(CityPicture.LEFT, CityPicture.TOP))
	var size := Vector2(CityPicture.W, CityPicture.H) * CityData.M_PER_PX
	material.set_shader_parameter("town_rect", Vector4(lt.x, lt.y, size.x, size.y))
	var at := PackedVector4Array()
	var shape := PackedVector4Array()
	for t: Dictionary in towers_of(city):
		var p: Vector3 = t.at
		at.append(Vector4(p.x, p.y, p.z, t.height))
		shape.append(Vector4(t.width, t.kind, 0.0, 0.0))
	material.set_shader_parameter("tower_at", at)
	material.set_shader_parameter("tower_shape", shape)
	material.set_shader_parameter("tower_count", at.size())
	var smoke := smoke_of(city)
	material.set_shader_parameter("smoke_at", PackedVector4Array(smoke))
	material.set_shader_parameter("smoke_count", smoke.size())


## Work the profile out again, a slice a frame, once the camera has moved far enough.
func _step_profile(cam: Vector3) -> void:
	if _map == null or not (_map is CityMap):
		return
	var n := Config.SKY_PROFILE_SIZE
	if _profile_next < 0:
		if cam.distance_to(_profile_at) < Config.SKY_PROFILE_MOVE:
			return
		_profile_next = 0
		_profile_from = cam
		if _profile_at.x == INF: # the first time all at once, so the first frame has its hill
			_fill_profile(0, n)
			_profile_next = -1
			_profile_at = cam
			_profile_tex.update(_profile_img)
			return
	var end := mini(_profile_next + Config.SKY_PROFILE_SLICE, n)
	_fill_profile(_profile_next, end)
	_profile_next = end
	if _profile_next >= n:
		_profile_next = -1
		_profile_at = _profile_from
		_profile_tex.update(_profile_img)


func _fill_profile(from: int, to: int) -> void:
	var n := Config.SKY_PROFILE_SIZE
	for i in range(from, to):
		var v := profile_at(_map as CityMap, _profile_from, azimuth_of(i, n))
		_profile_img.set_pixel(i, 0, Color(v.x, v.y, v.z, v.w))


## The compass azimuth (radians) of profile texel i of n (the shader reads u = az / TAU + 0.5).
static func azimuth_of(i: int, n: int) -> float:
	return ((float(i) + 0.5) / n - 0.5) * TAU


static func profile_index(az: float, n: int) -> int:
	return posmod(floori((az / TAU + 0.5) * n), n)


## For each of n azimuths from `at`: Vector4(hill angle, its distance, roofscape angle, its distance),
## angles in radians above the horizon, of what stands past the far plane (0, 0 where nothing does).
static func horizon_profile(map: CityMap, at: Vector3, n: int) -> Array:
	var out := []
	for i in n:
		out.append(profile_at(map, at, azimuth_of(i, n)))
	return out


static func profile_at(map: CityMap, at: Vector3, az: float) -> Vector4:
	var dir := Vector3(sin(az), 0.0, -cos(az))
	var hill := -INF
	var hill_d := 0.0
	var roofs := -INF
	var roofs_d := 0.0
	var d := Config.VIEW_FAR * 0.9
	while d < Config.SKY_PROFILE_REACH:
		var p := at + dir * d
		var kind := map.type_at(p)
		var y := map.ground_y(p)
		if kind == CityMap.FOREST:
			y += Config.SKY_CANOPY
		if y > 1.0:
			var a := atan2(y - at.y, d)
			if a > hill:
				hill = a
				hill_d = d
		elif kind == CityMap.BLOCK or kind == CityMap.BUILT or kind == CityMap.LOT:
			var a := atan2(Config.SKY_ROOF_HEIGHT - at.y, d)
			if a > roofs:
				roofs = a
				roofs_d = d
		d += Config.SKY_PROFILE_STEP * (1.0 + d / 2000.0)
	if hill_d == 0.0:
		hill = 0.0
	if roofs_d == 0.0:
		roofs = 0.0
	return Vector4(hill, hill_d, roofs, roofs_d)


## The landmarks that tower over the roofs, as stand-ins drawn in the sky until their own elements
## stand in the town (S188 the church, S214 the campanile, S230 the telegraph tower and the mill):
## { id, at (foot), height, width, kind } with kind 0 spire, 1 campanile, 2 telegraph tower, 3 mill.
static func towers_of(map: CityMap) -> Array:
	var eglise := _centroid(CityData.square("eglise").pts)
	var church := CityData.to_world(eglise + Vector2(0, -18)) # the church closes the place on its north side
	var hall := map.poi_pos("prefeitura")
	var summit := map.poi_pos("mirante")
	var mill := summit + Vector3(-34, 0, 22)
	mill.y = map.ground_y(mill)
	return [
		{ "id": "eglise", "at": church, "height": 58.0, "width": 9.0, "kind": 0 },
		{ "id": "campanile", "at": hall, "height": 42.0, "width": 7.0, "kind": 1 },
		{ "id": "telegraphe", "at": summit, "height": 24.0, "width": 7.0, "kind": 2 },
		{ "id": "moulin", "at": mill, "height": 17.0, "width": 7.5, "kind": 3 },
	]


## Fires burning in the town: Vector4(x, z, strength, seed), seeded so every peer sees the same.
static func smoke_of(map: CityMap) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = Config.SKY_SEED + 11
	var out := []
	var tries := 0
	while out.size() < Config.SKY_SMOKE_COLUMNS and tries < 400:
		tries += 1
		var px := Vector2(rng.randf_range(CityData.FRAME.position.x, CityData.FRAME.end.x),
			rng.randf_range(0.0, CityData.FRAME.end.y))
		var p := CityData.to_world(px)
		if map.type_at(p) != CityMap.BLOCK and map.type_at(p) != CityMap.BUILT:
			continue
		var near := false
		for o: Vector4 in out:
			near = near or Vector2(o.x, o.y).distance_to(Vector2(p.x, p.z)) < 900.0
		if near:
			continue
		out.append(Vector4(p.x, p.z, rng.randf_range(0.6, 1.0), rng.randf_range(0.0, 50.0)))
	return out


static func _centroid(pts: Array) -> Vector2:
	var c := Vector2.ZERO
	for p: Vector2 in pts:
		c += p
	return c / maxf(pts.size(), 1)
