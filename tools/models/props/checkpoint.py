"""Barricades and checkpoint gear (S185). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

barrier_crowd: the grey crowd barrier of French streets (stacked, deauville): a 2.0 m galvanised
frame of tube, its bars, two bent flat feet, hooks at one end and eyes at the other so they chain.
barrier_concrete: the concrete safety barrier (jersey): the New Jersey profile, 2.0 m long, its
lifting holes, the drain notches at its foot, the joint keys at its ends.
sandbag_wall: a 1.2 m module of a sandbag wall (close, flood): a course of stretchers two deep, a
course of headers across, another of stretchers; each bag slumped, its tied ear.
wire_coil: concertina wire on pickets (coil, on_wall): a 3 m coil of loops, a straight wire along
its top, angle-iron pickets at its ends and middle.
traffic_cone: the 0.75 m road cone: its square foot, the orange cone and its two white bands.

Standing on y = 0, x the run's length (modules join end to end), the front -Z.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

CROWD = dict(len=2.00, h=1.10, tube=0.020, bars=16)
JERSEY = dict(len=2.00, prof=[(0.30, 0.0), (0.30, 0.075), (0.20, 0.33), (0.075, 0.80)])
BAG = dict(l=0.60, w=0.34, h=0.17)
COIL = dict(len=3.00, r=0.45, pitch=0.22, wire=0.0035)
CONE = dict(h=0.75, base=0.38, r0=0.15, r1=0.025)
WORKS = dict(len=2.00, h=1.00, boards=(0.86, 0.30))
WATER = dict(len=1.50, prof=[(0.22, 0.0), (0.22, 0.12), (0.10, 0.80)])
BODYBAG = dict(len=2.20, w=0.80)
TAPE = dict(len=4.00)
TARP = dict(w=2.60, d=2.10)
BARR = dict(len=4.00, d=1.70, h=1.20)


def materials():
    return {
        "galv": Material((0.66, 0.67, 0.66), under=(0.55, 0.56, 0.55), bare=(0.42, 0.30, 0.20), chip=0.3, grain=0.10),
        "concrete": Material((0.66, 0.65, 0.61), kind="concrete", chip=0.0, rusts=False, grain=0.18),
        "dark": Material((0.08, 0.08, 0.08), chip=0.0, rusts=False, grain=0.02, fades=False),
        "bag": Material((0.58, 0.52, 0.38), kind="paper", chip=0.0, rusts=False, grain=0.22,
                        palette=[(0.58, 0.52, 0.38), (0.54, 0.49, 0.36), (0.61, 0.55, 0.41), (0.50, 0.46, 0.34)], vary=0.06),
        "tie": Material((0.40, 0.35, 0.26), kind="paper", chip=0.0, rusts=False, grain=0.1),
        "wire": Material((0.50, 0.50, 0.48), under=(0.45, 0.45, 0.44), bare=(0.40, 0.26, 0.16), chip=0.2, grain=0.08),
        "picket": Material((0.25, 0.27, 0.22), under=(0.35, 0.22, 0.14), bare=(0.38, 0.22, 0.12), chip=0.6, grain=0.08),
        "orange": Material((0.85, 0.28, 0.06), kind="rubber", chip=0.0, rusts=False, grain=0.06),
        "band": Material((0.92, 0.92, 0.90), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "base": Material((0.12, 0.12, 0.12), kind="rubber", chip=0.0, rusts=False, grain=0.06),
        "rw": Material((0.92, 0.92, 0.90), under=(0.6, 0.6, 0.58), bare=(0.45, 0.45, 0.44), chip=0.3, grain=0.05),
        "lamp": Material((0.95, 0.55, 0.08), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.55, 0.10)),
        "smv": Material((0.90, 0.89, 0.85), kind="rubber", chip=0.0, rusts=False, grain=0.05),
        "cap": Material((0.10, 0.10, 0.10), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "bagblack": Material((0.075, 0.075, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.05),
        "zip": Material((0.03, 0.03, 0.03), kind="rubber", chip=0.0, rusts=False, grain=0.02),
        "tape": Material((0.93, 0.93, 0.91), kind="paper", chip=0.0, rusts=False, grain=0.03),
        "tarp": Material((0.12, 0.32, 0.62), kind="rubber", chip=0.0, rusts=False, grain=0.08),
        "rope": Material((0.75, 0.70, 0.55), kind="paper", chip=0.0, rusts=False, grain=0.15),
        "sett": Material((0.52, 0.51, 0.49), kind="stone", chip=0.0, rusts=False, grain=0.20,
                         palette=[(0.52, 0.51, 0.49), (0.46, 0.45, 0.44), (0.57, 0.55, 0.52), (0.49, 0.47, 0.46), (0.42, 0.42, 0.41)], vary=0.08),
        "earth": Material((0.30, 0.25, 0.19), kind="sand", chip=0.0, rusts=False, grain=0.25),
        "timber": Material((0.42, 0.36, 0.28), under=(0.36, 0.30, 0.22), bare=(0.48, 0.40, 0.30), kind="wood", chip=0.5, rusts=False, grain=0.18),
        "iron": Material((0.18, 0.17, 0.16), under=(0.30, 0.20, 0.13), bare=(0.38, 0.22, 0.12), chip=0.5, grain=0.08),
    }


# --- barrier_crowd ---------------------------------------------------------------------------------------
def barrier_crowd(lod):
    L, H, t, nb = CROWD["len"], CROWD["h"], CROWD["tube"], CROWD["bars"]
    m = Mesh()
    sides = [8, 6, 4][lod]
    y0, y1 = 0.12, H
    frame = S.fillet([(-L / 2, y0, 0), (-L / 2, y1, 0), (L / 2, y1, 0), (L / 2, y0, 0)], 0.06 if lod < 2 else 0.0, 3)
    m.merge(S.sweep(frame, S.circle(t, sides), "galv", up=(0, 0, 1)))
    m.merge(S.sweep([(-L / 2, y0 + 0.04, 0), (L / 2, y0 + 0.04, 0)], S.circle(t * 0.9, sides), "galv"))
    if lod < 2:
        n = nb if lod == 0 else nb // 2
        for i in range(n):
            x = -L / 2 + (i + 1) * L / (n + 1)
            m.merge(S.sweep([(x, y0 + 0.04, 0), (x, y1, 0)], S.circle(0.009, [5, 4][lod]), "galv"))
    # the feet: a flat bar bent into a low bridge under each end, the legs into it
    for x in (-L / 2 + 0.08, L / 2 - 0.08):
        foot = [(x, 0.0, -0.33), (x, 0.06, -0.24), (x, 0.08, 0.0), (x, 0.06, 0.24), (x, 0.0, 0.33)]
        m.merge(S.sweep(foot, [(-0.025, -0.004), (0.025, -0.004), (0.025, 0.004), (-0.025, 0.004)], "galv", up=(1, 0, 0)))
        m.merge(S.sweep([(x, 0.08, 0), (np.sign(x) * L / 2, y0, 0)], S.circle(t * 0.9, sides), "galv"))  # the leg from the foot up into the frame
    if lod == 0:  # the hooks at the right end, the eyes at the left
        for y in (0.30, H - 0.15):
            m.merge(S.sweep([(L / 2, y, 0), (L / 2 + 0.05, y, 0), (L / 2 + 0.05, y - 0.05, 0)], S.circle(0.006, 4), "galv"))
            ring = [(-L / 2 - 0.03 + np.cos(a) * 0.022, y, np.sin(a) * 0.022) for a in np.linspace(0, 2 * np.pi, 7)[:-1]]
            m.merge(S.sweep(ring, S.circle(0.005, 4), "galv", closed=True))
    return {"body": Part(m)}


# --- barrier_concrete ------------------------------------------------------------------------------------
def barrier_concrete(lod):
    L = JERSEY["len"]
    prof = JERSEY["prof"]
    outline = [(-z, y) for z, y in prof] + [(z, y) for z, y in reversed(prof)]
    c = 0.02 if lod == 0 else 0.0
    m = S.extrude([(z, y) for z, y in outline], L, c, "concrete", origin=(-L / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0))
    if lod < 2:
        for x in (-0.55, 0.55):  # the lifting holes through the top, the drain notches at the foot
            m.merge(S.box((x, 0.70, 0), (0.06, 0.04, 0.09), "dark"))
        for x in (-0.45, 0.45):
            for s in (1, -1):
                m.merge(S.box((x, 0.04, s * 0.30), (0.10, 0.04, 0.004), "dark"))
    if lod == 0:  # the joint key standing out of one end
        m.merge(S.box((L / 2 + 0.03, 0.40, 0), (0.03, 0.20, 0.05), "concrete"))
    return {"body": Part(m)}


# --- sandbag_wall ------------------------------------------------------------------------------------------
def _bag(c, along_x, lod, seed):
    """One filled bag lying flat at c: slumped (thinner at its ends, bellied), turned a little."""
    l, w, h = BAG["l"], BAG["w"], BAG["h"]
    rng = np.random.default_rng(seed)
    nx, nr = [7, 5, 3][lod], [10, 8, 4][lod]
    e = 2.0 / 2.6                                            # a superellipse: a pillow, not a box nor a tube
    rings = []
    for x in np.linspace(-l / 2, l / 2, nx):
        s = max(0.0, 1.0 - abs(2 * x / l) ** 3) ** 0.5       # full in the middle, pinched to the seams at the ends
        hy, hz = h / 2 * (0.30 + 0.70 * s), w / 2 * (0.70 + 0.30 * s)
        ring = []
        for a in np.linspace(0, 2 * np.pi, nr + 1)[:-1] + np.pi / nr:
            cs, sn = np.cos(a), np.sin(a)
            y = hy * np.sign(sn) * abs(sn) ** e
            z = hz * np.sign(cs) * abs(cs) ** e
            ring.append((x, y * (0.75 if y < 0 else 1.0), z))  # its belly flattened by its weight
        rings.append(np.array(ring))
    b = Mesh()
    b.loft(rings, "bag", caps=(True, True))
    b = S.weld(b)
    if lod == 0:  # the tied ear at one end
        b.merge(S.prism((l / 2 - 0.01, 0.0, 0.0), 0.025, 0.05, 5, axis=(1, 0, 0), tag="tie"))
    R = S.rotation((0, 1, 0), (0.0 if along_x else np.pi / 2) + rng.uniform(-0.06, 0.06)) @ S.rotation((1, 0, 0), rng.uniform(-0.03, 0.03))
    return b.transformed(R, c).set_unit(seed)


def sandbag_wall(lod):
    l, w, h = BAG["l"], BAG["w"], BAG["h"]
    m = Mesh()
    unit = 1
    rng = np.random.default_rng(11)
    yc = h / 2 * 0.95
    for course in range(3):
        y = yc + course * h * 0.88
        if course % 2 == 0:  # stretchers, two deep
            for z in (-w / 2, w / 2):
                for x in (-l / 2, l / 2):
                    m.merge(_bag((x + rng.uniform(-0.02, 0.02), y, z * 0.95), True, lod, unit))
                    unit += 1
        else:  # headers across the wall
            for x in (-0.40, 0.0, 0.40):
                m.merge(_bag((x + rng.uniform(-0.015, 0.015), y, 0.0), False, lod, unit))
                unit += 1
    return {"body": Part(m)}


# --- wire_coil ------------------------------------------------------------------------------------------
def wire_coil(lod):
    L, r, p, wr = COIL["len"], COIL["r"], COIL["pitch"], COIL["wire"]
    m = Mesh()
    seg = [16, 9, 6][lod]
    loops = int(L / p)
    pts = []
    for k in range(loops * seg + 1):
        a = 2 * np.pi * k / seg
        x = -L / 2 + L * k / (loops * seg)
        pts.append((x + 0.04 * np.sin(a), r + np.sin(a) * r * 0.98, np.cos(a) * r))   # a helix, each loop leaning a little
    m.merge(S.sweep(pts, S.circle(wr, 3), "wire"))
    if lod == 0:  # the razor barbs: small flat blades along the wire
        for k in range(0, len(pts), 3):
            x, y, z = pts[k]
            m.merge(S.box((x, y, z), (0.012, 0.004, 0.0008), "wire"))
    # the pickets: angle iron driven into the ground, the straight wire along the top
    for x in (-L / 2, 0.0, L / 2):
        pk = S.extrude([(0.0, 0.0), (0.04, 0.0), (0.04, 0.005), (0.005, 0.005), (0.005, 0.04), (0.0, 0.04)], 1.15, 0.0, "picket",
                       origin=(x - 0.02, 1.15, 0.02), right=(1, 0, 0), up=(0, 0, -1))  # pushed down from 1.15 to the ground
        m.merge(pk)
    if lod < 2:
        m.merge(S.cable((-L / 2, 1.10, 0.0), (L / 2, 1.10, 0.0), 0.04, r=0.003, n=[10, 5][lod], sides=3, tag="wire"))
    return {"body": Part(m)}


# --- traffic_cone -----------------------------------------------------------------------------------------
def traffic_cone(lod):
    h, b, r0, r1 = CONE["h"], CONE["base"], CONE["r0"], CONE["r1"]
    m = Mesh()
    c = 0.04 if lod < 2 else 0.0
    base = [(-b / 2 + c, -b / 2), (b / 2 - c, -b / 2), (b / 2, -b / 2 + c), (b / 2, b / 2 - c), (b / 2 - c, b / 2), (-b / 2 + c, b / 2), (-b / 2, b / 2 - c), (-b / 2, -b / 2 + c)]
    m.merge(S.extrude(base, 0.03, 0.006 if lod == 0 else 0.0, "base", origin=(0, 0.0, 0), right=(1, 0, 0), up=(0, 0, 1)))  # pushed up from the ground
    sides = [16, 10, 6][lod]

    def rad(y):
        return r0 + (r1 - r0) * (y - 0.03) / (h - 0.03)

    bands = [(0.03, "orange"), (0.30, "band"), (0.40, "orange"), (0.50, "band"), (0.58, "orange")]
    prof = [(y, rad(y), t) for y, t in bands] + [(h - 0.01, rad(h - 0.01), "orange"), (h, r1 * 0.8, "orange"), (h, 0.0, "orange")]
    if lod == 2:
        prof = [(0.03, r0), (h, r1), (h, 0.0)]
    m.merge(S.lathe(prof, sides, tag="orange", caps=(False, False)))
    return {"body": Part(m)}


# --- works_barrier ----------------------------------------------------------------------------------------
def works_barrier(lod):
    L, H = WORKS["len"], WORKS["h"]
    m = Mesh()
    sides = [8, 6, 4][lod]
    y0 = 0.10
    frame = S.fillet([(-L / 2, y0, 0), (-L / 2, H, 0), (L / 2, H, 0), (L / 2, y0, 0)], 0.05 if lod < 2 else 0.0, 3)
    m.merge(S.sweep(frame, S.circle(0.021, sides), "galv", up=(0, 0, 1)))
    # the two striped boards, their edges folded back
    for yc in WORKS["boards"]:
        if lod == 0:
            m.merge(S.chamfer_box((0, yc, 0), (L / 2 - 0.03, 0.105, 0.009), 0.004, "rw"))
        else:
            m.merge(S.box((0, yc, 0), (L / 2 - 0.03, 0.105, 0.009), "rw"))
    if lod < 2:  # the bars between them
        ya, yb = WORKS["boards"][0] + 0.105, WORKS["boards"][1] - 0.105
        for i in range([13, 6][lod]):
            x = -L / 2 + (i + 1) * L / ([13, 6][lod] + 1)
            m.merge(S.sweep([(x, ya, 0), (x, yb, 0)], S.circle(0.008, [5, 4][lod]), "galv"))
    # the feet: a moulded plastic shoe under each upright, its slot and its toe
    for x in (-L / 2, L / 2):
        if lod < 2:
            m.merge(S.chamfer_box((x, 0.065, 0), (0.07, 0.065, 0.30), 0.03, "base", edges="top"))
            m.merge(S.box((x, 0.135, 0), (0.035, 0.01, 0.035), "dark"))
        else:
            m.merge(S.box((x, 0.065, 0), (0.07, 0.065, 0.30), "base"))
    if lod == 0:  # the flasher clamped on the top left, its battery box under the lens; the clip joints at the ends
        bx = -L / 2 + 0.25
        m.merge(S.chamfer_box((bx, H + 0.06, 0), (0.06, 0.05, 0.04), 0.008, "base"))
        m.merge(S.lathe([(H + 0.11, 0.055), (H + 0.15, 0.06), (H + 0.20, 0.045), (H + 0.215, 0.0)], 10, tag="lamp").transformed(np.eye(3), (bx, 0, 0)))
        for s in (1, -1):
            for y in (0.35, H - 0.15):
                m.merge(S.box((s * (L / 2 + 0.025), y, 0), (0.012, 0.03, 0.012), "galv"))
    return {"body": Part(m)}


def _paint_rw(P, N, tag, tags, state, col):
    """Red and white diagonal bands on the boards and the posts; the tape's blocks."""
    out = col
    if "rw" in tags:
        sel = tag == tags.index("rw")
        red = np.mod(np.floor((P[:, 0] - P[:, 1]) / 0.20), 2) == 0
        out = np.where((sel & red)[:, None], np.array([0.72, 0.08, 0.06], np.float32), out)
    if "tape" in tags:
        sel = tag == tags.index("tape")
        red = np.mod(np.floor((P[:, 0] + P[:, 1] * 0.8 + P[:, 2] * 0.3) / 0.09), 2) == 0
        out = np.where((sel & red)[:, None], np.array([0.78, 0.07, 0.06], np.float32), out)
    return out


