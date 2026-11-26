"""Carried things (S153): what the inventory holds, seen in the hands, on the wheel and on the floor.
Cards and references: references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

medkit: a red first-aid bag (0.30 x 0.19 x 0.15): rounded, zipped all round, a white cross patch on
its front and top, a carry handle, a strap ring at each end.
bandage: a roll of gauze lying on its side, its loose end unrolled on the floor.
pills: an orange pill bottle with its white ridged cap and a paper label.
planks: three rough planks for barricading, crossed a little, nails in them, a split end.
backpack: a hiking pack (0.34 x 0.58 x 0.24): the body, its top lid with a buckle strap, a front
pocket, side pockets with a bottle in one, shoulder straps and hip belt on the back (+Z), a grab
loop. The dropped `Backpack` (scripts/world/backpack.gd) stands it up.

Standing on y = 0, the front -Z, metres.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

MED = dict(w=0.30, h=0.19, d=0.15)
ROLL = dict(r=0.038, w=0.10, core=0.012)
BOTTLE = dict(r=0.026, h=0.085, cap=0.022)
PLANK = dict(l=1.20, w=0.15, t=0.025)
PACK = dict(w=0.34, h=0.58, d=0.24)


def materials():
    fab = dict(kind="rubber", chip=0.0, rusts=False, fades=True)
    return {
        "red": Material((0.62, 0.08, 0.07), grain=0.10, **fab),
        "white": Material((0.90, 0.90, 0.88), grain=0.05, **fab),
        "zip": Material((0.10, 0.10, 0.10), grain=0.05, **fab),
        "strap": Material((0.12, 0.12, 0.13), grain=0.08, **fab),
        "gauze": Material((0.92, 0.91, 0.86), kind="paper", chip=0.0, rusts=False, grain=0.18),
        "orange": Material((0.80, 0.42, 0.08), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "cap": Material((0.93, 0.93, 0.91), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "label": Material((0.95, 0.94, 0.90), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "pill": Material((0.85, 0.82, 0.55), kind="clay", chip=0.0, rusts=False, grain=0.05),
        "plank": Material((0.58, 0.46, 0.32), under=(0.50, 0.40, 0.28), bare=(0.62, 0.52, 0.38), kind="wood", chip=0.0, rusts=False, grain=0.22,
                          palette=[(0.58, 0.46, 0.32), (0.52, 0.42, 0.30), (0.62, 0.50, 0.36)], vary=0.05),
        "break": Material((0.70, 0.58, 0.42), kind="wood", chip=0.0, rusts=False, grain=0.3),
        "nail": Material((0.40, 0.40, 0.40), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
        "pack": Material((0.18, 0.30, 0.38), grain=0.10, **fab),
        "pack2": Material((0.10, 0.12, 0.14), grain=0.08, **fab),
        "buckle": Material((0.08, 0.08, 0.08), kind="rubber", chip=0.0, rusts=False, grain=0.03),
        "metal": Material((0.55, 0.56, 0.57), under=(0.4, 0.4, 0.4), bare=(0.4, 0.4, 0.4), chip=0.2, rusts=False, grain=0.04),
    }


# --- medkit --------------------------------------------------------------------------------------------
def medkit(lod):
    w, h, d = MED["w"], MED["h"], MED["d"]
    m = Mesh()
    r = 0.03 if lod == 0 else 0.02
    m.merge(S.bevel_box((0, h / 2, 0), (w / 2, h / 2, d / 2), r, "red") if lod < 2 else S.box((0, h / 2, 0), (w / 2, h / 2, d / 2), "red"))
    if lod < 2:
        # the zip round the top's edge: a dark band and its pull
        m.merge(S.box((0, h - 0.035, 0), (w / 2 + 0.002, 0.006, d / 2 + 0.002), "zip"))
        m.merge(S.box((w * 0.3, h - 0.045, -d / 2 - 0.006), (0.008, 0.016, 0.003), "metal"))
        # the cross patches, front and top
        for hx, hy in ((0.045, 0.014), (0.014, 0.045)):
            m.merge(S.box((0, h * 0.45, -d / 2 - 0.002), (hx, hy, 0.002), "white"))
            m.merge(S.box((0, h + 0.002, 0), (hx, 0.002, hy * d / 0.15 * 0.8 if hy > hx else hy), "white"))
        # the handle: two tabs and the grip across
        m.merge(S.sweep([(-0.06, h, 0), (-0.05, h + 0.035, 0), (0.05, h + 0.035, 0), (0.06, h, 0)], [(-0.012, -0.004), (0.012, -0.004), (0.012, 0.004), (-0.012, 0.004)],
                        "strap", up=(0, 0, 1)))
    if lod == 0:
        for sx in (1, -1):  # the strap rings at the ends
            ring = [(sx * (w / 2 + 0.01), h * 0.75 + np.sin(a) * 0.012, np.cos(a) * 0.012) for a in np.linspace(0, 2 * np.pi, 7)[:-1]]
            m.merge(S.sweep(ring, S.circle(0.003, 4), "metal", closed=True, up=(1, 0, 0)))
            m.merge(S.box((sx * (w / 2 + 0.002), h * 0.75, 0), (0.004, 0.012, 0.015), "strap"))
    return {"body": Part(m)}


# --- bandage --------------------------------------------------------------------------------------------
def bandage(lod):
    r, w, core = ROLL["r"], ROLL["w"], ROLL["core"]
    m = Mesh()
    sides = [16, 10, 6][lod]
    roll = S.lathe([(-w / 2, core), (-w / 2, r * 0.96), (-w / 2 + 0.004, r), (w / 2 - 0.004, r), (w / 2, r * 0.96), (w / 2, core)], sides, tag="gauze", caps=(False, False))
    m.merge(S.along(roll, (1, 0, 0), (0, r, 0)))
    if lod < 2:  # the core's hole, the loose end peeling off the bottom and lying out flat
        m.merge(S.along(S.lathe([(-w / 2 + 0.001, core), (w / 2 - 0.001, core)], 8, tag="label", caps=(False, False)), (1, 0, 0), (0, r, 0)))
        n = [8, 4][lod]
        pts = [(0, r - np.cos(a) * r * 1.01, -np.sin(a) * r * 1.01) for a in np.linspace(0.0, 0.9, 3)] + [(0, 0.002, -r - 0.03 - k * 0.12 / n) for k in range(n)]
        m.merge(S.sweep(pts, [(-w / 2 + 0.003, -0.0012), (w / 2 - 0.003, -0.0012), (w / 2 - 0.003, 0.0012), (-w / 2 + 0.003, 0.0012)], "gauze", up=(1, 0, 0)))
    return {"body": Part(m)}


def _paint_bandage(P, N, tag, tags, state, col):
    """The gauze's weave: a faint grid of threads."""
    sel = tag == tags.index("gauze")
    g = (np.mod(P[:, 0] * 260, 1.0) < 0.22) | (np.mod((P[:, 1] + P[:, 2]) * 260, 1.0) < 0.22)
    return np.where((sel & g)[:, None], col * 0.90, col)


