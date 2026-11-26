class_name Props
## Set dressing built from boxes: vehicles, barricades, camp gear, debris.
##
## Every function draws into the Builder it is given (so a whole yard stays one mesh) at
## transform `t`, and returns the solid parts as [[center, size], ...] in the prop's own space;
## the map turns those into collision shapes and navigation obstacles. Props stand on y = 0 and
## face -Z, like everything else. Scattered detail takes the map's seeded rng, never randf.

const OLIVE := Color("4a5236")
const OLIVE_DARK := Color("353b27")
const TAN := Color("a8946a")
const TAN_DARK := Color("8a7850")
const CONCRETE := Color("8a8c8e")
const CONCRETE_DARK := Color("6a6c6f")
const DARK := Color("1b1b1e")
const TYRE := Color("141416")
const GLASS := Color("16212b")
const STEEL := Color("5a5e64")
const RUST := Color("5a3320")
const WHITE := Color("d4d4cc")
const RED := Color("a01e1e")
const WOOD := Color("6a4a2c")
const HAZARD := Color("d8b21a")
const BRASS := Color("b8922e")
const SOOT := Color("0e0e0f")


static func bx(b: MeshKit.Builder, t: Transform3D, size: Vector3, pos: Vector3, color: Color,
		rot := Basis.IDENTITY) -> void:
	b.box(size, pos, color, rot, t)


static func V(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, y, z)


static func _wheels(b: MeshKit.Builder, t: Transform3D, half_w: float, zs: Array, r := 0.5, tw := 0.36) -> void:
	for z: float in zs:
		for side in [-1.0, 1.0]:
			bx(b, t, V(tw, r * 2.0, r * 2.0), V(side * half_w, r, z), TYRE)
			bx(b, t, V(tw + 0.02, r * 0.9, r * 0.9), V(side * half_w, r, z), STEEL) # hub


# --- Vehicles ---------------------------------------------------------------------

## Military cargo truck, 7 m long. The bed is open at the back with the tailgate down.
static func truck(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(2.0, 0.3, 6.8), V(0, 0.8, 0), DARK)                         # chassis
	_wheels(b, t, 1.05, [-2.5, 1.0, 2.3])
	bx(b, t, V(2.3, 1.6, 1.9), V(0, 1.75, -2.45), OLIVE)                   # cab
	bx(b, t, V(2.0, 0.6, 0.06), V(0, 2.05, -3.42), GLASS)                  # windshield
	bx(b, t, V(0.06, 0.55, 1.0), V(-1.16, 2.05, -2.5), GLASS)              # side windows
	bx(b, t, V(0.06, 0.55, 1.0), V(1.16, 2.05, -2.5), GLASS)
	bx(b, t, V(2.4, 0.35, 0.25), V(0, 0.8, -3.5), OLIVE_DARK)              # bumper
	bx(b, t, V(0.3, 0.2, 0.06), V(-0.8, 1.2, -3.43), WHITE)                # headlights
	bx(b, t, V(0.3, 0.2, 0.06), V(0.8, 1.2, -3.43), WHITE)
	bx(b, t, V(1.2, 0.5, 0.06), V(0, 1.25, -3.43), DARK)                   # grille
	bx(b, t, V(2.4, 0.15, 4.3), V(0, 1.08, 1.25), OLIVE_DARK)              # bed floor
	bx(b, t, V(0.1, 0.7, 4.3), V(-1.15, 1.5, 1.25), OLIVE)                 # bed sides
	bx(b, t, V(0.1, 0.7, 4.3), V(1.15, 1.5, 1.25), OLIVE)
	bx(b, t, V(2.4, 1.0, 0.1), V(0, 1.6, -0.9), OLIVE)                     # headboard
	bx(b, t, V(2.4, 0.1, 0.75), V(0, 0.78, 3.47), OLIVE, Basis(Vector3.RIGHT, 1.35)) # tailgate, dropped
	for z in [-0.6, 0.9, 2.4]:                                             # canvas hoops
		bx(b, t, V(0.06, 1.1, 0.06), V(-1.15, 2.4, z), STEEL)
		bx(b, t, V(0.06, 1.1, 0.06), V(1.15, 2.4, z), STEEL)
		bx(b, t, V(2.36, 0.06, 0.06), V(0, 2.95, z), STEEL)
	bx(b, t, V(2.44, 0.05, 1.7), V(0, 3.0, 0.1), OLIVE_DARK)               # what's left of the canvas
	bx(b, t, V(0.05, 0.9, 1.7), V(-1.2, 2.55, 0.1), OLIVE_DARK)
	bx(b, t, V(0.35, 0.3, 3.4), V(-0.9, 1.3, 1.1), WOOD)                   # bench
	bx(b, t, V(0.7, 0.4, 0.5), V(0.55, 1.35, -0.4), OLIVE)                 # crate left in the bed
	return [[V(0, 0.58, 0.3), V(2.4, 1.15, 6.9)], [V(0, 1.9, -2.45), V(2.3, 1.9, 1.9)],
		[V(-1.15, 1.5, 1.25), V(0.1, 0.8, 4.3)], [V(1.15, 1.5, 1.25), V(0.1, 0.8, 4.3)],
		[V(0, 1.6, -0.9), V(2.4, 1.0, 0.1)]]


