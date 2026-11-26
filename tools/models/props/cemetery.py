"""The old cemetery (S189). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

tomb_chapel: a family chapel like a little house (four_chapels, classical): a stone cell on a
plinth with a step, pilasters at its corners, an entablature, a pediment and its stone roof, a
cross on the ridge, the iron and glass door (part `door`, opening outwards), the name on the frieze.
tomb_cross: a cast-iron cross on its stone pedestal (cast_cross): the cross with trefoil ends and a
ring at its crossing, its scrolls, on a pedestal with a plaque and a cornice.
tomb_slab: the common grave: a stone border round the gravel, the slab, the headstone at its head
with a rounded top and the carved name, a small iron railing round it.
obelisk: a family obelisk (alley): two steps, a die with its cornice, the tapering shaft, its point.

Standing on y = 0, the front -Z.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

CHAPEL = dict(w=1.70, d=2.30, h=2.60, roof=0.80, door=(0.80, 1.85))
FAMILY = "FAMILLE DUVAL"           # invented
SLAB = dict(w=0.95, l=2.10, head=0.95)


def materials():
    return {
        "stone": Material((0.70, 0.68, 0.62), kind="stone", chip=0.0, rusts=False, grain=0.14),
        "dark_stone": Material((0.42, 0.42, 0.40), kind="stone", chip=0.0, rusts=False, grain=0.14),
        "iron": Material((0.10, 0.10, 0.11), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.6, grain=0.08),
        "door": Material((0.16, 0.30, 0.28), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.6, grain=0.06),
        "glass": Material((0.30, 0.34, 0.36), kind="glass", chip=0.0, rusts=False, grain=0.03, sheds=False),
        "gravel": Material((0.55, 0.52, 0.46), kind="sand", chip=0.0, rusts=False, grain=0.3),
        "plaque": Material((0.20, 0.20, 0.22), kind="stone", chip=0.0, rusts=False, grain=0.05),
        "wall": Material((0.74, 0.70, 0.62), kind="plaster", chip=0.0, rusts=False, grain=0.16),
        "carved": Material((0.76, 0.72, 0.64), kind="stone", chip=0.0, rusts=False, grain=0.12),
    }


# --- tomb_chapel ----------------------------------------------------------------------------------------
def tomb_chapel(lod):
    w, d, h, rf = CHAPEL["w"], CHAPEL["d"], CHAPEL["h"], CHAPEL["roof"]
    dw, dh = CHAPEL["door"]
    m = Mesh()
    c = 0.015 if lod == 0 else 0.0
    # plinth and step, the cell
    m.merge(S.chamfer_box((0, 0.15, 0), (w / 2 + 0.08, 0.15, d / 2 + 0.08), c, "stone", edges="top") if c else S.box((0, 0.15, 0), (w / 2 + 0.08, 0.15, d / 2 + 0.08), "stone"))
    m.merge(S.box((0, 0.075, -d / 2 - 0.25), (w / 2 - 0.1, 0.075, 0.17), "stone"))
    m.merge(S.box((0, 0.30 + (h - 0.55) / 2, 0), (w / 2, (h - 0.55) / 2, d / 2), "stone"))
    # the pilasters at the corners, the entablature, the frieze
    if lod < 2:
        for sx in (1, -1):
            for sz in (1, -1):
                m.merge(S.box((sx * (w / 2 - 0.06), 0.30 + (h - 0.55) / 2, sz * (d / 2 - 0.06)), (0.10, (h - 0.55) / 2, 0.10), "stone"))
    for y0, y1, o in ((h - 0.25, h - 0.12, 0.03), (h - 0.12, h, 0.09)):
        m.merge(S.box((0, (y0 + y1) / 2, 0), (w / 2 + o, (y1 - y0) / 2, d / 2 + o), "stone"))
    # the pediment and the roof: a stone gable over the front, the ridge running back
    gable = [(-w / 2 - 0.10, h), (w / 2 + 0.10, h), (0.0, h + rf)]
    m.merge(S.extrude(gable, d + 0.20, 0.0, "stone", origin=(0, 0, d / 2 + 0.10), right=(1, 0, 0), up=(0, 1, 0)))
    if lod < 2:  # the raking cornice proud of the pediment, the cross on the front of the ridge
        for s in (1, -1):
            m.merge(S.sweep([(s * (w / 2 + 0.12), h + 0.01, -d / 2 - 0.12), (0.0, h + rf + 0.03, -d / 2 - 0.12)],
                            [(-0.03, -0.04), (0.03, -0.04), (0.03, 0.04), (-0.03, 0.04)], "stone", up=(0, 0, -1)))
        m.merge(S.box((0, h + rf + 0.28, -d / 2), (0.035, 0.28, 0.035), "stone"))
        m.merge(S.box((0, h + rf + 0.38, -d / 2), (0.15, 0.035, 0.035), "stone"))
    # the door's opening and its frame; a dark inside, an altar shelf
    m.merge(S.opening_frame(dw, dh, [(0.0, 0.0), (0.10, 0.0), (0.10, -0.03), (0.0, -0.03)], arch=0.12, origin=(0, 0.30, -d / 2), tag="stone", bottom=False))
    door = Mesh()
    door.merge(S.box((0, dh / 2, -0.02), (dw / 2 - 0.01, dh / 2 - 0.01, 0.02), "door"))
    if lod < 2:  # the iron grille over its glass upper half
        door.merge(S.box((0, dh * 0.68, -0.045), (dw / 2 - 0.08, dh * 0.27, 0.004), "glass"))
        for k in range([7, 3][lod]):
            x = -dw / 2 + 0.10 + k * (dw - 0.20) / ([7, 3][lod] - 1)
            door.merge(S.box((x, dh * 0.68, -0.05), (0.008, dh * 0.27, 0.008), "door"))
    door = door.transformed(np.eye(3), (0.0, 0.30, -d / 2 - 0.005))   # on the wall's face inside its surround (the cell is solid)
    hinge = (-dw / 2, 0.30, -d / 2 - 0.005)
    return {"body": Part(m), "door": Part(door, hinge, {"rotate": [[0, 1, 0], 100.0]})}   # it opens out


def _paint_chapel(P, N, tag, tags, state, col):
    w, d, h = CHAPEL["w"], CHAPEL["d"], CHAPEL["h"]
    sel = (tag == tags.index("stone")) & (N[:, 2] < -0.5) & (P[:, 1] > h - 0.25) & (P[:, 1] < h - 0.12)
    words = lettering.mask(P, FAMILY, np.array([0, h - 0.185, -d / 2 - 0.03], np.float32), 0.07, (-1, 0, 0), (0, 1, 0), weight=1.3)
    return np.where((sel & words)[:, None], col * 0.45, col)


# --- tomb_cross ------------------------------------------------------------------------------------------
def _trefoil(c, axis_out, lod):
    """The cross's arm end: three lobes round c, in the plane x = 0."""
    m = Mesh()
    for a in (-0.9, 0.0, 0.9):
        d = S.rotation((1, 0, 0), a) @ np.asarray(axis_out, np.float64)
        p = np.asarray(c) + d * 0.04
        m.merge(S.prism(p - np.array([0.012, 0, 0]), 0.032, 0.024, [8, 6][lod], axis=(1, 0, 0), tag="iron"))
    return m


