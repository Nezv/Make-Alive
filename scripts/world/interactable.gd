class_name Interactable
extends Node3D
## Anything a player can right-click. The host decides what happens (see GameHooks.on_right_click);
## state travels to every peer as a small Dictionary via get_state()/apply_state().
##
## To add a new one: extend this, build visuals + a click body in _init, implement the three
## methods below, list it in the map's data (map_areas.gd, built by MapData.build_interactables), and add on_right_click_<thing> to GameHooks.

signal state_changed(iid: int, state: Dictionary)

var iid := 0 ## unique id, same on every peer


## Text shown on the HUD when a player looks at it ("" = nothing to do).
func prompt() -> String:
	return ""


func get_state() -> Dictionary:
	return {}


func apply_state(_state: Dictionary) -> void:
	pass


func _notify_changed() -> void:
	state_changed.emit(iid, get_state())


## A static box players can click (and optionally collide with).
func _click_body(size: Vector3, center: Vector3, solid := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = Config.LAYER_INTERACT | (Config.LAYER_WORLD if solid else 0)
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position = center
	body.add_child(cs)
	return body


## Walk up from a physics collider to the Interactable that owns it (or null).
static func from_collider(collider: Object) -> Interactable:
	var n := collider as Node
	while n != null:
		if n is Interactable:
			return n
		n = n.get_parent()
	return null
