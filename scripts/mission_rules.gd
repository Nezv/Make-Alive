class_name MissionRules
extends RefCounted
## Runs a map's objective list in order (host only): REACH a zone, HOLD it, SURVIVE waves or a
## time, INTERACT with a thing, EXTRACT. It fires the mission hooks, fails the mission when
## everyone is out or a time limit runs down, and tells every peer what the current objective is
## (Game.send_mission_state; late joiners get the same in `welcome`).
##
## An objective (see map_data.gd): { id, kind, zone, seconds, waves, text, who, target, time_limit }.

enum Status { IDLE, RUNNING, WON, FAILED }

var game: Game
var objectives: Array = []
var index := -1
var status: int = Status.IDLE
var reason := ""          ## why it failed
var progress := 0.0       ## seconds held / survived on the current objective
var limit_left := -1.0    ## seconds before the current objective fails the mission (-1 = no limit)
var counting := false     ## `progress` is running right now (peers count along)
var wave := 0             ## SURVIVE: how many of the objective's waves have been sent
var respawn := true       ## the dead come back; off, a dead player is out until something brings them back
var out := {}             ## player id -> true: dead (no respawn) or downed, so not counted and not needed
var checkpoint := ""      ## the last checkpoint zone reached: where the dead come back
var reached := {}         ## checkpoint zone id -> true, each counts once


func _init(owner_game: Game) -> void:
	game = owner_game


## Begin (or begin again) with this list. An empty list is free play: nothing runs.
func start(defs: Array, respawn_ := true) -> void:
	objectives = defs
	respawn = respawn_
	out = {}
	reason = ""
	checkpoint = ""
	reached = {}
	index = -1
	status = Status.IDLE
	if defs.is_empty():
		_changed()
	else:
		status = Status.RUNNING
		index = 0
		_begin()


func running() -> bool:
	return status == Status.RUNNING


func current() -> Dictionary:
	return objectives[index] if index >= 0 and index < objectives.size() else {}


## Ids of the players who still count: in the match and not out.
func alive() -> Array:
	return game.players.keys().filter(func(id: int) -> bool: return not out.has(id))


## Of those, the ones standing in zone `zone`.
func inside(zone: String) -> Array:
	var data := game.map.data
	return alive().filter(func(id: int) -> bool: return data.zones.has(zone) and data.zone_contains(zone, game.players[id].pos))


func step(delta: float) -> void:
	if status != Status.RUNNING:
		return
	_step_objective(delta)
	if status != Status.FAILED:
		_check_checkpoints()


## Any checkpoint zone a player still in the fight walks into counts, once, objective or not.
func _check_checkpoints() -> void:
	for zone: String in game.map.data.zone_ids("checkpoint"):
		if not reached.has(zone) and not inside(zone).is_empty():
			reached[zone] = true
			checkpoint = zone
			game.hooks.on_checkpoint_reached(zone)


func _step_objective(delta: float) -> void:
	var o := current()
	if limit_left >= 0.0:
		limit_left -= delta
		if limit_left <= 0.0:
			fail("out of time")
			return
	var zone: String = o.zone
	var seconds: float = o.seconds
	match o.kind:
		"reach":
			var here := inside(zone)
			var everyone: bool = o.who == "all"
			if not here.is_empty() and (not everyone or here.size() == alive().size()):
				_complete(here[0])
		"hold":
			var here := inside(zone)
			_count(not here.is_empty(), delta)
			if progress >= seconds:
				_complete(here[0] if not here.is_empty() else 0)
		"extract":
			var here := inside(zone)
			_count(not here.is_empty() and here.size() == alive().size(), delta)
			if progress >= seconds:
				_complete(0)
		"survive":
			var waves: Array = o.waves
			if waves.is_empty():
				_count(true, delta)
				if progress >= seconds:
					_complete(0)
			elif game.zombies.is_empty():
				if wave >= waves.size():
					_complete(0)
				else:
					wave += 1
					game.director.spawn_horde(waves[wave - 1])
					_changed()
		"interact":
			pass # waits for `interacted`


## A player right-clicked interactable `iid`.
func interacted(player_id: int, iid: int) -> void:
	var o := current()
	if status == Status.RUNNING and not o.is_empty() and o.kind == "interact" and o.target == iid and not out.has(player_id):
		_complete(player_id)


## A player dropped out of the fight (dead with no respawn, downed) or came back. With nobody
## left, the mission is lost.
func set_out(player_id: int, is_out: bool) -> void:
	if is_out:
		out[player_id] = true
	else:
		out.erase(player_id)
	if status == Status.RUNNING and not game.players.is_empty() and alive().is_empty():
		fail("everyone is down")


func fail(why: String) -> void:
	if status != Status.RUNNING:
		return
	status = Status.FAILED
	reason = why
	counting = false
	game.hooks.on_mission_failed(why)
	_changed()


## Seconds shown beside the objective: what is left to hold or survive, else what is left of the limit.
func seconds_left() -> float:
	var o := current()
	if status != Status.RUNNING or o.is_empty():
		return -1.0
	var seconds: float = o.seconds
	var waves: Array = o.waves
	if seconds > 0.0 and (o.kind == "hold" or o.kind == "extract" or (o.kind == "survive" and waves.is_empty())):
		return maxf(0.0, seconds - progress)
	return limit_left


## What every peer needs to show the mission: small, sent only when something changes.
func state() -> Dictionary:
	var o := current()
	var s := { "index": index, "status": status, "reason": reason, "id": "", "kind": "", "text": "", "zone": "",
		"left": seconds_left(), "counting": counting or (limit_left >= 0.0 and seconds_left() == limit_left),
		"wave": wave, "has_marker": false, "marker": Vector3.ZERO }
	if o.is_empty():
		return s
	s.id = o.id
	s.kind = o.kind
	s.text = o.text
	s.zone = o.zone
	var zone: String = o.zone
	if game.map.data.zones.has(zone):
		s.has_marker = true
		s.marker = game.map.data.zone_center(zone)
	elif game.interactables.has(o.target):
		s.has_marker = true
		s.marker = (game.interactables[o.target] as Node3D).global_position
	return s


func _count(on: bool, delta: float) -> void:
	if on:
		progress += delta
	if on != counting:
		counting = on
		_changed()


func _begin() -> void:
	var o := current()
	progress = 0.0
	counting = false
	wave = 0
	var limit: float = o.time_limit
	limit_left = limit if limit > 0.0 else -1.0
	if o.kind == "extract":
		game.hooks.on_extraction_ready(o.zone)
	_changed()


func _complete(by_player: int) -> void:
	var o := current()
	game.hooks.on_objective_reached(o.id, by_player)
	if o.kind == "extract":
		game.hooks.on_extracted(alive())
	index += 1
	if index >= objectives.size():
		status = Status.WON
		counting = false
		limit_left = -1.0
		_changed()
	else:
		_begin()


func _changed() -> void:
	game.send_mission_state()
