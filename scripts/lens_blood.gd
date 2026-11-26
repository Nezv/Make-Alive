class_name LensBlood
extends Control
## Blood on the lens after a close kill: a few drops that run down and fade over `Config.LENS_BLOOD_TIME`.

var drops: Array[Dictionary] = [] ## { pos, r, age, speed }
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 23


func splash() -> void:
	var s := size if size.x > 0.0 else Vector2(1600, 900)
	for i in _rng.randi_range(3, 6):
		drops.append({ "pos": Vector2(_rng.randf_range(0.15, 0.85) * s.x, _rng.randf_range(0.1, 0.6) * s.y),
			"r": _rng.randf_range(8.0, 22.0), "age": 0.0, "speed": _rng.randf_range(10.0, 40.0) })
	queue_redraw()


func step(delta: float) -> void:
	for d in drops:
		d.age = float(d.age) + delta
		d.pos = (d.pos as Vector2) + Vector2(0.0, float(d.speed) * delta)
	drops = drops.filter(func(d: Dictionary) -> bool: return float(d.age) < Config.LENS_BLOOD_TIME)
	queue_redraw()


func _process(delta: float) -> void:
	if not drops.is_empty():
		step(delta)


func _draw() -> void:
	for d: Dictionary in drops:
		var a := 0.7 * (1.0 - float(d.age) / Config.LENS_BLOOD_TIME)
		var col := Color(0.45, 0.02, 0.02, a)
		var p: Vector2 = d.pos
		var r: float = d.r
		draw_circle(p, r, col)
		draw_rect(Rect2(p + Vector2(-r * 0.25, 0), Vector2(r * 0.5, float(d.age) * float(d.speed))), col) # the run below it