# --- pills -----------------------------------------------------------------------------------------------
def pills(lod):
    r, h, ch = BOTTLE["r"], BOTTLE["h"], BOTTLE["cap"]
    sides = [16, 10, 6][lod]
    m = S.lathe([(0.0, 0.0), (0.0, r - 0.003), (0.003, r), (h - 0.006, r), (h - 0.004, r - 0.003)], sides, tag="orange", caps=(False, False))
    # the white ridged cap, a lip over the shoulder
    ridges = (lambda j, y: 1.0 + (0.04 if j % 2 else 0.0)) if lod == 0 else None
    m.merge(S.lathe([(h - 0.010, r + 0.002), (h - 0.010, r + 0.004), (h + ch - 0.003, r + 0.004), (h + ch, r - 0.002), (h + ch, 0.0)],
                    sides * (2 if lod == 0 else 1), flute=ridges, tag="cap"))
    if lod < 2:  # the label round the bottle
        m.merge(S.lathe([(0.015, r + 0.0006), (h - 0.018, r + 0.0006)], sides, tag="label", caps=(False, False)))
    if lod == 0:  # a few pills spilt beside it
        for i, (x, z) in enumerate(((0.05, -0.01), (0.062, 0.012), (0.045, 0.02))):
            m.merge(S.lathe([(0.0, 0.0), (0.0, 0.0055), (0.0035, 0.0055), (0.0045, 0.0)], 8, tag="pill").transformed(np.eye(3), (x, 0, z)).set_unit(i + 1))
    return {"body": Part(m)}


