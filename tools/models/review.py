"""The review sheet of an element: the game's own rack (`--prop-rack=<name> --review=...`) shot from
eight angles, a 1 m close-up, 10 m and 50 m away, its parts open and every state, beside the
reference photos on its card (references/elements/<name>/).

    python tools/models/review.py hydrant --round=1   -> references/elements/reviews/hydrant_r1.jpg

Write every difference from the references on the card's round section, fix them, rebuild
(tools\\blender.ps1 tools\\models\\props.py <name>) and shoot the next round.
"""
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
REVIEWS = os.path.join(ROOT, "references", "elements", "reviews")  # kept in git, beside the cards
TILE = (300, 400)
ORDER = [["a0", "a45", "a90", "a135"], ["a180", "a225", "a270", "a315"], ["close_1m", "far_10m", "far_50m", "open"]]


def godot(*args):
    cmd = ["powershell", "-ExecutionPolicy", "Bypass", "-File", os.path.join(ROOT, "tools", "godot.ps1"), *args]
    return subprocess.run(cmd, cwd=ROOT)


def shoot(name, out_dir):
    godot("--headless", "--import")
    godot("--", f"--prop-rack={name}", f"--review={out_dir.replace(os.sep, '/')}")


def _tile(path, label, size=TILE):
    im = Image.open(path).convert("RGB") if os.path.exists(path) else Image.new("RGB", size, (60, 0, 0))
    im.thumbnail(size)
    tile = Image.new("RGB", size, (20, 21, 26))
    tile.paste(im, ((size[0] - im.width) // 2, (size[1] - im.height) // 2))
    d = ImageDraw.Draw(tile)
    d.rectangle([0, 0, len(label) * 7 + 8, 16], fill=(0, 0, 0))
    d.text((4, 2), label, fill=(255, 255, 255))
    return tile


def sheet(name, shots_dir, out_path):
    states = sorted(f[6:-4] for f in os.listdir(shots_dir) if f.startswith("state_"))
    rows = [[(os.path.join(shots_dir, v + ".png"), v) for v in row] for row in ORDER]
    rows.append([(os.path.join(shots_dir, f"state_{s}.png"), s) for s in states])
    ref_dir = os.path.join(ROOT, "references", "elements", name)
    refs = sorted(os.path.join(ref_dir, f) for f in os.listdir(ref_dir)) if os.path.isdir(ref_dir) else []
    refs = [r for r in refs if r.lower().endswith((".jpg", ".jpeg", ".png"))]
    small = len(refs) > 8  # many references (the kit's board): half-size tiles, four across
    rt = (TILE[0] // 2, TILE[1] // 2) if small else TILE
    ref_cols = 4 if small else 2
    ref_rows = (len(refs) + ref_cols - 1) // ref_cols
    cols = max(len(r) for r in rows)
    height = max(len(rows) * TILE[1], ref_rows * rt[1])
    out = Image.new("RGB", (cols * TILE[0] + ref_cols * rt[0] + 12, height + 24), (10, 10, 12))
    d = ImageDraw.Draw(out)
    d.text((6, 6), f"{name}: the game's rack (left), the card's references (right)", fill=(230, 230, 230))
    for r, row in enumerate(rows):
        for c, (path, label) in enumerate(row):
            out.paste(_tile(path, label), (c * TILE[0], 24 + r * TILE[1]))
    for i, path in enumerate(refs):
        r, c = divmod(i, ref_cols)
        out.paste(_tile(path, os.path.basename(path)[:-4], rt), (cols * TILE[0] + 12 + c * rt[0], 24 + r * rt[1]))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    out.save(out_path, quality=82)
    return out_path


def view_sheets(name, shots_dir, out_path):
    """An element with close-ups of its own (the kit's board): one sheet per state, every
    close-up in it, big enough to judge the paint. Written beside the main sheet as
    <name>_r<N>_<state>.jpg; returns their paths."""
    names = sorted({f[5:-4].rsplit("_", 1)[0] for f in os.listdir(shots_dir) if f.startswith("view_")})
    if not names:
        return []
    states = sorted({f[:-4].rsplit("_", 1)[1] for f in os.listdir(shots_dir) if f.startswith("view_")},
                    key=lambda s: ["clean", "abandoned", "damaged", "burnt"].index(s) if s in ("clean", "abandoned", "damaged", "burnt") else 9)
    size = (640, 360)
    cols = 3
    out_paths = []
    for st in states:
        rows = (len(names) + cols - 1) // cols
        im = Image.new("RGB", (cols * size[0], rows * size[1] + 24), (10, 10, 12))
        ImageDraw.Draw(im).text((6, 6), f"{name}: close-ups, {st}", fill=(230, 230, 230))
        for i, v in enumerate(names):
            r, c = divmod(i, cols)
            im.paste(_tile(os.path.join(shots_dir, f"view_{v}_{st}.png"), v, size), (c * size[0], 24 + r * size[1]))
        p = out_path[:-4] + f"_{st}.jpg"
        im.save(p, quality=85)
        out_paths.append(p)
    return out_paths


def main():
    names = [a for a in sys.argv[1:] if not a.startswith("--")]
    rnd = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--round=")), "0")
    for name in names:
        tmp = tempfile.mkdtemp(prefix=f"review_{name}_")
        try:
            shoot(name, tmp)
            path = sheet(name, tmp, os.path.join(REVIEWS, f"{name}_r{rnd}.jpg"))
            print("wrote", path)
            for p in view_sheets(name, tmp, path):
                print("wrote", p)
        finally:
            shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
