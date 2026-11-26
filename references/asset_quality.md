# Asset quality: the bar and the workflow

Every model in the game is built in code. This page is how to take one from "boxes" to the level of
the art references in `references/quality/`, and the list of what has been done and what is left.
The Mirante (the gate, the road up, the summit, its forest) is the first place that went through it;
use it as the worked example (`scripts/world/mirante_set.gd`, `scripts/world/vegetation.gd`).

It is about the **level of quality**, not the subjects: no bakeries or pumpkins, but the same care.

## The bar: what the references do

| Reference | What to take from it |
|---|---|
| `ref_bakery.png` | Every edge bevelled and catching light. A building is never one box: plinth, wall, a band of brick, a cornice, a parapet, an awning with stripes, frames round every window and door, a sill. Small life on it: a lamp, a sign, a vent, a pipe, a planter with plants. |
| `ref_coffee_shop.png` | The same on a plainer building: the value of trims and bands, a signboard, a balcony rail, the AC unit and the pipe down the corner, a bin and a bollard on the pavement, a board on the ground. Grounding: it stands on a kerbed slab. |
| `ref_kitchen.png` | Density of believable small things; every object is turned or rounded (pots, jars, bowls), soft contact shadows where things touch, warm light pooling inside a cool scene, foliage in chunky rounded leaves. |
| `ref_kitchen_close.png` | Up close the shapes still hold: smooth rounded caps, curved stems, leaves with thickness, materials that read (glossy, matte, metal). |

Turned into rules:

1. **No raw cube edges.** Everything is bevelled (`rbox`) or turned (`lathe`, `rcyl`). The bevel catches a highlight; that one change does most of the work.
2. **Three layers of detail.** Primary mass (the wall, the trunk) → secondary forms that frame it (plinth, cornice, bands, frames, fascia, drip edges, kerbs) → tertiary things that tell you what it is and what happened (handles, lamps, pipes, vents, signs, pots, a tipped chair).
3. **Grounded.** Every object sits on something (a plinth, a kerb, a collar, a foot) and is darker at its foot (the kit does this, and SSAO adds contact shadows).
4. **Materials read.** Glass is glossy, metal is metal, paint has a soft highlight, brick, tile and pavers show their joints, bark has grain, leaves let light through.
5. **Colour with intent.** Neutral masses, a few saturated accents (an awning, a sign, flowers). No two neighbouring parts in exactly the same tone: trims are a step lighter or darker (`lightened` / `darkened` 0.08–0.2).
6. **Organic things are organic.** Foliage is lumpy rounded clumps (`blob`), branches, cables and fronds curve (`tube` along `arc` / `sag`).
7. **Warm light against cool night.** A few warm lamps (`Config.LOOK_LAMP_WARM`) that bloom, pools of light where people were.

## The toolkit

All in `scripts/models/mesh_kit.gd`. Every shape goes into a `MeshKit.Builder`, so a whole map is still
one mesh per builder (one draw call).

| Call | Use it for | Cost (triangles) |
|---|---|---|
| `b.rbox(size, pos, color, r, rot, xf)` | anything boxy: walls, slabs, trims, furniture, car bodies. `r` = bevel radius, -1 = `b.bevel` (4.5 cm), capped at 2/3 of the thinnest half-side | 44 (a `box` is 12) |
| `b.lathe(profile, pos, color, segments, rot, xf, squash)` | anything turned: pots, bottles, lamps, insulators, cones, dishes, tanks, bushings. `profile` is (radius, y) from bottom to top; normals are smoothed along it. `squash` stretches it into an oval (lamp heads) | 2 × segments × points |
| `b.rcyl(radius, height, pos, color, segments, r, rot, xf)` | posts, tyres, hubs, bollards, cans, tabletops, pipes' clamps | ~6 × segments |
| `b.taper(r0, r1, height, pos, ...)` | cones, tapered posts, chair legs | ~4 × segments |
| `b.frustum(bottom, top, height, pos, color, rot, xf, shift)` | flat-faced boxes that narrow upward: buttresses, plinths, hoppers, wedges | 12 |
| `b.blob(radii, pos, color, key, lump, rings, segments, rot, xf, flat)` | tree crowns, bushes, flowers, sandbags, rocks, scallops. `key` picks the dents (same key, same shape on every peer); `flat` cuts its foot flat | ~2 × rings × segments |
| `b.tube(points, radius, color, sides, radius_end, xf, caps)` | cables, pipes, hand rails, branches, fronds' midribs, legs | 2 × sides per segment |
| `MeshKit.sag(a, b, droop)`, `MeshKit.arc(a, bend, b)` | the points for a hanging cable, a curved branch or arm | – |
| `MeshKit.hash01(key, i, j)` | a 0..1 number for looks without an rng (never `randf`) | – |

Builder knobs: `b.shade` (0.22: how much darker the foot of a kit shape is than its top: fake
ambient occlusion), `b.edge_light` (0.07: bevels a touch lighter: edge wear), `b.bevel` (default radius).

