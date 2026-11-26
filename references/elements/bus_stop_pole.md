# bus_stop_pole — the plain bus stop pole (S170)

Family: `tools/models/props/bus_stop.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bus_stop_pole` · sketch: `python tools/models/props.py bus_stop_pole --sketch` · rack: `--prop-rack=bus_stop_pole` · review: `python tools/models/review.py bus_stop_pole --round=N`

The stop without a shelter: a grey pole, the blue BUS sign at its top, the stop's name on a plate flying to one side, the lines' numbers on plates below, the timetable case at eye height.

## References
Wikimedia Commons, `references/elements/bus_shelter/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `totem.jpg` | **the main reference**: the sign at the top, the name plate flying out, the lines' plates stacked | [Arrêt bus Victorien Sardou Paris 2.jpg](https://commons.wikimedia.org/wiki/File:Arr%C3%AAt_bus_Victorien_Sardou_Paris_2.jpg), Chabe01 | CC BY-SA 4.0 |

## Measurements
The pole 3.05 m against the shelter's 2.5 m roof beside it in totem.jpg; plates 0.15 m pitch.

- size (m): 0.74 x 3.08 x 0.16
- sign 0.44 square at the top
- name plate 0.64 x 0.15, lines' plates 0.16 x 0.12
- timetable case 0.34 x 0.48 at 1.50

## Visible details
- [x] M pole and cap, BUS sign, name plate, lines' plates, timetable case, clamps (R1)
- [x] B BUS, PLACE DU MARCHE, the line numbers, the timetable's rows (R1)
- [ ] M the plates' rims and screws (R2)
- [ ] B stickers, faded blue (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | grey | primer | rust |  |
| sign | blue |  | aluminium |  |
| panel | white |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 350 | 1 | 20 m |
| 1 | 250 | 1 | 60 m |
| 2 | 160 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bus_stop_pole_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bus_stop_pole --round=1`)
Differences from the references:
- totem.jpg's sign is the operator's round totem; ours is a plain blue square with BUS (no brand)
Fixed:
- -
Open:
- -

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
