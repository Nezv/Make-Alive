"""Posters, flyers and painted words (S186). Card and references: references/elements/decals.md; the
workflow: references/elements/WORKFLOW.md.

decals: a plaster wall panel dressed with what the dead town's walls carry: sprayed QUARANTAINE,
NE PAS ENTRER, MORTS À L'INTÉRIEUR and an arrow to ZONE SÛRE, DISPARU flyers held by tape, an
AVIS À LA POPULATION with the town's (invented) arms, an old election poster pasted in layers, and
DÉFENSE D'AFFICHER painted on a white band. All of it is paint by position on a thin slab, so
the game can stamp the same sheets on any wall (`PropModel.multimesh`) and the wear (rain fading,
sun bleaching, paint over paint) is the kit's, the same as on the wall behind.

Coordinates: metres, Y up, the wall's face is the plane z = 0.0 seen from -Z, x = 0 the middle,
the foot is y = 0. The panel is the size of a house wall's bay.
"""
import numpy as np

import lettering
import shapes as S
from poly import Mesh
from props import Material, Part

W, H, D = 4.0, 2.6, 0.16        # the panel: width, height, thickness (the card)


def materials():
    return {"plaster": Material((0.72, 0.68, 0.60), kind="plaster", chip=0.0, rusts=False, grain=0.08)}


def _slab(lod):
    m = Mesh()
    if lod >= 2:  # 300 m away it is a flat card
        base = m.add([(-W / 2, 0, 0), (-W / 2, H, 0), (W / 2, H, 0), (W / 2, 0, 0)])
        m.face([base, base + 1, base + 2, base + 3], "plaster")
        return m
    if lod == 1:
        m.merge(S.box((0, H / 2, -D / 2), (W / 2, H / 2, D / 2), "plaster"))
        return m
    m.merge(S.chamfer_box((0, H / 2, -D / 2), (W / 2, H / 2, D / 2), 0.02, "plaster", edges="front"))
    return m


def decals_element(lod):
    return {"body": Part(_slab(lod))}


# What goes where: world x (the reader's right is -x), y, and the size of the thing. Seeds pick
# the paper and the hand. Words are French and invented where they name anyone.
def _decals():
    z = -D                     # the slab's front face
    return [
        # the old election poster, two layers: the second pasted over a corner of the first
        {"kind": "poster", "at": (1.28, 1.40, z), "size": (0.62, 0.86), "seed": 4,
         "text": ["VOTEZ", "UNION DU PEUPLE", "DIMANCHE", "AU SCRUTIN"]},
        {"kind": "poster", "at": (1.0, 1.05, z), "size": (0.5, 0.7), "seed": 2,
         "text": ["ÉLECTIONS", "COMMUNALES", "LISTE DU", "RENOUVEAU"]},
        # the official notice
        {"kind": "poster", "at": (0.12, 1.50, z), "size": (0.42, 0.58), "seed": 0,
         "text": ["AVIS", "À LA POPULATION", "LES HABITANTS SONT", "PRIÉS DE REJOINDRE", "LA ZONE SÛRE",
                  "PAR ORDRE DU MAIRE"]},
        # missing people, each held by its own tape
        {"kind": "poster", "at": (-0.52, 1.32, z), "size": (0.21, 0.30), "seed": 3,
         "text": ["DISPARU", "MARIE 7 ANS", "VUE LE 12", "PRIÈRE D'APPELER"]},
        {"kind": "poster", "at": (-0.82, 1.0, z), "size": (0.21, 0.30), "seed": 5,
         "text": ["DISPARU", "M. LEGRAND", "62 ANS", "TÉLÉPHONER"]},
        {"kind": "poster", "at": (-0.34, 0.92, z), "size": (0.18, 0.26), "seed": 1,
         "text": ["DISPARUE", "LUCIE", "19 ANS"]},
        # sprayed words
        {"kind": "graffiti", "at": (-1.30, 1.88, z), "size": (1.2, 0.34), "text": "QUARANTAINE", "seed": 2, "colour": 1},
        {"kind": "graffiti", "at": (1.05, 2.12, z), "size": (1.4, 0.28), "text": "NE PAS ENTRER", "seed": 5, "colour": 0},
        {"kind": "graffiti", "at": (0.70, 0.45, z), "size": (1.9, 0.30), "text": "MORTS À L'INTÉRIEUR", "seed": 7, "colour": 0},
        {"kind": "graffiti", "at": (-1.30, 0.55, z), "size": (1.0, 0.24), "text": "ZONE SÛRE", "seed": 9, "colour": 2},
    ]


