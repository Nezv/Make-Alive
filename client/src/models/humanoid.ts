import * as THREE from 'three';
import { box, joint, mat } from './kit';

export interface HumanoidStyle {
  skin: number;
  shirt: number;
  pants: number;
  shoes?: number;
  eyes?: number; // emissive eye colour, e.g. glowing zombie eyes
  hunch?: number; // forward lean in radians
  armsForward?: boolean; // classic zombie reach
  scale?: number;
}

export interface Rig {
  root: THREE.Group;
  /** Advance animation. speed = ground speed in m/s. */
  update(dt: number, speed: number): void;
}

/** Blocky humanoid with jointed arms/legs. About 1.8 m tall, faces -Z. */
export function createHumanoid(s: HumanoidStyle): Rig {
  const root = new THREE.Group();
  const body = joint(root, 0, 0.9); // hips
  body.rotation.x = s.hunch ?? 0;

  const torso = box(0.5, 0.62, 0.28, s.shirt, [0, 0.31, 0]);
  body.add(torso);

  const neck = joint(body, 0, 0.66);
  neck.add(box(0.3, 0.3, 0.3, s.skin, [0, 0.15, 0]));
  if (s.eyes !== undefined) {
    const eyeMat = mat(s.eyes, { emissive: s.eyes });
    neck.add(box(0.06, 0.04, 0.02, eyeMat, [-0.07, 0.18, -0.151]));
    neck.add(box(0.06, 0.04, 0.02, eyeMat, [0.07, 0.18, -0.151]));
  } else {
    neck.add(box(0.05, 0.05, 0.02, 0x111111, [-0.07, 0.18, -0.151]));
    neck.add(box(0.05, 0.05, 0.02, 0x111111, [0.07, 0.18, -0.151]));
  }

  const limb = (parent: THREE.Object3D, x: number, y: number, w: number, h: number, color: number, end?: number) => {
    const j = joint(parent, x, y);
    j.add(box(w, h, w + 0.02, color, [0, -h / 2, 0]));
    if (end !== undefined) j.add(box(w + 0.01, 0.1, w + 0.08, end, [0, -h + 0.05, -0.03]));
    return j;
  };
  const armL = limb(body, -0.33, 0.6, 0.14, 0.62, s.skin);
  const armR = limb(body, 0.33, 0.6, 0.14, 0.62, s.skin);
  // Sleeves
  armL.add(box(0.17, 0.25, 0.18, s.shirt, [0, -0.12, 0]));
  armR.add(box(0.17, 0.25, 0.18, s.shirt, [0, -0.12, 0]));
  const legL = limb(root, -0.12, 0.9, 0.18, 0.9, s.pants, s.shoes ?? 0x222222);
  const legR = limb(root, 0.12, 0.9, 0.18, 0.9, s.pants, s.shoes ?? 0x222222);

  if (s.scale) root.scale.setScalar(s.scale);

  let phase = Math.random() * 10;
  const reach = s.armsForward ? 1.35 : 0;
  return {
    root,
    update(dt, speed) {
      const amt = Math.min(speed / 3, 1);
      phase += dt * (2 + speed * 2.2);
      const swing = Math.sin(phase) * 0.75 * amt;
      legL.rotation.x = swing;
      legR.rotation.x = -swing;
      if (s.armsForward) {
        const sway = Math.sin(phase * 0.5) * 0.12;
        armL.rotation.x = reach + sway;
        armR.rotation.x = reach - sway;
        neck.rotation.z = Math.sin(phase * 0.3) * 0.15;
      } else {
        armL.rotation.x = -swing * 0.8;
        armR.rotation.x = swing * 0.8;
      }
      body.position.y = 0.9 + Math.abs(Math.sin(phase)) * 0.04 * amt;
    },
  };
}
