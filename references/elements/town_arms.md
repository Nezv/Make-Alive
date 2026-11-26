# town_arms — the town's arms (S218)

Family: `tools/models/props/townhall.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py town_arms` · sketch: `python tools/models/props.py town_arms --sketch` · rack: `--prop-rack=town_arms` · review: `python tools/models/review.py town_arms --round=N`

The town's arms for the pediment, invented: a stone cartouche with scrolls at its sides; the shield azure with a tower argent (its door showing the field) and, on a chief gules, three mullets or in relief (the tinctures painted); the gilded mural crown of five towers over it; oak and laurel branches round it; the ribbon under it with the motto VIGILAT ET LABORAT (invented).

## References
Wikimedia Commons, `references/elements/town_arms/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Shield 0.9 x 1.05 m; the whole 1.6 m across.

- size (m): 1.60 x 1.54 x 0.21
- crown 0.30 high

## Visible details
- [x] M cartouche, scrolls, shield, tower, stars, crown, branches, ribbon, motto (R1)
- [ ] M the crown's masonry lines, the leaves' veins (R2)
- [ ] B the colours flaking off the stone, a chip off the crown (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | soot |
| field | painted field (azure, gules) |  |  | flaking |
| silver | the tower |  |  |  |
| gilt | crown and stars |  |  | worn |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1440 | 1 | 30 m |
| 1 | 620 | 1 | 90 m |
| 2 | 70 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/town_arms_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py town_arms --round=1`)
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
