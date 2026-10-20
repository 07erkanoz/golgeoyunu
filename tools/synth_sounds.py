"""Gölge Oyunu için sentez sesler: saf Python ile, dış kaynak kullanmadan."""
import math, random, struct, sys, wave, os

SR = 22050
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)
rnd = random.Random(1660)


def save(name, data, gain=0.9):
    peak = max(1e-9, max(abs(x) for x in data))
    k = gain / peak
    with wave.open(os.path.join(OUT, name + '.wav'), 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, x * k)) * 32000)) for x in data))


def n(sec):
    return int(sec * SR)


def lowpass(data, cutoff):
    a = 1 - math.exp(-2 * math.pi * cutoff / SR)
    y, out = 0.0, []
    for x in data:
        y += a * (x - y)
        out.append(y)
    return out


def highpass(data, cutoff):
    low = lowpass(data, cutoff)
    return [x - l for x, l in zip(data, low)]


def bandpass(data, lo, hi):
    return lowpass(highpass(data, lo), hi)


def noise(sec):
    return [rnd.uniform(-1, 1) for _ in range(n(sec))]


def brown(sec):
    y, out = 0.0, []
    for _ in range(n(sec)):
        y = (y + rnd.uniform(-1, 1) * 0.02) * 0.998
        out.append(y)
    return out


def env(data, attack, release, curve=2.0):
    total = len(data)
    a, r = n(attack), n(release)
    out = []
    for i, x in enumerate(data):
        g = 1.0
        if a and i < a:
            g = i / a
        if r and i > total - r:
            g *= ((total - i) / r) ** curve
        out.append(x * g)
    return out


def decay(data, tau):
    return [x * math.exp(-i / SR / tau) for i, x in enumerate(data)]


def sine(freq, sec, phase=0.0, vib=0.0, vib_rate=5.0):
    out, ph = [], phase
    for i in range(n(sec)):
        f = freq(i / SR) if callable(freq) else freq
        f *= 1 + vib * math.sin(2 * math.pi * vib_rate * i / SR)
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph))
    return out


def saw(freq, sec):
    out, ph = [], 0.0
    for i in range(n(sec)):
        f = freq(i / SR) if callable(freq) else freq
        ph = (ph + f / SR) % 1.0
        out.append(2 * ph - 1)
    return out


def mix(*tracks):
    length = max(len(t) for t, _ in tracks)
    out = [0.0] * length
    for t, g in tracks:
        for i, x in enumerate(t):
            out[i] += x * g
    return out


def place(base, clip, at, gain=1.0):
    s = n(at)
    for i, x in enumerate(clip):
        if s + i < len(base):
            base[s + i] += x * gain


def echo(data, delay, fb, mixg=0.5):
    d = n(delay)
    out = list(data) + [0.0] * (d * 6)
    for i in range(d, len(out)):
        out[i] += out[i - d] * fb
    return [x * mixg + (data[i] if i < len(data) else 0) * (1 - mixg) for i, x in enumerate(out)]


def loop(data, fade):
    """Sonu başına çapraz geçişle bağlar: dikişsiz döngü."""
    f = n(fade)
    body = data[:-f]
    tail = data[-f:]
    for i in range(f):
        t = i / f
        body[i] = body[i] * t + tail[i] * (1 - t)
    return body


def drip():
    return decay(sine(lambda t: 1500 - 900 * min(1, t / 0.05), 0.12), 0.03)


# ----------------------------------------------------------------- ortamlar
L = 24
drone = mix(
    (sine(55, L + 2, vib=0.004, vib_rate=0.1), 0.5),
    (sine(82.4, L + 2, vib=0.003, vib_rate=0.13), 0.3),
    (sine(110.3, L + 2, vib=0.003, vib_rate=0.07), 0.15),
    (lowpass(brown(L + 2), 160), 1.2),
)
# Derin, sakin bir uğultu: kabarıp sönen gürültü hışırtı gibi duyuluyordu.
drone = [x * (0.9 + 0.1 * math.sin(2 * math.pi * i / SR / 6.5)) for i, x in enumerate(drone)]
t = 0.8
while t < L:
    place(drone, echo(drip(), 0.23, 0.45), t, 0.35 * rnd.uniform(0.5, 1))
    t += rnd.uniform(1.1, 3.2)
