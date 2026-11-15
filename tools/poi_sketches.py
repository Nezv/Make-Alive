"""Isometric blockout sketches of the five Joinville mission maps -> one HTML page.
Usage: python tools/poi_sketches.py references/poi_sketches.html"""
import math, sys, html

C30, S30 = math.cos(math.radians(30)), 0.5
PAL = {
    "concrete": "#8a8a84", "light": "#c9c3b2", "glass": "#5f7d93", "roof": "#6b6f75", "asphalt": "#2c2e32",
    "grass": "#3f6a3a", "forest": "#1f3d24", "water": "#27506e", "olive": "#5b6338", "steel": "#9aa4ad",
    "bus": "#b8862e", "red": "#a8473a", "ground": "#4a4b4d", "sand": "#8f8061", "hill1": "#2d4a2c", "hill2": "#365a33",
    "hill3": "#41693c", "hill4": "#4c7846",
}


def shade(hexc, f):
    h = hexc.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(v * f))) for v in (r, g, b))


class Sketch:
    def __init__(self, s=3.2):
        self.s = s
        self.items = []  # (depth, svg)
        self.over = []   # always on top
        self.pts = []

    def p(self, x, y, z):
        sx = (x - z) * C30 * self.s
        sy = (x + z) * S30 * self.s - y * self.s
        self.pts.append((sx, sy))
        return sx, sy

    def poly(self, pts, fill, stroke="#111", sw=0.6, extra=""):
        d = " ".join("%.1f,%.1f" % self.p(*q) for q in pts)
        return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" %s/>' % (d, fill, stroke, sw, extra)

    def box(self, x, z, w, d, h, color, y=0.0, floors=0):
        c = PAL.get(color, color)
        x1, z1, y1 = x + w, z + d, y + h
        parts = [
            self.poly([(x, y1, z), (x1, y1, z), (x1, y1, z1), (x, y1, z1)], shade(c, 1.15)),
            self.poly([(x, y, z1), (x1, y, z1), (x1, y1, z1), (x, y1, z1)], shade(c, 0.85)),
            self.poly([(x1, y, z), (x1, y, z1), (x1, y1, z1), (x1, y1, z)], shade(c, 0.65)),
        ]
        if floors:
            fh = h / floors
            for k in range(1, floors):
                yy = y + k * fh
                a, b = self.p(x, yy, z1), self.p(x1, yy, z1)
                parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#0006" stroke-width="0.6"/>' % (*a, *b))
                a, b = self.p(x1, yy, z1), self.p(x1, yy, z)
                parts.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="#0006" stroke-width="0.6"/>' % (*a, *b))
        self.items.append((x + w * 0.5 + z + d * 0.5 + y * 3.0, "".join(parts)))

    def flat(self, pts2d, color, y=0.0, depth=-1e9, op=1.0):
        c = PAL.get(color, color)
        self.items.append((depth, self.poly([(a, y, b) for a, b in pts2d], c, stroke="#0008", sw=0.5,
                                            extra='fill-opacity="%s"' % op)))

    def rect(self, x, z, w, d, color, y=0.0, depth=-1e9, op=1.0):
        self.flat([(x, z), (x + w, z), (x + w, z + d), (x, z + d)], color, y, depth, op)

    def path(self, pts3d, color, dash="6 4", w=2.2, arrow=True):
        d = " ".join("%.1f,%.1f" % self.p(*q) for q in pts3d)
        m = ' marker-end="url(#arr-%s)"' % color.lstrip("#") if arrow else ""
        self.over.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="%s" stroke-dasharray="%s"%s/>' % (d, color, w, dash, m))

    def pin(self, x, y, z, text, color, dx=8, dy=-10):
        sx, sy = self.p(x, y, z)
        self.over.append('<circle cx="%.1f" cy="%.1f" r="5" fill="%s" stroke="#000" stroke-width="1"/>' % (sx, sy, color))
        self.label(sx + dx, sy + dy, text, color)

    def note(self, x, y, z, text, dx=6, dy=0, color="#e8e4d8"):
        sx, sy = self.p(x, y, z)
        self.label(sx + dx, sy + dy, text, color, size=10.5)

    def label(self, sx, sy, text, color, size=11.5):
        t = html.escape(text)
        self.over.append('<text x="%.1f" y="%.1f" font-size="%s" fill="%s" stroke="#0b0d10" stroke-width="3" paint-order="stroke" font-weight="600">%s</text>' % (sx, sy, size, color, t))

    def svg(self):
        xs = [a for a, _ in self.pts]
        ys = [b for _, b in self.pts]
        pad = 40
        x0, y0, x1, y1 = min(xs) - pad, min(ys) - pad, max(xs) + pad + 120, max(ys) + pad
        body = "".join(s for _, s in sorted(self.items, key=lambda t: t[0])) + "".join(self.over)
        defs = "<defs>" + "".join(
            '<marker id="arr-%s" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="%s"/></marker>' % (c.lstrip("#"), c)
            for c in (START, GOAL, ZOMB, ROUTE)) + "</defs>"
        return '<svg viewBox="%.0f %.0f %.0f %.0f" xmlns="http://www.w3.org/2000/svg">%s%s</svg>' % (x0, y0, x1 - x0, y1 - y0, defs, body)


