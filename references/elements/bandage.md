# bandage — a roll of gauze (S153)

Family: `tools/models/props/carried.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bandage` · sketch: `python tools/models/props.py bandage --sketch` · rack: `--prop-rack=bandage` · review: `python tools/models/review.py bandage --round=N`

A roll of gauze lying on its side, its loose end peeling off the bottom and lying out flat; the weave painted as a faint grid.

## References
Wikimedia Commons, `references/elements/bandage/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `rolling_1918.jpg` | nurses rolling bandages: the rolls' size in their hands | [3611 Bandage rolling.jpg](https://commons.wikimedia.org/wiki/File:3611_Bandage_rolling.jpg), Oscar Bernader Bengtsson (b1888) | Public domain |

## Measurements
A 10 cm roll (the common width), 7.6 cm across.

- size (m): 0.10 x 0.12 x 0.21
- roll 0.10 wide, radius 0.038, core 0.012
- loose end 0.15 out

## Visible details
- [x] M roll, core, loose end (R1)
- [x] B the weave (R1)
- [ ] M the end's frayed edge (R2)
- [ ] B blood soaked into one side (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| gauze | white gauze |  |  | dirt, blood |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 300 | 1 | 4 m |
| 1 | 190 | 1 | 10 m |
| 2 | 70 | 1 | 25 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bandage_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bandage --round=1`)
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
