r"""The sky's review sheet (S050, references/elements/sky.md): every preset from the same three
viewpoints, one row per preset, the card's reference for that preset beside it.

    python tools/sky_review.py 1            -> references/elements/reviews/sky_r1.jpg
    python tools/sky_review.py 1 --no-shoot -> the sheet again from the last shots
    python tools/sky_review.py 3 --missions -> also sky_r3_missions.jpg: each mission's start, every preset

Each viewpoint is one launch of the game with --time-cycle: one shot per preset, in TimeOfDay's order.
The shots go to references/shots/sky_<view>_<preset>.png."""
import os
import shutil
import subprocess
import sys
import tempfile
from PIL import Image, ImageDraw, ImageFont

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
shots = os.path.join(root, "references", "shots")
PRESETS = ["clear", "overcast", "dusk", "night", "storm"]
# name -> extra game options: the place du Marché looking past its roofs at the hill, the roofs
# by the bridge looking at the hill, and the hill looking down over the town.
VIEWS = {
    "marche": ["--shot-cam=150,1.7,40,-58,7"],
    "roofs": ["--shot-cam=262,30,-150,-61,2"],
    "hill": ["--shot-cam=1860,252,-1025,120,-10"],
}
REFS = {
    "clear": "dusk_roofs.jpg",
    "overcast": "overcast_montmartre.jpg",
    "dusk": "dusk_cityscape.jpg",
    "night": "night_glow_raphael.jpg",
    "storm": "storm_night.jpg",
}


def shoot(view: str, opts: list) -> None:
    tmp = tempfile.gettempdir().replace("\\", "/")  # no spaces: the game's arguments are split on them
    base = f"{tmp}/sky_{view}.png"
    at = ",".join(f"{2.4 + 1.3 * i:.1f}" for i in range(len(PRESETS)))
    args = ["powershell", "-NoProfile", "-File", os.path.join(root, "tools", "godot.ps1"), "--", "--host", "--no-hordes",
            "--time=" + PRESETS[0], "--time-cycle", "--lightning", *opts, f"--screenshot={base}", f"--shot-at={at}",
            f"--quit-after={2.4 + 1.3 * len(PRESETS) + 0.5:.1f}"]
    subprocess.run(args, cwd=root, capture_output=True)
    for i, preset in enumerate(PRESETS):
        src = f"{tmp}/sky_{view}_{i}.png"
        if os.path.exists(src):
            shutil.move(src, f"{shots}/sky_{view}_{preset}.png")
            print("shot ", view, preset)
        else:
            print("FAIL ", view, preset)


def fit(im, w, h):
    im = im.convert("RGB")
    r = min(w / im.width, h / im.height)
    im = im.resize((int(im.width * r), int(im.height * r)))
    canvas = Image.new("RGB", (w, h), (24, 24, 26))
    canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return canvas


def sheet(n: str) -> str:
    W, H = 560, 315
    cols = list(VIEWS) + ["reference"]
    out = Image.new("RGB", (10 + (W + 10) * len(cols), 40 + (H + 34) * len(PRESETS)), (24, 24, 26))
    d = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    for c, name in enumerate(cols):
        d.text((10 + c * (W + 10), 10), name, fill=(230, 230, 230), font=font)
    for r, preset in enumerate(PRESETS):
        y = 40 + r * (H + 34)
        d.text((10, y), preset, fill=(230, 230, 230), font=font)
        for c, view in enumerate(cols):
            if view == "reference":
                path = os.path.join(root, "references", "elements", "sky", REFS[preset])
                label = REFS[preset]
            else:
                path = f"{shots}/sky_{view}_{preset}.png"
                label = ""
            if os.path.exists(path):
                im = Image.open(path)
                if view != "reference":
                    im = im.crop((0, 110, im.width, im.height - 110))  # the HUD's top and bottom
                out.paste(fit(im, W, H), (10 + c * (W + 10), y + 24))
            if label:
                d.text((10 + c * (W + 10) + 80, y), label, fill=(170, 170, 170), font=font)
    path = os.path.join(root, "references", "elements", "reviews", f"sky_r{n}.jpg")
    out.save(path, quality=85)
    return path


MISSIONS = ["terminal", "hospital", "prefeitura", "batalhao", "mirante"]


def mission_sheet(n: str) -> str:
    """Round 3: the backdrop from each mission's start (the player's own view there), every preset."""
    if "--no-shoot" not in sys.argv:
        for m in MISSIONS:
            shoot("start_" + m, ["--mission=" + m])
    W, H = 440, 248
    out = Image.new("RGB", (10 + (W + 10) * len(PRESETS), 40 + (H + 34) * len(MISSIONS)), (24, 24, 26))
    d = ImageDraw.Draw(out)
    try:
        font = ImageFont.truetype("arial.ttf", 18)
    except OSError:
        font = ImageFont.load_default()
    for c, preset in enumerate(PRESETS):
        d.text((10 + c * (W + 10), 10), preset, fill=(230, 230, 230), font=font)
    for r, m in enumerate(MISSIONS):
        y = 40 + r * (H + 34)
        d.text((10, y), m, fill=(230, 230, 230), font=font)
        for c, preset in enumerate(PRESETS):
            path = f"{shots}/sky_start_{m}_{preset}.png"
            if os.path.exists(path):
                im = Image.open(path)
                out.paste(fit(im.crop((0, 110, im.width, im.height - 110)), W, H), (10 + c * (W + 10), y + 24))
    path = os.path.join(root, "references", "elements", "reviews", f"sky_r{n}_missions.jpg")
    out.save(path, quality=85)
    return path


if __name__ == "__main__":
    n = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("-") else "1"
    if "--no-shoot" not in sys.argv:
        only = [a[7:] for a in sys.argv if a.startswith("--view=")]
        for view, opts in VIEWS.items():
            if not only or view in only:
                shoot(view, opts)
    print(sheet(n))
    if "--missions" in sys.argv:
        print(mission_sheet(n))
