#!/usr/bin/env python3
"""Yerebatan'a iki tanıtım kesiti ekler (bir kez çalışır): ilk bölüm
zorlukları sırayla tanıtsın. Başlangıçtaki hareket dersinden (boşluk,
zincir, Umay ağacı) sonra, ilk Kandilci'nin sütunlarından önce:

- Eski Depo: tehlikesiz. Sandığı sete it, üstüne çık; kolu çek, kapı açılır.
- Fener Dersi: iki alçak duvar arasında devriye gezen tek Kandilci ve sık
  sütunlar (gölgede saklan); sonra sütunsuz dar bir geçitte bir Kandilci
  daha (ateşböceği sal, ışığa gitsin).

Sonraki her sütun kaydırılır: harita ve fısıltı planındaki ağaç sütunları
burada; bölüm tanımındaki sütunlar (yankılar, Gözcü, kayalar, sürprizler)
ve testlerdeki sabit konumlar elle güncellendi.
Kullanım: python3 tools/yerebatan_ders.py
"""
import pathlib
import re

AT = 24    # ekleme sütunu (eski 23 ile 24 arası)
N = 110
ROWS = 20


def column(j: int) -> list[str]:
    col = list("##" + "." * 12 + "=" + "..." + "ww")
    assert len(col) == ROWS

    def block(r0: int, r1: int, ch: str = "#") -> None:
        for r in range(r0, r1 + 1):
            col[r] = ch
    # --- Eski Depo
    # Üç kare yüksek set: sandıksız çıkılmaz.
    if 11 <= j <= 22:
        block(11, 13)
        block(14, 19)
    # Kapı: tavandan inen duvar ve altında kapı.
    if 31 <= j <= 33:
        block(2, 8)
    if j == 32:
        block(9, 13, "H")
    # --- Fener Dersi
    # Devriyeyi sınırlayan alçak duvarlar (Sâye üstünden atlar).
    if j in (44, 80, 86, 97):
        block(12, 13)
    # Duvarların altı taş (tahta değil): Kandilci duvarın dibinde döner.
    if j in (44, 80, 86, 97):
        block(14, 19)
    # Sonda zincir ve üst çıkıntı: eski üst yol (sütunların üstündeki
    # çıkıntılar, hatıra) yeniden bağlansın.
    if j == 105:
        block(8, 12, "|")
    if 106 <= j <= 109:
        col[7] = "#"
    return col


MARKS = {  # (j, satır): işaret
    (2, 12): "p",     # Eski Depo
    (5, 13): "C",     # sandık
    (16, 10): "F",    # setin üstünde ateşböceği
    (26, 13): "L",    # kol
    (38, 13): "K",    # Umay ağacı
    (42, 12): "p",    # Fener Dersi
    (50, 13): "I", (55, 13): "I", (60, 13): "I", (65, 13): "I", (70, 13): "I", (75, 13): "I",
    (62, 13): "G",    # sütunların arasında devriye
    (82, 13): "F", (83, 13): "F",  # salmak için ateşböcekleri
    (91, 13): "G",    # dar geçitte devriye
    (102, 13): "K",   # ders bitti: Umay ağacı
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
    cols = [column(j) for j in range(N)]
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r, cols[j][r])
        cols[j][r] = ch
    new_rows = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    head = s[a:s.index("[", a) + 1]
    body = "".join(f"  '{r}',\n" for r in new_rows)
    maps.write_text(s[:a] + head + "\n" + body + s[b:])

    plan = pathlib.Path("lib/game/anlatim_plani.dart")
    t = plan.read_text()
    i = t.index("  0: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)})",
                       t[i:j]) + t[j:]
    plan.write_text(t)
    for r in range(ROWS):
        print(f"{r:2d}", new_rows[r][AT - 4:AT + N + 4])


if __name__ == "__main__":
    main()
