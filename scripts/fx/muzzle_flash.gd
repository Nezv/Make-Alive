class_name MuzzleFlash
extends Node3D
## What comes out of the barrel when a gun goes off, on the shooter's view and on other players'
## guns: a star of 3 to 5 crossed quads (one mesh per shape, made once and shared), shown for a
## frame or two with a random roll and size; on the full tier a warm light that lights the hands
## and the walls nearby; two or three puffs of smoke drifting up with the wind; and after a long
## burst a thin wisp from the hot barrel for a couple of seconds. The shape comes from the gun
## (`Weapons.flash_shape`): a suppressed gun has no flash and only a thin grey puff.
##
## Sits at the muzzle, barrel along -Z (a child of the gun's parent). `cheap` is the tier for other
## players: no light, one puff, no wisp. Smoke goes through `fx` (the pooled kit); null = none.

const CORE := Color(1.0, 0.95, 0.78, 1.0)
const TIP := Color(1.0, 0.45, 0.08, 0.0)
const RIM := Color(1.0, 0.6, 0.2, 0.0)
const SMOKE := Color(0.62, 0.61, 0.6, 0.22)
const THIN := Color(0.6, 0.6, 0.62, 0.12)

static var _meshes := {}     ## Weapons.Flash -> ArrayMesh
static var _material: StandardMaterial3D

var cheap := false
var shape: int = Weapons.Flash.NONE
var flash: MeshInstance3D
var light: OmniLight3D       ## null on the cheap tier
var fx: Fx
var rng := RandomNumberGenerator.new()
var heat := 0.0              ## shots' worth, cooling at Config.MUZZLE_HEAT_DECAY a second
var shots := 0               ## fired so far (tests, debugging)

var _flash_t := 0.0
var _light_t := 0.0
var _wisp_left := 0.0
var _wisp_t := 0.0


func _init(cheap_tier := false) -> void:
	cheap = cheap_tier
	name = "MuzzleFlash"
	flash = MeshInstance3D.new()
	flash.material_override = material()
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.visible = false
	add_child(flash)
	if not cheap:
		light = OmniLight3D.new()
		light.light_color = Config.MUZZLE_LIGHT_COLOR
		light.omni_range = Config.MUZZLE_LIGHT_RANGE
		light.light_energy = 0.0
		light.shadow_enabled = false
		light.position = Vector3(0, 0, -0.08)
		add_child(light)


## Put it on gun `id` whose muzzle is at `muzzle` (in the parent's space).
func set_gun(id: int, muzzle: Vector3) -> void:
	shape = Weapons.flash_shape(id)
	position = muzzle
	flash.mesh = mesh_for(shape) if shape != Weapons.Flash.NONE else null
	flash.visible = false
	heat = 0.0
	_flash_t = 0.0
	_light_t = 0.0
	_wisp_left = 0.0
	if light:
		light.light_energy = 0.0


## A shot went off.
func fire() -> void:
	shots += 1
	if shape != Weapons.Flash.NONE:
		_flash_t = Config.MUZZLE_FLASH_TIME
		_light_t = Config.MUZZLE_LIGHT_TIME
		var roll := 0.15 if shape == Weapons.Flash.JETS else PI # the brake's ports don't turn
		flash.rotation = Vector3(0, 0, rng.randf_range(-roll, roll))
		var w := rng.randf_range(0.75, 1.25)
		flash.scale = Vector3(w, w, rng.randf_range(0.8, 1.3))
	_smoke()
	heat += 1.0
	if heat >= Config.MUZZLE_HEAT_WISP and not cheap:
		_wisp_left = Config.MUZZLE_WISP_TIME


## Advance by `delta` seconds (the owner calls this every frame). A flash fired since the last call
## shows for at least this frame.
func step(delta: float) -> void:
	flash.visible = _flash_t > 0.0 and flash.mesh != null
	_flash_t -= delta
	if light:
		light.light_energy = Config.MUZZLE_LIGHT_ENERGY * maxf(_light_t, 0.0) / Config.MUZZLE_LIGHT_TIME
		_light_t -= delta
	heat = maxf(0.0, heat - Config.MUZZLE_HEAT_DECAY * delta)
	if _wisp_left > 0.0:
		_wisp_left -= delta
		_wisp_t -= delta
		if _wisp_t <= 0.0:
			_wisp_t = Config.MUZZLE_WISP_EVERY
			_wisp()


