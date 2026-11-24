class_name Menu
extends CanvasLayer
## Main menu: all of central Joinville at night, every street of it, with the streets the game
## builds glowing red and a pin on every mission POI. Click a pin to read the mission, Start to
## host it. On the side: name, training (the test corridor), join by IP / LAN games, quit.
##
## The city is CityPicture (classified from the reference map by tools/trace_city.py), coloured by
## a palette shader, forest and parks as scattered trees. Pins and red streets are drawn over it.

signal host_pressed                       ## free play on the training corridor (no mission)
signal mission_pressed(id: String)        ## host the city map, everyone at this POI
signal join_pressed(ip: String)

const PANEL_W := 400.0
const SHOW_TOP := -110.0     ## first joinville.png row at the window's top (the Mirante's hairpin)
const MIRANTE_GAP := 60.0    ## pixels between the Mirante pin and the panel
const RED := Color("c4453a")
const AMBER := Color("ffcc66")
const BG := Color("0c0b0b")
const KINDS := { "EXTRACTION": Color("e8d7c8"), "DEFEND": Color("ff8a5c"), "RUN": Color("ffcc66") }
## Ground, building, street, main road, water, green: the dark city, a little red in it.
const PALETTE := [Color("181515"), Color("2a2424"), Color("5a4848"), Color("6e423d"), Color("1c2a33"), Color("1d1a19")]

const SHADER := """
shader_type canvas_item;
uniform sampler2D classes : filter_nearest;
uniform vec2 size;
uniform vec4 pal[6];
vec3 class_colour(vec2 uv) {
	int k = int(texture(classes, uv).r * 255.0 + 0.5);
	return pal[clamp(k, 0, 5)].rgb;
}
// Forest and parks: the ground's grey with little trees scattered over it, one per cell at most.
float tree(vec2 uv) {
	vec2 p = uv * size / 16.0;
	vec2 cell = floor(p);
	float h = fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
	if (h > 0.55) return 0.0;
	vec2 at = cell + 0.25 + 0.5 * vec2(fract(h * 17.0), fract(h * 29.0));
	vec2 d = (p - at) * 16.0;                        // texels from the tree's centre
	float crown = step(length(d - vec2(0.0, -1.5)), 3.4);
	float trunk = step(abs(d.x), 0.8) * step(1.5, d.y) * step(d.y, 4.5);
	return max(crown, trunk);
}
uniform vec2 uv_from = vec2(0.0);
uniform vec2 uv_span = vec2(1.0);
void fragment() {
	// The rect is the whole window; uv_from/uv_span say which part of the picture it shows. Past
	// the picture's edges it mirrors (a backdrop; the real city is inside).
	vec2 uv = uv_from + UV * uv_span;
	uv = 1.0 - abs(mod(uv, 2.0) - 1.0);
	vec2 px = TEXTURE_PIXEL_SIZE * 0.25;
	vec3 c = (class_colour(uv + vec2(-px.x, -px.y)) + class_colour(uv + vec2(px.x, -px.y))
		+ class_colour(uv + vec2(-px.x, px.y)) + class_colour(uv + vec2(px.x, px.y))) * 0.25;
	if (int(texture(classes, uv).r * 255.0 + 0.5) == 5) {
		c = mix(c, vec3(0.27, 0.25, 0.24), tree(uv));
	}
	COLOR = vec4(c, 1.0);
}
"""

