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
const SHOVE_TIME := 0.35         # seconds a shove takes, start to settled
const SHOVE_STAMINA := 15.0
const SHOVE_RANGE := 1.8         # metres from the eyes
const SHOVE_CONE := 0.7          # radians either side of where you look
const SHOVE_PUSH := 4.0          # m/s a shoved zombie is sent back at...
const SHOVE_PUSH_DECAY := 10.0   # ...losing this much a second
const SHOVE_DAMAGE := 10
const SHOVE_LEAP_RESET := 2.5    # seconds a shoved leaper must wait before it can wind up again
const SHOVE_NUDGE := Vector2(-0.025, 0.012) # the view's jolt when a shove lands
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
const BANDAGE_HEAL := 10        # HP a bandage gives back when it is on (it also stops the bleeding)
const BLEED_CHANCE := 0.35      # a zombie's hit opens a wound when the roll is under this
const BLEED_MAX := 3            # wounds at once
const BLEED_INTERVAL := 2.0     # seconds between bleeding ticks
const BLEED_DAMAGE := 1         # HP per wound per tick
const BLEED_DRIP_STEP := 0.9    # metres a bleeding player walks between drops on the floor (every peer draws them)
const BLEED_DRIP_IDLE := 1.2    # seconds between drops when they stand still
const BLEED_DRIP_SIZE := 0.16   # metres across a drop
const BLEED_SCREEN_DROPS := 4   # drops running up the bottom of your screen per wound
const HEAL_LOWER_TIME := 0.2    # seconds the gun takes to go down for a heal (and come back)
const HEAL_POSE_TIME := 0.32    # seconds per pose of the hands wrapping a bandage (four, round and round)
const HEARTBEAT_SLOW := 1.1     # seconds between beats at the low-HP line
const HEARTBEAT_FAST := 0.5     # ... and at death's door
const PAINKILLERS_TEMP := 30    # temporary HP a dose gives (not stacking)...
const PAINKILLERS_DECAY := 2.0  # ...worn off at this many HP a second
const PAINKILLERS_REUSE := 0.5  # no new dose while this share of the last is still there
const DOWNED_TIME := 30.0       # seconds a downed player lasts without help
const DOWNED_DAMAGE_SECONDS := 0.5 # seconds of that lost for every HP of damage a downed player takes
const DOWNED_SPEED := 1.0       # m/s: a crawl
const DOWNED_FINISH_RANGE := 12.0 # zombies this close to a downed player finish them unless someone standing is as close
const REVIVE_SECONDS := 4.0     # holding use beside a downed teammate this long gets them up
const REVIVE_RANGE := 2.0       # metres (the host allows a little more for lag)
const REVIVE_HP := 30           # what they get up with
const REVIVE_INVULN := 2.0      # seconds nothing can hurt them after
const DOWNED_EYE := 0.45        # metres: a downed player's eyes, near the floor
const DOWNED_ROLL := 0.3        # radians the downed view tilts
const DOWNED_FALL_TIME := 0.6   # seconds going down takes (camera and body)
const GETUP_TIME := 1.0         # seconds getting back up takes
const DOWNED_GREY_MIN := 0.35   # how grey the screen is the moment you go down (up to 0.9 as you bleed out)
const REACH_RANGE := 4.0        # metres: a downed player reaches out to a standing teammate this close
const FEED_RANGE := 15.0        # metres: zombies this close to a player who dies go to feed on the body
const FEED_TIME := 25.0         # seconds they keep at it (unless someone alive comes within ZOMBIE_NOTICE_RANGE)
const ARRIVE_DROP := 0.9        # metres the view drops coming back (off a truck bed)
const ARRIVE_TIME := 0.45       # seconds the drop takes
const CHAT_MAX_CHARS := 120     # a chat line is cut to this
const CHAT_LINES := 8           # chat lines kept on screen
const CHAT_SHOW := 15.0         # seconds a chat line stays
const PING_TIME := 8.0          # seconds a ping marks its spot
const PING_REACH := 80.0        # metres along the view a ping looks for something to mark

