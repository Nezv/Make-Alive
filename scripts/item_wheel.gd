class_name ItemWheel
extends RefCounted
## The radial item wheel while its key is held: the mouse moves a pointer round the middle instead of
## turning the view, the wedge it points at is picked on release. No nodes, and the game does not
## slow down meanwhile. The HUD draws `entries` and `offset`.

var open := false
var offset := Vector2.ZERO ## the pointer, from the middle, pixels (at most Config.WHEEL_RADIUS)
var entries: Array = []    ## Inventory.wheel() as it was when the wheel came up


func begin(inventory: Inventory) -> void:
	open = true
	offset = Vector2.ZERO
	entries = inventory.wheel()


## The mouse moved by `relative` pixels.
func push(relative: Vector2) -> void:
	offset = (offset + relative).limit_length(Config.WHEEL_RADIUS)


## The wedge the pointer is on, or -1 in the middle.
func selected() -> int:
	return Inventory.wedge_at(offset)


## Let go: the item on the wedge picked (&"" for the middle or an empty wedge). Closes the wheel.
func finish() -> StringName:
	var pick: StringName = &""
	var wedge := selected()
	if open and wedge >= 0 and wedge < entries.size() and entries[wedge].count > 0:
		pick = entries[wedge].item
	open = false
	offset = Vector2.ZERO
	return pick
