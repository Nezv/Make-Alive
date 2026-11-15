# Zombie Extraction — LAN multiplayer FPS (Godot 4.7, GDScript)

Early development. One test map (an L-shaped corridor), hordes of zombies that come apart.
Everything is code: no editor-made scenes, no imported assets. Models are built from boxes in GDScript.

## Commands (PowerShell, from the project folder)
- `tools\test.ps1` — run all tests headless (~12 s). `tools\test.ps1 zombie` runs only matching tests. **Run after every change.**
- `tools\godot.ps1` — play. `tools\godot.ps1 -e` opens the editor.
- `tools\godot.ps1 -- --host --demo` — zombie line-up right in front of you, no hordes (for looking at animations).
- `tools\play2.ps1` — two windows on one PC, host + guest, to test multiplayer alone.
- Other options after `--` (see top of `scripts/main.gd`): `--join=IP`, `--bot`, `--bot-aim=head|legs|arms`, `--no-fire`, `--spawn=N`, `--no-hordes`, `--quit-after=S`, `--screenshot=PATH --shot-at=2,4`, `--weapon=1..9`, `--pose=aim|sprint|reload`, `--gun-rack` (all nine gun models side on), `--zombie-rack=1` / `=2` (one still zombie of every outfit, half at a time; add `--back`).
- `tools\godot.ps1 -- --host` — play on the Joinville city map (the default; `--map=corridor` for the test corridor). From a PowerShell one-liner pass the args as an array (`$a = @('--headless','--','--city-plan=C:/dir'); tools\godot.ps1 @a`) to redraw `references/city_plan.png` and `city_on_reference.png` (which part of the city the map covers).
- `tools\godot.ps1 -- --host --mission=mirante` — start a city mission at its POI (terminal, hospital, prefeitura, batalhao, mirante). Without `--host`, `--mission=` just picks that pin on the menu map (for menu screenshots).
- `python tools/poi_sketches.py references/poi_sketches.html` — redraw the isometric sketches of the five mission maps.
- `python tools/trace_heights.py` — re-read the hill's heights off `joinville_topography.png` into `scripts/world/city_heights.gd`. `python tools/trace_city.py` — re-classify `joinville.png` into `scripts/world/city_picture.gd` (the menu's city). Both generated files: don't edit them by hand.
- **Seeing the game without a human:** run windowed with `--bot --screenshot=... --quit-after=...` and read the PNGs. Use this to check anything visual (poses, gore, lighting) before saying it works.

## Test-driven workflow (required)
1. Write a failing test in `tests/test_*.gd` (extend `TestCase`, methods named `test_*`, `await` allowed).
2. Run `tools\test.ps1 <name>` and watch it fail for the right reason.
3. Write the code. Run the whole suite. Commit only when it's green (a pre-commit hook enforces this).
- `await new_game()` gives a real host `Game` running offline with spawning off. `spy(g)` records every hook fired; `count(calls, &"on_x")` counts them. `wait_until(cond, timeout)`, `frames(n)`, `seconds(s)` for time.
- Test behaviour through the same entry points the game uses: `g.host_interact`, `g.hit_zombie`, `g.resolve_shot`, `g.damage_player`, `g.spawn_zombie`, `g.director.spawn_horde`.
- Random things (leap cooldown, stagger chance, zombie scale) must be pinned in tests, e.g. `z.leap_cd = 0.0`. A test that passes 9 times in 10 is a bug.
- A bug found by eye (screenshot) gets a test before the fix.

