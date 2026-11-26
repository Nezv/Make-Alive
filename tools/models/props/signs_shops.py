"""Shop signs hung out over the pavement (S160). Cards and references: references/elements/<name>.md;
the workflow: references/elements/WORKFLOW.md.

All of them stand out square from a house's wall: the wall's face is z = 0 (the house +Z), the
sign in the plane x = 0 so it is read from both ways along the street; y = 0 is the bracket's
fixing height (the map puts it at ~3 m).
sign_tabac: the tobacconist's "carotte" (carotte, side): a tall red lozenge, its rim bright,
TABAC down both faces, lit from inside, on a short arm.
sign_pharmacy: the green cross of a pharmacy (cross_lit): a box cross, its faces lit green, a
rim round each arm, on an arm with its cable from the wall.
sign_hanging: the wrought-iron hanging sign (bracket_rats, street_1900): a wall plate, an arm with
a strut and C-scrolls, a framed board hung on two rings, a gilded key cut out on it (a locksmith).
No brand anywhere.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

TABAC = dict(w=0.42, h=1.00, t=0.14, out=0.45)       # the lozenge: width, height, thickness; its middle out from the wall
CROSS = dict(span=0.80, arm=0.27, t=0.13, out=0.55)
HANG = dict(arm=0.95, board=(0.62, 0.42), drop=0.30)


def materials():
    return {
        "red": Material((0.70, 0.08, 0.06), kind="metal", chip=0.3, rusts=False, grain=0.03, emit=(0.55, 0.05, 0.03)),
        "green": Material((0.05, 0.55, 0.25), kind="metal", chip=0.2, rusts=False, grain=0.03, emit=(0.10, 0.85, 0.35)),
        "chrome": Material((0.78, 0.79, 0.80), under=(0.55, 0.55, 0.55), bare=(0.50, 0.50, 0.50), chip=0.3, rusts=False, grain=0.03),
        "case": Material((0.20, 0.21, 0.22), under=(0.40, 0.40, 0.40), bare=(0.42, 0.30, 0.20), chip=0.4, grain=0.05),
        "iron": Material((0.09, 0.09, 0.10), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.6, grain=0.08),
        "board": Material((0.20, 0.12, 0.08), under=(0.40, 0.30, 0.22), bare=(0.42, 0.32, 0.22), kind="wood", chip=0.7, grain=0.10),
        "gilt": Material((0.78, 0.60, 0.22), under=(0.45, 0.30, 0.14), bare=(0.30, 0.20, 0.12), chip=0.4, rusts=False, grain=0.05, fades=False),
        "cable": Material((0.05, 0.05, 0.05), kind="rubber", chip=0.0, rusts=False, grain=0.02),
        "bolt": Material((0.30, 0.30, 0.30), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


def _yz(outline, t, x0, tag, cap=None, chamfer=0.0):
    """An outline of (z, y) points as a slab t thick across x (centred on x0): a sign in the plane x = x0."""
    return S.extrude(outline, t, chamfer, tag, cap_tag=cap, origin=(x0 - t / 2, 0, 0), right=(0, 0, 1), up=(0, 1, 0))  # pushed out towards +x


def _arm(z0, z1, y, lod, tag="case"):
    """A short arm from a wall plate at z = 0 out to z1 (negative), its plate and bolts."""
    m = Mesh()
    m.merge(S.box((0, y, (z0 + z1) / 2), (0.02, 0.025, abs(z1 - z0) / 2), tag))
    m.merge(S.box((0, y, -0.008), (0.07, 0.10, 0.008), tag))
    if lod == 0:
        for dy in (-0.07, 0.07):
            m.merge(S.prism((0, y + dy, -0.016), 0.009, 0.006, 6, axis=(0, 0, -1), tag="bolt"))
    return m


# --- sign_tabac ---------------------------------------------------------------------------------------
def _lozenge(w, h, k=0.30):
    """The carotte's outline in (z, y) round its middle: a tall hexagon, its points top and bottom."""
    return [(0.0, -h / 2), (w / 2, -h / 2 + h * k), (w / 2, h / 2 - h * k), (0.0, h / 2), (-w / 2, h / 2 - h * k), (-w / 2, -h / 2 + h * k)]


