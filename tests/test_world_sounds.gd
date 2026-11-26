extends TestCase
## S084 world sounds: doors, barricades, lootboxes and pickups, glass, vehicles, the interface,
## and the hums of the world. Every one is made in code (WorldSounds); the host says what happened
## (Game.play_sound) and every peer plays it; loops sit in the world as capped SoundSpots.


func after_each() -> void:
	Sfx.reset()


## The sound was asked for lately (Sfx.last).
func assert_has(sounds: Array[String], sound: String, msg := "") -> void:
	assert_true(sounds.has(sound), "%s played %s (heard: %s)" % [sound, msg, sounds])


func _peak(buf: PackedFloat32Array) -> float:
	var p := 0.0
	for v in buf:
		p = maxf(p, absf(v))
	return p


## Mean of |x| over a window (an RMS-like level), from `from` seconds for `secs`.
func _level(buf: PackedFloat32Array, from: float, secs: float) -> float:
	var a := clampi(int(from * Sfx.RATE), 0, buf.size())
	var b := clampi(int((from + secs) * Sfx.RATE), a, buf.size())
	var s := 0.0
	for i in range(a, b):
		s += absf(buf[i])
	return s / maxi(b - a, 1)


## How bright a sound is: zero crossings per second (a rough spectral centroid).
func _brightness(buf: PackedFloat32Array) -> float:
	var n := 0
	var loud := 0
	for i in range(1, buf.size()):
		if absf(buf[i]) > 0.01:
			loud += 1
			if (buf[i - 1] < 0.0) != (buf[i] < 0.0):
				n += 1
	return float(n) / maxf(float(loud) / Sfx.RATE, 0.001) / 2.0


## Onsets: times (s) where the level jumps after a quieter stretch.
func _onsets(buf: PackedFloat32Array, win := 0.01, jump := 4.0) -> Array:
	var out := []
	var prev := 0.0
	var w := int(win * Sfx.RATE)
	var i := 0
	while i + w <= buf.size():
		var l := _level(buf, float(i) / Sfx.RATE, win)
		if l > 0.02 and l > prev * jump:
			out.append(float(i) / Sfx.RATE)
		prev = l
		i += w
	return out


func _stand_at(g: Game, pos: Vector3) -> void:
	g.local_player.teleport(pos)
	g.players[1].pos = pos
	await frames(2)


func _of(g: Game, type: Variant) -> Array:
	return g.interactables.values().filter(func(it): return is_instance_of(it, type))


# --- The sounds themselves ----------------------------------------------------------------

func test_every_world_sound_is_registered_and_well_made() -> void:
	for sound: String in WorldSounds.ONE_SHOTS:
		var buf := WorldSounds.samples(sound)
		assert_gt(buf.size(), 0, sound + " has samples")
		var peak := _peak(buf)
		assert_true(peak > 0.15 and peak <= 1.0, "%s is loud enough and never clips (%.2f)" % [sound, peak])
		var secs := float(buf.size()) / Sfx.RATE
		assert_lt(secs, WorldSounds.ONE_SHOTS[sound] + 0.001, "%s is no longer than it should be (%.2f s)" % [sound, secs])
		assert_lt(absf(buf[0]), 0.05, sound + " starts without a click")
		assert_lt(_level(buf, secs - 0.02, 0.02), 0.02, sound + " has died away at its end")
		for v in buf:
			if not is_finite(v):
				assert_true(false, sound + " has a NaN")
				break
		assert_true(Sfx.stream(sound) != null, sound + " plays through Sfx")
	for sound: String in WorldSounds.LOOPS:
		var s := Sfx.stream(sound)
		assert_true(s != null, sound + " plays through Sfx")
		assert_eq(s.loop_mode, AudioStreamWAV.LOOP_FORWARD, sound + " loops")
		var buf := WorldSounds.samples(sound)
		assert_near(float(buf.size()) / Sfx.RATE, WorldSounds.LOOPS[sound], 0.01, sound + " is as long as its loop")
		var steepest := 0.0
		for i in range(1, buf.size()):
			steepest = maxf(steepest, absf(buf[i] - buf[i - 1]))
		assert_lt(absf(buf[buf.size() - 1] - buf[0]), steepest + 0.001, sound + " joins its own start without a click")
		assert_true(_peak(buf) > 0.1 and _peak(buf) <= 1.0, sound + " level")


