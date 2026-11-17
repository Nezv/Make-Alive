"""The game's skeleton (scripts/models/humanoid.gd and character_model.gd), for the model scripts:
joints with their rest positions, plus the helper bones clothes bend on, and a numpy copy of how
the game poses them (Humanoid._apply), so a model can be looked at bent without the game.

A helper turns half as far as its joint and sits on it (shoulder_r_mid on shoulder_r, child of
the spine): a ring of cloth riding it shares a bend between the bands either side of it.
"""
import numpy as np

# name, parent, head (rest position), tail
JOINTS = [
    ("hips", None, (0, 0.92, 0), (0, 0.80, 0)),
    ("spine", "hips", (0, 0.92, 0), (0, 1.56, 0)),
    ("neck", "spine", (0, 1.56, 0), (0, 1.86, 0)),
    ("shoulder_l", "spine", (-0.33, 1.50, 0), (-0.33, 1.18, 0)),
    ("elbow_l", "shoulder_l", (-0.33, 1.18, 0), (-0.33, 0.86, 0)),
    ("shoulder_r", "spine", (0.33, 1.50, 0), (0.33, 1.18, 0)),
    ("elbow_r", "shoulder_r", (0.33, 1.18, 0), (0.33, 0.86, 0)),
    ("hip_l", "hips", (-0.12, 0.92, 0), (-0.12, 0.47, 0)),
    ("knee_l", "hip_l", (-0.12, 0.47, 0), (-0.12, 0.04, 0)),
    ("hip_r", "hips", (0.12, 0.92, 0), (0.12, 0.47, 0)),
    ("knee_r", "hip_r", (0.12, 0.47, 0), (0.12, 0.04, 0)),
]
# helper -> the joint it follows half way (same place, same parent)
HELPERS = {j + "_mid": j for j in ("shoulder_l", "elbow_l", "shoulder_r", "elbow_r", "hip_l", "knee_l", "hip_r", "knee_r")}


def bones():
    """Every bone: the joints, then the helpers (tail a third of the way to the joint's)."""
    out = list(JOINTS)
    table = {b[0]: b for b in JOINTS}
    for h, j in HELPERS.items():
        _, parent, head, tail = table[j]
        mid_tail = tuple(np.array(head) + (np.array(tail) - np.array(head)) / 3)
        out.append((h, parent, head, mid_tail))
    return out


BONES = bones()
HEAD = {b[0]: np.array(b[2], dtype=np.float64) for b in BONES}
PARENT = {b[0]: b[1] for b in BONES}


# --- Posing (as Humanoid._apply does) -------------------------------------------------------------

def _rx(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])


def _ry(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])


def _rz(a):
    c, s = np.cos(a), np.sin(a)
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])


def euler(x, y, z):
    """Godot's Node3D.rotation (order YXZ)."""
    return _ry(y) @ _rx(x) @ _rz(z)


def half(R):
    """The rotation half way from none to R (same axis, half the angle)."""
    angle = np.arccos(np.clip((np.trace(R) - 1) / 2, -1, 1))
    if angle < 1e-9:
        return np.eye(3)
    axis = np.array([R[2, 1] - R[1, 2], R[0, 2] - R[2, 0], R[1, 0] - R[0, 1]])
    n = np.linalg.norm(axis)
    if n < 1e-9:  # a half turn: any perpendicular axis of R + I
        S = R + np.eye(3)
        axis = S[:, np.argmax(np.linalg.norm(S, axis=0))]
        n = np.linalg.norm(axis)
    axis = axis / n
    a = angle / 2
    K = np.array([[0, -axis[2], axis[1]], [axis[2], 0, -axis[0]], [-axis[1], axis[0], 0]])
    return np.eye(3) + np.sin(a) * K + (1 - np.cos(a)) * K @ K


