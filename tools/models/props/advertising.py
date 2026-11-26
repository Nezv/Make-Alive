"""Advertising furniture (S171). Cards and references: references/elements/<name>.md; the workflow:
references/elements/WORKFLOW.md.

ad_column: the colonne Morris, the dark green cast-iron advertising column of Paris
(references/elements/ad_column/): a bulging foot with a beaded ring and raised panels, the drum
the posters are pasted round (three fluted stiles, the service door on the back), an octagonal
cornice whose frieze reads SPECTACLES / THÉÂTRES with lion masks on the corners and the town's
arms, a scale-covered onion dome with a scalloped fringe, and a finial.

Coordinates: metres, Y up, the front is -Z, x = 0 the axis. Standing on y = 0.
"""
import numpy as np

import shapes as S
from poly import Mesh
from props import Material, Part

# --- ad_column (the card: measured on paris16_717 / observatoire, 1.2 m drum taken as the scale) ---
FOOT_R, BASE_TOP = 0.70, 0.64     # the foot's radius, where the posters start
DRUM_R, DRUM_TOP = 0.60, 2.44     # the posters' cylinder
CORNICE_R = 0.73                  # the cornice's corner radius (the octagon's corners)
FRIEZE = (2.44, 2.74)             # cornice's underside, its top
DOME_TOP = 3.20                   # the dome's crown, under the finial
TOP = 3.50                        # the finial's tip
STILES = 3                        # fluted uprights between the poster panels
SHEET_H = 0.9                     # a poster sheet's height (two courses round the drum)
SHEETS = 8                        # sheets round each course
ARMS_Y = 2.60


def materials():
    green = (0.055, 0.17, 0.10)
    return {
        "iron": Material(green, under=(0.45, 0.16, 0.10), bare=(0.30, 0.17, 0.09), chip=0.45, grain=0.06),
        "letter": Material((0.07, 0.21, 0.12), under=(0.45, 0.16, 0.10), bare=(0.30, 0.17, 0.09), chip=0.8, grain=0.05),
        "poster": Material((0.80, 0.77, 0.68), kind="paper", chip=0.0, rusts=False, grain=0.04, fades=False),
        "door": Material(green, under=(0.45, 0.16, 0.10), bare=(0.30, 0.17, 0.09), chip=1.3, grain=0.07, fixing=True),
    }


