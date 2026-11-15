class_name Game
extends Node
## One match. Lives at /root/Main/Game on every peer so RPCs line up.
##
## The host (peer 1) is authoritative: zombies, damage, doors, loot. Clients send their own
## position, their shots and their right-clicks; the host answers with snapshots (positions,
## 20 Hz, unreliable) and events (reliable): zombie_fx for gore, interact_state for doors etc.
##
## Gameplay reactions live in GameHooks (scripts/hooks.gd), not here.

signal leave_requested

enum Fx { HIT, SEVER, DIE }

var is_host := false
var my_id := 1
var bot := false
var bot_fires := true
var bot_aim := "chest" ## chest | head | legs | arms
var map_name := "corridor" ## set before start_host; clients get it in `welcome`
var mission := ""          ## a city POI id ("mirante"...) or "" for free play; clients get it in `welcome`
var map: GameMap
var world: Node3D
var door: Door
var lootbox: Lootbox
var interactables := {}  ## iid -> Interactable
var local_player: LocalPlayer
var hud: Hud
var gore: Gore
var hooks: GameHooks
var director: HordeDirector
var shot_player: AudioStreamPlayer
var remotes := {}        ## peer id -> RemotePlayer
var zombies := {}        ## zombie id -> Zombie
var zombie_list: Array[Zombie] = [] ## same zombies as an array, refreshed each host tick
var looked_at: Interactable = null
var rng := RandomNumberGenerator.new() ## recoil, bullet scatter, shotgun pellets (tests seed it)

# Host-only
var players := {}        ## peer id -> { name, pos, yaw, health: Health, kills, ignore_until, last_shot, weapon, owned }
var _pending_shots: Array = []
var _next_zombie := 1
var _snapshot_timer := 0.0
var _now := 0.0
# Client-only
var _dead_zombies := {}  ## ids we've already turned into ragdolls (ignore late snapshots)

var _send_timer := 0.0


func _ready() -> void:
	name = "Game"
	Controls.setup()
	hooks = GameHooks.new()
	hooks.name = "Hooks"
	hooks.game = self
	add_child(hooks)
	director = HordeDirector.new(self)
	gore = Gore.new()
	add_child(gore)
	hud = Hud.new()
	hud.leave_pressed.connect(func(): leave_requested.emit())
	add_child(hud)
	shot_player = AudioStreamPlayer.new()
	shot_player.stream = Sfx.gunshot()
	shot_player.max_polyphony = 6
	shot_player.volume_db = -6
	add_child(shot_player)


# --- Session start ------------------------------------------------------------

func start_host(player_name_: String) -> void:
	is_host = true
	my_id = 1
	_build_world()
	map.roll_weapons(rng)
	_add_player(1, player_name_)
	if not Net.peer_left.is_connected(_on_peer_left):
		Net.peer_left.connect(_on_peer_left)


func start_client(player_name_: String) -> void:
	is_host = false
	my_id = multiplayer.get_unique_id()
	request_join.rpc_id(1, player_name_)


func _build_world() -> void:
	map = GameMap.create(map_name)
	map.mission = mission
	gore.ground = map.ground_y
	world = map.root
	add_child(world)
	door = map.door
	lootbox = map.lootbox
	for it: Interactable in map.interactables:
		interactables[it.iid] = it
		it.state_changed.connect(_on_interactable_changed)
	if door != null:
		door.smashed.connect(_on_door_smashed)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("0b0d10")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("7f8fa6")
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# The background stays black, but shiny things (guns, wet blood) reflect a dim night sky.
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("141c2b")
	sky_mat.sky_horizon_color = Color("5a6680")
	sky_mat.ground_horizon_color = Color("3a4252")
	sky_mat.ground_bottom_color = Color("0b0d10")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.fog_enabled = true
	env.fog_light_color = Color("0b0d10")
	env.fog_density = 0.035
	if map.outdoor: # see the night sky, and far enough to make out the building
		env.background_mode = Environment.BG_SKY
		env.ambient_light_energy = 0.6
		env.fog_light_color = Color("151b28")
		env.fog_density = 0.011
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var moon := DirectionalLight3D.new()
	moon.light_color = Color("aabbdd")
	moon.light_energy = 0.9 if map.outdoor else 0.5
	moon.shadow_enabled = false # lamps cast the shadows; a sun shadow would redraw the horde 4 more times
	moon.rotation = Vector3(deg_to_rad(-60), deg_to_rad(35), 0)
	add_child(moon)

	local_player = LocalPlayer.new()
	local_player.name = "LocalPlayer"
	local_player.bot = bot
	local_player.set_loadout(_starting_weapons())
	add_child(local_player)
	local_player.teleport(map.player_spawn())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- RPCs: client -> host -------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func request_join(player_name_: String) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	var states := {}
	for iid: int in interactables:
		states[iid] = (interactables[iid] as Interactable).get_state()
	welcome.rpc_id(id, map_name, mission, states)
	_add_player(id, player_name_)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func client_state(pos: Vector3, yaw: float) -> void:
	if not is_host:
		return
	var p = players.get(multiplayer.get_remote_sender_id())
	if p == null or _now < p.ignore_until:
		return
	p.pos = pos
	p.yaw = yaw


