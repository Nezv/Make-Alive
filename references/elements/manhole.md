# manhole — the round sewer cover in its square frame (S155)

Family: `tools/models/props/road.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py manhole` · sketch: `python tools/models/props.py manhole --sketch` · rack: `--prop-rack=manhole` · review: `python tools/models/review.py manhole --round=N`

The regard d'égout of the old streets: a square cast-iron frame set flush in the setts or the asphalt with a round seat, the round cover in it with its cast rings, its lettering and its lifting slot, the fine checker of studs cast over both, the masonry shaft with its rungs below. The cover is a part: opened, it lies pried off beside the hole (the "missing cover" state of S155 is the cover's open pose). The family's other covers: `manhole_square`, `valve_cover` (their own cards). Placed by S041.

## References
Wikimedia Commons, `references/elements/manhole/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `round_ballu.jpg` | **the main reference**, square-on from above: the square frame, the round cover, its rings, the lettering round the ring, the checker of studs, the slot, in setts | [Paris 9e Rue Ballu Plaque d'égout](https://commons.wikimedia.org/wiki/File:Paris_9e_Rue_Ballu_Plaque_d%27%C3%A9gout_670.jpg), GFreihalter | CC BY-SA 4.0 |
| `square_radial.jpg` | the square cover (`manhole_square`): the ring, the diamonds radiating, the corner triangles, the frame's border | [ManholeCoverParis2015c](https://commons.wikimedia.org/wiki/File:ManholeCoverParis2015c.JPG), Vysotsky | CC BY-SA 4.0 |
| `gaz_valve.jpg` | the gas valve cover (`valve_cover`) in a pavement, by a wall | [ManholeCoverParis2015a](https://commons.wikimedia.org/wiki/File:ManholeCoverParis2015a.JPG), Vysotsky | CC BY-SA 4.0 |
| `in_setts.jpg` | a cover in a cobbled court: the setts laid round its frame, how it reads from standing height | [20130119 - Paris - plaque d'égoût](https://commons.wikimedia.org/wiki/File:20130119_-_Paris_-_plaque_d%27%C3%A9go%C3%BBt.jpg), Pierre-Yves Beaudouin | CC BY-SA 3.0 |

## Measurements
The scale: the setts round the frame in `round_ballu` (Paris setts 14 x 20 cm: a frame side is just over four 20 cm setts) give the frame 0.86 m; the cover is then 0.65 m across (the French standard opening of 0.60 under a 0.65 cover agrees).

- size (m): 0.86 x 1.40 x 0.86 (the shaft goes 1.40 down under the road)
- the frame: 0.86 square, 0.10 deep, the seat 0.67 across chamfered 1 cm
- the cover: 0.65 across, 3.8 cm thick, 3 mm under the road; rings at r 0.30, 0.205, 0.105; letters 4.2 cm on r 0.252; the slot 8.4 x 2.6 cm
- the shaft 0.64 across, rungs 0.28 apart

## Visible details
- [x] M frame as a square plate with its round seat chamfered (R1)
- [x] M cover: rings, the lettering (EAUX over, ÉGOUTS under, read from the front; the town's name when it has one), the slot and its boss (R1)
- [x] B the checker of studs over the frame and the cover's top (`Checker`: polished tops, dark grooves) (R1)
- [x] M shaft: masonry tube, rungs, dark water (R1)
- [ ] M the setts laid round the frame (S041 lays them), a cover sunk or tilted in the road (R2)
- [ ] B rust in the grooves, polish where tyres pass, leaves and silt (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | cast iron, dark; the studs' tops polished | — | rust | rust in the grooves, polish on the tyre tracks |
| letter | the raised letters, polished | — | — | |
| hole | the slot's dark | — | — | |
| shaft | wet masonry | — | — | |
| water | dark | — | — | |
| rung | iron rungs | red lead | rust | rust |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2500 | 2 | 12 m |
| 1 | 300 | 1 | 40 m |
| 2 | 150 | 1 | 120 m |

Past 12 m the cover is closed and plain (its rings and letters baked); the shaft only exists at LOD 0, where an open cover can be seen.

## Moving parts
| part | pivot | motion |
|---|---|---|
| cover | its centre | moved 0.74 m to the front and up onto the road (pried off) |

## States
clean · abandoned · damaged · burnt. Missing cover: the part's open pose.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/manhole_r1_sketch.png`, `manhole_r1_open_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py manhole --round=1`)
Differences from the references:
- the letters round the ring came out in reverse order (XUAE): each letter was set right but the arc ran the wrong way
- the frame's square corners were cut off: the outline's samples missed the 45° corners
Fixed:
- the arc's direction (`_arc_text`)
- the frame's ring sampled from 45° so its corners are points of it
Open:
- seen from below on the rack the shaft is a dark post: in the road it is underground (accepted)
- the studs are baked, not modelled: at 1 m their relief is only paint (round 2: a normal map or a few hundred real studs if the close-up asks)

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
