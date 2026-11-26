class_name RoomDressing
extends RefCounted
## What a room of a HousePlan is dressed in (S244), no nodes: its paint, its lamps and switches,
## and where its furniture stands. Furniture is slots only (an item's name, footprint, height and
## the way it faces), standing in for the elements S193 will make: the proportions are real
## (a double bed 1.4 x 2.0, a kitchen range 0.9 x 0.65...), the look is not.
##
## Paint: every flat of a floor shares a scheme (how worn it is, its parquet and tomettes, a hue
## it leans to); every room picks its walls from its kind's palette (Directoire greys, greens and
## ochres in the salons, lime wash in the kitchens, an oil-painted dado in the corridors, faience in
## the WCs), varied a little. Lamps: a ceiling rose's pendant in a room (two in a long or large
## one, over the table if there is one), flush lamps every Config.INTERIOR_LIGHT_STEP along a
## corridor, a grid in a shop, sconces beside a salon's fireplace; a switch by each room's door on
## the latch side. Furniture: each kind's list (KITS), placed one item at a time against a wall,
## beside or in front of another item, on a flue (a fireplace, a range) or free in the room; never
## in a door's leaf or way in, nothing tall before a window; and after each item the player must
## still walk between every door of the room and up to a window (`check`, on a grid of
## Config.INTERIOR_GRID: gaps of 2 x Config.INTERIOR_PASS).

const EPS := 0.005
const DOOR_CLEAR := 0.65   ## m kept free inside a door the leaf does not swing into
const WINDOW_CLEAR := { "french": 0.65, "casement": 0.45, "shop": 0.5, "stair": 0.0 }

const LIVING_WALLS := [Color("a9b4a4"), Color("b8ab84"), Color("aab4b9"), Color("c4aa9c"), Color("cfc6ad"), Color("98a397"), Color("b9b294")]
const BED_WALLS := [Color("c8bfa6"), Color("b9b39a"), Color("a7b2a6"), Color("c9b1a3"), Color("b5b8c0"), Color("d1c7ad"), Color("bba98c")]
const PAPER := [Color("8d6e5a"), Color("6f7d6a"), Color("7d6f86"), Color("8a7b52"), Color("5f7380")]
const LIME_WALLS := [Color("d8d2bd"), Color("cfd0c4"), Color("c9c6b0"), Color("d3cbb4"), Color("c6bfa9")]
const OIL_LOWER := [Color("6f7f6a"), Color("7a6a55"), Color("5f6b73"), Color("8a7a5c"), Color("6b5c50")]
const TILE_LOWER := [Color("e6e3d8"), Color("b9c7c9"), Color("d9d3c0"), Color("aebfb3")]
const HALL_WALLS := [Color("c4b898"), Color("b7ae94"), Color("a9a08a"), Color("bdb5a0")]
const HALL_LOWER := [Color("6b5a48"), Color("5a4d40"), Color("4f5a52"), Color("74604c")]
const STAIR_WALLS := [Color("bfb39a"), Color("b0a68f"), Color("c3b8a3")]
const STAIR_LOWER := [Color("7b6a55"), Color("6a5f52"), Color("85776a")]
const SHOP_WALLS := [Color("d0c7ae"), Color("b8b09a"), Color("a89f8b")]
const SHOP_LOWER := [Color("5b4433"), Color("3f4a3c"), Color("4a3a30")]
const CEILINGS := [Color("e6e1d3"), Color("dcd6c6"), Color("d9d2bf"), Color("e0dacb")]
const FLOORS := {
	"parquet": [Color("8a5f3c"), Color("7a5434"), Color("9a6a43"), Color("6e4a2e")],
	"tomettes": [Color("9b4f34"), Color("a5583a"), Color("8e4730"), Color("94553c")],
	"carreaux": [Color("b8b0a0"), Color("8f8a80"), Color("a39a88")],
	"dalles": [Color("8f877a"), Color("9a9284"), Color("857e72")],
	"planches": [Color("7d6650"), Color("6f5a46"), Color("85705a")],
}
## What each kind is painted with: walls, a lower band (dado) and its height, the floor, and how
## likely panelling, wallpaper or a cornice are.
const PAINT := {
	"living": { "walls": LIVING_WALLS, "floor": "parquet", "panels": 0.5, "cornice": 0.8 },
	"bed": { "walls": BED_WALLS, "floor": "parquet", "paper": 0.5, "cornice": 0.4 },
	"kitchen": { "walls": LIME_WALLS, "lower": OIL_LOWER, "lower_h": [1.2, 1.45], "floor": "tomettes" },
	"wet": { "walls": LIME_WALLS, "lower": TILE_LOWER, "lower_h": [1.35, 1.6], "floor": "carreaux" },
	"hall": { "walls": HALL_WALLS, "lower": HALL_LOWER, "lower_h": [0.95, 1.1], "floor": "tomettes" },
	"stair": { "walls": STAIR_WALLS, "lower": STAIR_LOWER, "lower_h": [1.0, 1.15], "floor": "dalles" },
	"shop": { "walls": SHOP_WALLS, "lower": SHOP_LOWER, "lower_h": [0.9, 1.05], "floor": "carreaux" },
	"store": { "walls": LIME_WALLS, "floor": "dalles" },
}
const PAINT_OF := { "salon": "living", "salle_a_manger": "living", "chambre": "bed", "cabinet": "bed", "loge": "bed",
	"cuisine": "kitchen", "wc": "wet", "salle_d_eau": "wet", "corridor": "hall", "entree": "hall",
	"allee": "stair", "stair": "stair", "boutique": "shop", "arriere_boutique": "store", "reserve": "store",
	"remise": "store", "atelier": "store", "debarras": "store" }

