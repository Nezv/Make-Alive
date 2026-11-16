extends TestCase
## The sound engine: synthesis primitives, cached streams, buses, and the capped voice pool.

const RATE := Sfx.RATE


func after_each() -> void:
	Sfx.reset()


func _energy(buf: PackedFloat32Array) -> float:
	var e := 0.0
	for v in buf:
		e += v * v
	return e / maxi(buf.size(), 1)


func _crossings(buf: PackedFloat32Array) -> int:
	var n := 0
	for i in range(1, buf.size()):
		if (buf[i - 1] < 0.0) != (buf[i] < 0.0):
			n += 1
	return n


func _peak(buf: PackedFloat32Array) -> float:
	var p := 0.0
	for v in buf:
		p = maxf(p, absf(v))
	return p


# --- Buses ------------------------------------------------------------------------

func test_buses_exist_and_feed_master() -> void:
	Sfx.ensure_buses()
	Sfx.ensure_buses() # twice must not duplicate
	for bus: String in ["Guns", "Zombies", "World", "UI", "Music"]:
		var i := AudioServer.get_bus_index(bus)
		assert_gt(i, 0, bus + " exists")
		assert_eq(AudioServer.get_bus_send(i), &"Master", bus + " sends to Master")
	assert_eq(AudioServer.bus_count, Sfx.BUSES.size())


# --- Synthesis --------------------------------------------------------------------

func test_oscillators_have_the_right_length_and_pitch() -> void:
	for shape: int in [Sfx.Wave.SINE, Sfx.Wave.SAW, Sfx.Wave.SQUARE]:
		var buf := Sfx.tone(0.5, 440.0, shape)
		assert_eq(buf.size(), int(RATE * 0.5))
		assert_near(_peak(buf), 1.0, 0.05, "full scale")
		assert_near(_crossings(buf), 440, 6, "440 Hz for half a second crosses zero about 440 times")
	var fm := Sfx.fm(0.2, 300.0, 150.0, 2.0)
	assert_eq(fm.size(), int(RATE * 0.2))
	assert_true(fm != Sfx.tone(0.2, 300.0), "modulation changes the tone")
	assert_lt(_peak(fm), 1.0001)


func test_sweep_goes_from_low_to_high() -> void:
	var buf := Sfx.sweep(1.0, 100.0, 1000.0)
	var first := _crossings(buf.slice(0, RATE / 4))
	var last := _crossings(buf.slice(RATE * 3 / 4))
	assert_gt(last, first * 2, "the end is much higher than the start")


func test_noise_is_seeded() -> void:
	for color: int in [Sfx.Hiss.WHITE, Sfx.Hiss.PINK, Sfx.Hiss.BROWN]:
		var a := Sfx.noise(0.1, color, 7)
		assert_eq(a, Sfx.noise(0.1, color, 7), "same seed, same sound")
		assert_true(a != Sfx.noise(0.1, color, 8), "another seed, another sound")
		assert_lt(_peak(a), 1.0001)
		assert_gt(_energy(a), 0.0001)
	# White is bright, brown is dark: brown changes less from sample to sample.
	assert_gt(_crossings(Sfx.noise(0.5, Sfx.Hiss.WHITE, 1)), _crossings(Sfx.noise(0.5, Sfx.Hiss.PINK, 1)))
	assert_gt(_crossings(Sfx.noise(0.5, Sfx.Hiss.PINK, 1)), _crossings(Sfx.noise(0.5, Sfx.Hiss.BROWN, 1)))


func test_envelopes_shape_the_sound() -> void:
	var buf := Sfx.envelope(Sfx.tone(1.0, 200.0, Sfx.Wave.SQUARE), 0.1, 0.1, 0.5, 0.2)
	assert_near(absf(buf[0]), 0.0, 0.01, "starts silent")
	assert_near(absf(buf[int(RATE * 0.1) - 1]), 1.0, 0.02, "peak at the end of the attack")
	assert_near(absf(buf[int(RATE * 0.5)]), 0.5, 0.02, "sustain level")
	assert_near(absf(buf[buf.size() - 1]), 0.0, 0.01, "ends silent")
	var tail := Sfx.exp_tail(Sfx.tone(1.0, 200.0, Sfx.Wave.SQUARE), 6.0)
	assert_near(absf(tail[0]), 1.0, 0.01)
	assert_near(absf(tail[RATE / 2]), exp(-3.0), 0.01, "halfway: e^-(6 * 0.5)")


func test_filters_cut_what_they_should() -> void:
	var low := Sfx.tone(0.3, 100.0)
	var high := Sfx.tone(0.3, 6000.0)
	assert_gt(_energy(Sfx.low_pass(low, 800.0)), _energy(low) * 0.8, "low pass keeps the bass")
	assert_lt(_energy(Sfx.low_pass(high, 800.0)), _energy(high) * 0.1, "and drops the treble")
	assert_gt(_energy(Sfx.high_pass(high, 800.0)), _energy(high) * 0.5, "high pass keeps the treble")
	assert_lt(_energy(Sfx.high_pass(low, 800.0)), _energy(low) * 0.1, "and drops the bass")
	var mid := Sfx.tone(0.3, 1000.0)
	assert_gt(_energy(Sfx.band_pass(mid, 500.0, 2000.0)), _energy(Sfx.band_pass(low, 500.0, 2000.0)) * 4.0)
	assert_gt(_energy(Sfx.band_pass(mid, 500.0, 2000.0)), _energy(Sfx.band_pass(high, 500.0, 2000.0)) * 4.0)