START, GOAL, ZOMB, ROUTE = "#99ff66", "#66ccff", "#ff5a4a", "#ffcc66"


def terminal():
    k = Sketch(3.0)
    k.rect(-10, -10, 130, 95, "ground")
    k.rect(-10, 70, 130, 15, "asphalt")            # Rua Nove de Março side
    k.rect(-10, -10, 130, 10, "asphalt")
    for i, zz in enumerate((8, 26, 44)):            # platform islands
        k.rect(10, zz, 80, 6, "light", y=0.3)
    for zz in (16, 34, 52):                          # bus lanes
        k.rect(5, zz - 2, 90, 8, "asphalt", y=0.1)
    for (bx, bz, rot) in ((14, 15, 0), (40, 15, 0), (62, 33, 0), (22, 51, 0), (70, 51, 0)):
        k.box(bx, bz, 12, 3, 3.2, "bus")
    k.box(30, 34, 12, 3, 3.2, "red")                 # burnt-out bus
    for zz in (6, 24, 42):                           # canopies on columns
        for xx in (12, 30, 48, 66, 84):
            k.box(xx, zz + 2.5, 0.6, 0.6, 5.5, "steel")
        k.box(8, zz, 86, 10, 0.6, "roof", y=5.5)
    k.box(96, 4, 20, 56, 7, "concrete", floors=2)    # concourse: tickets, shops, toilets
    k.box(98, 62, 6, 6, 2.2, "olive")                # police booth
    k.pin(104, 7.5, 30, "START: concourse", START)
    k.path([(100, 0.5, 66), (100, 0.5, 78), (125, 0.5, 78)], ROUTE)
    k.note(110, 0, 80, "to Prefeitura, ~1.2 km NE")
    k.note(116, 0, 82, "(checkpoint halfway)", dy=13)
    k.path([(-30, 0.5, 30), (4, 0.5, 30)], ZOMB)
    k.path([(50, 0.5, 100), (50, 0.5, 72)], ZOMB)
    k.note(-36, 0, 22, "hordes from the bus lanes")
    k.note(14, 7, 6, "platform canopies: cover from leapers")
    return k, "Terminal Central", "RUN", [
        "Three platform islands under steel canopies, five buses (one burnt) as cover.",
        "Concourse block on the east side: ticket hall, shops, toilets. Players start inside.",
        "Exit onto Rua Nove de Março, then a street run north-east to the Prefeitura.",
        "Zombies pour in along the open bus lanes at both ends.",
    ]


def hospital():
    k = Sketch(3.0)
    k.rect(-12, -12, 92, 84, "ground")
    k.rect(-12, 60, 92, 12, "asphalt")                       # street
    k.box(0, 20, 60, 34, 8, "concrete", floors=2)            # podium: ER, lobby, imaging
    k.box(10, 0, 40, 22, 27, "light", floors=8)              # ward block, 8 floors
    k.box(46, 4, 7, 7, 31, "concrete")                       # stair core 1 (east)
    k.box(6, 12, 7, 7, 31, "concrete")                       # stair core 2 (west)
    k.box(26, 8, 5, 5, 30, "steel")                          # elevator shaft head
    k.rect(18, 3, 16, 16, "#d8d0bc", y=27.05, depth=1e3)    # helipad
    k.note(23, 27.1, 11, "H", dx=-4, dy=4, color="#1a1a1a")
    k.box(62, 40, 10, 14, 4, "roof")                         # ambulance canopy
    k.box(64, 44, 6, 2.4, 2.6, "#e8e8e8")                    # ambulance
    k.pin(66, 1, 58, "START: ER doors", START)
    k.pin(26, 28, 11, "GOAL: rooftop helipad", GOAL, dx=-150, dy=-14)
    k.path([(64, 0.5, 52), (49, 1, 8), (49, 30, 8)], ROUTE)
    k.note(54, 18, 8, "stairs, floor by floor")
    k.note(28, 20, 10, "elevator shaft (jammed)", dx=-160, dy=30)
    k.path([(-30, 0.5, 66), (-4, 0.5, 66)], ZOMB)
    k.path([(30, 0.5, 90), (30, 0.5, 70)], ZOMB)
    k.note(-36, 0, 58, "street hordes")
    return k, "Hospital Dona Helena", "EXTRACTION · climb", [
        "Two-storey podium (ER, lobby, imaging) under an eight-floor ward block.",
        "Two stair cores and one elevator shaft: the climb is a choke point every floor.",
        "Nurse and doctor zombies inside; street hordes follow you in.",
        "Extraction on the rooftop helipad.",
    ]


