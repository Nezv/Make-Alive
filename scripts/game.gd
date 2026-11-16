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

enum GoreFx { HIT, SEVER, DIE }

var is_host := false
var my_id := 1
var bot := false
var bot_fires := true
var bot_aim := "chest" ## chest | head | legs | arms
var brain: Bot             ## what plays for the local player when `bot` is on (scripts/bot.gd)
var map_name := "corridor" ## set before start_host; clients get it in `welcome`
var mission := ""          ## a city POI id ("mirante"...) or "" for free play; clients get it in `welcome`
var limited_ammo := false  ## set before start_host: reloads take from a reserve even on a test map (--limited-ammo, tests)
var map: GameMap
var world: Node3D
var door: Door
var lootbox: Lootbox
var interactables := {}  ## iid -> Interactable
var local_player: LocalPlayer
var hud: Hud
var gore: Gore
var fx: Fx
var noise_rings: NoiseRings = null ## --noise: rings where noise happened (host, debug)
var hooks: GameHooks
var director: HordeDirector
var remotes := {}        ## peer id -> RemotePlayer
var names := {}          ## peer id -> player name, on every peer (sent when someone joins or leaves)
var zombies := {}        ## zombie id -> Zombie
var zombie_list: Array[Zombie] = [] ## same zombies as an array, refreshed each host tick
var looked_at: Interactable = null
var rng := RandomNumberGenerator.new() ## recoil, bullet scatter, shotgun pellets (tests seed it)

# Host-only
var players := {}        ## peer id -> { slot, name, pos, yaw, health: Health, kills, ignore_until, last_shot, weapon, loadout: Loadout, swap_rounds, reserve }
var _pending_shots: Array = []
var _next_zombie := 1
var _step_t := 0.0       ## seconds since players were last checked for sprinting footsteps
var _next_drop := 0      ## how many things have been dropped (their iids count up from Config.DROP_IID_BASE)
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
	fx = Fx.new()
	add_child(fx)
	Settings.changed.connect(_on_setting_changed)
	hud = Hud.new()
	hud.leave_pressed.connect(func(): leave_requested.emit())
	add_child(hud)


# --- Session start ------------------------------------------------------------

func start_host(player_name_: String) -> void:
	is_host = true
	my_id = 1
	_build_world()
	map.roll_weapons(rng)
	_add_player(1, player_name_)
	if mission != "":
		hooks.on_mission_started(mission)
	if not Net.peer_left.is_connected(_on_peer_left):
		Net.peer_left.connect(_on_peer_left)


func start_client(player_name_: String) -> void:
	is_host = false
	my_id = multiplayer.get_unique_id()
	request_join.rpc_id(1, player_name_)


func _build_world() -> void:
	map = GameMap.create(map_name)
	map.mission = mission
	if limited_ammo:
		map.infinite_ammo = false
	gore.ground = map.ground_y
	fx.ground = map.ground_y
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
	local_player.set_loadout(_starting_loadout())
	local_player.landed.connect(_on_local_landed)
	if not map.infinite_ammo:
		local_player.weapons.limit(map.starting_ammo()) # the same data on every peer, so the host's count agrees
	add_child(local_player)
	local_player.teleport(map.player_spawn())
	if bot:
		brain = Bot.new(self)
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
	welcome.rpc_id(id, map_name, mission, states, { "infinite_ammo": map.infinite_ammo })
	_add_player(id, player_name_)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func client_state(pos: Vector3, yaw: float, action: int = 0) -> void:
	if not is_host:
		return
	var p = players.get(multiplayer.get_remote_sender_id())
	if p == null or _now < p.ignore_until:
		return
	p.pos = pos
	p.yaw = yaw
	p.action = action


## The sender came down after falling `height` metres.
@rpc("any_peer", "call_remote", "reliable")
func client_fell(height: float) -> void:
	if is_host:
		player_fell(multiplayer.get_remote_sender_id(), height)


@rpc("any_peer", "call_remote", "reliable")
func client_shoot(origin: Vector3, dir: Vector3, weapon: int) -> void:
	if is_host:
		_queue_shot(multiplayer.get_remote_sender_id(), origin, dir, weapon)


## A reload took `rounds` of a calibre out of the sender's reserve. Sent when it happens, not in snapshots.
@rpc("any_peer", "call_remote", "reliable")
func client_ammo_used(type: int, rounds: int) -> void:
	if is_host:
		_ammo_used(multiplayer.get_remote_sender_id(), type, rounds)


