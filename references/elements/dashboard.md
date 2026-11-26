# dashboard — a small car's dashboard (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py dashboard` · sketch: `python tools/models/props.py dashboard --sketch` · rack: `--prop-rack=dashboard` · review: `python tools/models/review.py dashboard --round=N`

A small car's dashboard, the driver on the left: the moulded top under the windscreen, the binnacle over two dials (lit), the three-spoke steering wheel on its column, the centre stack with two vents, the radio and three heater knobs, round vents at the ends, the glovebox on the right.

## References
Wikimedia Commons, `references/elements/dashboard/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
1.40 m across the car.

- size (m): 1.40 x 0.61 x 0.79
- wheel 0.37 across

## Visible details
- [x] M top, binnacle, dials, wheel, column, stack, vents, radio, knobs, glovebox (R1)
- [ ] M the gear lever and the handbrake between the seats (R2)
- [ ] B the airbag burst, glass on it (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| housing | dark grey plastic |  |  | dust |
| dial | dials (glow) |  |  |  |
| chrome | knobs |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1090 | 1 | 10 m |
| 1 | 640 | 1 | 30 m |
| 2 | 260 | 1 | 90 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/dashboard_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py dashboard --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; photos for round 2
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
