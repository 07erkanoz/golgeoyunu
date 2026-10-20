"""Konya'nın ortam sesi: Şeb-i Arûs gecesi, uzaktan bir semâhane.

Uhrevi, mistik bir gece: karlı ovada ince bir kış rüzgârı; uzaktan,
dalga dalga kabarıp sönen derin bir "Hû" zikri (çok sesli, 'u' ünlüsüne
biçimlendirilmiş); semâhaneden süzülen ney (Hicaz, uzak ve buğulu); seyrek,
yumuşak kudüm vuruşları. Hepsi geniş bir kubbenin altında yankılanır.

Kullanım: python3 tools/synth_konya.py assets/audio
"""
import math
import random
import sys

from synth_ney import (D, HICAZ, SR, hall, highpass, loop, lowpass, n, save,
                       smooth, taksim)

OUT = sys.argv[1]
rnd = random.Random(1273)          # Mevlânâ'nın vuslatı
L = 42.0                           # döngü uzunluğu (sn)
N = n(L)


def bandpass_q(data, f, q):
    """Sabit tepe kazançlı rezonans süzgeci."""
    w = 2 * math.pi * f / SR
    al = math.sin(w) / (2 * q)
    a0 = 1 + al
    b0, b2 = al / a0, -al / a0
    a1, a2 = -2 * math.cos(w) / a0, (1 - al) / a0
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for x in data:
        y = b0 * x + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out.append(y)
    return out


def hu_choir():
    """Uzaktan "Hû": birkaç ses, Re'de ve beşlisinde, 'u' ünlüsüyle.

    Her nefes ~8 sn kabarır, ~3 sn tutulur, söner; döngüde dört nefes.
    """
    voices = [(D / 4, 0.0), (D / 4 * 1.0035, 0.7), (D / 4 * 0.997, 1.9),
              (D / 4 * 1.5, 0.4), (D / 4 * 1.5 * 1.003, 1.3), (D / 2, 2.2)]
    raw = [0.0] * N
    for f, phase in voices:
        ph = phase
        drift = rnd.uniform(0, 6.28)
        gain = 0.55 if f > D / 3 else 1.0
        for k in range(N):
            t = k / SR
            ff = f * (1 + 0.0025 * math.sin(2 * math.pi * 0.11 * t + drift))
            ph += ff / SR
            ph -= math.floor(ph)
            raw[k] += (2 * ph - 1) * gain        # testere: zengin harmonik
    raw = lowpass(raw, 2200)
    # 'u' ünlüsü: biçimlendiriciler ~320, ~800, ~2300 Hz.
    voice = [a * 1.0 + b * 0.45 + c * 0.12 for a, b, c in zip(
        bandpass_q(raw, 320, 5), bandpass_q(raw, 800, 7), bandpass_q(raw, 2300, 9))]
    # Dört nefes; döngünün başına ve sonuna denk gelmez, dikiş temiz kalır.
    out = [0.0] * N
    for start in (1.0, 11.5, 22.0, 32.0):
        dur = 9.5
        for k in range(n(dur)):
            i = n(start) + k
            if i >= N:
                break
            t = k / SR
            a = smooth(t / 3.8) * smooth((dur - t) / 4.0)
            # Nefes ortasında hafif bir titreşim: zikrin nabzı.
            a *= 0.85 + 0.15 * math.sin(2 * math.pi * 0.9 * t) ** 2
            out[i] = voice[i] * a
    return out


def kudum():
    """Uzaktan seyrek kudüm: ağır bir 'düm ... tek tek ... düm'."""
    out = [0.0] * N

    def hit(at, f0, gain, length=0.9):
        s = n(at)
        ph = 0.0
        for k in range(n(length)):
            if s + k >= N:
                break
            t = k / SR
            f = f0 * (1 + 0.6 * math.exp(-t * 30))       # deri gerilip salınır
            ph += 2 * math.pi * f / SR
            body = math.sin(ph) * math.exp(-t * 5.5)
            click = rnd.uniform(-1, 1) * math.exp(-t * 90) * 0.25
            out[s + k] += (body + click) * gain

    # Usûl: her 4 sn'de bir döngü (düm, tek-tek), arada sessizlik.
    t = 2.2
    beat = 0
    while t < L - 3.0:
        if beat % 2 == 0:
            hit(t, 72, 1.0)
            hit(t + 1.5, 118, 0.35)
            hit(t + 2.0, 118, 0.3)
        else:
            hit(t, 72, 0.8)
            hit(t + 2.25, 118, 0.28)
        t += 4.0
        beat += 1
    return lowpass(out, 700)


def winter_wind():
    """Karlı ovanın ince rüzgârı: yavaş esintilerle kabaran, çok kısık."""
    white = [rnd.uniform(-1, 1) for _ in range(N)]
    w = bandpass_q(lowpass(white, 1400), 520, 0.8)
    out = []
    for k, x in enumerate(w):
        t = k / SR
        gust = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(2 * math.pi * t / L * 3 + 1.1)) \
            * (0.6 + 0.4 * math.sin(2 * math.pi * t / L * 7))
        out.append(x * gust)
    return out


def ney_far():
    """Semâhaneden süzülen ney: Hicaz, ağır, iki uzun nefes."""
    phrases = [
        [('D', 1.6), ('Eb', 1.0), ('F#', 1.4), ('G', 1.2), ('A', 3.6),
         ('G', 1.1), ('F#', 2.8)],
        [('A', 1.4), ('Bb', 1.2), ('C', 1.6), ('Bb', 1.0), ('A', 1.4),
         ('G', 1.0), ('F#', 1.3), ('Eb', 1.4), ('D', 4.0)],
    ]
    rests = [4.5, 0.0]
    dry = taksim(phrases, rests, HICAZ, with_dem=False, lead=6.0)
    # Uzaklık: tizler kubbede yutulur.
    return lowpass(dry, 2800)


def fit(data):
    return (data + [0.0] * N)[:N]


if __name__ == '__main__':
    hu = fit(hu_choir())
    ney = fit(ney_far())
    drum = fit(kudum())
    wind = fit(winter_wind())

    def rms(d):
        return math.sqrt(sum(x * x for x in d) / len(d)) or 1.0

    # Seviyeler: zikir ve ney önde, kudüm ve rüzgâr altta.
    gh, gy, gd, gw = (0.30 / rms(hu), 0.26 / rms(ney), 0.10 / rms(drum),
                      0.06 / rms(wind))
    mixed = [h * gh + y * gy + d * gd + w * gw
             for h, y, d, w in zip(hu, ney, drum, wind)]
    mixed = highpass(mixed, 45)
    wet = hall(mixed, 0.5, size=1.35)
    data = loop(wet, len(wet) / SR - L)
    save('amb_konya', data, 0.5, OUT)
    print(f'amb_konya {len(data) / SR:.2f} sn')
