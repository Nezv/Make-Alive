class_name MapData
extends RefCounted
## One playable area as data: where players and zombies appear, the zones, the things you can
## right-click, and the objectives. The dictionaries themselves are in map_areas.gd; a GameMap
## reads its own through this class (`map.data`, `map.zones`, `map.spawns`, `map.objective_defs`).
##
## The format (every key is optional; positions are metres in the map's own space):
##   name            "corridor"
##   bounds          [Vector2(x, z), ...]            outline of the playable area
##   blocked_exits   [{ at, kind }]                  where the area is closed off and with what
##   player_spawns   [{ at, yaw }]                   one per player slot, in slot order
##   zombie_closets  [{ id, at, radius, waves }]     where zombies appear; `waves` lists the wave
##                                                   numbers that use it (missing = every wave)
##   horde_routes    [{ closet, points }]            the way a horde walks from a closet to the fight
##   zones           [{ id, kind, box | polygon, y }] kind: extraction, checkpoint, trigger
##                     box: [centre, size]           an upright box
##                     polygon: [Vector2(x, z), ...]  with an optional floor range y: [low, high]
##   doors, lootboxes, ammo_crates, weapon_spots   [{ iid, at, yaw }]   `iid` is the same on every peer
##                     ammo_crates may add `uses` (takes before it is empty) and `unlock` (the id of
##                     the checkpoint zone that opens it; locked until then)
##                     a checkpoint zone may add `look` { at, yaw, kind: tent | door } and
##                     `arrow` { at, yaw }: what it looks like and the arrow painted on the way (CheckpointLook)
##   ammo_boxes      [{ iid, at, yaw, ammo, rounds }] a carton of one calibre ("9 mm"...); `rounds`
##                                                   missing = a full carton of that calibre
##   starting_ammo   { "9 mm": 45, "12 gauge": 16 }  the reserve a player starts with, by calibre name
##                                                   (Weapons.AMMO); a missing calibre uses its own default
##   respawn         true                            the dead come back (false: a dead player is out)
##   objectives      [{ id, kind, zone, seconds, waves, text, who, target, time_limit }]  in order;
##                                                   kind: reach, hold, survive, interact, extract
##                     reach: `who` "any" (default) or "all" players still in the fight
##                     hold / extract: `seconds` in the zone · survive: `waves` or `seconds`
##                       a wave is a size, or { size, types: { walker: 0.6, runner: 0.3, leaper: 0.1 },
##                       closets: [ids], gap: seconds of calm before it }; missing closets = one more
##                       way in each wave. `heli`: seconds the helicopter needs once the last wave
##                       begins; until it is down the last wave never ends (0 = it ends when cleared)
##                     interact: `target` is the iid of the thing to right-click
##                     `time_limit`: seconds before this objective fails the mission (0 = none)
##
## `errors` lists what is wrong with the dictionary itself (duplicate ids, references to things
## that aren't there). `check(map)` lists what is wrong once it is laid over the real map: a spawn
## in a wall, a zombie closet a player can see from their spawn.

const ZONE_KINDS := ["extraction", "checkpoint", "trigger"]
const OBJECTIVE_KINDS := ["reach", "hold", "survive", "interact", "extract"]
const INTERACTABLE_LISTS := ["doors", "lootboxes", "ammo_crates", "ammo_boxes", "weapon_spots"]
const COLORS := { "extraction": Color(0.3, 1.0, 0.4), "checkpoint": Color(0.3, 0.7, 1.0), "trigger": Color(1.0, 0.9, 0.3),
	"closet": Color(1.0, 0.25, 0.2), "route": Color(1.0, 0.55, 0.1), "spawn": Color.WHITE, "bounds": Color(0.6, 0.6, 0.7) }

