extends TestCase
## Ammo lying around: cartons of one calibre, the military crate, what zombies drop, and how a
## pickup reaches the player who took it.

const A := Weapons.Ammo


func _of(g: Game, type: Variant) -> Array:
	var out := []
	for iid: int in g.interactables:
		if is_instance_of(g.interactables[iid], type):
			out.append(g.interactables[iid])
	return out


## Stand the local player (the host, id 1) within reach of `it`.
func _reach(g: Game, it: Interactable) -> void:
	g.local_player.teleport(it.global_position + Vector3(0, 0.1, 1.0))
	g.players[1].pos = g.local_player.global_position


func test_the_corridor_has_ammo_boxes_and_a_crate_from_its_data() -> void:
	var g := await new_game()
	var boxes := _of(g, AmmoBox)
	var crates := _of(g, AmmoCrate)
	assert_eq(boxes.size(), MapAreas.CORRIDOR.ammo_boxes.size())
	assert_eq(crates.size(), 1)
	var first: Dictionary = MapAreas.CORRIDOR.ammo_boxes[0]
	var box: AmmoBox = g.interactables[first.iid]
	assert_eq(box.position, first.at)
	assert_eq(box.ammo, Weapons.ammo_id(first.ammo))
	assert_gt(box.rounds, 0)
	assert_false(box.dynamic, "a box from the data stays in the list")
	assert_true(box.prompt().contains(first.ammo), box.prompt())
	assert_eq(MapData.new(MapAreas.CORRIDOR).errors, [])


func test_map_data_refuses_an_ammo_box_of_no_calibre() -> void:
	var d := MapData.new({ "name": "t", "ammo_boxes": [{ "iid": 1, "at": Vector3.ZERO, "ammo": "plasma" }] })
	assert_eq(d.errors.size(), 1)
	assert_true(str(d.errors[0]).contains("plasma"), str(d.errors))


func test_a_carton_shows_its_count_as_pips_and_its_calibre_as_a_stripe() -> void:
	var full: int = Weapons.AMMO[A.MM762].box
	assert_eq(AmmoBox.pips(A.MM762, full), Config.AMMO_BOX_PIPS)
	assert_eq(AmmoBox.pips(A.MM762, full * 3), Config.AMMO_BOX_PIPS, "never more than the row holds")
	assert_eq(AmmoBox.pips(A.MM762, 1), 1, "never none while something is in it")
	assert_lt(AmmoBox.pips(A.MM762, full / 2), Config.AMMO_BOX_PIPS)
	var seen := {}
	for type in A.COUNT:
		seen[Weapons.AMMO[type].color] = true
	assert_eq(seen.size(), A.COUNT, "every calibre has its own stripe colour")


func test_taking_a_box_fills_the_reserve_fires_the_hook_and_shows_the_gain() -> void:
	var g := await new_game("corridor", "", true)
	var calls := spy(g)
	var box: AmmoBox = _of(g, AmmoBox)[0]
	var type := box.ammo
	var rounds := box.rounds
	var before := g.ammo_of(1, type)
	_reach(g, box)
	assert_true(g.host_interact(1, box.iid))
	assert_eq(g.ammo_of(1, type), before + rounds)
	assert_eq(g.local_player.weapons.reserve[type], before + rounds, "the player has them too")
	assert_eq(count(calls, &"on_right_click_ammo_box"), 1)
	assert_eq(count(calls, &"on_ammo_picked_up"), 1)
	assert_eq(calls[-1][1], [1, type, rounds])
	assert_eq(box.taken_by, 1)
	assert_eq(box.prompt(), "")
	assert_eq(box.get_state().by, 1)
	assert_true(g.hud.gain_label.text.begins_with("+%d" % rounds), g.hud.gain_label.text)
	assert_gt(g.hud.gain_label.modulate.a, 0.0)
	g.host_interact(1, box.iid)
	assert_eq(count(calls, &"on_ammo_picked_up"), 1, "only once")
	assert_eq(g.ammo_of(1, type), before + rounds)


func test_a_taken_box_hops_to_the_player_and_shrinks_away() -> void:
	var g := await new_game("corridor", "", true)
	var box: AmmoBox = _of(g, AmmoBox)[0]
	var start := box.global_position
	_reach(g, box)
	g.host_interact(1, box.iid)
	var goal := g.local_player.global_position + Vector3(0, Config.PICKUP_HOP_HEIGHT, 0)
	box._process(Config.PICKUP_HOP_TIME * 0.5)
	assert_lt(box.global_position.distance_to(goal), start.distance_to(goal), "on its way")
	assert_lt(box.scale.x, 1.0, "and shrinking")
	assert_gt(box.scale.x, 0.0)
	box._process(Config.PICKUP_HOP_TIME)
	assert_false(box.visible, "gone after the hop")
	assert_true(g.interactables.has(box.iid), "a box of the map keeps its id (late joiners get its state)")


