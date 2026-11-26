# sandbag_wall — a module of sandbag wall (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sandbag_wall` · sketch: `python tools/models/props.py sandbag_wall --sketch` · rack: `--prop-rack=sandbag_wall` · review: `python tools/models/review.py sandbag_wall --round=N`

A 1.2 m module of a sandbag wall, three courses: stretchers two deep, headers across, stretchers again. Each bag a pillow (a loft of superellipse sections, pinched to its seams at the ends, its belly flattened), turned a little at random (seeded), its tied ear at one end.

## References
Wikimedia Commons, `references/elements/sandbag_wall/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `close.jpg` | **the main reference**: a sandbag wall close up: the bags' shape, slump, seams, ties | [Capt Harper Checks Over a Sandbag Wall for Any Enemy Forces DVIDS15480.jpg](https://commons.wikimedia.org/wiki/File:Capt_Harper_Checks_Over_a_Sandbag_Wall_for_Any_Enemy_Forces_DVIDS15480.jpg), Photo by U.S. Army Sgt. Alex Licea, Third U.S. Army Public Affairs Office | Public domain |
| `flood.jpg` | a flood wall of bags along a canal: how they stack in courses | [Sandbag wall - geograph.org.uk - 3222014.jpg](https://commons.wikimedia.org/wiki/File:Sandbag_wall_-_geograph.org.uk_-_3222014.jpg), Bill Nicholls | CC BY-SA 2.0 |

## Measurements
The common bag filled: 0.60 x 0.34 x 0.17 (close.jpg against the soldier's rifle).

- size (m): 1.28 x 0.45 x 0.67
- bags 0.60 x 0.34 x 0.17, courses 0.15 apart
- stretchers two deep, headers three across

## Visible details
- [x] M bags as pillows, the ears, courses in bond (R1)
- [ ] M seams, ties' knots, a torn bag spilling (R2)
- [ ] B weave, damp, sand at the foot (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| bag | hessian or polypropylene |  |  | damp, faded |
| tie | the ties |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1800 | 1 | 15 m |
| 1 | 900 | 1 | 50 m |
| 2 | 250 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sandbag_wall_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sandbag_wall --round=1`)
Differences from the references:
- the far LOD's bags are four-sided: acceptable past 50 m
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
