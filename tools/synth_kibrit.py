"""Kibrit sesi (girişte perdenin kandili yakılırken): sürtünme, parlayış,
kısa çıtırtı. Saf Python, dış kaynak yok.

  python3 tools/synth_kibrit.py assets/audio
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


total = [0.0] * n(1.3)


def add(at, samples, gain=1.0):
    s = n(at)
    for i, v in enumerate(samples):
        if s + i < len(total):
            total[s + i] += v * gain


# 1) Sürtünme: kutunun kenarında iki kısa, pürüzlü çekiş.
for start, length in [(0.0, 0.07), (0.09, 0.11)]:
    x = [r.uniform(-1, 1) for _ in range(n(length))]
    hi = lowpass(x, 5200)
    lo = lowpass(x, 1400)
    out = []
    for i, (a, b) in enumerate(zip(hi, lo)):
        t = i / SR
        k = t / length
        grit = 0.55 + 0.45 * (1 if r.random() < 0.35 else 0)
        env = math.sin(math.pi * k) * grit
        out.append((a - b) * env)
    add(start, out, 0.8)

# 2) Parlayış: kükürt tutuşur ("fşş"), boğuklaşarak söner.
length = 0.45
x = [r.uniform(-1, 1) for _ in range(n(length))]
out = []
y = 0.0
for i, v in enumerate(x):
    t = i / SR
    fc = 6000 * math.exp(-t / 0.12) + 500
    a = 1 - math.exp(-2 * math.pi * fc / SR)
    y += a * (v - y)
    env = min(1, t / 0.008) * math.exp(-t / 0.16)
    out.append(y * env)
add(0.2, out, 1.0)

# 3) Alev: yumuşak uğultu ve birkaç çıtırtı.
length = 0.8
x = lowpass([r.uniform(-1, 1) for _ in range(n(length))], 380)
out = []
for i, v in enumerate(x):
    t = i / SR
    env = min(1, t / 0.1) * math.exp(-t / 0.35)
    out.append(v * env * 2.2)
add(0.32, out, 0.7)
for _ in range(7):
    at = 0.35 + r.random() * 0.6
    click = [r.uniform(-1, 1) * math.exp(-i / (SR * 0.002)) for i in range(n(0.01))]
    add(at, lowpass(click, 2500), 0.25 + r.random() * 0.25)

peak = max(abs(v) for v in total) or 1
total = [v / peak * 0.7 for v in total]
while total and abs(total[-1]) < 0.002:
    total.pop()
f = n(0.08)
for i in range(min(f, len(total))):
    total[-1 - i] *= i / f
os.makedirs(OUT, exist_ok=True)
with wave.open(os.path.join(OUT, "match.wav"), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in total))
print("match.wav", round(len(total) / SR, 2), "sn")
