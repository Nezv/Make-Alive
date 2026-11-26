"""Draw the house floors laid out by HousePlan (S244) from the JSON `--house-plans` writes.

    python tools/house_plans.py references/shots/houses/houses.json

Writes beside the JSON:
  house_floors.png    the sample house, every floor side by side, large: rooms in their floor and
                      wall colours (the band round each room is its wall paint, the inner line its
                      dado), doors with their leaves and swings, windows, the stair's flights, the
                      lamps (yellow), switches (black dots), furniture slots by name, the flues,
                      a player-sized disc for scale and a legend.
  house_variants.png  the other houses, each floor smaller, to judge the spread of layouts.
Run by tools\\houses.ps1 after the Godot export. Needs Pillow.
"""
import json
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFont

FLOOR_NAMES = ["rez-de-chaussée", "1er étage", "2e étage", "3e étage", "4e étage", "5e étage"]
WALL = (43, 41, 38)
BACKGROUND = (236, 233, 226)
INK = (30, 28, 26)
GLASS = (120, 180, 210)
LAMP = (255, 196, 40)
FURNITURE = {
    "lit": (196, 178, 150), "chevet": (120, 84, 58), "armoire": (96, 66, 46), "commode": (140, 98, 66),
    "canape": (128, 86, 74), "fauteuil": (140, 100, 84), "table_basse": (150, 110, 74), "table": (150, 110, 74),
    "bibliotheque": (90, 62, 44), "buffet": (126, 88, 60), "vaisselier": (110, 78, 54), "piano": (40, 34, 30),
    "cheminee": (226, 220, 206), "cuisiniere": (60, 58, 56), "evier": (190, 184, 170), "plan": (166, 132, 92),
    "cuvette": (250, 250, 246), "lave_mains": (250, 250, 246), "lavabo": (250, 250, 246), "baignoire": (240, 238, 230),
    "etagere": (150, 118, 82), "caisse": (150, 122, 82), "comptoir": (90, 62, 42), "rayonnage": (140, 108, 74),
    "vitrine": (170, 200, 206), "etabli": (130, 98, 62), "console": (130, 92, 62), "portemanteau": (100, 72, 50),
    "bureau": (120, 86, 58), "chaise": (140, 104, 72),
}
SHORT = {
    "lit": "lit", "chevet": "chv", "armoire": "armoire", "commode": "commode", "canape": "canapé",
    "fauteuil": "fauteuil", "table_basse": "t. basse", "table": "table", "bibliotheque": "biblio.", "buffet": "buffet",
    "vaisselier": "vaissel.", "piano": "piano", "cheminee": "cheminée", "cuisiniere": "fourneau", "evier": "évier",
    "plan": "plan", "cuvette": "wc", "lave_mains": "l-m", "lavabo": "lavabo", "baignoire": "baignoire",
    "etagere": "étag.", "caisse": "caisse", "comptoir": "comptoir", "rayonnage": "rayons", "vitrine": "vitrine",
    "etabli": "établi", "console": "console", "portemanteau": "pt-m", "bureau": "bureau", "chaise": "ch.",
}


def font(size, bold=False):
    names = ["segoeuib.ttf", "arialbd.ttf"] if bold else ["segoeui.ttf", "arial.ttf"]
    for n in names:
        for d in [r"C:\Windows\Fonts", "/usr/share/fonts/truetype/dejavu"]:
            p = os.path.join(d, n)
            if os.path.exists(p):
                return ImageFont.truetype(p, size)
    try:
        return ImageFont.load_default(size)
    except TypeError:
        return ImageFont.load_default()


def rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


