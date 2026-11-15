class_name TestCase
extends Node
## Base class for tests. Put files named test_*.gd in res://tests/, extend TestCase,
## and write methods named test_*. Methods may use `await`.
##
## Run all:      tools\test.ps1
## Run some:     tools\test.ps1 zombie      (matches file or method names)

var failures: Array[String] = []
var asserts := 0
var _games: Array[Game] = []


func before_each() -> void:
	pass


func after_each() -> void:
	pass


# --- Assertions ---------------------------------------------------------------

func fail(msg: String) -> void:
	failures.append(msg)


func assert_true(cond: bool, msg := "expected true") -> void:
	asserts += 1
	if not cond:
		fail(msg)


func assert_false(cond: bool, msg := "expected false") -> void:
	assert_true(not cond, msg)


func assert_eq(got: Variant, want: Variant, msg := "") -> void:
	asserts += 1
	if got != want:
		fail("%s: got %s, want %s" % [msg if msg != "" else "assert_eq", str(got), str(want)])


func assert_near(got: float, want: float, tol := 0.01, msg := "") -> void:
	asserts += 1
	if absf(got - want) > tol:
		fail("%s: got %f, want %f ± %f" % [msg if msg != "" else "assert_near", got, want, tol])


func assert_gt(got: float, than: float, msg := "") -> void:
	asserts += 1
	if not got > than:
		fail("%s: got %s, want > %s" % [msg if msg != "" else "assert_gt", str(got), str(than)])


func assert_lt(got: float, than: float, msg := "") -> void:
	asserts += 1
	if not got < than:
		fail("%s: got %s, want < %s" % [msg if msg != "" else "assert_lt", str(got), str(than)])


# --- Helpers ------------------------------------------------------------------

## Wait n physics frames.
func frames(n := 1) -> void:
	for i in n:
		await get_tree().physics_frame


func seconds(s: float) -> void:
	await get_tree().create_timer(s, true, true).timeout


## Poll `cond` every physics frame until it returns true or `timeout` seconds pass.
func wait_until(cond: Callable, timeout := 3.0) -> bool:
	var left := timeout
	while left > 0.0:
		if cond.call():
			return true
		await get_tree().physics_frame
		left -= 1.0 / Engine.physics_ticks_per_second
	return cond.call()


## A real host Game running offline (no sockets), with automatic spawning turned off.
func new_game(map_name := "corridor") -> Game:
	var g := Game.new()
	g.map_name = map_name
	add_child(g)
	g.start_host("Tester")
	g.director.enabled = false
	_games.append(g)
	await frames(2)
	return g


## Records every gameplay hook the game fires: [[hook_name, args], ...]
func spy(g: Game) -> Array:
	var calls := []
	g.hooks.fired.connect(func(hook: StringName, args: Array): calls.append([hook, args]))
	return calls


func count(calls: Array, hook: StringName) -> int:
	var n := 0
	for c in calls:
		if c[0] == hook:
			n += 1
	return n


func cleanup() -> void:
	for g in _games:
		if is_instance_valid(g):
			g.free()
	_games.clear()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
