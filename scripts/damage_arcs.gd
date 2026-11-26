class_name DamageArcs
extends Control
## A red arc round the middle of the screen on the side a hit came from (0 = ahead, clockwise),
## fading over `Config.DAMAGE_ARC_TIME`.

var _arcs: Array[Dictionary] = [] ## { angle, left }


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func add(angle: float) -> void:
	_arcs.append({ "angle": angle, "left": Config.DAMAGE_ARC_TIME })
	while _arcs.size() > 6:
		_arcs.pop_front()
	queue_redraw()


func count() -> int:
	return _arcs.size()


func angle_of(i: int) -> float:
	return _arcs[i].angle


func step(delta: float) -> void:
	for a in _arcs:
		a.left = float(a.left) - delta
	_arcs = _arcs.filter(func(a: Dictionary) -> bool: return float(a.left) > 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not _arcs.is_empty():
		step(delta)


func _draw() -> void:
	var c := size / 2.0
	var r := minf(size.x, size.y) * 0.28
	for a: Dictionary in _arcs:
		var mid: float = float(a.angle) - PI / 2.0 # screen angles start at the right; ahead is up
		var alpha := clampf(float(a.left) / Config.DAMAGE_ARC_TIME, 0.0, 1.0)
		draw_arc(c, r, mid - 0.45, mid + 0.45, 16, Color(0.9, 0.08, 0.05, 0.85 * alpha), 10.0, true)