class Plan:
    """One floor drawn at (ox, oy) with s pixels a metre; the street at the bottom."""

    def __init__(self, img, house, floor, ox, oy, s, detail=True):
        self.img = img
        self.d = ImageDraw.Draw(img, "RGBA")
        self.h = house
        self.f = floor
        self.ox = ox
        self.oy = oy
        self.s = s
        self.detail = detail
        self.party = house["party"]
        self.facade = house["facade"]
        self.depth = house["depth"]
        self.width = house["width"]
        self.spaces = {sp["id"]: sp for sp in floor["spaces"]}

    def p(self, x, z):
        return (self.ox + (x + self.party) * self.s, self.oy + (self.depth + self.facade - z) * self.s)

    def rect(self, r, **kw):
        x, z, w, d = r
        a = self.p(x, z + d)
        b = self.p(x + w, z)
        self.d.rectangle([a, b], **kw)

    def size(self):
        return ((self.width + 2 * self.party) * self.s, (self.depth + 2 * self.facade) * self.s)

    def draw(self):
        self.rect([-self.party, -self.facade, self.width + 2 * self.party, self.depth + 2 * self.facade], fill=WALL)
        for sp in self.f["spaces"]:
            self.space(sp)
        for d in self.f["doors"]:
            self.door(d)
        for w in self.f["windows"]:
            self.window(w)
        self.stair()
        if self.detail:
            for sp in self.f["spaces"]:
                self.furniture(sp)
            for sp in self.f["spaces"]:
                self.lamps(sp)
            self.flues()
        for sp in self.f["spaces"]:
            self.label(sp)
        if self.detail:
            self.player()

    def space(self, sp):
        paint = sp["paint"]
        floor = rgb(paint.get("floor_colour", "#999999")) if paint else (150, 150, 150)
        wall = rgb(paint.get("wall", "#aaaaaa")) if paint else (170, 170, 170)
        for r in sp["rects"]:
            self.rect(r, fill=mix(floor, (255, 255, 255), 0.55))
            band = min(0.16, r[2] * 0.2, r[3] * 0.2)
            x, z, w, d = r
            for strip in ([x, z, band, d], [x + w - band, z, band, d], [x, z, w, band], [x, z + d - band, w, band]):
                self.rect(strip, fill=wall)
            if paint and paint.get("lower_h", 0) > 0 and "lower" in paint and self.detail:
                lo = rgb(paint["lower"])
                inner = [x + band, z + band, w - 2 * band, d - 2 * band]
                self.rect(inner, outline=lo, width=max(1, int(self.s * 0.03)))

    def door(self, d):
        t = d["t"]
        if d["axis"] == "x":
            gap = [d["at"] - t / 2, d["from"], t, d["to"] - d["from"]]
        else:
            gap = [d["from"], d["at"] - t / 2, d["to"] - d["from"], t]
        into = self.spaces.get(d["swing"]) or self.spaces.get(d["a"])
        col = rgb(into["paint"]["floor_colour"]) if into and into.get("paint") else (200, 200, 200)
        self.rect(gap, fill=mix(col, (255, 255, 255), 0.55))
        if d["swing"] < 0 or d["swing"] not in self.spaces:
            ends = (gap[0], gap[1], gap[0] + gap[2], gap[1] + gap[3])
            self.d.line([self.p(ends[0], ends[1]), self.p(ends[2], ends[3])], fill=(90, 80, 70, 160), width=1)
            return
        room = self.spaces[d["swing"]]["rect"]
        w = d["to"] - d["from"]
        if d["axis"] == "x":
            sgn = 1 if room[0] + room[2] / 2 > d["at"] else -1
            hx, hz = d["at"] + sgn * t / 2, d["hinge"]
            closed = (0, w if d["hinge"] <= d["from"] + 1e-3 else -w)
            open_ = (sgn * w, 0)
        else:
            sgn = 1 if room[1] + room[3] / 2 > d["at"] else -1
            hx, hz = d["hinge"], d["at"] + sgn * t / 2
            closed = (w if d["hinge"] <= d["from"] + 1e-3 else -w, 0)
            open_ = (0, sgn * w)
        lw = max(1, int(self.s * 0.035))
        self.d.line([self.p(hx, hz), self.p(hx + open_[0], hz + open_[1])], fill=INK, width=lw)
        pts = []
        for k in range(13):
            a = k / 12 * math.pi / 2
            pts.append(self.p(hx + closed[0] * math.cos(a) + open_[0] * math.sin(a), hz + closed[1] * math.cos(a) + open_[1] * math.sin(a)))
        self.d.line(pts, fill=(30, 28, 26, 120), width=1)

    def window(self, w):
        f = self.facade
        z = -f if w["side"] == "front" else self.depth
        r = [w["from"], z, w["to"] - w["from"], f]
        col = GLASS if w["kind"] != "stair" else (150, 190, 205)
        self.rect(r, fill=mix(col, (255, 255, 255), 0.35))
        mid = z + f / 2
        self.d.line([self.p(w["from"], mid), self.p(w["to"], mid)], fill=(40, 90, 120), width=max(1, int(self.s * 0.03)))
        if w["kind"] == "french":
            c = (w["from"] + w["to"]) / 2
            self.d.line([self.p(c, z), self.p(c, z + f)], fill=(40, 90, 120), width=1)

    def stair(self):
        fr = self.h["frame"]
        up, back, mid = fr["up"], fr["back_flight"], fr["mid"]
        tread = (up[3]) / max(1, fr["risers"] // 2 - 1)
        top = self.f["level"] == len(self.h["floors"]) - 1
        for r, going_up in ((up, True), (back, False)):
            if top and going_up:
                self.rect(r, fill=(70, 66, 60))
                continue
            self.rect(r, fill=(205, 190, 168) if going_up else (180, 166, 146))
            n = fr["risers"] // 2 - 1
            for k in range(n + 1):
                z = r[1] + k * tread
                self.d.line([self.p(r[0], z), self.p(r[0] + r[2], z)], fill=(110, 90, 70), width=1)
        if not top:
            self.rect(mid, fill=(196, 180, 156))
            cx = up[0] + up[2] / 2
            self.arrow(cx, up[1] + 0.15, cx, up[1] + up[3] - 0.1)
            if self.detail:
                self.text(cx, up[1] + up[3] / 2, "monte", font(max(9, int(self.s * 0.14))), (80, 60, 40), rotate=True)

    def arrow(self, x0, z0, x1, z1):
        a, b = self.p(x0, z0), self.p(x1, z1)
        self.d.line([a, b], fill=(80, 60, 40), width=max(1, int(self.s * 0.03)))
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        L = self.s * 0.18
        for k in (-0.5, 0.5):
            self.d.line([b, (b[0] - L * math.cos(ang + k), b[1] - L * math.sin(ang + k))], fill=(80, 60, 40), width=max(1, int(self.s * 0.03)))

    def furniture(self, sp):
        f = font(max(8, int(self.s * 0.13)))
        for it in sp["furniture"]:
            col = FURNITURE.get(it["item"], (140, 110, 80))
            x, z, w, d = it["rect"]
            self.rect(it["rect"], fill=col + (200,), outline=(40, 34, 30), width=1)
            fx, fz = it["facing"]
            c = (x + w / 2, z + d / 2)
            if abs(fx) > 0.5:
                e = x + w if fx > 0 else x
                self.d.line([self.p(e, z), self.p(e, z + d)], fill=(255, 255, 255, 170), width=max(1, int(self.s * 0.03)))
            else:
                e = z + d if fz > 0 else z
                self.d.line([self.p(x, e), self.p(x + w, e)], fill=(255, 255, 255, 170), width=max(1, int(self.s * 0.03)))
            label = SHORT.get(it["item"], it["item"])
            tw = f.getlength(label)
            long_px = max(w, d) * self.s
            if tw < long_px - 4 and min(w, d) * self.s > f.size + 1:
                dark = sum(col) < 330
                self.text(c[0], c[1], label, f, (245, 240, 230) if dark else (40, 34, 30), rotate=d > w * 1.3 and tw > w * self.s - 4)

    def lamps(self, sp):
        r = max(3, self.s * 0.11)
        for l in sp["lights"]:
            x, y, z = l["pos"]
            cx, cy = self.p(x, z)
            rr = r * (1.4 if l["kind"] == "lustre" else (0.6 if l["kind"] == "applique" else 1.0))
            self.d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], fill=LAMP, outline=(120, 80, 0))
            if l["kind"] in ("lustre", "suspension"):
                for k in range(8):
                    a = k * math.pi / 4
                    self.d.line([(cx + math.cos(a) * rr * 1.2, cy + math.sin(a) * rr * 1.2), (cx + math.cos(a) * rr * 1.9, cy + math.sin(a) * rr * 1.9)], fill=(200, 140, 0), width=1)
        for sw in sp["switches"]:
            x, y, z = sw["pos"]
            cx, cy = self.p(x, z)
            k = max(2, self.s * 0.05)
            self.d.rectangle([cx - k, cy - k, cx + k, cy + k], fill=INK)

    def flues(self):
        for fl in self.h["frame"]["flues"]:
            x = fl["x"] - self.party / 2 if fl["x"] < 0.1 else fl["x"] + self.party / 2
            cx, cy = self.p(x, fl["z"])
            k = self.s * 0.09
            self.d.rectangle([cx - k, cy - k * 2, cx + k, cy + k * 2], fill=(150, 60, 40), outline=(255, 220, 200))

    def label(self, sp):
        kind = self.h["kinds"][sp["kind"]]["label"] if sp["kind"] in self.h["kinds"] else sp["kind"]
        if sp["kind"] == "stair":
            return
        x, z, w, d = sp["rect"]
        f = font(max(9, int(self.s * (0.19 if self.detail else 0.22))), bold=True)
        small = font(max(8, int(self.s * 0.14)))
        tall = d > w * 1.6 and f.getlength(kind) > w * self.s - 6
        cx, cz = x + w / 2, z + d / 2
        if self.detail:
            self.text(cx, cz + (0 if tall else 0.12), kind, f, INK, rotate=tall, plate=True)
            if not tall:
                self.text(cx, cz - 0.2, "%.1f m²" % sp["area"], small, (70, 64, 58), plate=True)
        else:
            self.text(cx, cz, kind, f, INK, rotate=tall)

    def player(self):
        for sp in self.f["spaces"]:
            if sp["kind"] in ("corridor", "entree", "allee"):
                x, z, w, d = sp["rect"]
                r = self.h["player"]["radius"]
                cx, cy = self.p(x + w / 2, z + d * 0.62)
                rr = r * self.s
                self.d.ellipse([cx - rr, cy - rr, cx + rr, cy + rr], outline=(200, 40, 40), width=max(1, int(self.s * 0.03)))
                self.d.line([(cx, cy - rr), (cx, cy + rr)], fill=(200, 40, 40), width=1)
                return

    def text(self, x, z, s, f, col, rotate=False, plate=False):
        cx, cy = self.p(x, z)
        if not rotate:
            tw = f.getlength(s)
            if plate:
                self.d.rectangle([cx - tw / 2 - 2, cy - f.size * 0.62, cx + tw / 2 + 2, cy + f.size * 0.62], fill=(255, 255, 255, 150))
            self.d.text((cx, cy), s, font=f, fill=col, anchor="mm")
            return
        tw = int(f.getlength(s)) + 6
        tile = Image.new("RGBA", (tw, f.size + 6), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile)
        if plate:
            td.rectangle([0, 0, tw, f.size + 6], fill=(255, 255, 255, 150))
        td.text((tw / 2, (f.size + 6) / 2), s, font=f, fill=col, anchor="mm")
        tile = tile.rotate(90, expand=True)
        self.img.paste(tile, (int(cx - tile.width / 2), int(cy - tile.height / 2)), tile)


