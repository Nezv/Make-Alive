class_name LocalPlayer
extends CharacterBody3D
## The player you control: physics movement, mouse look, first-person camera and guns.
## Movement runs at the physics rate; the camera is placed every rendered frame from the
## interpolated body transform, so it's smooth at 144 Hz.

var yaw := 0.0
var pitch := 0.0
var firing := false
var move_speed := 0.0
var camera: Camera3D
var weapons := WeaponState.new()
var owned := {}           # Weapons id -> true: the guns this player has found
var view: Viewmodel
var aiming := false
var sprinting := false
var aim_blocked := false  # this right-click was spent on a door or lootbox
var fire_buffer := 0.0    # > 0 for a moment after a click, so semi-auto clicks aren't lost
var punch := Vector2.ZERO # recoil on top of where you're looking (climb, sideways); recovers
var debug_aim := false    # tests and screenshots: hold the sights up / hold the sprint pose
var debug_sprint := false
var hide_view := false   # screenshots of the world without the gun in the way
var bot := false # test mode: Game aims and fires for us


func _ready() -> void:
	collision_layer = Config.LAYER_PLAYER
	collision_mask = Config.LAYER_WORLD | Config.LAYER_ZOMBIE # a horde can box you in
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = Config.PLAYER_RADIUS
	cap.height = Config.PLAYER_HEIGHT
	cs.shape = cap
	cs.position.y = Config.PLAYER_HEIGHT / 2.0
	add_child(cs)

	camera = Camera3D.new()
	camera.top_level = true
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.fov = Config.FOV
	camera.near = 0.05
	camera.far = 300
	add_child(camera)
	camera.make_current()
	view = Viewmodel.new()
	camera.add_child(view)
	view.show_weapon(weapons.current)


## Call before the player enters the tree: the guns it starts with.
func set_loadout(guns: Dictionary) -> void:
	owned = guns
	if not owned.has(weapons.current):
		weapons.current = Weapons.P19


func switch_weapon(id: int) -> void:
	if owned.has(id) and weapons.switch_to(id):
		view.show_weapon(id)


## Next (+1) or previous (-1) gun you actually own.
func cycle_weapon(step: int) -> void:
	for i in range(1, Weapons.COUNT):
		var id := posmod(weapons.current + step * i, Weapons.COUNT)
		if owned.has(id):
			switch_weapon(id)
			return


## The host gave us a gun: own it, load it, hold it.
func receive_weapon(id: int) -> void:
	owned[id] = true
	weapons.ammo[id] = Weapons.def(id).mag
	switch_weapon(id)


## Recoil from one shot. Part of it stays (you pull down to compensate), the rest springs back.
func kick_view(k: Vector2) -> void:
	pitch = clampf(pitch + k.x * Config.RECOIL_STAYS, -1.5, 1.5)
	yaw += k.y * Config.RECOIL_STAYS
	punch += k * (1.0 - Config.RECOIL_STAYS)


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		var sens := Config.MOUSE_SENS * camera.fov / Config.FOV # slower when zoomed in
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens, -1.5, 1.5)
	elif bot:
		return
	elif event.is_action_pressed("fire"):
		fire_buffer = Config.FIRE_BUFFER
	elif event.is_action_pressed("reload"):
		weapons.start_reload()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		cycle_weapon(1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		cycle_weapon(-1)
	else:
		for i in Weapons.COUNT:
			if event.is_action_pressed("weapon_%d" % (i + 1)):
				switch_weapon(i)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if captured and not bot:
		input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		firing = Input.is_action_pressed("fire")
	elif not bot:
		firing = false

	var ready := not weapons.is_reloading() and weapons.draw_left <= 0.0
	var want_aim := debug_aim or (captured and not bot and not aim_blocked and Input.is_action_pressed("aim"))
	aiming = want_aim and ready
	var running := captured and not bot and Input.is_action_pressed("sprint") and input.y > 0 and not aiming
	sprinting = (running or debug_sprint) and not aiming
	var speed := Config.WALK_SPEED
	if running:
		speed = Config.SPRINT_SPEED
	elif aiming:
		speed *= Config.ADS_MOVE_MULT
	var dir := Basis(Vector3.UP, yaw) * Vector3(input.x, 0, -input.y)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	if is_on_floor():
		if captured and Input.is_action_just_pressed("jump"):
			velocity.y = Config.JUMP_VELOCITY
	else:
		velocity.y -= Config.GRAVITY * delta
	move_and_slide()
	move_speed = Vector2(velocity.x, velocity.z).length()


func _process(delta: float) -> void:
	var origin := get_global_transform_interpolated().origin + Vector3(0, Config.EYE_HEIGHT, 0)
	weapons.step(delta)
	fire_buffer -= delta
	punch = punch.lerp(Vector2.ZERO, 1.0 - exp(-Config.RECOIL_RECOVER * delta))
	camera.global_transform = Transform3D(Basis.from_euler(Vector3(pitch + punch.x, yaw + punch.y, 0)), origin)
	view.update(delta, move_speed, aiming, sprinting, weapons)
	var zoom: float = weapons.def().ads_fov
	camera.fov = lerpf(Config.FOV, zoom, Viewmodel._ease(view.aim))


func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	reset_physics_interpolation()
