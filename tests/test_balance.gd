extends TestCase
## The balance sheet: time-to-kill of every gun against every zombie type, and the rules the
## numbers in weapons.gd must keep. A failure here means a tuning change broke a promise.


func test_shots_to_kill_matches_what_the_zombie_does() -> void:
	# The sheet must agree with Zombie.take_hit, or tuning by it is tuning by fiction.
	for gun in Weapons.COUNT:
		for type: int in Zombie.STATS:
			for part: int in [Humanoid.Part.HEAD, Humanoid.Part.TORSO, Humanoid.Part.LEG_L]:
				var z := Zombie.create(900 + gun, type, false, Vector3.ZERO)
				var d := Weapons.def(gun)
				var shots := 0
				var dead := false
				while not dead and shots < 500:
					shots += 1
					for p: int in d.pellets:
						if z.take_hit(part, d.damage).killed:
							dead = true
				assert_eq(Balance.shots_to_kill(gun, type, part), shots, "%s vs type %d part %d" % [d.name, type, part])
				z.free()


func test_time_to_kill_counts_fire_rate_and_reloads() -> void:
	var d := Weapons.def(Weapons.P19)
	var shots := Balance.shots_to_kill(Weapons.P19, Zombie.Type.WALKER, Humanoid.Part.TORSO)
	assert_near(Balance.seconds_to_kill(Weapons.P19, Zombie.Type.WALKER, Humanoid.Part.TORSO), (shots - 1) * d.interval, 0.001)
	assert_near(Balance.seconds_for_shots(Weapons.P19, 1), 0.0, 0.001, "the first shot is instant")
	assert_near(Balance.seconds_for_shots(Weapons.P19, d.mag + 1), d.mag * d.interval + d.reload, 0.001, "one reload in the middle")
	var s := Weapons.def(Weapons.SPAS12)
	assert_near(Balance.full_reload(Weapons.SPAS12), s.reload * s.mag, 0.001, "shells go in one at a time")


func test_a_sniper_headshot_kills_any_zombie() -> void:
	for type: int in Zombie.STATS:
		assert_eq(Balance.shots_to_kill(Weapons.T5000, type, Humanoid.Part.HEAD), 1, "T-5000")
		assert_eq(Balance.shots_to_kill(Weapons.DRAGUNOV, type, Humanoid.Part.HEAD), 1, "Dragunov")
		assert_eq(Balance.shots_to_kill(Weapons.T5000, type, Humanoid.Part.TORSO), 1, "the bolt rifle stops anything it hits")


func test_the_pistol_is_never_the_best_dps() -> void:
	var best_sustained := 0.0
	for gun in Weapons.COUNT:
		best_sustained = maxf(best_sustained, Balance.sustained_dps(gun))
		if gun != Weapons.P19:
			assert_gt(Balance.burst_dps(gun), Balance.burst_dps(Weapons.P19), Weapons.def(gun).name + " hits harder per second than the pistol")
	assert_lt(Balance.sustained_dps(Weapons.P19), best_sustained, "nor is it the best over a whole magazine and reload")


func test_every_gun_can_kill_every_zombie_with_one_magazine_of_headshots() -> void:
	for gun in Weapons.COUNT:
		for type: int in Zombie.STATS:
			assert_lt(Balance.shots_to_kill(gun, type, Humanoid.Part.HEAD), Weapons.def(gun).mag + 1,
				"%s vs type %d" % [Weapons.def(gun).name, type])


func test_shotguns_are_short_range_and_snipers_long() -> void:
	var shotgun := maxf(Balance.effective_range(Weapons.SPAS12), Balance.effective_range(Weapons.USAS12))
	for gun in Weapons.COUNT:
		if gun != Weapons.SPAS12 and gun != Weapons.USAS12:
			assert_gt(Balance.effective_range(gun), shotgun, Weapons.def(gun).name + " reaches further than a shotgun")
	assert_gt(Balance.effective_range(Weapons.T5000), Balance.effective_range(Weapons.AK47))
	assert_lt(Balance.effective_range(Weapons.T5000), Weapons.def(Weapons.T5000).range + 0.01, "never beyond the gun's own range")


func test_sheet_has_a_row_per_gun_and_zombie() -> void:
	var text := Balance.sheet()
	for gun in Weapons.COUNT:
		assert_true(text.contains("| " + Weapons.def(gun).name + " "), Weapons.def(gun).name)
	for type_name: String in Zombie.Type.keys():
		assert_true(text.contains(type_name.capitalize()), type_name)
	assert_true(text.contains("Kills / mag"))
