# Make Alive — steps

The build order for everything in `TODO.md`, cut into steps one agent can finish in one session.
Finishing every step leaves a LAN co-op zombie extraction game set in a recognisable central Joinville.

## How to use this file

- **Pick:** the lowest-numbered step that is `[ ]` and whose `needs` are all `[x]`. One step per session. Exception: S140 and S141 (the element pipeline and its kit) go first, since most open steps wait on them.
- **Do:** follow `CLAUDE.md` (failing test first, numbers in `Config`, gameplay reactions in `hooks.gd`, host decides, gore is local, everything is code, no imported assets).
- **Elements:** a step that makes something people look at (a building part, a family of props, a vehicle, a plant, the hands, a gun) is an element step: it makes that one thing, or one small family that shares one design, and nothing else, and it iterates in rounds (see "Detail and iteration" below). A step that places finished elements (a street, a square, a POI) is an assembly step and models nothing new.
- **Prove:** the step's `test` passes in the whole suite, and the `see` command's screenshots were read and look right. A step with `rounds` also has every round written on its element's card, and its last review sheet shown in chat.
- **Close:** tick each feature done, tick the step when all are, commit. If the session runs out, tick what is done and leave the step open. Update `CLAUDE.md` ("Where things are", "Not built yet") and `TODO.md` when a step changes them.
- **Size:** S = under half a session, M = one session, L = one full session, stop at any ticked feature.

## Format (the mind map script reads this)

- `## Pnn · name` is a phase, `### [ ] Snnn · name` is a step, `- [ ]` is a feature, an indented `- [ ]` is a sub-feature. These are the map's nodes.
- A plain `- ` bullet is a spec note of the node above it (a leaf, or hidden in the map).
- A `> ` line under a step is its data: `needs` (step ids), `size`, `rounds` (how many look-and-fix rounds at least; such a step must have the features `Round 1` .. `Round N` and `Review`), `test`, `see`, separated by ` | `.
- Nothing else has meaning. Keep ids unique and never renumber a step, append new ones.

## Rules every step obeys

- **Real Joinville:** streets, sidewalks, river, squares and hill follow the references (`references/joinville.png`, the OpenStreetMap tiles `references/1.png` to `9.png`, the photos). Only the five POIs are real buildings with interiors. Every other building is a solid block with a believable facade and doors that do not open.
- **Budget:** 144 fps on a laptop. Two shadow-casting lamps. Every effect has a cap in `Config` and a pool. Watch "draws".
- **Network:** new effects travel as *what happened* (kind, position, direction, one argument), never as particles or physics. Zombie snapshots stay 13 bytes each unless the step says otherwise and the packet test still passes.
- **Looks are deterministic:** seeded from ids or the map's own RNG, never `randf`, so every peer sees the same city.
- **Animation:** poses are goals the rig eases toward (`Humanoid.Anim`, `_write_goal`) and viewmodel weights 0..1. No direct joint or pivot writes.

## Detail and iteration

