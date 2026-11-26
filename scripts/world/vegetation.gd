class_name Vegetation
## Trees and bushes from boxes, like Props: `plant` draws one into the Builder it is given (so a
## whole hillside stays one mesh) at transform `t`, and returns its solid parts as
## [[center, size], ...] in its own space: a tree's trunk, nothing for a bush. Plants stand on
## y = 0. Every shape comes from the rng passed in (the map's seeded one), so every peer grows
## the same forest; a few seeds give a few shapes per species.
##
## The species are the ones in the Mirante photos and the Atlantic forest on Morro da Boa Vista:
## broad canopy trees, imperial and juçara palms, araucárias, ipês in bloom, tree ferns, and
## hibiscus and bougainvillea by the gate.

enum Kind { BROADLEAF, IMPERIAL_PALM, JUCARA, ARAUCARIA, IPE_YELLOW, IPE_PURPLE, TREE_FERN, HIBISCUS, BOUGAINVILLEA, COUNT }
const NAMES := ["broadleaf", "imperial palm", "juçara", "araucária", "yellow ipê", "purple ipê", "tree fern", "hibiscus", "bougainvillea"]

## Alpha is the surface class (MeshKit): 4d BARK (vertical grain), 33 LEAF (light comes through).
const BARK := Color("3b31284d")
const BARK_GREY := Color("6d6a624d")    ## imperial palm trunks are smooth and pale
const LEAVES := [Color("1f3a22"), Color("27482c"), Color("1a3020"), Color("2f5230"), Color("355a32")]
const LEAVES_LIT := [Color("3f6a36"), Color("4a7a3a"), Color("3a6234")]   ## sunlit tufts on top of a crown
const FROND := Color("2d4a2433")
const CROWNSHAFT := Color("4f6a32")
const NEEDLES := Color("1a2e1e33")
const IPE_YELLOW := Color("e0b41c33")
const IPE_PURPLE := Color("9a4a9e33")
const HIBISCUS_RED := Color("c4161c33")
const BOUGAINVILLEA_PINK := Color("c8237a33")


static func leaf(c: Color) -> Color:
	return MeshKit.surf(c, MeshKit.LEAF)


static func plant(b: MeshKit.Builder, t: Transform3D, kind: int, rng: RandomNumberGenerator) -> Array:
	match kind:
		Kind.BROADLEAF: return _broadleaf(b, t, rng, rng.randf_range(8.0, 14.0), [])
		Kind.IMPERIAL_PALM: return _palm(b, t, rng, rng.randf_range(20.0, 26.0), 0.36, 12, 4.6)
		Kind.JUCARA: return _palm(b, t, rng, rng.randf_range(8.0, 12.0), 0.12, 8, 2.8)
		Kind.ARAUCARIA: return _araucaria(b, t, rng)
		Kind.IPE_YELLOW: return _ipe(b, t, rng, IPE_YELLOW)
		Kind.IPE_PURPLE: return _ipe(b, t, rng, IPE_PURPLE)
		Kind.TREE_FERN: return _fern(b, t, rng)
		Kind.HIBISCUS: return _bush(b, t, rng, HIBISCUS_RED, 14)
		Kind.BOUGAINVILLEA: return _bush(b, t, rng, BOUGAINVILLEA_PINK, 40)
	return []


## A seeded pick for the Atlantic forest beside a road: mostly broad trees, then ferns and palms.
static func forest_kind(rng: RandomNumberGenerator) -> int:
	var r := rng.randf()
	if r < 0.5: return Kind.BROADLEAF
	if r < 0.68: return Kind.TREE_FERN
	if r < 0.82: return Kind.JUCARA
	if r < 0.9: return Kind.ARAUCARIA
	if r < 0.95: return Kind.IPE_PURPLE
	return Kind.IPE_YELLOW


static func _trunk(width: float, height: float) -> Array:
	return [[Vector3(0, height * 0.5, 0), Vector3(width, height, width)]]


## A trunk from the ground to `top`, `w` wide at the foot, flaring into roots, leaning as `top` does.
static func _bole(b: MeshKit.Builder, t: Transform3D, top: Vector3, w: float, color := BARK) -> void:
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(w * 1.1, 0), Vector2(w * 0.75, 0.25), Vector2(w * 0.55, 0.7), Vector2(0, 0.7)]),
		Vector3.ZERO, color.darkened(0.1), 7, Basis.IDENTITY, t)
	b.tube(MeshKit.arc(Vector3(0, 0.4, 0), Vector3(top.x * 0.3, top.y * 0.5, top.z * 0.3), top, 4), w * 0.5, color, 7, w * 0.3, t)


