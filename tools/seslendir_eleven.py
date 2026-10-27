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

# Kahramanların sesleri ve kimin konuştuğu: tırnak dışı anlatıcının (Seyfullah /
# David), tırnak içi konuşanın kendi sesiyle okunur, parçalar birleşir.
CAST = json.loads(pathlib.Path("tools/perde_metni/kadro.json").read_text())["ses"]
SPEAKERS = json.loads(pathlib.Path("tools/perde_metni/konusanlar.json").read_text())
METIN = json.loads(pathlib.Path("tools/perde_metni/metin.json").read_text())
MODEL = "eleven_v4"
SETTINGS = {"stability": 0.4, "similarity_boost": 0.8, "style": 0.5, "use_speaker_boost": True}
REJI = pathlib.Path("tools/perde_metni/reji.json")
# İngiliz ses Türkçe adları yazıldığı gibi okusun diye (yalnız seslendirmede).
EN_SAY = {"Hayalî": "Hayali", "Mevlânâ": "Mevlana", "Ülgen": "Ulgen", "Yel Ana": "Yell Ana"}
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


# Etiket yalnız ardındaki cümleye işliyor; satırın her cümlesine masalcı
# tarifi konur (--cumle). Kısa etiket yerine önsözde işe yarayan türden tarif.
RICH = {
    "[slowly, like an old storyteller beginning a tale]": "[slowly, like an old storyteller beginning a tale]",
    "[warm storyteller]": "[warmly, as a storyteller]",
    "[low, tense]": "[low, tense, as a storyteller]",
    "[low, ominous]": "[darkly, as a storyteller]",
    "[sad, restrained]": "[sadly, holding back tears]",
    "[quiet wonder]": "[softly, full of wonder]",
    "[gentle, hopeful]": "[gently, with hope]",
    "[quiet resolve]": "[quietly, with courage]",
    "[urgent, controlled]": "[urgently, excited]",
    "[tender, moved]": "[tenderly, deeply moved]",
    "[relieved, softer]": "[with relief, softly]",
    "[faint smile]": "[smiling, playful]",
    "[hushed, intimate]": "[hushed, like a secret]",
    "[gentle, peaceful]": "[peacefully, gently]",
    "[tender, voice trembling]": "[tenderly, voice trembling]",
    "[weary, gentle]": "[wearily, gently]",
    "[tender, quiet conviction]": "[tenderly, with conviction]",
    "[quiet, plain]": "[quietly, plainly]",
    "[low, slow]": "[slowly, deep and low]",
    "[joyful, excited]": "[joyfully, excited]",
    "[cheerful, playful]": "[cheerfully, playfully]",
}
CUMLE = False
# A yolu (--ayri): anlatıcının her cümlesi ayrı ve bağlamsız istek; her biri
# "ilk cümle" gibi başlar, ses satırın sonuna dek düzleşmez.
AYRI = False
BAGLI = False
STORY = {
    "[slowly, like an old storyteller beginning a tale]": "[slowly, like an old storyteller beginning a tale]",
    "[warm storyteller]": "[warmly, like an old storyteller]",
    "[low, tense]": "[tense, low, like an old storyteller]",
    "[low, ominous]": "[darkly, like an old storyteller]",
    "[sad, restrained]": "[sadly, like an old storyteller]",
    "[quiet wonder]": "[in wonder, like an old storyteller]",
    "[gentle, hopeful]": "[hopefully, like an old storyteller]",
    "[quiet resolve]": "[bravely, like an old storyteller]",
    "[urgent, controlled]": "[urgently, like an old storyteller]",
    "[tender, moved]": "[tenderly, like an old storyteller]",
    "[relieved, softer]": "[relieved, like an old storyteller]",
    "[faint smile]": "[smiling, like an old storyteller]",
    "[hushed, intimate]": "[hushed, like an old storyteller]",
    "[gentle, peaceful]": "[peacefully, like an old storyteller]",
    "[tender, voice trembling]": "[trembling, like an old storyteller]",
    "[weary, gentle]": "[wearily, like an old storyteller]",
    "[tender, quiet conviction]": "[tenderly, like an old storyteller]",
    "[quiet, plain]": "[quietly, like an old storyteller]",
    "[low, slow]": "[slowly, like an old storyteller]",
    "[joyful, excited]": "[joyfully, like an old storyteller]",
    "[cheerful, playful]": "[playfully, like an old storyteller]",
}


