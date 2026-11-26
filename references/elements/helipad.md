# helipad — the hospital's rooftop helipad (S208)

Family: `tools/models/props/helipad.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py helipad` · sketch: `python tools/models/props.py helipad --sketch` · rack: `--prop-rack=helipad` · review: `python tools/models/review.py helipad --round=N`

The raised helipad over the hospital's roof: a 16 m deck on a grid of steel beams and legs 1.6 m over the roof; the H in its circle, the yellow touchdown ring and the edge line painted (by position); perimeter lights along every edge (lit green); the safety netting sloping out 1.5 m on brackets all round with its rim tube and strands; the windsock on its red mast at a corner; the access stair down the -Z side over a walkway through the net; the red fire hose box.

## References
Wikimedia Commons, `references/elements/helipad/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Sized for the helicopter of S154 (rotor 11 m): a 16 m deck.

- size (m): 19.06 x 5.70 x 21.62
- touchdown ring 10 m
- net 1.5 m
- windsock at 3.9 m

## Visible details
- [x] M deck, frame, legs, netting, rim, lights, windsock, stair, walkway, hose box (R1)
- [ ] M the stair's gate, the windsock's flood (R2)
- [ ] B worn paint, skid marks, rust on the frame (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| deck | dark deck coating |  |  | skid marks |
| steel | galvanised frame and net |  | rust |  |
| lamp | edge lights (glow) |  |  |  |
| sock | orange windsock |  |  | faded |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2850 | 1 | 60 m |
| 1 | 1320 | 1 | 200 m |
| 2 | 480 | 1 | 600 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/helipad_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py helipad --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; rooftop helipads for round 2
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