def tomb_cross(lod):
    m = Mesh()
    # the pedestal: a base, the die with its plaque, a cornice
    m.merge(S.chamfer_box((0, 0.10, 0), (0.36, 0.10, 0.36), 0.02 if lod == 0 else 0.0, "stone", edges="top") if lod == 0 else S.box((0, 0.10, 0), (0.36, 0.10, 0.36), "stone"))
    m.merge(S.box((0, 0.20 + 0.28, 0), (0.27, 0.28, 0.27), "stone"))
    m.merge(S.chamfer_box((0, 0.80, 0), (0.32, 0.04, 0.32), 0.02 if lod == 0 else 0.0, "stone", edges="top") if lod == 0 else S.box((0, 0.80, 0), (0.32, 0.04, 0.32), "stone"))
    m.merge(S.box((0, 0.50, -0.275), (0.18, 0.13, 0.006), "plaque"))
    # the cross: an upright and a bar of flat iron, a ring at their crossing, trefoil ends
    y0, H, cy = 0.84, 1.25, 0.84 + 0.85
    t = 0.035
    m.merge(S.box((0, y0 + H / 2, 0), (t / 2, H / 2, 0.025), "iron"))
    m.merge(S.box((0, cy, 0), (t / 2, 0.025, 0.36), "iron"))
    if lod < 2:
        ring = [(0.0, cy + np.sin(a) * 0.12, np.cos(a) * 0.12) for a in np.linspace(0, 2 * np.pi, [16, 10][lod] + 1)[:-1]]
        m.merge(S.sweep(ring, [(-0.012, -0.008), (0.012, -0.008), (0.012, 0.008), (-0.012, 0.008)], "iron", closed=True, up=(1, 0, 0)))
        for c, out in (((0, y0 + H, 0), (0, 1, 0)), ((0, cy, 0.36), (0, 0, 1)), ((0, cy, -0.36), (0, 0, -1))):
            m.merge(_trefoil(c, out, lod))
        if lod == 0:  # the scrolls in the angles of the cross
            for sy in (1, -1):
                for sz in (1, -1):
                    pts = [(0.0, cy + sy * (0.03 + 0.07 * (1 - u) * abs(np.sin(u * 4))), sz * (0.03 + 0.10 * u)) for u in np.linspace(0, 1, 7)]
                    m.merge(S.sweep(pts, [(-0.01, -0.004), (0.01, -0.004), (0.01, 0.004), (-0.01, 0.004)], "iron", up=(1, 0, 0)))
            m.merge(S.box((0, y0 + 0.05, 0), (0.045, 0.05, 0.06), "iron"))   # its socket in the pedestal
    return {"body": Part(m)}


