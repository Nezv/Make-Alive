class_name CityData
## Joinville as data, in pixels of references/joinville.png: the POIs, river, hill and squares by hand,
## the streets traced by tools/trace_streets.py (CityStreets).
##
## Every coordinate here is a pixel of that picture (x right, y down, north is up). `to_world`
## turns a pixel into metres: the bus terminal is the origin, east is +X and north is -Z.
## CityMap builds all of it, out to FRAME.

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
	"hospital": { "name": "HOSPITAL DONA HELENA", "at": Vector2(742, 405), "gate": Vector2(763, 405),
		"lot": [Vector2(722, 371), Vector2(762, 371), Vector2(762, 439), Vector2(722, 439)] },
	"terminal": { "name": "TERMINAL CENTRAL", "at": Vector2(1035, 504), "gate": Vector2(1035, 528),
		"lot": [Vector2(1013, 488), Vector2(1057, 488), Vector2(1057, 520), Vector2(1013, 520)] },
	"prefeitura": { "name": "PREFEITURA DE JOINVILLE", "at": Vector2(1200, 215), "gate": Vector2(1159, 214),
		"lot": [Vector2(1174, 195), Vector2(1226, 195), Vector2(1226, 235), Vector2(1174, 235)] },
	# The compound faces rue Jules-Ferry (north-east); its gate is on the street opposite the way
	# through the front block, `at` the middle of the parade ground (BatalhaoSet's frame).
	"batalhao": { "name": "62º BATALHÃO DE INFANTARIA", "at": Vector2(699.0, 840.4), "gate": Vector2(730.9, 810.6),
		"lot": [Vector2(568, 842), Vector2(578, 795), Vector2(640, 765), Vector2(692.9, 773.1), Vector2(764.2, 849.6),
			Vector2(775, 880), Vector2(745, 900), Vector2(688.3, 920.3), Vector2(620, 892)] },
	# On the 230 m summit of Morro da Boa Vista, where the road ends. joinville.png shows only the tip
	# of the hill under its zoom buttons; this and the road up come from joinville_topography.png.
	"mirante": { "name": "MIRANTE DE JOINVILLE", "at": Vector2(1866, 45), "gate": Vector2(1848, 43),
		"lot": [Vector2(1880, 45), Vector2(1876, 55), Vector2(1866, 59), Vector2(1856, 55), Vector2(1852, 45),
			Vector2(1856, 35), Vector2(1866, 31), Vector2(1876, 35)] },
}

## The map: all of joinville.png, and above it as far as the hairpin of the road up to the Mirante,
## which swings north of the summit with room round it for the hill (joinville_topography.png gives
## the ground there; the menu's picture starts at the same row).
const FRAME := Rect2(0, -180, 1920, 1200)

## Rio Cachoeira, north to south.
const RIVER := [Vector2(1128, -90), Vector2(1130, 150), Vector2(1150, 220), Vector2(1154, 330), Vector2(1153, 440),
	Vector2(1168, 500), Vector2(1195, 560), Vector2(1232, 640), Vector2(1300, 740), Vector2(1380, 805), Vector2(1430, 865), Vector2(1462, 940),
	Vector2(1490, 1030)]

## Morro da Boa Vista: forest, crossed only by the road up to the Mirante.
const FOREST := [Vector2(1205, 265), Vector2(1290, 215), Vector2(1400, 200), Vector2(1410, 130), Vector2(1560, 110),
	Vector2(1620, 60), Vector2(1625, -330), Vector2(2110, -330), Vector2(2100, 420), Vector2(1620, 440),
	Vector2(1480, 600), Vector2(1340, 720), Vector2(1260, 600), Vector2(1215, 520), Vector2(1200, 420)]

## Open green ground: the old cemetery by the Hôtel-Dieu.
const PARKS := [
	[Vector2(668, 352), Vector2(735, 352), Vector2(735, 420), Vector2(690, 420), Vector2(668, 395)],
]

# --- The town's plan (S040) -----------------------------------------------------------------------
# Joinville's own streets, traced off joinville.png (CityStreets): the main ones where its bus routes
# run, every other street of the picture as a rue, all under invented French names; the road up the
# hill by hand off joinville_topography.png. The look is a French town's (setts, pavements, pans coupés).

const DRIVE := 8.0          ## metres: the way from a POI's gate to its door
const NAV_MIN_WIDTH := 6.0  ## metres: no street is narrower than this on the 4 m navigation grid

## Street surfaces (pavements are always `flags`).
const SURFACES := ["setts", "asphalt", "flags"]

## What each kind of street is, in metres: `road` the carriageway kerb to kerb, `walk` the pavement
## [left, right] looking along the street's points, `oneway` 1 along the points, -1 against, 0 both
## ways, `covered` for a passage through a block under the houses. A street may override any of them.
const KINDS := {
	"principale": { "road": 9.0, "walk": [2.5, 2.5], "surface": "asphalt", "oneway": 0 },
	"rue": { "road": 5.5, "walk": [1.5, 1.5], "surface": "setts", "oneway": 0 },
	"chemin": { "road": 6.0, "walk": [0.0, 0.0], "surface": "asphalt", "oneway": 0 },
}

