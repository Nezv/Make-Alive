class_name MeshKit
## Build low-poly models in code. Convention: models stand on y=0, face -Z, 1 unit = 1 metre.
## A Builder merges every shape you add into ONE mesh (one draw call) using vertex colours,
## so a whole building, car, or body part costs a single draw call.

static var _baked: StandardMaterial3D

## Shared material for all builder meshes: colour comes from vertex colours.
static func baked_material() -> StandardMaterial3D:
	if _baked == null:
		_baked = StandardMaterial3D.new()
		_baked.vertex_color_use_as_albedo = true
		_baked.roughness = 0.85
	return _baked

static func emissive(color: Color, energy := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

static func unshaded(color: Color, alpha := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color, alpha)
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


class Builder:
	var st := SurfaceTool.new()
	var count := 0

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	## Godot front faces wind clockwise (cross(b-a, c-a) points against the normal).
	func _tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, color: Color) -> void:
		if (b - a).cross(c - a).dot(n) > 0.0:
			var t := b
			b = c
			c = t
		st.set_color(color)
		st.set_normal(n)
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
		count += 1

	func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, color: Color) -> void:
		_tri(a, b, c, n, color)
		_tri(a, c, d, n, color)

	## Axis box of `size` centred at `pos`, optionally rotated by `rot`, then placed by `xf`.
	func box(size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY,
			xf := Transform3D.IDENTITY) -> Builder:
		var t := xf * Transform3D(rot, pos)
		var h := size * 0.5
		for axis in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
			var n: Vector3 = axis
			var u := Vector3(n.y, n.z, n.x).abs()  # a perpendicular axis
			var v := n.cross(u).abs()
			var c := n * h
			var hu := u * h
			var hv := v * h
			var wn := (t.basis * n).normalized()
			_quad(t * (c - hu - hv), t * (c + hu - hv), t * (c + hu + hv), t * (c - hu + hv), wn, color)
		return self

	## A flat rectangle facing up, centred at `pos`; `size` is (x, z). A sixth of a box's cost,
	## for ground paint that is only ever seen from above.
	func flat(size: Vector2, pos: Vector3, color: Color) -> Builder:
		var hx := size.x * 0.5
		var hz := size.y * 0.5
		_quad(pos + Vector3(-hx, 0, -hz), pos + Vector3(hx, 0, -hz), pos + Vector3(hx, 0, hz),
			pos + Vector3(-hx, 0, hz), Vector3.UP, color)
		return self

	## Ground between four corners (any heights), lit by each triangle's own upward normal.
	## Corners go round the quad: a (x0, z0), b (x1, z0), c (x1, z1), d (x0, z1).
	func ground_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> Builder:
		var n1 := (c - a).cross(b - a).normalized()
		var n2 := (d - a).cross(c - a).normalized()
		_tri(a, b, c, n1 if n1.y > 0.0 else -n1, color)
		_tri(a, c, d, n2 if n2.y > 0.0 else -n2, color)
		return self

	## A ground triangle (any heights), lit by its own upward normal.
	func ground_tri(a: Vector3, b: Vector3, c: Vector3, color: Color) -> Builder:
		var n := (c - a).cross(b - a).normalized()
		_tri(a, b, c, n if n.y > 0.0 else -n, color)
		return self

	## Cylinder along local Y, centred at `pos`.
	func cyl(radius: float, height: float, pos: Vector3, color: Color, segments := 8,
			rot := Basis.IDENTITY, xf := Transform3D.IDENTITY) -> Builder:
		var t := xf * Transform3D(rot, pos)
		var hy := height * 0.5
		var up := (t.basis * Vector3.UP).normalized()
		for i in segments:
			var a0 := TAU * i / segments
			var a1 := TAU * (i + 1) / segments
			var p0 := Vector3(cos(a0) * radius, 0, sin(a0) * radius)
			var p1 := Vector3(cos(a1) * radius, 0, sin(a1) * radius)
			var mid := (a0 + a1) * 0.5
			var n := (t.basis * Vector3(cos(mid), 0, sin(mid))).normalized()
			_quad(t * (p0 + Vector3.UP * -hy), t * (p1 + Vector3.UP * -hy),
				t * (p1 + Vector3.UP * hy), t * (p0 + Vector3.UP * hy), n, color)
			_tri(t * Vector3(0, hy, 0), t * (p0 + Vector3.UP * hy), t * (p1 + Vector3.UP * hy), up, color)
			_tri(t * Vector3(0, -hy, 0), t * (p1 - Vector3.UP * hy), t * (p0 - Vector3.UP * hy), -up, color)
		return self

	func mesh() -> ArrayMesh:
		return st.commit()

	## Finish into a MeshInstance3D. Uses the shared vertex-colour material unless one is given.
	func instance(material: Material = null, shadows := true) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = material if material else MeshKit.baked_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return mi


