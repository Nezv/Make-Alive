# bin_hoop — the bag bin on its post (S173)

Family: `tools/models/props/street_small.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py bin_hoop` · sketch: `python tools/models/props.py bin_hoop --sketch` · rack: `--prop-rack=bin_hoop` · review: `python tools/models/review.py bin_hoop --round=N`

The litter bin of the town's pavements since the bins were sealed: a flat green post bolted to the pavement, its head bent forward to hold a ring, a translucent green bag hung in the ring and folded over it. The bag is the thing seen: bulging, uneven, knotted at the bottom.

## References
Wikimedia Commons, `references/elements/bin_hoop/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `bag_hoop.jpg` | **the main reference**: the post, its base plate, the ring with its clamp, the green bag full | [Trash bin in Paris.jpg](https://commons.wikimedia.org/wiki/File:Trash_bin_in_Paris.jpg), Daniel Stockman | CC BY-SA 2.0 |

## Measurements
The ring at 0.86 m (bag_hoop: level with the bicycle saddles beside it, ~0.85 m); the ring's 0.41 m across from the bag's width against the bicycles' 0.6 m wheels.

- size (m): 0.43 x 0.92 x 0.53
- ring 0.41 across at 0.86, a flat band 12 x 36 mm
- post a flat bar 60 x 28 mm, 0.265 behind the ring's centre; base plate 0.14 x 0.10
- bag from the ring down to 0.24

## Visible details
- [x] M post, bent head, base plate and its bolts (R1)
- [x] M the ring and its clamp (R1)
- [x] M the bag: bulging, uneven, its fold over the ring (R1)
- [ ] M the ring's hinge and catch, the bag's knot and creases (R2)
- [ ] B stickers on the post, the bag's printed word, litter beside it (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| green | dark green | grey primer | rust | chips at the foot and the bend |
| bag | translucent green (opaque here) | — | — | dust |
| bolt | galvanised | — | rust | rust runs |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 700 | 1 | 15 m |
| 1 | 350 | 1 | 50 m |
| 2 | 200 | 1 | 150 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
None.

## States
clean · abandoned · damaged · burnt (the kit's paint layers).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/bin_hoop_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py bin_hoop --round=1`)
Differences from the references:
- the bag is opaque: the game's albedo has no translucency (accepted: at 1 m it reads by its colour and lumps)
Fixed:
- -
Open:
- the ring's hinge and catch (round 2)

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
