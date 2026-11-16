# Development

Draft backlog.
Legend: [x] exists, [ ] not built.

## Methods

1. [ ] **Building recreation pipeline** (Joinville POIs): take a footprint (traced from a map top view, saved as a point list in code), extrude to height, set floor count, facade/roof colours, window grid, door/entrance positions. Output: a `GameMap` built from `MeshKit` boxes, with navigation. One data dict per building, no imported assets.
2. [x] **Map data format**: one place that defines spawn points, extraction zones, doors, lootboxes, horde routes and objective rules, so a new map or mission is data, not code.
3. [x] **Mission rules in hooks**: `on_mission_started`, `on_objective_reached`, `on_extraction_ready`, `on_extracted`, `on_mission_failed` (host only, like the other hooks).
4. [x] **Sound pipeline**: procedural synthesis in `sfx.gd` (no files), one function per sound, with a cap on simultaneous voices and distance attenuation.
5. [x] **Balance sheet**: a test or tool that prints time-to-kill per gun against each zombie type, so tuning is by numbers.
6. [x] **Bot playtests**: `--bot` scenarios per mission (can the bot reach extraction?) run in the test suite.
7. [x] **Performance budget**: draw-call and zombie-count check per map in headless tests.

## Core game systems

- [ ] Extraction: zone, countdown, "all alive players inside" rule, win and fail screens.
- [ ] Defend objective: timer until the helicopter arrives, escalating hordes, helicopter fly-in.
- [x] Limited ammo, ammo pickups, reserve ammo per calibre (built; both maps still play with infinite ammo, try it with `--limited-ammo`).
- [ ] Loadout: carry 2-3 weapons instead of all nine, weapon pickups already exist (`weapon_pickup.gd`).
- [ ] Inventory: medkits, grenades, keys, barricade materials.
- [ ] Health: bleeding, healing items, downed state and revive by teammates.
- [ ] Respawn / spectator after death.
- [ ] Stamina for sprinting.
- [ ] Melee on every weapon (shove), plus dedicated melee weapons.
- [ ] Grenades and throwables (frag, molotov, flashbang, noise lure).
- [ ] Barricading doors and windows, repairable.
- [ ] Zombie types beyond walker / runner / leaper: bloater (explodes), spitter (ranged), brute (armour, charges), screamer (calls a horde), crawler (legless).
- [ ] Zombie climbing and vaulting.
- [ ] Noise system: gunshots attract zombies, silenced guns attract fewer.
- [ ] Difficulty setting and horde scaling per player count.
- [ ] Scoring: kills, headshots, time, shown on the end screen.
- [ ] Progression between missions (unlocked guns, attachments).
- [ ] Reload / aim animation on other players (already in "not built yet").

## Menus and UI

- [x] **Main menu**: All in one map screen: missions to select in the map, Start, training ground, Join, Quit. Settings still missing.
- [ ] **Mission select**: five Joinville missions with brief, difficulty and best time.
- [ ] **Pause menu** (Resume, Settings, Leave match). Does not pause the host's world in multiplayer.
- [ ] **Settings**: key bindings (`controls.gd`), mouse sensitivity, FOV, volume sliders, graphics quality, fps cap, show draws.
- [ ] **Lobby**: player list, ready state, mission and difficulty picked by host.
- [ ] **HUD**: ammo and reserve, weapon name, health, objective text and marker, compass, teammate names, kill feed, hit markers, damage direction indicator.
- [ ] End screen: extracted / failed, stats per player.
- [ ] Loading screen with a tip.

## Features

### Joinville City Center

- Not all of it: keep each map reduced to the POI surroundings.
- Streets, sidewalks, cars (wrecks as cover), lamp posts, bus stops, trash, barricades.
- Day / dusk / night variants, fog for cheap draw distance.
- Interiors only for the mission buildings; other buildings are solid blocks with doors that do not open.
- Zombie spawn points hidden behind corners, never in sight.

### City POI missions

