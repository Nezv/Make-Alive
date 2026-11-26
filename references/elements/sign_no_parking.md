# sign_no_parking — the no parking sign (B6a1) (S169)

Family: `tools/models/props/signs_street.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_no_parking` · sketch: `python tools/models/props.py sign_no_parking --sketch` · rack: `--prop-rack=sign_no_parking` · review: `python tools/models/review.py sign_no_parking --round=N`

One of the family's road signs (made as `sign_stop`'s card says: an aluminium plate with a rolled edge, the face painted by position so the kit's wear goes over it, rails and clamps, the galvanised pole). The family's references are on `sign_stop`'s card; the face follows the French standard. A blue disc in a red ring, a red bar from its top left to its bottom right.

## References
Wikimedia Commons, `references/elements/sign_stop/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The standard's 650 mm disc.

- size (m): 0.66 x 2.99 x 0.11
- disc 0.65 across, red ring 5.5 cm
- bar 7 cm wide

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
| 0 | 700 | 1 | 25 m |
| 1 | 300 | 1 | 80 m |
| 2 | 150 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_no_parking_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sign_no_parking --round=1`)
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
