# zombie_bites — ten bite variants of every zombie outfit model

Family: `tools/models/bites.py` (geometry, numpy) + `tools/models/outfits.py --bitten` (Blender: UVs, rig, .glb) · game: `Characters.BITES`, `Characters.bite_for`, `CharacterModel.outfit(name, female, bite)` · sketch (no Blender): `python tools/models/outfits.py --bites nurse --f` · rack: `--host --outfit-rack=1 --bite=N`

This is a model-variant step, not a prop: no registry entry in `elements.gd`, so `tests/test_elements.gd` does not read this card; `tests/test_bite_variants.gd` holds the rules below.

## References
Real wound photographs were **not** collected: the game is stylised and the only art reference the project has for zombies is `references/zombies.png` (the PolyGon city zombies: grey skin, torn clothes, blood on cloth and skin, open wounds drawn as dark red patches). The bones come from the project's own anatomy: `tools/models/skeleton.py` (which is fitted inside the male body and sets where ribs, humerus, radius, ulna, femur, tibia, cervical vertebrae lie). That is a limit of this step, written down on purpose: the shapes of the tears are made by taste against `zombies.png`, not copied from photos of injuries.

| file | what it shows | source | licence |
|---|---|---|---|
| `references/zombies.png` | the target look: blood-soaked cloth, dark red wounds, grey skin | project reference (given) | — |
| `references/shots/sketch_body.png`, `sketch_outfit_*.png` | the bodies and clothes the bites are cut from | made by the project | — |

## Measurements
Taken against the models themselves (a 1.75-1.9 m zombie, forearm radius ≈ 4.5 cm, thigh ≈ 8 cm, torso depth ≈ 20 cm).

- size (m): 0.10 x 0.13 x 0.05 for an abdomen / ribs bite, 0.08 x 0.12 x 0.04 on a forearm or calf (the ragged ellipsoid's half sizes are `BITES[..].r`)
- depth of the pit: 3 cm (forearm, neck) to 6.5 cm (abdomen), never more than half the thickness of the piece it is cut in
- the torn edge's teeth: ≈ 2-3 cm (the triangles near a bite are split down to 3 cm)
- bones: rib 2.4 x 1.6 cm in section, humerus 2.6 cm, radius 1.7 cm, ulna 1.5 cm, femur 3.8 cm, tibia 2.6 cm, fibula 1.5 cm, a vertebra 2.4 cm

## Visible details
- [x] M a ragged opening in clothes and flesh together (never a clean ellipse: five harmonics swing the edge)
- [x] M a pit: rim, wall ring, floor ring, floor point, jittered, so the opening is never see-through
- [x] M only the region's bones: ribs (3), ribs + collarbone-ish strip (chest), a floating rib (abdomen_l), a humeral head and collar strip (shoulder), humerus, radius + ulna, femur, tibia + fibula, three vertebrae
- [x] B cloth and skin touching the rim soaked dark (the small triangles round the opening take a dark blood texel)
- [x] M every rigid piece the hole reaches gets its own pit, so a gib or stump of it stays closed
- [ ] flaps of torn cloth hanging over the rim (not done: the cloth is only cut)
- [ ] blood running down from the bite on the cloth below (that is S237)
- [ ] intestines / organs in the abdomen pits (not done)

## Materials
No texture of its own: every face maps to the outfit's albedo/emission maps (kept faces by their parent's UV corners, new faces to single texels picked from the painted wound / bone texels well inside an island).

| tag | coat | under | bare | wear |
|---|---|---|---|---|
| rim | darkest 5-40 % of the wound texels | — | — | torn edge, blood-dark |
| flesh | brightest 70-97 % of the wound texels | — | — | raw wall of the pit |
| deep | darkest 12 % of the wound texels | — | — | the floor |
| bone | bone texels (teeth where a model has none) | — | — | pale |
| soak | = rim | the outfit's own colour | — | cloth round the opening |

## Budget
Plain outfit models are 2700-2900 triangles. A bite adds the pit (≈ 250-350 triangles with its rim) and the split triangles round it.

