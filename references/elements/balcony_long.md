# balcony_long — the long balcony on four consoles across three bays (S159)

Family: `tools/models/props/roofs.py` · rack: `--prop-rack=balcony_long` · review: `python tools/models/review.py balcony_long --round=N`

The same element as `balcony` (references, materials and rounds: `balcony.md`), run across three bays of a main-floor front as on `consoles_front` and `facade_long`: deeper, on four taller consoles (two at the rounded ends, two between the bays).

## Measurements
- size (m): 7.41 x 2.58 x 0.86
- the slab 7.40 long, 0.86 out, corners rounded 0.42; consoles at ±1.18 and ±3.30, 1.30 tall (consoles_front: they reach down between the ground floor's arches)

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 22000 | 1 | 25 m |
| 1 | 2400 | 1 | 80 m |
| 2 | 1200 | 1 | 400 m |

One per house at most; the hearts are most of LOD 0 (63 bays of bars).

## Round 1 — form
Sheet: `references/elements/reviews/balcony_long_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run)
Differences:
- consoles_front has three consoles under a four-bay balcony and cartouches between them; ours has four under three bays (a front's bays decide: S044 picks)
Fixed:
- (as `balcony.md`)
Open:
- the cartouches on the wall between the consoles belong to the house (S162)

## Review
