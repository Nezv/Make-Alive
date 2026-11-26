class_name Tracers
extends Node3D
## Tracers: thin bright streaks that run from a muzzle to where the bullet went at bullet speed, a
## fixed length long, fading as they reach the end; a shotgun throws a fan of short ones; a sniper shot
## also leaves a vapour line that hangs for `Config.VAPOUR_TIME` and drifts apart. Everything is drawn
## by one MultiMesh, capped at `Config.TRACER_MAX` (the oldest gives way). Cosmetic and local.

var fired := 0                      ## tracers started (tests)
var _items: Array[Dictionary] = []  ## { from, dir, dist, len, t, color }
var _vapours: Array[Dictionary] = [] ## { from, to, t, seed }
var _mm: MultiMesh
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	name = "Tracers"
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3.ONE
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	box.material = m
	_mm.mesh = box
	_mm.instance_count = Config.TRACER_MAX + Config.VAPOUR_MAX * Config.VAPOUR_SEGS
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-2000, -200, -2000), Vector3(4000, 600, 4000))
	add_child(mmi)


## The streak's colour for a gun: bright yellow-white for rifles, faint for pistols, warm for shotguns.
static func color_for(weapon: int) -> Color:
	if Weapons.GUN_KIND[weapon] == Weapons.Kind.SIDEARM or weapon == Weapons.P90:
		return Color(1.0, 0.85, 0.65, 0.35)
	if int(Weapons.def(weapon).pellets) > 1:
		return Color(1.0, 0.75, 0.45, 0.7)
	return Color(1.0, 0.92, 0.6, 0.95)


## A shot from `from` that went to `to` with `weapon`; `streak` false leaves only a sniper's vapour line.
func fire(from: Vector3, to: Vector3, weapon: int, streak := true) -> void:
	var d := Weapons.def(weapon)
	var col := color_for(weapon)
	var dir := (to - from).normalized()
	var dist := from.distance_to(to)
	var pellets: int = d.pellets
	if not streak:
		pass
	elif pellets > 1: # a fan of short ones
		for i in pellets:
			var pd := Weapons.scatter(dir, float(d.pellet_spread) * 1.2, _rng)
			_add(from, pd, minf(dist, Config.TRACER_SHOTGUN_REACH), Config.TRACER_LENGTH * 0.3, col)
	else:
		_add(from, dir, dist, Config.TRACER_LENGTH, col)
	if d.scoped: # a sniper's round leaves the air marked
		_vapours.append({ "from": from, "to": to, "t": 0.0, "seed": _rng.randf() * 100.0 })
		while _vapours.size() > Config.VAPOUR_MAX:
			_vapours.pop_front()


func _add(from: Vector3, dir: Vector3, dist: float, length: float, col: Color) -> void:
	_items.append({ "from": from, "dir": dir, "dist": dist, "len": length, "t": 0.0, "color": col })
	fired += 1
	while _items.size() > Config.TRACER_MAX:
		_items.pop_front()


func active() -> int:
	return _items.size()


func vapour_count() -> int:
	return _vapours.size()


## [head, tail] of tracer `i` now.
func segment(i: int) -> Array:
	var it := _items[i]
	var head := minf(float(it.t) * Config.TRACER_SPEED, it.dist)
	var tail := clampf(float(it.t) * Config.TRACER_SPEED - float(it.len), 0.0, it.dist)
	return [it.from + it.dir * head, it.from + it.dir * tail]


## How bright tracer `i` is now: full while running, fading as its tail catches up with the end.
func alpha(i: int) -> float:
	var it := _items[i]
	var tail := clampf(float(it.t) * Config.TRACER_SPEED - float(it.len), 0.0, it.dist)
	return float((it.color as Color).a) * clampf((float(it.dist) - tail) / float(it.len), 0.0, 1.0)


## How far vapour line `i` has drifted apart (metres).
func vapour_spread(i: int) -> float:
	return 0.01 + Config.VAPOUR_WOBBLE * float(_vapours[i].t) / Config.VAPOUR_TIME


func step(delta: float) -> void:
	for it in _items:
		it.t = float(it.t) + delta
	_items = _items.filter(func(it: Dictionary) -> bool:
		return float(it.t) * Config.TRACER_SPEED - float(it.len) < float(it.dist))
	for v in _vapours:
		v.t = float(v.t) + delta
	_vapours = _vapours.filter(func(v: Dictionary) -> bool: return float(v.t) < Config.VAPOUR_TIME)


func _process(delta: float) -> void:
	step(delta)
	_draw_all()


func _draw_all() -> void:
	var n := 0
	for i in _items.size():
		var seg := segment(i)
		var col: Color = _items[i].color
		n = _put(n, seg[1], seg[0], Config.TRACER_WIDTH, Color(col, alpha(i)))
	for v in _vapours:
		var u: float = float(v.t) / Config.VAPOUR_TIME
		var spread := 0.01 + Config.VAPOUR_WOBBLE * u
		var to: Vector3 = v.to
		var from: Vector3 = v.from
		from = from.move_toward(to, minf(1.5, from.distance_to(to) * 0.5)) # not in your face
		var side := (to - from).cross(Vector3.UP).normalized()
		var prev := from
		for k in Config.VAPOUR_SEGS:
			var f := float(k + 1) / Config.VAPOUR_SEGS
			var wob := side * sin(float(v.seed) + k * 1.7) * spread + Vector3.UP * (cos(float(v.seed) + k * 2.3) * spread + u * 0.3)
			var p := from.lerp(to, f) + wob
			n = _put(n, prev, p, 0.012 + spread * 0.08, Color(0.85, 0.88, 0.9, 0.22 * (1.0 - u)))
			prev = p
	_mm.visible_instance_count = n


func _put(n: int, a: Vector3, b: Vector3, width: float, col: Color) -> int:
	if n >= _mm.instance_count:
		return n
	var along := b - a
	var length := along.length()
	if length < 0.001:
		return n
	var z := along / length
	var x := z.cross(Vector3.UP if absf(z.y) < 0.95 else Vector3.RIGHT).normalized()
	var y := x.cross(z)
	_mm.set_instance_transform(n, Transform3D(Basis(x * width, y * width, z * length), (a + b) * 0.5))
	_mm.set_instance_color(n, col)
	return n + 1
