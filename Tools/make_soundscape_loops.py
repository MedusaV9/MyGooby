#!/usr/bin/env python3
"""Soft placeholder loops for the soundscape sheet.

Every clip is synthesized here from noise and sines. No recordings, no sample
library, no network. AVAudioPlayer loops the file, so the end joins the start
on two neighbouring samples instead of fading to silence.
"""

import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
AUDIO = ROOT / "Gooby" / "Resources" / "Shell" / "Audio"
SR = 16000
SECONDS = 7
FADE = int(SR * 0.35)
PEAK = 0.28

NAMES = (
    "home",
    "water",
    "forest",
    "rain",
    "travel",
    "boat",
    "shop",
    "thunder",
    "wind",
    "land",
    "birds",
)


def lowpass(src, keep):
    out = np.empty_like(src)
    acc = 0.0
    for index, sample in enumerate(src):
        acc += keep * (sample - acc)
        out[index] = acc
    return out


def dc_block(src):
    out = np.empty_like(src)
    previous_in = 0.0
    previous_out = 0.0
    for index, sample in enumerate(src):
        previous_out = sample - previous_in + 0.995 * previous_out
        previous_in = sample
        out[index] = previous_out
    return out


def seamless(src, fade):
    blended = np.array(src, copy=True)
    ramp = np.linspace(0.0, 1.0, fade, endpoint=False)
    blended[:fade] = src[:fade] * ramp + src[-fade:] * (1.0 - ramp)
    looped = blended[:-fade]
    if abs(looped[0] - src[-fade]) > 1e-6:
        raise SystemExit("loop start does not meet the tail")
    if abs(looped[-1] - src[-fade - 1]) > 1e-6:
        raise SystemExit("loop end does not meet the sample before the tail")
    return looped


def burst(count, start, freq, length, amp):
    tone = np.zeros(count)
    end = min(count, start + length)
    steps = np.arange(end - start)
    envelope = np.sin(np.pi * steps / max(1, length)) ** 2
    tone[start:end] = np.sin(2 * np.pi * freq * steps / SR) * envelope * amp
    return tone


def bed(seed, count, keep):
    rng = np.random.default_rng(seed)
    return lowpass(rng.uniform(-1.0, 1.0, count), keep)


def render(name, count):
    t = np.arange(count) / SR
    if name == "home":
        hum = np.sin(2 * np.pi * 98 * t) * (0.62 + 0.38 * np.sin(2 * np.pi * 0.07 * t))
        return hum * 0.34 + bed(11, count, 0.035) * 0.22
    if name == "water":
        swell = 0.62 + 0.38 * np.sin(2 * np.pi * 0.17 * t)
        ripple = bed(12, count, 0.42) * (0.45 + 0.55 * np.sin(2 * np.pi * 1.1 * t))
        return bed(13, count, 0.16) * swell + ripple * 0.12
    if name == "forest":
        air = bed(14, count, 0.07)
        tone = air * 0.85
        rng = np.random.default_rng(15)
        for _ in range(6):
            start = int(rng.integers(FADE, count - FADE - int(SR * 0.2)))
            freq = float(rng.choice([523, 587, 659, 784, 880]))
            tone += burst(count, start, freq, int(SR * 0.14), 0.22)
        return tone
    if name == "rain":
        noise = np.random.default_rng(16).uniform(-1.0, 1.0, count)
        bright = noise - lowpass(noise, 0.08)
        level = 0.78 + 0.22 * np.sin(2 * np.pi * 0.09 * t)
        return lowpass(bright, 0.5) * level
    if name == "travel":
        hum = np.sin(2 * np.pi * 82 * t) * (0.8 + 0.2 * np.sin(2 * np.pi * 0.35 * t))
        return hum * 0.28 + bed(17, count, 0.05) * 0.35
    if name == "boat":
        swell = 0.4 + 0.6 * (0.5 + 0.5 * np.sin(2 * np.pi * 0.12 * t)) ** 2
        creak = np.sin(2 * np.pi * 130 * t) * np.maximum(0.0, np.sin(2 * np.pi * 0.12 * t))
        return bed(18, count, 0.11) * swell + creak * 0.04
    if name == "shop":
        hush = bed(19, count, 0.2)
        gate = lowpass(np.random.default_rng(20).random(count), 0.008)
        return hush * (0.28 + 0.72 * gate)
    if name == "thunder":
        rumble = bed(21, count, 0.018)
        near = np.exp(-((t - 2.4) / 0.85) ** 2) + 0.7 * np.exp(-((t - 5.0) / 1.05) ** 2)
        return rumble * (0.18 + near)
    if name == "wind":
        gust = 0.55 + 0.45 * np.sin(2 * np.pi * 0.08 * t)
        return bed(22, count, 0.1) * gust
    if name == "land":
        tone = bed(23, count, 0.06) * 0.35
        rng = np.random.default_rng(24)
        for _ in range(4):
            start = int(rng.integers(FADE, count - FADE - int(SR * 0.4)))
            freq = float(rng.choice([196, 220, 247, 294]))
            tone += burst(count, start, freq, int(SR * 0.32), 0.16)
        return tone
    if name == "birds":
        tone = bed(25, count, 0.04) * 0.18
        rng = np.random.default_rng(26)
        for _ in range(5):
            start = int(rng.integers(FADE, count - FADE - int(SR * 0.28)))
            freq = float(rng.choice([784, 880, 988, 1175]))
            tone += burst(count, start, freq, int(SR * 0.09), 0.2)
            tone += burst(count, start + int(SR * 0.1), freq * 1.25, int(SR * 0.07), 0.14)
        return tone
    raise SystemExit("unknown scene " + name)


def align_join(src, fade):
    diffs = np.abs(np.diff(src))
    start = fade
    end = len(src) - fade - 1
    cut = start + int(np.argmin(diffs[start:end])) + 1
    target = len(src) - fade
    return np.roll(src, -(cut - target))


def to_pcm(samples):
    centred = seamless(align_join(dc_block(samples), FADE), FADE)
    centred = centred - np.mean(centred)
    peak = float(np.max(np.abs(centred))) or 1.0
    scaled = centred * (PEAK / peak)
    pcm = np.clip(np.rint(scaled * 32767.0), -32767, 32767).astype("<i2")
    return pcm, scaled


def write_wav(path, pcm):
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "w") as handle:
        handle.setnchannels(1)
        handle.setsampwidth(2)
        handle.setframerate(SR)
        handle.writeframes(pcm.tobytes())


def write_all(folder=AUDIO):
    folder = Path(folder)
    for name in NAMES:
        count = SR * SECONDS
        pcm, scaled = to_pcm(render(name, count))
        jump = abs(float(scaled[0] - scaled[-1]))
        peak_db = 20.0 * np.log10(max(1.0, float(np.max(np.abs(pcm)))) / 32768.0)
        write_wav(folder / f"sound-{name}.wav", pcm)
        print(f"{name:8} {len(pcm) / SR:4.2f}s  peak {peak_db:5.1f} dBFS  seam {jump:.4f}")


if __name__ == "__main__":
    write_all()
