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
