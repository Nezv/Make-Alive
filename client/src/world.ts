import * as THREE from 'three';
import { MAP_SIZE, type MapData } from '@zombie/shared';
import { createExtractionZone, createProp } from './models/props';
import { box } from './models/kit';

/** Lights, ground, fog and every static prop from the shared map data. */
export function buildWorld(scene: THREE.Scene, map: MapData, seed: number) {
  scene.background = new THREE.Color(0x1d2228);
  scene.fog = new THREE.Fog(0x1d2228, 15, 80);

  scene.add(new THREE.HemisphereLight(0x8899aa, 0x222018, 1.1));
  const moon = new THREE.DirectionalLight(0xaabbdd, 1.4);
  moon.position.set(30, 60, 20);
  moon.castShadow = true;
  moon.shadow.mapSize.set(2048, 2048);
  const s = moon.shadow.camera;
  s.left = s.bottom = -MAP_SIZE / 2;
  s.right = s.top = MAP_SIZE / 2;
  s.far = 150;
  scene.add(moon);

  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(MAP_SIZE + 40, MAP_SIZE + 40),
    new THREE.MeshStandardMaterial({ color: 0x2c2f2a, roughness: 1 }),
  );
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  // Perimeter fence (visual; collision is the map clamp).
  const h = MAP_SIZE / 2;
  for (const [x, z, w, d] of [[0, -h, MAP_SIZE, 0.3], [0, h, MAP_SIZE, 0.3], [-h, 0, 0.3, MAP_SIZE], [h, 0, 0.3, MAP_SIZE]]) {
    scene.add(box(w, 3, d, 0x444a44, [x, 1.5, z]));
  }

  map.boxes.forEach((b, i) => scene.add(createProp(b, seed + i)));

  const ex = createExtractionZone(map.extraction.r);
  ex.position.set(map.extraction.x, 0, map.extraction.z);
  scene.add(ex);
}