def sign_tabac(lod):
    w, h, t, out = TABAC["w"], TABAC["h"], TABAC["t"], TABAC["out"]
    m = Mesh()
    lz = [(z - out, y) for z, y in _lozenge(w, h)]
    m.merge(_yz(lz, t, 0.0, "chrome"))                              # the rim all round
    face = [(z - out, y) for z, y in _lozenge(w - 0.05, h - 0.07)]
    for s in (1, -1):                                              # the two red faces, a little proud of the rim
        m.merge(_yz(face, 0.006, s * (t / 2 + 0.003), "red"))
    m.merge(_arm(0.0, -(out - w / 2) - 0.02, 0.0, lod))
    if lod < 2:  # a second stay from the wall to the top point
        m.merge(S.sweep([(0, 0.25, -0.01), (0, h / 2 - 0.05, -out + 0.02)], [(-0.01, -0.01), (0.01, -0.01), (0.01, 0.01), (-0.01, 0.01)], "case"))
    return {"body": Part(m)}


def _paint_tabac(P, N, tag, tags, state, col):
    h, t, out = TABAC["h"], TABAC["t"], TABAC["out"]
    sel = (tag == tags.index("red")) & (np.abs(N[:, 0]) > 0.5)
    words = np.zeros(len(P), bool)
    for s in (1, -1):  # T A B A C down each face, the reader's right towards -z on the +x face
        for i, ch in enumerate("TABAC"):
            c = np.array([s * (t / 2 + 0.006), h * 0.30 - i * h * 0.15, -out], np.float32)
            words |= lettering.mask(P, ch, c, 0.11, (0, 0, -s), (0, 1, 0), weight=1.6) & (P[:, 0] * s > 0)  # this face only
    return np.where((sel & words)[:, None], np.array([0.95, 0.93, 0.88], np.float32), col)


# --- sign_pharmacy ------------------------------------------------------------------------------------
def _cross(span, arm):
    a, b = arm / 2, span / 2
    return [(a, -b), (a, -a), (b, -a), (b, a), (a, a), (a, b), (-a, b), (-a, a), (-b, a), (-b, -a), (-a, -a), (-a, -b)]


def sign_pharmacy(lod):
    span, arm, t, out = CROSS["span"], CROSS["arm"], CROSS["t"], CROSS["out"]
    m = Mesh()
    cr = [(z - out, y) for z, y in _cross(span, arm)]
    m.merge(_yz(cr, t, 0.0, "case"))
    inner = [(z - out, y) for z, y in _cross(span - 0.04, arm - 0.04)]
    for s in (1, -1):
        m.merge(_yz(inner, 0.008, s * (t / 2 + 0.004), "green"))
    m.merge(_arm(0.0, -(out - span / 2) - 0.01, 0.0, lod))
    if lod < 2:  # the cable: from the wall, sagging, into the cross's back
        m.merge(S.cable((0.0, -0.20, -0.01), (0.0, -0.08, -(out - span / 2) - 0.01), 0.05, r=0.008, n=[8, 4][lod], sides=[5, 3][lod], tag="cable"))
        m.merge(S.sweep([(0, -0.12, -0.01), (0, -0.28, -0.01)], S.circle(0.01, 4), "cable"))
    return {"body": Part(m)}


# --- sign_hanging -------------------------------------------------------------------------------------
def _scroll(c, r0, turns, y_up, lod, tag="iron", flip=1):
    """A C-scroll in the plane x = 0: a spiral round c (z, y) from radius r0 inward."""
    n = [16, 8, 4][lod]
    pts = []
    for k in range(n + 1):
        u = k / n
        a = flip * (np.pi * 2 * turns * u) + y_up
        r = r0 * (1 - 0.65 * u)
        pts.append((0.0, c[1] + np.sin(a) * r, c[0] + np.cos(a) * r))
    return S.sweep(pts, [(-0.008, -0.005), (0.008, -0.005), (0.008, 0.005), (-0.008, 0.005)], tag, up=(1, 0, 0))


