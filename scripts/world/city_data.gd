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

const AVENUE := 16.0 ## street widths in metres, kerb to kerb plus sidewalks
const STREET := 12.0
const LANE := 8.0
const RIVER_WIDTH := 26.0

## The five mission places. `at` is where a player stands, `lot` its grounds (cleared of city
## buildings) and `gate` a point on the nearest street that the lot is joined to.
const POIS := {
	"hospital": { "name": "HOSPITAL DONA HELENA", "at": Vector2(742, 405), "gate": Vector2(763, 405),
		"lot": [Vector2(722, 371), Vector2(762, 371), Vector2(762, 439), Vector2(722, 439)] },
	"terminal": { "name": "TERMINAL CENTRAL", "at": Vector2(1035, 504), "gate": Vector2(1035, 527),
		"lot": [Vector2(1013, 488), Vector2(1057, 488), Vector2(1057, 520), Vector2(1013, 520)] },
	"prefeitura": { "name": "PREFEITURA DE JOINVILLE", "at": Vector2(1200, 215), "gate": Vector2(1164, 215),
		"lot": [Vector2(1174, 195), Vector2(1226, 195), Vector2(1226, 235), Vector2(1174, 235)] },
	"batalhao": { "name": "62º BATALHÃO DE INFANTARIA", "at": Vector2(665, 840), "gate": Vector2(700, 786),
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
	Vector2(1620, 60), Vector2(1640, -130), Vector2(2100, -130), Vector2(2100, 420), Vector2(1620, 440),
	Vector2(1480, 600), Vector2(1340, 720), Vector2(1260, 600), Vector2(1215, 520), Vector2(1200, 420)]

## Open green ground: the immigrants' cemetery and the squares.
const PARKS := [
	[Vector2(668, 352), Vector2(735, 352), Vector2(735, 420), Vector2(690, 420), Vector2(668, 395)],
	[Vector2(930, 545), Vector2(995, 545), Vector2(995, 600), Vector2(945, 600)],
	[Vector2(1068, 490), Vector2(1148, 495), Vector2(1160, 528), Vector2(1068, 522)],
]

## [name, width, points...]. Only what lies inside the map's edge is built.
const STREETS := [
	# West to east
	["Rua Max Colin", AVENUE, Vector2(660, 150), Vector2(775, 165), Vector2(885, 172), Vector2(985, 182), Vector2(1105, 190), Vector2(1135, 203), Vector2(1166, 207)],
	["Rua Marechal Deodoro", STREET, Vector2(660, 215), Vector2(770, 222), Vector2(895, 232)],
	["Rua Tijucas", STREET, Vector2(770, 226), Vector2(900, 240), Vector2(985, 245), Vector2(1105, 250)],
	["Rua Lages", STREET, Vector2(600, 262), Vector2(660, 265), Vector2(770, 272), Vector2(900, 283), Vector2(985, 290), Vector2(1087, 293)],
	["Rua Luiz Brockmann", STREET, Vector2(658, 310), Vector2(766, 318)],
	["Rua dos Ginásticos", STREET, Vector2(766, 349), Vector2(896, 357), Vector2(1076, 343)],
	["Rua Mário Lobo", STREET, Vector2(762, 412), Vector2(895, 422), Vector2(1066, 435), Vector2(1141, 440), Vector2(1167, 440)],
	["Rua XV de Novembro", AVENUE, Vector2(470, 368), Vector2(620, 380), Vector2(690, 420), Vector2(760, 468), Vector2(895, 475),
		Vector2(1063, 480), Vector2(1148, 487), Vector2(1186, 502)],
	["Rua Otto Boehm", STREET, Vector2(440, 600), Vector2(540, 570), Vector2(622, 535), Vector2(690, 518), Vector2(758, 512)],
	["Rua Nove de Março", AVENUE, Vector2(758, 512), Vector2(885, 520), Vector2(1040, 528), Vector2(1160, 540), Vector2(1206, 546)],
	["Rua Jerônimo Coelho", STREET, Vector2(1000, 582), Vector2(1084, 588), Vector2(1160, 595), Vector2(1208, 600)],
	["Rua Pedro Lobo leste", STREET, Vector2(885, 632), Vector2(1000, 640), Vector2(1082, 646), Vector2(1160, 648)],
	["Rua Abdon Batista", STREET, Vector2(1010, 740), Vector2(1160, 741), Vector2(1215, 742)],
	["Rua Ministro Calógeras", AVENUE, Vector2(660, 960), Vector2(740, 915), Vector2(800, 872), Vector2(900, 832), Vector2(990, 828), Vector2(1210, 835)],
	["Rua Campo Alegre", STREET, Vector2(560, 500), Vector2(622, 470), Vector2(690, 452), Vector2(745, 458)],
	# North to south
	["Rua Conselheiro Arp", STREET, Vector2(660, 150), Vector2(658, 265), Vector2(655, 340), Vector2(645, 385)],
	["Rua Expedicionário Holz", STREET, Vector2(645, 385), Vector2(626, 420), Vector2(620, 470), Vector2(622, 560), Vector2(630, 680), Vector2(650, 750)],
	["Rua Blumenau", AVENUE, Vector2(778, 100), Vector2(775, 165), Vector2(770, 290), Vector2(762, 420), Vector2(760, 468), Vector2(758, 512)],
	["Rua Henrique Meyer", STREET, Vector2(758, 512), Vector2(752, 560), Vector2(748, 600), Vector2(765, 632)],
	["Rua Doutor João Colin", AVENUE, Vector2(882, 100), Vector2(885, 172), Vector2(898, 300), Vector2(895, 420), Vector2(888, 515)],
	["Avenida Juscelino Kubitschek", AVENUE, Vector2(888, 515), Vector2(900, 560), Vector2(940, 620), Vector2(965, 700), Vector2(990, 830), Vector2(995, 960)],
	["Rua Orestes Guimarães", STREET, Vector2(985, 100), Vector2(985, 182), Vector2(985, 290), Vector2(990, 345), Vector2(1005, 440)],
	["Rua do Príncipe", STREET, Vector2(1005, 440), Vector2(1003, 520), Vector2(1000, 640), Vector2(1010, 740), Vector2(1030, 830)],
	["Rua Dona Francisca", STREET, Vector2(1105, 250), Vector2(1087, 293), Vector2(1076, 343), Vector2(1066, 435), Vector2(1063, 480), Vector2(1062, 528)],
	["Rua Rio Branco", STREET, Vector2(1084, 530), Vector2(1084, 588), Vector2(1082, 646)],
	["Rua Itajaí", STREET, Vector2(1160, 540), Vector2(1160, 648), Vector2(1160, 741)],
	["Avenida José Vieira", AVENUE, Vector2(1106, -20), Vector2(1110, 150), Vector2(1135, 203), Vector2(1139, 260), Vector2(1139, 430), Vector2(1148, 487), Vector2(1160, 540)],
	["Avenida Hermann August Lepper", AVENUE, Vector2(1146, 60), Vector2(1150, 150), Vector2(1166, 207), Vector2(1169, 262), Vector2(1168, 330),
		Vector2(1167, 440), Vector2(1186, 502), Vector2(1206, 546), Vector2(1208, 600), Vector2(1212, 648), Vector2(1215, 742), Vector2(1212, 835)],
	["Rua Saguaçu", STREET, Vector2(1166, 207), Vector2(1226, 185), Vector2(1280, 175), Vector2(1330, 165)],
	# The diagonals south-west of the centre, toward the barracks
	["Rua Pedro Lobo", STREET, Vector2(835, 572), Vector2(885, 632), Vector2(940, 620)],
	["Rua Visconde de Taunay", STREET, Vector2(888, 515), Vector2(835, 572), Vector2(765, 632), Vector2(740, 655), Vector2(650, 750)],
	["Rua Senador Felipe Schmidt", STREET, Vector2(885, 632), Vector2(800, 720), Vector2(735, 786)],
	["Rua Jaguaruna", STREET, Vector2(950, 660), Vector2(905, 690), Vector2(850, 745), Vector2(775, 815)],
	["Rua Duque de Caxias", AVENUE, Vector2(650, 750), Vector2(720, 800), Vector2(790, 875), Vector2(800, 872)],
	["Rua Jacob Eisenhuth", STREET, Vector2(650, 750), Vector2(600, 742), Vector2(560, 720), Vector2(522, 770)],
	["Rua General Valgas Neves", STREET, Vector2(522, 770), Vector2(545, 850), Vector2(580, 895), Vector2(660, 960)],
	# Up the hill
	["Rua Otto Eduardo Lepper", LANE, Vector2(1169, 262), Vector2(1230, 285), Vector2(1290, 315), Vector2(1380, 272), Vector2(1480, 265), Vector2(1560, 290), Vector2(1600, 285)],
	# Traced on joinville_topography.png (pixel + TOPO_OFFSET_PX): two S-bends up the west slope, a
	# hairpin north of the summit, then back south-east onto the top. Negative y is above joinville.png.
	["Rua Pastor Guilherme Rau", LANE, Vector2(1600, 285), Vector2(1628, 302), Vector2(1648, 283), Vector2(1665, 253),
		Vector2(1678, 218), Vector2(1680, 188), Vector2(1698, 168), Vector2(1700, 148), Vector2(1688, 118), Vector2(1688, 88),
		Vector2(1668, 53), Vector2(1668, 33), Vector2(1683, 15), Vector2(1708, 10), Vector2(1733, -2), Vector2(1773, -37),
		Vector2(1798, -77), Vector2(1808, -92), Vector2(1818, -87), Vector2(1825, -57), Vector2(1818, -27), Vector2(1813, 8),
		Vector2(1823, 33), Vector2(1848, 43), Vector2(1866, 45)],
]


static func to_world(px: Vector2) -> Vector3:
	var p := (px - ORIGIN_PX) * M_PER_PX
	return Vector3(p.x, 0.0, p.y)


## Same as to_world, as (x, z) for flat geometry.
static func to_plan(px: Vector2) -> Vector2:
	return (px - ORIGIN_PX) * M_PER_PX


static func to_px(world: Vector3) -> Vector2:
	return Vector2(world.x, world.z) / M_PER_PX + ORIGIN_PX
