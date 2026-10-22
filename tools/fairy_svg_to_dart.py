"""Peri bacası siluetini (Nevit Dilmen, "Cappadocia Fairy chimneys.svg",
Wikimedia Commons, CC BY-SA 3.0) oyunun okuduğu Dart verisine çevirir.

    python3 -I tools/fairy_svg_to_dart.py <svg> > lib/game/fairy_chimney_shapes.dart
    dart format lib/game/fairy_chimney_shapes.dart

Görünen koyu parçalar (#241f1c: üç gövde, üç şapka) ve pencereler (#e6e6e6)
alınır; sayfanın dışında kalan artık parçalar atılır.
"""
import re
import sys

TX, TY = 6.4113292, 499.9263  # katmanın kayması
W, H = 1419.7123, 1101.1859  # sayfa


def parse(d):
    toks = re.findall(r'[a-zA-Z]|-?[0-9.]+(?:e-?[0-9]+)?', d)
    i = 0
    cmd = None
    x = y = sx = sy = 0.0
    out = []

    def num():
        nonlocal i
        v = float(toks[i])
        i += 1
        return v

    while i < len(toks):
        if re.match(r'[a-zA-Z]', toks[i]):
            cmd = toks[i]
            i += 1
            if cmd in 'zZ':
                out.append(('Z',))
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
            out.append(('M', x, y))
            cmd = 'l' if rel else 'L'
        elif c == 'l':
            nx, ny = num(), num()
            if rel:
                nx += x
                ny += y
            x, y = nx, ny
            out.append(('L', x, y))
        elif c == 'c':
            p = [num() for _ in range(6)]
            if rel:
                p = [p[0] + x, p[1] + y, p[2] + x, p[3] + y, p[4] + x, p[5] + y]
            out.append(('C', *p))
            x, y = p[4], p[5]
        else:
            raise ValueError(f'desteklenmeyen komut: {cmd}')
    return out


def enc(segs):
    def f(v):
        return round(v / H, 5)

    out = []
    for sg in segs:
        if sg[0] == 'M':
            out += [0, f(sg[1] + TX), f(sg[2] + TY)]
        elif sg[0] == 'L':
            out += [1, f(sg[1] + TX), f(sg[2] + TY)]
        elif sg[0] == 'C':
            out += [2] + [f(sg[k] + (TX if k % 2 else TY)) for k in range(1, 7)]
        else:
            out += [3]
    return out


def main():
    s = open(sys.argv[1]).read()
    items = []
    for m in re.finditer(r'<path\b(.*?)/>', s, re.S):
        a = m.group(1)
        fill = re.search(r'fill:(#[0-9a-f]+)', a).group(1)
        if fill in ('#241f1c', '#e6e6e6'):
            items.append((fill, parse(re.search(r'\sd="([^"]*)"', a).group(1))))
    dark = [sg for f, sg in items if f == '#241f1c']
    print('''// Peri bacası silueti: "Cappadocia Fairy chimneys.svg", Nevit Dilmen,
// Wikimedia Commons, CC BY-SA 3.0
// (https://commons.wikimedia.org/wiki/File:Cappadocia_Fairy_chimneys.svg).
// Bu dosyadaki uyarlanmış çizim verisi de CC BY-SA 3.0 lisanslıdır.
//
// Yollar boyu 1 olacak biçimde ölçeklenmiştir (taban y ≈ 1). Kodlama:
// 0 x y = moveTo, 1 x y = lineTo, 2 x1 y1 x2 y2 x y = cubicTo, 3 = close.
// tools/fairy_svg_to_dart.py ile üretildi; elle değiştirmeyin.
''')
    print(f'const double fairyArtWidth = {round(W / H, 5)};\n')
    print('/// Gövdeler, şapkalar ve oyma pencereler (çizimdeki sırayla).')
    print('const fairyArtBodies = <List<double>>[')
    for sg in dark[:3]:
        print('  ' + repr(enc(sg)) + ',')
    print('];\nconst fairyArtCaps = <List<double>>[')
    for sg in dark[3:]:
        print('  ' + repr(enc(sg)) + ',')
    print('];\nconst fairyArtWindows = <List<double>>[')
    for f, sg in items:
        if f == '#e6e6e6':
            print('  ' + repr(enc(sg)) + ',')
    print('];')


main()
