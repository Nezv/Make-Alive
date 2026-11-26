class_name AmmoPanel
extends Control
## Bottom right: the gun's name and fire mode, the magazine as a pip a round (or a number for a big
## one), and the reserve.

const SIZE := Vector2(400, 70)
const PIP := Vector2(5, 14)

var gun_name := ""
var mode := ""
var rounds := 0
var mag := 0
var reserve := -1
var reloading := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	position = Vector2(-SIZE.x - 24, -SIZE.y - 40)
	size = SIZE


func set_gun(d: Dictionary, rounds_: int, reloading_: bool, reserve_: int) -> bool:
	var changed := rounds_ != rounds or reloading_ != reloading or str(d.name) != gun_name or reserve_ != reserve
	gun_name = d.name
	mode = Hud.fire_mode(d)
	mag = d.mag
	rounds = rounds_
	reloading = reloading_
	reserve = reserve_
	if changed:
		queue_redraw()
	return changed


## How many pips are drawn (-1: the magazine is shown as a number).
func pips() -> int:
	return rounds if mag <= Config.HUD_PIP_MAX else -1


func reserve_text() -> String:
	return "∞" if reserve < 0 else str(reserve)


func _draw() -> void:
	var right := SIZE.x
	HudParts.text(self, Vector2(0, 18), "%s  ·  %s" % [gun_name, mode], 18, HudParts.INK, HORIZONTAL_ALIGNMENT_RIGHT, right)
	var low := rounds <= Config.LOW_AMMO_ROUNDS and mag > 5
	var col := HudParts.BAD if rounds == 0 and not reloading else (HudParts.WARN if low else HudParts.INK)
	var res := "/ " + reserve_text()
	var res_w := HudParts.text_width(res, 22)
	HudParts.text(self, Vector2(right - res_w, 56), res, 22, HudParts.WARN if reserve == 0 else HudParts.DIM)
	var x := right - res_w - 14
	if reloading:
		HudParts.text(self, Vector2(0, 56), "RELOADING", 22, HudParts.WARN, HORIZONTAL_ALIGNMENT_RIGHT, x)
	elif pips() >= 0:
		for i in mag: # spent rounds dim, from the left
			var filled := i >= mag - rounds
			draw_rect(Rect2(Vector2(x - (mag - i) * (PIP.x + 2), 40), PIP), col if filled else HudParts.DIM)
	else:
		HudParts.text(self, Vector2(0, 58), str(rounds), 30, col, HORIZONTAL_ALIGNMENT_RIGHT, x)
