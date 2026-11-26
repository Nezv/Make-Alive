# park_gate — the jardin public gate (S190)

Family: `tools/models/props/park.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py park_gate` · sketch: `python tools/models/props.py park_gate --sketch` · rack: `--prop-rack=park_gate` · review: `python tools/models/review.py park_gate --round=N`

The gilded iron gate of a jardin public between stone piers: plinths, shafts with sunk panels, cornices and urns; two leaves (parts `leaf_l`, `leaf_r`, opening in) of bars rising to a wave with gilt spear tips, a dog-bar panel at the foot, a frieze of gilt rings, scrolls; the overthrow arch with its scrolls and gilt crest.

## References
Wikimedia Commons, `references/elements/park_gate/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `monceau.jpg` | a gilded park gate: piers, leaves, overthrow | [Parc Monceau Grille d'entrée 001.jpg](https://commons.wikimedia.org/wiki/File:Parc_Monceau_Grille_d%27entr%C3%A9e_001.jpg), Moonik | CC BY-SA 3.0 |
| `courcelles.jpg` | old photo of a park entrance's gates and lamps | [Grille de l’entrée du parc Monceau, boulevard de Courcelles, 8ème arrondissement, Paris. PH31614.jpg](https://commons.wikimedia.org/wiki/File:Grille_de_l%E2%80%99entr%C3%A9e_du_parc_Monceau,_boulevard_de_Courcelles,_8%C3%A8me_arrondissement,_Paris._PH31614.jpg), Anonyme, photographe | CC0 |
| `bethune.jpg` | a jardin public's gate with its crest overhead | [Béthune — La grille d'entrée du jardin public.jpg](https://commons.wikimedia.org/wiki/File:B%C3%A9thune_%E2%80%94_La_grille_d%27entr%C3%A9e_du_jardin_public.jpg), Jpcuvelier | CC BY-SA 4.0 |
| `brocard.jpg` | a gilded gate from the side: the leaves' depth | [Grille parc Monceau, place du Général-Brocard, rue Van-Dyck, Paris 8e.jpg](https://commons.wikimedia.org/wiki/File:Grille_parc_Monceau,_place_du_G%C3%A9n%C3%A9ral-Brocard,_rue_Van-Dyck,_Paris_8e.jpg), Celette | CC BY-SA 4.0 |

## Measurements
An opening of 3.6 m, piers 0.7 m square and 3.1 m high.

- size (m): 5.14 x 4.50 x 0.84
- leaves 2.4 m high to the top rail, bars to 2.85
- overthrow crest at 4.5

## Visible details
- [x] M piers, urns, leaves, spears, rings, scrolls, overthrow, crest (R1)
- [ ] M the cast leaves and rosettes in the panels; lamps on the piers (R2)
- [ ] B one leaf hanging off, chained shut (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| black | black paint over iron | red primer | rust | chips, rust |
| gilt | gilding | black | rust | worn gilt |
| stone | limestone |  |  | soot, moss |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 6820 | 1 | 40 m |
| 1 | 1220 | 1 | 120 m |
| 2 | 380 | 1 | 400 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l | its hinge at the left pier (-1.80, 0, 0) | rotate -95° about +Y |
| leaf_r | its hinge at the right pier (1.80, 0, 0) | rotate 95° about +Y |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/park_gate_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py park_gate --round=1`)
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
