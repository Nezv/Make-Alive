extends TestCase
## Horde director 2: pacing states driven by stress, spawns only where nobody can see or is close,
## hordes that stream in from one closet and walk its route, wanderers from the map's data, a budget
## for the dangerous types, and stragglers that get moved up ahead.

const S := HordeDirector.State

## Closets on the corridor: the far end of leg B, the middle of leg B, the corner, the closed end of leg A.
const CLOSETS := [
	{ "id": "far", "at": Vector3(40, 0.1, 0), "radius": 1.5 },
	{ "id": "mid", "at": Vector3(22, 0.1, 0), "radius": 1.5 },
	{ "id": "corner", "at": Vector3(0, 0.1, 0), "radius": 1.5 },
	{ "id": "north", "at": Vector3(0, 0.1, 29), "radius": 1.0 },
]
const ROUTE := [Vector3(40, 0.1, 0), Vector3(22, 0.1, 0), Vector3(0, 0.1, 0)]


## A host with the physics loop off (the tests step the director themselves), the corridor's own
## map data with these closets, and the director on.
func _game(closets: Array = CLOSETS, extra := {}) -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	var dict := MapAreas.CORRIDOR.duplicate()
	dict["zombie_closets"] = closets
	dict["horde_routes"] = []
	dict.merge(extra, true)
	g.map.data = MapData.new(dict)
	g.director.enabled = true
	g.players[1].pos = Vector3(0, 0.1, 26)
	return g


## Step the director for `secs` in half-second ticks, holding stress at `stress` (-1: let it be).
func _run(d: HordeDirector, secs: float, stress := -1.0) -> void:
	var left := secs
	while left > 0.0:
		var dt := minf(0.5, left)
		if stress >= 0.0:
			d.stress = stress
		d.step(dt)
		left -= dt


func _remove(g: Game, z: Zombie) -> void:
	g.zombies.erase(z.zid)
	z.queue_free()


func _clear_zombies(g: Game) -> void:
	for z: Zombie in g.zombies.values():
		_remove(g, z)


## Is closet `c` out of sight of everyone in `living` and at least Config.SPAWN_MIN_DIST from them?
func _hidden(g: Game, c: Dictionary, living: Array) -> bool:
	var at: Vector3 = c.at
	for q: Vector3 in living:
		if q.distance_to(at) < Config.SPAWN_MIN_DIST or (g.map.sees(q, at) and g.map.is_direct(q, at)):
			return false
	return true


func _random_spot(rng: RandomNumberGenerator) -> Vector3:
	if rng.randf() < 0.5: # leg A
		return Vector3(rng.randf_range(-2.5, 2.5), 0.1, rng.randf_range(0.0, 29.0))
	return Vector3(rng.randf_range(3.5, 43.0), 0.1, rng.randf_range(-2.5, 2.5)) # leg B


# --- Pacing ---------------------------------------------------------------------------

func test_pacing_goes_build_peak_relax_calm_and_round_again() -> void:
	var g := await _game()
	var d := g.director
	var calls := spy(g)
	assert_eq(d.state, S.BUILD, "the first thing is the build-up to the first horde")
	_run(d, Config.HORDE_FIRST, 0.0)
	assert_eq(d.state, S.PEAK)
	assert_eq(count(calls, &"on_horde_incoming"), 1)
	_run(d, Config.PEAK_MIN, 0.0)
	assert_eq(d.state, S.PEAK, "the horde is still about")
	_clear_zombies(g)
	_run(d, 1.0, 0.0)
	assert_eq(d.state, S.RELAX, "the horde is dead: a breather")
	_run(d, Config.RELAX_MIN + 1.0, 0.9)
	assert_eq(d.state, S.RELAX, "it waits for the players to calm down")
	_run(d, 1.0, 0.0)
	assert_eq(d.state, S.CALM)
	_run(d, Config.CALM_TIME + 1.0, 0.0)
	assert_eq(d.state, S.BUILD, "and round again")
	var changes := calls.filter(func(c: Array) -> bool: return c[0] == &"on_pacing_changed").map(func(c: Array) -> int: return c[1][0])
	assert_eq(changes, [S.PEAK, S.RELAX, S.CALM, S.BUILD])


func test_a_peak_also_ends_when_it_has_gone_on_too_long() -> void:
	var g := await _game()
	var d := g.director
	_run(d, Config.HORDE_FIRST, 0.0)
	assert_eq(d.state, S.PEAK)
	g.players[1].pos = Vector3(0, 0.1, 40) # out of reach: nothing gets killed
	_run(d, Config.PEAK_MAX + 1.0, 0.0)
	assert_eq(d.state, S.RELAX)


