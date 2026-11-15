class_name Weapons
## Every gun and its numbers. Tune guns here (the rest of the tuning lives in config.gd).
## Looks are in scripts/models/guns.gd, first-person animation in scripts/viewmodel.gd.

enum { P19, P90, TYPE95, AK47, ASVAL, USAS12, SPAS12, T5000, DRAGUNOV, COUNT }
enum Carry { HIGH, LOW }            ## while sprinting: muzzle up and ready, or dropped across the body
enum Reload { MAG, SHELLS }         ## swap a magazine, or push shells in one at a time
enum Cycle { BLOWBACK, PUMP, BOLT } ## what the action does after each shot

const DEFAULT := AK47

## How often each gun turns up as loot, in id order (0 = never: everyone starts with the pistol).
const LOOT := [0, 3, 3, 4, 2, 2, 3, 1, 2]

## damage: per bullet/pellet · interval: seconds between shots · reload: seconds (per shell for SHELLS)
## spread / ads_spread / pellet_spread: cone half-angle in radians · recoil: radians of climb per shot
## recoil_side: sideways kick as a share of the climb · ads_fov: camera FOV when aiming
## pitch / volume: how the shared gunshot sound is played
const DEFS := [
	{ "name": "P19", "damage": 22, "interval": 0.14, "auto": false, "mag": 15, "reload": 1.4,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.012, "ads_spread": 0.003, "recoil": 0.012, "recoil_side": 0.5, "ads_fov": 62.0,
		"scoped": false, "carry": Carry.HIGH, "range": 80.0, "flash": true, "pitch": 1.5, "volume": -8.0 },
	{ "name": "P90", "damage": 17, "interval": 0.067, "auto": true, "mag": 50, "reload": 2.2,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.022, "ads_spread": 0.008, "recoil": 0.006, "recoil_side": 0.8, "ads_fov": 60.0,
		"scoped": false, "carry": Carry.HIGH, "range": 90.0, "flash": true, "pitch": 1.7, "volume": -9.0 },
	{ "name": "Type 95", "damage": 28, "interval": 0.092, "auto": true, "mag": 30, "reload": 2.4,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.016, "ads_spread": 0.004, "recoil": 0.009, "recoil_side": 0.5, "ads_fov": 55.0,
		"scoped": false, "carry": Carry.HIGH, "range": 120.0, "flash": true, "pitch": 1.25, "volume": -6.0 },
	{ "name": "AK47", "damage": 34, "interval": 0.1, "auto": true, "mag": 30, "reload": 2.5,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.02, "ads_spread": 0.005, "recoil": 0.013, "recoil_side": 0.7, "ads_fov": 55.0,
		"scoped": false, "carry": Carry.LOW, "range": 120.0, "flash": true, "pitch": 1.0, "volume": -6.0 },
	{ "name": "AS Val", "damage": 26, "interval": 0.067, "auto": true, "mag": 20, "reload": 2.2,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.014, "ads_spread": 0.003, "recoil": 0.007, "recoil_side": 0.4, "ads_fov": 55.0,
		"scoped": false, "carry": Carry.HIGH, "range": 90.0, "flash": false, "pitch": 2.3, "volume": -18.0 },
	{ "name": "USAS-12", "damage": 13, "interval": 0.24, "auto": true, "mag": 10, "reload": 3.0,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 7, "pellet_spread": 0.07,
		"spread": 0.01, "ads_spread": 0.005, "recoil": 0.03, "recoil_side": 0.6, "ads_fov": 62.0,
		"scoped": false, "carry": Carry.LOW, "range": 40.0, "flash": true, "pitch": 0.7, "volume": -4.0 },
	{ "name": "SPAS-12", "damage": 15, "interval": 0.75, "auto": false, "mag": 8, "reload": 0.5,
		"reload_style": Reload.SHELLS, "cycle": Cycle.PUMP, "pellets": 8, "pellet_spread": 0.055,
		"spread": 0.01, "ads_spread": 0.005, "recoil": 0.045, "recoil_side": 0.4, "ads_fov": 62.0,
		"scoped": false, "carry": Carry.LOW, "range": 40.0, "flash": true, "pitch": 0.6, "volume": -3.0 },
	{ "name": "Orsis T-5000", "damage": 240, "interval": 1.3, "auto": false, "mag": 5, "reload": 3.2,
		"reload_style": Reload.MAG, "cycle": Cycle.BOLT, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.03, "ads_spread": 0.0, "recoil": 0.06, "recoil_side": 0.3, "ads_fov": 18.0,
		"scoped": true, "carry": Carry.LOW, "range": 250.0, "flash": true, "pitch": 0.5, "volume": -2.0 },
	{ "name": "Dragunov", "damage": 110, "interval": 0.38, "auto": false, "mag": 10, "reload": 2.8,
		"reload_style": Reload.MAG, "cycle": Cycle.BLOWBACK, "pellets": 1, "pellet_spread": 0.0,
		"spread": 0.025, "ads_spread": 0.0005, "recoil": 0.035, "recoil_side": 0.4, "ads_fov": 22.0,
		"scoped": true, "carry": Carry.LOW, "range": 250.0, "flash": true, "pitch": 0.65, "volume": -3.0 },
]


## A random lootable gun, weighted by LOOT.
static func roll_loot(rng: RandomNumberGenerator) -> int:
	var total := 0
	for w: int in LOOT:
		total += w
	var r := rng.randi_range(0, total - 1)
	for id in COUNT:
		r -= LOOT[id]
		if r < 0:
			return id
	return DEFAULT


static func valid(id: int) -> bool:
	return id >= 0 and id < COUNT


static func def(id: int) -> Dictionary:
	return DEFS[id]


## How far one shot throws the view: Vector2(climb, sideways) in radians. Never the same twice.
static func kick(d: Dictionary, rng: RandomNumberGenerator, aiming: bool) -> Vector2:
	var recoil: float = d.recoil
	var side: float = d.recoil_side
	var m := Config.ADS_RECOIL_MULT if aiming else 1.0
	return Vector2(
		recoil * m * rng.randf_range(1.0 - Config.RECOIL_JITTER, 1.0 + Config.RECOIL_JITTER),
		recoil * m * side * rng.randf_range(-1.0, 1.0))


## Cone half-angle a bullet may stray by. `moving` is 0 (standing) to 1 (sprinting).
static func spread(d: Dictionary, aiming: bool, moving: float) -> float:
	var base: float = d.ads_spread if aiming else d.spread
	return base * (1.0 + clampf(moving, 0.0, 1.0) * Config.MOVE_SPREAD)


## `dir` nudged to a random direction within `angle` radians of itself.
static func scatter(dir: Vector3, angle: float, rng: RandomNumberGenerator) -> Vector3:
	if angle <= 0.0:
		return dir.normalized()
	var f := dir.normalized()
	var u := f.cross(Vector3.UP if absf(f.y) < 0.99 else Vector3.RIGHT).normalized()
	var v := f.cross(u)
	var r := tan(angle * sqrt(rng.randf()))
	var a := rng.randf() * TAU
	return (f + u * cos(a) * r + v * sin(a) * r).normalized()
