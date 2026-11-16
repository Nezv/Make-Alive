class_name AmmoCrate
extends Interactable
## A long olive military crate with a hinged lid. Right-click gives a couple of boxes of whatever
## the gun in your hands is fed with (GameHooks.on_right_click_ammo_crate), a limited number of
## times; the lid swings up for each take and stays open once the crate is empty.

const SIZE := Vector3(1.1, 0.36, 0.5)
const OLIVE := Color("4b5320")
const OLIVE_DARK := Color("3a4119")
const STENCIL := Color("d8c040")
const BRASS := Color("b08a3a")
const OPEN_ANGLE := -1.7

var uses := Config.AMMO_CRATE_USES
var open_left := 0.0 ## seconds the lid still stays up after a take
var lid: Node3D


func _init() -> void:
	var b := MeshKit.Builder.new()
	var h := SIZE.y
	b.box(SIZE, Vector3(0, h / 2.0, 0), OLIVE)
	for x in [-0.42, 0.42]: # battens
		b.box(Vector3(0.07, h + 0.02, SIZE.z + 0.03), Vector3(x, h / 2.0, 0), OLIVE_DARK)
	for x in [-0.57, 0.57]: # rope handles
		b.box(Vector3(0.04, 0.05, 0.22), Vector3(x, h * 0.6, 0), Color("8a7a55"))
	b.box(Vector3(0.5, 0.1, 0.012), Vector3(0, h * 0.55, SIZE.z / 2.0 + 0.004), STENCIL)  # stencilled band
	for i in 6: # what is inside, seen when the lid is up
		b.box(Vector3(0.1, 0.03, 0.34), Vector3(-0.3 + i * 0.12, h + 0.005, 0), BRASS)
	add_child(b.instance())

	lid = Node3D.new()
	lid.position = Vector3(0, h + 0.02, -SIZE.z / 2.0)
	add_child(lid)
	var lb := MeshKit.Builder.new()
	lb.box(Vector3(SIZE.x + 0.02, 0.06, SIZE.z + 0.02), Vector3(0, 0.03, SIZE.z / 2.0), OLIVE_DARK)
	for x in [-0.3, 0.3]: # latches
		lb.box(Vector3(0.07, 0.09, 0.03), Vector3(x, 0.0, SIZE.z + 0.015), Color("2a2c30"))
	lid.add_child(lb.instance())
	add_child(_click_body(Vector3(SIZE.x, h + 0.08, SIZE.z), Vector3(0, (h + 0.08) / 2.0, 0)))


func prompt() -> String:
	return "" if uses <= 0 else "Right-click: take ammo (%d left)" % uses


## Host: one take. False when the crate is empty.
func use() -> bool:
	if uses <= 0:
		return false
	uses -= 1
	open_left = Config.AMMO_CRATE_OPEN_TIME
	_notify_changed()
	return true


func get_state() -> Dictionary:
	return { "uses": uses }


func apply_state(state: Dictionary) -> void:
	var left: int = state.get("uses", uses)
	if left < uses:
		open_left = Config.AMMO_CRATE_OPEN_TIME # someone just took from it
	uses = left


func _process(delta: float) -> void:
	open_left = maxf(0.0, open_left - delta)
	var open := open_left > 0.0 or uses <= 0
	lid.rotation.x = lerp_angle(lid.rotation.x, OPEN_ANGLE if open else 0.0, 1.0 - exp(-9.0 * delta))
