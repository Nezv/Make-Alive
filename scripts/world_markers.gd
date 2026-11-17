class_name WorldMarkers
extends Control
## Markers over the world: the objective as a diamond with its distance, held at the screen's edge with
## an arrow when it is off screen or behind you; far teammates as an outline that shows through walls.

var objective := Vector3.INF  ## where the objective marker is (INF: none)
var _marks: Array = []        ## [{ pos, clamped, angle, text, kind }] worked out each frame


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Where a marker goes on a screen `size` for a point projected at `p` (`behind`: it is behind the
## camera): on the spot, or at the edge (`Config.HUD_EDGE` in) pointing toward it.
static func place(size: Vector2, p: Vector2, behind: bool) -> Dictionary:
	var m := Config.HUD_EDGE
	if not behind and p.x >= m and p.x <= size.x - m and p.y >= m and p.y <= size.y - m:
		return { "pos": p, "clamped": false, "angle": 0.0 }
	var c := size / 2.0
	var d := p - c
	if behind:
		d = -d
		if d.length() < 1.0:
			d = Vector2(0, 1)
	var half := c - Vector2(m, m)
	var t := INF
	if absf(d.x) > 0.0001:
		t = minf(t, half.x / absf(d.x))
	if absf(d.y) > 0.0001:
		t = minf(t, half.y / absf(d.y))
	return { "pos": c + d * t, "clamped": true, "angle": d.angle() }


static func distance_text(metres: float) -> String:
	return "%d m" % roundi(metres)


## True when teammate `id` is far enough to be drawn as an outline through the walls.
func outlined(g: Game, id: int) -> bool:
	if not g.remotes.has(id) or g.local_player == null:
		return false
	var r := g.remotes[id] as RemotePlayer
	return r.visible and r.global_position.distance_to(g.local_player.global_position) > Config.HUD_OUTLINE_DIST


## Work out this frame's markers from the camera.
func update_from(g: Game) -> void:
	_marks.clear()
	var cam := g.local_player.camera if g.local_player else null
	if cam == null or not cam.is_inside_tree():
		queue_redraw()
		return
	var vp := get_viewport_rect().size
	if objective.is_finite():
		var at := objective + Vector3(0, 1.5, 0)
		var pl := place(vp, cam.unproject_position(at), cam.is_position_behind(at))
		pl.text = distance_text(cam.global_position.distance_to(objective))
		pl.kind = "objective"
		_marks.append(pl)
	for id: int in g.remotes:
		if outlined(g, id):
			var at := (g.remotes[id] as Node3D).global_position + Vector3(0, 1.0, 0)
			if cam.is_position_behind(at):
				continue
			var pl := { "pos": cam.unproject_position(at), "clamped": false, "angle": 0.0, "text": g.names.get(id, ""), "kind": "mate" }
			_marks.append(pl)
	queue_redraw()


func _draw() -> void:
	for mk: Dictionary in _marks:
		var p: Vector2 = mk.pos
		if mk.kind == "objective":
			HudParts.diamond(self, p, 9.0, HudParts.OBJECTIVE)
			HudParts.text(self, p + Vector2(-40, 26), mk.text, 14, HudParts.OBJECTIVE, HORIZONTAL_ALIGNMENT_CENTER, 80)
			if mk.clamped: # an arrow toward it
				var dir := Vector2.from_angle(mk.angle)
				var tip := p + dir * 20.0
				var side := dir.orthogonal() * 6.0
				draw_colored_polygon(PackedVector2Array([tip, p + dir * 12.0 + side, p + dir * 12.0 - side]), HudParts.OBJECTIVE)
		else: # a teammate far off: an outline and their name
			draw_rect(Rect2(p - Vector2(10, 22), Vector2(20, 44)), HudParts.MATE, false, 2.0)
			HudParts.text(self, p + Vector2(-60, -28), mk.text, 13, HudParts.MATE, HORIZONTAL_ALIGNMENT_CENTER, 120)