## Light utility vehicle with a roof gun ring.
static func humvee(b: MeshKit.Builder, t: Transform3D, paint := TAN) -> Array:
	_wheels(b, t, 0.95, [-1.4, 1.4], 0.48, 0.34)
	bx(b, t, V(2.1, 0.6, 4.5), V(0, 0.95, 0), paint)                       # tub
	bx(b, t, V(2.0, 0.25, 1.5), V(0, 1.3, -1.5), paint.darkened(0.08))     # hood
	bx(b, t, V(1.9, 0.75, 2.3), V(0, 1.62, 0.25), paint)                   # cabin
	bx(b, t, V(1.7, 0.45, 0.06), V(0, 1.7, -0.92), GLASS)                  # windshield
	bx(b, t, V(0.06, 0.4, 0.8), V(-0.96, 1.7, -0.3), GLASS)
	bx(b, t, V(0.06, 0.4, 0.8), V(0.96, 1.7, -0.3), GLASS)
	bx(b, t, V(2.2, 0.3, 0.2), V(0, 0.75, -2.3), DARK)                     # bumper
	bx(b, t, V(0.25, 0.18, 0.06), V(-0.75, 1.1, -2.27), WHITE)
	bx(b, t, V(0.25, 0.18, 0.06), V(0.75, 1.1, -2.27), WHITE)
	bx(b, t, V(1.0, 0.12, 1.0), V(0, 2.05, 0.3), DARK)                     # gun ring
	bx(b, t, V(0.1, 0.1, 1.1), V(0, 2.25, -0.2), DARK)                     # roof gun
	bx(b, t, V(0.5, 0.35, 0.05), V(0, 2.25, 0.05), paint.darkened(0.2))    # gun shield
	bx(b, t, V(0.06, 0.85, 0.9), V(1.35, 1.2, 0.35), paint, Basis(Vector3.UP, 0.9)) # a door left open
	bx(b, t, V(1.9, 0.5, 0.9), V(0, 1.35, 1.85), paint.darkened(0.12))     # cargo hump
	return [[V(0, 0.72, 0), V(2.1, 1.42, 4.5)], [V(0, 1.72, 0.3), V(1.9, 0.6, 2.2)]]


## Eight-wheeled armoured carrier with a turret; the rear ramp is down.
static func apc(b: MeshKit.Builder, t: Transform3D) -> Array:
	_wheels(b, t, 1.3, [-2.3, -0.9, 0.5, 1.9], 0.55, 0.4)
	bx(b, t, V(2.8, 1.3, 6.4), V(0, 1.35, 0), OLIVE)                       # hull
	bx(b, t, V(2.8, 1.0, 1.4), V(0, 1.1, -3.4), OLIVE, Basis(Vector3.RIGHT, -0.6)) # sloped nose
	bx(b, t, V(2.5, 0.25, 5.2), V(0, 2.1, 0.3), OLIVE_DARK)                # deck
	bx(b, t, V(1.5, 0.55, 1.7), V(0, 2.45, -0.6), OLIVE)                   # turret
	bx(b, t, V(0.16, 0.16, 2.6), V(0.2, 2.5, -2.6), DARK)                  # cannon
	bx(b, t, V(0.5, 0.2, 0.5), V(-0.45, 2.8, -0.4), OLIVE_DARK)            # hatch, open
	bx(b, t, V(0.5, 0.5, 0.06), V(-0.45, 3.0, -0.1), OLIVE_DARK)
	bx(b, t, V(0.5, 0.25, 0.06), V(-0.8, 1.75, -3.55), GLASS)              # driver's slits
	bx(b, t, V(0.5, 0.25, 0.06), V(0.8, 1.75, -3.55), GLASS)
	bx(b, t, V(0.25, 0.2, 0.06), V(-1.1, 1.3, -3.75), WHITE)
	bx(b, t, V(0.25, 0.2, 0.06), V(1.1, 1.3, -3.75), WHITE)
	bx(b, t, V(2.2, 0.12, 1.9), V(0, 0.45, 4.05), OLIVE_DARK, Basis(Vector3.RIGHT, -0.4)) # ramp
	bx(b, t, V(1.9, 1.1, 0.1), V(0, 1.4, 3.16), SOOT)                      # dark troop bay
	for z in [-1.5, 0.0, 1.5]:
		bx(b, t, V(0.08, 0.5, 0.6), V(1.42, 1.5, z), OLIVE_DARK)           # side boxes
		bx(b, t, V(0.08, 0.5, 0.6), V(-1.42, 1.5, z), OLIVE_DARK)
	return [[V(0, 1.1, 0), V(2.8, 2.2, 6.6)], [V(0, 2.45, -0.6), V(1.5, 0.6, 1.7)]]


