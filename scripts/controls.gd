class_name Controls
## Key and mouse bindings, registered in code so there's one obvious place to change them.
## KEYS are the defaults; the player's own choices come from Settings (`Settings.set_key`).

const KEYS := {
	"move_forward": KEY_W, "move_back": KEY_S, "move_left": KEY_A, "move_right": KEY_D,
	"sprint": KEY_SHIFT, "jump": KEY_SPACE, "pause": KEY_ESCAPE, "reload": KEY_R, "last_weapon": KEY_Q, "crouch": KEY_CTRL, "shove": KEY_V,
	"item_wheel": KEY_TAB, "quick_heal": KEY_H, "quick_throw": KEY_G,
	"weapon_1": KEY_1, "weapon_2": KEY_2, "weapon_3": KEY_3, "weapon_4": KEY_4, "weapon_5": KEY_5,
	"weapon_6": KEY_6, "weapon_7": KEY_7, "weapon_8": KEY_8, "weapon_9": KEY_9,
}
## Right mouse does two jobs: it uses the door or lootbox you're looking at, otherwise it aims.
## The mouse wheel cycles guns (handled in player.gd).
const MOUSE := { "fire": MOUSE_BUTTON_LEFT, "interact": MOUSE_BUTTON_RIGHT, "aim": MOUSE_BUTTON_RIGHT }

static var _bound := {} ## action -> physical keycode, only for keys moved off their default


## Safe to call more than once.
static func setup() -> void:
	for action: String in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			_bind(action)
	for action: String in MOUSE:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE[action]
			InputMap.action_add_event(action, m)


## The physical key `action` is on right now.
static func key_of(action: String) -> int:
	return _bound.get(action, KEYS.get(action, KEY_NONE))


static func set_key(action: String, keycode: int) -> void:
	if not KEYS.has(action):
		return
	if keycode == KEYS[action]:
		_bound.erase(action)
	else:
		_bound[action] = keycode
	if InputMap.has_action(action):
		_bind(action)


## Every key back on its default.
static func reset() -> void:
	_bound.clear()
	for action: String in KEYS:
		if InputMap.has_action(action):
			_bind(action)


static func _bind(action: String) -> void:
	InputMap.action_erase_events(action)
	var e := InputEventKey.new()
	e.physical_keycode = key_of(action) as Key
	InputMap.action_add_event(action, e)
