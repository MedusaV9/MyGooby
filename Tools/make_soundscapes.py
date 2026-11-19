#!/usr/bin/env python3
"""Render Gooby's soundscapes.

Fourteen scenes, one minute each, stereo, 44.1 kHz. Everything is synthesized here from shaped noise, grains, and
tones: no recordings, no sample library, no network, so the files carry no third-party audio. The eleven scenes of
the soundscape sheet and the three extra ones of the calm screen (ocean, fire, nature) come from the same code.

Every layer is built on a circle of exactly one minute. Noise is shaped in the frequency domain, grains and
reverb are circular convolutions, events wrap around the end, and tones run a whole number of cycles. The last
sample therefore leads into the first one and `AVAudioPlayer` can repeat a file with no seam and no fade.

Setup (Python 3.9+, macOS for `afconvert`):
    python3 -m venv /tmp/soundscapes
    /tmp/soundscapes/bin/pip install numpy==2.0.2
    /tmp/soundscapes/bin/python Tools/make_soundscapes.py            # all scenes
    /tmp/soundscapes/bin/python Tools/make_soundscapes.py rain fire  # only these
    /tmp/soundscapes/bin/python Tools/make_soundscapes.py --wav DIR  # also keep the 16-bit WAV masters in DIR

Writes Gooby/Resources/Shell/Audio/sound-<scene>.m4a (AAC) and prints level, peak, and the seam check per file.
"""

import subprocess
import sys
import tempfile
import wave
import zlib
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "Gooby" / "Resources" / "Shell" / "Audio"
SR = 44100
SECONDS = 60
N = SR * SECONDS
FREQ = np.fft.rfftfreq(N, 1.0 / SR)
SAFE = np.maximum(FREQ, 1e-3)
BITRATE = 112000
HEADROOM = -2.0  # dBFS, measured on the decoded AAC


# ---------------------------------------------------------------- building blocks

def rms(x):
    return float(np.sqrt(np.mean(np.square(x)))) or 1.0


def band(lo, hi, order=2):
    """Magnitude of a smooth band-pass. `lo` 0 leaves the bottom open, `hi` 0 the top."""
    shape = np.ones_like(FREQ)
    if lo:
        shape *= 1.0 / np.sqrt(1.0 + (lo / SAFE) ** (2 * order))
    if hi:
        shape *= 1.0 / np.sqrt(1.0 + (FREQ / hi) ** (2 * order))
    return shape


def tilt(power):
    """1 is pink, 2 is brown."""
    return np.maximum(FREQ, 20.0) ** (-power / 2.0)


def shaped(x, shape):
    return np.fft.irfft(np.fft.rfft(x) * shape, N)


def noise(rng, shape):
    out = shaped(rng.standard_normal(N), shape)
    return out / rms(out)


def noise2(rng, shape, width=1.0):
    """Stereo noise. `width` 0 is mono, 1 is two unrelated channels."""
    mid = noise(rng, shape)
    left = noise(rng, shape)
    right = noise(rng, shape)
    keep = np.sqrt(max(0.0, 1.0 - width * width))
    return np.stack([keep * mid + width * left, keep * mid + width * right])


def slow(rng, hz, lo=0.0, hi=1.0, sharp=1.0):
    """Random curve between lo and hi that changes about `hz` times a second and closes on itself."""
    curve = shaped(rng.standard_normal(N), np.exp(-0.5 * (FREQ / hz) ** 2))
    curve = 0.5 + 0.5 * np.tanh(sharp * curve / rms(curve))
    return lo + (hi - lo) * curve


def pan(mono, where):
    """where: 0 left, 1 right. Equal power."""
    return np.stack([mono * np.cos(where * np.pi / 2), mono * np.sin(where * np.pi / 2)])


def put(buf, at, grain):
    """Adds a mono or stereo grain at sample `at`, wrapping past the end."""
    index = (int(at) + np.arange(grain.shape[-1])) % N
    if buf.ndim == 2 and grain.ndim == 1:
        grain = np.stack([grain, grain])
    np.add.at(buf, (Ellipsis, index), grain)


def scatter(rng, per_second, kernel, density=None, spread=0.6, sigma=0.7):
    """Many copies of one grain at random times, loudness, and pan. `density` weights the times."""
    count = int(rng.poisson(per_second * SECONDS))
    if density is None:
        at = rng.integers(0, N, count)
    else:
        cdf = np.cumsum(np.maximum(density, 0.0))
        at = np.minimum(np.searchsorted(cdf, rng.random(count) * cdf[-1]), N - 1)
    amp = rng.lognormal(0.0, sigma, count)
    where = 0.5 + spread * (rng.random(count) - 0.5)
    spectrum = np.fft.rfft(kernel, N)
    out = []
    for gain in (np.cos(where * np.pi / 2), np.sin(where * np.pi / 2)):
        train = np.zeros(N)
        np.add.at(train, at, amp * gain)
        out.append(np.fft.irfft(np.fft.rfft(train) * spectrum, N))
    return np.stack(out)


