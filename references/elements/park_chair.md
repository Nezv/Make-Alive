# park_chair — the iron garden chair (S190)

Family: `tools/models/props/park.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py park_chair` · sketch: `python tools/models/props.py park_chair --sketch` · rack: `--prop-rack=park_chair` · review: `python tools/models/review.py park_chair --round=N`

The iron chair of French public gardens: a frame of round rod, the back legs running up into the back, raked; a seat of slats dipping in the middle, curved slats across the back, a stretcher between the legs, caps on the feet. Painted garden green.

## References
Wikimedia Commons, `references/elements/park_chair/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `rows.jpg` | c. 1900: chairs stacked along a terrace of the Luxembourg | [Chaises rangées le long d'une terrasse du jardin du Luxembourg, 6ème arrondissement, Paris, PH77098.jpg](https://commons.wikimedia.org/wiki/File:Chaises_rang%C3%A9es_le_long_d%27une_terrasse_du_jardin_du_Luxembourg,_6%C3%A8me_arrondissement,_Paris,_PH77098.jpg), Blancard, Hippolyte (1843 - 1924), photographe | CC0 |

## Measurements
Seat at 0.43, back to 0.84, 0.44 wide.

- size (m): 0.49 x 0.84 x 0.63
- seat 0.44 x 0.46
- eight seat slats, five back slats

## Visible details
- [x] M frame, seat and back slats, stretchers, feet (R1)
- [ ] M the armchair and the low lounging chair (R2)
- [ ] B tipped over; rusted through (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| chair | green paint over iron | red primer | rust | chips, rust |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 740 | 1 | 12 m |
| 1 | 490 | 1 | 40 m |
| 2 | 230 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/park_chair_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py park_chair --round=1`)
Differences from the references:
- the close photo of a chair was dropped (it showed an institution's mark): a plain one to find for round 2
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
