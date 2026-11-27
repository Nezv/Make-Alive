class_name MapAreas
## The data of every playable area, one dictionary each (the format is documented in map_data.gd).
## A new map or mission starts here, not in code.

## The L-shaped test corridor (geometry in corridor_map.gd).
const CORRIDOR := {
	"name": "corridor",
	# (x, z) outline of the floor: leg A along Z, leg B along X.
	"bounds": [Vector2(-3, -3), Vector2(44, -3), Vector2(44, 3), Vector2(3, 3), Vector2(3, 30), Vector2(-3, 30)],
	"blocked_exits": [{ "at": Vector3(44, 0, 0), "kind": "darkness" }], # the open end the zombies come from
	# One per player slot, two rows of four at the closed end of leg A, looking down the corridor.
	"player_spawns": [
		{ "at": Vector3(0, 0.1, 26), "yaw": 0.0 }, { "at": Vector3(-1.2, 0.1, 26), "yaw": 0.0 },
		{ "at": Vector3(1.2, 0.1, 26), "yaw": 0.0 }, { "at": Vector3(-2.2, 0.1, 26.6), "yaw": 0.0 },
		{ "at": Vector3(2.2, 0.1, 26.6), "yaw": 0.0 }, { "at": Vector3(-0.6, 0.1, 27.6), "yaw": 0.0 },
		{ "at": Vector3(0.6, 0.1, 27.6), "yaw": 0.0 }, { "at": Vector3(0, 0.1, 28.6), "yaw": 0.0 },
	],
	"zombie_closets": [{ "id": "open_end", "at": Vector3(40.2, 0.1, 0), "radius": 2.4 }],
	"horde_routes": [{ "closet": "open_end", "points": [Vector3(40.2, 0, 0), Vector3(14, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 26)] }],
	"zones": [
		{ "id": "corner", "kind": "checkpoint", "box": [Vector3(0, 1.5, 0), Vector3(6, 3, 6)],
			"look": { "at": Vector3(-1.6, 0, -1.9), "yaw": 0.0, "kind": "tent" },
			"arrow": { "at": Vector3(0.6, 0, 7.0), "yaw": 0.0 } },
		{ "id": "exit", "kind": "extraction", "box": [Vector3(31, 1.5, 0), Vector3(6, 3, 6)] },
	],
	"doors": [{ "iid": 1, "at": Vector3(14, 0, 0), "yaw": 0.0 }],
	"lootboxes": [{ "iid": 2, "at": Vector3(2.4, 0, 22), "yaw": -PI / 2.0 }],
	"ammo_crates": [{ "iid": 3, "at": Vector3(-2.4, 0, 22), "yaw": PI / 2.0, "unlock": "corner" }],
	"ammo_boxes": [
		{ "iid": 4, "at": Vector3(-2.3, 0, 19.6), "yaw": 0.4, "ammo": "7.62" },
		{ "iid": 5, "at": Vector3(2.3, 0, 19.2), "yaw": -0.7, "ammo": "12 gauge" },
	],
	# Only counts with limited ammo on (--limited-ammo): the corridor is a test map and never runs dry.
	"starting_ammo": { "9 mm": 45, "7.62": 90, "12 gauge": 24 },
	"weapon_spots": [],
	"objectives": [
		{ "id": "reach_corner", "kind": "reach", "zone": "corner", "text": "Get to the corner" },
		{ "id": "get_out", "kind": "extract", "zone": "exit", "seconds": 5.0, "text": "Reach the far end and hold it" },
	],
}