func test_calm_waits_for_low_stress() -> void:
	var g := await _game()
	var d := g.director
	d.state = S.CALM
	d._state_t = 0.0
	_run(d, Config.CALM_TIME + 5.0, 0.9)
	assert_eq(d.state, S.CALM, "players in a fight are not sent more")
	_run(d, 1.0, 0.0)
	assert_eq(d.state, S.BUILD)


func test_the_build_up_is_slower_while_the_players_are_stressed() -> void:
	var g := await _game()
	var d := g.director
	d._horde_timer = 20.0
	d.stress = 0.0
	d.step(2.0)
	var calm := d._horde_timer
	d._horde_timer = 20.0
	d.stress = 1.0
	d.step(2.0)
	var stressed := d._horde_timer
	assert_lt(calm, stressed, "a comfortable group gets its horde sooner")
	assert_lt(calm, 20.0 - 2.0, "faster than the clock")
	assert_gt(stressed, 20.0 - 2.0, "slower than the clock")


func test_between_hordes_stragglers_only_come_during_the_build_up() -> void:
	var g := await _game()
	var d := g.director
	d.state = S.BUILD
	d._horde_timer = 1000.0
	d._trickle = 0.0
	d.step(0.1)
	assert_eq(g.zombies.size(), 1, "one straggler while the horde builds")
	for s in [S.CALM, S.RELAX, S.PEAK]:
		d.state = s
		d._state_t = -1000.0 # stays in it
		d._trickle = 0.0
		d.stress = 0.0
		d.step(0.1)
	assert_eq(g.zombies.size(), 1, "none in the calm, the breather or the peak (the peak has its horde)")


func test_a_checkpoints_calm_still_stops_everything_and_drops_the_stream() -> void:
	var g := await _game()
	var d := g.director
	d.stream_horde(10)
	d.calm(5.0)
	d.step(1.0)
	assert_eq(g.zombies.size(), 0, "the ones still to come are not coming")


# --- Stress ---------------------------------------------------------------------------

func test_damage_taken_adds_stress() -> void:
	var g := await _game()
	assert_eq(g.director.stress, 0.0)
	g.damage_player(1, 25)
	assert_near(g.director.stress, 25 * Config.STRESS_PER_HP, 0.001)
	g.damage_player(1, 1000)
	assert_eq(g.director.stress, 1.0, "never more than full")


func test_zombies_close_to_a_living_player_add_stress_and_it_fades() -> void:
	var g := await _game()
	var d := g.director
	d.state = S.CALM
	d._state_t = -1000.0
	for i in 3:
		g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 22 + i * 0.5))
	g.spawn_zombie(Zombie.Type.WALKER, Vector3(40, 0.1, 0)) # far away: no stress
	d.step(1.0)
	assert_near(d.stress, 3 * Config.STRESS_PER_ZOMBIE - Config.STRESS_DECAY, 0.001)
	_clear_zombies(g)
	d.stress = 1.0
	d.step(1.0)
	assert_near(d.stress, 1.0 - Config.STRESS_DECAY, 0.001)
	d.step(1000.0)
	assert_eq(d.stress, 0.0)


func test_the_dead_do_not_feel_zombies_near() -> void:
	var g := await _game()
	var d := g.director
	d.state = S.CALM
	d._state_t = -1000.0
	g._add_player(7, "Guest")
	g.players[7].pos = Vector3(0, 0.1, 5)
	for i in 3:
		g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 22 + i * 0.5))
	g.rules.set_out(1, true)
	d.step(1.0)
	assert_eq(d.stress, 0.0, "the zombies are next to someone who is out of the fight")


func test_running_low_on_ammo_adds_stress_only_where_ammo_is_limited() -> void:
	var g := await _game()
	var d := g.director
	d.state = S.CALM
	d._state_t = -1000.0
	var type := Weapons.ammo_of(g.players[1].weapon)
	g.players[1].reserve[type] = Config.STRESS_AMMO_LOW - 1
	d.stress = 0.5
	d.step(1.0)
	assert_near(d.stress, 0.5 - Config.STRESS_DECAY, 0.001, "infinite ammo: nothing to worry about")
	g.map.infinite_ammo = false
	d.stress = 0.5
	d.step(1.0)
	assert_near(d.stress, 0.5 + Config.STRESS_AMMO_RATE - Config.STRESS_DECAY, 0.001)
	g.players[1].reserve[type] = Config.STRESS_AMMO_LOW + 30
	d.stress = 0.5
	d.step(1.0)
	assert_near(d.stress, 0.5 - Config.STRESS_DECAY, 0.001, "plenty left")


