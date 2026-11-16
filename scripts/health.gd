class_name Health
extends RefCounted
## Hit points with threshold events. Pure logic, no nodes.

signal changed(hp: int)
signal low  ## HP crossed from above the low threshold to at/below it
signal died

var max_hp: int
var hp: int
var low_fraction: float
var temp := 0.0 ## painkillers: extra HP on top of `hp`, soaked up first, wearing off by itself


func _init(max_value := Config.PLAYER_HP, low_at := Config.LOW_HP_FRACTION) -> void:
	max_hp = max_value
	hp = max_value
	low_fraction = low_at


func is_low() -> bool:
	return hp > 0 and float(hp) <= max_hp * low_fraction


func is_dead() -> bool:
	return hp <= 0


## Temporary HP, whole points (what is shown and sent).
func temp_hp() -> int:
	return ceili(temp)


## What the HUD and the snapshot show: real HP plus the temporary kind.
func total() -> int:
	return hp + temp_hp()


## A dose of painkillers: `amount` temporary HP, never more than that at once.
func add_temp(amount: int) -> void:
	temp = maxf(temp, float(amount))


func decay_temp(seconds: float) -> void:
	temp = maxf(0.0, temp - Config.PAINKILLERS_DECAY * seconds)


func damage(amount: int) -> void:
	if hp <= 0 or amount <= 0:
		return
	var soaked := mini(temp_hp(), amount)
	temp = maxf(0.0, temp - soaked)
	amount -= soaked
	if amount <= 0:
		changed.emit(hp)
		return
	var was_low := is_low()
	hp = maxi(0, hp - amount)
	changed.emit(hp)
	if hp == 0:
		died.emit()
	elif is_low() and not was_low:
		low.emit()


func heal(amount: int) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = mini(max_hp, hp + amount)
	changed.emit(hp)


func reset() -> void:
	hp = max_hp
	temp = 0.0
	changed.emit(hp)
