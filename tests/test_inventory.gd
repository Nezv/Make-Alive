extends TestCase
## What a player carries besides guns: counted stacks with caps (medkit, bandage, painkillers, planks),
## throwable slots, keys by id. The host owns it, the player mirrors it, a radial wheel and two quick
## keys use it, and a dead player's goes into a backpack the others can loot.

const I := preload("res://scripts/inventory.gd")


func _backpacks(g: Game) -> Array:
	var found := []
	for iid: int in g.interactables:
		if g.interactables[iid] is Backpack:
			found.append(g.interactables[iid])
	return found


# --- The stacks themselves (no nodes) ------------------------------------------------

func test_every_item_has_a_name_a_kind_and_a_cap() -> void:
	for item: StringName in [I.MEDKIT, I.BANDAGE, I.PAINKILLERS, I.PLANK, I.FRAG, I.MOLOTOV, I.FLASHBANG, I.LURE]:
		assert_true(I.valid(item), str(item))
		assert_true(I.item_name(item) != "", str(item))
		assert_gt(I.cap_of(item), 0, str(item))
	assert_eq(I.kind_of(I.MEDKIT), I.Kind.MEDICAL)
	assert_eq(I.kind_of(I.PLANK), I.Kind.MATERIAL)
	assert_eq(I.kind_of(I.FRAG), I.Kind.THROWABLE)
	assert_false(I.valid(&"unicorn"))
	assert_lt(I.cap_of(I.MEDKIT), I.cap_of(I.BANDAGE), "bandages are small, medkits are not")


func test_stacks_stop_at_their_cap_and_say_how_many_fitted() -> void:
	var inv := Inventory.new()
	assert_eq(inv.count(I.BANDAGE), 0)
	assert_eq(inv.add(I.BANDAGE, 3), 3)
	var cap := I.cap_of(I.BANDAGE)
	assert_eq(inv.add(I.BANDAGE, 99), cap - 3, "only what fits")
	assert_eq(inv.count(I.BANDAGE), cap)
	assert_eq(inv.room(I.BANDAGE), 0)
	assert_eq(inv.add(I.BANDAGE), 0, "full")
	assert_eq(inv.add(&"unicorn"), 0, "not an item")
	assert_eq(inv.add(I.MEDKIT, 0), 0)
	assert_eq(inv.add(I.MEDKIT, -2), 0)
	assert_eq(inv.count(I.MEDKIT), 0)


func test_taking_out_is_all_or_nothing() -> void:
	var inv := Inventory.new()
	inv.add(I.MEDKIT, 2)
	assert_false(inv.remove(I.MEDKIT, 3), "there are only two")
	assert_eq(inv.count(I.MEDKIT), 2, "and nothing was taken")
	assert_true(inv.remove(I.MEDKIT))
	assert_eq(inv.count(I.MEDKIT), 1)
	assert_true(inv.remove(I.MEDKIT))
	assert_false(inv.remove(I.MEDKIT), "none left")
	assert_true(inv.is_empty())


func test_only_so_many_kinds_of_throwable_fit_in_the_slots() -> void:
	var inv := Inventory.new()
	assert_eq(Config.THROWABLE_SLOTS, 2)
	assert_eq(inv.add(I.FRAG, 2), 2)
	assert_eq(inv.add(I.MOLOTOV, 1), 1)
	assert_eq(inv.room(I.FLASHBANG), 0, "both slots are taken by other kinds")
	assert_eq(inv.add(I.FLASHBANG), 0)
	assert_eq(inv.room(I.FRAG), I.cap_of(I.FRAG) - 2, "more of a kind you carry still fits")
	assert_eq(inv.throwables(), [I.FRAG, I.MOLOTOV])
	assert_true(inv.remove(I.MOLOTOV))
	assert_eq(inv.add(I.FLASHBANG), 1, "the slot is free again")
	assert_eq(inv.throwables(), [I.FRAG, I.FLASHBANG])


