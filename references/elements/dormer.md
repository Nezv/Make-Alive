# dormer — the zinc dormer of a Paris mansard (S159)

Family: `tools/models/props/roofs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py dormer` · sketch: `python tools/models/props.py dormer --sketch` · match: `python tools/models/match.py dormer --round=N` · rack: `--prop-rack=dormer` · review: `python tools/models/review.py dormer --round=N`

The lucarne of the mansard roofs on the main streets (S043's `main` class): a casement down to the floor behind a little railing on the gutter's ledge, zinc-clad jambs and lintel, skirts flaring out at the foot, cheeks running back to the mansard's steep slope (72°), a small hipped zinc cap with roll joints. The house sets it on the slope; the cheeks and the room behind are hidden in the roof.

## References
Wikimedia Commons, `references/elements/dormer/`. Matched: zinc_row.

| file | what it shows | source | licence |
|---|---|---|---|
| `zinc_row.jpg` | **the main reference**: four zinc dormers in a slate mansard, from above: caps, flared skirts, railings, the gutter ledge | [Dormer windows in Paris, 26 September 2011](https://commons.wikimedia.org/wiki/File:Dormer_windows_in_Paris,_September_26,_2011.jpg), Jorge Andrade | CC BY 2.0 |
| `slate_pediments.jpg` | slate mansard dormers with zinc pediments and awnings on a corner house, from the street | [32 rue de la Roquette](https://commons.wikimedia.org/wiki/File:32_rue_de_la_Roquette,_Paris_March_2011.jpg), ParisSharing | CC BY 2.0 |
| `zinc_roof.jpg` | dormers in an all-zinc roof, skylights, chimney stacks: how they sit in the slope | [Fameux toits en zinc de Paris](https://commons.wikimedia.org/wiki/File:Fameux_toits_en_zinc_de_Paris.jpg), besopha | CC BY 2.0 |
| `slate_dormer.jpg` | a dormer with a stone front and a slate cap, a hoist frame over it, from below | [30 rue de Condé](https://commons.wikimedia.org/wiki/File:30_rue_de_Cond%C3%A9_-_d%C3%A9tail.jpg), Jmgobet | CC BY-SA 3.0 |

## Measurements
The scale: the casement taken as 0.95 x 1.9 (a porte-fenêtre), which makes the slates ~0.20 x 0.30: as Angers slates are. Read off `dormer_grid_zinc_row.jpg` (seen from above: the cap and the cheeks are drawn higher than they stand).

- size (m): 1.76 x 2.45 x 1.41
- the opening 0.94 x 1.88 over the floor; jambs 0.18; the lintel to 2.02
- the cap: eaves 2.02-2.10, 1.62 wide, 0.15 in front, ridge 2.38
- the skirts flare from 1.60 down to 0.18 past the jambs at the floor
- the railing's top 0.98, on the floor plate 0.16 in front
- the mansard behind: 0.325 m back per metre up

## Visible details
- [x] M zinc front, flared skirts with rolls on their edges, cheeks back to the slope (R1)
- [x] M the hipped cap with fascia, rolls on hips and ridge and down the front (R1)
- [x] M casement: frame, two leaves of three panes (fixed), the dark room (R1)
- [x] M railing and floor plate (R1)
- [x] M leaves that open (as window_french), the cap's standing seams, the cornice's drip, the jambs' panel mouldings, the architrave strip, the flashing where the cheeks meet the slope (R2)
- [ ] M variants: stone front with a segmental pediment (slate_pediments, slate_dormer), an awning (slate_pediments)
- [ ] B zinc's dull blue-grey and its white bloom, dark streaks below the cap, plants on the railing (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| zinc | dull blue-grey | — | — | white bloom, dark streaks (never rust) |
| joinery | white paint | grey | wood | flakes at the bottom rail |
| glass | dark | — | — | |
| iron | black | red lead | rust | rust at the feet |
| room | dark | — | — | lit at night (R3) |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3000 | 1 | 20 m |
| 1 | 800 | 1 | 60 m |
| 2 | 500 | 1 | 300 m |

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l, leaf_r | the frame's jamb, behind | turn 100° into the room about Y |

## States
clean · abandoned · damaged · burnt.

## Round 1 — form
Match: `references/elements/reviews/dormer_match_r1.jpg`. Sheet: `references/elements/reviews/dormer_r1.jpg`.
Differences from the references:
- the first build failed in Blender: each zinc sheet was a face and its reverse on the same corners, which Blender merges (838 triangles became 817 faces)
- zinc_row's window sits 3 cm left of the jambs' middle (the photo; accepted)
Fixed:
- every zinc sheet is a slab 4 mm thick (`_poly_face`)
Open:
- abandoned and burnt paint the zinc like painted iron (pink patches, rust): zinc wants its own wear (white bloom, no rust) in round 3
- the room and the cheeks' backs show on the rack from behind; in a roof they are hidden (accepted)

## Round 2 — structure
Sheet: `references/elements/reviews/dormer_r2_sketch.png` (flat-shaded close-ups from the sketch renderer; the rack's review sheet `dormer_r2.jpg` needs a windowed Godot run: `python tools/models/review.py dormer --round=2`, left for the user).
Differences (against zinc_row):
- the casement's leaves were fixed: zinc_row shows two of the four standing open
- the cap's side slopes were plain sheets; zinc_row's have rolls (standing seams) running from the ridge down to the eaves, and the cap's eave stands out over its fascia as a drip
- the jambs were flat zinc; zinc_row's carry a raised panel each and a strip under the cap
- the cheeks met the slope with nothing between; every reference has a zinc flashing there
Fixed:
- `leaf_l` and `leaf_r` as parts hinged on the frame (100° into the room), each with stiles, rails, three panes, bars and its jet d'eau; past LOD 0 merged closed (draws 3)
- two rolls down each side slope, the cornice's drip front and sides
- raised panel mouldings on both jambs, the architrave strip
- a flashing strip along each cheek's foot on the slope
- triangles 1388 / 692 / 476 (budget 3000 / 800 / 500)
Open:
- the slates themselves belong to the mansard's roof face (the family's next element), not to the dormer
- a gutter end: zinc_row's dormers have none (the cap drips onto the slope); dropped

## Round 3 — surface
Sheet:
Differences:
-
Fixed:
-

## Review
