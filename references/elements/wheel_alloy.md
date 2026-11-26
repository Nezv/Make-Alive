# wheel_alloy — a five-spoke alloy wheel (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py wheel_alloy` · sketch: `python tools/models/props.py wheel_alloy --sketch` · rack: `--prop-rack=wheel_alloy` · review: `python tools/models/review.py wheel_alloy --round=N`

The kit's 195/65 R15 tyre (shared with `wheel_steel`) on a five-spoke alloy rim: the barrel, the lip, five spokes tapering from the hub, the plain centre cap (no badge), five nuts between the spokes. The wheel faces -X (the car's left side); mirrored for the right.

## References
Wikimedia Commons, `references/elements/wheel_alloy/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
0.635 m across, 0.195 wide.

- size (m): 0.23 x 0.64 x 0.64
- spokes 64 mm at the hub

## Visible details
- [x] M tyre, barrel, lip, spokes, hub, cap, nuts (R1)
- [ ] M hubcaps on the steel wheel (R2)
- [ ] B kerbed, flat, burnt to the rim (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| tyre | rubber |  |  | dust |
| alloy | silver alloy |  |  | brake dust, kerb rash |
| nut | nuts |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2160 | 1 | 15 m |
| 1 | 880 | 1 | 45 m |
| 2 | 400 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/wheel_alloy_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py wheel_alloy --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; photos for round 2
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
