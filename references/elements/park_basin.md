# park_basin — the round basin (S190)

Family: `tools/models/props/park.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py park_basin` · sketch: `python tools/models/props.py park_basin --sketch` · rack: `--prop-rack=park_basin` · review: `python tools/models/review.py park_basin --round=N`

The round basin of a jardin public, 6 m across: a broad stone roll on a low wall, its inner face going down into the water; still dark water; a vasque on a pedestal in the middle, its water in the bowl, the jet's nozzle.

## References
Wikimedia Commons, `references/elements/park_basin/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bassin127.jpg` | a big basin with its statue fountain in the middle | [Paris 6e Jardin du Luxembourg Bassin 127.jpg](https://commons.wikimedia.org/wiki/File:Paris_6e_Jardin_du_Luxembourg_Bassin_127.jpg), GFreihalter | CC BY-SA 3.0 |
| `bassin2016.jpg` | the rim's roll and the water close to it | [Paris 75006 Jardin du Luxembourg Bassin 20160502.jpg](https://commons.wikimedia.org/wiki/File:Paris_75006_Jardin_du_Luxembourg_Bassin_20160502.jpg), Wulf Alex | CC0 |
| `seeberger.jpg` | 1930s: children at the rim, its section | [Séeberger - Paris - grand bassin du jardin du Luxembourg 02.jpg](https://commons.wikimedia.org/wiki/File:S%C3%A9eberger_-_Paris_-_grand_bassin_du_jardin_du_Luxembourg_02.jpg), Séeberger frères | Licence Ouverte |

## Measurements
6 m across, rim 0.5 m high.

- size (m): 6.12 x 1.64 x 6.12
- rim roll 0.36 deep
- vasque 1.6 m across, 1.3 m high over the water

## Visible details
- [x] M rim, water, pedestal, bowl, nozzle (R1)
- [ ] M the water's moving surface (shader) and the jet (R2)
- [ ] B dry and cracked, leaves and litter in it (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | pale limestone |  |  | moss, stains |
| water | dark water |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1990 | 1 | 40 m |
| 1 | 1170 | 1 | 120 m |
| 2 | 180 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/park_basin_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py park_basin --round=1`)
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
