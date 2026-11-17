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
signal retry_requested ## the host wants the same match again (main.gd starts it)
signal join_refused(message: String) ## this client's build and the host's do not match (main.gd goes back to the menu with it)

enum GoreFx { HIT, SEVER, DIE }

var is_host := false
var my_id := 1
var bot := false
var bot_fires := true
var bot_aim := "chest" ## chest | head | legs | arms
var brain: Bot             ## what plays for the local player when `bot` is on (scripts/bot.gd)
var map_name := "corridor" ## set before start_host; clients get it in `welcome`
var mission := ""          ## a city POI id ("mirante"...) or "" for free play; clients get it in `welcome`
var difficulty := "normal" ## Difficulty.LEVELS; set before start_host, clients get it in `welcome`
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
var extraction: ExtractionZone = null ## the open way out's look, while its objective is up
var noise_rings: NoiseRings = null ## --noise: rings where noise happened (host, debug)
var hooks: GameHooks
var director: HordeDirector
var score := Score.new() ## what each player did this match (host)
var director_overlay := false ## --director: the pacing as text on the HUD (host)
var final_score_view := {} ## the end screen's numbers as this peer was sent them (Score.summary)
var rules: MissionRules  ## the objective list being played (host runs it; see `mission_view` for what peers know)
## The mission as this peer was last told it (MissionRules.state); the clock is counted along locally.
var mission_view := { "index": -1, "status": MissionRules.Status.IDLE, "reason": "", "id": "", "kind": "", "text": "",
	"left": -1.0, "counting": false, "wave": 0, "has_marker": false, "marker": Vector3.ZERO }
var remotes := {}        ## peer id -> RemotePlayer
var _drips := BleedTrail.new() ## where bleeding players last dropped blood
var pings := {}          ## player id -> { node: the marker, left: seconds }
var tracers: Tracers      ## every bullet's streak (cosmetic, local)
var casings: Casings      ## spent cases on the floor (cosmetic, local)
var whizzes := 0          ## near misses heard (tests)
var _own_shots := 0
var heli: Helicopter = null ## the extraction helicopter, while one is coming, down or leaving
var heli_flight: HeliFlight = null
var heli_t := 0.0        ## seconds into its flight (every peer counts it itself)
var _wash_t := 0.0
var _gunner_t := 0.0
var names := {}          ## peer id -> player name, on every peer (sent when someone joins or leaves)
var zombies := {}        ## zombie id -> Zombie
var zombie_list: Array[Zombie] = [] ## same zombies as an array, refreshed each host tick
var looked_at: Interactable = null
var rng := RandomNumberGenerator.new() ## recoil, bullet scatter, shotgun pellets (tests seed it)

# Host-only
var players := {}        ## peer id -> { slot, name, pos, yaw, health: Health, kills, ignore_until, last_shot, weapon, loadout: Loadout, swap_rounds, reserve, inventory: Inventory, status: PlayerStatus }
var _pending_shots: Array = []
var _next_zombie := 1
var _step_t := 0.0       ## seconds since players were last checked for sprinting footsteps
var _reviving := 0         ## the downed teammate the local player is holding use on
var _snap_tick := 0         ## snapshots sent so far (the far zombies are sent in turn by it)
var _zombie_seen := {}      ## client: zombie id -> when (msec) a snapshot last had it
var _next_drop := 0      ## how many things have been dropped (their iids count up from Config.DROP_IID_BASE)
var _snapshot_timer := 0.0
var _now := 0.0
# Client-only
var _dead_zombies := {}  ## ids we've already turned into ragdolls (ignore late snapshots)

var _send_timer := 0.0


func _ready() -> void:
	name = "Game"
	Controls.setup()
	for path in Characters.model_paths():
		CharacterModel.load_model(path) # now, not as a hitch when the first one spawns
	hooks = GameHooks.new()
	hooks.name = "Hooks"
	hooks.game = self
	add_child(hooks)
	director = HordeDirector.new(self)
	rules = MissionRules.new(self)
	gore = Gore.new()
	add_child(gore)
	tracers = Tracers.new()
	add_child(tracers)
	casings = Casings.new()
	add_child(casings)
	fx = Fx.new()
	add_child(fx)
	Settings.changed.connect(_on_setting_changed)
	hud = Hud.new()
	hud.leave_pressed.connect(func(): leave_requested.emit())
	hud.retry_pressed.connect(func(): retry_requested.emit())
	add_child(hud)


# --- Session start ------------------------------------------------------------

func start_host(player_name_: String) -> void:
	is_host = true
	hud.retry_button.visible = true
	my_id = 1
	_build_world()
	map.roll_weapons(rng)
	_add_player(1, player_name_)
	rules.start(map.objective_defs, map.data.respawn, map.data.respawn_after, map.data.respawn_checkpoint)
	if mission != "":
		hooks.on_mission_started(mission)
	if not Net.peer_left.is_connected(_on_peer_left):
		Net.peer_left.connect(_on_peer_left)


func start_client(player_name_: String) -> void:
	is_host = false
	my_id = multiplayer.get_unique_id()
	request_join.rpc_id(1, player_name_, Config.PROTOCOL_VERSION)


func _build_world() -> void:
	map = GameMap.create(map_name)
	map.mission = mission
	if limited_ammo:
		map.infinite_ammo = false
	gore.ground = map.ground_y
	casings.ground = map.ground_y
	fx.ground = map.ground_y
	world = map.root
	add_child(world)
	door = map.door
	lootbox = map.lootbox
	for it: Interactable in map.interactables:
		interactables[it.iid] = it
		if it is AmmoBox: # less (or more) is found by level
			(it as AmmoBox).setup((it as AmmoBox).ammo, maxi(1, roundi((it as AmmoBox).rounds * mult("ammo"))))
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
	local_player.shoved.connect(_on_local_shove)
	local_player.item_requested.connect(_on_local_item)
	local_player.chat_requested.connect(func():
		local_player.typing = true
		hud.open_chat())
	local_player.ping_requested.connect(ping)
	hud.chat_submitted.connect(say)
	hud.chat_closed.connect(func(): if local_player: local_player.typing = false)
	local_player.use_cancelled.connect(_on_local_use_cancelled)
	if not map.infinite_ammo:
		local_player.weapons.limit(map.starting_ammo()) # the same data on every peer, so the host's count agrees
	add_child(local_player)
	local_player.view.smoke.connect(muzzle_smoke) # (the viewmodel is made when the player enters the tree)
	local_player.view.eject.connect(casings.spawn)
	local_player.teleport(map.player_spawn())
	if bot:
		brain = Bot.new(self)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- RPCs: client -> host -------------------------------------------------------

@rpc("any_peer", "call_remote", "reliable")
func request_join(player_name_: String, version := 0) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	var problem := version_problem(version)
	if problem != "":
		refuse_join.rpc_id(id, problem)
		return
	var states := {}
	for iid: int in interactables:
		states[iid] = (interactables[iid] as Interactable).get_state()
	welcome.rpc_id(id, map_name, mission, states, welcome_rules())
	_add_player(id, player_name_)


## What a joining player must know about this match beyond the map: sent in `welcome`.
func welcome_rules() -> Dictionary:
	var r := { "infinite_ammo": map.infinite_ammo, "mission": rules.state(), "difficulty": difficulty, "version": Config.PROTOCOL_VERSION }
	if heli != null:
		r.heli = heli_state()
	return r


## What is wrong when the other side runs build `theirs` ("" when it is the same as this one). A build that
## sends no version at all is an older one.
static func version_problem(theirs: int) -> String:
	if theirs == Config.PROTOCOL_VERSION:
		return ""
	return "These two builds of the game do not match (this one is version %d, the other is version %d). Everyone has to run the same build." % [Config.PROTOCOL_VERSION, theirs]


