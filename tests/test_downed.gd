extends TestCase
## Downed and revive: at 0 HP a player with a teammate still standing is downed (crawling, pistol only,
## bleeding out) instead of dead; a teammate holding use beside them gets them up; zombies go for the
## standing first and finish the downed when nobody else is near; everyone out at once loses the mission.

const I := preload("res://scripts/inventory.gd")
const HERE := Vector3(0, 0.1, 26)


## Players 1 (the host's own) and 7 standing side by side, physics loop off (the tests tick by hand).
func _two() -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	g._add_player(7, "Guest")
	g.players[1].pos = HERE
	g.players[7].pos = HERE + Vector3(1.0, 0, 0)
	return g


func _status(g: Game, id: int) -> PlayerStatus:
	return g.players[id].status


func _zombie(g: Game, at := Vector3(0, 0.1, 5)) -> Zombie:
	return g.spawn_zombie(Zombie.Type.WALKER, at)


# --- Going down -----------------------------------------------------------------------

func test_at_zero_hp_with_a_teammate_standing_a_player_goes_down_instead_of_dying() -> void:
	var g := await _two()
	var calls := spy(g)
	g.give_item(1, I.MEDKIT)
	g.damage_player(1, 9999)
	assert_true(_status(g, 1).downed)
	assert_eq(g.players[1].health.hp, 0)
	assert_true(g.rules.out.has(1), "down means out of the fight for the mission rules")
	assert_eq(count(calls, &"on_player_downed"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_player_downed")[0][1], [1])
	assert_eq(count(calls, &"on_player_died"), 0)
	assert_near(_status(g, 1).down_left, Config.DOWNED_TIME, 0.001)
	assert_true(g.local_player.status.downed, "and the player knows")
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 1, "they keep what they carry while there is hope")
	assert_eq(g.interactables.values().filter(func(it) -> bool: return it is Backpack).size(), 0)


func test_the_last_one_standing_just_dies() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.damage_player(1, 9999)
	assert_eq(count(calls, &"on_player_downed"), 0, "nobody could get them up")
	assert_eq(count(calls, &"on_player_died"), 1)


func test_when_the_last_standing_falls_and_the_dead_stay_dead_the_mission_is_lost() -> void:
	var g := await _two()
	g.rules.respawn = false
	g.damage_player(7, 9999) # down
	assert_true(_status(g, 7).downed)
	g.damage_player(1, 9999) # nobody left to get them up
	assert_eq(g.rules.status, MissionRules.Status.FAILED)
	assert_eq(g.rules.reason, "everyone is down")


func test_going_down_stops_the_bleeding_and_the_healing() -> void:
	var g := await _two()
	g.give_item(1, I.BANDAGE)
	g.damage_player(1, 20, _zombie(g), 0.0)
	g.use_item(1, I.BANDAGE)
	g.damage_player(1, 9999)
	assert_eq(_status(g, 1).bleed, 0, "the bleeding is the bleed-out timer now")
	assert_false(_status(g, 1).is_using())


# --- Bleeding out ---------------------------------------------------------------------

func test_a_downed_player_bleeds_out_and_dies_if_nobody_comes() -> void:
	var g := await _two()
	var calls := spy(g)
	g.give_item(1, I.PLANK, 3)
	g.damage_player(1, 9999)
	g.tick_status(Config.DOWNED_TIME - 1.0)
	assert_true(_status(g, 1).downed)
	assert_near(_status(g, 1).down_left, 1.0, 0.01)
	assert_eq(count(calls, &"on_player_died"), 0)
	g.tick_status(2.0)
	assert_eq(count(calls, &"on_player_died"), 1)
	assert_false(_status(g, 1).downed, "the next life starts standing")
	assert_false(g.rules.out.has(1), "and in the fight (the corridor lets the dead come back)")
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP)
	var packs: Array = g.interactables.values().filter(func(it) -> bool: return it is Backpack)
	assert_eq(packs.size(), 1, "what they carried is lying where they fell")


func test_damage_to_a_downed_player_shortens_the_bleed_out_and_can_finish_them() -> void:
	var g := await _two()
	var calls := spy(g)
	var z := _zombie(g)
	g.damage_player(1, 9999)
	g.damage_player(1, 10, z, 0.0)
	assert_near(_status(g, 1).down_left, Config.DOWNED_TIME - 10 * Config.DOWNED_DAMAGE_SECONDS, 0.001)
	assert_eq(_status(g, 1).bleed, 0, "no wounds on top of being down")
	assert_eq(count(calls, &"on_player_died"), 0)
	g.damage_player(1, 100000, z, 0.0)
	assert_eq(count(calls, &"on_player_died"), 1, "finished off")


# --- What a downed player cannot do ----------------------------------------------------