@rpc("any_peer", "call_remote", "reliable")
func client_interact(iid: int, weapon: int = -1, rounds: int = -1) -> void:
	if is_host:
		host_interact(multiplayer.get_remote_sender_id(), iid, weapon, rounds)


# --- RPCs: host -> clients ------------------------------------------------------

@rpc("authority", "call_remote", "reliable")
func welcome(map_name_: String, mission_: String, interactable_states: Dictionary, rules: Dictionary = {}) -> void:
	if not GameMap.NAMES.has(map_name_):
		return
	map_name = map_name_
	mission = mission_
	limited_ammo = not rules.get("infinite_ammo", true)
	_build_world()
	for iid: int in interactable_states:
		_apply_interact_state(iid, interactable_states[iid])
	print("[client %d] joined host" % my_id)


@rpc("authority", "call_remote", "reliable")
func respawn_at(pos: Vector3, reason: String) -> void:
	if local_player:
		local_player.teleport(pos)
	if reason == "died":
		hud.toast("YOU DIED", Color("ff4444"))


@rpc("authority", "call_remote", "unreliable_ordered")
func snapshot(player_bytes: PackedByteArray, zombie_bytes: PackedByteArray) -> void:
	_apply_snapshot(PlayerWire.unpack(player_bytes), ZombieWire.unpack(zombie_bytes))


## Who is playing. Names change when someone joins or leaves, so they are not in the snapshots.
@rpc("authority", "call_remote", "reliable")
func player_names(names_: Dictionary) -> void:
	names = names_
	for id: int in remotes:
		(remotes[id] as RemotePlayer).tag.text = names.get(id, "Survivor")


## You picked up a gun: it's yours now, with `rounds` in it (-1 = full), and in your hands.
## `dropped` is the gun that left your slots to make room (-1 = none).
@rpc("authority", "call_remote", "reliable")
func got_weapon(weapon: int, rounds: int = -1, dropped: int = -1) -> void:
	if local_player and Weapons.valid(weapon):
		local_player.receive_weapon(weapon, rounds, dropped)


## The host put rounds in your reserve.
@rpc("authority", "call_remote", "reliable")
func got_ammo(type: int, rounds: int) -> void:
	if local_player:
		local_player.weapons.add_reserve(type, rounds)
		hud.gain("+%d  %s" % [rounds, Weapons.ammo_name(type)])


@rpc("authority", "call_remote", "reliable")
func hit_confirm(_killed: bool) -> void:
	hud.hit_marker()


@rpc("authority", "call_remote", "reliable")
func zombie_fx(zid: int, kind: int, part: int, pos: Vector3, dir: Vector3) -> void:
	_apply_fx(zid, kind, part, pos, dir)


## An effect from Fx.Kind at a place: impacts, flashes, explosions. Its own channel, so a burst of
## them never holds up doors and gore.
@rpc("authority", "call_remote", "reliable", 2)
func world_fx(kind: int, pos: Vector3, dir: Vector3, arg: float) -> void:
	fx.play(kind, pos, dir, arg)


@rpc("authority", "call_remote", "reliable")
func interact_state(iid: int, state: Dictionary) -> void:
	_apply_interact_state(iid, state)


## A peer learns the state of interactable `iid`. One it has never seen is something dropped
## during the match (its state says where it lies), so it is built here.
func _apply_interact_state(iid: int, state: Dictionary) -> void:
	if interactables.has(iid):
		(interactables[iid] as Interactable).apply_state(state)
	elif state.get("drop", false) and state.get("by", -1) < 0 and state.get("weapon", 0) >= 0:
		_add_drop(iid, state) # (not one that is already taken)
	_after_state(iid)


## An interactable just changed on this peer: what the match itself does about it.
func _after_state(iid: int) -> void:
	var gun := interactables.get(iid) as WeaponPickup
	if gun != null and gun.dynamic and gun.weapon < 0: # a dropped gun was taken: nothing is left of it
		interactables.erase(iid)
		gun.queue_free()
	var box := interactables.get(iid) as AmmoBox
	if box == null or box.taken_by < 0:
		return
	# Emptied: it hops to whoever took it (or just shrinks away if nobody did).
	box.hop_to(_player_pos(box.taken_by) + Vector3(0, Config.PICKUP_HOP_HEIGHT, 0) if box.taken_by > 0 else box.global_position)
	if box.dynamic:
		interactables.erase(iid) # it frees itself after the hop


