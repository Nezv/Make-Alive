class_name Corpses
## The dead, made from the same Humanoid rig and Characters outfits as the living.
##
## A corpse is a rig posed once (face down, face up, on its side, or slumped sitting) and then
## flattened into the Builder it is given, so thirty bodies cost one draw call and no animation.

enum Pose { PRONE, SUPINE, SIDE, SITTING }

const HUMAN_SKINS := [Color("e0b48a"), Color("c68e5a"), Color("8d5a3a"), Color("f0c8a0")]
const J := Humanoid.J


## What a person who died (and didn't turn) looks like in `outfit`.
static func human_style(id: int, outfit: int) -> Dictionary:
	var s := Characters.zombie_style(id, 0, outfit)
	s.zombie = false
	s.skin = HUMAN_SKINS[absi(id) % HUMAN_SKINS.size()]
	s.erase("eyes")
	s.erase("scale")
	return s


## Pose a body and merge it into `b` at `xf` (the spot on the ground where its hips lie).
static func add(b: MeshKit.Builder, style: Dictionary, pose: int, xf: Transform3D,
		rng: RandomNumberGenerator) -> void:
	style.erase("scale")
	var rig := Humanoid.create(style)
	var c := rig._cur
	c[J.NECK_YAW] = rng.randf_range(-0.9, 0.9)
	c[J.NECK_ROLL] = rng.randf_range(-0.3, 0.3)
	c[J.SPINE_YAW] = rng.randf_range(-0.25, 0.25)
	c[J.SPINE_ROLL] = rng.randf_range(-0.2, 0.2)
	c[J.SH_L_OUT] = rng.randf_range(0.1, 1.3)
	c[J.SH_R_OUT] = rng.randf_range(0.1, 1.3)
	c[J.SH_L_X] = rng.randf_range(-0.4, 2.8)
	c[J.SH_R_X] = rng.randf_range(-0.4, 2.8)
	c[J.EL_L] = rng.randf_range(0.0, 1.4)
	c[J.EL_R] = rng.randf_range(0.0, 1.4)
	c[J.HIP_L] = rng.randf_range(-0.15, 0.5)
	c[J.HIP_R] = rng.randf_range(-0.15, 0.5)
	c[J.KNEE_L] = rng.randf_range(-1.1, 0.0)
	c[J.KNEE_R] = rng.randf_range(-1.1, 0.0)
	var lay := Transform3D.IDENTITY # rig space (standing, feet at 0) -> lying on the ground
	match pose:
		Pose.PRONE:
			lay = Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, 0.16, Humanoid.HIP_HEIGHT))
		Pose.SUPINE:
			lay = Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.16, -Humanoid.HIP_HEIGHT))
		Pose.SIDE:
			lay = Transform3D(Basis(Vector3.FORWARD, PI / 2.0) * Basis(Vector3.RIGHT, -PI / 2.0),
				Vector3(0, 0.27, Humanoid.HIP_HEIGHT))
			c[J.HIP_L] = 0.9
			c[J.KNEE_L] = -1.2
			c[J.SH_L_X] = 1.2
		Pose.SITTING: # back against something behind it (+Z), legs out in front
			c[J.HIPS_Y] = 0.14
			c[J.HIP_L] = rng.randf_range(1.35, 1.55)
			c[J.HIP_R] = rng.randf_range(1.35, 1.55)
			c[J.KNEE_L] = rng.randf_range(-0.5, 0.0)
			c[J.KNEE_R] = rng.randf_range(-0.5, 0.0)
			c[J.SPINE_PITCH] = rng.randf_range(-0.2, 0.3)
			c[J.NECK_PITCH] = rng.randf_range(0.4, 0.9)
			c[J.SH_L_X] = rng.randf_range(0.0, 0.5)
			c[J.SH_R_X] = rng.randf_range(0.0, 0.5)
			c[J.SH_L_OUT] = 0.15
			c[J.SH_R_OUT] = 0.15
	rig._apply()
	for seg: Dictionary in rig.segs.values():
		var mi: MeshInstance3D = seg.mesh
		var t := Transform3D.IDENTITY
		var n: Node3D = mi
		while n != rig:
			t = n.transform * t
			n = n.get_parent()
		b.st.append_from(mi.mesh, 0, xf * lay * t)
	rig.free()
