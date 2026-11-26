class_name HouseStreamer
extends Node3D
## The room producer in the town (S246): the open houses of CityBlocks (`blocks.open_houses`) get
## their floors laid out by HousePlan and built by InteriorBuilder when the camera comes near, and
## taken down again when it goes away. Every peer does it round its own camera: the layout is
## seeded by the house's index, so a house is the same on every peer.
##
## Until a house's floors stand, its outer walls are part of one shared mesh (CityMap's
## OpenHouseShells) and a box keeps its street front solid. While they stand, the shell's shader
## cuts that house's walls away (up to Config.HOUSE_STREAM_MAX holes) and the box is off: the
## floors bring their own facade with the street door standing open.
##
## The layout (100-200 ms for a tall house) runs on a worker thread; building the nodes is one
## house per look round on the main thread. A layout that fails is tried again with a simpler spec
## (fewer bays, no shop); a house that never lays out stays a shell.
##
## Zombies do not come in yet: their navigation is CityMap's 4 m grid, where a block is solid.

const SHADER := """
shader_type spatial;
render_mode cull_back;
const int MAX_HOLES = %d;
uniform vec4 hole_a[MAX_HOLES]; // centre x, centre z, street axis x, z
uniform vec4 hole_b[MAX_HOLES]; // half width, half depth, top y, unused
uniform int holes = 0;
varying vec3 world_pos;
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	for (int i = 0; i < holes; i++) {
		vec2 d = world_pos.xz - hole_a[i].xy;
		vec2 u = hole_a[i].zw;
		if (abs(dot(d, u)) < hole_b[i].x + 0.06 && abs(dot(d, vec2(-u.y, u.x))) < hole_b[i].y + 0.06 && world_pos.y < hole_b[i].z) {
			discard;
		}
	}
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.85;
}
"""

var map: CityMap
var blocks: CityBlocks
var shell: ShaderMaterial
var built := {}       ## house index -> Node3D (its floors, standing)
var failed := {}      ## house index -> true: never laid out
var plans := {}       ## house index -> HousePlan, laid out (kept: coming back costs nothing)
var _task := -1       ## the worker task laying out `_task_house`
var _task_house := -1
var _result: HousePlan = null
var _mutex := Mutex.new()
var _t := 0.0
var focus_override := Vector3.INF ## tests and racks: stream round this point instead of the camera


static func shell_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER % Config.HOUSE_STREAM_MAX
	var m := ShaderMaterial.new()
	m.shader = shader
	var none := PackedVector4Array()
	none.resize(Config.HOUSE_STREAM_MAX)
	m.set_shader_parameter("hole_a", none)
	m.set_shader_parameter("hole_b", none)
	m.set_shader_parameter("holes", 0)
	return m


func _init(city: CityMap, shell_mat: Material) -> void:
	name = "OpenHouses"
	map = city
	blocks = city.blocks
	shell = shell_mat as ShaderMaterial


func _exit_tree() -> void:
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = Config.HOUSE_STREAM_EVERY
	var focus := focus_override
	if focus == Vector3.INF:
		var cam := get_viewport().get_camera_3d() if get_viewport() else null
		if cam == null:
			return
		focus = cam.global_position
	step(focus)


## One look round from `focus`: take down what is far, finish a layout that is done, start the
## next one (nearest first).
func step(focus: Vector3) -> void:
	var p := Vector2(focus.x, focus.z)
	for i: int in built.keys():
		if _distance(i, p) > Config.HOUSE_STREAM_KEEP:
			_take_down(i)
	_collect()
	if _task >= 0:
		return
	var best := -1
	var best_d := Config.HOUSE_STREAM_RADIUS
	for i: int in blocks.open_houses:
		if built.has(i) or failed.has(i):
			continue
		var d := _distance(i, p)
		if d < best_d:
			best_d = d
			best = i
	if best < 0 or built.size() >= Config.HOUSE_STREAM_MAX:
		return
	if plans.has(best):
		_put_up(best, plans[best])
		return
	_task_house = best
	_task = WorkerThreadPool.add_task(_layout.bind(best, blocks.house_spec(best)), false, "house layout")


