"""Ötüken Ormanı'nın sesleri (hepsi CC0 / kamu malı):
- "Birds and Wind - Ambient", Spring Spring (OpenGameArt, CC0; kuş sesleri
  isaiah658, syncopika, pauliuw, kamu malı)
- "Forest Ambience" (OpenGameArt, CC0)
- "Turdus merula 2.ogg", Oona Räisänen (Wikimedia Commons, kamu malı)

Kullanım: python3 -I tools/import_forest.py <kuş_rüzgâr.ogg> <orman.mp3>
          <karatavuk.ogg> <assets/audio>
Çıktı: amb_forest.wav (40 sn, dikişsiz döngü), bird_1..4.wav (tek ötüşler).
"""
import math
import struct
import subprocess
import sys
import wave

SR = 44100
BIRDS, AMB, BLACKBIRD, OUT = sys.argv[1:5]


def load(path):
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-ar', str(SR),
         '-f', 'f32le', '-'], check=True, capture_output=True).stdout
    return list(struct.unpack('<%df' % (len(raw) // 4), raw))


def n(sec):
    return int(sec * SR)


def save(name, d, peak):
    m = max(abs(x) for x in d) or 1
    k = peak / m
    with wave.open(f'{OUT}/{name}.wav', 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, x * k)) * 32000)) for x in d))
    print(f'{name:12s} {len(d) / SR:5.2f} sn')


def loop(d, xfade):
    f = n(xfade)
    body, tail = d[:-f], d[-f:]
    for i in range(f):
        t = i / f
        body[i] = body[i] * math.sqrt(t) + tail[i] * math.sqrt(1 - t)
    return body


# Ana döngü: kuş ve rüzgâr, altında hafif orman uğultusu.
birds = load(BIRDS)[n(6):n(6 + 43)]
amb = load(AMB)
under = [amb[i % len(amb)] * 0.45 for i in range(len(birds))]
mix = [a + b for a, b in zip(birds, under)]
save('amb_forest', loop(mix, 3.0), 0.5)

# Karatavuk: sessizlikle ayrılan ötüşler; en güçlü dördü.
bb = load(BLACKBIRD)
win = n(0.05)
env = [sum(abs(x) for x in bb[i:i + win]) / win for i in range(0, len(bb) - win, win)]
floor = sorted(env)[len(env) // 3] * 2.5
phrases = []
start = None
for i, e in enumerate(env):
    if e > floor and start is None:
        start = i
    elif e <= floor and start is not None:
        if i - start >= 8:  # en az 0,4 sn
            phrases.append((start, i))
        start = None
phrases.sort(key=lambda p: -sum(env[p[0]:p[1]]))
for k, (a, b) in enumerate(sorted(phrases[:4])):
    d = bb[max(0, a * win - n(0.05)):min(len(bb), b * win + n(0.15))]
    fi, fo = n(0.02), n(0.12)
    for i in range(min(fi, len(d))):
        d[i] *= i / fi
    for i in range(min(fo, len(d))):
        d[-1 - i] *= i / fo
    save(f'bird_{k + 1}', d, 0.5)
