class_name Surface
## What things are made of. A collision shape (or, failing that, its body) carries it as the "surface"
## metadata (`tag`); `of_hit` reads it from a ray hit, so bullets know what they struck. Untagged is
## concrete; a zombie's hitbox is flesh. The impacts are in Fx (`Fx.Kind.IMPACT`, the surface as `arg`).

enum Kind { CONCRETE, ASPHALT, BRICK, METAL, WOOD, GLASS, DIRT, GRASS, WATER, FLESH, TILE }
const NAMES := ["concrete", "asphalt", "brick", "metal", "wood", "glass", "dirt", "grass", "water", "flesh", "tile"]

## How easily a bullet goes through (0 = never, 1 = as if it were not there), for S101's penetration:
## a rifle round loses this share of its power less for every 10 cm of the stuff.
const PENETRATION := {
	Kind.CONCRETE: 0.1, Kind.ASPHALT: 0.05, Kind.BRICK: 0.15, Kind.METAL: 0.25, Kind.WOOD: 0.6,
	Kind.GLASS: 0.9, Kind.DIRT: 0.2, Kind.GRASS: 0.95, Kind.WATER: 0.3, Kind.FLESH: 0.5, Kind.TILE: 0.3,
}


## Say what `node` (a CollisionShape3D or a whole body) is made of.
static func tag(node: Node, kind: int) -> void:
	node.set_meta("surface", kind)


## What a ray hit (`intersect_ray`'s result) struck.
static func of_hit(hit: Dictionary) -> int:
	if hit.is_empty():
		return Kind.CONCRETE
	var collider: Object = hit.get("collider")
	if collider == null:
		return Kind.CONCRETE
	if collider is Area3D and (collider as Area3D).has_meta("zombie"):
		return Kind.FLESH
	if collider is CollisionObject3D and hit.has("shape"):
		var body := collider as CollisionObject3D
		var owner_id := body.shape_find_owner(int(hit.shape))
		if owner_id >= 0:
			var shape_node := body.shape_owner_get_owner(owner_id) as Node
			if shape_node != null and shape_node.has_meta("surface"):
				return int(shape_node.get_meta("surface"))
	if collider is Node and (collider as Node).has_meta("surface"):
		return int((collider as Node).get_meta("surface"))
	return Kind.CONCRETE