## Ambulance with the back doors thrown open and a stretcher inside.
static func ambulance(b: MeshKit.Builder, t: Transform3D) -> Array:
	_wheels(b, t, 0.95, [-1.7, 1.5], 0.42, 0.3)
	bx(b, t, V(2.1, 0.25, 5.3), V(0, 0.62, 0), WHITE)                      # floor
	bx(b, t, V(2.1, 1.3, 1.7), V(0, 1.4, -1.8), WHITE)                     # cab
	bx(b, t, V(1.9, 0.55, 0.06), V(0, 1.75, -2.67), GLASS)
	bx(b, t, V(2.1, 0.5, 0.9), V(0, 1.0, -2.3), WHITE)                     # nose
	bx(b, t, V(0.08, 1.75, 3.5), V(-1.01, 1.62, 0.9), WHITE)               # box sides
	bx(b, t, V(0.08, 1.75, 3.5), V(1.01, 1.62, 0.9), WHITE)
	bx(b, t, V(2.1, 0.08, 3.5), V(0, 2.52, 0.9), WHITE)                    # roof
	bx(b, t, V(2.1, 1.75, 0.08), V(0, 1.62, -0.85), WHITE)                 # bulkhead
	for side in [-1.0, 1.0]:
		bx(b, t, V(0.1, 0.3, 3.5), V(side * 1.04, 1.25, 0.9), RED)         # stripe
		bx(b, t, V(0.1, 0.5, 0.18), V(side * 1.05, 1.95, 0.9), RED)        # cross
		bx(b, t, V(0.1, 0.18, 0.5), V(side * 1.05, 1.95, 0.9), RED)
		bx(b, t, V(1.0, 1.7, 0.06), V(side * 1.5, 1.62, 2.75), WHITE, Basis(Vector3.UP, side * 0.35)) # open doors
	bx(b, t, V(1.0, 0.16, 0.3), V(0, 2.65, -1.6), RED)                     # light bar
	bx(b, t, V(0.6, 0.12, 1.9), V(-0.4, 0.95, 1.2), STEEL)                 # stretcher
	bx(b, t, V(0.55, 0.1, 1.7), V(-0.4, 1.05, 1.2), Color("9a2a2a"))       # stained sheet
	bx(b, t, V(0.4, 0.9, 1.6), V(0.75, 1.2, 0.6), Color("b8c4c8"))         # cabinets
	return [[V(0, 0.38, 0), V(2.1, 0.75, 5.3)], [V(0, 1.5, -1.9), V(2.1, 1.7, 1.9)],
		[V(-1.01, 1.62, 0.9), V(0.1, 1.75, 3.5)], [V(1.01, 1.62, 0.9), V(0.1, 1.75, 3.5)],
		[V(0, 2.52, 0.9), V(2.1, 0.1, 3.5)]]


## City bus that was hauling evacuees.
static func bus(b: MeshKit.Builder, t: Transform3D) -> Array:
	var paint := Color("7f97a8")
	_wheels(b, t, 1.2, [-3.6, 3.4], 0.5, 0.36)
	bx(b, t, V(2.6, 2.5, 11.0), V(0, 1.75, 0), paint)
	bx(b, t, V(2.64, 0.35, 11.02), V(0, 1.15, 0), Color("c9b23a"))         # stripe
	bx(b, t, V(2.4, 0.9, 0.06), V(0, 2.25, -5.52), GLASS)                  # windshield
	bx(b, t, V(1.6, 0.3, 0.06), V(0, 2.85, -5.52), Color("d8882a"))        # destination board
	for i in 7:
		var z := -4.2 + i * 1.4
		bx(b, t, V(0.06, 0.8, 1.1), V(-1.31, 2.25, z), GLASS if i != 2 else SOOT) # one window smashed
		bx(b, t, V(0.06, 0.8, 1.1), V(1.31, 2.25, z), GLASS if i != 5 else SOOT)
	bx(b, t, V(0.06, 1.9, 0.9), V(1.32, 1.5, -4.2), SOOT)                  # door, open
	bx(b, t, V(0.9, 1.9, 0.06), V(1.75, 1.5, -4.7), paint.darkened(0.1), Basis(Vector3.UP, 0.3))
	bx(b, t, V(2.7, 0.3, 0.2), V(0, 0.75, -5.55), DARK)
	return [[V(0, 1.5, 0), V(2.6, 3.0, 11.0)]]