func test_a_throwable_is_selected_for_the_quick_key_and_falls_back_when_spent() -> void:
	var inv := Inventory.new()
	assert_eq(inv.selected_throwable(), &"", "nothing to throw")
	inv.add(I.FRAG)
	assert_eq(inv.selected_throwable(), I.FRAG, "the first one you get is ready")
	inv.add(I.MOLOTOV)
	assert_eq(inv.selected_throwable(), I.FRAG, "and stays so")
	assert_true(inv.select_throwable(I.MOLOTOV))
	assert_eq(inv.selected_throwable(), I.MOLOTOV)
	assert_false(inv.select_throwable(I.LURE), "you do not carry it")
	assert_eq(inv.selected_throwable(), I.MOLOTOV)
	inv.cycle_throwable(1)
	assert_eq(inv.selected_throwable(), I.FRAG, "round again")
	inv.cycle_throwable(-1)
	assert_eq(inv.selected_throwable(), I.MOLOTOV)
	inv.remove(I.MOLOTOV)
	assert_eq(inv.selected_throwable(), I.FRAG, "the one you had is gone: the other is ready")
	inv.remove(I.FRAG)
	assert_eq(inv.selected_throwable(), &"")


func test_keys_are_carried_by_id_and_take_no_room() -> void:
	var inv := Inventory.new()
	assert_false(inv.has_key(&"hospital_roof"))
	assert_true(inv.add_key(&"hospital_roof"))
	assert_false(inv.add_key(&"hospital_roof"), "a second copy adds nothing")
	inv.add_key(&"generator")
	assert_true(inv.has_key(&"hospital_roof"))
	assert_true(inv.has_key(&"generator"))
	assert_eq(inv.keys().size(), 2)
	assert_false(inv.is_empty())
	assert_true(inv.remove_key(&"generator"))
	assert_false(inv.remove_key(&"generator"))
	assert_false(inv.has_key(&"generator"))
	for item: StringName in I.ITEMS:
		assert_eq(inv.count(item), 0, "keys are not stacks")


func test_quick_heal_picks_the_big_one_first() -> void:
	var inv := Inventory.new()
	assert_eq(inv.quick_heal(), &"")
	inv.add(I.PAINKILLERS)
	assert_eq(inv.quick_heal(), &"", "painkillers are not a heal")
	inv.add(I.BANDAGE)
	assert_eq(inv.quick_heal(), I.BANDAGE)
	inv.add(I.MEDKIT)
	assert_eq(inv.quick_heal(), I.MEDKIT)


func test_an_inventory_travels_as_a_dictionary_and_the_player_keeps_their_own_choice() -> void:
	var inv := Inventory.new()
	inv.add(I.MEDKIT, 2)
	inv.add(I.PLANK, 5)
	inv.add(I.FRAG, 2)
	inv.add(I.LURE, 1)
	inv.add_key(&"generator")
	var state := inv.get_state()
	var copy := Inventory.from_state(state)
	for item: StringName in I.ITEMS:
		assert_eq(copy.count(item), inv.count(item), str(item))
	assert_eq(copy.keys(), [&"generator"])
	assert_eq(copy.throwables(), inv.throwables())
	copy.select_throwable(I.LURE)
	copy.apply_state(state) # the host sends it again after something changed
	assert_eq(copy.selected_throwable(), I.LURE, "their choice of throwable is theirs")
	inv.remove(I.LURE)
	copy.apply_state(inv.get_state())
	assert_eq(copy.selected_throwable(), I.FRAG, "unless it is gone")
	assert_eq(copy.count(I.LURE), 0)
	var wire := Inventory.from_state(state.duplicate(true))
	assert_eq(wire.count(I.PLANK), 5)


