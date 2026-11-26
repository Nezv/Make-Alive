class_name ItemIcons
## The item wheel's icons, each drawn from a few flat boxes in a square from -1 to 1 (y down), so they
## cost no textures. `boxes(item)` is a list of [Rect2, Color], drawn in order.

const RED := Color("c8362f")
const WHITE := Color("eeeae0")
const TAN := Color("d8c39a")
const PILL := Color("e9e4d4")
const BOTTLE := Color("d07a2a")
const OLIVE := Color("5e6b3a")
const DARK := Color("2b2d2a")
const GLASS := Color("6f8a52")
const FLAME := Color("f0a030")
const STEEL := Color("a7adb2")
const WOOD := Color("9a6a3c")
const WOOD_DARK := Color("6e4824")
const LURE_RED := Color("e05040")


static func boxes(item: StringName) -> Array:
	match item:
		Inventory.MEDKIT: return [
			[Rect2(-0.8, -0.55, 1.6, 1.25), WHITE],
			[Rect2(-0.3, -0.75, 0.6, 0.22), DARK],           # handle
			[Rect2(-0.12, -0.35, 0.24, 0.85), RED],          # the cross
			[Rect2(-0.42, -0.04, 0.84, 0.24), RED],
		]
		Inventory.BANDAGE: return [
			[Rect2(-0.75, -0.45, 1.1, 0.9), TAN],            # the roll
			[Rect2(-0.75, -0.12, 1.1, 0.06), WOOD_DARK],     # turns of cloth
			[Rect2(-0.75, 0.12, 1.1, 0.06), WOOD_DARK],
			[Rect2(0.35, 0.15, 0.5, 0.3), TAN],              # the loose end
		]
		Inventory.PAINKILLERS: return [
			[Rect2(-0.45, -0.5, 0.9, 1.2), BOTTLE],
			[Rect2(-0.5, -0.8, 1.0, 0.3), WHITE],            # cap
			[Rect2(-0.35, -0.15, 0.7, 0.45), WHITE],         # label
			[Rect2(0.55, 0.45, 0.4, 0.2), PILL],             # a pill
		]
		Inventory.PLANK: return [
			[Rect2(-0.95, -0.25, 1.9, 0.5), WOOD],
			[Rect2(-0.95, -0.05, 1.9, 0.06), WOOD_DARK],     # grain
			[Rect2(-0.6, -0.12, 0.08, 0.08), DARK],          # nails
			[Rect2(0.52, -0.12, 0.08, 0.08), DARK],
		]
		Inventory.FRAG: return [
			[Rect2(-0.5, -0.35, 1.0, 1.1), OLIVE],
			[Rect2(-0.2, -0.6, 0.4, 0.25), STEEL],           # fuse
			[Rect2(0.2, -0.6, 0.15, 0.7), STEEL],            # spoon
			[Rect2(-0.5, 0.1, 1.0, 0.08), DARK],             # segments
		]
		Inventory.MOLOTOV: return [
			[Rect2(-0.4, -0.2, 0.8, 1.0), GLASS],
			[Rect2(-0.15, -0.6, 0.3, 0.4), GLASS],           # neck
			[Rect2(-0.1, -0.8, 0.2, 0.2), WHITE],            # rag
			[Rect2(-0.18, -1.0, 0.36, 0.22), FLAME],
		]
		Inventory.FLASHBANG: return [
			[Rect2(-0.35, -0.5, 0.7, 1.3), STEEL],
			[Rect2(-0.35, -0.2, 0.7, 0.1), DARK],            # vents
			[Rect2(-0.35, 0.2, 0.7, 0.1), DARK],
			[Rect2(-0.15, -0.75, 0.3, 0.25), DARK],          # fuse
		]
		Inventory.LURE: return [
			[Rect2(-0.55, -0.3, 1.1, 1.0), LURE_RED],        # a ticking box
			[Rect2(-0.3, -0.05, 0.6, 0.4), DARK],            # its clock face
			[Rect2(-0.4, -0.65, 0.2, 0.35), STEEL],          # bells
			[Rect2(0.2, -0.65, 0.2, 0.35), STEEL],
		]
	return []
