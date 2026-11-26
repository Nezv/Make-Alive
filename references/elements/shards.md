# shards — broken glass on a floor (S196)

Family: `tools/models/props/clutter.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py shards` · sketch: `python tools/models/props.py shards --sketch` · rack: `--prop-rack=shards` · review: `python tools/models/review.py shards --round=N`

A window's glass on a floor: forty flat jagged shards thrown from -Z towards +Z, four large, a few standing on an edge.

## References
Wikimedia Commons, `references/elements/shards/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
4 mm glass; the large shards 0.12 m, the rest 1.5 to 5 cm.

- size (m): 1.50 x 0.057 x 1.40
- spread 0.3 m across, 0.35 deep

## Visible details
- [x] M shards, some on edge (R1)
- [ ] M the large ones cracked across (R2)
- [ ] B dust and blood on them (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| glass | window glass |  |  | dust |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 620 | 1 | 6 m |
| 1 | 280 | 1 | 15 m |
| 2 | 130 | 1 | 40 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/shards_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py shards --round=1`)
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
