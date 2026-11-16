class_name CorridorGameMap
extends GameMap
## The L-shaped test corridor as a GameMap. Geometry and its spine navigation live in CorridorMap.


func _init() -> void:
	name = "corridor"
	var built := CorridorMap.build()
	root = built.root
	use_data(MapAreas.CORRIDOR)
	var made := data.build_interactables(root) # ids come from the data, identical on every peer
	data.build_checkpoints(root)
	door = made.doors[0]
	lootbox = made.lootboxes[0]
	interactables = made.all


func player_spawn() -> Vector3:
	return CorridorMap.PLAYER_SPAWN


func is_direct(from: Vector3, to: Vector3) -> bool:
	return CorridorMap.is_direct(from, to)


func nav_target(from: Vector3, to: Vector3, lane := 0.0) -> Vector3:
	return CorridorMap.nav_target(from, to, lane)


func door_in_the_way(here: Vector3, target: Vector3) -> Door:
	if door != null and door.blocks() and CorridorMap.next_choke(here, target) == CorridorMap.CHOKE_DOOR \
			and absf(here.x - CorridorMap.DOOR_X) < 1.2 and absf(here.z) < CorridorMap.DOOR_HALF + 0.5:
		return door
	return null