## Family car. `burnt` turns it into a blackened shell.
static func car(b: MeshKit.Builder, t: Transform3D, paint: Color, burnt := false, police := false) -> Array:
	var body := SOOT if burnt else paint
	var glass := Color("050505") if burnt else GLASS
	_wheels(b, t, 0.82, [-1.3, 1.25], 0.33, 0.24)
	bx(b, t, V(1.8, 0.55, 4.3), V(0, 0.68, 0), body)
	bx(b, t, V(1.6, 0.55, 2.2), V(0, 1.2, 0.2), body.darkened(0.05) if not police else WHITE)
	bx(b, t, V(1.5, 0.42, 0.06), V(0, 1.2, -0.92), glass)                  # windshield
	bx(b, t, V(1.5, 0.42, 0.06), V(0, 1.2, 1.32), glass)
	bx(b, t, V(0.06, 0.4, 1.9), V(-0.81, 1.2, 0.2), glass)
	bx(b, t, V(0.06, 0.4, 1.9), V(0.81, 1.2, 0.2), glass)
	bx(b, t, V(1.84, 0.2, 0.15), V(0, 0.5, -2.15), DARK)                   # bumpers
	bx(b, t, V(1.84, 0.2, 0.15), V(0, 0.5, 2.15), DARK)
	if not burnt:
		bx(b, t, V(0.3, 0.14, 0.06), V(-0.6, 0.78, -2.16), WHITE)
		bx(b, t, V(0.3, 0.14, 0.06), V(0.6, 0.78, -2.16), WHITE)
		bx(b, t, V(0.3, 0.12, 0.06), V(-0.6, 0.78, 2.16), RED)
		bx(b, t, V(0.3, 0.12, 0.06), V(0.6, 0.78, 2.16), RED)
	if police:
		bx(b, t, V(1.82, 0.3, 1.2), V(0, 0.7, 0.2), WHITE)                 # white doors
		bx(b, t, V(0.5, 0.12, 0.25), V(-0.3, 1.54, 0.2), Color("2040c0"))  # light bar
		bx(b, t, V(0.5, 0.12, 0.25), V(0.3, 1.54, 0.2), RED)
		bx(b, t, V(1.7, 0.06, 1.0), V(0, 1.18, 2.1), body, Basis(Vector3.RIGHT, 0.9)) # boot lid up
	return [[V(0, 0.75, 0), V(1.8, 1.5, 4.3)]]


## A transport helicopter that didn't make it out.
static func helicopter(b: MeshKit.Builder, t: Transform3D) -> Array:
	var tilt := Basis(Vector3.FORWARD, 0.22)
	bx(b, t, V(2.2, 2.0, 5.2), V(0, 1.15, 0), OLIVE, tilt)                 # cabin
	bx(b, t, V(2.0, 1.2, 1.4), V(0.1, 1.3, -3.0), OLIVE, tilt)             # nose
	bx(b, t, V(1.8, 0.8, 0.08), V(0.12, 1.6, -3.72), GLASS, tilt)          # canopy
	bx(b, t, V(0.08, 0.7, 1.2), V(-0.9, 1.75, -2.9), GLASS, tilt)
	bx(b, t, V(0.08, 1.3, 1.8), V(-0.9, 1.1, 0.2), SOOT, tilt)             # open side door
	bx(b, t, V(1.4, 0.7, 2.4), V(0.2, 2.45, 0.2), OLIVE_DARK, tilt)        # engine housing
	bx(b, t, V(0.2, 0.5, 0.2), V(0.3, 3.0, 0.0), STEEL, tilt)              # rotor mast
	bx(b, t, V(7.5, 0.06, 0.4), V(2.6, 3.0, 0.3), DARK, Basis(Vector3.FORWARD, 0.5) * Basis(Vector3.UP, 0.4)) # blades
	bx(b, t, V(0.4, 0.06, 6.0), V(0.6, 3.2, 2.2), DARK, Basis(Vector3.RIGHT, -0.25))
	bx(b, t, V(0.5, 0.06, 4.5), V(-3.2, 0.06, -1.5), DARK, Basis(Vector3.UP, 0.8)) # one snapped off
	bx(b, t, V(0.7, 0.7, 3.2), V(0.3, 1.5, 4.0), OLIVE, Basis(Vector3.RIGHT, 0.12)) # tail boom
	bx(b, t, V(0.6, 0.6, 2.6), V(1.6, 0.4, 6.6), OLIVE, Basis(Vector3.UP, 0.7))    # ...broken off
	bx(b, t, V(0.12, 1.4, 0.8), V(2.5, 0.75, 7.6), OLIVE_DARK, Basis(Vector3.UP, 0.7))
	bx(b, t, V(0.15, 0.15, 4.2), V(-1.0, 0.1, -0.3), STEEL)                # skids
	bx(b, t, V(0.15, 0.15, 4.2), V(1.2, 0.3, -0.3), STEEL)
	return [[V(0, 1.3, -0.6), V(2.6, 2.6, 6.6)], [V(0.3, 1.2, 4.0), V(0.9, 2.0, 3.2)],
		[V(1.6, 0.4, 6.6), V(1.8, 0.8, 2.4)]]


