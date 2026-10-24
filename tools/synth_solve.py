"""Düzenek çözülünce çalan "çözüldü" sesi: hicaz dizisinden yükselen üç nota,
kanun teli gibi çekilip yankıyla söner. Saf Python, dış kaynak yok.

  python3 tools/synth_solve.py assets/audio
"""
import math
import os
import struct
import sys
import wave

SR = 44100
OUT = sys.argv[1]


def pluck(freq: float, sec: float) -> list[float]:
    """Çekilen tel: hızlı saldırı, üst harmonikleri önce sönen gövde."""
    out = []
    for i in range(int(SR * sec)):
        t = i / SR
        a = min(1.0, t / 0.004)
        v = 0.0
        for h, g, tau in ((1, 1.0, 0.55), (2, 0.45, 0.25), (3, 0.22, 0.14), (4, 0.1, 0.08)):
            v += g * math.exp(-t / tau) * math.sin(2 * math.pi * freq * h * t)
        out.append(a * v)
    return out


def place(base: list[float], clip: list[float], at: float, gain: float) -> None:
    s = int(at * SR)
    for i, x in enumerate(clip):
        if s + i < len(base):
            base[s + i] += x * gain


def echo(data: list[float], delay: float, fb: float, mix: float) -> list[float]:
    d = int(delay * SR)
    out = data + [0.0] * (d * 4)
    for i in range(d, len(out)):
        out[i] += out[i - d] * fb * mix
    return out


# Hicaz: Re – Fa# – La (D5, F#5, A5); son nota biraz uzun.
total = [0.0] * int(SR * 1.6)
for k, (f, g) in enumerate(((587.33, 0.55), (739.99, 0.6), (880.0, 0.7))):
    place(total, pluck(f, 1.1), k * 0.11, g)
total = echo(total, 0.19, 0.4, 0.5)
peak = max(abs(x) for x in total) or 1.0
total = [x / peak * 0.7 for x in total]
# Sessiz kuyruk kırpılır, sonu yumuşar.
while total and abs(total[-1]) < 0.002:
    total.pop()
fade = int(0.08 * SR)
for i in range(min(fade, len(total))):
    total[-1 - i] *= i / fade

os.makedirs(OUT, exist_ok=True)
with wave.open(os.path.join(OUT, "solve.wav"), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x)) * 32767)) for x in total))
print("solve.wav", round(len(total) / SR, 2), "sn")