@rpc("any_peer", "call_remote", "reliable")
func client_shoot(origin: Vector3, dir: Vector3, weapon: int) -> void:
	if is_host:
		_queue_shot(multiplayer.get_remote_sender_id(), origin, dir, weapon)


@rpc("any_peer", "call_remote", "reliable")
func client_interact(iid: int) -> void:
	if is_host:
		host_interact(multiplayer.get_remote_sender_id(), iid)


# --- RPCs: host -> clients ------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func welcome(map_name_: String, mission_: String, interactable_states: Dictionary) -> void:
	if not GameMap.NAMES.has(map_name_):
		return
	map_name = map_name_
	mission = mission_
	_build_world()
	for iid: int in interactable_states:
		if interactables.has(iid):
			(interactables[iid] as Interactable).apply_state(interactable_states[iid])
	print("[client %d] joined host" % my_id)


@rpc("authority", "call_remote", "reliable")
func respawn_at(pos: Vector3, reason: String) -> void:
	if local_player:
		local_player.teleport(pos)
	if reason == "died":
		hud.toast("YOU DIED", Color("ff4444"))


@rpc("authority", "call_remote", "unreliable_ordered")
func snapshot(players_data: Array, zombie_bytes: PackedByteArray) -> void:
	_apply_snapshot(players_data, ZombieWire.unpack(zombie_bytes))


## You picked up a gun: it's yours now, loaded, and in your hands.
@rpc("authority", "call_remote", "reliable")
func got_weapon(weapon: int) -> void:
	if local_player and Weapons.valid(weapon):
		local_player.receive_weapon(weapon)


@rpc("authority", "call_remote", "reliable")
func hit_confirm(_killed: bool) -> void:
	hud.hit_marker()


@rpc("authority", "call_remote", "reliable")
func zombie_fx(zid: int, kind: int, part: int, pos: Vector3, dir: Vector3) -> void:
	_apply_fx(zid, kind, part, pos, dir)


@rpc("authority", "call_remote", "reliable")
func interact_state(iid: int, state: Dictionary) -> void:
	if interactables.has(iid):
		(interactables[iid] as Interactable).apply_state(state)


@rpc("authority", "call_local", "reliable")
func feed(text: String) -> void:
	hud.push_feed(text)
	print("[feed] ", text)


@rpc("authority", "call_local", "reliable")
func announce(text: String) -> void:
	hud.toast(text, Color("ffcc44"))
	print("[announce] ", text)


## Call a host->client RPC on one peer, or run it directly if that peer is us (the host).
func _send_to(id: int, method: StringName, args: Array) -> void:
	if id == my_id:
		callv(method, args)
	else:
		callv("rpc_id", [id, method] + args)


# --- Host: players --------------------------------------------------------------

func player_name(id: int) -> String:
	return players[id].name if players.has(id) else "Someone"


