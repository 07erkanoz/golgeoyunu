#!/usr/bin/env python3
"""Perdeleri, Hikâye köprülerini, önsözü ve son perdeyi ElevenLabs ile
masalcı sesinde seslendirir (Türkçe Seyfullah, İngilizce David).

Önce satırlar çıkarılır:
  flutter test tools/preview/ses_satirlari_test.dart   → build/ses/satirlar_<dil>.json
Sonra:
  python3 tools/seslendir_eleven.py --dil tr                  # hepsi (var olanı geçer)
  python3 tools/seslendir_eleven.py --dil en --sahne prologue perde:3
  python3 tools/seslendir_eleven.py --dil tr --kimlik 4cfaca07 --yeniden

Reji tools/perde_metni/reji.json: her satıra bir duygu etiketi ve birkaç
masalcı durağı (üç nokta). Bunlar yalnız seslendirmeye gider; altyazı ve
dosya kimliği ekrandaki metinden türetilir. Her satır yazıya döktürülüp
metinle karşılaştırılır (tekrar, atlama, okunan etiket varsa yeniden).
Çıktı: assets/voice/<dil>/<kimlik>.mp3 (tek kanal, 32 kHz, 56 kbps, -18 LUFS).
Anahtar: ~/.config/golge-oyunu/elevenlabs.key (depoya girmez).
"""

import argparse
import difflib
import json
import pathlib
import re
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import seslendir as s  # noqa: E402  (sayılar, yazıya döküm, kalıntı silme)

VOICE = {"tr": "mF7tIc9VLrznhGooGjaT", "en": "WdZjiN0nNcik2LBjOHiv"}
MODEL = "eleven_v4"
SETTINGS = {"stability": 0.4, "similarity_boost": 0.8, "style": 0.5, "use_speaker_boost": True}
REJI = pathlib.Path("tools/perde_metni/reji.json")
# İngiliz ses Türkçe adları yazıldığı gibi okusun diye (yalnız seslendirmede).
EN_SAY = {"Hayalî": "Hayali", "Mevlânâ": "Mevlana", "Ülgen": "Ulgen"}
KEY = (pathlib.Path.home() / ".config/golge-oyunu/elevenlabs.key").read_text().strip()

NUMS = set(
    "bir iki üç dört beş altı yedi sekiz dokuz on yirmi otuz kırk elli altmış yetmiş "
    "seksen doksan yüz bin one two three four five six seven eight nine ten eleven "
    "twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty thirty "
    "forty fifty sixty seventy eighty ninety hundred thousand and".split()
)


def scenes(lang: str) -> dict[str, list[dict]]:
    lines = json.loads(pathlib.Path(f"build/ses/satirlar_{lang}.json").read_text())
    out: dict[str, list[dict]] = {}
    for e in lines:
        w = e["where"]
        if w in ("prologue", "epilogue") or w.startswith(("perde:", "kopru:")):
            if not s.is_title(e["text"]):
                out.setdefault(w, []).append(e)
    return out


def scripted(lang: str, sc: dict[str, list[dict]]) -> dict[str, list[str]]:
    """Her sahnenin seslendirme kopyası: etiket + durak + sayılar yazıyla."""
    r = json.loads(REJI.read_text())
    edits: dict[tuple[str, int], list[tuple[str, str]]] = {}
    for w, i, a, b in r["durak"].get(lang, []):
        edits.setdefault((w, i), []).append((a, b))
    out = {}
    for w, items in sc.items():
        tags = r["sahne"].get(w)
        if tags is None or len(tags) != len(items):
            sys.exit(f"{w}: reji {0 if tags is None else len(tags)} etiket, metin {len(items)} satır")
        texts = []
        for i, e in enumerate(items):
            t = s.words_for_numbers(s.spoken(e["text"], lang), lang)
            for a, b in edits.get((w, i), []):
                if a not in t:
                    sys.exit(f"{w}[{i}]: durak yeri bulunamadı: {a}")
                t = t.replace(a, b)
            if lang == "en":
                for a, b in EN_SAY.items():
                    t = t.replace(a, b)
            tag = r.get(f"etiket_{lang}", {}).get(tags[i]) or r["etiket"][tags[i]]
            texts.append(f"{tag} {t}")
        out[w] = texts
    return out


def plain(t: str) -> str:
    return re.sub(r"\[[^\]]*\]\s*", "", t)


def words(t: str) -> list[str]:
    t = t.lower().replace("’", "'").replace("â", "a").replace("î", "i").replace("û", "u")
    ws = re.findall(r"[a-zçğıöşü']+|\d+", t)
    return [w.strip("'") for w in ws if not w.isdigit() and w.strip("'") not in NUMS]


