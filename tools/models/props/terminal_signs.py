"""The bus station's route boards and wayfinding (S202). Cards and references:
references/elements/<name>.md; the workflow: references/elements/WORKFLOW.md.

departure_board: the LED departure display hung under the slab: a black housing on two rods, DÉPARTS
over its columns (line, destination, quay, time) and six rows of invented departures, the letters lit
amber (`emit_where`), the rest of the face dark.
quay_sign: the bay's sign on its post: a blue double-sided box with the quay's letter in a white
disc, the lines that leave from it below, the post on its base plate.
wayfinding_sign: a blue blade hung from the slab on two rods, white words both sides with their
arrows: SORTIE, QUAIS A - F, TAXIS.

The departure board and the blade hang below y = 0 (the slab's soffit), like the fittings; the
quay sign stands on y = 0. The faces look -Z (the blade's and the quay sign's +Z too).
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

BOARD = dict(w=2.40, h=1.00, d=0.14, drop=1.10)
ROWS = [("12", "VIEILLE VILLE", "A", "07:45"), ("4", "GARE", "B", "07:50"), ("31", "FAUBOURG ST-RÉMY", "C", "08:05"),
        ("7", "LA BUTTE", "A", "08:10"), ("22", "LES MOULINS", "D", "08:20"), ("40", "ZONE INDUSTRIELLE", "F", "08:35")]
QUAY = dict(letter="A", lines="12  7  45", h=2.80, w=0.60, sh=0.90, d=0.12)
BLADE = dict(w=1.80, h=0.36, t=0.04, drop=0.60)
AMBER = np.array([1.0, 0.62, 0.12], np.float32)


def materials():
    return {
        "housing": Material((0.08, 0.08, 0.09), under=(0.40, 0.40, 0.40), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.04),
        "led": Material((0.05, 0.05, 0.05), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(1.0, 0.62, 0.12)),
        "steel": Material((0.55, 0.56, 0.57), under=(0.45, 0.45, 0.46), bare=(0.40, 0.30, 0.22), chip=0.3, grain=0.05),
        "blue": Material((0.08, 0.22, 0.48), under=(0.55, 0.56, 0.55), bare=(0.60, 0.61, 0.62), chip=0.3, grain=0.04),
        "face": Material((0.08, 0.22, 0.48), kind="glass", chip=0.0, rusts=False, grain=0.02, sheds=False, emit=(0.55, 0.65, 0.85)),
    }


def _cb(c, h, r, tag, lod, edges="all"):
    return S.chamfer_box(c, h, r, tag, edges=edges) if lod == 0 and r > 0 else S.box(c, h, tag)


# --- departure_board ----------------------------------------------------------------------------------------
def departure_board(lod):
    w, h, d, drop = BOARD["w"], BOARD["h"], BOARD["d"], BOARD["drop"]
    yc = -drop - h / 2
    m = Mesh()
    m.merge(_cb((0, yc, 0), (w / 2, h / 2, d / 2), 0.012, "housing", lod))
    m.merge(S.box((0, yc - 0.03, -d / 2 - 0.002), (w / 2 - 0.05, h / 2 - 0.08, 0.002), "led"))
    for x in (-w / 2 + 0.3, w / 2 - 0.3):  # the rods, their ceiling plates and clamps
        m.merge(S.sweep([(x, 0.0, 0.0), (x, yc + h / 2, 0.0)], S.circle(0.012, [8, 5, 4][lod]), "steel"))
        if lod < 2:
            m.merge(S.lathe([(-0.01, 0.06), (0.0, 0.06)], [10, 6][lod], tag="steel", caps=(True, True)).transformed(np.eye(3), (x, 0, 0)))
            m.merge(S.box((x, yc + h / 2 + 0.02, 0), (0.04, 0.02, 0.04), "steel"))
    if lod < 2:  # the vents on top, the cable in
        m.merge(S.sweep([(0.2, 0.0, 0.03), (0.2, yc + h / 2, 0.03)], S.circle(0.008, 4), "housing"))
    return {"body": Part(m)}


def _board_text(P):
    """Every lit character of the board, as a mask."""
    w, h, d, drop = BOARD["w"], BOARD["h"], BOARD["d"], BOARD["drop"]
    yc = -drop - h / 2
    z = -d / 2 - 0.004
    face = np.abs(P[:, 2] - z) < 0.004
    words = np.zeros(len(P), bool)
    top = yc + h / 2 - 0.17

    def put(text, x_left, y, hh, weight=1.2):
        wd = lettering.width(text, hh)
        # the reader's right is -X: a text starting at the reader's left (x_left, +X side) has its centre toward -X
        c = np.array([x_left - wd / 2, y, z], np.float32)
        return lettering.mask(P, text, c, hh, (-1, 0, 0), (0, 1, 0), weight=weight)

    x0 = w / 2 - 0.12
    words |= put("DÉPARTS", x0, top, 0.09, 1.4)
    cols = [x0, x0 - 0.26, x0 - 1.55, x0 - 1.85]
    for x, head in zip(cols, ("LIGNE", "DESTINATION", "QUAI", "HEURE")):
        words |= put(head, x, top - 0.13, 0.045)
    for i, row in enumerate(ROWS):
        y = top - 0.24 - i * 0.11
        for x, text in zip(cols, row):
            words |= put(text, x, y, 0.07)
    return words & face


def _paint_board(P, N, tag, tags, state, col):
    sel = tag == tags.index("led")
    lit = _board_text(P) & sel
    return np.where(lit[:, None], AMBER, col)


def _emit_board(P, N, tag, tags):
    return _board_text(P)


# --- quay_sign ----------------------------------------------------------------------------------------------
def quay_sign(lod):
    H, w, sh, d = QUAY["h"], QUAY["w"], QUAY["sh"], QUAY["d"]
    m = Mesh()
    m.merge(_cb((0, 0.01, 0), (0.15, 0.01, 0.15), 0.004, "steel", lod, edges="top"))
    m.merge(S.lathe([(0.02, 0.05), (0.06, 0.045), (H - sh, 0.045)], [10, 6, 4][lod], tag="steel"))
    yc = H - sh / 2
    m.merge(_cb((0, yc, 0), (w / 2, sh / 2, d / 2), 0.02, "blue", lod))
    for s in (-1, 1):  # both lit faces
        m.merge(S.box((0, yc, s * (d / 2 + 0.002)), (w / 2 - 0.03, sh / 2 - 0.03, 0.002), "face"))
    if lod < 2:
        m.merge(_cb((0, H + 0.01, 0), (w / 2 + 0.02, 0.012, d / 2 + 0.02), 0.004, "steel", lod))
    return {"body": Part(m)}


def _quay_marks(P):
    """The white disc with the letter knocked out of it, the lines' numbers under it, on each face."""
    H, w, sh, d = QUAY["h"], QUAY["w"], QUAY["sh"], QUAY["d"]
    yc = H - sh / 2
    disc = np.zeros(len(P), bool)
    text = np.zeros(len(P), bool)
    for s in (-1, 1):
        z = s * (d / 2 + 0.004)
        face = np.abs(P[:, 2] - z) < 0.004
        right = (-1, 0, 0) if s < 0 else (1, 0, 0)
        c = np.array([0, yc + 0.12, z], np.float32)
        in_disc = (np.hypot(P[:, 0], P[:, 1] - (yc + 0.12)) < 0.21) & face
        letter = lettering.mask(P, QUAY["letter"], c, 0.24, right, (0, 1, 0), weight=1.6) & face
        disc |= in_disc & ~letter
        text |= lettering.mask(P, QUAY["lines"], np.array([0, yc - 0.26, z], np.float32), 0.08, right, (0, 1, 0), weight=1.3) & face
    return disc, text


