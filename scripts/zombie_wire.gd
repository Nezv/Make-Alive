class_name ZombieWire
## Compact binary encoding of zombie snapshots: 13 bytes per zombie, so a full horde fits in
## one unreliable packet (anything over ~1392 bytes gets fragmented and dropped more often).
##
## Layout per zombie: u32 id | s16 x,y,z in centimetres | u8 yaw | u8 state<<4|type | u8 parts mask

const BYTES_EACH := 13


## `list`: Array of { zid, pos: Vector3, yaw, state, type, mask }.
static func pack(list: Array) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(list.size() * BYTES_EACH)
	var o := 0
	for z: Dictionary in list:
		var pos: Vector3 = z.pos
		out.encode_u32(o, z.zid)
		out.encode_s16(o + 4, clampi(roundi(pos.x * 100.0), -32768, 32767))
		out.encode_s16(o + 6, clampi(roundi(pos.y * 100.0), -32768, 32767))
		out.encode_s16(o + 8, clampi(roundi(pos.z * 100.0), -32768, 32767))
		out.encode_u8(o + 10, roundi(fposmod(z.yaw, TAU) / TAU * 256.0) & 0xFF)
		out.encode_u8(o + 11, ((z.state & 0xF) << 4) | (z.type & 0xF))
		out.encode_u8(o + 12, z.mask & 0xFF)
		o += BYTES_EACH
	return out


static func unpack(bytes: PackedByteArray) -> Array:
	var out := []
	var o := 0
	while o + BYTES_EACH <= bytes.size():
		var st := bytes.decode_u8(o + 11)
		out.append({
			"zid": bytes.decode_u32(o),
			"pos": Vector3(bytes.decode_s16(o + 4), bytes.decode_s16(o + 6), bytes.decode_s16(o + 8)) / 100.0,
			"yaw": bytes.decode_u8(o + 10) / 256.0 * TAU,
			"state": st >> 4,
			"type": st & 0xF,
			"mask": bytes.decode_u8(o + 12),
		})
		o += BYTES_EACH
	return out