## Trunk, limbs reaching up into a crown of lumpy rounded clumps, sunlit tufts on top.
## `bloom` colours most of the clumps.
static func _broadleaf(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, h: float, bloom: Array) -> Array:
	var bole := h * rng.randf_range(0.45, 0.6)
	var w := rng.randf_range(0.35, 0.6)
	var top := Vector3(rng.randf_range(-0.4, 0.4), bole + 0.6, rng.randf_range(-0.4, 0.4))
	_bole(b, t, top, w)
	var crown := h - bole
	var spread := rng.randf_range(2.2, 3.4)
	var key := rng.randi()
	var clumps := rng.randi_range(5, 7)
	for i in clumps:
		var a := TAU * i / clumps + rng.randf_range(-0.4, 0.4)
		var r := rng.randf_range(spread * 0.4, spread * 0.75) if i > 0 else 0.0
		var size := Vector3(rng.randf_range(1.4, 2.2), rng.randf_range(0.9, 1.4), rng.randf_range(1.4, 2.2))
		var y := bole + rng.randf_range(0.6, maxf(0.8, crown - size.y - 0.3))
		if i == 0:
			y = h - size.y
		var c := Vector3(cos(a) * r, y, sin(a) * r) + top * Vector3(1, 0, 1)
		if i > 0: # a limb out to every clump
			b.tube(MeshKit.arc(top + Vector3(0, -0.4, 0), top.lerp(c, 0.5) + Vector3(0, 0.6, 0), c + Vector3(0, -size.y * 0.3, 0), 3),
				w * 0.22, BARK, 5, w * 0.1, t)
		var color: Color = LEAVES[rng.randi() % LEAVES.size()]
		if not bloom.is_empty() and rng.randf() < 0.8:
			color = bloom[rng.randi() % bloom.size()]
		b.blob(size, c, leaf(color), key + i, 0.22, 4, 8, Basis(Vector3.UP, rng.randf() * TAU), t)
		if bloom.is_empty() and i % 2 == 0: # a lighter tuft on top where the light falls
			var lit: Color = LEAVES_LIT[rng.randi() % LEAVES_LIT.size()]
			b.blob(size * 0.45, c + Vector3(rng.randf_range(-0.4, 0.4), size.y * 0.7, rng.randf_range(-0.4, 0.4)), leaf(lit), key + 50 + i, 0.2, 3, 6, Basis.IDENTITY, t)
	return _trunk(w, bole)


## One frond: a midrib arching out along `dir` and drooping, with paired leaflets in a V along
## it, narrowing to the tip.
static func _frond(b: MeshKit.Builder, t: Transform3D, base: Vector3, yaw: float, length: float, lift: float,
		droop: float, width: float, color: Color) -> void:
	var out := Basis(Vector3.UP, yaw) * Vector3(0, 0, -1)
	var tip := base + out * length * 0.9 + Vector3(0, lift - droop * length, 0)
	var mid := base + out * length * 0.5 + Vector3(0, lift + length * 0.15, 0)
	var pts := MeshKit.arc(base, mid, tip, 6)
	b.tube(pts, width * 0.06, color.darkened(0.2), 4, width * 0.02, t)
	for i in pts.size() - 1:
		var p0 := pts[i]
		var p1 := pts[i + 1]
		var along := (p1 - p0).normalized()
		var side := along.cross(Vector3.UP).normalized()
		var f := float(i) / (pts.size() - 1)
		var wide := width * (1.0 - f * 0.75) * (0.6 if i == 0 else 1.0)
		var seg := p0.distance_to(p1)
		for sd in [-1.0, 1.0]: # the two halves fold up into a V
			var out_dir: Vector3 = side * sd
			var center := (p0 + p1) * 0.5 + out_dir * wide * 0.25 + Vector3(0, wide * 0.06, 0)
			b.box(Vector3(wide * 0.5, 0.03, seg * 1.05), center, color, _leaf_basis(along, out_dir), t)