# --- Where they come from -------------------------------------------------------------

func test_spawns_only_come_from_closets_nobody_can_see_or_is_close_to() -> void:
	var g := await _game()
	var d := g.director
	g._add_player(7, "Guest")
	g._add_player(8, "Guest 2")
	d.rng.seed = 12345
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var with_cover := 0
	var bad := 0
	var far_off := 0
	for i in 1000:
		var living: Array = []
		for id in [1, 7, 8]:
			var present: bool = id == 1 or rng.randf() < 0.6
			if id != 1:
				g.rules.set_out(id, not present) # the ones not drawn this time are out of the fight
			if present:
				var at := _random_spot(rng)
				g.players[id].pos = at
				living.append(at)
		var pick := d.pick_closet()
		if CLOSETS.any(func(c: Dictionary) -> bool: return _hidden(g, c, living)):
			with_cover += 1
			if not _hidden(g, pick, living):
				bad += 1
		else: # nowhere hides: the one farthest from the nearest player
			var best := 0.0
			for c: Dictionary in CLOSETS:
				var nearest := INF
				for q: Vector3 in living:
					nearest = minf(nearest, q.distance_to(c.at))
				best = maxf(best, nearest)
			var got := INF
			for q: Vector3 in living:
				got = minf(got, q.distance_to(pick.at))
			if absf(got - best) > 0.001:
				far_off += 1
	assert_gt(with_cover, 300, "most draws had somewhere to hide (%d)" % with_cover)
	assert_eq(bad, 0, "never a closet somebody could see or was standing near")
	assert_eq(far_off, 0, "with nowhere to hide, the farthest one")


func test_a_closet_round_the_corner_is_still_too_close() -> void:
	var near_bend := [
		{ "id": "bend", "at": Vector3(5, 0.1, 0), "radius": 1.0 },
		{ "id": "far", "at": Vector3(40, 0.1, 0), "radius": 1.0 },
	]
	var g := await _game(near_bend)
	g.players[1].pos = Vector3(0, 0.1, 12)
	assert_false(g.map.sees(g.players[1].pos, Vector3(5, 0.1, 0)), "round the corner: out of sight...")
	assert_lt(g.players[1].pos.distance_to(Vector3(5, 0.1, 0)), Config.SPAWN_MIN_DIST, "...but close")
	for i in 30:
		assert_eq(g.director.pick_closet().id, "far")


func test_closets_that_only_the_dead_can_see_are_fair_game() -> void:
	var g := await _game()
	var d := g.director
	g._add_player(7, "Guest")
	g.players[1].pos = Vector3(0, 0.1, 28)
	g.players[7].pos = Vector3(30, 0.1, 0) # sees both of leg B's closets
	g.rules.set_out(7, true)
	var seen := {}
	for i in 200:
		seen[d.pick_closet().id] = true
	assert_true(seen.has("far") or seen.has("mid"), "leg B is only watched by someone who is out")


func test_a_map_without_closets_falls_back_to_the_maps_own_spawn_point() -> void:
	var g := await _game([])
	_frozen(g.director)
	assert_eq(g.director.pick_closet(), {})
	assert_eq(g.director.stream_horde(3), 3, "it still sends a horde, from wherever the map says")
	g.director.step(Config.HORDE_STREAM_GAP * 4)
	assert_eq(g.zombies.size(), 3)


func test_closets_listed_for_other_waves_are_not_used() -> void:
	var listed := [
		{ "id": "far", "at": Vector3(40, 0.1, 0), "radius": 1.0, "waves": [3] },
		{ "id": "mid", "at": Vector3(22, 0.1, 0), "radius": 1.0, "waves": [] },
	]
	var g := await _game(listed)
	for i in 20:
		assert_eq(g.director.pick_closet(1).id, "mid")
	var seen := {}
	for i in 100:
		seen[g.director.pick_closet(3).id] = true
	assert_true(seen.has("far") and seen.has("mid"), "wave 3 may use both")


# --- Streams and routes ---------------------------------------------------------------