- [ ] Dona Helena Hospital: start at the street and extract at the top (rooftop helipad). Idea: stairs and elevator shaft, nurses and doctors outfits already exist.
- [ ] Mirante de Joinville: start at the top and extract at the bottom. Idea: descent through the tower, narrow stairs, leapers in tight spaces.
- [ ] Terminal Central: start at the bus station and extract at the city Prefecture. Idea: long street run with a mid-point checkpoint.
- [ ] Prefeitura da Cidade de Joinville: defend the prefecture until the helicopter arrives. Idea: barricade windows, three-wave horde.
- [ ] 62° Batalhão de Infantaria: defend the military post until the helicopter arrives. Idea: soldier zombies, ammo crates, mounted position.
- [ ] Keep the current corridor map as the training / test mission.

### Light effects

- [ ] Muzzle flash light (short, only on the shooter's gun, no shadows).
- [ ] Flashlight on the player (toggle, shadow casting only for the local player).
- [ ] Flickering lamps, emergency red lights in the hospital.
- [ ] Fire from molotovs and burning zombies.
- [ ] Helicopter searchlight on extraction.
- [ ] Muzzle smoke, bullet tracers, shell casings, impact dust per surface.
- [ ] Dust and volumetric fog in interiors.
- [ ] Rule: only two shadow-casting lamps at a time (performance).

### Sound effects

- [ ] Per-gun gunshots (pitch / length by calibre), suppressed variants, dry fire click.
- [ ] Reload: mag out, mag in, bolt, pump shell.
- [ ] Footsteps by surface, sprint breathing, low-hp heartbeat.
- [ ] Zombie groans, runner screeches, leaper snarl, per-type death, limb tear, squelch.
- [ ] Doors: open, close, break. Lootbox open, pickup.
- [ ] Horde warning siren, helicopter approach, extraction countdown beeps.
- [ ] Ambient: wind, distant gunfire, city hum.
- [ ] Positional audio for teammates and zombies.

### Gun models

Existing (nine, in `weapons.gd`): [x] P19 (pistol), [x] P90, [x] Type 95, [x] AK47, [x] AS Val, [x] USAS-12, [x] SPAS-12, [x] Orsis T-5000, [x] Dragunov.

Missing slots to consider: a rifle/carbine at a lower tier, an LMG, and everything below.

#### White Weapons

1. [ ] Combat knife: fast, quiet, short reach.
2. [ ] Baseball bat: stagger on hit, knocks back.
3. [ ] Fire axe: slow, severs limbs, can break doors.
4. [ ] Machete: fast, good limb severing.
5. [ ] Crowbar: opens locked vaults and doors, medium damage.
6. [ ] Katana (rare): fast, high damage, rare lootbox drop.
7. [ ] Sledgehammer: very slow, huge stagger, can break doors.
8. [ ] Shovel / pipe / frying pan: junk melee with low durability.

#### Pistols

[x] P19. Ideas: Desert Eagle (heavy, 7 rounds), revolver (6 shots, slow reload), Glock 18 (auto, high fire rate), flare gun (lights targets, sets fire).

#### Submachines

[x] P90. Ideas: MP5 (accurate, low recoil), Mac-10 (very fast, wild spread), Uzi, Vector (very fast, small mag), suppressed MP7.

#### Assault rifles

[x] AK47, [x] Type 95. Ideas: M4A1, SCAR-H, FAL, G36, AUG, burst-fire rifle.

#### Shotguns

[x] SPAS-12, [x] USAS-12. Ideas: double-barrel (two shots, huge damage), sawn-off, Mossberg pump, lever-action.

#### Sniper / marksman rifles

[x] Orsis T-5000, [x] Dragunov. Ideas: M14 EBR, Barrett .50 (penetrates multiple zombies), lever-action hunting rifle.

#### Heavy

- [ ] LMG (M249 / PKM): big mag, slow aim.
- [ ] Minigun (rare, slows the player).
- [ ] Grenade launcher, RPG (limited rounds, break doors and walls).
- [ ] Flamethrower (fire damage over time, short range).
- [ ] Crossbow (silent, retrievable bolts).

#### Attachments

- [ ] Suppressor, red dot, scope, extended mag, laser, grip, flashlight.

## Ideas

- Companion survivors (AI).
- Co-op revive.
- Vehicles for the Terminal Central run.
- Weather (rain muffles sound and adds fog).
- Daily random modifiers (fast zombies, low ammo, night only).
- Replay or killcam.
