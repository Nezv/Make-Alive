"""Containers (S152): what the loot is found in. Cards and references: references/elements/<name>.md;
the workflow: references/elements/WORKFLOW.md. Today `lootbox.gd`, `ammo_crate.gd` and `ammo_box.gd`
draw boxes; these are their looks (the same sizes, so the nodes and their click bodies stay).

lootbox: a steel supply chest (0.90 x 0.50 x 0.60): pressed ribs round the body, corner guards,
folding handles at the ends, two over-centre clasps on the front, the lid (part `lid`) with a raised
panel, hinged along the back.
ammo_crate: the long wooden military crate (1.10 x 0.36 x 0.50): boards, end cleats, rope
handles, steel corners, two hasps, the stencils; the rounds in their packets inside; the lid (part
`lid`) of boards on battens, hinged along the back.
ammo_carton: a carton of rounds (0.22 x 0.11 x 0.14): flaps, tape, the calibre's band (white
here: the band's colour per calibre is the game's, `Weapons.AMMO`), the printed words.

Standing on y = 0, the front -Z, hinges along the back (+Z).
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

LOOT = dict(w=0.90, h=0.50, d=0.60, lid=0.08)
CRATE = dict(w=1.10, h=0.36, d=0.50, lid=0.06, board=0.022)
CARTON = dict(w=0.22, h=0.11, d=0.14)


def materials():
    return {
        "olive": Material((0.24, 0.30, 0.20), under=(0.42, 0.40, 0.34), bare=(0.36, 0.34, 0.32), chip=0.9, grain=0.06),
        "steel": Material((0.30, 0.31, 0.30), under=(0.30, 0.20, 0.14), bare=(0.35, 0.33, 0.31), chip=0.5, grain=0.06),
        "wood": Material((0.30, 0.33, 0.20), under=(0.48, 0.40, 0.28), bare=(0.55, 0.45, 0.30), kind="wood", chip=0.8, grain=0.12,
                         palette=[(0.30, 0.33, 0.20), (0.28, 0.31, 0.19), (0.31, 0.34, 0.21)], vary=0.04),
        "rope": Material((0.55, 0.47, 0.32), kind="paper", chip=0.0, rusts=False, grain=0.2),
        "brass": Material((0.70, 0.56, 0.26), under=(0.5, 0.4, 0.2), bare=(0.5, 0.4, 0.2), chip=0.0, rusts=False, grain=0.04, fades=False),
        "card": Material((0.62, 0.52, 0.38), kind="paper", chip=0.0, rusts=False, grain=0.12),
        "stripe": Material((0.90, 0.90, 0.86), kind="paper", chip=0.0, rusts=False, grain=0.06),
        "tape": Material((0.70, 0.60, 0.42), kind="paper", chip=0.0, rusts=False, grain=0.04),
        "dark": Material((0.06, 0.06, 0.06), chip=0.0, rusts=False, grain=0.02, fades=False),
        "bolt": Material((0.35, 0.35, 0.35), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


# --- lootbox -------------------------------------------------------------------------------------------
def _clasp(x, y, z, lod):
    m = Mesh()
    m.merge(S.box((x, y, z - 0.006), (0.035, 0.045, 0.006), "steel"))            # the plate on the body
    if lod < 2:
        m.merge(S.chamfer_box((x, y + 0.035, z - 0.016), (0.025, 0.035, 0.008), 0.004 if lod == 0 else 0.0, "steel", edges="front") if lod == 0 else
                S.box((x, y + 0.035, z - 0.016), (0.025, 0.035, 0.008), "steel"))  # the lever up over the lid's keeper
    return m


def lootbox(lod):
    w, h, d, lh = LOOT["w"], LOOT["h"], LOOT["d"], LOOT["lid"]
    hb = h - lh
    m = Mesh()
    c = 0.015 if lod == 0 else 0.0
    m.merge(S.chamfer_box((0, hb / 2, 0), (w / 2, hb / 2, d / 2), c, "olive", edges="vertical") if c else S.box((0, hb / 2, 0), (w / 2, hb / 2, d / 2), "olive"))
    if lod < 2:
        for y in (0.10, hb - 0.10):  # the pressed ribs round the body
            m.merge(S.box((0, y, 0), (w / 2 + 0.006, 0.012, d / 2 + 0.006), "olive"))
        for sx in (1, -1):
            for sz in (1, -1):  # the corner guards, top and bottom
                for y in (0.03, hb - 0.03):
                    m.merge(S.box((sx * (w / 2 - 0.02), y, sz * (d / 2 - 0.02)), (0.03, 0.035, 0.03), "steel"))
        for sx in (1, -1):  # the folding handles on the ends
            m.merge(S.box((sx * (w / 2 + 0.008), hb * 0.62, 0), (0.008, 0.02, 0.09), "steel"))
            m.merge(S.sweep([(sx * (w / 2 + 0.012), hb * 0.62, -0.07), (sx * (w / 2 + 0.03), hb * 0.52, -0.07), (sx * (w / 2 + 0.03), hb * 0.52, 0.07),
                             (sx * (w / 2 + 0.012), hb * 0.62, 0.07)], S.circle(0.007, [6, 4][lod]), "steel"))
        for x in (-w / 3, w / 3):
            m.merge(_clasp(x, hb - 0.06, -d / 2, lod))
    if lod == 0:  # the hinges' knuckles along the back
        for x in (-w / 3, w / 3):
            m.merge(S.lathe([(-0.05, 0.012), (0.05, 0.012)], 6, tag="steel").transformed(S.rotation((0, 0, 1), np.pi / 2), (x, hb, d / 2 + 0.008)))
        m.merge(S.box((0, hb - 0.004, 0), (w / 2 - 0.03, 0.004, d / 2 - 0.03), "dark"))  # the inside's shadow under the lid
    lid = Mesh()
    lid.merge(S.chamfer_box((0, hb + lh / 2, 0), (w / 2 + 0.008, lh / 2, d / 2 + 0.008), c, "olive", edges="top") if c else
              S.box((0, hb + lh / 2, 0), (w / 2 + 0.008, lh / 2, d / 2 + 0.008), "olive"))
    if lod < 2:
        lid.merge(S.chamfer_box((0, h + 0.008, 0), (w / 2 - 0.08, 0.008, d / 2 - 0.08), 0.006 if lod == 0 else 0.0, "olive", edges="top") if lod == 0 else
                  S.box((0, h + 0.008, 0), (w / 2 - 0.08, 0.008, d / 2 - 0.08), "olive"))
        for x in (-w / 3, w / 3):  # the keepers the clasps catch
            lid.merge(S.box((x, hb + 0.02, -d / 2 - 0.014), (0.02, 0.012, 0.006), "steel"))
    hinge = (0.0, hb, d / 2)
    return {"body": Part(m), "lid": Part(lid, hinge, {"rotate": [[1, 0, 0], 110.0]})}


def _paint_loot(P, N, tag, tags, state, col):
    """The stencils: a cross and the words on the front, a number on the lid."""
    w, h, d = LOOT["w"], LOOT["h"], LOOT["d"]
    white = np.array([0.82, 0.82, 0.76], np.float32)
    front = (tag == tags.index("olive")) & (N[:, 2] < -0.5)
    sten = lettering.mask(P, "SECOURS", np.array([0, 0.20, -d / 2], np.float32), 0.06, (-1, 0, 0), (0, 1, 0), font="stencil", weight=1.2)
    col = np.where((front & sten)[:, None], white, col)
    top = (tag == tags.index("olive")) & (N[:, 1] > 0.5) & (P[:, 1] > h - 0.002)
    num = lettering.mask(P, "07", np.array([0, h + 0.016, 0], np.float32), 0.12, (1, 0, 0), (0, 0, -1), font="stencil", weight=1.3)
    return np.where((top & num)[:, None], white, col)


# --- ammo_crate ----------------------------------------------------------------------------------------
def ammo_crate(lod):
    w, h, d, lh, bt = CRATE["w"], CRATE["h"], CRATE["d"], CRATE["lid"], CRATE["board"]
    m = Mesh()
    unit = 1
    # the boards: three a side, laid long; the ends' boards upright
    n = 3 if lod < 2 else 1
    for sz in (1, -1):
        for k in range(n):
            y0 = k * h / n
            b = S.box((0, y0 + h / n / 2, sz * (d / 2 - bt / 2)), (w / 2 - bt, h / n / 2 - (0.002 if lod == 0 else 0), bt / 2), "wood")
            m.merge(b.set_unit(unit))
            unit += 1
    m.merge(S.box((0, bt / 2, 0), (w / 2 - bt, bt / 2, d / 2 - bt), "wood").set_unit(unit))
    for sx in (1, -1):
        m.merge(S.box((sx * (w / 2 - bt / 2), h / 2, 0), (bt / 2, h / 2, d / 2), "wood").set_unit(unit + 1))
        # the end cleats: battens round each end, standing proud
        m.merge(S.chamfer_box((sx * (w / 2 - 0.04), h / 2, 0), (0.04, h / 2 + 0.005, d / 2 + 0.012), 0.005 if lod == 0 else 0.0, "wood", edges="vertical") if lod == 0 else
                S.box((sx * (w / 2 - 0.04), h / 2, 0), (0.04, h / 2 + 0.005, d / 2 + 0.012), "wood"))
        if lod < 2:  # the rope handle through the end, its knots
            pts = [(sx * (w / 2 + 0.005), h * 0.62, -0.09), (sx * (w / 2 + 0.05), h * 0.48, -0.06), (sx * (w / 2 + 0.06), h * 0.45, 0.0),
                   (sx * (w / 2 + 0.05), h * 0.48, 0.06), (sx * (w / 2 + 0.005), h * 0.62, 0.09)]
            m.merge(S.sweep(pts, S.circle(0.011, [6, 4][lod]), "rope"))
            if lod == 0:
                for z in (-0.09, 0.09):
                    m.merge(S.prism((sx * (w / 2 + 0.004), h * 0.62, z), 0.02, 0.012, 6, axis=(sx, 0, 0), tag="rope"))
        if lod == 0:  # the steel corners
            for sz in (1, -1):
                for y in (0.025, h - 0.025):
                    m.merge(S.box((sx * (w / 2 + 0.004), y, sz * (d / 2 + 0.004)), (0.03, 0.03, 0.03), "steel"))
    # the hasps on the front, and inside the rounds' packets seen when the lid is up
    if lod < 2:
        for x in (-w / 4, w / 4):
            m.merge(S.box((x, h - 0.05, -d / 2 - 0.014), (0.025, 0.05, 0.004), "steel"))
    if lod == 0:
        for i in range(6):
            m.merge(S.box((-0.30 + i * 0.12, h - 0.03, 0), (0.05, 0.015, 0.17), "card").set_unit(20 + i))
            for j in range(4):
                m.merge(S.prism((-0.32 + i * 0.12 + j * 0.013, h - 0.015, -0.12), 0.005, 0.012, 5, tag="brass"))
        m.merge(S.box((0, h - 0.06, 0), (w / 2 - bt - 0.005, 0.002, d / 2 - bt - 0.005), "dark"))
    lid = Mesh()
    nb = 4 if lod < 2 else 1
    for k in range(nb):
        z0 = -d / 2 - 0.01 + k * (d + 0.02) / nb
        lb = S.box((0, h + bt / 2 + 0.002, z0 + (d + 0.02) / nb / 2), (w / 2 + 0.01, bt / 2, (d + 0.02) / nb / 2 - (0.002 if lod == 0 else 0)), "wood")
        lid.merge(lb.set_unit(30 + k))
    if lod < 2:
        for x in (-w / 2 + 0.06, w / 2 - 0.06):  # the battens across the boards
            lid.merge(S.box((x, h + bt + 0.012, 0), (0.035, 0.012, d / 2 + 0.01), "wood"))
        for x in (-w / 4, w / 4):  # the hasps' staples
            lid.merge(S.box((x, h + 0.005, -d / 2 - 0.016), (0.012, 0.012, 0.006), "steel"))
    hinge = (0.0, h + 0.002, d / 2 + 0.01)
    return {"body": Part(m), "lid": Part(lid, hinge, {"rotate": [[1, 0, 0], 105.0]})}


def _paint_crate(P, N, tag, tags, state, col):
    w, h, d = CRATE["w"], CRATE["h"], CRATE["d"]
    yel = np.array([0.80, 0.72, 0.36], np.float32)
    front = (tag == tags.index("wood")) & (N[:, 2] < -0.5)
    words = lettering.mask(P, "CARTOUCHES", np.array([0.10, h * 0.62, -d / 2], np.float32), 0.05, (-1, 0, 0), (0, 1, 0), font="stencil", weight=1.2)
    words |= lettering.mask(P, "LOT 14-07  1200", np.array([0.10, h * 0.36, -d / 2], np.float32), 0.028, (-1, 0, 0), (0, 1, 0), font="stencil")
    col = np.where((front & words)[:, None], yel, col)
    band = front & (np.abs(P[:, 0] + w * 0.33) < 0.05)  # the calibre's band: plain, the colour is the game's
    return np.where(band[:, None], np.array([0.75, 0.74, 0.70], np.float32), col)


# --- ammo_carton -----------------------------------------------------------------------------------------
def ammo_carton(lod):
    w, h, d = CARTON["w"], CARTON["h"], CARTON["d"]
    m = Mesh()
    c = 0.003 if lod == 0 else 0.0
    m.merge(S.chamfer_box((0, h / 2, 0), (w / 2, h / 2, d / 2), c, "card") if c else S.box((0, h / 2, 0), (w / 2, h / 2, d / 2), "card"))
    m.merge(S.box((-w * 0.22, h / 2, 0), (w * 0.15, h / 2 + 0.0015, d / 2 + 0.0015), "stripe"))  # the band round it
    if lod < 2:
        m.merge(S.box((0, h + 0.0008, 0), (w / 2 + 0.0005, 0.0008, 0.022), "tape"))  # the tape over the flaps' seam
        m.merge(S.box((w / 2 + 0.0008, h - 0.02, 0), (0.0008, 0.02, 0.022), "tape"))
        m.merge(S.box((-w / 2 - 0.0008, h - 0.02, 0), (0.0008, 0.02, 0.022), "tape"))
    if lod == 0:  # the flaps' seam under the tape and a torn corner
        m.merge(S.box((0, h + 0.0002, 0), (w / 2, 0.0002, 0.001), "dark"))
    return {"body": Part(m)}


def _paint_carton(P, N, tag, tags, state, col):
    w, h, d = CARTON["w"], CARTON["h"], CARTON["d"]
    ink = np.array([0.15, 0.13, 0.12], np.float32)
    sel = (tag == tags.index("card")) & (N[:, 2] < -0.5)
    words = lettering.mask(P, "50 CARTOUCHES", np.array([w * 0.12, h * 0.62, -d / 2], np.float32), 0.012, (-1, 0, 0), (0, 1, 0))
    words |= lettering.mask(P, "MUNITIONS", np.array([w * 0.12, h * 0.35, -d / 2], np.float32), 0.009, (-1, 0, 0), (0, 1, 0))
    return np.where((sel & words)[:, None], ink, col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3, extra_first=True)

ELEMENTS = {
    "lootbox": dict(build=lootbox, materials=materials(), extra=_paint_loot, edge_radius=0.004, close=(0.0, 0.35, -LOOT["d"] / 2), **_SPEC),
    "ammo_crate": dict(build=ammo_crate, materials=materials(), extra=_paint_crate, edge_radius=0.003, close=(CRATE["w"] / 2, 0.2, 0.0), **_SPEC),
    "ammo_carton": dict(build=ammo_carton, materials=materials(), extra=_paint_carton, edge_radius=0.002, close=(0.0, 0.06, -CARTON["d"] / 2), **_SPEC),
}