func test_a_horde_streams_in_from_one_closet_instead_of_arriving_as_a_blob() -> void:
	var g := await _game()
	var d := g.director
	_frozen(d)
	var calls := spy(g)
	assert_eq(d.stream_horde(10), 10)
	assert_eq(count(calls, &"on_horde_incoming"), 1)
	assert_eq(calls.filter(func(c: Array) -> bool: return c[0] == &"on_horde_incoming")[0][1], [1, 10])
	assert_eq(g.zombies.size(), 0, "nobody yet: they come one after another")
	d.step(0.01)
	assert_eq(g.zombies.size(), 1)
	d.step(Config.HORDE_STREAM_GAP)
	assert_eq(g.zombies.size(), 2)
	d.step(Config.HORDE_STREAM_GAP * 30)
	assert_eq(g.zombies.size(), 10, "all of them, and no more")
	assert_true(["far", "mid"].has(d.stream_from), "from a closet out of sight, not the corner or the dead end behind them")
	var closet: Dictionary = CLOSETS.filter(func(c: Dictionary) -> bool: return c.id == d.stream_from)[0]
	for z: Zombie in g.zombies.values():
		assert_lt(Vector2(z.global_position.x - closet.at.x, z.global_position.z - closet.at.z).length(), closet.radius + 0.1)


func test_a_streamed_horde_walks_the_closets_route_before_it_goes_for_anyone() -> void:
	var g := await _game(CLOSETS, { "horde_routes": [{ "closet": "far", "points": ROUTE }] })
	var d := g.director
	_frozen(d)
	d.stream_horde(1)
	d.step(0.5)
	# Only "far" has a route: the stream may come from "mid" (none) as well.
	var z: Zombie = g.zombies.values()[0]
	if d.stream_from == "far":
		assert_eq(z.route.size(), ROUTE.size(), "it was told the way")
	else:
		assert_eq(z.route.size(), 0)


func test_a_zombie_on_a_route_walks_to_each_point_then_chases() -> void:
	var g := await _game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(40, 0.1, 0))
	z.route = [Vector3(40.5, 0.1, 0), Vector3(22, 0.1, 0)]
	g.zombie_list.assign(g.zombies.values())
	g.players[1].pos = Vector3(0, 0.1, 28) # far: farther than it would notice
	z.host_step(0.05, g)
	assert_eq(z.route, [Vector3(22, 0.1, 0)], "it was already at the first point")
	g.players[1].pos = z.global_position + Vector3(-5, 0, 0)
	z.host_step(0.05, g)
	assert_true(z.route.is_empty(), "a player this close beats the route: it forgets it and chases them")


# --- Wanderers ------------------------------------------------------------------------

func test_wanderers_from_the_map_data_stand_about_until_something_wakes_them() -> void:
	var extra := { "zombie_wanderers": [{ "at": Vector3(22, 0.1, 0), "count": 3, "radius": 2.0 }] }
	var g := await _game(CLOSETS, extra)
	var d := g.director
	assert_eq(g.map.data.wanderers.size(), 1)
	assert_eq(g.zombies.size(), 0, "they are put out when the match gets going, not before")
	d.step(0.1)
	assert_eq(g.zombies.size(), 3)
	d.step(0.1)
	assert_eq(g.zombies.size(), 3, "once")
	g.zombie_list.assign(g.zombies.values())
	for z: Zombie in g.zombies.values():
		assert_true(z.idle)
		assert_lt(Vector2(z.global_position.x - 22.0, z.global_position.z).length(), 2.1)
	var w: Zombie = g.zombies.values()[0]
	var start := w.global_position
	for i in 10:
		w.host_step(0.1, g)
	assert_lt(Vector2(w.global_position.x - start.x, w.global_position.z - start.z).length(), 0.05, "it stands there")
	assert_true(w.idle)
	g.players[1].pos = start + Vector3(Config.ZOMBIE_NOTICE_RANGE - 3.0, 0, 0)
	w.host_step(0.1, g)
	assert_false(w.idle, "a player came close")


func test_a_noise_or_a_hit_wakes_a_wanderer() -> void:
	var extra := { "zombie_wanderers": [{ "at": Vector3(22, 0.1, 0), "count": 2, "radius": 1.0 }] }
	var g := await _game(CLOSETS, extra)
	g.director.step(0.1)
	var a: Zombie = g.zombies.values()[0]
	var b: Zombie = g.zombies.values()[1]
	assert_true(a.idle and b.idle)
	g.make_noise(a.global_position, 5.0, 1)
	assert_false(a.idle, "it heard that")
	b.take_hit(Humanoid.Part.ARM_L, 1)
	assert_false(b.idle, "and that woke this one")


