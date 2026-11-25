# shopfront — the wooden front of an old Paris shop (devanture en applique) (S158)

Family: `tools/models/props/shopfronts.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py shopfront` · sketch: `python tools/models/props.py shopfront --sketch` · match: `python tools/models/match.py shopfront --round=N` · rack: `--prop-rack=shopfront` · review: `python tools/models/review.py shopfront --round=N`

The joinery front applied to the ground floor of a plastered stone house (S162) or a timber house (S161): a stone step, two panelled side boxes that hold the night shutters, panelled stall risers under two shop windows, a glazed door in the middle, a frieze of panels over them, a deep fascia for the shop's name (S160 paints it) and a cornice capped in zinc. Painted dark green here; oxblood, black and varnished wood are round 3's palette. The night shutters (panels with iron bars across, as on shutters_up) are one moving part.

## References
Wikimedia Commons, `references/elements/shopfront/`. Matched (`match.json`): frontal_wood, brown_frontal. The shop names on the photos are only references: the game's are invented (S160).

| file | what it shows | source | licence |
|---|---|---|---|
| `frontal_wood.jpg` | **the main reference**, square-on: step, side boxes, stall risers, frieze of panels, the deep fascia and its cornice, the door's place; the scale (a table and chairs inside) | [La Crète, 85 Rue Mouffetard](https://commons.wikimedia.org/wiki/File:La_Cr%C3%A8te,_85_Rue_Mouffetard,_75005_Paris,_18_September_2019.jpg), Ricardalovesmonuments | CC BY-SA 4.0 |
| `brown_frontal.jpg` | the symmetric layout (window, door, window) between pilasters with capitals, a carved frieze, tall glass with a low riser | [Paris 39 rue des Petits-Champs](https://commons.wikimedia.org/wiki/File:Paris_39_rue_des_Petits-Champs_2012_4.jpg), Lionel Allorge | CC BY-SA 3.0 |
| `porcelain_frontal.jpg` | a long fascia with raised letters, the stall risers' row of panels, the door off-centre | [Paris X rue de Paradis n21](https://commons.wikimedia.org/wiki/File:P1300837_Paris_X_rue_de_Paradis_n21_rwk.jpg), Mbzt | CC BY-SA 4.0 |
| `shutters_up.jpg` | **the shutters up**: studded panels over the windows, a flat iron bar across each, the door's own panel | [La boutique jaune, Rue des Cascades](https://commons.wikimedia.org/wiki/File:La_boutique_jaune,_Rue_des_Cascades_2012-10-18_N1.jpg), Jean-François Gornet | CC BY-SA 2.0 |
| `shutters_up_old.jpg` | old horizontal shutter boards up, the faded painted fascia, the riser's boards rotting: the abandoned look | [Rameau & Chasseloup, Paris 11](https://commons.wikimedia.org/wiki/File:Rameau_%26_Chasseloup_-_Fils_de_fer_M%C3%A9taux._Paris_11_(22650941605).jpg), Jeanne Menjoulet | CC BY 2.0 |
| `dark_grille.jpg` | a black front behind a folding grille, gilded letters on the fascia | [Comptoir Général de Brosserie](https://commons.wikimedia.org/wiki/File:Comptoir_G%C3%A9n%C3%A9ral_de_Brosserie,_6_rue_de_Vaucouleurs,_Paris_02.jpg), Jeanne Menjoulet | CC BY 2.0 |
| `red_small_panes.jpg` | oxblood front with small panes and leaded tops | [25 rue des Grands-Augustins](https://commons.wikimedia.org/wiki/File:25_rue_des_Grands-Augustins,_Paris_6e.jpg), Celette | CC BY-SA 4.0 |
| `yellow_pilasters.jpg` | carved pilasters, a fascia with gilt letters, a pharmacy cross beside | [Paris 08 Herboristerie](https://commons.wikimedia.org/wiki/File:Paris_08_-_Herboristerie_87.jpg), Selbymay | CC BY-SA 3.0 |
| `blue_simple.jpg` | the plainest: posts, a door with crossed bars, a low riser | [Boutique 14 rue Sourdière](https://commons.wikimedia.org/wiki/File:Boutique_14_rue_Sourdi%C3%A8re.jpg), Oderik | CC BY-SA 3.0 |
| `street_pair.jpg` | two fronts side by side in a street of houses (the context) | [Boutiques d'artisans, rue Bodillot](https://commons.wikimedia.org/wiki/File:Boutiques_d%27artisans,_rue_Bodillot_-_Paris_13i%C3%A8me.jpg), besopha | CC BY-SA 2.0 |

## Measurements
The scale: on frontal_wood the table inside is 0.75 m high and a chair's back 0.95; both give ~340 px/m, so the side boxes' outsides are 4.80 apart and the cornice's top 3.56 over the pavement. Read off `shopfront_grid_frontal_wood.jpg` (10 cm squares).

- size (m): 5.22 x 3.56 x 1.66
- the step 0.13 high, across the front, 0.38 in front of the joinery
- the joinery's face 0.20 in front of the wall; side boxes 0.40 wide
- stall riser to 0.78; windows and door from there (the door from the step) to 2.09
- the frieze of panels 2.16-2.50; the fascia 2.56-3.42; the cornice to 3.56, 0.42 out from the wall and 0.20 past each box
- the door 1.00 wide in the middle, posts 9 cm each side
- the dark shop behind: 1.40 deep (the night shutters go in there when taken down)
- the house leaves a bay 4.90 wide for it (`shopfronts.bay()`)

## Visible details
- [x] M step, side boxes with plinth, panel and capital (R1)
- [x] M stall risers with fielded panels and the sill rail (R1)
- [x] M windows: stiles, a glazing bar, glass; posts by the door (R1)
- [x] M the door: stiles, rails, lock rail, fielded panel, glazed top, a brass handle (R1)
- [x] M head rail, frieze of fielded panels, fanlight over the door (R1)
- [x] M fascia with mouldings, cornice with cove and zinc capping (R1)
- [x] M night shutters: three panels over each window, two iron bars with bolt heads (R1)
- [ ] M pilaster capitals as consoles (brown_frontal, yellow_pilasters), the fascia's end blocks (R2)
- [ ] M small panes for the red variant, the door's letterbox, a kick plate, the shutters' studs (shutters_up), the bars' hooks into the boxes (R2)
- [ ] M striped fabric awning (store) on arms under the cornice, rolled up or out (R2)
- [ ] M counters and shelves seen through the glass (R2)
- [ ] B lettering on the fascia (painted, gilded, raised: from S160's kit), prices and posters in the windows, dirty glass, flaking paint, tags on the shutters (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| joinery, fascia | dark green (oxblood, black, varnish by seed: R3) | brown undercoat | oak | flakes at the riser and the step first |
| shutter | the same green, a shade lighter | grey | grey wood | tags, flaking |
| stone | the step | — | — | worn hollow at the door (R3) |
| zinc | capping | — | — | streaks under it |
| glass | dark | — | — | dirt, posters, broken (damaged) |
| iron | bars and bolts | red lead | rust | runs down the shutters |
| brass | the handle | — | — | polished where held |
| room | the dark shop | — | — | lit at night (R3) |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 6000 | 3 | 20 m |
| 1 | 1400 | 1 | 60 m |
| 2 | 900 | 1 | 300 m |

## Moving parts
| part | pivot | motion |
|---|---|---|
| door | its +X stile, behind | turns 95° into the shop about Y |
| shutters | — | the night shutters up at rest; open = taken down into the shop (moved 1.05 m back, out of sight) |

## States
clean · abandoned · damaged · burnt (paint); shutters up / open from the parts. Half shuttered, forced (panels torn off), looted (glass out, shelves bare): R3, with the damage tools.

## Round 1 — form (silhouette, proportions, real size)
Match: `references/elements/reviews/shopfront_match_r1.jpg`. Sheet: `references/elements/reviews/shopfront_r1.jpg`.
Differences from the references:
- the cornice stopped 0.10 past the side boxes; on frontal_wood and brown_frontal it runs ~0.20 past
- brown_frontal has no frieze of panels: its glass runs from a riser at ~0.59 to ~2.46 and the fascia is shallower. A second layout, not a fault: noted for round 4-like variants (S044 picks per building)
- the door: frontal_wood's is off-centre and double (one leaf folded back); brown_frontal's and blue_simple's are single and central. The element follows the central single door
- from the review sheet: the 10 m and 50 m views cut the 5.2 m front off (the rack framed for posts); the shutters' iron bars were rust-red in the clean state (the whole `iron` was marked a fixing, so all of it rusted)
Fixed:
- cornice 0.20 past the boxes (`CORNICE_SIDE`)
- the rack opens its lens for wide elements in the far views (`PropRack.look`)
- the bars plain iron; only their bolts are fixings that rust (`bolt`)
Open:
- layouts: tall glass without the frieze (brown_frontal), door off-centre (porcelain_frontal, frontal_wood), widths other than 4.80: S044 needs fronts for bays of 3 to 8 m. As parameters of the family (`W`, the frieze, the door's place) registered as more elements
- past LOD 0 the parts are merged at rest: far shops always show their shutters up (fitting for an abandoned town; decided with S044)

## Round 2 — structure (the secondary forms)
Sheet: `references/elements/reviews/shopfront_r2.jpg`
Differences:
-
Fixed:
-

## Round 3 — surface (lettering, posters, dirty glass, flaking paint, tags; the states)
Sheet: `references/elements/reviews/shopfront_r3.jpg`
Differences:
-
Fixed:
-

## Review
What is left, each item fixed or accepted with a reason.
