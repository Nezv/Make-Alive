class_name Casings
extends Node3D
## Spent casings: thrown from a gun's ejection port, a bounce with a tumble, a smaller one, then they lie
## still for `Config.CASING_REST` and sink away over `CASING_SINK`. A tink on each bounce. One MultiMesh
## per kind (pistol, rifle, shotgun hull, sniper case), `Config.CASING_MAX` at most (the oldest gives
## way). Cosmetic and local.

const COLORS := {
	Weapons.Casing.PISTOL: Color("c9a24a"),
	Weapons.Casing.RIFLE: Color("c99a3e"),
	Weapons.Casing.SHELL: Color("b0282a"),
	Weapons.Casing.SNIPER: Color("c7a252"),
	Weapons.Casing.MAG: Color("2a2b2d"),
}
## [radius, length] per kind.
const SIZES := {
	Weapons.Casing.PISTOL: [0.0055, 0.019],
	Weapons.Casing.RIFLE: [0.0065, 0.039],
	Weapons.Casing.SHELL: [0.011, 0.07],
	Weapons.Casing.SNIPER: [0.0085, 0.069],
	Weapons.Casing.MAG: [0.022, 0.15],
}
const BOUNCE := 0.35     ## share of the fall speed it bounces back with
const GRAVITY := 9.8

static var _meshes := {}

var tinks := 0           ## bounces heard (tests)
var ground := Callable() ## map.ground_y (unset: y = 0)
var _items: Array[Dictionary] = [] ## { kind, pos, vel, basis, spin, bounces, rest (-1 flying), floor }
var _mms := {}           ## kind -> MultiMesh


func _init() -> void:
	name = "Casings"
	for kind: int in COLORS:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh_for(kind)
		mm.instance_count = Config.CASING_MAX
		mm.visible_instance_count = 0
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.custom_aabb = AABB(Vector3(-2000, -200, -2000), Vector3(4000, 600, 4000))
		add_child(mmi)
		_mms[kind] = mm


## A casing's mesh: a short cylinder along Z (a shotgun hull has a brass base).
static func mesh_for(kind: int) -> ArrayMesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var b := MeshKit.Builder.new()
	var r: float = SIZES[kind][0]
	var l: float = SIZES[kind][1]
	var col: Color = COLORS[kind]
	b.cyl(r, l, Vector3.ZERO, col, 6, Basis(Vector3.RIGHT, PI / 2.0))
	if kind == Weapons.Casing.SHELL:
		b.cyl(r * 1.08, l * 0.25, Vector3(0, 0, l * 0.4), Color("c9a24a"), 6, Basis(Vector3.RIGHT, PI / 2.0))
	var m := b.mesh()
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.metallic = 0.7 if kind != Weapons.Casing.SHELL else 0.1
	mat.roughness = 0.35
	m.surface_set_material(0, mat)
	_meshes[kind] = m
	return m


func spawn(at: Vector3, vel: Vector3, kind: int) -> void:
	var spin := Vector3(randf_range(-30, 30), randf_range(-12, 12), randf_range(-30, 30))
	var floor_y: float = ground.call(at) if ground.is_valid() else 0.0
	_items.append({ "kind": kind, "pos": at, "vel": vel, "basis": Basis.IDENTITY, "spin": spin, "bounces": 0,
		"rest": -1.0, "floor": floor_y })
	while _items.size() > Config.CASING_MAX:
		_items.pop_front()


func alive() -> int:
	return _items.size()


## Dropped magazines lying about.
func mags() -> int:
	return _items.filter(func(it: Dictionary) -> bool: return it.kind == Weapons.Casing.MAG).size()


func bounces(i: int) -> int:
	return _items[i].bounces


func resting(i: int) -> bool:
	return float(_items[i].rest) >= 0.0


func position_of(i: int) -> Vector3:
	return _items[i].pos


func step(delta: float) -> void:
	for it in _items:
		var rest: float = it.rest
		if rest >= 0.0: # lying still, then sinking away
			it.rest = rest + delta
			if float(it.rest) > Config.CASING_REST:
				it.pos = Vector3(it.pos.x, float(it.floor) - (float(it.rest) - Config.CASING_REST) / Config.CASING_SINK * 0.03, it.pos.z)
			continue
		var v: Vector3 = it.vel
		v.y -= GRAVITY * delta
		var p: Vector3 = it.pos + v * delta
		it.basis = (it.basis as Basis).rotated((it.spin as Vector3).normalized(), (it.spin as Vector3).length() * delta).orthonormalized() \
			if (it.spin as Vector3).length() > 0.01 else it.basis
		var floor_y: float = it.floor
		if p.y <= floor_y and v.y < 0.0:
			p.y = floor_y
			it.bounces = int(it.bounces) + 1
			tinks += 1
			Sfx.play("tink", p, 0.15, -6.0, 0.45 if it.kind == Weapons.Casing.MAG else (0.8 if it.kind == Weapons.Casing.SHELL else 1.0 + 0.15 * float(it.kind)))
			if int(it.bounces) >= 2: # down for good: lying on its side
				v = Vector3.ZERO
				it.rest = 0.0
				var yaw: float = (it.basis as Basis).get_euler().y
				it.basis = Basis(Vector3.UP, yaw)
			else:
				v = Vector3(v.x * 0.5, -v.y * BOUNCE, v.z * 0.5)
				it.spin = (it.spin as Vector3) * 0.6
		it.vel = v
		it.pos = p
	_items = _items.filter(func(it: Dictionary) -> bool:
		return float(it.rest) < Config.CASING_REST + Config.CASING_SINK)


func _process(delta: float) -> void:
	step(delta)
	var counts := {}
	for kind: int in _mms:
		counts[kind] = 0
	for it in _items:
		var kind: int = it.kind
		var mm: MultiMesh = _mms[kind]
		var r: float = SIZES[kind][0]
		mm.set_instance_transform(counts[kind], Transform3D(it.basis, it.pos + Vector3(0, r, 0)))
		counts[kind] += 1
	for kind: int in _mms:
		(_mms[kind] as MultiMesh).visible_instance_count = counts[kind]