var raw := {}
var name := ""
var bounds := PackedVector2Array()
var blocked_exits: Array = []
var spawns: Array = []      ## [{ at, yaw }]
var closets: Array = []     ## [{ id, at, radius, waves }]
var routes: Array = []      ## [{ closet, points }]
var zones := {}             ## id -> { id, kind, box | polygon, y }
var objectives: Array = []  ## [{ id, kind, zone, seconds, waves, text, who, target, time_limit }]
var respawn := true         ## the dead come back
var starting_ammo := {}     ## Weapons.Ammo -> rounds in reserve at the start
var errors: Array = []


func _init(dict: Dictionary = {}) -> void:
	raw = dict
	name = dict.get("name", "")
	bounds = PackedVector2Array(dict.get("bounds", []))
	blocked_exits = dict.get("blocked_exits", [])
	respawn = dict.get("respawn", true)
	_read_spawns(dict)
	_read_closets(dict)
	_read_zones(dict)
	_read_objectives(dict)
	_read_interactables(dict)
	_read_ammo(dict)


# --- Reading and structural checks ------------------------------------------------

func _error(text: String) -> void:
	errors.append("%s: %s" % [name if name != "" else "map data", text])


func _need(entry: Dictionary, key: String, where: String) -> bool:
	if entry.has(key):
		return true
	_error("%s has no '%s'" % [where, key])
	return false


func _read_spawns(dict: Dictionary) -> void:
	if not dict.has("player_spawns"):
		return
	var list: Array = dict.player_spawns
	if list.is_empty():
		_error("player_spawns is empty: no spawn for anyone")
	for i in list.size():
		var e: Dictionary = list[i]
		if _need(e, "at", "player_spawns[%d]" % i):
			spawns.append({ "at": e.at, "yaw": e.get("yaw", 0.0) })


func _read_closets(dict: Dictionary) -> void:
	var seen := {}
	for e: Dictionary in dict.get("zombie_closets", []):
		var id: String = e.get("id", "")
		if seen.has(id):
			_error("two zombie closets are called '%s'" % id)
		seen[id] = true
		if _need(e, "at", "closet '%s'" % id):
			closets.append({ "id": id, "at": e.at, "radius": e.get("radius", 2.0), "waves": e.get("waves", []) })
	for e: Dictionary in dict.get("horde_routes", []):
		var closet: String = e.get("closet", "")
		if not seen.has(closet):
			_error("a horde route starts at closet '%s', which isn't there" % closet)
		routes.append({ "closet": closet, "points": e.get("points", []) })


func _read_zones(dict: Dictionary) -> void:
	for e: Dictionary in dict.get("zones", []):
		var id: String = e.get("id", "")
		if zones.has(id):
			_error("two zones are called '%s'" % id)
		var kind: String = e.get("kind", "")
		if not ZONE_KINDS.has(kind):
			_error("zone '%s' has unknown kind '%s'" % [id, kind])
		if not e.has("box") and not e.has("polygon"):
			_error("zone '%s' has no shape (a box or a polygon)" % id)
			continue
		zones[id] = e


func _read_objectives(dict: Dictionary) -> void:
	var seen := {}
	var iids := {} # every interactable the data lists
	for list_name: String in INTERACTABLE_LISTS:
		for e: Dictionary in dict.get(list_name, []):
			iids[e.get("iid", -1)] = true
	for e: Dictionary in dict.get("objectives", []):
		var id: String = e.get("id", "")
		if seen.has(id):
			_error("two objectives are called '%s'" % id)
		seen[id] = true
		var kind: String = e.get("kind", "")
		if not OBJECTIVE_KINDS.has(kind):
			_error("objective '%s' has unknown kind '%s'" % [id, kind])
		var zone: String = e.get("zone", "")
		if zone != "" and not zones.has(zone):
			_error("objective '%s' is in zone '%s', which isn't there" % [id, zone])
		elif zone == "" and ["reach", "hold", "extract"].has(kind):
			_error("objective '%s' (%s) needs a zone" % [id, kind])
		var who: String = e.get("who", "any")
		if who != "any" and who != "all":
			_error("objective '%s' is for '%s' (any or all)" % [id, who])
		var target: int = e.get("target", -1)
		if kind == "interact" and not iids.has(target):
			_error("objective '%s' has no thing to interact with (target %d)" % [id, target])
		var waves: Array = []
		for w: Variant in e.get("waves", []):
			waves.append(_read_wave(id, w))
		objectives.append({ "id": id, "kind": kind, "zone": zone, "seconds": float(e.get("seconds", 0.0)),
			"waves": waves, "heli": float(e.get("heli", 0.0)), "text": e.get("text", ""), "who": who, "target": target,
			"time_limit": float(e.get("time_limit", 0.0)) })