# --- Round, painted shapes (characters) ------------------------------------------------
# A Shape is geometry made once and reused: smooth-shaded triangles grouped into faces (a quad,
# a cap, a box side). A Body copies shapes into packed arrays, which is fast enough to build a
# whole zombie per spawn, and paints each face one colour from where its centre lies.

## Geometry built once, reused by every model. Vertices are grouped into faces (`starts[f]` is
## the first vertex of face f, the last entry the vertex count) with one centre each for painting.
## `bands` ([y_min, y_max, first_face, end_face]) let painting skip faces far from a rule.
class Shape:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var centres := PackedVector3Array()
	var starts := PackedInt32Array([0])
	var bands: Array = []
	## A loft's cross-section every PROFILE_STEP metres from y0 up: (half-width, half-depth,
	## depth offset). Empty for shapes that aren't lofts. Used to lay stains on the surface.
	var profile := PackedVector3Array()
	var y0 := 0.0
	var y1 := 0.0
	var power := 2.0

	## The surface straight out from the axis through `p` (at p's height): [point, normal].
	## The normal is level (a loft's sides are near upright where stains go).
	func surface(p: Vector3) -> Array:
		var y := clampf(p.y, y0, y1)
		var r := profile[int(roundf((y - y0) / MeshKit.PROFILE_STEP))]
		var dx := p.x
		var dz := p.z - r.z
		if absf(dx) + absf(dz) < 0.0001:
			dz = -1.0
		var t := pow(pow(absf(dx) / r.x, power) + pow(absf(dz) / r.y, power), -1.0 / power)
		var n := Vector3(signf(dx) * pow(absf(dx * t) / r.x, power - 1.0) / r.x, 0.0,
			signf(dz) * pow(absf(dz * t) / r.y, power - 1.0) / r.y)
		return [Vector3(dx * t, y, r.z + dz * t), n.normalized()]

	## Add one face: triangles as flat lists of points and normals; `out` says which way is outside.
	func face(pts: Array, ns: Array, out: Vector3) -> void:
		var c := Vector3.ZERO
		for i in range(0, pts.size(), 3):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var d: Vector3 = pts[i + 2]
			var na: Vector3 = ns[i]
			var nb: Vector3 = ns[i + 1]
			var nd: Vector3 = ns[i + 2]
			if (b - a).cross(d - a).dot(out) > 0.0: # Godot's front faces wind clockwise
				var t := b
				b = d
				d = t
				var tn := nb
				nb = nd
				nd = tn
			verts.append(a)
			verts.append(b)
			verts.append(d)
			normals.append(na)
			normals.append(nb)
			normals.append(nd)
			c += a + b + d
		centres.append(c / float(pts.size()))
		starts.append(verts.size())

	## Every face of `other`, moved by `xf` (normals by its inverse transpose).
	func merge(other: Shape, xf := Transform3D.IDENTITY) -> Shape:
		var base := verts.size()
		verts.append_array(xf * other.verts)
		normals.append_array(Transform3D(xf.basis.inverse().transposed(), Vector3.ZERO) * other.normals)
		centres.append_array(xf * other.centres)
		for f in range(1, other.starts.size()):
			starts.append(base + other.starts[f])
		return self

	## Group the faces, in the order they were made, into runs for painting to skip.
	func finish(run := 12) -> Shape:
		bands = []
		var n := centres.size()
		for first in range(0, n, run):
			var end := mini(first + run, n)
			var lo := INF
			var hi := -INF
			for f in range(first, end):
				lo = minf(lo, centres[f].y)
				hi = maxf(hi, centres[f].y)
			bands.append([lo, hi, first, end])
		return self