## Lay out every house near `focus` and build it now, without threads (tests, the rack).
func build_near(focus: Vector3) -> void:
	var p := Vector2(focus.x, focus.z)
	for i: int in blocks.open_houses:
		if built.size() >= Config.HOUSE_STREAM_MAX:
			return
		if not built.has(i) and not failed.has(i) and _distance(i, p) <= Config.HOUSE_STREAM_RADIUS:
			var plan := _lay_out(i)
			if plan == null:
				failed[i] = true
			else:
				_put_up(i, plan)


func _distance(i: int, p: Vector2) -> float:
	var box: Array = blocks.house_box(i)
	return maxf(0.0, (box[0] as Vector2).distance_to(p) - float(box[2]))


## Worker thread: data only (HousePlan makes no nodes).
func _layout(i: int, _spec: Dictionary) -> void:
	var plan := _lay_out(i)
	_mutex.lock()
	_result = plan
	_mutex.unlock()


func _lay_out(i: int) -> HousePlan:
	for attempt in Config.HOUSE_LAYOUT_TRIES:
		var plan := HousePlan.new(blocks.house_spec(i, attempt))
		if plan.ok:
			return plan
	return null


func _collect() -> void:
	if _task < 0 or not WorkerThreadPool.is_task_completed(_task):
		return
	WorkerThreadPool.wait_for_task_completion(_task)
	_task = -1
	_mutex.lock()
	var plan := _result
	_result = null
	_mutex.unlock()
	if plan == null:
		failed[_task_house] = true
	else:
		plans[_task_house] = plan
		if built.size() < Config.HOUSE_STREAM_MAX:
			_put_up(_task_house, plan)
	_task_house = -1


func _put_up(i: int, plan: HousePlan) -> void:
	var h: Dictionary = blocks.houses[i]
	var foot: PackedVector2Array = h.foot
	var door := (foot[0] + foot[1]) * 0.5
	var y := map.ground_y(Vector3(door.x, 0, door.y)) + CityMap.LAYER_Y[1]
	var node := InteriorBuilder.build(plan)
	node.name = "house_%d" % i
	node.transform = blocks.house_transform(i, y)
	_court_stop(node, plan)
	add_child(node)
	built[i] = node
	var front: CollisionShape3D = h.get("front_shape")
	if front:
		front.set_deferred("disabled", true)
	_holes()


func _take_down(i: int) -> void:
	var node: Node3D = built[i]
	built.erase(i)
	node.queue_free()
	var front: CollisionShape3D = blocks.houses[i].get("front_shape")
	if front:
		front.set_deferred("disabled", false)
	_holes()


## The court behind is not built for walking (the town's back buildings have no collision), so the
## court door's way out is closed by an invisible wall just outside the court facade.
func _court_stop(node: Node3D, plan: HousePlan) -> void:
	var body := StaticBody3D.new()
	body.name = "court_stop"
	body.collision_layer = Config.LAYER_WORLD
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(plan.width + 2.0 * Config.INTERIOR_PARTY, plan.storey * plan.floors.size(), 0.3)
	cs.shape = shape
	cs.position = Vector3(plan.width * 0.5, shape.size.y * 0.5, plan.depth + Config.INTERIOR_FACADE + 0.15)
	body.add_child(cs)
	node.add_child(body)


## Tell the shell's shader which houses to cut away.
func _holes() -> void:
	if shell == null:
		return
	var a := PackedVector4Array()
	var b := PackedVector4Array()
	a.resize(Config.HOUSE_STREAM_MAX)
	b.resize(Config.HOUSE_STREAM_MAX)
	var n := 0
	for i: int in built:
		if n >= Config.HOUSE_STREAM_MAX:
			break
		var box: Array = blocks.house_box(i)
		var c: Vector2 = box[0]
		var u: Vector2 = box[1]
		var top: float = (built[i] as Node3D).position.y + float(blocks.houses[i].eave) + 0.05
		a[n] = Vector4(c.x, c.y, u.x, u.y)
		b[n] = Vector4(float(box[2]), float(box[3]), top, 0.0)
		n += 1
	shell.set_shader_parameter("hole_a", a)
	shell.set_shader_parameter("hole_b", b)
	shell.set_shader_parameter("holes", n)