## Are HUD markers shown on this level? (Nightmare: no.)
func show_markers() -> bool:
	return Difficulty.flag(difficulty, "markers")


func mult(key: String) -> float:
	return Difficulty.get_mult(difficulty, key)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func client_state(pos: Vector3, yaw: float, action: int = 0, mag: int = 0) -> void:
	if not is_host:
		return
	var p = players.get(multiplayer.get_remote_sender_id())
	if p == null or _now < p.ignore_until:
		return
	p.pos = pos
	p.yaw = yaw
	p.action = action & PlayerWire.ACTION_BODY # the host adds bleeding and healing itself
	p.mag = clampi(mag, 0, 255) # only shown to whoever spectates them


## The sender swung a shove from `origin` along `dir`.
@rpc("any_peer", "call_remote", "reliable")
func client_shove(origin: Vector3, dir: Vector3) -> void:
	if is_host:
		host_shove(multiplayer.get_remote_sender_id(), origin, dir)


## A shove connected at `pos`: every peer hears the thud and sees a puff; the shover's view jolts.
@rpc("authority", "call_local", "reliable")
func shove_landed(pos: Vector3, by: int) -> void:
	Sfx.play("thud", pos, 0.08)
	fx.burst(Fx.Layer.SMOKE, pos, Vector3.UP, 3, { "speed": 0.8, "spread": 0.6, "life": 0.5, "size": 0.08,
		"size_end": 0.3, "color": Color(0.45, 0.04, 0.04, 0.6), "gravity": 1.0 })
	if by == my_id and local_player != null:
		local_player.kick_view(Config.SHOVE_NUDGE)


func _on_local_shove(origin: Vector3, dir: Vector3) -> void:
	if is_host:
		host_shove(my_id, origin, dir)
	else:
		client_shove.rpc_id(1, origin, dir)


## Host: player `id` shoves from `origin` along `dir`. Every zombie in reach and in front is
## knocked back and staggered for a little damage, never a limb. Returns how many it hit.
func host_shove(id: int, origin: Vector3, dir: Vector3) -> int:
	if not players.has(id) or _now - float(players[id].last_shove) < Config.SHOVE_TIME * 0.8:
		return 0
	if (players[id].status as PlayerStatus).downed or (players[id].status as PlayerStatus).dead:
		return 0 # no shoving from the floor, or from beyond
	players[id].last_shove = _now
	var flat := Vector3(dir.x, 0, dir.z).normalized()
	if flat == Vector3.ZERO:
		return 0
	var hit := 0
	var at := Vector3.ZERO
	for z: Zombie in zombies.values().duplicate():
		var to := z.global_position - origin
		to.y = 0.0
		if to.length() > Config.SHOVE_RANGE or flat.angle_to(to.normalized()) > Config.SHOVE_CONE:
			continue
		z.shove(flat * Config.SHOVE_PUSH)
		at = z.global_position + Vector3(0, 1.1, 0)
		hooks.on_zombie_shoved(z, id)
		hit_zombie(id, z, Humanoid.Part.TORSO, at, flat, Config.SHOVE_DAMAGE) # the torso: never a limb
		hit += 1
	if hit > 0:
		shove_landed.rpc(at, id)
	return hit


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


## The sender holds use on a downed teammate (`on`) or let go.
@rpc("any_peer", "call_remote", "reliable")
func client_revive(target: int, on: bool) -> void:
	if not is_host:
		return
	var id := multiplayer.get_remote_sender_id()
	if on:
		start_revive(id, target)
	elif players.has(id) and (players[id].status as PlayerStatus).using == &"revive":
		cancel_use(id)


## The sender started something that stops them using an item (a sprint).
@rpc("any_peer", "call_remote", "reliable")
func client_cancel_use() -> void:
	if is_host:
		cancel_use(multiplayer.get_remote_sender_id())


## A player used an item from their inventory (Inventory ids travel as strings).
@rpc("any_peer", "call_remote", "reliable")
func client_use_item(item: String) -> void:
	if is_host:
		use_item(multiplayer.get_remote_sender_id(), StringName(item))


# --- RPCs: host -> clients ------------------------------------------------------

## The host will not have this client (a different build): the message says why.
@rpc("authority", "call_remote", "reliable")
func refuse_join(message: String) -> void:
	join_refused.emit(message)


@rpc("authority", "call_remote", "reliable")
func welcome(map_name_: String, mission_: String, interactable_states: Dictionary, match_rules: Dictionary = {}) -> void:
	var problem := version_problem(int(match_rules.get("version", 0)))
	if problem != "":
		join_refused.emit(problem)
		return
	if not GameMap.NAMES.has(map_name_):
		return
	map_name = map_name_
	mission = mission_
	limited_ammo = not match_rules.get("infinite_ammo", true)
	difficulty = match_rules.get("difficulty", "normal")
	if match_rules.has("mission"):
		mission_state(match_rules.mission)
	_build_world()
	for iid: int in interactable_states:
		_apply_interact_state(iid, interactable_states[iid])
	if match_rules.has("heli"):
		apply_heli_state(match_rules.heli)
	print("[client %d] joined host" % my_id)


## The objective changed, its clock started or stopped, or the mission ended (MissionRules.state).
@rpc("authority", "call_remote", "reliable")
func mission_state(state: Dictionary) -> void:
	var before: int = mission_view.get("wave", 0)
	mission_view = state.duplicate() # counted down here; never the sender's own copy
	if state.get("kind", "") == "survive" and int(state.get("wave", 0)) > before:
		Sfx.play_ui("siren", -4.0) # a new wave is on its way


## Host: tell everyone where the mission stands. Called by MissionRules whenever something changes.
func send_mission_state() -> void:
	if not is_host:
		return
	var state := rules.state()
	mission_state.rpc(state)
	mission_state(state)


## Build the extraction zone's look when its objective comes up, and take it away after.
func _update_extraction() -> void:
	var zone: String = mission_view.get("zone", "")
	var want: bool = mission_view.kind == "extract" and mission_view.status == MissionRules.Status.RUNNING and map.data.zones.has(zone)
	if extraction != null and (not want or extraction.zone != zone):
		extraction.queue_free()
		extraction = null
	if want and extraction == null:
		var c := map.data.zone_center(zone)
		extraction = ExtractionZone.create(map.data, zone, fx, map.ground_y(c))
		world.add_child(extraction)


## Between two messages from the host every peer counts the objective's clock down itself.
func _tick_mission_view(delta: float) -> void:
	var left: float = mission_view.left
	if mission_view.counting and left > 0.0:
		mission_view.left = maxf(0.0, left - delta)


@rpc("authority", "call_remote", "reliable")
func respawn_at(pos: Vector3, reason: String) -> void:
	if local_player:
		local_player.teleport(pos)
		if reason != "spawn":
			local_player.arrive()
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


## What you carry changed: this is all of it now. `popup` is the "+1  Medkit" that rises on the HUD.
@rpc("authority", "call_remote", "reliable")
func inventory_changed(state: Dictionary, popup := "") -> void:
	if local_player:
		local_player.inventory.apply_state(state)
		if popup != "":
			hud.gain(popup)


## Your wounds and what you are using changed (PlayerStatus.get_state).
@rpc("authority", "call_remote", "reliable")
func status_changed(state: Dictionary) -> void:
	if local_player:
		local_player.status.apply_state(state)


