# iv_stand — the drip stand (S211)

Family: `tools/models/props/hospital.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py iv_stand` · sketch: `python tools/models/props.py iv_stand --sketch` · rack: `--prop-rack=iv_stand` · review: `python tools/models/review.py iv_stand --round=N`

The drip stand: five legs on castors, the pole with its height clamp and the thinner upper pole, four hooks with turned-up ends, a bag hung on one, its line hanging down.

## References
Wikimedia Commons, `references/elements/wheelchair/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `corridor.jpg` | IV poles on the transport chairs: the hooks, the pole | [Wheelchairs in a hospital corridor.jpg](https://commons.wikimedia.org/wiki/File:Wheelchairs_in_a_hospital_corridor.jpg), Ibex73 | CC BY-SA 4.0 |

## Measurements
The common stand: 2.05 m, its base 0.60 across.

- size (m): 0.59 x 2.07 x 0.65
- legs 0.30 out, castors 0.08
- pole 28 mm to 1.30, then 20 mm
- bag 0.12 x 0.24

## Visible details
- [x] M legs, castors, pole, clamp, hooks, bag, line (R1)
- [ ] M the bag's port and label, the clamp's knob (R2)
- [ ] B scratches, a bag of blood (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| chrome | chrome |  | rust |  |
| grey | the legs |  |  |  |
| bag | clear bag |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1150 | 1 | 15 m |
| 1 | 850 | 1 | 40 m |
| 2 | 500 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/iv_stand_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py iv_stand --round=1`)
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
