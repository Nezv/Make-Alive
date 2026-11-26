class_name GameModes
## The ways to play a city match, picked on the menu (or `--mode=`), the host's choice sent in
## `welcome`. Each mode is map data made at the start of the match from where the players start (the
## mission's POI, the terminal in free play), so every peer makes the same zones from the same town:
##
##   extraction  fight from the start to a way out a few hundred metres toward the next POI, a
##               checkpoint halfway (the dead come back there), hold the way out
##   defense     hold the start through three waves, the last one lasting until the helicopter is
##               down, then everyone to the helicopter
##   open_world  no objective: days and nights go by (OpenWorld), the nights bring the hordes and
##               every Config.OPEN_HORDE_NIGHT-th is a horde night; the dead come back after a while
##
## "" is free play as before (no objective at all).

const ORDER := ["extraction", "defense", "open_world"]
const INFO := {
	"extraction": { "title": "EXTRACTION", "brief": "Fight your way across town to a way out. A checkpoint halfway brings the dead back." },
	"defense": { "title": "DEFENSE", "brief": "Hold the start through three waves until the helicopter lands, then get aboard." },
	"open_world": { "title": "OPEN WORLD", "brief": "No way out. Scavenge the houses by day, survive the nights. Every seventh night the horde comes." },
}
## Where an extraction run heads from each POI (it stops after Config.MODE_EXTRACT_DIST metres).
const EXTRACT_TOWARD := { "terminal": "prefeitura", "hospital": "terminal", "prefeitura": "terminal",
	"batalhao": "hospital", "mirante": "hospital" }


static func valid(mode: String) -> bool:
	return mode == "" or ORDER.has(mode)


## The mode's map data for `map` (a CityMap), laid over the map: `map.use_data(GameModes.data(...))`.
static func data(mode: String, map: CityMap) -> Dictionary:
	match mode:
		"extraction":
			return _extraction(map)
		"defense":
			return _defense(map)
		"open_world":
			return { "name": "city_open_world", "respawn": Config.OPEN_RESPAWN, "sky": "clear" }
	return {}


static func apply(mode: String, map: GameMap) -> void:
	if mode == "" or not map is CityMap:
		return
	map.use_data(data(mode, map as CityMap))
	map.data.build_checkpoints(map.root)


static func _start_poi(map: CityMap) -> String:
	return map.mission if CityData.POIS.has(map.mission) else "terminal"


static func _extraction(map: CityMap) -> Dictionary:
	var poi := _start_poi(map)
	var start := map.poi_pos(poi)
	var toward := map.poi_pos(EXTRACT_TOWARD[poi])
	var dir := Vector3(toward.x - start.x, 0, toward.z - start.z)
	var dist := minf(dir.length(), Config.MODE_EXTRACT_DIST)
	dir = dir.normalized()
	var out := street_point(map, start + dir * dist)
	var mid := street_point(map, start + dir * dist * 0.5)
	var to_out := (out - mid).normalized()
	return {
		"name": "city_extraction",
		"respawn": "checkpoint",
		"zones": [
			{ "id": "halfway", "kind": "checkpoint", "box": [mid + Vector3(0, 2.0, 0), Vector3(12, 8, 12)],
				"look": { "at": mid + Vector3(3.0, 0, 3.0), "yaw": atan2(-to_out.x, -to_out.z), "kind": "tent" } },
			{ "id": "way_out", "kind": "extraction", "box": [out + Vector3(0, 2.0, 0), Vector3(10, 8, 10)] },
		],
		"objectives": [
			{ "id": "halfway", "kind": "reach", "zone": "halfway", "text": "Fight your way to the checkpoint" },
			{ "id": "way_out", "kind": "extract", "zone": "way_out", "seconds": Config.MODE_EXTRACT_HOLD,
				"text": "Reach the way out and hold it together" },
		],
	}


static func _defense(map: CityMap) -> Dictionary:
	var at := map.player_spawn()
	return {
		"name": "city_defense",
		"respawn": Config.MODE_DEFENSE_RESPAWN,
		"zones": [{ "id": "stand", "kind": "trigger", "box": [at + Vector3(0, 2.0, 0), Vector3(28, 8, 28)] }],
		"objectives": [
			{ "id": "hold", "kind": "survive", "zone": "stand", "heli": Config.MODE_DEFENSE_HELI,
				"text": "Hold out until the helicopter lands", "waves": [
					{ "size": 10, "gap": 20.0 },
					{ "size": 16, "types": { "walker": 0.6, "runner": 0.35, "leaper": 0.05 }, "gap": 25.0 },
					{ "size": 22, "types": { "walker": 0.5, "runner": 0.4, "leaper": 0.1 }, "gap": 30.0 },
				] },
			{ "id": "board", "kind": "extract", "zone": "stand", "seconds": Config.MODE_BOARD,
				"text": "Everyone to the helicopter" },
		],
	}


## The nearest street, square or park cell to `p` (rings outward, Config.MODE_STREET_SEARCH metres at
## most), on the ground. `p` itself when there is none.
static func street_point(map: CityMap, p: Vector3) -> Vector3:
	var open := [CityMap.STREET, CityMap.SQUARE]
	var step := Config.CITY_CELL
	var rings := ceili(Config.MODE_STREET_SEARCH / step)
	for r in rings + 1:
		var best := Vector3.INF
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var q := p + Vector3(dx * step, 0, dz * step)
				if open.has(map.type_at(q)) and (best == Vector3.INF or q.distance_to(p) < best.distance_to(p)):
					best = q
		if best != Vector3.INF:
			best.y = map.ground_y(best)
			return best
	var q := p
	q.y = map.ground_y(q)
	return q