func test_everything_in_a_backpack_moves_to_whoever_has_room() -> void:
	var pack := Inventory.new()
	pack.capped = false # a dead player's whole kit, whatever it was
	pack.add(I.BANDAGE, I.cap_of(I.BANDAGE) + 4)
	pack.add(I.MEDKIT, 1)
	pack.add_key(&"generator")
	assert_eq(pack.count(I.BANDAGE), I.cap_of(I.BANDAGE) + 4, "no cap on what lies on the ground")
	var mine := Inventory.new()
	mine.add(I.BANDAGE, 3)
	var moved := pack.transfer_to(mine)
	assert_eq(moved, (I.cap_of(I.BANDAGE) - 3) + 1 + 1, "bandages to the cap, the medkit, the key")
	assert_eq(mine.count(I.BANDAGE), I.cap_of(I.BANDAGE))
	assert_eq(mine.count(I.MEDKIT), 1)
	assert_true(mine.has_key(&"generator"))
	assert_eq(pack.count(I.BANDAGE), 7, "the rest stays in the pack")
	assert_false(pack.is_empty())
	assert_eq(pack.transfer_to(mine), 0, "nothing more fits")
	mine.remove(I.BANDAGE, I.cap_of(I.BANDAGE))
	assert_eq(pack.transfer_to(mine), I.cap_of(I.BANDAGE), "room again")
	assert_eq(pack.count(I.BANDAGE), 2)
	mine.remove(I.BANDAGE, I.cap_of(I.BANDAGE))
	assert_eq(pack.transfer_to(mine), 2)
	assert_true(pack.is_empty())


# --- The wheel ------------------------------------------------------------------------

func test_the_wheel_has_eight_wedges_in_a_fixed_order() -> void:
	var inv := Inventory.new()
	var wheel := inv.wheel()
	assert_eq(Config.WHEEL_WEDGES, 8)
	assert_eq(wheel.size(), 8)
	assert_eq(wheel[0].item, I.MEDKIT)
	assert_eq(wheel[1].item, I.BANDAGE)
	assert_eq(wheel[2].item, I.PAINKILLERS)
	assert_eq(wheel[0].count, 0, "shown, but empty")
	inv.add(I.MEDKIT)
	inv.add(I.LURE, 2)
	inv.add(I.FRAG)
	wheel = inv.wheel()
	assert_eq(wheel[0].count, 1)
	assert_eq(wheel[3].item, I.FRAG, "the two throwable wedges follow what is carried")
	assert_eq(wheel[4].item, I.LURE)
	assert_eq(wheel[4].count, 2)
	assert_eq(wheel[5].item, I.PLANK)


func test_the_mouse_direction_picks_the_wedge_clockwise_from_the_top() -> void:
	assert_eq(I.wedge_at(Vector2(0, -80)), 0, "up")
	assert_eq(I.wedge_at(Vector2(80, -80)), 1, "up and right")
	assert_eq(I.wedge_at(Vector2(80, 0)), 2, "right")
	assert_eq(I.wedge_at(Vector2(80, 80)), 3)
	assert_eq(I.wedge_at(Vector2(0, 80)), 4, "down")
	assert_eq(I.wedge_at(Vector2(-80, 80)), 5)
	assert_eq(I.wedge_at(Vector2(-80, 0)), 6, "left")
	assert_eq(I.wedge_at(Vector2(-80, -80)), 7)
	assert_eq(I.wedge_at(Vector2(-5, -80)), 0, "a little to the left of up is still up")
	assert_eq(I.wedge_at(Vector2(5, 5)), -1, "the middle picks nothing")


