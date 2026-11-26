# bus_shelter — the glass bus shelter (S170)

Family: `tools/models/props/bus_stop.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bus_shelter` · sketch: `python tools/models/props.py bus_shelter --sketch` · rack: `--prop-rack=bus_shelter` · review: `python tools/models/review.py bus_shelter --round=N`

The shelter of the main streets: a thin roof shaped like a wing over the kerb, carried by slim grey legs at the back, two glass panels behind, the lit poster case closing the left end, a perch bench along the glass, the timetable and the lines' map stuck inside, the stop's name on a blade at the roof's right end. No brand: the town's own buses.

## References
Wikimedia Commons, `references/elements/bus_shelter/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `shelter_front.jpg` | **the main reference**: the whole shelter from the front, the roof's curve, legs, glass, poster case, the totem beside | [Arrêt bus Victorien Sardou Paris 1.jpg](https://commons.wikimedia.org/wiki/File:Arr%C3%AAt_bus_Victorien_Sardou_Paris_1.jpg), Chabe01 | CC BY-SA 4.0 |
| `shelter_end.jpg` | the poster case end-on, the roof's thin edge over it, the legs' feet | [Arrêt bus Versailles Exelmans Paris 1.jpg](https://commons.wikimedia.org/wiki/File:Arr%C3%AAt_bus_Versailles_Exelmans_Paris_1.jpg), Chabe01 | CC BY-SA 4.0 |
| `smashed.jpg` | **the worn state**: the glass smashed and lying, tags all over the case | [Abris bus Paris dégradations manifestation du 23 mars 2023.jpg](https://commons.wikimedia.org/wiki/File:Abris_bus_Paris_d%C3%A9gradations_manifestation_du_23_mars_2023.jpg), Guallendra | CC BY-SA 4.0 |
| `totem.jpg` | the totem's sign and plates (`bus_stop_pole`) | [Arrêt bus Victorien Sardou Paris 2.jpg](https://commons.wikimedia.org/wiki/File:Arr%C3%AAt_bus_Victorien_Sardou_Paris_2.jpg), Chabe01 | CC BY-SA 4.0 |

## Measurements
The poster case is the standard 1.20 x 1.76 m poster (shelter_end); the roof's front edge at 2.5 m against the people under it.

- size (m): 4.40 x 2.80 x 1.75
- roof 4.40 long, from 0.70 behind the legs to 1.05 in front, 2.36 at the back rising to 2.52, thin at both edges
- legs 1.95 apart, 70 x 120 mm blades; glass from 0.14 to 2.10
- poster case 1.30 x 1.85 x 0.13, its foot 0.30
- bench 0.60 high, two perches 1.40 long

## Visible details
- [x] M roof, legs, foot plates, glass in frames, poster case, bench, timetable, map, name blade, gutter lip, the glass's rubber (R1)
- [x] B the stop's name, the timetable's rows, the map's lines, an invented poster (R1)
- [ ] M the roof's glazing bars, the case's lock, the bench's brackets (R2)
- [ ] B scratched glass, stickers, grime at the foot, the poster's light flickering (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| steel | grey | primer | rust | chips at the feet |
| roof | pale grey-green |  |  | streaks at the edge |
| glass | clear glass |  |  | scratches, tags; smashed |
| poster | lit poster |  |  | faded |
| sign | blue |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1000 | 1 | 25 m |
| 1 | 600 | 1 | 80 m |
| 2 | 250 | 1 | 250 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt; smashed glass waits for S113's breakables (the glass as `broken_pane`).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bus_shelter_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bus_shelter --round=1`)
Differences from the references:
- the reference's roof is glass with a green planted top on some; ours is a plain sheet (round 2)
Fixed:
- -
Open:
- smashed glass as a state of its own (S113)
- the poster's light per instance (S046, S108)

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
