extends TestCase
## Zombie variants: workers, nurses, cops, soldiers... Looks only, and the same on every peer.

const O := Characters.Outfit
const HATTED := [O.WORKER, O.NURSE, O.COP, O.SOLDIER, O.FIREFIGHTER]


func _tris(mi: MeshInstance3D) -> int:
	return mi.mesh.get_faces().size() / 3


func test_there_is_a_good_spread_of_variants() -> void:
	assert_gt(Characters.OUTFIT_NAMES.size(), 7, "at least eight kinds of zombie")
	for wanted in ["civilian", "worker", "nurse", "cop", "soldier"]:
		assert_true(Characters.OUTFIT_NAMES.has(wanted), wanted + " exists")
	assert_eq(Characters.OUTFIT_NAMES.size(), O.size(), "every outfit has a name")


func test_every_outfit_builds_a_whole_body_and_animates() -> void:
	for outfit: int in O.values():
		for type in [Zombie.Type.WALKER, Zombie.Type.RUNNER]:
			var rig := Characters.zombie(40 + outfit, type, outfit)
			add_child(rig)
			var n: String = Characters.OUTFIT_NAMES[outfit]
			assert_eq(rig.segs.size(), 10, n + " has all ten body segments")
			for anim in [Humanoid.Anim.WALK, Humanoid.Anim.ATTACK, Humanoid.Anim.CRAWL]:
				rig.set_anim(anim)
				for i in 30:
					rig.update(1.0 / 60.0, 2.0)
				var p := rig.neck.global_position
				assert_true(is_finite(p.x) and is_finite(p.y) and is_finite(p.z), n + " pose is finite")
			rig.free()


func test_outfits_look_different_from_each_other() -> void:
	var seen := {}
	for outfit: int in O.values():
		var s := Characters.zombie_style(7, Zombie.Type.WALKER, outfit)
		var key := "%s|%s|%d|%d" % [s.shirt, s.pants, (s.get("head_extras", []) as Array).size(),
			(s.torso_extras as Array).size()]
		assert_false(seen.has(key), "%s is not a copy of %s" % [Characters.OUTFIT_NAMES[outfit], seen.get(key, "")])
		seen[key] = Characters.OUTFIT_NAMES[outfit]


func test_uniforms_come_with_headgear_that_stays_on_the_head() -> void:
	var bare := Humanoid.create({ "zombie": true })
	add_child(bare)
	var bare_tris := _tris(bare.segs.head.mesh)
	bare.free()
	for outfit: int in HATTED:
		var rig := Characters.zombie(3, Zombie.Type.WALKER, outfit)
		add_child(rig)
		var n: String = Characters.OUTFIT_NAMES[outfit]
		assert_gt(_tris(rig.segs.head.mesh), bare_tris + 11, n + " wears something on its head")
		var before := _tris(rig.segs.head.mesh)
		var parts := rig.sever(Humanoid.Part.HEAD)
		assert_eq(parts.size(), 1)
		assert_eq(_tris(parts[0].mesh), before, n + ": the hat comes off with the head")
		Humanoid.discard(parts)
		rig.free()


func test_limbs_carry_their_clothes_when_severed() -> void:
	var rig := Characters.zombie(3, Zombie.Type.WALKER, O.FIREFIGHTER)
	add_child(rig)
	assert_gt(_tris(rig.segs.shin_l.mesh), 24, "reflective stripe is part of the shin")
	rig.free()


func test_same_zombie_id_looks_the_same_on_every_peer() -> void:
	for id in [1, 2, 17, 233, 4096]:
		var a := Characters.outfit_for(id, Zombie.Type.WALKER)
		assert_eq(Characters.outfit_for(id, Zombie.Type.WALKER), a, "picked from the id, not at random")
		var host := Zombie.create(id, Zombie.Type.WALKER, true, Vector3.ZERO)
		var client := Zombie.create(id, Zombie.Type.WALKER, false, Vector3.ZERO)
		assert_eq(host.outfit, a)
		assert_eq(client.outfit, host.outfit, "client draws what the host has")
		assert_eq(str(Characters.zombie_style(id, Zombie.Type.WALKER)), str(Characters.zombie_style(id, Zombie.Type.WALKER)),
			"whole look is repeatable")
		host.free()
		client.free()


func test_a_horde_is_a_mixed_crowd() -> void:
	var counts := {}
	for id in range(1, 301):
		var o := Characters.outfit_for(id, Zombie.Type.WALKER)
		counts[o] = counts.get(o, 0) + 1
	for outfit: int in O.values():
		if outfit == O.FERAL:
			continue
		assert_gt(counts.get(outfit, 0), 5, Characters.OUTFIT_NAMES[outfit] + " shows up in a crowd of 300")
	assert_gt(counts[O.CIVILIAN], counts[O.SOLDIER], "ordinary people are the most common")
	assert_false(counts.has(O.FERAL), "walkers are never the feral leaper body")
	var streak := 0
	var longest := 0
	for id in range(1, 61):
		streak = streak + 1 if Characters.outfit_for(id, 0) == Characters.outfit_for(id + 1, 0) else 0
		longest = maxi(longest, streak)
	assert_lt(longest, 4, "neighbouring ids aren't all the same kind")


func test_leapers_keep_their_own_feral_look() -> void:
	for id in 30:
		assert_eq(Characters.outfit_for(id, Zombie.Type.LEAPER), O.FERAL)
	var s := Characters.zombie_style(9, Zombie.Type.LEAPER)
	assert_eq(s.eyes, Color("ffd400"))


func test_spawned_zombies_get_an_outfit() -> void:
	var g := await new_game()
	var z := g.spawn_zombie(Zombie.Type.WALKER, Vector3(0, 0.1, 20))
	assert_eq(z.outfit, Characters.outfit_for(z.zid, z.type))
