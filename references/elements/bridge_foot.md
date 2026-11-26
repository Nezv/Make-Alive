# bridge_foot — the cast-iron footbridge (S165)

Family: `tools/models/props/bridges.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bridge_foot` · sketch: `python tools/models/props.py bridge_foot --sketch` · rack: `--prop-rack=bridge_foot` · review: `python tools/models/review.py bridge_foot --round=N`

The early cast-iron footbridge: one shallow span of 24 m between stone abutments, five iron arch ribs of I section, rings filling the outer ribs' spandrels (posts on the inner ones), cross-bracing, bearers, a deck of oak planks (one colour per plank), the iron railing each side (rail, foot rail, posts, balusters) and a lantern post at each corner, lit.

## References
Wikimedia Commons, `references/elements/bridge_foot/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A footbridge 5 m wide over 24 m; the deck 4.5 m over the water.

- size (m): 28.90 x 8.25 x 6.20
- rise 2.4 m
- railing 1.05 m
- lanterns at 3.25

## Visible details
- [x] M abutments, ribs, rings, bracing, planks, railing, lanterns (R1)
- [ ] M the ribs' bolted joints, the deck's iron edge (R2)
- [ ] B rust running from the joints, planks missing (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | green-grey iron | red primer | rust | rust runs |
| plank | oak planks |  |  | grey, rot |
| stone | abutments |  |  | moss |
| lamp | lantern glass (glows) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 12950 | 1 | 60 m |
| 1 | 3360 | 1 | 200 m |
| 2 | 510 | 1 | 800 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bridge_foot_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bridge_foot --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; the Pont des Arts' old photos for round 2
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
