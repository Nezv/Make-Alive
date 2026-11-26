# food_litter — food litter on a floor (S196)

Family: `tools/models/props/clutter.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py food_litter` · sketch: `python tools/models/props.py food_litter --sketch` · rack: `--prop-rack=food_litter` · review: `python tools/models/review.py food_litter --round=N`

What people ate and dropped: crisp packets and wrappers (pillows crimped at both ends, a colour each), cans on their sides with one crushed, a takeaway cup and its lid, a plastic bag crumpled half flat, a pizza box with its lid open. No brands.

## References
Wikimedia Commons, `references/elements/food_litter/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Spread over 1.4 x 0.9 m.

- size (m): 1.40 x 0.32 x 0.94
- cans 0.116 x 0.066

## Visible details
- [x] M packets, cans, cup, lid, bag, pizza box (R1)
- [ ] B trodden flat, burnt (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| wrapper | printed foil (four colours) |  |  |  |
| can | painted aluminium (three) |  |  | dents |
| bag | white plastic |  |  | dirt |
| board | cardboard |  |  | grease |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1100 | 1 | 6 m |
| 1 | 450 | 1 | 20 m |
| 2 | 70 | 1 | 60 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/food_litter_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py food_litter --round=1`)
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
