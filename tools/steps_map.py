#!/usr/bin/env python3
"""Reads STEPS.md and draws it as a mind map.

    python tools/steps_map.py            check, then write references/steps_map.html
    python tools/steps_map.py --check    check only (exit 1 with file:line on a mistake)
    python tools/steps_map.py --next     the steps that can be started now
    python tools/steps_map.py --stats    done / total per phase

The format is the one described at the top of STEPS.md:
    ## Pnn · name            a phase
    ### [ ] Snnn · name      a step
    > needs: ... | size: ... | test: ... | see: ...     the step's data
    - [ ] text               a feature (indented: a sub-feature)
    - text                   a spec note of the node above it
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STEPS = os.path.join(ROOT, "STEPS.md")
OUT = os.path.join(ROOT, "references", "steps_map.html")

PHASE = re.compile(r"^## (P\d{2}) · (\S.*)$")
STEP = re.compile(r"^### \[( |x)\] (S\d{3}) · (\S.*)$")
BOX = re.compile(r"^(\s*)- \[( |x)\] (\S.*)$")
NOTE = re.compile(r"^(\s*)- (\S.*)$")
DATA_KEYS = ("needs", "size", "test", "see")
SIZES = ("S", "M", "L")


class StepsError(Exception):
    def __init__(self, path, line, message):
        super().__init__("%s:%d: %s" % (path, line, message))
        self.line = line
        self.message = message


def parse(text, path="STEPS.md"):
    """Returns the list of phases; raises StepsError with the file and line."""
    phases = []
    step_ids = {}
    phase_ids = {}
    phase = None
    step = None
    feature = None  # last top-level feature of the current step
    last = None  # the node a note belongs to
    for number, raw in enumerate(text.splitlines(), 1):
        line = raw.rstrip()
        if line.startswith("### "):
            m = STEP.match(line)
            if not m:
                raise StepsError(path, number, "broken step heading, expected '### [ ] Snnn · name': %s" % line)
            if phase is None:
                raise StepsError(path, number, "step %s is outside every phase" % m.group(2))
            if m.group(2) in step_ids:
                raise StepsError(path, number, "duplicate id %s (first on line %d)" % (m.group(2), step_ids[m.group(2)]["line"]))
            step = {"id": m.group(2), "name": m.group(3), "done": m.group(1) == "x", "line": number,
                    "needs": [], "size": "", "test": "", "see": "", "notes": [], "features": []}
            step_ids[step["id"]] = step
            phase["steps"].append(step)
            feature = None
            last = step
        elif line.startswith("## "):
            m = PHASE.match(line)
            if not m:
                if re.match(r"^## P\d", line):
                    raise StepsError(path, number, "broken phase heading, expected '## Pnn · name': %s" % line)
                if phases:
                    raise StepsError(path, number, "a heading that is not a phase after the phases began: %s" % line)
                continue
            if m.group(1) in phase_ids:
                raise StepsError(path, number, "duplicate id %s (first on line %d)" % (m.group(1), phase_ids[m.group(1)]))
            phase_ids[m.group(1)] = number
            phase = {"id": m.group(1), "name": m.group(2), "line": number, "steps": []}
            phases.append(phase)
            step = feature = last = None
        elif step is None:
            continue
        elif line.startswith("> "):
            _read_data(step, line[2:], path, number)
        elif BOX.match(line):
            m = BOX.match(line)
            node = {"name": m.group(3), "done": m.group(2) == "x", "line": number, "notes": [], "features": []}
            if len(m.group(1)) == 0:
                step["features"].append(node)
                feature = node
            elif feature is None:
                raise StepsError(path, number, "a sub-feature with no feature above it")
            else:
                feature["features"].append(node)
            last = node
        elif NOTE.match(line):
            last["notes"].append(NOTE.match(line).group(2))
    _check(phases, step_ids, path)
    return phases


def _read_data(step, body, path, number):
    for part in body.split(" | "):
        key, sep, value = part.partition(":")
        key = key.strip()
        value = value.strip()
        if not sep or key not in DATA_KEYS:
            raise StepsError(path, number, "unknown data '%s' in %s (known: %s)" % (part.strip(), step["id"], ", ".join(DATA_KEYS)))
        if key == "needs":
            if value != "none":
                for need in [n.strip() for n in value.split(",")]:
                    if not re.match(r"^S\d{3}$", need):
                        raise StepsError(path, number, "broken id '%s' in the needs of %s" % (need, step["id"]))
                    step["needs"].append(need)
            step["needs_line"] = number
        elif key == "size":
            if value not in SIZES:
                raise StepsError(path, number, "size of %s is '%s', expected S, M or L" % (step["id"], value))
            step["size"] = value
        else:
            step[key] = value


def _check(phases, by_id, path):
    for step in by_id.values():
        for need in step["needs"]:
            if need not in by_id:
                raise StepsError(path, step.get("needs_line", step["line"]), "%s needs %s, which does not exist" % (step["id"], need))
    # A cycle: walk the needs depth first, a step met again while still open is one.
    state = {}
    for start in sorted(by_id):
        if start in state:
            continue
        trail = [(start, iter(by_id[start]["needs"]))]
        state[start] = 1
        while trail:
            sid, needs = trail[-1]
            need = next(needs, None)
            if need is None:
                state[sid] = 2
                trail.pop()
            elif state.get(need) == 1:
                loop = [t[0] for t in trail]
                loop = loop[loop.index(need):] + [need]
                raise StepsError(path, by_id[sid].get("needs_line", by_id[sid]["line"]), "needs cycle: %s" % " -> ".join(loop))
            elif need not in state:
                state[need] = 1
                trail.append((need, iter(by_id[need]["needs"])))


def all_steps(phases):
    return [s for p in phases for s in p["steps"]]


def startable(phases):
    """Open steps whose needs are all done, in file order."""
    done = {s["id"] for s in all_steps(phases) if s["done"]}
    return [s for s in all_steps(phases) if not s["done"] and all(n in done for n in s["needs"])]


def stats(phases):
    """[(phase id, name, done, total)] plus a total row."""
    rows = [(p["id"], p["name"], sum(1 for s in p["steps"] if s["done"]), len(p["steps"])) for p in phases]
    rows.append(("all", "Total", sum(r[2] for r in rows), sum(r[3] for r in rows)))
    return rows


def warnings(phases):
    """Things that are not mistakes in the format but are worth a look."""
    out = []
    for s in all_steps(phases):
        open_features = [f for f in _walk(s["features"]) if not f["done"]]
        if s["done"] and open_features:
            out.append("line %d: %s is ticked but has %d open features" % (s["line"], s["id"], len(open_features)))
        if not s["done"] and s["features"] and not open_features:
            out.append("line %d: %s has every feature ticked but is still open" % (s["line"], s["id"]))
    return out


def _walk(features):
    for f in features:
        yield f
        for sub in _walk(f["features"]):
            yield sub


def tree(phases):
    """The map's data: what the page draws."""
    can_start = {s["id"] for s in startable(phases)}

    def feature(f):
        return {"n": f["name"], "d": f["done"], "notes": f["notes"], "c": [feature(c) for c in f["features"]]}

    return [{"id": p["id"], "n": p["name"], "c": [{
        "id": s["id"], "n": s["name"], "d": s["done"], "start": s["id"] in can_start,
        "needs": s["needs"], "size": s["size"], "test": s["test"], "see": s["see"],
        "notes": s["notes"], "c": [feature(f) for f in s["features"]],
    } for s in p["steps"]]} for p in phases]


