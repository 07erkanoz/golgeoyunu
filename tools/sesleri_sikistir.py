#!/usr/bin/env python3
"""Büyük ses dosyalarını Ogg Vorbis'e sıkıştırır (uygulama küçülsün).

Asıl WAV'lar `assets_src/audio/` altında saklanır (uygulamaya girmez, silinmez);
sıkıştırılmışları `assets/audio/<ad>.ogg` olur. Kısa efektler WAV kalır
(küçükler; ani vuruşlarda Vorbis iz bırakabilir).

Her dosya için denetlenir:
- örnek sayısı aynı mı (döngüler dikişsiz kalsın),
- döngü dikişindeki sıçrama (son örnek → ilk örnek) asılınkinden büyük mü,
- ses düzeyi (ortalama ve tepe) asıla yakın mı.

Sentez araçları (tools/synth_*.py) WAV'ı yine assets/audio'ya yazar; bu araç
yeniden çalıştırılınca WAV assets_src'ye taşınır ve sıkıştırılır.

  python3 tools/sesleri_sikistir.py
"""
import array
import pathlib
import shutil
import subprocess
import sys

SRC = pathlib.Path("assets_src/audio")
OUT = pathlib.Path("assets/audio")
QUALITY = "6"  # libvorbis kalite (0-10); 6 ≈ mono 90-100 kbps, duyulur fark yok

NAMES = [
    "amb_konya", "amb_forest", "amb_ark", "perde_ney", "amb_cistern",
    "amb_snow", "amb_sky", "karabasan", "amb_cave", "murmur", "thunder",
    "heartbeat", "amb_wind", "howl", "sting", "memory", "death", "gust",
]

# Döngüyle çalınanlar: dikiş ayrıca denetlenir.
LOOPS = {
    "amb_konya", "amb_forest", "amb_ark", "perde_ney", "amb_cistern",
    "amb_snow", "amb_sky", "karabasan", "amb_cave", "murmur", "heartbeat",
    "amb_wind",
}


def pcm(path: pathlib.Path) -> array.array:
    """Dosyayı 44,1 kHz mono 16 bit örneklere çözer."""
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", str(path), "-f", "s16le", "-ac", "1",
         "-ar", "44100", "-"],
        capture_output=True, check=True,
    ).stdout
    a = array.array("h")
    a.frombytes(raw)
    return a


def level(a: array.array) -> tuple[float, int]:
    import math
    if not a:
        return 0.0, 0
    rms = math.sqrt(sum(x * x for x in a[:: max(1, len(a) // 200000)]) /
                    len(a[:: max(1, len(a) // 200000)]))
    return rms, max(abs(x) for x in a)


def main() -> int:
    SRC.mkdir(parents=True, exist_ok=True)
    bad = 0
    before = after = 0
    for name in NAMES:
        wav_in_assets = OUT / f"{name}.wav"
        src = SRC / f"{name}.wav"
        if wav_in_assets.exists():
            shutil.move(str(wav_in_assets), str(src))
        if not src.exists():
            print(f"YOK {name}")
            bad += 1
            continue
        ogg = OUT / f"{name}.ogg"
        subprocess.run(
            ["ffmpeg", "-y", "-v", "error", "-i", str(src), "-c:a", "libvorbis",
             "-q:a", QUALITY, str(ogg)],
            check=True,
        )
        a, b = pcm(src), pcm(ogg)
        (ra, pa), (rb, pb) = level(a), level(b)
        same_len = len(a) == len(b)
        seam_a = abs(a[-1] - a[0]) if a else 0
        seam_b = abs(b[-1] - b[0]) if b else 0
        seam_ok = name not in LOOPS or seam_b <= max(seam_a * 2, 600)
        lvl_ok = abs(rb - ra) <= ra * 0.03 + 1 and abs(pb - pa) <= pa * 0.1 + 200
        ok = same_len and seam_ok and lvl_ok
        bad += not ok
        before += src.stat().st_size
        after += ogg.stat().st_size
        print(
            f"{'TAMAM' if ok else 'SORUN'} {name:12} "
            f"{src.stat().st_size / 1e6:5.2f} → {ogg.stat().st_size / 1e6:5.2f} MB  "
            f"örnek {len(a)}/{len(b)}  dikiş {seam_a}/{seam_b}  "
            f"düzey {ra:.0f}/{rb:.0f} tepe {pa}/{pb}"
        )
    print(f"toplam {before / 1e6:.1f} MB → {after / 1e6:.1f} MB")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
