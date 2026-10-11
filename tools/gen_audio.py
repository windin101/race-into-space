#!/usr/bin/env python3
"""Synthesise the game's placeholder music and sound effects with numpy and pack them as
Ogg Vorbis via ffmpeg. Everything here is original and released under CC0.

    python3 -I tools/gen_audio.py --out game/assets/audio

Produces:
  music/title_theme.ogg      slow minor-key pad with a rising arpeggio (loop, 48 s)
  music/spaceport_day.ogg    quiet ambient drone with soft pulses (loop, 60 s)
  music/mission.ogg          tense ostinato for playback (loop, 40 s)
  sfx/click.ogg, confirm.ogg, back.ogg, flag.ogg, launch.ogg, success.ogg, failure.ogg,
  sfx/first.ogg, newscast.ogg, explosion.ogg
"""

import argparse
import math
import shutil
import subprocess
import tempfile
import wave
from pathlib import Path

import numpy as np

SR = 44100


def write_wav(path: Path, data: np.ndarray) -> None:
    data = np.clip(data, -1.0, 1.0)
    pcm = (data * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1 if pcm.ndim == 1 else pcm.shape[1])
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def to_ogg(wav: Path, ogg: Path, quality: int = 4) -> None:
    ogg.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-c:a", "libvorbis", "-q:a", str(quality), str(ogg)], check=True)


def env(n: int, attack: float, release: float) -> np.ndarray:
    a = int(SR * attack)
    r = int(SR * release)
    e = np.ones(n)
    if a > 0:
        e[:a] = np.linspace(0, 1, a)
    if r > 0:
        e[-r:] = np.linspace(1, 0, r)
    return e


def tone(freq: float, seconds: float, kind: str = "sine", attack: float = 0.01, release: float = 0.05, detune: float = 0.0) -> np.ndarray:
    n = int(SR * seconds)
    t = np.arange(n) / SR
    if kind == "sine":
        s = np.sin(2 * np.pi * freq * t)
    elif kind == "tri":
        s = 2 * np.abs(2 * ((t * freq) % 1) - 1) - 1
    elif kind == "saw":
        s = 2 * ((t * freq) % 1) - 1
    elif kind == "square":
        s = np.sign(np.sin(2 * np.pi * freq * t))
    else:
        s = np.sin(2 * np.pi * freq * t)
    if detune:
        s = 0.5 * (s + np.sin(2 * np.pi * freq * (1 + detune) * t))
    return s * env(n, attack, release)


def lowpass(x: np.ndarray, cutoff: float) -> np.ndarray:
    rc = 1.0 / (2 * np.pi * cutoff)
    dt = 1.0 / SR
    alpha = dt / (rc + dt)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc += alpha * (v - acc)
        y[i] = acc
    return y


def lowpass_fast(x: np.ndarray, cutoff: float) -> np.ndarray:
    # One-pole lowpass via lfilter-free recursion using cumulative trick is not exact;
    # use an FFT brick-wall instead for speed on long buffers.
    spec = np.fft.rfft(x)
    freqs = np.fft.rfftfreq(len(x), 1 / SR)
    spec[freqs > cutoff] *= np.exp(-(freqs[freqs > cutoff] - cutoff) / (cutoff * 0.5))
    return np.fft.irfft(spec, n=len(x))


def noise(seconds: float, seed: int = 1) -> np.ndarray:
    rng = np.random.default_rng(seed)
    return rng.uniform(-1, 1, int(SR * seconds))


def note(name: str, octave: int) -> float:
    names = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
    semis = names.index(name) + 12 * (octave - 4)
    return 440.0 * 2 ** ((semis - 9) / 12)


def mix(*parts: np.ndarray) -> np.ndarray:
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[: len(p)] += p
    return out


def place(buf: np.ndarray, snd: np.ndarray, at: float, gain: float = 1.0) -> None:
    i = int(at * SR)
    j = min(len(buf), i + len(snd))
    if i < len(buf):
        buf[i:j] += snd[: j - i] * gain


