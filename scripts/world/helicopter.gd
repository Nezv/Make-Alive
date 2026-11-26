class_name Helicopter
extends Node3D
## The extraction helicopter's look, built from boxes: a military transport with sliding side doors,
## skids, a four-blade main rotor (a translucent disc at speed, the blades sagging when stopped), a tail
## rotor, red / green nav lights, a white strobe, a red beacon sweeping the ground and a door gunner.
## `apply(pose, dt, time)` puts it where `HeliFlight.pose` says; nothing here decides anything.
## Faces -Z, stands on its skids at y = 0.

## Sound names for S087 to fill in (Sfx.play ignores names nobody registered yet).
const SOUNDS := { "rotor": "heli_rotor", "turbine": "heli_turbine", "touchdown": "heli_touchdown",
	"liftoff": "heli_liftoff", "gunner": "heli_gunner" }
const OLIVE := Color("4a5236")
const OLIVE_DARK := Color("353b27")
const GLASS := Color("1b2a33")
const STEEL := Color("5a5e64")
const DARK := Color("1b1b1e")
const DOOR_SLIDE := 1.6
const SINK := 0.12       ## metres the body sinks on its skids when down
const DROOP := 0.22      ## radians the blade tips sag when stopped
const BLADE_LEN := 7.5

var body: Node3D         ## everything above the skids (sinks when they compress)
var main_rotor: Node3D
var blades: Node3D       ## the blades themselves (shown below the blur speed)
var blur: MeshInstance3D
var tail_rotor: Node3D
var door_l: MeshInstance3D
var door_r: MeshInstance3D
var skids: MeshInstance3D
var nav_red: MeshInstance3D
var nav_green: MeshInstance3D
var strobe: MeshInstance3D
var beacon: SpotLight3D
var gunner: MeshInstance3D
var seat: Node3D         ## where a boarded player's eyes go
var rotor_speed := 0.0
var _flat: MeshInstance3D
var _droop: MeshInstance3D
var _door_open := 0.0
var _phase := -1