# --- Muzzle flash and smoke (scripts/fx/muzzle_flash.gd, viewmodel.gd) ---
const MUZZLE_FLASH_TIME := 0.03  # seconds the flash shows: a frame or two
const MUZZLE_LIGHT_TIME := 0.05  # seconds the warm light lasts
const MUZZLE_LIGHT_COLOR := Color(1.0, 0.6, 0.25)
const MUZZLE_LIGHT_RANGE := 6.0
const MUZZLE_LIGHT_ENERGY := 3.5
const MUZZLE_SMOKE_LIFE := 0.8   # seconds a puff lives
const MUZZLE_WIND := Vector3(0.5, 0.0, 0.2) # how the puffs drift
const HEAT_SHOTS := 12           # shots close together that make a barrel hot
const HEAT_COOL := 2.5           # shots' worth of heat lost a second
const HEAT_WISP_TIME := 2.0      # seconds a hot barrel shimmers and smokes after the burst
const HEAT_WISP_EVERY := 0.12    # seconds between the wisp's puffs

# --- Tracers and the whiz (scripts/fx/tracers.gd) ---
const TRACER_SPEED := 400.0      # m/s the streak runs at
const TRACER_LENGTH := 40.0      # metres long
const TRACER_WIDTH := 0.025
const TRACER_MAX := 96           # streaks at once (the oldest gives way)
const TRACER_OWN_EVERY := 3      # your own gun shows one every this many shots (a clean view)
const TRACER_SHOTGUN_REACH := 40.0 # metres a shotgun's fan runs at most
const VAPOUR_TIME := 0.6         # seconds a sniper shot's vapour line hangs
const VAPOUR_MAX := 6
const VAPOUR_SEGS := 12
const VAPOUR_WOBBLE := 0.25      # metres it drifts apart by the end
const WHIZ_RADIUS := 1.5         # metres from your head a teammate's bullet whizzes
const WHIZ_FLINCH := 0.012       # radians the view twitches

# --- Spent casings (scripts/fx/casings.gd) ---
const CASING_MAX := 160          # lying about at once (the oldest gives way)
const CASING_REST := 20.0        # seconds one lies still before it sinks
const CASING_SINK := 2.0         # seconds it takes to sink away

# --- Gun voices (scripts/gun_voice.gd) ---
const SHOT_FAR_DIST := 60.0      # metres beyond which you hear the far version (the crack gone)
const SHOT_PITCH_VARY := 0.04    # each shot up to this much higher or lower
const SHOT_DB_VARY := 1.5        # ...and this many dB louder or softer
const TAIL_DB := 5.0             # the room's answer is this much quieter than the shot
const HILL_OPEN_Y := 40.0        # metres up the hill where a shot rings out in the open

# --- Handling (viewmodel.gd) ---
const INSPECT_TIME := 2.2        # seconds looking the gun over takes
const HANDLING_DB := -6.0        # how loud magazines, bolts, pumps and slings are
const LOW_AMMO_ROUNDS := 3       # this few left in a magazine and each shot sounds thinner, with a click

# --- Camera feel (scripts/camera_feel.gd) ---
const CAM_BOB_RATE := TAU / WALK_SPEED # phase per metre: a step every half turn, two a second at a walk
const CAM_BOB_X := 0.018         # metres side to side
const CAM_BOB_Y := 0.022         # metres up and down
const CAM_BOB_SPRINT := 1.6      # how much bigger sprinting is
const CAM_SWAY_GAIN := 0.012     # how hard a mouse movement swings the gun back
const CAM_SWAY_K := 120.0        # its spring
const CAM_SWAY_D := 17.0         # and damping
const CAM_SWAY_MAX := 0.08       # radians at most
const CAM_TILT := 0.026          # radians of lean into a strafe (1.5 degrees)
const CAM_SPRINT_FOV := 4.0      # degrees wider while sprinting
const CAM_PINCH := -6.0          # degrees a sniper shot pinches the view
const CAM_SHAKE_MAX := 0.06      # metres: every shake together never more than this
const CAM_SHAKES_MAX := 8
const CAM_SHAKE_HIT := 0.025     # a hit taken
const CAM_SHAKE_BLAST := 0.06    # an explosion right beside you
const CAM_SHAKE_BLAST_RADIUS := 25.0
const CAM_SHAKE_LEAP := 0.03     # a leaper landing near
const CAM_SHAKE_LEAP_RADIUS := 8.0
const RECOIL_IMPULSE := 30.0     # the kick's spring: how fast it climbs
const RECOIL_K := 400.0          # how hard it pulls back
const RECOIL_D := 22.0           # damping (a little past the rest before it settles)