## Where things are
- `scripts/hooks.gd` — **the gameplay script.** `on_low_hp`, `on_right_click(target)` → `on_right_click_door` / `on_right_click_lootbox`, `on_loot_received`, `on_player_damaged`, `on_player_died`, `on_zombie_hit`, `on_limb_severed`, `on_zombie_killed`, `on_zombie_leap_landed`, `on_horde_incoming`, `on_door_broken`. Host-only. New gameplay reactions go here, not in `game.gd`.
- `scripts/config.gd` — every tuning number. Never inline numbers. Per-gun numbers are in `scripts/weapons.gd`.
- `scripts/weapons.gd` — the nine guns (damage, fire rate, magazine, reload, spread, recoil, zoom, sprint carry) plus `kick` (random recoil) and `scatter`. `weapon_state.gd` — magazine / reload / draw timers for one player, no nodes. `viewmodel.gd` — the first-person gun and arms: aim, sprint carry, reload, recoil, bolt and pump. `scripts/models/guns.gd` — the gun models.
- `scripts/game.gd` — the match: RPCs, host loop, shots, snapshots, turning host events into gore on every peer.
- `scripts/zombie.gd` — types (WALKER, RUNNER, LEAPER), state machine (CHASE, ATTACK, WINDUP, LEAP, LAND, STAGGER), per-part damage, AI. `scripts/horde_director.gd` — when zombies arrive.
- Guns over the network: clients send `client_shoot(origin, dir, weapon)`; the host uses that gun's damage, pellets and fire-rate limit, and puts the weapon id in the player snapshot so others see the right model. Magazines are client-side for now.
- `scripts/models/humanoid.gd` — jointed rig + procedural animation. `characters.gd` — looks: zombie outfits (civilian, worker, nurse, doctor, cop, soldier, firefighter, office, prisoner; leapers are feral) and the survivor. `mesh_kit.gd` — box/cylinder builder (one mesh per body part).
- `scripts/fx/gore.gd`, `ragdoll.gd` — blood, stains, spurts, gibs, chunks, ragdolls, corpses. All capped.
- `scripts/world/` — `corridor_map.gd` (geometry + navigation), `interactable.gd`, `door.gd`, `lootbox.gd`.
- `scripts/world/city_data.gd` — Joinville as data: the five POIs, streets, river, hill and squares, traced in pixels of `references/joinville.png`. `city_map.gd` — builds it: the edge is the convex hull of the POI lots plus `Config.CITY_MARGIN`; a 4 m cell grid (OUT / BLOCK / STREET / WATER / FOREST / PARK / LOT / BUILT) is both the layout and the navigation. The city is flat at y = 0; Morro da Boa Vista rises out of it (`CityHeights`, eased in from the forest's edge), so always place things with `map.ground_y(p)` and never assume y = 0 on the city. Placeholder POI buildings for now. To move or add a street, edit `CityData.STREETS` and redraw the plan. `joinville.png` cuts off Morro da Boa Vista: the Mirante and its road come from `joinville_topography.png` (same scale, `CityData.TOPO_OFFSET_PX`), and `EDGE_EXTRA` keeps the road's hairpin inside the edge. The way up starts where Rua Saguaçu ends (Rua Otto Eduardo Lepper is only a footpath).
- `scripts/world/scenery.gd` — the set-piece kit (what the old shelter map was made of): building elements (`shelter_building`, `facade`, `entrance`, `blast_hole`, `fire_escape`) and pieces (`crash_site` with the fallen helicopter, `triage_camp`, `motor_pool` with trucks/humvee/APC, `checkpoint`, `gun_pits`, `street_wrecks`, `roadblock`), plus weapon `spot`s. `kit.place(at, yaw).crash_site()`, then `kit.finish()`. The vehicles and other single props are in `props.gd`. The city puts a few in its squares (`CityMap._scenery`).
- `scripts/missions.gd` — the five missions (title, kind, brief), one per POI. `Game.mission` / `GameMap.mission` pick where everyone starts; clients get it in `welcome`.
- `scripts/net.gd` (autoload `Net`) — host/join by IP, LAN discovery. `zombie_wire.gd` — binary zombie snapshots.
- `scripts/player.gd`, `remote_player.gd`, `hud.gd`, `menu.gd` (all of central Joinville at night from `CityPicture`, the game's streets glowing red, a clickable pin per mission, Start, training corridor, join, quit), `controls.gd` (key bindings), `main.gd` (entry + command-line options).

## Rules that keep it working
- **Authority:** the host decides everything that matters (zombie HP, limbs, deaths, doors, loot, player HP). Clients send position, shots, right-clicks. Hooks run on the host only.
- **Gore is cosmetic and local.** The host sends *what happened* (`zombie_fx`: HIT / SEVER / DIE with part, position, direction); each peer makes its own blood and ragdolls. Never sync ragdoll physics.
- **Snapshots must fit one packet** (< ~1392 bytes): zombies go through `ZombieWire` (13 bytes each). Don't add fields casually; there's a test.
- **Interactables** sync through `get_state()` / `apply_state()`; ids (`iid`) are fixed in `CorridorMap.build()` and identical on every peer. Late joiners get all states in `welcome`.
- **Models:** stand on y=0, face **-Z**, metres. Positive limb rotation swings forward; pose "PITCH" channels lean forward. Yaw toward a direction: `atan2(-dir.x, -dir.z)`.
- **Zombie outfits are looks only and never sent:** `Characters.outfit_for(id, type)` picks from the zombie id, so every peer agrees. Never use `randf` for looks. Clothes are extra boxes merged into the body part's own mesh (`head_extras`, `torso_extras`, `upper_arm_extras`, ...), so they cost no draw calls and a hat leaves with the head.
- **Guns:** origin near the trigger, barrel along **-Z**. Vertex colour alpha = how metallic the part is (`Guns.material()`). The magazine and the action are separate meshes because they move. A new gun = an entry in `Weapons.DEFS` + a `_name()` builder in `guns.gd`; check it with `--gun-rack` and `--weapon=N --pose=aim`.
- **Viewmodel:** poses are weights eased 0..1 and blended (same idea as the zombie rig); never set `pivot` directly from gameplay code. Right mouse uses a door/lootbox if one is in reach, otherwise aims (`Game.right_click_is_use`).
- **Animation:** add a state by adding to `Humanoid.Anim` and writing its goal pose in `_write_goal`. Never set joint rotations directly: the rig eases toward the goal, which is what makes transitions smooth. A legless rig plays every state lying down.
- **Timers:** never capture a node in a timer lambda (it may be freed first). Use `Gore._later(delay, node, func(n): ...)` or connect a method directly.
- **Performance (144 fps on laptops):** one mesh per body part via `MeshKit.Builder`; floor stains are one MultiMesh; only two lamps cast shadows and the moon doesn't. Watch the "draws" number bottom-right.
- **GDScript typing:** values read from a Dictionary/Array are Variant. Write `var x: Type = dict.key`, not `:=`.
- After adding a script with `class_name`, the class cache must refresh: `tools\test.ps1` does it (`--import`); do the same before running the game from the command line.

## Not built yet
Extraction, limited ammo and pickups (reserve ammo is infinite; everyone carries all nine guns), inventory, reload/aim animation on other players, more maps, sounds beyond a procedural gunshot, zombies climbing/vaulting.
