# stair_flight — a concrete stair's half flight (S192)

Family: `tools/models/props/stairs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py stair_flight` · sketch: `python tools/models/props.py stair_flight --sketch` · rack: `--prop-rack=stair_flight` · review: `python tools/models/review.py stair_flight --round=N`

A dog-leg stair's half flight of cast concrete in a public building: nine risers of 167 mm up to the half landing 1.5 m up, granilite treads (a colour per tread) with dark nosing strips, the sloping soffit, the landing slab; on the wall side a blue steel tube handrail on brackets, its ends turned to the wall; on the well side flat-bar balusters under a top rail that runs on round the landing, a scroll at its foot. Two of them, the second turned, make a storey of 3.0 m.

## References
Wikimedia Commons, `references/elements/stair_flight/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
1.2 m wide; goings 0.28 m; the landing 1.3 m deep.

- size (m): 1.30 x 2.48 x 3.88
- handrail at 0.90 over the nosings
- balustrade at 0.95

## Visible details
- [x] M waist, treads, nosings, landing, handrail, brackets, balusters, top rail, scroll (R1)
- [ ] M the glass and concrete balustrades of the post-war buildings (R2)
- [ ] B worn nosings, chipped paint, blood on the treads (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| concrete | board-marked concrete |  |  | stains |
| granilite | granilite treads |  |  | worn |
| nosing | black strips |  |  |  |
| rail | blue paint over steel | red primer | rust | chips |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1120 | 1 | 15 m |
| 1 | 710 | 1 | 45 m |
| 2 | 220 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/stair_flight_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py stair_flight --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; stairwells and ceilings for round 2
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