save('amb_cistern', loop(drone, 2), 0.5)

gust_noise = noise(L + 2)
wind, y = [], 0.0
for i, x in enumerate(gust_noise):
    s = i / SR
    cutoff = 250 + 500 * (0.5 + 0.5 * math.sin(2 * math.pi * s / 7.3) * math.sin(2 * math.pi * s / 3.1))
    a = 1 - math.exp(-2 * math.pi * cutoff / SR)
    y += a * (x - y)
    wind.append(y * (0.6 + 0.4 * math.sin(2 * math.pi * s / 5.7)))
wind = mix((wind, 2.5), (sine(73.4, L + 2, vib=0.005, vib_rate=0.09), 0.18))
save('amb_wind', loop(wind, 2), 0.5)

air = bandpass(noise(L + 2), 800, 3000)
air = [x * (0.5 + 0.5 * math.sin(2 * math.pi * i / SR / 9)) for i, x in enumerate(air)]
pad = mix(
    (sine(220, L + 2, vib=0.004, vib_rate=0.2), 0.25),
    (sine(261.6, L + 2, vib=0.004, vib_rate=0.17), 0.18),
    (sine(329.6, L + 2, vib=0.004, vib_rate=0.23), 0.15),
    (air, 0.9),
)
pad = [x * (0.7 + 0.3 * math.sin(2 * math.pi * i / SR / 12)) for i, x in enumerate(pad)]
save('amb_sky', loop(pad, 2), 0.45)

rumble = mix(
    (lowpass(brown(8), 120), 10.0),
    (sine(38, 8, vib=0.05, vib_rate=0.7), 0.6),
    (bandpass(noise(8), 200, 600), 0.25),
)
rumble = [x * (0.6 + 0.4 * math.sin(2 * math.pi * i / SR / 1.6)) for i, x in enumerate(rumble)]
save('karabasan', loop(rumble, 1), 0.85)

# ------------------------------------------------------------------ efektler
# Adımlar: sürtünme değil, yumuşak tabanlı küçük bir ayağın "pat" sesi.
# Bir tık (geçiş anı), alçak bir topuk vuruşu ve kısa bir gövde tınısı.
def footstep(pitch, bright, body):
    click = decay(lowpass(noise(0.012), bright), 0.002)
    heel = decay(sine(lambda t: pitch * (1.0 - 0.35 * min(1, t / 0.03)), 0.09), 0.022)
    tone = decay(bandpass(noise(0.06), 250, 700), 0.012)
    out = mix((click, 0.55), (heel, 1.0), (tone, body))
    return env(out, 0.0005, 0.03)


for i, (pitch, bright, body) in enumerate(((128, 2600, 0.35), (112, 2200, 0.3), (142, 3000, 0.4), (120, 2400, 0.32))):
    save(f'step_{i + 1}', footstep(pitch, bright, body), 0.45)


# Tahta iskele: oyuk, tok bir vuruş.
def woodstep(pitch):
    knock = mix(
        (decay(sine(pitch, 0.14), 0.04), 1.0),
        (decay(sine(pitch * 2.37, 0.14), 0.02), 0.35),
        (decay(lowpass(noise(0.01), 3000), 0.002), 0.5),
    )
    return env(knock, 0.0005, 0.06)


for i, pitch in enumerate((190, 172, 208)):
    save(f'step_wood_{i + 1}', woodstep(pitch), 0.45)

# Zıplama: hafif bir nefes ve kumaş hışırtısı.
save('jump', mix(
    (env(bandpass(noise(0.11), 250, 900), 0.015, 0.08), 0.8),
    (decay(sine(lambda t: 180 + 120 * t, 0.08), 0.03), 0.25),
), 0.3)
# İniş: alçak bir gümleme ve küçük bir toz.
save('land', mix(
    (decay(sine(lambda t: 85 * (1 - 0.4 * min(1, t / 0.06)), 0.2), 0.045), 1.0),
    (decay(lowpass(noise(0.015), 2000), 0.004), 0.45),
    (env(lowpass(noise(0.12), 500), 0.005, 0.1), 0.25),
), 0.55)
chime = mix(*[(decay(sine(f, 1.0, vib=0.003, vib_rate=6), d), g)
              for f, d, g in ((1318, 0.35, 0.5), (1760, 0.25, 0.35), (2637, 0.18, 0.2))])
