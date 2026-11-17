class_name Fx
extends Node3D
## The effects kit: what every muzzle flash, impact, explosion and fire is built from.
## Cosmetic and local, like Gore. The host sends *what happened* (`Game.play_fx(kind, position,
## direction, arg)`); each peer draws it here with its own particles.
##
## Four pooled building blocks, each made once and capped in Config (FX_MAX_*):
##   burst(layer, ...)   particles: CHIP (lit boxes that fall and land), GLOW (bright additive
##                       billboards: sparks, flashes), SMOKE (soft billboards that grow and fade)
##   light(...)          a short omni light with a fading life. Never casts shadows.
##   decal(kind, ...)    a mark lying on a surface: bullet hole, scorch, crack, puddle
##   trail(node, ...)    a ribbon behind a moving node
## When a pool is full the oldest entry is reused, so a firefight can never grow the frame.
##
## Adding an effect: a name in Kind and NAMES, a branch in `play` built from the blocks above.
## Look at it with `tools\godot.ps1 -- --host --fx-rack`.

enum Layer { CHIP, GLOW, SMOKE }
enum Mark { HOLE, SCORCH, CRACK, PUDDLE }
## What travels on the wire. Append only: the numbers are the protocol.
enum Kind { DUST, SPARKS, FLASH, SMOKE, BLAST, HOLE, CRACK, SPLASH, ARRIVAL, TRACER }
const NAMES := ["dust", "sparks", "flash", "smoke", "blast", "hole", "crack", "splash", "arrival", "tracer"]

## Counters (tests read these; handy for debugging too).
var stats := { "played": 0, "bursts": 0, "lights": 0, "decals": 0, "trails": 0 }
var last_kind := -1 ## the last effect played (tests)
var ground := Callable() ## map.ground_y: where chips come to rest (unset: y = 0)

var _count_mult := 1.0
var _life_mult := 1.0
var _rng := RandomNumberGenerator.new()
var _layers: Array[Particles] = []
var _lights: Array = []    ## { node, age, life, energy }
var _next_light := 0
var _decals: Array = []    ## per Mark kind: { mm: MultiMesh, next: int }
var _trails: Array = []    ## { on, target (instance id), points: PackedVector3Array, width, color, life, fade }
var _trail_mesh: ImmediateMesh


func _ready() -> void:
	name = "Fx"
	_layers = [
		Particles.new(Config.FX_MAX_CHIPS, _chip_mesh(), true),
		Particles.new(Config.FX_MAX_GLOWS, _billboard_mesh(true), false),
		Particles.new(Config.FX_MAX_SMOKE, _billboard_mesh(false), false),
	]
	for l in _layers:
		add_child(l.node)
	for i in Config.FX_MAX_LIGHTS:
		var lamp := OmniLight3D.new()
		lamp.shadow_enabled = false
		lamp.visible = false
		add_child(lamp)
		_lights.append({ "node": lamp, "age": 0.0, "life": 0.0, "energy": 0.0 })
	for kind in Mark.size():
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _decal_mesh(kind)
		mm.instance_count = Config.FX_MAX_DECALS
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.custom_aabb = AABB(Vector3(-4000, -100, -4000), Vector3(8000, 600, 8000))
		add_child(mmi)
		_decals.append({ "mm": mm, "next": 0 })
	for i in Config.FX_MAX_TRAILS:
		_trails.append({ "on": false, "target": 0, "points": PackedVector3Array(), "width": 0.05,
			"color": Color.WHITE, "life": 0.3, "fade": 0.0 })
	_trail_mesh = ImmediateMesh.new()
	var ribbon := MeshInstance3D.new()
	ribbon.mesh = _trail_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	ribbon.material_override = mat
	ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ribbon.custom_aabb = AABB(Vector3(-4000, -100, -4000), Vector3(8000, 600, 8000))
	add_child(ribbon)
	set_tier(Settings.get_value("graphics_tier"))


func _process(delta: float) -> void:
	step(delta)


## LOW / MEDIUM / HIGH: how many particles a burst really makes and how long they linger.
func set_tier(tier: String) -> void:
	_count_mult = Config.FX_TIER_COUNT.get(tier, 1.0)
	_life_mult = Config.FX_TIER_LIFE.get(tier, 1.0)


