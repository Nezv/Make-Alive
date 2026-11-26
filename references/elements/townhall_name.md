# townhall_name — HÔTEL DE VILLE over the door (S218)

Family: `tools/models/props/townhall.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py townhall_name` · sketch: `python tools/models/props.py townhall_name --sketch` · rack: `--prop-rack=townhall_name` · review: `python tools/models/review.py townhall_name --round=N`

The town hall's name over its door: a stone panel in a moulded frame with HÔTEL DE VILLE in gilded raised letters (`lettering.mesh`), and under it the frieze band with the republic's motto LIBERTÉ - ÉGALITÉ - FRATERNITÉ cut in (painted by position). The far LOD drops the letters into the panel.

## References
Wikimedia Commons, `references/elements/townhall_name/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Letters 0.36 m on a 5.2 x 0.7 m panel.

- size (m): 5.60 x 0.98 x 0.15
- motto 90 mm

## Visible details
- [x] M panel, frame, raised letters, frieze, motto (R1)
- [ ] B worn gilding, dirty letters, one letter missing (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | soot |
| gilt | gilded letters |  |  | worn gilt |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 780 | 1 | 30 m |
| 1 | 660 | 1 | 90 m |
| 2 | 30 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/townhall_name_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py townhall_name --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; French town halls' carved names and arms for round 2
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
