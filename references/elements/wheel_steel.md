# wheel_steel — the steel wheel and its tyre (S179)

Family: `tools/models/props/vehicle_kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py wheel_steel` · sketch: `python tools/models/props.py wheel_steel --sketch` · rack: `--prop-rack=wheel_steel` · review: `python tools/models/review.py wheel_steel --round=N`

The kit's wheel: a 195/65 R15 tyre with bulged sidewalls, tread blocks in the shoulders and four grooves round, on a black steel rim (flanges, well, a disc set in to the hub, eight ventilation holes, four nuts). Standing on the ground, its axle along x, the outer face -x.

## References
Wikimedia Commons, `references/elements/wheel_steel/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `steel_rim.png` | a steel rim and its tyre: the disc, the holes, the flange | [MB W100 Fulda Diadem 9.00 H 15.png](https://commons.wikimedia.org/wiki/File:MB_W100_Fulda_Diadem_9.00_H_15.png), Mustavi | CC BY-SA 4.0 |

## Measurements
195/65 R15: 0.635 m across, 0.195 wide; the rim 15 inches.

- size (m): 0.21 x 0.64 x 0.64
- tyre radius 0.3175, rim radius 0.19
- nuts on a 0.10 circle

## Visible details
- [x] M tyre, tread blocks, grooves, rim, disc, holes, hub, nuts (R1)
- [ ] M the sidewall's lettering, a plastic hubcap as a variant, the alloy rim (R2)
- [ ] B flat and burnt states: no tyre, brown-black rim (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| tyre | rubber |  |  | dust, kerb scuffs |
| rim | black steel |  | rust | rust at the flange |
| nut | nuts |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1900 | 1 | 12 m |
| 1 | 700 | 1 | 40 m |
| 2 | 300 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/wheel_steel_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py wheel_steel --round=1`)
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
