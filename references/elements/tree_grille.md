# tree_grille — the cast-iron tree grate (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tree_grille` · sketch: `python tools/models/props.py tree_grille --sketch` · rack: `--prop-rack=tree_grille` · review: `python tools/models/review.py tree_grille --round=N`

The round grate at the foot of every street tree: concentric rings tied by radial bars inside a square plate, cast in two halves, the earth under its slots. Lies flush with the pavement: y = 0 is the pavement's top.

## References
Wikimedia Commons, `references/elements/tree_grille/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `round.jpg` | **the main reference**: a round grate from above, rings and bars, the tree in its middle | [Gitterrost fuer Baumschutz.jpg](https://commons.wikimedia.org/wiki/File:Gitterrost_fuer_Baumschutz.jpg), Hutschi | CC BY-SA 3.0 |
| `leaves.jpg` | a grate's bars close up, leaves in it | [Tree grate, Paris 30 October 2016.jpg](https://commons.wikimedia.org/wiki/File:Tree_grate,_Paris_30_October_2016.jpg), Guilhem Vellut from Paris, France | CC BY 2.0 |

## Measurements
round.jpg: the paving's slabs; the grate 1.5 m across the square, the hole 0.5 m for the trunk.

- size (m): 1.56 x 0.05 x 1.56
- rings from 0.24 to 0.72, 7 of them; 24 bars
- square plate 1.56; cast 30 mm thick

## Visible details
- [x] M rings, bars, the square plate's frame and corners, the halves' joint and lifting holes (R1)
- [ ] M the rings' slots in the corner plates (R2)
- [ ] B rust in the slots, leaves, cigarette ends (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| cast | bare cast iron | — | rust | polished by feet |
| earth | earth under |  |  |  |
| drain | dark joint |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2600 | 1 | 12 m |
| 1 | 1200 | 1 | 30 m |
| 2 | 700 | 1 | 80 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tree_grille_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tree_grille --round=1`)
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
