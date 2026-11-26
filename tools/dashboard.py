#!/usr/bin/env python3
"""Reads `Management Dashboard.md` (the master plan) and checks it, answers questions about it,
and draws it as the dashboard page.

    python tools/dashboard.py                 check, then write references/dashboard.html
    python tools/dashboard.py --check         check only (exit 1 with file:line on a mistake)
    python tools/dashboard.py --next          the items that can be started now
    python tools/dashboard.py --next --tag=#perf   ... only those with a tag
    python tools/dashboard.py --stats         done / started / total per phase and area
    python tools/dashboard.py --tags          how many items and details carry each tag
    python tools/dashboard.py --tag=#sound    every item and detail with a tag, with its status
    python tools/dashboard.py --renumber      rewrite the display numbers (N.M.K.D) in order
    python tools/dashboard.py --next-id       the next free item id
    python tools/dashboard.py --json          the parsed plan as JSON on stdout

The format is described at the top of the plan:
    # N · name                      a phase (the next line says what it means)
    ## N.M · name                   an area; `? question`, `> tags: ...`
    ### [ ] N.M.K · name            an item ([x] done, [~] started)
    > id: Snnn | from: ... | needs: ... | size: ... | asset: ... | rounds: N | tags: ... | test: ... | see: ...
    - [ ] N.M.K.D · text #tag       a detail (indented: a sub-detail)
    - text                          a spec note of the node above it
"""
import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAN = os.path.join(ROOT, "Management Dashboard.md")
OUT = os.path.join(ROOT, "references", "dashboard.html")

PHASE = re.compile(r"^# (\d+) · (\S.*)$")
AREA = re.compile(r"^## (\d+\.\d+) · (\S.*)$")
ITEM = re.compile(r"^### \[( |x|~)\] (\d+\.\d+\.\d+) · (\S.*)$")
DETAIL = re.compile(r"^- \[( |x)\] (\d+\.\d+\.\d+\.\d+) · (\S.*)$")
SUB = re.compile(r"^(\s+)- \[( |x)\] (\S.*)$")
NOTE = re.compile(r"^(\s*)- (\S.*)$")
TAG = re.compile(r"(?<!\S)#[a-z][a-z0-9-]*")
DATA_KEYS = ("id", "from", "needs", "size", "asset", "rounds", "tags", "test", "see")
SIZES = ("S", "M", "L")
ASSETS = ("complex", "simple")


class PlanError(Exception):
    def __init__(self, line, message):
        super().__init__("%s:%d: %s" % (os.path.basename(PLAN), line, message))


def split_tags(text):
    tags = TAG.findall(text)
    clean = TAG.sub("", text).rstrip()
    return clean, tags


