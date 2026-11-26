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
