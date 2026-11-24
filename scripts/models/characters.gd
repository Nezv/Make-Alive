class_name Characters
## Character presets built on Humanoid. Everything is picked from the id, never at random, so
## every peer draws the same zombie without sending its look over the network.
##
## Zombies come in outfits (who they were): civilians, workers, nurses, doctors, cops, soldiers,
## firefighters, office staff, prisoners. Leapers keep their own feral body.
## A walking zombie is a model: the male or female body dressed in its outfit's clothes
## (tools/models/outfits.py -> assets/models/zombie_<outfit>_<m|f>), which of the two picked from
## its id (FEMALE_SHARE). The style below still dresses corpses, the feral leaper and survivors.
## Adding an outfit: add it to Outfit, OUTFIT_NAMES, WEIGHTS and FEMALE_SHARE, give it a recipe
## in tools/models/outfits.py and build it, write `_name(s, id)` below and add it to the match in
## `zombie_style`. Check it with `tools\godot.ps1 -- --host --zombie-rack` and `--outfit-rack`.
##
## The look follows references/zombies.png: grey skin, dark sunken eyes, a bloody open mouth,
## clothes and blood painted onto the round body (Humanoid's paint rules: a box region or a ragged
## splat, in the part's own space), with hats, pouches and badges as extra shapes merged into the
## part they sit on, so a hat leaves with the head and a cuff with the arm.

enum Outfit { CIVILIAN, WORKER, NURSE, DOCTOR, COP, SOLDIER, FIREFIGHTER, OFFICE, PRISONER, FERAL }
const OUTFIT_NAMES := ["civilian", "worker", "nurse", "doctor", "cop", "soldier", "firefighter",
	"office", "prisoner", "feral"]
## Share of a crowd, out of 100, in Outfit order (FERAL is never rolled: it's the leaper).
const WEIGHTS := [34, 12, 9, 6, 11, 9, 6, 9, 4]
## Women per hundred of each outfit (FERAL has no model).
const FEMALE_SHARE := [45, 20, 70, 45, 35, 20, 20, 45, 20]

const ZOMBIE_SKINS := [Color("8e9a86"), Color("9aa391"), Color("7f8b80"), Color("a2a68f"), Color("88917f"),
	Color("959c97")]
const ZOMBIE_EYES := Color("e6ebc4")
const CIVILIAN_SHIRTS := [Color("4a3b2e"), Color("3d5a80"), Color("8a2a2a"), Color("6a7a3a"), Color("2f4a3a"),
	Color("70604a"), Color("7a5a80"), Color("b8a878"), Color("2e6d7b"), Color("b08a2a")]
const CIVILIAN_PANTS := [Color("2b2b3a"), Color("3a3226"), Color("2a3a2a"), Color("34435e"), Color("4f4a44")]
const PRINTS := [Color("d9d9d2"), Color("c8a030"), Color("a03030"), Color("3a3a3a")]
const HAIR := [Color("2a1a10"), Color("141414"), Color("9a7a3a"), Color("777777"), Color("6a2a14")]
const PLAYER_SHIRTS := [Color("3366cc"), Color("cc6633"), Color("33aa77"), Color("aa33aa"), Color("cccc33"), Color("33aacc")]
const BLOOD := Color("8c1010")
const BLOOD_DARK := Color("4e0606")
const WHITE := Color("d9d9d2")
const BLACK := Color("15151a")
const STRIPE := Color("c8e03a")  # reflective tape
const GOLD := Color("c9a227")

## The ten bites (tools/models/bites.py BITES: the numbers are the same): a point on the way in and
## the direction a ray travels to meet the bite's centre. A model with bite N is
## zombie_<outfit>_<m|f>_b<N>; it wears the outfit's textures.
const BITES := [
	{"name": "abdomen_l", "at": Vector3(-0.085, 1.07, 0), "to": Vector3(0, 0, 1)},
	{"name": "abdomen_r", "at": Vector3(0.09, 1.04, 0), "to": Vector3(-0.2, 0, 0.98)},
	{"name": "ribs_r", "at": Vector3(0.14, 1.25, 0), "to": Vector3(-0.45, 0, 0.89)},
	{"name": "chest", "at": Vector3(-0.05, 1.38, 0), "to": Vector3(0, 0.1, 1)},
	{"name": "shoulder_l", "at": Vector3(-0.31, 1.46, 0), "to": Vector3(0.45, -0.55, 0.35)},
	{"name": "upper_arm_r", "at": Vector3(0.3, 1.34, 0), "to": Vector3(-0.3, 0, 0.95)},
	{"name": "forearm_l", "at": Vector3(-0.3, 1.02, 0), "to": Vector3(0.35, 0, 0.94)},
	{"name": "thigh_r", "at": Vector3(0.12, 0.72, 0), "to": Vector3(-0.35, 0, 0.94)},
	{"name": "calf_l", "at": Vector3(-0.12, 0.34, 0), "to": Vector3(0, 0, -1)},
	{"name": "neck", "at": Vector3(0, 1.57, 0), "to": Vector3(0.8, -0.1, 0.6)},
]


