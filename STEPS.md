# Make Alive — steps

The build order for everything in `TODO.md`, cut into steps one agent can finish in one session.
Finishing every step leaves a LAN co-op zombie extraction game set in a recognisable central Joinville.

## How to use this file

- **Pick:** the lowest-numbered step that is `[ ]` and whose `needs` are all `[x]`. One step per session.
- **Do:** follow `CLAUDE.md` (failing test first, numbers in `Config`, gameplay reactions in `hooks.gd`, host decides, gore is local, everything is code, no imported assets).
- **Prove:** the step's `test` passes in the whole suite, and the `see` command's screenshots were read and look right.
- **Close:** tick each feature done, tick the step when all are, commit. If the session runs out, tick what is done and leave the step open. Update `CLAUDE.md` ("Where things are", "Not built yet") and `TODO.md` when a step changes them.
- **Size:** S = under half a session, M = one session, L = one full session, stop at any ticked feature.

## Format (the mind map script reads this)

- `## Pnn · name` is a phase, `### [ ] Snnn · name` is a step, `- [ ]` is a feature, an indented `- [ ]` is a sub-feature. These are the map's nodes.
- A plain `- ` bullet is a spec note of the node above it (a leaf, or hidden in the map).
- A `> ` line under a step is its data: `needs` (step ids), `size`, `test`, `see`, separated by ` | `.
- Nothing else has meaning. Keep ids unique and never renumber a step, append new ones.

## Rules every step obeys

- **Real Joinville:** streets, sidewalks, river, squares and hill follow the references (`references/joinville.png`, the OpenStreetMap tiles `references/1.png` to `9.png`, the photos). Only the five POIs are real buildings with interiors. Every other building is a solid block with a believable facade and doors that do not open.
- **Budget:** 144 fps on a laptop. Two shadow-casting lamps. Every effect has a cap in `Config` and a pool. Watch "draws".
- **Network:** new effects travel as *what happened* (kind, position, direction, one argument), never as particles or physics. Zombie snapshots stay 13 bytes each unless the step says otherwise and the packet test still passes.
- **Looks are deterministic:** seeded from ids or the map's own RNG, never `randf`, so every peer sees the same city.
- **Animation:** poses are goals the rig eases toward (`Humanoid.Anim`, `_write_goal`) and viewmodel weights 0..1. No direct joint or pivot writes.

---

## P01 · Foundations

### [x] S001 · Mind map of this file
> needs: none | size: S | test: `python tools/steps_map.py --check` | see: open `references/steps_map.html`
- [x] `tools/steps_map.py` parses the format above
  - [x] Fails with file and line on a broken id, duplicate id, unknown `needs`, or a `needs` cycle
  - [x] `--next` prints the steps that can be started now
  - [x] `--stats` prints done / total per phase
- [x] Writes `references/steps_map.html`, one self-contained file, no libraries
  - [x] Radial tree: root, phases, steps, features, sub-features
  - [x] Done nodes green, startable steps bright, blocked steps dim
  - [x] Click a step to fold or unfold it, hover shows its spec notes and `needs`
  - [x] Dependency arrows between steps as a toggle
- [x] Line in `CLAUDE.md` Commands

### [x] S002 · Map data format
> needs: none | size: L | test: `tests/test_map_data.gd` | see: `--host --map=corridor`
- [x] `scripts/world/map_data.gd`: one dictionary per mission area
  - [x] Player spawns (one per player slot, facing)
  - [x] Zombie spawn closets (position, radius, which wave uses them)
  - [x] Horde routes (polyline from closet to the play area)
  - [x] Zones (id, polygon or box, floor range) for extraction, checkpoints, triggers
  - [x] Doors, lootboxes, ammo crates, weapon spots with fixed `iid`
  - [x] Objective list (kind, zone, seconds, wave sizes, text)
  - [x] Bounds polygon of the playable area and its blocked exits
- [x] `GameMap` reads it: `zones`, `spawns`, `objective_defs`
- [x] Corridor map ported to the format, behaviour unchanged
- [x] Validation: every position on walkable nav, every spawn closet out of sight of every player spawn, ids unique
- [x] `--zones` debug flag draws zones, closets and routes as coloured wireframes

### [x] S003 · Mission hooks
> needs: none | size: S | test: `tests/test_hooks_mission.gd`
- [x] `on_mission_started(mission)`
- [x] `on_objective_reached(objective_id, by_player)`
- [x] `on_extraction_ready(zone)`
- [x] `on_extracted(player_ids)`
- [x] `on_mission_failed(reason)`
- [x] `on_checkpoint_reached(checkpoint_id)`
- [x] `on_player_downed`, `on_player_revived`, `on_noise(position, loudness, by_player)` declared now, fired by later steps
- [x] All host only, all visible to `spy(g)`

### [x] S004 · Effects kit
> needs: none | size: L | test: `tests/test_fx_kit.gd` | see: `--host --demo --fx-rack`
- [x] `scripts/fx/fx.gd`: every later effect is built from these
  - [x] Pooled particle bursts (CPU particles from `MeshKit` quads and boxes), never allocated in a fight
  - [x] Pooled omni lights with a life curve, never casting shadows
  - [x] Pooled decals as one MultiMesh per kind (bullet hole, scorch, crack, puddle)
  - [x] Pooled billboards (smoke puff, flash, spark) with flipbook-free animation: scale, spin, colour, alpha over life
  - [x] Trails (ribbon mesh rebuilt per frame, capped length)
- [x] One budget: `Config.FX_MAX_*` per pool, oldest is reused, test proves the cap holds under a 500-burst spam
- [x] One wire: `Game.play_fx(kind, position, direction, arg)` on the host, sent as the reliable `world_fx` RPC on its own channel, every peer plays it locally
- [x] Quality tiers LOW / MEDIUM / HIGH scale counts and lifetimes
- [x] `--fx-rack` shows every registered effect looping in a row, labelled

### [x] S005 · Sound engine
> needs: none | size: L | test: `tests/test_sfx.gd`
- [x] `sfx.gd` synthesis primitives, all cached `AudioStreamWAV`
  - [x] Noise (white, pink, brown), sine, saw, square, FM pair
  - [x] Envelopes (attack, decay, sustain, release), exponential tails
  - [x] Filters (one-pole low and high pass, band pass, comb), soft clip, bit-crush
  - [x] Layers and pitch sweep, seeded so a sound is the same on every run
- [x] Voice pool: `Config.SFX_VOICES` 3D players plus a few 2D, steals the quietest / farthest
- [x] Buses made in code: Master, Guns, Zombies, World, UI, Music, each with a volume
- [x] Distance attenuation and a low-pass by distance on every 3D voice
- [x] `Sfx.play(name, position, pitch_jitter)` and `Sfx.play_ui(name)` as the only entry points
- [x] Existing gunshot moved onto it

### [x] S006 · Settings store
> needs: none | size: S | test: `tests/test_settings.gd`
- [x] `scripts/settings.gd` autoload, saved to `user://settings.cfg`
  - [x] Mouse sensitivity, invert Y, FOV, aim-toggle or hold
  - [x] Volume per bus
  - [x] Graphics tier, fps cap, vsync, window mode, show draws
  - [x] Key bindings from `controls.gd`
  - [x] Player name
- [x] `changed(key)` signal, live apply
- [x] Unknown or broken file falls back to defaults without a crash

### [x] S007 · Balance sheet
> needs: none | size: S | test: `tools\test.ps1 balance`
- [x] `tools\balance.ps1` prints a table: every gun against every zombie type
  - [x] Shots and seconds to kill for head, torso, legs
  - [x] Damage per magazine, kills per magazine, seconds per reload
  - [x] Effective range from spread
- [x] Test asserts ordering rules (a sniper headshot kills a walker, the pistol is never the best DPS)
- [x] Writes `references/balance.md`

### [x] S008 · Bot playtests
> needs: S002 | size: M | test: `tests/test_bot_scenarios.gd`
- [x] Bot can follow nav to a zone, open doors, shoot what blocks it, reload
- [x] Scenario format: map, mission, seed, time limit, expected outcome
- [x] Corridor scenarios: the bot crosses the map with the director running, and holds the spawn against a horde
  - Fighting through a full horde in the open kills the bot most runs: no such scenario until the bot or the balance changes
- [x] Scenarios run headless at accelerated time inside the suite, total under 20 s
- [x] A failing scenario prints where the bot died or got stuck

### [x] S009 · Performance budget
> needs: none | size: M | test: `tests/test_budget.gd`
- [x] Per map: mesh, surface, light, shadow caster and collision shape counts, and the surfaces in view from a fixed set of cameras (the headless stand-in for draw calls)
- [x] Budgets in `Config.BUDGET_*`, test fails when a map goes over
- [x] Zombie count cap per map proven: host tick time with the cap alive stays under the frame
- [x] Snapshot size at the cap fits one packet
  - Players are packed by `PlayerWire` (22 bytes each), names travel once through `Game.player_names`
  - Zombie positions are sent relative to an anchor, so they survive anywhere in the city
- [x] `tools\perf.ps1` windowed run prints average and worst frame over 30 s with a horde

### [x] S010 · Screenshot gallery
> needs: none | size: S | see: `tools\shots.ps1`
- [x] `tools\shots.ps1` takes a fixed set of shots into `references/shots/` (ignored by git)
  - [x] Gun rack, zombie racks front and back, fx rack
  - [x] One street view and one landmark view per mission
  - [x] Viewmodel in aim, sprint, reload for the current weapon
- [x] `--shot-cam=x,y,z,yaw,pitch` places a free camera so shots repeat exactly, `--poi-cam` looks at a mission's place
- [x] Contact sheet `references/shots/index.html`

---

## P02 · Survival loop

### [x] S011 · Limited ammo
> needs: none | size: M | test: `tests/test_ammo.gd`
- [x] Ammo types by calibre: 9 mm, 5.7, 5.8, 7.62, 9x39, 12 gauge, .338, 7.62R
- [x] Reserve per type in `weapon_state.gd`, reload takes from it, partial reload when short
- [x] Shotgun shell-by-shell reload stops when the reserve is empty
- [x] Dry fire: click, small viewmodel twitch, no shot sent
- [x] Starting reserve per mission in map data, test maps keep infinite ammo behind `GameMap.infinite_ammo`
- [x] Host knows each player's reserve (sent on change, not per snapshot) so pickups are honest
- [x] HUD shows magazine / reserve

### [x] S012 · Ammo pickups and crates
> needs: S011, S002 | size: M | test: `tests/test_ammo_pickups.gd` | see: `--host --map=corridor --shot-at=2`
- [x] Ammo box interactable: small carton per calibre, coloured stripe, count printed as box pips
- [x] Ammo crate: military green, gives the held gun's type, limited uses, lid hinge animation
- [x] Zombie drops: seeded by zombie id, rare, soldiers and cops more often
- [x] Pickup feel: box hops to the player over 0.15 s, shrinks, small "+30" rises on the HUD
- [x] `on_ammo_picked_up` hook

### [x] S013 · Loadout
> needs: S011 | size: M | test: `tests/test_loadout.gd`
- [x] Slots: two primaries, one sidearm, one melee
- [x] Picking up with full slots swaps: the old gun drops at the feet as a `WeaponPickup` with its magazine count
- [x] Number keys follow slots, wheel cycles, last-weapon key
- [x] Holster and draw animation per swap (existing draw timer), slower for heavy guns
- [x] Start: pistol only on missions, everything on test maps (`all_weapons`)
- [x] Dropped guns sync to late joiners

### [x] S014 · Inventory and item wheel
> needs: S013 | size: L | test: `tests/test_inventory.gd` | see: `--host --map=corridor --wheel --shot-at=3`
- [x] `scripts/inventory.gd`, no nodes: counted stacks with caps
  - [x] Medkit, bandage, painkillers
  - [x] Throwable slots (filled later)
  - [x] Keys and keycards by id
  - [x] Planks for barricades
- [x] Host owns it, client gets its own inventory on change
- [x] Hold a key for a radial wheel: eight wedges, icons drawn from boxes, mouse direction picks, time slows nothing
  - [x] Eight wedges (`ItemWheel`, `ItemWheelView`): hold Tab, the mouse moves a pointer instead of the view, release picks
  - [x] Icons drawn from boxes (`ItemIcons`), a little hop when a wedge is lit
- [x] Quick-use keys for heal (H) and throwable (G)
- [x] Drop on death as a backpack other players can loot
- Medkit and bandage heal at once for now; painkillers and throwables are consumed with no effect until S015 and S093 write theirs in `GameHooks.on_item_used`.

