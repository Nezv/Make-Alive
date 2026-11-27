# roller_shutter — the steel roller shutter of a shop or a service bay (S191)

Family: `tools/models/props/doors.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py roller_shutter` · sketch: `python tools/models/props.py roller_shutter --sketch` · rack: `--prop-rack=roller_shutter` · review: `python tools/models/review.py roller_shutter --round=N`

## References
Photos in `references/elements/roller_shutter/`, each with its source and licence.

| file | what it shows | source | licence |
|---|---|---|---|
| — | none yet: Commons is out of reach from the cloud session; they are being fetched on the PC | | |

Where: the hospital's yard (the service bay), the bus station's shops, the barracks' stores, the town's shops (S158's modern fronts).

## Measurements
Standard galvanised roller shutters (rideaux métalliques / portas de enrolar): slats of 77 mm, guides 65 x 75 mm, a box of about 40 cm for a 3 m curtain.

- size (m): 3.36 x 3.20 x 0.40
- the opening: 3.00 x 2.80, the curtain running in the guides 4 cm in front of the wall
- the guides: 6.5 cm across, 7.5 cm deep, lips either side of the curtain
- the box: 0.40 high, 0.40 deep, 7 cm past each guide, its front rounded below
- the curtain: 36 slats, a band of perforated ones between 1.55 and 1.95 m, the bottom bar 6 cm with a rubber strip, two lifting handles, the lock's cylinder
- the key switch: 1.35 m up on the wall beside it (the viewer's left), its conduit up to the box

## Visible details
- [x] M guides with their lips and fixings (R1)
- [x] M box: rounded front, end plates, the slot, a fold line (R1)
- [x] M slats: a two-plane face each, the joint's shadow, the perforated band (R1)
- [x] M bottom bar, rubber, handles, lock cylinder (R1)
- [x] M key switch and conduit (R1)
- [ ] M a dent where it was rammed, the curtain off one guide (R2, states)
- [ ] B galvanised spangle, rust at the foot, tags on the slats, grime in the guides (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | galvanised grey | — | rust | rust at the foot and the bottom bar, tags |
| box | painted grey | primer | rust | chips at the corners |
| bolt | zinc | — | rust | runs |
| rubber | black | — | — | cracked |
| brass | the lock | — | — | dull |
| dark | the slots and joints | — | — | — |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 4500 | 2 | 20 m |
| 1 | 900 | 1 | 60 m |
| 2 | 300 | 1 | 200 m |

## Moving parts
| part | pivot | motion |
|---|---|---|
| curtain | the box's slot (top of the opening, the curtain's plane) | rolls up into the box: `{"roll": 0.975}` gathers it toward the pivot (new motion: `props._opened`, `PropModel.set_open`) |

## States
clean · abandoned · damaged · burnt (paint); down, half up (crawl under) and up from the part's amount. Rammed, torn: R2.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/roller_shutter_r1_sketch.png` (sketch: every LOD and the parts open; the rack's sheet waits for a windowed run: `python tools/models/review.py roller_shutter --round=1`)
Differences from the references:
- no photo yet: sizes are from standard practice (below), to be checked against the photos with `match.py --grid` in round 2
- `roll` squashes the slats as it gathers: at half open they read 3.8 cm instead of 7.7 cm. Accepted for round 1; a real roll (slats sliding into the box) is round 2
Fixed:
- the curtain first moved up through the box: a new motion `roll` gathers it into the box instead
Open:
- the rack's sheet and the baked paint, once built on the PC

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
