# window_french — the tall French casement of an old Paris plaster front (S157)

Family: `tools/models/props/windows.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py window_french` · sketch: `python tools/models/props.py window_french --sketch` · match: `python tools/models/match.py window_french --round=N` · rack: `--prop-rack=window_french` · review: `python tools/models/review.py window_french --round=N`

The window of the plastered stone houses (S162) and the window kit's first element. A fenêtre à la française: two leaves of panes opening into the room, persiennes (louvred shutters) closing in a rebate in the wall's face and folding back flat against it, a low iron garde-corps between the jambs, a stone sill. The other kinds of S157 (the timber houses' small casements, post-war ribbon glazing) are their own elements of the same family, after this one.

## References
Wikimedia Commons, `references/elements/window_french/`. Matched (straightened onto the wall, `match.json`): frontal_white, tall_railing.

| file | what it shows | source | licence |
|---|---|---|---|
| `frontal_white.jpg` | **the main reference**, square-on: the rebate, the reveal and its head down to the frame, two leaves, white persiennes folded open with their middle rail and catch, the garde-corps, the sill band, the raised plate over the head | [Bord de fenêtre Paris 7ème](https://commons.wikimedia.org/wiki/File:Bord_de_fen%C3%AAtre_Paris_7%C3%A8me.jpg), Dinkum | CC0 |
| `tall_railing.jpg` | a taller one: three panes up each leaf, the garde-corps' cast scrolls and lattice, the stone sill's ends | [Paris Auteuil 10 Rue du Buis](https://commons.wikimedia.org/wiki/File:Paris_Auteuil_10_Rue_du_Buis_594.jpg), GFreihalter | CC BY-SA 3.0 |
| `brick_railing.jpg` | **the scale**: brick courses (6.5 cm) beside the opening, persiennes folded in the reveal, a deep stone sill on corbels | [Paris Fenster mit Gitter](https://commons.wikimedia.org/wiki/File:Paris_Fenster_mit_Gitter740.JPG), GFreihalter | CC BY-SA 3.0 |
| `blue_frontal.jpg` | persiennes louvred above and panelled below, their catches; a plain stone sill | [Auvers-sur-Oise Rue Daubigny](https://commons.wikimedia.org/wiki/File:Auvers-sur-Oise_(95)_Rue_Daubigny_Fen%C3%AAtre_260.jpg), GFreihalter | CC BY-SA 4.0 |
| `worn_shutters.jpg` | the abandoned look: paint flaking off the persiennes to grey wood, four panes up each leaf, raised plates over the heads | [Bourges Rue des 3 Bourses](https://commons.wikimedia.org/wiki/File:Bourges_(18)_Rue_des_3_Bourses_Fen%C3%AAtres_963.jpg), GFreihalter | CC BY-SA 4.0 |
| `frontal_open_shutters.jpg` | the same window with its shutters' shadows: how far they stand off the wall | [Paris 10e Rue de la Grange-aux-Belles](https://commons.wikimedia.org/wiki/File:Paris_10e_Rue_de_la_Grange-aux-Belles_634.jpg), GFreihalter | CC BY-SA 4.0 |
| `open_leaves.jpg` | the leaves open into the room, persiennes half open, from below | [Paris 18e Rue Durantin 10](https://commons.wikimedia.org/wiki/File:Paris_18e_Rue_Durantin_10_937.jpg), GFreihalter | CC BY-SA 3.0 |
| `pair_cartouches.jpg` | two on a front: spacing, a shutter half closed, garde-corps | [Paris Auteuil 4 Rue du Buis](https://commons.wikimedia.org/wiki/File:Paris_Auteuil_4_Rue_du_Buis_593.jpg), GFreihalter | CC BY-SA 3.0 |
| `street_row.jpg` | a street front of them over shops, from below (the context) | [Paris 15e Rue du Commerce](https://commons.wikimedia.org/wiki/File:Paris_15e_Rue_du_Commerce_682.jpg), GFreihalter | CC BY-SA 4.0 |

## Measurements
The scale: on brick_railing the opening is 1.30 m between the reveal's edges (31 brick courses of 6.5 cm = 2.0 m beside it); frontal_white's reveal is taken as the same 1.30, which makes its persiennes' slats 6.7 cm apart (Paris persiennes: 6 to 7 cm) and its watering can 0.45 m: both agree. Everything else read off `window_french_grid_frontal_white.jpg` (`match.py --grid`, 10 cm squares).

- size (m): 1.80 x 2.73 x 0.935
- the sill: top 0.08 above its bottom, 1.60 long, 5.5 cm in front of the wall
- the rebate the persiennes close in: 1.40 x 2.41 over the sill, 5 cm deep
- the reveal: 1.30 wide, head 2.44; the frame 1.23 x 2.20 (0.20 back from the wall's face); the reveal's head comes down to the frame (2.28) and its jambs in to it
- the leaves: stiles 5 cm, meeting stiles 7.5 cm each, top rail 5.5, bottom rail 11; three panes up each (tall_railing, blue_frontal; frontal_white has two, worn_shutters four)
- the persiennes: 0.70 x 2.40 each, 3.4 cm thick, stiles 5.5 cm, middle rail at 1.40 (the catch), slats 6.7 cm apart tilted 35°
- the garde-corps: top rail at 0.80 (0.72 over the sill), across the reveal (1.30)
- the raised plate over the head: 1.80 x 0.24, 1 cm proud
- the element brings 0.16 m of wall round the rebate; the house cuts a hole 1.72 x 2.65 for it (`windows.hole()`)

## Visible details
Every form that catches light. M modelled, B baked; the round that does it.

- [x] M sill slab with chamfered top edges (R1)
- [x] M rebate, reveal and its head stepping down to the frame (R1)
- [x] M frame: jambs, head, sill rail standing forward (R1)
- [x] M two leaves: stiles, rails, meeting stiles proud, glazing bars, panes (R1)
- [x] M persiennes: stiles, rails, middle rail, tilted slats (R1); one board past 15 m
- [x] M garde-corps: rails and bars (R1, plain)
- [x] M raised plate over the head (R1)
- [x] M garde-corps: the cast panel's scrolls, rosette and lattice, its fixings into the jambs (R2)
- [x] M persiennes: hinges (pentures) and their pins on the wall, the catch on the middle rail, the bolt down the inner stile (R2); the shutter dogs belong to the wall (S162)
- [x] M leaves: the battement over the meeting stiles, the drip moulding (jet d'eau) on each bottom rail, the hinge knuckles, the frame's sill rail washed (R2); the espagnolette is inside (not seen from the street)
- [x] M sill: the drip groove under its nose (R2)
- [ ] B glass that reflects the sky unevenly, net curtains behind some (R3)
- [ ] B dirt in the frame corners, flaking paint on the frame and persiennes (worn_shutters), streaks under the sill (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plaster | cream lime render | — | — | grime, streaks under the sill and plate (R3) |
| stone | limestone | — | — | dirt on top, moss on the shaded nose |
| joinery | white oil paint | grey undercoat | grey weathered oak | flakes at the bottom rails first |
| persienne | white (later: grey, sage, blue by seed) | pale undercoat | grey wood | flakes in sheets (worn_shutters) |
| glass | dark, reflecting the sky | — | — | cracks, holes (damaged) |
| iron | black paint | red lead | rust | rust at the fixings, runs down the plaster |
| room | the dark room behind | — | — | lit at night (R3: emission) |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 6000 | 5 | 15 m |
| 1 | 1200 | 1 | 50 m |
| 2 | 800 | 1 | 300 m |

Repeated along a front: MultiMesh (`PropModel.multimesh`). A street shows a hundred: past 15 m the slats are baked onto one board.

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l, leaf_r | the frame's jamb, behind | turn 100° into the room about Y |
| shutter_l, shutter_r | the rebate's outer edge at the wall's face | turn 178° out and back flat against the wall about Y |

## States
clean · abandoned · damaged · burnt (paint); open, shut, shutters closed come from the parts. Broken (shards in the frame), boarded, burnt with soot above, lit warm / TV-blue / dark at night: R3.

## Round 1 — form (silhouette, proportions, real size)
Match: `references/elements/reviews/window_french_match_r1.jpg` (the first build's match was overwritten; its differences are below). Sheet: `references/elements/reviews/window_french_r1.jpg`.
Differences from the references:
- the first build had a raised band down both sides of the rebate: no reference has one (frontal_white and worn_shutters have a raised plate over the head only)
- two panes up each leaf, after frontal_white: tall_railing, blue_frontal and the card's "small panes" want three or more
- between the frame (1.23) and the reveal (1.30) the room showed through as a black slot each side; frontal_white has a light strip of reveal there
- the sill ran 0.96 each side, past the head plate; tall_railing's ends 0.10 past the rebate
- the meeting stiles 6 cm each against frontal_white's 8
- past 15 m the persiennes were frames with nothing in them (LOD 2 had no slats): a closed window read as an open one
- the parts are merged at rest past LOD 0, so far windows always show their persiennes closed; most of a street has them open
Fixed:
- no side band; a 1.80 x 0.24 raised plate over the head
- three panes up each leaf (`PANE_ROWS`)
- the reveal's jambs come in to the frame like its head
- sill 1.60 long
- meeting stiles 7.5 cm
- persiennes one board past LOD 0 (the slats baked onto it)
- from the review sheet (`window_french_r1.jpg`): opened, the persiennes were grey: their backs had baked their AO against the rebate they close in. Fixed in the pipeline: the AO is baked with the moving parts moved apart (`props._parts_apart`, every element with parts)
Open:
- at 50 m (LOD 2) the persiennes' board reads as pale flat panes: the slats' lines do not survive the UV transfer from LOD 0 (round 3, with the paint)
- seen from behind on the rack the room is a black box: in a house it is inside the wall (accepted)
- far windows with their persiennes open: LOD 1 and 2 for the open pose, or open and closed as two elements; decided with S044's MultiMesh placement

## Round 2 — structure (the secondary forms)
Sheet: `references/elements/reviews/window_french_r2_sketch.png` (flat-shaded close-ups from the sketch renderer; the rack's review sheet `window_french_r2.jpg` needs a windowed Godot run: `python tools/models/review.py window_french --round=2`, left for the user).
Differences (against tall_railing, frontal_white, worn_shutters):
- the garde-corps was a rail and eleven plain bars; tall_railing's is a cast panel: an oval with a rosette in the middle, C-scrolls winding out of it, a lattice in each top corner, small scrolls in the corners, a moulded handrail
- the persiennes hung on nothing: frontal_white shows three pentures on each, their pins in the rebate's edge, a catch on the middle rail, a bolt down the inner stile
- the leaves' bottom rails were flat; every reference has the sloped jet d'eau over the sill, and the right leaf's battement covering the joint
- the sill's underside was flat (water would run back to the wall)
Fixed:
- the garde-corps panel as flat iron bars swept along spirals and an oval (`_spiral`, `_ellipse`, `_lattice`): frame, standards, oval and inner ring, rosette of six petals, three pairs of scrolls, lattices framed, a cast leaf, fixing lugs into the jambs; LOD 1 keeps the oval and the two big scroll pairs, LOD 2 seven bars
- pentures with their spade ends and nails, pins (gonds) with their arms into the wall, the catch with its knob and bar, the bolt (`hardware`: painted with the shutters, its fixings rust)
- jet d'eau on each leaf, the battement on the right leaf, two hinge knuckles per leaf
- the sill's drip groove; the frame's sill rail washed off to the front
- triangles 5884 / 1064 / 660 (budget 6000 / 1200 / 800)
Open:
- the shutter dogs (arrêts) that hold the open persiennes stand on the wall 0.7 m out: the house (S162) places them, so the element's size stays the opening's
- the rosette and leaves are prisms, not carved: enough at 1 m (round 3 bakes their relief)

## Round 3 — surface (wear, lettering, colour variation, states)
Sheet: `references/elements/reviews/window_french_r3.jpg`
Differences:
-
Fixed:
-

## Review
What is left, each item fixed or accepted with a reason.
