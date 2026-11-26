# car_seat — a car's front seat (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py car_seat` · sketch: `python tools/models/props.py car_seat --sketch` · rack: `--prop-rack=car_seat` · review: `python tools/models/review.py car_seat --round=N`

A small car's front seat: runners on the floor, the frame, a padded cushion with side bolsters, the back reclined with its bolsters, the headrest on two chrome posts, the recline lever and the seat belt's buckle on its stalk. Grey cloth.

## References
Wikimedia Commons, `references/elements/car_seat/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
0.5 m wide, 1.15 m to the headrest.

- size (m): 0.59 x 1.15 x 0.83
- cushion at 0.32

## Visible details
- [x] M runners, frame, cushion, bolsters, back, headrest, posts, lever, buckle (R1)
- [ ] M the rear bench (R2)
- [ ] B torn, bloody, burnt to its springs (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| seat | grey cloth |  |  | stains |
| housing | plastic, frame |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 600 | 1 | 10 m |
| 1 | 220 | 1 | 30 m |
| 2 | 90 | 1 | 90 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/car_seat_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py car_seat --round=1`)
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
