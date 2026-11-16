class_name ItemWheelView
extends Control
## Draws the item wheel while its key is held: eight wedges round the middle of the screen with the
## item and how many, the wedge under the pointer lit. Names for now; icons drawn from boxes are S014's
## last feature.

const INNER := 58.0
const OUTER := 190.0
const GAP := 0.04          ## radians left between wedges
const FILL := Color(0.05, 0.06, 0.07, 0.62)
const LIT := Color(0.32, 0.5, 0.36, 0.85)
const EMPTY_INK := Color(1, 1, 1, 0.28)
const INK := Color(1, 1, 1, 0.95)
const ARC_STEPS := 8

var wheel: ItemWheel


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func _draw() -> void:
	if wheel == null or not wheel.open:
		return
	var c := size / 2.0
	var step := TAU / Config.WHEEL_WEDGES
	var picked := wheel.selected()
	var font := ThemeDB.fallback_font
	for i in wheel.entries.size():
		var entry: Dictionary = wheel.entries[i]
		var a0 := i * step - step / 2.0 + GAP
		var a1 := i * step + step / 2.0 - GAP
		var poly := PackedVector2Array()
		for s in ARC_STEPS + 1:
			poly.append(c + _dir(lerpf(a0, a1, float(s) / ARC_STEPS)) * OUTER)
		for s in ARC_STEPS + 1:
			poly.append(c + _dir(lerpf(a1, a0, float(s) / ARC_STEPS)) * INNER)
		draw_colored_polygon(poly, LIT if i == picked and entry.count > 0 else FILL)
		if entry.item == &"":
			continue
		var have: int = entry.count
		var label := "%s\n×%d" % [Inventory.item_name(entry.item), have]
		var at := c + _dir(i * step) * (INNER + OUTER) / 2.0
		var lines := label.split("\n")
		for n in lines.size():
			draw_string(font, at + Vector2(-60, -4 + n * 17), lines[n], HORIZONTAL_ALIGNMENT_CENTER, 120, 14,
				INK if have > 0 else EMPTY_INK)
	draw_circle(c + wheel.offset, 6.0, INK)


## The direction wedge `angle` (radians clockwise from straight up) points in on the screen.
static func _dir(angle: float) -> Vector2:
	return Vector2(sin(angle), -cos(angle))