## The transport helicopter that comes for you: olive cabin with both sliding doors open, the
## cockpit glass, engine housing, the long tail boom with its fin and stabiliser, and skids.
## The rotors are separate (`rotor`) because they turn. Skids touch y = 0; the main rotor hub is
## at HELI_HUB, the tail rotor's at HELI_TAIL_HUB.
const HELI_HUB := Vector3(0, 3.75, -0.3)
const HELI_TAIL_HUB := Vector3(0.45, 3.0, 9.7)
static func transport_helicopter(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(2.4, 1.9, 4.6), V(0, 1.55, 0), OLIVE)                         # cabin
	bx(b, t, V(2.2, 1.0, 0.3), V(0, 0.75, 0), OLIVE_DARK)                    # belly
	bx(b, t, V(2.2, 1.5, 2.0), V(0, 1.5, -3.2), OLIVE)                       # nose
	bx(b, t, V(1.9, 0.9, 1.3), V(0, 1.05, -4.6), OLIVE_DARK)                 # chin
	bx(b, t, V(2.0, 0.9, 0.08), V(0, 2.1, -4.15), GLASS, Basis(Vector3.RIGHT, -0.5)) # windscreen
	for side in [-1.0, 1.0]:
		bx(b, t, V(0.06, 0.8, 1.6), V(side * 1.12, 1.85, -3.1), GLASS)         # cockpit side windows
		bx(b, t, V(0.06, 1.45, 1.9), V(side * 1.22, 1.45, 0.4), SOOT)          # open sliding door...
		bx(b, t, V(0.08, 1.45, 1.9), V(side * 1.3, 1.45, 2.2), OLIVE_DARK)     # ...slid back
		bx(b, t, V(0.1, 0.1, 5.2), V(side * 1.3, 0.06, -0.5), STEEL)           # skid
		for z in [-1.8, 1.0]:
			bx(b, t, V(0.1, 0.75, 0.1), V(side * 1.2, 0.42, z), STEEL, Basis(Vector3.FORWARD, side * 0.25))
		bx(b, t, V(0.1, 0.1, 0.5), V(side * 1.3, 0.16, -3.2), STEEL, Basis(Vector3.RIGHT, -0.5)) # skid tip
	bx(b, t, V(1.6, 0.8, 3.2), V(0, 2.85, 0.2), OLIVE_DARK)                  # engine housing
	bx(b, t, V(0.5, 0.4, 0.5), V(0, 2.9, 1.9), SOOT)                         # exhaust
	bx(b, t, V(0.24, 0.55, 0.24), HELI_HUB + V(0, -0.3, 0), STEEL)           # mast
	bx(b, t, V(0.9, 0.9, 4.0), V(0, 2.2, 4.2), OLIVE)                        # tail boom
	bx(b, t, V(0.6, 0.6, 3.4), V(0, 2.45, 7.7), OLIVE)
	bx(b, t, V(0.15, 2.0, 1.3), V(0, 3.2, 9.6), OLIVE, Basis(Vector3.RIGHT, -0.3)) # fin
	bx(b, t, V(3.0, 0.08, 0.8), V(0, 2.3, 8.8), OLIVE_DARK)                  # stabiliser
	bx(b, t, V(0.9, 0.6, 0.06), V(0, 1.9, 2.32), WHITE)                      # a number on the back
	return [[V(0, 1.5, -1.0), V(2.4, 2.4, 7.0)]]


## Rotor blades round the hub, in the hub's own space: `count` blades `radius` long, flat (or,
## with `upright`, turning about X for a tail rotor).
static func rotor(b: MeshKit.Builder, radius: float, count: int, chord: float, upright := false) -> void:
	for i in count:
		var a := TAU * i / count
		var rot := Basis(Vector3.UP, a) if not upright else Basis(Vector3.RIGHT, a)
		var along := rot * V(0, 0, -radius * 0.5) if not upright else rot * V(0, radius * 0.5, 0)
		var size := V(chord, 0.06, radius) if not upright else V(0.06, radius, chord)
		b.box(size, along, DARK, rot)
	b.box(V(0.5, 0.25, 0.5), Vector3.ZERO, STEEL)


# --- Barricades -------------------------------------------------------------------

## A wall of sandbags `length` long (along X), `rows` bags high.
static func sandbags(b: MeshKit.Builder, t: Transform3D, length: float, rows := 3) -> Array:
	var bag := 0.62
	var n := maxi(1, roundi(length / bag))
	for row in rows:
		var shift := bag * 0.5 if row % 2 == 1 else 0.0
		for i in n - (1 if row % 2 == 1 else 0):
			var x := -length * 0.5 + bag * 0.5 + i * bag + shift
			var shade := 0.06 * float((i * 7 + row * 3) % 4)
			bx(b, t, V(bag - 0.04, 0.26, 0.4), V(x, 0.14 + row * 0.27, 0.03 * float((i + row) % 3 - 1)),
				TAN.darkened(shade))
	return [[V(0, rows * 0.135, 0), V(length, rows * 0.27, 0.42)]]


