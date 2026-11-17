class_name ProgressRing
extends Control
## A ring round the crosshair that fills clockwise from the top: how far a revive or a heal has got.

const RADIUS := 34.0
const WIDTH := 5.0
const BACK := Color(0, 0, 0, 0.45)
const FILL := Color(0.55, 0.95, 0.6, 0.95)

var progress := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false


func set_progress(p: float) -> void:
	visible = p >= 0.0
	if visible and not is_equal_approx(p, progress):
		queue_redraw()
	progress = clampf(p, 0.0, 1.0)


func _draw() -> void:
	var c := size / 2.0
	draw_arc(c, RADIUS, 0.0, TAU, 48, BACK, WIDTH + 2.0, true)
	if progress > 0.0:
		draw_arc(c, RADIUS, -PI / 2.0, -PI / 2.0 + TAU * progress, maxi(4, int(48 * progress)), FILL, WIDTH, true)
