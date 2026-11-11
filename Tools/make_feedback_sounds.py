#!/usr/bin/env python3
"""Render Gooby's UI sound effects from the earshot sound bank.

earshot (https://github.com/Leonxlnx/earshot, MIT) stores its 252 sounds as synthesis recipes and renders them by
id with no models and no network. Every cue below layers one or more bank sounds, tuned to C major pentatonic so
the whole set sounds like one instrument family. Only forge and 0.4 members are used, never the `fit/*` entries
derived from recordings, so the output carries no third-party sample.

Setup (Python 3.10+, ffmpeg on PATH):
    git clone https://github.com/Leonxlnx/earshot /tmp/earshot
    uv venv /tmp/earshot/.venv
    uv pip install --python /tmp/earshot/.venv/bin/python numpy scipy soundfile soxr librosa pyloudnorm scikit-learn pillow matplotlib
    uv pip install --python /tmp/earshot/.venv/bin/python --no-deps -e /tmp/earshot
    /tmp/earshot/.venv/bin/python Tools/make_feedback_sounds.py

Writes Gooby/Resources/Feedback/Audio/sfx-*.wav (mono, 44.1 kHz, 16-bit) and prints the model-free audit per file.
"""

import sys
from pathlib import Path

import numpy as np
import pyloudnorm
import soundfile
import soxr
from earshot.forge import bank, sfx

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Gooby" / "Resources" / "Feedback" / "Audio"
SR = 48000
OUT_SR = 44100


def layer(sound, at=0.0, gain=1.0, **knobs):
    return {"sound": sound, "at": at, "gain": gain, "knobs": knobs}


# name: (peak dBFS of the finished file, layers). Peaks stay low: the app plays these under a 0.8 master volume.
CUES = {
    "tap": (-14, [layer("ui_pop/soft", pitch="E5")]),
    "tab": (-13, [layer("ui_pop/step", pitch="G5")]),
    "toggle-on": (-13, [layer("ui_pop/soft", pitch="G5"), layer("ui_pop/soft", at=0.05, gain=0.7, pitch="C6")]),
    "toggle-off": (-13, [layer("ui_pop/fall", pitch="C5")]),
    "select": (-14, [layer("knock/wood", pitch="E5")]),
    "sheet": (-18, [layer("swish/soft", dur=0.34), layer("ui_pop/wide", at=0.11, gain=0.5, pitch="G5")]),
    "goal-done": (-6, [
        layer("ui_pop/soft", pitch="C5", gain=0.6),
        layer("mallet/celesta", at=0.05, pitch="G5"),
        layer("mallet/celesta", at=0.16, pitch="C6"),
    ]),
    "goal-undo": (-12, [layer("ui_pop/fall", pitch="A4")]),
    "all-done": (-4, [
        layer("mallet/flourish", pitch="C6"),
        layer("mallet/celesta", at=0.42, pitch="G6", gain=0.6),
        layer("shimmer/m2", at=0.1, dur=1.4, gain=0.25),
    ]),
    "coins": (-8, [
        layer("mallet/glock", pitch="E6", gain=0.8),
        layer("mallet/glock", at=0.06, pitch="G6", gain=0.8),
        layer("mallet/glock", at=0.12, pitch="C7"),
    ]),
    "purchase": (-7, [
        layer("knock/wood", pitch="C5", gain=0.7),
        layer("mallet/glock", at=0.08, pitch="G6", gain=0.8),
        layer("mallet/glock", at=0.14, pitch="C7"),
    ]),
    "level-up": (-3, [
        layer("mallet/up4", pitch="C5"),
        layer("mallet/celesta", at=0.62, pitch="C7", gain=0.7),
        layer("shimmer/m2", at=0.2, dur=1.6, gain=0.3),
    ]),
    "gift": (-4, [
        layer("swish/bright", dur=0.3, gain=0.45),
        layer("drip/bubble", at=0.2, pitch="G4", gain=0.8),
        layer("mallet/flourish", at=0.3, pitch="G5"),
    ]),
    "hatch": (-5, [
        layer("knock/snap", pitch="E6", gain=0.55),
        layer("knock/snap", at=0.12, pitch="G6", gain=0.65),
        layer("ui_pop/wide", at=0.24, pitch="C5"),
        layer("mallet/celesta", at=0.3, pitch="E6", gain=0.7),
        layer("mallet/celesta", at=0.4, pitch="A6", gain=0.6),
    ]),
    "boop": (-9, [layer("drip/bloop", pitch="G4")]),
    "giggle": (-9, [
        layer("drip/plink", pitch="C6", gain=0.8),
        layer("drip/plink", at=0.08, pitch="E6", gain=0.85),
        layer("drip/plink", at=0.16, pitch="G6"),
    ]),
    "quest-done": (-6, [
        layer("notify/mid_tine", pitch="C6"),
        layer("mallet/glock", at=0.12, pitch="E7", gain=0.45),
        layer("mallet/glock", at=0.18, pitch="G7", gain=0.45),
    ]),
    "notice": (-9, [layer("notify/mid_wood", pitch="G5"), layer("notify/mid_wood", at=0.11, pitch="C6", gain=0.8)]),
    "error": (-11, [layer("ui_pop/boop", pitch="E4"), layer("ui_pop/boop", at=0.12, pitch="C4", gain=0.85)]),
    "calm": (-8, [layer("pluck/kalimba_soft", pitch="E5", dur=1.6), layer("pluck/kalimba_soft", at=0.28, pitch="A5", dur=1.4, gain=0.7)]),
    "save": (-11, [layer("mallet/marimba", pitch="G5")]),
    "notify": (-3, [
        layer("pluck/kalimba", pitch="G5", dur=1.2),
        layer("pluck/kalimba", at=0.16, pitch="C6", dur=1.2, gain=0.85),
    ]),
}


