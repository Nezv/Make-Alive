class_name WorldSounds
## The sounds of things in the world (S084), all made in code from Sfx's primitives:
## doors, barricades, lootboxes and pickups, glass, vehicles, the interface, and hums.
##
## One-shots are played where they happen (the host: Game.play_sound, every peer hears it);
## loops sit in the world as SoundSpots (scripts/world/sound_spot.gd). Every sound is seeded, so it
## is the same on every run and every peer. `samples(name)` builds one (cached); Sfx registers them.
##
## How the materials are made: wood is an impulse through a few wide, low resonances (a knock), or
## a stick-slip pulse train through formants (a creak); metal is narrow, inharmonic, high rings
## (clicks, keys, latches); glass is brighter rings still, many of them, scattered in time;
## cloth and cardboard are band-passed noise bursts.

## name -> longest it may be (seconds)
const ONE_SHOTS := {
	"door_handle": 0.3, "door_creak": 1.0, "door_slam": 0.8, "door_open": 1.3, "door_close": 1.1,
	"locked_rattle": 0.7, "door_splinter": 0.6, "door_break": 1.5,
	"hammer_knock": 0.4, "plank_crack": 0.7, "plank_snap": 0.5,
	"latch": 0.35, "lid_creak": 0.6, "rummage": 1.0, "lootbox_open": 1.6, "crate_open": 1.8,
	"ammo_clink": 0.7, "medkit_zip": 0.6, "key_jingle": 0.9,
	"glass_crack": 0.45, "glass_shatter": 1.3, "glass_shards": 1.5, "glass_crunch": 0.35,
	"ui_hover": 0.06, "ui_click": 0.1, "ui_back": 0.18, "ui_error": 0.32, "objective_chime": 1.5, "wave_horn": 2.4,
}
## name -> loop length (seconds)
const LOOPS := {
	"car_alarm": 3.2, "hazard_tick": 1.6, "horn_stuck": 1.0, "engine_tick": 4.0,
	"generator": 2.0, "tube_buzz": 2.0, "sign_creak": 3.2,
}
const UI := ["ui_hover", "ui_click", "ui_back", "ui_error", "objective_chime"]
const HAZARD_PERIOD := 0.8 ## seconds from one flash of the hazard lights to the next
const SEAM := 0.03         ## a loop's end is faded into its start over this long

const RATE := Sfx.RATE

static var _cache := {}


static func register_all() -> void:
	for sound: String in ONE_SHOTS:
		Sfx.register(sound, "UI" if sound in UI else "World", func(): return samples(sound))
	for sound: String in LOOPS:
		Sfx.register(sound, "World", func(): return samples(sound), true)


## The finished samples of one of these sounds (built once).
static func samples(sound: String) -> PackedFloat32Array:
	if not _cache.has(sound):
		_cache[sound] = _build(sound)
	return _cache[sound]


## A menu or HUD button that ticks when the mouse comes over it and clicks when pressed
## (`back`: the way out, a falling blip).
static func wire_button(b: BaseButton, back := false) -> void:
	b.mouse_entered.connect(func(): Sfx.play_ui("ui_hover", -10.0))
	b.pressed.connect(func(): Sfx.play_ui("ui_back" if back else "ui_click", -6.0))


