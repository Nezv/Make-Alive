# ammo_carton — a carton of rounds (S152)

Family: `tools/models/props/containers.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py ammo_carton` · sketch: `python tools/models/props.py ammo_carton --sketch` · rack: `--prop-rack=ammo_carton` · review: `python tools/models/review.py ammo_carton --round=N`

The carton `ammo_box.gd` drops: brown card, the flaps' seam taped over and down the ends, the calibre's band round it (white here: its colour per calibre is the game's, `Weapons.AMMO`), 50 CARTOUCHES printed.

## References
Wikimedia Commons, `references/elements/ammo_crate/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `stacks.jpg` | cartons stacked by the crates at a resupply | [1-118th Field Artillery resupplies (6009479096).jpg](https://commons.wikimedia.org/wiki/File:1-118th_Field_Artillery_resupplies_(6009479096).jpg), Georgia National Guard from United States | CC BY 2.0 |

## Measurements
The game's carton (0.22 x 0.11 x 0.14).

- size (m): 0.22 x 0.11 x 0.14
- band 0.07 wide, 0.05 in from the left end
- tape 44 mm

## Visible details
- [x] M box, band, tape over the seam and ends (R1)
- [x] B 50 CARTOUCHES, MUNITIONS (R1)
- [ ] M the flaps' edges, a torn corner (R2)
- [ ] B damp, scuffs (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| card | brown card |  |  | scuffs, damp |
| stripe | the band |  |  |  |
| tape | brown tape |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 140 | 1 | 6 m |
| 1 | 70 | 1 | 15 m |
| 2 | 30 | 1 | 40 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/ammo_carton_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py ammo_carton --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- the band's colour per calibre (a material override per instance, S046)

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
