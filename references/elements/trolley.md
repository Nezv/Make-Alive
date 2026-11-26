# trolley — the supermarket trolley (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py trolley` · sketch: `python tools/models/props.py trolley --sketch` · rack: `--prop-rack=trolley` · review: `python tools/models/review.py trolley --round=N`

A supermarket trolley: the wire basket tapered for nesting, its bottom rising to the front, rims and rails, the push handle with its yellow grip and the child seat's flap at the back, a plastic panel on the side, the chassis rails on four casters, the lower tray. Pushed from +Z.

## References
Wikimedia Commons, `references/elements/trolley/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `side.jpg` | **the main reference**, side on: the basket's taper and bottom, the handle, the seat flap, the chassis, the casters | [Shopping cart of Prisma shop.JPG](https://commons.wikimedia.org/wiki/File:Shopping_cart_of_Prisma_shop.JPG), Dmitry G | Public domain |

## Measurements
The common 100 litre trolley: the handle at 1.04, the basket 0.95 long (side.jpg against the wall's panels).

- size (m): 0.61 x 1.06 x 0.99
- basket 0.88 long, 0.54 wide at the back, 0.44 at the front; its bottom 0.50 at the back, 0.62 at the front
- wires 7 mm every 4.5 cm
- casters 11 cm

## Visible details
- [x] M basket wires and rails, handle and grip, seat flap, side panel, chassis, casters, tray (R1)
- [ ] M the casters' forks and swivels, the coin lock (R2)
- [ ] B scratched green, rust where it's chipped (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| green | green coated wire |  | steel | chips, rust |
| yellow | the plastic grip and flap |  |  |  |
| tyre | casters |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1300 | 1 | 15 m |
| 1 | 700 | 1 | 40 m |
| 2 | 300 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; overturned is placing (S048).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/trolley_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py trolley --round=1`)
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