static func _pick(arr: Array, n: int) -> Color:
	return arr[absi(n) % arr.size()]


static func V(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)


## 0..1 from an id and a counter, the same on every peer.
static func _r(id: int, k: int) -> float:
	return float(absi((id * 7919 + k * 104729) ^ (k * 31337 + id * 613)) % 1000) / 1000.0


## Which outfit zombie `id` wears. Spread so neighbouring ids differ.
static func outfit_for(id: int, type: int) -> int:
	if type == 2: # LEAPER
		return Outfit.FERAL
	var roll := (absi(id) * 61 + 17) % 100
	for o in WEIGHTS.size():
		roll -= WEIGHTS[o]
		if roll < 0:
			return o
	return Outfit.CIVILIAN


## Whether zombie `id` wearing `outfit` is a woman (the female body), the same on every peer.
static func is_female(id: int, outfit: int) -> bool:
	return outfit < FEMALE_SHARE.size() and int(_r(id, 91) * 100.0) < FEMALE_SHARE[outfit]


## Whether an outfit is worn as a model (all but the feral leaper's).
static func has_model(outfit: int) -> bool:
	return outfit >= 0 and outfit < FEMALE_SHARE.size()


## Which bite (an index into BITES) zombie `id` wearing `outfit` carries, -1 for none: about
## `Config.BITE_SHARE` of a crowd, picked from the id so every peer sees the same wound.
static func bite_for(id: int, outfit: int) -> int:
	if not has_model(outfit) or _r(id, 57) >= Config.BITE_SHARE:
		return -1
	return int(_r(id, 58) * BITES.size()) % BITES.size()


## Every model a crowd may wear, each outfit on both bodies, plain and with each bite (Game loads
## them before the first spawn).
static func model_paths() -> Array[String]:
	var out: Array[String] = []
	for o in FEMALE_SHARE.size():
		for female in [false, true]:
			for bite in range(-1, BITES.size()):
				out.append(CharacterModel.outfit_path(OUTFIT_NAMES[o], female, bite))
	return out


## `type` is a Zombie.Type: walkers shamble and limp, runners are bloodier and don't limp,
## leapers are pale, small and long-armed with yellow eyes. `outfit` -1 = pick from the id.
static func zombie(id: int, type: int, outfit := -1) -> Humanoid:
	if outfit < 0:
		outfit = outfit_for(id, type)
	if has_model(outfit):
		var model := CharacterModel.outfit(OUTFIT_NAMES[outfit], is_female(id, outfit), bite_for(id, outfit))
		return Humanoid.create_model(model, zombie_style(id, type, outfit))
	return Humanoid.create(zombie_style(id, type, outfit))


## The full description of a zombie's look, as Humanoid style keys.
static func zombie_style(id: int, type: int, outfit := -1) -> Dictionary:
	if outfit < 0:
		outfit = outfit_for(id, type)
	var s := {
		"zombie": true,
		"skin": _pick(ZOMBIE_SKINS, id),
		"shirt": _pick(CIVILIAN_SHIRTS, id * 7),
		"pants": _pick(CIVILIAN_PANTS, id * 13),
		"shoes": Color("2a2622"),
		"eyes": ZOMBIE_EYES,
		"limp": float((id * 31) % 10) / 10.0,
		"scale": 0.95 + float((id * 37) % 10) / 50.0,
		"torso_extras": [], "head_extras": [], "upper_arm_extras": [], "forearm_extras": [],
		"thigh_extras": [], "shin_extras": [],
	}
	match outfit:
		Outfit.CIVILIAN: _civilian(s, id)
		Outfit.WORKER: _worker(s, id)
		Outfit.NURSE: _nurse(s, id)
		Outfit.DOCTOR: _doctor(s, id)
		Outfit.COP: _cop(s, id)
		Outfit.SOLDIER: _soldier(s, id)
		Outfit.FIREFIGHTER: _firefighter(s, id)
		Outfit.OFFICE: _office(s, id)
		Outfit.PRISONER: _prisoner(s, id)
		Outfit.FERAL: _feral(s, id)
	if outfit != Outfit.FERAL:
		var runner := type == 1
		if runner: # RUNNER: fresh, fast and soaked
			var shirt: Color = s.shirt
			s.shirt = shirt.lerp(Color("7a1c1c"), 0.35)
			s.hands = BLOOD
			s.limp = 0.0
		_gore(s, id, runner)
	return s


