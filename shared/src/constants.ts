// Gameplay tuning shared by client and server. Change numbers here, not inline.
export const PORT = 3000;
export const TICK_RATE = 20; // server simulation + snapshot rate (Hz)

export const PLAYER_HP = 100;
export const PLAYER_RADIUS = 0.4;
export const PLAYER_EYE_HEIGHT = 1.65;
export const WALK_SPEED = 5;
export const SPRINT_SPEED = 8;

export const ZOMBIE_MAX = 24;
export const ZOMBIE_HP = 100;
export const ZOMBIE_SPEED = 2.4;
export const ZOMBIE_RADIUS = 0.4;
export const ZOMBIE_DAMAGE = 15;
export const ZOMBIE_ATTACK_RANGE = 1.3;
export const ZOMBIE_ATTACK_COOLDOWN = 1.0; // s
export const ZOMBIE_AGGRO_RANGE = 45;
export const ZOMBIE_SPAWN_INTERVAL = 1.5; // s

export const WEAPON_DAMAGE = 34;
export const WEAPON_FIRE_INTERVAL = 0.12; // s
export const WEAPON_RANGE = 120;

export const EXTRACT_TIME = 5; // seconds standing in the zone