def _paint_cross(P, N, tag, tags, state, col):
    sel = (tag == tags.index("plaque")) & (N[:, 2] < -0.5)
    words = lettering.mask(P, "ICI REPOSE", np.array([0, 0.56, -0.281], np.float32), 0.025, (-1, 0, 0), (0, 1, 0)) | \
        lettering.mask(P, "J. DUVAL", np.array([0, 0.49, -0.281], np.float32), 0.03, (-1, 0, 0), (0, 1, 0), weight=1.2) | \
        lettering.mask(P, "1802 - 1861", np.array([0, 0.43, -0.281], np.float32), 0.02, (-1, 0, 0), (0, 1, 0))
    return np.where((sel & words)[:, None], np.array([0.75, 0.66, 0.40], np.float32), col)


# --- tomb_slab -------------------------------------------------------------------------------------------
def tomb_slab(lod):
    w, l, hh = SLAB["w"], SLAB["l"], SLAB["head"]
    m = Mesh()
    # the border and the slab over the grave, the gravel at its foot
    m.merge(S.box((0, 0.10, 0), (w / 2, 0.10, l / 2), "stone"))
    m.merge(S.chamfer_box((0, 0.25, 0.05), (w / 2 - 0.04, 0.05, l / 2 - 0.10), 0.02 if lod == 0 else 0.0, "stone", edges="top") if lod == 0 else
            S.box((0, 0.25, 0.05), (w / 2 - 0.04, 0.05, l / 2 - 0.10), "stone"))
    # the headstone at the grave's head (-Z), its face towards the foot (+Z) where the visitor stands
    n = [10, 6, 4][lod]
    arc = [(np.cos(a) * (w / 2 - 0.05), hh - (w / 2 - 0.05) + np.sin(a) * (w / 2 - 0.05)) for a in np.linspace(0, np.pi, n + 1)]
    stele = [(w / 2 - 0.05, 0.0)] + arc + [(-w / 2 + 0.05, 0.0)]
    m.merge(S.extrude(stele, 0.12, 0.012 if lod == 0 else 0.0, "stone", origin=(0, 0.20, -l / 2 + 0.02), right=(-1, 0, 0), up=(0, 1, 0)))
    if lod < 2:  # the low iron railing round it: posts with ball tops, two rails
        rail = [(-w / 2 - 0.10, 0.0, -l / 2 - 0.05), (w / 2 + 0.10, 0.0, -l / 2 - 0.05), (w / 2 + 0.10, 0.0, l / 2 + 0.10), (-w / 2 - 0.10, 0.0, l / 2 + 0.10)]
        for y in (0.15, 0.45):
            m.merge(S.sweep([(x, y, z) for x, _, z in rail], [(-0.008, -0.008), (0.008, -0.008), (0.008, 0.008), (-0.008, 0.008)], "iron", closed=True))
        for x, _, z in rail:
            m.merge(S.box((x, 0.25, z), (0.012, 0.25, 0.012), "iron"))
            m.merge(S.lathe([(0.50, 0.0), (0.51, 0.02), (0.54, 0.022), (0.56, 0.0)], 6, tag="iron").transformed(np.eye(3), (x, 0, z)))
        if lod == 0:
            for side in range(4):
                (ax, _, az), (bx, _, bz) = rail[side], rail[(side + 1) % 4]
                L = np.hypot(bx - ax, bz - az)
                for k in range(1, int(L / 0.12)):
                    t = k / int(L / 0.12)
                    m.merge(S.box((ax + (bx - ax) * t, 0.30, az + (bz - az) * t), (0.005, 0.15, 0.005), "iron"))
    return {"body": Part(m)}


