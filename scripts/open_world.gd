class_name OpenWorld
extends Node
## The open world mode (GameModes "open_world"): no objective, the clock runs through day, dusk,
## night and dawn (Config.OPEN_PHASES), each with its sky. Every peer counts the same clock (the host's
## goes in `welcome` as `open_clock`) and turns its own sky; the host alone sends the zombies: none by
## day, a horde now and then by night, and every Config.OPEN_HORDE_NIGHT-th night a horde night,
## waves one after another and bigger every time it comes round. Shown top centre on every peer.

var game: Game
var clock := 0.0          ## seconds since the first morning
var phase := -1           ## index into Config.OPEN_PHASES
var day := 1
var _horde_t := 0.0
var _label: Label


func _init(owner_game: Game, start_clock := 0.0) -> void:
	name = "OpenWorld"
	game = owner_game
	clock = start_clock


func _ready() -> void:
	var ui := CanvasLayer.new()
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_label.offset_top = 104
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 18)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 5)
	ui.add_child(_label)
	add_child(ui)
	step(0.0)


func _process(delta: float) -> void:
	step(delta)


static func cycle() -> float:
	var total := 0.0
	for p: Array in Config.OPEN_PHASES:
		total += float(p[2])
	return total


## Which phase `t` seconds in is, and the seconds left of it: [day, phase index, left].
static func at(t: float) -> Array:
	var c := cycle()
	var d := int(floor(t / c)) + 1
	var into := fmod(t, c)
	for i in Config.OPEN_PHASES.size():
		var len: float = Config.OPEN_PHASES[i][2]
		if into < len:
			return [d, i, len - into]
		into -= len
	return [d, 0, 0.0]


static func is_horde_night(d: int) -> bool:
	return d % Config.OPEN_HORDE_NIGHT == 0


func night() -> bool:
	return Config.OPEN_PHASES[phase][0] == "night"


func step(delta: float) -> void:
	clock += delta
	var now := at(clock)
	if now[1] != phase or now[0] != day:
		day = now[0]
		phase = now[1]
		_phase_began()
	if game.is_host and night():
		_horde_t -= delta
		if _horde_t <= 0.0:
			var horde := is_horde_night(day)
			_horde_t = Config.OPEN_HORDE_EVERY if horde else Config.OPEN_NIGHT_HORDE_EVERY
			var size := Config.OPEN_HORDE_SIZE * (day / Config.OPEN_HORDE_NIGHT) if horde else Config.OPEN_NIGHT_HORDE_SIZE + day
			game.director.spawn_horde(roundi(size * game.mult("horde")))
	if _label:
		_label.text = text(now)
		_label.add_theme_color_override("font_color", Color("ff5a4a") if night() and is_horde_night(day) else Color("f2ece0"))


func _phase_began() -> void:
	var sky: String = Config.OPEN_PHASES[phase][1]
	if game.sky_dome:
		game.sky_dome.apply(sky)
	game.sky = sky
	if game.is_host:
		game.director.enabled = night() # by day the town is quiet; the night brings them
		_horde_t = 5.0


## "DAY 3 · NIGHT · 2:41 to dawn", "HORDE NIGHT" on the seventh.
func text(now: Array) -> String:
	var name: String = Config.OPEN_PHASES[now[1]][0]
	var next: String = Config.OPEN_PHASES[(int(now[1]) + 1) % Config.OPEN_PHASES.size()][0]
	var left := int(ceil(float(now[2])))
	var head := "DAY %d · %s" % [now[0], name.to_upper()]
	if name == "night" and is_horde_night(now[0]):
		head = "DAY %d · HORDE NIGHT" % now[0]
	elif name != "night" and is_horde_night(now[0]):
		head += " · horde tonight"
	return "%s · %d:%02d to %s" % [head, left / 60, left % 60, next]