const WAVE_TYPES := { "walker": 0, "runner": 1, "leaper": 2 } ## Zombie.Type by name


## A wave as { size, types, closets, gap } whether it was written as a size or in full.
static func wave(w: Variant) -> Dictionary:
	var e: Dictionary = { "size": w } if w is int else w
	return { "size": int(e.get("size", 0)), "types": e.get("types", {}), "closets": e.get("closets", []),
		"gap": float(e.get("gap", Config.WAVE_GAP)) }


## One wave of a survive objective, read and checked.
func _read_wave(objective: String, w: Variant) -> Dictionary:
	var out := wave(w)
	for c: String in out.closets:
		if not closets.any(func(k: Dictionary) -> bool: return k.id == c):
			_error("objective '%s' sends a wave from closet '%s', which isn't there" % [objective, c])
	for t: String in out.types:
		if not WAVE_TYPES.has(t):
			_error("objective '%s' has a wave of unknown type '%s'" % [objective, t])
	return out


func _read_interactables(dict: Dictionary) -> void:
	var seen := {}
	for list_name: String in INTERACTABLE_LISTS:
		var list: Array = dict.get(list_name, [])
		for i in list.size():
			var e: Dictionary = list[i]
			var where := "%s[%d]" % [list_name, i]
			_need(e, "at", where)
			if _need(e, "iid", where):
				if seen.has(e.iid):
					_error("%s reuses iid %d (already %s)" % [where, e.iid, seen[e.iid]])
				seen[e.iid] = where
			var unlock: String = e.get("unlock", "")
			if unlock != "" and (not zones.has(unlock) or zones[unlock].kind != "checkpoint"):
				_error("%s is unlocked by '%s', which is no checkpoint zone" % [where, unlock])
			if list_name == "ammo_boxes" and _need(e, "ammo", where) and Weapons.ammo_id(e.ammo) < 0:
				_error("%s has no calibre '%s'" % [where, e.ammo])


func _read_ammo(dict: Dictionary) -> void:
	var by_name: Dictionary = dict.get("starting_ammo", {})
	for ammo_name: String in by_name:
		var type := Weapons.ammo_id(ammo_name)
		var rounds: int = by_name[ammo_name]
		if type < 0:
			_error("starting_ammo has no calibre '%s'" % ammo_name)
		elif rounds < 0:
			_error("starting_ammo '%s' is negative" % ammo_name)
		else:
			starting_ammo[type] = rounds


# --- Questions --------------------------------------------------------------------

## Is `pos` inside zone `id`? Unknown zones contain nothing.
func zone_contains(id: String, pos: Vector3) -> bool:
	if not zones.has(id):
		return false
	var z: Dictionary = zones[id]
	if z.has("box"):
		var center: Vector3 = z.box[0]
		var half: Vector3 = z.box[1] * 0.5
		var d := (pos - center).abs()
		return d.x <= half.x and d.y <= half.y and d.z <= half.z
	if z.has("y"):
		var low: float = z.y[0]
		var high: float = z.y[1]
		if pos.y < low or pos.y > high:
			return false
	return Geometry2D.is_point_in_polygon(Vector2(pos.x, pos.z), PackedVector2Array(z.polygon))


## Ids of every zone `pos` is inside.
func zones_at(pos: Vector3) -> Array:
	var out := []
	for id: String in zones:
		if zone_contains(id, pos):
			out.append(id)
	return out


## Ids of the zones of one kind ("extraction", "checkpoint", "trigger").
func zone_ids(kind: String) -> Array:
	var out := []
	for id: String in zones:
		if zones[id].kind == kind:
			out.append(id)
	return out