static func _build(sound: String) -> PackedFloat32Array:
	match sound:
		"door_handle": return _done(_door_handle())
		"door_creak": return _done(_creak(0.9, 55.0, 150.0, 11, [[480.0, 70.0], [1150.0, 110.0], [2300.0, 180.0]]))
		"door_slam": return _done(_door_slam())
		"door_open":
			var b := _blank(1.25)
			_put(b, _door_handle(), 0.0)
			_put(b, _creak(0.95, 55.0, 150.0, 11, [[480.0, 70.0], [1150.0, 110.0], [2300.0, 180.0]]), 0.16, 0.8)
			return _done(b)
		"door_close":
			var b := _blank(1.05)
			_put(b, _creak(0.38, 90.0, 190.0, 12, [[480.0, 70.0], [1150.0, 110.0], [2300.0, 180.0]]), 0.0, 0.5)
			_put(b, _door_slam(), 0.3)
			return _done(b)
		"locked_rattle": return _done(_locked_rattle())
		"door_splinter": return _done(_splinter(0.55, 31, 1.0))
		"door_break": return _done(_door_break())
		"hammer_knock": return _done(_hammer_knock())
		"plank_crack": return _done(_plank_crack())
		"plank_snap": return _done(_plank_snap())
		"latch": return _done(_latch(2200.0, 41))
		"lid_creak": return _done(_creak(0.5, 110.0, 280.0, 23, [[900.0, 60.0], [2100.0, 110.0], [3700.0, 200.0]]))
		"rummage": return _done(_rummage(0.95, 51))
		"lootbox_open":
			var b := _blank(1.55)
			_put(b, _latch(2200.0, 41), 0.0)
			_put(b, _creak(0.5, 110.0, 280.0, 23, [[900.0, 60.0], [2100.0, 110.0], [3700.0, 200.0]]), 0.14, 0.6)
			_put(b, _rummage(0.9, 52), 0.6, 0.8)
			return _done(b)
		"crate_open":
			var b := _blank(1.75)
			_put(b, _latch(1700.0, 42), 0.0)
			_put(b, _latch(1550.0, 43), 0.16)
			_put(b, _creak(0.55, 70.0, 170.0, 24, [[600.0, 70.0], [1500.0, 120.0], [2900.0, 200.0]]), 0.32, 0.6)
			_put(b, _rummage(0.85, 53), 0.85, 0.8)
			return _done(b)
		"ammo_clink": return _done(_ammo_clink())
		"medkit_zip": return _done(_zip())
		"key_jingle": return _done(_keys())
		"glass_crack": return _done(_glass_crack())
		"glass_shatter": return _done(_glass_shatter())
		"glass_shards": return _done(_shards(1.45, 18, 81, 1.0))
		"glass_crunch": return _done(_glass_crunch())
		"ui_hover": return _done(_ui_hover(), 0.5)
		"ui_click": return _done(_ui_click(), 0.6)
		"ui_back": return _done(_ui_back(), 0.6)
		"ui_error": return _done(_ui_error(), 0.6)
		"objective_chime": return _done(_chime(), 0.6)
		"wave_horn": return _done(_wave_horn(), 0.85)
		"car_alarm": return _loop(_car_alarm(), 0.8)
		"hazard_tick": return _loop(_hazard(), 0.7, true)
		"horn_stuck": return _loop(_horn(), 0.7)
		"engine_tick": return _loop(_engine_tick(), 0.6, true)
		"generator": return _loop(_generator(), 0.8)
		"tube_buzz": return _loop(_tube(), 0.6)
		"sign_creak": return _loop(_sign(), 0.6, true)
	return PackedFloat32Array()


# --- Doors ------------------------------------------------------------------------------------

## A lever handle pressed down and let go: two clicks of the latch, the second lower, a spring under them.
static func _door_handle() -> PackedFloat32Array:
	var b := _blank(0.28)
	_put(b, _click(1700.0, 120.0, 1), 0.0)
	_put(b, _ring([[620.0, 90.0]], 0.05, 0.2), 0.002)
	_put(b, _click(1350.0, 120.0, 2), 0.12, 0.8)
	_put(b, _ring([[540.0, 90.0]], 0.05, 0.16), 0.122)
	return b


## A wooden door swung shut: the thump of the panel in the frame, the crack of the hit, the boards
## ringing, the latch catching, and a short rattle of the door settling.
static func _door_slam() -> PackedFloat32Array:
	var b := _blank(0.75)
	_put(b, Sfx.exp_tail(Sfx.sweep(0.55, 115.0, 52.0), 14.0), 0.0, 1.0)
	_put(b, Sfx.exp_tail(Sfx.high_pass(Sfx.noise(0.04, Sfx.Hiss.WHITE, 3), 700.0), 110.0), 0.0, 0.7)
	_put(b, _knock([[170.0, 40.0], [410.0, 55.0], [860.0, 90.0], [1520.0, 160.0]], 4), 0.0, 1.2)
	_put(b, _click(1900.0, 140.0, 5), 0.035, 0.45)
	for k in 3:
		_put(b, _knock([[240.0, 60.0], [650.0, 100.0]], 6 + k), 0.13 + k * 0.065, 0.35 / (k + 1))
	return b


