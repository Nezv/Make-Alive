"""The generic zombie body, no clothes: a male and a female, made of flat faces only (the look
of references/zombies.png). Outfits are meant to be built on it: clothes go over these pieces,
and they also hide where the pieces meet.

    tools\\blender.ps1 tools\\models\\body.py            -> assets/models/zombie_body_m.glb, zombie_body_f.glb
                                                          (+ _albedo.png, _emission.png), previews
    tools\\blender.ps1 tools\\models\\body.py --quick    -> shapes only, flat colours, previews
    python tools/models/body.py --sketch                -> references/shots/sketch_body.png in seconds,
                                                          no Blender (for shaping)

Every body part is its own closed piece riding one joint of the game's skeleton (head and neck,
upper arm, forearm with the hand, thigh, shin with the foot), and ends in a faceted ball round
its joint so bends stay closed. A severed part is a whole closed piece; the faces that only show
once it is off are wound, with a bone of tools/models/skeleton.py sticking out of them. The
shoulder is the torso's: a ledge sloping from the neck over the top of the arm, which starts
under it. The torso is two pieces, chest on the spine and pelvis on the hips, meeting along an
upside-down V: high in the middle of the belly, down to the hip joints' height at the sides,
where the spine's turn barely moves anything. The ring they share bends half and half, so the
break stays closed however far the zombie hunches.

Proportions and the face's layout come from tools/models/measured.json (tools/models/measure.py
reads them off the reference): the eyes' line, their gap, the low wide mouth, the head's
width to height; colours too. The skeleton is the game's (scripts/models/humanoid.gd): the
shoulders sit 0.33 m out, so the bodies are broad by build and their arms hang a little inside
the joints. Game coordinates: metres, Y up, facing -Z, the model's right is +X.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import numpy as np  # noqa: E402

from poly import Mesh, V, limb, tapered_block  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models")
SHOTS = os.path.join(ROOT, "references", "shots")
TEX = 1024

TORSO, HEAD, HAIR, UPPER_ARM, FOREARM, THIGH, SHIN, PELVIS = 1, 2, 3, 4, 5, 6, 7, 8
# What a face is, for the painter (baked like the piece number, a tenth each: ten at most + 1).
TAGS = ["skin", "eye", "socket", "mouth", "teeth", "lip", "hair", "brow", "wound", "nail", "bone"]
TAG = {name: i for i, name in enumerate(TAGS)}

# The game's joints at rest (Humanoid: HIP_HEIGHT, NECK_AT, SHOULDER_AT, ELBOW_AT, HIP_AT, KNEE_AT).
NECK = V(0, 1.56, 0)
SHOULDER = V(0.33, 1.50, 0)
ELBOW = V(0.33, 1.18, 0)
HIP = V(0.12, 0.92, 0)
KNEE = V(0.12, 0.47, 0)


def _measured():
    with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "measured.json")) as fh:
        return json.load(fh)


MEASURED = _measured()


def _m(key, lo, hi):
    """A measured proportion (median of the reference's zombies), kept within sane bounds."""
    v = MEASURED["summary"].get(key)
    return float(np.clip(v if v is not None else (lo + hi) / 2, lo, hi))


def _hex(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


# The face's layout, as fractions of the head (measured): where the eyes and mouth are.
LAYOUT = dict(
    aspect=_m("head_aspect", 0.72, 0.82),     # face width / head height
    eye_line=_m("eye_line", 0.5, 0.58),       # eyes' centre, down from the crown
    eye_gap=_m("eye_gap", 0.36, 0.44),        # between the eyes' centres / face width
    mouth_line=_m("mouth_line", 0.78, 0.84),  # mouth's centre, down from the crown
    mouth_w=_m("mouth_w", 0.3, 0.4),          # / face width
    mouth_h=_m("mouth_h", 0.11, 0.15),        # / head height
)

# --- The variants ---------------------------------------------------------------------------
# The reference's heads are a fifth of the figure in its picture; the game's head hitbox
# (0.3 m) keeps them nearer a sixth here. Hands are two thirds of a head, as measured.

MALE = dict(
    sex="m",
    head_h=0.33, chin_y=1.588, head_w=1.1, jaw=1.12, brow=1.0, nose=1.0, lips=0.0, eye=1.0,
    neck=(0.07, 0.068),
    # The arms hang this far inside the game's shoulder joints (0.33 out), so they rest
    # against the body as in the reference; the joints still turn them.
    arm_in=0.04, arm=1.0, hand=1.2,
    thigh=1.0, shin=1.0, foot=1.0,
    hair="short",
    # The torso's break: height at the sides (the hip joints'), rise in the middle of the
    # front and of the back, half width of the V.
    seam=(0.955, 0.115, 0.07, 0.19),
    # Torso rings, bottom up: y, centre front z, (x, z) of front, front corner, side, back
    # corner, centre back z. y may be ("seam", offset): following the break. Points may sit at
    # their own heights: dy per column (c0..c5). The ring at "seam" 0.0 is the break; the
    # shoulder ring's side point is the ledge's tip, out over the arm.
    torso=[
        (0.77, -0.05, (0.04, -0.05), (0.07, -0.03), (0.08, 0.0), (0.07, 0.04), 0.055),
        (0.86, -0.1, (0.09, -0.098), (0.165, -0.072), (0.198, 0.0), (0.165, 0.09), 0.115),
        (("seam", -0.055), -0.117, (0.09, -0.116), (0.172, -0.09), (0.207, -0.004), (0.172, 0.092), 0.112),
        (("seam", 0.0), -0.122, (0.09, -0.121), (0.172, -0.097), (0.205, -0.004), (0.168, 0.088), 0.102),
        (("seam", 0.085), -0.128, (0.092, -0.127), (0.172, -0.101), (0.203, -0.004), (0.168, 0.084), 0.096),
        (1.24, -0.133, (0.1, -0.135), (0.192, -0.107), (0.228, -0.002), (0.187, 0.096), 0.106),
        (1.35, -0.138, (0.105, -0.147), (0.205, -0.112), (0.243, 0.0), (0.2, 0.107), 0.117),
        (1.42, -0.13, (0.108, -0.138), (0.21, -0.106), (0.262, 0.006), (0.205, 0.11), 0.12),
        (1.5, -0.095, (0.105, -0.1), (0.25, -0.06), (0.358, 0.002), (0.24, 0.072), 0.104,
         (-0.005, 0.028, 0.022, -0.036, 0.028, 0.04)),
        (1.585, -0.05, (0.045, -0.05), (0.078, -0.028), (0.09, 0.012), (0.072, 0.06), 0.076,
         (-0.035, -0.03, -0.018, -0.006, 0.008, 0.014)),
    ],
)

FEMALE = dict(
    MALE,
    sex="f",
    head_h=0.315, chin_y=1.584, head_w=1.04, jaw=0.94, brow=0.8, nose=0.8, lips=0.006, eye=1.1,
    neck=(0.056, 0.054),
    arm_in=0.062, arm=0.8, hand=1.04,
    thigh=1.0, shin=0.9, foot=0.9,
    hair="bob",
    seam=(0.955, 0.11, 0.065, 0.18),
    torso=[
        (0.77, -0.05, (0.04, -0.05), (0.07, -0.03), (0.08, 0.0), (0.07, 0.045), 0.06),
        (0.86, -0.1, (0.09, -0.097), (0.175, -0.074), (0.212, 0.0), (0.18, 0.105), 0.13),
        (("seam", -0.055), -0.106, (0.09, -0.106), (0.178, -0.088), (0.216, -0.005), (0.178, 0.098), 0.12),
        (("seam", 0.0), -0.103, (0.085, -0.103), (0.165, -0.086), (0.205, -0.005), (0.168, 0.09), 0.108),
        (("seam", 0.085), -0.1, (0.072, -0.1), (0.138, -0.084), (0.168, -0.005), (0.138, 0.07), 0.082),
        (1.2, -0.106, (0.076, -0.108), (0.146, -0.089), (0.178, -0.005), (0.146, 0.076), 0.086),
        (1.27, -0.116, (0.085, -0.12), (0.16, -0.096), (0.195, -0.002), (0.16, 0.085), 0.095),
        (1.34, -0.126, (0.082, -0.156), (0.165, -0.118), (0.2, 0.0), (0.165, 0.09), 0.1),
        (1.41, -0.115, (0.085, -0.125), (0.175, -0.095), (0.225, 0.004), (0.175, 0.096), 0.104),
        (1.495, -0.086, (0.09, -0.09), (0.225, -0.056), (0.328, 0.002), (0.215, 0.07), 0.094,
         (-0.005, 0.028, 0.022, -0.04, 0.028, 0.04)),
        (1.58, -0.042, (0.036, -0.042), (0.062, -0.024), (0.072, 0.008), (0.058, 0.05), 0.064,
         (-0.03, -0.026, -0.016, -0.005, 0.008, 0.014)),
    ],
)
VARIANTS = {"m": MALE, "f": FEMALE}


# --- Torso ------------------------------------------------------------------------------------

def seam_y(x, z, p):
    """Height of the torso's break at (x, z): an upside-down V, highest in the middle of the
    belly (a little at the back too), down to the hip joints' height at the sides."""
    side, front, back, half = p["seam"]
    f = np.clip(1.0 - np.abs(x) / half, 0.0, 1.0)
    return side + f * (front * np.clip(-z / 0.06, 0.0, 1.0) + back * np.clip(z / 0.06, 0.0, 1.0))


def torso(p):
    """(chest, pelvis): two pieces sharing the ring of the break, open to each other there, so
    together they are one closed surface."""
    rings, at = [], None
    for i, st in enumerate(p["torso"]):
        y, z0, c1, c2, c3, c4, z5 = st[:7]
        dy = st[7] if len(st) > 7 else (0.0,) * 6
        cols = [(0.0, z0), c1, c2, c3, c4, (0.0, z5)]
        if isinstance(y, tuple):
            ys = [seam_y(x, z, p) + y[1] for x, z in cols]
            if y[1] == 0.0:
                at = i
        else:
            ys = [y] * 6
        half = [(x, ys[k] + dy[k], z) for k, (x, z) in enumerate(cols)]
        ring = half + [(-x, yy, z) for x, yy, z in reversed(half[1:5])]
        rings.append(ring)
    chest, pelvis = Mesh(), Mesh()
    pelvis.loft(rings[:at + 1], "skin", caps=(True, False))
    chest.loft(rings[at:], "skin", caps=(False, True))
    return chest, pelvis


# --- Head -------------------------------------------------------------------------------------
# A head is rings of 16 points round it: the front of the face (F0 in the middle, F1..F4 out to
# its corner), the side (S1 before the ear, S2 behind it), the back (B1, B0). The face's
# features are those points moved: the socket pushed in, a brow that overhangs it in a V (low
# over the nose, high at the temples: the angry look), a wedge of a nose, a mouth sunk into
# the jaw with its corners dragged down, a square jaw. Designed at 0.32 m, scaled to the head.

# Columns of the right half; the left mirrors them. Index of the face between point j and j+1.
F0, F1, F2, F3, F4, S1, S2, B1, B0 = range(9)
MOUTH_BANDS = {0, 1, 14, 15}
SOCKET_BANDS = {1, 2, 13, 14}


def _full(half):
    """Nine points of the right half (F0..B0) to the 16 of a ring, going round the same way."""
    left = [(-x, y, z) for x, y, z in reversed(half[1:8])]
    return list(half) + left


def head_layout(p):
    """Heights (above the chin) and widths of the face's features, from the measured layout."""
    H = 0.32  # the design size; everything is scaled to p["head_h"] at the end
    W = LAYOUT["aspect"] * H
    t_eye = (1.0 - LAYOUT["eye_line"]) * H
    t_mouth = (1.0 - LAYOUT["mouth_line"]) * H
    mh = LAYOUT["mouth_h"] * H
    return dict(H=H, W=W, t_eye=t_eye, ex=LAYOUT["eye_gap"] * W / 2,
                t_ll=t_mouth - mh / 2, t_lh=t_mouth + mh / 2, mw=LAYOUT["mouth_w"] * W / 2)


def _skull_side(t):
    """The side and back columns (S1, S2, B1, B0) at height t: interpolated, faceted."""
    sx = np.interp(t, [0, 0.06, 0.12, 0.18, 0.24, 0.28, 0.302, 0.32],
                   [0.098, 0.108, 0.121, 0.127, 0.126, 0.118, 0.104, 0.072])
    s1z = np.interp(t, [0, 0.12, 0.25, 0.32], [-0.012, -0.016, -0.02, -0.004])
    s2z = np.interp(t, [0, 0.12, 0.25, 0.32], [0.05, 0.07, 0.078, 0.056])
    b0z = np.interp(t, [0.11, 0.17, 0.23, 0.27, 0.302, 0.32], [0.096, 0.126, 0.142, 0.14, 0.12, 0.088])
    return sx, s1z, s2z, b0z


def head_rings(p):
    L = head_layout(p)
    t_e, ex, t_ll, t_lh, mw = L["t_eye"], L["ex"], L["t_ll"], L["t_lh"], L["mw"]
    jaw, brow, nose = p["jaw"], p["brow"], p["nose"]
    lips = p["lips"]
    # name, t, front points F0..F4 as (x, z, dt) (dt: that point's own height offset)
    front = [
        ("jaw", 0.0, [(0, -0.112, 0), (0.024, -0.11, 0), (0.047 * jaw, -0.102, 0), (0.07 * jaw, -0.086, 0),
                      (0.088 * jaw, -0.058, 0)]),
        ("chin", t_ll - 0.012, [(0, -0.127, 0), (0.025, -0.125, 0), (0.05 * jaw, -0.117, 0),
                                (0.08 * jaw, -0.099, 0), (0.1 * (0.5 + 0.5 * jaw), -0.07, 0)]),
        # the mouth: an arch, both edges dragged down at the corners (a snarl, never a grin)
        ("lip_lo", t_ll, [(0, -0.13 - lips, 0), (0.024, -0.128 - lips, -0.001), (mw + 0.004, -0.12, -0.009),
                          (0.086, -0.104, 0.0), (0.106, -0.076, 0.006)]),
        ("mouth_lo", t_ll + 0.004, [(0, -0.094, 0), (0.022, -0.094, -0.001), (mw - 0.002, -0.099, -0.006),
                                    (0.088, -0.106, 0.012), (0.108, -0.077, 0.018)]),
        ("mouth_hi", t_lh - 0.003, [(0, -0.096, 0.004), (0.022, -0.096, 0.002), (mw - 0.008, -0.1, -0.012),
                                    (0.09, -0.107, 0.0), (0.11, -0.078, 0.004)]),
        ("lip_hi", t_lh, [(0, -0.135 - lips, 0.007), (0.023, -0.133 - lips, 0.004), (mw - 0.006, -0.124, -0.012),
                          (0.092, -0.108, 0.004), (0.112, -0.079, 0.008)]),
        ("nose_lo", t_lh + 0.016, [(0, -0.142 - 0.008 * nose, 0), (0.016, -0.143, 0), (0.05, -0.128, 0),
                                   (0.094, -0.11, 0), (0.115, -0.08, 0)]),
        ("nose_tip", t_lh + 0.028, [(0, -0.142 - 0.026 * nose, 0), (0.017 * nose, -0.147, 0),
                                    (0.052, -0.13, 0), (0.097, -0.115, 0), (0.118, -0.082, 0)]),
        ("cheek", t_e - 0.024, [(0, -0.142 - 0.016 * nose, 0), (0.019, -0.142, 0), (0.052, -0.134, 0),
                                (0.1, -0.123, 0), (0.121, -0.085, 0)]),
        ("socket_lo", t_e - 0.011, [(0, -0.142 - 0.01 * nose, 0), (0.021, -0.14, 0), (ex, -0.12, 0),
                                    (ex + 0.036, -0.126, 0.002), (0.123, -0.088, 0)]),
        ("socket_hi", t_e + 0.008, [(0, -0.142 - 0.008 * nose, -0.004), (0.021, -0.139, -0.004),
                                    (ex, -0.118, 0.0), (ex + 0.036, -0.124, 0.008), (0.124, -0.09, 0.006)]),
        ("brow", t_e + 0.018, [(0, -0.146 - 0.004 * brow, -0.007), (0.02, -0.142 - 0.014 * brow, -0.004),
                               (ex, -0.14 - 0.016 * brow, 0.004), (ex + 0.038, -0.136 - 0.014 * brow, 0.013),
                               (0.124, -0.1, 0.016)]),
        ("brow_top", t_e + 0.034, [(0, -0.142, -0.003), (0.022, -0.146, 0), (ex, -0.146, 0.003),
                                   (ex + 0.038, -0.14, 0.009), (0.123, -0.1, 0.01)]),
        ("fore", t_e + 0.07, [(0, -0.138, 0), (0.026, -0.138, 0), (0.058, -0.135, 0), (0.092, -0.126, 0),
                              (0.118, -0.096, 0)]),
        ("fore_hi", L["H"] - 0.055, [(0, -0.126, 0), (0.026, -0.126, 0), (0.058, -0.123, 0), (0.09, -0.115, 0),
                                     (0.112, -0.088, 0)]),
        ("top", L["H"] - 0.018, [(0, -0.095, 0), (0.026, -0.095, 0), (0.055, -0.092, 0), (0.08, -0.085, 0),
                                 (0.095, -0.066, 0)]),
        ("crown", L["H"], [(0, -0.06, 0), (0.024, -0.06, 0), (0.045, -0.058, 0), (0.06, -0.052, 0),
                           (0.07, -0.04, 0)]),
    ]
    rings = []
    for name, t, pts in front:
        half = []
        for k, (x, z, dt) in enumerate(pts):
            floor = (t, max(t, 0.016 + 0.85 * t), max(t, 0.016 + 0.85 * t), max(t, 0.016 + 0.85 * t),
                     max(t, 0.04 + 0.75 * t))[k] if k >= 3 else t
            half.append((x, floor + dt, z))
        ts = [max(t, 0.065 + 0.6 * t), max(t, 0.09 + 0.55 * t), max(t, 0.108 + 0.5 * t), max(t, 0.112 + 0.5 * t)]
        if name == "crown":
            ts = [t, t, t, t]
        sx, s1z, _, _ = _skull_side(ts[0])
        half.append((sx, ts[0], s1z))
        sx2, _, s2z, _ = _skull_side(ts[1])
        half.append((0.96 * sx2, ts[1], s2z))
        sx3, _, _, b0z3 = _skull_side(ts[2])
        half.append((0.68 * sx3, ts[2], b0z3 - 0.026))
        _, _, _, b0z = _skull_side(ts[3])
        half.append((0.0, ts[3], b0z))
        rings.append((name, _full(half)))
    return rings, L


def _to_head(points, p):
    """Design units (0.32 m head, chin at 0, neck axis at z = 0) to the model's space."""
    P = np.array(points, dtype=np.float64)
    s = p["head_h"] / 0.32
    P = P * np.array([s * p["head_w"], s, s])
    P[..., 1] += p["chin_y"]
    return P


def head(p):
    rings, L = head_rings(p)
    names = [n for n, _ in rings]
    i_lip_lo, i_mouth_hi = names.index("lip_lo"), names.index("mouth_hi")
    i_sock_lo, i_sock_hi, i_brow = names.index("socket_lo"), names.index("socket_hi"), names.index("brow")
    i_chin, i_nose_lo = names.index("chin"), names.index("nose_lo")

    def tag(r, j):
        if j in MOUTH_BANDS:
            if i_lip_lo <= r <= i_mouth_hi:
                return "mouth"
            if r == i_chin or r == i_mouth_hi + 1:
                return "lip"
        if j in SOCKET_BANDS and i_sock_lo - 1 <= r <= i_sock_hi:
            return "socket"
        if j in {1, 2, 13, 14} and r == i_brow:
            return "brow"
        return None

    m = Mesh()
    m.loft([_to_head(r, p) for _, r in rings], "skin", band_tags=tag)
    # Eyes: slanted slits in the sockets, lower at the nose (the brow presses on them).
    t_e, ex = L["t_eye"], L["ex"]
    e = p["eye"]
    for s in (1.0, -1.0):
        zf, zb = -0.124, -0.11
        face = [(ex - 0.015 * e, t_e - 0.006 * e, zf), (ex + 0.014 * e, t_e - 0.007 * e, zf),
                (ex + 0.016 * e, t_e + 0.008 * e, zf), (ex - 0.016 * e, t_e + 0.0005 * e, zf)]
        back = [(x, y, zb) for x, y, _ in face]
        lo = [(s * x, y, z) for x, y, z in face]
        hi = [(s * x, y, z) for x, y, z in back]
        if s < 0:
            lo, hi = lo[::-1], hi[::-1]
        eye = Mesh().block(_to_head(lo, p), _to_head(hi, p), "eye")
        m.merge(eye)
    # Teeth: a broken row hanging from the roof of the mouth, a shorter one on its floor.
    mw, t_ll, t_lh = L["mw"], L["t_ll"], L["t_lh"]
    tops = [0.013, 0.015, 0.0, 0.012, 0.016, 0.011]
    for k, h in enumerate(tops):
        if h <= 0:
            continue
        x = -mw + 0.012 + k * (2 * mw - 0.024) / (len(tops) - 1)
        a = (x, t_lh + 0.002, -0.114)
        b = (x, t_lh - 0.003 - h, -0.116)
        m.merge(_tooth(a, b, p))
    bottoms = [0.009, 0.0, 0.011, 0.01, 0.008]
    for k, h in enumerate(bottoms):
        if h <= 0:
            continue
        x = -mw + 0.014 + k * (2 * mw - 0.028) / (len(bottoms) - 1)
        a = (x, t_ll + 0.0, -0.112)
        b = (x, t_ll + 0.004 + h, -0.113)
        m.merge(_tooth(a, b, p))
    # Ears: wedges on the sides.
    for s in (1.0, -1.0):
        inner = [(0.112, t_lh + 0.012, -0.014), (0.112, t_lh + 0.012, 0.026), (0.112, t_e + 0.022, 0.034),
                 (0.112, t_e + 0.022, -0.016)]
        outer = [(0.136, t_lh + 0.022, -0.004), (0.136, t_lh + 0.022, 0.026), (0.138, t_e + 0.016, 0.036),
                 (0.138, t_e + 0.016, -0.004)]
        lo = [(s * x, y, z) for x, y, z in inner]
        hi = [(s * x, y, z) for x, y, z in outer]
        if s < 0:
            lo, hi = lo[::-1], hi[::-1]
        m.merge(Mesh().block(_to_head(lo, p), _to_head(hi, p), "skin"))
    # Neck: from inside the torso up into the head; its foot is the wound when the head goes.
    s = p["head_h"] / 0.32
    nx, nz = p["neck"]
    top = V(0, p["chin_y"] + 0.11 * s, 0.006)
    m.merge(limb(top, V(0, 1.46, 0.016), [(0.0, nx * 0.9, nz * 0.9), (0.06, nx, nz), (top[1] - 1.5, nx * 1.04, nz * 1.04),
                                          (top[1] - 1.46, 0, 0)], sides=8, turn=np.pi / 8,
                 cap_tags=(None, "wound")))
    return m


def _tooth(a, b, p):
    """One tooth from its root a to its tip b (design units)."""
    A, B = _to_head([a, b], p)
    s = p["head_h"] / 0.32
    return tapered_block(A, B, (0.0052 * s, 0.004 * s), (0.0042 * s, 0.003 * s), up=(0, 0, -1), tag="teeth")


# --- Hair ---------------------------------------------------------------------------------------

def _skull_at(rings, j, t):
    """The skull's surface in column j at height t (design units), by its rings."""
    pts = np.array([r[j] for _, r in rings[1:]])  # above the jaw ring each column climbs
    order = np.argsort(pts[:, 1])
    pts = pts[order]
    x = np.interp(t, pts[:, 1], pts[:, 0])
    z = np.interp(t, pts[:, 1], pts[:, 2])
    return np.array([x, t, z])


def hair(p):
    """Hair as a shell over the skull: short and cropped, or a bob down to the jaw."""
    rings, L = head_rings(p)
    H = L["H"]
    axis = np.array([0.0, 0.0, 0.012])

    def out(pt, d, up=0.0):
        q = np.array(pt, dtype=np.float64)
        r = np.array([q[0], 0.0, q[2]]) - axis
        n = np.linalg.norm(r)
        if n > 1e-6:
            q += r / n * d
        q[1] += up
        return q

    def shell_ring(ts, ds, ups=None, drop=None):
        pts = []
        for j in range(16):
            q = out(_skull_at(rings, j, ts[j]), ds[j], 0.0 if ups is None else ups[j])
            if drop is not None:
                q[1] -= drop[j]
            pts.append(q)
        return pts

    def per_col(front, f4, s1, s2, b1, b0):
        half = [front, front, front, front, f4, s1, s2, b1, b0]
        return half + list(reversed(half[1:8]))

    if p["hair"] == "short":
        low_t = per_col(0.262, 0.24, 0.205, 0.17, 0.14, 0.13)
        low = shell_ring(low_t, [0.006] * 16)
        mid_t = [(t + H) / 2 for t in low_t]
        mid = shell_ring(mid_t, [0.014] * 16)
        top = shell_ring([H - 0.012] * 16, [0.016] * 16, [0.012] * 16)
        crown = shell_ring([H - 0.004] * 16, [-0.02] * 16, [0.022] * 16)
        ring_list = [low, mid, top, crown]
    else:
        # a fringe over the forehead, the sides and back falling straight to the jaw
        low_t = per_col(0.212, 0.17, 0.2, 0.2, 0.2, 0.2)
        drop = per_col(0.0, 0.045, 0.14, 0.15, 0.15, 0.14)
        low = shell_ring(low_t, per_col(0.012, 0.022, 0.03, 0.032, 0.03, 0.028), drop=drop)
        ear_t = per_col(0.24, 0.2, 0.21, 0.21, 0.21, 0.21)
        ear = shell_ring(ear_t, per_col(0.014, 0.024, 0.032, 0.034, 0.032, 0.03))
        mid = shell_ring([0.275] * 16, per_col(0.016, 0.022, 0.026, 0.028, 0.026, 0.024))
        top = shell_ring([H - 0.012] * 16, [0.018] * 16, [0.012] * 16)
        crown = shell_ring([H - 0.004] * 16, [-0.02] * 16, [0.024] * 16)
        ring_list = [low, ear, mid, top, crown]
    centre = (0.0, 0.2, 0.02)
    m = Mesh()
    m.loft([_to_head(r, p) for r in ring_list], "hair", cap_points=(_to_head([centre], p)[0], None))
    return m


# --- Arms ---------------------------------------------------------------------------------------

def _keep(stations, top_y, keep):
    """Only the stations of a hanging limb whose height is within keep = (lo, hi): a limb cut
    short under clothes. A cut end is closed flat (the clothes hide it)."""
    if keep is None:
        return stations
    lo, hi = keep
    return [st for st in stations if lo - 1e-9 <= top_y - st[0] <= hi + 1e-9]


def upper_arm(p, keep=None):
    """From a low dome tucked under the shoulder's ledge (it ends early: the torso is the
    shoulder) down to a ball round the elbow."""
    k = p["arm"]
    x = SHOULDER[0] - p["arm_in"]
    top, bottom = V(x, SHOULDER[1], 0), V(x, ELBOW[1], 0)
    st = [(0.02 + 0.025 * (1 - k), 0, 0), (0.048, 0.064 * k, 0.06 * k), (0.078, 0.08 * k, 0.074 * k), (0.16, 0.072 * k, 0.07 * k, 0.006 * k),
          (0.25, 0.064 * k, 0.062 * k), (0.32, 0.06 * k, 0.058 * k), (0.356, 0.04 * k, 0.038 * k), (0.374, 0, 0)]
    return limb(top, bottom, _keep(st, top[1], keep), sides=6, turn=0.0, cap_tags=(None, "wound"))


def forearm(p, keep=None):
    k = p["arm"]
    x = ELBOW[0] - p["arm_in"]
    wrist = V(x, 0.905, 0)
    st = [(-0.056 * k, 0, 0), (-0.036 * k, 0.044 * k, 0.044 * k), (0.0, 0.058 * k, 0.057 * k),
          (0.05, 0.063 * k, 0.06 * k), (0.15, 0.054 * k, 0.051 * k), (0.24, 0.046 * k, 0.043 * k),
          (0.27, 0.043 * k, 0.04 * k), (0.29, 0.028 * k, 0.026 * k), (0.3, 0, 0)]
    m = limb(V(x, ELBOW[1], 0), wrist, _keep(st, ELBOW[1], keep), sides=6, turn=0.0, cap_tags=("wound", None))
    m.merge(hand(p, x))
    return m


def hand(p, x):
    """A big hand (two thirds of a head, as measured) hanging from the wrist: palm to the
    body, thumb forward, the fingers hooked into a claw."""
    k = p["hand"]
    top = 0.915
    knuckle = top - 0.102 * k
    m = Mesh()
    m.merge(tapered_block(V(x + 0.003, top, 0.0), V(x, knuckle, -0.004 * k), (0.05 * k, 0.03 * k),
                          (0.062 * k, 0.034 * k), up=(1, 0, 0)))
    lengths = (0.1, 0.112, 0.106, 0.09)
    for i in range(4):
        z = (-0.045 + i * 0.03) * k
        L = lengths[i] * k
        a = V(x - 0.004, knuckle + 0.008, z)
        mid = a + V(-np.sin(0.22), -np.cos(0.22), 0.0) * L * 0.55
        tip = mid + V(-np.sin(0.75), -np.cos(0.75), 0.0) * L * 0.45
        m.merge(tapered_block(a, mid, (0.0155 * k, 0.017 * k), (0.0145 * k, 0.016 * k), up=(1, 0, 0)))
        m.merge(tapered_block(mid + V(0.002, 0.004, 0), tip, (0.0145 * k, 0.016 * k), (0.0105 * k, 0.011 * k),
                              up=(1, 0, 0), tag="skin"))
    base = V(x - 0.014, top - 0.026 * k, -0.05 * k)
    mid = base + V(-0.016, -0.04, -0.032) * k
    tip = mid + V(-0.018, -0.036, -0.006) * k
    m.merge(tapered_block(base, mid, (0.019 * k, 0.018 * k), (0.018 * k, 0.017 * k), up=(1, 0, 0)))
    m.merge(tapered_block(mid, tip, (0.017 * k, 0.016 * k), (0.012 * k, 0.012 * k), up=(1, 0, 0)))
    return m


# --- Legs ---------------------------------------------------------------------------------------

def thigh(p, keep=None):
    k = p["thigh"]
    st = [(-0.062, 0, 0), (-0.045, 0.07 * k, 0.07 * k), (-0.02, 0.108 * k, 0.106 * k), (0.08, 0.108 * k, 0.104 * k),
          (0.2, 0.097 * k, 0.094 * k), (0.32, 0.083 * k, 0.081 * k), (0.42, 0.071, 0.07),
          (0.47, 0.066, 0.064), (0.5, 0.042, 0.042), (0.518, 0, 0)]
    return limb(HIP, KNEE, _keep(st, HIP[1], keep), sides=8, turn=np.pi / 8, cap_tags=("wound", "wound"))


def shin(p, keep=None, with_foot=True):
    k = p["shin"]
    calf = lambda a: 1.0 + 0.14 * max(0.0, -np.sin(a))  # noqa: E731  the back bulges
    st = [(-0.054, 0, 0), (-0.032, 0.052 * k, 0.052 * k), (0.0, 0.066 * k, 0.066 * k, 0.004),
          (0.06, 0.068 * k, 0.07 * k), (0.13, 0.073 * k, 0.071 * k, -0.004, calf),
          (0.22, 0.064 * k, 0.062 * k, -0.002, calf), (0.31, 0.051 * k, 0.049 * k), (0.37, 0.046 * k, 0.046 * k),
          (0.395, 0.035 * k, 0.035 * k), (0.41, 0, 0)]
    m = limb(KNEE, V(KNEE[0], 0.06, 0), _keep(st, KNEE[1], keep), sides=8, turn=np.pi / 8, cap_tags=("wound", None))
    if with_foot:
        m.merge(foot(p))
    return m


def foot(p):
    """A bare foot, flat on the floor, toes forward."""
    k = p["foot"]
    x = KNEE[0]
    # sections heel to toe: z, half width, height (each a hexagon with a flat sole)
    secs = [(0.078, 0.034, 0.055), (0.055, 0.045, 0.09), (-0.03, 0.052, 0.08), (-0.11, 0.057, 0.05),
            (-0.168 * k, 0.052, 0.036), (-0.188 * k, 0.043, 0.022)]
    rings = []
    for z, w, h in secs:
        w *= k
        h *= (0.6 + 0.4 * k)
        rings.append([(x - w, 0.0, z), (x + w, 0.0, z), (x + w, h * 0.6, z), (x + 0.6 * w, h, z),
                      (x - 0.6 * w, h, z), (x - w, h * 0.6, z)])
    m = Mesh()
    m.loft(rings, "skin")
    return m


# --- Assembly -----------------------------------------------------------------------------------

def pieces(p):
    """{(piece, side): Mesh} for one variant. Side is 1 (right, +x), -1 (left) or 0. Bones of
    the skeleton stick out of the wounds a severed part shows (hidden inside while it is on)."""
    import skeleton as S
    chest, hips = torso(p)
    head_m = head(p)
    head_m.merge(S.vertebra((0.0, 1.44, 0.022), 0.019, 0.011, 0.015))
    out = {(TORSO, 0): chest, (PELVIS, 0): hips, (HEAD, 0): head_m, (HAIR, 0): hair(p)}
    stubs = {THIGH: lambda: S.femur(p, stub_only=True)}
    for piece, fn in ((UPPER_ARM, upper_arm), (FOREARM, forearm), (THIGH, thigh), (SHIN, shin)):
        right = fn(p)
        if piece in stubs:
            right.merge(stubs[piece]())
        out[(piece, 1)] = right
        out[(piece, -1)] = right.mirrored()
    return out


# --- Colours --------------------------------------------------------------------------------------

# sRGB. Skin, blood, eyes and hair are the reference's (measured); its light is bluish, so the
# skin is nudged back towards the game's grey-green zombies.
C = {k: _hex(v) for k, v in MEASURED["colours"].items() if isinstance(v, str)}
SKIN = np.clip(C["skin"] * np.array([0.97, 1.03, 0.95]), 0, 1)
PALETTE = {
    "skin": SKIN, "eye": np.clip(C["eyes"] * 1.12, 0, 1), "socket": np.array([0.15, 0.14, 0.17]),
    "mouth": np.array([0.1, 0.02, 0.025]), "teeth": np.array([0.8, 0.76, 0.62]), "lip": np.array([0.3, 0.17, 0.18]),
    "hair": C["hair"] * 0.62, "brow": C["hair"] * 0.5 + SKIN * 0.25, "wound": C["blood_dark"] * 0.9,
    "nail": np.array([0.35, 0.33, 0.28]), "bone": np.array([0.8, 0.76, 0.64]),
}
BLOOD = {"dark": np.array([0.34, 0.03, 0.03]), "mid": np.array([0.55, 0.05, 0.05]), "light": np.array([0.7, 0.12, 0.1])}


def flat_colours(tags):
    return np.array([PALETTE[t] for t in tags])


# --- Painting -------------------------------------------------------------------------------------
# Every texel knows where it is (baked position), which way it faces, its piece and its face's
# tag. The tag gives the flat colour (the faceted look: one colour per face); blood, bruises and
# dirt go over it by position, so they run across faces like the reference's splatter.

def _splats(p):
    cy = p["chin_y"]
    return [((0.0, cy + 0.035, -0.135), 0.045), ((0.0, cy + 0.002, -0.115), 0.04), ((0.012, 1.55, -0.075), 0.04),
            ((-0.09, 1.38, -0.145), 0.07), ((0.11, 1.3, -0.14), 0.05), ((0.03, 1.2, -0.135), 0.045),
            ((-0.05, 1.05, -0.13), 0.04), ((0.22, 1.48, -0.05), 0.05), ((0.3, 1.3, -0.075), 0.04),
            ((-0.3, 1.35, 0.02), 0.035), ((-0.1, 1.35, 0.125), 0.06), ((0.07, 1.12, 0.1), 0.045),
            ((0.14, 0.72, -0.1), 0.05), ((-0.12, 0.6, -0.1), 0.045), ((-0.12, 0.45, -0.07), 0.05),
            ((0.13, 0.3, -0.07), 0.04), ((0.12, 0.05, -0.13), 0.05), ((-0.13, 0.06, -0.08), 0.04)]


def _drips(p):
    cy = p["chin_y"]
    return [((0.0, cy - 0.005, -0.125), 0.1, 0.012), ((0.02, 1.53, -0.09), 0.25, 0.013),
            ((-0.04, 1.5, -0.125), 0.3, 0.012), ((-0.09, 1.34, -0.155), 0.18, 0.012),
            ((0.11, 1.27, -0.145), 0.14, 0.01), ((0.22, 1.45, -0.07), 0.12, 0.01)]


def blood(P, N, colour, splats, drips, soak=None, seed=5):
    """Ragged splats with droplets round them, drips running down, and `soak` (0..1) flooding."""
    from noise import fbm
    field = np.full(len(P), -10.0, np.float32)
    rng = np.random.default_rng(seed)
    for i, (c, r) in enumerate(splats):
        c = np.array(c, dtype=np.float32)
        near = np.abs(P - c).max(-1) < r * 3.0
        if not near.any():
            continue
        Q = P[near]
        warp = (fbm(Q, 9.0, 2, seed * 31 + i) - 0.5) * r * 1.2
        stretch = np.array([1.0, 0.75 + rng.random() * 0.8, 1.0], dtype=np.float32)
        d = np.sqrt((((Q - c) / stretch) ** 2).sum(-1)) + warp
        edge = 0.55 + 0.85 * fbm(Q, 34.0, 3, seed * 7 + i)
        f = 1.0 - d / (r * edge)
        for _ in range(5):
            off = (rng.random(3) - 0.5) * r * 3.2
            off[1] *= 1.3
            rk = r * (0.12 + rng.random() * 0.22)
            dk = np.sqrt(((Q - (c + off.astype(np.float32))) ** 2).sum(-1))
            f = np.maximum(f, 1.0 - dk / rk)
        field[near] = np.maximum(field[near], f)
    mask = field > 0.0
    mask |= (field > -1.4) & (fbm(P, 110.0, 2, seed + 3) > 0.8)
    wob = fbm(P, 40.0, 2, 91) - 0.5
    for o, length, width in drips:
        o = np.array(o, dtype=np.float32)
        d = P - o
        n0 = np.array([o[0], 0.0, o[2]], np.float32)
        n0 /= max(np.linalg.norm(n0), 1e-6)
        side = np.cross(np.array([0, 1, 0], np.float32), n0)
        t = np.clip(-d[:, 1] / length, 0, 1)
        w = width * (1.0 - 0.55 * t) + 0.004 * (t > 0.92)
        mask |= ((d[:, 1] <= 0) & (d[:, 1] >= -length) & (np.abs(d @ side + wob * 0.01) < w)
                 & (np.abs(d @ n0) < 0.07) & ((N @ n0) > 0.2))
    if soak is not None:
        mask |= soak > (0.35 + 0.5 * fbm(P, 18.0, 3, seed + 7))
    tone = fbm(P, 30.0, 3, seed + 11)
    col = np.where((tone > 0.62)[:, None], BLOOD["dark"], BLOOD["mid"])
    col = np.where((tone < 0.3)[:, None], BLOOD["light"], col)
    return np.where(mask[:, None], col, colour)


def paint(maps, p):
    """Albedo and emission (both sRGB) for every texel the bake reached."""
    from noise import fbm
    mask = maps["mask"]
    P = maps["pos"][mask].astype(np.float32)
    N = maps["nrm"][mask].astype(np.float32)
    N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-6)
    piece = maps["piece"][mask]
    tag = np.clip(maps["tag"][mask], 0, len(TAGS) - 1)
    ao = np.clip(maps["ao"][mask], 0, 1)
    y = P[:, 1]
    col = np.array([PALETTE[t] for t in TAGS], dtype=np.float32)[tag]
    skin = tag == TAG["skin"]
    # Skin: faint mottling, purple-grey bruises, darker and dirtier towards hands and feet.
    mott = fbm(P, 3.0, 3, 21)
    col[skin] *= (0.95 + 0.1 * mott[skin])[:, None]
    bruise = skin & (fbm(P, 9.0, 3, 23) > 0.7)
    col[bruise] = col[bruise] * 0.7 + np.array([0.3, 0.26, 0.33], np.float32) * 0.3
    ends = skin & ((piece == FOREARM) & (y < 0.95) | (piece == SHIN) & (y < 0.2))
    col[ends] *= 0.9
    hair = tag == TAG["hair"]
    col[hair] *= (0.8 + 0.4 * fbm(P[hair] * np.array([1.0, 0.25, 1.0], np.float32), 90.0, 2, 35))[:, None]
    wound = tag == TAG["wound"]
    col[wound] = np.where((fbm(P[wound], 60.0, 2, 37) > 0.55)[:, None], BLOOD["light"], PALETTE["wound"])
    teeth = tag == TAG["teeth"]
    col[teeth] *= (0.85 + 0.2 * fbm(P[teeth], 140.0, 2, 39))[:, None]
    # Blood: round the mouth and down the chest, soaked hands, splashed legs and feet.
    soak = np.zeros(len(P), np.float32)
    soak = np.where(piece == FOREARM, np.clip((1.0 - y) / 0.2, 0, 1) * 1.05, soak)
    soak = np.where(piece == SHIN, np.clip((0.07 - y) / 0.07, 0, 1) * 0.7, soak)
    paintable = ~np.isin(tag, [TAG["eye"], TAG["teeth"], TAG["mouth"]])
    col[paintable] = blood(P[paintable], N[paintable], col[paintable], _splats(p), _drips(p), soak[paintable], seed=5)
    col *= (0.66 + 0.34 * ao)[:, None]
    eye = tag == TAG["eye"]
    col[eye] = PALETTE["eye"]
    emit = np.zeros_like(col)
    emit[eye] = PALETTE["eye"]
    size = mask.shape[0]
    albedo = np.zeros((size, size, 3), np.float32)
    emission = np.zeros((size, size, 3), np.float32)
    albedo[mask] = col
    emission[mask] = emit
    return albedo, emission


# --- Skinning -------------------------------------------------------------------------------------

def skin_weights(P, piece, p=None, seam=True):
    """How much each joint moves each vertex. Every piece rides one joint. With `seam` (a
    body), the torso's break bends: its shared ring goes half with the hips, half with the
    spine, and the rings either side follow their own piece."""
    import pipeline as pl
    n = len(P)
    W = {name: np.zeros(n, np.float32) for name, *_ in pl.BONES}
    x, y, z = P[:, 0], P[:, 1], P[:, 2]
    pc = np.rint(piece)
    side = np.where(x >= 0, "_r", "_l")
    rides = {HEAD: "neck", HAIR: "neck", UPPER_ARM: "shoulder", FOREARM: "elbow", THIGH: "hip", SHIN: "knee"}
    for k, joint in rides.items():
        sel = pc == k
        if joint == "neck":
            W["neck"][sel] = 1.0
        else:
            for s in ("_l", "_r"):
                W[joint + s][sel & (side == s)] = 1.0
    trunk = (pc == TORSO) | (pc == PELVIS)
    if seam:
        t = np.clip((y - seam_y(x, z, p) + 0.05) / 0.1, 0, 1)
        t = t * t * (3 - 2 * t)
    else:
        t = (pc == TORSO).astype(np.float32)
    W["spine"][trunk] = t[trunk]
    W["hips"][trunk] = 1 - t[trunk]
    return W


# --- Build ----------------------------------------------------------------------------------------

VIEWS = [
    ("front", (0.0, 1.2, -3.6), (0, 0.98, 0), 50),
    ("three_quarter", (-2.1, 1.55, -2.75), (0, 0.98, 0), 50),
    ("side", (3.6, 1.2, 0.0), (0, 0.98, 0), 50),
    ("back", (0.4, 1.4, 3.6), (0, 0.98, 0), 50),
    ("face", (-0.36, 1.82, -0.98), (0, 1.74, 0), 60),
]


def build(sex, quick):
    import pipeline as pl
    p = VARIANTS[sex]
    name = "zombie_body_" + sex
    pl.reset_scene()
    objs = []
    for (pc, side), mesh in pieces(p).items():
        P, T, tags = mesh.triangles()
        objs.append(pl.mesh_from_poly(f"{name}_{pc}_{side}", P, T, {"piece": pc, "tag": [TAG[t] for t in tags]}))
    obj = pl.join(objs, "ZombieBody_" + sex.upper())
    tris = len(obj.data.polygons)
    if quick:
        pl.flat_materials(obj, "tag", [PALETTE[t] for t in TAGS])
    else:
        pl.unwrap(obj, {HEAD: 2.0, HAIR: 1.1, FOREARM: 1.2})
        maps = pl.bake_maps(obj, TEX, (-0.5, -0.05, -0.3), (0.5, 2.05, 0.3), attrs=("piece", "tag"))
        albedo, emission = paint(maps, p)
        os.makedirs(OUT, exist_ok=True)
        alb = pl.save_png(albedo, os.path.join(OUT, name + "_albedo.png"), TEX)
        em = pl.save_png(emission, os.path.join(OUT, name + "_emission.png"), TEX)
        pl.textured_material(obj, alb, em)
        Pv, piece_v = pl.vertex_arrays(obj)
        arm = pl.add_rig(obj, skin_weights(Pv, piece_v, p))
        pl.export_glb([obj, arm], os.path.join(OUT, name + ".glb"))
    print(f"built {name}: {tris} triangles{' (quick)' if quick else ''}")
    prefix = "model_body_" + sex
    pl.render_views(obj, SHOTS, prefix, VIEWS)
    return [os.path.join(SHOTS, f"{prefix}_{v[0]}.png") for v in VIEWS]


def main():
    import pipeline as pl
    quick = "--quick" in sys.argv
    sexes = [s for s in ("m", "f") if "--" + s in sys.argv] or ["m", "f"]
    shots = []
    for sex in sexes:
        shots += build(sex, quick)
    pl.contact_sheet(shots, os.path.join(SHOTS, "model_body.png"), len(VIEWS))
    print("previews:", os.path.join(SHOTS, "model_body.png"))


# --- Sketch (no Blender) ----------------------------------------------------------------------------

SKETCH_VIEWS = [
    ("front", (0.0, 1.15, -4.2), (0, 0.98, 0), 4.0),
    ("three_quarter", (-2.6, 1.6, -3.3), (0, 0.98, 0), 4.0),
    ("side", (4.2, 1.15, 0.0), (0, 0.98, 0), 4.0),
    ("back", (0.5, 1.4, 4.2), (0, 0.98, 0), 4.0),
    ("face", (-0.35, 1.82, -1.05), (0, 1.76, 0), 3.0),
    ("face_front", (0.0, 1.76, -1.1), (0, 1.76, 0), 3.2),
]


FACE_VIEWS = [
    ("front", (0.0, 1.77, -1.0), (0, 1.76, 0), 3.4),
    ("three_quarter", (-0.62, 1.8, -0.8), (0, 1.76, 0), 3.4),
    ("side", (1.0, 1.77, -0.05), (0, 1.76, -0.02), 3.4),
    ("below", (-0.25, 1.45, -0.9), (0, 1.74, 0), 3.4),
]


def sketch(path, face_path):
    import sketch as sk
    import skeleton as S
    rows, faces = [], []
    for sex in ("m", "f", "skeleton"):
        p = VARIANTS.get(sex, MALE)
        mesh = Mesh()
        for m in (S.bones(p) if sex == "skeleton" else pieces(p)).values():
            mesh.merge(m)
        P, T, tags = mesh.triangles()
        cols = S.flat_colours(tags) if sex == "skeleton" else flat_colours(tags)
        rows.append([sk.render(P, T, cols, eye, target, focal=f) for _, eye, target, f in SKETCH_VIEWS])
        faces.append([sk.render(P, T, cols, eye, target, size=(560, 560), focal=f) for _, eye, target, f in FACE_VIEWS])
        print(f"{sex}: {len(P)} points, {len(T)} triangles")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sk.sheet(rows, path)
    sk.sheet(faces, face_path)
    print("wrote", path, "and", face_path)


if __name__ == "__main__":
    if "--sketch" in sys.argv:
        sketch(os.path.join(SHOTS, "sketch_body.png"), os.path.join(SHOTS, "sketch_face.png"))
    else:
        main()
