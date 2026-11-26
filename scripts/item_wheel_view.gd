class_name ItemWheelView
extends Control
## Draws the item wheel while its key is held: eight wedges round the middle of the screen, each with
## its item's icon (`ItemIcons`, flat boxes) and how many; the wedge under the pointer is lit and its
## icon hops up a little and grows.

const INNER := 58.0
const OUTER := 190.0
const GAP := 0.04          ## radians left between wedges
const FILL := Color(0.05, 0.06, 0.07, 0.62)
const LIT := Color(0.32, 0.5, 0.36, 0.85)
const EMPTY_INK := Color(1, 1, 1, 0.28)
const INK := Color(1, 1, 1, 0.95)
const ARC_STEPS := 8
const ICON := 26.0         ## half the icon's size in pixels

var wheel: ItemWheel
var _hop := PackedFloat32Array() ## per wedge, 0 resting .. 1 up


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	_hop.resize(Config.WHEEL_WEDGES)


func _process(dt: float) -> void:
	if visible:
		step(dt)
		queue_redraw()


## Eases every wedge's hop toward up (the lit one, if it holds something) or down.
func step(dt: float) -> void:
	var lit := -1
	if wheel != null and wheel.open:
		lit = wheel.selected()
		if lit >= 0 and lit < wheel.entries.size() and int(wheel.entries[lit].count) <= 0:
			lit = -1
	var rate := dt / Config.WHEEL_HOP_TIME
	for i in _hop.size():
		_hop[i] = move_toward(_hop[i], 1.0 if i == lit else 0.0, rate)


func hop_of(i: int) -> float:
	return _hop[i]


func icon_scale(i: int) -> float:
	return 1.0 + Config.WHEEL_HOP_SCALE * _ease(_hop[i])


static func _ease(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


func _draw() -> void:
	if wheel == null or not wheel.open:
		return
	var c := size / 2.0
	var step_a := TAU / Config.WHEEL_WEDGES
	var picked := wheel.selected()
	var font := ThemeDB.fallback_font
	for i in wheel.entries.size():
		var entry: Dictionary = wheel.entries[i]
		var a0 := i * step_a - step_a / 2.0 + GAP
		var a1 := i * step_a + step_a / 2.0 - GAP
		var poly := PackedVector2Array()
		for s in ARC_STEPS + 1:
			poly.append(c + _dir(lerpf(a0, a1, float(s) / ARC_STEPS)) * OUTER)
		for s in ARC_STEPS + 1:
			poly.append(c + _dir(lerpf(a1, a0, float(s) / ARC_STEPS)) * INNER)
		draw_colored_polygon(poly, LIT if i == picked and entry.count > 0 else FILL)
		if entry.item == &"":
			continue
		var have: int = entry.count
		var out := _dir(i * step_a)
		var at := c + out * ((INNER + OUTER) / 2.0 + sin(_hop[i] * PI) * Config.WHEEL_HOP_LIFT)
		_draw_icon(entry.item, at + Vector2(0, -8), ICON * icon_scale(i), 1.0 if have > 0 else 0.3)
		draw_string(font, at + Vector2(-60, ICON + 12), "×%d" % have, HORIZONTAL_ALIGNMENT_CENTER, 120, 14,
			INK if have > 0 else EMPTY_INK)
		if i == picked and have > 0:
			draw_string(font, c + Vector2(-80, 5), Inventory.item_name(entry.item), HORIZONTAL_ALIGNMENT_CENTER, 160, 15, INK)
	draw_circle(c + wheel.offset, 6.0, INK)


func _draw_icon(item: StringName, at: Vector2, half: float, alpha: float) -> void:
	for b: Array in ItemIcons.boxes(item):
		var r: Rect2 = b[0]
		var col: Color = b[1]
		col.a *= alpha
		draw_rect(Rect2(at + r.position * half, r.size * half), col)


## The direction wedge `angle` (radians clockwise from straight up) points in on the screen.
static func _dir(angle: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle))