var map_area: Control
var map_texture: TextureRect
var lines_layer: Control
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
var _lan_refresh := 0.0


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	map_area = Control.new()
	map_area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(map_area)
	map_texture = TextureRect.new()
	map_texture.texture = ImageTexture.create_from_image(CityPicture.image())
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_SCALE
	map_texture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST # classes, not colours: never blend them
	map_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var mat := ShaderMaterial.new()
	mat.shader = Shader.new()
	mat.shader.code = SHADER
	mat.set_shader_parameter("pal", PALETTE)
	mat.set_shader_parameter("classes", map_texture.texture)
	mat.set_shader_parameter("size", Vector2(CityPicture.W, CityPicture.H))
	map_texture.material = mat
	map_area.add_child(map_texture)

	lines_layer = Control.new()
	lines_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lines_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines_layer.draw.connect(_draw_lines)
	map_area.add_child(lines_layer)

	for id: String in Missions.ORDER:
		var poi: Dictionary = CityData.POIS[id]
		var east: bool = poi.at.x > 1600.0 # far east, by the panel: name on the left of the pin
		var pin := PoiPin.new(id, Missions.INFO[id].title, KINDS[Missions.INFO[id].kind], east)
		pin.pressed.connect(select.bind(id))
		WorldSounds.wire_button(pin)
		map_area.add_child(pin)
		pins[id] = pin
	map_area.resized.connect(_relayout)

	var title := Label.new()
	title.text = "MAKE ALIVE"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", RED)
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_color_override("font_outline_color", BG)
	title.position = Vector2(36, 24)
	map_area.add_child(title)
	var sub := Label.new()
	sub.text = "JOINVILLE · SANTA CATARINA  —  pick a mission on the map"
	sub.modulate = Color(1, 0.85, 0.82, 0.6)
	sub.add_theme_constant_override("outline_size", 6)
	sub.add_theme_color_override("font_outline_color", BG)
	sub.position = Vector2(40, 76)
	map_area.add_child(sub)

	_build_panel()
	_show_mission()
	_relayout.call_deferred()


## Every street the game builds, as screen polylines (CityData.STREETS order).
func street_lines() -> Array:
	var out := []
	for street: Dictionary in CityData.STREETS:
		var line := PackedVector2Array()
		for p: Vector2 in street.pts:
			line.append(px_point(p))
		out.append(line)
	return out


func _draw_lines() -> void:
	var r := map_rect()
	var scale := r.size.x / CityPicture.W / CityData.M_PER_PX # screen pixels per metre
	var lines := street_lines()
	for pass_i in 2: # a soft glow under, the line on top
		for i in lines.size():
			var width := CityData.width(CityData.STREETS[i])
			var major := width >= 12.0
			var w := maxf(1.0, width * scale * (0.5 if major else 0.4))
			if pass_i == 0:
				lines_layer.draw_polyline(lines[i], Color(RED, 0.16), w * 3.5, true)
			else:
				lines_layer.draw_polyline(lines[i], RED if major else RED.darkened(0.15), w, true)


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


## Where a joinville.png pixel is drawn on screen (inside map_area).
func px_point(px: Vector2) -> Vector2:
	var r := map_rect()
	return r.position + (px - Vector2(CityPicture.LEFT, CityPicture.TOP)) / Vector2(CityPicture.W, CityPicture.H) * r.size


## Where a POI is drawn on screen.
func pin_point(id: String) -> Vector2:
	var poi: Dictionary = CityData.POIS[id]
	return px_point(poi.at)


## Where the whole picture lies on screen (bigger than the window). Scaled so joinville.png's rows
## from SHOW_TOP down fill the window's height, shifted so the Mirante sits left of the panel.
func map_rect() -> Rect2:
	var view := map_area.size
	var rows := float(CityPicture.H) - (SHOW_TOP - CityPicture.TOP)
	var s := view.y / rows
	var mirante: Vector2 = CityData.POIS.mirante.at
	var x := (view.x - PANEL_W - MIRANTE_GAP) - (mirante.x - CityPicture.LEFT) * s
	x = minf(x, 0.0)
	return Rect2(Vector2(x, -(SHOW_TOP - CityPicture.TOP) * s), Vector2(CityPicture.W, CityPicture.H) * s)