### [ ] S015 · Bleeding and healing
> needs: S014 | size: M | test: `tests/test_bleeding.gd`
- [x] Bleed chance on a hit, stacks to three, ticks HP, pinned in tests
- [x] Bandage stops bleeding, medkit restores HP over its use time, painkillers give decaying temporary HP
  - The medkit and bandage are spent and heal only when their use time (`Inventory.use_time`) is over; a hit or a sprint cancels them and the item stays in the pack
- [ ] Use animation in first person: gun lowers, hands wrap a bandage (four eased poses), cancelled by sprint or damage
  - The cancelling is done (`LocalPlayer.check_use_cancel`, `Game.cancel_use`); `local_player.status.using` / `use_left` / `use_total` say what to animate
- [ ] Others see the heal pose on the remote player
  - The host already sets `PlayerWire.ACTION_HEAL` and `ACTION_BLEED` in every snapshot; `RemotePlayer.set_action` has to draw them
- [ ] Bleeding look: red drops from the lower screen edge, drip trail decals behind the player, heartbeat when low
  - Only a red "BLEEDING x2" line (`Hud.set_status`) so far
- [x] `on_player_bleeding`, `on_player_healed` hooks (and `on_item_use_cancelled`)

### [ ] S016 · Downed and revive
> needs: S015, S003 | size: L | test: `tests/test_downed.gd` | see: `tools\play2.ps1`
- [x] At 0 HP a player is downed, not dead: bleed-out timer, pistol only, crawl speed
  - Only while a teammate is still standing to get them up: the last one standing just dies. Damage to a downed player costs bleed-out time and can finish them
- [ ] First-person camera drops to the floor, tilts, desaturates toward grey as the timer runs
  - `local_player.status.downed` / `down_left` / `down_total` say when and how far
- [ ] Third-person rig: fall animation, propped on one arm, crawl cycle, reaching hand when a teammate is near
  - The host sets `PlayerWire.ACTION_DOWNED` in every snapshot (`RemotePlayer.action`)
- [ ] Revive: hold use within reach for `Config.REVIVE_SECONDS`, progress ring on both HUDs, interrupted by damage to the reviver
  - [x] Hold right-click beside a downed teammate (`Game.downed_teammate_near`, `start_revive`, `client_revive`); damage, a sprint, walking off or letting go cancels it; the bleed-out clock waits while it runs
  - [ ] The progress ring: only a text line so far (`Hud.set_status`, from `status.use_left` for the helper and `status.revive_left` / `revive_total` for the downed player)
- [ ] Revived at partial HP with a get-up animation and brief invulnerability
  - [x] `Config.REVIVE_HP` and `Config.REVIVE_INVULN` seconds in which nothing hurts them
  - [ ] The get-up animation
- [x] Zombies prefer standing players, finish downed ones when nobody else is near
- [x] All downed at once fails the mission

### [ ] S017 · Death and spectating
> needs: S016 | size: M | test: `tests/test_spectate.gd`
- [ ] Death camera: pulls back and up from the body, slow orbit, zombies feed on the corpse
  - The camera part is done (`Spectator.orbit_goal`, used when nobody is left to watch); the corpse and the feeding are not
- [ ] Spectate living teammates: next / previous, smoothed third-person follow, their HP and ammo shown
  - [x] Fire and aim cycle through the standing, `Spectator`, a camera that eases behind and above them, their name, HP and gun on screen (`Game.spectate_text`)
  - [ ] Their ammo: only its owner knows it (magazines are client-side), so the host would have to be told
- [x] Respawn rules per mission from map data: at the next checkpoint, after a timer, or never
  - `respawn` in the data: `true` at once, seconds, `"checkpoint"`, `false` never; the dead are `PlayerStatus.dead` (out, frozen, hidden from the others by `ACTION_DEAD`, no shooting or using) until then
- [ ] Respawn arrival: door kicked open or drop from a truck bed, not a pop
  - `GameHooks.on_player_respawned(id, reason)` fires when they are back
- [ ] Dead players keep text chat and pings
  - There is no chat or ping system yet

### [x] S018 · Stamina and movement
> needs: none | size: M | test: `tests/test_movement.gd`
- [x] Stamina: sprint drains, walking refills, empty forces a walk and heavy breathing
- [x] Crouch: lower capsule and camera, quieter steps, tighter spread
- [x] Jump with coyote time, landing dip scaled by fall speed, fall damage above a height
- [x] Vault over waist-high cover when sprinting into it (hands on, legs over, 0.5 s)
- [x] Weight: heavy guns sprint slower
- [x] Remote players show crouch and jump
- [x] HUD stamina bar that only appears while it is not full

### [x] S019 · Shove
> needs: S018 | size: M | test: `tests/test_shove.gd`
- [x] Melee key with any gun: stock or muzzle strike, 0.35 s, costs stamina
- [x] Viewmodel: gun pulls back 0.08 s, thrusts with a roll, recovers with overshoot
- [x] Cone hit on the host, pushes zombies back, staggers walkers, interrupts a leaper wind-up
- [x] Low damage, never severs
- [x] Shove a downed crawler away from a teammate
- [x] Impact: thud, small blood puff, camera nudge

### [x] S020 · Noise
> needs: S003 | size: M | test: `tests/test_noise.gd`
- [x] Every loud event calls `Game.make_noise(position, loudness, by)`: shots by calibre, explosions, breaking doors, sprinting, car alarms
- [x] Loudness per gun in `weapons.gd`, suppressed value alongside
- [x] Zombies within the radius turn and investigate the spot, not the player
- [x] Director heat: noise fills a meter, a full meter brings the next horde sooner
- [x] `on_noise` hook
- [x] `--noise` debug flag draws expanding rings where noise happened

---

## P03 · Missions

### [x] S021 · Mission state and objectives
> needs: S002, S003 | size: L | test: `tests/test_mission_rules.gd`
- [x] `scripts/mission_rules.gd` on the host: runs the map data's objective list in order
  - [x] REACH a zone (any player, or all alive players)
  - [x] HOLD a zone for seconds
  - [x] SURVIVE waves
  - [x] INTERACT with a thing (switch, radio, generator)
  - [x] EXTRACT
- [x] State in `welcome` and on change to every peer: objective index, text, timer, marker position
- [x] Fires the mission hooks
- [x] Fail conditions: everyone dead or downed, timer out
- [x] Corridor gets a tiny objective list as the test bed

### [x] S022 · Extraction zone
> needs: S021 | size: M | test: `tests/test_extraction.gd` | see: `--host --map=corridor --bot`
- [x] Zone opens with `on_extraction_ready`
- [x] Rule: every alive player inside starts the countdown, anyone leaving pauses it, downed players must be carried in or revived
- [x] Zone look: green flare smoke column rising 30 m and leaning with the wind, ground ring of pulsing light strips, particles drifting up inside
- [x] Countdown: big numerals on the HUD, beeps that rise in pitch for the last five
- [x] Success: fade to white, `on_extracted`, end screen

### [x] S023 · Defend objective
> needs: S021 | size: M | test: `tests/test_defend.gd`
- [x] Waves from map data: size, types, which closets, gap between waves
- [x] Wave grows with player count, each wave bigger and from more directions
- [x] Between waves: a calm with a countdown, time to barricade and restock
- [x] Last wave does not end, it lasts until the helicopter is down
- [x] HUD: wave number, zombies left, helicopter ETA
- [x] Siren at each wave start, `on_horde_incoming` already exists

### [ ] S024 · Helicopter
> needs: S022, S004 | size: L | test: `tests/test_helicopter.gd` | see: `--host --map=corridor --heli --shot-at=3,6,9`
- [ ] Model from boxes in `props.gd`: military transport, sliding side doors, skids, tail rotor, nav lights
- [ ] Rotor: blades as one spinning mesh, swapped for a translucent blur disc above a speed, blades droop when stopped
- [ ] Flight as a path on the host, sent as (path id, time): approach high, circle once, flare nose-up, settle
- [ ] Body language: banks into turns, nose dips when accelerating, sways in the hover, skids compress on touchdown
- [ ] Rotor wash: ring of dust blown outward on the ground, nearby particles and smoke pushed, players' view shakes softly underneath
- [ ] Lights: red and green nav lights, white strobe, red anti-collision beacon sweeping the ground
- [ ] Door gunner silhouette firing tracers at the horde during the hover
- [ ] Boarding: players enter the door zone, camera sits them inside, lift-off, the city falls away
- [ ] Sound hooks named for S087

### [x] S025 · Checkpoints
> needs: S021 | size: S | test: `tests/test_checkpoints.gd`
- [x] Checkpoint zone from map data, reached once
- [x] On reach: dead players respawn there, downed are revived, ammo crate unlocks
- [x] Look: a safe room door or a lit military tent, a hand-painted arrow before it
- [x] HUD toast and a short calm from the director

### [x] S026 · Scoring and end screen
> needs: S022 | size: M | test: `tests/test_scoring.gd`
- [x] Host counts per player: kills, headshots, limbs severed, damage taken, revives, shots fired and hit, distance
- [x] End screen: EXTRACTED in green or MISSION FAILED in red slamming in, mission time, a row per player with counters ticking up
- [x] Titles: most headshots, medic, survivor with least damage, last one standing
- [x] Best time per mission and difficulty saved to `user://records.cfg`
- [x] Buttons: retry (host), back to lobby
  - Until the lobby exists (S122) the second button goes back to the menu

### [x] S027 · Difficulty
> needs: S023 | size: S | test: `tests/test_difficulty.gd`
- [x] Easy / normal / hard / nightmare as multipliers in `Config`: zombie HP, damage, speed share of runners, horde size, ammo found
- [x] Horde size scales with players alive
- [x] Nightmare: no HUD markers, friendly fire on
- [x] Sent in `welcome`

### [x] S028 · Horde director 2
> needs: S002, S020 | size: L | test: `tests/test_director.gd`
- [x] Pacing states: CALM, BUILD, PEAK, RELAX, driven by stress (damage taken, zombies near, ammo low)
- [x] Spawns only in closets no alive player can see or is close to, test proves it across 1000 seeded spawns
- [x] Hordes travel along routes so they arrive as a stream round a corner, not a blob
  - One zombie every `Config.HORDE_STREAM_GAP` out of one hidden closet, each told the closet's `horde_routes` points (`Zombie.route`)
- [x] Wanderers: a few idle zombies placed ahead of the players, from map data
  - `zombie_wanderers` in the map's data; no map lists any yet (S051 and the five places will)
- [x] Specials on a budget: at most N of each special type alive (`Config.SPECIAL_BUDGET`, only the leaper for now)
- [x] Stragglers that lose the players are recycled to a closet ahead
- [x] `--director` debug overlay: state, stress, heat
- The city has no closets yet, so there the director still asks `CityMap.zombie_spawn_point` (a street corner out of sight); the closets come with S051

---

## P04 · Gun feel

### [ ] S029 · Muzzle flash and smoke
> needs: S004 | size: M | test: `tests/test_muzzle_fx.gd` | see: `--host --demo --weapon=4 --bot --shot-at=1,1.05,1.1`
- [ ] Flash mesh at the muzzle for one or two frames: star of 3 to 5 crossed quads, random roll, random scale
  - [ ] Shape per gun class: small round for pistols, long forked for rifles, wide ball for shotguns, side jets for braked snipers
  - [ ] Suppressed guns: no flash, a thin grey puff
- [ ] Light: one pooled omni, warm orange, 0.05 s, no shadows, only on the shooter's gun
- [ ] It lights the viewmodel hands and the nearest walls
- [ ] Smoke: two or three soft puffs drifting up and with the wind, 0.8 s
- [ ] Sustained fire: barrel heat shimmer and a steady wisp from the muzzle for 2 s after a long burst
- [ ] Remote players flash too, cheaper tier

### [ ] S030 · Tracers and bullet whiz
> needs: S004 | size: M | test: `tests/test_tracers.gd` | see: `tools\play2.ps1`
- [ ] Tracer: thin emissive streak from muzzle to hit, 40 m long segment moving at bullet speed, fades at the end
- [ ] Every shot for others' guns, every third for your own (clean view)
- [ ] Colour by calibre: yellow-white rifles, faint for pistols, a fan of short ones for shotguns
- [ ] Sniper shot: a vapour trail line that lingers 0.6 s and wobbles apart
- [ ] Near miss from a teammate's line: whiz sound and a tiny view flinch
- [ ] Capped, pooled

