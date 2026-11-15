class_name WeaponState
extends RefCounted
## What one player is holding: which gun, rounds in each magazine, and the timers for fire rate,
## reloading and drawing. Pure logic, no nodes, so it is easy to test. Reserve ammo is unlimited.

var current: int = Weapons.DEFAULT
var ammo := {}            ## gun id -> rounds in its magazine
var cooldown := 0.0       ## seconds until the next shot is allowed
var reload_left := 0.0    ## > 0 while reloading
var draw_left := Config.WEAPON_DRAW_TIME ## > 0 while the gun is still coming up
var since_shot := 99.0    ## seconds since the last shot (drives slide / pump / bolt animation)


func _init() -> void:
	for id in Weapons.COUNT:
		ammo[id] = Weapons.def(id).mag


func def() -> Dictionary:
	return Weapons.def(current)


func rounds() -> int:
	return ammo[current]


func is_reloading() -> bool:
	return reload_left > 0.0


## 0 at the start of a reload (or of the current shell), 1 when it's done.
func reload_progress() -> float:
	var t: float = def().reload
	return clampf(1.0 - reload_left / t, 0.0, 1.0) if is_reloading() else 1.0


func step(delta: float) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	draw_left = maxf(0.0, draw_left - delta)
	since_shot += delta
	if reload_left <= 0.0:
		return
	reload_left -= delta
	if reload_left > 0.0:
		return
	var d := def()
	var mag: int = d.mag
	if d.reload_style == Weapons.Reload.SHELLS:
		ammo[current] = mini(rounds() + 1, mag)
		var per: float = d.reload
		reload_left = reload_left + per if rounds() < mag else 0.0
	else:
		ammo[current] = mag
		reload_left = 0.0


## Pull the trigger. True if a shot went off.
func try_fire() -> bool:
	if draw_left > 0.0 or cooldown > 0.0 or rounds() <= 0:
		return false
	if is_reloading():
		if def().reload_style != Weapons.Reload.SHELLS:
			return false
		reload_left = 0.0 # a shotgun can stop loading and shoot what it has
	ammo[current] = rounds() - 1
	var interval: float = def().interval
	cooldown = interval
	since_shot = 0.0
	return true


func start_reload() -> bool:
	var mag: int = def().mag
	if is_reloading() or draw_left > 0.0 or rounds() >= mag:
		return false
	var t: float = def().reload
	reload_left = t
	return true


func switch_to(id: int) -> bool:
	if not Weapons.valid(id) or id == current:
		return false
	current = id
	reload_left = 0.0
	cooldown = 0.0
	since_shot = 99.0
	draw_left = Config.WEAPON_DRAW_TIME
	return true
