class_name Humanoid
extends Node3D
## Blocky humanoid with a real joint chain (hips, spine, neck, shoulders, elbows, hips, knees)
## and fully procedural animation. ~1.8 m tall, stands on y=0, faces -Z.
##
## How animation works: each frame the current Anim writes a *goal pose* (one float per joint
## angle, see J). The rig eases its current pose toward the goal, so every state change blends
## smoothly by itself. A damped spring adds flinches on top when it gets shot.
##
## Body parts can be severed (sever) or all handed over to a ragdoll (take_all).
##
## style keys: zombie (bool), skin, shirt, pants, shoes (Color), eyes (Color, glowing),
##   scale (float), limp (0..1), sleeve / forearm / hands (Color; default shirt / skin / darker skin),
##   clothes as extra boxes merged into the part they sit on, each [size: Vector3, pos: Vector3,
##   color: Color] in that part's space: torso_extras, head_extras, upper_arm_extras,
##   forearm_extras, thigh_extras, shin_extras (limb extras go on both sides)

enum Part { HEAD, TORSO, ARM_L, ARM_R, LEG_L, LEG_R }
enum Anim { IDLE, WALK, RUN, ATTACK, WINDUP, LEAP, LAND, STAGGER, CRAWL, CROUCH, JUMP }
## Pose channels. "PITCH" = lean forward/down, limbs: positive swings forward, knees bend negative.
enum J { HIPS_Y, HIPS_PITCH, HIPS_ROLL, SPINE_PITCH, SPINE_YAW, SPINE_ROLL,
	NECK_PITCH, NECK_YAW, NECK_ROLL, SH_L_X, SH_L_OUT, SH_R_X, SH_R_OUT, EL_L, EL_R,
	HIP_L, HIP_R, KNEE_L, KNEE_R, COUNT }

const HIP_HEIGHT := 0.92
const BLOOD := Color("7a0a0a")

var is_zombie := false
var anim: int = Anim.IDLE
var anim_t := 0.0     ## seconds since the current anim started
var phase := 0.0      ## walk-cycle phase
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
		center: Vector3, b: MeshKit.Builder) -> MeshInstance3D:
	var mi := b.instance()
	node.add_child(mi)
	segs[seg_name] = { "name": seg_name, "part": part, "parent": parent_seg, "node": node,
		"mesh": mi, "size": size, "center": center }
	return mi


func _build(s: Dictionary) -> void:
	is_zombie = s.get("zombie", false)
	var skin: Color = s.get("skin", Color("e0b48a"))
	var shirt: Color = s.get("shirt", Color("3366cc"))
	var pants: Color = s.get("pants", Color("2d3a4a"))
	var shoes: Color = s.get("shoes", Color("222222"))
	_limp = s.get("limp", 0.0)
	_seed = randf() * 10.0
	_tilt = randf_range(-0.3, 0.3) if is_zombie else 0.0
	_arm_bias = randf_range(-0.35, 0.35) if is_zombie else 0.0
	phase = _seed

	hips = _joint(self, Vector3(0, HIP_HEIGHT, 0))
	spine = _joint(hips, Vector3.ZERO)
	var tb := MeshKit.Builder.new().box(Vector3(0.5, 0.62, 0.28), Vector3(0, 0.31, 0), shirt)
	tb.box(Vector3(0.52, 0.08, 0.3), Vector3(0, 0.04, 0), pants) # belt line
	for e: Array in s.get("torso_extras", []):
		tb.box(e[0], e[1], e[2])
	_seg("torso", Part.TORSO, "", spine, Vector3(0.5, 0.62, 0.28), Vector3(0, 0.31, 0), tb)

	neck = _joint(spine, Vector3(0, 0.64, 0))
	var hb := MeshKit.Builder.new().box(Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0), skin)
	hb.box(Vector3(0.2, 0.05, 0.02), Vector3(0, 0.06, -0.151), Color("3a1010") if is_zombie else Color("8a5a4a")) # mouth
	_extras(hb, s, "head_extras") # hats, hair, masks: one mesh with the head, so they leave with it
	if not s.has("eyes"):
		hb.box(Vector3(0.05, 0.05, 0.02), Vector3(-0.07, 0.19, -0.151), Color("111111"))
		hb.box(Vector3(0.05, 0.05, 0.02), Vector3(0.07, 0.19, -0.151), Color("111111"))
	var head := _seg("head", Part.HEAD, "torso", neck, Vector3(0.3, 0.3, 0.3), Vector3(0, 0.15, 0), hb)
	if s.has("eyes"):
		var eb := MeshKit.Builder.new()
		eb.box(Vector3(0.06, 0.04, 0.02), Vector3(-0.07, 0.19, -0.152), s.eyes)
		eb.box(Vector3(0.06, 0.04, 0.02), Vector3(0.07, 0.19, -0.152), s.eyes)
		head.add_child(eb.instance(MeshKit.emissive(s.eyes, 4.0), false)) # child of head: goes with it

	shoulder_l = _joint(spine, Vector3(-0.33, 0.58, 0))
	shoulder_r = _joint(spine, Vector3(0.33, 0.58, 0))
	elbow_l = _arm("l", Part.ARM_L, shoulder_l, skin, shirt, s)
	elbow_r = _arm("r", Part.ARM_R, shoulder_r, skin, shirt, s)
	hip_l = _joint(hips, Vector3(-0.12, 0, 0))
	hip_r = _joint(hips, Vector3(0.12, 0, 0))
	knee_l = _leg("l", Part.LEG_L, hip_l, pants, shoes, s)
	knee_r = _leg("r", Part.LEG_R, hip_r, pants, shoes, s)

	if s.has("scale"):
		scale = Vector3.ONE * float(s.scale)
	_goal.resize(J.COUNT)
	_cur.resize(J.COUNT)
	_write_goal(0.0)
	for i in J.COUNT:
		_cur[i] = _goal[i]
	_apply()


