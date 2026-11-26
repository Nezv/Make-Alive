# sign_tabac — the tobacconist's carotte (S160)

Family: `tools/models/props/signs_shops.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_tabac` · sketch: `python tools/models/props.py sign_tabac --sketch` · rack: `--prop-rack=sign_tabac` · review: `python tools/models/review.py sign_tabac --round=N`

The red lozenge that marks every tabac: a tall hexagon, its rim bright metal, TABAC down both red faces, lit from inside, on a short arm from the wall. The sign stands in the plane x = 0, square to the wall (z = 0, the house +Z).

## References
Wikimedia Commons, `references/elements/sign_tabac/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `carotte.jpg` | **the main reference**: the lozenge from below, TABAC down it, the rim and the arm | [Carotte vendeur tabac.jpg](https://commons.wikimedia.org/wiki/File:Carotte_vendeur_tabac.jpg), Fabien1309 | CC BY-SA 2.0 fr |
| `side.jpg` | the carotte on a corner house, its height over the street | [Carotte débit de tabac (France).jpg](https://commons.wikimedia.org/wiki/File:Carotte_d%C3%A9bit_de_tabac_(France).jpg), Moktarama | CC BY 3.0 |

## Measurements
carotte.jpg: the letters against the house's downpipe (0.10 m); the lozenge 1.0 m tall, 0.42 wide.

- size (m): 0.15 x 1.00 x 0.66
- lozenge 0.42 x 1.00 x 0.14, its points 0.30 of the height
- its middle 0.45 out from the wall

## Visible details
- [x] M rim, two faces, arm and plate, bolts, the stay (R1)
- [x] B TABAC down each face (R1)
- [ ] M the face's bevel, the lamp's cable (R2)
- [ ] B faded red, a dead tube's dark band (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | red, lit |  |  | fades |
| chrome | the rim |  |  | dulls |
| case | the arm |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 200 | 1 | 30 m |
| 1 | 120 | 1 | 100 m |
| 2 | 100 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; lit / dead / flickering per instance (S046, S108).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_tabac_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sign_tabac --round=1`)
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
