class_name LocalPlayer
extends CharacterBody3D

signal shoved(origin: Vector3, dir: Vector3) ## a shove went out: the game tells the host
signal landed(height: float) ## the feet came down after falling this far (the host decides if it hurt)
signal item_requested(item: StringName) ## an item of the inventory is to be used (the host decides if it can be)
signal use_cancelled ## a sprint began while an item was being put on
signal chat_requested ## the chat key: open the line to type in
signal ping_requested(spot: Vector3) ## the ping key: mark where the view points
## The player you control: physics movement, mouse look, first-person camera and guns.
## Movement runs at the physics rate; the camera is placed every rendered frame from the
## interpolated body transform, so it's smooth at 144 Hz.

var yaw := 0.0
var pitch := 0.0
var firing := false
var move_speed := 0.0
var camera: Camera3D
var weapons := WeaponState.new()
var move := MoveState.new() # stamina, crouch, coyote time, landing dip, vault
var capsule: CapsuleShape3D
var body_shape: CollisionShape3D
var debug_crouch := false # tests and screenshots: hold the crouch
var _breath_t := 0.0
var shove_left := 0.0 # > 0 while a shove is still being swung
var loadout := Loadout.all() # the guns this player carries, by slot (the host keeps its own copy)
var last_weapon := -1     # the gun held before this one (the last-weapon key goes back to it)
var inventory := Inventory.new() # a copy of what the host says we carry: for the wheel and the HUD, never trusted
var wheel := ItemWheel.new()     # the item wheel, while its key is held
var status := PlayerStatus.new() # wounds and what is being put on, as the host says (a copy, for the HUD and the view)
var spectator := Spectator.new() # who a dead player watches
var spectate_candidates: Array = [] # the living they may watch (Game fills it)
var spectate_following := false   # the camera has someone to follow...
var spectate_focus := Vector3.ZERO # ...standing here...
var spectate_yaw := 0.0            # ...facing this way
var _spectate_cam := Vector3.INF   # where the camera is
var _dead_t := 0.0
var view: Viewmodel
var down_pose := 0.0      # 0 standing .. 1 on the floor, downed (eases: see step_down_view)
var arrive_left := 0.0    # > 0 while dropping off the truck bed after a respawn
var typing := false       # the chat line is open: keys go to it, not to walking
var aiming := false
var sprinting := false
var aim_blocked := false  # this right-click was spent on a door or lootbox
var fire_buffer := 0.0    # > 0 for a moment after a click, so semi-auto clicks aren't lost
var punch := Vector2.ZERO # recoil on top of where you're looking (climb, sideways); recovers
var debug_aim := false    # tests and screenshots: hold the sights up / hold the sprint pose
var debug_sprint := false
var hide_view := false   # screenshots of the world without the gun in the way
var bot := false # test mode: a Bot aims, fires and walks for us
var bot_move := Vector3.ZERO # with `bot`: the direction to walk (world space, flat), zero to stand
var bot_sprint := false
var _aim_latched := false # Settings aim_toggle: right mouse flips this instead of being held


func _ready() -> void:
	collision_layer = Config.LAYER_PLAYER
	collision_mask = Config.LAYER_WORLD | Config.LAYER_ZOMBIE # a horde can box you in
	body_shape = CollisionShape3D.new()
	capsule = CapsuleShape3D.new()
	capsule.radius = Config.PLAYER_RADIUS
	capsule.height = Config.PLAYER_HEIGHT
	body_shape.shape = capsule
	body_shape.position.y = Config.PLAYER_HEIGHT / 2.0
	add_child(body_shape)

	camera = Camera3D.new()
	camera.top_level = true
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	camera.fov = base_fov()
	camera.near = 0.05
	camera.far = 300
	add_child(camera)
	camera.make_current()
	view = Viewmodel.new()
	camera.add_child(view)
	view.show_weapon(weapons.current)


## Call before the player enters the tree: the guns it starts with.
func set_loadout(carried: Loadout) -> void:
	loadout = carried
	last_weapon = -1
	if not loadout.has(weapons.current):
		weapons.current = loadout.guns()[0]
		if view != null:
			view.show_weapon(weapons.current)