func test_a_downed_player_can_only_shoot_the_pistol_and_cannot_use_or_shove() -> void:
	var g := await _two()
	g.give_item(1, I.BANDAGE)
	g.give_item(1, I.FRAG)
	g.damage_player(1, 9999)
	g.damage_player(7, 0) # (nothing)
	assert_false(g.can_use_item(1, I.FRAG), "no throwing from the floor")
	g.give_item(1, I.PAINKILLERS)
	assert_false(g.use_item(1, I.PAINKILLERS))
	g._queue_shot(1, HERE, Vector3.FORWARD, Weapons.AK47)
	assert_eq(g._pending_shots.size(), 0, "a rifle is out of reach")
	g._queue_shot(1, HERE, Vector3.FORWARD, Weapons.P19)
	assert_eq(g._pending_shots.size(), 1, "the pistol is not")
	assert_eq(g.host_shove(1, HERE, Vector3.FORWARD), 0)
	g.local_player.teleport(g.lootbox.global_position + Vector3(-1.5, 0.1, 0))
	g.players[1].pos = g.local_player.global_position
	assert_false(g.host_interact(1, g.lootbox.iid), "and nothing to open")
	assert_false(g.lootbox.opened)


func test_the_local_player_crawls_with_the_pistol_and_cannot_sprint_jump_or_shove() -> void:
	var g := await _two()
	var lp := g.local_player
	lp.switch_weapon(Weapons.AK47)
	g.damage_player(1, 9999)
	await frames(2)
	assert_eq(lp.weapons.current, Weapons.P19, "the sidearm came out by itself")
	lp.switch_weapon(Weapons.AK47)
	assert_eq(lp.weapons.current, Weapons.P19, "and stays")
	assert_false(lp.try_shove())
	lp.bot = true
	lp.bot_move = Vector3(0, 0, -1)
	lp.bot_sprint = true
	await frames(10)
	assert_near(lp.move_speed, Config.DOWNED_SPEED, 0.15, "a crawl, sprint or not")


# --- Reviving -------------------------------------------------------------------------