func _add_player(id: int, player_name_: String) -> void:
	var n := player_name_.strip_edges().substr(0, 20)
	var health := Health.new()
	players[id] = { "name": n if n != "" else "Survivor", "pos": map.player_spawn(), "yaw": 0.0,
		"health": health, "kills": 0, "ignore_until": 0.0, "last_shot": -100.0,
		"weapon": Weapons.DEFAULT if map.all_weapons else Weapons.P19, "owned": _starting_weapons() }
	health.low.connect(func(): hooks.on_low_hp(id))
	health.died.connect(func(): hooks.on_player_died(id))
	respawn_player(id, "spawn")
	hooks.on_player_joined(id)


func _on_peer_left(id: int) -> void:
	if players.has(id):
		feed.rpc("%s left" % players[id].name)
		players.erase(id)


func respawn_player(id: int, reason: String) -> void:
	if not players.has(id):
		return
	var p: Dictionary = players[id]
	p.pos = map.player_spawn_point()
	(p.health as Health).reset()
	p.ignore_until = _now + 0.3 # drop in-flight positions from before the teleport
	_send_to(id, &"respawn_at", [p.pos, reason])


## The guns a player has when they arrive: all of them on test maps, just the pistol otherwise.
func _starting_weapons() -> Dictionary:
	var owned := { Weapons.P19: true }
	if map.all_weapons:
		for id in Weapons.COUNT:
			owned[id] = true
	return owned


## Hand a player a gun (from a pickup, or any hook that wants to reward one).
func give_weapon(id: int, weapon: int) -> void:
	if players.has(id) and Weapons.valid(weapon):
		players[id].owned[weapon] = true
		_send_to(id, &"got_weapon", [weapon])


func damage_player(id: int, amount: int, by: Zombie = null) -> void:
	if not players.has(id):
		return
	hooks.on_player_damaged(id, amount, by)
	(players[id].health as Health).damage(amount)


func heal_player(id: int, amount: int) -> void:
	if players.has(id):
		(players[id].health as Health).heal(amount)


## Id of the closest living player, or 0 if nobody is in range.
func nearest_player(from: Vector3) -> int:
	var best := 0
	var best_d := Config.ZOMBIE_AGGRO_RANGE
	for id: int in players:
		var pos: Vector3 = players[id].pos
		var d := Vector2(pos.x - from.x, pos.z - from.z).length()
		if d < best_d:
			best_d = d
			best = id
	return best


# --- Host: interactions -----------------------------------------------------------

## A player right-clicked interactable `iid`. Returns false if it was out of reach or unknown.
func host_interact(player_id: int, iid: int) -> bool:
	if not players.has(player_id) or not interactables.has(iid):
		return false
	var target: Interactable = interactables[iid]
	var pos: Vector3 = players[player_id].pos
	if pos.distance_to(target.global_position) > Config.INTERACT_RANGE + 1.5:
		return false
	hooks.on_right_click(player_id, target)
	return true


func _on_interactable_changed(iid: int, state: Dictionary) -> void:
	if is_host:
		interact_state.rpc(iid, state)


func _on_door_smashed(d: Door) -> void:
	# Runs on every peer: the panel flies off its hinges.
	var xf := d.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, Door.HEIGHT / 2.0, 0))
	gore.gib_box(Vector3(Door.THICK, Door.HEIGHT, Door.WIDTH), xf, Color("6a4a2c"), Vector3(-6, 2, randf_range(-1, 1)))
	if is_host:
		hooks.on_door_broken(d)


# --- Host: zombies ----------------------------------------------------------------

## Returns the new zombie, or null if the cap is reached.
func spawn_zombie(type: int, pos: Vector3) -> Zombie:
	if zombies.size() >= Config.ZOMBIE_MAX:
		return null
	var z := Zombie.create(_next_zombie, type, true, pos)
	_next_zombie += 1
	zombies[z.zid] = z
	add_child(z)
	return z


func zombie_attack_lands(z: Zombie, target_id: int) -> void:
	if not players.has(target_id):
		return
	var pos: Vector3 = players[target_id].pos
	if Vector2(pos.x - z.global_position.x, pos.z - z.global_position.z).length() < Config.ZOMBIE_ATTACK_RANGE + 0.6:
		damage_player(target_id, z.attack_damage(), z)


