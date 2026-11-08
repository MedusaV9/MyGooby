#!/usr/bin/env python3
"""Renders Gooby's bundled audio in code: the UI sound effects and the six soundscapes.

    python Tools/make_sounds.py sfx      UI effects    -> Gooby/Resources/Sounds/sfx-*.wav
    python Tools/make_sounds.py scapes   soundscapes   -> Gooby/Resources/Shell/Audio/sound-*.caf
    python Tools/make_sounds.py all      both (default)

The effects are takes from the sound bank of earshot (https://github.com/Leonxlnx/earshot, MIT;
sounds stored as code, rendered by id with `earshot.forge.bank.render`), layered, tuned to one key
(C major pentatonic) and leveled here. The soundscapes are synthesized here with numpy / scipy
(no recordings): every layer is periodic in the loop length, so the files loop without a seam.
Check both with Tools/check_sounds.py (earshot describe / match / realness / sfx check).

Needs earshot installed from a clone (python -m pip install -e <earshot>) and ffmpeg on PATH
(the soundscapes are written as IMA4 CAF, the compressed format Core Audio loops gaplessly).
Output is deterministic: every random draw has a fixed seed.
"""
import os
import shutil
import subprocess
import sys

import numpy as np
import soundfile as sf
import soxr
from scipy import signal

from earshot.forge import bank
from earshot.forge.polish import lufs_max

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SFX_DIR = os.path.join(ROOT, 'Gooby', 'Resources', 'Sounds')
SCAPE_DIR = os.path.join(ROOT, 'Gooby', 'Resources', 'Shell', 'Audio')
SR = 48000          # render rate (earshot's bank rate)
OUT_SR = 44100      # file rate


# ---------------------------------------------------------------------------------------------- shared helpers
def stereo(y):
    y = np.asarray(y, np.float64)
    return np.stack([y, y], axis=1) if y.ndim == 1 else y


def db(x):
    return 10 ** (x / 20)


def fade(y, fade_in=0.002, fade_out=0.03):
    y = y.copy()
    n_in, n_out = int(fade_in * SR), int(fade_out * SR)
    if n_in:
        y[:n_in] *= np.sin(np.linspace(0, np.pi / 2, n_in))[:, None] ** 2
    if n_out:
        y[-n_out:] *= np.cos(np.linspace(0, np.pi / 2, n_out))[:, None] ** 2
    return y


def trim_tail(y, floor_db=-62):
    """cut the silence after the last sample within floor_db of the peak (keeps 20 ms)"""
    env = np.abs(y).max(axis=1)
    above = np.nonzero(env > env.max() * db(floor_db))[0]
    end = min(len(y), (above[-1] if len(above) else len(y)) + int(0.02 * SR))
    return y[:end]


def write_wav(path, y, mono=False):
    y = soxr.resample(y, SR, OUT_SR)
    if mono:
        y = y.mean(axis=1)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    sf.write(path, np.clip(y, -1, 1).astype(np.float32), OUT_SR, subtype='PCM_16')


