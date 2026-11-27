# window_barracks — the tall green-framed timber window of the barracks blocks (S157, S221)

Family: `tools/models/props/windows.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py window_barracks` · sketch: `python tools/models/props.py window_barracks --sketch` · rack: `--prop-rack=window_barracks` · review: `python tools/models/review.py window_barracks --round=N`

## References
Photos in `references/elements/window_barracks/`, each with its source and licence.

| file | what it shows | source | licence |
|---|---|---|---|
| — | none yet: Commons is out of reach from the cloud session; they are being fetched on the PC | | |

Where: the Batalhão's four long blocks round the parade ground (`references/batalhao_elements.md`: "white walls with a green band at the foot, tall green-framed windows in a row"). Also fits the town's older public buildings.

## Measurements
Brazilian army barracks of the 1930s-50s: thick plastered brick walls (35 cm), tall openings with a fanlight (bandeira) over double casements.

- size (m): 1.44 x 2.52 x 0.99
- the opening: 1.10 wide, its head 2.38 over the sill's bottom; the sill's top at 0.08
- the band round it: 14 cm, 1.5 cm proud, painted white over the white wall (its line reads in the light)
- the sill: concrete, 6 cm in front of the band, washed, a drip under the nose
- the reveal: 0.24 deep to the frame's face (a 0.35 wall)
- the frame: green, 7 cm deep; the transom at 1.86
- each casement: stiles 5.5 cm, meeting stile 6 cm, top rail 6, bottom rail 12; three panes
- the fanlight: one sash of two panes, hinged at its foot
- the room behind: 0.60 deep

## Visible details
- [x] M band, reveal, sill with its drip (R1)
- [x] M frame, sill rail washed, transom (R1)
- [x] M two casements: stiles, rails, glazing bars, panes, drip mouldings, hinge knuckles, the battement on the right leaf (R1)
- [x] M fanlight with its middle bar (R1)
- [x] M the pins left in the band where shutters once hung (R1)
- [ ] M the fanlight's stay and the casements' espagnolette handle (R2)
- [ ] B peeling green paint, the white band's damp at the sill, dirt in the corners (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| band | white lime paint | — | — | damp and grey streaks under the sill |
| plaster | white, the reveal | — | — | grime |
| concrete | grey sill | — | — | moss on the shaded nose |
| frame | military green oil paint | white undercoat | grey wood | flakes on the bottom rails first |
| glass | dark | — | — | cracks, holes (damaged) |
| iron | the old pins | — | rust | runs down the band |
| room | the dark room | — | — | lit at night (R3) |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1500 | 4 | 15 m |
| 1 | 750 | 1 | 50 m |
| 2 | 400 | 1 | 300 m |

Repeated along a block: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l, leaf_r | the frame's jamb, behind | turn 100° into the room about Y |
| fanlight | its foot, behind | top tips 35° into the room about X |

## States
clean · abandoned · damaged · burnt (paint); open and shut from the parts. Broken, boarded (the defence), burnt with soot above: R2-R3.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/window_barracks_r1_sketch.png` (sketch: every LOD and the parts open; the rack's sheet waits for a windowed run: `python tools/models/review.py window_barracks --round=1`)
Differences from the references:
- no photo yet: sizes are from standard practice (below), to be checked against the photos with `match.py --grid` in round 2
- the photos of the 62º BI (`references/batalhao*`) are aerial: the window's proportions follow the usual 1:2 of the period
Fixed:
- the fanlight first tipped out toward the street: now into the room
Open:
- the rack's sheet and the baked paint, once built on the PC

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
