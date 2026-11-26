# city_blocks — the town's mass: îlots closed by rows of houses, their heights and roofs (S043)

Code: `scripts/world/city_blocks.gd` (`CityBlocks`, no nodes: îlots, houses, roofs as data and meshes), built by `CityMap._buildings` · test: `tests/test_city_blocks.gd` · see: `tools\godot.ps1 -- --host --shot-cam=...` (the views below), `--city-plan`

Not an element: the mass the facade kits (S157 to S164) and the roof kit (S159) dress later. No windows, doors, dormers, cornices or chimney pots here: walls, roofs and how high each house is.

## References
Photos in `references/elements/city_blocks/`. All from Wikimedia Commons.

| file | what it shows | source | licence |
|---|---|---|---|
| `turgot_sheet10.jpg` | Turgot plan (1739), sheet 10: the Marais and the Halles. Every îlot closed by a continuous row of narrow houses, each its own roof with the ridge along the street; courts and back buildings fill the inside; hôtels behind a court and a gate (Hôtel de Soubise); roofs step up and down house to house | commons.wikimedia.org/wiki/File:Turgot_map_of_Paris,_sheet_10_-_Norman_B._Leventhal_Map_Center.jpg | public domain |
| `turgot_sheet14.jpg` | Turgot plan, sheet 14: the edge of town. Houses only along the street, long gardens behind, gaps closed by garden walls, big institutions with courts | commons.wikimedia.org/wiki/File:Turgot_map_of_Paris,_sheet_14_-_Norman_B._Leventhal_Map_Center.jpg | public domain |
| `marville_rue_tiquetonne.jpg` | Charles Marville, rue Tiquetonne (c. 1865, before Haussmann): five and six floors over a 7 m street, plain plaster, shops on the ground floor, the cornice line steps house to house | commons.wikimedia.org/wiki/File:Charles_Marville,_Rue_Tiquetonne.jpg | public domain |
| `marville_rue_mercier.jpg` | Marville, rue Mercier: the same narrow canyon, a corner house turning the block | commons.wikimedia.org/wiki/File:Charles_Marville,_Rue_Mercier.jpg | public domain |
| `paris_roofs.jpg` | Paris roofs from above: mansards (steep slate lower slope with dormers, zinc top), party-wall chimney stacks across the roof, corner houses turning with a hipped roof, light wells and courts | commons.wikimedia.org/wiki/File:Paris_Roofs.jpg | CC BY-SA |
| `caillebotte_toits.jpg` | Caillebotte, Toits sous la neige (1878): the roofscape at eye level: ridges, stacks, gables of different heights | commons.wikimedia.org/wiki/File:Gustave_Caillebotte_-_Rooftops_in_the_Snow_(snow_effect)_-_Google_Art_Project.jpg | public domain |
| `rouen_rue_aux_ours.jpg` | Rouen, rue aux Ours: old-core houses, narrow (two or three windows), four floors and a steep roof, slate-hung side wall | commons.wikimedia.org/wiki/File:Rue_aux_Ours_-_immeubles_encorbellement_colombage.jpg | CC BY-SA |

## Measurements
Against a 3 m storey (a door of 2.1 m and the window above, Marville), a 7 m street (Marville: two carts wide).

- storey: 3.0 m (ground floor 3.6 m with the shop); `Config.CITY_FLOOR_H` stays 3.2 as the mean
- window bay: 2.2 to 2.8 m; a house is two to four bays in the old core (5 to 9 m), three to five on the main streets (8 to 13 m)
- house depth from the street: 9 to 14 m (one or two rooms); corner houses fill the corner
- old core: four to six floors (Marville: five and six), roof 50 to 55 degrees, ridge along the street
- main streets: four or five floors, mansard: lower slope about 75 degrees rising 2.8 m, top about 20 degrees
- edge of town (Turgot 14): two or three floors, tile roofs, gaps with 2.5 m garden walls
- post-war blocks: six to nine floors, flat roof, 20 to 40 m long
- ateliers: one or two high floors, saw-tooth glass roofs, 15 to 40 m

