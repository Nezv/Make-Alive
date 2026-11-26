# tube_light — the two-tube batten (S194)

Family: `tools/models/props/fittings.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tube_light` · sketch: `python tools/models/props.py tube_light --sketch` · rack: `--prop-rack=tube_light` · review: `python tools/models/review.py tube_light --round=N`

The ceiling light of offices and wards: a steel batten with its end caps and two tubes lit by the emission map, hung on two chains from hooks in the ceiling. The ceiling is y = 0: everything hangs below.

## References
Wikimedia Commons, `references/elements/tube_light/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `batten.jpg` | **the main reference**: a two-tube batten lit, its end caps | [Fluorescent light strip 2 tube.JPG](https://commons.wikimedia.org/wiki/File:Fluorescent_light_strip_2_tube.JPG), Chetvorno | CC0 |
| `louvre.jpg` | a recessed louvre panel of the same kind | [Fluorescent light fixture.JPG](https://commons.wikimedia.org/wiki/File:Fluorescent_light_fixture.JPG), Georg Pik | CC0 |

## Measurements
The common 1.2 m (36 W) tube in a 1.27 m batten.

- size (m): 1.27 x 0.56 x 0.14
- batten 1.27 x 0.06 x 0.14
- tubes 26 mm
- chains 0.45

## Visible details
- [x] M body, end caps, tubes, chains, hooks (R1)
- [ ] M a diffuser for some, the starters (R2)
- [ ] B dead insects, yellowed caps, dust (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | white steel |  | rust |  |
| tube | lit tubes |  |  |  |
| chain | chain |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1300 | 1 | 12 m |
| 1 | 200 | 1 | 35 m |
| 2 | 40 | 1 | 100 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; lit / dead / flickering / hanging by one chain are S108's.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tube_light_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tube_light --round=1`)
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
