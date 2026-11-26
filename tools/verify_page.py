r"""Write the verification page, references/verify.html, from VERIFY.md and what is on disk.

    python tools/verify_page.py            (then open references/verify.html)

Every check of VERIFY.md becomes a card: what to judge, its reference photos, its pictures (click for a
large view, arrow keys to step through), its sounds (each with a player and what it should be), and
OK / Issue buttons with a note that stay in the browser (localStorage). A picture older than the
check's `src` files is flagged stale. "Copy verdicts" copies every verdict as Markdown. Pictures and
sounds in references/shots/ that no check names are listed at the end, so nothing goes unseen.
Make the pictures and sounds first: tools\shots.ps1, tools\sounds.ps1.
"""
import ast
import datetime
import glob
import html
import json
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "references", "verify.html")
PAGE_DIR = os.path.dirname(OUT)
MEDIA = (".png", ".jpg", ".jpeg", ".wav", ".html")

GUNS = ["P19", "P90", "Type 95", "AK47", "AS Val", "USAS-12", "SPAS-12", "T-5000", "Dragunov"]
BUILTIN = {
    "gunshot": "the old single gunshot (tests only)", "dry_fire": "trigger on an empty gun: a dry click",
    "thud": "a body or a shove landing", "siren": "a wave starting", "beep": "the extraction count's beep",
    "breath": "winded breathing", "heartbeat": "low HP heartbeat", "whiz": "a bullet passing your head",
    "tink": "a spent case landing", "sever_wet": "a limb coming off", "low_ammo_click": "the last rounds' click",
    "tail_indoor": "the room answering a shot indoors", "tail_street": "a shot's tail between houses",
    "tail_open": "a shot's tail on the open hill",
}


def rel(path):
    return os.path.relpath(path, ROOT).replace("\\", "/")


def parse(text):
    """VERIFY.md -> [(section, [check])]."""
    sections, check = [], None
    for line in text.splitlines():
        if line.startswith("## "):
            sections.append([line[3:].strip(), []])
            check = None
            continue
        m = re.match(r"- \[( |x)\] \*\*(\w+)\*\* · (.+?)(?: — (.*))?$", line)
        if m and sections:
            check = {"done": m.group(1) == "x", "id": m.group(2), "title": m.group(3), "judge": m.group(4) or "",
                     "see": [], "ref": [], "make": "", "src": [], "notes": []}
            sections[-1][1].append(check)
            continue
        m = re.match(r"\s+- (see|ref|make|src|note): (.*)$", line)
        if m and check:
            key, val = m.groups()
            if key in ("see", "ref", "src"):
                check[key] += [v.strip() for v in val.split(",") if v.strip()]
            elif key == "make":
                check["make"] = val.strip()
            else:
                check["notes"].append(val.strip())
    return [(name, checks) for name, checks in sections if checks]


def expand(patterns):
    files, missing = [], []
    for p in patterns:
        hits = sorted(os.path.normpath(h) for h in glob.glob(os.path.join(ROOT, p)))
        hits = [h for h in hits if h.lower().endswith(MEDIA)]
        if not hits:
            missing.append(p)
        for h in hits:
            if h not in files:
                files.append(h)
    return files, missing


def sound_notes():
    notes = dict(BUILTIN)
    try:
        tree = ast.parse(open(os.path.join(ROOT, "tools", "sound_sheet.py"), encoding="utf-8").read())
        for node in tree.body:
            if isinstance(node, ast.Assign) and getattr(node.targets[0], "id", "") == "WHAT":
                notes.update(ast.literal_eval(node.value))
    except (OSError, SyntaxError, ValueError):
        pass
    for i, gun in enumerate(GUNS):
        notes[f"shot_{i}"] = f"{gun}, near"
        notes[f"shot_{i}_far"] = f"{gun}, far away: no crack"
        notes[f"shot_{i}_sup"] = f"{gun}, suppressed"
    for what in ["mag_release", "mag_out", "mag_in", "mag_slap", "bolt_rack", "shell_in", "pump_back", "pump_fwd",
                 "bolt_up", "bolt_back", "bolt_fwd", "bolt_down", "holster", "draw", "inspect"]:
        notes["h_" + what] = what.replace("_", " ")
    return notes