## The handle shaken against a lock: clacks of the latch, the door knocking in its frame.
static func _locked_rattle() -> PackedFloat32Array:
	var b := _blank(0.65)
	var times := [0.0, 0.1, 0.2, 0.29, 0.41]
	for i in times.size():
		var t: float = times[i]
		_put(b, _click(1250.0 + 180.0 * (i % 2), 130.0, 10 + i), t, 0.9)
		_put(b, _knock([[150.0, 50.0], [380.0, 80.0]], 20 + i), t + 0.004, 0.55)
	return b


## Wood giving way under a blow: the thud, then fibres tearing (many tiny bright cracks).
static func _splinter(secs: float, seed_: int, weight: float) -> PackedFloat32Array:
	var b := _blank(secs)
	_put(b, Sfx.exp_tail(Sfx.sweep(0.4, 125.0, 60.0), 20.0), 0.0, weight)
	_put(b, _knock([[210.0, 50.0], [520.0, 80.0], [1100.0, 140.0]], seed_), 0.0, 0.9)
	_put(b, _crackle(secs - 0.05, 60, seed_ + 1, [1800.0, 3200.0, 5200.0], 0.4), 0.01, 0.8)
	return b


## The door gives: a heavy crash, a long tear of wood, then planks falling and clattering.
static func _door_break() -> PackedFloat32Array:
	var b := _blank(1.45)
	_put(b, Sfx.exp_tail(Sfx.sweep(0.9, 95.0, 38.0), 6.0), 0.0, 1.0)
	_put(b, Sfx.exp_tail(Sfx.low_pass(Sfx.noise(0.3, Sfx.Hiss.BROWN, 33), 700.0), 12.0), 0.0, 0.8)
	_put(b, _crackle(0.9, 140, 34, [1500.0, 2600.0, 4300.0], 0.6), 0.0, 1.0)
	var r := _rng(35)
	for k in 5:
		var t := 0.35 + k * 0.17 + r.randf_range(-0.04, 0.04)
		_put(b, _knock([[r.randf_range(220.0, 320.0), 60.0], [r.randf_range(600.0, 800.0), 100.0], [1500.0, 200.0]], 36 + k), t, 0.7 / (1.0 + k * 0.5))
	return b


# --- Barricades -------------------------------------------------------------------------------

## A hammer on a nail through a plank: the steel face rings, the board knocks under it.
static func _hammer_knock() -> PackedFloat32Array:
	var b := _blank(0.38)
	_put(b, _ring([[2900.0, 18.0], [4150.0, 26.0], [6100.0, 45.0]], 0.34, 2.2), 0.0)
	_put(b, _knock([[260.0, 45.0], [610.0, 70.0], [1300.0, 120.0]], 61), 0.0, 1.1)
	_put(b, Sfx.exp_tail(Sfx.high_pass(Sfx.noise(0.01, Sfx.Hiss.WHITE, 62), 2000.0), 300.0), 0.0, 0.6)
	return b


## A plank strained until it cracks: a creak rising, then a sharp crack.
static func _plank_crack() -> PackedFloat32Array:
	var b := _blank(0.65)
	_put(b, _creak(0.3, 90.0, 220.0, 63, [[420.0, 70.0], [1000.0, 110.0], [2100.0, 170.0]]), 0.0, 0.6)
	_put(b, _splinter(0.4, 64, 0.5), 0.24, 0.9)
	return b


## A plank snapping clean through: one very short, loud crack and a tail of splinters.
static func _plank_snap() -> PackedFloat32Array:
	var b := _blank(0.48)
	_put(b, Sfx.exp_tail(Sfx.high_pass(Sfx.noise(0.02, Sfx.Hiss.WHITE, 65), 500.0), 220.0), 0.0, 1.0)
	_put(b, _knock([[380.0, 60.0], [870.0, 90.0], [1750.0, 150.0]], 66), 0.0, 1.0)
	_put(b, _crackle(0.3, 30, 67, [2200.0, 3800.0], 0.5), 0.015, 0.5)
	return b


