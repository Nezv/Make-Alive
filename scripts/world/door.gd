class_name Door
extends Interactable
## A hinged door across a corridor that runs along X. Right-click toggles it.
## Closed, it blocks players, zombies and bullets; zombies bash it until it breaks.

signal smashed(door: Door) ## visual moment the panel breaks (fires on every peer)

const WIDTH := 2.0
const HEIGHT := 2.6
const THICK := 0.12
const OPEN_ANGLE := -1.7

var is_open := false
var broken := false
var hp := Config.DOOR_HP
var hinge: Node3D
var panel: MeshInstance3D
var body: StaticBody3D
var _shake := 0.0


func _init() -> void:
	hinge = Node3D.new()
	hinge.position = Vector3(0, 0, -WIDTH / 2.0)
	add_child(hinge)
	var b := MeshKit.Builder.new()
	var c := Vector3(0, HEIGHT / 2.0, WIDTH / 2.0)
	b.box(Vector3(THICK, HEIGHT, WIDTH), c, Color("6a4a2c"))
	for y in [0.35, HEIGHT / 2.0, HEIGHT - 0.35]: # cross planks
		b.box(Vector3(THICK + 0.04, 0.16, WIDTH - 0.1), Vector3(0, y, WIDTH / 2.0), Color("4f3620"))
	b.box(Vector3(THICK + 0.1, 0.08, 0.2), Vector3(0, 1.1, WIDTH - 0.2), Color("b0b0b0")) # handle
	panel = b.instance()
	hinge.add_child(panel)
	body = _click_body(Vector3(THICK + 0.08, HEIGHT, WIDTH), c)
	hinge.add_child(body)


func prompt() -> String:
	if broken:
		return ""
	return "Right-click: close door" if is_open else "Right-click: open door"


## True while it physically stops things from passing.
func blocks() -> bool:
	return not is_open and not broken


func toggle() -> void:
	if broken:
		return
	is_open = not is_open
	_notify_changed()


## Zombies bashing it. Returns true if this hit broke it.
func take_hit(damage: int) -> bool:
	if broken or is_open:
		return false
	hp -= damage
	_shake = 1.0
	if hp <= 0:
		_break()
		_notify_changed()
		return true
	return false


func _break() -> void:
	if broken:
		return
	broken = true
	is_open = true
	panel.visible = false
	body.collision_layer = 0
	smashed.emit(self)


func get_state() -> Dictionary:
	return { "open": is_open, "broken": broken }


func apply_state(state: Dictionary) -> void:
	is_open = state.get("open", false)
	if state.get("broken", false):
		_break()


func _process(delta: float) -> void:
	var target := OPEN_ANGLE if is_open else 0.0
	_shake = maxf(0.0, _shake - delta * 5.0)
	var rattle := sin(Time.get_ticks_msec() * 0.08) * 0.05 * _shake
	hinge.rotation.y = lerp_angle(hinge.rotation.y, target, 1.0 - exp(-10.0 * delta)) + rattle * delta * 30.0
