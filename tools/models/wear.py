"""The detail kit's wear and damage (S141), painted per texel from the bake (position, normal,
ambient occlusion, edges, the face's tag and unit). `props.paint` runs these in order for each
state; a family may call them from its own `extra` too.

    Wear:   chips (paint off the edges and in patches, to the primer, then the bare stuff),
            sun fade, rust (on bare metal, and running down from fixings), water stains (running
            down from sills, ledges and joints), grime in cavities and joints, dirt splashed up
            at the foot, moss and algae (shaded, low, damp faces), plaster fallen off the wall,
            posters and graffiti (decals placed by the element: `spec["decals"]`)
    Damage: bullet pocks by material (a crater in stone, a bright ring on metal, a star in
            glass, splinters in wood), cracks in glass round its holes, and a burnt version of
            every kind of material (paint blistered off, wood charred in cracks, masonry and
            glass sooted, paper burnt away, soot plumes over the openings fire came out of)

Every layer is deterministic (noise seeded by position, `surfaces._hash` by unit).
"""
import numpy as np

import lettering
from noise import fbm_round as fbm
from surfaces import _hash

POROUS = ("masonry", "stone", "plaster", "concrete", "wood", "clay", "paper", "sand")
WEAR = {"clean": 0.15, "abandoned": 0.55, "damaged": 0.85, "burnt": 0.7}


def mix(a, b, t):
    t = np.asarray(t, np.float32)
    if t.ndim == 0:
        t = np.full(len(a), float(t), np.float32)
    return a * (1 - t[:, None]) + np.asarray(b, np.float32) * t[:, None]


class Ctx:
    """What every layer reads: the texels' position, normal, AO, edge, material per texel."""

    def __init__(self, maps, spec, state):
        mats = spec["materials"]
        self.tags = list(mats)
        mask = maps["mask"]
        self.P = maps["pos"][mask].astype(np.float32)
        N = maps["nrm"][mask].astype(np.float32)
        self.N = N / np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-6)
        self.tag = np.clip(maps["tag"][mask], 0, len(self.tags) - 1)
        self.unit = maps["unit"][mask] if "unit" in maps else np.zeros(len(self.P), np.int64)
        self.ao = np.clip(maps["ao"][mask], 0, 1)
        self.edge = np.clip(maps["edge"][mask], 0, 1)
        self.M = [mats[t] for t in self.tags]
        self.state = state
        self.wear = WEAR[state]
        self.spec = spec
        self.joint = np.zeros(len(self.P), np.float32)
        self.sky = np.clip(self.N[:, 1], 0, 1)
        self.n = len(self.P)

    def per(self, attr, dtype=np.float32):
        return np.array([getattr(m, attr) for m in self.M], dtype)[self.tag]

    def kind_is(self, *kinds):
        return np.isin(np.array([m.kind for m in self.M])[self.tag], kinds)

    def of(self, tag):
        return self.tag == self.tags.index(tag) if tag in self.tags else np.zeros(self.n, bool)


# --- Base ------------------------------------------------------------------------------------------

def base(c):
    """The coat: each material's colour, a little uneven; a pattern (bricks, boards) where the
    material has one; per-unit variation (each sett, tile, paver its own shade)."""
    coat = c.per("paint")
    grain = c.per("grain")
    col = coat * (1 - grain[:, None] + 2 * grain[:, None] * fbm(c.P, 9.0, 3, 3)[:, None])
    for i, m in enumerate(c.M):
        if m.kind == "glass":  # glass shows the sky: lighter, in soft diagonal sheens
            sel = c.tag == i
            q = c.P[sel] @ np.array([[0.7, 0, 0.7], [0.7, 1, -0.7], [0, 0, 0]], np.float32)
            col[sel] *= (0.75 + 0.5 * fbm(q, 2.5, 2, 41 + i))[:, None]
        if m.speckle:  # fine grains of a stone (granite's mica and feldspar, the aggregate in concrete)
            sel = c.tag == i
            col[sel] *= (1 - m.speckle + 2 * m.speckle * fbm(c.P[sel], 160.0, 2, 37 + i, warp=0))[:, None]
        if m.palette:
            sel = c.tag == i
            pal = np.array(m.palette, np.float32)
            h = _hash(c.unit[sel], 17.0 + i)
            col[sel] = pal[(h * len(pal)).astype(int) % len(pal)] * (1 - grain[sel, None] + 2 * grain[sel, None] * fbm(c.P[sel], 9.0, 3, 3)[:, None])
        if m.vary:
            sel = c.tag == i
            col[sel] *= (1 - m.vary + 2 * m.vary * _hash(c.unit[sel], 23.0 + i))[:, None]
        if m.pattern is not None:
            sel = np.nonzero(c.tag == i)[0]
            if len(sel):
                pc, pj, _ = m.pattern(c.P[sel], c.N[sel])
                col[sel] = pc
                c.joint[sel] = pj
    return col


