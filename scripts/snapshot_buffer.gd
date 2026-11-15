class_name SnapshotBuffer
extends RefCounted
## Buffers networked positions and returns a smoothly interpolated value
## Config.INTERP_DELAY_MS in the past, so 20 Hz updates look smooth at any frame rate.

var _samples: Array = [] # [t_ms, pos: Vector3, yaw: float]


func push(pos: Vector3, yaw: float, at_ms := -1) -> void:
	_samples.append([at_ms if at_ms >= 0 else Time.get_ticks_msec(), pos, yaw])
	if _samples.size() > 8:
		_samples.pop_front()


func is_empty() -> bool:
	return _samples.is_empty()


func size() -> int:
	return _samples.size()


## Returns [pos: Vector3, yaw: float] for (now - delay).
func sample(now_ms := -1) -> Array:
	var t: int = (now_ms if now_ms >= 0 else Time.get_ticks_msec()) - Config.INTERP_DELAY_MS
	var last: Array = _samples[-1]
	if t >= last[0]:
		return [last[1], last[2]]
	var a: Array = _samples[0]
	var b: Array = _samples[0]
	for i in range(_samples.size() - 1, 0, -1):
		if _samples[i - 1][0] <= t:
			a = _samples[i - 1]
			b = _samples[i]
			break
	var f := 1.0
	if b[0] != a[0]:
		f = clampf(float(t - a[0]) / float(b[0] - a[0]), 0.0, 1.0)
	var pa: Vector3 = a[1]
	var pb: Vector3 = b[1]
	return [pa.lerp(pb, f), lerp_angle(a[2], b[2], f)]