def prefeitura():
    k = Sketch(3.0)
    k.rect(-20, -20, 140, 100, "ground")
    k.rect(-40, -20, 18, 100, "water")                        # Rio Cachoeira
    k.rect(-22, -20, 8, 100, "asphalt")                       # riverside avenue
    k.rect(0, 30, 60, 40, "#5b5d60", y=0.05)                  # plaza
    k.box(5, 0, 70, 22, 16, "light", floors=5)               # main block
    k.box(75, 0, 30, 22, 9, "concrete", floors=3)            # annex
    k.box(30, 22, 18, 6, 4, "glass")                         # entrance hall
    for xx in (8, 20, 56, 68):
        k.box(xx, 23, 3, 1, 1.2, "olive")                     # barricade points
    k.rect(18, 42, 18, 18, "#d8d0bc", y=0.1, depth=-1e8)      # LZ on the plaza
    k.note(25, 0.2, 51, "H", dx=-4, dy=4, color="#1a1a1a")
    k.pin(39, 2, 26, "START: main hall", START, dx=10, dy=24)
    k.pin(27, 0.5, 51, "GOAL: hold, then helicopter LZ", GOAL, dx=-210, dy=22)
    for a, b in (((-60, 0.5, 50), (-24, 0.5, 50)), ((40, 0.5, 110), (40, 0.5, 72)), ((140, 0.5, 40), (108, 0.5, 40))):
        k.path([a, b], ZOMB)
    k.note(110, 0, 50, "wave 1 · 2 · 3, from three streets")
    k.note(8, 1.5, 24, "barricade the windows", dx=-150, dy=10)
    return k, "Prefeitura de Joinville", "DEFEND", [
        "Five-storey city hall plus a lower annex, on the east bank of the river.",
        "Ground-floor windows are barricade points; the entrance hall is the last line.",
        "Three waves, each from one more street; the river side stays quiet.",
        "Helicopter lands on the front plaza when the timer runs out.",
    ]


def batalhao():
    k = Sketch(2.4)
    k.flat([(0, 30), (40, 0), (150, 70), (130, 100), (30, 110), (-10, 70)], "sand")     # compound ground
    for i in range(3):
        k.box(10 + i * 4, 40 + i * 16, 50, 10, 6, "olive", floors=2)                  # barracks blocks
    k.rect(70, 50, 45, 32, "#7d7158", y=0.05, depth=-1e8)                               # parade ground
    k.box(40, 10, 22, 12, 5, "concrete")                                                # armoury
    for j in range(3):
        k.box(44 + j * 6, 24, 3, 3, 1.4, "#6b5a2a")                                     # ammo crates
    k.box(110, 50, 5, 5, 9, "concrete")                                                 # guard tower
    k.box(109, 49, 7, 7, 0.4, "olive", y=9)
    k.box(122, 40, 6, 3, 2.2, "olive")                                                  # humvee
    k.box(84, 92, 7, 3, 2.2, "olive")
    k.note(92, 0.2, 66, "H", dx=-4, dy=4, color="#1a1a1a")
    k.pin(112, 9.5, 52, "mounted MG on the gate tower", ROUTE, dx=10)
    k.pin(128, 0.5, 44, "START: main gate", START, dx=12, dy=14)
    k.pin(92, 0.5, 66, "GOAL: hold the parade ground", GOAL, dx=-60, dy=36)
    k.note(50, 5, 16, "armoury: ammo crates", dx=-140, dy=-10)
    for a, b in (((-40, 0.5, 70), (-8, 0.5, 70)), ((60, 0.5, 140), (60, 0.5, 108)), ((180, 0.5, 70), (146, 0.5, 70))):
        k.path([a, b], ZOMB)
    k.note(-50, 0, 60, "soldier zombies over the wall")
    return k, "62º Batalhão de Infantaria", "DEFEND", [
        "Walled compound: three barrack blocks, armoury, parade ground, gate tower.",
        "Ammo crates in the armoury; a mounted machine gun on the gate tower.",
        "Soldier zombies (armoured outfit) climb the walls from three sides.",
        "Helicopter lands on the parade ground.",
    ]