## Furniture per kind of room, placed in this order. size [along the wall, height, out from it] (m);
## at: wall / beside (an item: flush on its wall, either side) / front (of an item) / flue / centre;
## pref: middle / corner / far (from the door) / window (under a low window) / long (the longest
## wall); pad [left, right, front] kept free round a wall item (a number round a free one), pad_in:
## the pad must lie in the room; need: the room is not done without it; alt: smaller sizes to try.
const FIREPLACE := { "item": "cheminee", "at": "flue", "size": [1.4, 1.1, 0.45], "pad": [0.0, 0.0, 0.55] }
const KITS := {
	"salon": [FIREPLACE,
		{ "item": "canape", "at": "wall", "pref": "middle", "size": [2.0, 0.85, 0.9], "pad": [0.1, 0.1, 0.95], "need": true, "alt": [[1.6, 0.85, 0.85], [1.3, 0.85, 0.8]] },
		{ "item": "table_basse", "at": "front", "of": "canape", "size": [1.0, 0.45, 0.55], "gap": 0.35 },
		{ "item": "fauteuil", "at": "wall", "pref": "corner", "size": [0.8, 0.9, 0.8], "pad": [0.05, 0.05, 0.5], "count": [1, 2] },
		{ "item": "bibliotheque", "at": "wall", "pref": "corner", "size": [1.0, 2.0, 0.38], "pad": [0.0, 0.0, 0.6], "chance": 0.7 },
		{ "item": "buffet", "at": "wall", "pref": "long", "size": [1.5, 0.95, 0.5], "pad": [0.0, 0.0, 0.6], "chance": 0.5 },
		{ "item": "piano", "at": "wall", "size": [1.5, 1.3, 0.6], "pad": [0.0, 0.0, 0.7], "chance": 0.15, "min_area": 16.0 }],
	"salle_a_manger": [FIREPLACE,
		{ "item": "table", "at": "centre", "size": [1.6, 0.75, 0.9], "pad": 0.65, "need": true, "alt": [[1.2, 0.75, 0.8], [0.9, 0.75, 0.9]] },
		{ "item": "buffet", "at": "wall", "pref": "long", "size": [1.6, 0.95, 0.5], "pad": [0.0, 0.0, 0.6] },
		{ "item": "vaisselier", "at": "wall", "size": [1.2, 2.1, 0.45], "pad": [0.0, 0.0, 0.6], "chance": 0.5 }],
	"chambre": [FIREPLACE,
		{ "item": "lit", "at": "wall", "pref": "middle", "size": [1.4, 0.6, 2.0], "pad": [0.5, 0.5, 0.5], "pad_in": true, "need": true,
			"alt": [[1.2, 0.6, 1.95], { "size": [0.9, 0.6, 1.9], "pad": [0.0, 0.5, 0.45], "pref": "corner" }, { "size": [0.9, 0.6, 1.9], "pad": [0.5, 0.0, 0.45], "pref": "corner" }] },
		{ "item": "chevet", "at": "beside", "of": "lit", "size": [0.45, 0.6, 0.4], "count": [1, 2] },
		{ "item": "armoire", "at": "wall", "pref": "corner", "size": [1.2, 2.1, 0.6], "pad": [0.0, 0.0, 0.7], "chance": 0.9, "alt": [[0.9, 2.0, 0.55]] },
		{ "item": "commode", "at": "wall", "pref": "long", "size": [1.0, 0.85, 0.5], "pad": [0.0, 0.0, 0.6], "chance": 0.6 },
		{ "item": "chaise", "at": "wall", "pref": "corner", "size": [0.45, 0.9, 0.45], "pad": [0.0, 0.0, 0.3], "chance": 0.5 }],
	"cabinet": [FIREPLACE,
		{ "item": "bureau", "at": "wall", "pref": "window", "size": [1.2, 0.75, 0.6], "pad": [0.0, 0.0, 0.75], "need": true, "alt": [[0.9, 0.75, 0.55]] },
		{ "item": "bibliotheque", "at": "wall", "pref": "corner", "size": [1.0, 2.0, 0.35], "pad": [0.0, 0.0, 0.6], "count": [1, 2] },
		{ "item": "fauteuil", "at": "wall", "pref": "corner", "size": [0.8, 0.9, 0.8], "pad": [0.05, 0.05, 0.5], "chance": 0.5 }],
	"loge": [FIREPLACE,
		{ "item": "lit", "at": "wall", "pref": "corner", "size": [0.9, 0.6, 1.9], "pad": [0.0, 0.5, 0.4], "need": true },
		{ "item": "table", "at": "centre", "size": [0.8, 0.75, 0.6], "pad": 0.5, "chance": 0.8 },
		{ "item": "armoire", "at": "wall", "pref": "corner", "size": [1.0, 2.0, 0.55], "pad": [0.0, 0.0, 0.7], "chance": 0.7 }],
	"cuisine": [
		{ "item": "cuisiniere", "at": "flue", "or": "wall", "pref": "corner", "size": [0.9, 0.85, 0.65], "pad": [0.0, 0.0, 0.8], "need": true, "alt": [[0.7, 0.85, 0.6]] },
		{ "item": "evier", "at": "wall", "pref": "window", "size": [1.0, 0.88, 0.6], "pad": [0.0, 0.0, 0.7], "need": true, "alt": [[0.7, 0.88, 0.5]] },
		{ "item": "plan", "at": "beside", "of": "evier", "size": [0.9, 0.88, 0.6], "count": [1, 2] },
		{ "item": "buffet", "at": "wall", "pref": "corner", "size": [1.0, 2.0, 0.5], "pad": [0.0, 0.0, 0.7], "chance": 0.8 },
		{ "item": "table", "at": "centre", "size": [1.0, 0.75, 0.7], "pad": 0.55, "chance": 0.85, "min_area": 8.0 }],
	"wc": [
		{ "item": "cuvette", "at": "wall", "pref": "far", "size": [0.4, 0.8, 0.7], "pad": [0.2, 0.2, 0.35], "need": true },
		{ "item": "lave_mains", "at": "wall", "size": [0.4, 0.85, 0.3], "pad": [0.0, 0.0, 0.4], "chance": 0.5 }],
	"salle_d_eau": [
		{ "item": "baignoire", "at": "wall", "pref": "corner", "size": [1.6, 0.6, 0.7], "pad": [0.0, 0.0, 0.5], "chance": 0.8, "alt": [[0.8, 2.0, 0.8]] },
		{ "item": "lavabo", "at": "wall", "pref": "middle", "size": [0.6, 0.85, 0.45], "pad": [0.0, 0.0, 0.55], "need": true, "alt": [[0.45, 0.85, 0.35]] },
		{ "item": "cuvette", "at": "wall", "pref": "far", "size": [0.4, 0.8, 0.7], "pad": [0.2, 0.2, 0.35], "chance": 0.5 }],
	"debarras": [
		{ "item": "etagere", "at": "wall", "pref": "corner", "size": [0.9, 2.0, 0.4], "pad": [0.0, 0.0, 0.5], "count": [1, 3] }],
	"boutique": [
		{ "item": "comptoir", "at": "centre", "size": [2.0, 1.0, 0.6], "pad": 0.75, "need": true, "alt": [[1.4, 1.0, 0.6], [1.0, 1.0, 0.55]] },
		{ "item": "rayonnage", "at": "wall", "pref": "long", "size": [1.0, 2.2, 0.4], "pad": [0.0, 0.0, 0.7], "count": [2, 5] },
		{ "item": "vitrine", "at": "centre", "size": [1.2, 1.0, 0.5], "pad": 0.7, "chance": 0.4, "min_area": 20.0 }],
	"arriere_boutique": [
		{ "item": "table", "at": "centre", "size": [1.4, 0.8, 0.8], "pad": 0.6, "chance": 0.8 },
		{ "item": "etagere", "at": "wall", "pref": "long", "size": [1.0, 2.0, 0.45], "pad": [0.0, 0.0, 0.6], "count": [2, 3] }],
	"reserve": [
		{ "item": "etagere", "at": "wall", "pref": "long", "size": [1.0, 2.0, 0.45], "pad": [0.0, 0.0, 0.6], "count": [1, 4] },
		{ "item": "caisse", "at": "wall", "pref": "corner", "size": [0.6, 0.6, 0.6], "pad": [0.0, 0.0, 0.3], "count": [0, 3] }],
	"remise": [
		{ "item": "etagere", "at": "wall", "pref": "long", "size": [1.0, 2.0, 0.45], "pad": [0.0, 0.0, 0.6], "count": [1, 3] },
		{ "item": "caisse", "at": "wall", "pref": "corner", "size": [0.8, 0.8, 0.8], "pad": [0.0, 0.0, 0.3], "count": [1, 4] }],
	"atelier": [
		{ "item": "etabli", "at": "wall", "pref": "window", "size": [2.0, 0.9, 0.8], "pad": [0.0, 0.0, 0.8], "need": true, "alt": [[1.4, 0.9, 0.7]] },
		{ "item": "etagere", "at": "wall", "pref": "long", "size": [1.0, 2.0, 0.45], "pad": [0.0, 0.0, 0.6], "count": [1, 2] },
		{ "item": "caisse", "at": "wall", "pref": "corner", "size": [0.8, 0.8, 0.8], "pad": [0.0, 0.0, 0.3], "count": [0, 2] }],
	"entree": [
		{ "item": "console", "at": "wall", "pref": "middle", "size": [0.9, 0.85, 0.35], "pad": [0.0, 0.0, 0.4], "chance": 0.6, "hall": true },
		{ "item": "portemanteau", "at": "wall", "pref": "corner", "size": [0.6, 1.8, 0.3], "pad": [0.0, 0.0, 0.4], "chance": 0.6, "hall": true }],
	"corridor": [
		{ "item": "console", "at": "wall", "pref": "middle", "size": [0.8, 0.85, 0.3], "pad": [0.0, 0.0, 0.4], "chance": 0.3, "hall": true }],
}


