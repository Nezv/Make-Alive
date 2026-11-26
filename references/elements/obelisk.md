# obelisk — a family obelisk (S189)

Family: `tools/models/props/cemetery.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py obelisk` · sketch: `python tools/models/props.py obelisk --sketch` · rack: `--prop-rack=obelisk` · review: `python tools/models/review.py obelisk --round=N`

A family obelisk: two steps, a die with its plaque and cornice, the tapering dark shaft to its point, a bronze wreath on it.

## References
Wikimedia Commons, `references/elements/tomb_cross/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `alley.jpg` | an obelisk at the head of the alley | [Cimetière de Vichy, allée principale.jpg](https://commons.wikimedia.org/wiki/File:Cimeti%C3%A8re_de_Vichy,_all%C3%A9e_principale.jpg), TCY | CC BY-SA 4.0 |

## Measurements
alley.jpg: the obelisk ~3.5 m against the chapels beside it.

- size (m): 1.30 x 3.55 x 1.30
- steps 1.30 and 1.04, die 0.76, shaft 0.60 to 0.34 square

## Visible details
- [x] M steps, die, cornice, shaft, point, plaque, wreath (R1)
- [ ] B carved names on the die (R2)
- [ ] B black streaks, lichen (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | lichen, black streaks, moss at the foot |
| dark_stone | grey granite |  |  |  |
| plaque | bronze |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 230 | 1 | 30 m |
| 1 | 90 | 1 | 100 m |
| 2 | 72 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/obelisk_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py obelisk --round=1`)
Differences from the references:
- -
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