# --- HUD 2 (hud.gd and its parts) ---
const HUD_PIP_MAX := 40          # magazines this big or smaller show a pip a round, bigger a number
const HUD_TYPE_RATE := 40.0      # letters a second the objective types in at
const HUD_OBJECTIVE_OUT := 0.6   # seconds the old objective takes to slide away
const HUD_OBJECTIVE_SLIDE := 24.0 # pixels it slides up
const HUD_EDGE := 48.0           # pixels in from the edge a marker waits when off screen
const HUD_OUTLINE_DIST := 25.0   # metres beyond which a teammate is outlined through walls
const HUD_FADE_AFTER := 4.0      # seconds unchanged before a part fades
const HUD_FADED := 0.35          # how faded

# --- Hit feedback ---
const HIT_MARKER_TIME := 0.3     # seconds the ticks stay
const HIT_MARKER_SIZE := 8.0     # pixels long
const DAMAGE_ARC_TIME := 1.0     # seconds the arc showing where a hit came from fades over
const HIT_PUNCH := 1.4           # how hard a hit turns the view away (recoil-spring speed)
const MUFFLE_TIME := 0.5         # seconds the world sounds dull after a hit
const MUFFLE_CUTOFF := 700.0     # Hz at its dullest
const LENS_DIST := 3.0           # metres: a kill this close leaves blood on the lens
const LENS_BLOOD_TIME := 3.0     # seconds it takes to run off

# --- Other players' animations ---
const THROW_ANIM_TIME := 0.7     # seconds a throw shows on others (wind-up, release)
const REMOTE_KICK_DECAY := 8.0   # how fast a shot's kick on another player's gun settles
const DEATH_PUSH := 2.5          # how hard the last blow throws a dying player's body

# --- The helicopter (scripts/heli_flight.gd is its path; scripts/world/helicopter.gd its look) ---
const HELI_MAX_MESHES := 12      # draws for the whole machine
const HELI_BLUR_AT := 0.6        # rotor speed (0..1) above which the blades show as a disc
const HELI_ROTOR_RPS := 4.5      # main rotor turns a second at full speed
const HELI_WASH_HEIGHT := 14.0   # metres above the ground below which its downwash kicks up dust
const HELI_WASH_RADIUS := 16.0   # metres round it the dust and the view shake reach
const HELI_WASH_EVERY := 0.12    # seconds between dust rings
const HELI_WASH_SHAKE := 0.04    # metres the view trembles right under it
const HELI_GUNNER_RANGE := 45.0  # metres the door gunner reaches
const HELI_GUNNER_INTERVAL := 0.35 # seconds between his shots
const HELI_GUNNER_DAMAGE := 34
const HELI_GUNNER_ALT := 15.0    # he fires once it is this low
const HELI_BOARD_RADIUS := 2.2   # metres from the side door that count as aboard
const SPECTATE_BACK := 3.2      # metres behind the player being followed...
const SPECTATE_HEIGHT := 1.9    # ...and above their feet
const SPECTATE_SMOOTH := 5.0    # how fast the spectator camera catches up (per second)
const SPECTATE_ORBIT_RADIUS := 4.5 # with nobody to follow: round the body at this distance...
const SPECTATE_ORBIT_HEIGHT := 3.0 # ...this high...
const SPECTATE_ORBIT_SPEED := 0.25 # ...this many radians a second
const THROWABLE_SLOTS := 2      # different kinds of throwable carried at once
const WHEEL_WEDGES := 8         # the item wheel (hold the key, move the mouse, let go)
const WHEEL_RADIUS := 120.0     # pixels the pointer can travel from the middle
const WHEEL_DEAD_ZONE := 30.0   # closer than this to the middle picks nothing
const WHEEL_HOP_TIME := 0.12    # seconds the lit wedge's icon takes to hop up (and to sink back)
const WHEEL_HOP_SCALE := 0.25   # how much bigger the lit icon is once up
const WHEEL_HOP_LIFT := 10.0    # pixels it jumps outward in the middle of the hop
const BACKPACKS_MAX := 8        # dead players' backpacks lying around at once; the oldest goes first
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
const BITE_SHARE := 0.4         # share of a crowd that carries a bite (Characters.bite_for): a hole torn in clothes and flesh
const ZOMBIE_NOTICE_RANGE := 15.0 # a player this close beats any noise: the zombie goes for them
const FRIENDLY_FIRE_MULT := 0.5 # share of a bullet's damage a teammate takes (nightmare only)
const WAVE_GAP := 15.0          # seconds of calm before a defended wave, unless the wave says otherwise
const WAVE_PER_PLAYER := 0.35   # each living player beyond the first makes a wave this much bigger
const LAST_WAVE_TOPUP := 2.0    # seconds between top-ups of the endless last wave while the helicopter comes
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
const RUNNER_SHARE := 0.25    # of the usual mix (Difficulty scales it)
const LEAPER_SHARE := 0.15
## Pacing (scripts/horde_director.gd): stress 0..1 decides how fast the next horde builds up and when the breather ends.
const STRESS_PER_HP := 0.012    # added for every HP of damage a player takes
const STRESS_NEAR := 8.0        # metres: a zombie this close to a living player...
const STRESS_PER_ZOMBIE := 0.04 # ...adds this much a second
const STRESS_AMMO_LOW := 10     # reserve rounds of the held gun's calibre under which ammo adds stress (limited-ammo maps)
const STRESS_AMMO_RATE := 0.03  # a second, per player short of ammo
const STRESS_DECAY := 0.06      # lost every second
const STRESS_CALM := 0.25       # at or under this the players have calmed down
const CALM_TIME := 6.0          # the quiet at least this long, then the build-up
const BUILD_RATE_CALM := 1.4    # the build-up's clock runs at this speed when stress is 0...
const BUILD_RATE_STRESSED := 0.4 # ...and this at full stress
const PEAK_MIN := 10.0          # a peak lasts at least this long...
const PEAK_MAX := 45.0          # ...at most this long...
const PEAK_END_ALIVE := 0.25    # ...and ends once this share of its horde (or less) is left alive
const RELAX_MIN := 10.0         # the breather after a peak, at least this long
const HORDE_STREAM_GAP := 0.3   # seconds between one zombie of a horde and the next out of its closet
const ROUTE_ARRIVE := 2.0       # metres from a route point at which a zombie moves on to the next
## Most of a type alive at once (the others are not limited). Specials go here as they are added.
const SPECIAL_BUDGET := { Zombie.Type.LEAPER: 3 }
const STRAGGLER_DIST := 40.0    # a zombie this far from every living player...
const STRAGGLER_TIME := 20.0    # ...for this long has lost them: it is moved up to a closet ahead
const STRAGGLER_CHECK := 1.0    # seconds between checks for stragglers

