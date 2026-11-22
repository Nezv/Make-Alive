class_name CityData
## Central Joinville as data, traced by hand from references/joinville.png.
##
## Every coordinate here is a pixel of that picture (x right, y down, north is up). `to_world`
## turns a pixel into metres: the bus terminal is the origin, east is +X and north is -Z.
## CityMap decides which part to keep (the POIs plus a margin) and builds it.

const REF_IMAGE := "res://references/joinville.png"
const M_PER_PX := 200.0 / 89.0             ## the picture's scale bar: 200 m is 89 px
const ORIGIN_PX := Vector2(1035, 504)      ## Terminal Central
## joinville_topography.png has the same scale, shifted: topography pixel + this = joinville.png pixel.
## Matched on the Rio do Engenho park pond, which both pictures show.
const TOPO_OFFSET_PX := Vector2(183, -477)

const RIVER_WIDTH := 26.0

## The five mission places. `at` is where a player stands, `lot` its grounds (cleared of city
## buildings) and `gate` a point on the nearest street that the lot is joined to.
const POIS := {
	"hospital": { "name": "HOSPITAL DONA HELENA", "at": Vector2(742, 405), "gate": Vector2(777, 405),
		"lot": [Vector2(722, 371), Vector2(762, 371), Vector2(762, 439), Vector2(722, 439)] },
	"terminal": { "name": "TERMINAL CENTRAL", "at": Vector2(1035, 504), "gate": Vector2(1035, 529),
		"lot": [Vector2(1013, 488), Vector2(1057, 488), Vector2(1057, 520), Vector2(1013, 520)] },
	"prefeitura": { "name": "PREFEITURA DE JOINVILLE", "at": Vector2(1200, 215), "gate": Vector2(1160, 214),
		"lot": [Vector2(1174, 195), Vector2(1226, 195), Vector2(1226, 235), Vector2(1174, 235)] },
	"batalhao": { "name": "62º BATALHÃO DE INFANTARIA", "at": Vector2(665, 840), "gate": Vector2(686, 742),
		"lot": [Vector2(578, 795), Vector2(640, 765), Vector2(775, 880), Vector2(745, 900), Vector2(620, 892), Vector2(568, 842)] },
	# On the 230 m summit of Morro da Boa Vista, where the road ends. joinville.png shows only the tip
	# of the hill under its zoom buttons; this and the road up come from joinville_topography.png.
	"mirante": { "name": "MIRANTE DE JOINVILLE", "at": Vector2(1866, 45), "gate": Vector2(1848, 43),
		"lot": [Vector2(1880, 45), Vector2(1876, 55), Vector2(1866, 59), Vector2(1856, 55), Vector2(1852, 45),
			Vector2(1856, 35), Vector2(1866, 31), Vector2(1876, 35)] },
}

## Points the map's edge must also enclose: the hairpin of the road up to the Mirante, which
## swings north of the summit (the edge is the hull of the POI lots plus these, grown by CITY_MARGIN).
const EDGE_EXTRA := [Vector2(1808, -92), Vector2(1773, -37)]

## Rio Cachoeira, north to south.
const RIVER := [Vector2(1128, -90), Vector2(1130, 150), Vector2(1150, 220), Vector2(1154, 330), Vector2(1153, 440),
	Vector2(1168, 500), Vector2(1195, 560), Vector2(1232, 640), Vector2(1300, 740), Vector2(1420, 840)]

## Morro da Boa Vista: forest, crossed only by the road up to the Mirante.
const FOREST := [Vector2(1205, 265), Vector2(1290, 215), Vector2(1400, 200), Vector2(1410, 130), Vector2(1560, 110),
	Vector2(1620, 60), Vector2(1625, -330), Vector2(2110, -330), Vector2(2100, 420), Vector2(1620, 440),
	Vector2(1480, 600), Vector2(1340, 720), Vector2(1260, 600), Vector2(1215, 520), Vector2(1200, 420)]

## Open green ground: the old cemetery by the Hôtel-Dieu.
const PARKS := [
	[Vector2(668, 352), Vector2(735, 352), Vector2(735, 420), Vector2(690, 420), Vector2(668, 395)],
]

