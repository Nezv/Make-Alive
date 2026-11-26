# rope_box — the réverbère rope's wall box (S167)

Family: `tools/models/props/lamps.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py rope_box` · sketch: `python tools/models/props.py rope_box --sketch` · rack: `--prop-rack=rope_box` · review: `python tools/models/review.py rope_box --round=N`

The locked iron box on a house's wall where the réverbère's rope is tied off: a box with its door, hinges and lock, a pulley on a bracket over it, the rope coming down over the pulley into the box. Wall z = 0, the box's foot y = 0.

## References
Wikimedia Commons, `references/elements/rope_box/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The box 0.24 x 0.46 x 0.12, at about 2.5 m on the wall.

- size (m): 0.24 x 1.26 x 0.31
- pulley 0.09 across, 0.18 over the box

## Visible details
- [x] M box, door, hinges, lock, bracket, pulley, rope (R1)
- [ ] M the winch inside when open (R2)
- [ ] B rust, a forced door (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | black iron |  | rust |  |
| brass | lock |  |  |  |
| rope | hemp |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 180 | 1 | 12 m |
| 1 | 140 | 1 | 40 m |
| 2 | 14 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/rope_box_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py rope_box --round=1`)
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
