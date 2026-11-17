class_name Humanoid
extends Node3D
## Low-poly humanoid with a real joint chain (hips, spine, neck, shoulders, elbows, hips, knees)
## and fully procedural animation. ~1.8 m tall, stands on y=0, faces -Z.
##
## The body is round: every part is a smooth loft through the ring tables below (made once,
## shared by every rig), painted face by face, plus a face (brow, eyes, nose, mouth, ears).
## A zombie's face has sunken dark sockets, glowing eyes and a gaping mouth with teeth.
##
## How animation works: each frame the current Anim writes a *goal pose* (one float per joint
## angle, see J). The rig eases its current pose toward the goal, so every state change blends
## smoothly by itself. A damped spring adds flinches on top when it gets shot.
##
## Body parts can be severed (sever) or all handed over to a ragdoll (take_all).
##
## style keys: zombie (bool), skin, shirt, pants, shoes, sole, hands (Color), eyes (Color, glowing),
##   brows (Color, a living face's eyebrows), scale (float), limp (0..1),
##   sleeve (Color, default shirt), sleeves ("short", "long" or "none"), forearm (Color, overrides),
##   belt (Color).
## Paint (MeshKit.Body.add rules, in the part's own space): head_paint, torso_paint,
##   upper_arm_paint, forearm_paint, hand_paint, thigh_paint, shin_paint, shoe_paint. Limb keys
##   go on both sides; `<part>_l_paint` / `<part>_r_paint` on one.
## Stains (blood: MeshKit.Body.stain, lying on the surface, with drips), [at, radius, color,
##   drip, layer] where `at` is any point straight out from the part's axis: head_stains,
##   torso_stains, upper_arm_stains, forearm_stains, thigh_stains, shin_stains (and _l / _r).
## Extras, merged into the part they sit on (a hat leaves with the head): head_extras,
##   torso_extras, upper_arm_extras, forearm_extras, thigh_extras, shin_extras (both sides),
##   each [size, pos, color] (a box) or [size, pos, color, kind, rot: Basis] where kind is a
##   MeshKit.unit ("box", "ball", "dome", "tube") or a shape of this rig ("hair_cap").
## Placing things on the round body: `chest(x, y)`, `back(x, y)`, `face(x, y)`.

enum Part { HEAD, TORSO, ARM_L, ARM_R, LEG_L, LEG_R }
enum Anim { IDLE, WALK, RUN, ATTACK, WINDUP, LEAP, LAND, STAGGER, CRAWL, CROUCH, JUMP, HEAL, DOWNED, GETUP }
## Pose channels. "PITCH" = lean forward/down, limbs: positive swings forward, knees bend negative.
enum J { HIPS_Y, HIPS_PITCH, HIPS_ROLL, SPINE_PITCH, SPINE_YAW, SPINE_ROLL,
	NECK_PITCH, NECK_YAW, NECK_ROLL, SH_L_X, SH_L_OUT, SH_R_X, SH_R_OUT, EL_L, EL_R,
	HIP_L, HIP_R, KNEE_L, KNEE_R, COUNT }

const HIP_HEIGHT := 0.92
## Where each joint sits on its parent at rest (tools/models builds models on the same joints).
const NECK_AT := Vector3(0, 0.64, 0)
const SHOULDER_AT := Vector3(0.33, 0.58, 0)   # the right one; the left is mirrored
const ELBOW_AT := Vector3(0, -0.32, 0)
const HIP_AT := Vector3(0.12, 0, 0)            # the right one
const KNEE_AT := Vector3(0, -0.45, 0)
## A model rig's segments: name -> [part, parent segment, joint, hitbox size, hitbox centre].
const MODEL_SEGMENTS := {
	"torso": [Part.TORSO, "", "spine", Vector3(0.5, 0.62, 0.28), Vector3(0, 0.31, 0)],
	"head": [Part.HEAD, "torso", "neck", Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0)],
	"upper_arm_l": [Part.ARM_L, "torso", "shoulder_l", Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0)],
	"forearm_l": [Part.ARM_L, "upper_arm_l", "elbow_l", Vector3(0.13, 0.36, 0.15), Vector3(0, -0.18, 0)],
	"upper_arm_r": [Part.ARM_R, "torso", "shoulder_r", Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0)],
	"forearm_r": [Part.ARM_R, "upper_arm_r", "elbow_r", Vector3(0.13, 0.36, 0.15), Vector3(0, -0.18, 0)],
	"thigh_l": [Part.LEG_L, "torso", "hip_l", Vector3(0.19, 0.45, 0.21), Vector3(0, -0.225, 0)],
	"shin_l": [Part.LEG_L, "thigh_l", "knee_l", Vector3(0.17, 0.47, 0.2), Vector3(0, -0.235, 0)],
	"thigh_r": [Part.LEG_R, "torso", "hip_r", Vector3(0.19, 0.45, 0.21), Vector3(0, -0.225, 0)],
	"shin_r": [Part.LEG_R, "thigh_r", "knee_r", Vector3(0.17, 0.47, 0.2), Vector3(0, -0.235, 0)],
}
## The bone a part hangs from on a model rig (shrunk to nothing when the part is shot off).
const PART_BONE := { Part.HEAD: "neck", Part.ARM_L: "shoulder_l", Part.ARM_R: "shoulder_r",
	Part.LEG_L: "hip_l", Part.LEG_R: "hip_r" }
## The part each limb joint of a model rig belongs to, by bone (CharacterModel.JOINTS).
const JOINT_PART := { 3: Part.ARM_L, 4: Part.ARM_L, 5: Part.ARM_R, 6: Part.ARM_R,
	7: Part.LEG_L, 8: Part.LEG_L, 9: Part.LEG_R, 10: Part.LEG_R }
const BLOOD := Color("7a0a0a")
const MOUTH := Color("2a0606")
const TEETH := Color("d6cfa4")

# Ring tables: [y, half-width, half-depth, depth offset (+ is back)] in the part's space, bottom up.
const TORSO_RINGS := [[-0.06, 0.14, 0.095], [0.02, 0.18, 0.115], [0.08, 0.182, 0.115],
	[0.14, 0.175, 0.112], [0.2, 0.178, 0.117, -0.003], [0.26, 0.186, 0.124, -0.006],
	[0.32, 0.196, 0.13, -0.008], [0.38, 0.208, 0.135, -0.01], [0.44, 0.222, 0.14, -0.01],
	[0.5, 0.236, 0.138, -0.006], [0.56, 0.246, 0.128], [0.61, 0.222, 0.11, 0.006],
	[0.655, 0.145, 0.085, 0.01], [0.685, 0.075, 0.065, 0.012]]