# --- Lootboxes and pickups --------------------------------------------------------------------

## A box's catch flipped: a click and its spring ringing, a little tick as it seats.
static func _latch(hz: float, seed_: int) -> PackedFloat32Array:
	var b := _blank(0.32)
	_put(b, _click(hz, 110.0, seed_), 0.0)
	_put(b, _ring([[hz * 1.45, 22.0]], 0.25, 0.3), 0.003)
	_put(b, _click(hz * 1.3, 180.0, seed_ + 1), 0.055, 0.4)
	return b


## Hands going through a box: rustles of cloth and card, things knocking together.
static func _rummage(secs: float, seed_: int) -> PackedFloat32Array:
	var b := _blank(secs)
	var r := _rng(seed_)
	for k in 7:
		var len_ := r.randf_range(0.06, 0.13)
		var burst := Sfx.envelope(Sfx.band_pass(Sfx.noise(len_, Sfx.Hiss.PINK, seed_ * 10 + k), 400.0, 3000.0), len_ * 0.3, len_ * 0.3, 0.5, len_ * 0.3)
		_put(b, burst, r.randf_range(0.0, secs - 0.15), r.randf_range(0.5, 1.0))
	for k in 4:
		_put(b, _knock([[r.randf_range(450.0, 700.0), 80.0], [r.randf_range(1000.0, 1400.0), 140.0]], seed_ * 10 + 20 + k), r.randf_range(0.03, secs - 0.15), 0.5)
	return b


## Rounds taken from a carton: the card shaken, cartridges clinking against each other.
static func _ammo_clink() -> PackedFloat32Array:
	var b := _blank(0.65)
	_put(b, Sfx.envelope(Sfx.band_pass(Sfx.noise(0.22, Sfx.Hiss.PINK, 71), 500.0, 2500.0), 0.03, 0.08, 0.5, 0.08), 0.0, 0.5)
	var r := _rng(72)
	var t := 0.03
	for k in 7: # one after another as they tip into the hand, a pair now and then
		var f := r.randf_range(3000.0, 5200.0)
		_put(b, _ring([[f, r.randf_range(40.0, 70.0)], [f * 1.53, 90.0]], 0.2, 0.6), t, r.randf_range(0.5, 1.0))
		t += r.randf_range(0.015, 0.03) if k % 3 == 1 else r.randf_range(0.045, 0.075)
	return b


## A zip pulled open: a run of teeth, slow to start, quick through the middle.
static func _zip() -> PackedFloat32Array:
	var b := _blank(0.55)
	var r := _rng(73)
	var t := 0.02
	var teeth := PackedFloat32Array()
	teeth.resize(b.size())
	while t < 0.47:
		var u := (t - 0.02) / 0.45
		var rate := lerpf(90.0, 230.0, sin(u * PI))
		var i := int(t * RATE)
		if i < teeth.size():
			teeth[i] = r.randf_range(0.6, 1.0)
		t += 1.0 / rate
	var tick := Sfx.mix([Sfx.resonate(teeth, 2600.0, 500.0), Sfx.resonate(teeth, 4300.0, 700.0), Sfx.resonate(teeth, 6500.0, 900.0)])
	_put(b, tick, 0.0, 1.0)
	var hiss := Sfx.envelope(Sfx.band_pass(Sfx.noise(0.45, Sfx.Hiss.WHITE, 74), 2500.0, 7000.0), 0.05, 0.1, 0.6, 0.1)
	_put(b, hiss, 0.02, 0.06)
	return b


## A bunch of keys: several thin steel rings, struck one after another as they swing.
static func _keys() -> PackedFloat32Array:
	var b := _blank(0.85)
	var r := _rng(75)
	var t := 0.0
	for k in 9:
		var f := r.randf_range(2300.0, 3900.0)
		_put(b, _ring([[f, r.randf_range(25.0, 45.0)], [f * 2.76, 60.0], [f * 1.41, 50.0]], 0.35, 0.7), t, r.randf_range(0.5, 1.0))
		_put(b, _click(f * 1.2, 300.0, 76 + k), t, 0.3)
		t += r.randf_range(0.03, 0.065)
	return b


