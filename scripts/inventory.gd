class_name Inventory
extends RefCounted
## What a player carries besides guns: counted stacks with caps (medkit, bandage, painkillers, planks),
## throwables in a couple of slots, and keys by id. No nodes. The host keeps one per player
## (`players[id].inventory`) and sends the player their own whenever it changes; the player's copy is
## only for the wheel and the HUD, never trusted.
##
## A backpack (`Backpack`) holds one with `capped` off: whatever a dead player had, uncapped.

enum Kind { MEDICAL, THROWABLE, MATERIAL }

const MEDKIT := &"medkit"
const BANDAGE := &"bandage"
const PAINKILLERS := &"painkillers"
const PLANK := &"plank"
const FRAG := &"frag"
const MOLOTOV := &"molotov"
const FLASHBANG := &"flashbang"
const LURE := &"lure"

## Per item: name, kind, cap (most of it carried). The order here is the order things are listed in
## (throwables fill the wheel's two throwable wedges in it). Throwables are only handed out from S093 on.
const ITEMS := {
	MEDKIT: { "name": "Medkit", "kind": Kind.MEDICAL, "cap": 2 },
	BANDAGE: { "name": "Bandage", "kind": Kind.MEDICAL, "cap": 5 },
	PAINKILLERS: { "name": "Painkillers", "kind": Kind.MEDICAL, "cap": 3 },
	PLANK: { "name": "Plank", "kind": Kind.MATERIAL, "cap": 8 },
	FRAG: { "name": "Frag grenade", "kind": Kind.THROWABLE, "cap": 3 },
	MOLOTOV: { "name": "Molotov", "kind": Kind.THROWABLE, "cap": 3 },
	FLASHBANG: { "name": "Flashbang", "kind": Kind.THROWABLE, "cap": 3 },
	LURE: { "name": "Noise lure", "kind": Kind.THROWABLE, "cap": 3 },
}
## What the quick-heal key reaches for, in turn.
const QUICK_HEAL := [MEDKIT, BANDAGE]

var capped := true ## off for what lies in a backpack
var _counts := {}  ## item -> how many
var _keys: Array[StringName] = []
var _throwable := &"" ## the one the quick-throw key throws (the player's own choice; the host never reads it)


static func valid(item: StringName) -> bool:
	return ITEMS.has(item)


static func item_name(item: StringName) -> String:
	return ITEMS[item].name if valid(item) else str(item)


static func kind_of(item: StringName) -> int:
	return ITEMS[item].kind if valid(item) else -1


static func cap_of(item: StringName) -> int:
	return ITEMS[item].cap if valid(item) else 0


func count(item: StringName) -> int:
	return _counts.get(item, 0)


## How many more of `item` fit: its cap, and for throwables whether a slot is free for the kind.
func room(item: StringName) -> int:
	if not valid(item):
		return 0
	if not capped:
		return 1 << 20
	if kind_of(item) == Kind.THROWABLE and count(item) == 0 and throwables().size() >= Config.THROWABLE_SLOTS:
		return 0
	return maxi(0, cap_of(item) - count(item))


## Carry `n` of `item`. Returns how many fitted.
func add(item: StringName, n := 1) -> int:
	var fits := clampi(n, 0, room(item))
	if fits > 0:
		_counts[item] = count(item) + fits
	return fits


## Spend `n` of `item`: all of them or nothing.
func remove(item: StringName, n := 1) -> bool:
	if n <= 0 or count(item) < n:
		return false
	_counts[item] = count(item) - n
	if _counts[item] == 0:
		_counts.erase(item)
	return true


## Nothing at all: no stack, no key.
func is_empty() -> bool:
	return _counts.is_empty() and _keys.is_empty()


func clear() -> void:
	_counts.clear()
	_keys.clear()
	_throwable = &""


# --- Throwables ----------------------------------------------------------------------

## The kinds of throwable carried, in `ITEMS` order.
func throwables() -> Array[StringName]:
	var kinds: Array[StringName] = []
	for item: StringName in ITEMS:
		if kind_of(item) == Kind.THROWABLE and count(item) > 0:
			kinds.append(item)
	return kinds


