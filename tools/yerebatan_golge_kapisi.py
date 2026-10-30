#!/usr/bin/env python3
"""Yerebatan'a Gölge Kapısı'nı ekler (bir kez çalışır): gölgeyi önden
göndermenin ilk dersi. Sal Kanalı ile Karanlık Kanallar arasında, tehlikesiz
kısa bir oda:

- Gölge taşı (bölüm tanımında, ekleme sütunu + 4).
- Tavandan inen duvar ve altında demir parmaklıklı kapı: Sâye geçemez.
- Kapının ardında kol: Sâye yetişemez. Gölge parmaklıktan geçer, kolu çeker.

Eklemeden sonraki sütunlarda bölüm tanımında ya da fısıltı planında sütun
yok (Karabasan'ın kovalamacası haritadaki işaretlerle kayar).
Kullanım: python3 tools/yerebatan_golge_kapisi.py
"""
import pathlib
import re

AT = 376   # ekleme sütunu: Sal Kanalı'nın son kıyısı ile Karabasan'ın duvarı
N = 24
ROWS = 20


def column(j: int) -> list[str]:
    col = list("##" + "." * 12 + "######")
    assert len(col) == ROWS
    if j == 9:
        for r in range(2, 9):
            col[r] = "#"
        for r in range(9, 14):
            col[r] = "H"
    return col


MARKS = {  # (j, satır): işaret
    (1, 12): "p",     # Gölge Kapısı
    (16, 13): "L",    # parmaklığın ardındaki kol
}


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapYerebatan ")
    b = s.index("];", a)
    rows = re.findall(r"'([^']*)'", s[a:b])
    assert len(rows) == ROWS, len(rows)
    width = max(len(r) for r in rows)
    rows = [r.ljust(width, ".") for r in rows]
    # Ekleme yerinin iki yanı aynı zemin: satır 2-13 boş, 14'ten aşağısı taş.
    for r in range(ROWS):
        want = "#" if r < 2 or r >= 14 else "."
        assert rows[r][AT - 1] == want, (r, rows[r][AT - 1])
    cols = [column(j) for j in range(N)]
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r, cols[j][r])
        cols[j][r] = ch
    new_rows = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    head = s[a:s.index("[", a) + 1]
    body = "".join(f"  '{r}',\n" for r in new_rows)
    maps.write_text(s[:a] + head + "\n" + body + s[b:])
    for r in range(ROWS):
        print(f"{r:2d}", new_rows[r][AT - 4:AT + N + 6])


if __name__ == "__main__":
    main()
