import { createHumanoid, type Rig } from './humanoid';
import { box } from './kit';

const ZOMBIE_SKINS = [0x6f8f5a, 0x7a9461, 0x5e7d58, 0x8a9a6a];
const ZOMBIE_SHIRTS = [0x4a3b2e, 0x3d4f63, 0x5a2a2a, 0x666655, 0x2f3a2f];
const ZOMBIE_PANTS = [0x2b2b3a, 0x3a3226, 0x223322];

const pick = <T,>(arr: T[], seed: number) => arr[Math.abs(seed) % arr.length];

/** Seeded so every client draws the same zombie for the same id. */
export function createZombie(id: number): Rig {
  const rig = createHumanoid({
    skin: pick(ZOMBIE_SKINS, id),
    shirt: pick(ZOMBIE_SHIRTS, id * 7),
    pants: pick(ZOMBIE_PANTS, id * 13),
    eyes: 0xff2200,
    hunch: 0.25,
    armsForward: true,
    scale: 0.95 + ((id * 37) % 10) / 50,
  });
  // A wound on the torso.
  rig.root.add(box(0.14, 0.12, 0.02, 0x5a0000, [0.1, 1.35, -0.21]));
  return rig;
}

const PLAYER_SHIRTS = [0x3366cc, 0xcc6633, 0x33aa77, 0xaa33aa, 0xcccc33, 0x33aacc];

export function createSurvivor(playerId: string): Rig {
  const n = [...playerId].reduce((a, c) => a + c.charCodeAt(0), 0);
  const rig = createHumanoid({ skin: 0xe0b48a, shirt: pick(PLAYER_SHIRTS, n), pants: 0x2d3a4a });
  // Backpack and gun so other players read as survivors.
  rig.root.add(box(0.36, 0.42, 0.18, 0x4a4030, [0, 1.25, 0.24]));
  rig.root.add(box(0.06, 0.1, 0.6, 0x222222, [0.3, 1.15, -0.35]));
  return rig;
}