save('firefly', echo(chime, 0.12, 0.3, 0.3), 0.45)
pick = [0.0] * n(0.6)
for k, f in enumerate((880, 1174.7, 1568)):
    place(pick, decay(sine(f, 0.4), 0.12), k * 0.07, 0.6)
save('pickup', pick, 0.45)
bell = mix(*[(decay(sine(f, 2.2), d), g) for f, d, g in
             ((660, 0.9, 0.6), (1320 * 1.01, 0.5, 0.25), (1980 * 0.99, 0.3, 0.12), (495, 1.1, 0.25))])
save('memory', echo(bell, 0.21, 0.35, 0.35), 0.55)
save('suspect', env(lowpass(mix((saw(lambda t: 147 + 6 * t, 0.7), 0.6), (sine(147, 0.7), 0.4)), 600), 0.12, 0.35), 0.45)
save('alert', env(lowpass(mix((saw(110, 0.8), 0.5), (saw(116.5, 0.8), 0.5), (saw(220, 0.8), 0.2)), 1400), 0.02, 0.5), 0.55)
bats = [x * (0.5 + 0.5 * math.sin(2 * math.pi * 28 * i / SR)) for i, x in enumerate(bandpass(noise(1.4), 300, 2000))]
bats = env(bats, 0.02, 0.6)
tt = 0.0
while tt < 1.2:
    place(bats, decay(sine(lambda q, f0=rnd.uniform(3200, 5200): f0 - 2000 * q, 0.07), 0.02), tt, 0.5)
    tt += rnd.uniform(0.04, 0.13)
save('bats', bats, 0.5)
caw = [0.0] * n(0.75)
for at in (0.0, 0.32):
    c = saw(lambda q: 640 - 260 * q / 0.25, 0.25)
    c = bandpass(c, 500, 1800)
    place(caw, env(c, 0.01, 0.15), at, 1.0)
save('crow', caw, 0.5)
save('lever', mix(
    (decay(sine(85, 0.3), 0.06), 1.0),
    (decay(sine(910, 0.5, vib=0.002, vib_rate=7), 0.12), 0.25),
    (env(lowpass(noise(0.08), 1200), 0.001, 0.07), 0.6),
), 0.6)
grind = [x * (0.6 + 0.4 * math.sin(2 * math.pi * 11 * i / SR)) for i, x in enumerate(bandpass(noise(1.7), 900, 2200))]
save('gate', env(mix((grind, 1.0), (sine(lambda q: 2100 + 120 * math.sin(q * 9), 1.7), 0.06)), 0.1, 0.5), 0.45)
save('crumble', env(mix(
    (lowpass(noise(0.7), 1600), 0.8),
    (lowpass(brown(0.7), 150), 8.0),
), 0.005, 0.5), 0.6)
save('death', env(mix(
    (sine(lambda q: 220 - 120 * q, 1.4), 0.4),
    (lowpass(brown(1.4), 200), 6.0),
), 0.2, 0.9), 0.55)
spl = env(highpass(noise(0.7), 600), 0.002, 0.6)
for k in range(6):
    place(spl, decay(sine(lambda q, f0=rnd.uniform(500, 900): f0 + 1200 * q, 0.08), 0.03), 0.1 + k * 0.07, 0.25)
save('splash', spl, 0.5)
save('throw', mix(
    (env(bandpass(noise(0.25), 1000, 4000), 0.02, 0.2), 0.6),
    (decay(sine(2093, 0.4), 0.1), 0.25),
), 0.4)
save('glide', env(bandpass(noise(0.5), 300, 1200), 0.15, 0.3), 0.3)
save('creak', env(sine(lambda q: 240 + 80 * q, 0.35, vib=0.04, vib_rate=25), 0.05, 0.2), 0.3)
print('ok', sorted(os.listdir(OUT)))