def parse(text):
    phases = []
    phase = area = item = detail = None
    ids = {}
    in_plan = False
    for n, raw in enumerate(text.splitlines(), 1):
        line = raw.rstrip()
        if line.startswith("# ") and PHASE.match(line):
            m = PHASE.match(line)
            phase = {"num": m.group(1), "name": m.group(2), "meaning": "", "areas": [], "line": n}
            phases.append(phase)
            area = item = detail = None
            in_plan = True
            continue
        if not in_plan:
            continue
        if line.startswith("## "):
            m = AREA.match(line)
            if not m:
                raise PlanError(n, "broken area heading, expected '## N.M · name': " + line)
            if not m.group(1).startswith(phase["num"] + "."):
                raise PlanError(n, "area %s is not numbered under phase %s" % (m.group(1), phase["num"]))
            area = {"num": m.group(1), "name": m.group(2), "q": "", "tags": [], "items": [], "line": n}
            phase["areas"].append(area)
            item = detail = None
            continue
        if line.startswith("### "):
            m = ITEM.match(line)
            if not m:
                raise PlanError(n, "broken item heading, expected '### [ ] N.M.K · name': " + line)
            if area is None:
                raise PlanError(n, "item outside every area")
            item = {"num": m.group(2), "name": m.group(3), "status": m.group(1), "data": {}, "tags": [],
                    "details": [], "notes": [], "line": n}
            area["items"].append(item)
            detail = None
            continue
        if line.startswith("? ") and area is not None and item is None:
            area["q"] = line[2:]
            continue
        if line.startswith("> "):
            if item is None and area is not None:
                for part in line[2:].split(" | "):
                    k, _, v = part.partition(": ")
                    if k == "tags":
                        area["tags"] = v.split()
                continue
            if item is None or item["data"]:
                raise PlanError(n, "a data line belongs right under an item")
            for part in line[2:].split(" | "):
                k, sep, v = part.partition(": ")
                if not sep or k not in DATA_KEYS:
                    raise PlanError(n, "unknown data '%s' (keys: %s)" % (part, ", ".join(DATA_KEYS)))
                item["data"][k] = v.strip()
            item["tags"] = item["data"].get("tags", "").split()
            iid = item["data"].get("id", "")
            if not re.match(r"^S\d{3}$", iid):
                raise PlanError(n, "item %s has no id (id: Snnn)" % item["num"])
            if iid in ids:
                raise PlanError(n, "id %s used twice (also line %d)" % (iid, ids[iid]))
            ids[iid] = n
            continue
        if not line.strip() or line.strip() == "---":
            continue
        if phase is not None and area is None and not line.startswith("-"):
            phase["meaning"] = (phase["meaning"] + " " + line).strip()
            continue
        m = DETAIL.match(line)
        if m:
            if item is None:
                raise PlanError(n, "detail outside every item")
            text_, tags = split_tags(m.group(3))
            detail = {"num": m.group(2), "text": text_, "done": m.group(1) == "x", "tags": tags, "subs": [], "notes": [], "line": n}
            item["details"].append(detail)
            continue
        if re.match(r"^- \[", line):
            raise PlanError(n, "broken detail, expected '- [ ] N.M.K.D · text': " + line)
        m = SUB.match(line)
        if m:
            if detail is None:
                raise PlanError(n, "sub-detail without a detail above it")
            detail["subs"].append({"text": m.group(3), "done": m.group(2) == "x"})
            continue
        m = NOTE.match(line)
        if m:
            target = detail or item or area
            if target is not None:
                target.setdefault("notes", []).append(m.group(2))
            continue
        if item is not None:
            item["notes"].append(line)
    return phases


def items(phases):
    for p in phases:
        for a in p["areas"]:
            for it in a["items"]:
                yield p, a, it


def check(phases):
    problems = []
    known = {}
    frm = {}
    for p, a, it in items(phases):
        known[it["data"]["id"]] = it
        if it["data"].get("from"):
            frm.setdefault(it["data"]["from"], []).append(it)
    for p, a, it in items(phases):
        d = it["data"]
        where = "line %d (%s %s)" % (it["line"], it["num"], d.get("id"))
        if not it["num"].startswith(a["num"] + "."):
            problems.append("%s: not numbered under area %s" % (where, a["num"]))
        for need in [x.strip() for x in d.get("needs", "none").split(",")]:
            if need and need != "none" and need not in known and need not in frm:
                problems.append("%s: needs unknown id %s" % (where, need))
        if d.get("size") and d["size"] not in SIZES:
            problems.append("%s: size must be S, M or L" % where)
        if d.get("asset") and d["asset"] not in ASSETS:
            problems.append("%s: asset must be complex or simple" % where)
        if d.get("rounds"):
            texts = [x["text"] for x in it["details"]]
            for r in range(1, int(d["rounds"]) + 1):
                if not any(t.startswith("Round %d" % r) for t in texts):
                    problems.append("%s: rounds: %s but no 'Round %d' detail" % (where, d["rounds"], r))
            if not any(t.startswith("Review") for t in texts):
                problems.append("%s: rounds but no 'Review' detail" % where)
        for k, det in enumerate(it["details"], 1):
            if det["num"] != "%s.%d" % (it["num"], k):
                problems.append("line %d: detail numbered %s, expected %s.%d (run --renumber)" % (det["line"], det["num"], it["num"], k))
        done = [x["done"] for x in it["details"]]
        if it["status"] == "x" and done and not all(done):
            problems.append("%s: ticked but some details are open" % where)
        if it["status"] == " " and done and all(done):
            problems.append("%s: every detail is done but the item is not ticked" % where)
    # needs cycles
    graph = {i: [x.strip() for x in it["data"].get("needs", "none").split(",") if x.strip() not in ("", "none")] for i, it in known.items()}
    expand = lambda x: [x] if x in known else [o["data"]["id"] for o in frm.get(x, [])]
    state = {}

    def visit(i, path):
        if state.get(i) == 1:
            problems.append("needs cycle: " + " -> ".join(path + [i]))
            return
        if state.get(i) == 2:
            return
        state[i] = 1
        for nd in graph.get(i, []):
            for j in expand(nd):
                if j != i:
                    visit(j, path + [i])
        state[i] = 2

    for i in graph:
        visit(i, [])
    return problems