def click(rng, seconds, lo, hi, decay):
    """Short noise burst with an exponential tail."""
    count = int(SR * seconds)
    t = np.arange(count) / SR
    raw = rng.standard_normal(count) * np.exp(-t / decay)
    spectrum = np.fft.rfft(raw)
    f = np.maximum(np.fft.rfftfreq(count, 1.0 / SR), 1e-3)
    spectrum *= 1.0 / np.sqrt(1.0 + (lo / f) ** 4) / np.sqrt(1.0 + (f / hi) ** 4)
    out = np.fft.irfft(spectrum, count)
    out *= np.minimum(1.0, np.arange(count) / 8.0)
    return out / (np.max(np.abs(out)) or 1.0)


def ping(freq, decay, seconds=None, glide=0.0):
    """Damped sine. `glide` bends the pitch by that fraction over the tail, the way a bubble rises."""
    count = int(SR * (seconds or decay * 6))
    t = np.arange(count) / SR
    phase = 2 * np.pi * freq * (t + 0.5 * glide * t * t / max(decay, 1e-4))
    return np.sin(phase) * np.exp(-t / decay) * np.minimum(1.0, np.arange(count) / 16.0)


def swell(rise, fall, power=2.0, tail=2.0):
    """One breath of level: up in `rise` seconds, down in `fall`."""
    up = np.linspace(0.0, 1.0, int(SR * rise), endpoint=False) ** power
    down = np.linspace(1.0, 0.0, int(SR * fall)) ** tail
    return np.concatenate([up, down])


def envelope(rng, starts, shapes, gains=None):
    """Sums one shape per start time into a level curve that wraps."""
    curve = np.zeros(N)
    for index, start in enumerate(starts):
        shape = shapes[index % len(shapes)]
        put(curve, start * SR, shape * (1.0 if gains is None else gains[index]))
    return curve


def spaced(rng, count, jitter=0.25):
    """`count` start times around the circle, evenly spread and then nudged."""
    step = SECONDS / count
    return (np.arange(count) + 0.5 + jitter * rng.uniform(-1, 1, count)) * step


def reverb(rng, x, seconds, mix, lo=150.0, hi=5000.0):
    """Wraps the sound in a room: circular convolution with a decaying noise tail."""
    count = int(SR * seconds * 3)
    t = np.arange(count) / SR
    wet = []
    for channel in x:
        tail = rng.standard_normal(count) * np.exp(-t / (seconds / 3.0))
        tail[: int(SR * 0.004)] = 0.0
        spectrum = np.fft.rfft(tail, N) * band(lo, hi, 1)
        out = np.fft.irfft(np.fft.rfft(channel) * spectrum, N)
        wet.append(out)
    wet = np.stack(wet)
    wet *= rms(x) / rms(wet)
    return (1.0 - mix) * x + mix * wet


def glide_tone(rng, noise_hz, base, span, drive):
    """Narrow whistle of noise whose pitch follows `drive` (0..1). Closes on itself."""
    freq = base + span * drive
    cycles = float(np.sum(freq)) / SR
    freq = freq + (np.round(cycles) - cycles) / SECONDS
    phase = 2 * np.pi * np.cumsum(freq) / SR
    return noise(rng, band(0, noise_hz, 2)) * np.cos(phase)


# ---------------------------------------------------------------- textures

def weave(rng, lo, hi, bands=6, rate=2.0, depth=0.6, slope=1.0, sharp=1.0):
    """Stereo noise between lo and hi whose bands each breathe on their own, the way leaves, water, and flames do.

    `rate` is how often a band changes per second, `depth` how far it dips, `slope` how dark it is (0 is pink).
    """
    edges = np.geomspace(lo, hi, bands + 1)
    white = [np.fft.rfft(rng.standard_normal(N)) for _ in range(2)]
    out = np.zeros((2, N))
    for low, high in zip(edges[:-1], edges[1:]):
        shape = band(low, high, 3)
        gain = (np.sqrt(low * high) / lo) ** (-slope / 2.0)
        for side in range(2):
            part = np.fft.irfft(white[side] * shape, N)
            out[side] += part / rms(part) * gain * slow(rng, rate * rng.uniform(0.6, 1.6), 1.0 - depth, 1.0, sharp)
    return out / rms(out)


def shaped_stereo(x, shape):
    return np.stack([shaped(channel, shape) for channel in x])


def rustle(rng, events, per_second=70.0, lo=1500.0, hi=7000.0, spread=0.5):
    """Short flurries of dry ticks: paper, straw, a paw in the grass."""
    when = envelope(rng, spaced(rng, events, jitter=0.45), [swell(0.15, 0.7), swell(0.3, 1.3), swell(0.1, 0.4)],
                    rng.uniform(0.4, 1.0, events))
    out = scatter(rng, per_second, click(rng, 0.012, lo, hi, 0.002), density=when + 1e-6, sigma=0.9, spread=spread)
    return out / rms(out)


