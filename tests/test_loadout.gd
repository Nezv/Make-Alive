extends TestCase
## What a player carries: two primaries, a sidearm, a melee slot; swapping when the slots are full,
## the old gun dropped at the feet with what was in its magazine, keys by slot, the last-weapon key.

const S := Loadout.Slot


func _active(m: GameMap) -> Array:
	return m.spots.filter(func(s: WeaponPickup) -> bool: return s.weapon >= 0)


## A city match where guns must be found: the host player (id 1) with just the pistol.
func _found_game() -> Game:
	var g := await new_game("city", "terminal", true)
	return g


func test_every_gun_has_a_slot_kind_and_a_draw_time() -> void:
	assert_eq(Weapons.kind_of(Weapons.P19), Weapons.Kind.SIDEARM)
	for id in Weapons.COUNT:
		if id != Weapons.P19:
			assert_eq(Weapons.kind_of(id), Weapons.Kind.PRIMARY, Weapons.def(id).name)
		assert_gt(Weapons.draw_time(id), 0.0)
	assert_lt(Weapons.draw_time(Weapons.P19), Weapons.draw_time(Weapons.AK47), "a pistol comes up faster")
	assert_gt(Weapons.draw_time(Weapons.T5000), Weapons.draw_time(Weapons.AK47), "a heavy rifle slower")


func test_a_mission_loadout_starts_with_the_pistol_in_the_sidearm_slot() -> void:
	var lo := Loadout.pistol()
	assert_eq(lo.slots, [-1, -1, Weapons.P19, -1])
	assert_true(lo.has(Weapons.P19))
	assert_false(lo.has(Weapons.AK47))
	assert_eq(lo.guns(), [Weapons.P19])
	assert_eq(lo.key(S.SIDEARM), Weapons.P19)
	assert_eq(lo.key(S.PRIMARY_1), -1)
	assert_eq(lo.key(7), -1, "no such slot")


func test_guns_fill_the_free_slot_of_their_kind() -> void:
	var lo := Loadout.pistol()
	assert_eq(lo.would_drop(Weapons.AK47, Weapons.P19), -1)
	assert_eq(lo.take(Weapons.AK47, Weapons.P19), -1)
	assert_eq(lo.take(Weapons.SPAS12, Weapons.AK47), -1)
	assert_eq(lo.slots, [Weapons.AK47, Weapons.SPAS12, Weapons.P19, -1])
	assert_eq(lo.key(S.PRIMARY_2), Weapons.SPAS12)
	assert_eq(lo.guns(), [Weapons.AK47, Weapons.SPAS12, Weapons.P19])


func test_full_slots_swap_the_held_gun_or_the_first_of_that_kind() -> void:
	var lo := Loadout.pistol()
	lo.take(Weapons.AK47, Weapons.P19)
	lo.take(Weapons.SPAS12, Weapons.AK47)
	assert_eq(lo.would_drop(Weapons.T5000, Weapons.SPAS12), Weapons.SPAS12, "the primary in your hands goes")
	assert_eq(lo.take(Weapons.T5000, Weapons.SPAS12), Weapons.SPAS12)
	assert_eq(lo.slots, [Weapons.AK47, Weapons.T5000, Weapons.P19, -1])
	assert_eq(lo.take(Weapons.P90, Weapons.P19), Weapons.AK47, "holding the pistol: the first primary goes")
	assert_eq(lo.slots, [Weapons.P90, Weapons.T5000, Weapons.P19, -1])
	assert_eq(lo.take(Weapons.P90, Weapons.P90), -1, "a gun you already carry changes nothing")
	assert_eq(lo.slots, [Weapons.P90, Weapons.T5000, Weapons.P19, -1])


func test_cycling_walks_the_carried_guns_in_slot_order() -> void:
	var lo := Loadout.pistol()
	lo.take(Weapons.AK47, Weapons.P19)
	lo.take(Weapons.SPAS12, Weapons.AK47)
	assert_eq(lo.next(Weapons.AK47, 1), Weapons.SPAS12)
	assert_eq(lo.next(Weapons.SPAS12, 1), Weapons.P19)
	assert_eq(lo.next(Weapons.P19, 1), Weapons.AK47, "round again")
	assert_eq(lo.next(Weapons.AK47, -1), Weapons.P19)
	assert_eq(Loadout.pistol().next(Weapons.P19, 1), Weapons.P19, "nothing else to go to")


