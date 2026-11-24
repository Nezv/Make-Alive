r"""The town's review sheet (S043): the five city_ shots (tools\shots.ps1 city_) beside the
references on references/elements/city_blocks.md.  python tools/city_review.py [round]"""
import sys
from PIL import Image, ImageDraw, ImageFont

import os
root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
out = f"{root}/references/elements/reviews/city_blocks_r{sys.argv[1] if len(sys.argv) > 1 else 2}.jpg"
shots = ["city_hill", "city_roofs", "city_bridge", "city_marche", "city_core_street"]
refs = ["caillebotte_toits", "turgot_sheet10", "marville_rue_tiquetonne", "paris_roofs", "rouen_rue_aux_ours"]
W, H = 800, 450
sheet = Image.new("RGB", (W * 2 + 30, (H + 40) * len(shots) + 20), (24, 24, 26))
d = ImageDraw.Draw(sheet)
try:
    font = ImageFont.truetype("arial.ttf", 20)
except OSError:
    font = ImageFont.load_default()


def fit(im, w, h):
    im = im.convert("RGB")
    r = min(w / im.width, h / im.height)
    im = im.resize((int(im.width * r), int(im.height * r)))
    canvas = Image.new("RGB", (w, h), (24, 24, 26))
    canvas.paste(im, ((w - im.width) // 2, (h - im.height) // 2))
    return canvas


for i, (s, r) in enumerate(zip(shots, refs)):
    y = 10 + i * (H + 40)
    shot = Image.open(f"{root}/references/shots/{s}.png")
    shot = shot.crop((0, 110, shot.width, shot.height - 110))  # the HUD's top and bottom
    sheet.paste(fit(shot, W, H), (10, y + 30))
    sheet.paste(fit(Image.open(f"{root}/references/elements/city_blocks/{r}.jpg"), W, H), (W + 20, y + 30))
    d.text((10, y + 4), s, fill=(230, 230, 230), font=font)
    d.text((W + 20, y + 4), r, fill=(230, 230, 230), font=font)
sheet.save(out, quality=85)
print(out, sheet.size)