static func survivor(peer_id: int) -> Humanoid:
	var s := {
		"shirt": _pick(PLAYER_SHIRTS, peer_id),
		"pants": Color("3a3f4a"),
		"shoes": Color("3a2a1e"),
		"belt": Color("2a2018"),
		"head_extras": [],
		"torso_extras": [
			[V(0.34, 0.4, 0.16), Humanoid.back(0, 0.36, 0.075), Color("4a4030")],  # backpack
			[V(0.3, 0.12, 0.13), Humanoid.back(0, 0.2, 0.15), Color("3e3628")],    # its pocket
		],
	}
	for x in [-0.1, 0.1]:
		s.torso_extras.append([V(0.045, 0.26, 0.014), Humanoid.chest(x, 0.46, 0.004), Color("3a3226")]) # straps
	_hair(s, peer_id * 5 + 1, false)
	return Humanoid.create(s)


# --- Painting ---------------------------------------------------------------------

static func _add(s: Dictionary, key: String, rule: Array) -> void:
	if not s.has(key):
		s[key] = []
	(s[key] as Array).append(rule)


## A box region [from, to, colour] for a paint rule.
static func _region(a: Vector3, b: Vector3, c: Color) -> Array:
	return [a, b, c]


## Everything between two heights.
static func _band(y0: float, y1: float, c: Color) -> Array:
	return [V(-1, y0, -1), V(1, y1, 1), c]


## A ragged painted patch round `at` (faces only, so it comes out blocky: camo, not blood).
static func _splat(at: Vector3, radius: float, c: Color, drip := 0.0) -> Array:
	return [at, radius, c, drip]


## A stain lying on a part's surface (blood): `key` is "torso", "head", "thigh_l", ...; `at`
## only has to point the right way from the part's axis (front is -z).
static func _stain(s: Dictionary, key: String, at: Vector3, radius: float, c: Color, drip := 0.0, layer := 0) -> void:
	_add(s, key + "_stains", [at, radius, c, drip, layer])


# --- Shared bits ------------------------------------------------------------------

## Blood and wounds, different on every zombie: it has eaten (mouth, chin, down the front),
## its hands are red, a wound or two, stains on the limbs. `soaked` (runners) adds more.
static func _gore(s: Dictionary, id: int, soaked: bool) -> void:
	var skin: Color = s.skin
	_stain(s, "head", V(0, 0.055, -1), 0.045 + _r(id, 1) * 0.02, BLOOD, 0.035)
	var x := -0.1 + _r(id, 2) * 0.2
	if id % 4 != 3 or soaked:
		_stain(s, "torso", V(x * 0.4, 0.57, -1), 0.06, BLOOD, 0.16 + _r(id, 3) * 0.16)
	var wound := V(x, 0.18 + _r(id, 4) * 0.3, -1)
	_stain(s, "torso", wound, 0.07, BLOOD, 0.08)
	_stain(s, "torso", wound, 0.03, BLOOD_DARK, 0.0, 1)
	if id % 2 == 0: # exit wound
		_stain(s, "torso", V(-x, 0.25 + _r(id, 5) * 0.25, 1), 0.065, BLOOD_DARK, 0.12)
	if id % 3 == 0: # torn open, grey skin under
		_stain(s, "torso", V(-x * 2.0, 0.32, -1), 0.05, skin.darkened(0.2))
	_add(s, "hand_paint", _splat(V(0, -0.37, 0), 0.05 + _r(id, 6) * 0.03, BLOOD))
	var side := "l" if id % 2 == 0 else "r"
	var other := "r" if side == "l" else "l"
	_stain(s, "forearm_" + side, V(_r(id, 7) - 0.5, -0.17, -1), 0.045, BLOOD, 0.05)
	if id % 3 == 2:
		_stain(s, "upper_arm_" + other, V(0.5 - _r(id, 8), -0.12, -1), 0.05, BLOOD, 0.08)
	if id % 5 == 0:
		_stain(s, "thigh_" + side, V(0, -0.22, -1), 0.06, BLOOD_DARK, 0.12)
	if id % 4 == 1:
		_stain(s, "shin_" + other, V(0, -0.2, -1), 0.05, BLOOD_DARK, 0.1)
	if soaked:
		_stain(s, "torso", V(-x * 0.5, 0.42, -1), 0.1, BLOOD, 0.2)
		_stain(s, "torso", V(x, 0.12, -1), 0.07, BLOOD_DARK, 0.04)
		_stain(s, "torso", V(x, 0.48, 1), 0.08, BLOOD, 0.15)
		_stain(s, "head", V(0.4, 0.11, -1), 0.05, BLOOD, 0.04)
		_stain(s, "forearm", V(0, -0.21, -1), 0.05, BLOOD, 0.02)
		_stain(s, "thigh_" + other, V(0.3, -0.15, -1), 0.07, BLOOD, 0.15)


