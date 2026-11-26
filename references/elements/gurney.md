# gurney — the transport trolley (S211)

Family: `tools/models/props/hospital.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py gurney` · sketch: `python tools/models/props.py gurney --sketch` · rack: `--prop-rack=gurney` · review: `python tools/models/review.py gurney --round=N`

The hospital's transport trolley: a deck frame on two columns over a base on four castors, a lower shelf, the mattress with its head raised on the back rest, a sheet, side rails raised, the IV pole's socket, push bars at both ends.

## References
Wikimedia Commons, `references/elements/gurney/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `recovery.jpg` | a patient on a trolley in a recovery room: the mattress, the raised head | [Woman on gurney.jpg](https://commons.wikimedia.org/wiki/File:Woman_on_gurney.jpg), Bill Branson (Photographer) | Public domain |

## Measurements
The standard trolley: 1.95 x 0.68, the mattress at 0.78.

- size (m): 0.72 x 1.04 x 2.07
- deck at 0.70, mattress 0.10
- rails at +0.12 and +0.25 over the mattress
- castors 0.15

## Visible details
- [x] M frame, columns, base, shelf, castors, mattress and raised head, sheet, rails, socket, push bars (R1)
- [ ] M the columns' hydraulics and pedals, the rails' latches (R2)
- [ ] B stains, blood, the mattress torn (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| grey | grey steel |  | rust |  |
| mattress | blue vinyl |  |  | tears |
| sheet | white sheet |  |  | blood |
| chrome | rails |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1100 | 1 | 20 m |
| 1 | 900 | 1 | 60 m |
| 2 | 450 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/gurney_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py gurney --round=1`)
Differences from the references:
- recovery.jpg shows little of the frame: a full trolley photo to fetch for round 2
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
