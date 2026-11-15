class_name Zombie
extends CharacterBody3D
## One zombie.
## On the host it is the real thing: a physics body with AI (host_step), hit points and
## per-body-part hitboxes. On clients it is a puppet that interpolates host snapshots.
## Both sides animate the same rig from the same `state`, so everyone sees the same moves.

enum Type { WALKER, RUNNER, LEAPER }
enum State { CHASE, ATTACK, WINDUP, LEAP, LAND, STAGGER }

## Per-type stats: [min speed, max speed, hit points]
const STATS := {
	Type.WALKER: [1.6, 2.3, 100],
	Type.RUNNER: [4.6, 5.6, 70],
	Type.LEAPER: [3.0, 3.6, 80],
}

var zid := 0
var type: int = Type.WALKER
var outfit := 0          ## Characters.Outfit: who it used to be (looks only, derived from zid)
var hp := 100
var part_hp := {}
var state: int = State.CHASE
var state_t := 0.0
var speed := 2.0
var lane := 0.0          ## -1..1, which side of the corridor it prefers
var leap_cd := 0.0
var server_side := false
var rig: Humanoid
var buffer := SnapshotBuffer.new()
var est_velocity := Vector3.ZERO ## for clients: movement estimated from snapshots

var _attack_landed := false
var _attack_door: Door = null
var _last_pos := Vector3.ZERO
var _waypoint := Vector3.ZERO ## open maps: where the path says to walk, refreshed a few times a second
var _waypoint_t := 0.0


static func create(id: int, zombie_type: int, on_server: bool, pos: Vector3, severed := 0) -> Zombie:
	var z := Zombie.new()
	z.zid = id
	z.type = zombie_type
	z.name = "Z%d" % id
	z.server_side = on_server
	z.position = pos
	z._last_pos = pos
	var stats: Array = STATS[zombie_type]
	z.speed = randf_range(stats[0], stats[1])
	z.hp = stats[2]
	z.lane = randf_range(-1.0, 1.0)
	z.leap_cd = randf_range(0.5, 2.0)
	z.part_hp = { Humanoid.Part.ARM_L: Config.ARM_HP, Humanoid.Part.ARM_R: Config.ARM_HP,
		Humanoid.Part.LEG_L: Config.LEG_HP, Humanoid.Part.LEG_R: Config.LEG_HP }
	z.outfit = Characters.outfit_for(id, zombie_type)
	z.rig = Characters.zombie(id, zombie_type, z.outfit)
	z.add_child(z.rig)
	for part in Humanoid.Part.values(): # catch-up for limbs lost before we saw it
		if severed & (1 << part):
			Humanoid.discard(z.rig.sever(part))
	if on_server:
		z.collision_layer = Config.LAYER_ZOMBIE
		z.collision_mask = Config.LAYER_WORLD
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = Config.ZOMBIE_RADIUS
		cap.height = 1.7
		cs.shape = cap
		cs.position.y = 0.85
		z.add_child(cs)
		z.rig.add_hitboxes(z)
	else:
		z.collision_layer = 0
		z.collision_mask = 0
		z.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	return z


# --- Queries --------------------------------------------------------------------

func is_crawling() -> bool:
	return rig.legs_lost() > 0


func move_speed() -> float:
	return speed * (Config.CRAWL_SPEED_MULT if is_crawling() else 1.0)


func attack_damage() -> int:
	return int(Config.ZOMBIE_DAMAGE * (1.0 if rig.has_arms() else Config.ARMLESS_DAMAGE_MULT))


func set_state(s: int) -> void:
	state = s
	state_t = 0.0
	_attack_landed = false


# --- Damage (host) ----------------------------------------------------------------

## Apply a bullet to a body part. Returns { killed, severed (part or -1), headshot }.
## This only changes numbers; Game turns the result into blood, gibs and ragdolls on every peer.
func take_hit(part: int, damage: int) -> Dictionary:
	var result := { "killed": false, "severed": -1, "headshot": part == Humanoid.Part.HEAD }
	var body_damage := float(damage)
	if part == Humanoid.Part.HEAD:
		body_damage *= Config.HEAD_MULT
	elif part_hp.has(part):
		body_damage *= Config.LIMB_BODY_MULT
		part_hp[part] -= damage
		if part_hp[part] <= 0 and not rig.is_severed(part):
			result.severed = part
	hp -= int(body_damage)
	if hp <= 0:
		result.killed = true
	elif state != State.LEAP and (result.severed >= 0 or randf() < Config.STAGGER_CHANCE):
		set_state(State.STAGGER)
	return result


# --- AI (host, every physics tick) ----------------------------------------------------

