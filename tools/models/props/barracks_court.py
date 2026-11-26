"""The barracks' cour d'honneur (S222). Cards and references: references/elements/<name>.md; the
workflow: references/elements/WORKFLOW.md.

war_memorial: the regiment's memorial on the court's lawn: three steps, a die with the names cut on
its faces (invented), a cornice, a column with its base and a capital carrying a bronze helmet on a
wreath; four bollards round it hung with chains, a bronze wreath leaning on the die.
flagpoles: three white flagpoles on their stone bases in a row, each with its truck, halyard and
cleat; the middle one taller, its flag hanging limp.

Standing on y = 0, the memorial's front -Z.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

NAMES = ["BERTIN A.", "CHAUVET L.", "DUMONT P.", "FAURE J.", "GARNIER E.", "LEBRUN M.", "MARCHAND R.", "PERRIN G.", "ROUSSEL H.", "VIDAL C."]   # invented


def materials():
    return {
        "stone": Material((0.74, 0.71, 0.64), kind="stone", chip=0.0, rusts=False, grain=0.14),
        "bronze": Material((0.30, 0.38, 0.30), under=(0.4, 0.32, 0.2), bare=(0.55, 0.45, 0.28), chip=0.0, rusts=False, grain=0.06, fades=False),
        "iron": Material((0.10, 0.10, 0.11), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.06),
        "white": Material((0.88, 0.88, 0.86), under=(0.6, 0.6, 0.6), bare=(0.5, 0.5, 0.5), chip=0.3, grain=0.04),
        "flag": Material((0.20, 0.25, 0.55), kind="paper", chip=0.0, rusts=False, grain=0.06),
        "rope": Material((0.80, 0.78, 0.72), kind="paper", chip=0.0, rusts=False, grain=0.06),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- war_memorial ---------------------------------------------------------------------------------------------
def war_memorial(lod):
    m = Mesh()
    y = 0.0
    for hw, hh in ((1.40, 0.15), (1.15, 0.15), (0.90, 0.15)):
        m.merge(_cb((0, y + hh / 2, 0), (hw, hh / 2, hw), 0.01, "stone", lod, edges="top"))
        y += hh
    m.merge(_cb((0, y + 0.08, 0), (0.70, 0.08, 0.70), 0.015, "stone", lod))                 # the die's base
    m.merge(S.box((0, y + 0.16 + 0.75, 0), (0.62, 0.75, 0.62), "stone"))                      # the die
    yd = y + 0.16 + 1.50
    m.merge(_cb((0, yd + 0.06, 0), (0.72, 0.06, 0.72), 0.015, "stone", lod))
    m.merge(_cb((0, yd + 0.16, 0), (0.66, 0.05, 0.66), 0.01, "stone", lod))
    # the column: base, shaft with its entasis, capital, then the helmet on its wreath
    n = [16, 10, 6][lod]
    yb = yd + 0.21
    m.merge(S.lathe([(yb, 0.36), (yb + 0.10, 0.36), (yb + 0.14, 0.30), (yb + 0.20, 0.28), (yb + 2.60, 0.24), (yb + 2.66, 0.27), (yb + 2.76, 0.33),
                     (yb + 2.82, 0.36), (yb + 2.82, 0.0)], n, tag="stone",
                    flute=(lambda j, yy: 1.0 - 0.04 * (j % 2) * (yb + 0.25 < yy < yb + 2.55)) if lod == 0 else None))
    yt = yb + 2.82
    m.merge(S.lathe([(yt, 0.0), (yt, 0.30), (yt + 0.08, 0.30), (yt + 0.08, 0.0)], n, tag="bronze"))       # the wreath's ring
    m.merge(S.lathe([(yt + 0.08, 0.20), (yt + 0.20, 0.22), (yt + 0.32, 0.18), (yt + 0.40, 0.08), (yt + 0.42, 0.0)], n, tag="bronze"))   # the helmet's bowl
    if lod < 2:
        m.merge(S.lathe([(yt + 0.08, 0.26), (yt + 0.10, 0.26), (yt + 0.10, 0.0)], n, tag="bronze"))        # its brim
        m.merge(S.box((0, yt + 0.38, 0), (0.015, 0.06, 0.16), "bronze"))                              # its crest
        # the bronze wreath leaning on the die's front
        ring = [(np.cos(a) * 0.30, y + 0.55 + np.sin(a) * 0.30, -0.66) for a in np.linspace(0, 2 * np.pi, [16, 8][lod] + 1)[:-1]]
        m.merge(S.sweep(ring, S.circle(0.05, [6, 4][lod]), "bronze", closed=True, up=(0, 0, -1)))
        # the bollards and chains round it
        for k in range(4):
            a = np.pi / 4 + k * np.pi / 2
            p = np.array([np.cos(a), 0, np.sin(a)]) * 2.40
            m.merge(S.lathe([(0.0, 0.10), (0.55, 0.08), (0.60, 0.10), (0.68, 0.0)], [8, 6][lod], tag="iron").transformed(np.eye(3), tuple(p)))
            q = np.array([np.cos(a + np.pi / 2), 0, np.sin(a + np.pi / 2)]) * 2.40
            m.merge(S.cable(tuple(p + (0, 0.50, 0)), tuple(q + (0, 0.50, 0)), 0.25, r=0.012, n=[8, 4][lod], sides=4, tag="iron"))
    return {"body": Part(m)}


def _paint_memorial(P, N, tag, tags, state, col):
    """AUX MORTS and the dates on the front, the names on the sides (invented), cut dark."""
    y = 0.45 + 0.16
    sel = tag == tags.index("stone")
    words = np.zeros(len(P), bool)
    for k in range(4):
        a = k * np.pi / 2
        out = np.array([np.sin(a), 0.0, -np.cos(a)])          # front (-Z), then +X, +Z, -X
        right = np.array([-np.cos(a), 0.0, -np.sin(a)])
        face = (np.abs(P @ out - 0.62) < 0.004) & ((N @ out) > 0.8)
        c0 = out * 0.621
        if k == 0:
            w = lettering.mask(P, "AUX MORTS", (c0 + (0, y + 1.20, 0)).astype(np.float32), 0.10, right, (0, 1, 0), weight=1.4)
            w |= lettering.mask(P, "DU RÉGIMENT", (c0 + (0, y + 1.02, 0)).astype(np.float32), 0.07, right, (0, 1, 0), weight=1.2)
            w |= lettering.mask(P, "1914 - 1918", (c0 + (0, y + 0.82, 0)).astype(np.float32), 0.08, right, (0, 1, 0), weight=1.2)
        else:
            w = np.zeros(len(P), bool)
            for i in range(5):
                name = NAMES[(k * 3 + i) % len(NAMES)]
                w |= lettering.mask(P, name, (c0 + (0, y + 1.25 - i * 0.16, 0)).astype(np.float32), 0.06, right, (0, 1, 0), weight=1.1)
        words |= w & face
    return np.where((sel & words)[:, None], col * 0.35, col)


# --- flagpoles ----------------------------------------------------------------------------------------------------
def flagpoles(lod):
    m = Mesh()
    n = [10, 6, 4][lod]
    for x, H in ((-3.0, 8.0), (0.0, 10.0), (3.0, 8.0)):
        m.merge(_cb((x, 0.20, 0), (0.35, 0.20, 0.35), 0.02, "stone", lod, edges="top"))
        m.merge(S.lathe([(0.40, 0.07), (H, 0.035), (H + 0.02, 0.06), (H + 0.10, 0.06), (H + 0.12, 0.0)], n, tag="white").transformed(np.eye(3), (x, 0, 0)))
        if lod < 2:
            m.merge(S.cable((x + 0.05, H + 0.05, -0.04), (x + 0.05, 1.2, -0.04), 0.03, r=0.004, n=[6, 2][lod], sides=3, tag="rope"))
            m.merge(S.box((x, 1.2, -0.06), (0.012, 0.06, 0.02), "iron"))
        if x == 0.0:  # the flag hanging limp from the middle pole, its folds
            fw, fh = 1.50, 1.00
            rings = []
            for i in range([8, 4, 2][lod] + 1):
                t = i / [8, 4, 2][lod]
                yy = H - 0.10 - t * fh
                ring = []
                for j in range(6):
                    u = j / 5
                    xx = x + 0.05 + u * fw * (0.35 + 0.15 * t)
                    zz = 0.08 * np.sin(u * 7 + t * 2) * u
                    yyy = yy - u * u * 0.25 * (1 - t * 0.5)
                    ring.append((xx, yyy, zz))
                rings.append(ring)
            fl = Mesh()
            for i in range(len(rings) - 1):
                a = fl.add(rings[i] + rings[i + 1])
                k = len(rings[i])
                for j in range(k - 1):
                    fl.face([a + j, a + j + 1, a + k + j + 1, a + k + j], "flag")
                    fl.face([a + j, a + k + j, a + k + j + 1, a + j + 1], "flag")
            m.merge(fl)
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "war_memorial": dict(build=war_memorial, materials=materials(), extra=_paint_memorial, extra_first=True, uv_scale={"stone": 2.0},
                         edge_radius=0.006, close=(0.0, 1.5, -0.7), **_SPEC),
    "flagpoles": dict(build=flagpoles, materials=materials(), edge_radius=0.003, close=(0.0, 1.0, 0.0), **_SPEC),
}
