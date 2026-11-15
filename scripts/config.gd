class_name Config
## Every gameplay tuning number lives here. Tune here, never inline.

# --- Network ---
const PORT := 7777
const DISCOVERY_PORT := 7778 # UDP broadcast so LAN games show up in the menu
const MAX_PLAYERS := 8
const TICK_RATE := 20        # snapshots per second sent by the host
const INTERP_DELAY_MS := 125 # remote entities render this far in the past

# --- Player ---
const PLAYER_HP := 100
const LOW_HP_FRACTION := 0.3 # on_low_hp fires when HP drops to this share or below
const PLAYER_RADIUS := 0.4
const PLAYER_HEIGHT := 1.8
const EYE_HEIGHT := 1.65
const WALK_SPEED := 5.0
const SPRINT_SPEED := 8.0
const JUMP_VELOCITY := 7.0
const GRAVITY := 22.0
const MOUSE_SENS := 0.0022
const INTERACT_RANGE := 3.0
const MEDKIT_HEAL := 40

# --- Weapons (per-gun numbers are in weapons.gd) ---
const WEAPON_DAMAGE := 34    # damage of a hit when no gun is named (same as the AK47)
const WEAPON_DRAW_TIME := 0.35 # seconds to swap guns
const FIRE_BUFFER := 0.12    # a click this long before the gun is ready still fires (semi-autos)
const FOV := 75.0
const ADS_TIME := 0.18       # seconds to bring the sights up
const ADS_MOVE_MULT := 0.55  # walking speed while aiming
const ADS_RECOIL_MULT := 0.6
const RECOIL_JITTER := 0.35  # each shot climbs between -35% and +35% of the gun's recoil
const RECOIL_STAYS := 0.35   # share of the kick you have to pull down yourself; the rest recovers
const RECOIL_RECOVER := 7.0  # how fast the view drops back (per second)
const MOVE_SPREAD := 1.0     # extra bullet scatter at full sprint (1.0 = double)
const SPRINT_POSE_TIME := 0.22 # seconds to drop or raise the gun when you start sprinting
const SPRINT_FIRE_HOLD := 0.3  # after a shot the gun stays shouldered this long even if sprinting
const HEAD_MULT := 3.0       # body damage multiplier for headshots
const LIMB_BODY_MULT := 0.5  # share of limb damage that also hurts the body
const ARM_HP := 50           # damage an arm takes before it comes off
const LEG_HP := 60

# --- Zombies ---
const ZOMBIE_MAX := 60
const ZOMBIE_RADIUS := 0.35
const ZOMBIE_SEPARATION := 0.9 # zombies steer apart when closer than this
const ZOMBIE_AGGRO_RANGE := 200.0
const ZOMBIE_ATTACK_RANGE := 1.3
const ZOMBIE_ATTACK_TIME := 0.7   # length of the swing
const ZOMBIE_ATTACK_HIT_AT := 0.3 # moment in the swing the damage lands
const ZOMBIE_DAMAGE := 12
const ARMLESS_DAMAGE_MULT := 0.4  # no arms = it can only bite
const CRAWL_SPEED_MULT := 0.35
const STAGGER_TIME := 0.35
const STAGGER_CHANCE := 0.3
const LEAP_MIN := 4.0
const LEAP_MAX := 11.0
const LEAP_COOLDOWN := 4.0
const LEAP_WINDUP := 0.55
const LEAP_UP := 6.5
const LEAP_DAMAGE := 20
const LEAP_HIT_RADIUS := 1.7

# --- Hordes ---
const TRICKLE_INTERVAL := 2.5 # one straggler this often between hordes
const HORDE_FIRST := 8.0      # seconds until the first horde
const HORDE_INTERVAL := 30.0
const HORDE_SIZE := 16
const HORDE_GROWTH := 4       # extra zombies per wave

# --- World ---
const WEAPON_SPOTS_ACTIVE := 8 # how many of a map's weapon spots hold a gun each match
const SPAWN_MIN_DIST := 18.0  # zombies never appear closer to a player than this (open maps)
const DIRECT_CHECK_RANGE := 14.0 # open maps: beyond this a zombie just follows its path
const CITY_MARGIN := 180.0    # metres of city kept around the outermost POIs
const CITY_CELL := 4.0        # metres per cell of the city's layout / navigation grid
const CITY_FLOOR_H := 3.2
const CITY_WALL_H := 4.0      # the wall where the map ends
const CITY_SPAWN_NEAR := 30.0 # city zombies appear between these distances from a player
const CITY_SPAWN_FAR := 70.0
const CITY_SPAWN_TRIES := 40
const CITY_HILL_FADE := 100.0  # metres over which Morro da Boa Vista rises from the flat city at the forest's edge
const DOOR_HP := 120
const DOOR_BASH_DAMAGE := 10

# --- Physics layers (bit values) ---
const LAYER_WORLD := 1     # floors, walls, closed doors
const LAYER_PLAYER := 2
const LAYER_ZOMBIE := 4    # zombie movement capsules
const LAYER_HITBOX := 8    # per-body-part areas that bullets hit
const LAYER_INTERACT := 16 # things you can right-click
const LAYER_DEBRIS := 32   # gibs and ragdolls