func host_step(delta: float, game: Game) -> void:
	state_t += delta
	leap_cd -= delta
	var target_id := game.nearest_player(global_position)
	var target_pos := global_position
	if target_id != 0:
		target_pos = game.players[target_id].pos
	var to_target := target_pos - global_position
	to_target.y = 0.0
	var move := Vector3.ZERO

	match state:
		State.STAGGER:
			if state_t >= Config.STAGGER_TIME:
				set_state(State.CHASE)
		State.ATTACK:
			_face(to_target if _attack_door == null else _attack_door.global_position - global_position)
			if not _attack_landed and state_t >= Config.ZOMBIE_ATTACK_HIT_AT:
				_attack_landed = true
				if _attack_door != null:
					game.zombie_bashes_door(self, _attack_door)
				else:
					game.zombie_attack_lands(self, target_id)
			if state_t >= Config.ZOMBIE_ATTACK_TIME:
				_attack_door = null
				set_state(State.CHASE)
		State.WINDUP:
			_face(to_target)
			if is_crawling():
				set_state(State.CHASE)
			elif state_t >= Config.LEAP_WINDUP:
				_launch(to_target)
				move = Vector3(velocity.x, 0, velocity.z)
		State.LEAP:
			move = Vector3(velocity.x, 0, velocity.z) # keep flying
			if state_t > 0.15 and is_on_floor():
				game.zombie_leap_lands(self)
				set_state(State.LAND)
				move = Vector3.ZERO
		State.LAND:
			if state_t >= 0.3:
				set_state(State.CHASE)
		State.CHASE:
			if target_id != 0:
				move = _chase(game, target_id, target_pos, to_target)

	velocity.x = move.x
	velocity.z = move.z
	if not is_on_floor():
		velocity.y -= Config.GRAVITY * delta
	elif state != State.LEAP or state_t > 0.15:
		velocity.y = 0.0
	move_and_slide()


func _chase(game: Game, target_id: int, target_pos: Vector3, to_target: Vector3) -> Vector3:
	var here := global_position
	var dist := to_target.length()
	var map := game.map
	var costly := map.nav_refresh > 0.0 # grid maps: line-of-sight and paths aren't free
	var direct := (not costly or dist < Config.DIRECT_CHECK_RANGE) and map.is_direct(here, target_pos)
	var door := map.door_in_the_way(here, target_pos)

	if direct and dist < Config.ZOMBIE_ATTACK_RANGE:
		set_state(State.ATTACK)
		return Vector3.ZERO
	# A closed door between us and dinner: smash it.
	if door != null:
		_attack_door = door
		set_state(State.ATTACK)
		return Vector3.ZERO
	if type == Type.LEAPER and direct and leap_cd <= 0.0 and not is_crawling() \
			and dist > Config.LEAP_MIN and dist < Config.LEAP_MAX and is_on_floor():
		set_state(State.WINDUP)
		return Vector3.ZERO

	var aim := target_pos
	if not direct or not costly:
		_waypoint_t -= get_physics_process_delta_time()
		if not costly or _waypoint_t <= 0.0 or here.distance_to(_waypoint) < 0.6:
			_waypoint = map.nav_target(here, target_pos, lane)
			_waypoint_t = map.nav_refresh * randf_range(0.8, 1.2) # stagger the horde's path queries
		aim = _waypoint
	else:
		_waypoint_t = 0.0
	var way := aim - here
	way.y = 0.0
	var dir := way.normalized() if way.length() > 0.05 else Vector3.ZERO
	# Steer away from neighbours so the horde flows instead of stacking into one blob.
	var push := Vector3.ZERO
	for other: Zombie in game.zombie_list:
		if other == self:
			continue
		var off := here - other.global_position
		off.y = 0.0
		var d := off.length()
		if d < Config.ZOMBIE_SEPARATION:
			push += (off / d if d > 0.01 else Vector3(lane, 0, 0.5)) * (1.0 - d / Config.ZOMBIE_SEPARATION)
	dir = (dir + push * 1.6).limit_length(1.0)
	_face(dir if dir.length() > 0.1 else to_target)
	return dir * move_speed()


func _launch(to_target: Vector3) -> void:
	var air_time := 2.0 * Config.LEAP_UP / Config.GRAVITY
	var horizontal := clampf(to_target.length() / air_time, 4.0, 16.0)
	var v := to_target.normalized() * horizontal
	velocity = Vector3(v.x, Config.LEAP_UP, v.z)
	leap_cd = Config.LEAP_COOLDOWN
	set_state(State.LEAP)


func _face(dir: Vector3) -> void:
	if dir.length_squared() > 0.0025:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.25) # models face -Z


# --- Animation (every peer, every rendered frame) ------------------------------------

func _anim_for_state() -> int:
	match state:
		State.ATTACK: return Humanoid.Anim.ATTACK
		State.WINDUP: return Humanoid.Anim.WINDUP
		State.LEAP: return Humanoid.Anim.LEAP
		State.LAND: return Humanoid.Anim.LAND
		State.STAGGER: return Humanoid.Anim.STAGGER
	if is_crawling():
		return Humanoid.Anim.CRAWL
	return Humanoid.Anim.RUN if type == Type.RUNNER else Humanoid.Anim.WALK


func _process(delta: float) -> void:
	var ground_speed := 0.0
	if server_side:
		ground_speed = Vector2(velocity.x, velocity.z).length()
		est_velocity = velocity
	elif not buffer.is_empty():
		var s := buffer.sample()
		position = s[0]
		rotation.y = s[1]
		if delta > 0.0:
			est_velocity = (position - _last_pos) / delta
		_last_pos = position
		ground_speed = Vector2(est_velocity.x, est_velocity.z).length()
	rig.set_anim(_anim_for_state())
	rig.update(delta, ground_speed)
