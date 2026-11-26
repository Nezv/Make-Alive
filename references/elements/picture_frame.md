# picture_frame — a fallen picture frame (S196)

Family: `tools/models/props/clutter.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py picture_frame` · sketch: `python tools/models/props.py picture_frame --sketch` · rack: `--prop-rack=picture_frame` · review: `python tools/models/review.py picture_frame --round=N`

A picture fallen off its nail: the frame face to the wall, leaning back against it at 70°, its back board and hanging wire to the room, the picture behind, its glass in pieces on the floor in front. The wall's face is z = 0.

## References
Wikimedia Commons, `references/elements/picture_frame/`.

| file | what it shows | source | licence |
|---|---|---|---|

## Measurements
A 0.50 x 0.40 frame, 25 mm deep.

- size (m): 0.56 x 0.43 x 0.39
- frame moulding 50 mm
- glass shards 3 to 10 cm

## Visible details
- [x] M frame, back board, wire, picture, glass pieces (R1)
- [ ] M the back's tacks, a split corner (R2)
- [ ] B the picture's print, a stain (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| frame | stained wood |  |  | chips |
| board | card back |  |  |  |
| picture | the print |  |  |  |
| glass | glass |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 270 | 1 | 8 m |
| 1 | 190 | 1 | 25 m |
| 2 | 110 | 1 | 60 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/picture_frame_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py picture_frame --round=1`)
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