## The Mirante mission on the city map, climbing up: from the gate at the foot of Morro da Boa
## Vista, up the road through the forest (a checkpoint at the hairpin), hold the summit until the
## helicopter comes, then up the lookout tower to board it beside the deck. The places come from
## the built map (its ground heights, its gate and tower: `map.mirante`), so this is a function.
static func mirante(map: CityMap) -> Dictionary:
	var gate := Transform3D(Basis(Vector3.UP, map.mirante.gate_yaw), map.mirante.gate)
	var deck: Vector3 = map.mirante.deck
	var top := map.poi_pos("mirante")
	var on_road := func(px: Vector2, lift := 0.1) -> Vector3:
		var p := map.nav.nearest_free(CityData.to_world(px))
		p.y = map.ground_y(p) + lift
		return p
	var spawns := []
	for row in 2: # two rows of four on the road just outside the gate, facing up it
		for i in 4:
			var p := map.nav.nearest_free(gate * Vector3(-2.4 + i * 1.6, 0, -9.0 - row * 1.8))
			p.y = map.ground_y(p) + 0.1
			spawns.append({ "at": p, "yaw": map.mirante.gate_yaw + PI })
	var hairpin: Vector3 = on_road.call(Vector2(1808, -90), 3.0)
	var tent := CityData.to_world(Vector2(1806, -96))
	tent.y = map.ground_y(tent)
	var arrow: Vector3 = on_road.call(Vector2(1790, -63), 0.0)
	var half := MiranteSet.TOWER_HALF - 0.2
	return {
		"name": "mirante",
		"player_spawns": spawns,
		"zombie_closets": [
			{ "id": "road_below", "at": on_road.call(Vector2(1823, 33)), "radius": 3.0 },
			{ "id": "road_bend", "at": on_road.call(Vector2(1818, -27)), "radius": 3.0 },
			{ "id": "clearing_west", "at": on_road.call(Vector2(1854, 40)), "radius": 2.5 },
			{ "id": "clearing_south", "at": on_road.call(Vector2(1866, 57)), "radius": 2.5 },
		],
		"zones": [
			{ "id": "hairpin", "kind": "checkpoint", "box": [hairpin, Vector3(24, 12, 24)],
				"look": { "at": tent, "yaw": 0.0, "kind": "tent" }, "arrow": { "at": arrow, "yaw": map.mirante.gate_yaw + PI } },
			{ "id": "summit", "kind": "trigger", "box": [top + Vector3(0, 6, 0), Vector3(56, 24, 56)] },
			{ "id": "deck", "kind": "extraction", "box": [deck + Vector3(0, 1.5, 0), Vector3(half * 2.0, 3.0, half * 2.0)] },
		],
		# Hanging level with the deck off its east side, the open door towards it.
		"heli": { "at": deck + Vector3(MiranteSet.TOWER_HALF + 4.0, 1.0, 0), "yaw": 0.0, "floor": deck.y },
		"objectives": [
			{ "id": "hairpin", "kind": "reach", "zone": "hairpin", "text": "Climb the road to the hairpin" },
			{ "id": "summit", "kind": "reach", "zone": "summit", "text": "Reach the Mirante at the top" },
			{ "id": "hold", "kind": "survive", "zone": "summit", "text": "Hold the summit until the helicopter comes", "heli": 60.0,
				"waves": [
					{ "size": 8, "types": { "walker": 0.6, "runner": 0.3, "leaper": 0.1 }, "closets": ["road_below"] },
					{ "size": 12, "gap": 12.0, "types": { "walker": 0.5, "runner": 0.35, "leaper": 0.15 } },
					{ "size": 16, "gap": 12.0, "types": { "walker": 0.4, "runner": 0.4, "leaper": 0.2 } },
				] },
			{ "id": "board", "kind": "extract", "zone": "deck", "seconds": 5.0, "text": "Up the tower: board the helicopter" },
		],
	}


