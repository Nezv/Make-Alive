# reverbere — the réverbère on its rope (S167)

Family: `tools/models/props/lamps.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py reverbere` · sketch: `python tools/models/props.py reverbere --sketch` · rack: `--prop-rack=reverbere` · review: `python tools/models/review.py reverbere --round=N`

The lantern of about 1800 hung across the street: a glass box widening upwards on a pointed foot, corner posts, a pyramid roof, a reflector dish over the flame, a hook on its top and the rope rising from it both ways (1.4 m of the span each side; the span is S167's). Its foot y = 0.

## References
Wikimedia Commons, `references/elements/reverbere/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Engravings of Paris réverbères: the lantern 0.6 m across its top, 0.9 m tall with its roof.

- size (m): 2.81 x 1.44 x 0.64
- glass 0.42 tall, 0.40 to 0.56 across
- rope 12 mm

## Visible details
- [x] M foot, glass, posts, roof, reflector, flame, hook, rope (R1)
- [ ] M the reflector's second dish, the panes' leading (R2)
- [ ] B soot on the glass, a smashed lantern as a state (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| iron | black iron |  | rust |  |
| glass | lit glass |  |  | soot |
| reflector | tinned reflector |  |  |  |
| rope | hemp rope |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 380 | 1 | 25 m |
| 1 | 250 | 1 | 80 m |
| 2 | 130 | 1 | 250 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/reverbere_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py reverbere --round=1`)
Differences from the references:
- no engraving fetched yet: one to fetch for round 2
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