static func _hair(s: Dictionary, id: int, allow_long := true) -> void:
	var c := _pick(HAIR, id * 3)
	s.brows = c
	var style := (id * 17) % 5
	if style == 3: # bald
		return
	_add(s, "head_paint", _region(V(-1, 0.12, 0.03), V(1, 1, 1), c))   # the back of the head
	_add(s, "head_paint", _region(V(-1, 0.2, -0.07), V(1, 1, 1), c))   # sides over the ears
	s.head_extras.append([Vector3.ONE, Vector3.ZERO, c, "hair_cap"])
	match style:
		0: # short, a fringe
			s.head_extras.append([V(0.2, 0.04, 0.03), Humanoid.face(0.015, 0.262, 0.004), c, "box", Basis(Vector3.FORWARD, 0.12)])
		1: # long (short again under a helmet)
			if allow_long:
				s.head_extras.append([V(0.27, 0.26, 0.06), V(0, 0.13, 0.14), c, "box", Basis(Vector3.RIGHT, -0.1)])
				for x in [-0.13, 0.13]:
					s.head_extras.append([V(0.05, 0.2, 0.12), V(x, 0.15, 0.04), c])
		2: # bun
			s.head_extras.append([V(0.12, 0.11, 0.11), V(0, 0.31, 0.15), c, "ball"])
		4: # messy tufts
			for i in 3:
				s.head_extras.append([V(0.07, 0.05, 0.12), V(-0.06 + i * 0.06, 0.35, -0.02 + i * 0.03), c, "box",
					Basis(Vector3.FORWARD, -0.4 + i * 0.4) * Basis(Vector3.RIGHT, 0.3)])


static func _glasses(s: Dictionary) -> void:
	for x in [-0.054, 0.054]:
		s.head_extras.append([V(0.074, 0.012, 0.012), Humanoid.face(x, 0.204, 0.02), BLACK])
		s.head_extras.append([V(0.074, 0.01, 0.012), Humanoid.face(x, 0.15, 0.02), BLACK])
		s.head_extras.append([V(0.012, 0.012, 0.15), V(x * 2.5, 0.2, -0.07), BLACK])
	s.head_extras.append([V(0.03, 0.012, 0.012), Humanoid.face(0, 0.19, 0.03), BLACK])


## An open coat's skirts below the waist: a back panel and two sides, nothing in front.
static func _coat_tails(s: Dictionary, c: Color, length: float) -> void:
	s.torso_extras.append([V(0.36, length, 0.02), V(0, 0.09 - length * 0.5, 0.125), c, "box", Basis(Vector3.RIGHT, -0.08)])
	for x in [-0.185, 0.185]:
		s.torso_extras.append([V(0.02, length, 0.2), V(x, 0.09 - length * 0.5, 0.025), c, "box",
			Basis(Vector3.FORWARD, -0.08 * signf(x))])


## Boots up the shin, in `c`.
static func _boots(s: Dictionary, c: Color) -> void:
	s.shoes = c
	_add(s, "shin_paint", _band(-1, -0.27, c))


# --- Outfits ----------------------------------------------------------------------

