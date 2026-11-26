# kiosk — the newspaper kiosk (S172)

Family: `tools/models/props/kiosk.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py kiosk` · sketch: `python tools/models/props.py kiosk --sketch` · rack: `--prop-rack=kiosk` · review: `python tools/models/review.py kiosk --round=N`

The dark green kiosk of the boulevards: a hexagon of framed cast-iron faces on a stone plinth, a name panel over a poster on each, corner posts, a flared cornice crowned with leaves, an attic drum, a scaled dome with its ribs and finial. The street face is the serving hatch: its shutter hangs from the opening's top and folds up and out over the counter.

## References
Wikimedia Commons, `references/elements/kiosk/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `dome_today.jpg` | **the main reference**: three faces, PRESSE panels, posters, the cresting, attic, scaled dome, finial | [Kiosque à journaux boulevard Saint-Michel, Paris, octobre 2021 2.jpg](https://commons.wikimedia.org/wiki/File:Kiosque_%C3%A0_journaux_boulevard_Saint-Michel,_Paris,_octobre_2021_2.jpg), Artvill | CC BY-SA 4.0 |
| `dome_1930.jpg` | the kiosk in use: papers on the counter and hung on clips all round, the dome | [Paris - un kiosque à journaux - btv1b9029706j.jpg](https://commons.wikimedia.org/wiki/File:Paris_-_un_kiosque_%C3%A0_journaux_-_btv1b9029706j.jpg), Agence de presse Meurisse. Agence photographique (commanditaire) | Public domain |
| `open_today.jpg` | the open hatch and counter of a newer kiosk: how deep the inside is | [Kiosque à journaux, avenue Marceau (Paris) en janvier 2020.jpg](https://commons.wikimedia.org/wiki/File:Kiosque_%C3%A0_journaux,_avenue_Marceau_(Paris)_en_janvier_2020.jpg), Benoît Prieur | CC0 |

## Measurements
dome_today: the faces' panels against the pavement's kerb (0.15 m) and the traffic light's head beside (0.9 m): a face 1.0 m wide, the cornice at 2.35, the finial at 3.8.

- size (m): 2.24 x 3.80 x 2.17
- hexagon 1.0 a side, plinth 0.12
- name panels 2.06-2.26, posters under them
- cornice 2.35-2.52 flaring 0.12 out; attic to 2.84; dome to 3.53, finial 3.80
- the hatch 0.78 wide from 1.00 to 1.95, the counter 0.33 deep

## Visible details
- [x] M plinth, faces, rails, posts, name panels, posters in frames, cornice, cresting leaves, attic, dome with ribs, finial (R1)
- [x] M the hatch: dark inside, counter, papers on it, the shutter with its battens and lock (R1)
- [x] B PRESSE on each panel (R1)
- [ ] M the dome's scales, the cresting's acanthus, clips with papers hung round the faces (R2)
- [ ] B front pages without real titles, faded green, rust at the foot (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | dark green | red lead | rust | chips at the corners and the foot |
| zinc | the dome |  | zinc |  |
| stone | the plinth |  |  | dirt |
| poster | invented posters |  |  | torn |
| name | black, gilt letters |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2700 | 1 | 30 m |
| 1 | 1300 | 1 | 90 m |
| 2 | 900 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| shutter | the opening's top, (0, 1.97, -0.88) | rotate 105° about +X: up and out over the counter |

## States
clean · abandoned · damaged · burnt; open / shut is the shutter; looted (papers blowing) waits for S115.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/kiosk_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py kiosk --round=1`)
Differences from the references:
- dome_today's dome is scaled and its cresting is acanthus; ours plain zinc and pointed leaves (round 2)
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