## The middle of a zone: where its HUD marker goes.
func zone_center(id: String) -> Vector3:
	var z: Dictionary = zones[id]
	if z.has("box"):
		return z.box[0]
	var sum := Vector2.ZERO
	for p: Vector2 in z.polygon:
		sum += p
	sum /= (z.polygon as Array).size()
	var y: float = (z.y[0] + z.y[1]) * 0.5 if z.has("y") else 0.0
	return Vector3(sum.x, y, sum.y)


## Ids of the closets that wave number `wave` may use.
func closet_ids(wave: int) -> Array:
	var out := []
	for c: Dictionary in closets:
		var waves: Array = c.waves
		if waves.is_empty() or waves.has(wave):
			out.append(c.id)
	return out


## The points a horde from `closet` walks through ([] = straight at the players).
func route_from(closet: String) -> Array:
	for r: Dictionary in routes:
		if r.closet == closet:
			return r.points
	return []


func in_bounds(pos: Vector3) -> bool:
	return bounds.is_empty() or Geometry2D.is_point_in_polygon(Vector2(pos.x, pos.z), bounds)


# --- Checked against the map ------------------------------------------------------

## Everything that is wrong once the data is laid over `map`. Empty when all is well.
func check(map: GameMap) -> Array:
	var problems := []
	var stand := func(pos: Vector3, what: String) -> void:
		if not in_bounds(pos):
			problems.append("%s at %s is outside the bounds" % [what, pos])
		elif not map.is_walkable(pos):
			problems.append("%s at %s is not on walkable ground" % [what, pos])
	for i in spawns.size():
		stand.call(spawns[i].at, "player_spawns[%d]" % i)
	for c: Dictionary in closets:
		stand.call(c.at, "closet '%s'" % c.id)
		for i in spawns.size():
			if map.sees(spawns[i].at, c.at):
				problems.append("closet '%s' is in sight of player_spawns[%d]" % [c.id, i])
				break
	for r: Dictionary in routes:
		var points: Array = r.points
		for i in points.size():
			stand.call(points[i], "route from '%s', point %d" % [r.closet, i])
	for id: String in zones:
		var c := zone_center(id)
		var z: Dictionary = zones[id]
		if z.has("box") and (z.box[0] as Vector3).y - (z.box[1] as Vector3).y * 0.5 > map.ground_y(c) + 1.0:
			continue # up on something (a tower's deck): not stood on from the ground
		stand.call(Vector3(c.x, map.ground_y(c), c.z), "zone '%s'" % id)
	for list_name: String in INTERACTABLE_LISTS:
		var list: Array = raw.get(list_name, [])
		for i in list.size():
			if not in_bounds(list[i].at):
				problems.append("%s[%d] at %s is outside the bounds" % [list_name, i, list[i].at])
	return problems


# --- Building ---------------------------------------------------------------------

## Make the doors, lootboxes, ammo crates, ammo boxes and weapon spots the data lists, under `root`.
## Returns { doors, lootboxes, ammo_crates, ammo_boxes, weapon_spots, all }.
func build_interactables(root: Node3D) -> Dictionary:
	var out := { "doors": [], "lootboxes": [], "ammo_crates": [], "ammo_boxes": [], "weapon_spots": [], "all": [] }
	for list_name: String in INTERACTABLE_LISTS:
		for e: Dictionary in raw.get(list_name, []):
			var it := _make(list_name, e)
			it.iid = e.iid
			it.position = e.at
			it.rotation.y = e.get("yaw", 0.0)
			root.add_child(it)
			(out[list_name] as Array).append(it)
			(out.all as Array).append(it)
	return out


## The look of every checkpoint zone that has one (a lit tent or a safe-room door, an arrow), under `root`.
func build_checkpoints(root: Node3D) -> void:
	for id: String in zone_ids("checkpoint"):
		var z: Dictionary = zones[id]
		if z.has("look") or z.has("arrow"):
			root.add_child(CheckpointLook.build(id, z))


