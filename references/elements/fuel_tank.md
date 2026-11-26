# fuel_tank — the generator's day tank (S212)

Family: `tools/models/props/generator.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py fuel_tank` · sketch: `python tools/models/props.py fuel_tank --sketch` · rack: `--prop-rack=fuel_tank` · review: `python tools/models/review.py fuel_tank --round=N`

The day tank: a steel tank on four legs inside its bund's lip, GAZOLE on its front (painted by position), a sight gauge with its marks, the yellow fill cap, the vent pipe, the copper feed pipe and its red valve down to the set, the drip tray under it all.

## References
Wikimedia Commons, `references/elements/fuel_tank/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A 500 l tank: 1.2 x 0.8 x 0.6 on 0.4 m legs.

- size (m): 1.62 x 1.69 x 0.80
- gauge 0.64 tall

## Visible details
- [x] M legs, tank, bund, gauge, cap, vent, feed, valve, tray (R1)
- [ ] B diesel stains, a leak (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | grey steel |  | rust | stains |
| copper | feed pipe |  |  | verdigris |
| dial | gauge |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 290 | 1 | 20 m |
| 1 | 220 | 1 | 60 m |
| 2 | 90 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/fuel_tank_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py fuel_tank --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; photos first for round 2
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
