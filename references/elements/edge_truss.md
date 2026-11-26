# edge_truss — a bay of the canopy's edge truss (S198)

Family: `tools/models/props/terminal_columns.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py edge_truss` · sketch: `python tools/models/props.py edge_truss --sketch` · rack: `--prop-rack=edge_truss` · review: `python tools/models/review.py edge_truss --round=N`

A 7.2 m bay of the Warren truss along the canopy slab's edge: top and bottom chords of channel, six diagonals of angle alternating, gusset plates with four bolts at each node, verticals and bearing caps at both ends where the columns take it.

## References
Wikimedia Commons, `references/elements/edge_truss/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
1.2 m deep, its bottom chord at 5.3 m.

- size (m): 7.52 x 1.55 x 0.30
- chords 0.20 x 0.10
- diagonals 80 mm angle

## Visible details
- [x] M chords, diagonals, gussets, bolts, verticals, caps (R1)
- [ ] M bracing across to the next truss (R2)
- [ ] B rust runs from the nodes (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | blue-grey paint over steel | red primer | rust | rust runs |
| bolt | bolts |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1050 | 1 | 40 m |
| 1 | 260 | 1 | 120 m |
| 2 | 170 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/edge_truss_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py edge_truss --round=1`)
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
