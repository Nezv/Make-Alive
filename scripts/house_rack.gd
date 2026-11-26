class_name HouseRack
extends Node3D
## A house's floors built alone in a neutral, evenly lit room (`--house-rack[=seed]`), to walk the
## layout by eye: the floors above the one you look at taken off, and its ceiling, so you look
## down into the rooms; its lamps lit.
##   --house-rack[=seed]  the sample house (HousePlan.sample) with that seed
##   --floor=N            show the floors up to N (default: the top one)
##   --eye                start at eye height in the street door, looking in
## Keys: right mouse held looks round, WASD moves, Q / E down / up, Shift faster; PageUp / PageDown
## take a floor off or put it back; C ceilings, L lamps, F furniture; 1-9 stand at eye height in
## that floor's stair.

var plan: HousePlan
var house: Node3D
var camera: Camera3D
var cut := 0
var ceilings := false
var _yaw := 0.0
var _pitch := 0.0
var _look := false
var _label: Label


func setup(args: Dictionary) -> void:
	var arg := String(args.get("house-rack", "true"))
	var seed := int(arg) if arg.is_valid_int() else 18000
	plan = HousePlan.new(HousePlan.sample(seed))
	_room()
	house = InteriorBuilder.build(plan)
	add_child(house)
	cut = clampi(int(args.get("floor", str(plan.floors.size() - 1))), 0, plan.floors.size() - 1)
	camera = Camera3D.new()
	camera.fov = 60.0
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	if args.has("eye"):
		var door: Array = plan.frame.door
		_place(Vector3((float(door[0]) + float(door[1])) * 0.5, Config.EYE_HEIGHT, -1.2), 0.0, -4.0)
	else:
		_place(Vector3(plan.width * 0.5, plan.storey * (cut + 1) + 9.0, -6.5), 0.0, -52.0)
	var ui := CanvasLayer.new()
	_label = Label.new()
	_label.position = Vector2(12, 10)
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.9))
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	ui.add_child(_label)
	add_child(ui)
	_apply()


func _room() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.37, 0.39)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.84)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	ground.position.y = -Config.INTERIOR_SLAB - 0.01
	ground.material_override = MeshKit.unshaded(Color(0.3, 0.3, 0.31))
	add_child(ground)


func _place(at: Vector3, yaw_deg: float, pitch_deg: float) -> void:
	camera.position = at
	_yaw = deg_to_rad(yaw_deg + 180.0) # the street is at -z: looking into the house is looking +z
	_pitch = deg_to_rad(pitch_deg)
	camera.rotation = Vector3(_pitch, _yaw, 0)


## Floors above `cut` off, its ceiling off unless asked for.
func _apply() -> void:
	for i in plan.floors.size():
		var fl := house.get_node("floor_%d" % i)
		fl.visible = i <= cut
		(fl.get_node("ceiling") as Node3D).visible = i < cut or ceilings
	var f: Dictionary = plan.floors[cut]
	var kinds := []
	for s: Dictionary in f.spaces:
		kinds.append(HousePlan.KINDS[s.kind].label)
	_label.text = "seed %d · %.1f x %.1f m, %d floors · floor %d (%s): %s\n%s\nPgUp/PgDn floor · C ceilings · L lamps · F furniture · 1-9 stand in a floor · right mouse + WASD/QE" % [
		plan.spec.seed, plan.spec.width, plan.spec.depth, plan.floors.size(), cut, plan.frame.variant,
		", ".join(kinds), "" if f.ok else "NOT LAID OUT: " + String(f.problem)]


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		_look = e.pressed
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _look else Input.MOUSE_MODE_VISIBLE
	elif e is InputEventMouseMotion and _look:
		_yaw -= e.relative.x * 0.004
		_pitch = clampf(_pitch - e.relative.y * 0.004, -1.5, 1.5)
		camera.rotation = Vector3(_pitch, _yaw, 0)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_PAGEUP:
				cut = mini(cut + 1, plan.floors.size() - 1)
			KEY_PAGEDOWN:
				cut = maxi(cut - 1, 0)
			KEY_C:
				ceilings = not ceilings
			KEY_L:
				for i in plan.floors.size():
					var l := house.get_node("floor_%d/lights" % i) as Node3D
					l.visible = not l.visible
			KEY_F:
				for i in plan.floors.size():
					var m := house.get_node("floor_%d/furniture" % i) as Node3D
					m.visible = not m.visible
			_:
				var n: int = e.keycode - KEY_1
				if n >= 0 and n < plan.floors.size():
					cut = n
					var palier: Rect2 = plan.frame.palier
					_place(Vector3(palier.get_center().x, plan.storey * n + Config.EYE_HEIGHT, palier.get_center().y), 90.0, 0.0)
		_apply()


func _process(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move.z -= 1.0
	if Input.is_key_pressed(KEY_S):
		move.z += 1.0
	if Input.is_key_pressed(KEY_A):
		move.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		move.x += 1.0
	if Input.is_key_pressed(KEY_E):
		move.y += 1.0
	if Input.is_key_pressed(KEY_Q):
		move.y -= 1.0
	if move == Vector3.ZERO:
		return
	var speed := 9.0 if Input.is_key_pressed(KEY_SHIFT) else 2.5
	var b := camera.global_transform.basis
	camera.position += (b.x * move.x + Vector3.UP * move.y + b.z * move.z).normalized() * speed * delta
