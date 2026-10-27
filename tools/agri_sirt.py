#!/usr/bin/env python3
"""Ağrı'ya Rüzgârlı Sırt kesitini ekler (bir kez çalışır): buz mağarasının
sonundaki uçurumdan sonra, Akori'den önce. Üç buzul yarığı; her birinin
üstünde bir çıkıntıdan sarkan ip (`S`), en genişinde iki ip. Fırtınada
karşıdan esen rüzgâr sallanmayı zorlaştırır ("Burada ip, kanattan
sadıktır"). Aralarda kaya sırtları, ateşböcekleri, Umay ağacı.
Sonraki sütunlar kaydırılır: harita ve fısıltı planındaki ağaç sütunları.
Kullanım: python3 tools/agri_sirt.py
"""
import pathlib
import re

AT = 194
N = 60
ROWS = 26
GAPS = [(5, 12), (20, 27), (35, 44)]
# (sütun, ilk satır, son satır)
ROPES = [(8, 7, 15), (22, 7, 15), (37, 6, 15), (41, 6, 15)]
OVERHANGS = [(6, 10, 5), (20, 24, 5), (35, 43, 4)]


def column(j: int) -> list[str]:
    col = ["."] * 17 + ["#"] * 9
    for a, b in GAPS:
        if a <= j <= b:
            for r in range(17, ROWS):
                col[r] = "."
    for a, b, r in OVERHANGS:
        if a <= j <= b:
            col[r] = "#"
            col[r + 1] = "#"
    for c, r0, r1 in ROPES:
        if j == c:
            for r in range(r0, r1 + 1):
                col[r] = "S"
    return col


MARKS = {(1, 15): "p", (16, 16): "F", (31, 16): "F", (30, 16): "K", (50, 16): "F"}


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapAgri ")
    b = s.index("];", a)
    rows = [r.replace("\\$", "$") for r in re.findall(r"'([^']*)'", s[a:b])]
    assert len(rows) == ROWS
    cols = [column(j) for j in range(N)]
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r)
        cols[j][r] = ch
    new = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    head = s[a:s.index("[", a) + 1]
    s = s[:a] + head + "\n" + "".join(f"  '{r.replace('$', chr(92) + '$')}',\n" for r in new) + s[b:]
    maps.write_text(s)
    plan = pathlib.Path("lib/game/anlatim_plani.dart")
    t = plan.read_text()
    i = t.index("  4: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)})",
                       t[i:j]) + t[j:]
    plan.write_text(t)
    for r in range(ROWS):
        print(f"{r:2d}", new[r][AT - 4:AT + N + 6])


if __name__ == "__main__":
    main()
