# wire_coil — concertina wire on pickets (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py wire_coil` · sketch: `python tools/models/props.py wire_coil --sketch` · rack: `--prop-rack=wire_coil` · review: `python tools/models/review.py wire_coil --round=N`

A 3 m run of concertina wire: a coil of loops 0.9 m across, razor barbs along it, three angle-iron pickets (ends and middle) and a straight wire along their tops.

## References
Wikimedia Commons, `references/elements/wire_coil/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `coil.jpg` | **the main reference**: a coil of razor wire, its loops and barbs | [Barbed wire in Monaco.jpg](https://commons.wikimedia.org/wiki/File:Barbed_wire_in_Monaco.jpg), Tiia Monto | CC BY-SA 3.0 |
| `on_wall.jpg` | coils laid along a wall of gabions: their size against people | [591st Engineer Company places Concertina Wire on top of HESCO barriers at NDA 2.png](https://commons.wikimedia.org/wiki/File:591st_Engineer_Company_places_Concertina_Wire_on_top_of_HESCO_barriers_at_NDA_2.png), Staff Sgt. Adelina Garcia | Public domain |

## Measurements
The common coil: 0.9 m across, loops every 0.2 m when stretched.

- size (m): 3.04 x 1.15 x 0.91
- coil radius 0.45, pitch 0.22, wire 3.5 mm
- pickets 1.15 tall, 40 mm angle

## Visible details
- [x] M coil, barbs, pickets, the top wire (R1)
- [ ] M the clips where loops meet, the pickets' holes and ties (R2)
- [ ] B rust, rags caught in it (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| wire | galvanised wire |  | rust | rust |
| picket | olive angle iron |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2400 | 1 | 15 m |
| 1 | 850 | 1 | 40 m |
| 2 | 560 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/wire_coil_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py wire_coil --round=1`)
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
