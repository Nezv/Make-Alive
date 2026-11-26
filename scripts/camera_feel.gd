class_name CameraFeel
## How the first-person view moves, no nodes: a figure-eight bob in step with the feet (bigger when
## sprinting; a step counted at each low point), the gun lagging the mouse on a spring (more for heavy
## guns), a degree or two of tilt when strafing, the field of view widening while sprinting and pinching
## on a sniper shot, shakes mixed and capped (explosions, hits, leapers landing, the helicopter's
## rumble). Everything is scaled by `scale` (the "camera_motion" setting); at 0 nothing moves.
## The player reads `offset` (camera space), `angles` (pitch, yaw, roll), `fov_add` and `sway`.

var scale := 1.0
var offset := Vector3.ZERO
var angles := Vector3.ZERO
var fov_add := 0.0
var sway := Vector2.ZERO   ## the gun trailing the view (yaw, pitch radians), for the viewmodel
var step_count := 0
var rumble := 0.0          ## a steady shake that lasts while it is set (the helicopter overhead)

var _phase := 0.0
var _amount := 0.0
var _sway := Vector2.ZERO
var _sway_vel := Vector2.ZERO
var _tilt := 0.0
var _fov := 0.0
var _pinch := 0.0
var _shakes: Array[Dictionary] = [] ## { amp, left, total }
var _t := 0.0


func step(dt: float, speed: float, sprinting: bool, strafe: float, mouse: Vector2, weight: float) -> void:
	_t += dt
	# Bob: side to side once per two steps, up and down once per step; the feet land at the low points.
	var want := clampf(speed / Config.WALK_SPEED, 0.0, 1.0) * (Config.CAM_BOB_SPRINT if sprinting else 1.0)
	_amount = move_toward(_amount, want, dt * 4.0)
	var before := floori((_phase + PI / 2.0) / PI)
	_phase += dt * speed * Config.CAM_BOB_RATE
	if floori((_phase + PI / 2.0) / PI) > before:
		step_count += 1
	var bob := Vector3(sin(_phase) * Config.CAM_BOB_X, cos(2.0 * _phase) * Config.CAM_BOB_Y, 0.0) * _amount
	# The gun trails the mouse, then springs home.
	_sway_vel += -mouse * Config.CAM_SWAY_GAIN * weight
	_sway_vel += (-_sway * Config.CAM_SWAY_K - _sway_vel * Config.CAM_SWAY_D) * dt
	_sway = (_sway + _sway_vel * dt).limit_length(Config.CAM_SWAY_MAX)
	# Lean a little into a strafe.
	_tilt = lerpf(_tilt, -strafe * Config.CAM_TILT * clampf(speed / Config.WALK_SPEED, 0.0, 1.0), 1.0 - exp(-8.0 * dt))
	# Wider while sprinting; a pinch on a sniper shot that lets go fast.
	var open := Config.CAM_SPRINT_FOV if sprinting and speed > Config.WALK_SPEED * 0.9 else 0.0
	_fov = move_toward(_fov, open, dt * Config.CAM_SPRINT_FOV / 0.4)
	_pinch = move_toward(_pinch, 0.0, dt * 12.0)
	# Shakes: each dies away over its time; together never more than the cap.
	for s in _shakes:
		s.left = float(s.left) - dt
	_shakes = _shakes.filter(func(s: Dictionary) -> bool: return float(s.left) > 0.0)
	var shake := shake_amount()
	var jolt := Vector3(sin(_t * 41.0), sin(_t * 53.0 + 1.0), 0.0) * shake
	offset = (bob + jolt) * scale
	angles = Vector3(sin(_t * 37.0 + 2.0) * shake * 0.4, 0.0, _tilt + sin(_t * 29.0) * shake * 0.5) * scale
	fov_add = (_fov + _pinch) * scale
	sway = _sway * scale


## A sniper shot: the view pinches in for a moment.
func pinch() -> void:
	_pinch = Config.CAM_PINCH


## A jolt of `amp` metres dying away over `seconds`.
func add_shake(amp: float, seconds: float) -> void:
	_shakes.append({ "amp": amp, "left": seconds, "total": seconds })
	while _shakes.size() > Config.CAM_SHAKES_MAX:
		_shakes.pop_front()


func clear_shakes() -> void:
	_shakes.clear()


## How hard the view shakes now (metres), every source mixed, capped, scaled.
func shake_amount() -> float:
	var sum := rumble
	for s in _shakes:
		sum += float(s.amp) * float(s.left) / float(s.total)
	return minf(sum, Config.CAM_SHAKE_MAX) * scale
