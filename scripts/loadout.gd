class_name Loadout
extends RefCounted
## What one player carries: two primaries, one sidearm, one melee weapon. No nodes. The host keeps
## one per player (`players[id].loadout`) and so does each player for themself; both run the same
## `take`, so they agree on which gun is dropped when the slots are full.
##
## On a test map (`everything`) the player simply has all nine guns and the number keys pick by gun.

enum Slot { PRIMARY_1, PRIMARY_2, SIDEARM, MELEE, COUNT }

## Which slots a kind of weapon (Weapons.Kind) may go in.
const SLOTS_OF := [[Slot.PRIMARY_1, Slot.PRIMARY_2], [Slot.SIDEARM], [Slot.MELEE]]

var everything := false
var slots: Array = [-1, -1, -1, -1] ## Weapons id per Slot, -1 = empty


## A test map: every gun.
static func all() -> Loadout:
	var lo := Loadout.new()
	lo.everything = true
	return lo


## A mission: just the pistol.
static func pistol() -> Loadout:
	var lo := Loadout.new()
	lo.slots[Slot.SIDEARM] = Weapons.P19
	return lo


func has(id: int) -> bool:
	return Weapons.valid(id) and (everything or slots.has(id))


## The guns carried, in the order the keys and the wheel go through them.
func guns() -> Array:
	if everything:
		return range(Weapons.COUNT)
	return slots.filter(func(id: int) -> bool: return id >= 0)


## The gun number key `n` (0 = the "1" key) brings up, or -1.
func key(n: int) -> int:
	if everything:
		return n if Weapons.valid(n) else -1
	return slots[n] if n >= 0 and n < Slot.COUNT else -1


## The gun after (`step` 1) or before (-1) `current` among the ones carried.
func next(current: int, step: int) -> int:
	var carried := guns()
	if carried.is_empty():
		return current
	return carried[posmod(carried.find(current) + step, carried.size())]


## The gun that would have to go to make room for `id`, with `held` in hand: -1 if a slot is free
## (or it is carried already), otherwise the held gun if it is of that kind, else the first of that kind.
func would_drop(id: int, held: int) -> int:
	if everything or not Weapons.valid(id) or has(id):
		return -1
	var mine: Array = SLOTS_OF[Weapons.kind_of(id)]
	for s: int in mine:
		if slots[s] < 0:
			return -1
	for s: int in mine:
		if slots[s] == held:
			return held
	return slots[mine[0]]


## Carry `id`. Returns the gun dropped for it (see `would_drop`), or -1.
func take(id: int, held: int) -> int:
	if everything or not Weapons.valid(id) or has(id):
		return -1
	var out := would_drop(id, held)
	return swap(id, out)


## Put `id` where `out` was (or in the first free slot of its kind when `out` is -1). Returns `out`.
## A player uses this with what the host decided, so the two can never disagree.
func swap(id: int, out: int) -> int:
	if everything or not Weapons.valid(id) or has(id):
		return -1
	for s: int in SLOTS_OF[Weapons.kind_of(id)]:
		if slots[s] == out:
			slots[s] = id
			return out
	return -1


func get_state() -> Array:
	return [everything] + slots


static func from_state(state: Array) -> Loadout:
	var lo := Loadout.new()
	lo.everything = state[0]
	lo.slots = state.slice(1, 1 + Slot.COUNT)
	return lo
