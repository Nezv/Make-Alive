class_name GunVoice
## Every gun's shot, synthesised from layers with the Sfx primitives: a crack (a burst of bright noise),
## a body (a thump swept down, by calibre, with a rumble for the big ones), a mechanical click, and
## for some an echo. Each gun has three: near (`sound(id)`), far (`+ "_far"`: the crack is gone, a dull
## thump stays) and suppressed (`+ "_sup"`). The room answers with a tail by place (`tail(place)`).
## Registered in Sfx (`register_all`), built the first time each is played.

enum Place { INDOOR, STREET, OPEN }
const PLACE_NAMES := ["indoor", "street", "open"]

## Per gun: crack [seconds, gain, high-pass Hz], body [from Hz, to Hz, seconds, gain, decay], rumble
## [seconds, gain, low-pass Hz] (0 seconds: none), click gain, buzz (an FM rasp, gain), echo
## [delay s, feedback, repeats] (0 repeats: none).
const RECIPES := [
	{ "crack": [0.05, 0.9, 2200.0], "body": [190.0, 90.0, 0.12, 0.7, 34.0], "rumble": [0.0, 0.0, 0.0], "click": 0.35, "buzz": 0.0, "echo": [0.0, 0.0, 0] },     # P19: a short pop
	{ "crack": [0.04, 0.8, 3000.0], "body": [240.0, 120.0, 0.1, 0.55, 40.0], "rumble": [0.0, 0.0, 0.0], "click": 0.3, "buzz": 0.45, "echo": [0.0, 0.0, 0] },    # P90: a buzzy snap
	{ "crack": [0.07, 1.0, 1800.0], "body": [150.0, 60.0, 0.22, 0.95, 18.0], "rumble": [0.3, 0.35, 500.0], "click": 0.3, "buzz": 0.0, "echo": [0.0, 0.0, 0] },  # Type 95: a heavy bark
	{ "crack": [0.08, 1.0, 1500.0], "body": [130.0, 55.0, 0.26, 1.0, 15.0], "rumble": [0.35, 0.4, 450.0], "click": 0.35, "buzz": 0.0, "echo": [0.0, 0.0, 0] },  # AK47: heavier still
	{ "crack": [0.03, 0.08, 1200.0], "body": [160.0, 80.0, 0.12, 0.6, 30.0], "rumble": [0.0, 0.0, 0.0], "click": 0.2, "buzz": 0.0, "echo": [0.0, 0.0, 0], "dull": true }, # AS Val: a soft thud
	{ "crack": [0.09, 1.0, 1200.0], "body": [100.0, 40.0, 0.4, 1.0, 9.0], "rumble": [0.8, 0.6, 350.0], "click": 0.3, "buzz": 0.0, "echo": [0.0, 0.0, 0] },      # USAS-12: a boom
	{ "crack": [0.1, 1.0, 1000.0], "body": [90.0, 36.0, 0.45, 1.0, 8.0], "rumble": [0.9, 0.65, 320.0], "click": 0.25, "buzz": 0.0, "echo": [0.0, 0.0, 0] },     # SPAS-12: a deeper boom
	{ "crack": [0.06, 1.0, 2600.0], "body": [120.0, 45.0, 0.3, 0.9, 12.0], "rumble": [0.5, 0.4, 400.0], "click": 0.2, "buzz": 0.0, "echo": [0.22, 0.55, 4] },   # T-5000: a crack that rolls on
	{ "crack": [0.06, 1.0, 2000.0], "body": [140.0, 60.0, 0.22, 0.85, 16.0], "rumble": [0.35, 0.3, 450.0], "click": 0.3, "buzz": 0.0, "echo": [0.12, 0.3, 1] }, # Dragunov: a sharp slap
]


static func sound(id: int) -> String:
	return "shot_%d" % id


static func tail(place: int) -> String:
	return "tail_" + PLACE_NAMES[place]


## Register every gun's three voices and the three tails (Sfx calls this).
static func register_all() -> void:
	for id in Weapons.COUNT:
		Sfx.register(sound(id), "Guns", func(): return shot(id, 0))
		Sfx.register(sound(id) + "_far", "Guns", func(): return shot(id, 1))
		Sfx.register(sound(id) + "_sup", "Guns", func(): return shot(id, 2))
	for place in Place.size():
		Sfx.register(tail(place), "Guns", func(): return room(place))


