class_name VitalsBar
extends Control
## Bottom left: a health bar (green to red), temporary HP after it in pale yellow, a red mark for each
## open wound.

const SIZE := Vector2(220, 12)

var hp := 100
var temp := 0
var bleed := 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	position = Vector2(120, -52) # beside the heart and its number
	size = SIZE + Vector2(0, 14)


func set_vitals(hp_: int, temp_: int, bleed_: int) -> bool:
	var changed := hp_ != hp or temp_ != temp or bleed_ != bleed
	hp = hp_
	temp = temp_
	bleed = bleed_
	if changed:
		queue_redraw()
	return changed


func health_share() -> float:
	return clampf(float(hp) / Config.PLAYER_HP, 0.0, 1.0)


func temp_share() -> float:
	return clampf(float(temp) / Config.PLAYER_HP, 0.0, 1.0)


func bleed_marks() -> int:
	return bleed


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0, 0, 0, 0.5))
	var h := health_share()
	var col := HudParts.GOOD.lerp(HudParts.BAD, clampf(1.0 - h * 1.6, 0.0, 1.0))
	draw_rect(Rect2(Vector2(1, 1), Vector2((SIZE.x - 2) * h, SIZE.y - 2)), col)
	var t := minf(temp_share(), 1.0 - h)
	if t > 0.0:
		draw_rect(Rect2(Vector2(1 + (SIZE.x - 2) * h, 1), Vector2((SIZE.x - 2) * t, SIZE.y - 2)), Color(1.0, 0.95, 0.6, 0.8))
	for i in bleed: # a drop for each wound under the bar
		var c := Vector2(6 + i * 14, SIZE.y + 8)
		draw_circle(c, 4.0, HudParts.BAD)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -1), c + Vector2(3, -1), c + Vector2(0, -8)]), HudParts.BAD)
