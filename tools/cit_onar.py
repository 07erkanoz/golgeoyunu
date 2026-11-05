#!/usr/bin/env python3
"""Cümle birleşme yerlerindeki "çıt"ları onarır (kredisiz): satırın
içindeki her sessizliğin kenarına kısa yumuşak geçiş konur. A yoluyla
cümle cümle üretilip birleştirilen satırlarda kesik uç, araya konan
sessizlikle birleşirken çıt yapıyordu.
Kullanım: python3 tools/cit_onar.py [--kuru] dosya.mp3 ...
"""
import array
import re
import subprocess
import sys
import tempfile
import pathlib

SR = 32000
RAMP = int(0.02 * SR)


def silences(path: str) -> list[tuple[float, float]]:
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", "silencedetect=n=-45dB:d=0.15",
                        "-f", "null", "-"], capture_output=True, text=True).stderr
    st = [float(x) for x in re.findall(r"silence_start: ([0-9.]+)", r)]
    en = [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", r)]
    return list(zip(st, en))


def repair(path: str, dry: bool = False) -> int:
    sil = silences(path)
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-ac", "1", "-ar", str(SR),
                          "-f", "s16le", "-"], capture_output=True, check=True).stdout
    a = array.array("h")
    a.frombytes(raw)
    n = len(a)
    edges = 0
    peak = max(abs(x) for x in a) or 1
    quiet = 0.12 * peak  # konuşmanın kısık kuyruğu (nefes, ağız sesi, çıt)
    win = int(0.01 * SR)

    def low(i: int) -> bool:
        seg = a[max(0, i):min(n, i + win)]
        return max((abs(x) for x in seg), default=0) < quiet

    for s, e in sil:
        i0, i1 = int(s * SR), int(e * SR)
        if i0 <= RAMP or i1 >= n - RAMP:
            continue  # baş ve son: zaten dolgu
        edges += 2
        # Cümle sonu artığı: kelime bitince (derin bir çukur) gelen kısık bir
        # patlama (nefes, ağız sesi) varsa çukurdan itibaren silinir. Ses
        # modeli her cümlenin sonuna bunu ekliyor; iki cümle arasında
        # "bozukluk" olarak duyuluyordu.
        def wpk(i: int) -> int:
            seg = a[max(0, i):min(n, i + win)]
            return max((abs(x) for x in seg), default=0)

        t0 = i0
        j = i0 - win
        while j > i0 - int(0.28 * SR):
            if wpk(j) < 0.05 * peak and all(wpk(m) < 0.2 * peak for m in range(j, i0, win)):
                t0 = j
            if wpk(j) >= 0.2 * peak:
                break
            j -= win
        # Sessizlikten ileri: konuşma başlamadan önceki kısık bölge (en çok 120 ms).
        t1 = i1
        while t1 + win < i1 + int(0.12 * SR) and low(t1):
            t1 += win
        # Kuyruk ve baş sönümlenir, arası sıfır; kelimenin kendisine dokunulmaz.
        # Çukura kadar kısa sönüm, çukurdan sonraki konuşmaya dek sessizlik.
        for k in range(RAMP):
            j = t0 - RAMP + k
            a[j] = int(a[j] * (1 - k / RAMP))
        for k in range(t0, t1):
            a[k] = 0
        for k in range(RAMP):
            if t1 + k < n:
                a[t1 + k] = int(a[t1 + k] * (k / RAMP))
    if dry or not edges:
        return edges
    with tempfile.TemporaryDirectory() as t:
        out = pathlib.Path(t) / "o.mp3"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "1",
                        "-i", "-", "-b:a", "64k", str(out)], input=a.tobytes(), check=True)
        pathlib.Path(path).write_bytes(out.read_bytes())
    return edges


if __name__ == "__main__":
    dry = "--kuru" in sys.argv
    for p in [x for x in sys.argv[1:] if not x.startswith("--")]:
        print(p, repair(p, dry), "kenar")
