# medkit — the red first-aid bag (S153)

Family: `tools/models/props/carried.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py medkit` · sketch: `python tools/models/props.py medkit --sketch` · rack: `--prop-rack=medkit` · review: `python tools/models/review.py medkit --round=N`

The medkit of the inventory: a red rounded bag zipped round its top, a white cross on the front and the top, a carry handle, a strap ring at each end.

## References
Wikimedia Commons, `references/elements/medkit/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A hand: 0.30 m long, the handle a fist's width.

- size (m): 0.32 x 0.24 x 0.16
- bag 0.30 x 0.19 x 0.15, rounded 0.03
- crosses 0.09 across

## Visible details
- [x] M bag, zip and pull, crosses, handle, strap rings (R1)
- [ ] M the zip's teeth, the seams' piping (R2)
- [ ] B dirt and blood, worn corners (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | red nylon |  |  | dirt, blood |
| white | the crosses |  |  |  |
| zip | black zip |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 320 | 1 | 6 m |
| 1 | 180 | 1 | 15 m |
| 2 | 20 | 1 | 40 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/medkit_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py medkit --round=1`)
Differences from the references:
- no photo of a modern red bag yet (the museum's old bags are canvas): one to fetch for round 2
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
