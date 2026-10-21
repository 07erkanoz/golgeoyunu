"""Yapay seslerin yerine gerçek kayıtlar (kamu malı / CC0).

Kaynaklar:
- Kurt uluması: Wikimedia Commons "File:Wolf_howls.ogg", ABD Balık ve Yaban
  Hayatı Servisi (kamu malı). 8,6-12,7 sn arasındaki tek, temiz uluma.
- Karda adım: OpenGameArt "4 dry snow steps" (qubodup), CC0.
- Kalp atışı: OpenGameArt "heartbeat sounds" (bart), CC0. Biraz yavaşlatılıp
  (daha pes) 8 saniyelik döngü yapılır.
- Gök gürültüsü: OpenGameArt "Rain + Long Thunder" (WuxiaScrub), CC0.
  Gürlemenin başladığı yerden kesilir; yağmur hışırtısı alçak geçiren
  süzgeçle bastırılır.
- Yarasalar: OpenGameArt "Bat Screeches" (polymorpheva / freesound 104205),
  CC0. Üç çığlık üst üste bindirilip bir sürü yapılır.
- Kam'ın davulu: Wikimedia Commons "Bęben obręczowy uderzenia pojedyncze"
  (çerçeve davulu, tek vuruşlar), CC0. En güçlü vuruş, biraz pesleştirilir.
- Hırlama: OpenGameArt "Bear Growls" (ABD Balık ve Yaban Hayatı Servisi),
  CC0. İki hırıltı pesleştirilip art arda.
- Zincir: OpenGameArt "Chain winch sounds", CC0.
- Taş sürtünmesi: OpenGameArt "Stone Door", CC0.
- Nefes: Wikimedia Commons "Breathing man", kamu malı. Bir çekiş, bir veriş.
- Karlı rüzgâr: Wikimedia Commons "Howling wind", CC0. 24 sn dikişsiz döngü.
- Mağara: OpenGameArt "Dripping water loop" (atmosbasement), CC0. Ani
  vuruşlar bastırılır, dikişsiz döngü.

Her ses, değiştirdiği yapay sesin ortalama düzeyine (RMS) getirilir.
Kullanım: python3 -I tools/import_nature.py <kaynak_klasörü> <assets/audio>
Kaynak klasöründe dosyalar alt klasörlerde aranır (yalnızca okunur).
synth_sounds.py bu dosyaların adlarını CC0 kümesinde tanır ve üzerine yazmaz.
"""
import math
import os
import struct
import subprocess
import sys
import wave

SR = 44100
SRC, OUT = sys.argv[1], sys.argv[2]


def find(name):
    for root, _, files in os.walk(SRC):
        if name in files:
            return os.path.join(root, name)
    raise SystemExit(f'bulunamadı: {name}')


def load(name, start=0.0, dur=None, slow=1.0, lowpass=None, extra=None):
    """Mono, 44,1 kHz kayan noktalı örnekler. [slow] < 1: daha yavaş, pes."""
    path = find(name)
    rate = int(subprocess.run(
        ['ffprobe', '-v', 'error', '-select_streams', 'a:0', '-show_entries',
         'stream=sample_rate', '-of', 'csv=p=0', path],
        check=True, capture_output=True, text=True).stdout.strip())
    af = [f'asetrate={int(rate * slow)}', f'aresample={SR}']
    if lowpass:
        af.append(f'lowpass=f={lowpass}')
    if extra:
        af.append(extra)
    cmd = ['ffmpeg', '-v', 'error', '-ss', str(start)]
    if dur:
        cmd += ['-t', str(dur)]
    cmd += ['-i', path, '-ac', '1', '-af', ','.join(af), '-f', 'f32le', '-']
    raw = subprocess.run(cmd, check=True, capture_output=True).stdout
    return list(struct.unpack('<%df' % (len(raw) // 4), raw))


def fade(x, a=0.01, b=0.05):
    na, nb = int(a * SR), int(b * SR)
    for k in range(min(na, len(x))):
        x[k] *= k / na
    for k in range(min(nb, len(x))):
        x[-1 - k] *= (k / nb) ** 1.5
    return x


def trim(x, thr=0.03):
    peak = max(abs(v) for v in x)
    i = next(i for i, v in enumerate(x) if abs(v) > peak * thr)
    j = len(x) - next(i for i, v in enumerate(reversed(x)) if abs(v) > peak * thr)
    return x[max(0, i - 100):j]


def loop(x, xf=2.0):
    """Sonun [xf] saniyesi başa bindirilir: dikişsiz döngü."""
    n = int(xf * SR)
    body = x[:len(x) - n]
    for k in range(n):
        a = k / n
        body[k] = body[k] * a + x[len(x) - n + k] * (1 - a)
    return body


def rms(x):
    return math.sqrt(sum(v * v for v in x) / max(1, len(x)))


def old_rms(name):
    path = os.path.join(OUT, name + '.wav')
    with wave.open(path) as w:
        n = w.getnframes()
        data = struct.unpack('<%dh' % (n * w.getnchannels()), w.readframes(n))
    return rms([v / 32768 for v in data])


def mix(*parts):
    """(örnekler, başlangıç sn, kazanç) parçalarını üst üste bindirir."""
    n = max(int(at * SR) + len(x) for x, at, _ in parts)
    out = [0.0] * n
    for x, at, g in parts:
        o = int(at * SR)
        for k, v in enumerate(x):
            out[o + k] += v * g
    return out


def save(name, data, level=None):
    target = level if level is not None else old_rms(name)
    gain = target / max(rms(data), 1e-9)
    peak = max(abs(v) for v in data) * gain
    if peak > 0.95:
        gain *= 0.95 / peak
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(max(-1, min(1, v * gain)) * 32767))
            for v in data))
    print(f'{name}.wav {len(data) / SR:.2f} sn')


