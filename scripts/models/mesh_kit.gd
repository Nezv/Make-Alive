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
