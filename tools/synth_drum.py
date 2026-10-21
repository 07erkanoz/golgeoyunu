"""Kam'ın davulu: gergin deri, derin bir vuruş (saf Python sentezi).
Kullanım: python3 tools/synth_drum.py assets/audio"""
import math, random, struct, sys, wave, os

SR = 44100
rnd = random.Random(1071)


def drum(sec=1.1):
    n = int(sec * SR)
    out = []
    phase = 0.0
    lp = 0.0
    for i in range(n):
        t = i / SR
        # Deri: perdesi vuruşla hızla düşer.
        f = 62 + 70 * math.exp(-t * 22)
        phase += 2 * math.pi * f / SR
        body = math.sin(phase) * math.exp(-t * 4.2)
        # Çerçeve ve zil: kısa, parlak bir tıkırtı.
        lp += (rnd.uniform(-1, 1) - lp) * 0.5
        click = lp * math.exp(-t * 60) * 0.5
        ring = 0.12 * math.sin(2 * math.pi * 410 * t) * math.exp(-t * 9)
        out.append(body + click + ring)
    return out


def save(path, data, gain=0.85):
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
save(os.path.join(out, 'drum.wav'), drum())