# ---------------------------------------------------------------- birds

def note(rng, length, start, end, arc=0.0, flutter=0.0, flutter_hz=30.0):
    """One bird note. The pitch bends from start to end over an arc and never holds perfectly still."""
    count = max(64, int(SR * length))
    t = np.arange(count) / count
    freq = start * (end / start) ** t * 2.0 ** (arc * np.sin(np.pi * t))
    freq = freq * (1.0 + np.interp(t, np.linspace(0, 1, 8), rng.normal(0, 0.012, 8)))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    tone = np.sin(phase) + 0.22 * np.sin(2 * phase) + 0.07 * np.sin(3 * phase)
    shape = np.minimum(1.0, t / 0.12) ** 1.5 * (1.0 - t) ** rng.uniform(0.6, 1.4)
    grit = max(4, int(length * 400))
    shape = shape * (1.0 + 0.3 * np.interp(t, np.linspace(0, 1, grit), rng.normal(0, 1, grit)))
    if flutter:
        shape = shape * (1.0 - flutter * (0.5 + 0.5 * np.sin(2 * np.pi * flutter_hz * t * length)))
    return tone * shape / (np.max(np.abs(shape)) or 1.0)


def motif(rng, kind):
    """A song as (length, start Hz, end Hz, arc, flutter, pause after, loudness) per note."""
    notes = []
    if kind == "tit":  # two notes, see-saw
        high = rng.uniform(3600, 4400)
        low = high * rng.uniform(0.74, 0.82)
        for _ in range(int(rng.integers(3, 6))):
            notes += [(0.11, high, high * 0.97, 0.02, 0.0, 0.05, 1.0), (0.13, low, low * 0.96, -0.02, 0.0, 0.07, 0.9)]
    elif kind == "chiff":  # even, bright drops
        pitches = rng.uniform(3700, 5000, 3)
        for _ in range(int(rng.integers(5, 10))):
            top = float(rng.choice(pitches))
            notes.append((0.08, top, top * 0.78, 0.05, 0.0, rng.uniform(0.13, 0.19), rng.uniform(0.7, 1.0)))
    elif kind == "flute":  # low, mellow, unhurried, with a thin twitter to finish
        pitch = rng.uniform(1900, 2500)
        for _ in range(int(rng.integers(4, 7))):
            target = float(np.clip(pitch * rng.choice([0.8, 0.89, 1.0, 1.12, 1.26, 1.33]), 1600, 3300))
            notes.append((rng.uniform(0.16, 0.34), pitch, target, rng.uniform(-0.12, 0.15), 0.0,
                          rng.uniform(0.04, 0.1), rng.uniform(0.7, 1.0)))
            pitch = target
        for _ in range(int(rng.integers(2, 6))):
            top = rng.uniform(4200, 6400)
            notes.append((rng.uniform(0.04, 0.08), top, top * rng.uniform(0.8, 1.2), 0.1, 0.0, 0.03, 0.3))
    elif kind == "trill":  # quick run of sweeps
        start = rng.uniform(3200, 5200)
        step = rng.choice([-0.012, 0.012])
        for index in range(int(rng.integers(10, 22))):
            base = start * (1.0 + step * index)
            notes.append((0.045, base * 1.15, base * 0.9, 0.0, 0.0, 0.024, 0.6 + 0.4 * np.sin(np.pi * index / 22)))
    elif kind == "warble":  # wandering, no two notes alike
        for _ in range(int(rng.integers(7, 14))):
            top = rng.uniform(2500, 5600)
            notes.append((rng.uniform(0.04, 0.15), top, top * rng.uniform(0.72, 1.3), rng.uniform(-0.2, 0.25),
                          rng.choice([0.0, 0.0, 0.6]), rng.uniform(0.02, 0.09), rng.uniform(0.5, 1.0)))
    elif kind == "peep":  # one or two calls, nothing more
        top = rng.uniform(3000, 4600)
        for _ in range(int(rng.integers(1, 3))):
            notes.append((rng.uniform(0.09, 0.16), top, top * rng.uniform(0.86, 1.1), rng.uniform(0.05, 0.2), 0.0,
                          rng.uniform(0.18, 0.4), 1.0))
    else:
        raise SystemExit("unknown bird " + kind)
    return notes


def sing(rng, notes):
    """Performs a motif. No bird sings it twice the same."""
    parts = []
    tune = rng.normal(1.0, 0.008)
    for length, start, end, arc, flutter, pause, loud in notes:
        bend = tune * rng.normal(1.0, 0.006)
        parts.append(note(rng, length * rng.uniform(0.92, 1.08), start * bend, end * bend, arc, flutter) * loud)
        parts.append(np.zeros(int(SR * pause * rng.uniform(0.85, 1.2))))
    return np.concatenate(parts)


