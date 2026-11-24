class_name Hud
extends CanvasLayer
## In-game overlay: crosshair, health, info, kill feed, extraction bar, toasts, perf, pause menu.

signal leave_pressed
signal retry_pressed
signal chat_submitted(text: String) ## Enter in the chat line
signal chat_closed ## the chat line went away (sent or cancelled)

const GAIN_AT := Vector2(-420, -116)
const GAIN_COLOR := Color("9be29b")
const STAMINA_SIZE := Vector2(190, 6)
const STAMINA_COLOR := Color("d8e6f0")
const STAMINA_WINDED := Color("ff7a5a")
const STAMINA_FADE := 0.25 ## seconds

var hp_label: Label
var info_label: Label
var perf_label: Label
var toast_label: Label
var feed_box: VBoxContainer
var chat_box: VBoxContainer ## what was said, bottom left, above the status line
var chat_edit: LineEdit ## the line you type in (the chat key opens it)
var _chat: Array[String] = []
var prompt_label: Label
var weapon_label: Label
var root: Control           ## everything, scaled by the HUD scale setting
var ammo: AmmoPanel
var vitals: VitalsBar
var compass: Compass
var objective_text: ObjectiveText
var _chimed_for := "" ## the objective the chime last rang for
var markers: WorldMarkers
var hitmarker: HitMarker
var arcs: DamageArcs
var lens: LensBlood
var low_hp: ColorRect     ## low HP: a pulsing dark red edge, greyed and blurred
var _low := 0.0
const LOW_HP_SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
void fragment() {
	vec2 d = SCREEN_UV - 0.5;
	float edge = smoothstep(0.25, 0.75, length(d) * 1.4);
	float pulse = 0.75 + 0.25 * sin(TIME * 6.0);
	vec3 c = textureLod(screen, SCREEN_UV, edge * 3.0 * amount).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), amount * 0.6 * edge);
	c = mix(c, vec3(0.35, 0.0, 0.0), edge * amount * pulse * 0.7);
	COLOR = vec4(c, edge * amount);
}
"""
var _scale := 1.0
var _ammo_idle := 0.0
var _vitals_idle := 0.0
var gain_label: Label ## "+30" rising over the ammo count after a pickup
var inventory_label: Label ## what is carried besides guns, small, bottom left
var status_label: Label    ## wounds and what is being put on, above it
var director_label: Label  ## --director: the horde director's pace (host debug)
var spectate_label: Label  ## while dead: who you are watching and when you come back
var wheel_view: ItemWheelView ## the item wheel, while its key is held
var bleed_drops: BleedDrops ## blood at the bottom of the screen while bleeding
var ring: ProgressRing ## round the crosshair while a revive or a heal goes on
var grey: ColorRect ## drains the colour out of the screen while downed
const GREY_SHADER := """
shader_type canvas_item;
uniform float amount = 0.0;
uniform sampler2D screen : hint_screen_texture, filter_linear;
void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(mix(c, vec3(l) * 0.85, amount), 1.0);
}
"""
var heartbeat := Heartbeat.new() ## when to thump while HP is low
var objective_label: Label  ## the current objective and its clock, top centre
var countdown_label: Label  ## big numerals while the extraction clock runs
var last_beep_pitch := 0.0  ## pitch of the last countdown beep (tests)
var fade: ColorRect         ## the end: everything fades to white (or red)
var end_panel: PanelContainer
var end_title: Label
var end_detail: Label
var end_button: Button
var retry_button: Button     ## only the host may start the match again
var end_titles: Label
var score_rows: Array[Label] = []
var _rows_box: VBoxContainer
var _score: Dictionary = {}
var _score_t := 0.0
var _last_second := -1
var _ended := false
var _match_t := 0.0
var stamina_bar: ColorRect  ## the trough; only there while stamina is not full
var stamina_fill: ColorRect
var scope: ColorRect
var damage: ColorRect
var cross: Array[ColorRect] = []
var pause_panel: PanelContainer
var _last_hp := Config.PLAYER_HP
var _hit_t := 0.0
var _toast_t := 0.0
var _dmg_t := 0.0
var _gain_t := 0.0
var _stamina := 1.0


func _ready() -> void:
	grey = ColorRect.new()
	grey.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grey.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gs := Shader.new()
	gs.code = GREY_SHADER
	var gm := ShaderMaterial.new()
	gm.shader = gs
	grey.material = gm
	grey.visible = false
	add_child(grey) # first, so everything else on the HUD stays in colour
	ring = ProgressRing.new()
	add_child(ring)
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
	stamina_bar = ColorRect.new()
	stamina_bar.color = Color(0, 0, 0, 0.55)
	stamina_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	stamina_bar.position = Vector2(28, -76)
	stamina_bar.size = STAMINA_SIZE
	stamina_bar.modulate.a = 0.0
	add_child(stamina_bar)
	stamina_fill = ColorRect.new()
	stamina_fill.color = STAMINA_COLOR
	stamina_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stamina_fill.size = STAMINA_SIZE
	stamina_bar.add_child(stamina_fill)
	spectate_label = _label(22, Control.PRESET_CENTER_BOTTOM, Vector2(-400, -190))
	spectate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spectate_label.size.x = 800
	director_label = _label(14, Control.PRESET_TOP_LEFT, Vector2(24, 96))
	director_label.modulate = Color(1, 0.85, 0.4, 0.9)
	status_label = _label(17, Control.PRESET_BOTTOM_LEFT, Vector2(28, -132))
	inventory_label = _label(15, Control.PRESET_BOTTOM_LEFT, Vector2(28, -104))
	inventory_label.modulate.a = 0.85
	bleed_drops = BleedDrops.new()
	add_child(bleed_drops)
	wheel_view = ItemWheelView.new()
	add_child(wheel_view)
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

	objective_label = _label(20, Control.PRESET_CENTER_TOP, Vector2(-400, 22))
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.size.x = 800
	countdown_label = _label(120, Control.PRESET_CENTER, Vector2(-200, -230))
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	countdown_label.size.x = 400
	countdown_label.add_theme_color_override("font_color", Color("9bf0a4"))
	countdown_label.add_theme_constant_override("shadow_offset_y", 4)
	countdown_label.visible = false

	feed_box = VBoxContainer.new()
	feed_box.position = Vector2(24, 20)
	add_child(feed_box)
	chat_box = VBoxContainer.new()
	chat_box.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	chat_box.position = Vector2(28, -330)
	chat_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chat_box)
	chat_edit = LineEdit.new()
	chat_edit.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	chat_edit.position = Vector2(28, -170)
	chat_edit.size = Vector2(460, 30)
	chat_edit.max_length = Config.CHAT_MAX_CHARS
	chat_edit.placeholder_text = "Say something (Enter to send, Esc to cancel)"
	chat_edit.visible = false
	chat_edit.text_submitted.connect(_on_chat_submitted)
	chat_edit.gui_input.connect(func(e: InputEvent):
		if e.is_action_pressed("ui_cancel"):
			close_chat()
			chat_edit.accept_event())
	add_child(chat_edit)

	prompt_label = _label(20, Control.PRESET_CENTER, Vector2(-300, 60))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.size.x = 600

	_build_pause()
	_build_end()
	_build_hud2()


func _build_hud2() -> void:
	weapon_label.visible = false # (still written: the ammo panel draws it now)
	objective_label.visible = false # (still written: the typed objective draws it now)
	ammo = AmmoPanel.new()
	add_child(ammo)
	vitals = VitalsBar.new()
	add_child(vitals)
	compass = Compass.new()
	add_child(compass)
	objective_text = ObjectiveText.new()
	add_child(objective_text)
	markers = WorldMarkers.new()
	add_child(markers)
	move_child(markers, 1) # under the rest
	low_hp = ColorRect.new()
	low_hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	low_hp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var lsh := Shader.new()
	lsh.code = LOW_HP_SHADER
	var lmat := ShaderMaterial.new()
	lmat.shader = lsh
	low_hp.material = lmat
	low_hp.visible = false
	add_child(low_hp)
	move_child(low_hp, 1)
	lens = LensBlood.new()
	add_child(lens)
	arcs = DamageArcs.new()
	add_child(arcs)
	hitmarker = HitMarker.new()
	add_child(hitmarker)
	# Everything under one root, so the HUD scale setting can scale it and it still fills the screen.
	root = Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in get_children():
		c.reparent(root, false)
	add_child(root)
	apply_scale(Settings.get_value("hud_scale"))
	get_viewport().size_changed.connect(func(): apply_scale(_scale))
	Settings.changed.connect(func(key: String):
		if key == "hud_scale":
			apply_scale(Settings.get_value(key)))


## Draw the HUD `s` times bigger, laid out in a screen `1 / s` the size so it still fills it.
func apply_scale(s: float) -> void:
	_scale = s
	var vp := get_viewport().get_visible_rect().size
	root.scale = Vector2(s, s)
	root.position = Vector2.ZERO
	root.size = vp / s


## How a gun fires, for the ammo panel.
static func fire_mode(d: Dictionary) -> String:
	match int(d.cycle):
		Weapons.Cycle.PUMP: return "PUMP"
		Weapons.Cycle.BOLT: return "BOLT"
	return "AUTO" if d.auto else "SEMI"


## The gun in hand: name, fire mode, magazine, reserve (-1: no limit).
func set_gun(d: Dictionary, rounds: int, reloading: bool, reserve := -1) -> void:
	set_weapon(d.name, rounds, reloading, reserve)
	if ammo.set_gun(d, rounds, reloading, reserve):
		_ammo_idle = 0.0


## Health (and temporary HP above it), and a mark for each wound.
func set_vitals(hp: int, temp: int, status: PlayerStatus) -> void:
	if vitals.set_vitals(hp, temp, status.bleed) or hp < Config.PLAYER_HP or status.bleed > 0:
		_vitals_idle = 0.0


## The compass: which way you look (a bearing) and what to mark on it.
func set_compass(heading: float, ticks: Array) -> void:
	compass.set_view(heading, ticks)


## Idle parts fade; a change brings them back at once.
## Low HP: the edges of the screen pulse dark red, go grey and blur, more the lower it is.
func step_low_hp(delta: float) -> void:
	var line := Config.PLAYER_HP * Config.LOW_HP_FRACTION
	var want := 0.0 if _last_hp <= 0 or _last_hp > line else 0.6 + 0.4 * (1.0 - float(_last_hp) / line)
	_low = move_toward(_low, want, delta * 2.0)
	low_hp.visible = _low > 0.0
	(low_hp.material as ShaderMaterial).set_shader_parameter("amount", _low)


func low_hp_amount() -> float:
	return _low


func step_fades(delta: float) -> void:
	_ammo_idle += delta
	_vitals_idle += delta
	for pair in [[ammo, _ammo_idle], [vitals, _vitals_idle]]:
		var node: Control = pair[0]
		if float(pair[1]) < Config.HUD_FADE_AFTER:
			node.modulate.a = 1.0
		else:
			node.modulate.a = move_toward(node.modulate.a, Config.HUD_FADED, delta * 1.5)


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


func _build_end() -> void:
	fade = ColorRect.new()
	fade.color = Color(1, 1, 1, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	end_panel = PanelContainer.new()
	end_panel.set_anchors_preset(Control.PRESET_CENTER)
	end_panel.custom_minimum_size = Vector2(760, 0)
	end_panel.position = Vector2(-380, -170)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	end_panel.add_child(v)
	end_title = Label.new()
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 44)
	v.add_child(end_title)
	end_detail = Label.new()
	end_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(end_detail)
	_rows_box = VBoxContainer.new()
	v.add_child(_rows_box)
	end_titles = Label.new()
	end_titles.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_titles.modulate = Color("ffd27a")
	v.add_child(end_titles)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	v.add_child(buttons)
	retry_button = Button.new()
	retry_button.text = "Retry"
	retry_button.visible = false
	retry_button.pressed.connect(func(): retry_pressed.emit())
	WorldSounds.wire_button(retry_button)
	buttons.add_child(retry_button)
	end_button = Button.new()
	end_button.text = "Back to the menu"
	end_button.pressed.connect(func(): leave_pressed.emit())
	WorldSounds.wire_button(end_button, true)
	buttons.add_child(end_button)
	end_panel.visible = false
	add_child(end_panel)


## The extraction clock: big numerals while it runs, a beep for each of the last seconds.
func set_countdown(view: Dictionary) -> void:
	var left: float = view.get("left", -1.0)
	var on: bool = view.get("kind", "") == "extract" and view.get("counting", false) \
		and view.get("status", 0) == MissionRules.Status.RUNNING and left > 0.0
	countdown_label.visible = on
	if not on:
		_last_second = -1
		return
	var whole := ceili(left)
	countdown_label.text = str(whole)
	if whole != _last_second and whole <= Config.EXTRACT_BEEPS:
		last_beep_pitch = Config.EXTRACT_BEEP_PITCH * pow(Config.EXTRACT_BEEP_STEP, Config.EXTRACT_BEEPS - whole)
		Sfx.play_ui("beep", 0.0, last_beep_pitch)
	_last_second = whole


## The host's numbers for the end screen (Score.summary): a row per player, counted up.
func set_final_score(summary: Dictionary) -> void:
	_score = summary
	_score_t = 0.0
	for r in score_rows:
		r.free()
	score_rows.clear()
	for row: Dictionary in summary.get("rows", []):
		var l := Label.new()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rows_box.add_child(l)
		score_rows.append(l)
	var lines := []
	var titles: Dictionary = summary.get("titles", {})
	for title: String in titles:
		lines.append("%s: %s" % [title, titles[title]])
	end_titles.text = "   ·   ".join(lines)
	var whole := floori(float(summary.get("seconds", _match_t)))
	end_detail.text = "Time %d:%02d%s" % [whole / 60, whole % 60, "   NEW BEST" if summary.get("best", false) else ""]
	_write_rows(0.0)


## The rows with every counter at `share` (0..1) of its final value.
func _write_rows(share: float) -> void:
	var rows: Array = _score.get("rows", [])
	for i in mini(rows.size(), score_rows.size()):
		var r: Dictionary = rows[i]
		var n := func(key: String) -> int: return roundi(float(r.get(key, 0)) * share)
		var shots: int = r.get("shots", 0)
		var accuracy := roundi(100.0 * float(r.get("hits", 0)) / shots * share) if shots > 0 else 0
		score_rows[i].text = "%s    %d kills · %d heads · %d limbs · %d%% hit · %d hurt · %d revives · %d m" % [
			r.get("name", "Survivor"), n.call("kills"), n.call("headshots"), n.call("severs"), accuracy,
			n.call("damage"), n.call("revives"), n.call("distance")]


## The mission is over: fade, then the end screen with how long it took.
func show_end(won: bool, reason: String) -> void:
	if _ended:
		return
	_ended = true
	fade.color = Color(1, 1, 1, 0) if won else Color(0.45, 0, 0, 0)
	end_title.text = "EXTRACTED" if won else "MISSION FAILED"
	end_title.add_theme_color_override("font_color", Color("7be08a") if won else Color("ff5555"))
	var whole := floori(_match_t)
	end_detail.text = ("Time %d:%02d" % [whole / 60, whole % 60]) + ("" if won else "\n" + reason)


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
	WorldSounds.wire_button(resume, true)
	v.add_child(resume)
	var leave := Button.new()
	leave.text = "Leave game"
	leave.pressed.connect(func(): leave_pressed.emit())
	WorldSounds.wire_button(leave, true)
	v.add_child(leave)
	var help := Label.new()
	help.text = "WASD move · Shift sprint · Ctrl crouch · Space jump (sprint into low cover to vault it)\nLeft click shoot · Right click aim, or use / pick up what you look at\nR reload · V shove · 1-9 or mouse wheel change gun · Q last gun · Esc menu\nH heal · G throw · hold Tab for the item wheel"
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


## What right-click (or `action`'s key) would do now: "[RMB] Open door".
func set_prompt(text: String, action := "") -> void:
	if text == "" or action == "":
		prompt_label.text = text
	else:
		prompt_label.text = "[%s] %s" % [Controls.label_of(action), text]


## Rounds in the magazine / rounds in reserve (`reserve` -1: no limit).
func set_weapon(gun_name: String, rounds: int, reloading: bool, reserve := -1) -> void:
	var left := "∞" if reserve < 0 else str(reserve)
	weapon_label.text = "%s   %s / %s" % [gun_name, "RELOADING" if reloading else str(rounds), left]
	var empty := rounds == 0 and not reloading
	weapon_label.modulate = Color("ff5555") if empty else (Color("ffcc66") if reserve == 0 else Color.WHITE)


## The mission as every peer is told it (MissionRules.state): the objective's text and what is
## left on its clock, or how the mission ended. Nothing in free play.
## `zombies`: how many are about (shown while a wave is on).
func set_objective(view: Dictionary, zombies := 0) -> void:
	var status: int = view.get("status", MissionRules.Status.IDLE)
	var text: String = view.get("text", "")
	if text != _chimed_for:
		_chimed_for = text
		if text != "":
			Sfx.play_ui("objective_chime", -8.0) # a new objective
	var left: float = view.get("left", -1.0)
	objective_label.modulate = Color.WHITE
	if status == MissionRules.Status.FAILED:
		objective_label.text = "MISSION FAILED  ·  %s" % view.get("reason", "")
		objective_label.modulate = Color("ff5555")
	elif status == MissionRules.Status.WON:
		objective_label.text = "MISSION COMPLETE"
		objective_label.modulate = Color("7be08a")
	elif status != MissionRules.Status.RUNNING or text == "":
		objective_label.text = ""
	elif int(view.get("waves", 0)) > 0: # defending: the wave, what is left of it, the clocks
		var line := "▸ %s   Wave %d/%d" % [text, view.get("wave", 0), view.waves]
		if view.get("calm", false):
			line += "   next wave %s" % _clock(left)
		else:
			line += "   %d left" % zombies
			if view.get("heli", false):
				line += "   Helicopter %s" % _clock(left)
		objective_label.text = line
	elif left >= 0.0:
		objective_label.text = "▸ %s   %s" % [text, _clock(left)]
	else:
		objective_label.text = "▸ %s" % text
	# The typed line: what the objective is types in; its clock and counts show at once.
	var full := objective_label.text
	var main := ("▸ " + text) if status == MissionRules.Status.RUNNING and full.begins_with("▸ " + text) else full
	objective_text.color = objective_label.modulate
	objective_text.show_text(main, full.substr(main.length()))


static func _clock(seconds: float) -> String:
	var whole := ceili(maxf(seconds, 0.0))
	return "%d:%02d" % [whole / 60, whole % 60]


## `share` 0..1 of a full bar; `winded` = ran dry and cannot sprint yet.
func set_stamina(share: float, winded: bool) -> void:
	_stamina = clampf(share, 0.0, 1.0)
	stamina_fill.size.x = STAMINA_SIZE.x * _stamina
	stamina_fill.color = STAMINA_WINDED if winded else STAMINA_COLOR


## What is carried besides guns: "Medkit 1 · Bandage 2 · Frag grenade 3 (ready)". Empty, nothing shows.
func set_inventory(inv: Inventory) -> void:
	var parts: Array[String] = []
	for item: StringName in Inventory.ITEMS:
		if inv.count(item) > 0:
			var ready := " (ready)" if item == inv.selected_throwable() and inv.throwables().size() > 1 else ""
			parts.append("%s %d%s" % [Inventory.item_name(item), inv.count(item), ready])
	for id in inv.keys():
		parts.append("Key %s" % id)
	inventory_label.text = "  ·  ".join(parts)


## What a dead player's screen says ("" while playing).
func set_spectate(text: String) -> void:
	spectate_label.text = text


## The director's pace as text (`--director`); "" hides it.
func set_director(text: String) -> void:
	director_label.text = text


## "BLEEDING x2" and what is being put on, with the seconds left. Nothing when all is well.
func set_status(status: PlayerStatus) -> void:
	var parts: Array[String] = []
	if status.bleed > 0:
		parts.append("BLEEDING x%d" % status.bleed)
	if status.downed:
		parts.append(("BEING GOT UP  %.1f s" % status.revive_left) if status.revive_left > 0.0 else "DOWN  %d s" % ceili(status.down_left))
	if status.using == &"revive":
		parts.append("Getting them up  %.1f s" % status.use_left)
	elif status.is_using():
		parts.append("%s  %.1f s" % [Inventory.item_name(status.using), status.use_left])
	status_label.text = "   ·   ".join(parts)
	status_label.modulate = Color("ff6a5a") if status.bleed > 0 or status.downed else Color.WHITE
	bleed_drops.bleed = 0 if status.dead else status.bleed
	ring.set_progress(ring_for(status))
	var g := grey_for(status)
	grey.visible = g > 0.0
	(grey.material as ShaderMaterial).set_shader_parameter("amount", g)


## How grey the screen is: none standing, more and more as a downed player's clock runs out.
static func grey_for(status: PlayerStatus) -> float:
	if not status.downed or status.down_total <= 0.0:
		return 0.0
	return lerpf(Config.DOWNED_GREY_MIN, 0.9, clampf(1.0 - status.down_left / status.down_total, 0.0, 1.0))


func grey_amount() -> float:
	return (grey.material as ShaderMaterial).get_shader_parameter("amount")


## How far along the ring round the crosshair is (-1: no ring): what you are putting on or the
## teammate you are getting up, or being got up yourself.
static func ring_for(status: PlayerStatus) -> float:
	if status.is_using() and status.use_total > 0.0:
		return 1.0 - status.use_left / status.use_total
	if status.downed and status.revive_left > 0.0 and status.revive_total > 0.0:
		return 1.0 - status.revive_left / status.revive_total
	return -1.0


## The item wheel is up (or not): drawn round the middle of the screen.
func set_wheel(wheel: ItemWheel) -> void:
	wheel_view.wheel = wheel
	wheel_view.visible = wheel.open
	if wheel.open:
		wheel_view.queue_redraw()


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


## A chat line from someone, shown for a while.
func push_chat(text: String) -> void:
	_chat.append(text)
	while _chat.size() > Config.CHAT_LINES:
		_chat.pop_front()
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	l.add_theme_color_override("font_color", Color("cfe8ff"))
	chat_box.add_child(l)
	while chat_box.get_child_count() > Config.CHAT_LINES:
		chat_box.get_child(0).free()
	get_tree().create_timer(Config.CHAT_SHOW).timeout.connect(l.queue_free)


## The lines said so far (the last `Config.CHAT_LINES`).
func chat_lines() -> Array[String]:
	return _chat


func open_chat() -> void:
	chat_edit.text = ""
	chat_edit.visible = true
	chat_edit.grab_focus()


func close_chat() -> void:
	chat_edit.release_focus()
	chat_edit.visible = false
	chat_closed.emit()


func _on_chat_submitted(text: String) -> void:
	if text.strip_edges() != "":
		chat_submitted.emit(text)
	close_chat()


func push_feed(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_shadow_color", Color.BLACK)
	feed_box.add_child(l)
	while feed_box.get_child_count() > 6:
		feed_box.get_child(0).free()
	get_tree().create_timer(8.0).timeout.connect(l.queue_free)


func _process(delta: float) -> void:
	step_fades(delta)
	step_low_hp(delta)
	_hit_t -= delta
	for r in cross:
		r.color = Color(1, 0.2, 0.2) if _hit_t > 0.0 else Color(1, 1, 1, 0.85)
	_toast_t -= delta
	toast_label.modulate.a = clampf(_toast_t / 0.4, 0.0, 1.0)
	_dmg_t -= delta
	if _ended:
		fade.color.a = move_toward(fade.color.a, 0.9, delta / Config.END_FADE_TIME)
		if fade.color.a >= 0.8 and not end_panel.visible:
			end_panel.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if end_panel.visible and _score_t < Config.SCORE_TICK_TIME: # the counters tick up once it is shown
			_score_t = minf(Config.SCORE_TICK_TIME, _score_t + delta)
			var u := _score_t / Config.SCORE_TICK_TIME
			_write_rows(1.0 - (1.0 - u) * (1.0 - u))
	else:
		_match_t += delta
	stamina_bar.modulate.a = move_toward(stamina_bar.modulate.a, 0.0 if _stamina >= 0.999 else 1.0, delta / STAMINA_FADE)
	if _gain_t > 0.0:
		_gain_t = maxf(0.0, _gain_t - delta)
		var done := 1.0 - _gain_t / Config.PICKUP_GAIN_TIME
		gain_label.position.y = GAIN_AT.y - Config.PICKUP_GAIN_RISE * (1.0 - (1.0 - done) * (1.0 - done))
		gain_label.modulate.a = clampf(_gain_t / 0.35, 0.0, 1.0)
	var low := _last_hp > 0 and float(_last_hp) <= Config.PLAYER_HP * Config.LOW_HP_FRACTION
	var pulse := 0.03 + 0.02 * sin(Time.get_ticks_msec() * 0.008) if low else 0.0 # a faint all-over pulse; the edges are low_hp's
	damage.color.a = maxf(clampf(_dmg_t, 0.0, 0.3), pulse)
	if heartbeat.step(delta, _last_hp if not _ended else 0):
		Sfx.play_ui("heartbeat")
	pause_panel.visible = Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not _ended
	perf_label.visible = Settings.get_value("show_draws")
	perf_label.text = "%d fps · %d draws · ping %d ms" % [
		Engine.get_frames_per_second(),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Net.ping_ms()]