def _paint_slab(P, N, tag, tags, state, col):
    w, l, hh = SLAB["w"], SLAB["l"], SLAB["head"]
    sel = (tag == tags.index("stone")) & (N[:, 2] > 0.5) & (P[:, 1] > 0.3)          # the headstone's face looks +Z
    z = -l / 2 + 0.14
    words = lettering.mask(P, "FAMILLE", np.array([0, 0.20 + hh * 0.62, z], np.float32), 0.05, (1, 0, 0), (0, 1, 0), weight=1.2) | \
        lettering.mask(P, "MOREAU", np.array([0, 0.20 + hh * 0.50, z], np.float32), 0.07, (1, 0, 0), (0, 1, 0), weight=1.4)
    return np.where((sel & words)[:, None], col * 0.45, col)


# --- obelisk ---------------------------------------------------------------------------------------------
def obelisk(lod):
    m = Mesh()
    for k, (hw, y0, y1) in enumerate(((0.65, 0.0, 0.15), (0.52, 0.15, 0.30))):
        m.merge(S.box((0, (y0 + y1) / 2, 0), (hw, (y1 - y0) / 2, hw), "stone"))
    m.merge(S.box((0, 0.30 + 0.40, 0), (0.38, 0.40, 0.38), "stone"))   # the die
    m.merge(S.chamfer_box((0, 1.14, 0), (0.44, 0.04, 0.44), 0.02 if lod == 0 else 0.0, "stone", edges="top") if lod == 0 else S.box((0, 1.14, 0), (0.44, 0.04, 0.44), "stone"))
    shaft = S.lathe([(1.18, 0.30 * np.sqrt(2)), (3.30, 0.17 * np.sqrt(2)), (3.30, 0.17 * np.sqrt(2)), (3.55, 0.0)], 4, turn=np.pi / 4, tag="dark_stone")
    m.merge(shaft)
    if lod < 2:
        m.merge(S.box((0, 0.72, -0.385), (0.24, 0.18, 0.006), "plaque"))
        if lod == 0:  # a bronze wreath on the shaft: a ring
            ring = [(np.cos(a) * 0.11, 1.75 + np.sin(a) * 0.11, -0.27) for a in np.linspace(0, 2 * np.pi, 13)[:-1]]
            m.merge(S.sweep(ring, S.circle(0.018, 5), "plaque", closed=True, up=(0, 0, -1)))
    return {"body": Part(m)}


# --- tomb_gothic -------------------------------------------------------------------------------------------
def _pointed(w, spring, n):
    """A pointed arch's outline in (x, y) from the left foot round to the right foot: straight
    jambs to `spring`, two arcs of radius 0.8 w meeting at the point."""
    r = 0.8 * w
    cx = w / 2 - r                     # the right arc's centre lies left of the right jamb
    a1 = np.arccos(-cx / r)            # where the arc meets x = 0
    right = [(cx + r * np.cos(a), spring + r * np.sin(a)) for a in np.linspace(0.0, a1, n + 1)]
    left = [(-x, y) for x, y in right]                       # up the left side to the point
    return [(-w / 2, 0.0)] + left + list(reversed(right))[1:] + [(w / 2, 0.0)]


def _pinnacle(c, h, s, lod):
    """A square pinnacle at c: shaft `s` wide, a little gable each face, its pyramid and knob."""
    m = Mesh()
    m.merge(S.box((c[0], c[1] + h * 0.55 / 2, c[2]), (s / 2, h * 0.55 / 2, s / 2), "stone"))
    m.merge(S.lathe([(c[1] + h * 0.55, s * 0.75), (c[1] + h * 0.62, s * 0.75), (c[1] + h, 0.0)], 4, turn=np.pi / 4, tag="stone").transformed(np.eye(3), (c[0], 0, c[2])))
    if lod == 0:
        m.merge(S.lathe([(c[1] + h - 0.02, 0.0), (c[1] + h + 0.03, 0.035), (c[1] + h + 0.08, 0.0)], 6, tag="stone").transformed(np.eye(3), (c[0], 0, c[2])))
    return m


