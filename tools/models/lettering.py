"""The detail kit's lettering (S141): two stroke fonts drawn on a 4 x 6 grid (capitals, figures,
French accents, the punctuation of signs), painted into a bake or built as raised geometry.

    block    a plain sans of straight strokes and cut corners: enamel street plates, shop signs,
             painted numbers, road words (stretch it with `aspect`)
    stencil  the same letters with a bridge across every closed counter and a lighter weight,
             as sprayed through a stencil: crates, military marks, kerbs

    mask(P, text, centre, height, right, up, font, ...)  -> which points lie on the text
    mesh(text, height, depth, origin, right, up, ...)    -> raised letters (cast plates)
    width(text, height, font)                             -> how long a line is

Lower case is set in capitals (signs here are). Every glyph is polylines of (x, y) with y up, cap
height 6; `BRIDGES` are points of the stencil's breaks.
"""
import numpy as np

from poly import Mesh

O_ = [(0.8, 0), (3.2, 0), (4, 0.8), (4, 5.2), (3.2, 6), (0.8, 6), (0, 5.2), (0, 0.8), (0.8, 0)]
C_ = [(4, 5.2), (3.2, 6), (0.8, 6), (0, 5.2), (0, 0.8), (0.8, 0), (3.2, 0), (4, 0.8)]
P_ = [(0, 0), (0, 6), (3.2, 6), (4, 5.2), (4, 3.8), (3.2, 3), (0, 3)]