# ---------------------------------------------------------------- music

def title_theme(seconds: float = 48.0) -> np.ndarray:
    buf = np.zeros(int(SR * seconds))
    chords = [["D", "F", "A"], ["A#", "D", "F"], ["G", "A#", "D"], ["A", "C#", "E"]]
    bar = seconds / 8
    for b in range(8):
        chord = chords[b % 4]
        for i, nm in enumerate(chord):
            pad = tone(note(nm, 3), bar * 1.05, "tri", attack=bar * 0.4, release=bar * 0.4, detune=0.004) * 0.12
            place(buf, pad, b * bar)
            arp = tone(note(nm, 5), bar / 6, "sine", attack=0.02, release=bar / 8) * 0.08
            for k in range(2):
                place(buf, arp, b * bar + (i + 3 * k) * bar / 6)
        bass = tone(note(chord[0], 2), bar, "saw", attack=0.05, release=bar * 0.5) * 0.08
        place(buf, lowpass_fast(bass, 300), b * bar)
    return lowpass_fast(buf, 5000) * env(len(buf), 1.0, 2.0)


def spaceport_day(seconds: float = 60.0) -> np.ndarray:
    buf = np.zeros(int(SR * seconds))
    drone = mix(tone(note("D", 2), seconds, "tri", attack=3, release=3, detune=0.003), tone(note("A", 2), seconds, "sine", attack=4, release=3)) * 0.09
    buf += drone[: len(buf)]
    wind = lowpass_fast(noise(seconds, 5), 400) * 0.03
    buf += wind[: len(buf)]
    for k in range(12):
        ping = tone(note(["D", "F", "A", "C"][k % 4], 5), 1.4, "sine", attack=0.02, release=1.2) * 0.05
        place(buf, ping, 2 + k * 4.7)
    return buf * env(len(buf), 1.0, 2.0)


def mission(seconds: float = 40.0) -> np.ndarray:
    buf = np.zeros(int(SR * seconds))
    step = 0.25
    seq = ["D", "D", "F", "D", "G", "D", "A#", "A"]
    for i in range(int(seconds / step)):
        nm = seq[i % len(seq)]
        p = tone(note(nm, 3 if i % 16 < 8 else 4), step * 0.9, "square", attack=0.005, release=0.08) * 0.06
        place(buf, lowpass_fast(p, 2500), i * step)
    pad = tone(note("D", 2), seconds, "saw", attack=2, release=3, detune=0.005) * 0.05
    buf += lowpass_fast(pad, 500)[: len(buf)]
    pulse = tone(60, 0.12, "sine", attack=0.002, release=0.1) * 0.5
    for i in range(int(seconds)):
        place(buf, pulse, i * 1.0)
        place(buf, pulse, i * 1.0 + 0.5, 0.6)
    return buf * env(len(buf), 0.5, 2.0)


# ---------------------------------------------------------------- effects

def click() -> np.ndarray:
    return mix(tone(1800, 0.03, "sine", 0.002, 0.02), tone(900, 0.05, "tri", 0.002, 0.04) * 0.5) * 0.4


def confirm() -> np.ndarray:
    buf = np.zeros(int(SR * 0.35))
    place(buf, tone(note("D", 5), 0.12, "sine", 0.005, 0.08) * 0.5, 0.0)
    place(buf, tone(note("A", 5), 0.2, "sine", 0.005, 0.15) * 0.5, 0.1)
    return buf


def back() -> np.ndarray:
    buf = np.zeros(int(SR * 0.3))
    place(buf, tone(note("A", 4), 0.1, "sine", 0.005, 0.08) * 0.4, 0.0)
    place(buf, tone(note("D", 4), 0.18, "sine", 0.005, 0.15) * 0.4, 0.08)
    return buf


