# rowboat — a small rowing boat (S184)

Family: `tools/models/props/remains.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py rowboat` · sketch: `python tools/models/props.py rowboat --sketch` · rack: `--prop-rack=rowboat` · review: `python tools/models/review.py rowboat --round=N`

A small aluminium rowing boat for the river (S047), drawn upright; the river turns it over: the hull lofted from sections (a vee at the bow rising to its stem, flatter aft), painted green outside and bare inside, the transom, gunwale rails, three thwarts, ribs, the rowlocks, two oars laid in her.

## References
Wikimedia Commons, `references/elements/rowboat/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `lake.jpg` | a small painted boat by a shore: the thwarts, the sheer | [Aluminium boat, Mahamaya Lake (01).jpg](https://commons.wikimedia.org/wiki/File:Aluminium_boat,_Mahamaya_Lake_(01).jpg), Moheen Reeyad | CC BY-SA 4.0 |
| `skiffs.jpg` | aluminium skiffs beached | [Beaching the skiffs - panoramio.jpg](https://commons.wikimedia.org/wiki/File:Beaching_the_skiffs_-_panoramio.jpg), palm_ak | CC BY 3.0 |

## Measurements
A 3.6 m boat, 1.4 m beam.

- size (m): 1.42 x 0.60 x 3.62
- depth 0.48 amidships, the bow 0.60
- thwarts 0.13 under the gunwale

## Visible details
- [x] M hull, transom, rails, thwarts, ribs, rowlocks, oars (R1)
- [ ] M rivet lines along the strakes; the stem (R2)
- [ ] B dents, the paint flaking off the aluminium (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| hullpaint | green paint outside | aluminium |  | flaking |
| alu | bare aluminium |  |  | dull, scratches |
| oar | varnished oars |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1810 | 1 | 25 m |
| 1 | 510 | 1 | 75 m |
| 2 | 120 | 1 | 250 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/rowboat_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py rowboat --round=1`)
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