func test_sounds_of_one_family_differ_and_sit_where_they_should() -> void:
	var b := {}
	for sound in ["door_slam", "door_creak", "glass_shatter", "glass_crack", "key_jingle", "generator",
			"tube_buzz", "wave_horn", "ui_hover", "ui_error", "medkit_zip", "hammer_knock", "plank_snap"]:
		b[sound] = _brightness(WorldSounds.samples(sound))
	assert_lt(b.door_slam, b.glass_shatter, "wood thuds lower than breaking glass")
	assert_lt(b.generator, b.key_jingle, "a generator rumbles under keys")
	assert_lt(b.wave_horn, b.ui_hover, "the horn is low, a hover tick is bright")
	assert_lt(b.ui_error, b.ui_hover, "an error buzzes lower than a tick")
	assert_gt(b.glass_crack, 2000.0, "a crack in glass is bright (%.0f)" % b.glass_crack)
	assert_lt(b.generator, 700.0, "a generator is low (%.0f)" % b.generator)
	# The same sound twice is the same (seeded), two creaks are not the same creak.
	assert_eq(WorldSounds.samples("door_creak"), WorldSounds.samples("door_creak"))
	assert_true(WorldSounds.samples("door_creak") != WorldSounds.samples("lid_creak"))


func test_rhythms_ticks_clicks_and_teeth() -> void:
	# The hazard relay: a tick and a tock each flash, two to a cycle.
	var hazard := WorldSounds.samples("hazard_tick")
	var on := _onsets(hazard)
	assert_eq(on.size(), roundi(WorldSounds.LOOPS.hazard_tick / WorldSounds.HAZARD_PERIOD) * 2, "tick, tock: %s" % [on])
	# A zip is a run of teeth; a door handle is two clicks (down and up); keys jingle more than once.
	assert_gt(_onsets(WorldSounds.samples("medkit_zip"), 0.002, 2.0).size(), 20, "the zip's teeth")
	assert_eq(_onsets(WorldSounds.samples("door_handle"), 0.005).size(), 2, "the handle goes down and comes back")
	assert_gt(_onsets(WorldSounds.samples("key_jingle"), 0.005, 2.0).size(), 3, "several keys")
	assert_gt(_onsets(WorldSounds.samples("locked_rattle"), 0.01, 2.0).size(), 3, "the locked handle is shaken")
	assert_gt(_onsets(WorldSounds.samples("hammer_knock"), 0.01).size(), 0)
	# The tube's buzz is mains hum: 100 Hz under it.
	var tube := WorldSounds.samples("tube_buzz")
	var best := 0
	var best_c := -INF
	for lag in range(Sfx.RATE / 400, Sfx.RATE / 70): # 70..400 Hz
		var c := 0.0
		for i in range(0, 8000):
			c += tube[i] * tube[i + lag]
		if c > best_c:
			best_c = c
			best = lag
	assert_near(float(Sfx.RATE) / best, 100.0, 6.0, "the hum is 100 Hz (%d samples)" % best)
	# The car alarm sweeps up and down: its brightness moves.
	var alarm := WorldSounds.samples("car_alarm")
	var lo := INF
	var hi := 0.0
	for k in 12:
		var part := alarm.slice(int(k * 0.1 * Sfx.RATE), int((k * 0.1 + 0.1) * Sfx.RATE))
		var br := _brightness(part)
		lo = minf(lo, br)
		hi = maxf(hi, br)
	assert_gt(hi, lo * 1.5, "the alarm whoops (%.0f..%.0f)" % [lo, hi])
	# A door's creak swells and fades rather than starting at full.
	var creak := WorldSounds.samples("door_creak")
	assert_lt(_level(creak, 0.0, 0.05), _level(creak, 0.3, 0.1), "the creak builds")


