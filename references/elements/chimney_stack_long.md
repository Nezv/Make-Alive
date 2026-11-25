# chimney_stack_long — a long party-wall stack of eight flues (S159)

Family: `tools/models/props/roofs.py` · rack: `--prop-rack=chimney_stack_long` · review: `python tools/models/review.py chimney_stack_long --round=N`

The same element as `chimney_stack` (references, materials and rounds: `chimney_stack.md`), stretched along a long party wall with eight flues and pots of the heights a stack collects as its flues are rebuilt (stacks_rows, pots_antennas).

## Measurements
- size (m): 3.01 x 3.20 x 1.00 (round 2: the aerial on its mast at the right end, 2 m over the coping)
- eight pots 0.28 apart, 0.30 to 0.48 tall (`LONG_HEIGHTS`)

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3000 | 1 | 25 m |
| 1 | 900 | 1 | 80 m |
| 2 | 500 | 1 | 400 m |

## Round 1 — form
Sheet: `references/elements/reviews/chimney_stack_long_r1.jpg` (beside chimney_stack's references: `review.py` uses the family's folder for a variant)
Differences:
- stacks_rows has pots in two rows on the widest stacks and zinc cowls among them: round 2
Fixed:
- the pots' heights vary by flue

## Round 2 — structure
Sheet: `references/elements/reviews/chimney_stack_long_r2_sketch.png` (flat-shaded close-ups from the sketch renderer; the rack's review sheet `chimney_stack_long_r2.jpg` needs a windowed Godot run: `python tools/models/review.py chimney_stack_long --round=2`, left for the user).
Differences (against stacks_rows, pots_antennas):
- eight bare pots in a row; pots_antennas' long stack has a TV aerial clamped to its end and extensions on its flues, stacks_rows has cast ventilating cowls and broken pots among them
Fixed:
- extension pipes with hats on flues 2 and 7, a cast cowl (aspirateur: collar, slotted drum, mushroom cap) on flue 4, flue 6's pot broken off jagged with its flue open (`LONG_KINDS`)
- the aerial: a galvanised mast clamped twice to the +X end, a Yagi of nine elements on its boom, the reflector's grid, a dipole lower down, the cable down the mast (`_antenna`); LOD 1 three elements, LOD 2 the boom only
- size 3.01 x 3.20 x 1.00; LOD 2's budget 450 -> 500 for the aerial; triangles 2812 / 872 / 470
Open:
- the aerial is always on the +X end: S044 mirrors the element to put it on the other

## Review
