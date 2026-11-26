# plane_tree — the plane tree of the squares and quays (S174)

Family: `tools/models/props/trees.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py plane_tree` · sketch: `python tools/models/props.py plane_tree --sketch` · rack: `--prop-rack=plane_tree` · review: `python tools/models/review.py plane_tree --round=N`

The plane tree: a trunk flaring into root buttresses, leaning a little, forking at 3.6 m into three limbs that branch twice more; a dense rounded crown of leaf clusters (faceted lumps, seeded) round the branch ends and along the last limbs; the bark painted in the mottled patches of grey, olive and cream. Seeded, so every peer grows the same tree; the map turns and scales it. LOD 3 is one lump on a trunk.

## References
Wikimedia Commons, `references/elements/plane_tree/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `square.jpg` | **the main reference**: a village square's plane, whole: trunk, fork, the dense crown | [Place du platane centenaire.jpg](https://commons.wikimedia.org/wiki/File:Place_du_platane_centenaire.jpg), Mairie66 | CC BY-SA 4.0 |
| `fork.jpg` | a trunk forking into its limbs, the shed bark | [Platanus x hispanica tree at Lorsch Abbey.jpg](https://commons.wikimedia.org/wiki/File:Platanus_x_hispanica_tree_at_Lorsch_Abbey.jpg), Mountain | CC BY-SA 3.0 |
| `bare.jpg` | the branching in winter, from below | [Bare London planetree (Platanus × hispanica) in winter, Campo dos Mártires da Pátria, Lisbon, Portugal julesvernex2.jpg](https://commons.wikimedia.org/wiki/File:Bare_London_planetree_(Platanus_%C3%97_hispanica)_in_winter,_Campo_dos_M%C3%A1rtires_da_P%C3%A1tria,_Lisbon,_Portugal_julesvernex2.jpg), Jules Verne Times Two | CC BY-SA 4.0 |
| `bark.jpg` | the bark's patches close | [Bark of Platanus x hispanica.jpg](https://commons.wikimedia.org/wiki/File:Bark_of_Platanus_x_hispanica.jpg), Krzysztof Golik | CC BY-SA 4.0 |
| `quay_1900.jpg` | a quay planted with young planes in 1900 | [Quai de Tounis, Toulouse - btv1b10578950f.jpg](https://commons.wikimedia.org/wiki/File:Quai_de_Tounis,_Toulouse_-_btv1b10578950f.jpg), Trutat, Eugène (1840-1910). Photographe | Public domain |

## Measurements
square.jpg against the two-storey house beside it: about 18 m tall, the crown 14 m across; the trunk 1.0 m across at the foot.

- size (m): 15.0 x 17.5 x 13.8
- trunk radius 0.52 (0.80 at the roots), fork at 3.6
- limbs 5.0 m, then 0.55-0.7 of that, three levels
- clusters 1.6 to 2.4 m

## Visible details
- [x] M trunk, buttresses, fork, three levels of limbs, leaf clusters (R1)
- [x] B the bark's patches (R1)
- [ ] M the seed balls hanging, smaller twigs at the crown's edge (R2)
- [ ] B the leaves' light and dark sides, autumn by preset, the wind (S047) (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| bark | mottled bark, painted |  |  |  |
| leaves | leaf green, a palette per cluster |  |  | autumn later |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 11000 | 1 | 30 m |
| 1 | 1800 | 1 | 80 m |
| 2 | 240 | 1 | 200 m |
| 3 | 130 | 1 | 800 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/plane_tree_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py plane_tree --round=1`)
Differences from the references:
- the crown's lumps are faceted balls: the style of the characters, not leaves (round 2 breaks their edges)
Fixed:
- the first growth read as an umbrella pine (crown high and flat, trunk thin): stouter trunk, lower fork, limbs upright, clusters along the last limbs
Open:
- three variants (S174) by seed
- a card at 200 m: LOD 3 is a lump on a trunk for now

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
