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

const BARK := Color("3b3128")
const BARK_GREY := Color("6d6a62")      ## imperial palm trunks are smooth and pale
const LEAVES := [Color("1c3320"), Color("23402a"), Color("182b1c"), Color("2a4a2c"), Color("2f5230")]
const FROND := Color("2d4a24")
const CROWNSHAFT := Color("4f6a32")
const NEEDLES := Color("1a2e1e")
const IPE_YELLOW := Color("e0b41c")
const IPE_PURPLE := Color("9a4a9e")
const HIBISCUS_RED := Color("c4161c")
const BOUGAINVILLEA_PINK := Color("c8237a")


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


## Trunk, two limbs and a clumpy crown of overlapping boxes. `bloom` colours some of the clumps.
static func _broadleaf(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, h: float, bloom: Array) -> Array:
	var bole := h * rng.randf_range(0.45, 0.6)
	var w := rng.randf_range(0.35, 0.6)
	var lean := Basis(Vector3.FORWARD, rng.randf_range(-0.06, 0.06))
	b.box(Vector3(w, bole + 0.6, w), Vector3(0, (bole + 0.6) * 0.5, 0), BARK, lean, t)
	for i in 2:
		var a := rng.randf() * TAU
		var limb := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -0.7)
		b.box(Vector3(w * 0.5, w * 0.5, 2.6), Vector3(0, bole, 0) + Basis(Vector3.UP, a) * Vector3(0, 0.9, -1.0), BARK, limb, t)
	var crown := h - bole
	var spread := rng.randf_range(2.2, 3.4)
	for i in rng.randi_range(5, 7):
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.4, spread * 0.6) if i > 0 else 0.0
		var size := Vector3(rng.randf_range(2.6, 4.2), rng.randf_range(1.6, 2.6), rng.randf_range(2.6, 4.2))
		var y := bole + rng.randf_range(0.3, maxf(0.4, crown - size.y * 0.5 - 0.3))
		if i == 0:
			y = h - size.y * 0.5
		var color: Color = LEAVES[rng.randi() % LEAVES.size()]
		if not bloom.is_empty() and rng.randf() < 0.8:
			color = bloom[rng.randi() % bloom.size()]
		b.box(size, Vector3(cos(a) * r, y, sin(a) * r), color, Basis(Vector3.UP, rng.randf() * TAU), t)
	return _trunk(w, bole)


## A tall palm: ringed trunk, a green crownshaft for the big ones, fronds drooping all round.
static func _palm(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, h: float, radius: float,
		fronds: int, frond_len: float) -> Array:
	var bend := Basis(Vector3.RIGHT, rng.randf_range(-0.04, 0.04)) * Basis(Vector3.FORWARD, rng.randf_range(-0.04, 0.04))
	var top := bend * Vector3(0, h - frond_len * 0.35, 0)
	b.cyl(radius, top.y, top * 0.5, BARK_GREY if radius > 0.2 else BARK, 6, bend, t)
	if radius > 0.2:
		b.cyl(radius * 0.85, 2.2, top + bend * Vector3(0, 0.8, 0), CROWNSHAFT, 6, bend, t)
		top += bend * Vector3(0, 1.8, 0)
	var turn := rng.randf() * TAU
	for i in fronds:
		var a := turn + TAU * i / fronds + rng.randf_range(-0.15, 0.15)
		var droop := rng.randf_range(-0.3, 0.4) if i % 2 == 0 else rng.randf_range(0.4, 0.9)
		var rot := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -droop)
		var dir := rot * Vector3(0, 0, -1)
		b.box(Vector3(frond_len * 0.22, 0.05, frond_len), top + dir * frond_len * 0.5, FROND, rot, t)
	return _trunk(radius * 2.0, top.y)


## Straight trunk, bare to near the top, then upturned limbs holding flat pads: the candelabra.
static func _araucaria(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator) -> Array:
	var h := rng.randf_range(16.0, 22.0)
	b.cyl(0.32, h - 0.8, Vector3(0, (h - 0.8) * 0.5, 0), BARK, 6, Basis.IDENTITY, t)
	var turn := rng.randf() * TAU
	for tier in 3:
		var y := h - 3.6 + tier * 1.2
		var n := 7 - tier
		var reach := rng.randf_range(4.0, 5.2) - tier * 1.2
		for i in n:
			var a := turn + TAU * (i + tier * 0.5) / n
			var out := Vector3(cos(a), 0, sin(a))
			var tip := Vector3(0, y, 0) + out * reach + Vector3(0, reach * 0.35, 0)
			var mid := (Vector3(0, y, 0) + tip) * 0.5
			var limb := Basis.looking_at((tip - Vector3(0, y, 0)).normalized(), Vector3.UP)
			b.box(Vector3(0.14, 0.14, Vector3(0, y, 0).distance_to(tip)), mid, BARK, limb, t)
			b.box(Vector3(2.0, 0.45, 2.0), tip + Vector3(0, 0.15, 0), NEEDLES, Basis(Vector3.UP, a), t)
	b.box(Vector3(2.4, 0.6, 2.4), Vector3(0, h - 0.2, 0), NEEDLES, Basis(Vector3.UP, turn), t)
	return _trunk(0.64, h)


## An ipê in bloom: a broad tree whose crown is mostly flowers, petals fallen round its foot.
static func _ipe(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, color: Color) -> Array:
	var solid := _broadleaf(b, t, rng, rng.randf_range(7.0, 11.0), [color])
	for i in rng.randi_range(10, 18):
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 3.5 + 0.5
		b.box(Vector3(0.35, 0.02, 0.35), Vector3(cos(a) * r, 0.01, sin(a) * r), color, Basis(Vector3.UP, rng.randf() * TAU), t)
	return solid


## Xaxim: a short furry trunk and a ring of long arching fronds.
static func _fern(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator) -> Array:
	var h := rng.randf_range(2.6, 4.6)
	b.cyl(0.2, h, Vector3(0, h * 0.5, 0), BARK, 6, Basis.IDENTITY, t)
	var turn := rng.randf() * TAU
	for i in 11:
		var a := turn + TAU * i / 11.0
		var droop := rng.randf_range(0.1, 0.7)
		var rot := Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, -droop)
		b.box(Vector3(0.55, 0.04, 2.4), Vector3(0, h, 0) + rot * Vector3(0, 0, -1.2), FROND, rot, t)
	return _trunk(0.4, h)


## A rounded clump of leaf boxes dotted with flowers. Nothing solid: it hides, it does not stop.
static func _bush(b: MeshKit.Builder, t: Transform3D, rng: RandomNumberGenerator, flower: Color, flowers: int) -> Array:
	var size := rng.randf_range(1.2, 2.0)
	for i in rng.randi_range(3, 5):
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.0, size * 0.35)
		var s := Vector3(size * rng.randf_range(0.6, 0.9), size * rng.randf_range(0.55, 0.85), size * rng.randf_range(0.6, 0.9))
		b.box(s, Vector3(cos(a) * r, s.y * 0.5, sin(a) * r), LEAVES[rng.randi() % LEAVES.size()], Basis(Vector3.UP, rng.randf() * TAU), t)
	for i in flowers:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.3, size * 0.5)
		b.box(Vector3(0.16, 0.16, 0.16), Vector3(cos(a) * r, rng.randf_range(0.4, size * 0.8), sin(a) * r), flower, Basis.IDENTITY, t)
	return []
