# column_tree — the canopy's steel tree column (S198)

Family: `tools/models/props/terminal_columns.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py column_tree` · sketch: `python tools/models/props.py column_tree --sketch` · rack: `--prop-rack=column_tree` · review: `python tools/models/review.py column_tree --round=N`

A steel tree holding the bus station's canopy slab: a concrete pedestal with chamfered corners, the base plate and its four bolts, a tube trunk swelling at its foot up to a cast node ring at 4.2 m, four arms splaying up and out (narrowing as they go) to bearing plates bolted under the slab at 6.5 m, gussets between the arms' roots.

## References
Wikimedia Commons, `references/elements/column_tree/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Trunk 0.32 m across; arms reach 2.4 m out; the slab's underside at 6.5 m.

- size (m): 3.75 x 6.51 x 3.75
- pedestal 0.8 x 0.9
- node at 4.2

## Visible details
- [x] M pedestal, plate, bolts, trunk, node, arms, bearings, gussets (R1)
- [ ] M the arms as I-sections or tubes per the photos; welds (R2)
- [ ] B chipped paint, rust at the base, posters on the pedestal, pigeon mess (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | blue-grey paint over steel | red primer | rust | chips |
| concrete | pedestal |  |  | posters, stains |
| bolt | bolts |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1370 | 1 | 40 m |
| 1 | 440 | 1 | 120 m |
| 2 | 270 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/column_tree_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py column_tree --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; canopy stations' tree columns for round 2 (photos first, says the step)
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
