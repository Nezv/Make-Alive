class_name Characters
## Character presets built on Humanoid. Everything is picked from the id, never at random, so
## every peer draws the same zombie without sending its look over the network.
##
## Zombies come in outfits (who they were): civilians, workers, nurses, doctors, cops, soldiers,
## firefighters, office staff, prisoners. Leapers keep their own feral body.
## Adding an outfit: add it to Outfit, OUTFIT_NAMES and WEIGHTS, write `_name(s, id)` below and
## add it to the match in `zombie_style`. Check it with `tools\godot.ps1 -- --host --zombie-rack`.
##
## Clothes are extra boxes merged into the body part they sit on ([size, position, colour] in
## that part's own space), so a hat leaves with the head and a sleeve with the arm.

enum Outfit { CIVILIAN, WORKER, NURSE, DOCTOR, COP, SOLDIER, FIREFIGHTER, OFFICE, PRISONER, FERAL }
const OUTFIT_NAMES := ["civilian", "worker", "nurse", "doctor", "cop", "soldier", "firefighter",
	"office", "prisoner", "feral"]
## Share of a crowd, out of 100, in Outfit order (FERAL is never rolled: it's the leaper).
const WEIGHTS := [34, 12, 9, 6, 11, 9, 6, 9, 4]

const ZOMBIE_SKINS := [Color("6f8f5a"), Color("7a9461"), Color("5e7d58"), Color("8a9a6a"), Color("7d8f7a")]
const CIVILIAN_SHIRTS := [Color("4a3b2e"), Color("3d4f63"), Color("5a2a2a"), Color("666655"), Color("2f3a2f"),
	Color("70604a"), Color("7a5a80"), Color("a8a089"), Color("2e5d6b"), Color("8a6a2a")]
const CIVILIAN_PANTS := [Color("2b2b3a"), Color("3a3226"), Color("223322"), Color("34435e"), Color("4f4a44")]
const HAIR := [Color("2a1a10"), Color("111111"), Color("9a7a3a"), Color("777777"), Color("6a2a14")]
const PLAYER_SHIRTS := [Color("3366cc"), Color("cc6633"), Color("33aa77"), Color("aa33aa"), Color("cccc33"), Color("33aacc")]
const BLOOD := Color("5a0000")
const BLOOD_DARK := Color("3a0000")
const WHITE := Color("d9d9d2")
const BLACK := Color("15151a")
const STRIPE := Color("c8e03a")  # reflective tape
const GOLD := Color("c9a227")


static func _pick(arr: Array, n: int) -> Color:
	return arr[absi(n) % arr.size()]


static func V(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)


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


## `type` is a Zombie.Type: walkers shamble and limp, runners are bloodier and don't limp,
## leapers are pale, small and long-armed with yellow eyes. `outfit` -1 = pick from the id.
static func zombie(id: int, type: int, outfit := -1) -> Humanoid:
	return Humanoid.create(zombie_style(id, type, outfit))


