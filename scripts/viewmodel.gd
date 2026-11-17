class_name Viewmodel
extends Node3D
## The gun you see in first person, plus two boxy arms. Child of the camera.
##
## Like the zombie rig, nothing snaps: each pose (hip, aiming, sprint carry, reloading, lowered)
## has a weight that eases between 0 and 1, and the gun sits at the blend. Recoil is a spring on
## top. The magazine, the action (slide / pump / bolt) and the left hand are driven by WeaponState
## timers, so the animation always matches what the gun is really doing.

const CARRY_HIGH_POS := Vector3(0.13, -0.3, -0.44)   ## muzzle up by the shoulder, ready to drop on target
const CARRY_HIGH_ROT := Vector3(1.0, 0.25, -0.15)
const CARRY_LOW_POS := Vector3(0.2, -0.42, -0.55)    ## muzzle down across the body
const CARRY_LOW_ROT := Vector3(-0.5, 0.55, 0.2)
const RELOAD_SHIFT := Vector3(-0.03, 0.03, 0.03)
const LOWERED_SHIFT := Vector3(0.0, -0.3, 0.05)     ## off-screen, while swapping guns
const LOWERED_ROT := Vector3(-0.9, 0.0, 0.0)
const STOW_TIME := 0.12                              ## seconds to drop the gun out of the way or bring it back
const ELBOW_R := Vector3(0.36, -0.6, 0.15)           ## where the forearms come from (camera space)
const ELBOW_L := Vector3(-0.22, -0.62, 0.1)
## Putting on a bandage: [left hand, right hand] in camera space. The left forearm is held across the
## body, the right hand goes round it: beside, over, behind, under, and round again.
const HEAL_POSES := [
	[Vector3(-0.05, -0.2, -0.4), Vector3(0.09, -0.18, -0.37)],
	[Vector3(-0.04, -0.21, -0.4), Vector3(-0.01, -0.12, -0.41)],
	[Vector3(-0.05, -0.2, -0.39), Vector3(-0.12, -0.17, -0.42)],
	[Vector3(-0.04, -0.19, -0.4), Vector3(0.0, -0.26, -0.35)],
]
const HEAL_ELBOW_L := Vector3(-0.42, -0.36, -0.22)  ## the left forearm lies across the body
const HEAL_ELBOW_R := Vector3(0.36, -0.42, -0.04)
const BANDAGE := Color(0.92, 0.9, 0.84)
const SHIMMER_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float strength = 0.006;
void fragment() {
	vec2 wob = vec2(sin(TIME * 23.0 + UV.y * 31.0), cos(TIME * 19.0 + UV.x * 27.0)) * strength * (1.0 - UV.y);
	ALBEDO = texture(screen, SCREEN_UV + wob).rgb;
	ALPHA = smoothstep(0.0, 0.35, UV.x) * smoothstep(1.0, 0.65, UV.x) * smoothstep(0.0, 0.3, 1.0 - UV.y);
}
"""
const SLEEVE := Color(0.1, 0.12, 0.08)
const GLOVE := Color(0.05, 0.05, 0.05)

var pivot: Node3D          ## moves and tilts; the gun hangs under it
var gun: GunModel
var weapon_id := -1
var aim := 0.0             ## 0 = hip, 1 = sights up
var sprint := 0.0
var reload_w := 0.0
var lower := 0.0
var kick_pos := 0.0        ## 1 right after a shot, decays to 0
var kick_rot := Vector3.ZERO ## (climb, sideways, roll): the random part of the recoil
var dry := 0.0             ## 1 right after a click on an empty gun, runs down to 0
var shove_t := -1.0         ## seconds into a shove (-1 = none)
var stow := 0.0            ## 0..1: the gun is down and out of the way (hands busy: vaulting)
var stow_goal := 0.0       ## where `stow` is easing to; the player sets this, never the pose
var heal := 0.0            ## 0..1: the gun is down and the hands are putting something on
var heal_goal := 0.0       ## where `heal` is easing to (the player sets it from its status)
var heal_t := 0.0          ## seconds into the heal: which pose the hands are at
var bandage: MeshInstance3D ## the roll in the right hand while healing
var bob := 0.0
signal eject(at: Vector3, vel: Vector3, kind: int) ## a spent case leaves the port (the game drops it)
signal handling(what: String) ## a part of handling the gun with its own sound: "mag_out", "bolt_back", "draw"...
signal mag_dropped(at: Vector3, vel: Vector3) ## the old magazine falls out (the game drops it)
signal smoke(at: Vector3, count: int, thin: bool) ## puffs at the muzzle, in the world (the game makes them)

var flash: MuzzleFlash
var shimmer: MeshInstance3D ## the air wobbling over a hot barrel
var heat := 0.0            ## shots' worth of heat in the barrel, cooling
var wisp_left := 0.0       ## seconds a hot barrel still shimmers and smokes after a burst
var light: OmniLight3D
var arm_r: Node3D
var arm_l: Node3D

var _pending := -1
var _light_t := 0.0
var _eject_pending := false ## a pump or bolt gun throws its case when the action is worked
var scope_break := 0.0     ## 0..1: working a bolt takes the eye off the scope
var inspect_t := -1.0      ## seconds into looking the gun over (-1: not)
var chamber_peek := 0.0    ## 0..1: the action held open to look in the chamber
var _reload_done: Array[String] = []
var _was_reloading := false
var _last_rounds := -1
var _pump_fwd_in := -1.0
var _cycle_armed := false
var _cycle_done: Array[String] = []
var _idle_t := 0.0
var _idle_next := 0.0
var _idle_goal := Vector3.ZERO
var _idle_rot_goal := Vector3.ZERO
var _idle_off := Vector3.ZERO
var _idle_rot := Vector3.ZERO
var _since_fire := 100.0
var _hot := false
var _wisp_t := 0.0
var _rng := RandomNumberGenerator.new()
var _last_rot := Vector3.ZERO
var _sway := Vector2.ZERO


func _init() -> void:
	pivot = Node3D.new()
	add_child(pivot)
	arm_r = _make_arm()
	arm_l = _make_arm()
	var bb := MeshKit.Builder.new()
	bb.box(Vector3(0.04, 0.04, 0.03), Vector3(0, 0.04, -0.02), BANDAGE)
	bb.box(Vector3(0.022, 0.004, 0.05), Vector3(-0.012, 0.062, 0.01), BANDAGE) # the strip running off it
	bandage = bb.instance(null, false)
	bandage.visible = false
	add_child(bandage)

	flash = MuzzleFlash.create(Weapons.Flash.ROUND)
	pivot.add_child(flash)
	light = OmniLight3D.new()
	light.light_color = Config.MUZZLE_LIGHT_COLOR
	light.omni_range = Config.MUZZLE_LIGHT_RANGE
	light.light_energy = 0
	light.shadow_enabled = false
	pivot.add_child(light)
	shimmer = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.1, 0.32)
	shimmer.mesh = q
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHIMMER_SHADER
	sm.shader = sh
	shimmer.material_override = sm
	shimmer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shimmer.visible = false
	pivot.add_child(shimmer)


## A hand and a forearm. The node sits at the hand; the forearm runs back along +Z to the elbow.
func _make_arm() -> Node3D:
	var b := MeshKit.Builder.new()
	b.box(Vector3(0.06, 0.065, 0.1), Vector3(0, 0, 0.02), GLOVE)
	b.box(Vector3(0.07, 0.07, 0.6), Vector3(0, 0, 0.36), SLEEVE)
	var mi := b.instance(null, false)
	add_child(mi)
	return mi


## Switch the model. Mid-game the old gun drops first and the new one comes up (see `update`).
func show_weapon(id: int) -> void:
	if gun == null:
		_swap(id)
	else:
		_pending = id
		inspect_t = -1.0
		handling.emit("holster")


func _swap(id: int) -> void:
	if gun:
		gun.queue_free()
	var first := gun == null
	gun = Guns.build(id)
	weapon_id = id
	_pending = -1
	pivot.add_child(gun)
	if not first:
		handling.emit("draw")
	flash.shape = Weapons.flash_shape(id)
	flash.mesh = MuzzleFlash.mesh_for(flash.shape) if flash.shape != Weapons.Flash.NONE else null
	flash.position = gun.muzzle + Vector3(0, 0, -0.02)
	light.position = gun.muzzle + Vector3(0, 0.05, -0.1)
	shimmer.position = gun.muzzle + Vector3(0, 0.14, 0.12)


## A shot went off: kick the gun, with a different sideways twist every time.
func fire() -> void:
	kick_pos = 1.0
	kick_rot = Vector3(1.0, _rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0))
	flash.fire(_rng)
	inspect_t = -1.0
	_cycle_armed = Weapons.def(weapon_id).cycle != Weapons.Cycle.BLOWBACK
	_cycle_done.clear()
	var suppressed := flash.shape == Weapons.Flash.NONE
	_light_t = 0.0 if suppressed else Config.MUZZLE_LIGHT_TIME
	heat += 1.0
	_since_fire = 0.0
	if heat >= Config.HEAT_SHOTS:
		_hot = true
	smoke.emit(muzzle_world(), 1 if suppressed else 2 + _rng.randi() % 2, suppressed)
	if Weapons.def(weapon_id).cycle == Weapons.Cycle.BLOWBACK:
		_eject()
	else:
		_eject_pending = true


## The spent case flies out of the port the gun's own way, with a wisp of smoke.
func _eject() -> void:
	_eject_pending = false
	if gun == null or not is_inside_tree():
		return
	var e: Array = Weapons.GUN_EJECT[weapon_id]
	var at := pivot.global_transform * (e[0] as Vector3)
	var vel := pivot.global_basis * (e[1] as Vector3).normalized() * float(e[2])
	vel += Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.2))
	eject.emit(at, vel, Weapons.casing_kind(weapon_id))
	smoke.emit(at, 1, true)


## Where the muzzle is in the world (for the smoke).
func muzzle_world() -> Vector3:
	if gun == null or not is_inside_tree():
		return global_position if is_inside_tree() else Vector3.ZERO
	return pivot.global_transform * gun.muzzle


## A shove: the gun is pulled back, driven forward with a roll and swings home past its rest.
func shove() -> void:
	shove_t = 0.0


## Where the gun is pushed `t` seconds into a shove (camera space, added to the pose).
func shove_pose(t: float) -> Vector3:
	var z := 0.0
	if t < 0.0 or t >= Config.SHOVE_TIME:
		return Vector3.ZERO
	if t < 0.08: # pull back
		z = 0.06 * _ease(t / 0.08)
	elif t < 0.18: # thrust
		z = lerpf(0.06, -0.18, _ease((t - 0.08) / 0.1))
	else: # recover, overshooting home, settled by the end
		var u := t - 0.18
		var span := Config.SHOVE_TIME - 0.18
		z = -0.18 * exp(-12.0 * u) * cos(TAU * u / span) * (1.0 - u / span)
	return Vector3(0.0, -z * 0.2, z)


## How far the gun is rolled `t` seconds into a shove.
func shove_roll(t: float) -> float:
	return 0.5 * sin(PI * clampf((t - 0.04) / 0.2, 0.0, 1.0)) if t >= 0.0 else 0.0


## The trigger was pulled on an empty gun: a small twitch, no kick.
func dry_fire() -> void:
	dry = 1.0


static func _ease(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)


## Where the hands are `t` seconds into a heal: [left, right], eased from pose to pose, each held
## exactly on its beat (`Config.HEAL_POSE_TIME` apart).
static func heal_hands(t: float) -> Array:
	var ph := maxf(t, 0.0) / Config.HEAL_POSE_TIME
	var k := floori(ph)
	var f := ph - k
	if absf(ph - roundf(ph)) < 1e-5:
		k = roundi(ph)
		f = 0.0
	var a: Array = HEAL_POSES[k % HEAL_POSES.size()]
	if f == 0.0:
		return a.duplicate()
	var b: Array = HEAL_POSES[(k + 1) % HEAL_POSES.size()]
	var w := _ease(f)
	return [(a[0] as Vector3).lerp(b[0], w), (a[1] as Vector3).lerp(b[1], w)]


## A reload's parts for a magazine gun: [progress, what], each with its own sound; an empty one also
## racks the charging handle at the end.
static func reload_events(empty: bool) -> Array:
	if empty:
		return [[0.05, "mag_release"], [0.13, "mag_out"], [0.5, "mag_in"], [0.62, "mag_slap"], [0.86, "bolt_rack"]]
	return [[0.06, "mag_release"], [0.16, "mag_out"], [0.6, "mag_in"], [0.74, "mag_slap"]]


## The moves of a pump or a bolt after a shot: [seconds after the shot, what].
static func cycle_events(d: Dictionary) -> Array:
	var a := 0.18
	var b: float = float(d.interval) - 0.12
	if d.cycle == Weapons.Cycle.BOLT:
		return [[a, "bolt_up"], [a + 0.3 * (b - a), "bolt_back"], [a + 0.6 * (b - a), "bolt_fwd"], [b - 0.05, "bolt_down"]]
	if d.cycle == Weapons.Cycle.PUMP:
		return [[a + 0.25 * (b - a), "pump_back"], [a + 0.65 * (b - a), "pump_fwd"]]
	return []


## Turn the gun over to look at it: a roll one way, the other, then the chamber. False while busy.
func inspect() -> bool:
	if gun == null or reload_w > 0.1 or aim > 0.1 or lower > 0.1:
		return false
	inspect_t = 0.0
	handling.emit("inspect")
	return true


func _drop_mag() -> void:
	if gun == null or gun.mag == null or not is_inside_tree():
		return
	mag_dropped.emit(gun.mag.global_position, pivot.global_basis * Vector3(0.2, -1.2, 0.3))


## 0 → 1 → 0 as `x` goes from `from` to `to`.
static func _pulse(x: float, from: float, to: float) -> float:
	return sin(clampf((x - from) / (to - from), 0.0, 1.0) * PI)


## Each part of a reload, a pump or a bolt says so once (`handling`), as it happens.
func _handling_events(d: Dictionary, ws: WeaponState, reloading: bool, style_mag: bool, empty: bool, u: float, delta: float) -> void:
	if reloading and style_mag:
		for ev: Array in reload_events(empty):
			if u >= float(ev[0]) and not _reload_done.has(ev[1]):
				_reload_done.append(ev[1])
				handling.emit(ev[1])
				if ev[1] == "mag_out":
					_drop_mag()
	if not style_mag and (reloading or _was_reloading):
		var r := ws.rounds()
		if _last_rounds >= 0 and r > _last_rounds:
			for k in r - _last_rounds:
				handling.emit("shell_in")
		if _was_reloading and not reloading and d.cycle == Weapons.Cycle.PUMP and ws.since_shot > float(d.interval):
			handling.emit("pump_back") # loaded: rack it
			_pump_fwd_in = 0.15
	if _pump_fwd_in >= 0.0:
		_pump_fwd_in -= delta
		if _pump_fwd_in < 0.0:
			handling.emit("pump_fwd")
	if not reloading:
		_reload_done.clear()
	_was_reloading = reloading
	_last_rounds = ws.rounds()
	if _cycle_armed:
		var all_done := true
		for ev: Array in cycle_events(d):
			if _cycle_done.has(ev[1]):
				continue
			if ws.since_shot >= float(ev[0]):
				_cycle_done.append(ev[1])
				handling.emit(ev[1])
			else:
				all_done = false
		if all_done:
			_cycle_armed = false


func update(delta: float, move_speed: float, aiming: bool, sprinting: bool, ws: WeaponState) -> void:
	if gun == null:
		return
	var d := Weapons.def(weapon_id)
	var reloading := ws.is_reloading()

	# Swapping guns: the first half of the draw time lowers the old one, the second raises the new.
	var draw := clampf(ws.draw_left / ws.draw_total, 0.0, 1.0)
	if _pending >= 0 and draw <= 0.5:
		_swap(_pending)
		d = Weapons.def(weapon_id)
	lower = clampf((1.0 - draw) * 2.0 if _pending >= 0 else draw * 2.0, 0.0, 1.0)

	# Pose weights ease toward where they should be.
	var carried := sprinting and not aiming and not reloading and ws.since_shot > Config.SPRINT_FIRE_HOLD
	aim = move_toward(aim, 1.0 if aiming and not reloading else 0.0, delta / Config.ADS_TIME)
	sprint = move_toward(sprint, 1.0 if carried else 0.0, delta / Config.SPRINT_POSE_TIME)
	reload_w = move_toward(reload_w, 1.0 if reloading else 0.0, delta / 0.2)

	var high: bool = d.carry == Weapons.Carry.HIGH
	var pos := gun.hip
	var rot := Vector3.ZERO
	var ads_pos := Vector3(-gun.sight.x, -gun.sight.y, -gun.ads_dist - gun.sight.z)
	# Working a bolt takes the eye off the scope for a moment.
	scope_break = _pulse(ws.since_shot, 0.18, float(d.interval) - 0.12) if d.cycle == Weapons.Cycle.BOLT else 0.0
	var w := _ease(aim) * (1.0 - 0.85 * scope_break)
	pos = pos.lerp(ads_pos, w)
	w = _ease(sprint)
	pos = pos.lerp(CARRY_HIGH_POS if high else CARRY_LOW_POS, w)
	rot = rot.lerp(CARRY_HIGH_ROT if high else CARRY_LOW_ROT, w)
	w = _ease(reload_w)
	pos = pos.lerp(gun.hip + RELOAD_SHIFT, w)
	rot = rot.lerp(gun.reload_rot, w)
	w = _ease(lower)
	pos = pos.lerp(gun.hip + LOWERED_SHIFT, w)
	rot = rot.lerp(LOWERED_ROT, w)
	stow = move_toward(stow, stow_goal, delta / STOW_TIME)
	w = _ease(stow)
	pos = pos.lerp(gun.hip + LOWERED_SHIFT, w)
	rot = rot.lerp(LOWERED_ROT, w)
	heal = move_toward(heal, heal_goal, delta / Config.HEAL_LOWER_TIME)
	w = _ease(heal)
	pos = pos.lerp(gun.hip + LOWERED_SHIFT, w)
	rot = rot.lerp(LOWERED_ROT, w)

	# Working the action: slide and charging handles snap, a pump or bolt is worked by hand.
	var cyc := 0.0
	var manual: bool = d.cycle != Weapons.Cycle.BLOWBACK
	var interval: float = d.interval
	if manual:
		cyc = _pulse(ws.since_shot, 0.18, interval - 0.12)
	else:
		cyc = _pulse(ws.since_shot, 0.0, minf(0.08, interval))
	var u := ws.reload_progress() if reloading else 1.0
	var style_mag: bool = d.reload_style == Weapons.Reload.MAG
	var empty := ws.reload_empty
	if reloading and style_mag and empty:
		cyc = maxf(cyc, _pulse(u, 0.84, 0.97)) # an empty gun: rack it after the new magazine is in
	if inspect_t >= 0.0:
		cyc = maxf(cyc, 0.6 * chamber_peek)
	_handling_events(d, ws, reloading, style_mag, empty, u, delta)
	if gun.action:
		gun.action.position = gun.action_travel * cyc
	if _eject_pending and cyc >= 0.6: # the pump or the bolt is back: out it goes
		_eject()
	if d.cycle == Weapons.Cycle.BOLT:
		rot += Vector3(0.06, 0.0, -0.3) * cyc * (1.0 - aim)

	# Magazine: out, away, a fresh one back in.
	var out := 0.0
	if reloading and style_mag:
		if empty: # quicker with the magazine, then the charging handle
			out = smoothstep(0.12, 0.3, u) - smoothstep(0.42, 0.6, u)
			rot.x += 0.12 * _pulse(u, 0.6, 0.7) # the slap that seats it
		else:
			out = smoothstep(0.14, 0.34, u) - smoothstep(0.52, 0.76, u)
			rot.x += 0.12 * _pulse(u, 0.74, 0.84)
	if gun.mag:
		gun.mag.position = gun.mag_out * out

	# Recoil spring, walking bob, and the gun lagging a little behind the view.
	kick_pos = maxf(0.0, kick_pos - delta * 12.0 * kick_pos - delta * 0.5)
	var recoil: float = d.recoil
	var strength := clampf(recoil * 5.0, 0.03, 0.22) * (1.0 - 0.5 * aim)
	pos.z += kick_pos * (0.03 + strength * 0.25)
	rot += Vector3(kick_rot.x, kick_rot.y * 0.35, kick_rot.z * 0.5) * kick_pos * strength
	if shove_t >= 0.0:
		shove_t += delta
		pos += shove_pose(shove_t)
		rot.z += shove_roll(shove_t)
		if shove_t >= Config.SHOVE_TIME:
			shove_t = -1.0
	dry = maxf(0.0, dry - delta / Config.DRY_FIRE_TIME)
	rot += Vector3(-1.0, 0.0, 0.6) * Config.DRY_FIRE_TWITCH * sin(dry * PI) * (1.0 - 0.5 * aim)
	# Looking the gun over: a roll one way, the other, then the chamber held open.
	if inspect_t >= 0.0:
		inspect_t += delta
		if aiming or reloading or sprinting or inspect_t >= Config.INSPECT_TIME:
			inspect_t = -1.0
			chamber_peek = 0.0
		else:
			var k := inspect_t / Config.INSPECT_TIME
			rot.z += 0.75 * _pulse(k, 0.0, 0.35) - 0.7 * _pulse(k, 0.3, 0.65)
			chamber_peek = _pulse(k, 0.62, 0.98)
			rot.y += 0.35 * chamber_peek
			pos += Vector3(-0.04, 0.03, 0.03) * chamber_peek
	# Idle life: breathing, and the hands shifting on the grip now and then.
	_idle_t += delta
	_idle_next -= delta
	if _idle_next <= 0.0:
		_idle_next = _rng.randf_range(2.5, 4.5)
		_idle_goal = Vector3(_rng.randf_range(-0.006, 0.006), _rng.randf_range(-0.005, 0.005), _rng.randf_range(-0.004, 0.004))
		_idle_rot_goal = Vector3(_rng.randf_range(-0.03, 0.03), _rng.randf_range(-0.03, 0.03), _rng.randf_range(-0.04, 0.04))
	var settle := 1.0 - exp(-2.5 * delta)
	_idle_off = _idle_off.lerp(_idle_goal, settle)
	_idle_rot = _idle_rot.lerp(_idle_rot_goal, settle)
	var calm := (1.0 - 0.85 * _ease(aim)) * (1.0 - clampf(move_speed / 2.0, 0.0, 1.0)) * (1.0 - _ease(reload_w))
	pos += (Vector3(0.0, sin(_idle_t * 1.7) * 0.0035, 0.0) + _idle_off) * calm
	rot += _idle_rot * calm
	bob += delta * move_speed * 1.6
	var amount := minf(move_speed / 5.0, 1.6) * (1.0 - 0.85 * aim)
	pos += Vector3(cos(bob) * 0.012, absf(sin(bob)) * 0.015, 0.0) * amount
	rot.z += sin(bob) * 0.03 * sprint
	var now_rot := global_rotation
	if delta > 0.0:
		var turn := Vector2(wrapf(now_rot.y - _last_rot.y, -PI, PI), now_rot.x - _last_rot.x) / delta
		_sway = _sway.lerp((turn * 0.012).limit_length(0.06), 1.0 - exp(-10.0 * delta))
	_last_rot = now_rot
	rot += Vector3(-_sway.y, -_sway.x, _sway.x * 0.5) * (1.0 - 0.7 * aim)

	pivot.position = pos
	pivot.rotation = rot

	# Hands. Right stays on the grip (or works the bolt); left holds the front, the pump, the
	# magazine during a reload, or feeds shells.
	var right := gun.grip
	var left := gun.support
	if d.cycle == Weapons.Cycle.PUMP:
		left += gun.action_travel * cyc
	elif d.cycle == Weapons.Cycle.BOLT and gun.action:
		right = right.lerp(Vector3(0.06, 0.04, 0.11) + gun.action.position, cyc)
	if reloading and style_mag:
		var grab := smoothstep(0.04, 0.14, u) - smoothstep(0.76, 0.9, u)
		left = left.lerp(gun.mag_at + gun.mag_out * out, grab)
	elif reloading:
		left = (gun.port + Vector3(-0.05, -0.28, 0.1)).lerp(gun.port, _pulse(u, 0.0, 1.0))
	var hand_r := pivot.transform * right
	var hand_l := pivot.transform * left
	var elbow_l := ELBOW_L
	var elbow_r := ELBOW_R
	if heal > 0.0: # the hands leave the gun for the wound
		var hh := heal_hands(heal_t)
		w = _ease(heal)
		hand_l = hand_l.lerp(hh[0], w)
		hand_r = hand_r.lerp(hh[1], w)
		elbow_l = ELBOW_L.lerp(HEAL_ELBOW_L, w)
		elbow_r = ELBOW_R.lerp(HEAL_ELBOW_R, w)
	_place_arm(arm_r, hand_r, elbow_r)
	_place_arm(arm_l, hand_l, elbow_l)
	bandage.visible = heal > 0.5
	if bandage.visible:
		bandage.transform = arm_r.transform

	flash.step(delta)
	_light_t -= delta
	light.light_energy = Config.MUZZLE_LIGHT_ENERGY if _light_t > 0.0 else 0.0
	# A hot barrel: once the burst stops, the air over it wobbles and a thin wisp rises for a while.
	_since_fire += delta
	heat = maxf(0.0, heat - Config.HEAT_COOL * delta)
	if _hot and _since_fire > 0.2:
		_hot = false
		wisp_left = Config.HEAT_WISP_TIME
	if wisp_left > 0.0:
		wisp_left = maxf(0.0, wisp_left - delta)
		_wisp_t -= delta
		if _wisp_t <= 0.0:
			_wisp_t = Config.HEAT_WISP_EVERY
			smoke.emit(muzzle_world(), 1, true)
	shimmer.visible = wisp_left > 0.0


func _place_arm(arm: Node3D, hand: Vector3, elbow: Vector3) -> void:
	var dir := hand - elbow
	if dir.length() < 0.01:
		return
	arm.transform = Transform3D(Basis.looking_at(dir, Vector3.UP), hand)
