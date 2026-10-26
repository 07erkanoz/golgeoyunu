#!/usr/bin/env python3
"""perde_denetim_test.dart çıktısından sahne başına bir inceleme sayfası:
her satırda iki an ve anlatım metni. → build/preview/denetim/sayfa_*.png"""
import json
import pathlib
import textwrap

from PIL import Image, ImageDraw, ImageFont

D = pathlib.Path("build/preview/denetim")
idx = json.loads((D / "index.json").read_text())
font = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans.ttf", 15)
bold = ImageFont.truetype("/usr/share/fonts/TTF/DejaVuSans-Bold.ttf", 18)
W, H, TW = 400, 225, 460
acts: dict[str, list] = {}
for e in idx:
    acts.setdefault(e["act"], []).append(e)
for act, rows in acts.items():
    img = Image.new("RGB", (W * 2 + TW + 30, 36 + len(rows) * (H + 8)), (24, 22, 20))
    d = ImageDraw.Draw(img)
    d.text((10, 8), act, fill=(255, 220, 150), font=bold)
    for i, e in enumerate(rows):
        y = 36 + i * (H + 8)
        for j, p in enumerate(e["shots"]):
            img.paste(Image.open(p).convert("RGB").resize((W, H)), (10 + j * (W + 5), y))
        txt = f"{e['line']}: " + e["text"]
        d.multiline_text((W * 2 + 25, y + 4), "\n".join(textwrap.wrap(txt, 52)), fill=(235, 230, 220), font=font, spacing=3)
    img.save(D / f"sayfa_{act.replace(':', '_')}.png")
print(len(acts), "sayfa")