func _relayout() -> void:
	var r := map_rect()
	var mat := map_texture.material as ShaderMaterial
	mat.set_shader_parameter("uv_from", -r.position / r.size)
	mat.set_shader_parameter("uv_span", map_area.size / r.size)
	for id: String in pins:
		var pin: PoiPin = pins[id]
		pin.position = pin_point(id) - pin.anchor_point()
	lines_layer.queue_redraw()


func _build_panel() -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("110e0e", 0.88) # the map runs on behind it
	style.border_color = Color("3a2422")
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
	for c: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		start_button.add_theme_color_override(c, Color("fff1ec"))
	start_button.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.3))
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = {"normal": RED.darkened(0.1), "hover": RED.lightened(0.12), "pressed": RED.darkened(0.3),
			"disabled": Color("2a2020")}[state]
		sb.set_corner_radius_all(3)
		start_button.add_theme_stylebox_override(state, sb)
	start_button.pressed.connect(func():
		if selected != "":
			_save_name()
			mission_pressed.emit(selected))
	WorldSounds.wire_button(start_button)
	v.add_child(start_button)
	var note := Label.new()
	note.text = "Objectives aren't built yet: a mission starts you at its POI on the city map."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD
	note.add_theme_font_size_override("font_size", 12)
	note.modulate.a = 0.4
	v.add_child(note)
	v.add_child(HSeparator.new())

	free_play_button = Button.new()
	free_play_button.text = "Training corridor (free play)"
	free_play_button.pressed.connect(func(): _save_name(); host_pressed.emit())
	WorldSounds.wire_button(free_play_button)
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
	WorldSounds.wire_button(join)
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
	WorldSounds.wire_button(quit, true)
	v.add_child(quit)


func open(message := "") -> void:
	visible = true
	status.text = message
	if message != "":
		Sfx.play_ui("ui_error", -6.0) # back here because something went wrong (refused, lost the host)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Net.start_listening()


func close() -> void:
	visible = false
	Net.stop_listening()


func _save_name() -> void:
	var n := name_edit.text.strip_edges()
	Net.player_name = n if n != "" else "Survivor"
	Settings.set_value("player_name", n)


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
		WorldSounds.wire_button(b)
		lan_list.add_child(b)


## A map pin: a ring on the POI with its name beside it. Toggles on when picked.
class PoiPin extends Button:
	const R := 9.0
	var id := ""
	var tint := Color.WHITE
	var name_left := false

	func _init(id_: String, title: String, tint_: Color, name_left_ := false) -> void:
		id = id_
		tint = tint_
		name_left = name_left_
		toggle_mode = true
		flat = true
		focus_mode = Control.FOCUS_NONE
		text = title
		alignment = HORIZONTAL_ALIGNMENT_RIGHT if name_left else HORIZONTAL_ALIGNMENT_LEFT
		add_theme_font_size_override("font_size", 15)
		add_theme_constant_override("outline_size", 7)
		add_theme_color_override("font_outline_color", Color("0c0b0b"))
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			add_theme_color_override(c, Color.WHITE if c != "font_color" else Color(1, 0.95, 0.92, 0.85))
		var pad := StyleBoxEmpty.new()
		pad.content_margin_left = 6 if name_left else R * 2 + 10
		pad.content_margin_right = R * 2 + 10 if name_left else 6
		for s: String in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			add_theme_stylebox_override(s, pad)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)
		size = get_combined_minimum_size()

	## The ring's centre, relative to the button: put this on the POI.
	func anchor_point() -> Vector2:
		return Vector2(size.x - R - 2 if name_left else R + 2, size.y * 0.5)

	func _draw() -> void:
		var c := anchor_point()
		var lit := button_pressed or is_hovered()
		if button_pressed:
			draw_circle(c, R * 2.3, Color(Menu.RED, 0.28))
		draw_circle(c, R, Color("0c0b0b", 0.9))
		draw_arc(c, R, 0, TAU, 32, tint if lit else Color(tint, 0.8), 3.0 if lit else 2.0, true)
		draw_circle(c, R * 0.35, Menu.RED if not lit else tint)
