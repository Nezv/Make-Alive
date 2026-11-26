# vending_machine — the snack machine (S193)

Family: `tools/models/props/office.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py vending_machine` · sketch: `python tools/models/props.py vending_machine --sketch` · rack: `--prop-rack=vending_machine` · review: `python tools/models/review.py vending_machine --round=N`

The snack machine: a red cabinet; behind its window five shelves of spiral coils holding products (seeded colours, no brands); the panel on the right with a lit display, a keypad, the coin and note slots, the return; a lit card above it; the pick-up flap at the foot. The window's glass shows only on the far LOD until a see-through material exists.

## References
Wikimedia Commons, `references/elements/vending_machine/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
0.90 x 1.83 x 0.80.

- size (m): 0.90 x 1.83 x 0.82
- window 0.58 x 1.31
- coils 7 cm across

## Visible details
- [x] M cabinet, window frame, shelves, coils, goods, panel, keypad, slots, flap (R1)
- [ ] B the glass smashed and the goods looted (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | red painted steel |  | rust | scratches |
| goods | products (seven colours) |  |  |  |
| panel | display (glows) |  |  |  |
| lit | lit card (glows) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 4320 | 1 | 15 m |
| 1 | 680 | 1 | 45 m |
| 2 | 140 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/vending_machine_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py vending_machine --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; fetch office photos for round 2
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
