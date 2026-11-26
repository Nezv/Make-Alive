"""What the evacuation left behind (S184). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

trolley: a supermarket trolley (side): the tapered wire basket for nesting, its bottom rising to
the front, the push handle with its grip and the child seat's flap, the chassis on four casters,
the lower tray.
plastic_chair: the white monobloc chair (white): the seat, the slatted back, arms sweeping down to
the front legs, four flared legs of U section.
pram: an old pram (navy, wicker): the deep body, its hood folded up at the back on ribs, the
chassis on C-springs, four spoked wheels, the handle.
suitcase_hard: a hard-shell case on its wheels (shell, decayed): two shells with ribs, the zip
between them, the telescopic handle, the side handle, four spinner wheels. No brand.
suitcase_soft: an old leather suitcase lying flat: two straps round it, the handle, corner caps,
brass locks.

Standing on y = 0, the front -Z (the trolley is pushed from +Z).
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

TROLLEY = dict(top=0.98, back=(0.40, 0.50, 0.27), front=(-0.48, 0.62, 0.22), wire=0.0035)   # z, basket bottom, half width
CHAIR = dict(seat=0.44, w=0.46, d=0.44, back=0.82, arm=0.64)
PRAM = dict(len=0.82, w=0.40, body=(0.45, 0.78), wheel=0.21)
CASE = dict(w=0.46, h=0.68, d=0.27)
SOFT = dict(w=0.66, h=0.19, d=0.42)
MATT = dict(len=1.90, w=1.40, h=0.20)
BOAT = dict(len=3.60, beam=1.40, depth=0.48)


def materials():
    return {
        "green": Material((0.10, 0.45, 0.25), under=(0.55, 0.56, 0.55), bare=(0.45, 0.45, 0.44), chip=0.4, grain=0.05),
        "yellow": Material((0.90, 0.80, 0.10), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "plastic": Material((0.88, 0.88, 0.85), kind="rubber", chip=0.0, rusts=False, grain=0.05),
        "tyre": Material((0.08, 0.08, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.06),
        "chrome": Material((0.75, 0.76, 0.77), under=(0.5, 0.5, 0.5), bare=(0.40, 0.28, 0.18), chip=0.3, grain=0.04),
        "navy": Material((0.10, 0.15, 0.32), under=(0.30, 0.28, 0.25), bare=(0.30, 0.28, 0.25), kind="rubber", chip=0.0, rusts=False, grain=0.08),
        "cream": Material((0.88, 0.84, 0.74), kind="rubber", chip=0.0, rusts=False, grain=0.06),
        "shell": Material((0.55, 0.57, 0.60), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "leather": Material((0.40, 0.24, 0.13), kind="rubber", chip=0.0, rusts=False, grain=0.12),
        "strap": Material((0.25, 0.15, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.10),
        "brass": Material((0.68, 0.54, 0.26), under=(0.5, 0.4, 0.2), bare=(0.5, 0.4, 0.2), chip=0.0, rusts=False, grain=0.04, fades=False),
        "dark": Material((0.06, 0.06, 0.06), chip=0.0, rusts=False, grain=0.02, fades=False),
        "ticking": Material((0.86, 0.84, 0.78), kind="paper", chip=0.0, rusts=False, grain=0.06),
        "piping": Material((0.70, 0.68, 0.62), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "fur": Material((0.48, 0.33, 0.18), kind="paper", chip=0.0, rusts=False, grain=0.25),
        "felt": Material((0.78, 0.66, 0.48), kind="paper", chip=0.0, rusts=False, grain=0.10),
        "alu": Material((0.66, 0.68, 0.70), under=(0.60, 0.62, 0.64), bare=(0.62, 0.64, 0.66), chip=0.0, rusts=False, grain=0.06),
        "hullpaint": Material((0.22, 0.34, 0.30), under=(0.60, 0.62, 0.64), bare=(0.62, 0.64, 0.66), chip=0.6, rusts=False, grain=0.06),
        "oar": Material((0.62, 0.48, 0.30), under=(0.55, 0.42, 0.26), bare=(0.60, 0.50, 0.36), kind="wood", chip=0.4, rusts=False, grain=0.14),
        "sole": Material((0.90, 0.89, 0.85), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "upper": Material((0.30, 0.38, 0.55), kind="paper", chip=0.0, rusts=False, grain=0.08),
        "upper2": Material((0.24, 0.16, 0.10), kind="rubber", chip=0.0, rusts=False, grain=0.10),
        "lace": Material((0.92, 0.92, 0.90), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "pet": Material((0.62, 0.74, 0.82), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "bcap": Material((0.12, 0.30, 0.70), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "label": Material((0.85, 0.88, 0.92), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "film": Material((0.80, 0.84, 0.86), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "cloth": Material((0.25, 0.30, 0.45), kind="paper", chip=0.0, rusts=False, grain=0.14,
                          palette=[(0.25, 0.30, 0.45), (0.55, 0.12, 0.12), (0.20, 0.20, 0.22), (0.70, 0.66, 0.55), (0.30, 0.42, 0.28), (0.82, 0.60, 0.15)], vary=0.05),
    }


# --- trolley ---------------------------------------------------------------------------------------------
def _caster(x, z, r, lod):
    m = Mesh()
    m.merge(S.along(S.lathe([(-0.012, r), (0.012, r)], [10, 6, 4][lod], tag="tyre"), (1, 0, 0), (x, r, z)))
    if lod < 2:
        m.merge(S.box((x, r + 0.04, z), (0.02, 0.04, 0.02), "chrome"))
    return m


def trolley(lod):
    top = TROLLEY["top"]
    zb, yb, hb = TROLLEY["back"]
    zf, yf, hf = TROLLEY["front"]
    w = TROLLEY["wire"]
    m = Mesh()
    wsides = [3, 3, 3][lod]
    rod = S.circle(w, wsides)

    def half(z):
        return hb + (hf - hb) * (z - zb) / (zf - zb)

    def bottom(z):
        return yb + (yf - yb) * (z - zb) / (zf - zb)

    # the basket's rims: the top, the bottom; its corner posts
    for y_of, k in ((lambda z: top, 0.008), (bottom, 0.006)):
        ring = [(-half(zb), y_of(zb), zb), (half(zb), y_of(zb), zb), (half(zf), y_of(zf), zf), (-half(zf), y_of(zf), zf)]
        m.merge(S.sweep(ring, S.circle(k, [6, 4, 3][lod]), "green", closed=True))
    # the side and end walls: wires up from the bottom to the top rim, rails along
    step = [0.045, 0.09, 0.18][lod]
    nz = int((zb - zf) / step)
    for s in (1, -1):
        for i in range(nz + 1):
            z = zf + (zb - zf) * i / nz
            m.merge(S.sweep([(s * half(z), bottom(z), z), (s * half(z), top, z)], rod, "green"))
    for z in (zb, zf):
        n = int(2 * half(z) / step)
        for i in range(1, n):
            x = -half(z) + 2 * half(z) * i / n
            m.merge(S.sweep([(x, bottom(z), z), (x, top, z)], rod, "green"))
    if lod < 2:
        for k in range(1, [6, 3][lod]):
            f = k / [6, 3][lod]
            ring = [(-half(zb), bottom(zb) + (top - bottom(zb)) * f, zb), (half(zb), bottom(zb) + (top - bottom(zb)) * f, zb),
                    (half(zf), bottom(zf) + (top - bottom(zf)) * f, zf), (-half(zf), bottom(zf) + (top - bottom(zf)) * f, zf)]
            m.merge(S.sweep(ring, rod, "green", closed=True))
        for i in range(1, int(2 * hb / step)):  # the bottom's wires, front to back
            x = -hb + 2 * hb * i / int(2 * hb / step)
            m.merge(S.sweep([(x * hf / hb, bottom(zf), zf), (x, bottom(zb), zb)], rod, "green"))
    # the push handle and its grip, the child seat's flap at the back
    m.merge(S.sweep([(-hb, top, zb), (-hb - 0.02, top + 0.06, zb + 0.08), (hb + 0.02, top + 0.06, zb + 0.08), (hb, top, zb)], S.circle(0.011, [6, 4, 3][lod]), "green"))
    m.merge(S.along(S.lathe([(-hb + 0.02, 0.018), (hb - 0.02, 0.018)], [8, 6, 4][lod], tag="yellow"), (1, 0, 0), (0, top + 0.06, zb + 0.08)))
    if lod < 2:
        m.merge(S.box((0, top - 0.16, zb - 0.02), (hb - 0.06, 0.13, 0.006), "yellow"))
        m.merge(S.box((-hf + 0.01, (top + bottom(zf)) / 2, zf + 0.25), (0.006, 0.12, 0.18), "green"))   # the plastic panel at the side
    # the chassis: the base rails on four casters, legs up to the basket, the lower tray
    yc = 0.11
    for s in (1, -1):
        m.merge(S.sweep([(s * 0.25, yc, zb - 0.04), (s * 0.19, yc, zf + 0.06)], S.circle(0.012, [6, 4, 3][lod]), "green"))
        m.merge(S.sweep([(s * 0.25, yc, zb - 0.04), (s * hb * 0.9, yb, zb)], S.circle(0.012, [6, 4, 3][lod]), "green"))
        m.merge(S.sweep([(s * 0.19, yc, zf + 0.06), (s * hf * 0.9, yf, zf + 0.15)], S.circle(0.010, [6, 4, 3][lod]), "green"))
        m.merge(_caster(s * 0.25, zb - 0.04, 0.055, lod))
        m.merge(_caster(s * 0.19, zf + 0.06, 0.055, lod))
    if lod < 2:
        for i in range([7, 3][lod]):
            z = zf + 0.15 + (zb - zf - 0.3) * i / ([7, 3][lod] - 1)
            m.merge(S.sweep([(-0.22, 0.17, z), (0.22, 0.17, z)], rod, "green"))
    return {"body": Part(m)}


# --- plastic_chair -------------------------------------------------------------------------------------------
def plastic_chair(lod):
    sh, w, d, bk, arm = CHAIR["seat"], CHAIR["w"], CHAIR["d"], CHAIR["back"], CHAIR["arm"]
    m = Mesh()
    c = 0.04 if lod < 2 else 0.0
    seat = [(-w / 2 + c, -d / 2), (w / 2 - c, -d / 2), (w / 2, -d / 2 + c), (w / 2, d / 2), (-w / 2, d / 2), (-w / 2, -d / 2 + c)]
    m.merge(S.extrude(seat, 0.03, 0.008 if lod == 0 else 0.0, "plastic", origin=(0, sh - 0.03, 0), right=(1, 0, 0), up=(0, 0, 1)))
    # the legs: tapering, flared out at the foot
    for sx in (1, -1):
        for sz in (1, -1):
            top = (sx * (w / 2 - 0.04), sh - 0.03, sz * (d / 2 - 0.04))
            foot = (sx * (w / 2 + 0.02), 0.0, sz * (d / 2 + 0.03))
            m.merge(S.sweep([foot, top], [(-0.022, -0.016), (0.022, -0.016), (0.022, 0.016), (-0.022, 0.016)], "plastic",
                            scale=lambda i: 0.8 if i == 0 else 1.15))
    # the back: slats between two posts, a curved top rail, leaning back
    lean = 0.10
    posts = [(sx * (w / 2 - 0.03), sh, d / 2 - 0.02) for sx in (1, -1)]
    for x, y, z in posts:
        m.merge(S.sweep([(x, y, z), (x, bk, z + lean)], [(-0.02, -0.012), (0.02, -0.012), (0.02, 0.012), (-0.02, 0.012)], "plastic"))
    n = [5, 3, 0][lod]
    for k in range(n):
        x = -w / 2 + 0.07 + k * (w - 0.14) / max(n - 1, 1)
        m.merge(S.sweep([(x, sh + 0.08, d / 2 - 0.02 + lean * 0.08 / (bk - sh)), (x, bk - 0.08, d / 2 - 0.02 + lean * (bk - sh - 0.08) / (bk - sh))],
                        [(-0.022, -0.006), (0.022, -0.006), (0.022, 0.006), (-0.022, 0.006)], "plastic"))
    if lod == 2:
        m.merge(S.box((0, (sh + bk) / 2, d / 2 + lean / 2), (w / 2 - 0.02, (bk - sh) / 2, 0.01), "plastic"))
    k = [8, 5, 3][lod]
    rail = [(np.sin(np.pi * (t - 0.5)) * (w / 2 - 0.02), bk - 0.04 + 0.02 * np.cos(np.pi * (t - 0.5)), d / 2 - 0.02 + lean - 0.02 * np.cos(np.pi * (t - 0.5)))
            for t in np.linspace(0, 1, k)]
    m.merge(S.sweep(rail, [(-0.012, -0.04), (0.012, -0.04), (0.012, 0.04), (-0.012, 0.04)], "plastic"))
    m.merge(S.sweep([(-w / 2 + 0.02, sh + 0.08, d / 2 - 0.01), (w / 2 - 0.02, sh + 0.08, d / 2 - 0.01)],
                    [(-0.008, -0.025), (0.008, -0.025), (0.008, 0.025), (-0.008, 0.025)], "plastic"))
    # the arms: from the back posts sweeping forward and down into the front legs
    for sx in (1, -1):
        x = sx * (w / 2 - 0.01)
        arm_path = [(x, arm, d / 2 - 0.02 + lean * (arm - sh) / (bk - sh)), (x, arm + 0.01, 0.0), (x + sx * 0.01, arm - 0.03, -d / 2 + 0.04), (x + sx * 0.005, sh - 0.02, -d / 2 + 0.02)]
        m.merge(S.sweep(S.fillet(arm_path, 0.06, 3) if lod == 0 else arm_path, [(-0.02, -0.01), (0.02, -0.01), (0.02, 0.01), (-0.02, 0.01)], "plastic"))
    return {"body": Part(m)}


# --- pram -------------------------------------------------------------------------------------------------
def _wheel(c, r, lod):
    m = Mesh()
    sides = [16, 10, 6][lod]
    tyre = S.lathe([(-0.015, r - 0.02), (-0.015, r), (0.015, r), (0.015, r - 0.02)], sides, tag="tyre", caps=(False, False))
    m.merge(S.along(tyre, (1, 0, 0), c))
    m.merge(S.along(S.lathe([(-0.025, 0.025), (0.025, 0.025)], 8, tag="chrome"), (1, 0, 0), c))
    if lod < 2:
        for k in range([12, 6][lod]):
            a = 2 * np.pi * k / [12, 6][lod]
            p = (c[0], c[1] + np.sin(a) * (r - 0.02), c[2] + np.cos(a) * (r - 0.02))
            m.merge(S.sweep([c, p], S.circle(0.003, 3), "chrome"))
    return m


def pram(lod):
    L, w = PRAM["len"], PRAM["w"]
    y0, y1 = PRAM["body"]
    r = PRAM["wheel"]
    m = Mesh()
    # the body: a deep tub, its foot rounded, a rolled rim
    body = S.bevel_box((0, (y0 + y1) / 2, 0), (w / 2, (y1 - y0) / 2, L / 2), 0.06, "navy") if lod < 2 else S.box((0, (y0 + y1) / 2, 0), (w / 2, (y1 - y0) / 2, L / 2), "navy")
    body.verts = [np.array([v[0], v[1], v[2] * (1.0 - 0.18 * ((y1 - v[1]) / (y1 - y0)) ** 2)]) for v in body.verts]
    m.merge(body)
    if lod < 2:
        rim = [(-w / 2, y1, -L / 2), (w / 2, y1, -L / 2), (w / 2, y1, L / 2), (-w / 2, y1, L / 2)]
        m.merge(S.sweep(S.fillet(rim + [rim[0]], 0.05, 2)[:-1] if lod == 0 else rim, S.circle(0.012, 5), "chrome", closed=True))
        m.merge(S.box((0, y1 - 0.004, -0.05), (w / 2 - 0.03, 0.004, L / 2 - 0.12), "cream"))  # the cover over the baby's place
    # the hood folded up at the back: half a dome on its ribs
    n = [10, 6, 4][lod]
    hood = S.lathe([(0.0, w / 2), (0.10, w / 2 - 0.01), (0.20, w / 2 - 0.05), (0.28, w / 2 - 0.15), (0.31, 0.0)], n * 2, tag="navy", caps=(False, False))
    hood = S.clip(hood, (0, 0, 0), (0, 0, -1), None)
    hood.verts = [np.array([v[0], v[2], -v[1]]) for v in hood.verts]   # turned so it opens to the front
    hood.faces = [tuple(reversed(f)) for f in hood.faces]
    m.merge(hood.transformed(np.eye(3), (0, y1, L / 2 - 0.02)))
    if lod < 2:
        ry, rz = w / 2, 0.31  # the hood is half an ellipsoid: w/2 across and up, 0.31 forward
        for a in (0.15, 0.75, 1.35):
            rho = 1.0 / np.sqrt(np.sin(a) ** 2 / ry ** 2 + np.cos(a) ** 2 / rz ** 2) + 0.006   # the hood's reach in the rib's plane, just outside it
            rib = [(np.cos(t) * (ry + 0.006), y1 + np.sin(t) * rho * np.sin(a), L / 2 - 0.02 - np.sin(t) * rho * np.cos(a)) for t in np.linspace(0, np.pi, 9)]
            m.merge(S.sweep(rib, S.circle(0.004, 3), "chrome"))
    # the chassis: C-springs from the axles up to the body, the handle up the back
    for zc in (-L / 2 + 0.10, L / 2 - 0.10):
        for sx in (1, -1):
            spring = [(sx * (w / 2 - 0.02), y0 + 0.02, zc * 0.7), (sx * (w / 2 + 0.02), y0 - 0.08, zc * 0.85), (sx * (w / 2 + 0.04), r, zc)]
            m.merge(S.sweep(spring, [(-0.012, -0.004), (0.012, -0.004), (0.012, 0.004), (-0.012, 0.004)], "chrome", up=(1, 0, 0)))
            m.merge(_wheel((sx * (w / 2 + 0.07), r, zc), r if zc > 0 else r * 0.85, lod).transformed(np.eye(3), (0, (r * 0.15 if zc < 0 else 0) * -1, 0)))
        m.merge(S.sweep([(-w / 2 - 0.05, r, zc), (w / 2 + 0.05, r, zc)], S.circle(0.008, 5), "chrome"))
    for sx in (1, -1):
        m.merge(S.sweep([(sx * (w / 2 - 0.02), y0 + 0.05, L / 2 - 0.15), (sx * (w / 2 - 0.02), 1.02, L / 2 + 0.30)], S.circle(0.010, 5), "chrome"))
    m.merge(S.sweep([(-w / 2 + 0.02, 1.02, L / 2 + 0.30), (w / 2 - 0.02, 1.02, L / 2 + 0.30)], S.circle(0.015, 6), "cream"))
    return {"body": Part(m)}


# --- suitcases ------------------------------------------------------------------------------------------------
def suitcase_hard(lod):
    w, h, d = CASE["w"], CASE["h"], CASE["d"]
    m = Mesh()
    y0 = 0.06
    for s in (1, -1):  # the two shells, front and back, ribs across each
        shell = S.bevel_box((0, y0 + h / 2, s * d / 4), (w / 2, h / 2, d / 4 - 0.004), 0.04, "shell") if lod < 2 else \
            S.box((0, y0 + h / 2, s * d / 4), (w / 2, h / 2, d / 4 - 0.004), "shell")
        m.merge(shell)
        if lod == 0:
            for k in range(7):
                y = y0 + 0.10 + k * (h - 0.20) / 6
                m.merge(S.chamfer_box((0, y, s * (d / 2 - 0.002)), (w / 2 - 0.05, 0.012, 0.006), 0.004, "shell", edges="front" if s < 0 else "all"))
    m.merge(S.box((0, y0 + h / 2, 0), (w / 2 + 0.003, h / 2 - 0.02, 0.006), "dark"))  # the zip between the shells
    if lod < 2:
        # the telescopic handle down, its grip on top; the side handle
        for x in (-0.12, 0.12):
            m.merge(S.box((x, y0 + h + 0.015, d / 4), (0.012, 0.015, 0.012), "dark"))
        m.merge(S.box((0, y0 + h + 0.035, d / 4), (0.15, 0.012, 0.02), "dark"))
        m.merge(S.box((w / 2 + 0.012, y0 + h * 0.6, 0), (0.012, 0.02, 0.09), "dark"))
        for sx in (1, -1):  # the four spinners
            for sz in (1, -1):
                c = (sx * (w / 2 - 0.05), 0.03, sz * (d / 2 - 0.05))
                m.merge(S.box((c[0], 0.055, c[2]), (0.025, 0.008, 0.025), "dark"))
                m.merge(S.along(S.lathe([(-0.01, 0.025), (0.01, 0.025)], [8, 6][lod], tag="tyre"), (1, 0, 0), (c[0], 0.025, c[2])))
    return {"body": Part(m)}


def suitcase_soft(lod):
    w, h, d = SOFT["w"], SOFT["h"], SOFT["d"]
    m = Mesh()
    m.merge(S.bevel_box((0, h / 2, 0), (w / 2, h / 2, d / 2), 0.03, "leather") if lod < 2 else S.box((0, h / 2, 0), (w / 2, h / 2, d / 2), "leather"))
    if lod < 2:
        # the lid's seam round its edge, the two straps round it with their buckles, the handle, corner caps, locks
        m.merge(S.box((0, h * 0.62, 0), (w / 2 + 0.002, 0.004, d / 2 + 0.002), "strap"))
        for x in (-w * 0.28, w * 0.28):
            loop = [(x, -0.001, -d / 2 - 0.004), (x, h + 0.004, -d / 2 - 0.004), (x, h + 0.004, d / 2 + 0.004), (x, -0.001, d / 2 + 0.004)]
            m.merge(S.sweep(loop, [(-0.018, -0.002), (0.018, -0.002), (0.018, 0.002), (-0.018, 0.002)], "strap", closed=True, up=(1, 0, 0)))
            m.merge(S.box((x, h + 0.008, -d * 0.2), (0.022, 0.004, 0.018), "brass"))
        m.merge(S.sweep([(-0.08, h * 0.55, -d / 2), (-0.06, h * 0.55, -d / 2 - 0.04), (0.06, h * 0.55, -d / 2 - 0.04), (0.08, h * 0.55, -d / 2)],
                        [(-0.008, -0.012), (0.008, -0.012), (0.008, 0.012), (-0.008, 0.012)], "strap"))
        for x in (-w * 0.40, w * 0.40):
            m.merge(S.box((x, h * 0.62, -d / 2 - 0.006), (0.02, 0.025, 0.004), "brass"))
    if lod == 0:
        for sx in (1, -1):
            for sz in (1, -1):
                for y in (0.02, h - 0.02):
                    m.merge(S.box((sx * (w / 2 - 0.015), y, sz * (d / 2 - 0.015)), (0.022, 0.022, 0.022), "brass"))
    return {"body": Part(m)}


# --- mattress -------------------------------------------------------------------------------------------
def _rrect(w, d, r, n):
    """A rounded rectangle's outline in (x, z), counter-clockwise from +X."""
    pts = []
    for cx, cz, a0 in ((w / 2 - r, d / 2 - r, 0.0), (-w / 2 + r, d / 2 - r, np.pi / 2), (-w / 2 + r, -d / 2 + r, np.pi), (w / 2 - r, -d / 2 + r, 1.5 * np.pi)):
        for a in np.linspace(a0, a0 + np.pi / 2, n + 1):
            pts.append((cx + np.cos(a) * r, cz + np.sin(a) * r))
    return pts