# ------------------------------------------------------------------------------------------------ UI effects
# Each effect: bank layers (id, start s, gain dB, render knobs) mixed, then leveled to a momentary-max
# loudness (LUFS, 400 ms K-weighted) so effects sit at one consistent level under each other:
# taps quiet, confirmations a little louder, celebrations and the notification chime loudest.
L = dict
SFX = {
    # plain feedback
    'tap':          dict(layers=[L(id='fit/pop/mouth_plop')], lufs=-31, mono=True),
    'tab':          dict(layers=[L(id='fit/tick/domino'), L(id='ui_pop/blip', at=0.004, gain=-12, pitch='G5')], lufs=-31, mono=True),
    'toggle-on':    dict(layers=[L(id='toggle/micro'), L(id='ui_pop/blip', at=0.012, gain=-16, pitch='C6')], lufs=-30, mono=True),
    'toggle-off':   dict(layers=[L(id='toggle/micro', seed=7)], lufs=-32, mono=True),
    'sheet-open':   dict(layers=[L(id='swipe/glide', dur=0.4, apex=0.16, seed=9)], lufs=-34),
    'sheet-close':  dict(layers=[L(id='swipe/glide', dur=0.3, apex=0.08)], lufs=-36),
    # goals
    'check':        dict(layers=[L(id='pro_pop/bloop', gain=-4), L(id='mallet/celesta', at=0.03, pitch='C6'),
                                 L(id='mallet/glock', at=0.03, gain=-11, pitch='G6')], lufs=-23),
    'all-done':     dict(layers=[L(id='pro_pop/bloop', gain=-6), L(id='mallet/up4', at=0.03),
                                 L(id='pro_shimmer/m3', at=0.28, gain=-9)], lufs=-21),
    'undo':         dict(layers=[L(id='fit/pop/mouth_plop', pitch='E5')], lufs=-30, mono=True),
    'skip':         dict(layers=[L(id='swish/flick', dur=0.26, apex=0.07)], lufs=-33),
    # rewards and growth
    'sparkle':      dict(layers=[L(id='pro_shimmer/m0', dur=1.3)], lufs=-24),
    'coin':         dict(layers=[L(id='pro_notify/ding_2045'), L(id='pro_notify/ding_2296', at=0.075, gain=-2)], lufs=-24),
    'energy':       dict(layers=[L(id='mallet/flourish', pitch='C6'), L(id='pro_shimmer/m3', at=0.2, gain=-8)], lufs=-22),
    'level-up':     dict(layers=[L(id='mallet/up4'), L(id='mallet/flourish', at=0.44, pitch='C6', gain=-1),
                                 L(id='pro_shimmer/m0', at=0.35, gain=-8, dur=1.4)], lufs=-20),
    # adventures, friends, things
    'depart':       dict(layers=[L(id='whoosh_fast/tight', gain=-3), L(id='mallet/flourish', at=0.1, gain=-7, pitch='G5')], lufs=-24),
    'return':       dict(layers=[L(id='pluck/kalimba', pitch='G5', dur=1.0), L(id='pluck/kalimba', at=0.15, pitch='C6', dur=1.2)], lufs=-22),
    'boop':         dict(layers=[L(id='fit/pop/mouth_plop', pitch='C6')], lufs=-27, mono=True),
    'hatch':        dict(layers=[L(id='knock/snap', gain=-4), L(id='fit/pop/mouth_plop', at=0.09),
                                 L(id='mallet/flourish', at=0.15, gain=-2, pitch='C6')], lufs=-21),
    'knock':        dict(layers=[L(id='knock/wood', pitch='E4'), L(id='knock/wood', at=0.15, pitch='E4', seed=5, gain=-2),
                                 L(id='notify/mid_wood', at=0.3, gain=-5, pitch='C6', dur=0.6)], lufs=-24),
    'equip':        dict(layers=[L(id='swipe/cloth', dur=0.45, apex=0.14), L(id='pro_pop_in/round', at=0.2, gain=-6)], lufs=-27),
    'page':         dict(layers=[L(id='swipe/cloth', dur=0.45, apex=0.14), L(id='pluck/kalimba_soft', at=0.18, gain=-3, pitch='E5', dur=0.7)], lufs=-28),
    # calm tools
    'focus-start':  dict(layers=[L(id='mallet/marimba', pitch='C4'), L(id='mallet/marimba', at=0.14, pitch='G4')], lufs=-25),
    'focus-pause':  dict(layers=[L(id='mallet/marimba', pitch='G4'), L(id='mallet/marimba', at=0.14, pitch='C4', gain=-2)], lufs=-27),
    'chime':        dict(layers=[L(id='pluck/kalimba_ring', pitch='C5', dur=1.6), L(id='pluck/kalimba_ring', at=0.09, pitch='E5', dur=1.6),
                                 L(id='pluck/kalimba_ring', at=0.18, pitch='G5', dur=1.6), L(id='pluck/kalimba_ring', at=0.27, pitch='C6', dur=1.6)], lufs=-22),
    # local notifications (GoobyAlerts.sound looks for sfx-notify)
    'notify':       dict(layers=[L(id='pluck/kalimba', pitch='G5', dur=1.2), L(id='pluck/kalimba', at=0.16, pitch='C6', dur=1.4),
                                 L(id='mallet/celesta', at=0.16, gain=-12, pitch='C7')], lufs=-16),
}
# Mood check-in: one kalimba note per level (1 = very bad ... 5 = very good), lower and softer for
# heavy days, brighter for good ones; never a "wrong" sound.
for level, (notes, lufs) in enumerate([(('A4',), -29), (('C5',), -28), (('D5', 'G5'), -27), (('E5', 'A5'), -26), (('G5', 'C6'), -25)], 1):
    SFX[f'mood-{level}'] = dict(lufs=lufs, layers=[L(id='pluck/kalimba_soft', at=0.11 * i, pitch=n, dur=0.9, gain=-2 * i)
                                                   for i, n in enumerate(notes)])


