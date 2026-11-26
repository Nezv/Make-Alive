# mansard — one bay of a Paris mansard roof (S159)

Family: `tools/models/props/roofs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py mansard` · sketch: `python tools/models/props.py mansard --sketch` · rack: `--prop-rack=mansard` · review: `python tools/models/review.py mansard --round=N`

The roof of the main streets' houses (S043's `main` class), as a 3 m bay repeated along the front: the zinc box gutter (chéneau) on the cornice, the steep slate slope (brisis, 72°) on its board deck, the zinc roll at the break (bourseau), the shallow zinc slope (terrasson, 20°) with standing seams up to the ridge's roll, a cast-iron skylight (tabatière). Dormers (`dormer`) and chimney stacks stand in it. Slates are the kit's new surface `surfaces.slates` (rows a half slate on, each resting on the two below).

## References
`references/elements/mansard/` (Wikimedia Commons; the same files as the dormer's and the chimney's cards).

| file | what it shows | source | licence |
|---|---|---|---|
| `zinc_row.jpg` | **the main reference**: a slate brisis with four dormers, the zinc terrasson above with its standing seams and two skylights, the break's roll, the gutter ledge | [Dormer windows in Paris, 26 September 2011](https://commons.wikimedia.org/wiki/File:Dormer_windows_in_Paris,_September_26,_2011.jpg), Jorge Andrade | CC BY 2.0 |
| `slate_close.jpg` | the slates close: rows, sizes, stains, slipped and patched slates, the zinc at the top | [Camini Parigi](https://commons.wikimedia.org/wiki/File:Camini_Parigi.jpg), Ricce | public domain |
| `zinc_roof.jpg` | an all-zinc roof: seams, skylights, how a roofscape reads from above | [Fameux toits en zinc de Paris](https://commons.wikimedia.org/wiki/File:Fameux_toits_en_zinc_de_Paris.jpg), besopha | CC BY 2.0 |

## Measurements
The scale: the dormers of zinc_row (casement 0.95 x 1.9: `dormer.md`); their slates then come out 0.22 wide with 0.11 showing per row (Angers slates 0.32 x 0.22, a gauge of 0.11): both agree. The terrasson's seams 0.62 apart (zinc sheets 0.65 wide less the rolls).

- size (m): 3.00 x 3.63 x 3.66
- the gutter on the cornice: 0.36 out from the slates' foot, 0.16 deep with its rolled lip
- the brisis: 2.60 tall at 72° (0.325 back per metre up, as the dormer's cheeks), slates from 0.10 over the cornice
- the terrasson: 2.40 back to the ridge at 20°, seams 0.62 apart, the ridge's roll 7 cm
- the tabatière: 0.48 x 0.60

## Visible details
- [x] M box gutter with its rolled front lip and its back turned up under the slates (R1)
- [x] M slates in rows a half slate on, each a little out of line, three missing showing the dark deck (R1)
- [x] M the break's zinc roll and its apron over the top row (R1)
- [x] M terrasson: zinc sheet, standing seams, the ridge's roll (R1)
- [x] M a cast-iron tabatière with its glass, middle bar and flashing (R1)
- [ ] M the gutter's outlet to a downpipe, snow hooks (crochets) on the brisis, the cross seams of the zinc sheets, a patched slate in a lighter tone (R2)
- [ ] M the bay's ends: a party-wall return (the stack's foot) and a hipped corner (R2: S044 needs corners)
- [ ] B lichen and white bloom on the zinc, the slates' rust-brown stains and moss in the rows, dark streaks below the break (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| slate | blue-grey, a little different slate to slate | — | — | moss in the rows, rust stains, white bloom |
| zinc | dull blue-grey | — | — | white bloom, dark streaks (never rust) |
| deck | the dark boards under the slates | — | — | |
| iron | the tabatière's frame, black | red lead | rust | rust round the frame |
| glass | dark | — | — | cracked, broken (damaged) |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 5000 | 1 | 20 m |
| 1 | 600 | 1 | 80 m |
| 2 | 120 | 1 | 500 m |

A street of houses shows hundreds of bays: past 20 m the slates are one stepped board a row (LOD 1), past 80 m two sheets (LOD 2), the slates baked onto them.

## Moving parts
None (the tabatière opening: later, if a mission climbs onto the roofs).

## States
clean · abandoned · damaged · burnt.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/mansard_r1_sketch.png` (sketch close-ups; the rack's review sheet waits for a windowed run: `python tools/models/review.py mansard --round=1`)
Differences from the references:
- the slates' colours (the sketch's palette, one per slate) alternated like a checkerboard; slate_close's slates differ much less
Fixed:
- a narrower palette (within 0.03 of the mean)
Open:
- the bay's ends are open: a run of bays closes them, a street's end needs the party-wall return (round 2)

## Round 2 — structure
Sheet:
Differences:
-
Fixed:
-

## Round 3 — surface
Sheet:
Differences:
-
Fixed:
-

## Review
What is left, each item fixed or accepted with a reason.