## Where a player is, as this peer sees them.
func _player_pos(id: int) -> Vector3:
	if id == my_id and local_player != null:
		return local_player.global_position
	if remotes.has(id):
		return (remotes[id] as Node3D).global_position
	if players.has(id):
		return players[id].pos
	return Vector3.ZERO


## Build something that was dropped during the match from its state: a gun or an ammo carton.
func _add_drop(iid: int, state: Dictionary) -> Interactable:
	var it: Interactable
	if state.has("weapon"):
		var gun := WeaponPickup.new()
		gun.kind = "drop"
		gun.dynamic = true
		gun.rotation.y = state.get("yaw", 0.0)
		gun.stand = state.get("at", Vector3.ZERO)
		it = gun
	else:
		var box := AmmoBox.new()
		box.dynamic = true
		box.rotation.y = fposmod(iid * 2.399963, TAU) # each lies at its own angle, the same on every peer
		it = box
	it.iid = iid
	it.position = state.get("at", Vector3.ZERO)
	world.add_child(it)
	it.apply_state(state)
	interactables[iid] = it
	it.state_changed.connect(_on_interactable_changed)
	return it


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
	elif multiplayer.get_peers().has(id): # someone who has just left gets nothing
		callv("rpc_id", [id, method] + args)


# --- Host: players --------------------------------------------------------------

func player_name(id: int) -> String:
	return players[id].name if players.has(id) else "Someone"


func _add_player(id: int, player_name_: String) -> void:
	var n := player_name_.strip_edges().substr(0, 20)
	var health := Health.new()
	var taken := {}
	for other: Dictionary in players.values():
		taken[other.slot] = true
	var slot := 0 # the lowest free slot: it picks this player's own spawn point
	while taken.has(slot):
		slot += 1
	players[id] = { "slot": slot, "name": n if n != "" else "Survivor", "pos": map.player_spawn(), "yaw": 0.0,
		"health": health, "kills": 0, "ignore_until": 0.0, "last_shot": -100.0,
		"weapon": _starting_loadout().guns()[0] if not _starting_loadout().everything else Weapons.DEFAULT,
		"loadout": _starting_loadout(), "swap_rounds": -1, "action": 0, "step_pos": map.player_spawn(),
		"reserve": map.starting_ammo() }
	health.low.connect(func(): hooks.on_low_hp(id))
	health.died.connect(func(): hooks.on_player_died(id))
	respawn_player(id, "spawn")
	_send_names()
	hooks.on_player_joined(id)


func _on_peer_left(id: int) -> void:
	if players.has(id):
		feed.rpc("%s left" % players[id].name)
		players.erase(id)
		_send_names()


func _send_names() -> void:
	var all := {}
	for id: int in players:
		all[id] = players[id].name
	player_names.rpc(all)
	player_names(all)


func respawn_player(id: int, reason: String) -> void:
	if not players.has(id):
		return
	var p: Dictionary = players[id]
	p.pos = map.player_spawn_point(p.slot)
	p.step_pos = p.pos
	(p.health as Health).reset()
	p.ignore_until = _now + 0.3 # drop in-flight positions from before the teleport
	_send_to(id, &"respawn_at", [p.pos, reason])


## What a player carries when they arrive: every gun on a test map or in free play, just the
## pistol on a mission.
func _starting_loadout() -> Loadout:
	return Loadout.all() if map.all_weapons and mission == "" else Loadout.pistol()


## Hand a player a gun (from a pickup, or any hook that wants to reward one), with `rounds` in its
## magazine (-1 = full). With their slots full, the gun it replaces drops at their feet.
func give_weapon(id: int, weapon: int, rounds: int = -1) -> void:
	if not players.has(id) or not Weapons.valid(weapon):
		return
	var p: Dictionary = players[id]
	var carried: Loadout = p.loadout
	var dropped := carried.take(weapon, p.weapon)
	if dropped >= 0:
		var mag: int = Weapons.def(dropped).mag
		var left: int = clampi(p.swap_rounds, 0, mag) if p.swap_rounds >= 0 else mag
		var pickup := drop_weapon(p.pos, p.yaw, dropped, left)
		hooks.on_weapon_dropped(id, dropped, pickup)
	p.weapon = weapon
	p.swap_rounds = -1
	_send_to(id, &"got_weapon", [weapon, rounds, dropped])