def narrator_pieces(lang: str, seg: str, before: str | None = None, after: str | None = None) -> list[bytes]:
    """A yolu: parçanın cümleleri tek tek, masalcı tarifiyle. Bağlı yolda
    (--bagli) her cümleye önceki ve sonraki cümle bağlam olarak verilir; sıfırdan
    başlayan cümlenin başına ses modeli fazladan hece/nefes ekliyordu."""
    m = re.match(r"(\[[^\]]*\])\s*(.*)", seg, re.S)
    tag, body = (m.group(1), m.group(2)) if m else ("[warm storyteller]", seg)
    rich = STORY.get(tag, tag)
    out = []
    snts = sentences(body)
    for j, snt in enumerate(snts):
        prev = nxt = None
        if BAGLI:
            prev = " ".join(snts[max(0, j - 2):j]) or before
            nxt = snts[j + 1] if j + 1 < len(snts) else after
        best = None
        for attempt in range(4):
            mp3 = tts(lang, f"{rich} {snt}", prev, nxt, "anlatici")
            heard = s.transcribe(wav16(mp3))
            bad = doubled(heard, snt)
            if not bad:
                best = mp3
                break
            print(f"      cümle yeniden ({bad}): {heard[:70]}", flush=True)
            best = best or mp3
        out.append(best)
    return out


def doubled(heard: str, text: str) -> str:
    """İkileme ya da fazladan söz: duyulan, metinden uzun ya da yan yana
    yinelenen söz/hece varsa nedenini döndürür."""
    h, p = words(heard), words(text)
    # Bitişik/ayrık yazım farkı ("ateşböcekleri" / "ateş böcekleri") fazla söz
    # sayılmasın: uzunluk harf üzerinden ölçülür.
    hl, pl = len("".join(h)), len("".join(p))
    if hl > pl * 1.12 + 3:
        return f"{hl - pl} fazla harf"
    pairs = set(zip(p, p[1:]))
    for a, b in zip(h, h[1:]):
        # Metnin kendi ikilemeleri ("ev ev", "birer birer") hata değil.
        if (a, b) in pairs:
            continue
        if a == b or (len(a) >= 2 and b.startswith(a) and a not in p):
            return f"ikileme: {a} {b}"
    if difflib.SequenceMatcher(None, "".join(h), "".join(p)).ratio() < 0.8:
        return "eşleşmedi"
    return ""


def sentences(body: str) -> list[str]:
    """Yalnız gerçek cümle sonlarında (. ! ?) böler; üç nokta, iki nokta ve
    noktalı virgül cümlenin içinde kalır (tek kelimelik parça ikileniyordu).
    Kısa parçalar komşusuna eklenir."""
    raw = [s for s in re.split(r"(?<=[.!?])\s+", body.strip()) if re.search(r"\w", s)]
    out: list[str] = []
    for s in raw:
        if out and (len(s) < 25 or len(out[-1]) < 25):
            out[-1] = out[-1] + " " + s
        else:
            out.append(s)
    return out


def per_sentence(tag: str, text: str) -> str:
    """Anlatıcı parçasında her cümlenin başına tarif."""
    rich = RICH.get(tag, tag)
    parts = re.split(r"(?<=[.!?…])\s+", text.strip())
    return " ".join(f"{rich} {p}" for p in parts if p)


SPEECH_TAG = re.compile(
    r"^(dedi|derdi|demişti|diye|sordu|fısıldadı|bağırdı|seslendi|said|asked|whispered|cried|he said|she said|it said)\b",
    re.I,
)


def full_index(lang: str, w: str, i: int) -> int:
    """Başlık kartları sayılmayan satır sırasından metin.json'daki sıraya."""
    lines = METIN[lang][w] if w in ("prologue", "epilogue") else METIN[lang][w.split(":")[0]][w.split(":")[1]]
    k = -1
    for j, line in enumerate(lines):
        if not s.is_title(line):
            k += 1
            if k == i:
                return j
    return i