## The names given by hand (the traced streets carry theirs in CityStreets.NAMES).
const HAND_NAMES := {
	"telegraphe": "chemin du Télégraphe",
	"marche": "place du Marché",
	"eglise": "place de l'Église",
}

## Paved squares, open ground.
const SQUARES := [
	{ "id": "marche", "pts": [Vector2(1068, 486), Vector2(1095, 482), Vector2(1121, 488), Vector2(1123, 520),
		Vector2(1094, 527), Vector2(1066, 525)] },
	{ "id": "eglise", "pts": [Vector2(893, 528), Vector2(985, 530), Vector2(992, 597), Vector2(930, 601), Vector2(906, 570)] },
]

## Streets drawn by hand, each `{ id, kind, pts }` in pixels of joinville.png, with optional overrides
## of its kind (`road`, `walk`, `oneway`, `surface`, `covered`) and `narrow`: a factor on the
## carriageway per point, where the street pinches or opens out. Streets meet where an end lies on
## another street (within a few metres) or where two cross; StreetNet finds the junctions.
const HAND_STREETS := [
	# Traced on joinville_topography.png (pixel + TOPO_OFFSET_PX): two S-bends up the west slope, a
	# hairpin north of the summit, then back south-east onto the top. Negative y is above joinville.png.
	# It starts where the road along the south of the Rio do Engenho park ends.
	{ "id": "telegraphe", "kind": "chemin", "walk": [1.0, 1.0], "pts": [Vector2(1329.2, 167.4), Vector2(1385, 187), Vector2(1430, 198), Vector2(1470, 212),
		Vector2(1500, 207), Vector2(1520, 212), Vector2(1535, 235), Vector2(1560, 255), Vector2(1590, 280), Vector2(1615, 297),
		Vector2(1630, 300), Vector2(1648, 283), Vector2(1665, 253),
		Vector2(1678, 218), Vector2(1680, 188), Vector2(1698, 168), Vector2(1700, 148), Vector2(1688, 118), Vector2(1688, 88),
		Vector2(1668, 53), Vector2(1668, 33), Vector2(1683, 15), Vector2(1708, 10), Vector2(1733, -2), Vector2(1773, -37),
		Vector2(1798, -77), Vector2(1808, -92), Vector2(1818, -87), Vector2(1825, -57), Vector2(1818, -27), Vector2(1813, 8),
		Vector2(1823, 33), Vector2(1848, 43), Vector2(1866, 45)] },
]

## Every street of the plan: the traced ones, less those that lie mostly inside a POI's grounds (its
## driveways and car parks: the POI builds its own) or along a hand-drawn street (the top of the hill
## road, which joinville.png shows too), and the hand-drawn ones.
static var STREETS: Array = _plan_streets()


static func _plan_streets() -> Array:
	var out := []
	for s: Dictionary in CityStreets.STREETS:
		if not _mostly_in_a_lot(s.pts) and not _along_a_hand_street(s.pts):
			out.append(s)
	out.append_array(HAND_STREETS)
	return out


static func _along_a_hand_street(pts: Array) -> bool:
	var near := 0
	var total := 0
	for i in pts.size() - 1:
		for j in 8:
			var p: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], j / 8.0)
			total += 1
			for h: Dictionary in HAND_STREETS:
				var q: Array = h.pts
				var hit := false
				for k in q.size() - 1:
					if Geometry2D.get_closest_point_to_segment(p, q[k], q[k + 1]).distance_to(p) < 8.0:
						hit = true
						break
				if hit:
					near += 1
					break
	return near * 2 > total


static func _mostly_in_a_lot(pts: Array) -> bool:
	var inside := 0
	var total := 0
	for i in pts.size() - 1:
		for j in 8:
			var p: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], j / 8.0)
			total += 1
			for id: String in POIS:
				if Geometry2D.is_point_in_polygon(p, PackedVector2Array(POIS[id].lot)):
					inside += 1
					break
	return inside * 2 > total


## The name of a street or square.
static func name_of(id: String) -> String:
	return HAND_NAMES.get(id, CityStreets.NAMES.get(id, ""))


## A street's kind with its own overrides: road, walk [left, right], surface, oneway, covered.
static func spec(street: Dictionary) -> Dictionary:
	var out: Dictionary = (KINDS[street.kind] as Dictionary).duplicate(true)
	for k in ["road", "walk", "surface", "oneway", "covered"]:
		if street.has(k):
			out[k] = street[k]
	out.walk = [float(out.walk[0]), float(out.walk[1])]
	out.road = float(out.road)
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