func test_the_wheel_follows_the_mouse_and_picks_on_release() -> void:
	var inv := Inventory.new()
	inv.add(I.BANDAGE)
	var wheel := ItemWheel.new()
	assert_false(wheel.open)
	wheel.begin(inv)
	assert_true(wheel.open)
	assert_eq(wheel.selected(), -1, "starts in the middle")
	wheel.push(Vector2(40, -60))
	wheel.push(Vector2(-40, 0))
	assert_eq(wheel.selected(), 0, "(40,-60) then (-40,0) is straight up again")
	wheel.push(Vector2(400, 0))
	assert_near(wheel.offset.length(), Config.WHEEL_RADIUS, 0.01, "the pointer stays on the rim")
	wheel.push(Vector2(-4000, 4000))
	assert_eq(wheel.selected(), 5, "it can be swung right round")
	wheel.offset = Vector2(0, -Config.WHEEL_RADIUS)
	wheel.push(Vector2(-Config.WHEEL_RADIUS * 1.3, Config.WHEEL_RADIUS * 1.3))
	assert_eq(wheel.finish(), &"", "a wedge with nothing in it picks nothing")
	assert_false(wheel.open)
	wheel.begin(inv)
	wheel.push(Vector2(0, -Config.WHEEL_RADIUS))
	wheel.push(Vector2(Config.WHEEL_RADIUS, Config.WHEEL_RADIUS * 0.4))
	assert_eq(wheel.selected(), 1)
	assert_eq(wheel.finish(), I.BANDAGE, "up and right is the bandage")
	wheel.begin(inv)
	assert_eq(wheel.finish(), &"", "released in the middle: nothing")


func test_every_item_has_an_icon_drawn_from_boxes_and_no_two_look_alike() -> void:
	var seen := {}
	for item: StringName in I.ITEMS:
		var boxes: Array = ItemIcons.boxes(item)
		assert_true(boxes.size() >= 2, "%s is drawn from a few boxes" % item)
		for b: Array in boxes:
			var r: Rect2 = b[0]
			assert_true(Rect2(-1, -1, 2, 2).encloses(r), "%s stays inside its square: %s" % [item, r])
			assert_true(b[1] is Color)
		var key := str(boxes)
		assert_false(seen.has(key), "%s looks like %s" % [item, seen.get(key, "")])
		seen[key] = item
	assert_eq(ItemIcons.boxes(&"nothing").size(), 0, "an empty wedge has no icon")


func test_the_lit_wedge_hops_and_settles_back_when_the_pointer_leaves() -> void:
	var inv := Inventory.new()
	inv.add(I.MEDKIT, 1)
	inv.add(I.BANDAGE, 1)
	var wheel := ItemWheel.new()
	wheel.begin(inv)
	var view := ItemWheelView.new()
	view.wheel = wheel
	view.step(0.5)
	assert_eq(view.hop_of(0), 0.0, "nothing lit, nothing hops")
	wheel.offset = Vector2(0, -Config.WHEEL_RADIUS)
	view.step(Config.WHEEL_HOP_TIME / 2.0)
	assert_true(view.hop_of(0) > 0.1, "the lit wedge's icon rises")
	view.step(Config.WHEEL_HOP_TIME)
	assert_near(view.hop_of(0), 1.0, 0.05, "and settles fully up")
	assert_true(view.icon_scale(0) > view.icon_scale(1), "bigger than the others")
	wheel.offset = Vector2(Config.WHEEL_RADIUS, -Config.WHEEL_RADIUS * 2.0).limit_length(Config.WHEEL_RADIUS)
	view.step(Config.WHEEL_HOP_TIME * 3.0)
	assert_near(view.hop_of(0), 0.0, 0.05, "the old one sinks back")
	assert_true(view.hop_of(1) > 0.9, "the new one is up")
	view.free()


# --- In a match -----------------------------------------------------------------------