### [ ] S031 · Shell casings
> needs: S004 | size: M | test: `tests/test_casings.gd` | see: `--host --demo --weapon=4 --bot --shot-at=2`
- [ ] Casing mesh per class: brass pistol, brass rifle, red shotgun hull, long sniper case
- [ ] Ejects from the port with the gun's own direction, speed and spin, timed with the action (bolt guns eject on the bolt pull, pumps on the pump)
- [ ] Cheap physics: one bounce off the floor with a tumble, a second small one, then rest
- [ ] Tink on each bounce by surface
- [ ] Rests for a while, then sinks, capped by MultiMesh
- [ ] A wisp of smoke from the ejection port

### [ ] S032 · Surfaces and impacts
> needs: S004 | size: L | test: `tests/test_impacts.gd` | see: `--host --fx-rack`
- [ ] Surface kinds on collision bodies via metadata: concrete, asphalt, brick, metal, wood, glass, dirt, grass, water, flesh, tile
- [ ] Impact per surface
  - [ ] Concrete: grey dust cone, chips flying, round pocked hole
  - [ ] Brick: red dust, larger chips
  - [ ] Metal: sparks with gravity that bounce once, bright flash, dented hole with a shine ring, ricochet chance with a tracer
  - [ ] Wood: splinters, pale torn hole
  - [ ] Glass: star crack decal, a spray of shards
  - [ ] Dirt and grass: clod spray, dark puff, blades of grass
  - [ ] Water: vertical splash column, ring ripples
  - [ ] Tile: white shards, cracked decal
- [ ] Hole decals in the MultiMesh pool, aligned to the normal
- [ ] Shotgun: one combined puff for the pattern plus individual holes
- [ ] Penetration data per surface stored now, used by S101

### [ ] S033 · Gun voices
> needs: S005 | size: L | test: `tests/test_gun_sounds.gd`
- [ ] One synthesised shot per gun from layers: crack (noise burst), body (low thump by calibre), mechanical click, tail
  - [ ] P19 short pop, P90 buzzy snap, Type 95 and AK47 heavy bark, AS Val soft thud
  - [ ] USAS-12 and SPAS-12 boom with a long tail, T-5000 crack with a rolling echo, Dragunov sharp slap
- [ ] Tail by place: short and boxy indoors, long slapback between buildings, open on the hill
- [ ] Distance versions: far shots lose the crack and keep a dull thump
- [ ] Suppressed variants
- [ ] Dry fire click
- [ ] Small pitch and level variation per shot, seeded per shot index

### [ ] S034 · Handling animation and sound
> needs: S033 | size: L | test: `tests/test_viewmodel.gd` | see: `--weapon=1..9 --pose=reload`
- [ ] Reload has parts with their own sound and pose: mag release, mag out, new mag in, slap, bolt or charging handle
  - [ ] Empty reload differs from a tactical reload
  - [ ] The old magazine falls and stays on the floor a while
  - [ ] Shotgun: shell in per round, pump at the end
  - [ ] Bolt rifle: bolt up, back, forward, down, with the scope leaving the eye
- [ ] Inspect animation on a key: roll the gun left and right, check the chamber
- [ ] Idle life: slow breathing, micro-adjustments of the grip
- [ ] Draw and holster with cloth and sling sounds
- [ ] Low ammo: the last rounds of a magazine sound thinner and click

### [ ] S035 · Camera feel
> needs: S018 | size: M | test: `tests/test_camera_feel.gd`
- [ ] Walk and sprint bob as a figure eight, synced with footsteps
- [ ] Weapon sway lags the mouse, spring back, more with heavy guns
- [ ] Strafe tilt of a degree or two
- [ ] Recoil as a spring: kick up, recover most of the way, horizontal wander by gun
- [ ] FOV opens a little while sprinting, pinches on a sniper shot
- [ ] Shake sources mixed and capped: explosions, hits taken, leaper landing, helicopter
- [ ] All of it scaled by a setting, off at zero

### [ ] S036 · HUD 2
> needs: S011, S021 | size: L | test: `tests/test_hud.gd` | see: `--host --shot-at=2`
- [ ] Bottom right: weapon name, magazine as individual pips or a number, reserve, fire mode
- [ ] Bottom left: health bar with a bleed marker, stamina, item counts
- [ ] Top: compass strip with bearings, objective and teammate ticks
- [ ] Objective text with a typed-in reveal, strike-through and slide-out when done
- [ ] World markers: objective diamond with distance, clamped to the screen edge with an arrow
- [ ] Teammates: name over the head, outline through walls when far, downed icon with a timer
- [ ] Interaction prompt with the bound key and a hold ring
- [ ] Everything fades when not needed, HUD scale setting
- [ ] Built in code, no draw-call growth

### [ ] S037 · Hit feedback
> needs: S036 | size: M | test: `tests/test_hit_feedback.gd`
- [ ] Hit marker: four ticks that snap in and ease out, red and larger for a kill, a skull tick for a headshot
- [ ] Limb sever: a brief extra tick and a wet sound
- [ ] Damage direction: red arc on the side the hit came from, fades over a second
- [ ] Taking a hit: view punch away from the attacker, red edge flash, short muffling of sound
- [ ] Low HP: pulsing dark red vignette, desaturation, heartbeat, blurred edges
- [ ] Blood on the lens after a close kill: a few drops that run down and fade

### [ ] S038 · Other players' animations
> needs: S016, S019 | size: L | test: `tests/test_remote_anim.gd` | see: `tools\play2.ps1`
- [ ] Player snapshot carries an action byte: aim, reload, shove, heal, throw, downed, vault, crouch
- [ ] Rig states in `Humanoid.Anim`
  - [ ] Aim: shouldered gun, head tracks the look pitch
  - [ ] Reload: support hand to the pouch and back, gun tilted
  - [ ] Sprint with the gun carried low
  - [ ] Shove, throw (wind-up, release), heal
  - [ ] Hit flinch, death fall forward or backward by hit direction
- [ ] Upper and lower body blend: legs run while the arms reload
- [ ] Gun recoil kick on the remote rig per shot

---

## P05 · The real Joinville

### [ ] S039 · Trace the OpenStreetMap tiles
> needs: none | size: L | test: `tests/test_city_osm.gd` | see: redraw `references/city_plan.png`
- [ ] `tools/trace_osm.py` reads `references/1.png` to `9.png` into `scripts/world/city_osm.gd` (generated, never edited by hand)
  - [ ] Each tile registered to `joinville.png` pixels by two named control points per tile, kept in the tool
  - [ ] Building footprints: the brown-grey polygons, simplified to a few corners, area and centroid
  - [ ] Street casings by colour class: red trunk, orange, yellow, white residential, grey pedestrian
  - [ ] Water, parks, parking lots, forest stipple as polygons
- [ ] Overlay picture `references/osm_on_reference.png` proves the registration by eye
- [ ] Test: the terminal, the Prefeitura and the hospital footprints land inside their `CityData.POIS` lots
- [ ] Gaps between tiles reported, not guessed

### [ ] S040 · Street network 2
> needs: S039 | size: L | test: `tests/test_city_map.gd` | see: `--city-plan`
- [ ] `CityData.STREETS` checked street by street against the tiles: missing ones added, names fixed
  - [ ] Centre: Rua do Príncipe, Rua Nove de Março, Rua XV de Novembro, Rua Jerônimo Coelho, Rua Rio Branco, Rua Itajaí, Rua Abdon Batista, Rua Sete de Setembro, Rua Três de Maio, Rua Padre Carlos, Alameda Brüstlein
  - [ ] River roads: Avenida Hermann August Lepper, Avenida José Vieira, Avenida Doutor Paulo Medeiros, Rua Aubé
  - [ ] Foot of the hill: Rua Saguaçu, Rua Amazonas, Rua Chapecó, Rua Curitiba, Rua Cantareira, Rua Bela Vista
- [ ] Per street: carriageway width, lanes, one-way direction, sidewalk width each side, surface kind
- [ ] Junctions as real shapes: rounded kerb corners by radius, T and cross, the riverside interchange as slip roads
- [ ] Streets as meshes following the polyline with mitred joints, not grid cells; the 4 m grid stays for navigation only
- [ ] Only what lies inside a mission area is built in detail (S051)

### [ ] S041 · Road surface
> needs: S040 | size: L | test: `tests/test_road_surface.gd` | see: `--host --shot-cam` over Rua Nove de Março
- [ ] Surfaces as vertex colour and one shared material, no textures
  - [ ] Asphalt: dark, patched rectangles, tar seams, a lighter worn track per lane
  - [ ] Paralelepípedo (stone setts) on old centre streets and the terminal apron: rows drawn in vertex colour, slight height noise
  - [ ] Grey concrete pavers on the Mirante road
- [ ] Markings as thin overlay meshes in one draw per street
  - [ ] Centre line single or double yellow, white lane dashes, edge lines
  - [ ] Zebra crossings with a stop line before them, at every traced junction that has one
  - [ ] Bus lane and bus box lettering near the terminal, painted arrows, PARE on the ground
  - [ ] Yellow painted kerbs where parking is forbidden
- [ ] Details: manhole covers, storm drains at the kerb, speed humps with stripes, cracks and potholes seeded per street
- [ ] Camber: the road crown is a few centimetres above the gutters

### [ ] S042 · Sidewalks
> needs: S040 | size: M | test: `tests/test_sidewalks.gd` | see: `--host --shot-cam` on a street corner
- [ ] Kerb as a real 15 cm step with a granite edge, players and zombies walk it without a jump
- [ ] Paving kinds by street
  - [ ] Red interlocking brick pavers (the squares, the Mirante walkway)
  - [ ] Grey concrete slabs with joints
  - [ ] Petit-pavé black and white mosaic bands on the main shopping streets
- [ ] Dropped kerbs at driveways and crossings, yellow tactile strips at corners
- [ ] Tree pits, grass verges, low garden walls and iron fences in front of houses
- [ ] Sidewalks are nav cells: zombies use them, hordes spill onto the road

### [ ] S043 · Block massing
> needs: S039, S040 | size: L | test: `tests/test_city_blocks.gd` | see: `--host --shot-cam` skyline
- [ ] Every traced footprint inside a mission area becomes a solid extruded block, in the right place and shape
- [ ] Height from a class picked by footprint area, street and seed
  - [ ] House: one or two floors, hipped red clay tile roof
  - [ ] Shop row: two or three floors, flat roof behind a parapet
  - [ ] Slab block: 8 to 20 floors, set back, with a podium
  - [ ] Shed: large low footprint, shallow metal roof (the works along Rua Aubé)
- [ ] Known heights for buildings visible in the photos (the towers behind Praça da Bandeira, the blocks around the hospital) in a small override table
- [ ] Collision is the block, one mesh per city block, test counts draws
- [ ] Blocks outside every mission area: low-detail silhouettes only

### [ ] S044 · Facades
> needs: S043 | size: L | test: `tests/test_facades.gd` | see: `--host --shot-cam` street level, day and night
- [ ] Facade grammar baked into the block's mesh as vertex colour and shallow relief
  - [ ] Ground floor: shopfront glass, roll-down steel shutters, awnings, a doorway recess with a door that does not open
  - [ ] Upper floors: window grid by class, sills, balconies with railings on the slab blocks, air-conditioner boxes
  - [ ] Top: parapet, water tanks, antennas, lift overruns
- [ ] Joinville character: enxaimel half-timbered gables (dark beams on white, steep red roofs), pastel plaster houses, brise-soleil fins on the modernist blocks
- [ ] Shop signs as coloured boards with block lettering in Portuguese: FARMÁCIA, PADARIA, LOTÉRICA, LANCHONETE, FERRAGENS, deterministic per building
- [ ] Night: a seeded few windows lit warm or TV-blue as emission, some flickering, most dark
- [ ] Decay: boarded windows, soot above burnt ones, broken panes, quarantine tape across doors
- [ ] House numbers by the door

### [ ] S045 · Rio Cachoeira
> needs: S040, S004 | size: L | test: `tests/test_river.gd` | see: `--host --shot-cam` on a bridge
- [ ] Channel cut below street level: sloped grass and stone banks, a retaining wall where the avenues run beside it
- [ ] Water: one mesh, shader in code with slow flow along the river line, small ripples, dark green-brown, sky and lamp reflections as stretched streaks
- [ ] Bridges at the traced crossings: deck, kerbs, concrete or steel railings, piers in the water
- [ ] Floating things drifting with the flow: debris, a body, an upturned boat, seeded
- [ ] Imperial palm row along the riverside avenue as in `prefeitura3.png`
- [ ] Water is not walkable; falling in wades the player to the bank slowly, zombies stay out
- [ ] Mist over the water at night

