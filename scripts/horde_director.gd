class_name HordeDirector
extends RefCounted
## Decides when zombies arrive (host only), and keeps the pace. The pace is four states, driven by how
## hard the players have it (`stress`, 0..1: damage taken, zombies close, ammo running low):
##   CALM   quiet, nothing comes, until the players have calmed down
##   BUILD  a straggler now and then while the next horde's clock runs (slower while stressed, sooner when noisy)
##   PEAK   a horde streams out of one closet nobody can see; ends when most of it is dead or it drags on
##   RELAX  a breather until the players are calm again
## Zombies only appear in closets no living player can see or is close to; wanderers stand about from
## the map's data; dangerous types are kept to a budget (`Config.SPECIAL_BUDGET`); zombies that have lost
## the players are moved up to a closet ahead of them.

enum State { CALM, BUILD, PEAK, RELAX }

var game: Game
var enabled := true
var wave := 0
var calm_left := 0.0 ## seconds nobody is sent (after a checkpoint)
var heat := 0.0 ## filled by noise (Game.make_noise); full, it brings the next horde sooner
var stress := 0.0 ## 0..1: how hard the players have it right now
var state: int = State.BUILD ## the first thing is the build-up to the first horde
var recycled := 0 ## stragglers moved up so far
var stream_from := "" ## the closet the current (or last) horde comes out of
var rng := RandomNumberGenerator.new() ## spawn places and types (tests seed it)
var _state_t := 0.0
var _trickle := 1.0
var _horde_timer := Config.HORDE_FIRST ## seconds of build-up left before the next horde
var _stream_left := 0 ## zombies of the horde still to come out of the closet
var _stream_t := 0.0
var _stream_closet := {}
var _peak_size := 0
var _lost := {} ## zombie id -> seconds it has been far from every living player
var _lost_t := 0.0
var _populated := false


func _init(owner_game: Game) -> void:
	game = owner_game


func step(delta: float) -> void:
	heat = maxf(0.0, heat - Config.NOISE_HEAT_DECAY * delta)
	_update_stress(delta)
	if not enabled:
		return
	if calm_left > 0.0:
		calm_left -= delta
		return
	if not _populated:
		_populated = true
		_place_wanderers()
	_step_stream(delta)
	_state_t += delta
	_recycle(delta)
	match state:
		State.CALM:
			if _state_t >= Config.CALM_TIME and stress <= Config.STRESS_CALM:
				_enter(State.BUILD)
		State.BUILD:
			_horde_timer -= delta * lerpf(Config.BUILD_RATE_CALM, Config.BUILD_RATE_STRESSED, stress)
			_trickle -= delta
			if _trickle <= 0.0:
				_trickle = Config.TRICKLE_INTERVAL
				_spawn_one()
			if _horde_timer <= 0.0:
				_enter(State.PEAK)
				stream_horde(horde_size(wave + 1))
		State.PEAK:
			var mostly_dead := _stream_left == 0 and game.zombies.size() <= ceili(_peak_size * Config.PEAK_END_ALIVE)
			if (mostly_dead and _state_t >= Config.PEAK_MIN) or _state_t >= Config.PEAK_MAX:
				_enter(State.RELAX)
		State.RELAX:
			if _state_t >= Config.RELAX_MIN and stress <= Config.STRESS_CALM:
				_enter(State.CALM)


func _enter(next: int) -> void:
	state = next
	_state_t = 0.0
	if next == State.BUILD:
		_trickle = Config.TRICKLE_INTERVAL
	elif next == State.PEAK:
		_horde_timer = Config.HORDE_INTERVAL # the build-up after this one
	game.hooks.on_pacing_changed(next)


## Send nobody for `seconds` (the clocks wait too); a horde still coming out of its closet stops.
func calm(seconds: float) -> void:
	calm_left = maxf(calm_left, seconds)
	_stream_left = 0


## Something loud happened (`loudness` in metres). Enough of it and the next horde will not wait.
func add_heat(loudness: float) -> void:
	heat += loudness * Config.NOISE_HEAT_PER_M
	if heat >= Config.NOISE_HEAT_FULL:
		heat = 0.0
		_horde_timer = minf(_horde_timer, Config.NOISE_HORDE_SOON)


## A player took `amount` HP of damage.
func hurt(amount: int) -> void:
	stress = clampf(stress + amount * Config.STRESS_PER_HP, 0.0, 1.0)


func debug_text() -> String:
	return "director %s   stress %.2f   heat %d   zombies %d   horde %d" % [State.keys()[state], stress, roundi(heat), game.zombies.size(), wave]


# --- Stress ---------------------------------------------------------------------------

