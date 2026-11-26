# alarm_point — the red fire alarm point (S194)

Family: `tools/models/props/fittings.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py alarm_point` · sketch: `python tools/models/props.py alarm_point --sketch` · rack: `--prop-rack=alarm_point` · review: `python tools/models/review.py alarm_point --round=N`

The red manual call point on a wall: a box, the white glass square to press, ALARME over it, APPUYER on the glass.

## References
Wikimedia Commons, `references/elements/alarm_point/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The standard box: 0.10 square, 0.05 deep, at 1.40.

- size (m): 0.10 x 0.10 x 0.054
- glass 0.06 square

## Visible details
- [x] M box, glass (R1)
- [x] B ALARME, APPUYER (R1)
- [ ] M the key slot, the glass's frame (R2)
- [ ] B the glass broken as a state (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | red plastic |  |  | fades |
| glass | white glass |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 40 | 1 | 10 m |
| 1 | 26 | 1 | 40 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/alarm_point_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py alarm_point --round=1`)
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
