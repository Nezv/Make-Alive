class_name ZombieWire
## Compact binary encoding of zombie snapshots: 13 bytes per zombie plus a 12-byte header, so a
## full horde fits in one unreliable packet (anything over ~1392 bytes gets fragmented and dropped
## more often).
##
## Header: f32 x,y,z of an anchor, the first zombie's position in whole metres. The city is
## kilometres wide, so positions are sent as centimetres from the anchor: good for 327 m around it.
## Per zombie: u24 id | s16 x,y,z in centimetres from the anchor | u8 yaw | u16 look | u8 parts mask
## `look` = type (4 bits: twelve types fit) | state (5 bits) | flags (3) | armour (4). Ids are 24 bits: a
## match that spawns sixteen million zombies wraps, and the old ones are long dead.

const HEADER := 12
const BYTES_EACH := 13
const FLAG_BURNING := 1
const FLAG_CLIMBING := 2
const FLAG_CRAWLING := 4 ## legs lost (also readable from the parts mask)


## `list`: Array of { zid, pos: Vector3, yaw, state, type, mask, flags?, armour? } (flags and armour may be left out).
static func pack(list: Array) -> PackedByteArray:
	var out := PackedByteArray()
	if list.is_empty():
		return out
	out.resize(HEADER + list.size() * BYTES_EACH)
	var anchor: Vector3 = (list[0].pos as Vector3).round()
	out.encode_float(0, anchor.x)
	out.encode_float(4, anchor.y)
	out.encode_float(8, anchor.z)
	var o := HEADER
	for z: Dictionary in list:
		var pos: Vector3 = z.pos - anchor
		out.encode_u16(o, z.zid & 0xFFFF)
		out.encode_u8(o + 2, (z.zid >> 16) & 0xFF)
		out.encode_s16(o + 3, clampi(roundi(pos.x * 100.0), -32768, 32767))
		out.encode_s16(o + 5, clampi(roundi(pos.y * 100.0), -32768, 32767))
		out.encode_s16(o + 7, clampi(roundi(pos.z * 100.0), -32768, 32767))
		out.encode_u8(o + 9, roundi(fposmod(z.yaw, TAU) / TAU * 256.0) & 0xFF)
		var look: int = (z.type & 0xF) | ((z.state & 0x1F) << 4) | ((int(z.get("flags", 0)) & 7) << 9) | ((int(z.get("armour", 0)) & 0xF) << 12)
		out.encode_u16(o + 10, look)
		out.encode_u8(o + 12, z.mask & 0xFF)
		o += BYTES_EACH
	return out


static func unpack(bytes: PackedByteArray) -> Array:
	var out := []
	if bytes.size() < HEADER:
		return out
	var anchor := Vector3(bytes.decode_float(0), bytes.decode_float(4), bytes.decode_float(8))
	var o := HEADER
	while o + BYTES_EACH <= bytes.size():
		var look := bytes.decode_u16(o + 10)
		out.append({
			"zid": bytes.decode_u16(o) | (bytes.decode_u8(o + 2) << 16),
			"pos": anchor + Vector3(bytes.decode_s16(o + 3), bytes.decode_s16(o + 5), bytes.decode_s16(o + 7)) / 100.0,
			"yaw": bytes.decode_u8(o + 9) / 256.0 * TAU,
			"type": look & 0xF,
			"state": (look >> 4) & 0x1F,
			"flags": (look >> 9) & 7,
			"armour": (look >> 12) & 0xF,
			"mask": bytes.decode_u8(o + 12),
		})
		o += BYTES_EACH
	return out