func switch_weapon(id: int) -> void:
	if status.downed and id != loadout.sidearm():
		return # on the floor, only the pistol is within reach
	var before := weapons.current
	if loadout.has(id) and weapons.switch_to(id):
		last_weapon = before
		view.show_weapon(id)


## Number key `n` (0 = "1"): the gun in that slot, or gun `n` itself where everything is carried.
func press_weapon_key(n: int) -> void:
	var id := loadout.key(n)
	if id >= 0:
		switch_weapon(id)


## Back to the gun held before this one.
func switch_last() -> void:
	if last_weapon >= 0 and loadout.has(last_weapon):
		switch_weapon(last_weapon)


## Next (+1) or previous (-1) gun you actually carry.
func cycle_weapon(step: int) -> void:
	switch_weapon(loadout.next(weapons.current, step))


## The host gave us a gun: carry it (in place of `dropped`, if the slots were full), with `rounds`
## in its magazine (-1 = a full one), and hold it.
func receive_weapon(id: int, rounds := -1, dropped := -1) -> void:
	loadout.swap(id, dropped)
	var mag: int = Weapons.def(id).mag
	weapons.ammo[id] = clampi(rounds, 0, mag) if rounds >= 0 else mag
	switch_weapon(id)
	if not loadout.has(last_weapon):
		last_weapon = -1


## Recoil from one shot. Part of it stays (you pull down to compensate), the rest springs back.
func kick_view(k: Vector2) -> void:
	pitch = clampf(pitch + k.x * Config.RECOIL_STAYS, -1.5, 1.5)
	yaw += k.y * Config.RECOIL_STAYS
	punch += k * (1.0 - Config.RECOIL_STAYS)


## Hold the wheel key: the mouse moves its pointer instead of the view, until the key is let go.
func open_wheel() -> void:
	wheel.begin(inventory)


## Let go of the wheel: a medical item is used, a throwable becomes the one the quick key throws.
func close_wheel() -> void:
	var item := wheel.finish()
	match Inventory.kind_of(item):
		Inventory.Kind.MEDICAL:
			item_requested.emit(item)
		Inventory.Kind.THROWABLE:
			inventory.select_throwable(item)


## Sprinting off while something is being put on cancels it (the host is told; the item stays in the pack).
func check_use_cancel(running: bool) -> void:
	if running and status.is_using():
		status.cancel_use()
		use_cancelled.emit()


## The quick-heal key: the best heal carried. False if there is none.
func try_quick_heal() -> bool:
	var item := inventory.quick_heal()
	if item == &"":
		return false
	item_requested.emit(item)
	return true


## The quick-throw key: the throwable that is ready. False if there is none.
func try_quick_throw() -> bool:
	var item := inventory.selected_throwable()
	if item == &"":
		return false
	item_requested.emit(item)
	return true


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		handle_event(event)


