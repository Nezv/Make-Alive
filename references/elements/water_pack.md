# water_pack — bottled water left behind (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py water_pack` · sketch: `python tools/models/props.py water_pack --sketch` · rack: `--prop-rack=water_pack` · review: `python tools/models/review.py water_pack --round=N`

A pack of six 1.5 l bottles in its film, the film's handle on top; one bottle loose on its side, one crushed. Each bottle lathed: ribbed foot, label band, shoulders, neck and blue cap. No brand.

## References
Wikimedia Commons, `references/elements/water_pack/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `discarded.jpg` | a 1.5 l bottle: its shape, cap, label band | [City of London Cemetery discarded water drinks bottle 1.jpg](https://commons.wikimedia.org/wiki/File:City_of_London_Cemetery_discarded_water_drinks_bottle_1.jpg), Acabashi | CC BY-SA 4.0 |
| `pallets.jpg` | packs of bottles on pallets, the film | [080512-M-2764H-078 Pallets of water from USAID.jpg](https://commons.wikimedia.org/wiki/File:080512-M-2764H-078_Pallets_of_water_from_USAID.jpg), U.S. Marine Corps photo by Lance Cpl. Robert A. Harding | Public domain |

## Measurements
1.5 l bottles: 0.31 tall, 9 cm across.

- size (m): 0.80 x 0.40 x 0.62
- pack 0.28 x 0.19
- handle loop to 0.37

## Visible details
- [x] M bottles, label bands, caps, film band, handle (R1)
- [ ] M the film's wrinkles round the pack (R2)
- [ ] B empty ones; a torn pack (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| pet | clear blue plastic |  |  | dust |
| label | label band |  |  |  |
| bcap | blue caps |  |  |  |
| film | film |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1990 | 1 | 8 m |
| 1 | 1340 | 1 | 25 m |
| 2 | 380 | 1 | 80 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/water_pack_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py water_pack --round=1`)
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