**Surface classes** ride in a colour's alpha; the shared world shader (`MeshKit.WORLD_SHADER`) reads
them. Plain colours (alpha 1) are matte, so old code looks as before plus a little grain and rim light.

| Class | Alpha | Hex suffix | Looks like |
|---|---|---|---|
| `MATTE` | 1.0 | (none) | concrete, plaster, cloth, wood |
| `PAVERS` | 0.9 | `e6` | 24 × 12 cm pavers in a basket weave (ground) |
| `PAINT` | 0.8 | `cc` | car paint, enamel, plastic, signs: soft highlight |
| `BRICK` | 0.7 | `b3` | running-bond brick with mortar, any face |
| `METAL` | 0.6 | `99` | galvanised steel, chrome, brass |
| `TILE` | 0.5 | `80` | 30 cm square tiles with grout, glossy |
| `GLASS` | 0.4 | `66` | windows, screens, lenses: sharp reflections |
| `BARK` | 0.3 | `4d` | bark and rough wood: vertical grain |
| `LEAF` | 0.2 | `33` | leaves, petals: light comes through |
| `SOOT` | 0.1 | `1a` | rubber, tar, burnt things |

Write `Color("16212b66")` in a constant, or `MeshKit.surf(color, MeshKit.GLASS)` in code. `darkened` and
`lightened` keep the class. **A Label3D's colour must keep alpha 1** (or the text goes see-through):
tag the box, not the shared constant (see `MiranteSet.SIGN_GREEN`).

**Shared details** (in `MiranteSet` for now; move them to their own kit when a second map needs
them): `window` (glass, frame, mullion, sill), `door` (leaf with panels, frame, handle), `ac_unit`,
`downpipe`, `potted` (pot with a shrub), `planter` (a long box of shrubs). `Vegetation.shrub` draws a
small flowering shrub without an rng.

**The look**: `Game._apply_tier_look` turns on SSAO (contact shadows), glow (lamps bloom) and a
touch of contrast and saturation from the medium graphics tier up, SSIL on high; the numbers are
`Config.LOOK_*`.

`Props.bx`, `RoadProps.bx` and `MiranteSet.bx` all draw `rbox` now, so every prop is bevelled
already; wheels are round (`Props._wheels`), cones and barrels turned. That is the free part. The
rest of the pass below is per asset.

## The workflow, one asset at a time

1. **Shoot it before.** `tools\shots.ps1 <filter>` or a fixed camera:
   `tools\godot.ps1 -- --host --mission=<poi> --no-hordes --shot-cam=x,y,z,yaw,pitch --screenshot=<path>.png --shot-at=2.2 --quit-after=3`.
   Put the picture next to a reference and write down the three biggest gaps.
2. **Silhouette.** Is the outline right from 10 m and from 1 m? Round things become `lathe` /
   `rcyl` / `taper`; organic things `blob` and `tube`; anything that hangs or bends follows `sag` / `arc`.
3. **Bevel.** Every `box` becomes `rbox`. Radius by scale: 0.5–1.5 cm for small hand-sized things,
   2–4 cm for furniture, trims and vehicles' panels, 5–8 cm for walls, pillars and slabs.
4. **Secondary forms.** Add what frames the mass: a plinth or foot, a cap or cornice, bands at floor
   lines, frames and sills on openings, fascia on roof edges, a drip edge under slabs and landings,
   kerbs round paving, stringers under stairs.
5. **Tertiary detail.** Three to eight small believable things per object (handles, hinges, bolts,
   lamps, pipes, vents, AC units, signs, number plates, pots, things left behind), at least one
   that tells a story (a chair knocked over, a lamp still on, a shutter half down).
6. **Materials.** Tag every colour with its surface class (table above).
7. **Colour.** Trims a step off the wall colour, one saturated accent per object, petals and flowers
   to break up the green, no pure black or white.
8. **Light.** Does it own a light? A small emissive box in the map's glow builder, and an
   `OmniLight3D` only where it matters (they count against `Config.BUDGET`, raise it on purpose).
9. **Shoot it after**, same camera, and compare with the before and the reference. Fix what still reads
   as a box.
