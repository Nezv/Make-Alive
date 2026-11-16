class_name GameMap
extends RefCounted
## What the match needs from any map. Game, Zombie and HordeDirector only talk to this, never to
## a specific map, so adding a map means extending GameMap and adding it to `create`.
##
## Everything a map builds must be identical on every peer: fixed positions, fixed interactable
## ids, and only its own seeded RandomNumberGenerator (never randf) for scattered detail.

const NAMES := ["corridor", "city"]

var name := ""
var root: Node3D             ## all geometry, lights and interactables
var interactables: Array = []
var door: Door = null        ## a door zombies may have to smash (or none)
var lootbox: Lootbox = null
var outdoor := false         ## night sky and thin fog instead of a black, foggy interior
var all_weapons := true      ## players carry every gun (test maps) or must find them
var nav_refresh := 0.0       ## seconds a zombie keeps its last waypoint (0 = ask every tick)
var spots: Array = []        ## every WeaponPickup on the map, filled or not (Scenery makes them)
var mission := ""            ## which mission is being played on this map ("" = free play); set right after create
var infinite_ammo := true    ## test maps never run dry; off, players live on `starting_ammo()` and what they find
var data := MapData.new()    ## this area as data (map_areas.gd): spawns, closets, zones, objectives
var zones := {}              ## data.zones: id -> { id, kind, box | polygon, y }
var spawns: Array = []       ## data.spawns: [{ at, yaw }], one per player slot
var objective_defs: Array = [] ## data.objectives, in order


static func create(map_name: String) -> GameMap:
	match map_name:
		"corridor": return CorridorGameMap.new()
		"city": return CityMap.new()
	return null


func player_spawn() -> Vector3:
	return Vector3.ZERO


## Read this map's data dictionary (see map_data.gd for the format).
func use_data(dict: Dictionary) -> void:
	data = MapData.new(dict)
	zones = data.zones
	spawns = data.spawns
	objective_defs = data.objectives


## The reserve every player starts with (Weapons.Ammo -> rounds): each calibre's own default
## unless the map's data says otherwise.
func starting_ammo() -> Dictionary:
	var out := {}
	for type in Weapons.Ammo.COUNT:
		out[type] = data.starting_ammo.get(type, Weapons.AMMO[type].start)
	return out


## Where the player in `slot` (0, 1, 2...) appears: their own spawn from the data, if the map has any.
func player_spawn_point(slot := 0) -> Vector3:
	if spawns.is_empty():
		return player_spawn()
	return spawns[posmod(slot, spawns.size())].at


## Where the next zombie appears. `avoid` holds player positions to keep away from.
func zombie_spawn_point(_avoid: Array) -> Vector3:
	if data.closets.is_empty():
		return Vector3.ZERO
	var c: Dictionary = data.closets[randi() % data.closets.size()]
	var at: Vector3 = c.at
	var r: float = c.radius * sqrt(randf())
	var a := randf() * TAU
	return at + Vector3(cos(a) * r, 0, sin(a) * r)


## Can someone stand at `p`? (MapData.check uses this to catch spawns in walls.)
func is_walkable(p: Vector3) -> bool:
	return data.in_bounds(p)


## Is there an open line from `a` to `b` at floor level? Walked in half-metre steps over the
## walkable ground, so it is only as fine as `is_walkable`.
func sees(a: Vector3, b: Vector3) -> bool:
	var n := maxi(1, ceili(a.distance_to(b) / 0.5))
	for i in n + 1:
		if not is_walkable(a.lerp(b, float(i) / n)):
			return false
	return true


## Height of the walkable ground under `p` (flat maps: 0).
func ground_y(_p: Vector3) -> float:
	return 0.0


func is_direct(_from: Vector3, _to: Vector3) -> bool:
	return true


func nav_target(_from: Vector3, to: Vector3, _lane := 0.0) -> Vector3:
	return to


## A closed door a zombie at `here` must break to reach `target`, if it is right in front of it.
func door_in_the_way(_here: Vector3, _target: Vector3) -> Door:
	return null


## Host, once per match: empty every spot, then put a random gun in a random few.
func roll_weapons(rng: RandomNumberGenerator) -> void:
	var order := range(spots.size())
	for i in range(order.size() - 1, 0, -1): # shuffle with the given rng so a seed pins it
		var j := rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	for i in order.size():
		var spot: WeaponPickup = spots[order[i]]
		spot.set_weapon(Weapons.roll_loot(rng) if i < Config.WEAPON_SPOTS_ACTIVE else -1)
