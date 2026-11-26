# manhole_square — the square cover with radiating diamonds (S155)

Family: `tools/models/props/road.py` · rack: `--prop-rack=manhole_square` · review: `python tools/models/review.py manhole_square --round=N`

The family of `manhole` (references, materials and rounds: `manhole.md`), after `square_radial.jpg`: a square frame with a raised border round its square hole, a square cover with a big ring, four rings of diamonds radiating from the middle, an inner ring, a slot, corner triangles. The same shaft and the same pried-off cover part.

## Measurements
- size (m): 0.80 x 1.41 x 0.80
- the frame 0.80 square, the hole 0.62; the cover 0.61, 4 cm thick; its ring r 0.27; diamonds 8, 14, 20, 26 on r 0.065, 0.15, 0.215, 0.245

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 2000 | 2 | 12 m |
| 1 | 100 | 1 | 40 m |
| 2 | 60 | 1 | 120 m |

## Moving parts
| part | pivot | motion |
|---|---|---|
| cover | its centre | moved 0.70 m to the front and up onto the road |

## Round 1 — form
Sheet: `references/elements/reviews/manhole_square_r1_sketch.png`
Differences:
- square_radial's diamonds are long lozenges pointing outward; ours are squares turned to the radius (round 2)
Fixed:
- LOD 2 a plain box so it is cheaper than LOD 1

## Review
