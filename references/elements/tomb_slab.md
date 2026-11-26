# tomb_slab — a grave with its headstone and railing (S189)

Family: `tools/models/props/cemetery.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tomb_slab` · sketch: `python tools/models/props.py tomb_slab --sketch` · rack: `--prop-rack=tomb_slab` · review: `python tools/models/review.py tomb_slab --round=N`

The common grave: a stone border, the slab over it, a headstone at its head with a rounded top and FAMILLE MOREAU carved (invented), facing the foot where the visitor stands, a low iron railing round it with ball-topped posts.

## References
Wikimedia Commons, `references/elements/tomb_cross/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `alley.jpg` | graves along the alley: slabs, headstones, railings | [Cimetière de Vichy, allée principale.jpg](https://commons.wikimedia.org/wiki/File:Cimeti%C3%A8re_de_Vichy,_all%C3%A9e_principale.jpg), TCY | CC BY-SA 4.0 |

## Measurements
A single grave: 0.95 x 2.10; the headstone 0.95 over the slab.

- size (m): 1.19 x 1.15 x 2.29
- border 0.20, slab to 0.30
- railing 0.50 high, two rails, bars every 0.12

## Visible details
- [x] M border, slab, headstone, railing, posts, balls, bars (R1)
- [x] B the carved name (R1)
- [ ] M a vase, a plaque, a broken railing (R2)
- [ ] B lichen, the headstone tilted and cracked (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | lichen, black streaks, moss at the foot |
| iron | black iron |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 950 | 1 | 15 m |
| 1 | 280 | 1 | 50 m |
| 2 | 50 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tomb_slab_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tomb_slab --round=1`)
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
