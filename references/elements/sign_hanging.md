# sign_hanging — the wrought-iron hanging sign (S160)

Family: `tools/models/props/signs_shops.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_hanging` · sketch: `python tools/models/props.py sign_hanging --sketch` · rack: `--prop-rack=sign_hanging` · review: `python tools/models/review.py sign_hanging --round=N`

The old trade sign: a wall plate, an arm with a strut and C-scrolls, gilt leaves along it, a framed board hung on two rings, a gilded key on both faces (a locksmith's). Other trades (a boot, grapes, a pretzel) are the same bracket with another cut-out.

## References
Wikimedia Commons, `references/elements/sign_hanging/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bracket_rats.jpg` | **the main reference**: a museum's bracket, square-on: the arm, the scrolls, the hanging sign | [Aux trois rats. Enseigne de marchand de fromages (). Rue Montorgueil, 2ème arrondissement, Paris, EN43.jpg](https://commons.wikimedia.org/wiki/File:Aux_trois_rats._Enseigne_de_marchand_de_fromages_()._Rue_Montorgueil,_2%C3%A8me_arrondissement,_Paris,_EN43.jpg), Anonyme, ferronnier | CC0 |
| `street_1900.jpg` | a lane of 1900 with signs hung out over the pavement | [Passage du Dragon, 6ème arrondissement, Paris, PH874.jpg](https://commons.wikimedia.org/wiki/File:Passage_du_Dragon,_6%C3%A8me_arrondissement,_Paris,_PH874.jpg), Marville, Charles (Charles-François Bossu, dit) (17–07–1813 - 01–06–1879), photographe | CC0 |

## Measurements
bracket_rats: the bracket ~1.0 m out from the wall, the board 0.6 m.

- size (m): 0.08 x 0.67 x 1.01
- arm 0.95 out, strut from 0.34 below it
- board 0.62 x 0.42, 0.30 under the arm
- key 0.50 long

## Visible details
- [x] M plate, arm, strut, scrolls, leaves, rings and hangers, board and frame, key (R1)
- [ ] M the key's bow open, the scrolls' collars (R2)
- [ ] B gilt worn off, rust runs on the board (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | black | red lead | rust |  |
| board | brown paint |  | wood | flakes |
| gilt | gold leaf |  |  | worn |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1000 | 1 | 20 m |
| 1 | 560 | 1 | 60 m |
| 2 | 380 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_hanging_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sign_hanging --round=1`)
Differences from the references:
- the key's bow is solid, not a ring (round 2)
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