### [ ] S046 · Street furniture
> needs: S041, S042 | size: L | test: `tests/test_street_furniture.gd` | see: `--furniture-rack`
- [ ] Props in `props.gd`, placed by rules along streets, seeded, merged per block
  - [ ] Avenue lamp: tall grey pole, curved arm, sodium-orange head
  - [ ] Square lamp: green post with two white globes (Praça da Bandeira)
  - [ ] Concrete power poles with a transformer, crossarms and sagging bundles of cables between them
  - [ ] Traffic lights on masts, some blinking yellow, some dead
  - [ ] Blue street-name plates on corner poles with the real street name
  - [ ] Bus stop shelter with a bench and an ad panel
  - [ ] Orelhão phone booth (the egg-shaped hood), green bins, benches, bollards, newsstand kiosk, fire hydrant, post box
  - [ ] Road signs: PARE, speed limit, one-way arrows, no parking
- [ ] Lamps follow the two-shadow rule: emission and a cheap light, shadows only from the manager (S108)
- [ ] A few lamps flicker or are bent and dead
- [ ] Small props are cover; thin poles do not block bullets

### [ ] S047 · Vegetation
> needs: S042 | size: L | test: `tests/test_vegetation.gd` | see: `--tree-rack`
- [ ] Trees from boxes and crossed leaf cards, a few seeded shapes per species, merged
  - [ ] Imperial palm: very tall smooth trunk, crown of drooping fronds (Alameda Brüstlein, the riverside)
  - [ ] Araucária: straight trunk, flat candelabra crown
  - [ ] Ipê in yellow or purple bloom, petals on the ground beneath
  - [ ] Broad street tree, hibiscus and bougainvillea bushes, clipped hedges
- [ ] Atlantic forest on Morro da Boa Vista: dense wall of canopy, tree ferns, palms, lianas, undergrowth, dark between the trunks
  - [ ] Near the road real trees, behind them merged billboards, then a solid silhouette
- [ ] Wind: vertex sway in a shader, stronger at the tips, gusts travel across a street
- [ ] Grass tufts on lawns and verges as one MultiMesh, pressed down where zombies ran
- [ ] Leaves fall and skitter along the gutter in gusts

### [ ] S048 · Apocalypse dressing
> needs: S046 | size: L | test: `tests/test_dressing.gd` | see: `--host --shot-cam` on the avenue
- [ ] Vehicles in `props.gd`: hatchback, sedan, pickup, delivery van, taxi, motorbike, the yellow city bus, ambulance, police car
  - [ ] States: parked, abandoned with doors open, crashed into a pole, rolled over, burnt out
  - [ ] Hazard lights still blinking on a few, a dome light on, a wiper still moving
- [ ] Traffic jam generator along a street: queue toward the way out of town, gaps to walk through
- [ ] Evacuation remains: suitcases, prams, shoes, shopping carts, a dropped teddy bear
- [ ] Military and police leftovers from `scenery.gd`: checkpoints, sandbags, concertina wire, body bags in rows
- [ ] Portuguese signs and paint: QUARENTENA, NÃO ENTRE, MORTOS DENTRO, arrows to ZONA SEGURA, missing-person flyers on walls
- [ ] Blood: drag trails into doorways, handprints, pools under cars
- [ ] Small fires in barrels and wrecks (uses S094 when present, a plain flicker before)
- [ ] Wrecks are cover and block nav

### [ ] S049 · Squares and landmarks
> needs: S044, S047 | size: L | test: `tests/test_landmarks.gd` | see: `--host --shot-cam` on Praça da Bandeira
- [ ] Praça da Bandeira from `praça_da_bandeira.jpg`: red paver field, the stone monument with bronze figures on a stepped red granite base, flagpole, white-edged tree beds, green bins
- [ ] Alameda Brüstlein: the double row of imperial palms on a long median
- [ ] Catedral on Rua do Príncipe as a tall silhouette block
- [ ] Cemitério do Imigrante: sloped ground, rows of old stones and crosses, iron gate
- [ ] Zoobotânico at the foot of the hill: pond, path ring, the gate (seen only on the Mirante mission)
- [ ] Each is exterior only, placed on its traced footprint

### [ ] S050 · Sky and time of day
> needs: S004 | size: L | test: `tests/test_sky.gd` | see: `--time=day|dusk|night --shot-at=2`
- [ ] Sky shader in code: gradient, sun or moon disc, stars that twinkle, two drifting cloud layers lit from below by the city at night
- [ ] Presets per mission in map data: overcast day, orange dusk with long shadows, moonlit night, storm
- [ ] One directional light per preset, shadows only by day and dusk
- [ ] Distance fog tinted by the preset, hides the draw distance limit
- [ ] Far backdrop: skyline silhouette of towers and the dark mass of Morro da Boa Vista with the lit Mirante on top, visible from every mission
- [ ] Columns of smoke on the horizon, a distant fire glow under the clouds
- [ ] `--time=` flag, sent in `welcome`

### [ ] S051 · Mission areas
> needs: S002, S043 | size: L | test: `tests/test_mission_areas.gd` | see: `--mission=<each>`
- [ ] Each mission builds only its area: the POI and the streets around it, bounds polygon in map data
- [ ] Edges closed believably, never an invisible wall in the open: bus across the road, collapsed facade, burning pile-up, military fence, flood water
- [ ] Beyond the edge: low-detail blocks and the backdrop
- [ ] Build time per area under a limit, measured in the test
- [ ] Visibility ranges on small props, block meshes split so culling works
- [ ] The whole-city map stays available as free play

### [ ] S052 · City navigation 2
> needs: S051, S028 | size: M | test: `tests/test_city_nav.gd`
- [ ] Nav grid built per mission area at 1 m near the POI, 4 m in the streets
- [ ] Kerbs, wreck gaps, fences with holes and stairs are walkable links
- [ ] Spawn closets authored per area: alleys, garage ramps, behind buses, manholes, each proven out of sight
- [ ] Horde routes authored per area so streams come down real streets
- [ ] Zombies do not walk through hedges, railings or water
- [ ] Bot scenario: walk the whole mission route without getting stuck

---

## P06 · The five places

### [ ] S053 · Building pipeline
> needs: S002 | size: L | test: `tests/test_building.gd` | see: `--building=sample`
- [ ] `scripts/world/building.gd`: a building from one data dictionary
  - [ ] Footprint point list (traced from the top view), wall thickness
  - [ ] Floors: count, height each, slab thickness
  - [ ] Openings per wall: window grid (columns, rows, size, sill), doors, big openings
  - [ ] Facade and roof colours, trim, relief (fins, bands, columns)
  - [ ] Roof kind: flat with parapet, hipped tile, metal shed, concrete canopy
  - [ ] Interior walls and rooms per floor as rectangles with door gaps
  - [ ] Stairs (straight, dog-leg), ramps, shafts between floors
- [ ] Output: meshes merged per floor and material, collision, nav for every floor with stair links, fixed `iid`s
- [ ] Floors above and below the player hidden or cheap
- [ ] Top-view plan export per building for checking against the reference
- [ ] `ground_y` and multi-floor zones work with `MapData`

### [ ] S054 · Interior kit
> needs: S053 | size: L | test: `tests/test_interior_kit.gd` | see: `--interior-rack`
- [ ] Parts: door frames, swing doors, double doors, glass doors, roller shutters, railings, columns, ceiling tiles with missing ones, floor patterns
- [ ] Furniture props: desks, office chairs, filing cabinets, counters, benches, lockers, shelves, vending machine, water cooler, beds, gurneys, wheelchairs, bunks, tables
- [ ] Clutter generator per room kind (office, ward, corridor, store room, barracks), seeded: papers, overturned chairs, blood, barricade attempts
- [ ] Ceiling lights: tube fixtures, some hanging by a wire and swinging, some dead
- [ ] Locked door (needs a key, a crowbar, or damage) and a light switch as interactables
- [ ] Elevator: shaft, car stuck between floors, doors that can be pried, ladder inside

### [ ] S055 · Barricades
> needs: S014, S054 | size: M | test: `tests/test_barricade.gd`
- [ ] Barricade point on doors and windows: holds up to five planks
- [ ] Building: hold use, a plank from the inventory goes up with a hammer animation, three knocks, each plank at a slightly different angle
- [ ] Zombies attack it: planks crack, splinter and fly off one at a time, arms reach through the gaps
- [ ] Repair while it stands
- [ ] Shooting through the gaps works, planks are bullet cover otherwise
- [ ] Plank piles as pickups
- [ ] State through `get_state` / `apply_state`

### [ ] S056 · Terminal Central
> needs: S053, S048 | size: L | test: `tests/test_poi_terminal.gd` | see: `--mission=terminal --shot-at=2`
- [ ] From `terminal1.png` and `praça_da_bandeira.jpg`
  - [ ] Huge raw concrete roof slab, water-stained, with the pleated zigzag fascia facing the square
  - [ ] Dark steel V-struts and trusses holding it
  - [ ] Central skylight strip with a hanging lattice
  - [ ] Bus bays on wet stone setts, raised platform islands with yellow kerbs
- [ ] Inside: ticket booths, turnstiles, benches, route boards with real destination names, kiosks, toilets block
- [ ] Yellow city buses: some in the bays, one jack-knifed across the exit, one with its doors open and lights on
- [ ] Lighting: cold tube lights under the slab, half dead, puddles catching them
- [ ] Player start on the platforms, first weapon spots, first ammo

### [ ] S057 · Mission: the terminal run
> needs: S056, S052, S022, S025 | size: L | test: `tests/test_mission_terminal.gd` | see: `--mission=terminal --bot`
- [ ] Route along real streets from the terminal to the Prefeitura's steps, drawn in map data
- [ ] Beats
  - [ ] Leave the terminal: the buses block the easy exit, out through the square
  - [ ] The centre streets: jammed cars, a horde from the side streets
  - [ ] Checkpoint halfway: a shop with its shutter half up
  - [ ] The river: cross a bridge that is a choke point
  - [ ] The riverside avenue under the palms, then the Prefeitura lawn
- [ ] Extraction on the lawn's concrete pad
- [ ] Director tuned for a moving fight: spawns ahead and behind, never on the route in view
- [ ] Bot scenario finishes it on easy

### [ ] S058 · Hospital Dona Helena, outside
> needs: S053, S048 | size: L | test: `tests/test_poi_hospital.gd` | see: `--mission=hospital --shot-at=2`
- [ ] From `hospital1.jpg` and `hospital2.png`, on Rua Blumenau
  - [ ] Old block: white, five floors, tall dark vertical fins over the entrance bay, logo panel on the blank wall
  - [ ] Middle block: four floors, olive-green spandrel bands between window rows
  - [ ] The low yellow old house between them
  - [ ] New tower: about twelve floors, white frame, blue glass, a taller central core carrying the lit sign
  - [ ] Covered drop-off canopy along the street, ramp, zebra crossing, ambulance bay
- [ ] Night look: the tower washed in blue floodlight from below, the sign glowing, most windows dark, a few flickering
- [ ] Street scene: abandoned ambulances, triage tents from `scenery.gd`, a queue of cars that never got in
- [ ] Rooftop helipad with the H, edge lights, a windsock

### [ ] S059 · Hospital, inside
> needs: S058, S054 | size: L | test: `tests/test_poi_hospital_interior.gd` | see: `--mission=hospital --floor=3`
- [ ] Ground floor: lobby with a reception desk, waiting chairs, the emergency room with curtained bays
- [ ] Ward floors: a long corridor, rooms both sides with beds, a nurses' station, a store room with loot
- [ ] Not every floor is open: two are blocked by fire or collapse and are passed by the stairs
- [ ] Two stairwells and the elevator shaft; the route forces a switch between them
- [ ] Power out: emergency lighting only
  - [ ] Red rotating beacons sweeping the corridors
  - [ ] Green exit signs
  - [ ] One generator room: restart it to light a floor and call the elevator car
- [ ] Details: IV stands, gurneys used as barricades, blood handprints on glass, a ward locked from the outside
- [ ] Nurse and doctor outfits weighted high here

### [ ] S060 · Mission: the hospital climb
> needs: S059, S022, S024 | size: M | test: `tests/test_mission_hospital.gd` | see: `--mission=hospital --bot`
- [ ] Start in the street, in through the emergency entrance
- [ ] Objectives: find the keycard, restart the generator, reach the roof, hold the helipad until the helicopter lands
- [ ] Zombies come up the stairwells behind the players and out of wards ahead
- [ ] Checkpoint at the mid floor
- [ ] Roof finale: wind, the city spread out below, the helicopter's light finding the pad
- [ ] Bot scenario finishes it on easy