const PROFILE_STEP := 0.01
const STAIN_LIFT := 0.003   # how far a stain stands off the surface (each layer one more)


## (half-width, half-depth, depth offset) of a ring table at height y, straight between rings.
static func ring_at(rings: Array, y: float) -> Vector3:
	var lo: Array = rings[0]
	for i in range(1, rings.size()):
		var hi: Array = rings[i]
		if y <= float(hi[0]) or i == rings.size() - 1:
			var t := clampf(inverse_lerp(float(lo[0]), float(hi[0]), y), 0.0, 1.0)
			var a := Vector3(lo[1], lo[2], lo[3] if lo.size() > 3 else 0.0)
			var b := Vector3(hi[1], hi[2], hi[3] if hi.size() > 3 else 0.0)
			return a.lerp(b, t)
		lo = hi
	return Vector3.ZERO


## A smooth tube through `rings` ([y, half_width, half_depth] or [.., z_offset], bottom to top)
## with `segs` sides; `power` above 2 squares the cross-section off. A face is centred on the
## front (-Z). Ends are closed flat unless `tips` lifts their centres into points (a ball's poles):
## [bottom_tip, top_tip] in metres, or null for an open end.
static func loft(rings: Array, segs := 12, power := 2.0, tips: Array = [0.0, 0.0]) -> Shape:
	var sh := Shape.new()
	var e := 2.0 / power
	var grid: Array[PackedVector3Array] = []
	var axis: Array[Vector3] = []
	for r: Array in rings:
		var row := PackedVector3Array()
		var y: float = r[0]
		var cz: float = r[3] if r.size() > 3 else 0.0
		for j in segs:
			var a := -PI / 2.0 + TAU * (j + 0.5) / segs
			var c := cos(a)
			var s := sin(a)
			row.append(Vector3(float(r[1]) * signf(c) * pow(absf(c), e), y,
				cz + float(r[2]) * signf(s) * pow(absf(s), e)))
		grid.append(row)
		axis.append(Vector3(0, y, cz))
	var n := rings.size()
	var nrm: Array[PackedVector3Array] = []
	for i in n:
		var row := PackedVector3Array()
		for j in segs:
			var around := grid[i][(j + 1) % segs] - grid[i][(j - 1 + segs) % segs]
			var along := grid[mini(i + 1, n - 1)][j] - grid[maxi(i - 1, 0)][j]
			var nn := along.cross(around).normalized()
			if nn.dot(grid[i][j] - axis[i]) < 0.0:
				nn = -nn
			row.append(nn)
		nrm.append(row)
	for i in n - 1:
		for j in segs:
			var k := (j + 1) % segs
			var out := nrm[i][j] + nrm[i][k] + nrm[i + 1][j] + nrm[i + 1][k]
			sh.face([grid[i][j], grid[i][k], grid[i + 1][k], grid[i][j], grid[i + 1][k], grid[i + 1][j]],
				[nrm[i][j], nrm[i][k], nrm[i + 1][k], nrm[i][j], nrm[i + 1][k], nrm[i + 1][j]], out)
	for end in 2:
		if tips[end] == null:
			continue
		var i := 0 if end == 0 else n - 1
		var dir := Vector3.DOWN if end == 0 else Vector3.UP
		var tip := axis[i] + dir * float(tips[end])
		var smooth := float(tips[end]) > 0.0
		var pts := []
		var ns := []
		for j in segs:
			var k := (j + 1) % segs
			pts.append_array([tip, grid[i][j], grid[i][k]])
			ns.append_array([dir, nrm[i][j] if smooth else dir, nrm[i][k] if smooth else dir])
		sh.face(pts, ns, dir)
	sh.power = power
	sh.y0 = rings[0][0]
	sh.y1 = rings[n - 1][0]
	for k in int(ceilf((sh.y1 - sh.y0) / PROFILE_STEP)) + 1:
		sh.profile.append(ring_at(rings, sh.y0 + k * PROFILE_STEP))
	return sh.finish(segs)


