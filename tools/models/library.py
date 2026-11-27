"""The element library's triage (S248): every element by family, its round, whether its card has
photos, its states, which mission areas use it, and whether it is ready to place; then, per area,
the elements it needs that nobody has made yet.

    python tools/models/library.py            -> writes references/elements/library.md
    python tools/models/library.py --check    -> only checks (every element has a card and an area)

Read from: the family files (`props.families()`), the cards `references/elements/<name>.md` (a
round counts once its section says what differed or what was fixed), the photos beside each card
(`references/elements/<name>/`, or the family's folder), `scripts/models/elements.gd` (states and
parts), `assets/models/props/<name>.glb` (built). Which area uses what is the table `AREAS` below,
by family with exceptions by element: keep it in step when an element or an area is added.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, HERE)
import props  # noqa: E402

CARDS = os.path.join(ROOT, "references", "elements")
MODELS = os.path.join(ROOT, "assets", "models", "props")
REGISTRY = os.path.join(ROOT, "scripts", "models", "elements.gd")
OUT = os.path.join(CARDS, "library.md")
PHOTO_EXT = (".jpg", ".jpeg", ".png", ".webp")

# The five mission areas (S051) and the town's later detail pass (S259).
AREA_NAMES = {
    "terminal": "Terminal Central (bus station)",
    "hospital": "Hospital Dona Helena",
    "prefeitura": "Prefeitura (town hall)",
    "batalhao": "Batalhão (barracks)",
    "mirante": "Mirante (lookout)",
    "town": "the town between them (S259)",
}
ALL5 = ["terminal", "hospital", "prefeitura", "batalhao", "mirante"]
STREETS = ["terminal", "hospital", "prefeitura", "batalhao", "town"]  # the flat areas with streets

# Which areas use each family; an element named here overrides its family.
AREAS = {
    "advertising": STREETS,
    "barracks_court": ["batalhao"],
    "boundaries": ["prefeitura", "batalhao", "mirante", "town"],
    "bridges": ["town"],
    "bus_stop": ["terminal", "hospital", "mirante", "town"],
    "campanile": ["prefeitura"],
    "carried": ALL5 + ["town"],
    "cemetery": ["town"],
    "checkpoint": ALL5 + ["town"],
    "clutter": ALL5 + ["town"],
    "containers": ALL5 + ["town"],
    "decals": ALL5 + ["town"],
    "doors": ALL5 + ["town"],
    "fittings": ["terminal", "hospital", "prefeitura", "batalhao", "town"],
    "generator": ["hospital", "batalhao", "mirante"],
    "helipad": ["hospital"],
    "hospital": ["hospital"],
    "kiosk": ["terminal", "town"],
    "kit": [],
    "lamps": ALL5 + ["town"],
    "monument": ["terminal", "town"],
    "office": ["hospital", "prefeitura", "batalhao", "terminal"],
    "park": ["town"],
    "remains": ALL5 + ["town"],
    "riding_hall": ["batalhao"],
    "road": STREETS + ["mirante"],
    "roofs": ["town", "terminal", "prefeitura"],
    "shopfronts": ["terminal", "town"],
    "shrubs": ["prefeitura", "town"],
    "signs_shops": ["terminal", "town"],
    "signs_street": STREETS + ["mirante"],
    "stairs": ["hospital", "prefeitura", "batalhao", "terminal", "town"],
    "street": STREETS,
    "street_small": STREETS + ["mirante"],
    "summit": ["mirante"],
    "terminal_columns": ["terminal"],
    "terminal_signs": ["terminal"],
    "townhall": ["prefeitura"],
    "traffic": STREETS,
    "trees": STREETS,
    "vehicle_kit": ALL5 + ["town"],
    "windows": ["town", "terminal", "prefeitura"],
    # elements that differ from their family
    "utility_pole": ["mirante", "town", "batalhao"],
    "lamp_mast": ["terminal", "hospital", "batalhao"],
    "rowboat": ["town"],
    "sports_court": ["batalhao"],
    "porte_cochere": ["town"],
    "railing_plinth": ["prefeitura", "batalhao", "town"],
    "door_plank": ALL5 + ["town"],
    "fountain_wall": ["mirante", "town"],
    "coin_binoculars": ["mirante"],
    "window_ribbon": ["terminal", "hospital", "prefeitura"],
    "window_barracks": ["batalhao"],
    "window_french": ["town"],
    "roller_shutter": ["terminal", "hospital", "batalhao", "town"],
}

# What each area still needs and nobody has made yet, from its element list
# (`references/<area>_elements.md`) and the dashboard's area steps. An entry: (name, step, what).
MISSING = {
    "terminal": [
        ("terminal_roof_shell", "S197", "the grey concrete shell cantilevered from the spine, its fascia"),
        ("terminal_skylight", "S199", "the skylight lantern along the spine"),
        ("platform_island", "S200", "a platform island: yellow kerbs, pavers, end barriers"),
        ("bus_city", "S180", "the yellow city bus, doors that open, a burnt state"),
        ("turnstile_booth", "S201", "ticket booth and turnstile"),
        ("station_clock", "S202", "the station clock on its post"),
        ("soffit_downlight", "S194", "round downlight in a soffit"),
    ],
    "hospital": [
        ("elevator", "S195", "the bed lift: car, landing doors, shaft"),
        ("hospital_bed", "S211", "a ward bed with rails and wheels"),
        ("ward_curtain", "S211", "a curtain track and its curtain"),
        ("samu_van", "S180", "the SAMU ambulance van"),
    ],
    "prefeitura": [
        ("barricade_window", "S055", "a window boarded with planks and furniture"),
        ("council_bench", "S193", "the council chamber's benches and dais"),
        ("blind_venetian", "S157", "venetian blinds hanging out of a broken window"),
        ("tent_civil", "S185", "the Defesa Civil tent"),
    ],
    "batalhao": [
        ("barracks_block", "S221", "the long two-storey block: hipped tile roof, green band, tall windows"),
        ("guard_house", "S223", "the guard house and the gate's barrier arm"),
        ("parade_stand", "S222", "the stepped stand across the ground"),
        ("army_truck", "S180", "the army truck, open and covered"),
        ("mounted_gun", "S225", "the mounted gun on the guard tower"),
    ],
    "mirante": [
        ("lookout_tower", "S230", "the 14.5 m tower itself (no photo in references yet)"),
        ("guard_booth", "S229", "the gate's guard booth on its island"),
        ("info_totem", "S231", "the green information totem"),
        ("forest_walkway", "S232", "the suspended forest walkway's platforms"),
        ("retaining_wall", "S178", "the retaining wall and gutter on the bends"),
    ],
    "town": [
        ("window_small", "S157", "the timber houses' small casement"),
        ("half_timber", "S161", "the timber-framed house"),
        ("house_plaster", "S162", "the plastered stone house's modules"),
        ("atelier", "S164", "the riverside atelier hall"),
        ("mansard_ends", "S159", "the mansard's ends and corners"),
        ("house_plate", "S044", "the blue enamel house number"),
    ],
}


def _registry():
    """{name: {"states": [...], "parts": [...]}} from Elements.ALL."""
    text = open(REGISTRY, encoding="utf-8").read()
    out = {}
    for m in re.finditer(r'\n\t"(\w+)": \{(.*?)\n\t\}', text, re.S):
        body = m.group(2)
        get = lambda k: re.findall(r'"([^"]+)"', (re.search(r'"%s": \[(.*?)\]' % k, body, re.S) or [None, ""])[1]
                                   if re.search(r'"%s": \[(.*?)\]' % k, body, re.S) else "")
        out[m.group(1)] = {"states": get("states"), "parts": get("parts")}
    return out


def _filled(section):
    """True once a round's section says something: a sheet named, or a bullet with real words."""
    for line in section.splitlines():
        s = line.strip()
        if s.startswith("Sheet:") and "`" in s and "<name>" not in s:
            return True
        if s.startswith("- ") and len(s[2:].strip(" -")) > 3:
            return True
    return False