func test_wanderers_must_stand_on_walkable_ground() -> void:
	var extra := { "zombie_wanderers": [{ "at": Vector3(22, 0.1, 20), "count": 1, "radius": 1.0 }] }
	var g := await _game(CLOSETS, extra)
	var problems := g.map.data.check(g.map)
	assert_true(problems.any(func(p: String) -> bool: return p.contains("wanderer")), str(problems))


# --- Specials -------------------------------------------------------------------------

func test_dangerous_types_are_kept_to_a_budget() -> void:
	var g := await _game()
	var d := g.director
	d.rng.seed = 3
	var cap: int = Config.SPECIAL_BUDGET[Zombie.Type.LEAPER]
	assert_gt(cap, 0)
	assert_eq(d.type_room(Zombie.Type.LEAPER), cap)
	assert_gt(d.type_room(Zombie.Type.WALKER), cap, "no budget on the usual ones")
	var leapers: Array[Zombie] = []
	for i in cap:
		leapers.append(g.spawn_zombie(Zombie.Type.LEAPER, Vector3(40, 0.1, 0)))
	assert_eq(d.type_room(Zombie.Type.LEAPER), 0)
	var too_many := 0
	for i in 1000:
		if d.pick_type() == Zombie.Type.LEAPER:
			too_many += 1
	assert_eq(too_many, 0, "the budget is spent")
	_remove(g, leapers[0])
	assert_eq(d.type_room(Zombie.Type.LEAPER), 1)
	var got := 0
	for i in 1000:
		if d.pick_type() == Zombie.Type.LEAPER:
			got += 1
	assert_gt(got, 0, "one has died: room for another")


# --- Stragglers -----------------------------------------------------------------------

func _frozen(d: HordeDirector) -> void:
	d._trickle = 100000.0
	d._horde_timer = 100000.0 # nothing else comes while the test watches one zombie


func test_a_zombie_that_has_lost_the_players_is_moved_up_ahead_of_them() -> void:
	var g := await _game()
	var d := g.director
	_frozen(d)
	g.players[1].pos = Vector3(0, 0.1, 28)
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(40, 0.1, 0))
	assert_gt(z.global_position.distance_to(g.players[1].pos), Config.STRAGGLER_DIST)
	_run(d, Config.STRAGGLER_TIME - 2.0, 0.0)
	assert_eq(d.recycled, 0, "not yet")
	_run(d, 4.0, 0.0)
	assert_eq(d.recycled, 1)
	var at := z.global_position
	var here: Vector3 = g.players[1].pos
	assert_false(g.map.sees(here, at) and g.map.is_direct(here, at), "out of their sight")
	assert_gt(here.distance_to(at), Config.SPAWN_MIN_DIST - 0.1, "and not on top of them")
	assert_lt(Vector2(at.x - 22.0, at.z).length(), 1.7, "in the closet nearest the objective (the corner): the middle of leg B")


func test_a_zombie_near_a_player_or_after_a_noise_is_not_a_straggler() -> void:
	var g := await _game()
	var d := g.director
	_frozen(d)
	g.players[1].pos = Vector3(0, 0.1, 28)
	var near := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 12))
	var listening := g.spawn_zombie(Zombie.Type.WALKER, Vector3(40, 0.1, 0))
	listening.hear(Vector3(30, 0.1, 0))
	_run(d, Config.STRAGGLER_TIME + 5.0, 0.0)
	assert_eq(d.recycled, 0)
	assert_near(near.global_position.z, 12.0, 0.01)
	assert_near(listening.global_position.x, 40.0, 0.01)


func test_coming_back_into_range_resets_the_straggler_clock() -> void:
	var g := await _game()
	var d := g.director
	_frozen(d)
	g.players[1].pos = Vector3(0, 0.1, 28)
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(40, 0.1, 0))
	_run(d, Config.STRAGGLER_TIME - 2.0, 0.0)
	z.global_position = Vector3(0, 0.1, 15)
	_run(d, 3.0, 0.0)
	z.global_position = Vector3(40, 0.1, 0)
	_run(d, Config.STRAGGLER_TIME - 2.0, 0.0)
	assert_eq(d.recycled, 0, "the clock started again")


# --- The overlay ----------------------------------------------------------------------

func test_the_debug_overlay_says_what_the_director_is_thinking() -> void:
	var g := await _game()
	var d := g.director
	d.stress = 0.5
	d.heat = 40.0
	var text := d.debug_text()
	assert_true(text.contains("BUILD"), text)
	assert_true(text.contains("0.50"), text)
	assert_true(text.contains("40"), text)
