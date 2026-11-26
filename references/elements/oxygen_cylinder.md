# oxygen_cylinder — the oxygen cylinder on its trolley (S211)

Family: `tools/models/props/hospital.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py oxygen_cylinder` · sketch: `python tools/models/props.py oxygen_cylinder --sketch` · rack: `--prop-rack=oxygen_cylinder` · review: `python tools/models/review.py oxygen_cylinder --round=N`

A medical oxygen cylinder on its two-wheeled trolley: the white cylinder, its brass valve, the regulator with its gauge and outlet, the trolley's frame and handle behind it, a strap round it, a base plate.

## References
Wikimedia Commons, `references/elements/oxygen_cylinder/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common 15 litre medical cylinder: 0.18 across, 0.95 tall.

- size (m): 0.30 x 1.10 x 0.34
- cylinder radius 0.09, 0.95 tall
- wheels 0.16

## Visible details
- [x] M cylinder, valve, regulator, gauge, outlet, trolley, wheels, handle, strap (R1)
- [ ] M the gauge's face, the valve's wheel (R2)
- [ ] B labels, scuffs (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| white | white cylinder |  | steel | scuffs |
| brass | valve |  |  |  |
| grey | trolley |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 800 | 1 | 12 m |
| 1 | 600 | 1 | 35 m |
| 2 | 320 | 1 | 100 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/oxygen_cylinder_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py oxygen_cylinder --round=1`)
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