def resolve(phases):
    """id -> done?, and a function telling whether an item's needs are met."""
    known = {}
    frm = {}
    for p, a, it in items(phases):
        known[it["data"]["id"]] = it
        if it["data"].get("from"):
            frm.setdefault(it["data"]["from"], []).append(it)

    def done(i):
        group = ([known[i]] if i in known else []) + frm.get(i, [])
        return bool(group) and all(g["status"] == "x" for g in group)

    def ready(it):
        needs = [x.strip() for x in it["data"].get("needs", "none").split(",") if x.strip() not in ("", "none")]
        return it["status"] != "x" and all(done(x) for x in needs)

    return done, ready


def all_tags(p, a, it):
    return list(dict.fromkeys(a["tags"] + it["tags"]))


def renumber(text):
    out = []
    ph = ar = itn = det = 0
    for raw in text.splitlines():
        m = PHASE.match(raw)
        if m:
            ph = int(m.group(1))
            ar = 0
            out.append(raw)
            continue
        m = AREA.match(raw)
        if m and ph:
            ar += 1
            itn = 0
            out.append("## %d.%d · %s" % (ph, ar, m.group(2)))
            continue
        m = ITEM.match(raw)
        if m and ph:
            itn += 1
            det = 0
            out.append("### [%s] %d.%d.%d · %s" % (m.group(1), ph, ar, itn, m.group(3)))
            continue
        m = DETAIL.match(raw)
        if m and ph:
            det += 1
            out.append("- [%s] %d.%d.%d.%d · %s" % (m.group(1), ph, ar, itn, det, m.group(3)))
            continue
        out.append(raw)
    return "\n".join(out) + "\n"


def to_json(phases):
    done, ready = resolve(phases)
    data = []
    for p in phases:
        pa = {"num": p["num"], "name": p["name"], "meaning": p["meaning"], "areas": []}
        for a in p["areas"]:
            aa = {"num": a["num"], "name": a["name"], "q": a["q"], "tags": a["tags"], "items": []}
            for it in a["items"]:
                d = it["data"]
                aa["items"].append({
                    "num": it["num"], "name": it["name"], "status": it["status"], "id": d.get("id"),
                    "from": d.get("from", ""), "needs": d.get("needs", "none"), "size": d.get("size", ""),
                    "asset": d.get("asset", ""), "rounds": d.get("rounds", ""), "test": d.get("test", ""),
                    "see": d.get("see", ""), "tags": all_tags(p, a, it), "ready": ready(it),
                    "notes": it["notes"],
                    "details": [{"num": x["num"], "text": x["text"], "done": x["done"], "tags": x["tags"],
                                 "subs": x["subs"], "notes": x.get("notes", [])} for x in it["details"]],
                })
            pa["areas"].append(aa)
        data.append(pa)
    return data


