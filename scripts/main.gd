extends Node
## Root of the app: owns the menu and the current Game.
##
## Command-line options (after `--`), handy for testing:
##   --host                 host immediately
##   --map=corridor         host on the test corridor instead of the city (the default)
##   --mission=mirante      a city mission (terminal, hospital, prefeitura, batalhao, mirante): with --host start it,
##                          without it just pick it on the menu map (for screenshots of the menu)
##   --balance=C:/x.md      print the balance sheet (guns against zombie types), save it there and exit
##   --city-plan=C:/dir     save city_plan.png and city_on_reference.png (what part of Joinville the city map covers) and exit
##   --join=192.168.1.7     join immediately
##   --name=Bob             player name
##   --bot                  local player wanders and shoots by itself
##   --bot-goal=exit        with --bot: walk into this zone of the map's data (see --zones)
##   --perf=30              measure frame times and draw calls for N seconds, print them and exit (tools\\perf.ps1)
##   --quit-after=10        exit after N seconds (prints a summary)
##   --screenshot=C:/x.png  save a picture of the screen (with --shot-at=6 seconds, default 5)
##   --no-hordes            host without automatic zombie spawning
##   --spawn=12             host: spawn a horde of N immediately
##   --demo                 host: no hordes, door open, a few of each zombie type right in front of you
##   --no-fire              with --bot: aim but don't shoot
##   --bot-aim=legs         with --bot: chest (default), head, legs or arms
##   --weapon=4             start holding gun 1-9 (P19, P90, Type 95, AK47, AS Val, USAS-12, SPAS-12, T-5000, Dragunov)
##   --limited-ammo         host: reloads take from a reserve (the map's starting_ammo) even on a test map
##   --pose=aim             hold a gun pose for screenshots: aim, sprint or reload
##   --poi-cam              with --mission: look at the mission's place from above the street in front of it
##   --cam=x,y,z,yaw,pitch  (or --shot-cam=) look at the map from a fixed camera (degrees), e.g. --cam=0,45,50,0,-50 for an overview
##   --noise                host: draw an expanding ring wherever something made noise, out to where it is heard
##   --zones                draw the map data: zones, zombie closets (red), horde routes (orange), spawns (white)
##   --fx-rack              every effect of the effects kit looping in a row in front of you, labelled
##   --gun-rack             hang all nine gun models in front of you, side on
##   --zombie-rack=1        stand one zombie of every outfit in front of you: =1 first half, =2 second half (add --back for their backs)

var menu: Menu
var game: Game
var _args := {}
var _shots := 0
var _perf_left := 0.0   # --perf: seconds still to measure
var _perf_warmup := 0.0 # the first seconds are loading hitches, not the game
var _perf_ms: Array[float] = []
var _perf_draws: Array[int] = []


func _ready() -> void:
	Controls.setup()
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	if Settings.get_value("player_name") != "":
		Net.player_name = Settings.get_value("player_name")
	if _args.has("name"):
		Net.player_name = _args.name
	if _args.has("balance"):
		_balance(_args.balance)
		return
	if _args.has("city-plan"):
		_city_plan(_args["city-plan"])
		return

	menu = Menu.new()
	menu.host_pressed.connect(func(): _host("corridor"))
	menu.mission_pressed.connect(func(id: String): _host("city", id))
	menu.join_pressed.connect(_join)
	add_child(menu)
	Net.join_failed.connect(func(): _to_menu("Couldn't connect. Check the IP, that the host is running, and the firewall."))
	Net.host_lost.connect(func(): _to_menu("Lost connection to the host."))
	Net.joined.connect(_on_joined)
	menu.open()
	if _args.has("mission"):
		menu.select(_args.mission)

	if _args.has("screenshot"):
		for t in str(_args.get("shot-at", "5")).split(","): # e.g. --shot-at=2,4,6 saves x_0.png, x_1.png...
			get_tree().create_timer(float(t)).timeout.connect(_screenshot)
	if _args.has("quit-after"):
		get_tree().create_timer(float(_args["quit-after"])).timeout.connect(_quit_with_summary)
	if _args.has("host"):
		_host("city" if _args.has("mission") else _args.get("map", "city"), _args.get("mission", ""))
	elif _args.has("join"):
		_join(_args.join)


