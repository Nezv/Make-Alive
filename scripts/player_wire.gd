class_name PlayerWire
## Compact binary encoding of player snapshots, the partner of ZombieWire: 23 bytes per player.
## Names are not here: they change when someone joins or leaves, not 20 times a second, so they
## travel once through Game.player_names.
##
## Layout per player: u32 id | f32 x,y,z | u16 yaw | u8 hp | u16 kills | u8 weapon | u8 action
## `action` is bits (ACTION_*): what the body is doing, so others can draw it.

const BYTES_EACH := 23
const ACTION_CROUCH := 1
const ACTION_AIR := 2 ## off the ground: jumping, falling, vaulting
const ACTION_HEAL := 4  ## using a medical item (set by the host, never trusted from a client)
const ACTION_BLEED := 8 ## has an open wound (host only too)
const ACTION_DOWNED := 16 ## downed: crawling, waiting to be got up (host only too)
const ACTION_BODY := ACTION_CROUCH | ACTION_AIR ## what a client may say about itself


## `list`: Array of { id, pos: Vector3, yaw, hp, kills, weapon, action } (`action` may be left out).
static func pack(list: Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(list.size() * BYTES_EACH)
	var o := 0
	for p: Dictionary in list:
		var pos: Vector3 = p.pos
		out.encode_u32(o, p.id)
		out.encode_float(o + 4, pos.x)
		out.encode_float(o + 8, pos.y)
		out.encode_float(o + 12, pos.z)
		out.encode_u16(o + 16, roundi(fposmod(p.yaw, TAU) / TAU * 65536.0) & 0xFFFF)
		out.encode_u8(o + 18, clampi(p.hp, 0, 255))
		out.encode_u16(o + 19, clampi(p.kills, 0, 65535))
		out.encode_u8(o + 21, clampi(p.weapon, 0, 255))
		out.encode_u8(o + 22, int(p.get("action", 0)) & 0xFF)
		o += BYTES_EACH
	return out


static func unpack(bytes: PackedByteArray) -> Array:
	var out := []
	var o := 0
	while o + BYTES_EACH <= bytes.size():
		out.append({
			"id": bytes.decode_u32(o),
			"pos": Vector3(bytes.decode_float(o + 4), bytes.decode_float(o + 8), bytes.decode_float(o + 12)),
			"yaw": bytes.decode_u16(o + 16) / 65536.0 * TAU,
			"hp": bytes.decode_u8(o + 18),
			"kills": bytes.decode_u16(o + 19),
			"weapon": bytes.decode_u8(o + 21),
			"action": bytes.decode_u8(o + 22),
		})
		o += BYTES_EACH
	return out
