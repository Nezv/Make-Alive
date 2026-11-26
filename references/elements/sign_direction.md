# sign_direction — the white town direction signs (S169)

Family: `tools/models/props/signs_street.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_direction` · sketch: `python tools/models/props.py sign_direction --sketch` · rack: `--prop-rack=sign_direction` · review: `python tools/models/review.py sign_direction --round=N`

One of the family's road signs (made as `sign_stop`'s card says: an aluminium plate with a rolled edge, the face painted by position so the kit's wear goes over it, rails and clamps, the galvanised pole). The family's references are on `sign_stop`'s card; the face follows the French standard. Two white arrow-shaped plates, one over the other, a black edge and the destination in black: CENTRE VILLE, GARE ROUTIERE (the town's own places).

## References
Wikimedia Commons, `references/elements/sign_stop/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The standard's 1.0 m by 0.25 m town plates; the lower one's foot 2.20 over the pavement.

- size (m): 1.07 x 2.99 x 0.11
- plates 1.00 x 0.25, their points 0.12
- letters 7.5 cm

## Visible details
- [x] M plate, rolled edge, rails, clamps, pole, cap, collar (R1)
- [x] B the face by the standard (R1)
- [ ] M the rails' screws, the plate's back stamped (R2)
- [ ] B retroreflection, stickers, faded red, bullet holes (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| face | the painted face |  | aluminium | fades, chips |
| back | bare aluminium |  |  |  |
| galv | the pole |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 350 | 1 | 25 m |
| 1 | 250 | 1 | 80 m |
| 2 | 100 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_direction_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sign_direction --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- the destinations per instance (S046): the text is paint, one set per build for now

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
