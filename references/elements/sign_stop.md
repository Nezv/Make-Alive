# sign_stop — the French STOP sign on its pole (S169)

Family: `tools/models/props/signs_street.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py sign_stop` · rack: `--prop-rack=sign_stop` · review: `python tools/models/review.py sign_stop --round=N`

The French road signs on their poles, made one way: an aluminium plate with a rolled edge, its face painted by position (`_paint_stop`, `_paint_giveway`, `_paint_no_entry`: so the kit's wear and damage go over the paint), two rails across its back with a clamp round the pole each, a galvanised pole with its cap and collar. This card holds the family's references; `sign_giveway` and `sign_no_entry` have short cards.

## References
Wikimedia Commons, `references/elements/sign_stop/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `stop_fleuri.jpg` | a STOP on its pole by a road, square-on: the octagon, the word, the white edge | [Panneau de stop fleuri](https://commons.wikimedia.org/wiki/File:Panneau_de_stop_fleuri.jpg), TCY | CC0 |
| `giveway_lyon.jpg` | a cédez-le-passage in a town with its distance plate, faded, a sticker on it, the pole and clamps | [Lyon 7e, Rue Lamothe](https://commons.wikimedia.org/wiki/File:Lyon_7e_-_Rue_Lamothe,_panneau_c%C3%A9dez-le-passage_(sept_2022).jpg), Sebleouf | CC BY-SA 4.0 |
| `giveway_back.jpg` | a give-way with its plate under it, beside a road: the height, the pole | [Panneau Cédez Passage, Chemin Romagne](https://commons.wikimedia.org/wiki/File:Panneau_C%C3%A9dez_Passage_Chemin_Romagne_St_Cyr_Menthon_2.jpg), Chabe01 | CC BY-SA 4.0 |

## Measurements
The French standard's "normal" range: STOP 0.70 across its flats, the give-way triangle 0.90 a side (the town's smaller range of 1.0 m signs is not used), no-entry 0.65 across; the lowest edge 2.20 m over the pavement (2.30 asked where people walk under: the poles stand at the kerb); poles 76 mm.

- size (m): 0.71 x 2.99 x 0.11
- the octagon 0.70 across its flats; STOP's letters fill half its width; a white edge of 1.8 cm
- the pole 2.95 tall and its cap

## Visible details
- [x] M the plate and its rolled edge, two rails and clamps with their bolts, the pole, its cap and collar (R1)
- [x] B the red face, the white edge, STOP (R1)
- [ ] M the distance plate under a give-way (giveway_lyon), a bent sign, a sign shot through (R2)
- [ ] B faded red (giveway_lyon), stickers, the retroreflective sheeting catching the flashlight (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| face | the painted face (red / white) | grey | aluminium | fades, stickers, scratches |
| back | grey aluminium | — | — | grime |
| galv | galvanised steel | — | rust | white bloom, rust at the foot |
| cap | black plastic cap | — | — | |
| bolt | the clamps' bolts | — | rust | rust runs |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 600 | 1 | 25 m |
| 1 | 250 | 1 | 80 m |
| 2 | 120 | 1 | 300 m |

## Moving parts
None.

## States
clean · abandoned · damaged · burnt. Bent, knocked over: placed so by S048.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/sign_stop_r1_sketch.png`, faces flat: `signs_r1_faces.png` (the rack's sheet waits for a windowed run)
Differences from the references:
- the word first stood 0.20 tall and ran over the octagon's sides
- the give-way's lower rail stuck out past the triangle's sides
Fixed:
- STOP fitted to half the octagon's width
- each rail 85 % of the sign's width at its height (`_width_at`)
Open:
- the face's letters are the kit's block font; the standard's lettering is narrower (round 2)

## Review
