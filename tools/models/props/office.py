"""Office and public furniture (S193). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

desk: the office desk: a laminate top on a grey steel frame of four legs with a modesty panel, a
pedestal of three drawers under its right end (the top one is part `drawer`, pulling out), the
cable grommet.
office_chair: the swivel chair: five-star base on castors, the gas column and its shroud, the seat
cushion, the back on its support bar, two armrests.
filing_cabinet: the four-drawer steel cabinet: drawers with recessed handles and label holders,
the lock at the top, the top drawer part `drawer`.
shelving: a bay of grey steel shelving: perforated angle posts, five shelves, cross braces at the
back, archive boxes and binders on the shelves (seeded).
desk_computer: what stands on a desk: a flat monitor on its stand, a keyboard, a mouse, a tower
under or beside it, a desk phone, cables.
beam_seating: three moulded seats on a steel beam on two legs, the waiting room's.
vending_machine: the snack machine: a cabinet with a glass front over five rows of spiral coils
holding products (seeded colours, no brands), the keypad panel with its coin slot and display (lit),
the pick-up flap.
water_cooler: the bottled water cooler: the upturned 18.9 l bottle, the white cabinet with its two
taps and drip tray, the cup dispenser on its side.

Standing on y = 0, the front -Z (where a person sits or stands).
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

DESK = dict(w=1.60, d=0.80, h=0.75, top=0.025)
CAB = dict(w=0.47, h=1.32, d=0.62, drawers=4)
SHELF = dict(w=1.00, h=2.00, d=0.40, shelves=5)
VEND = dict(w=0.90, h=1.83, d=0.80)


def materials():
    return {
        "laminate": Material((0.74, 0.62, 0.46), under=(0.70, 0.66, 0.58), bare=(0.62, 0.52, 0.38), kind="wood", chip=0.2, rusts=False, grain=0.06),
        "edge": Material((0.30, 0.30, 0.31), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "steel": Material((0.62, 0.63, 0.64), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.05),
        "dark": Material((0.08, 0.08, 0.09), chip=0.0, rusts=False, grain=0.02, fades=False),
        "plastic": Material((0.12, 0.12, 0.13), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "fabric": Material((0.20, 0.24, 0.32), kind="paper", chip=0.0, rusts=False, grain=0.12),
        "chrome": Material((0.75, 0.76, 0.77), under=(0.5, 0.5, 0.5), bare=(0.40, 0.28, 0.18), chip=0.2, grain=0.03),
        "screen": Material((0.05, 0.06, 0.07), kind="glass", chip=0.0, rusts=False, grain=0.01, sheds=False),
        "beige": Material((0.80, 0.78, 0.72), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "box": Material((0.70, 0.62, 0.48), kind="paper", chip=0.0, rusts=False, grain=0.10,
                        palette=[(0.70, 0.62, 0.48), (0.66, 0.58, 0.44), (0.20, 0.30, 0.55), (0.55, 0.15, 0.12), (0.18, 0.40, 0.25), (0.75, 0.70, 0.60)], vary=0.04),
        "seat": Material((0.22, 0.40, 0.58), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "red": Material((0.55, 0.08, 0.08), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.04),
        "glass": Material((0.30, 0.33, 0.35), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "goods": Material((0.80, 0.20, 0.15), kind="paper", chip=0.0, rusts=False, grain=0.05,
                          palette=[(0.80, 0.20, 0.15), (0.90, 0.75, 0.15), (0.15, 0.35, 0.70), (0.20, 0.55, 0.25), (0.45, 0.25, 0.12), (0.85, 0.45, 0.10), (0.60, 0.15, 0.45)], vary=0.05),
        "panel": Material((0.25, 0.70, 0.35), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.30, 0.95, 0.45)),
        "lit": Material((0.92, 0.94, 0.96), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.85, 0.90, 1.0)),
        "white": Material((0.90, 0.90, 0.88), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "water": Material((0.55, 0.72, 0.85), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- desk ------------------------------------------------------------------------------------------------
def _pedestal_drawer(x, y, w, h, d, lod):
    """A drawer's front with its handle, and the box behind it."""
    m = Mesh()
    m.merge(_cb((x, y, -d / 2 + 0.01), (w / 2 - 0.005, h / 2 - 0.004, 0.01), 0.003, "steel", lod))
    if lod < 2:
        m.merge(S.box((x, y + h / 2 - 0.04, -d / 2 - 0.006), (0.06, 0.008, 0.008), "chrome"))
    m.merge(S.box((x, y, 0.0), (w / 2 - 0.02, h / 2 - 0.02, d / 2 - 0.03), "steel"))
    return m