def legend(d, x, y):
    f = font(15)
    b = font(17, bold=True)
    d.text((x, y), "Légende", font=b, fill=INK)
    y += 30
    rows = [
        ("rect", (190, 175, 160), "pièce : sol (fond), peinture (bande), soubassement (filet)"),
        ("glass", GLASS, "fenêtre (2 traits : porte-fenêtre)"),
        ("door", INK, "porte : battant ouvert et débattement"),
        ("lamp", LAMP, "luminaire (gros : lustre / suspension)"),
        ("switch", INK, "interrupteur, côté gâche"),
        ("flue", (150, 60, 40), "conduit de cheminée (fixe, dans le mur mitoyen)"),
        ("player", (200, 40, 40), "le joueur (rayon 0,4 m) pour l'échelle"),
        ("rect", (150, 110, 74), "emplacement de meuble (trait blanc : sa face)"),
    ]
    for kind, col, txt in rows:
        if kind == "rect":
            d.rectangle([x, y + 2, x + 22, y + 16], fill=col, outline=INK)
        elif kind == "glass":
            d.rectangle([x, y + 5, x + 22, y + 13], fill=col)
        elif kind == "door":
            d.line([(x + 2, y + 16), (x + 2, y + 2)], fill=col, width=2)
            d.arc([x - 12, y + 2, x + 16, y + 30], 270, 360, fill=col)
        elif kind == "lamp":
            d.ellipse([x + 4, y + 2, x + 18, y + 16], fill=col, outline=(120, 80, 0))
        elif kind == "switch":
            d.rectangle([x + 8, y + 6, x + 14, y + 12], fill=col)
        elif kind == "flue":
            d.rectangle([x + 7, y, x + 15, y + 18], fill=col)
        elif kind == "player":
            d.ellipse([x + 3, y + 1, x + 19, y + 17], outline=col, width=2)
        d.text((x + 32, y), txt, font=f, fill=INK)
        y += 26
    return y


