# wing_mirror — a door mirror (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py wing_mirror` · sketch: `python tools/models/props.py wing_mirror --sketch` · rack: `--prop-rack=wing_mirror` · review: `python tools/models/review.py wing_mirror --round=N`

The kit's door mirror: the sail fixed to the door (x = 0), the arm, the housing in the car's colour swept back at its tip, the glass in its rim facing +Z (back along the car).

## References
Wikimedia Commons, `references/elements/wing_mirror/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `mirror.jpg` | **the main reference**: a door mirror from inside the car: housing, glass, sail | [Car wing mirror.jpg](https://commons.wikimedia.org/wiki/File:Car_wing_mirror.jpg), Santeri Viinamäki | CC BY-SA 4.0 |

## Measurements
A small car's mirror: the glass 0.16 x 0.10.

- size (m): 0.24 x 0.12 x 0.10
- housing 0.18 x 0.12 x 0.09

## Visible details
- [x] M sail, arm, housing, rim, glass (R1)
- [ ] M the indicator repeater (R2)
- [ ] B cracked glass, hanging by its cable as a state (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| paint | the car's colour |  |  |  |
| housing | black plastic |  |  |  |
| glass | mirror |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 110 | 1 | 10 m |
| 1 | 46 | 1 | 40 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/wing_mirror_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py wing_mirror --round=1`)
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