# --- water_barrier ----------------------------------------------------------------------------------------
def water_barrier(lod):
    L, prof = WATER["len"], WATER["prof"]
    outline = [(-z, y) for z, y in prof] + [(z, y) for z, y in reversed(prof)]
    m = S.extrude(outline, L, 0.03 if lod == 0 else (0.015 if lod == 1 else 0.0), "smv", origin=(-L / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0))
    (zb, _), (zk, yk), (zt, yt) = prof[0], prof[1], prof[-1]
    if lod < 2:
        # the bays: moulded ribs up the sloping faces, the forklift slots through the foot
        for x in np.linspace(-L / 2, L / 2, 4)[1:-1]:
            for s in (1, -1):
                rib = [(x, yk, s * (zk + 0.012)), (x, yt - 0.05, s * (zt + 0.012))]
                m.merge(S.sweep(rib, [(-0.03, -0.012), (0.03, -0.012), (0.03, 0.0), (-0.03, 0.0)], "smv", up=(0, 0, s)))
        for x in (-L / 4, L / 4):
            m.merge(S.box((x, 0.06, 0), (0.12, 0.045, zb + 0.004), "cap"))
        # the filling caps on the top, the drain plug at the foot
        for x in (-L / 3, L / 3):
            m.merge(S.lathe([(yt - 0.005, 0.065), (yt + 0.012, 0.065), (yt + 0.016, 0.05), (yt + 0.016, 0.0)], [12, 8][lod], tag="cap").transformed(np.eye(3), (x, 0, 0)))
        m.merge(S.along(S.lathe([(0.0, 0.03), (0.02, 0.03), (0.02, 0.0)], 8, tag="cap"), (0, 0, -1), (L / 2 - 0.15, 0.05, -zb + 0.002)))
    # the knuckles that lock one to the next: two on one end, one on the other
    for x, ys in ((L / 2 + 0.04, (0.12, 0.52)), (-L / 2 - 0.04, (0.32,))):
        for y in ys:
            m.merge(S.lathe([(y, 0.0), (y, 0.05), (y + 0.16, 0.05), (y + 0.16, 0.0)], [10, 6, 4][lod], tag="smv").transformed(np.eye(3), (x, 0, 0)))
    return {"body": Part(m)}