const TORSO_POWER := 2.5
const HEAD_RINGS := [[0.02, 0.06, 0.06, -0.04], [0.045, 0.095, 0.1, -0.03], [0.08, 0.115, 0.125, -0.016],
	[0.12, 0.127, 0.137, -0.008], [0.165, 0.135, 0.148, -0.002], [0.21, 0.139, 0.153, 0.004],
	[0.255, 0.136, 0.15, 0.008], [0.295, 0.122, 0.137, 0.011], [0.325, 0.095, 0.108, 0.012],
	[0.345, 0.055, 0.065, 0.012]]
const HEAD_POWER := 2.3
const HAIR_RINGS := [[0.245, 0.147, 0.162, 0.009], [0.28, 0.142, 0.157, 0.012], [0.31, 0.128, 0.143, 0.014],
	[0.336, 0.1, 0.114, 0.015], [0.356, 0.058, 0.068, 0.015]]
const UPPER_ARM_RINGS := [[-0.345, 0.032, 0.034], [-0.32, 0.052, 0.055], [-0.25, 0.056, 0.059],
	[-0.16, 0.062, 0.066], [-0.08, 0.07, 0.073], [-0.02, 0.074, 0.077], [0.035, 0.064, 0.068], [0.06, 0.035, 0.035]]
const FOREARM_RINGS := [[-0.25, 0.03, 0.032], [-0.235, 0.037, 0.039], [-0.19, 0.042, 0.044],
	[-0.12, 0.049, 0.051], [-0.05, 0.055, 0.057], [0.01, 0.052, 0.054], [0.035, 0.036, 0.038]]
const HAND_RINGS := [[-0.328, 0.024, 0.048], [-0.3, 0.031, 0.056], [-0.258, 0.034, 0.054], [-0.232, 0.03, 0.044]]
const THIGH_RINGS := [[-0.47, 0.042, 0.045], [-0.43, 0.063, 0.068], [-0.32, 0.074, 0.079],
	[-0.2, 0.083, 0.089], [-0.08, 0.089, 0.096], [0.03, 0.091, 0.098], [0.08, 0.08, 0.085]]
const SHIN_RINGS := [[-0.39, 0.033, 0.034], [-0.36, 0.045, 0.047], [-0.28, 0.051, 0.054],
	[-0.18, 0.06, 0.067, 0.006], [-0.08, 0.067, 0.074, 0.008], [0.0, 0.066, 0.07], [0.035, 0.056, 0.06]]
## The shoe runs heel to toe; rings are [along, half-width, half-height, height offset].
const SHOE_RINGS := [[0.0, 0.042, 0.03], [0.015, 0.056, 0.046], [0.09, 0.06, 0.047, -0.003],
	[0.17, 0.064, 0.042, -0.008], [0.23, 0.06, 0.033, -0.014], [0.262, 0.045, 0.022, -0.02],
	[0.272, 0.025, 0.012, -0.022]]
const SLEEVE_END := -0.13   # a short sleeve covers the upper arm down to here
const PELVIS_TOP := 0.07    # trousers come up the torso to here
const SOLE_TOP := -0.452    # shin space: a shoe's faces under this are sole

static var _shapes := {}
static var _eye_mats := {}

var is_zombie := false
var anim: int = Anim.IDLE
var anim_t := 0.0     ## seconds since the current anim started
var phase := 0.0      ## walk-cycle phase
var reach := 0.0      ## 0..1: a downed survivor's free arm reaching out to a teammate (a goal, eased like the rest)
var flinch := Vector2.ZERO  ## (pitch, yaw) spring offset from being hit
var segs := {}        ## name -> { name, part, parent, node, mesh, size, center, hitbox? }
var severed_mask := 0

var hips: Node3D
var spine: Node3D
var neck: Node3D
var shoulder_l: Node3D
var shoulder_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var hip_l: Node3D
var hip_r: Node3D
var knee_l: Node3D
var knee_r: Node3D

## Set on a rig made from a model (create_model): the skinned body and its bones. The joints
## above still carry the pose; _apply copies it onto the bones.
var skeleton: Skeleton3D
var body_mesh: MeshInstance3D
var _bone_nodes: Array[Node3D] = []

var _goal := PackedFloat32Array()
var _cur := PackedFloat32Array()
var _flinch_vel := Vector2.ZERO
var _limp := 0.0
var _tilt := 0.0
var _arm_bias := 0.0
var _seed := 0.0
var _stagger_side := 1.0


static func create(style: Dictionary) -> Humanoid:
	var h := Humanoid.new()
	h._build(style)
	return h


## A rig wearing a model (one skinned, textured mesh made by tools/models) instead of style
## boxes. `style` still gives zombie, limp and scale.
static func create_model(model: CharacterModel, style: Dictionary) -> Humanoid:
	var h := Humanoid.new()
	h._build_model(model, style)
	return h


## Free the meshes of severed segments nobody wants (e.g. a late joiner's catch-up).
static func discard(severed: Array) -> void:
	for seg: Dictionary in severed:
		(seg.mesh as Node).queue_free()


# --- Construction -------------------------------------------------------------

