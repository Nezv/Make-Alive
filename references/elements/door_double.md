# door_double — the half-glazed double door (S191)

Family: `tools/models/props/doors.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py door_double` · sketch: `python tools/models/props.py door_double --sketch` · rack: `--prop-rack=door_double` · review: `python tools/models/review.py door_double --round=N`

The double door of a hall or a corridor: the architrave and lining of a 1.5 m opening; two leaves (parts `leaf_l` hung on the viewer's left, `leaf_r` on the right, both opening in) each with its glass over a raised panel, glazing beads, a brass push plate outside, a kick plate inside, three hinges.

## References
Wikimedia Commons, `references/elements/door_double/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
An opening of 1.50 x 2.10.

- size (m): 1.54 x 2.12 x 0.22
- glass from 1.02 to 2.00
- push plates at 1.20

## Visible details
- [x] M lining, leaves, glass, panels, beads, plates, hinges (R1)
- [ ] M the wired glass of the fire version (R2)
- [ ] B the glass smashed, a leaf off a hinge (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| paint | green gloss | white undercoat | wood | chips |
| glass | glass |  |  | cracks |
| brass | plates, hinges |  |  | tarnish |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 820 | 1 | 15 m |
| 1 | 720 | 1 | 45 m |
| 2 | 390 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l | its hinge edge (0.748, 0, 0.094) | rotate 95° about +Y: inward |
| leaf_r | its hinge edge (-0.748, 0, 0.094) | rotate -95° about +Y: inward |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/door_double_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py door_double --round=1`)
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
