# tomb_cross — a cast-iron cross on its pedestal (S189)

Family: `tools/models/props/cemetery.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py tomb_cross` · sketch: `python tools/models/props.py tomb_cross --sketch` · rack: `--prop-rack=tomb_cross` · review: `python tools/models/review.py tomb_cross --round=N`

A cast-iron cross on its stone pedestal: a base, the die with a bronze plaque (ICI REPOSE, J. DUVAL, 1802 - 1861, invented), a cornice, the cross with trefoil ends, a ring at its crossing, scrolls in its angles, its socket.

## References
Wikimedia Commons, `references/elements/tomb_cross/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `cast_cross.jpg` | **the main reference**: a cast-iron cross with trefoils and a ring on a white pedestal | [Lucheux cimetière (croix de fonte) tombe DONNETTE-HURET.jpg](https://commons.wikimedia.org/wiki/File:Lucheux_cimeti%C3%A8re_(croix_de_fonte)_tombe_DONNETTE-HURET.jpg), Markus3 (Marc ROUSSEL) | CC BY-SA 3.0 |
| `alley.jpg` | a cemetery's main alley: crosses, obelisks, chapels in rows | [Cimetière de Vichy, allée principale.jpg](https://commons.wikimedia.org/wiki/File:Cimeti%C3%A8re_de_Vichy,_all%C3%A9e_principale.jpg), TCY | CC BY-SA 4.0 |

## Measurements
cast_cross: the pedestal 0.84 high against the brick wall; the cross 1.25.

- size (m): 0.72 x 2.16 x 0.86
- pedestal 0.72 square at its base, die 0.54
- cross bar 0.72 at 1.69, ring 0.24 across

## Visible details
- [x] M base, die, cornice, plaque, cross, ring, trefoils, scrolls, socket (R1)
- [x] B the plaque's words (R1)
- [ ] M the Christ figure on some, the pierced arms (R2)
- [ ] B rust running onto the stone (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone |  |  | lichen, black streaks, moss at the foot |
| iron | black cast iron | red lead | rust | rust runs |
| plaque | bronze plaque |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 720 | 1 | 15 m |
| 1 | 350 | 1 | 50 m |
| 2 | 80 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/tomb_cross_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py tomb_cross --round=1`)
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
