class_name MeshKit
## Build models in code. Convention: models stand on y=0, face -Z, 1 unit = 1 metre.
## A Builder merges every shape you add into ONE mesh (one draw call) using vertex colours,
## so a whole building, car, or body part costs a single draw call.
##
## The quality kit (see references/asset_quality.md): `rbox` (bevelled box with rounded shading),
## `lathe` / `rcyl` / `cone` (turned shapes: posts, pots, lamps, tanks), `blob` (lumpy rounded
## masses: canopies, bushes, sandbags, rocks) and `tube` (cables, pipes, rails, branches). They
## all shade a colour darker toward their foot (`shade`) and lighter on their edges (`edge_light`),
## the cheap stand-ins for ambient occlusion and edge wear.
##
## A colour's ALPHA is its surface class, read by the shared world shader: `surf(c, MeshKit.METAL)`.
## Plain colours (alpha 1) are MATTE, so old code keeps its look.

const MATTE := 1.0     ## plaster, concrete, wood, cloth: the default
const PAVERS := 0.9    ## concrete pavers laid in a weave (ground)
const PAINT := 0.8     ## car paint, enamel signs, glazed tile, plastic: a soft highlight
const BRICK := 0.7     ## brick in running bond (walls, the walking lane)
const METAL := 0.6     ## galvanised steel, chrome, brass
const TILE := 0.5      ## square tiles with grout (floors, toilet walls)
const GLASS := 0.4     ## windows, screens, lamp covers: sharp reflections
const BARK := 0.3      ## bark and rough wood: vertical grain
const LEAF := 0.2      ## leaves and petals: light comes through
const SOOT := 0.1      ## rubber, tar, burnt things: no highlight at all

## A colour tagged with a surface class (one of the constants above).
static func surf(c: Color, kind: float) -> Color:
	return Color(c.r, c.g, c.b, kind)


const WORLD_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform float grain = 0.09;          // how much every surface mottles
uniform float grain_scale = 1.3;     // mottles per metre
varying vec3 lp;