def caption(house, floor):
    name = FLOOR_NAMES[floor["level"]] if floor["level"] < len(FLOOR_NAMES) else "étage %d" % floor["level"]
    return "%s  ·  %d essai%s" % (name, floor["tries"], "s" if floor["tries"] > 1 else "")


def sample_sheet(house, path):
    s = 64
    floors = house["floors"]
    w = (house["width"] + 2 * house["party"]) * s
    h = (house["depth"] + 2 * house["facade"]) * s
    gap = 60
    W = int(len(floors) * (w + gap) + gap + 520)
    H = int(h + 230)
    img = Image.new("RGB", (W, H), BACKGROUND)
    d = ImageDraw.Draw(img)
    spec = house["spec"]
    title = font(26, bold=True)
    d.text((gap, 18), "Maison de %d travées, %.2f × %.2f m, %d niveaux de %.2f m (graine %d) — escalier %s" % (
        spec["bays"], spec["width"], spec["depth"], spec["floors"], spec["storey"], spec["seed"],
        "entre les deux corps" if house["frame"]["variant"] == "middle" else "sur cour"), font=title, fill=INK)
    sub = font(16)
    d.text((gap, 54), "Fixe à chaque niveau : façades et travées, porte d'entrée, cage d'escalier, murs de refend, conduits. "
           "Tiré au sort par niveau : cloisons, pièces, portes, peinture, luminaires, meubles.", font=sub, fill=(70, 64, 58))
    for i, f in enumerate(floors):
        ox = gap + i * (w + gap)
        oy = 110
        Plan(img, house, f, ox, oy, s).draw()
        d.text((ox, oy + h + 10), caption(house, f), font=font(19, bold=True), fill=INK)
        d.text((ox, oy + h + 36), "rue ↓", font=font(15), fill=(90, 84, 76))
        if not f.get("ok", True):
            d.text((ox, oy + h + 60), "ÉCHEC : " + f.get("problem", ""), font=font(15, bold=True), fill=(190, 30, 30))
        # a metre for scale
        d.line([(ox + w - s - 4, oy + h + 22), (ox + w - 4, oy + h + 22)], fill=INK, width=3)
        d.text((ox + w - s / 2 - 4, oy + h + 34), "1 m", font=font(14), fill=INK, anchor="mm")
    y = legend(d, int(len(floors) * (w + gap) + gap), 110)
    paint = font(14)
    y += 20
    d.text((int(len(floors) * (w + gap) + gap), y), "Peintures (mur · sol) par pièce", font=font(17, bold=True), fill=INK)
    y += 28
    x0 = int(len(floors) * (w + gap) + gap)
    for f in floors:
        d.text((x0, y), FLOOR_NAMES[f["level"]], font=font(15, bold=True), fill=INK)
        y += 22
        for sp in f["spaces"]:
            p = sp["paint"]
            if not p:
                continue
            d.rectangle([x0, y, x0 + 18, y + 14], fill=rgb(p["wall"]), outline=INK)
            if "lower" in p:
                d.rectangle([x0 + 20, y, x0 + 38, y + 14], fill=rgb(p["lower"]), outline=INK)
            d.rectangle([x0 + 40, y, x0 + 58, y + 14], fill=rgb(p["floor_colour"]), outline=INK)
            extra = []
            if p.get("panels"):
                extra.append("boiseries")
            if p.get("paper"):
                extra.append("papier peint, " + p.get("paper_pattern", ""))
            if p.get("cornice"):
                extra.append("corniche")
            name = house["kinds"][sp["kind"]]["label"]
            d.text((x0 + 66, y - 2), "%s — %s%s%s" % (name, p["floor"], (" " + p["pattern"]) if "pattern" in p else "",
                    (" · " + ", ".join(extra)) if extra else ""), font=paint, fill=INK)
            y += 18
        y += 8
    img.save(path)
    return path