func _update_stress(delta: float) -> void:
	var living := _living()
	if not living.is_empty():
		var range2 := Config.STRESS_NEAR * Config.STRESS_NEAR
		var near := 0
		for z: Zombie in game.zombies.values():
			var p := z.global_position
			for q: Vector3 in living:
				if Vector2(p.x - q.x, p.z - q.z).length_squared() < range2:
					near += 1
					break
		stress += near * Config.STRESS_PER_ZOMBIE * delta
		stress += _short_of_ammo() * Config.STRESS_AMMO_RATE * delta
	stress = clampf(stress - Config.STRESS_DECAY * delta, 0.0, 1.0)


## How many living players are nearly out of ammo for the gun in their hands (limited-ammo maps only).
func _short_of_ammo() -> int:
	if game.map.infinite_ammo:
		return 0
	var n := 0
	for id: int in game.rules.alive():
		var have := game.ammo_of(id, Weapons.ammo_of(game.players[id].weapon))
		if have >= 0 and have < Config.STRESS_AMMO_LOW:
			n += 1
	return n


## Where the players still in the fight stand.
func _living() -> Array:
	var at := []
	for id: int in game.rules.alive():
		at.append(game.players[id].pos)
	return at


# --- Where they come from -------------------------------------------------------------

## The closets zombies may come out of now: the ones of this wave that no living player can see or is
## within Config.SPAWN_MIN_DIST of; if there are none, the one farthest from the nearest player.
func _candidates(wave_number: int) -> Array:
	var ids := game.map.data.closet_ids(wave_number)
	var usable: Array = game.map.data.closets.filter(func(c: Dictionary) -> bool: return ids.has(c.id))
	var living := _living()
	if usable.is_empty() or living.is_empty():
		return usable
	var hidden: Array = usable.filter(func(c: Dictionary) -> bool: return _hidden(c.at, living))
	if not hidden.is_empty():
		return hidden
	var best: Dictionary = usable[0]
	var best_d := -1.0
	for c: Dictionary in usable:
		var nearest := INF
		for q: Vector3 in living:
			nearest = minf(nearest, q.distance_to(c.at))
		if nearest > best_d:
			best_d = nearest
			best = c
	return [best]


func _hidden(at: Vector3, living: Array) -> bool:
	for q: Vector3 in living:
		if q.distance_to(at) < Config.SPAWN_MIN_DIST or (game.map.sees(q, at) and game.map.is_direct(q, at)):
			return false
	return true


## A closet for the coming horde (`wave_number`, default the next): one of the hidden ones at random.
## {} when the map has none.
func pick_closet(wave_number := -1) -> Dictionary:
	var options := _candidates(wave + 1 if wave_number < 0 else wave_number)
	return {} if options.is_empty() else options[rng.randi() % options.size()]


## The hidden closet nearest the objective: where a zombie that lost the players is put back.
func _closet_ahead() -> Dictionary:
	var options := _candidates(wave + 1)
	if options.is_empty():
		return {}
	var zone: String = game.rules.state().get("zone", "")
	if zone == "" or not game.map.data.zones.has(zone):
		return options[rng.randi() % options.size()]
	var goal := game.map.data.zone_center(zone)
	var best: Dictionary = options[0]
	var best_d := INF
	for c: Dictionary in options:
		var d := Vector2(c.at.x - goal.x, c.at.z - goal.z).length()
		if d < best_d:
			best_d = d
			best = c
	return best


## A spot in a closet, or wherever the map says when it has none.
func _closet_spot(closet: Dictionary) -> Vector3:
	if closet.is_empty():
		return _spawn_point()
	var r: float = closet.radius * sqrt(rng.randf())
	var a := rng.randf() * TAU
	var at: Vector3 = closet.at
	return at + Vector3(cos(a) * r, 0, sin(a) * r)


func _spawn_point() -> Vector3:
	var avoid := []
	for p: Dictionary in game.players.values():
		avoid.append(p.pos)
	return game.map.zombie_spawn_point(avoid)


func _closet_point(id: String) -> Vector3:
	for c: Dictionary in game.map.data.closets:
		if c.id == id:
			return _closet_spot(c)
	return _spawn_point()


func _spawn_one() -> Zombie:
	return game.spawn_zombie(pick_type(), _closet_spot(pick_closet()))


# --- Hordes ---------------------------------------------------------------------------

## How many come in horde number `wave_number`: growing each wave, scaled by the level and by the
## players still in the fight.
func horde_size(wave_number: int) -> int:
	var base := Config.HORDE_SIZE + Config.HORDE_GROWTH * (wave_number - 1)
	var living := game.rules.alive().size() if game.rules != null else 1
	return roundi(base * game.mult("horde") * (1.0 + Config.WAVE_PER_PLAYER * maxi(0, living - 1)))


## The usual mix: mostly walkers, some runners (more on harder levels), a few leapers, and never more
## of a dangerous type than its budget allows.
func pick_type() -> int:
	var runners := clampf(Config.RUNNER_SHARE * game.mult("runners"), 0.0, 1.0 - Config.LEAPER_SHARE)
	var r := rng.randf()
	var type: int = Zombie.Type.WALKER
	if r < Config.LEAPER_SHARE:
		type = Zombie.Type.LEAPER
	elif r < Config.LEAPER_SHARE + runners:
		type = Zombie.Type.RUNNER
	return type if type_room(type) > 0 else Zombie.Type.WALKER