func _joint(parent: Node3D, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.position = pos
	parent.add_child(j)
	return j


func _seg(seg_name: String, part: int, parent_seg: String, node: Node3D, size: Vector3,
		center: Vector3, b: MeshKit.Body) -> MeshInstance3D:
	var mi := b.instance()
	node.add_child(mi)
	segs[seg_name] = { "name": seg_name, "part": part, "parent": parent_seg, "node": node,
		"mesh": mi, "size": size, "center": center }
	return mi


## The body's round shapes, made once and shared by every rig.
static func shape(shape_name: String) -> MeshKit.Shape:
	if _shapes.has(shape_name):
		return _shapes[shape_name]
	var sh: MeshKit.Shape
	match shape_name:
		"torso": sh = MeshKit.loft(TORSO_RINGS, 16, TORSO_POWER)
		"head": sh = MeshKit.loft(HEAD_RINGS, 16, HEAD_POWER, [0.0, 0.01])
		"hair_cap": sh = MeshKit.loft(HAIR_RINGS, 16, HEAD_POWER, [null, 0.01])
		"neck": sh = MeshKit.loft([[-0.05, 0.06, 0.062], [0.07, 0.055, 0.058, -0.01]], 10, 2.0, [null, null])
		"upper_arm": sh = MeshKit.loft(UPPER_ARM_RINGS, 8, 2.2, [0.0, 0.012])
		"forearm": sh = MeshKit.loft(FOREARM_RINGS, 8, 2.2)
		"thigh": sh = MeshKit.loft(THIGH_RINGS, 8, 2.2)
		"shin": sh = MeshKit.loft(SHIN_RINGS, 8, 2.2)
		"shoe":
			sh = MeshKit.Shape.new().merge(MeshKit.loft(SHOE_RINGS, 8, 2.8),
				Transform3D(Basis(Vector3.RIGHT, -PI / 2.0), Vector3(0, -0.425, 0.085))).finish(8)
		"hand": # a mitten of a palm (thumb forward, palm to the body) and four fingers
			sh = MeshKit.Shape.new().merge(MeshKit.loft(HAND_RINGS, 8, 2.6))
			var box := MeshKit.unit("box")
			for k in 4:
				sh.merge(box, Transform3D(Basis.from_scale(Vector3(0.026, 0.066 - absf(k - 1.5) * 0.008, 0.02)),
					Vector3(0, -0.352 + absf(k - 1.5) * 0.004, -0.033 + k * 0.022)))
			sh.merge(box, Transform3D(Basis(Vector3.RIGHT, 0.45) * Basis.from_scale(Vector3(0.024, 0.056, 0.024)),
				Vector3(0, -0.282, -0.054)))
			sh.finish(8)
	_shapes[shape_name] = sh
	return sh


## The surface of a round part at (x, y), on its front (side -1) or back (+1), `out` metres proud.
static func _surface(rings: Array, power: float, x: float, y: float, side: float, out: float) -> Vector3:
	var r := MeshKit.ring_at(rings, y)
	var u := clampf(absf(x) / r.x, 0.0, 1.0)
	var z := r.z + side * (r.y * pow(1.0 - pow(u, power), 1.0 / power) + out)
	return Vector3(x, y, z)


## A point on the front of the torso (spine space): where a badge or a pocket goes.
static func chest(x: float, y: float, out := 0.0) -> Vector3:
	return _surface(TORSO_RINGS, TORSO_POWER, x, y, -1.0, out)


static func back(x: float, y: float, out := 0.0) -> Vector3:
	return _surface(TORSO_RINGS, TORSO_POWER, x, y, 1.0, out)


## A point on the front of the head (neck space): where glasses or a mask go.
static func face(x: float, y: float, out := 0.0) -> Vector3:
	return _surface(HEAD_RINGS, HEAD_POWER, x, y, -1.0, out)


static func _eye_material(c: Color) -> Material:
	if not _eye_mats.has(c):
		_eye_mats[c] = MeshKit.emissive(c, 3.0)
	return _eye_mats[c]


## A style's paint rules for one part (and side).
static func _paints(s: Dictionary, part_name: String, side := "") -> Array:
	var out: Array = s.get(part_name + "_paint", []).duplicate()
	if side != "":
		out.append_array(s.get(part_name + "_" + side + "_paint", []))
	return out


## Lay a style's stains (`<part>_stains`, `<part>_<side>_stains`: [at, radius, color, drip, layer])
## on the part's round shape.
static func _stains(b: MeshKit.Body, s: Dictionary, part_name: String, side := "") -> void:
	var sh := shape(part_name)
	var list: Array = s.get(part_name + "_stains", []).duplicate()
	if side != "":
		list.append_array(s.get(part_name + "_" + side + "_stains", []))
	for st: Array in list:
		b.stain(sh, st[0], st[1], st[2], st[3] if st.size() > 3 else 0.0, st[4] if st.size() > 4 else 0)


func _build(s: Dictionary) -> void:
	var skin: Color = s.get("skin", Color("e0b48a"))
	var shirt: Color = s.get("shirt", Color("3366cc"))
	var pants: Color = s.get("pants", Color("2d3a4a"))
	_traits(s)
	hips = _joint(self, Vector3(0, HIP_HEIGHT, 0))
	spine = _joint(hips, Vector3.ZERO)
	var paint := [[Vector3(-1, -1, -1), Vector3(1, PELVIS_TOP, 1), pants]]
	if s.has("belt"):
		paint.append([Vector3(-1, PELVIS_TOP, -1), Vector3(1, 0.115, 1), s.belt])
	var tb := MeshKit.Body.new().add(shape("torso"), shirt, paint + _paints(s, "torso"))
	_stains(tb, s, "torso")
	_extras(tb, s, "torso_extras")
	_seg("torso", Part.TORSO, "", spine, Vector3(0.5, 0.62, 0.28), Vector3(0, 0.31, 0), tb)

	neck = _joint(spine, NECK_AT)
	var hb := MeshKit.Body.new().add(shape("head"), skin, _face_paint(skin) + _paints(s, "head"))
	hb.add(shape("neck"), skin, [])
	_stains(hb, s, "head")
	_face(hb, s, skin)
	_extras(hb, s, "head_extras") # hats, hair, masks: one mesh with the head, so they leave with it
	var head := _seg("head", Part.HEAD, "torso", neck, Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0), hb)
	if s.has("eyes") and is_zombie:
		var eb := MeshKit.Body.new()
		for x in [-0.054, 0.054]:
			eb.box(Vector3(0.032, 0.022, 0.01), face(x, 0.176, 0.012), s.eyes)
		head.add_child(eb.instance(_eye_material(s.eyes), false)) # child of head: goes with it

	shoulder_l = _joint(spine, SHOULDER_AT * Vector3(-1, 1, 1))
	shoulder_r = _joint(spine, SHOULDER_AT)
	elbow_l = _arm("l", Part.ARM_L, shoulder_l, skin, shirt, s)
	elbow_r = _arm("r", Part.ARM_R, shoulder_r, skin, shirt, s)
	hip_l = _joint(hips, HIP_AT * Vector3(-1, 1, 1))
	hip_r = _joint(hips, HIP_AT)
	knee_l = _leg("l", Part.LEG_L, hip_l, pants, s)
	knee_r = _leg("r", Part.LEG_R, hip_r, pants, s)
	_finish(s)