func zombie_bashes_door(_z: Zombie, d: Door) -> void:
	d.take_hit(Config.DOOR_BASH_DAMAGE)


func zombie_leap_lands(z: Zombie) -> void:
	hooks.on_zombie_leap_landed(z)
	for id: int in players:
		var pos: Vector3 = players[id].pos
		if pos.distance_to(z.global_position) < Config.LEAP_HIT_RADIUS:
			damage_player(id, Config.LEAP_DAMAGE, z)


func _queue_shot(shooter: int, origin: Vector3, dir: Vector3, weapon: int = Weapons.DEFAULT) -> void:
	var p = players.get(shooter)
	if p == null or not Weapons.valid(weapon) or not p.owned.has(weapon):
		return
	var interval: float = Weapons.def(weapon).interval
	if _now - p.last_shot < interval * 0.8:
		return # rate limit: nobody fires faster than their gun can
	p.last_shot = _now
	p.weapon = weapon
	_pending_shots.append([shooter, origin, dir, weapon])


## One trigger pull of `weapon`: a single bullet, or a cloud of pellets for shotguns.
func resolve_shot(shooter: int, origin: Vector3, dir: Vector3, weapon: int = Weapons.DEFAULT) -> void:
	var d := Weapons.def(weapon)
	var pellets: int = d.pellets
	var cone: float = d.pellet_spread
	for i in pellets:
		_trace_bullet(shooter, origin, Weapons.scatter(dir, cone, rng), d)


## Trace a bullet and apply it. Body-part hitboxes are Area3Ds; walls and closed doors block.
func _trace_bullet(shooter: int, origin: Vector3, dir: Vector3, d: Dictionary) -> void:
	var space := get_viewport().get_world_3d().direct_space_state
	var reach: float = d.range
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach,
		Config.LAYER_WORLD | Config.LAYER_HITBOX)
	q.collide_with_areas = true
	var hit := space.intersect_ray(q)
	if hit.is_empty():
		return
	var collider: Object = hit.collider
	if collider is Area3D and collider.has_meta("zombie"):
		var z: Zombie = collider.get_meta("zombie")
		if is_instance_valid(z) and zombies.has(z.zid):
			hit_zombie(shooter, z, collider.get_meta("part"), hit.position, dir, d.damage)


## A bullet from `shooter` hit zombie `z` in `part`. Applies damage, fires hooks, and tells
## every peer what gore to show.
func hit_zombie(shooter: int, z: Zombie, part: int, pos: Vector3, dir: Vector3,
		damage: int = Config.WEAPON_DAMAGE) -> void:
	var result := z.take_hit(part, damage)
	hooks.on_zombie_hit(z, part, damage, shooter)
	_broadcast_fx(z.zid, Fx.HIT, part, pos, dir)
	var severed: int = result.severed
	if severed >= 0:
		hooks.on_limb_severed(z, severed, shooter)
		_broadcast_fx(z.zid, Fx.SEVER, severed, pos, dir)
	if result.killed:
		hooks.on_zombie_killed(z, shooter, result.headshot)
		if players.has(shooter):
			players[shooter].kills += 1
		_broadcast_fx(z.zid, Fx.DIE, part, pos, dir)
	if players.has(shooter):
		_send_to(shooter, &"hit_confirm", [result.killed])


func _broadcast_fx(zid: int, kind: int, part: int, pos: Vector3, dir: Vector3) -> void:
	zombie_fx.rpc(zid, kind, part, pos, dir)
	_apply_fx(zid, kind, part, pos, dir)


# --- Every peer: gore -------------------------------------------------------------