func test_the_host_keeps_each_players_inventory_and_the_player_mirrors_it() -> void:
	var g := await new_game()
	var calls := spy(g)
	assert_true(g.players[1].inventory.is_empty(), "nobody starts with anything")
	assert_eq(g.give_item(1, I.MEDKIT, 2), 2)
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 2)
	assert_eq(g.local_player.inventory.count(I.MEDKIT), 2, "and the player sees the same")
	assert_eq(count(calls, &"on_item_picked_up"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_item_picked_up")[0][1], [1, I.MEDKIT, 2])
	assert_eq(g.give_item(1, I.MEDKIT, 5), 0, "the cap is the host's to hold")
	assert_eq(count(calls, &"on_item_picked_up"), 1, "nothing was picked up")
	assert_eq(g.give_item(1, &"unicorn"), 0)
	assert_eq(g.give_item(99, I.MEDKIT), 0, "nobody by that id")
	assert_true(g.give_key(1, &"generator"))
	assert_true(g.local_player.inventory.has_key(&"generator"))
	assert_eq(g.inventory_room(1, I.MEDKIT), 0)
	assert_eq(g.inventory_room(1, I.BANDAGE), I.cap_of(I.BANDAGE))


func test_a_medkit_is_spent_to_heal_and_never_wasted_at_full_health() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.give_item(1, I.MEDKIT)
	assert_false(g.can_use_item(1, I.MEDKIT), "at full health there is nothing to heal")
	assert_false(g.use_item(1, I.MEDKIT))
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 1, "and it is still there")
	g.damage_player(1, 50)
	assert_true(g.use_item(1, I.MEDKIT))
	g.tick_status(I.use_time(I.MEDKIT)) # healing takes its time
	assert_eq(g.players[1].health.hp, 50 + Config.MEDKIT_HEAL)
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 0)
	assert_eq(g.local_player.inventory.count(I.MEDKIT), 0, "the player's copy follows")
	assert_eq(count(calls, &"on_item_used"), 1)
	assert_false(g.use_item(1, I.MEDKIT), "none left")
	assert_false(g.use_item(1, I.PLANK), "planks are for barricades, not for using")
	assert_false(g.use_item(99, I.MEDKIT))


func test_the_dead_cannot_use_things() -> void:
	var g := await new_game()
	g.give_item(1, I.FRAG)
	g.rules.set_out(1, true)
	assert_false(g.use_item(1, I.FRAG))
	assert_eq(g.players[1].inventory.count(I.FRAG), 1)


func test_the_quick_heal_key_asks_the_host_for_the_best_heal() -> void:
	var g := await new_game()
	var lp := g.local_player
	assert_true(InputMap.has_action("quick_heal"))
	assert_true(InputMap.has_action("quick_throw"))
	assert_true(InputMap.has_action("item_wheel"))
	assert_false(lp.try_quick_heal(), "nothing to heal with")
	g.give_item(1, I.BANDAGE)
	g.give_item(1, I.MEDKIT)
	g.damage_player(1, 60)
	assert_true(lp.try_quick_heal())
	g.tick_status(I.use_time(I.MEDKIT))
	assert_eq(g.players[1].health.hp, 40 + Config.MEDKIT_HEAL, "the medkit went first")
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 0)
	assert_eq(g.players[1].inventory.count(I.BANDAGE), 1)


func test_the_quick_throw_key_uses_the_selected_throwable() -> void:
	var g := await new_game()
	var calls := spy(g)
	var lp := g.local_player
	assert_false(lp.try_quick_throw(), "nothing to throw")
	g.give_item(1, I.FRAG, 2)
	g.give_item(1, I.LURE, 1)
	lp.inventory.select_throwable(I.LURE)
	assert_true(lp.try_quick_throw())
	assert_eq(g.players[1].inventory.count(I.LURE), 0)
	assert_eq(g.players[1].inventory.count(I.FRAG), 2)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_item_used")[0][1], [1, I.LURE])
	assert_eq(lp.inventory.selected_throwable(), I.FRAG, "and the next one is ready")
	assert_true(lp.try_quick_throw())
	assert_eq(g.players[1].inventory.count(I.FRAG), 1)


