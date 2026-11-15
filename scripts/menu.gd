class_name Menu
extends CanvasLayer
## Main menu: the whole Joinville city map with a pin on every mission POI. Click a pin to read
## the mission, Start to host it. On the side: name, training ground (free play), join by IP
## and a live list of LAN games, quit.

signal host_pressed                       ## free play on the training ground (no mission)
signal mission_pressed(id: String)        ## host the city map, everyone at this POI
signal join_pressed(ip: String)

const PANEL_W := 400.0
const GREEN := Color("99ff66")
const AMBER := Color("ffcc66")
const KINDS := { "EXTRACTION": Color("66ccff"), "DEFEND": Color("ff8866"), "RUN": Color("ffcc66") }

var map_area: Control
var map_texture: TextureRect
var pins := {}                 ## id -> PoiPin
var selected := ""
var mission_title: Label
var mission_kind: Label
var mission_brief: Label
var mission_route: Label
var start_button: Button
var free_play_button: Button
var name_edit: LineEdit
var ip_edit: LineEdit
var status: Label
var lan_list: VBoxContainer
var _pois := {}                ## id -> 0..1 position on the map picture
var _lan_refresh := 0.0


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0b0d10")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var picture := CityMap.menu_picture()
	_pois = picture.pois
	map_area = Control.new()
	map_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_area.offset_right = -PANEL_W
	add_child(map_area)
	map_texture = TextureRect.new()
	map_texture.texture = ImageTexture.create_from_image(picture.image)
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	map_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_texture.offset_left = 24
	map_texture.offset_top = 24
	map_texture.offset_right = -24
	map_texture.offset_bottom = -24
	map_area.add_child(map_texture)
	for id: String in Missions.ORDER:
		var pin := PoiPin.new(id, Missions.INFO[id].title, KINDS[Missions.INFO[id].kind])
		pin.pressed.connect(select.bind(id))
		map_area.add_child(pin)
		pins[id] = pin
	map_area.resized.connect(_place_pins)

	var title := Label.new()
	title.text = "ZOMBIE EXTRACTION"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", GREEN)
	title.position = Vector2(36, 28)
	map_area.add_child(title)
	var sub := Label.new()
	sub.text = "JOINVILLE · SANTA CATARINA  —  pick a mission on the map"
	sub.modulate.a = 0.6
	sub.position = Vector2(40, 80)
	map_area.add_child(sub)

	_build_panel()
	_show_mission()
	_place_pins.call_deferred()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101317", 0.96)
	style.border_color = Color("2a3138")
	style.border_width_left = 1
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 28
	style.content_margin_bottom = 24
	panel.add_theme_stylebox_override("panel", style)
	panel.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -PANEL_W
	add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.max_length = 20
	name_edit.text = Net.player_name
	v.add_child(name_edit)
	v.add_child(HSeparator.new())

	mission_kind = Label.new()
	mission_kind.add_theme_font_size_override("font_size", 13)
	v.add_child(mission_kind)
	mission_title = Label.new()
	mission_title.add_theme_font_size_override("font_size", 24)
	mission_title.autowrap_mode = TextServer.AUTOWRAP_WORD
	v.add_child(mission_title)
	mission_brief = Label.new()
	mission_brief.autowrap_mode = TextServer.AUTOWRAP_WORD
	mission_brief.modulate.a = 0.8
	mission_brief.custom_minimum_size.y = 96
	v.add_child(mission_brief)
	mission_route = Label.new()
	mission_route.autowrap_mode = TextServer.AUTOWRAP_WORD
	mission_route.modulate = Color(1, 1, 1, 0.55)
	v.add_child(mission_route)

	start_button = Button.new()
	start_button.text = "START MISSION"
	start_button.custom_minimum_size.y = 52
	start_button.add_theme_font_size_override("font_size", 20)
	start_button.add_theme_color_override("font_color", Color("0b0d10"))
	start_button.add_theme_color_override("font_hover_color", Color("0b0d10"))
	start_button.add_theme_color_override("font_pressed_color", Color("0b0d10"))
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": GREEN, "hover": GREEN.lightened(0.25), "pressed": GREEN.darkened(0.2),
			"disabled": Color("2a3138")}[state]
		sb.set_corner_radius_all(3)
		start_button.add_theme_stylebox_override(state, sb)
	start_button.pressed.connect(func():
		if selected != "":
			_save_name()
			mission_pressed.emit(selected))
	v.add_child(start_button)
	var note := Label.new()
	note.text = "Objectives aren't built yet: a mission starts you at its POI on the city map."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 12)
	note.modulate.a = 0.4
	v.add_child(note)
	v.add_child(HSeparator.new())

	free_play_button = Button.new()
	free_play_button.text = "Training ground (free play)"
	free_play_button.pressed.connect(func(): _save_name(); host_pressed.emit())
	v.add_child(free_play_button)

	var row := HBoxContainer.new()
	ip_edit = LineEdit.new()
	ip_edit.placeholder_text = "Host IP, e.g. 192.168.1.7"
	ip_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ip_edit.text_submitted.connect(func(_t): _join(ip_edit.text))
	row.add_child(ip_edit)
	var join := Button.new()
	join.text = "Join"
	join.pressed.connect(func(): _join(ip_edit.text))
	row.add_child(join)
	v.add_child(row)
	var lan_title := Label.new()
	lan_title.text = "Games on your network:"
	lan_title.modulate.a = 0.6
	v.add_child(lan_title)
	lan_list = VBoxContainer.new()
	v.add_child(lan_list)

	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
	status.modulate = AMBER
	v.add_child(status)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spacer)
	var quit := Button.new()
	quit.text = "Quit"
	quit.pressed.connect(func(): get_tree().quit())
	v.add_child(quit)