def desk(lod):
    w, d, h, t = DESK["w"], DESK["d"], DESK["h"], DESK["top"]
    m = Mesh()
    m.merge(_cb((0, h - t / 2, 0), (w / 2, t / 2, d / 2), 0.004, "laminate", lod, edges="top"))
    if lod < 2:  # the top's dark edge band, the cable grommet
        for s in (1, -1):
            m.merge(S.box((0, h - t / 2, s * (d / 2 + 0.001)), (w / 2, t / 2, 0.001), "edge"))
        m.merge(S.lathe([(h - 0.001, 0.03), (h + 0.002, 0.03), (h + 0.002, 0.0)], 10, tag="plastic").transformed(np.eye(3), (w / 2 - 0.25, 0, d / 2 - 0.08)))
    # the frame: four square legs, rails under the top, the modesty panel at the back
    for sx in (1, -1):
        for sz in (1, -1):
            m.merge(S.box((sx * (w / 2 - 0.04), (h - t) / 2, sz * (d / 2 - 0.04)), (0.02, (h - t) / 2, 0.02), "steel"))
        m.merge(S.box((sx * (w / 2 - 0.04), h - t - 0.03, 0), (0.015, 0.03, d / 2 - 0.04), "steel"))
    m.merge(S.box((0, h - t - 0.03, d / 2 - 0.04), (w / 2 - 0.04, 0.03, 0.015), "steel"))
    m.merge(S.box((0, h - t - 0.22, d / 2 - 0.05), (w / 2 - 0.06, 0.18, 0.006), "steel"))
    if lod < 2:
        for sx in (1, -1):
            for sz in (1, -1):
                m.merge(S.box((sx * (w / 2 - 0.04), 0.005, sz * (d / 2 - 0.04)), (0.022, 0.005, 0.022), "plastic"))
    # the pedestal of three drawers under the right end; the top drawer pulls out
    pw, pd = 0.42, d - 0.10
    px = w / 2 - 0.08 - pw / 2
    m.merge(S.box((px, (h - t - 0.03) / 2 + 0.015, 0.02), (pw / 2, (h - t - 0.03) / 2 - 0.015, pd / 2), "steel"))
    hs = [0.14, 0.14, 0.30]
    y = h - t - 0.035
    parts = {}
    for k, dh in enumerate(hs):
        y -= dh
        dr = _pedestal_drawer(px, y + dh / 2, pw, dh, pd + 0.03, lod)
        if k == 0:
            parts["drawer"] = Part(dr, (px, y + dh / 2, -d / 2), {"move": [0.0, 0.0, -0.34]})
        else:
            m.merge(dr)
    return dict({"body": Part(m)}, **parts)


