class_name Spectator
extends RefCounted
## What a dead player watches: one of the living, followed from behind and above by a smoothed camera
## (or, with nobody left to follow, a slow orbit round their own body). No nodes: the camera maths and
## who is being followed. `LocalPlayer` places the camera, `Game` says who can be followed.

var target := 0 ## peer id being followed, 0 = nobody


## Keep following the same one while they can be followed, else the first of `candidates` (0 if none).
func update(candidates: Array) -> void:
	if candidates.is_empty():
		target = 0
	elif not candidates.has(target):
		target = candidates[0]


## The next (+1) or previous (-1) of `candidates`.
func cycle(candidates: Array, step: int) -> void:
	if candidates.is_empty():
		target = 0
		return
	target = candidates[posmod(candidates.find(target) + step, candidates.size())]


## Where the camera wants to be for someone standing at `pos` facing `yaw`: behind and above.
static func camera_goal(pos: Vector3, yaw: float) -> Vector3:
	var back := Vector3(sin(yaw), 0, cos(yaw)) # models face -Z, so behind them is +Z at yaw 0
	return pos + back * Config.SPECTATE_BACK + Vector3(0, Config.SPECTATE_HEIGHT, 0)


## One frame of the camera easing toward `goal`: a step, never past it, the same at any frame rate.
static func follow(current: Vector3, goal: Vector3, delta: float) -> Vector3:
	return current.lerp(goal, 1.0 - exp(-Config.SPECTATE_SMOOTH * delta))


## Where the camera is `seconds` into the slow orbit round `center` (a body with nobody to watch).
static func orbit_goal(center: Vector3, seconds: float) -> Vector3:
	var a := seconds * Config.SPECTATE_ORBIT_SPEED
	return center + Vector3(cos(a) * Config.SPECTATE_ORBIT_RADIUS, Config.SPECTATE_ORBIT_HEIGHT, sin(a) * Config.SPECTATE_ORBIT_RADIUS)
