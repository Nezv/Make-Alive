# <name> — <one line: what it is>

Family: `tools/models/props/<family>.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py <name>` · sketch: `python tools/models/props.py <name> --sketch` · rack: `--prop-rack=<name>` · review: `python tools/models/review.py <name> --round=N`

## References
Photos in `references/elements/<name>/`, each with its source and licence. Old Paris first; never model from memory.

| file | what it shows | source | licence |
|---|---|---|---|
| `ref_1.jpg` | | | |

## Measurements
Taken against something of known size (a 2.1 m door, a 12 m bus, a 15 cm kerb, a 1.75 m person); say which.

- size (m): W x H x D        ← tests/test_elements.gd reads this line; the model must be within 5 %
- 

## Visible details
Every form that catches light, as a list. Tick when modelled (M) or baked (B).

- [ ] 

## Materials
One line per face tag: top coat, primer under it, what is under that, how it wears.

| tag | coat | under | bare | wear |
|---|---|---|---|---|

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | | | m |
| 1 | | 1 | m |
| 2 | | 1 | m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|

## States
clean · abandoned · damaged · burnt — what each changes.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/<name>_r1.jpg`
Differences from the references:
- 
Fixed:
- 

## Round 2 — structure (the secondary forms)
Sheet: `references/elements/reviews/<name>_r2.jpg`
Differences:
- 
Fixed:
- 

## Round 3 — surface (wear, lettering, colour variation, states)
Sheet: `references/elements/reviews/<name>_r3.jpg`
Differences:
- 
Fixed:
- 

## Review
What is left, each item fixed or accepted with a reason.
