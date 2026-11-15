class_name Menu
extends CanvasLayer
## Main menu: name, Host, Join by IP, and a live list of LAN games (click to join).

signal host_pressed
signal join_pressed(ip: String)

var name_edit: LineEdit
var ip_edit: LineEdit
var status: Label
var lan_list: VBoxContainer
var _lan_refresh := 0.0


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color("0d1013")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := VBoxContainer.new()
	v.custom_minimum_size = Vector2(420, 0)
	v.add_theme_constant_override("separation", 12)
	center.add_child(v)

	var title := Label.new()
	title.text = "ZOMBIE EXTRACTION"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color("99ff66"))
	v.add_child(title)

	name_edit = LineEdit.new()
	name_edit.placeholder_text = "Your name"
	name_edit.max_length = 20
	name_edit.text = Net.player_name
	v.add_child(name_edit)

	var host := Button.new()
	host.text = "Host game"
	host.pressed.connect(func(): _save_name(); host_pressed.emit())
	v.add_child(host)

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
	lan_title.modulate.a = 0.7
	v.add_child(lan_title)
	lan_list = VBoxContainer.new()
	v.add_child(lan_list)

	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD
	status.modulate = Color("ffcc66")
	v.add_child(status)


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
		none.text = "  (none found yet. Hosts appear here automatically.)"
		none.modulate.a = 0.5
		lan_list.add_child(none)
	for ip in Net.lan_games:
		var g: Dictionary = Net.lan_games[ip]
		var b := Button.new()
		b.text = "%s's game · %d players · %s" % [g.name, g.players, ip]
		b.pressed.connect(func(): _join(ip))
		lan_list.add_child(b)