## What every rig takes from its style: zombie or not, the limp, a random tilt and arm swing.
func _traits(s: Dictionary) -> void:
	is_zombie = s.get("zombie", false)
	_limp = s.get("limp", 0.0)
	_seed = randf() * 10.0
	_tilt = randf_range(-0.3, 0.3) if is_zombie else 0.0
	_arm_bias = randf_range(-0.35, 0.35) if is_zombie else 0.0
	phase = _seed


func _finish(s: Dictionary) -> void:
	if s.has("scale"):
		scale = Vector3.ONE * float(s.scale)
	_goal.resize(J.COUNT)
	_cur.resize(J.COUNT)
	_write_goal(0.0)
	for i in J.COUNT:
		_cur[i] = _goal[i]
	_apply()


## The joints, a skeleton copying them, the shared skinned mesh on it, and per segment a hidden
## rigid piece of the model riding its joint (shown when the segment is shot off or ragdolls).
func _build_model(model: CharacterModel, s: Dictionary) -> void:
	_traits(s)
	var m := Vector3(-1, 1, 1)
	hips = _joint(self, Vector3(0, HIP_HEIGHT, 0))
	spine = _joint(hips, Vector3.ZERO)
	neck = _joint(spine, NECK_AT)
	shoulder_l = _joint(spine, SHOULDER_AT * m)
	elbow_l = _joint(shoulder_l, ELBOW_AT)
	shoulder_r = _joint(spine, SHOULDER_AT)
	elbow_r = _joint(shoulder_r, ELBOW_AT)
	hip_l = _joint(hips, HIP_AT * m)
	knee_l = _joint(hip_l, KNEE_AT)
	hip_r = _joint(hips, HIP_AT)
	knee_r = _joint(hip_r, KNEE_AT)
	_bone_nodes = [hips, spine, neck, shoulder_l, elbow_l, shoulder_r, elbow_r, hip_l, knee_l, hip_r, knee_r]
	skeleton = model.make_skeleton()
	add_child(skeleton)
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	body_mesh.mesh = model.mesh
	body_mesh.skin = model.skin
	body_mesh.material_override = model.material
	skeleton.add_child(body_mesh)
	body_mesh.skeleton = NodePath("..")
	for seg_name: String in MODEL_SEGMENTS:
		var d: Array = MODEL_SEGMENTS[seg_name]
		var node: Node3D = _bone_nodes[CharacterModel.JOINTS.find(d[2])]
		var piece := MeshInstance3D.new()
		piece.mesh = model.parts[seg_name]
		piece.material_override = model.material
		piece.visible = false
		node.add_child(piece)
		segs[seg_name] = { "name": seg_name, "part": d[0], "parent": d[1], "node": node,
			"mesh": piece, "size": d[3], "center": d[4] }
	_finish(s)


## Merge a style's extras (clothes, hats, hair) into the mesh being built for one part.
func _extras(b: MeshKit.Body, s: Dictionary, key: String) -> void:
	for e: Array in s.get(key, []):
		var kind: String = e[3] if e.size() > 3 else "box"
		var rot: Basis = e[4] if e.size() > 4 else Basis.IDENTITY
		if kind in ["box", "ball", "dome", "tube"]:
			b.part(kind, e[0], e[1], e[2], rot)
		else:
			b.put(shape(kind), Transform3D(rot * Basis.from_scale(e[0]), e[1]), e[2])


## Shading painted onto the head: a zombie's hollow cheeks and the bruised ring round its eyes.
func _face_paint(skin: Color) -> Array:
	if not is_zombie:
		return []
	var hollow := skin.darkened(0.16)
	var bruise := skin.darkened(0.28).lerp(Color("4a2a3a"), 0.2)
	return [
		[Vector3(-0.15, 0.08, -1), Vector3(-0.06, 0.15, -0.04), hollow],
		[Vector3(0.06, 0.08, -1), Vector3(0.15, 0.15, -0.04), hollow],
		[Vector3(-0.11, 0.14, -1), Vector3(-0.03, 0.2, -0.09), bruise],
		[Vector3(0.03, 0.14, -1), Vector3(0.11, 0.2, -0.09), bruise],
	]


## Brow, eyes, nose, mouth and ears, in the head's mesh.
func _face(b: MeshKit.Body, s: Dictionary, skin: Color) -> void:
	for x in [-0.14, 0.14]:
		b.box(Vector3(0.03, 0.062, 0.048), Vector3(x, 0.165, 0.012), skin.darkened(0.12)) # ears
	b.box(Vector3(0.036, 0.058, 0.042), face(0, 0.13, -0.008), skin.darkened(0.06), Basis(Vector3.RIGHT, 0.35)) # nose
	if is_zombie:
		for x in [-0.054, 0.054]:
			b.box(Vector3(0.082, 0.026, 0.03), face(x, 0.214, -0.004), skin.darkened(0.3),
				Basis(Vector3.FORWARD, 0.22 * signf(x))) # heavy brows, sloping in to a frown
			b.box(Vector3(0.07, 0.05, 0.02), face(x, 0.176, -0.005), skin.darkened(0.75).lerp(Color("1e0e16"), 0.4)) # sockets
			if not s.has("eyes"):
				b.box(Vector3(0.03, 0.02, 0.01), face(x, 0.176, 0.009), Color("bdb898")) # dead, milky eyes
		b.box(Vector3(0.088, 0.06, 0.03), face(0, 0.078, -0.01), MOUTH) # the jaw hangs open
		for i in 3:
			b.box(Vector3(0.024, 0.02 - i % 2 * 0.004, 0.012), face(-0.028 + i * 0.028, 0.099 - i % 2 * 0.002, 0.008), TEETH)
		for i in 2:
			b.box(Vector3(0.026, 0.016, 0.012), face(-0.016 + i * 0.032, 0.056, 0.006), TEETH)
	else:
		b.box(Vector3(0.22, 0.026, 0.04), face(0, 0.214, -0.012), skin.darkened(0.05)) # brow
		var brows: Color = s.get("brows", Color("3a2a1a"))
		for x in [-0.052, 0.052]:
			b.box(Vector3(0.034, 0.018, 0.008), face(x, 0.176, 0.0), Color("ece8de")) # whites
			b.box(Vector3(0.016, 0.017, 0.006), face(x, 0.176, 0.006), Color("2a1a10")) # irises
			b.box(Vector3(0.056, 0.013, 0.012), face(x, 0.207, 0.008), brows)
		b.box(Vector3(0.062, 0.012, 0.01), face(0, 0.083, 0.0), skin.darkened(0.35).lerp(Color("8a3a30"), 0.3))


