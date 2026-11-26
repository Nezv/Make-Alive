# pram — the old pram (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py pram` · sketch: `python tools/models/props.py pram --sketch` · rack: `--prop-rack=pram` · review: `python tools/models/review.py pram --round=N`

An old pram: a deep navy body narrowing to its foot, a chrome rim and a cream cover, the hood folded up at the back on its ribs, C-springs from the axles, four spoked wheels (the back ones larger), the handle up the back with its cream grip.

## References
Wikimedia Commons, `references/elements/pram/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `navy.jpg` | **the main reference**: a navy pram with its hood, spoked wheels and chrome chassis | [Old pram at the Musée Automobile de Vendée pic-3.JPG](https://commons.wikimedia.org/wiki/File:Old_pram_at_the_Mus%C3%A9e_Automobile_de_Vend%C3%A9e_pic-3.JPG), Alf van Beem | CC0 |
| `wicker.jpg` | an older wicker pram: the hood's shape, the springs | [Baby pram.jpg](https://commons.wikimedia.org/wiki/File:Baby_pram.jpg), Jason7825 at en.wikipedia | Public domain |

## Measurements
The common pram: the handle at 1.0 m, the body 0.82 long; wheels 0.42 at the back (navy.jpg against the child mannequin beside it).

- size (m): 0.59 x 1.04 x 1.21
- body 0.82 x 0.40 from 0.45 to 0.78
- wheels 0.42 and 0.36
- the hood 0.31 forward, 0.20 up

## Visible details
- [x] M body, rim, cover, hood and ribs, springs, axles, wheels with spokes, handle and grip (R1)
- [ ] M the hood's struts and hinge, the brake (R2)
- [ ] B faded navy, rust on the chrome, mud on the tyres (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| navy | navy leathercloth |  |  | fades, tears |
| chrome | chassis |  | rust |  |
| cream | cover and grip |  |  | dirt |
| tyre | rubber |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1500 | 1 | 15 m |
| 1 | 1050 | 1 | 40 m |
| 2 | 480 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/pram_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py pram --round=1`)
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