def segments(lang: str, w: str, i: int, text: str) -> list[tuple[str, str]]:
    """Satırı (konuşan, seslendirme metni) parçalarına böler; her parça
    satırın duygu etiketini taşır."""
    m = re.match(r"(\[[^\]]*\])\s*(.*)", text, re.S)
    tag, body = (m.group(1), m.group(2)) if m else ("", text)
    spec = SPEAKERS.get(w, {}).get(str(full_index(lang, w, i)))
    if not spec:
        return [("anlatici", per_sentence(tag, body) if CUMLE else text)]
    out: list[tuple[str, str]] = []
    n = 0
    for part in re.split(r"(“[^”]*”)", body):
        if part.startswith("“"):
            who = spec if isinstance(spec, str) else spec[min(n, len(spec) - 1)]
            n += 1
            piece = part.strip("“”").strip()
        else:
            who = "anlatici"
            piece = part.strip().lstrip(",;").strip()
            # Kahraman kendi sesiyle konuşurken "dedi", "diye fısıldadı
            # Hüdhüd", "said the Hoopoe" gibi kısa ekler okunmaz (altyazıda
            # kalır): tek başına üretilen kırıntı ses ikileniyordu.
            if SPEECH_TAG.match(piece) and len(piece.split()) <= 4:
                continue
        if not re.search(r"\w", piece):
            continue
        if out and out[-1][0] == who:
            prev = out[-1][1]
            # Arada okunmayan "dedi" kalktıysa: "istemiş, Her gece" → "istemiş. Her gece"
            if prev.endswith(",") and piece[:1].isupper():
                prev = prev[:-1] + "."
            out[-1] = (who, prev + " " + piece)
        else:
            out.append((who, piece))
    out = [(who, p[:-1] + "." if p.endswith(",") else p) for who, p in out]
    if CUMLE:
        return [(who, per_sentence(tag, piece) if who == "anlatici" else f"{tag} {piece}".strip()) for who, piece in out]
    return [(who, f"{tag} {piece}".strip()) for who, piece in out]


OYUN_TAG = {"saye": "[soft, nostalgic, gentle]", "usta": "[old, warm, gentle]", "hudhud": "[warm, wise, confidential]",
            "anlatici": "[warm storyteller]", "akana": "[calm, luminous]", "demirci": "[hearty, encouraging]",
            "calkuyruk": "[brave, urgent]", "tulpar": "[noble, proud]"}
# Oyun içinde kadrodaki bir kahramanın konuştuğu sözler: tırnak dışı anlatıcı.
OYUN_SOZ = {"soz:cameo_akAna": "akana", "soz:cameo_demirci": "demirci",
            "soz:calkuyrukMount": "calkuyruk", "soz:tulparMount": "tulpar"}
ASKED = re.compile(r"^\W*(dedim|sordum|diye sordum|I asked|I said)\b", re.I)


def game_segments(lang: str, e: dict) -> list[tuple[str, str]] | None:
    """Oyun içi satırlar: hatıralarda anlatım Sâye'nin, tırnak içi ustanın
    (Sâye'nin kendi soruları Sâye'nin); Gökyolu ve Kaf fısıltıları Hüdhüd'ün."""
    w, text = e["where"], e["text"]
    if w in ("fisilti:2", "fisilti:3"):
        t = s.words_for_numbers(text, lang)
        return [("hudhud", f"{OYUN_TAG['hudhud']} {t}")]
    if w in OYUN_SOZ:
        out = []
        for part in re.split(r"([\"“][^\"“”]*[\"”])", s.words_for_numbers(text, lang)):
            who = OYUN_SOZ[w] if part[:1] in ('"', "“") else "anlatici"
            piece = part.strip('"“” ').rstrip(":").strip()
            # Yalnız konuşanın adı ("Demirci:") okunmaz; ses zaten onun.
            if re.search(r"\w", piece) and (who != "anlatici" or len(piece.split()) > 1):
                out.append((who, f"{OYUN_TAG[who]} {piece}"))
        return out
    if e["role"] != "hatira":
        return None
    t = s.words_for_numbers(s.PREFIX.sub("", text), lang)
    if lang == "en":
        for a, b in EN_SAY.items():
            t = t.replace(a, b)
    parts = re.split(r"([\"“][^\"“”]*[\"”])", t)
    out: list[tuple[str, str]] = []
    for k, part in enumerate(parts):
        if part[:1] in ('"', "“"):
            q = part.strip('"“” ')
            after = parts[k + 1] if k + 1 < len(parts) else ""
            mine = ASKED.match(after) or re.match(r"^(Usta|Master)\b", q) or re.search(r"(usta|master)\?$", q, re.I)
            who, piece = ("saye" if mine else "usta"), q
        else:
            who, piece = "saye", part.strip().lstrip(",;").strip()
            if SPEECH_TAG.match(piece) and len(piece.split()) <= 3:
                continue
        if not re.search(r"\w", piece):
            continue
        if out and out[-1][0] == who:
            out[-1] = (who, out[-1][1] + " " + piece)
        else:
            out.append((who, piece))
    out = [(who, p[:-1] + "." if p.endswith(",") else p) for who, p in out]
    return [(who, f"{OYUN_TAG[who]} {p}") for who, p in out]


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


