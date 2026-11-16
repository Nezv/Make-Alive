extends TestCase
## Limited ammo: calibres, the reserve a reload takes from, dry fire, what the host knows, the HUD.


func _limited(type: int, rounds: int) -> WeaponState:
	var w := WeaponState.new()
	w.limit({ type: rounds })
	w.draw_left = 0.0
	return w


func test_every_gun_has_a_calibre_and_the_shotguns_share_shells() -> void:
	assert_eq(Weapons.Ammo.COUNT, 8)
	assert_eq(Weapons.AMMO.size(), Weapons.Ammo.COUNT)
	var used := {}
	for id in Weapons.COUNT:
		var type: int = Weapons.ammo_of(id)
		assert_true(type >= 0 and type < Weapons.Ammo.COUNT, Weapons.def(id).name + " has a calibre")
		used[type] = true
	assert_eq(used.size(), Weapons.Ammo.COUNT, "every calibre is fired by some gun")
	assert_eq(Weapons.ammo_of(Weapons.USAS12), Weapons.ammo_of(Weapons.SPAS12))
	assert_eq(Weapons.ammo_name(Weapons.ammo_of(Weapons.P19)), "9 mm")
	assert_eq(Weapons.ammo_id("12 gauge"), Weapons.Ammo.GAUGE12)
	assert_eq(Weapons.ammo_id("plasma"), -1)
	for type in Weapons.Ammo.COUNT:
		assert_gt(Weapons.AMMO[type].start, 0, Weapons.ammo_name(type) + " start")
		assert_gt(Weapons.AMMO[type].max, Weapons.AMMO[type].start, Weapons.ammo_name(type) + " max")


func test_a_new_weapon_state_never_runs_dry() -> void:
	var w := WeaponState.new()
	w.draw_left = 0.0
	assert_true(w.infinite)
	assert_eq(w.reserve_rounds(), -1, "-1 means no limit")
	w.ammo[w.current] = 0
	assert_false(w.is_dry())
	assert_true(w.start_reload())
	w.step(w.def().reload + 0.01)
	assert_eq(w.rounds(), w.def().mag)
	assert_true(w.take_spent().is_empty(), "nothing to tell the host")


func test_reload_takes_what_the_magazine_needs_from_the_reserve() -> void:
	var w := _limited(Weapons.Ammo.MM762, 90)
	w.ammo[Weapons.AK47] = 12
	assert_true(w.start_reload())
	assert_eq(w.reserve_rounds(), 90, "not taken until the magazine is in")
	w.step(w.def().reload + 0.01)
	assert_eq(w.rounds(), 30)
	assert_eq(w.reserve_rounds(), 72)
	assert_eq(w.take_spent(), { Weapons.Ammo.MM762: 18 })
	assert_true(w.take_spent().is_empty(), "reported once")


func test_reload_is_partial_when_the_reserve_is_short() -> void:
	var w := _limited(Weapons.Ammo.MM762, 7)
	w.ammo[Weapons.AK47] = 3
	assert_true(w.start_reload())
	w.step(w.def().reload + 0.01)
	assert_eq(w.rounds(), 10)
	assert_eq(w.reserve_rounds(), 0)
	assert_false(w.start_reload(), "nothing left to load")
	assert_false(w.is_dry(), "still ten in the magazine")


func test_other_calibres_do_not_feed_the_gun() -> void:
	var w := _limited(Weapons.Ammo.MM9, 45)
	w.ammo[Weapons.AK47] = 0
	assert_eq(w.reserve_rounds(), 0)
	assert_false(w.start_reload())
	assert_true(w.is_dry())
	assert_false(w.try_fire())


func test_shotgun_stops_loading_shells_when_the_reserve_is_empty() -> void:
	var w := _limited(Weapons.Ammo.GAUGE12, 2)
	w.switch_to(Weapons.SPAS12)
	w.step(1.0)
	w.ammo[Weapons.SPAS12] = 1
	assert_true(w.start_reload())
	var per: float = w.def().reload
	w.step(per + 0.01)
	assert_eq(w.rounds(), 2)
	assert_eq(w.reserve_rounds(), 1)
	assert_true(w.is_reloading(), "one shell left to push in")
	w.step(per + 0.01)
	assert_eq(w.rounds(), 3)
	assert_eq(w.reserve_rounds(), 0)
	assert_false(w.is_reloading(), "no more shells: the reload stops short of a full tube")
	w.step(per * 3.0)
	assert_eq(w.rounds(), 3)
	assert_eq(w.take_spent(), { Weapons.Ammo.GAUGE12: 2 })


func test_reserve_is_added_to_and_capped() -> void:
	var w := _limited(Weapons.Ammo.MM9, 10)
	assert_eq(w.add_reserve(Weapons.Ammo.MM9, 30), 30)
	assert_eq(w.reserve[Weapons.Ammo.MM9], 40)
	var cap: int = Weapons.AMMO[Weapons.Ammo.MM9].max
	assert_eq(w.add_reserve(Weapons.Ammo.MM9, 10000), cap - 40, "only what fits")
	assert_eq(w.reserve[Weapons.Ammo.MM9], cap)


func test_map_data_reads_the_starting_reserve_by_calibre_name() -> void:
	var d := MapData.new({ "name": "t", "starting_ammo": { "9 mm": 30, "12 gauge": 8 } })
	assert_eq(d.errors, [])
	assert_eq(d.starting_ammo, { Weapons.Ammo.MM9: 30, Weapons.Ammo.GAUGE12: 8 })
	var bad := MapData.new({ "name": "t", "starting_ammo": { "plasma": 5 } })
	assert_eq(bad.errors.size(), 1)
	assert_true(str(bad.errors[0]).contains("plasma"), str(bad.errors))