## Concrete road barrier, 3 m long (along Z).
static func barrier(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(0.62, 0.3, 3.0), V(0, 0.15, 0), CONCRETE_DARK)
	bx(b, t, V(0.42, 0.25, 3.0), V(0, 0.42, 0), CONCRETE)
	bx(b, t, V(0.26, 0.4, 3.0), V(0, 0.72, 0), CONCRETE)
	for z in [-1.1, -0.35, 0.4, 1.15]:
		bx(b, t, V(0.28, 0.2, 0.3), V(0, 0.75, z), HAZARD)
	return [[V(0, 0.46, 0), V(0.62, 0.92, 3.0)]]


## Earth-filled wire basket.
static func hesco(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(1.2, 1.3, 1.2), V(0, 0.65, 0), TAN_DARK)
	bx(b, t, V(1.1, 0.1, 1.1), V(0, 1.33, 0), Color("5a4a34"))             # dirt on top
	for x in [-0.61, 0.61]:
		for z in [-0.61, 0.61]:
			bx(b, t, V(0.05, 1.34, 0.05), V(x, 0.67, z), STEEL)
	for y in [0.35, 0.7, 1.05]:
		bx(b, t, V(1.25, 0.03, 1.25), V(0, y, 0), STEEL)
	return [[V(0, 0.68, 0), V(1.2, 1.36, 1.2)]]


## A coil of razor wire `length` long (along X).
static func wire(b: MeshKit.Builder, t: Transform3D, length: float) -> Array:
	var n := maxi(2, roundi(length / 0.5))
	for i in n:
		var x := -length * 0.5 + (i + 0.5) * length / n
		var lean := 0.7 if i % 2 == 0 else -0.7
		bx(b, t, V(0.03, 0.95, 0.03), V(x, 0.42, 0), STEEL, Basis(Vector3.RIGHT, lean))
		bx(b, t, V(length / n + 0.05, 0.025, 0.025), V(x, 0.75 if i % 2 == 0 else 0.2, 0.25 if i % 2 == 0 else -0.25), STEEL)
	for x in [-length * 0.5, 0.0, length * 0.5]:
		bx(b, t, V(0.06, 1.0, 0.06), V(x, 0.5, 0), RUST, Basis(Vector3.FORWARD, 0.5))
		bx(b, t, V(0.06, 1.0, 0.06), V(x, 0.5, 0), RUST, Basis(Vector3.FORWARD, -0.5))
	return [[V(0, 0.4, 0), V(length, 0.8, 0.7)]]


## Chain-link fence `length` long (along X).
static func fence(b: MeshKit.Builder, t: Transform3D, length: float) -> Array:
	var posts := maxi(2, roundi(length / 2.6) + 1)
	for i in posts:
		bx(b, t, V(0.08, 2.5, 0.08), V(-length * 0.5 + i * length / (posts - 1), 1.25, 0), STEEL)
	for y in [0.15, 0.6, 1.05, 1.5, 1.95, 2.4]:
		bx(b, t, V(length, 0.035, 0.035), V(0, y, 0), STEEL)
	for i in int(length / 0.65):
		bx(b, t, V(0.025, 2.3, 0.025), V(-length * 0.5 + 0.3 + i * 0.65, 1.25, 0), Color("44484e"))
	bx(b, t, V(length, 0.3, 0.3), V(0, 2.65, 0), Color("44484e"), Basis(Vector3.RIGHT, 0.6)) # barbed top
	return [[V(0, 1.3, 0), V(length, 2.6, 0.15)]]


# --- Camp gear --------------------------------------------------------------------

## Folding table, 1.8 m long (along X). The top is at y = 0.8.
static func table(b: MeshKit.Builder, t: Transform3D, top := Color("6f7376")) -> Array:
	bx(b, t, V(1.8, 0.06, 0.8), V(0, 0.77, 0), top)
	for x in [-0.8, 0.8]:
		for z in [-0.32, 0.32]:
			bx(b, t, V(0.05, 0.75, 0.05), V(x, 0.375, z), STEEL)
	return [[V(0, 0.4, 0), V(1.8, 0.8, 0.8)]]


static func crate(b: MeshKit.Builder, t: Transform3D, size := Vector3(1.0, 0.6, 0.7), color := OLIVE,
		open := false) -> Array:
	bx(b, t, size, V(0, size.y * 0.5, 0), color)
	bx(b, t, V(size.x + 0.03, 0.06, size.z + 0.03), V(0, size.y * 0.25, 0), color.darkened(0.3))
	bx(b, t, V(size.x + 0.03, 0.06, size.z + 0.03), V(0, size.y * 0.8, 0), color.darkened(0.3))
	if open:
		bx(b, t, V(size.x - 0.1, 0.05, size.z - 0.1), V(0, size.y + 0.005, 0), BRASS) # belts of ammunition
		bx(b, t, V(size.x, 0.06, size.z), V(0, size.y * 0.6, size.z * 0.85), color, Basis(Vector3.RIGHT, 1.2))
	return [[V(0, size.y * 0.5, 0), size]]


