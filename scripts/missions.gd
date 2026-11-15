class_name Missions
## The five Joinville missions, one per city POI (ids are CityData.POIS keys). What the menu shows.
## Objectives aren't built yet: starting a mission hosts the city map with everyone at its POI.

const ORDER := ["terminal", "hospital", "prefeitura", "batalhao", "mirante"]

const INFO := {
	"terminal": { "title": "TERMINAL CENTRAL", "kind": "RUN", "difficulty": 2,
		"brief": "Start in the bus terminal and fight your way north-east through the centre to the Prefeitura. Long street run, one checkpoint halfway.",
		"start": "Bus platforms", "goal": "Prefeitura steps" },
	"hospital": { "title": "HOSPITAL DONA HELENA", "kind": "EXTRACTION", "difficulty": 3,
		"brief": "Enter from the street and climb the ward block floor by floor to the rooftop helipad. Stairwells and an elevator shaft; the staff never left.",
		"start": "Street entrance", "goal": "Rooftop helipad" },
	"prefeitura": { "title": "PREFEITURA DE JOINVILLE", "kind": "DEFEND", "difficulty": 3,
		"brief": "Hold city hall by the river until the helicopter arrives. Barricade the windows; three waves, each bigger than the last.",
		"start": "Main hall", "goal": "Survive three waves" },
	"batalhao": { "title": "62º BATALHÃO DE INFANTARIA", "kind": "DEFEND", "difficulty": 4,
		"brief": "Defend the barracks' parade ground until the helicopter lands. Ammo crates in the armoury, a mounted position on the guard tower, soldiers who turned.",
		"start": "Main gate", "goal": "Hold the parade ground" },
	"mirante": { "title": "MIRANTE DE JOINVILLE", "kind": "EXTRACTION", "difficulty": 5,
		"brief": "Start on the lookout tower at the top of Morro da Boa Vista and get down alive. Narrow stairs, then the switchback road through the forest; leapers in the trees.",
		"start": "Tower deck, 230 m", "goal": "Foot of the hill road" },
}
