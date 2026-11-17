extends TestCase
## Bleeding and healing: a zombie's hit may open a wound (up to three at once), wounds cost HP every few
## seconds until a bandage or medkit stops them; healing takes time, is spent only when it finishes, and
## any hit or a sprint cancels it. Painkillers give temporary HP that soaks up damage and wears off.

const I := preload("res://scripts/inventory.gd")


## A running host with the physics loop off (the tests tick the status themselves) and a zombie to do the hitting.
func _game() -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	return g


func _zombie(g: Game) -> Zombie:
	return g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 40))


func _status(g: Game) -> PlayerStatus:
	return g.players[1].status


# --- The status itself (no nodes) -----------------------------------------------------

func test_a_hit_opens_a_wound_only_when_the_roll_is_under_the_chance() -> void:
	var s := PlayerStatus.new()
	assert_false(s.hurt(Config.BLEED_CHANCE), "a roll at the chance is a miss")
	assert_false(s.hurt(0.99))
	assert_eq(s.bleed, 0)
	assert_true(s.hurt(0.0))
	assert_eq(s.bleed, 1)


func test_wounds_stack_to_three_and_no_further() -> void:
	var s := PlayerStatus.new()
	assert_eq(Config.BLEED_MAX, 3)
	for i in 5:
		s.hurt(0.0)
	assert_eq(s.bleed, Config.BLEED_MAX)
	assert_false(s.hurt(0.0), "no fourth wound")


func test_bleeding_loses_hp_per_wound_every_interval() -> void:
	var s := PlayerStatus.new()
	assert_eq(s.bleed_damage(10.0), 0, "not bleeding")
	s.hurt(0.0)
	s.hurt(0.0)
	assert_eq(s.bleed_damage(Config.BLEED_INTERVAL * 0.5), 0, "not yet")
	assert_eq(s.bleed_damage(Config.BLEED_INTERVAL * 0.5), 2 * Config.BLEED_DAMAGE, "two wounds, one tick")
	assert_eq(s.bleed_damage(Config.BLEED_INTERVAL * 2.0), 2 * 2 * Config.BLEED_DAMAGE, "two ticks")
	assert_true(s.stop_bleeding())
	assert_false(s.stop_bleeding(), "nothing to stop")
	assert_eq(s.bleed_damage(100.0), 0)


func test_using_something_runs_down_and_hands_it_over_when_done() -> void:
	var s := PlayerStatus.new()
	assert_false(s.is_using())
	s.begin_use(I.BANDAGE, 1.5)
	assert_true(s.is_using())
	assert_eq(s.step_use(1.0), &"")
	assert_near(s.use_left, 0.5)
	assert_eq(s.step_use(0.6), I.BANDAGE, "done: this is what was used")
	assert_false(s.is_using())
	s.begin_use(I.MEDKIT, 3.0)
	assert_true(s.cancel_use())
	assert_false(s.cancel_use(), "nothing to cancel")
	assert_eq(s.step_use(10.0), &"")


func test_a_status_travels_as_a_dictionary() -> void:
	var s := PlayerStatus.new()
	s.hurt(0.0)
	s.begin_use(I.MEDKIT, 3.0)
	s.step_use(1.0)
	var copy := PlayerStatus.new()
	copy.apply_state(s.get_state())
	assert_eq(copy.bleed, 1)
	assert_eq(copy.using, I.MEDKIT)
	assert_near(copy.use_left, 2.0)
	assert_near(copy.use_total, 3.0)


func test_every_heal_has_a_use_time_and_throwables_none() -> void:
	assert_gt(I.use_time(I.MEDKIT), I.use_time(I.BANDAGE), "a medkit takes longer than a bandage")
	assert_gt(I.use_time(I.BANDAGE), 0.0)
	assert_gt(I.use_time(I.PAINKILLERS), 0.0)
	assert_eq(I.use_time(I.FRAG), 0.0)


