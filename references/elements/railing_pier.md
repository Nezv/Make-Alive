# railing_pier — the stone pier of a railing (S156)

Family: `tools/models/props/boundaries.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py railing_pier` · sketch: `python tools/models/props.py railing_pier --sketch` · rack: `--prop-rack=railing_pier` · review: `python tools/models/review.py railing_pier --round=N`

The square stone pier between railing bays and at the gates: a base, a plain shaft, a moulded cap over a neck, a stone ball.

## References
Wikimedia Commons, `references/elements/railing_plinth/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bury_plate28.jpg` | the piers between the railing's bays and at its gate | [Bury - Modèles de serrurerie - planche 28.jpg](https://commons.wikimedia.org/wiki/File:Bury_-_Mod%C3%A8les_de_serrurerie_-_planche_28.jpg), exemples gravés géométriquement par MM. Normand, Hibon, Thierry, Olivier, etc., | Public domain |

## Measurements
Taller than the railing (2.08 m): the ball's top at 2.64.

- size (m): 0.64 x 2.64 x 0.64
- shaft 0.50 square on a 0.58 base 0.30 high
- cap 0.64 square at 2.05-2.26
- ball 0.30 across

## Visible details
- [x] M base, shaft, cap and neck, the ball (R1)
- [ ] M the cap's mouldings, an urn instead of a ball on some (R2)
- [ ] B lichen on the cap, the joints (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | lichen, damp |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 220 | 1 | 25 m |
| 1 | 150 | 1 | 80 m |
| 2 | 60 | 1 | 250 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/railing_pier_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py railing_pier --round=1`)
Differences from the references:
- -
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