## A leaflet's basis: long along `along`, wide toward `out`, tilted up a little at its outer edge.
static func _leaf_basis(along: Vector3, out: Vector3) -> Basis:
	var x := out.normalized()
	var z := along.normalized()
	var y := z.cross(x).normalized()
	if y.y < 0.0:
		y = -y
		x = -x
	return Basis(x, y, z).orthonormalized() * Basis(Vector3.BACK, 0.35 * signf(x.dot(out)))


## A tall palm: ringed trunk, a green crownshaft for the big ones, fronds arching all round.
static func _palm(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, h: float, radius: float,
		fronds: int, frond_len: float) -> Array:
	var bend := Basis(Vector3.RIGHT, rng.randf_range(-0.04, 0.04)) * Basis(Vector3.FORWARD, rng.randf_range(-0.04, 0.04))
	var top := bend * Vector3(0, h - frond_len * 0.35, 0)
	var trunk_color := BARK_GREY if radius > 0.2 else BARK
	b.lathe(PackedVector2Array([Vector2(0, 0), Vector2(radius * 1.5, 0), Vector2(radius * 1.15, 0.3), Vector2(radius, 0.8), Vector2(0, 0.8)]),
		Vector3.ZERO, trunk_color.darkened(0.1), 8, Basis.IDENTITY, t)
	b.tube(PackedVector3Array([Vector3(0, 0.5, 0), top * 0.5, top]), radius, trunk_color, 8, radius * 0.85, t)
	var rings := int(top.y / 0.9)
	for i in rings: # the leaf scars ringing the trunk
		var p := top * ((i + 0.5) / rings)
		b.rcyl(radius * lerpf(1.06, 0.92, float(i) / rings), 0.06, p, trunk_color.darkened(0.25), 8, 0.02, bend, t)
	if radius > 0.2:
		b.rcyl(radius * 0.88, 2.2, top + bend * Vector3(0, 0.8, 0), MeshKit.surf(CROWNSHAFT, MeshKit.PAINT), 8, 0.2, bend, t)
		top += bend * Vector3(0, 1.8, 0)
	b.blob(Vector3(radius * 1.1, radius * 1.4, radius * 1.1), top, leaf(FROND).darkened(0.2), rng.randi(), 0.1, 3, 6, Basis.IDENTITY, t)
	var turn := rng.randf() * TAU
	for i in fronds:
		var a := turn + TAU * i / fronds + rng.randf_range(-0.15, 0.15)
		var droop := rng.randf_range(0.15, 0.4) if i % 2 == 0 else rng.randf_range(0.5, 0.9)
		_frond(b, t, top, a, frond_len, frond_len * 0.25, droop, frond_len * 0.24, FROND)
	return _trunk(radius * 2.0, top.y)


## Straight trunk, bare to near the top, then upturned limbs holding flat pads: the candelabra.
static func _araucaria(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator) -> Array:
	var h := rng.randf_range(16.0, 22.0)
	_bole(b, t, Vector3(0, h - 0.8, 0), 0.6)
	var turn := rng.randf() * TAU
	var key := rng.randi()
	for tier in 3:
		var y := h - 3.6 + tier * 1.2
		var n := 7 - tier
		var reach := rng.randf_range(4.0, 5.2) - tier * 1.2
		for i in n:
			var a := turn + TAU * (i + tier * 0.5) / n
			var out := Vector3(cos(a), 0, sin(a))
			var tip := Vector3(0, y, 0) + out * reach + Vector3(0, reach * 0.35, 0)
			b.tube(MeshKit.arc(Vector3(0, y, 0), Vector3(0, y, 0) + out * reach * 0.6, tip, 3), 0.1, BARK, 5, 0.05, t)
			b.blob(Vector3(1.1, 0.3, 1.1), tip + Vector3(0, 0.15, 0), NEEDLES, key + tier * 10 + i, 0.25, 3, 7, Basis(Vector3.UP, a), t)
	b.blob(Vector3(1.3, 0.45, 1.3), Vector3(0, h - 0.2, 0), NEEDLES, key + 99, 0.2, 3, 7, Basis(Vector3.UP, turn), t)
	return _trunk(0.64, h)


