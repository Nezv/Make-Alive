class_name GameHooks
extends Node
## THE GAMEPLAY SCRIPT. Every interesting moment in the game calls one function here.
## Want something to happen when X? Find on_X below and write it there.
##
## All hooks run on the HOST only (the host is the authority), so it's safe to change game
## state here: heal, damage, spawn, open doors... Results reach the other players through the
## normal sync. Use game.feed.rpc("text") for the message log and game.announce.rpc("text")
## for a big on-screen banner.
##
## Every hook also emits `fired(name, args)`, which is how the tests watch them.
##
## Adding a hook: write `func on_thing(...)` here starting with `fired.emit(...)`, call it from
## the host code where the thing happens, and add a test in tests/ that expects it.

signal fired(hook: StringName, args: Array)

var game: Game


# --- Player ---------------------------------------------------------------------

## HP just dropped to Config.LOW_HP_FRACTION or below. Fires once per dip.
func on_low_hp(player_id: int) -> void:
	fired.emit(&"on_low_hp", [player_id])
	game.feed.rpc("%s is badly hurt!" % game.player_name(player_id))


## `by` is the zombie that did it (null for other causes).
func on_player_damaged(player_id: int, amount: int, by: Zombie) -> void:
	fired.emit(&"on_player_damaged", [player_id, amount, by])


func on_player_died(player_id: int) -> void:
	fired.emit(&"on_player_died", [player_id])
	game.feed.rpc("%s was eaten" % game.player_name(player_id))
	game.respawn_player(player_id, "died")


func on_player_joined(player_id: int) -> void:
	fired.emit(&"on_player_joined", [player_id])
	game.feed.rpc("%s joined" % game.player_name(player_id))


# --- Right-click ------------------------------------------------------------------

## A player right-clicked something in reach. Routes to the specific handler below.
func on_right_click(player_id: int, target: Interactable) -> void:
	fired.emit(&"on_right_click", [player_id, target])
	if target is Door:
		on_right_click_door(player_id, target)
	elif target is Lootbox:
		on_right_click_lootbox(player_id, target)
	elif target is WeaponPickup:
		on_right_click_weapon(player_id, target)


func on_right_click_door(player_id: int, door: Door) -> void:
	fired.emit(&"on_right_click_door", [player_id, door])
	door.toggle()


func on_right_click_lootbox(player_id: int, box: Lootbox) -> void:
	fired.emit(&"on_right_click_lootbox", [player_id, box])
	var item := box.try_open()
	if item != "":
		on_loot_received(player_id, item)


## A gun lying in a truck, by a corpse, on a table...
func on_right_click_weapon(player_id: int, pickup: WeaponPickup) -> void:
	fired.emit(&"on_right_click_weapon", [player_id, pickup])
	var weapon := pickup.take()
	if weapon >= 0:
		on_weapon_picked_up(player_id, weapon, pickup)


func on_weapon_picked_up(player_id: int, weapon: int, pickup: WeaponPickup) -> void:
	fired.emit(&"on_weapon_picked_up", [player_id, weapon, pickup])
	game.give_weapon(player_id, weapon)
	game.feed.rpc("%s found a %s" % [game.player_name(player_id), Weapons.def(weapon).name])


func on_loot_received(player_id: int, item: String) -> void:
	fired.emit(&"on_loot_received", [player_id, item])
	match item:
		"medkit":
			game.heal_player(player_id, Config.MEDKIT_HEAL)
			game.feed.rpc("%s found a medkit (+%d HP)" % [game.player_name(player_id), Config.MEDKIT_HEAL])


# --- Zombies ----------------------------------------------------------------------

## A bullet hit a zombie. `part` is a Humanoid.Part.
func on_zombie_hit(zombie: Zombie, part: int, damage: int, by_player: int) -> void:
	fired.emit(&"on_zombie_hit", [zombie, part, damage, by_player])


## An arm or leg just came off (the zombie is still alive).
func on_limb_severed(zombie: Zombie, part: int, by_player: int) -> void:
	fired.emit(&"on_limb_severed", [zombie, part, by_player])


## Called just before the zombie is removed and turned into a ragdoll.
func on_zombie_killed(zombie: Zombie, by_player: int, headshot: bool) -> void:
	fired.emit(&"on_zombie_killed", [zombie, by_player, headshot])


## A leaper finished its jump (it may or may not have hit anyone).
func on_zombie_leap_landed(zombie: Zombie) -> void:
	fired.emit(&"on_zombie_leap_landed", [zombie])


func on_horde_incoming(wave: int, count: int) -> void:
	fired.emit(&"on_horde_incoming", [wave, count])
	game.announce.rpc("HORDE INCOMING  ·  wave %d" % wave)


# --- World ------------------------------------------------------------------------

## Zombies smashed a door down.
func on_door_broken(door: Door) -> void:
	fired.emit(&"on_door_broken", [door])
	game.feed.rpc("The door has been smashed!")
