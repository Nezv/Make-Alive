class_name ObjectiveText
extends Control
## Top centre: the objective, typed in a letter at a time; when it changes, the old one is struck
## through and slides up and away. A `suffix` (its clock, a wave count) shows at once, untyped.

var text := ""
var suffix := ""
var leaving := ""
var color := Color.WHITE
var _type_t := 0.0
var _leave_t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-500, 18)
	size = Vector2(1000, 40)


func show_text(t: String, suffix_ := "") -> void:
	suffix = suffix_
	if t == text:
		return
	if text != "":
		leaving = text
		_leave_t = 0.0
	text = t
	_type_t = 0.0


func visible_chars() -> int:
	return mini(text.length(), int(_type_t * Config.HUD_TYPE_RATE))


## How far the struck-out one has slid up (pixels).
func leaving_offset() -> float:
	return Config.HUD_OBJECTIVE_SLIDE * clampf(_leave_t / Config.HUD_OBJECTIVE_OUT, 0.0, 1.0) if leaving != "" else 0.0


func step(delta: float) -> void:
	_type_t += delta
	if leaving != "":
		_leave_t += delta
		if _leave_t >= Config.HUD_OBJECTIVE_OUT:
			leaving = ""
	queue_redraw()


func _process(delta: float) -> void:
	step(delta)


func _draw() -> void:
	var w := size.x
	if leaving != "":
		var u := clampf(_leave_t / Config.HUD_OBJECTIVE_OUT, 0.0, 1.0)
		var y := 26.0 - leaving_offset()
		var col := Color(color, 1.0 - u)
		HudParts.text(self, Vector2(0, y), leaving, 22, col, HORIZONTAL_ALIGNMENT_CENTER, w)
		var lw := HudParts.text_width(leaving, 22)
		draw_rect(Rect2(Vector2((w - lw) / 2.0, y - 8), Vector2(lw, 2)), col) # struck through
	if text == "":
		return
	var shown := text.left(visible_chars())
	var line := shown + (suffix if visible_chars() >= text.length() else "")
	HudParts.text(self, Vector2(0, 26 + (12.0 if leaving != "" else 0.0) * (1.0 - clampf(_leave_t / Config.HUD_OBJECTIVE_OUT, 0.0, 1.0))), line, 22, color, HORIZONTAL_ALIGNMENT_CENTER, w)