## The Terminal Central (RUN): start on the middle platform under the roof, out through the way in
## onto Rua Nove de Março, north-east through the centre to a checkpoint halfway (the dead come
## back there), then on to the Prefeitura and its pad on the south lawn to be lifted out.
static func terminal(map: CityMap) -> Dictionary:
	var lot: Transform3D = map.terminal.frame
	var pad: Vector3 = map.prefeitura.pad
	var free := func(world: Vector3) -> Vector3:
		var p := map.nav.nearest_free(world)
		p.y = map.ground_y(p) + 0.1
		return p
	var spawns := []
	for row in 2: # two rows of four on the middle island, facing the way out
		for i in 4:
			var p: Vector3 = free.call(lot * Vector3(-3.6 + i * 2.4, 0, TerminalSet.ISLANDS[1] - 0.8 + row * 1.6))
			p.y = lot.origin.y + TerminalSet.ISLAND_H + 0.1
			spawns.append({ "at": p, "yaw": PI })
	var gate: Vector3 = map.terminal.gate
	var mid := GameModes.street_point(map, gate.lerp(pad, 0.5))
	var to_out := Vector3(pad.x - mid.x, 0, pad.z - mid.z).normalized()
	return {
		"name": "terminal",
		"respawn": "checkpoint",
		"player_spawns": spawns,
		"zombie_closets": [
			{ "id": "west", "at": free.call(GameModes.street_point(map, CityData.to_world(Vector2(985, 520)))), "radius": 3.0 },
			{ "id": "east", "at": free.call(GameModes.street_point(map, CityData.to_world(Vector2(1084, 540)))), "radius": 3.0 },
			{ "id": "midway", "at": free.call(GameModes.street_point(map, mid + Vector3(40, 0, 40))), "radius": 3.0 },
			{ "id": "avenue", "at": map.nav.nearest_free(CityData.to_world(Vector2(1169, 268))), "radius": 3.0 },
		],
		"zones": [
			{ "id": "halfway", "kind": "checkpoint", "box": [mid + Vector3(0, 2.0, 0), Vector3(14, 8, 14)],
				"look": { "at": mid + Vector3(3.0, 0, 3.0), "yaw": atan2(-to_out.x, -to_out.z), "kind": "tent" } },
			{ "id": "pad", "kind": "extraction", "box": [pad + Vector3(0, 1.5, 0), Vector3(PrefeituraSet.PAD_R * 1.8, 3.0, PrefeituraSet.PAD_R * 1.8)] },
		],
		"objectives": [
			{ "id": "halfway", "kind": "reach", "zone": "halfway", "text": "Out of the terminal and across the centre to the checkpoint" },
			{ "id": "board", "kind": "extract", "zone": "pad", "seconds": 5.0, "text": "On to the Prefeitura: hold the pad on the south lawn" },
		],
	}

## The 62º Batalhão (DEFEND): in through the gate onto the lawn, hold the parade ground through
## three waves, then the helicopter comes down on the painted H at its middle.
static func batalhao(map: CityMap) -> Dictionary:
	var lot: Transform3D = map.batalhao.frame
	var pad: Vector3 = map.batalhao.pad
	var free := func(local: Vector3) -> Vector3:
		var p := map.nav.nearest_free(lot * local)
		p.y = map.ground_y(p) + 0.1
		return p
	var spawns := []
	for row in 2: # two rows of four on the drive inside the gate, facing in
		for i in 4:
			spawns.append({ "at": free.call(Vector3(-3.6 + i * 2.4, 0, 6.0 + row * 1.6)), "yaw": BatalhaoSet.YAW + PI })
	var gx := BatalhaoSet.GROUND_X
	var gz := BatalhaoSet.GROUND_Z
	var poly := []
	for k: Vector3 in [Vector3(-gx, 0, gz.x), Vector3(gx, 0, gz.x), Vector3(gx, 0, gz.y), Vector3(-gx, 0, gz.y)]:
		var w := lot * k
		poly.append(Vector2(w.x, w.z))
	var square := func(c: Vector3, r: float) -> Array:
		var out := []
		for k: Vector2 in [Vector2(-r, -r), Vector2(r, -r), Vector2(r, r), Vector2(-r, r)]:
			var w := lot * (c + Vector3(k.x, 0, k.y))
			out.append(Vector2(w.x, w.z))
		return out
	return {
		"name": "batalhao",
		"player_spawns": spawns,
		"zombie_closets": [
			{ "id": "hq_back", "at": free.call(Vector3(0, 0, 192)), "radius": 3.0 },
			{ "id": "gym", "at": free.call(Vector3(-92, 0, 196)), "radius": 3.0 },
			{ "id": "east_yard", "at": free.call(Vector3(90, 0, 110)), "radius": 3.0 },
			{ "id": "west_yard", "at": free.call(Vector3(-92, 0, 64)), "radius": 3.0 },
		],
		"zones": [
			{ "id": "parade", "kind": "trigger", "polygon": poly, "y": [pad.y - 2.0, pad.y + 8.0] },
			{ "id": "pad", "kind": "extraction", "polygon": square.call(BatalhaoSet.PAD, 6.0), "y": [pad.y - 2.0, pad.y + 4.0] },
		],
		# Coming down on the H, nose to the gate.
		"heli": { "at": pad + Vector3(0, 0.7, 0), "yaw": BatalhaoSet.YAW, "floor": pad.y },
		"objectives": [
			{ "id": "hold", "kind": "survive", "zone": "parade", "text": "Hold the parade ground until the helicopter comes", "heli": 60.0,
				"waves": [
					{ "size": 12, "types": { "walker": 0.7, "runner": 0.3 }, "closets": ["hq_back", "gym"] },
					{ "size": 16, "gap": 12.0, "types": { "walker": 0.55, "runner": 0.35, "leaper": 0.1 }, "closets": ["east_yard", "west_yard"] },
					{ "size": 20, "gap": 12.0, "types": { "walker": 0.45, "runner": 0.4, "leaper": 0.15 } },
				] },
			{ "id": "board", "kind": "extract", "zone": "pad", "seconds": 5.0, "text": "To the H on the ground: board the helicopter" },
		],
	}