# --- body_bag ---------------------------------------------------------------------------------------------
def body_bag(lod):
    BL, BW = BODYBAG["len"], BODYBAG["w"]
    # the body under the sheet, along +X from the feet: (x, half width of the body, its height)
    body = [(0.00, 0.10, 0.05), (0.06, 0.15, 0.16), (0.14, 0.16, 0.12), (0.45, 0.20, 0.13), (0.80, 0.23, 0.17),
            (1.05, 0.25, 0.20), (1.30, 0.26, 0.22), (1.48, 0.27, 0.21), (1.58, 0.14, 0.13), (1.70, 0.12, 0.17), (1.86, 0.12, 0.17), (1.95, 0.06, 0.08)]
    xs, ws, hs = (np.array(c) for c in zip(*body))
    nst = [26, 14, 7][lod]
    nz = [14, 9, 5][lod]
    rings = []
    for x in np.linspace(-0.08, BL - 0.08, nst):
        t = np.clip((x + 0.08) / BL, 0, 1)
        end = np.sin(np.pi * t) ** 0.25                      # the bag's rounded ends
        hz = BW / 2 * max(end, 0.25)
        bw = np.interp(x, xs, ws) if 0 <= x <= xs[-1] else 0.04
        bh = np.interp(x, xs, hs) if 0 <= x <= xs[-1] else 0.02
        ring = []
        for z in np.linspace(-hz, hz, nz):
            u = min(1.0, abs(z) / max(bw * 1.25, 1e-3))
            y = 0.012 + bh * (1 - u * u) ** 1.4 * (1.0 if abs(z) < hz * 0.98 else 0.0)
            ring.append((x - BL / 2 + 0.08, y, z))
        ring += [(x - BL / 2 + 0.08, 0.0, z) for z in np.linspace(hz, -hz, 3)[1:-1]]
        rings.append(np.array(ring))
    m = Mesh()
    m.loft(rings, "bagblack", caps=(True, True))
    m = S.weld(m)
    if lod < 2:  # the zip along the top, curving round the head end
        zp = []
        for x in np.linspace(0.10, 1.90, [24, 10][lod]):
            bh = np.interp(x, xs, hs)
            bw = np.interp(x, xs, ws)
            z = 0.07
            u = min(1.0, z / (bw * 1.25))
            zp.append((x - BL / 2 + 0.08, 0.012 + bh * (1 - u * u) ** 1.4 + 0.004, -z))
        m.merge(S.sweep(zp, [(-0.008, -0.002), (0.008, -0.002), (0.008, 0.002), (-0.008, 0.002)], "zip"))
        if lod == 0:  # the pull, and the carrying handles along each side
            m.merge(S.box(zp[-1], (0.02, 0.004, 0.008), "galv"))
            for x in (0.35, 0.95, 1.55):
                for s in (1, -1):
                    m.merge(S.chamfer_box((x - BL / 2 + 0.08, 0.02, s * (BW / 2 - 0.02)), (0.07, 0.008, 0.025), 0.004, "zip"))
    return {"body": Part(m)}


