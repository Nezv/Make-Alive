class_name Helicopter
extends Node3D
## The helicopter that comes to take everyone out, as every peer sees it. Cosmetic and local
## like the extraction zone: nothing about it is sent. Each peer works out where it is from the
## mission's state, which it already has (Game._update_helicopter): while the last wave's
## helicopter clock runs it is `arrive(seconds flown)`, while the extraction runs it is `hover`,
## and once the mission is won it is `depart`. Its spot comes from the map's data
## (`heli`: { at, yaw, floor }), the point its skids hang at in the hover.
##
## The flight is a fixed path in the spot's own space (`flight_pose`): first seen far behind
## and high, it comes in, circles its spot once, flares nose-up and settles. Its attitude comes
## from the path itself: it banks into turns, dips its nose to speed up and lifts it to slow
## down. Then it sways in the hover, rotor wash raising dust below it.

var land := Transform3D.IDENTITY  ## its spot: where it hovers, facing -Z
var wash_y := 0.0                 ## height of the ground (or deck) its rotor wash blows across
var fx: Fx                        ## for the wash; none in some tests
var rotor_speed := Config.HELI_ROTOR_RPS
var mode := ""                    ## "arrive", "hover" or "depart"

var blades: MeshInstance3D        ## the main rotor's blades, drawn when it turns slowly
var blur: MeshInstance3D          ## the translucent disc drawn instead when it is up to speed
var nav_red: MeshInstance3D
var nav_green: MeshInstance3D
var strobe: MeshInstance3D
var beacon: MeshInstance3D
var searchlight: SpotLight3D

var _rotor := Node3D.new()
var _tail := Node3D.new()
var _beacon_mat: StandardMaterial3D
var _flown := -1.0
var _hover_t := 0.0
var _depart_t := 0.0
var _clock := 0.0
var _wash_t := 0.0


## The path: where it is at each moment of the flight, in its spot's space. First seen behind
## and high, in past the right of the spot, once round it the other way, then straight in.
static func _keys() -> Array:
	var r := Config.HELI_CIRCLE
	var f := Config.HELI_FLIGHT
	return [
		[0.0, Config.HELI_FROM],
		[0.35 * f, Vector3(0, 70, r * 2.2)],
		[0.5 * f, Vector3(r, 50, 0)],
		[0.62 * f, Vector3(0, 45, -r)],
		[0.74 * f, Vector3(-r, 38, 0)],
		[0.82 * f, Vector3(0, 22, r * 0.8)],
		[0.9 * f, Vector3(0, 5, 16)],
		[f, Vector3.ZERO],
	]


## Position along the path at `t` seconds, in the spot's space (a Hermite spline through the
## keys that comes to rest at the end).
static func path_point(t: float) -> Vector3:
	var keys := _keys()
	t = clampf(t, 0.0, Config.HELI_FLIGHT)
	var n := keys.size()
	var i := 0
	while i < n - 2 and t > float(keys[i + 1][0]):
		i += 1
	var t0: float = keys[i][0]
	var t1: float = keys[i + 1][0]
	var p0: Vector3 = keys[i][1]
	var p1: Vector3 = keys[i + 1][1]
	var h := t1 - t0
	var s := (t - t0) / h
	var m0 := _tangent(keys, i) * h
	var m1 := _tangent(keys, i + 1) * h
	var s2 := s * s
	var s3 := s2 * s
	return (2 * s3 - 3 * s2 + 1) * p0 + (s3 - 2 * s2 + s) * m0 + (-2 * s3 + 3 * s2) * p1 + (s3 - s2) * m1


static func _tangent(keys: Array, i: int) -> Vector3:
	var n := keys.size()
	if i == n - 1:
		return Vector3.ZERO # it comes to rest
	if i == 0:
		return ((keys[1][1] as Vector3) - (keys[0][1] as Vector3)) / (float(keys[1][0]) - float(keys[0][0]))
	return ((keys[i + 1][1] as Vector3) - (keys[i - 1][1] as Vector3)) / (float(keys[i + 1][0]) - float(keys[i - 1][0]))


## Where it is and how it sits at `t` seconds into the flight, in the world, for spot `at`.
static func flight_pose(t: float, at: Transform3D) -> Transform3D:
	var f := Config.HELI_FLIGHT
	if t >= f:
		return at
	var p := path_point(t)
	var dt := 0.25
	var v := (path_point(t + dt) - path_point(t - dt)) / (2.0 * dt)
	var a := (path_point(t + dt) - 2.0 * p + path_point(t - dt)) / (dt * dt)
	var flat := Vector3(v.x, 0, v.z)
	var speed := flat.length()
	var fwd := Vector3.FORWARD
	if speed > 0.01:
		fwd = Vector3.FORWARD.lerp(flat / speed, clampf((speed - 1.0) / 6.0, 0.0, 1.0)).normalized()
	var right := Vector3(-fwd.z, 0, fwd.x)
	var settle := clampf((f - t) / 1.5, 0.0, 1.0) # level out in the last moments
	var pitch := clampf(-a.dot(fwd) * 0.05, -0.3, 0.35) - clampf(speed * 0.003, 0.0, 0.1)
	var roll := clampf(a.dot(right) * 0.07, -0.6, 0.6)
	var basis := Basis(Vector3.UP, atan2(-fwd.x, -fwd.z)) * Basis(Vector3.RIGHT, pitch * settle) * Basis(Vector3.FORWARD, roll * settle)
	return at * Transform3D(basis, p)