### [ ] S061 · Prefeitura, outside
> needs: S053, S045, S047 | size: L | test: `tests/test_poi_prefeitura.gd` | see: `--mission=prefeitura --shot-at=2`
- [ ] From `prefeitura1.jpg`, `prefeitura2.jpg`, `prefeitura3.png`, between the river and the hill
  - [ ] Long three-floor brutalist bar: deep exposed concrete slab edges shading recessed window bands, salmon lower walls
  - [ ] Two red brick stair towers rising above the roof, sloped brick buttresses at the base
  - [ ] Blue steel space-frame lattice panels over the centre entrance and both wings
  - [ ] Ribbed metal roof with plant boxes
- [ ] The front lawn mound: brick stairs zigzagging up with steel railings, curved paths, flower beds, the blue "Prefeitura Municipal de Joinville" letter sign
- [ ] The concrete pad on the lawn is the landing zone
- [ ] Car parks on both sides, the riverside avenue and its palms in front, the forested hill rising behind
- [ ] Flagpoles, a torn banner across the entrance

### [ ] S062 · Mission: hold the Prefeitura
> needs: S061, S054, S055, S023, S024 | size: L | test: `tests/test_mission_prefeitura.gd` | see: `--mission=prefeitura --bot`
- [ ] Inside: main hall with a wide stair, council chamber, office wings, the brick stair towers, roof access
- [ ] Defend the hall: many windows and three doors to barricade, plank piles, ammo crate
- [ ] Three waves, each from more sides: the lawn, the car parks, then out of the forest behind
- [ ] Between waves: restock, repair
- [ ] Finale: fall back to the lawn pad, the helicopter lands among the horde
- [ ] Bot scenario survives on easy

### [ ] S063 · Mounted gun
> needs: S011, S004 | size: M | test: `tests/test_mounted_gun.gd`
- [ ] Tripod machine gun as an interactable: use to man, use to leave
- [ ] Limited arc, heavy slow traverse, belt of its own ammo, overheats (barrel glows from dull red to orange, steam when it cools)
- [ ] Viewmodel: both hands on spade grips, the whole gun shudders, belt links and big casings pour out
- [ ] Heavy tracers every shot, large muzzle flash lighting the sandbags
- [ ] Host owns who mans it, the gunner is exposed from behind
- [ ] Bullets tear limbs off at any range

### [ ] S064 · 62º Batalhão, outside
> needs: S053, S048 | size: L | test: `tests/test_poi_batalhao.gd` | see: `--mission=batalhao --shot-at=2`
- [ ] From `batalhao.jpg` and `batalhao2.jpg`, on Rua Ministro Calógeras
  - [ ] The quadrangle: long low buildings with red clay tile hip roofs around a paved parade ground
  - [ ] Front building in green and white with the entrance arch
  - [ ] "62 BI" painted in white on the far roof
  - [ ] Centre garden with the monument and flagpoles, painted lines of the parade ground
  - [ ] Front lawn with the white star-shaped beds
  - [ ] Arched metal-roof gym, the green sports court, the tree clump and the field behind
- [ ] Main gate with a guard house, boom barrier, wall with fence on top around the lot
- [ ] Military dressing from `scenery.gd`: trucks, humvee, APC on the parade ground, sandbag gun pits, tents
- [ ] A guard tower with a searchlight that still turns

### [ ] S065 · Mission: hold the Batalhão
> needs: S064, S054, S063, S023, S024 | size: L | test: `tests/test_mission_batalhao.gd` | see: `--mission=batalhao --bot`
- [ ] Inside: armoury with ammo crates and gun racks behind a locked cage, barracks rows, mess hall, command room with the radio
- [ ] Objectives: get in through the gate, call the helicopter on the radio, open the armoury, hold the parade ground
- [ ] Mounted guns in the pits and on the tower
- [ ] Waves pour over the walls and through the gate; soldier zombies in the mix
- [ ] The helicopter lands in the middle of the parade ground
- [ ] Bot scenario survives on easy

### [ ] S066 · Mirante, the summit
> needs: S053, S047 | size: L | test: `tests/test_poi_mirante.gd` | see: `--mission=mirante --shot-at=2`
- [ ] Before building: a photo of the tower must be in `references/` (none yet); read it first, do not build from memory
- [ ] The lookout tower on the 230 m summit, its deck, the way down inside it (stairs or ramp as in the photo)
- [ ] Summit clearing: car park, railings, coin binoculars, a kiosk, antenna masts with red lights
- [ ] The view: the whole city backdrop below, lit windows, fires, the river as a pale line
- [ ] Wind up here: stronger sway, louder, cloud wisps passing through the deck at night
- [ ] Player start on the deck

### [ ] S067 · Mirante, the road down
> needs: S066, S041 | size: L | test: `tests/test_poi_mirante_road.gd` | see: `--mission=mirante --shot-cam` on the hairpin
- [ ] From `mirante_street.jpg` and `mirante_entrance.jpg`
  - [ ] Road of grey pavers with a red brick walking lane beside it, split by a white line
  - [ ] Forest walls both sides, canopy closing overhead
  - [ ] Concrete power poles with thick cable bundles following the road
  - [ ] Guard rails on the outside of bends, drainage gutters, a retaining wall on the uphill side
- [ ] The hairpin and the grade from `CityHeights`; everything placed with `map.ground_y`
- [ ] The gate at the foot: concrete portal with MORRO DA BOA VISTA lettering, the white butterfly canopy, guard booth, boom barrier, yellow kerbs
- [ ] Side trail (Trilha Rústica) as a risky shortcut: dirt steps, roots, no lamps
- [ ] A few lamps only, long dark stretches for flashlights

### [ ] S068 · Mission: down from the Mirante
> needs: S067, S052, S022 | size: M | test: `tests/test_mission_mirante.gd` | see: `--mission=mirante --bot`
- [ ] Descend the tower: tight stairs, leapers
- [ ] The road: leapers drop out of the trees, runners come up the road in packs, fog between the trunks
- [ ] Checkpoint at the hairpin
- [ ] Choice: the lit road or the dark trail
- [ ] Extraction at the gate at the foot, a truck instead of the helicopter
- [ ] Bot scenario finishes it on easy

---

## P07 · Zombies

### [x] S070 · Room on the wire
> needs: none | size: M | test: `tests/test_zombie_wire.gd`
- [x] Type field widened to hold twelve types, state field to hold the new states, still 13 bytes
  - 4 bits of type, 5 of state; the id is 24 bits now
- [x] Flags packed into spare bits: burning, armoured parts left, climbing, crawling
  - `ZombieWire.FLAG_*` and a 4-bit `armour`; the host sets only crawling so far, the rest wait for their steps
- [x] Packet test at the zombie cap still passes
- [x] Version byte in `welcome` so a mismatched build is refused with a clear message
  - `Config.PROTOCOL_VERSION` (bump it with any change to what is on the wire), sent in `request_join` and `welcome`; `Game.join_refused` takes the client back to the menu with the message
- [x] Interest management: when the count exceeds one packet, each client gets the nearest zombies every tick and the far ones every few ticks
  - `Interest.pick`; today's cap of 60 fits in one packet with eight players, so it only starts to matter above `Interest.budget`. Clients keep a zombie that missed a packet for `Config.ZOMBIE_STALE` seconds

### [x] S136 · Low-poly bodies and skeleton ✅
> needs: none | size: L | test: `tests/test_body_model.gd` | see: `--host --body-rack`
- [x] `tools/models/poly.py`: low-poly kit, rings lofted into flat-shaded prisms, a tag per face ✅
- [x] `tools/models/measure.py`: proportions, face layout and colours read off `references/zombies.png` ✅
- [x] Generic male and female bodies (`body.py`): one closed piece per joint, shoulder ledge, torso break that bends closed ✅
  - [x] Faceted head: sunk sockets, V brow, glowing slit eyes, downturned mouth with teeth ✅
  - [x] Bone stubs in the wounds a severed part shows ✅
- [x] Skeleton model on the same joints, fitted inside the male body (`skeleton.py`) ✅
- [x] `CharacterModel` loads a .glb, binds it to the game's joints, cuts a rigid copy per segment for gibs and ragdolls ✅
- [x] The old SDF cop model removed ✅

### [x] S137 · Outfit models ✅
> needs: S136 | size: L | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=1`
- [x] Garment kit `tools/models/clothes.py`, fitted by slicing the body ✅
  - [x] Shirts and jackets: long, short or no sleeves; crew, collar or high neck; tucked or over the trousers; open front ✅
  - [x] Trousers and shorts with an optional belt ✅
  - [x] Shoes, sneakers, boots ✅
  - [x] Headgear: police cap, hard hat, helmet, fire helmet, nurse's cap ✅
- [x] One continuous surface per garment: sleeves out of the armhole, legs out of the seat, no break at any joint ✅
- [x] Helper bones turning half as far as each limb joint, so cloth bends without pinching ✅
- [x] Pieces cut below each joint, closed by wounds; piece ids in the .glb's second UV channel ✅
- [x] Nine outfits on the male and the female body (18 models), plain colours, worn by every walking zombie ✅
- [x] Sex picked from the id per outfit (`Characters.FEMALE_SHARE`) ✅
- [x] Tools: `outfits.py --sketch` (posed previews without Blender), `--folds`, `--outfit-rack`, `--rack-sever` ✅

### [ ] S138 · Bite variants
> needs: S137 | size: L | test: `tests/test_bite_variants.gd` | see: `python tools/models/outfits.py --bites nurse --f`
- Agent: Opus 5.5 at effort max. Geometry-heavy work with many look-and-fix rounds; it needs the whole pipeline (body, skeleton, clothes, rig, piece cuts) in its head at once. Plan first, then build one bite end to end before the other nine.
- [ ] Optimized variant producer in `tools/models/`: from one outfit and body, many variants that share what they can
  - [ ] Clothes swaps per variant (sleeve length, open or closed, hat or none, colour sets)
  - [ ] Variants picked from the zombie id, the same on every peer; the wire unchanged
  - [ ] Budget: triangles and texture memory per variant kept close to the plain model, loading stays before the first spawn
- [ ] Ten bites, each a named region torn out of flesh and clothes together, e.g.
  - [ ] Left or right side of the abdomen, left or right lower ribs, upper chest, shoulder, upper arm, forearm, thigh, calf, neck and jaw
  - [ ] The hole cuts the body and every garment over it, with a torn ragged edge (not a clean cut) and blood-dark rims
  - [ ] Only that region's bones show under it (a few ribs, the radius and ulna, a length of femur, a piece of spine), never the whole skeleton model
  - [ ] Inside the hole: wound flesh, the bone section, depth, so no see-through; the piece it belongs to stays closed for gibs
- [ ] Bites survive the existing rules: helpers bend them, they come off with their piece, stumps still close
- [ ] Contact sheet of every bone, clothes and body variant of the female nurse in one isometric picture, shown in chat when done

### [ ] S139 · Outfit details and special bodies
> needs: S137 | size: L | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=2`
- [ ] Details painted or modelled on the outfits: prints, badges, pockets, hi-vis stripes, ties
- [ ] Skirts and dresses
- [ ] Blood that varies per zombie on a model
- [ ] Special zombies built on the same pipeline, not on the round body
  - [ ] Bloater: swollen torso and neck, split shirt, pale green skin, pulsing belly
  - [ ] Spitter: long neck, distended jaw, burnt chest, thin limbs
  - [ ] Brute: a head taller, huge arms, small head, firefighter or riot gear fused on
  - [ ] Screamer: gaunt, torn hospital gown, jaw unhinged, hands clawing its own head
  - [ ] Crawler: torn trousers, entrails dragging
- [ ] Survivor models by player slot: four distinct looks with living faces, deterministic

### [ ] S071 · Zombie animation pass
> needs: S070 | size: L | test: `tests/test_rig.gd` | see: `--host --demo --shot-at=1,2,3`
- [ ] Idle variety per zombie id: sway, head twitch, jaw working, one arm hanging dead, sniffing the air
- [ ] Walk variety: limp, drag one foot, hunch, arms forward; chosen by id so peers agree
- [ ] Turn in place before walking, head leads the turn, eyes on the target
- [ ] Hit reactions by part and direction
  - [ ] Head snaps back, shoulder is thrown round, gut shot folds the torso
  - [ ] Leg hit: stumble on that side, a knee touches the ground
  - [ ] Heavy calibres spin or knock down; a knocked-down zombie rolls over and gets up in stages
- [ ] Attack variety: two-hand grab, wide swipe, lunge bite, each with wind-up, strike and recovery
- [ ] Losing an arm mid-attack: the swing continues with the stump and sprays
- [ ] Losing a leg: topple sideways, then the existing lying states
- [ ] Runner: head-down sprint with arms pumping wrong, skids on turns
- [ ] Leaper: all-fours scuttle, coil with the back arched, land in a roll
- [ ] Secondary motion: head and arm lag on stops, jaw and fingers always moving

