# barrier_crowd — the grey crowd barrier (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py barrier_crowd` · sketch: `python tools/models/props.py barrier_crowd --sketch` · rack: `--prop-rack=barrier_crowd` · review: `python tools/models/review.py barrier_crowd --round=N`

The galvanised crowd barrier of French streets: a 2.0 m frame of tube with rounded top corners, a bottom rail, sixteen bars, two flat feet bent into low bridges under its ends, hooks at the right end and eyes at the left so a run of them chains. Bays join along x.

## References
Wikimedia Commons, `references/elements/barrier_crowd/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `stacked.jpg` | **the main reference**: barriers stacked, square-on: frame, bars, feet, hooks | [Absperrgitter.JPG](https://commons.wikimedia.org/wiki/File:Absperrgitter.JPG), 4028mdk09 | CC BY-SA 3.0 |
| `deauville.jpg` | a long run of them chained across a beach in Normandy | [Crowd control barriers on the beach - 37th G8 summit in Deauville 027.jpg](https://commons.wikimedia.org/wiki/File:Crowd_control_barriers_on_the_beach_-_37th_G8_summit_in_Deauville_027.jpg), Guillaume Paumier | CC BY 3.0 |

## Measurements
The common barrier: 2.0 m long, 1.1 m high (stacked.jpg against the fence's mesh).

- size (m): 2.11 x 1.14 x 0.69
- tube 40 mm, bars 18 mm, sixteen
- bottom rail at 0.16, the frame's foot at 0.12
- feet 0.66 long, 50 mm flat bar

## Visible details
- [x] M frame, rail, bars, feet, legs, hooks, eyes (R1)
- [ ] M the bars' welds, the feet's rubber pads (R2)
- [ ] B scuffed galvanising, rust at the welds, stickers (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| galv | galvanised steel |  | rust | dull, scuffed |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 800 | 1 | 20 m |
| 1 | 400 | 1 | 60 m |
| 2 | 160 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/barrier_crowd_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py barrier_crowd --round=1`)
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