static func _civilian(s: Dictionary, id: int) -> void:
	_hair(s, id)
	var shirt: Color = s.shirt
	var kind := (id * 19) % 5
	match kind:
		0: # t-shirt, sometimes with a print
			if id % 3 == 0:
				_add(s, "torso_paint", _region(V(-0.09, 0.33, -1), V(0.09, 0.5, -0.05), _pick(PRINTS, id)))
		1: # hoodie
			s.sleeves = "long"
			s.torso_extras.append([V(0.3, 0.13, 0.14), Humanoid.back(0, 0.6, 0.0), shirt.darkened(0.12), "ball"]) # hood
			_add(s, "torso_paint", _region(V(-0.13, 0.12, -1), V(0.13, 0.27, -0.05), shirt.darkened(0.18))) # pouch
			_add(s, "forearm_paint", _band(-1, -0.2, shirt.darkened(0.15)))
			for x in [-0.035, 0.035]:
				s.torso_extras.append([V(0.012, 0.12, 0.012), Humanoid.chest(x, 0.55, 0.008), WHITE])
		2: # open jacket over a light shirt
			s.sleeves = "long"
			s.shirt = shirt.darkened(0.25)
			_add(s, "torso_paint", _region(V(-0.075, 0.08, -1), V(0.075, 0.62, -0.05), shirt.lightened(0.4)))
			for x in [-0.07, 0.07]:
				s.torso_extras.append([V(0.06, 0.16, 0.014), Humanoid.chest(x, 0.53, 0.004), shirt.darkened(0.35),
					"box", Basis(Vector3.FORWARD, 0.35 * signf(x))]) # lapels
		3: # apron (shop or kitchen)
			var apron := Color("c9c3ae")
			_add(s, "torso_paint", _region(V(-0.17, -1, -1), V(0.17, 0.5, -0.05), apron))
			_add(s, "thigh_paint", _region(V(-1, -0.3, -1), V(1, 1, -0.03), apron))
			s.torso_extras.append([V(0.03, 0.1, 0.012), Humanoid.chest(-0.1, 0.56, 0.004), apron])
			s.torso_extras.append([V(0.03, 0.1, 0.012), Humanoid.chest(0.1, 0.56, 0.004), apron])
		4: # a dress, bare legs
			var dress := shirt.lightened(0.1)
			s.shirt = dress
			s.pants = s.skin
			s.shoes = Color("3a1a1a")
			s.torso_extras.append([V(0.42, 0.32, 0.3), V(0, -0.05, 0.0), dress, "tube"]) # skirt
	if kind != 4 and id % 7 == 0: # shorts
		_add(s, "thigh_paint", _band(-1, -0.24, s.skin))
		_add(s, "shin_paint", _band(-1, 1, s.skin))
	if id % 6 == 0: # baseball cap
		var cap := _pick(CIVILIAN_SHIRTS, id * 5)
		s.head_extras.append([V(0.3, 0.13, 0.32), V(0, 0.255, 0.008), cap, "dome"])
		s.head_extras.append([V(0.2, 0.016, 0.12), V(0, 0.27, -0.2), cap.darkened(0.2), "box", Basis(Vector3.RIGHT, -0.12)])


static func _worker(s: Dictionary, id: int) -> void:
	var vest := Color("e0701a") if id % 2 == 0 else Color("c6dc22")
	var hat: Color = [Color("e8c21a"), Color("d8d8d0"), Color("e0701a")][id % 3]
	s.shirt = [Color("5b6b7a"), Color("6a6a60"), Color("3e4a5a")][id % 3]
	s.pants = Color("34435e")
	s.hands = Color("b08a2a") # work gloves
	s.belt = Color("4a3520")
	if id % 2 == 1:
		s.sleeves = "long"
	_boots(s, Color("6a4a28"))
	_add(s, "torso_paint", _region(V(-1, 0.11, -1), V(1, 0.64, 1), vest))        # hi-vis vest
	_add(s, "torso_paint", _band(0.2, 0.25, WHITE))                             # reflective bands
	_add(s, "torso_paint", _band(0.4, 0.45, WHITE))
	s.torso_extras.append([V(0.1, 0.13, 0.08), V(0.2, 0.03, -0.06), Color("3a2a18")]) # pouch
	s.torso_extras.append([V(0.04, 0.16, 0.03), V(-0.19, 0.0, -0.08), Color("8a8a8a")]) # a hammer's handle
	_hair(s, id, false)
	s.head_extras.append([V(0.33, 0.15, 0.35), V(0, 0.255, 0.005), hat, "dome"])     # hard hat
	s.head_extras.append([V(0.37, 0.018, 0.41), V(0, 0.262, -0.005), hat, "tube"])    # brim
	s.head_extras.append([V(0.045, 0.03, 0.3), V(0, 0.395, 0.005), hat.darkened(0.12)]) # ridge


