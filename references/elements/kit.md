# kit — the detail kit's board: every helper of S141 side by side

Family: `tools/models/props/kit.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py kit` · sketch: `python tools/models/props.py kit --sketch` · rack: `--prop-rack=kit` (`--view=bricks` ...) · review: `python tools/models/review.py kit --round=N` (the main sheet plus one sheet of close-ups per state: `kit_r<N>_<state>.jpg`)

The kit (S141) is the helpers every later element is made of: `tools/models/shapes.py` (forms), `surfaces.py` (walls, floors, roofs, sheet, grilles), `lettering.py` (two stroke fonts), `wear.py` (wear and damage, run by `props.paint`). This board is their sample: a mason's-yard garden wall of sample panels, a door bay, copings of tiles, floor samples in front and a bench of shapes. It is never placed in a map; it exists to be reviewed, and `tests/test_elements.gd` checks that it shows every helper (`kit.json`'s `samples`) where a close-up sees it.

Seen from the front, +X is to the viewer's left (the door bay is on the viewer's right... at +X: the board reads mirrored to the layout notes in `kit.py`; nothing depends on it).

## References
Photos in `references/elements/kit/`, all from Wikimedia Commons. French first; the pavers are the only non-French photo (shape only).

| file | what it shows | source | licence |
|---|---|---|---|
| `setts_haut_pave.jpg` | a Paris street of setts and pavements, for scale | [P1170617 Paris V rue du Haut-Pavé rwk.jpg](https://commons.wikimedia.org/wiki/File:P1170617_Paris_V_rue_du_Haut-Pav%C3%A9_rwk.jpg), Mbzt | CC BY-SA 3.0 |
| `setts_granite.jpg` | granite setts close: sizes, colour spread, sand joints | [Granite paving tileable 2048x2048.jpg](https://commons.wikimedia.org/wiki/File:Granite_paving_tileable_2048x2048.jpg), Coyau | CC BY-SA 3.0 |
| `brick_toulouse.jpg` | Toulouse brick: long thin bricks, wide joints, bands | [Mur briques Toulouse.JPG](https://commons.wikimedia.org/wiki/File:Mur_briques_Toulouse.JPG), Traumrune | CC BY-SA 3.0 |
| `brick_valade.jpg` | brick under fallen plaster, crumbling joints | [Toulouse - Rue Valade - Mur briques.jpg](https://commons.wikimedia.org/wiki/File:Toulouse_-_Rue_Valade_-_Mur_briques.jpg), Traumrune | CC BY-SA 3.0 |
| `block_wall.jpg` | a parpaing garden wall: 50 x 20 blocks, running bond | [Malfaçon d'un mur de clôture en maçonnerie de parpaing.](https://commons.wikimedia.org/wiki/File:Malfa%C3%A7on_d%27un_mur_de_cl%C3%B4ture_en_ma%C3%A7onnerie_de_parpaing.jpg), Abujoy | CC BY 4.0 |
| `board_formed_keroman.jpg` | concrete with formwork marks, tie lines, stains | [Keroman III - détail traces coffrage en acier.JPG](https://commons.wikimedia.org/wiki/File:Keroman_III_-_d%C3%A9tail_traces_coffrage_en_acier.JPG), user:XIIIfromTOKYO | CC BY 3.0 |
| `tiles_canal.jpg` | a canal-tile roof: channels and covers, moss, uneven rows | [Toit en tuile-canal.jpg](https://commons.wikimedia.org/wiki/File:Toit_en_tuile-canal.jpg), No machine-readable author provided. Eme | Public domain |
| `tiles_ridge.jpg` | flat clay tiles in stepped rows, ridge caps | [Essendiéras restaurant faîtage.JPG](https://commons.wikimedia.org/wiki/File:Essendi%C3%A9ras_restaurant_fa%C3%AEtage.JPG), Père Igor | CC BY-SA 3.0 |
| `corrugated_tole.jpg` | a ribbed rolling shutter (rideau) with graffiti: the ribbed sheet | [Tôle-phrase.jpg](https://commons.wikimedia.org/wiki/File:T%C3%B4le-phrase.jpg), Wisi eu | CC0 |
| `shutters_white.jpg` | a louvred shutter (persienne) open: stiles, rails, slats | [White window shutters in Paris.JPG](https://commons.wikimedia.org/wiki/File:White_window_shutters_in_Paris.JPG), Marimarina | CC BY-SA 3.0 |
| `shutters_ile.jpg` | a Paris window: stone surround, closed persiennes, railing | [Window, 9 rue Saint-Louis en l'Île, Paris 5 February 20](https://commons.wikimedia.org/wiki/File:Window,_9_rue_Saint-Louis_en_l%27%C3%8Ele,_Paris_5_February_2017.jpg), Guilhem Vellut from Paris, France | CC BY 2.0 |
| `plate_morante.jpg` | the Paris street plate: blue enamel, white capitals, green border | [Plaque rue Morante Paris 1.jpg](https://commons.wikimedia.org/wiki/File:Plaque_rue_Morante_Paris_1.jpg), Chabe01 | CC BY-SA 4.0 |
| `plate_defense.jpg` | DÉFENSE D'AFFICHER cast plaque: raised letters, border | [Défense d'afficher Plaque - Paris, Rue Hermel.jpg](https://commons.wikimedia.org/wiki/File:D%C3%A9fense_d%27afficher_Plaque_-_Paris,_Rue_Hermel.jpg), Poulpy | CC BY-SA 3.0 |
| `pocks_mines.jpg` | 1944 bullet pocks on Paris ashlar: scattered pale craters | [P1250412 Paris VI bd St-Michel n60 ecole sup des mines ](https://commons.wikimedia.org/wiki/File:P1250412_Paris_VI_bd_St-Michel_n60_ecole_sup_des_mines_impact_balles_bis_rwk.jpg), Mbzt | CC BY-SA 3.0 |
| `pocks_florentin.jpg` | pocks on ashlar, a cellar vent grille | [P1020396 Paris VIII Rue Saint-Florentin 1944 impacts de](https://commons.wikimedia.org/wiki/File:P1020396_Paris_VIII_Rue_Saint-Florentin_1944_impacts_de_balles_rwk.JPG), Mbzt | CC BY 3.0 |
| `posters_rol.jpg` | posters pasted on a Paris wall, layered and torn | [Ensemble d'affiches murales sur un mur de Paris photogr](https://commons.wikimedia.org/wiki/File:Ensemble_d%27affiches_murales_sur_un_mur_de_Paris_photographie_de_presse,_Agence_Rol.jpg), Agence Rol. Agence photographique | Public domain |
| `graffiti_1871.jpg` | sprayed capitals on plaster | [Graffiti "We are 1871" Paris 2019.jpg](https://commons.wikimedia.org/wiki/File:Graffiti_%22We_are_1871%22_Paris_2019.jpg), Ittmostt | CC BY 2.0 |
| `grille_arbre.jpg` | a Paris cast-iron tree grate: rings and radial bars | [Paris 3e Place Nathalie-Lemel Grille d'arbre 669.jpg](https://commons.wikimedia.org/wiki/File:Paris_3e_Place_Nathalie-Lemel_Grille_d%27arbre_669.jpg), GFreihalter | CC BY-SA 4.0 |
| `glass_montreux.jpg` | a pane cracked round a hole: radial cracks and rings | [Gare-Montreux-vitre-brisée-20220613.jpg](https://commons.wikimedia.org/wiki/File:Gare-Montreux-vitre-bris%C3%A9e-20220613.jpg), MHM55 | CC BY-SA 4.0 |
| `glass_broken.jpg` | an abandoned window: broken panes, peeling frame | [Broken-window hg.jpg](https://commons.wikimedia.org/wiki/File:Broken-window_hg.jpg), Hannes Grobe | CC BY-SA 4.0 |
| `paint_perpignan.jpg` | paint peeling off a door to the wood, stained stone | [Balcony in Perpignan.JPG](https://commons.wikimedia.org/wiki/File:Balcony_in_Perpignan.JPG), Mmorell | CC BY-SA 4.0 |
| `paint_saint_brieuc.jpg` | faded paint and lettering on planks | [Saint-Brieuc - 20180328 (1).jpg](https://commons.wikimedia.org/wiki/File:Saint-Brieuc_-_20180328_(1).jpg), Olybrius | CC BY-SA 4.0 |
| `road_bus_carnot.jpg` | stencilled road markings, figures on asphalt | [Arrêt de bus Carnot (avenue Carnot, Clermont-Ferrand) -](https://commons.wikimedia.org/wiki/File:Arr%C3%AAt_de_bus_Carnot_(avenue_Carnot,_Clermont-Ferrand)_-_C%C3%B4t%C3%A9_nord,_marquage_au_sol_des_lignes_desservies_2025-12-20.JPG), Tabl-trai | CC BY-SA 4.0 |
| `pavers_polyhaven.jpg` | interlocking concrete pavers (not French: the shape only) | [PREVIEW interlocking concrete pavers (Amal Kumar via Po](https://commons.wikimedia.org/wiki/File:PREVIEW_interlocking_concrete_pavers_(Amal_Kumar_via_Poly_Haven).png), Amal Kumar | CC0 |
| `moss_lille.jpg` | moss and plants on damp ashlar joints | [Citadelle de Lille 2013 plantes muricoles 01.JPG](https://commons.wikimedia.org/wiki/File:Citadelle_de_Lille_2013_plantes_muricoles_01.JPG), Lamiot | CC BY-SA 3.0 |
| `block_tregastel.jpg` | concrete blocks close: hollows, texture, maker's mark | [Parpaings sur chantier à Trégastel.jpg](https://commons.wikimedia.org/wiki/File:Parpaings_sur_chantier_%C3%A0_Tr%C3%A9gastel.jpg), Syced | CC0 |
| `stencil_crate.jpg` | stencilled letters on a crate board, worn | [Board from a wooden shipping crate with stencil "Glass ](https://commons.wikimedia.org/wiki/File:Board_from_a_wooden_shipping_crate_with_stencil_%22Glass_With_Care%22_and_hand_lettering_%22Bath_B(%3F)%22_LCCN2010651505.jpg), Miscellaneous Items in High Demand, PPOC | Public domain |

## Measurements
Against the 2.1 m door and the units' own standard sizes (French brick 22 x 10.5 x 5.5 cm; parpaing 50 x 20 x 20; the 1 m checker of the rack's floor).

- size (m): 7.75 x 2.75 x 3.73
- board: wall 6.1 m long, 2.05 high, panels 0.9 x 0.92 in two tiers, standing 3 cm proud; door bay 1.3 x 2.75; floor strip 1.2 deep; bench 0.72 high, 0.6 deep
- brick (stretcher, flemish, english): 220 x 55 face, 10 mm joints; headers 105; foraine (Toulouse, brick_toulouse): 400 x 45 face, 22 mm joints
- concrete block: 500 x 200, 10 mm joints (block_wall)
- ashlar: courses 320–460 high, stones 250–550 long, 5 mm joints (pocks_mines, moss_lille)
- board-formed concrete: boards 140, tie holes on a 600 x 560 grid (board_formed_keroman)
- setts: 200 x 140, 14 mm sand joints, tops chamfered round (setts_granite); fans of 100 mm cubes, a fan 1 m across, rows 0.5 m apart
- pavers: double-T 200 x 165, 60 thick, 4 mm joints (pavers_polyhaven)
- flat tiles: 170 x 270, 105 gauge, each resting 4.5° steeper than the roof (tiles_ridge); canal tiles 420 long, 210/160 wide, 300 gauge (tiles_canal); ridge caps 400, half round Ø 220, on mortar fillets
- corrugated sheet: 76 mm pitch, 18 deep; ribbed (rolling-shutter) sheet: 250 pitch, 35 deep (corrugated_tole)
- welded mesh: 50 mm, 4 mm wire, angle frame
- persienne: slats 50 mm at 38°, stiles 55 (shutters_white)
- window (half size, to fit a panel): opening 0.5 x 0.62, moulded surround 75, segmental arch rise 60, keystone, sill 45 thick with drip
- door: 0.95 x 2.1, surround 90, cornice; leaf of two inset and two raised panels
- street plate 0.60 x 0.22, letters 50 mm (plate_morante); house number 120 x 140; cast plaque 0.56 x 0.20, raised letters 29 mm (plate_defense)
- road word: letters 0.9 m long, 3.2 times as long as wide (road_bus_carnot; real ones are 1.6 m and more: the strip is only 1.2 m deep)
- tree grate Ø 0.48 (half size: grille_arbre's is about 1.2 m, square framed)

## Visible details
M modelled, B baked (painted). Every sample's name as in `tests/test_elements.gd`.

Shapes (`shapes.py`):
- [ ] M chamfer_box, bevel_box: boxes with edges cut once or twice (clipped by planes, so any edges)
- [ ] M lathe: a turned baluster
- [ ] M extrude: a T outline (concave), its front edge chamfered
- [ ] M panel_inset, panel_raised: door panels
- [ ] M array_linear: a railing of seven balusters between plinth and rail; array_radial: eight bolts round a flange
- [ ] M sweep_pipe: a pipe bent three ways; cable: sagging between two posts; handrail on posts, its ends turned down
- [ ] M window_frame (moulding swept round an arched opening, keystone, sill, drip), door_frame (jambs and head, cornice)
- [ ] M vent (slots), louvre_vent (slanted louvres), dark behind
- [ ] M cut: a column cut on a slanting rough break; its top is the moving part `fallen`
Surfaces (`surfaces.py`):
- [ ] B brick_stretcher, brick_flemish, brick_english, brick_foraine, concrete_block, ashlar: bonds painted, each unit its own shade, recessed joints darker
- [ ] B board_formed: board prints, grain, ridges, tie holes
- [ ] B plaster over brick (falls off with the years)
- [ ] M setts in rows (edge setts cut to fit), setts_fan (fish-scale fans), pavers
- [ ] M roof_flat_tiles (stepped rows, round-cut tails), roof_canal_tiles (channels and covers), ridge_caps on mortar fillets
- [ ] M corrugated, ribbed sheet; mesh in an angle frame; grille (rings, spokes, dark under); louvres (the shutter)
Lettering (`lettering.py`):
- [ ] B font_block: street plate RUE DES TANNEURS / XVIIE SIÈCLE, house number 12, road word BUS stretched
- [ ] B font_stencil: ABRI 12 / À 50 M on the concrete, MUNITIONS on the crate
- [ ] M raised cast letters: ÉDIFICE PUBLIC / DÉFENSE D'AFFICHER / LOI DU 29 JUILLET 1881
Wear (`wear.py`):
- [ ] B chips (to primer, then bare), rust_runs under the six bolts, water_stains under every coping, dirt_foot, moss (abandoned), plaster falling, posters (two, French, torn), graffiti (ILS ARRIVENT on plaster; NE PAS OUVRIR on the ribbed sheet once abandoned)
Damage:
- [ ] M dents in the corrugated sheet; broken_glass: a pane with a jagged hole
- [ ] B glass cracks round the hole, pocks by material (damaged), soot plumes over the window and door (burnt), burnt_materials: a swatch of each kind (wood, painted metal, brick, plaster, glass, clay, rubber, cloth)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| bricks, block, ashlar, board | the pattern | — | — | stains, grime in joints, moss low, soot, pocks pale |
| plaster | off-white lime, patched | the brick bond under it | — | falls off in patches (abandoned on) |
| coping, surround, column, slab | limestone | — | — | sheds water: stains below |
| plate, shape, pipe, rail, angle | paint (green-grey, blue-grey, black) | ochre primer | dark steel | chips, rust |
| bolt | dark steel | — | rust | fixing: rust runs below |
| zinc, shutter_steel | galvanised, green paint | — | steel | chips, rust |
| joinery, persienne, door | cream, grey-green, Paris green paint on wood | lighter undercoat | grey wood | chips to wood, chars when burnt |
| enamel | blue enamel | — | black iron | chips at the edges |
| glass | dark blue-grey | — | — | cracks, pocks as stars, smoked when burnt |
| sett, paver, tile, canal | a palette per unit | — | — | grime, moss, soot |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 90000 | 3 | 30 m |
| 1 | 30000 | 1 | 90 m |
| 2 | 6000 | 1 | 300 m |

The board is a review piece, never placed in a map; its texture is 2048 (`tex`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| shutter | the window's left jamb | swings 165° open about Y |
| fallen | the cut column's lowest corner | topples 80° about Z |

## States
clean · abandoned (fade, chips, stains, moss, plaster falling, the second graffiti) · damaged (heavy chips, pocks by material) · burnt (soot plumes over the openings, every material's burnt version)

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/kit_r1.jpg`, close-ups `kit_r1_<state>.jpg`
Differences from the references:
- the close-ups were shot portrait (the review window is 600 x 800), too narrow to judge a panel
- the texture (2048 over ~30 m²) is far too coarse for lettering: the street plate, posters, graffiti and stencils are blocks of pixels; plate_morante and stencil_crate read at arm's length
- the road word reads mirrored from the front (BUS as SUB)
- the louvred shutter closes over the broken pane, so the broken glass cannot be seen
- the 50 m tile is a smear of stripes: LOD 1 and 2 took their UVs corner by corner from LOD 0's nearest face, tearing every big face across many islands (a pipeline fault S140 hid on the small hydrant)
- abandoned: wooden things chip to an orange primer and orange wood, which reads as rust; paint_perpignan's door wears to a pale undercoat and grey wood
- abandoned: plaster falls off in huge sheets (half of every plastered bay), brick_valade loses patches
- abandoned: moss is green spots all over the paving and walls, moss_lille has it in the joints and low down
- graffiti NE PAS OUVRIR is set 2.4 m wide on a 0.9 m sheet
- burnt: one even soot from the foot up over everything, the bricks' pattern gone; the road paint stays bright yellow
Fixed:
- close-ups are shot 1280 x 720 (`PropRack.review`), 19 named views in `kit.json`
- the board's texture is 4096, and lettered or fine surfaces get more of it (`uv_scale`: enamel x6, cast, letters, board, crate x2, ...)
- the road word's `right` is the reader's (-X); the convention is written in `lettering.py`: `right` is the reader's right, the text faces `right x up`
- the broken pane moved to the right leaf
- `pipeline.transfer_uvs` rewritten: each LOD face takes one LOD 0 triangle under its middle (same facing) and maps all its corners through it; a face much bigger than that triangle takes one colour
- wood's under and bare are a pale undercoat and grey wood
- plaster falls in smaller patches (threshold 0.84 - 0.22 x wear)
- moss: on flat ground only in joints and shaded corners; on walls low, north and in joints, in bigger patches
- graffiti scales to fit its box
- burnt: soot rises (more higher up), darkens rather than paints over; masonry darkens in clouds; the lettering is painted before the damage (`extra_first`), so it burns too

## Round 2 — structure (the secondary forms)
Sheet: `references/elements/reviews/kit_r2.jpg`, close-ups `kit_r2_<state>.jpg`
Differences:
- floor samples: many pavers and the road strip flicker or vanish: their tops lie at y = 0, on the ground plane (an element stands on y = 0, it does not sink into it)
- the street plate's first line runs off both ends (RUE DES TANNEURS 0.69 m on a 0.6 m plate)
- setts read as flat tiles with wide gaps; setts_granite's are domed, tight, speckled
- brick panels are a patchwork of light and dark bricks; brick_valade and brick_toulouse read as one red with small variation
- the stencil's bridges are too thin to see at 2 m; stencil_crate's breaks are obvious
- the corrugated sheet's dents are X-shaped pinches (12 rows of points are too few to bend)
- the glass close-up misses the broken pane
- burnt and abandoned: every thresholded noise (chips, burns, moss, plaster) makes square blobs, a camouflage of pixels: the value noise's lattice runs along the axes
- chamfer_box's cut faces were wound against the box (24 edges): Blender re-orients each piece so it did not show, but `shapes.check()` now counts it
Fixed:
- the floor samples stand on the ground (`FLOOR_LIFT` 0.09: their beds' bottoms at y = 0)
- plate 0.66 wide, its first line 42 mm
- setts: tops and corners rounded (2-cut bevel of 22 mm on the top and upright edges), 10 mm joints, a granite speckle (`Material.speckle`)
- brick palette narrowed, each brick +-6 %
- stencil bridges 0.9 of a stroke unit
- corrugated sheet 32 rows of points, softer dents
- glass close-up aimed at the broken pane
- `noise.fbm_round`: each octave on its own turned lattice and domain-warped; `wear.py` uses it everywhere (the characters keep `fbm`)
- `clip` turns its cap to agree with the faces it closes; `shapes.check()` fails on miswound shapes (`miswound`)

## Round 3 — surface (wear, lettering, colour variation, states)
Sheet: `references/elements/reviews/kit_r3.jpg`, close-ups `kit_r3_<state>.jpg`
Differences:
- clean: the plate, setts (domed, speckled), fans, pavers and bricks now match plate_morante, setts_granite, pavers_polyhaven, brick_valade
- the tree grate reads as a black hole: dark iron over a black box; grille_arbre's iron is dark grey over brown earth
- the broken pane cannot be told from the others: the glass is as dark as the room behind it; glass_montreux and glass_broken show a pale pane with a dark hole
- the corrugated sheet's dents are oval rings: the whole sheet was pushed in, crests and troughs alike; a kicked sheet has its crests flattened
- damaged: painted wood (the door, the persienne) chips in big camouflage patches; paint_perpignan peels in narrow strips along the grain
- damaged: the enamel plate is half rust; enamel chips in small flakes at the edges and the bolt holes
Fixed:
- the grate stands over earth (sand), its iron a lighter dark grey
- glass is a lighter blue-grey with soft diagonal sheens of sky (`wear.base`, kind glass)
- `shapes.dent(..., crush=True)`: only what stands proud of the dent's bowl is pushed onto it
- `wear.chips` on wood: the patch noise stretched upright, its threshold higher: strips along the grain
- enamel chips at 0.6

## Round 4 — the states again
Sheet: `references/elements/reviews/kit_r4.jpg`, close-ups `kit_r4_<state>.jpg`
Differences:
- burnt: soot now rises and the bricks show through it, as on a fired facade; but plaster and wood still break into stair-stepped blotches a centimetre or two across: texels. The 4096 texture is spent on island margins (every sett, tile and paver is an island with a 4 mm margin) and on hidden backs (the backing wall's back, the door bay's slab)
- burnt: the bench and crate read as grey-and-black camouflage: hard-edged ash patches on every upward face, mottled char
Fixed:
- `uv_margin` per element (the kit 0.0015); `uv_scale` gives backs, undersides, mortar and sand less (`backing` 0.35, `bench` 0.6, ...); the door bay is a backing slab with a thin plaster skin
- ash lies in soft-edged drifts (`clip((noise - 0.5) x 3)`), char an even black with darker cracks

## Round 5 — texture density and the burnt version
Sheet: `references/elements/reviews/kit_r5.jpg`, close-ups `kit_r5_<state>.jpg` (the final sheets)
Differences:
- none of the earlier ones left: char reads as an even black with cracks, ash in soft drifts, soot plumes stand over the door and the window, the bricks show through the soot; the far LODs wear their texture without tearing (`far_50m`)
- the plaster round the window still shows texel steps at the 0.75 m close-up (plaster falling, burnt)
- the 50 m view (LOD 1) has one board-formed triangle painted the green of its neighbour
- the graffiti stays red in the burnt state where little soot reaches it
Fixed: nothing more this round; the three are accepted below.

## Review
Sheets: `references/elements/reviews/kit_r5.jpg` and `kit_r5_clean.jpg` / `_abandoned` / `_damaged` / `_burnt`
Left over, each accepted:
- accepted: texel steps on plaster at 0.75 m. The board spreads one 4096 texture over ~38 m² and 41 800 triangles; at play distance (2 m and more) they do not show. Real elements are one thing each with their own texture.
- accepted: one LOD 1 triangle takes a neighbour's colour at 50 m (`transfer_uvs`' fallback for a face much bigger than the triangle under it). One triangle at 50 m on a review board.
- accepted: graffiti burns only where the soot reaches it, as paint does.
- accepted: roof paint (words painted on roofs) has no sample: it is the same `lettering.mask` as the road word, on a roof's faces.
- accepted: slate and zinc roofs, the core of a Paris roofscape, are not in the kit yet (the step asks for clay tiles); they belong to the roof element steps.
- accepted: the board is seen mirrored from the layout notes in `kit.py` (+X is the viewer's left); nothing depends on it.
- accepted: the kit's PNGs are 4096 (about 11 MB each, 4 states and a wear map); it is a review piece and never loaded in a map.
- the hydrant was rebuilt on the kit's painter (`references/elements/reviews/hydrant_rkit.jpg`): unchanged in form, its number now in the block font, its chips rounder.