## Host: lay a gun on the ground at `at` with `rounds` in its magazine. Every peer gets it, late joiners too.
func drop_weapon(at: Vector3, yaw: float, weapon: int, rounds: int) -> WeaponPickup:
	if not is_host or not Weapons.valid(weapon):
		return null
	var iid := Config.DROP_IID_BASE + _next_drop
	_next_drop += 1
	var pickup: WeaponPickup = _add_drop(iid, { "weapon": weapon, "rounds": rounds, "yaw": yaw,
		"at": Vector3(at.x, map.ground_y(at), at.z) })
	interact_state.rpc(iid, pickup.get_state())
	return pickup


## Rounds of a calibre (Weapons.Ammo) a player has outside their magazines; -1 where ammo is infinite.
func ammo_of(id: int, type: int) -> int:
	if map.infinite_ammo:
		return -1
	if not players.has(id):
		return 0
	var have: int = players[id].reserve.get(type, 0)
	return have


## Put rounds in a player's reserve (a pickup, a crate, a hook's reward). Returns how many fitted.
func give_ammo(id: int, type: int, rounds: int) -> int:
	if map.infinite_ammo or not players.has(id) or type < 0 or type >= Weapons.Ammo.COUNT:
		return 0
	var have := ammo_of(id, type)
	var cap: int = Weapons.AMMO[type].max
	var fits := clampi(rounds, 0, maxi(0, cap - have))
	if fits > 0:
		players[id].reserve[type] = have + fits
		_send_to(id, &"got_ammo", [type, fits])
	return fits


## A player's reload took rounds out of their reserve: keep the host's count in step.
func _ammo_used(id: int, type: int, rounds: int) -> void:
	if not players.has(id) or type < 0 or type >= Weapons.Ammo.COUNT or rounds <= 0:
		return
	var have: int = players[id].reserve.get(type, 0)
	players[id].reserve[type] = maxi(0, have - rounds)


# --- Host: noise ------------------------------------------------------------------

## Something loud happened at `at`: it is heard `loudness` metres away. Zombies in earshot go and
## look at the spot, and the director's heat rises. `by` is the player who caused it (0 = nobody).
## Every loud thing calls this: shots, broken doors, sprinting, and later explosions and alarms.
func make_noise(at: Vector3, loudness: float, by: int = 0) -> void:
	if not is_host or loudness <= 0.0:
		return
	hooks.on_noise(at, loudness, by)
	for z: Zombie in zombies.values():
		if z.global_position.distance_to(at) <= loudness:
			z.hear(at)
	director.add_heat(loudness)
	if noise_rings != null:
		noise_rings.add(at, loudness)


## Debug: draw a ring for every noise from now on (--noise).
func show_noise() -> void:
	if noise_rings == null:
		noise_rings = NoiseRings.new()
		add_child(noise_rings)


## Host, every tick: a player covering ground at a sprint, and not crouched, is heard.
func _footsteps(delta: float) -> void:
	_step_t += delta
	if _step_t < Config.NOISE_STEP_INTERVAL:
		return
	for id: int in players:
		var p: Dictionary = players[id]
		var pos: Vector3 = p.pos
		var from: Vector3 = p.step_pos
		var over_ground := Vector2(pos.x - from.x, pos.z - from.z).length() / _step_t
		p.step_pos = pos
		var crouched: bool = int(p.action) & PlayerWire.ACTION_CROUCH != 0
		# (faster than anyone runs = a respawn or a teleport, not footsteps)
		if over_ground >= Config.NOISE_SPRINT_SPEED and over_ground < Config.SPRINT_SPEED * 2.0 and not crouched:
			make_noise(pos, Config.NOISE_SPRINT, id)
	_step_t = 0.0


## Host: a player landed after falling `height` metres. Above the safe height it costs HP.
func player_fell(id: int, height: float) -> void:
	var hurt := MoveState.fall_damage(clampf(height, 0.0, 200.0))
	if players.has(id) and hurt > 0:
		damage_player(id, hurt)


func _on_local_landed(height: float) -> void:
	if is_host:
		player_fell(my_id, height)
	else:
		client_fell.rpc_id(1, height)


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
## `weapon`: the gun in the player's hands as they clicked (the host otherwise only learns it from shots).
## `rounds`: what is in the magazine of the gun they would drop to take this one (-1 = not said).
func host_interact(player_id: int, iid: int, weapon: int = -1, rounds: int = -1) -> bool:
	if not players.has(player_id) or not interactables.has(iid):
		return false
	if Weapons.valid(weapon) and players[player_id].loadout.has(weapon):
		players[player_id].weapon = weapon
	players[player_id].swap_rounds = rounds
	var target: Interactable = interactables[iid]
	var pos: Vector3 = players[player_id].pos
	if pos.distance_to(target.global_position) > Config.INTERACT_RANGE + 1.5:
		return false
	hooks.on_right_click(player_id, target)
	return true