static func _nurse(s: Dictionary, id: int) -> void:
	var scrubs: Color = [Color("4fa3a0"), Color("6f8fc8"), Color("c88aa0")][id % 3]
	s.shirt = scrubs
	s.pants = scrubs.darkened(0.1)
	s.shoes = WHITE
	s.sole = Color("a8a8a0")
	_add(s, "torso_paint", _region(V(-0.075, 0.5, -1), V(0.075, 1, -0.02), s.skin))  # v-neck
	_add(s, "torso_paint", _region(V(-0.03, 0.44, -1), V(0.03, 0.52, -0.05), s.skin))
	s.torso_extras.append([V(0.1, 0.09, 0.012), Humanoid.chest(0.11, 0.38, 0.004), scrubs.darkened(0.2)]) # pocket
	s.torso_extras.append([V(0.05, 0.07, 0.012), Humanoid.chest(-0.12, 0.45, 0.004), WHITE])              # badge
	_hair(s, id, false)
	if id % 2 == 0:
		s.head_extras.append([V(0.24, 0.08, 0.1), V(0, 0.335, -0.07), WHITE])               # cap
		s.head_extras.append([V(0.07, 0.022, 0.02), V(0, 0.34, -0.12), Color("b01818")])     # red cross
		s.head_extras.append([V(0.022, 0.07, 0.02), V(0, 0.34, -0.121), Color("b01818")])
	else:
		s.head_extras.append([V(0.3, 0.12, 0.32), V(0, 0.255, 0.01), scrubs.lightened(0.1), "dome"]) # surgical cap
		s.head_extras.append([V(0.19, 0.1, 0.03), Humanoid.face(0, 0.085, 0.02), Color("9fc4d8")])    # mask
		for x in [-0.11, 0.11]:
			s.head_extras.append([V(0.012, 0.012, 0.12), V(x, 0.11, -0.06), Color("9fc4d8"), "box",
				Basis(Vector3.UP, 0.5 * signf(x))])


static func _doctor(s: Dictionary, id: int) -> void:
	s.shirt = WHITE
	s.pants = Color("3a3a40")
	s.shoes = BLACK
	s.sleeves = "long"
	_add(s, "torso_paint", _region(V(-0.075, 0.1, -1), V(0.075, 1, -0.04), Color("4f8f7a")))  # scrubs under
	_coat_tails(s, WHITE, 0.3)
	for x in [-0.075, 0.075]:
		s.torso_extras.append([V(0.016, 0.22, 0.016), Humanoid.chest(x, 0.48, 0.01), BLACK]) # stethoscope
	s.torso_extras.append([V(0.05, 0.016, 0.05), Humanoid.chest(0.075, 0.36, 0.01), Color("9a9aa2"), "tube",
		Basis(Vector3.RIGHT, PI / 2.0)])
	s.torso_extras.append([V(0.012, 0.09, 0.012), Humanoid.chest(-0.13, 0.42, 0.006), Color("2a3a6a")]) # pens
	s.torso_extras.append([V(0.012, 0.09, 0.012), Humanoid.chest(-0.11, 0.42, 0.006), Color("8a1c1c")])
	_hair(s, id, false)
	if id % 2 == 0:
		s.head_extras.append([V(0.3, 0.12, 0.32), V(0, 0.255, 0.01), Color("4f8f7a"), "dome"]) # surgical cap
	else:
		_glasses(s)


static func _cop(s: Dictionary, id: int) -> void:
	var navy := Color("1f2a44")
	var shirt := Color("5a7aa8") if id % 3 == 0 else Color("2a3a5e")
	s.shirt = shirt
	s.pants = Color("161d30")
	s.belt = BLACK
	_boots(s, BLACK)
	if id % 2 == 0:
		s.sleeves = "long"
		_add(s, "torso_paint", _region(V(-0.06, 0.58, -1), V(0.06, 1, -0.02), shirt.lightened(0.15)))
		s.torso_extras.append([V(0.045, 0.035, 0.016), Humanoid.chest(0, 0.6, 0.006), BLACK])  # tie
		s.torso_extras.append([V(0.04, 0.26, 0.012), Humanoid.chest(0, 0.45, 0.006), BLACK])
	for x in [-0.115, 0.115]: # pocket flaps
		_add(s, "torso_paint", _region(V(x - 0.055, 0.4, -1), V(x + 0.055, 0.47, -0.05), shirt.darkened(0.2)))
	s.torso_extras.append([V(0.05, 0.06, 0.014), Humanoid.chest(-0.115, 0.5, 0.006), GOLD])  # badge
	s.torso_extras.append([V(0.07, 0.02, 0.012), Humanoid.chest(0.115, 0.5, 0.006), WHITE]) # name tag
	s.torso_extras.append([V(0.08, 0.17, 0.11), V(0.22, -0.02, -0.01), BLACK])             # holster
	s.torso_extras.append([V(0.06, 0.09, 0.04), Humanoid.chest(-0.17, 0.55, 0.02), BLACK]) # radio
	_add(s, "upper_arm_l_paint", _region(V(-1, -0.12, -0.06), V(-0.04, -0.02, 0.06), GOLD.darkened(0.3)))
	_add(s, "upper_arm_r_paint", _region(V(0.04, -0.12, -0.06), V(1, -0.02, 0.06), GOLD.darkened(0.3)))
	_hair(s, id, false)
	s.head_extras.append([V(0.295, 0.025, 0.315), V(0, 0.27, 0.008), BLACK, "tube"])  # cap band
	s.head_extras.append([V(0.29, 0.07, 0.31), V(0, 0.3, 0.008), navy, "tube"])       # crown
	s.head_extras.append([V(0.34, 0.035, 0.37), V(0, 0.345, -0.005), navy, "tube"])   # top
	s.head_extras.append([V(0.22, 0.014, 0.11), V(0, 0.262, -0.185), BLACK, "box", Basis(Vector3.RIGHT, -0.25)]) # visor
	s.head_extras.append([V(0.05, 0.045, 0.012), V(0, 0.3, -0.162), GOLD])