## A shot of gun `id`: `variant` 0 near, 1 far, 2 suppressed.
static func shot(id: int, variant: int) -> PackedFloat32Array:
	var r: Dictionary = RECIPES[id]
	var c: Array = r.crack
	var b: Array = r.body
	var ru: Array = r.rumble
	var e: Array = r.echo
	var seed_ := 100 + id * 17
	var layers := []
	var gains := []
	var body := Sfx.low_pass(Sfx.exp_tail(Sfx.sweep(b[2], b[0], b[1]), b[4]), 700.0)
	if variant == 0:
		layers.append(Sfx.exp_tail(Sfx.high_pass(Sfx.noise(c[0], Sfx.Hiss.WHITE, seed_), c[2]), 4.0 / c[0]))
		gains.append(c[1])
	elif variant == 2: # a suppressor: the crack becomes a muffled puff
		layers.append(Sfx.exp_tail(Sfx.band_pass(Sfx.noise(0.06, Sfx.Hiss.PINK, seed_), 300.0, 1400.0), 50.0))
		gains.append(0.35)
	layers.append(body)
	gains.append(float(b[3]) * (0.45 if variant == 2 else 1.0))
	if float(ru[0]) > 0.0:
		layers.append(Sfx.exp_tail(Sfx.low_pass(Sfx.noise(ru[0], Sfx.Hiss.BROWN, seed_ + 1), ru[2]), 3.0 / float(ru[0])))
		gains.append(float(ru[1]) * (0.5 if variant == 2 else 1.0))
	if variant != 1:
		layers.append(Sfx.exp_tail(Sfx.fm(0.04, 2300.0 + id * 90.0, 3300.0, 1.5), 110.0))
		gains.append(r.click)
	if float(r.buzz) > 0.0 and variant == 0:
		layers.append(Sfx.exp_tail(Sfx.fm(0.09, 520.0, 1210.0, 4.0), 30.0))
		gains.append(r.buzz)
	var buf := Sfx.mix(layers, gains)
	if int(e[2]) > 0: # the shot rolls back off the distance
		buf = _echo(buf, e[0], e[1], e[2])
	if r.get("dull", false) or variant == 2: # built quiet: everything bright muffled
		buf = Sfx.low_pass(buf, 1300.0)
	if variant == 1: # far: only the low thump, softened, a little late
		buf = Sfx.low_pass(Sfx.low_pass(buf, 260.0), 260.0)
		var late := Sfx._blank(0.03)
		late.append_array(buf)
		buf = late
	buf = Sfx.soft_clip(buf, 1.3)
	return _normalise(buf, [0.9, 0.5, 0.45][variant])


## Copies of `buf` every `delay` seconds, each `feedback` as loud as the last.
static func _echo(buf: PackedFloat32Array, delay: float, feedback: float, repeats: int) -> PackedFloat32Array:
	var step := int(delay * Sfx.RATE)
	var out := buf.duplicate()
	out.resize(buf.size() + step * repeats)
	var g := 1.0
	for k in range(1, repeats + 1):
		g *= feedback
		var soft := Sfx.low_pass(buf, 1800.0 / k)
		for i in soft.size():
			out[i + step * k] += soft[i] * g
	return out


static func _normalise(buf: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var top := 0.0
	for v in buf:
		top = maxf(top, absf(v))
	if top > 0.0:
		var k := peak / top
		for i in buf.size():
			buf[i] *= k
	return buf


## The room answering a shot: short and boxy indoors, slapback off the buildings in the street, a long
## fading roll in the open.
static func room(place: int) -> PackedFloat32Array:
	match place:
		Place.INDOOR:
			var b := Sfx.exp_tail(Sfx.low_pass(Sfx.noise(0.3, Sfx.Hiss.PINK, 301), 1800.0), 16.0)
			return _normalise(Sfx.comb(b, 0.011, 0.55), 0.35)
		Place.STREET:
			var b := Sfx.exp_tail(Sfx.low_pass(Sfx.noise(0.25, Sfx.Hiss.PINK, 302), 1500.0), 14.0)
			return _normalise(_echo(b, 0.19, 0.6, 5), 0.4)
		_:
			var b := Sfx.exp_tail(Sfx.low_pass(Sfx.noise(1.8, Sfx.Hiss.BROWN, 303), 600.0), 2.2)
			return _normalise(b, 0.35)


## How shot number `i` differs from the last: [pitch multiplier, decibels], the same on every run.
static func variation(i: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = hash(i * 7919 + 13)
	return [1.0 + r.randf_range(-Config.SHOT_PITCH_VARY, Config.SHOT_PITCH_VARY), r.randf_range(-Config.SHOT_DB_VARY, Config.SHOT_DB_VARY)]
