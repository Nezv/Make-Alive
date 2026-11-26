class_name HeliFlight
## The helicopter's flight, no nodes: a fixed path from the landing point `lz` and the heading it comes
## in from (`yaw`), so every peer works out the same pose from the same time. In high from far off,
## one circle round the landing point, a spiral down with a nose-up flare, a settle onto the skids;
## it waits there until `depart_at`, then climbs away.
##
## `pose(t)` is { pos, yaw, pitch (nose up +), roll (bank right +), rotor (0..1), phase, compress (skids, 0..1) }.

enum Phase { APPROACH, CIRCLE, DESCEND, LANDED, DEPART, GONE }

const APPROACH_DIST := 260.0  ## metres out it starts
const APPROACH_ALT := 45.0
const CIRCLE_R := 35.0
const CIRCLE_ALT := 28.0
const HOVER_ALT := 4.0
const APPROACH_SPEED := 34.0
const CIRCLE_SPEED := 19.0
const DESCEND_TIME := 9.0     ## from the circle to hovering over the spot
const SETTLE_TIME := 2.5      ## from the hover onto the skids
const DEPART_TIME := 14.0     ## climbing away until it is gone
const APPROACH_TIME := (APPROACH_DIST - CIRCLE_R) / APPROACH_SPEED
const CIRCLE_TIME := TAU * CIRCLE_R / CIRCLE_SPEED
const LAND_AT := APPROACH_TIME + CIRCLE_TIME + DESCEND_TIME + SETTLE_TIME ## seconds from the start to touchdown

var lz: Vector3
var yaw: float
var depart_at := INF ## seconds into the flight it lifts off (INF: waiting)
var _out: Vector3     ## flat unit vector from the landing point toward where it comes from


func _init(landing: Vector3, heading_from: float) -> void:
	lz = landing
	yaw = heading_from
	_out = Vector3(sin(heading_from), 0.0, cos(heading_from))


static func _smooth(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func phase_at(t: float) -> int:
	if t >= depart_at + DEPART_TIME:
		return Phase.GONE
	if t >= depart_at:
		return Phase.DEPART
	if t >= LAND_AT:
		return Phase.LANDED
	if t >= APPROACH_TIME + CIRCLE_TIME:
		return Phase.DESCEND
	if t >= APPROACH_TIME:
		return Phase.CIRCLE
	return Phase.APPROACH


## Where it is at `t`, before any body language.
func path_pos(t: float) -> Vector3:
	var up := Vector3.UP
	var a0 := atan2(_out.z, _out.x) # angle of the way in, round the landing point
	var circle_in := lz + _out * CIRCLE_R + up * CIRCLE_ALT
	match phase_at(t):
		Phase.APPROACH:
			var start := lz + _out * APPROACH_DIST + up * APPROACH_ALT
			return start.lerp(circle_in, t / APPROACH_TIME)
		Phase.CIRCLE:
			var a := a0 + TAU * (t - APPROACH_TIME) / CIRCLE_TIME
			return lz + Vector3(cos(a), 0.0, sin(a)) * CIRCLE_R + up * CIRCLE_ALT
		Phase.DESCEND:
			var u := (t - APPROACH_TIME - CIRCLE_TIME)
			if u < DESCEND_TIME: # a quarter turn more while it spirals in and drops to the hover
				var k := u / DESCEND_TIME
				var a := a0 + TAU + 0.5 * PI * k
				var r := CIRCLE_R * (1.0 - _smooth(k))
				var alt := lerpf(CIRCLE_ALT, HOVER_ALT, _smooth(k))
				return lz + Vector3(cos(a), 0.0, sin(a)) * r + up * alt
			var s := (u - DESCEND_TIME) / SETTLE_TIME
			return lz + up * HOVER_ALT * (1.0 - _smooth(s))
		Phase.LANDED:
			return lz
		_:
			var d := t - depart_at
			var k := d / DEPART_TIME
			var ahead := -_out.rotated(Vector3.UP, 0.5 * PI) # off the way it faces
			return lz + up * (APPROACH_ALT * k * k + 6.0 * k + 0.5 * d) + ahead * (90.0 * k * k)


## The full pose at `t`, with the body language worked out from how the path moves.
func pose(t: float) -> Dictionary:
	var ph := phase_at(t)
	var pos := path_pos(t)
	var dt := 0.1
	var v := (path_pos(t + dt) - path_pos(t - dt)) / (2.0 * dt)
	var acc := (path_pos(t + dt) - 2.0 * pos + path_pos(t - dt)) / (dt * dt)
	var flat_v := Vector3(v.x, 0.0, v.z)
	var speed := flat_v.length()
	var heading := _landing_heading()
	if speed > 1.0 and ph != Phase.LANDED: # along the way it flies, turning to its landing heading as it slows
		heading = lerp_angle(heading, atan2(-flat_v.x, -flat_v.z), clampf((speed - 1.0) / 8.0, 0.0, 1.0))
	var fwd := Vector3(-sin(heading), 0.0, -cos(heading))
	var right := Vector3(-fwd.z, 0.0, fwd.x)
	var fwd_acc := acc.dot(fwd)
	var side_acc := acc.dot(right)
	var pitch := clampf(-speed * 0.006 - fwd_acc * 0.04, -0.35, 0.35) # nose down going fast, up when slowing
	var roll := clampf(side_acc * 0.05, -0.5, 0.5)                   # into the turn
	var compress := 0.0
	if ph == Phase.LANDED:
		compress = 1.0
		pitch = 0.0
		roll = 0.0
	elif ph == Phase.DESCEND:
		var hover := t - (APPROACH_TIME + CIRCLE_TIME + DESCEND_TIME)
		if hover > 0.0: # hanging over the spot: a slow sway, the skids touching at the end
			pitch += sin(t * 1.3) * 0.02
			roll += sin(t * 0.9 + 1.0) * 0.03
			compress = _smooth((hover - SETTLE_TIME + 0.4) / 0.4)
	var rotor := 0.0 if ph == Phase.GONE else 1.0
	return { "pos": pos, "yaw": heading, "pitch": pitch, "roll": roll, "rotor": rotor, "phase": ph, "compress": compress }


## The heading it holds over the spot: nose toward the way it came in, turned a quarter.
func _landing_heading() -> float:
	var face := -_out.rotated(Vector3.UP, 0.5 * PI)
	return atan2(-face.x, -face.z)
