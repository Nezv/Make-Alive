# Prefeitura: element list

Everything that belongs at the Prefeitura Municipal de Joinville (city hall, Avenida Hermann August
Lepper, on the east bank of the Rio Cachoeira with Morro da Boa Vista behind it), and whether the
game has it yet. Built from `prefeitura1.jpg` (the front, straight on), `prefeitura2.jpg` (from
the air over the river) and `prefeitura3.png` (from high up: the roof, the car parks, the forest).

Art quality: everything marked [x] went through the pass in `references/asset_quality.md`
(bevels, trims, details, materials).

Legend: [x] built · [~] built roughly, needs a better pass · [ ] not built yet.
Code: `scripts/world/prefeitura_set.gd` (the pieces), `CityMap._prefeitura` (where they go),
`MapAreas.prefeitura` (the mission's data).

## The building (`prefeitura1.jpg`, `prefeitura2.jpg`)

- [x] A long low block, four storeys, facing west over its lawn to the avenue and the river
- [x] Red brick piers at every bay, the full height of the front
- [x] Grey concrete balcony bands at every floor line, deep and upturned (the strong horizontal stripes)
- [x] Window bands set back behind them: dark glass, frames, mullions
- [x] Pink plaster ground floor between the piers, windows with sills
- [x] Deep concrete fascia at the roof line, a low corrugated metal roof behind it (seen from the air)
- [x] The blue steel space frames: the big one over the main entrance (two floors), two smaller ones on the wings
- [x] The tall blue space frame up the stair tower at the north end
- [x] Brick buttresses widening to the ground under the space frames (trapezoids)
- [x] Two tall brick towers on the roof with a concrete band, two lower brick boxes, a white tank room
- [x] Air conditioners hanging under the windows, many of them
- [x] Planters on the first balcony band with plants spilling over (green along the band in `prefeitura2.jpg`)
- [x] Entrance: glazed doors in a frame, a concrete canopy, steps up
- [x] The three flags at the door (Brazil; Santa Catarina with its green lozenge; Joinville with a blue band and the shield: simplified)
- [x] The back and the ends: plainer (bands and windows, no space frames)
- [ ] Interiors: the main hall, the corridors along each floor, the council chamber
- [ ] Barricaded windows (planks, furniture) for the defence
- [ ] Rooftop access by the stair tower

## The grounds (`prefeitura2.jpg`, `prefeitura3.png`)

- [x] The lawn sloping down to the avenue (flat here), split by the walk up the middle
- [x] Paved forecourt along the front of the building
- [x] Zig-zag ramp with rails across the lawn
- [x] "Prefeitura Municipal de Joinville" in white letters (lit, readable at night) on a blue framed board on the lawn
- [x] Flower beds with red and yellow flowers round the sign and by the steps
- [x] Imperial palms in a row along the avenue
- [x] The round concrete pad on the south lawn (the helicopter lands there in the mission)
- [x] Lamp posts along the walks, one still lit; a lit lamp at the door
- [x] Car park to the north with cars left in it
- [ ] The slope itself (the lawn rises ~3 m from the avenue to the forecourt)
- [ ] The riverside rail and the bike path along the avenue, the river bank's undergrowth
- [ ] Festival Nacional de Dança sign at the corner
- [x] The car park behind (east) with the staff cars, bins by the back door, the first trees of the hill's forest

## What happened here (story, scatter)

- [x] A last stand at the door: sandbags and a police car across the steps, a tipped bench
- [x] Papers blown across the forecourt, a dropped backpack
- [x] An ambulance left on the forecourt with its doors open
- [x] Blood dragged from the door down the steps
- [ ] A Defesa Civil tent and crates on the lawn
- [ ] A broken window on the ground floor with the blinds hanging out
- [ ] Sound: a fire alarm still ringing inside

## The mission (DEFEND)

- [x] Start on the forecourt, eight spawns facing the avenue
- [x] Zombies come from the avenue both ways, the north car park and the forest behind
- [x] Hold the forecourt through three waves, the helicopter coming in during the last
- [x] Board: everyone on the round pad on the south lawn for five seconds
- [ ] Barricades the players can build or repair (S0xx)
- [ ] Fight inside the building (needs interiors)

## Sources

- `references/prefeitura1.jpg`, `references/prefeitura2.jpg`, `references/prefeitura3.png`

## Screenshots

`references/quality/prefeitura/after/` (from `tools\shots.ps1 pref`). First round's fixes: the sign's
letters were unlit and hidden behind its frame, the Joinville flag read as Japan's, the yard behind was
an empty grey slab.
