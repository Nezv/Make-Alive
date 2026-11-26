# barrier_concrete — the concrete safety barrier (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py barrier_concrete` · sketch: `python tools/models/props.py barrier_concrete --sketch` · rack: `--prop-rack=barrier_concrete` · review: `python tools/models/review.py barrier_concrete --round=N`

The precast concrete barrier: the New Jersey profile (a steep foot, a sloping middle, a narrow top), 2.0 m long, two lifting holes through its top, drain notches at its foot, the joint key standing out of one end.

## References
Wikimedia Commons, `references/elements/barrier_concrete/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `jersey.jpg` | **the main reference**: the profile end-on, the lifting holes, the joint | [BarreiraNewJersey.JPG](https://commons.wikimedia.org/wiki/File:BarreiraNewJersey.JPG), CorreiaPM | Public domain |
| `painted.jpg` | a short one painted with red and yellow stripes | [Concrete barrier 20180625.jpg](https://commons.wikimedia.org/wiki/File:Concrete_barrier_20180625.jpg), Santeri Viinamäki | CC BY-SA 4.0 |

## Measurements
The standard profile: 0.80 high, 0.60 at the foot, 0.15 at the top.

- size (m): 2.06 x 0.80 x 0.61
- profile: 0.60 to 0.075, then 0.40 at 0.33, 0.15 at 0.80
- lifting holes at ±0.55; notches at ±0.45

## Visible details
- [x] M body, chamfered ends, lifting holes, drain notches, joint key (R1)
- [ ] M the cast seams, the ends' chamfers (R2)
- [ ] B scuffs, tags, the painted stripes as a state (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| concrete | precast concrete |  |  | scuffs, stains |
| dark | the holes |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 150 | 1 | 30 m |
| 1 | 110 | 1 | 100 m |
| 2 | 30 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/barrier_concrete_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py barrier_concrete --round=1`)
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
