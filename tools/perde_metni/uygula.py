#!/usr/bin/env python3
"""Perde metnini koda işler.

Tek kaynak tools/perde_metni/metin.json (Türkçe ve İngilizce: önsöz, son
perde, bölüm perdeleri, Hikâye köprüleri). Bu betik lib/game/levels.dart
içindeki prologue, epilogue, interludes, bridges dizilerini (ve İngilizce
eşlerini) baştan yazar.

Perdedeki resimler satır sırasına bağlıdır (kahraman kartları, kovalama
anı): her perdenin satır sayısı korunmalıdır; betik bunu denetler.

Kullanım: python3 tools/perde_metni/uygula.py
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
SRC = ROOT / "tools/perde_metni/metin.json"
DART = ROOT / "lib/game/levels.dart"


def lit(s: str) -> str:
    s = s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$")
    return f"'{s}'"


def flat(name: str, lines: list[str]) -> str:
    body = "".join(f"  {lit(l)},\n" for l in lines)
    return f"const {name} = [\n{body}];"


def nested(name: str, by_level: dict[str, list[str]]) -> str:
    out = [f"const {name} = <List<String>>["]
    for i in range(len(by_level)):
        lines = by_level[str(i)]
        if not lines:
            out.append("  [],")
            continue
        out.append("  [")
        out += [f"    {lit(l)}," for l in lines]
        out.append("  ],")
    out.append("];")
    return "\n".join(out)


def replace_block(src: str, name: str, new: str) -> str:
    m = re.search(rf"^const {name} = (<List<String>>)?\[\n.*?^\];", src, re.S | re.M)
    if not m:
        sys.exit(f"{name} bulunamadı")
    return src[: m.start()] + new + src[m.end():]


def main() -> None:
    d = json.loads(SRC.read_text())
    src = DART.read_text()
    for lang, suf in (("tr", ""), ("en", "En")):
        t = d[lang]
        src = replace_block(src, f"prologue{suf}", flat(f"prologue{suf}", t["prologue"]))
        src = replace_block(src, f"epilogue{suf}", flat(f"epilogue{suf}", t["epilogue"]))
        src = replace_block(src, f"interludes{suf}", nested(f"interludes{suf}", t["perde"]))
        src = replace_block(src, f"bridges{suf}", nested(f"bridges{suf}", t["kopru"]))
    # Satır sayıları iki dilde aynı olmalı (resimler satıra bağlı).
    for sec in ("perde", "kopru"):
        for k, v in d["tr"][sec].items():
            if len(v) != len(d["en"][sec][k]):
                sys.exit(f"{sec} {k}: Türkçe {len(v)}, İngilizce {len(d['en'][sec][k])} satır")
    DART.write_text(src)
    print("levels.dart güncellendi")


if __name__ == "__main__":
    main()