static var _units := {}

## Shared unit shapes for clothes and props, stretched by a Body: "box" and "ball" (1 m across,
## centred), "dome" (1 m across and 1 m tall, standing on its centre), "tube" (1 m across and
## tall, centred, flat ends).
static func unit(kind: String) -> Shape:
	if _units.has(kind):
		return _units[kind]
	var sh: Shape
	match kind:
		"ball", "dome":
			var dome := kind == "dome"
			var rings := []
			for k in range(3 if dome else 1, 6):
				var a := PI * k / 6.0
				rings.append([-cos(a) * (1.0 if dome else 0.5), sin(a) * 0.5, sin(a) * 0.5])
			var tip := (1.0 if dome else 0.5) - float(rings[-1][0])
			sh = loft(rings, 10, 2.0, [0.0 if dome else tip, tip])
		"tube":
			sh = loft([[-0.5, 0.5, 0.5], [0.5, 0.5, 0.5]], 10)
		_:
			sh = Shape.new()
			for n: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
				var u := Vector3(n.y, n.z, n.x).abs() * 0.5
				var v := n.cross(u * 2.0).abs() * 0.5
				var c := n * 0.5
				sh.face([c - u - v, c + u - v, c + u + v, c - u - v, c + u + v, c - u + v],
					[n, n, n, n, n, n], n)
			sh.finish()
	_units[kind] = sh
	return sh


## Where a ragged splat's edge falls on a face, the same on every peer: 0..1 from a position.
static func speckle(p: Vector3) -> float:
	var h := int(p.x * 1000.0) * 73856093 ^ int(p.y * 1000.0) * 19349663 ^ int(p.z * 1000.0) * 83492791
	return float((h >> 4) & 0xffff) / 65535.0