func test_a_box_keeps_what_does_not_fit_and_a_full_player_takes_nothing() -> void:
	var g := await new_game("corridor", "", true)
	var calls := spy(g)
	var box: AmmoBox = _of(g, AmmoBox)[0]
	var type := box.ammo
	var cap: int = Weapons.AMMO[type].max
	var rounds := box.rounds
	g.give_ammo(1, type, cap) # full
	_reach(g, box)
	g.host_interact(1, box.iid)
	assert_eq(box.taken_by, -1, "still lying there")
	assert_eq(box.rounds, rounds)
	assert_eq(count(calls, &"on_ammo_picked_up"), 0)
	g._ammo_used(1, type, 4)
	g.local_player.weapons.reserve[type] = cap - 4
	g.host_interact(1, box.iid)
	assert_eq(g.ammo_of(1, type), cap)
	assert_eq(box.rounds, rounds - 4, "the rest stays in the carton")
	assert_eq(box.taken_by, -1)
	assert_eq(calls[-1][1], [1, type, 4])


func test_on_a_map_with_infinite_ammo_boxes_stay_where_they_are() -> void:
	var g := await new_game()
	var calls := spy(g)
	var box: AmmoBox = _of(g, AmmoBox)[0]
	_reach(g, box)
	g.host_interact(1, box.iid)
	assert_eq(box.taken_by, -1)
	assert_eq(count(calls, &"on_ammo_picked_up"), 0)


func test_box_state_travels_to_another_peer() -> void:
	var host := AmmoBox.new()
	var client := AmmoBox.new()
	host.setup(A.GAUGE12, 8)
	client.apply_state(host.get_state())
	assert_eq(client.ammo, A.GAUGE12)
	assert_eq(client.rounds, 8)
	assert_eq(client.prompt(), host.prompt())
	host.take(8, 3)
	client.apply_state(host.get_state())
	assert_eq(client.taken_by, 3)
	assert_eq(client.prompt(), "")
	host.free()
	client.free()


func test_the_crate_gives_the_held_guns_calibre_a_few_times() -> void:
	var g := await new_game("corridor", "", true)
	var calls := spy(g)
	var crate: AmmoCrate = _of(g, AmmoCrate)[0]
	crate.locked = false # (the corridor's crate opens at the checkpoint)
	assert_eq(crate.uses, Config.AMMO_CRATE_USES)
	assert_true(crate.prompt().contains(str(crate.uses)), crate.prompt())
	_reach(g, crate)
	var type := A.GAUGE12
	g._ammo_used(1, type, 1000) # an empty pocket, so every use fits
	g.local_player.weapons.reserve[type] = 0
	var per: int = Weapons.AMMO[type].box * Config.AMMO_CRATE_BOXES
	assert_true(g.host_interact(1, crate.iid, Weapons.SPAS12), "the click says which gun is in hand")
	assert_eq(g.players[1].weapon, Weapons.SPAS12)
	assert_eq(g.ammo_of(1, type), per)
	assert_eq(crate.uses, Config.AMMO_CRATE_USES - 1)
	assert_eq(count(calls, &"on_right_click_ammo_crate"), 1)
	assert_eq(calls[-1][1], [1, type, per])
	assert_gt(crate.open_left, 0.0, "the lid swings up")
	crate._process(0.3)
	assert_lt(crate.lid.rotation.x, -0.3, "on its hinge")
	crate._process(Config.AMMO_CRATE_OPEN_TIME)
	for i in 30:
		crate._process(0.1)
	assert_gt(crate.lid.rotation.x, -0.05, "and falls shut again")
	for i in Config.AMMO_CRATE_USES - 1:
		g._ammo_used(1, type, 1000)
		g.host_interact(1, crate.iid, Weapons.SPAS12)
	assert_eq(crate.uses, 0)
	assert_eq(crate.prompt(), "")
	var picked := count(calls, &"on_ammo_picked_up")
	g._ammo_used(1, type, 1000)
	g.host_interact(1, crate.iid, Weapons.SPAS12)
	assert_eq(count(calls, &"on_ammo_picked_up"), picked, "empty")
	assert_eq(g.ammo_of(1, type), 0)


func test_the_crate_wastes_no_use_on_a_full_player() -> void:
	var g := await new_game("corridor", "", true)
	var crate: AmmoCrate = _of(g, AmmoCrate)[0]
	crate.locked = false
	_reach(g, crate)
	g.give_ammo(1, A.MM762, 100000)
	g.host_interact(1, crate.iid, Weapons.AK47)
	assert_eq(crate.uses, Config.AMMO_CRATE_USES)


func test_crate_state_travels_and_opens_the_lid_on_the_other_peer() -> void:
	var host := AmmoCrate.new()
	var client := AmmoCrate.new()
	assert_true(host.use())
	client.apply_state(host.get_state())
	assert_eq(client.uses, host.uses)
	assert_gt(client.open_left, 0.0)
	host.free()
	client.free()


