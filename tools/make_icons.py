"""Başlatma ikonlarını üretir (önce: flutter test tools/preview/icon_test.dart).

build/icon/{icon,background,foreground}_1024.png dosyalarından Android
(eski ve uyarlanabilir), Windows (.ico) ve Linux (png) ikonlarını yazar.
"""
import os
from PIL import Image

SRC = 'build/icon'
full = Image.open(f'{SRC}/icon_1024.png').convert('RGBA')
bg = Image.open(f'{SRC}/background_1024.png').convert('RGBA')
fg = Image.open(f'{SRC}/foreground_1024.png').convert('RGBA')

def save(im, size, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.resize((size, size), Image.LANCZOS).save(path)

# Android: eski ikon (48 dp) ve uyarlanabilir katmanlar (108 dp).
res = 'android/app/src/main/res'
for name, k in [('mdpi', 1), ('hdpi', 1.5), ('xhdpi', 2), ('xxhdpi', 3), ('xxxhdpi', 4)]:
    save(full, int(48 * k), f'{res}/mipmap-{name}/ic_launcher.png')
    save(bg, int(108 * k), f'{res}/mipmap-{name}/ic_launcher_background.png')
    save(fg, int(108 * k), f'{res}/mipmap-{name}/ic_launcher_foreground.png')
os.makedirs(f'{res}/mipmap-anydpi-v26', exist_ok=True)
open(f'{res}/mipmap-anydpi-v26/ic_launcher.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n'
    '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
    '    <background android:drawable="@mipmap/ic_launcher_background"/>\n'
    '    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n'
    '</adaptive-icon>\n')

# Windows.
full.save('windows/runner/resources/app_icon.ico',
          sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

# Linux: pencere ikonu ve masaüstü kısayolu için.
save(full, 256, 'assets/icon/golge.png')
print('ikonlar yazıldı')
