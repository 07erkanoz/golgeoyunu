"""Gizli alkış sesi: perdenin ardında birkaç seyirci (kısa, sıcak, yankılı).
Saf Python, dış kaynak yok.

  python3 tools/synth_alkis.py assets/audio
"""
import math
import os
import random
import struct
import sys
import wave

SR = 44100
OUT = sys.argv[1]
r = random.Random(1660)


def n(sec):
    return int(SR * sec)


def lowpass(x, fc):
    a = 1 - math.exp(-2 * math.pi * fc / SR)
    y, out = 0.0, []
    for v in x:
        y += a * (v - y)
        out.append(y)
    return out


def clap(sec=0.06):
    """Tek el çırpışı: bant geçiren gürültü patlaması."""
    x = [r.uniform(-1, 1) for _ in range(n(sec))]
    hi = lowpass(x, 3200)
    lo = lowpass(x, 700)
    out = []
    for i, (a, b) in enumerate(zip(hi, lo)):
        t = i / SR
        env = math.exp(-t / 0.012) * min(1, t / 0.0008)
        out.append((a - b) * env)
    return out


total = [0.0] * n(3.0)
# Beş seyirci, her biri kendi hızında; başta seyrek, sonra coşar, söner.
for who in range(5):
    t = 0.05 + r.random() * 0.25
    rate = 0.24 + r.random() * 0.1
    gain = 0.5 + r.random() * 0.4
    while t < 2.4:
        k = t / 2.4
        loud = gain * (0.6 + 0.4 * math.sin(math.pi * min(1, k * 1.2)))
        c = clap(0.05 + r.random() * 0.03)
        s = n(t)
        for i, v in enumerate(c):
            if s + i < len(total):
                total[s + i] += v * loud
        t += rate * (0.85 + r.random() * 0.3)
# Kısa yankı: sarnıcın taşı.
d = n(0.11)
for i in range(d, len(total)):
    total[i] += total[i - d] * 0.28
peak = max(abs(v) for v in total) or 1
total = [v / peak * 0.6 for v in total]
while total and abs(total[-1]) < 0.002:
    total.pop()
f = n(0.08)
for i in range(min(f, len(total))):
    total[-1 - i] *= i / f
os.makedirs(OUT, exist_ok=True)
with wave.open(os.path.join(OUT, "clap.wav"), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in total))
print("clap.wav", round(len(total) / SR, 2), "sn")