### [ ] S072 · Senses and ambient zombies
> needs: S020, S071 | size: L | test: `tests/test_zombie_senses.gd`
- [ ] States before CHASE: DORMANT (standing still, lying, slumped in a car), FEEDING (kneeling on a corpse), WANDER
- [ ] Sight cone and range, shorter in the dark, widened by a flashlight shining on them
- [ ] Hearing from the noise system
- [ ] Alert: head snaps up, a scream that wakes others within a radius, then the chase
- [ ] Feeding animation: kneel, tear, head jerks up with a strip, blood on the mouth
- [ ] Trapped ones: behind glass slapping it, seat-belted in cars, under a gate reaching out
- [ ] Banging on a closed door in rhythm, the door shakes
- [ ] Sneaking past is possible: crouch, no light, suppressed guns

### [ ] S073 · Crowd movement
> needs: S052 | size: M | test: `tests/test_crowd.gd`
- [ ] Separation steering so a horde spreads across the street instead of stacking
- [ ] Lanes: fast ones overtake on the outside
- [ ] Funnel at doors and gaps: pressure builds, the ones in front are pushed through
- [ ] Shoving reactions: a staggered zombie bumps its neighbours into a stumble
- [ ] Tripping over corpses and crawlers at a seeded chance, pinned in tests
- [ ] Host tick cost at the zombie cap stays in budget (S009)

### [ ] S074 · Climbing and vaulting
> needs: S071, S073 | size: L | test: `tests/test_zombie_climb.gd` | see: `--host --demo --climb`
- [ ] Nav links typed VAULT (waist high), CLIMB (up to a floor), DROP
- [ ] Vault animation: hands slap the top, belly over, tumble down the other side, get up
- [ ] Climb animation: jump, grab the edge, feet scrabble, pull up; fingers show on the ledge first
- [ ] Drop: fall, heavy landing, a broken ankle limp at a seeded chance
- [ ] Windows: head and arms through, drag the body over the sill, glass tears at them
- [ ] Shot while climbing: falls back onto the ones below
- [ ] Cars are vaulted over, fences climbed, barricades clawed at first

### [ ] S075 · Crawler
> needs: S071 | size: S | test: `tests/test_zombie_crawler.gd`
- [ ] Spawns legless: under cars, in stairwells, under beds
- [ ] Silent until close, grabs an ankle: the player is slowed until it is shoved or shot
- [ ] Hard to see: low, in the dark, flashlights help

### [ ] S076 · Bloater
> needs: S070, S004 | size: M | test: `tests/test_zombie_bloater.gd` | see: `--zombie-rack=1`
- [ ] Slow waddle, gurgling
- [ ] Death or close contact: bursts
  - [ ] Belly swells for 0.4 s first as a warning
  - [ ] Wet explosion: chunks, a ring of bile on the floor, a green mist cloud that lingers
  - [ ] Damage and a knock-back in the radius, bile on the screen of players caught
- [ ] Bile puddle draws other zombies to it
- [ ] Kill it at range, or use it against a horde

### [ ] S077 · Spitter
> needs: S070, S004 | size: M | test: `tests/test_zombie_spitter.gd`
- [ ] Keeps distance, climbs to high ground, strafes between spits
- [ ] Spit: rears the head back with a throat bulge, then a glowing green arc with a drip trail
- [ ] Lands as an acid pool: bubbles, steam wisps, eats HP while stood in, fades in seconds
- [ ] Host simulates the arc; clients get start, velocity and time
- [ ] Dies easily, flees when approached

### [ ] S078 · Brute
> needs: S070, S071 | size: L | test: `tests/test_zombie_brute.gd`
- [ ] Armour plates on torso and arms as separate parts with their own HP; plates crack, then fly off, showing flesh
- [ ] Charge: lowers the shoulder, paws the ground, a straight run that throws players and zombies aside and ends in a stumble if it misses
- [ ] Smashes doors and barricades in one hit, flips small wrecks aside
- [ ] Ground slam at close range with a dust ring and a camera shake
- [ ] Weak spot: the head and the back after a missed charge
- [ ] At most one or two alive (director budget)

### [ ] S079 · Screamer
> needs: S070, S028 | size: M | test: `tests/test_zombie_screamer.gd`
- [ ] On sight of a player it stands still, arches back and screams for three seconds
- [ ] The scream is visible: ripple rings of distorted air, nearby glass rattles, the player's view trembles
- [ ] Finished scream calls a horde through the director; killing it mid-scream stops it
- [ ] Runs away between screams

### [ ] S080 · Armoured dead
> needs: S070 | size: M | test: `tests/test_zombie_armour.gd`
- [ ] Soldier: helmet stops pistol and SMG headshots until knocked off, vest halves torso damage
- [ ] Riot cop: visor helmet, limb pads, sometimes still holding a shield in front
- [ ] Firefighter: helmet and thick coat, immune to fire
- [ ] Helmets are parts: a hit knocks them off with a clang and they roll away
- [ ] Bullets on armour spark and ricochet instead of bleeding
- [ ] Weighted by place: soldiers at the Batalhão, cops at checkpoints

### [ ] S081 · Death and ragdolls
> needs: S071 | size: M | test: `tests/test_ragdoll.gd` | see: `--host --demo --bot --shot-at=2,4`
- [ ] Death animation before the ragdoll by cause: headshot drop, torso crumple to the knees, run-death tumble that carries momentum
- [ ] Ragdoll impulse from the killing shot's direction and calibre; shotguns lift them off the ground
- [ ] Twitching: a hand or leg jerks for a few seconds on some corpses
- [ ] Corpses settle, then become static corpses as now; caps unchanged
- [ ] Piles: corpses stack at choke points without jitter
- [ ] Explosions throw ragdolls and loose limbs

---

## P08 · Sound

### [ ] S082 · Zombie voices
> needs: S005 | size: L | test: `tests/test_zombie_sounds.gd`
- [ ] Synthesised from formant-filtered saw and noise, a voice seeded per zombie id (pitch, rasp, size)
  - [ ] Walker: low groans, wet breathing
  - [ ] Runner: rising screech when it spots someone, panting
  - [ ] Leaper: clicking snarl, a shriek in the air
  - [ ] Specials: bloater gurgle, spitter retch, brute roar, screamer's scream
- [ ] States have sounds: alert, attack grunt, hit yelp, death rattle per type
- [ ] Horde bed: beyond a count, single voices are replaced by one crowd roar that swells with their number and nearness
- [ ] Voice cap respected, nearest first

### [ ] S083 · Bodies and footsteps
> needs: S005, S032 | size: M | test: `tests/test_footsteps.gd`
- [ ] Footsteps by surface for players: concrete, asphalt, setts, pavers, grass, dirt, metal stair, tile, wood, water, glass shards
- [ ] Walk, sprint, crouch, land, each timed with the camera bob and the remote rig's feet
- [ ] Gear rattle while sprinting, cloth while turning
- [ ] Breathing: heavy after sprint, ragged when hurt, held while aiming a sniper
- [ ] Low-HP heartbeat that speeds up
- [ ] Zombie feet: shuffle, runner slaps, horde rumble
- [ ] Gore sounds: limb tear, bone crack, squelch, splash of a blood burst, a head burst pop

### [ ] S084 · World sounds
> needs: S005 | size: M | test: `tests/test_world_sounds.gd`
- [ ] Doors: handle, creak open, slam, locked rattle, splinter and break
- [ ] Barricade: hammer knocks, plank crack, plank snap
- [ ] Lootbox: latch, lid creak, rummage; pickups: ammo clink, medkit zip, key jingle
- [ ] Glass: crack, shatter, shards falling, crunch underfoot
- [ ] Vehicles: car alarm, hazard tick, a horn stuck on, engine ticking as it cools
- [ ] UI: hover tick, click, back, error, objective chime, wave horn
- [ ] Generators, buzzing tube lights, a swinging sign creaking

### [ ] S085 · Ambience
> needs: S005 | size: M | test: `tests/test_ambience.gd`
- [ ] Bed per place, crossfaded by zones in map data
  - [ ] Streets: wind between buildings, far sirens, a dog, distant gunfire and screams at random times
  - [ ] Terminal: wide hall reverb, dripping, a loose metal sheet
  - [ ] Hospital: hum, alarm beeps down a corridor, a monitor flatline
  - [ ] Forest: insects, frogs, night birds, leaves, twigs snapping somewhere
  - [ ] Riverside: water, palms rattling
  - [ ] Summit: strong wind, mast cables singing
- [ ] One-shots placed in the world, not in the player's head
- [ ] Quiet that means something: the bed thins out before a horde

### [ ] S086 · Space and occlusion
> needs: S085 | size: M | test: `tests/test_audio_space.gd`
- [ ] Reverb zones from map data: small room, corridor, hall, street canyon, open
- [ ] Occlusion: a wall between source and listener low-passes and quietens (one ray per voice, spread across frames)
- [ ] Sounds through doors change when the door opens
- [ ] Teammates' shots, steps and reloads are positional
- [ ] Vertical cues in buildings: floor above is muffled thumps

### [ ] S087 · Mission audio
> needs: S005, S024 | size: M | test: `tests/test_mission_sounds.gd`
- [ ] Horde warning: an air-raid siren winding up across the city, then the roar
- [ ] Helicopter: rotor thump with distance (far: low pulse, near: full chop and turbine whine), doppler on the pass, wash noise underneath
- [ ] Radio voice as filtered noise bursts and beeps with subtitles on the HUD
- [ ] Extraction countdown beeps, success swell, failure drone
- [ ] Checkpoint and objective stingers

### [ ] S088 · Procedural music
> needs: S005, S028 | size: L | test: `tests/test_music.gd`
- [ ] A small sequencer in code: drone, pulse, percussion, a detuned piano-like pluck, all synthesised
- [ ] Layers follow the director: CALM drone only, BUILD adds a pulse, PEAK adds drums and a rising tone, RELAX thins out
- [ ] Per-mission key and tempo
- [ ] Stingers: special zombie spotted, teammate down, last player standing
- [ ] Menu theme
- [ ] Music volume setting, ducked under gunfire

### [ ] S089 · The mix
> needs: S033, S082, S085 | size: M | test: `tests/test_mix.gd`
- [ ] Ducking: guns duck ambience and music, explosions duck everything briefly
- [ ] Explosion near the player: tinnitus tone and a low-pass that recover over seconds
- [ ] Low HP and downed: muffled world, loud heart and breath
- [ ] Limiter on Master, no clipping with a full horde and four guns
- [ ] Loudness per category balanced by ear with a checklist in the step's commit

---

## P09 · Arsenal

### [ ] S090 · Melee weapons: knife and bat
> needs: S013, S019 | size: L | test: `tests/test_melee.gd` | see: `--weapon=knife --pose=swing`
- [ ] Melee entries in `Weapons.DEFS`: reach, arc, swing time, recovery, damage, stagger, sever chance, noise, durability
- [ ] Host resolves a swing as an arc sweep at the hit frame, part hit decided by height
- [ ] Viewmodel swings as blended poses: wind-up, strike with overshoot, follow-through, return; a three-swing combo alternating sides
- [ ] Hit stop: 40 ms freeze of the viewmodel and a camera nudge on contact
- [ ] Combat knife: fast stabs and slashes, quiet, a held stab to the head from behind kills a dormant zombie
- [ ] Baseball bat: two-hand swings, knocks zombies down, dents and blood build up on the bat mesh
- [ ] Blood on the weapon and hands that fades over time
- [ ] Models in `guns.gd` style, shown in the rack

### [ ] S091 · Blades: axe, machete, katana
> needs: S090 | size: M | test: `tests/test_melee_blades.gd`
- [ ] Sever rules: blades cut the limb the arc passes through, with a clean stump
- [ ] Fire axe: slow overhead chop, sticks in the body for a beat and is wrenched out, breaks doors
- [ ] Machete: fast diagonal cuts, best limb sever per second
- [ ] Katana: rare loot, fast wide arcs, decapitation with a held strike, a blood arc flung off the blade after each cut
- [ ] Blade trails: a faint streak along the edge during the strike

### [ ] S092 · Blunt and junk: crowbar, sledgehammer, the rest
> needs: S090, S054 | size: M | test: `tests/test_melee_blunt.gd`
- [ ] Crowbar: pries locked doors, vaults and elevator doors with a held use and a pry animation
- [ ] Sledgehammer: very slow, huge stagger in an arc, bursts heads, breaks doors and weak walls marked in map data
- [ ] Junk with durability that breaks in the hand: shovel, pipe, frying pan (with a ringing hit)
- [ ] Breaking: the head flies off, the player is left with a stub for one weak hit