def _paint_pills(P, N, tag, tags, state, col):
    r, h = BOTTLE["r"], BOTTLE["h"]
    sel = tag == tags.index("label")
    a = np.arctan2(P[:, 2], P[:, 0])
    face = sel & (np.cos(a + np.pi / 2) > 0.2)  # the label's printed side towards -Z
    rows = face & (np.mod(P[:, 1] * 220, 1.0) < 0.35) & (P[:, 1] < h * 0.55)
    col = np.where(rows[:, None], np.array([0.30, 0.30, 0.32], np.float32), col)
    band = sel & (P[:, 1] > h * 0.62)
    return np.where(band[:, None], np.array([0.75, 0.15, 0.12], np.float32), col)


# --- planks ------------------------------------------------------------------------------------------------
def planks(lod):
    L, w, t = PLANK["l"], PLANK["w"], PLANK["t"]
    m = Mesh()
    if lod == 2:  # far: the stack as one block
        return {"body": Part(S.box((0, 1.5 * t, 0), (L / 2, 1.5 * t, w / 2 + 0.02), "plank"))}
    lay = [(0.0, 0.0, 0.0), (0.02, t, 0.05), (-0.03, 2 * t, -0.04)]
    for i, (dx, y, a) in enumerate(lay):
        p = S.chamfer_box((0, t / 2, 0), (L / 2 - i * 0.04, t / 2, w / 2 - (0.01 if i == 1 else 0)), 0.003, "plank", edges="top") if lod == 0 else \
            S.box((0, t / 2, 0), (L / 2 - i * 0.04, t / 2, w / 2), "plank")
        if lod == 0 and i == 2:  # a split end, broken off rough
            p = S.clip(p, (L / 2 - 0.12, 0, 0.02), (1, 0, 0.35), "break", rough=0.006, seed=4)
        m.merge(p.transformed(S.rotation((0, 1, 0), a), (dx, y, 0)).set_unit(i + 1))
        if lod == 0:  # nails left in from the last barricade, and their holes
            R = S.rotation((0, 1, 0), a)
            for k, x in enumerate((-L / 2 + 0.06, L / 2 - 0.10)):
                c = R @ np.array([x, 0, (k - 0.5) * 0.06]) + np.array([dx, y + t, 0])
                m.merge(S.prism(c, 0.0045, 0.002, 6, tag="nail"))
                if k == 0 and i == 1:
                    m.merge(S.prism(c + np.array([0, 0.002, 0]), 0.0015, 0.04, 4, tag="nail"))  # one standing proud, bent over later
    return {"body": Part(m)}


