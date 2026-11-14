// Wire protocol. Every message is JSON with a `t` discriminator.
export type Vec3 = [number, number, number];

export interface PlayerState {
  id: string;
  name: string;
  pos: Vec3; // feet position
  yaw: number;
  pitch: number;
  hp: number;
  extract: number; // 0..1 extraction progress
  kills: number;
}

export interface ZombieState {
  id: number;
  pos: Vec3;
  yaw: number;
  hp: number;
}

export type ClientMsg =
  | { t: 'hello'; name: string }
  | { t: 'input'; pos: Vec3; yaw: number; pitch: number }
  | { t: 'shoot'; origin: Vec3; dir: Vec3 };

export type ServerMsg =
  | { t: 'welcome'; id: string; seed: number }
  | { t: 'snapshot'; players: PlayerState[]; zombies: ZombieState[] }
  | { t: 'respawn'; pos: Vec3; reason: 'spawn' | 'died' | 'extracted' }
  | { t: 'hit'; killed: boolean }
  | { t: 'feed'; text: string };
