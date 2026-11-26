# plate_fr — the long French number plate (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py plate_fr` · sketch: `python tools/models/props.py plate_fr --sketch` · rack: `--prop-rack=plate_fr` · review: `python tools/models/review.py plate_fr --round=N`

The kit's plate: white, the blue band at the left with the ring of gold stars and F, the band at the right with the region number, JV-417-KM in black, on a black plastic holder with two rivets. Invented: the region 00 does not exist. Its front -Z.

## References
Wikimedia Commons, `references/elements/plate_fr/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `siv_transit.jpg` | **the main reference**, square-on: the bands, the stars, F, the letters' size and spacing (a temporary red plate; ours the common white) | [Immatriculation SIV transit temporaire AA-572-BF.jpg](https://commons.wikimedia.org/wiki/File:Immatriculation_SIV_transit_temporaire_AA-572-BF.jpg), JFŻ | CC BY-SA 3.0 |

## Measurements
The standard plate: 520 x 110 mm, bands 40 mm.

- size (m): 0.544 x 0.134 x 0.016
- plate 0.520 x 0.110 on a 0.544 x 0.134 holder
- letters fill the white field (0.41)

## Visible details
- [x] M plate, holder, rivets (R1)
- [x] B bands, stars, F, region, the code (R1)
- [ ] M the embossed letters (R2)
- [ ] B dirt, a bent corner (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plate | white reflective |  | aluminium | dirt |
| holder | black plastic |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 100 | 1 | 10 m |
| 1 | 26 | 1 | 40 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/plate_fr_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py plate_fr --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- the code per car, seeded (S046): one per build for now

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
