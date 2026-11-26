class_name Lootbox
extends Interactable
## A crate with a hinged lid. Right-click opens it once and gives its loot.

var opened := false
var loot := "medkit"
var lid: Node3D
var glow: MeshInstance3D


func _init() -> void:
	var b := MeshKit.Builder.new()
	b.box(Vector3(0.9, 0.5, 0.6), Vector3(0, 0.25, 0), Color("3f5a3a"))
	for x in [-0.36, 0.36]: # metal bands
		b.box(Vector3(0.08, 0.52, 0.62), Vector3(x, 0.25, 0), Color("2a2c30"))
	add_child(b.instance())

	lid = Node3D.new()
	lid.position = Vector3(0, 0.5, -0.3)
	add_child(lid)
	var lb := MeshKit.Builder.new()
	lb.box(Vector3(0.92, 0.08, 0.62), Vector3(0, 0.04, 0.3), Color("4a6a44"))
	lb.box(Vector3(0.12, 0.1, 0.04), Vector3(0, 0.02, 0.62), Color("c8b040")) # latch
	lid.add_child(lb.instance())

	var gb := MeshKit.Builder.new()
	gb.box(Vector3(0.8, 0.04, 0.5), Vector3(0, 0.47, 0), Color("ffffff"))
	glow = gb.instance(MeshKit.emissive(Color("66ff99"), 3.0), false)
	glow.visible = false
	add_child(glow)
	var box_body := _click_body(Vector3(0.9, 0.58, 0.6), Vector3(0, 0.29, 0))
	Surface.tag(box_body, Surface.Kind.METAL)
	add_child(box_body)


func prompt() -> String:
	return "" if opened else "Right-click: open lootbox"


## Opens it. Returns the loot name the first time, "" if it was already open.
func try_open() -> String:
	if opened:
		return ""
	opened = true
	_notify_changed()
	return loot


func get_state() -> Dictionary:
	return { "opened": opened }


func apply_state(state: Dictionary) -> void:
	opened = state.get("opened", false)


func _process(delta: float) -> void:
	lid.rotation.x = lerp_angle(lid.rotation.x, -1.9 if opened else 0.0, 1.0 - exp(-8.0 * delta))
	glow.visible = opened
