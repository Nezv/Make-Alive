# lamp_post — the cast-iron candélabre of the old streets and quays (S166)

Family: `tools/models/props/lamps.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py lamp_post` · sketch: `python tools/models/props.py lamp_post --sketch` · rack: `--prop-rack=lamp_post` · review: `python tools/models/review.py lamp_post --round=N`

The gas candélabre of the main streets and the quays in Marville's photographs: a stone slab, a square cast-iron pedestal tapering up with a cartouche on each face and a cornice, a bell with garlands, a collar, leaves round the foot of a square fluted shaft, a capital, four arms holding the lantern. The lantern (`lamps._lantern`) is shared with `wall_lantern` (its own card): a square glass box widening upwards on a pointed foot, corner posts, a pyramid roof with its eave and crockets, a vented crown, a finial, the burner inside. The réverbère hung on ropes across the lanes is S167's.

## References
Wikimedia Commons, `references/elements/lamp_post/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `louvre.jpg` | **the main reference**, square-on against a wall: every section of the post and the lantern | [Charles Marville, Candélabre du Louvre](https://commons.wikimedia.org/wiki/File:Charles_Marville_-_(Cand%C3%A9labre_du_Louvre)_-_Google_Art_Project.jpg) | public domain |
| `arts_metiers.jpg` | the "ancien modèle" on a quay parapet: the lantern from below, the post's proportions in a street | [Charles Marville, Arts et Métiers (Ancien Modèle)](https://commons.wikimedia.org/wiki/File:Arts_et_M%C3%A9tiers_(Ancien_Mod%C3%A8le).jpg) | public domain |
| `lantern_head.jpg` | a lantern's head in a museum: the crown, the roof, the rim, the glass | [Réverbère de Paris](https://commons.wikimedia.org/wiki/File:R%C3%A9verb%C3%A8re_de_Paris.jpg) | public domain |
| `bury_porte_lanternes.jpg` | engraved porte-lanternes and porte-réverbères with a scale of feet: the scrolled brackets (`wall_lantern`) | [Bury, Modèles de serrurerie, planche 31](https://commons.wikimedia.org/wiki/File:Bury_-_Mod%C3%A8les_de_serrurerie_-_planche_31.jpg) | public domain |
| `street_today.jpg` | a lamp post in a Paris street today: the dark green, the height against the houses | [9 rue Murillo Paris](https://commons.wikimedia.org/wiki/File:9_rue_Murillo_Paris.jpg), Philippe Cendron | CC BY-SA 4.0 |

## Measurements
The scale: the lantern's top 0.46 m across (the Paris lanterns' 45 cm), which makes `louvre` 0.0033 m a pixel and the post 3.5 m to its finial; the stone courses behind it then come out 0.35 m, as the Louvre's bossage is.

- size (m): 0.80 x 3.58 x 0.80
- the stone slab 0.80 square, 0.15 tall; the iron foot 0.62 square
- the pedestal 0.72 tall tapering from 0.50 to 0.38, its cornice 0.43; the bell to 1.33; the collar to 1.54
- the shaft 1.08 tall, 0.14 square at its foot, 0.12 under the capital
- the lantern: the glass 0.31 tall from 0.31 to 0.45 across, the roof 0.19 over a 0.48 eave, the crown 0.13, the finial

## Visible details
- [x] M stone slab, the iron foot stepping in, the pedestal, its cornice, the bell, the collar, the shaft, the capital: an octagonal loft (a square with its corners cut) (R1)
- [x] M a cartouche on each face of the pedestal, scrolls at its foot, a garland on the bell, three leaves rising up each face of the shaft's foot, three flutes up each face (R1)
- [x] M the arms holding the lantern; the lantern's foot, glass, corner posts, rims, eave and crockets, roof ribs, vented crown, finial, burner (R1)
- [ ] M the porte-échelle (the ladder bar under the lantern, arts_metiers), the pedestal's access door with its lock (R2)
- [ ] B dark green paint chipped to the red lead and rust at the foot, stickers on the shaft, soot in the lantern's roof, dead insects on the glass (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | Paris dark green | red lead | rust | chips at the foot and the corners |
| stone | the slab, limestone | — | — | dirt |
| glass | the lantern's glass, lit warm | — | — | dirty, cracked (damaged) |
| flame | the burner's mantle, lit | — | — | |
| brass | the burner | — | — | |
| fixing | the crown's vents (dark) and bolts | — | rust | |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3000 | 1 | 25 m |
| 1 | 600 | 1 | 80 m |
| 2 | 300 | 1 | 400 m |

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (paint). Lit: the glass and the burner carry the emission map; dead and flickering lamps turn it down per instance (S046, S108).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/lamp_post_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py lamp_post --round=1`)
Differences from the references:
- the burner lit inside could not be seen through the glass (the glass is opaque in the game's material): a lit lantern would read dead
Fixed:
- the glass carries the warm emission itself
Open:
- louvre's pedestal and bell carry garlands and acanthus in relief; ours are a few bars and prisms (round 2, with the bake)

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
