"""Trace Joinville's streets from references/joinville.png into scripts/world/city_streets.gd.

The street fills of joinville.png (white, yellow and orange in its OpenStreetMap style) are masked,
closed over the labels written on them, thinned to one pixel, cut into a graph at the junctions,
cleared of the short spurs labels leave, simplified, and chained into streets that run straight on
through junctions. A street is a main one (`principale`) where it runs under the red bus-route lines of
references/joinville_main_streets.png (the same view at the same scale, shifted by MAIN_SHIFT, found by
cross-correlating the two pictures' edges: the same in all four quarters), otherwise a `rue`. Every
street gets an invented French name. references/streets_on_reference.png draws them over joinville.png
(main streets red, the rest blue) to check by eye.

    python tools/trace_streets.py
"""
import math
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = os.path.join(ROOT, "references")
SRC = os.path.join(REF, "joinville.png")
MAIN = os.path.join(REF, "joinville_main_streets.png")
OUT = os.path.join(ROOT, "scripts", "world", "city_streets.gd")
OVERLAY = os.path.join(REF, "streets_on_reference.png")

MAIN_SHIFT = (2, -4)          # main-streets pixel + MAIN_SHIFT = joinville.png pixel (to the pixel)
MASK_OUT = [(0, 0, 350, 50), (1875, 0, 1920, 370), (0, 975, 110, 1025), (1460, 1000, 1920, 1025)]  # site bars, buttons, scale, credits
STREET_FILLS = [(255, 255, 255), (254, 254, 254), (252, 214, 164), (247, 250, 191), (247, 250, 190), (255, 255, 229)]
MIN_SPUR = 14                 # px: dangling branches shorter than this are labels or driveways, not streets
MIN_KEEP = 18                 # px: a whole street shorter than this is dropped
SIMPLIFY = 1.0                # px: Douglas-Peucker tolerance, after SMOOTH
SMOOTH = 4                    # px each side: the pixel path is averaged over this before simplifying
REACH = 12                    # px: a dead end carries on this far to meet the street it points at
MERGE_JUNCTIONS = 5           # px: junction pixels closer than this are one junction
STRAIGHT_ON = 35.0            # degrees: a street runs on through a junction if it bends less than this
MAIN_NEAR = 4                 # px: how close to a bus-route line a main street's points lie
MAIN_SHARE = 0.7              # of a street's length under bus routes to call it main


def street_mask():
    a = np.asarray(Image.open(SRC).convert("RGB")).astype(int)
    m = np.zeros(a.shape[:2], bool)
    for c in STREET_FILLS:
        m |= np.abs(a - np.array(c)).sum(2) <= 6
    # Labels are written over the streets in dark grey: where one lies on a street it is street.
    text = a.max(2) < 150
    m |= text & ndimage.binary_dilation(m, iterations=3)
    for x0, y0, x1, y1 in MASK_OUT:
        m[y0:y1, x0:x1] = False
    m = ndimage.binary_closing(m, structure=disk(2), iterations=1)
    m = ndimage.binary_opening(m, structure=np.ones((2, 2)))
    lab, n = ndimage.label(m)
    sizes = ndimage.sum(m, lab, range(1, n + 1))
    keep = np.zeros(n + 1, bool)
    keep[1:] = sizes > 150
    return keep[lab]


def disk(r):
    y, x = np.mgrid[-r:r + 1, -r:r + 1]
    return x * x + y * y <= r * r + r


def main_mask():
    """The bus-route lines, in joinville.png pixels, grown by MAIN_NEAR."""
    a = np.asarray(Image.open(MAIN).convert("RGB")).astype(int)
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    m = (r > 190) & (r - g > 70) & (r - b > 70) & (abs(g - b) < 40)
    m = ndimage.binary_closing(m, structure=np.ones((5, 5)))
    out = np.zeros((1020, 1920), bool)
    dx, dy = MAIN_SHIFT
    h, w = m.shape
    ys, xs = np.nonzero(m)
    ys, xs = ys + dy, xs + dx
    ok = (ys >= 0) & (ys < out.shape[0]) & (xs >= 0) & (xs < out.shape[1])
    out[ys[ok], xs[ok]] = True
    return ndimage.binary_dilation(out, iterations=MAIN_NEAR)


