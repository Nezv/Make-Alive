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
	game.score.add(player_id, "damage", amount)
	game.director.hurt(amount) # being hurt is what the pacing feels


func on_player_died(player_id: int) -> void:
	fired.emit(&"on_player_died", [player_id])
	game.feed.rpc("%s was eaten" % game.player_name(player_id))
	game.drop_backpack(player_id) # what they carried stays where they fell
	game.clear_status(player_id)
	if game.rules.running() and not game.rules.respawn:
		game.rules.set_out(player_id, true) # no way back yet: with everyone out the mission is lost
		game.mark_dead(player_id)
	else:
		game.respawn_player(player_id, "died")


## A player is back on their feet at the spawn (or the checkpoint): `reason` is "died", "respawn" (the
## timer), "checkpoint" or "spawn" (joining).
func on_player_respawned(player_id: int, reason: String) -> void:
	fired.emit(&"on_player_respawned", [player_id, reason])


## Someone said something in the chat (the dead too).
func on_chat(player_id: int, text: String) -> void:
	fired.emit(&"on_chat", [player_id, text])


## Someone marked a spot for everyone.
func on_ping(player_id: int, spot: Vector3) -> void:
	fired.emit(&"on_ping", [player_id, spot])


func on_player_joined(player_id: int) -> void:
	fired.emit(&"on_player_joined", [player_id])
	game.feed.rpc("%s joined" % game.player_name(player_id))


## At 0 HP a player goes down instead of dying (fired by the downed-state step).
func on_player_downed(player_id: int) -> void:
	fired.emit(&"on_player_downed", [player_id])


func on_player_revived(player_id: int, by_player: int) -> void:
	fired.emit(&"on_player_revived", [player_id, by_player])
	game.score.add(by_player, "revives")


# --- Mission ----------------------------------------------------------------------

## The match began on a mission (`mission` is a Missions id). Free play never fires this.
func on_mission_started(mission: String) -> void:
	fired.emit(&"on_mission_started", [mission])


## An objective of the mission's list was completed. `by_player` is 0 when nobody in particular did it.
func on_objective_reached(objective_id: String, by_player: int) -> void:
	fired.emit(&"on_objective_reached", [objective_id, by_player])


## The way out is open: `zone` is the id of the extraction zone in the map's data.
func on_extraction_ready(zone: String) -> void:
	fired.emit(&"on_extraction_ready", [zone])


## These players got out. The mission is won.
func on_extracted(player_ids: Array) -> void:
	fired.emit(&"on_extracted", [player_ids])
	game.announce.rpc("EXTRACTED")


func on_mission_failed(reason: String) -> void:
	fired.emit(&"on_mission_failed", [reason])
	game.announce.rpc("MISSION FAILED  ·  %s" % reason)


## A checkpoint zone was reached (once each): the dead come back there, its crate opens, a breather.
func on_checkpoint_reached(checkpoint_id: String) -> void:
	fired.emit(&"on_checkpoint_reached", [checkpoint_id])
	for id: int in game.rules.out.keys():
		game.rules.set_out(id, false)
		game.respawn_player(id, "checkpoint")
	for it: Interactable in game.interactables.values():
		if it is AmmoCrate and (it as AmmoCrate).unlock == checkpoint_id:
			(it as AmmoCrate).open_lock()
	game.director.calm(Config.CHECKPOINT_CALM)
	game.announce.rpc("CHECKPOINT REACHED")


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
	elif target is AmmoBox:
		on_right_click_ammo_box(player_id, target)
	elif target is AmmoCrate:
		on_right_click_ammo_crate(player_id, target)
	elif target is Backpack:
		on_right_click_backpack(player_id, target)


func on_right_click_door(player_id: int, door: Door) -> void:
	fired.emit(&"on_right_click_door", [player_id, door])
	door.toggle()


func on_right_click_lootbox(player_id: int, box: Lootbox) -> void:
	fired.emit(&"on_right_click_lootbox", [player_id, box])
	var wanted := StringName(box.loot)
	if not box.opened and Inventory.valid(wanted) and game.inventory_room(player_id, wanted) <= 0:
		game.notice_to(player_id, "Can't carry any more %s" % Inventory.item_name(wanted)) # it stays shut for later
		return
	var item := box.try_open()
	if item != "":
		on_loot_received(player_id, item)


