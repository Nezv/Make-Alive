class_name Controls
## Key and mouse bindings, registered in code so there's one obvious place to change them.

const KEYS := {
	"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
	"sprint": KEY_SHIFT, "jump": KEY_SPACE, "pause": KEY_ESCAPE, "reload": KEY_R,
	"weapon_1": KEY_1, "weapon_2": KEY_2, "weapon_3": KEY_3, "weapon_4": KEY_4, "weapon_5": KEY_5,
	"weapon_6": KEY_6, "weapon_7": KEY_7, "weapon_8": KEY_8, "weapon_9": KEY_9,
}
## Right mouse does two jobs: it uses the door or lootbox you're looking at, otherwise it aims.
## The mouse wheel cycles guns (handled in player.gd).
const MOUSE := { "fire": MOUSE_BUTTON_LEFT, "interact": MOUSE_BUTTON_RIGHT, "aim": MOUSE_BUTTON_RIGHT }


## Safe to call more than once.
static func setup() -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var e := InputEventKey.new()
			e.physical_keycode = KEYS[action]
			InputMap.action_add_event(action, e)
	for action: String in MOUSE:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE[action]
			InputMap.action_add_event(action, m)