# ------------------------------------------------------------- perde: ney
# Perde sahnelerinde çalan ney: Hicaz makamında, nefesli, notalar arasında
# kayarak geçen ağır bir taksim ve altında hafif bir dem.
def ney_taksim():
    D = 293.66
    hz = {'D': D, 'Eb': D * 1.0593, 'F#': D * 1.26, 'G': D * 1.335, 'A': D * 1.5,
          'Bb': D * 1.5874, 'C': D * 1.7818, 'D2': D * 2, 'C3': D * 0.8909, 'A3': D * 0.75}
    # (nota, süre sn); None = nefes arası
    phrase = [('A', 2.6), ('Bb', 1.0), ('A', 1.6), ('G', 1.0), ('F#', 2.4), (None, 1.0),
              ('D', 1.2), ('Eb', 0.8), ('F#', 1.0), ('G', 1.4), ('A', 3.2), (None, 1.2),
              ('C', 1.4), ('Bb', 1.0), ('A', 1.0), ('G', 0.8), ('F#', 1.2), ('Eb', 1.6), ('D', 3.6), (None, 2.0)]
    total = sum(d for _, d in phrase)
    N = n(total)
    out = [0.0] * N
    breath = bandpass(noise(total), 500, 2600)
    ph = 0.0
    f_prev = hz['A']
    i = 0
    for note, dur in phrase:
        m = n(dur)
        if note is None:
            i += m
            continue
        f_to = hz[note]
        for k in range(m):
            if i >= N:
                break
            t = k / SR
            # Notaya kayarak varış (ney'in glissandosu).
            slide = min(1.0, t / 0.18)
            f = f_prev + (f_to - f_prev) * (slide * slide * (3 - 2 * slide))
            vib = 1 + 0.006 * min(1.0, t / 0.9) * math.sin(2 * math.pi * 5.2 * t)
            ph += 2 * math.pi * f * vib / SR
            att = min(1.0, t / 0.22)
            rel = min(1.0, (dur - t) / 0.3)
            a = att * rel * (0.85 + 0.15 * math.sin(2 * math.pi * 0.7 * t))
            tone = math.sin(ph) + 0.22 * math.sin(2 * ph) + 0.1 * math.sin(3 * ph)
            out[i] = a * (tone * 0.75 + breath[i] * 1.6 * (0.4 + 0.6 * (1 - att)))
            i += 1
        f_prev = f_to
    # Hafif oda yankısı ve dem.
    wet = echo(out, 0.19, 0.42, 0.45)[:N]
    dem = mix((sine(hz['D'] / 2, total + 0.1, vib=0.002, vib_rate=0.2), 0.12),
              (lowpass(brown(total + 0.1), 250), 1.5))
    return mix((wet, 1.0), (dem, 1.0))


save('perde_ney', loop(ney_taksim(), 2), 0.6)


# ------------------------------------------------------------- gerilim
def thump(f0, sec, tau):
    return decay(sine(lambda t: f0 * (1 + 0.6 * math.exp(-t / 0.02)), sec), tau)


def heartbeat_loop():
    total = 8.0
    out = [0.0] * n(total)
    t = 0.0
    while t < total - 0.5:
        place(out, lowpass(thump(52, 0.3, 0.07), 220), t, 1.0)
        place(out, lowpass(thump(46, 0.3, 0.06), 200), t + 0.26, 0.7)
        t += 1.0
    return out


