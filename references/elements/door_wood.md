# door_wood — the panelled wooden door (S191)

Family: `tools/models/props/doors.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py door_wood` · sketch: `python tools/models/props.py door_wood --sketch` · rack: `--prop-rack=door_wood` · review: `python tools/models/review.py door_wood --round=N`

The panelled door of a flat or an office: the moulded architrave on the wall's face, the lining round the reveal, a stone threshold; the leaf (part `leaf`) painted green with four raised panels on both faces, three brass butt hinges on the viewer's left, lever handles on their roses both sides, the keyhole's escutcheon.

## References
Wikimedia Commons, `references/elements/door_wood/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
An opening of 0.90 x 2.10, a 42 mm leaf.

- size (m): 0.97 x 2.12 x 0.22
- reveal 0.16
- handles at 1.02

## Visible details
- [x] M architrave, lining, threshold, leaf, panels, hinges, levers, escutcheons (R1)
- [ ] M the double door, a fanlight (R2)
- [ ] B worn paint round the handle, scuffs at the foot, a number (R3)
- [ ] B splintered and broken by the door's HP (S191 states)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| paint | green gloss over wood | white undercoat | wood | chips round the handle |
| trim | off-white architrave |  |  |  |
| brass | hinges, handles |  |  | tarnish |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 890 | 1 | 15 m |
| 1 | 490 | 1 | 45 m |
| 2 | 170 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf | its hinge edge (0.45, 0, 0.09) | rotate 95° about +Y: inward |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/door_wood_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py door_wood --round=1`)
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
