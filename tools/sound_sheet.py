r"""Draw every world sound's waveform and spectrogram on one sheet, to review them by eye.

    tools\sounds.ps1   (tools/sound_sheet.tscn writes references/shots/sounds/*.wav, then this draws sheet.png)

Each row: the name, what it should be (WHAT below, from the step's list), its waveform (level over
time) and its spectrogram (time across, 50 Hz .. 11 kHz up, log scale): wood sits low and wide,
metal in thin high lines, glass higher still, clicks are vertical strokes, hums horizontal lines.
"""
import os
import sys
import wave

import numpy as np
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, "references", "shots", "sounds")

WHAT = {
    "door_handle": "lever down and up: two clicks, a spring",
    "door_creak": "wooden hinge: stick-slip creak, swells and fades",
    "door_slam": "panel into frame: low thump, crack, boards ring, latch, rattle",
    "door_open": "handle, then the creak",
    "door_close": "a short creak, then the slam",
    "locked_rattle": "handle shaken against a lock: clacks and knocks",
    "door_splinter": "a blow on a door: thud and tearing fibres",
    "door_break": "the door gives: crash, long tear, planks clatter",
    "hammer_knock": "hammer on a nail: steel ring over a wood knock",
    "plank_crack": "plank strained: creak, then a crack",
    "plank_snap": "plank snaps: one sharp crack, splinters",
    "latch": "a box's catch: click and spring",
    "lid_creak": "metal hinge: higher, thinner creak",
    "rummage": "hands in a box: rustles and knocks",
    "lootbox_open": "latch, lid, rummage",
    "crate_open": "two latches, heavy lid, rummage",
    "ammo_clink": "rounds from a carton: card and clinks",
    "medkit_zip": "zip: a run of teeth",
    "key_jingle": "keys: thin steel rings one after another",
    "glass_crack": "bullet star: tick and quick crackle, bright",
    "glass_shatter": "pane breaks: burst and a shower of rings",
    "glass_shards": "shards falling, sparse tinkles",
    "glass_crunch": "boot on glass: thud and gritty crackle",
    "ui_hover": "a soft high tick",
    "ui_click": "a crisp two-step click",
    "ui_back": "a falling blip",
    "ui_error": "two low buzzes",
    "objective_chime": "three bell notes rising",
    "wave_horn": "long low horn, a fifth, swelling",
    "car_alarm": "loop: four whoops up, then a warble",
    "hazard_tick": "loop: relay tick ... tock",
    "horn_stuck": "loop: two nasal notes, steady",
    "engine_tick": "loop: irregular metal ticks",
    "generator": "loop: 25 firings a second, low",
    "tube_buzz": "loop: 100 Hz mains hum, a crackle now and then",
    "sign_creak": "loop: a slow creak each way",
}


def read(path):
    with wave.open(path) as w:
        rate = w.getframerate()
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
    return x, rate


def spectrogram(x, rate, n=512, hop=96):
    if len(x) < n:
        x = np.pad(x, (0, n - len(x)))
    frames = np.lib.stride_tricks.sliding_window_view(x, n)[::hop] * np.hanning(n)
    mag = np.abs(np.fft.rfft(frames, axis=1)).T
    freqs = np.fft.rfftfreq(n, 1.0 / rate)
    # resample onto a log axis 50 Hz .. rate/2
    logf = np.geomspace(50.0, rate / 2.0, 96)
    idx = np.clip(np.searchsorted(freqs, logf), 0, len(freqs) - 1)
    db = 20 * np.log10(mag[idx] + 1e-5)
    return np.clip(db, db.max() - 45, None), logf


def main():
    names = [n for n in WHAT if os.path.exists(os.path.join(DIR, n + ".wav"))]
    if not names:
        sys.exit("no wavs: run tools/sounds.ps1")
    cols = 2
    rows = (len(names) + cols - 1) // cols
    fig = plt.figure(figsize=(22, rows * 1.15), dpi=90, facecolor="#15161a")
    for i, name in enumerate(names):
        x, rate = read(os.path.join(DIR, name + ".wav"))
        c, r = divmod(i, rows)
        left = 0.01 + c * 0.5
        top = 1.0 - (r + 1) / rows
        h = 1.0 / rows * 0.82
        fig.text(left, top + h * 0.75, name, color="#f0e6d0", fontsize=11, weight="bold")
        fig.text(left, top + h * 0.38, WHAT[name], color="#a8a294", fontsize=8.5, wrap=True)
        fig.text(left, top + h * 0.05, "%.2f s  peak %.2f" % (len(x) / rate, np.abs(x).max()), color="#6f6a60", fontsize=8)
        t = np.arange(len(x)) / rate
        ax = fig.add_axes([left + 0.13, top, 0.12, h])
        ax.plot(t, x, color="#e8c47a", lw=0.4)
        ax.set_xlim(0, max(t[-1], 0.05))
        ax.set_ylim(-1, 1)
        ax.axis("off")
        db, logf = spectrogram(x, rate)
        ax2 = fig.add_axes([left + 0.26, top, 0.22, h])
        ax2.imshow(db, origin="lower", aspect="auto", cmap="magma",
                   extent=[0, len(x) / rate, 0, len(logf)])
        ticks = [100, 300, 1000, 3000, 10000]
        ax2.set_yticks([np.searchsorted(logf, f) for f in ticks])
        ax2.set_yticklabels(["100", "300", "1k", "3k", "10k"], fontsize=6, color="#777")
        ax2.tick_params(axis="x", labelsize=6, colors="#777", length=2)
        for s in ax2.spines.values():
            s.set_visible(False)
    out = os.path.join(DIR, "sheet.png")
    fig.savefig(out, facecolor=fig.get_facecolor())
    print("sheet:", out)


if __name__ == "__main__":
    main()
