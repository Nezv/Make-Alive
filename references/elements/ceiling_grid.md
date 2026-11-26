# ceiling_grid — a suspended ceiling module (S192)

Family: `tools/models/props/stairs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py ceiling_grid` · sketch: `python tools/models/props.py ceiling_grid --sketch` · rack: `--prop-rack=ceiling_grid` · review: `python tools/models/review.py ceiling_grid --round=N`

A 2.4 m module of suspended ceiling hung 0.45 m under the slab: the T-bar grid, mineral tiles of 600 mm (a colour per tile), one hanging open from its far edge, one gone showing a duct and a cable above, a water stain spreading over two (painted), a recessed louvre light (lit), the wire hangers.

## References
Wikimedia Commons, `references/elements/ceiling_grid/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Tiles 600 mm; the grid at 0.45 m under the soffit (y = 0).

- size (m): 2.42 x 0.91 x 2.42
- tees 24 mm

## Visible details
- [x] M grid, tiles, hanging tile, gap, light, louvres, hangers, duct, cable (R1)
- [ ] M which tiles fall per instance (seed) (R2)
- [ ] B tiles fallen to the floor, the light dead or flickering (S108)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| tile | mineral tiles |  |  | water stains |
| steel | grid, louvres, hangers |  |  |  |
| light | diffuser (glows) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1000 | 1 | 15 m |
| 1 | 690 | 1 | 45 m |
| 2 | 340 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/ceiling_grid_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py ceiling_grid --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; stairwells and ceilings for round 2
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