func _make(list_name: String, e: Dictionary) -> Interactable:
	match list_name:
		"doors":
			return Door.new()
		"lootboxes":
			return Lootbox.new()
		"ammo_crates":
			var crate := AmmoCrate.new()
			crate.uses = e.get("uses", Config.AMMO_CRATE_USES)
			crate.unlock = e.get("unlock", "")
			crate.locked = crate.unlock != ""
			return crate
		"ammo_boxes":
			var box := AmmoBox.new()
			var type := maxi(0, Weapons.ammo_id(e.get("ammo", "")))
			box.setup(type, e.get("rounds", Weapons.AMMO[type].box))
			return box
	return WeaponPickup.new()


## Wireframes of everything in the data, for `--zones`: zones by kind, closets red, routes orange,
## spawns white, bounds grey.
func debug_node() -> Node3D:
	var node := Node3D.new()
	node.name = "MapDataDebug"
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	var line := func(a: Vector3, b: Vector3, color: Color) -> void:
		im.surface_set_color(color)
		im.surface_add_vertex(a)
		im.surface_set_color(color)
		im.surface_add_vertex(b)
	var ring := func(points: Array, y0: float, y1: float, color: Color) -> void:
		for i in points.size():
			var a: Vector2 = points[i]
			var b: Vector2 = points[(i + 1) % points.size()]
			line.call(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), color)
			if y1 > y0:
				line.call(Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), color)
				line.call(Vector3(a.x, y0, a.y), Vector3(a.x, y1, a.y), color)
	var circle := func(at: Vector3, radius: float) -> Array:
		var points := []
		for i in 20:
			points.append(Vector2(at.x + cos(TAU * i / 20.0) * radius, at.z + sin(TAU * i / 20.0) * radius))
		return points
	im.surface_set_color(Color.BLACK)
	im.surface_add_vertex(Vector3.ZERO) # a surface must not be empty, whatever the data holds
	im.surface_add_vertex(Vector3.ZERO)
	if not bounds.is_empty():
		ring.call(Array(bounds), 0.05, 0.05, COLORS.bounds)
	for id: String in zones:
		var z: Dictionary = zones[id]
		var color: Color = COLORS.get(z.kind, Color.MAGENTA)
		if z.has("box"):
			var c: Vector3 = z.box[0]
			var h: Vector3 = z.box[1] * 0.5
			ring.call([Vector2(c.x - h.x, c.z - h.z), Vector2(c.x + h.x, c.z - h.z), Vector2(c.x + h.x, c.z + h.z),
				Vector2(c.x - h.x, c.z + h.z)], c.y - h.y + 0.05, c.y + h.y, color)
		else:
			var low: float = z.y[0] if z.has("y") else 0.05
			var high: float = z.y[1] if z.has("y") else 3.0
			ring.call(z.polygon, low, high, color)
		var tag := Label3D.new()
		tag.text = "%s (%s)" % [id, z.kind]
		tag.modulate = color
		tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		tag.no_depth_test = true
		tag.pixel_size = 0.006
		tag.position = zone_center(id) + Vector3(0, 1.2, 0)
		node.add_child(tag)
	for c: Dictionary in closets:
		var at: Vector3 = c.at
		ring.call(circle.call(at, c.radius), at.y, at.y + 2.0, COLORS.closet)
	for r: Dictionary in routes:
		var points: Array = r.points
		for i in points.size() - 1:
			line.call(points[i] + Vector3(0, 0.3, 0), points[i + 1] + Vector3(0, 0.3, 0), COLORS.route)
	for s: Dictionary in spawns:
		var at: Vector3 = s.at
		ring.call(circle.call(at, 0.4), at.y, at.y, COLORS.spawn)
		var facing := Basis(Vector3.UP, s.yaw) * Vector3(0, 0, -0.9)
		line.call(at, at + facing, COLORS.spawn)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.no_depth_test = true # seen through walls: this is a debugging view
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)
	return node
