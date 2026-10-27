#!/usr/bin/env python3
"""Kar Yolu'na Erzurum Damları kesitini ekler (bir kez çalışır): donmuş
gölden sonra, Terk Edilmiş Han'dan önce. Karlı damlar üstünde süzülme:
bacaların sıcak dumanı yukarı taşır (rüzgâr akımı `r`), fırtınaya karşı
damdan dama süzülünür; sokakta kurtlar dolaşır, evlerin duvarındaki
zincirlerle dama geri çıkılır. İki dam arasında havada donmuş kedi
(Evliya Çelebi'nin anlattığı; sürpriz `donmusKedi`).
Sonraki sütunlar kaydırılır: harita ve fısıltı planındaki ağaç sütunları.
Bölüm tanımındaki sütunlar ve testler elle güncellenir.
Kullanım: python3 tools/kar_yolu_damlar.py
"""
import pathlib
import re

AT = 197
N = 80
ROWS = 26

# (ilk sütun, son sütun, dam satırı, baca sütunu ya da None, zincir sütunu ya da None)
HOUSES = [
    (3, 10, 14, 9, 3),
    (17, 23, 13, 22, 17),
    (31, 37, 12, 36, 31),
    (45, 52, 14, 51, 45),
    (60, 68, 11, None, None),
]


def column(j: int) -> list[str]:
    col = ["."] * 20 + ["#"] * 6
    for c0, c1, roof, chimney, chain in HOUSES:
        if c0 <= j <= c1:
            for r in range(roof, 20):
                col[r] = "#"
        if chimney is not None and j == chimney:
            col[roof - 1] = "#"
            for r in range(3, roof - 1):
                col[r] = "r"
        # Duman sütunu bacadan sağa dört kare: rüzgâra karşı süzülen
        # içinden geçerken yükselir.
        if chimney is not None and chimney < j <= chimney + 3:
            for r in range(3, roof - 1):
                if col[r] == ".":
                    col[r] = "r"
        if chain is not None and j == chain - 1:
            for r in range(roof, 19):
                col[r] = "|"
    # Dördüncü evin sağ duvarında da zincir: son aralığa düşen geri çıkar.
    if j == 53:
        for r in range(14, 19):
            col[r] = "|"
    return col


MARKS = {
    (1, 18): "p",          # Erzurum Damları
    (14, 19): "b",         # sokakta kurt
    (40, 19): "b",
    (6, 13): "F", (20, 12): "F", (34, 11): "F", (48, 13): "F",
    (74, 19): "K",         # damlardan inince Umay ağacı
}

CAT = (41, 9)


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapKarYolu ")
    b = s.index("];", a)
    rows = [r.replace("\\$", "$") for r in re.findall(r"'([^']*)'", s[a:b])]
    assert len(rows) == ROWS
    cols = [column(j) for j in range(N)]
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r, cols[j][r])
        cols[j][r] = ch
    new = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    head = s[a:s.index("[", a) + 1]
    s = s[:a] + head + "\n" + "".join(f"  '{r.replace('$', chr(92) + '$')}',\n" for r in new) + s[b:]
    maps.write_text(s)
    plan = pathlib.Path("lib/game/anlatim_plani.dart")
    t = plan.read_text()
    i = t.index("  8: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)})",
                       t[i:j]) + t[j:]
    plan.write_text(t)
    print("kedi:", (AT + CAT[0], CAT[1]))
    for r in range(ROWS):
        print(f"{r:2d}", new[r][AT - 4:AT + N + 6])


if __name__ == "__main__":
    main()
