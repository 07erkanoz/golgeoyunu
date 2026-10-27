#!/usr/bin/env python3
"""Hatıralarda ustanın sözünü bölen "derdi ustam", "dedi", "he said" eklerini
metinden ve sesten çıkarır (kredisiz). Ustanın bölünen sözü tek tırnakta
birleşir; sondaki ek de kalkar (söz zaten ustanın sesiyle duyuluyor).
Ses: ek, Sâye'nin sesiyle okunmuş ayrı bir parçadır. Parçalar sessizlikten
adalara bölünür, adalar ses perdesine göre (Sâye ince, usta kalın)
gruplanıp kayıttaki konuşan sırasıyla eşlenir; eşleşmezse satıra
dokunulmaz. Ek adası kesilir, iki usta parçası arasında kısa bir durak kalır.
Kullanım: python3 tools/hatira_derdi.py [--uygula]  (numpy gerekir)
"""
import json
import pathlib
import re
import subprocess
import sys

TAG = {
    "tr": r"(?:derdi|dedi|demişti)(?: ustam| bir gece)?",
    "en": r"(?:(?:he|my master) (?:had said|said|used to say|would say)(?: one night)?|said (?:my master|he))",
}
PREFIX = {"tr": "Hatıra · ", "en": "Memory · "}


def voice_id(text: str) -> str:
    h = 0x811C9DC5
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return f"{h:08x}"


def transform(line: str, lang: str) -> str:
    t = TAG[lang]
    # 1) İki söz arasında: "A," derdi ustam. "B."  →  "A. B."
    def between(m: re.Match) -> str:
        p = m.group(1) if m.group(1) in ("!", "?", ".") else "."
        return f'{p} '
    out = re.sub(r'([,.!?])"\s*' + t + r'\.\s*"', between, line)
    # 2) Söz ortasında: "A," dedi ustam, "b…"  →  "A, b…"
    out = re.sub(r',"\s*' + t + r',\s*"', ", ", out)
    # 3) Sonda: … "A," derdi.  →  … "A."  (sözden önce cümle bitmişse ya da
    # söz satırın başındaysa; "gösterip "…," demişti" gibi bağlılar kalır)
    def tail(m: re.Match) -> str:
        before = out[:m.start()]
        q = before.rfind('"')
        lead = before[:q].rstrip()
        if lead and not lead.endswith((".", ":", "!", "?", "·")):
            return m.group(0)
        p = m.group(1) if m.group(1) in ("!", "?", ".") else "."
        return f'{p}"'
    out = re.sub(r'([,.!?])"\s*' + t + r'\.(?=\s|$)', tail, out)
    return out


def plan(lang: str) -> list[dict]:
    import numpy as np  # noqa: F401
    sys.path.insert(0, str(pathlib.Path(__file__).parent))
    import ses_perdesi as sp
    done = json.loads(pathlib.Path(f"build/ses/eleven_oyun_{lang}.json").read_text())
    lines = json.loads(pathlib.Path(f"build/ses/satirlar_{lang}.json").read_text())
    tag_only = re.compile(r"^\[[^\]]*\]\s*" + TAG[lang] + r"[.,]?$", re.I)
    out = []
    for e in lines:
        if e["role"] != "hatira":
            continue
        new = transform(e["text"], lang)
        if new == e["text"]:
            continue
        path = f"assets/voice/{lang}/{e['id']}.mp3"
        segs = [tuple(x.split(": ", 1)) for x in done.get(e["id"], "").split(" ‖ ")]
        item = dict(id=e["id"], old=e["text"], new=new, new_id=voice_id(new), path=path, cut=None, why="")
        out.append(item)
        if not pathlib.Path(path).exists() or len(segs) < 2:
            item["why"] = "ses ya da kayıt yok"
            continue
        drop = [k for k, (who, txt) in enumerate(segs) if who == "saye" and tag_only.match(txt.strip())]
        if not drop:
            item["why"] = "ek ayrı parça değil"
            continue
        groups = sp.groups(path)
        if [g[2] for g in groups] != [who for who, _ in segs]:
            item["why"] = f"eşleşmedi: ses {[g[2] for g in groups]} kayıt {[w for w, _ in segs]}"
            continue
        cuts = []
        for k in drop:
            a = groups[k - 1][1] + 0.15 if k > 0 else 0.0
            b = groups[k + 1][0] - 0.15 if k + 1 < len(groups) else None
            cuts.append((a, b))
        item["cut"] = cuts
    return out


