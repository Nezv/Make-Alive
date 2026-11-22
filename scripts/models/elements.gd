class_name Elements
## Every element made by tools/models/props.py, with what its card (references/elements/<name>.md)
## promises: triangles per LOD (at most), draw calls of one copy at LOD 0, where each LOD stops
## being drawn (metres), the moving parts and the states. tests/test_elements.gd holds every entry
## to it, and to the card's size.

const ALL := {
	"hydrant": {
		"family": "street",
		"tris": [3400, 1300, 480],
		"draws": 4,
		"lod_ends": [14.0, 45.0, 160.0],
		"parts": ["cap_front", "cap_l", "cap_r"],
		"states": ["clean", "abandoned", "damaged", "burnt"],
	},
}