# --- police_tape ------------------------------------------------------------------------------------------
def _post(x, lod):
    """A red and white stake in its rubber foot."""
    m = Mesh()
    m.merge(S.lathe([(0.0, 0.17), (0.03, 0.17), (0.045, 0.06), (0.10, 0.04), (0.10, 0.0)], [12, 8, 6][lod], tag="base"))
    prof = [(0.10, 0.022, "rw")] + ([(y, 0.022, "rw") for y in np.arange(0.30, 1.0, 0.20)] if lod < 2 else []) + [(1.0, 0.022), (1.0, 0.0)]
    m.merge(S.lathe(prof, [8, 6, 4][lod], tag="rw"))
    return m.transformed(np.eye(3), (x, 0, 0))


def _ribbon(path, width, twist, tag, thick=0.0008):
    """A thin flat ribbon along `path`, its width turned by `twist[i]` about the run."""
    P = np.array(path, float)
    rings = []
    for i, c in enumerate(P):
        d = P[min(i + 1, len(P) - 1)] - P[max(i - 1, 0)]
        d /= np.linalg.norm(d)
        side = np.cross(d, (0, 1, 0))
        side = side / (np.linalg.norm(side) + 1e-9)
        up = np.cross(side, d)
        w = np.cos(twist[i]) * up + np.sin(twist[i]) * side
        n = np.cross(d, w)
        rings.append([c - w * width / 2 - n * thick, c + w * width / 2 - n * thick, c + w * width / 2 + n * thick, c - w * width / 2 + n * thick])
    m = Mesh()
    m.loft(rings, tag, caps=(True, True))
    return m