func test_a_map_starts_players_with_its_own_reserve_and_defaults_for_the_rest() -> void:
	var m := GameMap.new()
	m.use_data({ "name": "t", "starting_ammo": { "9 mm": 30 } })
	var start := m.starting_ammo()
	assert_eq(start.size(), Weapons.Ammo.COUNT)
	assert_eq(start[Weapons.Ammo.MM9], 30)
	assert_eq(start[Weapons.Ammo.MM762], Weapons.AMMO[Weapons.Ammo.MM762].start)


func test_test_maps_keep_infinite_ammo() -> void:
	var g := await new_game()
	assert_true(g.map.infinite_ammo)
	assert_true(g.local_player.weapons.infinite)
	assert_eq(g.ammo_of(1, Weapons.Ammo.MM762), -1)
	g._update_weapon()
	assert_true(g.hud.weapon_label.text.ends_with("30 / ∞"), g.hud.weapon_label.text)


func test_limited_game_gives_the_player_the_maps_reserve_and_the_host_knows_it() -> void:
	var g := await new_game("corridor", "", true)
	assert_false(g.map.infinite_ammo)
	var ws := g.local_player.weapons
	assert_false(ws.infinite)
	var start: int = g.map.starting_ammo()[Weapons.Ammo.MM762]
	assert_eq(ws.reserve_rounds(), start)
	assert_eq(g.ammo_of(1, Weapons.Ammo.MM762), start)
	g._update_weapon()
	assert_true(g.hud.weapon_label.text.ends_with("30 / %d" % start), g.hud.weapon_label.text)


func test_host_hears_about_a_reload_once_not_every_snapshot() -> void:
	var g := await new_game("corridor", "", true)
	var ws := g.local_player.weapons
	var start := ws.reserve_rounds()
	ws.draw_left = 0.0
	ws.ammo[ws.current] = 20
	ws.start_reload()
	ws.step(ws.def().reload + 0.01)
	g._update_weapon()
	assert_eq(g.ammo_of(1, Weapons.Ammo.MM762), start - 10)
	g._update_weapon()
	assert_eq(g.ammo_of(1, Weapons.Ammo.MM762), start - 10, "counted once")
	assert_true(g.hud.weapon_label.text.ends_with("30 / %d" % (start - 10)), g.hud.weapon_label.text)


func test_host_never_lets_a_reserve_go_below_zero_or_above_its_cap() -> void:
	var g := await new_game("corridor", "", true)
	var type := Weapons.Ammo.MM9
	g._ammo_used(1, type, 100000)
	assert_eq(g.ammo_of(1, type), 0)
	g._ammo_used(1, type, -50)
	assert_eq(g.ammo_of(1, type), 0, "a negative count is ignored")
	g._ammo_used(1, 99, 5)
	g._ammo_used(42, type, 5) # nobody: ignored
	assert_eq(g.give_ammo(1, type, 30), 30)
	assert_eq(g.ammo_of(1, type), 30)
	assert_eq(g.local_player.weapons.reserve[type], g.map.starting_ammo()[type] + 30, "the player got the rounds")
	var cap: int = Weapons.AMMO[type].max
	assert_eq(g.give_ammo(1, type, 100000), cap - 30)
	assert_eq(g.ammo_of(1, type), cap)
	assert_eq(g.give_ammo(1, 99, 5), 0, "no such calibre")
	assert_eq(g.give_ammo(42, type, 5), 0, "no such player")


func test_dry_fire_clicks_twitches_and_sends_no_shot() -> void:
	var g := await new_game("corridor", "", true)
	var lp := g.local_player
	var ws := lp.weapons
	ws.draw_left = 0.0
	ws.ammo[ws.current] = 0
	ws.reserve[Weapons.Ammo.MM762] = 0
	assert_true(Sfx.stream("dry_fire") != null, "there is a click sound")
	var played: int = Sfx.stats.played
	lp.firing = true
	lp.fire_buffer = Config.FIRE_BUFFER
	g._update_weapon()
	assert_eq(g._pending_shots.size(), 0, "no shot")
	assert_false(ws.is_reloading(), "nothing to reload with")
	assert_gt(lp.view.dry, 0.0, "the gun twitches")
	assert_eq(Sfx.stats.played, played + 1, "click")
	assert_true(g.hud.weapon_label.text.ends_with("0 / 0"), g.hud.weapon_label.text)
	lp.firing = true
	g._update_weapon()
	assert_eq(Sfx.stats.played, played + 1, "holding the trigger does not click again")
	lp.view.update(Config.DRY_FIRE_TIME + 0.05, 0.0, false, false, ws)
	assert_eq(lp.view.dry, 0.0, "and the twitch is over")


func test_an_empty_magazine_with_rounds_in_reserve_reloads_instead_of_clicking() -> void:
	var g := await new_game("corridor", "", true)
	var lp := g.local_player
	lp.weapons.draw_left = 0.0
	lp.weapons.ammo[lp.weapons.current] = 0
	lp.firing = true
	lp.fire_buffer = Config.FIRE_BUFFER
	g._update_weapon()
	assert_true(lp.weapons.is_reloading())
	assert_eq(lp.view.dry, 0.0)