func _apply_fx(zid: int, kind: int, part: int, pos: Vector3, dir: Vector3) -> void:
	var z: Zombie = zombies.get(zid)
	if z == null:
		return
	var rig := z.rig
	var local_dir := z.global_basis.inverse() * dir
	match kind:
		Fx.HIT:
			gore.burst(pos, dir + Vector3(0, 0.3, 0), 16, 5.0)   # exit spray
			gore.burst(pos, -dir + Vector3(0, 0.5, 0), 6, 2.5)   # splash back
			rig.hit_react(local_dir, 1.3 if part == Humanoid.Part.HEAD else 0.8)
		Fx.SEVER:
			var root := rig.part_root(part)
			var wound := root.global_position
			gore.gibs_from_segments(rig.sever(part), dir * 4.0 + z.est_velocity)
			gore.burst(wound, dir + Vector3.UP, 45, 6.5)
			var out := Vector3.DOWN
			if part == Humanoid.Part.ARM_L:
				out = Vector3(-1, 0.3, 0)
			elif part == Humanoid.Part.ARM_R:
				out = Vector3(1, 0.3, 0)
			gore.spurt(root.get_parent(), root.position, out)
			rig.hit_react(local_dir, 1.5)
		Fx.DIE:
			if part == Humanoid.Part.HEAD and not rig.is_severed(Humanoid.Part.HEAD):
				var head_pos := rig.neck.global_position + Vector3(0, 0.15, 0)
				Humanoid.discard(rig.sever(Humanoid.Part.HEAD)) # the head just pops
				gore.chunks(head_pos, dir, 12)
				gore.burst(head_pos, Vector3.UP, 70, 7.5)
				gore.burst(head_pos, dir, 40, 9.0)
			else:
				gore.burst(pos, dir + Vector3(0, 0.4, 0), 50, 7.0)
			gore.ragdoll(rig.take_all(), z.est_velocity, dir * 4.5 + Vector3(0, 1.5, 0), part)
			zombies.erase(zid)
			_dead_zombies[zid] = true
			z.queue_free()


# --- Host: main loop --------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if not is_host or local_player == null:
		return
	_now += delta
	players[1].pos = local_player.global_position
	players[1].yaw = local_player.yaw

	director.step(delta)
	zombie_list.assign(zombies.values())
	for z in zombie_list:
		z.host_step(delta, self)
	for shot in _pending_shots:
		resolve_shot(shot[0], shot[1], shot[2], shot[3])
	_pending_shots.clear()

	_snapshot_timer -= delta
	if _snapshot_timer <= 0.0:
		_snapshot_timer += 1.0 / Config.TICK_RATE
		var pd := []
		for id: int in players:
			var p: Dictionary = players[id]
			pd.append([id, p.name, p.pos, p.yaw, (p.health as Health).hp, p.kills, p.weapon])
		var zd := []
		for z: Zombie in zombies.values():
			zd.append({ "zid": z.zid, "pos": z.global_position, "yaw": z.rotation.y, "state": z.state,
				"type": z.type, "mask": z.rig.severed_mask })
		snapshot.rpc(pd, ZombieWire.pack(zd))
		_apply_snapshot(pd, zd)


# --- Every peer -------------------------------------------------------------------

func _apply_snapshot(players_data: Array, zombies_data: Array) -> void:
	var seen := {}
	for e: Array in players_data:
		var id: int = e[0]
		if id == my_id:
			hud.set_hp(e[4])
			hud.set_info(players_data.size(), zombies_data.size(), e[5])
			continue
		seen[id] = true
		if not remotes.has(id):
			var r := RemotePlayer.create(id, e[1])
			remotes[id] = r
			add_child(r)
		(remotes[id] as RemotePlayer).buffer.push(e[2], e[3])
		(remotes[id] as RemotePlayer).set_weapon(e[6])
	for id: int in remotes.keys():
		if not seen.has(id):
			(remotes[id] as Node).queue_free()
			remotes.erase(id)

	if is_host:
		return # the host's zombies are the real ones
	var zseen := {}
	for e: Dictionary in zombies_data:
		var zid: int = e.zid
		if _dead_zombies.has(zid):
			continue
		zseen[zid] = true
		var z: Zombie = zombies.get(zid)
		if z == null:
			z = Zombie.create(zid, e.type, false, e.pos, e.mask)
			zombies[zid] = z
			add_child(z)
		z.buffer.push(e.pos, e.yaw)
		z.state = e.state
	for zid: int in zombies.keys():
		if not zseen.has(zid):
			(zombies[zid] as Node).queue_free()
			zombies.erase(zid)


