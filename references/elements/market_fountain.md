# market_fountain — the place du Marché's fountain (S187)

Family: `tools/models/props/monument.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py market_fountain` · sketch: `python tools/models/props.py market_fountain --sketch` · rack: `--prop-rack=market_fountain` · review: `python tools/models/review.py market_fountain --round=N`

The market's fountain, a column of about 1800 in the manner of whole.jpg, the invented town's and smaller: a wide round basin with its moulded rim and still water, a square inner tier with a bronze lion mask and spout on each face pouring into it, the pedestal with its cornice, the inscription (FONTAINE DU MARCHE, AN XI, invented) and four couchant beasts at its corners, the column's base, a shaft banded with four gilt bracelets, a capital of palm leaves, a globe, and the gilt Victory on it holding up two wreaths. The Victory is a blockout (round 4).

## References
Wikimedia Commons, `references/elements/market_fountain/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `whole.jpg` | **the main reference**: a column fountain of 1808 whole: basins, pedestal with beasts, banded shaft, palm capital, globe, Victory | [Paris 1 - Fontaine du Palmier.jpg](https://commons.wikimedia.org/wiki/File:Paris_1_-_Fontaine_du_Palmier.jpg), Selbymay | CC BY-SA 3.0 |
| `victory.jpg` | the gilt Victory close: arms up, two wreaths, wings | [Victory Boizot Chatelet Fountain.jpg](https://commons.wikimedia.org/wiki/File:Victory_Boizot_Chatelet_Fountain.jpg), Marie-Lan Nguyen | CC BY 3.0 |
| `moved_1858.jpg` | the same fountain in 1858, being moved: its column in scaffolding | [Déplacement de la fontaine du Palmier, place du Châtelet, 4e arrondissement, Paris., PH10154.jpg](https://commons.wikimedia.org/wiki/File:D%C3%A9placement_de_la_fontaine_du_Palmier,_place_du_Ch%C3%A2telet,_4e_arrondissement,_Paris.,_PH10154.jpg), Michelez, Charles Louis (Paris, vers 1817 - en 1883), photographe | CC0 |

## Measurements
whole.jpg against the trees and the people round its basin: ours scaled to 14 m for a smaller square; the basin 8.8 m across.

- size (m): 9.0 x 14.2 x 9.0
- basin radius 4.4, rim 0.55, water at 0.38
- tier 3.0 square, 1.1 high; pedestal 1.7 square, 2.4 high
- column 6.6, radius 0.46 to 0.38, bracelets 0.24 tall
- capital 0.8, globe 0.33, Victory 1.9 with her arms

## Visible details
- [x] M basin, rim, water, tier, masks, spouts, jets, pedestal, beasts, inscription panel, column, bracelets, capital, globe, Victory blockout (R1)
- [x] B the inscription (R1)
- [ ] M the masks' faces, the beasts as sphinxes, garlands on the pedestal, the railing round the basin (R2)
- [ ] B green streaks under the spouts, leaves on the water, a notice taped on (R3)
- [ ] M the Victory as a low-poly sculpture (R4)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | streaks, lichen |
| water | still water |  |  | leaves |
| gilt | gilt bronze |  |  | dulls |
| bronze | green bronze |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3200 | 1 | 50 m |
| 1 | 1550 | 1 | 150 m |
| 2 | 720 | 1 | 600 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/market_fountain_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py market_fountain --round=1`)
Differences from the references:
- the beasts are blocks, the Victory a blockout: rounds 2 and 4
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