func test_a_test_map_loadout_holds_everything_and_keys_pick_by_gun() -> void:
	var lo := Loadout.all()
	assert_true(lo.everything)
	assert_eq(lo.guns().size(), Weapons.COUNT)
	for id in Weapons.COUNT:
		assert_true(lo.has(id))
		assert_eq(lo.key(id), id)
	assert_eq(lo.take(Weapons.AK47, Weapons.P19), -1)
	assert_eq(lo.next(Weapons.DRAGUNOV, 1), Weapons.P19)


func test_a_loadout_travels_as_its_slots() -> void:
	var lo := Loadout.pistol()
	lo.take(Weapons.AK47, Weapons.P19)
	var copy := Loadout.from_state(lo.get_state())
	assert_eq(copy.slots, lo.slots)
	assert_false(copy.everything)
	assert_true(Loadout.from_state(Loadout.all().get_state()).everything)


func test_heavy_guns_take_longer_to_draw() -> void:
	var w := WeaponState.new()
	w.switch_to(Weapons.T5000)
	assert_near(w.draw_left, Weapons.draw_time(Weapons.T5000), 0.001)
	assert_near(w.draw_total, Weapons.draw_time(Weapons.T5000), 0.001)
	w.step(Weapons.draw_time(Weapons.P19) + 0.01)
	assert_false(w.try_fire(), "still coming up")
	w.switch_to(Weapons.P19)
	w.step(Weapons.draw_time(Weapons.P19) + 0.01)
	assert_true(w.try_fire(), "the pistol is out already")


func test_missions_start_with_the_pistol_and_free_play_with_everything() -> void:
	var g := await _found_game()
	assert_false(g.local_player.loadout.everything)
	assert_eq(g.local_player.loadout.guns(), [Weapons.P19])
	assert_eq(g.local_player.weapons.current, Weapons.P19)
	assert_eq(g.players[1].loadout.guns(), [Weapons.P19], "the host agrees")
	assert_eq(g.players[1].weapon, Weapons.P19)
	var free := await new_game("city")
	assert_true(free.local_player.loadout.everything)
	var corridor := await new_game()
	assert_eq(corridor.local_player.loadout.guns().size(), Weapons.COUNT)


func test_number_keys_follow_slots_wheel_cycles_and_last_weapon_goes_back() -> void:
	var g := await _found_game()
	var lp := g.local_player
	g.give_weapon(1, Weapons.AK47)
	g.give_weapon(1, Weapons.SPAS12)
	assert_eq(lp.weapons.current, Weapons.SPAS12, "what you pick up is in your hands")
	lp.press_weapon_key(S.PRIMARY_1)
	assert_eq(lp.weapons.current, Weapons.AK47)
	lp.press_weapon_key(S.SIDEARM)
	assert_eq(lp.weapons.current, Weapons.P19)
	lp.press_weapon_key(S.MELEE)
	assert_eq(lp.weapons.current, Weapons.P19, "an empty slot does nothing")
	lp.switch_last()
	assert_eq(lp.weapons.current, Weapons.AK47, "back to the one before")
	lp.switch_last()
	assert_eq(lp.weapons.current, Weapons.P19, "and back again")
	lp.cycle_weapon(1)
	assert_eq(lp.weapons.current, Weapons.AK47)
	lp.cycle_weapon(1)
	assert_eq(lp.weapons.current, Weapons.SPAS12)
	lp.cycle_weapon(-1)
	assert_eq(lp.weapons.current, Weapons.AK47)
	assert_true(InputMap.has_action("last_weapon"))