# --- office_chair -----------------------------------------------------------------------------------------
def office_chair(lod):
    m = Mesh()
    sides = [10, 6, 4][lod]
    # the star base: five legs out from the hub, a castor at each end
    for k in range(5):
        a = k * 2 * np.pi / 5 + np.pi / 2
        tip = np.array([np.cos(a) * 0.32, 0.07, np.sin(a) * 0.32])
        m.merge(S.sweep([(0, 0.10, 0), tuple(tip)], [(-0.025, -0.015), (0.025, -0.015), (0.025, 0.015), (-0.025, 0.015)], "plastic", up=(0, 1, 0)))
        if lod < 2:
            m.merge(S.along(S.lathe([(-0.012, 0.025), (0.012, 0.025)], [8, 6][lod], tag="plastic"), (np.sin(a), 0, -np.cos(a)), tip + (0, -0.04, 0)))
            m.merge(S.box(tip + (0, -0.01, 0), (0.012, 0.02, 0.012), "plastic"))
    # the column, its shroud, the mechanism under the seat
    m.merge(S.lathe([(0.08, 0.04), (0.25, 0.035), (0.42, 0.015)], sides, tag="plastic"))
    m.merge(S.lathe([(0.25, 0.014), (0.42, 0.014)], sides, tag="chrome"))
    m.merge(S.box((0, 0.43, 0.02), (0.10, 0.02, 0.12), "plastic"))
    # the seat: a cushion rounded at its front edge
    seat = [(-0.24, 0.0), (0.24, 0.0), (0.25, 0.04), (0.24, 0.08), (-0.24, 0.08), (-0.25, 0.04)]
    m.merge(S.extrude(seat, 0.46, 0.015 if lod == 0 else 0.0, "fabric", origin=(0, 0.45, 0.23), right=(1, 0, 0), up=(0, 1, 0)))
    # the back on its bar, curved round the sitter
    m.merge(S.sweep([(0, 0.46, 0.20), (0, 0.50, 0.27), (0, 0.65, 0.28)], [(-0.03, -0.01), (0.03, -0.01), (0.03, 0.01), (-0.03, 0.01)], "plastic", up=(1, 0, 0)))
    nb = [9, 5, 3][lod]
    rings = []
    for y in np.linspace(0.60, 1.02, [6, 4, 2][lod]):
        k = 1.0 - 0.25 * ((y - 0.81) / 0.21) ** 2
        ring = []
        for a in np.linspace(-0.55, 0.55, nb):
            ring.append((np.sin(a) * 0.40 * k, y, 0.27 - 0.08 * (1 - np.cos(a))))       # its sides come round the sitter
        ring += [(x, yy, z + 0.06) for x, yy, z in reversed(ring)]
        rings.append(ring)
    back = Mesh()
    back.loft(rings, "fabric", caps=(True, True))
    m.merge(back)
    if lod < 2:  # the armrests on their uprights
        for s in (1, -1):
            m.merge(S.sweep([(s * 0.23, 0.46, 0.05), (s * 0.26, 0.55, 0.05), (s * 0.26, 0.64, 0.02)], [(-0.015, -0.02), (0.015, -0.02), (0.015, 0.02), (-0.015, 0.02)], "plastic", up=(1, 0, 0)))
            m.merge(_cb((s * 0.26, 0.655, -0.02), (0.035, 0.015, 0.13), 0.008, "plastic", lod))
    return {"body": Part(m)}


# --- filing_cabinet ---------------------------------------------------------------------------------------
def filing_cabinet(lod):
    w, h, d, n = CAB["w"], CAB["h"], CAB["d"], CAB["drawers"]
    m = Mesh()
    m.merge(_cb((0, h / 2 + 0.02, 0.01), (w / 2, h / 2 - 0.02, d / 2 - 0.01), 0.004, "steel", lod))
    m.merge(S.box((0, 0.025, 0.02), (w / 2 - 0.02, 0.025, d / 2 - 0.03), "dark"))     # the plinth, set back
    dh = (h - 0.06) / n
    parts = {}
    for k in range(n):
        y = h - 0.02 - (k + 0.5) * dh
        dr = Mesh()
        dr.merge(_cb((0, y, -d / 2 - 0.005), (w / 2 - 0.012, dh / 2 - 0.006, 0.012), 0.004, "steel", lod))
        if lod < 2:  # the handle's recess and bar, the label holder
            dr.merge(S.box((0, y + dh * 0.12, -d / 2 - 0.018), (0.09, 0.016, 0.003), "dark"))
            dr.merge(S.box((0, y + dh * 0.12 - 0.012, -d / 2 - 0.022), (0.08, 0.005, 0.008), "chrome"))
            dr.merge(S.box((0, y + dh * 0.32, -d / 2 - 0.019), (0.05, 0.018, 0.002), "chrome"))
            if lod == 0:
                dr.merge(S.box((0, y + dh * 0.32, -d / 2 - 0.0205), (0.042, 0.013, 0.001), "beige"))
        if k == 0:
            dr.merge(S.box((0, y, 0.0), (w / 2 - 0.03, dh / 2 - 0.02, d / 2 - 0.04), "steel"))
            if lod < 2:  # the files hanging inside
                for i in range(8):
                    dr.merge(S.box((0, y + 0.02, -d / 2 + 0.06 + i * 0.06), (w / 2 - 0.05, dh / 2 - 0.05, 0.004), "box").set_unit(i % 6 + 1))
            parts["drawer"] = Part(dr, (0, y, -d / 2), {"move": [0.0, 0.0, -0.45]})
        else:
            m.merge(dr)
    if lod < 2:
        m.merge(S.along(S.lathe([(0.0, 0.012), (0.008, 0.012), (0.008, 0.0)], 8, tag="chrome"), (0, 0, -1), (w / 2 - 0.05, h - 0.02, -d / 2 - 0.0)))
    return dict({"body": Part(m)}, **parts)


