"""Gerçek kayıtlı CC0 sesleri oyuna uyarlar.

Kaynaklar (hepsi CC0 1.0, kamu malı):
- Kenney "Impact Sounds" ve "RPG Audio" (kenney.nl)
- OpenGameArt: "40 CC0 water / splash / slime SFX" (rubberduck),
  "Loopable Dungeon Ambience" (JaggedStone), "Fire Crackling"
  (AntumDeluge), "wind whoosh loop" (SketchMan3)

Kullanım: python3 -I tools/import_cc0.py <kaynak_klasörü> <assets/audio>
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


def load(name):
    """ffmpeg ile 44,1 kHz tek kanal kayan noktalı örneklere çevirir."""
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', find(name), '-ac', '1', '-ar', str(SR),
         '-f', 'f32le', '-'], check=True, capture_output=True).stdout
    return list(struct.unpack('<%df' % (len(raw) // 4), raw))


def n(sec):
    return int(sec * SR)


def mix(*parts):
    """(veri, başlangıç_sn, kazanç) parçalarını üst üste koyar."""
    length = max(n(at) + len(d) for d, at, _ in parts)
    out = [0.0] * length
    for d, at, g in parts:
        s = n(at)
        for i, x in enumerate(d):
            out[s + i] += x * g
    return out


def trim(d, start, length):
    return d[n(start):n(start) + n(length)]


def fade(d, fin=0.002, fout=0.03):
    a, b = n(fin), min(n(fout), len(d) // 3)
    L = len(d)
    return [x * (i / a if a and i < a else 1.0) * ((L - i) / b if i > L - b else 1.0)
            for i, x in enumerate(d)]


def silence_trim(d, floor=0.001):
    """Baştaki ve sondaki sessizliği atar."""
    peak = max(abs(x) for x in d) or 1
    s = 0
    while s < len(d) and abs(d[s]) < peak * floor:
        s += 1
    e = len(d)
    while e > s and abs(d[e - 1]) < peak * floor:
        e -= 1
    return d[max(0, s - 32):e]


def loop(d, xfade):
    """Sonu başına çapraz geçişle bağlar: dikişsiz döngü."""
    f = n(xfade)
    body, tail = d[:-f], d[-f:]
    for i in range(f):
        t = i / f
        body[i] = body[i] * math.sqrt(t) + tail[i] * math.sqrt(1 - t)
    return body


def save(name, d, peak):
    m = max(abs(x) for x in d) or 1
    k = peak / m
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x * k)) * 32000)) for x in d))
    print(f'{name:14s} {len(d) / SR:5.2f} sn')


one = lambda name: fade(silence_trim(load(name)))

# Adımlar: taş, tahta, kar.
for i in range(4):
    save(f'step_{i + 1}', one(f'footstep_concrete_00{i}.ogg'), 0.45)
    save(f'step_snow_{i + 1}', one(f'footstep_snow_00{i}.ogg'), 0.45)
for i in range(3):
    save(f'step_wood_{i + 1}', one(f'footstep_wood_00{i}.ogg'), 0.45)

save('land', one('impactSoft_heavy_001.ogg'), 0.55)
save('jump', one('cloth1.ogg'), 0.3)
save('glide', one('cloth4.ogg'), 0.3)
save('creak', one('creak1.ogg'), 0.3)
save('lever', one('metalLatch.ogg'), 0.6)
save('gate', one('doorOpen_2.ogg'), 0.5)
save('crumble', fade(mix((silence_trim(load('impactMining_002.ogg')), 0, 1.0),
                         (silence_trim(load('impactMining_004.ogg')), 0.12, 0.8))), 0.6)
save('splash', one('splash_03.ogg'), 0.5)
save('shatter', fade(mix((silence_trim(load('impactGlass_heavy_000.ogg')), 0, 1.0),
                         (silence_trim(load('impactGlass_light_002.ogg')), 0.13, 0.6),
                         (silence_trim(load('impactGlass_light_004.ogg')), 0.27, 0.45))), 0.7)
save('bell', one('impactBell_heavy_000.ogg'), 0.6)
# Ateş: alevin süresi kadar (1,3 sn) gerçek çıtırtı, kısa bir kuyrukla.
save('fire', fade(trim(load('fire-1.wav'), 0.2, 1.6), 0.08, 0.35), 0.55)
# Ortamlar: döngüler.
save('amb_cistern', loop(trim(load('dungeon_ambient_1.ogg'), 10, 33), 3), 0.5)
wind = load('wind_woosh_loop.ogg')
save('amb_wind', wind, 0.5)
save('gust', fade(trim(wind, 0.5, 3.0), 0.6, 1.2), 0.6)