## Merge a style's extra boxes (clothes, hats, stains) into the mesh being built for one part.
func _extras(b: MeshKit.Builder, s: Dictionary, key: String) -> void:
	for e: Array in s.get(key, []):
		b.box(e[0], e[1], e[2])


func _arm(side: String, part: int, shoulder: Node3D, skin: Color, shirt: Color, s: Dictionary) -> Node3D:
	var sleeve: Color = s.get("sleeve", shirt)
	var lower: Color = s.get("forearm", skin)
	var hand: Color = s.get("hands", skin.darkened(0.15))
	var ub := MeshKit.Builder.new().box(Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0), sleeve)
	_extras(ub, s, "upper_arm_extras")
	_seg("upper_arm_" + side, part, "torso", shoulder, Vector3(0.15, 0.32, 0.17), Vector3(0, -0.16, 0), ub)
	var elbow := _joint(shoulder, Vector3(0, -0.32, 0))
	var fb := MeshKit.Builder.new().box(Vector3(0.12, 0.26, 0.14), Vector3(0, -0.13, 0), lower)
	fb.box(Vector3(0.13, 0.1, 0.16), Vector3(0, -0.31, 0), hand)
	_extras(fb, s, "forearm_extras")
	_seg("forearm_" + side, part, "upper_arm_" + side, elbow, Vector3(0.13, 0.36, 0.15), Vector3(0, -0.18, 0), fb)
	return elbow


func _leg(side: String, part: int, hip: Node3D, pants: Color, shoes: Color, s: Dictionary) -> Node3D:
	var tb := MeshKit.Builder.new().box(Vector3(0.19, 0.45, 0.21), Vector3(0, -0.225, 0), pants)
	_extras(tb, s, "thigh_extras")
	_seg("thigh_" + side, part, "torso", hip, Vector3(0.19, 0.45, 0.21), Vector3(0, -0.225, 0), tb)
	var knee := _joint(hip, Vector3(0, -0.45, 0))
	var sb := MeshKit.Builder.new().box(Vector3(0.16, 0.38, 0.18), Vector3(0, -0.19, 0), pants.darkened(0.1))
	sb.box(Vector3(0.18, 0.09, 0.28), Vector3(0, -0.425, -0.04), shoes) # foot
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
	var root := part_root(part)
	var stump := MeshKit.Builder.new().box(Vector3(0.16, 0.08, 0.16), Vector3.ZERO, BLOOD).instance(null, false)
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