## An ipê in bloom: a broad tree whose crown is mostly flowers, petals fallen round its foot.
static func _ipe(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, color: Color) -> Array:
	var solid := _broadleaf(b, t, rng, rng.randf_range(7.0, 11.0), [color])
	for i in rng.randi_range(10, 18):
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 3.5 + 0.5
		b.box(Vector3(0.35, 0.02, 0.35), Vector3(cos(a) * r, 0.01, sin(a) * r), color, Basis(Vector3.UP, rng.randf() * TAU), t)
	return solid


## Xaxim: a short shaggy trunk and a ring of long arching fronds.
static func _fern(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator) -> Array:
	var h := rng.randf_range(2.6, 4.6)
	b.tube(PackedVector3Array([Vector3(0, 0, 0), Vector3(rng.randf_range(-0.1, 0.1), h * 0.5, rng.randf_range(-0.1, 0.1)), Vector3(0, h, 0)]), 0.24, BARK, 7, 0.2, t)
	for i in int(h / 0.5): # the old frond stubs that make it shaggy
		b.rcyl(0.27, 0.12, Vector3(0, 0.3 + i * 0.5, 0), BARK.darkened(0.25), 7, 0.05, Basis.IDENTITY, t)
	var turn := rng.randf() * TAU
	for i in 11:
		var a := turn + TAU * i / 11.0
		_frond(b, t, Vector3(0, h, 0), a, 2.6, 0.5, rng.randf_range(0.15, 0.5), 0.6, FROND.lightened(0.05))
	b.blob(Vector3(0.3, 0.25, 0.3), Vector3(0, h, 0), leaf(Color("4a5a2a")), rng.randi(), 0.2, 3, 6, Basis.IDENTITY, t)  # the coiled new fronds
	return _trunk(0.4, h)


## A rounded clump of leafy blobs dotted with flowers. Nothing solid: it hides, it does not stop.
static func _bush(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, flower: Color, flowers: int) -> Array:
	var size := rng.randf_range(1.2, 2.0)
	var key := rng.randi()
	var n := rng.randi_range(3, 5)
	for i in n:
		var a := TAU * i / n + rng.randf_range(-0.5, 0.5)
		var r := rng.randf_range(0.0, size * 0.32)
		var s := Vector3(size * rng.randf_range(0.32, 0.45), size * rng.randf_range(0.3, 0.42), size * rng.randf_range(0.32, 0.45))
		b.blob(s, Vector3(cos(a) * r, s.y * 0.9, sin(a) * r), leaf(LEAVES[rng.randi() % LEAVES.size()]), key + i, 0.25, 4, 8,
			Basis(Vector3.UP, rng.randf() * TAU), t, 0.08)
	for i in flowers:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.3, size * 0.5)
		var fs := rng.randf_range(0.07, 0.11)
		b.blob(Vector3(fs, fs * 0.7, fs), Vector3(cos(a) * r, rng.randf_range(0.4, size * 0.8), sin(a) * r), flower, key + 100 + i, 0.0, 2, 5, Basis.IDENTITY, t)
	return []


## A small shrub drawn without an rng (planters, pots): `key` picks its shape, `size` its height.
static func shrub(b: MeshKit.Builder, t: Transform3D, at: Vector3, size: float, flower: Color, key: int) -> void:
	for i in 4:
		var a := TAU * i / 4.0 + MeshKit.hash01(key, i, 1) * 1.2
		var r := size * 0.22 * MeshKit.hash01(key, i, 2)
		var s := Vector3(size * 0.32, size * (0.26 + 0.12 * MeshKit.hash01(key, i, 3)), size * 0.32)
		var color: Color = LEAVES[int(MeshKit.hash01(key, i, 4) * LEAVES.size()) % LEAVES.size()]
		b.blob(s, at + Vector3(cos(a) * r, s.y * 0.85, sin(a) * r), leaf(color), key + i, 0.25, 4, 7, Basis.IDENTITY, t, 0.1)
	for i in 9:
		var a := TAU * MeshKit.hash01(key, i, 5)
		var r := size * 0.3 * (0.4 + 0.6 * MeshKit.hash01(key, i, 6))
		var fs := size * 0.06
		b.blob(Vector3(fs, fs * 0.7, fs), at + Vector3(cos(a) * r, size * (0.35 + 0.35 * MeshKit.hash01(key, i, 7)), sin(a) * r), flower, key + 50 + i, 0.0, 2, 5, Basis.IDENTITY, t)