def stats():
    try:
        out = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "dashboard.py"), "--stats"],
                             capture_output=True, text=True, cwd=ROOT, timeout=60).stdout
        return out.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def when(t):
    return datetime.datetime.fromtimestamp(t).strftime("%Y-%m-%d %H:%M")


def card(check, notes, used):
    files, missing = expand(check["see"])
    refs, _ = expand(check["ref"])
    src_time = 0.0
    for p in check["src"]:
        for h in glob.glob(os.path.join(ROOT, p)):
            src_time = max(src_time, os.path.getmtime(h))
    used.update(files)
    used.update(refs)
    stamp = max([os.path.getmtime(f) for f in files] or [0])
    e = html.escape
    parts = [f'<article class="check{" done" if check["done"] else ""}" id="{e(check["id"])}" data-id="{e(check["id"])}" '
             f'data-stamp="{int(stamp)}" data-title="{e(check["title"])}">',
             f'<header><h3>{e(check["title"])}</h3><span class="id">{e(check["id"])}</span>'
             + ('<span class="badge ok">ticked in VERIFY.md</span>' if check["done"] else "") + "</header>",
             f'<p class="judge">{e(check["judge"])}</p>']
    for n in check["notes"]:
        parts.append(f'<p class="note">Note: {e(n)}</p>')
    if check["make"]:
        parts.append(f'<p class="make">Remake: <code>{e(check["make"])}</code></p>')
    if missing:
        parts.append('<p class="warn">Not on disk yet: ' + ", ".join(f"<code>{e(m)}</code>" for m in missing)
                     + (f' — run <code>{e(check["make"])}</code>' if check["make"] else "") + "</p>")
    if refs:
        parts.append('<div class="refs"><span>References</span>' + "".join(
            f'<img src="{e(os.path.relpath(r, PAGE_DIR).replace(chr(92), "/"))}" loading="lazy" title="{e(rel(r))}" class="zoom">'
            for r in refs) + "</div>")
    imgs = [f for f in files if f.lower().endswith((".png", ".jpg", ".jpeg"))]
    wavs = [f for f in files if f.lower().endswith(".wav")]
    pages = [f for f in files if f.lower().endswith(".html")]
    if imgs:
        parts.append('<div class="grid">')
        for f in imgs:
            t = os.path.getmtime(f)
            stale = src_time and t < src_time
            parts.append(f'<figure><img src="{e(os.path.relpath(f, PAGE_DIR).replace(chr(92), "/"))}" loading="lazy" class="zoom" '
                         f'title="{e(rel(f))}"><figcaption>{e(os.path.splitext(os.path.basename(f))[0])}'
                         f' <small>{when(t)}</small>' + (' <b class="stale">stale</b>' if stale else "")
                         + "</figcaption></figure>")
        parts.append("</div>")
    if wavs:
        parts.append('<div class="sounds"><button class="playall">Play all in order</button><ol>')
        for f in wavs:
            name = os.path.splitext(os.path.basename(f))[0]
            parts.append(f'<li><span class="sname">{e(name)}</span><audio controls preload="none" '
                         f'src="{e(os.path.relpath(f, PAGE_DIR).replace(chr(92), "/"))}"></audio>'
                         f'<span class="what">{e(notes.get(name, ""))}</span>'
                         f'<span class="mini"><button data-v="ok">ok</button><button data-v="bad">bad</button></span></li>')
        parts.append("</ol></div>")
    for f in pages:
        parts.append(f'<p><a href="{e(os.path.relpath(f, PAGE_DIR).replace(chr(92), "/"))}" target="_blank">{e(rel(f))}</a></p>')
    parts.append('<footer><button data-v="ok">OK</button><button data-v="issue">Issue</button><button data-v="">Clear</button>'
                 '<textarea placeholder="What is wrong, where (file name, which zombie, which second)"></textarea>'
                 '<span class="verdict"></span></footer></article>')
    return "\n".join(parts)