# Humanoid.J goal channels for a few poses (zombie walk, attack, run, crouched windup, crawl, stagger)
POSES = {
    "rest": {},
    "walk": dict(HIPS_Y=0.89, SPINE_PITCH=0.32, NECK_PITCH=-0.25, SH_L_X=1.25, SH_R_X=1.25, SH_L_OUT=0.1,
                 SH_R_OUT=0.1, EL_L=0.25, EL_R=0.45, HIP_L=0.42, HIP_R=-0.42, KNEE_L=-0.12, KNEE_R=-0.75),
    "attack": dict(HIPS_Y=0.84, SPINE_PITCH=-0.2, NECK_PITCH=-0.5, SH_L_X=2.9, SH_R_X=2.7, SH_L_OUT=0.3,
                   SH_R_OUT=0.3, EL_L=0.9, EL_R=0.9, HIP_L=0.5, KNEE_L=-0.4, HIP_R=-0.35, KNEE_R=-0.15),
    "run": dict(HIPS_Y=0.9, HIPS_PITCH=0.15, SPINE_PITCH=0.6, NECK_PITCH=-0.55, SH_L_X=2.2, SH_R_X=0.8,
                SH_L_OUT=0.25, SH_R_OUT=0.25, EL_L=1.1, EL_R=0.5, HIP_L=0.8, HIP_R=-0.8, KNEE_L=-0.12, KNEE_R=-1.72),
    "windup": dict(HIPS_Y=0.548, SPINE_PITCH=0.75, NECK_PITCH=-0.7, SH_L_X=-0.7, SH_R_X=-0.7, SH_L_OUT=0.4,
                   SH_R_OUT=0.4, EL_L=0.9, EL_R=0.9, HIP_L=0.935, HIP_R=0.935, KNEE_L=-1.87, KNEE_R=-1.87),
    "crawl": dict(HIPS_Y=0.22, HIPS_PITCH=1.38, NECK_PITCH=-0.95, SH_L_X=3.2, SH_R_X=2.3, SH_L_OUT=0.35,
                  SH_R_OUT=0.35, EL_L=0.25, EL_R=1.15, HIP_L=-0.05, HIP_R=-0.05),
    "stagger": dict(HIPS_Y=0.82, SPINE_PITCH=-0.4, SPINE_YAW=0.45, NECK_PITCH=-0.5, NECK_ROLL=0.3, SH_L_X=-0.3,
                    SH_R_X=-0.3, SH_L_OUT=1.0, SH_R_OUT=1.0, EL_L=0.5, EL_R=0.5, HIP_L=-0.35, HIP_R=0.4,
                    KNEE_L=-0.3, KNEE_R=-0.6),
}


def local_rotations(goal):
    g = dict(goal)
    v = lambda k: float(g.get(k, 0.0))  # noqa: E731
    rot = {
        "hips": euler(-v("HIPS_PITCH"), 0, v("HIPS_ROLL")),
        "spine": euler(-v("SPINE_PITCH"), v("SPINE_YAW"), v("SPINE_ROLL")),
        "neck": euler(-v("NECK_PITCH"), v("NECK_YAW"), v("NECK_ROLL")),
        "shoulder_l": euler(v("SH_L_X"), 0, -v("SH_L_OUT")),
        "shoulder_r": euler(v("SH_R_X"), 0, v("SH_R_OUT")),
        "elbow_l": euler(v("EL_L"), 0, 0), "elbow_r": euler(v("EL_R"), 0, 0),
        "hip_l": euler(v("HIP_L"), 0, 0), "hip_r": euler(v("HIP_R"), 0, 0),
        "knee_l": euler(v("KNEE_L"), 0, 0), "knee_r": euler(v("KNEE_R"), 0, 0),
    }
    for h, j in HELPERS.items():
        rot[h] = half(rot[j])
    return rot, v("HIPS_Y") if "HIPS_Y" in g else 0.92


def skin_matrices(goal):
    """{bone: (3x3, translation)} taking a rest point to its posed place."""
    rot, hips_y = local_rotations(goal)
    glob = {}
    for name, parent, head, _ in BONES:
        R = rot[name]
        if parent is None:
            Gr, Gt = R, np.array([0.0, hips_y, 0.0])
        else:
            pr, pt = glob[parent]
            off = HEAD[name] - HEAD[parent]
            Gr, Gt = pr @ R, pt + pr @ off
        glob[name] = (Gr, Gt)
    return {n: (Gr, Gt - Gr @ HEAD[n]) for n, (Gr, Gt) in glob.items()}


def pose_points(P, weights, goal):
    """Linear blend skinning of points P (n, 3) with weights [{bone: w}] into a pose."""
    M = skin_matrices(goal)
    out = np.zeros_like(P)
    for i, (p, w) in enumerate(zip(P, weights)):
        acc = np.zeros(3)
        tot = 0.0
        for b, wb in w.items():
            Rm, t = M[b]
            acc += wb * (Rm @ p + t)
            tot += wb
        out[i] = acc / max(tot, 1e-9)
    return out
