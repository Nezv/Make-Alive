# hydrant — the old cast-iron poteau d'incendie of a French street

Family: `tools/models/props/street.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py hydrant` · sketch: `python tools/models/props.py hydrant --sketch` · rack: `--prop-rack=hydrant` · review: `python tools/models/review.py hydrant --round=N`

The worked example of the element pipeline (S140). Paris itself hides its hydrants under the pavement (bouches); the town's streets get the standing post of every other French town, in its old fluted cast-iron form, which fits the town's age. The modern smooth Bayard post is a later element if the post-war edge wants it.

## References
All from Wikimedia Commons, `references/elements/hydrant/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `fluted_pont_a_mousson.jpg` | **the main reference**: old fluted post, front 100 mm outlet, two side outlets, oval maker's plate, rim and dome, pentagon nut, faded red | [Borne d'incendie Pont-à-Mousson (1)](https://commons.wikimedia.org/wiki/File:Borne_d%27incendie_Pont-%C3%A0-Mousson_(1).jpg), Cjp24 | CC BY-SA 4.0 |
| `ornate_thionville.jpg` | the same layout close up: couplings with lugs and chains, ribbed dome, fluted foot, bolted base flange | [Borne Incendie Place Anne Grommerch, Thionville](https://commons.wikimedia.org/wiki/File:Borne_Incendie_Place_Anne_Grommerch_-_Thionville_(FR57)_-_2026-09-26_-_1.jpg), Chabe01 | CC BY-SA 4.0 |
| `classic_roadside.jpg` | its size against a fence, the red and the aluminium caps from a distance | [Fire-fighting-facility node-6092881446](https://commons.wikimedia.org/wiki/File:Fire-fighting-facility_node-6092881446.jpg), William27 | CC BY 2.0 |
| `modern_three_outlets.jpg` | a newer post on a pavement: proportions of the outlets, caps hanging on chains | [Chatenay-Malabry PoteauIncendie](https://commons.wikimedia.org/wiki/File:Chatenay-Malabry-PoteauIncendie.jpg), Brunoct-osm | CC BY 4.0 |
| `poste_rouen.jpg` | an older "POSTE INCENDIE" with raised lettering and numbers painted on: the lettering style | [Borne Incendie 20, Rouen](https://commons.wikimedia.org/wiki/File:Borne_Incendie_20_Jardin_H%C3%B4tel_Ville_-_Rouen_(FR76)_-_2021-11-14_-_1.jpg), Chabe01 | CC BY-SA 4.0 |
| `worn_paint.jpg` | how the red wears: patches through to an ochre primer, rust at the nut | [Borne d'Incendie Le Bec-Hellouin](https://commons.wikimedia.org/wiki/File:Borne_d%27Incendie_Le_Bec-Hellouin.jpg), Stanzilla | CC BY-SA 4.0 |
| `modern_bayard.jpg` | the modern smooth post (not this element) | [French Fire Hydrant](https://commons.wikimedia.org/wiki/File:French_Fire_Hydrant_-_Flickr_-_lorentey.jpg), Károly Lőrentey | CC BY 2.0 |

## Measurements
Against `classic_roadside.jpg`'s fence (a garden fence's lower rail at ~0.4 m, the post reaching just above the upper one at ~0.9 m) and the French standard post (NF S 61-213: about a metre above ground, a 100 mm outlet and two 65 mm). Heights on `fluted_pont_a_mousson.jpg` as fractions of the whole.

- size (m): 0.34 x 0.97 x 0.30
- overall height to the top of the nut 0.97; the dome's top 0.91
- foot flange Ø 0.25, 0.03 thick, four bolts on it
- column Ø 0.14 (a seventh of the height on fluted_pont_a_mousson), twelve flutes; a collar at 0.31–0.355 (Ø 0.17)
- head widens from 0.66 to Ø 0.17 at 0.80, rim band 0.80–0.835 (Ø 0.185)
- front outlet centred at 0.58, spout Ø 0.10 with flange, cap Ø 0.12 standing 0.125 in front of the axis
- side outlets centred at 0.74, just under the rim, spout Ø 0.072, cap Ø 0.088, 0.13 out from the axis
- oval plate 0.072 x 0.044 at 0.785 on the front, between the side outlets
- pentagon nut 0.05 across, 0.04 tall, on a round seat Ø 0.08

## Visible details
- [x] M bolted foot flange with chamfer, four hex bolts
- [x] M fluted lower and upper column, plain where the flutes end
- [x] M collar band with chamfers
- [x] M head swelling to the rim, rim band, dome, nut seat, pentagon nut
- [x] M front spout with flange, two side spouts with flanges
- [x] M three coupling caps with lugs and a square nut each
- [x] M raised oval plate
- [x] M chains from each cap to the body
- [x] M ribs on the dome (ornate_thionville)
- [x] B lettering on the plate, a painted number on the column
- [x] B paint wear: chips to ochre primer at edges, rust at the nut and bolts
- [x] M flared spouts, a dark bore at each spout end (seen with the caps open)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| paint | signal red, fading to pink on top | ochre primer | dark cast iron | chips at edges and in patches; rust runs |
| plate | the same red | ochre | cast iron | chips sooner (raised) |
| cap | aluminium grey | darker aluminium | aluminium | little, no rust |
| iron | dark iron (nut, bolts) | rust brown | rust | rusts first |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 3400 | 4 | 14 m |
| 1 | 1300 | 1 | 45 m |
| 2 | 480 | 1 | 160 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| cap_front | lower edge of the front cap | turns 100° down about X, hangs in front |
| cap_l, cap_r | lower edge of each side cap | turns 100° down about Z, hangs at the side |

## States
- clean: fresh red, a little dirt at the foot
- abandoned: faded, chipped to the primer at the edges, rust streaks, grime in the flutes, moss at the foot on the shaded side
- damaged: heavily chipped, bullet pocks with bright rims
- burnt: soot from the foot up, the coat blistered, ash on top

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/hydrant_r1.jpg` (as first built)
Differences from the references:
- the column is too fat: Ø 0.176, about a fifth of the height; on fluted_pont_a_mousson it is a seventh
- the side outlets sit too low (0.705): on the references they are just under the rim, level with the plate
- the plate sits below the side outlets; on fluted_pont_a_mousson it is between them
- the dome is a cone; the references' domes are round shoulders under a ring
- the 50 m view is too small to judge the far LOD's silhouette
Fixed:
- column Ø 0.14, head, collar and rim scaled with it; foot flange Ø 0.25; outlets shortened to keep their reach
- side outlets at 0.74, plate at 0.785 between them, plate a size smaller
- dome rebuilt as a rounded shoulder (four rings) under the rim
- the 50 m view zoomed (fov 5°)

