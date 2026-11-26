# Terminal Central: element list

Everything that belongs at the Terminal Central (the city's central bus terminal, Rua Nove de
Março) and whether the game has it yet. Built from `terminal1.png` (inside, on a wet day).

Legend: [x] built · [~] built roughly · [ ] not built yet.
The set is `scripts/world/terminal_set.gd` (`TerminalSet`), placed by `CityMap._terminal` in the
lot's frame (`map.terminal.frame`: -Z to the street; `gate`, `platform`).

## The structure (`terminal1.png`)

- [x] The roof: heavy grey concrete slabs over the three platforms, haunches down at the edges, rain streaks on the fascias
- [x] Skylight lantern along the spine (glass between steel frames, trusses under it)
- [x] Dark steel tree columns: a post splitting into a fan of angled struts under the roof
- [x] Corrugated metal clerestory band under the lantern
- [x] Round downlights in the soffit, a few still on
- [x] Platform islands: kerbs painted yellow, grey pavers, white concrete barriers at the ends
- [x] Cobbled bus lanes between the platforms, drains along the kerbs, painted bay lines
- [~] Benches, bins, the station clock, round stop signs on posts (no turnstiles, kiosk or timetables yet)
- [ ] Wet, shiny setts (needs the storm's rain, S050 follow-up)

## Buses

- [x] Yellow city buses (the Joinville colour), some lit, doors open, two nose to tail, one crashed into a column
- [x] One burnt out at the back end, scorched ground and an orange glow

## Around it

- [x] Ticket hall and shops on the street side with shutters; TERMINAL CENTRAL sign over the way in
- [ ] The square to the south and Rua Nove de Março traffic left behind (the street scatter only)

## Story and scatter

- [x] Luggage on the islands and in the lanes, litter, blood trails toward the hall
- [ ] Umbrellas, a dropped shopping bag, a pram (the `remains` family's elements, once placed)
- [ ] Smoke under the roof from the burnt bus

## The mission (RUN, `MapAreas.terminal`)

- [x] Start on the middle platform, out through the street side
- [x] Through the centre to a checkpoint halfway (the dead come back there, a lit tent)
- [x] On to the Prefeitura: hold its pad on the south lawn for five seconds to be lifted out
- [ ] Closets checked in a run (`MapData.check` in `tests/test_mission_terminal.gd`)
