class_name NoiseRings
extends MeshInstance3D
## Debug (`--noise`): a ring that grows out to each noise's reach from where it happened, then is gone.
## One mesh for all of them, capped (Config.NOISE_RINGS_MAX), host only.

const SEGMENTS := 40
const COLOR := Color(1.0, 0.85, 0.2)

var _rings: Array = [] ## [{ at, loudness, t }]
var _mesh := ImmediateMesh.new()


func _init() -> void:
	mesh = _mesh
	material_override = MeshKit.unshaded(COLOR)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func add(at: Vector3, loudness: float) -> void:
	if _rings.size() >= Config.NOISE_RINGS_MAX:
		_rings.pop_front()
	_rings.append({ "at": at, "loudness": loudness, "t": 0.0 })


func count() -> int:
	return _rings.size()


## How far ring `i` has spread so far.
func radius_of(i: int) -> float:
	var r: Dictionary = _rings[i]
	return r.loudness * clampf(r.t / Config.NOISE_RING_TIME, 0.0, 1.0)


func _process(delta: float) -> void:
	for r: Dictionary in _rings:
		r.t += delta
	_rings = _rings.filter(func(r: Dictionary) -> bool: return r.t < Config.NOISE_RING_TIME)
	_mesh.clear_surfaces()
	if _rings.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in _rings.size():
		var at: Vector3 = _rings[i].at
		var radius := radius_of(i)
		for s in SEGMENTS:
			var a := TAU * s / SEGMENTS
			var b := TAU * (s + 1) / SEGMENTS
			_mesh.surface_add_vertex(Vector3(at.x + cos(a) * radius, at.y + 0.15, at.z + sin(a) * radius))
			_mesh.surface_add_vertex(Vector3(at.x + cos(b) * radius, at.y + 0.15, at.z + sin(b) * radius))
	_mesh.surface_end()
