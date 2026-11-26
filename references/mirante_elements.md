# Mirante: element list

Everything that belongs on Morro da Boa Vista, from the gate at the foot to the lookout on the
summit, and whether the game has it yet. Built from `mirante_entrance.jpg`, `mirante_street.jpg`,
the topography map, and what is written about the place (sources at the bottom).

Art quality: everything here has had the pass in `references/asset_quality.md` (bevels, trims, details, materials); its inventory says what is left.

Legend: [x] built · [~] built roughly, needs a better pass · [ ] not built yet.
Code: `scripts/world/mirante_set.gd` (the pieces), `scripts/world/vegetation.gd` (plants),
`CityMap._hill_road` / `_mirante` (where they go), `MapAreas.mirante` (the mission's data).

## The gate at the foot (`mirante_entrance.jpg`)

- [x] Concrete portal: two square pillars and the sign across them
- [x] MORRO DA BOA VISTA in green, "Área de Relevante Interesse Ecológico" under it
- [x] White butterfly roof (two slabs rising away from a valley over the road)
- [~] Guard booth: an orange box with windows beside the right pillar (the real one sits on the island between the road and the walkway, with a brown roof band)
- [x] Boom barrier, red and white, raised and left that way
- [x] Yellow-painted kerbs along both sides
- [x] Red and white PARE barrier board and traffic cones on the walking side
- [x] Hibiscus (red flowers) and bougainvillea bushes, a purple flowering tree
- [ ] Grass island with a yellow kerb splitting the road from the walkway under the portal
- [ ] The orange-walled house with a tile roof on the left, behind a garden wall
- [ ] Green information totem on the right
- [ ] Bus stop for the line from the Terminal Central (the only public way up: no private cars)
- [ ] Zoobotânico gate and pond nearby (S049)

## The road up (`mirante_street.jpg`)

- [x] Grey concrete pavers on the road (herringbone in the photo; flat grey for now)
- [x] Red brick walking lane on the right going up, split from the road by a white line
- [x] Concrete power poles with crossarms, insulators and thick cable bundles sagging between them
- [x] Transformers on some poles
- [x] A few street lamps on the poles, most dark: long unlit stretches
- [x] Galvanised guard rails round the outside of the sharp bends
- [x] Atlantic forest walls both sides: broad canopy trees, tree ferns (xaxim), juçara palms, araucárias, ipês in bloom
- [x] Paver pattern (a basket weave drawn by the world shader's PAVERS class; the brick lane is BRICK)
- [ ] Grass verge between the brick lane and the forest
- [ ] Tall grass, bamboo clumps and lianas hanging off the trees
- [ ] Canopy closing over the road (branches reaching across)
- [ ] Drainage gutters, a retaining wall on the uphill side of the bends
- [ ] Undergrowth and dark between the trunks behind the first row
- [ ] Trilha Rústica: the dirt side trail as a risky shortcut, steps and roots, no lamps
- [ ] Wind: trees swaying, stronger near the top

## Road scatter (what an emptied hill would have on it)

Placed by `RoadScatter.HILL` (`scripts/world/road_scatter.gd`), models in `scripts/world/road_props.gd`.
Edit HILL to move, add or drop any of them.

- [x] Abandoned cars on the road (the bus line's minibus, a taxi, three hatchbacks), doors open
- [x] A car that slid off a bend into the guard rail (first sharp bend)
- [x] Fallen tree across part of the road, a snapped power pole with its cables on the ground
- [x] Bicycles dropped by the kerb (the road is a favourite climb for cyclists and runners)
- [x] Backpacks, water bottles, a dropped phone (some still lit), a selfie stick, flip-flops on the brick lane
- [x] Guarda Municipal motorbike at the gate, a patrol car across the road higher up (one lamp of its bar still lit)
- [x] Traffic cones and a PARE board dragged up the road, a makeshift barricade of benches below the hairpin
- [x] Blood trails into the forest, two body bags at the hairpin
- [x] Rubbish bins knocked over, a bench at the viewpoint bend near the top
- [ ] Sound or light on any of it (a car alarm, a hazard light blinking): none yet
- [ ] Props that move when shot or shoved (all static and baked into the map's mesh)

## The summit

- [~] The lookout tower, 14.5 m of reinforced concrete: a lift shaft in the middle, four flights of stairs round it up to the deck. Shape is from the written facts only; **no photo of the tower is in `references/` yet**. Add one and the tower gets a proper pass.
- [x] Deck about 70 m² (here 9.2 m square), railing all round
- [x] Part of the deck floor open steel grating on the bay side (the "glass floor" thrill)
- [x] Lift (a shaft with its door at the bottom; it does not run)
- [x] Coin binoculars on the deck
- [x] Snack bar with its shutter half down and an orange awning
- [x] Toilet block
- [x] Guard hut
- [x] Two radio masts with red warning lights (the hill has had transmission antennas for decades)
- [ ] Tourist information centre (CAT) and the support room
- [ ] Drinking fountain at the foot of the stairs
- [ ] The elevated forest walkway (Trilha Ecológica on suspended platforms) to the "Janela do Mirante", a smaller lookout
- [ ] Benches, bins, signs with the view's landmarks
- [ ] Monkeys (saguis) in the trees round the walkway
- [ ] The view: the whole city below, lit windows, fires, the river and Baía da Babitonga, Serra do Mar behind (S050 backdrop)

## The mission (climb up)

- [x] Start at the gate, eight spawns on the road outside it
- [x] Checkpoint at the hairpin (tent, painted arrow)
- [x] Reach the summit, then hold it through three waves until the helicopter is down
- [x] Board: everyone on the tower deck for five seconds
- [x] Helicopter: flies in, circles once, flares, hangs beside the deck with its door open, flies off
- [ ] Helicopter: door gunner firing at the horde, players seated inside on lift-off, the city falling away
- [ ] Zombies climbing the tower's stairs (the 2D navigation grid stops them at its foot for now)
- [ ] Leapers dropping out of the trees onto the road, runners coming up in packs
- [ ] Fog between the trunks
- [ ] Bot scenario that plays it end to end

## Sources

- `references/mirante_entrance.jpg`, `references/mirante_street.jpg`, `references/joinville_topography.png`
- Diário do Turismo, "Mirante de Joinville é reaberto com nova estrutura e serviços" (March 2016): height 14.5 m, 70 m² deck for about 40 people, lift, snack bar, CAT, guard hut, toilets
- Esse Mundo é Nosso, "Mirante de Joinville: como chegar" (2024): reinforced concrete, flights of stairs, perforated metal floor on the Babitonga side, elevated forest trail to the Janela do Mirante, no private cars, bus from the Terminal Central
- Panrotas (January 2011): the closure for works, the radio transmission antennas on the hill