func _init() -> void:
	name = "Helicopter"
	body = Node3D.new()
	add_child(body)
	var b := MeshKit.Builder.new()
	b.box(Vector3(2.4, 2.2, 5.0), Vector3(0, 1.65, 0), OLIVE)                          # cabin
	b.box(Vector3(2.2, 1.7, 1.8), Vector3(0, 1.5, -3.3), OLIVE)                         # nose
	b.box(Vector3(2.0, 1.0, 0.1), Vector3(0, 2.0, -4.15), GLASS, Basis(Vector3.RIGHT, -0.5)) # windscreen
	b.box(Vector3(0.08, 0.8, 1.4), Vector3(-1.12, 1.95, -3.2), GLASS)                   # side windows
	b.box(Vector3(0.08, 0.8, 1.4), Vector3(1.12, 1.95, -3.2), GLASS)
	b.box(Vector3(1.7, 0.85, 2.8), Vector3(0, 3.1, 0.3), OLIVE_DARK)                    # engine housing
	b.box(Vector3(0.3, 0.6, 0.3), Vector3(0, 3.7, 0), STEEL)                            # mast
	b.box(Vector3(0.75, 0.7, 6.2), Vector3(0, 2.35, 5.5), OLIVE)                        # tail boom
	b.box(Vector3(0.15, 1.9, 1.3), Vector3(0, 3.1, 8.3), OLIVE_DARK, Basis(Vector3.RIGHT, -0.25)) # fin
	b.box(Vector3(2.6, 0.1, 0.7), Vector3(0, 2.4, 7.7), OLIVE_DARK)                     # stabiliser
	b.box(Vector3(2.3, 0.05, 4.6), Vector3(0, 0.56, 0.1), OLIVE_DARK)                   # belly
	b.box(Vector3(0.4, 0.3, 0.3), Vector3(0, 0.5, 1.6), Color("5a1010"))                # beacon housing
	body.add_child(b.instance(null, true))

	main_rotor = Node3D.new()
	main_rotor.position = Vector3(0, 4.05, 0)
	body.add_child(main_rotor)
	blades = Node3D.new()
	main_rotor.add_child(blades)
	_flat = _blade_mesh(0.0)
	_droop = _blade_mesh(DROOP)
	blades.add_child(_flat)
	blades.add_child(_droop)
	blur = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = BLADE_LEN
	disc.bottom_radius = BLADE_LEN
	disc.height = 0.02
	disc.radial_segments = 24
	disc.rings = 1
	blur.mesh = disc
	var bm := MeshKit.unshaded(Color(0.08, 0.08, 0.09), 0.22)
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	blur.material_override = bm
	blur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	main_rotor.add_child(blur)

	tail_rotor = Node3D.new()
	tail_rotor.position = Vector3(0.18, 3.15, 8.5)
	body.add_child(tail_rotor)
	var tb := MeshKit.Builder.new()
	tb.box(Vector3(0.05, 2.3, 0.22), Vector3.ZERO, DARK)
	tb.box(Vector3(0.05, 0.22, 2.3), Vector3.ZERO, DARK)
	tail_rotor.add_child(tb.instance(null, false))

	door_l = _slab(Vector3(0.08, 1.6, 1.8), OLIVE_DARK)
	door_l.position = Vector3(-1.25, 1.55, 0.3)
	body.add_child(door_l)
	door_r = _slab(Vector3(0.08, 1.6, 1.8), OLIVE_DARK)
	door_r.position = Vector3(1.25, 1.55, 0.3)
	body.add_child(door_r)

	var sk := MeshKit.Builder.new()
	for x in [-1.3, 1.3]:
		sk.box(Vector3(0.12, 0.12, 4.6), Vector3(x, 0.06, 0.0), STEEL)
		sk.box(Vector3(0.12, 0.12, 0.5), Vector3(x, 0.2, -2.45), STEEL, Basis(Vector3.RIGHT, 0.6)) # upturned toe
		for z in [-1.2, 1.2]:
			sk.box(Vector3(0.1, 0.5, 0.1), Vector3(x * 0.9, 0.35, z), STEEL, Basis(Vector3.FORWARD, x * 0.25))
	skids = sk.instance(null, true)
	add_child(skids)

	nav_red = _lamp(Color(1.0, 0.1, 0.08), Vector3(-1.3, 1.3, -1.6))
	nav_green = _lamp(Color(0.1, 1.0, 0.2), Vector3(1.3, 1.3, -1.6))
	strobe = _lamp(Color(1, 1, 1), Vector3(0, 4.1, 8.7))
	beacon = SpotLight3D.new()
	beacon.light_color = Color(1.0, 0.15, 0.1)
	beacon.light_energy = 3.0
	beacon.spot_range = 30.0
	beacon.spot_angle = 18.0
	beacon.shadow_enabled = false
	beacon.position = Vector3(0, 0.45, 1.6)
	beacon.rotation = Vector3(-1.1, 0, 0) # down and ahead; it sweeps round
	body.add_child(beacon)

	var g := MeshKit.Builder.new() # the door gunner in the left door, his gun pointing out
	g.box(Vector3(0.5, 0.75, 0.38), Vector3(-0.75, 1.75, 0.6), Color("2e3324"))
	g.box(Vector3(0.26, 0.28, 0.26), Vector3(-0.78, 2.3, 0.6), Color("8a6e58"))
	g.box(Vector3(0.32, 0.16, 0.32), Vector3(-0.78, 2.47, 0.6), OLIVE_DARK)                 # helmet
	g.box(Vector3(1.2, 0.09, 0.09), Vector3(-1.45, 1.95, 0.6), DARK)                         # gun
	g.box(Vector3(0.28, 0.22, 0.14), Vector3(-1.0, 1.9, 0.6), DARK)
	gunner = g.instance(null, false)
	body.add_child(gunner)

	seat = Node3D.new()
	seat.position = Vector3(0.5, 1.75, 0.9)
	body.add_child(seat)


