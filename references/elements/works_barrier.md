# works_barrier — the red-and-white works barrier (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py works_barrier` · sketch: `python tools/models/props.py works_barrier --sketch` · rack: `--prop-rack=works_barrier` · review: `python tools/models/review.py works_barrier --round=N`

The French works barrier: a 2 m galvanised tube frame on two moulded plastic feet, two boards painted in red and white diagonal bands (painted by position, `_paint_rw`), bars between them, a flasher lamp clamped on the top (glowing) and the clips that join one to the next.

## References
Wikimedia Commons, `references/elements/works_barrier/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `invalides.jpg` | a run of them closing a lane by the Invalides, cones in front | [Boulevard des Invalides 1, Paris 24 August 2013.jpg](https://commons.wikimedia.org/wiki/File:Boulevard_des_Invalides_1,_Paris_24_August_2013.jpg), flightlog | CC BY 2.0 |
| `cusset.jpg` | a red and white boom closing a street: the bands' width | [Allée Pierre-Berthomier (Cusset) - Barrière sur voie en impasse 2026-08-19.JPG](https://commons.wikimedia.org/wiki/File:All%C3%A9e_Pierre-Berthomier_(Cusset)_-_Barri%C3%A8re_sur_voie_en_impasse_2026-08-19.JPG), Tabl-trai | CC BY-SA 4.0 |
| `jarente.jpg` | a works sign on its stand in an old street | [Rue de Jarente, October 31, 2010.jpg](https://commons.wikimedia.org/wiki/File:Rue_de_Jarente,_October_31,_2010.jpg), jean-louis Zimmermann | CC BY 2.0 |

## Measurements
Two metres long, a metre high, the boards 21 cm deep.

- size (m): 2.14 x 1.22 x 0.60
- boards centred at 0.30 and 0.86
- feet 0.14 x 0.13 x 0.60
- lamp on top to 1.22

## Visible details
- [x] M frame, boards, bars, feet, lamp, clips (R1)
- [ ] M the bands' angle and width against the photo (R2)
- [ ] B the feet's slots and the lamp's battery box (R2)
- [ ] B the boards' reflective sheen, scuffs (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| galv | galvanised steel |  | rust | scratches |
| rw | white board, red bands |  |  | faded red |
| base | black plastic feet |  |  | dust |
| lamp | orange lens (glows) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 800 | 1 | 20 m |
| 1 | 310 | 1 | 60 m |
| 2 | 90 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/works_barrier_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py works_barrier --round=1`)
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
