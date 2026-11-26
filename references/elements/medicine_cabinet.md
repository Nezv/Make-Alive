# medicine_cabinet — the ward's medicine cabinet (S211)

Family: `tools/models/props/hospital.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py medicine_cabinet` · sketch: `python tools/models/props.py medicine_cabinet --sketch` · rack: `--prop-rack=medicine_cabinet` · review: `python tools/models/review.py medicine_cabinet --round=N`

A ward's steel medicine cabinet on four feet: two glazed doors (parts `door_l`, `door_r`, opening outwards) over four shelves of boxes and bottles (seeded), two drawers with handles under them.

## References
Wikimedia Commons, `references/elements/medicine_cabinet/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common cabinet: 0.80 x 1.80 x 0.40 on 6 cm feet.

- size (m): 0.80 x 1.86 x 0.44
- shelves every 0.30 from 0.61
- drawers 0.20 tall

## Visible details
- [x] M body, feet, shelves, boxes, drawers, handles, glazed doors (R1)
- [ ] M the lock, labels on the shelves (R2)
- [ ] B looted: shelves bare, glass smashed (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| grey | white-grey steel |  | rust | scratches |
| sheet | boxes |  |  |  |
| bag | glass, bottles |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 760 | 1 | 15 m |
| 1 | 250 | 1 | 40 m |
| 2 | 200 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| door_l | its left edge (-0.39, 0, -0.20) | rotate 100° about +Y: out |
| door_r | its right edge (0.39, 0, -0.20) | rotate -100° about +Y: out |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/medicine_cabinet_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py medicine_cabinet --round=1`)
Differences from the references:
- no photo yet: one to fetch for round 2
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