def flock(rng, plan, room=2.0, mix=0.6, top=6500.0):
    """plan: (kind, songs in the minute, level, perch 0..1). One bird per row, each on its own branch."""
    out = np.zeros((2, N))
    for kind, count, level, perch in plan:
        own = motif(rng, kind)
        for start in spaced(rng, count, jitter=0.45):
            song = sing(rng, motif(rng, kind) if kind in ("flute", "warble", "peep") else own)
            where = float(np.clip(perch + rng.uniform(-0.05, 0.05), 0, 1))
            put(out, start * SR, pan(song * level * rng.uniform(0.6, 1.0), where))
    out = reverb(rng, shaped_stereo(out, band(0, top, 1)), room, mix, lo=500, hi=top)
    return out / rms(out)


# ---------------------------------------------------------------- water, fire, air

def rain_layers(rng, weight=1.0, roof=1.0):
    wash = weave(rng, 600, 7000, bands=6, rate=0.8, depth=0.35, slope=1.6)
    fine = scatter(rng, 180 * weight, click(rng, 0.01, 2000, 6000, 0.0012), sigma=0.6, spread=1.0)
    taps = sum(
        scatter(rng, 12 * weight, click(rng, 0.04, lo, hi, decay), sigma=0.6, spread=0.9)
        for lo, hi, decay in ((400, 1200, 0.006), (600, 1800, 0.005), (900, 2600, 0.004), (1200, 3400, 0.003))
    )
    drips = sum(scatter(rng, 0.7, click(rng, 0.06, lo, lo * 2.2, 0.012), sigma=0.5, spread=0.9) for lo in (500, 800))
    out = wash * 0.5 + fine / rms(fine) * 0.33 + taps / rms(taps) * 0.5 * roof + drips / rms(drips) * 0.1
    return out * slow(rng, 0.07, 0.8, 1.0)


def bubbles(rng, per_second, density=None, lo=450.0, hi=3200.0, voices=9):
    out = np.zeros((2, N))
    for freq in np.geomspace(lo, hi, voices):
        freq *= rng.uniform(0.94, 1.06)
        out += scatter(rng, per_second / voices, ping(freq, 9.0 / freq + 0.004, glide=0.35), density=density, spread=0.9)
    return out / rms(out)


def breeze(rng, gust):
    """Open-air wind. `gust` (0..1) lifts both the level and the pitch of the air."""
    body = weave(rng, 180, 1400, bands=6, rate=1.2, depth=0.5, slope=1.6) * (0.25 + 0.75 * gust ** 1.3)
    upper = weave(rng, 900, 4200, bands=5, rate=2.5, depth=0.6, slope=1.2) * (0.05 + 0.95 * gust ** 2.2)
    whistle = np.stack([
        glide_tone(rng, 140.0, 300.0, 500.0, gust),
        glide_tone(rng, 140.0, 330.0, 540.0, np.roll(gust, int(SR * 0.4))),
    ]) * (0.1 + 0.9 * gust ** 2)
    return body * 1.0 + upper * 0.5 + whistle * 0.5


def peal(rng):
    """One thunderclap as two level curves, crack and rumble: a few claps close together, then a long roll."""
    count = int(SR * 11)
    t = np.arange(count) / SR
    crack = np.zeros(count)
    rumble = np.zeros(count)
    delays = np.sort(rng.uniform(0.0, 2.6, int(rng.integers(3, 7))))
    delays[0] = 0.0
    for delay, size in zip(delays, rng.uniform(0.45, 1.0, len(delays))):
        since = t - delay
        on = np.clip(since / 0.12, 0.0, 1.0)
        crack += size * on * np.exp(-np.maximum(since, 0) / rng.uniform(0.25, 0.5))
        rumble += size * on * np.exp(-np.maximum(since, 0) / rng.uniform(1.0, 2.2))
    rumble += 0.5 * np.clip(t / 0.5, 0, 1) * np.exp(-t / 3.2)
    fade = np.clip((11.0 - t) / 1.5, 0.0, 1.0)
    return crack * fade, rumble * fade


def pops(rng, per_second=6.0):
    """Wood fire: wide, very short snaps of every size, and now and then a log that settles."""
    busy = 0.4 + 0.6 * slow(rng, 0.3, 0.0, 1.0)
    out = np.zeros((2, N))
    for lo, hi, decay, share in ((900, 6500, 0.0009, 0.5), (1500, 7500, 0.0006, 0.3), (500, 4000, 0.002, 0.2)):
        snaps = scatter(rng, per_second * share, click(rng, decay * 10, lo, hi, decay), density=busy, sigma=0.85, spread=0.6)
        out += snaps / rms(snaps) * np.sqrt(share)
    settle = scatter(rng, 0.15, click(rng, 0.2, 150, 700, 0.03), sigma=0.5, spread=0.4)
    return out / rms(out) + settle / rms(settle) * 0.35