GLYPHS = {
    "A": [[(0, 0), (0, 4.4), (1.4, 6), (2.6, 6), (4, 4.4), (4, 0)], [(0, 2.6), (4, 2.6)]],
    "B": [[(0, 0), (0, 6), (3, 6), (3.8, 5.2), (3.8, 3.9), (3, 3.2), (0, 3.2)],
          [(3, 3.2), (4, 2.4), (4, 0.8), (3.2, 0), (0, 0)]],
    "C": [C_],
    "D": [[(0, 0), (0, 6), (2.6, 6), (4, 4.6), (4, 1.4), (2.6, 0), (0, 0)]],
    "E": [[(4, 6), (0, 6), (0, 0), (4, 0)], [(0, 3.1), (3, 3.1)]],
    "F": [[(4, 6), (0, 6), (0, 0)], [(0, 3.1), (3, 3.1)]],
    "G": [C_[:-1] + [(4, 0.8), (4, 2.8), (2.2, 2.8)]],
    "H": [[(0, 0), (0, 6)], [(4, 0), (4, 6)], [(0, 3.1), (4, 3.1)]],
    "I": [[(1, 6), (3, 6)], [(2, 6), (2, 0)], [(1, 0), (3, 0)]],
    "J": [[(1.6, 6), (4, 6), (4, 0.8), (3.2, 0), (0.8, 0), (0, 0.8), (0, 1.8)]],
    "K": [[(0, 0), (0, 6)], [(4, 6), (0, 2.2)], [(1.4, 3.5), (4, 0)]],
    "L": [[(0, 6), (0, 0), (4, 0)]],
    "M": [[(0, 0), (0, 6), (2, 2.6), (4, 6), (4, 0)]],
    "N": [[(0, 0), (0, 6), (4, 0), (4, 6)]],
    "O": [O_],
    "P": [P_],
    "Q": [O_, [(2.4, 1.6), (4.3, -0.5)]],
    "R": [P_, [(2.2, 3), (4, 0)]],
    "S": [[(4, 5.2), (3.2, 6), (0.8, 6), (0, 5.2), (0, 3.8), (0.8, 3.1), (3.2, 3.1), (4, 2.3), (4, 0.8), (3.2, 0),
           (0.8, 0), (0, 0.8)]],
    "T": [[(0, 6), (4, 6)], [(2, 6), (2, 0)]],
    "U": [[(0, 6), (0, 0.8), (0.8, 0), (3.2, 0), (4, 0.8), (4, 6)]],
    "V": [[(0, 6), (2, 0), (4, 6)]],
    "W": [[(0, 6), (1, 0), (2, 4), (3, 0), (4, 6)]],
    "X": [[(0, 6), (4, 0)], [(0, 0), (4, 6)]],
    "Y": [[(0, 6), (2, 3), (4, 6)], [(2, 3), (2, 0)]],
    "Z": [[(0, 6), (4, 6), (0, 0), (4, 0)]],
    "0": [[(1.1, 0), (2.9, 0), (3.6, 0.8), (3.6, 5.2), (2.9, 6), (1.1, 6), (0.4, 5.2), (0.4, 0.8), (1.1, 0)]],
    "1": [[(0.8, 4.6), (2.4, 6), (2.4, 0)], [(1, 0), (3.8, 0)]],
    "2": [[(0, 5.2), (0.8, 6), (3.2, 6), (4, 5.2), (4, 3.9), (0, 0.6), (0, 0), (4, 0)]],
    "3": [[(0, 5.2), (0.8, 6), (3.2, 6), (4, 5.2), (4, 3.9), (3.2, 3.1), (1.4, 3.1)],
          [(3.2, 3.1), (4, 2.3), (4, 0.8), (3.2, 0), (0.8, 0), (0, 0.8)]],
    "4": [[(3, 0), (3, 6), (0, 1.8), (4, 1.8)]],
    "5": [[(4, 6), (0.4, 6), (0, 3.2), (3.2, 3.4), (4, 2.6), (4, 0.8), (3.2, 0), (0.8, 0), (0, 0.8)]],
    "6": [[(3.6, 6), (1.8, 6), (0, 4.2), (0, 0.8), (0.8, 0), (3.2, 0), (4, 0.8), (4, 2.4), (3.2, 3.2), (0.8, 3.2), (0, 2.6)]],
    "7": [[(0, 6), (4, 6), (4, 5.2), (1.6, 0)]],
    "8": [[(0.8, 3.1), (0, 3.9), (0, 5.2), (0.8, 6), (3.2, 6), (4, 5.2), (4, 3.9), (3.2, 3.1), (0.8, 3.1), (0, 2.3),
           (0, 0.8), (0.8, 0), (3.2, 0), (4, 0.8), (4, 2.3), (3.2, 3.1)]],
    "9": [[(0.4, 0), (2.2, 0), (4, 1.8), (4, 5.2), (3.2, 6), (0.8, 6), (0, 5.2), (0, 3.6), (0.8, 2.8), (3.2, 2.8), (4, 3.4)]],
    ".": [[(2, 0), (2, 0.35)]],
    ",": [[(2.2, 0.4), (1.6, -0.9)]],
    "-": [[(1, 3), (3, 3)]],
    "'": [[(2.1, 6), (1.8, 4.6)]],
    "/": [[(0.4, -0.2), (3.6, 6.2)]],
    ":": [[(2, 0), (2, 0.35)], [(2, 3.6), (2, 3.95)]],
    "!": [[(2, 6), (2, 1.8)], [(2, 0), (2, 0.35)]],
    "?": [[(0, 5.2), (0.8, 6), (3.2, 6), (4, 5.2), (4, 4.2), (2, 2.8), (2, 1.8)], [(2, 0), (2, 0.35)]],
    "+": [[(0.6, 3), (3.4, 3)], [(2, 1.6), (2, 4.4)]],
    "=": [[(0.6, 2.2), (3.4, 2.2)], [(0.6, 3.8), (3.4, 3.8)]],
    "(": [[(2.8, 6.4), (1.6, 5), (1.6, 1), (2.8, -0.4)]],
    ")": [[(1.2, 6.4), (2.4, 5), (2.4, 1), (1.2, -0.4)]],
    "°": [[(1.4, 5.2), (2, 5.8), (2.6, 5.2), (2, 4.6), (1.4, 5.2)]],
    "&": [[(4, 0), (0.6, 4.2), (0.6, 5.3), (1.3, 6), (2.5, 6), (3.1, 5.3), (3.1, 4.4), (0, 2.2), (0, 0.8), (0.8, 0),
           (2.6, 0), (4, 1.8)]],
    " ": [],
}

