#!/usr/bin/env python3
"""Boğuk duyulan sesleri netleştirir (kredisiz): konuşma bölgesi (2,5 kHz)
kalın bölgeden (300 Hz altı) ortalamadan fazla düşükse fark kadar öne
çıkarılır, kalın bölge biraz kısılır, ses yüksekliği -18 LUFS'a eşitlenir.
Telefon hoparlöründe kalın sesler kısık duyuluyordu (ör. kervancı).
Kullanım: python3 tools/sesleri_netlestir.py [--kuru]"""
import json
import pathlib
import re
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor

HEDEF = -4.4  # bütün seslerin ortanca farkı
ESIK = -6.0


def fark(f: pathlib.Path) -> float:
    v = []
    for flt in ("lowpass=f=300", "bandpass=f=2500:width_type=o:w=2"):
        r = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(f), "-af", flt + ",ebur128", "-f", "null", "-"],
                           capture_output=True, text=True).stderr
        v.append(float(re.findall(r"I:\s+(-?[\d.]+) LUFS", r)[-1]))
    return v[1] - v[0]


def netlestir(f: pathlib.Path, d: float) -> None:
    g = min(6.0, HEDEF - d)
    af = (f"highpass=f=90,lowshelf=f=200:g={-min(3.0, g / 2):.1f},"
          f"equalizer=f=2500:width_type=o:w=2:g={g:.1f},"
          "loudnorm=I=-18:TP=-2:LRA=7,aresample=32000")
    with tempfile.TemporaryDirectory() as t:
        out = pathlib.Path(t) / "o.mp3"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(f), "-af", af,
                        "-ac", "1", "-ar", "32000", "-b:a", "56k", str(out)], check=True)
        f.write_bytes(out.read_bytes())


def main() -> None:
    files = []
    for lang in ("tr", "en"):
        for e in json.loads(pathlib.Path(f"build/ses/satirlar_{lang}.json").read_text()):
            p = pathlib.Path(f"assets/voice/{lang}/{e['id']}.mp3")
            if p.exists():
                files.append(p)
    with ThreadPoolExecutor(8) as ex:
        res = list(zip(files, ex.map(fark, files)))
    todo = [(f, d) for f, d in res if d < ESIK]
    print(f"{len(files)} dosya, {len(todo)} boğuk")
    if "--kuru" in sys.argv:
        return
    with ThreadPoolExecutor(8) as ex:
        list(ex.map(lambda x: netlestir(*x), todo))
    after = list(ThreadPoolExecutor(8).map(fark, [f for f, _ in todo]))
    for (f, d), a in zip(todo, after):
        print(f"{f.parent.name}/{f.name} {d:.1f} → {a:.1f}")


if __name__ == "__main__":
    main()