def tomb_gothic(lod):
    w, d, h, rf = GOTHIC["w"], GOTHIC["d"], GOTHIC["h"], GOTHIC["roof"]
    dw, ds = GOTHIC["door"]
    m = Mesh()
    c = 0.015 if lod == 0 else 0.0
    m.merge(S.chamfer_box((0, 0.15, 0), (w / 2 + 0.10, 0.15, d / 2 + 0.10), c, "stone", edges="top") if c else S.box((0, 0.15, 0), (w / 2 + 0.10, 0.15, d / 2 + 0.10), "stone"))
    m.merge(S.box((0, 0.075, -d / 2 - 0.27), (w / 2 - 0.1, 0.075, 0.17), "stone"))
    m.merge(S.box((0, 0.30 + (h - 0.30) / 2, 0), (w / 2, (h - 0.30) / 2, d / 2), "stone"))
    # the steep gable roof of stone slabs, its ridge running back; the front gable's coping proud of it
    gable = [(-w / 2 - 0.06, h), (w / 2 + 0.06, h), (0.0, h + rf)]
    m.merge(S.extrude(gable, d + 0.12, 0.0, "dark_stone", origin=(0, 0, d / 2 + 0.06), right=(1, 0, 0), up=(0, 1, 0)))
    m.merge(S.extrude([(-w / 2, h - 0.02), (w / 2, h - 0.02), (0.0, h + rf - 0.04)], 0.04, 0.0, "stone", origin=(0, 0, -d / 2 + 0.01), right=(1, 0, 0), up=(0, 1, 0)))
    for s in (1, -1):  # the raking copings with their crockets
        rake = [(s * (w / 2 + 0.10), h + 0.0, -d / 2 - 0.10), (0.0, h + rf + 0.05, -d / 2 - 0.10)]
        m.merge(S.sweep(rake, [(-0.045, -0.05), (0.045, -0.05), (0.045, 0.05), (-0.045, 0.05)], "stone", up=(0, 0, -1)))
        if lod == 0:
            for t in np.linspace(0.15, 0.85, 5):
                p = np.array(rake[0]) + (np.array(rake[1]) - np.array(rake[0])) * t
                m.merge(S.prism(p + (0, 0.07, 0), 0.03, 0.06, 5, axis=(s * -0.4, 1, 0), tag="stone"))
    # buttresses set diagonally at the corners, each carrying a pinnacle
    for sx in (1, -1):
        for sz in (1, -1):
            R = S.rotation((0, 1, 0), np.pi / 4 * sx * sz)
            if lod < 2:
                for k, (hh, out) in enumerate(((h * 0.55, 0.20), (h * 0.85, 0.12))):
                    m.merge(S.box((0, 0.30 + hh / 2, 0), (0.08, hh / 2, out), "stone").transformed(R, (sx * w / 2, 0, sz * d / 2)))
            m.merge(_pinnacle((sx * (w / 2 + 0.02), h - 0.10, sz * (d / 2 + 0.02)), 0.95, 0.16, lod))
    # the front: a pointed doorway in a moulded frame under a gablet, a cross on the apex
    n = [8, 5, 3][lod]
    door_out = _pointed(dw, ds, n)
    frame = S.sweep([(x, y + 0.30, -d / 2 - 0.02) for x, y in door_out], [(-0.07, -0.05), (0.07, -0.05), (0.07, 0.05), (-0.07, 0.05)], "stone", up=(0, 0, -1)) if lod < 2 else Mesh()
    m.merge(frame)
    apex = max(y for _, y in door_out) + 0.30
    if lod < 2:
        m.merge(S.extrude([(-dw / 2 - 0.16, apex - 0.35), (dw / 2 + 0.16, apex - 0.35), (0.0, apex + 0.30)], 0.06, 0.0, "stone", origin=(0, 0, -d / 2 - 0.02), right=(1, 0, 0), up=(0, 1, 0)))
        m.merge(S.extrude([(-0.03, 0.0), (0.03, 0.0), (0.03, 0.22), (0.10, 0.22), (0.10, 0.28), (0.03, 0.28), (0.03, 0.36), (-0.03, 0.36), (-0.03, 0.28), (-0.10, 0.28), (-0.10, 0.22), (-0.03, 0.22)],
                          0.05, 0.0, "stone", origin=(0, h + rf + 0.06, -d / 2 - 0.08), right=(1, 0, 0), up=(0, 1, 0)))
        for s in (1, -1):  # the lancet windows down the sides, glazed dark
            lancet = _pointed(0.30, 0.75, [6, 3][lod])
            m.merge(S.extrude(lancet, 0.01, 0.0, "glass", origin=(s * (w / 2 + 0.005), 0.95, 0.0), right=(0, 0, -s), up=(0, 1, 0)))
    # the door: iron and glass under its point, opening out
    door = S.extrude(door_out, 0.035, 0.0, "door", origin=(0, 0.30, -d / 2 + 0.0), right=(1, 0, 0), up=(0, 1, 0))
    if lod < 2:
        door.merge(S.extrude(_pointed(dw - 0.20, ds - 0.20, n), 0.004, 0.0, "glass", origin=(0, 0.50, -d / 2 - 0.035), right=(1, 0, 0), up=(0, 1, 0)))
        for k in range([5, 3][lod]):
            x = -dw / 2 + 0.16 + k * (dw - 0.32) / ([5, 3][lod] - 1)
            door.merge(S.box((x, 0.50 + ds * 0.55, -d / 2 - 0.042), (0.008, ds * 0.42, 0.008), "door"))
    hinge = (-dw / 2, 0.30, -d / 2)
    return {"body": Part(m), "door": Part(door, hinge, {"rotate": [[0, 1, 0], 100.0]})}