func test_comb_clip_and_crush() -> void:
	var click := PackedFloat32Array()
	click.resize(RATE / 10)
	click[0] = 1.0
	var echo := Sfx.comb(click, 0.01, 0.5)
	assert_near(echo[int(RATE * 0.01)], 0.5, 0.001, "first echo after the delay")
	assert_near(echo[int(RATE * 0.01) * 2], 0.25, 0.001, "second echo, quieter")
	var loud := Sfx.soft_clip(Sfx.gain(Sfx.tone(0.1, 200.0), 8.0), 1.0)
	assert_lt(_peak(loud), 1.0001, "never past full scale")
	assert_gt(_energy(loud), _energy(Sfx.tone(0.1, 200.0)), "but fatter than the clean tone")
	var crushed := Sfx.bit_crush(Sfx.tone(0.1, 200.0), 3, 1)
	var levels := {}
	for v in crushed:
		levels[snappedf(v, 0.0001)] = true
	assert_lt(levels.size(), 10, "3 bits leave a handful of levels")


func test_mix_layers_and_convert() -> void:
	var mixed := Sfx.mix([Sfx.tone(0.2, 100.0), Sfx.tone(0.5, 300.0)], [0.5, 0.25])
	assert_eq(mixed.size(), int(RATE * 0.5), "as long as the longest layer")
	assert_lt(_peak(mixed), 0.76)
	var stream := Sfx.to_stream(mixed)
	assert_eq(stream.format, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(stream.mix_rate, RATE)
	assert_eq(stream.data.size(), mixed.size() * 2)
	assert_near(stream.get_length(), 0.5, 0.01)


# --- Named sounds -----------------------------------------------------------------

func test_streams_are_built_once_and_identical_every_run() -> void:
	var a := Sfx.stream("gunshot")
	assert_true(a != null, "the gunshot is registered")
	assert_true(a == Sfx.stream("gunshot"), "cached")
	Sfx.reset()
	assert_eq(Sfx.stream("gunshot").data, a.data, "rebuilt bit for bit")
	assert_eq(Sfx.stream("no such sound"), null)


func test_register_adds_a_sound_on_a_bus() -> void:
	Sfx.register("test_beep", "UI", func(): return Sfx.exp_tail(Sfx.tone(0.2, 880.0), 20.0))
	assert_near(Sfx.stream("test_beep").get_length(), 0.2, 0.01)
	assert_true(Sfx.play_ui("test_beep"))
	var v: Dictionary = Sfx.pool().active()[0]
	assert_eq(v.player.bus, &"UI")
	Sfx.unregister("test_beep")


# --- Playing ----------------------------------------------------------------------

func test_play_places_a_voice_in_the_world() -> void:
	assert_true(Sfx.play("gunshot", Vector3(3, 1, -4), 0.1))
	var voices := Sfx.pool().active()
	assert_eq(voices.size(), 1)
	var p: AudioStreamPlayer3D = voices[0].player
	assert_eq(p.global_position, Vector3(3, 1, -4))
	assert_eq(p.bus, &"Guns")
	assert_gt(p.pitch_scale, 0.899)
	assert_lt(p.pitch_scale, 1.101)
	assert_near(p.max_distance, Config.SFX_MAX_DISTANCE)
	assert_lt(p.attenuation_filter_cutoff_hz, 20000.0, "far sounds lose their treble")
	assert_false(Sfx.play("no such sound", Vector3.ZERO), "unknown names are refused, not a crash")


func test_voice_pool_never_grows_past_its_cap() -> void:
	for i in Config.SFX_VOICES * 3:
		Sfx.play("gunshot", Vector3(i, 0, 0))
	assert_eq(Sfx.pool().active().size(), Config.SFX_VOICES)
	assert_eq(Sfx.pool().get_child_count(), Config.SFX_VOICES + Config.SFX_UI_VOICES, "players are made once, up front")
	for i in Config.SFX_UI_VOICES * 3:
		Sfx.play_ui("gunshot")
	assert_eq(Sfx.pool().active().size(), Config.SFX_VOICES + Config.SFX_UI_VOICES)


func test_a_full_pool_steals_the_farthest_voice_for_a_nearer_sound() -> void:
	Sfx.pool().listener = Vector3.ZERO
	for i in Config.SFX_VOICES:
		Sfx.play("gunshot", Vector3(10 + i, 0, 0))
	var farthest := Vector3(10 + Config.SFX_VOICES - 1, 0, 0)
	assert_true(Sfx.play("gunshot", Vector3(2, 0, 0)), "a near sound gets in")
	var positions := []
	for v: Dictionary in Sfx.pool().active():
		positions.append(v.player.global_position)
	assert_true(positions.has(Vector3(2, 0, 0)))
	assert_false(positions.has(farthest), "the farthest one made room")
	assert_eq(Sfx.stats.stolen, 1)
	assert_false(Sfx.play("gunshot", Vector3(500, 0, 0)), "a sound farther than everything playing is dropped")
	assert_eq(Sfx.stats.dropped, 1)


func test_finished_voices_are_free_again() -> void:
	Sfx.register("test_blip", "UI", func(): return Sfx.tone(0.05, 500.0))
	Sfx.play("test_blip", Vector3.ZERO)
	assert_eq(Sfx.pool().active().size(), 1)
	# Voices end by the wall clock; game time can run ahead of it after a hitch, so poll instead of sleeping.
	assert_true(await wait_until(func() -> bool: return Sfx.pool().active().is_empty()), "the blip ended and its voice is free")
	Sfx.unregister("test_blip")


func test_firing_a_gun_goes_through_the_engine() -> void:
	var g := await new_game()
	g.local_player.weapons.switch_to(Weapons.AK47)
	g.local_player.weapons.step(1.0)
	var before: int = Sfx.stats.played
	g._fire(Weapons.def(Weapons.AK47))
	assert_eq(Sfx.stats.played, before + 1)