## The Hospital Dona Helena (EXTRACTION, up): start under the ambulance bay on Rua Blumenau, get
## round the tower to the yard behind (a checkpoint, the triage tent), hold it through three waves
## while the helicopter comes, then up the fire stair, ten floors, to board it on the roof.
static func hospital(map: CityMap) -> Dictionary:
	var lot: Transform3D = map.hospital.frame
	var pad: Vector3 = map.hospital.pad
	var free := func(local: Vector3) -> Vector3:
		var p := map.nav.nearest_free(lot * local)
		p.y = map.ground_y(p) + 0.1
		return p
	var spawns := []
	for row in 2: # two rows of four in the drop-off lane, facing the street
		for i in 4:
			spawns.append({ "at": free.call(Vector3(-33.6 + i * 2.4, 0, -15.0 - row * 1.6)), "yaw": -PI * 0.5 })
	var yard := lot * Vector3(-31, 4, 34)
	return {
		"name": "hospital",
		"player_spawns": spawns,
		"zombie_closets": [
			{ "id": "back_west", "at": free.call(Vector3(-70, 0, 40)), "radius": 3.0 },
			{ "id": "back_east", "at": free.call(Vector3(-6, 0, 42)), "radius": 3.0 },
			{ "id": "blumenau_north", "at": map.nav.nearest_free(CityData.to_world(Vector2(767, 335))), "radius": 3.0 },
			{ "id": "blumenau_south", "at": map.nav.nearest_free(CityData.to_world(Vector2(760, 466))), "radius": 3.0 },
		],
		"zones": [
			# 44 m along the back of the tower, 20 m out from it (the lot is turned: x and z swap).
			{ "id": "yard", "kind": "checkpoint", "box": [yard, Vector3(20, 8, 44)],
				"look": { "at": lot * Vector3(-40, 0, 31), "yaw": -PI * 0.5, "kind": "tent" } },
			{ "id": "roof", "kind": "extraction", "box": [pad + Vector3(0, 1.5, 0), Vector3(HospitalSet.PAD_HALF * 2.0, 3.0, HospitalSet.PAD_HALF * 2.0)] },
		],
		# Settling onto the helipad, nose to the street.
		"heli": { "at": pad + Vector3(0, 0.82, 0), "yaw": -PI * 0.5, "floor": pad.y + 0.12 },
		"objectives": [
			{ "id": "yard", "kind": "reach", "zone": "yard", "text": "Get round the tower to the yard behind" },
			{ "id": "hold", "kind": "survive", "zone": "yard", "text": "Hold the yard until the helicopter is on the roof", "heli": 60.0,
				"waves": [
					{ "size": 10, "types": { "walker": 0.7, "runner": 0.3 }, "closets": ["blumenau_north", "blumenau_south"] },
					{ "size": 14, "gap": 12.0, "types": { "walker": 0.55, "runner": 0.35, "leaper": 0.1 }, "closets": ["back_west", "back_east"] },
					{ "size": 18, "gap": 12.0, "types": { "walker": 0.45, "runner": 0.4, "leaper": 0.15 } },
				] },
			{ "id": "board", "kind": "extract", "zone": "roof", "seconds": 5.0, "text": "Up the fire stair to the roof: board the helicopter" },
		],
	}


