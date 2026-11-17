extends TestCase
## Death and spectating: how the dead come back (at once, after a timer, at the next checkpoint, or
## never, from the map's data), what a dead player can no longer do, and the spectator who follows
## the living with a smoothed third-person camera.

const HERE := Vector3(0, 0.1, 26)


## Players 1 and 7 side by side; `respawn` true / after seconds / at a checkpoint / never.
func _game(respawn := false, after := -1.0, at_checkpoint := false) -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	g.rules.respawn = respawn
	g.rules.respawn_after = after
	g.rules.respawn_checkpoint = at_checkpoint
	g.players[1].pos = HERE
	g.players[7].pos = HERE + Vector3(1, 0, 0)
	return g


func _status(g: Game, id: int) -> PlayerStatus:
	return g.players[id].status


# --- The rules from the map's data ----------------------------------------------------

func test_a_map_says_how_the_dead_come_back() -> void:
	var now := MapData.new({ "respawn": true })
	assert_true(now.respawn)
	var never := MapData.new({ "respawn": false })
	assert_false(never.respawn)
	assert_eq(never.respawn_after, -1.0)
	assert_false(never.respawn_checkpoint)
	var timed := MapData.new({ "respawn": 25.0 })
	assert_false(timed.respawn)
	assert_eq(timed.respawn_after, 25.0)
	var checkpoint := MapData.new({ "respawn": "checkpoint" })
	assert_false(checkpoint.respawn)
	assert_true(checkpoint.respawn_checkpoint)
	assert_eq(MapData.new({}).respawn, true, "by default at once")
	assert_eq(MapData.new({}).errors.size(), 0)
	assert_gt(MapData.new({ "respawn": "someday" }).errors.size(), 0, "anything else is a mistake in the data")
	assert_gt(MapData.new({ "respawn": -3.0 }).errors.size(), 0)


func test_the_rules_take_them_when_the_mission_starts() -> void:
	var g := await new_game()
	g.rules.start([], false, 12.0, false)
	assert_false(g.rules.respawn)
	assert_eq(g.rules.respawn_after, 12.0)
	g.rules.start([], false, -1.0, true)
	assert_true(g.rules.respawn_checkpoint)
	g.rules.start([], true)
	assert_true(g.rules.respawn)
	assert_eq(g.rules.respawn_after, -1.0)


# --- Dead ------------------------------------------------------------------------------

func test_the_dead_are_out_and_can_do_nothing() -> void:
	var g := await _game()
	var calls := spy(g)
	g.give_item(1, Inventory.MEDKIT)
	g.kill_player(1)
	assert_true(_status(g, 1).dead)
	assert_true(g.rules.out.has(1))
	assert_true(g.local_player.status.dead, "and their own game knows")
	assert_eq(count(calls, &"on_player_died"), 1)
	g._queue_shot(1, HERE, Vector3.FORWARD, Weapons.P19)
	assert_eq(g._pending_shots.size(), 0)
	assert_eq(g.host_shove(1, HERE, Vector3.FORWARD), 0)
	g.local_player.teleport(g.lootbox.global_position + Vector3(-1.5, 0.1, 0))
	g.players[1].pos = g.local_player.global_position
	assert_false(g.host_interact(1, g.lootbox.iid))
	assert_false(g.use_item(1, Inventory.FRAG))
	var hp: int = g.players[1].health.hp
	g.damage_player(1, 50)
	assert_eq(g.players[1].health.hp, hp, "nothing left to hurt")
	assert_true(g.build_snapshot()[0][0].action & PlayerWire.ACTION_DEAD != 0, "everyone else can tell")


func test_with_respawn_on_the_dead_come_straight_back() -> void:
	var g := await _game(true)
	var calls := spy(g)
	g.kill_player(1)
	assert_false(_status(g, 1).dead)
	assert_false(g.rules.out.has(1))
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP)
	assert_eq(count(calls, &"on_player_respawned"), 1)


func test_a_timer_brings_them_back_at_the_spawn() -> void:
	var g := await _game(false, 5.0)
	var calls := spy(g)
	g.kill_player(1)
	assert_true(_status(g, 1).dead)
	assert_near(_status(g, 1).respawn_left, 5.0, 0.001)
	assert_near(g.local_player.status.respawn_left, 5.0, 0.001, "they can count it down")
	g.players[1].pos = Vector3(40, 0.1, 0) # where they fell
	g.tick_status(4.9)
	assert_true(_status(g, 1).dead)
	g.tick_status(0.2)
	assert_false(_status(g, 1).dead)
	assert_false(g.rules.out.has(1))
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP)
	assert_eq(g.players[1].pos, g.map.player_spawn_point(g.players[1].slot), "back at the start")
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_player_respawned").map(func(c: Array) -> Array: return c[1]), [[1, "respawn"]])
	assert_false(g.local_player.status.dead)


