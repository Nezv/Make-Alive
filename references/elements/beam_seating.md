# beam_seating — waiting-room beam seating (S193)

Family: `tools/models/props/office.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py beam_seating` · sketch: `python tools/models/props.py beam_seating --sketch` · rack: `--prop-rack=beam_seating` · review: `python tools/models/review.py beam_seating --round=N`

Three moulded seats on a steel beam on two legs with T feet: each seat a shell (pan and back in one, curved), a bracket under each, armrests between them. The bus station's and the hospital's waiting rooms.

## References
Wikimedia Commons, `references/elements/beam_seating/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Three seats at 0.60, the beam 1.8 m.

- size (m): 1.80 x 0.84 x 0.52
- seats at 0.43, backs to 0.84

## Visible details
- [x] M beam, legs, shells, brackets, armrests (R1)
- [ ] M the perforated steel version (R2)
- [ ] B a seat torn off (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| seat | blue plastic shells |  |  | scratches |
| steel | grey steel |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 820 | 1 | 12 m |
| 1 | 470 | 1 | 36 m |
| 2 | 210 | 1 | 110 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/beam_seating_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py beam_seating --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; fetch office photos for round 2
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