def mattress(lod):
    w, d, h = MATT["len"], MATT["w"], MATT["h"]
    nr = [3, 2, 1][lod]
    m = Mesh()
    base = _rrect(w, d, 0.07, nr)

    def lift(x, z):  # one end curled up off the ground, the middle sagging
        return 0.05 * max(0.0, (x - w / 2 + 0.45) / 0.45) ** 2 - 0.01 * np.cos(np.pi * x / w)

    rings = []
    for y, k in ((0.0, 0.97), (0.015, 1.0), (h / 2, 1.005), (h - 0.015, 1.0), (h + 0.012, 0.93)):
        rings.append([(x * k, y + lift(x, z) + (0.012 if y > h else 0), z * k) for x, z in base])
    if lod < 2:  # the quilted top bellies up between the piping
        rings.insert(-1, [(x * 0.985, h + 0.006 + lift(x, z), z * 0.985) for x, z in base])
    m.loft(rings, "ticking", caps=(True, True))
    if lod < 2:  # the piping round both edges, the tufting buttons, the side handles and vents
        for y in (0.015, h - 0.015):
            path = [(x, y + lift(x, z), z) for x, z in base]
            m.merge(S.sweep(path, S.circle(0.007, [5, 4][lod]), "piping", closed=True))
        if lod == 0:
            for i in range(6):
                for j in range(4):
                    x, z = -w / 2 + (i + 0.5) * w / 6, -d / 2 + (j + 0.5) * d / 4
                    m.merge(S.prism((x, h + 0.010 + lift(x, z), z), 0.012, 0.006, 6, tag="piping"))
            for s in (1, -1):
                for x in (-0.35, 0.35):
                    m.merge(S.box((x, h / 2 + lift(x, 0), s * (d / 2 + 0.006)), (0.08, 0.012, 0.006), "piping"))
                    m.merge(S.lathe([(-0.004, 0.012), (0.004, 0.012)], 6, tag="dark").transformed(S.rotation((1, 0, 0), np.pi / 2), (x + 0.25, h / 2, s * (d / 2 + 0.002))))
    return {"body": Part(m)}


