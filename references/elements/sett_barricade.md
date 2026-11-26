# sett_barricade — a barricade of setts (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sett_barricade` · sketch: `python tools/models/props.py sett_barricade --sketch` · rack: `--prop-rack=sett_barricade` · review: `python tools/models/review.py sett_barricade --round=N`

The old-town classic: a barricade of setts torn up from the street, banked 1.2 m high across 4 m, the setts laid in courses up both faces and thrown loose along the crest and on the street in front, a handcart tipped up against one end on its big spoked wheels, barrels on the crest, a door laid against the front, a wardrobe laid along the crest and two chairs thrown on.

## References
Wikimedia Commons, `references/elements/sett_barricade/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `blanche.jpg` | 1871: the barricade being built place Blanche, setts in heaps | [Barricade sous la Commune, place Blanche, D.3132.jpg](https://commons.wikimedia.org/wiki/File:Barricade_sous_la_Commune,_place_Blanche,_D.3132.jpg), Arnaud-Durbec, Jean-Baptiste-François (Marseille, 30–07–1827 - Paris, 02–02–1910), dessinateur | CC0 |
| `temple.jpg` | 1871: a finished one across the faubourg du Temple, its height and courses | [Barricade à l'entrée du faubourg du Temple, sur le canal St-Martin. (18 mars 1871), PH10363.jpg](https://commons.wikimedia.org/wiki/File:Barricade_%C3%A0_l%27entr%C3%A9e_du_faubourg_du_Temple,_sur_le_canal_St-Martin._(18_mars_1871),_PH10363.jpg), Anonyme, photographe | CC0 |
| `paix.jpg` | 1871: carts and setts across the rue de la Paix | [Barricade à l'angle de la rue de la Paix et de la place Vendôme, 1er arrondissement (1870-1871). D.4875.jpg](https://commons.wikimedia.org/wiki/File:Barricade_%C3%A0_l%27angle_de_la_rue_de_la_Paix_et_de_la_place_Vend%C3%B4me,_1er_arrondissement_(1870-1871)._D.4875.jpg), Humbert, Gaston, dessinateur | CC0 |

## Measurements
A street's width in modules of 4 m; the heap 1.2 m high, 1.7 m deep at the foot.

- size (m): 4.23 x 2.37 x 2.75
- setts 0.18 x 0.13 x 0.14
- cart wheels 1.1 m across
- barrels 0.76 tall

## Visible details
- [x] M core, courses of setts, loose setts, cart, barrels, door (R1)
- [x] M furniture: a wardrobe, two chairs (R1)
- [ ] M a gap for a gun (R2)
- [ ] B the hole in the street the setts came from (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| sett | grey granite setts (five greys) |  |  | dirt |
| earth | earth and sand |  |  |  |
| timber | weathered wood |  |  | rot |
| iron | hoops, axle |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 6090 | 1 | 30 m |
| 1 | 3170 | 1 | 90 m |
| 2 | 360 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sett_barricade_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py sett_barricade --round=1`)
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
