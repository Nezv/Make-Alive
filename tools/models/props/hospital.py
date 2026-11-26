"""The hospital's medical props (S211). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

wheelchair: the folding hospital wheelchair (behind): the seat and back of sling cloth on a chrome
frame crossed under the seat, the big wheels with their push rims, the small castors in front, the
footplates, the push handles.
gurney: the transport trolley (recovery): a frame on four castors with its lower shelf, the
mattress, side rails raised, the back rest tilted up, the IV pole socket.
iv_stand: the drip stand (corridor): five legs on castors, the pole, four hooks, a bag hung with
its line.
oxygen_cylinder: a medical oxygen cylinder on its two-wheeled trolley: the white cylinder, its
valve and regulator with the gauge, the trolley's frame and handle.
medicine_cabinet: a ward's steel cabinet, glazed doors (parts) over shelves of boxes, drawers.
sharps_bin: the yellow sharps bin with its red lid.

Standing on y = 0, the front -Z.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

CHAIR = dict(seat=0.50, w=0.46, d=0.44, back=0.92, wheel=0.30, castor=0.10)
GURNEY = dict(l=1.95, w=0.68, top=0.78)
O2 = dict(r=0.090, h=0.95)


def materials():
    return {
        "chrome": Material((0.74, 0.75, 0.76), under=(0.55, 0.55, 0.55), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.04),
        "red": Material((0.60, 0.12, 0.10), under=(0.4, 0.4, 0.4), bare=(0.40, 0.30, 0.22), chip=0.5, grain=0.05),
        "cloth": Material((0.10, 0.12, 0.20), kind="rubber", chip=0.0, rusts=False, grain=0.10),
        "tyre": Material((0.07, 0.07, 0.07), kind="rubber", chip=0.0, rusts=False, grain=0.05),
        "mattress": Material((0.30, 0.48, 0.58), kind="rubber", chip=0.0, rusts=False, grain=0.06),
        "sheet": Material((0.88, 0.88, 0.85), kind="paper", chip=0.0, rusts=False, grain=0.08),
        "grey": Material((0.62, 0.64, 0.66), under=(0.5, 0.5, 0.5), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.05),
        "bag": Material((0.85, 0.88, 0.88), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "white": Material((0.90, 0.90, 0.88), under=(0.5, 0.5, 0.5), bare=(0.40, 0.40, 0.40), chip=0.4, grain=0.04),
        "brass": Material((0.68, 0.54, 0.26), under=(0.5, 0.4, 0.2), bare=(0.5, 0.4, 0.2), chip=0.0, rusts=False, grain=0.04, fades=False),
        "dark": Material((0.08, 0.08, 0.08), chip=0.0, rusts=False, grain=0.02, fades=False),
        "yellow": Material((0.92, 0.78, 0.10), kind="rubber", chip=0.0, rusts=False, grain=0.04),
    }


def _tube(a, b, r, lod, tag="chrome"):
    return S.sweep([a, b], S.circle(r, [6, 5, 4][lod]), tag)


def _wheel(c, r, w, lod, spokes=0):
    m = Mesh()
    sides = [18, 12, 8][lod]
    m.merge(S.along(S.lathe([(-w / 2, r - 0.025), (-w / 2, r), (w / 2, r), (w / 2, r - 0.025)], sides, tag="tyre", caps=(False, False)), (1, 0, 0), c))
    m.merge(S.along(S.lathe([(-0.02, 0.03), (0.02, 0.03)], 8, tag="chrome"), (1, 0, 0), c))
    if spokes and lod < 2:
        for k in range(spokes if lod == 0 else spokes // 2):
            a = 2 * np.pi * k / (spokes if lod == 0 else spokes // 2)
            m.merge(S.sweep([c, (c[0], c[1] + np.sin(a) * (r - 0.025), c[2] + np.cos(a) * (r - 0.025))], S.circle(0.002, 3), "chrome"))
    return m


def _castor(c, r, lod):
    m = _wheel(c, r, 0.03, lod)
    if lod < 2:
        m.merge(S.box((c[0], c[1] + r * 0.6, c[2] + r * 0.3), (0.022, r * 0.6, 0.012), "chrome"))
    return m


# --- wheelchair ------------------------------------------------------------------------------------------
def wheelchair(lod):
    sh, w, d, bk, R, rc = CHAIR["seat"], CHAIR["w"], CHAIR["d"], CHAIR["back"], CHAIR["wheel"], CHAIR["castor"]
    m = Mesh()
    t = 0.012
    for s in (1, -1):
        x = s * w / 2
        # the side frame: the seat rail, the back post up to its push handle, down to the castor and the footrest
        m.merge(_tube((x, sh, -d / 2), (x, sh, d / 2), t, lod))
        m.merge(_tube((x, rc * 2, d / 2 - 0.02), (x, bk, d / 2 + 0.03), t, lod))
        m.merge(_tube((x, bk, d / 2 + 0.03), (x, bk + 0.01, d / 2 + 0.14), t, lod))
        m.merge(S.along(S.lathe([(0.0, 0.016), (0.11, 0.016)], 6, tag="tyre"), (0, 0, 1), (x, bk + 0.01, d / 2 + 0.03)))   # the grips
        m.merge(_tube((x, sh, -d / 2), (x, rc * 2, -d / 2 + 0.02), t, lod))
        m.merge(_tube((x, rc * 2, -d / 2 + 0.02), (x * 0.9, 0.12, -d / 2 - 0.16), t, lod))
        m.merge(S.box((x * 0.55, 0.11, -d / 2 - 0.20), (0.09, 0.006, 0.07), "grey"))   # the footplate
        m.merge(_tube((x, rc * 2, -d / 2 + 0.02), (x, rc * 2, d / 2 - 0.02), t, lod))
        # the armrest
        m.merge(_tube((x, sh + 0.22, -d / 2 + 0.06), (x, sh + 0.22, d / 2 - 0.02), t, lod))
        m.merge(S.box((x, sh + 0.235, 0.02), (0.025, 0.012, 0.15), "tyre"))
        m.merge(_tube((x, sh, -d / 2 + 0.06), (x, sh + 0.22, -d / 2 + 0.06), t, lod))
        # the big wheel with its push rim, the castor
        m.merge(_wheel((x + s * 0.045, R, d / 2 - 0.10), R, 0.03, lod, spokes=24))
        if lod < 2:
            rim = S.along(S.lathe([(-0.005, R - 0.035), (0.005, R - 0.035)], [16, 10][lod], tag="chrome", caps=(False, False)), (1, 0, 0), (x + s * 0.075, R, d / 2 - 0.10))
            m.merge(rim)
        m.merge(_castor((x, rc, -d / 2 + 0.02), rc, lod))
    # the cross brace under the seat, the sling seat and back
    if lod < 2:
        m.merge(_tube((-w / 2, sh, -0.08), (w / 2, rc * 2, 0.08), t, lod))
        m.merge(_tube((w / 2, sh, -0.08), (-w / 2, rc * 2, 0.08), t, lod))
    m.merge(S.box((0, sh - 0.01, 0), (w / 2, 0.006, d / 2 - 0.01), "cloth"))
    m.merge(S.box((0, (sh + bk) / 2 + 0.05, d / 2 - 0.01 + 0.015), (w / 2, (bk - sh) / 2 - 0.08, 0.004), "cloth"))
    return {"body": Part(m)}


# --- gurney -------------------------------------------------------------------------------------------------
def gurney(lod):
    L, w, top = GURNEY["l"], GURNEY["w"], GURNEY["top"]
    m = Mesh()
    # the deck's frame, the column legs, the lower shelf, the base on castors
    rect = [(-w / 2, top - 0.08, -L / 2), (w / 2, top - 0.08, -L / 2), (w / 2, top - 0.08, L / 2), (-w / 2, top - 0.08, L / 2)]
    m.merge(S.sweep(rect, [(-0.02, -0.02), (0.02, -0.02), (0.02, 0.02), (-0.02, 0.02)], "grey", closed=True))
    for z in (-L / 2 + 0.35, L / 2 - 0.35):
        m.merge(S.box((0, (top - 0.08 + 0.2) / 2, z), (0.05, (top - 0.28) / 2, 0.05), "grey"))
    m.merge(S.box((0, 0.20, 0), (w / 2 - 0.05, 0.02, L / 2 - 0.15), "grey"))
    m.merge(S.box((0, 0.32, 0), (w / 2 - 0.08, 0.008, L / 2 - 0.25), "grey"))   # the shelf
    for sx in (1, -1):
        for sz in (1, -1):
            m.merge(_castor((sx * (w / 2 - 0.08), 0.075, sz * (L / 2 - 0.20)), 0.075, lod))
    # the mattress: flat, its head raised on the back rest, a sheet over it
    m.merge(S.bevel_box((0, top - 0.02, -0.25), (w / 2 - 0.02, 0.05, L / 2 - 0.28), 0.03, "mattress") if lod < 2 else
            S.box((0, top - 0.02, -0.25), (w / 2 - 0.02, 0.05, L / 2 - 0.28), "mattress"))
    head = S.bevel_box((0, 0.0, -0.30), (w / 2 - 0.02, 0.05, 0.30), 0.03, "mattress") if lod < 2 else S.box((0, 0.0, -0.30), (w / 2 - 0.02, 0.05, 0.30), "mattress")
    m.merge(head.transformed(S.rotation((1, 0, 0), np.radians(-35)), (0, top + 0.01, L / 2 - 0.02)))
    if lod < 2:
        m.merge(S.box((0, top + 0.035, -0.30), (w / 2 - 0.01, 0.004, 0.55), "sheet"))
        # the side rails, raised: two bars on posts each side
        for sx in (1, -1):
            x = sx * (w / 2 + 0.01)
            for y in (top + 0.12, top + 0.25):
                m.merge(_tube((x, y, -0.55), (x, y, 0.45), 0.012, lod))
            for z in (-0.55, 0.45):
                m.merge(_tube((x, top - 0.08, z), (x, top + 0.25, z), 0.012, lod))
        m.merge(_tube((w / 2 - 0.03, top - 0.08, L / 2 - 0.05), (w / 2 - 0.03, top + 0.12, L / 2 - 0.05), 0.015, lod))   # the IV pole's socket
        for sz in (1, -1):  # the push bars at the ends
            m.merge(_tube((-w / 2 + 0.04, top - 0.08, sz * (L / 2 + 0.05)), (w / 2 - 0.04, top - 0.08, sz * (L / 2 + 0.05)), 0.014, lod))
    return {"body": Part(m)}


# --- iv_stand -----------------------------------------------------------------------------------------------
def iv_stand(lod):
    m = Mesh()
    for k in range(5):
        a = 2 * np.pi * k / 5
        end = (np.cos(a) * 0.30, 0.085, np.sin(a) * 0.30)
        m.merge(_tube((0, 0.10, 0), end, 0.012, lod, tag="grey"))
        m.merge(_castor((end[0], 0.04, end[2]), 0.04, lod))
    m.merge(_tube((0, 0.10, 0), (0, 1.30, 0), 0.014, lod))
    m.merge(_tube((0, 1.30, 0), (0, 2.05, 0), 0.010, lod))
    if lod < 2:
        m.merge(S.lathe([(1.28, 0.02), (1.34, 0.02)], 8, tag="grey"))   # the height clamp
        for k in range(4):  # the hooks: arms out, their ends turned up
            a = 2 * np.pi * k / 4 + np.pi / 4
            c, s = np.cos(a), np.sin(a)
            m.merge(S.sweep([(0, 2.02, 0), (c * 0.12, 2.02, s * 0.12), (c * 0.13, 2.07, s * 0.13)], S.circle(0.004, 4), "chrome"))
        # a drip bag on one hook, its line down
        m.merge(S.bevel_box((0.13, 1.87, 0.0), (0.06, 0.12, 0.012), 0.01, "bag") if lod == 0 else S.box((0.13, 1.87, 0.0), (0.06, 0.12, 0.012), "bag"))
        m.merge(S.sweep([(0.13, 1.75, 0.0), (0.14, 1.55, -0.02), (0.18, 1.20, -0.06), (0.22, 0.90, -0.10)], S.circle(0.002, 3), "bag"))
    return {"body": Part(m)}


# --- oxygen_cylinder -----------------------------------------------------------------------------------------
def oxygen_cylinder(lod):
    r, h = O2["r"], O2["h"]
    m = Mesh()
    sides = [16, 10, 6][lod]
    y0 = 0.06
    cyl = [(y0, 0.0), (y0, r * 0.8), (y0 + 0.02, r), (y0 + h - 0.12, r), (y0 + h - 0.06, r * 0.75), (y0 + h - 0.02, r * 0.35), (y0 + h, r * 0.30)]
    m.merge(S.lathe(cyl, sides, tag="white", caps=(False, True)))
    # the valve, the regulator with its gauge, the outlet
    m.merge(S.lathe([(y0 + h, 0.022), (y0 + h + 0.08, 0.022), (y0 + h + 0.09, 0.015)], [8, 6, 4][lod], tag="brass"))
    if lod < 2:
        m.merge(S.along(S.lathe([(0.0, 0.03), (0.025, 0.03)], 12, tag="chrome"), (0, 0, -1), (0, y0 + h + 0.05, -0.022)))
        m.merge(S.along(S.lathe([(0.0, 0.025), (0.004, 0.025)], 12, tag="sheet"), (0, 0, -1), (0, y0 + h + 0.05, -0.047)))
        m.merge(_tube((0.02, y0 + h + 0.04, 0), (0.07, y0 + h + 0.03, 0), 0.006, lod, tag="brass"))
    # the trolley: a frame behind the cylinder, a strap round it, two wheels, the handle
    for sx in (1, -1):
        m.merge(_tube((sx * 0.07, 0.10, r + 0.03), (sx * 0.07, h + 0.10, r + 0.06), 0.011, lod, tag="grey"))
        m.merge(_wheel((sx * 0.13, 0.08, r + 0.05), 0.08, 0.035, lod))
    m.merge(_tube((-0.07, h + 0.10, r + 0.06), (0.07, h + 0.10, r + 0.06), 0.011, lod, tag="grey"))
    m.merge(S.box((0, 0.035, 0), (r + 0.02, 0.008, r + 0.03), "grey"))
    if lod < 2:
        m.merge(_tube((-0.15, 0.08, r + 0.05), (0.15, 0.08, r + 0.05), 0.010, lod, tag="grey"))
        m.merge(S.lathe([(y0 + h * 0.6, r + 0.004), (y0 + h * 0.6 + 0.03, r + 0.004)], sides, tag="grey", caps=(False, False)))
    return {"body": Part(m)}


# --- medicine_cabinet and sharps_bin ------------------------------------------------------------------------
def medicine_cabinet(lod):
    """A ward's steel medicine cabinet on four feet: two glazed doors over shelves of boxes and
    bottles, two steel drawers under them, a lock (parts `door_l`, `door_r`)."""
    w, h, d = 0.80, 1.80, 0.40
    m = Mesh()
    m.merge(S.box((0, h / 2 + 0.06, 0), (w / 2, h / 2, d / 2), "grey"))
    for sx in (1, -1):
        for sz in (1, -1):
            m.merge(S.box((sx * (w / 2 - 0.03), 0.03, sz * (d / 2 - 0.03)), (0.02, 0.03, 0.02), "dark"))
    m.merge(S.box((0, 0.06 + 1.05, -d / 2 + 0.03), (w / 2 - 0.02, 0.62, 0.01), "dark"))   # the inside's back, in shadow
    rng = np.random.default_rng(4)
    for k in range(4 if lod < 2 else 0):  # shelves and what stands on them
        y = 0.06 + 0.55 + k * 0.30
        m.merge(S.box((0, y, -0.02), (w / 2 - 0.02, 0.006, d / 2 - 0.04), "grey"))
        if lod == 0:
            x = -w / 2 + 0.05
            while x < w / 2 - 0.08:
                bw = rng.uniform(0.03, 0.08)
                bh = rng.uniform(0.06, 0.16)
                tag = "sheet" if rng.uniform() < 0.6 else "bag"
                m.merge(S.box((x + bw / 2, y + bh / 2, -0.05 + rng.uniform(-0.04, 0.04)), (bw / 2, bh / 2, 0.035), tag).set_unit(int(rng.integers(1, 5))))
                x += bw + 0.01
    for y in (0.06 + 0.12, 0.06 + 0.36):  # the drawers and their handles
        m.merge(S.box((0, y, -d / 2 - 0.006), (w / 2 - 0.02, 0.10, 0.006), "grey"))
        m.merge(S.box((0, y + 0.04, -d / 2 - 0.018), (0.08, 0.008, 0.008), "chrome"))
    parts = {"body": Part(m)}
    for name, s in (("door_l", -1), ("door_r", 1)):
        dw = w / 2 - 0.015
        door = Mesh()
        cx = s * (w / 2 - 0.01) - s * dw / 2
        y0, y1 = 0.06 + 0.50, 0.06 + h - 0.02
        door.merge(S.box((cx, (y0 + y1) / 2, -d / 2 - 0.012), (dw / 2, (y1 - y0) / 2, 0.012), "grey"))
        door.merge(S.box((cx, (y0 + y1) / 2, -d / 2 - 0.025), (dw / 2 - 0.05, (y1 - y0) / 2 - 0.05, 0.002), "bag"))   # the glass
        door.merge(S.box((cx - s * (dw / 2 - 0.04), (y0 + y1) / 2, -d / 2 - 0.03), (0.008, 0.06, 0.008), "chrome"))
        hinge = (s * (w / 2 - 0.01), 0.0, -d / 2)
        parts[name] = Part(door, hinge, {"rotate": [[0, 1, 0], -100.0 * s]})
    return parts


def sharps_bin(lod):
    """The yellow sharps bin: a tapered box, its red lid with the slot, a handle."""
    m = Mesh()
    body = S.lathe([(0.0, 0.11 * np.sqrt(2)), (0.26, 0.13 * np.sqrt(2))], 4, turn=np.pi / 4, tag="yellow")
    m.merge(body.transformed(np.diag([1.0, 1.0, 0.75]), (0, 0, 0)))
    m.merge(S.box((0, 0.275, 0), (0.135, 0.015, 0.10), "red"))
    if lod == 0:
        m.merge(S.box((0, 0.2915, -0.03), (0.06, 0.0015, 0.015), "dark"))
        m.merge(S.sweep([(-0.08, 0.29, 0.06), (-0.06, 0.33, 0.06), (0.06, 0.33, 0.06), (0.08, 0.29, 0.06)], S.circle(0.008, 4), "red"))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "wheelchair": dict(build=wheelchair, materials=materials(), edge_radius=0.002, close=(0.2, 0.5, 0.1), **_SPEC),
    "gurney": dict(build=gurney, materials=materials(), edge_radius=0.003, close=(0.3, 0.8, 0.6), **_SPEC),
    "iv_stand": dict(build=iv_stand, materials=materials(), edge_radius=0.002, close=(0.1, 1.8, 0.0), **_SPEC),
    "oxygen_cylinder": dict(build=oxygen_cylinder, materials=materials(), edge_radius=0.002, close=(0.0, 1.0, 0.0), **_SPEC),
    "medicine_cabinet": dict(build=medicine_cabinet, materials=materials(), edge_radius=0.003, close=(0.0, 1.2, -0.2), **_SPEC),
    "sharps_bin": dict(build=sharps_bin, materials=materials(), edge_radius=0.002, close=(0.0, 0.2, -0.1), states=_SPEC["states"], lods=2),
}
