class_name SoundSpot
extends Node3D
## A looping sound fixed in the world: a generator, a lamp's buzz, a car alarm, hazard lights,
## a stuck horn, an engine ticking as it cools, a sign creaking. Made when the map is built,
## never in a fight. Sfx.step_spots plays only the nearest few (Config.SOUND_SPOTS_AUDIBLE) and
## stops the rest, so a street full of them costs a handful of voices.
##
## `period` and `duty`: a spot that comes and goes (an alarm sounding for a while, then resting).
## Its phase comes from where it stands, so every peer hears the same alarm at the same moment of
## its cycle, give or take when they joined.

var sound := ""
var volume_db := 0.0
var period := 0.0   ## seconds of one on-off cycle (0 = always on)
var duty := 1.0     ## share of the cycle it sounds
var reach := Config.SOUND_SPOT_REACH
var clock := 0.0    ## seconds this spot has been running (Sfx.step_spots counts it)
var player: AudioStreamPlayer3D
var _phase := 0.0
var _listed := false


static func make(sound_: String, at: Vector3, volume := 0.0, period_ := 0.0, duty_ := 1.0) -> SoundSpot:
	var s := SoundSpot.new()
	s.sound = sound_
	s.volume_db = volume
	s.period = period_
	s.duty = duty_
	s.position = at
	s.name = "Sound_" + sound_
	return s


func _ready() -> void:
	add_to_group(&"sound_spots")
	player = AudioStreamPlayer3D.new()
	player.stream = Sfx.stream(sound)
	player.bus = &"World"
	player.volume_db = volume_db
	player.unit_size = Config.SFX_UNIT_SIZE
	player.max_distance = reach
	player.attenuation_filter_cutoff_hz = Config.SFX_FAR_CUTOFF_HZ
	player.attenuation_filter_db = Config.SFX_FAR_CUTOFF_DB
	add_child(player)
	var h := absi(hash(Vector3i(roundi(global_position.x), roundi(global_position.y), roundi(global_position.z))))
	_phase = float(h % 10007) / 10007.0 * maxf(period, 0.0)


func _enter_tree() -> void:
	_listed = Sfx.add_spot(self)


func _exit_tree() -> void:
	if _listed:
		Sfx.remove_spot(self)
		_listed = false


## In the on part of its cycle.
func sounding() -> bool:
	return period <= 0.0 or fposmod(clock + _phase, period) < period * duty


func playing() -> bool:
	return player != null and player.playing


## Sfx.step_spots: start or stop it. A spot starts somewhere into its loop, not at the top, so
## two lamps side by side do not buzz in step.
func set_heard(on: bool) -> void:
	if player == null or player.stream == null:
		return
	if on and not player.playing:
		var length := player.stream.get_length()
		player.play(fposmod(clock + _phase * 3.7, maxf(length, 0.01)))
	elif not on and player.playing:
		player.stop()
