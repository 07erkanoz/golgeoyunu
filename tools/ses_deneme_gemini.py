#!/usr/bin/env python3
"""Sesli anlatım denemesi (Gemini TTS): fısıltıları birkaç sesle okutur.

Anahtar depoya girmez; şu sırayla aranır:
  1. GEMINI_API_KEY ortam değişkeni
  2. ~/.config/golge-oyunu/gemini.key dosyası (tek satır)

Kullanım:
  python3 tools/ses_deneme_gemini.py --modeller   # ses (TTS) modellerini listeler
  python3 tools/ses_deneme_gemini.py              # örnek satırları üretir
  python3 tools/ses_deneme_gemini.py --model <ad> --ses Charon Enceladus

Çıktı: build/ses_deneme/gemini_<ses>_<n>.wav (build/ depoya girmez).
Yalnız standart kütüphane kullanır.
"""

import argparse
import base64
import json
import os
import re
import pathlib
import sys
import time
import urllib.error
import urllib.request
import wave

API = "https://generativelanguage.googleapis.com/v1beta"
OUT = pathlib.Path("build/ses_deneme")

LINES = [
    "Yükselen merdiven göğe varmaz; varan, gölgesini yerde bırakandır.",
    "Fener neye değerse onu alır. Karanlıkta kal.",
]

# Okuma talimatı: kısa kalıp ("Nasıl söyle: metin"); uzun talimat da
# sesli okunuyordu. Hayal perdesinin anlatıcısı, fısıltıya yakın.
STYLE = "Yaşlı bir masalcı gibi, alçak sesle, fısıldayarak ve yavaşça söyle: "

# Talimatın okunmaması için: yönetmen notları ile metni ayıran yapılı kalıp
# ("yapi"). Kısa kalıpta ("kisa") talimat da okunuyordu; ses modelleri ayrı
# sistem talimatını ("sistem") kabul etmiyor (400).
DIRECTION = (
    "You are the voice of an old Turkish shadow-play (Karagöz) narrator. "
    "Speak the transcript in Turkish as a slow, soft, close whisper: calm, "
    "mysterious but not scary, with short pauses at the ends of sentences. "
    "Never read these notes aloud; speak only the transcript."
)


def prompt(text: str, mode: str, notes: str = DIRECTION) -> dict:
    """İstek gövdesinin metin kısmı; [mode]: kisa, sistem, yapi, yok.
    [notes]: satıra özel yönetmen notu (duygu, hız, anlatıcının yaşı)."""
    if mode == "sistem":
        return {
            "systemInstruction": {"parts": [{"text": DIRECTION}]},
            "contents": [{"parts": [{"text": text}]}],
        }
    if mode == "yapi":
        return {
            "contents": [
                {
                    "parts": [
                        {
                            # Google'ın rehberindeki kalıp: profil, sahne,
                            # notlar; okunacak metin yalnız TRANSCRIPT'te.
                            "text": "# AUDIO PROFILE: Hayali, a shadow-play narrator\n"
                            "## THE SCENE: Behind a lit shadow-play screen.\n"
                            "### DIRECTOR'S NOTES\n"
                            + notes
                            + "\n#### TRANSCRIPT\n"
                            + text
                        }
                    ]
                }
            ]
        }
    if mode == "yok":
        return {"contents": [{"parts": [{"text": text}]}]}
    return {"contents": [{"parts": [{"text": STYLE + text}]}]}

# Denenecek hazır sesler (Gemini TTS ses adları).
VOICES = ["Charon", "Enceladus", "Gacrux"]


def key() -> str:
    k = os.environ.get("GEMINI_API_KEY", "").strip()
    if k:
        return k
    f = pathlib.Path.home() / ".config/golge-oyunu/gemini.key"
    if f.exists():
        return f.read_text().strip()
    sys.exit(
        "Anahtar bulunamadı: GEMINI_API_KEY ortam değişkenini ya da "
        "~/.config/golge-oyunu/gemini.key dosyasını ayarla."
    )


