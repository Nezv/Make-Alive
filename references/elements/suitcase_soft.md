# suitcase_soft — the old leather suitcase (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py suitcase_soft` · sketch: `python tools/models/props.py suitcase_soft --sketch` · rack: `--prop-rack=suitcase_soft` · review: `python tools/models/review.py suitcase_soft --round=N`

An old leather suitcase lying flat: the lid's seam round it, two straps with buckles, the handle, brass corner caps and locks.

## References
Wikimedia Commons, `references/elements/suitcase_hard/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `decayed.jpg` | an old suitcase gone to rot: its straps and corners | [Suitcase Decay (16186065183).jpg](https://commons.wikimedia.org/wiki/File:Suitcase_Decay_(16186065183).jpg), darkday from Brisbane, Australia | CC BY 2.0 |

## Measurements
The common old case: 0.66 x 0.42, 0.19 deep.

- size (m): 0.67 x 0.23 x 0.49
- straps 36 mm at ±0.18
- handle on the long side

## Visible details
- [x] M case, seam, straps and buckles, handle, locks, corner caps (R1)
- [ ] M the stitching, the handle's fixings (R2)
- [ ] B worn leather, labels, damp (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| leather | brown leather |  |  | scuffs, damp |
| strap | dark leather |  |  |  |
| brass | locks and corners |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 330 | 1 | 10 m |
| 1 | 230 | 1 | 30 m |
| 2 | 20 | 1 | 90 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/suitcase_soft_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py suitcase_soft --round=1`)
Differences from the references:
- no photo of a whole old suitcase yet: one to fetch for round 2
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
