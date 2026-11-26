# railing_gate — the iron gate between two piers (S156)

Family: `tools/models/props/boundaries.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py railing_gate` · sketch: `python tools/models/props.py railing_gate --sketch` · rack: `--prop-rack=railing_gate` · review: `python tools/models/review.py railing_gate --round=N`

The gate of a railing between two piers: two leaves of bars, their top rail rising to the middle in a curve, spears on every bar, stiles and two rails, the lock box on the meeting stile, the stone sill.

## References
Wikimedia Commons, `references/elements/porte_cochere/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `arched_gate.jpg` | **the main reference**: an iron gate in a court entrance | [P1030730 Paris XII rue Rottembourg porte cochère rwk.JPG](https://commons.wikimedia.org/wiki/File:P1030730_Paris_XII_rue_Rottembourg_porte_coch%C3%A8re_rwk.JPG), Mbzt | CC BY 3.0 |
| `bury_plate28.jpg` | the gate of the railing's elevation | [Bury - Modèles de serrurerie - planche 28.jpg](https://commons.wikimedia.org/wiki/File:Bury_-_Mod%C3%A8les_de_serrurerie_-_planche_28.jpg), exemples gravés géométriquement par MM. Normand, Hibon, Thierry, Olivier, etc., | Public domain |

## Measurements
3.0 m between the piers (a carriage); the top rail 1.94 at the hinges, 2.24 at the middle.

- size (m): 3.05 x 2.43 x 0.40
- leaves 1.48 wide; bars every 0.12
- rails at 0.09 and 0.95, the stiles 50 mm

## Visible details
- [x] M leaves, bars, spears, curved top rail, rails, stiles, lock box, sill (R1)
- [ ] M the hinges' pins and collars, the drop bolt, a scroll band under the top rail (R2)
- [ ] B rust, a chain and padlock (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | black | red lead | rust |  |
| stone | the sill |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1050 | 1 | 20 m |
| 1 | 950 | 1 | 60 m |
| 2 | 500 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l | the left pier's face (-1.5, 0, 0) | rotate -95° about +Y |
| leaf_r | the right pier's face (1.5, 0, 0) | rotate 95° about +Y |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/railing_gate_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py railing_gate --round=1`)
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
