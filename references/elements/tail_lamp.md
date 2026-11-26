# tail_lamp — a rear lamp cluster (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tail_lamp` · sketch: `python tools/models/props.py tail_lamp --sketch` · rack: `--prop-rack=tail_lamp` · review: `python tools/models/review.py tail_lamp --round=N`

The kit's rear lamp: a housing with red, amber and white sections behind its lens, ribs moulded in the red. Lit by the emission map (the reversing white is not).

## References
Wikimedia Commons, `references/elements/tail_lamp/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A small car's rear lamp: 0.28 x 0.13.

- size (m): 0.28 x 0.13 x 0.09
- red two thirds, amber, white

## Visible details
- [x] M housing, sections, ribs (R1)
- [ ] B cracked lens (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | lit |  |  |  |
| amber | lit |  |  |  |
| white | reversing |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 120 | 1 | 12 m |
| 1 | 56 | 1 | 60 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tail_lamp_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tail_lamp --round=1`)
Differences from the references:
- -
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
