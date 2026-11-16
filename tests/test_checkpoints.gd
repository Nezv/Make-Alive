extends TestCase
## Checkpoints: reached once, the dead come back there, a crate opens, the director gives a breather,
## and there is something to see before you get there.

const S := MissionRules.Status
const CORNER := Vector3(0, 0.1, 0)
const NOWHERE := Vector3(0, 0.1, 20)


func _game(respawn := true) -> Game:
	var g := await new_game()
	g.set_physics_process(false)
	g.players[1].pos = NOWHERE
	g.rules.start([{ "id": "far", "kind": "reach", "zone": "exit", "seconds": 0.0, "waves": [], "text": "Go",
		"who": "any", "target": -1, "time_limit": 0.0 }], respawn)
	return g


func _crate(g: Game) -> AmmoCrate:
	for it: Interactable in g.interactables.values():
		if it is AmmoCrate:
			return it
	return null


func test_a_checkpoint_zone_is_reached_once_whatever_the_objective() -> void:
	var g := await _game()
	var calls := spy(g)
	g.rules.step(0.1)
	assert_eq(count(calls, &"on_checkpoint_reached"), 0)
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_eq(count(calls, &"on_checkpoint_reached"), 1)
	assert_eq(calls[0][1], ["corner"])
	assert_eq(g.rules.checkpoint, "corner")
	g.players[1].pos = NOWHERE
	g.rules.step(0.1)
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_eq(count(calls, &"on_checkpoint_reached"), 1, "only the first time")
	assert_true(g.rules.running(), "not an objective here: the mission goes on")


func test_the_corridor_objective_and_the_checkpoint_fire_once_together() -> void:
	var g := await new_game()
	g.set_physics_process(false)
	var calls := spy(g)
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_eq(count(calls, &"on_objective_reached"), 1)
	assert_eq(count(calls, &"on_checkpoint_reached"), 1)


func test_after_a_checkpoint_the_dead_respawn_there() -> void:
	var g := await _game()
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	g.players[1].pos = NOWHERE
	g.damage_player(1, 100000)
	assert_true(g.map.data.zone_contains("corner", g.players[1].pos + Vector3(0, 0.5, 0)), "back at the corner, not the start")


func test_a_checkpoint_brings_back_players_who_were_out() -> void:
	var g := await _game(false)
	g._add_player(7, "Guest")
	g.players[7].pos = NOWHERE
	g.damage_player(7, 100000)
	assert_true(g.rules.out.has(7))
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_false(g.rules.out.has(7), "back in the fight")
	assert_eq(g.players[7].health.hp, Config.PLAYER_HP)
	assert_true(g.map.data.zone_contains("corner", g.players[7].pos + Vector3(0, 0.5, 0)), "at the checkpoint")


func test_the_crate_at_the_checkpoint_is_locked_until_it_is_reached() -> void:
	var g := await new_game("corridor", "", true)
	g.set_physics_process(false)
	var crate := _crate(g)
	assert_eq(crate.unlock, "corner", "the data ties it to the checkpoint")
	assert_true(crate.locked)
	assert_true(crate.prompt().to_lower().contains("locked"), crate.prompt())
	g.players[1].pos = crate.global_position
	g._ammo_used(1, Weapons.Ammo.MM762, 1000)
	g.host_interact(1, crate.iid, Weapons.AK47)
	assert_eq(crate.uses, Config.AMMO_CRATE_USES, "nothing from a locked crate")
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_false(crate.locked)
	assert_false(crate.get_state().locked, "every peer hears of it")
	g.players[1].pos = crate.global_position
	g.host_interact(1, crate.iid, Weapons.AK47)
	assert_eq(crate.uses, Config.AMMO_CRATE_USES - 1)


func test_the_director_gives_a_short_calm() -> void:
	var g := await _game()
	var d := g.director
	d.enabled = true
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_near(d.calm_left, Config.CHECKPOINT_CALM, 0.001)
	var before := g.zombies.size()
	d._trickle = 0.0
	d._horde_timer = 0.0
	d.step(1.0)
	assert_eq(g.zombies.size(), before, "nobody comes during the calm")
	d.step(Config.CHECKPOINT_CALM)
	d.step(0.1)
	assert_gt(g.zombies.size(), before, "then they do")


func test_a_toast_says_so() -> void:
	var g := await _game()
	var said := []
	g.hud.toast_label.text = ""
	g.players[1].pos = CORNER
	g.rules.step(0.1)
	assert_true(g.hud.toast_label.text.to_upper().contains("CHECKPOINT"), g.hud.toast_label.text)


func test_the_checkpoint_has_a_lit_tent_and_a_painted_arrow_before_it() -> void:
	var g := await new_game()
	var look := g.map.root.find_child("Checkpoint_corner", true, false) as Node3D
	assert_true(look != null, "built from the zone's data")
	assert_true(look.find_child("Lamp", true, false) != null, "lit")
	var data: Dictionary = MapAreas.CORRIDOR.zones.filter(func(z: Dictionary) -> bool: return z.id == "corner")[0]
	assert_true(data.has("look") and data.has("arrow"))
	var arrow: Vector3 = data.arrow.at
	assert_false(g.map.data.zone_contains("corner", arrow + Vector3(0, 0.5, 0)), "the arrow is on the way, before it")
	assert_eq(MapData.new(MapAreas.CORRIDOR).errors, [])