# --- shelving ---------------------------------------------------------------------------------------------
def shelving(lod):
    w, h, d, n = SHELF["w"], SHELF["h"], SHELF["d"], SHELF["shelves"]
    rng = np.random.default_rng(4)
    m = Mesh()
    angle = [(0.0, 0.0), (0.035, 0.0), (0.035, 0.002), (0.002, 0.002), (0.002, 0.035), (0.0, 0.035)]
    for sx in (1, -1):
        for sz in (1, -1):
            # an angle post, its flanges facing in
            pts = [(-sx * x, -sz * y) for x, y in angle]
            m.merge(S.extrude(pts, h, 0.0, "steel", origin=(sx * w / 2, 0.0, sz * d / 2), right=(1, 0, 0), up=(0, 0, 1)))
    ys = np.linspace(0.08, h - 0.02, n)
    unit = 1
    for y in ys:
        m.merge(S.box((0, y, 0), (w / 2, 0.012, d / 2), "steel"))
        if lod < 2:
            for s in (1, -1):  # the shelf's folded lips
                m.merge(S.box((0, y - 0.02, s * (d / 2 - 0.002)), (w / 2, 0.02, 0.002), "steel"))
        if y > h - 0.1 or lod == 2:
            continue
        # what stands on it: archive boxes, binders, a stack lying flat
        x = -w / 2 + 0.03
        while x < w / 2 - 0.08:
            kind = rng.integers(0, 3)
            if kind == 0:
                bw, bh, bd = 0.10, 0.26, 0.32
            elif kind == 1:
                bw, bh, bd = 0.07, 0.31, 0.28
            else:
                bw, bh, bd = 0.24, 0.10, 0.30
            if x + bw > w / 2 - 0.03:
                break
            if rng.random() < 0.15:
                x += bw
                continue
            lean = rng.uniform(-0.06, 0.06) if kind == 1 and lod == 0 else 0.0
            b = S.box((0, bh / 2, 0), (bw / 2, bh / 2, bd / 2), "box").transformed(S.rotation((0, 0, 1), lean), (x + bw / 2, y + 0.012, -d / 2 + bd / 2 + 0.02))
            m.merge(b.set_unit(int(rng.integers(1, 7))))
            if lod == 0 and kind == 0:  # the box's hand hole
                m.merge(S.box((x + bw / 2, y + 0.012 + bh * 0.75, -d / 2 + 0.019), (0.025, 0.012, 0.001), "dark"))
            x += bw + 0.005
            unit += 1
    if lod < 2:  # the cross braces at the back
        for s in (1, -1):
            m.merge(S.sweep([(-w / 2, 0.08, d / 2 - 0.01), (w / 2, h / 2, d / 2 - 0.01)] if s > 0 else [(w / 2, 0.08, d / 2 - 0.01), (-w / 2, h / 2, d / 2 - 0.01)],
                            [(-0.012, -0.0015), (0.012, -0.0015), (0.012, 0.0015), (-0.012, 0.0015)], "steel", up=(0, 0, 1)))
    return {"body": Part(m)}


# --- desk_computer ------------------------------------------------------------------------------------------
def desk_computer(lod):
    m = Mesh()
    # the monitor: a thin screen on a neck and a foot
    m.merge(_cb((0, 0.30, 0.10), (0.27, 0.17, 0.02), 0.006, "plastic", lod))
    m.merge(S.box((0, 0.30, 0.079), (0.255, 0.155, 0.002), "screen"))
    m.merge(S.box((0, 0.13, 0.13), (0.03, 0.12, 0.012), "plastic"))
    m.merge(_cb((0, 0.008, 0.12), (0.12, 0.008, 0.09), 0.004, "plastic", lod))
    # the keyboard, its keys as rows of ridges; the mouse
    m.merge(_cb((0, 0.012, -0.12), (0.22, 0.012, 0.07), 0.004, "plastic", lod, edges="top"))
    if lod == 0:
        for r in range(5):
            m.merge(S.box((-0.02, 0.026, -0.17 + r * 0.022), (0.18, 0.004, 0.008), "dark"))
    if lod < 2:
        m.merge(S.lathe([(0.0, 0.0), (0.0, 0.03), (0.018, 0.028), (0.03, 0.0)], [8, 5][lod], tag="plastic").transformed(np.diag([1.0, 1.0, 1.7]), (0.32, 0, -0.10)))
        # the desk phone and its handset; the cables
        m.merge(_cb((-0.40, 0.03, -0.02), (0.10, 0.03, 0.09), 0.01, "plastic", lod))
        m.merge(_cb((-0.40, 0.07, -0.02), (0.025, 0.018, 0.10), 0.01, "plastic", lod))
        m.merge(S.cable((0, 0.15, 0.15), (0.0, 0.0, 0.32), 0.02, r=0.003, n=6, sides=4, tag="dark"))
        m.merge(S.cable((0, 0.012, -0.05), (0.0, 0.0, 0.25), 0.01, r=0.002, n=6, sides=4, tag="dark"))
    # the tower beside it
    m.merge(_cb((0.45, 0.21, 0.12), (0.09, 0.21, 0.22), 0.006, "plastic", lod))
    if lod < 2:
        m.merge(S.box((0.45, 0.34, -0.101), (0.07, 0.04, 0.001), "dark"))
        m.merge(S.box((0.45, 0.39, -0.101), (0.008, 0.008, 0.001), "panel"))
    return {"body": Part(m)}


