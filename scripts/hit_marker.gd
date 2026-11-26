class_name HitMarker
extends Control
## Four ticks round the crosshair when your shot lands: they snap in from wide and ease out; red and
## bigger for a kill, with a skull over them for a headshot; a second ring of ticks for a limb off.

enum Kind { HIT, KILL, HEADSHOT }

var kind := Kind.HIT
var skull := false
var sever_tick := 0.0  ## 1 when a limb came off, running down
var _t := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func show_hit(k: int) -> void:
	kind = k
	skull = k == Kind.HEADSHOT
	_t = 0.0
	visible = true
	queue_redraw()


func show_sever() -> void:
	sever_tick = 1.0
	visible = true


## How far out the ticks are (1 = their rest): wide the instant it lands, snapping in.
func spread() -> float:
	return 1.0 + 0.6 * exp(-_t * 60.0)


func tick_size() -> float:
	return Config.HIT_MARKER_SIZE * (1.5 if kind != Kind.HIT else 1.0)


func color() -> Color:
	return Color(1.0, 0.18, 0.15) if kind != Kind.HIT else Color(1, 1, 1)


func step(delta: float) -> void:
	_t += delta
	sever_tick = maxf(0.0, sever_tick - delta / Config.HIT_MARKER_TIME)
	if _t >= Config.HIT_MARKER_TIME and sever_tick <= 0.0:
		visible = false
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		step(delta)


func _draw() -> void:
	var c := size / 2.0
	var a := clampf(1.0 - (_t - Config.HIT_MARKER_TIME * 0.4) / (Config.HIT_MARKER_TIME * 0.6), 0.0, 1.0)
	var col := Color(color(), a)
	var gap := 9.0 * spread()
	var len := tick_size()
	for k in 4:
		var d := Vector2.from_angle(PI / 4.0 + k * PI / 2.0)
		draw_line(c + d * gap, c + d * (gap + len), col, 2.5, true)
	if sever_tick > 0.0: # a limb off: a second ring, further out
		var sc := Color(1.0, 0.45, 0.35, sever_tick)
		for k in 4:
			var d := Vector2.from_angle(k * PI / 2.0)
			draw_line(c + d * (gap + len + 6.0), c + d * (gap + len + 12.0), sc, 2.0, true)
	if skull and a > 0.0:
		HudParts.text(self, c + Vector2(-20, -gap - len - 6.0), "☠", 20, col, HORIZONTAL_ALIGNMENT_CENTER, 40)
