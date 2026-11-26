extends TestCase
## Right-click interactions go: player -> Game.host_interact -> hooks.on_right_click(target)
## -> hooks.on_right_click_door / on_right_click_lootbox.


func _stand_at(g: Game, pos: Vector3) -> void:
	g.local_player.teleport(pos)
	await frames(2)


func test_right_click_toggles_door() -> void:
	var g := await new_game()
	var calls := spy(g)
	await _stand_at(g, g.door.global_position + Vector3(-2, 0.1, 0))
	assert_false(g.door.is_open)
	assert_true(g.host_interact(1, g.door.iid))
	assert_true(g.door.is_open, "open after first right-click")
	g.host_interact(1, g.door.iid)
	assert_false(g.door.is_open, "closed after second")
	assert_eq(count(calls, &"on_right_click_door"), 2)
	assert_eq(count(calls, &"on_right_click"), 2)


func test_cannot_interact_from_far_away() -> void:
	var g := await new_game()
	assert_false(g.host_interact(1, g.door.iid), "player is at spawn, far from the door")
	assert_false(g.door.is_open)


func test_lootbox_gives_medkit_once() -> void:
	var g := await new_game()
	var calls := spy(g)
	await _stand_at(g, g.lootbox.global_position + Vector3(-1.5, 0.1, 0))
	g.damage_player(1, 50)
	g.host_interact(1, g.lootbox.iid)
	assert_true(g.lootbox.opened)
	assert_eq(g.players[1].inventory.count(Inventory.MEDKIT), 1, "the medkit goes in the pack, to be used when needed")
	assert_eq(g.players[1].health.hp, 50)
	assert_true(g.use_item(1, Inventory.MEDKIT))
	g.tick_status(Inventory.use_time(Inventory.MEDKIT))
	assert_eq(g.players[1].health.hp, 50 + Config.MEDKIT_HEAL)
	g.host_interact(1, g.lootbox.iid)
	assert_eq(g.players[1].inventory.count(Inventory.MEDKIT), 0, "second click gives nothing")
	assert_eq(count(calls, &"on_loot_received"), 1)


func test_closed_door_blocks_then_zombies_smash_it() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := g.spawn_zombie(Zombie.Type.WALKER, g.door.global_position + Vector3(1.0, 0.1, 0))
	var damaged := await wait_until(func(): return g.door.hp < Config.DOOR_HP, 3.0)
	assert_true(damaged, "zombie bashes the closed door")
	assert_gt(z.global_position.x, CorridorMap.DOOR_X, "and hasn't walked through it")
	g.door.take_hit(9999)
	assert_true(g.door.broken)
	assert_false(g.door.blocks())
	assert_eq(count(calls, &"on_door_broken"), 1)


func test_interactable_state_round_trips_for_late_joiners() -> void:
	var g := await new_game()
	g.door.toggle()
	var state := g.door.get_state()
	var other := Door.new()
	add_child(other)
	other.apply_state(state)
	assert_true(other.is_open)
	other.free()