# --- World ---
const WEAPON_SPOTS_ACTIVE := 8 # how many of a map's weapon spots hold a gun each match
const SPAWN_MIN_DIST := 18.0  # zombies never appear closer to a player than this (open maps)
const DIRECT_CHECK_RANGE := 14.0 # open maps: beyond this a zombie just follows its path
const CITY_CELL := 4.0        # metres per cell of the city's layout / navigation grid
const CITY_FLOOR_H := 3.2
const CITY_WALL_H := 4.0      # the wall where the map ends
const CITY_SPAWN_NEAR := 30.0 # city zombies appear between these distances from a player
const CITY_SPAWN_FAR := 70.0
const CITY_SPAWN_TRIES := 40
const CITY_HILL_FADE := 100.0  # metres over which Morro da Boa Vista rises from the flat city at the forest's edge

# --- City blocks (S043, scripts/world/city_blocks.gd; the classes' numbers are CityBlocks.CLASSES) ---
const CITY_BLOCK_SIMPLIFY := 3.0   # metres an îlot's outline may stray from the 4 m grid's staircase
const CITY_BAY := Vector2(2.3, 2.8) # metres: a window bay, the unit a house's width is counted in
const CITY_STOREY := Vector2(2.9, 3.4) # metres per floor, seeded per house (the cornice line steps)
const CITY_CORE_RADIUS := 400.0    # metres round the place du Marché and the place de l'Église: the old core
const CITY_FAUBOURG := 1150.0      # metres from the place du Marché beyond which is the edge of town
const CITY_POSTWAR_NEAR := Vector2(200.0, 120.0) # metres round the hospital and round the bus station that were rebuilt after the war
const CITY_MARCHE_KEEP := 150.0    # metres round the place du Marché kept old: tall plastered houses close it, not slabs
const CITY_POSTWAR_EDGE := 0.1     # share of the îlots at the edge of town that are post-war blocks
const CITY_ATELIER_RIVER := 70.0   # metres from the river within which a row may be ateliers
const CITY_ATELIER_SHARE := 0.7    # ...and the share of those rows that are
const CITY_HOTEL_SHARE := 0.08     # chance a long row in the centre has an hôtel particulier behind a gate
const CITY_HOTEL_ROW := 34.0       # metres of row an hôtel needs, and twice its depth inside the block
const CITY_STRAIGHT_DEG := 25.0    # an outline turning less than this at a point runs straight on
const CITY_ILOT_SMALL := 150.0     # m²: an îlot smaller than this is one building
const CITY_BACK_MIN := 60.0        # m²: a traced footprint smaller than this is a shed, not built
const CITY_HALL_AREA := 1200.0     # m²: a traced footprint larger than this is a hall
const CITY_LIT_SHARE := 0.1        # houses with a window still lit
const CITY_BLOCK_TRIANGLES := 1500000 # the whole town's walls and roofs
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
	"city": { "meshes": 16, "surfaces": 16, "lights": 14, "shadow_lights": 2, "shapes": 48000, "worst_view": 14 }, # shapes: the whole of joinville.png is built until the performance pass decides what stays in detail
}
const BUDGET_HOST_TICK_MS := 16.6  # the host's tick with ZOMBIE_MAX zombies must fit one 60 Hz frame
const PROTOCOL_VERSION := 6   # bump when anything on the wire changes: a client of another build is refused with a message
const PACKET_OVERHEAD := 64    # what the RPC itself and the player block's framing take of a snapshot packet
const INTEREST_NEAR_SHARE := 0.7 # over budget: this share of the packet is the zombies nearest the client, every tick
const INTEREST_FAR_TICKS := 6  # ...and the rest of them are sent in turn, each at least this often
const INTEREST_RANGE := 160.0  # metres from the client beyond which a zombie is not sent (positions are 327 m around the first one)
const ZOMBIE_STALE := 1.0      # seconds a client keeps a zombie that missed the snapshots before it takes it for gone
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
const SCORE_TICK_TIME := 1.5      # seconds the end screen's counters take to tick up
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
const SOUND_SPOTS_MAX := 64       # hums, alarms and ticks placed in a map; more stay silent
const SOUND_SPOTS_AUDIBLE := 6    # of those, only the nearest this many play at once
const SOUND_SPOT_REACH := 30.0    # metres a placed hum is heard from (a spot can say its own)
const WORLD_SOUND_JITTER := 0.05  # pitch spread of a world sound the host sends
const DOOR_SOUND_DB := -2.0       # a door opening, closing, being bashed
const PICKUP_SOUND_DB := -6.0     # ammo, a medkit, keys going into your kit
const TUBE_BUZZ_DB := -16.0       # a lamp's hum, quiet: you hear it standing under it

