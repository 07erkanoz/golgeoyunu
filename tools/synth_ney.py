"""Perde sahnelerinin neyi: Hicaz makamında ağır bir taksim.

Eski sentezde sürekli ve yüksek geniş bantlı nefes gürültüsü, her notada
sıfıra inen kesik bir zarf ve kısa geri beslemeli bir yankı vardı; ses
hışırtılı ve titrek çıkıyordu. Burada:

- Notalar legato: aralarında kayarak geçilir (glissando), nefes bir cümle
  boyunca sürer; nota başlarında hafif bir eğilme (çarpma) olur.
- Ton: kök ses ağırlıklı, zayıf çift harmonikler (uçtan üflemeli kamış).
- Nefes: perdeye ayarlı dar bantlı gürültü (kök ve 2. harmonikte rezonans)
  neyin buğulu sesini verir; geniş bantlı hışırtı çok azdır, yalnızca nota
  başlarında biraz artar.
- Yankı: uzun kuyruklu yumuşak bir salon (Freeverb benzeri), titreme yok.

Kullanım: python3 tools/synth_ney.py assets/audio
"""
import math
import os
import random
import struct
import sys
import wave

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else '.'
rnd = random.Random(1660)


def n(sec):
    return int(sec * SR)


def _biquad(data, b0, b1, b2, a1, a2):
    x1 = x2 = y1 = y2 = 0.0
    out = []
    for x in data:
        y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2, x1, y2, y1 = x1, x, y1, y
        out.append(y)
    return out


def lowpass(data, cutoff):
    w = 2 * math.pi * cutoff / SR
    c, sn = math.cos(w), math.sin(w)
    al = sn / math.sqrt(2)
    a0 = 1 + al
    return _biquad(data, (1 - c) / 2 / a0, (1 - c) / a0, (1 - c) / 2 / a0,
                   -2 * c / a0, (1 - al) / a0)


def highpass(data, cutoff):
    w = 2 * math.pi * cutoff / SR
    c, sn = math.cos(w), math.sin(w)
    al = sn / math.sqrt(2)
    a0 = 1 + al
    return _biquad(data, (1 + c) / 2 / a0, -(1 + c) / a0, (1 + c) / 2 / a0,
                   -2 * c / a0, (1 - al) / a0)


def hall(data, wet, size=1.0):
    """Yumuşak salon yankısı: sekiz sönümlü tarak, dört tüm geçiren."""
    tail = n(2.6)
    src = list(data) + [0.0] * tail
    acc = [0.0] * len(src)
    for d in (1557, 1617, 1491, 1422, 1277, 1356, 1188, 1116):
        d = int(d * size)
        buf = [0.0] * d
        idx = 0
        store = 0.0
        for i, x in enumerate(src):
            y = buf[idx]
            store = y * 0.6 + store * 0.4          # tizler çabuk söner: sıcak kuyruk
            buf[idx] = x * 0.015 + store * 0.84
            idx += 1
            if idx == d:
                idx = 0
            acc[i] += y
    for d in (556, 441, 341, 225):
        buf = [0.0] * d
        idx = 0
        for i, x in enumerate(acc):
            b = buf[idx]
            acc[i] = -x + b
            buf[idx] = x + b * 0.5
            idx += 1
            if idx == d:
                idx = 0
    return [x * (1 - wet) + a * wet for x, a in zip(src, acc)]


