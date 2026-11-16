class_name CheckpointLook
## What a checkpoint looks like, from its zone's data: a lit military tent (or a safe-room door with
## a lamp over it) where it is, and a hand-painted arrow on the ground on the way there.
##   zone: { ..., "look": { at, yaw, kind: "tent" | "door" }, "arrow": { at, yaw } }
## One baked mesh plus one glowing lamp per checkpoint; no collision (it must not block the way).

const PAINT := Color("e6dfc8")
const LAMP := Color(1.0, 0.82, 0.5)


static func build(zone_id: String, zone: Dictionary) -> Node3D:
	var node := Node3D.new()
	node.name = "Checkpoint_%s" % zone_id
	var b := MeshKit.Builder.new()
	var lamp_at := Vector3.ZERO
	if zone.has("look"):
		var look: Dictionary = zone.look
		var t := Transform3D(Basis(Vector3.UP, look.get("yaw", 0.0)), look.at)
		if look.get("kind", "tent") == "door":
			Props.bx(b, t, Vector3(1.3, 2.3, 0.12), Vector3(0, 1.15, 0), Color("4d5a52"))    # steel door
			Props.bx(b, t, Vector3(1.5, 0.12, 0.16), Vector3(0, 2.36, 0), Color("2f3530"))   # frame
			Props.bx(b, t, Vector3(0.08, 0.3, 0.06), Vector3(0.5, 1.1, 0.08), Color("b8b0a0")) # bar
			Props.bx(b, t, Vector3(0.9, 0.18, 0.02), Vector3(0, 1.85, 0.07), Color("2f8f3f")) # SAFE plate
			lamp_at = t * Vector3(0, 2.6, 0.18)
		else:
			Props.tent(b, t, 2.4, 1.6, Color("5b6340"), false)
			Props.bx(b, t, Vector3(0.7, 0.5, 0.45), Vector3(0.4, 0.25, 0.1), Props.OLIVE)     # supplies inside
			Props.bx(b, t, Vector3(0.75, 0.06, 1.4), Vector3(-0.55, 0.42, 0.0), Color("5f6b4a")) # a cot
			lamp_at = t * Vector3(0, 2.25, 0)
	if zone.has("arrow"):
		var arrow: Dictionary = zone.arrow
		var t := Transform3D(Basis(Vector3.UP, arrow.get("yaw", 0.0)), arrow.at)
		# Painted with a brush: a shaft and two strokes for the head, none quite straight.
		Props.bx(b, t, Vector3(0.22, 0.006, 1.6), Vector3(0.02, 0.004, 0.3), PAINT, Basis(Vector3.UP, 0.03))
		Props.bx(b, t, Vector3(0.2, 0.006, 0.85), Vector3(-0.24, 0.004, -0.62), PAINT, Basis(Vector3.UP, -0.72))
		Props.bx(b, t, Vector3(0.2, 0.006, 0.8), Vector3(0.26, 0.004, -0.6), PAINT, Basis(Vector3.UP, 0.68))
		Props.bx(b, t, Vector3(0.12, 0.006, 0.18), Vector3(0.18, 0.004, 1.25), PAINT, Basis(Vector3.UP, 0.4)) # a drip
	node.add_child(b.instance(null, false))
	if zone.has("look"):
		var lb := MeshKit.Builder.new()
		lb.box(Vector3(0.16, 0.16, 0.16), Vector3.ZERO, Color.WHITE)
		var lamp := lb.instance(MeshKit.emissive(LAMP, 4.0), false)
		lamp.name = "Lamp"
		lamp.position = lamp_at
		node.add_child(lamp)
	return node