## Packed arrays a model is copied into, then committed as one mesh (one draw call).
class Body:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()

	## Add `shape` in `color`, then paint its faces whose centre lies in a region, later rules on top:
	##   [min: Vector3, max: Vector3, color]               a box
	##   [centre: Vector3, radius: float, color, drip]    a ragged splat; `drip` metres stretch it downward
	func add(shape: Shape, color: Color, paints: Array = []) -> Body:
		var cols := PackedColorArray()
		cols.resize(shape.verts.size())
		cols.fill(color)
		for rule: Array in paints:
			var splat: bool = rule[1] is float
			var lo: float
			var hi: float
			var c: Vector3 = rule[0]
			var r := 0.0
			var drip := 0.0
			var mx: Vector3
			if splat:
				r = rule[1]
				drip = rule[3] if rule.size() > 3 else 0.0
				lo = c.y - r * 1.2 - drip
				hi = c.y + r * 1.2
			else:
				mx = rule[1]
				lo = c.y
				hi = mx.y
			var paint: Color = rule[2]
			for band: Array in shape.bands:
				if band[1] < lo or band[0] > hi:
					continue
				for f in range(band[2], band[3]):
					var p := shape.centres[f]
					var hit: bool
					if splat:
						var d := p - c
						if d.y < 0.0 and drip > 0.0:
							d.y /= 1.0 + drip / r
							d.x *= 1.35
						hit = d.length() < r * (0.6 + 0.6 * MeshKit.speckle(p))
					else:
						hit = p.x >= c.x and p.x <= mx.x and p.y >= c.y and p.y <= mx.y and p.z >= c.z and p.z <= mx.z
					if hit:
						for v in range(shape.starts[f], shape.starts[f + 1]):
							cols[v] = paint
		verts.append_array(shape.verts)
		normals.append_array(shape.normals)
		colors.append_array(cols)
		return self

	func _tri(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, color: Color) -> void:
		if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:
			verts.append_array(PackedVector3Array([a, c, b]))
			normals.append_array(PackedVector3Array([na, nc, nb]))
		else:
			verts.append_array(PackedVector3Array([a, b, c]))
			normals.append_array(PackedVector3Array([na, nb, nc]))
		colors.append_array(PackedColorArray([color, color, color]))

	## A ragged stain lying on a loft's surface round `at` (straight out from the axis), with a run
	## `drip` metres down it. `layer` 1 sits on top of a stain of layer 0 (a dark wound core).
	func stain(shape: Shape, at: Vector3, radius: float, color: Color, drip := 0.0, layer := 0) -> Body:
		var lift := MeshKit.STAIN_LIFT * (layer + 1)
		var s0: Array = shape.surface(at)
		var c: Vector3 = s0[0]
		var n: Vector3 = s0[1]
		var side := Vector3.UP.cross(n)
		var k := 7
		var pts := PackedVector3Array()
		var ns := PackedVector3Array()
		for i in k:
			var a := TAU * i / k
			var rad := radius * (0.55 + 0.7 * MeshKit.speckle(at * 7.0 + Vector3(i * 0.131, i * 0.07, 0)))
			var s: Array = shape.surface(c + side * cos(a) * rad + Vector3.UP * sin(a) * rad * 0.85)
			pts.append(s[0] + s[1] * lift)
			ns.append(s[1])
		var mid := c + n * lift
		for i in k:
			_tri(mid, pts[i], pts[(i + 1) % k], n, ns[i], ns[(i + 1) % k], color)
		if drip > 0.0:
			var x := (MeshKit.speckle(at * 3.0) - 0.5) * radius * 0.8
			var w := radius * 0.3
			var l0: Array = shape.surface(c + side * (x - w) - Vector3.UP * radius * 0.3)
			var r0: Array = shape.surface(c + side * (x + w) - Vector3.UP * radius * 0.3)
			for step in range(1, 4):
				var t := step / 3.0
				var ww := w * (1.0 - t * 0.65)
				var down := Vector3.UP * (radius * 0.3 + drip * t)
				var l1: Array = shape.surface(c + side * (x - ww) - down)
				var r1: Array = shape.surface(c + side * (x + ww) - down)
				var pl0: Vector3 = l0[0] + l0[1] * lift
				var pr0: Vector3 = r0[0] + r0[1] * lift
				var pl1: Vector3 = l1[0] + l1[1] * lift
				var pr1: Vector3 = r1[0] + r1[1] * lift
				_tri(pl0, pr0, pr1, l0[1], r0[1], r1[1], color)
				_tri(pl0, pr1, pl1, l0[1], r1[1], l1[1], color)
				l0 = l1
				r0 = r1
		return self

	## A shape moved by `xf`, all one colour.
	func put(shape: Shape, xf: Transform3D, color: Color) -> Body:
		verts.append_array(xf * shape.verts)
		normals.append_array(Transform3D(xf.basis.inverse().transposed(), Vector3.ZERO) * shape.normals)
		var cols := PackedColorArray()
		cols.resize(shape.verts.size())
		cols.fill(color)
		colors.append_array(cols)
		return self

	## A unit shape (MeshKit.unit) stretched to `size`, centred at `pos`, turned by `rot`.
	func part(kind: String, size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> Body:
		return put(MeshKit.unit(kind), Transform3D(rot * Basis.from_scale(size), pos), color)

	func box(size: Vector3, pos: Vector3, color: Color, rot := Basis.IDENTITY) -> Body:
		return part("box", size, pos, color, rot)

	func mesh() -> ArrayMesh:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		return m

	func instance(material: Material = null, shadows := true) -> MeshInstance3D:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh()
		mi.material_override = material if material else MeshKit.baked_material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows \
			else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		return mi