def thin(m):
    """Zhang-Suen thinning."""
    img = np.pad(m.astype(np.uint8), 1)
    while True:
        changed = False
        for step in (0, 1):
            p = img
            P2, P3, P4 = p[:-2, 1:-1], p[:-2, 2:], p[1:-1, 2:]
            P5, P6, P7 = p[2:, 2:], p[2:, 1:-1], p[2:, :-2]
            P8, P9 = p[1:-1, :-2], p[:-2, :-2]
            nb = [P2, P3, P4, P5, P6, P7, P8, P9]
            B = sum(x.astype(int) for x in nb)
            seq = nb + [P2]
            A = sum(((seq[i] == 0) & (seq[i + 1] == 1)).astype(int) for i in range(8))
            c = p[1:-1, 1:-1] == 1
            if step == 0:
                cond = c & (B >= 2) & (B <= 6) & (A == 1) & (P2 * P4 * P6 == 0) & (P4 * P6 * P8 == 0)
            else:
                cond = c & (B >= 2) & (B <= 6) & (A == 1) & (P2 * P4 * P8 == 0) & (P2 * P6 * P8 == 0)
            if cond.any():
                img[1:-1, 1:-1][cond] = 0
                changed = True
        if not changed:
            return img[1:-1, 1:-1].astype(bool)


NB8 = [(-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1)]


