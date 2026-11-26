# post_box — the yellow letter box on a wall (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py post_box` · sketch: `python tools/models/props.py post_box --sketch` · rack: `--prop-rack=post_box` · review: `python tools/models/review.py post_box --round=N`

The town's post box fixed to a wall: a yellow steel box with a hood over two slots, a blue label under each, the collection door below with its lock and the times plate, raised words at the foot. No brand: the town's own post.

## References
Wikimedia Commons, `references/elements/post_box/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `wall_box.jpg` | **the main reference**, square-on: hood, two slots and labels, the door, the times plate, the raised words | [Boîte postale, Pais 2014.jpg](https://commons.wikimedia.org/wiki/File:Bo%C3%AEte_postale,_Pais_2014.jpg), Sam Nabi from Paris, France | CC BY-SA 2.0 |
| `railing_box.jpg` | the rounded-top kind on a railing: the hood's depth, wear and scratches | [Boite aux lettres à Paris.JPG](https://commons.wikimedia.org/wiki/File:Boite_aux_lettres_%C3%A0_Paris.JPG), Peazapata | CC BY-SA 4.0 |

## Measurements
wall_box against its wall's stone courses (~0.35 m) and railing_box against the railing's bars (0.12 m apart).

- size (m): 0.48 x 0.58 x 0.23
- box 0.46 x 0.58 x 0.20, its foot 1.00 over the pavement
- slots 0.17 x 0.018, labels 0.19 x 0.05
- the hood 0.03 out over the front

## Visible details
- [x] M box, hood, slots, labels, door with its frame, lock, times plate, screws (R1)
- [x] B the labels' words, the times plate, the raised words (R1)
- [ ] M the slots' flaps, the hood's rounded edge (R2)
- [ ] B scratches, tags, faded yellow (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| yellow | post yellow | grey primer | rust | chips at the corners |
| label | blue labels | — | — | fade |
| slot | dark |  |  |  |
| bolt | lock and screws |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 300 | 1 | 15 m |
| 1 | 150 | 1 | 40 m |
| 2 | 40 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/post_box_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py post_box --round=1`)
Differences from the references:
- the labels say VILLE / AUTRES and the box has no logo (no real brand)
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
