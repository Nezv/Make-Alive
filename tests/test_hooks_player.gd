extends TestCase
## Player-side gameplay hooks: on_low_hp, on_player_damaged, on_player_died.


func test_on_low_hp_fires_once() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.damage_player(1, 75)
	g.damage_player(1, 5)
	assert_eq(count(calls, &"on_low_hp"), 1)
	assert_eq(count(calls, &"on_player_damaged"), 2)


func test_death_fires_hook_and_respawns_at_full_hp() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.local_player.teleport(Vector3(0, 0.1, 10))
	await frames(2)
	g.damage_player(1, 500)
	await frames(3)
	assert_eq(count(calls, &"on_player_died"), 1)
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP)
	assert_lt(g.local_player.global_position.distance_to(CorridorMap.PLAYER_SPAWN), 4.0, "back at spawn")


func test_zombie_next_to_player_hurts_them() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.spawn_zombie(Zombie.Type.WALKER, g.local_player.global_position + Vector3(0, 0, -1.0))
	var hurt := await wait_until(func(): return g.players[1].health.hp < Config.PLAYER_HP, 2.5)
	assert_true(hurt, "player took damage from an adjacent zombie")
	assert_gt(count(calls, &"on_player_damaged"), 0)