# ---------------------------------------------------------------- the scenes

def scene_rain(rng):
    return rain_layers(rng)


def scene_thunder(rng):
    rain = shaped_stereo(rain_layers(rng, weight=0.5, roof=0.6), band(0, 2500, 1)) * 0.2
    crack = np.zeros(N)
    rumble = np.zeros(N)
    for start, size in zip(spaced(rng, 4, jitter=0.3), rng.uniform(0.6, 1.0, 4)):
        high, low = peal(rng)
        put(crack, start * SR, high * size)
        put(rumble, start * SR, low * size)
    mid = noise2(rng, band(150, 800, 2) * tilt(1.5), width=0.9) * crack
    low = noise2(rng, band(50, 260, 2) * tilt(1.0), width=0.6) * rumble * slow(rng, 1.5, 0.5, 1.0)
    return rain + mid * 1.6 + low * 1.8


def scene_water(rng):
    starts = spaced(rng, 19, jitter=0.35)
    sizes = rng.uniform(0.5, 1.0, 19)
    body = envelope(rng, starts, [swell(0.9, 1.9, 1.6, 1.8), swell(0.7, 2.4, 1.6, 2.0)], sizes)
    edge = envelope(rng, starts + 0.55, [swell(0.35, 1.3, 1.3, 2.4)], sizes)
    lap = noise2(rng, band(300, 1600, 2)) * (0.07 + body)
    foam = noise2(rng, band(1500, 7500, 2)) * (0.015 + edge)
    trickle = bubbles(rng, 26, density=0.08 + edge) * 0.2
    return lap * 1.0 + foam * 0.34 + trickle


def scene_ocean(rng):
    starts = spaced(rng, 5, jitter=0.2)
    sizes = rng.uniform(0.65, 1.0, 5)
    build = envelope(rng, starts, [swell(3.0, 2.5, 2.0, 1.5)], sizes)
    crash = envelope(rng, starts + 2.6, [swell(0.9, 4.2, 1.4, 2.4), swell(1.1, 4.8, 1.4, 2.2)], sizes)
    hiss = envelope(rng, starts + 3.6, [swell(1.6, 5.5, 1.2, 2.6)], sizes)
    drift = slow(rng, 0.08, 0.35, 0.65)
    under = weave(rng, 200, 600, bands=3, rate=1.5, depth=0.4, slope=1.0) * (0.1 + build)
    body = weave(rng, 300, 3000, bands=6, rate=3.0, depth=0.5, slope=1.3) * (0.03 + crash)
    wash = weave(rng, 1800, 8000, bands=5, rate=6.0, depth=0.6, slope=1.0) * (0.01 + hiss)
    out = under * 0.12 + body * 1.0 + wash * 0.4
    return out * np.stack([np.cos(drift * np.pi / 2), np.sin(drift * np.pi / 2)]) * 1.414


def scene_boat(rng):
    starts = spaced(rng, 20, jitter=0.3)
    sizes = rng.uniform(0.4, 1.0, 20)
    left = envelope(rng, starts, [swell(0.5, 1.3, 1.4, 1.8), swell(0.4, 1.6, 1.4, 2.0)], sizes)
    right = envelope(rng, starts + 1.45, [swell(0.5, 1.2, 1.4, 1.8)], sizes * 0.8)
    lap = weave(rng, 240, 1500, bands=5, rate=3.0, depth=0.55, slope=1.5) * np.stack([0.1 + left, 0.1 + right])
    spray = weave(rng, 1800, 6000, bands=4, rate=5.0, depth=0.6, slope=1.2)
    spray *= 0.01 + envelope(rng, starts + 0.4, [swell(0.2, 0.8, 1.3, 2.4)], sizes)
    hull = np.zeros((2, N))
    thunk = click(rng, 0.14, 160, 520, 0.022)
    for start, size in zip(starts, sizes):
        if rng.random() < 0.45:
            put(hull, (start + 0.45 + rng.uniform(-0.1, 0.1)) * SR, pan(thunk * size, rng.uniform(0.3, 0.45)))
        if rng.random() < 0.25:
            put(hull, (start + 1.9 + rng.uniform(-0.1, 0.1)) * SR, pan(thunk * size * 0.6, rng.uniform(0.55, 0.7)))
    hull = reverb(rng, hull, 0.35, 0.35, lo=140, hi=1500)
    trickle = bubbles(rng, 20, density=0.05 + left + right, lo=500, hi=2600, voices=7)
    return lap * 1.0 + spray * 0.12 + hull / rms(hull) * 0.18 + trickle * 0.14