## Build it at its spot. `kit` raises the rotor wash; `floor_y` is what the wash blows across.
func setup(at: Transform3D, kit: Fx = null, floor_y := NAN) -> void:
	land = at
	fx = kit
	wash_y = at.origin.y if is_nan(floor_y) else floor_y
	name = "Helicopter"
	transform = at
	var b := MeshKit.Builder.new()
	Props.transport_helicopter(b, Transform3D.IDENTITY)
	var body := b.instance()
	add_child(body)
	# Main rotor: blades and their blur.
	_rotor.position = Props.HELI_HUB
	add_child(_rotor)
	var rb := MeshKit.Builder.new()
	Props.rotor(rb, 7.4, 4, 0.5)
	blades = rb.instance()
	_rotor.add_child(blades)
	var disc := MeshKit.Builder.new()
	disc.cyl(7.4, 0.04, Vector3.ZERO, Color.WHITE, 24)
	blur = disc.instance(MeshKit.unshaded(Color(0.12, 0.13, 0.12), 0.35), false)
	_rotor.add_child(blur)
	var hub := MeshKit.Builder.new()
	hub.box(Vector3(0.5, 0.25, 0.5), Vector3.ZERO, Props.STEEL)
	_rotor.add_child(hub.instance())
	# Tail rotor.
	_tail.position = Props.HELI_TAIL_HUB
	add_child(_tail)
	var tb := MeshKit.Builder.new()
	Props.rotor(tb, 1.4, 4, 0.22, true)
	_tail.add_child(tb.instance())
	# Lights: red to port (left), green to starboard, a white strobe on the tail, a red beacon on top.
	nav_red = _lamp(Vector3(-1.25, 1.2, -2.2), Color(1.0, 0.1, 0.08))
	nav_green = _lamp(Vector3(1.25, 1.2, -2.2), Color(0.1, 1.0, 0.3))
	strobe = _lamp(Vector3(0, 4.2, 9.9), Color.WHITE)
	beacon = _lamp(Vector3(0, 3.35, 1.6), Color(1.0, 0.15, 0.1))
	_beacon_mat = beacon.material_override
	searchlight = SpotLight3D.new()
	searchlight.position = Vector3(0, 0.7, -4.6)
	searchlight.rotation = Vector3(-0.9, 0, 0)
	searchlight.spot_range = 90.0
	searchlight.spot_angle = 16.0
	searchlight.light_energy = 6.0
	searchlight.light_color = Color(1.0, 0.96, 0.85)
	searchlight.shadow_enabled = false
	add_child(searchlight)
	_spin(0.0)


func _lamp(at: Vector3, color: Color) -> MeshInstance3D:
	var b := MeshKit.Builder.new()
	b.box(Vector3(0.18, 0.18, 0.18), at, Color.WHITE)
	var m := b.instance(MeshKit.emissive(color, 4.0), false)
	add_child(m)
	return m


## On the way in: `flown` seconds since it was first seen (before 0 it is not seen yet).
func arrive(flown: float) -> void:
	mode = "arrive"
	visible = flown >= 0.0
	var delta := clampf(flown - _flown, 0.0, 0.5) if _flown >= 0.0 else 0.0
	_flown = flown
	transform = flight_pose(maxf(0.0, flown), land)
	_spin(delta)


## Holding over its spot for the boarding: drifts a little, never still.
func hover(delta: float) -> void:
	mode = "hover"
	visible = true
	_hover_t += delta
	var s := Config.HELI_SWAY
	var k := _hover_t
	var drift := Vector3(sin(k * 1.3) * s, sin(k * 0.9 + 1.0) * s * 0.4, sin(k * 0.7 + 2.0) * s)
	var sway := Basis(Vector3.FORWARD, sin(k * 1.1) * 0.025) * Basis(Vector3.RIGHT, sin(k * 0.8 + 0.5) * 0.02)
	transform = land * Transform3D(sway, drift)
	_spin(delta)


## Everyone is aboard: it lifts off, dips its nose and climbs away.
func depart(delta: float) -> void:
	mode = "depart"
	visible = true
	_depart_t += delta
	var s := _depart_t
	var p := Vector3(0, Config.HELI_CLIMB * s + 0.4 * s * s, -1.6 * s * s)
	transform = land * Transform3D(Basis(Vector3.RIGHT, -minf(0.25, s * 0.08)), p)
	_spin(delta)


## Turn the rotors, blink the lights, raise the wash.
func _spin(delta: float) -> void:
	_clock += delta
	_rotor.rotate_y(rotor_speed * TAU * delta)
	_tail.rotate_x(rotor_speed * 5.0 * TAU * delta)
	var fast := rotor_speed > Config.HELI_BLUR_RPS
	blur.visible = fast
	blades.visible = not fast
	strobe.visible = fmod(_clock, Config.HELI_STROBE_EVERY) < 0.08
	_beacon_mat.emission_energy_multiplier = 1.0 + 5.0 * maxf(0.0, sin(_clock * TAU * 0.8))
	if fx == null or delta <= 0.0:
		return
	var above := transform.origin.y - wash_y
	if above > Config.HELI_WASH_HEIGHT or above < -2.0:
		return
	_wash_t -= delta
	var strength := 1.0 - above / Config.HELI_WASH_HEIGHT
	while _wash_t <= 0.0:
		_wash_t += Config.HELI_WASH_EVERY
		var a := randf() * TAU # cosmetic and local: no need to agree with other peers
		var out := Vector3(cos(a), 0.05, sin(a))
		var at := Vector3(transform.origin.x, wash_y + 0.3, transform.origin.z) + out * randf_range(2.0, 5.0)
		fx.burst(Fx.Layer.SMOKE, at, out, 1, { "speed": 9.0 * strength + 2.0, "spread": 0.15, "life": 1.4,
			"size": 0.6, "size_end": 3.0, "color": Color(0.55, 0.52, 0.46, 0.35 * strength), "gravity": 0.0, "drag": 1.6 })
