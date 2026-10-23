#!/usr/bin/env python3
"""Sesli anlatım denemesi (ElevenLabs): birkaç fısıltıyı birkaç sesle okutur.

Anahtar depoya girmez; şu sırayla aranır:
  1. ELEVENLABS_API_KEY ortam değişkeni
  2. ~/.config/golge-oyunu/elevenlabs.key dosyası (tek satır)

Kullanım:
  python3 tools/ses_deneme.py --sesler        # hesaptaki sesleri listeler
  python3 tools/ses_deneme.py                 # örnek satırları üretir
  python3 tools/ses_deneme.py --ses <id> ...  # yalnız bu sesler

Çıktı: build/ses_deneme/<ses>_<n>.mp3 (build/ depoya girmez).
Yalnız standart kütüphane kullanır.
"""

import argparse
import json
import os
import pathlib
import sys
import urllib.error
import urllib.request

API = "https://api.elevenlabs.io/v1"
MODEL = "eleven_multilingual_v2"
OUT = pathlib.Path("build/ses_deneme")

# Oyundan örnek satırlar: ozan, hikâye fısıltısı, perde, oynanışı anlatan söz.
LINES = [
    "Yükselen merdiven göğe varmaz; varan, gölgesini yerde bırakandır.",
    "Fener neye değerse onu alır. Karanlıkta kal.",
    "İstanbul, Temmuz 1660. Şehir iki gündür yanıyordu.",
    "Sâye ak gövdeli ağaca dokundu; dallardaki çaputlar rüzgârsız kıpırdadı.",
]


def key() -> str:
    k = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if k:
        return k
    f = pathlib.Path.home() / ".config/golge-oyunu/elevenlabs.key"
    if f.exists():
        return f.read_text().strip()
    sys.exit(
        "Anahtar bulunamadı: ELEVENLABS_API_KEY ortam değişkenini ya da "
        "~/.config/golge-oyunu/elevenlabs.key dosyasını ayarla."
    )


def call(path: str, body: dict | None = None) -> bytes:
    req = urllib.request.Request(
        API + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={"xi-api-key": key(), "Content-Type": "application/json"},
        method="GET" if body is None else "POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.read()
    except urllib.error.HTTPError as e:
        # Hata gövdesi yazdırılır; anahtar asla yazdırılmaz.
        sys.exit(f"ElevenLabs hatası {e.code}: {e.read().decode(errors='replace')[:400]}")


def voices() -> list[dict]:
    return json.loads(call("/voices"))["voices"]


def speak(voice_id: str, text: str) -> bytes:
    # Fısıltı havası: sakin, tutarlı, abartısız.
    return call(
        f"/text-to-speech/{voice_id}?output_format=mp3_44100_128",
        {
            "text": text,
            "model_id": MODEL,
            "language_code": "tr",
            "voice_settings": {
                "stability": 0.6,
                "similarity_boost": 0.75,
                "style": 0.2,
                "use_speaker_boost": True,
            },
        },
    )


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sesler", action="store_true", help="sesleri listele")
    ap.add_argument("--ses", nargs="*", help="kullanılacak ses kimlikleri")
    ap.add_argument("--adet", type=int, default=3, help="kaç ses denensin")
    # Ücretsiz hesap ayda ~1000 karakter: varsayılan iki kısa satır.
    ap.add_argument("--satir", type=int, default=2, help="kaç satır okunsun")
    a = ap.parse_args()
    vs = voices()
    if a.sesler:
        for v in vs:
            labels = ", ".join(f"{k}:{x}" for k, x in (v.get("labels") or {}).items())
            print(f"{v['voice_id']}  {v['name']}  [{labels}]")
        return
    chosen = [v for v in vs if not a.ses or v["voice_id"] in a.ses][: a.adet if not a.ses else None]
    OUT.mkdir(parents=True, exist_ok=True)
    for v in chosen:
        name = "".join(ch for ch in v["name"].lower() if ch.isalnum()) or v["voice_id"]
        for i, line in enumerate(LINES[: a.satir], 1):
            f = OUT / f"{name}_{i}.mp3"
            f.write_bytes(speak(v["voice_id"], line))
            print(f"{f}  ({len(line)} karakter)")


if __name__ == "__main__":
    main()
