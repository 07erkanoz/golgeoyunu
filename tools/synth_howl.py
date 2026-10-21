"""Gökbörü'nün uluması: saf Python sentezi (dış kaynak yok).
Kullanım: python3 tools/synth_howl.py assets/audio"""
import math, random, struct, sys, wave, os

SR = 44100
rnd = random.Random(552)


def howl(sec=3.2, f0=390.0):
    n = int(sec * SR)
    out = [0.0] * n
    phase = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SR
        u = t / sec
        # Perde: hızla yükselir, uzun tutulur, sonda iner.
        if u < 0.18:
            f = f0 + (f0 * 0.42) * math.sin(u / 0.18 * math.pi / 2)
        elif u < 0.72:
            f = f0 * 1.42 + f0 * 0.04 * math.sin((u - 0.18) * 9)
        else:
            k = (u - 0.72) / 0.28
            f = f0 * 1.42 - f0 * 0.5 * k * k
        # Ağır titreşim (vibrato), uca doğru artar.
        f *= 1 + 0.012 * math.sin(2 * math.pi * 5.2 * t) * (0.4 + u)
        phase += 2 * math.pi * f / SR
        tone = (math.sin(phase) + 0.32 * math.sin(2 * phase + 0.4)
                + 0.12 * math.sin(3 * phase + 1.1))
        # Nefes: süzülmüş gürültü.
        lp += (rnd.uniform(-1, 1) - lp) * 0.08
        a = min(1.0, t / 0.35) * min(1.0, (sec - t) / 0.9)
        a = a * a * (3 - 2 * a)
        out[i] = (tone * 0.75 + lp * 0.5) * a
    return out


def distance(data, delays=((0.19, 0.35), (0.41, 0.22), (0.77, 0.14), (1.3, 0.08))):
    """Dağlarda uzaktan gelen yankılar."""
    tail = int(1.8 * SR)
    res = list(data) + [0.0] * tail
    for d, g in delays:
        k = int(d * SR)
        for i, x in enumerate(data):
            res[i + k] += x * g
    # Tizleri biraz yumuşat (uzaklık).
    y = 0.0
    for i, x in enumerate(res):
        y += (x - y) * 0.35
        res[i] = y
    return res


def save(path, data, gain=0.8):
    peak = max(1e-9, max(abs(x) for x in data))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, x / peak * gain)) * 32767))
            for x in data))


out = sys.argv[1]
os.makedirs(out, exist_ok=True)
save(os.path.join(out, 'howl.wav'), distance(howl()))
