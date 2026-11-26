# clothes_pile — a pile of clothes (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py clothes_pile` · sketch: `python tools/models/props.py clothes_pile --sketch` · rack: `--prop-rack=clothes_pile` · review: `python tools/models/review.py clothes_pile --round=N`

Clothes dropped from a suitcase or a car: seven garments lying in folds on each other (each a cloth sheet over what is under it, a colour per garment), sleeves trailing, a scarf across, a shoe among them.

## References
Wikimedia Commons, `references/elements/clothes_pile/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A heap 1.1 x 1.0 m, 0.26 m high.

- size (m): 1.11 x 0.26 x 1.01
- garments 0.35 to 0.65 m

## Visible details
- [x] M garments, sleeves, scarf, shoe (R1)
- [ ] M a coat, a pair of jeans by shape (R2)
- [ ] B wet, trodden, bloody (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| cloth | fabrics (six colours) |  |  | wet, dirt |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1760 | 1 | 8 m |
| 1 | 650 | 1 | 25 m |
| 2 | 80 | 1 | 80 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/clothes_pile_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py clothes_pile --round=1`)
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