def render_sfx(name, spec):
    parts = []
    for layer in spec['layers']:
        y, _ = bank.render(layer['id'], seed=layer.get('seed'), dur=layer.get('dur'), apex=layer.get('apex'),
                           pitch=layer.get('pitch'), checks=False)
        y = stereo(y) * db(layer.get('gain', 0))
        start = int(round(layer.get('at', 0) * SR))
        parts.append((start, y))
    n = max(s + len(y) for s, y in parts)
    mix = np.zeros((n, 2))
    for s, y in parts:
        mix[s:s + len(y)] += y
    mix = fade(trim_tail(mix), fade_in=0.0005, fade_out=0.04)
    mix *= db(spec['lufs'] - lufs_max(mix))
    peak = np.abs(mix).max()
    if peak > db(-1):
        mix *= db(-1) / peak
    path = os.path.join(SFX_DIR, f'sfx-{name}.wav')
    write_wav(path, mix, mono=spec.get('mono', False))
    print(f'sfx-{name}.wav  {len(mix) / SR:.2f} s  {lufs_max(mix):.1f} LUFS(m max)  peak {20 * np.log10(np.abs(mix).max()):.1f} dBFS')


# ------------------------------------------------------------------------------------------------ soundscapes
LOOP = 48.0                 # seconds per loop: a whole number of IMA4 packets (64 frames) at 44.1 kHz
N = int(LOOP * SR)


def rng(seed):
    return np.random.default_rng(seed)


def spectral_noise(r, lo, hi, slope=-3.0, order=4, n=N):
    """periodic noise (exactly n samples, loops seamlessly): Gaussian spectrum shaped by a slope in dB per octave
    (0 white, -3 pink, -6 brown) and a smooth band from lo to hi Hz"""
    f = np.fft.rfftfreq(n, 1 / SR)
    spec = (r.standard_normal(len(f)) + 1j * r.standard_normal(len(f)))
    ff = np.maximum(f, 1.0)
    mag = ff ** (slope / 6.02)
    if lo:
        mag *= 1 / np.sqrt(1 + (lo / ff) ** (2 * order))
    if hi:
        mag *= 1 / np.sqrt(1 + (ff / hi) ** (2 * order))
    mag[0] = 0
    y = np.fft.irfft(spec * mag, n)
    return y / (np.std(y) + 1e-12)


def stereo_noise(r, lo, hi, slope=-3.0, corr=0.3, order=4):
    a, b, c = (spectral_noise(r, lo, hi, slope, order) for _ in range(3))
    k = np.sqrt(corr)
    return np.stack([k * c + np.sqrt(1 - corr) * a, k * c + np.sqrt(1 - corr) * b], axis=1)


