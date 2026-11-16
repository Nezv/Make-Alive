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
const STAMINA_MAX := 100.0
const STAMINA_SPRINT_DRAIN := 12.0 # per second of sprinting (a full bar is about 8 s)
const STAMINA_REFILL := 20.0     # per second, once rested
const STAMINA_REST_DELAY := 0.8  # seconds without sprinting before it starts to refill
const STAMINA_RECOVER := 25.0    # after running dry, no sprint until it is back up to this
const STAMINA_JUMP_COST := 6.0
const STAMINA_VAULT_COST := 10.0
const BREATH_INTERVAL := 0.9     # seconds between heavy breaths while winded
const BREATH_VOLUME := -8.0      # dB
const CROUCH_TIME := 0.2         # seconds to get down or up
const CROUCH_HEIGHT := 1.1       # capsule height when crouched
const CROUCH_EYE_HEIGHT := 1.0
const CROUCH_SPEED_MULT := 0.5   # of walking speed
const CROUCH_SPREAD_MULT := 0.7  # bullet scatter when crouched
const CROUCH_STEP_LOUDNESS := 0.35 # footsteps, as a share of a standing walk
const SPRINT_STEP_LOUDNESS := 1.8
const COYOTE_TIME := 0.12        # seconds after walking off an edge in which a jump still works
const LAND_DIP_PER_SPEED := 0.025 # metres the view dips per m/s of fall speed...
const LAND_DIP_MAX := 0.35       # ...up to this
const LAND_DIP_RECOVER := 9.0    # how fast it comes back (per second)
const FALL_SAFE_HEIGHT := 3.5    # metres you can fall unhurt (a jump is about 1.1)
const FALL_DAMAGE_PER_M := 12.0  # HP per metre beyond that
const VAULT_TIME := 0.5          # seconds to go over cover
const VAULT_REACH := 1.0         # metres ahead that cover is looked for when sprinting into it
const VAULT_MIN_HEIGHT := 0.4    # lower than this you just step or jump
const VAULT_MAX_HEIGHT := 1.2    # waist high; higher is a wall
const VAULT_MAX_DEPTH := 0.8     # thicker cover than this cannot be cleared
const VAULT_CLEARANCE := 0.15    # how far the feet pass above its top
const GRAVITY := 22.0
const MOUSE_SENS := 0.0022
const INTERACT_RANGE := 3.0
const MEDKIT_HEAL := 40
const AMMO_BOX_PIPS := 5        # squares printed on a full carton (fewer as it empties)
const AMMO_CRATE_USES := 6      # takes before a military crate is empty
const AMMO_CRATE_BOXES := 2     # cartons' worth of the held gun's calibre per take
const AMMO_CRATE_OPEN_TIME := 1.2 # seconds the lid stays up after a take
const AMMO_DROP_CHANCE := 0.06  # share of dead zombies that leave a carton...
const AMMO_DROP_CHANCE_ARMED := 0.3 # ...and of the ones that carried a gun in life
## Outfit -> the calibres its dead carry (Weapons.Ammo). Outfits not listed drop any calibre, rarely.
const AMMO_DROP_ARMED := {
	Characters.Outfit.COP: [Weapons.Ammo.MM9, Weapons.Ammo.GAUGE12],
	Characters.Outfit.SOLDIER: [Weapons.Ammo.MM762, Weapons.Ammo.MM58, Weapons.Ammo.MM9X39],
}
const AMMO_DROPS_MAX := 24      # dropped cartons lying around at once; the oldest goes first
const DROP_IID_BASE := 100000   # interactable ids from here up are things dropped during the match
const PICKUP_HOP_TIME := 0.15   # seconds a pickup takes to fly to the player who took it
const PICKUP_HOP_HEIGHT := 1.1  # it flies to this height on the player (chest)
const PICKUP_HOP_ARC := 0.25    # how high it rises on the way
const PICKUP_GAIN_TIME := 1.2   # seconds the "+30" stays on the HUD
const PICKUP_GAIN_RISE := 34.0  # pixels it climbs meanwhile

# --- Weapons (per-gun numbers are in weapons.gd) ---
const WEAPON_DAMAGE := 34    # damage of a hit when no gun is named (same as the AK47)
const WEAPON_DRAW_TIME := 0.35 # seconds the first gun of a match takes to come up (swaps: Weapons.GUN_DRAW)
const FIRE_BUFFER := 0.12    # a click this long before the gun is ready still fires (semi-autos)
const DRY_FIRE_TIME := 0.14  # seconds the gun twitches after a click on an empty chamber
const DRY_FIRE_TWITCH := 0.03 # how far it dips, radians
const DRY_FIRE_VOLUME := -10.0 # dB
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
const ZOMBIE_NOTICE_RANGE := 15.0 # a player this close beats any noise: the zombie goes for them
const CHECKPOINT_CALM := 20.0   # seconds the director sends nobody after a checkpoint is reached
const NOISE_INVESTIGATE_TIME := 12.0 # seconds a zombie stays interested in a noise it heard
const NOISE_ARRIVE := 1.5        # metres from the spot at which it stops and stands there
const NOISE_DOOR_BREAK := 40.0   # loudness = metres away it is heard (guns: Weapons.GUN_LOUDNESS)
const NOISE_SPRINT := 9.0
const NOISE_SPRINT_SPEED := 6.5  # m/s over the ground from which footsteps count as sprinting
const NOISE_STEP_INTERVAL := 0.5 # seconds between the host's checks for sprinting players
const NOISE_HEAT_PER_M := 0.02   # director heat per metre of loudness (an AK shot: 1.2)
const NOISE_HEAT_FULL := 100.0   # a full meter brings the next horde...
const NOISE_HORDE_SOON := 4.0    # ...within this many seconds
const NOISE_HEAT_DECAY := 1.5    # heat lost per second
const NOISE_RING_TIME := 1.5     # --noise: seconds a debug ring takes to spread and vanish
const NOISE_RINGS_MAX := 24
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

