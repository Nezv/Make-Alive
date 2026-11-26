# desk — the office desk (S193)

Family: `tools/models/props/office.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py desk` · sketch: `python tools/models/props.py desk --sketch` · rack: `--prop-rack=desk` · review: `python tools/models/review.py desk --round=N`

The office desk: a beech laminate top with a dark edge band on a grey steel frame of four square legs, rails and a modesty panel; a pedestal of three drawers under its right end (the top one is part `drawer`, pulling out 34 cm); the cable grommet; plastic feet.

## References
Wikimedia Commons, `references/elements/desk/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common 160 x 80 desk, 75 cm high.

- size (m): 1.60 x 0.75 x 0.80
- top 25 mm
- pedestal 0.42 wide: drawers 14, 14 and 30 cm

## Visible details
- [x] M top, edge, frame, modesty panel, pedestal, drawers, handles, grommet (R1)
- [ ] M the drawers' locks, a return desk (R2)
- [ ] B coffee rings, papers, chipped edges (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| laminate | beech laminate |  |  | worn at the front edge |
| steel | grey powder-coated steel |  | rust | scratches |
| edge | dark edge band |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 550 | 1 | 12 m |
| 1 | 380 | 1 | 36 m |
| 2 | 220 | 1 | 110 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| drawer | its front's middle | move 0.34 m out (-Z) |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/desk_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py desk --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; fetch office photos for round 2
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