## What a key press or mouse move does (only while the mouse is captured; tests call this directly).
func handle_event(event: InputEvent) -> void:
	if not bot and event.is_action_pressed("chat"): # (the dead too)
		chat_requested.emit()
		return
	if not bot and event.is_action_pressed("ping"):
		ping_requested.emit(look_point())
		return
	if status.dead: # watching: fire goes to the next one, aim to the one before
		if event.is_action_pressed("fire"):
			spectator.cycle(spectate_candidates, 1)
		elif event.is_action_pressed("aim"):
			spectator.cycle(spectate_candidates, -1)
		elif event is InputEventMouseMotion:
			pass
		return
	if wheel.open: # nothing else works with the wheel up
		if event.is_action_released("item_wheel"):
			close_wheel()
		elif event is InputEventMouseMotion:
			wheel.push(event.relative)
		return
	if event is InputEventMouseMotion:
		var sens: float = Settings.get_value("mouse_sensitivity") * camera.fov / base_fov() # slower when zoomed in
		yaw -= event.relative.x * sens
		pitch = clampf(pitch - event.relative.y * sens * (-1.0 if Settings.get_value("invert_y") else 1.0), -1.5, 1.5)
	elif bot:
		return
	elif event.is_action_pressed("aim") and Settings.get_value("aim_toggle"):
		_aim_latched = not _aim_latched
	elif event.is_action_pressed("fire"):
		fire_buffer = Config.FIRE_BUFFER
	elif event.is_action_pressed("reload"):
		weapons.start_reload()
	elif event.is_action_pressed("last_weapon"):
		switch_last()
	elif event.is_action_pressed("shove"):
		try_shove()
	elif event.is_action_pressed("item_wheel"):
		if not status.downed:
			open_wheel()
	elif event.is_action_pressed("quick_heal"):
		try_quick_heal()
	elif event.is_action_pressed("quick_throw"):
		try_quick_throw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		cycle_weapon(1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		cycle_weapon(-1)
	else:
		for i in Weapons.COUNT:
			if event.is_action_pressed("weapon_%d" % (i + 1)):
				press_weapon_key(i)


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if wheel.open and not captured:
		wheel.finish() # the window lost the mouse (pause menu) with the wheel up: nothing is picked
	if captured and not bot and not typing:
		input = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		firing = Input.is_action_pressed("fire") and not wheel.open
	elif typing:
		firing = false
	elif not bot:
		firing = false

	if status.downed and loadout.sidearm() >= 0 and weapons.current != loadout.sidearm():
		var before := weapons.current
		if weapons.switch_to(loadout.sidearm()): # the pistol comes out by itself
			last_weapon = before
			view.show_weapon(weapons.current)
	if status.dead: # a ghost: no walking about, no shooting
		firing = false
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= Config.GRAVITY * delta
		move_and_slide()
		move_speed = 0.0
		return
	var ready := not weapons.is_reloading() and weapons.draw_left <= 0.0
	var toggle: bool = Settings.get_value("aim_toggle")
	if not toggle or not ready or aim_blocked or not captured:
		_aim_latched = false # reloading, swapping, using a door or leaving the window lowers the sights
	var held := _aim_latched if toggle else Input.is_action_pressed("aim")
	var want_aim := debug_aim or (captured and not bot and not aim_blocked and held and not wheel.open)
	aiming = want_aim and ready and not move.is_vaulting()
	view.stow_goal = 1.0 if move.is_vaulting() else 0.0
	if move.is_vaulting():
		_vault_step(delta)
		return
	var wants_crouch := debug_crouch or (captured and not bot and Input.is_action_pressed("crouch"))
	if not wants_crouch and move.crouch > 0.0 and not _room_to_stand():
		wants_crouch = true # something low overhead keeps you down
	var running := captured and not bot and Input.is_action_pressed("sprint") and input.y > 0 and not aiming
	var dir := Basis(Vector3.UP, yaw) * Vector3(input.x, 0, -input.y)
	if bot:
		dir = bot_move
		running = bot_sprint and bot_move != Vector3.ZERO and not aiming
	else:
		running = running and move.can_sprint() and not wants_crouch # winded or crouched: a walk
	if status.downed:
		running = false
	check_use_cancel(running and move_speed > 0.1)
	sprinting = (running or debug_sprint) and not aiming
	var speed := Config.DOWNED_SPEED if status.downed else move.speed(weapons.current, running, aiming)
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	var fall_speed := maxf(0.0, -velocity.y)
	if captured and not bot and Input.is_action_just_pressed("jump") and move.can_jump() and not status.downed:
		velocity.y = Config.JUMP_VELOCITY # also just after walking off an edge (coyote time)
		move.jump()
	elif not is_on_floor():
		velocity.y -= Config.GRAVITY * delta
	if running and not bot and is_on_floor() and try_vault(dir):
		return
	move_and_slide()
	move_speed = Vector2(velocity.x, velocity.z).length()
	# The bot is a test player: it never tires.
	var fell := move.step(delta, running and not bot and move_speed > 0.1, is_on_floor(), wants_crouch, global_position.y, fall_speed)
	if fell > 0.0:
		landed.emit(fell)
	capsule.height = move.height()
	body_shape.position.y = capsule.height / 2.0
	_breathe(delta)


## Strike with the gun's stock or muzzle. False if a swing is still going, you are too tired, or
## your hands are busy.
func try_shove() -> bool:
	if status.downed or status.dead or shove_left > 0.0 or move.is_vaulting() or move.stamina < Config.SHOVE_STAMINA:
		return false
	shove_left = Config.SHOVE_TIME
	move.stamina -= Config.SHOVE_STAMINA
	view.shove()
	shoved.emit(camera.global_position, -camera.global_basis.z)
	return true


## What others should see this body doing, as PlayerWire.ACTION_* bits.
func action_bits() -> int:
	var bits := 0
	if move.crouch > 0.5:
		bits |= PlayerWire.ACTION_CROUCH
	if move.is_vaulting() or move.air_time > 0.1:
		bits |= PlayerWire.ACTION_AIR
	return bits


## Heavy breathing while winded, one breath at a time.
func _breathe(delta: float) -> void:
	if not move.winded:
		_breath_t = 0.0
		return
	_breath_t -= delta
	if _breath_t <= 0.0:
		_breath_t = Config.BREATH_INTERVAL
		Sfx.play_ui("breath", Config.BREATH_VOLUME)


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD))