## The Prefeitura mission on the city map, defending: start on the forecourt behind the sandbags
## at the door, hold it through three waves coming down the avenue, round the ends of the building
## from the yard behind it and out of the car park, the helicopter coming in during the last; then
## everyone onto the round pad on the south lawn. Places come from the built map (`map.prefeitura`).
static func prefeitura(map: CityMap) -> Dictionary:
	var lot: Transform3D = map.prefeitura.frame
	var pad: Vector3 = map.prefeitura.pad
	var free := func(local: Vector3) -> Vector3:
		var p := map.nav.nearest_free(lot * local)
		p.y = map.ground_y(p) + 0.1
		return p
	var spawns := []
	for row in 2: # two rows of four between the sandbags and the canopy, facing the avenue
		for i in 4:
			spawns.append({ "at": free.call(Vector3(-3.6 + i * 2.4, 0, -0.5 - row * 1.6)), "yaw": PI * 0.5 })
	var forecourt := lot * Vector3(0, 4, -8)
	return {
		"name": "prefeitura",
		"player_spawns": spawns,
		"zombie_closets": [
			{ "id": "yard_south", "at": free.call(Vector3(-30, 0, 44)), "radius": 3.0 },
			{ "id": "yard_north", "at": free.call(Vector3(28, 0, 46)), "radius": 3.0 },
			{ "id": "avenue_south", "at": map.nav.nearest_free(CityData.to_world(Vector2(1169, 268))), "radius": 3.0 },
			{ "id": "avenue_north", "at": map.nav.nearest_free(CityData.to_world(Vector2(1156, 160))), "radius": 3.0 },
		],
		"zones": [
			{ "id": "forecourt", "kind": "trigger", "box": [forecourt, Vector3(36, 8, 64)] }, # 64 m along the front, 36 m out from it
			{ "id": "pad", "kind": "extraction", "box": [pad + Vector3(0, 1.5, 0), Vector3(PrefeituraSet.PAD_R * 1.8, 3.0, PrefeituraSet.PAD_R * 1.8)] },
		],
		# Settling onto the pad, nose to the avenue.
		"heli": { "at": pad + Vector3(0, 0.7, 0), "yaw": PI * 0.5, "floor": pad.y },
		"objectives": [
			{ "id": "hold", "kind": "survive", "zone": "forecourt", "text": "Hold the Prefeitura until the helicopter comes", "heli": 60.0,
				"waves": [
					{ "size": 10, "types": { "walker": 0.7, "runner": 0.3 }, "closets": ["avenue_south", "avenue_north"] },
					{ "size": 14, "gap": 12.0, "types": { "walker": 0.55, "runner": 0.35, "leaper": 0.1 }, "closets": ["yard_south", "yard_north"] },
					{ "size": 18, "gap": 12.0, "types": { "walker": 0.45, "runner": 0.4, "leaper": 0.15 } },
				] },
			{ "id": "board", "kind": "extract", "zone": "pad", "seconds": 5.0, "text": "To the pad on the lawn: board the helicopter" },
		],
	}