def mirante():
    k = Sketch(1.35)
    # The hill as stepped terraces (each tier ~ 45 m of the 230 m), a switchback road down.
    tiers = [(0, 0, 220, 200, "hill1"), (25, 20, 170, 160, "hill2"), (50, 40, 120, 120, "hill3"), (75, 60, 70, 80, "hill4")]
    for i, (x, z, w, d, c) in enumerate(tiers):
        k.box(x, z, w, d, 10, c, y=i * 10)
    top = 40
    k.box(100, 82, 8, 8, 36, "concrete", y=top)                 # tower
    k.box(96, 78, 16, 16, 1, "roof", y=top + 36)                # deck
    k.box(90, 108, 10, 6, 3.5, "light", y=top)                  # kiosk
    road = [(110, top, 100), (120, top, 130), (150, 30, 150), (190, 20, 160), (180, 10, 190), (120, 10, 195),
            (60, 0, 205), (20, 0, 215), (-20, 0, 220)]
    k.path(road, ROUTE, dash="4 3", w=3)
    k.pin(104, top + 37, 86, "START: tower deck (230 m)", START, dx=10, dy=-6)
    k.pin(-20, 0, 220, "GOAL: foot of the road", GOAL, dx=-40, dy=26)
    k.note(150, 30, 150, "hairpins, forest walls both sides", dx=10)
    k.note(104, top + 18, 86, "narrow stair inside", dx=12)
    k.path([(240, 0.5, 120), (200, 25, 120)], ZOMB)
    k.path([(120, 0.5, -40), (120, 25, 10)], ZOMB)
    k.note(240, 0, 112, "leapers out of the trees")
    return k, "Mirante de Joinville", "EXTRACTION · descend", [
        "Lookout tower on the 230 m summit of Morro da Boa Vista; narrow stair down from the deck.",
        "Rua Pastor Guilherme Rau winds down through thick forest (traced from the topography map).",
        "Leapers jump out of the trees onto the road; the forest is closed to players.",
        "Extraction at the foot of the hill. Needs real terrain height: the city map is still flat.",
    ]


def page(sketches):
    cards = []
    for k, title, kind, notes in sketches:
        lis = "".join("<li>%s</li>" % html.escape(n) for n in notes)
        cards.append('<section><header><h2>%s</h2><span class="kind">%s</span></header>%s<ul>%s</ul></section>'
                     % (html.escape(title), html.escape(kind), k.svg(), lis))
    legend = ('<p class="legend"><b style="color:%s">●</b> start &nbsp; <b style="color:%s">●</b> goal &nbsp; '
              '<b style="color:%s">➜</b> player route &nbsp; <b style="color:%s">➜</b> zombies come from</p>' % (START, GOAL, ROUTE, ZOMB))
    return """<!DOCTYPE html><html><head><meta charset="utf-8"><title>Joinville missions: 3D map sketches</title>
<style>
body{background:#0b0d10;color:#e8e4d8;font:15px/1.45 system-ui,Segoe UI,sans-serif;margin:0;padding:28px 32px}
h1{color:#99ff66;margin:0 0 4px;font-size:28px}.sub{opacity:.6;margin:0 0 6px}
.legend{opacity:.85;margin:0 0 22px}
main{display:grid;grid-template-columns:repeat(auto-fit,minmax(560px,1fr));gap:22px}
section{background:#101317;border:1px solid #2a3138;border-radius:6px;padding:16px 18px}
header{display:flex;align-items:baseline;gap:12px}h2{margin:0;font-size:19px}
.kind{font-size:12px;letter-spacing:.08em;color:#66ccff}
svg{width:100%;height:auto;display:block;margin:8px 0}
ul{margin:4px 0 0;padding-left:18px;opacity:.85}
</style></head><body>
<h1>Joinville missions: 3D map sketches</h1>
<p class="sub">Isometric blockouts, metres roughly to scale per sketch, not between sketches. North is up-left. Planning drawings, not what the game builds today.</p>
""" + legend + "<main>" + "".join(cards) + "</main></body></html>"


if __name__ == "__main__":
    out = sys.argv[1]
    with open(out, "w", encoding="utf-8") as f:
        f.write(page([terminal(), hospital(), prefeitura(), batalhao(), mirante()]))
    print("wrote", out)