def main():
    text = open(os.path.join(ROOT, "VERIFY.md"), encoding="utf-8").read()
    sections = parse(text)
    notes = sound_notes()
    used = set()
    body, nav = [], []
    total = done = 0
    for name, checks in sections:
        sid = re.sub(r"\W+", "_", name.lower())
        nav.append(f'<a href="#{sid}">{html.escape(name)}</a>')
        nav += [f'<a class="sub" href="#{c["id"]}" data-for="{c["id"]}">{html.escape(c["title"])}</a>' for c in checks]
        body.append(f'<section id="{sid}"><h2>{html.escape(name)}</h2>')
        for c in checks:
            body.append(card(c, notes, used))
            total += 1
            done += c["done"]
        body.append("</section>")
    rest = [f for f in sorted(os.path.normpath(h) for h in glob.glob(os.path.join(ROOT, "references", "shots", "**", "*"), recursive=True))
            if f.lower().endswith(MEDIA) and f not in used and os.path.basename(f) != "index.html"]
    if rest:
        nav.append('<a href="#unlisted">Not in any check</a>')
        body.append('<section id="unlisted"><h2>Not in any check</h2><p class="judge">On disk but no check of VERIFY.md names them: '
                    'add a check or delete them.</p>' + card({"done": False, "id": "unlisted", "title": "Unlisted files",
                    "judge": "", "see": [rel(f) for f in rest], "ref": [], "make": "", "src": [], "notes": []}, notes, set())
                    + "</section>")
    page = TEMPLATE.replace("%NAV%", "\n".join(nav)).replace("%BODY%", "\n".join(body)) \
        .replace("%STATS%", html.escape(stats())).replace("%WHEN%", when(datetime.datetime.now().timestamp())) \
        .replace("%COUNT%", f"{done} / {total} ticked in VERIFY.md")
    with open(OUT, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"{rel(OUT)}: {total} checks ({done} ticked), {len(used)} files, {len(rest)} not in any check")


