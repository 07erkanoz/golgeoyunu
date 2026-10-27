#!/usr/bin/env python3
"""İki konuşma arasındaki anlatıcı eklerini ("dedi Hüdhüd", "said the Hoopoe")
metinden ve sesten çıkarır (kredisiz). Kahramanlar kendi sesiyle konuştuğu
için ekler akışı bozuyordu.
Ses: ek, iki konuşma arasında sessizliklerle ayrılmış ayrı bir parçadır; o
parça tek başına yazıya dökülüp ek olduğu doğrulanınca kesilir. Dosya yeni
metnin kimliğine taşınır (yeniden seslendirme yok).
Kullanım: python3 tools/dedi_temizle.py [--uygula]
"""
import array
import json
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import seslendir as s  # noqa: E402

SR = 32000
VERB = {"tr": r"(dedi|diye|derdi|demişti|sordu|fısıldadı|seslendi|bağırdı)",
        "en": r"((?:he |she |it )?(?:said|asked|whispered|cried))"}


def voice_id(text: str) -> str:
    h = 0x811C9DC5
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


SPEAKERS = json.loads(pathlib.Path("tools/perde_metni/konusanlar.json").read_text())
# Anlam taşıyan ekler kalır: kendi kendine konuşma, bağırış, yazıt okuma.
KEEP = re.compile(r"kendi kendine|to herself|bağırdı|cried|shouted|demişti|:")


def speakers(w: str, i: int, n: int) -> list | None:
    spec = SPEAKERS.get(w, {}).get(str(i))
    if spec is None:
        return None
    if isinstance(spec, str):
        return [spec] * n
    return (spec + [spec[-1]] * n)[:n]


def transform(line: str, lang: str, w: str, i: int) -> tuple[str, list[str], list | None]:
    """Kahramanın kendi sesiyle konuştuğu satırlarda "dedi Hüdhüd" gibi ekler
    kalkar; ekten sonra cümle sürüyorsa ("dedi. Sesi titriyordu.") kalan kısım
    kalır. Aynı kişinin bölünmüş sözü tek tırnakta birleşir. Dönen üçüncü
    değer: birleşmeden sonraki konuşan listesi (konusanlar.json için)."""
    spk = speakers(w, i, line.count("“"))
    if spk is None:
        return line, [], None
    tags: list[str] = []
    merged: set[int] = set()
    verb = VERB[lang]
    # 1) İki söz arasında: “A,” dedi X. [anlatı] “B”
    rx = re.compile(r"([,.!?])?”\s*(" + verb + r"[^.“”]{0,40}\.)\s*([^“”]*?)\s*“")

    def between(m: re.Match) -> str:
        if KEEP.search(m.group(2)):
            return m.group(0)
        q = line[:m.start()].count("”")
        tags.append(m.group(2))
        p = m.group(1) if m.group(1) in ("!", "?", ".") else "."
        rest = m.group(4).strip()
        if rest:
            return f"{p}” {rest} “"
        if q + 1 < len(spk) and spk[q] == spk[q + 1]:
            merged.add(q + 1)
            return f"{p} "
        return f"{p}” “"
    out = rx.sub(between, line)
    # 2) Söz ortasında: “Al,” dedi ihtiyar, “yolun açık olsun.”
    out, n = re.subn(r",”\s*(" + verb + r"[^,“”]{0,30}),\s*“", lambda m: (tags.append(m.group(1)), ", ")[1], out)
    if n:
        merged.add(-1)
    # 3) Sonda: “Ustan orada,” dedi Tulpar. [anlatı]
    def tail(m: re.Match) -> str:
        if KEEP.search(m.group(2)) or len(m.group(2).split()) > 4:
            return m.group(0)
        tags.append(m.group(2))
        p = m.group(1) if m.group(1) in ("!", "?", ".") else "."
        return f"{p}”"
    out = re.sub(r"([,.!?])?”\s*(" + verb + r"[^.“”]{0,30}\.)(?=\s*(?:[^“”]*$))", tail, out)
    out = re.sub(r"\s{2,}", " ", out).strip()
    left = [x for k, x in enumerate(spk) if k not in merged]
    if -1 in merged:
        left = left[:out.count("“")]
    return out, tags, left


def islands(path: str) -> list[tuple[float, float]]:
    r = subprocess.run(["ffmpeg", "-hide_banner", "-i", path, "-af", "silencedetect=n=-45dB:d=0.2",
                        "-f", "null", "-"], capture_output=True, text=True).stderr
    st = [float(x) for x in re.findall(r"silence_start: ([0-9.]+)", r)]
    en = [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", r)]
    dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
                               capture_output=True, text=True).stdout)
    edges = [0.0] + sorted(en) + [dur]
    starts = sorted(st)
    out = []
    # konuşma adaları: bir sessizliğin sonundan bir sonrakinin başına
    prev = 0.0
    for s0, e0 in zip(sorted(st), sorted(en)):
        if s0 - prev > 0.05:
            out.append((prev, s0))
        prev = e0
    if dur - prev > 0.05:
        out.append((prev, dur))
    return out


def snippet_text(path: str, a: float, b: float) -> str:
    w = subprocess.run(["ffmpeg", "-loglevel", "error", "-ss", str(a), "-to", str(b), "-i", path, "-ac", "1",
                        "-ar", "16000", "-f", "wav", "-"], capture_output=True).stdout
    return s.transcribe(w)


def norm(t: str) -> str:
    return re.sub(r"[^a-zçğıöşüâîû ]", "", t.lower().replace("’", "'")).replace("'", "").strip()