# --- teddy_bear ---------------------------------------------------------------------------------------------
def _blob(c, r, axis, lod, tag="fur", stretch=1.0):
    """A soft ellipsoid round c, `r` across, `stretch` times as long along `axis`."""
    n = [8, 6, 4][lod]
    prof = [(-r * stretch, 0.0)] + [(-r * stretch * np.cos(a), r * np.sin(a)) for a in np.linspace(0, np.pi, n + 1)[1:-1]] + [(r * stretch, 0.0)]
    return S.along(S.lathe(prof, [10, 7, 5][lod], tag=tag), axis, c)


def teddy_bear(lod):
    m = Mesh()
    # sitting slumped against something, legs out to the front, its head lolling to one side
    m.merge(_blob((0, 0.13, 0.02), 0.085, (0, 1, 0.25), lod, stretch=1.35))                       # the body
    m.merge(_blob((0, 0.10, -0.025), 0.06, (0, 1, 0.25), lod, tag="felt", stretch=1.2))          # its tummy patch
    hc = np.array([0.02, 0.28, 0.02])
    m.merge(_blob(hc, 0.075, (0.2, 1, 0), lod))
    m.merge(_blob(hc + (0.005, -0.02, -0.065), 0.035, (0, 0.2, -1), lod, tag="felt", stretch=0.9))    # the muzzle
    for s in (1, -1):
        m.merge(_blob(hc + (s * 0.06, 0.055, 0.005), 0.028, (0, 0, 1), lod, stretch=0.45))           # the ears
        m.merge(_blob((s * 0.065, 0.055, -0.09), 0.040, (s * 0.15, 0.25, -1), lod, stretch=1.9))      # the legs
        m.merge(_blob((s * 0.07, 0.05, -0.17), 0.028, (0, 1, 0.3), lod, tag="felt", stretch=0.55))   # the soles
        m.merge(_blob((s * 0.095, 0.14, -0.01), 0.032, (s * 0.45, -1, -0.35), lod, stretch=2.0))      # the arms
        if lod < 2:
            m.merge(S.prism(hc + (s * 0.03, 0.015, -0.068), 0.009, 0.006, 6, tag="dark", axis=(0, 0, -1)))   # the button eyes
    if lod < 2:
        m.merge(S.prism(hc + (0.005, -0.005, -0.105), 0.013, 0.008, 6, tag="dark", axis=(0, 0.2, -1)))   # the nose
    if lod == 0:  # a ribbon tied round the neck, its bow
        m.merge(S.lathe([(0.205, 0.058), (0.222, 0.060)], 10, tag="bcap").transformed(np.eye(3), (0.008, 0, 0.012)))
        m.merge(_blob((0.0, 0.212, -0.055), 0.022, (1, 0, 0), lod, tag="bcap", stretch=1.5))
    return {"body": Part(m)}