## A short line for one player (the HUD's rising text): "Can't carry any more".
@rpc("authority", "call_remote", "reliable")
func notice(text: String) -> void:
	if hud:
		hud.gain(text)


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
	var pack := interactables.get(iid) as Backpack
	if pack != null and pack.taken_by >= 0: # emptied: nothing is left of it
		interactables.erase(iid)
		pack.queue_free()
		return
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
	if state.has("pack"):
		var pack := Backpack.new()
		pack.rotation.y = state.get("yaw", 0.0)
		it = pack
	elif state.has("weapon"):
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
		"loadout": _starting_loadout(), "swap_rounds": -1, "action": 0, "mag": 0, "boarded": false, "last_shove": -100.0, "step_pos": map.player_spawn(),
		"reserve": map.starting_ammo(), "inventory": Inventory.new(), "status": PlayerStatus.new() }
	health.low.connect(func(): hooks.on_low_hp(id))
	score.join(id, players[id].name)
	health.died.connect(func(): _hp_zero(id))
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
	if rules.checkpoint != "": # past a checkpoint: back there, around its middle
		var c := map.data.zone_center(rules.checkpoint)
		var a: float = p.slot * TAU / 8.0
		var at := Vector3(c.x + cos(a) * 1.2, 0, c.z + sin(a) * 1.2)
		p.pos = Vector3(at.x, map.ground_y(at) + 0.1, at.z)
	p.step_pos = p.pos
	p.boarded = false
	(p.health as Health).reset()
	clear_status(id)
	rules.set_out(id, false) # (a downed player who bled out is back in the fight)
	p.ignore_until = _now + 0.3 # drop in-flight positions from before the teleport
	_send_to(id, &"respawn_at", [p.pos, reason])
	if reason != "spawn":
		play_fx(Fx.Kind.ARRIVAL, p.pos, Vector3.UP) # dust where they jump down
	hooks.on_player_respawned(id, reason)


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


# --- Host: inventory --------------------------------------------------------------

## How many more of an item a player can carry (0 for nobody).
func inventory_room(id: int, item: StringName) -> int:
	return (players[id].inventory as Inventory).room(item) if players.has(id) else 0


## Put `n` of an item in a player's inventory (a pickup, a lootbox, a hook's reward). Returns how many fitted.
func give_item(id: int, item: StringName, n := 1) -> int:
	if not players.has(id):
		return 0
	var got := (players[id].inventory as Inventory).add(item, n)
	if got > 0:
		_sync_inventory(id, "+%d  %s" % [got, Inventory.item_name(item)])
		hooks.on_item_picked_up(id, item, got)
	return got


## Hand a player the key or keycard `key`. False if they had it already.
func give_key(id: int, key: StringName) -> bool:
	if not players.has(id) or not (players[id].inventory as Inventory).add_key(key):
		return false
	_sync_inventory(id, "Key  %s" % key)
	hooks.on_key_picked_up(id, key)
	return true


## Tell a player what they carry (the whole inventory, whenever it changed).
func _sync_inventory(id: int, popup := "") -> void:
	if players.has(id):
		_send_to(id, &"inventory_changed", [(players[id].inventory as Inventory).get_state(), popup])


## Could this player start using `item` right now? They must be alive, have one and not be busy with
## another; a heal is for the hurt or the bleeding, painkillers for when the last dose is wearing off.
func can_use_item(id: int, item: StringName) -> bool:
	if not players.has(id) or rules.out.has(id) or not Inventory.valid(item):
		return false
	var health: Health = players[id].health
	var status: PlayerStatus = players[id].status
	if health.is_dead() or status.is_using() or (players[id].inventory as Inventory).count(item) <= 0:
		return false
	match Inventory.kind_of(item):
		Inventory.Kind.MATERIAL:
			return false # planks go up on a barricade, they are not used from the pack
		Inventory.Kind.MEDICAL:
			if item == Inventory.PAINKILLERS:
				return health.temp < Config.PAINKILLERS_TEMP * Config.PAINKILLERS_REUSE
			return health.hp < health.max_hp or status.bleed > 0
	return true


## A player starts using an item. A throw is at once; the medical things take their time
## (`Inventory.use_time`) and only leave the pack when they are done: a hit or a sprint cancels them.
func use_item(id: int, item: StringName) -> bool:
	if not can_use_item(id, item):
		return false
	var seconds := Inventory.use_time(item)
	if seconds <= 0.0:
		_finish_use(id, item)
	else:
		(players[id].status as PlayerStatus).begin_use(item, seconds)
		_sync_status(id)
	return true


## What a player was using is cancelled (a hit, a sprint). The item stays in the pack. False if they were not using anything.
func cancel_use(id: int) -> bool:
	if not players.has(id):
		return false
	var status: PlayerStatus = players[id].status
	var item := status.using
	var helping := status.revive_target
	if not status.cancel_use():
		return false
	if item == &"revive":
		status.revive_target = 0
		if players.has(helping): # the downed one goes back to waiting
			var down: PlayerStatus = players[helping].status
			down.revive_left = 0.0
			down.revive_total = 0.0
			_sync_status(helping)
	_sync_status(id)
	hooks.on_item_use_cancelled(id, item)
	return true


## The item is on: it leaves the pack and `on_item_used` does what it does.
func _finish_use(id: int, item: StringName) -> void:
	if not (players[id].inventory as Inventory).remove(item):
		return
	_sync_inventory(id)
	hooks.on_item_used(id, item)


## Tell a player their wounds and what they are using.
func _sync_status(id: int) -> void:
	if players.has(id):
		_send_to(id, &"status_changed", [(players[id].status as PlayerStatus).get_state()])


## A new life (or a death with no way back): no wounds, nothing being used.
func clear_status(id: int) -> void:
	if players.has(id):
		(players[id].status as PlayerStatus).reset()
		_sync_status(id)


## Host, every physics tick: wounds bleed, painkillers wear off, what is being used gets nearer done,
## the downed bleed out or are got up.
func tick_status(delta: float) -> void:
	for id: int in players.keys():
		if not players.has(id):
			continue # (one of the others died a moment ago and was taken out)
		var p: Dictionary = players[id]
		var health: Health = p.health
		var status: PlayerStatus = p.status
		status.invuln = maxf(0.0, status.invuln - delta)
		if status.dead:
			if status.respawn_left >= 0.0: # a timer brings them back; otherwise a checkpoint does, or nothing
				status.respawn_left -= delta
				if status.respawn_left <= 0.0:
					respawn_player(id, "respawn")
			continue
		if status.downed:
			_tick_downed(id, delta)
			continue
		if health.is_dead() or rules.out.has(id):
			continue
		health.decay_temp(delta)
		var lost: int = status.bleed_damage(delta)
		if lost > 0:
			hooks.on_player_damaged(id, lost, null)
			health.damage(lost) # (not damage_player: bleeding must not cancel the bandage)
			if health.is_dead():
				continue # it knocked them down or killed them: they have a new state
		if status.using == &"revive" and not _in_reach_of_downed(id, status.revive_target):
			cancel_use(id) # walked off, or the one they were helping is gone
			continue
		var done: StringName = status.step_use(delta)
		if done == &"revive":
			_finish_revive(id)
		elif done != &"":
			_sync_status(id)
			_finish_use(id, done)


## A downed player: bleeding out, unless someone is getting them up (then the clock waits).
func _tick_downed(id: int, delta: float) -> void:
	var status: PlayerStatus = players[id].status
	if status.revive_left > 0.0:
		status.revive_left = maxf(0.0, status.revive_left - delta)
		return
	status.down_left -= delta
	if status.down_left <= 0.0:
		kill_player(id)