def page(data):
    template = open(os.path.join(ROOT, "tools", "dashboard_page.html"), encoding="utf-8").read()
    blob = json.dumps(data, ensure_ascii=False, separators=(",", ":")).replace("</", "<\\/")
    return template.replace("/*PLAN*/null", blob)


def main(argv):
    text = open(PLAN, encoding="utf-8").read()
    if "--renumber" in argv:
        new = renumber(text)
        open(PLAN, "w", encoding="utf-8").write(new)
        text = new
        print("renumbered")
    try:
        phases = parse(text)
    except PlanError as e:
        print(e)
        return 1
    problems = check(phases)
    if problems:
        for p in problems:
            print(p)
        return 1
    tag = next((a.split("=", 1)[1] for a in argv if a.startswith("--tag=")), None)
    if tag and not tag.startswith("#"):
        tag = "#" + tag
    done, ready = resolve(phases)
    if "--check" in argv or "--renumber" in argv:
        n = sum(1 for _ in items(phases))
        print("ok: %d phases, %d areas, %d items" % (len(phases), sum(len(p["areas"]) for p in phases), n))
        return 0
    if "--next-id" in argv:
        ids = [int(it["data"]["id"][1:]) for _, _, it in items(phases)]
        print("S%03d" % (max(ids) + 1))
        return 0
    if "--json" in argv:
        print(json.dumps(to_json(phases), ensure_ascii=False, indent=1))
        return 0
    if "--next" in argv:
        for p, a, it in items(phases):
            if ready(it) and (not tag or tag in all_tags(p, a, it) or any(tag in d["tags"] for d in it["details"])):
                d = it["data"]
                print("%-9s %s  %s  %s · %s" % (it["num"], d["id"], d.get("size", "?"), a["name"], it["name"]))
        return 0
    if "--stats" in argv:
        tot = [0, 0, 0]
        for p in phases:
            c = [0, 0, 0]
            for a in p["areas"]:
                for it in a["items"]:
                    c[0] += it["status"] == "x"
                    c[1] += it["status"] == "~"
                    c[2] += 1
            tot = [x + y for x, y in zip(tot, c)]
            print("%-3s %-34s %4d done  %4d started  / %4d" % (p["num"], p["name"], c[0], c[1], c[2]))
            for a in p["areas"]:
                d = sum(it["status"] == "x" for it in a["items"])
                s = sum(it["status"] == "~" for it in a["items"])
                print("    %-6s %-48s %3d  %3d  / %3d" % (a["num"], a["name"], d, s, len(a["items"])))
        print("all %-34s %4d done  %4d started  / %4d" % ("", tot[0], tot[1], tot[2]))
        return 0
    if "--tags" in argv:
        counts = {}
        for p, a, it in items(phases):
            for t in all_tags(p, a, it):
                counts.setdefault(t, [0, 0])[0] += 1
            for d in it["details"]:
                for t in d["tags"]:
                    counts.setdefault(t, [0, 0])[1] += 1
        for t, (i, d) in sorted(counts.items(), key=lambda kv: -kv[1][0] - kv[1][1]):
            print("%-14s %4d items  %4d details" % (t, i, d))
        return 0
    if tag:
        for p, a, it in items(phases):
            whole = tag in all_tags(p, a, it)
            ds = [d for d in it["details"] if tag in d["tags"]]
            if whole or ds:
                print("[%s] %s %s · %s" % (it["status"], it["num"], it["data"]["id"], it["name"]))
                for d in (it["details"] if whole else ds):
                    print("      [%s] %s %s" % ("x" if d["done"] else " ", d["num"], d["text"]))
        return 0
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8").write(page(to_json(phases)))
    print("wrote", os.path.relpath(OUT, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
