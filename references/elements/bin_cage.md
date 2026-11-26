# bin_cage — the steel-rod litter basket (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bin_cage` · sketch: `python tools/models/props.py bin_cage --sketch` · rack: `--prop-rack=bin_cage` · review: `python tools/models/review.py bin_cage --round=N`

The older town bin: a barrel of grey steel rods between a foot ring and a rolled rim, a bag inside when there is one. In the reference the bag has been stolen and the litter lies in and round it.

## References
Wikimedia Commons, `references/elements/bin_cage/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `cage.jpg` | **the main reference**: the rods' bulge, the rim, the foot; the bag stolen, litter round it | [Poubelle située rue Linné à Paris dont le sac a été volé en juin 2015.jpg](https://commons.wikimedia.org/wiki/File:Poubelle_situ%C3%A9e_rue_Linn%C3%A9_%C3%A0_Paris_dont_le_sac_a_%C3%A9t%C3%A9_vol%C3%A9_en_juin_2015.jpg), Lionel Allorge | CC BY-SA 3.0 |

## Measurements
The rim at 0.88 m against the kerb's 0.15 m and the scooter's wheel (0.40 m) beside it.

- size (m): 0.47 x 0.88 x 0.47
- 24 rods of 9 mm; 0.20 radius at the foot, 0.23 at the belly, 0.19 under the rim
- the rim flares out to 0.23 at 0.86-0.88

## Visible details
- [x] M the rods, foot ring, middle hoop, flared rim (R1)
- [x] M litter at the bottom (R1)
- [ ] M the rim's rolled lip and the foot's bolts (R2)
- [ ] B scuffs and rust on the foot ring (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| grey | pale grey | primer | rust | chips at the rim |
| litter | paper, cans | — | — |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3300 | 1 | 15 m |
| 1 | 1000 | 1 | 40 m |
| 2 | 400 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bin_cage_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bin_cage --round=1`)
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