func _arm(side: String, part: int, shoulder: Node3D, skin: Color, shirt: Color, s: Dictionary) -> Node3D:
	var sleeve: Color = s.get("sleeve", shirt)
	var sleeves: String = s.get("sleeves", "short")
	var paint := []
	if sleeves == "short":
		paint.append([Vector3(-1, -1, -1), Vector3(1, SLEEVE_END, 1), skin])
	var ub := MeshKit.Body.new().add(shape("upper_arm"), skin if sleeves == "none" else sleeve,
		paint + _paints(s, "upper_arm", side))
	_stains(ub, s, "upper_arm", side)
	_extras(ub, s, "upper_arm_extras")
	_seg("upper_arm_" + side, part, "torso", shoulder, Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0), ub)
	var elbow := _joint(shoulder, Vector3(0, -0.32, 0))
	var lower: Color = s.get("forearm", sleeve if sleeves == "long" else skin)
	var fb := MeshKit.Body.new().add(shape("forearm"), lower, _paints(s, "forearm", side))
	_stains(fb, s, "forearm", side)
	fb.add(shape("hand"), s.get("hands", skin.darkened(0.08)), _paints(s, "hand", side))
	_extras(fb, s, "forearm_extras")
	_seg("forearm_" + side, part, "upper_arm_" + side, elbow, Vector3(0.13, 0.36, 0.15), Vector3(0, -0.18, 0), fb)
	return elbow


func _leg(side: String, part: int, hip: Node3D, pants: Color, s: Dictionary) -> Node3D:
	var tb := MeshKit.Body.new().add(shape("thigh"), pants, _paints(s, "thigh", side))
	_stains(tb, s, "thigh", side)
	_extras(tb, s, "thigh_extras")
	_seg("thigh_" + side, part, "torso", hip, Vector3(0.19, 0.45, 0.21), Vector3(0, -0.225, 0), tb)
	var knee := _joint(hip, Vector3(0, -0.45, 0))
	var shoes: Color = s.get("shoes", Color("222222"))
	var sb := MeshKit.Body.new().add(shape("shin"), pants, _paints(s, "shin", side))
	_stains(sb, s, "shin", side)
	sb.add(shape("shoe"), shoes, [[Vector3(-1, -1, -1), Vector3(1, SOLE_TOP, 1), s.get("sole", shoes.darkened(0.5))]]
		+ _paints(s, "shoe", side))
	_extras(sb, s, "shin_extras")
	_seg("shin_" + side, part, "thigh_" + side, knee, Vector3(0.17, 0.47, 0.2), Vector3(0, -0.235, 0), sb)
	return knee


# --- Parts: hitboxes, severing, ragdoll hand-over -------------------------------

## Adds one Area3D per segment that bullets can hit. Each carries metas "zombie" and "part".
func add_hitboxes(owner_zombie: Node) -> void:
	for seg: Dictionary in segs.values():
		var area := Area3D.new()
		area.collision_layer = Config.LAYER_HITBOX
		area.collision_mask = 0
		area.monitoring = false
		area.set_meta("zombie", owner_zombie)
		area.set_meta("part", seg.part)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = (seg.size as Vector3) * 1.15 # slightly generous
		cs.shape = shape
		area.add_child(cs)
		area.position = seg.center
		(seg.node as Node3D).add_child(area)
		seg.hitbox = area


func is_severed(part: int) -> bool:
	return severed_mask & (1 << part) != 0


func has_arms() -> bool:
	return not (is_severed(Part.ARM_L) and is_severed(Part.ARM_R))


func legs_lost() -> int:
	return int(is_severed(Part.LEG_L)) + int(is_severed(Part.LEG_R))


## The joint a part hangs from (where the wound is).
func part_root(part: int) -> Node3D:
	match part:
		Part.HEAD: return neck
		Part.ARM_L: return shoulder_l
		Part.ARM_R: return shoulder_r
		Part.LEG_L: return hip_l
		Part.LEG_R: return hip_r
	return spine


## Cut a part off. Returns its segments (meshes still attached to the rig; the caller turns
## them into gibs or discards them). Leaves a bloody stump. The torso can't be severed.
func sever(part: int) -> Array:
	var out := []
	if part == Part.TORSO or is_severed(part):
		return out
	severed_mask |= 1 << part
	for seg_name: String in segs.keys():
		var seg: Dictionary = segs[seg_name]
		if seg.part == part:
			if seg.has("hitbox"):
				(seg.hitbox as Node).queue_free()
				seg.erase("hitbox")
			out.append(seg)
			segs.erase(seg_name)
			(seg.mesh as Node3D).visible = true # a model rig's rigid piece, ready to fly
	if skeleton:
		skeleton.set_bone_pose_scale(skeleton.find_bone(PART_BONE[part]), Vector3.ONE * 0.001)
	var root := part_root(part)
	var stump := MeshKit.Body.new().part("tube", Vector3(0.15, 0.06, 0.15), Vector3.ZERO, BLOOD).instance(null, false)
	stump.position = root.position
	root.get_parent().add_child(stump)
	return out


## Hand every remaining segment to the caller (used to build the ragdoll). The rig is empty after.
func take_all() -> Array:
	var out := segs.values()
	for seg: Dictionary in out:
		if seg.has("hitbox"):
			(seg.hitbox as Node).queue_free()
			seg.erase("hitbox")
		(seg.mesh as Node3D).visible = true
	if body_mesh:
		body_mesh.visible = false # the rigid pieces take over
	segs = {}
	return out


# --- Animation ----------------------------------------------------------------