## A gun lying in a truck, by a corpse, on a table...
func on_right_click_weapon(player_id: int, pickup: WeaponPickup) -> void:
	fired.emit(&"on_right_click_weapon", [player_id, pickup])
	var weapon := pickup.weapon
	if weapon < 0 or not game.players.has(player_id):
		return
	var mag: int = Weapons.def(weapon).mag
	var rounds := pickup.rounds if pickup.rounds >= 0 else mag
	var carried: Loadout = game.players[player_id].loadout
	pickup.take()
	if carried.has(weapon) and not carried.everything: # a second one: strip its magazine
		var got := game.give_ammo(player_id, Weapons.ammo_of(weapon), rounds)
		if got > 0:
			on_ammo_picked_up(player_id, Weapons.ammo_of(weapon), got)
		return
	on_weapon_picked_up(player_id, weapon, pickup, rounds)


## `rounds`: what is in the magazine of the gun that was lying there.
func on_weapon_picked_up(player_id: int, weapon: int, pickup: WeaponPickup, rounds := -1) -> void:
	fired.emit(&"on_weapon_picked_up", [player_id, weapon, pickup])
	game.give_weapon(player_id, weapon, rounds)
	game.feed.rpc("%s found a %s" % [game.player_name(player_id), Weapons.def(weapon).name])


## A player's slots were full: `weapon` went to the ground as `pickup`, at their feet.
func on_weapon_dropped(player_id: int, weapon: int, pickup: WeaponPickup) -> void:
	fired.emit(&"on_weapon_dropped", [player_id, weapon, pickup])


## A carton of one calibre: the player takes what fits in their reserve, the rest stays in it.
func on_right_click_ammo_box(player_id: int, box: AmmoBox) -> void:
	fired.emit(&"on_right_click_ammo_box", [player_id, box])
	if box.taken_by >= 0:
		return
	var got := game.give_ammo(player_id, box.ammo, box.rounds)
	if got > 0:
		box.take(got, player_id)
		on_ammo_picked_up(player_id, box.ammo, got)


## The military crate: a couple of cartons of whatever the gun in the player's hands is fed with.
func on_right_click_ammo_crate(player_id: int, crate: AmmoCrate) -> void:
	fired.emit(&"on_right_click_ammo_crate", [player_id, crate])
	if crate.locked or crate.uses <= 0 or not game.players.has(player_id):
		return
	var type := Weapons.ammo_of(game.players[player_id].weapon)
	var carton: int = Weapons.AMMO[type].box
	var got := game.give_ammo(player_id, type, carton * Config.AMMO_CRATE_BOXES)
	if got > 0 and crate.use(): # a full player wastes no use
		on_ammo_picked_up(player_id, type, got)


## `rounds` of a calibre (Weapons.Ammo) went into a player's reserve from a box, a crate or a drop.
func on_ammo_picked_up(player_id: int, ammo_type: int, rounds: int) -> void:
	fired.emit(&"on_ammo_picked_up", [player_id, ammo_type, rounds])


## What a lootbox held, by Inventory id: it goes in the player's pack.
func on_loot_received(player_id: int, item: String) -> void:
	fired.emit(&"on_loot_received", [player_id, item])
	if Inventory.valid(StringName(item)) and game.give_item(player_id, StringName(item)) > 0:
		game.feed.rpc("%s found a %s" % [game.player_name(player_id), Inventory.item_name(StringName(item)).to_lower()])


# --- Inventory --------------------------------------------------------------------

## `count` of an item went into a player's inventory (found, looted, handed out).
func on_item_picked_up(player_id: int, item: StringName, count: int) -> void:
	fired.emit(&"on_item_picked_up", [player_id, item, count])


func on_key_picked_up(player_id: int, key: StringName) -> void:
	fired.emit(&"on_key_picked_up", [player_id, key])