## HP reached 0. With a teammate still standing who could get them up, a player goes down; the last
## one standing just dies.
func _hp_zero(id: int) -> void:
	for other: int in players:
		if other != id and not rules.out.has(other):
			down_player(id)
			return
	kill_player(id)


## Host: down on the floor for `Config.DOWNED_TIME` seconds, out of the fight until got up.
func down_player(id: int) -> void:
	var status: PlayerStatus = players[id].status
	cancel_use(id)
	status.stop_bleeding()
	status.downed = true
	status.down_left = Config.DOWNED_TIME
	status.down_total = Config.DOWNED_TIME
	rules.set_out(id, true)
	_sync_status(id)
	hooks.on_player_downed(id)


## Host: a player dies for good (and respawns or stays out, as the mission says): HP ran out with nobody
## to help, or a downed player bled out or was finished.
func kill_player(id: int) -> void:
	(players[id].health as Health).hp = 0
	_leave_body(id)
	for other: int in players: # whoever was getting them up stops
		if other != id and (players[other].status as PlayerStatus).revive_target == id:
			cancel_use(other)
	hooks.on_player_died(id)


## Host: dead with no way back yet (`rules.respawn` off): out of the fight, watching, until the timer or
## the next checkpoint (or the end of the mission) says otherwise.
func mark_dead(id: int) -> void:
	var status: PlayerStatus = players[id].status
	status.dead = true
	status.respawn_left = rules.respawn_after
	status.respawn_checkpoint = rules.respawn_checkpoint
	rules.set_out(id, true)
	_sync_status(id)


## Host: `id` starts getting the downed player `target` up (the use key held beside them).
func start_revive(id: int, target: int) -> bool:
	if id == target or not players.has(id) or not players.has(target):
		return false
	var helper: PlayerStatus = players[id].status
	var down: PlayerStatus = players[target].status
	if not down.downed or helper.downed or rules.out.has(id) or helper.is_using() or down.revive_left > 0.0:
		return false
	if not _in_reach_of_downed(id, target):
		return false
	helper.begin_use(&"revive", Config.REVIVE_SECONDS)
	helper.revive_target = target
	down.revive_left = Config.REVIVE_SECONDS
	down.revive_total = Config.REVIVE_SECONDS
	_sync_status(id)
	_sync_status(target)
	return true


func _in_reach_of_downed(id: int, target: int) -> bool:
	if not players.has(target) or not (players[target].status as PlayerStatus).downed:
		return false
	return (players[id].pos as Vector3).distance_to(players[target].pos) <= Config.REVIVE_RANGE + 1.5


func _finish_revive(id: int) -> void:
	var helper: PlayerStatus = players[id].status
	var target := helper.revive_target
	helper.revive_target = 0
	_sync_status(id)
	if players.has(target) and (players[target].status as PlayerStatus).downed:
		revive_player(target, id)


## Host: up again at `Config.REVIVE_HP`, safe for a moment.
func revive_player(id: int, by: int) -> void:
	var status: PlayerStatus = players[id].status
	status.downed = false
	status.down_left = 0.0
	status.down_total = 0.0
	status.revive_left = 0.0
	status.revive_total = 0.0
	status.invuln = Config.REVIVE_INVULN
	(players[id].health as Health).revive(Config.REVIVE_HP)
	rules.set_out(id, false)
	_sync_status(id)
	hooks.on_player_revived(id, by)


## Who the local player can watch: the other players standing (not downed, not dead), by id.
func spectate_candidates() -> Array:
	var ids := []
	for id: int in remotes:
		var bits := int((remotes[id] as RemotePlayer).action)
		if (remotes[id] as RemotePlayer).hp > 0 and bits & (PlayerWire.ACTION_DOWNED | PlayerWire.ACTION_DEAD) == 0:
			ids.append(id)
	ids.sort()
	return ids


## While dead: keep following someone who is still standing and tell the camera where they are.
func _update_spectating(_delta: float) -> void:
	var lp := local_player
	lp.spectate_candidates = spectate_candidates()
	lp.spectator.update(lp.spectate_candidates)
	var target := lp.spectator.target
	lp.spectate_following = target != 0 and remotes.has(target)
	if lp.spectate_following:
		lp.spectate_focus = (remotes[target] as Node3D).global_position
		lp.spectate_yaw = (remotes[target] as Node3D).rotation.y


## What a dead player's screen says: who they are watching and when (if ever) they come back.
func spectate_text() -> String:
	if local_player == null or not local_player.status.dead:
		return ""
	var lines: Array[String] = []
	var target := local_player.spectator.target
	if target != 0 and remotes.has(target):
		var r := remotes[target] as RemotePlayer
		lines.append("SPECTATING  %s   ♥ %d   %s  %d" % [names.get(target, "Survivor"), r.hp,
			Weapons.def(r.weapon_id).name if Weapons.valid(r.weapon_id) else "", r.mag])
	var status := local_player.status
	if status.respawn_left >= 0.0:
		lines.append("Respawn in %d s" % ceili(status.respawn_left))
	elif status.respawn_checkpoint:
		lines.append("Respawn at the next checkpoint")
	else:
		lines.append("You are out for this mission")
	return "\n".join(lines)


## The downed teammate within reach of the local player, as this peer sees them (0 for none).
func downed_teammate_near() -> int:
	if local_player == null or local_player.status.downed:
		return 0
	for id: int in remotes:
		if int((remotes[id] as RemotePlayer).action) & PlayerWire.ACTION_DOWNED != 0 \
				and _player_pos(id).distance_to(local_player.global_position) <= Config.REVIVE_RANGE:
			return id
	return 0


## Host: everything a player carries goes on the ground where they stand, for the others to loot.
## Nothing carried means no backpack. Returns it, or null.
func drop_backpack(id: int) -> Backpack:
	if not is_host or not players.has(id):
		return null
	var inv: Inventory = players[id].inventory
	if inv.is_empty():
		return null
	var lying: Array[int] = []
	for iid: int in interactables:
		if iid >= Config.DROP_IID_BASE and interactables[iid] is Backpack:
			lying.append(iid)
	if lying.size() >= Config.BACKPACKS_MAX: # the oldest one makes room
		lying.sort()
		(interactables[lying[0]] as Backpack).discard()
	var at: Vector3 = players[id].pos
	var state := inv.get_state()
	state.merge({ "by": -1, "drop": true, "pack": true, "yaw": fposmod(_next_drop * 2.399963, TAU),
		"at": Vector3(at.x, map.ground_y(at), at.z) })
	var iid := Config.DROP_IID_BASE + _next_drop
	_next_drop += 1
	var pack := _add_drop(iid, state) as Backpack
	interact_state.rpc(iid, pack.get_state())
	inv.clear()
	_sync_inventory(id)
	hooks.on_backpack_dropped(id, pack)
	return pack


## A player takes what fits from a backpack. Returns how many things they took.
func loot_backpack(id: int, pack: Backpack) -> int:
	if not players.has(id) or pack.taken_by >= 0:
		return 0
	var inv: Inventory = players[id].inventory
	var before := {}
	for item: StringName in Inventory.ITEMS:
		before[item] = inv.count(item)
	var had_keys := inv.keys()
	var moved := pack.loot(inv, id)
	if moved == 0:
		notice_to(id, "Can't carry any more")
		return 0
	_sync_inventory(id, "+%d  from the backpack" % moved)
	for item: StringName in Inventory.ITEMS:
		if inv.count(item) > before[item]:
			hooks.on_item_picked_up(id, item, inv.count(item) - before[item])
	for key in inv.keys():
		if not had_keys.has(key):
			hooks.on_key_picked_up(id, key)
	return moved


