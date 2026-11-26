# balcony — the stone balcony on consoles of the main floor (S159)

Family: `tools/models/props/roofs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py balcony` · sketch: `python tools/models/props.py balcony --sketch` · rack: `--prop-rack=balcony` · review: `python tools/models/review.py balcony --round=N`

The balcony of the étage noble of the plastered stone houses (S162): a stone slab with a moulded edge and rounded front corners, carried on scrolled consoles, a wrought-iron railing of square bars with hearts of C-scrolls between them in a band under the handrail and a small one at the foot. `balcony` serves one window; `balcony_long` (its own card) runs along three bays of a front, on four consoles. The house sets the consoles' feet on its wall at `roofs.balcony_floor(spec)` under the floor it serves.

## References
Wikimedia Commons, `references/elements/balcony/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `consoles_front.jpg` | **the main reference**: a long balcony on its consoles over the arched ground floor, from below: the slab's moulded edge and rounded ends, the railing's bars and two bands of hearts, three tall consoles with acanthus and the cartouches between | [Paris 61 rue des Petits-Champs 2012 1](https://commons.wikimedia.org/wiki/File:Paris_61_rue_des_Petits-Champs_2012_1.jpg), Lionel Allorge | CC BY-SA 3.0 |
| `consoles_below.jpg` | the consoles from below and the side: the big volute under the slab with its eye, the neck, the small volute at the foot, the soffit; a railing of scrolls | [6 rue de Valois, balcon](https://commons.wikimedia.org/wiki/File:6_rue_de_Valois,_balcon.jpg), Racinaire | CC BY-SA 3.0 |
| `facade_long.jpg` | **the scale and context**: the same house whole, square-on: the balcony over three bays of the first floor, the single balconettes above, floor heights | [Paris 61 rue des Petits-Champs 2012 3](https://commons.wikimedia.org/wiki/File:Paris_61_rue_des_Petits-Champs_2012_3.jpg), Lionel Allorge | CC BY-SA 3.0 |
| `street_row.jpg` | a street of such fronts: the single-window balconies of the first floor beside long ones | [Paris 39 rue des Petits-Champs 2012 1](https://commons.wikimedia.org/wiki/File:Paris_39_rue_des_Petits-Champs_2012_1.jpg), Lionel Allorge | CC BY-SA 3.0 |

## Measurements
The scale: the French windows behind the railing in `consoles_front` taken as 1.25 m between their frames (as window_french's 1.23 frame), which puts their centres 2.36 m apart and the railing at 1.05 m: the French rule for a garde-corps (1.00 m) agrees.

- size (m): 1.91 x 2.08 x 0.58
- the slab: 1.90 long, 0.58 out from the wall, its front corners rounded 0.24, 0.26 thick with its moulding (fillet, torus, cavetto, corona, the soffit stepping 9 cm in)
- two consoles 0.24 wide, 1.24 apart, 0.80 tall under the slab, 0.36 out at the top
- the railing 1.00 over the floor, 7 cm in from the slab's edge; square bars 14 mm, 0.118 apart; hearts 0.20 tall under the handrail and 0.12 at the foot

## Visible details
Every form that catches light. M modelled, B baked; the round that does it.

- [x] M slab lofted through its moulding, rounded front corners, the lead flashing on its top edge (R1)
- [x] M consoles: the side profile (big volute under the slab, neck, small volute at the foot), the volutes' eyes on both sides, an abacus, a leaf down the front, drops under the foot (R1)
- [x] M railing: moulded handrail, bottom rail, the band's rail, square bars, hearts of two C-scrolls between each pair of bars in two bands, lugs into the wall, the bars' feet leaded into the slab (R1)
- [ ] M the leaf as a carved acanthus (it is stepped blocks), the console's front panel, the cartouches between the consoles of the long one (they belong to the wall: S162) (R2)
- [ ] M the railing's ends curling down onto the slab (pc61's ends), collars where the scrolls meet the bars (R2)
- [ ] B stone: black crust under the slab and in the volutes, streaks from the bars' feet, the soffit's damp; iron: rust at the feet (R3)
- [ ] B plants, a chair, laundry on some (R3, with S044)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| stone | limestone, cream | — | — | black crust under the slab, streaks below the bars' feet |
| iron | black paint | red lead | rust | rust at the feet and the lugs |
| lead | grey lead flashing | — | — | white bloom |
| fixing | the lugs into the wall | red lead | rust | rust runs down the stone |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 8000 | 1 | 20 m |
| 1 | 1200 | 1 | 60 m |
| 2 | 700 | 1 | 300 m |

Past LOD 0 the hearts go (the bars and rails stay): seen past 20 m the railing reads as bars, as it does in `street_row`.

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (paint). A broken railing hanging off, a slab fallen in the street: with S044.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/balcony_r1_sketch.png` (flat-shaded close-ups from the sketch renderer; the rack's review sheet needs a windowed Godot run: `python tools/models/review.py balcony --round=1`, left for the user). No square-on photo of a single balcony: `match.py` waits for one.
Differences from the references:
- the hearts first took 9 segments a scroll: 9 472 triangles for 1.9 m, more than the window it serves
- the consoles' drops hung 5 cm under the feet (below y = 0)
Fixed:
- 6 segments for the top band's scrolls, 4 for the foot's (6 784 triangles)
- the drops end at the foot
Open:
- the leaf down the console's front is stepped blocks, not a carved leaf (round 2)
- consoles_front's railing ends curl down onto the slab; ours end square on the wall (round 2)

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