def scene_wind(rng):
    gust = slow(rng, 0.12, 0.05, 1.0, sharp=1.3)
    flutter = slow(rng, 7.0, 0.55, 1.0)
    low = noise2(rng, band(140, 500, 2)) * (0.3 + 0.7 * gust)
    mid = noise2(rng, band(400, 1800, 2)) * gust ** 1.5
    high = noise2(rng, band(1500, 6000, 2)) * gust ** 2.5
    return (low * 0.9 + mid * 0.8 + high * 0.15) * flutter


def scene_forest(rng):
    gust = slow(rng, 0.12, 0.0, 1.0)
    leaves = weave(rng, 1800, 8000, bands=6, rate=8.0, depth=0.7, slope=0.8) * (0.3 + 0.7 * gust)
    air = weave(rng, 250, 1800, bands=5, rate=0.7, depth=0.4, slope=1.6)
    far = flock(rng, [("flute", 4, 1.0, 0.75), ("warble", 3, 0.6, 0.3), ("chiff", 2, 0.4, 0.55)], room=2.6, mix=0.75, top=4500)
    return air * 0.3 + leaves * 0.18 + far * 0.26


def scene_birds(rng):
    gust = slow(rng, 0.12, 0.0, 1.0)
    leaves = weave(rng, 1800, 8000, bands=6, rate=8.0, depth=0.7, slope=0.8) * (0.2 + gust ** 2)
    air = weave(rng, 220, 1800, bands=5, rate=0.7, depth=0.4, slope=1.6)
    song = flock(rng, [
        ("warble", 6, 0.7, 0.3), ("tit", 3, 0.5, 0.2), ("chiff", 4, 0.5, 0.82), ("flute", 6, 1.0, 0.45),
        ("trill", 3, 0.4, 0.68), ("peep", 3, 0.5, 0.6),
    ], room=2.2, mix=0.65, top=5000)
    return air * 0.38 + leaves * 0.28 + song * 0.3


def scene_land(rng):
    t = np.arange(N) / SR
    gust = slow(rng, 0.1, 0.0, 1.0)
    air = weave(rng, 300, 2500, bands=5, rate=0.6, depth=0.4, slope=1.8)
    grass = weave(rng, 2000, 7000, bands=5, rate=6.0, depth=0.7, slope=1.0) * (0.15 + gust ** 2)
    far = flock(rng, [("peep", 3, 1.0, 0.8), ("flute", 2, 0.8, 0.15)], room=2.6, mix=0.8, top=4200)
    paws = shaped_stereo(rustle(rng, 12, per_second=45, lo=900, hi=4500, spread=0.7), band(0, 3500, 1))
    breath = np.zeros((2, N))
    puff = noise2(rng, band(250, 1400, 2), width=0.4)
    for start in spaced(rng, 5, jitter=0.4):  # an animal breathing out, close by
        shape = swell(0.12, rng.uniform(0.5, 0.8), 1.3, 2.0) * rng.uniform(0.5, 1.0)
        index = (int(start * SR) + np.arange(len(shape))) % N
        breath[:, index] += puff[:, index] * shape * np.array([[0.8], [0.5]])
    chorus = np.zeros((2, N))
    for _ in range(10):  # tree crickets, far off: each holds one note and pulses it, in bouts
        pitch = np.round(rng.uniform(2700, 4300) * SECONDS) / SECONDS
        beat = np.round(rng.uniform(32, 58) * SECONDS) / SECONDS
        voice = np.sin(2 * np.pi * pitch * t + rng.uniform(0, 6.28)) * (0.5 - 0.5 * np.cos(2 * np.pi * beat * t)) ** 2
        chorus += pan(voice * slow(rng, 0.12, 0.0, 1.0, sharp=3.0) ** 2 * rng.lognormal(0, 0.6), rng.uniform(0.05, 0.95))
    chorus = reverb(rng, chorus, 1.4, 0.7, lo=1500, hi=5000)
    return (air * 0.3 + grass * 0.14 + far * 0.1 + paws * 0.07 + breath / rms(breath) * 0.1
            + chorus / rms(chorus) * 0.035)


def scene_home(rng):
    hearth = weave(rng, 110, 1100, bands=6, rate=9.0, depth=0.7, slope=1.8) * slow(rng, 0.3, 0.7, 1.0)
    hiss = weave(rng, 1800, 6000, bands=4, rate=2.0, depth=0.4, slope=1.3)
    embers = shaped_stereo(pops(rng, 2.0), band(250, 5000, 1))
    return hearth * 1.0 + hiss * 0.1 + embers * 0.07


def scene_fire(rng):
    roar = weave(rng, 90, 1500, bands=6, rate=9.0, depth=0.7, slope=1.4) * slow(rng, 0.3, 0.65, 1.0)
    hiss = weave(rng, 2000, 8000, bands=4, rate=2.0, depth=0.4, slope=1.0)
    return roar * 1.0 + hiss * 0.2 + pops(rng) * 0.18