def _key(L):
    """A key's outline in (z, y), its bow up: a ring, the shank, the bit."""
    bow = [(np.cos(a) * 0.075, 0.10 + np.sin(a) * 0.075) for a in np.linspace(-np.pi / 2 + 0.35, 3 * np.pi / 2 - 0.35, 12)]
    sh = 0.018
    return [(sh, 0.10 - 0.072)] + bow[1:-1] + [(-sh, 0.10 - 0.072), (-sh, -L + 0.06), (-0.075, -L + 0.06), (-0.075, -L + 0.02),
                                               (-0.04, -L + 0.02), (-0.04, -L), (sh, -L)]


def sign_hanging(lod):
    arm, (bw, bh), drop = HANG["arm"], HANG["board"], HANG["drop"]
    m = Mesh()
    sq = [(-0.011, -0.011), (0.011, -0.011), (0.011, 0.011), (-0.011, 0.011)]
    # the wall plate, the arm, the strut from under it to the wall
    m.merge(S.box((0, -0.15, -0.008), (0.04, 0.22, 0.008), "iron"))
    m.merge(S.sweep([(0, 0.0, -0.01), (0, 0.0, -arm), (0, 0.04, -arm - 0.05)], sq, "iron", up=(1, 0, 0)))
    m.merge(S.sweep([(0, -0.34, -0.01), (0, -0.06, -arm * 0.62)], sq, "iron", up=(1, 0, 0)))
    if lod < 2:  # the scrolls filling the triangle, and one curling over the arm's end
        m.merge(_scroll((-0.20, -0.14), 0.11, 0.85, np.pi * 0.5, lod))
        m.merge(_scroll((-0.42, 0.07), 0.07, 0.8, -np.pi * 0.5, lod, flip=-1))
        if lod == 0:
            m.merge(_scroll((-arm + 0.06, 0.09), 0.05, 0.9, 0.0, lod))
            m.merge(_scroll((-0.08, -0.26), 0.05, 0.8, np.pi, lod, flip=-1))
            for b in range(3):  # leaves along the arm
                z = -0.25 - b * 0.22
                m.merge(_yz([(z - 0.035, 0.012), (z, 0.06), (z + 0.035, 0.012)], 0.006, 0.0, "gilt"))
    # the board hung from two rings under the arm, its frame, the key
    zc = -arm * 0.58
    yb = -drop
    for z in (zc - bw * 0.35, zc + bw * 0.35):
        ring = [(0.0, -0.035 + np.sin(a) * 0.03, z + np.cos(a) * 0.03) for a in np.linspace(0, 2 * np.pi, 9)[:-1]]
        m.merge(S.sweep(ring, [(-0.004, -0.004), (0.004, -0.004), (0.004, 0.004), (-0.004, 0.004)], "iron", closed=True, up=(1, 0, 0)))
        m.merge(S.box((0, (yb + bh / 2 - 0.06) / 2 - 0.03, z), (0.005, abs(yb + bh / 2 + 0.06) / 2 - 0.03, 0.005), "iron"))
    board = [(zc - bw / 2, yb - bh / 2), (zc + bw / 2, yb - bh / 2), (zc + bw / 2, yb + bh / 2), (zc - bw / 2, yb + bh / 2)]
    m.merge(_yz(board, 0.035, 0.0, "board"))
    if lod < 2:
        fr = [(0.0, y, z) for z, y in board]
        m.merge(S.sweep(fr, [(-0.022, -0.012), (0.022, -0.012), (0.022, 0.012), (-0.022, 0.012)], "iron", closed=True, up=(1, 0, 0)))
    key = [(zc + y + 0.07, yb + z) for z, y in _key(0.32)]  # the key lying along the board, centred on it
    for s in (1, -1):
        m.merge(_yz(key, 0.008, s * 0.0215, "gilt"))
    return {"body": Part(m)}


ELEMENTS = {
    "sign_tabac": dict(build=sign_tabac, materials=materials(), extra=_paint_tabac, extra_first=True, states=["clean", "abandoned", "damaged", "burnt"],
                       lods=3, edge_radius=0.003, close=(0.0, 0.0, -TABAC["out"])),
    "sign_pharmacy": dict(build=sign_pharmacy, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"],
                          lods=3, edge_radius=0.003, close=(0.0, 0.0, -CROSS["out"])),
    "sign_hanging": dict(build=sign_hanging, materials=materials(), states=["clean", "abandoned", "damaged", "burnt"],
                         lods=3, edge_radius=0.003, close=(0.0, -0.2, -0.5)),
}
