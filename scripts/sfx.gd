class_name Sfx
## Every sound in the game, made in code: no audio files.
##
## Playing:   Sfx.play("gunshot", position, 0.05)   a sound in the world (the only way to make one)
##            Sfx.play_ui("click")                  a sound in your head: menus, your own gun
## Adding:    Sfx.register("name", "Bus", func(): return <samples>)   one builder function per sound,
##            written with the primitives below; it runs once and the stream is cached.
##
## Samples are PackedFloat32Array at RATE, -1..1. Noise takes a seed, so a sound is the same on
## every run and every peer. Voices are pooled and capped (Config.SFX_VOICES): when the pool is
## full a new sound takes the place of the farthest one playing, or is dropped if it is farther still.

enum Wave { SINE, SAW, SQUARE }
enum Hiss { WHITE, PINK, BROWN }

const RATE := 22050
const BUSES := ["Master", "Guns", "Zombies", "World", "UI", "Music"]

static var stats := { "played": 0, "stolen": 0, "dropped": 0 }
static var _defs := {}    ## name -> { bus, build }
static var _streams := {} ## name -> AudioStreamWAV
static var _pool: Pool


## Make the audio buses (in code: there is no bus layout file). Safe to call more than once.
static func ensure_buses() -> void:
	for bus: String in BUSES:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")


# --- Named sounds -----------------------------------------------------------------

static func register(sound: String, bus: String, build: Callable) -> void:
	_defs[sound] = { "bus": bus, "build": build }
	_streams.erase(sound)


static func unregister(sound: String) -> void:
	_defs.erase(sound)
	_streams.erase(sound)


static func _builtin() -> void:
	if not _defs.has("gunshot"):
		register("gunshot", "Guns", _gunshot)
	if not _defs.has("dry_fire"):
		register("dry_fire", "Guns", _dry_fire)
	if not _defs.has("thud"):
		register("thud", "World", _thud)
	if not _defs.has("siren"):
		register("siren", "World", _siren)
	if not _defs.has("beep"):
		register("beep", "UI", _beep)
	if not _defs.has("breath"):
		register("breath", "World", _breath)
	if not _defs.has("heartbeat"):
		register("heartbeat", "UI", _heartbeat)
	if not _defs.has("whiz"):
		register("whiz", "Guns", _whiz)


## The cached stream of a registered sound (null if there is no such sound).
static func stream(sound: String) -> AudioStreamWAV:
	_builtin()
	if not _streams.has(sound):
		if not _defs.has(sound):
			return null
		var samples: PackedFloat32Array = (_defs[sound].build as Callable).call()
		_streams[sound] = to_stream(samples)
	return _streams[sound]


## Play `sound` at `position` in the world. `pitch_jitter` 0.05 means each play is up to 5% higher or lower.
## Returns false if the sound is unknown or was dropped because the pool is full of nearer sounds.
static func play(sound: String, position: Vector3, pitch_jitter := 0.0, volume_db := 0.0, pitch := 1.0) -> bool:
	var s := stream(sound)
	return s != null and pool().play_3d(s, _defs[sound].bus, position, pitch_jitter, volume_db, pitch)


## Play `sound` with no position: interface sounds and the local player's own gun.
static func play_ui(sound: String, volume_db := 0.0, pitch := 1.0) -> bool:
	var s := stream(sound)
	return s != null and pool().play_2d(s, _defs[sound].bus, volume_db, pitch)


## The node that owns the voices. Made on first use, lives under the scene tree's root.
static func pool() -> Pool:
	if _pool == null or not is_instance_valid(_pool):
		ensure_buses()
		_pool = Pool.new()
		_pool.name = "SfxPool"
		(Engine.get_main_loop() as SceneTree).root.add_child(_pool)
	return _pool


## Drop the pool and every cached stream (tests).
static func reset() -> void:
	if _pool != null and is_instance_valid(_pool):
		_pool.free()
	_pool = null
	_streams.clear()
	stats = { "played": 0, "stolen": 0, "dropped": 0 }


# --- Sounds -----------------------------------------------------------------------

## The shared gunshot: a burst of low-passed noise with a steep fall. Guns play it at their own pitch.
static func _gunshot() -> PackedFloat32Array:
	var buf := noise(0.25, Hiss.WHITE, 1)
	var n := buf.size()
	var lp := 0.0
	for i in n:
		var env := pow(1.0 - float(i) / n, 3.0)
		lp = lerpf(lp, buf[i] * env, 0.35)
		buf[i] = clampf(lp * 1.8, -1.0, 1.0)
	return buf