float h3(vec3 q) {
	vec3 p = fract(q * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vn(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
// 0 on a grout line, 1 inside a unit. `uv` is in units, `w` the lines' half widths in units,
// `fw` how many units one pixel covers (fwidth, taken in fragment()). Fades to flat far away.
float grout(vec2 uv, vec2 w, vec2 fw) {
	vec2 d = min(fract(uv), 1.0 - fract(uv));
	vec2 aa = fw * 0.75 + 1e-4;
	float lines = smoothstep(w.x - aa.x, w.x + aa.x, d.x) * smoothstep(w.y - aa.y, w.y + aa.y, d.y);
	return mix(0.85, lines, clamp(1.5 - max(aa.x, aa.y) * 6.0, 0.0, 1.0));
}
// Pavers in a basket weave: 2:1 blocks, pairs turning at right angles cell by cell.
float weave(vec2 p, vec2 fw) {
	vec2 c = floor(p * 0.5);
	vec2 q = p - c * 2.0;
	bool turn = mod(c.x + c.y, 2.0) > 0.5;
	vec2 uv = turn ? vec2(q.x, q.y * 0.5) : vec2(q.x * 0.5, q.y);
	vec2 fu = turn ? vec2(fw.x, fw.y * 0.5) : vec2(fw.x * 0.5, fw.y);
	return grout(uv, turn ? vec2(0.04, 0.02) : vec2(0.02, 0.04), fu);
}
// Running bond: one unit is one brick, every other row shifted by half a brick.
float bond(vec2 p, vec2 fw) {
	vec2 q = vec2(p.x + mod(floor(p.y), 2.0) * 0.5, p.y);
	return grout(q, vec2(0.04, 0.1), fw);
}

void vertex() {
	lp = VERTEX;
}

void fragment() {
	int k = int(round(COLOR.a * 10.0));
	float n = vn(lp * grain_scale) * 0.6 + vn(lp * grain_scale * 6.0) * 0.4;
	float g = grain;
	float rough = 0.86;
	float metal = 0.0;
	float spec = 0.35;
	float leaf = 0.0;
	float shade = 1.0;
	vec3 up_w = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	if (k == 9) {         // pavers
		vec2 wp = lp.xz / 0.12;
		shade = mix(0.55, 1.0, weave(wp, fwidth(wp))) * (0.9 + 0.2 * h3(vec3(floor(lp.xz / 0.24), 3.0)));
		g *= 1.4;
	} else if (k == 8) {  // paint
		rough = 0.4; spec = 0.55; g *= 0.35;
	} else if (k == 7) {  // brick
		vec2 bp = abs(up_w.y) > 0.6 ? lp.xz : (abs(up_w.x) > abs(up_w.z) ? lp.zy : lp.xy);
		vec2 bu = bp / vec2(0.2, 0.07);
		float shift = mod(floor(bu.y), 2.0) * 0.5;
		shade = mix(0.6, 1.0, bond(bu, fwidth(bu))) * (0.86 + 0.28 * h3(vec3(floor(bu.x + shift), floor(bu.y), 1.0)));
	} else if (k == 6) {  // metal
		rough = 0.36; metal = 0.75; spec = 0.6; g *= 0.6;
	} else if (k == 5) {  // tile
		vec2 tp = abs(up_w.y) > 0.6 ? lp.xz : (abs(up_w.x) > abs(up_w.z) ? lp.zy : lp.xy);
		shade = mix(0.7, 1.0, grout(tp / 0.3, vec2(0.025), fwidth(tp / 0.3)));
		rough = 0.3; spec = 0.6; g *= 0.3;
	} else if (k == 4) {  // glass
		rough = 0.05; metal = 0.15; spec = 0.9; g = 0.0;
	} else if (k == 3) {  // bark
		shade = 0.75 + 0.5 * vn(lp * vec3(9.0, 0.7, 9.0));
		rough = 0.95;
	} else if (k == 2) {  // leaf
		rough = 0.65; spec = 0.3; leaf = 1.0; g *= 1.6;
	} else if (k == 1) {  // soot, rubber
		rough = 0.95; spec = 0.12;
	}
	ALBEDO = COLOR.rgb * shade * (1.0 + (n - 0.5) * 2.0 * g);
	ROUGHNESS = clamp(rough + (n - 0.5) * 0.2, 0.03, 1.0);
	METALLIC = metal;
	SPECULAR = spec;
	RIM = 0.18 * (1.0 - metal);
	RIM_TINT = 0.6;
	BACKLIGHT = COLOR.rgb * 0.7 * leaf;
}
"""

static var _baked: ShaderMaterial

## Shared material for all builder meshes: colour comes from vertex colours, the surface class
## from their alpha (see WORLD_SHADER).
static func baked_material() -> ShaderMaterial:
	if _baked == null:
		var sh := Shader.new()
		sh.code = WORLD_SHADER
		_baked = ShaderMaterial.new()
		_baked.shader = sh
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


## A number in 0..1 from three integers, the same on every peer (never randf for looks).
static func hash01(key: int, i: int, j: int) -> float:
	var h := (key * 73856093) ^ (i * 19349663) ^ (j * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h >> 8) & 0xFFFF) / 65535.0


## Points of a cable hanging from `a` to `b`, `droop` metres low in the middle.
static func sag(a: Vector3, b: Vector3, droop: float, steps := 8) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps + 1:
		var f := float(i) / steps
		out.append(a.lerp(b, f) + Vector3(0, -droop * 4.0 * f * (1.0 - f), 0))
	return out


## Points of a curve from `a` to `b` bowed toward `bend` (a quadratic Bézier).
static func arc(a: Vector3, bend: Vector3, b: Vector3, steps := 6) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps + 1:
		var f := float(i) / steps
		out.append(a.lerp(bend, f).lerp(bend.lerp(b, f), f))
	return out


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

	# --- The quality kit -----------------------------------------------------------------

	var shade := 0.22        ## how much darker the foot of a kit shape is than its top
	var edge_light := 0.07   ## how much lighter a bevel is than the faces it joins
	var bevel := 0.045       ## default bevel radius in metres (capped by the shape's size)

	## One triangle with a normal and a colour per corner (smooth shading).
	func _tri3(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			ca: Color, cb: Color, cc: Color) -> void:
		if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:
			var tv := b
			b = c
			c = tv
			var tn := nb
			nb = nc
			nc = tn
			var tc := cb
			cb = cc
			cc = tc
		st.set_color(ca)
		st.set_normal(na)
		st.add_vertex(a)
		st.set_color(cb)
		st.set_normal(nb)
		st.add_vertex(b)
		st.set_color(cc)
		st.set_normal(nc)
		st.add_vertex(c)
		count += 1

	## `color` darkened toward the foot: `f` is 0 at the bottom of the shape, 1 at its top.
	func _graded(color: Color, f: float, lift := 0.0) -> Color:
		var k := (1.0 - shade * (1.0 - clampf(f, 0.0, 1.0))) * (1.0 + lift)
		return Color(color.r * k, color.g * k, color.b * k, color.a)

	## Bevelled box: like `box`, but every edge is cut at 45° (`r` metres, -1 = the Builder's
	## `bevel`, capped at a third of the thinnest side) and shaded round, so light catches it.
	## 44 triangles instead of 12.
	func rbox(size: Vector3, pos: Vector3, color: Color, r := -1.0, rot := Basis.IDENTITY,
			xf := Transform3D.IDENTITY) -> Builder:
		var h := size.abs() * 0.5
		var thin := minf(h.x, minf(h.y, h.z))
		var rr := (bevel if r < 0.0 else r)
		rr = minf(rr, thin * 0.66)
		if rr < 0.003:
			return box(size, pos, color, rot, xf)
		var t := xf * Transform3D(rot, pos)
		var hi := h - Vector3(rr, rr, rr)
		var pts := {}    # (sign, out axis) -> [world point, world normal, colour]
		for sx in [-1, 1]:
			for sy in [-1, 1]:
				for sz in [-1, 1]:
					var sg := Vector3(sx, sy, sz)
					for ax in 3:
						var p := hi * sg
						p[ax] = h[ax] * sg[ax]
						var n := Vector3.ZERO
						n[ax] = sg[ax]
						pts[Vector4i(sx, sy, sz, ax)] = [t * p, (t.basis * n).normalized(), (p.y + h.y) / (2.0 * h.y)]
		var cface := func(k: Vector4i, lift: float) -> Color: return _graded(color, pts[k][2], lift)
		# Faces: axis `ax`, side `s`; corners round the other two axes.
		for ax in 3:
			var u := (ax + 1) % 3
			var v := (ax + 2) % 3
			for s in [-1, 1]:
				var ks := []
				for uv: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
					var sg := Vector3i.ZERO
					sg[ax] = s
					sg[u] = uv.x
					sg[v] = uv.y
					ks.append(Vector4i(sg.x, sg.y, sg.z, ax))
				_quad3(ks, pts, cface, 0.0)
		# Edge strips between face `a` and face `b`, running along the third axis.
		for a in 3:
			var bb := (a + 1) % 3
			var k3 := (a + 2) % 3
			for sa in [-1, 1]:
				for sb in [-1, 1]:
					var ks := []
					for step: Array in [[-1, a], [1, a], [1, bb], [-1, bb]]:
						var sg := Vector3i.ZERO
						sg[a] = sa
						sg[bb] = sb
						sg[k3] = step[0]
						ks.append(Vector4i(sg.x, sg.y, sg.z, step[1]))
					_quad3(ks, pts, cface, edge_light)
		# Corner triangles.
		for sx in [-1, 1]:
			for sy in [-1, 1]:
				for sz in [-1, 1]:
					var k0 := Vector4i(sx, sy, sz, 0)
					var k1 := Vector4i(sx, sy, sz, 1)
					var k2 := Vector4i(sx, sy, sz, 2)
					_tri3(pts[k0][0], pts[k1][0], pts[k2][0], pts[k0][1], pts[k1][1], pts[k2][1],
						cface.call(k0, edge_light), cface.call(k1, edge_light), cface.call(k2, edge_light))
		return self

	func _quad3(ks: Array, pts: Dictionary, cface: Callable, lift: float) -> void:
		var p := []
		var n := []
		var c := []
		for k: Vector4i in ks:
			p.append(pts[k][0])
			n.append(pts[k][1])
			c.append(cface.call(k, lift))
		_tri3(p[0], p[1], p[2], n[0], n[1], n[2], c[0], c[1], c[2])
		_tri3(p[0], p[2], p[3], n[0], n[2], n[3], c[0], c[2], c[3])

	## A turned shape round local Y, centred on `pos`: `profile` is (radius, y) points from the
	## bottom (radius 0 closes it) to the top. Normals are smoothed along the profile, so a few
	## points make a rounded pot, a lamp head, a bollard or a tank. `squash` scales x and z apart
	## (Vector2(1, 1) = round).
	func lathe(profile: PackedVector2Array, pos: Vector3, color: Color, segments := 12,
			rot := Basis.IDENTITY, xf := Transform3D.IDENTITY, squash := Vector2.ONE) -> Builder:
		var t := xf * Transform3D(rot, pos)
		var m := profile.size()
		if m < 2:
			return self
		var y0 := profile[0].y
		var y1 := profile[m - 1].y
		var span := maxf(y1 - y0, 0.001)
		# Outward normal of each profile segment, then averaged at each point.
		var seg_n := []
		for i in m - 1:
			var d := profile[i + 1] - profile[i]
			seg_n.append(Vector2(d.y, -d.x).normalized() if d.length() > 1e-5 else Vector2.ZERO)
		var pn := []
		for i in m:
			var acc := Vector2.ZERO
			if i > 0:
				acc += seg_n[i - 1]
			if i < m - 1:
				acc += seg_n[i]
			pn.append(acc.normalized() if acc.length() > 1e-5 else Vector2(0, 1))
		for i in m - 1:
			var pa := profile[i]
			var pb := profile[i + 1]
			if pa.distance_to(pb) < 1e-5:
				continue
			var na: Vector2 = pn[i]
			var nb: Vector2 = pn[i + 1]
			var ca := _graded(color, (pa.y - y0) / span)
			var cb := _graded(color, (pb.y - y0) / span)
			for j in segments:
				var a0 := TAU * j / segments
				var a1 := TAU * (j + 1) / segments
				var d0 := Vector3(cos(a0) * squash.x, 0, sin(a0) * squash.y)
				var d1 := Vector3(cos(a1) * squash.x, 0, sin(a1) * squash.y)
				var q00 := t * (d0 * pa.x + Vector3(0, pa.y, 0))
				var q01 := t * (d1 * pa.x + Vector3(0, pa.y, 0))
				var q10 := t * (d0 * pb.x + Vector3(0, pb.y, 0))
				var q11 := t * (d1 * pb.x + Vector3(0, pb.y, 0))
				var n00 := (t.basis * (Vector3(cos(a0) / squash.x, 0, sin(a0) / squash.y).normalized() * na.x + Vector3(0, na.y, 0))).normalized()
				var n01 := (t.basis * (Vector3(cos(a1) / squash.x, 0, sin(a1) / squash.y).normalized() * na.x + Vector3(0, na.y, 0))).normalized()
				var n10 := (t.basis * (Vector3(cos(a0) / squash.x, 0, sin(a0) / squash.y).normalized() * nb.x + Vector3(0, nb.y, 0))).normalized()
				var n11 := (t.basis * (Vector3(cos(a1) / squash.x, 0, sin(a1) / squash.y).normalized() * nb.x + Vector3(0, nb.y, 0))).normalized()
				if pa.x > 1e-5:
					_tri3(q00, q01, q11, n00, n01, n11, ca, ca, cb)
				if pb.x > 1e-5:
					_tri3(q00, q11, q10, n00, n11, n10, ca, cb, cb)
		return self

	## Rounded cylinder along local Y centred at `pos`: bevelled rims (`r`, -1 = auto) and smooth
	## sides. For posts, tanks, wheels (turn it with `rot`), bollards, cans.
	func rcyl(radius: float, height: float, pos: Vector3, color: Color, segments := 12, r := -1.0,
			rot := Basis.IDENTITY, xf := Transform3D.IDENTITY) -> Builder:
		var hy := height * 0.5
		var rr := minf(bevel if r < 0.0 else r, minf(radius * 0.4, hy * 0.6))
		return lathe(PackedVector2Array([Vector2(0, -hy), Vector2(radius - rr, -hy), Vector2(radius, -hy + rr),
			Vector2(radius, hy - rr), Vector2(radius - rr, hy), Vector2(0, hy)]), pos, color, segments, rot, xf)

	## A cone or a tapered post from `r0` at the bottom to `r1` at the top, `height` tall, its foot
	## at `pos`. Closed both ends.
	func taper(r0: float, r1: float, height: float, pos: Vector3, color: Color, segments := 10,
			rot := Basis.IDENTITY, xf := Transform3D.IDENTITY) -> Builder:
		var pts := PackedVector2Array([Vector2(0, 0), Vector2(r0, 0), Vector2(r0, minf(0.02, height * 0.1)), Vector2(r1, height)])
		if r1 > 0.001:
			pts.append(Vector2(0, height))
		return lathe(pts, pos, color, segments, rot, xf)

	## A flat-faced rectangular frustum: `bottom` (x, z) at its foot (`pos`), `top` (x, z) `height`
	## above, the top moved by `shift` (x, z). Buttresses, plinths that widen to the ground, hoppers,
	## wedges (a `top` of zero depth). Shaded darker at the foot like the other kit shapes. 12 triangles.
	func frustum(bottom: Vector2, top: Vector2, height: float, pos: Vector3, color: Color,
			rot := Basis.IDENTITY, xf := Transform3D.IDENTITY, shift := Vector2.ZERO) -> Builder:
		var t := xf * Transform3D(rot, pos)
		var lo_c := []
		var hi_c := []
		for k: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			lo_c.append(Vector3(k.x * bottom.x * 0.5, 0, k.y * bottom.y * 0.5))
			hi_c.append(Vector3(k.x * top.x * 0.5 + shift.x, height, k.y * top.y * 0.5 + shift.y))
		var mid := Vector3(shift.x * 0.5, height * 0.5, shift.y * 0.5)
		var c0 := _graded(color, 0.0)
		var c1 := _graded(color, 1.0)
		for i in 4:
			var a: Vector3 = lo_c[i]
			var b: Vector3 = lo_c[(i + 1) % 4]
			var c: Vector3 = hi_c[(i + 1) % 4]
			var d: Vector3 = hi_c[i]
			var n := (b - a).cross(d - a).normalized()
			if n.dot((a + b + c + d) * 0.25 - mid) < 0.0:
				n = -n
			var wn := (t.basis * n).normalized()
			_tri3(t * a, t * b, t * c, wn, wn, wn, c0, c0, c1)
			_tri3(t * a, t * c, t * d, wn, wn, wn, c0, c1, c1)
		var up := (t.basis * Vector3.UP).normalized()
		_tri3(t * hi_c[0], t * hi_c[1], t * hi_c[2], up, up, up, c1, c1, c1)
		_tri3(t * hi_c[0], t * hi_c[2], t * hi_c[3], up, up, up, c1, c1, c1)
		return self

	## A lumpy rounded mass of `radii` centred at `pos`: canopy clumps, bushes, sandbags, rocks,
	## heaps. `lump` (0..0.4) dents it, from `key` (the same key, the same shape on every peer).
	## `flat` cuts the bottom flat at that fraction of the height (0.5 = a half dome on the ground).
	func blob(radii: Vector3, pos: Vector3, color: Color, key := 0, lump := 0.15, rings := 5,
			segments := 8, rot := Basis.IDENTITY, xf := Transform3D.IDENTITY, flat := 0.0) -> Builder:
		var t := xf * Transform3D(rot, pos)
		var grid := []
		var norms := []
		var cols := []
		for i in rings + 1:
			var row := []
			var nrow := []
			var crow := []
			var phi := PI * float(i) / rings            # 0 at the top
			for j in segments:
				var th := TAU * float(j) / segments
				var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
				var k := 1.0
				if i > 0 and i < rings:
					k += lump * (MeshKit.hash01(key, i, j) - 0.5) * 2.0
				var p := dir * radii * k
				var floor_y := -radii.y + flat * 2.0 * radii.y
				var nl := (dir / radii).normalized()
				if flat > 0.0 and p.y < floor_y:
					p.y = floor_y
					nl = (nl + Vector3.DOWN * 2.0).normalized()
				row.append(t * p)
				nrow.append((t.basis * nl).normalized())
				crow.append(_graded(color, (p.y + radii.y) / (2.0 * radii.y), 0.0))
			grid.append(row)
			norms.append(nrow)
			cols.append(crow)
		for i in rings:
			for j in segments:
				var j1 := (j + 1) % segments
				var a: Vector3 = grid[i][j]
				var b: Vector3 = grid[i][j1]
				var c: Vector3 = grid[i + 1][j1]
				var d: Vector3 = grid[i + 1][j]
				if i > 0:
					_tri3(a, b, c, norms[i][j], norms[i][j1], norms[i + 1][j1], cols[i][j], cols[i][j1], cols[i + 1][j1])
				if i < rings - 1:
					_tri3(a, c, d, norms[i][j], norms[i + 1][j1], norms[i + 1][j], cols[i][j], cols[i + 1][j1], cols[i + 1][j])
		return self

	## A round tube through `points` (world space if `xf` is identity), `radius` thick, or tapering
	## from `radius` to `radius_end`. Smooth, open ended unless `caps`. For cables, pipes, hand rails,
	## branches, roots, vines.
	func tube(points: PackedVector3Array, radius: float, color: Color, sides := 6, radius_end := -1.0,
			xf := Transform3D.IDENTITY, caps := false) -> Builder:
		var m := points.size()
		if m < 2:
			return self
		var r1 := radius if radius_end < 0.0 else radius_end
		var wp := PackedVector3Array()
		for p in points:
			wp.append(xf * p)
		var rings := []
		var rnorm := []
		var side := Vector3.ZERO
		for i in m:
			var tg := (wp[mini(i + 1, m - 1)] - wp[maxi(i - 1, 0)]).normalized()
			if side == Vector3.ZERO or absf(side.dot(tg)) > 0.95:
				side = tg.cross(Vector3.UP if absf(tg.y) < 0.9 else Vector3.RIGHT).normalized()
			else: # carry the frame along so the tube does not twist
				side = (side - tg * side.dot(tg)).normalized()
			var up := side.cross(tg).normalized()
			var rad := lerpf(radius, r1, float(i) / (m - 1))
			var ring := []
			var nr := []
			for k in sides:
				var a := TAU * k / sides
				var n := side * cos(a) + up * sin(a)
				ring.append(wp[i] + n * rad)
				nr.append(n)
			rings.append(ring)
			rnorm.append(nr)
		for i in m - 1:
			var c0 := _graded(color, 1.0, 0.0)
			for k in sides:
				var k1 := (k + 1) % sides
				_tri3(rings[i][k], rings[i][k1], rings[i + 1][k1], rnorm[i][k], rnorm[i][k1], rnorm[i + 1][k1], c0, c0, c0)
				_tri3(rings[i][k], rings[i + 1][k1], rings[i + 1][k], rnorm[i][k], rnorm[i + 1][k1], rnorm[i + 1][k], c0, c0, c0)
		if caps:
			for e: int in [0, m - 1]:
				var tg := (wp[mini(e + 1, m - 1)] - wp[maxi(e - 1, 0)]).normalized() * (1.0 if e > 0 else -1.0)
				for k in sides:
					_tri(wp[e], rings[e][k], rings[e][(k + 1) % sides], tg, color)
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