func test_holding_use_beside_a_downed_teammate_gets_them_up_after_the_revive_time() -> void:
	var g := await _two()
	var calls := spy(g)
	g.damage_player(1, 9999)
	assert_true(g.start_revive(7, 1))
	assert_eq(_status(g, 7).using, &"revive")
	assert_near(_status(g, 7).use_left, Config.REVIVE_SECONDS, 0.001)
	assert_near(_status(g, 1).revive_left, Config.REVIVE_SECONDS, 0.001, "the downed one sees it too")
	g.tick_status(Config.REVIVE_SECONDS * 0.5)
	assert_true(_status(g, 1).downed)
	g.tick_status(Config.REVIVE_SECONDS * 0.6)
	assert_false(_status(g, 1).downed)
	assert_eq(g.players[1].health.hp, Config.REVIVE_HP, "up, but hurt")
	assert_false(g.rules.out.has(1))
	assert_false(_status(g, 7).is_using())
	assert_eq(_status(g, 1).revive_left, 0.0)
	assert_eq(count(calls, &"on_player_revived"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_player_revived")[0][1], [1, 7])
	assert_eq(g.score.get_stat(7, "revives"), 1)
	assert_false(g.local_player.status.downed)


func test_a_revived_player_is_safe_for_a_moment() -> void:
	var g := await _two()
	g.damage_player(1, 9999)
	g.start_revive(7, 1)
	g.tick_status(Config.REVIVE_SECONDS + 0.1)
	g.damage_player(1, 50, _zombie(g), 0.0)
	assert_eq(g.players[1].health.hp, Config.REVIVE_HP, "the hit did nothing")
	g.tick_status(Config.REVIVE_INVULN + 0.1)
	g.damage_player(1, 10)
	assert_eq(g.players[1].health.hp, Config.REVIVE_HP - 10)


func test_only_a_standing_player_in_reach_can_start_a_revive() -> void:
	var g := await _two()
	assert_false(g.start_revive(7, 1), "they are not down")
	g.damage_player(1, 9999)
	assert_false(g.start_revive(1, 1), "not yourself")
	g.players[7].pos = HERE + Vector3(30, 0, 0)
	assert_false(g.start_revive(7, 1), "too far")
	g.players[7].pos = HERE + Vector3(1, 0, 0)
	g._add_player(8, "Third")
	g.players[8].pos = HERE + Vector3(0, 0, 1)
	assert_true(g.start_revive(7, 1))
	assert_false(g.start_revive(8, 1), "somebody is already on it")
	assert_false(g.start_revive(7, 99), "nobody by that id")
	assert_false(g.start_revive(99, 1))


func test_a_downed_player_cannot_revive_anyone() -> void:
	var g := await _two()
	g._add_player(8, "Third")
	g.players[8].pos = HERE + Vector3(0, 0, 1)
	g.damage_player(1, 9999)
	g.damage_player(7, 9999)
	assert_true(_status(g, 7).downed)
	assert_false(g.start_revive(7, 1))


func test_a_hit_on_the_reviver_interrupts_it() -> void:
	var g := await _two()
	var calls := spy(g)
	g.damage_player(1, 9999)
	g.start_revive(7, 1)
	g.tick_status(1.0)
	g.damage_player(7, 5, _zombie(g), 0.99)
	assert_false(_status(g, 7).is_using())
	assert_eq(_status(g, 1).revive_left, 0.0, "the downed one is back to waiting")
	assert_true(_status(g, 1).downed)
	assert_eq(count(calls, &"on_player_revived"), 0)
	assert_true(g.start_revive(7, 1), "and it can be started again")
	g.tick_status(Config.REVIVE_SECONDS + 0.1)
	assert_false(_status(g, 1).downed, "and the whole time counts again")


func test_stopping_walking_away_or_sprinting_interrupts_it() -> void:
	var g := await _two()
	g.damage_player(7, 9999) # 7 is down; 1 revives them
	assert_true(g.start_revive(1, 7))
	g.cancel_use(1) # the key was let go
	assert_false(_status(g, 1).is_using())
	assert_eq(_status(g, 7).revive_left, 0.0)
	g.start_revive(1, 7)
	g.players[1].pos = HERE + Vector3(10, 0, 0) # off they go
	g.tick_status(0.1)
	assert_false(_status(g, 1).is_using(), "out of reach")
	g.players[1].pos = HERE
	g.start_revive(1, 7)
	g.local_player.check_use_cancel(true) # sprinting
	assert_false(_status(g, 1).is_using())
	assert_true(_status(g, 7).downed)


func test_a_revive_stops_if_the_downed_player_dies_meanwhile() -> void:
	var g := await _two()
	g.damage_player(1, 9999)
	g.start_revive(7, 1)
	g.damage_player(1, 100000, _zombie(g), 0.0)
	assert_false(_status(g, 7).is_using(), "nobody left to work on")


func test_a_checkpoint_gets_the_downed_up() -> void:
	var g := await _two()
	g.damage_player(1, 9999)
	g.hooks.on_checkpoint_reached("corner")
	assert_false(_status(g, 1).downed)
	assert_false(g.rules.out.has(1))
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP)


# --- Zombies --------------------------------------------------------------------------

func test_zombies_go_for_the_standing_and_finish_the_downed_when_nobody_else_is_near() -> void:
	var g := await _two()
	g.damage_player(1, 9999)
	g.players[1].pos = Vector3(0, 0.1, 10)
	var near_downed := Vector3(0, 0.1, 8)
	g.players[7].pos = Vector3(0, 0.1, 10) + Vector3(Config.DOWNED_FINISH_RANGE + 8, 0, 0)
	assert_eq(g.nearest_player(near_downed), 1, "nobody standing close: finish them")
	g.players[7].pos = near_downed + Vector3(4, 0, 0)
	assert_eq(g.nearest_player(near_downed), 7, "someone standing close: them first")
	g.players[7].pos = Vector3(0, 0.1, 10) + Vector3(100, 0, 0)
	assert_eq(g.nearest_player(Vector3(0, 0.1, 10) + Vector3(60, 0, 0)), 7, "far from the downed one: the standing, as ever")


func test_a_horde_with_everyone_downed_has_nobody_to_chase_but_the_downed() -> void:
	var g := await _two()
	g.rules.respawn = false
	g.damage_player(7, 9999)
	g.damage_player(1, 9999) # last standing: dies, mission over
	assert_eq(g.nearest_player(Vector3(0, 0.1, 20)), 7, "the one still down is all there is")


# --- Seeing it ------------------------------------------------------------------------

func test_everyone_can_see_who_is_down_and_a_player_finds_the_downed_teammate_beside_them() -> void:
	var g := await _two()
	g.damage_player(1, 9999)
	var bits: int = g.build_snapshot()[0][1].action
	assert_eq(bits & PlayerWire.ACTION_DOWNED, 0, "player 7 is standing")
	assert_true(g.build_snapshot()[0][0].action & PlayerWire.ACTION_DOWNED != 0)
	# As player 7's own game sees it: player 1 is a remote with the down bit set.
	g.my_id = 7
	g._apply_snapshot([{ "id": 7, "pos": HERE, "yaw": 0.0, "hp": 100, "kills": 0, "weapon": 0, "action": 0 },
		{ "id": 1, "pos": HERE + Vector3(1, 0, 0), "yaw": 0.0, "hp": 0, "kills": 0, "weapon": 0, "action": PlayerWire.ACTION_DOWNED }], [])
	g.local_player.status.reset() # (this body is player 7's now)
	g.local_player.global_position = HERE
	(g.remotes[1] as Node3D).global_position = HERE + Vector3(1, 0, 0)
	assert_eq(g.downed_teammate_near(), 1)
	(g.remotes[1] as Node3D).global_position = HERE + Vector3(9, 0, 0)
	assert_eq(g.downed_teammate_near(), 0, "out of reach")
	g.my_id = 1
