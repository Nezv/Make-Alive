# mattress — a mattress dumped on the street (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py mattress` · sketch: `python tools/models/props.py mattress --sketch` · rack: `--prop-rack=mattress` · review: `python tools/models/review.py mattress --round=N`

A double mattress lying on the pavement: its quilted top bellying between the piping, one end curled up, the middle sagging; the piping round both edges, tufting buttons in a grid, the handles and vents on its sides.

## References
Wikimedia Commons, `references/elements/mattress/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `ostia.jpg` | one dumped on paving: the piping, the stains | [Abandoned mattress in Ostia.jpg](https://commons.wikimedia.org/wiki/File:Abandoned_mattress_in_Ostia.jpg), Kaga tau | CC BY-SA 4.0 |
| `park.jpg` | one left against a railing at night | [Mattress in the Park.jpg](https://commons.wikimedia.org/wiki/File:Mattress_in_the_Park.jpg), Alan Stanton | CC BY-SA 2.0 |

## Measurements
A double: 1.90 x 1.40 x 0.20.

- size (m): 1.91 x 0.28 x 1.42
- curl 5 cm at one end

## Visible details
- [x] M body, piping, buttons, handles, vents (R1)
- [ ] M one folded over a car roof, roped (R2)
- [ ] B stains and tears (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| ticking | cream ticking |  |  | stains, dirt |
| piping | piping, buttons |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1250 | 1 | 15 m |
| 1 | 380 | 1 | 45 m |
| 2 | 90 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/mattress_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py mattress --round=1`)
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
