# chimney_stack — the plastered chimney stack of an old Paris house, with its pots (S159)

Family: `tools/models/props/roofs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py chimney_stack` · sketch: `python tools/models/props.py chimney_stack --sketch` · match: `python tools/models/match.py chimney_stack --round=N` · rack: `--prop-rack=chimney_stack` · review: `python tools/models/review.py chimney_stack --round=N`

The souche: a rendered stack standing out of the roof on the party wall, an overhanging stone coping weathered to a slope, a mortar bed round each pot and a row of terracotta pots (mitrons), one per flue. The skyline's "sea of roofs bristling with chimney pots" (S043) is made of these. `chimney_stack_long` (its own card) is the same on a long party wall.

## References
Wikimedia Commons, `references/elements/chimney_stack/` (shared with chimney_stack_long). Matched: three_pots.

| file | what it shows | source | licence |
|---|---|---|---|
| `three_pots.jpg` | **the main reference**, square-on: a rendered stack, its coping green with moss, three pots | [Cheminée Paris](https://commons.wikimedia.org/wiki/File:Chemin%C3%A9e_Paris.JPG), KoS | public domain |
| `stacks_rows.jpg` | stacks over a block's courts: long party-wall stacks, pots of every height in one and two rows, zinc cowls and pipes | [Chimneys in Paris, 15 November 2015](https://commons.wikimedia.org/wiki/File:Chimneys_in_Paris,_15_November_2015.jpg), fotologic | CC BY 2.0 |
| `pots_antennas.jpg` | a long stack of pots against the sky with TV antennas: the silhouette | [Camini Parigi](https://commons.wikimedia.org/wiki/File:Camini_Parigi.jpg), Ricce | public domain |
| `stacks_street.jpg` | brick and rendered stacks from the street, how high they stand over the roofs | [Cheminées, rue Raffet, Paris 16e](https://commons.wikimedia.org/wiki/File:Chemin%C3%A9es,_rue_Raffet,_Paris_16e_1.jpg), Polymagou | CC BY-SA 4.0 |

## Measurements
The scale: a pot is 0.22 across (the merchants' common size); on three_pots that gives ~500 px/m and pots 0.36 tall, as in the catalogues. Read off `chimney_stack_grid_three_pots.jpg`.

- size (m): 1.36 x 1.70 x 0.70
- the body 1.16 x 1.20 x 0.50 (the party wall), the roof hiding ~0.40 of it
- the coping 0.12 thick, 0.10 past the body all round, its top weathered down to its edges
- pots: Ø 0.215 at the foot, 0.195 at the top under a rolled lip, 0.36 tall, 0.28 apart, on a mortar bed Ø 0.30

## Visible details
- [x] M body with chamfered corners, coping with a weathered top, flaunching, pots with lips and dark flues (R1)
- [ ] M zinc cowls and extension pipes on some flues, a broken pot, a TV antenna on a bracket (R2: stacks_rows, pots_antennas)
- [ ] M brick variant (stacks_street), render cracked off it in patches (R2/R3)
- [ ] B moss on the coping, soot at the pots' mouths and streaks down the render, the render's damp line (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| render | grey lime render | — | — | soot streaks, damp, cracks |
| coping | stone | — | — | moss on top (three_pots) |
| mortar | flaunching | — | — | cracked |
| pot | terracotta, one of four shades per pot | — | — | soot at the mouth |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1500 | 1 | 25 m |
| 1 | 500 | 1 | 80 m |
| 2 | 200 | 1 | 400 m |

Hundreds over a town: MultiMesh. Seen mostly from afar: the far LODs keep every pot.

## Moving parts
None.

## States
clean · abandoned · damaged · burnt.

## Round 1 — form
Match: `references/elements/reviews/chimney_stack_match_r1.jpg`. Sheet: `references/elements/reviews/chimney_stack_r1.jpg`.
Differences from the references:
- three_pots' pots sit 4 cm left of the middle; the element centres them (accepted: an offset belongs to S044's placing, not the element)
- the rack's 1 m close-up looked at the plain render; the pots are the point
Fixed:
- the element says where its close-up looks (`close` in the family spec, read by `PropRack.look`)
Open:
- the render reads white on the rack; three_pots' is a darker grey with damp (round 3)

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