## Is there headroom to stand up where we are?
func _room_to_stand() -> bool:
	var feet := global_position
	return _ray(feet + Vector3(0, Config.CROUCH_HEIGHT - 0.1, 0), feet + Vector3(0, Config.PLAYER_HEIGHT + 0.05, 0)).is_empty()


## Go over waist-high cover lying `dir` ahead, if there is some: low enough, thin enough, with
## clear floor behind it. True when the vault has begun.
func try_vault(dir: Vector3) -> bool:
	var fwd := Vector3(dir.x, 0, dir.z).normalized()
	if move.is_vaulting() or fwd == Vector3.ZERO or not is_inside_tree():
		return false
	var feet := global_position
	var low := _ray(feet + Vector3(0, Config.VAULT_MIN_HEIGHT, 0), feet + Vector3(0, Config.VAULT_MIN_HEIGHT, 0) + fwd * Config.VAULT_REACH)
	if low.is_empty():
		return false # nothing in the way
	var hit: Vector3 = low.position
	var near := Vector2(hit.x - feet.x, hit.z - feet.z).length()
	var far := near + Config.VAULT_MAX_DEPTH + Config.PLAYER_RADIUS + 0.2 # where the feet come down
	var over := Vector3(0, Config.VAULT_MAX_HEIGHT + 0.15, 0)
	if not _ray(feet + over, feet + over + fwd * (far + Config.PLAYER_RADIUS)).is_empty():
		return false # a wall, or something tall right behind
	var top := _ray(feet + over + fwd * (near + 0.1), feet + fwd * (near + 0.1))
	if top.is_empty():
		return false
	var top_at: Vector3 = top.position
	var height := top_at.y - feet.y
	if height < Config.VAULT_MIN_HEIGHT or height > Config.VAULT_MAX_HEIGHT:
		return false
	var ground := _ray(feet + over + fwd * far, feet + fwd * far - Vector3(0, Config.FALL_SAFE_HEIGHT, 0))
	if ground.is_empty():
		return false
	var land_at: Vector3 = ground.position
	if land_at.y - feet.y > Config.VAULT_MIN_HEIGHT * 0.5:
		return false # still on top of it: too deep to clear
	move.start_vault(feet, land_at, height)
	view.stow_goal = 1.0 # hands on the cover, not the gun
	return true


## Carried over the cover along MoveState's arc; nothing else moves the body meanwhile.
func _vault_step(delta: float) -> void:
	move.step(delta, false, false, false, global_position.y, 0.0)
	global_position = move.vault_point()
	velocity = Vector3.ZERO
	move_speed = Config.WALK_SPEED
	sprinting = false