def _paint_gothic(P, N, tag, tags, state, col):
    w, d, h = GOTHIC["w"], GOTHIC["d"], GOTHIC["h"]
    dw, ds = GOTHIC["door"]
    y = 0.30 + ds + 0.8 * dw * 0.6 + 0.12
    sel = (tag == tags.index("stone")) & (N[:, 2] < -0.5) & (np.abs(P[:, 2] + d / 2 + 0.08) < 0.03)
    words = lettering.mask(P, GOTHIC_NAME, np.array([0, y - 0.28, -d / 2 - 0.08], np.float32), 0.045, (-1, 0, 0), (0, 1, 0), weight=1.3)
    return np.where((sel & words)[:, None], col * 0.45, col)


# --- cemetery_gate ------------------------------------------------------------------------------------------
def _cem_leaf(x0, x1, lod):
    H = CGATE["leaf_h"]
    m = Mesh()
    flat = [(-0.025, -0.012), (0.025, -0.012), (0.025, 0.012), (-0.025, 0.012)]
    for x in (x0, x1):
        m.merge(S.sweep([(x, 0.04, 0), (x, H, 0)], flat, "iron", up=(0, 0, 1)))
    for y in ((0.06, 0.95, H - 0.25) if lod < 2 else (0.06, H - 0.25)):
        m.merge(S.sweep([(x0, y, 0), (x1, y, 0)], flat, "iron", up=(0, 0, 1)))
    lo, hi = min(x0, x1), max(x0, x1)
    nb = int((hi - lo) / [0.12, 0.20, 0.40][lod])
    for i in range(nb):
        x = lo + (i + 0.5) * (hi - lo) / nb
        top = H + 0.12
        m.merge(S.sweep([(x, 0.06, 0), (x, top, 0)], S.circle(0.011, [6, 4, 4][lod]), "iron"))
        if lod < 2:
            m.merge(S.lathe([(0.0, 0.0), (0.02, 0.024), (0.08, 0.0)], [6, 4][lod], tag="iron").transformed(np.eye(3), (x, top, 0)))
    if lod == 0:  # a cross wrought in the middle of each leaf, plate panels at the foot
        xm = (lo + hi) / 2
        m.merge(S.box((xm, 1.45, -0.016), (0.02, 0.32, 0.006), "iron"))
        m.merge(S.box((xm, 1.55, -0.016), (0.14, 0.02, 0.006), "iron"))
        m.merge(S.box(((lo + hi) / 2, 0.50, 0.0), ((hi - lo) / 2 - 0.03, 0.42, 0.004), "iron"))
    return m


