#!/usr/bin/env python3
"""Nemrut'a Tümülüsün Yamacı kesitini ekler (bir kez çalışır): "Tümülüsün
altında bir kral uyur. Taşlarını oynatma" fısıltısından sonra, uçurumun
üstünde basınca kayıp düşen moloz taşlarıyla (`O`) yükselen bir yamaç;
tepede düzlük ve Umay ağacı, öbür yandan inişe kayan taşlar. Sonraki
sütunlar kaydırılır: harita ve fısıltı planındaki ağaç sütunları.
Kullanım: python3 tools/nemrut_yamac.py
"""
import pathlib
import re

AT = 204
N = 60
ROWS = 26
STEPS = [(5, 18), (8, 17), (11, 16), (14, 15), (24, 13), (27, 12), (30, 11),
         (42, 11), (45, 13), (48, 15), (51, 17)]
LEDGES = [(17, 20, 14), (33, 38, 10)]


def column(j: int) -> list[str]:
    col = ["."] * 20 + ["#"] * 6
    if 4 <= j <= 53:
        for r in range(20, ROWS):
            col[r] = "."
    for c0, c1, r in LEDGES:
        if c0 <= j <= c1:
            col[r] = "#"
            col[r + 1] = "#"
    return col


MARKS = {(19, 13): "F", (35, 9): "F", (37, 9): "K", (34, 9): "F"}


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapNemrut ")
    b = s.index("];", a)
    rows = [r.replace("\\$", "$") for r in re.findall(r"'([^']*)'", s[a:b])]
    assert len(rows) == ROWS
    cols = [column(j) for j in range(N)]
    for j, r in STEPS:
        assert cols[j][r] == "."
        cols[j][r] = "O"
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r)
        cols[j][r] = ch
    new = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    head = s[a:s.index("[", a) + 1]
    s = s[:a] + head + "\n" + "".join(f"  '{r.replace('$', chr(92) + '$')}',\n" for r in new) + s[b:]
    maps.write_text(s)
    plan = pathlib.Path("lib/game/anlatim_plani.dart")
    t = plan.read_text()
    i = t.index("  6: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)})",
                       t[i:j]) + t[j:]
    plan.write_text(t)
    for r in range(4, ROWS):
        print(f"{r:2d}", new[r][AT - 4:AT + N + 6])


if __name__ == "__main__":
    main()