# --- painted by position: the white band, the arms, the tape, the arrow -------------------------------

def _paint(P, N, tag, tags, state, col):
    front = N[:, 2] < -0.5
    on = (tag == tags.index("plaster")) & front

    # DÉFENSE D'AFFICHER: a white band at the top, black letters, a hand painted them
    band = on & (np.abs(P[:, 0] + 0.1) < 1.00) & (np.abs(P[:, 1] - 2.38) < 0.13)  # the words are 1.84 m
    white = np.array([0.82, 0.80, 0.74], np.float32)
    col = np.where(band[:, None], white * (0.97 + 0.03 * np.sin(P[:, 0] * 40)[:, None]), col)
    ink = lettering.mask(P, "DÉFENSE D'AFFICHER", (-0.1, 2.38, 0.0), 0.12, (-1, 0, 0), (0, 1, 0), weight=1.15) & band
    col = np.where(ink[:, None], np.array([0.07, 0.06, 0.06], np.float32), col)

    # the arms on the official notice (centre (0.12, 1.50), top of the sheet at 1.79): a shield, a tower, bars
    cx, cy = 0.12, 1.69
    u, v = -(P[:, 0] - cx), P[:, 1] - cy        # u to the reader's right
    shield = on & (np.abs(u) < 0.035 * (1.0 - np.clip(-v / 0.06, 0, 1) * 0.6)) & (v > -0.055) & (v < 0.04)
    arms = np.array([0.10, 0.19, 0.45], np.float32)
    col = np.where(shield[:, None], arms, col)
    tower = shield & (np.abs(u) < 0.016) & (v > -0.012) & (v < 0.03)
    col = np.where(tower[:, None], np.array([0.82, 0.62, 0.20], np.float32), col)
    bars = shield & (v < -0.015) & (v > -0.045) & (np.abs(np.sin((u + v) * 150)) > 0.8)
    col = np.where(bars[:, None], np.array([0.86, 0.86, 0.82], np.float32), col)

    # tape: a strip across the top corners of each flyer, yellowed, a little see-through
    tape = np.zeros(len(P), bool)
    for fx, fy, w, h in ((-0.52, 1.32, 0.21, 0.30), (-0.82, 1.0, 0.21, 0.30), (-0.34, 0.92, 0.18, 0.26)):
        for sx in (-1, 1):
            cx_, cy_ = fx + sx * (w / 2 - 0.02), fy + h / 2 - 0.005
            tape |= (np.abs(P[:, 0] - cx_) < 0.035) & (np.abs(P[:, 1] - cy_) < 0.012)
    tape &= on
    col = np.where(tape[:, None], col * 0.35 + np.array([0.62, 0.55, 0.30], np.float32) * 0.65, col)

    # the arrow to the safe zone: a painted arrow, shaft and head, under the ZONE SÛRE
    ax, ay = -1.30, 0.28
    u2, v2 = -(P[:, 0] - ax), P[:, 1] - ay
    shaft = on & (np.abs(v2) < 0.012) & (np.abs(u2) < 0.34)
    head = on & (u2 > 0.20) & (u2 < 0.40) & (np.abs(v2) < (0.40 - u2) * 0.8)
    col = np.where((shaft | head)[:, None], np.array([0.10, 0.20, 0.55], np.float32), col)
    if state == "burnt":
        sooty = np.array([0.05, 0.045, 0.04], np.float32)
        col = np.where((band | shield | tape)[:, None], col * 0.3 + sooty * 0.7, col)
    return col


ELEMENTS = {
    "decals": {
        "build": decals_element,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.01,
        "decals": _decals(),
        "extra": _paint,
        "close": (0.0, 1.4, 0.0),  # the middle of the wall of them
        "tex": 2048,
    },
}