def straight(t: str) -> str:
    return t.replace("“", '"').replace("”", '"')


def cut_audio(src: str, dst: str, cuts: list) -> None:
    """Ek parçalarını keser; kesim yerleri sessizlikte, uçlara 10 ms yumuşak
    geçiş (EQ yok)."""
    if not cuts:
        pathlib.Path(dst).write_bytes(pathlib.Path(src).read_bytes())
        return
    keep, prev = [], 0.0
    for a, b, _ in sorted(cuts):
        keep.append((prev, a))
        prev = b
    keep.append((prev, None))
    parts = []
    for k, (a, b) in enumerate(keep):
        trim = f"atrim=start={a}" + (f":end={b}" if b is not None else "")
        parts.append(f"[0:a]{trim},asetpts=PTS-STARTPTS,afade=t=in:d=0.01,areverse,afade=t=in:d=0.01,areverse[p{k}]")
    graph = ";".join(parts) + ";" + "".join(f"[p{k}]" for k in range(len(keep))) + f"concat=n={len(keep)}:v=0:a=1[o]"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", src, "-filter_complex", graph, "-map", "[o]",
                    "-ac", "1", "-ar", "32000", "-b:a", "56k", dst], check=True)


def apply_plan(d: dict, plan: list) -> None:
    sp = json.loads(pathlib.Path("tools/perde_metni/konusanlar.json").read_text())
    drafts = {lang: pathlib.Path(f"tools/perde_metni/masal_{lang}.txt") for lang in ("tr", "en")}
    draft_text = {lang: f.read_text() for lang, f in drafts.items()}
    for p in plan:
        lang, k, lv, i = p["lang"], p["k"], p["lv"], p["i"]
        lines = d[lang][k] if lv is None else d[lang][k][lv]
        assert lines[i] == p["old"], (lang, k, lv, i)
        lines[i] = p["new"]
        if straight(p["old"]) in draft_text[lang]:
            draft_text[lang] = draft_text[lang].replace(straight(p["old"]), straight(p["new"]))
        else:
            print("taslakta yok:", lang, p["w"], i)
        # Konuşan listesi yalnız Türkçeye göre tutulur (iki dil aynı sırada).
        cur = sp.get(p["w"], {}).get(str(i))
        if lang == "tr" and isinstance(cur, list) and p["spk"] != cur:
            sp[p["w"]][str(i)] = p["spk"] if len(set(p["spk"])) > 1 else p["spk"][0]
        if pathlib.Path(p["path"]).exists():
            dst = f"assets/voice/{lang}/{p['new_id']}.mp3"
            cut_audio(p["path"], dst, p["cut"])
            pathlib.Path(p["path"]).unlink()
    pathlib.Path("tools/perde_metni/metin.json").write_text(json.dumps(d, ensure_ascii=False, indent=1) + "\n")
    pathlib.Path("tools/perde_metni/konusanlar.json").write_text(json.dumps(sp, ensure_ascii=False, indent=1) + "\n")
    for lang, f in drafts.items():
        f.write_text(draft_text[lang])


def main() -> None:
    apply = "--uygula" in sys.argv
    d = json.loads(pathlib.Path("tools/perde_metni/metin.json").read_text())
    plan = []
    # Önceki taramanın sonuçları: aynı dosya ve aynı ekler yeniden taranmaz.
    cache_f = pathlib.Path("build/ses/dedi_onbellek.json")
    cache = json.loads(cache_f.read_text()) if cache_f.exists() else {}
    for lang in ("tr", "en"):
        def walk():
            for k in ("prologue", "epilogue"):
                for i, l in enumerate(d[lang][k]):
                    yield (k, None, i, l)
            for k in ("perde", "kopru"):
                for lv, ls in d[lang][k].items():
                    for i, l in enumerate(ls):
                        yield (k, lv, i, l)
        for k, lv, i, l in walk():
            w = k if lv is None else f"{k}:{lv}"
            new, tags, spk = transform(l, lang, w, i)
            if not tags:
                continue
            old_id, new_id = voice_id(l), voice_id(new)
            path = f"assets/voice/{lang}/{old_id}.mp3"
            cut = []
            key = old_id + "|" + "|".join(tags)
            if key in cache:
                cut = cache[key]
            elif pathlib.Path(path).exists():
                for a, b in islands(path):
                    if b - a > 2.2:
                        continue
                    h = norm(snippet_text(path, a, b))
                    for t in tags:
                        tw = norm(t).split()
                        if h and tw and h.split()[0] == tw[0] and len(h.split()) <= len(tw) + 1:
                            cut.append((a, b, h))
                            break
                cache[key] = cut
                cache_f.write_text(json.dumps(cache, ensure_ascii=False, indent=1))
                print("  tarandı", lang, w, i, cut, flush=True)
            plan.append(dict(lang=lang, k=k, lv=lv, i=i, w=w, old=l, new=new, tags=tags, spk=spk, old_id=old_id,
                             new_id=new_id, path=path, cut=cut))
    pathlib.Path("build/ses/dedi_plan.json").write_text(json.dumps(plan, ensure_ascii=False, indent=1))
    if apply:
        apply_plan(d, plan)
    for p in plan:
        print(p["lang"], p["k"], p["lv"], p["i"], "ekler", p["tags"], "| seste kesilecek", [(round(a, 2), round(b, 2), h) for a, b, h in p["cut"]])
    print("satır", len(plan))


if __name__ == "__main__":
    main()
