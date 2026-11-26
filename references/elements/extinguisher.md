# extinguisher — the extinguisher on its bracket (S194)

Family: `tools/models/props/fittings.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py extinguisher` · sketch: `python tools/models/props.py extinguisher --sketch` · rack: `--prop-rack=extinguisher` · review: `python tools/models/review.py extinguisher --round=N`

A 6 kg extinguisher on its wall bracket: the red body, the valve head with handle and lever, the safety pin, the hose round to its nozzle clipped low, the label (EAU and printed rows), the bracket.

## References
Wikimedia Commons, `references/elements/extinguisher/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `on_wall.jpg` | **the main reference**: an extinguisher on a corridor's wall: head, hose, label | [Fire Extinguisher 501.JPG](https://commons.wikimedia.org/wiki/File:Fire_Extinguisher_501.JPG), Tripl3rdmc454 | CC BY-SA 3.0 |
| `cabinet.jpg` | one in its wall cabinet | [Fire extinguisher in wall mount.jpg](https://commons.wikimedia.org/wiki/File:Fire_extinguisher_in_wall_mount.jpg), Mibrahim74 | CC BY 3.0 |

## Measurements
The common 6 kg extinguisher: 0.16 across, 0.60 tall; hung at 0.80.

- size (m): 0.19 x 0.60 x 0.37
- body radius 0.08, 0.50 tall, hung from 0.80
- hose 18 mm

## Visible details
- [x] M body, head, handle, lever, pin, hose, nozzle, label, bracket (R1)
- [x] B the label's word and rows (R1)
- [ ] M the gauge, the seal (R2)
- [ ] B dents, faded red (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| red | red |  | steel | chips |
| black | head, hose |  |  |  |
| label | white label |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 450 | 1 | 10 m |
| 1 | 300 | 1 | 30 m |
| 2 | 110 | 1 | 80 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/extinguisher_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py extinguisher --round=1`)
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
