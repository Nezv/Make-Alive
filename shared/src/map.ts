// Deterministic map layout: the server picks a seed, every client rebuilds the same map from it.
export const MAP_SIZE = 120; // square, centered on origin

export interface Box {
  x: number; // center
  z: number;
  w: number; // size along x
  d: number; // size along z
  h: number; // height
  kind: 'building' | 'crate' | 'car';
}

export interface MapData {
  boxes: Box[];
  extraction: { x: number; z: number; r: number };
  spawn: { x: number; z: number };
}

export function mulberry32(seed: number): () => number {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export function generateMap(seed: number): MapData {
  const rnd = mulberry32(seed);
  const half = MAP_SIZE / 2;
  const spawn = { x: 0, z: 0 };
  // Extraction sits in a random corner.
  const cx = rnd() < 0.5 ? -1 : 1;
  const cz = rnd() < 0.5 ? -1 : 1;
  const extraction = { x: cx * (half - 10), z: cz * (half - 10), r: 4 };

  const boxes: Box[] = [];
  const clear = (x: number, z: number, pad: number) =>
    Math.hypot(x - spawn.x, z - spawn.z) > 12 + pad &&
    Math.hypot(x - extraction.x, z - extraction.z) > extraction.r + 4 + pad;
  const overlaps = (b: Box) =>
    boxes.some(
      (o) => Math.abs(o.x - b.x) < (o.w + b.w) / 2 + 2 && Math.abs(o.z - b.z) < (o.d + b.d) / 2 + 2,
    );

  const place = (kind: Box['kind'], count: number, size: () => [number, number, number]) => {
    for (let i = 0, tries = 0; i < count && tries < count * 30; tries++) {
      const [w, d, h] = size();
      const b: Box = {
        x: (rnd() - 0.5) * (MAP_SIZE - w - 6),
        z: (rnd() - 0.5) * (MAP_SIZE - d - 6),
        w, d, h, kind,
      };
      if (!clear(b.x, b.z, Math.max(w, d) / 2) || overlaps(b)) continue;
      boxes.push(b);
      i++;
    }
  };

  place('building', 14, () => [8 + rnd() * 10, 8 + rnd() * 10, 4 + rnd() * 8]);
  place('car', 18, () => (rnd() < 0.5 ? [2, 4.2, 1.5] : [4.2, 2, 1.5]));
  place('crate', 40, () => {
    const s = 1 + rnd() * 0.6;
    return [s, s, s];
  });
  return { boxes, extraction, spawn };
}