def graph(sk):
    """Cut the skeleton into edges between junction / end clusters. Returns nodes {id: (x, y)} and
    edges [(a, b, [(x, y), ...])]."""
    h, w = sk.shape
    pts = set(zip(*np.nonzero(sk)))
    def nbs(p):
        return [(p[0] + dy, p[1] + dx) for dy, dx in NB8 if (p[0] + dy, p[1] + dx) in pts]
    deg = {p: len(nbs(p)) for p in pts}
    special = {p for p in pts if deg[p] != 2}
    # Cluster special pixels into nodes.
    sm = np.zeros_like(sk)
    for y, x in special:
        sm[y, x] = True
    lab, n = ndimage.label(ndimage.binary_dilation(sm, iterations=MERGE_JUNCTIONS // 2))
    node_of = {}
    nodes = {}
    for y, x in special:
        k = int(lab[y, x])
        node_of[(y, x)] = k
    for k in range(1, n + 1):
        ys, xs = np.nonzero((lab == k) & sm)
        if len(ys):
            nodes[k] = (float(xs.mean()), float(ys.mean()))
    # Pixels inside a node's blob belong to it.
    for p in pts:
        k = int(lab[p])
        if k and k in nodes:
            node_of[p] = k
    edges = []
    seen = set()
    for p in pts:
        if p not in node_of:
            continue
        for q in nbs(p):
            if q in node_of or (p, q) in seen:
                continue
            path = [p, q]
            seen.add((p, q))
            prev, cur = p, q
            while cur not in node_of:
                nxt = [r for r in nbs(cur) if r != prev and r not in path[-3:]]
                if not nxt:
                    break
                prev, cur = cur, nxt[0]
                path.append(cur)
            if cur in node_of:
                seen.add((cur, prev))
                a, b = node_of[p], node_of[cur]
                line = [nodes[a]] + [(float(x), float(y)) for y, x in path[1:-1]] + [nodes[b]]
                edges.append([a, b, line])
    # Drop loops of a node onto itself that are tiny, and duplicate edges.
    out = []
    keys = set()
    for a, b, line in edges:
        key = (min(a, b), max(a, b), round(length(line)))
        if key in keys:
            continue
        keys.add(key)
        if a == b and length(line) < 40:
            continue
        out.append([a, b, line])
    return nodes, out


def length(line):
    return sum(math.dist(line[i], line[i + 1]) for i in range(len(line) - 1))


def prune(nodes, edges):
    """Drop short dangling edges (label spurs) until none is left, then merge through degree-2 nodes."""
    while True:
        deg = {}
        for a, b, _ in edges:
            deg[a] = deg.get(a, 0) + 1
            deg[b] = deg.get(b, 0) + 1
        drop = [e for e in edges if (deg[e[0]] == 1 or deg[e[1]] == 1) and deg[e[0]] + deg[e[1]] > 2
            and length(e[2]) < MIN_SPUR]
        if not drop:
            break
        for e in drop:
            edges.remove(e)
    edges = merge_deg2(edges)
    return [e for e in edges if length(e[2]) >= MIN_KEEP or not dangling(e, edges)]


def dangling(e, edges):
    deg = {}
    for a, b, _ in edges:
        deg[a] = deg.get(a, 0) + 1
        deg[b] = deg.get(b, 0) + 1
    return deg[e[0]] == 1 or deg[e[1]] == 1


def merge_deg2(edges):
    while True:
        deg = {}
        for a, b, _ in edges:
            deg[a] = deg.get(a, 0) + 1
            deg[b] = deg.get(b, 0) + 1
        k = next((n for n, d in deg.items() if d == 2 and sum(1 for e in edges if n in (e[0], e[1]) and e[0] != e[1]) == 2), None)
        if k is None:
            return edges
        e1, e2 = [e for e in edges if k in (e[0], e[1])]
        edges.remove(e1)
        edges.remove(e2)
        l1 = e1[2] if e1[1] == k else e1[2][::-1]
        a = e1[0] if e1[1] == k else e1[1]
        l2 = e2[2] if e2[0] == k else e2[2][::-1]
        b = e2[1] if e2[0] == k else e2[0]
        edges.append([a, b, l1 + l2[1:]])


def smooth(line):
    """Average the pixel path over SMOOTH each side, keeping its ends."""
    if len(line) < 3:
        return line
    pts = np.array(line)
    out = [tuple(pts[0])]
    for i in range(1, len(pts) - 1):
        k = min(SMOOTH, i, len(pts) - 1 - i)
        out.append(tuple(pts[i - k:i + k + 1].mean(0)))
    out.append(tuple(pts[-1]))
    return out


def extend_dead_ends(streets):
    """A street that stops just short of another (a label or a stop broke the line) carries on along
    its last stretch until it meets it, within REACH."""
    def hit(o, d, skip):
        best = None
        for j, t in enumerate(streets):
            for i in range(len(t) - 1):
                if j == skip and (i < 2 or i > len(t) - 4):
                    continue
                ax, ay = t[i]
                bx, by = t[i + 1]
                ex, ey = bx - ax, by - ay
                den = d[0] * ey - d[1] * ex
                if abs(den) < 1e-9:
                    continue
                u = ((ax - o[0]) * ey - (ay - o[1]) * ex) / den
                v = ((ax - o[0]) * d[1] - (ay - o[1]) * d[0]) / den
                if 0.3 < u <= REACH and -0.01 <= v <= 1.01 and (best is None or u < best):
                    best = u
        return best
    for k, s in enumerate(streets):
        for end in (0, -1):
            p = s[end]
            q = s[1] if end == 0 else s[-2]
            for back in (s[min(3, len(s) - 1)] if end == 0 else s[max(-4, -len(s))],):
                q = back
            dx, dy = p[0] - q[0], p[1] - q[1]
            n = math.hypot(dx, dy)
            if n < 1e-6:
                continue
            d = (dx / n, dy / n)
            # Another street's end straight ahead (both broken at the same stop): bridge the two.
            bridge = None
            for j, t in enumerate(streets):
                if j == k:
                    continue
                for q in (t[0], t[-1]):
                    gx, gy = q[0] - p[0], q[1] - p[1]
                    g = math.hypot(gx, gy)
                    if 0.3 < g <= 2 * REACH and (gx * d[0] + gy * d[1]) / g > math.cos(math.radians(25)):
                        if bridge is None or g < bridge[0]:
                            bridge = (g, q)
            if bridge is not None:
                if end == 0:
                    s.insert(0, bridge[1])
                else:
                    s.append(bridge[1])
                continue
            u = hit(p, d, k)
            if u is not None:
                np_ = (p[0] + d[0] * u, p[1] + d[1] * u)
                if end == 0:
                    s.insert(0, np_)
                else:
                    s.append(np_)
    return streets


def dp(line, tol):
    if len(line) < 3:
        return line
    a, b = np.array(line[0]), np.array(line[-1])
    d = b - a
    n = np.hypot(*d)
    best, idx = 0.0, 0
    for i in range(1, len(line) - 1):
        p = np.array(line[i])
        dist = abs(d[0] * (a[1] - p[1]) - d[1] * (a[0] - p[0])) / n if n > 1e-9 else np.hypot(*(p - a))
        if dist > best:
            best, idx = dist, i
    if best <= tol:
        return [line[0], line[-1]]
    return dp(line[: idx + 1], tol)[:-1] + dp(line[idx:], tol)


def heading(line, at_start):
    """Direction leaving the line's end (into the line), over the first ~25 px."""
    pts = line if at_start else line[::-1]
    p0 = pts[0]
    for q in pts[1:]:
        if math.dist(p0, q) > 25:
            break
    return math.atan2(q[1] - p0[1], q[0] - p0[0])


def chain(edges):
    """Join edges into streets that run straight on through junctions."""
    ends = {}
    for i, (a, b, _) in enumerate(edges):
        ends.setdefault(a, []).append((i, True))
        ends.setdefault(b, []).append((i, False))
    # At each node pair arms that face each other best.
    partner = {}
    for n, arms in ends.items():
        dirs = [(i, s, heading(edges[i][2], s)) for i, s in arms]
        pairs = []
        for x in range(len(dirs)):
            for y in range(x + 1, len(dirs)):
                diff = abs(((dirs[x][2] - dirs[y][2]) + math.pi) % (2 * math.pi) - math.pi)
                bend = math.degrees(math.pi - diff)
                if bend < STRAIGHT_ON and dirs[x][0] != dirs[y][0]:
                    pairs.append((bend, x, y))
        used = set()
        for bend, x, y in sorted(pairs):
            if x in used or y in used:
                continue
            used |= {x, y}
            partner[(dirs[x][0], dirs[x][1])] = (dirs[y][0], dirs[y][1])
            partner[(dirs[y][0], dirs[y][1])] = (dirs[x][0], dirs[x][1])
    done = set()
    streets = []
    for i in range(len(edges)):
        if i in done:
            continue
        # Walk back to the start of the chain.
        cur, start_side = i, True
        visited = {i}
        while (cur, start_side) in partner:
            j, s = partner[(cur, start_side)]
            if j in visited:
                break
            visited.add(j)
            cur, start_side = j, not s
        # Walk forward collecting.
        line = []
        e, s = cur, start_side
        while True:
            done.add(e)
            seg = edges[e][2] if s else edges[e][2][::-1]
            line = seg if not line else line + seg[1:]
            nxt = partner.get((e, not s))
            if nxt is None or nxt[0] in done:
                break
            e, s = nxt
        streets.append(line)
    return streets


# Invented names: main streets take the first pool, the rest the second, in order of length (the
# longest first). Common French street names, never a real street of a real town on purpose.
MAIN_NAMES = [
    "avenue de la République", "rue Nationale", "avenue de la Gare", "rue de Paris", "avenue du Général-Leclerc",
    "rue de la Libération", "avenue Jean-Jaurès", "rue Victor-Hugo", "avenue de Verdun", "rue Gambetta",
    "boulevard Carnot", "avenue Foch", "rue Pasteur", "rue de Strasbourg", "avenue des Tilleuls", "rue Thiers",
    "rue du Commerce", "rue de la Paix", "avenue Pierre-Brossolette", "rue Jules-Ferry", "route de Lyon",
    "rue Émile-Zola", "avenue du Maréchal-Joffre", "rue Voltaire", "route de Metz", "rue Danton",
    "avenue de Bretagne", "route de Nancy", "rue Lamartine", "rue Condorcet", "route de Rouen", "avenue Kléber",
    "rue Michelet", "rue Saint-Antoine", "rue de Lorraine", "rue Mirabeau", "avenue Hoche", "route de Reims",
    "rue Diderot", "rue Saint-Denis", "rue Colbert", "route de Dijon", "avenue Marceau", "route de Tours",
    "rue Saint-Honoré", "route de Bordeaux", "avenue Vauban", "route de Nantes", "route de Grenoble",
    "route de Toulouse", "avenue de Valmy", "route de Chartres", "avenue de Provence", "avenue Lafayette",
    "rue de Châlons", "avenue de Sèvres", "rue de Rivoli", "rue d'Alsace", "avenue de Champagne",
    "rue du Dauphiné", "avenue de Savoie", "rue de Touraine", "route du Poitou", "rue de Gascogne",
    "avenue du Berry", "rue d'Anjou", "route de Picardie", "rue de Normandie", "avenue de Bourgogne",
    "route d'Orléans", "rue de Besançon", "avenue de Limoges", "route de Poitiers", "rue de Calais",
]
_PEOPLE = ["Racine", "Corneille", "Molière", "Buffon", "Lavoisier", "Cuvier", "Sully", "Rabelais", "Montaigne",
    "Bossuet", "Fénelon", "Daguerre", "Arago", "Rollin", "Mabillon", "Monge", "Turgot", "Montesquieu", "Pascal",
    "Descartes", "La Fontaine", "Boileau", "Chateaubriand", "Balzac", "Flaubert", "George-Sand", "Musset",
    "Vigny", "Berlioz", "Rameau", "Lully", "Couperin", "Poussin", "Watteau", "Chardin", "Delacroix", "Ingres",
    "Gay-Lussac", "Ampère", "Fourier", "Laplace", "Lagrange", "Fresnel", "Coulomb", "Parmentier", "Jussieu",
    "Daubenton", "Lamarck", "Bichat", "Laennec", "Du Guesclin", "Bayard", "Jeanne-d'Arc", "Turenne", "Condé",
    "Richelieu", "Mazarin", "Sévigné", "La Bruyère", "Vauvenargues", "Marivaux", "Beaumarchais"]
_SAINTS = ["Saint-Pierre", "Saint-Paul", "Saint-Jean", "Saint-Michel", "Saint-Nicolas", "Saint-Éloi",
    "Saint-Georges", "Saint-Laurent", "Saint-Vincent", "Saint-Roch", "Saint-Sauveur", "Saint-Étienne",
    "Saint-Louis", "Saint-Marc", "Saint-Luc", "Saint-Mathieu", "Saint-Thomas", "Saint-Benoît", "Saint-Bernard",
    "Saint-Gilles", "Saint-Hilaire", "Saint-Maur", "Saint-Ouen", "Saint-Sulpice", "Sainte-Anne",
    "Sainte-Catherine", "Sainte-Claire", "Sainte-Marthe", "Sainte-Geneviève", "Sainte-Agnès", "Sainte-Cécile",
    "Sainte-Barbe", "Sainte-Odile", "Notre-Dame", "Saint-Blaise", "Saint-Fiacre", "Saint-Rémi"]
_TRADES = ["Tanneurs", "Teinturiers", "Bouchers", "Boulangers", "Tisserands", "Charpentiers", "Forgerons",
    "Cordiers", "Potiers", "Orfèvres", "Tonneliers", "Chapeliers", "Vanniers", "Meuniers", "Drapiers",
    "Serruriers", "Couteliers", "Fondeurs", "Chaudronniers", "Selliers", "Bourreliers", "Maréchaux",
    "Charrons", "Menuisiers", "Verriers", "Brasseurs", "Lavandières", "Jardiniers", "Vignerons", "Pêcheurs",
    "Bateliers", "Carriers", "Tuiliers", "Cloutiers", "Épiciers", "Merciers", "Fripiers", "Libraires",
    "Imprimeurs", "Horlogers", "Armuriers", "Cordonniers", "Tailleurs", "Brodeuses", "Fileuses"]
_THINGS = ["Puits", "Four", "Moulin", "Pressoir", "Marché", "Pont", "Port", "Château", "Prieuré", "Couvent",
    "Cloître", "Calvaire", "Lavoir", "Grenier", "Colombier", "Pigeonnier", "Verger", "Bocage", "Ruisseau",
    "Étang", "Coteau", "Val", "Bois", "Chêne", "Tilleul", "Noyer", "Cerisier", "Sureau", "Cygne", "Lion",
    "Faucon", "Héron", "Paon", "Renard", "Cheval-Blanc", "Lion-d'Or", "Soleil", "Croissant", "Heaume",
    "Écu", "Pot-d'Étain", "Chaudron", "Gril", "Mouton", "Bœuf", "Coq", "Dauphin", "Rempart", "Bastion",
    "Guet", "Beffroi", "Bailliage", "Présidial", "Collège", "Séminaire", "Grand-Cerf"]
_PLACES = ["Champs", "Prés", "Jardins", "Vignes", "Saules", "Peupliers", "Ormes", "Fossés", "Remparts",
    "Moulins", "Carrières", "Sablons", "Tuileries", "Granges", "Écoles", "Halles", "Capucins", "Cordeliers",
    "Carmes", "Ursulines", "Jacobins", "Minimes", "Récollets", "Augustins", "Bénédictins", "Chartreux",
    "Célestins", "Feuillants", "Templiers", "Trois-Rois", "Quatre-Vents", "Sept-Arpents", "Deux-Ponts"]


def minor_names():
    out = []
    for i in range(max(len(_PEOPLE), len(_SAINTS), len(_TRADES), len(_THINGS), len(_PLACES))):
        if i < len(_TRADES):
            out.append("rue des " + _TRADES[i])
        if i < len(_SAINTS):
            out.append("rue " + _SAINTS[i])
        if i < len(_THINGS):
            t = _THINGS[i]
            out.append(("rue de l'" if t[0] in "AEIOUÉÈ" else "rue du ") + t)
        if i < len(_PEOPLE):
            out.append("rue " + _PEOPLE[i])
        if i < len(_PLACES):
            out.append("rue des " + _PLACES[i])
    for prefix in ("impasse ", "ruelle ", "allée ", "passage ", "chemin "):
        for stem in list(out[: 240]):
            if stem.startswith("rue "):
                out.append(prefix + stem[4:])
    seen = []
    for n in out:
        if n not in seen:
            seen.append(n)
    return seen


def main_share(line, mm):
    n, hit = 0, 0
    for i in range(len(line) - 1):
        a, b = line[i], line[i + 1]
        k = max(1, int(math.dist(a, b) / 2))
        for j in range(k):
            x = a[0] + (b[0] - a[0]) * j / k
            y = a[1] + (b[1] - a[1]) * j / k
            n += 1
            if 0 <= int(y) < mm.shape[0] and 0 <= int(x) < mm.shape[1] and mm[int(y), int(x)]:
                hit += 1
    return hit / max(1, n)


def main():
    sk = thin(street_mask())
    nodes, edges = graph(sk)
    edges = prune(nodes, edges)
    mm = main_mask()
    # Classify each edge before chaining, so a street changes kind where the bus routes leave it.
    share = [main_share(e[2], mm) for e in edges]
    out = []
    for kind, group in (("principale", [e for e, s in zip(edges, share) if s >= MAIN_SHARE]),
            ("rue", [e for e, s in zip(edges, share) if s < MAIN_SHARE])):
        streets = [dp(smooth(s), SIMPLIFY) for s in chain(group)]
        streets = [s for s in streets if length(s) >= MIN_KEEP]
        streets.sort(key=lambda s: -length(s))
        out.append((kind, streets))
    # Dead ends reach for any street, main or not.
    allst = out[0][1] + out[1][1]
    extend_dead_ends(allst)
    names_minor = minor_names()
    names_main = MAIN_NAMES + ["avenue " + p for p in _PEOPLE[::-1]]
    assert len(out[0][1]) <= len(names_main), "%d main streets, %d names" % (len(out[0][1]), len(names_main))
    assert len(out[1][1]) <= len(names_minor), "%d streets, %d names" % (len(out[1][1]), len(names_minor))
    lines = [
        "class_name CityStreets",
        "## GENERATED by tools/trace_streets.py from references/joinville.png and joinville_main_streets.png:",
        "## never edit by hand. Joinville's streets in pixels of joinville.png (like CityData): `principale`",
        "## where the bus routes run, `rue` elsewhere; every one with an invented French name.",
        "## CityData.STREETS adds them to the town's plan.",
        "",
        "const STREETS := [",
    ]
    names = []
    for kind, streets in out:
        pool = names_main if kind == "principale" else names_minor
        tag = "p" if kind == "principale" else "r"
        for i, s in enumerate(streets):
            sid = "%s%03d" % (tag, i)
            pts = ", ".join("Vector2(%.1f, %.1f)" % p for p in s)
            lines.append('\t{ "id": "%s", "kind": "%s", "pts": [%s] },' % (sid, kind, pts))
            names.append((sid, pool[i]))
    lines += ["]", "", "const NAMES := {"]
    lines += ['\t"%s": "%s",' % (sid, n) for sid, n in names]
    lines.append("}")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    img = Image.open(SRC).convert("RGB")
    img = Image.blend(img, Image.new("RGB", img.size, (0, 0, 0)), 0.45)
    d = ImageDraw.Draw(img)
    for kind, streets in out[::-1]:
        main_ = kind == "principale"
        for s in streets:
            d.line(s, fill=(255, 60, 40) if main_ else (70, 160, 255), width=3 if main_ else 2)
            for p in (s[0], s[-1]):
                d.ellipse([p[0] - 2, p[1] - 2, p[0] + 2, p[1] + 2], outline=(255, 255, 255))
    img.save(OVERLAY)
    print("%d main streets, %d streets, %.0f px -> %s" % (len(out[0][1]), len(out[1][1]),
        sum(length(s) for _, st in out for s in st), OUT))


if __name__ == "__main__":
    main()
