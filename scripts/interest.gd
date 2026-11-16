class_name Interest
extends RefCounted
## Which zombies a client is sent when there are more than fit in one packet: the nearest ones every
## tick, the far ones in turn (each at least every `Config.INTEREST_FAR_TICKS` ticks), nothing beyond
## `Config.INTEREST_RANGE`. While everything fits, everybody gets everything and none of this runs.


## How many zombies fit in the snapshot packet next to `player_count` players.
static func budget(player_count: int) -> int:
	return (Config.BUDGET_PACKET_BYTES - ZombieWire.HEADER - PlayerWire.BYTES_EACH * player_count - Config.PACKET_OVERHEAD) / ZombieWire.BYTES_EACH


## `list` (entries as ZombieWire.pack takes them) cut down to at most `budget` for a client at `viewer`
## on snapshot number `tick`.
static func pick(list: Array, viewer: Vector3, tick: int, budget_: int) -> Array:
	if list.size() <= budget_:
		return list
	var range2 := Config.INTEREST_RANGE * Config.INTEREST_RANGE
	var by_distance: Array = []
	for z: Dictionary in list:
		var p: Vector3 = z.pos
		var d2 := Vector2(p.x - viewer.x, p.z - viewer.z).length_squared()
		if d2 <= range2:
			by_distance.append([d2, z])
	by_distance.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var sorted: Array = by_distance.map(func(e: Array) -> Dictionary: return e[1])
	if sorted.size() <= budget_:
		return sorted
	var near_n := int(budget_ * Config.INTEREST_NEAR_SHARE)
	var far_slots := budget_ - near_n
	if ceili(float(sorted.size() - near_n) / far_slots) > Config.INTEREST_FAR_TICKS: # a big crowd: more room for the far ones
		far_slots = mini(budget_ - 1, ceili(float(sorted.size() - near_n) / Config.INTEREST_FAR_TICKS))
		near_n = budget_ - far_slots
	var out := sorted.slice(0, near_n)
	var far := sorted.slice(near_n)
	var turns := ceili(float(far.size()) / far_slots)
	var turn := tick % turns
	out.append_array(far.slice(turn * far_slots, (turn + 1) * far_slots))
	return out