## Everything off at once (a new match, a test).
func clear() -> void:
	for l in _layers:
		l.clear()
	for e: Dictionary in _lights:
		e.life = 0.0
		(e.node as OmniLight3D).visible = false
	for d: Dictionary in _decals:
		d.next = 0
		(d.mm as MultiMesh).visible_instance_count = 0
	for t: Dictionary in _trails:
		t.on = false


# --- Particles --------------------------------------------------------------------

## `count` particles from `pos`, thrown along `dir`. What `opts` may hold (all optional):
##   speed (m/s) · spread (0 = a line, 1 = every direction) · life (s) · gravity · drag
##   size / size_end (m) · color / color_end · spin (rad/s)
## Speed, life and size vary a little per particle so a burst never looks stamped.
func burst(layer: int, pos: Vector3, dir: Vector3, count: int, opts: Dictionary = {}) -> void:
	var n := maxi(1, roundi(count * _count_mult))
	var l := _layers[layer]
	var d: Dictionary = Particles.DEFAULTS[layer]
	var speed: float = opts.get("speed", d.speed)
	var spread: float = opts.get("spread", d.spread)
	var life: float = opts.get("life", d.life) * _life_mult
	var size: float = opts.get("size", d.size)
	var size_end: float = opts.get("size_end", opts.get("size", d.size) * d.grow)
	var color: Color = opts.get("color", d.color)
	var color_end: Color = opts.get("color_end", Color(color, 0.0))
	var gravity: float = opts.get("gravity", d.gravity)
	var drag: float = opts.get("drag", d.drag)
	var spin: float = opts.get("spin", d.spin)
	var f := dir.normalized() if dir.length_squared() > 0.0001 else Vector3.UP
	for i in n:
		var stray := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), _rng.randf_range(-1, 1))
		var v := (f + stray * spread).normalized() * speed * _rng.randf_range(0.6, 1.0)
		var vary := _rng.randf_range(0.75, 1.0)
		l.emit(pos, v, life * vary, size * vary, size_end * vary, color, color_end, gravity, drag,
			spin * _rng.randf_range(-1.0, 1.0), _rng.randf() * TAU)
	stats.bursts += 1


## Particles of `layer` still alive.
func alive(layer: int) -> int:
	return _layers[layer].alive


## Where the live particles of `layer` are (tests).
func positions(layer: int) -> Array:
	return _layers[layer].positions()


# --- Lights -----------------------------------------------------------------------

## A light that starts at `energy` and fades to nothing over `life` seconds.
func light(pos: Vector3, color: Color, energy: float, radius: float, life: float) -> void:
	var e: Dictionary = _lights[_next_light]
	for i in _lights.size(): # a free one if there is one, otherwise round-robin (the oldest)
		var c: Dictionary = _lights[(_next_light + i) % _lights.size()]
		if c.age >= c.life:
			e = c
			_next_light = (_next_light + i) % _lights.size()
			break
	_next_light = (_next_light + 1) % _lights.size()
	var lamp: OmniLight3D = e.node
	lamp.position = to_local(pos) if is_inside_tree() else pos
	lamp.light_color = color
	lamp.light_energy = energy
	lamp.omni_range = radius
	lamp.visible = true
	e.age = 0.0
	e.life = life
	e.energy = energy
	stats.lights += 1


func lights_on() -> int:
	var n := 0
	for e: Dictionary in _lights:
		if e.age < e.life:
			n += 1
	return n


# --- Decals -----------------------------------------------------------------------

## A mark of `size` metres lying on the surface at `pos` whose normal is `normal`.
## Returns where it was put (its local Y points out of the surface).
func decal(kind: int, pos: Vector3, normal: Vector3, size: float, color := Color.WHITE) -> Transform3D:
	var d: Dictionary = _decals[kind]
	var mm: MultiMesh = d.mm
	var i: int = d.next % Config.FX_MAX_DECALS
	var up := normal.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
	var basis := Basis(side, up, side.cross(up)).rotated(up, _rng.randf() * TAU)
	# A hair off the surface, and each one a little higher than the last, so marks never flicker.
	var xf := Transform3D(basis.scaled_local(Vector3(size, 1.0, size)), pos + up * (0.006 + i * 0.00002))
	mm.set_instance_transform(i, xf)
	mm.set_instance_color(i, color)
	d.next += 1
	mm.visible_instance_count = mini(d.next, Config.FX_MAX_DECALS)
	stats.decals += 1
	return xf


