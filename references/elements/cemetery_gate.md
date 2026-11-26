# cemetery_gate — the cemetery's gate (S189)

Family: `tools/models/props/cemetery.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py cemetery_gate` · sketch: `python tools/models/props.py cemetery_gate --sketch` · rack: `--prop-rack=cemetery_gate` · review: `python tools/models/review.py cemetery_gate --round=N`

The cemetery's entrance as at the old Paris cemeteries: two broad stone pylons (plinth, shaft, band, a half-round top bearing a carved roundel with an hourglass and wings, a garland under it, the cemetery's name cut in the front: invented, CIMETIÈRE / DU NORD), the lintel across the gateway with its frieze of wreaths, a bay of the rendered wall each side on a stone base under its coping, and two plain iron leaves (parts `leaf_l`, `leaf_r`, opening in) of bars with spear tips, a cross wrought in each and plates at the foot.

## References
Wikimedia Commons, `references/elements/cemetery_gate/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `pl_entree.jpg` | **the main reference**: the pylons, roundels, garlands, the lintel of wreaths | [Père-Lachaise - entrée principale 01.jpg](https://commons.wikimedia.org/wiki/File:P%C3%A8re-Lachaise_-_entr%C3%A9e_principale_01.jpg), Coyau | CC BY-SA 3.0 |
| `pl_ext.jpg` | from the street: the wall beside, the keeper's lodge | [Cimetière du Père Lachaise entrée principale (vue ext.).jpg](https://commons.wikimedia.org/wiki/File:Cimeti%C3%A8re_du_P%C3%A8re_Lachaise_entr%C3%A9e_principale_(vue_ext.).jpg), ManoSolo13241324 | CC BY-SA 4.0 |
| `pl_revers.jpg` | from inside | [Père-Lachaise - entrée principale, revers 01.jpg](https://commons.wikimedia.org/wiki/File:P%C3%A8re-Lachaise_-_entr%C3%A9e_principale,_revers_01.jpg), Coyau | CC BY-SA 3.0 |

## Measurements
An opening of 3.2 m, pylons 1.4 x 0.8 m and 5.0 m high, the wall 2.6 m.

- size (m): 10.00 x 5.00 x 1.02
- leaves 2.8 m to the top rail
- lintel at 4.0
- roundels 0.68 across
- wall bays 2.0 m each side

## Visible details
- [x] M piers, urns, torches, name, wall bays, coping, leaves, spears, crosses (R1)
- [ ] M the keeper's lodge beside it, a notice board (R2)
- [ ] B chained shut, a leaf forced (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | soot, moss |
| wall | lime render |  |  | falling off, stains |
| iron | black iron | red primer | rust | rust |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2800 | 1 | 30 m |
| 1 | 1240 | 1 | 90 m |
| 2 | 390 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l | its hinge at the left pier (-1.60, 0, 0) | rotate -95° about +Y |
| leaf_r | its hinge at the right pier (1.60, 0, 0) | rotate 95° about +Y |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/cemetery_gate_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py cemetery_gate --round=1`)
Differences from the references:
- round 1 had slim piers with urns: pl_entree.jpg has broad round-topped pylons with roundels and a lintel
Fixed:
- pylons, roundels, garlands, the lintel and its wreaths; the pylons raised to 5 m over the 2.6 m wall
Open:
- the wall is rubble stone, not render (round 3); the leaves are hidden at Père-Lachaise: ours stay

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
