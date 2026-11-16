extends TestCase
## Bot playtests: the bot plays whole scenarios at accelerated time. If a map change walls off the
## way out, or a tuning change makes a horde unbeatable, one of these says where it went wrong.


func before_each() -> void:
	Engine.time_scale = Config.BOT_TIME_SCALE # walking a corridor in real time would take all day
	Engine.max_physics_steps_per_frame = int(Config.BOT_TIME_SCALE) * 2


func after_each() -> void:
	Engine.time_scale = 1.0
	Engine.max_physics_steps_per_frame = 8


func test_bot_walks_to_a_zone_and_opens_the_door_on_the_way() -> void:
	var g := await new_game()
	g.bot = true
	g.local_player.bot = true
	g.brain = Bot.new(g)
	assert_false(g.door.is_open)
	g.brain.go_to_zone("exit")
	var there := await wait_until(func(): return g.brain.arrived, 30.0)
	assert_true(there, "reached the exit zone; it is at %s" % g.local_player.global_position)
	assert_true(g.door.is_open, "it opened the door itself")
	assert_true(g.map.data.zone_contains("exit", g.local_player.global_position + Vector3(0, 0.5, 0)))
	assert_eq(g.local_player.bot_move, Vector3.ZERO, "and stopped")


func test_bot_stands_and_shoots_what_blocks_it() -> void:
	var g := await new_game()
	g.bot = true
	g.local_player.bot = true
	g.brain = Bot.new(g)
	g.brain.go_to_zone("corner")
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 16))
	z.speed = 0.0 # a zombie that just stands in the way...
	z.hp = 1000000 # ...and takes a while to drop
	await wait_until(func(): return g.local_player.global_position.distance_to(z.global_position) < Config.BOT_HOLD_DIST, 10.0)
	await frames(30)
	var gap := g.local_player.global_position.distance_to(z.global_position)
	assert_true(g.local_player.firing, "shooting at it")
	assert_eq(g.local_player.bot_move, Vector3.ZERO, "standing its ground")
	assert_gt(gap, Config.BOT_RETREAT_DIST, "at a safe distance")
	assert_lt(gap, Config.BOT_HOLD_DIST + 0.5)
	z.hp = 1
	var there := await wait_until(func(): return g.brain.arrived, 30.0)
	assert_true(there, "killed it and carried on to the corner")
	assert_eq(g.players[1].kills, 1)


func test_bot_reloads_when_the_magazine_is_empty() -> void:
	var g := await new_game()
	g.bot = true
	g.local_player.bot = true
	g.brain = Bot.new(g)
	var ws := g.local_player.weapons
	ws.ammo[ws.current] = 1
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 12))
	z.speed = 0.0
	z.hp = 100000
	var reloading := await wait_until(func(): return ws.is_reloading(), 5.0)
	assert_true(reloading, "one round left: it fires it and reloads")


func test_bot_reports_being_stuck() -> void:
	var g := await new_game()
	g.bot = true
	g.local_player.bot = true
	g.brain = Bot.new(g)
	g.brain.goal = Vector3(0, 0, 60) # through the end wall of leg A
	var stuck := await wait_until(func(): return g.brain.stuck_for > 1.0, 15.0)
	assert_true(stuck, "walking into a wall counts as stuck")
	assert_false(g.brain.arrived)


func test_scenarios_play_out_as_expected() -> void:
	Engine.time_scale = 1.0 # Bot.run speeds time up itself, and must put it back
	var started := Time.get_ticks_msec()
	for s: Dictionary in Bot.SCENARIOS:
		var result: Dictionary = await Bot.run(self, s)
		print("[bot] %s: %s" % [s.name, result.note])
		assert_eq(result.outcome, s.expect, "%s: %s" % [s.name, result.note])
	assert_near(Engine.time_scale, 1.0, 0.001, "time runs normally again afterwards")
	assert_lt((Time.get_ticks_msec() - started) / 1000.0, 20.0, "all scenarios together stay under 20 s")