func _new_game(map_name := "city", mission := "") -> Game:
	game = Game.new()
	game.bot = _args.has("bot")
	game.map_name = map_name
	game.mission = mission
	if _args.has("demo") or _args.has("fx-rack") or _args.has("gun-rack") or _args.has("zombie-rack") or not GameMap.NAMES.has(game.map_name):
		game.map_name = "corridor" # the debug line-ups are laid out for the corridor
	game.limited_ammo = _args.has("limited-ammo")
	game.bot_fires = not _args.has("no-fire")
	game.bot_aim = _args.get("bot-aim", "chest")
	game.leave_requested.connect(func(): _to_menu())
	add_child(game)
	menu.close()
	return game


## Free play in the city by default; the menu's Start hosts ("city", mission), training is the corridor.
func _host(map_name := "city", mission := "") -> void:
	var err := Net.host()
	if err != OK:
		menu.open("Couldn't host on port %d (already in use?)." % Config.PORT)
		return
	_new_game(map_name, mission).start_host(Net.player_name)
	if _args.has("no-hordes"):
		game.director.enabled = false
	if _args.has("spawn"):
		game.director.spawn_horde(int(_args.spawn))
	if _args.has("demo"):
		_demo()
	if _args.has("weapon"):
		game.give_weapon(1, int(_args.weapon) - 1)
	if _args.has("pose"):
		_pose(_args.pose)
	if _args.has("gun-rack"):
		_gun_rack()
	if _args.has("fx-rack"):
		_fx_rack()
	if _args.has("noise"):
		game.show_noise()
	if _args.has("zones"):
		game.add_child(game.map.data.debug_node())
	if _args.has("cam") or _args.has("shot-cam"):
		_debug_camera(_args.get("cam", _args.get("shot-cam", "")))
	if _args.has("poi-cam") and game.map is CityMap:
		var poi := (game.map as CityMap).poi_pos(mission if mission != "" else "terminal")
		_debug_camera("%f,%f,%f,0,-22" % [poi.x, poi.y + 38.0, poi.z + 80.0])
	if _args.has("bot-goal") and game.brain != null and game.map.zones.has(_args["bot-goal"]):
		game.brain.go_to_zone(_args["bot-goal"])
	if _args.has("perf"):
		_perf_left = float(_args.perf)
		_perf_warmup = 2.0
	if _args.has("zombie-rack"):
		_zombie_rack()
	var ips := ", ".join(Net.local_ips())
	print("[host] hosting on port %d. Friends join: %s" % [Config.PORT, ips])
	game.hud.push_feed("Hosting. Friends join with IP: %s" % ips)


func _join(ip: String) -> void:
	if Net.join(ip) != OK:
		menu.open("Invalid address.")


func _on_joined() -> void:
	_new_game().start_client(Net.player_name)


func _to_menu(message := "") -> void:
	if game:
		remove_child(game)
		game.queue_free()
		game = null
	Net.leave()
	menu.open(message)


func _input(event: InputEvent) -> void:
	# Click the game window to recapture the mouse after Esc / alt-tab.
	if game and event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not game.hud.pause_panel.get_global_rect().has_point(event.position):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	if _perf_left <= 0.0:
		return
	if _perf_warmup > 0.0:
		_perf_warmup -= delta
		return
	_perf_ms.append(delta * 1000.0)
	_perf_draws.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	_perf_left -= delta
	if _perf_left <= 0.0:
		_perf_report()


