class_name SettingsStore
extends Node
## What the player chose: look sensitivity, field of view, volumes, graphics, keys, name.
## Autoloaded as `Settings`, kept in user://settings.cfg and applied the moment a value changes.
##
##   Settings.get_value("fov")            Settings.set_value("fov", 90.0)
##   Settings.changed.connect(func(key): ...)
##
## Adding a setting: one line in DEFS (and a branch in `_apply` if the engine must be told).
## A missing, broken or hand-edited file can never crash the game: anything unreadable is a default.

signal changed(key: String)

const BUSES := Sfx.BUSES
const TIERS := ["low", "medium", "high"]
const WINDOW_MODES := ["windowed", "borderless", "fullscreen"]

## key -> { default, and either min/max (numbers) or choices (strings) }
const DEFS := {
	"mouse_sensitivity": { "default": Config.MOUSE_SENS, "min": 0.0003, "max": 0.01 },
	"invert_y": { "default": false },
	"fov": { "default": Config.FOV, "min": 60.0, "max": 110.0 },
	"camera_motion": { "default": 1.0, "min": 0.0, "max": 1.0 }, # bob, sway, tilt, shakes, FOV changes; 0 is none
	"hud_scale": { "default": 1.0, "min": 0.75, "max": 1.5 },
	"aim_toggle": { "default": false },          # false: hold right mouse to aim
	"volume_master": { "default": 1.0, "min": 0.0, "max": 1.0 },
	"volume_guns": { "default": 1.0, "min": 0.0, "max": 1.0 },
	"volume_zombies": { "default": 1.0, "min": 0.0, "max": 1.0 },
	"volume_world": { "default": 1.0, "min": 0.0, "max": 1.0 },
	"volume_ui": { "default": 1.0, "min": 0.0, "max": 1.0 },
	"volume_music": { "default": 1.0, "min": 0.0, "max": 1.0 },
	"graphics_tier": { "default": "medium", "choices": TIERS },
	"fps_cap": { "default": 0, "min": 0, "max": 360 }, # 0 = no cap
	"vsync": { "default": true },
	"window_mode": { "default": "windowed", "choices": WINDOW_MODES },
	"show_draws": { "default": true },
	"player_name": { "default": "" },
}

var path := "user://settings.cfg"
var apply_to_engine := true ## off in tests: never resize the window or touch the buses from a test
var _values := {}


func _ready() -> void:
	Sfx.ensure_buses()
	load_file()


func get_value(key: String) -> Variant:
	return _values.get(key)


## Change a setting: clamped to its range, saved, applied, and announced through `changed`.
func set_value(key: String, value: Variant) -> void:
	if not DEFS.has(key):
		return
	var clean: Variant = _clean(key, value)
	if clean == null or clean == _values[key]:
		return
	_values[key] = clean
	_apply(key)
	save_file()
	changed.emit(key)


## Bind `action` (a Controls.KEYS name) to a physical key, now and on every later run.
func set_key(action: String, keycode: int) -> void:
	if not Controls.KEYS.has(action):
		return
	Controls.set_key(action, keycode)
	save_file()
	changed.emit("key_" + action)


## Everything back to DEFS and the default keys. `save` false keeps the file as it is (tests).
func reset_to_defaults(save := true) -> void:
	for key: String in DEFS:
		_values[key] = DEFS[key].default
		_apply(key)
	Controls.reset()
	if save:
		save_file()
	for key: String in DEFS:
		changed.emit(key)


func load_file() -> void:
	for key: String in DEFS:
		_values[key] = DEFS[key].default
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(path) and cfg.load(path) == OK:
		for key: String in DEFS:
			if cfg.has_section_key("settings", key):
				var clean: Variant = _clean(key, cfg.get_value("settings", key))
				if clean != null:
					_values[key] = clean
		for action: String in Controls.KEYS:
			var code: Variant = cfg.get_value("keys", action) if cfg.has_section_key("keys", action) else null
			if code is int and code > 0:
				Controls.set_key(action, code)
	for key: String in DEFS:
		_apply(key)


func save_file() -> void:
	var cfg := ConfigFile.new()
	for key: String in DEFS:
		cfg.set_value("settings", key, _values[key])
	for action: String in Controls.KEYS:
		if Controls.key_of(action) != Controls.KEYS[action]:
			cfg.set_value("keys", action, Controls.key_of(action))
	cfg.save(path)


## `value` as this setting stores it, or null if it is the wrong kind of thing altogether.
func _clean(key: String, value: Variant) -> Variant:
	var d: Dictionary = DEFS[key]
	var def: Variant = d.default
	if def is bool:
		return value if value is bool else null
	if def is String:
		if not value is String:
			return null
		if d.has("choices"):
			return value if (d.choices as Array).has(value) else null
		return (value as String).strip_edges().substr(0, 20)
	if not (value is int or value is float):
		return null
	if def is int:
		return clampi(int(value), d.min, d.max)
	return clampf(float(value), d.min, d.max)


## Tell the engine. Things the game reads each frame (fov, sensitivity) need nothing here.
func _apply(key: String) -> void:
	if not apply_to_engine:
		return
	if key.begins_with("volume_"):
		var bus := AudioServer.get_bus_index(key.trim_prefix("volume_").capitalize())
		if bus >= 0:
			var v: float = _values[key]
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
			AudioServer.set_bus_mute(bus, v <= 0.0)
		return
	match key:
		"fps_cap":
			Engine.max_fps = _values[key]
		"vsync", "window_mode":
			if DisplayServer.get_name() == "headless":
				return
			if key == "vsync":
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if _values[key] else DisplayServer.VSYNC_DISABLED)
			else:
				var modes := { "windowed": DisplayServer.WINDOW_MODE_WINDOWED, "fullscreen": DisplayServer.WINDOW_MODE_FULLSCREEN,
					"borderless": DisplayServer.WINDOW_MODE_FULLSCREEN }
				var mode: int = modes[_values[key]]
				if DisplayServer.window_get_mode() != mode:
					DisplayServer.window_set_mode(mode)
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, _values[key] == "borderless")