static func _soldier(s: Dictionary, id: int) -> void:
	var camo := Color("4b5a3a") if id % 2 == 0 else Color("8a7a58") # woodland or desert
	var dark := camo.darkened(0.35)
	var light := camo.lightened(0.18)
	s.shirt = camo
	s.pants = camo.darkened(0.06)
	s.hands = Color("2a2a22") # gloves
	s.sleeves = "long"
	s.belt = dark
	_boots(s, Color("2a2420"))
	for k in 6: # camo blotches
		var c := dark if k % 2 == 0 else light
		_add(s, "torso_paint", _splat(V(-0.2 + _r(id, 10 + k) * 0.4, 0.05 + _r(id, 20 + k) * 0.5,
			-0.15 if k < 3 else 0.14), 0.07, c))
		var limb: String = ["upper_arm", "forearm", "thigh", "shin", "thigh", "upper_arm"][k]
		_add(s, limb + "_paint", _splat(V(0, -0.08 - _r(id, 30 + k) * 0.25, -0.08 if k % 2 == 0 else 0.08), 0.07, c))
	s.torso_extras.append([V(0.41, 0.36, 0.32), V(0, 0.39, -0.004), dark])            # plate carrier
	for i in 3:
		s.torso_extras.append([V(0.1, 0.12, 0.05), V(-0.12 + i * 0.12, 0.29, -0.185), dark.lightened(0.12)]) # pouches
	s.torso_extras.append([V(0.05, 0.12, 0.05), V(-0.21, 0.02, -0.04), dark])         # canteen
	s.shin_extras.append([V(0.11, 0.1, 0.05), V(0, -0.02, -0.07), BLACK])             # knee pads
	s.head_extras.append([V(0.35, 0.17, 0.37), V(0, 0.225, 0.008), camo.darkened(0.15), "dome"]) # helmet
	s.head_extras.append([V(0.36, 0.022, 0.38), V(0, 0.232, 0.008), camo.darkened(0.25), "tube"])
	for x in [-0.13, 0.13]:
		s.head_extras.append([V(0.014, 0.17, 0.014), V(x, 0.12, -0.03), BLACK])     # chin strap


static func _firefighter(s: Dictionary, id: int) -> void:
	var coat := Color("9a8048") if id % 2 == 0 else Color("2a2a2e")
	var helmet := Color("b3261e") if id % 3 != 0 else Color("d8b81a")
	s.shirt = coat
	s.pants = coat.darkened(0.08)
	s.hands = Color("3a3020")
	s.sleeves = "long"
	_boots(s, BLACK)
	_add(s, "torso_paint", _band(0.14, 0.2, STRIPE))
	_add(s, "torso_paint", _band(0.4, 0.45, STRIPE))
	_add(s, "torso_paint", _region(V(-0.03, 0.08, -1), V(0.03, 0.62, -0.05), coat.darkened(0.3))) # the clasp line
	_add(s, "upper_arm_paint", _band(-0.2, -0.15, STRIPE))
	_add(s, "forearm_paint", _band(-0.2, -0.12, STRIPE))
	_add(s, "shin_paint", _band(-0.2, -0.15, STRIPE))
	s.torso_extras.append([V(0.42, 0.22, 0.3), V(0, -0.06, 0.0), coat, "tube"])         # coat hem
	s.torso_extras.append([V(0.43, 0.035, 0.31), V(0, -0.12, 0.0), STRIPE, "tube"])
	if id % 2 == 1:
		s.torso_extras.append([V(0.16, 0.42, 0.16), Humanoid.back(0, 0.36, 0.08), Color("8a8a30"), "tube"]) # air tank
	s.head_extras.append([V(0.33, 0.15, 0.35), V(0, 0.258, 0.005), helmet, "dome"])     # helmet
	s.head_extras.append([V(0.38, 0.018, 0.5), V(0, 0.262, 0.06), helmet, "tube"])      # long back brim
	s.head_extras.append([V(0.045, 0.04, 0.3), V(0, 0.4, 0.0), helmet.darkened(0.2)])
	s.head_extras.append([V(0.1, 0.1, 0.015), V(0, 0.32, -0.172), GOLD, "box", Basis(Vector3.RIGHT, 0.3)]) # front shield


