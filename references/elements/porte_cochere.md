# porte_cochere — the carriage gateway (S156)

Family: `tools/models/props/boundaries.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py porte_cochere` · sketch: `python tools/models/props.py porte_cochere --sketch` · rack: `--prop-rack=porte_cochere` · review: `python tools/models/review.py porte_cochere --round=N`

The gateway of a house to its court: an opening with a low segmental head in a broad stone surround, its reveal, two great leaves of raised panels opening into the court, a fixed panel in the arch over a transom, the knob, the letter plate, the hinge straps, the stone sill and a cast-iron chasse-roue at each jamb's foot. The wall's face is z = 0 (the house +Z).

## References
Wikimedia Commons, `references/elements/porte_cochere/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `square_on.jpg` | **the main reference**, square-on: blue leaves of panels, the segmental head, the letter plate, the chasse-roues | [Porte cochère - Paris.JPG](https://commons.wikimedia.org/wiki/File:Porte_coch%C3%A8re_-_Paris.JPG), Celette | CC BY-SA 3.0 |
| `carved.jpg` | a carved oak gateway of a grander house: the fixed panel in the arch, the knockers | [Paris Porte cochère rue La Bruyère 2012.jpg](https://commons.wikimedia.org/wiki/File:Paris_Porte_coch%C3%A8re_rue_La_Bruy%C3%A8re_2012.jpg), JLPC | CC BY-SA 3.0 |
| `worn_1900.jpg` | **the worn state**: an old gateway with posters, flaking paint, a cobbled foot | [Porte cochère, 15 rue Barbette, 3ème arrondissement, Paris. PH37531.jpg](https://commons.wikimedia.org/wiki/File:Porte_coch%C3%A8re,_15_rue_Barbette,_3%C3%A8me_arrondissement,_Paris._PH37531.jpg), Union Photographique Française, photographe | CC0 |
| `arched_gate.jpg` | a round-arched court entrance closed by an iron gate (`railing_gate`) | [P1030730 Paris XII rue Rottembourg porte cochère rwk.JPG](https://commons.wikimedia.org/wiki/File:P1030730_Paris_XII_rue_Rottembourg_porte_coch%C3%A8re_rwk.JPG), Mbzt | CC BY 3.0 |

## Measurements
square_on: the leaves against the window beside them and the pavement's 0.15 m kerb; 2.5 m wide (a carriage) and 3.2 m to the springing.

- size (m): 3.10 x 3.44 x 0.50
- opening 2.50 x 3.20, the head rising 0.22
- surround 0.30 broad, 0.06 proud
- leaves 1.25 x 3.12 x 0.07, set 0.22 back; a low panel to 1.05
- chasse-roues 0.62 high, 0.20 out

## Visible details
- [x] M surround and its inner moulding, reveal, soffit, tympanum, transom, sill, chasse-roues (R1)
- [x] M leaves of raised panels, battement, knob, letter plate and slot, hinge straps (R1)
- [ ] M the wicket door in one leaf, knockers, studs, the panels' mouldings (R2)
- [ ] B flaking paint at the foot, posters, tags (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| wood | dark blue paint | grey undercoat | grey wood | flakes at the foot, bumper scrapes |
| stone | limestone |  |  | damp at the foot |
| brass | knob and plate |  |  | polished where touched |
| iron | black | red lead | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 950 | 1 | 30 m |
| 1 | 400 | 1 | 90 m |
| 2 | 200 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| leaf_l | the left jamb at the reveal's back | rotate -95° about +Y, into the court |
| leaf_r | the right jamb | rotate 95° about +Y |

## States
clean · abandoned · damaged · burnt; open / shut by the leaves; rammed waits for S048.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/porte_cochere_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py porte_cochere --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- the wicket door, its own part in the left leaf (round 2)

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
