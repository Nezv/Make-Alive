"""The town hall's name and arms (S218). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

townhall_name: the name over the door: a stone panel with its moulded frame and gilded raised
letters HÔTEL DE VILLE, the republic's motto on the frieze band under it.
town_arms: the town's arms in the pediment (invented, never a real town's): a cartouche of scrolls,
the shield (azure, a tower argent, on a chief gules three mullets or), the mural crown over it, oak
and laurel branches round it, the ribbon with an invented motto.

On the wall's face z = 0, the front -Z, the bottom y = 0.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

NAME = dict(w=5.20, h=0.70, t=0.12, text="HÔTEL DE VILLE", motto="LIBERTÉ - ÉGALITÉ - FRATERNITÉ")
ARMS = dict(w=0.90, h=1.05, motto="VIGILAT ET LABORAT")       # invented


def materials():
    return {
        "stone": Material((0.80, 0.76, 0.66), kind="stone", chip=0.0, rusts=False, grain=0.12),
        "gilt": Material((0.82, 0.64, 0.26), under=(0.55, 0.45, 0.30), bare=(0.60, 0.56, 0.48), chip=0.4, rusts=False, grain=0.04, fades=False),
        "field": Material((0.80, 0.76, 0.66), kind="stone", chip=0.0, rusts=False, grain=0.08),
        "silver": Material((0.85, 0.85, 0.82), under=(0.6, 0.6, 0.58), bare=(0.60, 0.56, 0.48), chip=0.3, rusts=False, grain=0.04),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- townhall_name ------------------------------------------------------------------------------------------
def townhall_name(lod):
    w, h, t = NAME["w"], NAME["h"], NAME["t"]
    m = Mesh()
    yc = 0.30 + h / 2
    m.merge(_cb((0, yc, -t / 2), (w / 2, h / 2, t / 2), 0.01, "stone", lod))
    if lod < 2:  # the moulded frame round the panel
        mould = [(0.0, 0.0), (0.06, 0.0), (0.06, -0.03), (0.03, -0.045), (0.0, -0.05)]
        m.merge(S.opening_frame(w - 0.12, h - 0.12, mould if lod == 0 else [(0.0, 0.0), (0.06, 0.0), (0.06, -0.04), (0.0, -0.04)],
                                origin=(0, 0.30 + 0.06, -t), tag="stone", bottom=True))
    if lod < 2:  # far off the letters are gone into the panel
        m.merge(lettering.mesh(NAME["text"], 0.36, 0.025, origin=(0, yc - 0.18, -t), right=(-1, 0, 0), up=(0, 1, 0), weight=1.4, tag="gilt"))
    # the frieze band under it with the motto, cut in (painted)
    m.merge(_cb((0, 0.15, -0.04), (w / 2 + 0.20, 0.13, 0.04), 0.008, "stone", lod))
    return {"body": Part(m)}


def _paint_name(P, N, tag, tags, state, col):
    sel = (tag == tags.index("stone")) & (N[:, 2] < -0.5) & (np.abs(P[:, 2] + 0.08) < 0.005)
    words = lettering.mask(P, NAME["motto"], np.array([0, 0.11, -0.081], np.float32), 0.09, (-1, 0, 0), (0, 1, 0), weight=1.2)
    return np.where((sel & words)[:, None], col * 0.45, col)


# --- town_arms ----------------------------------------------------------------------------------------------
def _shield_outline(w, h, n):
    """The French shield: straight sides, rounded corners at the foot meeting in a point."""
    pts = [(-w / 2, h), (w / 2, h), (w / 2, h * 0.35)]
    for a in np.linspace(0, 1, n):
        x = w / 2 * (1 - a) ** 1.3
        y = h * 0.35 * (1 - a) ** 0.8 * (1 - a * 0.0)
        pts.append((x, y))
    pts = pts[:-1] + [(0.0, 0.0)]
    pts += [(-x, y) for x, y in reversed(pts[3:-1])] + [(-w / 2, h * 0.35)]
    return pts


def _star(c, r, z, depth, tag):
    pts = []
    for k in range(10):
        a = np.pi / 2 + k * np.pi / 5
        rr = r if k % 2 == 0 else r * 0.42
        pts.append((c[0] + np.cos(a) * rr, c[1] + np.sin(a) * rr))
    return S.extrude(pts, depth, 0.0, tag, origin=(0, 0, z), right=(1, 0, 0), up=(0, 1, 0))


def town_arms(lod):
    w, h = ARMS["w"], ARMS["h"]
    m = Mesh()
    y0 = 0.30
    # the cartouche: a scrolled stone frame behind the shield
    n = [24, 12, 8][lod]
    oval = [(np.cos(a) * (w / 2 + 0.22), y0 + h / 2 + np.sin(a) * (h / 2 + 0.18)) for a in np.linspace(0, 2 * np.pi, n + 1)[:-1]]
    m.merge(S.extrude(oval, 0.10, 0.02 if lod == 0 else 0.0, "stone", origin=(0, 0, 0), right=(1, 0, 0), up=(0, 1, 0)))
    if lod < 2:
        for s in (1, -1):  # the scrolls curling out at its sides
            sc = [(s * (w / 2 + 0.22 + 0.10 * (1 - a / 9) * np.cos(a)), y0 + h * 0.55 + 0.10 * (1 - a / 9) * np.sin(a), -0.12) for a in np.linspace(0, 1.7 * np.pi, [10, 6][lod])]
            m.merge(S.sweep(sc, S.circle(0.035, 5), "stone"))
    # the shield, its field, the tower and the chief's stars in relief
    sh = [(x, y + y0) for x, y in _shield_outline(w, h, [8, 5, 3][lod])]
    m.merge(S.extrude(sh, 0.05, 0.01 if lod == 0 else 0.0, "field", origin=(0, 0, -0.10), right=(1, 0, 0), up=(0, 1, 0)))
    zf = -0.15
    if lod < 2:
        tw = 0.30
        tower = Mesh()
        tower.merge(S.box((0, y0 + 0.40, zf - 0.02), (tw / 2, 0.20, 0.02), "silver"))
        for k in range(4):  # the crenellations
            tower.merge(S.box((-tw / 2 + 0.04 + k * (tw - 0.08) / 3, y0 + 0.63, zf - 0.02), (0.025, 0.03, 0.02), "silver"))
        tower.merge(S.box((0, y0 + 0.30, zf - 0.041), (0.04, 0.09, 0.002), "field"))     # its door, the field showing through
        m.merge(tower)
        for k in range(3):
            m.merge(_star((-0.24 + k * 0.24, y0 + h - 0.13), 0.07, zf, 0.02, "gilt"))
    # the mural crown: a band with towers over the shield
    yc = y0 + h + 0.04
    m.merge(S.box((0, yc + 0.05, -0.10), (w / 2 - 0.05, 0.05, 0.06), "gilt"))
    for k in range(5 if lod < 2 else 0):
        x = -w / 2 + 0.12 + k * (w - 0.24) / 4
        m.merge(S.box((x, yc + 0.16, -0.10), (0.05, 0.07, 0.06), "gilt"))
        if lod == 0:
            for j in (-1, 1):
                m.merge(S.box((x + j * 0.03, yc + 0.25, -0.10), (0.015, 0.02, 0.06), "gilt"))
    # oak and laurel branches round the shield: stems with leaves; the ribbon under it with the motto
    if lod < 2:
        for s in (1, -1):
            stem = [(s * (0.10 + (w / 2 + 0.10) * np.sin(a)), y0 - 0.05 + (h * 0.8) * (1 - np.cos(a)) * 0.9, -0.16) for a in np.linspace(0.1, 1.5, [9, 5][lod])]
            m.merge(S.sweep(stem, S.circle(0.012, 4), "stone"))
            if lod == 0:
                for i, p in enumerate(stem[1:]):
                    for j in (-1, 1):
                        leaf = S.lathe([(0.0, 0.0), (0.03, 0.018), (0.07, 0.0)], 4, tag="stone")
                        m.merge(S.along(leaf, (s * 0.6 * j + 0.2, 0.8, -0.1), p))
        rib = [(x, y0 - 0.14 + 0.05 * (x / 0.6) ** 2, -0.14) for x in np.linspace(-0.62, 0.62, [11, 5][lod])]
        m.merge(S.sweep(rib, [(-0.004, -0.07), (0.004, -0.07), (0.004, 0.07), (-0.004, 0.07)], "stone", up=(0, 0, -1)))
    return {"body": Part(m)}


def _paint_arms(P, N, tag, tags, state, col):
    """Azure field with a chief gules (the tinctures in colour, as the gilding is); the ribbon's motto."""
    w, h = ARMS["w"], ARMS["h"]
    y0 = 0.30
    field = (tag == tags.index("field")) & (N[:, 2] < -0.5)
    chief = P[:, 1] > y0 + h - 0.26
    azure, gules = np.array([0.16, 0.26, 0.55], np.float32), np.array([0.62, 0.12, 0.10], np.float32)
    col = np.where((field & chief)[:, None], gules, np.where(field[:, None], azure, col))
    rib = (tag == tags.index("stone")) & (np.abs(P[:, 2] + 0.144) < 0.004) & (P[:, 1] < y0 - 0.02)
    words = lettering.mask(P, ARMS["motto"], np.array([0, y0 - 0.13, -0.146], np.float32), 0.05, (-1, 0, 0), (0, 1, 0), weight=1.2)
    return np.where((rib & words)[:, None], col * 0.4, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "townhall_name": dict(build=townhall_name, materials=materials(), extra=_paint_name, extra_first=True, uv_scale={"stone": 2.0},
                          edge_radius=0.004, close=(1.4, 0.6, -0.1), **_SPEC),
    "town_arms": dict(build=town_arms, materials=materials(), extra=_paint_arms, extra_first=True, uv_scale={"field": 2.0},
                      edge_radius=0.004, close=(0.0, 0.8, -0.15), **_SPEC),
}
