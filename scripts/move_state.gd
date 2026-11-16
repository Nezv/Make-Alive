class_name MoveState
extends RefCounted
## How one player's body is doing: stamina, crouch, time off the ground, the dip after a landing
## and a vault in progress. Pure logic, no nodes (LocalPlayer feeds it and reads it), so it is easy to test.

var stamina := Config.STAMINA_MAX
var winded := false     ## ran dry: no sprinting until it is back above Config.STAMINA_RECOVER
var crouch := 0.0       ## 0 standing .. 1 crouched, eased
var air_time := 0.0     ## seconds since the feet last touched the floor
var jumped := false     ## this time off the floor began with a jump (so no second one in the air)
var dip := 0.0          ## metres the camera is pushed down by the last landing; springs back
var vault_left := 0.0   ## > 0 while going over cover
var vault_from := Vector3.ZERO
var vault_to := Vector3.ZERO
var vault_top := 0.0    ## height of the cover's top above `vault_from`
var _rest := 0.0        ## seconds since the last sprinting frame
var _peak_y := 0.0      ## the highest the feet were since leaving the floor
var _was_on_floor := true


## One frame. `sprinting`: the player is really running this frame. `feet_y`: height of the feet.
## Returns the height fallen if this frame was a landing (0 otherwise).
func step(delta: float, sprinting: bool, on_floor: bool, wants_crouch: bool, feet_y: float, fall_speed: float) -> float:
	if sprinting:
		stamina = maxf(0.0, stamina - Config.STAMINA_SPRINT_DRAIN * delta)
		_rest = 0.0
		if stamina <= 0.0:
			winded = true
	else:
		_rest += delta
		if _rest >= Config.STAMINA_REST_DELAY:
			stamina = minf(Config.STAMINA_MAX, stamina + Config.STAMINA_REFILL * delta)
		if stamina >= Config.STAMINA_RECOVER:
			winded = false
	crouch = move_toward(crouch, 1.0 if wants_crouch else 0.0, delta / Config.CROUCH_TIME)
	dip = lerpf(dip, 0.0, 1.0 - exp(-Config.LAND_DIP_RECOVER * delta))
	vault_left = maxf(0.0, vault_left - delta)

	var fell := 0.0
	if on_floor:
		if not _was_on_floor:
			fell = maxf(0.0, _peak_y - feet_y)
			land(fall_speed)
		air_time = 0.0
		jumped = false
		_peak_y = feet_y
	else:
		air_time += delta
		_peak_y = maxf(_peak_y, feet_y)
	_was_on_floor = on_floor
	return fell


func can_sprint() -> bool:
	return not winded and stamina > 0.0 and crouch < 0.5 and not is_vaulting()


## Stamina as 0..1 for the HUD.
func stamina_share() -> float:
	return stamina / Config.STAMINA_MAX


## On the floor, or just off an edge (coyote time), and not already jumping.
func can_jump() -> bool:
	return not jumped and air_time <= Config.COYOTE_TIME and not is_vaulting()


func jump() -> void:
	jumped = true
	stamina = maxf(0.0, stamina - Config.STAMINA_JUMP_COST)


## The feet hit the floor at `fall_speed` m/s: the camera dips, harder the faster it was.
func land(fall_speed: float) -> void:
	dip = clampf(fall_speed * Config.LAND_DIP_PER_SPEED, 0.0, Config.LAND_DIP_MAX)


## HP lost for falling `height` metres: nothing up to the safe height, then so much a metre.
static func fall_damage(height: float) -> int:
	return maxi(0, roundi((height - Config.FALL_SAFE_HEIGHT) * Config.FALL_DAMAGE_PER_M))


## Speed on the ground with `weapon` in hand.
func speed(weapon: int, sprinting: bool, aiming: bool) -> float:
	var v := Config.WALK_SPEED
	if sprinting:
		v = Config.SPRINT_SPEED * Weapons.sprint_mult(weapon)
	elif aiming:
		v *= Config.ADS_MOVE_MULT
	return lerpf(v, minf(v, Config.WALK_SPEED * Config.CROUCH_SPEED_MULT), crouch)


## How tall the body is right now (capsule and eyes scale with it).
func height() -> float:
	return lerpf(Config.PLAYER_HEIGHT, Config.CROUCH_HEIGHT, crouch)


func eye_height() -> float:
	return lerpf(Config.EYE_HEIGHT, Config.CROUCH_EYE_HEIGHT, crouch) - dip


## How loud the footsteps are, as a share of a standing walk (crouched steps are quieter).
func step_loudness(sprinting: bool) -> float:
	return lerpf(Config.SPRINT_STEP_LOUDNESS if sprinting else 1.0, Config.CROUCH_STEP_LOUDNESS, crouch)


# --- Vaulting ---------------------------------------------------------------------

func is_vaulting() -> bool:
	return vault_left > 0.0


## Go over cover: from where the feet are to `to` on the far side, clearing a top `top` metres up.
func start_vault(from: Vector3, to: Vector3, top: float) -> void:
	vault_from = from
	vault_to = to
	vault_top = top
	vault_left = Config.VAULT_TIME
	stamina = maxf(0.0, stamina - Config.STAMINA_VAULT_COST)
	jumped = true


## 0 at the start of the vault, 1 when the feet are down on the far side.
func vault_progress() -> float:
	return 1.0 - vault_left / Config.VAULT_TIME


## Where the feet are during the vault: across in a line, up and over the top in an arc.
func vault_point() -> Vector3:
	var t := vault_progress()
	var flat := vault_from.lerp(vault_to, t * t * (3.0 - 2.0 * t))
	var over := sin(t * PI) * (vault_top + Config.VAULT_CLEARANCE)
	return Vector3(flat.x, lerpf(vault_from.y, vault_to.y, t) + over, flat.z)
