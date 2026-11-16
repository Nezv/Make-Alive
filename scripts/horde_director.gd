class_name HordeDirector
extends RefCounted
## Decides when zombies arrive (host only): a slow trickle of stragglers, and every so often
## a horde that grows each wave.

var game: Game
var enabled := true
var wave := 0
var calm_left := 0.0 ## seconds nobody is sent (after a checkpoint)
var heat := 0.0 ## filled by noise (Game.make_noise); full, it brings the next horde sooner
var _trickle := 1.0
var _horde_timer := Config.HORDE_FIRST


func _init(owner_game: Game) -> void:
	game = owner_game


func step(delta: float) -> void:
	heat = maxf(0.0, heat - Config.NOISE_HEAT_DECAY * delta)
	if not enabled:
		return
	if calm_left > 0.0:
		calm_left -= delta
		return
	_trickle -= delta
	if _trickle <= 0.0:
		_trickle = Config.TRICKLE_INTERVAL
		game.spawn_zombie(pick_type(), _spawn_point())
	_horde_timer -= delta
	if _horde_timer <= 0.0:
		_horde_timer = Config.HORDE_INTERVAL
		spawn_horde(horde_size(wave + 1))


## Send nobody for `seconds` (the clocks wait too).
func calm(seconds: float) -> void:
	calm_left = maxf(calm_left, seconds)


## Something loud happened (`loudness` in metres). Enough of it and the next horde will not wait.
func add_heat(loudness: float) -> void:
	heat += loudness * Config.NOISE_HEAT_PER_M
	if heat >= Config.NOISE_HEAT_FULL:
		heat = 0.0
		_horde_timer = minf(_horde_timer, Config.NOISE_HORDE_SOON)


func _spawn_point() -> Vector3:
	var avoid := []
	for p: Dictionary in game.players.values():
		avoid.append(p.pos)
	return game.map.zombie_spawn_point(avoid)


func horde_size(wave_number: int) -> int:
	return Config.HORDE_SIZE + Config.HORDE_GROWTH * (wave_number - 1)


func pick_type() -> int:
	var r := randf()
	if r < 0.6:
		return Zombie.Type.WALKER
	if r < 0.85:
		return Zombie.Type.RUNNER
	return Zombie.Type.LEAPER


## Spawn up to `count` zombies at once. Returns how many actually spawned (the cap may cut it).
func spawn_horde(count: int) -> int:
	wave += 1
	var spawned := 0
	for i in count:
		if game.spawn_zombie(pick_type(), _spawn_point()) != null:
			spawned += 1
	game.hooks.on_horde_incoming(wave, spawned)
	return spawned
