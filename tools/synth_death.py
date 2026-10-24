"""Ölüm sesleri: tını değil olay. Saf Python, dış kaynak yok.

  death.wav   düşüş/yakalanma: karara inen kısa, hüzünlü bir ney cümlesi
              ve perdenin ardından boğuk bir vuruş (tasvir düşer).
  shatter.wav fener ışığında yakalanma: kavanoz camı tek bir çatlakla kırılır
              (melodi gibi tıngırdamaz), kandil boğuk bir "puf"la söner.

  python3 tools/synth_death.py assets/audio
  python3 tools/sesleri_sikistir.py   # death.wav → assets_src, death.ogg
"""
import math
import os
import random
import struct
import sys
import wave

SR = 44100
OUT = sys.argv[1]
r = random.Random(7)


def n(sec):
    return int(SR * sec)


def lowpass(x, fc):
    a = 1 - math.exp(-2 * math.pi * fc / SR)
    y, out = 0.0, []
    for v in x:
        y += a * (v - y)
        out.append(y)
    return out


def highpass(x, fc):
    lp = lowpass(x, fc)
    return [a - b for a, b in zip(x, lp)]


def noise(sec):
    return [r.uniform(-1, 1) for _ in range(n(sec))]


def place(base, clip, at, gain):
    s = n(at)
    for i, v in enumerate(clip):
        if s + i < len(base):
            base[s + i] += v * gain


def finish(x, name, peak=0.7):
    m = max(abs(v) for v in x) or 1
    x = [v / m * peak for v in x]
    while x and abs(x[-1]) < 0.002:
        x.pop()
    f = n(0.06)
    for i in range(min(f, len(x))):
        x[-1 - i] *= i / f
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, v)) * 32767)) for v in x))
    print(name, round(len(x) / SR, 2), "sn")


def thud(f0, sec, tau):
    """Boğuk davul: perdenin ardından gelir gibi, saldırısı yumuşak."""
    out, ph = [], 0.0
    for i in range(n(sec)):
        t = i / SR
        f = f0 * (1 + 0.8 * math.exp(-t / 0.03))
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * math.exp(-t / tau) * min(1, t / 0.006))
    return out


def fall_tone(f0, f1, sec):
    """Aşağı inen kısık ton (neyin son nefesi gibi, üflemeli)."""
    out, ph = [], 0.0
    air = lowpass(noise(sec), 900)
    for i in range(n(sec)):
        t = i / sec / SR
        f = f0 * (f1 / f0) ** t
        ph += 2 * math.pi * f / SR
        a = min(1, t / 0.08) * (1 - t) ** 1.6
        out.append((math.sin(ph) * 0.8 + math.sin(2 * ph) * 0.15 + air[i] * 0.5) * a)
    return out


def swish(sec, lo, hi):
    """Kumaş/hava hışırtısı."""
    x = lowpass(highpass(noise(sec), lo), hi)
    m = len(x)
    return [v * math.sin(math.pi * i / m) ** 2 for i, v in enumerate(x)]


# ---------------------------------------------------------------- death
# Hüzünlü bir ney cümlesi: hicazda La'dan karara (Re) inen beş nota, tek
# nefeste, salon yankısıyla; altında perdenin ardından gelen boğuk bir
# vuruş (tasvir düştü). Melodi kısa: sık ölünse de bıktırmasın.
sys.path.insert(0, os.path.dirname(__file__))
import synth_ney as ney  # noqa: E402

phrase = [("A", 0.42), ("G", 0.34), ("F#", 0.34), ("Eb", 0.46), ("D", 1.25)]
dry = ney.taksim(phrases=[phrase], rests=[0.2], with_dem=False, lead=0.12)
wet = ney.hall(dry, 0.38)
death = [0.0] * (len(wet) + n(0.3))
place(death, wet, 0.0, 1.0)
place(death, lowpass(thud(66, 1.0, 0.3), 700), 0.0, 0.5)
finish(death, "death", 0.7)

# -------------------------------------------------------------- shatter
sh = [0.0] * n(1.4)
crack = highpass(noise(0.09), 2200)
crack = [v * math.exp(-i / n(0.018)) for i, v in enumerate(crack)]
place(sh, crack, 0.0, 1.0)
# Birkaç cam kırığı, aynı anda ve kısa: tıngırtı dizisi değil.
for k in range(4):
    f = 2800 + r.random() * 2600
    ping = [math.sin(2 * math.pi * f * i / SR) * math.exp(-i / n(0.035)) for i in range(n(0.2))]
    place(sh, ping, 0.004 + k * 0.006, 0.18)
place(sh, swish(0.5, 120, 700), 0.08, 0.55)  # kandil söner: boğuk "puf"
place(sh, thud(62, 0.9, 0.3), 0.1, 0.55)
finish(sh, "shatter", 0.7)
