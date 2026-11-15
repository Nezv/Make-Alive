extends TestCase
## Guns: the stats table, magazines and reloading, random recoil, and what the host does with a shot.

const NAMES := ["P19", "P90", "Type 95", "AK47", "AS Val", "USAS-12", "SPAS-12", "Orsis T-5000", "Dragunov"]


func test_all_nine_guns_exist_with_sane_numbers() -> void:
	assert_eq(Weapons.COUNT, 9)
	for id in Weapons.COUNT:
		var d := Weapons.def(id)
		assert_eq(d.name, NAMES[id], "gun %d" % id)
		assert_gt(d.damage, 0, d.name + " damage")
		assert_gt(d.interval, 0.0, d.name + " interval")
		assert_gt(d.mag, 0, d.name + " magazine")
		assert_gt(d.reload, 0.0, d.name + " reload time")
		assert_gt(d.pellets, 0, d.name + " pellets")
		assert_lt(d.ads_spread, d.spread + 0.0001, d.name + " is no worse when aimed")
		assert_lt(d.ads_fov, Config.FOV, d.name + " zooms when aimed")


func test_firing_uses_a_round_and_respects_the_fire_rate() -> void:
	var w := WeaponState.new()
	w.switch_to(Weapons.AK47)
	w.step(Config.WEAPON_DRAW_TIME + 0.01)
	var mag: int = Weapons.def(Weapons.AK47).mag
	assert_true(w.try_fire(), "first shot")
	assert_eq(w.rounds(), mag - 1)
	assert_false(w.try_fire(), "too soon for a second shot")
	w.step(Weapons.def(Weapons.AK47).interval + 0.001)
	assert_true(w.try_fire(), "second shot after the interval")
	assert_eq(w.rounds(), mag - 2)


func test_empty_gun_wont_fire_until_the_reload_finishes() -> void:
	var w := WeaponState.new()
	w.draw_left = 0.0
	w.ammo[w.current] = 0
	assert_false(w.try_fire(), "click")
	assert_true(w.start_reload())
	assert_false(w.start_reload(), "already reloading")
	var t: float = w.def().reload
	w.step(t * 0.9)
	assert_true(w.is_reloading())
	assert_eq(w.rounds(), 0, "not loaded until the animation is done")
	assert_false(w.try_fire())
	w.step(t * 0.2)
	assert_false(w.is_reloading())
	assert_eq(w.rounds(), w.def().mag)
	assert_true(w.try_fire())


func test_full_gun_does_not_reload() -> void:
	var w := WeaponState.new()
	assert_false(w.start_reload())


func test_spas_loads_one_shell_at_a_time_and_a_shot_interrupts() -> void:
	var w := WeaponState.new()
	w.switch_to(Weapons.SPAS12)
	w.step(1.0)
	w.ammo[Weapons.SPAS12] = 2
	assert_true(w.start_reload())
	var per: float = w.def().reload
	w.step(per + 0.01)
	assert_eq(w.rounds(), 3, "one shell in")
	assert_true(w.is_reloading(), "and it keeps going")
	w.step(per + 0.01)
	assert_eq(w.rounds(), 4)
	assert_true(w.try_fire(), "firing cuts the reload short")
	assert_false(w.is_reloading())
	assert_eq(w.rounds(), 3)


func test_switching_keeps_each_guns_ammo_and_cancels_a_reload() -> void:
	var w := WeaponState.new()
	w.draw_left = 0.0
	w.try_fire()
	var left := w.rounds()
	w.start_reload()
	assert_true(w.switch_to(Weapons.P19))
	assert_false(w.is_reloading(), "reload cancelled")
	assert_false(w.try_fire(), "still drawing the pistol")
	w.step(Config.WEAPON_DRAW_TIME + 0.01)
	assert_true(w.try_fire())
	w.switch_to(Weapons.DEFAULT)
	assert_eq(w.rounds(), left, "the rifle kept its half-used magazine")
	assert_false(w.switch_to(99), "no such gun")


func test_recoil_is_random_but_bounded_and_smaller_when_aiming() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var d := Weapons.def(Weapons.AK47)
	var seen := {}
	var hip_total := 0.0
	var ads_total := 0.0
	for i in 200:
		var k := Weapons.kick(d, rng, false)
		seen[snappedf(k.x, 0.0001)] = true
		hip_total += k.x
		assert_gt(k.x, 0.0, "always climbs")
		assert_lt(k.x, d.recoil * (1.0 + Config.RECOIL_JITTER) + 0.0001, "pitch bounded")
		assert_lt(absf(k.y), d.recoil * d.recoil_side + 0.0001, "sideways bounded")
		ads_total += Weapons.kick(d, rng, true).x
	assert_gt(seen.size(), 50, "no two shots kick the same")
	assert_lt(ads_total, hip_total, "aiming tames it")


func test_bullets_scatter_less_when_aiming() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var d := Weapons.def(Weapons.P90)
	var hip := 0.0
	var ads := 0.0
	for i in 100:
		hip += Vector3.FORWARD.angle_to(Weapons.scatter(Vector3.FORWARD, Weapons.spread(d, false, 0.0), rng))
		ads += Vector3.FORWARD.angle_to(Weapons.scatter(Vector3.FORWARD, Weapons.spread(d, true, 0.0), rng))
		assert_lt(Vector3.FORWARD.angle_to(Weapons.scatter(Vector3.FORWARD, 0.05, rng)), 0.0501, "inside the cone")
	assert_lt(ads, hip * 0.6)
	assert_gt(Weapons.spread(d, false, 1.0), Weapons.spread(d, false, 0.0), "moving opens the cone")


func test_host_applies_the_guns_own_damage() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	await frames(2)
	var chest := z.rig.spine.global_position + Vector3(0, 0.25, 0)
	var from := chest + Vector3(0, 0, 3)
	g.resolve_shot(1, from, (chest - from).normalized(), Weapons.P19)
	assert_eq(count(calls, &"on_zombie_hit"), 1)
	assert_eq(calls[-1][1][2], Weapons.def(Weapons.P19).damage, "pistol damage, not rifle damage")


func test_shotgun_fires_a_cloud_of_pellets() -> void:
	var g := await new_game()
	var calls := spy(g)
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	z.hp = 100000
	await frames(2)
	var chest := z.rig.spine.global_position + Vector3(0, 0.25, 0)
	var from := chest + Vector3(0, 0, 1.2)
	g.rng.seed = 11
	g.resolve_shot(1, from, (chest - from).normalized(), Weapons.SPAS12)
	assert_gt(count(calls, &"on_zombie_hit"), 3, "most pellets land at point-blank")
	assert_lt(count(calls, &"on_zombie_hit"), Weapons.def(Weapons.SPAS12).pellets + 1)


func test_host_rate_limits_each_gun_by_its_own_fire_rate() -> void:
	var g := await new_game()
	g._queue_shot(1, Vector3(0, 1.6, 26), Vector3.FORWARD, Weapons.T5000)
	g._queue_shot(1, Vector3(0, 1.6, 26), Vector3.FORWARD, Weapons.T5000)
	assert_eq(g._pending_shots.size(), 1, "a bolt-action can't fire twice in one tick")
	assert_eq(g.players[1].weapon, Weapons.T5000, "host knows what the player is holding")
	g._queue_shot(1, Vector3(0, 1.6, 26), Vector3.FORWARD, 99)
	assert_eq(g._pending_shots.size(), 1, "unknown gun ignored")
