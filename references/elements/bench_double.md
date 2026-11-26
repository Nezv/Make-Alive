# bench_double — the Paris double bench (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bench_double` · sketch: `python tools/models/props.py bench_double --sketch` · rack: `--prop-rack=bench_double` · review: `python tools/models/review.py bench_double --round=N`

The banc double of the main streets and squares (Davioud's model): two seats back to back on two cast-iron end frames, each a central post with a crest, seat brackets, legs with cast rings on a foot plate, a shield on the post; three green slats a seat and a back board each side, bolted. The family's other elements: `borne` and `guard_bar` (their own cards); the hydrant of the same step is `street.py`'s.

## References
Wikimedia Commons, `references/elements/bench_double/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `end_frame.jpg` | **the main reference**, square-on: an end frame (post, crest, shield, brackets, legs of rings, foot plate) and the slats' ends | [A street bench on the bank of Canal Saint-Martin](https://commons.wikimedia.org/wiki/File:A_street_bench_on_the_bank_of_Canal_Saint-Martin,_Paris_April_2010.jpg), Pierre (Rennes) | CC BY 2.0 |
| `by_railing.jpg` | **the scale**: a whole bench along a park railing, the back board with tags, three-quarter | [Banc public Paris](https://commons.wikimedia.org/wiki/File:Banc_public_Paris.JPG), Peazapata | CC BY-SA 4.0 |
| `from_above.jpg` | from above: the slats, the gaps, the frames' tops, worn paint | [BoulevardPortRoyalBench2015](https://commons.wikimedia.org/wiki/File:BoulevardPortRoyalBench2015.JPG), Vysotsky | CC BY-SA 4.0 |
| `bornes_lane.jpg` | an old lane with stone bornes at the house corners (`borne`) | [Charles Marville, Rue de Glatigny](https://commons.wikimedia.org/wiki/File:Charles_Marville,_Rue_de_Glatigny,_ca._1853%E2%80%9370.jpg) | public domain |
| `guard_bar.jpg` | a cast-iron chasse-roue at a gate's jamb (`guard_bar`) | [Guard stone 43, rue St-Georges](https://commons.wikimedia.org/wiki/File:Guard_stone_43,_rue_St-Georges.jpg), Tangopaso | public domain |

## Measurements
The scale: the seat at 0.44 m (French benches 0.42 to 0.46); `end_frame`'s slats then come out 10.5 cm wide, three a seat, and the frame 1.0 m from seat edge to seat edge, as `by_railing`'s bench beside its railing's 1.2 m bays.

- size (m): 1.90 x 0.89 x 1.00
- slats 1.90 long, 10.5 x 3.2 cm, three a seat; the back board 0.64 to 0.80 on the post
- end frames 1.56 apart; the post's crest 0.89; the brackets reach 0.50 from the middle

## Visible details
- [x] M end frames: foot plate, post and crest, seat brackets, legs, cast rings, the shield and its boss, the back board's brackets (R1)
- [x] M slats chamfered, the back boards, carriage bolts (R1)
- [ ] M the shield's arms in relief, the brackets' pierced rings (they are rings laid on), the slats' rounded ends (R2)
- [ ] B the frames' paint chipped to rust at the feet, the slats worn pale where people sit, tags on the back boards (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | the frames' pale grey (end_frame, from_above) | red lead | rust | chips at the foot and the crest |
| slat | Paris green | grey undercoat | grey wood | worn pale on the seat's front edge |
| bolt | carriage bolts | — | rust | rust runs on the slats |
| stone | (borne) | — | — | |
| cast | (guard_bar) black | red lead | rust | |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3000 | 1 | 20 m |
| 1 | 900 | 1 | 60 m |
| 2 | 400 | 1 | 200 m |

## Moving parts
None.

## States
clean · abandoned · damaged · burnt. Overturned: placed so by S048.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bench_double_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bench_double --round=1`)
Differences from the references:
- end_frame's legs are a lattice of rings on a lyre; ours are a strut each side with three rings laid on it (round 2)
Fixed:
-
Open:
- the frames' colour: end_frame and from_above are pale grey, by_railing green; pale grey taken (S046 may seed both)

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