## The hammer falling on an empty chamber: a tick of bright noise over a short metallic ring.
static func _dry_fire() -> PackedFloat32Array:
	var tick := exp_tail(high_pass(noise(0.05, Hiss.WHITE, 5), 2500.0), 140.0)
	var ring := exp_tail(fm(0.05, 1900.0, 2730.0, 1.5), 90.0)
	return soft_clip(mix([tick, ring], [0.9, 0.35]), 1.5)


## A rifle stock into a body: a low, dull knock.
static func _thud() -> PackedFloat32Array:
	var body := exp_tail(sweep(0.18, 140.0, 60.0), 26.0)
	var slap := exp_tail(low_pass(noise(0.08, Hiss.PINK, 31), 900.0), 60.0)
	return soft_clip(mix([body, slap], [1.0, 0.7]), 1.6)


## An air-raid siren winding up, holding and winding down: a saw swept up and back, softened.
static func _siren() -> PackedFloat32Array:
	var up := sweep(1.2, 220.0, 620.0, Wave.SAW)
	var hold := tone(0.8, 620.0, Wave.SAW)
	var down := sweep(1.0, 620.0, 260.0, Wave.SAW)
	var buf := PackedFloat32Array()
	buf.append_array(up)
	buf.append_array(hold)
	buf.append_array(down)
	return envelope(low_pass(buf, 1800.0), 0.3, 0.2, 0.9, 0.6)


## A short electronic beep (the extraction countdown); played at rising pitches.
static func _beep() -> PackedFloat32Array:
	return envelope(mix([tone(0.14, 1320.0, Wave.SQUARE), tone(0.14, 2640.0)], [0.25, 0.2]), 0.004, 0.03, 0.7, 0.05)


## One heavy breath, in and out: band-passed noise that swells twice, the second lower.
static func _breath() -> PackedFloat32Array:
	var breath_in := envelope(band_pass(noise(0.32, Hiss.PINK, 21), 900.0, 2600.0), 0.14, 0.1, 0.4, 0.08)
	var breath_out := envelope(band_pass(noise(0.4, Hiss.PINK, 22), 500.0, 1700.0), 0.08, 0.16, 0.3, 0.16)
	var buf := _blank(0.78)
	for i in breath_in.size():
		buf[i] = breath_in[i] * 2.2
	var at := int(0.36 * RATE)
	for i in breath_out.size():
		if at + i < buf.size():
			buf[at + i] += breath_out[i] * 2.6
	return soft_clip(buf)


## A heartbeat heard from inside: lub-dub, two low thumps, the second softer.
static func _heartbeat() -> PackedFloat32Array:
	var lub := low_pass(exp_tail(sweep(0.16, 75.0, 42.0), 22.0), 220.0)
	var dub := low_pass(exp_tail(sweep(0.14, 68.0, 40.0), 26.0), 200.0)
	var buf := _blank(0.42)
	for i in lub.size():
		buf[i] = lub[i] * 1.6
	var at := int(0.2 * RATE)
	for i in dub.size():
		if at + i < buf.size():
			buf[at + i] += dub[i] * 1.1
	return soft_clip(buf, 1.4)


## A bullet going past your ear: a bright hiss that drops in pitch as it goes by.
static func _whiz() -> PackedFloat32Array:
	var hiss := band_pass(noise(0.22, Hiss.WHITE, 41), 1800.0, 6500.0)
	var tone_ := sweep(0.22, 3200.0, 900.0)
	var buf := mix([hiss, tone_], [0.9, 0.25])
	var n := buf.size()
	for i in n:
		var x := float(i) / n
		buf[i] *= sin(minf(x * 3.0, 1.0) * PI * 0.5) * (1.0 - x) * (1.0 - x) * 1.6
	return soft_clip(buf)


# --- Sources ----------------------------------------------------------------------

static func _blank(seconds: float) -> PackedFloat32Array:
	var buf := PackedFloat32Array()
	buf.resize(int(RATE * seconds))
	return buf


static func _wave(phase: float, shape: int) -> float:
	match shape:
		Wave.SAW: return 2.0 * fposmod(phase, 1.0) - 1.0
		Wave.SQUARE: return 1.0 if fposmod(phase, 1.0) < 0.5 else -1.0
	return sin(phase * TAU)


static func tone(seconds: float, freq: float, shape := Wave.SINE) -> PackedFloat32Array:
	return sweep(seconds, freq, freq, shape)


