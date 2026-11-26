"""The hospital's generator room (S212). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

genset: the emergency diesel generator set: a steel skid on anti-vibration mounts, the engine block
with its rocker covers and injector pipes, the air filter, the radiator at the front behind its fan
guard, the alternator at the back with its terminal box, the exhaust rising from the manifold through
a flexible section to the silencer, the control box on its bracket.
fuel_tank: the day tank: a bunded steel tank on legs, its gauge, the fill cap, the vent, the feed
pipe out at the foot, the drip tray.
switchgear: the transfer switchgear: three steel cabinets side by side, louvres, meters, lamps (the
mains and the generator), breakers' handles, the start lever (part `lever`, thrown up from OFF to
START) on the middle door, the cable tray over them.

Standing on y = 0, the front -Z (where the engineer stands).
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

GEN = dict(len=2.80, w=1.10, skid=0.20)


def materials():
    return {
        "engine": Material((0.20, 0.38, 0.26), under=(0.40, 0.40, 0.40), bare=(0.35, 0.30, 0.26), chip=0.5, grain=0.06, fixing=True),
        "yellow": Material((0.85, 0.66, 0.10), under=(0.40, 0.40, 0.40), bare=(0.35, 0.30, 0.26), chip=0.5, grain=0.05),
        "steel": Material((0.48, 0.49, 0.50), under=(0.40, 0.40, 0.40), bare=(0.40, 0.30, 0.22), chip=0.4, grain=0.06, fixing=True),
        "grey": Material((0.70, 0.71, 0.70), under=(0.55, 0.56, 0.55), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.04),
        "dark": Material((0.07, 0.07, 0.07), chip=0.0, rusts=False, grain=0.02, fades=False),
        "rubber": Material((0.10, 0.10, 0.10), kind="rubber", chip=0.0, rusts=False, grain=0.04),
        "pipe": Material((0.36, 0.30, 0.26), under=(0.35, 0.28, 0.22), bare=(0.40, 0.25, 0.15), chip=0.0, grain=0.12),
        "copper": Material((0.70, 0.42, 0.24), under=(0.5, 0.3, 0.2), bare=(0.5, 0.3, 0.2), chip=0.0, rusts=False, grain=0.04, fades=False),
        "red": Material((0.65, 0.10, 0.08), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.18, 0.12)),
        "green": Material((0.15, 0.60, 0.25), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.25, 1.0, 0.35)),
        "dial": Material((0.92, 0.92, 0.88), kind="paper", chip=0.0, rusts=False, grain=0.02),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- genset ------------------------------------------------------------------------------------------------
def genset(lod):
    L, W, sk = GEN["len"], GEN["w"], GEN["skid"]
    m = Mesh()
    # the skid: two channels and cross members on rubber mounts
    for s in (1, -1):
        m.merge(S.box((0, sk / 2, s * (W / 2 - 0.05)), (L / 2, sk / 2, 0.05), "steel"))
    for x in np.linspace(-L / 2 + 0.1, L / 2 - 0.1, 4):
        m.merge(S.box((x, sk * 0.75, 0), (0.05, sk * 0.25, W / 2 - 0.08), "steel"))
    y0 = sk
    # the engine block, the sump, two rocker covers, the oil filler
    xe0, xe1 = -L / 2 + 0.45, 0.35
    m.merge(_cb(((xe0 + xe1) / 2, y0 + 0.12, 0), ((xe1 - xe0) / 2, 0.12, 0.28), 0.02, "engine", lod))
    m.merge(_cb(((xe0 + xe1) / 2, y0 + 0.24 + 0.27, 0), ((xe1 - xe0) / 2, 0.27, 0.30), 0.02, "engine", lod))
    for s in (1, -1):
        m.merge(_cb(((xe0 + xe1) / 2, y0 + 0.85, s * 0.13), ((xe1 - xe0) / 2 - 0.05, 0.07, 0.10), 0.02, "engine", lod))
    if lod < 2:
        # the injector pipes over the rocker covers, the manifolds down the side
        for k in range(6):
            x = xe0 + 0.12 + k * (xe1 - xe0 - 0.24) / 5
            m.merge(S.sweep([(x, y0 + 0.92, -0.02), (x, y0 + 0.98, -0.05), (x - 0.05, y0 + 0.98, -0.32)] if lod == 0 else [(x, y0 + 0.92, -0.02), (x, y0 + 0.92, -0.30)],
                            S.circle(0.006, 4), "steel"))
        m.merge(S.box(((xe0 + xe1) / 2, y0 + 0.62, -0.34), ((xe1 - xe0) / 2 - 0.05, 0.06, 0.05), "pipe"))
        m.merge(S.box(((xe0 + xe1) / 2, y0 + 0.42, 0.34), ((xe1 - xe0) / 2 - 0.08, 0.06, 0.04), "engine"))
        # the air filter: a drum on the inlet side
        m.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.14), (0.30, 0.14), (0.30, 0.0)], [12, 8][lod], tag="yellow"), (0, 0, 1), (xe0 + 0.25, y0 + 0.95, 0.30)))
    # the radiator at the front (-X end), its core, the fan guard and the cap
    xr = -L / 2 + 0.12
    m.merge(_cb((xr, y0 + 0.62, 0), (0.10, 0.62, W / 2 - 0.08), 0.01, "engine", lod))
    m.merge(S.box((xr - 0.101, y0 + 0.62, 0), (0.001, 0.52, W / 2 - 0.16), "dark"))
    if lod < 2:
        for k in range([12, 6][lod]):  # the guard's bars across the core
            y = y0 + 0.14 + k * 0.96 / ([12, 6][lod] - 1)
            m.merge(S.box((xr - 0.11, y, 0), (0.006, 0.006, W / 2 - 0.16), "steel"))
        m.merge(S.lathe([(y0 + 1.24, 0.04), (y0 + 1.30, 0.045), (y0 + 1.30, 0.0)], 8, tag="steel").transformed(np.eye(3), (xr, 0, 0.2)))
        m.merge(S.sweep([(xr + 0.1, y0 + 0.90, 0.20), (xe0, y0 + 0.75, 0.20)], S.circle(0.035, 6), "rubber"))
    # the alternator behind the engine: a drum with its ribs, the terminal box on top
    xa0, xa1 = xe1, L / 2 - 0.10
    alt = S.lathe([(0.0, 0.0), (0.0, 0.36), (xa1 - xa0, 0.36), (xa1 - xa0, 0.0)], [16, 10, 6][lod], tag="engine",
                  flute=(lambda j, y: 1.0 + 0.04 * (j % 2)) if lod == 0 else None)
    m.merge(S.along(alt, (1, 0, 0), (xa0, y0 + 0.42, 0)))
    m.merge(_cb(((xa0 + xa1) / 2, y0 + 0.88, 0), (0.25, 0.12, 0.22), 0.01, "engine", lod))
    if lod < 2:
        for s in (1, -1):  # its feet on the skid
            m.merge(S.box(((xa0 + xa1) / 2, y0 + 0.05, s * 0.28), (0.30, 0.05, 0.06), "engine"))
        # the cable glands and the cables down into the floor trench
        for k in range(3):
            z = -0.12 + k * 0.12
            m.merge(S.sweep([((xa0 + xa1) / 2 + 0.25, y0 + 0.88, z), (xa1 + 0.15, y0 + 0.80, z), (xa1 + 0.15, 0.0, z)], S.circle(0.022, 6), "rubber"))
    # the exhaust: from the manifold up through the flexible section to the silencer over the set
    ex = [(xe0 + 0.30, y0 + 0.66, -0.40), (xe0 + 0.30, y0 + 1.25, -0.40), (xe0 + 0.30, y0 + 1.55, -0.20)]
    m.merge(S.sweep(ex, S.circle(0.055, [10, 6, 4][lod]), "pipe"))
    if lod == 0:  # the bellows' corrugations
        for y in np.linspace(y0 + 0.90, y0 + 1.15, 6):
            m.merge(S.lathe([(y, 0.064), (y + 0.02, 0.064)], 10, tag="steel").transformed(np.eye(3), (xe0 + 0.30, 0, -0.40)))
    m.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.16), (1.10, 0.16), (1.10, 0.0)], [12, 8, 6][lod], tag="pipe"), (1, 0, 0), (xe0 + 0.30, y0 + 1.60, -0.20)))
    m.merge(S.sweep([(xe0 + 1.40, y0 + 1.60, -0.20), (xe0 + 1.60, y0 + 1.60, -0.20), (xe0 + 1.60, y0 + 2.20, -0.20)], S.circle(0.055, [10, 6, 4][lod]), "pipe"))
    # the control box on its bracket by the alternator
    m.merge(S.box((xa0 + 0.05, y0 + 1.00, -0.42), (0.02, 0.25, 0.02), "steel"))
    m.merge(_cb((xa0 + 0.05, y0 + 1.30, -0.48), (0.20, 0.16, 0.07), 0.008, "grey", lod))
    if lod < 2:
        m.merge(S.box((xa0 + 0.05, y0 + 1.34, -0.551), (0.12, 0.06, 0.001), "dark"))
        m.merge(S.box((xa0 - 0.08, y0 + 1.20, -0.556), (0.02, 0.02, 0.006), "red"))
        m.merge(S.box((xa0 + 0.18, y0 + 1.20, -0.556), (0.02, 0.02, 0.006), "green"))
    return {"body": Part(m)}


# --- fuel_tank -----------------------------------------------------------------------------------------------
def fuel_tank(lod):
    m = Mesh()
    w, h, d = 1.20, 0.80, 0.60
    for sx in (1, -1):
        for sz in (1, -1):
            m.merge(S.box((sx * (w / 2 - 0.05), 0.20, sz * (d / 2 - 0.05)), (0.025, 0.20, 0.025), "steel"))
    m.merge(_cb((0, 0.40 + h / 2, 0), (w / 2, h / 2, d / 2), 0.015, "steel", lod))
    if lod < 2:  # the bund's lip round the tank, the sight gauge, the fill cap, the vent, the feed pipe and valve
        m.merge(S.box((0, 0.44, 0), (w / 2 + 0.04, 0.04, d / 2 + 0.04), "steel"))
        m.merge(S.box((w / 2 - 0.15, 0.40 + h / 2, -d / 2 - 0.015), (0.02, h / 2 - 0.08, 0.015), "dial"))
        m.merge(S.lathe([(0.40 + h, 0.06), (0.40 + h + 0.05, 0.06), (0.40 + h + 0.06, 0.0)], [10, 6][lod], tag="yellow").transformed(np.eye(3), (-0.30, 0, 0)))
        m.merge(S.sweep([(0.30, 0.40 + h, 0.15), (0.30, 0.40 + h + 0.40, 0.15), (0.35, 0.40 + h + 0.48, 0.15)], S.circle(0.015, 6), "steel"))
        m.merge(S.sweep([(-w / 2, 0.48, 0.0), (-w / 2 - 0.30, 0.48, 0.0), (-w / 2 - 0.30, 0.0, 0.0)], S.circle(0.015, 6), "copper"))
        m.merge(S.box((-w / 2 - 0.15, 0.48, 0.0), (0.03, 0.03, 0.03), "red" if lod == 0 else "steel"))
    m.merge(S.box((0, 0.02, 0), (w / 2 + 0.10, 0.02, d / 2 + 0.10), "steel"))       # the drip tray
    return {"body": Part(m)}


def _paint_tank(P, N, tag, tags, state, col):
    """The tank's words on its front: GAZOLE, and the level's marks on the gauge."""
    import lettering
    sel = (tag == tags.index("steel")) & (N[:, 2] < -0.5) & (P[:, 1] > 0.8) & (P[:, 1] < 1.1)
    words = lettering.mask(P, "GAZOLE", np.array([-0.15, 0.95, -0.301], np.float32), 0.09, (-1, 0, 0), (0, 1, 0), weight=1.4)
    col = np.where((sel & words)[:, None], np.array([0.85, 0.66, 0.10], np.float32), col)
    g = (tag == tags.index("dial")) & (np.mod(P[:, 1], 0.08) < 0.006)
    return np.where(g[:, None], col * 0.3, col)


# --- switchgear ----------------------------------------------------------------------------------------------
def switchgear(lod):
    m = Mesh()
    cw, h, d = 0.80, 2.00, 0.60
    for k in range(3):
        x = (k - 1) * cw
        m.merge(_cb((x, 0.05 + h / 2, 0), (cw / 2 - 0.003, h / 2, d / 2), 0.006, "grey", lod))
        m.merge(S.box((x, 0.025, 0), (cw / 2 - 0.01, 0.025, d / 2 - 0.02), "dark"))
        if lod < 2:
            # the door's seam and hinges, the handle, the louvres at the foot and the head
            m.merge(S.box((x, 0.05 + h / 2, -d / 2 - 0.001), (cw / 2 - 0.04, h / 2 - 0.04, 0.001), "grey"))
            m.merge(S.box((x - cw / 2 + 0.07, 1.00, -d / 2 - 0.02), (0.012, 0.09, 0.02), "dark"))
            for y in (0.25, 1.85):
                for j in range([5, 3][lod]):
                    m.merge(S.box((x, y + j * 0.025 - 0.05, -d / 2 - 0.004), (cw / 2 - 0.16, 0.004, 0.004), "dark"))
        if k != 1 and lod < 2:  # meters and lamps on the outer cabinets, a row of breakers' handles behind a window
            for j in range(3):
                c = (x - 0.20 + j * 0.20, 1.55, -d / 2 - 0.006)
                m.merge(S.box(c, (0.07, 0.07, 0.006), "dark"))
                if lod == 0:
                    m.merge(S.box((c[0], c[1], c[2] - 0.004), (0.058, 0.058, 0.002), "dial"))
                    m.merge(S.box((c[0] + 0.02, c[1] - 0.01, c[2] - 0.007), (0.025, 0.002, 0.001), "dark"))
            m.merge(S.box((x - 0.15, 1.38, -d / 2 - 0.01), (0.025, 0.025, 0.01), "green" if k == 0 else "red"))
            for j in range(6):
                m.merge(S.box((x - 0.25 + j * 0.10, 1.00, -d / 2 - 0.02), (0.02, 0.06, 0.02), "dark"))
    # the start lever on the middle door: its plate, the arm that throws up from OFF to START
    m.merge(_cb((0, 1.25, -d / 2 - 0.01), (0.14, 0.22, 0.01), 0.004, "yellow", lod))
    lever = Mesh()
    lever.merge(S.along(S.lathe([(0.0, 0.035), (0.04, 0.035), (0.05, 0.02), (0.05, 0.0)], [10, 6, 4][lod], tag="dark"), (0, 0, -1), (0, 1.15, -d / 2 - 0.02)))
    lever.merge(S.sweep([(0, 1.15, -d / 2 - 0.06), (0, 0.98, -d / 2 - 0.07)], S.circle(0.014, [6, 4, 4][lod]), "red" if lod == 0 else "dark"))
    if lod < 2:
        lever.merge(S.along(S.lathe([(0.0, 0.0), (0.0, 0.025), (0.08, 0.025), (0.08, 0.0)], [8, 5][lod], tag="dark"), (0, -1, 0), (0, 0.98, -d / 2 - 0.07)))
    parts = {}
    parts["lever"] = Part(lever, (0, 1.15, -d / 2 - 0.05), {"rotate": [[0, 0, -1], 150.0]})
    # the cable tray over the cabinets, cables dropping into them
    if lod < 2:
        m.merge(S.box((0, h + 0.40, 0.05), (1.40, 0.004, 0.15), "steel"))
        for s in (1, -1):
            m.merge(S.box((0, h + 0.44, 0.05 + s * 0.15), (1.40, 0.04, 0.003), "steel"))
        for k in range(3):
            m.merge(S.sweep([((k - 1) * cw + 0.2, h + 0.41, 0.05), ((k - 1) * cw + 0.2, h + 0.05, 0.05)], S.circle(0.02, 5), "rubber"))
    return dict({"body": Part(m)}, **parts)


def _paint_switch(P, N, tag, tags, state, col):
    """MARCHE / ARRÊT on the lever's plate."""
    import lettering
    sel = (tag == tags.index("yellow")) & (N[:, 2] < -0.5)
    words = lettering.mask(P, "MARCHE", np.array([0, 1.40, -0.321], np.float32), 0.035, (-1, 0, 0), (0, 1, 0), weight=1.3) | \
        lettering.mask(P, "ARRÊT", np.array([0, 1.08, -0.321], np.float32), 0.035, (-1, 0, 0), (0, 1, 0), weight=1.3)
    return np.where((sel & words)[:, None], col * 0.15, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "genset": dict(build=genset, materials=materials(), edge_radius=0.004, close=(-0.6, 0.9, -0.5), **_SPEC),
    "fuel_tank": dict(build=fuel_tank, materials=materials(), extra=_paint_tank, edge_radius=0.004, close=(0.0, 0.8, -0.3), **_SPEC),
    "switchgear": dict(build=switchgear, materials=materials(), extra=_paint_switch, edge_radius=0.003, close=(0.0, 1.2, -0.3), **_SPEC),
}
