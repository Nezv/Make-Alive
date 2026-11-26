# street_plate — the blue enamel street name plate (S169)

Family: `tools/models/props/signs_street.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py street_plate` · sketch: `python tools/models/props.py street_plate --sketch` · rack: `--prop-rack=street_plate` · review: `python tools/models/review.py street_plate --round=N`

The street's name on a house's corner: a blue enamel field with white letters and a white line inside a raised green cast frame, rosettes over the screws at its corners and the arch's top, a half-round plate over it with the quarter's name. Its words are paint (`_paint_street`, the kit's lettering), so the wear goes over them. The family's traffic signs: `sign_stop` (their card), `sign_giveway`, `sign_no_entry`.

## References
Wikimedia Commons, `references/elements/street_plate/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `plate_beaubourg.jpg` | **the main reference**, square-on: the frame, the rosettes, the arch with the arrondissement, two lines of letters, the white line | [Plaque Rue Beaubourg](https://commons.wikimedia.org/wiki/File:Plaque_Rue_Beaubourg_-_Paris_III_(FR75)_-_2023-04-15_-_3.jpg), Chabe01 | CC BY-SA 4.0 |
| `plate_damesme.jpg` | another, the enamel crazed, a screw rusting, on pebbled render | [Plaque Rue Damesme](https://commons.wikimedia.org/wiki/File:Plaque_Rue_Damesme_-_Paris_XIII_(FR75)_-_2021-07-21_-_3.jpg), Chabe01 | CC BY-SA 4.0 |

## Measurements
The scale: Paris plates' letters stand 7 to 8 cm; with `RUE` at 7.5 cm the plate comes out 0.72 x 0.40 and the arch 0.40 x 0.15, as plate_beaubourg's proportions.

- size (m): 0.74 x 0.57 x 0.033
- the plate 0.72 x 0.40, the arch 0.40 wide and 0.15 tall over it; the frame 3.2 cm, 0.6 cm proud; rosettes 5 cm
- letters 7.5 cm (two lines), the quarter's 4.5 cm

## Visible details
- [x] M the enamel field and the arch as one plate, the raised frame round both, five rosettes (R1)
- [x] B white letters RUE / PASTEUR and CENTRE (an invented town's street from `CityStreets.NAMES`), the white line (R1)
- [ ] B any street's name per plate: the game needs the text per instance (a decal of letters, or a plate per name baked on demand: with S046)
- [ ] B the enamel crazed and chipped to black iron round the screws, rust weeping from them (R3: plate_damesme)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| enamel | blue vitreous enamel, white letters | — | black iron | chips round the screws, crazing |
| frame | green paint on cast iron | red lead | rust | chips |
| face, back, galv, cap, bolt | (the traffic signs) | | | |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 800 | 1 | 15 m |
| 1 | 250 | 1 | 40 m |
| 2 | 60 | 1 | 120 m |

## Moving parts
None.

## States
clean · abandoned · damaged · burnt. Hanging by one screw: S046.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/street_plate_r1_sketch.png`, the painted faces flat: `signs_r1_faces.png` (the rack's sheet waits for a windowed run)
Differences from the references:
- plate_beaubourg's letters are a serifed roman; ours are the kit's block font (round 2: a serif font in `lettering.py`)
Fixed:
-
Open:
- one name for every plate (see the list above)

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