## The throwable the quick key throws: the one chosen if it is still carried, else the first carried.
func selected_throwable() -> StringName:
	if count(_throwable) > 0:
		return _throwable
	var kinds := throwables()
	return kinds[0] if not kinds.is_empty() else &""


func select_throwable(item: StringName) -> bool:
	if kind_of(item) != Kind.THROWABLE or count(item) == 0:
		return false
	_throwable = item
	return true


func cycle_throwable(step: int) -> void:
	var kinds := throwables()
	if kinds.size() > 1:
		_throwable = kinds[posmod(kinds.find(selected_throwable()) + step, kinds.size())]


# --- Keys ----------------------------------------------------------------------------

func has_key(id: StringName) -> bool:
	return _keys.has(id)


## Carry the key (or keycard) `id`. False if you had it already.
func add_key(id: StringName) -> bool:
	if id == &"" or _keys.has(id):
		return false
	_keys.append(id)
	return true


func remove_key(id: StringName) -> bool:
	if not _keys.has(id):
		return false
	_keys.erase(id)
	return true


func keys() -> Array[StringName]:
	return _keys.duplicate()


# --- Using ---------------------------------------------------------------------------

## The heal the quick key would use, or &"".
func quick_heal() -> StringName:
	for item: StringName in QUICK_HEAL:
		if count(item) > 0:
			return item
	return &""


## The wheel's wedges, clockwise from the top: medkit, bandage, painkillers, the two throwables
## carried, planks, and two still free. Each is { item, count } (item &"" where nothing goes).
func wheel() -> Array:
	var wedges: Array = []
	for item: StringName in [MEDKIT, BANDAGE, PAINKILLERS]:
		wedges.append({ "item": item, "count": count(item) })
	var kinds := throwables()
	for i in Config.THROWABLE_SLOTS:
		var kind: StringName = kinds[i] if i < kinds.size() else &""
		wedges.append({ "item": kind, "count": count(kind) })
	wedges.append({ "item": PLANK, "count": count(PLANK) })
	while wedges.size() < Config.WHEEL_WEDGES:
		wedges.append({ "item": &"", "count": 0 })
	return wedges


## Which wedge a pointer `offset` from the middle of the wheel points at (0 = straight up, going
## clockwise), or -1 inside the dead zone.
static func wedge_at(offset: Vector2) -> int:
	if offset.length() < Config.WHEEL_DEAD_ZONE:
		return -1
	var angle := atan2(offset.x, -offset.y) # 0 up, clockwise (screen y points down)
	return posmod(roundi(angle / (TAU / Config.WHEEL_WEDGES)), Config.WHEEL_WEDGES)


# --- Moving and sending --------------------------------------------------------------

## Move what fits into `other` (a backpack looted). Returns how many things moved (stacks count by
## the unit, a key by one); what does not fit stays here.
func transfer_to(other: Inventory) -> int:
	var moved := 0
	for item: StringName in _counts.keys():
		var got := other.add(item, count(item))
		if got > 0:
			remove(item, got)
			moved += got
	for id in keys():
		if other.add_key(id):
			remove_key(id)
			moved += 1
	return moved


## `{ "n": { item: count }, "keys": [id] }` with plain strings, so it crosses the wire as it is.
func get_state() -> Dictionary:
	var n := {}
	for item: StringName in _counts:
		n[String(item)] = _counts[item]
	var ids := []
	for id in _keys:
		ids.append(String(id))
	return { "n": n, "keys": ids }


## Take the host's word for what is carried. The choice of throwable stays what it was while it is
## still carried.
func apply_state(state: Dictionary) -> void:
	_counts.clear()
	var n: Dictionary = state.get("n", {})
	for item: String in n:
		if valid(StringName(item)) and int(n[item]) > 0:
			_counts[StringName(item)] = int(n[item])
	_keys.clear()
	for id: String in state.get("keys", []):
		_keys.append(StringName(id))


static func from_state(state: Dictionary, capped_ := true) -> Inventory:
	var inv := Inventory.new()
	inv.capped = capped_
	inv.apply_state(state)
	return inv