## A tone whose pitch slides from `from_hz` to `to_hz` (exponentially, as the ear hears it).
static func sweep(seconds: float, from_hz: float, to_hz: float, shape := Wave.SINE) -> PackedFloat32Array:
	var buf := _blank(seconds)
	var n := buf.size()
	var phase := 0.0
	var ratio := to_hz / from_hz
	for i in n:
		buf[i] = _wave(phase, shape)
		phase += from_hz * pow(ratio, float(i) / n) / RATE
	return buf


## Two sines, one bending the other's pitch: bells, metal, growls. `index` is how hard.
static func fm(seconds: float, carrier_hz: float, mod_hz: float, index: float) -> PackedFloat32Array:
	var buf := _blank(seconds)
	for i in buf.size():
		var t := float(i) / RATE
		buf[i] = sin(TAU * carrier_hz * t + index * sin(TAU * mod_hz * t))
	return buf


## White is hiss, pink is softer (rain, breath), brown is a rumble.
static func noise(seconds: float, color := Hiss.WHITE, noise_seed := 0) -> PackedFloat32Array:
	var buf := _blank(seconds)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([noise_seed, color])
	var b0 := 0.0
	var b1 := 0.0
	var b2 := 0.0
	var brown := 0.0
	for i in buf.size():
		var white := rng.randf_range(-1.0, 1.0)
		match color:
			Hiss.PINK: # Paul Kellet's economy filter
				b0 = 0.99765 * b0 + white * 0.0990460
				b1 = 0.96300 * b1 + white * 0.2965164
				b2 = 0.57000 * b2 + white * 1.0526913
				buf[i] = clampf((b0 + b1 + b2 + white * 0.1848) * 0.25, -1.0, 1.0)
			Hiss.BROWN:
				brown = clampf(brown + white * 0.06, -1.0, 1.0)
				buf[i] = brown
			_:
				buf[i] = white
	return buf


# --- Shaping ----------------------------------------------------------------------