def _sides(lod, s0):
    return max(8, [s0, s0 // 2, s0 // 4][lod])


def _base(lod):
    """The foot: a plinth, a sloping shoulder with twelve raised panels, a bulging beaded ring under the posters."""
    sides = _sides(lod, 48)
    beads = lod == 0

    def bead(j, y):  # the ring's beads, one every other point
        return 1.025 if beads and j % 2 and 0.545 < y < 0.60 else 1.0

    r = FOOT_R
    prof = [(0.0, r), (0.07, r), (0.08, r * 0.96), (0.11, r * 0.94), (0.14, r * 0.915), (0.50, r * 0.90),
            (0.52, r * 0.94), (0.555, r * 0.965), (0.60, r * 0.965), (0.615, r * 0.90), (BASE_TOP - 0.02, r * 0.86),
            (BASE_TOP - 0.01, DRUM_R + 0.04), (BASE_TOP, DRUM_R + 0.02)]
    if lod >= 2:
        prof = [prof[i] for i in (0, 2, 5, 8, 10, 12)]
    m = S.lathe(prof, sides, flute=bead, turn=np.pi / sides, tag="iron")
    if lod == 0:  # the raised panels on the shoulder, each a chamfered tablet
        tab = S.chamfer_box((0.0, 0.31, -r * 0.90 - 0.005), (0.075, 0.17, 0.016), 0.012, "iron", edges="front")
        m.merge(S.array_radial(tab, 12, start=np.pi / 12))
    return m


def _drum(lod):
    """The posters' cylinder with an iron ring at each end."""
    sides = _sides(lod, 48)
    r = DRUM_R
    prof = [(BASE_TOP - 0.005, r + 0.025, "iron"), (BASE_TOP + 0.02, r + 0.025, "iron"), (BASE_TOP + 0.03, r, "poster"),
            (DRUM_TOP - 0.05, r, "poster"), (DRUM_TOP - 0.04, r + 0.025, "iron"), (DRUM_TOP, r + 0.025, "iron")]
    return S.lathe(prof, sides, turn=np.pi / sides, tag="poster", caps=(False, False))


def _stile(lod):
    """A fluted upright standing proud of the drum: a flat with a rib down each side and a groove between."""
    h0, h1 = BASE_TOP + 0.03, DRUM_TOP - 0.05
    cz = -(DRUM_R + 0.012)
    m = S.chamfer_box((0.0, (h0 + h1) / 2, cz), (0.055, (h1 - h0) / 2, 0.022), 0.008, "iron", edges="vertical")
    if lod == 0:
        for x in (-0.028, 0.0, 0.028):
            m.merge(S.chamfer_box((x, (h0 + h1) / 2, cz - 0.022), (0.009, (h1 - h0) / 2 - 0.01, 0.008), 0.003, "iron", edges="vertical"))
    return m


def _stiles(lod):
    out = Mesh()
    # one on each side of the front and one at the back would hide the door: put them at 60, 180, 300 degrees
    for k in range(STILES):
        ang = np.pi / 3 + k * 2 * np.pi / STILES
        out.merge(_stile(lod).transformed(S.rotation((0, 1, 0), ang)))
    return out


def _door(lod):
    """The service door on the back: a raised panel with a keyhole plate and two hinges, no posters on it."""
    m = Mesh()
    cz = DRUM_R + 0.03
    top, bot = 2.20, 0.95
    cy = (top + bot) / 2
    m.merge(S.chamfer_box((0.0, cy, cz), (0.27, (top - bot) / 2, 0.014), 0.008, "door", edges="not_bottom"))
    if lod == 0:
        m.merge(S.chamfer_box((0.0, cy, cz + 0.016), (0.21, (top - bot) / 2 - 0.06, 0.006), 0.004, "door"))
        m.merge(S.prism((0.15, cy, cz + 0.02), 0.022, 0.012, 12, tag="door", axis=(0, 0, 1)))  # the lock's escutcheon
        for y in (bot + 0.18, top - 0.18):
            m.merge(S.prism((-0.25, y, cz + 0.014), 0.016, 0.014, 8, tag="door", axis=(0, 0, 1)))  # hinge knuckles
        m.merge(S.prism((0.15, cy, cz + 0.03), 0.007, 0.006, 6, tag="door", axis=(0, 0, 1)))
    return m


def _cornice(lod):
    """The octagonal cornice: a bracketed underside, the frieze (tilted out), a moulded top."""
    r = CORNICE_R
    y0, y1 = FRIEZE
    rr = lambda f: r * f                      # noqa: E731
    prof = [(y0, rr(0.80)), (y0 + 0.03, rr(0.88)), (y0 + 0.07, rr(0.94)), (y0 + 0.09, rr(0.96)),
            (y0 + 0.11, rr(0.955)), (y1 - 0.12, rr(0.955), "iron"), (y1 - 0.10, rr(0.985)), (y1 - 0.06, rr(1.0)),
            (y1 - 0.02, rr(0.985)), (y1, rr(0.90))]
    if lod >= 2:
        prof = [prof[i] for i in (0, 2, 5, 7, 9)]
    m = S.lathe(prof, 8, turn=np.pi / 8, tag="iron", caps=(False, True))
    # the ring that holds the drum's top: the cornice sits on it
    m.merge(S.lathe([(y0 - 0.02, DRUM_R + 0.025), (y0 + 0.01, DRUM_R + 0.025)], _sides(lod, 48), tag="iron",
                    caps=(False, False)))
    return m


def _frieze_letters(lod):
    """SPECTACLES / THÉÂTRES in raised letters on the four faces that look front, back and sideways; on the
    others the lion masks. The octagon's flat k is at angle k * 45 degrees (0 = the front, -Z)."""
    m = Mesh()
    if lod > 0:
        return m
    y = (FRIEZE[0] + FRIEZE[1]) / 2 + 0.02
    words = {0: "SPECTACLES", 2: "THÉÂTRES", 4: "SPECTACLES", 6: "CONCERTS"}
    face_r = CORNICE_R * 0.955 * np.cos(np.pi / 8)   # the frieze flat's distance from the axis
    for k, word in words.items():
        a = k * np.pi / 4
        d = np.array([np.sin(a), 0.0, -np.cos(a)])         # outwards
        right = np.array([-np.cos(a), 0.0, -np.sin(a)])    # the reader's right, looking at the face
        import lettering
        m.merge(lettering.mesh(word, 0.10, 0.012, origin=d * (face_r - 0.004) + np.array([0, y, 0]), right=right,
                               up=(0, 1, 0), tag="letter", weight=1.1))
    return m


def _masks_and_arms(lod):
    """A lion's mask on each corner of the frieze (a boss with a brow and a muzzle) and the town's arms
    in a roundel on the front: a disc with a rim, a shield and a ship's hull."""
    m = Mesh()
    if lod > 1:
        return m
    y = (FRIEZE[0] + FRIEZE[1]) / 2 + 0.02
    rc = CORNICE_R * 0.955
    for k in range(8):
        a = (k + 0.5) * np.pi / 4
        d = np.array([np.sin(a), 0.0, -np.cos(a)])
        if k % 2 == 0 and lod == 0:  # corners between the lettered flats: only the four at 45, 135...
            pass
        c = d * (rc + 0.01) + np.array([0, y, 0])
        face = S.lathe([(0.0, 0.07), (0.02, 0.065), (0.045, 0.045), (0.06, 0.02), (0.065, 0.0)], 8, tag="iron")
        face = S.along(face, d, c)
        m.merge(face)
        if lod == 0:  # the brow and the muzzle
            f = np.array([-d[2], 0, d[0]])
            m.merge(S.box(c + d * 0.05 + np.array([0, 0.03, 0]), (0.045, 0.012, 0.012), "iron", basis=np.stack([f, [0, 1, 0], d], 1)))
            m.merge(S.box(c + d * 0.06 - np.array([0, 0.025, 0]), (0.03, 0.018, 0.016), "iron", basis=np.stack([f, [0, 1, 0], d], 1)))
    # the roundel on the front flat, under the lettering
    d = np.array([0.0, 0.0, -1.0])
    fr = CORNICE_R * 0.955 * np.cos(np.pi / 8)
    if lod == 0:
        disc = S.lathe([(0.0, 0.11), (0.012, 0.11), (0.012, 0.095), (0.022, 0.09), (0.03, 0.0)], 20, tag="iron")
        m.merge(S.along(disc, d, np.array([0.0, ARMS_Y - 0.19, -fr])))
    return m


def _dome(lod):
    """The onion dome: ribs up its eight faces and rows of scale tiles, the lowest a scalloped fringe."""
    sides = _sides(lod, 32)
    ribs = lod == 0

    def rib(j, y):
        return 1.035 if ribs and j % (sides // 8) == 0 and y < DOME_TOP - 0.1 else 1.0

    y0 = FRIEZE[1]
    r0 = CORNICE_R * 0.74
    prof = [(y0, r0), (y0 + 0.03, r0 * 1.02), (y0 + 0.12, r0 * 1.07), (y0 + 0.24, r0 * 1.0), (y0 + 0.33, r0 * 0.80),
            (y0 + 0.39, r0 * 0.52), (y0 + 0.44, r0 * 0.26), (DOME_TOP - 0.02, 0.10), (DOME_TOP, 0.07)]
    if lod >= 2:
        prof = [prof[i] for i in (0, 2, 4, 6, 8)]
    m = S.lathe(prof, sides, flute=rib, turn=np.pi / sides, tag="iron", caps=(False, True))
    if lod == 0:  # scale tiles, three rows (the first hangs over the rim as the fringe)
        rows = [(y0 + 0.06, r0 * 1.075, 24, 0.075), (y0 + 0.16, r0 * 1.04, 24, 0.07), (y0 + 0.25, r0 * 0.90, 20, 0.06)]
        for y, r, n, w in rows:
            scale = S.chamfer_box((0.0, y, -r), (w * 0.48, w * 0.55, 0.01), 0.008, "iron", edges="front")
            m.merge(S.array_radial(scale, n, start=np.pi / n if y > y0 + 0.1 else 0.0))
    return m


def _finial(lod):
    """The finial: a collar, a ball, a leaf-shaped swelling and the spike."""
    s = _sides(lod, 12)
    y = DOME_TOP - 0.02
    prof = [(y, 0.09), (y + 0.03, 0.095), (y + 0.05, 0.05), (y + 0.09, 0.045), (y + 0.11, 0.075), (y + 0.15, 0.085),
            (y + 0.19, 0.05), (y + 0.21, 0.025), (y + 0.26, 0.032), (y + 0.30, 0.012), (TOP, 0.0)]
    if lod >= 2:
        prof = [prof[i] for i in (0, 2, 5, 8, 10)]
    return S.lathe(prof, s, tag="iron")


def ad_column(lod):
    body = _base(lod)
    for piece in (_drum(lod), _stiles(lod), _door(lod), _cornice(lod), _frieze_letters(lod), _masks_and_arms(lod),
                  _dome(lod), _finial(lod)):
        body.merge(piece)
    return {"body": Part(body)}


# --- The posters: pasted by angle and height, painted where the bake reached the drum ------------------

PAPER = [(0.86, 0.83, 0.74), (0.88, 0.80, 0.55), (0.72, 0.80, 0.86), (0.90, 0.75, 0.72), (0.92, 0.90, 0.84),
         (0.80, 0.86, 0.74), (0.62, 0.30, 0.26), (0.20, 0.28, 0.45)]
HEADS = [["OPÉRA", "DE NUIT"], ["CONCERT", "SALLE LUCE"], ["LE CIRQUE", "DES ÉTOILES"], ["GRAND BAL", "SAMEDI"], ["MOLIÈRE", "MATINÉE"],
         ["AVIS", "AU PUBLIC"], ["CABARET", "20 H 30"], ["LA TRAVIATA", "NOUVEAU"]]


def _posters(P, N, tag, tags, state, col):
    import lettering
    import wear as W
    sel = tag == tags.index("poster")
    if not sel.any():
        return col
    # the drum's own colour behind a torn sheet: a dull green sheet-iron
    base = np.array([0.10, 0.16, 0.12], np.float32)
    ang = np.arctan2(P[:, 0], -P[:, 2])                      # 0 at the front, growing towards +X
    a01 = (ang / (2 * np.pi)) % 1.0
    y0, y1 = BASE_TOP + 0.03, DRUM_TOP - 0.05
    course = np.clip(((P[:, 1] - y0) / SHEET_H).astype(int), 0, 1)
    col_idx = np.floor((a01 + 0.5 * course / SHEETS) * SHEETS).astype(int) % SHEETS
    cid = course * SHEETS + col_idx
    out = col.copy()
    tear_amount = {"clean": 0.0, "abandoned": 0.55, "damaged": 0.30, "burnt": 0.2}[state]
    for c in range(2 * SHEETS):
        on = sel & (cid == c)
        if not on.any():
            continue
        paper = np.array(PAPER[(c * 3 + 1) % len(PAPER)], np.float32)
        idx = np.nonzero(on)[0]
        Q = P[idx]
        wob = W.fbm(Q * np.array([1, 0.3, 1], np.float32), 9.0, 2, 17 + c)
        shade = (0.92 + 0.12 * W.fbm(Q, 30.0, 2, 3 + c))[:, None]
        pcol = paper[None] * shade
        # a darker overpasted edge where the sheets meet
        v = (Q[:, 1] - y0) / SHEET_H - course[idx]
        edge = (v < 0.012) | (v > 0.985)
        pcol = np.where(edge[:, None], pcol * 0.7, pcol)
        # the headline and the small print
        a = ((c % SHEETS) + 0.5 - 0.5 * (c // SHEETS)) / SHEETS * 2 * np.pi
        d = np.array([np.sin(a), 0.0, -np.cos(a)], np.float32)
        right = np.array([-np.cos(a), 0.0, -np.sin(a)], np.float32)
        yc = y0 + (c // SHEETS) * SHEET_H + SHEET_H * 0.62
        ink = np.array([0.55, 0.07, 0.06], np.float32) if c % 3 == 0 else np.array([0.07, 0.06, 0.06], np.float32)
        if paper.sum() < 1.6:
            ink = np.array([0.92, 0.90, 0.84], np.float32)
        head, small = HEADS[c % len(HEADS)]
        rad = np.array([0.0, 0.0, 0.0], np.float32) + d * DRUM_R
        fit = 0.36  # a sheet is 0.47 wide round the drum: the type stays inside it
        h1 = min(0.12, fit / max(lettering.width(head, 1.0), 1e-3))
        h2 = min(0.06, fit / max(lettering.width(small, 1.0), 1e-3))
        m1 = lettering.mask(Q, head, rad + np.array([0, yc, 0], np.float32), h1, right, (0, 1, 0), weight=1.1)
        m2 = lettering.mask(Q, small, rad + np.array([0, yc - 0.17, 0], np.float32), h2, right, (0, 1, 0), weight=0.9)
        facing = (Q @ d) > 0
        pcol = np.where(((m1 | m2) & facing)[:, None], ink[None], pcol)
        # the lines of type under: short grey bars
        bars = (np.abs(((Q[:, 1] - yc + 0.36) * 40) % 1.0 - 0.5) < 0.22) & ((Q[:, 1] - yc) < -0.30) & ((Q[:, 1] - yc) > -0.62)
        along = np.abs(Q @ right) < 0.12 * (0.7 + 0.3 * np.sin(np.floor((Q[:, 1] - yc) * 40) * 2.3 + c))
        pcol = np.where((bars & along & facing)[:, None], pcol * 0.55, pcol)
        # torn: the sheet missing in ragged patches, an older one under it, then the iron
        tear = wob > (1.0 - tear_amount * 0.9) - 0.5 * (v < 0.4)
        older = np.array(PAPER[(c * 3 + 4) % len(PAPER)], np.float32) * 0.8
        under = np.where((W.fbm(Q, 6.0, 2, 41 + c) > 0.52)[:, None], base[None], older[None] * shade)
        pcol = np.where(tear[:, None] & (tear_amount > 0), under, pcol)
        out[idx] = pcol
    if state in ("damaged", "abandoned"):
        # the quarantine notice over everything on the front, a red band across it
        centre = np.array([0.0, 1.55, -DRUM_R], np.float32)
        u = -(P[:, 0])
        vy = P[:, 1] - centre[1]
        sheet = sel & (np.abs(u) < 0.26) & (np.abs(vy) < 0.34) & (P[:, 2] < 0)
        out = np.where(sheet[:, None], np.array([0.93, 0.92, 0.88], np.float32), out)
        band = sheet & (vy > 0.14)
        out = np.where(band[:, None], np.array([0.62, 0.07, 0.06], np.float32), out)
        for text, dy, h in (("QUARANTAINE", 0.20, 0.055), ("AVIS A LA POPULATION", 0.04, 0.032), ("NE PAS ENTRER", -0.06, 0.032),
                            ("ZONE INTERDITE", -0.16, 0.032)):
            m = lettering.mask(P, text, centre + np.array([0, dy, 0], np.float32), h, (-1, 0, 0), (0, 1, 0), weight=1.0) & sheet
            out = np.where(m[:, None], (np.array([0.96, 0.94, 0.9], np.float32) if dy > 0.1 else np.array([0.08, 0.07, 0.07], np.float32)), out)
    # grime and the pasted paper's age at the foot of the drum
    foot = np.clip((y0 + 0.5 - P[:, 1]) / 0.5, 0, 1)[:, None] * 0.35 if state != "clean" else 0
    out = out * (1 - foot) + np.array([0.12, 0.10, 0.08], np.float32) * foot
    return np.where(sel[:, None], out, col)


ELEMENTS = {
    "ad_column": {
        "build": ad_column,
        "materials": materials(),
        "states": ["clean", "abandoned", "damaged", "burnt"],
        "lods": 3,
        "edge_radius": 0.006,
        "extra": _posters,
        "close": (0.0, 2.6, 0.0),  # the frieze, the lion masks and the dome's fringe
    },
}