## Say something short to one player (the host included).
func notice_to(id: int, text: String) -> void:
	_send_to(id, &"notice", [text])


func _on_local_use_cancelled() -> void:
	if is_host:
		cancel_use(my_id)
	else:
		client_cancel_use.rpc_id(1)


func _on_local_item(item: StringName) -> void:
	if is_host:
		use_item(my_id, item)
	else:
		client_use_item.rpc_id(1, String(item))


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
		if over_ground < Config.SPRINT_SPEED * 2.0:
			score.add(id, "distance", over_ground * _step_t)
		var crouched: bool = int(p.action) & PlayerWire.ACTION_CROUCH != 0
		# (faster than anyone runs = a respawn or a teleport, not footsteps)
		if over_ground >= Config.NOISE_SPRINT_SPEED and over_ground < Config.SPRINT_SPEED * 2.0 and not crouched:
			make_noise(pos, Config.NOISE_SPRINT, id)
	_step_t = 0.0


## Host: the mission just ended. Save the time if it was won and send everyone the end screen.
func match_over(won: bool) -> void:
	if not is_host:
		return
	var seconds := rules.elapsed
	var new_best := won and Records.submit(mission if mission != "" else map_name, seconds, difficulty)
	var summary := score.summary(won, seconds, new_best)
	final_score.rpc(summary)
	final_score(summary)


## The end screen's numbers (Score.summary), sent once when the mission ends.
@rpc("authority", "call_remote", "reliable")
func final_score(summary: Dictionary) -> void:
	final_score_view = summary
	hud.set_final_score(summary)


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


## `bleed_roll` (0..1) decides whether a zombie's hit also opens a wound; -1 rolls it (tests pin it).
func damage_player(id: int, amount: int, by: Zombie = null, bleed_roll := -1.0) -> void:
	if not players.has(id):
		return
	var status: PlayerStatus = players[id].status
	if status.invuln > 0.0 or status.dead:
		return # just got up (nothing can hurt them yet), or there is nothing left to hurt
	hooks.on_player_damaged(id, amount, by)
	if status.downed: # on the floor: the hit costs time, and can finish them
		if amount > 0:
			status.down_left -= amount * Config.DOWNED_DAMAGE_SECONDS
			if status.down_left <= 0.0:
				kill_player(id)
			else:
				_sync_status(id)
		return
	var bleeds := false
	if amount > 0:
		cancel_use(id) # a hit knocks the bandage off
		if by != null:
			bleeds = status.hurt(rng.randf() if bleed_roll < 0.0 else bleed_roll)
	(players[id].health as Health).damage(amount)
	if bleeds and status.bleed > 0: # (a hit that killed them leaves a clean new life, no wound)
		_sync_status(id)
		hooks.on_player_bleeding(id, status.bleed)


func heal_player(id: int, amount: int) -> void:
	if players.has(id):
		(players[id].health as Health).heal(amount)


## Id of the closest living player, or 0 if nobody is in range.
func nearest_player(from: Vector3) -> int:
	var best := 0
	var best_d := Config.ZOMBIE_AGGRO_RANGE
	var down := 0
	var down_d := Config.DOWNED_FINISH_RANGE
	for id: int in players:
		var pos: Vector3 = players[id].pos
		var d := Vector2(pos.x - from.x, pos.z - from.z).length()
		if (players[id].status as PlayerStatus).downed:
			if d < down_d: # a downed player is only a target when nobody else is as near
				down_d = d
				down = id
		elif not rules.out.has(id) and d < best_d:
			best_d = d
			best = id
	if down != 0 and (best == 0 or best_d > Config.DOWNED_FINISH_RANGE):
		return down
	return best


# --- Host: interactions -----------------------------------------------------------

## A player right-clicked interactable `iid`. Returns false if it was out of reach or unknown.
## `weapon`: the gun in the player's hands as they clicked (the host otherwise only learns it from shots).
## `rounds`: what is in the magazine of the gun they would drop to take this one (-1 = not said).
func host_interact(player_id: int, iid: int, weapon: int = -1, rounds: int = -1) -> bool:
	if not players.has(player_id) or not interactables.has(iid) or (players[player_id].status as PlayerStatus).downed \
			or (players[player_id].status as PlayerStatus).dead:
		return false
	if Weapons.valid(weapon) and players[player_id].loadout.has(weapon):
		players[player_id].weapon = weapon
	players[player_id].swap_rounds = rounds
	var target: Interactable = interactables[iid]
	var pos: Vector3 = players[player_id].pos
	if pos.distance_to(target.global_position) > Config.INTERACT_RANGE + 1.5:
		return false
	hooks.on_right_click(player_id, target)
	rules.interacted(player_id, iid)
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
	var box: AmmoBox = _add_drop(iid, { "ammo": type, "rounds": maxi(1, roundi(rounds * mult("ammo"))), "by": -1, "at": Vector3(at.x, map.ground_y(at), at.z) })
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
	z.hp = roundi(z.hp * mult("hp"))
	_next_zombie += 1
	zombies[z.zid] = z
	add_child(z)
	return z


func zombie_attack_lands(z: Zombie, target_id: int) -> void:
	if not players.has(target_id):
		return
	var pos: Vector3 = players[target_id].pos
	if Vector2(pos.x - z.global_position.x, pos.z - z.global_position.z).length() < Config.ZOMBIE_ATTACK_RANGE + 0.6:
		damage_player(target_id, roundi(z.attack_damage() * mult("damage")), z)


func zombie_bashes_door(_z: Zombie, d: Door) -> void:
	d.take_hit(Config.DOOR_BASH_DAMAGE)


func zombie_leap_lands(z: Zombie) -> void:
	hooks.on_zombie_leap_landed(z)
	for id: int in players:
		var pos: Vector3 = players[id].pos
		if pos.distance_to(z.global_position) < Config.LEAP_HIT_RADIUS:
			damage_player(id, roundi(Config.LEAP_DAMAGE * mult("damage")), z)


func _queue_shot(shooter: int, origin: Vector3, dir: Vector3, weapon: int = Weapons.DEFAULT) -> void:
	var p = players.get(shooter)
	if p == null or not Weapons.valid(weapon) or not p.loadout.has(weapon):
		return
	if (p.status as PlayerStatus).dead:
		return
	if (p.status as PlayerStatus).downed and weapon != (p.loadout as Loadout).sidearm():
		return # only the pistol is within reach
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
	var landed := false
	var impacts := []
	for i in pellets:
		landed = _trace_bullet(shooter, origin, Weapons.scatter(dir, cone, rng), d, impacts) or landed
	if pellets > 1 and not impacts.is_empty(): # a pattern: a hole per pellet, one puff for the lot
		var mid := Vector3.ZERO
		for im: Array in impacts:
			play_fx(Fx.Kind.IMPACT, im[0], im[1], im[2] + Fx.IMPACT_HOLE_ONLY)
			mid += im[0]
		play_fx(Fx.Kind.IMPACT, mid / impacts.size(), impacts[0][1], impacts[0][2] + Fx.IMPACT_PUFF_ONLY)
	elif not impacts.is_empty():
		play_fx(Fx.Kind.IMPACT, impacts[0][0], impacts[0][1], impacts[0][2])
	score.add(shooter, "shots")
	if landed:
		score.add(shooter, "hits")
	_tell_shot(shooter, weapon, origin, _bullet_end(origin, dir, float(d.range)))


## Where a bullet from `origin` along `dir` stops: the first wall or body, or its reach.
func _bullet_end(origin: Vector3, dir: Vector3, reach: float) -> Vector3:
	if not is_inside_tree():
		return origin + dir * reach
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach, Config.LAYER_WORLD | Config.LAYER_HITBOX)
	q.collide_with_areas = true
	var hit := get_viewport().get_world_3d().direct_space_state.intersect_ray(q)
	return hit.position if not hit.is_empty() else origin + dir * reach