func decal_count(kind: int) -> int:
	return (_decals[kind].mm as MultiMesh).visible_instance_count


# --- Trails -----------------------------------------------------------------------

## A ribbon behind `target`, `life` seconds long. It fades by itself once the node is gone.
## Returns its id, or -1 if every trail is in use.
func trail(target: Node3D, width: float, color: Color, life: float) -> int:
	for i in _trails.size():
		var t: Dictionary = _trails[i]
		if not t.on:
			t.on = true
			t.target = target.get_instance_id()
			t.points = PackedVector3Array([target.global_position])
			t.width = width
			t.color = color
			t.life = life
			t.fade = life
			stats.trails += 1
			return i
	return -1


func trails_on() -> int:
	var n := 0
	for t: Dictionary in _trails:
		if t.on:
			n += 1
	return n


func trail_points(id: int) -> int:
	return (_trails[id].points as PackedVector3Array).size()


# --- Named effects (the wire) -----------------------------------------------------

## Play effect `kind` (a Kind) at `pos`. `dir` is the surface normal or the way it is thrown;
## `arg` is its size (1 = normal). Unknown kinds are ignored: they come from the network.
func play(kind: int, pos: Vector3, dir: Vector3, arg := 1.0) -> void:
	if kind < 0 or kind >= Kind.size():
		return
	stats.played += 1
	last_kind = kind
	var s := maxf(arg, 0.1)
	match kind:
		Kind.DUST: # a bullet in concrete: a grey cone, a few chips
			burst(Layer.SMOKE, pos, dir, 5, { "speed": 1.6 * s, "spread": 0.45, "life": 0.7, "size": 0.12 * s,
				"size_end": 0.55 * s, "color": Color(0.55, 0.53, 0.5, 0.5) })
			burst(Layer.CHIP, pos, dir, 6, { "speed": 3.5, "spread": 0.6, "size": 0.035, "color": Color("77736c") })
		Kind.SPARKS: # a bullet on metal: bright sparks that arc and die
			burst(Layer.GLOW, pos, dir, 14, { "speed": 7.0, "spread": 0.55, "life": 0.35, "size": 0.035,
				"size_end": 0.01, "color": Color(1.0, 0.8, 0.35), "color_end": Color(1.0, 0.3, 0.05, 0.0), "gravity": 14.0 })
			light(pos + dir * 0.1, Color(1.0, 0.75, 0.4), 1.2, 3.0, 0.06)
		Kind.FLASH: # a muzzle: one bright frame and a light
			burst(Layer.GLOW, pos, dir, 3, { "speed": 0.6, "spread": 0.2, "life": 0.05, "size": 0.22 * s,
				"size_end": 0.3 * s, "color": Color(1.0, 0.85, 0.5), "gravity": 0.0 })
			light(pos, Color(1.0, 0.8, 0.5), 2.5 * s, 7.0, 0.05)
		Kind.SMOKE: # a lazy grey puff drifting up
			burst(Layer.SMOKE, pos, dir, 4, { "speed": 0.5, "spread": 0.5, "life": 1.6, "size": 0.2 * s,
				"size_end": 0.9 * s, "color": Color(0.4, 0.4, 0.42, 0.35), "gravity": -0.4 })
		Kind.BLAST: # an explosion: flash, fireball, black smoke, debris, scorch
			light(pos + Vector3.UP * 0.5, Color(1.0, 0.7, 0.35), 9.0 * s, 16.0 * s, 0.35)
			burst(Layer.GLOW, pos, Vector3.UP, 14, { "speed": 4.0 * s, "spread": 1.0, "life": 0.35, "size": 0.7 * s,
				"size_end": 1.6 * s, "color": Color(1.0, 0.75, 0.3), "color_end": Color(0.9, 0.2, 0.02, 0.0), "gravity": -1.0 })
			burst(Layer.SMOKE, pos, Vector3.UP, 12, { "speed": 2.5 * s, "spread": 0.9, "life": 2.6, "size": 0.6 * s,
				"size_end": 2.4 * s, "color": Color(0.08, 0.08, 0.08, 0.7), "gravity": -1.2 })
			burst(Layer.CHIP, pos, Vector3.UP, 22, { "speed": 9.0 * s, "spread": 0.9, "life": 2.5, "size": 0.07,
				"color": Color("3a3632") })
			burst(Layer.GLOW, pos, Vector3.UP, 16, { "speed": 11.0 * s, "spread": 0.9, "life": 0.6, "size": 0.04,
				"size_end": 0.01, "color": Color(1.0, 0.7, 0.3), "gravity": 12.0 })
			decal(Mark.SCORCH, Vector3(pos.x, _floor(pos), pos.z), Vector3.UP, 3.0 * s)
		Kind.HOLE:
			decal(Mark.HOLE, pos, dir, 0.09 * s)
		Kind.CRACK:
			decal(Mark.CRACK, pos, dir, 0.4 * s)
			burst(Layer.CHIP, pos, dir, 5, { "speed": 2.5, "spread": 0.7, "size": 0.025, "color": Color("c8d4d8") })
		Kind.SPLASH: # a bullet in water: a column and a wet patch
			burst(Layer.SMOKE, pos, Vector3.UP, 7, { "speed": 3.0 * s, "spread": 0.2, "life": 0.5, "size": 0.1 * s,
				"size_end": 0.35 * s, "color": Color(0.75, 0.82, 0.88, 0.55), "gravity": 9.0 })
			decal(Mark.PUDDLE, pos, Vector3.UP, 0.7 * s)
		Kind.TRACER: # a bright streak along `dir` for `arg` metres (the door gun; S030 makes the real ones)
			var n := clampi(int(arg / 2.0), 3, 24)
			for k in n:
				burst(Layer.GLOW, pos + dir.normalized() * arg * (k + 0.5) / n, dir, 1, { "speed": 0.0, "spread": 0.0,
					"life": 0.07, "size": 0.06, "size_end": 0.03, "color": Color(1.0, 0.85, 0.45), "gravity": 0.0 })
		Kind.ARRIVAL: # a survivor jumps down off a truck bed: a ring of dust kicked out round the feet
			var feet := Vector3(pos.x, _floor(pos) + 0.05, pos.z)
			for k in 8:
				var out := Vector3(cos(k * TAU / 8.0), 0.15, sin(k * TAU / 8.0))
				burst(Layer.SMOKE, feet, out, 1, { "speed": 1.8 * s, "spread": 0.25, "life": 0.9, "size": 0.15 * s,
					"size_end": 0.6 * s, "color": Color(0.5, 0.48, 0.44, 0.45), "gravity": -0.2 })
			burst(Layer.CHIP, feet, Vector3.UP, 6, { "speed": 2.0, "spread": 0.9, "size": 0.03, "color": Color("6f6a62") })


