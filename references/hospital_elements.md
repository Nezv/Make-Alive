# Hospital Dona Helena: element list

Everything that belongs at the Hospital Dona Helena (Rua Blumenau, central Joinville) and whether
the game has it yet. Built from `hospital1.jpg` (night, from the air: the new tower lit blue, the
ambulance bay along the street) and `hospital2.png` (day, from the street: the old wing with its
vertical concrete fins, the green-banded annex, the glass tower behind).

Art quality: everything marked [x] went through the pass in `references/asset_quality.md`.

Legend: [x] built · [~] built roughly, needs a better pass · [ ] not built yet.
Code: `scripts/world/hospital_set.gd` (the pieces), `CityMap._hospital` (where they go, in the lot's
frame: -Z to the street), `MapAreas.hospital` (the mission's data).

## The buildings

- [x] The tower: ten floors, white, facing east over the bay to Rua Blumenau
- [x] Its front split into three bodies: A tall and narrow with punched windows, B stepping forward with a full-height slot of blue glass, C wide with balcony slabs, glass rails, fins and blue glass bands
- [x] HOSPITAL DONA HELENA in lit letters on the top of the middle body, the round logo beside it
- [x] Blue wash light up the faces at night (a blue lamp at the foot), some windows left lit
- [x] The old wing on the street: white plaster ends with ledges, the dark vertical concrete fins flaring at their feet in front of brown glass, steps to the old door, the logo high on the left
- [x] The green-banded annex: three floors of olive panels and white bands, square windows
- [x] The small old house with a tile gable roof kept beside the tower
- [x] Rooftop: helipad with its H, the edge lights and the windsock; lift motor room, water tank, condensers, an antenna with its light
- [x] The back: a band of windows per floor and a door onto the fire stair at every floor
- [x] The steel fire stair up the back from the yard to the roof: flights, landings with grating, rails, posts (walkable)
- [ ] Interiors: lobby, the stairwells, one ward floor, the lift shaft

## The street side

- [x] Ambulance bay: a long thin canopy on round columns along the front, its edge lit blue, lamps in its soffit, PRONTO ATENDIMENTO on a red board
- [x] Glass entrance with sliding doors, the drop-off lane with its bays
- [x] Ambulances (Props.ambulance), one across the lane
- [x] Street trees along the pavement (one yellow ipê)
- [ ] Bollards, a ramp with rails, a bus stop, lamp posts, the zebra crossing in front
- [ ] A SAMU van, cars parked half on the pavement

## The yard behind

- [x] Asphalt with staff bays and cars, bins by the back doors
- [x] The oxygen tank in its fenced pad, the generator
- [x] The triage tent (the checkpoint's look)

## Story and scatter

- [x] Triage outside, overrun: cots, body bags, wheelchairs (two tipped), drip stands, papers
- [x] A minibus dragged across the drop-off lane
- [x] Blood dragged from the doors
- [ ] Blood on the glass doors, files blown across the lobby (needs interiors)

## The mission (EXTRACTION, up)

- [x] Start in the drop-off lane in front of the doors, eight spawns facing the street
- [x] Get round the tower to the yard (a checkpoint)
- [x] Hold the yard through three waves (from Rua Blumenau both ways, then from behind the lot), the helicopter coming in during the last
- [x] Up the fire stair, ten floors, to board on the helipad (five seconds)
- [ ] Up the stairwells inside floor by floor (needs interiors), the lift shaft as a shortcut

## Sources

- `references/hospital1.jpg`, `references/hospital2.png`

## Screenshots

`references/quality/hospital/after/` (from `tools\shots.ps1 hosp`).
