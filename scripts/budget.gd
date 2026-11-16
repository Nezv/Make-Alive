class_name Budget
## What a map costs to draw, counted without a screen so the headless tests can hold every map
## to a budget (Config.BUDGET). Real frame times and draw calls come from `tools\perf.ps1`,
## which needs a window.
##
##   meshes         mesh and multimesh instances in the map
##   surfaces       their surfaces: one draw call each, per pass, when in view
##   lights         every light
##   shadow_lights  lights that cast shadows (each redraws what it reaches)
##   shapes         collision shapes
##   worst_view     most surfaces inside any one camera: the draw calls of a frame, before shadows
##
## `worst_view` looks from every player spawn and every zone, in four directions.

const VIEW_FOV := 75.0
const VIEW_FAR := 300.0
const VIEW_YAWS := [0.0, PI / 2.0, PI, PI * 1.5]


## Count everything under `root` (a map's root, or a whole Game).
static func measure(root: Node) -> Dictionary:
	var out := { "meshes": 0, "surfaces": 0, "lights": 0, "shadow_lights": 0, "shapes": 0 }
	_walk(root, out, [])
	return out


## The cameras a map is judged from: [Transform3D, ...] at eye height.
static func views(map: GameMap) -> Array:
	var spots := [map.player_spawn()]
	for s: Dictionary in map.spawns.slice(0, 1):
		spots.append(s.at)
	for id: String in map.zones:
		var c := map.data.zone_center(id)
		spots.append(Vector3(c.x, map.ground_y(c), c.z))
	var out := []
	for at: Vector3 in spots:
		for yaw: float in VIEW_YAWS:
			out.append(Transform3D(Basis(Vector3.UP, yaw), at + Vector3(0, Config.EYE_HEIGHT, 0)))
	return out


## Surfaces inside the camera at `view`: what one frame would draw from there.
static func surfaces_in_view(root: Node, view: Transform3D) -> int:
	var drawn := []
	_walk(root, { "meshes": 0, "surfaces": 0, "lights": 0, "shadow_lights": 0, "shapes": 0 }, drawn)
	var planes := _frustum(view)
	var n := 0
	for d: Array in drawn:
		var box: AABB = d[0]
		var reach: float = d[2]
		if reach > 0.0 and box.get_center().distance_to(view.origin) > reach + box.get_longest_axis_size():
			continue # past its visibility range
		if _in_frustum(box, planes):
			n += d[1]
	return n


## The whole report for a map: `measure` plus `worst_view`.
static func report(map: GameMap) -> Dictionary:
	var out := measure(map.root)
	var worst := 0
	for v: Transform3D in views(map):
		worst = maxi(worst, surfaces_in_view(map.root, v))
	out["worst_view"] = worst
	return out


## Which numbers of `got` are over the budget for `map_name`. Empty = inside the budget.
static func over(map_name: String, got: Dictionary) -> Array:
	var problems := []
	var limits: Dictionary = Config.BUDGET.get(map_name, {})
	for key: String in limits:
		if got.get(key, 0) > limits[key]:
			problems.append("%s: %s is %d, budget %d" % [map_name, key, got[key], limits[key]])
	return problems


static func _walk(n: Node, out: Dictionary, drawn: Array) -> void:
	if n is Node3D and not (n as Node3D).visible:
		return
	if n is GeometryInstance3D:
		var surfaces := 0
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			surfaces = (n as MeshInstance3D).mesh.get_surface_count()
		elif n is MultiMeshInstance3D and (n as MultiMeshInstance3D).multimesh != null:
			var mm := (n as MultiMeshInstance3D).multimesh
			surfaces = mm.mesh.get_surface_count() if mm.mesh != null and mm.instance_count != 0 else 0
		if surfaces > 0:
			out.meshes += 1
			out.surfaces += surfaces
			var g := n as GeometryInstance3D
			drawn.append([g.global_transform * g.get_aabb() if g.is_inside_tree() else g.transform * g.get_aabb(),
				surfaces, g.visibility_range_end])
	elif n is Light3D:
		out.lights += 1
		if (n as Light3D).shadow_enabled:
			out.shadow_lights += 1
	elif n is CollisionShape3D:
		out.shapes += 1
	for c in n.get_children():
		_walk(c, out, drawn)


## The six planes of a camera at `view`, normals pointing out of the visible space.
static func _frustum(view: Transform3D) -> Array:
	var half_v := deg_to_rad(VIEW_FOV) * 0.5
	var half_h := atan(tan(half_v) * 16.0 / 9.0)
	var b := view.basis
	var fwd := -b.z
	var planes := [Plane(-fwd, view.origin + fwd * 0.05), Plane(fwd, view.origin + fwd * VIEW_FAR)]
	for side: Vector3 in [b.x.rotated(b.y, -half_h), -b.x.rotated(b.y, half_h), b.y.rotated(b.x, half_v), -b.y.rotated(b.x, -half_v)]:
		planes.append(Plane(side, view.origin))
	return planes


static func _in_frustum(box: AABB, planes: Array) -> bool:
	for p: Plane in planes:
		# The corner of the box deepest inside the plane: if even that is outside, the box is.
		var corner := box.position
		if p.normal.x < 0.0:
			corner.x += box.size.x
		if p.normal.y < 0.0:
			corner.y += box.size.y
		if p.normal.z < 0.0:
			corner.z += box.size.z
		if p.is_point_over(corner):
			return false
	return true
