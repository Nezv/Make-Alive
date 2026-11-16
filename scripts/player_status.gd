class_name PlayerStatus
extends RefCounted
## What is happening to one player's body besides HP: wounds that bleed and a medical item being used.
## No nodes. The host keeps one per player (`players[id].status`) and sends the player theirs whenever
## it changes (`Game.status_changed`); the player counts the use down by themself in between.

var bleed := 0            ## wounds open, 0..Config.BLEED_MAX
var using := &""          ## the Inventory item being applied, or &""
var use_left := 0.0       ## seconds until it is done
var use_total := 0.0
var downed := false       ## at 0 HP with a teammate to get them up: crawling, bleeding out
var down_left := 0.0      ## seconds until they die
var down_total := 0.0
var revive_left := 0.0    ## being got up: seconds to go (0 = nobody is)
var revive_total := 0.0
var revive_target := 0    ## (host) the downed player this one is getting up
var dead := false         ## dead with no way back yet: out of the fight, watching
var respawn_left := -1.0  ## seconds until they come back (-1: no timer)
var respawn_checkpoint := false ## they come back at the next checkpoint
var invuln := 0.0         ## (host) seconds nothing can hurt them (just revived)
var _tick := 0.0          ## seconds until the next bleeding tick


## A zombie's hit landed: `roll` (0..1) under the chance opens a wound, up to the most at once.
## True if one opened.
func hurt(roll: float) -> bool:
	if roll >= Config.BLEED_CHANCE or bleed >= Config.BLEED_MAX:
		return false
	if bleed == 0:
		_tick = Config.BLEED_INTERVAL
	bleed += 1
	return true


## True if there was anything to stop.
func stop_bleeding() -> bool:
	var was := bleed > 0
	bleed = 0
	return was


## HP lost to bleeding over `delta` seconds: every wound costs `Config.BLEED_DAMAGE` each interval.
func bleed_damage(delta: float) -> int:
	if bleed == 0:
		return 0
	_tick -= delta
	var lost := 0
	while _tick <= 0.0:
		lost += bleed * Config.BLEED_DAMAGE
		_tick += Config.BLEED_INTERVAL
	return lost


func is_using() -> bool:
	return using != &""


func begin_use(item: StringName, seconds: float) -> void:
	using = item
	use_left = seconds
	use_total = seconds


## True if something was being used.
func cancel_use() -> bool:
	var was := is_using()
	using = &""
	use_left = 0.0
	use_total = 0.0
	return was


## `delta` seconds of using go by. Returns the item once it is done (and nothing is being used after
## that), otherwise &"".
func step_use(delta: float) -> StringName:
	if not is_using():
		return &""
	use_left -= delta
	if use_left > 0.0:
		return &""
	var item := using
	cancel_use()
	return item


## Just count the clock down (the player's own copy between two messages from the host).
func tick_view(delta: float) -> void:
	if is_using():
		use_left = maxf(0.0, use_left - delta)
	if downed and revive_left <= 0.0:
		down_left = maxf(0.0, down_left - delta)
	revive_left = maxf(0.0, revive_left - delta)
	if dead and respawn_left > 0.0:
		respawn_left = maxf(0.0, respawn_left - delta)


## A new life.
func reset() -> void:
	bleed = 0
	_tick = 0.0
	cancel_use()
	downed = false
	down_left = 0.0
	down_total = 0.0
	revive_left = 0.0
	revive_total = 0.0
	revive_target = 0
	invuln = 0.0
	dead = false
	respawn_left = -1.0
	respawn_checkpoint = false


func get_state() -> Dictionary:
	return { "bleed": bleed, "using": String(using), "left": use_left, "total": use_total,
		"downed": downed, "down_left": down_left, "down_total": down_total, "revive_left": revive_left, "revive_total": revive_total,
		"dead": dead, "respawn_left": respawn_left, "respawn_checkpoint": respawn_checkpoint }


func apply_state(state: Dictionary) -> void:
	bleed = int(state.get("bleed", 0))
	using = StringName(state.get("using", ""))
	use_left = float(state.get("left", 0.0))
	use_total = float(state.get("total", 0.0))
	downed = bool(state.get("downed", false))
	down_left = float(state.get("down_left", 0.0))
	down_total = float(state.get("down_total", 0.0))
	revive_left = float(state.get("revive_left", 0.0))
	revive_total = float(state.get("revive_total", 0.0))
	dead = bool(state.get("dead", false))
	respawn_left = float(state.get("respawn_left", -1.0))
	respawn_checkpoint = bool(state.get("respawn_checkpoint", false))
