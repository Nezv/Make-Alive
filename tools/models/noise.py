"""Noise for the model painters (blood splats, dirt, mottled skin): smooth 3D value noise and its
fractal sum, deterministic from a seed, over arrays of points."""
import numpy as np


def _hash3(ix, iy, iz, seed):
    h = (ix * 73856093) ^ (iy * 19349663) ^ (iz * 83492791) ^ (seed * 2654435761)
    h = (h ^ (h >> 13)) * 1274126177
    h = h ^ (h >> 16)
    return (h & 0xFFFFFF).astype(np.float32) / float(0xFFFFFF)


def value_noise(P, freq, seed=0):
    """Smooth 3D value noise in 0..1 at `freq` cycles per metre."""
    q = P * freq
    i = np.floor(q).astype(np.int64)
    f = q - i
    u = f * f * (3.0 - 2.0 * f)
    out = np.zeros(len(P), dtype=np.float32)
    for dx in (0, 1):
        wx = u[:, 0] if dx else 1.0 - u[:, 0]
        for dy in (0, 1):
            wy = u[:, 1] if dy else 1.0 - u[:, 1]
            for dz in (0, 1):
                wz = u[:, 2] if dz else 1.0 - u[:, 2]
                out += wx * wy * wz * _hash3(i[:, 0] + dx, i[:, 1] + dy, i[:, 2] + dz, seed)
    return out


def fbm(P, freq, octaves=4, seed=0):
    """Fractal noise in about 0..1."""
    total = np.zeros(len(P), dtype=np.float32)
    amp = 0.5
    norm = 0.0
    for o in range(octaves):
        total += amp * value_noise(P, freq * (2.0 ** o), seed + o * 17)
        norm += amp
        amp *= 0.5
    return total / norm
