import type { Box } from './map';
import { MAP_SIZE } from './map';

/** Push a circle (top-down XZ) out of every box and keep it inside the map. Height is ignored. */
export function pushOut(x: number, z: number, r: number, boxes: Box[]): [number, number] {
  for (const b of boxes) {
    const hx = b.w / 2;
    const hz = b.d / 2;
    const cx = Math.max(b.x - hx, Math.min(x, b.x + hx));
    const cz = Math.max(b.z - hz, Math.min(z, b.z + hz));
    const dx = x - cx;
    const dz = z - cz;
    const d2 = dx * dx + dz * dz;
    if (d2 >= r * r) continue;
    if (d2 > 1e-8) {
      const d = Math.sqrt(d2);
      x = cx + (dx / d) * r;
      z = cz + (dz / d) * r;
    } else {
      // Center is inside the box: exit along the shallowest axis.
      const px = hx - Math.abs(x - b.x) + r;
      const pz = hz - Math.abs(z - b.z) + r;
      if (px < pz) x += Math.sign(x - b.x || 1) * px;
      else z += Math.sign(z - b.z || 1) * pz;
    }
  }
  const lim = MAP_SIZE / 2 - r;
  return [Math.max(-lim, Math.min(lim, x)), Math.max(-lim, Math.min(lim, z))];
}

/** Distance along a normalized ray to a sphere, or -1 on miss. */
export function raySphere(
  o: readonly number[], d: readonly number[], c: readonly number[], r: number,
): number {
  const lx = c[0] - o[0], ly = c[1] - o[1], lz = c[2] - o[2];
  const t = lx * d[0] + ly * d[1] + lz * d[2];
  if (t < 0) return -1;
  const d2 = lx * lx + ly * ly + lz * lz - t * t;
  if (d2 > r * r) return -1;
  return t - Math.sqrt(r * r - d2);
}

/** Distance along a normalized ray to an axis-aligned box sitting on y=0, or -1 on miss. */
export function rayBox(o: readonly number[], d: readonly number[], b: Box): number {
  const min = [b.x - b.w / 2, 0, b.z - b.d / 2];
  const max = [b.x + b.w / 2, b.h, b.z + b.d / 2];
  let tmin = -Infinity, tmax = Infinity;
  for (let i = 0; i < 3; i++) {
    if (Math.abs(d[i]) < 1e-9) {
      if (o[i] < min[i] || o[i] > max[i]) return -1;
      continue;
    }
    let t1 = (min[i] - o[i]) / d[i];
    let t2 = (max[i] - o[i]) / d[i];
    if (t1 > t2) [t1, t2] = [t2, t1];
    tmin = Math.max(tmin, t1);
    tmax = Math.min(tmax, t2);
    if (tmin > tmax) return -1;
  }
  return tmax < 0 ? -1 : Math.max(tmin, 0);
}
