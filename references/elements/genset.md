# genset — the emergency diesel generator set (S212)

Family: `tools/models/props/generator.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py genset` · sketch: `python tools/models/props.py genset --sketch` · rack: `--prop-rack=genset` · review: `python tools/models/review.py genset --round=N`

The hospital's emergency generator set: a steel skid of channels on its mounts; the green engine block with its sump, rocker covers, injector pipes and manifolds, the yellow air filter; the radiator at the front behind the bars of its fan guard, its cap and hose; the ribbed alternator behind with its terminal box and the cables down to the trench; the exhaust rising through its bellows to the silencer over the set and away; the control box with its lamps on a bracket.

## References
Wikimedia Commons, `references/elements/genset/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A 500 kVA set: 2.8 x 1.1 m, the engine 1.1 m high on its skid.

- size (m): 2.87 x 2.40 x 1.16
- skid 0.20
- radiator 1.24 high
- silencer at 1.80

## Visible details
- [x] M skid, engine, filter, radiator, guard, alternator, cables, exhaust, bellows, silencer, control box (R1)
- [ ] M belts and the fan behind the guard, the starter batteries (R2)
- [ ] B oil on the skid, warning signs, rust; running: shaking and smoke (S212 states)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| engine | green engine paint | grey primer | steel | oil, chips |
| pipe | rusted exhaust |  | rust |  |
| yellow | air filter |  |  |  |
| steel | skid, guard |  | rust |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1680 | 1 | 20 m |
| 1 | 810 | 1 | 60 m |
| 2 | 310 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/genset_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py genset --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; photos first for round 2
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
