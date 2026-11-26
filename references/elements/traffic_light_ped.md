# traffic_light_ped — the pedestrians' signal (S168)

Family: `tools/models/props/traffic.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py traffic_light_ped` · sketch: `python tools/models/props.py traffic_light_ped --sketch` · rack: `--prop-rack=traffic_light_ped` · review: `python tools/models/review.py traffic_light_ped --round=N`

The pedestrians' head on its own pole: two dark lenses, the red man standing over the green man walking, each a lit figure.

## References
Wikimedia Commons, `references/elements/traffic_light/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `short_pole.jpg` | the same family's head and visors (the pedestrians' head beside the crossings) | [Feux Tricolores Avenue Victor Hugo Fontenay Bois 2.jpg](https://commons.wikimedia.org/wiki/File:Feux_Tricolores_Avenue_Victor_Hugo_Fontenay_Bois_2.jpg), Chabe01 | CC BY-SA 4.0 |

## Measurements
The same 200 mm lenses as the drivers' head.

- size (m): 0.30 x 2.64 x 0.56
- head 0.30 x 0.60, its top 2.55
- figures 0.13 tall

## Visible details
- [x] M pole, head, dark lenses, visors, the two figures (R1)
- [ ] B grime on the lenses (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| lens | dark |  |  |  |
| red / green | the figures, lit |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 750 | 1 | 25 m |
| 1 | 500 | 1 | 80 m |
| 2 | 200 | 1 | 250 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/traffic_light_ped_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py traffic_light_ped --round=1`)
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
