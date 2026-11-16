class_name PlayerStatus
extends RefCounted
## What is happening to one player's body besides HP: wounds that bleed and a medical item being used.
## No nodes. The host keeps one per player (`players[id].status`) and sends the player theirs whenever
## it changes (`Game.status_changed`); the player counts the use down by themself in between.

var bleed := 0            ## wounds open, 0..Config.BLEED_MAX
var using := &""          ## the Inventory item being applied, or &""
var use_left := 0.0       ## seconds until it is done
var use_total := 0.0
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


## A new life.
func reset() -> void:
	bleed = 0
	_tick = 0.0
	cancel_use()


func get_state() -> Dictionary:
	return { "bleed": bleed, "using": String(using), "left": use_left, "total": use_total }


func apply_state(state: Dictionary) -> void:
	bleed = int(state.get("bleed", 0))
	using = StringName(state.get("using", ""))
	use_left = float(state.get("left", 0.0))
	use_total = float(state.get("total", 0.0))