## A player used an item (it is on, and the host already took it out of their inventory): this is what it does.
## Throwables have no effect yet: S093 writes theirs here.
func on_item_used(player_id: int, item: StringName) -> void:
	fired.emit(&"on_item_used", [player_id, item])
	if item == Inventory.PAINKILLERS:
		game.players[player_id].health.add_temp(Config.PAINKILLERS_TEMP)
		return
	if item != Inventory.MEDKIT and item != Inventory.BANDAGE:
		return
	var health: Health = game.players[player_id].health
	var before := health.hp
	game.heal_player(player_id, Config.MEDKIT_HEAL if item == Inventory.MEDKIT else Config.BANDAGE_HEAL)
	(game.players[player_id].status as PlayerStatus).stop_bleeding()
	game._sync_status(player_id)
	on_player_healed(player_id, item, health.hp - before)


## A heal finished: `amount` HP came back (and the wounds closed).
func on_player_healed(player_id: int, item: StringName, amount: int) -> void:
	fired.emit(&"on_player_healed", [player_id, item, amount])


## A zombie's hit opened another wound: `stacks` are bleeding now.
func on_player_bleeding(player_id: int, stacks: int) -> void:
	fired.emit(&"on_player_bleeding", [player_id, stacks])


## What a player was putting on was knocked off (a hit) or abandoned (a sprint). The item is still theirs.
func on_item_use_cancelled(player_id: int, item: StringName) -> void:
	fired.emit(&"on_item_use_cancelled", [player_id, item])


## A dead player's inventory is lying where they fell.
func on_backpack_dropped(player_id: int, pack: Backpack) -> void:
	fired.emit(&"on_backpack_dropped", [player_id, pack])


## Someone takes what they can from a backpack; what does not fit stays in it.
func on_right_click_backpack(player_id: int, pack: Backpack) -> void:
	fired.emit(&"on_right_click_backpack", [player_id, pack])
	game.loot_backpack(player_id, pack)


# --- Zombies ----------------------------------------------------------------------

## A bullet hit a zombie. `part` is a Humanoid.Part.
func on_zombie_hit(zombie: Zombie, part: int, damage: int, by_player: int) -> void:
	fired.emit(&"on_zombie_hit", [zombie, part, damage, by_player])


## An arm or leg just came off (the zombie is still alive).
func on_limb_severed(zombie: Zombie, part: int, by_player: int) -> void:
	fired.emit(&"on_limb_severed", [zombie, part, by_player])
	game.score.add(by_player, "severs")


## Called just before the zombie is removed and turned into a ragdoll.
func on_zombie_killed(zombie: Zombie, by_player: int, headshot: bool) -> void:
	fired.emit(&"on_zombie_killed", [zombie, by_player, headshot])
	game.score.add(by_player, "kills")
	if headshot:
		game.score.add(by_player, "headshots")
	if not game.map.infinite_ammo: # a few of the dead had ammo on them (which ones is seeded by their id)
		var drop := AmmoBox.roll_drop(zombie.zid, Characters.outfit_for(zombie.zid, zombie.type))
		if not drop.is_empty():
			game.drop_ammo_box(zombie.global_position, drop.ammo, drop.rounds)


## A player's shove connected.
func on_zombie_shoved(zombie: Zombie, by_player: int) -> void:
	fired.emit(&"on_zombie_shoved", [zombie, by_player])


## A leaper finished its jump (it may or may not have hit anyone).
func on_zombie_leap_landed(zombie: Zombie) -> void:
	fired.emit(&"on_zombie_leap_landed", [zombie])


## The director's pace changed: `state` is a HordeDirector.State (CALM, BUILD, PEAK, RELAX).
func on_pacing_changed(state: int) -> void:
	fired.emit(&"on_pacing_changed", [state])


func on_horde_incoming(wave: int, count: int) -> void:
	fired.emit(&"on_horde_incoming", [wave, count])
	game.announce.rpc("HORDE INCOMING  ·  wave %d" % wave)


# --- World ------------------------------------------------------------------------

## Zombies smashed a door down.
func on_door_broken(door: Door) -> void:
	fired.emit(&"on_door_broken", [door])
	game.feed.rpc("The door has been smashed!")


## Something loud happened at `position` (`loudness` is how many metres away it is heard).
## `by_player` is 0 when no player caused it.
func on_noise(position: Vector3, loudness: float, by_player: int) -> void:
	fired.emit(&"on_noise", [position, loudness, by_player])