# --- beam_seating -------------------------------------------------------------------------------------------
def _shell(lod):
    """One moulded seat: the pan and the back in one, curved."""
    rings = []
    prof = [(0.00, 0.42, -0.21), (0.00, 0.44, -0.10), (0.00, 0.43, 0.10), (0.00, 0.48, 0.19), (0.00, 0.70, 0.24), (0.00, 0.84, 0.25)]
    if lod == 2:
        prof = [prof[0], prof[2], prof[3], prof[5]]
    for _, y, z in prof:
        hw = 0.24 if y < 0.6 else 0.22
        n = [7, 4, 2][lod]
        ring = [(x, y + 0.012 * (x / hw) ** 2 * (1 if y < 0.6 else 0), z + (0.02 * (x / hw) ** 2 if y >= 0.6 else 0)) for x in np.linspace(-hw, hw, n)]
        ring += [(x, yy - (0.012 if y < 0.6 else 0.0), zz + (0.0 if y < 0.6 else 0.012)) for x, yy, zz in reversed(ring)]
        rings.append(ring)
    m = Mesh()
    m.loft(rings, "seat", caps=(True, True))
    return m


def beam_seating(lod):
    m = Mesh()
    L = 1.80
    m.merge(S.box((0, 0.36, 0.05), (L / 2, 0.03, 0.04), "steel"))       # the beam
    for x in (-L / 2 + 0.2, L / 2 - 0.2):                                 # the legs: a post on a T foot
        m.merge(S.box((x, 0.18, 0.05), (0.025, 0.18, 0.025), "steel"))
        m.merge(_cb((x, 0.01, 0.05), (0.03, 0.01, 0.26), 0.005, "steel", lod))
    for k in range(3):
        x = (k - 1) * 0.60
        m.merge(_shell(lod).transformed(np.eye(3), (x, 0, 0)))
        m.merge(S.box((x, 0.40, 0.05), (0.05, 0.02, 0.10), "steel"))      # the bracket under each seat
        if lod < 2 and k < 2:  # an armrest between seats
            ax = x + 0.30
            m.merge(S.sweep([(ax, 0.39, 0.10), (ax, 0.62, 0.10), (ax, 0.62, -0.12)], [(-0.012, -0.012), (0.012, -0.012), (0.012, 0.012), (-0.012, 0.012)], "steel", up=(1, 0, 0)))
    return {"body": Part(m)}