- **The bar is the zombies, not the boxes.** Everything on screen is made to the level of the zombie bodies and outfits (S136, S137): low-poly and flat-shaded, but every form that catches light is modelled (chamfers, lips, frames, seams, bolts, hinges, handles), proportions are measured from references, and surfaces carry baked shading, wear, dirt and lettering. Plain boxes are a blockout, never a result. The gap today: the first-person hands are two boxes per arm, next to zombies with knuckles and nails.
- **One element, one step.** An agent given one well-bounded thing (the street signs) does it well; given "make the city detailed" it makes garbage. An element step makes one element, or one small family that shares one design. Assembly steps place finished elements. A step that would model two unrelated things is split, and the new part appended as a new step.
- **References first.** Read every reference the step names before any geometry. Where `references/` has nothing for the element, put at least two photos of the real thing in `references/elements/` first (from the user, or found, with the source on the card). Never model from memory.
- **The card.** Every element has `references/elements/<name>.md` (from `_template.md`): its references, its measurements in metres taken against something of known size (a 2.1 m door, a 12 m bus, a 15 cm kerb, a 1.75 m person), every visible detail as a list, the materials, the triangle budget per LOD, the moving parts, the states (clean, abandoned, damaged, burnt), and one section per round.
- **The loop.** A round: shoot the review sheet (`python tools/models/review.py <name> --round=N`: the rack's eight angles, a 1 m close-up, 10 m and 50 m, beside the references), write on the card every difference from the references, fix them, write what was fixed. Round 1 is form (silhouette, proportions, real size), Round 2 structure (the secondary forms), Round 3 surface (wear, lettering, colour variation, states); later rounds are named in the step. A round with nothing written down does not count. The step is done when the last round's list is empty, or each leftover is marked accepted with a reason. The final sheet is shown in chat.
- **Photo match for places.** Assembly steps rebuild each reference photo's viewpoint with `--shot-cam` and review the screenshot beside the photo, round by round, the same way.
- **The data says it.** Element and assembly steps carry `rounds: N` and the features `Round 1` .. `Round N` and `Review`; `python tools/steps_map.py --check` fails a step that names rounds without them.
- **Budgets hold.** Detail lives in silhouettes and baked textures, not in triangle soup: LODs, draw calls and triangles per LOD are on the card and checked by `tests/test_elements.gd`; repeated elements are instanced.
- **Later steps too.** Every weapon of P09 gets its model from its own element step, appended before its gameplay step starts. Effects and surfaces (P10) take rounds the same way on their racks when they are started.

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

### [ ] S140 · Element pipeline and review loop
> needs: S136 | size: L | test: `tests/test_elements.gd` | see: `python tools/models/review.py hydrant`
- Props, building parts, vehicles and guns are made the way the characters are: Python geometry, baked and exported by Blender into `assets/models/props/`, never edited by hand. GDScript boxes stay only for blockouts and the test maps.
- [ ] `python tools/models/props.py <name>` builds one element from `tools/models/props/<family>.py`; `--sketch` draws it flat-shaded without Blender in seconds, `--quick` shapes only
- [ ] Bake per element: albedo with ambient occlusion, a wear mask (edges, cavities, what faces the sky) painted from the card's materials, emission for anything lit, a LOD chain
- [ ] Named moving parts and states in the .glb (doors, lids, shutters, magazines, actions, wheels; clean, abandoned, damaged, burnt), loaded by `PropModel` with their nodes; repeated elements as MultiMesh
- [ ] Registry `scripts/models/elements.gd`: name, model, size, triangles per LOD, draws, parts, states; `tests/test_elements.gd` checks every entry (loads, size within 5 % of the card, budgets, parts, states, LODs)
- [ ] `--prop-rack=<name>` (with `--state=` and `--part=open`) in a neutral, evenly lit room; `python tools/models/review.py <name> --round=N` shoots the sheet (eight angles, 1 m, 10 m, 50 m) beside the card's references into `references/shots/review_<name>_r<N>.png`
- [ ] `references/elements/_template.md`, the card
- [ ] A fire hydrant taken through three rounds as the worked example, its card and sheets kept

### [ ] S141 · Detail kit
> needs: S140 | size: L | test: `tests/test_elements.gd` | see: `python tools/models/review.py kit`
- [ ] Shapes: chamfered and bevelled boxes, lathed profiles, sweeps along a path (pipes, rails, handrails, cables with sag), extrusions with inset and raised panels, linear and radial arrays, window and door frames, vents and slots
- [ ] Surfaces as geometry or bake: brick bonds, concrete block, stone setts, interlocking pavers, clay roof tiles in rows with ridge caps, corrugated and ribbed sheet, grilles and mesh, louvres, board-formed concrete
- [ ] Lettering: block and stencil fonts as geometry or painted into the bake (signs, plates, roof paint, road words), numbers
- [ ] Wear: chipped paint on edges, rust running from fixings, water stains below sills and joints, soot, moss and algae on shaded faces, dirt at the foot of walls, posters and graffiti as decals
- [ ] Damage: dents, broken glass with holes and cracks, bullet pocks, a burnt version of every material, cut lines for collapse
- [ ] The kit sheet: every helper side by side on the rack

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

### [x] S015 · Bleeding and healing
> needs: S014 | size: M | test: `tests/test_bleeding.gd`
- [x] Bleed chance on a hit, stacks to three, ticks HP, pinned in tests
- [x] Bandage stops bleeding, medkit restores HP over its use time, painkillers give decaying temporary HP
  - The medkit and bandage are spent and heal only when their use time (`Inventory.use_time`) is over; a hit or a sprint cancels them and the item stays in the pack
- [x] Use animation in first person: gun lowers, hands wrap a bandage (four eased poses), cancelled by sprint or damage
  - `Viewmodel.heal` / `heal_goal` / `heal_t`, `HEAL_POSES`, `heal_hands(t)`; the player sets them from `status`; `--pose=heal` shows it
- [x] Others see the heal pose on the remote player
  - `Humanoid.Anim.HEAL`, picked by `RemotePlayer.anim_for` from `PlayerWire.ACTION_HEAL`
- [x] Bleeding look: red drops from the lower screen edge, drip trail decals behind the player, heartbeat when low
  - `BleedDrops` on the HUD, `BleedTrail` + `Game.update_drips` (every peer, from `ACTION_BLEED`), `Heartbeat` and the `heartbeat` sound
- [x] `on_player_bleeding`, `on_player_healed` hooks (and `on_item_use_cancelled`)

### [x] S016 · Downed and revive
> needs: S015, S003 | size: L | test: `tests/test_downed.gd` | see: `tools\play2.ps1`
- [x] At 0 HP a player is downed, not dead: bleed-out timer, pistol only, crawl speed
  - Only while a teammate is still standing to get them up: the last one standing just dies. Damage to a downed player costs bleed-out time and can finish them
- [x] First-person camera drops to the floor, tilts, desaturates toward grey as the timer runs
  - `LocalPlayer.step_down_view`, `view_height`, `view_roll`; `Hud.grey_for` drives a screen shader; `--pose=downed`
- [x] Third-person rig: fall animation, propped on one arm, crawl cycle, reaching hand when a teammate is near
  - `Humanoid.Anim.DOWNED` (slow blend: the fall) with `reach`, `CRAWL` when moving; `RemotePlayer.animate`, `Game.update_reach`
- [x] Revive: hold use within reach for `Config.REVIVE_SECONDS`, progress ring on both HUDs, interrupted by damage to the reviver
  - [x] Hold right-click beside a downed teammate (`Game.downed_teammate_near`, `start_revive`, `client_revive`); damage, a sprint, walking off or letting go cancels it; the bleed-out clock waits while it runs
  - [x] The progress ring round the crosshair (`ProgressRing`, `Hud.ring_for`), for heals too
- [x] Revived at partial HP with a get-up animation and brief invulnerability
  - [x] `Config.REVIVE_HP` and `Config.REVIVE_INVULN` seconds in which nothing hurts them
  - [x] The get-up animation (`Humanoid.Anim.GETUP` for `Config.GETUP_TIME` on others, the view rising for yourself)
- [x] Zombies prefer standing players, finish downed ones when nobody else is near
- [x] All downed at once fails the mission

### [x] S017 · Death and spectating
> needs: S016 | size: M | test: `tests/test_spectate.gd`
- [x] Death camera: pulls back and up from the body, slow orbit, zombies feed on the corpse
  - `Spectator.orbit_goal`; the body is `Game.player_body` (a ragdoll of their own look on every peer), zombies within `Config.FEED_RANGE` go to it (`Zombie.feed_at`, `State.FEED`, `Anim.FEED`) until someone alive comes close; `--feed` shows it
- [x] Spectate living teammates: next / previous, smoothed third-person follow, their HP and ammo shown
  - [x] Fire and aim cycle through the standing, `Spectator`, a camera that eases behind and above them, their name, HP and gun on screen (`Game.spectate_text`)
  - [x] Their ammo: the magazine travels in `client_state` and in the player snapshot (`PlayerWire` 24 bytes, `mag`)
- [x] Respawn rules per mission from map data: at the next checkpoint, after a timer, or never
  - `respawn` in the data: `true` at once, seconds, `"checkpoint"`, `false` never; the dead are `PlayerStatus.dead` (out, frozen, hidden from the others by `ACTION_DEAD`, no shooting or using) until then
- [x] Respawn arrival: door kicked open or drop from a truck bed, not a pop
  - A drop off a truck bed: the view falls `Config.ARRIVE_DROP` (`LocalPlayer.arrive`), others see dust kicked up (`Fx.Kind.ARRIVAL`)
- [x] Dead players keep text chat and pings
  - T opens the chat line (`Hud.open_chat`, `Game.say` → `host_chat` → `chat_line`), Z pings where you look (`Game.ping` → `host_ping` → `ping_at`, `Config.PING_TIME`); hooks `on_chat`, `on_ping`

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

### [ ] S152 · Containers: lootbox, ammo crate, ammo cartons
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=containers`, `--host --map=corridor --shot-at=2`
- Today these are boxes in `lootbox.gd`, `ammo_crate.gd`, `ammo_box.gd`; the same nodes and states get new looks.
- [ ] Card: a steel supply box, a military ammunition crate, a carton per calibre; references of each
- [ ] Round 1 · form: sizes against a hand and a rifle; the lids and their hinge lines
- [ ] Round 2 · structure: latches, hinges, rope or steel handles, corner guards, the crate's stacking feet, the cartons' flaps and tape
- [ ] Round 3 · surface: stencilled lettering and lot numbers, chipped olive paint, the calibre stripe and brand-free print on the cartons, worn corners
- [ ] States: shut, open (the lid hinge already animates), empty, broken open
- [ ] Review: the corridor shot and the rack at 1 m

### [ ] S153 · Carried things: medkit, bandage, pills, planks, backpack
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=carried`, `--host --map=corridor --wheel --shot-at=3`
- [ ] Card: a red medical bag with a white cross, a bandage roll, a pill bottle, rough planks with nails, a hiking backpack; references of each
- [ ] Round 1 · form: sizes in a hand (the first-person heal and the wheel show them close)
- [ ] Round 2 · structure: zips, straps and buckles, the roll's loose end and gauze weave, the bottle's cap and label, nail heads and split ends on the planks
- [ ] Round 3 · surface: dirt and blood on the bag, fabric texture, the label's print, wood grain and saw marks
- [ ] The item wheel's icons rendered from these models, replacing the box icons of S014
- [ ] The heal animation (S015) holds the real bandage; the dropped backpack (`backpack.gd`) is this one
- [ ] Review: the wheel and the heal at 1080p, the rack at 1 m

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

### [x] S024 · Helicopter
> needs: S022, S004 | size: L | test: `tests/test_helicopter.gd` | see: `--host --map=corridor --heli --shot-at=3,6,9`
- [x] Model from boxes in `props.gd`: military transport, sliding side doors, skids, tail rotor, nav lights
- [x] Rotor: blades as one spinning mesh, swapped for a translucent blur disc above a speed, blades droop when stopped
- [x] Flight as a path on the host, sent as (path id, time): approach high, circle once, flare nose-up, settle
- [x] Body language: banks into turns, nose dips when accelerating, sways in the hover, skids compress on touchdown
- [x] Rotor wash: ring of dust blown outward on the ground, nearby particles and smoke pushed, players' view shakes softly underneath
- [x] Lights: red and green nav lights, white strobe, red anti-collision beacon sweeping the ground
- [x] Door gunner silhouette firing tracers at the horde during the hover
- [x] Boarding: players enter the door zone, camera sits them inside, lift-off, the city falls away
- [x] Sound hooks named for S087
  - `HeliFlight` (the path from landing point, heading and time), `Helicopter` (the look), `Game.call_heli` / `step_heli` / `heli_state`; the last wave of a defend objective calls it; `--heli`

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

### [ ] S154 · Helicopter model 2
> needs: S141, S179 | size: L | rounds: 4 | test: `tests/test_helicopter.gd` | see: `--prop-rack=helicopter`, `--host --map=corridor --heli --shot-at=3,6,9`
- Today it is twenty boxes (S024), and it ends every mission. `Helicopter`'s nodes and `HeliFlight` stay; the look is rebuilt.
- [ ] Card: a medium military transport helicopter of the Brazilian forces (photos in `references/elements/` first), its real length and rotor span
- [ ] Round 1 · form: the fuselage's curves, the nose and its glazing, the cabin, the tail boom's taper, the fin and stabiliser, the engine housing; skids or wheels as in the photos
- [ ] Round 2 · structure: sliding doors on rails, window frames, engine intakes and exhausts, the rotor head with its hub and pitch links, blade tips, the tail rotor's gearbox, steps, antennas, the door gun's mount
- [ ] Round 3 · surface: matt olive paint with panel lines and rivet rows baked, soot behind the exhausts, oil streaks, worn walkway paint, stencilled national markings and serials
- [ ] Round 4 · inside and night: seats along the cabin walls, cargo nets, the cockpit's panels and seats; the nav lights, strobe and beacon as emission
- [ ] Review: the three flight shots and the rack sheet beside the photos

---

## P04 · Gun feel

### [x] S029 · Muzzle flash and smoke
> needs: S004 | size: M | test: `tests/test_muzzle_fx.gd` | see: `--host --demo --weapon=4 --bot --shot-at=1,1.05,1.1`
- [x] Flash mesh at the muzzle for one or two frames: star of 3 to 5 crossed quads, random roll, random scale
  - [x] Shape per gun class: small round for pistols, long forked for rifles, wide ball for shotguns, side jets for braked snipers
  - [x] Suppressed guns: no flash, a thin grey puff
- [x] Light: one pooled omni, warm orange, 0.05 s, no shadows, only on the shooter's gun
- [x] It lights the viewmodel hands and the nearest walls
- [x] Smoke: two or three soft puffs drifting up and with the wind, 0.8 s
- [x] Sustained fire: barrel heat shimmer and a steady wisp from the muzzle for 2 s after a long burst
- [x] Remote players flash too, cheaper tier
  - `MuzzleFlash` (shapes by `Weapons.flash_shape`), `Viewmodel.smoke` → `Game.muzzle_smoke`, `heat` / `wisp_left` / `shimmer`; the host tells the others who fired (`Game.shot_seen`, which S030 can draw tracers from)

### [x] S030 · Tracers and bullet whiz
> needs: S004 | size: M | test: `tests/test_tracers.gd` | see: `tools\play2.ps1`
- [x] Tracer: thin emissive streak from muzzle to hit, 40 m long segment moving at bullet speed, fades at the end
- [x] Every shot for others' guns, every third for your own (clean view)
- [x] Colour by calibre: yellow-white rifles, faint for pistols, a fan of short ones for shotguns
- [x] Sniper shot: a vapour trail line that lingers 0.6 s and wobbles apart
- [x] Near miss from a teammate's line: whiz sound and a tiny view flinch
- [x] Capped, pooled
  - `Tracers` (`game.tracers`, one MultiMesh), fed by `Game._fire` (yours) and `shot_seen` (theirs, with where the bullet stopped: `_bullet_end`); `_near_miss` whizzes; a sniper's vapour line shows on every shot

### [x] S031 · Shell casings
> needs: S004 | size: M | test: `tests/test_casings.gd` | see: `--host --demo --weapon=4 --bot --shot-at=2`
- [x] Casing mesh per class: brass pistol, brass rifle, red shotgun hull, long sniper case
- [x] Ejects from the port with the gun's own direction, speed and spin, timed with the action (bolt guns eject on the bolt pull, pumps on the pump)
- [x] Cheap physics: one bounce off the floor with a tumble, a second small one, then rest
- [x] Tink on each bounce by surface
- [x] Rests for a while, then sinks, capped by MultiMesh
- [x] A wisp of smoke from the ejection port
  - `Casings` (`game.casings`), `Weapons.GUN_EJECT` / `casing_kind`, `Viewmodel.eject`; the tink's pitch is by kind of case until S032 gives floors their surface

### [x] S032 · Surfaces and impacts
> needs: S004 | size: L | test: `tests/test_impacts.gd` | see: `--host --fx-rack`
- [x] Surface kinds on collision bodies via metadata: concrete, asphalt, brick, metal, wood, glass, dirt, grass, water, flesh, tile
- [x] Impact per surface
  - [x] Concrete: grey dust cone, chips flying, round pocked hole
  - [x] Brick: red dust, larger chips
  - [x] Metal: sparks with gravity that bounce once, bright flash, dented hole with a shine ring, ricochet chance with a tracer
  - [x] Wood: splinters, pale torn hole
  - [x] Glass: star crack decal, a spray of shards
  - [x] Dirt and grass: clod spray, dark puff, blades of grass
  - [x] Water: vertical splash column, ring ripples
  - [x] Tile: white shards, cracked decal
- [x] Hole decals in the MultiMesh pool, aligned to the normal
- [x] Shotgun: one combined puff for the pattern plus individual holes
- [x] Penetration data per surface stored now, used by S101
  - `Surface` (`scripts/world/surface.gd`: `tag`, `of_hit`, `PENETRATION`), `Fx.Kind.IMPACT` with the surface as `arg` (`IMPACT_HOLE_ONLY`, `IMPACT_PUFF_ONLY` for a shotgun's pattern); the corridor, doors, crates and lootboxes are tagged, the city is still all concrete until its streets and blocks are built (S041, S043); `--fx-rack` has a row of impacts

### [x] S033 · Gun voices
> needs: S005 | size: L | test: `tests/test_gun_sounds.gd`
- [x] One synthesised shot per gun from layers: crack (noise burst), body (low thump by calibre), mechanical click, tail
  - [x] P19 short pop, P90 buzzy snap, Type 95 and AK47 heavy bark, AS Val soft thud
  - [x] USAS-12 and SPAS-12 boom with a long tail, T-5000 crack with a rolling echo, Dragunov sharp slap
- [x] Tail by place: short and boxy indoors, long slapback between buildings, open on the hill
- [x] Distance versions: far shots lose the crack and keep a dull thump
- [x] Suppressed variants
- [x] Dry fire click
- [x] Small pitch and level variation per shot, seeded per shot index
  - `GunVoice` (`scripts/gun_voice.gd`: `RECIPES`, `sound(id)` + `_far` / `_sup`, `tail(place)`, `variation(i)`), `Game.place_at`; checked by measurement in the tests (length, loudness, brightness), not yet by ear

### [x] S034 · Handling animation and sound
> needs: S033 | size: L | test: `tests/test_viewmodel.gd` | see: `--weapon=1..9 --pose=reload`
- [x] Reload has parts with their own sound and pose: mag release, mag out, new mag in, slap, bolt or charging handle
  - [x] Empty reload differs from a tactical reload
  - [x] The old magazine falls and stays on the floor a while
  - [x] Shotgun: shell in per round, pump at the end
  - [x] Bolt rifle: bolt up, back, forward, down, with the scope leaving the eye
- [x] Inspect animation on a key: roll the gun left and right, check the chamber
- [x] Idle life: slow breathing, micro-adjustments of the grip
- [x] Draw and holster with cloth and sling sounds
- [x] Low ammo: the last rounds of a magazine sound thinner and click
  - `Viewmodel.handling` (each part once, `reload_events`, `cycle_events`) → `Sfx` "h_" sounds; `mag_dropped` → `Casings` (`Weapons.Casing.MAG`); `WeaponState.reload_empty`; `scope_break`; `inspect()` (F, `--pose=inspect`); idle breathing and grip shifts; `low_ammo_click` under `Config.LOW_AMMO_ROUNDS`

### [x] S035 · Camera feel
> needs: S018 | size: M | test: `tests/test_camera_feel.gd`
- [x] Walk and sprint bob as a figure eight, synced with footsteps
- [x] Weapon sway lags the mouse, spring back, more with heavy guns
- [x] Strafe tilt of a degree or two
- [x] Recoil as a spring: kick up, recover most of the way, horizontal wander by gun
- [x] FOV opens a little while sprinting, pinches on a sniper shot
- [x] Shake sources mixed and capped: explosions, hits taken, leaper landing, helicopter
- [x] All of it scaled by a setting, off at zero
  - `CameraFeel` (`local_player.feel`: `step`, `add_shake`, `pinch`, `rumble`), the recoil spring (`punch_vel`, `step_recoil`), `Game.shake_near` / `got_hit` / `_fx_shake`, the "camera_motion" setting; recoil itself is gameplay and is not scaled by it

### [x] S036 · HUD 2
> needs: S011, S021 | size: L | test: `tests/test_hud.gd` | see: `--host --shot-at=2`
- [x] Bottom right: weapon name, magazine as individual pips or a number, reserve, fire mode
- [x] Bottom left: health bar with a bleed marker, stamina, item counts
- [x] Top: compass strip with bearings, objective and teammate ticks
- [x] Objective text with a typed-in reveal, strike-through and slide-out when done
- [x] World markers: objective diamond with distance, clamped to the screen edge with an arrow
- [x] Teammates: name over the head, outline through walls when far, downed icon with a timer
- [x] Interaction prompt with the bound key and a hold ring
- [x] Everything fades when not needed, HUD scale setting
- [x] Built in code, no draw-call growth
  - Parts: `AmmoPanel`, `VitalsBar`, `Compass`, `ObjectiveText`, `WorldMarkers` (`HudParts` draws for them), all under `Hud.root` (`apply_scale`, the `hud_scale` setting); `Hud.set_gun`, `set_vitals`, `set_compass`, `set_prompt(text, action)`, `step_fades`; `RemotePlayer.step_tag` counts a downed teammate's time; `Controls.label_of`. A downed teammate's clock is counted on each peer from when they went down (the host's own is not sent)

### [x] S037 · Hit feedback
> needs: S036 | size: M | test: `tests/test_hit_feedback.gd`
- [x] Hit marker: four ticks that snap in and ease out, red and larger for a kill, a skull tick for a headshot
- [x] Limb sever: a brief extra tick and a wet sound
- [x] Damage direction: red arc on the side the hit came from, fades over a second
- [x] Taking a hit: view punch away from the attacker, red edge flash, short muffling of sound
- [x] Low HP: pulsing dark red vignette, desaturation, heartbeat, blurred edges
- [x] Blood on the lens after a close kill: a few drops that run down and fade
  - `HitMarker`, `DamageArcs`, `LensBlood`, the `low_hp` shader on the HUD; `Game.hit_confirm(killed, headshot, severed, dist)` and `got_hit(amount, from)` (protocol 4); `Sfx.muffle` / `step_muffle` (a low-pass on Master); the `sever_wet` sound

### [x] S038 · Other players' animations
> needs: S016, S019 | size: L | test: `tests/test_remote_anim.gd` | see: `tools\play2.ps1`
- [x] Player snapshot carries an action byte: aim, reload, shove, heal, throw, downed, vault, crouch
- [x] Rig states in `Humanoid.Anim`
  - [x] Aim: shouldered gun, head tracks the look pitch
  - [x] Reload: support hand to the pouch and back, gun tilted
  - [x] Sprint with the gun carried low
  - [x] Shove, throw (wind-up, release), heal
  - [x] Hit flinch, death fall forward or backward by hit direction
- [x] Upper and lower body blend: legs run while the arms reload
- [x] Gun recoil kick on the remote rig per shot
  - `PlayerWire` 26 bytes (u16 action: AIM, RELOAD, SHOVE, THROW, VAULT added; s8 look pitch), protocol 5; `Humanoid.Upper` layered by `_write_upper` over the legs, `look_pitch`, `kick`; `RemotePlayer.upper_for`, `_place_gun`; the death falls along `players[id].last_push`; `--survivor-rack`. Aiming arms and gun line up roughly, not exactly (the gun hangs from the spine, not the hands)

### [ ] S142 · First-person hands and sleeves
> needs: S140, S136 | size: L | rounds: 4 | test: `tests/test_viewmodel.gd` | see: `--weapon=4 --pose=aim`, `--hands-rack`
- Today each arm is two boxes (a glove and a sleeve, `Viewmodel._make_arm`) while the zombies have real hands: the most-seen model of the game is the worst one.
- [ ] Card: the hand of `tools/models/body.py` (the bodies' measured proportions), forearm and wrist; references of hands on a pistol grip, a rifle grip and a handguard
- [ ] Rig: wrist, palm, five fingers in three segments, the thumb with its base; grip poses as data per gun and per moment (hip, aim, trigger pulled, magazine grab, pump, bolt, shove, bandage), blended like the rest of the viewmodel
- [ ] Round 1 · form: hand size and finger lengths against every gun's grip, the thumb over the web, no finger through a grip in any pose
- [ ] Round 2 · structure: knuckles, finger pads, nails, the web of the thumb, the wrist's bones, tendons on the back of the hand; sleeves with a cuff, a seam and folds that follow the elbow's bend
- [ ] Round 3 · surface: skin colour per player slot, dirt in the creases, scratches; tactical gloves as a variant (knuckle pads, stitching, cut fingertips); a watch on the left wrist
- [ ] Round 4 · motion: the index finger pulls on each shot, the support hand slides on the pump, fingers spread on a magazine, the fingers wrap the bandage (S015)
- [ ] The sleeves follow the player's survivor look (S243 when it exists)
- [ ] Review: hip and aim on all nine guns at 1080p and the hands rack, beside the zombies' hands


### [ ] S143 · Gun model 2: P19 pistol
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=1 --pose=aim`, `--weapon=1 --pose=reload`
- [ ] Card: photos of the real gun (a modern polymer-frame pistol) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: slide, frame, the grip's angle and beavertail, trigger guard, the magazine in the grip; the profile matches the photo at the same scale
- [ ] Round 2 · structure: front and rear slide serrations, the ejection port with the barrel's hood, sights with white dots, takedown lever, slide stop, magazine release, the accessory rail's slots, the trigger with its safety blade
- [ ] Round 3 · surface: the grip's stippled panels, a matte slide with holster wear on its edges, stamped markings, grime
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S144 · Gun model 2: P90
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=2 --pose=aim`, `--weapon=2 --pose=reload`
- [ ] Card: photos of the real gun (the bullpup personal defence weapon) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the bullpup shell, the thumbhole grip, the translucent magazine along the top, the stubby barrel and flash hider; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the ring sight on top, both charging handles, the cartridges visible in the magazine, the ejection chute under the stock, the fire selector disc, sling points
- [ ] Round 3 · surface: polymer with mould seams, scuffs on the grip, the magazine's tint, markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S145 · Gun model 2: Type 95
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=3 --pose=aim`, `--weapon=3 --pose=reload`
- [ ] Card: photos of the real gun (the bullpup assault rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the bullpup body, the carry handle with its sight, the magazine behind the pistol grip, the cheek rest, the short barrel; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the rear aperture and front post, the charging handle under the carry handle, the ejection port, the selector behind the magazine, vent slots in the handguard, the flash hider
- [ ] Round 3 · surface: dark polymer texture, worn edges, stamped markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S146 · Gun model 2: AK47
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=4 --pose=aim`, `--weapon=4 --pose=reload`
- [ ] Card: photos of the real gun (the rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the receiver, the gas tube over the barrel, wooden handguards and stock, the curved magazine, the pistol grip; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the dust cover's ribs and rivets, the rear sight leaf with its range scale, the hooded front post, the slant brake, the cleaning rod, the selector lever, the charging handle, sling loops, the trigger guard
- [ ] Round 3 · surface: bluing worn on the edges, scratched wood with grain, the magazine's ribs catching the light, a serial stamp, grime in the corners
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S147 · Gun model 2: AS Val
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=5 --pose=aim`, `--weapon=5 --pose=reload`
- [ ] Card: photos of the real gun (the suppressed rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the integral suppressor along the whole front, the receiver, the skeleton stock folded or out, the 20-round box magazine; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the suppressor's perforated sleeve and end cap, the side scope rail, the iron sights on the suppressor, the safety lever, the charging handle, the stock's tube frame and butt plate
- [ ] Round 3 · surface: black finish worn bare on the suppressor's edges, the magazine's ribs, markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S148 · Gun model 2: USAS-12
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=6 --pose=aim`, `--weapon=6 --pose=reload`
- [ ] Card: photos of the real gun (the automatic shotgun) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the long boxy receiver, the carry handle, the pistol grip and fixed stock, the box magazine; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the handle's sight channel, the front sight, the charging handle, the barrel shroud's vents, sling swivels, the magazine release
- [ ] Round 3 · surface: matte black polymer and steel, scuffs, markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S149 · Gun model 2: SPAS-12
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=7 --pose=aim`, `--weapon=7 --pose=reload`
- [ ] Card: photos of the real gun (the pump shotgun) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the receiver, the perforated heat shield over the barrel, the pump fore-end, the tube magazine, the pistol grip, the folding stock with its hook; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the heat shield's holes, the fore-end's ribs, the pump and semi selector, the sights, the stock's hinge and hook, sling swivels
- [ ] Round 3 · surface: parkerised finish with wear, scratches on the shield, markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S150 · Gun model 2: Orsis T-5000
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=8 --pose=aim`, `--weapon=8 --pose=reload`
- [ ] Card: photos of the real gun (the bolt-action sniper rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the chassis stock with its skeleton butt, the long free-floated barrel, the big scope, the bolt with its large knob, the box magazine, the bipod; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the adjustable cheek riser and butt pad, the top rail, the scope's turrets and caps, the muzzle brake's ports, the folding hinge, the bipod's legs and feet
- [ ] Round 3 · surface: a ceramic-coat finish worn at the edges, scratches on the brake, tinted lens glass, markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places


### [ ] S151 · Gun model 2: Dragunov
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=9 --pose=aim`, `--weapon=9 --pose=reload`
- [ ] Card: photos of the real gun (the marksman rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] Round 1 · form: the long thin barrel, the skeleton wooden thumbhole stock, the handguards, the scope offset to the left, the 10-round magazine; the profile matches the photo at the same scale
- [ ] Round 2 · structure: the slotted flash hider, the bayonet lug, the handguards' vent holes, the cheek piece, the scope's rubber eyecup and turrets, the dust cover, the safety lever
- [ ] Round 3 · surface: lacquered wood with grain and dents, worn bluing, markings
- [ ] Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places

---

## P05 · The real Joinville

### [x] S039 · Trace the OpenStreetMap tiles
> needs: none | size: L | test: `tests/test_city_osm.gd` | see: redraw `references/city_plan.png`
- [x] `tools/trace_osm.py` reads `references/1.png` to `9.png` into `scripts/world/city_osm.gd` (generated, never edited by hand)
  - [x] Each tile registered to `joinville.png` pixels by two named control points per tile, kept in the tool
  - [x] Building footprints: the brown-grey polygons, simplified to a few corners, area and centroid
  - [x] Street casings by colour class: red trunk, orange, yellow, white residential, grey pedestrian
  - [x] Water, parks, parking lots, forest stipple as polygons
- [x] Overlay picture `references/osm_on_reference.png` proves the registration by eye
- [x] Test: the terminal, the Prefeitura and the hospital footprints land inside their `CityData.POIS` lots
- [x] Gaps between tiles reported, not guessed
  - The tiles are at four times joinville.png's zoom (their scale bars); `--register` finds each tile's place by cross-correlating its buildings with joinville.png's (match 0.64 to 0.77) and the control points are kept in `TILES`. 1301 footprints (convex, simplified), streets as 1-pixel cells per class, areas as polygons; the overlay is generated, not committed. The nine tiles cover the centre in an uneven patchwork: what their bounding box leaves uncovered is `CityOsm.GAPS`

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
> needs: S040, S155 | size: L | rounds: 3 | test: `tests/test_road_surface.gd` | see: `--host --shot-cam` over Rua Nove de Março, `--street-rack`
- [ ] Surfaces as vertex colour and one shared material, no textures
  - [ ] Asphalt: dark, patched rectangles, tar seams, a lighter worn track per lane
  - [ ] Paralelepípedo (stone setts) on old centre streets and the terminal apron: rows drawn in vertex colour, slight height noise
  - [ ] Grey concrete pavers on the Mirante road
- [ ] Markings as thin overlay meshes in one draw per street
  - [ ] Centre line single or double yellow, white lane dashes, edge lines
  - [ ] Zebra crossings with a stop line before them, at every traced junction that has one
  - [ ] Bus lane and bus box lettering near the terminal, painted arrows, PARE on the ground, words and numbers as on the Prefeitura's avenue (CURVA, 60 in `prefeitura2.jpg`)
  - [ ] Yellow painted kerbs where parking is forbidden
- [ ] The road details of S155 placed: manholes, drains at the kerb, speed humps, cracks and potholes seeded per street
- [ ] Camber: the road crown is a few centimetres above the gutters
- [ ] `--street-rack`: a 30 m strip of every surface and marking side by side
- [ ] Round 1 · form: the strips' crowns, kerb lines and the markings' widths against the Brazilian standards
- [ ] Round 2 · structure: patches, seams, worn tracks, faded and cracked paint, the setts' rows and joints
- [ ] Round 3 · wet and night: the same strips at night and wet (S110 when it exists), lamp pools, oil sheen
- [ ] Review: the street rack sheet and the Rua Nove de Março shot

### [ ] S042 · Sidewalks
> needs: S040, S156 | size: M | rounds: 3 | test: `tests/test_sidewalks.gd` | see: `--host --shot-cam` on a street corner, `--street-rack`
- [ ] Kerb as a real 15 cm step with a granite edge, players and zombies walk it without a jump
- [ ] Paving kinds by street
  - [ ] Red interlocking brick pavers (the squares and the Mirante walkway: `praça_da_bandeira.jpg`, `mirante_street.jpg`)
  - [ ] Grey concrete slabs with joints
  - [ ] Petit-pavé black and white mosaic bands on the main shopping streets
- [ ] Dropped kerbs at driveways and crossings, yellow tactile strips at corners
- [ ] Tree pits with white kerbs as in the square, grass verges; the front walls, fences and gates of S156 along the lot lines
- [ ] Sidewalks are nav cells: zombies use them, hordes spill onto the road
- [ ] Round 1 · form: kerb heights and sidewalk widths per street, the pavers' sizes and bonds against the photos
- [ ] Round 2 · structure: joints, broken and missing pavers, sunken slabs, roots lifting the paving by the trees
- [ ] Round 3 · surface: grime, gum, stains, weeds in the joints, darker where wet
- [ ] Review: the street rack and the corner shot beside the photos

### [ ] S043 · Block massing
> needs: S039, S040 | size: L | rounds: 2 | test: `tests/test_city_blocks.gd` | see: `--host --shot-cam` skyline
- [ ] Every traced footprint inside a mission area becomes a solid extruded block, in the right place and shape
- [ ] Height from a class picked by footprint area, street and seed
  - [ ] House: one or two floors, hipped red clay tile roof
  - [ ] Shop row: two or three floors, flat roof behind a parapet
  - [ ] Slab block: 8 to 20 floors, set back, with a podium
  - [ ] Shed: large low footprint, shallow metal roof (the works along Rua Aubé)
- [ ] Known heights for buildings visible in the photos (the towers behind Praça da Bandeira, the blocks around the hospital) in a small override table
- [ ] Collision is the block, one mesh per city block, test counts draws
- [ ] Blocks outside every mission area: low-detail silhouettes only
- [ ] Round 1 · skyline: the towers behind Praça da Bandeira and round the hospital, from the viewpoints of `praça_da_bandeira.jpg` and `hospital1.jpg`
- [ ] Round 2 · roofscape: the blocks and roofs from the helicopter's height against the OSM tiles and `prefeitura3.png`
- [ ] Review: the photo views side by side

### [ ] S044 · Facades
> needs: S043, S157, S158, S159, S160, S161, S162, S163, S164 | size: L | rounds: 2 | test: `tests/test_facades.gd` | see: `--host --shot-cam` street level, day and night
- Assembly: the blocks of S043 dressed from the facade kits; nothing modelled here.
- [ ] Facade grammar per block class: which kit, how many floors, where the shops, doors and signs go, seeded per building
  - [ ] Plaster houses (S162) and enxaimel houses (S161) on the residential streets; shop rows of shopfronts (S158) under windows (S157) in the centre; towers (S163) set back on podiums; sheds (S164) along Rua Aubé
  - [ ] Rooftops and balconies (S159), signs (S160) by the shop kinds of the street
- [ ] Joinville's mix: enxaimel gables among pastel houses and modernist towers, as in the background of `praça_da_bandeira.jpg`
- [ ] Night: a seeded few windows lit warm or TV-blue, some flickering, most dark
- [ ] Decay by street: boarded and broken windows, soot above burnt ones, quarantine tape across doors (the kits' states)
- [ ] House numbers by the doors
- [ ] Round 1 · composition: three street views (centre, residential, Rua Aubé) for variety; no two neighbours alike
- [ ] Round 2 · night and decay: the same views at night and in the abandoned state
- [ ] Review: the three views, day and night

### [ ] S045 · Rio Cachoeira
> needs: S040, S004, S165, S174 | size: L | rounds: 3 | test: `tests/test_river.gd` | see: `--host --shot-cam` on a bridge
- [ ] Channel cut below street level: sloped grass and stone banks, a retaining wall where the avenues run beside it, the green railing and shrubs along the Prefeitura's bank (`prefeitura2.jpg`)
- [ ] Water: one mesh, shader in code with slow flow along the river line, small ripples, dark green-brown, sky and lamp reflections as stretched streaks
- [ ] The bridges of S165 at the traced crossings
- [ ] Floating things drifting with the flow: debris, a body, an upturned boat (S184), seeded
- [ ] Imperial palm row along the riverside avenue as in `prefeitura3.png` (S174)
- [ ] Water is not walkable; falling in wades the player to the bank slowly, zombies stay out
- [ ] Mist over the water at night
- [ ] Round 1 · form: the channel's width, depth and banks against the OSM water and `prefeitura2.jpg`
- [ ] Round 2 · water: colour, flow, reflections, the line where water meets the bank
- [ ] Round 3 · night: the lamps' reflections, mist
- [ ] Review: the bridge shot and the `prefeitura2.jpg` view side by side

### [ ] S046 · Street furniture placement
> needs: S041, S042, S166, S167, S168, S169, S170, S171, S172, S173 | size: M | rounds: 2 | test: `tests/test_street_furniture.gd` | see: `--furniture-rack`, `--host --shot-cam` on a street corner
- Assembly: places the finished street furniture; nothing modelled here.
- [ ] Rules along streets, seeded, merged per block: lamps by street class and spacing, poles and cables along every street with their spans, traffic lights at the traced junctions that have them, name plates on corners with the real street names, bus stops where the lines run, an orelhão and a banca now and then, benches, bins and bollards by the squares and shops
- [ ] Lamps follow the two-shadow rule: emission and a cheap light, shadows only from the manager (S108)
- [ ] States by street: a few lamps flicker or are bent and dead, a pole leans with its cables down, a sign is bent
- [ ] Small props are cover; thin poles do not block bullets
- [ ] `--furniture-rack`: every piece of S166 to S173 in a row
- [ ] Round 1 · placement: a centre street, the riverside avenue and a residential street against the photos' streets
- [ ] Round 2 · density and light: enough clutter to read as a real street, the lamps' pools at night
- [ ] Review: the corner shot by day and night

### [ ] S047 · Vegetation placement and wind
> needs: S042, S174, S175, S176, S177, S178 | size: M | rounds: 2 | test: `tests/test_vegetation.gd` | see: `--tree-rack`, `--host --shot-cam` on Alameda Brüstlein
- Assembly and the shared systems: places the finished plants of S174 to S178.
- [ ] Planting rules: palms on the avenues and medians, ipê and street trees in the sidewalk pits, shrubs and hedges in front gardens and squares, the forest wall where the hill rises
- [ ] Wind: vertex sway in a shader, stronger at the tips, gusts that travel across a street
- [ ] Grass tufts on lawns and verges as one MultiMesh, pressed down where zombies ran
- [ ] Leaves fall and skitter along the gutter in gusts
- [ ] `--tree-rack`: every species and size in a row
- [ ] Round 1 · placement: Alameda Brüstlein, the Prefeitura's avenue, a residential street, the edge of the hill
- [ ] Round 2 · motion: wind strength by place, gusts, nothing swimming
- [ ] Review: the four views beside `prefeitura2.jpg` and `praça_da_bandeira.jpg`

### [ ] S048 · Apocalypse dressing
> needs: S046, S180, S181, S182, S183, S184, S185, S186, S203 | size: M | rounds: 2 | test: `tests/test_dressing.gd` | see: `--host --shot-cam` on the avenue
- Assembly: places the finished vehicles and leftovers; the set pieces of `scenery.gd` are rebuilt from them.
- [ ] Vehicles in their states (S179's generator): parked, abandoned with doors open, crashed into a pole, rolled over, burnt out; hazard lights still blinking on a few, a dome light on, a wiper still moving
- [ ] Traffic jam generator along a street: a queue toward the way out of town, buses (S203) among the cars, gaps to walk through
- [ ] Evacuation remains (S184) spilled along the jams and the sidewalks
- [ ] Military and police leftovers (S185): checkpoints, sandbags, wire, body bags in rows
- [ ] Words and posters (S186) on walls, shutters and vehicles
- [ ] Blood: drag trails into doorways, handprints, pools under cars
- [ ] Small fires in barrels and wrecks (uses S094 when present, a plain flicker before)
- [ ] Wrecks are cover and block nav
- [ ] Round 1 · story: each scene reads as something that happened (the jam, the checkpoint that fell, the evacuation)
- [ ] Round 2 · density: walkable, not a wall of clutter, budgets held
- [ ] Review: the avenue shot and a checkpoint shot

### [ ] S049 · Squares and landmarks
> needs: S044, S047, S166, S173, S187, S188, S189, S190 | size: M | rounds: 3 | test: `tests/test_landmarks.gd` | see: `--host --shot-cam` on Praça da Bandeira
- Assembly of the finished landmarks, each on its traced footprint, exterior only.
- [ ] Praça da Bandeira from `praça_da_bandeira.jpg`: the red paver field, the monument (S187) on its plinth, the flagpole, the white-edged tree beds with young trees, the green double-globe lamps (S166), the green square bins and benches (S173), the palms and the araucária by the monument
- [ ] Alameda Brüstlein: the double row of imperial palms on a long median
- [ ] The cathedral (S188) on Rua do Príncipe
- [ ] Cemitério do Imigrante (S189) on its slope
- [ ] Zoobotânico at the foot of the hill (S190), seen only on the Mirante mission
- [ ] Round 1 · layout: the square's plan against the OSM tiles and the photo's view from above
- [ ] Round 2 · photo match: the viewpoint of `praça_da_bandeira.jpg` rebuilt with `--shot-cam`, side by side
- [ ] Round 3 · decay: the abandoned square (litter, a fallen lamp, a car crashed into a tree bed) without losing the place
- [ ] Review: the photo match sheet

### [ ] S050 · Sky and time of day
> needs: S004 | size: L | rounds: 3 | test: `tests/test_sky.gd` | see: `--time=day|dusk|night --shot-at=2`
- [ ] Sky shader in code: gradient, sun or moon disc, stars that twinkle, two drifting cloud layers lit from below by the city at night
- [ ] Presets per mission in map data: overcast day, orange dusk with long shadows, moonlit night, storm
- [ ] One directional light per preset, shadows only by day and dusk
- [ ] Distance fog tinted by the preset, hides the draw distance limit
- [ ] Far backdrop: skyline silhouette of towers and the dark mass of Morro da Boa Vista with the lit Mirante on top, visible from every mission
- [ ] Columns of smoke on the horizon, a distant fire glow under the clouds
- [ ] `--time=` flag, sent in `welcome`
- [ ] Round 1 · day: the clear and overcast presets against `praça_da_bandeira.jpg` and `prefeitura2.jpg` (sky colour, clouds, the light on the facades)
- [ ] Round 2 · dusk and night: the night of `hospital1.jpg` (the city's glow under the clouds, the dark hill), the moon and stars
- [ ] Round 3 · storm and backdrop: the storm preset, the skyline and Morro da Boa Vista seen from each mission's start
- [ ] Review: every preset from the same three viewpoints in one sheet

### [ ] S051 · Mission areas
> needs: S002, S043, S048 | size: L | test: `tests/test_mission_areas.gd` | see: `--mission=<each>`
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

### [ ] S155 · Road details: manholes, drains, humps
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=road_details`
- [ ] Card: photos of the city's manhole covers, kerb inlets (bocas de lobo), grated drains and speed humps
- [ ] Round 1 · form: round and square covers with their frames, the kerb inlet's concrete lintel and mouth, grates, the hump's profile to the Brazilian standard
- [ ] Round 2 · structure: cast patterns and lettering on the covers, the grate bars, the hump's painted chevrons and its sign post, cracked asphalt rings round the covers
- [ ] Round 3 · surface: rust and polish where tyres pass, leaves and silt in the drains, faded paint, patches and potholes as decals with depth
- [ ] States: a missing cover (an open hole), a drain overflowing in rain (S110)
- [ ] Review: the rack and a street strip at 1 m and 10 m

### [ ] S156 · Front walls, fences and gates
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=boundaries`
- The muro is the face of a Brazilian street: most houses show a wall and a gate, not a facade.
- [ ] Card: photos of Joinville street fronts: plastered walls with pillars, iron bar gates, sliding sheet gates with grilles, low walls with railings, chain-link, hedges
- [ ] Round 1 · form: heights (1.8 to 2.2 m walls, 0.6 m low walls), pillar spacing, gate widths for a car and for a person
- [ ] Round 2 · structure: copings, pillar caps, the gates' bars and patterns, hinges and rollers, letterboxes and intercoms, house numbers, spikes or broken glass along the top, electric fence wires on insulators
- [ ] Round 3 · surface: painted plaster with damp rising from the ground, peeling paint, rust on the gates, tags, moss
- [ ] Modules that join along any lot line, with corners and ends; states: gate open, rammed, burnt
- [ ] Review: a street front of ten lots at 10 m and the rack at 1 m

### [ ] S157 · Window kit
> needs: S141 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=windows`
- [ ] Card: photos of the windows of Joinville's houses, shop rows and towers: aluminium sliders, wooden venezianas, iron grilles (grades), office ribbon glazing
- [ ] Round 1 · form: sizes and proportions per kind, how deep each sits in the wall, sills
- [ ] Round 2 · structure: frames and mullions, sliding sashes, the shutters' louvres, the grilles' patterns, drip edges, an AC box in some
- [ ] Round 3 · surface: glass that reflects the sky, dirt in the frame corners, rust running from the grilles, faded shutters, curtains and blinds behind some
- [ ] States: open, shut, broken (shards left in the frame), boarded, burnt with soot above; lit warm, TV-blue or dark at night (emission)
- [ ] Review: each kind at 1 m and on a test wall at 10 m, by day and night

### [ ] S158 · Shopfront kit
> needs: S141, S157 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=shopfronts`
- [ ] Card: photos of the centre's shopfronts (Rua do Príncipe, Rua XV de Novembro)
- [ ] Round 1 · form: bay widths, the glass front and its doorway, the box of the roll-down shutter above, awning depths
- [ ] Round 2 · structure: aluminium frames, the steel shutter's slats, locks and bottom bar, fabric and metal awnings on brackets, a recessed doorway with a tiled step, counters and shelves seen through the glass
- [ ] Round 3 · surface: posters and prices in the windows, dirty glass, scratched and tagged shutters, faded awnings
- [ ] States: open, shutter down, shutter half up, forced (bent up), looted (glass out, shelves bare)
- [ ] Review: a row of six fronts at 1 m and 10 m

### [ ] S159 · Rooftops and balconies
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=rooftops`
- [ ] Card: photos of the centre's roofs and the towers' balconies (the backgrounds of `praça_da_bandeira.jpg` and `hospital1.jpg`)
- [ ] Round 1 · form: balcony slabs and railings, split-AC outdoor units, water tanks (caixas d'água), lift overruns, parapets
- [ ] Round 2 · structure: railing bars and glass, the AC units' fans and pipes, tank lids and pipes, TV antennas and dishes, gutters, downpipes, roof ladders
- [ ] Round 3 · surface: rust streaks under the AC units, black water stains below the parapets, laundry and plants on some balconies
- [ ] Review: a tower top and a stack of balconies at 10 m and 50 m

### [ ] S160 · Shop signs and lettering
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=signs_shops`
- [ ] Card: photos of the centre's shop signs; the kinds: FARMÁCIA with a green cross, PADARIA, LOTÉRICA, LANCHONETE, FERRAGENS, AÇOUGUE, BAR, OFICINA, ÓTICA, never a real brand
- [ ] Round 1 · form: fascia boards, lightboxes, projecting signs, the pharmacy cross
- [ ] Round 2 · structure: letters raised or painted, the boxes' frames and fixings, the cables to the lit ones
- [ ] Round 3 · surface: faded paint, cracked acrylic, missing letters, rust running from the fixings
- [ ] Seeded per building from its shop kind; states: lit, dead, flickering (S108), half fallen
- [ ] Review: a street of signs by day and at night

### [ ] S161 · The enxaimel house
> needs: S141, S157 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=enxaimel`
- Joinville's German heritage: dark timber frames on white walls under steep red roofs.
- [ ] Card: photos of Joinville's half-timbered houses: the frame patterns, the proportions, the gables (the red gable in the background of `praça_da_bandeira.jpg`)
- [ ] Round 1 · form: the steep gable, the floors, the roof's overhang; a two-storey and a one-storey variant
- [ ] Round 2 · structure: posts, rails and diagonal braces, sills and lintels, small casements with shutters and flower boxes, roof tiles, bargeboards and the ridge
- [ ] Round 3 · surface: weathered dark timber, whitewash with hairline cracks, moss on the tiles, a date carved over the door
- [ ] Round 4 · use: a variant with a shop or café on the ground floor (S158), and the abandoned state
- [ ] Review: front, gable and three-quarter at 1 m and 10 m beside the photos

### [ ] S162 · Plaster houses
> needs: S156, S157 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=houses`
- [ ] Card: photos of Joinville's single-family houses: pastel plaster, tiled hip roofs, porches, garages behind the front wall
- [ ] Round 1 · form: one and two floors, roof pitches, the porch, the garage; modules that fit the traced footprints
- [ ] Round 2 · structure: windows (S157), the porch's columns and tiles, eaves with fascia and gutters, garage doors, the front wall and gate (S156), an outdoor laundry sink, a water tank
- [ ] Round 3 · surface: pastel paints faded by the sun, damp stains, mould under the eaves, pots of plants, satellite dishes
- [ ] Seeded variants so a street of them never repeats; abandoned and burnt states
- [ ] Review: a street of eight houses at 10 m and one at 1 m

### [ ] S163 · Tower facades
> needs: S157, S159 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=towers`
- [ ] Card: the towers in `praça_da_bandeira.jpg` and `hospital1.jpg`: a white tower with vertical slots, a dark glass block, a 1970s block with a crowned top, balcony slabs, brise-soleil fins
- [ ] Round 1 · form: the facade modules by kind (balcony bays, ribbon windows, punched windows, fin screens), the podium with its shops, the crown
- [ ] Round 2 · structure: slab edges, mullions, railings, fins with their brackets, the lit lobby with its glass doors, plant on the roof
- [ ] Round 3 · surface: water stains running from every slab edge, faded tiles, AC units scattered, a few burnt flats with soot above
- [ ] Round 4 · night: a seeded handful of lit windows, the lobby's light, aircraft lights on the tallest
- [ ] Review: the photos' backgrounds rebuilt with `--shot-cam`, side by side

### [ ] S164 · Works sheds
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=sheds`
- [ ] Card: photos of the industrial sheds along Rua Aubé (the OSM tiles show their footprints)
- [ ] Round 1 · form: long low halls, shallow and sawtooth roofs, loading bays
- [ ] Round 2 · structure: corrugated cladding, roller doors, clerestories and translucent roof panels, steel frames at the ends, loading docks with bumpers, brand-free gantry signs
- [ ] Round 3 · surface: rust, faded paint, oil on the yards, broken panels
- [ ] Review: the street front at 10 m and a loading bay at 1 m

### [ ] S165 · Bridges
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=bridges`
- [ ] Card: photos of the bridges over the Rio Cachoeira at the traced crossings
- [ ] Round 1 · form: deck widths and spans, piers in the water, sidewalks; a road bridge and a footbridge
- [ ] Round 2 · structure: parapets or railings as in the photos, expansion joints, the piers' cutwaters, drainage spouts, lamp posts, kerbs
- [ ] Round 3 · surface: stains below the spouts, moss at the waterline, graffiti under the deck, rust on the railings
- [ ] Review: each bridge from the road and from the water at 10 m and 50 m

### [ ] S166 · Street lamps
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=lamps_street`
- [ ] Card: the avenue lamps of `prefeitura2.jpg`, the square's green double-globe lamps of `praça_da_bandeira.jpg`, the hill road's arm on a pole (`mirante_street.jpg`)
- [ ] Round 1 · form: pole heights and tapers, the arms' curves, heads and globes, bases
- [ ] Round 2 · structure: base plates with bolts and the access door, the arm's bracket, the luminaire's housing and glass, the globes' fittings
- [ ] Round 3 · surface: galvanised or green paint with chips, stickers and posters on the poles, rust at the foot, insects in the globes
- [ ] States: lit (sodium orange, LED white), dead, flickering (S108), bent by a crash
- [ ] Review: each lamp at 1 m and 10 m, and lit at night

### [ ] S167 · Utility poles and cables
> needs: S141 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=poles`
- The tangle of cables on concrete poles is one of the strongest signatures of a Brazilian street.
- [ ] Card: photos of the city's poles: double-T and round concrete poles, crossarms, transformers, telecom bundles (`mirante_street.jpg`)
- [ ] Round 1 · form: pole heights and sections, the crossarms' levels, the transformer's place
- [ ] Round 2 · structure: insulators, fuse cutouts, the transformer's fins and bushings, ground wires, telecom boxes, cable bundles with coiled spare loops, a lamp arm
- [ ] Round 3 · surface: concrete stains, rust on the fittings, posters and stickers stapled on, stencilled numbers
- [ ] Round 4 · cables: catenaries between poles with their sag, bundles of different thickness, slack ones over the street, a few hanging down
- [ ] States: a leaning pole, a broken one with its cables down, sparks (S114)
- [ ] Review: a street of six spans at 10 m against the photo, and a pole at 1 m

### [ ] S168 · Traffic lights
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=traffic_lights`
- [ ] Card: photos of the city's semáforos on mast arms and short poles
- [ ] Round 1 · form: masts and arms, signal heads with three lenses, pedestrian heads
- [ ] Round 2 · structure: visors, backplates with yellow borders, push-button boxes, the controller cabinet and its door, bolts and clamps
- [ ] Round 3 · surface: faded paint, dirty lenses, stickers on the cabinet
- [ ] States: dead, blinking yellow, a head hanging by its cable (swung by S115)
- [ ] Review: a junction at 10 m and a head at 1 m, lit at night

### [ ] S169 · Street signs
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=signs_street`
- The model of a good element step: one family, every sign as an extremely detailed low-poly model.
- [ ] Card: photos of the city's street-name plates (their colour, layout and the neighbourhood line) and its traffic signs: PARE, speed limits, no parking, one-way, lombada, pedestrian crossing, bus stop
- [ ] Round 1 · form: plate and sign sizes from the Brazilian standards, mounting heights, the poles
- [ ] Round 2 · structure: rolled edges, the backs with their brackets and clamps, bolts, pole caps, two-sided name plates on corners
- [ ] Round 3 · surface: retroreflective faces that catch headlights and the flashlight, faded red, stickers, rust bleeding from the bolts, bullet holes
- [ ] Name plates take any real street name and neighbourhood; states: bent, knocked over, shot
- [ ] Review: every sign at 1 m and 10 m, lit by the flashlight at night

### [ ] S170 · Bus stop shelter
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=bus_stop`
- [ ] Card: photos of Joinville's bus shelters
- [ ] Round 1 · form: the canopy, the frame, the seat, the panels
- [ ] Round 2 · structure: glass or perforated panels, the ad box with its light, the timetable frame, a bin, the line numbers
- [ ] Round 3 · surface: scratched glass, stickers, posters, grime
- [ ] States: smashed glass, the ad light flickering
- [ ] Review: at 1 m and 10 m, by day and night

### [ ] S171 · Orelhão
> needs: S141 | size: S | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=orelhao`
- [ ] Card: photos of the egg-shaped public phone hoods and their phones
- [ ] Round 1 · form: the shell's curve and opening, the post, the height
- [ ] Round 2 · structure: the phone's body, keypad, the handset on its armoured cord, the hood's fixing ring
- [ ] Round 3 · surface: the shell's colours faded, scratches and stickers, grime
- [ ] States: the handset hanging, the shell cracked
- [ ] Review: at 1 m and 10 m

### [ ] S172 · Banca de jornal
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=banca`
- [ ] Card: photos of the centre's newsstands
- [ ] Round 1 · form: the kiosk box, the fold-up shutters that make its awning, the counter
- [ ] Round 2 · structure: magazine racks and clips, the shutters' hinges and props, the roof's lip, the sign
- [ ] Round 3 · surface: magazine covers as a texture (no real titles), faded paint, rust
- [ ] States: open, shut, looted (papers blowing, S115)
- [ ] Review: at 1 m and 10 m

### [ ] S173 · Small street furniture
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=street_small`
- [ ] Card: the square's benches and green square bins (`praça_da_bandeira.jpg`), bollards, a column fire hydrant, the yellow post box, bike racks, tree guards, planters
- [ ] Round 1 · form: each at its real size
- [ ] Round 2 · structure: slats and brackets, the bins' frames and lids, the hydrant's caps and chains, the post box's slot and door
- [ ] Round 3 · surface: worn paint, rust, stickers, litter in and round the bins
- [ ] Review: everything at 1 m

### [ ] S174 · Imperial palm
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=palm`
- [ ] Card: the palms of `prefeitura2.jpg` and `praça_da_bandeira.jpg`: a smooth grey trunk with a slight swelling, the green crownshaft, arching fronds
- [ ] Round 1 · form: heights from 12 to 25 m, the trunk's taper and swelling, the crownshaft's length, the crown's spread
- [ ] Round 2 · structure: ring scars on the trunk, fronds as stems with drooping leaflets, a dead frond hanging under the crown
- [ ] Round 3 · surface: lichen patches, the trunk's greys, the leaflets' light and dark sides
- [ ] Three variants and a LOD chain down to a card at 200 m; the wind of S047 bends the fronds
- [ ] Review: a row of six against `prefeitura2.jpg`

### [ ] S175 · Araucária
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=araucaria`
- [ ] Card: the araucária of `praça_da_bandeira.jpg` and photos of old ones: the straight trunk, branches only at the top, the candelabra crown
- [ ] Round 1 · form: young (conical) and old (flat-topped) shapes, trunk heights
- [ ] Round 2 · structure: whorls of branches turning up at the ends, needle tufts at the tips, plate bark
- [ ] Round 3 · surface: dark green tufts, grey-brown bark plates
- [ ] Review: young and old at 10 m and 50 m

### [ ] S176 · Ipê and street trees
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=street_trees`
- [ ] Card: ipê amarelo and roxo in bloom, the broad street trees of the centre, the young trees in the square's beds
- [ ] Round 1 · form: crown shapes and sizes, trunks
- [ ] Round 2 · structure: branching, flower clusters, the petals' carpet on the ground (decals), tree guards
- [ ] Round 3 · surface: bark, the leaves' colour variation, the bloom against the sky
- [ ] Review: each at 10 m and in a street

### [ ] S177 · Shrubs and flowers
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=shrubs`
- [ ] Card: the hibiscus and quaresmeira of `mirante_entrance.jpg`, bougainvillea, clipped hedges, the Prefeitura's flower beds
- [ ] Round 1 · form: sizes and shapes, the hedge modules
- [ ] Round 2 · structure: flowers, branch structure, bed edges
- [ ] Round 3 · surface: the blooms' colours, dead leaves, overgrown versions
- [ ] Review: the Mirante gate's planting rebuilt beside the photo

### [ ] S178 · Atlantic forest wall
> needs: S141 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=forest`
- [ ] Card: the hill in `prefeitura1.jpg` and `prefeitura2.jpg`, the walls along the road in `mirante_street.jpg` and `mirante_entrance.jpg`: emergent trees, embaúbas with silver leaves, palms, tree ferns, lianas, undergrowth
- [ ] Round 1 · form: the layers (emergent, canopy, understorey, ground) and the hill's silhouette
- [ ] Round 2 · structure: each plant kind as a model: embaúba, palmito palm, tree fern, a canopy tree, hanging lianas, bromeliads on the trunks, ferns and grasses below
- [ ] Round 3 · surface: the many greens, the dark under the canopy
- [ ] Round 4 · distance: near models, middle cards, the far silhouette, the joins invisible; mist between the trunks at night
- [ ] Review: the road views and the hill from the Prefeitura beside the photos

### [ ] S179 · Vehicle kit
> needs: S141 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=vehicle_kit`
- [ ] Card: what every vehicle shares, so each vehicle step is only its body: references of wheels, lamps, Mercosul plates, interiors, wrecks
- [ ] Round 1 · form: a test car built from the kit: wheels, glass, lights, plates, mirrors
- [ ] Round 2 · structure: rims (steel, alloy) with tyres whose tread and sidewall lettering show, hubcaps; headlamp and tail clusters with emission and indicators that blink for the hazard state; Mercosul plates with the BRASIL band and seeded letters; door seams and handles cut as parts so doors open; seats, dash and steering wheel
- [ ] Round 3 · surface: the state generator on the test car: dust, smashed (dents, cracked and shattered glass), burnt shell (no tyres, brown-black metal, soot), rolled; flat and missing wheels
- [ ] Review: the test car in every state at 1 m and 10 m

### [ ] S180 · Hatchback and sedan
> needs: S179 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=cars`
- [ ] Card: photos of the commonest compact hatchback and mid sedan on Brazilian streets (no badges, no brand's shapes copied)
- [ ] Round 1 · form: proportions, the glasshouse, the wheel arches
- [ ] Round 2 · structure: bumpers, grilles, lamps, door lines, mirrors, roof rails
- [ ] Round 3 · surface: paint colours by seed, chips and scratches, mud on the sills
- [ ] Round 4 · variants: a white taxi with its roof sign and door number, a Polícia Militar car with its livery and light bar
- [ ] Review: both bodies and the variants at 1 m and 10 m, in every state

### [ ] S181 · Pickup and van
> needs: S179 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=pickup_van`
- [ ] Card: a midsize double-cab pickup and a panel van
- [ ] Round 1 · form: proportions, the bed, the van's box
- [ ] Round 2 · structure: bed rails, tow hitch, roof rack, sliding door, rear doors
- [ ] Round 3 · surface: work dirt; ladders and tool boxes as variants
- [ ] Review: at 1 m and 10 m in every state

### [ ] S182 · Ambulance
> needs: S179, S181 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=ambulance`
- [ ] Card: photos of SAMU 192 ambulances
- [ ] Round 1 · form: the van with its raised box
- [ ] Round 2 · structure: light bars, the rear doors open on the stretcher, the side door, the inside (stretcher, cabinets, oxygen)
- [ ] Round 3 · surface: the livery and lettering, reflective stripes, blood inside
- [ ] Review: doors open and shut, lights on, at 1 m and 10 m

### [ ] S183 · Motorbike
> needs: S179 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=motorbike`
- [ ] Card: the common 150 cc commuter bike, and a delivery bike with its box
- [ ] Round 1 · form: frame, tank, seat, wheels
- [ ] Round 2 · structure: forks, chain, exhaust, mirrors, lights, the delivery box
- [ ] Round 3 · surface: a worn seat, scratches, dirt
- [ ] States: on its stand, fallen, burnt
- [ ] Review: at 1 m and 10 m

### [ ] S184 · Evacuation remains
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=remains`
- [ ] Card: suitcases (hard and soft), prams, shoes, piles of clothes, supermarket trolleys, a teddy bear, mattresses roped to roofs, water bottles, plastic chairs, a small aluminium boat
- [ ] Round 1 · form: each at its real size
- [ ] Round 2 · structure: zips, wheels, handles, straps, the trolley's wire mesh, the bear's seams
- [ ] Round 3 · surface: dirt, rain stains, tears, blood on some
- [ ] Review: a spill along a car at 1 m

### [ ] S185 · Barricades and checkpoint gear
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=checkpoint`
- [ ] Card: concrete New Jersey barriers, sandbags, concertina wire on pickets, water-filled plastic barriers, cones, police tape, body bags, tarps (shared with the Batalhão)
- [ ] Round 1 · form: sizes, how sandbags stack and slump
- [ ] Round 2 · structure: the barriers' lifting slots and joints, sandbag seams and ties, the wire's coils and barbs, the tape's sag
- [ ] Round 3 · surface: stencils, spray paint, torn bags spilling sand, rust on the wire
- [ ] Review: a checkpoint of each at 1 m and 10 m

### [ ] S186 · Posters, flyers and painted words
> needs: S141 | size: S | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=decals`
- [ ] Card: spray-painted QUARENTENA, NÃO ENTRE, MORTOS DENTRO, arrows to ZONA SEGURA, missing-person flyers, official notices, old election posters
- [ ] Round 1 · form: sizes, and where they go (walls, shutters, cars, the road)
- [ ] Round 2 · structure: paint drips, layered and torn posters, tape holding the flyers
- [ ] Round 3 · surface: rain fading, sun bleaching, paint over paint
- [ ] Review: a wall of them at 1 m

### [ ] S187 · Praça da Bandeira monument
> needs: S141 | size: M | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=monument`
- [ ] Card: `praça_da_bandeira.jpg` and photos of the monument close up
- [ ] Round 1 · form: the column's height and section, the stepped plinth, the bronze group
- [ ] Round 2 · structure: the medallion, the inscriptions, the column's courses and capital, the plinth's steps and corner blocks
- [ ] Round 3 · surface: stone weathering, bronze patina with streaks, graffiti and a quarantine notice taped on
- [ ] Round 4 · figures: the bronze figures as low-poly sculptures that read as people from 10 m
- [ ] Review: from the photo's viewpoint and at 1 m

### [ ] S188 · The cathedral
> needs: S141 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=cathedral`
- [ ] Card: no photo yet: put photos of the cathedral on Rua do Príncipe in `references/elements/` first
- [ ] Round 1 · form: its silhouette and roof as seen from the street and from the hill
- [ ] Round 2 · structure: the facade's openings, the tower or cross, the doors and steps
- [ ] Round 3 · surface: the materials as in the photos, weathering
- [ ] Review: beside the photos at 10 m and 100 m

### [ ] S189 · Cemitério do Imigrante
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=cemetery`
- [ ] Card: photos of the immigrants' cemetery: old German gravestones, iron crosses, slabs, the gate and the wall
- [ ] Round 1 · form: the stones' shapes and sizes, their rows on the slope
- [ ] Round 2 · structure: carved lettering, the iron crosses' scrolls, the gate's bars and posts
- [ ] Round 3 · surface: lichen, tilt and cracks, rust
- [ ] Review: a row at 1 m and the slope at 30 m

### [ ] S190 · Zoobotânico gate and pond
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=zoo`
- [ ] Card: no photo yet: put photos of the Zoobotânico's gate and pond in `references/elements/` first; tile 1 shows its plan
- [ ] Round 1 · form: the gate, the pond's edge and the ring of paths
- [ ] Round 2 · structure: railings, signs, the pond's stones
- [ ] Round 3 · surface: water plants, moss, rust
- [ ] Review: beside the photos

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
- Shells, floors, rooms, stairs and nav only: the facades come from the kits (S157 to S164) and from each POI's own elements.

### [ ] S054 · Interior assembly kit
> needs: S053, S191, S192, S193, S194, S195, S196 | size: M | rounds: 2 | test: `tests/test_interior_kit.gd` | see: `--interior-rack`
- Assembly: rooms from data furnished with finished elements; nothing modelled here.
- [ ] Room kinds from data (office, ward, corridor, store room, barracks, hall), each furnished from the element families with seeded layouts
- [ ] Clutter generator per room kind (S196), seeded: papers, overturned chairs, blood, barricade attempts
- [ ] Locked door (needs a key, a crowbar, or damage) and a light switch as interactables (S191, S194)
- [ ] The elevator (S195) in the buildings' shafts, stuck between floors, doors that can be pried
- [ ] `--interior-rack`: one room of each kind
- [ ] Round 1 · layout: each room kind against photos of real ones
- [ ] Round 2 · story and light: clutter that tells what happened, the fittings' states
- [ ] Review: the six rooms at eye height

### [ ] S191 · Doors and frames
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=doors`
- The corridor's door (`door.gd`) is a box today; it moves to this kit with its hinge and states.
- [ ] Card: wooden swing doors, double doors, glass doors with push bars, fire doors with wired glass, roller shutters, frames and architraves, handles and locks
- [ ] Round 1 · form: sizes (0.8 to 0.9 m by 2.1 m, doubles, shop shutters), frame depths
- [ ] Round 2 · structure: panels, hinges, handles, kick plates, door closers, vision panels, push bars, locks, the shutter's slats and guides
- [ ] Round 3 · surface: worn paint round the handles, scuffs at the foot, signs (SAÍDA, PRIVATIVO), blood handprints
- [ ] States and parts: open, shut, locked (it rattles), splintered and broken in stages by the door's HP
- [ ] Review: each on the rack at 1 m, and the corridor's door in its four states

### [ ] S192 · Stairs, railings, ceilings and floors
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=stairs`
- [ ] Card: the concrete stairs of public buildings, steel tube handrails, glass and concrete balustrades, suspended ceilings, granilite and tile floors
- [ ] Round 1 · form: straight and dog-leg flights to the building pipeline's floor heights, landings, nosings
- [ ] Round 2 · structure: handrail brackets and ends, balusters, ceiling grids with tiles and light openings, skirting, floor joints
- [ ] Round 3 · surface: worn nosings, chipped paint, missing and hanging ceiling tiles, stains
- [ ] Review: a stairwell from bottom to top and a corridor ceiling at eye height

### [ ] S193 · Office and public furniture
> needs: S141 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=office`
- [ ] Card: desks with drawers, wheeled office chairs, filing cabinets, counters, shelves, computers and monitors, beam seating, a vending machine, a water cooler
- [ ] Round 1 · form: real sizes
- [ ] Round 2 · structure: drawers and handles, chair mechanisms and castors, cabinet labels, cables, the vending machine's window and coils
- [ ] Round 3 · surface: laminate wear, coffee rings, stickers, papers on the desks
- [ ] States: knocked over, ransacked, smashed
- [ ] Review: an office corner at eye height

### [ ] S194 · Light fittings and signs
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=fittings`
- [ ] Card: recessed and hanging tube fixtures, emergency lights, exit signs (the green running figure), switches, fire alarm points, extinguishers
- [ ] Round 1 · form: sizes and mountings
- [ ] Round 2 · structure: diffusers and bare tubes, chains and wires, the exit sign's box, switch plates
- [ ] Round 3 · surface: dead insects in the diffusers, yellowed plastic, dust
- [ ] States: lit, dead, flickering, hanging by one wire (the swing of S108)
- [ ] Review: a ceiling at night with every state

### [ ] S195 · Elevator
> needs: S141, S191 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=elevator`
- [ ] Card: a hospital elevator: the car, the landing doors, the shaft
- [ ] Round 1 · form: a car a bed fits in, the shaft and pit, landing doors
- [ ] Round 2 · structure: the car's panel, mirror and handrail, the door tracks and the gap to pry, guide rails, cables, the ladder in the shaft
- [ ] Round 3 · surface: brushed steel with scratches, grime in the tracks, the emergency light inside
- [ ] States: stuck between floors, doors pried apart
- [ ] Review: from the landing and from inside

### [ ] S196 · Clutter
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=clutter`
- [ ] Card: papers and folders, broken glass, food packaging, phones, cups, bags, a fallen picture frame, cables
- [ ] Round 1 · form: sizes, and how they lie on a floor
- [ ] Round 2 · structure: folded and crumpled papers, shards, packaging shapes
- [ ] Round 3 · surface: print as texture (no real brands), stains, blood
- [ ] Review: a floor of it at 1 m

### [ ] S055 · Barricades
> needs: S014, S054, S153 | size: M | test: `tests/test_barricade.gd`
- [ ] Barricade point on doors and windows: holds up to five planks
- [ ] Building: hold use, a plank from the inventory goes up with a hammer animation, three knocks, each plank at a slightly different angle
- [ ] Zombies attack it: planks crack, splinter and fly off one at a time, arms reach through the gaps
- [ ] Repair while it stands
- [ ] Shooting through the gaps works, planks are bullet cover otherwise
- [ ] Plank piles as pickups
- [ ] State through `get_state` / `apply_state`

### [ ] S197 · Terminal: roof slab and pleated fascia
> needs: S141 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_roof`
- The signature of the Terminal Central.
- [ ] Card: `terminal1.png` and `praça_da_bandeira.jpg` (and any other photo of the terminal): the slab's thickness at the edge, the soffit's curve, the pleats' width and depth, the cladding band under them, measured against the 12 m buses under it
- [ ] Round 1 · form: the two slab halves and the gap of the skylight between them, the soffit curving up from the edges, the run of pleated V plates along the square's front, the corrugated cladding band
- [ ] Round 2 · structure: drip edges, expansion joints every bay, gutters and downpipes at the columns, recessed light cans in the soffit, the pleats' seams and fixings
- [ ] Round 3 · surface: raw concrete with board marks, black water stains running from every joint, algae on the shaded edge, grime under the pleats, rust weeping from the brackets
- [ ] Round 4 · night: the soffit's lights (half dead), their pools on the wet setts (with S200), the stains still readable under them
- [ ] Review: both photos' viewpoints and the rack sheet

### [ ] S198 · Terminal: steel tree columns and trusses
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_columns`
- [ ] Card: the dark steel columns of `terminal1.png`: arms opening from a node into an X, on white concrete pedestals
- [ ] Round 1 · form: the X's height and spread, the pedestal, where the arms meet the slab
- [ ] Round 2 · structure: I-section members, gusset plates at the node, bolts, base plates, the trusses along the slab edges with their bracing
- [ ] Round 3 · surface: chipped black paint, rust at the bases, posters taped to the pedestals, bird mess
- [ ] Review: at 1 m and from the photo's viewpoint

### [ ] S199 · Terminal: the skylight
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_skylight`
- [ ] Card: the lit box frame hanging in the gap between the slab halves (`terminal1.png`, centre)
- [ ] Round 1 · form: the frame's size and depth, how it hangs
- [ ] Round 2 · structure: glass panes in frames, diagonal lattice members, fixtures inside, the hangers
- [ ] Round 3 · surface: dirty glass, dead insects, broken panes letting the rain through
- [ ] Night: the light from inside it (S108)
- [ ] Review: from below at the photo's viewpoint

### [ ] S200 · Terminal: platforms, bays and setts
> needs: S141 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_platforms`
- [ ] Card: the ground of `terminal1.png`: worn granite setts, raised platform islands with yellow kerbs, white concrete blocks at their ends, signs on poles
- [ ] Round 1 · form: the islands' heights and widths, bays long enough for 12 m buses, kerb radii
- [ ] Round 2 · structure: the setts' rows and worn joints, tactile strips, drainage channels with grates, bus stop poles with round signs, bay numbers, painted lines
- [ ] Round 3 · surface: oil stains in the bays, wet low spots (puddles for S110), gum and litter on the platforms
- [ ] Review: from the photo's viewpoint, wet

### [ ] S201 · Terminal: booths, turnstiles, kiosks and toilets
> needs: S141, S158 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_kiosks`
- [ ] Card: photos of the terminal's platform buildings: ticket booths, lines of turnstiles, snack kiosks, the toilet block
- [ ] Round 1 · form: sizes and their places on the islands
- [ ] Round 2 · structure: the booths' glass with speaking grilles and trays, turnstiles with card readers, the kiosks' counters and shutters, the toilet block's doors and vents
- [ ] Round 3 · surface: stickers, timetables, grime, graffiti
- [ ] States: shutters down, smashed, a turnstile torn out
- [ ] Review: a platform at eye height

### [ ] S202 · Terminal: route boards and wayfinding
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_signs`
- [ ] Card: the terminal's line boards and signs; the destinations are real Joinville neighbourhoods (Itaum, Vila Nova, Pirabeiraba, Boa Vista, Costa e Silva, Iririú, Comasa...)
- [ ] Round 1 · form: board sizes and heights, the platform letters
- [ ] Round 2 · structure: line numbers and destinations as lettering, the LED departure board, arrows, frames and hangers
- [ ] Round 3 · surface: faded print, the LED board dead or showing a last message
- [ ] Review: from the platforms at 5 m

### [ ] S203 · The yellow city bus
> needs: S179 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=bus`
- Joinville's buses are yellow (`terminal1.png`); they fill the terminal and the jams.
- [ ] Card: photos of the city's 12 m buses and the midibus (`terminal1.png`, right)
- [ ] Round 1 · form: the 12 m body, the big split windscreen, the doors' places; the midibus variant
- [ ] Round 2 · structure: the LED destination board, the headlamps and the black lower front, mirrors on arms, folding doors with rubber edges, sliding window panes, the wheels, the AC unit on the roof
- [ ] Round 3 · surface: the yellow livery with the line number, grime, stickers
- [ ] Round 4 · inside and states: seats in rows, yellow handrails and straps, the turnstile and fare box at the front, the driver's seat and dash, windows you see through; doors open with the lights on, crashed across a road, a burnt shell
- [ ] Review: from the viewpoint of `terminal1.png` and at 1 m outside and inside

### [ ] S056 · Terminal Central
> needs: S053, S048, S049, S197, S198, S199, S200, S201, S202, S203 | size: L | rounds: 3 | test: `tests/test_poi_terminal.gd` | see: `--mission=terminal --shot-at=2`
- Assembly of the finished elements on the terminal's traced footprint (`CityOsm`); nothing modelled here.
- [ ] The slab (S197) on its columns (S198) with the skylight (S199), over the platforms and bays (S200), the booths, kiosks and toilets (S201) and the boards (S202)
- [ ] Yellow city buses (S203): some in the bays, one jack-knifed across the exit, one with its doors open and lights on
- [ ] Lighting: cold tube lights under the slab, half dead, puddles catching them
- [ ] The square in front (S049) joined to it
- [ ] Player start on the platforms, first weapon spots, first ammo
- [ ] Round 1 · layout: the plan against the OSM footprint, bays and islands where the photo puts them
- [ ] Round 2 · photo match: `terminal1.png` and `praça_da_bandeira.jpg` rebuilt with `--shot-cam`, side by side
- [ ] Round 3 · light and rain: the night and the rain against `terminal1.png` (with S108 and S110 when they exist)
- [ ] Review: the photo match sheets

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

### [ ] S204 · Hospital: the old block
> needs: S141, S157 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_old`
- [ ] Card: `hospital2.png` (left): white, five floors, horizontal sunshade ledges, the entrance bay's tall dark fins flaring at the foot with beige bands, the name panel on the blank wall, the entrance stairs, the green canopy
- [ ] Round 1 · form: the block's proportions, the bay of fins, the ledges, the blank wall
- [ ] Round 2 · structure: each fin with its flare and bands, dark glazing behind, the ledges and their soffits, windows (S157), the entrance stairs with railings, the canopy, AC units
- [ ] Round 3 · surface: white paint with black water stains under the ledges, the hospital's name on its panel (no logo copied), grime at street level
- [ ] Round 4 · night and decay: dark windows with a few lit, smoke stains from a burnt floor (the blocked floors of S059)
- [ ] Review: the viewpoint of `hospital2.png` rebuilt, side by side

### [ ] S205 · Hospital: the middle block and the yellow house
> needs: S141, S157 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_middle`
- [ ] Card: `hospital2.png` (middle): four floors, cream walls, olive-green spandrel bands, recessed bays; the low yellow two-storey house with its canopy over the sidewalk
- [ ] Round 1 · form: both volumes and how they meet the old block
- [ ] Round 2 · structure: the spandrels, the window bays (S157), the house's windows, cornice and canopy
- [ ] Round 3 · surface: faded olive and cream, stains, the house's peeling yellow
- [ ] Review: the viewpoint of `hospital2.png`

### [ ] S206 · Hospital: the new tower
> needs: S141, S157 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_tower`
- [ ] Card: `hospital1.jpg` and `hospital2.png` (right): about twelve floors of white vertical volumes, blue glazing grids, a taller central core carrying the lit sign, a wing of white ribbon bands, plant on the roof and a red aircraft light
- [ ] Round 1 · form: the volumes' heights and widths, the core, the wing
- [ ] Round 2 · structure: the frames and mullions of the glazing, the ribbon bands, the sign's letters, the roof's plant, the canopy at the foot
- [ ] Round 3 · surface: white panels with joints, blue glass reflecting, stains
- [ ] Round 4 · night: the blue floodlight from below, the sign glowing, most windows dark and a few flickering (`hospital1.jpg`)
- [ ] Review: the viewpoint of `hospital1.jpg` at night, side by side

### [ ] S207 · Hospital: the street front
> needs: S141, S166 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_front`
- [ ] Card: `hospital1.jpg` and `hospital2.png`: the long drop-off canopy along Rua Blumenau, the ramp, the zebra crossing, the ambulance bay, the low wall and the lamps
- [ ] Round 1 · form: the canopy's length and height, the ramp's slope, the bay
- [ ] Round 2 · structure: the canopy's posts, glass and gutters, railings, bollards, signs (EMERGÊNCIA, ambulances only)
- [ ] Round 3 · surface: grime, blood trails into the entrance, triage leftovers
- [ ] Review: from the street at eye height and from the height of `hospital1.jpg`

### [ ] S208 · Hospital: rooftop helipad
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=helipad`
- [ ] Card: photos of rooftop helipads: the deck, the H in its circle, edge lights, safety netting, the windsock, the access stair
- [ ] Round 1 · form: the deck's size for the helicopter of S154, its height above the roof
- [ ] Round 2 · structure: the netting and its frame, edge lights, the windsock's mast, the stair and its gate, the fire hose box
- [ ] Round 3 · surface: worn paint, skid marks, rust on the frame
- [ ] Night: the edge lights (S108), the windsock's flood
- [ ] Review: from the stair and from the helicopter's approach

### [ ] S209 · Hospital: lobby and emergency room
> needs: S193, S194 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_er`
- [ ] Card: photos of a Brazilian hospital's reception and pronto-socorro: the desk, waiting chairs, triage, curtained bays
- [ ] Round 1 · form: the reception desk, the waiting rows, a curtained bay with its bed
- [ ] Round 2 · structure: curtain rails and curtains, ER beds with rails, monitors on arms, a crash cart, wall gas outlets, signs
- [ ] Round 3 · surface: blood, overturned chairs, scattered paperwork, a flickering monitor
- [ ] Review: the lobby and a bay at eye height

### [ ] S210 · Hospital: ward and corridor kit
> needs: S193, S194 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_ward`
- [ ] Card: ward rooms and corridors of a Brazilian hospital
- [ ] Round 1 · form: the ward bed, bedside cabinet, over-bed table, the room's window and door, the nurses' station
- [ ] Round 2 · structure: bed rails and controls, curtain tracks, the bed-head panel with gas outlets and the nurse call, corridor handrails and bumper rails, vision panels in the doors
- [ ] Round 3 · surface: stained sheets, a ward barricaded from outside, handprints on the glass
- [ ] Review: a corridor and a ward at eye height

### [ ] S211 · Hospital: medical props
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_props`
- [ ] Card: IV stands, wheelchairs, gurneys, oxygen cylinders, medicine cabinets, sharps bins, monitors on poles
- [ ] Round 1 · form: real sizes
- [ ] Round 2 · structure: castors and brakes, the gurney's frame and mattress, the cylinder's valve and trolley
- [ ] Round 3 · surface: chrome and plastic wear, blood, labels
- [ ] States: gurneys and wheelchairs piled up as a barricade
- [ ] Review: everything at 1 m

### [ ] S212 · Hospital: generator room
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=generator`
- [ ] Card: an emergency diesel generator set with its fuel tank and switchgear
- [ ] Round 1 · form: the set, the tank, the panels
- [ ] Round 2 · structure: the radiator grille, the exhaust pipe, cable trays, breakers and gauges, the start switch the players use
- [ ] Round 3 · surface: oil, warning signs, rust
- [ ] States: dead, and running (shaking, exhaust smoke, the lights coming on)
- [ ] Review: the room at eye height before and after the restart

### [ ] S058 · Hospital Dona Helena, outside
> needs: S053, S048, S182, S228, S204, S205, S206, S207, S208 | size: L | rounds: 3 | test: `tests/test_poi_hospital.gd` | see: `--mission=hospital --shot-at=2`
- Assembly on Rua Blumenau of the finished blocks and street front; nothing modelled here.
- [ ] The old block (S204), the middle block and the yellow house (S205), the new tower (S206), the street front (S207) and the helipad on the roof (S208), on their traced footprints
- [ ] Night look: the tower washed in blue floodlight from below, the sign glowing, most windows dark, a few flickering
- [ ] Street scene: abandoned ambulances (S182), triage tents (S228), a queue of cars that never got in (S048)
- [ ] Round 1 · layout: the blocks' places and heights against the OSM footprints and both photos
- [ ] Round 2 · photo match: `hospital1.jpg` (night, from above) and `hospital2.png` (the street) rebuilt, side by side
- [ ] Round 3 · story: the street reads as a hospital overrun
- [ ] Review: the photo match sheets

### [ ] S059 · Hospital, inside
> needs: S058, S054, S195, S209, S210, S211, S212 | size: L | rounds: 2 | test: `tests/test_poi_hospital_interior.gd` | see: `--mission=hospital --floor=3`
- [ ] Ground floor: the lobby and the emergency room (S209)
- [ ] Ward floors: a long corridor, rooms both sides (S210), a nurses' station, a store room with loot
- [ ] Not every floor is open: two are blocked by fire or collapse and are passed by the stairs
- [ ] Two stairwells (S192) and the elevator shaft (S195); the route forces a switch between them
- [ ] Power out: emergency lighting only
  - [ ] Red rotating beacons sweeping the corridors
  - [ ] Green exit signs (S194)
  - [ ] The generator room (S212): restart it to light a floor and call the elevator car
- [ ] Details: IV stands and gurneys used as barricades (S211), blood handprints on glass, a ward locked from the outside
- [ ] Nurse and doctor outfits weighted high here
- [ ] Round 1 · route: walked floor by floor, every room believable
- [ ] Round 2 · light: emergency lighting only, readable but dark
- [ ] Review: one shot per floor

### [ ] S060 · Mission: the hospital climb
> needs: S059, S022, S024 | size: M | test: `tests/test_mission_hospital.gd` | see: `--mission=hospital --bot`
- [ ] Start in the street, in through the emergency entrance
- [ ] Objectives: find the keycard, restart the generator, reach the roof, hold the helipad until the helicopter lands
- [ ] Zombies come up the stairwells behind the players and out of wards ahead
- [ ] Checkpoint at the mid floor
- [ ] Roof finale: wind, the city spread out below, the helicopter's light finding the pad
- [ ] Bot scenario finishes it on easy

### [ ] S213 · Prefeitura: the facade bay
> needs: S141, S157 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_bay`
- The long bar is one bay repeated: get one bay exactly right.
- [ ] Card: `prefeitura1.jpg` and `prefeitura2.jpg`: floor heights, the slab edges' depth, the window bands' height, the brick pilasters' spacing
- [ ] Round 1 · form: three floors of deep exposed concrete slab edges shading recessed ribbon windows, brick pilasters between, the salmon ground-floor wall
- [ ] Round 2 · structure: planters along the upper slab edge with plants spilling over, black window frames and their divisions, AC units on the slabs, the brick bond, rainwater pipes
- [ ] Round 3 · surface: weathered concrete with dark streaks, the salmon paint faded, moss in the planters
- [ ] Round 4 · decay: broken windows on the ground floor, barricade points (S055) in the openings
- [ ] Review: a run of bays from the viewpoint of `prefeitura1.jpg`, side by side

### [ ] S214 · Prefeitura: brick towers, buttresses and roof boxes
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_towers`
- [ ] Card: the two square red-brick stair towers with their pale band, the sloped brick buttresses at the base, the smaller brick boxes and the white machine room on the roof
- [ ] Round 1 · form: heights and plans, the buttresses' slopes
- [ ] Round 2 · structure: the brick bond, the band, vents and louvres, the buttresses' copings
- [ ] Round 3 · surface: the bricks' colour variation, efflorescence, moss at the foot
- [ ] Review: from the viewpoint of `prefeitura2.jpg`

### [ ] S215 · Prefeitura: space-frame panels
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_frames`
- [ ] Card: the blue steel lattice panels over the centre entrance and on the wings, and the tall lattice tower at the left corner
- [ ] Round 1 · form: panel sizes and how far they stand off the facade
- [ ] Round 2 · structure: tubes and nodes, the X lattice, the white edge members, brackets
- [ ] Round 3 · surface: faded blue paint, rust at the nodes
- [ ] Review: the entrance at eye height and from the photos' viewpoints

### [ ] S216 · Prefeitura: the roof
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_roof`
- [ ] Card: `prefeitura3.png` from above: a ribbed light-grey metal roof, plant boxes, the towers rising through
- [ ] Round 1 · form: the roof's plan and pitch over both wings
- [ ] Round 2 · structure: ribs, ridge, flashing round the towers, gutters, plant and vents
- [ ] Round 3 · surface: rust streaks, dirt in the ribs, patches
- [ ] Review: from the helicopter's height beside `prefeitura3.png`

### [ ] S217 · Prefeitura: the lawn mound
> needs: S141, S177 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_lawn`
- [ ] Card: `prefeitura1.jpg` and `prefeitura2.jpg`: the grass mound, brick stairs zigzagging up with dark steel pipe railings, curved brick-edged paths, flower beds, the concrete landing pad, the flagpoles at the entrance
- [ ] Round 1 · form: the mound's shape and height, the stairs' flights and landings, the paths
- [ ] Round 2 · structure: steps and edges, railings with posts and joints, bed edging, the pad's markings, flagpoles with three flags
- [ ] Round 3 · surface: worn brick, rust on the railings, overgrown grass, torn flags and a banner across the entrance
- [ ] Review: both photos' viewpoints, side by side

### [ ] S218 · Prefeitura: the letter sign
> needs: S141 | size: S | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_sign`
- [ ] Card: the blue panel with white letters reading Prefeitura Municipal de Joinville in its dark steel frame, set at an angle into the lawn
- [ ] Round 1 · form: length, height, the frame and its legs
- [ ] Round 2 · structure: letters as geometry, the frame's bars, lights at its foot
- [ ] Round 3 · surface: faded blue, dirty letters, one letter missing
- [ ] Review: from the avenue and at 1 m

### [ ] S219 · Prefeitura: main hall and council chamber
> needs: S192, S193 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_hall`
- [ ] Card: photos of the Prefeitura's hall and its council chamber (put them in `references/elements/` first)
- [ ] Round 1 · form: the hall's height, the wide stair, the chamber's tiers
- [ ] Round 2 · structure: the stair's balustrade, reception counters, the chamber's desks with microphones, the presiding table, flags and the coat of arms
- [ ] Round 3 · surface: polished floors scuffed, papers everywhere, barricade attempts
- [ ] Review: both rooms at eye height

### [ ] S061 · Prefeitura, outside
> needs: S053, S045, S047, S213, S214, S215, S216, S217, S218 | size: L | rounds: 3 | test: `tests/test_poi_prefeitura.gd` | see: `--mission=prefeitura --shot-at=2`
- Assembly between the river and the hill of the finished parts; nothing modelled here.
- [ ] The bar from its bays (S213), the towers and buttresses (S214), the space frames (S215), the roof (S216)
- [ ] The lawn mound (S217) with the letter sign (S218); the concrete pad on it is the landing zone
- [ ] Car parks on both sides (S048's cars), the riverside avenue and its palms in front (S045, S047), the forested hill rising behind (S178)
- [ ] Round 1 · layout: the plan against `prefeitura3.png` and the OSM footprint
- [ ] Round 2 · photo match: `prefeitura1.jpg` and `prefeitura2.jpg` rebuilt, side by side
- [ ] Round 3 · abandoned: the car parks jammed, the lawn overgrown, the flags torn, without losing the place
- [ ] Review: the photo match sheets

### [ ] S062 · Mission: hold the Prefeitura
> needs: S061, S054, S055, S023, S024, S219 | size: L | test: `tests/test_mission_prefeitura.gd` | see: `--mission=prefeitura --bot`
- [ ] Inside: main hall with a wide stair, council chamber, office wings, the brick stair towers, roof access
- [ ] Defend the hall: many windows and three doors to barricade, plank piles, ammo crate
- [ ] Three waves, each from more sides: the lawn, the car parks, then out of the forest behind
- [ ] Between waves: restock, repair
- [ ] Finale: fall back to the lawn pad, the helicopter lands among the horde
- [ ] Bot scenario survives on easy

### [ ] S063 · Mounted gun
> needs: S011, S004, S244 | size: M | test: `tests/test_mounted_gun.gd`
- [ ] Tripod machine gun as an interactable: use to man, use to leave
- [ ] Limited arc, heavy slow traverse, belt of its own ammo, overheats (barrel glows from dull red to orange, steam when it cools)
- [ ] Viewmodel: both hands on spade grips, the whole gun shudders, belt links and big casings pour out
- [ ] Heavy tracers every shot, large muzzle flash lighting the sandbags
- [ ] Host owns who mans it, the gunner is exposed from behind
- [ ] Bullets tear limbs off at any range

### [ ] S244 · Mounted machine gun model
> needs: S141, S142 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=mounted_gun`
- [ ] Card: a heavy machine gun on a tripod with spade grips (photos first)
- [ ] Round 1 · form: the receiver, the heavy barrel and its carrying handle, the tripod's legs and pintle, the spade grips, the ammo can on its tray
- [ ] Round 2 · structure: the feed cover and its latch, the barrel's cooling holes, the leaf and ladder sights, the traverse and elevation gear, the belt of linked rounds, the cocking handle
- [ ] Round 3 · surface: worn parkerising, oil, brass of the rounds, stencils on the can
- [ ] It sits in a sandbag nest from S185
- [ ] Review: the first-person manned view with the hands on the grips, and the rack

### [ ] S220 · Batalhão: barracks block
> needs: S141, S157 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_barracks`
- [ ] Card: `batalhao.jpg` and `batalhao2.jpg`: long low buildings with red clay-tile hip roofs round the parade ground, white walls, long words painted on one roof and 62 BI on the far one
- [ ] Round 1 · form: lengths, widths, roof pitches and hips, eave depths
- [ ] Round 2 · structure: tile rows with ridge and hip caps, eaves with fascia and gutters, windows and doors, a veranda where the photos show one
- [ ] Round 3 · surface: the tiles' colour variation, moss and lichen, white paint with stains, the roof lettering painted and weathered
- [ ] Review: from the viewpoint of `batalhao.jpg`

### [ ] S221 · Batalhão: the front building
> needs: S141, S157 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_front`
- [ ] Card: `batalhao.jpg` (front): two floors, green below and white above, the central portico with the entrance arch, the projecting gable wings
- [ ] Round 1 · form: the front's length, the portico, the wings, the roof
- [ ] Round 2 · structure: the arch and its pilasters, windows in frames, the cornice and the band between the colours, the gate under the arch
- [ ] Round 3 · surface: the green and white weathered, the army's insignia over the arch (simplified), stains
- [ ] Round 4 · battle: sandbags in the windows, bullet pocks, a burnt room
- [ ] Review: from the front lawn and from the height of `batalhao.jpg`

### [ ] S222 · Batalhão: parade ground and centre garden
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_ground`
- [ ] Card: the concrete slab grid with painted lines, the centre lawn with its monument and flagpoles (`batalhao.jpg`)
- [ ] Round 1 · form: the ground's size, the slabs, the garden
- [ ] Round 2 · structure: joints, painted lines and markers, the monument, flagpoles and their bases, kerbs
- [ ] Round 3 · surface: oil stains where vehicles stand, cracks with grass, faded paint
- [ ] Review: from above at the height of `batalhao.jpg`

### [ ] S223 · Batalhão: perimeter, gate and guard tower
> needs: S141, S185 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_gate`
- [ ] Card: the lot's wall with a fence on top, the main gate with its guard house and boom barrier, a guard tower with a searchlight, the front lawn's white star beds (`batalhao.jpg`)
- [ ] Round 1 · form: wall height, gate width, the tower's height and cabin
- [ ] Round 2 · structure: wall pillars and fence, the barrier's arm and post, the guard house's windows, the tower's ladder and rail, the searchlight's yoke, the star beds' white borders
- [ ] Round 3 · surface: stains, rust, the army's signs at the gate
- [ ] Review: from the street at eye height

### [ ] S224 · Batalhão: gym and sports court
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_gym`
- [ ] Card: the gym with its barrel-vault metal roof and red end wall, the green court beside it (`batalhao.jpg`, top left)
- [ ] Round 1 · form: the vault's span and length, the end walls, the court
- [ ] Round 2 · structure: the roof's ribs, the end walls' windows and doors, the court's lines, posts and nets
- [ ] Round 3 · surface: rust on the roof, the court's paint faded
- [ ] Review: from the viewpoint of `batalhao.jpg`

### [ ] S225 · Army truck
> needs: S179 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=army_truck`
- [ ] Card: photos of the Brazilian army's cargo trucks
- [ ] Round 1 · form: cab, chassis, the cargo bed under its canvas
- [ ] Round 2 · structure: the canvas hoops and straps, tailgate, spare wheel, jerrycans, bumpers, mirrors
- [ ] Round 3 · surface: olive drab, mud, stencils
- [ ] Review: at 1 m and 10 m in every state

### [ ] S226 · Light 4×4
> needs: S179 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=army_4x4`
- [ ] Card: photos of the Brazilian army's light 4×4 utility vehicles
- [ ] Round 1 · form: body, soft top or open, wheels
- [ ] Round 2 · structure: roll bar, gun mount, jerrycans, antennas, tow hooks
- [ ] Round 3 · surface: olive paint, mud, stencils
- [ ] Review: at 1 m and 10 m

### [ ] S227 · 6×6 armoured personnel carrier
> needs: S179 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=apc`
- [ ] Card: photos of the Brazilian army's 6×6 wheeled APC
- [ ] Round 1 · form: the faceted hull, six wheels, the turret
- [ ] Round 2 · structure: hatches, periscopes, the rear ramp, lights in their guards, smoke launchers, the turret's gun
- [ ] Round 3 · surface: camouflage, mud, scorch from a fire
- [ ] Review: at 1 m and 10 m, the ramp down

### [ ] S228 · Military camp gear
> needs: S141, S185 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=camp`
- [ ] Card: field tents, camouflage nets, ammunition crates, weapon racks, field radios, cots, jerrycans
- [ ] Round 1 · form: sizes
- [ ] Round 2 · structure: the tents' ropes, pegs and seams, the net's leaves, crate latches, the radio's knobs and handset
- [ ] Round 3 · surface: mud, stencils, wear
- [ ] Review: a corner of the camp at eye height

### [ ] S229 · Batalhão interiors
> needs: S191, S193 | size: L | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_rooms`
- [ ] Card: photos of barracks rooms, an armoury and a mess hall (put them in `references/elements/` first)
- [ ] Round 1 · form: the armoury's cage, rows of bunks and lockers, mess tables, the command room's desk and map wall
- [ ] Round 2 · structure: gun racks and their locks, bunk frames and mattresses, the lockers' vents and names, the radio set
- [ ] Round 3 · surface: order left in panic: kit spilled, beds overturned
- [ ] Review: each room at eye height

### [ ] S064 · 62º Batalhão, outside
> needs: S053, S048, S220, S221, S222, S223, S224, S225, S226, S227, S228 | size: L | rounds: 3 | test: `tests/test_poi_batalhao.gd` | see: `--mission=batalhao --shot-at=2`
- Assembly on Rua Ministro Calógeras of the finished parts; nothing modelled here.
- [ ] The quadrangle of barracks blocks (S220) round the parade ground and centre garden (S222), the front building (S221), the gym and court (S224), the field behind
- [ ] The perimeter, gate and guard tower (S223); the searchlight still turns
- [ ] Vehicles on the parade ground (S225, S226, S227), gun pits and tents (S228, S185)
- [ ] Round 1 · layout: the plan against `batalhao.jpg`, `batalhao2.jpg` and the OSM footprint
- [ ] Round 2 · photo match: both photos' viewpoints rebuilt, side by side
- [ ] Round 3 · the last stand: the base as its defenders left it
- [ ] Review: the photo match sheets

### [ ] S065 · Mission: hold the Batalhão
> needs: S064, S054, S063, S023, S024, S229, S244 | size: L | test: `tests/test_mission_batalhao.gd` | see: `--mission=batalhao --bot`
- [ ] Inside: armoury with ammo crates and gun racks behind a locked cage, barracks rows, mess hall, command room with the radio
- [ ] Objectives: get in through the gate, call the helicopter on the radio, open the armoury, hold the parade ground
- [ ] Mounted guns in the pits and on the tower
- [ ] Waves pour over the walls and through the gate; soldier zombies in the mix
- [ ] The helicopter lands in the middle of the parade ground
- [ ] Bot scenario survives on easy

### [ ] S230 · Mirante: the lookout tower
> needs: S141 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_tower`
- [ ] Card: no photo yet: put photos of the tower on the summit in `references/elements/` first and build nothing from memory (S066 waits on this too)
- [ ] Round 1 · form: height, plan, the deck, the way up inside
- [ ] Round 2 · structure: as in the photos
- [ ] Round 3 · surface: as in the photos, weathered by the summit's wind
- [ ] Round 4 · night and wind: its lights, the antennas' lights, cloud wisps through the deck
- [ ] Review: beside the photos

### [ ] S231 · Mirante: summit furniture
> needs: S141 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_summit`
- [ ] Card: coin binoculars, the summit's railings, a kiosk, antenna masts with red lights (photos first)
- [ ] Round 1 · form: sizes
- [ ] Round 2 · structure: the binoculars' head and coin box, railing posts, the masts' lattice and guy wires
- [ ] Round 3 · surface: weathering
- [ ] Review: the summit at eye height

### [ ] S232 · Mirante: the entrance portal
> needs: S141, S177 | size: L | rounds: 4 | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_gate`
- [ ] Card: `mirante_entrance.jpg`: two square board-formed concrete pillars, the lintel with MORRO DA BOA VISTA in green letters and the smaller line under it, the white butterfly canopy over the lanes, the guard booth with its terracotta top and shield, the red and white barrier, the yellow-kerbed island, the PARE barricade, cones, the green info totem
- [ ] Round 1 · form: the pillars' and the canopy's sizes against the car in the photo, the canopy's two wings
- [ ] Round 2 · structure: the canopy's thin edges and joints, the booth's window and door, the barrier's arm and post, kerbs, the totem
- [ ] Round 3 · surface: board marks and stains on the concrete, the lettering's paint, the canopy's dirty underside
- [ ] Round 4 · photo match: the viewpoint of `mirante_entrance.jpg` rebuilt, side by side
- [ ] Review: the photo match and the rack at 1 m

### [ ] S233 · Mirante: the hill road
> needs: S141, S167 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_road`
- [ ] Card: `mirante_street.jpg`: grey rectangular concrete pavers for the cars, a red brick walking lane in herringbone, a white line between them, kerbs, the grass verge, gutters
- [ ] Round 1 · form: lane widths, the line, kerb heights; modules that follow the road's curve and grade
- [ ] Round 2 · structure: the pavers' bonds and joints, gutters, guard rails on the outside of bends, the retaining wall uphill
- [ ] Round 3 · surface: moss in the joints, leaves, wet patches under the canopy
- [ ] Review: the viewpoint of `mirante_street.jpg` rebuilt

### [ ] S234 · Mirante: the trail
> needs: S141, S178 | size: M | rounds: 3 | test: `tests/test_elements.gd` | see: `--prop-rack=trail`
- [ ] Card: photos of the Trilha Rústica (put them in `references/elements/` first): dirt steps held by logs, roots, rocks, a rope rail
- [ ] Round 1 · form: the steps' heights, the path's width
- [ ] Round 2 · structure: logs and stakes, roots across the path, rocks, a fallen tree
- [ ] Round 3 · surface: mud, leaf litter, moss
- [ ] Review: walking it at eye height

### [ ] S066 · Mirante, the summit
> needs: S053, S047, S230, S231 | size: L | rounds: 2 | test: `tests/test_poi_mirante.gd` | see: `--mission=mirante --shot-at=2`
- [ ] The lookout tower (S230) and the summit's clearing with its furniture (S231): car park, railings, coin binoculars, a kiosk, antenna masts with red lights
- [ ] The view: the whole city backdrop below, lit windows, fires, the river as a pale line
- [ ] Wind up here: stronger sway, louder, cloud wisps passing through the deck at night
- [ ] Player start on the deck
- [ ] Round 1 · layout: the summit against its photos and `joinville_topography.png`
- [ ] Round 2 · the view: the city from the deck at night reads as Joinville
- [ ] Review: the deck's view and the photo match

### [ ] S067 · Mirante, the road down
> needs: S066, S041, S167, S178, S232, S233, S234 | size: L | rounds: 3 | test: `tests/test_poi_mirante_road.gd` | see: `--mission=mirante --shot-cam` on the hairpin
- [ ] The hill road (S233) along the traced road, the hairpin and the grade from `CityHeights`; everything placed with `map.ground_y`
- [ ] Forest walls both sides (S178), canopy closing overhead; concrete poles with their cables following the road (S167)
- [ ] The gate at the foot (S232)
- [ ] Side trail (S234) as a risky shortcut: no lamps
- [ ] A few lamps only, long dark stretches for flashlights
- [ ] Round 1 · layout: the road's line, width and grade against the topography
- [ ] Round 2 · photo match: `mirante_street.jpg` and `mirante_entrance.jpg` rebuilt, side by side
- [ ] Round 3 · night: the dark stretches, the few lamps, fog between the trunks
- [ ] Review: the photo match sheets and the hairpin at night

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

### [ ] S139 · Outfit details: uniforms
> needs: S137 | size: L | rounds: 3 | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=2`
- The nine outfits are plain colours per garment today. This step does the four uniforms; the civilians are S235.
- [ ] Card per uniform with photos of the real ones: the Santa Catarina military police, the army's field uniform, the firefighters (Corpo de Bombeiros), a prison uniform
- [ ] Round 1 · form: the garments' cut against the photos: pocket shapes, collars, belts with their gear, boots
- [ ] Round 2 · structure: patches and badges, name tapes, rank, epaulettes, button lines, zips, the firefighters' hi-vis reflective bands, cargo pockets with flaps, holsters and pouches on the belts
- [ ] Round 3 · surface: camouflage print, fabric weave, stitching, dirt, blood and tears that follow the seams
- [ ] Review: the outfit rack front and back at 1 m beside the photos

### [ ] S235 · Outfit details: civilians
> needs: S137 | size: L | rounds: 3 | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=1`
- [ ] Card: civilian, worker, office, nurse and doctor, with photos of each kind of clothing
- [ ] Round 1 · form: shirt and trouser cuts, collars and cuffs, the doctor's long coat, the nurse's scrubs, the worker's overalls
- [ ] Round 2 · structure: ties, lanyards with ID cards, a stethoscope, pens in pockets, aprons, tool belts, buttons, prints on t-shirts
- [ ] Round 3 · surface: patterns (stripes, checks, slogans), stains and wear, blood
- [ ] Review: the outfit rack front and back at 1 m

### [ ] S236 · Skirts and dresses
> needs: S137 | size: L | rounds: 3 | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=3`
- [ ] Card: skirts (straight, flared), dresses (shift, wrap), a nurse's dress, fitted like the other garments
- [ ] Round 1 · form: hem lengths, the waist, the flare; walk, run and crawl poses without cloth folding through the legs
- [ ] Round 2 · structure: hems, slits, pleats, belts, buttons
- [ ] Round 3 · surface: patterns (florals, plain, stripes), stains, torn hems
- [ ] Review: the sketch's poses and the outfit rack

### [ ] S237 · Blood that varies per zombie
> needs: S137 | size: L | rounds: 3 | test: `tests/test_outfit_models.gd` | see: `--host --zombie-rack=1`
- [ ] Card: how blood sits on clothes and skin: bites, wounds, feeding, drips
- [ ] Round 1 · form: placement chosen from the id: around the mouth and chest for feeders, from wounds downward with gravity, soaked cuffs
- [ ] Round 2 · structure: a second texture layer or decal mask so no two zombies of an outfit wear the same blood
- [ ] Round 3 · surface: wet and dry blood, dark edges, smears where hands wiped
- [ ] Review: a horde where every zombie of one outfit looks different

### [ ] S238 · Special body: bloater
> needs: S136 | size: L | rounds: 3 | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`
- [ ] Card: references of bloated bodies in fiction: a swollen torso and neck, a split shirt, pale green skin, veins
- [ ] Round 1 · form: the swollen belly and neck on the generic body's joints; it still bends and severs like the others
- [ ] Round 2 · structure: the split shirt (garment kit) straining over the belly, stretch marks, the navel, sores
- [ ] Round 3 · surface: blotched pale green skin, dark veins, a wet belly; the belly's pulse as a shape S076 drives
- [ ] Review: the rack front, side and back at 1 m

### [ ] S239 · Special body: spitter
> needs: S136 | size: L | rounds: 3 | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`
- [ ] Card: a long neck, a distended jaw, a burnt chest, thin limbs
- [ ] Round 1 · form: the neck's length, the hinged jaw, the thin limbs on the generic joints
- [ ] Round 2 · structure: the throat sac that bulges before a spit, ribs through the burnt chest, teeth
- [ ] Round 3 · surface: charred and blistered skin, a green-stained mouth
- [ ] Review: the rack front, side and back at 1 m

### [ ] S240 · Special body: brute
> needs: S136 | size: L | rounds: 3 | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`
- [ ] Card: a head taller, huge arms and shoulders, a small head, firefighter or riot gear fused into it
- [ ] Round 1 · form: proportions on scaled joints, the hitboxes S078 needs
- [ ] Round 2 · structure: armour plates as separate parts (each with its HP for S078), straps sunk into flesh, swollen veins, broken gear
- [ ] Round 3 · surface: skin and gear worn and burnt
- [ ] Review: the rack front, side and back at 1 m

### [ ] S241 · Special body: screamer
> needs: S136 | size: L | rounds: 3 | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`
- [ ] Card: gaunt, a torn hospital gown, the jaw unhinged, hands clawing at its own head
- [ ] Round 1 · form: the gaunt body, the dislocated jaw, long fingers
- [ ] Round 2 · structure: ribs and tendons, the gown's ties and tears, hair
- [ ] Round 3 · surface: pale bruised skin
- [ ] Review: the rack front, side and back at 1 m

### [ ] S242 · Special look: crawler
> needs: S136 | size: L | rounds: 3 | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`
- [ ] Card: a body without working legs: torn trousers, entrails dragging
- [ ] Round 1 · form: the mangled or missing legs, the torso low
- [ ] Round 2 · structure: torn trousers, entrails as a chain of segments that trail and swing
- [ ] Round 3 · surface: blood and dirt from dragging; the drag trail's decal
- [ ] Review: the rack front, side and back at 1 m

### [ ] S243 · Survivor models
> needs: S136, S137 | size: L | rounds: 4 | test: `tests/test_body_model.gd` | see: `--host --survivor-rack`
- [ ] Card: four distinct survivor looks, one per player slot, with living faces (photos of the kinds of clothing)
- [ ] Round 1 · form: four bodies and outfits from the garment kit: a tactical vest, a jacket, a hoodie, backpack straps
- [ ] Round 2 · structure: living faces (eyes, brows, a mouth that is not a zombie's), hair styles, pouches and gear
- [ ] Round 3 · surface: dirt, wear, blood from the fight
- [ ] Round 4 · first person: the sleeves of S142 match each look; the lobby's picker (S122) shows them
- [ ] Review: the survivor rack front and back at 1 m, and a remote player in play

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
> needs: S071, S242 | size: S | test: `tests/test_zombie_crawler.gd`
- [ ] Spawns legless: under cars, in stairwells, under beds
- [ ] Silent until close, grabs an ankle: the player is slowed until it is shoved or shot
- [ ] Hard to see: low, in the dark, flashlights help

### [ ] S076 · Bloater
> needs: S070, S004, S238 | size: M | test: `tests/test_zombie_bloater.gd` | see: `--zombie-rack=1`
- [ ] Slow waddle, gurgling
- [ ] Death or close contact: bursts
  - [ ] Belly swells for 0.4 s first as a warning
  - [ ] Wet explosion: chunks, a ring of bile on the floor, a green mist cloud that lingers
  - [ ] Damage and a knock-back in the radius, bile on the screen of players caught
- [ ] Bile puddle draws other zombies to it
- [ ] Kill it at range, or use it against a horde

### [ ] S077 · Spitter
> needs: S070, S004, S239 | size: M | test: `tests/test_zombie_spitter.gd`
- [ ] Keeps distance, climbs to high ground, strafes between spits
- [ ] Spit: rears the head back with a throat bulge, then a glowing green arc with a drip trail
- [ ] Lands as an acid pool: bubbles, steam wisps, eats HP while stood in, fades in seconds
- [ ] Host simulates the arc; clients get start, velocity and time
- [ ] Dies easily, flees when approached

### [ ] S078 · Brute
> needs: S070, S071, S240 | size: L | test: `tests/test_zombie_brute.gd`
- [ ] Armour plates on torso and arms as separate parts with their own HP; plates crack, then fly off, showing flesh
- [ ] Charge: lowers the shoulder, paws the ground, a straight run that throws players and zombies aside and ends in a stumble if it misses
- [ ] Smashes doors and barricades in one hit, flips small wrecks aside
- [ ] Ground slam at close range with a dust ring and a camera shake
- [ ] Weak spot: the head and the back after a missed charge
- [ ] At most one or two alive (director budget)

### [ ] S079 · Screamer
> needs: S070, S028, S241 | size: M | test: `tests/test_zombie_screamer.gd`
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
- [ ] Each weapon's model from its own element step (rounds 3), appended and done before this step; shown in the rack

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
- [ ] Each: `DEFS` entry, a model from its own element step (one appended per gun, rounds 3, before this step starts), handling poses, voice, balance sheet row

### [ ] S098 · Submachine guns
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] MP5: accurate, low recoil, the slap of the charging handle on reload
- [ ] Mac-10: very fast, wild spread
- [ ] Uzi: open bolt, top charging knob
- [ ] Vector: very fast, small magazine, low muzzle rise
- [ ] MP7 suppressed: quiet, low noise value
- [ ] Each: `DEFS` entry, a model from its own element step (one appended per gun, rounds 3, before this step starts), handling poses, voice, balance sheet row

### [ ] S099 · Rifles
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] Fire modes in `weapon_state.gd`: auto, semi, three-round burst, with a selector key and click
- [ ] M4A1, SCAR-H, FAL, G36, AUG (bullpup magazine behind the grip)
- [ ] A low-tier carbine as the first rifle players find
- [ ] Each: `DEFS` entry, a model from its own element step (one appended per gun, rounds 3, before this step starts), handling poses, voice, balance sheet row

### [ ] S100 · Shotguns
> needs: S013 | size: M | test: `tests/test_weapons.gd` | see: `--gun-rack`
- [ ] Double-barrel: two shots, both at once on the alternate trigger, break-open reload with two hulls popping out
- [ ] Sawn-off: sidearm slot, huge spread
- [ ] Mossberg pump
- [ ] Lever-action: lever loop swing between shots
- [ ] Slug rounds as a second ammo type for shotguns
- [ ] Each: `DEFS` entry, a model from its own element step (one appended per gun, rounds 3, before this step starts), handling poses, voice, balance sheet row

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
> needs: S121, S243 | size: L | test: `tests/test_lobby.gd` | see: `tools\play2.ps1`
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
