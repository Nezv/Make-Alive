class_name RemotePlayer
extends Node3D
## Another player, drawn from interpolated host snapshots.

var peer_id := 0
var rig: Humanoid
var tag: Label3D
var buffer := SnapshotBuffer.new()
var gun: GunModel
var weapon_id := -1
var action := 0 ## PlayerWire.ACTION_* bits from the last snapshot
var hp := 100 ## from the last snapshot (temporary HP included)
var mag := 0 ## rounds in their magazine, from the last snapshot (for spectators)
var flash: MuzzleFlash ## on their gun's muzzle
var display_name := ""
var _down_left := -1.0 ## counted here from when they went down (a guess: the host knows the real clock)
var helper_near := false ## (set by the game) a standing teammate is close enough to get them up
var _was_downed := false
var _getup_left := 0.0
var _last_pos := Vector3.ZERO


static func create(id: int, player_name: String) -> RemotePlayer:
	var r := RemotePlayer.new()
	r.peer_id = id
	r.name = "P%d" % id
	r.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	r.rig = Characters.survivor(id)
	r.add_child(r.rig)
	r.display_name = player_name
	r.tag = Label3D.new()
	r.tag.text = player_name
	r.tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	r.tag.no_depth_test = true
	r.tag.font_size = 48
	r.tag.pixel_size = 0.005
	r.tag.outline_size = 12
	r.tag.position.y = 2.2
	r.add_child(r.tag)
	return r


## Show the gun this player is holding (comes with every snapshot).
func set_weapon(id: int) -> void:
	if id == weapon_id or not Weapons.valid(id):
		return
	weapon_id = id
	if gun:
		gun.queue_free()
	gun = Guns.build(id)
	gun.position = Vector3(0.2, 0.36, -0.3) - gun.grip
	rig.spine.add_child(gun)
	flash = MuzzleFlash.create(Weapons.flash_shape(id))
	flash.position = gun.muzzle + Vector3(0, 0, -0.02)
	gun.add_child(flash)


## Their gun went off: the flash (no light: others' guns are the cheaper tier).
func fired(rng: RandomNumberGenerator) -> void:
	if flash:
		flash.fire(rng)


func muzzle_world() -> Vector3:
	if gun == null or not gun.is_inside_tree():
		return global_position + Vector3(0, 1.4, 0)
	return gun.global_transform * gun.muzzle


## What the body is doing (crouching, off the ground), as PlayerWire.ACTION_* bits.
func set_action(bits: int) -> void:
	action = bits


## The name over their head; a downed one's says how long they have left.
func step_tag(delta: float) -> void:
	if action & PlayerWire.ACTION_DOWNED:
		if _down_left < 0.0:
			_down_left = Config.DOWNED_TIME
		_down_left = maxf(0.0, _down_left - delta)
		tag.text = "%s\n✚ DOWN %d s" % [display_name, ceili(_down_left)]
		tag.modulate = Color("ff7a6a")
	elif _down_left >= 0.0 or tag.text != display_name:
		_down_left = -1.0
		tag.text = display_name
		tag.modulate = Color.WHITE


func _process(delta: float) -> void:
	step_tag(delta)
	if flash:
		flash.step(delta)
	if buffer.is_empty():
		return
	var s := buffer.sample()
	position = s[0]
	rotation.y = s[1]
	var moved := Vector2(position.x - _last_pos.x, position.z - _last_pos.z).length()
	_last_pos = position
	var ground_speed := moved / delta if delta > 0.0 else 0.0
	animate(delta, ground_speed)


## Pick the rig's state and move it on: what the action bits say, a get-up after being downed, a
## reaching hand while a teammate is near enough to help.
func animate(delta: float, ground_speed: float) -> void:
	var downed := action & PlayerWire.ACTION_DOWNED != 0
	if _was_downed and not downed:
		_getup_left = Config.GETUP_TIME
	_was_downed = downed
	var a := anim_for(action, ground_speed)
	if _getup_left > 0.0 and not downed:
		_getup_left = maxf(0.0, _getup_left - delta)
		a = Humanoid.Anim.GETUP
	rig.reach = 1.0 if downed and helper_near else 0.0
	rig.set_anim(a)
	rig.update(delta, ground_speed)


## The rig's state for a player's action bits and how fast they move over the ground.
static func anim_for(bits: int, ground_speed: float) -> int:
	if bits & PlayerWire.ACTION_DOWNED:
		return Humanoid.Anim.CRAWL if ground_speed > 0.3 else Humanoid.Anim.DOWNED
	if bits & PlayerWire.ACTION_AIR:
		return Humanoid.Anim.JUMP
	if bits & PlayerWire.ACTION_HEAL:
		return Humanoid.Anim.HEAL
	if bits & PlayerWire.ACTION_CROUCH:
		return Humanoid.Anim.CROUCH
	if ground_speed > 6.0:
		return Humanoid.Anim.RUN
	if ground_speed > 0.3:
		return Humanoid.Anim.WALK
	return Humanoid.Anim.IDLE
