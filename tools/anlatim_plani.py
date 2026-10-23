#!/usr/bin/env python3
"""Anlatım planını oyuna yazar: build/ses/dagitim_*.json → lib/game/anlatim_plani.dart.

Dağıtım anahtarı "bölüm:fısıltı sırası"; sınıf yazi / tehlike / agac / defter;
agac için anlatılacağı Umay ağacının sütunu.

  python3 tools/anlatim_plani.py
"""

import glob
import json
import pathlib

OUT = pathlib.Path("lib/game/anlatim_plani.dart")
HEAD = OUT.read_text().split("const whisperPlan")[0]
TAIL = """
/// Fısıltının yeri (planda yoksa oynanış sırasında yazı).
(WhisperPlace, int?) whisperPlace(int level, int index) =>
    whisperPlan[level]?[index] ?? (WhisperPlace.yazi, null);
"""


def main() -> None:
    plan: dict[int, dict[int, tuple[str, int | None]]] = {}
    for f in sorted(glob.glob("build/ses/dagitim_*.json")):
        for key, v in json.load(open(f)).items():
            level, index = (int(x) for x in key.split(":"))
            plan.setdefault(level, {})[index] = (v["sinif"], v.get("agac_col"))
    lines = ["const whisperPlan = <int, Map<int, (WhisperPlace, int?)>>{"]
    for level in sorted(plan):
        lines.append(f"  {level}: {{")
        for index in sorted(plan[level]):
            kind, col = plan[level][index]
            lines.append(f"    {index}: (WhisperPlace.{kind}, {'null' if col is None else col}),")
        lines.append("  },")
    lines.append("};")
    OUT.write_text(HEAD + "\n".join(lines) + "\n" + TAIL)
    n = sum(len(v) for v in plan.values())
    print(f"{OUT}: {len(plan)} bölüm, {n} fısıltı")


if __name__ == "__main__":
    main()