func set_anim(a: int) -> void:
	if a == anim:
		return
	anim = a
	anim_t = 0.0
	_stagger_side = -1.0 if randf() < 0.5 else 1.0


## Shove the upper body: `dir_local` is the push direction in the rig's space, strength ~0..1.5.
func hit_react(dir_local: Vector3, strength: float) -> void:
	_flinch_vel += Vector2(dir_local.z, -dir_local.x) * strength * 9.0


func update(delta: float, speed: float) -> void:
	anim_t += delta
	phase += delta * _phase_rate(speed)
	_write_goal(speed)
	var k := 1.0 - exp(-_blend_rate() * delta)
	for i in J.COUNT:
		_cur[i] = lerpf(_cur[i], _goal[i], k)
	# Critically-damped-ish spring pulls the flinch back to zero.
	_flinch_vel += (-flinch * 140.0 - _flinch_vel * 14.0) * delta
	flinch += _flinch_vel * delta
	flinch = flinch.limit_length(0.9)
	_apply()


func _blend_rate() -> float:
	match anim:
		Anim.ATTACK: return 20.0
		Anim.STAGGER: return 24.0
		Anim.LEAP: return 14.0
		Anim.CRAWL: return 6.0
		Anim.DOWNED: return 4.0 # a slow fall to the ground
		Anim.GETUP: return 7.0
	return 10.0


func _stride_amp() -> float:
	return 0.8 if anim == Anim.RUN else 0.5


func _phase_rate(speed: float) -> float:
	match anim:
		Anim.WALK, Anim.RUN:
			# Match leg swing to ground speed so feet don't slide.
			return maxf(1.5, PI * speed / (2.0 * HIP_HEIGHT * sin(_stride_amp())))
		Anim.CRAWL:
			return 2.0 + speed * 5.0
		Anim.CROUCH:
			return 2.0 + speed * 3.0
	return 2.0


func _apply() -> void:
	hips.position.y = _cur[J.HIPS_Y]
	hips.rotation = Vector3(-_cur[J.HIPS_PITCH], 0, _cur[J.HIPS_ROLL])
	spine.rotation = Vector3(-_cur[J.SPINE_PITCH] + flinch.x, _cur[J.SPINE_YAW] + flinch.y, _cur[J.SPINE_ROLL])
	neck.rotation = Vector3(-_cur[J.NECK_PITCH] + flinch.x * 0.6, _cur[J.NECK_YAW], _cur[J.NECK_ROLL])
	shoulder_l.rotation = Vector3(_cur[J.SH_L_X], 0, -_cur[J.SH_L_OUT])
	shoulder_r.rotation = Vector3(_cur[J.SH_R_X], 0, _cur[J.SH_R_OUT])
	elbow_l.rotation.x = _cur[J.EL_L]
	elbow_r.rotation.x = _cur[J.EL_R]
	hip_l.rotation.x = _cur[J.HIP_L]
	hip_r.rotation.x = _cur[J.HIP_R]
	knee_l.rotation.x = _cur[J.KNEE_L]
	knee_r.rotation.x = _cur[J.KNEE_R]
	if skeleton:
		for b in _bone_nodes.size():
			skeleton.set_bone_pose_rotation(b, _bone_nodes[b].quaternion)
		skeleton.set_bone_pose_position(0, hips.position)
		# Clothes' helpers turn half as far as their joints; a shot-off limb's stays at rest, so
		# the ring of cloth it holds closes the stump where the clothes were cut.
		for h: int in CharacterModel.HELPER_OF:
			var j: int = CharacterModel.HELPER_OF[h]
			var q := Quaternion.IDENTITY
			if not is_severed(JOINT_PART[j]):
				q = q.slerp(_bone_nodes[j].quaternion, 0.5)
			skeleton.set_bone_pose_rotation(h, q)


func _crouch(depth: float) -> void:
	# depth 0..1: thighs forward, shins back, hips drop so the feet stay planted.
	var a := depth * 1.1
	_goal[J.HIP_L] = a
	_goal[J.HIP_R] = a
	_goal[J.KNEE_L] = -2.0 * a
	_goal[J.KNEE_R] = -2.0 * a
	_goal[J.HIPS_Y] = HIP_HEIGHT * cos(a)