func _blade_mesh(droop: float) -> MeshInstance3D:
	var b := MeshKit.Builder.new()
	for k in 4:
		var turn := Basis(Vector3.UP, k * PI / 2.0)
		var half := BLADE_LEN * 0.5
		b.box(Vector3(0.45, 0.06, half), turn * Vector3(0, -sin(droop) * half * 0.25, -half * 0.5), DARK,
			turn * Basis(Vector3.RIGHT, droop * 0.5))
		b.box(Vector3(0.45, 0.06, half), turn * Vector3(0, -sin(droop) * half, -half * 1.45), DARK,
			turn * Basis(Vector3.RIGHT, droop))
	b.box(Vector3(0.5, 0.25, 0.5), Vector3.ZERO, STEEL)
	return b.instance(null, true)


func _slab(size: Vector3, color: Color) -> MeshInstance3D:
	var b := MeshKit.Builder.new()
	b.box(size, Vector3.ZERO, color)
	return b.instance(null, true)


func _lamp(color: Color, at: Vector3) -> MeshInstance3D:
	var b := MeshKit.Builder.new()
	b.box(Vector3(0.14, 0.14, 0.14), Vector3.ZERO, color)
	var m := b.instance(MeshKit.emissive(color, 4.0), false)
	m.position = at
	body.add_child(m)
	return m


## Spin the rotors at `speed` (0..1) for `dt` seconds: blades below the blur speed, a disc above it,
## the blades sagging when stopped.
func set_rotor(speed: float, dt: float) -> void:
	rotor_speed = speed
	main_rotor.rotation.y = wrapf(main_rotor.rotation.y + speed * Config.HELI_ROTOR_RPS * TAU * dt, -PI, PI)
	tail_rotor.rotation.x = wrapf(tail_rotor.rotation.x + speed * Config.HELI_ROTOR_RPS * 5.0 * TAU * dt, -PI, PI)
	blur.visible = speed > Config.HELI_BLUR_AT
	blades.visible = not blur.visible
	_droop.visible = speed < 0.05
	_flat.visible = not _droop.visible


## How far the blade tips sag now (radians, negative = down).
func blade_droop() -> float:
	return -DROOP if _droop.visible else 0.0


## Put it where the flight says: place, heading, nose and bank, the skids squashed, doors open while it
## is low, lights blinking.
func apply(pose: Dictionary, dt: float, time: float) -> void:
	position = pose.pos
	rotation = Vector3(pose.pitch, pose.yaw, -float(pose.roll))
	set_rotor(pose.rotor, dt)
	body.position.y = -SINK * float(pose.compress)
	var ph: int = pose.phase
	var want_open := 1.0 if ph == HeliFlight.Phase.LANDED or (ph == HeliFlight.Phase.DESCEND and float(pose.pos.y) - _ground() < 8.0) else 0.0
	_door_open = move_toward(_door_open, want_open, dt / 1.2)
	door_l.position.z = 0.3 + DOOR_SLIDE * _door_open
	door_r.position.z = 0.3 + DOOR_SLIDE * _door_open
	strobe.visible = fmod(time, 1.2) < 0.07
	beacon.rotation.y = fmod(time * 3.0, TAU)
	if ph != _phase:
		if ph == HeliFlight.Phase.LANDED:
			Sfx.play(SOUNDS.touchdown, global_position)
		elif ph == HeliFlight.Phase.DEPART:
			Sfx.play(SOUNDS.liftoff, global_position)
		_phase = ph


var ground_y := 0.0 ## the landing point's height (the flight's lz.y)


func _ground() -> float:
	return ground_y


## Where someone has to stand to get in: just outside the left door, on the ground.
func door_point() -> Vector3:
	var p := global_transform * Vector3(-2.2, 0.0, 0.9)
	return Vector3(p.x, ground_y, p.z)


## The muzzle of the door gun.
func gun_muzzle() -> Vector3:
	return body.global_transform * Vector3(-2.05, 1.95, 0.6)
