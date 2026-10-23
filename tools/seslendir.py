#!/usr/bin/env python3
"""Anlatımı seslendirir (Gemini 3.8 Flash TTS) ve oyuna koyar.

Önce satırlar çıkarılır:
  flutter test tools/preview/ses_satirlari_test.dart   → build/ses/satirlar_<dil>.json
Sonra:
  python3 tools/seslendir.py --dil tr --bolum 0        # açılış perdesi + Yerebatan
  python3 tools/seslendir.py --dil tr --kimlik 4cfaca07 --yeniden

Sesler ve yönetmen notları: tools/ses_notlari.json (satır kimliği → ses, not).
Notu olmayan satır rolünün varsayılan sesiyle okunur.
Çıktı: assets/voice/<dil>/<kimlik>.mp3 (tek kanal, 24 kHz, 48 kbps).
Anahtar: GEMINI_API_KEY ya da ~/.config/golge-oyunu/gemini.key (depoya girmez).
"""

import argparse
import json
import pathlib
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import ses_deneme_gemini as g  # noqa: E402  (anahtar, istek, kota beklemesi)

MODEL = "gemini-3.8-flash-tts"
NOTES = pathlib.Path("tools/ses_notlari.json")

# Seslerin kalıcı tarifi; satırın kendi notu bunun üstüne eklenir.
PROFILE = {
    "Charon": (
        "Voice: the old master of a Turkish shadow theatre (hayali), old and "
        "wise, deep and resonant, calm authority. Pace: natural storytelling "
        "speed, not slow; brief pauses only where noted."
    ),
    "Enceladus": (
        "Voice: a mysterious, breathy whisper from the shadows, close to the "
        "listener. Pace: natural, not slow."
    ),
    "Leda": (
        "Voice: Saye, a girl of about twelve, apprentice of an old shadow-play "
        "master. Pace: natural storytelling speed."
    ),
}

ROLE_VOICE = {
    "perde": "Charon",
    "ozan": "Charon",
    "rivayet": "Charon",
    "fisilti": "Enceladus",
    "hatira": "Leda+Charon",
}

PREFIX = re.compile(r"^(Hatıra|Memory)\s*·\s*")
QUOTE = re.compile(r"[\"“”]([^\"“”]+)[\"“”]")


def body_single(voice: str, text: str, note: str) -> dict:
    return {
        "contents": [
            {
                "parts": [
                    {
                        "text": "# AUDIO PROFILE: " + voice + "\n"
                        "## THE SCENE: Behind a lit shadow-play screen.\n"
                        "### DIRECTOR'S NOTES\n"
                        + PROFILE[voice]
                        + "\n"
                        + note
                        + "\n#### TRANSCRIPT\n"
                        + text
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}}
            },
        },
    }


def dialogue(text: str) -> list[tuple[str, str]]:
    """Hatırayı konuşmalara böler: anlatım Sâye'nin, tırnak içi ustanın."""
    parts: list[tuple[str, str]] = []
    at = 0
    for m in QUOTE.finditer(text):
        before = text[at : m.start()].strip(" :")
        if before:
            parts.append(("Saye", before))
        said = m.group(1).strip().rstrip(",")
        if said and said[-1] not in ".!?…":
            said += "."
        parts.append(("Usta", said))
        at = m.end()
    rest = text[at:].strip(" ,")
    if rest:
        parts.append(("Saye", rest))
    return parts


def body_dialogue(parts: list[tuple[str, str]], note: str) -> dict:
    transcript = "\n".join(f"{who}: {line}" for who, line in parts)
    return {
        "contents": [
            {
                "parts": [
                    {
                        "text": "# AUDIO PROFILE: Saye and her master\n"
                        "## THE SCENE: Saye remembers her old master, the "
                        "shadow-play hayali.\n"
                        "### DIRECTOR'S NOTES\n"
                        "Saye: " + PROFILE["Leda"] + "\n"
                        "Usta: " + PROFILE["Charon"] + "\n" + note + "\n"
                        "#### TRANSCRIPT\n" + transcript
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "multiSpeakerVoiceConfig": {
                    "speakerVoiceConfigs": [
                        {
                            "speaker": "Saye",
                            "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": "Leda"}},
                        },
                        {
                            "speaker": "Usta",
                            "voiceConfig": {
                                "prebuiltVoiceConfig": {"voiceName": "Charon"}
                            },
                        },
                    ]
                }
            },
        },
    }


def generate(body: dict) -> bytes:
    import base64

    r = g.call(f"/models/{MODEL}:generateContent", body)
    return base64.b64decode(r["candidates"][0]["content"]["parts"][0]["inlineData"]["data"])


def trimmed_wav(raw: bytes, out: pathlib.Path) -> None:
    """Parçayı WAV olarak yazar; baştaki ve sondaki sessizlik kırpılır."""
    with tempfile.TemporaryDirectory() as d:
        src = pathlib.Path(d) / "in.wav"
        g.save_wav(src, raw)
        trim = (
            "silenceremove=start_periods=1:start_threshold=-48dB,"
            "areverse,silenceremove=start_periods=1:start_threshold=-48dB,"
            "areverse"
        )
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-af", trim,
             "-ac", "1", "-ar", "24000", str(out)],
            check=True,
        )


