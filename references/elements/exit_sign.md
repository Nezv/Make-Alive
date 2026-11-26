# exit_sign — the emergency exit light (S194)

Family: `tools/models/props/fittings.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py exit_sign` · sketch: `python tools/models/props.py exit_sign --sketch` · rack: `--prop-rack=exit_sign` · review: `python tools/models/review.py exit_sign --round=N`

The emergency exit light over the doors (the French BAES): a white box on the wall, its face lit green, the running man at his door and the arrow in white, the test button under it.

## References
Wikimedia Commons, `references/elements/exit_sign/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common box: 0.34 x 0.13 x 0.07, over a door at 2.20.

- size (m): 0.34 x 0.13 x 0.074
- face 0.31 x 0.11

## Visible details
- [x] M box, face, test button (R1)
- [x] B the man, the door, the arrow (R1)
- [ ] M the box's vents (R2)
- [ ] B yellowed plastic, dust (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plastic | white box |  |  | yellows |
| exit | green face, lit |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 60 | 1 | 12 m |
| 1 | 40 | 1 | 35 m |
| 2 | 26 | 1 | 100 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/exit_sign_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py exit_sign --round=1`)
Differences from the references:
- no photo yet; the running man is crude (round 2)
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