func _smoke() -> void:
	if fx == null or not is_inside_tree():
		return
	var at := global_position
	var forward := -global_basis.z.normalized()
	var drift := Config.MUZZLE_SMOKE_DRIFT
	var opts := { "speed": drift.length(), "spread": 0.3, "life": Config.MUZZLE_SMOKE_LIFE, "size": 0.05,
		"size_end": 0.35, "color": SMOKE, "gravity": -0.5, "drag": 0.6 }
	if shape == Weapons.Flash.NONE:
		opts.merge({ "size": 0.03, "size_end": 0.2, "color": THIN }, true)
		fx.burst(Fx.Layer.SMOKE, at, drift + forward * 0.2, 1, opts)
	elif cheap:
		fx.burst(Fx.Layer.SMOKE, at, drift + forward * 0.3, 1, opts)
	elif shape == Weapons.Flash.JETS:
		var side := global_basis.x.normalized()
		fx.burst(Fx.Layer.SMOKE, at + side * 0.05, drift + side * 0.6, 1, opts)
		fx.burst(Fx.Layer.SMOKE, at - side * 0.05, drift - side * 0.6, 1, opts)
		fx.burst(Fx.Layer.SMOKE, at, drift + forward * 0.3, 1, opts)
	else:
		var n := 3 if shape == Weapons.Flash.BALL else 2
		fx.burst(Fx.Layer.SMOKE, at, drift + forward * 0.3, n, opts)


func _wisp() -> void:
	if fx == null or not is_inside_tree():
		return
	fx.burst(Fx.Layer.SMOKE, global_position, Vector3.UP + Config.MUZZLE_SMOKE_DRIFT, 1, { "speed": 0.3,
		"spread": 0.15, "life": Config.MUZZLE_SMOKE_LIFE, "size": 0.02, "size_end": 0.16,
		"color": Color(THIN, 0.09), "gravity": -0.4, "drag": 0.5 })


# --- The shapes -------------------------------------------------------------------

## The star for a Flash shape (made once). Additive, unshaded, bright at the muzzle and fading out
## at the tips, so crossed quads read as a burst of fire from any side.
static func mesh_for(s: int) -> ArrayMesh:
	if _meshes.has(s):
		return _meshes[s]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match s:
		Weapons.Flash.ROUND: # small and round: a short cross and a disc facing out
			_axial(st, 0.0, 0.12, 0.03, 0.05)
			_axial(st, PI / 2.0, 0.12, 0.03, 0.05)
			_disc(st, 0.06, -0.02)
		Weapons.Flash.FORK: # long, opening into prongs at the tip
			for i in 3:
				_axial(st, i * PI / 3.0, 0.34, 0.02, 0.06)
			_disc(st, 0.05, -0.02)
		Weapons.Flash.BALL: # a wide ball of fire
			for i in 3:
				_axial(st, i * PI / 3.0, 0.22, 0.07, 0.14)
			_disc(st, 0.13, -0.05)
		_: # JETS: sideways out of the brake's ports, each a crossed pair
			for side in [1.0, -1.0]:
				_jet(st, side, Vector3.UP)
				_jet(st, side, Vector3.BACK)
	_meshes[s] = st.commit()
	return _meshes[s]


static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.vertex_color_use_as_albedo = true
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.no_depth_test = false
	return _material


## A quad along the barrel (-Z), `length` long, in the plane turned `angle` round the barrel:
## `w0` half wide at the muzzle, `w1` at the tip.
static func _axial(st: SurfaceTool, angle: float, length: float, w0: float, w1: float) -> void:
	var s := Vector3(cos(angle), sin(angle), 0.0)
	_quad(st, -s * w0, s * w0, s * w1 + Vector3(0, 0, -length), -s * w1 + Vector3(0, 0, -length))


## A jet out of side `side` (+1 right, -1 left), in the plane of X and `across`.
static func _jet(st: SurfaceTool, side: float, across: Vector3) -> void:
	var a := across * 0.015
	var b := across * 0.05
	var near := Vector3(0.02 * side, 0, 0)
	var far := Vector3(0.2 * side, 0, -0.02)
	_quad(st, near - a, near + a, far + b, far - b)


## A quad from the muzzle edge (p0, p1: bright) to the tip edge (p2, p3: faded).
static func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3) -> void:
	for v: Array in [[p0, CORE], [p1, CORE], [p2, TIP], [p0, CORE], [p2, TIP], [p3, TIP]]:
		st.set_color(v[1])
		st.add_vertex(v[0])


## A diamond facing out of the barrel at depth `z`: bright in the middle, faded at the rim.
## Four triangles (it counts as two quads).
static func _disc(st: SurfaceTool, r: float, z: float) -> void:
	var c := Vector3(0, 0, z)
	var rim := [Vector3(r, 0, z), Vector3(0, r, z), Vector3(-r, 0, z), Vector3(0, -r, z)]
	for i in 4:
		for v: Array in [[c, CORE], [rim[i], RIM], [rim[(i + 1) % 4], RIM]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