def plaster_fall(c, col):
    """Where plaster has fallen off (patches growing with the years, ragged), the wall under it
    shows (`Plaster.beneath`), with a pale broken rim and a shadow at its top."""
    for i, m in enumerate(c.M):
        if m.pattern is None or not hasattr(m.pattern, "beneath"):
            continue
        sel = np.nonzero(c.tag == i)[0]
        if not len(sel) or c.wear < 0.3:
            continue
        P = c.P[sel]
        f = fbm(P, 2.2, 4, 51) + 0.12 * fbm(P, 18.0, 2, 53)
        th = 0.84 - 0.22 * c.wear
        gone = f > th
        rim = (f > th - 0.025) & ~gone
        under, uj, _ = m.pattern.beneath(P, c.N[sel])
        out = col[sel]
        out = np.where(gone[:, None], under, out)
        out = np.where(rim[:, None], out * 1.12 + 0.03, out)
        col[sel] = out
        c.joint[sel] = np.where(gone, uj, c.joint[sel])
    return col


def fade(c, col):
    """Sun-faded: paler and warmer, most on what faces the sky (painted things only)."""
    if c.state == "clean":
        return col
    f = c.per("fades", bool)
    t = np.clip(0.55 * c.wear + 0.4 * c.wear * c.sky, 0, 1) * f
    return mix(col, col * 0.55 + np.array([0.33, 0.24, 0.22], np.float32), t)


def chips(c, col):
    """Paint chipped off the edges first, then in patches as the years go: through to the primer,
    the bare stuff in the middle of a patch. Returns (colour, where it is down to bare)."""
    P = c.P
    wood = c.kind_is("wood")
    # paint on wood peels in strips along the grain (paint_perpignan): the noise stretched upright
    Q = np.where(wood[:, None], P * np.array([3.0, 0.45, 3.0], np.float32), P)
    patch = fbm(Q, 14.0, 4, 7)
    edge_n = c.edge + 0.35 * (fbm(P, 70.0, 2, 9) - 0.5)
    w = c.wear
    th = np.where(wood, 0.80 - 0.18 * w, 0.74 - 0.22 * w)
    patches = (patch - th) * 2.0 if w > 0.3 else np.full(c.n, -1.0, np.float32)
    chipped = np.maximum(edge_n - (0.8 - 0.45 * w), patches) * c.per("chip")
    col = np.where((chipped > 0)[:, None], c.per("under") * (0.9 + 0.2 * fbm(P, 50.0, 2, 8))[:, None], col)
    deep = chipped > 0.3
    col = np.where(deep[:, None], c.per("bare"), col)
    return col, deep


