class_name Difficulty
## The four levels as multipliers on the game as tuned (normal = 1.0 everywhere) plus two rules.
## The host picks one (`Game.difficulty`, `--difficulty=`); clients get it in `welcome`.
##   hp: zombie health · damage: what zombies do to players · runners: share of runners in a mix
##   horde: horde and wave sizes · ammo: rounds in what is found · markers: HUD markers shown ·
##   friendly_fire: players' bullets hurt each other

const LEVELS := ["easy", "normal", "hard", "nightmare"]
const TABLE := {
	"easy": { "hp": 0.75, "damage": 0.6, "runners": 0.6, "horde": 0.7, "ammo": 1.5, "markers": true, "friendly_fire": false },
	"normal": { "hp": 1.0, "damage": 1.0, "runners": 1.0, "horde": 1.0, "ammo": 1.0, "markers": true, "friendly_fire": false },
	"hard": { "hp": 1.3, "damage": 1.4, "runners": 1.5, "horde": 1.3, "ammo": 0.75, "markers": true, "friendly_fire": false },
	"nightmare": { "hp": 1.6, "damage": 1.8, "runners": 2.0, "horde": 1.6, "ammo": 0.5, "markers": false, "friendly_fire": true },
}


static func get_mult(level: String, key: String) -> float:
	return float(TABLE.get(level, TABLE.normal)[key])


static func flag(level: String, key: String) -> bool:
	return bool(TABLE.get(level, TABLE.normal)[key])