def variants_sheet(houses, path):
    s = 30
    rows = []
    for h in houses:
        w = (h["width"] + 2 * h["party"]) * s
        hh = (h["depth"] + 2 * h["facade"]) * s
        rows.append((h, w, hh))
    gap = 30
    W = int(max(len(h["floors"]) * (w + gap) for h, w, _ in rows) + gap + 360)
    H = int(sum(hh + 70 for _, _, hh in rows) + 60)
    img = Image.new("RGB", (W, H), BACKGROUND)
    d = ImageDraw.Draw(img)
    d.text((gap, 14), "Variantes : d'autres maisons, d'autres graines", font=font(22, bold=True), fill=INK)
    y = 60
    for h, w, hh in rows:
        spec = h["spec"]
        d.text((gap, y), "%d travées, %.2f × %.2f m, %.2f m d'étage, porte à %s, %s, graine %d — escalier %s%s" % (
            spec["bays"], spec["width"], spec["depth"], spec["storey"], "gauche" if spec["door"] == "left" else "droite",
            "boutique" if spec["shop"] else "logement au rez", spec["seed"],
            ("entre les corps" if h["frame"].get("variant") == "middle" else "sur cour") if h["ok"] or h["frame"].get("variant") else "",
            "" if h["ok"] else "   ÉCHEC : " + h["problem"]), font=font(15, bold=not h["ok"]), fill=INK if h["ok"] else (190, 30, 30))
        y += 24
        for i, f in enumerate(h["floors"]):
            ox = gap + i * (w + gap)
            Plan(img, h, f, ox, y, s, detail=False).draw()
            d.text((ox, y + hh + 2), caption(h, f), font=font(12), fill=(70, 64, 58))
        y += hh + 46
    img.save(path)
    return path


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else os.path.join("references", "shots", "houses", "houses.json")
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    out = os.path.dirname(os.path.abspath(path))
    print("[houses] drew", sample_sheet(data["sample"], os.path.join(out, "house_floors.png")))
    if data.get("variants"):
        print("[houses] drew", variants_sheet(data["variants"], os.path.join(out, "house_variants.png")))


if __name__ == "__main__":
    main()