## Visible details
- [x] M Îlots: one per block between streets, closed by a row of houses along every edge facing a street, square, quay or park
- [x] M Corner houses turning each convex corner, hipped roof
- [x] M Houses of seeded width (bays) and height; roofs step house to house
- [x] M Gable roofs, ridge along the street, gables on the party walls
- [x] M Mansard roofs on the main streets
- [x] M Hipped roofs on corner houses and back buildings
- [x] M Flat roofs on post-war blocks
- [x] M Saw-tooth glass roofs on the ateliers
- [x] M Back buildings and halls inside the court from the traced footprints (`CityOsm`)
- [x] M Hôtels particuliers: gate wall on the street, court, the house set back
- [x] M Garden walls closing gaps at the edge of town
- [x] M Courts paved, gardens green
- [ ] Chimney stacks, dormers, cornices: the kits (S159, S162), not here (accepted: S043 says the stacks are left to the kits)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| plaster | creams, ochres, greys | stone rubble | | facades (S044) |
| stone | ground floor on the main streets, hôtels | | | |
| slate | blue-grey | | | |
| zinc | the mansard's top | | | |
| tile | red-brown, three shades | | | |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| detail | see `tests/test_city_blocks.gd` | the buildings' one mesh | all |
| silhouette (outside a mission area) | outline prism per îlot | same mesh | all |

Collision: one shape per îlot (its street walls).

## States
Clean only; decay is the facades' (S044).

## Views
`toolsshots.ps1 city_` (all with `--review-light`, an overcast day: at night the forms cannot be judged until S050):
`city_marche` (the place du Marché looking north-west), `city_core_street` (the place de l'Église and the core round it),
`city_bridge` (the quay from the bridge), `city_hill` (the town from Morro da Boa Vista), `city_roofs` (the helicopter's height).
Plans: `--city-plan=DIR` (every house by its roof colour, garden and gate walls) and `--city-zoom=x,y,w` (a close plan, îlot outlines in yellow).

## Round 1 — skyline (the place du Marché, the bridge, the hill)
Differences from the references:
- At night nothing could be judged: the views were all the moon's blue (tooling: `--review-light` added for review shots).
- The rows were 2.5 m deep, a stage set of fronts: the straightened outline lies up to 2 m outside the block's cells, so the depth probe stopped at once (`_reach`).
- The courts of the big Joinville blocks (150 x 250 m) were empty: Turgot's courts are full of wings and back buildings.
- Post-war slabs closed the place du Marché on two sides (the bus station's radius took the square's îlots); the spec wants tall plastered houses there.
- In the old core neighbours jumped up to two floors, so narrow houses stood like separate towers with their gables in a sawtooth; Marville's streets step one floor at most.
- No chimney stacks bristling over the roofs (the references have rows of pots on every party wall).
- No church tower or campanile over the roofs.
Fixed:
- `--review-light` (overcast, low sun from the south-west) for every `city_` shot.
- `_reach` counts from where the block's cells start: rows are 9 to 14 m deep.
- A wing behind most front houses across a 4 to 8 m court (`CLASSES[..].wing`), as on the Turgot plan.
- Post-war only round the hospital (200 m) and round the bus station away from the market (`Config.CITY_MARCHE_KEEP`).
- A row has a base height; each house keeps within a floor of it.
Accepted:
- Chimney stacks: S043 leaves the party-wall stacks to the kits (S159).
- Church tower (S188) and the town hall's campanile (S214) are their own steps; the skyline gets them there.

## Round 2 — roofscape (from the helicopter's height, against the Turgot plan)
Differences:
- Deep courts were still bare paving in their middle, beyond the wings.
- Courts everywhere one colour: Turgot's edge of town is gardens, the core paved.
- Collision was one box per building (30 000 shapes): S043 wants one per îlot.
Fixed:
- Court fill: back buildings every 18 m or so where the traced footprints leave the court empty, seeded, jittered by a third of the step (`_fill_courts`).
- Courts paved in the core and round the post-war blocks, gardens elsewhere.
- One `ConcavePolygonShape3D` per îlot: its street fronts and walls (tested: a bullet stops on the building line).
Accepted:
- The court buildings stand square to the îlot's longest side rather than leaning on the party walls as Turgot's do: from the helicopter it reads as courts full of sheds; the true backs come from the traced footprints where Joinville has them.
- Every house of the town is built in detail: nothing sets a mission area yet (S051); outside one an îlot is a silhouette (tested).

## Review
Final sheet: `references/elements/reviews/city_blocks_r2.jpg` (the five views beside the references).
