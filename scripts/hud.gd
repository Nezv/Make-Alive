class_name Hud
extends CanvasLayer
## In-game overlay: crosshair, health, info, kill feed, extraction bar, toasts, perf, pause menu.

signal leave_pressed

const GAIN_AT := Vector2(-420, -116)
const GAIN_COLOR := Color("9be29b")

var hp_label: Label
var info_label: Label
var perf_label: Label
var toast_label: Label
var feed_box: VBoxContainer
var prompt_label: Label
var weapon_label: Label
var gain_label: Label ## "+30" rising over the ammo count after a pickup
var scope: ColorRect
var damage: ColorRect
var cross: Array[ColorRect] = []
var pause_panel: PanelContainer
var _last_hp := Config.PLAYER_HP
var _hit_t := 0.0
var _toast_t := 0.0
var _dmg_t := 0.0
var _gain_t := 0.0


func _ready() -> void:
	damage = ColorRect.new()
	damage.color = Color(0.8, 0, 0, 0)
	damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(damage)

	# Sniper scope: black everywhere except a round window, with thin cross lines.
	scope = ColorRect.new()
	scope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scope.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
void fragment() {
	vec2 p = (UV - 0.5) * vec2(SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, 1.0);
	float r = length(p);
	float line = min(abs(p.x), abs(p.y));
	float a = smoothstep(0.40, 0.41, r);
	a = max(a, (1.0 - smoothstep(0.0008, 0.0016, line)) * step(0.02, r) * 0.9);
	a = max(a, smoothstep(0.30, 0.41, r) * 0.6);
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
"""
	var sm := ShaderMaterial.new()
	sm.shader = sh
	scope.material = sm
	scope.visible = false
	add_child(scope)

	for size in [Vector2(2, 18), Vector2(18, 2)]:
		var r := ColorRect.new()
		r.color = Color(1, 1, 1, 0.85)
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.set_anchors_preset(Control.PRESET_CENTER)
		r.size = size
		r.position = -size / 2.0
		add_child(r)
		cross.append(r)

	hp_label = _label(32, Control.PRESET_BOTTOM_LEFT, Vector2(24, -64))
	weapon_label = _label(26, Control.PRESET_BOTTOM_RIGHT, Vector2(-420, -82))
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	weapon_label.size.x = 400
	gain_label = _label(22, Control.PRESET_BOTTOM_RIGHT, GAIN_AT)
	gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	gain_label.size.x = 400
	gain_label.modulate = Color(GAIN_COLOR, 0.0)
	info_label = _label(16, Control.PRESET_TOP_RIGHT, Vector2(-220, 20))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info_label.size.x = 200
	perf_label = _label(13, Control.PRESET_BOTTOM_RIGHT, Vector2(-420, -34))
	perf_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	perf_label.size.x = 400
	perf_label.modulate.a = 0.7
	toast_label = _label(44, Control.PRESET_CENTER_TOP, Vector2(-400, 220))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.size.x = 800
	toast_label.modulate.a = 0

	feed_box = VBoxContainer.new()
	feed_box.position = Vector2(24, 20)
	add_child(feed_box)

	prompt_label = _label(20, Control.PRESET_CENTER, Vector2(-300, 60))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size.x = 600

	_build_pause()


func _label(font_size: int, preset: int, offset: Vector2) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.set_anchors_preset(preset)
	l.position = offset
	add_child(l)
	return l


func _build_pause() -> void:
	pause_panel = PanelContainer.new()
	pause_panel.set_anchors_preset(Control.PRESET_CENTER)
	pause_panel.custom_minimum_size = Vector2(320, 0)
	pause_panel.position = Vector2(-160, -90)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	pause_panel.add_child(v)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	v.add_child(title)
	var resume := Button.new()
	resume.text = "Resume"
	resume.pressed.connect(func(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED)
	v.add_child(resume)
	var leave := Button.new()
	leave.text = "Leave game"
	leave.pressed.connect(func(): leave_pressed.emit())
	v.add_child(leave)
	var help := Label.new()
	help.text = "WASD move · Shift sprint · Space jump\nLeft click shoot · Right click aim, or use / pick up what you look at\nR reload · 1-9 or mouse wheel change gun · Esc menu"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.modulate.a = 0.7
	v.add_child(help)
	add_child(pause_panel)


func set_hp(hp: int) -> void:
	hp_label.text = "♥ %d" % maxi(hp, 0)
	hp_label.modulate = Color.WHITE if hp > 50 else (Color("ffcc66") if hp > 25 else Color("ff5555"))
	if hp < _last_hp:
		_dmg_t = 0.3
	_last_hp = hp


func set_info(players: int, zombies: int, kills: int) -> void:
	info_label.text = "Survivors: %d\nZombies: %d\nKills: %d" % [players, zombies, kills]


func set_prompt(text: String) -> void:
	prompt_label.text = text


## Rounds in the magazine / rounds in reserve (`reserve` -1: no limit).
func set_weapon(gun_name: String, rounds: int, reloading: bool, reserve := -1) -> void:
	var left := "∞" if reserve < 0 else str(reserve)
	weapon_label.text = "%s   %s / %s" % [gun_name, "RELOADING" if reloading else str(rounds), left]
	var empty := rounds == 0 and not reloading
	weapon_label.modulate = Color("ff5555") if empty else (Color("ffcc66") if reserve == 0 else Color.WHITE)


## Something was picked up: `text` ("+30  7.62") rises over the ammo count and fades.
func gain(text: String) -> void:
	gain_label.text = text
	gain_label.modulate = Color(GAIN_COLOR, 1.0)
	gain_label.position = GAIN_AT
	_gain_t = Config.PICKUP_GAIN_TIME


## Sights are up: the crosshair gets out of the way.
func set_aiming(on: bool) -> void:
	for r in cross:
		r.visible = not on


func set_scope(on: bool) -> void:
	scope.visible = on


func hit_marker() -> void:
	_hit_t = 0.09


func toast(text: String, color := Color.WHITE) -> void:
	toast_label.text = text
	toast_label.modulate = Color(color, 1.0)
	_toast_t = 2.0


func push_feed(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	feed_box.add_child(l)
	while feed_box.get_child_count() > 6:
		feed_box.get_child(0).free()
	get_tree().create_timer(8.0).timeout.connect(l.queue_free)


func _process(delta: float) -> void:
	_hit_t -= delta
	for r in cross:
		r.color = Color(1, 0.2, 0.2) if _hit_t > 0.0 else Color(1, 1, 1, 0.85)
	_toast_t -= delta
	toast_label.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_dmg_t -= delta
	if _gain_t > 0.0:
		_gain_t = maxf(0.0, _gain_t - delta)
		var done := 1.0 - _gain_t / Config.PICKUP_GAIN_TIME
		gain_label.position.y = GAIN_AT.y - Config.PICKUP_GAIN_RISE * (1.0 - (1.0 - done) * (1.0 - done))
		gain_label.modulate.a = clampf(_gain_t / 0.35, 0.0, 1.0)
	var low := _last_hp > 0 and float(_last_hp) <= Config.PLAYER_HP * Config.LOW_HP_FRACTION
	var pulse := 0.12 + 0.08 * sin(Time.get_ticks_msec() * 0.008) if low else 0.0 # heartbeat when hurt
	damage.color.a = maxf(clampf(_dmg_t, 0.0, 0.3), pulse)
	pause_panel.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED
	perf_label.visible = Settings.get_value("show_draws")
	perf_label.text = "%d fps · %d draws · ping %d ms" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Net.ping_ms()]
