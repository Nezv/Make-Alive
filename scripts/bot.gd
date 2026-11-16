class_name Bot
extends RefCounted
## The test player: `--bot`, and the bot playtests in tests/test_bot_scenarios.gd.
## It aims at the nearest zombie it can see and holds the trigger; given a goal it also walks
## there along the map's navigation, opens doors in its way, and stands its ground (or backs off)
## while zombies are close. It plays through the same entry points a person does.
##
## A scenario is data: { name, map, mission, seed, goal_zone, hordes, spawn, aim, time_limit, expect }.
##   spawn       zombies already on their way when it starts
##   aim         where it shoots: chest, head, legs or arms
##   goal_zone   a zone id from the map's data: the bot walks into it
##   time_limit  game seconds before the run is called "timeout"
##   expect      "reached" (it must get there) or "survived" (it must simply not die)
## `run` plays one and reports { outcome, seconds, kills, at, note }.

const SCENARIOS := [
	{ "name": "corridor: cross the map with the director running", "map": "corridor", "mission": "", "seed": 7,
		"goal_zone": "exit", "hordes": true, "aim": "head", "time_limit": 90.0, "expect": "reached" },
	{ "name": "corridor: hold the spawn against a horde", "map": "corridor", "mission": "", "seed": 3,
		"goal_zone": "", "hordes": true, "aim": "head", "time_limit": 40.0, "expect": "survived" },
]

var game: Game
var goal := Vector3.INF      ## where to walk (INF = stay put)
var goal_zone := ""          ## if set, arriving means being inside this zone
var arrived := false
var stuck_for := 0.0         ## seconds spent trying to move without getting anywhere
var _door_wait := 0.0
var _progress_from := Vector3.ZERO
var _progress_t := 0.0


func _init(owner_game: Game) -> void:
	game = owner_game


## Walk into zone `id` of the map's data.
func go_to_zone(id: String) -> void:
	goal_zone = id
	goal = game.map.data.zone_center(id)
	goal.y = game.map.ground_y(goal)
	arrived = false


func step(delta: float) -> void:
	var lp := game.local_player
	var me := lp.global_position
	var threat := _aim(me)
	lp.bot_move = Vector3.ZERO
	lp.bot_sprint = false
	if goal == Vector3.INF or arrived:
		return
	if (goal_zone != "" and game.map.data.zone_contains(goal_zone, me + Vector3(0, 0.5, 0))) \
			or (goal_zone == "" and me.distance_to(goal) < Config.BOT_ARRIVE_DIST):
		arrived = true
		return
	_door_wait -= delta
	var way := game.map.nav_target(me, goal) - me
	way.y = 0.0
	# A closed door a few steps ahead: open it from here and wait, rather than walk into a door
	# that swings toward us.
	var door: Door = null
	for ahead: float in [0.0, 1.0, 2.0]:
		if door == null:
			door = game.map.door_in_the_way(me + way.normalized() * ahead, goal)
	if door != null:
		if _door_wait <= 0.0:
			game.interact_with(door)
			_door_wait = Config.BOT_DOOR_RETRY
		way = Vector3.ZERO
	if threat < Config.BOT_RETREAT_DIST and door == null:
		lp.bot_move = -way.normalized() # too close: give ground while shooting
	elif threat > Config.BOT_HOLD_DIST and way.length() > 0.05:
		lp.bot_move = way.normalized()
		lp.bot_sprint = threat == INF
	# Between the two distances it stands and shoots.
	_watch_progress(delta, me, lp.bot_move != Vector3.ZERO and threat == INF)


## Aim at the nearest zombie in sight and hold the trigger. Returns its distance (INF = none).
func _aim(me: Vector3) -> float:
	var lp := game.local_player
	var best: Zombie = null
	var best_d := Config.BOT_SIGHT
	for z: Zombie in game.zombies.values():
		var d := me.distance_to(z.global_position)
		if d < best_d and game.map.is_direct(me, z.global_position):
			best_d = d
			best = z
	lp.firing = best != null and game.bot_fires
	if best == null:
		if lp.bot_move != Vector3.ZERO: # nothing to shoot: look where we walk
			lp.yaw = atan2(-lp.bot_move.x, -lp.bot_move.z)
			lp.pitch = 0.0
		return INF
	var eye := me + Vector3(0, Config.EYE_HEIGHT, 0)
	var aim := best.rig.spine.global_position + Vector3(0, 0.3, 0)
	match game.bot_aim:
		"head": aim = best.rig.neck.global_position + Vector3(0, 0.15, 0)
		"legs": aim = (best.rig.knee_l if not best.rig.is_severed(Humanoid.Part.LEG_L) else best.rig.knee_r).global_position
		"arms": aim = (best.rig.elbow_l if not best.rig.is_severed(Humanoid.Part.ARM_L) else best.rig.elbow_r).global_position
	var to := aim - eye
	lp.yaw = atan2(-to.x, -to.z)
	lp.pitch = atan2(to.y, Vector2(to.x, to.z).length())
	return best_d


func _watch_progress(delta: float, me: Vector3, trying: bool) -> void:
	if not trying or me.distance_to(_progress_from) > Config.BOT_STUCK_DIST:
		_progress_from = me
		_progress_t = 0.0
		stuck_for = 0.0
		return
	_progress_t += delta
	stuck_for = _progress_t


## Play `scenario` in a fresh Game under `host` (a node in the tree) at accelerated time.
## Returns { outcome: "reached" | "survived" | "died" | "stuck" | "timeout", seconds, kills, at, note }.
static func run(host: Node, scenario: Dictionary) -> Dictionary:
	seed(scenario.seed) # zombie speeds, lanes and staggers come from the global generator
	var g := Game.new()
	g.bot = true
	g.map_name = scenario.map
	g.mission = scenario.mission
	g.bot_aim = scenario.get("aim", "chest")
	host.add_child(g)
	g.start_host("Bot")
	g.rng.seed = scenario.seed
	g.director.enabled = scenario.hordes
	if scenario.get("spawn", 0) > 0:
		g.director.spawn_horde(scenario.spawn)
	var died := [false]
	g.hooks.fired.connect(func(hook: StringName, _args: Array) -> void:
		if hook == &"on_player_died":
			died[0] = true)
	var zone: String = scenario.goal_zone
	if zone != "":
		g.brain.go_to_zone(zone)
	var tree := host.get_tree()
	var before := Engine.time_scale
	var steps_before := Engine.max_physics_steps_per_frame
	Engine.time_scale = Config.BOT_TIME_SCALE
	Engine.max_physics_steps_per_frame = int(Config.BOT_TIME_SCALE) * 2
	var t := 0.0
	var outcome := "timeout"
	var limit: float = scenario.time_limit
	while t < limit:
		await tree.physics_frame
		t = g._now # the host's own clock: game seconds, however fast they are being played
		if died[0]:
			outcome = "died"
			break
		if g.brain.arrived:
			outcome = "reached"
			break
		if g.brain.stuck_for > Config.BOT_STUCK_SECONDS:
			outcome = "stuck"
			break
	if outcome == "timeout" and zone == "":
		outcome = "survived" # nowhere to go: lasting the time is the point
	Engine.time_scale = before
	Engine.max_physics_steps_per_frame = steps_before
	var at := g.local_player.global_position
	var result := { "outcome": outcome, "seconds": t, "kills": g.players[1].kills, "at": at,
		"note": "%s after %.1f s at (%.1f, %.1f, %.1f), %d kills, %d zombies alive, %d HP" % [outcome, t, at.x, at.y, at.z,
			g.players[1].kills, g.zombies.size(), (g.players[1].health as Health).hp] }
	g.free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return result