### [ ] S093 · Throwables and the frag grenade
> needs: S014, S004, S020 | size: L | test: `tests/test_grenade.gd` | see: `--host --demo --throw=frag --shot-at=2,2.1,2.3`
- [ ] Throw: hold to cook and show an arc preview, release to throw; underhand roll with the alternate key
- [ ] Viewmodel: pull the pin with the off hand, arm back, release, hand lingers open
- [ ] Host simulates the bounce; clients see the same grenade with a spinning lever flying off
- [ ] Explosion
  - [ ] One-frame white flash and a pooled light
  - [ ] Fast fireball that turns to black smoke rolling upward
  - [ ] Shock ring on the ground, dust kicked from every nearby surface, debris chunks with trails
  - [ ] Scorch decal, lingering smoke for 8 s
  - [ ] Camera shake by distance, tinnitus hook for S089
- [ ] Damage falls off with distance and is blocked by walls; limbs fly
- [ ] Friendly damage by difficulty
- [ ] `on_explosion` hook

### [ ] S094 · Fire
> needs: S004, S070 | size: L | test: `tests/test_fire.gd` | see: `--host --demo --fire --shot-at=1,3,6`
- [ ] Fire as a host object: area, fuel time, spreads to flammable surface kinds and to zombies that touch it
- [ ] Flame look: layered additive billboards rising and curling, hot core white-yellow, orange body, red tips, sparks floating up, black smoke above
- [ ] Light: one flickering pooled omni per fire cluster, colour wandering between orange and yellow
- [ ] Heat shimmer above the flames (screen distortion on HIGH tier only)
- [ ] Burning zombies: flames attached to body parts, they keep coming, skin chars to black over seconds, they collapse smoking
- [ ] Burning players: screen edge flames, damage over time, sprinting spreads it less than standing still
- [ ] Aftermath: scorched ground decal, embers glowing and fading, charred corpses
- [ ] Capped: fires merge, the oldest die first

### [ ] S095 · Molotov
> needs: S093, S094 | size: S | test: `tests/test_molotov.gd`
- [ ] Bottle with a lit rag: the flame trails in the hand and in flight
- [ ] Breaks on impact: glass burst, a splash of fire that runs outward along the ground and up walls a little
- [ ] Burns for seconds as an area denial, blocks a doorway
- [ ] Lights anything flammable in the splash

### [ ] S096 · Flashbang, noise lure, flare
> needs: S093, S072 | size: M | test: `tests/test_tactical_throwables.gd`
- [ ] Flashbang: zombies in sight of it stagger blind for seconds; players looking at it get a white screen that fades through an after-image, and ringing
- [ ] Noise lure (an alarm clock taped to a pipe): rings, zombies gather on it, then it pops
- [ ] Road flare: red sputtering light with drifting sparks and red smoke, zombies avoid it a little, marks the extraction
- [ ] Each a pickup and a wheel slot

### [ ] S097 · Pistols
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] Desert Eagle: 7 rounds, heavy kick that lifts the whole view, big flash
- [ ] Revolver: 6 shots, cylinder turns per shot, reload by swinging it out and dropping six casings at once
- [ ] Glock 18: automatic, climbs fast
- [ ] Flare gun: one shot, a burning red ball that arcs, sticks, lights the area and sets fire (S094)
- [ ] Each: `DEFS` entry, model builder, handling poses, voice, balance sheet row

### [ ] S098 · Submachine guns
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] MP5: accurate, low recoil, the slap of the charging handle on reload
- [ ] Mac-10: very fast, wild spread
- [ ] Uzi: open bolt, top charging knob
- [ ] Vector: very fast, small magazine, low muzzle rise
- [ ] MP7 suppressed: quiet, low noise value
- [ ] Each: `DEFS` entry, model builder, handling poses, voice, balance sheet row

### [ ] S099 · Rifles
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] Fire modes in `weapon_state.gd`: auto, semi, three-round burst, with a selector key and click
- [ ] M4A1, SCAR-H, FAL, G36, AUG (bullpup magazine behind the grip)
- [ ] A low-tier carbine as the first rifle players find
- [ ] Each: `DEFS` entry, model builder, handling poses, voice, balance sheet row

### [ ] S100 · Shotguns
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] Double-barrel: two shots, both at once on the alternate trigger, break-open reload with two hulls popping out
- [ ] Sawn-off: sidearm slot, huge spread
- [ ] Mossberg pump
- [ ] Lever-action: lever loop swing between shots
- [ ] Slug rounds as a second ammo type for shotguns
- [ ] Each: `DEFS` entry, model builder, handling poses, voice, balance sheet row

### [ ] S101 · Marksman rifles and penetration
> needs: S032 | size: M | test: `tests/test_penetration.gd`
- [ ] Penetration on the host: a bullet passes through zombies and thin surfaces by calibre, losing damage each time
- [ ] Exit effects on the far side of a surface and of a body
- [ ] M14 EBR, lever-action hunting rifle
- [ ] Barrett .50: goes through a line of zombies, dust kicked up around the shooter, heavy view recoil, slow to aim
- [ ] Scope: lens glint seen by others, sway while standing, hold breath to steady (drains stamina)

### [ ] S102 · Machine guns
> needs: S063 | size: M | test: `tests/test_weapons.gd`
- [ ] M249 and PKM: belt of 100, slow aim, slow sprint, long reload with the feed cover lifted and the belt laid in
- [ ] Belt visibly shortens on the viewmodel; links and casings eject
- [ ] Barrel heat glow after long bursts
- [ ] Minigun: rare, spin-up before firing, a rope of tracers, the player walks slowly, barrels keep spinning down
- [ ] Deployed on cover when crouched behind it: tighter spread

### [ ] S103 · Launchers and destruction
> needs: S093, S053 | size: L | test: `tests/test_launchers.gd`
- [ ] Grenade launcher: break-open single shot, arcing round, thump
- [ ] RPG: rocket with a smoke trail and a lit motor, back-blast cone behind the shooter that hurts
- [ ] Destructible pieces marked in map data: doors, plank walls, marked wall panels blow out into rubble with rebar, leaving a hole that is a new nav link
- [ ] Cars hit by explosives burn, then explode once
- [ ] Rounds are rare loot

### [ ] S104 · Flamethrower and crossbow
> needs: S094 | size: M | test: `tests/test_special_weapons.gd`
- [ ] Flamethrower: a stream of fire that bends when the player turns, lights surfaces and zombies, pilot flame at the nozzle, fuel tank gauge, short range
- [ ] Crossbow: silent, bolt arcs, pins a zombie's limb or head to the wall behind it, bolts are retrieved from bodies and walls
- [ ] Reload: crank or lever draw with the string visibly bending the limbs

### [ ] S105 · Attachments
> needs: S099 | size: L | test: `tests/test_attachments.gd` | see: `--gun-rack --attach=all`
- [ ] Mount points per gun in the model builders: muzzle, top rail, under-barrel, side rail, magazine
- [ ] Suppressor: quieter noise value, no flash, slightly lower damage
- [ ] Red dot: a glowing dot on a glass pane that stays on target (parallax), replaces the iron sight pose
- [ ] Scope 4x: scoped view with a reticle
- [ ] Extended magazine: longer mesh, more rounds, slower reload
- [ ] Laser: a thin beam visible in fog and smoke, a dot on surfaces, tighter hip spread
- [ ] Grip: less recoil
- [ ] Weapon flashlight: shares S107
- [ ] Found as loot, fitted from the wheel with a short fitting animation; sent to others as a bit mask beside the weapon id

### [ ] S106 · Loot and rarity
> needs: S012, S014 | size: M | test: `tests/test_loot.gd`
- [ ] Loot tables in `Config` by container kind and place: lootbox, locker, ammo crate, medical cabinet, car boot, corpse
- [ ] Rarity tiers with a colour and a glow on the pickup
- [ ] Per-mission seeded rolls so every peer and every retry with the same seed agrees
- [ ] Lootbox opening: lid springs, light spills out, items rise and settle
- [ ] Searching takes time for big containers, with a progress ring
- [ ] Placement rule: good loot is off the main route

---

## P10 · Light, weather and atmosphere

### [ ] S107 · Flashlight
> needs: S004 | size: M | test: `tests/test_flashlight.gd` | see: `--host --time=night --flashlight --shot-at=2`
- [ ] Toggle key, state in the player snapshot's action bits
- [ ] Spot light with a soft-edged cone and a bright hot spot (a cookie made in code), slightly warm
- [ ] It lags the view a little and bobs with the walk; it swings down while sprinting and reloading
- [ ] Shadows only for the local player's own light; teammates' lights are shadowless
- [ ] Beam visible in fog, dust and smoke as a faint cone
- [ ] Battery: dims and flickers when low, recharges off; a tap on the light when it flickers
- [ ] Eye shine: zombies' eyes reflect in the beam before the body is seen
- [ ] Shining it on dormant zombies wakes them (S072)

### [ ] S108 · Lamps
> needs: S004 | size: L | test: `tests/test_lamps.gd` | see: `--mission=hospital --floor=3 --shot-at=1,2,3`
- [ ] Lamp manager: of all shadow-capable lamps, only the two most important to the local player cast shadows, switching with a fade so it never pops
- [ ] Lamp kinds with behaviours
  - [ ] Steady
  - [ ] Flicker: a seeded pattern of stutters and blackouts, the tube's emission and its light in step, a buzz
  - [ ] Dying: long dim, a bright spasm, dead
  - [ ] Swinging: hung by a wire, pushed by explosions and passing brutes, shadows sweep the room
  - [ ] Emergency beacon: red light rotating, sweeping walls
  - [ ] Strobe: fire alarm white flashes
  - [ ] Sodium street lamp: orange pool with a hazy cone in fog, moths round it
  - [ ] Neon and shop signs: letters that buzz and drop out one by one
  - [ ] TV glow: blue flicker from a window
- [ ] Lamps can be shot out: glass burst, sparks, dark
- [ ] Power events: a whole building or street going dark or coming on in a rolling sequence
- [ ] Same pattern on every peer (seeded by lamp id and match time)

### [ ] S109 · Fog, dust and light shafts
> needs: S050, S108 | size: M | test: `tests/test_atmosphere.gd` | see: `--mission=terminal --time=night --shot-at=2`
- [ ] Ground fog by place: thick on the river and in the forest, thin in the streets, none inside
- [ ] Volumetric fog on HIGH tier with lamps and the flashlight scattering in it; a cheap layered-card version below
- [ ] Interiors: dust motes drifting in lit volumes, stirred by movement and gunfire
- [ ] Light shafts through windows, skylights and holes in roofs, with dust in them
- [ ] Smoke from fires and grenades hangs, drifts with the wind and is lit by nearby lights
- [ ] Breath vapour from players on the summit at night

### [ ] S110 · Rain and wet streets
> needs: S050, S041 | size: L | test: `tests/test_rain.gd` | see: `--weather=rain --time=night --shot-at=2`
- [ ] Weather per mission in map data, sent in `welcome`: clear, drizzle, rain, storm
- [ ] Rain: streaks in a volume that follows the camera, slanted by wind, never indoors or under canopies (roof test)
- [ ] Splashes: small rings and crowns on the ground near the camera, denser on roads
- [ ] Wet look as in `terminal1.png`: darker, glossier asphalt and setts, lamps and headlights stretched as reflections, puddles in the road's low spots that ripple
- [ ] Water running in the gutters, dripping from canopy edges and awnings, pouring from broken downpipes
- [ ] Storm: lightning that lights the whole scene white-blue for two frames with hard shadows, thunder after a delay by distance
- [ ] Rain on the gun and on the lens: drops that streak when the player moves
- [ ] Gameplay: rain shortens zombie hearing and sight, footsteps splash

### [ ] S111 · Post-processing and grade
> needs: S050 | size: M | test: `tests/test_post.gd` | see: `tools\shots.ps1`
- [ ] Tonemap and exposure per time of day; eyes adapt when leaving a dark building into daylight
- [ ] Glow on emissive things: muzzle flashes, lamps, fire, signs
- [ ] Colour grade per mission: cold blue-green hospital, sodium orange streets, grey-green forest, bleached dusk at the Batalhão
- [ ] Film grain and a soft vignette, both with settings
- [ ] Ambient occlusion and screen-space reflections on HIGH only
- [ ] Sharpening after upscale on LOW
- [ ] Depth of field only in menus, the death camera and the end screen

