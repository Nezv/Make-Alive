# suitcase_hard — the hard-shell suitcase (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py suitcase_hard` · sketch: `python tools/models/props.py suitcase_hard --sketch` · rack: `--prop-rack=suitcase_hard` · review: `python tools/models/review.py suitcase_hard --round=N`

A hard-shell case standing on its wheels: two grey shells with ribs, the zip between them, the telescopic handle down with its grip on top, the side handle, four spinner wheels. No brand.

## References
Wikimedia Commons, `references/elements/suitcase_hard/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `shell.jpg` | **the main reference**: a hard case standing, its ribbed shell and wheels | [Samsonite Proxis.jpg](https://commons.wikimedia.org/wiki/File:Samsonite_Proxis.jpg), Joerivho | CC BY-SA 4.0 |
| `decayed.jpg` | **the worn state**: a suitcase rotted in a cellar | [Suitcase Decay (16186065183).jpg](https://commons.wikimedia.org/wiki/File:Suitcase_Decay_(16186065183).jpg), darkday from Brisbane, Australia | CC BY 2.0 |

## Measurements
The common medium case: 0.68 x 0.46 x 0.27 without its wheels.

- size (m): 0.49 x 0.79 x 0.28
- shells 0.68 high, ribs across every 8 cm
- wheels 5 cm

## Visible details
- [x] M shells, ribs, zip, handles, wheels (R1)
- [ ] M the ribs' zig-zag, the lock, the corner guards (R2)
- [ ] B scuffs, labels, a split shell (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| shell | grey polycarbonate |  |  | scuffs |
| dark | zip, handles |  |  |  |
| tyre | wheels |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 950 | 1 | 10 m |
| 1 | 330 | 1 | 30 m |
| 2 | 40 | 1 | 90 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/suitcase_hard_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py suitcase_hard --round=1`)
Differences from the references:
- shell.jpg's ribs zig-zag; ours run straight across (round 2)
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