func test_holding_the_wheel_takes_the_mouse_off_the_view_and_releasing_uses_the_wedge() -> void:
	var g := await new_game()
	var lp := g.local_player
	g.give_item(1, I.MEDKIT)
	g.give_item(1, I.FRAG)
	g.give_item(1, I.LURE)
	g.damage_player(1, 50)
	var yaw := lp.yaw
	lp.open_wheel()
	assert_true(lp.wheel.open)
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(0, -90)
	lp.handle_event(move)
	assert_eq(lp.yaw, yaw, "the view stays where it was")
	assert_eq(lp.wheel.selected(), 0, "the mouse moved the wheel instead")
	lp.close_wheel()
	assert_false(lp.wheel.open)
	g.tick_status(I.use_time(I.MEDKIT))
	assert_eq(g.players[1].health.hp, 50 + Config.MEDKIT_HEAL, "up is the medkit")
	# A throwable wedge only makes it the one the quick key throws.
	lp.open_wheel()
	lp.wheel.offset = Vector2(Config.WHEEL_RADIUS * 0.7, Config.WHEEL_RADIUS * 0.7) # wedge 3: the first throwable
	assert_eq(lp.wheel.selected(), 3)
	lp.close_wheel()
	assert_eq(g.players[1].inventory.count(I.FRAG), 1, "picking a throwable does not throw it")
	lp.open_wheel()
	lp.wheel.offset = Vector2(0, Config.WHEEL_RADIUS) # wedge 4: the second throwable
	lp.close_wheel()
	assert_eq(lp.inventory.selected_throwable(), I.LURE)


func test_you_cannot_shoot_while_the_wheel_is_up() -> void:
	var g := await new_game()
	var lp := g.local_player
	lp.fire_buffer = 0.0
	lp.open_wheel()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	lp.handle_event(click)
	assert_true(lp.fire_buffer <= 0.0, "a click on the wheel is not a shot")
	lp.close_wheel()


# --- Backpacks ------------------------------------------------------------------------

