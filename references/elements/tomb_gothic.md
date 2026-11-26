# tomb_gothic — the gothic family chapel (S189)

Family: `tools/models/props/cemetery.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tomb_gothic` · sketch: `python tools/models/props.py tomb_gothic --sketch` · rack: `--prop-rack=tomb_gothic` · review: `python tools/models/review.py tomb_gothic --round=N`

A neo-gothic family chapel: a stone cell on its plinth and step, a steep stone roof, the front gable's coping with crockets and a cross, buttresses set diagonally at the corners each carrying a pinnacle, a pointed doorway in a moulded frame under a gablet with the family's name (invented, painted by position), lancets down the sides, the iron and glass door (part `door`, opening out).

## References
Wikimedia Commons, `references/elements/tomb_gothic/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `four_chapels.jpg` | four chapels in a row: the left one and the right one are gothic (pinnacles, crockets, pointed doors, the rose) | [Père-Lachaise - quatre chapelles funéraires.jpg](https://commons.wikimedia.org/wiki/File:P%C3%A8re-Lachaise_-_quatre_chapelles_fun%C3%A9raires.jpg), Pierre-Yves Beaudouin | CC BY-SA 3.0 |

## Measurements
The small chapels of the alleys: 1.6 x 2.2 m, walls 2.4 m, the ridge 3.8 m, pinnacles to 4.2.

- size (m): 2.00 x 4.22 x 2.84
- door 0.72 wide, springing at 1.45
- pinnacles 0.16 square, 0.95 tall

## Visible details
- [x] M cell, roof, coping, crockets, buttresses, pinnacles, doorway, gablet, cross, lancets, door (R1)
- [ ] M the rose window over the door, tracery in the door's iron (R2)
- [ ] B the taller chapel of the right of four_chapels as a variant (R2)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | pale limestone |  |  | soot, moss, black streaks |
| dark_stone | the roof's stone slabs |  |  | lichen |
| door | green-blue iron door | red primer | rust | rust |
| glass | dark glass |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1130 | 1 | 30 m |
| 1 | 700 | 1 | 90 m |
| 2 | 240 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| door | its left edge (-0.36, 0.30, -1.10) | rotate 100° about +Y: out |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tomb_gothic_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tomb_gothic --round=1`)
Differences from the references:
- four_chapels' gothic chapels are richer: tracery, a rose, finer pinnacles (round 2)
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
