# How an element is made

The order every element step follows (ROADMAP.md, "Detail and iteration", says why). Each stage has
a tool that shows the work beside the references, and something to write on the card. A stage
with nothing written down did not happen. The worked examples are the hydrant (`street.py`, the
first) and window_french (`windows.py`, the first made this way from the start).

| stage | tool | seconds | what it catches |
|---|---|---|---|
| 1 references | Commons, `references/elements/<name>/` | | modelling from memory |
| 2 scale | `match.py <name> --grid` | 2 | sizes guessed instead of measured |
| 3 blockout | `props.py <name> --sketch` | 2 | parts missing, wrong pivots, parts that open into each other |
| 4 match | `match.py <name> --round=N` | 3 | proportions off by centimetres: two lines apart |
| 5 build | `tools\blender.ps1 tools\models\props.py <name>` | 60-150 | |
| 6 review | `review.py <name> --round=N` | 20 | the bake, the paint, the LODs, the states, the 50 m read |
| 7 card | `references/elements/<name>.md` | | rounds that leave nothing behind |

## 1 · References
- At least two photos of real French examples (old Paris first), plus one that gives the **scale**
  (something of known size in the same plane: brick courses of 6.5 cm, a 2.1 m door, a kerb, a
  person) and one of the **worn** state. Square-on photos are worth most: they can be matched.
- Wikimedia Commons by category: `python tools/commons.py cat "Windows in Paris"` (add `subcat`
  for its subcategories), or `search "persiennes Paris"`; fetch with `get <folder> < list.txt`
  (`file.jpg=File:Title.jpg` per line), which prints source, author and licence for the card.
  Fetch the candidates small first into the scratchpad and look at them on one contact sheet;
  keep the best. Commons refuses bursts (429): `get` waits and falls back to smaller thumbnails; if it
  still refuses, wait a few minutes.

## 2 · Scale and measurements
- Write `references/elements/<name>/match.json` (format at the top of `tools/models/match.py`):
  per photo, four points on one plane (corners of the opening, the panel, the door) in pixels and
  the same points in the element's elevation in metres.
- `python tools/models/match.py <name> --grid` straightens each into `reviews/<name>_grid_<photo>.jpg`
  with a 10 cm grid. Read every size off it; write them on the card with what gave the scale. Where
  two references disagree, say which one the element follows and why.

## 3 · Blockout
- The family file: every measurement a named constant at its top, copied from the card. Parts
  that move are their own `Part` with a pivot and a motion; check the sketch's open row (they must
  not pass through the body). The first LOD's form only; nothing structural yet.

## 4 · Match (round 1 is not done until this agrees)
- `python tools/models/match.py <name> --round=1`: per photo, the photo straightened, the element's
  flat elevation, and the photo greyed with the element's edges over it in cyan. Put the parts as the
  photo shows them (`"open"`). Every line of the photo should have a cyan line on it; write each one
  that doesn't on the card (with how far off: the grid is 10 cm), fix it, run it again. Seconds a
  loop: do the whole of round 1 here before Blender.
- What it cannot judge: depth (judge on the review's close-ups and the side angles), anything off the
  matched plane, colour.

## 5-6 · Build and review
- Build, then `python tools/models/review.py <name> --round=N`. Read the whole sheet, then crop and
  read the close, far and open tiles at full size (they are what the sheet shrinks most).
- Point the 1 m close-up at what matters (`close` in the spec: a chimney's pots, not its render). Never a face and its reverse on the same corners: Blender merges them and the build fails; make sheets thin slabs.
- The rack frames the far views by the element's size (a 5 m shopfront is shown whole). A material marked `fixing` rusts all over: mark only the bolts.
- Look for what the match could not show: dark faces where a moving part touched something at rest
  (the AO is baked with the parts apart: `props._parts_apart`), a far LOD that changes what the thing
  says (a closed shutter reading as open), shading seams, the states all looking alike.

## Round checklists
Round 1 · form: the match agrees on every main line within 2 cm; the size is the card's (the test
holds it to 5 %); every moving part opens clear; LOD 1 and 2 keep the silhouette and say the same
thing at 50 m.

Round 2 · structure: every secondary form on the card's "Visible details" list is ticked M or B,
and each was looked for in at least two references; every edge the key light catches is chamfered;
hardware (hinges, catches, fixings, bolts) is where the photos put it, not where it is easy.

Round 3 · surface: the clean state's colours sampled against the photos (the match's straightened
photo beside the albedo); wear where the worn reference has it (bottom rails, sills, under fixings),
not spread evenly; every state shot and different at 10 m; lit / emission states at night.

Later rounds named in the step (use, night, variants) take the same form: a sheet, differences,
fixes.

## The card's rounds
Each round: the sheet's path, "Differences" (each one against a named reference), "Fixed", and
"Open" for what waits for a later round or another step (say which). The step is done when the
last round leaves only items accepted with a reason.
