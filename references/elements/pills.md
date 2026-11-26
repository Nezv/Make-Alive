# pills — a bottle of painkillers (S153)

Family: `tools/models/props/carried.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py pills` · sketch: `python tools/models/props.py pills --sketch` · rack: `--prop-rack=pills` · review: `python tools/models/review.py pills --round=N`

An orange pill bottle with its white ridged cap and a paper label (printed rows, a red band, no brand), a few pills spilt beside it.

## References
Wikimedia Commons, `references/elements/pills/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bottle.jpg` | **the main reference**: the bottle, its cap and lip, pills beside it | [Clonazepam Pills and Pill Bottle.jpg](https://commons.wikimedia.org/wiki/File:Clonazepam_Pills_and_Pill_Bottle.jpg), ParentingPatch | CC BY-SA 3.0 |

## Measurements
The common 60 mm-high bottle, 52 mm across; ours 0.085 tall with the cap 0.107.

- size (m): 0.10 x 0.11 x 0.06
- bottle radius 0.026, 0.085 to the shoulder
- cap 0.022, its ridges

## Visible details
- [x] M bottle, cap with ridges, label, pills (R1)
- [x] B the label's rows and band (R1)
- [ ] M the cap's lip, the bottle's ring under it (R2)
- [ ] B scratches, the label peeling (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| orange | translucent orange (opaque here) |  |  |  |
| cap | white |  |  |  |
| label | paper |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 550 | 1 | 3 m |
| 1 | 190 | 1 | 8 m |
| 2 | 100 | 1 | 20 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/pills_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py pills --round=1`)
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