func test_drops_are_rare_seeded_by_the_zombie_and_armed_dead_carry_more() -> void:
	var plain := 0
	var cop := 0
	var soldier := 0
	var n := 4000
	for zid in range(1, n + 1):
		var d := AmmoBox.roll_drop(zid, Characters.Outfit.CIVILIAN)
		assert_eq(d, AmmoBox.roll_drop(zid, Characters.Outfit.CIVILIAN), "the same zombie always drops the same")
		if not d.is_empty():
			plain += 1
			assert_gt(d.rounds, 0)
			assert_true(d.ammo >= 0 and d.ammo < A.COUNT)
		if not AmmoBox.roll_drop(zid, Characters.Outfit.COP).is_empty():
			cop += 1
		if not AmmoBox.roll_drop(zid, Characters.Outfit.SOLDIER).is_empty():
			soldier += 1
	assert_near(float(plain) / n, Config.AMMO_DROP_CHANCE, 0.02, "plain share")
	assert_near(float(cop) / n, Config.AMMO_DROP_CHANCE_ARMED, 0.03, "cop share")
	assert_near(float(soldier) / n, Config.AMMO_DROP_CHANCE_ARMED, 0.03, "soldier share")
	assert_lt(Config.AMMO_DROP_CHANCE, 0.15, "rare")
	assert_gt(Config.AMMO_DROP_CHANCE_ARMED, Config.AMMO_DROP_CHANCE * 2.0)


## The id of a walker that drops ammo when it dies (ids are what seed the drop).
func _dropper() -> int:
	for zid in range(1, 5000):
		if not AmmoBox.roll_drop(zid, Characters.outfit_for(zid, Zombie.Type.WALKER)).is_empty():
			return zid
	return -1


func test_a_killed_zombie_leaves_its_box_where_it_fell_and_it_can_be_taken() -> void:
	var g := await new_game("corridor", "", true)
	var calls := spy(g)
	g._next_zombie = _dropper()
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	var drop := AmmoBox.roll_drop(z.zid, Characters.outfit_for(z.zid, z.type))
	await frames(2)
	var before := _of(g, AmmoBox).size()
	g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)
	assert_eq(count(calls, &"on_zombie_killed"), 1)
	var boxes := _of(g, AmmoBox)
	assert_eq(boxes.size(), before + 1)
	var box: AmmoBox = boxes[-1]
	assert_true(box.dynamic)
	assert_true(box.iid >= Config.DROP_IID_BASE)
	assert_eq(box.ammo, drop.ammo)
	assert_eq(box.rounds, drop.rounds)
	assert_lt(Vector2(box.global_position.x, box.global_position.z).distance_to(Vector2(0, 20)), 0.5)
	assert_near(box.global_position.y, 0.0, 0.01, "on the floor")
	var have := g.ammo_of(1, box.ammo)
	_reach(g, box)
	assert_true(g.host_interact(1, box.iid))
	assert_eq(g.ammo_of(1, box.ammo), have + drop.rounds)
	assert_false(g.interactables.has(box.iid), "a dropped box leaves the list once taken")
	box._process(Config.PICKUP_HOP_TIME * 2.0)
	await frames(2)
	assert_false(is_instance_valid(box), "and the tree after its hop")


func test_no_drops_where_ammo_is_infinite() -> void:
	var g := await new_game()
	g._next_zombie = _dropper()
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	await frames(2)
	var before := _of(g, AmmoBox).size()
	g.hit_zombie(1, z, Humanoid.Part.HEAD, z.global_position + Vector3(0, 1.7, 0), Vector3.FORWARD, 100000)
	assert_eq(_of(g, AmmoBox).size(), before)


func test_a_peer_builds_a_dropped_box_from_its_state_alone() -> void:
	var g := await new_game("corridor", "", true)
	var box := g.drop_ammo_box(Vector3(1, 0, 15), A.MM9, 15)
	var state := box.get_state()
	assert_true(state.drop)
	# What a client (or a late joiner, through `welcome`) does with a state for an id it has never seen:
	var iid := Config.DROP_IID_BASE + 500
	g._apply_interact_state(iid, state)
	var copy: AmmoBox = g.interactables[iid]
	assert_true(copy.dynamic)
	assert_eq(copy.global_position, box.global_position)
	assert_eq(copy.ammo, A.MM9)
	assert_eq(copy.rounds, 15)
	var taken := state.duplicate()
	taken.by = 1
	g._apply_interact_state(iid, taken)
	assert_false(g.interactables.has(iid), "taken by someone: it hops away there too")
	g._apply_interact_state(iid + 1, taken)
	assert_false(g.interactables.has(iid + 1), "a box already taken is never built")


func test_dropped_boxes_are_capped_and_the_oldest_goes_first() -> void:
	var g := await new_game("corridor", "", true)
	var first := g.drop_ammo_box(Vector3(0, 0, 10), A.MM9, 15)
	for i in Config.AMMO_DROPS_MAX:
		g.drop_ammo_box(Vector3(0, 0, 10), A.MM9, 15)
	var lying := 0
	for b: AmmoBox in _of(g, AmmoBox):
		if b.dynamic:
			lying += 1
	assert_eq(lying, Config.AMMO_DROPS_MAX)
	assert_false(g.interactables.has(first.iid))
	assert_eq(first.taken_by, 0, "removed, taken by nobody")