def _cem_pier(x, lod):
    """A broad pylon: plinth, shaft, a band, its half-round top with a carved roundel, a garland under it."""
    H, p, pw = CGATE["pier_h"], CGATE["pier"], CGATE["pylon"]
    m = Mesh()
    c = 0.015 if lod == 0 else 0.0
    m.merge(_cbx((x, 0.25, 0), (pw / 2 + 0.06, 0.25, p / 2 + 0.06), c, "stone", edges="top"))
    m.merge(S.box((x, 0.50 + (H - 0.50) / 2, 0), (pw / 2, (H - 0.50) / 2, p / 2), "stone"))
    m.merge(_cbx((x, H - 0.06, 0), (pw / 2 + 0.04, 0.06, p / 2 + 0.04), c, "stone"))
    n = [16, 10, 6][lod]
    top = [(np.cos(a) * pw / 2, np.sin(a) * pw / 2) for a in np.linspace(0, np.pi, n + 1)]
    m.merge(S.extrude(top, p, 0.0, "stone", origin=(x, H, p / 2), right=(1, 0, 0), up=(0, 1, 0)))
    if lod < 2:
        disc = S.lathe([(0.0, 0.0), (0.0, 0.34), (0.04, 0.34), (0.05, 0.27), (0.07, 0.26), (0.08, 0.0)], [16, 10][lod], tag="carved")
        m.merge(S.along(disc, (0, 0, -1), (x, H + 0.12, -p / 2)))
        if lod == 0:  # the hourglass carved in the roundel, wings either side
            m.merge(S.lathe([(0.0, 0.07), (0.09, 0.012), (0.18, 0.07), (0.18, 0.0)], 6, tag="carved").transformed(np.eye(3), (x, H + 0.03, -p / 2 - 0.10)))
            for s in (1, -1):
                m.merge(S.box((x + s * 0.15, H + 0.14, -p / 2 - 0.09), (0.09, 0.03, 0.01), "carved").transformed(np.eye(3), (0, 0, 0)))
        m.merge(S.cable((x - pw / 2 + 0.12, H - 0.30, -p / 2 - 0.04), (x + pw / 2 - 0.12, H - 0.30, -p / 2 - 0.04), 0.28, r=0.05, n=[10, 5][lod], sides=5, tag="carved"))
    return m

def cemetery_gate(lod):
    W, p, pw, Hw, H = CGATE["w"], CGATE["pier"], CGATE["pylon"], CGATE["wall_h"], CGATE["pier_h"]
    m = Mesh()
    xp = W / 2 + pw / 2
    for s in (1, -1):
        m.merge(_cem_pier(s * xp, lod))
        # a bay of the wall each side: rubble under its render, a stone base, the coping
        x0, x1 = s * (xp + pw / 2), s * (xp + pw / 2 + CGATE["wall"])
        xc, hw = (x0 + x1) / 2, abs(x1 - x0) / 2
        m.merge(S.box((xc, Hw / 2, 0.0), (hw, Hw / 2, 0.22), "wall"))
        m.merge(_cbx((xc, Hw + 0.06, 0.0), (hw, 0.06, 0.28), 0.02 if lod == 0 else 0.0, "stone", edges="top"))
        if lod < 2:
            m.merge(S.box((xc, 0.20, 0.0), (hw, 0.20, 0.24), "stone"))
    # the lintel across the gateway, its frieze of wreaths
    ly = H - 0.30
    m.merge(S.box((0, ly, 0), (W / 2, 0.16, 0.22), "stone"))
    if lod < 2:
        for x in np.linspace(-W / 2 + 0.35, W / 2 - 0.35, [6, 4][lod]):
            ring = [(x + np.cos(a) * 0.10, ly + np.sin(a) * 0.10, -0.24) for a in np.linspace(0, 2 * np.pi, [11, 7][lod])[:-1]]
            m.merge(S.sweep(ring, S.circle(0.025, 4), "carved", closed=True, up=(0, 0, -1)))
    parts = {"body": Part(m)}
    for name, x0, x1, side in (("leaf_l", -W / 2, -0.01, 1), ("leaf_r", W / 2, 0.01, -1)):
        parts[name] = Part(_cem_leaf(x0, x1, lod), (x0, 0.0, 0.0), {"rotate": [[0, 1, 0], -95.0 * side]})
    return parts