# --- vending_machine ----------------------------------------------------------------------------------------
def vending_machine(lod):
    w, h, d = VEND["w"], VEND["h"], VEND["d"]
    rng = np.random.default_rng(9)
    m = Mesh()
    m.merge(_cb((0, h / 2 + 0.04, 0), (w / 2, h / 2 - 0.04, d / 2), 0.01, "red", lod))
    m.merge(S.box((0, 0.02, 0.02), (w / 2 - 0.03, 0.02, d / 2 - 0.04), "dark"))
    gx0, gx1 = -w / 2 + 0.05, w / 2 - 0.27                    # the window's sides
    gy0, gy1 = 0.42, h - 0.10
    # the cavity behind the glass: back wall, five shelves of coils and goods
    m.merge(S.box(((gx0 + gx1) / 2, (gy0 + gy1) / 2, -d / 2 + 0.36), ((gx1 - gx0) / 2, (gy1 - gy0) / 2, 0.005), "dark"))
    unit = 1
    for r in range(5):
        y = gy0 + 0.05 + r * (gy1 - gy0 - 0.08) / 5
        m.merge(S.box(((gx0 + gx1) / 2, y, -d / 2 + 0.20), ((gx1 - gx0) / 2, 0.006, 0.16), "steel"))
        for c in range(5 if lod < 2 else 0):
            x = gx0 + 0.06 + c * (gx1 - gx0 - 0.08) / 4.6
            if lod == 0:  # the coil
                coil = [(x + 0.035 * np.cos(a), y + 0.04 + 0.035 * np.sin(a), -d / 2 + 0.06 + 0.25 * a / (6 * np.pi)) for a in np.linspace(0, 6 * np.pi, 19)]
                m.merge(S.sweep(coil, S.circle(0.003, 3), "chrome"))
            pk = rng.integers(0, 3)
            size = [(0.035, 0.07, 0.012), (0.03, 0.05, 0.03), (0.032, 0.045, 0.032)][pk]
            for k in range(3 if lod == 0 else 1):
                if rng.random() < 0.25:
                    continue
                m.merge(S.box((x, y + 0.006 + size[1], -d / 2 + 0.07 + k * 0.08), size, "goods").set_unit(int(rng.integers(1, 8))))
            unit += 1
    if lod == 2:  # far off the window is a dark pane; close to, the goods show (the glass waits for a see-through material)
        m.merge(S.box(((gx0 + gx1) / 2, (gy0 + gy1) / 2, -d / 2 - 0.004), ((gx1 - gx0) / 2, (gy1 - gy0) / 2, 0.004), "glass"))
    if lod < 2:  # the window's frame; the panel: display, keypad, coin slot, note slot, return
        for y in (gy0, gy1):
            m.merge(S.box(((gx0 + gx1) / 2, y, -d / 2 - 0.01), ((gx1 - gx0) / 2 + 0.02, 0.02, 0.01), "dark"))
        for x in (gx0, gx1):
            m.merge(S.box((x, (gy0 + gy1) / 2, -d / 2 - 0.01), (0.02, (gy1 - gy0) / 2, 0.01), "dark"))
        px = w / 2 - 0.13
        m.merge(S.box((px, 1.40, -d / 2 - 0.006), (0.09, 0.04, 0.006), "panel"))
        for r in range(4):
            for c in range(3):
                m.merge(S.box((px - 0.04 + c * 0.04, 1.27 - r * 0.04, -d / 2 - 0.008), (0.014, 0.014, 0.006), "chrome" if lod == 0 else "steel"))
        m.merge(S.box((px, 1.05, -d / 2 - 0.006), (0.03, 0.012, 0.006), "dark"))
        m.merge(S.box((px, 0.96, -d / 2 - 0.006), (0.05, 0.02, 0.006), "dark"))
        m.merge(S.box((px, 0.25, -d / 2 - 0.008), (0.05, 0.04, 0.008), "dark"))
        m.merge(S.box((px, h - 0.25, -d / 2 - 0.004), (0.09, 0.12, 0.004), "lit"))     # the lit card over the panel
    # the pick-up flap at the foot
    m.merge(S.box(((gx0 + gx1) / 2, 0.24, -d / 2 - 0.006), ((gx1 - gx0) / 2 - 0.05, 0.08, 0.006), "dark"))
    return {"body": Part(m)}


# --- water_cooler -------------------------------------------------------------------------------------------
def water_cooler(lod):
    m = Mesh()
    sides = [14, 8, 6][lod]
    m.merge(_cb((0, 0.48, 0), (0.15, 0.48, 0.16), 0.02, "white", lod, edges="vertical"))
    m.merge(S.lathe([(0.96, 0.15), (0.99, 0.14), (1.00, 0.06), (1.00, 0.0)], sides, tag="white"))
    # the bottle upside down: neck into the collar, the ribbed body, its flat bottom on top
    bottle = [(1.00, 0.025), (1.06, 0.03), (1.12, 0.13), (1.16, 0.135), (1.30, 0.135), (1.33, 0.13), (1.46, 0.13), (1.47, 0.12), (1.48, 0.0)]
    flute = (lambda j, y: 1.0 + 0.03 * np.cos(j * np.pi) * (1.18 < y < 1.46)) if lod == 0 else None
    m.merge(S.lathe(bottle, [16, 10, 6][lod], tag="water", flute=flute))
    if lod < 2:  # the two taps (blue and red), the drip tray, the cup dispenser
        for x, tag in ((-0.05, "seat"), (0.05, "red")):
            m.merge(_cb((x, 0.78, -0.17), (0.02, 0.03, 0.02), 0.004, tag, lod))
        m.merge(S.box((0, 0.69, -0.16), (0.12, 0.03, 0.006), "dark"))
        m.merge(_cb((0, 0.60, -0.19), (0.10, 0.012, 0.05), 0.004, "plastic", lod))
        m.merge(S.lathe([(0.35, 0.036), (0.70, 0.036), (0.72, 0.04)], [8, 6][lod], tag="white", caps=(True, False)).transformed(np.eye(3), (0.19, 0, 0.0)))
    return {"body": Part(m)}


