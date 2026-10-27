#!/usr/bin/env python3
"""Erlik'in katına Kıl Köprü kesitini ekler (bir kez çalışır): Erlik'in
bacasından önce, yeraltı ırmağının üstünde iki kıl köprü (ortada dinlenme
kayası), üstünde ışığa gelen bir Körmös, sonda Umay ağacı. Köprüler bölüm
tanımında (hairBridges); sonraki sütunlar kaydırılır: harita ve fısıltı
planındaki ağaç sütunları. Testlerdeki sabit konumlar elle güncellenir.
Kullanım: python3 tools/erlik_kopru.py
"""
import pathlib
import re

AT = 252
N = 50
ROWS = 48
BRIDGES = [(5, 19), (22, 36)]


def column(j: int) -> list[str]:
    col = ["#"] * 20 + ["."] * 11 + ["#"] * 17
    assert len(col) == ROWS
    for a, b in BRIDGES:
        if a <= j <= b:
            for r in range(31, 39):
                col[r] = "."
            for r in range(39, 42):
                col[r] = "w"
    return col


MARKS = {(2, 29): "p", (28, 25): "b", (41, 30): "K"}


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapErlik ")
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
    i = t.index("  14: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)})",
                       t[i:j]) + t[j:]
    plan.write_text(t)
    print("köprüler:", [(AT + x, AT + y, 31) for x, y in BRIDGES])
    for r in range(18, 43):
        print(f"{r:2d}", new[r][AT - 3:AT + N + 8])


if __name__ == "__main__":
    main()