def join_mp3(pieces: list[pathlib.Path], out: pathlib.Path, gap: float = 0.3) -> None:
    """Hatıranın parçalarını aralarında kısa duraklarla tek MP3 yapar."""
    inputs: list[str] = []
    for p in pieces:
        inputs += ["-i", str(p)]
    n = len(pieces)
    chain = "".join(
        f"[{i}]apad=pad_dur={gap if i < n - 1 else 0.25}[a{i}];" for i in range(n)
    )
    chain += "".join(f"[a{i}]" for i in range(n)) + f"concat=n={n}:v=0:a=1[o]"
    subprocess.run(
        ["ffmpeg", "-y", "-loglevel", "error", *inputs, "-filter_complex", chain,
         "-map", "[o]", "-ac", "1", "-ar", "24000", "-b:a", "48k", str(out)],
        check=True,
    )


def to_mp3(raw: bytes, out: pathlib.Path) -> None:
    """Gelen sesi MP3'e çevirir; baştaki ve sondaki sessizliği kırpar."""
    with tempfile.TemporaryDirectory() as d:
        src = pathlib.Path(d) / "in.wav"
        g.save_wav(src, raw)
        trim = (
            "silenceremove=start_periods=1:start_threshold=-48dB,"
            "areverse,silenceremove=start_periods=1:start_threshold=-48dB,"
            "areverse,apad=pad_dur=0.25"
        )
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-i", str(src), "-af", trim,
             "-ac", "1", "-ar", "24000", "-b:a", "48k", str(out)],
            check=True,
        )


def speak_checked(voice: str, text: str, note: str, ident: str) -> bytes:
    """Satırı okutur; talimat da okunmuş görünürse bir kez yeniden dener."""
    raw = b""
    for _ in range(2):
        raw = generate(body_single(voice, text, note))
        with tempfile.TemporaryDirectory() as d:
            probe = pathlib.Path(d) / "p.wav"
            g.save_wav(probe, raw)
            if not g.read_notes(probe, text):
                return raw
        print(f"  {ident}: talimat okunmuş görünüyor, yeniden deneniyor")
    return raw


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dil", default="tr")
    ap.add_argument("--bolum", type=int, nargs="*", help="bölüm sıraları (0: açılış perdesi ile)")
    ap.add_argument("--kimlik", nargs="*", help="yalnız bu satırlar")
    ap.add_argument("--yeniden", action="store_true", help="var olanı yeniden üret")
    ap.add_argument("--kuru", action="store_true", help="üretmeden listele")
    a = ap.parse_args()

    lines = json.loads(pathlib.Path(f"build/ses/satirlar_{a.dil}.json").read_text())
    notes = json.loads(NOTES.read_text()) if NOTES.exists() else {}

    def wanted(e: dict) -> bool:
        if a.kimlik:
            return e["id"] in a.kimlik
        if a.bolum is not None:
            where = e["where"]
            if where == "prologue":
                return 0 in a.bolum
            n = where.split(":")[-1]
            return n.isdigit() and int(n) in a.bolum
        return True

    out_dir = pathlib.Path(f"assets/voice/{a.dil}")
    out_dir.mkdir(parents=True, exist_ok=True)
    todo = [e for e in lines if wanted(e)]
    print(f"{len(todo)} satır")
    for e in todo:
        out = out_dir / f"{e['id']}.mp3"
        if out.exists() and not a.yeniden:
            continue
        spec = notes.get(e["id"], {})
        voice = spec.get("ses", ROLE_VOICE[e["role"]])
        note = spec.get("not", "")
        text = PREFIX.sub("", e["text"])
        if a.kuru:
            print(f"{e['id']} {voice:12} {text[:70]}")
            continue
        parts = dialogue(text) if voice == "Leda+Charon" else None
        if voice == "Leda+Charon" and not any(w == "Usta" for w, _ in parts):
            voice, parts = "Leda", None
        if parts:
            # Hatıra: her parça kendi sesiyle ayrı okunur, sonra birleşir.
            with tempfile.TemporaryDirectory() as d:
                pieces = []
                for k, (who, line) in enumerate(parts):
                    v = "Leda" if who == "Saye" else "Charon"
                    role_note = (
                        note + " This part is Saye narrating."
                        if who == "Saye"
                        else note + " This part is the old master speaking his words."
                    )
                    raw = speak_checked(v, line, role_note, e["id"])
                    piece = pathlib.Path(d) / f"{k}.wav"
                    trimmed_wav(raw, piece)
                    pieces.append(piece)
                join_mp3(pieces, out)
            print(f"{out}  Leda+Charon  {text[:60]}")
            continue
        to_mp3(speak_checked(voice, text, note, e["id"]), out)
        print(f"{out}  {voice}  {text[:60]}")


if __name__ == "__main__":
    main()