10. **Keep it working.** Same function, same colliders unless the shape really changed (visual detail
    needs no collider), deterministic (the map's rng or `hash01`, never `randf`), run the tests
    (`tools\test.ps1`), tick it below.

What it costs: a bevelled box is ~3.7× a box, a tree went from ~100 to ~600–900 triangles. That is
accepted for now; the performance pass comes later (see the end).

## Inventory

Legend: [x] through the workflow · [~] got the free part (bevels, round wheels, surface classes) but
not its own pass · [ ] not started.

### Mirante (the worked example)
- [x] Gate: plinths, grooves and bands on the pillars, a corniced sign beam with a framed panel, the butterfly roof with fascia, soffit, downlights, valley gutter and downpipe, planters of hibiscus and bougainvillea, kerbs
- [x] Guard hut: plinth, skirting, framed windows with sills, panelled door, brown roof band, AC unit, lamp over the door (lit), a potted hibiscus
- [x] Boom (round, striped, counterweight), PARE board on an A-frame with an octagon sign, cones
- [x] Power poles: collar, step bolts, number plate, braced crossarm, porcelain insulators, strapped cable bundles, splice box, transformer with fins, lid and bushings, curved lamp arm and cobra head; cables sag as round tubes
- [x] Guard rails: posts with spacer blocks and amber reflectors, W-beam with its two ribs, bolts
- [x] Lookout tower: pilasters and bands on the lift shaft, framed lift door with a lit call button, column plinths and caps, landing drip edges, stair stringers, treads with dark nosings, round hand rails on posts, deck fascia with a drip groove, grating cross bars, three-rail round railing, a corniced lift head with louvres and a mast, coin binoculars, two potted plants
- [x] Snack bar: plinth, tiled band, ribbed half-down shutter, counter with a tiled front, things left on it, striped awning with a scalloped valance on brackets, a sign box with LANCHONETE and two lit lamps, a menu board, a drinks cooler, a gas bottle, an AC unit, a downpipe, a back door, tables and chairs (one knocked over), a bin, a pot
- [x] Toilets: plinth, tiled band, framed doors with pictogram plates, framed high windows, louvred vents, fascia, downpipes, a drinking fountain
- [x] Radio masts: round banded legs with footings, round bracing and diagonals, dishes, panel antennas, the warning lamp, an equipment shelter with door, AC unit and cable tray
- [x] Trees: flared roots, curved trunks and limbs into lumpy crowns with sunlit tufts; palms with ringed trunks, crownshafts and arching pinnate fronds; araucárias with curved limbs and needle pads; tree ferns with shaggy trunks and arching fronds; bushes as lumpy clumps with round flowers
- [x] Road: grey pavers in a basket weave, red brick lane in running bond (shader patterns on the existing colours)
- [~] Road scatter (cars, minibus, bikes, benches, bins, bags): bevelled and glossy paint, round wheels; still needs its own pass (door panel lines, mirrors, number plates, seats, lights in lenses)
- [ ] Forest floor (undergrowth, ferns, fallen leaves, roots), lianas, the canopy closing over the road
- [ ] A photo of the real tower in `references/` and a pass against it

### Everything else
- [~] `scripts/world/props.gd`: vehicles, barriers, tents, crates (free part only)
- [~] `scripts/world/road_props.gd`: everyday cars and street things (free part only)
- [ ] `scripts/world/city_map.gd` `_buildings`: the city blocks are still plain boxes drawn with `box` (facades need plinths, floor bands, window grids with frames, shopfronts with awnings and signs, roof clutter)
- [x] Prefeitura (`scripts/world/prefeitura_set.gd`): brick piers, upturned concrete bands with coping, drip grooves and rain streaks, framed glazing with mullions and transoms, pink plaster ground floor with framed windows and sills, blue space frames (front and back grids, X bracing, struts, node plates), brick buttresses (`frustum`), ribbed metal roof with a ridge cap, brick roof towers with bands, louvres and masts, condensers, a turbine vent, AC units, planters spilling over the first band, canopy on round columns with downlights, flags, lamp posts, the lawn sign in its space frame, flower beds, ramp rails, the pad with its ring, H and rim lights. List: `references/prefeitura_elements.md`
- [x] Hospital Dona Helena (`scripts/world/hospital_set.gd`): tower in three bodies, bay canopy, old wing with fins, annex, house, fire stair, helipad, triage scatter (`references/hospital_elements.md`)
- [x] Terminal Central (`scripts/world/terminal_set.gd`): concrete roof slabs with haunches and streaked fascias, the skylight lantern with clerestory and trusses, steel tree columns, three islands with yellow kerbs, barriers, benches, bins, stop signs and clock, the ticket hall and shops with the sign, seven yellow buses (one crashed, one burnt). List: `references/terminal_elements.md`
- [ ] The batalhão: placeholder; element list in `references/batalhao_elements.md`
- [ ] `scripts/world/scenery.gd`: shelter building, facades, checkpoint, gun pits, motor pool
- [ ] `scripts/world/corridor_map.gd` (the test corridor)
- [ ] Interactables: `door.gd`, `lootbox.gd`, `ammo_box.gd`, `ammo_crate.gd`, `weapon_pickup.gd`, `checkpoint_look.gd`
- [ ] `scripts/models/guns.gd`: has its own material (alpha = metallic); bevels and turned barrels would help most
- [ ] `scripts/models/characters.gd` / `humanoid.gd`: survivors and zombie outfits. Careful: one mesh per body part, gore cuts at the joints
- [ ] `scripts/fx/helicopter.gd` (uses `Props.transport_helicopter`)
- [ ] The menu's city picture (2D, separate)

## Later: the performance pass

Not now, but this is what will pay for the detail: trees as a few shared meshes in `MultiMeshInstance3D`
(per species and seed) instead of baked into one huge mesh; a far version of each kit shape (`rbox`
falls back to `box`, `blob` with fewer rings) chosen by distance or graphics tier; visibility ranges
on the tertiary details; and the city's `_trees` builder split by area so the GPU can cull it.
`tools\perf.ps1` measures it.
