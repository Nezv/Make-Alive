# tomb_chapel — a family chapel (S189)

Family: `tools/models/props/cemetery.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tomb_chapel` · sketch: `python tools/models/props.py tomb_chapel --sketch` · rack: `--prop-rack=tomb_chapel` · review: `python tools/models/review.py tomb_chapel --round=N`

A family chapel like a little house: a stone cell on a plinth with its step, pilasters at the corners, an entablature with the family's name on the frieze (FAMILLE DUVAL, invented), a pediment over the front and a stone roof running back, a cross on the ridge, the green iron door with a grille over its glass, in an arched surround (part `door`, opening out).

## References
Wikimedia Commons, `references/elements/tomb_chapel/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `four_chapels.jpg` | **the main reference**: four chapels side by side square-on: gothic and classical fronts, grilled doors | [Père-Lachaise - quatre chapelles funéraires.jpg](https://commons.wikimedia.org/wiki/File:P%C3%A8re-Lachaise_-_quatre_chapelles_fun%C3%A9raires.jpg), Pierre-Yves Beaudouin | CC BY-SA 3.0 |
| `classical.jpg` | a classical chapel at an alley's corner: pilasters, entablature, garlands | [Paris Père-Lachaise division 04 chapelle funéraire.jpg](https://commons.wikimedia.org/wiki/File:Paris_P%C3%A8re-Lachaise_division_04_chapelle_fun%C3%A9raire.jpg), Kapsuglan | CC BY-SA 4.0 |
| `dark_row.jpg` | a row of chapels blackened by age | [Paris Père Lachaise Chapelle funéraire Coutant-Moity.jpg](https://commons.wikimedia.org/wiki/File:Paris_P%C3%A8re_Lachaise_Chapelle_fun%C3%A9raire_Coutant-Moity.jpg), Kapsuglan | CC BY-SA 4.0 |

## Measurements
four_chapels: the doors 0.80 x 1.85 against the cobbles' 0.15 setts; the chapels 1.7 m wide, 3.4 to the ridge.

- size (m): 1.98 x 3.96 x 2.82
- cell 1.70 x 2.30, plinth 0.30
- entablature 2.35-2.60, pediment 0.80 high
- door 0.80 x 1.85 under a 0.12 arch

## Visible details
- [x] M plinth, step, cell, pilasters, entablature, pediment and roof, raking cornices, cross, door surround, door with glass and grille (R1)
- [x] B the name on the frieze (R1)
- [ ] M the gothic variant (pinnacles, tracery), stained glass inside, garlands (R2)
- [ ] B lichen, streaks, the door rusted and broken as a state (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | lichen, black streaks, moss at the foot |
| door | green iron | red lead | rust | rust |
| glass | glass |  |  | broken |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 400 | 1 | 30 m |
| 1 | 320 | 1 | 90 m |
| 2 | 170 | 1 | 250 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| door | its left jamb (-0.40, 0.30, -1.155) | rotate 100° about +Y: out |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tomb_chapel_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tomb_chapel --round=1`)
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