static func gain(buf: PackedFloat32Array, amount: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	for i in out.size():
		out[i] *= amount
	return out


## Attack, decay to `sustain` (0..1), hold, release: times in seconds, the hold is whatever is left.
static func envelope(buf: PackedFloat32Array, attack: float, decay: float, sustain: float, release: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	var n := out.size()
	var a := attack * RATE
	var d := decay * RATE
	var r := release * RATE
	for i in n:
		var level := sustain
		if i < a:
			level = (i + 1) / a
		elif i < a + d:
			level = lerpf(1.0, sustain, (i - a) / d)
		if i >= n - r:
			level *= (n - 1 - i) / r
		out[i] *= level
	return out


## Fade as e^(-rate * seconds): the natural ring-out of anything struck.
static func exp_tail(buf: PackedFloat32Array, rate: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	for i in out.size():
		out[i] *= exp(-rate * i / RATE)
	return out


static func _alpha(cutoff_hz: float) -> float:
	return 1.0 - exp(-TAU * cutoff_hz / RATE)


## One-pole low pass, run twice for a steeper slope.
static func low_pass(buf: PackedFloat32Array, cutoff_hz: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	var k := _alpha(cutoff_hz)
	for _pass in 2:
		var y := 0.0
		for i in out.size():
			y += (out[i] - y) * k
			out[i] = y
	return out


static func high_pass(buf: PackedFloat32Array, cutoff_hz: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	var k := _alpha(cutoff_hz)
	for _pass in 2:
		var y := 0.0
		for i in out.size():
			y += (out[i] - y) * k
			out[i] -= y
	return out


static func band_pass(buf: PackedFloat32Array, low_hz: float, high_hz: float) -> PackedFloat32Array:
	return low_pass(high_pass(buf, low_hz), high_hz)


## Feed the sound back into itself after `delay` seconds: metallic ring (short) or echo (long).
static func comb(buf: PackedFloat32Array, delay: float, feedback: float) -> PackedFloat32Array:
	var out := buf.duplicate()
	var d := maxi(int(delay * RATE), 1)
	for i in range(d, out.size()):
		out[i] += out[i - d] * feedback
	return out


## Push the sound into a soft ceiling: louder and dirtier, never past full scale.
static func soft_clip(buf: PackedFloat32Array, drive := 1.0) -> PackedFloat32Array:
	var out := buf.duplicate()
	for i in out.size():
		out[i] = tanh(out[i] * drive)
	return out


## Fewer levels (`bits`) and each sample held for `hold` extra samples: radio, cheap speakers.
static func bit_crush(buf: PackedFloat32Array, bits: int, hold := 0) -> PackedFloat32Array:
	var out := buf.duplicate()
	var steps := float((1 << bits) - 1) / 2.0
	var held := 0.0
	for i in out.size():
		if hold <= 0 or i % (hold + 1) == 0:
			held = round(out[i] * steps) / steps
		out[i] = held
	return out


## Sum layers, each with its own gain. As long as the longest one.
static func mix(layers: Array, gains: Array = []) -> PackedFloat32Array:
	var n := 0
	for l: PackedFloat32Array in layers:
		n = maxi(n, l.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for li in layers.size():
		var l: PackedFloat32Array = layers[li]
		var g: float = gains[li] if li < gains.size() else 1.0
		for i in l.size():
			out[i] += l[i] * g
	return out


static func to_stream(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


# --- Voices -----------------------------------------------------------------------

## A fixed set of players made once. Nothing is allocated when a sound plays.
class Pool extends Node:
	var listener: Variant = null ## where the ears are; null = the current camera (tests pin it)
	var _voices: Array = []      ## { player, positional, ends (ms), at }
	var _rng := RandomNumberGenerator.new()

	func _init() -> void:
		for i in Config.SFX_VOICES:
			var p := AudioStreamPlayer3D.new()
			p.unit_size = Config.SFX_UNIT_SIZE
			p.max_distance = Config.SFX_MAX_DISTANCE
			p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
			p.attenuation_filter_cutoff_hz = Config.SFX_FAR_CUTOFF_HZ # treble falls away with distance
			p.attenuation_filter_db = Config.SFX_FAR_CUTOFF_DB
			add_child(p)
			_voices.append({ "player": p, "positional": true, "ends": 0, "at": Vector3.ZERO })
		for i in Config.SFX_UI_VOICES:
			var p := AudioStreamPlayer.new()
			add_child(p)
			_voices.append({ "player": p, "positional": false, "ends": 0, "at": Vector3.ZERO })

	## Voices that are sounding right now.
	func active() -> Array:
		var now := Time.get_ticks_msec()
		return _voices.filter(func(v: Dictionary) -> bool: return v.ends > now)

	func ears() -> Vector3:
		if listener != null:
			return listener
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		return cam.global_position if cam != null else Vector3.ZERO

	func play_3d(s: AudioStreamWAV, bus: String, at: Vector3, jitter: float, volume_db: float, pitch: float) -> bool:
		var v := _free_voice(true)
		if v.is_empty(): # full: the farthest voice gives way, unless the new sound is farther still
			var from := ears()
			var far := from.distance_squared_to(at)
			for c: Dictionary in _voices:
				var c_at: Vector3 = c.at
				if c.positional and from.distance_squared_to(c_at) > far:
					far = from.distance_squared_to(c_at)
					v = c
			if v.is_empty():
				Sfx.stats.dropped += 1
				return false
			Sfx.stats.stolen += 1
		var p: AudioStreamPlayer3D = v.player
		p.global_position = at
		v.at = at
		_start(v, p, s, bus, volume_db, pitch * (1.0 + _rng.randf_range(-jitter, jitter)))
		return true

	func play_2d(s: AudioStreamWAV, bus: String, volume_db: float, pitch: float) -> bool:
		var v := _free_voice(false)
		if v.is_empty(): # full: restart the one closest to finishing
			for c: Dictionary in _voices:
				if not c.positional and (v.is_empty() or c.ends < v.ends):
					v = c
			Sfx.stats.stolen += 1
		_start(v, v.player, s, bus, volume_db, pitch)
		return true

	func _free_voice(positional: bool) -> Dictionary:
		var now := Time.get_ticks_msec()
		for v: Dictionary in _voices:
			if v.positional == positional and v.ends <= now:
				return v
		return {}

	## `p` is an AudioStreamPlayer or an AudioStreamPlayer3D: the same properties under both.
	func _start(v: Dictionary, p: Node, s: AudioStreamWAV, bus: String, volume_db: float, pitch: float) -> void:
		p.set(&"stream", s)
		p.set(&"bus", bus)
		p.set(&"volume_db", volume_db)
		p.set(&"pitch_scale", maxf(pitch, 0.01))
		p.call(&"play")
		v.ends = Time.get_ticks_msec() + int(s.get_length() / maxf(pitch, 0.01) * 1000.0)
		Sfx.stats.played += 1