## Where the view points: the first wall or floor along it, or a spot well ahead in the open.
func look_point() -> Vector3:
	var from := camera.global_position
	var dir := -camera.global_transform.basis.z
	var to := from + dir * Config.PING_REACH
	if is_inside_tree():
		var q := PhysicsRayQueryParameters3D.create(from, to, Config.LAYER_WORLD)
		var hit := get_world_3d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			return hit.position
	return to


## Coming back: the view starts up on a truck bed and drops to the ground over `Config.ARRIVE_TIME`.
func arrive() -> void:
	arrive_left = Config.ARRIVE_TIME


func step_arrival(delta: float) -> void:
	arrive_left = maxf(0.0, arrive_left - delta)


## Going down drops the eyes to the floor and tilts the view (`Config.DOWNED_FALL_TIME`); getting up
## brings them back (`GETUP_TIME`). 0 = standing, 1 = on the floor.
func step_down_view(delta: float) -> void:
	var goal := 1.0 if status.downed else 0.0
	var time := Config.DOWNED_FALL_TIME if goal > down_pose else Config.GETUP_TIME
	down_pose = move_toward(down_pose, goal, delta / time)


## How high the eyes are above the feet now.
func view_height() -> float:
	var u := arrive_left / Config.ARRIVE_TIME # a fall: slow off the edge, fast at the bottom
	return lerpf(move.eye_height(), Config.DOWNED_EYE, Viewmodel._ease(down_pose)) + Config.ARRIVE_DROP * (1.0 - (1.0 - u) * (1.0 - u))


## How far the view is tilted sideways now.
func view_roll() -> float:
	return Config.DOWNED_ROLL * Viewmodel._ease(down_pose)


func _process(delta: float) -> void:
	step_down_view(delta)
	step_arrival(delta)
	var origin := get_global_transform_interpolated().origin + Vector3(0, view_height(), 0)
	weapons.step(delta)
	shove_left = maxf(0.0, shove_left - delta)
	fire_buffer -= delta
	punch = punch.lerp(Vector2.ZERO, 1.0 - exp(-Config.RECOIL_RECOVER * delta))
	if status.dead:
		_place_spectator_camera(origin, delta)
		return
	_spectate_cam = Vector3.INF
	_dead_t = 0.0
	camera.global_transform = Transform3D(Basis.from_euler(Vector3(pitch + punch.x, yaw + punch.y, view_roll())), origin)
	var healing := status.is_using() and Inventory.valid(status.using) # (a revive is hands on someone else)
	view.heal_goal = 1.0 if healing else 0.0
	view.heal_t = status.use_total - status.use_left if healing else 0.0
	view.update(delta, move_speed, aiming, sprinting, weapons)
	var zoom: float = weapons.def().ads_fov
	camera.fov = lerpf(base_fov(), minf(zoom, base_fov()), Viewmodel._ease(view.aim))


## The camera of a dead player: behind and above whoever they watch, easing after them, or slowly
## round their own body when nobody is left. `origin` is where their eyes were.
func _place_spectator_camera(origin: Vector3, delta: float) -> void:
	_dead_t += delta
	var focus := spectate_focus if spectate_following else global_position
	var goal := Spectator.camera_goal(spectate_focus, spectate_yaw) if spectate_following else Spectator.orbit_goal(global_position, _dead_t)
	_spectate_cam = origin if _spectate_cam == Vector3.INF else Spectator.follow(_spectate_cam, goal, delta)
	var look := focus + Vector3(0, 1.4, 0) - _spectate_cam
	if look.length() > 0.01: # (straight down at the first frame, from the eyes: pick another way up)
		var up := Vector3.UP if absf(look.normalized().y) < 0.99 else Vector3.FORWARD
		camera.global_transform = Transform3D(Basis.IDENTITY, _spectate_cam).looking_at(focus + Vector3(0, 1.4, 0), up)
	view.update(delta, 0.0, false, false, weapons)


## The field of view the player chose (Config.FOV unless they changed it).
func base_fov() -> float:
	return Settings.get_value("fov")


func teleport(pos: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	reset_physics_interpolation()