ACCENTS = {
    "acute": [[(1.6, 6.9), (2.7, 8)]],
    "grave": [[(1.3, 8), (2.4, 6.9)]],
    "circ": [[(0.9, 6.9), (2, 8), (3.1, 6.9)]],
    "trema": [[(1, 7.2), (1, 7.6)], [(3, 7.2), (3, 7.6)]],
    "cedilla": [[(2, 0), (2, -0.7), (1.1, -1.3)]],
}
COMPOSED = {
    "É": ("E", "acute"), "È": ("E", "grave"), "Ê": ("E", "circ"), "Ë": ("E", "trema"), "À": ("A", "grave"),
    "Â": ("A", "circ"), "Ç": ("C", "cedilla"), "Î": ("I", "circ"), "Ï": ("I", "trema"), "Ô": ("O", "circ"),
    "Ù": ("U", "grave"), "Û": ("U", "circ"), "Ü": ("U", "trema"), "Œ": None,
}
# The stencil's breaks: one per closed counter at least, so the stencil's middle would not fall out.
BRIDGES = {
    "A": [(2, 6)], "B": [(0, 4.6), (0, 1.6)], "D": [(0, 3)], "O": [(2, 6), (2, 0)], "Q": [(2, 6), (2, 0)],
    "P": [(0, 4.5)], "R": [(0, 4.5)], "0": [(2, 6), (2, 0)], "4": [(1.5, 3.9)], "6": [(2, 0)], "8": [(2, 6), (2, 0)],
    "9": [(2, 6)], "&": [(0, 1.5)], "°": [(2, 5.8)],
    # and where a stroke meets another, as stencil cutters do
    "E": [(0, 3.1)], "F": [(0, 3.1)], "H": [(2, 3.1)], "K": [(0, 3.1)], "T": [(2, 6)], "M": [(2, 2.6)], "N": [(0, 6)],
}
FONTS = {
    # weight: stroke width in grid units; gap: a stencil bridge's width; advance: space taken by a letter
    "block": {"weight": 0.95, "bridges": False, "advance": 5.4},
    "stencil": {"weight": 1.05, "bridges": True, "gap": 0.9, "advance": 5.6},
}


def strokes(ch):
    """The polylines of one character (composed from a letter and its accent where needed)."""
    ch = ch.upper()
    if ch == "Œ":
        o = [[(x * 0.55, y) for x, y in s] for s in GLYPHS["O"]]  # the O's right side is the E's stem
        e = [[(2.2 + x * 0.5, y) for x, y in s] for s in GLYPHS["E"]]
        return o + e
    if ch in COMPOSED:
        base, acc = COMPOSED[ch]
        return GLYPHS[base] + ACCENTS[acc]
    if ch not in GLYPHS:
        raise KeyError(f"no glyph for {ch!r}")
    return GLYPHS[ch]


def has(ch):
    try:
        strokes(ch)
        return True
    except KeyError:
        return False


def _advance(ch, font):
    a = FONTS[font]["advance"]
    if ch in ".,:!'":
        return a * 0.5
    if ch == " ":
        return a * 0.75
    if ch.upper() == "Œ":
        return a * 1.35
    return a


def width(text, height, font="block", aspect=1.0):
    """How long `text` is when set `height` tall (cap height), in metres."""
    u = height / 6.0 / aspect
    adv = sum(_advance(c, font) for c in text)
    return (adv - (FONTS[font]["advance"] - 4.0)) * u


def _segments(text, font):
    """Every stroke segment of the line as (ax, ay, bx, by) in grid units from the line's start,
    and the stencil's bridges as (x, y)."""
    segs, bridges = [], []
    x0 = 0.0
    for ch in text:
        for line in strokes(ch):
            pts = [(x0 + x, y) for x, y in line]
            for a, b in zip(pts, pts[1:]):
                segs.append((a[0], a[1], b[0], b[1]))
        for bx, by in BRIDGES.get(ch.upper(), []) if FONTS[font].get("bridges") else []:
            bridges.append((x0 + bx, by))
        x0 += _advance(ch, font)
    return np.array(segs, np.float32).reshape(-1, 4), np.array(bridges, np.float32).reshape(-1, 2), x0