# --- Glass ------------------------------------------------------------------------------------

## A bullet star in a pane: one sharp tick, the crack running out as a quick crackle, a faint ring.
static func _glass_crack() -> PackedFloat32Array:
	var b := _blank(0.42)
	_put(b, Sfx.exp_tail(Sfx.high_pass(Sfx.noise(0.008, Sfx.Hiss.WHITE, 81), 3000.0), 500.0), 0.0, 1.0)
	_put(b, _crackle(0.13, 26, 82, [4200.0, 6000.0, 8200.0], 0.3), 0.003, 0.8)
	_put(b, _ring([[5300.0, 25.0], [7400.0, 40.0]], 0.35, 0.25), 0.0)
	return b


## A pane breaking: a burst, a shower of bright shards ringing over each other, a low knock of the frame.
static func _glass_shatter() -> PackedFloat32Array:
	var b := _blank(1.25)
	_put(b, Sfx.exp_tail(Sfx.high_pass(Sfx.noise(0.25, Sfx.Hiss.WHITE, 83), 1500.0), 28.0), 0.0, 1.0)
	_put(b, Sfx.exp_tail(Sfx.sweep(0.2, 140.0, 70.0), 30.0), 0.0, 0.4)
	_put(b, _shards(1.2, 40, 84, 3.0), 0.0, 1.0)
	_put(b, _crackle(0.55, 220, 86, [3500.0, 5500.0, 8000.0], 0.35), 0.01, 0.7) # the fine debris
	return b


## Shards falling and tinkling: sparse bright rings, fewer as time goes on (`early`: how bunched at the start).
static func _shards(secs: float, count: int, seed_: int, early: float) -> PackedFloat32Array:
	var b := _blank(secs)
	var r := _rng(seed_)
	for k in count:
		var t := pow(r.randf(), early) * (secs - 0.25)
		var f := r.randf_range(3000.0, 8500.0)
		_put(b, _ring([[f, r.randf_range(25.0, 60.0)], [f * 1.62, 80.0]], 0.22, 0.6), t, r.randf_range(0.3, 1.0) * (1.0 - t / secs * 0.6))
	return b


## A boot on broken glass: a soft thud and a dense, gritty crackle.
static func _glass_crunch() -> PackedFloat32Array:
	var b := _blank(0.32)
	_put(b, Sfx.exp_tail(Sfx.sweep(0.15, 120.0, 70.0), 40.0), 0.0, 0.6)
	_put(b, _crackle(0.14, 50, 85, [2200.0, 3600.0, 5600.0], 0.6), 0.0, 1.0)
	return b


# --- The interface ----------------------------------------------------------------------------

static func _ui_hover() -> PackedFloat32Array:
	var b := _blank(0.05)
	_put(b, Sfx.exp_tail(Sfx.tone(0.04, 2400.0), 140.0), 0.0)
	return b


static func _ui_click() -> PackedFloat32Array:
	var b := _blank(0.09)
	_put(b, Sfx.exp_tail(Sfx.tone(0.03, 1800.0), 120.0), 0.0)
	_put(b, Sfx.exp_tail(Sfx.tone(0.05, 1200.0), 90.0), 0.014, 0.8)
	return b


static func _ui_back() -> PackedFloat32Array:
	var b := _blank(0.17)
	_put(b, Sfx.envelope(Sfx.low_pass(Sfx.sweep(0.06, 1250.0, 850.0, Sfx.Wave.SQUARE), 3000.0), 0.003, 0.02, 0.6, 0.02), 0.0, 0.6)
	_put(b, Sfx.envelope(Sfx.low_pass(Sfx.tone(0.07, 700.0, Sfx.Wave.SQUARE), 2500.0), 0.003, 0.02, 0.6, 0.03), 0.07, 0.6)
	return b


## Not allowed: two short low buzzes.
static func _ui_error() -> PackedFloat32Array:
	var b := _blank(0.3)
	for k in 2:
		_put(b, Sfx.envelope(Sfx.low_pass(Sfx.tone(0.09, 175.0, Sfx.Wave.SQUARE), 1600.0), 0.004, 0.02, 0.8, 0.02), k * 0.14, 0.7)
	return b