# --- rowboat -----------------------------------------------------------------------------------------------
def _hull_section(t, lod):
    """The hull's cross-section at t (0 the transom, 1 the bow): outer points from the port gunwale
    round the keel to the starboard gunwale, then the inner skin back."""
    B, D = BOAT["beam"], BOAT["depth"]
    b = B / 2 * (1 - max(0.0, (t - 0.35) / 0.65) ** 1.8) ** 0.6 * (0.86 + 0.14 * min(1.0, t / 0.2))
    b = max(b, 0.015)
    yk = 0.30 * max(0.0, (t - 0.55) / 0.45) ** 2.2
    yg = D + 0.12 * t ** 2.5
    n = [7, 5, 3][lod]
    out = []
    for k in range(n):
        u = -1 + 2 * k / (n - 1)
        a = abs(u)
        x = u * b * (0.55 + 0.45 * a ** 0.8)
        y = yk + (yg - yk) * a ** 1.6 + 0.04 * (1 - a) * (1 - t)
        out.append((x, y))
    out[0] = (-b, yg)
    out[-1] = (b, yg)
    th = 0.012
    inner = [(x * (1 - th / max(b, 0.05)), y + th) for x, y in reversed(out)]
    return out + inner, b, yk, yg


def rowboat(lod):
    L = BOAT["len"]
    m = Mesh()
    ns = [18, 10, 6][lod]
    rings, secs = [], []
    for t in np.linspace(0.0, 1.0, ns):
        sec, b, yk, yg = _hull_section(t, lod)
        x = -L / 2 + L * t
        rings.append([(xx, yy, -x) for xx, yy in sec])     # the boat lies along Z, the bow to -Z
        secs.append((x, b, yk, yg))
    m.loft(rings, "hullpaint", caps=(False, True), band_tags=lambda r, j: "alu" if j >= len(rings[0]) // 2 else "hullpaint")
    # the transom: a flat board closing the stern, built as two slabs back to back so both faces show
    sec = _hull_section(0.0, lod)[0]
    m.merge(S.extrude(sec, 0.012, 0.0, "hullpaint", origin=(0, 0, L / 2), right=(-1, 0, 0), up=(0, 1, 0)))
    m.merge(S.extrude(sec, 0.012, 0.0, "alu", origin=(0, 0, L / 2), right=(1, 0, 0), up=(0, 1, 0)))
    if lod < 2:
        # the gunwale rails, the thwarts across, the ribs inside, the oarlocks, two oars laid in her
        for s in (1, -1):
            rail = [(s * b, yg + 0.01, -x) for x, b, yk, yg in secs]
            m.merge(S.sweep(rail, [(-0.012, -0.015), (0.012, -0.015), (0.012, 0.012), (-0.012, 0.012)], "alu"))
        for t in (0.10, 0.45, 0.72):
            sec, b, yk, yg = _hull_section(t, lod)
            z = -(-L / 2 + L * t)
            m.merge(S.chamfer_box((0, yg - 0.13, z), (b - 0.02, 0.012, 0.11), 0.004, "alu") if lod == 0 else S.box((0, yg - 0.13, z), (b - 0.02, 0.012, 0.11), "alu"))
        if lod == 0:
            for t in np.linspace(0.08, 0.85, 8):
                sec, b, yk, yg = _hull_section(t, lod)
                z = -(-L / 2 + L * t)
                inner = sec[len(sec) // 2:]
                m.merge(S.sweep([(px, py + 0.008, z) for px, py in inner], [(-0.01, -0.004), (0.01, -0.004), (0.01, 0.004), (-0.01, 0.004)], "alu", up=(0, 0, 1)))
            sec, b, yk, yg = _hull_section(0.45, lod)
            for s in (1, -1):
                m.merge(S.lathe([(yg + 0.02, 0.012), (yg + 0.07, 0.012), (yg + 0.07, 0.0)], 6, tag="alu").transformed(np.eye(3), (s * b, 0, -(-L / 2 + L * 0.38))))
            for s, tilt in ((1, 0.05), (-1, -0.04)):
                oar = S.lathe([(0.0, 0.0), (0.0, 0.016), (0.10, 0.018), (1.75, 0.022), (1.78, 0.0)], 6, tag="oar")
                oar.merge(S.box((0, 1.95, 0), (0.075, 0.24, 0.007), "oar"))
                m.merge(oar.transformed(S.rotation((1, 0, 0), -np.pi / 2 + abs(tilt)), (s * 0.22, 0.10, 1.2)))
    return {"body": Part(m)}


# --- shoes --------------------------------------------------------------------------------------------------
def _trainer(lod, size=1.0, tags=("sole", "upper", "lace")):
    """A trainer standing on y = 0, the toe to -Z: the sole, the upper lofted heel to toe, the collar
    opening, the laces across the tongue."""
    sole_t, ut, lt = tags
    L, W = 0.28 * size, 0.10 * size
    nst = [9, 6, 4][lod]
    ring_n = [10, 8, 6][lod]
    m = Mesh()
    rings = []
    for k, t in enumerate(np.linspace(0, 1, nst)):        # 0 heel, 1 toe
        z = L / 2 - L * t
        hw = W / 2 * (0.55 + 0.45 * np.sin(np.pi * min(1.0, 0.15 + t * 0.9)) ** 0.6) * (0.92 if t > 0.5 else 1.0)
        top = (0.095 - 0.055 * t ** 1.4) * size
        ring = []
        for a in np.linspace(0, np.pi, ring_n // 2 + 1):
            ring.append((np.cos(a) * hw, 0.03 * size + np.sin(a) * (top - 0.03 * size), z))
        rings.append(ring)
    m.loft(rings, ut, caps=(True, True))
    m = S.weld(m)
    # the sole: a footprint pushed up 3 cm, wider than the upper
    foot = []
    for a in np.linspace(0, 2 * np.pi, [16, 10, 6][lod] + 1)[:-1]:
        zz = np.sin(a) * L / 2 * 1.04
        ww = W / 2 * 1.06 * (0.78 if np.sin(a) > 0 else 1.0)
        foot.append((np.cos(a) * ww, zz))
    m.merge(S.extrude(foot, 0.032 * size, 0.004 * size if lod == 0 else 0.0, sole_t, origin=(0, 0.032 * size, 0), right=(1, 0, 0), up=(0, 0, 1)))
    if lod < 2:
        m.merge(S.chamfer_box((0, 0.088 * size, L * 0.30), (W * 0.30, 0.004, L * 0.14), 0.003, "dark"))      # the collar opening
        if lod == 0:
            for i in range(4):
                z = L * 0.12 - i * 0.025 * size
                y = (0.095 - 0.055 * (0.5 - z / L) ** 1.4) * size + 0.002
                m.merge(S.box((0, y, z), (W * 0.26, 0.003, 0.004), lt))
    return m


def shoes(lod):
    m = Mesh()
    m.merge(_trainer(lod).transformed(S.rotation((0, 1, 0), 0.4), (-0.10, 0, 0.0)))
    # its pair kicked over onto its side, a step away
    side = _trainer(lod, 0.98).transformed(S.rotation((0, 0, 1), np.pi / 2 - 0.12), (0, 0, 0))
    m.merge(side.transformed(S.rotation((0, 1, 0), -1.9), (0.22, 0.05, -0.12)))
    # a woman's leather shoe further off
    m.merge(_trainer(lod, 0.88, ("upper2", "upper2", "upper2")).transformed(S.rotation((0, 1, 0), 2.6), (0.05, 0, 0.30)))
    return {"body": Part(m)}


# --- water_pack -------------------------------------------------------------------------------------------------
def _bottle(lod, crushed=0.0):
    r, h = 0.045, 0.31
    prof = [(0.0, 0.0), (0.0, r * 0.85), (0.012, r), (0.07, r, "label"), (0.17, r), (0.20, r * 0.97), (0.25, r * 0.55),
            (0.275, 0.014, "bcap"), (0.30, 0.015), (h, 0.015), (h, 0.0)]
    if lod == 2:
        prof = [(0.0, 0.0), (0.0, r), (0.20, r), (0.28, 0.015), (h, 0.015), (h, 0.0)]
    flute = (lambda j, y: (1.0 + 0.04 * np.cos(j * 2) * (0.03 < y < 0.07)) * (1.0 - crushed * 0.5 * (1 + np.cos(j * 1.3)) * (0.05 < y < 0.22))) if lod == 0 else None
    return S.lathe(prof, [12, 8, 6][lod], tag="pet", flute=flute)


def water_pack(lod):
    m = Mesh()
    # six bottles in their film, two rows of three, the film's handle loop on top
    for i in range(3):
        for j in range(2):
            m.merge(_bottle(lod).transformed(np.eye(3), (-0.092 + i * 0.092, 0.0, -0.046 + j * 0.092)).set_unit(i * 2 + j + 1))
    if lod < 2:
        m.merge(S.lathe([(0.08, 0.200), (0.12, 0.200)], 4, turn=np.pi / 4, tag="film", caps=(False, False)).transformed(np.diag([1.0, 1.0, 0.69]), (0, 0, 0)))
        m.merge(S.sweep([(0, 0.31, -0.03), (0, 0.36, -0.02), (0, 0.37, 0.0), (0, 0.36, 0.02), (0, 0.31, 0.03)], [(-0.02, -0.001), (0.02, -0.001), (0.02, 0.001), (-0.02, 0.001)], "film", up=(1, 0, 0)))
    # one loose bottle lying, one crushed
    m.merge(S.along(_bottle(lod), (1, 0, 0.4), (0.18, 0.045, 0.16)).set_unit(7))
    if lod < 2:
        m.merge(S.along(_bottle(lod, crushed=0.6), (-0.3, 0, 1), (-0.22, 0.035, 0.22)).set_unit(8))
    return {"body": Part(m)}


# --- clothes_pile ------------------------------------------------------------------------------------------
def _garment(rng, lod, unit):
    """A dropped garment: a sheet lying in folds over what is under it, a sleeve or leg trailing."""
    w, l = rng.uniform(0.35, 0.55), rng.uniform(0.40, 0.65)
    nx, nz = [5, 3, 2][lod], [5, 3, 2][lod]
    ph = rng.uniform(0, 6.28, 3)
    top = []
    for j in range(nz + 1):
        for i in range(nx + 1):
            u, v = i / nx - 0.5, j / nz - 0.5
            y = 0.03 + 0.06 * np.cos(np.pi * u) * np.cos(np.pi * v) + 0.025 * np.sin(u * 9 + ph[0]) * np.cos(v * 7 + ph[1])
            top.append((u * w, max(0.01, y), v * l))
    m = Mesh()
    t0 = m.add(top)
    b0 = m.add([(x, y - 0.012, z) for x, y, z in top])
    k = nx + 1
    for j in range(nz):
        for i in range(nx):
            a = j * k + i
            m.face([t0 + a, t0 + a + k, t0 + a + k + 1, t0 + a + 1], "cloth", unit)
            m.face([b0 + a, b0 + a + 1, b0 + a + k + 1, b0 + a + k], "cloth", unit)
    ring = [j * k for j in range(nz + 1)] + [nz * k + i for i in range(1, nx + 1)] + [j * k + nx for j in range(nz - 1, -1, -1)] + list(range(nx - 1, 0, -1))
    for q in range(len(ring)):
        a, b = ring[q], ring[(q + 1) % len(ring)]
        m.face([t0 + b, t0 + a, b0 + a, b0 + b], "cloth", unit)
    if lod < 2:  # a sleeve trailing off it
        sl = [(w / 2 - 0.02, 0.04, 0.0), (w / 2 + 0.12, 0.03, 0.06), (w / 2 + 0.25, 0.02, 0.02)]
        m.merge(S.sweep(sl, [(np.cos(a) * 0.045, np.sin(a) * 0.022) for a in np.linspace(0, 2 * np.pi, 7)[:-1]], "cloth").set_unit(unit))
    return m


def clothes_pile(lod):
    rng = np.random.default_rng(31)
    m = Mesh()
    for i in range([7, 4, 2][lod]):
        g = _garment(rng, lod, i % 6 + 1)
        lift = 0.035 * min(i, 3)
        m.merge(g.transformed(S.rotation((0, 1, 0), rng.uniform(0, np.pi)), (rng.normal(0, 0.12), lift, rng.normal(0, 0.10))))
    if lod < 2:  # a shoe and a scarf among them
        m.merge(_trainer(lod, 0.9, ("sole", "upper2", "upper2")).transformed(S.rotation((0, 0, 1), 1.5) @ S.rotation((0, 1, 0), 0.7), (0.35, 0.05, 0.25)))
        scarf = [(-0.45 + 0.08 * k, 0.01 + 0.02 * np.sin(k), -0.30 + 0.04 * np.sin(k * 1.7)) for k in range(8)]
        m.merge(S.sweep(scarf, [(-0.07, -0.006), (0.07, -0.006), (0.07, 0.006), (-0.07, 0.006)], "cloth", up=(0, 1, 0)).set_unit(6))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "trolley": dict(build=trolley, materials=materials(), edge_radius=0.002, close=(0.0, 0.9, 0.3), **_SPEC),
    "plastic_chair": dict(build=plastic_chair, materials=materials(), edge_radius=0.003, close=(0.0, 0.5, 0.0), **_SPEC),
    "pram": dict(build=pram, materials=materials(), edge_radius=0.003, close=(0.2, 0.6, 0.3), **_SPEC),
    "suitcase_hard": dict(build=suitcase_hard, materials=materials(), edge_radius=0.003, close=(0.0, 0.4, -0.13), **_SPEC),
    "suitcase_soft": dict(build=suitcase_soft, materials=materials(), edge_radius=0.003, close=(0.0, 0.1, -0.2), **_SPEC),
    "mattress": dict(build=mattress, materials=materials(), edge_radius=0.004, close=(0.6, 0.2, -0.7), **_SPEC),
    "teddy_bear": dict(build=teddy_bear, materials=materials(), edge_radius=0.002, close=(0.0, 0.2, -0.1), **_SPEC),
    "rowboat": dict(build=rowboat, materials=materials(), edge_radius=0.003, close=(0.0, 0.4, -1.2), **_SPEC),
    "shoes": dict(build=shoes, materials=materials(), edge_radius=0.002, close=(0.0, 0.05, 0.0), **_SPEC),
    "water_pack": dict(build=water_pack, materials=materials(), edge_radius=0.002, close=(0.0, 0.2, -0.1), **_SPEC),
    "clothes_pile": dict(build=clothes_pile, materials=materials(), edge_radius=0.002, close=(0.0, 0.1, 0.0), **_SPEC),
}