# --- Every frame ------------------------------------------------------------------

## Advance everything by `delta` seconds. `_process` calls this; tests call it directly.
func step(delta: float) -> void:
	for l in _layers:
		if l.alive > 0:
			l.step(delta, ground)
	for e: Dictionary in _lights:
		if e.age < e.life:
			e.age += delta
			var lamp: OmniLight3D = e.node
			if e.age >= e.life:
				lamp.visible = false
			else:
				var left: float = 1.0 - e.age / e.life
				lamp.light_energy = e.energy * left * left
	_step_trails(delta)


func _floor(pos: Vector3) -> float:
	return ground.call(pos) if ground.is_valid() else 0.0


func _step_trails(delta: float) -> void:
	var any := false
	for t: Dictionary in _trails:
		if not t.on:
			continue
		any = true
		var points: PackedVector3Array = t.points
		var target := instance_from_id(t.target) as Node3D
		if target != null and not target.is_queued_for_deletion():
			var p := target.global_position
			if points.is_empty() or points[points.size() - 1].distance_squared_to(p) > 0.0004:
				points.append(p)
				if points.size() > Config.FX_TRAIL_POINTS:
					points.remove_at(0)
				t.points = points
			t.fade = t.life
		else:
			t.fade -= delta
			if t.fade <= 0.0:
				t.on = false
	if not any and _trail_mesh.get_surface_count() == 0:
		return
	_trail_mesh.clear_surfaces()
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var eye := cam.global_position if cam != null else Vector3(0, 100, 0)
	var began := false
	for t: Dictionary in _trails:
		var points: PackedVector3Array = t.points
		if not t.on or points.size() < 2:
			continue
		if not began:
			_trail_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
			began = true
		var n := points.size()
		var fade: float = t.fade / t.life
		var base: Color = t.color
		var width: float = t.width
		for i in n - 1:
			var a := points[i]
			var b := points[i + 1]
			var side := (b - a).cross(eye - a).normalized() * width * 0.5
			var ca := Color(base, base.a * fade * float(i) / (n - 1))       # thin air at the tail
			var cb := Color(base, base.a * fade * float(i + 1) / (n - 1))   # full colour at the head
			for v: Array in [[a - side, ca], [a + side, ca], [b + side, cb], [a - side, ca], [b + side, cb], [b - side, cb]]:
				_trail_mesh.surface_set_color(v[1])
				_trail_mesh.surface_add_vertex(to_local(v[0]) if is_inside_tree() else v[0])
	if began:
		_trail_mesh.surface_end()


