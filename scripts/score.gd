class_name Score
extends RefCounted
## What each player did this match (host only, no nodes): kills, headshots, limbs severed, damage
## taken, revives, shots fired and shots that hit, distance covered. At the end it names the
## titles and becomes the rows of the end screen (`summary`, sent to every peer once).

const KEYS := ["kills", "headshots", "severs", "damage", "revives", "shots", "hits", "distance"]

var rows := {}      ## player id -> { key: number }
var names := {}     ## player id -> name (kept when a player leaves, so the end screen still has them)
var last_out := 0   ## the player who was last still in the fight when everyone else was out


func join(id: int, player_name: String) -> void:
	names[id] = player_name
	if not rows.has(id):
		var r := {}
		for k: String in KEYS:
			r[k] = 0.0 if k == "distance" else 0
		rows[id] = r


func add(id: int, key: String, amount: Variant = 1) -> void:
	if rows.has(id) and rows[id].has(key):
		rows[id][key] += amount


func get_stat(id: int, key: String) -> Variant:
	return rows[id][key] if rows.has(id) else 0


## Share of shots that hit, 0..1.
func accuracy(id: int) -> float:
	var shots: int = get_stat(id, "shots")
	return float(get_stat(id, "hits")) / shots if shots > 0 else 0.0


## The titles worth handing out: title -> player id. One title needs more than one player to mean
## anything, so with a single player only what they earned outright is named.
func titles() -> Dictionary:
	var out := {}
	var ids := rows.keys()
	if ids.is_empty():
		return out
	var best := _most(ids, "headshots")
	if best != 0:
		out["Sharpshooter"] = best # most headshots
	var medic := _most(ids, "revives")
	if medic != 0:
		out["Medic"] = medic
	if ids.size() > 1:
		var least := ids[0] as int
		for id: int in ids:
			if int(rows[id].damage) < int(rows[least].damage):
				least = id
		out["Untouched"] = least # the survivor who took least damage
	if last_out != 0 and ids.size() > 1:
		out["Last one standing"] = last_out
	return out


## The highest non-zero `key`, or 0 if nobody has any.
func _most(ids: Array, key: String) -> int:
	var best := 0
	var top := 0
	for id: int in ids:
		if int(rows[id][key]) > top:
			top = int(rows[id][key])
			best = id
	return best


## Everything the end screen needs, small enough to send once: rows in join order.
func summary(won: bool, seconds: float, new_best := false) -> Dictionary:
	var list := []
	for id: int in rows:
		var r: Dictionary = rows[id].duplicate()
		r["id"] = id
		r["name"] = names.get(id, "Survivor")
		r["distance"] = roundi(r.distance)
		list.append(r)
	var t := {}
	var named := titles()
	for title: String in named:
		t[title] = names.get(named[title], "Survivor")
	return { "won": won, "seconds": seconds, "rows": list, "titles": t, "best": new_best }