# --- backpack ----------------------------------------------------------------------------------------------
def backpack(lod):
    w, h, d = PACK["w"], PACK["h"], PACK["d"]
    m = Mesh()
    # the body: wider at the foot, rounded
    body = S.bevel_box((0, h * 0.45, 0), (w / 2, h * 0.45, d / 2), 0.04, "pack") if lod < 2 else S.box((0, h * 0.45, 0), (w / 2, h * 0.45, d / 2), "pack")
    body.verts = [np.array([v[0] * (1.06 - 0.12 * v[1] / h), v[1], v[2] * (1.04 - 0.10 * v[1] / h)]) for v in body.verts]
    m.merge(body)
    # the top lid hanging over the body
    lid = S.bevel_box((0, h * 0.93, 0.01), (w / 2 - 0.01, h * 0.06, d / 2 + 0.01), 0.03, "pack2") if lod < 2 else S.box((0, h * 0.93, 0.01), (w / 2 - 0.01, h * 0.06, d / 2 + 0.01), "pack2")
    m.merge(lid)
    if lod < 2:
        # the front pocket and its zip, the lid's strap and buckle down the front
        m.merge(S.bevel_box((0, h * 0.30, -d / 2 - 0.02), (w / 2 - 0.05, h * 0.18, 0.03), 0.02, "pack2") if lod == 0 else
                S.box((0, h * 0.30, -d / 2 - 0.02), (w / 2 - 0.05, h * 0.18, 0.03), "pack2"))
        m.merge(S.sweep([(0, h * 0.96, -d / 2 - 0.012), (0, h * 0.86, -d / 2 - 0.006), (0, h * 0.60, -d / 2 - 0.004)],
                        [(-0.012, -0.002), (0.012, -0.002), (0.012, 0.002), (-0.012, 0.002)], "strap", up=(0, 0, -1)))
        m.merge(S.box((0, h * 0.70, -d / 2 - 0.008), (0.018, 0.022, 0.006), "buckle"))
        # the side pockets, a bottle in the left one
        for sx in (1, -1):
            m.merge(S.box((sx * (w / 2 + 0.02), h * 0.18, 0), (0.025, h * 0.13, d / 2 - 0.04), "pack2"))
        m.merge(S.lathe([(h * 0.10, 0.032), (h * 0.42, 0.032), (h * 0.46, 0.018), (h * 0.50, 0.018), (h * 0.50, 0.0)], [10, 6][lod], tag="metal")
                .transformed(np.eye(3), (-w / 2 - 0.035, 0, 0)))
        # the back: shoulder straps from the lid's foot to the hip belt, the belt with its buckle
        for sx in (1, -1):
            pts = [(sx * 0.06, h * 0.86, d / 2), (sx * 0.08, h * 0.80, d / 2 + 0.05), (sx * 0.10, h * 0.50, d / 2 + 0.06), (sx * 0.12, h * 0.22, d / 2 + 0.03)]
            m.merge(S.sweep(pts, [(-0.03, -0.012), (0.03, -0.012), (0.03, 0.012), (-0.03, 0.012)], "strap", up=(0, 0, 1)))
        belt = [(-w / 2 - 0.08, h * 0.12, d / 2 - 0.04), (-w / 2 + 0.02, h * 0.13, d / 2 + 0.03), (w / 2 - 0.02, h * 0.13, d / 2 + 0.03), (w / 2 + 0.08, h * 0.12, d / 2 - 0.04)]
        m.merge(S.sweep(belt, [(-0.003, -0.04), (0.012, -0.04), (0.012, 0.04), (-0.003, 0.04)], "strap"))
    if lod == 0:
        m.merge(S.sweep([(-0.03, h * 0.98, d / 2), (0, h + 0.02, d / 2 + 0.01), (0.03, h * 0.98, d / 2)], S.circle(0.006, 4), "strap"))  # the grab loop
        for sx in (1, -1):  # the compression straps' buckles on the sides
            m.merge(S.box((sx * (w / 2 + 0.004), h * 0.55, -0.03), (0.004, 0.015, 0.02), "buckle"))
        m.merge(S.box((0, h * 0.465, -d / 2 - 0.051), (w / 2 - 0.07, 0.004, 0.002), "zip"))
    return {"body": Part(m)}


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "medkit": dict(build=medkit, materials=materials(), edge_radius=0.003, close=(0.0, 0.1, -MED["d"] / 2), **_SPEC),
    "bandage": dict(build=bandage, materials=materials(), extra=_paint_bandage, edge_radius=0.001, close=(0.0, 0.04, -0.05), **_SPEC),
    "pills": dict(build=pills, materials=materials(), extra=_paint_pills, edge_radius=0.001, close=(0.0, 0.05, -0.03), **_SPEC),
    "planks": dict(build=planks, materials=materials(), edge_radius=0.002, close=(0.5, 0.05, 0.0), **_SPEC),
    "backpack": dict(build=backpack, materials=materials(), edge_radius=0.004, close=(0.0, 0.35, -PACK["d"] / 2), **_SPEC),
}
