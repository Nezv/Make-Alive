# bike_hoop — the bicycle hoop (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bike_hoop` · sketch: `python tools/models/props.py bike_hoop --sketch` · rack: `--prop-rack=bike_hoop` · review: `python tools/models/review.py bike_hoop --round=N`

The bicycle stand of the pavements: a green steel tube bent into an inverted U, set into the pavement (its feet go 5 cm under y = 0), a bar across it low down for small wheels, collars at its feet.

## References
Wikimedia Commons, `references/elements/bike_hoop/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common hoop: 0.70 wide, 0.75 high, tube 48 mm.

- size (m): 0.79 x 0.82 x 0.09
- tube radius 0.024, the low bar at 0.28

## Visible details
- [x] M tube, bar, collars (R1)
- [ ] M the bend's welds (R2)
- [ ] B scratches where locks rub, a lock left on it (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| green | dark green | grey primer | rust | rubbed bare where bikes lean |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 650 | 1 | 15 m |
| 1 | 170 | 1 | 40 m |
| 2 | 56 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bike_hoop_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bike_hoop --round=1`)
Differences from the references:
- no photo yet: one to fetch for round 2
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
