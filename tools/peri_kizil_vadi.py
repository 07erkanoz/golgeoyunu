#!/usr/bin/env python3
"""Peri Bacaları'na Kızıl Vadi kesitini ekler (bir kez çalışır): Güvercinlik
Vadisi'nden inişle Kaya Kilisesi'nin mağara ağzı arasında, gökyüzü açık bir
vadi. Sarmaşıklı peri bacaları, dibinde demir nallar (bölüm tanımında
irons), vadide süzülen Albastı (albastis): ışığa gelir, demirin çevresine
giremez. Sonraki sütunlar kaydırılır: harita ve fısıltı planındaki ağaç
sütunları. Bölüm tanımındaki sütunlar ve testler elle güncellenir.
Kullanım: python3 tools/peri_kizil_vadi.py
"""
import pathlib
import re

AT = 198
N = 70
ROWS = 30
PILLARS = [(12, 13, 17), (27, 28, 15), (42, 43, 16), (57, 58, 18)]
IRONS = [(9, 25), (24, 25), (39, 25), (54, 25), (64, 25)]
ALBASTIS = [(33, 19), (49, 17)]


def column(j: int) -> list[str]:
    col = ["."] * 26 + ["#"] * 4
    for a, b, top in PILLARS:
        if a <= j <= b:
            for r in range(top, 26):
                col[r] = "#"
        if j == a - 1:
            for r in range(top, 25):
                col[r] = "|"
    # Sonda yar ve Kaya Kilisesi'nin mağara ağzı.
    if j >= N - 4:
        for r in range(6, 14):
            col[r] = "#"
    return col


MARKS = {(2, 25): "K", (3, 25): "p"}


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapPeri ")
    b = s.index("];", a)
    rows = [r.replace("\\$", "$") for r in re.findall(r"'([^']*)'", s[a:b])]
    assert len(rows) == ROWS
    cols = [column(j) for j in range(N)]
    for a0, b0, top in PILLARS:
        cols[a0][top - 1] = "F"
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r)
        cols[j][r] = ch
    new = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    head = s[a:s.index("[", a) + 1]
    s = s[:a] + head + "\n" + "".join(f"  '{r.replace('$', chr(92) + '$')}',\n" for r in new) + s[b:]
    maps.write_text(s)
    plan = pathlib.Path("lib/game/anlatim_plani.dart")
    t = plan.read_text()
    i = t.index("  11: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)})",
                       t[i:j]) + t[j:]
    plan.write_text(t)
    print("irons:", [(AT + c, r) for c, r in IRONS])
    print("albastis:", [(AT + c, r) for c, r in ALBASTIS])
    for r in range(4, ROWS):
        print(f"{r:2d}", new[r][AT - 4:AT + N + 6])


if __name__ == "__main__":
    main()
