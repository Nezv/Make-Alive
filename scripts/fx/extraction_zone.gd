class_name ExtractionZone
extends Node3D
## How the open way out looks, on every peer (cosmetic, local, built from the map's own data):
## a green flare's smoke rising as a tall column that leans with the wind, a ring of light strips
## round the zone's edge that pulses, and sparks drifting up inside it. The smoke and sparks come
## from the pooled effects kit, so they share its caps.

const GREEN := Color(0.35, 1.0, 0.45)
const STRIP := Vector3(0.9, 0.05, 0.12)

var zone := ""
var fx: Fx
var _ring: MeshInstance3D
var _material: StandardMaterial3D
var _strips := 0
var _t := 0.0
var _puff_t := 0.0
var _spark_t := 0.0
var _half := Vector2.ONE ## half the zone's size on the ground (x, z), for where sparks rise


## Build it for zone `id` of `data`, using `kit` for the particles.
static func create(data: MapData, id: String, kit: Fx, ground_y: float) -> ExtractionZone:
	var z := ExtractionZone.new()
	z.zone = id
	z.fx = kit
	var c := data.zone_center(id)
	z.position = Vector3(c.x, ground_y, c.z)
	z._build(data.zones[id])
	return z


func _build(def: Dictionary) -> void:
	var outline: Array = []
	if def.has("box"):
		var h: Vector3 = def.box[1] * 0.5
		outline = [Vector2(-h.x, -h.z), Vector2(h.x, -h.z), Vector2(h.x, h.z), Vector2(-h.x, h.z)]
		_half = Vector2(h.x, h.z)
	else:
		var c := Vector2(position.x, position.z)
		for p: Vector2 in def.polygon:
			outline.append(p - c)
			_half = _half.max((p - c).abs())
	var b := MeshKit.Builder.new()
	for i in outline.size(): # dashed strips along each edge
		var a: Vector2 = outline[i]
		var e: Vector2 = outline[(i + 1) % outline.size()]
		var n := maxi(1, floori(a.distance_to(e) / (STRIP.x * 2.0)))
		var yaw := -atan2(e.y - a.y, e.x - a.x)
		for k in n:
			var p := a.lerp(e, (k + 0.5) / n)
			b.box(STRIP, Vector3(p.x, STRIP.y / 2.0, p.y), Color.WHITE, Basis(Vector3.UP, yaw))
			_strips += 1
	_material = MeshKit.emissive(GREEN, 2.0)
	_ring = b.instance(_material, false)
	add_child(_ring)


func ring_count() -> int:
	return _strips


## How bright the ring is right now (0..1 of its range).
func glow() -> float:
	return 0.5 + 0.5 * sin(_t * TAU / Config.EXTRACT_PULSE)


func _process(delta: float) -> void:
	step(delta)


## Advance by `delta`: pulse the ring, feed the column and the sparks.
func step(delta: float) -> void:
	_t += delta
	_material.emission_energy_multiplier = lerpf(0.6, 3.0, glow())
	if fx == null:
		return
	var base := global_position if is_inside_tree() else position
	_puff_t -= delta
	while _puff_t <= 0.0:
		_puff_t += Config.EXTRACT_PUFF_EVERY
		# Rises at about height / life; the wind pushes it sideways as it goes.
		var rise := Config.EXTRACT_SMOKE_HEIGHT / Config.EXTRACT_SMOKE_LIFE
		fx.burst(Fx.Layer.SMOKE, base + Vector3(0, 0.3, 0), Vector3.UP * rise + Config.EXTRACT_WIND, 1, {
			"speed": (Vector3.UP * rise + Config.EXTRACT_WIND).length(), "spread": 0.06, "life": Config.EXTRACT_SMOKE_LIFE,
			"size": 0.6, "size_end": 4.5, "color": Color(0.45, 0.9, 0.5, 0.55), "color_end": Color(0.6, 0.75, 0.62, 0.0),
			"gravity": 0.0, "drag": 0.0 })
	_spark_t -= delta
	while _spark_t <= 0.0:
		_spark_t += Config.EXTRACT_SPARK_EVERY
		var at := base + Vector3(randf_range(-_half.x, _half.x), 0.1, randf_range(-_half.y, _half.y))
		fx.burst(Fx.Layer.GLOW, at, Vector3.UP, 1, { "speed": 0.8, "spread": 0.2, "life": 2.0, "size": 0.05,
			"size_end": 0.02, "color": GREEN, "gravity": 0.0, "drag": 0.0 })
