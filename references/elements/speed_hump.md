# speed_hump — the flat-topped speed hump (S155)

Family: `tools/models/props/road.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py speed_hump` · sketch: `python tools/models/props.py speed_hump --sketch` · rack: `--prop-rack=speed_hump` · review: `python tools/models/review.py speed_hump --round=N`

A trapezoidal hump across a 3.5 m lane: two 1 m ramps rising 10 cm to a 2.5 m plateau, their foot and head eased, white teeth painted on each ramp with their points up the slope. y = 0 is the road's surface; the lane runs along z.

## References
Wikimedia Commons, `references/elements/speed_hump/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `teeth.jpg` | **the main reference**: a hump with its white teeth on a street of houses, the bollards at its side | [Ralentisseur de type dos-d'âne et passage piétons - Aix-les-Bains.jpg](https://commons.wikimedia.org/wiki/File:Ralentisseur_de_type_dos-d%27%C3%A2ne_et_passage_pi%C3%A9tons_-_Aix-les-Bains.jpg), Mathis Brancquart | CC BY-SA 4.0 |

## Measurements
The French standard's trapezoidal hump: 10 cm high, ramps of 1 to 1.4 m; teeth.jpg's lane 3.5 m against the car beyond.

- size (m): 3.50 x 0.10 x 4.50
- ramps 1.00, plateau 2.50, 0.10 high
- teeth 0.50 wide at their base, seven across

## Visible details
- [x] M ramps, plateau, the eased edges (R1)
- [x] B the teeth (R1)
- [ ] M the kerb's ends where it meets the pavement (R2)
- [ ] B worn paint in the wheel tracks, patched asphalt (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| asphalt | dark asphalt |  |  | cracks, patches |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 40 | 1 | 40 m |
| 1 | 14 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/speed_hump_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py speed_hump --round=1`)
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