def streaks(P, N, sources, length, width, depth=0.15, seed=0):
    """How strongly each point lies in a run hanging below one of `sources` (points): down a face
    that stands up, within `width` of the source sideways (widening as it falls) and `depth` of it
    through the face, fading over `length` (each source's own, from 0.4 to 1.4 times)."""
    out = np.zeros(len(P), np.float32)
    if len(sources) == 0:
        return out
    S = np.unique(np.round(np.asarray(sources, np.float64) / 0.035), axis=0) * 0.035
    cell = max(width * 3, 0.06)
    kx = np.floor(P[:, 0] / cell).astype(np.int64)
    kz = np.floor(P[:, 2] / cell).astype(np.int64)
    key = kx * 1_000_003 + kz
    order = np.argsort(key)
    sk = key[order]
    up = np.array([0, 1, 0], np.float32)
    T = np.cross(up[None], N)
    T /= np.maximum(np.linalg.norm(T, axis=1, keepdims=True), 1e-6)
    standing = np.abs(N[:, 1]) < 0.55
    for s in S:
        L = length * (0.4 + _hash(s[0] * 100, s[2] * 100, seed + 1.0))
        sx, sz = int(np.floor(s[0] / cell)), int(np.floor(s[2] / cell))
        for dx in (-1, 0, 1):
            for dz in (-1, 0, 1):
                k = (sx + dx) * 1_000_003 + (sz + dz)
                a, b = np.searchsorted(sk, k), np.searchsorted(sk, k, side="right")
                if a == b:
                    continue
                idx = order[a:b]
                rel = P[idx] - s
                dy = -rel[:, 1]
                ok = standing[idx] & (dy > 0) & (dy < L)
                if not ok.any():
                    continue
                lat = np.abs(np.sum(rel * T[idx], 1))
                thr = np.abs(np.sum(rel * N[idx], 1))
                w = width * (1 + 0.8 * dy / L) * (0.7 + 0.6 * fbm(P[idx] * np.array([1, 0.1, 1], np.float32), 30.0, 2, seed + 3))
                v = (1 - lat / w) * (1 - dy / L) ** 0.6
                v = np.where(ok & (thr < depth) & (lat < w), v, 0)
                out[idx] = np.maximum(out[idx], v)
    return out


def rust(c, col, deep):
    """Rust on bare metal, in random runs on what rusts, and hanging under every fixing."""
    if c.state == "clean":
        fix = c.per("fixing", bool) & c.per("rusts", bool)
        tint = np.array([0.34, 0.16, 0.07], np.float32)
        return mix(col, tint, fix * 0.25)
    rusts = c.per("rusts", bool)
    rust_c = np.array([0.34, 0.16, 0.07], np.float32)
    streak = fbm(c.P * np.array([1.0, 0.12, 1.0], np.float32), 55.0, 3, 11)
    runs = rusts & (streak > 0.72 - 0.12 * c.wear) & (fbm(c.P, 6.0, 2, 13) > 0.45)
    col = np.where((rusts & deep)[:, None], mix(c.per("bare"), rust_c, 0.7), col)
    col = mix(col, rust_c, runs * 0.55 * c.wear)
    fix = c.per("fixing", bool) & rusts
    if fix.any():
        col = np.where(fix[:, None], mix(col, rust_c * 0.9, 0.75), col)
        hang = streaks(c.P, c.N, c.P[fix], 0.08 + 0.35 * c.wear, 0.012, 0.05, seed=61)
        col = mix(col, np.array([0.42, 0.20, 0.08], np.float32), np.clip(hang * 1.4, 0, 0.85))
    return col


def water(c, col):
    """Water stains: dark runs down the wall from under every ledge that sheds water (the top
    edge of a sill, a coping, a cornice), and greenish at their foot on porous stuff."""
    if c.state == "clean":
        return col
    ledge = (c.N[:, 1] > 0.75) & (c.edge > 0.25) & (c.P[:, 1] > 0.15) & c.per("sheds", bool)
    if not ledge.any():
        return col
    run = streaks(c.P, c.N, c.P[ledge], 0.25 + 0.9 * c.wear, 0.05, 0.25, seed=71)
    porous = c.kind_is(*POROUS)
    k = np.clip(run * (0.35 + 0.5 * c.wear), 0, 0.8) * np.where(porous, 1.0, 0.5)
    dark = col * np.array([0.62, 0.64, 0.62], np.float32)
    col = mix(col, dark, k)
    if c.state == "abandoned":
        algae = (run > 0.25) & porous & (fbm(c.P, 20.0, 2, 73) > 0.5)
        col = mix(col, np.array([0.17, 0.21, 0.12], np.float32), algae * 0.5)
    return col


def grime(c, col):
    """Grime in the cavities and in the joints, dirt splashed up from the ground."""
    w = c.wear
    g = np.clip((1 - c.ao) * 1.4, 0, 1) * (0.25 + 0.6 * w)
    col = mix(col, np.array([0.17, 0.15, 0.12], np.float32), g * 0.6)
    col = mix(col, np.array([0.20, 0.18, 0.15], np.float32), np.clip(c.joint, 0, 1) * (0.1 + 0.4 * w))
    y = c.P[:, 1] - c.spec.get("ground", 0.0)
    foot = np.clip(1 - y / (0.12 + 0.25 * w), 0, 1) * (0.5 + 0.5 * fbm(c.P, 30.0, 3, 17))
    standing = np.abs(c.N[:, 1]) < 0.7
    return mix(col, np.array([0.30, 0.26, 0.21], np.float32), foot * (0.35 + 0.4 * w) * np.where(standing, 1.0, 0.5))


