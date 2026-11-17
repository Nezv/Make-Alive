class_name WeaponState
extends RefCounted
## What one player is holding: which gun, rounds in each magazine, and the timers for fire rate,
## reloading and drawing. Pure logic, no nodes, so it is easy to test.
## The reserve is counted per calibre (Weapons.Ammo) and a reload takes from it. Until `limit` is
## called it is infinite, which is how the test maps play.

var current: int = Weapons.DEFAULT
var ammo := {}            ## gun id -> rounds in its magazine
var cooldown := 0.0       ## seconds until the next shot is allowed
var reload_left := 0.0    ## > 0 while reloading
var reload_empty := false ## this reload began with nothing in the gun (so it ends with the charging handle)
var draw_left := Config.WEAPON_DRAW_TIME ## > 0 while the gun is still coming up
var draw_total := Config.WEAPON_DRAW_TIME ## how long this swap takes in all (Weapons.draw_time of the new gun)
var since_shot := 99.0    ## seconds since the last shot (drives slide / pump / bolt animation)
var infinite := true      ## reloads cost nothing
var reserve := {}         ## Weapons.Ammo -> rounds not in a magazine (when not `infinite`)
var _spent := {}          ## Weapons.Ammo -> rounds taken from the reserve since `take_spent`


func _init() -> void:
	for id in Weapons.COUNT:
		ammo[id] = Weapons.def(id).mag


func def() -> Dictionary:
	return Weapons.def(current)


func rounds() -> int:
	return ammo[current]


## From now on reloads take from a reserve: `start` is Weapons.Ammo -> rounds.
func limit(start: Dictionary) -> void:
	infinite = false
	reserve = start.duplicate()
	_spent = {}


func ammo_type() -> int:
	return Weapons.ammo_of(current)


## Rounds left for the gun in hand outside its magazine; -1 when there is no limit.
func reserve_rounds() -> int:
	if infinite:
		return -1
	var have: int = reserve.get(ammo_type(), 0)
	return have


## Nothing in the magazine and nothing to reload with.
func is_dry() -> bool:
	return rounds() <= 0 and reserve_rounds() == 0


## Put up to `n` rounds of a calibre in the reserve. Returns how many fitted under its cap.
func add_reserve(type: int, n: int) -> int:
	if infinite or type < 0 or type >= Weapons.Ammo.COUNT or n <= 0:
		return 0
	var have: int = reserve.get(type, 0)
	var cap: int = Weapons.AMMO[type].max
	var fits := clampi(n, 0, maxi(0, cap - have))
	reserve[type] = have + fits
	return fits


## What the reloads since the last call took from the reserve (Weapons.Ammo -> rounds), so the
## host is told once per reload instead of in every snapshot.
func take_spent() -> Dictionary:
	var out := _spent
	_spent = {}
	return out


## Move up to `want` rounds out of the reserve. Returns how many there were.
func _take(want: int) -> int:
	if infinite:
		return want
	var type := ammo_type()
	var have: int = reserve.get(type, 0)
	var got := mini(want, have)
	if got > 0:
		var before: int = _spent.get(type, 0)
		reserve[type] = have - got
		_spent[type] = before + got
	return got


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
		ammo[current] = mini(rounds() + _take(1), mag)
		var per: float = d.reload
		reload_left = reload_left + per if rounds() < mag and reserve_rounds() != 0 else 0.0
	else:
		ammo[current] = rounds() + _take(mag - rounds()) # a partial magazine when the reserve is short
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
	if is_reloading() or draw_left > 0.0 or rounds() >= mag or reserve_rounds() == 0:
		return false
	var t: float = def().reload
	reload_left = t
	reload_empty = rounds() == 0
	return true


func switch_to(id: int) -> bool:
	if not Weapons.valid(id) or id == current:
		return false
	current = id
	reload_left = 0.0
	cooldown = 0.0
	since_shot = 99.0
	draw_total = Weapons.draw_time(id)
	draw_left = draw_total
	return true