# --- Physics layers (bit values) ---
const LAYER_WORLD := 1     # floors, walls, closed doors
const LAYER_PLAYER := 2
const LAYER_ZOMBIE := 4    # zombie movement capsules
const LAYER_HITBOX := 8    # per-body-part areas that bullets hit
const LAYER_INTERACT := 16 # things you can right-click
const LAYER_DEBRIS := 32   # gibs and ragdolls

# --- Sky and time of day (S050: TimeOfDay, SkyDome, SkyShader) ---
const VIEW_FAR := 1200.0           # metres: the player's far plane; the sky's backdrop goes on past it
const SKY_FOG_HIDES := 0.4         # at least this much of the far plane is hidden by fog in every preset (the backdrop does the rest)
const SKY_UPDATE := 0.12           # seconds between the sky shader's updates (clouds, stars, where the camera is)
const SKY_SEED := 1800             # the sky's own dice (lightning, the fires' places)
const SKY_SHADOW_DISTANCE := 60.0  # metres of sun shadows, by day and at dusk
const SKY_CLOUD_SPEED := 0.012     # cloud drift in the shader's units per second at wind 1
const SKY_FLASH_TIME := 0.35       # seconds a lightning strike flickers
const SKY_FLASH_LIGHT := 1.2       # extra light energy at a strike's brightest
const SKY_PROFILE_SIZE := 512      # azimuths in the backdrop's horizon profile
const SKY_PROFILE_MOVE := 40.0     # metres the camera moves before the profile is worked out again
const SKY_PROFILE_SLICE := 32      # azimuths worked out per frame meanwhile
const SKY_PROFILE_REACH := 6000.0  # metres the profile looks out to
const SKY_PROFILE_STEP := 12.0     # metres between its samples near the far plane (wider further out)
const SKY_CANOPY := 14.0           # metres of forest crown over the hill's ground
const SKY_ROOF_HEIGHT := 16.0      # metres: the far roofscape's ridge line
const SKY_SMOKE_COLUMNS := 3       # fires burning somewhere in town (the shader holds 4 at most)

