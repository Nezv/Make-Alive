# ammo_crate — the wooden ammunition crate (S152)

Family: `tools/models/props/containers.py` · registry: `scripts/models/elements.gd` · build: `tools\blender.ps1 tools\models\props.py ammo_crate` · sketch: `python tools/models/props.py ammo_crate --sketch` · rack: `--prop-rack=ammo_crate` · review: `python tools/models/review.py ammo_crate --round=N`

The long olive crate `ammo_crate.gd` gives rounds from: boards on a frame, end cleats, rope handles knotted through the ends, steel corners, two hasps, CARTOUCHES and a lot number stencilled, the rounds' packets inside; the lid of four boards on two battens, hinged along the back.

## References
Wikimedia Commons, `references/elements/ammo_crate/`.

| file | what it shows | source | licence |
|---|---|---|---|
| `trench_1915.jpg` | **the main reference**: French wooden crates of 1915 at a dugout: boards, cleats, rope handles, the lids | [Notre-Dame-de-Lorette, dépôt de munitions à l'arrière des tranchées, grenades à mains (soldats maniant des caisses en bois devant l'entrée d'un abri souterrain) - btv1b6933738g.jpg](https://commons.wikimedia.org/wiki/File:Notre-Dame-de-Lorette,_d%C3%A9p%C3%B4t_de_munitions_%C3%A0_l%27arri%C3%A8re_des_tranch%C3%A9es,_grenades_%C3%A0_mains_(soldats_maniant_des_caisses_en_bois_devant_l%27entr%C3%A9e_d%27un_abri_souterrain)_-_btv1b6933738g.jpg), Agence Rol. Agence photographique (commanditaire) | Public domain |
| `stacks.jpg` | crates and cartons stacked at a resupply: their sizes against people | [1-118th Field Artillery resupplies (6009479096).jpg](https://commons.wikimedia.org/wiki/File:1-118th_Field_Artillery_resupplies_(6009479096).jpg), Georgia National Guard from United States | CC BY 2.0 |

## Measurements
The game's crate (1.10 x 0.36 x 0.50); trench_1915's crates against the soldiers' hands.

- size (m): 1.24 x 0.41 x 0.57
- boards 22 mm, three a side
- cleats 0.08 wide at each end
- rope handles 0.18 apart

## Visible details
- [x] M boards, bottom, ends, cleats, rope handles and knots, corners, hasps, packets and rounds inside, lid boards and battens (R1)
- [x] B CARTOUCHES, LOT 14-07 1200, the calibre's band (R1)
- [ ] M nail heads, the hasps' staples and pins (R2)
- [ ] B worn olive, splinters, dirt at the foot (R3)

## Materials
| tag | coat | under | bare | wear |
|---|---|---|---|---|
| wood | olive paint on pine |  | pale pine | worn on the edges |
| rope | hemp |  |  | frayed |
| steel | corners and hasps |  | rust |  |
| brass | the rounds |  |  |  |

## Budget
| LOD | triangles (max) | draws | drawn up to |
|---|---|---|---|
| 0 | 1150 | 1 | 15 m |
| 1 | 380 | 1 | 40 m |
| 2 | 120 | 1 | 120 m |

Repeated: MultiMesh (`PropModel.multimesh`).

## Moving parts
| part | pivot | motion |
|---|---|---|
| lid | the back's top edge (0, 0.36, 0.26) | rotate 105° about +X |

## States
clean · abandoned · damaged · burnt; empty waits for round 3 (the packets gone).

## Round 1 — form (silhouette, proportions, real size)
Sheet: `references/elements/reviews/ammo_crate_r1_sketch.png` (sketch close-ups; the rack's sheet waits for a windowed run: `python tools/models/review.py ammo_crate --round=1`)
Differences from the references:
- -
Fixed:
- -
Open:
- -

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
