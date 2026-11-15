class_name WeaponPickup
extends Interactable
## A place a gun may be lying: a truck bed, next to a corpse, on a table. The map creates one per
## possible spot; each match the host fills a random few (GameMap.roll_weapons). Right-click takes
## the gun (GameHooks.on_right_click_weapon), which empties the spot for everyone.

var kind := ""              ## "truck", "vehicle", "corpse", "table", "crate"
var weapon := -1            ## Weapons id, or -1 when there is nothing here
var stand := Vector3.ZERO   ## a clear spot on the ground from which a player can reach it
var gun: GunModel
var _body: StaticBody3D


func _init() -> void:
	_body = _click_body(Vector3(1.3, 0.45, 0.7), Vector3(0, 0.12, 0), false)
	_body.collision_layer = 0
	add_child(_body)


func prompt() -> String:
	return "" if weapon < 0 else "Right-click: take %s" % Weapons.def(weapon).name


## Host: put a gun here (-1 = nothing).
func set_weapon(id: int) -> void:
	weapon = id
	_refresh()
	_notify_changed()


## Host: remove the gun. Returns its Weapons id, or -1 if the spot was empty.
func take() -> int:
	var w := weapon
	if w >= 0:
		set_weapon(-1)
	return w


func get_state() -> Dictionary:
	return { "weapon": weapon }


func apply_state(state: Dictionary) -> void:
	weapon = state.get("weapon", -1)
	_refresh()


func _refresh() -> void:
	if gun != null:
		gun.free()
		gun = null
	_body.collision_layer = Config.LAYER_INTERACT if weapon >= 0 else 0
	if weapon >= 0:
		gun = Guns.build(weapon)
		gun.rotation = Vector3(0, 0, PI / 2.0) # lying on its side
		gun.position = Vector3(-0.05, 0.03, 0.1)
		add_child(gun)
