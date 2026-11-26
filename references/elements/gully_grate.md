# gully_grate — the double gully grate at the kerb (S155)

Family: `tools/models/props/road.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py gully_grate` · sketch: `python tools/models/props.py gully_grate --sketch` · rack: `--prop-rack=gully_grate` · review: `python tools/models/review.py gully_grate --round=N`

Where the gutter drains: two square cast-iron grates side by side in a concrete surround, flush with the road (y = 0 its surface), each a frame, a bar down its middle and bars between seven rows of slots, the lifting slot, the dark pit under them.

## References
Wikimedia Commons, `references/elements/gully_grate/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `double.jpg` | **the main reference**, from above: the two grates, their slots and lifting holes, the concrete round them, litter | [ManholeCoverParis2015g.JPG](https://commons.wikimedia.org/wiki/File:ManholeCoverParis2015g.JPG), Vysotsky | CC BY-SA 4.0 |

## Measurements
The common 400 mm grate; double.jpg's slots 12 x 2 cm against the cigarette end in it.

- size (m): 1.00 x 0.16 x 0.54
- grates 0.40 square, 0.06 apart, 35 mm thick
- seven rows, slots 2.2 cm
- surround 0.07 broad

## Visible details
- [x] M frames, middle bars, bars between the slots, lifting slot, pit, surround (R1)
- [ ] M the bars' fine diagonal ribs, the hinge lugs (R2)
- [ ] B rust, leaves and litter in the slots (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| grate | bare cast iron |  | rust | polished by tyres |
| concrete | the surround |  |  | cracks |
| hole | the pit |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 400 | 1 | 12 m |
| 1 | 360 | 1 | 30 m |
| 2 | 220 | 1 | 80 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/gully_grate_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py gully_grate --round=1`)
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