def moss(c, col):
    """Moss and algae where it stays damp: low, facing away from the sun (north is +Z), in
    joints and on the shaded top of ledges; only in the abandoned years. Metal gets a little at
    its foot, porous stuff a lot."""
    if c.state != "abandoned":
        return col
    y = c.P[:, 1] - c.spec.get("ground", 0.0)
    north = np.clip(c.N[:, 2], 0, 1)
    shade = np.clip(-c.N[:, 1] * 0.5 + 0.5, 0, 1) * np.clip(1 - y / 0.5, 0, 1)
    porous = c.kind_is(*POROUS)
    flat = c.N[:, 1] > 0.7
    low = np.clip(1 - y / 0.9, 0, 1)
    damp = np.where(porous, np.where(flat, 0.9 * c.joint + 0.6 * (1 - c.ao),
                                     0.3 * north + 0.45 * low + 0.6 * c.joint * low + 0.3 * (1 - c.ao)), shade)
    f = fbm(c.P, 6.0, 4, 19)
    m = (f * damp * (1 - c.ao * 0.3)) > np.where(porous, 0.34, 0.3)
    green = np.array([0.20, 0.25, 0.10], np.float32) * (0.8 + 0.3 * fbm(c.P, 60.0, 2, 21))[:, None]
    m &= ~c.kind_is("glass")
    return np.where(m[:, None], green, col)


# --- Decals ----------------------------------------------------------------------------------------

def _decal_uv(c, d):
    """(u, v) in metres in the decal's plane from its centre, and the texels it may land on."""
    at = np.asarray(d["at"], np.float32)
    right = np.asarray(d.get("right", (-1, 0, 0)), np.float32)  # the reader's right
    up = np.asarray(d.get("up", (0, 1, 0)), np.float32)
    face = np.cross(right, up)  # the decal faces the reader (-Z for the default frame: the front)
    rel = c.P - at
    u, v = rel @ right, rel @ up
    w, h = d["size"]
    on = (np.abs(u) < w / 2 + 0.05) & (np.abs(v) < h / 2 + 0.05) & (np.abs(rel @ face) < d.get("depth", 0.06)) & \
         (c.N @ face > 0.5)
    return u, v, on, right, up


POSTER_PAPER = [(0.86, 0.83, 0.74), (0.88, 0.80, 0.55), (0.72, 0.80, 0.86), (0.90, 0.75, 0.72), (0.92, 0.90, 0.84)]


def poster(c, col, d):
    """A paper poster pasted on: a sheet of a seeded colour, a heading and lines of type in the
    block font, its bottom torn and peeling with the years, an older one showing under the tear."""
    u, v, on, right, up = _decal_uv(c, d)
    if not on.any():
        return col
    w, h = d["size"]
    seed = d.get("seed", 0)
    idx = np.nonzero(on)[0]
    uu, vv, P = u[idx], v[idx], c.P[idx]
    tear = -h / 2 + h * (0.05 + 0.4 * c.wear * fbm(P * np.array([1, 0, 1], np.float32), 6.0, 2, seed + 5))
    rag = 0.012 * (fbm(P, 80.0, 2, seed + 7) - 0.5)
    sheet = (np.abs(uu) < w / 2 + rag) & (vv < h / 2 + rag) & (vv > tear + rag)
    older = (np.abs(uu - 0.04) < w / 2) & (vv < h / 2 - 0.05) & (vv > -h / 2 + 0.02) & ~sheet & (c.wear > 0.4)
    paper = np.array(POSTER_PAPER[seed % len(POSTER_PAPER)], np.float32)
    old = np.array(POSTER_PAPER[(seed + 2) % len(POSTER_PAPER)], np.float32) * 0.85
    age = 0.15 + 0.6 * c.wear
    pcol = paper * (1 - 0.25 * age) + np.array([0.08, 0.06, 0.0], np.float32) * age
    pcol = pcol * (0.94 + 0.1 * fbm(P, 25.0, 2, seed + 9))[:, None]  # wrinkles
    ink = np.array([0.08, 0.07, 0.07], np.float32) if seed % 3 else np.array([0.55, 0.08, 0.06], np.float32)
    lines = d.get("text", ["AVIS"])
    out = col[idx]
    out = np.where(older[:, None], old * (0.9 + 0.1 * fbm(P, 25.0, 2, seed + 11))[:, None], out)
    out = np.where(sheet[:, None], pcol, out)
    # type: the first line big, the rest small, from the top down
    at = np.asarray(d["at"], np.float32)
    y = h / 2 - h * 0.14
    for k, line in enumerate(lines):
        size = min(h * (0.12 if k == 0 else 0.045), w * 0.85 / max(lettering.width(line, 1.0), 1e-3))
        m = lettering.mask(P, line, at + up * y, size, right=right, up=up, weight=1.1 if k == 0 else 0.9) & sheet
        out = np.where(m[:, None], ink * (1 - 0.3 * age) + paper * 0.3 * age, out)
        y -= size * (1.6 if k == 0 else 1.7)
    if c.state == "burnt":
        out = np.where(sheet[:, None], out * 0.25 + np.array([0.06, 0.04, 0.03], np.float32), out)
    col[idx] = out
    return col