## Open-sided tent `w` wide (X) by `d` deep (Z). Poles only: you can walk through it.
static func tent(b: MeshKit.Builder, t: Transform3D, w: float, d: float, canvas := WHITE, cross := true) -> Array:
	for x in [-w * 0.5, 0.0, w * 0.5]:
		for z in [-d * 0.5, d * 0.5]:
			bx(b, t, V(0.08, 2.3, 0.08), V(x, 1.15, z), STEEL)
	var slope := atan2(0.9, d * 0.5)
	var run := sqrt(0.81 + d * d * 0.25)
	bx(b, t, V(w + 0.4, 0.05, run + 0.1), V(0, 2.75, -d * 0.25), canvas, Basis(Vector3.RIGHT, -slope))
	bx(b, t, V(w + 0.4, 0.05, run + 0.1), V(0, 2.75, d * 0.25), canvas.darkened(0.1), Basis(Vector3.RIGHT, slope))
	bx(b, t, V(w + 0.4, 0.5, 0.04), V(0, 2.1, -d * 0.5 - 0.02), canvas.darkened(0.05)) # valances
	bx(b, t, V(w + 0.4, 0.5, 0.04), V(0, 2.1, d * 0.5 + 0.02), canvas.darkened(0.05))
	bx(b, t, V(0.04, 2.3, d), V(-w * 0.5 - 0.02, 1.15, 0), canvas.darkened(0.15)) # one closed end
	if cross:
		bx(b, t, V(0.9, 0.28, 0.05), V(0, 2.1, d * 0.5 + 0.05), RED)
		bx(b, t, V(0.28, 0.44, 0.05), V(0, 2.1, d * 0.5 + 0.05), RED)
	return [[V(-w * 0.5 - 0.02, 1.15, 0), V(0.1, 2.3, d)]]


## Camp bed / stretcher on legs.
static func cot(b: MeshKit.Builder, t: Transform3D, stained := false) -> Array:
	bx(b, t, V(0.75, 0.06, 1.95), V(0, 0.42, 0), Color("5f6b4a"))
	bx(b, t, V(0.6, 0.1, 0.4), V(0, 0.5, -0.7), WHITE)                     # pillow
	if stained:
		bx(b, t, V(0.5, 0.02, 0.9), V(0.05, 0.46, 0.2), Color("5a0a0a"))
	for x in [-0.33, 0.33]:
		for z in [-0.85, 0.85]:
			bx(b, t, V(0.04, 0.42, 0.04), V(x, 0.21, z), STEEL)
	return []


## A body that someone had time to bag.
static func bodybag(b: MeshKit.Builder, t: Transform3D, color := Color("1d1f24")) -> Array:
	bx(b, t, V(0.55, 0.22, 1.2), V(0, 0.12, 0.25), color)
	bx(b, t, V(0.42, 0.26, 0.45), V(0, 0.14, -0.55), color)                # head end
	bx(b, t, V(0.36, 0.2, 0.4), V(0, 0.11, 1.0), color)                    # feet
	bx(b, t, V(0.04, 0.02, 1.7), V(0, 0.245, 0.15), Color("8a8a8a"))       # zip
	return []


## Generator with a light mast. Returns [] and leaves the lamp head at (0, 5.2, 0).
static func floodlight(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(1.3, 0.8, 0.9), V(0, 0.55, 0), HAZARD.darkened(0.25))
	bx(b, t, V(1.4, 0.15, 1.0), V(0, 0.12, 0), DARK)
	bx(b, t, V(0.1, 4.6, 0.1), V(0, 3.0, 0), STEEL)
	bx(b, t, V(1.3, 0.1, 0.1), V(0, 5.2, 0), STEEL)
	return [[V(0, 0.5, 0), V(1.3, 1.0, 0.9)]]


static func barrel(b: MeshKit.Builder, t: Transform3D, color := RUST) -> Array:
	b.cyl(0.3, 0.9, V(0, 0.45, 0), color, 8, Basis.IDENTITY, t)
	return [[V(0, 0.45, 0), V(0.6, 0.9, 0.6)]]


## Checkpoint hut with a window.
static func booth(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(2.0, 1.0, 2.0), V(0, 0.5, 0), CONCRETE)
	bx(b, t, V(2.0, 1.1, 0.1), V(0, 1.55, 0.95), CONCRETE)
	bx(b, t, V(0.1, 1.1, 2.0), V(0.95, 1.55, 0), CONCRETE)
	bx(b, t, V(1.9, 1.0, 0.05), V(0, 1.55, -0.97), GLASS)
	bx(b, t, V(0.05, 1.0, 1.9), V(-0.97, 1.55, 0), GLASS)
	bx(b, t, V(2.4, 0.12, 2.4), V(0, 2.16, 0), OLIVE_DARK)
	bx(b, t, V(0.12, 0.12, 2.6), V(-1.6, 1.0, 1.4), HAZARD, Basis(Vector3.RIGHT, 0.5)) # snapped boom
	return [[V(0, 1.1, 0), V(2.0, 2.2, 2.0)]]