### [ ] S112 · Gore 2
> needs: S032, S081 | size: L | test: `tests/test_gore.gd` | see: `--host --demo --bot --bot-aim=head --shot-at=2,3,4`
- [ ] Exit wounds: a bigger burst and a spray on the wall behind in the bullet's direction
- [ ] Head: jaw, top or half can go separately; a headshot leaves a stump with a spurting pulse that weakens
- [ ] Blood in the world
  - [ ] Wall splatter with drips that run down over seconds
  - [ ] Pools that grow under corpses and follow the floor's slope
  - [ ] Footprints: players and zombies who step in blood leave fading prints
  - [ ] Drag smears behind crawlers
  - [ ] Mist that hangs for a moment after a shotgun hit
- [ ] Viewmodel: blood spatters on the gun and hands at close range, wiped during the inspect animation
- [ ] Everything capped and pooled as now, tiered

### [ ] S113 · Glass and breakables
> needs: S032 | size: M | test: `tests/test_breakables.gd`
- [ ] Windows on POI buildings: first shot cracks (star decal), later shots or a body break the pane into falling shards
- [ ] Shards on the floor crunch and make noise
- [ ] Car windows and windscreens, bus windows, shop glass, bottles, monitors, tube lights
- [ ] Wooden crates and pallets, cardboard boxes, plaster board that shows studs
- [ ] State as a bit per breakable in `welcome`, a `world_fx` event when it breaks

### [ ] S114 · Explosive props and car alarms
> needs: S093, S094 | size: M | test: `tests/test_hazards.gd`
- [ ] Red fuel barrel, blue gas cylinder (botijão): hiss and a flame jet when shot, then explode, the cylinder rockets off
- [ ] Petrol trail from a shot fuel tank that can be lit
- [ ] Car alarm: shooting or bumping some cars sets off lights and a siren, a loud noise source until it is shot or dies
- [ ] Electrical box: sparks, shocks zombies in a puddle (uses S110 when raining)
- [ ] Fire extinguisher: white cloud that puts out fire and blinds for a moment

### [ ] S115 · Ambient life
> needs: S048 | size: M | test: `tests/test_ambient_life.gd`
- [ ] Crows on wires and corpses that take off when a player comes near or a shot is fired
- [ ] Vultures circling over the Batalhão, bats round the lamps on the hill road
- [ ] Rats running along walls into holes, cockroaches scattering from light indoors
- [ ] Flies as a small buzzing cloud over old corpses
- [ ] Moths round lamps, fireflies in the forest
- [ ] Paper, plastic bags and leaves blown down the street in gusts
- [ ] Hanging things that swing: signs, cables, a traffic light, curtains through broken windows
- [ ] All local and cosmetic, none on the wire

### [ ] S116 · Screen effects
> needs: S037 | size: M | test: `tests/test_screen_fx.gd`
- [ ] One layer that mixes them and caps the total
  - [ ] Blood drops and smears
  - [ ] Bile from a bloater: green, blurs, slides down
  - [ ] Acid: edges sizzle
  - [ ] Rain and splash drops
  - [ ] Dirt and dust after an explosion
  - [ ] Flash blindness with an after-image
  - [ ] Concussion: double vision that swims back together
  - [ ] Heat shimmer near fire
  - [ ] Cracked glass corner when HP is very low
- [ ] Each has a setting to tone it down

### [ ] S117 · Searchlights
> needs: S024, S109 | size: S | test: `tests/test_searchlight.gd`
- [ ] Helicopter searchlight: a hard white cone through fog and rain, a moving pool on the ground that hunts for the players, then locks on the landing zone
- [ ] Zombies in the pool are lit sharply with long shadows (one of the two shadow slots while it is on)
- [ ] The Batalhão tower's searchlight on a slow sweep
- [ ] Lens flare when looking into it

### [ ] S118 · Graphics tiers
> needs: S111, S009 | size: M | test: `tests/test_tiers.gd`
- [ ] LOW / MEDIUM / HIGH decide: fx counts, decal life, fog kind, reflections, shadow size, vegetation density, draw distance, post effects
- [ ] One place (`Config.TIER_*`) holds every tier number
- [ ] Auto-pick on first run from a five-second benchmark
- [ ] The budget test runs per tier
- [ ] LOW holds 144 fps on the target laptop with a full horde, checked with `tools\perf.ps1`

---

## P11 · Menus and LAN

### [ ] S119 · Settings menu
> needs: S006 | size: M | test: `tests/test_menu_settings.gd` | see: `--menu=settings --screenshot`
- [ ] Tabs: Game, Controls, Video, Audio
- [ ] Sliders with live preview: sensitivity, FOV, volumes, HUD scale, shake, gore amount
- [ ] Key rebinding: click, press a key, conflicts shown, reset to default
- [ ] Graphics tier, fps cap, vsync, window mode, show draws
- [ ] Same panel reachable from the main menu and the pause menu
- [ ] Menu motion: panels slide and fade, the hovered row glows, values tick

### [ ] S120 · Pause menu
> needs: S119 | size: S | test: `tests/test_pause.gd`
- [ ] Resume, Settings, Leave match
- [ ] The world keeps running in multiplayer; the player is marked as paused over their head
- [ ] Solo offline pauses the world
- [ ] Background blurs and darkens, the game sound is low-passed

### [ ] S121 · Mission select
> needs: S026, S027 | size: M | test: `tests/test_menu.gd` | see: `--mission=hospital --screenshot`
- [ ] On the city map: the picked pin opens a card with the brief, kind, difficulty skulls, best time and best score
- [ ] Difficulty picker
- [ ] The route or area of the mission drawn on the map when picked, camera eases toward it
- [ ] Pins pulse; completed missions get a tick, locked ones a padlock (S127)
- [ ] Time of day and weather shown as icons

### [ ] S122 · Lobby
> needs: S121 | size: L | test: `tests/test_lobby.gd` | see: `tools\play2.ps1`
- [ ] Host opens a lobby instead of starting at once; LAN discovery lists it with mission, players and difficulty
- [ ] Player list with names, ready ticks, ping
- [ ] Host picks mission and difficulty, everyone sees the map move
- [ ] Survivor look picker (the four outfits, colour)
- [ ] Start when all are ready, or host forces; a countdown
- [ ] After a mission everyone returns to the lobby together
- [ ] Join by IP stays as a fallback

### [ ] S123 · Loading screen
> needs: S051 | size: S | test: `tests/test_loading.gd`
- [ ] Mission title, the POI's sketch, a tip that changes
- [ ] The map builds across frames with a progress bar instead of one long freeze
- [ ] Everyone starts together when the slowest peer is ready
- [ ] Fade from the loading screen into the first view

### [ ] S124 · Pings, chat, scoreboard
> needs: S036 | size: M | test: `tests/test_social.gd`
- [ ] Ping key: a marker where the player looks, contextual (go here, zombie, loot, special spotted), with a sound and the player's colour
- [ ] Text chat with a short history, usable while dead
- [ ] Scoreboard on a held key: kills, headshots, revives, ping
- [ ] Kill feed with weapon icons, headshot and sever marks
- [ ] Emote wheel with a few hand signals on the rig (point, wave, stop)

### [ ] S125 · Joining late and leaving
> needs: S021, S122 | size: M | test: `tests/test_late_join.gd` | see: `tools\play2.ps1`
- [ ] A late joiner gets everything in `welcome`: mission state, breakables, barricades, fires, dropped guns, inventory defaults
- [ ] They spawn at the last checkpoint or beside a teammate out of sight of zombies
- [ ] A leaving player's body drops their backpack; the horde scales down
- [ ] Host quits: clients get a clear message and return to the menu
- [ ] Short network hiccups: the client keeps going and catches up without a snap
- [ ] Reconnect within a minute gives the player their state back

### [ ] S126 · Net stress
> needs: S070, S125 | size: M | test: `tests/test_net_stress.gd`
- [ ] Headless harness: one host and seven fake clients on localhost, a full horde, 60 s
- [ ] Asserts: every packet under the limit, bytes per second per client under a budget, no reliable-queue growth
- [ ] Simulated loss and delay: the game stays playable at 5 % loss and 80 ms
- [ ] Remote zombies and players stay smooth (interpolation checked numerically)
- [ ] Player cap decided from the results and written in `Config`

---

## P12 · Beyond the missions

### [ ] S127 · Progression
> needs: S026, S106 | size: M | test: `tests/test_progression.gd`
- [ ] `user://profile.cfg`: missions done per difficulty, records, total kills, unlocked items
- [ ] Finishing missions unlocks the next ones and starting loadout options (a better sidearm, a melee weapon, an attachment)
- [ ] Each player's own unlocks apply to themself; the host's unlock the missions
- [ ] Challenges: finish the hospital with melee only, the Mirante without the flashlight, and the like
- [ ] A profile screen in the menu

### [ ] S128 · Daily modifiers
> needs: S027, S110 | size: S | test: `tests/test_modifiers.gd`
- [ ] Modifiers as small rule sets: all runners, low ammo, night only, thick fog, storm, no HUD, one life, exploding heads
- [ ] A daily pick seeded from the date, shown on the menu; the host can also pick by hand
- [ ] Sent in `welcome`

### [ ] S129 · Companion survivors
> needs: S038, S016 | size: L | test: `tests/test_companion.gd`
- [ ] AI teammates fill empty slots when the host wants them
- [ ] They follow, keep spacing, shoot what threatens, reload behind cover, revive and heal players
- [ ] They never take the last ammo or medkit, never block doorways
- [ ] Ping commands: go there, hold here, follow
- [ ] Built on the bot from S008, same rig and animations as players

### [ ] S130 · Vehicles
> needs: S057 | size: L | test: `tests/test_vehicle.gd`
- [ ] One drivable pickup truck for the terminal run as an optional route
- [ ] Host simulates it; the driver sends input; passengers ride in the bed and shoot
- [ ] Runs zombies down with ragdoll hits and blood on the bonnet, slows through crowds
- [ ] Fuel and damage: smoke, then fire, then it stops
- [ ] Engine noise draws everything (S020)
- [ ] Body roll, suspension bounce, headlights, brake lights, wheels that steer and spin

### [ ] S131 · Killcam and replays
> needs: S126 | size: L | test: `tests/test_replay.gd`
- [ ] The host records the snapshot stream and events of the last 15 s in a ring
- [ ] On a player's death or at the end: replay the final moments from a cinematic camera, slowed at the kill
- [ ] End screen highlight: the biggest multi-kill of the match
- [ ] Free camera and photo mode in solo: pause, fly, hide the HUD, save a PNG

---

## P13 · Ship it

### [ ] S132 · Balance pass
> needs: S007, S060, S062, S065, S068 | size: L | test: `tools\test.ps1 balance`
- [ ] Balance sheet reviewed gun by gun and zombie by zombie, every outlier fixed in `weapons.gd` and `Config`
- [ ] Each mission played by the bot on each difficulty: finish rates and times in a table in `references/balance.md`
- [ ] Ammo and healing economy per mission: found against spent
- [ ] Mission lengths in the target range (15 to 25 minutes)
- [ ] Notes from human playtests turned into numbers

### [ ] S133 · Performance pass
> needs: S118, S126 | size: L | test: `tests/test_budget.gd`
- [ ] Every mission inside its budget on every tier, measured at the worst moment (final wave, rain, fire, helicopter)
- [ ] Profiler findings fixed: merged meshes, MultiMesh where repeated, scripts off the hot path, pooled everything
- [ ] Host with eight players and a full horde keeps its tick rate
- [ ] No hitch above a frame when a horde spawns, a building appears or an effect first plays (warm-up at load)
- [ ] Memory steady over a 30-minute soak

### [ ] S134 · Windows build for friends
> needs: S122 | size: M | test: `tools\build.ps1` then run the exe with `--quit-after=5`
- [ ] `tools\build.ps1` exports a release folder and a zip, version stamped from git
- [ ] First run: asks for a name, picks a tier, shows the LAN address to tell friends
- [ ] Firewall prompt explained on the host screen; port in settings
- [ ] Version check on join (S070)
- [ ] `README.md`: how to host, how to join, controls, troubleshooting
- [ ] Crash log written to `user://` with the last hooks fired

### [ ] S135 · LAN night
> needs: S132, S133, S134 | size: M | test: whole suite | see: `tools\shots.ps1`
- [ ] A checklist played start to finish on two real machines: lobby, each of the five missions, a late join, a disconnect, a failure and a win
- [ ] Every rough edge found becomes a test and a fix, or a new step appended to this file
- [ ] Credits and a thank-you screen after the fifth mission
- [ ] `TODO.md`, `CLAUDE.md` and this file agree with the game
