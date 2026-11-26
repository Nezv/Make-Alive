# war_memorial — the regiment's memorial (S222)

Family: `tools/models/props/barracks_court.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py war_memorial` · sketch: `python tools/models/props.py war_memorial --sketch` · rack: `--prop-rack=war_memorial` · review: `python tools/models/review.py war_memorial --round=N`

The memorial on the cour d'honneur's lawn: three steps, the die's base, the die with AUX MORTS / DU RÉGIMENT / 1914 - 1918 on its front and invented names on its other faces (painted by position, each face's mask kept to its plane), a cornice, a fluted column with its base and capital, a bronze wreath and helmet on top; a bronze wreath leaning on the die; four iron bollards round it hung with chains.

## References
Wikimedia Commons, `references/elements/war_memorial/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
5.6 m to the helmet; steps 2.8 m square.

- size (m): 3.59 x 5.58 x 3.59
- die 1.24 square, 1.5 high
- column 2.8 m

## Visible details
- [x] M steps, die, inscriptions, names, cornice, column, capital, helmet, wreaths, bollards, chains (R1)
- [ ] M a later plaque for other wars (R2)
- [ ] B verdigris runs, a wreath's faded ribbon (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | lichen, black streaks |
| bronze | bronze |  |  | verdigris |
| iron | bollards, chains |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1590 | 1 | 40 m |
| 1 | 850 | 1 | 120 m |
| 2 | 280 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/war_memorial_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py war_memorial --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; French barracks courts and regimental memorials for round 2
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
