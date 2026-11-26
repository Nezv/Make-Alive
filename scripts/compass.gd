class_name Compass
extends Control
## Top centre: a strip of bearings that slides as you turn (N, NE, E ... and a tick every 15°), with
## the objective and teammates marked on it. Bearings are radians clockwise from north (-Z).

const WIDTH := 600.0
const HALF_VIEW := deg_to_rad(80.0) ## how far either side of straight ahead the strip shows
const NAMES := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]

var heading := 0.0
var ticks: Array = [] ## { bearing, kind: "objective" | "mate" }


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-WIDTH / 2.0, 64)
	size = Vector2(WIDTH, 34)


## Where bearing `b` sits on a strip `w` wide when looking along `view` (NAN: off the strip).
static func bearing_x(view: float, b: float, w: float) -> float:
	var rel := wrapf(b - view, -PI, PI)
	if absf(rel) > HALF_VIEW:
		return NAN
	return w / 2.0 + rel / HALF_VIEW * w / 2.0


## The bearing of a flat direction (north is -Z, east +X).
static func bearing_of(dir: Vector3) -> float:
	return atan2(dir.x, -dir.z)


static func label(b: float) -> String:
	return NAMES[posmod(roundi(b / (PI / 4.0)), 8)]


func set_view(heading_: float, ticks_: Array) -> void:
	heading = heading_
	ticks = ticks_
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2(0, 10), Vector2(WIDTH, 1)), HudParts.DIM)
	for k in 24: # every 15 degrees
		var b := k * PI / 12.0
		var x := bearing_x(heading, b, WIDTH)
		if is_nan(x):
			continue
		var major := k % 3 == 0
		draw_rect(Rect2(Vector2(x - 1, 4), Vector2(2, 12 if major else 6)), HudParts.INK if major else HudParts.DIM)
		if major:
			HudParts.text(self, Vector2(x - 20, 32), label(b), 14, HudParts.INK, HORIZONTAL_ALIGNMENT_CENTER, 40)
	for t: Dictionary in ticks:
		var x := bearing_x(heading, t.bearing, WIDTH)
		if is_nan(x):
			continue
		if t.kind == "objective":
			HudParts.diamond(self, Vector2(x, 10), 6.0, HudParts.OBJECTIVE)
		else:
			draw_circle(Vector2(x, 10), 4.0, HudParts.MATE)
	draw_rect(Rect2(Vector2(WIDTH / 2.0 - 1, 0), Vector2(2, 20)), HudParts.WARN)
