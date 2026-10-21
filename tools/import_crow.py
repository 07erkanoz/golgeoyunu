"""Karga sesi: gerçek kayıttan (CC0).

Kaynak: OpenGameArt "crow caw" (zeroisnotnull), CC0 1.0 —
https://opengameart.org/content/crow-caw ("Crow caw recorded in Cairo
somewhere close to the pyramids").

Tek gak kırpılır, düzeyi dengelenir; kuş havalanırken iki kez bağırsın diye
ikinci, biraz daha pes bir gak eklenir.
Kullanım: python3 -I tools/import_crow.py <crow_caw.wav> <assets/audio>
"""
import struct
import subprocess
import sys
import wave

SR = 44100
src, out = sys.argv[1], sys.argv[2]


def load(path, rate_scale=1.0):
    # rate_scale < 1: daha pes ve uzun (örnek hızıyla perde kaydırma).
    af = f'asetrate={int(96000 * rate_scale)},aresample={SR}'
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', path, '-ac', '1', '-af', af,
         '-f', 'f32le', '-'], check=True, capture_output=True).stdout
    return list(struct.unpack('<%df' % (len(raw) // 4), raw))


def trim(x, thr=0.02):
    peak = max(abs(v) for v in x)
    i = next(i for i, v in enumerate(x) if abs(v) > peak * thr)
    j = len(x) - next(i for i, v in enumerate(reversed(x)) if abs(v) > peak * thr)
    return x[max(0, i - 200):j + 400]


def fade(x, a=0.004, b=0.04):
    na, nb = int(a * SR), int(b * SR)
    for k in range(min(na, len(x))):
        x[k] *= k / na
    for k in range(min(nb, len(x))):
        x[-1 - k] *= k / nb
    return x


first = fade(trim(load(src)))
second = fade(trim(load(src, 0.9)))
gap = [0.0] * int(0.16 * SR)
data = first + gap + [v * 0.8 for v in second]
peak = max(abs(v) for v in data)
with wave.open(f'{out}/crow.wav', 'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b''.join(struct.pack('<h', int(v / peak * 0.85 * 32767)) for v in data))
print('crow.wav', round(len(data) / SR, 2), 's')
