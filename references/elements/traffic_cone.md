# traffic_cone — the road cone (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py traffic_cone` · sketch: `python tools/models/props.py traffic_cone --sketch` · rack: `--prop-rack=traffic_cone` · review: `python tools/models/review.py traffic_cone --round=N`

The 0.75 m road cone: a black square foot with chamfered corners, the orange cone, two white reflective bands.

## References
Wikimedia Commons, `references/elements/traffic_cone/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `worn.jpg` | **the main reference**: a worn cone at a kerb: its foot, bands, dirt | [Orange traffic cone that has seen better days.jpg](https://commons.wikimedia.org/wiki/File:Orange_traffic_cone_that_has_seen_better_days.jpg), Ser Amantio di Nicolao | CC BY-SA 4.0 |
| `stack.jpg` | cones by a wall | [Traffic cones london.jpg](https://commons.wikimedia.org/wiki/File:Traffic_cones_london.jpg), Secretlondon | CC BY-SA 3.0 |

## Measurements
The common 750 mm cone with its 380 mm foot.

- size (m): 0.38 x 0.75 x 0.38
- foot 0.38 square, 30 mm
- cone from 0.15 radius to 0.025
- bands 0.30-0.40 and 0.50-0.58

## Visible details
- [x] M foot, cone, bands (R1)
- [ ] M the foot's lip, the cone's hollow (R2)
- [ ] B scuffs, tyre marks, dirt (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| orange | orange PVC |  |  | dirt, fade |
| band | white reflective |  |  | scuffs |
| base | black rubber |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 280 | 1 | 12 m |
| 1 | 170 | 1 | 40 m |
| 2 | 30 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/traffic_cone_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py traffic_cone --round=1`)
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