def murmur_loop():
    # Uzaktan duyulan, anlaşılmayan bir dua: kapalı ağızla mırıldanan alçak
    # bir ilahi (hicaz dizisinden notalar), aralarda sessizlik.
    total = 12.0
    out = [0.0] * n(total)
    r = random.Random(7)
    scale = [110.0, 116.5, 138.6, 146.8, 164.8, 174.6]
    t = 0.4
    while t < total - 2.0:
        phrase = r.randint(3, 5)
        for _ in range(phrase):
            d = 0.6 + 0.7 * r.random()
            f = r.choice(scale)
            tone = mix(
                (sine(f, d, vib=0.006, vib_rate=4.5), 1.0),
                (sine(f * 2, d, vib=0.006, vib_rate=4.5), 0.25),
                (sine(f * 3, d, vib=0.006, vib_rate=4.5), 0.08),
            )
            place(out, env(tone, 0.18, 0.3), t, 1.0)
            t += d * 0.85
        t += 1.2 + r.random() * 1.5
    wet = echo(out, 0.31, 0.4, 0.5)[:len(out)]
    return lowpass(wet, 700)


def shatter():
    out = [0.0] * n(1.4)
    r = random.Random(11)
    for i in range(16):
        f = 2400 + r.random() * 5200
        at = r.random() * 0.25 * (i / 16) ** 0.5
        place(out, decay(sine(f, 0.8), 0.06 + r.random() * 0.2), at, 0.25 + r.random() * 0.3)
    place(out, decay(highpass(noise(0.4), 2500), 0.05), 0, 1.5)
    return echo(out, 0.11, 0.3, 0.3)


def breath():
    # Karanlıkta ağır, derin bir nefes: içe çekiş ve uzun bir veriş.
    inn = env(bandpass(noise(1.1), 200, 900), 0.6, 0.4)
    out_ = env(bandpass(noise(1.6), 120, 600), 0.2, 1.1)
    rumble = env(lowpass(brown(2.8), 120), 0.5, 1.0)
    total = [0.0] * n(3.0)
    place(total, inn, 0.0, 0.8)
    place(total, out_, 1.2, 1.0)
    place(total, rumble, 0.0, 6.0)
    return total


def fizzle():
    return env(mix((decay(sine(lambda t: 1800 - 1400 * min(1, t / 0.35), 0.5), 0.18), 0.5),
                   (decay(bandpass(noise(0.5), 1500, 5000), 0.12), 0.6)), 0.005, 0.2)


def chain():
    out = [0.0] * n(2.2)
    r = random.Random(5)
    t = 0.0
    for _ in range(7):
        f = 1300 + r.random() * 900
        clink = mix((decay(sine(f, 0.4), 0.09), 0.6), (decay(sine(f * 2.76, 0.3), 0.05), 0.3),
                    (decay(bandpass(noise(0.05), 2000, 6000), 0.01), 0.5))
        place(out, clink, t, 0.6 + r.random() * 0.4)
        t += 0.08 + r.random() * 0.22
    return lowpass(echo(out, 0.27, 0.5, 0.55), 3500)


save('heartbeat', heartbeat_loop(), 0.8)
save('murmur', loop(murmur_loop(), 1), 0.4)
save('shatter', shatter(), 0.7)
save('breath', breath(), 0.6)
save('fizzle', fizzle(), 0.4)
save('chain', chain(), 0.45)


# ------------------------------------------------------- doğu ortamları
def amb_snow():
    L = 24
    base = bandpass(noise(L + 2), 250, 1400)
    r = random.Random(21)
    gusts = [0.0] * len(base)
    for i in range(len(base)):
        t = i / SR
        gusts[i] = 0.45 + 0.35 * math.sin(2 * math.pi * t / 7.3) + 0.2 * math.sin(2 * math.pi * t / 3.1 + 1)
    wind = [x * g for x, g in zip(base, gusts)]
    out = mix((wind, 1.0), (lowpass(brown(L + 2), 200), 3.0))
    # Ara sıra ince bir ıslık.
    t = 2.0
    while t < L - 3:
        f0 = 700 + r.random() * 500
        whistle = env(sine(lambda q, f=f0: f * (1 + 0.15 * math.sin(q * 1.3)), 2.5, vib=0.01, vib_rate=4), 1.0, 1.2)
        place(out, whistle, t, 0.05)
        t += 4 + r.random() * 5
    return out