# --- reception_counter --------------------------------------------------------------------------------------
def reception_counter(lod):
    """The reception counter of a hall: a laminate front on its dark plinth, the raised ledge for the
    visitor along the top, the work top behind at desk height, a glass screen on posts, a bell."""
    L, H, D = 2.40, 1.10, 0.80
    m = Mesh()
    m.merge(S.box((0, 0.05, -D / 2 + 0.06), (L / 2, 0.05, 0.02), "dark"))
    m.merge(_cb((0, 0.10 + (H - 0.10) / 2, -D / 2 + 0.04), (L / 2, (H - 0.10) / 2, 0.025), 0.004, "laminate", lod))
    for s in (1, -1):
        m.merge(S.box((s * (L / 2 - 0.02), H / 2, 0), (0.02, H / 2, D / 2 - 0.02), "laminate"))
    m.merge(_cb((0, H + 0.02, -D / 2 + 0.10), (L / 2 + 0.03, 0.02, 0.17), 0.006, "laminate", lod, edges="top"))
    m.merge(_cb((0, 0.74, 0.05), (L / 2 - 0.04, 0.015, D / 2 - 0.10), 0.004, "laminate", lod, edges="top"))
    m.merge(S.box((0, 0.42, 0.0), (L / 2 - 0.05, 0.32, 0.01), "laminate"))     # the back of the front panel's cavity
    if lod < 2:
        # the front's panels: grooves dividing it in three
        for x in (-L / 6, L / 6):
            m.merge(S.box((x, 0.10 + (H - 0.10) / 2, -D / 2 + 0.013), (0.004, (H - 0.18) / 2, 0.002), "dark"))
        # the glass screen on two posts, the slot under it, the bell
        for x in (-0.60, 0.60):
            m.merge(S.box((x, H + 0.04 + 0.30, -D / 2 + 0.14), (0.012, 0.30, 0.012), "chrome"))
        m.merge(S.box((0, H + 0.12 + 0.30, -D / 2 + 0.14), (0.62, 0.26, 0.004), "glass"))
        m.merge(S.lathe([(H + 0.04, 0.035), (H + 0.05, 0.035), (H + 0.09, 0.03), (H + 0.10, 0.0)], [10, 6][lod], tag="chrome").transformed(np.eye(3), (0.85, 0, -D / 2 + 0.10)))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "desk": dict(build=desk, materials=materials(), edge_radius=0.003, close=(0.5, 0.6, -0.4), **_SPEC),
    "office_chair": dict(build=office_chair, materials=materials(), edge_radius=0.003, close=(0.0, 0.5, -0.2), **_SPEC),
    "filing_cabinet": dict(build=filing_cabinet, materials=materials(), edge_radius=0.002, close=(0.0, 1.0, -0.31), **_SPEC),
    "shelving": dict(build=shelving, materials=materials(), edge_radius=0.002, close=(0.0, 1.0, -0.2), **_SPEC),
    "desk_computer": dict(build=desk_computer, materials=materials(), edge_radius=0.002, close=(0.0, 0.2, -0.1), **_SPEC),
    "beam_seating": dict(build=beam_seating, materials=materials(), edge_radius=0.003, close=(0.0, 0.5, -0.2), **_SPEC),
    "vending_machine": dict(build=vending_machine, materials=materials(), edge_radius=0.004, close=(0.0, 1.2, -0.4), **_SPEC),
    "water_cooler": dict(build=water_cooler, materials=materials(), edge_radius=0.003, close=(0.0, 0.9, -0.16), **_SPEC),
    "reception_counter": dict(build=reception_counter, materials=materials(), edge_radius=0.003, close=(0.6, 1.0, -0.4), **_SPEC),
}
