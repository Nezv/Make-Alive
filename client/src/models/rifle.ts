import * as THREE from 'three';
import { box, cyl, mat } from './kit';

/** First-person rifle. Attach to the camera; barrel points -Z. */
export function createRifle() {
  const g = new THREE.Group();
  const metal = mat(0x2a2c30, { rough: 0.4, metal: 0.6 });
  const wood = mat(0x5a3b22);
  g.add(box(0.07, 0.1, 0.45, metal, [0, 0, 0]));       // receiver
  g.add(box(0.06, 0.12, 0.22, wood, [0, -0.02, 0.32]));  // stock
  g.add(box(0.05, 0.14, 0.06, metal, [0, -0.1, -0.05])); // magazine
  g.add(box(0.04, 0.08, 0.05, wood, [0, -0.08, 0.1]));   // grip
  g.add(box(0.03, 0.04, 0.12, metal, [0, 0.07, -0.05])); // sight
  const barrel = cyl(0.018, 0.018, 0.4, metal);
  barrel.rotation.x = Math.PI / 2;
  barrel.position.set(0, 0.01, -0.42);
  g.add(barrel);
  g.traverse((o) => { o.castShadow = false; });

  const flash = new THREE.Mesh(
    new THREE.SphereGeometry(0.06, 6, 4),
    new THREE.MeshBasicMaterial({ color: 0xffcc55 }),
  );
  flash.position.set(0, 0.01, -0.66);
  flash.visible = false;
  g.add(flash);
  const light = new THREE.PointLight(0xffaa33, 0, 8);
  light.position.copy(flash.position);
  g.add(light);

  const rest = new THREE.Vector3(0.22, -0.22, -0.4);
  g.position.copy(rest);
  let kick = 0;
  let bob = 0;
  return {
    object: g,
    fire() {
      kick = 1;
    },
    update(dt: number, moveSpeed: number) {
      kick = Math.max(0, kick - dt * 12);
      bob += dt * moveSpeed * 1.6;
      const b = Math.min(moveSpeed / 5, 1);
      g.position.set(
        rest.x + Math.cos(bob) * 0.012 * b,
        rest.y + Math.abs(Math.sin(bob)) * 0.015 * b,
        rest.z + kick * 0.06,
      );
      g.rotation.x = kick * 0.12;
      flash.visible = kick > 0.6;
      flash.scale.setScalar(0.7 + Math.random() * 0.6);
      light.intensity = kick > 0.6 ? 4 : 0;
    },
  };
}
