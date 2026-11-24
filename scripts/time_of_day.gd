class_name TimeOfDay
## The sky presets (S050), as data: what the sky looks like, where the sun or the moon stands and
## how it lights the town, the fog and the haze. SkyDome draws them; `Game.sky` names the one a
## match plays (the host's `--time=`, else the mission's, else the map's data), sent in `welcome`.
## Card: references/elements/sky.md.
##
## Azimuths are compass degrees: 0 north (-Z), 90 east (+X). Elevations are degrees above the horizon.

const NAMES := ["clear", "overcast", "dusk", "night", "storm"]
const ALIASES := { "day": "clear", "evening": "dusk", "rain": "storm" }
const KEYS := ["zenith", "horizon", "ground", "sun_elevation", "sun_azimuth", "sun_color", "sun_energy",
	"sun_size", "moon", "stars", "cloud_low", "cloud_high", "cloud_lit", "cloud_shade", "glow", "glow_color",
	"ambient", "ambient_energy", "fog_color", "fog_begin", "fog_curve", "fog_max", "air", "shadows", "shadow_opacity", "wind",
	"lightning", "hill_color", "roof_color", "lights", "exposure", "cloud_relief"]

const PRESETS := {
	# A clear day: blue overhead, a pale milky horizon, the sun high in the south-west.
	"clear": {
		"zenith": Color("4775ab"), "horizon": Color("c3cfdb"), "ground": Color("7d8186"),
		"sun_elevation": 46.0, "sun_azimuth": 215.0, "sun_color": Color("fff1dc"), "sun_energy": 1.15,
		"sun_size": 0.012, "moon": false, "stars": 0.0,
		"cloud_low": 0.3, "cloud_high": 0.25, "cloud_lit": Color("f4f6f8"), "cloud_shade": Color("a3afbe"),
		"glow": 0.0, "glow_color": Color("ffb070"),
		"ambient": Color("aebdd0"), "ambient_energy": 0.42,
		"fog_color": Color("b9c5d1"), "fog_begin": 150.0, "fog_curve": 1.3, "fog_max": 0.4, "air": 0.00022,
		"shadows": true, "shadow_opacity": 0.85, "wind": 1.0, "lightning": 0.0,
		"hill_color": Color("4a5a4c"), "roof_color": Color("4e4f55"), "lights": 0.0, "cloud_relief": 1.0, "exposure": 0.9,
	},
	# The overcast day (Pissarro's Rouen, Montmartre in grey): one even lid of cloud, soft light, no sun disc.
	"overcast": {
		"zenith": Color("7f8994"), "horizon": Color("bfc4c9"), "ground": Color("75787a"),
		"sun_elevation": 40.0, "sun_azimuth": 200.0, "sun_color": Color("eceef0"), "sun_energy": 0.55,
		"sun_size": 0.0, "moon": false, "stars": 0.0,
		"cloud_low": 0.95, "cloud_high": 0.6, "cloud_lit": Color("c9cdd1"), "cloud_shade": Color("8f959c"),
		"glow": 0.0, "glow_color": Color("ffb070"),
		"ambient": Color("aab1b9"), "ambient_energy": 0.8,
		"fog_color": Color("b3b8bd"), "fog_begin": 100.0, "fog_curve": 1.2, "fog_max": 0.5, "air": 0.00035,
		"shadows": true, "shadow_opacity": 0.35, "wind": 0.8, "lightning": 0.0,
		"hill_color": Color("525a52"), "roof_color": Color("4f5257"), "lights": 0.0, "cloud_relief": 0.33, "exposure": 1.0,
	},
	# Dusk: the sun just over the western roofs, long orange light, a violet sky above, clouds lit pink.
	"dusk": {
		"zenith": Color("1c2246"), "horizon": Color("d98a62"), "ground": Color("3b3238"),
		"sun_elevation": 5.0, "sun_azimuth": 285.0, "sun_color": Color("ff9a5a"), "sun_energy": 0.85,
		"sun_size": 0.016, "moon": false, "stars": 0.08,
		"cloud_low": 0.45, "cloud_high": 0.5, "cloud_lit": Color("e8805e"), "cloud_shade": Color("2e2640"),
		"glow": 0.1, "glow_color": Color("ffa060"),
		"ambient": Color("7c6c8c"), "ambient_energy": 0.26,
		"fog_color": Color("5c4652"), "fog_begin": 80.0, "fog_curve": 0.9, "fog_max": 0.5, "air": 0.0003,
		"shadows": true, "shadow_opacity": 0.9, "wind": 1.0, "lightning": 0.0,
		"hill_color": Color("26252f"), "roof_color": Color("2f2b35"), "lights": 0.35, "cloud_relief": 1.0, "exposure": 0.8,
	},
	# A moonlit night: the moon high in the south-east, stars where the cloud breaks, and the town's
	# dull orange light on the cloud's underside (the night photos of Paris).
	"night": {
		"zenith": Color("060912"), "horizon": Color("1a1f2a"), "ground": Color("0b0d10"),
		"sun_elevation": 38.0, "sun_azimuth": 135.0, "sun_color": Color("aabbdd"), "sun_energy": 0.55,
		"sun_size": 0.014, "moon": true, "stars": 1.0,
		"cloud_low": 0.38, "cloud_high": 0.3, "cloud_lit": Color("40444f"), "cloud_shade": Color("101318"),
		"glow": 0.4, "glow_color": Color("9a6e52"),
		"ambient": Color("7f8fa6"), "ambient_energy": 0.2,
		"fog_color": Color("141923"), "fog_begin": 0.0, "fog_curve": 0.45, "fog_max": 0.9, "air": 0.00045,
		"shadows": false, "shadow_opacity": 0.0, "wind": 1.0, "lightning": 0.0,
		"hill_color": Color("0c100f"), "roof_color": Color("15171c"), "lights": 1.0, "cloud_relief": 1.0, "exposure": 0.6,
	},
	# A storm at nightfall: a low lid of heavy cloud racing past, the town glow smothered, lightning.
	"storm": {
		"zenith": Color("0d0f13"), "horizon": Color("262a31"), "ground": Color("101215"),
		"sun_elevation": 50.0, "sun_azimuth": 240.0, "sun_color": Color("8492a3"), "sun_energy": 0.3,
		"sun_size": 0.0, "moon": false, "stars": 0.0,
		"cloud_low": 1.0, "cloud_high": 0.9, "cloud_lit": Color("2e3238"), "cloud_shade": Color("0b0c0f"),
		"glow": 0.08, "glow_color": Color("8a6a55"),
		"ambient": Color("5a6470"), "ambient_energy": 0.3,
		"fog_color": Color("1d2026"), "fog_begin": 0.0, "fog_curve": 0.4, "fog_max": 0.93, "air": 0.0009,
		"shadows": false, "shadow_opacity": 0.0, "wind": 3.0, "lightning": 6.0,
		"hill_color": Color("121516"), "roof_color": Color("1b1e22"), "lights": 0.7, "cloud_relief": 1.5, "exposure": 0.7,
	},
}


## A preset's name from what a player typed ("day" is "clear"); anything unknown is the night.
static func resolve(name: String) -> String:
	name = ALIASES.get(name, name)
	return name if NAMES.has(name) else "night"


static func preset(name: String) -> Dictionary:
	return PRESETS[resolve(name)]


## Unit vector toward the sun (or the moon) of a preset.
static func sun_dir(p: Dictionary) -> Vector3:
	var el := deg_to_rad(float(p.sun_elevation))
	var az := deg_to_rad(float(p.sun_azimuth))
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))


## The rotation of a DirectionalLight3D shining from that sun (a light shines along its -Z).
## How much the fog hides at `dist` metres (Godot's depth fog, and the sky shader's copy of it).
static func fog_at(p: Dictionary, dist: float) -> float:
	var t := clampf((dist - float(p.fog_begin)) / (Config.VIEW_FAR - float(p.fog_begin)), 0.0, 1.0)
	return pow(t * t * (3.0 - 2.0 * t), float(p.fog_curve)) * float(p.fog_max)


static func light_rotation(p: Dictionary) -> Vector3:
	return Vector3(-deg_to_rad(float(p.sun_elevation)), PI - deg_to_rad(float(p.sun_azimuth)), 0.0)
