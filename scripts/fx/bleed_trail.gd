class_name BleedTrail
## Where bleeding players drop blood, no nodes: one drop every `Config.BLEED_DRIP_STEP` metres walked,
## or every `BLEED_DRIP_IDLE` seconds standing. Each peer keeps its own and draws the drops itself
## (who is bleeding comes in snapshots as `PlayerWire.ACTION_BLEED`).

var _last := {}  ## id -> [position of the last drop, seconds since it]


## True when player `id`, now at `pos`, drops blood this step.
func step(id: int, pos: Vector3, bleeding: bool, dt: float) -> bool:
	if not bleeding:
		_last.erase(id)
		return false
	if not _last.has(id):
		_last[id] = [pos, 0.0]
		return true
	var l: Array = _last[id]
	l[1] = float(l[1]) + dt
	var from: Vector3 = l[0]
	if Vector2(pos.x - from.x, pos.z - from.z).length() >= Config.BLEED_DRIP_STEP or float(l[1]) >= Config.BLEED_DRIP_IDLE:
		l[0] = pos
		l[1] = 0.0
		return true
	return false