func test_taking_a_third_primary_drops_the_held_one_at_your_feet_with_its_magazine() -> void:
	var g := await _found_game()
	var calls := spy(g)
	var lp := g.local_player
	g.give_weapon(1, Weapons.AK47)
	g.give_weapon(1, Weapons.SPAS12)
	lp.switch_weapon(Weapons.AK47)
	lp.weapons.ammo[Weapons.AK47] = 11
	var spot: WeaponPickup = _active(g.map).filter(func(s: WeaponPickup) -> bool:
		return s.weapon != Weapons.AK47 and s.weapon != Weapons.SPAS12)[0]
	var found := spot.weapon
	lp.teleport(spot.stand + Vector3(0, 0.1, 0))
	await frames(3)
	g.players[1].pos = lp.global_position
	var before := g.interactables.size()
	g.interact_with(spot) # what a right-click does: it says what is in hand and how full it is
	assert_eq(lp.loadout.slots, [found, Weapons.SPAS12, Weapons.P19, -1])
	assert_eq(g.players[1].loadout.slots, lp.loadout.slots, "host and player agree")
	assert_eq(lp.weapons.current, found)
	assert_eq(spot.weapon, -1)
	assert_eq(g.interactables.size(), before + 1, "one new thing on the ground")
	var dropped: WeaponPickup = null
	for iid: int in g.interactables:
		if iid >= Config.DROP_IID_BASE and g.interactables[iid] is WeaponPickup:
			dropped = g.interactables[iid]
	assert_true(dropped != null)
	assert_eq(dropped.weapon, Weapons.AK47)
	assert_eq(dropped.rounds, 11, "with what was left in its magazine")
	assert_true(dropped.dynamic)
	assert_lt(dropped.global_position.distance_to(lp.global_position), 1.5, "at your feet")
	assert_eq(count(calls, &"on_weapon_dropped"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_weapon_dropped")[0][1], [1, Weapons.AK47, dropped])
	g._queue_shot(1, lp.global_position, Vector3.FORWARD, Weapons.AK47)
	assert_eq(g._pending_shots.size(), 0, "the host no longer takes shots from the gun you dropped")

	# Take it back: it comes with those eleven rounds, and the other one goes down in its place.
	lp.weapons.ammo[found] = 3
	g.interact_with(dropped)
	assert_eq(lp.weapons.current, Weapons.AK47)
	assert_eq(lp.weapons.rounds(), 11)
	assert_false(g.interactables.has(dropped.iid), "a dropped gun that is taken is gone")
	var again: WeaponPickup = null
	for iid: int in g.interactables:
		if iid >= Config.DROP_IID_BASE and g.interactables[iid] is WeaponPickup:
			again = g.interactables[iid]
	assert_eq(again.weapon, found)
	assert_eq(again.rounds, 3)
	await frames(2)
	assert_false(is_instance_valid(dropped))


func test_a_gun_you_already_carry_gives_you_its_magazine_as_ammo() -> void:
	var g := await _found_game()
	g.give_weapon(1, Weapons.AK47)
	var spot: WeaponPickup = _active(g.map)[0]
	spot.set_weapon(Weapons.AK47)
	spot.rounds = 12
	g.local_player.teleport(spot.stand + Vector3(0, 0.1, 0))
	await frames(3)
	g.players[1].pos = g.local_player.global_position
	var type := Weapons.ammo_of(Weapons.AK47)
	var have := g.ammo_of(1, type)
	g.interact_with(spot)
	assert_eq(g.ammo_of(1, type), have + 12)
	assert_eq(spot.weapon, -1)
	assert_eq(g.local_player.loadout.slots, [Weapons.AK47, -1, Weapons.P19, -1])


func test_a_late_joiner_builds_dropped_guns_from_their_state() -> void:
	var g := await _found_game()
	var drop := g.drop_weapon(Vector3(3, 0, 3), 1.0, Weapons.DRAGUNOV, 4)
	var state := drop.get_state()
	assert_true(state.drop)
	var iid := Config.DROP_IID_BASE + 700
	g._apply_interact_state(iid, state) # what `welcome` does with a state for an id it has never seen
	var copy: WeaponPickup = g.interactables[iid]
	assert_eq(copy.weapon, Weapons.DRAGUNOV)
	assert_eq(copy.rounds, 4)
	assert_true(copy.dynamic)
	assert_eq(copy.position, drop.position)
	assert_near(copy.rotation.y, drop.rotation.y, 0.001)
	assert_true(copy.gun != null, "lying there to be seen")
	var gone := state.duplicate()
	gone.weapon = -1
	g._apply_interact_state(iid, gone)
	assert_false(g.interactables.has(iid))
	g._apply_interact_state(iid + 1, gone)
	assert_false(g.interactables.has(iid + 1), "an empty drop is never built")


func test_dropped_ammo_cap_leaves_dropped_guns_alone() -> void:
	var g := await _found_game()
	var gun := g.drop_weapon(Vector3(3, 0, 3), 0.0, Weapons.AK47, 5)
	for i in Config.AMMO_DROPS_MAX + 2:
		g.drop_ammo_box(Vector3(0, 0, 0), Weapons.Ammo.MM9, 15)
	assert_true(g.interactables.has(gun.iid))
	assert_eq(gun.weapon, Weapons.AK47)
