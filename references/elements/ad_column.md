# ad_column — the colonne Morris, Paris's dark green advertising column (S171)

Family: `tools/models/props/advertising.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py ad_column` · sketch: `python tools/models/props.py ad_column --sketch` · rack: `--prop-rack=ad_column` · review: `python tools/models/review.py ad_column --round=N`

A cast-iron drum the theatre posters are pasted round, on a bulging foot, under an octagonal cornice with a lettered frieze, an onion dome and a finial. It stands on the pavements of the main streets and the squares. Posters are invented (no real brands or titles).

## References
Wikimedia Commons, `references/elements/ad_column/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `paris16_717.jpg` | **main reference**: whole column from the side, foot panels, stiles, cornice, dome, finial | [Paris 16e Colonne Morris 717](https://commons.wikimedia.org/wiki/File:Paris_16e_Colonne_Morris_717.jpg), GFreihalter | CC BY-SA 4.0 |
| `paris16_716.jpg` | the cornice, the lion mask on the corner, the dome's scales, a fluted stile | [Paris 16e Colonne Morris 716](https://commons.wikimedia.org/wiki/File:Paris_16e_Colonne_Morris_716.jpg), GFreihalter | CC BY-SA 4.0 |
| `paris18_778.jpg` | the cornice and dome from below, the lion mask, the scalloped fringe | [Paris 18e Colonne Morris 778](https://commons.wikimedia.org/wiki/File:Paris_18e_Boulevard_Marguerite_de_Rochechouart_Colonne_Morris_778.jpg), GFreihalter | CC BY-SA 4.0 |
| `blason.jpg` | the frieze's roundel with the city's arms, the raised lettering, the dome's scale pattern | [blason de Paris](https://commons.wikimedia.org/wiki/File:Paris_-_Colonne_Morris_-_blason_de_Paris.JPG), Ordifana75 | CC BY-SA 3.0 |
| `observatoire.jpg` | **old** (Marville, 1860s): the same column among trees; its size against the pavement and the trees | [avenue de l'Observatoire](https://commons.wikimedia.org/wiki/File:Colonne_Morris,_avenue_de_l%27Observatoire,_14%C3%A8me_arrondissement,_Paris._PH4157.jpg), Marville | CC0 |
| `renversee_1934.jpg` | **worn / damaged**: a column knocked over in the riots | [6 février 1934](https://commons.wikimedia.org/wiki/File:Les_manifestations_du_06_f%C3%A9vrier_1934_%C3%A0_Paris,_colonne_Morris_renvers%C3%A9e.jpg), Agence Meurisse | public domain |

## Measurements
Taken against the posters' drum (a pasted sheet is ~0.9 m high, two courses fill it: the drum is 1.8 m of posters at 1.2 m across) and against a person in the Marville print (the column reads ~2 x a person to the cornice's top, a little over 3 m to the finial). No photo is square-on, so `match.py` is not used: proportions were read off `paris16_717` by pixel rows (drum 890 px ≈ 1.8 m).

- size (m): 1.47 x 3.5 x 1.47
- foot: 0.70 radius, 0.64 high (a plinth, a shoulder with twelve raised panels, a bulging ring with beads)
- drum: 0.60 radius, 1.8 high, between two iron rings; three fluted stiles
- cornice: octagonal, corner radius 0.73, frieze 2.44-2.74 with raised SPECTACLES / THÉÂTRES / CONCERTS and a lion mask on each corner
- dome: onion, ribs and three rows of scales over a scalloped fringe, to 3.20; finial to 3.50

## Visible details
- [x] M foot: plinth, panels, beaded ring (R1)
- [x] M drum, iron rings, three fluted stiles (R1)
- [x] M octagonal cornice with bracket mouldings (R1)
- [x] M raised lettering on the frieze, lion masks, the arms' roundel (R2)
- [x] M the dome: ribs, scales, fringe; the finial (R2)
- [x] M the service door on the back: panel, escutcheon, hinges (R2)
- [x] B posters (invented theatre bills) in two courses of eight sheets, overpasted edges, bars of small print (R3)
- [x] B states: torn sheets with an older bill and the iron showing (abandoned), a quarantine notice pasted over them (abandoned, damaged), soot (burnt)
- [ ] a lamp or a lit poster frame at night (not in the references)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | dark green | red lead | cast iron | chips at edges, rust runs |
| letter | green | red lead | iron | chips on the raised faces |
| poster | pasted paper, painted by sheet | older bill | green sheet-iron | torn, grimed at the foot |
| door | green | red lead | iron | rust at the fixings |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 9000 | 2 | 25 m |
| 1 | 2600 | 1 | 80 m |
| 2 | 800 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned (half torn, quarantine notice) · damaged (notice, pocks) · burnt. Knocked over by a car (`renversee_1934`) is not a state of this model: a fallen column needs its own placement and is left for the street-dressing step.

## Round 1 — form
Sheet: `references/elements/reviews/ad_column_r1.jpg`
Differences from the references:
- the first sketch's cornice was 1.63 wide (corner radius taken as a flat's distance): 0.1 m too wide against the drum
- the dome read flat and wide beside `paris16_717`
Fixed:
- corner radius 0.73 (1.47 wide); dome narrower at its foot and taller (crown 3.20)

## Round 2 — structure
Sheet: `references/elements/reviews/ad_column_r2.jpg`
Differences (against `paris16_716`, `paris18_778`, `blason`):
- the poster headlines ran over their neighbours (sheets are 0.47 m wide round the drum, "LA TRAVIATA" is 9.4 letter-heights long)
- the dome is a flatter, wider cap than the references' tall onion with its swelling; the scales read as studs at 10 m
- the lion masks and the arms' roundel are small bosses, the roundel does not read as arms; the frieze lettering is only legible within 3 m
Fixed:
- type sized to fit the sheet (`lettering.width`)
Open (accepted for now): the onion's swelling, a real shield on the roundel (the town's arms arrive with S245; this step's roundel is a blank disc until then)

## Round 3 — surface
Sheet: `references/elements/reviews/ad_column_r3.jpg`
Differences:
- abandoned and damaged: rust blotches over the dome and the cornice were too red and too even (`paris16_716` is clean green; the worn reference shows rust only at edges)
- the quarantine notice reads at 10 m, the torn sheets show an older bill and the green iron, as wanted
Fixed:
- iron chips 1.0 -> 0.45, letters 1.4 -> 0.8
Open: the blotches remain stronger than the photos on the two worn states (the kit's chip layer is by patch, not by edge only); not a model fault, left for a wear pass.

## Review
Sheets: `ad_column_r1.jpg`, `_r2.jpg` (round 3's paint is in r2). Accepted: the dome's shape, the roundel's blank disc (S245), a fallen column (street dressing). Not done: a lamp at night.