# --- What makes them -------------------------------------------------------------------------

func test_doors_sound_when_opened_closed_bashed_and_broken() -> void:
	var g := await new_game()
	await _stand_at(g, g.door.global_position + Vector3(-2, 0.1, 0))
	Sfx.last.clear()
	g.host_interact(1, g.door.iid)
	assert_has(Sfx.last, "door_open")
	g.host_interact(1, g.door.iid)
	assert_has(Sfx.last, "door_close")
	Sfx.last.clear()
	var z := g.spawn_zombie(Zombie.Type.WALKER, g.door.global_position + Vector3(1.0, 0.1, 0))
	g.zombie_bashes_door(z, g.door)
	assert_has(Sfx.last, "door_splinter", "a blow on the door")
	g.door.hp = 1
	g.zombie_bashes_door(z, g.door)
	assert_has(Sfx.last, "door_break", "and the crash when it goes")


func test_lootboxes_crates_and_pickups() -> void:
	var g := await new_game("corridor", "", true)
	await _stand_at(g, g.lootbox.global_position + Vector3(-1.5, 0.1, 0))
	Sfx.last.clear()
	g.host_interact(1, g.lootbox.iid)
	assert_has(Sfx.last, "lootbox_open", "latch, lid and a hand inside")
	assert_has(Sfx.last, "medkit_zip", "the medkit goes in the pack")

	var crate: AmmoCrate = _of(g, AmmoCrate)[0]
	await _stand_at(g, crate.global_position + Vector3(0, 0.1, 1.0))
	crate.locked = true
	Sfx.last.clear()
	g.host_interact(1, crate.iid)
	assert_has(Sfx.last, "locked_rattle", "a locked crate rattles")
	crate.locked = false
	g.players[1].reserve[Weapons.ammo_of(g.players[1].weapon)] = 0
	Sfx.last.clear()
	g.host_interact(1, crate.iid)
	assert_has(Sfx.last, "crate_open")
	assert_has(Sfx.last, "ammo_clink", "rounds taken")

	Sfx.last.clear()
	g.give_key(1, &"gate")
	assert_has(Sfx.last, "key_jingle")


func test_glass_cracks_under_a_bullet() -> void:
	var g := await new_game()
	Sfx.last.clear()
	g.fx.play(Fx.Kind.IMPACT, Vector3(0, 1, 5), Vector3.BACK, Surface.Kind.GLASS)
	assert_has(Sfx.last, "glass_crack")
	Sfx.last.clear()
	g.fx.play(Fx.Kind.IMPACT, Vector3(0, 1, 5), Vector3.BACK, Surface.Kind.CONCRETE)
	assert_false(Sfx.last.has("glass_crack"))


func test_host_sounds_reach_every_peer_as_what_happened() -> void:
	var g := await new_game()
	Sfx.last.clear()
	g.world_sound("door_slam", Vector3(1, 0, 2), 0.05, 0.0) # what a client runs when the host says so
	assert_has(Sfx.last, "door_slam")
	Sfx.last.clear()
	g.play_sound("ui_error_unknown_name", Vector3.ZERO)
	assert_has(Sfx.last, "ui_error_unknown_name", "an unknown name is asked for and simply not heard")


func test_the_interface_ticks_clicks_and_complains() -> void:
	var b := Button.new()
	add_child(b)
	WorldSounds.wire_button(b)
	Sfx.last.clear()
	b.mouse_entered.emit()
	assert_has(Sfx.last, "ui_hover")
	b.pressed.emit()
	assert_has(Sfx.last, "ui_click")
	var back := Button.new()
	add_child(back)
	WorldSounds.wire_button(back, true)
	back.pressed.emit()
	assert_has(Sfx.last, "ui_back")
	b.free()
	back.free()
	var g := await new_game()
	Sfx.last.clear()
	g.ui_sound_to(1, "ui_error")
	assert_has(Sfx.last, "ui_error", "a refusal (a full pack) beeps at the one refused")
	await _stand_at(g, g.lootbox.global_position + Vector3(-1.5, 0.1, 0))
	var inv: Inventory = g.players[1].inventory
	while g.inventory_room(1, &"medkit") > 0:
		inv.add(&"medkit")
	Sfx.last.clear()
	g.host_interact(1, g.lootbox.iid)
	assert_has(Sfx.last, "ui_error", "the pack is full")


