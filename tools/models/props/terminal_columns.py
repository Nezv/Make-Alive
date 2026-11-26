"""The bus station's steel columns and trusses (S198). Cards and references:
references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

column_tree: a steel tree holding the canopy slab: a concrete pedestal with its chamfers, the base
plate and its bolts, a tube trunk up to a node of gusset plates, four arms splaying up and out to
the slab's underside, each ending in a bearing plate.
edge_truss: a 7.2 m bay of the Warren truss along the slab's edge: top and bottom chords of channel,
diagonals of angle, gusset plates and bolts at each node, the bearing on a column cap at each end.

Standing on y = 0; the slab's underside is at y = SLAB.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

TREE = dict(slab=6.50, node=4.20, spread=2.40, trunk=0.16, ped=0.90)
TRUSS = dict(len=7.20, depth=1.20, y0=5.30)


def materials():
    return {
        "steel": Material((0.36, 0.42, 0.46), under=(0.48, 0.30, 0.20), bare=(0.40, 0.28, 0.18), chip=0.5, grain=0.06, fixing=True),
        "concrete": Material((0.62, 0.61, 0.58), kind="concrete", chip=0.0, rusts=False, grain=0.18),
        "bolt": Material((0.30, 0.30, 0.30), under=(0.4, 0.3, 0.2), bare=(0.4, 0.3, 0.2), chip=0.3, grain=0.05),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


def _bolts(c, normal, n, spacing, lod):
    m = Mesh()
    if lod > 0:
        return m
    nrm = np.asarray(normal, np.float64)
    side = np.cross(nrm, (0, 1, 0)) if abs(nrm[1]) < 0.9 else np.array([1.0, 0, 0])
    side /= np.linalg.norm(side)
    up = np.cross(side, nrm)
    for i in range(n):
        for j in range(n):
            p = np.asarray(c) + side * (i - (n - 1) / 2) * spacing + up * (j - (n - 1) / 2) * spacing
            m.merge(S.prism(tuple(p + nrm * 0.008), 0.014, 0.016, 6, axis=tuple(nrm), tag="bolt"))
    return m


# --- column_tree --------------------------------------------------------------------------------------------
def column_tree(lod):
    sl, nd, sp, r, ph = TREE["slab"], TREE["node"], TREE["spread"], TREE["trunk"], TREE["ped"]
    m = Mesh()
    m.merge(_cb((0, ph / 2, 0), (0.40, ph / 2, 0.40), 0.04, "concrete", lod, edges="vertical"))
    m.merge(_cb((0, ph + 0.015, 0), (0.30, 0.015, 0.30), 0.004, "steel", lod))
    if lod == 0:
        for sx in (1, -1):
            for sz in (1, -1):
                m.merge(S.prism((sx * 0.22, ph + 0.04, sz * 0.22), 0.02, 0.03, 6, tag="bolt"))
    sides = [16, 10, 6][lod]
    m.merge(S.lathe([(ph + 0.03, r * 1.2), (ph + 0.25, r), (nd - 0.20, r), (nd, r * 1.25)], sides, tag="steel"))
    # the node: a cast ring, four gussets between the arms' roots
    m.merge(S.lathe([(nd - 0.05, r * 1.4), (nd + 0.25, r * 1.4)], sides, tag="steel"))
    for k in range(4):
        a = np.pi / 4 + k * np.pi / 2
        d = np.array([np.cos(a), 0, np.sin(a)])
        tip = d * sp + (0, sl - 0.05, 0)
        root = d * r + (0, nd + 0.15, 0)
        mid = d * (sp * 0.35) + (0, nd + 0.15 + (sl - nd) * 0.55, 0)
        arm = [tuple(root), tuple(mid), tuple(tip)]
        m.merge(S.sweep(arm, S.circle(r * 0.62, [12, 8, 5][lod]), "steel", scale=lambda i: [1.0, 0.85, 0.75][i]))
        # the bearing plate under the slab
        m.merge(_cb(tuple(tip + (0, 0.04, 0)), (0.18, 0.012, 0.18), 0.003, "steel", lod))
        m.merge(_bolts(tip + (0, 0.04 - 0.012, 0), (0, -1, 0), 2, 0.20, lod))
        if lod < 2:  # the gusset between this arm and the next, in the trunk's plane
            b = np.pi / 4 + (k + 0.5) * np.pi / 2
            e = np.array([np.cos(b), 0, np.sin(b)])
            g = S.extrude([(0.0, 0.0), (0.30, 0.0), (0.0, 0.55)], 0.012, 0.0, "steel", origin=tuple(e * r + (0, nd, 0) - np.cross(e, (0, 1, 0)) * 0.006),
                          right=tuple(e), up=(0, 1, 0))
            m.merge(g)
    return {"body": Part(m)}


# --- edge_truss -----------------------------------------------------------------------------------------------
def edge_truss(lod):
    L, D, y0 = TRUSS["len"], TRUSS["depth"], TRUSS["y0"]
    m = Mesh()
    ch = [(-0.10, -0.05), (0.10, -0.05), (0.10, 0.05), (-0.10, 0.05)]
    for y in (y0, y0 + D):  # the chords
        m.merge(S.sweep([(-L / 2, y, 0), (L / 2, y, 0)], ch, "steel", up=(0, 0, 1)))
    n = 6
    ang = [(0.0, 0.0), (0.08, 0.0), (0.08, 0.008), (0.008, 0.008), (0.008, 0.08), (0.0, 0.08)]
    for i in range(n):
        xa = -L / 2 + i * L / n
        xb = xa + L / n
        ya, yb = (y0 + 0.05, y0 + D - 0.05) if i % 2 == 0 else (y0 + D - 0.05, y0 + 0.05)
        m.merge(S.sweep([(xa, ya, 0), (xb, yb, 0)], [(-0.04, -0.04), (0.04, -0.04), (0.04, 0.04), (-0.04, 0.04)] if lod > 0 else
                        [(x - 0.04, y - 0.04) for x, y in ang], "steel", up=(0, 0, 1)))
    for i in range(n + 1):  # the nodes' gussets and bolts; the verticals at the ends
        x = -L / 2 + i * L / n
        y = y0 + (D if i % 2 else 0.0)
        if lod < 2:
            m.merge(S.box((x, y + (-0.12 if i % 2 else 0.12), 0), (0.16, 0.14, 0.006), "steel"))
            m.merge(_bolts((x, y + (-0.12 if i % 2 else 0.12), -0.006), (0, 0, -1), 2, 0.08, lod))
    for x in (-L / 2, L / 2):
        m.merge(S.box((x, y0 + D / 2, 0), (0.06, D / 2, 0.06), "steel"))
        m.merge(_cb((x, y0 - 0.15, 0), (0.15, 0.10, 0.15), 0.004, "steel", lod))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "column_tree": dict(build=column_tree, materials=materials(), edge_radius=0.004, close=(0.0, 4.3, -0.3), **_SPEC),
    "edge_truss": dict(build=edge_truss, materials=materials(), edge_radius=0.003, close=(0.0, 5.9, -0.2), **_SPEC),
}
