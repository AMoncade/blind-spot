"""BLIND SPOT's sounds, synthesised by code (our own work: no licence to track, plan section 7). Writes 16-bit mono
WAV files to assets/sounds/. Loops fade into themselves so they repeat without a click.

    py -I tools/audio/make_sounds.py

Then import the files in Studio (Asset Manager, Import) and put each id in content/sounds.csv (column asset).
Phone speakers can't play the lowest notes (plan section 8): the drone carries low-mid harmonics too.
"""

import os
import wave

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "sounds")
RATE = 44100
RNG = np.random.default_rng(1979)


def t(seconds):
    return np.arange(int(RATE * seconds)) / RATE


def lowpass(x, cutoff):
    """One-pole low-pass, run twice (12 dB per octave)."""
    a = np.exp(-2 * np.pi * cutoff / RATE)
    for _ in range(2):
        y = np.empty_like(x)
        acc = 0.0
        for i, v in enumerate(x):
            acc = (1 - a) * v + a * acc
            y[i] = acc
        x = y
    return x


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def loopable(x, fade=0.4):
    """Crossfades the end into the start so the file loops without a seam."""
    n = int(RATE * fade)
    head, body, tail = x[:n], x[n:-n], x[-n:]
    ramp = np.linspace(0, 1, n)
    return np.concatenate([tail * (1 - ramp) + head * ramp, body])


def envelope(n, attack, release):
    e = np.ones(n)
    a, r = int(RATE * attack), int(RATE * release)
    if a:
        e[:a] = np.linspace(0, 1, a)
    if r:
        e[-r:] = np.linspace(1, 0, r)
    return e


def write(name, x, peak=0.8):
    x = np.asarray(x, dtype=float)
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    data = (x * 32767).astype(np.int16)
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(data.tobytes())
    print(f"{name}.wav  {len(x) / RATE:.1f} s")


def hum():
    """Fluorescent tubes: a 120 Hz buzz with odd harmonics, a slow beat, a little crackle."""
    s = t(6.4)
    x = np.zeros_like(s)
    for k, amp in ((1, 1.0), (2, 0.5), (3, 0.35), (5, 0.18), (7, 0.1), (9, 0.06)):
        x += amp * np.sin(2 * np.pi * 120 * k * s + k)
    x *= 1 + 0.08 * np.sin(2 * np.pi * 0.31 * s)
    crackle = (RNG.random(len(s)) > 0.9993) * RNG.normal(0, 1.5, len(s))
    x += lowpass(crackle, 3000) * 3
    return loopable(x)


def vent():
    """Ventilation: brown noise through a slowly breathing low-pass, a faint rattle."""
    s = t(8.4)
    noise = np.cumsum(RNG.normal(0, 1, len(s)))
    noise = highpass(noise, 20)
    x = lowpass(noise, 500) * (1 + 0.25 * np.sin(2 * np.pi * 0.12 * s))
    x += 0.03 * np.sin(2 * np.pi * 47 * s) * (1 + np.sin(2 * np.pi * 0.5 * s))
    return loopable(x, fade=0.8)


def drip():
    """A water drop on concrete: a falling plink and a small echo."""
    s = t(1.2)
    f = 1600 * np.exp(-s * 9) + 700
    x = np.sin(2 * np.pi * np.cumsum(f) / RATE) * np.exp(-s * 28)
    echo = np.zeros_like(x)
    d = int(RATE * 0.21)
    echo[d:] = x[:-d] * 0.35
    return x + echo


def motor():
    """A security camera's pan motor: a geared whine rising and settling."""
    s = t(0.7)
    f = 420 + 160 * np.sin(np.pi * s / 0.7)
    phase = 2 * np.pi * np.cumsum(f) / RATE
    x = np.sign(np.sin(phase)) * 0.4 + np.sin(phase * 2) * 0.3
    x = lowpass(x, 2500)
    x += RNG.normal(0, 0.05, len(s))
    return x * envelope(len(s), 0.05, 0.12)


def clack():
    """A tube dying: a sharp tick, a buzz cut short, the glass settling."""
    s = t(0.6)
    tick = RNG.normal(0, 1, len(s)) * np.exp(-s * 140)
    buzz = np.sin(2 * np.pi * 120 * s) * (s < 0.18) * 0.6
    tink = np.sin(2 * np.pi * 3100 * s) * np.exp(-s * 30) * 0.3
    return tick + buzz + tink


def static():
    """Radio static: band-passed noise with a squelch at both ends."""
    s = t(0.9)
    x = highpass(lowpass(RNG.normal(0, 1, len(s)), 3200), 400)
    x *= 0.7 + 0.3 * (RNG.random(len(s)) > 0.5)
    return x * envelope(len(s), 0.02, 0.15)


def drone():
    """The blackout drone: 43 Hz and its harmonics up to the low mids (heard on a phone), a slow swell."""
    s = t(9.6)
    x = np.zeros_like(s)
    for k, amp in ((1, 1.0), (2, 0.6), (3, 0.45), (4, 0.3), (6, 0.2), (8, 0.12)):
        x += amp * np.sin(2 * np.pi * 43 * k * s + 0.7 * k)
    x *= 0.7 + 0.3 * np.sin(2 * np.pi * 0.07 * s)
    x += lowpass(RNG.normal(0, 0.15, len(s)), 300)
    return loopable(x, fade=1.2)


def tear():
    """The death's tape tear: a falling screech through noise, then silence (no scream, no gore: plan section 2)."""
    s = t(1.6)
    f = 2400 * np.exp(-s * 2.2) + 120
    x = np.sin(2 * np.pi * np.cumsum(f) / RATE) * 0.6
    x += highpass(RNG.normal(0, 1, len(s)), 800) * 0.5
    x = np.tanh(x * 2)
    return x * envelope(len(s), 0.01, 0.5)


for name, fn in (("hum", hum), ("vent", vent), ("drip", drip), ("motor", motor), ("clack", clack),
                 ("static", static), ("drone", drone), ("tear", tear)):
    write(name, fn())