# --- The town's plan (S040) -----------------------------------------------------------------------
# Joinville gives the bones: the river and the roads on its two banks (the quays), the hill and its
# road up, where the five places stand and the roads that join them. On them stands a French town as
# Paris was around 1800: an old core of crooked streets round the place du Marché (where Praça da
# Bandeira is, by the gare routière), closed by a boulevard on the line of the old walls that runs from
# the quay round to the quay again and meets it at a rond-point; faubourgs outside it, the caserne at
# the end of the faubourg Saint-Rémy; the hôtel de ville across the river at the foot of the hill.

const DRIVE := 8.0          ## metres: the way from a POI's gate to its door
const NAV_MIN_WIDTH := 6.0  ## metres: no street is narrower than this on the 4 m navigation grid
const RING_ROAD := 7.0      ## metres: the carriageway round a rond-point's island

## Street surfaces (pavements are always `flags`).
const SURFACES := ["setts", "asphalt", "flags"]

## What each kind of street is, in metres: `road` the carriageway kerb to kerb, `walk` the pavement
## [left, right] looking along the street's points, `mall` the gravel walk under trees down the middle
## of a boulevard (inside `road`, between its two carriageways), `oneway` 1 along the points, -1
## against, 0 both ways, `covered` for a passage through a block under the houses. A street may
## override any of them.
const KINDS := {
	"boulevard": { "road": 24.0, "walk": [4.0, 4.0], "mall": 10.0, "surface": "asphalt", "oneway": 0 },
	"quai": { "road": 8.0, "walk": [3.0, 2.5], "surface": "setts", "oneway": 0 },
	"pont": { "road": 8.0, "walk": [2.5, 2.5], "surface": "setts", "oneway": 0 },
	"grande_rue": { "road": 7.0, "walk": [2.0, 2.0], "surface": "setts", "oneway": 0 },
	"rue": { "road": 5.0, "walk": [1.5, 1.5], "surface": "setts", "oneway": 0 },
	"ruelle": { "road": 3.5, "walk": [0.0, 0.0], "surface": "setts", "oneway": 0 },
	"impasse": { "road": 3.5, "walk": [0.0, 0.0], "surface": "setts", "oneway": 0 },
	"passage": { "road": 3.0, "walk": [0.0, 0.0], "surface": "flags", "oneway": 0, "covered": true },
	"faubourg": { "road": 8.0, "walk": [2.5, 2.5], "surface": "asphalt", "oneway": 0 },
	"route": { "road": 7.0, "walk": [1.5, 1.5], "surface": "asphalt", "oneway": 0 },
	"chemin": { "road": 6.0, "walk": [0.0, 0.0], "surface": "asphalt", "oneway": 0 },
}

## Every name in the town, invented: streets and places by id. Never a real street of a real town on
## purpose (common French names like rue du Marché are everywhere, which is the point).
const NAMES := {
	"rempart": "boulevard du Rempart",
	"saint_remy_blvd": "boulevard Saint-Rémy",
	"bateliers": "quai des Bateliers",
	"vigie": "quai de la Vigie",
	"pont_hdv": "pont de l'Hôtel-de-Ville",
	"pont_neuf": "pont Neuf",
	"pont_vieux": "pont Vieux",
	"route_paris": "route de Paris",
	"recollets": "rue des Récollets",
	"capucins": "rue des Capucins",
	"montagne": "rue de la Montagne",
	"telegraphe": "chemin du Télégraphe",
	"grande_rue": "Grande Rue",
	"pont": "rue du Pont",
	"harpe_rouge": "rue de la Harpe-Rouge",
	"saint_jacques": "rue Saint-Jacques",
	"marche_rue": "rue du Marché",
	"saint_martin": "rue Saint-Martin",
	"harpe": "rue de la Harpe",
	"carmes": "rue des Carmes",
	"gare": "rue de la Gare",
	"puits": "rue du Puits",
	"ursulines": "rue des Ursulines",
	"heaume": "rue du Heaume",
	"orfevres": "rue des Orfèvres",
	"sainte_croix": "rue Sainte-Croix",
	"tanneurs": "rue des Tanneurs",
	"lanternes": "passage des Lanternes",
	"cheval_blanc": "passage du Cheval-Blanc",
	"arbalete": "ruelle de l'Arbalète",
	"chat": "ruelle du Chat-qui-Dort",
	"moines": "ruelle des Moines",
	"teinturiers": "ruelle des Teinturiers",
	"cordeliers": "impasse des Cordeliers",
	"four": "impasse du Four",
	"sainte_anne": "impasse Sainte-Anne",
	"cygne": "impasse du Cygne",
	"croix_blanche": "route de la Croix-Blanche",
	"cordiers": "rue des Cordiers",
	"jardins": "rue des Jardins",
	"lavandieres": "rue des Lavandières",
	"vignes": "chemin des Vignes",
	"faubourg": "rue du Faubourg-Saint-Rémy",
	"champ_de_mars": "rue du Champ-de-Mars",
	"moulins": "rue des Moulins",
	"val": "route du Val",
	"fosses": "rue des Fossés",
	"poudriere": "chemin de la Poudrière",
	"marche": "place du Marché",
	"eglise": "place de l'Église",
}

