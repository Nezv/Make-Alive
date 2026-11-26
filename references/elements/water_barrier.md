# water_barrier — the water-filled plastic barrier (S185)

Family: `tools/models/props/checkpoint.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py water_barrier` · sketch: `python tools/models/props.py water_barrier --sketch` · rack: `--prop-rack=water_barrier` · review: `python tools/models/review.py water_barrier --round=N`

The hollow plastic road barrier filled with water: a jersey-like profile 0.8 m high, ribs moulded up its sides into three bays, forklift slots through the foot, two filling caps on top, a drain plug, and the knuckles that lock it to the next (two at one end, one at the other).

## References
Wikimedia Commons, `references/elements/water_barrier/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `connected.jpg` | a row of them locked together, caps and knuckles | [Plastic road barriers can be connected filled with water emptied.JPG](https://commons.wikimedia.org/wiki/File:Plastic_road_barriers_can_be_connected_filled_with_water_emptied.JPG), Tomwsulcer | CC0 |
| `street.jpg` | one alone across a road, a sandbag on it | [Moscow, roadworks barrier, June 2026 04.jpg](https://commons.wikimedia.org/wiki/File:Moscow,_roadworks_barrier,_June_2026_04.jpg), Retired electrician | CC0 |

## Measurements
The common module: 1.5 m long, 0.8 m high, 0.44 m at the foot.

- size (m): 1.68 x 0.82 x 0.47
- profile 0.44 at the foot to 0.20 at the top
- knuckles 0.10 across, 0.16 tall
- caps 0.13 across

## Visible details
- [x] M body, ribs, slots, caps, plug, knuckles (R1)
- [ ] M the bays' recess and the top's handle hollows (R2)
- [ ] B a red one beside the white for the rows (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| smv | white plastic |  |  | grime, green streaks |
| cap | black caps and slots |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 450 | 1 | 20 m |
| 1 | 340 | 1 | 60 m |
| 2 | 80 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/water_barrier_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py water_barrier --round=1`)
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
