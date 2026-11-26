class_name Weapons
## Every gun and its numbers. Tune guns here (the rest of the tuning lives in config.gd).
## Looks are in scripts/models/guns.gd, first-person animation in scripts/viewmodel.gd.

enum { P19, P90, TYPE95, AK47, ASVAL, USAS12, SPAS12, T5000, DRAGUNOV, COUNT }
enum Carry { HIGH, LOW }            ## while sprinting: muzzle up and ready, or dropped across the body
enum Reload { MAG, SHELLS }         ## swap a magazine, or push shells in one at a time
enum Cycle { BLOWBACK, PUMP, BOLT } ## what the action does after each shot
enum Ammo { MM9, MM57, MM58, MM762, MM9X39, GAUGE12, LAPUA338, MM762R, COUNT } ## calibres: what a reserve is counted in

## The calibres, in Ammo order. start: rounds in reserve when a mission begins (a map's
## `starting_ammo` can say otherwise) · max: the most a player can carry · box: rounds in one
## carton (AmmoBox) · color: the stripe on that carton.
const AMMO := [
	{ "name": "9 mm", "start": 45, "max": 150, "box": 15, "color": Color("e0c040") },
	{ "name": "5.7", "start": 100, "max": 250, "box": 50, "color": Color("4080e0") },
	{ "name": "5.8", "start": 90, "max": 240, "box": 30, "color": Color("30b0a0") },
	{ "name": "7.62", "start": 90, "max": 240, "box": 30, "color": Color("d04030") },
	{ "name": "9x39", "start": 60, "max": 160, "box": 20, "color": Color("9050c0") },
	{ "name": "12 gauge", "start": 24, "max": 64, "box": 8, "color": Color("f08020") },
	{ "name": ".338", "start": 15, "max": 40, "box": 5, "color": Color("e8e8e8") },
	{ "name": "7.62R", "start": 30, "max": 80, "box": 10, "color": Color("50b040") },
]
enum Kind { PRIMARY, SIDEARM, MELEE } ## which slots of a Loadout a weapon may go in
## What kind each gun is, in id order: the pistol is the sidearm, the rest are primaries.
const GUN_KIND := [Kind.SIDEARM, Kind.PRIMARY, Kind.PRIMARY, Kind.PRIMARY, Kind.PRIMARY, Kind.PRIMARY, Kind.PRIMARY, Kind.PRIMARY, Kind.PRIMARY]
## Seconds to holster the gun in hand and bring this one up, in id order: heavy guns are slower.
const GUN_DRAW := [0.25, 0.3, 0.35, 0.35, 0.33, 0.48, 0.45, 0.55, 0.5]
## How fast you sprint with each gun in hand, as a share of Config.SPRINT_SPEED, in id order.
const GUN_SPRINT := [1.0, 1.0, 0.97, 0.95, 0.97, 0.88, 0.9, 0.85, 0.88]
## How far a shot is heard, in metres, in id order (the AS Val is suppressed as built), and the
## same with a suppressor fitted.
const GUN_LOUDNESS := [35.0, 40.0, 55.0, 60.0, 14.0, 70.0, 70.0, 90.0, 80.0]
const GUN_LOUDNESS_SUPPRESSED := [12.0, 13.0, 18.0, 20.0, 14.0, 28.0, 28.0, 35.0, 30.0]
## The shape of each gun's muzzle flash, in id order (MuzzleFlash draws them): small and round for
## the pistol and the P90, long and forked for rifles, a wide ball for shotguns, side jets out of
## the T-5000's brake, nothing from the suppressed AS Val. NONE must agree with `flash: false`.
enum Flash { NONE, ROUND, FORK, BALL, JETS }
const GUN_FLASH := [Flash.ROUND, Flash.ROUND, Flash.FORK, Flash.FORK, Flash.NONE, Flash.BALL, Flash.BALL, Flash.JETS, Flash.FORK]
## Which calibre each gun is fed with, in id order (the two shotguns share shells).
const GUN_AMMO := [Ammo.MM9, Ammo.MM57, Ammo.MM58, Ammo.MM762, Ammo.MM9X39, Ammo.GAUGE12, Ammo.GAUGE12, Ammo.LAPUA338, Ammo.MM762R]

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


static func kind_of(id: int) -> int:
	return GUN_KIND[id]


static func draw_time(id: int) -> float:
	return GUN_DRAW[id]


static func sprint_mult(id: int) -> float:
	return GUN_SPRINT[id]


## The muzzle flash of gun `id` (a Flash).
static func flash_shape(id: int) -> int:
	return GUN_FLASH[id] if id >= 0 and id < GUN_FLASH.size() else Flash.NONE


## Metres away one shot of gun `id` is heard (Game.make_noise).
static func loudness(id: int, suppressed := false) -> float:
	return GUN_LOUDNESS_SUPPRESSED[id] if suppressed else GUN_LOUDNESS[id]


## The calibre (Ammo) gun `id` is fed with.
static func ammo_of(id: int) -> int:
	return GUN_AMMO[id]


static func ammo_name(type: int) -> String:
	return AMMO[type].name if type >= 0 and type < Ammo.COUNT else ""


## The calibre called `ammo_name_` ("9 mm", "12 gauge"...), or -1.
static func ammo_id(ammo_name_: String) -> int:
	for type in Ammo.COUNT:
		if AMMO[type].name == ammo_name_:
			return type
	return -1


## How far one shot throws the view: Vector2(climb, sideways) in radians. Never the same twice.
static func kick(d: Dictionary, rng: RandomNumberGenerator, aiming: bool) -> Vector2:
	var recoil: float = d.recoil
	var side: float = d.recoil_side
	var m := Config.ADS_RECOIL_MULT if aiming else 1.0
	return Vector2(
		recoil * m * rng.randf_range(1.0 - Config.RECOIL_JITTER, 1.0 + Config.RECOIL_JITTER),
		recoil * m * side * rng.randf_range(-1.0, 1.0))


## Cone half-angle a bullet may stray by. `moving` is 0 (standing) to 1 (sprinting),
## `crouch` 0 (standing) to 1 (down): crouching steadies the gun.
static func spread(d: Dictionary, aiming: bool, moving: float, crouch := 0.0) -> float:
	var base: float = d.ads_spread if aiming else d.spread
	return base * (1.0 + clampf(moving, 0.0, 1.0) * Config.MOVE_SPREAD) * lerpf(1.0, Config.CROUCH_SPREAD_MULT, clampf(crouch, 0.0, 1.0))


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