## Paved squares, open ground.
const SQUARES := [
	{ "id": "marche", "pts": [Vector2(1068, 486), Vector2(1095, 482), Vector2(1121, 488), Vector2(1123, 520),
		Vector2(1094, 527), Vector2(1066, 525)] },
	{ "id": "eglise", "pts": [Vector2(893, 528), Vector2(985, 530), Vector2(992, 597), Vector2(930, 601), Vector2(906, 570)] },
]

## Where streets meet round an island: `at` a point on both streets, `r` the outer radius in metres.
const ROUNDABOUTS := [{ "at": Vector2(1215, 626), "r": 22.0 }]

## The streets, each `{ id, kind, pts }` in pixels of joinville.png, and optional overrides of its
## kind (`road`, `walk`, `oneway`, `surface`) and `narrow`: a factor on the carriageway per point,
## where the street pinches or opens out. Streets meet where an end lies on another street (within a
## few metres) or where two cross; StreetNet finds the junctions. Only what lies inside the map's
## edge is built.
const STREETS := [
	# The boulevard on the line of the old walls, from the quay north of the core round to the quay south.
	{ "id": "rempart", "kind": "boulevard", "pts": [Vector2(1143, 292), Vector2(1090, 298), Vector2(1030, 296),
		Vector2(968, 290), Vector2(905, 298), Vector2(850, 312), Vector2(808, 338), Vector2(784, 372), Vector2(777, 405),
		Vector2(772, 462), Vector2(776, 510), Vector2(790, 560)] },
	{ "id": "saint_remy_blvd", "kind": "boulevard", "pts": [Vector2(790, 560), Vector2(818, 604), Vector2(862, 640),
		Vector2(925, 664), Vector2(1000, 673), Vector2(1075, 665), Vector2(1140, 646), Vector2(1215, 626)] },
	# The quays, along both banks of the river.
	{ "id": "bateliers", "kind": "quai", "walk": [2.5, 3.0], "pts": [Vector2(1118, 105), Vector2(1120, 152),
		Vector2(1140, 221), Vector2(1144, 330), Vector2(1143, 441), Vector2(1158, 503), Vector2(1186, 564),
		Vector2(1215, 626), Vector2(1225, 648)] },
	{ "id": "vigie", "kind": "quai", "walk": [3.0, 2.5], "pts": [Vector2(1138, 106), Vector2(1139, 148),
		Vector2(1160, 218), Vector2(1164, 330), Vector2(1163, 440), Vector2(1177, 497), Vector2(1204, 556),
		Vector2(1241, 636)] },
	{ "id": "pont_hdv", "kind": "pont", "pts": [Vector2(1140, 221), Vector2(1160, 218)] },
	{ "id": "pont_neuf", "kind": "pont", "pts": [Vector2(1143, 441), Vector2(1163, 440)] },
	{ "id": "pont_vieux", "kind": "pont", "road": 6.0, "pts": [Vector2(1158, 503), Vector2(1177, 497)] },
	# North of the walls: the road out to Paris and the lanes up to it.
	{ "id": "route_paris", "kind": "route", "pts": [Vector2(1140, 221), Vector2(1100, 212), Vector2(1050, 203),
		Vector2(1000, 192), Vector2(948, 188)] },
	{ "id": "recollets", "kind": "rue", "oneway": 1, "pts": [Vector2(968, 290), Vector2(972, 250), Vector2(980, 215), Vector2(985, 191)] },
	{ "id": "capucins", "kind": "rue", "oneway": -1, "pts": [Vector2(1090, 298), Vector2(1080, 262), Vector2(1070, 232), Vector2(1062, 206)] },
	# Across the river: the hôtel de ville at the foot of the hill and the road up it.
	{ "id": "montagne", "kind": "route", "pts": [Vector2(1160, 218), Vector2(1170, 195), Vector2(1200, 185),
		Vector2(1226, 183), Vector2(1280, 175), Vector2(1330, 165)] },
	# Traced on joinville_topography.png (pixel + TOPO_OFFSET_PX): two S-bends up the west slope, a
	# hairpin north of the summit, then back south-east onto the top. Negative y is above joinville.png.
	# It starts where the road along the south of the Rio do Engenho park ends.
	{ "id": "telegraphe", "kind": "chemin", "walk": [1.0, 1.0], "pts": [Vector2(1330, 165), Vector2(1385, 187), Vector2(1430, 198), Vector2(1470, 212),
		Vector2(1500, 207), Vector2(1520, 212), Vector2(1535, 235), Vector2(1560, 255), Vector2(1590, 280), Vector2(1615, 297),
		Vector2(1630, 300), Vector2(1648, 283), Vector2(1665, 253),
		Vector2(1678, 218), Vector2(1680, 188), Vector2(1698, 168), Vector2(1700, 148), Vector2(1688, 118), Vector2(1688, 88),
		Vector2(1668, 53), Vector2(1668, 33), Vector2(1683, 15), Vector2(1708, 10), Vector2(1733, -2), Vector2(1773, -37),
		Vector2(1798, -77), Vector2(1808, -92), Vector2(1818, -87), Vector2(1825, -57), Vector2(1818, -27), Vector2(1813, 8),
		Vector2(1823, 33), Vector2(1848, 43), Vector2(1866, 45)] },
	# The old core. West to east...
	{ "id": "grande_rue", "kind": "grande_rue", "narrow": [1.0, 0.9, 0.8, 1.0, 0.9, 1.0, 1.2, 1.5],
		"pts": [Vector2(772, 462), Vector2(812, 468), Vector2(858, 471), Vector2(902, 478), Vector2(948, 476),
		Vector2(995, 481), Vector2(1040, 483), Vector2(1068, 488)] },
	{ "id": "pont", "kind": "rue", "pts": [Vector2(1121, 503), Vector2(1140, 504), Vector2(1158, 503)] },
	{ "id": "harpe_rouge", "kind": "rue", "oneway": 1, "narrow": [1.0, 1.0, 0.8, 1.0, 1.0, 0.8, 1.0, 1.0, 1.0, 1.0],
		"pts": [Vector2(775, 425), Vector2(815, 423), Vector2(850, 428), Vector2(893, 424), Vector2(935, 430),
		Vector2(990, 433), Vector2(1030, 438), Vector2(1068, 440), Vector2(1110, 438), Vector2(1143, 441)] },
	{ "id": "saint_jacques", "kind": "rue", "oneway": -1, "pts": [Vector2(808, 338), Vector2(850, 347), Vector2(902, 352),
		Vector2(950, 349), Vector2(1000, 352), Vector2(1048, 347), Vector2(1080, 342)] },
	{ "id": "heaume", "kind": "rue", "oneway": 1, "pts": [Vector2(904, 325), Vector2(935, 320), Vector2(976, 330),
		Vector2(1027, 322), Vector2(1085, 320)] },
	{ "id": "gare", "kind": "grande_rue", "surface": "asphalt", "pts": [Vector2(889, 522), Vector2(940, 524), Vector2(990, 528),
		Vector2(1035, 530), Vector2(1066, 526), Vector2(1094, 528), Vector2(1130, 536), Vector2(1160, 548), Vector2(1180, 551)] },
	{ "id": "orfevres", "kind": "rue", "oneway": -1, "pts": [Vector2(843, 560), Vector2(875, 566), Vector2(903, 562)] },
	{ "id": "puits", "kind": "rue", "oneway": 1, "narrow": [1.0, 1.0, 1.0, 1.0, 0.8, 1.0, 1.0, 1.0, 1.0],
		"pts": [Vector2(846, 592), Vector2(880, 596), Vector2(925, 604), Vector2(970, 602), Vector2(1002, 604),
		Vector2(1040, 600), Vector2(1080, 598), Vector2(1130, 602), Vector2(1205, 606)] },
	{ "id": "sainte_croix", "kind": "rue", "oneway": -1, "pts": [Vector2(862, 640), Vector2(905, 640), Vector2(950, 645), Vector2(1000, 630)] },
	# ...and north to south.
	{ "id": "marche_rue", "kind": "rue", "oneway": -1, "pts": [Vector2(1090, 298), Vector2(1080, 342), Vector2(1073, 390),
		Vector2(1068, 440), Vector2(1080, 485)] },
	{ "id": "saint_martin", "kind": "grande_rue", "narrow": [1.0, 1.0, 0.8, 1.0, 1.0, 1.0, 1.0, 0.85, 1.0, 1.0],
		"pts": [Vector2(905, 298), Vector2(902, 352), Vector2(897, 400), Vector2(893, 424), Vector2(895, 478),
		Vector2(889, 522), Vector2(903, 562), Vector2(925, 604), Vector2(950, 645), Vector2(960, 668)] },
	{ "id": "harpe", "kind": "rue", "oneway": 1, "narrow": [1.0, 1.0, 0.75, 0.75, 1.0, 1.0, 1.0, 1.0, 1.0],
		"pts": [Vector2(968, 290), Vector2(976, 330), Vector2(984, 378), Vector2(990, 433), Vector2(995, 481),
		Vector2(1000, 528), Vector2(1003, 578), Vector2(1000, 630), Vector2(1004, 672)] },
	{ "id": "carmes", "kind": "rue", "oneway": -1, "pts": [Vector2(850, 312), Vector2(846, 360), Vector2(842, 420),
		Vector2(838, 470), Vector2(843, 530), Vector2(846, 592), Vector2(862, 640)] },
	{ "id": "ursulines", "kind": "rue", "oneway": 1, "pts": [Vector2(1066, 526), Vector2(1072, 560), Vector2(1080, 598),
		Vector2(1082, 630), Vector2(1078, 664)] },
	{ "id": "tanneurs", "kind": "rue", "walk": [1.0, 0.0], "oneway": 1, "pts": [Vector2(1118, 295), Vector2(1116, 340),
		Vector2(1112, 390), Vector2(1110, 438)] },
	# Lanes, passages under the houses and blind alleys.
	{ "id": "lanternes", "kind": "passage", "pts": [Vector2(948, 476), Vector2(946, 452), Vector2(944, 431)] },
	{ "id": "cheval_blanc", "kind": "passage", "pts": [Vector2(1048, 347), Vector2(1047, 392), Vector2(1046, 439)] },
	{ "id": "arbalete", "kind": "ruelle", "pts": [Vector2(1010, 435), Vector2(1020, 460), Vector2(1040, 483)] },
	{ "id": "chat", "kind": "ruelle", "pts": [Vector2(950, 349), Vector2(945, 375), Vector2(952, 400), Vector2(958, 431)] },
	{ "id": "moines", "kind": "ruelle", "pts": [Vector2(1030, 296), Vector2(1027, 322), Vector2(1024, 350)] },
	{ "id": "teinturiers", "kind": "ruelle", "pts": [Vector2(1094, 528), Vector2(1102, 555), Vector2(1110, 575), Vector2(1130, 602)] },
	{ "id": "cordeliers", "kind": "impasse", "pts": [Vector2(840, 445), Vector2(868, 447)] },
	{ "id": "four", "kind": "impasse", "pts": [Vector2(987, 405), Vector2(962, 404)] },
	{ "id": "sainte_anne", "kind": "impasse", "pts": [Vector2(1040, 600), Vector2(1045, 630)] },
	{ "id": "cygne", "kind": "impasse", "pts": [Vector2(897, 400), Vector2(870, 392)] },
	# The faubourgs west and south-west, outside the walls.
	{ "id": "croix_blanche", "kind": "route", "pts": [Vector2(772, 462), Vector2(735, 453), Vector2(692, 432),
		Vector2(660, 410), Vector2(620, 388)] },
	{ "id": "cordiers", "kind": "rue", "pts": [Vector2(692, 432), Vector2(662, 470), Vector2(642, 520), Vector2(634, 580),
		Vector2(640, 660), Vector2(650, 720), Vector2(655, 751)] },
	{ "id": "jardins", "kind": "rue", "pts": [Vector2(776, 510), Vector2(735, 515), Vector2(690, 522), Vector2(642, 520),
		Vector2(600, 540), Vector2(565, 556)] },
	{ "id": "lavandieres", "kind": "rue", "pts": [Vector2(640, 660), Vector2(690, 668), Vector2(735, 648)] },
	{ "id": "vignes", "kind": "chemin", "pts": [Vector2(634, 580), Vector2(590, 600), Vector2(540, 640)] },
	{ "id": "faubourg", "kind": "faubourg", "pts": [Vector2(790, 560), Vector2(762, 604), Vector2(735, 648),
		Vector2(708, 700), Vector2(686, 742), Vector2(630, 762), Vector2(570, 782), Vector2(495, 812)] },
	{ "id": "champ_de_mars", "kind": "rue", "pts": [Vector2(862, 640), Vector2(830, 680), Vector2(795, 725),
		Vector2(770, 770), Vector2(760, 820), Vector2(790, 870), Vector2(830, 900), Vector2(860, 930)] },
	{ "id": "moulins", "kind": "rue", "pts": [Vector2(925, 664), Vector2(900, 705), Vector2(860, 745), Vector2(815, 768),
		Vector2(770, 770)] },
	{ "id": "val", "kind": "route", "pts": [Vector2(1000, 673), Vector2(996, 720), Vector2(990, 770), Vector2(983, 830)] },
	{ "id": "fosses", "kind": "rue", "pts": [Vector2(996, 720), Vector2(1050, 710), Vector2(1100, 692), Vector2(1140, 646)] },
	{ "id": "poudriere", "kind": "chemin", "pts": [Vector2(570, 782), Vector2(548, 830), Vector2(560, 880),
		Vector2(600, 920), Vector2(660, 955), Vector2(705, 985)] },
]