## A new objective: three bell notes rising.
static func _chime() -> PackedFloat32Array:
	var b := _blank(1.45)
	var notes := [659.0, 784.0, 1047.0]
	for k in notes.size():
		var f: float = notes[k]
		_put(b, Sfx.exp_tail(Sfx.fm(1.1, f, f * 1.4, 1.1), 4.5), k * 0.16, 0.6)
		_put(b, Sfx.exp_tail(Sfx.tone(1.1, f * 2.0), 6.0), k * 0.16, 0.2)
	return b


## Here they come: a long low horn, a fifth over its root, wavering as it swells.
static func _wave_horn() -> PackedFloat32Array:
	var secs := 2.3
	var b := _blank(secs)
	var ph1 := 0.0
	var ph2 := 0.0
	for i in b.size():
		var t := float(i) / RATE
		var vib := 1.0 + sin(t * TAU * 5.0) * 0.006 + minf(t, 0.3) * 0.02 # a scoop up into the note
		ph1 += 98.0 * vib / RATE
		ph2 += 147.0 * vib / RATE
		b[i] = (2.0 * fposmod(ph1, 1.0) - 1.0) * 0.6 + (2.0 * fposmod(ph2, 1.0) - 1.0) * 0.4
	b = Sfx.low_pass(Sfx.low_pass(b, 900.0), 1200.0)
	b = Sfx.envelope(b, 0.35, 0.2, 0.85, 0.6)
	return Sfx.soft_clip(b, 1.3)


# --- Vehicles (loops) ---------------------------------------------------------------------------

## A car alarm: four whoops sweeping up, then a fast warble between two notes.
static func _car_alarm() -> PackedFloat32Array:
	var secs: float = LOOPS.car_alarm + SEAM
	var b := _blank(secs)
	var ph := 0.0
	for i in b.size():
		var t := fmod(float(i) / RATE, LOOPS.car_alarm)
		var f := 0.0
		if t < 1.6:
			f = lerpf(600.0, 1600.0, fmod(t, 0.4) / 0.4)
		else:
			f = 900.0 if int(t / 0.1) % 2 == 0 else 1300.0
		ph += f / RATE
		b[i] = 1.0 if fposmod(ph, 1.0) < 0.5 else -1.0
	return Sfx.soft_clip(Sfx.band_pass(b, 400.0, 4000.0), 1.5)


## Hazard lights: the relay's tick when they come on, its tock when they go off.
static func _hazard() -> PackedFloat32Array:
	var b := _blank(LOOPS.hazard_tick + SEAM)
	var n := roundi(LOOPS.hazard_tick / HAZARD_PERIOD)
	for k in n:
		_put(b, _click(1900.0, 160.0, 91), k * HAZARD_PERIOD, 1.0)
		_put(b, _ring([[700.0, 60.0]], 0.05, 0.3), k * HAZARD_PERIOD)
		_put(b, _click(1450.0, 160.0, 92), k * HAZARD_PERIOD + HAZARD_PERIOD / 2.0, 0.8)
		_put(b, _ring([[560.0, 60.0]], 0.05, 0.25), k * HAZARD_PERIOD + HAZARD_PERIOD / 2.0)
	return b


## A horn stuck on: two square notes a third apart, nasal, with a slight wobble of a tired battery.
static func _horn() -> PackedFloat32Array:
	var b := _blank(LOOPS.horn_stuck + SEAM)
	for i in b.size():
		var t := float(i) / RATE
		var a := 1.0 if fposmod(t * 420.0, 1.0) < 0.5 else -1.0
		var c := 1.0 if fposmod(t * 525.0, 1.0) < 0.5 else -1.0
		b[i] = (a * 0.5 + c * 0.5) * (0.9 + 0.1 * sin(t * TAU * 3.0))
	return Sfx.soft_clip(Sfx.band_pass(b, 300.0, 3000.0), 1.4)


