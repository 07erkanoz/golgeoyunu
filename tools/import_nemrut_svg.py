"""Nemrut SVG paketini oyuna uyarlar (kullanıcının verdiği çizimler).

Girdi: Nemrut_SVG_Paketi klasörü (nemrut_stone_giant.svg, nemrut_zeus_head.svg,
nemrut_eagle_head.svg). Çıktı:
- assets/images/nemrut/*.png: Zeus başı (karlı), kartal başı, taş devin
  her uzvu ayrı (kırpılmış).
- lib/game/nemrut_sprites.dart: her parçanın SVG koordinatındaki sol üst
  köşesi ve boyutu (oyun, parçayı rig.json'daki dönüş noktası etrafında
  çevirerek yerleştirir).

Devin `rim-light` katmanı (sabit kenar ışığı çizgileri) uzuvlar hareket
edince kayacağı için alınmaz.

Lisans: kartal, Antiochos, Kommagene, Apollon, Herakles ve aslan başları
Wikimedia Commons fotoğraflarından (Vincent Vega, Dosseman, Bernard Gagnon,
Carole Raddato) türetilmiş çizimlerdir: CC BY-SA 4.0. Atıflar
docs/NEMRUT_CIZIMLER.md'de, kısaca Hakkında'da. Zeus başı ve taş dev özgün
çizimdir.

Kullanım: python3 -I tools/import_nemrut_svg.py <paket_klasörü> <proje_kökü>
Gerekenler: rsvg-convert, magick.
"""
import os
import re
import subprocess
import sys
import tempfile

SRC, ROOT = sys.argv[1], sys.argv[2]
OUT = os.path.join(ROOT, 'assets/images/nemrut')
os.makedirs(OUT, exist_ok=True)

# Devin parçaları çizim sırasıyla (SVG belge sırası).
GIANT_PARTS = [
    'leg-back', 'shin-back', 'foot-back', 'arm-back', 'forearm-back',
    'hand-back', 'pelvis', 'leg-front', 'shin-front', 'foot-front', 'torso',
    'chest-carving', 'head', 'arm-front', 'shoulder-front', 'shoulder-back',
    'forearm-front', 'hand-front',
]
GIANT_SCALE = 1.0
HEAD_SCALE = 0.8


def top_groups(svg):
    """Kök düzeyindeki <g id=...> gruplarının (başlangıç, bitiş) aralıkları."""
    start = svg.index('>', svg.index('<svg')) + 1
    out = {}
    depth = 0
    cur = None
    for m in re.finditer(r'<(/?)g\b([^>]*)>', svg[start:]):
        if m.group(1) == '':
            if depth == 0:
                idm = re.search(r'id="([^"]+)"', m.group(2))
                cur = (idm.group(1) if idm else None, start + m.start())
            depth += 1
        else:
            depth -= 1
            if depth == 0 and cur:
                out[cur[0]] = (cur[1], start + m.end())
    return out


def render(svg_text, scale, name):
    """SVG'yi sayfa boyutunda çizer, saydam kenarları kırpar; (x, y, w, h)
    SVG birimiyle döner."""
    with tempfile.TemporaryDirectory() as tmp:
        src = os.path.join(tmp, 'in.svg')
        full = os.path.join(tmp, 'full.png')
        with open(src, 'w') as f:
            f.write(svg_text)
        subprocess.run(['rsvg-convert', '-z', str(scale), '-o', full, src],
                       check=True)
        info = subprocess.run(
            ['magick', 'identify', '-format', '%@', full],
            check=True, capture_output=True, text=True).stdout.strip()
        w, h, x, y = map(int, re.match(r'(\d+)x(\d+)\+(\d+)\+(\d+)', info)
                         .groups())
        # Kenarda süzme için 2 piksel pay.
        x, y = max(0, x - 2), max(0, y - 2)
        w, h = w + 4, h + 4
        dst = os.path.join(OUT, name + '.png')
        subprocess.run(['magick', full, '-crop', f'{w}x{h}+{x}+{y}', '+repage',
                        '-strip', dst], check=True)
    return (x / scale, y / scale, w / scale, h / scale)


def only(svg, groups, keep):
    """Yalnızca [keep] gruplarını bırakır."""
    parts = []
    last = 0
    for gid, (a, b) in sorted(groups.items(), key=lambda kv: kv[1][0]):
        parts.append(svg[last:a])
        if gid in keep:
            parts.append(svg[a:b])
        last = b
    parts.append(svg[last:])
    return ''.join(parts)


def find(name):
    for root, _, files in os.walk(SRC):
        if name in files:
            return os.path.join(root, name)
    raise SystemExit(f'bulunamadı: {name}')


boxes = {}
giant = open(find('nemrut_stone_giant.svg')).read()
groups = top_groups(giant)
for part in GIANT_PARTS:
    boxes['giant_' + part.replace('-', '_')] = render(
        only(giant, groups, {part}), GIANT_SCALE,
        'giant_' + part.replace('-', '_'))

# Dev başlar ve koruyucular (hepsi 540 genişlik viewBox).
for name in ['zeus', 'antiochos', 'kommagene', 'apollon', 'herakles',
             'eagle', 'lion']:
    svg = open(find(f'nemrut_{name}_head.svg')).read()
    # Karlı dağ: başlığın üstündeki kar görünsün.
    svg = svg.replace('<g id="snow" opacity="0">', '<g id="snow">')
    boxes[f'{name}_head'] = render(svg, HEAD_SCALE, f'{name}_head')

lines = [
    '// tools/import_nemrut_svg.py tarafından üretildi; elle değiştirmeyin.',
    '// Her parça: SVG koordinatında sol üst köşe ve boyut.',
    "import 'dart:ui';",
    '',
    'const nemrutSprites = <String, Rect>{',
]
for k, (x, y, w, h) in boxes.items():
    lines.append(f"  '{k}': Rect.fromLTWH({x:.1f}, {y:.1f}, {w:.1f}, {h:.1f}),")
lines.append('};')
with open(os.path.join(ROOT, 'lib/game/nemrut_sprites.dart'), 'w') as f:
    f.write('\n'.join(lines) + '\n')
for k, v in boxes.items():
    print(k, [round(n) for n in v])