## How many more of `type` may be about before its budget is spent.
func type_room(type: int) -> int:
	if not Config.SPECIAL_BUDGET.has(type):
		return 1 << 20
	var alive := 0
	for z: Zombie in game.zombies.values():
		if z.type == type:
			alive += 1
	return maxi(0, Config.SPECIAL_BUDGET[type] - alive)


## A horde of `count` that comes out of one closet nobody can see, one zombie every
## Config.HORDE_STREAM_GAP seconds, walking the closet's route: a stream round a corner, not a blob.
func stream_horde(count: int) -> int:
	wave += 1
	_stream_closet = pick_closet(wave)
	stream_from = _stream_closet.get("id", "")
	_stream_left = count
	_stream_t = Config.HORDE_STREAM_GAP # the first one is out at once
	_peak_size = count
	game.hooks.on_horde_incoming(wave, count)
	return count


func _step_stream(delta: float) -> void:
	if _stream_left <= 0:
		return
	_stream_t += delta
	while _stream_left > 0 and _stream_t >= Config.HORDE_STREAM_GAP:
		_stream_t -= Config.HORDE_STREAM_GAP
		_stream_left -= 1
		var z := game.spawn_zombie(pick_type(), _closet_spot(_stream_closet))
		if z != null and not _stream_closet.is_empty():
			z.route = game.map.data.route_from(_stream_closet.id).duplicate()


## A defended wave: `count` zombies of `types` ({ "walker": weight, ... }, empty = the usual mix),
## spread round-robin over the closets `closet_ids` of the map's data (empty = wherever the map
## says). Returns how many spawned.
func spawn_wave(count: int, types: Dictionary, closet_ids: Array) -> int:
	wave += 1
	var spawned := 0
	for i in count:
		var at := _spawn_point() if closet_ids.is_empty() else _closet_point(closet_ids[i % closet_ids.size()])
		if game.spawn_zombie(_pick_from(types), at) != null:
			spawned += 1
	game.hooks.on_horde_incoming(wave, spawned)
	return spawned


func _pick_from(types: Dictionary) -> int:
	if types.is_empty():
		return pick_type()
	var total := 0.0
	for t: String in types:
		total += float(types[t])
	var r := rng.randf() * total
	for t: String in types:
		r -= float(types[t])
		if r <= 0.0:
			return MapData.WAVE_TYPES[t]
	return MapData.WAVE_TYPES[types.keys()[-1]]


## Spawn up to `count` zombies at once, wherever the map says. Returns how many actually spawned
## (the cap may cut it).
func spawn_horde(count: int) -> int:
	wave += 1
	var spawned := 0
	for i in count:
		if game.spawn_zombie(pick_type(), _spawn_point()) != null:
			spawned += 1
	game.hooks.on_horde_incoming(wave, spawned)
	return spawned


# --- Wanderers and stragglers -----------------------------------------------------------

## Put out the map's wanderers: a few zombies standing about ahead of the players until something wakes them.
func _place_wanderers() -> void:
	for w: Dictionary in game.map.data.wanderers:
		for i in w.count:
			var a := rng.randf() * TAU
			var r: float = w.radius * sqrt(rng.randf())
			var at: Vector3 = w.at
			var z := game.spawn_zombie(pick_type(), at + Vector3(cos(a) * r, 0, sin(a) * r))
			if z != null:
				z.idle = true
				z.rotation.y = rng.randf() * TAU


## Zombies that have been far from every living player for a long time (stuck, left behind) are put
## back in a closet ahead of the players, out of sight.
func _recycle(delta: float) -> void:
	_lost_t += delta
	if _lost_t < Config.STRAGGLER_CHECK:
		return
	var elapsed := _lost_t
	_lost_t = 0.0
	var living := _living()
	if living.is_empty():
		return
	for z: Zombie in game.zombies.values():
		var nearest := INF
		for q: Vector3 in living:
			nearest = minf(nearest, Vector2(z.global_position.x - q.x, z.global_position.z - q.z).length())
		if nearest <= Config.STRAGGLER_DIST or z.investigating() or z.idle:
			_lost.erase(z.zid)
			continue
		_lost[z.zid] = float(_lost.get(z.zid, 0.0)) + elapsed
		if _lost[z.zid] >= Config.STRAGGLER_TIME:
			_lost.erase(z.zid)
			_move_ahead(z)
	for zid: int in _lost.keys():
		if not game.zombies.has(zid):
			_lost.erase(zid)


func _move_ahead(z: Zombie) -> void:
	z.global_position = _closet_spot(_closet_ahead())
	z.velocity = Vector3.ZERO
	z.route = []
	z.heard_left = 0.0
	recycled += 1
