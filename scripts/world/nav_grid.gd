class_name NavGrid
extends RefCounted
## Navigation for open maps: a flat grid of free / blocked cells with A* on top.
##
## The map blocks a rectangle for every solid thing (vehicles, barricades, walls), grown by a
## zombie's radius, then calls finish(). Zombies ask nav_target() where to walk next: straight at
## the goal when nothing is in the way, otherwise toward the furthest corner of the path they can
## already see, which makes them cut corners naturally instead of walking cell to cell.

const LOOK_AHEAD := 20 ## how many path cells ahead a walker may aim for

var lo: Vector2
var cell: float
var w: int
var h: int
var solid := PackedByteArray()
var astar := AStarGrid2D.new()


func _init(min_corner: Vector2, max_corner: Vector2, cell_size := 0.5) -> void:
	lo = min_corner
	cell = cell_size
	w = ceili((max_corner.x - min_corner.x) / cell)
	h = ceili((max_corner.y - min_corner.y) / cell)
	solid.resize(w * h)


## Block a rectangle on the ground: `center` and `half` are (x, z); `yaw` turns it like a node's
## rotation.y. `margin` grows it so walkers keep their shoulders out of it.
func block_rect(center: Vector2, half: Vector2, yaw := 0.0, margin := Config.ZOMBIE_RADIUS) -> void:
	var hx := half.x + margin
	var hz := half.y + margin
	var c := cos(yaw)
	var s := sin(yaw)
	var reach := absf(hx * c) + absf(hz * s)
	var reach_z := absf(hx * s) + absf(hz * c)
	var x0 := maxi(0, floori((center.x - reach - lo.x) / cell))
	var x1 := mini(w - 1, floori((center.x + reach - lo.x) / cell))
	var z0 := maxi(0, floori((center.y - reach_z - lo.y) / cell))
	var z1 := mini(h - 1, floori((center.y + reach_z - lo.y) / cell))
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var dx := lo.x + (ix + 0.5) * cell - center.x
			var dz := lo.y + (iz + 0.5) * cell - center.y
			if absf(dx * c - dz * s) <= hx and absf(dx * s + dz * c) <= hz:
				solid[iz * w + ix] = 1


## Call once after the last block_rect.
func finish() -> void:
	astar.region = Rect2i(0, 0, w, h)
	astar.cell_size = Vector2(cell, cell)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for i in solid.size():
		if solid[i] == 1:
			astar.set_point_solid(Vector2i(i % w, i / w), true)


func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x - lo.x) / cell), floori((p.z - lo.y) / cell))


func center_of(c: Vector2i) -> Vector3:
	return Vector3(lo.x + (c.x + 0.5) * cell, 0.0, lo.y + (c.y + 0.5) * cell)


func _solid(c: Vector2i) -> bool:
	return c.x < 0 or c.y < 0 or c.x >= w or c.y >= h or solid[c.y * w + c.x] == 1


func is_blocked(p: Vector3) -> bool:
	return _solid(cell_of(p))


## True if a straight walk from `a` to `b` crosses no blocked cell. Visits every cell the line
## touches (grid traversal), so nothing slips through between samples.
func is_direct(a: Vector3, b: Vector3) -> bool:
	var x := (a.x - lo.x) / cell
	var z := (a.z - lo.y) / cell
	var dx := (b.x - lo.x) / cell - x
	var dz := (b.z - lo.y) / cell - z
	var c := Vector2i(floori(x), floori(z))
	var last := Vector2i(floori(x + dx), floori(z + dz))
	var step_x := 1 if dx > 0.0 else -1
	var step_z := 1 if dz > 0.0 else -1
	var t_dx := absf(1.0 / dx) if dx != 0.0 else INF
	var t_dz := absf(1.0 / dz) if dz != 0.0 else INF
	var t_x := ((c.x + 1 - x) if dx > 0.0 else (x - c.x)) * t_dx if dx != 0.0 else INF
	var t_z := ((c.y + 1 - z) if dz > 0.0 else (z - c.y)) * t_dz if dz != 0.0 else INF
	for i in w + h + 2:
		if _solid(c):
			return false
		if c == last or (t_x > 1.0 and t_z > 1.0):
			return true
		if t_x < t_z:
			c.x += step_x
			t_x += t_dx
		else:
			c.y += step_z
			t_z += t_dz
	return true


## The closest free spot to `p` (p itself if it is free).
func nearest_free(p: Vector3) -> Vector3:
	var c := cell_of(p)
	if not _solid(c):
		return p
	for r in range(1, 24):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var n := c + Vector2i(dx, dz)
				if not _solid(n) and center_of(n).distance_squared_to(p) < best_d:
					best_d = center_of(n).distance_squared_to(p)
					best = n
		if best.x >= 0:
			return center_of(best)
	return p


func _path(from: Vector3, to: Vector3) -> Array[Vector2i]:
	var a := cell_of(nearest_free(from))
	var b := cell_of(nearest_free(to))
	if _solid(a) or _solid(b):
		return []
	return astar.get_id_path(a, b)


func reachable(from: Vector3, to: Vector3) -> bool:
	return not _path(from, to).is_empty()


## Where to walk right now to get from `from` to `to`. `lane` (-1..1) spreads a crowd sideways.
func nav_target(from: Vector3, to: Vector3, lane := 0.0) -> Vector3:
	if is_direct(from, to):
		return to
	var path := _path(from, to)
	if path.size() < 2:
		return to
	var target := center_of(path[1])
	for i in range(mini(path.size() - 1, LOOK_AHEAD), 1, -1):
		var p := center_of(path[i])
		if is_direct(from, p):
			target = p
			break
	var dir := (target - from).normalized()
	var shifted := target + Vector3(-dir.z, 0.0, dir.x) * lane * 0.45
	if lane != 0.0 and not is_blocked(shifted) and is_direct(from, shifted):
		return shifted
	return target