func _write_goal(speed: float) -> void:
	_goal.fill(0.0)
	_goal[J.HIPS_Y] = HIP_HEIGHT
	var p := phase
	var s := sin(p)
	var c := cos(p)
	match anim:
		Anim.IDLE:
			if is_zombie:
				_goal[J.SPINE_PITCH] = 0.28 + sin(p * 0.7) * 0.05
				_goal[J.SPINE_ROLL] = sin(p * 0.45 + _seed) * 0.08
				_goal[J.NECK_ROLL] = _tilt + sin(p * 0.6) * 0.15
				_goal[J.NECK_PITCH] = -0.1
				_goal[J.SH_L_X] = 0.3 + _arm_bias
				_goal[J.SH_R_X] = 0.2 - _arm_bias
				_goal[J.EL_L] = 0.4
				_goal[J.EL_R] = 0.6
				_goal[J.KNEE_L] = -0.12
				_goal[J.HIP_L] = 0.06
			else:
				_goal[J.SPINE_PITCH] = 0.04 + sin(p * 0.8) * 0.015
				_goal[J.SH_L_X] = 0.9
				_goal[J.SH_R_X] = 1.0
				_goal[J.EL_L] = 0.7
				_goal[J.EL_R] = 0.5

		Anim.WALK, Anim.RUN:
			var amp := _stride_amp() * clampf(speed / 0.8, 0.0, 1.0)
			var stiff := 1.0 - _limp * 0.5 # the limping (right) leg swings less
			_goal[J.HIP_L] = s * amp
			_goal[J.HIP_R] = -s * amp * stiff
			_goal[J.KNEE_L] = -0.12 - maxf(0.0, c) * 1.0 * amp * 2.0
			_goal[J.KNEE_R] = -0.12 - maxf(0.0, -c) * 1.0 * amp * 2.0 * stiff
			_goal[J.HIPS_Y] = HIP_HEIGHT - 0.05 + absf(c) * 0.05 * amp * 2.0
			_goal[J.HIPS_ROLL] = s * 0.07 + maxf(0.0, -s) * _limp * 0.18 # dips onto the bad leg
			_goal[J.SPINE_YAW] = -s * 0.18
			if is_zombie and anim == Anim.WALK:
				_goal[J.SPINE_PITCH] = 0.32 + sin(p * 2.0) * 0.05
				_goal[J.SPINE_ROLL] = -s * 0.07 - maxf(0.0, -s) * _limp * 0.12
				_goal[J.NECK_PITCH] = -0.25
				_goal[J.NECK_ROLL] = _tilt + sin(p * 0.5 + _seed) * 0.2
				_goal[J.NECK_YAW] = sin(p * 0.31 + _seed) * 0.2
				_goal[J.SH_L_X] = 1.25 + _arm_bias + sin(p * 0.5 + _seed) * 0.15
				_goal[J.SH_R_X] = 1.25 - _arm_bias - sin(p * 0.5 + _seed) * 0.15
				_goal[J.SH_L_OUT] = 0.1
				_goal[J.SH_R_OUT] = 0.1
				_goal[J.EL_L] = 0.25 + sin(p + 1.0) * 0.15
				_goal[J.EL_R] = 0.45 + sin(p + 2.5) * 0.15
			elif is_zombie: # sprinting zombie: thrown forward, arms clawing the air
				_goal[J.SPINE_PITCH] = 0.6 + sin(p * 2.0) * 0.06
				_goal[J.HIPS_PITCH] = 0.15
				_goal[J.NECK_PITCH] = -0.55
				_goal[J.NECK_ROLL] = _tilt * 0.5
				_goal[J.SH_L_X] = 1.5 - s * 0.7
				_goal[J.SH_R_X] = 1.5 + s * 0.7
				_goal[J.SH_L_OUT] = 0.25
				_goal[J.SH_R_OUT] = 0.25
				_goal[J.EL_L] = 0.5 + maxf(0.0, s) * 0.6
				_goal[J.EL_R] = 0.5 + maxf(0.0, -s) * 0.6
			else: # survivor carrying a rifle
				_goal[J.SPINE_PITCH] = 0.06 + speed * 0.02
				_goal[J.SH_L_X] = 0.9 - s * 0.12
				_goal[J.SH_R_X] = 1.0 + s * 0.12
				_goal[J.EL_L] = 0.7
				_goal[J.EL_R] = 0.5

		Anim.ATTACK: # raise both arms, slam down with the whole body, recover
			var t := anim_t
			_goal[J.HIP_L] = 0.5
			_goal[J.KNEE_L] = -0.4
			_goal[J.HIP_R] = -0.35
			_goal[J.KNEE_R] = -0.15
			_goal[J.HIPS_Y] = HIP_HEIGHT - 0.08
			if t < 0.2:
				_goal[J.SPINE_PITCH] = -0.2
				_goal[J.SH_L_X] = 2.9
				_goal[J.SH_R_X] = 2.7
				_goal[J.SH_L_OUT] = 0.3
				_goal[J.SH_R_OUT] = 0.3
				_goal[J.EL_L] = 0.9
				_goal[J.EL_R] = 0.9
				_goal[J.NECK_PITCH] = -0.5
			elif t < 0.45:
				_goal[J.SPINE_PITCH] = 0.85
				_goal[J.SH_L_X] = 0.7
				_goal[J.SH_R_X] = 0.6
				_goal[J.EL_L] = 0.15
				_goal[J.EL_R] = 0.15
				_goal[J.NECK_PITCH] = -0.3
				_goal[J.HIPS_Y] = HIP_HEIGHT - 0.14
			else:
				_goal[J.SPINE_PITCH] = 0.4
				_goal[J.SH_L_X] = 1.2
				_goal[J.SH_R_X] = 1.2
				_goal[J.EL_L] = 0.4
				_goal[J.EL_R] = 0.4

		Anim.WINDUP, Anim.LAND: # coiled crouch (trembling before a leap)
			_crouch(0.85 if anim == Anim.WINDUP else 0.6)
			var jitter := sin(anim_t * 45.0) * 0.03 if anim == Anim.WINDUP else 0.0
			_goal[J.SPINE_PITCH] = 0.75 + jitter
			_goal[J.NECK_PITCH] = -0.7
			_goal[J.SH_L_X] = -0.7 + jitter
			_goal[J.SH_R_X] = -0.7 - jitter
			_goal[J.SH_L_OUT] = 0.4
			_goal[J.SH_R_OUT] = 0.4
			_goal[J.EL_L] = 0.9
			_goal[J.EL_R] = 0.9

		Anim.LEAP: # stretched out, arms reaching, legs trailing
			_goal[J.HIPS_PITCH] = 0.95
			_goal[J.SPINE_PITCH] = 0.15
			_goal[J.NECK_PITCH] = -0.8
			_goal[J.SH_L_X] = 2.7
			_goal[J.SH_R_X] = 2.5
			_goal[J.SH_L_OUT] = 0.2
			_goal[J.SH_R_OUT] = 0.2
			_goal[J.EL_L] = 0.3
			_goal[J.EL_R] = 0.3
			_goal[J.HIP_L] = -0.5
			_goal[J.HIP_R] = -0.2
			_goal[J.KNEE_L] = -0.9
			_goal[J.KNEE_R] = -1.2

		Anim.STAGGER: # knocked back, arms flung wide
			_goal[J.SPINE_PITCH] = -0.4
			_goal[J.SPINE_YAW] = 0.45 * _stagger_side
			_goal[J.NECK_PITCH] = -0.5
			_goal[J.NECK_ROLL] = 0.3 * _stagger_side
			_goal[J.SH_L_X] = -0.3
			_goal[J.SH_R_X] = -0.3
			_goal[J.SH_L_OUT] = 1.0
			_goal[J.SH_R_OUT] = 1.0
			_goal[J.EL_L] = 0.5
			_goal[J.EL_R] = 0.5
			_goal[J.HIP_L] = -0.35
			_goal[J.HIP_R] = 0.4
			_goal[J.KNEE_L] = -0.3
			_goal[J.KNEE_R] = -0.6
			_goal[J.HIPS_Y] = HIP_HEIGHT - 0.1

		Anim.CROUCH: # a survivor on their haunches, gun up; the legs shuffle when they move
			var shuffle := s * 0.25 * clampf(speed / 1.5, 0.0, 1.0)
			_goal[J.HIPS_Y] = HIP_HEIGHT - 0.4
			_goal[J.HIP_L] = 1.15 + shuffle
			_goal[J.HIP_R] = 0.75 - shuffle
			_goal[J.KNEE_L] = -1.7
			_goal[J.KNEE_R] = -1.75
			_goal[J.SPINE_PITCH] = 0.3
			_goal[J.NECK_PITCH] = -0.25
			_goal[J.SH_L_X] = 0.9
			_goal[J.SH_R_X] = 1.0
			_goal[J.EL_L] = 0.7
			_goal[J.EL_R] = 0.5

		Anim.JUMP: # a survivor off the ground: knees tucked, gun held in
			_goal[J.HIP_L] = 0.7
			_goal[J.HIP_R] = 0.35
			_goal[J.KNEE_L] = -1.1
			_goal[J.KNEE_R] = -0.7
			_goal[J.SPINE_PITCH] = 0.12
			_goal[J.SH_L_X] = 0.9
			_goal[J.SH_R_X] = 1.0
			_goal[J.EL_L] = 0.7
			_goal[J.EL_R] = 0.5

		Anim.HEAL: # a survivor wrapping a wound: head down, left forearm across the body, the right hand going round it
			var wrap := anim_t * TAU / (4.0 * Config.HEAL_POSE_TIME)
			_goal[J.SPINE_PITCH] = 0.25
			_goal[J.NECK_PITCH] = 0.7
			_goal[J.NECK_YAW] = 0.2
			_goal[J.SH_L_X] = 0.3
			_goal[J.SH_L_OUT] = -0.3
			_goal[J.EL_L] = 1.25
			_goal[J.SH_R_X] = 0.45 + sin(wrap) * 0.2
			_goal[J.SH_R_OUT] = -0.3 + cos(wrap) * 0.12
			_goal[J.EL_R] = 1.1 + cos(wrap) * 0.25
			_goal[J.KNEE_L] = -0.1
			_goal[J.HIP_L] = 0.05

		Anim.DOWNED: # a survivor on the ground: half lying back, propped on the left arm, the right hand on the wound or reaching out
			_goal[J.HIPS_Y] = 0.2
			_goal[J.HIPS_PITCH] = -1.1
			_goal[J.HIPS_ROLL] = 0.15
			_goal[J.SPINE_PITCH] = 0.6 + sin(p * 0.6) * 0.03 # laboured breathing
			_goal[J.SPINE_ROLL] = -0.15
			_goal[J.NECK_PITCH] = 0.25
			_goal[J.SH_L_X] = -0.55
			_goal[J.SH_L_OUT] = 0.3
			_goal[J.EL_L] = 0.1
			_goal[J.SH_R_X] = lerpf(0.4, 2.0, reach)
			_goal[J.SH_R_OUT] = lerpf(-0.25, 0.1, reach)
			_goal[J.EL_R] = lerpf(1.4, 0.25, reach)
			_goal[J.HIP_L] = 0.35
			_goal[J.KNEE_L] = -0.15
			_goal[J.HIP_R] = 0.6
			_goal[J.KNEE_R] = -0.9

		Anim.GETUP: # back on the feet: a knee and a hand on it first, then standing
			var u := clampf(anim_t / Config.GETUP_TIME, 0.0, 1.0)
			if u < 0.5:
				_goal[J.HIPS_Y] = 0.45
				_goal[J.HIP_L] = 1.4
				_goal[J.KNEE_L] = -2.0
				_goal[J.HIP_R] = -0.2
				_goal[J.KNEE_R] = -1.6
				_goal[J.SPINE_PITCH] = 0.55
				_goal[J.SH_L_X] = 0.6
				_goal[J.EL_L] = 0.5
				_goal[J.SH_R_X] = 0.3
				_goal[J.NECK_PITCH] = -0.2
			else:
				_crouch(0.35 * (1.0 - u) * 2.0)
				_goal[J.SPINE_PITCH] = 0.3 * (1.0 - u) * 2.0
				_goal[J.SH_L_X] = 0.9
				_goal[J.SH_R_X] = 1.0
				_goal[J.EL_L] = 0.7
				_goal[J.EL_R] = 0.5

		Anim.CRAWL: # face down, dragging itself forward one arm at a time
			_goal[J.HIPS_Y] = 0.22
			_goal[J.HIPS_PITCH] = 1.38
			_goal[J.HIPS_ROLL] = s * 0.14
			_goal[J.SPINE_YAW] = s * 0.2
			_goal[J.NECK_PITCH] = -0.95
			_goal[J.NECK_ROLL] = _tilt
			_goal[J.SH_L_X] = 2.75 + s * 0.45
			_goal[J.SH_R_X] = 2.75 - s * 0.45
			_goal[J.SH_L_OUT] = 0.35
			_goal[J.SH_R_OUT] = 0.35
			_goal[J.EL_L] = 0.25 + maxf(0.0, -s) * 0.9
			_goal[J.EL_R] = 0.25 + maxf(0.0, s) * 0.9
			_goal[J.HIP_L] = -0.05 + c * 0.1
			_goal[J.HIP_R] = -0.05 - c * 0.1

	# Missing a leg: it can't stand, so every other state plays lying down. Attacks rear the
	# chest up off the floor before the arms come down; staggers flop it flat.
	if legs_lost() > 0 and anim != Anim.CRAWL:
		var rear := 0.45 if anim == Anim.ATTACK and anim_t < 0.2 else 0.0
		_goal[J.HIPS_Y] = 0.22 + rear * 0.15
		_goal[J.HIPS_PITCH] = 1.38 - rear
		_goal[J.HIPS_ROLL] = 0.0
		_goal[J.SPINE_PITCH] = clampf(_goal[J.SPINE_PITCH], -0.3, 0.3) - rear * 0.5
		_goal[J.NECK_PITCH] = -0.95
		_goal[J.HIP_L] = -0.05
		_goal[J.HIP_R] = -0.05
		_goal[J.KNEE_L] = 0.0
		_goal[J.KNEE_R] = 0.0
		if anim == Anim.IDLE or anim == Anim.STAGGER:
			_goal[J.SH_L_X] = 2.6
			_goal[J.SH_R_X] = 2.6
