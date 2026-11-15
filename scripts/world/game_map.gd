class_name GameMap
extends RefCounted
## What the match needs from any map. Game, Zombie and HordeDirector only talk to this, never to
## a specific map, so adding a map means extending GameMap and adding it to `create`.
##
## Everything a map builds must be identical on every peer: fixed positions, fixed interactable
## ids, and only its own seeded RandomNumberGenerator (never randf) for scattered detail.

const NAMES := ["corridor", "shelter", "city"]

var name := ""
var root: Node3D             ## all geometry, lights and interactables
var interactables: Array = []
var door: Door = null        ## a door zombies may have to smash (or none)
var lootbox: Lootbox = null
var outdoor := false         ## night sky and thin fog instead of a black, foggy interior
var all_weapons := true      ## players carry every gun (test maps) or must find them
var nav_refresh := 0.0       ## seconds a zombie keeps its last waypoint (0 = ask every tick)
var mission := ""            ## which mission is being played on this map ("" = free play); set right after create


static func create(map_name: String) -> GameMap:
	match map_name:
		"corridor": return CorridorGameMap.new()
		"shelter": return ShelterMap.new()
		"city": return CityMap.new()
	return null


func player_spawn() -> Vector3:
	return Vector3.ZERO


func player_spawn_point() -> Vector3:
	return player_spawn()


## Where the next zombie appears. `avoid` holds player positions to keep away from.
func zombie_spawn_point(_avoid: Array) -> Vector3:
	return Vector3.ZERO


func is_direct(_from: Vector3, _to: Vector3) -> bool:
	return true


func nav_target(_from: Vector3, to: Vector3, _lane := 0.0) -> Vector3:
	return to


## A closed door a zombie at `here` must break to reach `target`, if it is right in front of it.
func door_in_the_way(_here: Vector3, _target: Vector3) -> Door:
	return null


## Host, once per match: decide which weapon spots hold which gun.
func roll_weapons(_rng: RandomNumberGenerator) -> void:
	pass
