#!/usr/bin/env python3
"""Masal taslağını (masal_<dil>.txt) okur, metin.json ile satır sayılarını
denetler, okunur belgeyi yazar. '=N' satırı mevcut N. satırı korur.
Kullanım: python3 tools/perde_metni/masal_taslak.py [--uygula]
--uygula: taslağı metin.json'a yazar (sonra uygula.py ve belge.py)."""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/perde_metni/metin.json"
d = json.loads(SRC.read_text())


def curly(s: str) -> str:
    out, open_ = [], True
    for ch in s:
        if ch == '"':
            out.append("“" if open_ else "”")
            open_ = not open_
        else:
            out.append(ch)
    if not open_:
        sys.exit(f"kapanmamış tırnak: {s[:60]}")
    return "".join(out)


def old(lang, key):
    if key in ("prologue", "epilogue"):
        return d[lang][key]
    k, i = key.split(":")
    return d[lang][k][i]


def parse(lang):
    p = ROOT / f"tools/perde_metni/masal_{lang}.txt"
    if not p.exists():
        return None
    res, key = {}, None
    for line in p.read_text().splitlines():
        if line.startswith("## "):
            key = line[3:].strip()
            res[key] = []
        elif line.strip():
            if line.startswith("="):
                res[key].append(old(lang, key)[int(line[1:])])
            else:
                res[key].append(curly(line.strip()))
    for key, lines in res.items():
        o = old(lang, key)
        if len(lines) != len(o):
            sys.exit(f"{lang} {key}: taslak {len(lines)}, eski {len(o)} satır")
        for i, (a, b) in enumerate(zip(lines, o)):
            if b.isupper() != a.isupper():
                sys.exit(f"{lang} {key}[{i}]: başlık satırı yer değiştirmiş")
    return res


tr, en = parse("tr"), parse("en")
lv = (ROOT / "lib/game/levels.dart").read_text()
order = [int(x) for x in re.search(r"const levelOrder = <int>\[(.*?)\]", lv, re.S).group(1).replace("//", "").split(",") if x.strip()]
titles = re.findall(r"^    title: '(.*?)',", lv, re.M)
out = ["# Gölge Oyunu · masal metni (taslak)", "",
       "Bütün perdeler ve Hikâye köprüleri, oynanış sırasıyla. Büyük harfli satırlar perde başlığıdır, seslendirilmez.", ""]


def block(title, key):
    out.append(f"## {title}")
    out.append("")
    for i, a in enumerate(tr[key]):
        out.append(f"{i + 1}. {a}")
        if en and key in en:
            out.append(f"   *{en[key][i]}*")
    out.append("")


block("Önsöz", "prologue")
for i in order:
    t = titles[i].replace("\\'", "'")
    if tr.get(f"perde:{i}"):
        block(f"{t} · perde", f"perde:{i}")
    block(f"{t} · Hikâye köprüsü", f"kopru:{i}")
block("Son perde", "epilogue")
(ROOT / "docs/oneri/MASAL_TAM_METIN.md").write_text("\n".join(out) + "\n")
n = sum(len(v) for v in tr.values())
print(f"denetim tamam: {len(tr)} sahne, {n} satır; docs/oneri/MASAL_TAM_METIN.md yazıldı")

if "--uygula" in sys.argv:
    for lang, src in (("tr", tr), ("en", en)):
        if not src:
            continue
        for key, lines in src.items():
            if key in ("prologue", "epilogue"):
                d[lang][key] = lines
            else:
                k, i = key.split(":")
                d[lang][k][i] = lines
    SRC.write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")
    print("metin.json güncellendi")
