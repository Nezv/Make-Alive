# papers — an office floor's papers (S196)

Family: `tools/models/props/clutter.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py papers` · sketch: `python tools/models/props.py papers --sketch` · rack: `--prop-rack=papers` · review: `python tools/models/review.py papers --round=N`

A 1.2 m patch of an office floor after the panic: sixteen A4 sheets lying flat or curled, crumpled balls, an open folder, a paper cup on its side, a phone face down, a pen (seeded, the same everywhere: the map turns it).

## References
Wikimedia Commons, `references/elements/papers/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A4 sheets (0.21 x 0.297), a 0.10 m cup, a phone 0.15 m.

- size (m): 1.23 x 0.10 x 1.08
- sheets 0.8 mm off the floor, a third curled up to 0.12

## Visible details
- [x] M sheets, curls, crumpled balls, folder, cup, phone, pen (R1)
- [ ] M folds, torn sheets (R2)
- [ ] B print per sheet, footprints, blood (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| paper | white paper |  |  | footprints, damp |
| folder | card folders |  |  |  |
| cup | paper cup |  |  |  |
| phone | black phone |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 850 | 1 | 8 m |
| 1 | 220 | 1 | 25 m |
| 2 | 10 | 1 | 60 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/papers_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py papers --round=1`)
Differences from the references:
- no photos: everyday things at their real sizes; the print on the sheets waits for round 3
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