def _paint_quay(P, N, tag, tags, state, col):
    sel = tag == tags.index("face")
    disc, text = _quay_marks(P)
    white = np.array([0.92, 0.92, 0.90], np.float32)
    return np.where(((disc | text) & sel)[:, None], white, col)


# --- wayfinding_sign ----------------------------------------------------------------------------------------
def wayfinding_sign(lod):
    w, h, t, drop = BLADE["w"], BLADE["h"], BLADE["t"], BLADE["drop"]
    yc = -drop - h / 2
    m = Mesh()
    m.merge(_cb((0, yc, 0), (w / 2, h / 2, t / 2), 0.008, "blue", lod))
    for x in (-w / 2 + 0.2, w / 2 - 0.2):
        m.merge(S.sweep([(x, 0.0, 0.0), (x, yc + h / 2, 0.0)], S.circle(0.01, [6, 4, 4][lod]), "steel"))
        if lod < 2:
            m.merge(S.box((x, yc + h / 2 + 0.015, 0), (0.03, 0.015, t / 2 + 0.005), "steel"))
    return {"body": Part(m)}


def _arrow(P, tip, direction, size, right, up):
    """An arrow's mask in the plane spanned by right and up: a head and a shaft, pointing along `direction`
    (+1 toward `right`, -1 against it)."""
    rel = P - tip
    u = rel @ np.asarray(right, np.float64) * direction      # along the arrow, 0 at the tip, negative behind it
    v = rel @ np.asarray(up, np.float64)
    head = (u <= 0) & (u > -size * 0.6) & (np.abs(v) < -u * 0.8)          # a point at the tip, widening behind it
    shaft = (u <= -size * 0.5) & (u > -size * 1.3) & (np.abs(v) < size * 0.14)
    return head | shaft


