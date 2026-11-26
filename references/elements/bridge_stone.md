# bridge_stone — the old stone road bridge (S165)

Family: `tools/models/props/bridges.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bridge_stone` · sketch: `python tools/models/props.py bridge_stone --sketch` · rack: `--prop-rack=bridge_stone` · review: `python tools/models/review.py bridge_stone --round=N`

The old stone bridge of the town's centre: three elliptical arches (10 m span, 4 m rise) on two piers, the body cut from its elevation and pushed through 12 m; archivolts proud round each arch on both faces; the piers' pointed cutwaters rising from the water into half-round bays in the parapet, each with its stone bench; a cornice on corbels with a carved mask every three metres; the parapet with its coping; the road between granite kerbs, pavements of flags. y = 0 is the road, the water 6.2 m below. The stone is painted in ashlar courses (`surfaces.Bond`).

## References
Wikimedia Commons, `references/elements/bridge_stone/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `pn_1425.jpg` | **the main reference**: the demi-lunes over the piers, the cornice and its masks, lamps | [Paris, Pont Neuf -- 2014 -- 1425.jpg](https://commons.wikimedia.org/wiki/File:Paris,_Pont_Neuf_--_2014_--_1425.jpg), Dietmar Rabich | CC BY-SA 4.0 |
| `pn_1430.jpg` | from the quay: the arches, the run of the bridge | [Paris, Pont Neuf -- 2014 -- 1430.jpg](https://commons.wikimedia.org/wiki/File:Paris,_Pont_Neuf_--_2014_--_1430.jpg), Dietmar Rabich | CC BY-SA 4.0 |
| `pn_arches.jpg` | Atget: a demi-lune from below, the corbelled cornice | [Pont-Neuf - Vue des arches du pont - Paris 06 - Médiathèque de l'architecture et du patrimoine - APMH00037642.jpg](https://commons.wikimedia.org/wiki/File:Pont-Neuf_-_Vue_des_arches_du_pont_-_Paris_06_-_M%C3%A9diath%C3%A8que_de_l%27architecture_et_du_patrimoine_-_APMH00037642.jpg), Eugène Atget | Public domain |
| `pn_1901.jpg` | 1901: the arches from the water | [Le Pont-Neuf, 1901, G.5271.jpg](https://commons.wikimedia.org/wiki/File:Le_Pont-Neuf,_1901,_G.5271.jpg), Lepère, Auguste (Montmartre (ancienne commune), 30–11–1849 - Domme, 20–11–1918), graveur | CC0 |

## Measurements
A bridge of three arches over a 37 m river; deck 12 m (8 m road, 2 m pavements).

- size (m): 37.10 x 7.76 x 16.00
- arches 10 m span, crown 0.8 m under the road
- piers 3 m, bays 1.6 m radius
- parapet 1.0 m, cornice 0.45 m

## Visible details
- [x] M body, arches, archivolts, cutwaters, bays, benches, cornice, corbels, masks, parapet, road, kerbs, pavements (R1)
- [ ] M the voussoirs' joints, lanterns on the parapet, steps down to the lower quay (R2)
- [ ] B stains below the spouts, moss at the waterline, graffiti under the arches (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone in ashlar courses |  |  | soot, moss at the water |
| voussoir | the archivolts' stone |  |  |  |
| carved | corbels and masks |  |  | worn |
| asphalt | road |  |  | cracks |
| flags | pavement flags |  |  |  |
| kerb | granite kerbs |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 5820 | 1 | 60 m |
| 1 | 2250 | 1 | 200 m |
| 2 | 930 | 1 | 800 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bridge_stone_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bridge_stone --round=1`)
Differences from the references:
- the arches were too flat for the Pont Neuf's near half-rounds
Fixed:
- rise 4.0 to 4.6 on a 10 m span
Open:
- the demi-lunes stand on corbels (pn_arches.jpg), the masks are dense, lamps stand on the demi-lunes (round 2)

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
