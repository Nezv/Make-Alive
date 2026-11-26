"""Light fittings and signs of the buildings' insides (S194). Cards and references:
references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

tube_light: the two-tube batten (batten, louvre) hung from the ceiling on two chains: the steel
body, the end caps, two tubes lit by the emission map. The ceiling is y = 0: everything hangs below.
exit_sign: the emergency exit light on a wall (the French BAES): a white box, its green face lit,
the running man and the arrow in white. The wall's face is z = 0 (the room -Z), y = 0 the floor.
extinguisher: a 6 kg extinguisher on its wall bracket (on_wall, cabinet): the red body, the valve
head with handle and lever, the pin, the hose round to its nozzle, the label. Wall z = 0, floor y = 0.
alarm_point: the red manual call point: a box, the white glass square, the words. Wall z = 0.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

BATTEN = dict(l=1.27, w=0.14, h=0.06, drop=0.45)
EXIT = dict(w=0.34, h=0.13, d=0.07, y=2.20)
EXT = dict(r=0.08, h=0.50, y=0.80)
ALARM = dict(s=0.10, d=0.05, y=1.40)


def materials():
    return {
        "steel": Material((0.85, 0.85, 0.82), under=(0.6, 0.6, 0.6), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.05),
        "tube": Material((0.92, 0.94, 0.95), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.90, 0.95, 1.0)),
        "chain": Material((0.55, 0.55, 0.55), under=(0.4, 0.4, 0.4), bare=(0.40, 0.28, 0.18), chip=0.2, grain=0.05),
        "plastic": Material((0.90, 0.90, 0.86), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "exit": Material((0.10, 0.55, 0.30), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.15, 0.85, 0.40)),
        "red": Material((0.70, 0.08, 0.06), under=(0.5, 0.5, 0.5), bare=(0.40, 0.30, 0.22), chip=0.5, grain=0.04),
        "black": Material((0.08, 0.08, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "label": Material((0.92, 0.92, 0.88), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "glass": Material((0.85, 0.86, 0.86), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
    }


# --- tube_light ------------------------------------------------------------------------------------------
def tube_light(lod):
    L, w, h, drop = BATTEN["l"], BATTEN["w"], BATTEN["h"], BATTEN["drop"]
    m = Mesh()
    y = -drop
    body = S.chamfer_box((0, y + h / 2, 0), (L / 2, h / 2, w / 2), 0.012, "steel", edges="top") if lod < 2 else S.box((0, y + h / 2, 0), (L / 2, h / 2, w / 2), "steel")
    m.merge(body)
    for z in (-w / 4, w / 4):  # the two tubes under it
        m.merge(S.along(S.lathe([(-L / 2 + 0.05, 0.013), (L / 2 - 0.05, 0.013)], [8, 6, 4][lod], tag="tube"), (1, 0, 0), (0, y - 0.022, z)))
    if lod < 2:
        for sx in (1, -1):  # the end caps that hold the tubes, the chains up to the ceiling's hooks
            m.merge(S.box((sx * (L / 2 - 0.035), y - 0.02, 0), (0.012, 0.03, w / 2 - 0.01), "plastic"))
            x = sx * (L / 2 - 0.15)
            if lod == 0:
                for k in range(int(drop / 0.03)):
                    yk = y + h + 0.015 + k * 0.03
                    link = [(x + np.cos(a) * 0.008 * (k % 2 == 0), yk + np.sin(a) * 0.014, np.cos(a) * 0.008 * (k % 2)) for a in np.linspace(0, 2 * np.pi, 7)[:-1]]
                    m.merge(S.sweep(link, S.circle(0.0018, 3), "chain", closed=True))
            else:
                m.merge(S.sweep([(x, y + h, 0), (x, -0.01, 0)], S.circle(0.003, 3), "chain"))
            m.merge(S.lathe([(-0.012, 0.03), (0.0, 0.03)], 8, tag="plastic").transformed(np.eye(3), (x, 0, 0)))
    return {"body": Part(m)}


# --- exit_sign -------------------------------------------------------------------------------------------
def exit_sign(lod):
    w, h, d, y = EXIT["w"], EXIT["h"], EXIT["d"], EXIT["y"]
    m = Mesh()
    m.merge(S.chamfer_box((0, y, -d / 2), (w / 2, h / 2, d / 2), 0.01, "plastic", edges="front") if lod < 2 else S.box((0, y, -d / 2), (w / 2, h / 2, d / 2), "plastic"))
    m.merge(S.box((0, y, -d - 0.002), (w / 2 - 0.015, h / 2 - 0.012, 0.002), "exit"))
    if lod == 0:  # the test button and the charge light under the face
        m.merge(S.prism((w / 2 - 0.03, y - h / 2 + 0.005, -d / 2), 0.005, 0.004, 6, axis=(0, -1, 0), tag="exit"))
    return {"body": Part(m)}


def _inside(x, y, poly):
    inside = np.zeros(len(x), bool)
    for i in range(len(poly)):
        (ax, ay), (bx, by) = poly[i], poly[(i + 1) % len(poly)]
        cond = (ay > y) != (by > y)
        xc = ax + (y - ay) * (bx - ax) / np.where(by - ay == 0, 1e-9, by - ay)
        inside ^= cond & (x < xc)
    return inside


def _paint_exit(P, N, tag, tags, state, col):
    """The running man going out through a door, and the arrow: white on the green face (the
    reader's right is -x, so the figure runs to the reader's left: +x)."""
    w, y0 = EXIT["w"], EXIT["y"]
    sel = (tag == tags.index("exit")) & (N[:, 2] < -0.5)
    u, v = P[:, 0], P[:, 1] - y0           # u: +x is the reader's left
    door = _inside(u, v, [(0.03, -0.045), (0.075, -0.045), (0.075, 0.045), (0.03, 0.045)])
    man = [(0.005, 0.03), (0.02, 0.012), (0.035, 0.0), (0.03, -0.006), (0.014, 0.004), (0.01, -0.015), (0.03, -0.04), (0.02, -0.044),
           (0.0, -0.022), (-0.018, -0.044), (-0.026, -0.038), (-0.008, -0.015), (-0.01, 0.01), (-0.028, -0.002), (-0.03, 0.004), (-0.004, 0.026)]
    man = [(-x, y) for x, y in man]         # facing the door: he runs into it
    fig = _inside(u, v, man) | (np.hypot(u + 0.008, v - 0.042) < 0.009)
    arrow = _inside(u, v, [(-0.135, -0.008), (-0.095, -0.008), (-0.095, -0.022), (-0.06, 0.0), (-0.095, 0.022), (-0.095, 0.008), (-0.135, 0.008)])
    white = (door & ~fig) | (fig & ~door) | arrow
    return np.where((sel & white)[:, None], np.array([0.95, 0.97, 0.95], np.float32), col)


# --- extinguisher ------------------------------------------------------------------------------------------
def extinguisher(lod):
    r, h, y0 = EXT["r"], EXT["h"], EXT["y"]
    z = -0.10
    m = Mesh()
    sides = [14, 10, 6][lod]
    m.merge(S.lathe([(y0, 0.0), (y0, r * 0.85), (y0 + 0.02, r), (y0 + h - 0.06, r), (y0 + h - 0.01, r * 0.55), (y0 + h, r * 0.30)], sides, tag="red",
                    caps=(False, True)).transformed(np.eye(3), (0, 0, z)))
    # the valve head, its carrying handle and the lever over it, the pin
    m.merge(S.lathe([(y0 + h, 0.022), (y0 + h + 0.06, 0.022), (y0 + h + 0.07, 0.016)], [8, 6, 4][lod], tag="black").transformed(np.eye(3), (0, 0, z)))
    if lod < 2:
        m.merge(S.box((0, y0 + h + 0.05, z + 0.06), (0.012, 0.008, 0.07), "black"))
        m.merge(S.box((0, y0 + h + 0.085, z + 0.05), (0.012, 0.006, 0.07), "black").transformed(S.rotation((1, 0, 0), 0.12), (0, 0.0, 0)))
        m.merge(S.lathe([(-0.008, 0.012), (0.008, 0.012)], 6, tag="chain").transformed(S.rotation((0, 0, 1), np.pi / 2), (0.025, y0 + h + 0.06, z)))
        # the hose from the head round the body's side to the nozzle clipped low
        hose = [(-0.02, y0 + h + 0.03, z - 0.01), (-0.06, y0 + h + 0.01, z - 0.04), (-r - 0.015, y0 + h - 0.12, z - 0.05), (-r - 0.015, y0 + 0.15, z - 0.04)]
        m.merge(S.sweep(S.fillet(hose, 0.04, 3) if lod == 0 else hose, S.circle(0.009, 5), "black"))
        m.merge(S.lathe([(0.0, 0.012), (0.06, 0.015), (0.07, 0.01)], 6, tag="black").transformed(np.eye(3), (-r - 0.015, y0 + 0.08, z - 0.04)))
        # the label on its front
        m.merge(S.lathe([(y0 + 0.12, r + 0.0008), (y0 + 0.30, r + 0.0008)], sides, tag="label", caps=(False, False)).transformed(np.eye(3), (0, 0, z)))
    # the bracket: a plate on the wall, the hook under the head
    m.merge(S.box((0, y0 + h - 0.05, -0.004), (0.04, 0.08, 0.004), "black"))
    m.merge(S.box((0, y0 + h - 0.02, -0.03), (0.02, 0.012, 0.03), "black"))
    return {"body": Part(m)}


def _paint_ext(P, N, tag, tags, state, col):
    r, y0 = EXT["r"], EXT["y"]
    sel = tag == tags.index("label")
    front = (P[:, 2] + 0.10) < -r * 0.3
    rows = sel & front & (np.mod(P[:, 1] * 120, 1.0) < 0.3) & (P[:, 1] < y0 + 0.25)
    col = np.where(rows[:, None], np.array([0.25, 0.25, 0.28], np.float32), col)
    word = lettering.mask(P, "EAU", np.array([0, y0 + 0.28, -0.10 - r], np.float32), 0.025, (-1, 0, 0), (0, 1, 0), weight=1.4)
    return np.where((sel & front & word)[:, None], np.array([0.70, 0.08, 0.06], np.float32), col)


# --- alarm_point -------------------------------------------------------------------------------------------
def alarm_point(lod):
    s, d, y = ALARM["s"], ALARM["d"], ALARM["y"]
    m = Mesh()
    m.merge(S.chamfer_box((0, y, -d / 2), (s / 2, s / 2, d / 2), 0.006, "red", edges="front") if lod == 0 else S.box((0, y, -d / 2), (s / 2, s / 2, d / 2), "red"))
    m.merge(S.box((0, y - 0.004, -d - 0.002), (s * 0.3, s * 0.3, 0.002), "glass"))
    return {"body": Part(m)}


def _paint_alarm(P, N, tag, tags, state, col):
    s, d, y = ALARM["s"], ALARM["d"], ALARM["y"]
    front = N[:, 2] < -0.5
    words = lettering.mask(P, "ALARME", np.array([0, y + s * 0.40, -d], np.float32), 0.010, (-1, 0, 0), (0, 1, 0), weight=1.3)
    col = np.where((front & (tag == tags.index("red")) & words)[:, None], np.array([0.95, 0.95, 0.92], np.float32), col)
    press = lettering.mask(P, "APPUYER", np.array([0, y - 0.004, -d - 0.004], np.float32), 0.007, (-1, 0, 0), (0, 1, 0))
    return np.where((front & (tag == tags.index("glass")) & press)[:, None], np.array([0.15, 0.15, 0.15], np.float32), col)


# --- emergency_light ---------------------------------------------------------------------------------------
def emergency_light(lod):
    """The BAES d'ambiance: a white box on the wall at 2.3 m, its lit diffuser underneath, the green
    charge lamp on its face, the cable coming in from the top."""
    w, h, d, y = 0.33, 0.12, 0.07, 2.30
    m = Mesh()
    m.merge(S.chamfer_box((0, y, -d / 2), (w / 2, h / 2, d / 2), 0.008, "plastic") if lod == 0 else S.box((0, y, -d / 2), (w / 2, h / 2, d / 2), "plastic"))
    m.merge(S.box((0, y - h / 2 - 0.004, -d / 2), (w / 2 - 0.02, 0.004, d / 2 - 0.012), "tube"))
    if lod < 2:
        m.merge(S.box((w / 2 - 0.03, y + 0.02, -d - 0.002), (0.006, 0.006, 0.002), "exit"))
        m.merge(S.sweep([(0.0, y + h / 2, -0.012), (0.0, y + 0.60, -0.012)], [(-0.012, -0.008), (0.012, -0.008), (0.012, 0.008), (-0.012, 0.008)], "plastic", up=(0, 0, 1)))
    return {"body": Part(m)}


# --- switch_socket -----------------------------------------------------------------------------------------
def switch_socket(lod):
    """A switch at 1.10 m and a double socket at 0.30 m, joined by a white trunking down the wall."""
    m = Mesh()
    for y, w in ((1.10, 0.085), (0.30, 0.155)):
        m.merge(S.chamfer_box((0, y, -0.006), (w / 2, 0.0425, 0.006), 0.003, "plastic") if lod == 0 else S.box((0, y, -0.006), (w / 2, 0.0425, 0.006), "plastic"))
    if lod < 2:
        m.merge(S.box((0, 1.10, -0.0135), (0.028, 0.028, 0.0015), "plastic"))                         # the rocker
        for x in (-0.039, 0.039):                                                                    # the sockets' wells and pins
            m.merge(S.lathe([(0.0, 0.019), (0.002, 0.019), (0.002, 0.0)], [12, 6][lod], tag="black").transformed(S.rotation((1, 0, 0), -np.pi / 2), (x, 0.30, -0.012)))
            if lod == 0:
                for px in (-0.0095, 0.0095):
                    m.merge(S.box((x + px, 0.30, -0.0145), (0.002, 0.002, 0.002), "black"))
    m.merge(S.box((0, 0.70, -0.009), (0.02, 0.35, 0.009), "plastic"))
    m.merge(S.box((0, 1.13 + 0.80, -0.009), (0.02, 0.80, 0.009), "plastic"))                       # up to the ceiling
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "emergency_light": dict(build=emergency_light, materials=materials(), edge_radius=0.002, close=(0.0, 2.3, -0.05), **_SPEC),
    "switch_socket": dict(build=switch_socket, materials=materials(), edge_radius=0.001, close=(0.0, 0.7, -0.02), **_SPEC),
    "tube_light": dict(build=tube_light, materials=materials(), edge_radius=0.002, close=(0.5, -0.4, 0.0), **_SPEC),
    "exit_sign": dict(build=exit_sign, materials=materials(), extra=_paint_exit, extra_first=True, edge_radius=0.002, close=(0.0, EXIT["y"], -0.07), **_SPEC),
    "extinguisher": dict(build=extinguisher, materials=materials(), extra=_paint_ext, extra_first=True, edge_radius=0.002, close=(0.0, 1.1, -0.1), **_SPEC),
    "alarm_point": dict(build=alarm_point, materials=materials(), extra=_paint_alarm, extra_first=True, edge_radius=0.002, close=(0.0, ALARM["y"], -0.05),
                        states=["clean", "abandoned", "damaged", "burnt"], lods=2),
}