def police_tape(lod):
    L = TAPE["len"]
    m = Mesh()
    for x in (-L / 2, L / 2):
        m.merge(_post(x, lod))
    n = [40, 18, 8][lod]
    ts = np.linspace(0, 1, n + 1)
    run = [(-L / 2 + L * t, 0.93 - 0.16 * 4 * t * (1 - t), -0.024 + 0.05 * np.sin(np.pi * t) ** 2) for t in ts]
    twist = [0.9 * np.sin(np.pi * t * 3.0) * np.sin(np.pi * t) for t in ts]
    m.merge(_ribbon(run, 0.075, twist, "tape"))
    if lod < 2:  # the loose end blowing off the far stake, the knots round both
        k = [14, 6][lod]
        tail = [(L / 2 + 0.03 + 0.25 * s + 0.05 * np.sin(s * 9), 0.92 - 0.85 * s ** 1.3, -0.03 - 0.12 * s) for s in np.linspace(0, 1, k)]
        m.merge(_ribbon(tail, 0.075, [0.4 + 1.6 * s for s in np.linspace(0, 1, k)], "tape"))
        for x in (-L / 2, L / 2):
            m.merge(S.lathe([(0.89, 0.026), (0.97, 0.026)], [8, 6][lod], tag="tape", caps=(True, True)).transformed(np.eye(3), (x, 0, 0)))
    return {"body": Part(m)}


