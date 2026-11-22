class_name PropRack
extends Node3D
## One element alone in a neutral, evenly lit room (`--prop-rack=<name>`), for looking at it and
## for the review sheets (tools/models/review.py). A grey floor with a faint 1 m checker to read
## sizes by, a sky-grey ambient light, a key light that casts shadows and a soft fill.
##   --prop-rack=hydrant [--state=burnt] [--part=open] [--view=0..10]
##   --review=C:/dir       shoot every view, the parts open and every state into dir, then quit
## An element with close-ups of its own (`views` in its .json: the kit's board) also gets each of
## those shot in every state (`view_<name>_<state>.png`); `--view=name` puts the camera on one.

## The review's views, by name: eight angles round it, a 1 m close-up, 10 m and 50 m.
const VIEWS := ["a0", "a45", "a90", "a135", "a180", "a225", "a270", "a315", "close_1m", "far_10m", "far_50m"]

var model: PropModel
var element: Node3D
var camera: Camera3D
var state := ""


func setup(elem: String, args: Dictionary) -> bool:
	model = PropModel.load_model(elem)
	if model == null:
		push_error("no element " + elem)
		return false
	state = args.get("state", "")
	_room()
	_place(state)
	if args.get("part", "") == "open":
		_open(1.0)
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.far = 400.0
	add_child(camera)
	camera.make_current()
	var v := String(args.get("view", "1"))
	if v.is_valid_int():
		look(int(v))
	else:
		look_view(_view_index(v))
	return true


## The element's own close-ups (its .json's `views`: name, eye, at, fov).
func views() -> Array:
	return model.info.get("views", [])


func _view_index(view_name: String) -> int:
	for i in views().size():
		if views()[i].name == view_name:
			return i
	return 0


## Put the camera on the element's own close-up i.
func look_view(i: int) -> void:
	var v: Dictionary = views()[i]
	var e: Array = v.eye
	var a: Array = v.at
	camera.fov = float(v.get("fov", 40.0))
	camera.look_at_from_position(Vector3(e[0], e[1], e[2]), Vector3(a[0], a[1], a[2]))


func _room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.37, 0.39)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.84)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -35, 0)
	key.light_energy = 1.1
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 30.0
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25, 150, 0)
	fill.light_energy = 0.35
	add_child(fill)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.46, 0.46, 0.47))
	img.set_pixel(1, 1, Color(0.46, 0.46, 0.47))
	img.set_pixel(1, 0, Color(0.42, 0.42, 0.43))
	img.set_pixel(0, 1, Color(0.42, 0.42, 0.43))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(200, 200, 1) # 2 texels a tile, 400 m: 1 m squares
	mat.roughness = 1.0
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(400, 400)
	var fl := MeshInstance3D.new()
	fl.mesh = floor_mesh
	fl.material_override = mat
	add_child(fl)


func _place(s: String) -> void:
	if element:
		element.free()
	element = model.instance(s)
	add_child(element)


func _open(t: float) -> void:
	for part: String in model.info.parts:
		PropModel.set_open(element, part, t)


## Put the camera on view i of VIEWS.
func look(i: int) -> void:
	var size := model.size()
	var c := Vector3(0, size.y * 0.5, 0)
	var r := maxf(maxf(size.x, size.z), size.y) * 2.2 + 0.3
	var eye: Vector3
	var at := c
	if i < 8:
		var a := deg_to_rad(45.0 * i)
		eye = c + Vector3(-sin(a) * r, r * 0.3, -cos(a) * r)
	elif i == 8:
		# the head of a post (a hydrant's outlets, plate, dome); the middle of anything taller than a person
		at = Vector3(0, size.y * (0.68 if size.y < 1.5 else 0.5), 0)
		eye = at + Vector3(-0.34, 0.12, -0.93)
	elif i == 9:
		eye = Vector3(-5.0, 1.7, -8.66)
	else:
		eye = Vector3(-25.0, 1.7, -43.3)
	camera.fov = 40.0 if i < 10 else 5.0 # the 50 m view is zoomed, so it shows the far LOD at a readable size
	if i == 9:
		camera.fov = 18.0
	camera.look_at_from_position(eye, at)


## Every view, the parts open and every state, saved as PNGs into `dir`, then quit.
func review(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for i in VIEWS.size():
		look(i)
		await _shoot(dir.path_join(VIEWS[i] + ".png"))
	look(1)
	_open(1.0)
	await _shoot(dir.path_join("open.png"))
	_open(0.0)
	look(1)
	camera.fov = 24.0 # the states close enough to see the paint
	for s: String in model.states():
		_place(s)
		await _shoot(dir.path_join("state_" + s + ".png"))
	if views().size():
		get_window().size = Vector2i(1280, 720) # close-ups are landscape, big enough to read lettering
		for f in 3:
			await get_tree().process_frame
	for s: String in model.states():
		_place(s)
		for i in views().size():
			look_view(i)
			await _shoot(dir.path_join("view_%s_%s.png" % [views()[i].name, s]))
	print("[review] ", dir)
	get_tree().quit()


func _shoot(path: String) -> void:
	for f in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
