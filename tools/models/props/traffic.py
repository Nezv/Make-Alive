"""Traffic lights (S168). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

traffic_light: the French signal on a short pole at the kerb (short_pole, repeater): a dark
grey pole, the three-lens head (200 mm lenses, a visor over each) on its side at the top, the small
repeater head at the drivers' eye height under it, the pedestrians' push-button box.
traffic_light_ped: the pedestrians' head on its own pole: two lenses, the red man standing and the
green man walking as lit figures on dark lenses.
controller_cabinet: the grey cabinet at the corner that runs the junction: a box on a plinth, its
door with a lock and hinges, vents, a roof that sheds rain.

The lenses glow by their emission map (all lit); which one is on is the game's (S046, S108).
Standing on y = 0, the pole at x = z = 0, the heads looking at -Z.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

POLE = dict(r=0.055, h=3.10)
HEAD = dict(lens=0.10, pitch=0.30, w=0.30, d=0.22, top=3.05)   # the main head: lens radius, spacing, box
REPEAT = dict(lens=0.05, pitch=0.13, w=0.15, d=0.12, top=1.75)
CAB = dict(w=0.80, h=1.30, d=0.40)


def materials():
    return {
        "grey": Material((0.20, 0.21, 0.21), under=(0.40, 0.40, 0.38), bare=(0.42, 0.30, 0.20), chip=0.4, grain=0.05),
        "head": Material((0.08, 0.08, 0.09), under=(0.25, 0.25, 0.25), bare=(0.30, 0.30, 0.30), chip=0.2, rusts=False, grain=0.04),
        "red": Material((0.55, 0.06, 0.04), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.12, 0.06)),
        "amber": Material((0.62, 0.36, 0.04), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.55, 0.08)),
        "green": Material((0.05, 0.42, 0.30), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.15, 1.0, 0.65)),
        "lens": Material((0.05, 0.05, 0.05), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False),
        "cabinet": Material((0.62, 0.64, 0.60), under=(0.50, 0.50, 0.48), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.05),
        "concrete": Material((0.55, 0.54, 0.51), kind="concrete", chip=0.0, rusts=False, grain=0.15),
        "button": Material((0.85, 0.72, 0.10), under=(0.3, 0.3, 0.3), bare=(0.3, 0.3, 0.3), chip=0.5, rusts=False, grain=0.04),
        "bolt": Material((0.40, 0.40, 0.40), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


def _pole(lod, h=POLE["h"]):
    r = POLE["r"]
    sides = [12, 8, 5][lod]
    prof = [(0.0, r + 0.03), (0.03, r + 0.02), (0.05, r + 0.004), (0.40, r), (h, r * 0.85), (h + 0.02, r * 0.85), (h + 0.04, 0.0)]
    return S.lathe(prof, sides, tag="grey")


def _head(spec, lenses, lod, x=0.0, z=None):
    """A signal head hung in front of the pole: a box with its lenses down the front, a visor over
    each, its bracket to the pole. `lenses`: the tags from the top down."""
    m = Mesh()
    w, d, p, lr, top = spec["w"], spec["d"], spec["pitch"], spec["lens"], spec["top"]
    h = p * len(lenses)
    z = -POLE["r"] - d / 2 - 0.02 if z is None else z
    cy = top - h / 2
    c = 0.02 if lod == 0 else 0.0
    m.merge(S.chamfer_box((x, cy, z), (w / 2, h / 2, d / 2), c, "head", edges="vertical") if c else S.box((x, cy, z), (w / 2, h / 2, d / 2), "head"))
    sides = [16, 10, 6][lod]
    zf = z - d / 2
    for i, t in enumerate(lenses):
        y = top - p * (i + 0.5)
        m.merge(S.prism((x, y, zf), lr, 0.012, sides, axis=(0, 0, -1), tag=t))
        if lod < 2:  # the visor: half a tube over the lens
            n = [8, 4][lod]
            arc = [(x + np.cos(a) * (lr + 0.015), y + np.sin(a) * (lr + 0.015)) for a in np.linspace(-0.25, np.pi + 0.25, n + 1)]
            outer = arc + [(x + (px - x) * 0.9, y + (py - y) * 0.9) for px, py in arc[::-1]]
            m.merge(S.extrude([(px - x, py - y) for px, py in outer], lr * 1.8, 0.0, "head", origin=(x, y, zf), right=(1, 0, 0), up=(0, 1, 0)))
    # the bracket: two arms from the box's back to the pole, a clamp each
    for y in (top - 0.06, top - h + 0.06):
        m.merge(S.box((x * 0.5, y, (z + d / 2) / 2 - POLE["r"] / 2), (max(abs(x) * 0.5, 0.02), 0.02, abs(z + d / 2 + POLE["r"]) / 2 + 0.01), "grey"))
        if lod == 0:
            m.merge(S.lathe([(-0.025, POLE["r"] + 0.008), (0.025, POLE["r"] + 0.008)], 8, tag="grey", caps=(False, False)).transformed(np.eye(3), (0, y, 0)))
    return m


def traffic_light(lod):
    m = _pole(lod)
    m.merge(_head(HEAD, ["red", "amber", "green"], lod))
    m.merge(_head(REPEAT, ["red", "amber", "green"], lod))
    # the push-button box for the pedestrians, on the kerb's side of the pole
    m.merge(S.chamfer_box((0.0, 1.05, POLE["r"] + 0.05), (0.06, 0.10, 0.04), 0.008 if lod == 0 else 0.0, "button", edges="vertical")
            if lod == 0 else S.box((0.0, 1.05, POLE["r"] + 0.05), (0.06, 0.10, 0.04), "button"))
    if lod < 2:
        m.merge(S.prism((0.0, 1.07, POLE["r"] + 0.09), 0.022, 0.01, 10, axis=(0, 0, 1), tag="head"))
    return {"body": Part(m)}


# --- the pedestrians' head -----------------------------------------------------------------------------
def _man(walking):
    """The figure on a lens, as (x, y) round the lens's middle, 0.13 m tall."""
    if walking:
        return [(-0.01, 0.065), (0.012, 0.065), (0.014, 0.04), (0.035, 0.01), (0.03, 0.0), (0.012, 0.02), (0.012, -0.01), (0.035, -0.06),
                (0.022, -0.065), (0.0, -0.025), (-0.025, -0.065), (-0.037, -0.06), (-0.012, -0.01), (-0.012, 0.02), (-0.03, 0.0), (-0.035, 0.008)]
    return [(-0.012, 0.065), (0.012, 0.065), (0.014, 0.045), (0.03, 0.04), (0.03, -0.005), (0.016, -0.005), (0.016, -0.065), (0.003, -0.065),
            (0.0, -0.02), (-0.003, -0.065), (-0.016, -0.065), (-0.016, -0.005), (-0.03, -0.005), (-0.03, 0.04), (-0.014, 0.045)]