## A hot engine cooling: metal ticking now and then, never in step.
static func _engine_tick() -> PackedFloat32Array:
	var b := _blank(LOOPS.engine_tick + SEAM)
	var r := _rng(93)
	for k in 14:
		var t := r.randf_range(0.02, LOOPS.engine_tick - 0.1)
		var f := r.randf_range(2400.0, 5200.0)
		_put(b, _ring([[f, r.randf_range(60.0, 120.0)]], 0.06, 1.0), t, r.randf_range(0.4, 1.0))
		_put(b, _click(f * 0.6, 260.0, 94 + k), t, 0.4)
	return b


# --- Hums (loops) -------------------------------------------------------------------------------

## A diesel generator: twenty-five firings a second, each a low thump with a puff of exhaust noise.
static func _generator() -> PackedFloat32Array:
	var secs: float = LOOPS.generator + SEAM
	var b := _blank(secs)
	var hit := Sfx.exp_tail(Sfx.tone(0.04, 52.0), 60.0)
	var puff := Sfx.exp_tail(Sfx.low_pass(Sfx.noise(0.03, Sfx.Hiss.BROWN, 95), 350.0), 90.0)
	var r := _rng(96)
	var n := roundi(secs * 25.0)
	for k in n:
		_put(b, hit, k / 25.0, 0.8 + r.randf() * 0.15 + (0.2 if k % 2 == 0 else 0.0)) # two cylinders, one stronger
		_put(b, puff, k / 25.0, 0.5)
	_put(b, Sfx.gain(Sfx.tone(secs, 150.0), 0.08), 0.0) # the alternator's whine under it
	return Sfx.low_pass(b, 700.0)


## A tube light's buzz: mains hum (100 Hz and its harmonics, edgy), and now and then a crackle of the starter.
static func _tube() -> PackedFloat32Array:
	var secs: float = LOOPS.tube_buzz + SEAM
	var b := _blank(secs)
	for i in b.size():
		var t := float(i) / RATE
		var s := absf(sin(t * TAU * 50.0)) * 2.0 - 1.27 # rectified mains: 100 Hz, every harmonic even
		b[i] = s * 0.6 + sin(t * TAU * 100.0) * 0.4
	b = Sfx.band_pass(b, 90.0, 3000.0)
	var r := _rng(97)
	for k in 3:
		_put(b, _crackle(0.05, 12, 98 + k, [3000.0, 5000.0], 0.25), r.randf_range(0.1, LOOPS.tube_buzz - 0.2), 0.25)
	return b


## A sign swinging on its bracket: one creak each way, the second lower, quiet in between.
static func _sign() -> PackedFloat32Array:
	var b := _blank(LOOPS.sign_creak + SEAM)
	var formants := [[380.0, 50.0], [900.0, 80.0], [1900.0, 140.0]]
	_put(b, _creak(0.75, 45.0, 105.0, 99, formants), 0.15, 1.0)
	_put(b, _creak(0.75, 38.0, 90.0, 100, formants), 1.75, 0.85)
	return b


# --- Pieces ---------------------------------------------------------------------------------------

## A small metal click: a bright FM blip and a tick of noise, gone in a few milliseconds.
static func _click(hz: float, rate: float, seed_: int) -> PackedFloat32Array:
	var ring := Sfx.exp_tail(Sfx.fm(0.04, hz, hz * 1.37, 1.6), rate)
	var tick := Sfx.exp_tail(Sfx.high_pass(Sfx.noise(0.012, Sfx.Hiss.WHITE, seed_), 2500.0), 400.0)
	return Sfx.mix([ring, tick], [0.7, 0.6])


## Struck metal: sine partials [[hz, decay rate]] summed.
static func _ring(partials: Array, secs: float, gain: float) -> PackedFloat32Array:
	var layers := []
	for p: Array in partials:
		layers.append(Sfx.exp_tail(Sfx.tone(secs, p[0]), p[1]))
	return Sfx.gain(Sfx.mix(layers), gain / partials.size())


## Struck wood: one impulse through wide resonances [[hz, width]].
static func _knock(modes: Array, seed_: int) -> PackedFloat32Array:
	var imp := Sfx.exp_tail(Sfx.noise(0.012, Sfx.Hiss.WHITE, seed_), 500.0)
	imp.resize(int(0.25 * RATE))
	var layers := []
	for m: Array in modes:
		layers.append(Sfx.resonate(imp, m[0], m[1]))
	return Sfx.gain(Sfx.mix(layers), 4.0)