def card_info(name):
    """(card exists, highest round filled in, review written)."""
    path = os.path.join(CARDS, name + ".md")
    if not os.path.exists(path):
        return False, 0, False
    text = open(path, encoding="utf-8").read()
    sections = re.split(r"\n## ", "\n" + text)
    rounds, review = 0, False
    for sec in sections:
        head = sec.split("\n", 1)[0]
        body = sec.split("\n", 1)[1] if "\n" in sec else ""
        m = re.match(r"Round (\d)", head)
        if m and _filled(body):
            rounds = max(rounds, int(m.group(1)))
        if head.startswith("Review") and _filled(body):
            review = True
    return True, rounds, review


def photos(name, family):
    for folder in (name, family):
        d = os.path.join(CARDS, folder)
        if os.path.isdir(d):
            n = sum(1 for f in os.listdir(d) if f.lower().endswith(PHOTO_EXT))
            if n:
                return n
    return 0


def areas_of(name, family):
    return AREAS.get(name, AREAS.get(family, []))


def rows():
    reg = _registry()
    out = []
    for fam, mod in props.families().items():
        for name in mod.ELEMENTS:
            card, rnd, review = card_info(name)
            built = os.path.exists(os.path.join(MODELS, name + ".glb"))
            spec = reg.get(name, {"states": [], "parts": []})
            n_photos = photos(name, fam)
            if not built:
                status = "build it (Blender)"
            elif rnd == 0:
                status = "round 1"
            elif review:
                status = "ready, reviewed"
            else:
                status = "ready (draft)" if rnd < 3 else "ready, review left"
            nxt = []
            if n_photos == 0:
                nxt.append("photos")
            if built and rnd < 3:
                nxt.append(f"round {rnd + 1}")
            out.append(dict(family=fam, name=name, card=card, round=rnd, photos=n_photos,
                            built=built, states=spec["states"], parts=spec["parts"],
                            areas=areas_of(name, fam), status=status, next=nxt,
                            registered=name in reg))
    return out


