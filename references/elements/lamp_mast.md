# lamp_mast — the modern mast of the outer roads (S166)

Family: `tools/models/props/lamps.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py lamp_mast` · sketch: `python tools/models/props.py lamp_mast --sketch` · rack: `--prop-rack=lamp_mast` · review: `python tools/models/review.py lamp_mast --round=N`

The street light of the outer roads and the hill road: a galvanised conical pole, its arm bending out over the road (-Z), a flat luminaire tilted up a little with its lit bowl underneath, the door to its wiring near the foot.

## References
Wikimedia Commons, `references/elements/lamp_mast/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
The common 8 m mast, the arm 1.6 m out.

- size (m): 0.26 x 8.13 x 2.29
- pole 0.17 across at its foot, 0.09 at its top
- head 0.62 x 0.11 x 0.26

## Visible details
- [x] M pole, foot, arm, head, lit bowl, door (R1)
- [ ] M the base plate's bolts, the head's fins (R2)
- [ ] B stickers, rust at the foot (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| galv | galvanised steel |  | rust |  |
| head | grey aluminium |  |  |  |
| lamp | lit bowl |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 420 | 1 | 40 m |
| 1 | 210 | 1 | 120 m |
| 2 | 100 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; lit / dead / flickering per instance (S046, S108).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/lamp_mast_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py lamp_mast --round=1`)
Differences from the references:
- no photo yet: one to fetch for round 2
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