## Host: everyone but the shooter sees (and hears) their gun go off.
func _tell_shot(shooter: int, weapon: int, origin: Vector3, end: Vector3) -> void:
	for peer in multiplayer.get_peers():
		if peer != shooter:
			shot_seen.rpc_id(peer, shooter, weapon, origin, end)
	if shooter != my_id:
		shot_seen(shooter, weapon, origin, end)


## Someone else fired: their gun flashes, a puff of smoke, the shot heard where they are. (`end` is
## where the bullet went, for the tracers to come.)
@rpc("authority", "call_remote", "unreliable")
func shot_seen(shooter: int, weapon: int, origin: Vector3, end: Vector3) -> void:
	if not remotes.has(shooter):
		return
	var r: RemotePlayer = remotes[shooter]
	r.fired(rng)
	var at := r.muzzle_world()
	tracers.fire(at, end, weapon)
	_near_miss(origin, end)
	if Weapons.flash_shape(weapon) == Weapons.Flash.NONE:
		muzzle_smoke(at, 1, true)
	else:
		muzzle_smoke(at, 1, false)
	var d := Weapons.def(weapon)
	Sfx.play("gunshot", at, 0.04, d.volume, d.pitch)


## Someone else's bullet from `origin` to `end`: if it passed close by your head, you hear it go by
## and flinch.
func _near_miss(origin: Vector3, end: Vector3) -> void:
	var lp := local_player
	if lp == null or lp.status.dead:
		return
	var ear := lp.camera.global_position
	var line := end - origin
	var length := line.length()
	if length < 0.01:
		return
	var u := (ear - origin).dot(line) / (length * length)
	if u <= 0.0 or u >= 1.0: # behind the shooter or short of you
		return
	if (origin + line * u).distance_to(ear) > Config.WHIZ_RADIUS:
		return
	whizzes += 1
	Sfx.play("whiz", origin + line * u, 0.1)
	lp.punch += Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)).normalized() * Config.WHIZ_FLINCH


## Puffs of smoke from a muzzle at `at`, drifting up and with the wind; `thin` for a suppressed gun or a
## hot barrel's wisp.
func muzzle_smoke(at: Vector3, count: int, thin: bool) -> void:
	var drift := (Vector3.UP + Config.MUZZLE_WIND * 0.6).normalized()
	fx.burst(Fx.Layer.SMOKE, at, drift, count, { "speed": 0.35 if thin else 0.6, "spread": 0.5,
		"life": Config.MUZZLE_SMOKE_LIFE * (1.4 if thin else 1.0), "size": 0.03 if thin else 0.06,
		"size_end": 0.14 if thin else 0.28, "color": Color(0.62, 0.62, 0.64, 0.16 if thin else 0.22), "gravity": -0.5 })


## Trace a bullet and apply it. Body-part hitboxes are Area3Ds; walls and closed doors block.
## True if it hit a zombie.
func _trace_bullet(shooter: int, origin: Vector3, dir: Vector3, d: Dictionary, impacts: Array = []) -> bool:
	var space := get_viewport().get_world_3d().direct_space_state
	var reach: float = d.range
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * reach,
		Config.LAYER_WORLD | Config.LAYER_HITBOX)
	q.collide_with_areas = true
	var hit := space.intersect_ray(q)
	if Difficulty.flag(difficulty, "friendly_fire") and _shoot_teammate(shooter, origin, dir, hit, d):
		return false
	if hit.is_empty():
		return false
	var collider: Object = hit.collider
	if collider is Area3D and collider.has_meta("zombie"):
		var z: Zombie = collider.get_meta("zombie")
		if is_instance_valid(z) and zombies.has(z.zid):
			hit_zombie(shooter, z, collider.get_meta("part"), hit.position, dir, d.damage)
			return true
	impacts.append([hit.position, hit.normal, Surface.of_hit(hit)]) # a wall, a floor, a door: what it is made of
	return false


## Friendly fire: the first other player whose body the bullet passes through before whatever
## else it hit takes part of its damage. Players are capsules at their reported positions.
func _shoot_teammate(shooter: int, origin: Vector3, dir: Vector3, hit: Dictionary, d: Dictionary) -> bool:
	var reach: float = d.range
	if not hit.is_empty():
		reach = origin.distance_to(hit.position)
	var best := -1
	var best_t := reach
	for id: int in players:
		if id == shooter:
			continue
		var feet: Vector3 = players[id].pos
		var mid := feet + Vector3(0, Config.PLAYER_HEIGHT / 2.0, 0)
		var t := (mid - origin).dot(dir)
		if t <= 0.0 or t >= best_t:
			continue
		var p := origin + dir * t
		var flat := Vector2(p.x - feet.x, p.z - feet.z).length()
		if flat <= Config.PLAYER_RADIUS and p.y >= feet.y and p.y <= feet.y + Config.PLAYER_HEIGHT:
			best = id
			best_t = t
	if best < 0:
		return false
	var dmg: int = d.damage
	damage_player(best, roundi(dmg * Config.FRIENDLY_FIRE_MULT))
	return true


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
	_record_own_player()
	_footsteps(delta)
	tick_status(delta)

	director.step(delta)
	rules.step(delta)
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
		var player_bytes := PlayerWire.pack(snap[0])
		if snap[1].size() <= Interest.budget(players.size()):
			snapshot.rpc(player_bytes, ZombieWire.pack(snap[1])) # it all fits: one packet for everyone
		else:
			for peer: int in multiplayer.get_peers(): # too many zombies: each client gets the ones that matter to it
				if players.has(peer):
					snapshot.rpc_id(peer, player_bytes, zombie_bytes_for(peer, snap[1], _snap_tick))
		_snap_tick += 1
		_apply_snapshot(snap[0], snap[1])


## What a player's body is doing as everyone else sees it: what their own game said plus what the host knows.
func _action_bits(p: Dictionary) -> int:
	var bits: int = p.action
	if (p.status as PlayerStatus).bleed > 0:
		bits |= PlayerWire.ACTION_BLEED
	if (p.status as PlayerStatus).is_using():
		bits |= PlayerWire.ACTION_HEAL
	if (p.status as PlayerStatus).downed:
		bits |= PlayerWire.ACTION_DOWNED
	if (p.status as PlayerStatus).dead:
		bits |= PlayerWire.ACTION_DEAD
	return bits


## The zombie block of the snapshot for client `peer`: all of `list` while it fits in the packet, otherwise
## the nearest to that player every time and the far ones in turn (Interest).
func zombie_bytes_for(peer: int, list: Array, tick: int) -> PackedByteArray:
	var budget := Interest.budget(players.size())
	if list.size() <= budget:
		return ZombieWire.pack(list)
	var at: Vector3 = players[peer].pos if players.has(peer) else Vector3.ZERO
	return ZombieWire.pack(Interest.pick(list, at, tick, budget))


