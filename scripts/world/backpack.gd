class_name Backpack
extends Interactable
## What a dead player was carrying, left where they fell (Game.drop_backpack). Right-click takes what
## fits in your own inventory (GameHooks.on_right_click_backpack); the rest stays in it, and an empty
## one is gone. Always a drop: made during the match with an iid from Config.DROP_IID_BASE up, and its
## state says where it lies, so a peer that has never seen it builds it from the state.

const SIZE := Vector3(0.34, 0.2, 0.46)
const CLOTH := Color("4a5236")
const STRAP := Color("2a2c24")
const FLAP := Color("5a6342")

var contents := Inventory.new() ## uncapped: whatever the dead player had
var dynamic := true
var taken_by := -1              ## -1: lying here · otherwise it is emptied (by that player, 0 = removed)
var _mesh: MeshInstance3D


func _init() -> void:
	contents.capped = false
	add_child(_click_body(Vector3(0.5, 0.3, 0.6), Vector3(0, 0.15, 0), false))
	var b := MeshKit.Builder.new()
	b.box(SIZE, Vector3(0, SIZE.y / 2.0, 0), CLOTH)
	b.box(Vector3(SIZE.x * 0.94, 0.07, SIZE.z * 0.55), Vector3(0, SIZE.y + 0.01, -SIZE.z * 0.12), FLAP)
	b.box(Vector3(0.05, SIZE.y + 0.02, SIZE.z + 0.02), Vector3(-SIZE.x * 0.28, SIZE.y / 2.0, 0), STRAP)
	b.box(Vector3(0.05, SIZE.y + 0.02, SIZE.z + 0.02), Vector3(SIZE.x * 0.28, SIZE.y / 2.0, 0), STRAP)
	b.box(Vector3(SIZE.x * 0.5, 0.1, 0.08), Vector3(0, 0.07, SIZE.z / 2.0 + 0.04), STRAP) # a pocket on the back
	_mesh = b.instance(null, false)
	add_child(_mesh)


func prompt() -> String:
	if taken_by >= 0:
		return ""
	var things: Array[String] = []
	for item: StringName in Inventory.ITEMS:
		if contents.count(item) > 0:
			things.append("%d %s" % [contents.count(item), Inventory.item_name(item)])
	for id in contents.keys():
		things.append("key %s" % id)
	return "Right-click: take from the backpack (%s)" % ", ".join(things)


## Host: `inventory` takes what it has room for. An emptied pack is done (`by` is who emptied it).
## Returns how many things moved.
func loot(inventory: Inventory, by: int) -> int:
	if taken_by >= 0:
		return 0
	var moved := contents.transfer_to(inventory)
	if contents.is_empty():
		taken_by = by
	if moved > 0:
		_notify_changed()
	return moved


## Host: gone without anyone getting it (the oldest of too many).
func discard() -> void:
	contents.clear()
	taken_by = 0
	_notify_changed()


func get_state() -> Dictionary:
	var state := contents.get_state()
	state["by"] = taken_by
	state["drop"] = true
	state["pack"] = true
	state["at"] = position
	state["yaw"] = rotation.y
	return state


func apply_state(state: Dictionary) -> void:
	contents.apply_state(state)
	taken_by = state.get("by", -1)
