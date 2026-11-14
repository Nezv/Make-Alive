import * as THREE from 'three';

/**
 * Tiny toolkit for building low-poly models in code.
 * Convention: models stand on y=0, face -Z, 1 unit = 1 metre.
 */
const matCache = new Map<string, THREE.MeshStandardMaterial>();

export function mat(color: number, opts: { emissive?: number; rough?: number; metal?: number } = {}) {
  const key = `${color}|${opts.emissive ?? 0}|${opts.rough ?? 0.85}|${opts.metal ?? 0}`;
  let m = matCache.get(key);
  if (!m) {
    m = new THREE.MeshStandardMaterial({
      color,
      emissive: opts.emissive ?? 0,
      roughness: opts.rough ?? 0.85,
      metalness: opts.metal ?? 0,
      flatShading: true,
    });
    matCache.set(key, m);
  }
  return m;
}

export function box(w: number, h: number, d: number, color: number | THREE.Material, pos?: [number, number, number]) {
  const m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), typeof color === 'number' ? mat(color) : color);
  m.castShadow = true;
  m.receiveShadow = true;
  if (pos) m.position.set(...pos);
  return m;
}

export function cyl(rTop: number, rBot: number, h: number, color: number | THREE.Material, seg = 8) {
  const m = new THREE.Mesh(new THREE.CylinderGeometry(rTop, rBot, h, seg), typeof color === 'number' ? mat(color) : color);
  m.castShadow = true;
  m.receiveShadow = true;
  return m;
}

/** A pivot group at (x,y,z); children hang from it. Rotate the pivot to animate a joint. */
export function joint(parent: THREE.Object3D, x: number, y: number, z = 0) {
  const g = new THREE.Group();
  g.position.set(x, y, z);
  parent.add(g);
  return g;
}
