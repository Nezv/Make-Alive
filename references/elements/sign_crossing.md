# sign_crossing — the pedestrian crossing sign (C20a) (S169)

Family: `tools/models/props/signs_street.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_crossing` · sketch: `python tools/models/props.py sign_crossing --sketch` · rack: `--prop-rack=sign_crossing` · review: `python tools/models/review.py sign_crossing --round=N`

One of the family's road signs (made as `sign_stop`'s card says: an aluminium plate with a rolled edge, the face painted by position so the kit's wear goes over it, rails and clamps, the galvanised pole). The family's references are on `sign_stop`'s card; the face follows the French standard. A blue square, a white triangle, a black walker on the zebra's stripes.

## References
Wikimedia Commons, `references/elements/sign_stop/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The standard's 500 mm square.

- size (m): 0.51 x 2.99 x 0.11
- square 0.50
- triangle 0.42 across its foot, the walker 0.23 tall

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
| 0 | 400 | 1 | 25 m |
| 1 | 250 | 1 | 80 m |
| 2 | 100 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_crossing_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sign_crossing --round=1`)
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