## Tripod-mounted machine gun.
static func mounted_gun(b: MeshKit.Builder, t: Transform3D) -> Array:
	for a in [0.0, 2.1, 4.2]:
		bx(b, t, V(0.04, 0.9, 0.04), V(sin(a) * 0.22, 0.4, cos(a) * 0.22), STEEL,
			Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, 0.5))
	bx(b, t, V(0.1, 0.14, 0.9), V(0, 0.86, -0.1), DARK)
	bx(b, t, V(0.05, 0.05, 0.7), V(0, 0.88, -0.85), DARK)
	bx(b, t, V(0.3, 0.22, 0.2), V(-0.2, 0.8, 0.0), OLIVE)                  # ammo box
	return []


# --- Debris -----------------------------------------------------------------------

## A heap of broken concrete about `radius` across.
static func rubble(b: MeshKit.Builder, t: Transform3D, radius: float, rng: RandomNumberGenerator) -> Array:
	var n := int(8 + radius * 7)
	for i in n:
		var r := radius * sqrt(rng.randf())
		var a := rng.randf() * TAU
		var s := rng.randf_range(0.18, 0.75) * (1.2 - r / radius * 0.6)
		var rot := Basis.from_euler(Vector3(rng.randf_range(-0.7, 0.7), rng.randf() * TAU, rng.randf_range(-0.7, 0.7)))
		bx(b, t, V(s * rng.randf_range(0.7, 1.6), s, s * rng.randf_range(0.7, 1.4)),
			V(cos(a) * r, s * 0.35 + (radius - r) * 0.22, sin(a) * r),
			CONCRETE.darkened(rng.randf_range(0.0, 0.35)), rot)
	bx(b, t, V(0.05, 0.05, 1.6), V(0.3, radius * 0.25, 0.2), RUST, Basis.from_euler(V(0.5, 0.4, 0))) # rebar
	bx(b, t, V(0.05, 0.05, 1.3), V(-0.4, radius * 0.2, -0.3), RUST, Basis.from_euler(V(-0.6, 2.0, 0)))
	return [[V(0, radius * 0.14, 0), V(radius * 0.9, radius * 0.28, radius * 0.9)]]


## A shell hole: scorched earth with a raised rim.
static func crater(b: MeshKit.Builder, t: Transform3D, radius: float, rng: RandomNumberGenerator) -> Array:
	b.cyl(radius, 0.02, V(0, 0.011, 0), SOOT, 10, Basis.IDENTITY, t)
	b.cyl(radius * 0.55, 0.03, V(0, 0.016, 0), Color("231b14"), 8, Basis.IDENTITY, t)
	for i in 10:
		var a := TAU * i / 10.0 + rng.randf_range(-0.2, 0.2)
		var s := rng.randf_range(0.2, 0.5)
		bx(b, t, V(s * 1.6, s * 0.5, s), V(cos(a) * radius * 0.95, s * 0.2, sin(a) * radius * 0.95),
			Color("3a332a").darkened(rng.randf_range(0.0, 0.3)), Basis(Vector3.UP, -a + 1.57))
	return []


## Suitcases and bags dropped by people who ran.
static func luggage(b: MeshKit.Builder, t: Transform3D, count: int, rng: RandomNumberGenerator) -> Array:
	var colors := [Color("7a2a2a"), Color("2a4a7a"), Color("3a3a3a"), Color("8a6a3a"), Color("3a6a4a"), Color("7a4a7a")]
	for i in count:
		var p := V(rng.randf_range(-1.6, 1.6), 0, rng.randf_range(-1.6, 1.6))
		var flat := rng.randf() < 0.6
		var size := V(0.7, 0.24, 0.45) if flat else V(0.45, 0.65, 0.25)
		var c: Color = colors[rng.randi() % colors.size()]
		var rot := Basis(Vector3.UP, rng.randf() * TAU)
		bx(b, t, size, p + V(0, size.y * 0.5, 0), c, rot)
		bx(b, t, V(size.x * 0.3, 0.04, 0.06), p + V(0, size.y + 0.02, 0), DARK, rot) # handle
	return []


## Spent brass.
static func casings(b: MeshKit.Builder, t: Transform3D, count: int, rng: RandomNumberGenerator) -> Array:
	for i in count:
		bx(b, t, V(0.02, 0.02, 0.06), V(rng.randf_range(-1.2, 1.2), 0.012, rng.randf_range(-1.2, 1.2)), BRASS,
			Basis(Vector3.UP, rng.randf() * TAU))
	return []


static func cone(b: MeshKit.Builder, t: Transform3D) -> Array:
	bx(b, t, V(0.36, 0.04, 0.36), V(0, 0.02, 0), DARK)
	bx(b, t, V(0.22, 0.3, 0.22), V(0, 0.19, 0), Color("e0661a"))
	bx(b, t, V(0.24, 0.08, 0.24), V(0, 0.26, 0), WHITE)
	bx(b, t, V(0.12, 0.25, 0.12), V(0, 0.46, 0), Color("e0661a"))
	return []