def smooth_lfo(r, max_hz, n=N):
    """periodic smooth random curve in about [-1, 1]: only spectral bins up to max_hz"""
    k = max(1, int(max_hz * n / SR))
    spec = np.zeros(n // 2 + 1, complex)
    spec[1:k + 1] = (r.standard_normal(k) + 1j * r.standard_normal(k)) / np.sqrt(np.arange(1, k + 1))
    y = np.fft.irfft(spec, n)
    return y / (np.abs(y).max() + 1e-12)


def add_event(out, ev, start, pan=0.0):
    """adds a mono or stereo event at `start` (samples), wrapping around the loop end"""
    ev = np.asarray(ev, np.float64)
    if ev.ndim == 1:
        th = (pan + 1) * np.pi / 4
        ev = np.stack([ev * np.cos(th), ev * np.sin(th)], axis=1) * np.sqrt(2)
    n = len(out)
    idx = (start + np.arange(len(ev))) % n
    np.add.at(out, idx, ev)


def circular_reverb(y, r, seconds=1.2, predelay=0.012, lo=200, hi=7000, wet=0.25):
    """a soft room (exponentially decaying noise IR) applied by circular FFT convolution, so the tail of the loop
    end rings into its start: the loop stays seamless"""
    n_ir = int(seconds * SR)
    t = np.arange(n_ir) / SR
    out = np.zeros_like(y)
    sos = signal.butter(2, [lo, hi], btype='band', fs=SR, output='sos')
    for ch in range(2):
        ir = r.standard_normal(n_ir) * np.exp(-6.9 * t / seconds)
        ir = signal.sosfilt(sos, ir)
        ir = np.concatenate([np.zeros(int(predelay * SR)), ir])
        ir /= np.sqrt(np.sum(ir ** 2)) + 1e-12
        h = np.fft.rfft(ir, len(y))
        out[:, ch] = np.fft.irfft(np.fft.rfft(y[:, ch]) * h, len(y))
    return (1 - wet) * y + wet * out


def band(y, lo, hi, order=2):
    if lo and hi:
        sos = signal.butter(order, [lo, hi], btype='band', fs=SR, output='sos')
    elif lo:
        sos = signal.butter(order, lo, btype='high', fs=SR, output='sos')
    else:
        sos = signal.butter(order, hi, btype='low', fs=SR, output='sos')
    return signal.sosfilt(sos, y, axis=0)


def poisson_times(r, rate, n=N):
    count = r.poisson(rate * n / SR)
    return np.sort(r.integers(0, n, count))


def decay_env(r_len, tau):
    t = np.arange(r_len) / SR
    return np.exp(-t / tau)


# Rain: thousands of drops a second on leaves and a roof (short ticks, some ringing pings, soft thuds on
# wood), a thin hiss of far rain, a few heavier drips from a gutter.
def scape_rain():
    r = rng(11)
    y = 0.08 * stereo_noise(r, 700, 9000, slope=-2.5, corr=0.15)
    y += 0.06 * stereo_noise(r, 60, 400, slope=-4.5, corr=0.6)
    swell = 1 + 0.15 * smooth_lfo(r, 0.08)
    y *= swell[:, None]
    for t in poisson_times(r, 900):                         # near drops on leaves: short noise ticks
        n = int(r.uniform(0.002, 0.008) * SR)
        ev = r.standard_normal(n) * decay_env(n, r.uniform(0.0006, 0.0025))
        ev = band(ev, r.uniform(900, 2500), r.uniform(5000, 10000))
        add_event(y, ev * r.lognormal(-3.2, 0.8), t, pan=r.uniform(-0.95, 0.95))
    for t in poisson_times(r, 70):                          # drops on hard surfaces: tiny damped pings
        n = int(0.03 * SR)
        f0 = r.uniform(1400, 3800)
        tt = np.arange(n) / SR
        ev = np.sin(2 * np.pi * f0 * tt * (1 - 0.6 * tt)) * np.exp(-tt / r.uniform(0.002, 0.006))
        add_event(y, ev * r.lognormal(-3.4, 0.6), t, pan=r.uniform(-0.8, 0.8))
    for t in poisson_times(r, 40):                          # drops on a wooden roof: soft low thuds
        n = int(0.025 * SR)
        tt = np.arange(n) / SR
        ev = band(r.standard_normal(n) * np.exp(-tt / 0.004), 180, 1200)
        add_event(y, ev * r.lognormal(-3.0, 0.5), t, pan=r.uniform(-0.6, 0.6))
    for t in poisson_times(r, 0.6):                         # gutter drips: a water drop rising in pitch
        drip, _ = bank.render('drip/plink', seed=int(r.integers(1, 99)), pitch=float(r.uniform(700, 1100)), checks=False)
        add_event(y, stereo(drip) * 0.05, t)
    return circular_reverb(y, r, seconds=0.9, wet=0.3)


# Ocean: waves 6.5-9.5 s apart. A wave is a swell of splashes: hundreds of short noise grains a second
# whose number, level and brightness follow the wave (dense and bright at the crash, thinning out as the
# wash runs back), over a broadband roar and a distant surf rumble that never stops.
def wave_envelope(r):
    w, t = np.zeros(N), 0.0
    while t < LOOP - 2:
        rise, wash = r.uniform(2.0, 3.0), r.uniform(4.0, 6.0)
        n = int((rise + wash * 2) * SR)
        tt = np.arange(n) / SR
        e = np.clip(tt / rise, 0, 1) ** 2 * np.exp(-np.clip(tt - rise, 0, None) / (0.4 * wash)) * r.uniform(0.7, 1.0)
        idx = (int(t * SR) + np.arange(n)) % N
        w[idx] = np.maximum(w[idx], e)
        t += r.uniform(6.5, 9.5)
    return w


def scape_ocean():
    r = rng(23)
    w = wave_envelope(r)
    y = 0.2 * stereo_noise(r, 40, 2000, slope=-4.0, corr=0.4) * (0.6 + 0.4 * w)[:, None]
    y += 0.35 * stereo_noise(r, 150, 6000, slope=-2.5, corr=0.2) * (w ** 1.5)[:, None]
    for t in poisson_times(r, 300):
        level = w[t]
        if r.uniform() > level ** 1.2:
            continue
        n = int(r.uniform(0.03, 0.16) * SR)
        c = r.uniform(300, 1500) * (1 + 3 * level)
        grain = band(r.standard_normal(n) * np.hanning(n), c / 1.8, min(c * 1.8, 20000))
        add_event(y, grain * 0.05 * level, t, pan=r.uniform(-0.8, 0.8))
    return circular_reverb(y, r, seconds=1.4, wet=0.2)


# Wind: a low rush whose loudness follows gusts (slow swells, quicker gusts and a restless flutter), a
# hollow howl whose pitch rises as a gust builds and a thin airy hiss on the strongest gusts.
def scape_wind():
    r = rng(37)
    gust = np.clip(0.55 + 0.15 * smooth_lfo(r, 0.05) + 0.3 * smooth_lfo(r, 0.25) + 0.2 * smooth_lfo(r, 2.0), 0.05, 1.0)
    y = (1.0 * gust ** 1.4)[:, None] * stereo_noise(r, 25, 450, slope=-6.0, corr=0.6)
    centers = np.geomspace(230, 950, 12)
    pos = gust * (len(centers) - 1)
    for ch in range(2):
        howl = np.zeros(N)
        for i, f in enumerate(centers):
            weight = np.exp(-0.5 * ((pos - i) / 1.1) ** 2)
            howl += spectral_noise(rng(300 + 20 * ch + i), f * 0.97, f * 1.03, slope=0, order=6) * weight
        y[:, ch] += 0.2 * gust ** 1.8 * howl
    y += (0.03 * gust ** 3)[:, None] * stereo_noise(r, 1500, 6500, slope=-2.0, corr=0.2)
    return circular_reverb(y, r, seconds=1.2, wet=0.15)


# Fire: a low roar that flickers, crackles (many small, some sharp) in clusters, sizzling bursts and a
# woody pop every few seconds, in a small room.
def scape_fire():
    r = rng(41)
    flicker = 1 + 0.35 * smooth_lfo(r, 0.6)
    y = 0.2 * stereo_noise(r, 30, 300, slope=-5.0, corr=0.7) * flicker[:, None]
    y += 0.01 * stereo_noise(r, 2500, 8000, slope=-1.0, corr=0.2) * (1 + 0.5 * smooth_lfo(r, 1.5))[:, None]
    cluster = np.clip(0.6 + 0.6 * smooth_lfo(r, 0.4), 0.1, 1.2)
    times = poisson_times(r, 34)
    keep = r.uniform(0, 1, len(times)) < cluster[times] / 1.2
    for t in times[keep]:                                    # crackles
        n = int(r.uniform(0.002, 0.012) * SR)
        ev = r.standard_normal(n) * decay_env(n, r.uniform(0.0005, 0.003))
        ev = band(ev, r.uniform(600, 1800), r.uniform(4000, 9000))
        a = min(0.9, 0.04 * r.pareto(2.0) + 0.015)
        add_event(y, ev * a, t, pan=r.uniform(-0.7, 0.7))
    for t in poisson_times(r, 3):                            # sizzle bursts of micro crackles
        for k in range(int(r.integers(5, 18))):
            n = int(0.0015 * SR)
            ev = band(r.standard_normal(n) * decay_env(n, 0.0004), 3000, 10000)
            add_event(y, ev * r.uniform(0.004, 0.012), t + int(r.uniform(0, 0.25) * SR), pan=r.uniform(-0.5, 0.5))
    for t in poisson_times(r, 0.35):                         # woody pops
        n = int(0.06 * SR)
        tt = np.arange(n) / SR
        f0 = r.uniform(250, 600)
        body = np.sin(2 * np.pi * f0 * tt) * np.exp(-tt / 0.012)
        crack = band(r.standard_normal(n) * np.exp(-tt / 0.004), 800, 7000)
        add_event(y, (0.10 * body + 0.22 * crack) * r.uniform(0.6, 1.0), t, pan=r.uniform(-0.5, 0.5))
    return circular_reverb(y, r, seconds=0.5, predelay=0.006, lo=150, hi=6000, wet=0.22)


def bird_element(r, kind):
    """one element of a song (mono): a short frequency-modulated tone, never a held note"""
    if kind == 'sweep':                                        # a quick glide up or down
        d = r.uniform(0.03, 0.09)
        a, b = r.uniform(2500, 6500, 2)
        f = np.geomspace(a, b, int(d * SR))
    elif kind == 'chip':                                       # a sharp falling chip
        d = r.uniform(0.015, 0.03)
        f = np.geomspace(r.uniform(5500, 7500), r.uniform(2800, 3800), int(d * SR))
    elif kind == 'trill':                                      # a fast run of tiny sweeps
        d = r.uniform(0.3, 0.7)
        tt = np.arange(int(d * SR)) / SR
        rate, fc = r.uniform(12, 22), r.uniform(3500, 5500)
        f = fc * (1 + 0.18 * signal.sawtooth(2 * np.pi * rate * tt, 0.1))
    else:                                                      # 'warble': a wandering, fluttering phrase
        d = r.uniform(0.15, 0.4)
        n = int(d * SR)
        contour = np.interp(np.arange(n), np.linspace(0, n, 6), r.uniform(2800, 5200, 6))
        f = contour * (1 + 0.05 * np.sin(2 * np.pi * r.uniform(25, 60) * np.arange(n) / SR))
    n = len(f)
    tt = np.arange(n) / SR
    env = np.sin(np.pi * np.arange(n) / n) ** 1.5
    if kind == 'trill':
        env *= 0.55 + 0.45 * np.sin(2 * np.pi * rate * tt) ** 2
    ph = 2 * np.pi * np.cumsum(f) / SR
    return env * (np.sin(ph) + 0.08 * np.sin(2 * ph))


def bird_song(r, repertoire):
    """a song of 3-9 elements from one bird's repertoire, with short gaps"""
    parts = []
    for _ in range(int(r.integers(3, 10))):
        kind, seed = repertoire[int(r.integers(len(repertoire)))]
        parts.append(bird_element(rng(seed), kind) * r.uniform(0.6, 1.0))
        parts.append(np.zeros(int(r.uniform(0.02, 0.12) * SR)))
    return np.concatenate(parts)


def add_birds(y, r, rate, level):
    """birds that sing in bouts: each has a place (pan, distance) and a small repertoire of elements it reuses"""
    kinds = ('sweep', 'chip', 'trill', 'warble')
    for t in poisson_times(r, rate):
        repertoire = [(kinds[int(r.integers(4))], int(r.integers(1, 10 ** 6))) for _ in range(int(r.integers(2, 4)))]
        pan, dist = r.uniform(-0.85, 0.85), r.uniform(0.25, 1.0)
        start = t
        for _ in range(int(r.integers(1, 4))):
            song = bird_song(r, repertoire)
            if dist < 0.6:
                song = band(song, None, 5000, order=1)          # distant birds lose their top
            add_event(y, song * level * dist, start, pan=pan)
            start += len(song) + int(r.uniform(1.0, 4.0) * SR)


# Forest: a soft breeze moving through the trees and birds near and far in a wide, open space.
def scape_forest():
    r = rng(53)
    breeze = np.clip(0.55 + 0.45 * smooth_lfo(r, 0.08), 0.15, 1)
    y = (0.03 * breeze)[:, None] * stereo_noise(r, 200, 2000, slope=-3.5, corr=0.2)
    y += (0.03 * breeze)[:, None] * stereo_noise(r, 60, 500, slope=-5.0, corr=0.5)
    add_birds(y, r, rate=0.6, level=0.09)
    return circular_reverb(y, r, seconds=1.8, predelay=0.02, lo=300, hi=8000, wet=0.32)


def bubble(r):
    """one bubble of a brook (rising sine, after van den Doel's liquid model)"""
    radius = r.uniform(0.0015, 0.008)
    f0 = 3.0 / radius                                          # Minnaert: about 3 / r Hz
    d = min(0.06, 0.02 + 0.13 * radius * 50)
    n = int(d * SR)
    tt = np.arange(n) / SR
    tau = 1 / (0.043 * f0 + 0.0014 * f0 ** 1.5)
    f = f0 * (1 + r.uniform(0.1, 0.25) * tt / tau)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt / tau)


