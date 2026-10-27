#!/usr/bin/env python3
"""Anlatıcı sesinde bozuk tek cümleyi yeniden üretip yerine oturtur.
Satırın geri kalanına dokunulmaz (kredi yalnız o cümleye gider).
Cümle bağlı yolla üretilir: önceki ve sonraki cümle bağlam olarak verilir.
Yeri bulmak: ses sessizliklerden adalara bölünür, her ada yazıya dökülür,
cümleye en çok benzeyen ardışık adalar değiştirilir. Kesimler sessizlikte;
EQ yok, yalnız ses yüksekliği eşitlenir.
Kullanım:
  python3 tools/cumle_onar.py --kimlik 8b55c324 --cumle "Derken su" [--dil tr] [--kuru]
--kuru: üretmeden yalnız bulunan yeri yazar. Eski dosya build/ses/onarim_yedek/
altına yedeklenir; yeni dosya ayrıca
docs/onizleme/ses/onarim/ altına dinlemek için kopyalanır.
"""
import argparse
import difflib
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

sys.argv, _args = sys.argv[:1], sys.argv[1:]
sys.path.insert(0, str(pathlib.Path(__file__).parent))
import seslendir_eleven as se  # noqa: E402
import dedi_temizle as dt  # noqa: E402

sys.argv += _args


def norm(t: str) -> str:
    return " ".join(se.words(t))


def locate(path: str, target: str) -> tuple[float, float, float]:
    """Cümleye en çok benzeyen ardışık adaların başı, sonu ve benzerliği."""
    isl = dt.islands(path)
    heard = [norm(dt.snippet_text(path, a, b)) for a, b in isl]
    want = norm(target)
    best = (0.0, 0, 0)
    for i in range(len(isl)):
        for j in range(i, min(len(isl), i + 6)):
            got = " ".join(h for h in heard[i:j + 1] if h)
            r = difflib.SequenceMatcher(None, got, want).ratio()
            if r > best[0]:
                best = (r, i, j)
    r, i, j = best
    for k, ((a, b), h) in enumerate(zip(isl, heard)):
        print(f"  {'>' if i <= k <= j else ' '} {a:6.2f}-{b:6.2f} {h}")
    return isl[i][0], isl[j][1], r


def piece(mp3: bytes, d: pathlib.Path) -> pathlib.Path:
    src, out = d / "n.mp3", d / "n.wav"
    src.write_bytes(mp3)
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-af",
                    "aresample=32000,silenceremove=start_periods=1:start_threshold=-48dB,"
                    "areverse,silenceremove=start_periods=1:start_threshold=-48dB,"
                    "afade=t=in:d=0.015,areverse,afade=t=in:d=0.01,loudnorm=I=-18:TP=-2:LRA=7,aresample=32000",
                    "-ac", "1", str(out)], check=True)
    return out


def splice(path: str, a: float, b: float, new: pathlib.Path, dst: pathlib.Path) -> None:
    fade = "afade=t=in:d=0.01,areverse,afade=t=in:d=0.01,areverse"
    graph = (f"[0:a]atrim=end={a},asetpts=PTS-STARTPTS,{fade}[x];"
             f"[1:a]aresample=32000[y];"
             f"[0:a]atrim=start={b},asetpts=PTS-STARTPTS,{fade}[z];"
             "[x][y][z]concat=n=3:v=0:a=1[o]")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-i", str(new), "-filter_complex", graph,
                    "-map", "[o]", "-ac", "1", "-ar", "32000", "-b:a", "56k", str(dst)], check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dil", default="tr")
    ap.add_argument("--kimlik", required=True)
    ap.add_argument("--cumle", required=True, help="bozuk cümlenin başı (altyazıdaki gibi)")
    ap.add_argument("--kuru", action="store_true")
    a = ap.parse_args()
    se.AYRI = se.BAGLI = True
    sc = se.scenes(a.dil)
    tx = se.scripted(a.dil, sc)
    hit = [(w, i) for w, items in sc.items() for i, e in enumerate(items) if e["id"] == a.kimlik]
    if not hit:
        sys.exit("satır bulunamadı")
    w, i = hit[0]
    segs = se.segments(a.dil, w, i, tx[w][i])
    found = None
    for k, (who, p) in enumerate(segs):
        if who != "anlatici":
            continue
        m = re.match(r"(\[[^\]]*\])\s*(.*)", p, re.S)
        tag, body = (m.group(1), m.group(2)) if m else ("[warm storyteller]", p)
        snts = se.sentences(body)
        for j, snt in enumerate(snts):
            if norm(snt).startswith(norm(a.cumle)) or norm(a.cumle) in norm(snt):
                prev = " ".join(snts[max(0, j - 2):j]) or (se.plain(segs[k - 1][1]) if k > 0 else None)
                nxt = snts[j + 1] if j + 1 < len(snts) else (se.plain(segs[k + 1][1]) if k + 1 < len(segs) else None)
                found = (se.STORY.get(tag, tag), snt, prev, nxt)
    if not found:
        sys.exit("cümle anlatıcı parçalarında bulunamadı")
    rich, snt, prev, nxt = found
    path = f"assets/voice/{a.dil}/{a.kimlik}.mp3"
    print(f"{w} {a.kimlik}: {snt}")
    start, end, r = locate(path, snt)
    print(f"  yer {start:.2f}-{end:.2f} benzerlik {r:.2f}")
    if r < 0.7:
        sys.exit("yer güvenle bulunamadı; elle bakılmalı")
    if a.kuru:
        return
    best = None
    for attempt in range(3):
        mp3 = se.tts(a.dil, f"{rich} {snt}", prev, nxt, "anlatici")
        bad = se.doubled(se.s.transcribe(se.wav16(mp3)), snt)
        best = best or mp3
        if not bad:
            best = mp3
            break
        print(f"  yeniden ({bad})")
    yedek = pathlib.Path("build/ses/onarim_yedek")
    yedek.mkdir(parents=True, exist_ok=True)
    shutil.copy(path, yedek / f"{a.dil}_{a.kimlik}.mp3")
    with tempfile.TemporaryDirectory() as d:
        new = piece(best, pathlib.Path(d))
        out = pathlib.Path(d) / "o.mp3"
        splice(path, start, end, new, out)
        shutil.copy(out, path)
    dinle = pathlib.Path("docs/onizleme/ses/onarim")
    dinle.mkdir(parents=True, exist_ok=True)
    shutil.copy(path, dinle / f"{a.dil}_{a.kimlik}.mp3")
    print("  yazıldı:", path)


if __name__ == "__main__":
    main()
