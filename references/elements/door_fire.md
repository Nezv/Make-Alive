# door_fire — the steel fire door (S191)

Family: `tools/models/props/doors.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py door_fire` · sketch: `python tools/models/props.py door_fire --sketch` · rack: `--prop-rack=door_fire` · review: `python tools/models/review.py door_fire --round=N`

The steel fire door of the hospital and the offices: a pressed steel frame with its stop, the flush leaf (part `leaf`) painted red, a wired-glass vision panel in steel beads (the wire painted by position, `_paint_fire`), the panic bar and kick plate inside, a pull handle outside, three heavy hinges, the closer on the head.

## References
Wikimedia Commons, `references/elements/door_fire/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
An opening of 0.95 x 2.10, a 54 mm leaf.

- size (m): 1.05 x 2.15 x 0.28
- vision panel 0.16 x 0.60 at 1.45
- panic bar at 0.98

## Visible details
- [x] M frame, leaf, vision panel, wire, panic bar, kick plate, handle, hinges, closer (R1)
- [ ] M the green running-man sign over it (fittings), the intumescent strip (R2)
- [ ] B dents, a bloody handprint (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | red painted steel | grey primer | rust | scuffs |
| steel | frame, bar, plates |  | rust |  |
| glass | wired glass |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 740 | 1 | 15 m |
| 1 | 470 | 1 | 45 m |
| 2 | 210 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf | its hinge edge (0.47, 0, 0.11) | rotate 95° about +Y: inward |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/door_fire_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py door_fire --round=1`)
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
