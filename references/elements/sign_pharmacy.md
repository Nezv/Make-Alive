# sign_pharmacy — the pharmacy's green cross (S160)

Family: `tools/models/props/signs_shops.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_pharmacy` · sketch: `python tools/models/props.py sign_pharmacy --sketch` · rack: `--prop-rack=sign_pharmacy` · review: `python tools/models/review.py sign_pharmacy --round=N`

The green cross of a pharmacy: a box cross, each face lit green inside a dark rim, on an arm from the wall, its cable sagging from the wall into it.

## References
Wikimedia Commons, `references/elements/sign_pharmacy/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `cross_lit.jpg` | the lit face of a cross close up (its LEDs; ours a plain lit face) | [Croix verte - Pharmacie - Route de la Reine - (Boulogne-Billancourt, FR92) - 27-12-2023.jpg](https://commons.wikimedia.org/wiki/File:Croix_verte_-_Pharmacie_-_Route_de_la_Reine_-_(Boulogne-Billancourt,_FR92)_-_27-12-2023.jpg), Manchesterunited1234 | CC BY-SA 4.0 |

## Measurements
French pharmacy crosses are 0.6 to 1.0 m: 0.80 m taken.

- size (m): 0.15 x 0.80 x 0.95
- cross 0.80 across, arms 0.27, 0.13 thick
- its middle 0.55 out from the wall

## Visible details
- [x] M case, two lit faces, arm and plate, cable (R1)
- [ ] M the faces' grid of lights, a caduceus (R2)
- [ ] B dirt, a dead quarter (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| green | green, lit |  |  |  |
| case | dark grey |  | rust |  |
| cable | black |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 350 | 1 | 30 m |
| 1 | 220 | 1 | 100 m |
| 2 | 180 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; lit / dead / flickering per instance (S046, S108).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_pharmacy_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sign_pharmacy --round=1`)
Differences from the references:
- no photo of a whole cross on its arm yet: one to fetch for round 2
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
