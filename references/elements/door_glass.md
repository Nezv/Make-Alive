# door_glass — the aluminium glass door (S191)

Family: `tools/models/props/doors.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py door_glass` · sketch: `python tools/models/props.py door_glass --sketch` · rack: `--prop-rack=door_glass` · review: `python tools/models/review.py door_glass --round=N`

The aluminium-framed glass door of a shop or a hall: its frame in the opening, a flat threshold; the leaf (part `leaf`) of narrow stiles, a top rail and a deep bottom rail round the glass, a push bar standing off the outside, a pull handle inside, the lock in the bottom rail; the closer on the head with its arm.

## References
Wikimedia Commons, `references/elements/door_glass/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
An opening of 1.00 x 2.20.

- size (m): 1.12 x 2.27 x 0.30
- bottom rail 0.26
- push bar at 1.05

## Visible details
- [x] M frame, leaf, glass, push bar, pull handle, lock, closer (R1)
- [ ] M the PUSH / PULL lettering, a side light (R2)
- [ ] B the glass cracked, then smashed (S113)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| alu | anodised aluminium |  |  | scratches |
| glass | glass |  |  | dirt, cracks |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 710 | 1 | 15 m |
| 1 | 320 | 1 | 45 m |
| 2 | 190 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf | its hinge edge (0.49, 0, 0.09) | rotate 95° about +Y: inward |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/door_glass_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py door_glass --round=1`)
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
