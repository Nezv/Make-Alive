# door_plank — the plank service door (S191)

Family: `tools/models/props/doors.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py door_plank` · sketch: `python tools/models/props.py door_plank --sketch` · rack: `--prop-rack=door_plank` · review: `python tools/models/review.py door_plank --round=N`

The corridor's service door (`door.gd` today draws it as boxes, 2.0 x 2.6): a heavy chamfered timber frame on a stone sill; the leaf (part `leaf`) of eleven vertical planks, ledged and braced inside, strap hinges with their nails outside, the pins, a thumb latch and a hasp with its padlock.

## References
Wikimedia Commons, `references/elements/door_plank/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
2.0 x 2.6, as `door.gd`.

- size (m): 2.32 x 2.81 x 0.32
- planks 0.18
- ledges at 0.35, 1.29, 2.23

## Visible details
- [x] M frame, sill, planks, ledges, braces, straps, nails, pins, latch, hasp, padlock (R1)
- [ ] M swapping it into `door.gd` with its hinge and HP states (S191)
- [ ] B splintered planks, kicked in (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plank | weathered planks (four browns) |  |  | grey, splits |
| timber | the frame |  |  |  |
| iron | straps, latch |  | rust | rust runs |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1600 | 1 | 15 m |
| 1 | 500 | 1 | 45 m |
| 2 | 130 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf | its hinge edge (0.99, 0, 0.12) | rotate 100° about +Y: inward |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/door_plank_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py door_plank --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; fetch door photos for round 2
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
