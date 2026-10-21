"""Nuh'un Gemisi'nin ortam sesi: gerçek kayıtlardan katmanlı bir döngü.

Kaynaklar (hepsi CC0 / kamu malı):
- Yağmur: OpenGameArt "AMB Rain Loop 1" (CC0); gövdenin içinden duyulur
  gibi boğuk.
- Güverteye vuran yağmur: Wikimedia Commons "Rain on a veranda and thunder"
  (ezwa, kamu malı); gök gürültüsünün olduğu yer alınmaz.
- Dalgalar: OpenGameArt "Water Waves" (transitking / freesound 11505, CC0);
  yavaşlatılıp boğulur, gövdeye çarpar gibi.
- Gıcırtı: OpenGameArt "Tree Creaking" (Department64, CC0); yavaşlatılıp
  kalınlaştırılır: yalpalayan geminin kaburgaları.

Kullanım: python3 -I tools/import_ark.py <kaynak_klasörü> <assets/audio>
"""
import math
import os
import struct
import subprocess
import sys
import wave

SR = 44100
SRC, OUT = sys.argv[1], sys.argv[2]
L = 32.0  # döngü süresi (sn)


def find(name):
    for root, _, files in os.walk(SRC):
        if name in files:
            return os.path.join(root, name)
    raise SystemExit(f'bulunamadı: {name}')


def load(name, start=0.0, dur=None, slow=1.0, lowpass=None, highpass=None):
    path = find(name)
    rate = int(subprocess.run(
        ['ffprobe', '-v', 'error', '-select_streams', 'a:0', '-show_entries',
         'stream=sample_rate', '-of', 'csv=p=0', path],
        check=True, capture_output=True, text=True).stdout.strip())
    af = [f'asetrate={int(rate * slow)}', f'aresample={SR}']
    if lowpass:
        af.append(f'lowpass=f={lowpass}')
    if highpass:
        af.append(f'highpass=f={highpass}')
    cmd = ['ffmpeg', '-v', 'error', '-ss', str(start)]
    if dur:
        cmd += ['-t', str(dur)]
    cmd += ['-i', path, '-ac', '1', '-af', ','.join(af), '-f', 'f32le', '-']
    raw = subprocess.run(cmd, check=True, capture_output=True).stdout
    return list(struct.unpack('<%df' % (len(raw) // 4), raw))


def fade(x, a, b):
    na, nb = int(a * SR), int(b * SR)
    for k in range(min(na, len(x))):
        x[k] *= k / na
    for k in range(min(nb, len(x))):
        x[-1 - k] *= k / nb
    return x


def rms(x):
    return math.sqrt(sum(v * v for v in x) / max(1, len(x)))


def norm(x, level):
    g = level / max(rms(x), 1e-9)
    return [v * g for v in x]


n = int((L + 2) * SR)
out = [0.0] * n


def place(x, at, gain):
    o = int(at * SR)
    for k, v in enumerate(x):
        i = o + k
        if 0 <= i < n:
            out[i] += v * gain


# Yağmur yatağı: boğuk, sürekli.
rain = norm(load('amb_rain_loop_1.ogg', 2, L + 2, lowpass=2600), 0.08)
place(rain, 0, 1.0)
# Güverteye vuran damlalar: iki parça (gök gürültüsü olan 12.5-14 sn dışı).
drip1 = norm(load('veranda_rain.ogg', 0, 12, lowpass=6000, highpass=400), 0.035)
drip2 = norm(load('veranda_rain.ogg', 14.5, 15, lowpass=6000, highpass=400), 0.035)
place(fade(drip1, 1.5, 1.5), 0, 1.0)
place(fade(drip2, 1.5, 1.5), 11, 1.0)
place(fade(drip1[:], 1.5, 1.5), 24, 1.0)
# Dalgalar: gövdeye vuran boğuk çarpmalar.
waves = [
    norm(fade(load(f'wave_0{i}_cc0-11505__transitking__wavesound.flac',
                   slow=0.8, lowpass=650), 0.3, 0.8), 0.12)
    for i in (1, 2, 3)
]
for at, i, g in [(1.0, 0, 1.0), (6.5, 1, 0.8), (12.0, 2, 1.1),
                 (17.5, 0, 0.7), (22.0, 1, 1.0), (27.5, 2, 0.8)]:
    place(waves[i], at, g)
# Kaburga gıcırtıları: yalpa ritminde, ağır.
creak = load('tree_creak.ogg', 0, 4.2)
deep = norm(fade(load('tree_creak.ogg', 0, 4.2, slow=0.62, lowpass=2200), 0.2, 1.0), 0.07)
mid = norm(fade(load('tree_creak.ogg', 0.6, 3.0, slow=0.78, lowpass=3000), 0.2, 0.8), 0.05)
for at, x, g in [(3.0, deep, 1.0), (10.0, mid, 0.8), (16.5, deep, 0.75),
                 (25.0, mid, 1.0)]:
    place(x, at, g)

# Dikişsiz döngü: sonun 2 saniyesi başa bindirilir.
xf = int(2 * SR)
body = out[:int(L * SR)]
for k in range(xf):
    a = k / xf
    body[k] = body[k] * a + out[int(L * SR) + k] * (1 - a)
# Eski ortam sesinin düzeyine getirilir; dalga vuruşları yumuşakça
# sınırlanır (tanh), patlamaz.
body = norm(body, 0.085)
body = [math.tanh(v * 1.6) / math.tanh(1.6) for v in body]
peak = max(abs(v) for v in body)
g = min(0.92 / peak, 1.0)
with wave.open(os.path.join(OUT, 'amb_ark.wav'), 'wb') as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(b''.join(
        struct.pack('<h', int(max(-1, min(1, v * g)) * 32767)) for v in body))
print('amb_ark.wav', L, 'sn, tepe', round(peak, 3))
