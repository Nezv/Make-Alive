extends TestCase
## Gun voices: every gun has its own synthesised shot built from layers (a crack of noise, a body thump by
## calibre, a mechanical click), a far version that has lost the crack, a suppressed version; a tail
## by place (boxy indoors, slapback between buildings, long in the open); a small seeded variation per
## shot.


func _samples(sound: String) -> PackedFloat32Array:
	var s := Sfx.stream(sound)
	assert_true(s != null, sound)
	var data := s.data
	var out := PackedFloat32Array()
	out.resize(data.size() / 2)
	for i in out.size():
		out[i] = data.decode_s16(i * 2) / 32768.0
	return out


func _rms(buf: PackedFloat32Array) -> float:
	var sum := 0.0
	for v in buf:
		sum += v * v
	return sqrt(sum / maxf(1.0, buf.size()))


func _energy(buf: PackedFloat32Array) -> float:
	var sum := 0.0
	for v in buf:
		sum += v * v
	return sum


## How much of it is high (the crack): the energy left after a high-pass.
func _bright(buf: PackedFloat32Array) -> float:
	return _rms(Sfx.high_pass(buf, 2500.0))


func _seconds(sound: String) -> float:
	return _samples(sound).size() / float(Sfx.RATE)


func test_every_gun_has_its_own_shot_a_far_one_and_a_suppressed_one() -> void:
	var seen := {}
	for id in Weapons.COUNT:
		for variant in ["", "_far", "_sup"]:
			var name: String = GunVoice.sound(id) + variant
			var buf := _samples(name)
			assert_gt(buf.size(), 1000, name)
			var peak := 0.0
			for v in buf:
				peak = maxf(peak, absf(v))
			assert_true(peak > 0.05 and peak <= 1.0, "%s is heard and does not clip: %f" % [name, peak])
		var key := str(_samples(GunVoice.sound(id)).slice(0, 400))
		assert_false(seen.has(key), "%s sounds like %s" % [Weapons.def(id).name, seen.get(key, "")])
		seen[key] = Weapons.def(id).name


func test_the_voices_have_their_character() -> void:
	assert_lt(_seconds(GunVoice.sound(Weapons.P19)), _seconds(GunVoice.sound(Weapons.SPAS12)), "a pistol's pop is shorter than a shotgun's boom")
	assert_gt(_seconds(GunVoice.sound(Weapons.T5000)), 1.0, "the sniper rolls on")
	assert_lt(_bright(_samples(GunVoice.sound(Weapons.ASVAL))), _bright(_samples(GunVoice.sound(Weapons.AK47))) * 0.5, "the AS Val is a soft thud")
	assert_gt(_energy(_samples(GunVoice.sound(Weapons.USAS12))), _energy(_samples(GunVoice.sound(Weapons.P19))), "a shotgun is bigger than a pistol")


func test_far_away_the_crack_is_gone_and_the_thump_stays() -> void:
	for id in [Weapons.AK47, Weapons.T5000, Weapons.P19]:
		var near := _samples(GunVoice.sound(id))
		var far := _samples(GunVoice.sound(id) + "_far")
		assert_lt(_bright(far), _bright(near) * 0.4, Weapons.def(id).name)


func test_suppressed_is_quieter_and_duller() -> void:
	var near := _samples(GunVoice.sound(Weapons.AK47))
	var sup := _samples(GunVoice.sound(Weapons.AK47) + "_sup")
	assert_lt(_rms(sup), _rms(near))
	assert_lt(_bright(sup), _bright(near))


func test_the_tail_is_the_places() -> void:
	var indoor := _seconds("tail_indoor")
	var street := _seconds("tail_street")
	var open := _seconds("tail_open")
	assert_lt(indoor, street, "indoors it dies fast")
	assert_lt(indoor, open)
	var g := await new_game()
	assert_eq(g.place_at(g.map.player_spawn()), GunVoice.Place.INDOOR, "the corridor is a room")


func test_every_shot_varies_a_little_and_the_same_on_every_run() -> void:
	var seen := {}
	for i in 20:
		var v := GunVoice.variation(i)
		assert_eq(v, GunVoice.variation(i), "seeded by the shot")
		assert_true(absf(v[0] - 1.0) <= Config.SHOT_PITCH_VARY + 0.0001, "pitch %f" % v[0])
		assert_true(absf(v[1]) <= Config.SHOT_DB_VARY + 0.0001, "level %f" % v[1])
		seen[str(v)] = true
	assert_gt(seen.size(), 10, "not the same twice in a row")


func test_the_game_plays_your_guns_voice_and_far_shots_dull() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	var d := Weapons.def(g.local_player.weapons.current)
	Sfx.last.clear()
	g._fire(d)
	assert_true(Sfx.last.has(GunVoice.sound(g.local_player.weapons.current)), str(Sfx.last))
	assert_true(Sfx.last.has("tail_indoor"), "and the room answers")
	g._add_player(7, "Guest")
	var far := g.local_player.global_position + Vector3(0, 0, -(Config.SHOT_FAR_DIST + 20))
	g._apply_snapshot([{ "id": 7, "pos": far, "yaw": 0.0, "hp": 100, "kills": 0, "weapon": Weapons.AK47, "action": 0 }], [])
	Sfx.last.clear()
	g.shot_seen(7, Weapons.AK47, far + Vector3(0, 1.5, 0), far + Vector3(0, 1.5, -10))
	assert_true(Sfx.last.has(GunVoice.sound(Weapons.AK47) + "_far"), str(Sfx.last))