# --- tarp ---------------------------------------------------------------------------------------------------
def _drape(lod):
    """The tarp's height over the ground at (x, z): laid over two crates and a drum, slumping to
    the ground, folds running down its skirts."""
    under = [((-0.45, 0.10), (0.38, 0.32), 0.78), ((0.40, -0.05), (0.30, 0.42), 0.55), ((0.55, 0.45), (0.25, 0.25), 0.92)]
    rng = np.random.default_rng(5)
    folds = [(rng.uniform(0, 2 * np.pi), rng.uniform(5, 9), rng.uniform(0.02, 0.05)) for _ in range(4)]

    r = 0.20   # how round the cloth goes over a corner

    def h(x, z):
        tops = [0.0]
        for (cx, cz), (hx, hz), hh in under:
            g = np.hypot(max(0.0, abs(x - cx) - hx + r), max(0.0, abs(z - cz) - hz + r))
            drop = 1.3 * g * g / (2 * r) if g < r else 1.3 * (g - r / 2) + 0.5 * (g - r) ** 2
            tops.append(hh - drop)
        tops = np.array(tops)
        top = np.log(np.sum(np.exp(14 * tops))) / 14          # a soft max: the cloth sags between the things under it
        top = max(top, 0.0)
        a = np.arctan2(z - 0.1, x)
        wr = sum(amp * np.sin(k * a + ph) for ph, k, amp in folds)
        return max(0.004, top + wr * min(1.0, top / 0.3) * (1.0 if top < 0.7 else 0.3))
    return h


def tarp(lod):
    W, D = TARP["w"], TARP["d"]
    h = _drape(lod)
    nx, nz = [28, 16, 9][lod], [22, 12, 7][lod]
    m = Mesh()
    top, bot = [], []
    for j in range(nz + 1):
        for i in range(nx + 1):
            x = -W / 2 + W * i / nx
            z = -D / 2 + D * j / nz
            edge = 0.03 * np.sin(x * 7 + z * 3) * (1 if i in (0, nx) or j in (0, nz) else 0)
            y = h(x, z)
            top.append((x + edge, y, z))
            bot.append((x + edge, max(0.0, y - 0.004), z))
    t0, b0 = m.add(top), m.add(bot)
    w = nx + 1
    for j in range(nz):
        for i in range(nx):
            a = j * w + i
            m.face([t0 + a, t0 + a + w, t0 + a + w + 1, t0 + a + 1], "tarp")
            m.face([b0 + a, b0 + a + 1, b0 + a + w + 1, b0 + a + w], "tarp")
    ring = [j * w for j in range(nz + 1)] + [nz * w + i for i in range(1, nx + 1)] + [j * w + nx for j in range(nz - 1, -1, -1)] + [i for i in range(nx - 1, 0, -1)]
    for k in range(len(ring)):
        a, b = ring[k], ring[(k + 1) % len(ring)]
        m.face([t0 + b, t0 + a, b0 + a, b0 + b], "tarp")
    if lod < 2:  # the eyelets along the hem, a rope pegged out from two corners
        for k in range(0, len(ring), [4, 8][lod]):
            p = np.array(top[ring[k]]) + (0, 0.002, 0)
            m.merge(S.lathe([(-0.001, 0.012), (0.003, 0.012), (0.003, 0.0)], 6, tag="galv").transformed(np.eye(3), p))
        if lod == 0:
            for c in (top[0], top[nx]):
                c = np.array(c)
                peg = c + np.array([np.sign(c[0]) * 0.35, 0, -0.30])
                m.merge(S.cable(c + (0, 0.01, 0), peg + (0, 0.05, 0), 0.03, r=0.004, n=6, sides=4, tag="rope"))
                m.merge(S.box(peg + (0, 0.03, 0), (0.008, 0.04, 0.008), "galv"))
    return {"body": Part(m)}


