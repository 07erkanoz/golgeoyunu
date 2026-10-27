#!/usr/bin/env python3
"""Ak Ana'nın Denizi'ne Yunus Koyu'nu ekler (bir kez çalışır): açık denizle
mağaraların arasına, gökyüzü açık, geniş ve derin bir koy. Sonraki her
sütun kaydırılır: harita, maps.dart'taki deniz listeleri, fısıltı planındaki
ağaç sütunları ve deniz testleri.
Kullanım: python3 tools/deniz_koy.py
"""
import math
import pathlib
import re

AT = 88   # ekleme sütunu (eski 87 ile 88 arası)
N = 150   # koyun genişliği
ROWS = 78


def floor(j: int) -> int:
    """Koyun dibi (ilk kaya satırı)."""
    def lerp(a, b, t):
        return a + (b - a) * max(0.0, min(1.0, t))
    if j < 12:
        f = lerp(23, 34, j / 12)
    elif j < 40:
        f = 36 + 2 * math.sin(j / 4.0)
    elif j < 46:
        f = lerp(37, 45, (j - 40) / 6)
    elif j < 76:
        f = 45 + (1 if j % 9 < 4 else 0)
    elif j < 82:
        f = lerp(45, 16, (j - 76) / 6)
    elif j < 94:
        f = 16 + (j % 4 == 0)
    elif j < 96:
        f = lerp(17, 31, (j - 94) / 2)
    elif j < 116:
        f = lerp(31, 41, (j - 96) / 6) if j < 102 else 41
    elif j < 138:
        f = 41 + 1.5 * math.sin(j / 3.0)
    else:
        f = lerp(41, 23, (j - 138) / 8)
    return int(round(f))


def column(j: int) -> list[str]:
    col = ["."] * ROWS
    f = floor(j)
    for r in range(f, ROWS):
        col[r] = "#"
    # Taş sütunlar: aralarından süzülerek geçilir.
    for x0, top in ((22, 26), (29, 22), (36, 27)):
        if x0 <= j < x0 + 2:
            for r in range(top, f):
                col[r] = "#"
    # Kayalık sırt: içinden bir tünel geçer (üstünden de aşılır).
    if 78 <= j < 97:
        for r in range(24, 29):
            col[r] = "."
    # Adacık: sudan bir sıra yükselir (üstünde Umay ağacı); gövdesinde
    # bir geçit.
    if 104 <= j < 112:
        for r in range(5, f):
            col[r] = "#"
        for r in range(17, 23):
            col[r] = "."
    # Koyun sonu: kayalık yar; su mağaralara iner.
    if j >= N - 4:
        for r in range(0, 10):
            col[r] = "#"
    return col


MARKS = {  # (j, satır): işaret
    (6, 12): "p",     # Yunus Koyu
    (58, 34): "p",    # Batık Gemi
    (108, 4): "K",    # adacıktaki Umay ağacı
    (20, 2): "F", (33, 1): "F", (66, 2): "F", (122, 2): "F", (132, 1): "F",
    (48, 40): "F", (88, 26): "F", (108, 19): "F",
}


def main() -> None:
    maps = pathlib.Path("lib/game/maps.dart")
    s = maps.read_text()
    a = s.index("const kMapDeniz")
    b = s.index("];", a)
    rows = re.findall(r"'([^']*)'", s[a:b])
    assert len(rows) == ROWS and all(len(r) == 420 for r in rows), "harita beklenen biçimde değil"
    cols = [column(j) for j in range(N)]
    for (j, r), ch in MARKS.items():
        assert cols[j][r] == ".", (j, r)
        cols[j][r] = ch
    new_rows = [rows[r][:AT] + "".join(cols[j][r] for j in range(N)) + rows[r][AT:] for r in range(ROWS)]
    body = "".join(f"  '{r}',\n" for r in new_rows)
    head = s[a:s.index("[", a) + 1]
    s = s[:a] + head + "\n" + body + s[b:]

    def shift_c(m: re.Match) -> str:
        c = int(m.group(1))
        return f"({c + N if c >= AT else c}{m.group(2)}"
    # Deniz listelerinde ilk sayı sütundur: (c, r, ...) ve (c0, c1) çiftlerinde ikisi de.
    for name in ("kDenizAir", "kDenizKelp", "kDenizFish", "kDenizJellies", "kDenizAnglers", "kDenizOctopi",
                 "kDenizCurrents", "kDenizVents", "kDenizTurtle", "kDenizBoats", "kDenizAkAna"):
        i = s.index(f"const {name}")
        j = s.index(";", i)
        part = s[i:j]
        if name in ("kDenizKelp", "kDenizBoats"):
            part = re.sub(r"\((\d+), (\d+)\)",
                          lambda m: f"({int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)}, "
                                    f"{int(m.group(2)) + (N if int(m.group(2)) >= AT else 0)})", part)
        elif name == "kDenizAir":
            part = re.sub(r"\((\d+), (\d+), (\d+), (\d+)\)",
                          lambda m: f"({int(m.group(1)) + (N if int(m.group(1)) >= AT else 0)}, {m.group(2)}, "
                                    f"{int(m.group(3)) + (N if int(m.group(3)) >= AT else 0)}, {m.group(4)})", part)
        else:
            part = re.sub(r"\((\d+)(,)", shift_c, part)
        s = s[:i] + part + s[j:]
    maps.write_text(s)

    plan = pathlib.Path("lib/game/anlatim_plani.dart")
    t = plan.read_text()
    i = t.index("  20: {")
    j = t.index("},", i)
    t = t[:i] + re.sub(r"WhisperPlace\.agac, (\d+)\)",
                       lambda m: f"WhisperPlace.agac, {int(m.group(1)) + N})", t[i:j]) + t[j:]
    plan.write_text(t)
    print("koy eklendi:", N, "sütun; dip satırları", [floor(j) for j in range(0, N, 10)])


if __name__ == "__main__":
    main()