# Ek, Sâye'nin anlatısıyla aynı parçada ya da ses perdesi yanıldığında:
# adalar elle bakılıp ek adasını çevreleyen sessizlikler (saniye).
MANUAL = {
    ("tr", "e7e68828"): [],  # seste ek zaten okunmamış
    ("tr", "5f3743f0"): [(3.24, 4.75)],
    ("tr", "e15677eb"): [(5.75, 6.92)],
    ("tr", "ddc2ec57"): [(4.92, None)],
    ("tr", "c3ce2d22"): [(4.01, 4.92)],
    ("tr", "bbcc8448"): [(4.79, 5.66)],
    ("en", "44ac15da"): [(3.66, 5.09)],
    ("en", "c5ea0d86"): [(7.06, 8.39)],
    ("en", "f5c23471"): [(3.31, 5.07)],
}


def cut_audio(src: str, dst: str, cuts: list) -> None:
    """Kesimler sessizlikte; uçlara 10 ms yumuşak geçiş (EQ yok). Sondaki
    kesimden sonra 0,25 sn sessizlik."""
    keep, prev = [], 0.0
    for a, b in sorted(cuts):
        keep.append((prev, a))
        prev = b
    if prev is not None:
        keep.append((prev, None))
    parts = []
    for k, (a, b) in enumerate(keep):
        trim = f"atrim=start={a}" + (f":end={b}" if b is not None else "")
        parts.append(f"[0:a]{trim},asetpts=PTS-STARTPTS,afade=t=in:d=0.01,areverse,afade=t=in:d=0.01,areverse[p{k}]")
    tail = "" if keep[-1][1] is None else ",apad=pad_dur=0.25"
    graph = ";".join(parts) + ";" + "".join(f"[p{k}]" for k in range(len(keep))) + \
        f"concat=n={len(keep)}:v=0:a=1{tail}[o]"
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", src, "-filter_complex", graph, "-map", "[o]",
                    "-ac", "1", "-ar", "32000", "-b:a", "56k", dst], check=True)


def dart_str(t: str) -> str:
    return t.replace("\\", "\\\\").replace("'", "\\'")


def apply(lang: str, items: list[dict]) -> None:
    dart = pathlib.Path("lib/game/levels.dart")
    src = dart.read_text()
    for it in items:
        cuts = MANUAL.get((lang, it["id"]), it["cut"])
        if cuts is None:
            print("atlandı:", it["id"], it["why"])
            continue
        old_s, new_s = f"'{dart_str(it['old'])}'", f"'{dart_str(it['new'])}'"
        if src.count(old_s) != 1:
            print("levels.dart'ta tek değil:", it["id"], src.count(old_s))
            continue
        src = src.replace(old_s, new_s)
        dst = f"assets/voice/{lang}/{it['new_id']}.mp3"
        if cuts:
            cut_audio(it["path"], dst, cuts)
        else:
            pathlib.Path(dst).write_bytes(pathlib.Path(it["path"]).read_bytes())
        pathlib.Path(it["path"]).unlink()
    dart.write_text(src)


if __name__ == "__main__":
    for lang in ("tr", "en"):
        items = plan(lang)
        pathlib.Path(f"build/ses/hatira_plan_{lang}.json").write_text(json.dumps(items, ensure_ascii=False, indent=1))
        print(lang, len(items), "satır;", sum(1 for x in items if x["cut"] or (lang, x["id"]) in MANUAL), "uygulanabilir")
        if "--uygula" in sys.argv:
            apply(lang, items)