## Pick a mission (a pin was clicked, or `--mission=` on the command line).
func select(id: String) -> void:
	if not Missions.INFO.has(id):
		return
	selected = id
	for k: String in pins:
		(pins[k] as PoiPin).set_pressed_no_signal(k == id)
		(pins[k] as PoiPin).queue_redraw()
	_show_mission()


func _show_mission() -> void:
	start_button.disabled = selected == ""
	if selected == "":
		mission_kind.text = "NO MISSION PICKED"
		mission_kind.modulate = Color(1, 1, 1, 0.5)
		mission_title.text = "Click a place on the map"
		mission_brief.text = "Five places in central Joinville, each its own mission. Pick one to read its brief."
		mission_route.text = ""
		return
	var info: Dictionary = Missions.INFO[selected]
	mission_kind.text = "%s   %s" % [info.kind, "■".repeat(info.difficulty) + "□".repeat(5 - info.difficulty)]
	mission_kind.modulate = KINDS[info.kind]
	mission_title.text = info.title
	mission_brief.text = info.brief
	mission_route.text = "Start: %s\nGoal: %s" % [info.start, info.goal]


## Where a POI is drawn on screen (inside map_area).
func pin_point(id: String) -> Vector2:
	var r := map_rect()
	var uv: Vector2 = _pois[id]
	return r.position + uv * r.size


## The part of map_area the picture actually covers (it keeps its aspect).
func map_rect() -> Rect2:
	var box := Rect2(map_texture.position, map_texture.size)
	var tex := map_texture.texture.get_size()
	var s := minf(box.size.x / tex.x, box.size.y / tex.y)
	var size := tex * s
	return Rect2(box.position + (box.size - size) * 0.5, size)


func _place_pins() -> void:
	for id: String in pins:
		var pin: PoiPin = pins[id]
		pin.position = pin_point(id) - pin.anchor_point()


func open(message := "") -> void:
	visible = true
	status.text = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Net.start_listening()


func close() -> void:
	visible = false
	Net.stop_listening()


func _save_name() -> void:
	var n := name_edit.text.strip_edges()
	Net.player_name = n if n != "" else "Survivor"


func _join(ip: String) -> void:
	if ip.strip_edges() == "":
		status.text = "Type the host's IP address first."
		return
	_save_name()
	status.text = "Connecting to %s…" % ip
	join_pressed.emit(ip)


func _process(delta: float) -> void:
	if not visible:
		return
	_lan_refresh -= delta
	if _lan_refresh > 0.0:
		return
	_lan_refresh = 0.5
	for c in lan_list.get_children():
		c.queue_free()
	if Net.lan_games.is_empty():
		var none := Label.new()
		none.text = "  (none found yet)"
		none.modulate.a = 0.45
		lan_list.add_child(none)
	for ip in Net.lan_games:
		var g: Dictionary = Net.lan_games[ip]
		var b := Button.new()
		b.text = "%s's game · %d players · %s" % [g.name, g.players, ip]
		b.pressed.connect(func(): _join(ip))
		lan_list.add_child(b)


## A map pin: a ring on the POI with its name beside it. Toggles on when picked.
class PoiPin extends Button:
	const R := 9.0
	var id := ""
	var tint := Color.WHITE

	func _init(id_: String, title: String, tint_: Color) -> void:
		id = id_
		tint = tint_
		toggle_mode = true
		flat = true
		focus_mode = Control.FOCUS_NONE
		text = title
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		add_theme_font_size_override("font_size", 15)
		add_theme_constant_override("outline_size", 6)
		add_theme_color_override("font_outline_color", Color("0b0d10"))
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			add_theme_color_override(c, Color.WHITE if c != "font_color" else Color(1, 1, 1, 0.85))
		var pad := StyleBoxEmpty.new()
		pad.content_margin_left = R * 2 + 10
		pad.content_margin_right = 6
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			add_theme_stylebox_override(s, pad)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		size = get_combined_minimum_size()

	## The ring's centre, relative to the button: put this on the POI.
	func anchor_point() -> Vector2:
		return Vector2(R + 2, size.y * 0.5)

	func _draw() -> void:
		var c := anchor_point()
		var lit := button_pressed or is_hovered()
		if button_pressed:
			draw_circle(c, R * 2.2, Color(tint, 0.18))
		draw_circle(c, R, Color("0b0d10", 0.85))
		draw_arc(c, R, 0, TAU, 32, tint if lit else Color(tint, 0.75), 3.0 if lit else 2.0, true)
		draw_circle(c, R * 0.35, tint)
