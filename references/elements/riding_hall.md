# riding_hall — the barracks' riding hall (S224)

Family: `tools/models/props/riding_hall.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py riding_hall` · sketch: `python tools/models/props.py riding_hall --sketch` · rack: `--prop-rack=riding_hall` · review: `python tools/models/review.py riding_hall --round=N`

The caserne's old manège, now its gym: a 40 x 18 m hall of stone (ashlar painted) on a plinth, pilasters between eight tall round-headed windows down each side (surrounds, keystones, sills, glazing bars), the gable ends with an oculus and a great arched door under its fanlight (the front one's two leaves are parts `door_l` and `door_r`, opening out), the cornice, the slate roof with a zinc ridge vent, the iron trusses inside.

## References
Wikimedia Commons, `references/elements/riding_hall/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
40 m long, 18 m wide, walls 8 m, the ridge 12.9 m.

- size (m): 18.70 x 12.91 x 40.90
- windows 2.2 x 4.6
- doors 5.0 x 6.0

## Visible details
- [x] M walls, plinth, pilasters, windows, surrounds, keystones, sills, bars, gables, oculi, doors, fanlights, cornice, roof, ridge vent, trusses (R1)
- [ ] M the interior: the sports floor, wall bars, the gallery (R2)
- [ ] B moss on the roof, broken panes (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone in ashlar courses |  |  | streaks |
| dress | dressed stone |  |  |  |
| slate | slates |  |  | moss |
| door | brown painted wood |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 5330 | 1 | 80 m |
| 1 | 3090 | 1 | 250 m |
| 2 | 810 | 1 | 1000 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| door_l | its hinge (-2.5, 0, -20.07) | rotate 100° about +Y: out |
| door_r | its hinge (2.5, 0, -20.07) | rotate -100° about +Y: out |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/riding_hall_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py riding_hall --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; French casernes' manèges for round 2
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