static func _office(s: Dictionary, id: int) -> void:
	var suit: Color = [Color("2b2e36"), Color("4a4036"), Color("1c2a3a")][id % 3]
	var tie: Color = [Color("8a1c1c"), Color("1c3a8a"), Color("3a6a2a")][(id / 3) % 3]
	s.shirt = suit
	s.pants = suit.darkened(0.08)
	s.shoes = BLACK
	s.sleeves = "long"
	_add(s, "torso_paint", _region(V(-0.075, 0.42, -1), V(0.075, 1, -0.02), WHITE))   # shirt front
	_add(s, "torso_paint", _region(V(-0.03, 0.28, -1), V(0.03, 0.42, -0.05), WHITE))
	_add(s, "forearm_paint", _band(-1, -0.2, WHITE))                                   # cuffs
	s.torso_extras.append([V(0.05, 0.04, 0.02), Humanoid.chest(0, 0.6, 0.008), tie])   # knot
	s.torso_extras.append([V(0.045, 0.28, 0.012), Humanoid.chest(0, 0.43, 0.007), tie])
	for x in [-0.075, 0.075]:
		s.torso_extras.append([V(0.06, 0.18, 0.014), Humanoid.chest(x, 0.5, 0.004), suit.darkened(0.2),
			"box", Basis(Vector3.FORWARD, 0.35 * signf(x))]) # lapels
	s.torso_extras.append([V(0.4, 0.12, 0.28), V(0, 0.0, 0.0), suit, "tube"])          # jacket hem
	_hair(s, id)
	if id % 4 == 0:
		_glasses(s)


static func _prisoner(s: Dictionary, id: int) -> void:
	var orange := Color("d0661a")
	s.shirt = orange
	s.pants = orange.darkened(0.06)
	s.shoes = Color("c8c8c0")
	_add(s, "torso_paint", _region(V(0.03, 0.42, -1), V(0.17, 0.48, -0.05), WHITE))   # number
	_add(s, "torso_paint", _region(V(-0.15, 0.38, 0.05), V(0.15, 0.5, 1), WHITE))
	s.forearm_extras.append([V(0.1, 0.03, 0.1), V(0, -0.215, 0), Color("8a8a92"), "tube"]) # handcuffs
	if id % 2 == 0: # buzz cut
		_add(s, "head_paint", _region(V(-1, 0.24, -1), V(1, 1, 1), Color("1a1a1a")))
		_add(s, "head_paint", _region(V(-1, 0.12, 0.03), V(1, 1, 1), Color("1a1a1a")))


static func _feral(s: Dictionary, id: int) -> void:
	var skin := Color("b9c2b0")
	s.skin = skin
	s.shirt = skin
	s.sleeves = "none"
	s.pants = Color("1b1d21")
	s.shoes = skin.darkened(0.15)
	s.sole = skin.darkened(0.35)
	s.hands = skin.darkened(0.1)
	s.eyes = Color("ffd400")
	s.limp = 0.0
	s.scale = 0.88
	for y in [0.3, 0.37, 0.44]: # ribs
		for x in [-0.25, 0.1]:
			_add(s, "torso_paint", _region(V(x, y - 0.02, -1), V(x + 0.15, y + 0.02, 1), skin.darkened(0.25)))
	for i in 5: # spine
		s.torso_extras.append([V(0.045, 0.04, 0.035), Humanoid.back(0, 0.15 + i * 0.1, -0.008), skin.darkened(0.1), "ball"])
	_add(s, "shin_paint", _splat(V(0, -0.32, 0), 0.09, skin)) # torn trousers
	_stain(s, "head", V(0, 0.055, -1), 0.05, BLOOD, 0.04)
	_add(s, "hand_paint", _splat(V(0, -0.37, 0), 0.07, BLOOD))
	_stain(s, "torso", V(0.02, 0.55, -1), 0.06, BLOOD, 0.25)
	if id % 2 == 0:
		_add(s, "head_paint", _region(V(-1, 0.28, -1), V(1, 1, 1), Color("3a3a36"))) # a few wisps left
