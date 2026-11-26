# Make Alive · Management Dashboard

The master plan. Everything the game will have, from a gun's scope glint to snow settling on the roofs, as a tree of four levels:

1. **Phase**: what the game is when it is done (`# 1 · Game is structured`).
2. **Area**: one question about it (`## 1.1 · Zombie animation and bodies`, with the question under it).
3. **Item**: one piece of work one agent can finish in one session (`### [ ] 1.1.14 · Getting up from the ground`). Items are what the roadmap called steps and keep their ids (`S260`).
4. **Detail**: what the item must have, each ticked on its own (`- [ ] 1.1.14.2 · Rise in stages ... #anim`).

Every node carries tags (`#perf`, `#sound`, ...): pick a tag and work through it across the whole plan. `python tools/dashboard.py` checks this file and draws the dashboard (`references/dashboard.html`, also published as an artifact).

**Direction (26 Nov 2026): five maps, not a city.** Building and running the whole town is not feasible, so each mission is its own map: its POI and the streets round it (S051), dressed with the element library that already exists (S247, S249). The rest of the town is backdrop. The town in detail everywhere waits in 3.5 until the five maps ship. The sets built on the old real-Joinville look (the Mirante, the Prefeitura and the Hospital, PRs 2 to 7) are the starting point of each area's first playable item (S250 to S254), not thrown away.

## How to use this file

- **Pick:** an item that is `[ ]` or `[~]` and whose `needs` are all done (`python tools/dashboard.py --next`, or `--next --tag=#perf` for one tag). One item per session. S247, S248 and S051 go first, then the five areas' first playable items (S250 to S254), then S255 and S258.
- **Do:** follow `CLAUDE.md` (failing test first, numbers in `Config`, gameplay reactions in `hooks.gd`, host decides, gore is local, everything is code).
- **Prove:** the item's `test` passes in the whole suite and the `see` command's screenshots were read. An item with `rounds` has every round written on its element's card.
- **Close:** tick each detail when done, tick the item when all are (`[~]` while some are), run `python tools/dashboard.py --renumber` if items moved, commit. Update `CLAUDE.md` and `TODO.md` when an item changes them.
- **Verify:** an item that makes anything to look at or listen to adds its checks to `VERIFY.md` (only a person ticks a check).
- **Add:** a new item gets the next free id (`--next-id`), its area, its tags and its details. Never reuse or change an id; display numbers may change.

## Format (the dashboard script reads this)

- `# N · name` is a phase, followed by one line of what it means.
- `## N.M · name` is an area; the line under it starting `?` is its question; `> tags: ...` its tags.
- `### [ ] N.M.K · name` is an item (`[x]` done, `[~]` started). The `> ` line under it is its data: `id`, `from` (the roadmap step it was split from), `needs` (ids), `size` (S, M, L), `asset` (complex, simple), `rounds`, `tags`, `test`, `see`, separated by ` | `.
- `- [ ] N.M.K.D · text #tag` is a detail; an indented `- [ ]` is a sub-detail; a plain `- ` bullet is a spec note of the node above it.
- Tags: `#art` models, kits, materials, the look of a thing, `#anim` poses, rigs, animation, `#ai` how zombies and companions think and move, `#gameplay` rules, numbers, what players do, `#map` maps, areas, places, layout, navigation, `#weapon` guns, melee, throwables, attachments, `#vfx` particles, light, weather, post, gore, `#sound` sound effects, voices, ambience, music, `#ui` HUD, menus, screens, icons, `#net` host and peers, snapshots, LAN, `#perf` frame rate, budgets, LOD, culling, memory, `#tool` tools, tests, pipelines, review sheets, `#loot` loot, containers, items, resources, `#progression` unlocks, skills, levels, profiles, `#base` safe houses, bases, crafting, `#story` scatter that tells what happened.

## Rules every item obeys

- **A French town on Joinville's plan:** Joinville is the plan, not the look. `references/joinville.png`, the OpenStreetMap tiles `references/1.png` to `9.png` and `joinville_topography.png` give the bones: the river's line, the hill and its height, where the five places stand, the streets, how dense each part is. The streets are Joinville's own, traced off the map (S040: the main ones where its bus routes run), and everything people see is dressed as a French town in the style of Paris around 1800, before Haussmann: narrow crooked streets of setts between tall plastered houses with shutters, mansards and chimney stacks, timber-framed houses in the old core, quays along the river, a few post-war blocks at the edge. Life is today's (cars, buses, a hospital tower, an army), set in that old fabric. Every name, sign and word on a wall is French. The Joinville photos (`terminal1.png`, `hospital*.png`, `prefeitura*.jpg`, `batalhao*.jpg`, `mirante_*.jpg`, `praça_da_bandeira.jpg`) give only arrangement and scale; no building, sign or name is copied from them, and every name is invented. Only the five POIs have interiors. Every other building is a solid block with a believable facade and doors that do not open.
- **Five maps:** a mission builds only its area (S051). Nothing in the street and building areas (1.2 to 1.5) is built town-wide any more: every such item works inside the mission areas, and the town-wide part is S259 (3.5).
- **Budget:** 144 fps on a laptop. Two shadow-casting lamps. Every effect has a cap in `Config` and a pool. Watch "draws".
- **Network:** new effects travel as *what happened* (kind, position, direction, one argument), never as particles or physics. Zombie snapshots stay 13 bytes each unless the step says otherwise and the packet test still passes.
- **Looks are deterministic:** seeded from ids or the map's own RNG, never `randf`, so every peer sees the same city.
- **Animation:** poses are goals the rig eases toward (`Humanoid.Anim`, `_write_goal`) and viewmodel weights 0..1. No direct joint or pivot writes.

## Detail and iteration

