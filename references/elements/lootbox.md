# lootbox — the steel supply chest (S152)

Family: `tools/models/props/containers.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py lootbox` · sketch: `python tools/models/props.py lootbox --sketch` · rack: `--prop-rack=lootbox` · review: `python tools/models/review.py lootbox --round=N`

The supply chest that `lootbox.gd` opens: olive pressed steel, ribs round the body, corner guards, folding handles at the ends, two over-centre clasps on the front, the lid with a raised panel hinged along the back. The same 0.90 x 0.50 x 0.60 as today's box, so its node and click body stay.

## References
Wikimedia Commons, `references/elements/lootbox/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `steel_can.jpg` | **the main reference**: a steel ammunition can, its lid open: the clasp, the hinge, the pressed ribs, the stencils | [(US) CAL.30M1 AMMUNITION BOX, REEVES, 2002.1917.jpg](https://commons.wikimedia.org/wiki/File:(US)_CAL.30M1_AMMUNITION_BOX,_REEVES,_2002.1917.jpg), Anonyme | CC0 |

## Measurements
The game's box (0.90 x 0.50 x 0.60); the can's clasp and hinge scaled up from its 0.28 m length.

- size (m): 0.97 x 0.52 x 0.64
- body 0.90 x 0.42 x 0.60, lid 0.08 with a 0.016 raised panel
- ribs at 0.10 and 0.32
- clasps at ±0.30

## Visible details
- [x] M body, ribs, corner guards, handles, clasps and keepers, hinge knuckles, lid and panel, the inside's shadow (R1)
- [x] B SECOURS and 07 stencilled (R1)
- [ ] M the clasps' levers and pins, the lid's rubber seal (R2)
- [ ] B chipped olive to the primer at the corners (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| olive | olive drab | grey primer | steel | chips at the edges and corners |
| steel | the hardware |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 500 | 1 | 15 m |
| 1 | 350 | 1 | 40 m |
| 2 | 40 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| lid | the back's top edge (0, 0.42, 0.30) | rotate 110° about +X: up and back |

## States
clean · abandoned · damaged · burnt; open / shut by the lid; empty and broken open wait for round 3.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/lootbox_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py lootbox --round=1`)
Differences from the references:
- lootbox.gd hinges its lid on the -Z edge: when the look is swapped the node turns 180° (S152's last item)
Fixed:
- -
Open:
- hooking it into lootbox.gd in place of the boxes

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
