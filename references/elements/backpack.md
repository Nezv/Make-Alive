# backpack — the hiking backpack (S153)

Family: `tools/models/props/carried.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py backpack` · sketch: `python tools/models/props.py backpack --sketch` · rack: `--prop-rack=backpack` · review: `python tools/models/review.py backpack --round=N`

The pack a dead player leaves (`Backpack`): the body widening to its foot, a top lid with a strap and buckle down the front, a front pocket with its zip, side pockets with a bottle in one, shoulder straps and the hip belt on the back, a grab loop.

## References
Wikimedia Commons, `references/elements/backpack/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `hiking.jpg` | **the main reference**: a hiking pack leaning on a wall: lid, pockets, straps, belt | [A backpack with trekking poles and shoes.jpg](https://commons.wikimedia.org/wiki/File:A_backpack_with_trekking_poles_and_shoes.jpg), SGrabarczuk (WMF) | CC BY-SA 4.0 |

## Measurements
A 40 litre pack: 0.58 tall, 0.34 wide, against the door handle in hiking.jpg.

- size (m): 0.52 x 0.61 x 0.37
- body 0.34 x 0.52 x 0.24, lid 0.07
- front pocket 0.24 x 0.21
- hip belt 0.08 deep

## Visible details
- [x] M body, lid, front pocket, lid strap and buckle, side pockets, bottle, shoulder straps, hip belt, grab loop, side buckles, zip (R1)
- [ ] M compression straps, the straps' padding, the zips' pulls (R2)
- [ ] B dirt, blood, the fabric's weave (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| pack | blue nylon |  |  | dirt |
| pack2 | dark nylon |  |  |  |
| strap | black webbing |  |  |  |
| metal | the bottle |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 500 | 1 | 8 m |
| 1 | 350 | 1 | 25 m |
| 2 | 30 | 1 | 60 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/backpack_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py backpack --round=1`)
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