## The full description of a zombie's look, as Humanoid style keys.
static func zombie_style(id: int, type: int, outfit := -1) -> Dictionary:
	if outfit < 0:
		outfit = outfit_for(id, type)
	var s := {
		"zombie": true,
		"seed": id, # how it moves (gait, twitches, stumbles) comes from the id too
		"frantic": type == Zombie.Type.RUNNER,
		"skin": _pick(ZOMBIE_SKINS, id),
		"shirt": _pick(CIVILIAN_SHIRTS, id * 7),
		"pants": _pick(CIVILIAN_PANTS, id * 13),
		"eyes": Color("ff2200"),
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
		Outfit.FERAL: _feral(s)
	if outfit != Outfit.FERAL:
		_gore(s, id)
		if type == 1: # RUNNER: fresh, fast and soaked
			var shirt: Color = s.shirt
			s.shirt = shirt.lerp(Color("7a1c1c"), 0.45)
			s.hands = Color("6a0c0c")
			s.limp = 0.0
			s.torso_extras.append([V(0.34, 0.24, 0.02), V(-0.04, 0.22, -0.166), BLOOD_DARK])
			s.head_extras.append([V(0.22, 0.1, 0.02), V(0, 0.04, -0.158), BLOOD])
	return s


static func survivor(peer_id: int) -> Humanoid:
	return Humanoid.create({
		"shirt": _pick(PLAYER_SHIRTS, peer_id),
		"torso_extras": [
			[V(0.36, 0.42, 0.18), V(0, 0.33, 0.23), Color("4a4030")], # backpack
		],
	})


# --- Shared bits ------------------------------------------------------------------

## Wounds and stains, different on every zombie.
static func _gore(s: Dictionary, id: int) -> void:
	var x := -0.14 + float((id * 11) % 7) * 0.045
	var y := 0.14 + float((id * 5) % 6) * 0.07
	s.torso_extras.append([V(0.14, 0.12, 0.02), V(x, y, -0.168), BLOOD])
	if id % 2 == 0:
		s.torso_extras.append([V(0.1, 0.2, 0.02), V(-x, 0.5 - y * 0.5, 0.168), BLOOD_DARK]) # exit wound
	if id % 3 == 0:
		s.head_extras.append([V(0.16, 0.07, 0.02), V(0.02, 0.03, -0.157), BLOOD]) # it has eaten
	if id % 5 == 0:
		s.thigh_extras.append([V(0.2, 0.12, 0.22), V(0, -0.3, 0), BLOOD_DARK])


static func _hair(s: Dictionary, id: int, allow_long := true) -> void:
	var c := _pick(HAIR, id * 3)
	match (id * 17) % 4:
		0: # short
			s.head_extras.append([V(0.32, 0.07, 0.32), V(0, 0.3, 0), c])
			s.head_extras.append([V(0.32, 0.14, 0.05), V(0, 0.22, 0.15), c])
		1: # long (or short again under a helmet)
			s.head_extras.append([V(0.32, 0.07, 0.32), V(0, 0.3, 0), c])
			s.head_extras.append([V(0.32, 0.34 if allow_long else 0.14, 0.06),
				V(0, 0.13 if allow_long else 0.22, 0.17), c])
		2: # bun
			s.head_extras.append([V(0.32, 0.06, 0.32), V(0, 0.3, 0), c])
			s.head_extras.append([V(0.14, 0.14, 0.12), V(0, 0.26, 0.2), c])
		3: # bald
			pass


static func _long_sleeves(s: Dictionary, color: Color) -> void:
	s.sleeve = color
	s.forearm = color


# --- Outfits ----------------------------------------------------------------------

static func _civilian(s: Dictionary, id: int) -> void:
	_hair(s, id)
	var shirt: Color = s.shirt
	match (id * 19) % 4:
		0: # t-shirt
			pass
		1: # hoodie
			_long_sleeves(s, shirt)
			s.torso_extras.append([V(0.36, 0.2, 0.1), V(0, 0.58, 0.17), shirt.darkened(0.1)])    # hood
			s.torso_extras.append([V(0.3, 0.12, 0.02), V(0, 0.16, -0.15), shirt.darkened(0.2)])  # pocket
		2: # open jacket over a shirt
			_long_sleeves(s, shirt.darkened(0.25))
			s.torso_extras.append([V(0.16, 0.5, 0.02), V(0, 0.34, -0.146), shirt.lightened(0.35)])
			s.shirt = shirt.darkened(0.25)
		3: # apron (shop or kitchen)
			s.torso_extras.append([V(0.4, 0.5, 0.02), V(0, 0.2, -0.15), Color("b9b3a0")])
			s.thigh_extras.append([V(0.2, 0.3, 0.02), V(0, -0.15, -0.11), Color("b9b3a0")])
	if id % 6 == 0: # baseball cap
		var cap := _pick(CIVILIAN_SHIRTS, id * 5)
		s.head_extras.append([V(0.33, 0.08, 0.33), V(0, 0.32, 0), cap])
		s.head_extras.append([V(0.26, 0.02, 0.14), V(0, 0.29, -0.22), cap.darkened(0.2)])


static func _worker(s: Dictionary, id: int) -> void:
	var vest := Color("e0701a") if id % 2 == 0 else Color("b8d020")
	var hat: Color = [Color("e8c21a"), Color("d8d8d0"), Color("e0701a")][id % 3]
	s.shirt = Color("5b6b7a")
	s.pants = Color("34435e")
	s.shoes = Color("7a5a30")
	s.hands = Color("b08a2a") # work gloves
	s.torso_extras.append([V(0.44, 0.5, 0.31), V(0, 0.35, 0), vest])            # hi-vis vest
	s.torso_extras.append([V(0.45, 0.04, 0.32), V(0, 0.2, 0), WHITE])           # reflective bands
	s.torso_extras.append([V(0.45, 0.04, 0.32), V(0, 0.42, 0), WHITE])
	s.torso_extras.append([V(0.54, 0.07, 0.32), V(0, 0.04, 0), Color("4a3520")]) # tool belt
	s.torso_extras.append([V(0.1, 0.14, 0.08), V(0.24, -0.02, 0.0), Color("3a2a18")]) # pouch
	_hair(s, id, false)
	s.head_extras.append([V(0.34, 0.11, 0.34), V(0, 0.335, 0), hat])             # hard hat
	s.head_extras.append([V(0.37, 0.025, 0.44), V(0, 0.285, -0.03), hat])        # brim
	s.head_extras.append([V(0.07, 0.03, 0.3), V(0, 0.4, 0), hat.darkened(0.12)]) # ridge


static func _nurse(s: Dictionary, id: int) -> void:
	var scrubs: Color = [Color("4fa3a0"), Color("6f8fc8"), Color("c88aa0")][id % 3]
	s.shirt = scrubs
	s.pants = scrubs.darkened(0.12)
	s.shoes = WHITE
	s.torso_extras.append([V(0.2, 0.1, 0.02), V(0, 0.57, -0.146), scrubs.darkened(0.3)]) # v-neck
	s.torso_extras.append([V(0.12, 0.1, 0.02), V(0.12, 0.2, -0.146), scrubs.darkened(0.2)]) # pocket
	s.torso_extras.append([V(0.06, 0.08, 0.02), V(-0.13, 0.46, -0.146), WHITE])          # name badge
	_hair(s, id, false)
	s.head_extras.append([V(0.26, 0.09, 0.1), V(0, 0.34, -0.07), WHITE])                 # cap
	s.head_extras.append([V(0.08, 0.025, 0.02), V(0, 0.34, -0.126), Color("b01818")])    # red cross
	s.head_extras.append([V(0.025, 0.08, 0.02), V(0, 0.34, -0.127), Color("b01818")])
	if id % 2 == 0:
		s.head_extras.append([V(0.26, 0.11, 0.02), V(0, 0.07, -0.166), Color("9fc4d8")]) # surgical mask


static func _doctor(s: Dictionary, id: int) -> void:
	s.shirt = WHITE
	s.pants = Color("3a3a40")
	_long_sleeves(s, WHITE)
	s.torso_extras.append([V(0.53, 0.26, 0.31), V(0, -0.1, 0), WHITE])                   # coat tails
	s.torso_extras.append([V(0.14, 0.44, 0.02), V(0, 0.38, -0.146), Color("4f8f7a")])    # scrubs under
	s.torso_extras.append([V(0.03, 0.3, 0.02), V(-0.1, 0.44, -0.15), BLACK])             # stethoscope
	s.torso_extras.append([V(0.03, 0.3, 0.02), V(0.1, 0.44, -0.15), BLACK])
	s.torso_extras.append([V(0.06, 0.06, 0.03), V(0.1, 0.28, -0.155), Color("9a9aa2")])
	s.torso_extras.append([V(0.1, 0.03, 0.02), V(-0.14, 0.3, -0.146), Color("2a3a6a")])  # pens
	_hair(s, id, false)
	if id % 2 == 0:
		s.head_extras.append([V(0.33, 0.1, 0.33), V(0, 0.31, 0), Color("4f8f7a")])       # surgical cap


static func _cop(s: Dictionary, id: int) -> void:
	var navy := Color("1f2a44")
	s.shirt = navy
	s.pants = Color("161d30")
	s.shoes = BLACK
	if id % 2 == 0:
		_long_sleeves(s, navy)
	s.torso_extras.append([V(0.07, 0.08, 0.02), V(-0.13, 0.46, -0.146), GOLD])           # badge
	s.torso_extras.append([V(0.12, 0.08, 0.02), V(0.12, 0.44, -0.146), navy.darkened(0.3)]) # pocket
	s.torso_extras.append([V(0.54, 0.07, 0.32), V(0, 0.04, 0), BLACK])                   # duty belt
	s.torso_extras.append([V(0.08, 0.18, 0.12), V(0.28, -0.04, 0.0), BLACK])             # holster
	s.torso_extras.append([V(0.07, 0.1, 0.05), V(-0.2, 0.56, -0.14), BLACK])             # radio
	s.upper_arm_extras.append([V(0.16, 0.08, 0.18), V(0, -0.1, 0), GOLD.darkened(0.3)])  # shoulder patch
	_hair(s, id, false)
	s.head_extras.append([V(0.34, 0.07, 0.34), V(0, 0.325, 0), navy])                    # cap
	s.head_extras.append([V(0.38, 0.035, 0.38), V(0, 0.375, 0), navy])
	s.head_extras.append([V(0.3, 0.02, 0.12), V(0, 0.295, -0.2), BLACK])                 # visor
	s.head_extras.append([V(0.07, 0.06, 0.02), V(0, 0.335, -0.176), GOLD])


static func _soldier(s: Dictionary, id: int) -> void:
	var camo := Color("4b5a3a") if id % 2 == 0 else Color("7a7050") # woodland or desert
	var dark := camo.darkened(0.35)
	s.shirt = camo
	s.pants = camo.darkened(0.08)
	s.shoes = BLACK
	s.hands = Color("2a2a22") # gloves
	_long_sleeves(s, camo)
	s.torso_extras.append([V(0.47, 0.42, 0.34), V(0, 0.36, 0), dark])                    # plate carrier
	for i in 3:
		s.torso_extras.append([V(0.11, 0.13, 0.06), V(-0.14 + i * 0.14, 0.24, -0.19), dark.lightened(0.12)]) # pouches
	s.torso_extras.append([V(0.54, 0.07, 0.32), V(0, 0.04, 0), dark])
	s.upper_arm_extras.append([V(0.16, 0.1, 0.1), V(0, -0.08, 0.04), dark])              # camo blotches
	s.upper_arm_extras.append([V(0.16, 0.08, 0.09), V(0, -0.24, -0.045), camo.lightened(0.2)])
	s.thigh_extras.append([V(0.2, 0.12, 0.12), V(0, -0.12, -0.05), dark])
	s.thigh_extras.append([V(0.2, 0.1, 0.12), V(0, -0.33, 0.05), camo.lightened(0.2)])
	s.shin_extras.append([V(0.18, 0.12, 0.06), V(0, -0.04, -0.09), BLACK])               # knee pads
	s.head_extras.append([V(0.36, 0.14, 0.36), V(0, 0.3, 0), camo.darkened(0.15)])       # helmet
	s.head_extras.append([V(0.36, 0.1, 0.2), V(0, 0.2, 0.09), camo.darkened(0.15)])
	s.head_extras.append([V(0.03, 0.2, 0.02), V(0.16, 0.12, -0.05), BLACK])              # chin strap


static func _firefighter(s: Dictionary, id: int) -> void:
	var coat := Color("8a7440") if id % 2 == 0 else Color("26262a")
	var helmet := Color("b3261e") if id % 3 != 0 else Color("d8b81a")
	s.shirt = coat
	s.pants = coat.darkened(0.1)
	s.shoes = BLACK
	s.hands = Color("3a3020")
	_long_sleeves(s, coat)
	s.torso_extras.append([V(0.51, 0.045, 0.29), V(0, 0.16, 0), STRIPE])
	s.torso_extras.append([V(0.51, 0.045, 0.29), V(0, 0.44, 0), STRIPE])
	s.torso_extras.append([V(0.53, 0.2, 0.31), V(0, -0.07, 0), coat])                    # coat hem
	s.torso_extras.append([V(0.54, 0.04, 0.32), V(0, -0.13, 0), STRIPE])
	if id % 2 == 1:
		s.torso_extras.append([V(0.2, 0.44, 0.16), V(0, 0.34, 0.22), Color("8a8a30")])   # air tank
	s.upper_arm_extras.append([V(0.16, 0.04, 0.18), V(0, -0.22, 0), STRIPE])
	s.shin_extras.append([V(0.17, 0.04, 0.19), V(0, -0.2, 0), STRIPE])
	s.head_extras.append([V(0.34, 0.12, 0.34), V(0, 0.34, 0), helmet])                   # helmet
	s.head_extras.append([V(0.4, 0.025, 0.5), V(0, 0.285, 0.05), helmet])                # long back brim
	s.head_extras.append([V(0.06, 0.04, 0.34), V(0, 0.41, 0), helmet.darkened(0.2)])
	s.head_extras.append([V(0.1, 0.1, 0.02), V(0, 0.34, -0.176), GOLD])                  # front shield


static func _office(s: Dictionary, id: int) -> void:
	var suit: Color = [Color("2b2e36"), Color("4a4036"), Color("1c2a3a")][id % 3]
	var tie: Color = [Color("8a1c1c"), Color("1c3a8a"), Color("3a6a2a")][(id / 3) % 3]
	s.shirt = suit
	s.pants = suit.darkened(0.08)
	s.shoes = BLACK
	_long_sleeves(s, suit)
	s.torso_extras.append([V(0.16, 0.46, 0.02), V(0, 0.38, -0.146), WHITE])              # shirt front
	s.torso_extras.append([V(0.05, 0.36, 0.02), V(0, 0.38, -0.152), tie])
	s.torso_extras.append([V(0.09, 0.07, 0.03), V(0, 0.58, -0.152), tie])                # knot
	s.torso_extras.append([V(0.53, 0.1, 0.3), V(0, -0.03, 0), suit])                     # jacket hem
	s.forearm_extras.append([V(0.13, 0.03, 0.15), V(0, -0.245, 0), WHITE])               # cuffs
	_hair(s, id)
	if id % 4 == 0:
		s.head_extras.append([V(0.3, 0.04, 0.02), V(0, 0.19, -0.165), BLACK])            # glasses


static func _prisoner(s: Dictionary, id: int) -> void:
	var orange := Color("d0661a")
	s.shirt = orange
	s.pants = orange.darkened(0.06)
	s.shoes = Color("c8c8c0")
	s.torso_extras.append([V(0.16, 0.07, 0.02), V(0.1, 0.46, -0.146), WHITE])            # number
	s.torso_extras.append([V(0.3, 0.1, 0.02), V(0, 0.44, 0.146), WHITE])
	s.forearm_extras.append([V(0.14, 0.04, 0.16), V(0, -0.23, 0), Color("8a8a92")])      # cuffs
	if id % 2 == 0:
		s.head_extras.append([V(0.32, 0.05, 0.32), V(0, 0.3, 0), Color("1a1a1a")])       # buzz cut


static func _feral(s: Dictionary) -> void:
	s.skin = Color("b9c2b0")
	s.shirt = Color("23262b")
	s.pants = Color("1b1d21")
	s.eyes = Color("ffd400")
	s.limp = 0.0
	s.scale = 0.88
	s.torso_extras = [[V(0.06, 0.5, 0.06), V(0, 0.3, 0.16), Color("d8d8c8")]] # spine ridge