## Many tiny cracks over `secs`, bunched at the start (`spread` < 1 bunches more), each through high
## resonances: splintering wood, glass cracking, grit underfoot.
static func _crackle(secs: float, count: int, seed_: int, bands: Array, spread: float) -> PackedFloat32Array:
	var imp := _blank(secs)
	var r := _rng(seed_)
	for k in count:
		var i := int(pow(r.randf(), 1.0 / maxf(spread, 0.05) * 0.5) * (imp.size() - 1))
		imp[i] += r.randf_range(-1.0, 1.0)
	var layers := []
	for f: float in bands:
		layers.append(Sfx.resonate(imp, f * r.randf_range(0.9, 1.1), f * 0.25))
	var out := Sfx.mix(layers)
	for i in out.size():
		out[i] *= 1.0 - float(i) / out.size()
	return Sfx.gain(out, 3.0)


## A creak: stick-slip, a train of tiny impulses whose rate arcs from `f0` up to `f1` and back,
## rung through formants [[hz, width]] (low and wide: wood; higher and narrow: metal hinges). Swells and fades.
static func _creak(secs: float, f0: float, f1: float, seed_: int, formants: Array) -> PackedFloat32Array:
	var imp := _blank(secs)
	var r := _rng(seed_)
	var t := 0.0
	while t < secs:
		var u := t / secs
		# the rate wanders slowly (stick-slip catching and letting go), not sample to sample, so the
		# creak has a pitch you can follow; each slip's strength varies a little
		var wander := sin(u * TAU * 1.7 + float(seed_)) * 0.06
		var f := lerpf(f0, f1, sin(u * PI)) * (1.0 + wander) * r.randf_range(0.985, 1.015)
		var i := int(t * RATE)
		if i < imp.size():
			imp[i] = r.randf_range(0.8, 1.0) * sin(u * PI)
		t += 1.0 / maxf(f, 1.0)
	var layers := []
	for fm: Array in formants:
		layers.append(Sfx.resonate(imp, fm[0], fm[1]))
	var out := Sfx.mix(layers)
	for i in out.size():
		out[i] *= pow(sin(float(i) / out.size() * PI), 0.7)
	return out


static func _blank(secs: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(secs * RATE))
	return b


static func _rng(seed_: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_
	return r


## Add `src` into `into` at `at` seconds, times `g`.
static func _put(into: PackedFloat32Array, src: PackedFloat32Array, at: float, g := 1.0) -> void:
	var o := int(at * RATE)
	var n := mini(src.size(), into.size() - o)
	for i in n:
		into[o + i] += src[i] * g


## A one-shot finished: no DC, scaled so its loudest is `peak`, a 1 ms fade in and 15 ms out.
static func _done(b: PackedFloat32Array, peak := 0.8) -> PackedFloat32Array:
	b = Sfx.high_pass(b, 25.0)
	_normalise(b, peak)
	var fin := mini(int(0.001 * RATE), b.size())
	for i in fin:
		b[i] *= float(i) / fin
	var fout := mini(int(0.015 * RATE), b.size())
	for i in fout:
		b[b.size() - 1 - i] *= float(i) / fout
	return b


## A loop finished: built SEAM longer than its loop. A steady sound (`events` false) has the extra
## faded over its start, so the end runs straight into the beginning; a loop of separate events
## (ticks, creaks) has the tails that run past its end wrapped round onto its start, so nothing at
## the start is lost. Scaled to `peak`.
static func _loop(b: PackedFloat32Array, peak: float, events := false) -> PackedFloat32Array:
	var seam := int(SEAM * RATE)
	var n := b.size() - seam
	var out := b.slice(0, n)
	for i in seam:
		if events:
			out[i] += b[n + i]
		else:
			var w := float(i) / seam
			out[i] = b[i] * w + b[n + i] * (1.0 - w)
	_normalise(out, peak)
	return out


static func _normalise(b: PackedFloat32Array, peak: float) -> void:
	var p := 0.0
	for v in b:
		p = maxf(p, absf(v))
	if p > 0.0:
		var k := peak / p
		for i in b.size():
			b[i] *= k