## What --perf measured: average, 99th percentile and worst frame, and the draw calls.
func _perf_report() -> void:
	var sorted := _perf_ms.duplicate()
	sorted.sort()
	var sum := 0.0
	for ms in _perf_ms:
		sum += ms
	var draws := 0
	var most := 0
	for d in _perf_draws:
		draws += d
		most = maxi(most, d)
	var n := _perf_ms.size()
	print("[perf] map=%s frames=%d  avg %.2f ms (%.0f fps)  99%% %.2f ms  worst %.2f ms  draws avg %d max %d  zombies %d" % [
		game.map_name if game else "menu", n, sum / n, 1000.0 * n / sum, sorted[int(n * 0.99)], sorted[n - 1],
		draws / n, most, game.zombies.size() if game else 0])
	get_tree().quit()


## A line-up of every zombie type walking at you, for looking at animations.
func _demo() -> void:
	game.director.enabled = false
	game.door.toggle()
	var types := [Zombie.Type.WALKER, Zombie.Type.RUNNER, Zombie.Type.LEAPER, Zombie.Type.WALKER,
		Zombie.Type.WALKER, Zombie.Type.RUNNER, Zombie.Type.LEAPER, Zombie.Type.WALKER]
	for i in types.size():
		game.spawn_zombie(types[i], Vector3(-2.2 + (i % 4) * 1.4, 0.1, 8.0 + (i / 4) * 5.0 + (i % 2) * 1.5))


## Hold a first-person gun pose so a screenshot can show it.
func _pose(pose: String) -> void:
	var p := game.local_player
	p.debug_aim = pose == "aim"
	p.debug_sprint = pose == "sprint"
	if pose == "reload": # be 40% through a reload when the first screenshot is taken
		var at := float(str(_args.get("shot-at", "5")).split(",")[0])
		var t: float = p.weapons.def().reload
		get_tree().create_timer(maxf(0.5, at - t * 0.4)).timeout.connect(func():
			if game:
				game.local_player.weapons.ammo[game.local_player.weapons.current] = 0
				game.local_player.weapons.start_reload())


## All nine guns side on, three rows of three, lit by their own lamp.
func _gun_rack() -> void:
	game.director.enabled = false
	game.local_player.hide_view = true
	var eye := game.local_player.global_position + Vector3(0, Config.EYE_HEIGHT, 0)
	for id in Weapons.COUNT:
		var g := Guns.build(id)
		game.add_child(g)
		g.rotation.y = -PI / 2.0 # barrel to the right
		g.position = eye + Vector3(-1.25 + (id % 3) * 1.25 - 0.15, 0.48 - (id / 3) * 0.48, -1.9)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 8.0
	lamp.light_energy = 2.5
	lamp.position = eye + Vector3(0.6, 0.8, -0.6)
	game.add_child(lamp)


## Every effect in Fx.Kind in a row, each replayed every two seconds, with its name over it.
func _fx_rack() -> void:
	game.director.enabled = false
	game.local_player.hide_view = true
	var at := game.local_player.global_position
	var n := Fx.Kind.size()
	for kind in n:
		var tag := Label3D.new()
		tag.text = Fx.NAMES[kind]
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.font_size = 40
		tag.pixel_size = 0.004
		tag.outline_size = 10
		tag.position = _fx_rack_spot(at, kind, n) + Vector3(0, 1.6, 0)
		game.add_child(tag)
	var timer := Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_fx_rack_play)
	game.add_child(timer) # dies with the game, so the timer never outlives it
	_fx_rack_play()


func _fx_rack_spot(at: Vector3, kind: int, n: int) -> Vector3:
	return at + Vector3((kind - (n - 1) / 2.0) * 0.7, 0.0, -5.0)