def call(path: str, body: dict | None = None, tries: int = 6) -> dict:
    req = urllib.request.Request(
        API + path,
        data=None if body is None else json.dumps(body).encode(),
        # Anahtar adreste değil başlıkta gider (günlüklere düşmesin).
        headers={"x-goog-api-key": key(), "Content-Type": "application/json"},
        method="GET" if body is None else "POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors="replace")
        # Ücretsiz katman dakikada birkaç istek: söylenen süre beklenir.
        wait = re.search(r"retry in ([0-9.]+)s", msg)
        # Sunucu tarafında geçici hata: biraz bekleyip yeniden denenir.
        if e.code in (500, 502, 503, 504) and tries > 1:
            print(f"  sunucu hatası {e.code}: 10 sn sonra yeniden", flush=True)
            time.sleep(10)
            return call(path, body, tries - 1)
        if e.code == 429 and wait and tries > 1:
            secs = float(wait.group(1)) + 1
            print(f"  kota: {secs:.0f} sn bekleniyor…", flush=True)
            time.sleep(secs)
            return call(path, body, tries - 1)
        sys.exit(f"Gemini hatası {e.code}: {msg[:600]}")


def tts_models() -> list[str]:
    names = []
    page = ""
    while True:
        r = call("/models?pageSize=200" + (f"&pageToken={page}" if page else ""))
        for m in r.get("models", []):
            if "tts" in m["name"].lower():
                names.append(m["name"].removeprefix("models/"))
        page = r.get("nextPageToken", "")
        if not page:
            return names


def speak(
    model: str, voice: str, text: str, mode: str = "yapi", notes: str = DIRECTION
) -> bytes:
    r = call(
        f"/models/{model}:generateContent",
        {
            **prompt(text, mode, notes),
            "generationConfig": {
                "responseModalities": ["AUDIO"],
                "speechConfig": {
                    "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}
                },
            },
        },
    )
    part = r["candidates"][0]["content"]["parts"][0]["inlineData"]
    return base64.b64decode(part["data"])


def speech_seconds(path: pathlib.Path) -> float:
    """Dosyadaki konuşma süresi (sessizlikler sayılmaz)."""
    import array
    import math

    with wave.open(str(path)) as w:
        r = w.getframerate()
        a = array.array("h", w.readframes(w.getnframes()))
    win = r // 10
    loud = 0
    for i in range(0, len(a) - win, win):
        if math.sqrt(sum(x * x for x in a[i : i + win]) / win) > 400:
            loud += 1
    return loud / 10


def read_notes(path: pathlib.Path, text: str) -> bool:
    """Talimat da okunmuş mu: konuşma, metnin en yavaş okunuşundan uzun."""
    return speech_seconds(path) > 1.5 + len(text) * 0.11


def save_wav(path: pathlib.Path, pcm: bytes, rate: int = 24000) -> None:
    # Yeni modeller tam bir WAV dosyası verir (sonunda "Google Generative AI
    # ile üretildi" içerik kimliği, C2PA): olduğu gibi yazılır; yeniden
    # sarılırsa başlık ve kimlik ses gibi çalınıp cızırdıyordu.
    if pcm[:4] == b"RIFF":
        path.write_bytes(pcm)
        return
    # Eski modeller ham ses verir: 16 bit, tek kanal, 24 kHz.
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(pcm)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--modeller", action="store_true", help="TTS modellerini listele")
    ap.add_argument("--model", help="kullanılacak model (yoksa listedeki ilk Flash TTS)")
    ap.add_argument("--ses", nargs="*", default=VOICES, help="ses adları")
    ap.add_argument("--satir", type=int, default=2, help="kaç satır okunsun")
    ap.add_argument("--atla", action="store_true", help="var olan dosyaları yeniden üretme")
    ap.add_argument("--kip", default="yapi", help="talimat: sistem, yapi, kisa, yok")
    ap.add_argument("--yalniz", type=int, help="yalnız bu satır (1'den)")
    ap.add_argument("--metin", help="tek satır: okunacak metin")
    ap.add_argument("--not", dest="notes", help="tek satır: yönetmen notu")
    ap.add_argument("--ad", help="tek satır: dosya adı (uzantısız)")
    a = ap.parse_args()
    models = tts_models()
    if a.modeller:
        print("\n".join(models) or "TTS modeli bulunamadı")
        return
    model = a.model or next(
        (m for m in models if "flash" in m and "lite" not in m),
        models[0] if models else None,
    )
    if not model:
        sys.exit("Bu anahtarla kullanılabilen TTS modeli yok.")
    print(f"model: {model}")
    OUT.mkdir(parents=True, exist_ok=True)
    # Tek satır, kendi notuyla (duygu denemeleri).
    if a.metin:
        for v in a.ses:
            f = OUT / f"{a.ad or 'gemini_tek'}_{v.lower()}.wav"
            save_wav(f, speak(model, v, a.metin, "yapi", a.notes or DIRECTION))
            warn = "  ← TALİMAT DA OKUNMUŞ" if read_notes(f, a.metin) else ""
            print(f"{f}  konuşma {speech_seconds(f):.1f} sn{warn}")
        return
    for v in a.ses:
        for i, line in enumerate(LINES[: a.satir], 1):
            if a.yalniz and i != a.yalniz:
                continue
            f = OUT / f"gemini_{v.lower()}_{a.kip}_{i}.wav"
            if a.atla and f.exists():
                continue
            save_wav(f, speak(model, v, line, a.kip))
            print(f)


if __name__ == "__main__":
    main()