def _blade_marks(P):
    w, h, t, drop = BLADE["w"], BLADE["h"], BLADE["t"], BLADE["drop"]
    yc = -drop - h / 2
    out = np.zeros(len(P), bool)
    for s in (-1, 1):
        z = s * (t / 2)
        face = np.abs(P[:, 2] - z) < 0.003
        right = np.array([-1.0, 0, 0]) if s < 0 else np.array([1.0, 0, 0])
        # reading left to right on this face: ← QUAIS A - F | SORTIE → ; TAXIS under SORTIE
        left_end = -right * (w / 2)
        words = lettering.mask(P, "QUAIS A - F", (left_end + right * 0.55 + (0, yc, z)).astype(np.float32), 0.075, right, (0, 1, 0), weight=1.3)
        words |= lettering.mask(P, "SORTIE", (-left_end - right * 0.47 + (0, yc + 0.06, z)).astype(np.float32), 0.085, right, (0, 1, 0), weight=1.3)
        words |= lettering.mask(P, "TAXIS", (-left_end - right * 0.47 + (0, yc - 0.10, z)).astype(np.float32), 0.055, right, (0, 1, 0), weight=1.2)
        words |= _arrow(P, (left_end + right * 0.06 + (0, yc, z)), -1, 0.10, right, (0, 1, 0))
        words |= _arrow(P, (-left_end - right * 0.06 + (0, yc + 0.03, z)), 1, 0.10, right, (0, 1, 0))
        out |= words & face
    return out


def _paint_blade(P, N, tag, tags, state, col):
    sel = tag == tags.index("blue")
    return np.where((_blade_marks(P) & sel)[:, None], np.array([0.93, 0.93, 0.91], np.float32), col)


_SPEC = dict(states=["clean", "abandoned", "damaged", "burnt"], lods=3)

ELEMENTS = {
    "departure_board": dict(build=departure_board, materials=materials(), extra=_paint_board, extra_first=True, emit_where=_emit_board,
                            uv_scale={"led": 3.0}, edge_radius=0.004, close=(0.0, -1.6, -0.1), **_SPEC),
    "quay_sign": dict(build=quay_sign, materials=materials(), extra=_paint_quay, extra_first=True, uv_scale={"face": 2.0},
                      edge_radius=0.004, close=(0.0, 2.3, -0.1), **_SPEC),
    "wayfinding_sign": dict(build=wayfinding_sign, materials=materials(), extra=_paint_blade, extra_first=True, uv_scale={"blue": 2.0},
                            edge_radius=0.003, close=(0.0, -0.8, -0.05), **_SPEC),
}