def scene_travel(rng):
    t = np.arange(N) / SR
    cabin = weave(rng, 85, 2200, bands=7, rate=0.25, depth=0.25, slope=2.1)
    vents = weave(rng, 1500, 6000, bands=4, rate=0.5, depth=0.3, slope=1.2)
    drone = np.zeros((2, N))
    for side, detune in ((0, 0.0), (1, 1.0 / 6.0)):
        for multiple, level in ((1, 1.0), (2, 0.45), (3, 0.18)):
            pitch = np.round((112.0 + detune) * multiple * SECONDS) / SECONDS
            drone[side] += level * np.sin(2 * np.pi * pitch * t + rng.uniform(0, 2 * np.pi))
    drone *= slow(rng, 0.15, 0.6, 1.0)
    return (cabin * 1.0 + vents * 0.08 + drone * 0.03) * slow(rng, 0.05, 0.85, 1.0)


VOWELS = ((730, 1090, 2440), (530, 1840, 2480), (390, 1990, 2550), (570, 840, 2410), (440, 1020, 2240), (300, 870, 2240))


def talker(rng):
    """One distant voice: quick syllables with a pitch line, vowel colours and breathy consonants. No words."""
    out = np.zeros(N)
    pitch = rng.uniform(105, 225)
    tract = rng.uniform(0.9, 1.15)
    hushes = [click(rng, 0.07, 2200, 5500, 0.02), click(rng, 0.03, 1500, 4500, 0.006), click(rng, 0.09, 3000, 7000, 0.03)]
    at = rng.uniform(0, 6.0)
    while at < SECONDS:
        count = int(rng.integers(3, 12))
        for index in range(count):
            length = rng.uniform(0.07, 0.19)
            frames = int(SR * length)
            t = np.arange(frames) / SR
            line = pitch * (1.15 - 0.25 * index / count) * rng.uniform(0.88, 1.15)
            line = line * (1.0 + rng.uniform(-0.2, 0.15) * t / length)
            phase = 2 * np.pi * np.cumsum(line) / SR
            f1, f2, f3 = (f * tract for f in VOWELS[int(rng.integers(len(VOWELS)))])
            voice = np.zeros(frames)
            for k in range(1, int(3400 / pitch)):
                f = pitch * k
                gain = 1.0 / (1 + ((f - f1) / 130.0) ** 2) + 0.6 / (1 + ((f - f2) / 170.0) ** 2) + 0.25 / (1 + ((f - f3) / 220.0) ** 2)
                voice += gain / k ** 0.7 * np.sin(k * phase + rng.uniform(0, 6.28))
            loud = rng.uniform(0.4, 1.0)
            voice *= np.sin(np.pi * np.arange(frames) / frames) ** rng.uniform(0.5, 1.2) * loud / (np.max(np.abs(voice)) or 1.0)
            if rng.random() < 0.55:
                hush = hushes[int(rng.integers(3))]
                put(out, at * SR, hush * 0.22 * loud)
                at += len(hush) / SR * 0.6
            put(out, at * SR, voice)
            at += length + rng.choice([0.0, 0.0, 0.03, 0.08])
        at += rng.uniform(0.6, 4.0)
    return out


def scene_shop(rng):
    murmur = np.zeros((2, N))
    for _ in range(9):
        murmur += pan(talker(rng) * rng.uniform(0.4, 1.0), rng.uniform(0.15, 0.85))
    murmur = reverb(rng, shaped_stereo(murmur, band(160, 2600, 1)), 0.7, 0.45, lo=200, hi=3000)
    room = weave(rng, 200, 1800, bands=4, rate=0.4, depth=0.3, slope=1.6)
    steps = np.zeros((2, N))
    heel = click(rng, 0.08, 150, 600, 0.015)
    for start in spaced(rng, 4, jitter=0.4):
        side, walk = rng.uniform(0.2, 0.8), rng.uniform(-0.04, 0.04)
        for step in range(int(rng.integers(4, 9))):
            where = float(np.clip(side + walk * step, 0.05, 0.95))
            put(steps, (start + step * rng.uniform(0.52, 0.6)) * SR, pan(heel * rng.uniform(0.6, 1.0), where))
    steps = reverb(rng, steps, 0.6, 0.4, lo=120, hi=3000)
    return murmur / rms(murmur) * 0.8 + room * 0.4 + steps / rms(steps) * 0.12


def scene_nature(rng):
    brook = weave(rng, 500, 7000, bands=9, rate=11.0, depth=0.8, slope=0.9, sharp=1.5)
    gurgle = weave(rng, 200, 700, bands=3, rate=6.0, depth=0.8, slope=0.5, sharp=1.5)
    drops = bubbles(rng, 60, lo=700, hi=4200, voices=12)
    gust = slow(rng, 0.1, 0.0, 0.6)
    song = flock(rng, [("flute", 4, 1.0, 0.2), ("peep", 5, 0.7, 0.8), ("warble", 3, 0.6, 0.65)], room=2.0, mix=0.6, top=6000)
    return brook * 0.6 + gurgle * 0.25 + drops * 0.07 + breeze(rng, gust) * 0.22 + song * 0.1