static func dress(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> String:
	s.paint = paint(s.kind, ctx.scheme, rng)
	var missing := furnish(s, ctx, rng)
	s.lights = lamps(s, float(ctx.clear), rng)
	s.switches = switches(s, ctx)
	return missing


# --- Paint ------------------------------------------------------------------------

## A floor's own look, shared by its rooms.
static func scheme(rng: RandomNumberGenerator, level: int) -> Dictionary:
	var out := { "wear": clampf(rng.randf_range(0.25, 0.75) + (0.1 if level == 0 else 0.0), 0.0, 1.0),
		"tint": rng.randf_range(-0.02, 0.02), "ceiling": CEILINGS[rng.randi() % CEILINGS.size()] }
	for k: String in FLOORS:
		out[k] = FLOORS[k][rng.randi() % FLOORS[k].size()]
	return out


static func paint(kind: String, sch: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var p: Dictionary = PAINT[PAINT_OF.get(kind, "store")]
	var walls: Array = p.walls
	var out := { "wall": _vary(walls[rng.randi() % walls.size()], sch, rng, 1.0),
		"ceiling": _vary(sch.ceiling, sch, rng, 0.4), "floor": p.floor,
		"wear": snappedf(clampf(float(sch.wear) + rng.randf_range(-0.15, 0.15), 0.0, 1.0), 0.01),
		"lower_h": 0.0, "panels": false, "paper": false, "cornice": false }
	if kind == "salon" and p.floor == "parquet":
		out.pattern = "point de Hongrie" if rng.randf() < 0.6 else "à l'anglaise"
	elif p.floor == "parquet":
		out.pattern = "à l'anglaise"
	if p.has("lower"):
		var lower: Array = p.lower
		out.lower = _vary(lower[rng.randi() % lower.size()], sch, rng, 0.7)
		out.lower_h = snappedf(rng.randf_range(p.lower_h[0], p.lower_h[1]), 0.01)
	if rng.randf() < float(p.get("panels", 0.0)): # boiseries: panelled to the dado, the walls paler
		out.panels = true
		out.lower = (out.wall as Color).darkened(0.1)
		out.lower_h = snappedf(rng.randf_range(0.85, 1.0), 0.01)
		out.wall = (out.wall as Color).lightened(0.12)
	if rng.randf() < float(p.get("paper", 0.0)):
		out.paper = true
		out.paper_colour = _vary(PAPER[rng.randi() % PAPER.size()], sch, rng, 1.0)
		out.paper_pattern = ["rayures", "fleurs", "toile de Jouy"][rng.randi() % 3]
	out.cornice = rng.randf() < float(p.get("cornice", 0.0))
	var floors: Dictionary = FLOORS
	out.floor_colour = _vary(sch.get(p.floor, floors[p.floor][0]), sch, rng, 0.5)
	return out


## A colour moved a little in hue, saturation and value, leaning to the floor's tint and darkened
## by its wear.
static func _vary(c: Color, sch: Dictionary, rng: RandomNumberGenerator, amount: float) -> Color:
	var h := fposmod(c.h + (float(sch.tint) + rng.randf_range(-0.015, 0.015)) * amount, 1.0)
	var s := clampf(c.s + rng.randf_range(-0.05, 0.05) * amount, 0.0, 1.0)
	var v := clampf(c.v + rng.randf_range(-0.06, 0.06) * amount, 0.0, 1.0)
	return Color.from_hsv(h, s, v).darkened(float(sch.wear) * 0.12 * rng.randf() * amount)


# --- Lamps and switches --------------------------------------------------------------

static func lamps(s: Dictionary, clear: float, _rng: RandomNumberGenerator) -> Array:
	var r: Rect2 = s.rect
	var c := r.get_center()
	var along_x := r.size.x >= r.size.y
	var long := maxf(r.size.x, r.size.y)
	var out := []
	var flush := clear - 0.05
	var low := maxf(clear - 0.65, Config.PLAYER_HEIGHT + 0.2)
	match s.kind:
		"stair":
			out.append(_lamp("plafonnier", Vector3(c.x, flush, r.position.y + Config.INTERIOR_LANDING * 0.5), 3.5))
		"corridor", "allee", "entree":
			var n := maxi(1, floori(long / Config.INTERIOR_LIGHT_STEP))
			for i in n:
				var t := (i + 0.5) / n
				var p := Vector2(lerpf(r.position.x, r.end.x, t), c.y) if along_x else Vector2(c.x, lerpf(r.position.y, r.end.y, t))
				out.append(_lamp("plafonnier", Vector3(p.x, flush, p.y), clampf(long / n + 1.5, 2.5, 5.0)))
		"boutique", "atelier", "remise", "reserve", "arriere_boutique":
			var nx := maxi(1, roundi(r.size.x / 3.0))
			var nz := maxi(1, roundi(r.size.y / 3.0))
			for i in nx:
				for j in nz:
					var p := Vector3(lerpf(r.position.x, r.end.x, (i + 0.5) / nx), flush, lerpf(r.position.y, r.end.y, (j + 0.5) / nz))
					out.append(_lamp("plafonnier", p, clampf(maxf(r.size.x / nx, r.size.y / nz) + 1.5, 2.5, 5.0)))
		"wc", "salle_d_eau", "debarras":
			out.append(_lamp("plafonnier", Vector3(c.x, flush, c.y), 2.5))
		_:
			var kind := "lustre" if s.kind in ["salon", "salle_a_manger"] else "suspension"
			var y := maxf(clear - (0.85 if kind == "lustre" else 0.6), Config.PLAYER_HEIGHT + 0.2)
			var reach := clampf(sqrt(float(s.area)) * 1.2 + 1.0, 3.0, 7.0)
			var table := {}
			for it: Dictionary in s.furniture:
				if it.item == "table":
					table = it
			if not table.is_empty(): # over the table
				var tc: Vector2 = (table.rect as Rect2).get_center()
				out.append(_lamp(kind, Vector3(tc.x, y, tc.y), reach))
			elif float(s.area) > Config.INTERIOR_LIGHT_BIG or long > 1.7 * minf(r.size.x, r.size.y):
				for t in [0.27, 0.73]:
					var p := Vector2(lerpf(r.position.x, r.end.x, t), c.y) if along_x else Vector2(c.x, lerpf(r.position.y, r.end.y, t))
					out.append(_lamp(kind, Vector3(p.x, y, p.y), reach * 0.8))
			else:
				out.append(_lamp(kind, Vector3(c.x, y, c.y), reach))
			for it: Dictionary in s.furniture: # sconces each side of the fireplace
				if it.item == "cheminee" and s.kind in ["salon", "salle_a_manger"]:
					var fr: Rect2 = it.rect
					var fc: Vector2 = it.facing
					var side := Vector2(-fc.y, fc.x)
					var mid := fr.get_center() - fc * fr.size.dot(fc.abs()) * 0.5 + fc * 0.06
					for k in [-1.0, 1.0]:
						var p: Vector2 = mid + side * k * 0.95
						out.append(_lamp("applique", Vector3(p.x, Config.PLAYER_HEIGHT + 0.2, p.y), 2.5))
	return out


static func _lamp(kind: String, pos: Vector3, reach: float) -> Dictionary:
	var warm := { "lustre": Color("ffd9a0"), "suspension": Color("ffd59a"), "applique": Color("ffcf90"), "plafonnier": Color("ffe3b8") }
	return { "kind": kind, "pos": pos, "range": snappedf(reach, 0.01), "colour": warm[kind],
		"energy": 1.1 if kind == "lustre" else (0.6 if kind == "applique" else 0.9) }


## A switch by the room's way in, on the side the door opens from.
static func switches(s: Dictionary, ctx: Dictionary) -> Array:
	var d := {}
	for e: Dictionary in ctx.doors:
		if e.id == s.main_door:
			d = e
	if d.is_empty():
		for e: Dictionary in ctx.doors:
			if d.is_empty() and (e.a == s.id or e.b == s.id):
				d = e
	if d.is_empty():
		return []
	var r: Rect2 = s.rect
	var latch_hi := float(d.hinge) <= float(d.from) + EPS
	var along := float(d.to) + 0.15 if latch_hi else float(d.from) - 0.15
	var inward := 1.0
	var pos: Vector3
	if d.axis == "x":
		inward = 1.0 if r.get_center().x > float(d.at) else -1.0
		along = clampf(along, r.position.y + 0.05, r.end.y - 0.05)
		pos = Vector3(float(d.at) + inward * (float(d.t) * 0.5 + 0.01), Config.INTERIOR_SWITCH, along)
	else:
		inward = 1.0 if r.get_center().y > float(d.at) else -1.0
		along = clampf(along, r.position.x + 0.05, r.end.x - 0.05)
		pos = Vector3(along, Config.INTERIOR_SWITCH, float(d.at) + inward * (float(d.t) * 0.5 + 0.01))
	return [{ "pos": pos, "door": d.id }]


# --- Doors' and windows' room -----------------------------------------------------

## The square a door's leaf sweeps in a room.
static func swing_rect(d: Dictionary, room: Rect2) -> Rect2:
	return _door_strip(d, room, float(d.to) - float(d.from))


## What a door keeps free in room `id`: the leaf's square if it swings that way, else a strip to
## step through.
static func door_zone(d: Dictionary, room: Rect2, id: int) -> Rect2:
	if d.swing == id:
		return swing_rect(d, room)
	return _door_strip(d, room, DOOR_CLEAR)


## The doorway itself, a hand's depth into the room.
static func doorway(d: Dictionary, room: Rect2) -> Rect2:
	return _door_strip(d, room, 0.15)


static func _door_strip(d: Dictionary, room: Rect2, deep: float) -> Rect2:
	var w := float(d.to) - float(d.from)
	var half := float(d.t) * 0.5
	var at := float(d.at)
	if d.axis == "x":
		if room.get_center().x > at:
			return Rect2(at + half, d.from, deep, w)
		return Rect2(at - half - deep, d.from, deep, w)
	if room.get_center().y > at:
		return Rect2(d.from, at + half, w, deep)
	return Rect2(d.from, at - half - deep, w, deep)


static func window_zone(w: Dictionary, room: Rect2) -> Rect2:
	var deep: float = WINDOW_CLEAR.get(w.kind, 0.5)
	if w.side == "front":
		return Rect2(float(w.from) - 0.05, room.position.y, float(w.to) - float(w.from) + 0.1, deep)
	return Rect2(float(w.from) - 0.05, room.end.y - deep, float(w.to) - float(w.from) + 0.1, deep)


# --- Furniture ------------------------------------------------------------------------

## A room being furnished: the zones nothing (or nothing tall) may stand in, and its items.
class Fitting:
	var r: Rect2
	var id: int
	var zones := []   ## [Rect2, highest item allowed in it (-1: none)]
	var items := []   ## { item, rect, height, facing, wall, pad }
	var door_pts := []
	var window_pts := []
	var flues := []
	var circulation := false

	func _init(s: Dictionary, doors: Array, windows: Array, flue_list: Array) -> void:
		r = s.rect
		id = s.id
		circulation = HousePlan.KINDS[s.kind].circulation
		var inset := Config.INTERIOR_PASS + 0.06
		for d: Dictionary in doors:
			if d.a != id and d.b != id:
				continue
			var z := RoomDressing.door_zone(d, r, id)
			zones.append([z.grow(0.05), -1.0])
			var mid := (float(d.from) + float(d.to)) * 0.5
			var inward := 0.0
			if d.axis == "x":
				inward = 1.0 if r.get_center().x > float(d.at) else -1.0
				door_pts.append(Vector2(float(d.at) + inward * (float(d.t) * 0.5 + inset), mid))
			else:
				inward = 1.0 if r.get_center().y > float(d.at) else -1.0
				door_pts.append(Vector2(mid, float(d.at) + inward * (float(d.t) * 0.5 + inset)))
		for w: Dictionary in windows:
			if w.space != id:
				continue
			var z := RoomDressing.window_zone(w, r)
			if z.size.y > 0.0:
				zones.append([z, float(w.sill) - 0.02 if w.kind != "french" else -1.0])
			if w.kind != "stair":
				var mid := (float(w.from) + float(w.to)) * 0.5
				window_pts.append(Vector2(mid, r.position.y + inset if w.side == "front" else r.end.y - inset))
		for f: Dictionary in flue_list:
			var fx := float(f.x)
			var fz := float(f.z)
			if (absf(fx - r.position.x) < 0.02 or absf(fx - r.end.x) < 0.02) and fz > r.position.y + 0.8 and fz < r.end.y - 0.8:
				flues.append(f)

	func find(name: String) -> Dictionary:
		for i in range(items.size() - 1, -1, -1):
			if items[i].item == name:
				return items[i]
		return {}

	## Try to place one `spec` item of `size`; true when it stands.
	func place(spec: Dictionary, size: Array, rng: RandomNumberGenerator) -> bool:
		var cands := _candidates(spec, size, rng)
		cands.sort_custom(func(p: Dictionary, q: Dictionary): return float(p.score) > float(q.score))
		var tried := 0
		for c: Dictionary in cands:
			if not _free(c, spec):
				continue
			tried += 1
			items.append(c)
			if way_through().is_empty():
				return true
			items.pop_back()
			if tried >= 6:
				break
		return false

	func _candidates(spec: Dictionary, size: Array, rng: RandomNumberGenerator) -> Array:
		var w: float = size[0]
		var h: float = size[1]
		var d: float = size[2]
		var out := []
		match spec.at:
			"flue":
				for f: Dictionary in flues:
					var side := "x0" if absf(float(f.x) - r.position.x) < 0.02 else "x1"
					var u := float(f.z) - r.position.y - w * 0.5
					out.append(_on_wall(spec, side, u, w, h, d, 10.0))
				if out.is_empty() and spec.get("or", "") == "wall":
					return _wall_candidates(spec, w, h, d, rng)
			"wall":
				return _wall_candidates(spec, w, h, d, rng)
			"beside":
				var a := find(spec.of)
				if a.is_empty():
					return []
				var len := _side_len(a.wall)
				for k in [-1.0, 1.0]:
					var u := float(a.u) - w - 0.02 if k < 0.0 else float(a.u) + float(a.w) + 0.02
					if u >= 0.0 and u + w <= len:
						var c := _on_wall(spec, a.wall, u, w, h, d, rng.randf())
						c.anchor = a.item
						out.append(c)
			"front":
				var a := find(spec.of)
				if a.is_empty():
					return []
				var fc: Vector2 = a.facing
				var ar: Rect2 = a.rect
				var depth_a := ar.size.x if absf(fc.x) > 0.5 else ar.size.y
				var centre := ar.get_center() + fc * (depth_a * 0.5 + float(spec.get("gap", 0.35)) + d * 0.5)
				var sz := Vector2(d, w) if absf(fc.x) > 0.5 else Vector2(w, d)
				out.append({ "item": spec.item, "rect": Rect2(centre - sz * 0.5, sz), "height": h, "facing": -fc,
					"wall": "", "pad": Rect2(), "score": 1.0, "anchor": a.item })
			"centre":
				var along_x := r.size.x >= r.size.y
				var sz := Vector2(w, d) if along_x else Vector2(d, w)
				var pad := float(spec.get("pad", 0.5))
				var step := 0.25
				var x := r.position.x + pad + sz.x * 0.5
				while x <= r.end.x - pad - sz.x * 0.5 + EPS:
					var z := r.position.y + pad + sz.y * 0.5
					while z <= r.end.y - pad - sz.y * 0.5 + EPS:
						var cen := Vector2(x, z)
						var score := -cen.distance_to(r.get_center()) / maxf(r.size.x, r.size.y) + rng.randf() * 0.15
						out.append({ "item": spec.item, "rect": Rect2(cen - sz * 0.5, sz), "height": h,
							"facing": Vector2(0, -1), "wall": "", "pad": Rect2(cen - sz * 0.5, sz).grow(pad), "score": score })
						z += step
					x += step
		return out

	func _wall_candidates(spec: Dictionary, w: float, h: float, d: float, rng: RandomNumberGenerator) -> Array:
		var out := []
		var pref: String = spec.get("pref", "")
		var longest := maxf(r.size.x, r.size.y)
		for side in ["x0", "x1", "z0", "z1"]:
			var len := _side_len(side)
			if len < w + 0.04:
				continue
			var u := 0.02
			while u <= len - w - 0.02 + EPS:
				var score := rng.randf() * 0.3
				var mid := u + w * 0.5
				match pref:
					"middle":
						score -= absf(mid - len * 0.5) / len
					"corner":
						score -= minf(u, len - w - u) / len
					"long":
						score += len / longest * 0.5 - absf(mid - len * 0.5) / len * 0.3
					"far":
						var p := _wall_point(side, mid)
						var far := 0.0
						for dp: Vector2 in door_pts:
							far = maxf(far, p.distance_to(dp))
						score += far / r.size.length()
					"window":
						var best := 1.0
						for wp: Vector2 in window_pts:
							if _wall_of(wp) == side:
								best = minf(best, absf(_along(side, wp) - mid) / len)
						score -= best
				out.append(_on_wall(spec, side, u, w, h, d, score))
				u += 0.1
		return out

	func _side_len(side: String) -> float:
		return r.size.y if side.begins_with("x") else r.size.x

	func _wall_of(p: Vector2) -> String:
		var dists := { "x0": p.x - r.position.x, "x1": r.end.x - p.x, "z0": p.y - r.position.y, "z1": r.end.y - p.y }
		var best := "x0"
		for k: String in dists:
			if float(dists[k]) < float(dists[best]):
				best = k
		return best

	func _along(side: String, p: Vector2) -> float:
		return p.y - r.position.y if side.begins_with("x") else p.x - r.position.x

	func _wall_point(side: String, u: float) -> Vector2:
		match side:
			"x0":
				return Vector2(r.position.x, r.position.y + u)
			"x1":
				return Vector2(r.end.x, r.position.y + u)
			"z0":
				return Vector2(r.position.x + u, r.position.y)
		return Vector2(r.position.x + u, r.end.y)

	## An item of w x d with its back to `side`, `u` along it, and the pad round it.
	func _on_wall(spec: Dictionary, side: String, u: float, w: float, h: float, d: float, score: float) -> Dictionary:
		var pad: Array = spec.get("pad", [0.0, 0.0, 0.0])
		var pl: float = pad[0]
		var pr: float = pad[1]
		var pf: float = pad[2]
		var rect: Rect2
		var prect: Rect2
		var facing: Vector2
		match side:
			"x0":
				rect = Rect2(r.position.x, r.position.y + u, d, w)
				prect = Rect2(r.position.x, r.position.y + u - pl, d + pf, w + pl + pr)
				facing = Vector2(1, 0)
			"x1":
				rect = Rect2(r.end.x - d, r.position.y + u, d, w)
				prect = Rect2(r.end.x - d - pf, r.position.y + u - pl, d + pf, w + pl + pr)
				facing = Vector2(-1, 0)
			"z0":
				rect = Rect2(r.position.x + u, r.position.y, w, d)
				prect = Rect2(r.position.x + u - pl, r.position.y, w + pl + pr, d + pf)
				facing = Vector2(0, 1)
			_:
				rect = Rect2(r.position.x + u, r.end.y - d, w, d)
				prect = Rect2(r.position.x + u - pl, r.end.y - d - pf, w + pl + pr, d + pf)
				facing = Vector2(0, -1)
		return { "item": spec.item, "rect": rect, "height": h, "facing": facing, "wall": side, "u": u, "w": w,
			"pad": prect, "score": score }

	func _free(c: Dictionary, spec: Dictionary) -> bool:
		var rect: Rect2 = c.rect
		var pad: Rect2 = c.pad
		if not r.grow(EPS).encloses(rect):
			return false
		if spec.get("pad_in", false) and not r.grow(EPS).encloses(pad):
			return false
		if spec.at == "centre" and not r.grow(EPS).encloses(pad):
			return false
		if spec.get("hall", false): # in a way through, the corridor's own width stays clear
			var across := r.size.x if c.wall.begins_with("x") else r.size.y
			if across - float(spec.size[2]) < Config.INTERIOR_CORRIDOR:
				return false
		var h: float = c.height
		for z: Array in zones:
			var zr: Rect2 = z[0]
			if zr.grow(-EPS).intersects(rect) and (float(z[1]) < 0.0 or h > float(z[1])):
				return false
		var anchor: String = c.get("anchor", "")
		for it: Dictionary in items:
			var ir: Rect2 = it.rect
			if ir.grow(-EPS).intersects(rect.grow(-EPS)):
				return false
			var ip: Rect2 = it.pad
			if it.item != anchor and ip.has_area() and ip.grow(-EPS).intersects(rect):
				return false
			if pad.has_area() and it.item != anchor and pad.grow(-EPS).intersects(ir):
				return false
		return true

	## "" when the player walks from the first door to every other door and to a window; else what
	## is cut off.
	func way_through() -> String:
		var starts := door_pts + window_pts
		if starts.is_empty():
			return ""
		var g := Config.INTERIOR_GRID
		var nx := maxi(1, int(r.size.x / g))
		var nz := maxi(1, int(r.size.y / g))
		var cx := r.size.x / nx
		var cz := r.size.y / nz
		var big := 1e6
		var dist := PackedFloat32Array()
		dist.resize(nx * nz)
		for j in nz:
			for i in nx:
				var p := Vector2(r.position.x + (i + 0.5) * cx, r.position.y + (j + 0.5) * cz)
				var v := big
				for it: Dictionary in items:
					if (it.rect as Rect2).grow(g * 0.5).has_point(p):
						v = 0.0
						break
				dist[j * nx + i] = v
		var diag := sqrt(cx * cx + cz * cz)
		for j in nz: # chamfer distance to the furniture, forward then back
			for i in nx:
				var k := j * nx + i
				var v := dist[k]
				if i > 0:
					v = minf(v, dist[k - 1] + cx)
				if j > 0:
					v = minf(v, dist[k - nx] + cz)
					if i > 0:
						v = minf(v, dist[k - nx - 1] + diag)
					if i < nx - 1:
						v = minf(v, dist[k - nx + 1] + diag)
				dist[k] = v
		for j in range(nz - 1, -1, -1):
			for i in range(nx - 1, -1, -1):
				var k := j * nx + i
				var v := dist[k]
				if i < nx - 1:
					v = minf(v, dist[k + 1] + cx)
				if j < nz - 1:
					v = minf(v, dist[k + nx] + cz)
					if i < nx - 1:
						v = minf(v, dist[k + nx + 1] + diag)
					if i > 0:
						v = minf(v, dist[k + nx - 1] + diag)
				dist[k] = v
		var pass_r := Config.INTERIOR_PASS
		var walk := PackedByteArray()
		walk.resize(nx * nz)
		for j in nz:
			for i in nx:
				var px := (i + 0.5) * cx
				var pz := (j + 0.5) * cz
				var wall := minf(minf(px, r.size.x - px), minf(pz, r.size.y - pz))
				var k := j * nx + i
				walk[k] = 1 if minf(dist[k] - g * 0.5, wall) >= pass_r - EPS else 0
		var cells := []
		for p: Vector2 in starts:
			var i := clampi(int((p.x - r.position.x) / cx), 0, nx - 1)
			var j := clampi(int((p.y - r.position.y) / cz), 0, nz - 1)
			cells.append(j * nx + i)
		var first: int = cells[0]
		if walk[first] == 0:
			return "its door is blocked"
		var seen := PackedByteArray()
		seen.resize(nx * nz)
		seen[first] = 1
		var todo := [first]
		while not todo.is_empty():
			var k: int = todo.pop_back()
			var i := k % nx
			var j := k / nx
			for n: int in [k - 1 if i > 0 else -1, k + 1 if i < nx - 1 else -1, k - nx if j > 0 else -1, k + nx if j < nz - 1 else -1]:
				if n >= 0 and walk[n] == 1 and seen[n] == 0:
					seen[n] = 1
					todo.append(n)
		for q in range(1, door_pts.size()):
			if seen[cells[q]] == 0:
				return "a door is cut off from the others"
		if window_pts.is_empty():
			return ""
		for q in range(door_pts.size(), cells.size()):
			if seen[cells[q]] == 1:
				return ""
		return "no window can be reached"


## Furnish a room from its kind's kit; the first needed item that found no place, or "".
static func furnish(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> String:
	var kit: Array = KITS.get(s.kind, [])
	var fit := Fitting.new(s, ctx.doors, ctx.windows, ctx.flues)
	var missing := ""
	for spec: Dictionary in kit:
		if spec.has("chance") and rng.randf() >= float(spec.chance):
			continue
		if spec.has("min_area") and float(s.area) < float(spec.min_area):
			continue
		var n := 1
		if spec.has("count"):
			n = rng.randi_range(spec.count[0], spec.count[1])
		var tries: Array = [spec]
		for alt: Variant in spec.get("alt", []): # a smaller size, or other fields (a single bed's pad against the wall)
			var other := spec.duplicate()
			if alt is Array:
				other.size = alt
			else:
				other.merge(alt, true)
			tries.append(other)
		for k in n:
			var placed := false
			for t: Dictionary in tries:
				if fit.place(t, t.size, rng):
					placed = true
					break
			if not placed:
				if spec.get("need", false) and k == 0 and missing == "":
					missing = spec.item
				break
	var out := []
	for it: Dictionary in fit.items:
		out.append({ "item": it.item, "rect": it.rect, "height": it.height, "facing": it.facing, "wall": it.wall })
	s.furniture = out
	return missing


## What is wrong with a furnished room: items outside it, in a door's way, tall before a window,
## or a door or every window cut off.
static func check(s: Dictionary, f: Dictionary) -> Array:
	var fit := Fitting.new(s, f.doors, f.windows, [])
	var out := []
	for it: Dictionary in s.furniture:
		var rect: Rect2 = it.rect
		if not fit.r.grow(EPS).encloses(rect):
			out.append("the %s stands outside the room" % it.item)
		for z: Array in fit.zones:
			var zr: Rect2 = z[0]
			if zr.grow(-0.06).intersects(rect) and (float(z[1]) < 0.0 or float(it.height) > float(z[1])):
				out.append("the %s stands in a door's or window's way" % it.item)
		fit.items.append({ "item": it.item, "rect": rect, "pad": Rect2() })
	var way := fit.way_through()
	if way != "":
		out.append(way)
	return out