def tts(lang: str, text: str, prev: str | None, nxt: str | None, who: str = "anlatici") -> bytes:
    body = {"text": text, "model_id": MODEL, "voice_settings": SETTINGS}
    if lang == "tr":
        body["language_code"] = "tr"
    if prev:
        body["previous_text"] = plain(prev)
    if nxt:
        body["next_text"] = plain(nxt)
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{CAST[who][lang]}?output_format=mp3_44100_128"
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


def join(pieces: list[bytes]) -> bytes:
    """Parçaları kırpıp her birinin ses yüksekliğini eşitler, aralarına kısa
    bir durak koyarak birleştirir (MP3)."""
    if len(pieces) == 1:
        return pieces[0]
    with tempfile.TemporaryDirectory() as d:
        ins, flt = [], []
        for j, mp3 in enumerate(pieces):
            f = pathlib.Path(d) / f"{j}.mp3"
            f.write_bytes(mp3)
            ins += ["-i", str(f)]
            # Kesilen uçlara kısa yumuşak geçiş: yoksa birleşme yerinde "çıt"
            # oluşuyordu (plak cızırtısı gibi duyuldu).
            flt.append(f"[{j}:a]aresample=32000,silenceremove=start_periods=1:start_threshold=-48dB,"
                       "areverse,silenceremove=start_periods=1:start_threshold=-48dB,"
                       "afade=t=in:d=0.015,areverse,afade=t=in:d=0.01,"
                       f"loudnorm=I=-18:TP=-2:LRA=7,aresample=32000,apad=pad_dur=0.3[a{j}]")
        flt.append("".join(f"[a{j}]" for j in range(len(pieces))) + f"concat=n={len(pieces)}:v=0:a=1[o]")
        out = pathlib.Path(d) / "o.mp3"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", *ins, "-filter_complex", ";".join(flt),
                        "-map", "[o]", "-ac", "1", "-b:a", "128k", str(out)], check=True)
        return out.read_bytes()


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
    ap.add_argument("--cumle", action="store_true", help="anlatıcının her cümlesine masalcı tarifi")
    ap.add_argument("--ayri", action="store_true", help="A yolu: anlatıcının her cümlesi ayrı, bağlamsız")
    ap.add_argument("--bagli", action="store_true", help="A yolu, ama her cümleye önceki/sonraki cümle bağlam")
    ap.add_argument("--deneme", help="oyuna yazmadan bu klasöre üret (karşılaştırma)")
    ap.add_argument("--oyunici", action="store_true", help="hatıralar (Sâye ve usta) ve Gökyolu/Kaf fısıltıları (Hüdhüd)")
    a = ap.parse_args()
    if a.oyunici:
        return game_lines(a)
    global CUMLE, AYRI, BAGLI
    CUMLE = a.cumle
    BAGLI = a.bagli
    AYRI = a.ayri or BAGLI

    sc = scenes(a.dil)
    texts = scripted(a.dil, sc)
    out_dir = pathlib.Path(a.deneme or f"assets/voice/{a.dil}")
    out_dir.mkdir(parents=True, exist_ok=True)
    done_file = pathlib.Path(f"build/ses/eleven_{a.dil}.json" if not a.deneme else f"{a.deneme}/done.json")
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
            segs = segments(a.dil, w, i, tx[i])
            sig = tx[i] + "|" + ",".join(who for who, _ in segs)
            if AYRI and any(who == "anlatici" for who, _ in segs):
                sig += "|bagli" if BAGLI else "|ayri"
            if a.kuru:
                print(f"{w} {e['id']} " + " ‖ ".join(f"{who}: {p}" for who, p in segs))
                continue
            # Daha önce bu kadroyla üretildiyse geç.
            if not a.yeniden and (out_dir / f"{e['id']}.mp3").exists():
                old = done.get(e["id"], "")
                # Aynı metin A yoluyla zaten üretildiyse ("dedi" ekleri sonradan
                # çıkarılsa da) yeniden üretilmez.
                if old == sig or (AYRI and old.startswith(tx[i] + "|") and old.endswith("|ayri")):
                    continue
                # A yolu yalnız anlatıcıyı yeniler; anlatıcısız satırlar kalır.
                if AYRI and not any(who == "anlatici" for who, _ in segs):
                    continue
            prev = tx[i - 1] if i > 0 else None
            nxt = tx[i + 1] if i + 1 < len(tx) else None
            best = None
            for attempt in range(3 if AYRI else 4):
                pieces = []
                for k, (who, piece) in enumerate(segs):
                    p_prev = segs[k - 1][1] if k > 0 else prev
                    p_next = segs[k + 1][1] if k + 1 < len(segs) else nxt
                    if AYRI and who == "anlatici":
                        pieces += narrator_pieces(a.dil, piece, p_prev and plain(p_prev), p_next and plain(p_next))
                        continue
                    pieces.append(tts(a.dil, piece, p_prev, p_next, who))
                mp3 = join(pieces)
                heard = s.transcribe(wav16(mp3))
                # Beklenen: seslendirilen parçalar (okunmayan "dedi" ekleri hariç).
                ok, score = check(heard, " ".join(plain(p) for _, p in segs))
                if best is None or score > best[0]:
                    best = (score, mp3, heard)
                if ok:
                    break
                print(f"    {e['id']} yeniden ({score:.2f}): {heard[:90]}", flush=True)
            save(best[1], out_dir / f"{e['id']}.mp3")
            done[e["id"]] = sig
            done_file.write_text(json.dumps(done, ensure_ascii=False, indent=1))
            mark = "" if best[0] >= 0.88 else "  <<< DENETLE"
            if mark:
                bad.append((w, e["id"], best[2]))
            print(f"  {w} {e['id']} {best[0]:.2f}  {plain(tx[i])[:60]}{mark}", flush=True)
    for w, i, h in bad:
        print(f"DENETLE {w} {i}: {h}")


