import * as THREE from 'three';
import type { Box } from '@zombie/shared';
import { mulberry32 } from '@zombie/shared';
import { box, cyl, mat } from './kit';

/** Build the visual for a collision box from the map. The visual must stay inside the box. */
export function createProp(b: Box, seed: number): THREE.Object3D {
  const rnd = mulberry32(seed);
  if (b.kind === 'building') return building(b, rnd);
  if (b.kind === 'car') return car(b, rnd);
  return crate(b);
}

function building(b: Box, rnd: () => number) {
  const g = new THREE.Group();
  const walls = [0x6b6560, 0x7a6f62, 0x5f6670, 0x857b6e][Math.floor(rnd() * 4)];
  g.add(box(b.w, b.h, b.d, walls, [0, b.h / 2, 0]));
  g.add(box(b.w + 0.3, 0.3, b.d + 0.3, 0x3a3633, [0, b.h + 0.15, 0])); // roof lip
  // Dark windows on each face.
  const win = mat(0x1a1d22, { rough: 0.3 });
  const glow = mat(0xffcc66, { emissive: 0x996622 });
  const floors = Math.max(1, Math.floor(b.h / 3));
  for (let f = 0; f < floors; f++) {
    const y = 1.8 + f * 3;
    for (const [axis, len, depth] of [['x', b.w, b.d], ['z', b.d, b.w]] as const) {
      const n = Math.floor(len / 3);
      for (let i = 0; i < n; i++) {
        const off = -len / 2 + (i + 0.5) * (len / n);
        for (const side of [-1, 1]) {
          const m = rnd() < 0.08 ? glow : win;
          const w = axis === 'x' ? box(1.2, 1.4, 0.05, m) : box(0.05, 1.4, 1.2, m);
          if (axis === 'x') w.position.set(off, y, side * (depth / 2 + 0.01));
          else w.position.set(side * (depth / 2 + 0.01), y, off);
          w.castShadow = false;
          g.add(w);
        }
      }
    }
  }
  g.position.set(b.x, 0, b.z);
  return g;
}

function car(b: Box, rnd: () => number) {
  const g = new THREE.Group();
  const long = b.d > b.w; // oriented along z
  const L = Math.max(b.w, b.d), W = Math.min(b.w, b.d);
  const paint = [0x8a2020, 0x204a8a, 0xb0b0b0, 0x2a2a2a, 0x6a6a20][Math.floor(rnd() * 5)];
  const body = new THREE.Group();
  body.add(box(W, 0.6, L, mat(paint, { rough: 0.5, metal: 0.3 }), [0, 0.55, 0]));
  body.add(box(W * 0.9, 0.5, L * 0.5, paint, [0, 1.1, 0.1]));
  body.add(box(W * 0.85, 0.42, 0.05, mat(0x223344, { rough: 0.2 }), [0, 1.1, 0.1 - L * 0.25 - 0.03])); // windshield
  for (const x of [-1, 1]) for (const z of [-1, 1]) {
    const wheel = cyl(0.33, 0.33, 0.22, 0x111111, 10);
    wheel.rotation.z = Math.PI / 2;
    wheel.position.set(x * (W / 2 - 0.08), 0.33, z * (L / 2 - 0.7));
    body.add(wheel);
  }
  if (!long) body.rotation.y = Math.PI / 2;
  body.rotation.y += (rnd() - 0.5) * 0.15; // abandoned at an angle
  g.add(body);
  g.position.set(b.x, 0, b.z);
  return g;
}

function crate(b: Box) {
  const g = new THREE.Group();
  g.add(box(b.w, b.h, b.d, 0x8b6a3e, [0, b.h / 2, 0]));
  const trim = mat(0x5c4426);
  for (const y of [0.05, b.h - 0.05]) {
    g.add(box(b.w + 0.02, 0.1, b.d + 0.02, trim, [0, y, 0]));
  }
  g.position.set(b.x, 0, b.z);
  return g;
}

/** Glowing beam marking the extraction zone. */
export function createExtractionZone(r: number) {
  const g = new THREE.Group();
  const ring = new THREE.Mesh(
    new THREE.RingGeometry(r - 0.25, r, 48),
    new THREE.MeshBasicMaterial({ color: 0x44ff88, side: THREE.DoubleSide }),
  );
  ring.rotation.x = -Math.PI / 2;
  ring.position.y = 0.03;
  g.add(ring);
  const beam = new THREE.Mesh(
    new THREE.CylinderGeometry(r * 0.3, r * 0.6, 60, 24, 1, true),
    new THREE.MeshBasicMaterial({ color: 0x44ff88, transparent: true, opacity: 0.18, depthWrite: false, side: THREE.DoubleSide }),
  );
  beam.position.y = 30;
  g.add(beam);
  const light = new THREE.PointLight(0x44ff88, 30, 20);
  light.position.y = 2;
  g.add(light);
  return g;
}
