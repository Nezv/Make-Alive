extends TestCase
## Difficulty: four levels of multipliers on the zombies, the hordes and the ammo found, sent to
## every peer; nightmare hides the markers and lets players shoot each other.

const LEVELS := ["easy", "normal", "hard", "nightmare"]


func _game(level: String, limited := false) -> Game:
	var g := Game.new()
	g.map_name = "corridor"
	g.difficulty = level
	g.limited_ammo = limited
	add_child(g)
	_games.append(g)
	g.start_host("Tester")
	g.director.enabled = false
	await frames(2)
	return g


func test_four_levels_each_harder_than_the_last() -> void:
	assert_eq(Difficulty.LEVELS, LEVELS)
	for key in ["hp", "damage", "runners", "horde"]:
		for i in range(1, LEVELS.size()):
			assert_gt(Difficulty.get_mult(LEVELS[i], key), Difficulty.get_mult(LEVELS[i - 1], key) - 0.0001, "%s %s" % [LEVELS[i], key])
		assert_eq(Difficulty.get_mult("normal", key), 1.0, "normal is the game as tuned")
	for i in range(1, LEVELS.size()):
		assert_lt(Difficulty.get_mult(LEVELS[i], "ammo"), Difficulty.get_mult(LEVELS[i - 1], "ammo") + 0.0001, "less ammo found")
	assert_eq(Difficulty.get_mult("plasma", "hp"), 1.0, "an unknown level plays as normal")
	assert_false(Difficulty.flag("nightmare", "markers"))
	assert_true(Difficulty.flag("hard", "markers"))
	assert_true(Difficulty.flag("nightmare", "friendly_fire"))
	assert_false(Difficulty.flag("hard", "friendly_fire"))


func test_zombies_are_tougher_and_hit_harder() -> void:
	var easy := await _game("easy")
	var hard := await _game("hard")
	var a := easy.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	var b := hard.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	assert_lt(a.hp, b.hp)
	assert_eq(b.hp, roundi(Zombie.STATS[Zombie.Type.WALKER][2] * Difficulty.get_mult("hard", "hp")))
	await frames(2)
	easy.players[1].pos = a.global_position + Vector3(0, 0, 0.5)
	hard.players[1].pos = b.global_position + Vector3(0, 0, 0.5)
	easy.zombie_attack_lands(a, 1)
	hard.zombie_attack_lands(b, 1)
	assert_eq(Config.PLAYER_HP - easy.players[1].health.hp, roundi(Config.ZOMBIE_DAMAGE * Difficulty.get_mult("easy", "damage")))
	assert_eq(Config.PLAYER_HP - hard.players[1].health.hp, roundi(Config.ZOMBIE_DAMAGE * Difficulty.get_mult("hard", "damage")))


func test_more_runners_on_harder_levels() -> void:
	var easy := await _game("easy")
	var hard := await _game("nightmare")
	seed(5)
	var e := 0
	var h := 0
	for i in 2000:
		if easy.director.pick_type() == Zombie.Type.RUNNER:
			e += 1
		if hard.director.pick_type() == Zombie.Type.RUNNER:
			h += 1
	assert_gt(h, e * 1.4)


func test_hordes_are_bigger_and_grow_with_the_players_alive() -> void:
	var easy := await _game("easy")
	var hard := await _game("hard")
	assert_lt(easy.director.horde_size(1), hard.director.horde_size(1))
	var alone := hard.director.horde_size(2)
	hard._add_player(7, "Guest")
	assert_gt(hard.director.horde_size(2), alone, "another player, a bigger horde")
	hard.rules.set_out(7, true)
	assert_eq(hard.director.horde_size(2), alone, "only the living count")
	assert_gt(hard.rules.wave_size(10), easy.rules.wave_size(10), "defended waves too")


func test_less_ammo_is_found_on_harder_levels() -> void:
	var easy := await _game("easy", true)
	var hard := await _game("nightmare", true)
	var box := func(g: Game) -> AmmoBox:
		for it: Interactable in g.interactables.values():
			if it is AmmoBox:
				return it
		return null
	var e: AmmoBox = box.call(easy)
	var h: AmmoBox = box.call(hard)
	assert_gt(e.rounds, h.rounds)
	assert_eq(h.rounds, maxi(1, roundi(Weapons.AMMO[h.ammo].box * Difficulty.get_mult("nightmare", "ammo"))))
	var drop_e := easy.drop_ammo_box(Vector3(0, 0, 10), Weapons.Ammo.MM9, 15)
	var drop_h := hard.drop_ammo_box(Vector3(0, 0, 10), Weapons.Ammo.MM9, 15)
	assert_gt(drop_e.rounds, drop_h.rounds, "drops too")


func test_the_level_is_sent_in_welcome_and_saved_with_records() -> void:
	var g := await _game("hard")
	assert_eq(g.welcome_rules().difficulty, "hard")
	var client := Game.new()
	add_child(client)
	_games.append(client)
	client.welcome("corridor", "", {}, g.welcome_rules())
	assert_eq(client.difficulty, "hard")
	assert_false(client.show_markers() == false, "hard still has markers")
	client.welcome("corridor", "", {}, { "difficulty": "nightmare" })
	assert_false(client.show_markers())


func test_nightmare_lets_players_shoot_each_other() -> void:
	var g := await _game("nightmare")
	g._add_player(7, "Guest")
	var target := Vector3(0, 0.1, 15)
	g.players[7].pos = target
	var from := Vector3(0, 1.6, 20)
	g.resolve_shot(1, from, (target + Vector3(0, 1.2, 0) - from).normalized(), Weapons.AK47)
	var hurt := Config.PLAYER_HP - int(g.players[7].health.hp)
	assert_eq(hurt, roundi(Weapons.def(Weapons.AK47).damage * Config.FRIENDLY_FIRE_MULT))
	g.resolve_shot(1, from, Vector3.UP, Weapons.AK47)
	assert_eq(Config.PLAYER_HP - int(g.players[7].health.hp), hurt, "a miss is a miss")
	var calm := await _game("hard")
	calm._add_player(7, "Guest")
	calm.players[7].pos = target
	calm.resolve_shot(1, from, (target + Vector3(0, 1.2, 0) - from).normalized(), Weapons.AK47)
	assert_eq(calm.players[7].health.hp, Config.PLAYER_HP, "no friendly fire below nightmare")