GRAFFITI = [(0.05, 0.05, 0.06), (0.62, 0.07, 0.06), (0.10, 0.20, 0.55), (0.92, 0.92, 0.90)]


def graffiti(c, col, d):
    """Sprayed words: the block letters slanted and wobbling as a hand sprays, an overspray halo,
    paint running down from the heavy strokes."""
    u, v, on, right, up = _decal_uv(c, d)
    if not on.any():
        return col
    seed = d.get("seed", 0)
    idx = np.nonzero(on)[0]
    P = c.P[idx]
    text = d.get("text", "ZONE")
    h = min(d["size"][1] * 0.8, d["size"][0] * 0.92 / max(lettering.width(text, 1.0) * 1.1, 1e-3))
    paint = np.array(GRAFFITI[d.get("colour", seed) % len(GRAFFITI)], np.float32)

    def wobble(x, y):
        Q = np.stack([x, y, np.full_like(x, seed)], 1).astype(np.float32)
        return x + 0.35 * (fbm(Q, 0.35, 2, seed + 1) - 0.5), y + 0.35 * (fbm(Q, 0.35, 2, seed + 2) - 0.5) + 0.25 * np.sin(x * 0.9)

    cov = lettering.coverage(P, text, d["at"], h, right=right, up=up, weight=1.3, shear=0.22, jitter=wobble)
    core = cov > 0
    halo = (cov > -0.45) & ~core
    # drips: below a stroke, thin runs at seeded columns
    uu, vv = u[idx], v[idx]
    col_k = np.floor(uu / 0.03)
    dripping = _hash(col_k, seed + 31.0) > 0.8
    drip_len = 0.04 + 0.12 * _hash(col_k, seed + 33.0)
    above = lettering.coverage(P + up * 0.01, text, d["at"], h, right=right, up=up, weight=1.3, shear=0.22, jitter=wobble)
    fresh = np.zeros(len(idx), bool)
    for k in range(1, 12):  # look up the column for paint within the drip's length
        a = lettering.coverage(P + up[None] * (drip_len * k / 11)[:, None], text, d["at"], h, right=right, up=up, weight=1.3, shear=0.22,
                               jitter=wobble) > 0.2
        fresh |= a
    thin = np.abs(uu - (col_k + 0.5) * 0.03) < 0.003
    drip = dripping & thin & fresh & ~core & (above <= 0)
    out = col[idx]
    age = 0.2 + 0.5 * c.wear
    out = mix(out, paint, halo * 0.3 * (1 - age * 0.5))
    pc = paint * (1 - 0.3 * age) + out * 0.3 * age
    out = np.where((core | drip)[:, None], pc, out)
    col[idx] = out
    return col


