# tarp — a blue tarp thrown over a pile (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tarp` · sketch: `python tools/models/props.py tarp --sketch` · rack: `--prop-rack=tarp` · review: `python tools/models/review.py tarp --round=N`

A blue tarp thrown over two crates and a drum: lying on them, sagging between them (a soft maximum of the shapes under it), falling in folds to the ground; its eyelets along the hem, a rope from two corners to pegs.

## References
Wikimedia Commons, `references/elements/tarp/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `draped.jpg` | a tarp draped over things: how it folds and sags | [Draped tarp in the factory area on Furilden.jpg](https://commons.wikimedia.org/wiki/File:Draped_tarp_in_the_factory_area_on_Furilden.jpg), W.carter | CC BY-SA 4.0 |

## Measurements
A 3 x 2 m tarp; the pile under it up to 0.92 m.

- size (m): 3.30 x 0.92 x 2.42
- tarp 2.6 x 2.1 m laid
- pegs 0.35 out from the corners

## Visible details
- [x] M sheet over the pile, eyelets, ropes, pegs (R1)
- [ ] M folds where the hem lies on the ground (R2)
- [ ] B a green or a grey one; holes torn (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| tarp | blue polythene |  |  | dirt, puddles |
| rope | rope |  |  |  |
| galv | eyelets, pegs |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3750 | 1 | 20 m |
| 1 | 1160 | 1 | 60 m |
| 2 | 360 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tarp_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tarp --round=1`)
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