def amb_ark():
    L = 24
    out = mix((lowpass(brown(L + 2), 160), 4.0))
    r = random.Random(33)
    t = 0.5
    while t < L - 1:
        lap = env(lowpass(noise(0.6), 500), 0.15, 0.4)
        place(out, lap, t, 0.35)
        t += 0.9 + r.random() * 1.6
    t = 3.0
    while t < L - 1:
        f0 = 180 + r.random() * 120
        creak = env(sine(lambda q, f=f0: f + 60 * q, 0.6, vib=0.05, vib_rate=30), 0.1, 0.3)
        place(out, creak, t, 0.12)
        t += 4 + r.random() * 5
    t = 1.0
    while t < L - 1:
        place(out, drip(), t, 0.2)
        t += 1.5 + r.random() * 3
    return out


def amb_konya():
    # Uzaktan bir semâhane: kudümün ağır vuruşları ve ney'in uzun sesi.
    L = 24
    out = mix((sine(146.8, L + 2, vib=0.003, vib_rate=0.2), 0.08),
              (lowpass(brown(L + 2), 180), 2.0))
    t = 0.4
    beat = 0
    while t < L - 1:
        strong = beat % 4 == 0
        place(out, lowpass(thump(70 if strong else 95, 0.4, 0.09), 400), t, 0.5 if strong else 0.3)
        t += 0.75
        beat += 1
    ney = env(sine(lambda q: 293.66 * (1 + 0.004 * math.sin(q * 5)), 7.0), 2.0, 2.5)
    breath_ = env(bandpass(noise(7.0), 600, 2400), 2.0, 2.5)
    place(out, mix((ney, 0.25), (breath_, 0.05)), 6.0, 1.0)
    return lowpass(echo(out, 0.31, 0.4, 0.4), 2500)


save('amb_snow', loop(amb_snow(), 2), 0.5)
save('amb_ark', loop(amb_ark(), 2), 0.5)
save('amb_konya', loop(amb_konya(), 2), 0.5)


# ------------------------------------------------------------- dağ sesleri
def gust():
    n_ = noise(3.0)
    out = []
    for i, x in enumerate(bandpass(n_, 300, 2500)):
        t = i / SR
        out.append(x * math.sin(math.pi * min(1, t / 3.0)) ** 1.5)
    return out


def bell():
    # Bronz çan: uyumsuz kısmi sesler, uzun sönüm.
    f = 392
    parts = [(0.5, 0.6, 3.0), (1.0, 1.0, 2.2), (1.19, 0.5, 1.6), (1.5, 0.4, 1.2),
             (2.0, 0.35, 1.0), (2.74, 0.2, 0.6), (3.76, 0.12, 0.4)]
    tracks = [(decay(sine(f * k, 3.5), tau), g) for k, g, tau in parts]
    strike = decay(bandpass(noise(0.05), 1500, 5000), 0.01)
    return echo(mix(*tracks, (strike, 0.6)), 0.23, 0.35, 0.35)


save('gust', gust(), 0.6)
save('bell', bell(), 0.6)


# ------------------------------------------------------------- efsaneler
def grind():
    base = bandpass(noise(1.4), 80, 700)
    r = random.Random(4)
    out = []
    for i, x in enumerate(base):
        t = i / SR
        out.append(x * (0.6 + 0.4 * math.sin(t * 37 + math.sin(t * 7) * 3)))
    return env(mix((out, 1.0), (lowpass(brown(1.4), 120), 2.0)), 0.1, 0.5)


def fire():
    roar = env(bandpass(noise(1.3), 150, 1800), 0.05, 0.6)
    crackle = [0.0] * n(1.3)
    r = random.Random(8)
    for _ in range(25):
        place(crackle, decay(highpass(noise(0.03), 2000), 0.006), r.random() * 1.2, 0.5)
    return mix((roar, 1.0), (crackle, 0.6))


def thunder():
    crack = decay(highpass(noise(0.3), 800), 0.05)
    rumble = env(lowpass(brown(4.0), 160), 0.05, 3.0)
    out = mix((crack, 0.6), (rumble, 6.0))
    return echo(out, 0.4, 0.3, 0.3)


save('grind', grind(), 0.6)
save('fire', fire(), 0.55)
save('thunder', thunder(), 0.7)