# Kurt: tek uluma, yumuşak giriş, uzun sönüş.
save('howl', fade(load('wolf_howls.ogg', 8.6, 4.1), 0.25, 1.2))

# Karda adım: dördü de kısaltılır (adım sesi uzun sürmesin).
for i in range(1, 5):
    x = trim(load(f'snow_step_dry-0{i}.flac', lowpass=9000))
    save(f'step_snow_{i}', fade(x[:int(0.34 * SR)], 0.003, 0.08))

# Kalp: yavaş ve pes; altı tekrar ~8,4 sn, uçları sessiz (dikişsiz döngü).
beat = load('heartbeat_fast_0.wav', slow=0.8, lowpass=1800)
save('heartbeat', beat * 6)

# Gök gürültüsü: gürlemenin başından 9 sn; yağmur süzülür.
save('thunder', fade(load('rain-thunder.ogg', 20.9, 9.0, lowpass=2200),
                     0.03, 3.0))

# Yarasalar: üç çığlık, kısa aralıklarla; bir sürü havalanır.
b1 = load('bat_01.ogg')
b2 = load('bat_02.ogg')
b3 = load('bat_03.ogg')
save('bats', fade(mix((b1, 0, 1), (b3, 0.22, 0.8), (b2, 0.5, 0.6)), 0.005, 0.4))

# Kam'ın davulu: en güçlü tek vuruş, biraz daha pes ve derin.
save('drum', fade(load('frame_drum.flac', 0.42, 0.95, slow=0.88), 0.002, 0.3))

# Hırlama: iki ayı hırıltısı, pes; biri öbürünün sönüşüne biner.
g1 = load('bear_02.ogg', slow=0.82)
g2 = load('bear_01.ogg', slow=0.78)
save('growl', fade(mix((g1, 0, 1), (g2, 1.15, 0.85)), 0.01, 0.4))

# Zincir: vinç zinciri şıkırtısı.
save('chain', fade(load('winch - Marker #9.wav', 0, 2.6), 0.01, 0.3))

# Taş taşa sürtünür.
save('grind', fade(trim(load('stone_door.ogg')), 0.01, 0.25))

# Nefes: karanlıkta bir içe çekiş, ağır bir veriş.
save('breath', fade(load('breathing_man.ogg', 6.5, 2.9, lowpass=6000),
                    0.3, 0.5))

# Karlı rüzgâr: uğuldayan, kesintisiz.
save('amb_snow', loop(load('howling_wind.ogg', 64, 26), 2.0))

# Mağara: damlalar; ani vuruşlar sıkıştırılır.
save('amb_cave', loop(load(
    'atmosbasement.mp3_.flac', 0, 20,
    extra='acompressor=threshold=-24dB:ratio=8:attack=3:release=250'), 2.0))
