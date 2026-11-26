class_name MuzzleFlash
extends MeshInstance3D
## A muzzle flash: a star of three to five crossed quads along the barrel (-Z), hot white in the middle
## going orange and clear at the tips, shown for a frame or two with a random roll and size. The shape
## is the gun's (`Weapons.Flash`): small and round for pistols, long for rifles, a wide ball for
## shotguns, side jets for braked rifles. One per gun model, made once; no allocation per shot.

const CORE := Color(1.0, 0.95, 0.75, 1.0)
const EDGE := Color(1.0, 0.5, 0.12, 0.0)

static var _meshes := {}
static var _material: StandardMaterial3D

var shape := Weapons.Flash.ROUND
var _t := 0.0


static func create(flash_shape: int) -> MuzzleFlash:
	var f := MuzzleFlash.new()
	f.shape = flash_shape
	if flash_shape != Weapons.Flash.NONE:
		f.mesh = mesh_for(flash_shape)
	f.material_override = _mat()
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.visible = false
	return f


static func _mat() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.vertex_color_use_as_albedo = true
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.no_depth_test = false
	return _material


## The flash's mesh for a shape, built once.
static func mesh_for(flash_shape: int) -> ArrayMesh:
	if _meshes.has(flash_shape):
		return _meshes[flash_shape]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match flash_shape:
		Weapons.Flash.ROUND:
			_star(st, 2, 0.14, 0.12)
			_disc(st, 0.14)
		Weapons.Flash.FORKED:
			_star(st, 3, 0.1, 0.42)
			_disc(st, 0.1)
		Weapons.Flash.BALL:
			_star(st, 4, 0.34, 0.3)
			_disc(st, 0.3)
		Weapons.Flash.JETS:
			for side in [-1.0, 1.0]: # out of the brake's side ports
				_quad(st, Vector3(side * 0.03, -0.035, -0.06), Vector3(side * 0.03, 0.035, -0.06),
					Vector3(side * 0.32, 0.06, -0.08), Vector3(side * 0.32, -0.06, -0.08))
			_star(st, 1, 0.08, 0.12)
			_disc(st, 0.08)
	var m := st.commit()
	_meshes[flash_shape] = m
	return m


## `n` diamonds through the barrel's axis, turned evenly round it: `w` wide, `length` long.
static func _star(st: SurfaceTool, n: int, w: float, length: float) -> void:
	for k in n:
		var a := PI * k / n
		var side := Vector3(cos(a), sin(a), 0.0) * w * 0.5
		_quad(st, Vector3.ZERO, side + Vector3(0, 0, -length * 0.4), Vector3(0, 0, -length), -side + Vector3(0, 0, -length * 0.4))


## The square seen end on (from in front of the gun).
static func _disc(st: SurfaceTool, w: float) -> void:
	var h := w * 0.5
	_quad(st, Vector3(-h, -h, -0.02), Vector3(h, -h, -0.02), Vector3(h, h, -0.02), Vector3(-h, h, -0.02), true)


## A quad whose first corner (or, for a disc, its middle) is the hot core.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, disc := false) -> void:
	var cols := [CORE, EDGE.lerp(CORE, 0.6), EDGE, EDGE.lerp(CORE, 0.6)]
	if disc:
		cols = [Color(CORE, 0.5), Color(CORE, 0.5), Color(CORE, 0.5), Color(CORE, 0.5)]
	var pts := [a, b, c, d]
	for tri in [[0, 1, 2], [0, 2, 3]]:
		for i: int in tri:
			st.set_color(cols[i])
			st.add_vertex(pts[i])


## A shot: show it, rolled and sized at random.
func fire(rng: RandomNumberGenerator) -> void:
	if shape == Weapons.Flash.NONE:
		return
	_t = Config.MUZZLE_FLASH_TIME
	visible = true
	rotation.z = rng.randf() * TAU
	scale = Vector3.ONE * rng.randf_range(0.8, 1.25)


func step(delta: float) -> void:
	if _t > 0.0:
		_t -= delta
		if _t <= 0.0:
			visible = false
