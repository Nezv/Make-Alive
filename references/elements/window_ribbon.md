# window_ribbon — one 2.40 m bay of the post-war band window (S157)

Family: `tools/models/props/windows.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py window_ribbon` · sketch: `python tools/models/props.py window_ribbon --sketch` · rack: `--prop-rack=window_ribbon` · review: `python tools/models/review.py window_ribbon --round=N`

## References
Photos in `references/elements/window_ribbon/`, each with its source and licence.

| file | what it shows | source | licence |
|---|---|---|---|
| — | none yet: Commons is out of reach from the cloud session; they are being fetched on the PC | | |

Where: the hospital's tower (its back's band of windows per floor), the town hall's office floors, the bus station's ticket hall. Bays side by side make the ribbon; each end post is half a mullion, so they join without a seam.

## Measurements
Standard 1960s-70s French and Brazilian office glazing: a structural bay of 2.40 m (two 1.20 m lights), sill at desk height under it, the head at the slab's soffit.

- size (m): 2.40 x 1.49 x 0.69
- the sill: precast, its top 0.06 above its bottom, 5 cm in front of the face, a drip under the nose
- the opening: 2.40 bay, sill to head 1.39 (top 1.45); the head is the slab edge, 4 cm deep
- the frame: anodised aluminium, 7 cm deep, its face 5 cm back; posts 5 cm (the ends half that), the transom at 1.10
- the lights: a fixed pane on the viewer's left, the sliding sash on the right in the inner track, a top-hung vent over each half
- the room behind: 0.50 deep, a venetian blind's head showing under the head

## Visible details
- [x] M sill with its washed top and drip (R1)
- [x] M head soffit and its drip edge (R1)
- [x] M frame: head, sill rail, end posts, mullion, transom (R1)
- [x] M fixed pane with its bead, sliding sash with grip and lock lever, two top-hung vents with stays (R1)
- [x] M weep slots in the sill rail (R1)
- [x] M the blind's head behind the glass (R1)
- [ ] M the blind's slats half down in some bays, a broken pane (R2, states)
- [ ] B streaks under the sill, grime in the tracks, sky in the glass (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| concrete | precast grey | — | — | streaks and lichen under the sill, black runs from the slab edge |
| alu | natural anodised | — | — | dull, grime in the tracks |
| glass | dark, reflecting the sky | — | — | cracks, holes (damaged) |
| blind | off-white slats | — | — | yellowed |
| dark | the weep slots, the grip | — | — | — |
| room | the dark room | — | — | lit at night (R3) |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1200 | 4 | 15 m |
| 1 | 500 | 1 | 50 m |
| 2 | 300 | 1 | 300 m |

Repeated along a band: MultiMesh (`PropModel.multimesh`). A tower shows hundreds: past 50 m the moving parts are glass alone.

## Moving parts
| part | pivot | motion |
|---|---|---|
| sash | its bottom corner on the mullion side | slides 1.09 m toward the viewer's left, behind the fixed pane |
| vent_l, vent_r | the head, at the frame | foot swings out 28° about X |

## States
clean · abandoned · damaged · burnt (paint); open and shut from the parts. Broken panes, the blind hanging out (the town hall), lit at night: R2-R3.

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/window_ribbon_r1_sketch.png` (sketch: every LOD and the parts open; the rack's sheet waits for a windowed run: `python tools/models/review.py window_ribbon --round=1`)
Differences from the references:
- no photo yet: sizes are from standard practice (below), to be checked against the photos with `match.py --grid` in round 2
- the transom at 1.10 leaves vents 0.30 high: right for 1970s office bands, check against the hospital's photo
Fixed:
- the glazing bead first drawn as a solid sheet over the fixed pane: now a rim of four strips
Open:
- the rack's sheet and the baked paint, once built on the PC

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
