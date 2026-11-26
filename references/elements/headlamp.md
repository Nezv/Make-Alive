# headlamp — a headlamp cluster (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py headlamp` · sketch: `python tools/models/props.py headlamp --sketch` · rack: `--prop-rack=headlamp` · review: `python tools/models/review.py headlamp --round=N`

The kit's headlamp: a dark housing, two chrome reflector bowls with their lit bulbs behind a clear lens, the amber indicator in its corner. Lit by the emission map. Its front -Z.

## References
Wikimedia Commons, `references/elements/headlamp/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A small car's headlamp: 0.34 x 0.14, 0.12 deep.

- size (m): 0.34 x 0.14 x 0.13
- bowls 0.10 and 0.09 across

## Visible details
- [x] M housing, bowls, bulbs, indicator, lens (R1)
- [ ] M the lens's moulding, the projector (R2)
- [ ] B yellowed lens, cracked as a state (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| housing | black plastic |  |  |  |
| chrome | reflectors |  |  |  |
| lens | lit |  |  |  |
| amber | indicator |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 300 | 1 | 12 m |
| 1 | 220 | 1 | 40 m |
| 2 | 170 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/headlamp_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py headlamp --round=1`)
Differences from the references:
- no photo yet: one to fetch with S180's car
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
