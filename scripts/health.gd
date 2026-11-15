class_name Health
extends RefCounted
## Hit points with threshold events. Pure logic, no nodes.

signal changed(hp: int)
signal low  ## HP crossed from above the low threshold to at/below it
signal died

var max_hp: int
var hp: int
var low_fraction: float


func _init(max_value := Config.PLAYER_HP, low_at := Config.LOW_HP_FRACTION) -> void:
	max_hp = max_value
	hp = max_value
	low_fraction = low_at


func is_low() -> bool:
	return hp > 0 and float(hp) <= max_hp * low_fraction


func is_dead() -> bool:
	return hp <= 0


func damage(amount: int) -> void:
	if hp <= 0 or amount <= 0:
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
	changed.emit(hp)
