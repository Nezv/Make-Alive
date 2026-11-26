# chestnut_old — the old horse chestnut (S175)

Family: `tools/models/props/trees.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py chestnut_old` · sketch: `python tools/models/props.py chestnut_old --sketch` · rack: `--prop-rack=chestnut_old` · review: `python tools/models/review.py chestnut_old --round=N`

The old horse chestnut of squares and gardens: a thick short trunk with buttresses and furrowed bark (moss on its north side), five limbs spreading wide and low, a dome crown of faceted clusters coming down almost to the ground, white candles of flowers standing on it in spring. Seeded.

## References
Wikimedia Commons, `references/elements/chestnut_old/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `in_flower.jpg` | **the main reference**: an old chestnut in flower, its dome down to the grass | [Horse-chestnut tree Donegal town - geograph.org.uk - 408567.jpg](https://commons.wikimedia.org/wiki/File:Horse-chestnut_tree_Donegal_town_-_geograph.org.uk_-_408567.jpg), Kay Atherton | CC BY-SA 2.0 |
| `bare.jpg` | an old one bare in March: the trunk's girth, the limbs | [An Old Horse Chestnut Tree near Aldbury in March - geograph.org.uk - 1206683.jpg](https://commons.wikimedia.org/wiki/File:An_Old_Horse_Chestnut_Tree_near_Aldbury_in_March_-_geograph.org.uk_-_1206683.jpg), Chris Reynolds | CC BY-SA 2.0 |
| `allee_1900.jpg` | the allée des marronniers of a Paris garden in 1900 | [L'allée des marronniers (à gauche, fosses aux ours). Jardin des plantes, 5ème arrondissement, Paris. PH38996.jpg](https://commons.wikimedia.org/wiki/File:L%27all%C3%A9e_des_marronniers_(%C3%A0_gauche,_fosses_aux_ours)._Jardin_des_plantes,_5%C3%A8me_arrondissement,_Paris._PH38996.jpg), Séeberger Frères, photographe | CC0 |

## Measurements
in_flower.jpg against the fence and the lawn: about 14 m tall, 19 m across; the trunk 1.5 m across.

- size (m): 19.5 x 13.3 x 18.3
- trunk radius 0.75 (1.15 at the roots), forking at 2.6
- five limbs 4.6 m, two levels more
- clusters 2.1 to 3.1 m, six candles each (0.36 tall)

## Visible details
- [x] M trunk, buttresses, limbs, dome crown, candles (R1)
- [x] B furrowed bark, moss on the north (R1)
- [ ] M burrs on the trunk, the hand-shaped leaves' edge, conkers on the ground (R2)
- [ ] B the leaves' early brown (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| bark | furrowed bark, painted |  |  |  |
| leaves | leaf green |  |  |  |
| flower | white candles |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 7600 | 1 | 30 m |
| 1 | 2900 | 1 | 80 m |
| 2 | 340 | 1 | 200 m |
| 3 | 160 | 1 | 800 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/chestnut_old_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py chestnut_old --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- a young variant (S175 asks for young and old)

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