# --- sett_barricade ---------------------------------------------------------------------------------------
def _barrel(c, axis, lod, unit):
    prof = [(0.0, 0.0), (0.0, 0.25), (0.05, 0.27, "iron"), (0.09, 0.28), (0.36, 0.30, "iron"), (0.40, 0.30), (0.67, 0.28, "iron"),
            (0.71, 0.27), (0.76, 0.25), (0.76, 0.0)]
    if lod == 2:
        prof = [(0.0, 0.0), (0.0, 0.25), (0.38, 0.30), (0.76, 0.25), (0.76, 0.0)]
    b = S.lathe(prof, [14, 9, 6][lod], tag="timber", flute=(lambda j, y: 1.0 + 0.012 * (j % 2)) if lod == 0 else None)
    return S.along(b, axis, c).set_unit(unit)


def _cart(lod):
    """A handcart tipped up against the heap: its bed, two big spoked wheels, the shafts."""
    m = Mesh()
    m.merge(S.chamfer_box((0, 0.15, 0), (0.70, 0.04, 0.45), 0.01, "timber") if lod < 2 else S.box((0, 0.15, 0), (0.70, 0.04, 0.45), "timber"))
    for s in (1, -1):
        m.merge(S.box((0, 0.30, s * 0.43), (0.70, 0.12, 0.02), "timber"))
        m.merge(S.box((1.25, 0.15, s * 0.30), (0.60, 0.03, 0.03), "timber"))     # a shaft
        r = 0.55
        hub = np.array([0.0, 0.0, s * 0.55])
        rim = [hub + (np.cos(a) * r, np.sin(a) * r, 0) for a in np.linspace(0, 2 * np.pi, [20, 12, 8][lod] + 1)[:-1]]
        m.merge(S.sweep(rim, [(-0.035, -0.025), (0.035, -0.025), (0.035, 0.025), (-0.035, 0.025)], "timber", closed=True, up=(0, 0, 1)))
        if lod < 2:
            for a in np.linspace(0, 2 * np.pi, [12, 8][lod] + 1)[:-1]:
                m.merge(S.sweep([hub, hub + (np.cos(a) * (r - 0.03), np.sin(a) * (r - 0.03), 0)], S.circle(0.014, 4), "timber"))
            m.merge(S.along(S.lathe([(-0.07, 0.07), (0.07, 0.07)], 8, tag="iron"), (0, 0, 1), hub))
    m.merge(S.sweep([(0, 0, -0.62), (0, 0, 0.62)], S.circle(0.03, [6, 4, 4][lod]), "iron"))    # the axle
    return m