def check(heard: str, text: str) -> tuple[bool, float]:
    """Duyulan metinle okunacak metni söz söz karşılaştırır. Tekrar ve
    okunan etiket söz sayısını büyütür; atlama küçültür."""
    h, p = words(heard), words(plain(text))
    ratio = difflib.SequenceMatcher(None, h, p).ratio()
    return ratio >= 0.88 and abs(len(h) - len(p)) <= max(2, len(p) // 12), ratio


def tts(lang: str, text: str, prev: str | None, nxt: str | None) -> bytes:
    body = {"text": text, "model_id": MODEL, "voice_settings": SETTINGS}
    if prev:
        body["previous_text"] = plain(prev)
    if nxt:
        body["next_text"] = plain(nxt)
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{VOICE[lang]}?output_format=mp3_44100_128"
    for attempt in range(5):
        req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                     headers={"xi-api-key": KEY, "Content-Type": "application/json"})
        try:
            return urllib.request.urlopen(req, timeout=180).read()
        except urllib.error.HTTPError as e:
            msg = e.read()[:300]
            if e.code in (429, 500, 502, 503) and attempt < 4:
                time.sleep(10 * (attempt + 1))
                continue
            sys.exit(f"ElevenLabs {e.code}: {msg}")
        except (urllib.error.URLError, TimeoutError):
            time.sleep(10 * (attempt + 1))
    sys.exit("ElevenLabs yanıt vermedi")


def wav16(mp3: bytes) -> bytes:
    return subprocess.run(["ffmpeg", "-loglevel", "error", "-i", "pipe:0", "-ac", "1",
                           "-ar", "16000", "-f", "wav", "-"], input=mp3,
                          capture_output=True, check=True).stdout


def save(mp3: bytes, out: pathlib.Path) -> None:
    """Kalıntıyı siler, baş/son sessizliği kırpar, ses yüksekliğini eşitler."""
    with tempfile.TemporaryDirectory() as d:
        src = pathlib.Path(d) / "in.mp3"
        src.write_bytes(mp3)
        w = pathlib.Path(d) / "a.wav"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src),
                        "-ac", "1", "-ar", "32000", str(w)], check=True)
        s.drop_blips(w)
        af = ("silenceremove=start_periods=1:start_threshold=-48dB,"
              "areverse,silenceremove=start_periods=1:start_threshold=-48dB,areverse,"
              "loudnorm=I=-18:TP=-2:LRA=7,aresample=32000,apad=pad_dur=0.25")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(w), "-af", af,
                        "-ac", "1", "-ar", "32000", "-b:a", "56k", str(out)], check=True)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dil", default="tr")
    ap.add_argument("--sahne", nargs="*", help="yalnız bu sahneler (prologue, perde:3, kopru:5, epilogue)")
    ap.add_argument("--kimlik", nargs="*", help="yalnız bu satırlar")
    ap.add_argument("--yeniden", action="store_true", help="var olanı da yeniden üret")
    ap.add_argument("--kuru", action="store_true", help="üretmeden seslendirme kopyasını yaz")
    a = ap.parse_args()

    sc = scenes(a.dil)
    texts = scripted(a.dil, sc)
    out_dir = pathlib.Path(f"assets/voice/{a.dil}")
    done_file = pathlib.Path(f"build/ses/eleven_{a.dil}.json")
    done = json.loads(done_file.read_text()) if done_file.exists() else {}
    order = ["prologue"] + [f"{k}:{i}" for i in range(len(sc)) for k in ("perde", "kopru")] + ["epilogue"]
    bad = []
    for w in [w for w in order if w in sc]:
        if a.sahne and w not in a.sahne:
            continue
        items, tx = sc[w], texts[w]
        for i, e in enumerate(items):
            if a.kimlik and e["id"] not in a.kimlik:
                continue
            if a.kuru:
                print(f"{w} {e['id']} {tx[i]}")
                continue
            # Daha önce bu masalcı sesiyle üretildiyse geç (eski Gemini sesi değil).
            if not a.yeniden and done.get(e["id"]) == tx[i] and (out_dir / f"{e['id']}.mp3").exists():
                continue
            prev = tx[i - 1] if i > 0 else None
            nxt = tx[i + 1] if i + 1 < len(tx) else None
            best = None
            for attempt in range(4):
                mp3 = tts(a.dil, tx[i], prev, nxt)
                heard = s.transcribe(wav16(mp3))
                ok, score = check(heard, tx[i])
                if best is None or score > best[0]:
                    best = (score, mp3, heard)
                if ok:
                    break
                print(f"    {e['id']} yeniden ({score:.2f}): {heard[:90]}", flush=True)
            save(best[1], out_dir / f"{e['id']}.mp3")
            done[e["id"]] = tx[i]
            done_file.write_text(json.dumps(done, ensure_ascii=False, indent=1))
            mark = "" if best[0] >= 0.88 else "  <<< DENETLE"
            if mark:
                bad.append((w, e["id"], best[2]))
            print(f"  {w} {e['id']} {best[0]:.2f}  {plain(tx[i])[:60]}{mark}", flush=True)
    for w, i, h in bad:
        print(f"DENETLE {w} {i}: {h}")


if __name__ == "__main__":
    main()
