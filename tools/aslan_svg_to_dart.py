"""PhyloPic'teki kamu malı (CC0) potrace siluetleri → MythShapes'in
kodlamasına (0 moveTo, 1 lineTo, 2 cubicTo, 3 close; ayakların ortası (0, 0),
boy 100 birim, baş sağa). Kullanılanlar:
- lion: Margot Michaud, dd7c7bc6-2c6d-48e4-860b-02bf37886b5b
- rabbit (aynalı): Ferran Sayol, ad7d2a9d-ef0d-46f2-895d-7c67bb8e6355
- fox: Ferran Sayol, 9b3e3567-2238-40bf-ab5d-bcb6ce7b32d5
- deer: Ferran Sayol, cc03f5c2-933f-4c40-9c64-7f8727556fdb

    python3 -I tools/aslan_svg_to_dart.py <vector.svg> [ad] [aynala]

Çıktıyı lib/game/myth_shapes.dart'a yapıştırın.
"""
import re
import sys

s = open(sys.argv[1]).read()
NAME = sys.argv[2] if len(sys.argv) > 2 else 'lion'
FLIP = len(sys.argv) > 3 and sys.argv[3] == 'aynala'
tr = re.search(r'translate\(([-0-9.]+),([-0-9.]+)\)\s*scale\(([-0-9.]+),([-0-9.]+)\)', s)
TX, TY, SX, SY = (float(v) for v in tr.groups())
d = ' '.join(m for m in re.findall(r'<path d="([^"]*)"', s, re.S))
toks = re.findall(r'[a-zA-Z]|-?[0-9.]+(?:e-?[0-9]+)?', d)
i = 0
cmd = None
x = y = sx = sy = 0.0
segs = []


def num():
    global i
    v = float(toks[i])
    i += 1
    return v


while i < len(toks):
    if re.match(r'[a-zA-Z]', toks[i]):
        cmd = toks[i]
        i += 1
        if cmd in 'zZ':
            segs.append(('Z',))
            x, y = sx, sy
            continue
    rel = cmd.islower()
    c = cmd.lower()
    if c == 'm':
        nx, ny = num(), num()
        if rel:
            nx += x
            ny += y
        x, y = nx, ny
        sx, sy = x, y
        segs.append(('M', x, y))
        cmd = 'l' if rel else 'L'
    elif c == 'l':
        nx, ny = num(), num()
        if rel:
            nx += x
            ny += y
        x, y = nx, ny
        segs.append(('L', x, y))
    elif c == 'c':
        p = [num() for _ in range(6)]
        if rel:
            p = [p[0] + x, p[1] + y, p[2] + x, p[3] + y, p[4] + x, p[5] + y]
        segs.append(('C', *p))
        x, y = p[4], p[5]
    else:
        raise SystemExit(f'desteklenmeyen komut: {cmd}')


def T(px, py):
    return TX + SX * px, TY + SY * py


pts = []
out = []
for sg in segs:
    if sg[0] == 'Z':
        out.append(('Z',))
        continue
    q = [T(sg[k], sg[k + 1]) for k in range(1, len(sg), 2)]
    pts += q
    out.append((sg[0], q))
x0 = min(p[0] for p in pts)
x1 = max(p[0] for p in pts)
y0 = min(p[1] for p in pts)
y1 = max(p[1] for p in pts)
k = 100 / (y1 - y0)
cx = (x0 + x1) / 2


def f(p):
    x = (p[0] - cx) * k
    return [round(-x if FLIP else x, 2), round((p[1] - y1) * k, 2)]


data = []
for sg in out:
    if sg[0] == 'Z':
        data.append(3)
    else:
        data.append({'M': 0, 'L': 1, 'C': 2}[sg[0]])
        for p in sg[1]:
            data += f(p)
w = (x1 - x0) * k
print(f'  // {NAME}: {sum(1 for s in out)} komut, {w:.1f}x100.0 birim')
print(f'  static final Path {NAME} = _decode(const <double>[')
line = '    '
for v in data:
    t = (str(v) if isinstance(v, int) else (f'{v:g}' if v != int(v) else f'{int(v)}')) + ', '
    if len(line) + len(t) > 100:
        print(line.rstrip())
        line = '    '
    line += t
print(line.rstrip())
print('  ]);')