# Nature: a small brook babbling over stones (bubbles and a soft water rush), a light breeze and a
# few birds in the distance.
def scape_nature():
    r = rng(67)
    churn = 1 + 0.3 * smooth_lfo(r, 0.4)
    y = 0.05 * stereo_noise(r, 300, 3500, slope=-2.5, corr=0.3) * churn[:, None]
    y += 0.015 * stereo_noise(r, 3000, 9000, slope=-1.0, corr=0.2)
    density = np.clip(0.7 + 0.5 * smooth_lfo(r, 0.3), 0.2, 1.3)
    times = poisson_times(r, 160)
    keep = r.uniform(0, 1.3, len(times)) < density[times]
    for t in times[keep]:
        add_event(y, bubble(r) * r.lognormal(-3.4, 0.5), t, pan=r.uniform(-0.6, 0.6))
    breeze = np.clip(0.5 + 0.5 * smooth_lfo(r, 0.06), 0.1, 1)
    y += (0.025 * breeze)[:, None] * stereo_noise(r, 1500, 7000, slope=-1.5, corr=0.1)
    add_birds(y, r, rate=0.2, level=0.04)
    return circular_reverb(y, r, seconds=1.2, wet=0.25)


SCAPES = {'rain': scape_rain, 'ocean': scape_ocean, 'forest': scape_forest,
          'wind': scape_wind, 'fire': scape_fire, 'nature': scape_nature}