| variant | triangles (max) | draws | texture memory |
|---|---|---|---|
| plain outfit | 2900 | 1 | 1 albedo + 1 emission |
| any bite of it | plain + 1400 (< 5000) | 1 | shared with the plain model (same texture objects) |

Disk: one small .glb per variant (≈ 0.3-0.4 MB), 180 of them.

## Moving parts
Same joints and helpers as the plain model: the pit's points ride the weights of the rim point they hang from, the bones one rim point's weights (rigid). Severed limbs take their pit with them (`tests/test_bite_variants.gd`).

## States
Walkers only (the leaper stays feral, corpses stay round bodies).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/shots/bites_nurse_f.png` (flat-shaded: top rows close up from outside, from the side so the pit's depth shows, wide for scale; no Blender)
Differences from the references (first pass):
- the first sheet read as a starburst: the floor fan of needle triangles with random wall / floor colours looked like a firework, not flesh
- the soaked rim swallowed whole 8 cm cloth quads (half a sleeve, a collar) because big triangles touching the rim were all marked
- the floor is a smooth bowl; `zombies.png` wounds are rough, dark and torn
- the abdomen, ribs and shoulder bites were reaching the arms' and the pelvis' pieces as well (correct: each gets a pit) but made the sheet look cluttered
Fixed:
- crater bands keep their own colour (rim / flesh / deep), only one face in six varies
- soak only marks triangles smaller than 4.5 cm whose middle is within 2.2 cm of the rim: a narrow ragged band
- refinement region and the triangle size reduced so a bite costs ≈ 400-1100 triangles, not 2400
Left: the pit's walls are flat-coloured facets; the edge still shows a stair-step pattern where the triangles were split along axes.

## Round 2 — structure (the secondary forms)
Sheets: `references/shots/bites_nurse_f.png` (flat sketch, redrawn) and `references/shots/bites_nurse_f_game.png` (the game's own render, `--host --bite-rack=1|2 --outfit=nurse`, front and back, two groups of six)
Differences (read in the game, 1.3 m figures at 3 m):
- the bites are small at that distance and low contrast against the baked blood splats of the outfit texture: only the abdomen, ribs, chest, thigh and calf ones read at once; the shoulder and forearm ones read as a dark strip
- the neck bite is on the figure's left side and cannot be seen from the front
- the in-game pit is dark maroon: the wall and floor swatches were too close in value
- the forearm and calf pits were only 1.6-1.8 cm deeper than the surface (the test asked for 2 cm and failed); the shoulder bite never reaches the arm's piece (the arm starts under the armpit) so its humeral head knob was never placed
Fixed:
- limb pits deeper (forearm 3 -> 4.2 cm, calf 3.6 -> 4.6 cm); the test passes for every outfit, body and bite it casts
- the wall swatch takes the brightest 18 % of the wound texels, the rim the darkest 30 %
- the shoulder's knob goes in the torso's pit, where the bite is

## Round 3 — surface (wear, colour variation, states)
Differences:
- the pit's faces are flat texels, one per face: no baked ambient occlusion in the cavity, so depth is only read from the real-time light
- no torn flaps of cloth, no blood running down from the bite (S237 owns blood placement), no organs in the abdomen pits
- every zombie that wears the same bite and outfit has the same hole (ten per outfit and body)
Fixed: nothing in this round; each item above is accepted as left over (see the review).

## Review
Accepted as left over, with reasons:
- *Real wound photographs were not collected* (card References): the reference is `references/zombies.png` and the project's own skeleton. The tear shapes are by taste, not copied.
- *Clothes swaps per variant (sleeve length, open or closed, hat or none, colour sets)* is **not done** and stays unticked in `STEPS.md`: a swap needs its own geometry and its own texture, which breaks the shared-texture budget this step set; it is its own step.
- The contact sheet of every bone, clothes and body variant of the female nurse: the bites and their bones are shown (`bites_nurse_f_game.png`); clothes variants do not exist yet, so the sheet is ticked off only as far as that.
- The round-1 star-shaped fan of the pit's floor remains: the floor is a fan to one point.