def html(phases):
    data = json.dumps(tree(phases), ensure_ascii=False).replace("</", "<\\/")
    return PAGE.replace("/*DATA*/", data)


PAGE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Make Alive: steps</title>
<style>
  html, body { margin: 0; height: 100%; background: #0d0f12; color: #cfd6de; font: 13px/1.4 "Segoe UI", system-ui, sans-serif; overflow: hidden; }
  svg { width: 100%; height: 100%; display: block; cursor: grab; }
  svg.drag { cursor: grabbing; }
  #bar { position: fixed; left: 12px; top: 10px; display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
  #bar b { font-size: 15px; margin-right: 6px; color: #fff; }
  button, label.tog { background: #1a1f26; color: #cfd6de; border: 1px solid #333c47; border-radius: 4px; padding: 4px 10px; font: inherit; cursor: pointer; user-select: none; }
  button:hover, label.tog:hover { border-color: #6b7a8c; }
  #legend { position: fixed; left: 12px; bottom: 10px; display: flex; gap: 14px; color: #8b97a5; }
  #legend i { display: inline-block; width: 10px; height: 10px; border-radius: 50%; margin-right: 5px; vertical-align: -1px; }
  #tip { position: fixed; display: none; max-width: 440px; background: #161b22; border: 1px solid #3a4553; border-radius: 6px; padding: 9px 12px; pointer-events: none; box-shadow: 0 6px 24px #000a; }
  #tip h4 { margin: 0 0 4px; font-size: 14px; color: #fff; }
  #tip .k { color: #8b97a5; }
  #tip ul { margin: 4px 0 0; padding-left: 18px; }
  #tip code { color: #e6c07b; font-family: Consolas, monospace; font-size: 12px; }
  .link { fill: none; stroke: #2b333d; stroke-width: 1; }
  .link.done { stroke: #2f6b45; }
  .dep { fill: none; stroke: #c0843a; stroke-width: 1.1; opacity: .5; }
  .dep.hot { stroke: #ffd27a; opacity: 1; stroke-width: 2; }
  .dep.cold { opacity: .08; }
  text { fill: #8b97a5; font-size: 11px; paint-order: stroke; stroke: #0d0f12; stroke-width: 3px; stroke-linejoin: round; }
  .node { cursor: default; }
  .node.step { cursor: pointer; }
  .done > circle { fill: #3fb968; } .done > text { fill: #6fd391; }
  .start > circle { fill: #ffe066; stroke: #fff3b0; stroke-width: 2; } .start > text { fill: #fff; font-weight: 600; }
  .blocked > circle { fill: #39424d; } .blocked > text { fill: #5d6875; }
  .open > circle { fill: #7d8996; } .open > text { fill: #aab4bf; }
  .phase > circle { fill: #4a90d9; } .phase > text { fill: #dbe7f5; font-size: 13px; font-weight: 600; }
  .phase.done > circle { fill: #3fb968; }
  .root > circle { fill: #fff; } .root > text { fill: #fff; font-size: 15px; font-weight: 700; }
  .step.folded > circle { stroke-dasharray: none; }
  .step.has > circle { stroke: #0d0f12; stroke-width: 1; }
  .step.folded.has > text { text-decoration: none; }
</style>
</head>
<body>
<svg id="svg"><defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse"><path d="M0 0L10 5L0 10z" fill="#c0843a"/></marker></defs><g id="view"><g id="links"></g><g id="deps"></g><g id="nodes"></g></g></svg>
<div id="bar"><b>Make Alive: steps</b><span id="count"></span>
  <button id="unfold">Unfold all</button><button id="fold">Fold all</button><button id="foldstart">Only startable</button>
  <label class="tog"><input type="checkbox" id="deps-on"> Dependency arrows</label><button id="fit">Fit</button></div>
<div id="legend"><span><i style="background:#3fb968"></i>done</span><span><i style="background:#ffe066"></i>can start now</span><span><i style="background:#39424d"></i>blocked</span><span>click a step to fold or unfold, hover for its notes, wheel to zoom, drag to move</span></div>
<div id="tip"></div>
<script>
const PHASES = /*DATA*/;
const NS = "http://www.w3.org/2000/svg";
const svg = document.getElementById("svg"), view = document.getElementById("view");
const gLinks = document.getElementById("links"), gDeps = document.getElementById("deps"), gNodes = document.getElementById("nodes");
const tip = document.getElementById("tip");
const steps = {};
const open = {};
let showDeps = false, hover = null;

const root = {kind: "root", n: "Make Alive", c: PHASES};
for (const p of PHASES) { p.kind = "phase"; p.d = p.c.every(s => s.d);
  for (const s of p.c) { s.kind = "step"; steps[s.id] = s; open[s.id] = s.start; mark(s.c, s); } }
function mark(list, step) { for (const f of list) { f.kind = "feature"; f.step = step; mark(f.c, step); } }

function kids(n) { return n.kind === "step" && !open[n.id] ? [] : n.c; }
function leaves(n) { const k = kids(n); n.w = k.length ? k.reduce((a, c) => a + leaves(c), 0) : 1; return n.w; }
function depth(n) { return n.kind === "root" ? 0 : n.kind === "phase" ? 1 : n.kind === "step" ? 2 : n.step && n.step.c.includes(n) ? 3 : 4; }

function layout() {
  const total = leaves(root);
  const r2 = Math.max(330, total * 15 / (2 * Math.PI));
  const radii = [0, r2 * 0.5, r2, r2 + 250, r2 + 560];
  let at = 0;
  (function place(n) {
    const k = kids(n);
    n.r = radii[depth(n)];
    if (!k.length) { n.a = (at + 0.5) / total * 2 * Math.PI; at += 1; }
    else { k.forEach(place); n.a = (k[0].a + k[k.length - 1].a) / 2; }
    n.x = n.r * Math.sin(n.a); n.y = -n.r * Math.cos(n.a);
  })(root);
  return radii[4] + 330;
}

function el(name, attrs, parent) { const e = document.createElementNS(NS, name); for (const k in attrs) e.setAttribute(k, attrs[k]); if (parent) parent.appendChild(e); return e; }
function cut(s, n) { return s.length > n ? s.slice(0, n - 1) + "…" : s; }
function plain(s) { return s.replace(/`/g, ""); }
function status(n) {
  if (n.kind === "root") return "root";
  if (n.kind === "phase") return "phase" + (n.d ? " done" : "");
  if (n.d) return "done";
  const s = n.kind === "step" ? n : n.step;
  return s.start ? (n.kind === "step" ? "start" : "open") : "blocked";
}

let extent = 1000;
function draw() {
  extent = layout();
  gLinks.textContent = ""; gNodes.textContent = ""; gDeps.textContent = "";
  (function walk(n) {
    for (const c of kids(n)) {
      const mid = (n.r + c.r) / 2;
      const ax = mid * Math.sin(n.a), ay = -mid * Math.cos(n.a), bx = mid * Math.sin(c.a), by = -mid * Math.cos(c.a);
      el("path", {class: "link" + (c.d ? " done" : ""), d: `M${n.x} ${n.y}C${ax} ${ay} ${bx} ${by} ${c.x} ${c.y}`}, gLinks);
      walk(c);
    }
    const g = el("g", {class: "node " + n.kind + " " + status(n) + (n.kind === "step" ? (open[n.id] ? "" : " folded") + (n.c.length ? " has" : "") : ""), transform: `translate(${n.x} ${n.y})`}, gNodes);
    const size = n.kind === "root" ? 9 : n.kind === "phase" ? 7 : n.kind === "step" ? 5.5 : 3;
    el("circle", {r: size}, g);
    const deg = n.a * 180 / Math.PI - 90, flip = n.a > Math.PI;
    let label = n.kind === "step" ? n.id + " · " + n.n : n.kind === "phase" ? n.id + " · " + n.n : plain(n.n);
    if (n.kind === "step" && !open[n.id] && n.c.length) label += "  +";
    const t = el("text", n.kind === "root" ? {y: -16, "text-anchor": "middle"} :
      {transform: `rotate(${flip ? deg + 180 : deg})`, x: flip ? -(size + 5) : size + 5, dy: "0.32em", "text-anchor": flip ? "end" : "start"}, g);
    t.textContent = cut(label, n.kind === "feature" ? 46 : 44);
    g.addEventListener("mousemove", e => showTip(n, e));
    g.addEventListener("mouseleave", () => { tip.style.display = "none"; if (hover) { hover = null; drawDeps(); } });
    if (n.kind === "step") {
      g.addEventListener("mouseenter", () => { hover = n.id; drawDeps(); });
      g.addEventListener("click", () => { if (moved) return; open[n.id] = !open[n.id]; tip.style.display = "none"; draw(); });
    }
  })(root);
  drawDeps();
}

function drawDeps() {
  gDeps.textContent = "";
  if (!showDeps && !hover) return;
  for (const id in steps) {
    const s = steps[id];
    for (const need of s.needs) {
      const from = steps[need];
      const mine = hover && (hover === id || hover === need);
      if (!showDeps && !mine) continue;
      const pull = 0.35;
      el("path", {class: "dep" + (hover ? (mine ? " hot" : " cold") : ""), "marker-end": "url(#arrow)",
        d: `M${from.x} ${from.y}Q${(from.x + s.x) / 2 * pull} ${(from.y + s.y) / 2 * pull} ${s.x} ${s.y}`}, gDeps);
    }
  }
}

function esc(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;"); }
function rich(s) { return esc(s).replace(/`([^`]*)`/g, "<code>$1</code>"); }
function showTip(n, e) {
  let h = "";
  if (n.kind === "step") {
    const all = []; (function w(l) { for (const f of l) { all.push(f); w(f.c); } })(n.c);
    h = `<h4>${n.id} · ${esc(n.n)}</h4><div><span class="k">${n.d ? "done" : n.start ? "can start now" : "blocked"} · size ${n.size || "?"} · ${all.filter(f => f.d).length} / ${all.length} features</span></div>`;
    h += `<div><span class="k">needs:</span> ${n.needs.length ? n.needs.map(i => `${i} ${esc(steps[i].n)} ${steps[i].d ? "✓" : "✗"}`).join(", ") : "none"}</div>`;
    if (n.test) h += `<div><span class="k">test:</span> ${rich(n.test)}</div>`;
    if (n.see) h += `<div><span class="k">see:</span> ${rich(n.see)}</div>`;
  } else if (n.kind === "phase") {
    h = `<h4>${n.id} · ${esc(n.n)}</h4><div class="k">${n.c.filter(s => s.d).length} / ${n.c.length} steps done</div>`;
  } else if (n.kind === "feature") {
    h = `<h4>${rich(n.n)}</h4><div class="k">${n.d ? "done" : "open"} · ${n.step.id} ${esc(n.step.n)}</div>`;
  } else {
    const all = Object.values(steps); h = `<h4>Make Alive</h4><div class="k">${all.filter(s => s.d).length} / ${all.length} steps done</div>`;
  }
  if (n.notes && n.notes.length) h += "<ul>" + n.notes.map(t => `<li>${rich(t)}</li>`).join("") + "</ul>";
  tip.innerHTML = h; tip.style.display = "block";
  const w = tip.offsetWidth, hh = tip.offsetHeight;
  tip.style.left = Math.min(e.clientX + 16, innerWidth - w - 8) + "px";
  tip.style.top = Math.min(e.clientY + 16, innerHeight - hh - 8) + "px";
}

let tx = 0, ty = 0, k = 1, moved = false, grab = null;
function apply() { view.setAttribute("transform", `translate(${tx} ${ty}) scale(${k})`); }
function fit() { k = Math.min(innerWidth, innerHeight) / (2 * extent); tx = innerWidth / 2; ty = innerHeight / 2; apply(); }
svg.addEventListener("wheel", e => { e.preventDefault(); const f = Math.exp(-e.deltaY * 0.0015); tx = e.clientX - (e.clientX - tx) * f; ty = e.clientY - (e.clientY - ty) * f; k *= f; apply(); }, {passive: false});
svg.addEventListener("mousedown", e => { grab = [e.clientX, e.clientY]; moved = false; svg.classList.add("drag"); });
addEventListener("mousemove", e => { if (!grab) return; const dx = e.clientX - grab[0], dy = e.clientY - grab[1]; if (Math.abs(dx) + Math.abs(dy) > 3) moved = true; tx += dx; ty += dy; grab = [e.clientX, e.clientY]; apply(); });
addEventListener("mouseup", () => { grab = null; svg.classList.remove("drag"); setTimeout(() => moved = false, 0); });
function setAll(f) { for (const id in steps) open[id] = f(steps[id]); draw(); fit(); }
document.getElementById("unfold").onclick = () => setAll(() => true);
document.getElementById("fold").onclick = () => setAll(() => false);
document.getElementById("foldstart").onclick = () => setAll(s => s.start);
document.getElementById("fit").onclick = fit;
document.getElementById("deps-on").onchange = e => { showDeps = e.target.checked; drawDeps(); };
{ const all = Object.values(steps); document.getElementById("count").textContent = `${all.filter(s => s.d).length} / ${all.length} done, ${all.filter(s => s.start).length} can start`; }
if (location.hash === "#deps") { showDeps = true; document.getElementById("deps-on").checked = true; }
if (location.hash === "#all") for (const id in steps) open[id] = true;
draw(); fit();
addEventListener("resize", fit);
</script>
</body>
</html>
"""


def main(argv):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    known = ("--check", "--next", "--stats")
    for a in argv:
        if a not in known:
            print(__doc__)
            return 2
    with open(STEPS, encoding="utf-8") as f:
        text = f.read()
    try:
        phases = parse(text)
    except StepsError as e:
        print(e, file=sys.stderr)
        return 1
    for w in warnings(phases):
        print("warning: STEPS.md " + w, file=sys.stderr)
    if "--next" in argv:
        for s in startable(phases):
            print("%s  %s  %s" % (s["id"], s["size"] or "?", s["name"]))
    if "--stats" in argv:
        for pid, name, done, total in stats(phases):
            print("%-4s %-36s %3d / %3d" % (pid, name, done, total))
    if "--check" in argv or not argv:
        steps = all_steps(phases)
        print("STEPS.md OK: %d phases, %d steps, %d done, %d can start" % (
            len(phases), len(steps), sum(1 for s in steps if s["done"]), len(startable(phases))))
    if not argv:
        with open(OUT, "w", encoding="utf-8", newline="\n") as f:
            f.write(html(phases))
        print("wrote " + os.path.relpath(OUT, ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
