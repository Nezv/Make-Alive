# railing_plinth — one bay of railing on a stone plinth (S156)

Family: `tools/models/props/boundaries.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py railing_plinth` · sketch: `python tools/models/props.py railing_plinth --sketch` · rack: `--prop-rack=railing_plinth` · review: `python tools/models/review.py railing_plinth --round=N`

One 2.40 m bay of the iron railing that closes a garden or a court from the street: a stone plinth with its coping, square bars with spear finials between a bottom and a top rail, a band of rings at the foot. Bays join end to end along x; piers (`railing_pier`) stand between them where the run turns or a gate opens.

## References
Wikimedia Commons, `references/elements/railing_plinth/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bury_plate28.jpg` | **the main reference**, an elevation: the bars, spears, rails, the band at the foot, the plinth and the piers | [Bury - Modèles de serrurerie - planche 28.jpg](https://commons.wikimedia.org/wiki/File:Bury_-_Mod%C3%A8les_de_serrurerie_-_planche_28.jpg), exemples gravés géométriquement par MM. Normand, Hibon, Thierry, Olivier, etc., | Public domain |
| `boulevard.jpg` | a railing on a low wall along a boulevard: the height against people, the rhythm of the bars | [Boulevard Lannes, Paris 16e 1.jpg](https://commons.wikimedia.org/wiki/File:Boulevard_Lannes,_Paris_16e_1.jpg), Thank you to indicate this credit line next to the image in case of reuse:

Credit: Polymagou - CC BY-SA

I'd appreciate if you could send a message on my user talk page if you use this picture out of the Wikimedia project scope . | CC BY-SA 4.0 |

## Measurements
bury_plate28's scale bar; boulevard.jpg: the bars to ~2 m against the trees' guards and the people.

- size (m): 2.40 x 2.08 x 0.46
- plinth 0.60 high, 0.40 thick, its coping 0.08 overhanging 0.03
- bars 22 mm every 0.12; the top rail at 1.92, the spears to 2.08
- the ring band 0.13 over the coping

## Visible details
- [x] M plinth, coping, bars, rails, spears with their collars, rings, the lead at the bars' feet (R1)
- [ ] M the spears' leaves, the bars' twists on some (R2)
- [ ] B rust at the feet, moss on the coping (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | black | red lead | rust | rust running onto the coping |
| stone | limestone |  |  | moss, damp |
| dark | lead joints |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2500 | 1 | 20 m |
| 1 | 700 | 1 | 60 m |
| 2 | 320 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/railing_plinth_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py railing_plinth --round=1`)
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