# --- Meshes and materials (made once) ---------------------------------------------

func _chip_mesh() -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(1.0, 0.6, 0.8)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.9
	m.material = mat
	return m


## A soft round dot that always faces the camera. `additive` glows (sparks, fire); otherwise it is smoke.
func _billboard_mesh(additive: bool) -> Mesh:
	var m := QuadMesh.new()
	m.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _radial(Color.WHITE, Color(1, 1, 1, 0), 0.15 if additive else 0.0)
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES # spins by the instance's custom data
	mat.billboard_keep_scale = true
	mat.disable_receive_shadows = true
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.material = mat
	return m


func _decal_mesh(kind: int) -> Mesh:
	var m := PlaneMesh.new()
	m.size = Vector2.ONE
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_receive_shadows = true
	match kind:
		Mark.HOLE:
			mat.albedo_texture = _radial(Color(0.02, 0.02, 0.02, 1), Color(0.12, 0.11, 0.1, 0), 0.35)
		Mark.SCORCH:
			mat.albedo_texture = _radial(Color(0.02, 0.02, 0.02, 0.9), Color(0.05, 0.04, 0.03, 0), 0.1)
		Mark.CRACK:
			mat.albedo_texture = _crack_texture()
		Mark.PUDDLE:
			mat.albedo_texture = _radial(Color(0.03, 0.04, 0.05, 0.75), Color(0.03, 0.04, 0.05, 0), 0.6)
			mat.roughness = 0.05
			mat.metallic = 0.3
	m.material = mat
	return m


## A round gradient: `inner` in the middle (solid out to `core` of the radius), `outer` at the rim.
func _radial(inner: Color, outer: Color, core: float) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.set_color(0, inner)
	grad.set_color(1, outer)
	if core > 0.0:
		grad.add_point(core, inner)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex


## Cracked glass: a few jagged lines out from the middle, drawn into an image once.
func _crack_texture() -> ImageTexture:
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 62 # the same cracks on every run
	for ray in 9:
		var angle := TAU * ray / 9.0 + rng.randf_range(-0.2, 0.2)
		var p := Vector2(size, size) * 0.5
		for stepi in rng.randi_range(14, 30):
			angle += rng.randf_range(-0.35, 0.35)
			p += Vector2(cos(angle), sin(angle))
			if p.x < 0 or p.y < 0 or p.x >= size or p.y >= size:
				break
			img.set_pixelv(Vector2i(p), Color(0.9, 0.95, 1.0, 0.9))
	return ImageTexture.create_from_image(img)


# --- One pool of particles --------------------------------------------------------

