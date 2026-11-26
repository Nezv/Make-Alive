# wheelchair — the folding hospital wheelchair (S211)

Family: `tools/models/props/hospital.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py wheelchair` · sketch: `python tools/models/props.py wheelchair --sketch` · rack: `--prop-rack=wheelchair` · review: `python tools/models/review.py wheelchair --round=N`

The folding wheelchair of a hospital's corridors: sling seat and back of dark cloth on a chrome frame crossed under the seat, the big spoked wheels with their push rims, castors in front, footplates, armrests, the push handles' grips.

## References
Wikimedia Commons, `references/elements/wheelchair/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `behind.jpg` | **the main reference**, from behind: back, handles, big wheels, push rims, the cross brace | [Wheelchair from Wheelchair Foundation in Russia,.jpg](https://commons.wikimedia.org/wiki/File:Wheelchair_from_Wheelchair_Foundation_in_Russia,.jpg), Davronov Alexander | CC BY-SA 4.0 |
| `corridor.jpg` | transport chairs and IV poles by a ward's door | [Wheelchairs in a hospital corridor.jpg](https://commons.wikimedia.org/wiki/File:Wheelchairs_in_a_hospital_corridor.jpg), Ibex73 | CC BY-SA 4.0 |

## Measurements
The standard chair: seat 0.50 high, 0.46 wide; wheels 0.60 (behind.jpg against the floor's 0.30 tiles).

- size (m): 0.62 x 0.94 x 0.91
- seat 0.46 x 0.44 at 0.50, back to 0.92
- wheels 0.60 with 24 spokes, castors 0.20

## Visible details
- [x] M frame, cross brace, sling seat and back, armrests and pads, wheels, push rims, castors, footplates, grips (R1)
- [ ] M brakes, the footrests' hinges (R2)
- [ ] B worn cloth, rust on the chrome, blood (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| chrome | chrome tube |  | rust | pits |
| cloth | dark sling cloth |  |  | worn, stains |
| tyre | rubber |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1600 | 1 | 15 m |
| 1 | 1100 | 1 | 40 m |
| 2 | 650 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; piled as a barricade is placing (S048).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/wheelchair_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py wheelchair --round=1`)
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