def traffic_light_ped(lod):
    m = _pole(lod, 2.60)
    spec = dict(HEAD, top=2.55)
    m.merge(_head(spec, ["lens", "lens"], lod))
    zf = -POLE["r"] - spec["d"] - 0.02 - 0.013
    for i, (walk, tag) in enumerate(((False, "red"), (True, "green"))):
        y = spec["top"] - spec["pitch"] * (i + 0.5)
        if lod < 2:
            m.merge(S.extrude(_man(walk), 0.004, 0.0, tag, origin=(0, y, zf), right=(1, 0, 0), up=(0, 1, 0)))
            m.merge(S.prism((0.0, y + 0.085, zf), 0.018, 0.004, 8, axis=(0, 0, -1), tag=tag))  # the head
        else:
            m.merge(S.box((0, y, zf - 0.002), (0.03, 0.06, 0.002), tag))
    return {"body": Part(m)}


# --- the controller's cabinet --------------------------------------------------------------------------
def controller_cabinet(lod):
    w, h, d = CAB["w"], CAB["h"], CAB["d"]
    m = Mesh()
    m.merge(S.box((0, 0.06, 0), (w / 2 + 0.05, 0.06, d / 2 + 0.05), "concrete"))
    body = S.chamfer_box((0, 0.12 + h / 2, 0), (w / 2, h / 2, d / 2), 0.01, "cabinet", edges="vertical") if lod < 2 else S.box((0, 0.12 + h / 2, 0), (w / 2, h / 2, d / 2), "cabinet")
    m.merge(body)
    # the roof: a lid sloping back, its drip over the front
    m.merge(S.extrude([(-d / 2 - 0.03, 0.12 + h), (d / 2 + 0.02, 0.12 + h), (d / 2 + 0.02, 0.12 + h + 0.03), (-d / 2 - 0.03, 0.12 + h + 0.05)],
                      w + 0.04, 0.0, "cabinet", origin=(-w / 2 - 0.02, 0, 0), right=(0, 0, 1), up=(0, 1, 0)))
    if lod < 2:
        # the door: a panel with its rebate, two hinges, a lock, vents at the foot and the head
        m.merge(S.panel(w - 0.08, h - 0.10, t=0.006, border=0.03, kind="inset", depth=0.003, bevel=0.01, tag="cabinet",
                        origin=(0, 0.12 + h / 2, -d / 2)))
        for y in (0.12 + 0.12, 0.12 + h - 0.12):
            m.merge(S.box((-w / 2 + 0.03, y, -d / 2 - 0.01), (0.012, 0.05, 0.01), "grey"))
        m.merge(S.prism((w / 2 - 0.09, 0.12 + h / 2, -d / 2 - 0.006), 0.015, 0.012, 10, axis=(0, 0, -1), tag="bolt"))
        for y0 in (0.12 + 0.10, 0.12 + h - 0.22):
            for k in range(5 if lod == 0 else 2):
                m.merge(S.box((0, y0 + k * 0.025 if lod == 0 else y0 + k * 0.05, -d / 2 - 0.008), (w / 2 - 0.16, 0.006, 0.004), "grey"))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3, edge_radius=0.003)

ELEMENTS = {
    "traffic_light": dict(build=traffic_light, materials=materials(), close=(0.0, HEAD["top"] - 0.45, -0.2), **_SPEC),
    "traffic_light_ped": dict(build=traffic_light_ped, materials=materials(), close=(0.0, 2.25, -0.2), **_SPEC),
    "controller_cabinet": dict(build=controller_cabinet, materials=materials(), close=(0.0, 0.8, -CAB["d"] / 2), **_SPEC),
}