## A fixed-size ring of particles drawn by one MultiMesh (one draw call). Plain arrays, no nodes.
class Particles:
	## Per layer (CHIP, GLOW, SMOKE): what a burst uses when `opts` doesn't say.
	const DEFAULTS := [
		{ "speed": 4.0, "spread": 0.6, "life": 1.6, "size": 0.05, "grow": 1.0, "color": Color("6b6660"),
			"gravity": Config.GRAVITY, "drag": 0.2, "spin": 9.0 },
		{ "speed": 5.0, "spread": 0.5, "life": 0.3, "size": 0.05, "grow": 0.3, "color": Color(1.0, 0.8, 0.4),
			"gravity": 6.0, "drag": 1.0, "spin": 0.0 },
		{ "speed": 1.0, "spread": 0.5, "life": 1.2, "size": 0.2, "grow": 3.0, "color": Color(0.5, 0.5, 0.5, 0.4),
			"gravity": -0.3, "drag": 1.5, "spin": 0.8 },
	]

	var node: MultiMeshInstance3D
	var mm: MultiMesh
	var cap := 0
	var alive := 0
	var lands := false ## chips stop on the ground; glows and smoke pass through
	var _next := 0
	var _pos := PackedVector3Array()
	var _vel := PackedVector3Array()
	var _age := PackedFloat32Array()
	var _life := PackedFloat32Array() ## 0 = this slot is free
	var _size0 := PackedFloat32Array()
	var _size1 := PackedFloat32Array()
	var _col0 := PackedColorArray()
	var _col1 := PackedColorArray()
	var _grav := PackedFloat32Array()
	var _drag := PackedFloat32Array()
	var _spin := PackedFloat32Array()
	var _angle := PackedFloat32Array()

	func _init(count: int, mesh: Mesh, on_ground: bool) -> void:
		cap = count
		lands = on_ground
		_age.resize(cap)
		_life.resize(cap)
		_size0.resize(cap)
		_size1.resize(cap)
		_grav.resize(cap)
		_drag.resize(cap)
		_spin.resize(cap)
		_angle.resize(cap)
		_pos.resize(cap)
		_vel.resize(cap)
		_col0.resize(cap)
		_col1.resize(cap)
		mm = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = mesh
		mm.instance_count = cap
		for i in cap:
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
		node = MultiMeshInstance3D.new()
		node.multimesh = mm
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.custom_aabb = AABB(Vector3(-4000, -100, -4000), Vector3(8000, 600, 8000))

	func emit(pos: Vector3, vel: Vector3, life: float, size0: float, size1: float, col0: Color, col1: Color,
			grav: float, drag: float, spin: float, angle: float) -> void:
		var i := _next
		_next = (_next + 1) % cap
		if _life[i] <= 0.0:
			alive += 1 # a free slot; otherwise the oldest particle just became this one
		_pos[i] = pos
		_vel[i] = vel
		_age[i] = 0.0
		_life[i] = maxf(life, 0.001)
		_size0[i] = size0
		_size1[i] = size1
		_col0[i] = col0
		_col1[i] = col1
		_grav[i] = grav
		_drag[i] = drag
		_spin[i] = spin
		_angle[i] = angle
		_draw(i, 0.0)

	func clear() -> void:
		for i in cap:
			if _life[i] > 0.0:
				_kill(i)

	func positions() -> Array:
		var out := []
		for i in cap:
			if _life[i] > 0.0:
				out.append(_pos[i])
		return out

	func step(delta: float, ground: Callable) -> void:
		for i in cap:
			var life := _life[i]
			if life <= 0.0:
				continue
			var age := _age[i] + delta
			if age >= life:
				_kill(i)
				continue
			_age[i] = age
			var v := _vel[i]
			v.y -= _grav[i] * delta
			v *= maxf(0.0, 1.0 - _drag[i] * delta)
			var p := _pos[i] + v * delta
			if lands:
				var floor_y: float = ground.call(p) if ground.is_valid() else 0.0
				if p.y < floor_y: # one dull bounce, then it lies there
					p.y = floor_y
					v = Vector3(v.x * 0.4, -v.y * 0.25 if v.y < -1.5 else 0.0, v.z * 0.4)
					_spin[i] *= 0.3
			_vel[i] = v
			_pos[i] = p
			_angle[i] += _spin[i] * delta
			_draw(i, age / life)

	func _kill(i: int) -> void:
		_life[i] = 0.0
		alive -= 1
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), _pos[i]))

	func _draw(i: int, t: float) -> void:
		var s := lerpf(_size0[i], _size1[i], t)
		var basis := Basis.from_scale(Vector3(s, s, s))
		if lands:
			basis = Basis(Vector3(0.3, 1.0, 0.5).normalized(), _angle[i]).scaled(Vector3(s, s, s))
		mm.set_instance_transform(i, Transform3D(basis, _pos[i]))
		mm.set_instance_color(i, _col0[i].lerp(_col1[i], t * t if lands else t))
		mm.set_instance_custom_data(i, Color(_angle[i], 0, 0, 0))