# --- Temporary HP ---------------------------------------------------------------------

func test_temporary_hp_soaks_damage_first_and_wears_off() -> void:
	var h := Health.new()
	assert_eq(h.total(), 100)
	h.add_temp(30)
	assert_eq(h.total(), 130)
	h.damage(10)
	assert_eq(h.hp, 100, "the temporary HP took it")
	assert_eq(h.total(), 120)
	h.damage(30)
	assert_eq(h.hp, 90, "20 soaked, 10 got through")
	assert_eq(h.temp_hp(), 0)
	h.add_temp(30)
	h.decay_temp(5.0)
	assert_eq(h.temp_hp(), 30 - roundi(5.0 * Config.PAINKILLERS_DECAY))
	h.decay_temp(100.0)
	assert_eq(h.temp_hp(), 0)
	h.add_temp(30)
	h.add_temp(10)
	assert_eq(h.temp_hp(), 30, "they do not stack")
	h.reset()
	assert_eq(h.temp_hp(), 0, "a new life has none")


# --- In a match -----------------------------------------------------------------------

func test_only_a_zombies_hit_makes_you_bleed() -> void:
	var g := await _game()
	var calls := spy(g)
	var z := _zombie(g)
	g.damage_player(1, 5, z, 0.99)
	assert_eq(_status(g).bleed, 0, "a lucky hit")
	g.damage_player(1, 5, null, 0.0)
	assert_eq(_status(g).bleed, 0, "a fall or a stray bullet does not open a wound")
	g.damage_player(1, 5, z, 0.0)
	assert_eq(_status(g).bleed, 1)
	assert_eq(count(calls, &"on_player_bleeding"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_player_bleeding")[0][1], [1, 1])
	assert_eq(g.local_player.status.bleed, 1, "the player knows it")
	for i in 4:
		g.damage_player(1, 1, z, 0.0)
	assert_eq(_status(g).bleed, Config.BLEED_MAX)
	assert_eq(count(calls, &"on_player_bleeding"), Config.BLEED_MAX, "told once for each new wound")


func test_a_hit_that_does_no_damage_opens_nothing() -> void:
	var g := await _game()
	g.damage_player(1, 0, _zombie(g), 0.0)
	assert_eq(_status(g).bleed, 0)


func test_bleeding_ticks_hp_and_can_kill() -> void:
	var g := await _game()
	var calls := spy(g)
	var z := _zombie(g)
	g.damage_player(1, 1, z, 0.0)
	g.damage_player(1, 1, z, 0.0)
	assert_eq(g.players[1].health.hp, 98)
	g.tick_status(Config.BLEED_INTERVAL)
	assert_eq(g.players[1].health.hp, 98 - 2 * Config.BLEED_DAMAGE)
	assert_eq(count(calls, &"on_player_damaged"), 3, "a tick of bleeding is damage taken")
	g.players[1].health.hp = 1
	g.tick_status(Config.BLEED_INTERVAL)
	assert_eq(count(calls, &"on_player_died"), 1, "bled to death")
	assert_eq(_status(g).bleed, 0, "and the next life starts clean")
	assert_eq(g.players[1].health.hp, Config.PLAYER_HP)


func test_a_bandage_takes_time_stops_the_bleeding_and_closes_a_wound() -> void:
	var g := await _game()
	var calls := spy(g)
	g.give_item(1, I.BANDAGE, 2)
	g.damage_player(1, 20, _zombie(g), 0.0)
	assert_true(g.use_item(1, I.BANDAGE))
	assert_true(_status(g).is_using())
	assert_eq(g.local_player.status.using, I.BANDAGE, "the player sees it going on")
	assert_false(g.use_item(1, I.BANDAGE), "one thing at a time")
	g.tick_status(I.use_time(I.BANDAGE) * 0.5)
	assert_eq(g.players[1].inventory.count(I.BANDAGE), 2, "not spent until it is done")
	assert_eq(_status(g).bleed, 1)
	g.tick_status(I.use_time(I.BANDAGE) * 0.6)
	assert_false(_status(g).is_using())
	assert_eq(g.players[1].inventory.count(I.BANDAGE), 1)
	assert_eq(_status(g).bleed, 0)
	assert_eq(g.players[1].health.hp, 80 + Config.BANDAGE_HEAL)
	assert_eq(count(calls, &"on_item_used"), 1)
	assert_eq(count(calls, &"on_player_healed"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_player_healed")[0][1], [1, I.BANDAGE, Config.BANDAGE_HEAL])
	assert_eq(g.local_player.status.bleed, 0)
	assert_false(g.local_player.status.is_using())


func test_a_bandage_is_for_the_hurt_or_the_bleeding() -> void:
	var g := await _game()
	g.give_item(1, I.BANDAGE)
	assert_false(g.can_use_item(1, I.BANDAGE), "unhurt and not bleeding")
	_status(g).bleed = 1
	assert_true(g.can_use_item(1, I.BANDAGE), "bleeding at full health is still worth a bandage")


func test_a_medkit_restores_hp_when_it_finishes_and_stops_the_bleeding() -> void:
	var g := await _game()
	g.give_item(1, I.MEDKIT)
	g.damage_player(1, 50, _zombie(g), 0.0)
	assert_eq(_status(g).bleed, 1)
	assert_true(g.use_item(1, I.MEDKIT))
	g.tick_status(I.use_time(I.MEDKIT) - 0.1)
	var before: int = g.players[1].health.hp
	assert_true(before <= 50, "nothing restored yet: it is still being used")
	assert_eq(_status(g).bleed, 1)
	g.tick_status(0.2)
	assert_eq(g.players[1].health.hp, before + Config.MEDKIT_HEAL)
	assert_eq(_status(g).bleed, 0)
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 0)


func test_a_hit_cancels_healing_and_the_item_is_kept() -> void:
	var g := await _game()
	var calls := spy(g)
	g.give_item(1, I.MEDKIT)
	g.damage_player(1, 50)
	g.use_item(1, I.MEDKIT)
	g.tick_status(1.0)
	g.damage_player(1, 10)
	assert_false(_status(g).is_using(), "knocked out of it")
	assert_false(g.local_player.status.is_using())
	assert_eq(g.players[1].inventory.count(I.MEDKIT), 1, "still in the pack")
	assert_eq(count(calls, &"on_item_use_cancelled"), 1)
	assert_eq(count(calls, &"on_item_used"), 0)
	g.tick_status(10.0)
	assert_eq(g.players[1].health.hp, 40, "nothing was healed")
	assert_true(g.use_item(1, I.MEDKIT), "and it can be tried again")
	g.tick_status(I.use_time(I.MEDKIT) + 0.1)
	assert_eq(g.players[1].health.hp, 40 + Config.MEDKIT_HEAL)


func test_bleeding_does_not_stop_you_healing() -> void:
	var g := await _game()
	g.give_item(1, I.MEDKIT)
	g.damage_player(1, 20, _zombie(g), 0.0)
	g.use_item(1, I.MEDKIT)
	g.tick_status(Config.BLEED_INTERVAL + 0.5) # a tick of bleeding lands while the medkit is going on
	assert_eq(g.players[1].health.hp, 80 - Config.BLEED_DAMAGE, "the wound did cost HP")
	assert_true(_status(g).is_using(), "but its own damage never interrupts")


func test_sprinting_cancels_healing() -> void:
	var g := await _game()
	var lp := g.local_player
	g.give_item(1, I.BANDAGE)
	g.damage_player(1, 20)
	g.use_item(1, I.BANDAGE)
	lp.check_use_cancel(false)
	assert_true(_status(g).is_using(), "walking is fine")
	lp.check_use_cancel(true)
	assert_false(_status(g).is_using(), "running off is not")
	assert_false(lp.status.is_using())
	assert_eq(g.players[1].inventory.count(I.BANDAGE), 1)


func test_painkillers_give_temporary_hp_that_wears_off() -> void:
	var g := await _game()
	var calls := spy(g)
	g.give_item(1, I.PAINKILLERS, 2)
	assert_true(g.can_use_item(1, I.PAINKILLERS), "useful even unhurt")
	g.use_item(1, I.PAINKILLERS)
	g.tick_status(I.use_time(I.PAINKILLERS) + 0.01)
	var health: Health = g.players[1].health
	assert_eq(health.hp, Config.PLAYER_HP)
	assert_gt(health.temp_hp(), Config.PAINKILLERS_TEMP - 3)
	assert_eq(g.build_snapshot()[0][0].hp, health.total(), "and others see it, in the same byte")
	assert_false(g.can_use_item(1, I.PAINKILLERS), "no point taking more on top")
	g.damage_player(1, 10)
	assert_eq(health.hp, Config.PLAYER_HP, "it soaked the hit")
	g.tick_status(100.0)
	assert_eq(health.temp_hp(), 0, "worn off")
	assert_eq(count(calls, &"on_player_healed"), 0, "painkillers do not heal, they pad")
	assert_true(g.can_use_item(1, I.PAINKILLERS))


func test_a_new_life_clears_wounds_and_healing() -> void:
	var g := await _game()
	g.give_item(1, I.BANDAGE)
	g.damage_player(1, 1, _zombie(g), 0.0)
	g.use_item(1, I.BANDAGE)
	g.damage_player(1, 9999)
	assert_eq(_status(g).bleed, 0)
	assert_false(_status(g).is_using())
	assert_eq(g.local_player.status.bleed, 0)
	assert_false(g.local_player.status.is_using())


func test_others_see_who_is_bleeding_or_healing() -> void:
	var g := await _game()
	g.damage_player(1, 5, _zombie(g), 0.0)
	assert_true(g.build_snapshot()[0][0].action & PlayerWire.ACTION_BLEED != 0)
	assert_true(g.build_snapshot()[0][0].action & PlayerWire.ACTION_HEAL == 0)
	g.give_item(1, I.BANDAGE)
	g.use_item(1, I.BANDAGE)
	assert_true(g.build_snapshot()[0][0].action & PlayerWire.ACTION_HEAL != 0)
	var wire := PlayerWire.unpack(PlayerWire.pack(g.build_snapshot()[0]))
	assert_true(wire[0].action & PlayerWire.ACTION_BLEED != 0)


# --- How it looks ---------------------------------------------------------------------

func _viewmodel() -> Array:
	var vm := Viewmodel.new()
	add_child(vm)
	var w := WeaponState.new()
	w.switch_to(Weapons.AK47)
	w.step(1.0)
	vm.show_weapon(Weapons.AK47)
	return [vm, w]


func _run_vm(vm: Viewmodel, w: WeaponState, secs: float) -> void:
	var dt := 1.0 / 60.0
	for i in int(secs / dt):
		w.step(dt)
		vm.update(dt, 0.0, false, false, w)


func test_putting_on_a_bandage_lowers_the_gun_and_the_hands_wrap_through_four_poses() -> void:
	var a := _viewmodel()
	var vm: Viewmodel = a[0]
	_run_vm(vm, a[1], 0.5)
	var rest_y := vm.pivot.position.y
	assert_false(vm.bandage.visible, "no bandage in hand at rest")
	vm.heal_goal = 1.0
	_run_vm(vm, a[1], Config.HEAL_LOWER_TIME * 0.4)
	assert_true(vm.heal > 0.0 and vm.heal < 1.0, "eases down, no snap")
	_run_vm(vm, a[1], Config.HEAL_LOWER_TIME * 2.0)
	assert_near(vm.heal, 1.0, 0.01)
	assert_lt(vm.pivot.position.y, rest_y - 0.15, "the gun is down out of the way")
	assert_true(vm.bandage.visible)
	assert_eq(Viewmodel.HEAL_POSES.size(), 4)
	var seen := []
	for k in 4:
		var hands: Array = Viewmodel.heal_hands(k * Config.HEAL_POSE_TIME)
		assert_eq(hands, Viewmodel.HEAL_POSES[k], "pose %d is held exactly on its beat" % k)
		assert_false(hands in seen, "every pose is its own")
		seen.append(hands)
	assert_eq(Viewmodel.heal_hands(4 * Config.HEAL_POSE_TIME), Viewmodel.HEAL_POSES[0], "and round again")
	var mid: Array = Viewmodel.heal_hands(0.5 * Config.HEAL_POSE_TIME)
	var pose0: Array = Viewmodel.HEAL_POSES[0]
	var pose1: Array = Viewmodel.HEAL_POSES[1]
	assert_true((mid[0] as Vector3).distance_to(pose0[0]) > 0.001 and (mid[0] as Vector3).distance_to(pose1[0]) > 0.001, "eased between beats")
	vm.heal_goal = 0.0
	_run_vm(vm, a[1], Config.HEAL_LOWER_TIME * 2.0)
	assert_eq(vm.heal, 0.0, "cancelled: the gun comes back up")
	assert_false(vm.bandage.visible)
	vm.free()


func test_the_player_animates_what_is_being_put_on_and_stops_when_it_is_cancelled() -> void:
	var g := await _game()
	var lp := g.local_player
	g.give_item(1, I.BANDAGE)
	g.damage_player(1, 20)
	g.use_item(1, I.BANDAGE)
	lp.status.use_left = 99.0 # (the player's copy counts down by itself: a slow frame must not finish it)
	await frames(3)
	assert_eq(lp.view.heal_goal, 1.0, "a bandage going on")
	g.damage_player(1, 1)
	await frames(3)
	assert_eq(lp.view.heal_goal, 0.0, "a hit knocks it off")
	g.give_item(1, I.PAINKILLERS)
	g.use_item(1, I.PAINKILLERS)
	lp.status.use_left = 99.0
	await frames(3)
	assert_eq(lp.view.heal_goal, 1.0, "pills too")
	_status(g).begin_use(&"revive", 3.0)
	lp.status.apply_state(_status(g).get_state())
	await frames(3)
	assert_eq(lp.view.heal_goal, 0.0, "getting someone up is not a heal")


func test_others_see_the_heal_pose_on_the_remote_player() -> void:
	assert_eq(RemotePlayer.anim_for(PlayerWire.ACTION_HEAL, 0.0), Humanoid.Anim.HEAL)
	assert_eq(RemotePlayer.anim_for(PlayerWire.ACTION_HEAL | PlayerWire.ACTION_CROUCH, 0.0), Humanoid.Anim.HEAL)
	assert_eq(RemotePlayer.anim_for(PlayerWire.ACTION_HEAL | PlayerWire.ACTION_AIR, 0.0), Humanoid.Anim.JUMP, "off the ground wins")
	assert_eq(RemotePlayer.anim_for(0, 0.0), Humanoid.Anim.IDLE)
	assert_eq(RemotePlayer.anim_for(0, 3.0), Humanoid.Anim.WALK)
	var rig := Characters.survivor(2)
	add_child(rig)
	rig.set_anim(Humanoid.Anim.HEAL)
	for i in 60:
		rig.update(1.0 / 60.0, 0.0)
	assert_gt(rig._cur[Humanoid.J.NECK_PITCH], 0.2, "looking down at the wound")
	assert_gt(rig._cur[Humanoid.J.EL_L], 0.8, "the arm held across the body")
	assert_gt(rig._cur[Humanoid.J.EL_R], 0.8)
	var before := rig._cur[Humanoid.J.SH_R_X]
	for i in 20:
		rig.update(1.0 / 60.0, 0.0)
	assert_true(absf(rig._cur[Humanoid.J.SH_R_X] - before) > 0.01, "the right hand keeps wrapping")
	rig.free()


func test_a_bleeding_player_leaves_drops_behind_them() -> void:
	var t := BleedTrail.new()
	assert_false(t.step(1, Vector3.ZERO, false, 0.1), "not bleeding")
	assert_true(t.step(1, Vector3.ZERO, true, 0.1), "the first drop falls at once")
	assert_false(t.step(1, Vector3(0.2, 0, 0), true, 0.1))
	assert_true(t.step(1, Vector3(Config.BLEED_DRIP_STEP + 0.01, 0, 0), true, 0.1), "a drop every few steps")
	assert_false(t.step(1, Vector3(Config.BLEED_DRIP_STEP + 0.01, 0, 0), true, Config.BLEED_DRIP_IDLE * 0.5))
	assert_true(t.step(1, Vector3(Config.BLEED_DRIP_STEP + 0.01, 0, 0), true, Config.BLEED_DRIP_IDLE * 0.6), "standing still it drips in place")
	assert_true(t.step(2, Vector3(5, 0, 5), true, 0.1), "everyone has their own trail")
	var g := await _game()
	var before: int = g.gore.stats.splats
	g.damage_player(1, 5, _zombie(g), 0.0)
	g.update_drips(0.1)
	g.local_player.global_position += Vector3(Config.BLEED_DRIP_STEP * 1.5, 0, 0)
	g.update_drips(0.1)
	assert_eq(g.gore.stats.splats, before + 2, "two drops on the floor")


func test_blood_runs_up_from_the_bottom_of_the_screen_while_bleeding() -> void:
	var drops := BleedDrops.new()
	drops.size = Vector2(1600, 900)
	drops.bleed = 0
	drops.step(1.0)
	assert_eq(drops.drops.size(), 0)
	drops.bleed = 2
	for i in 60:
		drops.step(1.0 / 30.0)
	assert_gt(drops.drops.size(), 0, "drops on the screen")
	assert_true(drops.drops.size() <= 2 * Config.BLEED_SCREEN_DROPS, "a few per wound")
	for d: Dictionary in drops.drops:
		assert_gt((d.pos as Vector2).y, drops.size.y * 0.55, "only the lower edge")
	drops.bleed = 0
	for i in 120:
		drops.step(1.0 / 30.0)
	assert_eq(drops.drops.size(), 0, "they fade once the bleeding stops")
	drops.free()


func test_a_heartbeat_when_hp_is_low_and_faster_the_lower_it_is() -> void:
	assert_true(Sfx.stream("heartbeat") != null, "a heartbeat sound")
	var h := Heartbeat.new()
	var beats := 0
	for i in 300:
		if h.step(0.02, Config.PLAYER_HP):
			beats += 1
	assert_eq(beats, 0, "healthy: no heartbeat")
	var low := int(Config.PLAYER_HP * Config.LOW_HP_FRACTION)
	for i in 300:
		if h.step(0.02, low):
			beats += 1
	var near_death := 0
	for i in 300:
		if h.step(0.02, 3):
			near_death += 1
	assert_gt(beats, 2, "hurt: it beats")
	assert_gt(near_death, beats, "faster near death")
	assert_false(h.step(10.0, 0), "the dead have none")


func test_the_dead_do_not_bleed_or_heal() -> void:
	var g := await _game()
	g.give_item(1, I.BANDAGE)
	g.damage_player(1, 5, _zombie(g), 0.0)
	g.rules.set_out(1, true)
	assert_false(g.use_item(1, I.BANDAGE))
	var hp: int = g.players[1].health.hp
	g.tick_status(Config.BLEED_INTERVAL * 3.0)
	assert_eq(g.players[1].health.hp, hp, "no more bleeding for someone already out")