def _cbx(c, h, r, tag, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if r > 0 else S.box(c, h, tag)

def _paint_cem_gate(P, N, tag, tags, state, col):
    """The cemetery's name cut in the pylons' fronts, one line each (invented)."""
    W, p, pw = CGATE["w"], CGATE["pier"], CGATE["pylon"]
    xp = W / 2 + pw / 2
    sel = (tag == tags.index("stone")) & (N[:, 2] < -0.5) & (np.abs(P[:, 2] + p / 2) < 0.03)
    words = np.zeros(len(P), bool)
    for s, word in ((-1, "CIMETIÈRE"), (1, "DU NORD")):
        words |= lettering.mask(P, word, np.array([s * xp, 2.40, -p / 2 - 0.001], np.float32), 0.09, (-1, 0, 0), (0, 1, 0), weight=1.3) & (np.abs(P[:, 0] - s * xp) < pw / 2)
    return np.where((sel & words)[:, None], col * 0.45, col)

# --- tomb_column --------------------------------------------------------------------------------------------
def tomb_column(lod):
    """The broken column: a life cut short. A stepped base, a die with its plaque, a fluted column
    broken off on a slant, a stone drape over the break and a wreath hung on the shaft."""
    m = Mesh()
    for hw, y0, y1 in ((0.55, 0.0, 0.15), (0.45, 0.15, 0.28)):
        m.merge(S.box((0, (y0 + y1) / 2, 0), (hw, (y1 - y0) / 2, hw), "stone"))
    m.merge(S.box((0, 0.28 + 0.35, 0), (0.34, 0.35, 0.34), "stone"))
    m.merge(S.chamfer_box((0, 1.02, 0), (0.38, 0.04, 0.38), 0.015, "stone", edges="top") if lod == 0 else S.box((0, 1.02, 0), (0.38, 0.04, 0.38), "stone"))
    m.merge(S.box((0, 0.66, -0.345), (0.20, 0.14, 0.006), "plaque"))
    n = [16, 10, 6][lod]
    shaft = S.lathe([(1.06, 0.26), (1.14, 0.26), (1.18, 0.22), (2.60, 0.20)], n, tag="stone",
                    flute=(lambda j, y: 1.0 - 0.05 * (j % 2) * (y > 1.2)) if lod == 0 else None)
    nrm = np.array([0.45, 1.0, 0.2])
    nrm /= np.linalg.norm(nrm)
    m.merge(S.clip(shaft, (0, 2.05, 0), nrm, cap_tag="stone", rough=0.025 if lod == 0 else 0.0, seed=3))
    if lod < 2:
        # the drape over the break, falling down one side
        rings = []
        for k in range([6, 3][lod]):
            y = 2.10 - k * 0.12
            ring = [(np.cos(a) * (0.27 + 0.02 * np.sin(a * 5 + k)), y - 0.10 * max(0.0, np.cos(a - 0.4)) * (k > 0), np.sin(a) * (0.27 + 0.02 * np.sin(a * 5 + k))) for a in np.linspace(-1.2, 1.6, 8)]
            ring += [(x * 0.90, y2, z * 0.90) for x, y2, z in reversed(ring)]
            rings.append(ring)
        drape = Mesh()
        drape.loft(rings, "stone", caps=(True, True))
        m.merge(drape)
        ring = [(np.cos(a) * 0.24, 1.55 + np.sin(a) * 0.02, np.sin(a) * 0.24) for a in np.linspace(0, 2 * np.pi, [14, 8][lod])[:-1]]
        m.merge(S.sweep(ring, S.circle(0.035, 5), "plaque", closed=True))
    return {"body": Part(m)}


GOTHIC = dict(w=1.60, d=2.20, h=2.40, roof=1.40, door=(0.72, 1.45))
GOTHIC_NAME = "FAMILLE LEROUX"     # invented
CGATE = dict(w=3.20, pier=0.80, pylon=1.40, pier_h=4.30, leaf_h=2.80, wall_h=2.60, wall=2.00)

_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "tomb_chapel": dict(build=tomb_chapel, materials=materials(), extra=_paint_chapel, extra_first=True, edge_radius=0.006, close=(0.0, 1.4, -1.2), **_SPEC),
    "tomb_cross": dict(build=tomb_cross, materials=materials(), extra=_paint_cross, extra_first=True, edge_radius=0.003, close=(0.0, 1.6, 0.0), **_SPEC),
    "tomb_slab": dict(build=tomb_slab, materials=materials(), extra=_paint_slab, extra_first=True, edge_radius=0.004, close=(0.0, 0.7, -0.9), **_SPEC),
    "obelisk": dict(build=obelisk, materials=materials(), edge_radius=0.005, close=(0.0, 1.0, -0.4), **_SPEC),
    "tomb_gothic": dict(build=tomb_gothic, materials=materials(), extra=_paint_gothic, extra_first=True, edge_radius=0.006, close=(0.0, 1.6, -1.1), **_SPEC),
    "tomb_column": dict(build=tomb_column, materials=materials(), edge_radius=0.005, close=(0.0, 1.6, -0.3), **_SPEC),
    "cemetery_gate": dict(build=cemetery_gate, materials=materials(), extra=_paint_cem_gate, extra_first=True, edge_radius=0.005, close=(0.0, 2.2, -0.4), **_SPEC),
}