def check(rs):
    errs = []
    for r in rs:
        if not r["card"]:
            errs.append(f"{r['name']}: no card")
        if not r["areas"] and r["family"] != "kit":
            errs.append(f"{r['name']}: no area in library.AREAS")
        if not r["registered"]:
            errs.append(f"{r['name']}: not in Elements.ALL")
    return errs


def write(rs):
    ready = [r for r in rs if r["status"].startswith("ready")]
    lines = [
        "# The element library: triage (S248)",
        "",
        "Generated by `python tools/models/library.py`: don't edit by hand; change the cards, the family",
        "files or the tables at the top of the script, and run it again.",
        "",
        f"{len(rs)} elements in {len({r['family'] for r in rs})} families; {len(ready)} ready to place "
        f"(built, round 1 at least: a draft is placed and improved in place), "
        f"{sum(1 for r in rs if r['photos'] == 0)} without photos on their card.",
        "",
        "Round: the highest round whose section on the card is filled in. Photos: pictures beside the",
        "card (its own folder, else its family's). Areas: " + ", ".join(f"`{k}` {v}" for k, v in AREA_NAMES.items()) + ".",
        "",
    ]
    fam = None
    for r in rs:
        if r["family"] != fam:
            fam = r["family"]
            lines += ["", f"## {fam}", "", "| element | round | photos | states | parts | areas | status | next |",
                      "|---|---|---|---|---|---|---|---|"]
        states = ", ".join(s for s in r["states"] if s != "clean") or "-"
        parts = ", ".join(r["parts"]) or "-"
        areas = ", ".join(r["areas"]) or "-"
        lines.append(f"| `{r['name']}` | {r['round']} | {r['photos'] or '**none**'} | {states} | {parts} | "
                     f"{areas} | {r['status']} | {', '.join(r['next']) or '-'} |")
    lines += ["", "", "# What each area uses, and what nobody has made yet", "",
              "Element steps are picked from the missing lists first."]
    for area, title in AREA_NAMES.items():
        used = [r["name"] for r in rs if area in r["areas"]]
        lines += ["", f"## {title}", "",
                  f"Uses {len(used)}: " + ", ".join(f"`{n}`" for n in used) + ".", "", "Missing:"]
        for name, step, what in MISSING.get(area, []):
            lines.append(f"- `{name}` ({step}): {what}")
    open(OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


if __name__ == "__main__":
    rs = rows()
    errs = check(rs)
    for e in errs:
        print(e)
    if "--check" not in sys.argv:
        write(rs)
        print(f"wrote {os.path.relpath(OUT, ROOT)}: {len(rs)} elements")
    sys.exit(1 if errs and "--check" in sys.argv else 0)