SCAPE_LUFS = -23.0          # integrated loudness of every loop (SoundscapePlayer plays them at one volume)


def integrated_lufs(y):
    import pyloudnorm
    return pyloudnorm.Meter(SR).integrated_loudness(y)


# IMA4 (QuickTime IMA ADPCM): packets of 64 frames per channel, each a 2-byte header (predictor's top 9 bits,
# step index) and 32 bytes of 4-bit codes. ffmpeg's encoder starts the first packet cold (predictor 0, smallest
# step), so the decoded loop would ramp up from silence at every restart: a click at the seam. The first packet
# of each channel is encoded again here, starting from the state the decoder has at the end of the loop.
IMA_INDEX = [-1, -1, -1, -1, 2, 4, 6, 8] * 2
IMA_STEP = [7, 8, 9, 10, 11, 12, 13, 14, 16, 17, 19, 21, 23, 25, 28, 31, 34, 37, 41, 45, 50, 55, 60, 66, 73, 80, 88,
            97, 107, 118, 130, 143, 157, 173, 190, 209, 230, 253, 279, 307, 337, 371, 408, 449, 494, 544, 598, 658,
            724, 796, 876, 963, 1060, 1166, 1282, 1411, 1552, 1707, 1878, 2066, 2272, 2499, 2749, 3024, 3327, 3660,
            4026, 4428, 4871, 5358, 5894, 6484, 7132, 7845, 8630, 9493, 10442, 11487, 12635, 13899, 15289, 16818,
            18500, 20350, 22385, 24623, 27086, 29794, 32767]