func test_at_a_checkpoint_mission_the_dead_wait_for_the_next_checkpoint() -> void:
	var g := await _game(false, -1.0, true)
	g.kill_player(1)
	assert_true(_status(g, 1).respawn_checkpoint, "so the screen can say so")
	g.tick_status(1000.0)
	assert_true(_status(g, 1).dead, "no timer")
	g.hooks.on_checkpoint_reached("corner")
	assert_false(_status(g, 1).dead)
	assert_false(g.rules.out.has(1))


func test_with_no_way_back_they_stay_out_and_the_last_death_loses_the_mission() -> void:
	var g := await _game()
	g.kill_player(1)
	g.tick_status(100000.0)
	assert_true(_status(g, 1).dead)
	assert_true(g.rules.running())
	g.kill_player(7)
	assert_eq(g.rules.status, MissionRules.Status.FAILED)


func test_a_dead_player_who_respawns_starts_clean() -> void:
	var g := await _game(false, 1.0)
	g.give_item(1, Inventory.BANDAGE)
	g.kill_player(1)
	g.tick_status(1.5)
	assert_true(g.players[1].inventory.is_empty(), "what they had is in the backpack where they fell")
	assert_false(_status(g, 1).downed)


# --- The spectator ---------------------------------------------------------------------

func test_the_spectator_follows_one_of_the_living_and_cycles_through_them() -> void:
	var sp := Spectator.new()
	assert_eq(sp.target, 0)
	sp.update([])
	assert_eq(sp.target, 0, "nobody to follow")
	sp.update([3, 7, 9])
	assert_eq(sp.target, 3, "the first of them")
	sp.cycle([3, 7, 9], 1)
	assert_eq(sp.target, 7)
	sp.cycle([3, 7, 9], 1)
	sp.cycle([3, 7, 9], 1)
	assert_eq(sp.target, 3, "round again")
	sp.cycle([3, 7, 9], -1)
	assert_eq(sp.target, 9, "and the other way")
	sp.update([3, 7, 9])
	assert_eq(sp.target, 9, "kept while they are still there")
	sp.update([3, 7])
	assert_eq(sp.target, 3, "they fell: the next one")
	sp.update([])
	assert_eq(sp.target, 0)
	sp.cycle([5], 1)
	assert_eq(sp.target, 5, "cycling picks someone when there was nobody")


func test_the_camera_sits_behind_and_above_the_one_followed_and_eases_there() -> void:
	var goal := Spectator.camera_goal(Vector3(10, 0, 20), 0.0) # facing -Z: the camera is on the +Z side
	assert_near(goal.x, 10.0, 0.001)
	assert_near(goal.z, 20.0 + Config.SPECTATE_BACK, 0.001)
	assert_near(goal.y, Config.SPECTATE_HEIGHT, 0.001)
	var turned := Spectator.camera_goal(Vector3.ZERO, PI / 2.0) # facing -X: behind them is +X
	assert_near(turned.x, Config.SPECTATE_BACK, 0.001)
	assert_near(turned.z, 0.0, 0.001)
	var at := Vector3(0, 5, 0)
	var last := at.distance_to(goal)
	for i in 120:
		at = Spectator.follow(at, goal, 1.0 / 60.0)
		var d := at.distance_to(goal)
		assert_true(d <= last + 0.0001, "never away from it")
		last = d
	assert_lt(last, 0.5, "there within two seconds")
	assert_gt(Spectator.follow(Vector3.ZERO, Vector3(10, 0, 0), 0.01).x, 0.0)
	assert_lt(Spectator.follow(Vector3.ZERO, Vector3(10, 0, 0), 0.01).x, 10.0, "a step, not a jump")


func test_with_nobody_to_follow_the_camera_pulls_back_and_orbits_the_body() -> void:
	var center := Vector3(4, 0, 4)
	var a := Spectator.orbit_goal(center, 0.0)
	var b := Spectator.orbit_goal(center, 3.0)
	assert_near(Vector2(a.x - center.x, a.z - center.z).length(), Config.SPECTATE_ORBIT_RADIUS, 0.001)
	assert_near(Vector2(b.x - center.x, b.z - center.z).length(), Config.SPECTATE_ORBIT_RADIUS, 0.001)
	assert_gt(a.distance_to(b), 0.1, "slowly round")
	assert_gt(a.y, center.y + 1.0, "from above")