## Host: where everyone and everything is right now, as [players, zombies] (see PlayerWire and
## ZombieWire for what each entry holds). Sent Config.TICK_RATE times a second; must fit one packet.
func build_snapshot() -> Array:
	var pd := []
	for id: int in players:
		var p: Dictionary = players[id]
		pd.append({ "id": id, "pos": p.pos, "yaw": p.yaw, "hp": (p.health as Health).total(), "kills": p.kills, "weapon": p.weapon, "action": _action_bits(p), "mag": p.mag })
	var zd := []
	for z: Zombie in zombies.values():
		zd.append({ "zid": z.zid, "pos": z.global_position, "yaw": z.rotation.y, "state": z.state,
			"type": z.type, "mask": z.rig.severed_mask, "flags": ZombieWire.FLAG_CRAWLING if z.is_crawling() else 0 })
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
		(remotes[id] as RemotePlayer).hp = e.hp
		(remotes[id] as RemotePlayer).mag = e.get("mag", 0)
		(remotes[id] as RemotePlayer).visible = int(e.get("action", 0)) & PlayerWire.ACTION_DEAD == 0 # (no ghost left standing)
	for id: int in remotes.keys():
		if not seen.has(id):
			(remotes[id] as Node).queue_free()
			remotes.erase(id)

	if is_host:
		return # the host's zombies are the real ones
	var now := Time.get_ticks_msec()
	for e: Dictionary in zombies_data:
		var zid: int = e.zid
		if _dead_zombies.has(zid):
			continue
		_zombie_seen[zid] = now
		var z: Zombie = zombies.get(zid)
		if z == null:
			z = Zombie.create(zid, e.type, false, e.pos, e.mask)
			zombies[zid] = z
			add_child(z)
		z.buffer.push(e.pos, e.yaw)
		z.state = e.state
	for zid: int in zombies.keys(): # one that has been missing from the snapshots for a while is gone
		if now - int(_zombie_seen.get(zid, 0)) > Config.ZOMBIE_STALE * 1000.0:
			(zombies[zid] as Node).queue_free()
			zombies.erase(zid)
	for zid: int in _zombie_seen.keys():
		if not zombies.has(zid):
			_zombie_seen.erase(zid)


func _process(delta: float) -> void:
	if local_player == null:
		return
	var captured := Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_update_looked_at()
	var downed_near := downed_teammate_near() if looked_at == null else 0
	hud.set_prompt(looked_at.prompt() if looked_at else ("Hold right-click: revive %s" % names.get(downed_near, "them") if downed_near != 0 else ""))
	if captured and Input.is_action_just_pressed("interact") and right_click_is_use(looked_at):
		interact_with(looked_at)
		local_player.aim_blocked = true
	elif not Input.is_action_pressed("interact"):
		local_player.aim_blocked = false
	_update_revive(captured and downed_near != 0 and Input.is_action_pressed("interact"), downed_near)

	_tick_mission_view(delta)
	hud.set_objective(mission_view, zombies.size())
	local_player.status.tick_view(delta)
	hud.set_inventory(local_player.inventory)
	hud.set_status(local_player.status)
	update_drips(delta)
	update_reach()
	step_pings(delta)
	step_heli(delta)
	if local_player.status.dead:
		_update_spectating(delta)
	hud.set_spectate(spectate_text())
	hud.set_director(director.debug_text() if director_overlay and is_host else "")
	hud.set_wheel(local_player.wheel)
	hud.set_countdown(mission_view)
	_update_extraction()
	var status: int = mission_view.status
	if status == MissionRules.Status.WON or status == MissionRules.Status.FAILED:
		hud.show_end(status == MissionRules.Status.WON, mission_view.reason)
	if brain != null:
		brain.step(delta)
	if hud.end_panel.visible:
		return # the match is over: no shooting at the end screen
	_update_weapon()

	if not is_host:
		_send_timer -= delta
		if _send_timer <= 0.0:
			_send_timer = 1.0 / 30.0
			client_state.rpc_id(1, local_player.global_position, local_player.yaw, local_player.action_bits(), local_player.weapons.rounds())


## Every bleeding player, you and the others, leaves drops on the floor behind them (drawn by each peer).
func update_drips(delta: float) -> void:
	var me := local_player.status
	if _drips.step(my_id, local_player.global_position, me.bleed > 0 and not me.dead, delta):
		gore.splat(local_player.global_position, Vector3.ZERO, Config.BLEED_DRIP_SIZE)
	for id: int in remotes:
		var r: RemotePlayer = remotes[id]
		var bleeding := r.action & PlayerWire.ACTION_BLEED != 0 and r.action & PlayerWire.ACTION_DEAD == 0
		if _drips.step(id, r.global_position, bleeding, delta):
			gore.splat(r.global_position, Vector3.ZERO, Config.BLEED_DRIP_SIZE)


## The host's own player, as its local game sees it.
func _record_own_player() -> void:
	players[1].pos = local_player.global_position
	players[1].yaw = local_player.yaw
	players[1].action = local_player.action_bits()
	players[1].mag = local_player.weapons.rounds()


## Host: a player just died. Their body falls on every peer, and zombies near it go to feed.
func _leave_body(id: int) -> void:
	var at: Vector3 = players[id].pos
	player_body.rpc(id, at, float(players[id].yaw))
	for z: Zombie in zombies.values():
		if z.global_position.distance_to(at) <= Config.FEED_RANGE:
			z.feed_at(at)


## Every peer: a dead player's body (their own look) crumples where they fell.
@rpc("authority", "call_local", "reliable")
func player_body(id: int, at: Vector3, yaw: float) -> void:
	var rig := Characters.survivor(id)
	add_child(rig)
	rig.global_position = Vector3(at.x, map.ground_y(at), at.z)
	rig.rotation.y = yaw
	rig.update(0.0, 0.0)
	gore.ragdoll(rig.take_all(), Vector3.ZERO, Vector3(0, 0.5, 0) - rig.global_transform.basis.z * 1.5, Humanoid.Part.TORSO)
	rig.queue_free()


# --- Chat and pings (the dead keep both) ------------------------------------------------

## What the local player typed: through the host, which sends it to everyone.
func say(text: String) -> void:
	if is_host:
		host_chat(my_id, text)
	else:
		client_chat.rpc_id(1, text)


@rpc("any_peer", "call_remote", "reliable")
func client_chat(text: String) -> void:
	if is_host:
		host_chat(multiplayer.get_remote_sender_id(), text)


## Host: `id` says `text` (trimmed, cut to `Config.CHAT_MAX_CHARS`); false if there was nothing to say.
func host_chat(id: int, text: String) -> bool:
	var line := text.strip_edges().left(Config.CHAT_MAX_CHARS)
	if line == "" or not players.has(id):
		return false
	chat_line.rpc(id, line)
	hooks.on_chat(id, line)
	return true


@rpc("authority", "call_local", "reliable")
func chat_line(id: int, text: String) -> void:
	hud.push_chat("%s: %s" % [player_name(id), text])


## The local player marks where they look.
func ping(spot: Vector3) -> void:
	if is_host:
		host_ping(my_id, spot)
	else:
		client_ping.rpc_id(1, spot)


@rpc("any_peer", "call_remote", "reliable")
func client_ping(spot: Vector3) -> void:
	if is_host:
		host_ping(multiplayer.get_remote_sender_id(), spot)


## Host: `id` marks `spot` for everyone for `Config.PING_TIME` (one each: a new one replaces the old).
func host_ping(id: int, spot: Vector3) -> bool:
	if not players.has(id) or not spot.is_finite():
		return false
	ping_at.rpc(id, spot)
	hooks.on_ping(id, spot)
	return true


@rpc("authority", "call_local", "reliable")
func ping_at(id: int, spot: Vector3) -> void:
	if pings.has(id):
		(pings[id].node as Node).queue_free()
	var mark := Label3D.new()
	mark.text = "▼
%s" % player_name(id)
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.no_depth_test = true
	mark.fixed_size = true
	mark.pixel_size = 0.0012
	mark.font_size = 28
	mark.outline_size = 8
	mark.modulate = Color("ffd24a")
	add_child(mark)
	mark.global_position = spot
	mark.offset = Vector2(0, 30) # the arrow's point just over the spot
	pings[id] = { "node": mark, "left": Config.PING_TIME }
	Sfx.play_ui("beep", -10.0, 1.5)