TEMPLATE = r"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Make Alive — verify</title>
<style>
:root { --bg:#111316; --card:#1a1d22; --line:#2a2f36; --fg:#cfd3d8; --dim:#8a919a; --ok:#4caf6a; --bad:#e0564f; --warn:#d9a441; }
* { box-sizing: border-box; }
body { background: var(--bg); color: var(--fg); font: 14px/1.45 system-ui, sans-serif; margin: 0; display: flex; }
nav { position: sticky; top: 0; height: 100vh; overflow: auto; width: 250px; flex: none; padding: 16px; border-right: 1px solid var(--line); }
nav a { display: block; color: var(--fg); text-decoration: none; padding: 2px 0; font-weight: 600; margin-top: 8px; }
nav a.sub { font-weight: 400; color: var(--dim); margin: 0 0 0 10px; font-size: 13px; }
nav a.sub.ok::before { content: "✓ "; color: var(--ok); } nav a.sub.issue::before { content: "✗ "; color: var(--bad); }
main { flex: 1; padding: 20px 28px; min-width: 0; }
h1 { margin: 0 0 4px; } h2 { border-bottom: 1px solid var(--line); padding-bottom: 6px; margin-top: 36px; }
pre.stats { color: var(--dim); font-size: 12px; background: var(--card); padding: 8px 12px; border-radius: 6px; display: inline-block; }
.tools { margin: 10px 0; display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.check { background: var(--card); border: 1px solid var(--line); border-radius: 8px; padding: 14px 16px; margin: 16px 0; }
.check.v-ok { border-color: var(--ok); } .check.v-issue { border-color: var(--bad); } .check.done { opacity: .75; }
.check header { display: flex; gap: 10px; align-items: baseline; } .check h3 { margin: 0; }
.id { color: var(--dim); font-family: monospace; } .badge.ok { color: var(--ok); font-size: 12px; }
.judge { margin: 6px 0; } .note { color: var(--warn); margin: 4px 0; } .make { color: var(--dim); margin: 4px 0; font-size: 12px; }
.warn { color: var(--warn); } code { background: #0c0d10; padding: 1px 5px; border-radius: 3px; }
.refs { display: flex; gap: 6px; overflow-x: auto; padding: 6px 0; align-items: center; }
.refs span { color: var(--dim); writing-mode: vertical-rl; transform: rotate(180deg); font-size: 11px; }
.refs img { height: 120px; border-radius: 4px; cursor: zoom-in; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(var(--thumb, 300px), 1fr)); gap: 10px; margin-top: 8px; }
figure { margin: 0; } figure img { width: 100%; display: block; border-radius: 4px; cursor: zoom-in; background: #000; }
figcaption { font-size: 12px; padding: 3px 0; word-break: break-all; } figcaption small { color: var(--dim); }
.stale { color: var(--warn); }
.sounds ol { padding-left: 22px; margin: 8px 0; } .sounds li { display: grid; grid-template-columns: 150px 300px 1fr auto; gap: 10px; align-items: center; padding: 2px 0; }
.sounds li.playing { background: #23303a; } .sname { font-family: monospace; font-size: 12px; } .what { color: var(--dim); }
.sounds audio { width: 300px; height: 30px; } .mini button { padding: 1px 6px; font-size: 11px; }
.sounds li.s-ok .sname { color: var(--ok); } .sounds li.s-bad .sname { color: var(--bad); }
footer { display: flex; gap: 8px; margin-top: 12px; align-items: flex-start; }
footer textarea { flex: 1; min-height: 34px; background: #0c0d10; color: var(--fg); border: 1px solid var(--line); border-radius: 4px; padding: 6px; font: inherit; }
button { background: #262b33; color: var(--fg); border: 1px solid var(--line); border-radius: 4px; padding: 5px 12px; cursor: pointer; font: inherit; }
button[data-v=ok]:hover, button.on[data-v=ok] { background: var(--ok); color: #000; } button[data-v=issue]:hover, button.on[data-v=issue], button.on[data-v=bad] { background: var(--bad); color: #000; }
.verdict { color: var(--dim); font-size: 12px; align-self: center; }
#box { position: fixed; inset: 0; background: rgba(0,0,0,.92); display: none; align-items: center; justify-content: center; flex-direction: column; z-index: 9; }
#box img { max-width: 96vw; max-height: 90vh; } #box p { color: var(--fg); margin: 8px; }
</style></head><body>
<nav><b>Make Alive — verify</b><br><small>%COUNT%</small>%NAV%</nav>
<main>
<h1>Verification dashboard</h1>
<p>Made %WHEN% by <code>python tools/verify_page.py</code> from <code>VERIFY.md</code>. Your verdicts stay in this browser.
Click a picture for a large view (← → step through the check, Esc closes).</p>
<pre class="stats">%STATS%</pre>
<div class="tools"><button id="copy">Copy verdicts as Markdown</button><button id="hideok">Hide checks marked OK</button>
<label>Thumbnails <input type="range" id="thumb" min="160" max="700" value="300"></label><span id="msg"></span></div>
%BODY%
</main>
<div id="box"><img><p></p></div>
<script>
const KEY = 'make-alive-verify';
const store = JSON.parse(localStorage.getItem(KEY) || '{}');
const save = () => localStorage.setItem(KEY, JSON.stringify(store));
function paint(card) {
  const s = store[card.dataset.id] || {};
  card.classList.toggle('v-ok', s.v === 'ok'); card.classList.toggle('v-issue', s.v === 'issue');
  card.querySelectorAll('footer button').forEach(b => b.classList.toggle('on', !!s.v && b.dataset.v === s.v));
  const changed = s.v && s.stamp && +card.dataset.stamp > s.stamp;
  card.querySelector('.verdict').textContent = s.v ? (s.v.toUpperCase() + ' ' + (s.at || '') + (changed ? ' — files changed since' : '')) : '';
  const link = document.querySelector(`nav a[data-for="${card.dataset.id}"]`);
  if (link) { link.classList.toggle('ok', s.v === 'ok'); link.classList.toggle('issue', s.v === 'issue'); }
  card.querySelectorAll('.sounds li').forEach(li => {
    const n = li.querySelector('.sname').textContent, v = (s.sounds || {})[n];
    li.classList.toggle('s-ok', v === 'ok'); li.classList.toggle('s-bad', v === 'bad');
  });
}
document.querySelectorAll('.check').forEach(card => {
  const id = card.dataset.id, ta = card.querySelector('footer textarea');
  ta.value = (store[id] || {}).note || '';
  ta.addEventListener('input', () => { store[id] = Object.assign(store[id] || {}, { note: ta.value }); save(); });
  card.querySelectorAll('footer button').forEach(b => b.onclick = () => {
    store[id] = Object.assign(store[id] || {}, { v: b.dataset.v, at: new Date().toISOString().slice(0, 16).replace('T', ' '), stamp: +card.dataset.stamp });
    save(); paint(card);
  });
  card.querySelectorAll('.sounds li').forEach(li => li.querySelectorAll('.mini button').forEach(b => b.onclick = () => {
    const s = store[id] = store[id] || {}; s.sounds = s.sounds || {};
    const n = li.querySelector('.sname').textContent;
    s.sounds[n] = s.sounds[n] === b.dataset.v ? undefined : b.dataset.v; save(); paint(card);
  }));
  const all = card.querySelector('.playall');
  if (all) all.onclick = () => {
    const items = [...card.querySelectorAll('.sounds li')]; let i = 0;
    const next = () => { items.forEach(l => l.classList.remove('playing')); if (i >= items.length) return;
      const li = items[i++], a = li.querySelector('audio'); li.classList.add('playing'); li.scrollIntoView({ block: 'nearest' });
      a.currentTime = 0; a.play(); const d = Math.min((a.duration || 3) * 1000, 4000) + 400; setTimeout(() => { a.pause(); next(); }, d); };
    next();
  };
  paint(card);
});
document.querySelectorAll('audio').forEach(a => a.addEventListener('play', () =>
  document.querySelectorAll('audio').forEach(o => { if (o !== a) o.pause(); })));
document.getElementById('copy').onclick = () => {
  const lines = ['Verdicts from references/verify.html (' + new Date().toISOString().slice(0, 16).replace('T', ' ') + '):', ''];
  document.querySelectorAll('.check').forEach(card => {
    const s = store[card.dataset.id]; if (!s || (!s.v && !s.note && !s.sounds)) return;
    lines.push(`- ${s.v === 'ok' ? '[x]' : '[ ]'} **${card.dataset.id}** · ${card.dataset.title}: ${s.v ? s.v.toUpperCase() : 'no verdict'}${s.note ? ' — ' + s.note.replace(/\n/g, ' ') : ''}`);
    const bad = Object.entries(s.sounds || {}).filter(([, v]) => v === 'bad').map(([n]) => n);
    if (bad.length) lines.push(`  - sounds that are wrong: ${bad.join(', ')}`);
  });
  navigator.clipboard.writeText(lines.join('\n')).then(() => { document.getElementById('msg').textContent = 'Copied ' + (lines.length - 2) + ' lines.'; });
};
document.getElementById('hideok').onclick = e => {
  const on = e.target.classList.toggle('on');
  document.querySelectorAll('.check').forEach(c => c.style.display = on && (store[c.dataset.id] || {}).v === 'ok' ? 'none' : '');
};
document.getElementById('thumb').oninput = e => document.documentElement.style.setProperty('--thumb', e.target.value + 'px');
const box = document.getElementById('box'), bimg = box.querySelector('img'), bcap = box.querySelector('p');
let set = [], at = 0;
const show = () => { bimg.src = set[at].src; bcap.textContent = set[at].title + '  (' + (at + 1) + ' / ' + set.length + ')'; };
document.querySelectorAll('img.zoom').forEach(img => img.onclick = () => {
  set = [...img.closest('.check, .refs').querySelectorAll('img.zoom')]; at = set.indexOf(img); show(); box.style.display = 'flex';
});
box.onclick = () => box.style.display = 'none';
document.addEventListener('keydown', e => {
  if (box.style.display !== 'flex') return;
  if (e.key === 'Escape') box.style.display = 'none';
  if (e.key === 'ArrowRight') { at = (at + 1) % set.length; show(); }
  if (e.key === 'ArrowLeft') { at = (at - 1 + set.length) % set.length; show(); }
});
</script></body></html>
"""

if __name__ == "__main__":
    main()