def soot_plume(c, col, d):
    """Soot that climbed out of an opening when it burnt: a plume widening up the wall above it."""
    u, v, on, right, up = _decal_uv(c, d)
    w, h = d["size"]
    rel_v = v + h / 2  # from the plume's foot
    width = w / 2 * (0.7 + 0.8 * np.clip(rel_v / h, 0, 1))
    k = np.clip(1 - np.abs(u) / np.maximum(width, 1e-3), 0, 1) ** 0.6 * np.clip(1 - rel_v / h, 0, 1) ** 0.5
    k = k * (0.75 + 0.5 * fbm(c.P, 5.0, 3, 81)) * on * (rel_v > -0.02)
    return mix(col, np.array([0.04, 0.035, 0.03], np.float32), np.clip(k, 0, 0.95))


def decals(c, col):
    for d in c.spec.get("decals", []):
        if c.state not in d.get("states", ("clean", "abandoned", "damaged", "burnt")):
            continue
        kind = d["kind"]
        if kind == "poster":
            col = poster(c, col, d)
        elif kind == "graffiti":
            col = graffiti(c, col, d)
        elif kind == "soot" and c.state == "burnt":
            col = soot_plume(c, col, d)
    return col


# --- Damage ----------------------------------------------------------------------------------------

def pocks(c, col):
    """Bullet strikes, scattered in bursts on what faces the shooter, each by its material: a pale
    crater in masonry and stone, a bright ring on metal, a pale splinter in wood, a little star in
    glass; a dark hole in the middle."""
    if c.state != "damaged":
        return col
    P = c.P
    cell = np.floor(P / 0.06)
    h = _hash(cell[:, 0], cell[:, 1], cell[:, 2], 3.0)
    burst = fbm(P, 2.0, 2, 91) > 0.48
    hit = (h > 0.72) & burst
    centre = (cell + 0.25 + 0.5 * np.stack([_hash(cell[:, 0], cell[:, 1], 5.0), _hash(cell[:, 1], cell[:, 2], 6.0),
                                            _hash(cell[:, 2], cell[:, 0], 7.0)], 1)) * 0.06
    d = np.linalg.norm(P - centre, axis=1)
    r = 0.010 + 0.012 * _hash(cell[:, 0], cell[:, 2], 8.0)
    masonry = c.kind_is("masonry", "stone", "plaster", "concrete", "clay")
    metal = c.kind_is("metal")
    wood = c.kind_is("wood")
    glass = c.kind_is("glass")
    ring = hit & (d < r)
    pale = np.where(masonry[:, None], col * 0.55 + np.array([0.42, 0.40, 0.36], np.float32),
                    np.where(metal[:, None], c.per("bare") * 0.9 + 0.18, col * 0.7 + np.array([0.3, 0.24, 0.15], np.float32)))
    col = np.where((ring & ~glass)[:, None], pale, col)
    # spall: a ragged pale scar round a strike on masonry
    scar = hit & masonry & (d < r * 1.9) & (fbm(P, 120.0, 2, 93) > 0.5)
    col = np.where(scar[:, None], col * 0.75 + np.array([0.18, 0.17, 0.15], np.float32), col)
    if glass.any():
        ang = np.arctan2(P[:, 1] - centre[:, 1], P[:, 0] - centre[:, 0] + (P[:, 2] - centre[:, 2]))
        star = hit & glass & (d < r * 3.5) & (np.abs(np.sin(ang * 4.5 + h * 9)) < 0.12 + 0.4 * (d < r * 0.8))
        col = np.where(star[:, None], np.array([0.75, 0.80, 0.82], np.float32), col)
    col = np.where((hit & (d < r * 0.45))[:, None], np.array([0.05, 0.05, 0.05], np.float32), col)
    return col