# --- House interiors (S244: HousePlan, HouseFloor, RoomDressing, InteriorBuilder) ---
# Passages are counted in the player's own size, so a corridor is always one the capsule walks down.
const INTERIOR_CORRIDOR := PLAYER_RADIUS * 3.0      # 1.2 m: the narrowest corridor, passage or allée
const INTERIOR_CORRIDOR_SLACK := PLAYER_RADIUS * 0.75 # up to this much wider, seeded per floor
const INTERIOR_HALL := PLAYER_RADIUS * 4.5          # 1.8 m: wider than this a corridor is an entrée (a hall: furniture may stand in it)
const INTERIOR_DOOR := PLAYER_RADIUS * 2.25         # 0.9 m: a door's clear width
const INTERIOR_DOOR_HEIGHT := PLAYER_HEIGHT + 0.25  # 2.05 m
const INTERIOR_STREET_DOOR := Vector2(1.2, 2.6)     # m: the porte d'entrée, width and height
const INTERIOR_SHOP_DOOR := Vector2(1.0, 2.4)
const INTERIOR_COURT_DOOR := Vector2(1.0, 2.2)
const INTERIOR_JAMB := 0.12                         # m of wall at least each side of a door
const INTERIOR_ROOM_MIN := PLAYER_RADIUS * 5.5      # 2.2 m: a room's narrowest side
const INTERIOR_CLOSET_MIN := PLAYER_RADIUS * 3.0    # 1.2 m: a WC's, a box room's
const INTERIOR_WET_MAX := 2.2                       # m: a WC or salle d'eau carved off a room is at most this wide
const INTERIOR_BAND_MIN := 3.0                      # m: the shallowest band of rooms between the facade and the refend
const INTERIOR_BAND_MAX := 6.4                      # m: the deepest front band
const INTERIOR_PASS := PLAYER_RADIUS * 0.9          # 0.36 m: half the narrowest gap between furniture the player squeezes through
const INTERIOR_FACADE := 0.5    # m: the street and court walls (rubble stone under plaster)
const INTERIOR_PARTY := 0.2     # m: this house's half of a party wall
const INTERIOR_REFEND := 0.25   # m: the load-bearing wall across the house (mur de refend)
const INTERIOR_CAGE_WALL := 0.2 # m: the stair's own walls
const INTERIOR_PARTITION := 0.1 # m: a cloison
const INTERIOR_SLAB := 0.25     # m: a floor's thickness, joists and boards
const INTERIOR_RISER_MAX := 0.18 # m: the highest riser
const INTERIOR_TREAD := 0.27    # m: a step's depth
const INTERIOR_FLIGHT := PLAYER_RADIUS * 2.5        # 1.0 m: a flight's width
const INTERIOR_LANDING := PLAYER_RADIUS * 3.25      # 1.3 m: the landings' depth (the flat's door and the corridor's first doorway side by side)
const INTERIOR_WELL := 0.1      # m: the gap between the two flights at least
const INTERIOR_WINDOW := Vector3(1.3, 0.12, 2.55)   # the upper floors' French windows: width, sill, head (m over the floor)
const INTERIOR_CASEMENT := Vector3(1.0, 0.9, 2.25)  # the court's windows
const INTERIOR_SHOP_WINDOW := Vector3(1.7, 0.45, 2.6) # a shop's windows (as wide as the bay allows)
const INTERIOR_ENFILADE := 0.6  # chance two living rooms along the street open into each other as well
const INTERIOR_ALIGN := 0.35    # m: a partition this close to a wall of the band behind it lines up with it
const INTERIOR_STACK := 0.6     # chance a floor keeps a partition of the floor below
const INTERIOR_LIGHT_STEP := 3.2 # m between a corridor's lamps
const INTERIOR_LIGHT_BIG := 17.0 # m²: a room larger than this, or long, has two lamps
const INTERIOR_SWITCH := 1.1    # m: a light switch's height
const INTERIOR_GRID := 0.1      # m: the cells furniture's way-through check works in
const INTERIOR_TRIES := 16      # layouts tried per floor before giving up
