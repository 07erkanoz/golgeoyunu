"""Ses adalarının ortanca perdesi (numpy): hatıralarda Sâye (ince) ile
ustanın (kalın) parçalarını ayırmak için."""
import subprocess

import numpy as np

SR = 16000
SAYE_HZ = 180


def load(path: str) -> np.ndarray:
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-ac", "1", "-ar", str(SR), "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768


def islands(x: np.ndarray, thr_db: float = -45, min_sil: float = 0.2) -> list[tuple[float, float]]:
    hop = 160
    fr = len(x) // hop
    e = np.sqrt(np.mean(x[:fr * hop].reshape(fr, hop) ** 2, axis=1) + 1e-12)
    voiced = 20 * np.log10(e) > thr_db
    out, start, sil = [], None, 0
    for i, v in enumerate(voiced):
        if v:
            if start is None:
                start = i
            sil = 0
        elif start is not None:
            sil += 1
            if sil * hop / SR >= min_sil:
                out.append((start * hop / SR, (i - sil + 1) * hop / SR))
                start, sil = None, 0
    if start is not None:
        out.append((start * hop / SR, fr * hop / SR))
    return [(a, b) for a, b in out if b - a > 0.08]


def f0(seg: np.ndarray) -> float:
    w, hop, vals = 640, 320, []
    for i in range(0, len(seg) - w, hop):
        fr = seg[i:i + w] - np.mean(seg[i:i + w])
        if np.sqrt(np.mean(fr ** 2)) < 0.01:
            continue
        ac = np.correlate(fr, fr, "full")[w - 1:]
        lo, hi = SR // 450, SR // 70
        lag = lo + int(np.argmax(ac[lo:hi]))
        if ac[lag] > 0.35 * ac[0]:
            vals.append(SR / lag)
    return float(np.median(vals)) if vals else 0.0


def groups(path: str) -> list[tuple[float, float, str]]:
    """Ardışık aynı konuşanın adaları birleşir: (baş, son, konuşan)."""
    x = load(path)
    out: list[tuple[float, float, str]] = []
    for a, b in islands(x):
        hz = f0(x[int(a * SR):int(b * SR)])
        who = ("saye" if hz > SAYE_HZ else "usta") if hz else (out[-1][2] if out else "saye")
        if out and out[-1][2] == who:
            out[-1] = (out[-1][0], b, who)
        else:
            out.append((a, b, who))
    return out