# --- In a match ------------------------------------------------------------------------

func test_a_dead_players_body_stays_put_and_cannot_shove() -> void:
	var g := await _game()
	var lp := g.local_player
	g.kill_player(1)
	assert_false(lp.try_shove())
	lp.bot = true
	lp.bot_move = Vector3(0, 0, -1)
	await frames(8)
	assert_lt(lp.move_speed, 0.01, "no walking about as a ghost")


func test_the_dead_cycle_through_the_living_with_the_fire_and_aim_buttons() -> void:
	var g := await _game()
	var lp := g.local_player
	g.kill_player(1)
	lp.spectate_candidates = [3, 7, 9]
	lp.spectator.update(lp.spectate_candidates)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	lp.handle_event(click)
	assert_eq(lp.spectator.target, 7, "fire: the next one")
	assert_true(lp.fire_buffer <= 0.0, "and no shot")
	var aim := InputEventMouseButton.new()
	aim.button_index = MOUSE_BUTTON_RIGHT
	aim.pressed = true
	lp.handle_event(aim)
	assert_eq(lp.spectator.target, 3, "aim: the one before")


func test_who_can_be_followed_is_whoever_is_standing_as_this_peer_sees_them() -> void:
	var g := await _game()
	g.kill_player(1) # this peer's player is dead; 7 (and a third and a fourth) are the others
	var standing := { "id": 7, "pos": HERE, "yaw": 0.0, "hp": 80, "kills": 0, "weapon": Weapons.AK47, "action": 0 }
	var downed := { "id": 8, "pos": HERE, "yaw": 0.0, "hp": 0, "kills": 0, "weapon": 0, "action": PlayerWire.ACTION_DOWNED }
	var gone := { "id": 9, "pos": HERE, "yaw": 0.0, "hp": 0, "kills": 0, "weapon": 0, "action": PlayerWire.ACTION_DEAD }
	var me := { "id": 1, "pos": HERE, "yaw": 0.0, "hp": 0, "kills": 0, "weapon": 0, "action": PlayerWire.ACTION_DEAD }
	g._apply_snapshot([me, standing, downed, gone], [])
	assert_eq(g.spectate_candidates(), [7], "not the downed, not the dead")
	assert_false((g.remotes[9] as RemotePlayer).visible, "a dead player is not left standing about")
	assert_true((g.remotes[7] as RemotePlayer).visible)
	g._update_spectating(0.016)
	assert_eq(g.local_player.spectator.target, 7)
	var text := g.spectate_text()
	assert_true(text.contains("Guest") and text.contains("80"), text)


func test_the_screen_says_when_you_are_coming_back() -> void:
	var timed := await _game(false, 20.0)
	timed.kill_player(1)
	assert_true(timed.spectate_text().contains("Respawn in 20"), timed.spectate_text())
	var checkpoint := await _game(false, -1.0, true)
	checkpoint.kill_player(1)
	assert_true(checkpoint.spectate_text().contains("checkpoint"), checkpoint.spectate_text())
	var never := await _game()
	never.kill_player(1)
	assert_true(never.spectate_text().contains("out"), never.spectate_text())
	var alive := await _game()
	assert_eq(alive.spectate_text(), "", "nothing while you are playing")


# --- The body, the arrival, and what the dead can still do ----------------------------

func test_a_dead_player_leaves_a_body_and_zombies_near_it_go_and_feed() -> void:
	var g := await _game()
	g.players[7].pos = HERE + Vector3(60, 0, 0) # the other one far off
	var near := g.spawn_zombie(Zombie.Type.WALKER, HERE + Vector3(0, 0, 5))
	var far := g.spawn_zombie(Zombie.Type.WALKER, HERE + Vector3(0, 0, Config.FEED_RANGE + 8))
	var before: int = g.gore.stats.ragdolls
	g.kill_player(1)
	assert_eq(g.gore.stats.ragdolls, before + 1, "a body on the floor")
	assert_true(near.investigating(), "the near one smells it")
	assert_false(far.investigating(), "too far to care")
	for i in 900:
		near.host_step(1.0 / 60.0, g)
		if near.state == Zombie.State.FEED:
			break
	assert_eq(near.state, Zombie.State.FEED, "down on the body")
	assert_eq(near._anim_for_state(), Humanoid.Anim.FEED)
	var wire := ZombieWire.unpack(ZombieWire.pack([{ "zid": 3, "pos": HERE, "yaw": 0.0, "state": Zombie.State.FEED, "type": 0, "mask": 0 }]))
	assert_eq(wire[0].state, Zombie.State.FEED, "and every peer sees it")
	g.players[7].pos = near.global_position + Vector3(2, 0, 0)
	near.host_step(1.0 / 60.0, g)
	assert_eq(near.state, Zombie.State.CHASE, "someone alive comes close: the meal can wait")