def ima_step(code, pred, idx):
    step = IMA_STEP[idx]
    diff = step >> 3
    if code & 4:
        diff += step
    if code & 2:
        diff += step >> 1
    if code & 1:
        diff += step >> 2
    pred = max(-32768, min(32767, pred - diff if code & 8 else pred + diff))
    return pred, max(0, min(88, idx + IMA_INDEX[code & 7]))


def ima_decode_packet(block):
    header = int.from_bytes(block[:2], 'big')
    pred, idx = (header & 0xFF80) - (0x10000 if header & 0x8000 else 0), header & 0x7F
    for byte in block[2:34]:
        for code in (byte & 0x0F, byte >> 4):
            pred, idx = ima_step(code, pred, idx)
    return pred, idx


def ima_encode_packet(samples, pred, idx):
    pred = max(-32768, min(32767, (pred + 64) & ~0x7F))     # the header keeps the top 9 bits
    out = bytearray(((pred & 0xFF80) | idx).to_bytes(2, 'big'))
    codes = []
    for s in samples:
        delta, code, step = int(s) - pred, 0, IMA_STEP[idx]
        if delta < 0:
            code, delta = 8, -delta
        for bit in (4, 2, 1):
            if delta >= step:
                code |= bit
                delta -= step
            step >>= 1
        codes.append(code)
        pred, idx = ima_step(code, pred, idx)
    out += bytes(codes[i] | (codes[i + 1] << 4) for i in range(0, 64, 2))
    return bytes(out)


