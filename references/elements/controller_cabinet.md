# controller_cabinet — the junction's controller cabinet (S168)

Family: `tools/models/props/traffic.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py controller_cabinet` · sketch: `python tools/models/props.py controller_cabinet --sketch` · rack: `--prop-rack=controller_cabinet` · review: `python tools/models/review.py controller_cabinet --round=N`

The grey cabinet that runs a junction: a steel box on a concrete plinth, its door with hinges and lock, vents at the foot and the head, a lid that sheds the rain.

## References
Wikimedia Commons, `references/elements/traffic_light/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `short_pole.jpg` | the poles it feeds (the cabinet stands at the corner) | [Feux Tricolores Avenue Victor Hugo Fontenay Bois 2.jpg](https://commons.wikimedia.org/wiki/File:Feux_Tricolores_Avenue_Victor_Hugo_Fontenay_Bois_2.jpg), Chabe01 | CC BY-SA 4.0 |

## Measurements
From the street furniture's standard: 0.80 x 1.30 x 0.40 on a 0.12 m plinth.

- size (m): 0.90 x 1.47 x 0.50
- door inset 0.72 x 1.20
- five vent slots at the foot and the head

## Visible details
- [x] M plinth, box, sloping lid, door, hinges, lock, vents (R1)
- [ ] B stickers, posters, tags, rust at the foot (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| cabinet | pale grey | primer | rust | tags and stickers |
| concrete | the plinth |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 300 | 1 | 15 m |
| 1 | 200 | 1 | 40 m |
| 2 | 40 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/controller_cabinet_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py controller_cabinet --round=1`)
Differences from the references:
- no photo of a cabinet yet: one to fetch for round 2
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
