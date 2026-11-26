# emergency_light — the emergency light block (S194)

Family: `tools/models/props/fittings.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py emergency_light` · sketch: `python tools/models/props.py emergency_light --sketch` · rack: `--prop-rack=emergency_light` · review: `python tools/models/review.py emergency_light --round=N`

The BAES d'ambiance of French public buildings: a white box on the wall at 2.3 m, its diffuser underneath (lit), the green charge lamp on its face, the trunking bringing its cable down from the ceiling.

## References
Wikimedia Commons, `references/elements/emergency_light/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
0.33 x 0.12 x 0.07.

- size (m): 0.33 x 0.67 x 0.07
- at 2.3 m

## Visible details
- [x] M box, diffuser, charge lamp, trunking (R1)
- [ ] B dead, hanging off the wall (S108)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plastic | white plastic |  |  | yellowed |
| tube | diffuser (glows) |  |  |  |
| exit | charge lamp (glows) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 110 | 1 | 12 m |
| 1 | 60 | 1 | 36 m |
| 2 | 30 | 1 | 110 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/emergency_light_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py emergency_light --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; photos for round 2
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