def render_layer(spec):
    knobs = {k: v for k, v in spec["knobs"].items() if v is not None}
    y, _ = bank.render(spec["sound"], peak_db=-1, checks=False, **knobs)
    y = np.asarray(y, dtype=np.float64)
    if y.ndim == 2:
        y = y.mean(axis=1)
    return y * spec["gain"]


def mix(layers):
    parts = [(int(round(spec["at"] * SR)), render_layer(spec)) for spec in layers]
    length = max(start + len(y) for start, y in parts)
    out = np.zeros(length)
    for start, y in parts:
        out[start:start + len(y)] += y
    return out


def finish(y, peak_db):
    floor = np.max(np.abs(y)) * 10 ** (-60 / 20)
    loud = np.nonzero(np.abs(y) > floor)[0]
    y = y[: loud[-1] + 1] if len(loud) else y
    fade = min(len(y), max(int(0.02 * SR), len(y) // 4))
    y[-fade:] *= np.linspace(1, 0, fade)
    y = y - np.mean(y)
    y = y / max(1e-9, np.max(np.abs(y))) * 10 ** (peak_db / 20)
    return y


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    meter = pyloudnorm.Meter(SR, block_size=0.05)
    failed = []
    for name, (peak_db, layers) in CUES.items():
        y = finish(mix(layers), peak_db)
        audit = sfx.check(y.astype(np.float32), sr=SR)
        loudness = meter.integrated_loudness(np.pad(y, (0, max(0, int(0.4 * SR) - len(y)))))
        soundfile.write(OUT / f"sfx-{name}.wav", soxr.resample(y, SR, OUT_SR), OUT_SR, subtype="PCM_16")
        warnings = ", ".join(w["code"] for w in audit["warnings"]) or "clean"
        print(f"sfx-{name:12s} {len(y) / SR:5.2f} s  peak {peak_db:+d} dBFS  {loudness:6.1f} LUFS  {warnings}")
        if audit["warnings"]:
            failed.append(name)
    return 1 if failed and "--strict" in sys.argv else 0


if __name__ == "__main__":
    sys.exit(main())
