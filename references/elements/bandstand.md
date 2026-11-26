# bandstand — the jardin public's bandstand (S190)

Family: `tools/models/props/park.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bandstand` · sketch: `python tools/models/props.py bandstand --sketch` · rack: `--prop-rack=bandstand` · review: `python tools/models/review.py bandstand --round=N`

The octagonal kiosque à musique: a stone base 0.9 m high with its cornice and steps on the front, a wooden floor, eight slender cast-iron columns, a railing between them, curved brackets and a frieze under the eaves, the green zinc tent roof with its pale ceiling, the lantern and finial.

## References
Wikimedia Commons, `references/elements/bandstand/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `small.jpg` | **the main reference**: a small octagonal bandstand: base, columns, railing, green roof, lantern | [Jardin public d'Albert (kiosque à musique) 1.jpg](https://commons.wikimedia.org/wiki/File:Jardin_public_d%27Albert_(kiosque_%C3%A0_musique)_1.jpg), Bycro | CC BY-SA 4.0 |
| `large.jpg` | a larger one with a lace frieze and a dome | [Kiosque à musique du Jardin Public de Cambrai.jpg](https://commons.wikimedia.org/wiki/File:Kiosque_%C3%A0_musique_du_Jardin_Public_de_Cambrai.jpg), JackyM59 | CC BY-SA 4.0 |

## Measurements
small.jpg: the base 0.9 m against the people's knees beside it; 6 m across.

- size (m): 6.19 x 5.95 x 7.01
- base radius 3.0, 0.90 high
- columns 2.70, the eave at 3.75, the lantern at 5.0

## Visible details
- [x] M base, steps, floor, columns, brackets, railing, frieze, roof, ceiling, lantern, finial (R1)
- [ ] M the frieze's lace, the columns' capitals, the railing's scrolls (R2)
- [ ] B moss on the base, rust, chairs tipped over (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | moss |
| iron | green cast iron | red lead | rust |  |
| zinc | green zinc |  |  |  |
| ceiling | cream boards |  |  | flaking |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2700 | 1 | 40 m |
| 1 | 1800 | 1 | 120 m |
| 2 | 1000 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bandstand_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bandstand --round=1`)
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
