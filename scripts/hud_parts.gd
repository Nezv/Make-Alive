class_name HudParts
## Shared drawing bits for the HUD's parts (ammo panel, vitals, compass, objective, world markers).

const INK := Color(1, 1, 1, 0.95)
const DIM := Color(1, 1, 1, 0.35)
const SHADOW := Color(0, 0, 0, 0.6)
const WARN := Color("ffcc66")
const BAD := Color("ff5555")
const GOOD := Color("7be08a")
const OBJECTIVE := Color("ffd24a")
const MATE := Color("7fd4ff")


static func text(ci: CanvasItem, at: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	var font := ThemeDB.fallback_font
	ci.draw_string(font, at + Vector2(1, 2), s, align, width, size, SHADOW)
	ci.draw_string(font, at, s, align, width, size, col)


static func text_width(s: String, size: int) -> float:
	return ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func diamond(ci: CanvasItem, c: Vector2, r: float, col: Color, filled := true) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	if filled:
		ci.draw_colored_polygon(pts, col)
	else:
		pts.append(pts[0])
		ci.draw_polyline(pts, col, 2.0, true)