func _on_interactable_changed(iid: int, state: Dictionary) -> void:
	if is_host:
		interact_state.rpc(iid, state)
		_after_state(iid)


## Host: leave a carton of `rounds` of a calibre on the ground at `at` (what a dead zombie had on it).
func drop_ammo_box(at: Vector3, type: int, rounds: int) -> AmmoBox:
	if not is_host or type < 0 or type >= Weapons.Ammo.COUNT or rounds <= 0:
		return null
	var lying: Array[int] = []
	for iid: int in interactables:
		if iid >= Config.DROP_IID_BASE and interactables[iid] is AmmoBox:
			lying.append(iid)
	if lying.size() >= Config.AMMO_DROPS_MAX: # the oldest one makes room
		lying.sort()
		var oldest: AmmoBox = interactables[lying[0]]
		oldest.take(oldest.rounds, 0)
	var iid := Config.DROP_IID_BASE + _next_drop
	_next_drop += 1
	var box: AmmoBox = _add_drop(iid, { "ammo": type, "rounds": rounds, "by": -1, "at": Vector3(at.x, map.ground_y(at), at.z) })
	interact_state.rpc(iid, box.get_state())
	return box


func _on_door_smashed(d: Door) -> void:
	# Runs on every peer: the panel flies off its hinges.
	var xf := d.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, Door.HEIGHT / 2.0, 0))
	gore.gib_box(Vector3(Door.THICK, Door.HEIGHT, Door.WIDTH), xf, Color("6a4a2c"), Vector3(-6, 2, randf_range(-1, 1)))
	if is_host:
		hooks.on_door_broken(d)
		make_noise(d.global_position, Config.NOISE_DOOR_BREAK)


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
	if p == null or not Weapons.valid(weapon) or not p.loadout.has(weapon):
		return
	var interval: float = Weapons.def(weapon).interval
	if _now - p.last_shot < interval * 0.8:
		return # rate limit: nobody fires faster than their gun can
	p.last_shot = _now
	p.weapon = weapon
	_pending_shots.append([shooter, origin, dir, weapon])
	make_noise(origin, Weapons.loudness(weapon), shooter)


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
	_broadcast_fx(z.zid, GoreFx.HIT, part, pos, dir)
	var severed: int = result.severed
	if severed >= 0:
		hooks.on_limb_severed(z, severed, shooter)
		_broadcast_fx(z.zid, GoreFx.SEVER, severed, pos, dir)
	if result.killed:
		hooks.on_zombie_killed(z, shooter, result.headshot)
		if players.has(shooter):
			players[shooter].kills += 1
		_broadcast_fx(z.zid, GoreFx.DIE, part, pos, dir)
	if players.has(shooter):
		_send_to(shooter, &"hit_confirm", [result.killed])


func _broadcast_fx(zid: int, kind: int, part: int, pos: Vector3, dir: Vector3) -> void:
	zombie_fx.rpc(zid, kind, part, pos, dir)
	_apply_fx(zid, kind, part, pos, dir)


## Host: show effect `kind` (an Fx.Kind) on every peer. `dir` is the surface normal or throw
## direction, `arg` its size. The host says what happened; each peer draws its own particles.
func play_fx(kind: int, pos: Vector3, dir: Vector3, arg := 1.0) -> void:
	world_fx.rpc(kind, pos, dir, arg)
	fx.play(kind, pos, dir, arg)


func _on_setting_changed(key: String) -> void:
	if key == "graphics_tier":
		fx.set_tier(Settings.get_value(key))


# --- Every peer: gore -------------------------------------------------------------

func _apply_fx(zid: int, kind: int, part: int, pos: Vector3, dir: Vector3) -> void:
	var z: Zombie = zombies.get(zid)
	if z == null:
		return
	var rig := z.rig
	var local_dir := z.global_basis.inverse() * dir
	match kind:
		GoreFx.HIT:
			gore.burst(pos, dir + Vector3(0, 0.3, 0), 16, 5.0)   # exit spray
			gore.burst(pos, -dir + Vector3(0, 0.5, 0), 6, 2.5)   # splash back
			rig.hit_react(local_dir, 1.3 if part == Humanoid.Part.HEAD else 0.8)
		GoreFx.SEVER:
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
		GoreFx.DIE:
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
	players[1].action = local_player.action_bits()
	_footsteps(delta)

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
		var snap := build_snapshot()
		snapshot.rpc(PlayerWire.pack(snap[0]), ZombieWire.pack(snap[1]))
		_apply_snapshot(snap[0], snap[1])