def sett_barricade(lod):
    L, D, H = BARR["len"], BARR["d"], BARR["h"]
    rng = np.random.default_rng(1871)
    m = Mesh()
    # the heap's core: earth and broken setts banked across the street
    prof = [(-D / 2, 0.0), (-0.22, H - 0.12), (-0.05, H), (0.18, H - 0.10), (D / 2, 0.0)]
    core = S.extrude(prof, L, 0.0, "earth", origin=(-L / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0))
    for s in (1, -1):  # its ends slumped, not cut square
        nrm = np.array([s * 1.0, 0.8, 0.0]) / np.hypot(1.0, 0.8)
        core = S.clip(core, (s * (L / 2 - 0.45), H * 0.5, 0), nrm, cap_tag="earth")
    m.merge(core)
    # setts laid in courses up both faces and along the crest
    step_x, step_s = [(0.22, 0.15), (0.32, 0.22), (None, None)][lod]
    unit = 1
    if step_x:
        for (za, ya), (zb, yb) in ((prof[0], prof[1]), (prof[3], prof[4])):
            run = np.hypot(zb - za, yb - ya)
            nrow = int(run / step_s)
            for r in range(nrow + 1):
                t = (r + 0.5) / (nrow + 1)
                z, y = za + (zb - za) * t, ya + (yb - ya) * t
                ny, nzz = abs(zb - za) / run, np.sign(za) * abs(yb - ya) / run     # the face's outward normal
                nrm = np.array([0.0, ny, nzz])
                off = (r % 2) * step_x / 2
                for x in np.arange(-L / 2 + 0.12 + off, L / 2 - 0.08, step_x):
                    if rng.random() < 0.08:
                        continue
                    c = np.array([x + rng.uniform(-0.03, 0.03), y, z]) + nrm * 0.04
                    R = S.rotation((0, 1, 0), rng.uniform(-0.25, 0.25)) @ S.rotation((1, 0, 0), np.arctan2(nzz, ny) + rng.uniform(-0.2, 0.2))
                    m.merge(S.box((0, 0, 0), (0.09, 0.065, 0.07), "sett").transformed(R, c).set_unit(unit))
                    unit = unit % 9 + 1
        # the crest: setts thrown loose on top
        for x in np.arange(-L / 2 + 0.15, L / 2 - 0.1, step_x * 0.8):
            c = (x + rng.uniform(-0.05, 0.05), H + 0.04, rng.uniform(-0.15, 0.15))
            R = S.rotation((0, 1, 0), rng.uniform(0, np.pi)) @ S.rotation((1, 0, 0), rng.uniform(-0.5, 0.5))
            m.merge(S.box((0, 0, 0), (0.09, 0.065, 0.07), "sett").transformed(R, c).set_unit(unit))
            unit = unit % 9 + 1
    # loose setts spilled on the street in front
    for _ in range([30, 12, 0][lod]):
        c = (rng.uniform(-L / 2, L / 2), 0.065, -D / 2 - rng.uniform(0.0, 0.7) ** 1.5)
        m.merge(S.box((0, 0, 0), (0.09, 0.065, 0.07), "sett").transformed(S.rotation((0, 1, 0), rng.uniform(0, np.pi)), c).set_unit(unit))
        unit = unit % 9 + 1
    # the cart tipped up against the left end, barrels along the crest, a door laid on the right
    cart = _cart(lod)
    m.merge(cart.transformed(S.rotation((0, 1, 0), 0.15) @ S.rotation((1, 0, 0), -1.0), (-L / 2 + 0.55, 0.62, -0.62)))
    m.merge(_barrel((0.55, H - 0.02, 0.05), (0, 1, 0), lod, 20))
    m.merge(_barrel((1.10, H - 0.30, -0.25), (1, 0.2, 0.3), lod, 21))
    door = S.panel(0.85, 2.05, 0.04, 0.10, "raised" if lod == 0 else "inset", tag="timber") if lod < 2 else S.box((0, 1.025, -0.02), (0.425, 1.025, 0.02), "timber")
    m.merge(door.transformed(S.rotation((1, 0, 0), -1.15) @ S.rotation((0, 1, 0), 0.2), (1.45 - 0.4, 0.10, -D / 2 + 0.05)))
    if lod < 2:
        # a wardrobe dragged out and laid along the crest, its doors' panels up; two chairs thrown on
        wd = Mesh()
        wd.merge(S.box((0, 0.30, 0), (0.95, 0.30, 0.28), "timber"))
        for x in (-0.47, 0.47):
            wd.merge(S.panel(0.80, 0.46, t=0.012, border=0.06, kind="inset" if lod else "raised", tag="timber",
                             origin=(x, 0.30, -0.28), right=(1, 0, 0), up=(0, 1, 0)))
        wd.merge(S.box((0, 0.64, 0), (1.00, 0.04, 0.31), "timber"))            # its cornice
        m.merge(wd.transformed(S.rotation((1, 0, 0), np.pi / 2 - 0.25) @ S.rotation((0, 1, 0), 0.08), (-0.55, H - 0.20, 0.18)))
        for k, (x, yaw, roll) in enumerate(((1.35, 0.6, 2.4), (-1.45, -0.9, 1.3))):
            ch = Mesh()
            ch.merge(S.box((0, 0.45, 0), (0.21, 0.02, 0.20), "timber"))
            for sx in (1, -1):
                for sz in (1, -1):
                    ch.merge(S.box((sx * 0.18, 0.22, sz * 0.17), (0.018, 0.22, 0.018), "timber"))
                ch.merge(S.box((sx * 0.18, 0.70, 0.17), (0.018, 0.25, 0.018), "timber"))
            ch.merge(S.box((0, 0.88, 0.17), (0.18, 0.05, 0.012), "timber"))
            m.merge(ch.transformed(S.rotation((0, 1, 0), yaw) @ S.rotation((0, 0, 1), roll), (x, H + 0.15 - k * 0.25, -0.05 + k * 0.2)))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "barrier_crowd": dict(build=barrier_crowd, materials=materials(), edge_radius=0.002, close=(CROWD["len"] / 2, 0.6, 0.0), **_SPEC),
    "barrier_concrete": dict(build=barrier_concrete, materials=materials(), edge_radius=0.006, close=(0.55, 0.6, -0.15), **_SPEC),
    "sandbag_wall": dict(build=sandbag_wall, materials=materials(), edge_radius=0.004, close=(0.0, 0.3, -0.3), **_SPEC),
    "wire_coil": dict(build=wire_coil, materials=materials(), edge_radius=0.001, close=(0.0, 0.6, -0.4), **_SPEC),
    "traffic_cone": dict(build=traffic_cone, materials=materials(), edge_radius=0.003, close=(0.0, 0.4, -0.1), **_SPEC),
    "works_barrier": dict(build=works_barrier, materials=materials(), extra=_paint_rw, edge_radius=0.002, close=(-0.6, 0.8, 0.0), **_SPEC),
    "water_barrier": dict(build=water_barrier, materials=materials(), edge_radius=0.006, close=(0.5, 0.7, -0.1), **_SPEC),
    "body_bag": dict(build=body_bag, materials=materials(), edge_radius=0.003, close=(0.6, 0.15, 0.0), **_SPEC),
    "police_tape": dict(build=police_tape, materials=materials(), extra=_paint_rw, edge_radius=0.001, close=(1.9, 0.8, 0.0), **_SPEC),
    "tarp": dict(build=tarp, materials=materials(), edge_radius=0.002, close=(-0.9, 0.3, -0.9), **_SPEC),
    "sett_barricade": dict(build=sett_barricade, materials=materials(), edge_radius=0.004, close=(0.0, 0.6, -0.8), **_SPEC),
}