## Round 2 — structure (the secondary forms)
Sheet: `references/elements/reviews/hydrant_r2.jpg`
Differences:
- no chains: on ornate_thionville and modern_three_outlets each cap hangs on a chain to the body
- plain dome: ornate_thionville and fluted_pont_a_mousson have ribs over it
- the spouts are plain tubes; on fluted_pont_a_mousson the front spout flares out of the column
- open, the spouts' ends are solid red: the references show a dark bore
- the 1 m close-up misses the head (aimed at the middle of the post)
Fixed:
- three chains of flat links turned alternately, sagging from each spout to an eye on the column
- twelve raised ribs over the dome (LOD 0)
- every spout flares out of the column; its end is a dark `hole` face
- the close-up aims at the head

## Round 3 — surface (wear, lettering, colour variation, states)
Sheet: `references/elements/reviews/hydrant_r3.jpg` (the first pass of these fixes; the states before them are the bottom row of `hydrant_r2.jpg`)
Differences (against hydrant_r2.jpg):
- abandoned and damaged look like clean: the chips are too few to see (the edge bake is weak on 15° facets)
- no lettering on the plate, no painted number (poste_rouen has both)
- the red is a toy red; fluted_pont_a_mousson's has faded to a pinkish red
- the operating nut is black; on the references it is rusty iron
- the state tiles are too far away to judge paint
- first pass (hydrant_r3.jpg): the clean post already had big patches, too much of them black bare iron where worn_paint shows mostly ochre primer, the bullet pocks still invisible
Fixed:
- chips: edges with noise plus patches that only open from "abandoned" on, through to the ochre primer, bare iron only in the middle of a patch
- sun fade towards a pale pinkish red, most on top
- "VERNAY 1887" raised on the plate (the paint rubbed off the letters), "17" painted white on the front of the column (5 x 7 stencil, `props.letters`); invented founder
- the nut and bolts a rusty iron
- bigger, denser pocks with bright rims in "damaged"
- states shot at fov 24°

## Review
Sheet: `references/elements/reviews/hydrant_rfinal.jpg`
Left over, each accepted:
- accepted: the painted number found itself on the back as well while the mask used the baked normal; it now uses position (the front half). The baked normal's Z may be flipped in `pipeline.bake_maps`; nothing else depends on its sign yet (sky uses Y). Check it when an element paints by facing (S141).
- accepted: the edge bake is weak on the facets of a lathe (15° between faces), so edge chipping shows mostly on the flanges, caps and collar; the patches carry the wear. The kit's bevelled shapes (S141) give real edges.
- accepted: dents are not in the "damaged" state (texture only). A damaged geometry variant waits for the kit's damage tools (S141).
- accepted: the plate's lettering is too small to read beyond 1 m, as on the real ones.
