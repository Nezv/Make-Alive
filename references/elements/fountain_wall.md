# fountain_wall — the cast-iron wall fountain (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py fountain_wall` · sketch: `python tools/models/props.py fountain_wall --sketch` · rack: `--prop-rack=fountain_wall` · review: `python tools/models/review.py fountain_wall --round=N`

The drinking fountain fixed to a wall (the applied model of 1872): a dark green cast-iron plate with an arched top, a shell fanning behind a head whose mouth gives the water, a cup under it with a drop hanging below, pilasters with consoles, scrolls at the foot and a drain grating on the pavement.

## References
Wikimedia Commons, `references/elements/fountain_wall/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `applied.jpg` | **the main reference**: the whole plate face up on pallets during a restoration, square-on | [Fontaine Wallace - applied model.jpg](https://commons.wikimedia.org/wiki/File:Fontaine_Wallace_-_applied_model.jpg), Elsenyor | CC BY-SA 3.0 |
| `applied_side.jpg` | the same from the side: the depth of the head and the cup | [Fontaine Wallace - applied model 2.jpg](https://commons.wikimedia.org/wiki/File:Fontaine_Wallace_-_applied_model_2.jpg), Elsenyor | CC BY-SA 3.0 |

## Measurements
The pallets under it (1.2 m long): the plate 1.95 m tall, 0.96 m across its foot.

- size (m): 0.96 x 1.95 x 0.35
- arch centred at 1.55, radius 0.40
- the cup at 1.02, 0.34 across
- the head at 1.45; the drain 0.60 x 0.30 at the foot

## Visible details
- [x] M plate, arch moulding, shell ribs, pilasters, consoles, foot scrolls (R1)
- [x] M head with hair and crown, spout, cup, drop, drain grating (R1)
- [ ] M the face's features, the garlands, the cup's fluting (R2)
- [ ] B verdigris in the hollows, limescale under the spout (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| cast | dark green | red lead | rust | worn pale on the cup's rim |
| drain | black |  | rust |  |
| earth | the drain's slots |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1500 | 1 | 20 m |
| 1 | 800 | 1 | 60 m |
| 2 | 400 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/fountain_wall_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py fountain_wall --round=1`)
Differences from the references:
- the head is a few lumps, not the sculpted face (round 2)
- applied.jpg's plate is waisted more at the scrolls
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