def game_lines(a) -> None:
    lines = json.loads(pathlib.Path(f"build/ses/satirlar_{a.dil}.json").read_text())
    out_dir = pathlib.Path(f"assets/voice/{a.dil}")
    done_file = pathlib.Path(f"build/ses/eleven_oyun_{a.dil}.json")
    done = json.loads(done_file.read_text()) if done_file.exists() else {}
    bad = []
    for e in lines:
        segs = game_segments(a.dil, e)
        if not segs or (a.kimlik and e["id"] not in a.kimlik):
            continue
        sig = " ‖ ".join(f"{who}: {p}" for who, p in segs)
        if a.kuru:
            print(f"{e['where']} {e['id']} {sig}")
            continue
        if not a.yeniden and done.get(e["id"]) == sig and (out_dir / f"{e['id']}.mp3").exists():
            continue
        whole = " ".join(plain(p) for _, p in segs)
        best = None
        for attempt in range(4):
            pieces = []
            for k, (who, piece) in enumerate(segs):
                p_prev = segs[k - 1][1] if k > 0 else None
                p_next = segs[k + 1][1] if k + 1 < len(segs) else None
                pieces.append(tts(a.dil, piece, p_prev, p_next, who))
            mp3 = join(pieces)
            heard = s.transcribe(wav16(mp3))
            ok, score = check(heard, whole)
            if best is None or score > best[0]:
                best = (score, mp3, heard)
            if ok:
                break
            print(f"    {e['id']} yeniden ({score:.2f}): {heard[:90]}", flush=True)
        save(best[1], out_dir / f"{e['id']}.mp3")
        done[e["id"]] = sig
        done_file.write_text(json.dumps(done, ensure_ascii=False, indent=1))
        mark = "" if best[0] >= 0.88 else "  <<< DENETLE"
        if mark:
            bad.append((e["where"], e["id"], best[2]))
        print(f"  {e['where']} {e['id']} {best[0]:.2f}  {whole[:60]}{mark}", flush=True)
    for w, i, h in bad:
        print(f"DENETLE {w} {i}: {h}")


if __name__ == "__main__":
    main()
