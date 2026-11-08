#!/usr/bin/env python3
"""Listens to Gooby's bundled audio with earshot (https://github.com/Leonxlnx/earshot, MIT) and prints one
line per file: the model-free audit (`earshot sfx check`: clicks, cut tails, clipping, DC, ring), what it sounds
most like (`describe`), how well its intended description fits against the ways it could go wrong (`match` with
alternatives) and whether it reads as a recording or as code (`realness`). Soundscapes also get a seam check
(the step from the last sample to the first against the loop's own largest steps).

    python Tools/check_sounds.py            every file
    python Tools/check_sounds.py tap rain   only these names

Needs earshot from a clone with its two models cached (`earshot doctor --fetch`) and ffmpeg on PATH.
"""
import glob
import os
import sys

import numpy as np
import soundfile as sf

from earshot import api, audio

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, 'Gooby', 'Resources', 'Sounds')
SCAPE_DIR = os.path.join(ROOT, 'Gooby', 'Resources', 'Shell', 'Audio')

BAD = ['an error buzz', 'a digital glitch', 'a harsh sound']
INTENT = {
    'tap': 'a bubble pop', 'tab': 'a wooden block hit', 'toggle-on': 'a toggle switch click',
    'toggle-off': 'a toggle switch click', 'sheet-open': 'a soft air whoosh', 'sheet-close': 'a soft air whoosh',
    'check': 'a success chime', 'all-done': 'a success chime', 'undo': 'a bubble pop', 'skip': 'a short swish',
    'sparkle': 'a magic sparkle chime', 'coin': 'a bright coin ding', 'energy': 'a magic sparkle chime',
    'level-up': 'a success chime', 'depart': 'a fast whoosh', 'return': 'a kalimba note', 'boop': 'a mouth pop',
    'hatch': 'a success chime', 'knock': 'a wooden block hit', 'equip': 'cloth whipping through the air',
    'page': 'a kalimba note', 'focus-start': 'a marimba', 'focus-pause': 'a marimba', 'chime': 'a kalimba note',
    'notify': 'a notification ding',
    'mood-1': 'a kalimba note', 'mood-2': 'a kalimba note', 'mood-3': 'a kalimba note', 'mood-4': 'a kalimba note',
    'mood-5': 'a kalimba note',
    'rain': 'rain on a roof', 'ocean': 'ocean waves', 'forest': 'a forest ambience with birds singing',
    'wind': 'wind blowing', 'fire': 'a crackling fire', 'nature': 'a stream flowing with birds in the distance',
}
SCAPE_ALTS = ['white noise', 'a computer fan hum', 'an error buzz', 'a digital glitch']


def seam(path):
    y = audio.load(path, sr=sf.info(path).samplerate if path.endswith('.wav') else 44100, cache=False)
    steps = np.abs(np.diff(y, axis=0)).max(axis=1)
    jump = np.abs(y[0] - y[-1]).max()
    return jump, float(np.percentile(steps, 99.9))


def short(text, n=60):
    return text if len(text) <= n else text[:n - 1] + '…'


def check(path, name, scape):
    intent = INTENT.get(name, name)
    alts = SCAPE_ALTS if scape else BAD
    d = api.describe(path)
    tops = ', '.join(f"{t['term']} {t['z']:+.1f}" for t in d['top_tags'][:2])
    m = api.match(path, intent, alts=alts)
    real = api.realness(path)
    line = (f"{os.path.basename(path):<22} '{intent}': {m['verdict']} (z {m['z']:+.2f}, {100 * m['p_vs_alts']:.0f}% vs "
            f"{'noise/hum/buzz/glitch' if scape else 'buzz/glitch/harsh'}); most like {tops}; "
            f"realness {real['verdict']} (p {float(real['p_real']):.2f})")
    if scape:
        jump, top = seam(path)
        line += f"; loop seam step {jump:.4f} = {jump / top:.2f}x the loop's 99.9th-percentile step (a click: > 1)"
    else:
        a = api.sfx_check(path)
        line += '; audit ' + ('clean' if a['ok'] else 'WARN ' + '; '.join(w['code'] for w in a['warnings']))
    print(line, flush=True)


def main():
    only = set(sys.argv[1:])
    files = [(p, os.path.basename(p)[4:-4], False) for p in sorted(glob.glob(os.path.join(SFX_DIR, 'sfx-*.wav')))]
    files += [(p, os.path.basename(p)[6:-4], True) for p in sorted(glob.glob(os.path.join(SCAPE_DIR, 'sound-*.*')))]
    for path, name, scape in files:
        if not only or name in only:
            check(path, name, scape)


if __name__ == '__main__':
    main()
