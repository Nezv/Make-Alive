"""Reference photos from Wikimedia Commons for an element's card (references/elements/WORKFLOW.md).

    python tools/commons.py cat "Windows in Paris"            -> the files of a category
    python tools/commons.py cat "Windows in Paris" subcat     -> its subcategories
    python tools/commons.py search "persiennes Paris"         -> files whose text matches
    python tools/commons.py get references/elements/<name> < list.txt
        list.txt: one `file.jpg=File:Title on Commons.jpg` per line; writes each (1920 px wide: a width Commons keeps ready; others are rendered on demand and rate-limited) and
        prints one JSON line per file (title, page, licence, author) for the card's table.

Requests go slowly and back off when Commons says too many; the client names itself generically.
"""
import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

UA = {"User-Agent": "element-refs/1.0 (game asset research)"}
API = "https://commons.wikimedia.org/w/api.php"


def fetch(url, tries=6):
    req = urllib.request.Request(url, headers=UA)
    for k in range(tries):
        try:
            time.sleep(1.5)
            return urllib.request.urlopen(req, timeout=60).read()
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
            time.sleep(10 * (k + 1))
    raise SystemExit("Commons keeps saying too many requests: wait a minute")


def query(**p):
    p["format"] = "json"
    return json.loads(fetch(API + "?" + urllib.parse.urlencode(p)))


def category(name, kind="file", n=100):
    r = query(action="query", list="categorymembers", cmtitle="Category:" + name, cmtype=kind, cmlimit=n)
    return [m["title"] for m in r.get("query", {}).get("categorymembers", [])]


def search(text, n=30):
    r = query(action="query", list="search", srsearch=text + " filetype:bitmap", srnamespace=6, srlimit=n)
    return [m["title"] for m in r.get("query", {}).get("search", [])]


def info(title, width=1920):
    r = query(action="query", titles=title, prop="imageinfo", iiprop="url|extmetadata", iiurlwidth=width)
    page = next(iter(r["query"]["pages"].values()))
    ii = page.get("imageinfo", [{}])[0]
    md = ii.get("extmetadata", {})
    return dict(title=page.get("title", title), thumb=ii.get("thumburl"), page=ii.get("descriptionurl"),
                licence=md.get("LicenseShortName", {}).get("value"),
                author=re.sub("<[^>]+>", "", md.get("Artist", {}).get("value", "")).strip())


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stdin.reconfigure(encoding="utf-8")
    cmd = sys.argv[1]
    if cmd == "cat":
        print("\n".join(category(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "file")))
    elif cmd == "search":
        print("\n".join(search(sys.argv[2])))
    elif cmd == "get":
        out = sys.argv[2]
        os.makedirs(out, exist_ok=True)
        for line in sys.stdin:
            if "=" not in line:
                continue
            name, title = line.strip().split("=", 1)
            data = None
            for w in (int(os.environ.get("WIDTH", "1920")), 1280, 960):  # a thumbnail not rendered yet may be refused: a smaller one
                i = info(title, w)
                if not i["thumb"]:
                    break
                try:
                    data = fetch(i["thumb"], tries=2)
                    break
                except SystemExit:
                    continue
            if data is None:
                print("missing:", title)
                continue
            open(os.path.join(out, name), "wb").write(data)
            print(json.dumps({"file": name, **{k: i[k] for k in ("title", "page", "licence", "author")}}, ensure_ascii=False))


if __name__ == "__main__":
    main()
