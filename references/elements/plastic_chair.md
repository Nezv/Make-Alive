# plastic_chair — the white monobloc chair (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py plastic_chair` · sketch: `python tools/models/props.py plastic_chair --sketch` · rack: `--prop-rack=plastic_chair` · review: `python tools/models/review.py plastic_chair --round=N`

The white monobloc chair: a seat with rounded front corners, four flared legs, the back leaning with its slats and curved top rail, arms sweeping from the back down into the front legs.

## References
Wikimedia Commons, `references/elements/plastic_chair/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `white.jpg` | **the main reference**: the chair three-quarter: slats, arms, legs | [White Monobloc chair.jpg](https://commons.wikimedia.org/wiki/File:White_Monobloc_chair.jpg), Seniju | CC BY 2.0 |

## Measurements
The common monobloc: seat 0.44, back 0.82, arms 0.64.

- size (m): 0.54 x 0.84 x 0.59
- seat 0.46 x 0.44
- five slats
- legs flaring 0.02 out at the foot

## Visible details
- [x] M seat, legs, posts, slats, top rail, rail under the slats, arms (R1)
- [ ] M the legs' U section, the seat's drain holes (R2)
- [ ] B grime, green algae in the corners (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plastic | white polypropylene |  |  | grime, algae |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 420 | 1 | 15 m |
| 1 | 250 | 1 | 40 m |
| 2 | 190 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/plastic_chair_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py plastic_chair --round=1`)
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
