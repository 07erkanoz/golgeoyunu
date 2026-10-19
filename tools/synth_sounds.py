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
    (lowpass(brown(L + 2), 300), 6.0),
)
drone = [x * (0.75 + 0.25 * math.sin(2 * math.pi * i / SR / 6.5)) for i, x in enumerate(drone)]
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
save('step', env(lowpass(noise(0.07), 900), 0.002, 0.06), 0.5)
save('step_wood', mix(
    (env(lowpass(noise(0.09), 600), 0.002, 0.08), 1.0),
    (decay(sine(lambda t: 310 + 40 * math.sin(t * 90), 0.14, vib=0.02, vib_rate=30), 0.05), 0.35),
), 0.55)
save('jump', env(bandpass(noise(0.16), 400, 2500), 0.03, 0.12), 0.35)
save('land', mix(
    (decay(sine(lambda t: 90 - 40 * t, 0.18), 0.05), 1.0),
    (env(lowpass(noise(0.1), 700), 0.001, 0.09), 0.6),
), 0.6)
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