def glass_cracks(c, col):
    """Cracks round every hole in a pane (`spec["glass_holes"]`: centre, radius, the pane's normal):
    lines running out from it, a few rings between them, bright where the light catches them."""
    holes = c.spec.get("glass_holes", [])
    glass = c.kind_is("glass")
    if not holes or not glass.any():
        return col
    idx = np.nonzero(glass)[0]
    P = c.P[idx]
    lines = np.zeros(len(idx), bool)
    for k, (centre, radius, normal) in enumerate(holes):
        n = np.asarray(normal, np.float32)
        n /= np.linalg.norm(n)
        a = np.cross(n, [0, 1, 0]) if abs(n[1]) < 0.9 else np.cross(n, [1, 0, 0])
        a = a / np.linalg.norm(a)
        b = np.cross(n, a)
        rel = P - np.asarray(centre, np.float32)
        x, y = rel @ a, rel @ b
        r = np.hypot(x, y)
        ang = np.arctan2(y, x)
        reach = radius * 5.0
        wav = ang + 0.08 * np.sin(r * 40 + k)  # cracks wander
        spokes = 11 + k * 2
        s = np.abs(((wav / (2 * np.pi) * spokes + _hash(k, 1.0)) % 1.0) - 0.5) * 2 * np.pi * r / spokes
        long = _hash(np.floor((wav / (2 * np.pi)) * spokes + _hash(k, 1.0)), k + 3.0)
        radial = (s < 0.0016) & (r < reach * (0.5 + 0.7 * long)) & (r > radius * 0.9)
        rings = (np.abs(((r / radius) % 1.15) - 0.6) < 0.025) & (r < reach * 0.6) & (r > radius) & \
                (np.sin(ang * spokes * 0.5 + r * 3) > -0.2)
        lines |= radial | rings
    out = col[idx]
    out = np.where(lines[:, None], np.array([0.78, 0.82, 0.84], np.float32), out)
    col[idx] = out
    return col


def burnt(c, col):
    """The burnt version of every material: soot climbing from the foot; paint blistered and burnt
    off to heat-tinted, rusting metal; wood charred black and cracked into blocks; masonry, stone
    and concrete blackened in clouds, spalled pale where it popped; glass smoked; clay darkened;
    paper and cloth burnt away; ash lying on top."""
    if c.state != "burnt":
        return col
    P = c.P
    top = max(float(P[:, 1].max()), 0.3)
    y = P[:, 1] - c.spec.get("ground", 0.0)
    soot = np.clip(0.2 + 0.55 * y / top + 0.5 * (fbm(P, 1.5, 4, 23) - 0.5), 0, 1)
    col = col * (1 - 0.6 * soot)[:, None]
    kind = np.array([m.kind for m in c.M])[c.tag]
    metal = kind == "metal"
    blister = fbm(P, 90.0, 2, 29) > 0.62
    burnt_off = (fbm(P, 12.0, 3, 101) > 0.55) & metal
    heat = mix(np.repeat(np.array([[0.22, 0.20, 0.24]], np.float32), c.n, 0), np.array([0.35, 0.18, 0.08], np.float32),
               fbm(P, 20.0, 2, 103))
    col = np.where((blister & metal)[:, None], col * 0.6, col)
    col = np.where(burnt_off[:, None], heat, col)
    wood = kind == "wood"
    if wood.any():
        # charring: black, cracked into a grid of blocks along the grain (alligatoring)
        q = P * np.array([28.0, 9.0, 28.0], np.float32)
        cx = np.abs(((q[:, 0] + q[:, 2]) + 0.6 * fbm(P, 30.0, 2, 105)) % 1.0 - 0.5)
        cy = np.abs((q[:, 1] + 0.5 * fbm(P, 30.0, 2, 107)) % 1.0 - 0.5)
        crack = (cx > 0.44) | (cy > 0.45)
        char = np.array([0.075, 0.06, 0.05], np.float32) * (0.9 + 0.2 * fbm(P, 60.0, 2, 109))[:, None]
        col = np.where(wood[:, None], np.where(crack[:, None], np.array([0.025, 0.02, 0.017], np.float32), char), col)
    mas = np.isin(kind, ("masonry", "stone", "concrete", "plaster", "clay"))
    clouds = fbm(P, 1.8, 4, 111)
    col = np.where(mas[:, None], col * (1 - np.clip(clouds * 1.3 - 0.35, 0, 0.6))[:, None], col)
    spall = mas & (fbm(P, 5.0, 4, 113) > 0.74)
    col = np.where(spall[:, None], col * 0.4 + np.array([0.45, 0.42, 0.38], np.float32) * 0.6, col)
    col = np.where((kind == "glass")[:, None], mix(col, np.array([0.12, 0.10, 0.08], np.float32), 0.75), col)
    col = np.where(np.isin(kind, ("paper", "cloth"))[:, None], np.array([0.05, 0.04, 0.035], np.float32), col)
    ash = c.sky * np.clip((fbm(P, 6.0, 4, 31) - 0.5) * 3.0, 0, 1)  # drifts of ash on what faces up, soft-edged
    return mix(col, np.array([0.42, 0.40, 0.37], np.float32), ash * 0.55)
