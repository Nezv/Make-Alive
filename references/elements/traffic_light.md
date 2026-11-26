# traffic_light — the signal on its short pole (S168)

Family: `tools/models/props/traffic.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py traffic_light` · sketch: `python tools/models/props.py traffic_light --sketch` · rack: `--prop-rack=traffic_light` · review: `python tools/models/review.py traffic_light --round=N`

The French traffic signal at the kerb: a dark grey pole, the three-lens head on its front at the top, the small repeater head at the drivers' eye height, the pedestrians' push-button box on the kerb's side. All lenses glow by the emission map; which is on is the game's.

## References
Wikimedia Commons, `references/elements/traffic_light/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `short_pole.jpg` | **the main reference**: the short pole, the head at its top, the visors, the repeater under it | [Feux Tricolores Avenue Victor Hugo Fontenay Bois 2.jpg](https://commons.wikimedia.org/wiki/File:Feux_Tricolores_Avenue_Victor_Hugo_Fontenay_Bois_2.jpg), Chabe01 | CC BY-SA 4.0 |
| `repeater.jpg` | the repeater close: three small lenses, the visors, a sign on the pole above | [Feux tricolores Avenue Pépinière Fontenay Bois 1.jpg](https://commons.wikimedia.org/wiki/File:Feux_tricolores_Avenue_P%C3%A9pini%C3%A8re_Fontenay_Bois_1.jpg), Chabe01 | CC BY-SA 4.0 |
| `wall_head.jpg` | a head on a wall bracket at a junction of old houses | [FR 16 Cognac - Feu de circulation au croisement de l'avenue Victor Hugo avec le boulevard de Paris et la rue Fernand Chabiran.jpg](https://commons.wikimedia.org/wiki/File:FR_16_Cognac_-_Feu_de_circulation_au_croisement_de_l%27avenue_Victor_Hugo_avec_le_boulevard_de_Paris_et_la_rue_Fernand_Chabiran.jpg), KiwiNeko14 | CC BY-SA 4.0 |

## Measurements
The 200 mm lenses (French standard) and the head's 0.30 m width; the pole 3.1 m against the barriers beside it.

- size (m): 0.30 x 3.14 x 0.63
- head 0.30 x 0.90 x 0.22, lenses 200 mm, its top 3.05
- repeater 0.15 x 0.39, lenses 100 mm, its top 1.75
- button box at 1.05

## Visible details
- [x] M pole with its foot, head, lenses, visors, brackets and clamps, repeater, button box (R1)
- [ ] M the heads' backplates, the hinges of the lens doors (R2)
- [ ] B dirty lenses, stickers on the pole (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| grey | dark grey | primer | rust | chips at the foot |
| head | black polycarbonate |  |  | faded |
| red / amber / green | the lenses, lit |  |  | dirty |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1300 | 1 | 25 m |
| 1 | 700 | 1 | 80 m |
| 2 | 300 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; dead, blinking amber and a head hanging by its cable are the game's (S046, S115).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/traffic_light_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py traffic_light --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- the lit lens per instance (S046)

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