## Pings fade out and go.
func step_pings(delta: float) -> void:
	for id: int in pings.keys():
		var pg: Dictionary = pings[id]
		pg.left = float(pg.left) - delta
		var mark := pg.node as Label3D
		if pg.left <= 0.0:
			mark.queue_free()
			pings.erase(id)
		else:
			mark.modulate.a = clampf(float(pg.left) / 1.0, 0.0, 1.0)


# --- The helicopter ---------------------------------------------------------------------

## Host: send the helicopter to land at `lz` in `eta` seconds (sooner than a whole flight: it joins it
## part way). Every peer flies the same path from the same numbers.
func call_heli(lz: Vector3, eta: float) -> void:
	var heading := fposmod(lz.x * 0.37 + lz.z * 0.11 + 0.8, TAU) # from the spot, so it is the same every run
	var state := { "lz": lz, "yaw": heading, "t": HeliFlight.LAND_AT - eta, "depart": INF }
	heli_started.rpc(state)
	apply_heli_state(state)


@rpc("authority", "call_remote", "reliable")
func heli_started(state: Dictionary) -> void:
	apply_heli_state(state)


## Where the flight stands now (for late joiners).
func heli_state() -> Dictionary:
	return { "lz": heli_flight.lz, "yaw": heli_flight.yaw, "t": heli_t, "depart": heli_flight.depart_at }


func apply_heli_state(state: Dictionary) -> void:
	if heli != null:
		heli.queue_free()
	heli_flight = HeliFlight.new(state.lz, state.yaw)
	heli_flight.depart_at = state.get("depart", INF)
	heli_t = state.t
	heli = Helicopter.new()
	heli.ground_y = (state.lz as Vector3).y
	add_child(heli)
	_wash_t = 0.0
	_gunner_t = 0.0
	step_heli(0.0)


@rpc("authority", "call_remote", "reliable")
func heli_departs(at: float) -> void:
	if heli_flight != null:
		heli_flight.depart_at = at


## Every peer, every frame: fly it on, kick up dust under it; the host also runs the door gunner and
## sees who has climbed in.
func step_heli(delta: float) -> void:
	if heli == null:
		return
	heli_t += delta
	var pose := heli_flight.pose(heli_t)
	heli.apply(pose, delta, heli_t)
	if pose.phase == HeliFlight.Phase.GONE:
		local_player.seat = null
		local_player.wash_shake = 0.0
		heli.queue_free()
		heli = null
		return
	var alt := float(pose.pos.y) - heli_flight.lz.y
	_heli_wash(delta, pose.pos, alt)
	if is_host:
		var low: bool = pose.phase == HeliFlight.Phase.LANDED or (pose.phase == HeliFlight.Phase.DESCEND and alt < Config.HELI_GUNNER_ALT)
		if low:
			_heli_gunner(delta)
		if pose.phase == HeliFlight.Phase.LANDED:
			_heli_boarding()


func _heli_wash(delta: float, at: Vector3, alt: float) -> void:
	var lp := local_player
	if alt > Config.HELI_WASH_HEIGHT:
		lp.wash_shake = 0.0
		return
	var strength := 1.0 - alt / Config.HELI_WASH_HEIGHT * 0.6
	_wash_t -= delta
	if _wash_t <= 0.0:
		_wash_t = Config.HELI_WASH_EVERY
		var ground := Vector3(at.x, heli_flight.lz.y + 0.1, at.z)
		for k in 10:
			var a := k * TAU / 10.0 + heli_t
			var out := Vector3(cos(a), 0.05, sin(a))
			fx.burst(Fx.Layer.SMOKE, ground + out * 2.0, out, 1, { "speed": 9.0 * strength, "spread": 0.2, "life": 0.9,
				"size": 0.3, "size_end": 1.4, "color": Color(0.52, 0.5, 0.46, 0.35), "gravity": -0.3 })
	var d := Vector2(lp.global_position.x - at.x, lp.global_position.z - at.z).length()
	lp.wash_shake = Config.HELI_WASH_SHAKE * strength * (1.0 - d / Config.HELI_WASH_RADIUS) if d < Config.HELI_WASH_RADIUS else 0.0


func _heli_gunner(delta: float) -> void:
	_gunner_t -= delta
	while _gunner_t <= 0.0:
		_gunner_t += Config.HELI_GUNNER_INTERVAL
		var muzzle := heli.gun_muzzle()
		var best: Zombie = null
		var best_d := Config.HELI_GUNNER_RANGE
		for z: Zombie in zombies.values():
			var dd := z.global_position.distance_to(muzzle)
			if dd < best_d:
				best = z
				best_d = dd
		if best == null:
			return
		var target := best.global_position + Vector3(0, 1.2, 0)
		var dir := (target - muzzle).normalized()
		play_fx(Fx.Kind.TRACER, muzzle, dir, muzzle.distance_to(target))
		Sfx.play(Helicopter.SOUNDS.gunner, muzzle)
		hit_zombie(0, best, Humanoid.Part.TORSO, target, dir, Config.HELI_GUNNER_DAMAGE)


## Players at the door are in; once everyone still standing is, it lifts off.
func _heli_boarding() -> void:
	var door := heli.door_point()
	var standing := 0
	var aboard := 0
	for id: int in players:
		var p: Dictionary = players[id]
		if rules.out.has(id):
			continue
		standing += 1
		if not p.boarded and Vector2(p.pos.x - door.x, p.pos.z - door.z).length() <= Config.HELI_BOARD_RADIUS:
			p.boarded = true
			_send_to(id, &"heli_boarded", [])
			hooks.on_heli_boarded(id)
		if p.boarded:
			aboard += 1
	if standing > 0 and aboard == standing and heli_flight.depart_at == INF:
		heli_flight.depart_at = heli_t
		heli_departs.rpc(heli_t)
		var ids := []
		for id: int in players:
			if players[id].boarded:
				ids.append(id)
		hooks.on_heli_departed(ids)


@rpc("authority", "call_remote", "reliable")
func heli_boarded() -> void:
	if heli != null:
		local_player.seat = heli.seat


## A downed teammate reaches out when you, standing, come within `Config.REACH_RANGE`.
func update_reach() -> void:
	var me := local_player.status
	var standing := not me.downed and not me.dead
	for id: int in remotes:
		var r: RemotePlayer = remotes[id]
		r.helper_near = standing and r.global_position.distance_to(local_player.global_position) <= Config.REACH_RANGE


## Holding use beside a downed teammate gets them up: say so to the host once, and again when you let go.
func _update_revive(holding: bool, target: int) -> void:
	if holding:
		local_player.aim_blocked = true
		if _reviving == 0 and not local_player.status.is_using():
			_reviving = target
			if is_host:
				start_revive(my_id, target)
			else:
				client_revive.rpc_id(1, target, true)
	elif _reviving != 0:
		if is_host:
			if (players[my_id].status as PlayerStatus).using == &"revive":
				cancel_use(my_id)
		else:
			client_revive.rpc_id(1, _reviving, false)
		_reviving = 0


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
	lp.view.visible = not through_scope and not lp.hide_view and not lp.status.dead
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
	_own_shots += 1
	var streak := _own_shots % Config.TRACER_OWN_EVERY == 0 # a clean view: only some of your own
	if streak or d.scoped: # (a sniper's vapour line shows every time)
		tracers.fire(lp.view.muzzle_world(), _bullet_end(origin, dir, float(d.range)), lp.weapons.current, streak)
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


