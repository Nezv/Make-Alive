# filing_cabinet — the four-drawer filing cabinet (S193)

Family: `tools/models/props/office.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py filing_cabinet` · sketch: `python tools/models/props.py filing_cabinet --sketch` · rack: `--prop-rack=filing_cabinet` · review: `python tools/models/review.py filing_cabinet --round=N`

The steel filing cabinet of four drawers: each front with a recessed handle, its bar and a label holder with its card; the lock at the top corner; the plinth set back. The top drawer (part `drawer`) pulls out 45 cm on its hanging files.

## References
Wikimedia Commons, `references/elements/filing_cabinet/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common cabinet: 0.47 x 1.32 x 0.62.

- size (m): 0.47 x 1.32 x 0.65
- drawers 0.315 each

## Visible details
- [x] M body, drawers, handles, label holders, lock, plinth, files (R1)
- [ ] M the labels' handwriting, dents (R2)
- [ ] B ransacked: every drawer out, files on the floor (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | grey steel |  | rust | dents, scratches |
| box | files |  |  |  |
| beige | label cards |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 720 | 1 | 12 m |
| 1 | 400 | 1 | 36 m |
| 2 | 100 | 1 | 110 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| drawer | its front's middle | move 0.45 m out (-Z) |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/filing_cabinet_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py filing_cabinet --round=1`)
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