def coverage(P, text, centre, height, right=(-1, 0, 0), up=(0, 1, 0), font="block", weight=None, aspect=1.0,
             align="center", shear=0.0, jitter=None):
    """How far inside the strokes each point lies, in grid units (> 0 inside, the stroke's half
    width at its middle); points far away get -1. `aspect` > 1 stretches the letters along `up`
    (road words are long), `shear` slants them, `jitter(u, v)` may move the points first (a
    sprayed hand)."""
    P = np.asarray(P, np.float32)
    right, up = np.asarray(right, np.float32), np.asarray(up, np.float32)
    f = FONTS[font]
    w = (weight if weight is not None else f["weight"]) / 2
    segs, bridges, total = _segments(text, font)
    unit_x = height / 6.0 / aspect  # metres per grid unit across
    unit_y = height / 6.0
    line_w = (total - (f["advance"] - 4.0)) * unit_x
    rel = P - np.asarray(centre, np.float32)
    off = {"center": line_w / 2, "left": 0.0, "right": line_w}[align]
    gx = (rel @ right + off) / unit_x
    gy = (rel @ up + height / 2) / unit_y
    gx = gx - shear * gy
    out = np.full(len(P), -1.0, np.float32)
    near = (gx > -2) & (gx < total + 2) & (gy > -2.5) & (gy < 9.5)
    idx = np.nonzero(near)[0]
    if len(idx) == 0 or len(segs) == 0:
        return out
    x, y = gx[idx], gy[idx]
    if jitter is not None:
        x, y = jitter(x, y)
    best = np.full(len(idx), 1e9, np.float32)
    for k in range(0, len(segs), 64):  # segments in chunks: points x segments stays small
        s = segs[k:k + 64]
        ax, ay, bx, by = s[:, 0][None], s[:, 1][None], s[:, 2][None], s[:, 3][None]
        dx, dy = bx - ax, by - ay
        L2 = np.maximum(dx * dx + dy * dy, 1e-9)
        t = np.clip(((x[:, None] - ax) * dx + (y[:, None] - ay) * dy) / L2, 0, 1)
        ex, ey = x[:, None] - (ax + t * dx), y[:, None] - (ay + t * dy)
        best = np.minimum(best, np.sqrt(ex * ex + ey * ey).min(1))
    cov = w - best
    if len(bridges):
        g = f["gap"] / 2
        for bx, by in bridges:
            # a bridge cuts clean across the stroke it sits on: a band square to that stroke
            sx = segs[:, 2] - segs[:, 0]
            sy = segs[:, 3] - segs[:, 1]
            L2 = np.maximum(sx * sx + sy * sy, 1e-9)
            t = np.clip(((bx - segs[:, 0]) * sx + (by - segs[:, 1]) * sy) / L2, 0, 1)
            k = int(np.argmin(np.hypot(bx - (segs[:, 0] + t * sx), by - (segs[:, 1] + t * sy))))
            dl = np.sqrt(L2[k])
            ux, uy = sx[k] / dl, sy[k] / dl
            along = np.abs((x - bx) * ux + (y - by) * uy)
            across = np.abs((x - bx) * -uy + (y - by) * ux)
            cut = (across < w * 1.8) & (along < g)
            cov = np.where(cut, np.minimum(cov, along - g), cov)
    out[idx] = np.where(cov > -1, cov, -1)
    return out


def mask(P, text, centre, height, right=(-1, 0, 0), up=(0, 1, 0), font="block", **kw):
    """Which points lie on `text` written at `centre` (the line's middle), `height` tall (cap
    height), along `right` and `up`, the reader's right and up (the default reads from the
    front, -Z). A flat projection: give it the faces it may land on too."""
    return coverage(P, text, centre, height, right, up, font, **kw) > 0


def mesh(text, height, depth, origin=(0, 0, 0), right=(-1, 0, 0), up=(0, 1, 0), font="block", weight=None,
         tag="letter", align="center"):
    """Raised letters standing `depth` out of the plane towards the reader (right x up: -Z for
    the default frame, read from the front), one bar per stroke segment with square ends
    overlapping at the joins."""
    o = np.asarray(origin, np.float64)
    r, u = np.asarray(right, np.float64), np.asarray(up, np.float64)
    f = np.cross(r, u)
    segs, _, total = _segments(text, font)
    unit = height / 6.0
    w = (weight if weight is not None else FONTS[font]["weight"]) * unit
    line_w = (total - (FONTS[font]["advance"] - 4.0)) * unit
    shift = {"center": line_w / 2, "left": 0.0, "right": line_w}[align]
    m = Mesh()
    for ax, ay, bx, by in segs:
        a = o + r * (ax * unit - shift) + u * (ay * unit - height / 2)
        b = o + r * (bx * unit - shift) + u * (by * unit - height / 2)
        d = b - a
        L = np.linalg.norm(d)
        if L < 1e-9:
            d = u * 1e-3
            L = 1e-3
        d /= L
        side = np.cross(f, d)
        c = (a + b) / 2 + f * depth / 2
        basis = np.stack([side, d, f], 1)
        m.box(c, (w / 2, L / 2 + w / 2, depth / 2), tag, basis)
    return m


def check():
    fails = []
    for ch in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ÉÈÊËÀÂÇÎÏÔÙÛÜŒ.,-'/:!?+=()°& ":
        if not has(ch):
            fails.append(f"no glyph {ch}")
    # a stencil O has its two breaks, a block O none
    P = np.array([[0.0, 0.5, 0.0], [0.0, -0.5, 0.0]], np.float32)  # top and bottom middle of an O 1 m tall
    if not mask(P, "O", (0, 0, 0), 1.0).all():
        fails.append("block O: top and bottom drawn")
    if mask(P, "O", (0, 0, 0), 1.0, font="stencil").any():
        fails.append("stencil O: bridged top and bottom")
    return fails


if __name__ == "__main__":
    import sys
    if "--check" in sys.argv:
        f = check()
        print("\n".join(f) if f else "lettering: all checks pass")
        sys.exit(1 if f else 0)