func test_a_new_objective_chimes_and_a_wave_blows_the_horn() -> void:
	var g := await new_game()
	Sfx.last.clear()
	g.hud.set_objective({ "text": "Reach the door" })
	g.hud.set_objective({ "text": "Reach the door" })
	assert_eq(Sfx.last.count("objective_chime"), 1, "once, when it changes")
	g.hud.set_objective({ "text": "Hold the room" })
	assert_eq(Sfx.last.count("objective_chime"), 2)
	Sfx.last.clear()
	g.mission_state({ "kind": "survive", "wave": 1 })
	assert_has(Sfx.last, "wave_horn")


# --- Sounds that stay in one place -------------------------------------------------------------

func test_spots_play_the_nearest_few_and_stop_far_ones() -> void:
	var root := Node3D.new()
	add_child(root)
	var spots := []
	for i in 12:
		var s := SoundSpot.make("tube_buzz", Vector3(i * 3.0, 2, 0))
		root.add_child(s)
		spots.append(s)
	await frames(1)
	Sfx.step_spots(Vector3(-1, 2, 0))
	var playing := spots.filter(func(s: SoundSpot) -> bool: return s.playing())
	assert_eq(playing.size(), Config.SOUND_SPOTS_AUDIBLE, "only the nearest few sound")
	for i in Config.SOUND_SPOTS_AUDIBLE:
		assert_true((spots[i] as SoundSpot).playing(), "the nearest ones (%d)" % i)
	Sfx.step_spots(Vector3(500, 2, 0))
	assert_eq(spots.filter(func(s: SoundSpot) -> bool: return s.playing()).size(), 0, "out of earshot: silent")
	root.free()
	assert_eq(Sfx.spot_count(), 0, "a freed spot leaves the list")


func test_spots_can_come_and_go_on_a_cycle() -> void:
	var s := SoundSpot.make("car_alarm", Vector3.ZERO, 0.0, 10.0, 0.5)
	add_child(s)
	await frames(1)
	var on := 0
	for i in 200:
		s.clock = i * 0.1
		Sfx.step_spots(Vector3(0, 0, 3))
		if s.playing():
			on += 1
	assert_true(on > 70 and on < 130, "an alarm that sounds half the time and rests (%d of 200)" % on)
	s.free()


func test_the_maps_put_hums_where_things_hum() -> void:
	var g := await new_game()
	var names := {}
	for s: SoundSpot in g.get_tree().get_nodes_in_group(&"sound_spots"):
		names[s.sound] = names.get(s.sound, 0) + 1
	assert_gt(names.get("tube_buzz", 0), 3, "the corridor's lamps buzz")
	var root := Node3D.new()
	add_child(root)
	var kit := Scenery.new(root, StaticBody3D.new(), RandomNumberGenerator.new())
	kit.place(Vector3.ZERO).street_wrecks()
	kit.place(Vector3(80, 0, 0)).motor_pool()
	kit.place(Vector3(-80, 0, 0)).triage_camp()
	kit.place(Vector3(0, 0, 80)).checkpoint()
	kit.finish()
	names.clear()
	for s: Node in root.find_children("*", "SoundSpot", true, false):
		names[(s as SoundSpot).sound] = true
	for sound in ["car_alarm", "horn_stuck", "hazard_tick", "engine_tick", "generator"]:
		assert_true(names.has(sound), sound + " placed by the set pieces")
	assert_lt(root.find_children("*", "SoundSpot", true, false).size(), Config.SOUND_SPOTS_MAX)
	kit.body.free()
	root.free()