- **The bar is the zombies, not the boxes.** Everything on screen is made to the level of the zombie bodies and outfits (S136, S137): low-poly and flat-shaded, but every form that catches light is modelled (chamfers, lips, frames, seams, bolts, hinges, handles), proportions are measured from references, and surfaces carry baked shading, wear, dirt and lettering. Plain boxes are a blockout, never a result. The gap today: the first-person hands are two boxes per arm, next to zombies with knuckles and nails.
- **One element, one step.** An agent given one well-bounded thing (the street signs) does it well; given "make the city detailed" it makes garbage. An element step makes one element, or one small family that shares one design. Assembly steps place finished elements. A step that would model two unrelated things is split, and the new part appended as a new step.
- **References first.** Read every reference the step names before any geometry. Where `references/` has nothing for the element, put at least two photos of real French examples (old Paris first) in `references/elements/` first (from the user, or found, with the source on the card). Never model from memory.
- **The card.** Every element has `references/elements/<name>.md` (from `_template.md`): its references, its measurements in metres taken against something of known size (a 2.1 m door, a 12 m bus, a 15 cm kerb, a 1.75 m person), every visible detail as a list, the materials, the triangle budget per LOD, the moving parts, the states (clean, abandoned, damaged, burnt), and one section per round.
- **The workflow.** `references/elements/WORKFLOW.md`: references and the scale, a blockout matched against straightened photos (`tools/models/match.py`, seconds a loop) before anything is built, then the rounds below, with a checklist per round.
- **The loop.** A round: shoot the review sheet (`python tools/models/review.py <name> --round=N`: the rack's eight angles, a 1 m close-up, 10 m and 50 m, beside the references), write on the card every difference from the references, fix them, write what was fixed. Round 1 is form (silhouette, proportions, real size), Round 2 structure (the secondary forms), Round 3 surface (wear, lettering, colour variation, states); later rounds are named in the step. A round with nothing written down does not count. The step is done when the last round's list is empty, or each leftover is marked accepted with a reason. The final sheet is shown in chat.
- **Style match for places.** Assembly steps shoot fixed viewpoints with `--shot-cam` and review each screenshot beside the French references on the place's card, round by round, the same way. They are never rebuilt to match a Joinville photo.
- **The data says it.** Element and assembly steps carry `rounds: N` and the features `Round 1` .. `Round N` and `Review`; `python tools/steps_map.py --check` fails a step that names rounds without them.
- **Budgets hold.** Detail lives in silhouettes and baked textures, not in triangle soup: LODs, draw calls and triangles per LOD are on the card and checked by `tests/test_elements.gd`; repeated elements are instanced.
- **Asset grade.** Every step that makes an asset (an element, a kit, a model) says `asset: complex` or `asset: simple`; assembly steps that only place finished elements carry none.
  - `complex`: organic or deforming (skinned bodies, cloth, foliage), several linked moving parts or seen up close in first person (guns, hands, vehicles, the elevator), a whole building, room or structure fitted to the map's own data (streets, river, terrain, catenaries), or a parametric kit many other elements build on (windows, shopfronts, roofs, vehicles).
  - `simple`: a rigid object or a small family of rigid objects built from the kit's helpers, with at most one moving part, or a variant of a finished kit (the ambulance on the van).
  - A new asset step is graded when it is appended. `python tools/steps_map.py --stats` counts both.
- **Later items too.** Every gun in 2.5 carries its own model rounds (card, Round 1 to 3, review) beside its gameplay, sound, attachments and render budget; melee weapons get an element item each before their gameplay item starts. Effects and surfaces (2.1) take rounds the same way on their racks when they are started.




---

# 1 · Game is structured

Everything a match needs exists: the zombies move like the dead, the five maps are built and dressed, the survival loop and the missions work.

## 1.1 · Zombie animation and bodies
? Do we have enough animations for zombies that lie on the ground then get up, that seem organic, that eat corpses, and corpses for devastated towns?
> tags: #anim #art

### [x] 1.1.1 · Low-poly bodies and skeleton
> id: S136 | needs: none | size: L | asset: complex | tags: #anim #art | test: `tests/test_body_model.gd` | see: `--host --body-rack`

- [x] 1.1.1.1 · `tools/models/poly.py`: low-poly kit, rings lofted into flat-shaded prisms, a tag per face ✅ #sound
- [x] 1.1.1.2 · `tools/models/measure.py`: proportions, face layout and colours read off `references/zombies.png` ✅
- [x] 1.1.1.3 · Generic male and female bodies (`body.py`): one closed piece per joint, shoulder ledge, torso break that bends closed ✅
  - [x] Faceted head: sunk sockets, V brow, glowing slit eyes, downturned mouth with teeth ✅
  - [x] Bone stubs in the wounds a severed part shows ✅
- [x] 1.1.1.4 · Skeleton model on the same joints, fitted inside the male body (`skeleton.py`) ✅
- [x] 1.1.1.5 · `CharacterModel` loads a .glb, binds it to the game's joints, cuts a rigid copy per segment for gibs and ragdolls ✅
- [x] 1.1.1.6 · The old SDF cop model removed ✅

### [x] 1.1.2 · Outfit models
> id: S137 | needs: S136 | size: L | asset: complex | tags: #anim #art | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=1`

- [x] 1.1.2.1 · Garment kit `tools/models/clothes.py`, fitted by slicing the body ✅
  - [x] Shirts and jackets: long, short or no sleeves; crew, collar or high neck; tucked or over the trousers; open front ✅
  - [x] Trousers and shorts with an optional belt ✅
  - [x] Shoes, sneakers, boots ✅
  - [x] Headgear: police cap, hard hat, helmet, fire helmet, nurse's cap ✅
- [x] 1.1.2.2 · One continuous surface per garment: sleeves out of the armhole, legs out of the seat, no break at any joint ✅
- [x] 1.1.2.3 · Helper bones turning half as far as each limb joint, so cloth bends without pinching ✅
- [x] 1.1.2.4 · Pieces cut below each joint, closed by wounds; piece ids in the .glb's second UV channel ✅
- [x] 1.1.2.5 · Nine outfits on the male and the female body (18 models), plain colours, worn by every walking zombie ✅
- [x] 1.1.2.6 · Sex picked from the id per outfit (`Characters.FEMALE_SHARE`) ✅
- [x] 1.1.2.7 · Tools: `outfits.py --sketch` (posed previews without Blender), `--folds`, `--outfit-rack`, `--rack-sever` ✅

### [~] 1.1.3 · Bite variants
> id: S138 | needs: S137 | size: L | asset: complex | tags: #anim #art | test: `tests/test_bite_variants.gd` | see: `python tools/models/outfits.py --bites nurse --f`

- Agent: Opus 5.5 at effort max. Geometry-heavy work with many look-and-fix rounds; it needs the whole pipeline (body, skeleton, clothes, rig, piece cuts) in its head at once. Plan first, then build one bite end to end before the other nine.
- [ ] 1.1.3.1 · Optimized variant producer in `tools/models/`: from one outfit and body, many variants that share what they can
  - [ ] Clothes swaps per variant (sleeve length, open or closed, hat or none, colour sets)
  - [x] Variants picked from the zombie id, the same on every peer; the wire unchanged
  - [x] Budget: triangles and texture memory per variant kept close to the plain model, loading stays before the first spawn
- [x] 1.1.3.2 · Ten bites, each a named region torn out of flesh and clothes together, e.g.
  - [x] Left or right side of the abdomen, left or right lower ribs, upper chest, shoulder, upper arm, forearm, thigh, calf, neck and jaw
  - [x] The hole cuts the body and every garment over it, with a torn ragged edge (not a clean cut) and blood-dark rims
  - [x] Only that region's bones show under it (a few ribs, the radius and ulna, a length of femur, a piece of spine), never the whole skeleton model
  - [x] Inside the hole: wound flesh, the bone section, depth, so no see-through; the piece it belongs to stays closed for gibs
- [x] 1.1.3.3 · Bites survive the existing rules: helpers bend them, they come off with their piece, stumps still close
- [ ] 1.1.3.4 · Contact sheet of every bone, clothes and body variant of the female nurse in one isometric picture, shown in chat when done

### [ ] 1.1.4 · Outfit details: uniforms
> id: S139 | needs: S137 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=2`

- The nine outfits are plain colours per garment today. This step does the four uniforms; the civilians are S235.
- [ ] 1.1.4.1 · Card per uniform with photos of the real ones: the Santa Catarina military police, the army's field uniform, the firefighters (Corpo de Bombeiros), a prison uniform
- [ ] 1.1.4.2 · Round 1 · form: the garments' cut against the photos: pocket shapes, collars, belts with their gear, boots
- [ ] 1.1.4.3 · Round 2 · structure: patches and badges, name tapes, rank, epaulettes, button lines, zips, the firefighters' hi-vis reflective bands, cargo pockets with flaps, holsters and pouches on the belts
- [ ] 1.1.4.4 · Round 3 · surface: camouflage print, fabric weave, stitching, dirt, blood and tears that follow the seams #vfx
- [ ] 1.1.4.5 · Review: the outfit rack front and back at 1 m beside the photos

### [ ] 1.1.5 · Outfit details: civilians
> id: S235 | needs: S137 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=1`

- [ ] 1.1.5.1 · Card: civilian, worker, office, nurse and doctor, with photos of each kind of clothing
- [ ] 1.1.5.2 · Round 1 · form: shirt and trouser cuts, collars and cuffs, the doctor's long coat, the nurse's scrubs, the worker's overalls
- [ ] 1.1.5.3 · Round 2 · structure: ties, lanyards with ID cards, a stethoscope, pens in pockets, aprons, tool belts, buttons, prints on t-shirts
- [ ] 1.1.5.4 · Round 3 · surface: patterns (stripes, checks, slogans), stains and wear, blood #vfx
- [ ] 1.1.5.5 · Review: the outfit rack front and back at 1 m

### [ ] 1.1.6 · Skirts and dresses
> id: S236 | needs: S137 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_outfit_models.gd` | see: `--host --outfit-rack=3`

- [ ] 1.1.6.1 · Card: skirts (straight, flared), dresses (shift, wrap), a nurse's dress, fitted like the other garments
- [ ] 1.1.6.2 · Round 1 · form: hem lengths, the waist, the flare; walk, run and crawl poses without cloth folding through the legs
- [ ] 1.1.6.3 · Round 2 · structure: hems, slits, pleats, belts, buttons
- [ ] 1.1.6.4 · Round 3 · surface: patterns (florals, plain, stripes), stains, torn hems
- [ ] 1.1.6.5 · Review: the sketch's poses and the outfit rack

### [ ] 1.1.7 · Blood that varies per zombie
> id: S237 | needs: S137 | size: L | asset: complex | rounds: 3 | tags: #anim #art #vfx | test: `tests/test_outfit_models.gd` | see: `--host --zombie-rack=1`

- [ ] 1.1.7.1 · Card: how blood sits on clothes and skin: bites, wounds, feeding, drips
- [ ] 1.1.7.2 · Round 1 · form: placement chosen from the id: around the mouth and chest for feeders, from wounds downward with gravity, soaked cuffs
- [ ] 1.1.7.3 · Round 2 · structure: a second texture layer or decal mask so no two zombies of an outfit wear the same blood
- [ ] 1.1.7.4 · Round 3 · surface: wet and dry blood, dark edges, smears where hands wiped
- [ ] 1.1.7.5 · Review: a horde where every zombie of one outfit looks different

### [ ] 1.1.8 · Special body: bloater
> id: S238 | needs: S136 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`

- [ ] 1.1.8.1 · Card: references of bloated bodies in fiction: a swollen torso and neck, a split shirt, pale green skin, veins
- [ ] 1.1.8.2 · Round 1 · form: the swollen belly and neck on the generic body's joints; it still bends and severs like the others
- [ ] 1.1.8.3 · Round 2 · structure: the split shirt (garment kit) straining over the belly, stretch marks, the navel, sores #vfx
- [ ] 1.1.8.4 · Round 3 · surface: blotched pale green skin, dark veins, a wet belly; the belly's pulse as a shape S076 drives
- [ ] 1.1.8.5 · Review: the rack front, side and back at 1 m

### [ ] 1.1.9 · Special body: spitter
> id: S239 | needs: S136 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`

- [ ] 1.1.9.1 · Card: a long neck, a distended jaw, a burnt chest, thin limbs
- [ ] 1.1.9.2 · Round 1 · form: the neck's length, the hinged jaw, the thin limbs on the generic joints
- [ ] 1.1.9.3 · Round 2 · structure: the throat sac that bulges before a spit, ribs through the burnt chest, teeth
- [ ] 1.1.9.4 · Round 3 · surface: charred and blistered skin, a green-stained mouth
- [ ] 1.1.9.5 · Review: the rack front, side and back at 1 m

### [ ] 1.1.10 · Special body: brute
> id: S240 | needs: S136 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`

- [ ] 1.1.10.1 · Card: a head taller, huge arms and shoulders, a small head, firefighter or riot gear fused into it
- [ ] 1.1.10.2 · Round 1 · form: proportions on scaled joints, the hitboxes S078 needs
- [ ] 1.1.10.3 · Round 2 · structure: armour plates as separate parts (each with its HP for S078), straps sunk into flesh, swollen veins, broken gear
- [ ] 1.1.10.4 · Round 3 · surface: skin and gear worn and burnt
- [ ] 1.1.10.5 · Review: the rack front, side and back at 1 m

### [ ] 1.1.11 · Special body: screamer
> id: S241 | needs: S136 | size: L | asset: complex | rounds: 3 | tags: #anim #art #sound | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`

- [ ] 1.1.11.1 · Card: gaunt, a torn hospital gown, the jaw unhinged, hands clawing at its own head
- [ ] 1.1.11.2 · Round 1 · form: the gaunt body, the dislocated jaw, long fingers
- [ ] 1.1.11.3 · Round 2 · structure: ribs and tendons, the gown's ties and tears, hair
- [ ] 1.1.11.4 · Round 3 · surface: pale bruised skin
- [ ] 1.1.11.5 · Review: the rack front, side and back at 1 m

### [ ] 1.1.12 · Special look: crawler
> id: S242 | needs: S136 | size: L | asset: complex | rounds: 3 | tags: #anim #art | test: `tests/test_body_model.gd` | see: `--host --zombie-rack=1`

- [ ] 1.1.12.1 · Card: a body without working legs: torn trousers, entrails dragging
- [ ] 1.1.12.2 · Round 1 · form: the mangled or missing legs, the torso low
- [ ] 1.1.12.3 · Round 2 · structure: torn trousers, entrails as a chain of segments that trail and swing
- [ ] 1.1.12.4 · Round 3 · surface: blood and dirt from dragging; the drag trail's decal #vfx
- [ ] 1.1.12.5 · Review: the rack front, side and back at 1 m

### [~] 1.1.13 · Zombie animation pass
> id: S071 | needs: S070 | size: L | tags: #anim #art | test: `tests/test_rig.gd` | see: `--host --demo --shot-at=1,2,3`

- [ ] 1.1.13.1 · Idle variety per zombie id: sway, head twitch, jaw working, one arm hanging dead, sniffing the air
- [ ] 1.1.13.2 · Walk variety: limp, drag one foot, hunch, arms forward; chosen by id so peers agree #net
- [ ] 1.1.13.3 · Turn in place before walking, head leads the turn, eyes on the target
- [ ] 1.1.13.4 · Hit reactions by part and direction
  - [ ] Head snaps back, shoulder is thrown round, gut shot folds the torso
  - [ ] Leg hit: stumble on that side, a knee touches the ground
  - [ ] Heavy calibres spin or knock down; a knocked-down zombie rolls over and gets up in stages
- [ ] 1.1.13.5 · Attack variety: two-hand grab, wide swipe, lunge bite, each with wind-up, strike and recovery
- [ ] 1.1.13.6 · Losing an arm mid-attack: the swing continues with the stump and sprays
- [ ] 1.1.13.7 · Losing a leg: topple sideways, then the existing lying states
- [x] 1.1.13.8 · Runner: head-down sprint with arms pumping wrong, skids on turns
  - Frantic runner (PR 3): `Humanoid.Anim.SPRINT` / `LUNGE` / `SURGE`, three arm gaits by id, banking into turns, clawing over a jam; `--runner-rack`
- [ ] 1.1.13.9 · Leaper: all-fours scuttle, coil with the back arched, land in a roll
- [ ] 1.1.13.10 · Secondary motion: head and arm lag on stops, jaw and fingers always moving

### [ ] 1.1.14 · Getting up from the ground
> id: S260 | needs: S071, S072 | size: M | tags: #anim #ai #art | test: `tests/test_zombie_rise.gd` | see: `--zombie-rack=1 --pose=rise`

- [ ] 1.1.14.1 · Lying states as dormant poses: face down, on the back, curled, slumped against a wall, sitting in a car seat
- [ ] 1.1.14.2 · Rise in stages, chosen by pose: roll to the side, push up on the arms, a knee, stand with a stagger; each a goal pose the rig eases through
- [ ] 1.1.14.3 · Missing limbs change the rise: one arm pushes and slips, no legs means it drags itself instead
- [ ] 1.1.14.4 · Crawling out from under a car or a bed, hands first
- [ ] 1.1.14.5 · Dead that are really dead: a share of lying bodies never rise (seeded by id), so players cannot tell #gameplay
- [ ] 1.1.14.6 · The rise wakes on noise and sight (S072) and is interrupted by a shove or a hit

### [ ] 1.1.15 · Organic motion
> id: S261 | needs: S071 | size: M | tags: #anim #art | test: `tests/test_humanoid.gd` | see: `--host --demo`

- [ ] 1.1.15.1 · Layered noise on every joint by id: breathing, weight shift, small tremors; never two zombies in step
- [ ] 1.1.15.2 · Tempo per zombie: some slow and heavy, some twitchy and fast, from the id
- [ ] 1.1.15.3 · Feet on the ground: foot placement on slopes, kerbs and stairs, no sliding (stride from speed)
- [ ] 1.1.15.4 · Head and eyes look at the nearest noise or player, the body follows late #ai
- [ ] 1.1.15.5 · Collisions in a crowd push shoulders and heads apart, a stumble when shoved by another zombie #ai
- [ ] 1.1.15.6 · Cheap at distance: the noise layers drop past `Config.ZOMBIE_DETAIL_RANGE` (see 2.3) #perf

### [ ] 1.1.16 · Feeding on corpses
> id: S262 | needs: S072, S081 | size: M | tags: #anim #ai #story #art | test: `tests/test_feeding.gd`

- [ ] 1.1.16.1 · Feeding groups: two to five kneel round one body, shoulder to shoulder, each with its own cycle (S072's FEEDING state)
- [ ] 1.1.16.2 · The body they feed on: an opened corpse prop with a blood pool that grows, torn clothes, a limb pulled away #vfx
- [ ] 1.1.16.3 · Sounds: wet tearing, chewing, grunts, falling quiet when one looks up (S082) #sound
- [ ] 1.1.16.4 · They are slow to notice: hearing range halved while feeding, then the whole group rises together #gameplay
- [ ] 1.1.16.5 · Placed by map data and by the director in quiet streets #map

### [ ] 1.1.17 · Corpses for a devastated town
> id: S263 | needs: S137, S081 | size: M | asset: complex | tags: #art #story #anim | test: `tests/test_corpses.gd` | see: `--prop-rack=corpses`

- [ ] 1.1.17.1 · A corpse kit from the zombie bodies and outfits: lying poses frozen from the ragdoll, mesh-merged, no rig #perf
- [ ] 1.1.17.2 · States: fresh, bloated, decayed to bone; burnt; in a body bag; under a sheet
- [ ] 1.1.17.3 · Arrangements: heaps at a barricade, rows on a triage floor, one slumped in a car, hanging out of a window, half under rubble
- [ ] 1.1.17.4 · Devastation level per area in map data (0 calm to 3 overrun) decides how many and which #map
- [ ] 1.1.17.5 · Instanced (MultiMesh per pose) and capped by `Config` #perf
- [ ] 1.1.17.6 · Flies and a faint smell haze over the worst (small particles, S004) #vfx

### [ ] 1.1.18 · Death and ragdolls
> id: S081 | needs: S071 | size: M | tags: #anim #art | test: `tests/test_ragdoll.gd` | see: `--host --demo --bot --shot-at=2,4`

- [ ] 1.1.18.1 · Death animation before the ragdoll by cause: headshot drop, torso crumple to the knees, run-death tumble that carries momentum
- [ ] 1.1.18.2 · Ragdoll impulse from the killing shot's direction and calibre; shotguns lift them off the ground
- [ ] 1.1.18.3 · Twitching: a hand or leg jerks for a few seconds on some corpses
- [ ] 1.1.18.4 · Corpses settle, then become static corpses as now; caps unchanged #perf
- [ ] 1.1.18.5 · Piles: corpses stack at choke points without jitter
- [ ] 1.1.18.6 · Explosions throw ragdolls and loose limbs

## 1.2 · Assets: building exteriors
? Do we have enough assets to dress the outsides of buildings: facades, windows, shopfronts, roofs, signs?
> tags: #art

### [ ] 1.2.1 · Facades
> id: S044 | needs: S043, S157, S158, S159, S160, S161, S162, S163, S164 | size: L | rounds: 2 | tags: #art | test: `tests/test_facades.gd` | see: `--host --shot-cam` street level, day and night

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- Assembly: the blocks of S043 dressed from the facade kits; nothing modelled here.
- [ ] 1.2.1.1 · Facade grammar per block class: which kit, how many floors, where the shops, carriage gates and signs go, seeded per building
  - [ ] Timber-framed houses (S161) in the old core; plastered stone houses (S162) on the main streets with wooden shopfronts (S158) under French windows (S157); the few post-war blocks (S163) at the edge; ateliers (S164) by the river
  - [ ] Roofs, dormers and balconies (S159), painted and hanging signs (S160) by the shop kinds of the street
- [ ] 1.2.1.2 · The town's mix: plaster fronts in creams, ochres and greys, a stone hôtel behind its gate, a leaning timber house, a later infill where one burnt #sound
- [ ] 1.2.1.3 · Night: a seeded few windows lit warm or TV-blue behind the shutters, some flickering, most dark
- [ ] 1.2.1.4 · Decay by street: shutters closed or hanging, broken windows, soot above burnt ones, quarantine tape across doors (the kits' states)
- [ ] 1.2.1.5 · House numbers on blue enamel plates by the doors
- [ ] 1.2.1.6 · Round 1 · composition: three street views (old core, a main street, the river ateliers) for variety; no two neighbours alike
- [ ] 1.2.1.7 · Round 2 · night and decay: the same views at night and in the abandoned state
- [ ] 1.2.1.8 · Review: the three views, day and night

### [ ] 1.2.2 · Window kit
> id: S157 | needs: S141 | size: L | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=windows`

- [ ] 1.2.2.1 · Card: photos of old Paris windows: tall French casements (fenêtres à la française) with small panes, louvred wooden shutters folding against the wall, low iron railings across the opening (garde-corps), the small windows of the timber houses, post-war ribbon glazing for the few new blocks
- [ ] 1.2.2.2 · Round 1 · form: sizes and proportions per kind (tall, narrow, regular), how deep each sits in the wall, sills, the plaster or stone surrounds
- [ ] 1.2.2.3 · Round 2 · structure: frames and glazing bars, the shutters' louvres, hinges and catches, the garde-corps' bars and scrolls, drip edges
- [ ] 1.2.2.4 · Round 3 · surface: old glass that reflects the sky unevenly, dirt in the frame corners, flaking paint on the frames and shutters, net curtains behind some
- [ ] 1.2.2.5 · States: open, shut, shutters closed, broken (shards left in the frame), boarded, burnt with soot above; lit warm, TV-blue or dark at night (emission)
- [ ] 1.2.2.6 · Review: each kind at 1 m and on a test wall at 10 m, by day and night
- Under way: the tall French casement `window_french` (card `references/elements/window_french.md`, family `tools/models/props/windows.py`) has its references, round 1 and round 2 (the cast garde-corps, pentures and pins, catch and bolt, jet d'eau, battement, the sill's drip; built, sketch close-ups, the rack's sheet not shot); the timber houses' small casement and the post-war ribbon glazing are the family's next elements, each with its own card.

### [ ] 1.2.3 · Shopfront kit
> id: S158 | needs: S141, S157 | size: L | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=shopfronts`

- [ ] 1.2.3.1 · Card: photos of old Paris shopfronts: the wooden front applied to the house (devanture en applique) with pilasters, a deep fascia and the side boxes that hold the night shutters, painted in dark green, oxblood or black #vfx
- [ ] 1.2.3.2 · Round 1 · form: bay widths, the glazed front and its door, the fascia, the shutter boxes, awning depths
- [ ] 1.2.3.3 · Round 2 · structure: the panels and mouldings, small-paned shop windows, the wooden shutter panels put up at night, the bars across them, striped fabric awnings (stores) on arms, a stone step, counters and shelves seen through the glass
- [ ] 1.2.3.4 · Round 3 · surface: gilded or painted lettering on the fascia, posters and prices in the windows, dirty glass, flaking paint, tags on the shutters
- [ ] 1.2.3.5 · States: open, shutters up, half shuttered, forced (panels torn off), looted (glass out, shelves bare) #loot
- [ ] 1.2.3.6 · Review: a row of six fronts at 1 m and 10 m
- Under way: `shopfront` (card `references/elements/shopfront.md`, family `tools/models/props/shopfronts.py`): the central-door layout with its night shutters has its references, round 1 and round 2 (fluted pilasters with console capitals, the fascia's end blocks, letterbox and kick plate, studded shutters, the rolled store, the shop's counter and shelves); the other layouts (tall glass without the frieze, the door off-centre, other bay widths) are parameters of the family, registered as more elements when S044 needs them.

### [ ] 1.2.4 · Roofs, dormers and balconies
> id: S159 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=rooftops`

- [ ] 1.2.4.1 · Card: photos of old Paris roofs: slate and tile, mansards with their steep and shallow slopes, dormers (lucarnes), the tall party-wall chimney stacks with rows of pots, wrought-iron balconies
- [ ] 1.2.4.2 · Round 1 · form: roof faces and mansard breaks, dormers with their pediments, chimney stacks, skylights, balconies on brackets
- [ ] 1.2.4.3 · Round 2 · structure: slate and tile rows, ridge and hip caps, zinc flashing and gutters, downpipes, chimney pots (mitrons) in rows, the balconies' scrolled railings and stone brackets, TV antennas and dishes #perf #vfx
- [ ] 1.2.4.4 · Round 3 · surface: moss and lichen, soot round the chimneys, black stains below the gutters, laundry and plants on some balconies
- [ ] 1.2.4.5 · Review: a roofscape and a balcony at 10 m and 50 m
- Under way (family `tools/models/props/roofs.py`, cards in `references/elements/`): `chimney_stack`, `chimney_stack_long` and `dormer` have rounds 1 and 2 (extension pipes, cowl, broken pot, aerial, rungs; the dormer's leaves open, standing seams, panels, flashing); `balcony` and `balcony_long` (stone slab on scrolled consoles, railing of bars and hearts) and `mansard` (a 3 m bay: box gutter, slate brisis on the kit's new `surfaces.slates`, the break's roll, zinc terrasson with seams, a tabatière) have round 1. All built; sketch close-ups in `references/elements/reviews/*_sketch.png`; the rack's review sheets wait for a windowed run. Left: rounds 3 (surface) of all, round 2 of the balconies and the mansard, the mansard's ends and corners.

### [ ] 1.2.5 · Shop signs and lettering
> id: S160 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=signs_shops`

- [ ] 1.2.5.1 · Card: photos of old French shop signs; the kinds: PHARMACIE with a green cross, BOULANGERIE, BOUCHERIE, CAFÉ, BRASSERIE, TABAC with its red lozenge, QUINCAILLERIE, HERBORISTERIE, OPTICIEN, COIFFEUR, never a real brand
- [ ] 1.2.5.2 · Round 1 · form: lettering painted on the fascia and on the wall over the shop, wrought-iron hanging signs on brackets with a shape cut out (a key, a boot, a bunch of grapes), the pharmacy cross
- [ ] 1.2.5.3 · Round 2 · structure: letters painted, gilded or raised, the brackets' scrolls and chains, the cross's box and its cable
- [ ] 1.2.5.4 · Round 3 · surface: faded paint, ghost signs of old trades on the blank walls, missing letters, rust running from the fixings
- [ ] 1.2.5.5 · Seeded per building from its shop kind; states: lit, dead, flickering (S108), half fallen
- [ ] 1.2.5.6 · Review: a street of signs by day and at night
- Under way: family `tools/models/props/signs_shops.py`: `sign_tabac` (the carotte, TABAC on both faces, lit), `sign_pharmacy` (the green cross, lit, its cable) and `sign_hanging` (a wrought-iron bracket with scrolls, a board with a gilt key) have references and round 1, built. Left: the painted fascia words and the ghost signs on walls, more cut-outs (boot, grapes), seeding per shop, rounds 2 and 3.

### [ ] 1.2.6 · The timber-framed house
> id: S161 | needs: S141, S157 | size: L | asset: complex | rounds: 4 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=half_timber`

- Old Paris's houses on narrow medieval lots: timber frames (pans de bois), most plastered over, a few left bare, leaning with age.
- [ ] 1.2.6.1 · Card: photos of the surviving timber houses of old Paris and French old towns: the narrow front, the jettied floors, the gable or the eaves to the street
- [ ] 1.2.6.2 · Round 1 · form: four or five floors on a two-window front, the upper floors jutting, the steep roof; a plastered and a bare variant
- [ ] 1.2.6.3 · Round 2 · structure: posts, rails and cross-braces (bare variant), the plaster's mouldings over them (plastered variant), small casements, the shop floor's beam, roof tiles and the dormer
- [ ] 1.2.6.4 · Round 3 · surface: weathered dark timber, cracked plaster showing the frame, the lean of the old front, moss on the tiles
- [ ] 1.2.6.5 · Round 4 · use: a variant with a shop or a cabaret on the ground floor (S158), and the abandoned state
- [ ] 1.2.6.6 · Review: front, side and three-quarter at 1 m and 10 m beside the references

### [ ] 1.2.7 · Plastered stone houses
> id: S162 | needs: S156, S157 | size: L | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=houses`

- [ ] 1.2.7.1 · Card: photos of Paris houses of the late 1700s and early 1800s: four to six floors, plaster fronts in cream and grey over stone, a stone ground floor with arches, string courses at each floor, tall French windows with iron railings, a porte cochère, a mansard roof
- [ ] 1.2.7.2 · Round 1 · form: floors and their heights (the ground floor and the first floor tallest), the arched ground floor, the porte cochère; modules that fill a block's row at any width
- [ ] 1.2.7.3 · Round 2 · structure: windows (S157), string courses and the cornice, the arches' keystones, the gate's leaves, downpipes, the long iron balcony on the second floor of some
- [ ] 1.2.7.4 · Round 3 · surface: plaster faded and patched, damp stains at the foot, flaking render showing the rubble, soot streaks under the cornice, pigeon spikes, satellite dishes
- [ ] 1.2.7.5 · Seeded variants so a street of them never repeats; abandoned and burnt states
- [ ] 1.2.7.6 · Review: a street of eight houses at 10 m and one at 1 m

### [ ] 1.2.8 · Post-war blocks
> id: S163 | needs: S157, S159 | size: L | asset: complex | rounds: 4 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=towers`

- Only a few, at the edge of the old town (round the hospital and the bus station): the contrast that makes the old town read as old.
- [ ] 1.2.8.1 · Card: photos of French 1960s and 70s blocks: a rendered slab with loggias, a panel block, an office building with ribbon windows
- [ ] 1.2.8.2 · Round 1 · form: the facade modules by kind (loggia bays, ribbon windows, punched windows), the shop floor at the foot, the roof edge
- [ ] 1.2.8.3 · Round 2 · structure: slab edges, panel joints, railings, the stair towers' glass, the entrance canopy with its glass doors, plant on the roof
- [ ] 1.2.8.4 · Round 3 · surface: water stains running from every slab edge, faded render, mismatched new windows, a few burnt flats with soot above
- [ ] 1.2.8.5 · Round 4 · night: a seeded handful of lit windows, the lit stairwells, a red light on the tallest
- [ ] 1.2.8.6 · Review: each kind at 10 m and 50 m beside the references

### [ ] 1.2.9 · Ateliers
> id: S164 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=sheds`

- [ ] 1.2.9.1 · Card: photos of old French riverside workshops and manufactures: stone and brick halls, glazed roofs, a tall brick chimney, a yard behind a gate
- [ ] 1.2.9.2 · Round 1 · form: long low halls, pitched and glazed roofs, the yard, the chimney
- [ ] 1.2.9.3 · Round 2 · structure: stone piers and arched windows, the roof glazing's bars, big wooden doors, a hoist beam over a loft door, painted names without brands
- [ ] 1.2.9.4 · Round 3 · surface: soot, rust, faded paint, oil on the yards, broken panes
- [ ] 1.2.9.5 · Review: the street front at 10 m and the yard at 1 m

### [ ] 1.2.10 · Front walls, railings and gates
> id: S156 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=boundaries`

- Most houses stand on the street; walls and gates are for the courts of the hôtels, the gardens and the villas on the hill road.
- [ ] 1.2.10.1 · Card: photos of old Paris street fronts: portes cochères with their great wooden leaves, a court wall with a carved gateway, stone walls with iron railings on a low plinth, garden walls with copings
- [ ] 1.2.10.2 · Round 1 · form: heights (0.6 m plinths, 2 m railings, 3 to 4 m court walls), pier spacing, gate widths for a carriage and for a person
- [ ] 1.2.10.3 · Round 2 · structure: copings and pier caps with urns, the railings' bars and spear finials, the gate leaves' panels, studs, knockers and the wicket door, chasse-roues at the gate's foot #perf
- [ ] 1.2.10.4 · Round 3 · surface: stone and plaster with damp rising from the ground, flaking paint, rust on the railings, tags, moss
- [ ] 1.2.10.5 · Modules that join along any lot line, with corners and ends; states: gate open, rammed, burnt
- [ ] 1.2.10.6 · Review: a street front of ten lots at 10 m and the rack at 1 m
- Under way: family `tools/models/props/boundaries.py`: `porte_cochere` (surround, reveal, leaves of panels opening into the court, chasse-roues), `railing_plinth` (a 2.40 m bay), `railing_pier`, `railing_gate` (two leaves) and `garden_wall` (a 3 m bay) have references and round 1, built. Left: corners and ends, the wicket door, the hill's villa walls, rounds 2 and 3, rammed and burnt states.

## 1.3 · Assets: interiors
? Do we have enough to fill the insides: rooms, doors, stairs, furniture, lights, clutter?
> tags: #art #map

### [ ] 1.3.1 · Building pipeline
> id: S053 | needs: S002 | size: L | tags: #art #map | test: `tests/test_building.gd` | see: `--building=sample`

- [ ] 1.3.1.1 · `scripts/world/building.gd`: a building from one data dictionary
  - [ ] Footprint point list (traced from the top view), wall thickness
  - [ ] Floors: count, height each, slab thickness
  - [ ] Openings per wall: window grid (columns, rows, size, sill), doors, big openings
  - [ ] Facade and roof colours, trim, relief (fins, bands, columns)
  - [ ] Roof kind: flat with parapet, hipped tile, metal shed, concrete canopy
  - [ ] Interior walls and rooms per floor as rectangles with door gaps
  - [ ] Stairs (straight, dog-leg), ramps, shafts between floors
- [ ] 1.3.1.2 · Output: meshes merged per floor and material, collision, nav for every floor with stair links, fixed `iid`s
- [ ] 1.3.1.3 · Floors above and below the player hidden or cheap
- [ ] 1.3.1.4 · Top-view plan export per building for checking against the reference
- [ ] 1.3.1.5 · `ground_y` and multi-floor zones work with `MapData`
- Shells, floors, rooms, stairs and nav only: the facades come from the kits (S157 to S164) and from each POI's own elements.

### [ ] 1.3.2 · Interior assembly kit
> id: S054 | needs: S053, S191, S192, S193, S194, S195, S196 | size: M | rounds: 2 | tags: #art #map | test: `tests/test_interior_kit.gd` | see: `--interior-rack`

- Assembly: rooms from data furnished with finished elements; nothing modelled here.
- [ ] 1.3.2.1 · Room kinds from data (office, ward, corridor, store room, barracks, hall), each furnished from the element families with seeded layouts
- [ ] 1.3.2.2 · Clutter generator per room kind (S196), seeded: papers, overturned chairs, blood, barricade attempts #vfx
- [ ] 1.3.2.3 · Locked door (needs a key, a crowbar, or damage) and a light switch as interactables (S191, S194)
- [ ] 1.3.2.4 · The elevator (S195) in the buildings' shafts, stuck between floors, doors that can be pried
- [ ] 1.3.2.5 · `--interior-rack`: one room of each kind
- [ ] 1.3.2.6 · Round 1 · layout: each room kind against photos of real ones
- [ ] 1.3.2.7 · Round 2 · story and light: clutter that tells what happened, the fittings' states
- [ ] 1.3.2.8 · Review: the six rooms at eye height

### [ ] 1.3.3 · Doors and frames
> id: S191 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art #map | test: `tests/test_elements.gd` | see: `--prop-rack=doors`

- The corridor's door (`door.gd`) is a box today; it moves to this kit with its hinge and states.
- [ ] 1.3.3.1 · Card: wooden swing doors, double doors, glass doors with push bars, fire doors with wired glass, roller shutters, frames and architraves, handles and locks #vfx #anim
- [ ] 1.3.3.2 · Round 1 · form: sizes (0.8 to 0.9 m by 2.1 m, doubles, shop shutters), frame depths
- [ ] 1.3.3.3 · Round 2 · structure: panels, hinges, handles, kick plates, door closers, vision panels, push bars, locks, the shutter's slats and guides
- [ ] 1.3.3.4 · Round 3 · surface: worn paint round the handles, scuffs at the foot, signs (SORTIE, PRIVÉ), blood handprints #vfx
- [ ] 1.3.3.5 · States and parts: open, shut, locked (it rattles), splintered and broken in stages by the door's HP
- Under way: family `tools/models/props/doors.py`: `door_wood` (architrave, lining, four raised panels both faces, butts, levers), `door_glass` (aluminium stiles, push bar, closer), `door_fire` (pressed frame, wired vision panel, panic bar, closer) and `door_plank` (the corridor's 2.0 x 2.6 ledged and braced door) have round 1, built, each leaf a part opening inward. `door_double` (half-glazed, two leaves) too. Left: photos, the roller shutter, swapping `door_plank` into `door.gd`, the broken states, rounds 2 and 3.
- [ ] 1.3.3.6 · Review: each on the rack at 1 m, and the corridor's door in its four states

### [ ] 1.3.4 · Stairs, railings, ceilings and floors
> id: S192 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art #map | test: `tests/test_elements.gd` | see: `--prop-rack=stairs`

- [ ] 1.3.4.1 · Card: the concrete stairs of public buildings, steel tube handrails, glass and concrete balustrades, suspended ceilings, granilite and tile floors
- [ ] 1.3.4.2 · Round 1 · form: straight and dog-leg flights to the building pipeline's floor heights, landings, nosings
- [ ] 1.3.4.3 · Round 2 · structure: handrail brackets and ends, balusters, ceiling grids with tiles and light openings, skirting, floor joints
- [ ] 1.3.4.4 · Round 3 · surface: worn nosings, chipped paint, missing and hanging ceiling tiles, stains
- [ ] 1.3.4.5 · Review: a stairwell from bottom to top and a corridor ceiling at eye height
- Under way: family `tools/models/props/stairs.py`: `stair_flight` (a half flight to its landing, granilite treads with nosings, tube handrail, flat-bar balustrade with its scroll) and `ceiling_grid` (a 2.4 m module: grid, tiles, one hanging, one gone, a stain, a louvre light) have round 1, built (no photos yet). Left: photos, glass and concrete balustrades, floors, the building pipeline's storey heights (S053), rounds 2 and 3.

### [ ] 1.3.5 · Office and public furniture
> id: S193 | needs: S141 | size: L | asset: simple | rounds: 3 | tags: #art #map | test: `tests/test_elements.gd` | see: `--prop-rack=office`

- [ ] 1.3.5.1 · Card: desks with drawers, wheeled office chairs, filing cabinets, counters, shelves, computers and monitors, beam seating, a vending machine, a water cooler #ui
- [ ] 1.3.5.2 · Round 1 · form: real sizes
- [ ] 1.3.5.3 · Round 2 · structure: drawers and handles, chair mechanisms and castors, cabinet labels, cables, the vending machine's window and coils
- [ ] 1.3.5.4 · Round 3 · surface: laminate wear, coffee rings, stickers, papers on the desks #sound
- [ ] 1.3.5.5 · States: knocked over, ransacked, smashed
- [ ] 1.3.5.6 · Review: an office corner at eye height
- Under way: family `tools/models/props/office.py`: `desk` (laminate top, steel frame, pedestal with its top drawer pulling out), `office_chair`, `filing_cabinet` (four drawers, the top one pulling out on its files), `shelving` (archive boxes and binders seeded), `desk_computer` (monitor, keyboard, mouse, phone, tower), `beam_seating`, `vending_machine` (coils of goods, lit panel) and `water_cooler` have round 1, built (no photos yet: Commons refused requests). `reception_counter` too. Left: photos, the knocked-over and ransacked states, rounds 2 and 3.

### [ ] 1.3.6 · Light fittings and signs
> id: S194 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art #map | test: `tests/test_elements.gd` | see: `--prop-rack=fittings`

- [ ] 1.3.6.1 · Card: recessed and hanging tube fixtures, emergency lights, exit signs (the green running figure, SORTIE DE SECOURS), switches, fire alarm points, extinguishers #vfx
- [ ] 1.3.6.2 · Round 1 · form: sizes and mountings
- [ ] 1.3.6.3 · Round 2 · structure: diffusers and bare tubes, chains and wires, the exit sign's box, switch plates
- [ ] 1.3.6.4 · Round 3 · surface: dead insects in the diffusers, yellowed plastic, dust #vfx
- [ ] 1.3.6.5 · States: lit, dead, flickering, hanging by one wire (the swing of S108) #anim
- [ ] 1.3.6.6 · Review: a ceiling at night with every state
- Under way: family `tools/models/props/fittings.py`: `tube_light` (two-tube batten on chains, lit), `exit_sign` (the BAES with its lit green face), `extinguisher` (on its bracket) and `alarm_point` have round 1, built. `emergency_light` (the BAES d'ambiance) and `switch_socket` too; the louvre panel is in `ceiling_grid`. Left: the states (dead, flickering, hanging by one chain: S108), rounds 2 and 3.

### [ ] 1.3.7 · Elevator
> id: S195 | needs: S141, S191 | size: M | asset: complex | rounds: 3 | tags: #art #map | test: `tests/test_elements.gd` | see: `--prop-rack=elevator`

- [ ] 1.3.7.1 · Card: a hospital elevator: the car, the landing doors, the shaft
- [ ] 1.3.7.2 · Round 1 · form: a car a bed fits in, the shaft and pit, landing doors
- [ ] 1.3.7.3 · Round 2 · structure: the car's panel, mirror and handrail, the door tracks and the gap to pry, guide rails, cables, the ladder in the shaft
- [ ] 1.3.7.4 · Round 3 · surface: brushed steel with scratches, grime in the tracks, the emergency light inside
- [ ] 1.3.7.5 · States: stuck between floors, doors pried apart
- [ ] 1.3.7.6 · Review: from the landing and from inside

### [ ] 1.3.8 · Clutter
> id: S196 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art #map | test: `tests/test_elements.gd` | see: `--prop-rack=clutter`

- [ ] 1.3.8.1 · Card: papers and folders, broken glass, food packaging, phones, cups, bags, a fallen picture frame, cables
- [ ] 1.3.8.2 · Round 1 · form: sizes, and how they lie on a floor
- [ ] 1.3.8.3 · Round 2 · structure: folded and crumpled papers, shards, packaging shapes
- [ ] 1.3.8.4 · Round 3 · surface: print as texture (no real brands), stains, blood #vfx
- [ ] 1.3.8.5 · Review: a floor of it at 1 m
- Under way: family `tools/models/props/clutter.py`: `papers` (an office floor's sheets, folder, cup, phone, pen), `shards` (a window's glass on a floor) and `picture_frame` (fallen face to the wall, its glass out) have round 1, built. `food_litter` (packets, cans, a cup, a bag, a pizza box) too. Left: cables, photos, rounds 2 and 3.

### [ ] 1.3.9 · Barricades
> id: S055 | needs: S014, S054, S153 | size: M | tags: #art #map | test: `tests/test_barricade.gd`

- [ ] 1.3.9.1 · Barricade point on doors and windows: holds up to five planks
- [ ] 1.3.9.2 · Building: hold use, a plank from the inventory goes up with a hammer animation, three knocks, each plank at a slightly different angle #anim
- [ ] 1.3.9.3 · Zombies attack it: planks crack, splinter and fly off one at a time, arms reach through the gaps
- [ ] 1.3.9.4 · Repair while it stands
- [ ] 1.3.9.5 · Shooting through the gaps works, planks are bullet cover otherwise
- [ ] 1.3.9.6 · Plank piles as pickups #loot
- [ ] 1.3.9.7 · State through `get_state` / `apply_state`

## 1.4 · Assets: streets, vehicles and street dressing
? Do we have the roads, kerbs, street signs, lamps, cars and the wreckage of the evacuation?
> tags: #art

### [ ] 1.4.1 · Road surface
> id: S041 | needs: S040, S155 | size: L | asset: complex | rounds: 3 | tags: #art | test: `tests/test_road_surface.gd` | see: `--host --shot-cam` over the rue du Marché, `--street-rack`

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- [ ] 1.4.1.1 · Surfaces as vertex colour and one shared material, no textures
  - [ ] Pavés: square sandstone and granite setts in rows on the old streets, the squares and the quays, slightly domed each, the joints dark; drawn in vertex colour with height noise
  - [ ] The old lanes dished to a gutter (ruisseau) down the middle, as before pavements
  - [ ] Asphalt on the main streets: dark, patched, a lighter worn track per lane
- [ ] 1.4.1.2 · Markings as thin overlay meshes in one draw per street, French style
  - [ ] White dashed centre and lane lines on the asphalt, none on the setts
  - [ ] Zebra crossings (passages piétons) as white bars, on the setts too
  - [ ] BUS lettering and lanes near the bus station, painted arrows, give-way triangles, yellow zigzags at the bus stops, parking bays and PAYANT lettering
- [ ] 1.4.1.3 · The road details of S155 placed: manholes, gutters and kerb drains, raised crossings, cracks and potholes seeded per street, setts missing in patches #vfx
- [ ] 1.4.1.4 · Camber: the main streets crowned, the old lanes falling to the middle
- [ ] 1.4.1.5 · `--street-rack`: a 30 m strip of every surface and marking side by side
- [ ] 1.4.1.6 · Round 1 · form: the strips' crowns and dishes, kerb lines and the markings' widths against the card's French references
- [ ] 1.4.1.7 · Round 2 · structure: the setts' rows and joints, sunk and lifted ones, asphalt patches over setts, faded and cracked paint
- [ ] 1.4.1.8 · Round 3 · wet and night: the same strips at night and wet (S110 when it exists), lamp pools, the setts' shine, water running in the ruisseau
- [ ] 1.4.1.9 · Review: the street rack sheet and the rue du Marché shot

### [ ] 1.4.2 · Sidewalks
> id: S042 | needs: S040, S156 | size: M | asset: complex | rounds: 3 | tags: #art #anim | test: `tests/test_sidewalks.gd` | see: `--host --shot-cam` on a street corner, `--street-rack`

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- [ ] 1.4.2.1 · Kerb as a real 12 to 15 cm step of long granite blocks, players and zombies walk it without a jump
- [ ] 1.4.2.2 · Paving kinds by street
  - [ ] Poured grey asphalt pavements with the granite kerb, the Parisian kind
  - [ ] Stone flags on the squares and in front of the public buildings
  - [ ] No pavement in the narrowest lanes: setts wall to wall, stone bollards (bornes chasse-roues) guarding the house corners and the carriage gates
- [ ] 1.4.2.3 · Dropped kerbs at the portes cochères and crossings, studded tactile strips at corners
- [ ] 1.4.2.4 · Tree pits with cast-iron grilles on the main streets; the walls, railings and gates of S156 where buildings stand back
- [ ] 1.4.2.5 · Sidewalks are nav cells: zombies use them, hordes spill onto the road
- [ ] 1.4.2.6 · Round 1 · form: kerb heights and pavement widths per street, the flags' sizes against the photos
- [ ] 1.4.2.7 · Round 2 · structure: joints, cracked and patched asphalt, broken kerb stones, the bornes' worn tops
- [ ] 1.4.2.8 · Round 3 · surface: grime, gum, stains, moss and weeds in the joints, darker where wet
- [ ] 1.4.2.9 · Review: the street rack and the corner shot beside the references

### [ ] 1.4.3 · Road details: manholes, drains, humps
> id: S155 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art #vfx | test: `tests/test_elements.gd` | see: `--prop-rack=road_details`

- [ ] 1.4.3.1 · Card: photos of French manhole covers (regards), kerb drains (bouches d'égout) with their cast-iron mouths, the stone gutter channels, raised crossings
- [ ] 1.4.3.2 · Round 1 · form: round and square covers with their frames, the kerb drain's mouth and its stone, the gutter's dish, the raised crossing's ramps
- [ ] 1.4.3.3 · Round 2 · structure: cast patterns and lettering on the covers (the town's invented name and arms), the grate bars, the crossing's painted marks, setts laid round the covers
- [ ] 1.4.3.4 · Round 3 · surface: rust and polish where tyres pass, leaves and silt in the drains, faded paint, patches and potholes as decals with depth
- [ ] 1.4.3.5 · States: a missing cover (an open hole), a drain overflowing in rain (S110)
- [ ] 1.4.3.6 · Review: the rack and a street strip at 1 m and 10 m
- Under way: family `tools/models/props/road.py`: `manhole` (round cover in its square frame, after a Paris regard: rings, EAUX / ÉGOUTS cast round the ring, slot, the checker of studs baked by `road.Checker`, the shaft and rungs; the cover a part that lies pried off), `manhole_square` (radiating diamonds) and `valve_cover` (GAZ) have references and round 1, built. `gully_grate` (two slotted grates in a concrete surround) and `speed_hump` (a flat-topped hump with its painted teeth) have round 1 too. Left: the kerb drain's mouth in the kerb (bouche d'égout; no square-on reference found yet), the gutter's dish, rounds 2 and 3.

### [ ] 1.4.4 · Bridges
> id: S165 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=bridges`

- [ ] 1.4.4.1 · Card: photos of old Paris bridges: a stone bridge of round arches with half-round bays over the piers, and an early cast-iron footbridge
- [ ] 1.4.4.2 · Round 1 · form: deck widths and spans, the arches and piers in the water, pavements; a road bridge and a footbridge
- [ ] 1.4.4.3 · Round 2 · structure: stone parapets with copings and the bays' benches, the piers' cutwaters, carved masks on the cornice, lanterns on the parapet, the footbridge's iron arches and wooden deck
- [ ] 1.4.4.4 · Round 3 · surface: stains below the spouts, moss at the waterline, graffiti under the arches, rust on the ironwork
- [ ] 1.4.4.5 · Review: each bridge from the quay and from the water at 10 m and 50 m
- Under way: family `tools/models/props/bridges.py`: `bridge_stone` (three elliptical arches, archivolts, cutwaters rising into half-round bays with benches, cornice on corbels with masks, parapet, road and pavements; ashlar painted) and `bridge_foot` (one cast-iron span of five ribs with rings, oak deck, railings, lanterns) have round 1, built (the Pont Neuf's photos on the stone bridge's card; the footbridge's still to fetch: Commons refused requests). Left: the footbridge's photos, the demi-lunes' corbels, lanterns on the stone parapet, steps to the lower quay, rounds 2 and 3.

### [ ] 1.4.5 · Street lamps
> id: S166 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=lamps_street`

- [ ] 1.4.5.1 · Card: the réverbère of about 1800 (a lantern with a reflector hung on a rope across the street), the lantern on an iron wall bracket (potence), the cast-iron candelabrum of the main streets and quays, the modern mast on the outer roads
- [ ] 1.4.5.2 · Round 1 · form: the lanterns' shapes, the brackets' curves, the candelabrum's height, base and arms
- [ ] 1.4.5.3 · Round 2 · structure: the réverbère's glass, reflector and hook, the bracket's scrolls, the candelabrum's base with its access door and fluted column, the lantern's panes and crown
- [ ] 1.4.5.4 · Round 3 · surface: dark green or black paint with chips, stickers on the posts, rust at the foot, insects in the glass
- [ ] 1.4.5.5 · States: lit (warm, a little flicker in the old lanterns), dead, flickering (S108), bent by a crash, a lantern hanging askew
- [ ] 1.4.5.6 · Review: each lamp at 1 m and 10 m, and lit at night
- Under way: family `tools/models/props/lamps.py`: `lamp_post` (Marville's cast-iron candélabre: slab, pedestal with cartouches, bell, collar, leaves and flutes, capital, the shared lantern lit) and `wall_lantern` (the same lantern on a scrolled wall bracket) have references and round 1, built. `lamp_mast` (the modern mast: conical pole, arm, flat lit head) and `reverbere` (the 1800 lantern with its reflector, hook and rope stubs) have round 1 too. Left: rounds 2 and 3, the lit / dead / flickering switch per instance (S046).

### [ ] 1.4.6 · Lantern ropes and wires
> id: S167 | needs: S141 | size: L | asset: complex | rounds: 4 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=poles`

- What hangs in the air of the old town is the réverbères' ropes across the streets, run through pulleys to a locked box on the wall to lower them; wooden poles only on the hill road and the outskirts.
- [ ] 1.4.6.1 · Card: engravings and photos of réverbères on their ropes, the wall boxes and pulleys, later wires on wall brackets, wooden poles with crossarms on the edge of town
- [ ] 1.4.6.2 · Round 1 · form: the anchors' heights, the ropes' spans across a street, the boxes' size, the pole heights and crossarms' levels
- [ ] 1.4.6.3 · Round 2 · structure: pulleys and hooks, the wall box with its iron door and lock, wall brackets with insulators, the pole's crossarms, stays and their ground anchors, cable boxes at the poles' foot
- [ ] 1.4.6.4 · Round 3 · surface: weathered grey wood with cracks, rust on the fittings, stapled flyers, stencilled numbers
- [ ] 1.4.6.5 · Round 4 · cables: catenaries with their sag, the lantern's weight pulling the span into a V, wires between poles along the hill road, a few broken and hanging down
- [ ] 1.4.6.6 · States: a rope cut and its lantern smashed in the street, a leaning pole, sparks (S114) #vfx
- [ ] 1.4.6.7 · Review: a street of three spans and a stretch of hill road at 10 m, and a wall box at 1 m
- Under way: in `tools/models/props/lamps.py`: `reverbere` (the lantern on its hook, the rope's start each way) and `rope_box` (the locked wall box, pulley and rope) have round 1, built. `utility_pole` (crossarms, insulators, wires, stay) and `wall_insulators` (the bracket where the wires meet a house) too. Left: the spans as catenaries between anchors, seeded per street, rounds 2 to 4.

### [ ] 1.4.7 · Traffic lights
> id: S168 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=traffic_lights`

- [ ] 1.4.7.1 · Card: photos of French traffic lights on short poles at the kerb, with the small repeater lights at eye height and the pedestrian heads
- [ ] 1.4.7.2 · Round 1 · form: poles, signal heads with three lenses, the repeaters, pedestrian heads, the controller cabinet
- [ ] 1.4.7.3 · Round 2 · structure: visors, backplates, push-button boxes, the cabinet's door and vents, bolts and clamps
- [ ] 1.4.7.4 · Round 3 · surface: faded paint, dirty lenses, stickers on the poles and cabinet
- [ ] 1.4.7.5 · States: dead, blinking amber, a head hanging by its cable (swung by S115)
- [ ] 1.4.7.6 · Review: a junction at 10 m and a head at 1 m, lit at night
- Under way: family `tools/models/props/traffic.py`: `traffic_light` (short pole, head with visors, repeater, button box), `traffic_light_ped` (the red and green men lit) and `controller_cabinet` have references and round 1, built. Left: a cabinet photo, backplates, which lens is lit per instance (S046), rounds 2 and 3.

### [ ] 1.4.8 · Street signs
> id: S169 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=signs_street`

- The model of a good element step: one family, every sign as an extremely detailed low-poly model.
- [ ] 1.4.8.1 · Card: photos of the street names carved in the corner stones of old Paris, the blue enamel street plates with their green frame and the quarter's line, and French traffic signs: STOP, CÉDEZ LE PASSAGE, speed limits, no parking, one-way, raised crossing, pedestrian crossing, bus stop, the white town direction signs
- [ ] 1.4.8.2 · Round 1 · form: plate and sign sizes from the French standards, mounting heights, the poles
- [ ] 1.4.8.3 · Round 2 · structure: the carved letters' depth, enamel plates' rims and screw holes, rolled edges, the backs with their brackets and clamps, bolts, pole caps #perf
- [ ] 1.4.8.4 · Round 3 · surface: retroreflective faces that catch headlights and the flashlight, faded red, chipped enamel, worn carving, stickers, rust bleeding from the bolts, bullet holes #vfx
- [ ] 1.4.8.5 · Name plates and carvings take any of the invented street names; states: bent, knocked over, shot
- [ ] 1.4.8.6 · Review: every sign at 1 m and 10 m, lit by the flashlight at night #vfx
- Under way: family `tools/models/props/signs_street.py`: `street_plate` (blue enamel, green cast frame with rosettes, the arch; RUE PASTEUR / CENTRE painted), `sign_stop`, `sign_giveway`, `sign_no_entry` (aluminium plates with rolled edges, painted faces, rails, clamps, galvanised poles) have references and round 1, built; `sign_speed` (30), `sign_no_parking`, `sign_one_way`, `sign_crossing` and `sign_direction` (two white arrow plates) have round 1 too, built on the same plate and pole. Left: names per plate (text per instance), the carved corner-stone names, the bus stop's C6, rounds 2 and 3.

### [ ] 1.4.9 · Bus stop shelter
> id: S170 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=bus_stop`

- [ ] 1.4.9.1 · Card: photos of French glass bus shelters (abribus) and a plain pole stop with its sign
- [ ] 1.4.9.2 · Round 1 · form: the canopy, the frame, the bench, the panels
- [ ] 1.4.9.3 · Round 2 · structure: glass panels, the lit poster case, the timetable frame, the map of the lines, a bin, the stop's sign with line numbers
- [ ] 1.4.9.4 · Round 3 · surface: scratched glass, stickers, posters, grime
- [ ] 1.4.9.5 · States: smashed glass, the poster light flickering
- [ ] 1.4.9.6 · Review: at 1 m and 10 m, by day and night
- Under way: family `tools/models/props/bus_stop.py`: `bus_shelter` (wing roof, legs, glass, lit poster case, bench, timetable, map, name blade) and `bus_stop_pole` (BUS sign, the stop's name, lines' plates, timetable) have references and round 1, built. Left: smashed glass (S113), rounds 2 and 3.

### [x] 1.4.10 · Colonne Morris
> id: S171 | needs: S141 | size: S | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=ad_column`

- [x] 1.4.10.1 · Card: photos of the dark green Paris advertising column with its fringed dome and finial
- [x] 1.4.10.2 · Round 1 · form: the drum's height and diameter, the dome, the plinth
- [x] 1.4.10.3 · Round 2 · structure: the dome's scalloped fringe and ribs, the finial, the plinth's ring, the service door, the paper edges of the posters
- [x] 1.4.10.4 · Round 3 · surface: theatre and concert posters pasted over each other (invented, no real brands), torn layers, grime at the foot
- [x] 1.4.10.5 · States: posters half torn off, a quarantine notice pasted over them (knocked over by a car: left to street dressing)
- [x] 1.4.10.6 · Review: at 1 m and 10 m

### [ ] 1.4.11 · Kiosk
> id: S172 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=kiosk`

- [ ] 1.4.11.1 · Card: photos of the dark green Paris newspaper kiosk with its domed roof and its hatch
- [ ] 1.4.11.2 · Round 1 · form: the kiosk's octagon or box, the serving hatch with its fold-up shutter, the dome and the roof's overhang
- [ ] 1.4.11.3 · Round 2 · structure: newspaper racks and clips, the hatch's hinges and props, the dome's ribs and finial, the name panel, the cast-iron frame
- [ ] 1.4.11.4 · Round 3 · surface: front pages as a texture (no real titles), faded paint, rust
- [ ] 1.4.11.5 · States: open, shut, looted (papers blowing, S115) #loot
- [ ] 1.4.11.6 · Review: at 1 m and 10 m
- Under way: family `tools/models/props/kiosk.py`: `kiosk` (hexagon of framed faces, PRESSE panels, posters, cresting, attic, dome with ribs, finial; the shutter opening over the counter) has references and round 1, built. Left: the dome's scales, papers on clips, rounds 2 and 3.

### [ ] 1.4.12 · Small street furniture
> id: S173 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=street_small`

- [ ] 1.4.12.1 · Card: French double benches on cast legs, the green bins on a hoop, stone bornes and cast-iron bollards, a cast-iron drinking fountain, the column fire hydrant, the yellow post box on a wall, bike racks, tree grilles, the low hoop railings round the lawns #vfx
- [ ] 1.4.12.2 · Round 1 · form: each at its real size
- [ ] 1.4.12.3 · Round 2 · structure: slats and brackets, the bins' hoops and lids, the fountain's basin and button, the hydrant's caps and chains, the post box's slot and door #perf
- [ ] 1.4.12.4 · Round 3 · surface: worn paint, rust, stickers, litter in and round the bins
- [ ] 1.4.12.5 · Review: everything at 1 m
- Under way: family `tools/models/props/street_small.py`: `bench_double` (Davioud's double bench: cast end frames with rings and shield, green slats), `borne` (stone guard stone), `guard_bar` (cast-iron chasse-roue), `bin_hoop` (the bag bin), `bin_cage` (the rod basket), `bollard` (the potelet), `post_box` (the yellow wall box, no brand), `tree_grille`, `fountain_wall` (the cast-iron wall fountain of 1872), `bike_hoop` and `lawn_hoops` have round 1, built (references for all but the last two). Left: rounds 2 and 3.

### [ ] 1.4.13 · Vehicle kit
> id: S179 | needs: S141 | size: L | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=vehicle_kit`

- [ ] 1.4.13.1 · Card: what every vehicle shares, so each vehicle step is only its body: references of wheels, lamps, French plates, interiors, wrecks #ui
- [ ] 1.4.13.2 · Round 1 · form: a test car built from the kit: wheels, glass, lights, plates, mirrors #ui
- [ ] 1.4.13.3 · Round 2 · structure: rims (steel, alloy) with tyres whose tread and sidewall lettering show, hubcaps; headlamp and tail clusters with emission and indicators that blink for the hazard state; long white plates with a blue band at each end and seeded letters (an invented code and region number, no real one); door seams and handles cut as parts so doors open; seats, dash and steering wheel #ui
- [ ] 1.4.13.4 · Round 3 · surface: the state generator on the test car: dust, smashed (dents, cracked and shattered glass), burnt shell (no tyres, brown-black metal, soot), rolled; flat and missing wheels #vfx #ui
- [ ] 1.4.13.5 · Review: the test car in every state at 1 m and 10 m
- Under way: family `tools/models/props/vehicle_kit.py`: `wheel_steel` (195/65 R15 with tread, steel rim, nuts), `plate_fr` (the long white plate, its bands and an invented code), `headlamp`, `tail_lamp` and `wing_mirror` have round 1, built. `wheel_alloy` (five spokes on the same tyre), `car_seat` and `dashboard` (binnacle, wheel, centre stack) too. Left: hubcaps, doors as parts on a test car, the state generator, rounds 2 and 3.

### [ ] 1.4.14 · Hatchback and estate
> id: S180 | needs: S179 | size: L | asset: complex | rounds: 4 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=cars`

- [ ] 1.4.14.1 · Card: photos of the commonest small hatchback and family estate on French streets (no badges, no brand's shapes copied)
- [ ] 1.4.14.2 · Round 1 · form: proportions, the glasshouse, the wheel arches #ui
- [ ] 1.4.14.3 · Round 2 · structure: bumpers, grilles, lamps, door lines, mirrors, roof rails
- [ ] 1.4.14.4 · Round 3 · surface: paint colours by seed, chips and scratches, parking dents on every corner, mud on the sills
- [ ] 1.4.14.5 · Round 4 · variants: a taxi with its lit roof sign, a police car in a generic blue-and-white livery with its light bar (no real force's markings)
- [ ] 1.4.14.6 · Review: both bodies and the variants at 1 m and 10 m, in every state

### [ ] 1.4.15 · Pickup and van
> id: S181 | needs: S179 | size: M | asset: complex | rounds: 3 | tags: #art #loot | test: `tests/test_elements.gd` | see: `--prop-rack=pickup_van`

- [ ] 1.4.15.1 · Card: a midsize double-cab pickup and a panel van
- [ ] 1.4.15.2 · Round 1 · form: proportions, the bed, the van's box
- [ ] 1.4.15.3 · Round 2 · structure: bed rails, tow hitch, roof rack, sliding door, rear doors #perf
- [ ] 1.4.15.4 · Round 3 · surface: work dirt; ladders and tool boxes as variants
- [ ] 1.4.15.5 · Review: at 1 m and 10 m in every state

### [ ] 1.4.16 · Ambulance
> id: S182 | needs: S179, S181 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=ambulance`

- [ ] 1.4.16.1 · Card: photos of French box ambulances
- [ ] 1.4.16.2 · Round 1 · form: the van with its raised box
- [ ] 1.4.16.3 · Round 2 · structure: light bars, the rear doors open on the stretcher, the side door, the inside (stretcher, cabinets, oxygen)
- [ ] 1.4.16.4 · Round 3 · surface: a generic livery (white with a reflective chequer band and the town's invented hospital name), blood inside #vfx
- [ ] 1.4.16.5 · Review: doors open and shut, lights on, at 1 m and 10 m

### [ ] 1.4.17 · Scooter and moped
> id: S183 | needs: S179 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=motorbike`

- [ ] 1.4.17.1 · Card: the common 125 cc scooter, and a delivery moped with its box
- [ ] 1.4.17.2 · Round 1 · form: frame and bodywork, seat, wheels #ui
- [ ] 1.4.17.3 · Round 2 · structure: forks, exhaust, mirrors, lights, the leg cover, the top box and the delivery box
- [ ] 1.4.17.4 · Round 3 · surface: a worn seat, scratches, dirt
- [ ] 1.4.17.5 · States: on its stand, fallen, burnt
- [ ] 1.4.17.6 · Review: at 1 m and 10 m

### [ ] 1.4.18 · Evacuation remains
> id: S184 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=remains`

- [ ] 1.4.18.1 · Card: suitcases (hard and soft), prams, shoes, piles of clothes, supermarket trolleys, a teddy bear, mattresses roped to roofs, water bottles, plastic chairs, a small aluminium boat
- [ ] 1.4.18.2 · Round 1 · form: each at its real size
- [ ] 1.4.18.3 · Round 2 · structure: zips, wheels, handles, straps, the trolley's wire mesh, the bear's seams #ui
- [ ] 1.4.18.4 · Round 3 · surface: dirt, rain stains, tears, blood on some #vfx
- [ ] 1.4.18.5 · Review: a spill along a car at 1 m
- Under way: family `tools/models/props/remains.py`: `trolley` (the tapered wire basket, handle, seat flap, chassis on casters), `plastic_chair` (the monobloc), `pram` (navy body, hood on ribs, C-springs, spoked wheels), `suitcase_hard`, `suitcase_soft`, `mattress` (quilted, piping, one end curled), `teddy_bear`, `rowboat` (an aluminium boat lofted from sections, thwarts, oars), `shoes` (trainers and a leather shoe), `water_pack` (six bottles, film, a loose and a crushed one) and `clothes_pile` (garments in folds, sleeves, a scarf) have references and round 1, built. Left: a mattress roped to a roof, rounds 2 and 3.

### [ ] 1.4.19 · Barricades and checkpoint gear
> id: S185 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=checkpoint`

- [ ] 1.4.19.1 · Card: concrete barriers, the grey metal crowd barriers of French streets, red-and-white works barriers, sandbags, concertina wire on pickets, water-filled plastic barriers, cones, police tape, body bags, tarps, and the old-town classic: a barricade of setts torn up from the street, carts and furniture (shared with the barracks)
- [ ] 1.4.19.2 · Round 1 · form: sizes, how sandbags and setts stack and slump
- [ ] 1.4.19.3 · Round 2 · structure: the barriers' feet and hooks, sandbag seams and ties, the wire's coils and barbs, the tape's sag, the sett barricade's pile with a cart wheel and a wardrobe in it #ui
- [ ] 1.4.19.4 · Round 3 · surface: stencils, spray paint, torn bags spilling sand, rust on the wire
- [ ] 1.4.19.5 · Review: a checkpoint of each at 1 m and 10 m
- Under way: family `tools/models/props/checkpoint.py`: `barrier_crowd` (the galvanised crowd barrier, hooks and eyes to chain), `barrier_concrete` (the New Jersey profile), `sandbag_wall` (a 1.2 m module, bags as pillows in stretcher and header courses), `wire_coil` (concertina on pickets), `traffic_cone`, `works_barrier` (red and white boards, flasher), `water_barrier` (the filled plastic module, caps, knuckles), `body_bag` (the body's shape under it, zip, handles), `police_tape` (tape on two stakes, twisting, its loose end), `tarp` (draped over a pile, eyelets, ropes) and `sett_barricade` (setts in courses on a banked core, a handcart, barrels, a door, a wardrobe and chairs thrown on) have references and round 1, built. Left: rounds 2 and 3.

### [ ] 1.4.20 · Posters, flyers and painted words
> id: S186 | needs: S141 | size: S | asset: simple | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=decals`

- [ ] 1.4.20.1 · Card: spray-painted QUARANTAINE, NE PAS ENTRER, MORTS À L'INTÉRIEUR, arrows to ZONE SÛRE, missing-person flyers (DISPARU), official notices (AVIS À LA POPULATION) with the town's invented arms, old election posters, DÉFENSE D'AFFICHER painted on the walls
- [ ] 1.4.20.2 · Round 1 · form: sizes, and where they go (walls, shutters, cars, the road)
- [ ] 1.4.20.3 · Round 2 · structure: paint drips, layered and torn posters, tape holding the flyers
- [ ] 1.4.20.4 · Round 3 · surface: rain fading, sun bleaching, paint over paint #vfx
- [ ] 1.4.20.5 · Review: a wall of them at 1 m
- Under way: family `tools/models/props/decals.py`: `decals` (a 4 m wall bay of sprayed words, flyers, the AVIS, an election poster and the DÉFENSE D'AFFICHER band, all paint by position) has round 1, built. Left: photos, rounds 2 and 3, sheets for shutters, cars and the road.

### [ ] 1.4.21 · Street furniture placement
> id: S046 | needs: S041, S042, S166, S167, S168, S169, S170, S171, S172, S173 | size: M | rounds: 2 | tags: #art | test: `tests/test_street_furniture.gd` | see: `--furniture-rack`, `--host --shot-cam` on a street corner

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- Assembly: places the finished street furniture; nothing modelled here.
- [ ] 1.4.21.1 · Rules along streets, seeded, merged per block: réverbères hung on ropes over the old streets and lanterns on wall brackets, cast-iron candelabra on the main streets and quays, the ropes and wires of S167, traffic lights at the bigger junctions, street names carved in the corner stones and on blue plates, bus stops where the lines run, a colonne Morris and a kiosk now and then, benches, bins, bornes and railings by the squares and shops
- [ ] 1.4.21.2 · Lamps follow the two-shadow rule: emission and a cheap light, shadows only from the manager (S108)
- [ ] 1.4.21.3 · States by street: a few lamps flicker or hang dead, a réverbère down in the street on its rope, a sign bent
- [ ] 1.4.21.4 · Small props are cover; thin poles do not block bullets
- [ ] 1.4.21.5 · `--furniture-rack`: every piece of S166 to S173 in a row
- [ ] 1.4.21.6 · Round 1 · placement: an old lane, the quay and a main street against the card's references
- [ ] 1.4.21.7 · Round 2 · density and light: enough clutter to read as a lived-in town, the lamps' pools at night
- [ ] 1.4.21.8 · Review: the corner shot by day and night

### [ ] 1.4.22 · Apocalypse dressing
> id: S048 | needs: S046, S180, S181, S182, S183, S184, S185, S186, S203 | size: M | rounds: 2 | tags: #art | test: `tests/test_dressing.gd` | see: `--host --shot-cam` on the avenue

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- Assembly: places the finished vehicles and leftovers; the set pieces of `scenery.gd` are rebuilt from them.
- [ ] 1.4.22.1 · Vehicles in their states (S179's generator): parked, abandoned with doors open, crashed into a pole, rolled over, burnt out; hazard lights still blinking on a few, a dome light on, a wiper still moving
- [ ] 1.4.22.2 · Traffic jam generator along a street: a queue toward the way out of town, buses (S203) among the cars, gaps to walk through #anim
- [ ] 1.4.22.3 · Evacuation remains (S184) spilled along the jams and the sidewalks #anim
- [ ] 1.4.22.4 · Military and police leftovers (S185): checkpoints, sandbags, wire, body bags in rows
- [ ] 1.4.22.5 · Words and posters (S186) on walls, shutters and vehicles
- [ ] 1.4.22.6 · Blood: drag trails into doorways, handprints, pools under cars #vfx
- [ ] 1.4.22.7 · Small fires in barrels and wrecks (uses S094 when present, a plain flicker before)
- [ ] 1.4.22.8 · Wrecks are cover and block nav
- [ ] 1.4.22.9 · Round 1 · story: each scene reads as something that happened (the jam, the checkpoint that fell, the evacuation)
- [ ] 1.4.22.10 · Round 2 · density: walkable, not a wall of clutter, budgets held #perf #anim
- [ ] 1.4.22.11 · Review: the avenue shot and a checkpoint shot

### [ ] 1.4.23 · Helicopter model 2
> id: S154 | needs: S141, S179 | size: L | asset: complex | rounds: 4 | tags: #art | test: `tests/test_helicopter.gd` | see: `--prop-rack=helicopter`, `--host --map=corridor --heli --shot-at=3,6,9`

- Today it is twenty boxes (S024), and it ends every mission. `Helicopter`'s nodes and `HeliFlight` stay; the look is rebuilt.
- [ ] 1.4.23.1 · Card: a medium military transport helicopter of a French-style army (no one army's markings copied) (photos in `references/elements/` first), its real length and rotor span
- [ ] 1.4.23.2 · Round 1 · form: the fuselage's curves, the nose and its glazing, the cabin, the tail boom's taper, the fin and stabiliser, the engine housing; skids or wheels as in the photos #ui
- [ ] 1.4.23.3 · Round 2 · structure: sliding doors on rails, window frames, engine intakes and exhausts, the rotor head with its hub and pitch links, blade tips, the tail rotor's gearbox, steps, antennas, the door gun's mount
- [ ] 1.4.23.4 · Round 3 · surface: matt olive paint with panel lines and rivet rows baked, soot behind the exhausts, oil streaks, worn walkway paint, stencilled national markings and serials #anim
- [ ] 1.4.23.5 · Round 4 · inside and night: seats along the cabin walls, cargo nets, the cockpit's panels and seats; the nav lights, strobe and beacon as emission
- [ ] 1.4.23.6 · Review: the three flight shots and the rack sheet beside the photos

## 1.5 · Assets: nature
? Do we have the trees, shrubs and the forest wall, moving in the wind?
> tags: #art

### [ ] 1.5.1 · Plane tree
> id: S174 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=plane_tree`

- [ ] 1.5.1.1 · Card: photos of French avenue and quay plane trees: the mottled bark, the high broad crown, the pollarded ones in the squares
- [ ] 1.5.1.2 · Round 1 · form: heights from 12 to 25 m, the trunk's lean and fork, the crown's spread; a pollarded variant with knuckled branch ends
- [ ] 1.5.1.3 · Round 2 · structure: branching, leaf clusters, the hanging seed balls
- [ ] 1.5.1.4 · Round 3 · surface: the bark's patches of grey, olive and cream, the leaves' light and dark sides, autumn colour by preset
- [ ] 1.5.1.5 · Three variants and a LOD chain down to a card at 200 m; the wind of S047 moves the crown #perf
- [ ] 1.5.1.6 · Review: a row of six along the quay
- Under way: family `tools/models/props/trees.py`: `plane_tree` (seeded: buttressed trunk, fork, three levels of limbs, a dense crown of faceted clusters, the bark's patches painted) and `plane_pollard` (knuckles with tufts) have references and round 1, built, four LODs each. Left: the variants by seed, seed balls, a proper card at 200 m, autumn and wind, rounds 2 and 3.

### [ ] 1.5.2 · The old chestnut
> id: S175 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=chestnut`

- [ ] 1.5.2.1 · Card: photos of the old horse chestnuts (marronniers) of French squares and gardens: a thick trunk, a dome crown, the white candles of flowers in spring
- [ ] 1.5.2.2 · Round 1 · form: young and centuries-old shapes, trunk girths
- [ ] 1.5.2.3 · Round 2 · structure: burrs on the old trunk, branching, the hand-shaped leaves, the flower candles, the conkers on the ground
- [ ] 1.5.2.4 · Round 3 · surface: furrowed bark, moss on the north side, the leaves' greens and their early brown
- [ ] 1.5.2.5 · Review: young and old at 10 m and 50 m
- Under way: `chestnut_old` (family `tools/models/props/trees.py`: thick short trunk, low dome crown, white candles, furrowed bark with moss) has references and round 1, built. Left: the young variant, burrs, conkers, rounds 2 and 3.

### [ ] 1.5.3 · Street trees
> id: S176 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=street_trees`

- [ ] 1.5.3.1 · Card: the trees of French streets and courts: elm, lime, a paulownia, a flowering cherry, a fig against a court wall; young trees with stakes in their pits
- [ ] 1.5.3.2 · Round 1 · form: crown shapes and sizes, trunks
- [ ] 1.5.3.3 · Round 2 · structure: branching, the cherry's and paulownia's blossom, the petals' carpet on the ground (decals), stakes and guards #vfx
- [ ] 1.5.3.4 · Round 3 · surface: bark, the leaves' colour variation, autumn and bare variants by preset
- [ ] 1.5.3.5 · Review: each at 10 m and in a street
- Under way: `street_lime` (family `tools/models/props/trees.py`: a young staked lime, narrow oval crown) has round 1, built. Left: elm, paulownia, cherry, the court fig, photos, rounds 2 and 3.

### [ ] 1.5.4 · Shrubs and flowers
> id: S177 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=shrubs`

- [ ] 1.5.4.1 · Card: box parterres and clipped yews of a jardin à la française, roses, lilac, ivy and wisteria on walls, geraniums in window boxes, limes trained flat, the town hall's beds #vfx
- [ ] 1.5.4.2 · Round 1 · form: sizes and shapes, the parterre and hedge modules, the window box
- [ ] 1.5.4.3 · Round 2 · structure: flowers, branch structure, bed edges, ivy and wisteria following a wall
- [ ] 1.5.4.4 · Round 3 · surface: the blooms' colours, dead leaves, overgrown versions
- [ ] 1.5.4.5 · Review: a parterre and a window row at 1 m and 10 m
- Under way: family `tools/models/props/shrubs.py`: `window_box` (geraniums in zinc on brackets), `yew_cone` (clipped, in its box-edged bed), `hedge_box` (a 1 m module) and `ivy_patch` (stems and leaf clusters on a wall) have round 1, built. Left: photos, roses, lilac, wisteria, trained limes, rounds 2 and 3.

### [ ] 1.5.5 · Forest wall
> id: S178 | needs: S141 | size: L | asset: complex | rounds: 4 | tags: #art | test: `tests/test_elements.gd` | see: `--prop-rack=forest`

- The hill keeps Joinville's place and height; its forest is the oak and chestnut woods round Paris.
- [ ] 1.5.5.1 · Card: photos of the forests of the Île-de-France hills: oak, beech, sweet chestnut and hornbeam, the road's edge with brambles, ferns and ivy, sandstone boulders
- [ ] 1.5.5.2 · Round 1 · form: the layers (canopy, understorey, ground) and the hill's silhouette
- [ ] 1.5.5.3 · Round 2 · structure: each plant kind as a model: oak, beech, sweet chestnut, hornbeam, a dead standing trunk, hazel and holly below, ferns, brambles and grasses, fallen logs, boulders
- [ ] 1.5.5.4 · Round 3 · surface: the many greens, the beech's smooth grey bark, the chestnut's twisted ridges, ivy up the trunks
- [ ] 1.5.5.5 · Round 4 · distance: near models, middle cards, the far silhouette, the joins invisible; mist between the trunks at night
- [ ] 1.5.5.6 · Review: the hill road views and the hill from the town hall

### [ ] 1.5.6 · Vegetation placement and wind
> id: S047 | needs: S042, S174, S175, S176, S177, S178 | size: M | rounds: 2 | tags: #art | test: `tests/test_vegetation.gd` | see: `--tree-rack`, `--host --shot-cam` on a main street

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- Assembly and the shared systems: places the finished plants of S174 to S178.
- [ ] 1.5.6.1 · Planting rules: rows of plane trees and elms on the main streets and the quays, the old chestnuts on the squares, limes trained flat in the courts, box parterres in the formal gardens, window boxes and climbing ivy on the old houses, the forest wall where the hill rises #vfx
- [ ] 1.5.6.2 · Wind: vertex sway in a shader, stronger at the tips, gusts that travel across a street
- [ ] 1.5.6.3 · Grass tufts on lawns and verges as one MultiMesh, pressed down where zombies ran #perf
- [ ] 1.5.6.4 · Leaves fall and skitter along the gutter in gusts
- [ ] 1.5.6.5 · `--tree-rack`: every species and size in a row
- [ ] 1.5.6.6 · Round 1 · placement: a main street, the quay, a square, the edge of the hill
- [ ] 1.5.6.7 · Round 2 · motion: wind strength by place, gusts, nothing swimming
- [ ] 1.5.6.8 · Review: the four views beside the card's references

## 1.6 · The element library in the maps
? Is the library of about 140 elements placed, triaged and dressing the areas?
> tags: #map #art

### [ ] 1.6.1 · Place the element library in maps
> id: S247 | needs: S140 | size: M | tags: #map #art | test: `tests/test_placement.gd` | see: `--host --mission=hospital --shot-at=2`

- The library (`assets/models/props`, about 140 elements, each with LODs, states and parts) is built but nothing places it: props in the maps are still GDScript boxes.
- [ ] 1.6.1.1 · Map data `props`: `{ name, at, yaw, state, open }` per placed element, and `scatter` rules (an element along a line or over an area, seeded by the map)
- [ ] 1.6.1.2 · `PropModel` instances for few, one `MultiMesh` per element and state for many, LOD visibility ranges from `Elements.ALL` #perf
- [ ] 1.6.1.3 · Collision from each element's `.json` (boxes per part), nav cells closed under solid ones, moving parts (doors, lids, drawers) as interactables where the data says so
- [ ] 1.6.1.4 · Budget: draws and triangles of a placed set counted by `Budget`, `tests/test_placement.gd` holds a full area under `Config.BUDGET` #perf
- [ ] 1.6.1.5 · `--place-rack` lays a sample of every family on a street to look at

### [ ] 1.6.2 · Library triage
> id: S248 | needs: S140 | size: S | tags: #map #art | test: `python tools/models/props.py --list` | see: `references/elements/library.md`

- [ ] 1.6.2.1 · `references/elements/library.md`: every element by family, its round, whether its card has photos, its states, and which area uses it
- [ ] 1.6.2.2 · Each marked ready to place, or the round it still needs (a draft at round 1 is placed and improved in place)
- [ ] 1.6.2.3 · The elements each area needs and nobody has made yet, listed per area, so element steps are picked from that list first

### [ ] 1.6.3 · Area dressing from the library
> id: S249 | needs: S051, S247, S248 | size: L | rounds: 2 | tags: #map #art | test: `tests/test_area_dressing.gd` | see: `--mission=<each> --shot-cam`

- The area version of S046, S047 and S048, with the elements that exist: lamps, signs, small furniture, bus stops, kiosks, trees and shrubs, remains, checkpoint gear, wrecks. Seeded per area, the same on every peer.
- [ ] 1.6.3.1 · Along the area's streets: lamps and signs at their spacing, furniture by the doors and corners, trees where the plan has them
- [ ] 1.6.3.2 · The evacuation that failed: remains, abandoned cars, checkpoint gear, by the area's own story (the hospital's triage, the barracks' gate)
- [ ] 1.6.3.3 · The area's edge closed by placed barricades, wrecks and fences (S051's edge rules)
- [ ] 1.6.3.4 · Round 1 · each area's street views at eye height against the town's references
- [ ] 1.6.3.5 · Round 2 · night: lamps that work and those that don't
- [ ] 1.6.3.6 · Review: one sheet per area

## 1.7 · The five maps
? Is each mission its own area map round its POI, closed at its edges, navigable?
> tags: #map

### [ ] 1.7.1 · Mission areas
> id: S051 | needs: S002, S043 | size: L | tags: #map | test: `tests/test_mission_areas.gd` | see: `--mission=<each>`

- [ ] 1.7.1.1 · Each mission builds only its area: the POI and the streets around it, bounds polygon in map data
- [ ] 1.7.1.2 · Edges closed believably, never an invisible wall in the open: bus across the road, collapsed facade, burning pile-up, military fence, flood water
- [ ] 1.7.1.3 · Beyond the edge: low-detail blocks and the backdrop
- [ ] 1.7.1.4 · Build time per area under a limit, measured in the test
- [ ] 1.7.1.5 · Visibility ranges on small props, block meshes split so culling works #perf
- [ ] 1.7.1.6 · Each area is a map of its own (`GameMap` for one POI, from the same plan and data): a mission loads only it, never the whole town
- [ ] 1.7.1.7 · The whole-town map stays behind `--map=town` for tools and screenshots, not as the default
- [ ] 1.7.1.8 · The menu's pins start their area #ui

### [ ] 1.7.2 · City navigation 2
> id: S052 | needs: S051, S028 | size: M | tags: #map | test: `tests/test_city_nav.gd`

- [ ] 1.7.2.1 · Nav grid built per mission area at 1 m near the POI, 4 m in the streets
- [ ] 1.7.2.2 · Kerbs, wreck gaps, fences with holes and stairs are walkable links #anim
- [ ] 1.7.2.3 · Spawn closets authored per area: portes cochères, courtyard passages, impasses, cellar stairs, behind buses, manholes, each proven out of sight
- [ ] 1.7.2.4 · Horde routes authored per area so streams come down the town's streets and lanes
- [ ] 1.7.2.5 · Zombies do not walk through hedges, railings or water #anim
- [ ] 1.7.2.6 · Bot scenario: walk the whole mission route without getting stuck #anim

### [~] 1.7.3 · Lookout area, first playable
> id: S250 | needs: S051, S247 | size: L | tags: #map | test: `tests/test_mission_mirante.gd` | see: `--mission=mirante --bot`

- From what is built: the Mirante set, the vegetation and the smooth hill road (PRs 2, 4 to 6), in the lookout's own area map.
- [ ] 1.7.3.1 · The area: the hill from the park gate to the summit, its edge the forest; the town below as backdrop
- [ ] 1.7.3.2 · Names and signs French (S245): the telegraph tower, the chemin du Télégraphe
- [ ] 1.7.3.3 · Placed elements where the library has them (summit furniture, poles, lamps, signs, remains)
- [ ] 1.7.3.4 · The mission end to end on the area, bot scenario on easy
- [x] 1.7.3.5 · Built on the old real-Joinville set (PR 2, 5, 6): the gate, the forest road, the 14.5 m tower, the Mirante mission

### [~] 1.7.4 · Hospital area, first playable
> id: S251 | needs: S051, S247 | size: L | tags: #map | test: `tests/test_mission_hospital.gd` | see: `--mission=hospital --bot`

- From what is built: `hospital_set.gd` and its mission (PR 7).
- [ ] 1.7.4.1 · The area: the hospital's block and the streets round it, edges closed
- [ ] 1.7.4.2 · The hospital's elements placed (wheelchairs, gurneys, IV stands, oxygen, genset, helipad) instead of box props #ui
- [ ] 1.7.4.3 · The mission end to end on the area, bot scenario on easy
- [x] 1.7.4.4 · Built on the old real-Joinville set (PR 7): the tower, bay, old wing, annex, fire stair, helipad and the climb mission (`hospital_set.gd`)

### [~] 1.7.5 · Town hall area, first playable
> id: S252 | needs: S051, S247 | size: L | tags: #map | test: `tests/test_mission_prefeitura.gd` | see: `--mission=prefeitura --bot`

- From what is built: `prefeitura_set.gd` and its defend mission (PR 7).
- [ ] 1.7.5.1 · The area: the town hall, its lawn and garden, the quay along the river (a simple bank until S045)
- [ ] 1.7.5.2 · Elements placed: townhall name and arms, park furniture, lamps, barricade gear for the defence
- [ ] 1.7.5.3 · The defence end to end on the area, bot scenario on easy
- [x] 1.7.5.4 · Built on the old real-Joinville set (PR 7): the Prefeitura block, lawn, pad and the defend mission (`prefeitura_set.gd`)

### [ ] 1.7.6 · Bus station area, first playable
> id: S253 | needs: S051, S247 | size: L | tags: #map | test: `tests/test_mission_terminal.gd` | see: `--mission=terminal --bot`

- Nothing built beyond the placeholder: the station from the library's terminal parts (columns, trusses, signs, departure boards) on a simple slab.
- [ ] 1.7.6.1 · The area: the station, the place du Marché beside it and the streets out
- [ ] 1.7.6.2 · A first objective list (extraction across the area), checkpoint, way out
- [ ] 1.7.6.3 · Bot scenario on easy

### [ ] 1.7.7 · Barracks area, first playable
> id: S254 | needs: S051, S247 | size: L | tags: #map | test: `tests/test_mission_batalhao.gd` | see: `--mission=batalhao --bot`

- Nothing built beyond the placeholder: the court, the riding hall and the camp gear from the library, blocks as simple masses.
- [ ] 1.7.7.1 · The area: the barracks inside its wall, the gate and the street before it
- [ ] 1.7.7.2 · A first defend objective list with waves and the helicopter
- [ ] 1.7.7.3 · Bot scenario on easy

## 1.8 · Bus station
? Is the bus station built outside and in, with its mission?
> tags: #map #art

### [ ] 1.8.1 · Bus station: roof slab and fascia
> id: S197 | needs: S141 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_roof`

- The town's gare routière is a 1970s concrete canopy dropped into the old fabric by the main street; `terminal1.png` gives only the idea (a long slab on steel columns over platform islands) and the scale.
- [ ] 1.8.1.1 · Card: photos of French bus stations of the 1960s and 70s: a long concrete canopy, its edge band, the soffit; measured against 12 m buses under it
- [ ] 1.8.1.2 · Round 1 · form: the two slab halves and the gap of the skylight between them, the soffit, the fascia band along the main street
- [ ] 1.8.1.3 · Round 2 · structure: drip edges, expansion joints every bay, gutters and downpipes at the columns, recessed light cans in the soffit, the fascia's panels and fixings
- [ ] 1.8.1.4 · Round 3 · surface: raw concrete with board marks, black water stains running from every joint, algae on the shaded edge, grime, rust weeping from the brackets
- [ ] 1.8.1.5 · Round 4 · night: the soffit's lights (half dead), their pools on the wet setts (with S200), the stains still readable under them
- [ ] 1.8.1.6 · Review: the rack sheet and a view from the main street beside the references, with the old houses behind

### [ ] 1.8.2 · Bus station: steel columns and trusses
> id: S198 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_columns`

- [ ] 1.8.2.1 · Card: the columns of French canopy stations: steel trees opening from a node, on concrete pedestals (photos first)
- [ ] 1.8.2.2 · Round 1 · form: the tree's height and spread, the pedestal, where the arms meet the slab
- [ ] 1.8.2.3 · Round 2 · structure: I-section or tube members, gusset plates at the node, bolts, base plates, the trusses along the slab edges with their bracing #vfx
- [ ] 1.8.2.4 · Round 3 · surface: chipped paint, rust at the bases, posters taped to the pedestals, pigeon mess
- [ ] 1.8.2.5 · Review: at 1 m and from the platforms
- Under way: family `tools/models/props/terminal_columns.py`: `column_tree` (pedestal, base plate, trunk, node, four arms to bearing plates under the slab) and `edge_truss` (a 7.2 m Warren bay, gussets and bolts) have round 1, built (no photos yet: the step wants photos first). Left: photos, the arms' sections, rounds 2 and 3.

### [ ] 1.8.3 · Bus station: the skylight
> id: S199 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_skylight`

- [ ] 1.8.3.1 · Card: the glazed lantern in the gap between the slab halves (photos of French station roof lights)
- [ ] 1.8.3.2 · Round 1 · form: the frame's size and depth, how it sits or hangs
- [ ] 1.8.3.3 · Round 2 · structure: glass panes in frames, lattice members, fixtures inside, the hangers #vfx
- [ ] 1.8.3.4 · Round 3 · surface: dirty glass, dead insects, broken panes letting the rain through #vfx
- [ ] 1.8.3.5 · Night: the light from inside it (S108)
- [ ] 1.8.3.6 · Review: from below on the platforms

### [ ] 1.8.4 · Bus station: platforms, bays and setts
> id: S200 | needs: S141 | size: L | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_platforms`

- [ ] 1.8.4.1 · Card: photos of French bus station ground: granite setts in the bays, raised platform islands with high kerbs, the quay letters on posts
- [ ] 1.8.4.2 · Round 1 · form: the islands' heights and widths, bays long enough for 18 m articulated buses, kerb radii
- [ ] 1.8.4.3 · Round 2 · structure: the setts' rows and worn joints, tactile strips, drainage channels with grates, stop posts with their signs, quay letters, painted lines #vfx
- [ ] 1.8.4.4 · Round 3 · surface: oil stains in the bays, wet low spots (puddles for S110), gum and litter on the platforms
- [ ] 1.8.4.5 · Review: along a platform, wet

### [ ] 1.8.5 · Bus station: ticket office, kiosks and toilets
> id: S201 | needs: S141, S158 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_kiosks`

- [ ] 1.8.5.1 · Card: photos of French bus station buildings: the ticket office (GUICHETS), ticket machines, a snack kiosk and a café counter, the toilet block
- [ ] 1.8.5.2 · Round 1 · form: sizes and their places on the islands
- [ ] 1.8.5.3 · Round 2 · structure: the office's glass with its counter, the ticket machines' screens and slots, the kiosks' counters and shutters, the toilet block's doors and vents
- [ ] 1.8.5.4 · Round 3 · surface: stickers, timetables, grime, graffiti
- [ ] 1.8.5.5 · States: shutters down, smashed, a ticket machine torn open
- [ ] 1.8.5.6 · Review: a platform at eye height

### [ ] 1.8.6 · Bus station: route boards and wayfinding
> id: S202 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=terminal_signs`

- [ ] 1.8.6.1 · Card: French bus station signs: quay letters, line boards, the departure display (DÉPARTS); the destinations are invented quarters and villages (Vieille Ville, Gare, Faubourg Saint-Rémy, La Butte, Les Moulins, Saint-Martin-des-Prés, Zone Industrielle...) #vfx
- [ ] 1.8.6.2 · Round 1 · form: board sizes and heights, the quay letters
- [ ] 1.8.6.3 · Round 2 · structure: line numbers and destinations as lettering, the LED departure board, arrows, frames and hangers
- [ ] 1.8.6.4 · Round 3 · surface: faded print, the LED board dead or showing a last message
- [ ] 1.8.6.5 · Review: from the platforms at 5 m
- Under way: family `tools/models/props/terminal_signs.py`: `departure_board` (DÉPARTS and six invented departures in lit amber: the pipeline's new `emit_where` lights only the letters), `quay_sign` (the letter in its disc, the lines) and `wayfinding_sign` (QUAIS A - F, SORTIE, TAXIS with arrows) have round 1, built (no photos yet). Left: photos, the letter per quay, more blades, the dead board, rounds 2 and 3.

### [ ] 1.8.7 · The city bus
> id: S203 | needs: S179 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=bus`

- The town's buses fill the bus station and the jams; one livery, the town's own (white with a deep green band), no real operator's.
- [ ] 1.8.7.1 · Card: photos of French low-floor 12 m city buses and the 18 m articulated one
- [ ] 1.8.7.2 · Round 1 · form: the 12 m body, the big windscreen, the doors' places; the articulated variant with its bellows #ui
- [ ] 1.8.7.3 · Round 2 · structure: the LED destination board, the headlamps, mirrors on arms, double sliding-plug doors, window panes, the wheels, the roof's AC and the bellows' joint #ui
- [ ] 1.8.7.4 · Round 3 · surface: the livery with the line number, grime, stickers
- [ ] 1.8.7.5 · Round 4 · inside and states: low-floor seats, handrails and straps, the ticket validators and the driver's cab, windows you see through; doors open with the lights on, crashed across a road, a burnt shell
- [ ] 1.8.7.6 · Review: in a bay and at 1 m outside and inside

### [ ] 1.8.8 · The bus station
> id: S056 | needs: S053, S253, S249, S197, S198, S199, S200, S201, S202, S203 | size: L | rounds: 3 | tags: #map #art | test: `tests/test_poi_terminal.gd` | see: `--mission=terminal --shot-at=2`

- Assembly of the finished elements where the plan puts the gare routière (`--mission=terminal`); nothing modelled here.
- [ ] 1.8.8.1 · The slab (S197) on its columns (S198) with the skylight (S199), over the platforms and bays (S200), the ticket office, kiosks and toilets (S201) and the boards (S202)
- [ ] 1.8.8.2 · City buses (S203): some in the bays, one jack-knifed across the exit, one with its doors open and lights on
- [ ] 1.8.8.3 · Lighting: cold tube lights under the slab, half dead, puddles catching them
- [ ] 1.8.8.4 · The old houses of the main street round it, the place du marché (S049) a street away and joined to it
- [ ] 1.8.8.5 · Player start on the platforms, first weapon spots, first ammo
- [ ] 1.8.8.6 · Round 1 · layout: bays and islands laid out like the French references on the card, sized for the buses
- [ ] 1.8.8.7 · Round 2 · style match: fixed `--shot-cam` views from the platforms and the main street beside the card's references
- [ ] 1.8.8.8 · Round 3 · light and rain: the night and the rain (with S108 and S110 when they exist) #vfx
- [ ] 1.8.8.9 · Review: the style match sheets

### [ ] 1.8.9 · Mission: the bus station run
> id: S057 | needs: S056, S052, S022, S025 | size: L | tags: #map #art | test: `tests/test_mission_terminal.gd` | see: `--mission=terminal --bot`

- [ ] 1.8.9.1 · Route along the town's streets from the bus station to the town hall's garden, drawn in map data
- [ ] 1.8.9.2 · Beats
  - [ ] Leave the station: the buses block the easy exit, out through the place du marché
  - [ ] The old town: narrow crooked streets, jammed cars, a horde out of the portes cochères and passages
  - [ ] Checkpoint halfway: a shop with its shutters half up
  - [ ] The river: cross the stone bridge, a choke point
  - [ ] The quay under the plane trees, then the town hall's garden
- [ ] 1.8.9.3 · Extraction on the garden's lawn
- [ ] 1.8.9.4 · Director tuned for a moving fight: spawns ahead and behind, never on the route in view
- [ ] 1.8.9.5 · Bot scenario finishes it on easy

## 1.9 · Hospital
? Is the hospital built outside and in, with its climb?
> tags: #map #art

### [ ] 1.9.1 · Hospital: the old Hôtel-Dieu
> id: S204 | needs: S141, S157 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_old`

- The town's hospital grew over centuries: the old Hôtel-Dieu, a post-war wing and a new tower. `hospital1.jpg` and `hospital2.png` give only the arrangement (three volumes along one street, the tower tallest) and the scale.
- [ ] 1.9.1.1 · Card: photos of the old French hospitals of the 1600s and 1700s (Hôtel-Dieu, hospices): long stone wings round an arcaded court, a chapel with a dome, a gate pavilion on the street
- [ ] 1.9.1.2 · Round 1 · form: the wings' proportions round the court, the arcade, the chapel's dome, the gate pavilion
- [ ] 1.9.1.3 · Round 2 · structure: the arcade's piers and arches, tall windows (S157), string courses and cornice, the dome's lantern, the gate's pediment and leaves, a glass porch added later
- [ ] 1.9.1.4 · Round 3 · surface: limestone dark with soot, HÔTEL-DIEU carved over the gate, the court's worn flags, grime at street level
- [ ] 1.9.1.5 · Round 4 · night and decay: dark windows with a few lit, smoke stains from a burnt floor (the blocked floors of S059) #vfx
- [ ] 1.9.1.6 · Review: from the street and the court at 10 m and 50 m beside the references

### [ ] 1.9.2 · Hospital: the post-war wing
> id: S205 | needs: S141, S157 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_middle`

- [ ] 1.9.2.1 · Card: photos of French hospital wings of the 1960s and 70s: four or five floors, ribbon windows between coloured spandrel bands, a flat roof; an old house left standing beside it
- [ ] 1.9.2.2 · Round 1 · form: the wing and how it meets the Hôtel-Dieu, the house
- [ ] 1.9.2.3 · Round 2 · structure: the spandrels, the window bands (S157), the link bridge to the old wing, the house's windows, cornice and shopfront
- [ ] 1.9.2.4 · Round 3 · surface: faded spandrel colour, stains, the house's peeling plaster
- [ ] 1.9.2.5 · Review: at 10 m beside the references

### [ ] 1.9.3 · Hospital: the new tower
> id: S206 | needs: S141, S157 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_tower`

- [ ] 1.9.3.1 · Card: photos of new French hospital buildings: about eight floors of white panels and glass, a taller core carrying the lit sign, plant on the roof, a red aircraft light
- [ ] 1.9.3.2 · Round 1 · form: the volumes' heights and widths, the core
- [ ] 1.9.3.3 · Round 2 · structure: the frames and mullions of the glazing, sunshade fins, the sign's letters, the roof's plant, the canopy at the foot
- [ ] 1.9.3.4 · Round 3 · surface: white panels with joints, glass reflecting, stains
- [ ] 1.9.3.5 · Round 4 · night: a floodlight from below, the sign glowing, most windows dark and a few flickering #vfx
- [ ] 1.9.3.6 · Review: at night from the street and from the roof's height, over the old roofs

### [ ] 1.9.4 · Hospital: the street front
> id: S207 | needs: S141, S166 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_front`

- [ ] 1.9.4.1 · Card: photos of French hospital entrances: the drop-off canopy, the ramp, the ambulance bay, the low wall and the lamps
- [ ] 1.9.4.2 · Round 1 · form: the canopy's length and height, the ramp's slope, the bay
- [ ] 1.9.4.3 · Round 2 · structure: the canopy's posts, glass and gutters, railings, bollards, signs (URGENCES, RÉSERVÉ AMBULANCES)
- [ ] 1.9.4.4 · Round 3 · surface: grime, blood trails into the entrance, triage leftovers #vfx
- [ ] 1.9.4.5 · Review: from the street at eye height and from the tower's roof

### [ ] 1.9.5 · Hospital: rooftop helipad
> id: S208 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=helipad`

- [ ] 1.9.5.1 · Card: photos of rooftop helipads: the deck, the H in its circle, edge lights, safety netting, the windsock, the access stair
- [ ] 1.9.5.2 · Round 1 · form: the deck's size for the helicopter of S154, its height above the roof
- [ ] 1.9.5.3 · Round 2 · structure: the netting and its frame, edge lights, the windsock's mast, the stair and its gate, the fire hose box #vfx
- [ ] 1.9.5.4 · Round 3 · surface: worn paint, skid marks, rust on the frame
- [ ] 1.9.5.5 · Night: the edge lights (S108), the windsock's flood
- [ ] 1.9.5.6 · Review: from the stair and from the helicopter's approach
- Under way: `helipad` (family `tools/models/props/helipad.py`: the 16 m deck on its frame, H and touchdown ring painted, edge lights, netting, windsock, stair, hose box) has round 1, built (no photos yet). Left: photos, the stair's gate, the windsock's flood, rounds 2 and 3.

### [ ] 1.9.6 · Hospital: lobby and emergency room
> id: S209 | needs: S193, S194 | size: L | asset: complex | rounds: 3 | tags: #map #art #ui | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_er`

- [ ] 1.9.6.1 · Card: photos of a French hospital's reception and urgences: the desk, waiting chairs, triage, curtained bays
- [ ] 1.9.6.2 · Round 1 · form: the reception desk, the waiting rows, a curtained bay with its bed
- [ ] 1.9.6.3 · Round 2 · structure: curtain rails and curtains, ER beds with rails, monitors on arms, a crash cart, wall gas outlets, signs
- [ ] 1.9.6.4 · Round 3 · surface: blood, overturned chairs, scattered paperwork, a flickering monitor #vfx
- [ ] 1.9.6.5 · Review: the lobby and a bay at eye height

### [ ] 1.9.7 · Hospital: ward and corridor kit
> id: S210 | needs: S193, S194 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_ward`

- [ ] 1.9.7.1 · Card: ward rooms and corridors of a French hospital, and the long vaulted wards of the old Hôtel-Dieu
- [ ] 1.9.7.2 · Round 1 · form: the ward bed, bedside cabinet, over-bed table, the room's window and door, the nurses' station, the old ward's vault
- [ ] 1.9.7.3 · Round 2 · structure: bed rails and controls, curtain tracks, the bed-head panel with gas outlets and the nurse call, corridor handrails and bumper rails, vision panels in the doors
- [ ] 1.9.7.4 · Round 3 · surface: stained sheets, a ward barricaded from outside, handprints on the glass
- [ ] 1.9.7.5 · Review: a corridor and a ward at eye height

### [ ] 1.9.8 · Hospital: medical props
> id: S211 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=hospital_props`

- [ ] 1.9.8.1 · Card: IV stands, wheelchairs, gurneys, oxygen cylinders, medicine cabinets, sharps bins, monitors on poles #ui
- [ ] 1.9.8.2 · Round 1 · form: real sizes
- [ ] 1.9.8.3 · Round 2 · structure: castors and brakes, the gurney's frame and mattress, the cylinder's valve and trolley
- [ ] 1.9.8.4 · Round 3 · surface: chrome and plastic wear, blood, labels #vfx
- [ ] 1.9.8.5 · States: gurneys and wheelchairs piled up as a barricade #ui
- [ ] 1.9.8.6 · Review: everything at 1 m
- Under way: family `tools/models/props/hospital.py`: `wheelchair` (folding chair, spoked wheels, push rims), `gurney` (trolley with raised head and side rails), `iv_stand` (five legs, hooks, a bag and line) and `oxygen_cylinder` (on its trolley, valve and gauge) have round 1, built (references for the wheelchair and the drip stands; the gurney and the cylinder want photos). `medicine_cabinet` (glazed doors as parts) and `sharps_bin` have round 1 too. Left: monitors on poles, photos, rounds 2 and 3.

### [ ] 1.9.9 · Hospital: generator room
> id: S212 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=generator`

- [ ] 1.9.9.1 · Card: an emergency diesel generator set with its fuel tank and switchgear
- [ ] 1.9.9.2 · Round 1 · form: the set, the tank, the panels
- [ ] 1.9.9.3 · Round 2 · structure: the radiator grille, the exhaust pipe, cable trays, breakers and gauges, the start switch the players use
- [ ] 1.9.9.4 · Round 3 · surface: oil, warning signs, rust
- [ ] 1.9.9.5 · States: dead, and running (shaking, exhaust smoke, the lights coming on) #vfx
- [ ] 1.9.9.6 · Review: the room at eye height before and after the restart
- Under way: family `tools/models/props/generator.py`: `genset` (skid, engine, radiator and guard, alternator, exhaust with bellows and silencer, control box), `fuel_tank` (GAZOLE, gauge, feed and valve) and `switchgear` (three cabinets, meters and lamps, the start lever as a part) have round 1, built (no photos yet). Left: photos, the running state (shaking, smoke, lamps), rounds 2 and 3.

### [ ] 1.9.10 · The hospital, outside
> id: S058 | needs: S053, S251, S249, S182, S228, S204, S205, S206, S207, S208 | size: L | rounds: 3 | tags: #map #art | test: `tests/test_poi_hospital.gd` | see: `--mission=hospital --shot-at=2`

- Built on the old look (PR 7): `scripts/world/hospital_set.gd` (tower in three bodies, bay, old wing, annex, fire stair to the roof pad) and its mission. S251 brings it into its area; this step takes it to the bar with the hospital's elements.
- Assembly along the hospital's street of the finished wings and street front; nothing modelled here.
- [ ] 1.9.10.1 · The Hôtel-Dieu round its court (S204), the post-war wing and the house (S205), the new tower (S206), the street front (S207) and the helipad on the tower's roof (S208), where the plan puts them
- [ ] 1.9.10.2 · Night look: the tower lit from below, the sign glowing, most windows dark, a few flickering #vfx
- [ ] 1.9.10.3 · Street scene: abandoned ambulances (S182), triage tents in the old court (S228), a queue of cars that never got in (S048)
- [ ] 1.9.10.4 · Round 1 · layout: the three volumes' places and heights, the tower rising over the old town's roofs
- [ ] 1.9.10.5 · Round 2 · style match: fixed `--shot-cam` views (night from above, the street, the court) beside the card's references
- [ ] 1.9.10.6 · Round 3 · story: the street reads as a hospital overrun
- [ ] 1.9.10.7 · Review: the style match sheets

### [ ] 1.9.11 · Hospital, inside
> id: S059 | needs: S058, S054, S195, S209, S210, S211, S212 | size: L | rounds: 2 | tags: #map #art | test: `tests/test_poi_hospital_interior.gd` | see: `--mission=hospital --floor=3`

- [ ] 1.9.11.1 · Ground floor: the lobby and the emergency room (S209) #ui
- [ ] 1.9.11.2 · Ward floors: a long corridor, rooms both sides (S210), a nurses' station, a store room with loot #loot
- [ ] 1.9.11.3 · Not every floor is open: two are blocked by fire or collapse and are passed by the stairs #vfx
- [ ] 1.9.11.4 · Two stairwells (S192) and the elevator shaft (S195); the route forces a switch between them
- [ ] 1.9.11.5 · Power out: emergency lighting only
  - [ ] Red rotating beacons sweeping the corridors
  - [ ] Green exit signs (S194)
  - [ ] The generator room (S212): restart it to light a floor and call the elevator car
- [ ] 1.9.11.6 · Details: IV stands and gurneys used as barricades (S211), blood handprints on glass, a ward locked from the outside #vfx
- [ ] 1.9.11.7 · Nurse and doctor outfits weighted high here
- [ ] 1.9.11.8 · Round 1 · route: walked floor by floor, every room believable #anim
- [ ] 1.9.11.9 · Round 2 · light: emergency lighting only, readable but dark
- [ ] 1.9.11.10 · Review: one shot per floor

### [ ] 1.9.12 · Mission: the hospital climb
> id: S060 | needs: S059, S022, S024 | size: M | tags: #map #art | test: `tests/test_mission_hospital.gd` | see: `--mission=hospital --bot`

- [ ] 1.9.12.1 · Start in the street, in through the emergency entrance
- [ ] 1.9.12.2 · Objectives: find the keycard, restart the generator, reach the roof, hold the helipad until the helicopter lands
- [ ] 1.9.12.3 · Zombies come up the stairwells behind the players and out of wards ahead
- [ ] 1.9.12.4 · Checkpoint at the mid floor
- [ ] 1.9.12.5 · Roof finale: wind, the city spread out below, the helicopter's light finding the pad
- [ ] 1.9.12.6 · Bot scenario finishes it on easy

## 1.10 · Town hall
? Is the town hall built outside and in, with its defence?
> tags: #map #art

### [ ] 1.10.1 · Town hall: the front's bay
> id: S213 | needs: S141, S157 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_bay`

- The town hall (`--mission=prefeitura`) is a French hôtel de ville in the classical style of about 1800: a long stone front with a central pavilion carrying a campanile, an office wing behind. Joinville's Prefeitura gives only its place between the river and the hill and its garden in front.
- The front is one bay repeated: get one bay exactly right.
- [ ] 1.10.1.1 · Card: photos of French town halls of the 1700s and early 1800s: rusticated ground floor with round-arched doors and windows, tall windows of the first floor under pediments, pilasters, the balustrade along the roof
- [ ] 1.10.1.2 · Round 1 · form: two floors over a rusticated ground floor, the tall first-floor windows, the pavilions at the ends and the middle, the mansard over it
- [ ] 1.10.1.3 · Round 2 · structure: the rustication's joints, keystones, window pediments and the iron balconies, pilasters and their capitals, the cornice and the balustrade, niches with statues in the pavilions
- [ ] 1.10.1.4 · Round 3 · surface: weathered limestone with dark streaks, the motto LIBERTÉ ÉGALITÉ FRATERNITÉ over the door, the town's invented arms in the pediment
- [ ] 1.10.1.5 · Round 4 · decay: broken windows on the ground floor, barricade points (S055) in the openings
- [ ] 1.10.1.6 · Review: a run of bays from the garden at 10 m and 1 m

### [ ] 1.10.2 · Town hall: the campanile
> id: S214 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_towers`

- [ ] 1.10.2.1 · Card: photos of French town hall campaniles: a square stone lantern on the central pavilion's roof, the clock face in the pediment below it, the bell, the dome and its finial
- [ ] 1.10.2.2 · Round 1 · form: the campanile's height and plan, the dome
- [ ] 1.10.2.3 · Round 2 · structure: the clock face and hands, the open arches and the bell, the dome's ribs and lead, the flagstaffs
- [ ] 1.10.2.4 · Round 3 · surface: the stone's colour variation, the lead gone grey-white with streaks below, a clock stopped at one time
- [ ] 1.10.2.5 · Review: from the garden and from the quay
- Under way: `campanile` (family `tools/models/props/campanile.py`: base with the clock stopped at 4:20, the open arcaded stage with its bell, entablature, lead dome à l'impériale with ribs, lantern, finial, flagstaffs) has round 1, built (no photos yet). Left: photos, rounds 2 and 3.

### [ ] 1.10.3 · Town hall: the office wing
> id: S215 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_frames`

- [ ] 1.10.3.1 · Card: photos of the later administrative wings behind French town halls: three or four floors of plain windows, a glazed stair tower, a link to the old house
- [ ] 1.10.3.2 · Round 1 · form: the wing's length and floors, the stair tower, the link
- [ ] 1.10.3.3 · Round 2 · structure: window bands and spandrels, the stair tower's mullions, the entrance canopy, the link bridge's glazing
- [ ] 1.10.3.4 · Round 3 · surface: faded render, stains under the sills, blinds half down
- [ ] 1.10.3.5 · Review: from the car park and at eye height

### [ ] 1.10.4 · Town hall: the roofs
> id: S216 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_roof`

- [ ] 1.10.4.1 · Card: aerial photos of French town halls: the slate mansard with its oeil-de-boeuf dormers, the pavilions' steeper roofs, the wing's flat roof
- [ ] 1.10.4.2 · Round 1 · form: the roofs' plans and pitches, the campanile rising out of the middle
- [ ] 1.10.4.3 · Round 2 · structure: slate rows, dormers, ridge and hips with lead, the balustrade behind which they rise, gutters, the flat roof's plant and vents
- [ ] 1.10.4.4 · Round 3 · surface: moss, rust and lead streaks, patches, gull mess
- [ ] 1.10.4.5 · Review: from the helicopter's height

### [ ] 1.10.5 · Town hall: the garden
> id: S217 | needs: S141, S177 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_lawn`

- [ ] 1.10.5.1 · Card: photos of jardins à la française before French civic buildings: a raised terrace with stone stairs and balustrades, box parterres, gravel walks, clipped yews, a round basin, flagpoles #anim
- [ ] 1.10.5.2 · Round 1 · form: the terrace's shape and height, the stairs' flights and landings, the parterres and walks, the open lawn the helicopter lands on #anim
- [ ] 1.10.5.3 · Round 2 · structure: steps and copings, balusters, bed edging, the basin's rim, flagpoles with three flags, benches and urns
- [ ] 1.10.5.4 · Round 3 · surface: worn stone, moss, overgrown box, torn flags and a banner across the entrance
- [ ] 1.10.5.5 · Review: from the town hall's door and from the quay

### [ ] 1.10.6 · Town hall: the name and the arms
> id: S218 | needs: S141 | size: S | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_sign`

- [ ] 1.10.6.1 · Card: the carved and gilded HÔTEL DE VILLE over a French town hall's door, the motto on the frieze, and the town's coat of arms in the pediment; the arms are invented, never a real town's
- [ ] 1.10.6.2 · Round 1 · form: the letters' height and spacing, the shield's shape and frame
- [ ] 1.10.6.3 · Round 2 · structure: letters as geometry, the shield's charges in relief, the mural crown and the garlands round it
- [ ] 1.10.6.4 · Round 3 · surface: worn gilding, dirty letters, one letter missing
- [ ] 1.10.6.5 · Review: from the garden and at 1 m
- Under way: family `tools/models/props/townhall.py`: `townhall_name` (HÔTEL DE VILLE in gilded raised letters, the motto on the frieze) and `town_arms` (invented: a tower and three stars, mural crown, branches, ribbon) have round 1, built (no photos yet). Left: photos, rounds 2 and 3.

### [ ] 1.10.7 · Town hall: main hall and council chamber
> id: S219 | needs: S192, S193 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=prefeitura_hall`

- [ ] 1.10.7.1 · Card: photos of French town halls' stair halls and salles du conseil (put them in `references/elements/` first)
- [ ] 1.10.7.2 · Round 1 · form: the hall's height, the wide stone stair, the chamber's panelled room and its rows
- [ ] 1.10.7.3 · Round 2 · structure: the stair's wrought-iron railing, reception counters, the chamber's desks with microphones, the mayor's table, flags, the bust of Marianne and the town's arms, paintings on the panelling
- [ ] 1.10.7.4 · Round 3 · surface: parquet scuffed, papers everywhere, barricade attempts
- [ ] 1.10.7.5 · Review: both rooms at eye height

### [ ] 1.10.8 · Town hall, outside
> id: S061 | needs: S053, S252, S249, S213, S214, S215, S216, S217, S218 | size: L | rounds: 3 | tags: #map #art | test: `tests/test_poi_prefeitura.gd` | see: `--mission=prefeitura --shot-at=2`

- Built on the old look (PR 7): `scripts/world/prefeitura_set.gd` (the block, lawn, pad, flags) and a defend mission. S252 brings it into its area.
- Assembly between the river and the hill of the finished parts; nothing modelled here.
- [ ] 1.10.8.1 · The front from its bays (S213) with the campanile (S214), the office wing behind (S215), the roofs (S216)
- [ ] 1.10.8.2 · The garden (S217) with the name and arms over the door (S218); the open lawn is the landing zone
- [ ] 1.10.8.3 · A car park beside the wing (S048's cars), the quay and its plane trees in front (S045, S047), the wooded hill rising behind (S178)
- [ ] 1.10.8.4 · Round 1 · layout: the plan (front, wing, garden, car park) against French town halls on the card
- [ ] 1.10.8.5 · Round 2 · style match: fixed `--shot-cam` views from the quay and the garden beside the card's references
- [ ] 1.10.8.6 · Round 3 · abandoned: the car park jammed, the garden overgrown, the flags torn, without losing the place
- [ ] 1.10.8.7 · Review: the style match sheets

### [ ] 1.10.9 · Mission: hold the town hall
> id: S062 | needs: S061, S054, S055, S023, S024, S219 | size: L | tags: #map #art | test: `tests/test_mission_prefeitura.gd` | see: `--mission=prefeitura --bot`

- [ ] 1.10.9.1 · Inside: the stair hall, the salle du conseil, the office wing, the campanile's stair, roof access
- [ ] 1.10.9.2 · Defend the hall: many windows and three doors to barricade, plank piles, ammo crate
- [ ] 1.10.9.3 · Three waves, each from more sides: the garden, the car park, then out of the forest behind
- [ ] 1.10.9.4 · Between waves: restock, repair
- [ ] 1.10.9.5 · Finale: fall back to the lawn, the helicopter lands among the horde
- [ ] 1.10.9.6 · Bot scenario survives on easy

## 1.11 · Barracks
? Are the barracks built with their vehicles, camp and defence?
> tags: #map #art

### [ ] 1.11.1 · Barracks: barrack blocks
> id: S220 | needs: S141, S157 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_barracks`

- The army barracks (`--mission=batalhao`) is a French caserne of the 1700s and the Empire: long stone blocks round a cour d'honneur. `batalhao.jpg` and `batalhao2.jpg` give only the arrangement (a quadrangle with a front building, a gym, a field behind) and the scale.
- [ ] 1.11.1.1 · Card: photos of French casernes of about 1800: long three- or four-storey blocks of stone and plaster, regular windows, mansard or hipped slate roofs, a pediment on the middle pavilion
- [ ] 1.11.1.2 · Round 1 · form: lengths, widths, floors, roof pitches and hips, the pavilions
- [ ] 1.11.1.3 · Round 2 · structure: slate rows with ridge and hip caps, dormers, string courses, stone window frames, doors with their steps, the middle pavilion's pediment #perf
- [ ] 1.11.1.4 · Round 3 · surface: the stone's and slates' colour variation, moss, an invented regiment's number painted on one pavilion
- [ ] 1.11.1.5 · Review: from the cour d'honneur and from above

### [ ] 1.11.2 · Barracks: the gate pavilion
> id: S221 | needs: S141, S157 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_front`

- [ ] 1.11.2.1 · Card: photos of French caserne gates: a two-storey stone pavilion with a great arch through it, carved trophies of arms over it, sentry boxes at both sides, wings at both ends
- [ ] 1.11.2.2 · Round 1 · form: the front's length, the arch, the wings, the roof
- [ ] 1.11.2.3 · Round 2 · structure: the arch and its rustication, the trophies and the carved QUARTIER name (invented), windows in stone frames, the cornice, the gate leaves under the arch, the sentry boxes
- [ ] 1.11.2.4 · Round 3 · surface: stone weathered and sooty, an invented army's crest (simplified), stains
- [ ] 1.11.2.5 · Round 4 · battle: sandbags in the windows, bullet pocks, a burnt room
- [ ] 1.11.2.6 · Review: from the street and from the cour d'honneur

### [ ] 1.11.3 · Barracks: the cour d'honneur
> id: S222 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_ground`

- [ ] 1.11.3.1 · Card: photos of French barracks courts: setts or gravel with painted lines, a lawn with a memorial and flagpoles
- [ ] 1.11.3.2 · Round 1 · form: the court's size, the surface, the lawn
- [ ] 1.11.3.3 · Round 2 · structure: joints, painted lines and markers, the memorial (a column with names), flagpoles and their bases, kerbs
- [ ] 1.11.3.4 · Round 3 · surface: oil stains where vehicles stand, grass between the setts, faded paint
- [ ] 1.11.3.5 · Review: from above
- Under way: family `tools/models/props/barracks_court.py`: `war_memorial` (steps, die with AUX MORTS and invented names, column, bronze helmet and wreaths, bollards and chains) and `flagpoles` (three, a limp flag) have round 1, built (no photos yet). Left: photos, the court's setts and painted lines, the lawn's kerbs, rounds 2 and 3.

### [ ] 1.11.4 · Barracks: perimeter, gate and guard tower
> id: S223 | needs: S141, S185 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_gate`

- [ ] 1.11.4.1 · Card: photos of French barracks perimeters: a high stone wall with a mesh fence and barbed wire on top, the vehicle gate with its guard house and boom barrier, a guard tower with a searchlight
- [ ] 1.11.4.2 · Round 1 · form: wall height, gate width, the tower's height and cabin
- [ ] 1.11.4.3 · Round 2 · structure: the wall's piers and coping, the fence, the barrier's arm and post, the guard house's windows, the tower's ladder and rail, the searchlight's yoke
- [ ] 1.11.4.4 · Round 3 · surface: stains, rust, the warning signs at the gate (TERRAIN MILITAIRE, DÉFENSE D'ENTRER) #vfx
- [ ] 1.11.4.5 · Review: from the street at eye height

### [ ] 1.11.5 · Barracks: the riding hall and court
> id: S224 | needs: S141 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_gym`

- [ ] 1.11.5.1 · Card: photos of the old riding halls (manèges) of French casernes, now gyms: a long stone hall with a big timber or iron roof, the sports court beside it
- [ ] 1.11.5.2 · Round 1 · form: the roof's span and length, the end walls, the court
- [ ] 1.11.5.3 · Round 2 · structure: the roof's trusses, the end walls' round windows and great doors, the court's lines, posts and nets
- [ ] 1.11.5.4 · Round 3 · surface: moss on the roof, the court's paint faded
- [ ] 1.11.5.5 · Review: from the cour d'honneur
- Under way: family `tools/models/props/riding_hall.py`: `riding_hall` (the stone manège, eight round-headed windows a side, oculi, the great doors as parts, slate roof, ridge vent, iron trusses) and `sports_court` (lines painted, basketball and volleyball) have round 1, built (no photos yet). Left: photos, the interior, rounds 2 and 3.

### [ ] 1.11.6 · Army truck
> id: S225 | needs: S179 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=army_truck`

- [ ] 1.11.6.1 · Card: photos of European armies' cargo trucks (no one army's markings copied)
- [ ] 1.11.6.2 · Round 1 · form: cab, chassis, the cargo bed under its canvas
- [ ] 1.11.6.3 · Round 2 · structure: the canvas hoops and straps, tailgate, spare wheel, jerrycans, bumpers, mirrors #ui
- [ ] 1.11.6.4 · Round 3 · surface: an invented green and brown camouflage, mud, stencils
- [ ] 1.11.6.5 · Review: at 1 m and 10 m in every state

### [ ] 1.11.7 · Light 4×4
> id: S226 | needs: S179 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=army_4x4`

- [ ] 1.11.7.1 · Card: photos of European armies' light 4×4 utility vehicles
- [ ] 1.11.7.2 · Round 1 · form: body, soft top or open, wheels #ui
- [ ] 1.11.7.3 · Round 2 · structure: roll bar, gun mount, jerrycans, antennas, tow hooks
- [ ] 1.11.7.4 · Round 3 · surface: the same invented camouflage, mud, stencils
- [ ] 1.11.7.5 · Review: at 1 m and 10 m

### [ ] 1.11.8 · Wheeled armoured personnel carrier
> id: S227 | needs: S179 | size: L | asset: complex | rounds: 3 | tags: #map #art #ui | test: `tests/test_elements.gd` | see: `--prop-rack=apc`

- [ ] 1.11.8.1 · Card: photos of European 6×6 and 8×8 wheeled APCs (no one model copied)
- [ ] 1.11.8.2 · Round 1 · form: the faceted hull, six wheels, the turret
- [ ] 1.11.8.3 · Round 2 · structure: hatches, periscopes, the rear ramp, lights in their guards, smoke launchers, the turret's gun #vfx
- [ ] 1.11.8.4 · Round 3 · surface: camouflage, mud, scorch from a fire #vfx
- [ ] 1.11.8.5 · Review: at 1 m and 10 m, the ramp down

### [ ] 1.11.9 · Military camp gear
> id: S228 | needs: S141, S185 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=camp`

- [ ] 1.11.9.1 · Card: field tents, camouflage nets, ammunition crates, weapon racks, field radios, cots, jerrycans
- [ ] 1.11.9.2 · Round 1 · form: sizes
- [ ] 1.11.9.3 · Round 2 · structure: the tents' ropes, pegs and seams, the net's leaves, crate latches, the radio's knobs and handset
- [ ] 1.11.9.4 · Round 3 · surface: mud, stencils, wear
- [ ] 1.11.9.5 · Review: a corner of the camp at eye height

### [ ] 1.11.10 · Barracks interiors
> id: S229 | needs: S191, S193 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=batalhao_rooms`

- [ ] 1.11.10.1 · Card: photos of barracks rooms, an armoury and a mess hall (put them in `references/elements/` first)
- [ ] 1.11.10.2 · Round 1 · form: the armoury's cage, rows of bunks and lockers, mess tables, the command room's desk and map wall
- [ ] 1.11.10.3 · Round 2 · structure: gun racks and their locks, bunk frames and mattresses, the lockers' vents and names, the radio set
- [ ] 1.11.10.4 · Round 3 · surface: order left in panic: kit spilled, beds overturned
- [ ] 1.11.10.5 · Review: each room at eye height

### [ ] 1.11.11 · The barracks, outside
> id: S064 | needs: S053, S254, S249, S220, S221, S222, S223, S224, S225, S226, S227, S228 | size: L | rounds: 3 | tags: #map #art | test: `tests/test_poi_batalhao.gd` | see: `--mission=batalhao --shot-at=2`

- Assembly where the plan puts the caserne of the finished parts; nothing modelled here.
- [ ] 1.11.11.1 · The quadrangle of barrack blocks (S220) round the cour d'honneur (S222), the gate pavilion (S221), the riding hall and court (S224), the field behind
- [ ] 1.11.11.2 · The perimeter, gate and guard tower (S223); the searchlight still turns
- [ ] 1.11.11.3 · Vehicles in the court (S225, S226, S227), gun pits and tents (S228, S185)
- [ ] 1.11.11.4 · Round 1 · layout: the quadrangle against French caserne plans on the card
- [ ] 1.11.11.5 · Round 2 · style match: fixed `--shot-cam` views from the gate and from above beside the card's references
- [ ] 1.11.11.6 · Round 3 · the last stand: the base as its defenders left it
- [ ] 1.11.11.7 · Review: the style match sheets

### [ ] 1.11.12 · Mission: hold the barracks
> id: S065 | needs: S064, S054, S063, S023, S024, S229, S244 | size: L | tags: #map #art | test: `tests/test_mission_batalhao.gd` | see: `--mission=batalhao --bot`

- [ ] 1.11.12.1 · Inside: armoury with ammo crates and gun racks behind a locked cage, barrack rooms, mess hall, command room with the radio
- [ ] 1.11.12.2 · Objectives: get in through the gate, call the helicopter on the radio, open the armoury, hold the cour d'honneur
- [ ] 1.11.12.3 · Mounted guns in the pits and on the tower
- [ ] 1.11.12.4 · Waves pour over the walls and through the gate; soldier zombies in the mix #sound
- [ ] 1.11.12.5 · The helicopter lands in the middle of the court
- [ ] 1.11.12.6 · Bot scenario survives on easy

## 1.12 · Lookout
? Is the lookout on the hill built, its road and trail, and its mission?
> tags: #map #art

### [ ] 1.12.1 · Lookout: the telegraph tower
> id: S230 | needs: S141 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_tower`

- The hill keeps Morro da Boa Vista's place and height (`CityHeights`); on top stands the old stone tower that carried a Chappe telegraph around 1800, now a lookout (`--mission=mirante`), with a windmill beside it.
- [ ] 1.12.1.1 · Card: engravings and photos of Chappe telegraph towers and the windmills of the hills round Paris (put them in `references/elements/` first and build nothing from memory; S066 waits on this too) #perf
- [ ] 1.12.1.2 · Round 1 · form: the tower's height and plan, the deck on top, the stair inside; the windmill's tower and sails
- [ ] 1.12.1.3 · Round 2 · structure: the stone courses, the telegraph's mast with its beam and arms still on the roof, the deck's railing, the stair, the windmill's cap, sails and tail pole, a mast with antennas added later #perf
- [ ] 1.12.1.4 · Round 3 · surface: weathered by the summit's wind: lichen, rust, carved initials, torn sail cloth
- [ ] 1.12.1.5 · Round 4 · night and wind: its lights, the antennas' lights, the sails creaking round, cloud wisps through the deck
- [ ] 1.12.1.6 · Review: beside the references

### [ ] 1.12.2 · Lookout: summit furniture
> id: S231 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_summit`

- [ ] 1.12.2.1 · Card: coin binoculars, a panorama table naming what you see, the summit's railings, a guinguette with its terrace, antenna masts with red lights (photos first)
- [ ] 1.12.2.2 · Round 1 · form: sizes
- [ ] 1.12.2.3 · Round 2 · structure: the binoculars' head and coin box, the panorama table's engraved plate, railing posts, the guinguette's arbour, tables and lamps, the masts' lattice and guy wires
- [ ] 1.12.2.4 · Round 3 · surface: weathering
- [ ] 1.12.2.5 · Review: the summit at eye height
- Under way: family `tools/models/props/summit.py`: `coin_binoculars`, `panorama_table` (the bronze plate naming the town's places) and `antenna_mast` (guyed lattice, panels, dish, red lamps) have round 1, built (no photos yet). Left: photos, the summit's railings, the guinguette, rounds 2 and 3.

### [ ] 1.12.3 · Lookout: the park gate
> id: S232 | needs: S141, S177 | size: L | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_gate`

- [ ] 1.12.3.1 · Card: photos of the gates of French hill parks and estates: stone piers with urns and the hill's invented name carved on them, an iron grille, a small gatekeeper's lodge (pavillon de garde), the car park's edge, a map board; `mirante_entrance.jpg` gives only the scale (a two-lane road through it)
- [ ] 1.12.3.2 · Round 1 · form: the piers' and the lodge's sizes against a car, the road through
- [ ] 1.12.3.3 · Round 2 · structure: the piers' caps, urns and lettering, the grille's bars and gilded tips, the lodge's windows, door and roof, a barrier added later, kerbs, the map board #perf
- [ ] 1.12.3.4 · Round 3 · surface: moss on the stone, the lettering's worn paint, rust on the grille
- [ ] 1.12.3.5 · Round 4 · style match: a fixed `--shot-cam` view up the road through the gate beside the card's references
- [ ] 1.12.3.6 · Review: the style match and the rack at 1 m

### [ ] 1.12.4 · Lookout: the hill road
> id: S233 | needs: S141, S167 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=mirante_road`

- [ ] 1.12.4.1 · Card: photos of old French roads up a wooded hill: a narrow road of setts, a gravel verge, stone gutters, a low stone parapet on the outside of bends, a mossy retaining wall uphill
- [ ] 1.12.4.2 · Round 1 · form: lane widths, verges; modules that follow the road's curve and grade
- [ ] 1.12.4.3 · Round 2 · structure: the setts' edges and asphalt patches, gutters, parapets on the outside of bends, the retaining wall, milestones (bornes kilométriques)
- [ ] 1.12.4.4 · Round 3 · surface: moss, leaves, wet patches under the canopy
- [ ] 1.12.4.5 · Review: a bend and the hairpin at eye height

### [ ] 1.12.5 · Lookout: the trail
> id: S234 | needs: S141, S178 | size: M | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=trail`

- [ ] 1.12.5.1 · Card: photos of French forest trails (put them in `references/elements/` first): dirt steps held by logs, roots, sandstone rocks, a wooden handrail, a painted waymark on a trunk
- [ ] 1.12.5.2 · Round 1 · form: the steps' heights, the path's width
- [ ] 1.12.5.3 · Round 2 · structure: logs and stakes, roots across the path, rocks, a fallen tree, waymarks
- [ ] 1.12.5.4 · Round 3 · surface: mud, leaf litter, moss
- [ ] 1.12.5.5 · Review: walking it at eye height #anim

### [ ] 1.12.6 · Lookout, the summit
> id: S066 | needs: S053, S250, S249, S230, S231 | size: L | rounds: 2 | tags: #map #art | test: `tests/test_poi_mirante.gd` | see: `--mission=mirante --shot-at=2`

- Built on the old look (PRs 2, 4 to 6): `scripts/world/mirante_set.gd` (gate, poles, guard rails, the tower with walkable stairs, snack bar, radio masts), `vegetation.gd`, the smooth hill road band. S250 brings it into its area.
- [ ] 1.12.6.1 · The telegraph tower and the windmill (S230) and the summit's clearing with its furniture (S231): car park, railings, coin binoculars, the guinguette, antenna masts with red lights
- [ ] 1.12.6.2 · The view: the whole town backdrop below, the church tower and the campanile, lit windows, fires, the river as a pale line
- [ ] 1.12.6.3 · Wind up here: stronger sway, louder, the windmill's sails turning, cloud wisps passing through the deck at night
- [ ] 1.12.6.4 · Player start on the deck
- [ ] 1.12.6.5 · Round 1 · layout: the summit against the card's references and `joinville_topography.png` (its height and shape only)
- [ ] 1.12.6.6 · Round 2 · the view: the town from the deck at night reads as old Paris under siege
- [ ] 1.12.6.7 · Review: the deck's view and the summit at eye height

### [ ] 1.12.7 · Lookout, the road down
> id: S067 | needs: S066, S250, S167, S178, S232, S233, S234 | size: L | rounds: 3 | tags: #map #art | test: `tests/test_poi_mirante_road.gd` | see: `--mission=mirante --shot-cam` on the hairpin

- [ ] 1.12.7.1 · The hill road (S233) along the road of the plan, the hairpin and the grade from `CityHeights`; everything placed with `map.ground_y`
- [ ] 1.12.7.2 · Forest walls both sides (S178), canopy closing overhead; wooden poles with their wires following the road (S167)
- [ ] 1.12.7.3 · The park gate at the foot (S232)
- [ ] 1.12.7.4 · Side trail (S234) as a risky shortcut: no lamps
- [ ] 1.12.7.5 · A few lamps only, long dark stretches for flashlights #vfx
- [ ] 1.12.7.6 · Round 1 · layout: the road's line, width and grade against the topography
- [ ] 1.12.7.7 · Round 2 · style match: fixed `--shot-cam` views of a bend and of the gate beside the card's references
- [ ] 1.12.7.8 · Round 3 · night: the dark stretches, the few lamps, fog between the trunks #vfx
- [ ] 1.12.7.9 · Review: the style match sheets and the hairpin at night

### [ ] 1.12.8 · Mission: down from the lookout
> id: S068 | needs: S067, S052, S022 | size: M | tags: #map #art | test: `tests/test_mission_mirante.gd` | see: `--mission=mirante --bot`

- As built (PR 2) the mission runs the other way: from the gate up the road to the helicopter on the tower. Decide here whether it stays a climb or becomes the descent below.
- [ ] 1.12.8.1 · Descend the tower: tight stairs, leapers
- [ ] 1.12.8.2 · The road: leapers drop out of the trees, runners come up the road in packs, fog between the trunks #vfx
- [ ] 1.12.8.3 · Checkpoint at the hairpin
- [ ] 1.12.8.4 · Choice: the lit road or the dark trail
- [ ] 1.12.8.5 · Extraction at the park gate at the foot, a truck instead of the helicopter
- [ ] 1.12.8.6 · Bot scenario finishes it on easy

## 1.13 · Survival loop
? Do ammo, items, health, downing, stamina and noise make a match tense?
> tags: #gameplay

### [x] 1.13.1 · Limited ammo
> id: S011 | needs: none | size: M | tags: #gameplay | test: `tests/test_ammo.gd`

- [x] 1.13.1.1 · Ammo types by calibre: 9 mm, 5.7, 5.8, 7.62, 9x39, 12 gauge, .338, 7.62R
- [x] 1.13.1.2 · Reserve per type in `weapon_state.gd`, reload takes from it, partial reload when short
- [x] 1.13.1.3 · Shotgun shell-by-shell reload stops when the reserve is empty
- [x] 1.13.1.4 · Dry fire: click, small viewmodel twitch, no shot sent #sound #vfx #anim #art
- [x] 1.13.1.5 · Starting reserve per mission in map data, test maps keep infinite ammo behind `GameMap.infinite_ammo`
- [x] 1.13.1.6 · Host knows each player's reserve (sent on change, not per snapshot) so pickups are honest #net #loot
- [x] 1.13.1.7 · HUD shows magazine / reserve #ui

### [x] 1.13.2 · Ammo pickups and crates
> id: S012 | needs: S011, S002 | size: M | tags: #gameplay #loot | test: `tests/test_ammo_pickups.gd` | see: `--host --map=corridor --shot-at=2`

- [x] 1.13.2.1 · Ammo box interactable: small carton per calibre, coloured stripe, count printed as box pips
- [x] 1.13.2.2 · Ammo crate: military green, gives the held gun's type, limited uses, lid hinge animation #anim
- [x] 1.13.2.3 · Zombie drops: seeded by zombie id, rare, soldiers and cops more often
- [x] 1.13.2.4 · Pickup feel: box hops to the player over 0.15 s, shrinks, small "+30" rises on the HUD #ui
- [x] 1.13.2.5 · `on_ammo_picked_up` hook

### [x] 1.13.3 · Loadout
> id: S013 | needs: S011 | size: M | tags: #gameplay | test: `tests/test_loadout.gd`

- [x] 1.13.3.1 · Slots: two primaries, one sidearm, one melee
- [x] 1.13.3.2 · Picking up with full slots swaps: the old gun drops at the feet as a `WeaponPickup` with its magazine count #loot
- [x] 1.13.3.3 · Number keys follow slots, wheel cycles, last-weapon key #ui
- [x] 1.13.3.4 · Holster and draw animation per swap (existing draw timer), slower for heavy guns #anim
- [x] 1.13.3.5 · Start: pistol only on missions, everything on test maps (`all_weapons`)
- [x] 1.13.3.6 · Dropped guns sync to late joiners #net

### [x] 1.13.4 · Inventory and item wheel
> id: S014 | needs: S013 | size: L | tags: #gameplay #ui | test: `tests/test_inventory.gd` | see: `--host --map=corridor --wheel --shot-at=3`

- [x] 1.13.4.1 · `scripts/inventory.gd`, no nodes: counted stacks with caps #perf
  - [x] Medkit, bandage, painkillers
  - [x] Throwable slots (filled later)
  - [x] Keys and keycards by id
  - [x] Planks for barricades
- [x] 1.13.4.2 · Host owns it, client gets its own inventory on change #net
- [x] 1.13.4.3 · Hold a key for a radial wheel: eight wedges, icons drawn from boxes, mouse direction picks, time slows nothing
  - [x] Eight wedges (`ItemWheel`, `ItemWheelView`): hold Tab, the mouse moves a pointer instead of the view, release picks
  - [x] Icons drawn from boxes (`ItemIcons`), a little hop when a wedge is lit
- [x] 1.13.4.4 · Quick-use keys for heal (H) and throwable (G)
- [x] 1.13.4.5 · Drop on death as a backpack other players can loot #loot
- Medkit and bandage heal at once for now; painkillers and throwables are consumed with no effect until S015 and S093 write theirs in `GameHooks.on_item_used`.

### [x] 1.13.5 · Bleeding and healing
> id: S015 | needs: S014 | size: M | tags: #gameplay | test: `tests/test_bleeding.gd`

- [x] 1.13.5.1 · Bleed chance on a hit, stacks to three, ticks HP, pinned in tests
- [x] 1.13.5.2 · Bandage stops bleeding, medkit restores HP over its use time, painkillers give decaying temporary HP
  - The medkit and bandage are spent and heal only when their use time (`Inventory.use_time`) is over; a hit or a sprint cancels them and the item stays in the pack
- [x] 1.13.5.3 · Use animation in first person: gun lowers, hands wrap a bandage (four eased poses), cancelled by sprint or damage #anim
  - `Viewmodel.heal` / `heal_goal` / `heal_t`, `HEAL_POSES`, `heal_hands(t)`; the player sets them from `status`; `--pose=heal` shows it
- [x] 1.13.5.4 · Others see the heal pose on the remote player #anim
  - `Humanoid.Anim.HEAL`, picked by `RemotePlayer.anim_for` from `PlayerWire.ACTION_HEAL`
- [x] 1.13.5.5 · Bleeding look: red drops from the lower screen edge, drip trail decals behind the player, heartbeat when low #vfx #ui
  - `BleedDrops` on the HUD, `BleedTrail` + `Game.update_drips` (every peer, from `ACTION_BLEED`), `Heartbeat` and the `heartbeat` sound
- [x] 1.13.5.6 · `on_player_bleeding`, `on_player_healed` hooks (and `on_item_use_cancelled`)

### [x] 1.13.6 · Downed and revive
> id: S016 | needs: S015, S003 | size: L | tags: #gameplay | test: `tests/test_downed.gd` | see: `tools\play2.ps1`

- [x] 1.13.6.1 · At 0 HP a player is downed, not dead: bleed-out timer, pistol only, crawl speed
  - Only while a teammate is still standing to get them up: the last one standing just dies. Damage to a downed player costs bleed-out time and can finish them
- [x] 1.13.6.2 · First-person camera drops to the floor, tilts, desaturates toward grey as the timer runs
  - `LocalPlayer.step_down_view`, `view_height`, `view_roll`; `Hud.grey_for` drives a screen shader; `--pose=downed`
- [x] 1.13.6.3 · Third-person rig: fall animation, propped on one arm, crawl cycle, reaching hand when a teammate is near #anim
  - `Humanoid.Anim.DOWNED` (slow blend: the fall) with `reach`, `CRAWL` when moving; `RemotePlayer.animate`, `Game.update_reach`
- [x] 1.13.6.4 · Revive: hold use within reach for `Config.REVIVE_SECONDS`, progress ring on both HUDs, interrupted by damage to the reviver #ui
  - [x] Hold right-click beside a downed teammate (`Game.downed_teammate_near`, `start_revive`, `client_revive`); damage, a sprint, walking off or letting go cancels it; the bleed-out clock waits while it runs
  - [x] The progress ring round the crosshair (`ProgressRing`, `Hud.ring_for`), for heals too
- [x] 1.13.6.5 · Revived at partial HP with a get-up animation and brief invulnerability #anim
  - [x] `Config.REVIVE_HP` and `Config.REVIVE_INVULN` seconds in which nothing hurts them
  - [x] The get-up animation (`Humanoid.Anim.GETUP` for `Config.GETUP_TIME` on others, the view rising for yourself)
- [x] 1.13.6.6 · Zombies prefer standing players, finish downed ones when nobody else is near
- [x] 1.13.6.7 · All downed at once fails the mission

### [x] 1.13.7 · Death and spectating
> id: S017 | needs: S016 | size: M | tags: #gameplay | test: `tests/test_spectate.gd`

- [x] 1.13.7.1 · Death camera: pulls back and up from the body, slow orbit, zombies feed on the corpse
  - `Spectator.orbit_goal`; the body is `Game.player_body` (a ragdoll of their own look on every peer), zombies within `Config.FEED_RANGE` go to it (`Zombie.feed_at`, `State.FEED`, `Anim.FEED`) until someone alive comes close; `--feed` shows it
- [x] 1.13.7.2 · Spectate living teammates: next / previous, smoothed third-person follow, their HP and ammo shown
  - [x] Fire and aim cycle through the standing, `Spectator`, a camera that eases behind and above them, their name, HP and gun on screen (`Game.spectate_text`)
  - [x] Their ammo: the magazine travels in `client_state` and in the player snapshot (`PlayerWire` 24 bytes, `mag`)
- [x] 1.13.7.3 · Respawn rules per mission from map data: at the next checkpoint, after a timer, or never
  - `respawn` in the data: `true` at once, seconds, `"checkpoint"`, `false` never; the dead are `PlayerStatus.dead` (out, frozen, hidden from the others by `ACTION_DEAD`, no shooting or using) until then
- [x] 1.13.7.4 · Respawn arrival: door kicked open or drop from a truck bed, not a pop
  - A drop off a truck bed: the view falls `Config.ARRIVE_DROP` (`LocalPlayer.arrive`), others see dust kicked up (`Fx.Kind.ARRIVAL`)
- [x] 1.13.7.5 · Dead players keep text chat and pings
  - T opens the chat line (`Hud.open_chat`, `Game.say` → `host_chat` → `chat_line`), Z pings where you look (`Game.ping` → `host_ping` → `ping_at`, `Config.PING_TIME`); hooks `on_chat`, `on_ping`

### [x] 1.13.8 · Stamina and movement
> id: S018 | needs: none | size: M | tags: #gameplay | test: `tests/test_movement.gd`

- [x] 1.13.8.1 · Stamina: sprint drains, walking refills, empty forces a walk and heavy breathing #vfx #anim
- [x] 1.13.8.2 · Crouch: lower capsule and camera, quieter steps, tighter spread
- [x] 1.13.8.3 · Jump with coyote time, landing dip scaled by fall speed, fall damage above a height
- [x] 1.13.8.4 · Vault over waist-high cover when sprinting into it (hands on, legs over, 0.5 s)
- [x] 1.13.8.5 · Weight: heavy guns sprint slower
- [x] 1.13.8.6 · Remote players show crouch and jump
- [x] 1.13.8.7 · HUD stamina bar that only appears while it is not full #ui

### [x] 1.13.9 · Shove
> id: S019 | needs: S018 | size: M | tags: #gameplay | test: `tests/test_shove.gd`

- [x] 1.13.9.1 · Melee key with any gun: stock or muzzle strike, 0.35 s, costs stamina
- [x] 1.13.9.2 · Viewmodel: gun pulls back 0.08 s, thrusts with a roll, recovers with overshoot #anim #art
- [x] 1.13.9.3 · Cone hit on the host, pushes zombies back, staggers walkers, interrupts a leaper wind-up #anim
- [x] 1.13.9.4 · Low damage, never severs
- [x] 1.13.9.5 · Shove a downed crawler away from a teammate
- [x] 1.13.9.6 · Impact: thud, small blood puff, camera nudge #sound #vfx

### [x] 1.13.10 · Noise
> id: S020 | needs: S003 | size: M | tags: #gameplay #sound | test: `tests/test_noise.gd`

- [x] 1.13.10.1 · Every loud event calls `Game.make_noise(position, loudness, by)`: shots by calibre, explosions, breaking doors, sprinting, car alarms
- [x] 1.13.10.2 · Loudness per gun in `weapons.gd`, suppressed value alongside
- [x] 1.13.10.3 · Zombies within the radius turn and investigate the spot, not the player
- [x] 1.13.10.4 · Director heat: noise fills a meter, a full meter brings the next horde sooner
- [x] 1.13.10.5 · `on_noise` hook
- [x] 1.13.10.6 · `--noise` debug flag draws expanding rings where noise happened #perf

## 1.14 · Missions and game modes
? Do objectives, extraction, defence, checkpoints, scoring and difficulty work, and the three game modes?
> tags: #gameplay

### [x] 1.14.1 · Mission state and objectives
> id: S021 | needs: S002, S003 | size: L | tags: #gameplay | test: `tests/test_mission_rules.gd`

- [x] 1.14.1.1 · `scripts/mission_rules.gd` on the host: runs the map data's objective list in order
  - [x] REACH a zone (any player, or all alive players)
  - [x] HOLD a zone for seconds
  - [x] SURVIVE waves
  - [x] INTERACT with a thing (switch, radio, generator)
  - [x] EXTRACT
- [x] 1.14.1.2 · State in `welcome` and on change to every peer: objective index, text, timer, marker position #net
- [x] 1.14.1.3 · Fires the mission hooks
- [x] 1.14.1.4 · Fail conditions: everyone dead or downed, timer out
- [x] 1.14.1.5 · Corridor gets a tiny objective list as the test bed

### [x] 1.14.2 · Extraction zone
> id: S022 | needs: S021 | size: M | tags: #gameplay | test: `tests/test_extraction.gd` | see: `--host --map=corridor --bot`

- [x] 1.14.2.1 · Zone opens with `on_extraction_ready`
- [x] 1.14.2.2 · Rule: every alive player inside starts the countdown, anyone leaving pauses it, downed players must be carried in or revived
- [x] 1.14.2.3 · Zone look: green flare smoke column rising 30 m and leaning with the wind, ground ring of pulsing light strips, particles drifting up inside #vfx
- [x] 1.14.2.4 · Countdown: big numerals on the HUD, beeps that rise in pitch for the last five #ui
- [x] 1.14.2.5 · Success: fade to white, `on_extracted`, end screen #ui

### [x] 1.14.3 · Defend objective
> id: S023 | needs: S021 | size: M | tags: #gameplay | test: `tests/test_defend.gd`

- [x] 1.14.3.1 · Waves from map data: size, types, which closets, gap between waves
- [x] 1.14.3.2 · Wave grows with player count, each wave bigger and from more directions
- [x] 1.14.3.3 · Between waves: a calm with a countdown, time to barricade and restock
- [x] 1.14.3.4 · Last wave does not end, it lasts until the helicopter is down
- [x] 1.14.3.5 · HUD: wave number, zombies left, helicopter ETA #ui
- [x] 1.14.3.6 · Siren at each wave start, `on_horde_incoming` already exists

### [x] 1.14.4 · Helicopter
> id: S024 | needs: S022, S004 | size: L | tags: #gameplay | test: `tests/test_helicopter.gd` | see: `--host --map=corridor --heli --shot-at=3,6,9`

- [x] 1.14.4.1 · Model from boxes in `props.gd`: military transport, sliding side doors, skids, tail rotor, nav lights #art
- [x] 1.14.4.2 · Rotor: blades as one spinning mesh, swapped for a translucent blur disc above a speed, blades droop when stopped #art
- [x] 1.14.4.3 · Flight as a path on the host, sent as (path id, time): approach high, circle once, flare nose-up, settle
- [x] 1.14.4.4 · Body language: banks into turns, nose dips when accelerating, sways in the hover, skids compress on touchdown
- [x] 1.14.4.5 · Rotor wash: ring of dust blown outward on the ground, nearby particles and smoke pushed, players' view shakes softly underneath #vfx
- [x] 1.14.4.6 · Lights: red and green nav lights, white strobe, red anti-collision beacon sweeping the ground
- [x] 1.14.4.7 · Door gunner silhouette firing tracers at the horde during the hover #vfx
- [x] 1.14.4.8 · Boarding: players enter the door zone, camera sits them inside, lift-off, the city falls away
- [x] 1.14.4.9 · Sound hooks named for S087 #sound
  - `HeliFlight` (the path from landing point, heading and time), `Helicopter` (the look), `Game.call_heli` / `step_heli` / `heli_state`; the last wave of a defend objective calls it; `--heli`

### [x] 1.14.5 · Checkpoints
> id: S025 | needs: S021 | size: S | tags: #gameplay | test: `tests/test_checkpoints.gd`

- [x] 1.14.5.1 · Checkpoint zone from map data, reached once
- [x] 1.14.5.2 · On reach: dead players respawn there, downed are revived, ammo crate unlocks
- [x] 1.14.5.3 · Look: a safe room door or a lit military tent, a hand-painted arrow before it
- [x] 1.14.5.4 · HUD toast and a short calm from the director #ui

### [x] 1.14.6 · Scoring and end screen
> id: S026 | needs: S022 | size: M | tags: #gameplay #ui | test: `tests/test_scoring.gd`

- [x] 1.14.6.1 · Host counts per player: kills, headshots, limbs severed, damage taken, revives, shots fired and hit, distance
- [x] 1.14.6.2 · End screen: EXTRACTED in green or MISSION FAILED in red slamming in, mission time, a row per player with counters ticking up
- [x] 1.14.6.3 · Titles: most headshots, medic, survivor with least damage, last one standing
- [x] 1.14.6.4 · Best time per mission and difficulty saved to `user://records.cfg`
- [x] 1.14.6.5 · Buttons: retry (host), back to lobby
  - Until the lobby exists (S122) the second button goes back to the menu

### [x] 1.14.7 · Difficulty
> id: S027 | needs: S023 | size: S | tags: #gameplay | test: `tests/test_difficulty.gd`

- [x] 1.14.7.1 · Easy / normal / hard / nightmare as multipliers in `Config`: zombie HP, damage, speed share of runners, horde size, ammo found
- [x] 1.14.7.2 · Horde size scales with players alive
- [x] 1.14.7.3 · Nightmare: no HUD markers, friendly fire on #vfx #ui
- [x] 1.14.7.4 · Sent in `welcome` #net

### [x] 1.14.8 · Horde director 2
> id: S028 | needs: S002, S020 | size: L | tags: #gameplay | test: `tests/test_director.gd`

- [x] 1.14.8.1 · Pacing states: CALM, BUILD, PEAK, RELAX, driven by stress (damage taken, zombies near, ammo low) #art
- [x] 1.14.8.2 · Spawns only in closets no alive player can see or is close to, test proves it across 1000 seeded spawns
- [x] 1.14.8.3 · Hordes travel along routes so they arrive as a stream round a corner, not a blob
  - One zombie every `Config.HORDE_STREAM_GAP` out of one hidden closet, each told the closet's `horde_routes` points (`Zombie.route`)
- [x] 1.14.8.4 · Wanderers: a few idle zombies placed ahead of the players, from map data
  - `zombie_wanderers` in the map's data; no map lists any yet (S051 and the five places will)
- [x] 1.14.8.5 · Specials on a budget: at most N of each special type alive (`Config.SPECIAL_BUDGET`, only the leaper for now) #perf
- [x] 1.14.8.6 · Stragglers that lose the players are recycled to a closet ahead
- [x] 1.14.8.7 · `--director` debug overlay: state, stress, heat
- The city has no closets yet, so there the director still asks `CityMap.zombie_spawn_point` (a street corner out of sight); the closets come with S051

### [x] 1.14.9 · Game modes: extraction, defense, open world
> id: S264 | needs: S021 | size: L | tags: #gameplay | test: `tests/test_game_modes.gd`

- [x] 1.14.9.1 · `GameModes.apply` builds a mode's map data on every peer from where the players start #net
- [x] 1.14.9.2 · Extraction: a checkpoint halfway and a way out toward the next POI, snapped to a street
- [x] 1.14.9.3 · Defense: three waves round the start, the last until the helicopter is down
- [x] 1.14.9.4 · Open world: day / dusk / night / dawn clock, hordes by night, a horde night every few nights, respawn
- [x] 1.14.9.5 · Menu buttons and `--mode=`; the clock goes to late joiners in `welcome` #ui #net

## 1.15 · Zombie behaviour and types
? Do zombies sense, gather, climb and come in every kind the missions need?
> tags: #ai

### [x] 1.15.1 · Room on the wire
> id: S070 | needs: none | size: M | tags: #ai | test: `tests/test_zombie_wire.gd`

- [x] 1.15.1.1 · Type field widened to hold twelve types, state field to hold the new states, still 13 bytes
  - 4 bits of type, 5 of state; the id is 24 bits now
- [x] 1.15.1.2 · Flags packed into spare bits: burning, armoured parts left, climbing, crawling
  - `ZombieWire.FLAG_*` and a 4-bit `armour`; the host sets only crawling so far, the rest wait for their steps
- [x] 1.15.1.3 · Packet test at the zombie cap still passes #perf
- [x] 1.15.1.4 · Version byte in `welcome` so a mismatched build is refused with a clear message #net
  - `Config.PROTOCOL_VERSION` (bump it with any change to what is on the wire), sent in `request_join` and `welcome`; `Game.join_refused` takes the client back to the menu with the message
- [x] 1.15.1.5 · Interest management: when the count exceeds one packet, each client gets the nearest zombies every tick and the far ones every few ticks
  - `Interest.pick`; today's cap of 60 fits in one packet with eight players, so it only starts to matter above `Interest.budget`. Clients keep a zombie that missed a packet for `Config.ZOMBIE_STALE` seconds

### [ ] 1.15.2 · Senses and ambient zombies
> id: S072 | needs: S020, S071 | size: L | tags: #ai | test: `tests/test_zombie_senses.gd`

- [ ] 1.15.2.1 · States before CHASE: DORMANT (standing still, lying, slumped in a car), FEEDING (kneeling on a corpse), WANDER
- [ ] 1.15.2.2 · Sight cone and range, shorter in the dark, widened by a flashlight shining on them #vfx
- [ ] 1.15.2.3 · Hearing from the noise system #sound
- [ ] 1.15.2.4 · Alert: head snaps up, a scream that wakes others within a radius, then the chase #sound
- [ ] 1.15.2.5 · Feeding animation: kneel, tear, head jerks up with a strip, blood on the mouth #vfx #anim
- [ ] 1.15.2.6 · Trapped ones: behind glass slapping it, seat-belted in cars, under a gate reaching out #sound
- [ ] 1.15.2.7 · Banging on a closed door in rhythm, the door shakes
- [ ] 1.15.2.8 · Sneaking past is possible: crouch, no light, suppressed guns

### [ ] 1.15.3 · Crowd movement
> id: S073 | needs: S052 | size: M | tags: #ai | test: `tests/test_crowd.gd`

- [ ] 1.15.3.1 · Separation steering so a horde spreads across the street instead of stacking
- [ ] 1.15.3.2 · Lanes: fast ones overtake on the outside
- [ ] 1.15.3.3 · Funnel at doors and gaps: pressure builds, the ones in front are pushed through
- [ ] 1.15.3.4 · Shoving reactions: a staggered zombie bumps its neighbours into a stumble #anim
- [ ] 1.15.3.5 · Tripping over corpses and crawlers at a seeded chance, pinned in tests
- [ ] 1.15.3.6 · Host tick cost at the zombie cap stays in budget (S009) #perf

### [ ] 1.15.4 · Climbing and vaulting
> id: S074 | needs: S071, S255 | size: L | tags: #ai | test: `tests/test_zombie_climb.gd` | see: `--host --demo --climb`

- [ ] 1.15.4.1 · Nav links typed VAULT (waist high), CLIMB (up to a floor), DROP
- [ ] 1.15.4.2 · Vault animation: hands slap the top, belly over, tumble down the other side, get up #sound #anim
- [ ] 1.15.4.3 · Climb animation: jump, grab the edge, feet scrabble, pull up; fingers show on the ledge first #anim
- [ ] 1.15.4.4 · Drop: fall, heavy landing, a broken ankle limp at a seeded chance
- [ ] 1.15.4.5 · Windows: head and arms through, drag the body over the sill, glass tears at them
- [ ] 1.15.4.6 · Shot while climbing: falls back onto the ones below
- [ ] 1.15.4.7 · Cars are vaulted over, fences climbed, barricades clawed at first

### [ ] 1.15.5 · Zombies through stairs, doors and floors
> id: S255 | needs: S051 | size: L | tags: #ai | test: `tests/test_zombie_levels.gd` | see: `--mission=mirante --bot`, `--house-rack --zombies`

- Today zombies can't climb the lookout tower's stairs or the hospital's fire stair, and can't come into the open houses (their grid has the block solid).
- [ ] 1.15.5.1 · The area's navigation has levels: stairs, landings, decks and floors as linked cells, not only the ground grid
- [ ] 1.15.5.2 · Doorways of open houses and the POIs' interiors are links; a shut door blocks until it is broken
- [ ] 1.15.5.3 · Zombies follow players up the tower and the fire stair, into houses and from floor to floor #vfx
- [ ] 1.15.5.4 · The director's closets may be inside (a house's court, a stair)
- [ ] 1.15.5.5 · Host tick at the zombie cap stays in budget #perf

### [ ] 1.15.6 · Crawler
> id: S075 | needs: S071, S242 | size: S | tags: #ai | test: `tests/test_zombie_crawler.gd`

- [ ] 1.15.6.1 · Spawns legless: under cars, in stairwells, under beds
- [ ] 1.15.6.2 · Silent until close, grabs an ankle: the player is slowed until it is shoved or shot
- [ ] 1.15.6.3 · Hard to see: low, in the dark, flashlights help #vfx

### [ ] 1.15.7 · Bloater
> id: S076 | needs: S070, S004, S238 | size: M | tags: #ai | test: `tests/test_zombie_bloater.gd` | see: `--zombie-rack=1`

- [ ] 1.15.7.1 · Slow waddle, gurgling
- [ ] 1.15.7.2 · Death or close contact: bursts
  - [ ] Belly swells for 0.4 s first as a warning
  - [ ] Wet explosion: chunks, a ring of bile on the floor, a green mist cloud that lingers
  - [ ] Damage and a knock-back in the radius, bile on the screen of players caught
- [ ] 1.15.7.3 · Bile puddle draws other zombies to it #perf
- [ ] 1.15.7.4 · Kill it at range, or use it against a horde

### [ ] 1.15.8 · Spitter
> id: S077 | needs: S070, S004, S239 | size: M | tags: #ai | test: `tests/test_zombie_spitter.gd`

- [ ] 1.15.8.1 · Keeps distance, climbs to high ground, strafes between spits
- [ ] 1.15.8.2 · Spit: rears the head back with a throat bulge, then a glowing green arc with a drip trail #vfx
- [ ] 1.15.8.3 · Lands as an acid pool: bubbles, steam wisps, eats HP while stood in, fades in seconds #vfx
- [ ] 1.15.8.4 · Host simulates the arc; clients get start, velocity and time #net
- [ ] 1.15.8.5 · Dies easily, flees when approached

### [ ] 1.15.9 · Brute
> id: S078 | needs: S070, S071, S240 | size: L | tags: #ai | test: `tests/test_zombie_brute.gd`

- [ ] 1.15.9.1 · Armour plates on torso and arms as separate parts with their own HP; plates crack, then fly off, showing flesh
- [ ] 1.15.9.2 · Charge: lowers the shoulder, paws the ground, a straight run that throws players and zombies aside and ends in a stumble if it misses #anim
- [ ] 1.15.9.3 · Smashes doors and barricades in one hit, flips small wrecks aside
- [ ] 1.15.9.4 · Ground slam at close range with a dust ring and a camera shake #vfx
- [ ] 1.15.9.5 · Weak spot: the head and the back after a missed charge
- [ ] 1.15.9.6 · At most one or two alive (director budget) #perf

### [ ] 1.15.10 · Screamer
> id: S079 | needs: S070, S028, S241 | size: M | tags: #ai #sound | test: `tests/test_zombie_screamer.gd`

- [ ] 1.15.10.1 · On sight of a player it stands still, arches back and screams for three seconds
- [ ] 1.15.10.2 · The scream is visible: ripple rings of distorted air, nearby glass rattles, the player's view trembles
- [ ] 1.15.10.3 · Finished scream calls a horde through the director; killing it mid-scream stops it
- [ ] 1.15.10.4 · Runs away between screams

### [ ] 1.15.11 · Armoured dead
> id: S080 | needs: S070 | size: M | tags: #ai | test: `tests/test_zombie_armour.gd`

- [ ] 1.15.11.1 · Soldier: helmet stops pistol and SMG headshots until knocked off, vest halves torso damage
- [ ] 1.15.11.2 · Riot cop: visor helmet, limb pads, sometimes still holding a shield in front
- [ ] 1.15.11.3 · Firefighter: helmet and thick coat, immune to fire #vfx
- [ ] 1.15.11.4 · Helmets are parts: a hit knocks them off with a clang and they roll away
- [ ] 1.15.11.5 · Bullets on armour spark and ricochet instead of bleeding #vfx
- [ ] 1.15.11.6 · Weighted by place: soldiers at the barracks, cops at checkpoints

## 1.16 · Foundations and tools
? Are the shared systems and the tools that check them in place?
> tags: #tool

### [x] 1.16.1 · Mind map of this file
> id: S001 | needs: none | size: S | tags: #tool | test: `python tools/steps_map.py --check` | see: open `references/steps_map.html`

- [x] 1.16.1.1 · `tools/steps_map.py` parses the format above
  - [x] Fails with file and line on a broken id, duplicate id, unknown `needs`, or a `needs` cycle
  - [x] `--next` prints the steps that can be started now
  - [x] `--stats` prints done / total per phase
- [x] 1.16.1.2 · Writes `references/steps_map.html`, one self-contained file, no libraries
  - [x] Radial tree: root, phases, steps, features, sub-features
  - [x] Done nodes green, startable steps bright, blocked steps dim
  - [x] Click a step to fold or unfold it, hover shows its spec notes and `needs`
  - [x] Dependency arrows between steps as a toggle
- [x] 1.16.1.3 · Line in `CLAUDE.md` Commands

### [x] 1.16.2 · Map data format
> id: S002 | needs: none | size: L | tags: #tool | test: `tests/test_map_data.gd` | see: `--host --map=corridor`

- [x] 1.16.2.1 · `scripts/world/map_data.gd`: one dictionary per mission area
  - [x] Player spawns (one per player slot, facing)
  - [x] Zombie spawn closets (position, radius, which wave uses them)
  - [x] Horde routes (polyline from closet to the play area)
  - [x] Zones (id, polygon or box, floor range) for extraction, checkpoints, triggers
  - [x] Doors, lootboxes, ammo crates, weapon spots with fixed `iid`
  - [x] Objective list (kind, zone, seconds, wave sizes, text)
  - [x] Bounds polygon of the playable area and its blocked exits
- [x] 1.16.2.2 · `GameMap` reads it: `zones`, `spawns`, `objective_defs`
- [x] 1.16.2.3 · Corridor map ported to the format, behaviour unchanged
- [x] 1.16.2.4 · Validation: every position on walkable nav, every spawn closet out of sight of every player spawn, ids unique #anim
- [x] 1.16.2.5 · `--zones` debug flag draws zones, closets and routes as coloured wireframes #perf

### [x] 1.16.3 · Mission hooks
> id: S003 | needs: none | size: S | tags: #tool | test: `tests/test_hooks_mission.gd`

- [x] 1.16.3.1 · `on_mission_started(mission)`
- [x] 1.16.3.2 · `on_objective_reached(objective_id, by_player)`
- [x] 1.16.3.3 · `on_extraction_ready(zone)`
- [x] 1.16.3.4 · `on_extracted(player_ids)`
- [x] 1.16.3.5 · `on_mission_failed(reason)`
- [x] 1.16.3.6 · `on_checkpoint_reached(checkpoint_id)`
- [x] 1.16.3.7 · `on_player_downed`, `on_player_revived`, `on_noise(position, loudness, by_player)` declared now, fired by later steps
- [x] 1.16.3.8 · All host only, all visible to `spy(g)`

### [x] 1.16.4 · Effects kit
> id: S004 | needs: none | size: L | tags: #tool | test: `tests/test_fx_kit.gd` | see: `--host --demo --fx-rack`

- [x] 1.16.4.1 · `scripts/fx/fx.gd`: every later effect is built from these
  - [x] Pooled particle bursts (CPU particles from `MeshKit` quads and boxes), never allocated in a fight
  - [x] Pooled omni lights with a life curve, never casting shadows
  - [x] Pooled decals as one MultiMesh per kind (bullet hole, scorch, crack, puddle)
  - [x] Pooled billboards (smoke puff, flash, spark) with flipbook-free animation: scale, spin, colour, alpha over life
  - [x] Trails (ribbon mesh rebuilt per frame, capped length)
- [x] 1.16.4.2 · One budget: `Config.FX_MAX_*` per pool, oldest is reused, test proves the cap holds under a 500-burst spam #perf
- [x] 1.16.4.3 · One wire: `Game.play_fx(kind, position, direction, arg)` on the host, sent as the reliable `world_fx` RPC on its own channel, every peer plays it locally #net
- [x] 1.16.4.4 · Quality tiers LOW / MEDIUM / HIGH scale counts and lifetimes #perf
- [x] 1.16.4.5 · `--fx-rack` shows every registered effect looping in a row, labelled

### [x] 1.16.5 · Sound engine
> id: S005 | needs: none | size: L | tags: #tool #sound | test: `tests/test_sfx.gd`

- [x] 1.16.5.1 · `sfx.gd` synthesis primitives, all cached `AudioStreamWAV`
  - [x] Noise (white, pink, brown), sine, saw, square, FM pair
  - [x] Envelopes (attack, decay, sustain, release), exponential tails
  - [x] Filters (one-pole low and high pass, band pass, comb), soft clip, bit-crush
  - [x] Layers and pitch sweep, seeded so a sound is the same on every run
- [x] 1.16.5.2 · Voice pool: `Config.SFX_VOICES` 3D players plus a few 2D, steals the quietest / farthest
- [x] 1.16.5.3 · Buses made in code: Master, Guns, Zombies, World, UI, Music, each with a volume
- [x] 1.16.5.4 · Distance attenuation and a low-pass by distance on every 3D voice
- [x] 1.16.5.5 · `Sfx.play(name, position, pitch_jitter)` and `Sfx.play_ui(name)` as the only entry points
- [x] 1.16.5.6 · Existing gunshot moved onto it

### [x] 1.16.6 · Settings store
> id: S006 | needs: none | size: S | tags: #tool | test: `tests/test_settings.gd`

- [x] 1.16.6.1 · `scripts/settings.gd` autoload, saved to `user://settings.cfg`
  - [x] Mouse sensitivity, invert Y, FOV, aim-toggle or hold
  - [x] Volume per bus
  - [x] Graphics tier, fps cap, vsync, window mode, show draws
  - [x] Key bindings from `controls.gd`
  - [x] Player name
- [x] 1.16.6.2 · `changed(key)` signal, live apply
- [x] 1.16.6.3 · Unknown or broken file falls back to defaults without a crash

### [x] 1.16.7 · Balance sheet
> id: S007 | needs: none | size: S | tags: #tool | test: `tools\test.ps1 balance`

- [x] 1.16.7.1 · `tools\balance.ps1` prints a table: every gun against every zombie type
  - [x] Shots and seconds to kill for head, torso, legs
  - [x] Damage per magazine, kills per magazine, seconds per reload
  - [x] Effective range from spread
- [x] 1.16.7.2 · Test asserts ordering rules (a sniper headshot kills a walker, the pistol is never the best DPS) #anim
- [x] 1.16.7.3 · Writes `references/balance.md`

### [x] 1.16.8 · Bot playtests
> id: S008 | needs: S002 | size: M | tags: #tool | test: `tests/test_bot_scenarios.gd`

- [x] 1.16.8.1 · Bot can follow nav to a zone, open doors, shoot what blocks it, reload
- [x] 1.16.8.2 · Scenario format: map, mission, seed, time limit, expected outcome
- [x] 1.16.8.3 · Corridor scenarios: the bot crosses the map with the director running, and holds the spawn against a horde
  - Fighting through a full horde in the open kills the bot most runs: no such scenario until the bot or the balance changes
- [x] 1.16.8.4 · Scenarios run headless at accelerated time inside the suite, total under 20 s
- [x] 1.16.8.5 · A failing scenario prints where the bot died or got stuck

### [x] 1.16.9 · Performance budget
> id: S009 | needs: none | size: M | tags: #tool #perf | test: `tests/test_budget.gd`

- [x] 1.16.9.1 · Per map: mesh, surface, light, shadow caster and collision shape counts, and the surfaces in view from a fixed set of cameras (the headless stand-in for draw calls) #art
- [x] 1.16.9.2 · Budgets in `Config.BUDGET_*`, test fails when a map goes over
- [x] 1.16.9.3 · Zombie count cap per map proven: host tick time with the cap alive stays under the frame
- [x] 1.16.9.4 · Snapshot size at the cap fits one packet #net
  - Players are packed by `PlayerWire` (22 bytes each), names travel once through `Game.player_names`
  - Zombie positions are sent relative to an anchor, so they survive anywhere in the city
- [x] 1.16.9.5 · `tools\perf.ps1` windowed run prints average and worst frame over 30 s with a horde

### [x] 1.16.10 · Screenshot gallery
> id: S010 | needs: none | size: S | tags: #tool | see: `tools\shots.ps1`

- [x] 1.16.10.1 · `tools\shots.ps1` takes a fixed set of shots into `references/shots/` (ignored by git)
  - [x] Gun rack, zombie racks front and back, fx rack
  - [x] One street view and one landmark view per mission
  - [x] Viewmodel in aim, sprint, reload for the current weapon
- [x] 1.16.10.2 · `--shot-cam=x,y,z,yaw,pitch` places a free camera so shots repeat exactly, `--poi-cam` looks at a mission's place
- [x] 1.16.10.3 · Contact sheet `references/shots/index.html`

### [x] 1.16.11 · Element pipeline and review loop
> id: S140 | needs: S136 | size: L | tags: #tool | test: `tests/test_elements.gd` | see: `python tools/models/review.py hydrant`

- Props, building parts, vehicles and guns are made the way the characters are: Python geometry, baked and exported by Blender into `assets/models/props/`, never edited by hand. GDScript boxes stay only for blockouts and the test maps.
- [x] 1.16.11.1 · `python tools/models/props.py <name>` builds one element from `tools/models/props/<family>.py`; `--sketch` draws it flat-shaded without Blender in seconds, `--quick` shapes only #perf #art
- [x] 1.16.11.2 · Bake per element: albedo with ambient occlusion, a wear mask (edges, cavities, what faces the sky) painted from the card's materials, emission for anything lit, a LOD chain #perf #art
- [x] 1.16.11.3 · Named moving parts and states in the .glb (doors, lids, shutters, magazines, actions, wheels; clean, abandoned, damaged, burnt), loaded by `PropModel` with their nodes; repeated elements as MultiMesh #perf #ui #art
- [x] 1.16.11.4 · Registry `scripts/models/elements.gd`: name, model, size, triangles per LOD, draws, parts, states; `tests/test_elements.gd` checks every entry (loads, size within 5 % of the card, budgets, parts, states, LODs) #perf #art
- [x] 1.16.11.5 · `--prop-rack=<name>` (with `--state=` and `--part=open`) in a neutral, evenly lit room; `python tools/models/review.py <name> --round=N` shoots the sheet (eight angles, 1 m, 10 m, 50 m) beside the card's references into `references/elements/reviews/<name>_r<N>.jpg` #art
- [x] 1.16.11.6 · `references/elements/_template.md`, the card
- [x] 1.16.11.7 · A fire hydrant taken through three rounds as the worked example, its card and sheets kept #vfx

### [x] 1.16.12 · Detail kit
> id: S141 | needs: S140 | size: L | tags: #tool | test: `tests/test_elements.gd` | see: `python tools/models/review.py kit`

- [x] 1.16.12.1 · Shapes: chamfered and bevelled boxes, lathed profiles, sweeps along a path (pipes, rails, handrails, cables with sag), extrusions with inset and raised panels, linear and radial arrays, window and door frames, vents and slots #perf
- [x] 1.16.12.2 · Surfaces as geometry or bake: brick bonds, concrete block, stone setts, interlocking pavers, clay roof tiles in rows with ridge caps, corrugated and ribbed sheet, grilles and mesh, louvres, board-formed concrete #perf #art
- [x] 1.16.12.3 · Lettering: block and stencil fonts as geometry or painted into the bake (signs, plates, roof paint, road words), numbers #art
- [x] 1.16.12.4 · Wear: chipped paint on edges, rust running from fixings, water stains below sills and joints, soot, moss and algae on shaded faces, dirt at the foot of walls, posters and graffiti as decals #vfx #art
- [x] 1.16.12.5 · Damage: dents, broken glass with holes and cracks, bullet pocks, a burnt version of every material, cut lines for collapse
- [x] 1.16.12.6 · The kit sheet: every helper side by side on the rack

### [x] 1.16.13 · The Management Dashboard
> id: S265 | needs: S001 | size: M | tags: #tool | test: `python tools/dashboard.py --check`

- [x] 1.16.13.1 · `Management Dashboard.md`: phases, areas, items, details, tags; replaces ROADMAP.md
- [x] 1.16.13.2 · `tools/dashboard.py`: --check, --next, --stats, --tag, and the HTML dashboard (`references/dashboard.html`)
- [x] 1.16.13.3 · `--renumber` keeps the display numbers right after items move; ids never change
- [x] 1.16.13.4 · Published as an artifact: tag filter, status filter, search, progress per level #ui

---

# 2 · Game looks good

It looks, sounds and feels right at a stable frame rate: light, particles, weather, sound, gun feel, every gun and the people holding them.

## 2.1 · Light, particles, weather and post
? Do we have every visual control Godot gives us (light, particles, fog, post) to make a minimal game look stunning?
> tags: #vfx

### [x] 2.1.1 · Sky and time of day
> id: S050 | needs: S004 | size: L | asset: complex | rounds: 3 | tags: #vfx #art | test: `tests/test_sky.gd` | see: `python tools/sky_review.py N [--missions]`, `--time=clear|overcast|dusk|night|storm`

- [x] 2.1.1.1 · Sky shader in code: gradient, sun or moon disc, stars that twinkle, two drifting cloud layers lit from below by the town at night
- [x] 2.1.1.2 · Presets per mission in map data: overcast day, orange dusk with long shadows, moonlit night, storm
- [x] 2.1.1.3 · One directional light per preset, shadows only by day and dusk
- [x] 2.1.1.4 · Distance fog tinted by the preset, hides the draw distance limit
- [x] 2.1.1.5 · Far backdrop: the roofscape bristling with chimneys, the church tower and the campanile, and the dark wooded hill with the old telegraph tower and its windmill on top, visible from every mission
- [x] 2.1.1.6 · Columns of smoke on the horizon, a distant fire glow under the clouds
- [x] 2.1.1.7 · `--time=` flag, sent in `welcome` #net
- [x] 2.1.1.8 · Round 1 · day: the clear and overcast presets (sky colour, clouds, the light on the plaster) against the card's references
- [x] 2.1.1.9 · Round 2 · dusk and night: the town's glow under the clouds, the dark hill, the moon and stars
- [x] 2.1.1.10 · Round 3 · storm and backdrop: the storm preset, the roofscape and the hill seen from each mission's start
- [x] 2.1.1.11 · Review: every preset from the same three viewpoints in one sheet
- Done: `TimeOfDay` (five presets as data: clear, overcast, dusk, night, storm; `Missions.INFO[..].sky`, `MapData.sky`, the host's `--time=`, sent in `welcome`), `SkyDome` (environment, sun or moon, depth fog to `fog_max` at the far plane, lightning) and one sky shader (`SkyShader`) that also paints the backdrop past the far plane (`Config.VIEW_FAR` 1200 m): the hill and the roofscape from a horizon profile worked out from the map's heights for where the camera stands, the town from above out of `CityPicture` with its lamps at night, the fires' smoke columns, and the church, campanile, telegraph tower and mill as silhouettes until S188, S214 and S230 build them. No draw call; measured 8.2 ms with 60 zombies in the city, the same as a plain sky. Card and rounds: `references/elements/sky.md`, sheets `sky_r1..r4`, `sky_rfinal`. Left: plaster reads light (the town's vertex colours are linear; the exposure makes up for it at night), the mission starts hide the backdrop behind their placeholder buildings, no drawn lightning bolt.

### [ ] 2.1.2 · Flashlight
> id: S107 | needs: S004 | size: M | tags: #vfx | test: `tests/test_flashlight.gd` | see: `--host --time=night --flashlight --shot-at=2`

- [ ] 2.1.2.1 · Toggle key, state in the player snapshot's action bits #net
- [ ] 2.1.2.2 · Spot light with a soft-edged cone and a bright hot spot (a cookie made in code), slightly warm
- [ ] 2.1.2.3 · It lags the view a little and bobs with the walk; it swings down while sprinting and reloading #anim
- [ ] 2.1.2.4 · Shadows only for the local player's own light; teammates' lights are shadowless
- [ ] 2.1.2.5 · Beam visible in fog, dust and smoke as a faint cone
- [ ] 2.1.2.6 · Battery: dims and flickers when low, recharges off; a tap on the light when it flickers
- [ ] 2.1.2.7 · Eye shine: zombies' eyes reflect in the beam before the body is seen
- [ ] 2.1.2.8 · Shining it on dormant zombies wakes them (S072)

### [ ] 2.1.3 · Lamps
> id: S108 | needs: S004 | size: L | tags: #vfx | test: `tests/test_lamps.gd` | see: `--mission=hospital --floor=3 --shot-at=1,2,3`

- [ ] 2.1.3.1 · Lamp manager: of all shadow-capable lamps, only the two most important to the local player cast shadows, switching with a fade so it never pops
- [ ] 2.1.3.2 · Lamp kinds with behaviours
  - [ ] Steady
  - [ ] Flicker: a seeded pattern of stutters and blackouts, the tube's emission and its light in step, a buzz
  - [ ] Dying: long dim, a bright spasm, dead
  - [ ] Swinging: hung by a wire, pushed by explosions and passing brutes, shadows sweep the room
  - [ ] Emergency beacon: red light rotating, sweeping walls
  - [ ] Strobe: fire alarm white flashes
  - [ ] Sodium street lamp: orange pool with a hazy cone in fog, moths round it
  - [ ] Neon and shop signs: letters that buzz and drop out one by one
  - [ ] TV glow: blue flicker from a window
- [ ] 2.1.3.3 · Lamps can be shot out: glass burst, sparks, dark
- [ ] 2.1.3.4 · Power events: a whole building or street going dark or coming on in a rolling sequence
- [ ] 2.1.3.5 · Same pattern on every peer (seeded by lamp id and match time) #net

### [ ] 2.1.4 · Fog, dust and light shafts
> id: S109 | needs: S050, S108 | size: M | tags: #vfx | test: `tests/test_atmosphere.gd` | see: `--mission=terminal --time=night --shot-at=2`

- [ ] 2.1.4.1 · Ground fog by place: thick on the river and in the forest, thin in the streets, none inside
- [ ] 2.1.4.2 · Volumetric fog on HIGH tier with lamps and the flashlight scattering in it; a cheap layered-card version below #perf
- [ ] 2.1.4.3 · Interiors: dust motes drifting in lit volumes, stirred by movement and gunfire
- [ ] 2.1.4.4 · Light shafts through windows, skylights and holes in roofs, with dust in them
- [ ] 2.1.4.5 · Smoke from fires and grenades hangs, drifts with the wind and is lit by nearby lights
- [ ] 2.1.4.6 · Breath vapour from players on the summit at night

### [ ] 2.1.5 · Rain and wet streets
> id: S110 | needs: S050, S041 | size: L | tags: #vfx | test: `tests/test_rain.gd` | see: `--weather=rain --time=night --shot-at=2`

- [ ] 2.1.5.1 · Weather per mission in map data, sent in `welcome`: clear, drizzle, rain, storm #net
- [ ] 2.1.5.2 · Rain: streaks in a volume that follows the camera, slanted by wind, never indoors or under canopies (roof test)
- [ ] 2.1.5.3 · Splashes: small rings and crowns on the ground near the camera, denser on roads #sound
- [ ] 2.1.5.4 · Wet look as in `terminal1.png`: darker, glossier asphalt and setts, lamps and headlights stretched as reflections, puddles in the road's low spots that ripple
- [ ] 2.1.5.5 · Water running in the gutters, dripping from canopy edges and awnings, pouring from broken downpipes
- [ ] 2.1.5.6 · Storm: lightning that lights the whole scene white-blue for two frames with hard shadows, thunder after a delay by distance #sound
- [ ] 2.1.5.7 · Rain on the gun and on the lens: drops that streak when the player moves
- [ ] 2.1.5.8 · Gameplay: rain shortens zombie hearing and sight, footsteps splash #sound

### [ ] 2.1.6 · Snow and cold
> id: S266 | needs: S110 | size: M | tags: #vfx | test: `tests/test_weather.gd` | see: `tools\shots.ps1 snow`

- [ ] 2.1.6.1 · Weather `snow` in map data beside rain (S110): flakes in a camera volume that drift and swirl in the wind, never indoors
- [ ] 2.1.6.2 · Settled snow: a shader layer on up-facing surfaces that grows over minutes, thinner under trees and canopies #art
- [ ] 2.1.6.3 · Footprints and drag marks in it (decals, capped), zombies leave tracks to follow #gameplay
- [ ] 2.1.6.4 · Breath vapour on everyone, frost on glass and the lens edge
- [ ] 2.1.6.5 · Snow muffles sound: hearing ranges and the mix shift (S086) #sound #gameplay
- [ ] 2.1.6.6 · Cheap on LOW: fewer flakes, no settling #perf

### [ ] 2.1.7 · Smoke columns, embers and ash over the town
> id: S267 | needs: S094, S050 | size: S | tags: #vfx | see: `tools\shots.ps1 sky`

- [ ] 2.1.7.1 · Distant smoke columns from burning blocks on the skyline, leaning with the wind (cards, lit by the sky)
- [ ] 2.1.7.2 · Embers and ash falling near fires, glowing then grey
- [ ] 2.1.7.3 · An orange glow under the clouds over the worst of the town at night
- [ ] 2.1.7.4 · Placed per area by devastation level (S263) #map

### [ ] 2.1.8 · Wind and loose things
> id: S268 | needs: S004, S047 | size: S | tags: #vfx

- [ ] 2.1.8.1 · One wind (direction, gusts) shared by trees, flags, smoke, rain and snow, from map data
- [ ] 2.1.8.2 · Paper, leaves and plastic bags skittering along the ground in gusts (pooled particles)
- [ ] 2.1.8.3 · Hanging things sway: shop signs, cables, laundry, torn awnings #art
- [ ] 2.1.8.4 · Gust sounds through streets and broken windows (S085) #sound

### [ ] 2.1.9 · Look development room
> id: S269 | needs: S111 | size: M | tags: #vfx #tool

- [ ] 2.1.9.1 · `--lookdev`: one room with every surface class, a grey ball, a chrome ball, a colour chart, under each time of day
- [ ] 2.1.9.2 · The shared world shader's wear, dirt, wetness, snow and soot controls on sliders
- [ ] 2.1.9.3 · A list of the Godot rendering features in use and their cost per tier (glow, fog, SSAO, SSR, decals, GPU particles) #perf

### [ ] 2.1.10 · Post-processing and grade
> id: S111 | needs: S050 | size: M | tags: #vfx | test: `tests/test_post.gd` | see: `tools\shots.ps1`

- [ ] 2.1.10.1 · Tonemap and exposure per time of day; eyes adapt when leaving a dark building into daylight
- [ ] 2.1.10.2 · Glow on emissive things: muzzle flashes, lamps, fire, signs
- [ ] 2.1.10.3 · Colour grade per mission: cold blue-green hospital, sodium orange streets, grey-green forest, bleached dusk at the barracks
- [ ] 2.1.10.4 · Film grain and a soft vignette, both with settings
- [ ] 2.1.10.5 · Ambient occlusion and screen-space reflections on HIGH only #ui
- [ ] 2.1.10.6 · Sharpening after upscale on LOW
- [ ] 2.1.10.7 · Depth of field only in menus, the death camera and the end screen #ui

### [ ] 2.1.11 · Gore 2
> id: S112 | needs: S032, S081 | size: L | tags: #vfx | test: `tests/test_gore.gd` | see: `--host --demo --bot --bot-aim=head --shot-at=2,3,4`

- [ ] 2.1.11.1 · Exit wounds: a bigger burst and a spray on the wall behind in the bullet's direction
- [ ] 2.1.11.2 · Head: jaw, top or half can go separately; a headshot leaves a stump with a spurting pulse that weakens
- [ ] 2.1.11.3 · Blood in the world
  - [ ] Wall splatter with drips that run down over seconds
  - [ ] Pools that grow under corpses and follow the floor's slope
  - [ ] Footprints: players and zombies who step in blood leave fading prints
  - [ ] Drag smears behind crawlers
  - [ ] Mist that hangs for a moment after a shotgun hit
- [ ] 2.1.11.4 · Viewmodel: blood spatters on the gun and hands at close range, wiped during the inspect animation #anim #art
- [ ] 2.1.11.5 · Everything capped and pooled as now, tiered #perf

### [ ] 2.1.12 · Glass and breakables
> id: S113 | needs: S032 | size: M | tags: #vfx | test: `tests/test_breakables.gd`

- [ ] 2.1.12.1 · Windows on POI buildings: first shot cracks (star decal), later shots or a body break the pane into falling shards
- [ ] 2.1.12.2 · Shards on the floor crunch and make noise #sound
- [ ] 2.1.12.3 · Car windows and windscreens, bus windows, shop glass, bottles, monitors, tube lights
- [ ] 2.1.12.4 · Wooden crates and pallets, cardboard boxes, plaster board that shows studs
- [ ] 2.1.12.5 · State as a bit per breakable in `welcome`, a `world_fx` event when it breaks #net

### [ ] 2.1.13 · Explosive props and car alarms
> id: S114 | needs: S093, S094 | size: M | tags: #vfx | test: `tests/test_hazards.gd`

- [ ] 2.1.13.1 · Red fuel barrel, blue gas cylinder (botijão): hiss and a flame jet when shot, then explode, the cylinder rockets off
- [ ] 2.1.13.2 · Petrol trail from a shot fuel tank that can be lit
- [ ] 2.1.13.3 · Car alarm: shooting or bumping some cars sets off lights and a siren, a loud noise source until it is shot or dies #sound
- [ ] 2.1.13.4 · Electrical box: sparks, shocks zombies in a puddle (uses S110 when raining)
- [ ] 2.1.13.5 · Fire extinguisher: white cloud that puts out fire and blinds for a moment

### [ ] 2.1.14 · Ambient life
> id: S115 | needs: S249 | size: M | tags: #vfx | test: `tests/test_ambient_life.gd`

- [ ] 2.1.14.1 · Crows on wires and corpses that take off when a player comes near or a shot is fired
- [ ] 2.1.14.2 · Crows circling over the barracks, bats round the lamps on the hill road
- [ ] 2.1.14.3 · Rats running along walls into holes, cockroaches scattering from light indoors
- [ ] 2.1.14.4 · Flies as a small buzzing cloud over old corpses
- [ ] 2.1.14.5 · Moths round lamps, fireflies in the forest
- [ ] 2.1.14.6 · Paper, plastic bags and leaves blown down the street in gusts
- [ ] 2.1.14.7 · Hanging things that swing: signs, cables, a traffic light, curtains through broken windows #anim
- [ ] 2.1.14.8 · All local and cosmetic, none on the wire

### [ ] 2.1.15 · Screen effects
> id: S116 | needs: S037 | size: M | tags: #vfx #ui | test: `tests/test_screen_fx.gd`

- [ ] 2.1.15.1 · One layer that mixes them and caps the total #perf
  - [ ] Blood drops and smears
  - [ ] Bile from a bloater: green, blurs, slides down
  - [ ] Acid: edges sizzle
  - [ ] Rain and splash drops
  - [ ] Dirt and dust after an explosion
  - [ ] Flash blindness with an after-image
  - [ ] Concussion: double vision that swims back together
  - [ ] Heat shimmer near fire
  - [ ] Cracked glass corner when HP is very low
- [ ] 2.1.15.2 · Each has a setting to tone it down

### [ ] 2.1.16 · Searchlights
> id: S117 | needs: S024, S109 | size: S | tags: #vfx | test: `tests/test_searchlight.gd`

- [ ] 2.1.16.1 · Helicopter searchlight: a hard white cone through fog and rain, a moving pool on the ground that hunts for the players, then locks on the landing zone
- [ ] 2.1.16.2 · Zombies in the pool are lit sharply with long shadows (one of the two shadow slots while it is on)
- [ ] 2.1.16.3 · The barracks tower's searchlight on a slow sweep
- [ ] 2.1.16.4 · Lens flare when looking into it

## 2.2 · Sound
? Do we have the sound to make it immersive: voices, steps, ambience, space, music, the mix?
> tags: #sound

### [ ] 2.2.1 · Zombie voices
> id: S082 | needs: S005 | size: L | tags: #sound | test: `tests/test_zombie_sounds.gd`

- [ ] 2.2.1.1 · Synthesised from formant-filtered saw and noise, a voice seeded per zombie id (pitch, rasp, size)
  - [ ] Walker: low groans, wet breathing
  - [ ] Runner: rising screech when it spots someone, panting
  - [ ] Leaper: clicking snarl, a shriek in the air
  - [ ] Specials: bloater gurgle, spitter retch, brute roar, screamer's scream
- [ ] 2.2.1.2 · States have sounds: alert, attack grunt, hit yelp, death rattle per type
- [ ] 2.2.1.3 · Horde bed: beyond a count, single voices are replaced by one crowd roar that swells with their number and nearness
- [ ] 2.2.1.4 · Voice cap respected, nearest first #perf

### [ ] 2.2.2 · Bodies and footsteps
> id: S083 | needs: S005, S032 | size: M | tags: #sound | test: `tests/test_footsteps.gd`

- [ ] 2.2.2.1 · Footsteps by surface for players: concrete, asphalt, setts, pavers, grass, dirt, metal stair, tile, wood, water, glass shards
- [ ] 2.2.2.2 · Walk, sprint, crouch, land, each timed with the camera bob and the remote rig's feet #anim
- [ ] 2.2.2.3 · Gear rattle while sprinting, cloth while turning
- [ ] 2.2.2.4 · Breathing: heavy after sprint, ragged when hurt, held while aiming a sniper
- [ ] 2.2.2.5 · Low-HP heartbeat that speeds up
- [ ] 2.2.2.6 · Zombie feet: shuffle, runner slaps, horde rumble
- [ ] 2.2.2.7 · Gore sounds: limb tear, bone crack, squelch, splash of a blood burst, a head burst pop #vfx

### [x] 2.2.3 · World sounds
> id: S084 | needs: S005 | size: M | tags: #sound | test: `tests/test_world_sounds.gd`

- `scripts/world_sounds.gd` (`WorldSounds`) makes them all; the host plays one on every peer with `Game.play_sound`; loops are `SoundSpot`s, the nearest `Config.SOUND_SPOTS_AUDIBLE` heard. `tools\sounds.ps1` writes them as WAVs and draws their spectrogram sheet.
- [x] 2.2.3.1 · Doors: handle, creak open, slam, locked rattle, splinter and break
  - Opening, closing, a zombie's blow and the break are played (`hooks.gd`). Doors have no locks yet: the rattle is a locked ammo crate's for now.
- [x] 2.2.3.2 · Barricade: hammer knocks, plank crack, plank snap
  - Made and registered; nothing barricades yet, so nothing plays them (the step that makes planks do something calls them).
- [x] 2.2.3.3 · Lootbox: latch, lid creak, rummage; pickups: ammo clink, medkit zip, key jingle #loot
- [x] 2.2.3.4 · Glass: crack, shatter, shards falling, crunch underfoot
  - A bullet into glass cracks (`Fx._impact`). Shatter and shards wait for breakable glass (S113), the crunch for footsteps by surface (S083).
- [x] 2.2.3.5 · Vehicles: car alarm, hazard tick, a horn stuck on, engine ticking as it cools
  - Placed by the set pieces (`Scenery.sound`): the alarm and the horn come and go on their own cycles.
- [x] 2.2.3.6 · UI: hover tick, click, back, error, objective chime, wave horn
- [x] 2.2.3.7 · Generators, buzzing tube lights, a swinging sign creaking #anim
  - Generators at the camps and the checkpoint, tubes at the corridor's lamps and the booth. No swinging sign exists yet: the creak waits for the shop signs (S160).

### [ ] 2.2.4 · Ambience
> id: S085 | needs: S005 | size: M | tags: #sound | test: `tests/test_ambience.gd`

- [ ] 2.2.4.1 · Bed per place, crossfaded by zones in map data
  - [ ] Streets: wind between buildings, far sirens, a dog, distant gunfire and screams at random times
  - [ ] Terminal: wide hall reverb, dripping, a loose metal sheet
  - [ ] Hospital: hum, alarm beeps down a corridor, a monitor flatline
  - [ ] Forest: insects, frogs, night birds, leaves, twigs snapping somewhere
  - [ ] Riverside: water, palms rattling
  - [ ] Summit: strong wind, mast cables singing
- [ ] 2.2.4.2 · One-shots placed in the world, not in the player's head
- [ ] 2.2.4.3 · Quiet that means something: the bed thins out before a horde

### [ ] 2.2.5 · Space and occlusion
> id: S086 | needs: S085 | size: M | tags: #sound | test: `tests/test_audio_space.gd`

- [ ] 2.2.5.1 · Reverb zones from map data: small room, corridor, hall, street canyon, open
- [ ] 2.2.5.2 · Occlusion: a wall between source and listener low-passes and quietens (one ray per voice, spread across frames)
- [ ] 2.2.5.3 · Sounds through doors change when the door opens
- [ ] 2.2.5.4 · Teammates' shots, steps and reloads are positional
- [ ] 2.2.5.5 · Vertical cues in buildings: floor above is muffled thumps

### [ ] 2.2.6 · Mission audio
> id: S087 | needs: S005, S024 | size: M | tags: #sound | test: `tests/test_mission_sounds.gd`

- [ ] 2.2.6.1 · Horde warning: an air-raid siren winding up across the city, then the roar
- [ ] 2.2.6.2 · Helicopter: rotor thump with distance (far: low pulse, near: full chop and turbine whine), doppler on the pass, wash noise underneath
- [ ] 2.2.6.3 · Radio voice as filtered noise bursts and beeps with subtitles on the HUD #ui
- [ ] 2.2.6.4 · Extraction countdown beeps, success swell, failure drone
- [ ] 2.2.6.5 · Checkpoint and objective stingers

### [ ] 2.2.7 · Procedural music
> id: S088 | needs: S005, S028 | size: L | tags: #sound | test: `tests/test_music.gd`

- [ ] 2.2.7.1 · A small sequencer in code: drone, pulse, percussion, a detuned piano-like pluck, all synthesised
- [ ] 2.2.7.2 · Layers follow the director: CALM drone only, BUILD adds a pulse, PEAK adds drums and a rising tone, RELAX thins out
- [ ] 2.2.7.3 · Per-mission key and tempo
- [ ] 2.2.7.4 · Stingers: special zombie spotted, teammate down, last player standing
- [ ] 2.2.7.5 · Menu theme #ui
- [ ] 2.2.7.6 · Music volume setting, ducked under gunfire #vfx

### [ ] 2.2.8 · The mix
> id: S089 | needs: S033, S082, S085 | size: M | tags: #sound | test: `tests/test_mix.gd`

- [ ] 2.2.8.1 · Ducking: guns duck ambience and music, explosions duck everything briefly
- [ ] 2.2.8.2 · Explosion near the player: tinnitus tone and a low-pass that recover over seconds
- [ ] 2.2.8.3 · Low HP and downed: muffled world, loud heart and breath
- [ ] 2.2.8.4 · Limiter on Master, no clipping with a full horde and four guns
- [ ] 2.2.8.5 · Loudness per category balanced by ear with a checklist in the step's commit

## 2.3 · Stable frame rate
? Is the game a stable 144 fps on a laptop in every area, at the worst moment?
> tags: #perf

### [ ] 2.3.1 · Graphics tiers
> id: S118 | needs: S111, S009 | size: M | tags: #perf | test: `tests/test_tiers.gd`

- [ ] 2.3.1.1 · LOW / MEDIUM / HIGH decide: fx counts, decal life, fog kind, reflections, shadow size, vegetation density, draw distance, post effects #vfx
- [ ] 2.3.1.2 · One place (`Config.TIER_*`) holds every tier number
- [ ] 2.3.1.3 · Auto-pick on first run from a five-second benchmark
- [ ] 2.3.1.4 · The budget test runs per tier
- [ ] 2.3.1.5 · LOW holds 144 fps on the target laptop with a full horde, checked with `tools\perf.ps1`

### [ ] 2.3.2 · Area performance pass
> id: S258 | needs: S051, S247, S249 | size: M | tags: #perf | test: `tests/test_budget.gd` | see: `tools\perf.ps1 <area>`

- [ ] 2.3.2.1 · `Config.BUDGET` per area (meshes, surfaces, lights, shapes, triangles) with the library placed
- [ ] 2.3.2.2 · `tools\perf.ps1` on every area with 60 zombies: average and worst frame written to `references/perf.md`
- [ ] 2.3.2.3 · Visibility ranges, LODs and MultiMesh use fixed where an area is over

### [ ] 2.3.3 · Zombie level of detail
> id: S270 | needs: S071 | size: M | tags: #perf | test: `tests/test_budget.gd`

- [ ] 2.3.3.1 · Past `Config.ZOMBIE_DETAIL_RANGE`: no secondary motion, fewer bone updates, a lower animation rate #anim
- [ ] 2.3.3.2 · Far zombies as impostors or merged low meshes, the rig only near #art
- [ ] 2.3.3.3 · Ragdolls and corpses capped by distance; the far ones settle at once #vfx
- [ ] 2.3.3.4 · The budget test counts bone updates per frame with a full horde #tool

### [ ] 2.3.4 · Culling in the areas
> id: S271 | needs: S249, S051 | size: M | tags: #perf | test: `tests/test_budget.gd`

- [ ] 2.3.4.1 · Occluders from the buildings' massing so streets behind a block are not drawn
- [ ] 2.3.4.2 · Visibility ranges on every placed element by size, set from its card
- [ ] 2.3.4.3 · Interiors drawn only when a player is in or at a window (rooms as portals) #map

### [ ] 2.3.5 · Frame-time regression check
> id: S272 | needs: S258 | size: S | tags: #perf #tool

- [ ] 2.3.5.1 · `tools\perf.ps1` runs every area at its worst moment and compares with `references/perf.md`
- [ ] 2.3.5.2 · A step that makes the worst frame 10 % slower says so in its commit

### [ ] 2.3.6 · Performance pass
> id: S133 | needs: S118, S126, S258 | size: L | tags: #perf | test: `tests/test_budget.gd`

- [ ] 2.3.6.1 · Every mission inside its budget on every tier, measured at the worst moment (final wave, rain, fire, helicopter) #vfx
- [ ] 2.3.6.2 · Profiler findings fixed: merged meshes, MultiMesh where repeated, scripts off the hot path, pooled everything
- [ ] 2.3.6.3 · Host with eight players and a full horde keeps its tick rate
- [ ] 2.3.6.4 · No hitch above a frame when a horde spawns, a building appears or an effect first plays (warm-up at load)
- [ ] 2.3.6.5 · Memory steady over a 30-minute soak

## 2.4 · Gun feel
? Do shots look, sound and kick right, and do the hands and other players move right?
> tags: #weapon

### [x] 2.4.1 · Muzzle flash and smoke
> id: S029 | needs: S004 | size: M | tags: #weapon #vfx | test: `tests/test_muzzle_fx.gd` | see: `--host --demo --weapon=4 --bot --shot-at=1,1.05,1.1`

- [x] 2.4.1.1 · Flash mesh at the muzzle for one or two frames: star of 3 to 5 crossed quads, random roll, random scale #art
  - [x] Shape per gun class: small round for pistols, long forked for rifles, wide ball for shotguns, side jets for braked snipers
  - [x] Suppressed guns: no flash, a thin grey puff
- [x] 2.4.1.2 · Light: one pooled omni, warm orange, 0.05 s, no shadows, only on the shooter's gun #perf
- [x] 2.4.1.3 · It lights the viewmodel hands and the nearest walls #anim #art
- [x] 2.4.1.4 · Smoke: two or three soft puffs drifting up and with the wind, 0.8 s
- [x] 2.4.1.5 · Sustained fire: barrel heat shimmer and a steady wisp from the muzzle for 2 s after a long burst
- [x] 2.4.1.6 · Remote players flash too, cheaper tier #perf
  - `MuzzleFlash` (shapes by `Weapons.flash_shape`), `Viewmodel.smoke` → `Game.muzzle_smoke`, `heat` / `wisp_left` / `shimmer`; the host tells the others who fired (`Game.shot_seen`, which S030 can draw tracers from)

### [x] 2.4.2 · Tracers and bullet whiz
> id: S030 | needs: S004 | size: M | tags: #weapon #vfx | test: `tests/test_tracers.gd` | see: `tools\play2.ps1`

- [x] 2.4.2.1 · Tracer: thin emissive streak from muzzle to hit, 40 m long segment moving at bullet speed, fades at the end
- [x] 2.4.2.2 · Every shot for others' guns, every third for your own (clean view)
- [x] 2.4.2.3 · Colour by calibre: yellow-white rifles, faint for pistols, a fan of short ones for shotguns
- [x] 2.4.2.4 · Sniper shot: a vapour trail line that lingers 0.6 s and wobbles apart
- [x] 2.4.2.5 · Near miss from a teammate's line: whiz sound and a tiny view flinch #sound
- [x] 2.4.2.6 · Capped, pooled #perf
  - `Tracers` (`game.tracers`, one MultiMesh), fed by `Game._fire` (yours) and `shot_seen` (theirs, with where the bullet stopped: `_bullet_end`); `_near_miss` whizzes; a sniper's vapour line shows on every shot

### [x] 2.4.3 · Shell casings
> id: S031 | needs: S004 | size: M | tags: #weapon | test: `tests/test_casings.gd` | see: `--host --demo --weapon=4 --bot --shot-at=2`

- [x] 2.4.3.1 · Casing mesh per class: brass pistol, brass rifle, red shotgun hull, long sniper case #art
- [x] 2.4.3.2 · Ejects from the port with the gun's own direction, speed and spin, timed with the action (bolt guns eject on the bolt pull, pumps on the pump)
- [x] 2.4.3.3 · Cheap physics: one bounce off the floor with a tumble, a second small one, then rest
- [x] 2.4.3.4 · Tink on each bounce by surface
- [x] 2.4.3.5 · Rests for a while, then sinks, capped by MultiMesh #perf
- [x] 2.4.3.6 · A wisp of smoke from the ejection port #vfx
  - `Casings` (`game.casings`), `Weapons.GUN_EJECT` / `casing_kind`, `Viewmodel.eject`; the tink's pitch is by kind of case until S032 gives floors their surface

### [x] 2.4.4 · Surfaces and impacts
> id: S032 | needs: S004 | size: L | tags: #weapon | test: `tests/test_impacts.gd` | see: `--host --fx-rack`

- [x] 2.4.4.1 · Surface kinds on collision bodies via metadata: concrete, asphalt, brick, metal, wood, glass, dirt, grass, water, flesh, tile
- [x] 2.4.4.2 · Impact per surface
  - [x] Concrete: grey dust cone, chips flying, round pocked hole
  - [x] Brick: red dust, larger chips
  - [x] Metal: sparks with gravity that bounce once, bright flash, dented hole with a shine ring, ricochet chance with a tracer
  - [x] Wood: splinters, pale torn hole
  - [x] Glass: star crack decal, a spray of shards
  - [x] Dirt and grass: clod spray, dark puff, blades of grass
  - [x] Water: vertical splash column, ring ripples
  - [x] Tile: white shards, cracked decal
- [x] 2.4.4.3 · Hole decals in the MultiMesh pool, aligned to the normal #perf #vfx
- [x] 2.4.4.4 · Shotgun: one combined puff for the pattern plus individual holes
- [x] 2.4.4.5 · Penetration data per surface stored now, used by S101
  - `Surface` (`scripts/world/surface.gd`: `tag`, `of_hit`, `PENETRATION`), `Fx.Kind.IMPACT` with the surface as `arg` (`IMPACT_HOLE_ONLY`, `IMPACT_PUFF_ONLY` for a shotgun's pattern); the corridor, doors, crates and lootboxes are tagged, the city is still all concrete until its streets and blocks are built (S041, S043); `--fx-rack` has a row of impacts

### [x] 2.4.5 · Gun voices
> id: S033 | needs: S005 | size: L | tags: #weapon #sound | test: `tests/test_gun_sounds.gd`

- [x] 2.4.5.1 · One synthesised shot per gun from layers: crack (noise burst), body (low thump by calibre), mechanical click, tail
  - [x] P19 short pop, P90 buzzy snap, Type 95 and AK47 heavy bark, AS Val soft thud
  - [x] USAS-12 and SPAS-12 boom with a long tail, T-5000 crack with a rolling echo, Dragunov sharp slap
- [x] 2.4.5.2 · Tail by place: short and boxy indoors, long slapback between buildings, open on the hill
- [x] 2.4.5.3 · Distance versions: far shots lose the crack and keep a dull thump
- [x] 2.4.5.4 · Suppressed variants
- [x] 2.4.5.5 · Dry fire click #vfx
- [x] 2.4.5.6 · Small pitch and level variation per shot, seeded per shot index
  - `GunVoice` (`scripts/gun_voice.gd`: `RECIPES`, `sound(id)` + `_far` / `_sup`, `tail(place)`, `variation(i)`), `Game.place_at`; checked by measurement in the tests (length, loudness, brightness), not yet by ear

### [x] 2.4.6 · Handling animation and sound
> id: S034 | needs: S033 | size: L | tags: #weapon #sound #anim | test: `tests/test_viewmodel.gd` | see: `--weapon=1..9 --pose=reload`

- [x] 2.4.6.1 · Reload has parts with their own sound and pose: mag release, mag out, new mag in, slap, bolt or charging handle
  - [x] Empty reload differs from a tactical reload
  - [x] The old magazine falls and stays on the floor a while
  - [x] Shotgun: shell in per round, pump at the end
  - [x] Bolt rifle: bolt up, back, forward, down, with the scope leaving the eye
- [x] 2.4.6.2 · Inspect animation on a key: roll the gun left and right, check the chamber
- [x] 2.4.6.3 · Idle life: slow breathing, micro-adjustments of the grip
- [x] 2.4.6.4 · Draw and holster with cloth and sling sounds
- [x] 2.4.6.5 · Low ammo: the last rounds of a magazine sound thinner and click
  - `Viewmodel.handling` (each part once, `reload_events`, `cycle_events`) → `Sfx` "h_" sounds; `mag_dropped` → `Casings` (`Weapons.Casing.MAG`); `WeaponState.reload_empty`; `scope_break`; `inspect()` (F, `--pose=inspect`); idle breathing and grip shifts; `low_ammo_click` under `Config.LOW_AMMO_ROUNDS`

### [x] 2.4.7 · Camera feel
> id: S035 | needs: S018 | size: M | tags: #weapon | test: `tests/test_camera_feel.gd`

- [x] 2.4.7.1 · Walk and sprint bob as a figure eight, synced with footsteps #sound #anim
- [x] 2.4.7.2 · Weapon sway lags the mouse, spring back, more with heavy guns
- [x] 2.4.7.3 · Strafe tilt of a degree or two
- [x] 2.4.7.4 · Recoil as a spring: kick up, recover most of the way, horizontal wander by gun
- [x] 2.4.7.5 · FOV opens a little while sprinting, pinches on a sniper shot
- [x] 2.4.7.6 · Shake sources mixed and capped: explosions, hits taken, leaper landing, helicopter #perf
- [x] 2.4.7.7 · All of it scaled by a setting, off at zero
  - `CameraFeel` (`local_player.feel`: `step`, `add_shake`, `pinch`, `rumble`), the recoil spring (`punch_vel`, `step_recoil`), `Game.shake_near` / `got_hit` / `_fx_shake`, the "camera_motion" setting; recoil itself is gameplay and is not scaled by it

### [x] 2.4.8 · HUD 2
> id: S036 | needs: S011, S021 | size: L | tags: #weapon #ui | test: `tests/test_hud.gd` | see: `--host --shot-at=2`

- [x] 2.4.8.1 · Bottom right: weapon name, magazine as individual pips or a number, reserve, fire mode #vfx
- [x] 2.4.8.2 · Bottom left: health bar with a bleed marker, stamina, item counts
- [x] 2.4.8.3 · Top: compass strip with bearings, objective and teammate ticks #sound
- [x] 2.4.8.4 · Objective text with a typed-in reveal, strike-through and slide-out when done
- [x] 2.4.8.5 · World markers: objective diamond with distance, clamped to the screen edge with an arrow
- [x] 2.4.8.6 · Teammates: name over the head, outline through walls when far, downed icon with a timer
- [x] 2.4.8.7 · Interaction prompt with the bound key and a hold ring
- [x] 2.4.8.8 · Everything fades when not needed, HUD scale setting
- [x] 2.4.8.9 · Built in code, no draw-call growth
  - Parts: `AmmoPanel`, `VitalsBar`, `Compass`, `ObjectiveText`, `WorldMarkers` (`HudParts` draws for them), all under `Hud.root` (`apply_scale`, the `hud_scale` setting); `Hud.set_gun`, `set_vitals`, `set_compass`, `set_prompt(text, action)`, `step_fades`; `RemotePlayer.step_tag` counts a downed teammate's time; `Controls.label_of`. A downed teammate's clock is counted on each peer from when they went down (the host's own is not sent)

### [x] 2.4.9 · Hit feedback
> id: S037 | needs: S036 | size: M | tags: #weapon | test: `tests/test_hit_feedback.gd`

- [x] 2.4.9.1 · Hit marker: four ticks that snap in and ease out, red and larger for a kill, a skull tick for a headshot
- [x] 2.4.9.2 · Limb sever: a brief extra tick and a wet sound #sound
- [x] 2.4.9.3 · Damage direction: red arc on the side the hit came from, fades over a second
- [x] 2.4.9.4 · Taking a hit: view punch away from the attacker, red edge flash, short muffling of sound #sound #vfx
- [x] 2.4.9.5 · Low HP: pulsing dark red vignette, desaturation, heartbeat, blurred edges
- [x] 2.4.9.6 · Blood on the lens after a close kill: a few drops that run down and fade #vfx
  - `HitMarker`, `DamageArcs`, `LensBlood`, the `low_hp` shader on the HUD; `Game.hit_confirm(killed, headshot, severed, dist)` and `got_hit(amount, from)` (protocol 4); `Sfx.muffle` / `step_muffle` (a low-pass on Master); the `sever_wet` sound

### [x] 2.4.10 · Other players' animations
> id: S038 | needs: S016, S019 | size: L | tags: #weapon #anim | test: `tests/test_remote_anim.gd` | see: `tools\play2.ps1`

- [x] 2.4.10.1 · Player snapshot carries an action byte: aim, reload, shove, heal, throw, downed, vault, crouch #net
- [x] 2.4.10.2 · Rig states in `Humanoid.Anim`
  - [x] Aim: shouldered gun, head tracks the look pitch
  - [x] Reload: support hand to the pouch and back, gun tilted
  - [x] Sprint with the gun carried low
  - [x] Shove, throw (wind-up, release), heal
  - [x] Hit flinch, death fall forward or backward by hit direction
- [x] 2.4.10.3 · Upper and lower body blend: legs run while the arms reload
- [x] 2.4.10.4 · Gun recoil kick on the remote rig per shot
  - `PlayerWire` 26 bytes (u16 action: AIM, RELOAD, SHOVE, THROW, VAULT added; s8 look pitch), protocol 5; `Humanoid.Upper` layered by `_write_upper` over the legs, `look_pitch`, `kick`; `RemotePlayer.upper_for`, `_place_gun`; the death falls along `players[id].last_push`; `--survivor-rack`. Aiming arms and gun line up roughly, not exactly (the gun hangs from the spine, not the hands)

### [ ] 2.4.11 · First-person hands and sleeves
> id: S142 | needs: S140, S136 | size: L | asset: complex | rounds: 4 | tags: #weapon #art | test: `tests/test_viewmodel.gd` | see: `--weapon=4 --pose=aim`, `--hands-rack`

- Today each arm is two boxes (a glove and a sleeve, `Viewmodel._make_arm`) while the zombies have real hands: the most-seen model of the game is the worst one.
- [ ] 2.4.11.1 · Card: the hand of `tools/models/body.py` (the bodies' measured proportions), forearm and wrist; references of hands on a pistol grip, a rifle grip and a handguard
- [ ] 2.4.11.2 · Rig: wrist, palm, five fingers in three segments, the thumb with its base; grip poses as data per gun and per moment (hip, aim, trigger pulled, magazine grab, pump, bolt, shove, bandage), blended like the rest of the viewmodel #anim
- [ ] 2.4.11.3 · Round 1 · form: hand size and finger lengths against every gun's grip, the thumb over the web, no finger through a grip in any pose #anim
- [ ] 2.4.11.4 · Round 2 · structure: knuckles, finger pads, nails, the web of the thumb, the wrist's bones, tendons on the back of the hand; sleeves with a cuff, a seam and folds that follow the elbow's bend
- [ ] 2.4.11.5 · Round 3 · surface: skin colour per player slot, dirt in the creases, scratches; tactical gloves as a variant (knuckle pads, stitching, cut fingertips); a watch on the left wrist
- [ ] 2.4.11.6 · Round 4 · motion: the index finger pulls on each shot, the support hand slides on the pump, fingers spread on a magazine, the fingers wrap the bandage (S015)
- [ ] 2.4.11.7 · The sleeves follow the player's survivor look (S243 when it exists)
- [ ] 2.4.11.8 · Review: hip and aim on all nine guns at 1080p and the hands rack, beside the zombies' hands

## 2.5 · Guns
? Does every gun have its model, sound, handling, attachments and a render budget?
> tags: #weapon

### [~] 2.5.1 · P19 pistol
> id: S143 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=1 --pose=aim`, `--weapon=1 --pose=reload`

- [ ] 2.5.1.1 · Card: photos of the real gun (a modern polymer-frame pistol) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.1.2 · Round 1 · form: slide, frame, the grip's angle and beavertail, trigger guard, the magazine in the grip; the profile matches the photo at the same scale #perf
- [ ] 2.5.1.3 · Round 2 · structure: front and rear slide serrations, the ejection port with the barrel's hood, sights with white dots, takedown lever, slide stop, magazine release, the accessory rail's slots, the trigger with its safety blade
- [ ] 2.5.1.4 · Round 3 · surface: the grip's stippled panels, a matte slide with holster wear on its edges, stamped markings, grime
- [ ] 2.5.1.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.1.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.1.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.1.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.1.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.1.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.2 · P90
> id: S144 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=2 --pose=aim`, `--weapon=2 --pose=reload`

- [ ] 2.5.2.1 · Card: photos of the real gun (the bullpup personal defence weapon) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.2.2 · Round 1 · form: the bullpup shell, the thumbhole grip, the translucent magazine along the top, the stubby barrel and flash hider; the profile matches the photo at the same scale #perf #vfx
- [ ] 2.5.2.3 · Round 2 · structure: the ring sight on top, both charging handles, the cartridges visible in the magazine, the ejection chute under the stock, the fire selector disc, sling points #vfx
- [ ] 2.5.2.4 · Round 3 · surface: polymer with mould seams, scuffs on the grip, the magazine's tint, markings
- [ ] 2.5.2.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.2.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.2.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.2.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.2.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.2.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.3 · Type 95
> id: S145 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=3 --pose=aim`, `--weapon=3 --pose=reload`

- [ ] 2.5.3.1 · Card: photos of the real gun (the bullpup assault rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.3.2 · Round 1 · form: the bullpup body, the carry handle with its sight, the magazine behind the pistol grip, the cheek rest, the short barrel; the profile matches the photo at the same scale #perf
- [ ] 2.5.3.3 · Round 2 · structure: the rear aperture and front post, the charging handle under the carry handle, the ejection port, the selector behind the magazine, vent slots in the handguard, the flash hider #vfx
- [ ] 2.5.3.4 · Round 3 · surface: dark polymer texture, worn edges, stamped markings
- [ ] 2.5.3.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.3.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.3.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.3.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.3.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.3.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.4 · AK47
> id: S146 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=4 --pose=aim`, `--weapon=4 --pose=reload`

- [ ] 2.5.4.1 · Card: photos of the real gun (the rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.4.2 · Round 1 · form: the receiver, the gas tube over the barrel, wooden handguards and stock, the curved magazine, the pistol grip; the profile matches the photo at the same scale #perf
- [ ] 2.5.4.3 · Round 2 · structure: the dust cover's ribs and rivets, the rear sight leaf with its range scale, the hooded front post, the slant brake, the cleaning rod, the selector lever, the charging handle, sling loops, the trigger guard #vfx
- [ ] 2.5.4.4 · Round 3 · surface: bluing worn on the edges, scratched wood with grain, the magazine's ribs catching the light, a serial stamp, grime in the corners #vfx
- [ ] 2.5.4.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.4.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.4.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.4.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.4.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.4.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.5 · AS Val
> id: S147 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=5 --pose=aim`, `--weapon=5 --pose=reload`

- [ ] 2.5.5.1 · Card: photos of the real gun (the suppressed rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.5.2 · Round 1 · form: the integral suppressor along the whole front, the receiver, the skeleton stock folded or out, the 20-round box magazine; the profile matches the photo at the same scale #perf
- [ ] 2.5.5.3 · Round 2 · structure: the suppressor's perforated sleeve and end cap, the side scope rail, the iron sights on the suppressor, the safety lever, the charging handle, the stock's tube frame and butt plate #perf
- [ ] 2.5.5.4 · Round 3 · surface: black finish worn bare on the suppressor's edges, the magazine's ribs, markings
- [ ] 2.5.5.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.5.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.5.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.5.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.5.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.5.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.6 · USAS-12
> id: S148 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=6 --pose=aim`, `--weapon=6 --pose=reload`

- [ ] 2.5.6.1 · Card: photos of the real gun (the automatic shotgun) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.6.2 · Round 1 · form: the long boxy receiver, the carry handle, the pistol grip and fixed stock, the box magazine; the profile matches the photo at the same scale #perf
- [ ] 2.5.6.3 · Round 2 · structure: the handle's sight channel, the front sight, the charging handle, the barrel shroud's vents, sling swivels, the magazine release
- [ ] 2.5.6.4 · Round 3 · surface: matte black polymer and steel, scuffs, markings
- [ ] 2.5.6.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.6.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.6.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.6.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.6.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.6.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.7 · SPAS-12
> id: S149 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=7 --pose=aim`, `--weapon=7 --pose=reload`

- [ ] 2.5.7.1 · Card: photos of the real gun (the pump shotgun) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.7.2 · Round 1 · form: the receiver, the perforated heat shield over the barrel, the pump fore-end, the tube magazine, the pistol grip, the folding stock with its hook; the profile matches the photo at the same scale #perf
- [ ] 2.5.7.3 · Round 2 · structure: the heat shield's holes, the fore-end's ribs, the pump and semi selector, the sights, the stock's hinge and hook, sling swivels
- [ ] 2.5.7.4 · Round 3 · surface: parkerised finish with wear, scratches on the shield, markings
- [ ] 2.5.7.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.7.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.7.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.7.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.7.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.7.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.8 · Orsis T-5000
> id: S150 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=8 --pose=aim`, `--weapon=8 --pose=reload`

- [ ] 2.5.8.1 · Card: photos of the real gun (the bolt-action sniper rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.8.2 · Round 1 · form: the chassis stock with its skeleton butt, the long free-floated barrel, the big scope, the bolt with its large knob, the box magazine, the bipod; the profile matches the photo at the same scale #perf
- [ ] 2.5.8.3 · Round 2 · structure: the adjustable cheek riser and butt pad, the top rail, the scope's turrets and caps, the muzzle brake's ports, the folding hinge, the bipod's legs and feet #perf
- [ ] 2.5.8.4 · Round 3 · surface: a ceramic-coat finish worn at the edges, scratches on the brake, tinted lens glass, markings
- [ ] 2.5.8.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.8.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.8.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.8.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.8.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.8.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [~] 2.5.9 · Dragunov
> id: S151 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #existing | test: `tests/test_elements.gd` | see: `--gun-rack`, `--weapon=9 --pose=aim`, `--weapon=9 --pose=reload`

- [ ] 2.5.9.1 · Card: photos of the real gun (the marksman rifle) from the left, the right and three-quarter, sizes from its overall length; the magazine and the moving action stay separate parts
- [ ] 2.5.9.2 · Round 1 · form: the long thin barrel, the skeleton wooden thumbhole stock, the handguards, the scope offset to the left, the 10-round magazine; the profile matches the photo at the same scale #perf
- [ ] 2.5.9.3 · Round 2 · structure: the slotted flash hider, the bayonet lug, the handguards' vent holes, the cheek piece, the scope's rubber eyecup and turrets, the dust cover, the safety lever #vfx
- [ ] 2.5.9.4 · Round 3 · surface: lacquered wood with grain and dents, worn bluing, markings #vfx
- [ ] 2.5.9.5 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos; the hands (S142) close on the right places
- [x] 2.5.9.6 · In the game: `Weapons.DEFS` entry, balance sheet row, the first model (`guns.gd`) #gameplay
- [x] 2.5.9.7 · SFX: its own shot near, far and suppressed (S033) #sound
- [x] 2.5.9.8 · Handling poses: aim, reload, sprint carry, bolt or pump (S034) #anim
- [ ] 2.5.9.9 · Compatible attachments by its family (mount points, S105)
- [ ] 2.5.9.10 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD #perf

### [ ] 2.5.10 · Desert Eagle
> id: S273 | from: S097 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #pistol | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.10.1 · Behaviour: 7 rounds, heavy kick that lifts the whole view, big flash #gameplay
- [ ] 2.5.10.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.10.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.10.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.10.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.10.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.10.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.10.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.10.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.10.10 · Compatible attachments: suppressor, red dot, laser, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.10.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.10.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.11 · Revolver
> id: S274 | from: S097 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #pistol | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.11.1 · Behaviour: 6 shots, cylinder turns per shot, reload by swinging it out and dropping six casings at once #gameplay
- [ ] 2.5.11.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.11.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.11.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.11.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.11.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.11.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.11.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.11.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.11.10 · Compatible attachments: suppressor, red dot, laser, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.11.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.11.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.12 · Glock 18
> id: S275 | from: S097 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #pistol | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.12.1 · Behaviour: automatic, climbs fast #gameplay
- [ ] 2.5.12.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.12.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.12.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.12.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.12.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.12.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.12.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.12.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.12.10 · Compatible attachments: suppressor, red dot, laser, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.12.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.12.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.13 · Flare gun
> id: S276 | from: S097 | needs: S013, S094, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #pistol | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.13.1 · Behaviour: one shot, a burning red ball that arcs, sticks, lights the area and sets fire (S094) #gameplay
- [ ] 2.5.13.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.13.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.13.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.13.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.13.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.13.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.13.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.13.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.13.10 · Compatible attachments: suppressor, red dot, laser, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.13.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.13.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.14 · MP5
> id: S277 | from: S098 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #smg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.14.1 · Behaviour: accurate, low recoil, the slap of the charging handle on reload #gameplay
- [ ] 2.5.14.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.14.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.14.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.14.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.14.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.14.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.14.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.14.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.14.10 · Compatible attachments: suppressor, red dot, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.14.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.14.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.15 · Mac-10
> id: S278 | from: S098 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #smg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.15.1 · Behaviour: very fast, wild spread #gameplay
- [ ] 2.5.15.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.15.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.15.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.15.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.15.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.15.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.15.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.15.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.15.10 · Compatible attachments: suppressor, red dot, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.15.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.15.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.16 · Uzi
> id: S279 | from: S098 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #smg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.16.1 · Behaviour: open bolt, top charging knob #gameplay
- [ ] 2.5.16.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.16.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.16.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.16.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.16.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.16.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.16.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.16.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.16.10 · Compatible attachments: suppressor, red dot, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.16.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.16.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.17 · Vector
> id: S280 | from: S098 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #smg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.17.1 · Behaviour: very fast, small magazine, low muzzle rise #gameplay
- [ ] 2.5.17.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.17.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.17.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.17.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.17.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.17.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.17.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.17.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.17.10 · Compatible attachments: suppressor, red dot, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.17.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.17.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.18 · MP7 suppressed
> id: S281 | from: S098 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #smg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.18.1 · Behaviour: quiet, low noise value #gameplay
- [ ] 2.5.18.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.18.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.18.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.18.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.18.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.18.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.18.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.18.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.18.10 · Compatible attachments: suppressor, red dot, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.18.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.18.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.19 · M4A1
> id: S282 | from: S099 | needs: S099, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #rifle | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.19.1 · Behaviour: the all-rounder; auto, semi and burst #gameplay
- [ ] 2.5.19.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.19.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.19.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.19.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.19.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.19.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.19.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.19.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.19.10 · Compatible attachments: suppressor, red dot, scope 4x, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.19.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.19.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.20 · SCAR-H
> id: S283 | from: S099 | needs: S099, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #rifle | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.20.1 · Behaviour: heavy calibre, slower, hits hard #gameplay
- [ ] 2.5.20.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.20.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.20.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.20.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.20.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.20.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.20.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.20.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.20.10 · Compatible attachments: suppressor, red dot, scope 4x, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.20.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.20.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.21 · FAL
> id: S284 | from: S099 | needs: S099, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #rifle | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.21.1 · Behaviour: semi-heavy battle rifle, long reach #gameplay
- [ ] 2.5.21.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.21.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.21.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.21.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.21.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.21.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.21.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.21.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.21.10 · Compatible attachments: suppressor, red dot, scope 4x, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.21.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.21.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.22 · G36
> id: S285 | from: S099 | needs: S099, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #rifle | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.22.1 · Behaviour: light, steady, a built-in optic #gameplay
- [ ] 2.5.22.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.22.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.22.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.22.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.22.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.22.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.22.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.22.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.22.10 · Compatible attachments: suppressor, red dot, scope 4x, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.22.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.22.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.23 · AUG
> id: S286 | from: S099 | needs: S099, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #rifle | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.23.1 · Behaviour: bullpup, magazine behind the grip (its own reload) #gameplay
- [ ] 2.5.23.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.23.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.23.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.23.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.23.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.23.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.23.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.23.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.23.10 · Compatible attachments: suppressor, red dot, scope 4x, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.23.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.23.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.24 · Low-tier carbine
> id: S287 | from: S099 | needs: S099, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #rifle | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.24.1 · Behaviour: the first rifle players find: worn, loose, honest #gameplay
- [ ] 2.5.24.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.24.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.24.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.24.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.24.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.24.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.24.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.24.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.24.10 · Compatible attachments: suppressor, red dot, scope 4x, laser, grip, extended magazine, weapon light (mount points, S105)
- [ ] 2.5.24.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.24.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.25 · Double-barrel
> id: S288 | from: S100 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #shotgun | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.25.1 · Behaviour: two shots, both at once on the alternate trigger, break-open reload with two hulls popping out #gameplay
- [ ] 2.5.25.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.25.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.25.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.25.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.25.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.25.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.25.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.25.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.25.10 · Compatible attachments: laser, weapon light, grip (pump only); slugs as ammo (mount points, S105)
- [ ] 2.5.25.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.25.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.26 · Sawn-off
> id: S289 | from: S100 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #shotgun | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.26.1 · Behaviour: sidearm slot, huge spread #gameplay
- [ ] 2.5.26.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.26.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.26.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.26.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.26.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.26.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.26.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.26.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.26.10 · Compatible attachments: laser, weapon light, grip (pump only); slugs as ammo (mount points, S105)
- [ ] 2.5.26.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.26.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.27 · Mossberg pump
> id: S290 | from: S100 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #shotgun | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.27.1 · Behaviour: the plain pump #gameplay
- [ ] 2.5.27.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.27.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.27.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.27.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.27.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.27.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.27.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.27.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.27.10 · Compatible attachments: laser, weapon light, grip (pump only); slugs as ammo (mount points, S105)
- [ ] 2.5.27.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.27.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.28 · Lever-action shotgun
> id: S291 | from: S100 | needs: S013, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #shotgun | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.28.1 · Behaviour: lever loop swing between shots #gameplay
- [ ] 2.5.28.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.28.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.28.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.28.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.28.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.28.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.28.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.28.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.28.10 · Compatible attachments: laser, weapon light, grip (pump only); slugs as ammo (mount points, S105)
- [ ] 2.5.28.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.28.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.29 · M14 EBR
> id: S292 | from: S101 | needs: S101, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #marksman | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.29.1 · Behaviour: semi marksman rifle on a chassis #gameplay
- [ ] 2.5.29.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.29.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.29.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.29.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.29.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.29.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.29.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.29.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.29.10 · Compatible attachments: scope (fixed), suppressor, bipod (mount points, S105)
- [ ] 2.5.29.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.29.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.30 · Lever-action hunting rifle
> id: S293 | from: S101 | needs: S101, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #marksman | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.30.1 · Behaviour: slow, accurate, a working lever #gameplay
- [ ] 2.5.30.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.30.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.30.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.30.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.30.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.30.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.30.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.30.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.30.10 · Compatible attachments: scope (fixed), suppressor, bipod (mount points, S105)
- [ ] 2.5.30.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.30.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.31 · Barrett .50
> id: S294 | from: S101 | needs: S101, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #marksman | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.31.1 · Behaviour: goes through a line of zombies, dust kicked up around the shooter, heavy view recoil, slow to aim #gameplay
- [ ] 2.5.31.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.31.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.31.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.31.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.31.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.31.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.31.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.31.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.31.10 · Compatible attachments: scope (fixed), suppressor, bipod (mount points, S105)
- [ ] 2.5.31.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.31.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.32 · M249
> id: S295 | from: S102 | needs: S102, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #mg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.32.1 · Behaviour: belt of 100, slow aim, slow sprint, long reload with the feed cover lifted and the belt laid in #gameplay
- [ ] 2.5.32.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.32.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.32.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.32.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.32.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.32.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.32.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.32.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.32.10 · Compatible attachments: grip, weapon light; deployed on cover (mount points, S105)
- [ ] 2.5.32.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.32.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.33 · PKM
> id: S296 | from: S102 | needs: S102, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #mg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.33.1 · Behaviour: belt of 100, heavier, the same long reload #gameplay
- [ ] 2.5.33.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.33.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.33.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.33.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.33.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.33.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.33.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.33.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.33.10 · Compatible attachments: grip, weapon light; deployed on cover (mount points, S105)
- [ ] 2.5.33.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.33.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.34 · Minigun
> id: S297 | from: S102 | needs: S102, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #mg | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.34.1 · Behaviour: rare, spin-up before firing, a rope of tracers, the player walks slowly, barrels keep spinning down #gameplay
- [ ] 2.5.34.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.34.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.34.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.34.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.34.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.34.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.34.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.34.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.34.10 · Compatible attachments: grip, weapon light; deployed on cover (mount points, S105)
- [ ] 2.5.34.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.34.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.35 · Grenade launcher
> id: S298 | from: S103 | needs: S103, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #launcher | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.35.1 · Behaviour: break-open single shot, arcing round, thump #gameplay
- [ ] 2.5.35.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.35.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.35.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.35.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.35.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.35.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.35.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.35.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.35.10 · Compatible attachments: none (mount points, S105)
- [ ] 2.5.35.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.35.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.36 · RPG
> id: S299 | from: S103 | needs: S103, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #launcher | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.36.1 · Behaviour: rocket with a smoke trail and a lit motor, back-blast cone behind the shooter that hurts #gameplay
- [ ] 2.5.36.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.36.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.36.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.36.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.36.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.36.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.36.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.36.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.36.10 · Compatible attachments: none (mount points, S105)
- [ ] 2.5.36.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.36.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.37 · Flamethrower
> id: S300 | from: S104 | needs: S094, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #special | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.37.1 · Behaviour: a stream of fire that bends when the player turns, lights surfaces and zombies, pilot flame at the nozzle, fuel tank gauge, short range #gameplay
- [ ] 2.5.37.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.37.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.37.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.37.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.37.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.37.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.37.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.37.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.37.10 · Compatible attachments: crossbow: scope; flamethrower: none (mount points, S105)
- [ ] 2.5.37.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.37.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.38 · Crossbow
> id: S301 | from: S104 | needs: S094, S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art #special | test: `tests/test_weapons.gd`, `tests/test_elements.gd` | see: `--gun-rack`

- [ ] 2.5.38.1 · Behaviour: silent, bolt arcs, pins a zombie's limb or head to the wall behind it, bolts are retrieved; crank or lever draw with the string bending the limbs #gameplay
- [ ] 2.5.38.2 · `Weapons.DEFS` entry, calibre and balance sheet row (`tools\balance.ps1`) #gameplay
- [ ] 2.5.38.3 · Card: photos of the real gun from both sides and three-quarter, sizes from its overall length; magazine and moving action separate parts
- [ ] 2.5.38.4 · Round 1 · form: silhouette and proportions against the photos at the same scale
- [ ] 2.5.38.5 · Round 2 · structure: sights, controls, rails, serrations, the action's parts
- [ ] 2.5.38.6 · Round 3 · surface: finish, wear, markings, grime
- [ ] 2.5.38.7 · Handling poses: draw, aim, reload, sprint carry, inspect; the hands (S142) on the right places #anim
- [ ] 2.5.38.8 · SFX: its own shot (near, far, suppressed where it can be), action and reload sounds (`GunVoice.RECIPES`) #sound
- [ ] 2.5.38.9 · Effects: muzzle flash size, casing kind, tracer (S029 to S031) #vfx
- [ ] 2.5.38.10 · Compatible attachments: crossbow: scope; flamethrower: none (mount points, S105)
- [ ] 2.5.38.11 · Render optimisation: triangles per LOD on the card, one mesh per moving part, the third-person LOD on other players #perf
- [ ] 2.5.38.12 · Review: first person at the hip, aimed and reloading, and the gun rack, beside the photos

### [ ] 2.5.39 · Rifles: fire modes
> id: S099 | needs: S013 | size: M | tags: #weapon #vfx | test: `tests/test_weapons.gd` | see: `--gun-rack`

- [ ] 2.5.39.1 · Fire modes in `weapon_state.gd`: auto, semi, three-round burst, with a selector key and click #sound
- the guns of this family are their own items in 2.5 (`from: S099`)

### [ ] 2.5.40 · Shotguns: slug rounds
> id: S100 | needs: S013 | size: M | tags: #weapon | test: `tests/test_weapons.gd` | see: `--gun-rack`

- [ ] 2.5.40.1 · Slug rounds as a second ammo type for shotguns
- the guns of this family are their own items in 2.5 (`from: S100`)

### [ ] 2.5.41 · Penetration and scopes
> id: S101 | needs: S032 | size: M | tags: #weapon | test: `tests/test_penetration.gd`

- [ ] 2.5.41.1 · Penetration on the host: a bullet passes through zombies and thin surfaces by calibre, losing damage each time
- [ ] 2.5.41.2 · Exit effects on the far side of a surface and of a body
- [ ] 2.5.41.3 · Scope: lens glint seen by others, sway while standing, hold breath to steady (drains stamina) #vfx
- the guns of this family are their own items in 2.5 (`from: S101`)

### [ ] 2.5.42 · Machine guns: belts, heat, deploying
> id: S102 | needs: S063 | size: M | tags: #weapon | test: `tests/test_weapons.gd`

- [ ] 2.5.42.1 · Belt visibly shortens on the viewmodel; links and casings eject #anim #art
- [ ] 2.5.42.2 · Barrel heat glow after long bursts #vfx
- [ ] 2.5.42.3 · Deployed on cover when crouched behind it: tighter spread
- the guns of this family are their own items in 2.5 (`from: S102`)

### [ ] 2.5.43 · Destruction and explosive rounds
> id: S103 | needs: S093, S053 | size: L | tags: #weapon | test: `tests/test_launchers.gd`

- [ ] 2.5.43.1 · Destructible pieces marked in map data: doors, plank walls, marked wall panels blow out into rubble with rebar, leaving a hole that is a new nav link
- [ ] 2.5.43.2 · Cars hit by explosives burn, then explode once
- [ ] 2.5.43.3 · Rounds are rare loot #loot
- the guns of this family are their own items in 2.5 (`from: S103`)

### [ ] 2.5.44 · Attachments
> id: S105 | needs: S099 | size: L | tags: #weapon | test: `tests/test_attachments.gd` | see: `--gun-rack --attach=all`

- [ ] 2.5.44.1 · Mount points per gun in the model builders: muzzle, top rail, under-barrel, side rail, magazine #art
- [ ] 2.5.44.2 · Suppressor: quieter noise value, no flash, slightly lower damage #sound #vfx
- [ ] 2.5.44.3 · Red dot: a glowing dot on a glass pane that stays on target (parallax), replaces the iron sight pose #vfx #anim
- [ ] 2.5.44.4 · Scope 4x: scoped view with a reticle
- [ ] 2.5.44.5 · Extended magazine: longer mesh, more rounds, slower reload #art
- [ ] 2.5.44.6 · Laser: a thin beam visible in fog and smoke, a dot on surfaces, tighter hip spread #vfx
- [ ] 2.5.44.7 · Grip: less recoil
- [ ] 2.5.44.8 · Weapon flashlight: shares S107 #vfx
- [ ] 2.5.44.9 · Found as loot, fitted from the wheel with a short fitting animation; sent to others as a bit mask beside the weapon id #net #ui #anim #loot

### [ ] 2.5.45 · Mounted gun
> id: S063 | needs: S011, S004, S244 | size: M | tags: #weapon | test: `tests/test_mounted_gun.gd`

- [ ] 2.5.45.1 · Tripod machine gun as an interactable: use to man, use to leave
- [ ] 2.5.45.2 · Limited arc, heavy slow traverse, belt of its own ammo, overheats (barrel glows from dull red to orange, steam when it cools) #vfx
- [ ] 2.5.45.3 · Viewmodel: both hands on spade grips, the whole gun shudders, belt links and big casings pour out #anim #art
- [ ] 2.5.45.4 · Heavy tracers every shot, large muzzle flash lighting the sandbags #vfx
- [ ] 2.5.45.5 · Host owns who mans it, the gunner is exposed from behind #net
- [ ] 2.5.45.6 · Bullets tear limbs off at any range

### [ ] 2.5.46 · Mounted machine gun model
> id: S244 | needs: S141, S142 | size: M | asset: complex | rounds: 3 | tags: #weapon #art | test: `tests/test_elements.gd` | see: `--prop-rack=mounted_gun`

- [ ] 2.5.46.1 · Card: a heavy machine gun on a tripod with spade grips (photos first)
- [ ] 2.5.46.2 · Round 1 · form: the receiver, the heavy barrel and its carrying handle, the tripod's legs and pintle, the spade grips, the ammo can on its tray
- [ ] 2.5.46.3 · Round 2 · structure: the feed cover and its latch, the barrel's cooling holes, the leaf and ladder sights, the traverse and elevation gear, the belt of linked rounds, the cocking handle
- [ ] 2.5.46.4 · Round 3 · surface: worn parkerising, oil, brass of the rounds, stencils on the can
- [ ] 2.5.46.5 · It sits in a sandbag nest from S185
- [ ] 2.5.46.6 · Review: the first-person manned view with the hands on the grips, and the rack

## 2.6 · Melee and throwables
? Do we have melee weapons, grenades, fire and the tactical throwables?
> tags: #weapon

### [ ] 2.6.1 · Melee weapons: knife and bat
> id: S090 | needs: S013, S019 | size: L | tags: #weapon | test: `tests/test_melee.gd` | see: `--weapon=knife --pose=swing`

- [ ] 2.6.1.1 · Melee entries in `Weapons.DEFS`: reach, arc, swing time, recovery, damage, stagger, sever chance, noise, durability #sound #anim
- [ ] 2.6.1.2 · Host resolves a swing as an arc sweep at the hit frame, part hit decided by height #net #anim
- [ ] 2.6.1.3 · Viewmodel swings as blended poses: wind-up, strike with overshoot, follow-through, return; a three-swing combo alternating sides #anim #art
- [ ] 2.6.1.4 · Hit stop: 40 ms freeze of the viewmodel and a camera nudge on contact #anim #art
- [ ] 2.6.1.5 · Combat knife: fast stabs and slashes, quiet, a held stab to the head from behind kills a dormant zombie
- [ ] 2.6.1.6 · Baseball bat: two-hand swings, knocks zombies down, dents and blood build up on the bat mesh #vfx #anim #art
- [ ] 2.6.1.7 · Blood on the weapon and hands that fades over time #vfx
- [ ] 2.6.1.8 · Each weapon's model from its own element step (rounds 3), appended and done before this step; shown in the rack #art

### [ ] 2.6.2 · Blades: axe, machete, katana
> id: S091 | needs: S090 | size: M | tags: #weapon | test: `tests/test_melee_blades.gd`

- [ ] 2.6.2.1 · Sever rules: blades cut the limb the arc passes through, with a clean stump
- [ ] 2.6.2.2 · Fire axe: slow overhead chop, sticks in the body for a beat and is wrenched out, breaks doors #vfx
- [ ] 2.6.2.3 · Machete: fast diagonal cuts, best limb sever per second
- [ ] 2.6.2.4 · Katana: rare loot, fast wide arcs, decapitation with a held strike, a blood arc flung off the blade after each cut #vfx #loot
- [ ] 2.6.2.5 · Blade trails: a faint streak along the edge during the strike

### [ ] 2.6.3 · Blunt and junk: crowbar, sledgehammer, the rest
> id: S092 | needs: S090, S054 | size: M | tags: #weapon | test: `tests/test_melee_blunt.gd`

- [ ] 2.6.3.1 · Crowbar: pries locked doors, vaults and elevator doors with a held use and a pry animation #anim
- [ ] 2.6.3.2 · Sledgehammer: very slow, huge stagger in an arc, bursts heads, breaks doors and weak walls marked in map data
- [ ] 2.6.3.3 · Junk with durability that breaks in the hand: shovel, pipe, frying pan (with a ringing hit) #sound
- [ ] 2.6.3.4 · Breaking: the head flies off, the player is left with a stub for one weak hit

### [ ] 2.6.4 · Throwables and the frag grenade
> id: S093 | needs: S014, S004, S020 | size: L | tags: #weapon | test: `tests/test_grenade.gd` | see: `--host --demo --throw=frag --shot-at=2,2.1,2.3`

- [ ] 2.6.4.1 · Throw: hold to cook and show an arc preview, release to throw; underhand roll with the alternate key
- [ ] 2.6.4.2 · Viewmodel: pull the pin with the off hand, arm back, release, hand lingers open #anim #art
- [ ] 2.6.4.3 · Host simulates the bounce; clients see the same grenade with a spinning lever flying off #net
- [ ] 2.6.4.4 · Explosion
  - [ ] One-frame white flash and a pooled light
  - [ ] Fast fireball that turns to black smoke rolling upward
  - [ ] Shock ring on the ground, dust kicked from every nearby surface, debris chunks with trails
  - [ ] Scorch decal, lingering smoke for 8 s
  - [ ] Camera shake by distance, tinnitus hook for S089
- [ ] 2.6.4.5 · Damage falls off with distance and is blocked by walls; limbs fly
- [ ] 2.6.4.6 · Friendly damage by difficulty
- [ ] 2.6.4.7 · `on_explosion` hook

### [ ] 2.6.5 · Fire
> id: S094 | needs: S004, S070 | size: L | tags: #weapon #vfx | test: `tests/test_fire.gd` | see: `--host --demo --fire --shot-at=1,3,6`

- [ ] 2.6.5.1 · Fire as a host object: area, fuel time, spreads to flammable surface kinds and to zombies that touch it
- [ ] 2.6.5.2 · Flame look: layered additive billboards rising and curling, hot core white-yellow, orange body, red tips, sparks floating up, black smoke above
- [ ] 2.6.5.3 · Light: one flickering pooled omni per fire cluster, colour wandering between orange and yellow #perf
- [ ] 2.6.5.4 · Heat shimmer above the flames (screen distortion on HIGH tier only) #perf #ui
- [ ] 2.6.5.5 · Burning zombies: flames attached to body parts, they keep coming, skin chars to black over seconds, they collapse smoking
- [ ] 2.6.5.6 · Burning players: screen edge flames, damage over time, sprinting spreads it less than standing still #ui
- [ ] 2.6.5.7 · Aftermath: scorched ground decal, embers glowing and fading, charred corpses
- [ ] 2.6.5.8 · Capped: fires merge, the oldest die first #perf

### [ ] 2.6.6 · Molotov
> id: S095 | needs: S093, S094 | size: S | tags: #weapon | test: `tests/test_molotov.gd`

- [ ] 2.6.6.1 · Bottle with a lit rag: the flame trails in the hand and in flight #vfx
- [ ] 2.6.6.2 · Breaks on impact: glass burst, a splash of fire that runs outward along the ground and up walls a little #vfx
- [ ] 2.6.6.3 · Burns for seconds as an area denial, blocks a doorway
- [ ] 2.6.6.4 · Lights anything flammable in the splash #vfx

### [ ] 2.6.7 · Flashbang, noise lure, flare
> id: S096 | needs: S093, S072 | size: M | tags: #weapon #sound #vfx | test: `tests/test_tactical_throwables.gd`

- [ ] 2.6.7.1 · Flashbang: zombies in sight of it stagger blind for seconds; players looking at it get a white screen that fades through an after-image, and ringing #ui
- [ ] 2.6.7.2 · Noise lure (an alarm clock taped to a pipe): rings, zombies gather on it, then it pops
- [ ] 2.6.7.3 · Road flare: red sputtering light with drifting sparks and red smoke, zombies avoid it a little, marks the extraction
- [ ] 2.6.7.4 · Each a pickup and a wheel slot #ui #loot

## 2.7 · Player models
? Do we have variable player models for the survivors?
> tags: #art #anim

### [ ] 2.7.1 · Survivor models
> id: S243 | needs: S136, S137 | size: L | asset: complex | rounds: 4 | tags: #art #anim | test: `tests/test_body_model.gd` | see: `--host --survivor-rack`

- [ ] 2.7.1.1 · Card: four distinct survivor looks, one per player slot, with living faces (photos of the kinds of clothing)
- [ ] 2.7.1.2 · Round 1 · form: four bodies and outfits from the garment kit: a tactical vest, a jacket, a hoodie, backpack straps
- [ ] 2.7.1.3 · Round 2 · structure: living faces (eyes, brows, a mouth that is not a zombie's), hair styles, pouches and gear
- [ ] 2.7.1.4 · Round 3 · surface: dirt, wear, blood from the fight #vfx
- [ ] 2.7.1.5 · Round 4 · first person: the sleeves of S142 match each look; the lobby's picker (S122) shows them #ui
- [ ] 2.7.1.6 · Review: the survivor rack front and back at 1 m, and a remote player in play

### [ ] 2.7.2 · Survivor customisation
> id: S302 | needs: S243, S122 | size: M | asset: simple | tags: #art #anim

- [ ] 2.7.2.1 · Pick a survivor body and outfit in the menu, colour variants, a name tag; seeded looks for bots #ui
- [ ] 2.7.2.2 · Sent once in `welcome` as a small id, never in snapshots #net
- [ ] 2.7.2.3 · Dirt and blood build up on the outfit during a run (shader layer) #vfx
- [ ] 2.7.2.4 · The first-person sleeves match the outfit (S142)

---

# 3 · Open World (7 Days to Die)

A run without a script: loot to search, hordes by day and night, buildings that differ every time, a safe house to hold.

## 3.1 · Looting
? Do we have a looting system for the 7 Days to Die style?
> tags: #loot

### [ ] 3.1.1 · Loot and rarity
> id: S106 | needs: S012, S014 | size: M | tags: #loot | test: `tests/test_loot.gd`

- [ ] 3.1.1.1 · Loot tables in `Config` by container kind and place: lootbox, locker, ammo crate, medical cabinet, car boot, corpse
- [ ] 3.1.1.2 · Rarity tiers with a colour and a glow on the pickup #perf #vfx
- [ ] 3.1.1.3 · Per-mission seeded rolls so every peer and every retry with the same seed agrees #net
- [ ] 3.1.1.4 · Lootbox opening: lid springs, light spills out, items rise and settle #sound
- [ ] 3.1.1.5 · Searching takes time for big containers, with a progress ring #ui
- [ ] 3.1.1.6 · Placement rule: good loot is off the main route

### [ ] 3.1.2 · Containers: lootbox, ammo crate, ammo cartons
> id: S152 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #loot #art | test: `tests/test_elements.gd` | see: `--prop-rack=containers`, `--host --map=corridor --shot-at=2`

- Today these are boxes in `lootbox.gd`, `ammo_crate.gd`, `ammo_box.gd`; the same nodes and states get new looks.
- [ ] 3.1.2.1 · Card: a steel supply box, a military ammunition crate, a carton per calibre; references of each
- [ ] 3.1.2.2 · Round 1 · form: sizes against a hand and a rifle; the lids and their hinge lines
- [ ] 3.1.2.3 · Round 2 · structure: latches, hinges, rope or steel handles, corner guards, the crate's stacking feet, the cartons' flaps and tape
- [ ] 3.1.2.4 · Round 3 · surface: stencilled lettering and lot numbers, chipped olive paint, the calibre stripe and brand-free print on the cartons, worn corners
- [ ] 3.1.2.5 · States: shut, open (the lid hinge already animates), empty, broken open
- [ ] 3.1.2.6 · Review: the corridor shot and the rack at 1 m
- Under way: family `tools/models/props/containers.py`: `lootbox` (pressed steel chest, clasps, lid), `ammo_crate` (boards, cleats, rope handles, the rounds inside, lid) and `ammo_carton` (band, tape, print) have references and round 1, built. Left: rounds 2 and 3, the empty / broken states, swapping them into `lootbox.gd`, `ammo_crate.gd`, `ammo_box.gd` (the lootbox's lid hinges on its -Z edge today: turn the node).

### [ ] 3.1.3 · Carried things: medkit, bandage, pills, planks, backpack
> id: S153 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #loot #art | test: `tests/test_elements.gd` | see: `--prop-rack=carried`, `--host --map=corridor --wheel --shot-at=3`

- [ ] 3.1.3.1 · Card: a red medical bag with a white cross, a bandage roll, a pill bottle, rough planks with nails, a hiking backpack; references of each
- [ ] 3.1.3.2 · Round 1 · form: sizes in a hand (the first-person heal and the wheel show them close) #ui
- [ ] 3.1.3.3 · Round 2 · structure: zips, straps and buckles, the roll's loose end and gauze weave, the bottle's cap and label, nail heads and split ends on the planks #perf
- [ ] 3.1.3.4 · Round 3 · surface: dirt and blood on the bag, fabric texture, the label's print, wood grain and saw marks #vfx
- [ ] 3.1.3.5 · The item wheel's icons rendered from these models, replacing the box icons of S014 #ui
- [ ] 3.1.3.6 · The heal animation (S015) holds the real bandage; the dropped backpack (`backpack.gd`) is this one #anim
- [ ] 3.1.3.7 · Review: the wheel and the heal at 1080p, the rack at 1 m #ui

### [ ] 3.1.4 · Loot in houses
> id: S256 | needs: S246, S152, S153 | size: M | tags: #loot | test: `tests/test_house_loot.gd` | see: `--house-rack`

- [ ] 3.1.4.1 · Room dressing slots carry loot by room kind (kitchen, bedroom, bathroom cabinet, shop counter), seeded per house so every peer agrees #net
- [ ] 3.1.4.2 · Lootboxes, ammo cartons and carried things (medkit, bandage, pills, planks) from the library's models #art
- [ ] 3.1.4.3 · What was taken is part of the house's state (late joiners), capped like drops #perf #net
- [ ] 3.1.4.4 · Loot found scales with difficulty (`ammo found`)

### [ ] 3.1.5 · Searched and restocked
> id: S303 | needs: S256, S264 | size: S | tags: #loot

- [ ] 3.1.5.1 · Searched containers are marked (lid open, drawers out) on every peer #net
- [ ] 3.1.5.2 · Loot restocks after `Config.LOOT_RESTOCK` in-game days in open world, never in missions #gameplay
- [ ] 3.1.5.3 · Quality by place: a gun shop, a pharmacy, a police station beat a flat #map

### [ ] 3.1.6 · Scavenging parts
> id: S304 | needs: S014, S092 | size: M | tags: #loot #base

- [ ] 3.1.6.1 · Dismantle cars, furniture and appliances with a held use for parts (scrap, cloth, nails, wire, fuel) #gameplay
- [ ] 3.1.6.2 · Tools speed it up (crowbar, wrench); noise draws zombies (S020) #gameplay #sound
- [ ] 3.1.6.3 · Parts are the input to crafting (3.4, 4.2)

## 3.2 · Zombie spawn rate and hordes
? Do zombies come at the right rate by day and night, with horde nights?
> tags: #ai #gameplay

### [ ] 3.2.1 · Spawn rate by time and place
> id: S305 | needs: S028, S264 | size: M | tags: #ai #gameplay | test: `tests/test_open_world.gd`

- [ ] 3.2.1.1 · Spawn density per area and time of day in `Config` (fewer by day, more at night, more in the centre)
- [ ] 3.2.1.2 · Heat (S020) and the director (S028) raise it; quiet play lowers it
- [ ] 3.2.1.3 · Sleeping groups in buildings that wake when entered #map
- [ ] 3.2.1.4 · A spawn never happens in a player's sight (MapData.sees)

### [ ] 3.2.2 · Horde nights
> id: S306 | needs: S305, S308 | size: M | tags: #ai #gameplay

- [ ] 3.2.2.1 · Every Nth night (Config.OPEN_HORDE_NIGHT) a horde that knows where the players are and comes for the safe house
- [ ] 3.2.2.2 · Warnings: sirens far off, the sky turns red at dusk, screamers (S079) on the roofs #vfx #sound
- [ ] 3.2.2.3 · Diggers and climbers among them (S074, S078) so walls are tested
- [ ] 3.2.2.4 · Survived: a loot drop by air at dawn #loot

## 3.3 · Building variance
? Are buildings different every run, complete inside, and quick to generate?
> tags: #map

### [~] 3.3.1 · House interiors: layout
> id: S246 | needs: S043 | size: L | tags: #map | test: `tests/test_house_plan.gd` | see: `tools\houses.ps1`, `--house-rack`

- Asked for after the plan was written: the town's ordinary houses get empty floors to walk (until now only the five POIs had interiors). Rooms and proportions only: the furniture is slots for S193's elements.
- [x] 3.3.1.1 · `HousePlan` (`scripts/world/house_plan.gd`): the fixed frame from a house's data (bays of both facades, street door, stair cage against the party wall in the middle or on the court, refends, flues), the same on every floor; mirrored for a door on the right
- [x] 3.3.1.2 · `HouseFloor`: per floor, seeded: corridor beside the stair (an entrée when wide, none in a narrow house), the allée and passage to the court on the ground floor, rooms cut between windows, partitions lined up with the walls behind and below, kinds (dwelling or shop floor), doors near corners with clear leaves, enfilades; a layout that breaks a rule is tried again
- [x] 3.3.1.3 · Passages in the player's size (`Config.INTERIOR_*`): corridors 1.2 m, doors 0.9 m, rooms 2.2 m, a way 0.72 m wide between furniture to every door and a window
- [x] 3.3.1.4 · `RoomDressing`: paint per room (palettes by kind, dado, boiseries, wallpaper, cornice, wear), lamps and switches, furniture slots per kind (fireplaces on the flues) #art
- [x] 3.3.1.5 · `InteriorBuilder`: walls with door and window gaps, painted faces, slabs with the stair well, flights and rails, door leaves, lights, collision; `--house-rack`
- [x] 3.3.1.6 · `tools\houses.ps1`: the sample house's three floors and eight others as JSON, drawn by `tools/house_plans.py`
- [ ] 3.3.1.7 · Houses of `CityBlocks` laid out from their own footprint (non-rectangular corners, wings, back buildings), hôtels and post-war slabs
- [ ] 3.3.1.8 · A house's street door opens (S191) and its floors are built only when a player comes near (budget per house) #perf
- [ ] 3.3.1.9 · Round 1 · plans: the sample's floors and the variants against plans of real Paris houses before Haussmann (references on a card first) #art
- [ ] 3.3.1.10 · Review: the three floors walked at eye height in `--house-rack` #anim

### [ ] 3.3.2 · Random room seeding
> id: S307 | needs: S246, S193 | size: L | tags: #map | test: `tests/test_house_plan.gd`

- [ ] 3.3.2.1 · Building types beyond the row house: shop, flat block, office, clinic, police post, workshop, each with its own room kinds
- [ ] 3.3.2.2 · Furniture and loot slots per room kind, seeded per building so every peer agrees (S256) #loot
- [ ] 3.3.2.3 · Story rooms: a barricaded bedroom, a suicide, a family's last meal, a looted pharmacy (rare, seeded) #story

### [ ] 3.3.3 · Window, door and stairs completeness
> id: S308 | needs: S246, S191, S192 | size: M | tags: #map | test: `tests/test_house_plan.gd`

- [ ] 3.3.3.1 · Every opening on a facade is real from inside: glass, frame, shutters, curtains #art
- [ ] 3.3.3.2 · Every door has a leaf that opens, locks or breaks (S191); every floor joins by stairs; roofs by a hatch
- [ ] 3.3.3.3 · Windows can be broken, climbed through and boarded (S055) #gameplay
- [ ] 3.3.3.4 · A check walks every house: no floor unreachable, no door into a wall #tool

### [ ] 3.3.4 · World generation speed
> id: S309 | needs: S246 | size: M | tags: #perf #map | test: `tests/test_house_streamer.gd`

- [ ] 3.3.4.1 · House layout on worker threads (already), meshes built in slices under a per-frame budget
- [ ] 3.3.4.2 · A cache of built houses by seed for the session
- [ ] 3.3.4.3 · Generation time per area measured in a test, with a limit in `Config` #tool

## 3.4 · Open world run
? Can a group survive days in an area: a safe house, needs, hand crafting, a way out?
> tags: #gameplay

### [ ] 3.4.1 · Open World on the areas
> id: S257 | needs: S051 | size: M | tags: #gameplay | test: `tests/test_game_modes.gd` | see: `--mode=open_world`

- PR 8 added the mode on the whole town (day and night clock, hordes by night). It moves onto the areas and gets what it lacks.
- [ ] 3.4.1.1 · Runs on one area, or two joined by a street, not the whole town
- [ ] 3.4.1.2 · Open houses to search (S256) and a safe house to hold through a horde night
- [ ] 3.4.1.3 · A way to leave: any area's extraction ends the run with its score

### [ ] 3.4.2 · Safe house
> id: S310 | needs: S055, S257 | size: M | tags: #base #gameplay

- [ ] 3.4.2.1 · Claim any house with one door: it becomes the respawn point and the horde night's target
- [ ] 3.4.2.2 · Board windows and doors with planks (S055), repair them, they break under hits
- [ ] 3.4.2.3 · Store items in a chest that persists for the run #loot

### [ ] 3.4.3 · Survival needs
> id: S311 | needs: S014, S264 | size: M | tags: #gameplay

- [ ] 3.4.3.1 · Hunger, thirst and fatigue that drain over days and slow stamina refill when low
- [ ] 3.4.3.2 · Cold in snow and rain (S266, S110): shelter and fire warm you #vfx
- [ ] 3.4.3.3 · Food and water as loot; eating and drinking from the wheel #loot #ui
- [ ] 3.4.3.4 · Off in missions; a toggle in open world

### [ ] 3.4.4 · Hand crafting
> id: S312 | needs: S304 | size: M | tags: #base #gameplay

- [ ] 3.4.4.1 · Recipes from parts (S304): bandage, splint, molotov, planks, a pipe bomb, arrows for the crossbow
- [ ] 3.4.4.2 · Craft from the wheel, takes time, interrupted by a hit #ui

## 3.5 · The whole town (later)
? The town in detail everywhere, once the five maps ship.
> tags: #map

### [x] 3.5.1 · Trace the OpenStreetMap tiles
> id: S039 | needs: none | size: L | tags: #map | test: `tests/test_city_osm.gd` | see: redraw `references/city_plan.png`

- [x] 3.5.1.1 · `tools/trace_osm.py` reads `references/1.png` to `9.png` into `scripts/world/city_osm.gd` (generated, never edited by hand)
  - [x] Each tile registered to `joinville.png` pixels by two named control points per tile, kept in the tool
  - [x] Building footprints: the brown-grey polygons, simplified to a few corners, area and centroid
  - [x] Street casings by colour class: red trunk, orange, yellow, white residential, grey pedestrian
  - [x] Water, parks, parking lots, forest stipple as polygons
- [x] 3.5.1.2 · Overlay picture `references/osm_on_reference.png` proves the registration by eye
- [x] 3.5.1.3 · Test: the terminal, the Prefeitura and the hospital footprints land inside their `CityData.POIS` lots
- [x] 3.5.1.4 · Gaps between tiles reported, not guessed
- What this gives the town: a plan to simplify (S040) and a density map for the blocks (S043), not footprints to rebuild one by one.
  - The tiles are at four times joinville.png's zoom (their scale bars); `--register` finds each tile's place by cross-correlating its buildings with joinville.png's (match 0.64 to 0.77) and the control points are kept in `TILES`. 1301 footprints (convex, simplified), streets as 1-pixel cells per class, areas as polygons; the overlay is generated, not committed. The nine tiles cover the centre in an uneven patchwork: what their bounding box leaves uncovered is `CityOsm.GAPS`

### [x] 3.5.2 · Street network 2
> id: S040 | needs: S039 | size: L | tags: #map | test: `tests/test_street_net.gd`, `tests/test_city_map.gd` | see: `--city-plan`

- Joinville's own streets, not an invented plan: the street grid is Joinville's, dressed as a French town (setts, pavements, pans coupés, invented French names). The map is the whole of `joinville.png` (and the hill road's hairpin above it), not a part cut out round the POIs; what is kept in detail and what only as a far LOD is decided after a performance pass.
- [x] 3.5.2.1 · `CityData.STREETS` traced off `joinville.png` by `tools/trace_streets.py` into `CityStreets`: the main streets (`principale`) where the bus routes of `joinville_main_streets.png` run, every other street a `rue`; the hill road by hand off the topography
- [x] 3.5.2.2 · Invented French street names for every street (`CityData.name_of`); never a real street of a real town on purpose
- [x] 3.5.2.3 · Per street: carriageway width, one-way direction, pavement width each side, surface kind (setts or asphalt)
- [x] 3.5.2.4 · Junctions as real shapes: chamfered corners (pans coupés), T and skewed cross
- [x] 3.5.2.5 · Streets as meshes following the polyline with mitred joints, not grid cells; the 4 m grid stays for navigation only
- [x] 3.5.2.6 · Only what lies inside a mission area is built in detail (S051)
- [x] 3.5.2.7 · `--city-plan` and the menu's map redrawn from the new plan #ui
- Done: 328 traced streets (76 main) and the hill road, `StreetNet` for junctions and strips, meshes in `CityMap._street_surfaces`. A first version invented an old core, a boulevard ring with a rond-point and faubourgs, inside a map cut to the hull of the POIs; both were dropped for Joinville's streets and the whole picture. Buildings still stand on the 4 m grid's BLOCK cells until S043 builds the îlots along the street lines. The detail area is a parameter of `CityMap` that nothing sets yet (S051 will).

### [x] 3.5.3 · Block massing
> id: S043 | needs: S039, S040 | size: L | asset: complex | rounds: 2 | tags: #map #art | test: `tests/test_city_blocks.gd` | see: `tools\shots.ps1 city_`, `--city-plan`

- The traced footprints say how dense each part of town is and where the big buildings sit; the blocks are Paris's before Haussmann, not Joinville's lots.
- [x] 3.5.3.1 · Îlots: each block between the new streets is closed by a row of narrow houses along its edge with courtyards and passages inside, seeded widths per house (two to four windows); footprints from `CityOsm` inside it set its density and where a big hall, court or garden breaks the row
- [x] 3.5.3.2 · Height from a class picked by street, place and seed
  - [x] Old core: four to six floors on narrow fronts, steep roofs with dormers, leaning a little
  - [x] Houses on the main streets: four or five floors, stone ground floor, plastered above, mansard roofs
  - [x] Hôtels particuliers: a stone house between a front court behind a gate and a garden behind
  - [x] A few post-war blocks at the edge of town, where the hospital tower and the bus station stand; no skyline of towers
  - [x] Ateliers: long low halls with glass roofs by the river
- [x] 3.5.3.3 · Roofs are part of the mass: pitched and mansard roofs with ridges and hips, the tall party-wall chimney stacks left to the kits
- [x] 3.5.3.4 · Collision is the block, one mesh per city block, test counts draws #perf
- [x] 3.5.3.5 · Blocks outside every mission area: low-detail silhouettes only
- [x] 3.5.3.6 · Round 1 · skyline: from the place du marché, the bridge and the hill: a sea of grey slate and red tile roofs bristling with chimney pots, the church tower and the town hall's campanile above it
- [x] 3.5.3.7 · Round 2 · roofscape: the îlots and courtyards from the helicopter's height against old Paris views and plans on the card (the Turgot plan's bird's-eye view)
- [x] 3.5.3.8 · Review: the three views side by side with the references
- Done: `CityBlocks` (`scripts/world/city_blocks.gd`): îlots from the 4 m grid's BLOCK runs, outlines straightened onto the building lines; rows of houses in whole window bays, corner houses, wings across a court, back buildings from `CityOsm` and a seeded court fill, hôtels behind a gate, garden walls; classes core / main (mansards over stone) / rue / faubourg / post-war (hospital, bus station, a few at the edge) / ateliers (saw-tooth, by the river). About 34 000 houses, one mesh, one collision shape per îlot. Card and both rounds: `references/elements/city_blocks.md`. Left to the kits: chimney stacks and dormers (S159); no passages through the rows yet (the street plan has no covered passages); the church tower and campanile are S188 and S214. Joinville's blocks are big (180 îlots), so the courts are deep; the far LOD waits for S051's mission areas (silhouettes already work outside a detail area).

### [ ] 3.5.4 · The river
> id: S045 | needs: S040, S004, S165, S174 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_river.gd` | see: `--host --shot-cam` on a bridge

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- The river runs where Joinville's does; its banks are Paris's quays.
- [ ] 3.5.4.1 · Channel cut below street level: high stone quay walls with mooring rings, cobbled ramps (ports) and stairs down to a lower quay at the water, the quay road above with its parapet; grass banks and willows out of the centre #sound
- [ ] 3.5.4.2 · Water: one mesh, shader in code with slow flow along the river line, small ripples, dark green-brown, sky and lamp reflections as stretched streaks
- [ ] 3.5.4.3 · The bridges of S165 at the crossings of the new plan
- [ ] 3.5.4.4 · Floating things drifting with the flow: debris, a body, a sunk barge, an upturned rowing boat (S184), seeded
- [ ] 3.5.4.5 · Plane trees (S174) along the upper quay; the parapet's empty bouquinistes' boxes
- [ ] 3.5.4.6 · Water is not walkable; falling in wades the player to a ramp or stairs slowly, zombies stay out #anim
- [ ] 3.5.4.7 · Mist over the water at night
- [ ] 3.5.4.8 · Round 1 · form: the channel's width, depth, quay walls and ramps against the OSM water and the card's references of the Paris quays
- [ ] 3.5.4.9 · Round 2 · water: colour, flow, reflections, the line where water meets the wall
- [ ] 3.5.4.10 · Round 3 · night: the lamps' reflections, mist
- [ ] 3.5.4.11 · Review: the bridge shot and a view along the lower quay

### [ ] 3.5.5 · Squares and landmarks
> id: S049 | needs: S044, S047, S166, S173, S187, S188, S189, S190 | size: M | rounds: 3 | tags: #map | test: `tests/test_landmarks.gd` | see: `--host --shot-cam` on the place du marché

- Inside the mission areas first (S051, S249); the rest of the town is S259.
- Assembly of the finished landmarks, exterior only. They stand where the plan of S040 puts them (the place du marché where Praça da Bandeira is, the church near it), not on traced footprints.
- [ ] 3.5.5.1 · The place du marché: setts, the fountain (S187) in the middle, old chestnuts, lanterns (S166), benches and bins (S173), the empty market stalls, tall plastered houses with shops closing it
- [ ] 3.5.5.2 · The church (S188) on its parvis off the market
- [ ] 3.5.5.3 · The old cemetery (S189) on the slope behind the church
- [ ] 3.5.5.4 · The jardin public at the foot of the hill (S190), seen only on the lookout mission
- [ ] 3.5.5.5 · Round 1 · layout: the square's plan against old French market squares on the card (how irregular it is, how the streets enter it) #art
- [ ] 3.5.5.6 · Round 2 · style match: fixed `--shot-cam` views of the square and the church beside the card's references (old Paris engravings and photos of its surviving pre-Haussmann streets) #art
- [ ] 3.5.5.7 · Round 3 · decay: the abandoned square (litter, a fallen lantern, a car crashed into the fountain's basin) without losing the place #art
- [ ] 3.5.5.8 · Review: the style match sheet

### [ ] 3.5.6 · The market fountain
> id: S187 | needs: S141 | size: M | asset: complex | rounds: 4 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=monument`

- [ ] 3.5.6.1 · Card: photos of the Paris fountains of about 1800: a stone basin with a column or an obelisk in the middle, lion-mask spouts, a figure on top, the iron railing round it
- [ ] 3.5.6.2 · Round 1 · form: the basin's plan and rim height, the column's height and section, the steps round it
- [ ] 3.5.6.3 · Round 2 · structure: the spouts and their masks, the column's courses and capital, carved garlands and an inscription on the base, the railing
- [ ] 3.5.6.4 · Round 3 · surface: stone weathering, green streaks under the spouts, graffiti and a quarantine notice taped on, still water with leaves
- [ ] 3.5.6.5 · Round 4 · figure: the figure on top (a winged Victory) as a low-poly sculpture that reads from 10 m
- [ ] 3.5.6.6 · Review: from the square's corners and at 1 m
- Under way: family `tools/models/props/monument.py`: `market_fountain` (basin, tier with lion masks and jets, pedestal with its inscription and beasts, banded column, palm capital, globe, a blocked-out Victory) has references and round 1, built. Left: the railing, the masks and sphinxes, rounds 2 to 4 (the Victory's sculpture).

### [ ] 3.5.7 · The church
> id: S188 | needs: S141 | size: L | asset: complex | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=church`

- [ ] 3.5.7.1 · Card: photos of old Paris parish churches: a Gothic nave and apse with flying buttresses, a classical front of columns and a pediment added in the 1700s, a square bell tower (put them in `references/elements/` first)
- [ ] 3.5.7.2 · Round 1 · form: its silhouette and roof as seen from the street and from the hill; the tower is the town's landmark
- [ ] 3.5.7.3 · Round 2 · structure: the front's columns, pediment and portal, the tracery windows, the buttresses and pinnacles, the belfry's louvres, the doors and steps of the parvis #vfx
- [ ] 3.5.7.4 · Round 3 · surface: limestone gone grey and black with soot, the slate roofs, a clock face, weathering
- [ ] 3.5.7.5 · Review: beside the references at 10 m and 100 m

### [ ] 3.5.8 · The old cemetery
> id: S189 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=cemetery`

- [ ] 3.5.8.1 · Card: photos of the Paris cemeteries of the early 1800s: family chapels like little houses, obelisks, columns, iron crosses and railings round graves, cobbled alleys under trees, the gate and the wall
- [ ] 3.5.8.2 · Round 1 · form: the chapels', tombs' and stones' shapes and sizes, their rows on the slope along the alleys
- [ ] 3.5.8.3 · Round 2 · structure: carved lettering and urns, the chapels' doors and stained glass, the iron crosses' scrolls and railings, the gate's bars and posts
- [ ] 3.5.8.4 · Round 3 · surface: lichen, tilt and cracks, rust, broken chapel doors
- [ ] 3.5.8.5 · Review: an alley at 1 m and the slope at 30 m
- Under way: family `tools/models/props/cemetery.py`: `tomb_chapel` (a classical chapel with its name, cross and grilled door opening out), `tomb_cross` (cast iron on a pedestal with its plaque), `tomb_slab` (border, slab, headstone, railing), `obelisk`, `tomb_gothic` (steep roof, crockets, pinnacles on diagonal buttresses, pointed door opening out) and `cemetery_gate` (round-topped pylons with roundels and garlands as at Père-Lachaise, the lintel of wreaths, the name, wall bays, iron leaves) have round 1, built. `tomb_column` (the broken column with its drape) too. Left: the keeper's lodge, rows on the slope, rounds 2 and 3.

### [ ] 3.5.9 · Jardin public gate and pond
> id: S190 | needs: S141 | size: M | asset: simple | rounds: 3 | tags: #map #art | test: `tests/test_elements.gd` | see: `--prop-rack=park`

- [ ] 3.5.9.1 · Card: photos of French public gardens: the gilded iron gate between stone piers, a round basin with a stone rim, a bandstand (kiosque à musique), gravel paths, iron chairs (put them in `references/elements/` first); tile 1 shows where the garden lies
- [ ] 3.5.9.2 · Round 1 · form: the gate, the basin's edge, the bandstand and the ring of paths
- [ ] 3.5.9.3 · Round 2 · structure: railings, signs, the basin's rim and jet, the bandstand's columns and roof, the chairs
- [ ] 3.5.9.4 · Round 3 · surface: water plants, moss, rust, chairs tipped into the basin
- [ ] 3.5.9.5 · Review: beside the references
- Under way: family `tools/models/props/park.py`: `bandstand` (octagonal base, columns, railing, brackets, zinc roof, lantern) has references and round 1, built; so do `park_chair` (the iron garden chair), `park_basin` (a 6 m round basin, stone roll, the vasque) and `park_gate` (gilded leaves opening between stone piers with urns, the overthrow and crest). Left: the jet itself, gravel paths, a plain photo of a chair, rounds 2 and 3.

### [ ] 3.5.10 · From Joinville to the town
> id: S245 | needs: S040 | size: M | tags: #map | test: `tests/test_city_map.gd` | see: `--host`, the menu

- The game's text still names Joinville and its real places; the town becomes an invented French one in the style of Paris around 1800, on the same plan.
- [ ] 3.5.10.1 · An invented French town name, its street names (S040) and its coat of arms (one shape, used by S155, S186, S218), in `CityData`
- [ ] 3.5.10.2 · `Missions` titles and briefs in French names: the gare routière, the Hôtel-Dieu, the hôtel de ville, the caserne, the telegraph tower on the hill; mission ids (`terminal`, `hospital`, `prefeitura`, `batalhao`, `mirante`) stay as they are
- [ ] 3.5.10.3 · The menu's map: the invented names on the pins, the old core, the main streets and the quays drawn #ui
- [ ] 3.5.10.4 · `CLAUDE.md` and `TODO.md` follow: the city is described as the town, the Joinville references as its plan

### [ ] 3.5.11 · The whole town in detail
> id: S259 | needs: S258, S044, S045, S046, S047, S048, S049 | size: L | tags: #map | test: `tests/test_city_map.gd` | see: `--map=town --host`

- Not before the five areas ship. Everything outside the areas at full detail: every îlot with its facades, every street dressed, the river's whole length, the squares and landmarks.
- [ ] 3.5.11.1 · A far LOD for whatever is not near the players, streamed as they move #perf
- [ ] 3.5.11.2 · Free play and the Open World over the whole town
- [ ] 3.5.11.3 · The frame rate holds (`tools\perf.ps1 town`)

---

# 4 · State of Decay

What carries between runs: survivors who grow, a base with facilities, crafting, a community.

## 4.1 · Progression
? Do we have a progression tree: survivor skills, levels, progression outside the game?
> tags: #progression

### [ ] 4.1.1 · Progression
> id: S127 | needs: S026, S106 | size: M | tags: #progression | test: `tests/test_progression.gd`

- [ ] 4.1.1.1 · `user://profile.cfg`: missions done per difficulty, records, total kills, unlocked items #perf
- [ ] 4.1.1.2 · Finishing missions unlocks the next ones and starting loadout options (a better sidearm, a melee weapon, an attachment)
- [ ] 4.1.1.3 · Each player's own unlocks apply to themself; the host's unlock the missions
- [ ] 4.1.1.4 · Challenges: finish the hospital with melee only, the lookout without the flashlight, and the like #vfx
- [ ] 4.1.1.5 · A profile screen in the menu #perf #ui

### [ ] 4.1.2 · Survivor skills
> id: S313 | needs: S127 | size: L | tags: #progression

- [ ] 4.1.2.1 · Skills that grow by use: cardio (sprinting), fighting (melee), shooting (by gun family), wits (searching), stealth (crouch kills)
- [ ] 4.1.2.2 · Each skill's levels give small perks: faster search, steadier aim, more stamina #gameplay
- [ ] 4.1.2.3 · A specialisation at the top of each, chosen once
- [ ] 4.1.2.4 · Saved per survivor in the profile; the host checks the numbers #net

### [ ] 4.1.3 · Levels and meta progression
> id: S314 | needs: S127 | size: M | tags: #progression

- [ ] 4.1.3.1 · Experience from runs (kills, objectives, rescues) into a player level
- [ ] 4.1.3.2 · Levels unlock starting kits, survivors, cosmetic outfits and modifiers (S128)
- [ ] 4.1.3.3 · A profile screen with the tree and records #ui

### [ ] 4.1.4 · Daily modifiers
> id: S128 | needs: S027, S110 | size: S | tags: #progression | test: `tests/test_modifiers.gd`

- [ ] 4.1.4.1 · Modifiers as small rule sets: all runners, low ammo, night only, thick fog, storm, no HUD, one life, exploding heads #vfx #ui
- [ ] 4.1.4.2 · A daily pick seeded from the date, shown on the menu; the host can also pick by hand #ui
- [ ] 4.1.4.3 · Sent in `welcome` #net

### [ ] 4.1.5 · Killcam and replays
> id: S131 | needs: S126 | size: L | tags: #progression | test: `tests/test_replay.gd`

- [ ] 4.1.5.1 · The host records the snapshot stream and events of the last 15 s in a ring #net
- [ ] 4.1.5.2 · On a player's death or at the end: replay the final moments from a cinematic camera, slowed at the kill
- [ ] 4.1.5.3 · End screen highlight: the biggest multi-kill of the match #ui
- [ ] 4.1.5.4 · Free camera and photo mode in solo: pause, fly, hide the HUD, save a PNG #ui

## 4.2 · Base, crafting stations and loot structure
? Do we have a base system, crafting stations and a loot structure that matters?
> tags: #base

### [ ] 4.2.1 · The base
> id: S315 | needs: S310, S127 | size: L | tags: #base

- [ ] 4.2.1.1 · Claim a large building (the school, a warehouse, the barracks) as the community's base between runs #map
- [ ] 4.2.1.2 · Facility slots: workshop, infirmary, kitchen, storage, watchtower, garden, beds
- [ ] 4.2.1.3 · Building and upgrading a facility costs materials and time; upgrades show on the model #art
- [ ] 4.2.1.4 · Sieges: a horde comes for the base now and then #ai #gameplay

### [ ] 4.2.2 · Crafting stations
> id: S316 | needs: S315, S312 | size: L | tags: #base

- [ ] 4.2.2.1 · Workshop: repair guns and melee, make attachments and ammo #weapon
- [ ] 4.2.2.2 · Infirmary: medkits, painkillers, treat infection
- [ ] 4.2.2.3 · Kitchen: meals that buff a run; garden grows food
- [ ] 4.2.2.4 · Each recipe needs a station level and a skill (S313) #progression

### [ ] 4.2.3 · A loot structure that matters
> id: S317 | needs: S315 | size: M | tags: #loot #base

- [ ] 4.2.3.1 · Resource rucksacks (food, medicine, materials, ammunition, fuel) carried back to the base
- [ ] 4.2.3.2 · The base consumes them daily; shortages hurt morale (S318) #gameplay
- [ ] 4.2.3.3 · Rare finds: blueprints that unlock recipes #progression

### [ ] 4.2.4 · Outposts
> id: S318 | needs: S315 | size: M | tags: #base

- [ ] 4.2.4.1 · Claim smaller buildings as outposts: safe respawn, a little storage, they reveal the area round them #map
- [ ] 4.2.4.2 · Each costs influence to hold

## 4.3 · Community
? Do we have survivors with traits, morale and stories?
> tags: #ai #progression

### [ ] 4.3.1 · Companion survivors
> id: S129 | needs: S038, S016 | size: L | tags: #ai #progression | test: `tests/test_companion.gd`

- [ ] 4.3.1.1 · AI teammates fill empty slots when the host wants them
- [ ] 4.3.1.2 · They follow, keep spacing, shoot what threatens, reload behind cover, revive and heal players
- [ ] 4.3.1.3 · They never take the last ammo or medkit, never block doorways
- [ ] 4.3.1.4 · Ping commands: go there, hold here, follow
- [ ] 4.3.1.5 · Built on the bot from S008, same rig and animations as players #anim

### [ ] 4.3.2 · Survivors with traits
> id: S319 | needs: S129, S315 | size: L | tags: #progression #ai

- [ ] 4.3.2.1 · Each survivor has traits (strong, cowardly, medic, insomniac) that change numbers and dialogue
- [ ] 4.3.2.2 · Morale from food, losses and beds; low morale makes survivors leave or fight #gameplay
- [ ] 4.3.2.3 · Permadeath for survivors; switch to another between runs

### [ ] 4.3.3 · Radio requests
> id: S320 | needs: S315, S051 | size: M | tags: #gameplay #ai #progression

- [ ] 4.3.3.1 · The base's radio offers jobs: rescue a survivor, clear an infestation, fetch medicine
- [ ] 4.3.3.2 · Jobs become small missions on an area's map data #map

## 4.4 · Vehicles
? Can the group drive, carry loot in a boot and run down the dead?
> tags: #gameplay

### [ ] 4.4.1 · Vehicles
> id: S130 | needs: S057 | size: L | tags: #gameplay | test: `tests/test_vehicle.gd`

- [ ] 4.4.1.1 · One drivable pickup truck for the terminal run as an optional route #loot
- [ ] 4.4.1.2 · Host simulates it; the driver sends input; passengers ride in the bed and shoot #net
- [ ] 4.4.1.3 · Runs zombies down with ragdoll hits and blood on the bonnet, slows through crowds #vfx
- [ ] 4.4.1.4 · Fuel and damage: smoke, then fire, then it stops #vfx
- [ ] 4.4.1.5 · Engine noise draws everything (S020) #perf #sound
- [ ] 4.4.1.6 · Body roll, suspension bounce, headlights, brake lights, wheels that steer and spin #ui

### [ ] 4.4.2 · Vehicle storage and fuel
> id: S321 | needs: S130, S315 | size: S | tags: #gameplay

- [ ] 4.4.2.1 · The boot holds rucksacks and items between the area and the base #loot #base
- [ ] 4.4.2.2 · Fuel as loot, siphoned from wrecks #loot
- [ ] 4.4.2.3 · Repairs at the workshop (S316) #base

---

# 5 · Ship it

Menus, lobby and LAN, the balance and performance passes, a build for friends.

## 5.1 · Menus
? Do the menus, lobby and loading work for friends?
> tags: #ui

### [ ] 5.1.1 · Settings menu
> id: S119 | needs: S006 | size: M | tags: #ui | test: `tests/test_menu_settings.gd` | see: `--menu=settings --screenshot`

- [ ] 5.1.1.1 · Tabs: Game, Controls, Video, Audio #sound
- [ ] 5.1.1.2 · Sliders with live preview: sensitivity, FOV, volumes, HUD scale, shake, gore amount
- [ ] 5.1.1.3 · Key rebinding: click, press a key, conflicts shown, reset to default #sound
- [ ] 5.1.1.4 · Graphics tier, fps cap, vsync, window mode, show draws #perf
- [ ] 5.1.1.5 · Same panel reachable from the main menu and the pause menu
- [ ] 5.1.1.6 · Menu motion: panels slide and fade, the hovered row glows, values tick #vfx

### [ ] 5.1.2 · Pause menu
> id: S120 | needs: S119 | size: S | tags: #ui | test: `tests/test_pause.gd`

- [ ] 5.1.2.1 · Resume, Settings, Leave match
- [ ] 5.1.2.2 · The world keeps running in multiplayer; the player is marked as paused over their head
- [ ] 5.1.2.3 · Solo offline pauses the world
- [ ] 5.1.2.4 · Background blurs and darkens, the game sound is low-passed #sound

### [ ] 5.1.3 · Mission select
> id: S121 | needs: S026, S027 | size: M | tags: #ui | test: `tests/test_menu.gd` | see: `--mission=hospital --screenshot`

- [ ] 5.1.3.1 · On the city map: the picked pin opens a card with the brief, kind, difficulty skulls, best time and best score
- [ ] 5.1.3.2 · Difficulty picker
- [ ] 5.1.3.3 · The route or area of the mission drawn on the map when picked, camera eases toward it
- [ ] 5.1.3.4 · Pins pulse; completed missions get a tick, locked ones a padlock (S127)
- [ ] 5.1.3.5 · Time of day and weather shown as icons

### [ ] 5.1.4 · Lobby
> id: S122 | needs: S121, S243 | size: L | tags: #ui | test: `tests/test_lobby.gd` | see: `tools\play2.ps1`

- [ ] 5.1.4.1 · Host opens a lobby instead of starting at once; LAN discovery lists it with mission, players and difficulty
- [ ] 5.1.4.2 · Player list with names, ready ticks, ping
- [ ] 5.1.4.3 · Host picks mission and difficulty, everyone sees the map move
- [ ] 5.1.4.4 · Survivor look picker (the four outfits, colour)
- [ ] 5.1.4.5 · Start when all are ready, or host forces; a countdown
- [ ] 5.1.4.6 · After a mission everyone returns to the lobby together
- [ ] 5.1.4.7 · Join by IP stays as a fallback

### [ ] 5.1.5 · Loading screen
> id: S123 | needs: S051 | size: S | tags: #ui | test: `tests/test_loading.gd`

- [ ] 5.1.5.1 · Mission title, the POI's sketch, a tip that changes
- [ ] 5.1.5.2 · The map builds across frames with a progress bar instead of one long freeze
- [ ] 5.1.5.3 · Everyone starts together when the slowest peer is ready #net
- [ ] 5.1.5.4 · Fade from the loading screen into the first view

## 5.2 · LAN
? Does LAN play hold up: pings, chat, joining late, stress?
> tags: #net

### [ ] 5.2.1 · Pings, chat, scoreboard
> id: S124 | needs: S036 | size: M | tags: #net #ui | test: `tests/test_social.gd`

- [ ] 5.2.1.1 · Ping key: a marker where the player looks, contextual (go here, zombie, loot, special spotted), with a sound and the player's colour #sound #loot
- [ ] 5.2.1.2 · Text chat with a short history, usable while dead
- [ ] 5.2.1.3 · Scoreboard on a held key: kills, headshots, revives, ping
- [ ] 5.2.1.4 · Kill feed with weapon icons, headshot and sever marks
- [ ] 5.2.1.5 · Emote wheel with a few hand signals on the rig (point, wave, stop) #anim

### [ ] 5.2.2 · Joining late and leaving
> id: S125 | needs: S021, S122 | size: M | tags: #net | test: `tests/test_late_join.gd` | see: `tools\play2.ps1`

- [ ] 5.2.2.1 · A late joiner gets everything in `welcome`: mission state, breakables, barricades, fires, dropped guns, inventory defaults
- [ ] 5.2.2.2 · They spawn at the last checkpoint or beside a teammate out of sight of zombies
- [ ] 5.2.2.3 · A leaving player's body drops their backpack; the horde scales down
- [ ] 5.2.2.4 · Host quits: clients get a clear message and return to the menu #ui
- [ ] 5.2.2.5 · Short network hiccups: the client keeps going and catches up without a snap
- [ ] 5.2.2.6 · Reconnect within a minute gives the player their state back

### [ ] 5.2.3 · Net stress
> id: S126 | needs: S070, S125 | size: M | tags: #net | test: `tests/test_net_stress.gd`

- [ ] 5.2.3.1 · Headless harness: one host and seven fake clients on localhost, a full horde, 60 s
- [ ] 5.2.3.2 · Asserts: every packet under the limit, bytes per second per client under a budget, no reliable-queue growth #perf
- [ ] 5.2.3.3 · Simulated loss and delay: the game stays playable at 5 % loss and 80 ms
- [ ] 5.2.3.4 · Remote zombies and players stay smooth (interpolation checked numerically)
- [ ] 5.2.3.5 · Player cap decided from the results and written in `Config` #perf

## 5.3 · Release
? Is it balanced, fast and in a build friends can run?
> tags: #tool

### [ ] 5.3.1 · Balance pass
> id: S132 | needs: S007, S060, S062, S065, S068 | size: L | tags: #tool | test: `tools\test.ps1 balance`

- [ ] 5.3.1.1 · Balance sheet reviewed gun by gun and zombie by zombie, every outlier fixed in `weapons.gd` and `Config`
- [ ] 5.3.1.2 · Each mission played by the bot on each difficulty: finish rates and times in a table in `references/balance.md`
- [ ] 5.3.1.3 · Ammo and healing economy per mission: found against spent
- [ ] 5.3.1.4 · Mission lengths in the target range (15 to 25 minutes)
- [ ] 5.3.1.5 · Notes from human playtests turned into numbers

### [ ] 5.3.2 · Windows build for friends
> id: S134 | needs: S122 | size: M | tags: #tool | test: `tools\build.ps1` then run the exe with `--quit-after=5`

- [ ] 5.3.2.1 · `tools\build.ps1` exports a release folder and a zip, version stamped from git
- [ ] 5.3.2.2 · First run: asks for a name, picks a tier, shows the LAN address to tell friends #perf
- [ ] 5.3.2.3 · Firewall prompt explained on the host screen; port in settings #ui
- [ ] 5.3.2.4 · Version check on join (S070)
- [ ] 5.3.2.5 · `README.md`: how to host, how to join, controls, troubleshooting
- [ ] 5.3.2.6 · Crash log written to `user://` with the last hooks fired

### [ ] 5.3.3 · Versions, crash logs and patch notes
> id: S322 | needs: S134 | size: S | tags: #tool

- [ ] 5.3.3.1 · A version string in the menu and in `welcome`; peers on different versions are told #net #ui
- [ ] 5.3.3.2 · Crash and error logs written to `user://logs`, a button to open the folder
- [ ] 5.3.3.3 · Patch notes from the dashboard's ticked items since the last build

### [ ] 5.3.4 · LAN night
> id: S135 | needs: S132, S133, S134 | size: M | tags: #tool | test: whole suite | see: `tools\shots.ps1`

- [ ] 5.3.4.1 · A checklist played start to finish on two real machines: lobby, each of the five missions, a late join, a disconnect, a failure and a win #net #ui
- [ ] 5.3.4.2 · Every rough edge found becomes a test and a fix, or a new step appended to this file
- [ ] 5.3.4.3 · Credits and a thank-you screen after the fifth mission #ui
- [ ] 5.3.4.4 · `TODO.md`, `CLAUDE.md` and this file agree with the game
