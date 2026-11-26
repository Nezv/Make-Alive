# sky — the sky, the time of day and the far backdrop (S050)

Code: `scripts/time_of_day.gd` (`TimeOfDay`: the five presets as data), `scripts/fx/sky_dome.gd` (`SkyDome`: environment, sun or moon, depth fog, lightning, the backdrop's horizon profile, the landmark stand-ins and the fires), `scripts/fx/sky_shader.gd` (`SkyShader.CODE`: one sky shader) · test: `tests/test_sky.gd` · review: `python tools/sky_review.py N` (every preset from three viewpoints, one row each, the reference beside it) · play: `--time=clear|overcast|dusk|night|storm` (`day` = clear), `--time-cycle` steps through them shot by shot.

Not a prop: no mesh. Everything past the far plane (`Config.VIEW_FAR`, 1200 m) is painted by the sky shader, so the backdrop costs no draw call: the hill and the town's roofscape from a horizon profile worked out on the CPU from the map's own heights and cells for where the camera stands, the town seen from above (`CityPicture`'s classes) below the horizon, the landmarks as silhouettes until their elements exist.

## References
Photos in `references/elements/sky/`, all from Wikimedia Commons. Paris first: the sky over plastered houses and slate roofs.

| file | what it shows | source | licence |
|---|---|---|---|
| `overcast_montmartre.jpg` | Paris from Montmartre on an overcast day: one grey lid, a brighter band at the horizon, the town fading into haze over 3 to 5 km, roofs still readable at 2 km | commons.wikimedia.org/wiki/File:A_desaturated_shot_of_the_Paris_skyline_on_an_overcast_day_from_Montmartre.jpg | CC0 |
| `pissarro_rouen_overcast.jpg` | Pissarro, Morning, an Overcast Day, Rouen (1896): the colour of an overcast French town: warm grey sky, soft shadowless light on plaster, smoke rising straight from chimneys | commons.wikimedia.org/wiki/File:Morning,_An_Overcast_Day,_Rouen_MET_DT1863.jpg | CC0 |
| `dusk_roofs.jpg` | Paris roofs at sunset: pale blue overhead, a pink-orange band low in the west, small dark cloud wisps, zinc and slate roofs dark against it, the first lit windows | commons.wikimedia.org/wiki/File:Roofscapes_in_Paris_at_sunset_(30).jpg | CC BY 3.0 |
| `dusk_cityscape.jpg` | Paris at dusk from a roof: the town a black silhouette, a burning orange line on the horizon, red-lit undersides of a heavy violet cloud deck | commons.wikimedia.org/wiki/File:Paris_cityscape_at_dusk_from_the_Facult%C3%A9_de_M%C3%A9decine%27s_roof_(33499840888).jpg | CC BY 2.0 |
| `night_glow_raphael.jpg` | Paris at night from a roof: a brown-grey sky glowing from below, brightest at the horizon, a few stars only overhead, warm lit facades, the far town a carpet of points | commons.wikimedia.org/wiki/File:North_view_from_the_rooftop_at_the_H%C3%B4tel_Raphael_in_Paris_-_2019-08-24.jpg | CC BY-SA 4.0 |
| `night_paris.jpg` | Paris from the Tour Montparnasse at blue hour: streets as lines of orange lamps, blocks dark, the sky deep blue with a dark cloud band | commons.wikimedia.org/wiki/File:Paris_at_night,_4_July_2013.jpg | CC BY-SA 2.0 |
| `storm_night.jpg` | A night storm over Paris: an almost black sky, the cloud's bulges lit from inside by the strike | commons.wikimedia.org/wiki/File:Orage_%C3%A0_Paris_de_la_nuit_du_18_mai_2022_01.jpg | CC BY-SA 4.0 |

## Measurements
- the far plane: 1200 m; past it the backdrop. The hill (Morro da Boa Vista, `CityHeights`) is 230 m at the Mirante, 2 km from the place du Marché: about 6.5 degrees above the street.
- cloud decks: low 1500 m, high 6000 m; the low deck's masses about 1 km across (Montmartre: a few to the horizon).
- the sun: 0.5 degrees across in life; drawn 1.4 degrees (`sun_size` 0.012 rad radius) so it reads on a 1080p screen.
- the landmark stand-ins: the church's spire 58 m (a parish church of the old core), the town hall's campanile 42 m, the telegraph tower 24 m on the summit and its mill 17 m with 9 m sails (the Chappe towers and the moulins of the hills round Paris; S230 makes them).
- smoke columns: rise about 400 m before they spread, 10 to 80 m wide.

## Visible details
- [x] Gradient: horizon band, zenith, a ground colour below
- [x] Sun disc with a halo, its colour on the sky around it when it is low
- [x] Moon disc with seas, a faint halo
- [x] Stars, twinkling, only where the cloud breaks and away from the horizon
- [x] Two cloud layers drifting with the wind: a thin high one and the low deck, lit from the sun's side, darker bellies
- [x] The town's glow on the haze and on the clouds' undersides at night
- [x] Fires on the horizon: the glow over each, its smoke column leaning with the wind
- [x] A distant ridge to the west (the serra)
- [x] The roofscape past the far plane: ridge line, chimney stacks, a few lit windows at night
- [x] The hill and its forest crowns on the skyline, from the map's heights
- [x] The church spire, the campanile, the telegraph tower and the mill turning, as silhouettes
- [x] Below the horizon: the town seen from above (roofs, streets, water, green) with lamps at night
- [x] Lightning: the cloud lit from inside, a flash on the town

## Presets
| preset | sun / moon | light | fog | clouds | used by |
|---|---|---|---|---|---|
| clear | sun 46 deg SW | warm, shadows | thin, starts at 120 m | scattered | free play by `--time` |
| overcast | hidden | even, faint shadows | grey | a full lid | batalhao |
| dusk | sun 5 deg W | orange, long shadows | warm | pink-lit, broken | terminal |
| night | moon 38 deg SE | cold, no shadows | dark from the start | broken, town-lit | hospital, mirante, free play |
| storm | hidden | dim, no shadows, lightning | thick | a racing lid | prefeitura |

## Budget
No mesh and no draw call. One sky shader: the sky's reflections (radiance 64, incremental) skip stars and the backdrop (`AT_CUBEMAP_PASS`); its parameters change at most `1 / Config.SKY_UPDATE` times a second. Sun shadows by day and dusk only: two splits to `Config.SKY_SHADOW_DISTANCE` (60 m). The profile: 512 azimuths, worked out again 32 a frame when the camera has moved 40 m.

## States
The presets are the states. Later: rain (S2xx needs this), the time moving during a mission (not asked).

## Round 0 — first light (not a round: the first look at all of it)
Sheet: `references/elements/reviews/sky_r0.jpg`
Found and fixed before the rounds: stars drawn as streaks (a weak hash); clouds in straight-edged blocks (the same); the night far too bright (the town's vertex colours are read as linear: night and storm get a lower exposure and the sky a matching gain); exponential fog made the geometry hazier than the backdrop past it (now depth fog up to `fog_max` at the far plane, and the shader carries on from there); chimney spikes up the sky at the ends of the roofscape (the profile's distance fading to 0 between texels); the ridge and the roofscape painted over the town seen from above.

## Round 1 — day: clear and overcast
Sheet: `references/elements/reviews/sky_r1.jpg` (after: the day rows of `sky_r2.jpg`)
Differences from the references:
- From the hill the town past the far plane is a white blank; Montmartre shows dark roofs and light walls to 3 km and more.
- The day fog is milky already at 300 m (overcast streets); Montmartre is clear to 1 km.
- A grey band runs right round the horizon and reads as a sea; the references' horizon is the town's own, with hills only in places.
- The overcast deck is small regular ripples; Montmartre's lid is large soft masses with darker bases.
- Sunlit plaster burns to white on the clear day.
- The clear sky is milky down to half its height; the references are blue down to a narrow pale band.
- The fires' smoke hardly shows by day; Pissarro's smoke is a dark grey-brown.

Fixed:
- The town seen from above: slate, zinc and some red tile per roof cell, lit walls between, darker `roof_color` by day.
- Day fog: clear 0.4 at the far plane from 150 m, overcast 0.5 from 100 m, both on a steeper curve (`SKY_FOG_HIDES` 0.4: past the plane the backdrop goes on).
- The ridge only to the west (the serra), with a shape; elsewhere a hair of low hills.
- The low deck's masses grow with the cover (scale x 1.95 overcast), its light varies less under a full lid.
- Clear: exposure 0.9, sun 1.15.
- The gradient leans to the zenith colour (power 0.4).
- Smoke darker, less hazed.
Measured: `tools\perf.ps1 city 15 hospital` 8.2 ms (122 fps), the same with the plain sky swapped in: the shader costs nothing measurable.

## Round 2 — dusk and night
Sheet: `references/elements/reviews/sky_r2.jpg` (after: `sky_r3.jpg`)
Differences from the references:
- Night: pale streaks radiate up from the horizon (a faint star band sampled on the ground plane's projection); the Raphaël photo's sky is an even brown-grey.
- Night: the town's glow at the horizon is weak; in the Raphaël photo it is the brightest part of the sky.
- Night from the hill: the town below is nearly black, a few points; Montparnasse shows the streets as lines of orange lamps and the blocks dark.
- Night from the hill: past the picture the far town fades into a dark plain instead of glowing up to the horizon.
- Dusk: the whole sky orange-pink down from the zenith; dusk_cityscape is dark violet overhead with the bright band only low, near the sun.
- Dusk: every cloud lit pink; in the reference the deck is dark with red-lit undersides toward the sun only.
- Dusk from the hill: a purple fog over the town; in the reference the town is a black silhouette under the bright band.

Fixed:
- The faint star band is gone; stars only.
- Glow at the horizon 0.5 (was 0.35) over a wider band; night glow 0.4.
- The town from above: lamps on most street cells, brighter; far off they blur into a glow along the streets.
- The far town's haze turns into the sky's own horizon colour (glow included) toward the horizon, so the two meet without a line.
- A low sun colours a band along the horizon and the sky round itself, not the zenith; the clouds' lit side faces the sun (`sun_side`); dusk's zenith and cloud shade darker.
- Dusk fog darker and thinner (0.5 at the far plane), ambient 0.26, exposure 0.8.

## Round 3 — storm and the backdrop from each mission's start
Sheets: `references/elements/reviews/sky_r3.jpg` and `sky_r3_missions.jpg` (each mission's start in every preset; after: `sky_r4.jpg`, `sky_r4_missions.jpg`). The storm is shot at a strike (`--lightning`).
Differences from the references:
- A strike whites out the whole sky and lights the town like day; in storm_night one bulge of the deck is lit from inside and the rest stays black.
- The storm deck is a flat grey-brown lid; the reference is near-black with heavy bulges.
- The smoke in the storm is a bright white streak bent flat by the wind.
- From the hill at night a dark hairline runs along the horizon (the low hills' term), and the far haze shows a pale strip under the sky.
- From the starts of the terminal, the hospital and the prefeitura the backdrop is hidden by their own buildings; from the batalhão the skyline, the smoke and the hill's edge read; the Mirante's spawn faces its own wall.

Fixed:
- A strike lights the deck round its own bearing (`flash_az`, `SkyDome.strike(az)`), most where the cloud is dark, the sky between a little, the town with 1.2 extra light (was 2.5).
- Storm colours darker (zenith 0d0f13, cloud 2e3238 / 0b0c0f) and more relief (`cloud_relief` per preset: 1.5 storm, 0.33 overcast).
- Smoke takes the clouds' light (darker than the deck it rises into) and leans at most as in a wind of 1.5.
- The hairline is gone (the ridge only to the west); the far haze ends in the sky's horizon colour.
- The starts: accepted (see the review); nothing in the sky is wrong there, the POIs' placeholder buildings stand in the way.

## Review
Final sheets: `references/elements/reviews/sky_rfinal.jpg`, `sky_rfinal_missions.jpg`.
- The church tower, the campanile, the telegraph tower and the mill are silhouettes drawn in the sky (`SkyDome.towers_of`), seen only from the roofs and the hill. Accepted: their elements are S188, S214 and S230; each will take its stand-in out once it stands in the town (one line in `towers_of`). Modelling them here would be three elements in a step that makes none.
- The roofscape seen from the hill is the real town to 1200 m and `CityPicture`'s classes past it; the chimney pots on the near skyline are the kits' (S159). Accepted.
- The forest on the hill is boxes (S178's forest wall replaces it). Accepted: not the sky.
- Plaster still reads light at night and under a clear sun: the town's vertex colours are taken as linear (`MeshKit.baked_material`). Night, storm and dusk lower the exposure and the sky makes up for it; the facades of S044 bring their own textures. Accepted.
- From the mission starts the backdrop is mostly hidden by the POIs' own placeholder buildings. Accepted: S051 and the POI steps place the starts and the buildings.
- Lightning bolts are not drawn, only the light of a strike. Accepted: the reference's bolt is a single frame; rain (it needs this step) can add one.
- The time of day does not move during a mission. Not asked.