## Host: where everyone and everything is right now, as [players, zombies] (see PlayerWire and
## ZombieWire for what each entry holds). Sent Config.TICK_RATE times a second; must fit one packet.
func build_snapshot() -> Array:
	var pd := []
	for id: int in players:
		var p: Dictionary = players[id]
		pd.append({ "id": id, "pos": p.pos, "yaw": p.yaw, "hp": (p.health as Health).hp, "kills": p.kills, "weapon": p.weapon, "action": p.action })
	var zd := []
	for z: Zombie in zombies.values():
		zd.append({ "zid": z.zid, "pos": z.global_position, "yaw": z.rotation.y, "state": z.state,
			"type": z.type, "mask": z.rig.severed_mask })
	return [pd, zd]


# --- Every peer -------------------------------------------------------------------

func _apply_snapshot(players_data: Array, zombies_data: Array) -> void:
	var seen := {}
	for e: Dictionary in players_data:
		var id: int = e.id
		if id == my_id:
			hud.set_hp(e.hp)
			hud.set_info(players_data.size(), zombies_data.size(), e.kills)
			continue
		seen[id] = true
		if not remotes.has(id):
			var r := RemotePlayer.create(id, names.get(id, "Survivor"))
			remotes[id] = r
			add_child(r)
		(remotes[id] as RemotePlayer).buffer.push(e.pos, e.yaw)
		(remotes[id] as RemotePlayer).set_weapon(e.weapon)
		(remotes[id] as RemotePlayer).set_action(e.get("action", 0))
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

	if brain != null:
		brain.step(delta)
	_update_weapon()

	if not is_host:
		_send_timer -= delta
		if _send_timer <= 0.0:
			_send_timer = 1.0 / 30.0
			client_state.rpc_id(1, local_player.global_position, local_player.yaw, local_player.action_bits())


## Right mouse uses what you're looking at; with nothing in reach it aims instead.
func right_click_is_use(target: Interactable) -> bool:
	return target != null


## Trigger, magazine and what the HUD shows for the gun in hand.
func _update_weapon() -> void:
	var lp := local_player
	var ws := lp.weapons
	var d := ws.def()
	var auto: bool = d.auto
	hud.set_stamina(lp.move.stamina_share(), lp.move.winded)
	if lp.firing and (auto or bot or lp.fire_buffer > 0.0) and not lp.move.is_vaulting(): # hands are on the cover
		if ws.rounds() == 0:
			if not ws.start_reload() and ws.is_dry() and lp.fire_buffer > 0.0:
				lp.fire_buffer = 0.0 # one click per pull, and no shot goes to the host
				lp.view.dry_fire()
				Sfx.play_ui("dry_fire", Config.DRY_FIRE_VOLUME)
		elif ws.try_fire():
			lp.fire_buffer = 0.0
			_fire(d)
	var spent := ws.take_spent() # a reload finished: tell the host what it took, once
	for type: int in spent:
		if is_host:
			_ammo_used(my_id, type, spent[type])
		else:
			client_ammo_used.rpc_id(1, type, spent[type])
	var scoped: bool = d.scoped
	var through_scope := scoped and lp.view.aim > 0.9
	lp.view.visible = not through_scope and not lp.hide_view
	hud.set_scope(through_scope)
	hud.set_aiming(lp.view.aim > 0.5)
	hud.set_weapon(d.name, ws.rounds(), ws.is_reloading(), ws.reserve_rounds())


func _fire(d: Dictionary) -> void:
	var lp := local_player
	lp.view.fire()
	Sfx.play_ui("gunshot", d.volume, d.pitch * rng.randf_range(0.96, 1.04))
	var cam := lp.camera
	var origin := cam.global_position
	var cone := 0.0 if bot else Weapons.spread(d, lp.aiming, lp.move_speed / Config.SPRINT_SPEED, lp.move.crouch)
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
	var ws := local_player.weapons
	var rounds := -1 # taking a gun with full slots drops one: say what is left in its magazine
	var gun := target as WeaponPickup
	if gun != null:
		var out := local_player.loadout.would_drop(gun.weapon, ws.current)
		if out >= 0:
			rounds = ws.ammo[out]
	if is_host:
		host_interact(my_id, target.iid, ws.current, rounds)
	else:
		client_interact.rpc_id(1, target.iid, ws.current, rounds)


