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
NOTES = pathlib.Path("tools/ses_notlari")  # her bölüm grubu ayrı dosya

# Seslerin kalıcı tarifi; satırın kendi notu bunun üstüne eklenir.
PROFILE = {
    # Tek ve sabit bir sicil: satır notları yalnız vurguyu, durağı ve
    # tempoyu değiştirir; anlatıcı satırdan satıra mod değiştirmez.
    "Charon": (
        "Voice: the very old master of a Turkish shadow theatre (hayali) "
        "telling an epic legend: very old, full and deep, weary, dramatic. "
        "Keep ONE consistent register in every line; never switch into a "
        "casual, chatty or soft 'poetry reading' mode; fear and excitement "
        "stay inside the same voice (lower or faster, never a different "
        "narrator). Pace: slow and heavy but flowing, never dragging. Pause "
        "at every ellipsis."
    ),
    "Enceladus": (
        "Voice: a mythic, otherworldly whisper from the shadows, close to the "
        "listener. Keep the same register in every line: grave and epic even "
        "when quiet. Pace: natural, not slow."
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

# Ozanın dizesini ozan kendisi söyler: "Ozan der ki:" ekranda kalır (kimin
# konuştuğunu gösterir), seste okunmaz.
BARD = re.compile(r"^(Ozan der ki|The bard says)\s*:\s*")


BIR = ["", "bir", "iki", "üç", "dört", "beş", "altı", "yedi", "sekiz", "dokuz"]
ON = ["", "on", "yirmi", "otuz", "kırk", "elli", "altmış", "yetmiş", "seksen", "doksan"]


def tr_number(n: int) -> str:
    """Sayının Türkçe okunuşu (0 – 999999): 1660 → bin altı yüz altmış."""
    if n == 0:
        return "sıfır"
    out = []
    thousands, rest = divmod(n, 1000)
    if thousands:
        out.append("bin" if thousands == 1 else tr_number(thousands) + " bin")
    hundreds, rest = divmod(rest, 100)
    if hundreds:
        out.append("yüz" if hundreds == 1 else BIR[hundreds] + " yüz")
    tens, ones = divmod(rest, 10)
    if tens:
        out.append(ON[tens])
    if ones:
        out.append(BIR[ones])
    return " ".join(out)


def words_for_numbers(text: str, lang: str) -> str:
    """Rakamlar yazıyla okunur (model rakamı her zaman doğru okumuyor)."""
    if lang != "tr":
        return text
    return re.sub(r"\d+", lambda m: tr_number(int(m.group())), text)


def is_title(text: str) -> bool:
    """Perde başlığı (tamamı büyük harf: "GÖLGE OYUNU", "V · AĞRI"):
    seslendirilmez; göstermelik levhada görünür, o an ney çalar."""
    return text == text.upper() and any(c.isalpha() for c in text)


ROMAN = {"I": 1, "V": 5, "X": 10, "L": 50}
ORD_TR = ["", "Birinci", "İkinci", "Üçüncü", "Dördüncü", "Beşinci", "Altıncı",
          "Yedinci", "Sekizinci", "Dokuzuncu", "Onuncu", "On birinci",
          "On ikinci", "On üçüncü", "On dördüncü", "On beşinci", "On altıncı",
          "On yedinci", "On sekizinci", "On dokuzuncu", "Yirminci"]
NUM_EN = ["", "one", "two", "three", "four", "five", "six", "seven", "eight",
          "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen",
          "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]


def roman(word: str) -> int | None:
    if not word or any(c not in ROMAN for c in word):
        return None
    n = 0
    for i, c in enumerate(word):
        v = ROMAN[c]
        n += -v if i + 1 < len(word) and ROMAN[word[i + 1]] > v else v
    return n if 0 < n < len(ORD_TR) else None


def spoken(text: str, lang: str = "tr") -> str:
    """Okunacak biçim: tamamı büyük harfli perde başlıkları ("GÖLGE OYUNU",
    "V · AĞRI") Türkçe kurala göre küçültülür; büyük harfi model harf harf
    ya da tuhaf okuyordu. " · " duraklama olur."""
    if text != text.upper() or not any(c.isalpha() for c in text):
        return text
    # Başta Roma rakamı: bölümün sırası söylenir.
    head, sep, tail = text.partition(" · ")
    n = roman(head.strip()) if sep else None
    if n:
        lead = f"{ORD_TR[n]} bölüm" if lang == "tr" else f"Chapter {NUM_EN[n]}"
        return lead + ", " + spoken(tail, lang).rstrip(".") + "."
    low = text.replace("I", "ı").replace("İ", "i").lower() if lang == "tr" else text.lower()
    words = []
    for w in low.split(" "):
        if w and w[0] == "i":
            w = "İ" + w[1:]
        elif w and w[0] == "ı":
            w = "I" + w[1:]
        elif w:
            w = w[0].upper() + w[1:]
        words.append(w)
    return " ".join(words).replace(" · ", ", ") + "."
QUOTE = re.compile(r"[\"“”]([^\"“”]+)[\"“”]")


# Dil açıkça söylenir: kısa satırlarda ("Gölge Oyunu") model dili kendisi
# tahmin ediyor, İngilizce sanıyordu.
LANG = {
    "tr": ("tr-TR", "Language: Turkish. Native Turkish pronunciation and intonation."),
    "en": ("en-US", "Language: English."),
}
DIL = "tr"


def body_single(voice: str, text: str, note: str) -> dict:
    return {
        "contents": [
            {
                "parts": [
                    {
                        "text": "# AUDIO PROFILE: " + voice + "\n"
                        "## THE SCENE: Behind a lit shadow-play screen.\n"
                        "### DIRECTOR'S NOTES\n"
                        + LANG[DIL][1]
                        + "\n"
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
                "languageCode": LANG[DIL][0],
                "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}},
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
        # Sâye'nin kendi sözü ("…" dedim / sordum; "Usta, …"): onun sesiyle.
        after = text[m.end() : m.end() + 24].lower()
        low = said.lower()
        mine = (
            re.match(r"\s*,?\s*(diye )?(dedim|sordum|i said|i asked)", after)
            or low.startswith(("usta", "master"))
            or re.search(r",\s*(usta|master)\s*[?.!…]*$", low)
        )
        parts.append(("Saye" if mine else "Usta", said))
        at = m.end()
    rest = text[at:].strip(" ,")
    if rest:
        parts.append(("Saye", rest))
    # Art arda aynı konuşmacı: tek parça ("Kim bu?" dedim.).
    merged: list[tuple[str, str]] = []
    for who, line in parts:
        if merged and merged[-1][0] == who:
            merged[-1] = (who, merged[-1][1] + " " + line)
        else:
            merged.append((who, line))
    return merged


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
    import time

    for _ in range(4):
        t0 = time.time()
        r = g.call(f"/models/{MODEL}:generateContent", body)
        print(f"    ses geldi: {time.time() - t0:.0f} sn", flush=True)
        try:
            r["candidates"][0]["content"]["parts"][0]["inlineData"]["data"]
            break
        except (KeyError, IndexError, TypeError):
            print("    boş ses yanıtı, yeniden", flush=True)
            time.sleep(3)
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


def drop_blips(path: pathlib.Path) -> None:
    """Baştaki ve sondaki kısa kalıntıları (tık, nefes) siler: ana
    anlatımdan 0,5 sn'den uzun sessizlikle ayrılan, 0,35 sn'den kısa ses."""
    import array
    import math
    import wave

    with wave.open(str(path)) as f:
        rate, ch, sw = f.getframerate(), f.getnchannels(), f.getsampwidth()
        a = array.array("h", f.readframes(f.getnframes()))
    win = rate // 50
    loud = [
        math.sqrt(sum(x * x for x in a[i : i + win]) / win) > 350
        for i in range(0, len(a) - win, win)
    ]
    segs = []
    st = None
    for k, v in enumerate(loud + [False]):
        if v and st is None:
            st = k
        elif not v and st is not None:
            segs.append([st, k])
            st = None
    changed = False
    while len(segs) > 1 and segs[-1][1] - segs[-1][0] < 18 and segs[-1][0] - segs[-2][1] >= 25:
        segs.pop()
        changed = True
    while len(segs) > 1 and segs[0][1] - segs[0][0] < 18 and segs[1][0] - segs[0][1] >= 25:
        segs.pop(0)
        changed = True
    if not changed or not segs:
        return
    start = max(0, segs[0][0] - 5) * win
    end = min(len(a), (segs[-1][1] + 5) * win)
    with wave.open(str(path), "wb") as f:
        f.setnchannels(ch)
        f.setsampwidth(sw)
        f.setframerate(rate)
        f.writeframes(a[start:end].tobytes())


def to_mp3(raw: bytes, out: pathlib.Path) -> None:
    """Gelen sesi MP3'e çevirir; baştaki ve sondaki sessizliği kırpar."""
    with tempfile.TemporaryDirectory() as d:
        src = pathlib.Path(d) / "in.wav"
        g.save_wav(src, raw)
        # Model bazen sona tık ya da nefes bırakıyor: kırpmadan önce silinir.
        plain = pathlib.Path(d) / "plain.wav"
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(src),
                        "-ac", "1", "-ar", "24000", str(plain)], check=True)
        drop_blips(plain)
        src = plain
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


# ------------------------------------------------------------ toplu perde
# Bir perdenin satırları tek istekte, tek kesintisiz anlatım olarak okunur;
# sonra satır aralarındaki en uzun sessizliklerden bölünür. Satırlar ayrı
# ayrı üretilince model her seferinde sesi biraz farklı yorumluyordu
# (tonu ve ritmi satırdan satıra değişiyordu).

# Sahnenin oyunculuk tarifi (sahne kimliği → kim, ne anlatıyor, ne
# hissediyor). "Oku" değil "oyna": duygu sahneyle birlikte anlatılınca
# model dramatik okuyor; yalnız teknik notlarla düz okuyordu.
SCENES = pathlib.Path("tools/ses_sahneleri")  # her grup ayrı dosya

# Tarifi yazılmamış sahnelerin varsayılanı (sahne kimliğinin önekine göre).
DEFAULT_SCENES = {
    "ozan": (
        "The very old bard (ozan), the same old master, recites one of his own "
        "ancient sayings by the fire, as he has said it many times: weighty, "
        "proud and wise, every word chosen. Perform it like an epic verse."
    ),
    "fisilti": (
        "Late at night, at the foot of a sacred Umay tree hung with white rags, "
        "the very old master Hayali tells a traveller who has stopped to rest "
        "the legend of this very place: wonder, gravity and the weight of "
        "ancient memory. Perform it, do not read it."
    ),
}

# Yalnız bu satırlar (boşsa sahnenin hepsi).
ONLY_IDS: set[str] = set()

# Bu andan yeni dosyalar yeni yöntemle üretilmiştir: yeniden yapılmaz.
SKIP_NEWER = 0.0

SCENE_NOTE = (
    "Perform it, do not read it: a dramatic, epic storyteller. Same narrator "
    "and same voice from the first paragraph to the last, but play each "
    "paragraph's emotion fully as directed below. Leave a pause of about one "
    "and a half seconds between paragraphs."
)


def body_scene(voice: str, paras: list[str], notes: list[str], scene: str = "") -> dict:
    marks = "\n".join(
        f"Paragraph {k + 1}: {n}" for k, n in enumerate(notes) if n
    )
    return {
        "contents": [
            {
                "parts": [
                    {
                        "text": "# AUDIO PROFILE: Hayali, a very old Turkish shadow-play master\n"
                        "## THE SCENE: " + (scene or "Late at night, behind the lamp-lit screen, the old master tells a legend.") + "\n"
                        "### DIRECTOR'S NOTES\n"
                        + LANG[DIL][1] + "\n" + PROFILE[voice] + "\n"
                        + SCENE_NOTE + "\n" + marks
                        + "\n#### TRANSCRIPT\n" + "\n\n".join(paras)
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "languageCode": LANG[DIL][0],
                "voiceConfig": {"prebuiltVoiceConfig": {"voiceName": voice}},
            },
        },
    }


ASR_MODEL = "gemini-3.8-flash"


def _wav_bytes(samples, rate: int) -> bytes:
    import io
    import wave

    buf = io.BytesIO()
    with wave.open(buf, "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(rate)
        f.writeframes(samples.tobytes())
    return buf.getvalue()


def transcribe(wav: bytes) -> str:
    """Parçayı yazıya döker (doğrulama ve hizalama için)."""
    import base64

    r = g.call(
        f"/models/{ASR_MODEL}:generateContent",
        {
            "contents": [
                {
                    "parts": [
                        {"inlineData": {"mimeType": "audio/wav",
                                        "data": base64.b64encode(wav).decode()}},
                        {"text": "Bu ses kaydını harfi harfine yazıya dök. "
                                 "Yalnızca dökümü yaz; ses yoksa boş bırak."},
                    ]
                }
            ]
        },
    )
    # Boş yanıt (güvenlik süzgeci ya da geçici hata): döküm yok sayılır,
    # satır yeniden üretilir.
    cands = r.get("candidates") or [{}]
    parts = cands[0].get("content", {}).get("parts", [])
    return " ".join(p.get("text", "") for p in parts).strip()


def _norm(t: str) -> str:
    # Dökümdeki rakamlar yazıya çevrilir ("1660" = "bin altı yüz altmış").
    t = re.sub(r"\d+", lambda m: tr_number(int(m.group())), t)
    t = t.replace("I", "ı").replace("İ", "i").lower()
    return re.sub(r"[^\wçğıöşüâîû ]+", " ", t)


def _sim(a: str, b: str) -> float:
    import difflib

    # autojunk kapalı: açıkken 200 karakterden uzun metinlerde sık harfler
    # yok sayılıyor, doğru okunan uzun satır düşük puan alıyordu.
    return difflib.SequenceMatcher(None, _norm(a), _norm(b), autojunk=False).ratio()


def split_scene(raw: bytes, paras: list[str]) -> list[bytes] | None:
    """Sahneyi paragraflara böler. Kayıt bütün sessizliklerden küçük
    parçalara ayrılır, her parça yazıya dökülür, parçalar sırayla
    paragraflara metin benzerliğiyle eşlenir (kesim ne söylendiğine göre).
    Bir paragrafın dökümü metnine yeterince benzemezse None."""
    import array
    import math
    import wave

    with tempfile.TemporaryDirectory() as d:
        w = pathlib.Path(d) / "s.wav"
        g.save_wav(w, raw)
        with wave.open(str(w)) as f:
            rate = f.getframerate()
            a = array.array("h", f.readframes(f.getnframes()))
    win = rate // 50  # 20 ms
    quiet = [
        math.sqrt(sum(x * x for x in a[i : i + win]) / win) < 350
        for i in range(0, len(a) - win, win)
    ]
    # Parça sınırları: 0,3 sn'den uzun sessizliklerin ortası (durağın
    # uzunluğu da tutulur).
    cuts = [(0, 99.0)]
    st = None
    for k, q in enumerate(quiet + [False]):
        if q and st is None:
            st = k
        elif not q and st is not None:
            if k - st >= 15 and st > 0:
                cuts.append((((st + k) // 2) * win, (k - st) / 50))
            st = None
    cuts.append((len(a), 99.0))
    # Kısa duraklarla ayrılmış parçalar birleşir (dramatik okumada çok kısa
    # durak olur; 70 parçayı tek tek yazıya dökmek dakikalar sürüyordu).
    # Paragraf arası (0,6 sn'den uzun durak) hep sınır kalır.
    bounds = [cuts[0][0]]
    for pos, gap in cuts[1:-1]:
        if gap >= 0.6 or pos - bounds[-1] > rate * 12:
            bounds.append(pos)
    bounds.append(len(a))
    chunks = [a[bounds[i] : bounds[i + 1]] for i in range(len(bounds) - 1)]
    chunks = [c for c in chunks if len(c) > rate // 10]
    if len(chunks) < len(paras):
        return None
    print(f"    {len(chunks)} parça yazıya dökülüyor", flush=True)
    from concurrent.futures import ThreadPoolExecutor

    with ThreadPoolExecutor(8) as pool:
        texts = list(pool.map(lambda c: transcribe(_wav_bytes(c, rate)), chunks))
    m, n = len(chunks), len(paras)
    # DP: parçaları sırayla paragraflara böl (her paragrafa en az bir parça).
    neg = -1e9
    best = [[neg] * (m + 1) for _ in range(n + 1)]
    back = [[0] * (m + 1) for _ in range(n + 1)]
    best[0][0] = 0
    for j in range(1, n + 1):
        for i in range(j, m - (n - j) + 1):
            for k in range(j - 1, i):
                if best[j - 1][k] == neg:
                    continue
                v = best[j - 1][k] + _sim(" ".join(texts[k:i]), paras[j - 1])
                if v > best[j][i]:
                    best[j][i] = v
                    back[j][i] = k
    groups = []
    i = m
    for j in range(n, 0, -1):
        k = back[j][i]
        groups.append((k, i))
        i = k
    groups.reverse()
    out = []
    for (k, i), p in zip(groups, paras):
        heard = " ".join(texts[k:i])
        score = _sim(heard, p)
        if score < 0.72:
            print(f"    eşleşmedi ({score:.2f}): {p[:50]} / duyulan: {heard[:50]}")
            return None
        seg = array.array("h")
        for c in chunks[k:i]:
            seg.extend(c)
        out.append(_wav_bytes(seg, rate))
    return out


def scene_lines(lines: list[dict], where: str, notes: dict, lang: str) -> list[tuple[dict, str, str]]:
    """Sahnenin seslendirilecek satırları: (öğe, okunacak metin, not)."""
    out = []
    for e in lines:
        if e["where"] != where or is_title(e["text"]):
            continue
        spec = notes.get(e["id"], {})
        text = spec.get("metin") or spoken(PREFIX.sub("", e["text"]), lang)
        if BARD.match(text):
            text = BARD.sub("", text)
            text = text[:1].upper() + text[1:]
        out.append((e, words_for_numbers(text, lang), spec.get("not", "")))
    return out


def make_scene(lines: list[dict], where: str, notes: dict, lang: str, out_dir: pathlib.Path) -> bool:
    """Sahnenin her satırı ayrı okunur ama hepsine aynı sahne tarifi verilir
    (kim, ne anlatıyor, ne hissediyor) ve kendi oyunculuk notu eklenir.
    Her satır yazıya dökülüp metniyle karşılaştırılır; yanlış okunduysa
    (yanlış yıl, eksik söz, talimat okunmuş) yeniden üretilir."""
    items = scene_lines(lines, where, notes, lang)
    scenes: dict = {}
    for f in sorted(SCENES.glob("*.json")):
        scenes.update(json.loads(f.read_text()))
    spec = scenes.get(where) or {"sahne": DEFAULT_SCENES.get(where.split(":")[0], "")}
    ok = True
    for e, text, note in items:
        if ONLY_IDS and e["id"] not in ONLY_IDS:
            continue
        out = out_dir / f"{e['id']}.mp3"
        if SKIP_NEWER and out.exists() and out.stat().st_mtime > SKIP_NEWER:
            continue
        play = spec.get("oyun", {}).get(e["id"], note)
        best = None
        for attempt in range(5):
            raw = generate(body_scene("Charon", [text], [play], spec.get("sahne", "")))
            wav = raw if raw[:4] == b"RIFF" else None
            if wav is None:
                with tempfile.TemporaryDirectory() as d:
                    w = pathlib.Path(d) / "x.wav"
                    g.save_wav(w, raw)
                    wav = w.read_bytes()
            score = _sim(transcribe(wav), text)
            if best is None or score > best[0]:
                best = (score, raw)
            if score >= 0.8:
                break
            print(f"    {e['id']}: yanlış okundu ({score:.2f}), yeniden", flush=True)
        to_mp3(best[1], out_dir / f"{e['id']}.mp3")
        print(f"  {e['id']} {best[0]:.2f}  {text[:50]}", flush=True)
        ok = ok and best[0] >= 0.8
    return ok


def make_scene_take(lines: list[dict], where: str, notes: dict, lang: str, out_dir: pathlib.Path) -> bool:
    """Eski yol: sahne tek kayıtta okunup bölünür (tutarlı ama düz ve
    yıl gibi hatalara açık; kullanılmıyor)."""
    items = scene_lines(lines, where, notes, lang)
    if not items:
        return True
    paras = [t for _, t, _ in items]
    scenes: dict = {}
    for f in sorted(SCENES.glob("*.json")):
        scenes.update(json.loads(f.read_text()))
    spec = scenes.get(where, {})
    play = [spec.get("oyun", {}).get(e["id"], n) for e, _, n in items]
    for attempt in range(3):
        print(f"  {where}: sahne okutuluyor ({attempt + 1})", flush=True)
        raw = generate(body_scene("Charon", paras, play, spec.get("sahne", "")))
        pieces = split_scene(raw, paras) if len(paras) > 1 else [raw]
        if pieces:
            for (e, _, _), piece in zip(items, pieces):
                to_mp3(piece, out_dir / f"{e['id']}.mp3")
            print(f"{where}: {len(paras)} satır tek seferde")
            return True
        print(f"  {where}: bölünemedi, yeniden ({attempt + 1})")
    return False


def clean_existing(lang: str) -> None:
    """Mevcut ses dosyalarındaki baş/son kalıntılarını temizler."""
    n = 0
    for f in sorted(pathlib.Path(f"assets/voice/{lang}").glob("*.mp3")):
        with tempfile.TemporaryDirectory() as d:
            w = pathlib.Path(d) / "x.wav"
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(f),
                            "-ac", "1", "-ar", "24000", str(w)], check=True)
            before = w.stat().st_size
            drop_blips(w)
            if w.stat().st_size != before:
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(w),
                                "-af", "apad=pad_dur=0.25", "-b:a", "48k", str(f)], check=True)
                n += 1
                print(f"temizlendi: {f.name}")
    print(f"{n} dosyada kalıntı silindi")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dil", default="tr")
    ap.add_argument("--bolum", type=int, nargs="*", help="bölüm sıraları (0: açılış perdesi ile)")
    ap.add_argument("--kimlik", nargs="*", help="yalnız bu satırlar")
    ap.add_argument("--yeniden", action="store_true", help="var olanı yeniden üret")
    ap.add_argument("--eskiyse", help="yalnız bu dosyadan eski sesleri yeniden üret (kaldığı yerden sürdürmek için)")
    ap.add_argument("--kuru", action="store_true", help="üretmeden listele")
    ap.add_argument("--temizle", action="store_true", help="mevcut seslerde baş/son kalıntılarını sil")
    ap.add_argument("--hatirasiz", action="store_true", help="hatıraları atla")
    ap.add_argument("--hatiralar", action="store_true", help="yalnız hatıralar")
    ap.add_argument("--sahne", nargs="*", help="perde/köprü sahnelerini tek seferde üret (ör. prologue perde:3 kopru:5)")
    ap.add_argument("--ses-adi", help="yalnız bu sesin okuduğu satırlar (Charon: hatıralardaki usta da)")
    a = ap.parse_args()
    if a.temizle:
        clean_existing(a.dil)
        return
    global DIL
    DIL = a.dil

    lines = json.loads(pathlib.Path(f"build/ses/satirlar_{a.dil}.json").read_text())
    notes: dict = {}
    for f in sorted(NOTES.glob("*.json")):
        notes.update(json.loads(f.read_text()))

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
    if a.eskiyse:
        global SKIP_NEWER
        SKIP_NEWER = pathlib.Path(a.eskiyse).stat().st_mtime
    if a.kimlik:
        ONLY_IDS.update(a.kimlik)
    if a.sahne is not None:
        wheres = a.sahne or sorted(
            {e["where"] for e in lines if e["role"] == "perde"},
        )
        for w in wheres:
            if not make_scene(lines, w, notes, a.dil, out_dir):
                print(f"{w}: tek seferde bölünemedi, satır satır kaldı")
        return
    todo = [e for e in lines if wanted(e)]
    print(f"{len(todo)} satır")
    for e in todo:
        out = out_dir / f"{e['id']}.mp3"
        if out.exists() and not a.yeniden:
            if not a.eskiyse or out.stat().st_mtime >= pathlib.Path(a.eskiyse).stat().st_mtime:
                continue
        if a.hatirasiz and e["role"] == "hatira":
            continue
        if a.hatiralar and e["role"] != "hatira":
            continue
        spec = notes.get(e["id"], {})
        voice = spec.get("ses", ROLE_VOICE[e["role"]])
        if a.ses_adi and a.ses_adi not in voice.split("+"):
            continue
        note = spec.get("not", "")
        if is_title(e["text"]):
            continue
        # Notta "metin" varsa o okunur (duraklar için üç nokta, söyleyiş);
        # ekrandaki yazı değişmez.
        text = notes.get(e["id"], {}).get("metin") or spoken(
            PREFIX.sub("", e["text"]), a.dil
        )
        text = words_for_numbers(text, a.dil)
        if BARD.match(text):
            text = BARD.sub("", text)
            text = text[:1].upper() + text[1:]
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
