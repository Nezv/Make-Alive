# decals — posters, flyers and painted words (S186)

Family: `tools/models/props/decals.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py decals` · sketch: `python tools/models/props.py decals --sketch` · rack: `--prop-rack=decals` · review: `python tools/models/review.py decals --round=N`

A wall bay of what the dead town's walls carry, all paint by position on a thin plaster slab so it can be stamped on any wall and the kit's wear goes over it: QUARANTAINE, NE PAS ENTRER and MORTS À L'INTÉRIEUR sprayed with runs, an arrow to ZONE SÛRE, DISPARU flyers held by tape, an AVIS À LA POPULATION under the town's invented arms, an old election poster pasted in layers and torn, DÉFENSE D'AFFICHER painted on a white band.

## References
Wikimedia Commons, `references/elements/decals/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A house wall's bay: 4.0 x 2.6 m; the sprayed words 0.25 to 0.35 high, the band's letters 0.12.

- size (m): 4.00 x 2.60 x 0.16
- DÉFENSE D'AFFICHER 1.84 m on a 2.0 m band at 2.38
- flyers A4 and A5, the AVIS 0.45 x 0.60

## Visible details
- [x] B the sprayed words and their runs, the arrow, the flyers and their tape, the AVIS and the arms, the election poster's layers, the band (R1)
- [ ] B torn edges, paint over paint, the flyers curling (R2)
- [ ] B rain fading, sun bleaching (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plaster | the wall's plaster, painted by position |  |  | the kit's: fades, grime, soot |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 24 | 1 | 30 m |
| 1 | 14 | 1 | 100 m |
| 2 | 2 | 1 | 300 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/decals_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py decals --round=1`)
Differences from the references:
- no photos yet: the words are the step's list, the look from French wartime notices; to fetch for round 2
Fixed:
- DÉFENSE D'AFFICHER was wider than its band (1.84 m on 1.60): the band widened to 2.0 m
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