def smooth(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


D = 293.66
# Hicaz dizisi (Re karar).
HICAZ = {'D': D, 'Eb': D * 1.0593, 'F#': D * 1.2599, 'G': D * 1.3348,
         'A': D * 1.4983, 'Bb': D * 1.5874, 'C': D * 1.7818, 'D2': D * 2}
# Nefes cümleleri: her biri tek nefeste, notalar birbirine bağlı.
PERDE_PHRASES = [
    [('A', 2.4), ('Bb', 0.9), ('A', 1.5), ('G', 0.9), ('F#', 2.6)],
    [('D', 1.1), ('Eb', 0.8), ('F#', 1.0), ('G', 1.3), ('A', 3.2)],
    [('C', 1.4), ('Bb', 0.9), ('A', 0.9), ('G', 0.8), ('F#', 1.1),
     ('Eb', 1.4), ('D', 3.4)],
]
PERDE_RESTS = [0.9, 1.1, 2.4]     # son nefes arası döngünün dikişi olur


def taksim(phrases=PERDE_PHRASES, rests=PERDE_RESTS, hz=HICAZ, with_dem=True,
           lead=0.3):
    """Kuru (yankısız) ney taksimi; [lead] sn sessizlikle başlar."""
    total = sum(sum(d for _, d in p) for p in phrases) + sum(rests) + lead
    N = n(total)
    out = [0.0] * N

    # Rezonatörler için önceden üretilmiş beyaz gürültü.
    white = [rnd.uniform(-1, 1) for _ in range(N)]
    # Geniş bantlı nefes: 1,8–6 kHz arası, çok az.
    air = lowpass(highpass(white, 1800), 6000)

    i = n(lead)
    ph = 0.0
    vib_ph = 0.0
    vib_rate = 5.0
    prev = None
    # Rezonatör durumları (kök ve 2. harmonik).
    r = [[0.0, 0.0, 0.0, 0.0], [0.0, 0.0, 0.0, 0.0]]
    coef = [(0.0, 0.0, 0.0, 0.0), (0.0, 0.0, 0.0, 0.0)]
    for p_idx, phrase in enumerate(phrases):
        plen = sum(d for _, d in phrase)
        P = n(plen)
        start = i
        # Cümlenin nefes eğrisi: giriş, ortada hafif kabarma, çıkış.
        notes = []
        t0 = 0.0
        for note, dur in phrase:
            notes.append((t0, dur, hz[note]))
            t0 += dur
        k_note = 0
        for k in range(P):
            if i >= N:
                break
            t = k / SR
            while k_note + 1 < len(notes) and t >= notes[k_note + 1][0]:
                k_note += 1
            nt0, ndur, f_to = notes[k_note]
            tn = t - nt0
            f_from = prev if k_note == 0 and prev is not None else (
                notes[k_note - 1][2] if k_note > 0 else f_to)
            # Kayarak varış; aşağıdan yaklaşan kısa bir eğilme.
            glide = smooth(tn / 0.12)
            f = f_from + (f_to - f_from) * glide
            bend = 1 - 0.012 * (1 - smooth(tn / 0.08)) if k_note > 0 else 1
            # Gecikmeli, yavaşça değişen vibrato.
            vib_rate += (rnd.uniform(4.6, 5.6) - vib_rate) * 0.00002
            vib_ph += 2 * math.pi * vib_rate / SR
            depth = 0.0038 * smooth((tn - 0.35) / 0.8)
            f *= bend * (1 + depth * math.sin(vib_ph))

            # Nefes zarfı.
            a_in = smooth(t / 0.28)
            a_out = smooth((plen - t) / 0.55)
            swell = 0.82 + 0.18 * math.sin(math.pi * t / plen)
            # Nota geçişlerinde hafif bir dil darbesi (sıfıra inmez).
            dip = 1 - 0.12 * (1 - smooth(tn / 0.07)) if k_note > 0 else 1
            amp = a_in * a_out * swell * dip

            ph += 2 * math.pi * f / SR
            if ph > 2 * math.pi:
                ph -= 2 * math.pi
            bright = 0.6 + 0.4 * swell
            tone = (math.sin(ph) + 0.24 * bright * math.sin(2 * ph)
                    + 0.13 * math.sin(3 * ph) + 0.05 * bright * math.sin(4 * ph)
                    + 0.025 * math.sin(5 * ph))

            # Perdeye ayarlı nefes: 32 örnekte bir katsayı güncellenir.
            if k % 32 == 0:
                for h in (0, 1):
                    w = 2 * math.pi * f * (h + 1) / SR
                    q = 22.0 if h == 0 else 16.0
                    al = math.sin(w) / (2 * q)
                    a0 = 1 + al
                    coef[h] = (al / a0, -al / a0, -2 * math.cos(w) / a0,
                               (1 - al) / a0)
            x = white[i]
            pitched = 0.0
            for h in (0, 1):
                b0, b2, a1, a2 = coef[h]
                s = r[h]
                y = b0 * x + b2 * s[1] - a1 * s[2] - a2 * s[3]
                s[1], s[0] = s[0], x
                s[3], s[2] = s[2], y
                pitched += y * (1.0 if h == 0 else 0.5)
            chiff = 1 - smooth(tn / 0.09) if k_note == 0 else 0.3 * (1 - smooth(tn / 0.06))
            out[i] = amp * (0.62 * tone + 0.9 * pitched
                            + air[i] * (0.035 + 0.12 * chiff * a_in))
            i += 1
        prev = notes[-1][2]
        i = start + P + n(rests[p_idx])

    # Çok hafif bir dem: Re ve La, nefes gibi kabarıp söner.
    dem = [0.0] * N
    for k in range(N if with_dem else 0):
        t = k / SR
        s = 0.5 + 0.5 * math.sin(2 * math.pi * t / total - math.pi / 2)
        dem[k] = 0.045 * (0.6 + 0.4 * s) * (
            math.sin(2 * math.pi * D / 2 * t) + 0.35 * math.sin(2 * math.pi * D * 0.75 * t))
    data = [a + b for a, b in zip(out, dem)]
    data = highpass(data, 70)
    data = lowpass(data, 8500)
    return data


def loop(data, fade):
    """Yankı kuyruğu başa bindirilir: dikişsiz döngü."""
    f = n(fade)
    body = data[:-f]
    tail = data[-f:]
    for i in range(f):
        body[i] += tail[i]
    return body


def save(name, data, gain, out_dir=None):
    peak = max(1e-9, max(abs(x) for x in data))
    k = gain / peak
    with wave.open(os.path.join(out_dir or OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(
            struct.pack('<h', int(math.tanh(x * k * 1.1) / math.tanh(1.1) * 32000))
            for x in data))


if __name__ == '__main__':
    dry = taksim()
    length = len(dry)
    wet = hall(dry, 0.32)
    # Kuyruğun döngünün başına binen kısmı: döngü uzunluğu kuru taksim kadar.
    data = loop(wet, len(wet) / SR - length / SR)
    save('perde_ney', data, 0.6)
    print(f'perde_ney {len(data) / SR:.2f} sn')