def warm_start_ima4(path, pcm):
    import struct
    b = bytearray(open(path, 'rb').read())
    o, data = 8, None
    while o < len(b):
        kind, size = bytes(b[o:o + 4]), struct.unpack('>q', b[o + 4:o + 12])[0]
        if kind == b'data':
            data = o + 12 + 4                                # after the edit count
            break
        o += 12 + size
    ch = pcm.shape[1]
    packet = 34 * ch
    last = data + (len(pcm) // 64 - 1) * packet
    for c in range(ch):
        pred, idx = ima_decode_packet(b[last + 34 * c:last + 34 * (c + 1)])
        b[data + 34 * c:data + 34 * (c + 1)] = ima_encode_packet(pcm[:64, c], pred, idx)
    open(path, 'wb').write(bytes(b))


def render_scape(name, fn):
    y = fn()
    y -= y.mean(axis=0)
    y *= db(SCAPE_LUFS - integrated_lufs(y))
    peak = np.abs(y).max()
    if peak > db(-1.5):
        y = np.tanh(y / db(-1.5)) * db(-1.5)                 # soft-limit the rare loud crackle
    frames = int(LOOP * OUT_SR)
    assert frames % 64 == 0                                  # whole IMA4 packets: no padded tail at the seam
    y = signal.resample(y, frames, axis=0)                   # FFT resampling is circular: the loop stays seamless
    tmp = os.path.join(SCAPE_DIR, f'.sound-{name}.wav')
    out = os.path.join(SCAPE_DIR, f'sound-{name}.caf')
    sf.write(tmp, np.clip(y, -1, 1).astype(np.float32), OUT_SR, subtype='PCM_16')
    ffmpeg = shutil.which('ffmpeg')
    if not ffmpeg:
        sys.exit('ffmpeg is needed on PATH to write IMA4 CAF files')
    subprocess.run([ffmpeg, '-v', 'error', '-y', '-i', tmp, '-c:a', 'adpcm_ima_qt', '-f', 'caf', out], check=True)
    pcm, _ = sf.read(tmp, dtype='int16', always_2d=True)
    os.remove(tmp)
    warm_start_ima4(out, pcm)
    print(f'sound-{name}.caf  {frames / OUT_SR:.2f} s  {integrated_lufs(signal.resample(y, N, axis=0)):.1f} LUFS  '
          f'{os.path.getsize(out) / 1e6:.2f} MB')


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else 'all'
    only = sys.argv[2:]
    if what in ('sfx', 'all'):
        for name, spec in SFX.items():
            if not only or name in only:
                render_sfx(name, spec)
    if what in ('scapes', 'all'):
        for name, fn in SCAPES.items():
            if not only or name in only:
                render_scape(name, fn)


if __name__ == '__main__':
    main()
