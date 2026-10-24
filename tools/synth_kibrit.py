"""Kibrit sesi (girişte perdenin kandili yakılırken): kutuya sürtünen baş,
"fşt" diye tutuşma, kısa ince alev. Saf Python, dış kaynak yok.

Gerçek kibritte bas yoktur: ses tiz bir sürtünme ve parlayıştır. Bütün
parçalar 500 Hz'in altını keser (ilk sürümde alçak uğultu patlama gibi
duyuluyordu).

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


def band(x, lo, hi):
    """Kaba bant geçiren: iki alçak geçirenin farkı."""
    return [a - b for a, b in zip(lowpass(x, hi), lowpass(x, lo))]


def noise(sec):
    return [r.uniform(-1, 1) for _ in range(n(sec))]


total = [0.0] * n(1.0)


def add(at, samples, gain=1.0):
    s = n(at)
    for i, v in enumerate(samples):
        if s + i < len(total):
            total[s + i] += v * gain


# 1) Sürtünme: başın kutunun zımparasında iki kısa çekişi. Pürüzlü: sık,
# rastgele tıkırtılardan oluşan tiz bir hışırtı.
for start, length, gain in [(0.0, 0.05, 0.5), (0.07, 0.08, 0.8)]:
    x = band(noise(length), 2500, 7500)
    out = []
    for i, v in enumerate(x):
        k = i / max(1, len(x) - 1)
        grit = 0.35 + (0.65 if r.random() < 0.25 else 0)
        out.append(v * math.sin(math.pi * k) * grit)
    add(start, out, gain)

# 2) Tutuşma: "fşt" — parlak bir hışırtı, hızla açılır, çabuk söner; tınısı
# tizden ortaya iner.
length = 0.32
x = noise(length)
hi = band(x, 1800, 8000)
mid = band(x, 900, 3200)
out = []
for i, (a, b) in enumerate(zip(hi, mid)):
    t = i / SR
    env = min(1, t / 0.006) * math.exp(-t / 0.075)
    k = min(1, t / 0.2)
    out.append((a * (1 - k) + b * k) * env)
add(0.15, out, 1.1)
# Kükürdün çıtırtıları.
for _ in range(9):
    at = 0.15 + r.random() * 0.22
    click = [r.uniform(-1, 1) * math.exp(-i / (SR * 0.0015)) for i in range(n(0.008))]
    add(at, band(click, 1500, 6000), 0.35 + r.random() * 0.3)

# 3) Alev: çok kısık, ince bir hışırtı; yavaşça söner.
length = 0.55
x = band(noise(length), 900, 2600)
out = []
for i, v in enumerate(x):
    t = i / SR
    env = min(1, t / 0.05) * math.exp(-t / 0.22)
    out.append(v * env)
add(0.3, out, 0.25)

peak = max(abs(v) for v in total) or 1
total = [v / peak * 0.5 for v in total]
while total and abs(total[-1]) < 0.002:
    total.pop()
f = n(0.06)
for i in range(min(f, len(total))):
    total[-1 - i] *= i / f
os.makedirs(OUT, exist_ok=True)
with wave.open(os.path.join(OUT, "match.wav"), "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in total))
print("match.wav", round(len(total) / SR, 2), "sn")
