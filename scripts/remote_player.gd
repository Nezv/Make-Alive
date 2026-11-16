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
var _last_pos := Vector3.ZERO


static func create(id: int, player_name: String) -> RemotePlayer:
	var r := RemotePlayer.new()
	r.peer_id = id
	r.name = "P%d" % id
	r.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	r.rig = Characters.survivor(id)
	r.add_child(r.rig)
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


## What the body is doing (crouching, off the ground), as PlayerWire.ACTION_* bits.
func set_action(bits: int) -> void:
	action = bits


func _process(delta: float) -> void:
	if buffer.is_empty():
		return
	var s := buffer.sample()
	position = s[0]
	rotation.y = s[1]
	var moved := Vector2(position.x - _last_pos.x, position.z - _last_pos.z).length()
	_last_pos = position
	var ground_speed := moved / delta if delta > 0.0 else 0.0
	var a := Humanoid.Anim.IDLE
	if ground_speed > 6.0:
		a = Humanoid.Anim.RUN
	elif ground_speed > 0.3:
		a = Humanoid.Anim.WALK
	if action & PlayerWire.ACTION_AIR:
		a = Humanoid.Anim.JUMP
	elif action & PlayerWire.ACTION_CROUCH:
		a = Humanoid.Anim.CROUCH
	rig.set_anim(a)
	rig.update(delta, ground_speed)
