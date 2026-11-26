"""The newspaper kiosk (S172). Card and references: references/elements/kiosk.md; the workflow:
references/elements/WORKFLOW.md.

kiosk: the dark green kiosk of the boulevards (dome_today, dome_1930): a hexagon of cast-iron framed
faces on a stone plinth, each face a name panel over a poster under glass, the corners posts; a
flared cornice crowned with leaf cresting, an attic drum, a scaled dome and its finial. The face to
the street (-Z) is the serving hatch: its shutter hangs from the top of the opening and folds up
and out over the counter (part `shutter`). Standing on y = 0, the hexagon's middle at x = z = 0.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

R = 1.00                 # the hexagon's corners from the middle (= a face's width)
APO = R * np.cos(np.pi / 6)
BODY = (0.12, 2.35)      # the framed faces: plinth top, cornice foot
HATCH = dict(w=0.78, y=(1.00, 1.95))
NAME = (2.06, 2.26)      # the name panel's band
DOME = [(2.84, 0.66), (2.98, 0.66), (3.18, 0.56), (3.36, 0.38), (3.48, 0.16), (3.53, 0.0)]


def materials():
    return {
        "iron": Material((0.10, 0.20, 0.15), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.5, grain=0.07),
        "stone": Material((0.55, 0.54, 0.50), kind="stone", chip=0.0, rusts=False, grain=0.15),
        "poster": Material((0.85, 0.83, 0.78), kind="paper", chip=0.0, rusts=False, grain=0.05,
                           palette=[(0.86, 0.84, 0.80), (0.15, 0.15, 0.16), (0.72, 0.28, 0.20), (0.82, 0.70, 0.40), (0.30, 0.42, 0.55)], vary=0.03),
        "name": Material((0.06, 0.08, 0.07), under=(0.40, 0.24, 0.14), bare=(0.30, 0.18, 0.10), chip=0.3, grain=0.03),
        "dark": Material((0.05, 0.05, 0.05), kind="wood", chip=0.0, rusts=False, grain=0.03, fades=False),
        "paper": Material((0.85, 0.84, 0.80), kind="paper", chip=0.0, rusts=False, grain=0.1,
                          palette=[(0.88, 0.87, 0.84), (0.80, 0.78, 0.72), (0.70, 0.30, 0.25), (0.35, 0.45, 0.60)], vary=0.05),
        "zinc": Material((0.16, 0.20, 0.18), under=(0.40, 0.42, 0.40), bare=(0.45, 0.47, 0.46), chip=0.3, grain=0.05),
        "bolt": Material((0.20, 0.20, 0.20), under=(0.30, 0.18, 0.10), bare=(0.30, 0.17, 0.08), fixing=True, grain=0.1),
    }


def _turn(k):
    """The rotation about Y taking face 0 (its front at -Z) to face k (counter-clockwise from above)."""
    d = -k * np.pi / 3
    c, s = np.cos(d), np.sin(d)
    return np.array([[c, 0, -s], [0, 1, 0], [s, 0, c]], np.float64)


def _on_face(mesh, k):
    return mesh.transformed(_turn(k), (0, 0, 0))


def _face(k, lod, unit):
    """One framed face, built as face 0 (its plane z = -APO) and turned to face k."""
    m = Mesh()
    y0, y1 = BODY
    w = R
    z = -APO
    # the rails: at the foot, under and over the name panel
    for y, h in ((y0 + 0.10, 0.10), (NAME[0] - 0.03, 0.03), (NAME[1] + 0.035, 0.035)):
        m.merge(S.box((0, y, z - 0.015), (w / 2 - 0.05, h, 0.015), "iron"))
    # the name panel, sunk a little in its frame
    m.merge(S.box((0, (NAME[0] + NAME[1]) / 2, z - 0.006), (w / 2 - 0.08, (NAME[1] - NAME[0]) / 2 - 0.01, 0.006), "name"))
    if k == 0:  # the serving hatch: the dark inside, the counter
        hw = HATCH["w"]
        h0, h1 = HATCH["y"]
        m.merge(S.box((0, (h0 + h1) / 2, z + 0.12), (hw / 2, (h1 - h0) / 2, 0.01), "dark"))
        for x in (-hw / 2 - 0.035, hw / 2 + 0.035):
            m.merge(S.box((x, (h0 + h1) / 2, z - 0.015), (0.035, (h1 - h0) / 2, 0.015), "iron"))
        m.merge(S.box((0, h0 - 0.02, z - 0.16), (hw / 2 + 0.05, 0.02, 0.17), "iron"))  # the counter
        m.merge(S.box((0, (y0 + 0.2 + h0 - 0.04) / 2, z - 0.006), (w / 2 - 0.08, (h0 - 0.04 - y0 - 0.2) / 2, 0.006), "iron"))
        if lod == 0:  # papers laid out on the counter
            for i in range(5):
                m.merge(S.box((-0.30 + i * 0.15, h0 + 0.004 + 0.003 * (i % 2), z - 0.17 + 0.02 * (i % 3)), (0.065, 0.003, 0.11), "paper").set_unit(i + 1))
    else:  # a poster under glass in its frame
        p0, p1 = y0 + 0.22, NAME[0] - 0.08
        m.merge(S.box((0, (p0 + p1) / 2, z - 0.004), (w / 2 - 0.10, (p1 - p0) / 2, 0.004), "poster").set_unit(unit))
        if lod < 2:
            fr = [(-w / 2 + 0.09, p0 - 0.01), (w / 2 - 0.09, p0 - 0.01), (w / 2 - 0.09, p1 + 0.01), (-w / 2 + 0.09, p1 + 0.01)]
            m.merge(S.sweep([(x, y, z - 0.012) for x, y in fr], [(-0.012, -0.008), (0.012, -0.008), (0.012, 0.008), (-0.012, 0.008)],
                            "iron", closed=True, up=(0, 0, -1)))
    if lod == 0:  # the cresting's leaves along the cornice's edge
        for i in range(5):
            x = (i - 2) * w / 5
            hgt = 0.16 if i == 2 else 0.11
            leaf = [(-0.08, 0.0), (0.08, 0.0), (0.06, hgt * 0.5), (0.025, hgt * 0.75), (0.0, hgt), (-0.025, hgt * 0.75), (-0.06, hgt * 0.5)]
            m.merge(S.extrude(leaf, 0.015, 0.0, "iron", origin=(x, BODY[1] + 0.16, z - 0.10 + 0.012), right=(1, 0, 0), up=(0, 1, 0)))
    return _on_face(m, k)


def _body(lod):
    m = Mesh()
    y0, y1 = BODY
    # the stone plinth and the hexagon's core
    m.merge(S.lathe([(0.0, R + 0.06), (y0, R + 0.06), (y0, R + 0.02)], 6, tag="stone", caps=(False, True)))
    m.merge(S.lathe([(y0, R - 0.01), (y1, R - 0.01)], 6, tag="iron", caps=(False, False)))
    # the corner posts
    sides = [8, 6, 4][lod]
    for k in range(6):
        a = -np.pi / 2 + np.pi / 6 + k * np.pi / 3 - np.pi / 3
        c = (np.cos(a) * R, 0, np.sin(a) * R)
        post = S.lathe([(y0, 0.055), (y0 + 0.08, 0.055), (y0 + 0.10, 0.045), (y1 - 0.08, 0.045), (y1 - 0.04, 0.06), (y1, 0.06)], sides, tag="iron")
        m.merge(post.transformed(np.eye(3), c))
    # the cornice flaring out, the attic drum, its cap, the dome and finial
    m.merge(S.lathe([(y1, R + 0.02), (y1 + 0.06, R + 0.05), (y1 + 0.12, R + 0.12), (y1 + 0.17, R + 0.12), (y1 + 0.17, 0.70)], 6, tag="iron", caps=(False, False)))
    m.merge(S.lathe([(y1 + 0.17, 0.62), (2.78, 0.62), (2.80, 0.70), (2.84, 0.70), (2.84, 0.66)], 6, tag="iron", caps=(False, False)))
    dome = DOME if lod == 0 else [DOME[i] for i in (0, 2, 3, 5)]
    m.merge(S.lathe(dome, 6, tag="zinc", caps=(False, False)))
    if lod < 2:
        m.merge(S.lathe([(3.50, 0.05), (3.56, 0.06), (3.62, 0.05), (3.66, 0.025), (3.80, 0.0)], [8, 6][lod], tag="iron"))
    if lod == 0:  # the dome's ribs at its corners
        for k in range(6):
            a = -np.pi / 2 + np.pi / 6 + k * np.pi / 3 - np.pi / 3
            pts = [(np.cos(a) * r, y + 0.006, np.sin(a) * r) for y, r in DOME[:-1]]
            m.merge(S.sweep(pts, S.circle(0.018, 4), "iron"))
    return m


def kiosk(lod):
    m = _body(lod)
    for k in range(6):
        m.merge(_face(k, lod, k + 1))
    # the shutter: one panel hanging from the top of the opening, folding up and out
    hw = HATCH["w"]
    h0, h1 = HATCH["y"]
    sh = S.chamfer_box((0, -(h1 - h0) / 2, -0.02), (hw / 2 + 0.03, (h1 - h0) / 2 + 0.02, 0.016), 0.006 if lod == 0 else 0.0, "iron", edges="front") \
        if lod == 0 else S.box((0, -(h1 - h0) / 2, -0.02), (hw / 2 + 0.03, (h1 - h0) / 2 + 0.02, 0.016), "iron")
    if lod == 0:
        for y in (-0.3, -0.65):
            sh.merge(S.box((0, y, -0.038), (hw / 2 - 0.04, 0.012, 0.004), "iron"))
        sh.merge(S.prism((hw / 2 - 0.06, -(h1 - h0) + 0.08, -0.036), 0.012, 0.01, 8, axis=(0, 0, -1), tag="bolt"))
    hinge = (0.0, h1 + 0.02, -APO - 0.01)
    return {"body": Part(m), "shutter": Part(sh.transformed(np.eye(3), hinge), hinge, {"rotate": [[1, 0, 0], 105.0]})}


def _paint(P, N, tag, tags, state, col):
    """PRESSE on every name panel; the posters' invented titles."""
    sel = tag == tags.index("name")
    words = np.zeros(len(P), bool)
    for k in range(6):
        T = _turn(k)
        c = T @ np.array([0, (NAME[0] + NAME[1]) / 2, -APO - 0.012])
        right = T @ np.array([-1.0, 0, 0])
        near = np.abs((P - c) @ (T @ np.array([0, 0, -1.0]))) < 0.03   # only this face's plane: the opposite face is parallel
        words |= lettering.mask(P, "PRESSE", c.astype(np.float32), 0.08, right, (0, 1, 0), weight=1.3) & near
    col = np.where((sel & words)[:, None], np.array([0.86, 0.80, 0.62], np.float32), col)
    pos = tag == tags.index("poster")
    title = pos & (np.mod(P[:, 1] * 3.1, 1.0) < 0.12) & (P[:, 1] < 1.0)
    return np.where(title[:, None], col * 0.35, col)


ELEMENTS = {
    "kiosk": dict(build=kiosk, materials=materials(), extra=_paint, extra_first=True, states=["clean", "abandoned", "damaged", "burnt"],
                  lods=3, edge_radius=0.005, close=(0.0, 1.6, -APO)),
}