func _fx_rack_play() -> void:
	var at := game.local_player.global_position
	var n := Fx.Kind.size()
	for kind in n:
		var on_floor: bool = kind in [Fx.Kind.BLAST, Fx.Kind.SPLASH]
		var spot := _fx_rack_spot(at, kind, n)
		var decal: bool = kind in [Fx.Kind.HOLE, Fx.Kind.CRACK]
		game.play_fx(kind, spot + Vector3(0, 0.0 if on_floor or decal else 0.9, 0), Vector3.UP, 0.3 if kind == Fx.Kind.BLAST else 1.0)


## Still zombies, one per outfit, half of them at a time so none hides another. Models only: no AI.
func _zombie_rack() -> void:
	game.director.enabled = false
	game.local_player.hide_view = true
	var at := game.local_player.global_position
	var n := Characters.Outfit.size()
	var per_row := (n + 1) / 2
	for o in n:
		if o / per_row != int(_args["zombie-rack"]) - 1:
			continue
		var rig := Characters.zombie(100 + o * 7, Zombie.Type.WALKER, o)
		game.add_child(rig)
		rig.position = at + Vector3((o % per_row - (per_row - 1) / 2.0) * 0.95, 0.1, -3.2)
		rig.rotation.y = 0.0 if _args.has("back") else PI
		rig.set_anim(Humanoid.Anim.IDLE)
		rig.update(0.5, 0.0)
		var tag := Label3D.new()
		tag.text = Characters.OUTFIT_NAMES[o]
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.font_size = 40
		tag.pixel_size = 0.004
		tag.outline_size = 10
		tag.position = rig.position + Vector3(0, 2.05, 0)
		game.add_child(tag)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 10.0
	lamp.light_energy = 0.8
	lamp.position = at + Vector3(0, 2.4, -1.0)
	game.add_child(lamp)


## Print the balance sheet and save it as Markdown, then quit. Works headless (tools\balance.ps1).
func _balance(path: String) -> void:
	var text := Balance.sheet()
	print(text)
	if path != "true":
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f != null:
			f.store_string(text)
			print("[balance] saved ", path)
	get_tree().quit()


## Draw which part of Joinville the city map covers, then quit. Works headless.
func _city_plan(dir: String) -> void:
	var t := Time.get_ticks_msec()
	var city := CityMap.new()
	print("[city] built in %d ms: %.2f km2, %d x %d cells of %.0f m, %d buildings" % [
		Time.get_ticks_msec() - t, city.area_km2(), city.gw, city.gh, city.cell, city.building_count])
	city.plan_image().save_png(dir.path_join("city_plan.png"))
	var over := city.reference_overlay()
	if over != null:
		over.save_png(dir.path_join("city_on_reference.png"))
	print("[city] saved city_plan.png and city_on_reference.png in ", dir)
	city.root.free()
	get_tree().quit()


## A fixed camera for looking at a map: "x,y,z,yaw,pitch" in metres and degrees.
func _debug_camera(spec: String) -> void:
	var v := spec.split_floats(",")
	if v.size() < 5:
		return
	var cam := Camera3D.new()
	cam.fov = 70
	cam.far = maxf(400.0, v[1] * 6.0) # high overview cameras need to see the ground
	game.add_child(cam)
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(v[4]), deg_to_rad(v[3]), 0)), Vector3(v[0], v[1], v[2]))
	cam.make_current()
	game.local_player.hide_view = true


func _screenshot() -> void:
	await RenderingServer.frame_post_draw
	var path: String = _args.screenshot
	path = path.replace(".png", "_%d.png" % _shots)
	_shots += 1
	get_viewport().get_texture().get_image().save_png(path)
	print("[screenshot] ", path)


func _quit_with_summary() -> void:
	if game:
		var kills := 0
		for p: Dictionary in game.players.values():
			kills += p.kills
		print("[summary] host=%s players=%d zombies=%d remotes=%d kills=%d gore=%s fps=%d" % [
			game.is_host, game.players.size(), game.zombies.size(), game.remotes.size(), kills,
			str(game.gore.stats), Engine.get_frames_per_second()])
	get_tree().quit()
