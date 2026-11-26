# garden_wall — one bay of a garden wall (S156)

Family: `tools/models/props/boundaries.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py garden_wall` · sketch: `python tools/models/props.py garden_wall --sketch` · rack: `--prop-rack=garden_wall` · review: `python tools/models/review.py garden_wall --round=N`

One 3.0 m bay of the plastered rubble wall round a garden or a court: a stone plinth course, the plastered wall, a stone coping of two slopes overhanging both faces, a stone pier at the bay's end; at lod 0 the rubble shows where the plaster has fallen.

## References
Wikimedia Commons, `references/elements/porte_cochere/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `worn_1900.jpg` | the old walls beside the gateway: plaster, damp, posters | [Porte cochère, 15 rue Barbette, 3ème arrondissement, Paris. PH37531.jpg](https://commons.wikimedia.org/wiki/File:Porte_coch%C3%A8re,_15_rue_Barbette,_3%C3%A8me_arrondissement,_Paris._PH37531.jpg), Union Photographique Française, photographe | CC0 |

## Measurements
2.40 m to the coping's foot (a man's reach), 0.45 m thick.

- size (m): 3.04 x 2.65 x 0.63
- wall 2.30 + coping to 2.50
- plinth course 0.30
- pier 0.55 wide, its cap to 2.65

## Visible details
- [x] M plinth, wall, coping, pier and cap, rubble showing (R1)
- [ ] M a tiled coping instead of stone for the hill's villas (R2)
- [ ] B damp rising, plaster falling (the kit), moss on the coping (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plaster | lime plaster | the rubble |  | falls off in patches |
| stone | coping, plinth, pier |  |  | moss |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 200 | 1 | 30 m |
| 1 | 80 | 1 | 100 m |
| 2 | 50 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/garden_wall_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py garden_wall --round=1`)
Differences from the references:
- no square-on photo of a garden wall yet: one to fetch for round 2
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
