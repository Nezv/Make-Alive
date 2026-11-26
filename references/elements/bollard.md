# bollard — the Paris cast-iron potelet (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bollard` · sketch: `python tools/models/props.py bollard --sketch` · rack: `--prop-rack=bollard` · review: `python tools/models/review.py bollard --round=N`

The cast-iron post that keeps cars off the pavements: a slim baluster on a flared foot, a collar near the top, a neck and a ball. Rows of them along every kerb of the old town.

## References
Wikimedia Commons, `references/elements/bollard/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `potelets_aubry.jpg` | **the main reference**: a row of potelets, near ones square-on (foot, shaft, collar, neck, ball); one painted orange | [Cité Aubry (Paris), potelets.jpg](https://commons.wikimedia.org/wiki/File:Cit%C3%A9_Aubry_(Paris),_potelets.jpg), Coyau | CC BY-SA 3.0 |
| `potelets_row.jpg` | a row along a street, painted in colours; the white one shows the collar band | [Potelets colorés à Paris (10276915545).jpg](https://commons.wikimedia.org/wiki/File:Potelets_color%C3%A9s_%C3%A0_Paris_(10276915545).jpg), Krisztina.Konczos | CC BY-SA 2.0 |

## Measurements
Against the doors and the kerb in potelets_aubry: ~1.0 m to the top of the ball, 0.10 m across the shaft.

- size (m): 0.12 x 1.00 x 0.12
- foot 0.12 across, shaft 0.09 tapering to 0.08
- collar 0.80-0.84, neck at 0.88, ball 0.09 across at 0.94

## Visible details
- [x] M foot, tapering shaft, collar, neck, ball (R1)
- [x] M the white band at the collar (R1)
- [ ] M the foot's flare in steps (R2)
- [ ] B scrapes from bumpers, stickers (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| cast | dark brown-grey | red lead | rust | chips at the foot, a bumper's scrape |
| band | white reflective | — | — |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 400 | 1 | 20 m |
| 1 | 150 | 1 | 60 m |
| 2 | 80 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bollard_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bollard --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- the coloured ones of potelets_row (a palette per instance, S046)

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
