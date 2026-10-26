#!/usr/bin/env python3
"""Perde metnini okunur bir belgeye döker: docs/PERDE_METNI.md (oynanış
sırasıyla; her bölümün perdesi, ardından Hikâye köprüsü; Türkçe ve
İngilizce)."""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
d = json.loads((ROOT / "tools/perde_metni/metin.json").read_text())
lv = (ROOT / "lib/game/levels.dart").read_text()
order = [int(x) for x in re.search(r"const levelOrder = <int>\[(.*?)\]", lv, re.S).group(1).replace("//", "").split(",") if x.strip()]
titles = re.findall(r"^    title: '(.*?)',", lv, re.M)
out = ["# Perde metni", "",
       "Tek kaynak: tools/perde_metni/metin.json (koda tools/perde_metni/uygula.py",
       "işler; bu belgeyi tools/perde_metni/belge.py üretir). Büyük harfli satırlar",
       "perde başlığıdır, seslendirilmez.", ""]


def block(title, tr, en):
    out.append(f"## {title}")
    out.append("")
    for i, (a, b) in enumerate(zip(tr, en)):
        out.append(f"{i + 1}. {a}")
        out.append(f"   *{b}*")
    out.append("")


block("Önsöz", d["tr"]["prologue"], d["en"]["prologue"])
for i in order:
    t = titles[i].replace("\\'", "'")
    if d["tr"]["perde"][str(i)]:
        block(f"{t} · perde", d["tr"]["perde"][str(i)], d["en"]["perde"][str(i)])
    block(f"{t} · Hikâye köprüsü", d["tr"]["kopru"][str(i)], d["en"]["kopru"][str(i)])
block("Son perde", d["tr"]["epilogue"], d["en"]["epilogue"])
(ROOT / "docs/PERDE_METNI.md").write_text("\n".join(out))
print("docs/PERDE_METNI.md yazıldı")
