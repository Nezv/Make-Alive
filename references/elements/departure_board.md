# departure_board — the LED departure board (S202)

Family: `tools/models/props/terminal_signs.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py departure_board` · sketch: `python tools/models/props.py departure_board --sketch` · rack: `--prop-rack=departure_board` · review: `python tools/models/review.py departure_board --round=N`

The bus station's departure display hung under the slab on two rods: a black housing, its dark LED face, DÉPARTS over the columns LIGNE, DESTINATION, QUAI, HEURE and six invented departures (Vieille Ville, Gare, Faubourg St-Rémy, La Butte, Les Moulins, Zone Industrielle). The letters are painted amber and glow alone (`emit_where`: the pipeline's hook for lit lettering); the face around them stays dark.

## References
Wikimedia Commons, `references/elements/departure_board/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A 2.4 x 1.0 m board, its bottom 2.1 m under the slab's soffit (y = 0).

- size (m): 2.40 x 2.10 x 0.14
- rows 70 mm letters every 0.11 m
- rods 1.1 m

## Visible details
- [x] M housing, face, rods, plates, cable (R1)
- [x] M the rows as lettering, lit (R1)
- [ ] B dead, or one last message (ANNULÉ) left lit (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| housing | black steel |  | rust | dust |
| led | dark face, amber letters (glow) |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 270 | 1 | 15 m |
| 1 | 150 | 1 | 45 m |
| 2 | 60 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/departure_board_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py departure_board --round=1`)
Differences from the references:
- no photo yet: Commons refused requests while this was made; French bus station signs for round 2
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