def flag() -> np.ndarray:
    # A snare roll and a short brass-like swell.
    buf = np.zeros(int(SR * 1.2))
    for i in range(12):
        place(buf, lowpass_fast(noise(0.06, 20 + i), 3000) * env(int(SR * 0.06), 0.002, 0.05) * 0.25, i * 0.05)
    swell = mix(tone(note("D", 4), 0.8, "saw", 0.3, 0.4, 0.006), tone(note("A", 4), 0.8, "saw", 0.3, 0.4, 0.006)) * 0.12
    place(buf, lowpass_fast(swell, 1800), 0.5)
    return buf


def launch() -> np.ndarray:
    seconds = 4.0
    n = int(SR * seconds)
    rumble = lowpass_fast(noise(seconds, 9), 180) * 0.9
    crackle = lowpass_fast(noise(seconds, 10), 1200) * 0.15
    e = np.concatenate([np.linspace(0, 1, int(SR * 1.2)), np.ones(n - int(SR * 1.2) - int(SR * 1.5)), np.linspace(1, 0, int(SR * 1.5))])
    return (rumble + crackle) * e


def explosion() -> np.ndarray:
    seconds = 1.6
    n = int(SR * seconds)
    boom = lowpass_fast(noise(seconds, 13), 300)
    e = np.exp(-np.linspace(0, 6, n))
    thump = tone(55, 0.5, "sine", 0.002, 0.45)
    out = boom * e * 0.9
    out[: len(thump)] += thump * 0.6
    return out


def success() -> np.ndarray:
    buf = np.zeros(int(SR * 1.2))
    for i, nm in enumerate(["D", "F#", "A", "D"]):
        place(buf, tone(note(nm, 5 if i < 3 else 6), 0.5, "sine", 0.01, 0.4) * 0.35, i * 0.14)
    return buf


def failure() -> np.ndarray:
    buf = np.zeros(int(SR * 1.3))
    place(buf, tone(note("D", 3), 0.6, "saw", 0.01, 0.5, 0.01) * 0.3, 0.0)
    place(buf, tone(note("C#", 3), 0.9, "saw", 0.01, 0.8, 0.01) * 0.3, 0.35)
    return lowpass_fast(buf, 1500)


def first() -> np.ndarray:
    buf = np.zeros(int(SR * 2.2))
    for i, nm in enumerate(["D", "A", "D", "F#", "A", "D"]):
        place(buf, tone(note(nm, 4 + i // 3), 0.7, "tri", 0.01, 0.5) * 0.3, i * 0.18)
    place(buf, tone(note("D", 6), 1.2, "sine", 0.02, 1.0) * 0.25, 1.0)
    return buf


def newscast() -> np.ndarray:
    buf = np.zeros(int(SR * 1.4))
    for i, nm in enumerate(["G", "C", "E", "G"]):
        place(buf, tone(note(nm, 5), 0.3, "square", 0.005, 0.2) * 0.15, i * 0.12)
    place(buf, lowpass_fast(tone(note("C", 4), 1.0, "saw", 0.02, 0.8, 0.005), 1500) * 0.15, 0.5)
    return buf


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True, type=Path)
    a = ap.parse_args()
    if shutil.which("ffmpeg") is None:
        raise SystemExit("ffmpeg is required")
    jobs = {
        "music/title_theme": title_theme,
        "music/spaceport_day": spaceport_day,
        "music/mission": mission,
        "sfx/click": click,
        "sfx/confirm": confirm,
        "sfx/back": back,
        "sfx/flag": flag,
        "sfx/launch": launch,
        "sfx/explosion": explosion,
        "sfx/success": success,
        "sfx/failure": failure,
        "sfx/first": first,
        "sfx/newscast": newscast,
    }
    with tempfile.TemporaryDirectory() as tmp:
        for name, fn in jobs.items():
            data = fn()
            wav = Path(tmp) / (name.replace("/", "_") + ".wav")
            write_wav(wav, data)
            ogg = a.out / (name + ".ogg")
            to_ogg(wav, ogg)
            print("wrote %s (%.1f s)" % (ogg, len(data) / SR))


if __name__ == "__main__":
    main()