# --- The test bot (scripts/bot.gd) ---
const BOT_SIGHT := 25.0         # metres at which it notices and shoots a zombie
const BOT_HOLD_DIST := 13.0     # a zombie closer than this: stop walking and shoot
const BOT_RETREAT_DIST := 7.0  # closer than this: back away while shooting
const BOT_ARRIVE_DIST := 1.0    # this close to a goal point counts as there
const BOT_DOOR_RETRY := 1.0     # seconds between tries at a door in its way
const BOT_STUCK_DIST := 0.5     # moving less than this...
const BOT_STUCK_SECONDS := 5.0  # ...for this long while trying to walk means it is stuck
const BOT_TIME_SCALE := 8.0     # bot playtests run this many times faster than real time

# --- Performance budget (scripts/budget.gd, tests/test_budget.gd). Raise one only on purpose. ---
const BUDGET := {
	"corridor": { "meshes": 12, "surfaces": 12, "lights": 8, "shadow_lights": 2, "shapes": 20, "worst_view": 11 }, # +1: the checkpoint's lamp
	"city": { "meshes": 16, "surfaces": 16, "lights": 14, "shadow_lights": 2, "shapes": 26000, "worst_view": 14 },
}
const BUDGET_HOST_TICK_MS := 16.6  # the host's tick with ZOMBIE_MAX zombies must fit one 60 Hz frame
const BUDGET_PACKET_BYTES := 1392  # a snapshot larger than this is split by the network and may stall

# --- Effects (scripts/fx/fx.gd): every pool is made once at this size; the oldest entry is reused ---
const EXTRACT_SMOKE_HEIGHT := 30.0 # metres the flare's smoke column climbs
const EXTRACT_SMOKE_LIFE := 6.0    # seconds a puff of it lives
const EXTRACT_PUFF_EVERY := 0.15   # seconds between puffs (about 40 alive)
const EXTRACT_SPARK_EVERY := 0.25  # green sparks drifting up inside the zone
const EXTRACT_PULSE := 1.2         # seconds per pulse of the ring
const EXTRACT_WIND := Vector3(1.4, 0.0, 0.6) # m/s the column leans with
const EXTRACT_BEEPS := 5           # the last seconds of the countdown each beep, higher and higher
const EXTRACT_BEEP_PITCH := 1.0    # the first of them; each next one a semitone and a half up
const EXTRACT_BEEP_STEP := 1.09
const END_FADE_TIME := 1.6         # seconds to fade to white (or red) at the end
const FX_MAX_CHIPS := 220    # lit debris boxes
const FX_MAX_GLOWS := 260    # sparks and flashes
const FX_MAX_SMOKE := 160    # smoke and dust puffs
const FX_MAX_LIGHTS := 6     # short flashes of light, never shadowed
const FX_MAX_DECALS := 256   # per kind: bullet holes, scorches, cracks, puddles
const FX_MAX_TRAILS := 24
const FX_TRAIL_POINTS := 16  # a ribbon is at most this many points long
const FX_TIER_COUNT := { "low": 0.4, "medium": 0.7, "high": 1.0 } # share of a burst's particles drawn
const FX_TIER_LIFE := { "low": 0.6, "medium": 0.85, "high": 1.0 } # how long they linger

# --- Sound ---
const SFX_VOICES := 24          # sounds in the world playing at once; the farthest gives way
const SFX_UI_VOICES := 6        # sounds with no position: menus, your own gun
const SFX_UNIT_SIZE := 6.0      # metres at which a sound is still at full volume
const SFX_MAX_DISTANCE := 120.0 # beyond this a sound is silent
const SFX_FAR_CUTOFF_HZ := 4000.0 # far sounds lose what is above this...
const SFX_FAR_CUTOFF_DB := -18.0  # ...by up to this much

# --- Physics layers (bit values) ---
const LAYER_WORLD := 1     # floors, walls, closed doors
const LAYER_PLAYER := 2
const LAYER_ZOMBIE := 4    # zombie movement capsules
const LAYER_HITBOX := 8    # per-body-part areas that bullets hit
const LAYER_INTERACT := 16 # things you can right-click
const LAYER_DEBRIS := 32   # gibs and ragdolls