# name: (render, loudness in dB RMS). Sparse scenes sit lower because their peaks stand far above their average.
SCENES = {
    "rain": (scene_rain, -25.0),
    "thunder": (scene_thunder, -25.0),
    "water": (scene_water, -26.0),
    "ocean": (scene_ocean, -24.0),
    "boat": (scene_boat, -26.0),
    "wind": (scene_wind, -25.0),
    "forest": (scene_forest, -27.0),
    "birds": (scene_birds, -30.0),
    "land": (scene_land, -29.0),
    "home": (scene_home, -27.0),
    "fire": (scene_fire, -26.0),
    "travel": (scene_travel, -24.0),
    "shop": (scene_shop, -27.0),
    "nature": (scene_nature, -27.0),
}


# ---------------------------------------------------------------- mastering and files

def master(x, level_db):
    x = shaped_stereo(x, band(28, 15500, 2))
    x = x - np.mean(x, axis=1, keepdims=True)
    x = x * (10 ** (level_db / 20.0) / rms(x))
    ceiling = 10 ** (-6.0 / 20.0)
    knee = 0.5 * ceiling
    over = np.abs(x) > knee
    x[over] = np.sign(x[over]) * (knee + (ceiling - knee) * np.tanh((np.abs(x[over]) - knee) / (ceiling - knee)))
    return x


def write_wav(path, x, rng):
    dither = (rng.random(x.shape) - rng.random(x.shape)) / 32768.0
    pcm = np.clip(np.rint((x + dither) * 32767.0), -32767, 32767).astype("<i2")
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(2)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(pcm.T.tobytes())


def read_wav(path):
    """Reads 16-bit stereo PCM. afconvert writes the extensible header, which `wave` refuses."""
    raw = Path(path).read_bytes()
    at = 12
    while raw[at:at + 4] != b"data":
        at += 8 + int.from_bytes(raw[at + 4:at + 8], "little")
    size = int.from_bytes(raw[at + 4:at + 8], "little")
    return np.frombuffer(raw[at + 8:at + 8 + size], dtype="<i2").reshape(-1, 2).T / 32768.0


def afconvert(*args):
    subprocess.run(["afconvert", *args], check=True, capture_output=True)


def seam(x):
    """Step across the loop point against the usual step between neighbours. About 1 means no click."""
    step = np.abs(np.diff(x, axis=1))
    usual = float(np.percentile(step, 99.0)) or 1e-9
    return float(np.max(np.abs(x[:, 0] - x[:, -1]))) / usual


def render(name, folder, keep=None):
    make, level = SCENES[name]
    rng = np.random.default_rng(zlib.crc32(name.encode()))
    x = master(make(rng), level)
    with tempfile.TemporaryDirectory() as scratch:
        source = Path(keep or scratch) / f"sound-{name}.wav"
        back = Path(scratch) / "back.wav"
        target = Path(folder) / f"sound-{name}.m4a"
        for _ in range(4):  # the encoder overshoots on sharp grains; back off until the decoded file has headroom
            write_wav(source, x, rng)
            afconvert("-f", "m4af", "-d", "aac", "-b", str(BITRATE), "-q", "127", "-s", "2", str(source), str(target))
            afconvert("-f", "WAVE", "-d", "LEI16", str(target), str(back))
            heard = read_wav(back)
            peak = 20 * np.log10(float(np.max(np.abs(heard))))
            if peak <= HEADROOM:
                break
            x = x * 10 ** ((HEADROOM - 0.5 - peak) / 20.0)
    if heard.shape[1] != N:
        raise SystemExit(f"{name}: decodes to {heard.shape[1]} frames, wanted {N}; the loop would gap")
    if peak > HEADROOM:
        raise SystemExit(f"{name}: decoded peak {peak:.1f} dBFS is above {HEADROOM}")
    print(f"{name:8} {heard.shape[1] / SR:5.1f}s  {20 * np.log10(rms(heard)):6.1f} dB RMS  peak {peak:5.1f} dBFS  "
          f"seam {seam(x):.2f} (master) {seam(heard):.2f} (aac)  {target.stat().st_size // 1024} kB")


def write_all(folder=AUDIO, names=None, keep=None):
    Path(folder).mkdir(parents=True, exist_ok=True)
    for name in names or SCENES:
        if name not in SCENES:
            raise SystemExit("unknown scene " + name)
        render(name, folder, keep)


if __name__ == "__main__":
    args = sys.argv[1:]
    keep = None
    if "--wav" in args:
        at = args.index("--wav")
        keep = args[at + 1]
        Path(keep).mkdir(parents=True, exist_ok=True)
        del args[at:at + 2]
    write_all(names=args or None, keep=keep)