func test_the_dead_see_the_magazine_of_whoever_they_watch() -> void:
	assert_eq(PlayerWire.BYTES_EACH, 24)
	var out := PlayerWire.unpack(PlayerWire.pack([{ "id": 7, "pos": HERE, "yaw": 0.0, "hp": 80, "kills": 0, "weapon": Weapons.AK47, "action": 0, "mag": 17 }]))
	assert_eq(out[0].mag, 17)
	var g := await _game()
	var lp := g.local_player
	lp.weapons.ammo[lp.weapons.current] = 9
	g._record_own_player()
	assert_eq(g.build_snapshot()[0][0].mag, 9, "the host's own magazine")
	g.kill_player(1)
	var standing := { "id": 7, "pos": HERE, "yaw": 0.0, "hp": 80, "kills": 0, "weapon": Weapons.AK47, "action": 0, "mag": 17 }
	g._apply_snapshot([standing], [])
	g._update_spectating(0.016)
	var text := g.spectate_text()
	assert_true(text.contains("17"), text)


func test_coming_back_is_a_drop_from_a_truck_bed_not_a_pop() -> void:
	var g := await _game(false, 5.0)
	var lp := g.local_player
	var standing := lp.view_height()
	g.kill_player(1)
	var played: int = g.fx.stats.played
	g.tick_status(5.1)
	assert_false(lp.status.dead, "back")
	assert_eq(g.fx.last_kind, Fx.Kind.ARRIVAL, "dust where they land, on every peer")
	assert_gt(g.fx.stats.played, played)
	assert_gt(lp.view_height(), standing + Config.ARRIVE_DROP * 0.9, "the view starts up on the truck bed")
	lp.step_arrival(Config.ARRIVE_TIME * 0.5)
	assert_true(lp.view_height() > standing and lp.view_height() < standing + Config.ARRIVE_DROP, "dropping")
	lp.step_arrival(Config.ARRIVE_TIME)
	assert_near(lp.view_height(), standing, 0.01, "on the ground")


func test_anyone_dead_or_alive_can_chat_and_everyone_reads_it() -> void:
	var g := await _game()
	var calls := spy(g)
	g.kill_player(1)
	assert_true(g.host_chat(1, "  behind you!  "), "the dead can talk")
	assert_true(g.hud.chat_lines()[-1].ends_with(": behind you!"), str(g.hud.chat_lines()))
	assert_true(g.hud.chat_lines()[-1].begins_with(g.player_name(1)))
	assert_false(g.host_chat(7, "   "), "nothing to say")
	assert_true(g.host_chat(7, "x".repeat(500)))
	assert_true(g.hud.chat_lines()[-1].length() <= g.player_name(7).length() + 2 + Config.CHAT_MAX_CHARS, "cut short")
	assert_eq(count(calls, &"on_chat"), 2)
	g.say("on my way")
	assert_true(g.hud.chat_lines()[-1].ends_with("on my way"), "your own line goes through the host too")


func test_a_ping_marks_a_spot_for_everyone_for_a_while_and_the_dead_can_ping() -> void:
	var g := await _game()
	var calls := spy(g)
	g.kill_player(1)
	var spot := HERE + Vector3(3, 0, 3)
	assert_true(g.host_ping(1, spot))
	assert_eq(g.pings.size(), 1)
	assert_lt((g.pings[1].node as Node3D).global_position.distance_to(spot), 0.01)
	g.host_ping(1, HERE + Vector3(-3, 0, 0))
	assert_eq(g.pings.size(), 1, "one each: a new one replaces the old")
	g.host_ping(7, HERE)
	assert_eq(g.pings.size(), 2)
	g.step_pings(Config.PING_TIME * 0.5)
	assert_eq(g.pings.size(), 2)
	g.step_pings(Config.PING_TIME)
	assert_eq(g.pings.size(), 0, "gone after a while")
	assert_eq(count(calls, &"on_ping"), 3)
	assert_true(InputMap.has_action("chat") and InputMap.has_action("ping"))
