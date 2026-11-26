class_name BleedDrops
extends Control
## Blood at the bottom of your screen while you bleed: drops well up from the lower edge, creep a
## little way up, swell and fade, a few at a time for each wound (`Config.BLEED_SCREEN_DROPS`).

const LIFE := 1.6          ## seconds a drop lasts
const RISE := 70.0         ## pixels it creeps up over its life
const SIZE := Vector2(10.0, 26.0) ## radius range
const COLOR := Color(0.5, 0.02, 0.02, 0.75)

var bleed := 0             ## wounds open now (the HUD sets this)
var drops: Array[Dictionary] = []
var _spawn_t := 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.seed = 7


func _process(dt: float) -> void:
	step(dt)
	if not drops.is_empty() or visible:
		queue_redraw()


func step(dt: float) -> void:
	for d in drops:
		d.age += dt
		var rise: float = RISE / LIFE * dt * (1.0 - float(d.age) / LIFE)
		d.pos = (d.pos as Vector2) - Vector2(0.0, rise)
	drops = drops.filter(func(d: Dictionary) -> bool: return d.age < LIFE)
	var want := bleed * Config.BLEED_SCREEN_DROPS
	if want <= 0:
		_spawn_t = 0.0
		return
	_spawn_t -= dt
	while _spawn_t <= 0.0 and drops.size() < want:
		_spawn_t += LIFE / want
		var x := _rng.randf_range(0.04, 0.96) * size.x
		var bottom := size.y * _rng.randf_range(0.97, 1.02)
		drops.append({ "pos": Vector2(x, bottom), "age": 0.0, "r": _rng.randf_range(SIZE.x, SIZE.y) })
	if _spawn_t <= 0.0:
		_spawn_t = 0.0


func _draw() -> void:
	for d in drops:
		var u: float = d.age / LIFE
		var col := COLOR
		col.a *= sin(minf(u * 3.0, 1.0) * PI * 0.5) * (1.0 - u * u)
		var r: float = d.r * (0.6 + 0.4 * minf(u * 4.0, 1.0))
		var at: Vector2 = d.pos
		# a finger of blood creeping up from the edge: a rounded tip over a smear that widens to the edge
		var smear := PackedVector2Array([at + Vector2(-r, 0), at + Vector2(r, 0),
			Vector2(at.x + r * 1.5, size.y), Vector2(at.x - r * 1.5, size.y)])
		draw_colored_polygon(smear, col)
		draw_circle(at, r, col)
		draw_circle(at + Vector2(r * 0.3, -r * 0.2), r * 0.35, Color(col, col.a * 0.6).lightened(0.15)) # wet shine