func test_a_player_who_dies_leaves_a_backpack_with_everything() -> void:
	var g := await new_game()
	var calls := spy(g)
	g.give_item(1, I.MEDKIT)
	g.give_item(1, I.PLANK, 4)
	g.give_key(1, &"generator")
	var at: Vector3 = g.players[1].pos
	g.damage_player(1, 9999)
	assert_true(g.players[1].inventory.is_empty(), "nothing left on them")
	assert_true(g.local_player.inventory.is_empty(), "or in their mirror")
	var packs := _backpacks(g)
	assert_eq(packs.size(), 1)
	var pack: Backpack = packs[0]
	assert_gt(pack.iid, Config.DROP_IID_BASE - 1)
	assert_eq(pack.contents.count(I.MEDKIT), 1)
	assert_eq(pack.contents.count(I.PLANK), 4)
	assert_true(pack.contents.has_key(&"generator"))
	assert_lt(Vector2(pack.global_position.x - at.x, pack.global_position.z - at.z).length(), 1.5, "where they fell")
	assert_eq(count(calls, &"on_backpack_dropped"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_backpack_dropped")[0][1], [1, pack])


func test_nothing_to_carry_means_no_backpack() -> void:
	var g := await new_game()
	g.damage_player(1, 9999)
	assert_eq(_backpacks(g).size(), 0)


func test_another_player_loots_the_backpack_and_it_is_gone_when_empty() -> void:
	var g := await new_game()
	var calls := spy(g)
	g._add_player(7, "Guest")
	g.give_item(1, I.MEDKIT)
	g.give_item(1, I.BANDAGE, 3)
	g.give_key(1, &"generator")
	g.kill_player(1) # (not down: there is a teammate, but this is about the pack)
	var pack: Backpack = _backpacks(g)[0]
	var iid := pack.iid
	g.players[7].pos = pack.global_position + Vector3(1, 0, 0)
	assert_true(g.host_interact(7, iid))
	var theirs: Inventory = g.players[7].inventory
	assert_eq(theirs.count(I.MEDKIT), 1)
	assert_eq(theirs.count(I.BANDAGE), 3)
	assert_true(theirs.has_key(&"generator"))
	assert_eq(count(calls, &"on_right_click_backpack"), 1)
	assert_false(g.interactables.has(iid), "an empty pack is gone")
	await frames(2)
	assert_false(is_instance_valid(pack))


func test_a_full_pack_is_only_part_emptied() -> void:
	var g := await new_game()
	g._add_player(7, "Guest")
	g.give_item(1, I.MEDKIT, 2)
	g.kill_player(1) # (not down: there is a teammate, but this is about the pack)
	var pack: Backpack = _backpacks(g)[0]
	assert_eq(I.cap_of(I.MEDKIT), 2)
	g.give_item(7, I.MEDKIT, 1)
	g.players[7].pos = pack.global_position
	g.host_interact(7, pack.iid)
	assert_eq(g.players[7].inventory.count(I.MEDKIT), 2, "up to their cap")
	assert_true(g.interactables.has(pack.iid), "one was already in their pocket: the pack keeps the other")
	assert_eq(pack.contents.count(I.MEDKIT), 1)


func test_a_backpack_cannot_be_looted_from_across_the_map() -> void:
	var g := await new_game()
	g._add_player(7, "Guest")
	g.give_item(1, I.MEDKIT)
	g.kill_player(1) # (not down: there is a teammate, but this is about the pack)
	var pack: Backpack = _backpacks(g)[0]
	g.players[7].pos = pack.global_position + Vector3(40, 0, 0)
	assert_false(g.host_interact(7, pack.iid))
	assert_eq(g.players[7].inventory.count(I.MEDKIT), 0)


func test_a_late_joiner_builds_a_backpack_from_its_state() -> void:
	var g := await new_game()
	g.give_item(1, I.BANDAGE, 2)
	g.give_key(1, &"generator")
	g.damage_player(1, 9999)
	var pack: Backpack = _backpacks(g)[0]
	var state := pack.get_state()
	assert_true(state.drop)
	var iid := Config.DROP_IID_BASE + 800
	g._apply_interact_state(iid, state) # what `welcome` does with a state for an id it has never seen
	var copy: Backpack = g.interactables[iid]
	assert_eq(copy.contents.count(I.BANDAGE), 2)
	assert_true(copy.contents.has_key(&"generator"))
	assert_eq(copy.position, pack.position)
	assert_true(copy.dynamic)
	var gone := state.duplicate(true)
	gone.by = 0
	g._apply_interact_state(iid + 1, gone)
	assert_false(g.interactables.has(iid + 1), "an empty one is never built")


func test_only_so_many_backpacks_lie_around() -> void:
	var g := await new_game()
	var first := 0
	for i in Config.BACKPACKS_MAX + 3:
		g.give_item(1, I.BANDAGE)
		g.damage_player(1, 9999) # the corridor lets the dead come back, so there is always someone to die again
		if i == 0:
			first = _backpacks(g)[0].iid
	assert_eq(_backpacks(g).size(), Config.BACKPACKS_MAX)
	assert_false(g.interactables.has(first), "the oldest went first")


func test_a_lootbox_medkit_goes_into_the_inventory_and_stays_shut_when_there_is_no_room() -> void:
	var g := await new_game()
	g.local_player.teleport(g.lootbox.global_position + Vector3(-1.5, 0.1, 0))
	await frames(2)
	g.players[1].pos = g.local_player.global_position
	g.give_item(1, I.MEDKIT, I.cap_of(I.MEDKIT))
	assert_false(g.lootbox.opened)
	g.host_interact(1, g.lootbox.iid)
	assert_false(g.lootbox.opened, "no room: the crate stays shut for when there is")
	g.damage_player(1, 30)
	assert_true(g.use_item(1, I.MEDKIT))
	g.tick_status(I.use_time(I.MEDKIT))
	g.host_interact(1, g.lootbox.iid)
	assert_true(g.lootbox.opened)
	assert_eq(g.players[1].inventory.count(I.MEDKIT), I.cap_of(I.MEDKIT), "one used, one found")
