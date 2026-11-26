class_name Heartbeat
## When to play the low-HP heartbeat, no nodes: nothing above `Config.LOW_HP_FRACTION`, then beats
## from `HEARTBEAT_SLOW` apart at the line to `HEARTBEAT_FAST` near 0.

var _t := 0.0


## True when a beat is due after `dt` seconds at `hp`.
func step(dt: float, hp: int) -> bool:
	var line := Config.PLAYER_HP * Config.LOW_HP_FRACTION
	if hp <= 0 or hp > line:
		_t = 0.0
		return false
	_t -= dt
	if _t > 0.0:
		return false
	_t = lerpf(Config.HEARTBEAT_FAST, Config.HEARTBEAT_SLOW, clampf(hp / line, 0.0, 1.0))
	return true