## A street's kind with its own overrides: road, walk [left, right], mall, surface, oneway, covered.
static func spec(street: Dictionary) -> Dictionary:
	var out: Dictionary = (KINDS[street.kind] as Dictionary).duplicate(true)
	for k in ["road", "walk", "mall", "surface", "oneway", "covered"]:
		if street.has(k):
			out[k] = street[k]
	out.walk = [float(out.walk[0]), float(out.walk[1])]
	out.road = float(out.road)
	out.mall = float(out.get("mall", 0.0))
	out.covered = bool(out.get("covered", false))
	return out


## Wall to wall in metres: carriageway (at its widest) and both pavements.
static func width(street: Dictionary) -> float:
	var sp := spec(street)
	var most := 1.0
	for f: float in street.get("narrow", [1.0]):
		most = maxf(most, f)
	return sp.road * most + sp.walk[0] + sp.walk[1]


static func street(id: String) -> Dictionary:
	for s: Dictionary in STREETS:
		if s.id == id:
			return s
	return {}


static func square(id: String) -> Dictionary:
	for s: Dictionary in SQUARES:
		if s.id == id:
			return s
	return {}


static func to_world(px: Vector2) -> Vector3:
	var p := (px - ORIGIN_PX) * M_PER_PX
	return Vector3(p.x, 0.0, p.y)


## Same as to_world, as (x, z) for flat geometry.
static func to_plan(px: Vector2) -> Vector2:
	return (px - ORIGIN_PX) * M_PER_PX


static func to_px(world: Vector3) -> Vector2:
	return Vector2(world.x, world.z) / M_PER_PX + ORIGIN_PX
