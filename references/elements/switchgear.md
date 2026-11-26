# switchgear — the transfer switchgear (S212)

Family: `tools/models/props/generator.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py switchgear` · sketch: `python tools/models/props.py switchgear --sketch` · rack: `--prop-rack=switchgear` · review: `python tools/models/review.py switchgear --round=N`

The transfer switchgear: three grey steel cabinets on their plinths, each door with its seam, handle and louvres; meters, the green mains lamp and the red generator lamp, rows of breakers' handles on the outer two; on the middle one the yellow plate marked MARCHE / ARRÊT and the start lever (part `lever`) the players throw from OFF up to START; the cable tray over them with cables dropping in.

## References
Wikimedia Commons, `references/elements/switchgear/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
Cabinets 0.8 x 2.0 x 0.6.

- size (m): 2.80 x 2.48 x 0.70
- lever at 1.15
- tray at 2.40

## Visible details
- [x] M cabinets, doors, louvres, meters, lamps, breakers, plate, lever, tray (R1)
- [ ] M the lamps lit by the generator's state (S212)
- [ ] B warning signs, a burnt cabinet (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| grey | grey cabinets |  | rust | scratches |
| yellow | the lever's plate |  |  |  |
| red | generator lamp (glows) |  |  |  |
| green | mains lamp (glows) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1450 | 1 | 20 m |
| 1 | 860 | 1 | 60 m |
| 2 | 140 | 1 | 200 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| lever | its boss (0, 1.15, -0.35) | rotate 150° about -Z: up to START |

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/switchgear_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py switchgear --round=1`)
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
