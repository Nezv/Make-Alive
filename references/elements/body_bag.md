# body_bag — a body bag on the ground (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py body_bag` · sketch: `python tools/models/props.py body_bag --sketch` · rack: `--prop-rack=body_bag` · review: `python tools/models/review.py body_bag --round=N`

A black body bag lying full on the street: the shape of the body showing through it (feet up, legs, hips, chest, the neck's dip, the head), the flat margin of the bag round it, the zip along the top, its pull, three handles each side.

## References
Wikimedia Commons, `references/elements/body_bag/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bag.jpg` | an empty one held open: the zip, the size | [Body bag.jpg](https://commons.wikimedia.org/wiki/File:Body_bag.jpg), Mass Communication Specialist 1st Class Bruce McVicar, US Navy | Public domain |
| `street.jpg` | a black one lying on paving, sprayed on | [BodyBagRoussouSt1.jpg](https://commons.wikimedia.org/wiki/File:BodyBagRoussouSt1.jpg), Infrogmation | CC BY 2.5 |

## Measurements
The common adult bag: 2.2 x 0.8 m flat.

- size (m): 2.20 x 0.23 x 0.81
- body under it up to 0.22 high at the chest
- zip 0.07 off the middle

## Visible details
- [x] M the bag, the body's shape, zip, pull, handles (R1)
- [ ] M creases where it folds over the feet and the head (R2)
- [ ] B a white one; a row of them (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| bagblack | black PVC |  |  | dust, blood at the head |
| zip | zip and webbing |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1500 | 1 | 15 m |
| 1 | 400 | 1 | 45 m |
| 2 | 90 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/body_bag_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py body_bag --round=1`)
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