func _process(delta: float) -> void:
	if local_player == null:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_update_looked_at()
	hud.set_prompt(looked_at.prompt() if looked_at else "")
	if captured and Input.is_action_just_pressed("interact") and right_click_is_use(looked_at):
		interact_with(looked_at)
		local_player.aim_blocked = true
	elif not Input.is_action_pressed("interact"):
		local_player.aim_blocked = false

	if bot:
		_bot_aim()
	_update_weapon()

	if not is_host:
		_send_timer -= delta
		if _send_timer <= 0.0:
			_send_timer = 1.0 / 30.0
			client_state.rpc_id(1, local_player.global_position, local_player.yaw)


## Right mouse uses what you're looking at; with nothing in reach it aims instead.
func right_click_is_use(target: Interactable) -> bool:
	return target != null


## Trigger, magazine and what the HUD shows for the gun in hand.
func _update_weapon() -> void:
	var lp := local_player
	var ws := lp.weapons
	var d := ws.def()
	var auto: bool = d.auto
	if lp.firing and (auto or bot or lp.fire_buffer > 0.0):
		if ws.rounds() == 0:
			ws.start_reload()
		elif ws.try_fire():
			lp.fire_buffer = 0.0
			_fire(d)
	var scoped: bool = d.scoped
	var through_scope := scoped and lp.view.aim > 0.9
	lp.view.visible = not through_scope and not lp.hide_view
	hud.set_scope(through_scope)
	hud.set_aiming(lp.view.aim > 0.5)
	hud.set_weapon(d.name, ws.rounds(), d.mag, ws.is_reloading())


func _fire(d: Dictionary) -> void:
	var lp := local_player
	lp.view.fire()
	shot_player.pitch_scale = d.pitch * rng.randf_range(0.96, 1.04)
	shot_player.volume_db = d.volume
	shot_player.play()
	var cam := lp.camera
	var origin := cam.global_position
	var cone := 0.0 if bot else Weapons.spread(d, lp.aiming, lp.move_speed / Config.SPRINT_SPEED)
	var dir := Weapons.scatter(-cam.global_basis.z, cone, rng)
	if is_host:
		_queue_shot(1, origin, dir, lp.weapons.current)
	else:
		client_shoot.rpc_id(1, origin, dir, lp.weapons.current)
	if not bot:
		lp.kick_view(Weapons.kick(d, rng, lp.aiming))


## What the local player is pointing at within reach (for the prompt and right-click).
func _update_looked_at() -> void:
	looked_at = null
	var cam := local_player.camera
	var space := get_viewport().get_world_3d().direct_space_state
	var from := cam.global_position
	var q := PhysicsRayQueryParameters3D.create(from, from - cam.global_basis.z * Config.INTERACT_RANGE,
		Config.LAYER_WORLD | Config.LAYER_INTERACT)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		looked_at = Interactable.from_collider(hit.collider)


## The local player right-clicks `target`.
func interact_with(target: Interactable) -> void:
	if is_host:
		host_interact(my_id, target.iid)
	else:
		client_interact.rpc_id(1, target.iid)


## Test bot: aim at the nearest zombie's chest and hold the trigger.
func _bot_aim() -> void:
	var me := local_player.global_position
	var best: Zombie = null
	var best_d := 25.0
	for z: Zombie in zombies.values():
		var d := me.distance_to(z.global_position)
		if d < best_d and map.is_direct(me, z.global_position):
			best_d = d
			best = z
	local_player.firing = best != null and bot_fires
	if best:
		var eye := me + Vector3(0, Config.EYE_HEIGHT, 0)
		var aim := best.rig.spine.global_position + Vector3(0, 0.3, 0)
		match bot_aim:
			"head": aim = best.rig.neck.global_position + Vector3(0, 0.15, 0)
			"legs": aim = (best.rig.knee_l if not best.rig.is_severed(Humanoid.Part.LEG_L) else best.rig.knee_r).global_position
			"arms": aim = (best.rig.elbow_l if not best.rig.is_severed(Humanoid.Part.ARM_L) else best.rig.elbow_r).global_position
		var to := aim - eye
		local_player.yaw = atan2(-to.x, -to.z)
		local_player.pitch = atan2(to.y, Vector2(to.x, to.z).length())
