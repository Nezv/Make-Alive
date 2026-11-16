class_name AmmoBox
extends Interactable
## A small carton of one calibre lying on the ground: a stripe in the calibre's colour and a row of
## pips for how much is left in it. Right-click takes what fits in your reserve
## (GameHooks.on_right_click_ammo_box); an emptied carton hops to whoever took it and is gone.
##
## Two kinds: the ones a map's data lists (`ammo_boxes`, fixed iid) and the ones zombies drop
## (`dynamic`, made by Game.drop_ammo_box with an iid from Config.DROP_IID_BASE up; their state
## carries where they lie, so a peer that has never seen one can build it).

const SIZE := Vector3(0.22, 0.11, 0.14)
const CARD := Color("b89a6a")
const INK := Color("2a241c")

var ammo := 0             ## Weapons.Ammo
var rounds := 0
var taken_by := -1        ## -1: lying here · 0: removed, nobody got it · otherwise the player who took it
var dynamic := false      ## dropped by a zombie: leaves the tree after its hop
var _mesh: MeshInstance3D
var _body: StaticBody3D
var _hop := -1.0          ## 0..1 through the hop to the player; -1 while lying
var _from := Vector3.ZERO
var _to := Vector3.ZERO


func _init() -> void:
	_body = _click_body(Vector3(0.4, 0.3, 0.34), Vector3(0, 0.15, 0), false) # easier to point at than the carton
	add_child(_body)
	set_process(false)


## How many pips a carton holding `count` of a calibre shows: a full box fills the row.
static func pips(type: int, count: int) -> int:
	var full: int = Weapons.AMMO[type].box
	return clampi(ceili(float(Config.AMMO_BOX_PIPS) * count / full), 1, Config.AMMO_BOX_PIPS)


## What zombie `zid` leaves when it dies: {} for most, or { ammo, rounds }. Seeded by the id, so
## it is the same on every run. Cops and soldiers carry more often, and their own calibres.
static func roll_drop(zid: int, outfit: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(zid * 7919 + 104729)
	var armed: Array = Config.AMMO_DROP_ARMED.get(outfit, [])
	if rng.randf() >= (Config.AMMO_DROP_CHANCE if armed.is_empty() else Config.AMMO_DROP_CHANCE_ARMED):
		return {}
	var type: int = rng.randi_range(0, Weapons.Ammo.COUNT - 1) if armed.is_empty() else armed[rng.randi_range(0, armed.size() - 1)]
	var full: int = Weapons.AMMO[type].box
	return { "ammo": type, "rounds": full }


## Fill it (the map's data, or a drop).
func setup(type: int, count: int) -> void:
	ammo = type
	rounds = count
	_refresh()


func prompt() -> String:
	return "" if taken_by >= 0 else "Right-click: take %s (%d)" % [Weapons.ammo_name(ammo), rounds]


## Host: `count` rounds leave the carton for player `by` (0: nobody, it is just removed).
func take(count: int, by: int) -> void:
	rounds = maxi(0, rounds - count)
	if rounds == 0 or by == 0:
		taken_by = by
	_refresh()
	_notify_changed()


func get_state() -> Dictionary:
	var state := { "ammo": ammo, "rounds": rounds, "by": taken_by }
	if dynamic:
		state["drop"] = true
		state["at"] = position
	return state


func apply_state(state: Dictionary) -> void:
	ammo = state.get("ammo", ammo)
	rounds = state.get("rounds", rounds)
	taken_by = state.get("by", -1)
	_refresh()


## Fly to `point` (the player who took it) while shrinking, then disappear.
func hop_to(point: Vector3) -> void:
	if _hop >= 0.0:
		return
	_hop = 0.0
	_from = global_position
	_to = point
	set_process(true)


func _process(delta: float) -> void:
	if _hop < 0.0:
		return
	_hop = minf(1.0, _hop + delta / Config.PICKUP_HOP_TIME)
	var arc := Vector3(0, sin(_hop * PI) * Config.PICKUP_HOP_ARC, 0)
	global_position = _from.lerp(_to, _hop * _hop * (3.0 - 2.0 * _hop)) + arc
	scale = Vector3.ONE * maxf(1.0 - _hop, 0.001)
	if _hop >= 1.0:
		visible = false
		set_process(false)
		if dynamic:
			queue_free()


func _refresh() -> void:
	_body.collision_layer = Config.LAYER_INTERACT if taken_by < 0 else 0
	if _mesh != null:
		_mesh.free()
	var stripe: Color = Weapons.AMMO[ammo].color
	var b := MeshKit.Builder.new()
	var h := SIZE.y
	b.box(SIZE, Vector3(0, h / 2.0, 0), CARD)
	b.box(Vector3(SIZE.x * 0.3, h + 0.004, SIZE.z + 0.004), Vector3(-SIZE.x * 0.22, h / 2.0, 0), stripe) # the band round it
	b.box(Vector3(SIZE.x + 0.004, h * 0.22, SIZE.z + 0.004), Vector3(0, h * 0.16, 0), INK)                 # printed base line
	var n := pips(ammo, rounds)
	var step := SIZE.z * 0.8 / Config.AMMO_BOX_PIPS
	for i in n: # the count, as a row of squares printed on the lid
		b.box(Vector3(0.022, 0.004, step * 0.6), Vector3(SIZE.x * 0.24, h + 0.002, (i - (Config.AMMO_BOX_PIPS - 1) / 2.0) * step), INK)
	_mesh = b.instance(null, false)
	add_child(_mesh)
